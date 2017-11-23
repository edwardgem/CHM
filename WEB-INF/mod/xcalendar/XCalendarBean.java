//
//	Copyright (c) 2006, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: XCalendarBean.java
//	Author: AGQ
//	Date:	08/15/06
//	Description: 
//			Creates Exchange Server Calendar invite emails for meetings
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
package mod.xcalendar;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.Date;
import java.util.SimpleTimeZone;
import java.util.TimeZone;

import oct.codegen.meeting;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.pmp.exception.PmpException;
import oct.pmp.exception.PmpObjectNotFoundException;
import oct.pst.PstUserAbstractObject;

import org.apache.log4j.Logger;

import util.PrmLog;

public class XCalendarBean {
	/*
	 * An immutable object used to create a exchange server calendar
	 */
	
	private static final String 			ATTENDEE 	= "Attendee";
	private static final String 			EMAIL 		= "Email";
	private static final String 			OWNER 		= "Owner";
	private static final String 			STARTDATE 	= "StartDate";
	private static final String 			EXPIREDATE 	= "ExpireDate";
	private static final String 			LOCATION 	= "Location";
	private static final String 			AGENDAITEM 	= "AgendaItem";
	private static final String 			EMPTY 		= "";
	private static final String [] 			TZS;		
	private static final SimpleTimeZone 	TZ;
	private static final SimpleDateFormat 	DF;
	private static userManager 				uMgr; 		// user object to find email and names
	private static Logger 					l 			= PrmLog.getLog();
	
	private final String	 				organizer; 	// owner of meeting
	private final String	 				startDt; 	// meeting start time
	private final String	 				endDt; 		// meeting end time
	private final String				 	location; 	// location of meeting
	private final String 					curDt; 		// current time
	private final String 					description;// agenda items
	private final String 					msg; 		// exchange server calendar text
	private final ArrayList 				mandatoryName 	= new ArrayList(); // required attendee names
	private final ArrayList 				mandatoryEmail 	= new ArrayList(); // required attendee emails
	private final ArrayList 				optionalName 	= new ArrayList(); // optional attendee names
	private final ArrayList 				optionalEmail 	= new ArrayList(); // optional attendee emails
	private final PstUserAbstractObject 	pstuser; 	// current user
	
	/*
	 * Initialize static variables
	 */
	static {
		try {
			uMgr = userManager.getInstance();
		} catch (PmpException e) {
			uMgr = null;
		};
		
		TZS = TimeZone.getAvailableIDs(0); // GMT timezone
		TZ = new SimpleTimeZone(0, TZS[0]);
		DF = new SimpleDateFormat ("yyyyMMdd'T'HHmmss'Z'");
		DF.setTimeZone(TZ);
	}

	/**
	 * Initialize immutable object
	 * @param pstuser Organizer's user object
	 * @param mtg A fully setup db mtg object
	 * @throws PmpException
	 */
	public XCalendarBean(PstUserAbstractObject pstuser, meeting mtg) 
	throws PmpException {
		this.pstuser = pstuser;
		parseTeam(mtg); // fetches team members information
		this.organizer = parseOrganizer(mtg);
		this.startDt = parseStartDt(mtg);
		this.endDt = parseEndDt(mtg);
		this.location = parseLocation(mtg);	
		this.curDt = parseCurDt();
		this.description = parseDescription(mtg);
		
		this.msg = generateMsg();
	}
	
	/**
	 * Fetches meeting team members email and names
	 * @param mtg
	 * @throws PmpException
	 */
	private final void parseTeam(meeting mtg) 
	throws PmpException {
		Object [] objArr = mtg.getAttribute(ATTENDEE);
		user u;
		String s;
		String [] sa;
		
		if (uMgr == null) uMgr = userManager.getInstance(); // Shouldn't happen
		
		for (int i=0; i<objArr.length; i++)
		{
			s = (String) objArr[i];
			if (s == null) break;
			sa = s.split(meeting.DELIMITER); // uid::status e.g. 12345::mandatory
			int aId = Integer.parseInt(sa[0]);
			u = (user) uMgr.get(pstuser, aId);
			
			// Mandatory/Required team members
			if (sa[1].startsWith(meeting.ATT_MANDATORY))
			{
				mandatoryName.add(u.getFullName());
				mandatoryEmail.add(u.getAttribute(EMAIL)[0]);
			}
			// Optional team members
			else
			{
				optionalName.add(u.getFullName());
				optionalEmail.add(u.getAttribute(EMAIL)[0]);
			}
		}
	}

	/**
	 * Fetches meeting owner's email
	 * @param mtg
	 * @return Meeting owner's email address or blank if not found
	 * @throws PmpException
	 */
	private final String parseOrganizer(meeting mtg) 
	throws PmpException {
		String s = null;
		int aId = 0;
		
		try {
			Object obj = mtg.getAttribute(OWNER)[0];
			if (obj != null) {
				s = (String) obj;
				aId = Integer.parseInt(s);
				user u = (user) uMgr.get(pstuser, aId);
				obj = u.getAttribute(EMAIL)[0];
				if (obj!=null)
					return (String) obj;
			}
		} catch (NumberFormatException e) {
			l.warn("Meeting ("+mtg.getObjectId()+") owner id error: " + s);
		} catch (PmpObjectNotFoundException e) {
			l.warn("Meeting ("+mtg.getObjectId()+") owner id no found: " + aId);
		}
		return EMPTY;
	}
	
	/**
	 * Fetches and parses the start date
	 * @param mtg
	 * @return yyyyMMdd'T'HHmmss'Z' 
	 * 			e.g. 8/11/06 6:49 17sec pm -> 20060811T184917Z
	 * @throws PmpException
	 */
	private final String parseStartDt(meeting mtg) 
	throws PmpException {
		Date date = (Date) mtg.getAttribute(STARTDATE)[0];
		return DF.format(date);
	}
	
	/**
	 * Fetches and parse the expire date
	 * @param mtg
	 * @return yyyyMMdd'T'HHmmss'Z' 
	 * 			e.g. 8/11/06 6:49 17sec pm -> 20060811T184917Z
	 * @throws PmpException
	 */
	private final String parseEndDt(meeting mtg) 
	throws PmpException {
		Date date = (Date) mtg.getAttribute(EXPIREDATE)[0];
		return DF.format(date);
	}

	/**
	 * Parses the current time
	 * @return yyyyMMdd'T'HHmmss'Z' 
	 * 			e.g. 8/11/06 6:49 17sec pm -> 20060811T184917Z
	 * @throws PmpException
	 */
	private final String parseCurDt() {
		return DF.format(new Date());
	}

	/**
	 * Fetches location
	 * @param mtg
	 * @return The location of the meeting or "" if not found
	 * @throws PmpException
	 */
	private final String parseLocation(meeting mtg) 
	throws PmpException {
		Object obj = mtg.getAttribute(LOCATION)[0];
		if (obj != null) 
			return (String) obj;
		else
			return EMPTY;
	}
	
	/**
	 * Fetches and parse the agenda item
	 * @param mtg
	 * @return Agenda
	 * @throws PmpException
	 */
	private final String parseDescription(meeting mtg) 
	throws PmpException {
		StringBuffer sb = new StringBuffer();
		Object [] objArr = mtg.getAttribute(AGENDAITEM);

		if (objArr != null) {
			Arrays.sort(objArr, new Comparator()
			{
				public int compare(Object o1, Object o2)
				{
					try{
					String [] sa1 = ((String) o1).split(meeting.DELIMITER);
					String [] sa2 = ((String) o2).split(meeting.DELIMITER);
					int i1 = Integer.parseInt(sa1[0]);	// pre-order
					int i2 = Integer.parseInt(sa2[0]);	// pre-order
					return ((i1>i2)?1:0);
					}catch(Exception e){
						return 0;}
				}
			});
			
			for (int i=0; i<objArr.length; i++) {
				sb.append(objArr[i].toString());
				sb.append("\n");
			}
		}
	
		return sb.toString();
	}
	
	/**
	 * Constructs the msg String
	 * @return Exchange Server Calendar message body
	 */
	private final String generateMsg() {
		StringBuffer buf = new StringBuffer();
		buf.append(
				"BEGIN:VCALENDAR\n"+
				"PRODID:-//Microsoft Corporation//Outlook 9.0 MIMEDIR//EN\n"+
				"VERSION:2.0\n"+
				"METHOD:REQUEST\n"+
				"BEGIN:VEVENT\n");
		
		// attendee and organizer	
		int manSize = mandatoryName.size();
		int manESize = mandatoryEmail.size();
		if (manSize != manESize) manSize = (manSize<manESize)?manSize:manESize;
		for (int i=0; i<manSize; i++) {
			buf.append("ATTENDEE;CN=\""+mandatoryName.get(i)+
					"\";ROLE=REQ-PARTICIPANT;MAILTO:"+
					mandatoryEmail.get(i)+"\n");
		}
		
		int optSize = optionalName.size();
		int optESize = optionalEmail.size();
		if (optSize != optESize) optSize = (optSize<optESize)?optSize:optESize;
		for (int i=0; i<optSize; i++) {
			buf.append("ATTENDEE;CN=\""+optionalName.get(i)+
					"\";ROLE=OPT-PARTICIPANT;MAILTO:"+
					optionalEmail.get(i)+"\n");
		}
		
		buf.append("ORGANIZER:MAILTO:"+organizer+"\n");
		
		// meeting time
		buf.append(
				"DTSTART:" + startDt + "\n");
		buf.append(
				"DTEND:" + endDt + "\n");
		// location
		buf.append(
				"LOCATION:"+location+"\n"+
				"TRANSP:OPAQUE\n"+
				"SEQUENCE:0\n"+
				"UID:040000008200E00074C5B7101A82E00800000000A0A742" +
				"E5073AC5010000000000000000100\n" +
				" 0000029606C073D82204AB6C77ACE6BC2FBE2\n"+
				"DTSTAMP:" + curDt + "\n"+
				"CATEGORIES:Meeting\n");
		
		// agenda
		buf.append(
				"DESCRIPTION:"+description+"\n\n");
		
		buf.append(
				"SUMMARY:PRM Meeting invitation\n"+
				"PRIORITY:5\n"+
				"CLASS:PUBLIC\n"+
				"BEGIN:VALARM\n"+
				"TRIGGER:PT1440M\n"+
				"ACTION:DISPLAY\n"+
				"DESCRIPTION:Reminder\n"+
				"END:VALARM\n"+
				"END:VEVENT\n"+
				"END:VCALENDAR\n");
		return buf.toString();
	}

	/**
	 * The Exchange Server Calendar message
	 * @return
	 */
	public String getMsg() {
		return msg;
	}
	
	/**
	 * All the receipients' emails
	 * @return
	 */
	public String getEmails() {
		StringBuffer sb = new StringBuffer();
		String space = " ";
		int size = mandatoryEmail.size();
		for (int i=0; i<size; i++) {
			sb.append(mandatoryEmail.get(i) + space);
		}
		size = optionalEmail.size();
		for (int i=0; i<size; i++) {
			sb.append(optionalEmail.get(i) + space);
		}
		return sb.toString();
	}
}
