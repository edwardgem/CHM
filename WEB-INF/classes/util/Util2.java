//
//  Copyright (c) 2006, EGI Technologies.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   Util2.java
//  Author:
//  Date:   12/01/2006
//  Description:
//
//  Modification:
//
/////////////////////////////////////////////////////////////////////
//
// Util.java : implementation of the Util2 class for OMF
//
package util;

import java.io.File;
import java.io.UnsupportedEncodingException;
import java.math.BigDecimal;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.TimeZone;

import mod.xcalendar.XCalendarBean;
import oct.codegen.confManager;
import oct.codegen.meeting;
import oct.codegen.meetingManager;
import oct.codegen.project;
import oct.codegen.projectManager;
import oct.codegen.quest;
import oct.codegen.questManager;
import oct.codegen.result;
import oct.codegen.resultManager;
import oct.codegen.townManager;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.codegen.userinfo;
import oct.codegen.userinfoManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstManager;
import oct.pst.PstUserAbstractObject;

import org.apache.log4j.Logger;

public class Util2 {

	private static final SimpleDateFormat df1 = new SimpleDateFormat ("MM/dd/yy");
	private static final SimpleDateFormat df2 = new SimpleDateFormat ("M/dd (EEE) hh:mm");
	private static final SimpleDateFormat df3 = new SimpleDateFormat ("hh:mm a");

	public static final int DEFAULT_TOTAL_SPACE	= 1000;		// remote space in MB

	private static final String MAILFILE	= "alert.htm";
	private static final String FROM		= Util.getPropKey("pst", "FROM");
	private static final String NODE		= Prm.getPrmHost();
	private static final String APPS		= Prm.getAppTitle();
	
	private static final String USER_PIC_URL		= Util.getPropKey("pst", "USER_PICFILE_URL");
	private static final String DEFAULT_USER_PIC	= Util.getPropKey("pst", "DEFAULT_USER_PIC");

	private static boolean isAutoNewUser = false;
	private static boolean isUsernameEmail = false;

	private static Logger l = PrmLog.getLog();
	private static userManager 	uMgr;
	private static userinfoManager 	uiMgr;
	private static projectManager pjMgr;
	private static resultManager rMgr;
	protected static townManager tnMgr;
	protected static meetingManager mtgMgr;
	protected static questManager qMgr;
	protected static confManager cfMgr;

	static {
		try {
			String s = Util.getPropKey("pst", "NEW_USER_AUTO_APPROVAL");
			if (s!=null && s.equalsIgnoreCase("true"))
				isAutoNewUser = true;
			if ((s=Util.getPropKey("pst", "USERNAME_EMAIL"))!=null && s.equalsIgnoreCase("true"))
				isUsernameEmail = true;

			uMgr	= userManager.getInstance();
			uiMgr	= userinfoManager.getInstance();
			pjMgr	= projectManager.getInstance();
			rMgr	= resultManager.getInstance();
			tnMgr	= townManager.getInstance();
			mtgMgr	= meetingManager.getInstance();
			qMgr	= questManager.getInstance();
			cfMgr	= confManager.getInstance();
		} catch (PmpException e) {l.error("Fail in Util2.init().");}
	}

	// sendInvitation
	// ECC support both meeting and quest invitations
	public static void sendInvitation(PstUserAbstractObject pstuser, PstAbstractObject obj, String optMsg)
		throws PmpException
	{
		if (optMsg == null)
			optMsg = "";			// optional personal message

		String s;
		String userLink, guestLink;
		String msg;
		String myName;
		user creator;
		String ownerAttrName;
		String subject = (String)obj.getAttribute("Subject")[0];
		PstManager mgr;
		PstAbstractObject o;
		int id = obj.getObjectId();
		int [] ids;

		String agendaText = null;
		String blogText = null;
		boolean isMeeting;
		if (obj instanceof meeting)
		{
			isMeeting = true;

			// for meeting invitation, include the whole agenda
			agendaText = ((meeting)obj).getAgendaString().replaceAll("@@", ":");	// the agenda may have this encoded
			if (agendaText.length() <= 0)
				agendaText = "<blockquote>No agenda specified</blockquote>";

			// include blog
			ids = rMgr.findId(pstuser, "Type='" + result.TYPE_MTG_BLOG + "' && TaskID='" + id + "'");
			if (ids.length > 0)
				blogText = "A total of " + ids.length + " blog" + ((ids.length>1)?"s":"") + " posted. ";
			else
				blogText = "No blog posted on this meeting. ";
			blogText += "<a href='" + NODE + "/meeting/mtg_view.jsp?mid=" + id + "#blog'>Click to access and post blog to this meeting.</a>";

			userLink = NODE + "/meeting/mtg_view.jsp?mid=" + id;
			guestLink = NODE + "/login_omf.jsp?mid=" + id + "&email=" ;
			ownerAttrName = "Owner";
			mgr = mtgMgr;
		}
		else
		{
			// quest
			isMeeting = false;

			// include blog
			ids = rMgr.findId(pstuser, "Type='" + result.TYPE_QUEST_BLOG + "' && TaskID='" + id + "'");
			if (ids.length > 0)
				blogText = "A total of " + ids.length + " blog" + ((ids.length>1)?"s":"") + " posted. ";
			else
				blogText = "No blog posted on this event. ";
			blogText += "<a href='" + NODE + "/question/q_respond.jsp?qid=" + id + "'>Click to access and post blog to this event.</a>";

			userLink = NODE + "/question/q_respond.jsp?qid=" + id;
			guestLink = NODE + "/login_omf.jsp?status=new&email=" ;
			ownerAttrName = "Creator";
			mgr = qMgr;
		}

		s = (String)obj.getAttribute(ownerAttrName)[0];
		creator = (user)userManager.getInstance().get(pstuser, Integer.parseInt(s));
		myName = creator.getFullName();

		String tzS = "";
		SimpleDateFormat df = new SimpleDateFormat ("MMMMMMMM dd, yyyy (EEE) hh:mm a");
		Date dt = (Date)obj.getAttribute("StartDate")[0];
		if (dt != null)
		{
			userinfo myUI = (userinfo) uiMgr.get(pstuser, String.valueOf(creator.getObjectId()));
			TimeZone myTimeZone = myUI.getTimeZone();
			if (!userinfo.isServerTimeZone(myTimeZone)) {
				df.setTimeZone(myTimeZone);
			}
			s = df.format(dt); 			// 8:00 PM
			tzS = myUI.getZoneString();				// get the timezone string like "GMT+8 Hong Kong..."
			tzS = s + " (" + tzS + ")";
			s += " (" + myUI.getZoneShortString() + ")";	// 8:00 PM (GMT+8) just for Subject
		}
		else
			s = "";

		if (isMeeting)
		{
			// meeting
			// time and location
			String location = obj.getStringAttribute("Location");
			if (location != null) {
				try {
					Integer.parseInt(location);
					PstAbstractObject cf = cfMgr.get(pstuser, location);
					location = cf.getStringAttribute("Name");
				}
				catch (Exception e) {}
			}
			
			msg = myName + " has invited you to a meeting:"
					+ "<blockquote>Time: "+ tzS;
			if (!StringUtil.isNullOrEmptyString(location))
				msg += "<br/>Location: " + location;
			msg	+= "</blockquote>";
			
			
			msg += "<br />To join the meeting, click the link below at the specified time.";
		}
		else
		{
			// quest/event
			if (((String)obj.getAttribute("Type")[0]).indexOf(quest.TYPE_EVENT)!=-1)
			{
				msg = myName + " has invited you to an event/party on " + tzS;	//df.format(localStartDate);
				if (obj.getAttribute("Content")[0] != null) {
					msg += "<br />Please RSVP by clicking the link below.";
				}
				else {
					msg += "<br />Please click the link below for more details.";
				}
			}
			else
			{
				msg = myName + " has requested you to respond to a questionnaire/survey/vote";
				msg += "<br />Please respond by clicking the link below.";
			}
		}

		if (s != "") s = " - " + s;
		String subj = "[" + APPS + " Invite] ";
		subj += subject + s;

		String from = (String)creator.getAttribute("Email")[0];

		String msg2	= msg + "<blockquote><b><a href='" + userLink
			+ "'>" + subject + "</a></b><br>"
			+ "<a href='" + userLink + "'>"+ userLink + "</a>"
			+ "\n</blockquote>" + optMsg;

		Object [] guestEmails = obj.getAttribute("GuestEmails");

		// get the user ids from the invitee list
		Object [] attArr = obj.getAttribute("Attendee");
		Object [] userIdArr = new Object [attArr.length];
		String [] sa;
		for (int i=0; i<attArr.length; i++)
		{
			s = (String)attArr[i];
			if (s == null) break;
			sa = s.split(meeting.DELIMITER);
			userIdArr[i] = sa[0];
		}

		// send the invitation

		// description
		Object bTextObj = obj.getAttribute("Description")[0];
		String descStr = "";
		try {descStr = (bTextObj==null)?null : new String((byte[])bTextObj, "utf-8");}
		catch (UnsupportedEncodingException e) {throw new PmpException(e.getMessage());}
		if (descStr != null)
			msg2 += "<b>Description:</b><blockquote>" + descStr + "</blockquote>";

		// agenda
		if (agendaText != null)
			msg2 += "<b>Agenda:</b><p>" + agendaText;

		// blog
		msg2 += "</p><b>Blogs:</b><blockquote>" + blogText + "</blockquote>";

		String sendXCal = Util.getPropKey("pst", "SEND_X_CALENDAR");
		if (sendXCal != null && sendXCal.equalsIgnoreCase("true"))
		{
			// this is to support sending outlook meeting request
			XCalendarBean xCal = new XCalendarBean(pstuser, (meeting)obj);
			util.PrmEmail em = new util.PrmEmail();
			em.sendMtgReq(xCal.getEmails(), from, null, null,
					subject, xCal.getMsg(), false);
		}
		else
		{
			// send regular email
			String guestStr;
			Util.sendMailAsyn(pstuser, from, userIdArr, null, null, subj, msg2, MAILFILE);
			if (guestEmails != null && guestEmails.length > 0)
			{
				if (!isAutoNewUser || !isUsernameEmail)
				{
					msg += "<blockquote><b><a href='" + guestLink;
					for (int i=0; i<guestEmails.length; i++)
					{
						if (guestEmails[i] == null) continue;
						guestStr = (String)guestEmails[i];
						msg2 = msg + guestStr + "'>" + subject + "</a></b><br>"
							+ "<a href='" + guestLink + guestStr + "'>"
							+ guestLink + guestStr + "</a>\n</blockquote>" + optMsg;
						if (descStr != null)
							msg2 += "<b>Description:</b><blockquote>" + descStr + "</blockquote>";
						if (agendaText != null)
							msg2 += "<b>Agenda:</b>" + agendaText;
						Util.sendMailAsyn(pstuser, from, guestStr, null, null, subj, msg2, MAILFILE);
					}
				}
				else
				{
					// create the guest email account now and send invitation email
					for (int i=0; i<guestEmails.length; i++)
					{
						if (guestEmails[i] == null) continue;
						guestStr = (String)guestEmails[i];
						String newPass = Util.createPassword();	// ironman12
						try {o = uMgr.createUser(pstuser, guestStr, newPass, true);}	// create user, userinfo and set up base values
						catch (PmpException e){l.error("Fail to create guest [" + guestStr + "]"); continue;}
						msg = "<b>Your login information follows:</b>";
						msg += "<blockquote><table cellspacing='0' cellpadding='0'>";
						msg += "<tr><td class='plaintext' width='120'><b>Username</b>:</td><td class='plaintext'>" + guestStr + "</td></tr>";
						msg += "<tr><td class='plaintext' width='120'><b>Password</b>:</td><td class='plaintext'>" + newPass + "</td></tr>";
						msg += "</table></blockquote>";
						msg2 += msg;
						Util.sendMailAsyn(pstuser, from, guestStr, null, null, subj, msg2, MAILFILE);
						s = String.valueOf(o.getObjectId());
						if (isMeeting)
							s += meeting.DELIMITER + meeting.ATT_OPTIONAL;
						obj.appendAttribute("Attendee", s);
					}
					obj.setAttribute("GuestEmails", null);		// remove because they are now members
					mgr.commit(obj);
				}
			}
		}
	}	// END: sendInvitation

	public static String getAllLinkedMeetings(PstUserAbstractObject pstuser, meetingManager mMgr, String midS, boolean bAfterStart)
		throws PmpException
	{
		// return the list of meeting Ids (separated by colon) that are linked together with midS
		// Note: midS will be repeated once, but there is no harm for that

		// get those meetings that has midS in the Recurring attribute
		String ret = getAllPrevMeetings(pstuser, mMgr, midS, bAfterStart);

		// get those meetings in my Recurring string
		String nxt = getAllNextMeetings(pstuser, mMgr, midS, bAfterStart);
		if (nxt.length() > 0)
			ret += ";" + nxt;

		return ret;
	}

	private static String getAllPrevMeetings(PstUserAbstractObject pstuser, meetingManager mMgr, String midS, boolean bAfterStart)
		throws PmpException
	{
		String ret = "";
		String cond = "";
		if (bAfterStart)
			cond = "'&& Status!='" + meeting.NEW + "'";

		int [] ids = mMgr.findId(pstuser, "Recurring='%" + midS + cond);	// at most one return
		for (int i=0; i<ids.length; i++)
		{
			ret += getAllPrevMeetings(pstuser, mMgr, String.valueOf(ids[i]), bAfterStart);
			if (ret.length() > 0) ret += ";";
		}
		ret += midS;
		return ret;
	}

	private static String getAllNextMeetings(PstUserAbstractObject pstuser, meetingManager mMgr, String midS, boolean bAfterStart)
		throws PmpException
	{
		String ret = "";
		PstAbstractObject m = null;
		try {m = mMgr.get(pstuser, midS);}
		catch (PmpException e) {return "";}		// the meeting can be deleted thus break the link

		String s = (String)m.getAttribute("Status")[0];
		if (bAfterStart && s.equals(meeting.NEW))
			return "";		// reach the end (this meeting and any after has not started yet)

		s = (String)m.getAttribute("Recurring")[0];
		if (s != null)
		{
			String [] sa = s.split(meeting.DELIMITER);		// e.g. Weekly::1::12345
			if (sa.length > 2)
			{
				ret += getAllNextMeetings(pstuser, mMgr, sa[2], bAfterStart);
				if (ret.length() > 0) ret = ";" + ret;
			}
			ret = midS + ret;
		}
		return ret;
	}

	public static void sortAttInfoArray(Object [] oArr, String sortBy, boolean ignoreCase)
	{
		// AttInfo object has 4 Strings: attid; filename; author; dateS;
		AttInfo o1, o2;
		String v1, v2;
		boolean swap;
		if (sortBy.equals("fn"))
		{
			// filename
			do
			{
				swap = false;
				for (int i=0; i<oArr.length-1; i++)
				{
					o1 = (AttInfo)oArr[i];
					o2 = (AttInfo)oArr[i+1];
					try
					{
						v1 = o1.filename;
						v2 = o2.filename;
						int result;
						if (ignoreCase)
							result = v1.compareToIgnoreCase(v2);
						else
							result = v1.compareTo(v2);

						if (result > 0)
						{
							// swap the element
							oArr[i]   = o2;
							oArr[i+1] = o1;
							swap = true;
						}
					}
					catch (Exception e) {}
				}
			} while (swap);
		}
		else if (sortBy.equals("au"))
		{
			// owner/author
			do
			{
				swap = false;
				for (int i=0; i<oArr.length-1; i++)
				{
					o1 = (AttInfo)oArr[i];
					o2 = (AttInfo)oArr[i+1];
					try
					{
						v1 = o1.author;
						v2 = o2.author;
						int result;
						if (ignoreCase)
							result = v1.compareToIgnoreCase(v2);
						else
							result = v1.compareTo(v2);

						if (result > 0)
						{
							// swap the element
							oArr[i]   = o2;
							oArr[i+1] = o1;
							swap = true;
						}
					}
					catch (Exception e) {}
				}
			} while (swap);
		}
		else if (sortBy.equals("dt"))
		{
			// date
			// ECC: bug fix, date is not reliable because it is only mm/dd/yy.  Use attid is reliable.
			int i1, i2;
			do
			{
				swap = false;
				for (int i=0; i<oArr.length-1; i++)
				{
					o1 = (AttInfo)oArr[i];
					o2 = (AttInfo)oArr[i+1];
					try
					{
						i1 = Integer.parseInt(o1.attid);
						i2 = Integer.parseInt(o2.attid);

						if (i1 < i2)
						{
							// swap the element
							oArr[i]   = o2;
							oArr[i+1] = o1;
							swap = true;
						}
					}
					catch (Exception e) {}
				}
			} while (swap);
		}
	}

	// return true if the user dept string partially matches the deptname string
	public static boolean isAuthAttachmt(String myDeptS, String deptName)
	{
		if (deptName == null || deptName.trim().length()==0)
			return true;
		if (myDeptS == null || myDeptS.trim().length()==0)
			return false;

		String [] myDept = myDeptS.split("[@-]");
		String s;
		for (int i=0; i<myDept.length; i++)
		{
			s = myDept[i].trim();
			if (deptName.indexOf(s) != -1) return true;		// found
		}
		return false;	// not found
	}

	public static String postBlog(PstUserAbstractObject pstuser,
			String type, String objIdS, String projIdS, String subj, String msg)
		throws PmpException
	{
		return postBlog(pstuser, type, objIdS, projIdS, subj, msg, null);
	}
	
	public static String postBlog(PstUserAbstractObject pstuser,
			String type, String objIdS, String projIdS, String subj, String msg, String charsetName)
		throws PmpException
	{
		result blogObj = (result)rMgr.create(pstuser);

		// construct text
		if (subj != null)
		{
			msg = "<b>" + subj + "</b></p> " + msg;
		}

		String updatorIdS = String.valueOf(pstuser.getObjectId());
		Date now = new Date();
		blogObj.setAttribute("CreatedDate", now);
		blogObj.setAttribute("Creator", updatorIdS);
		blogObj.setAttribute("Type", type);
		blogObj.setAttribute("ProjectID", projIdS);						// @ECC061206
		blogObj.setAttribute("TaskID", objIdS);	// can be taskId, bugId, mtgId, userId, projId, townId (null for forum)
		try {
			blogObj.setAttribute("Comment", msg.getBytes("UTF-8"));
		}
		catch (UnsupportedEncodingException e) {
			throw new PmpException(e.getMessage());
		}
		rMgr.commit(blogObj);

		// create short text
		String stripText = msg.replaceAll("<\\S[^>]*>", "");		// strip HTML tag
		if (stripText.length() > 300) stripText = stripText.substring(0,300);
		stripText = stripText.replaceAll("&nbsp;", " ");	// replace &nbsp;
		stripText = pstuser.getObjectName() +":: " + stripText;
		int len = stripText.length();
		if (len > result.LRESULT_LENGTH) len = result.LRESULT_LENGTH;
		String shortText = stripText.substring(0,len);				// **** this is used below also

		// lastest result
		if (stripText!=null)
		{
			result.createOneLiner(pstuser, objIdS, String.valueOf(blogObj.getObjectId()), shortText, null, false);
		}

		// keep statistics
		Util.incUserinfo(pstuser, "WriteBlogNum");
		return blogObj.getObjectName();		// name and ID are the same for blog
	}

	// given a pstuser name, find its PictureFile name (e.g. jsmith.jpg) if any
	public static String findPictureName(PstUserAbstractObject pstuser, String uname)
	{
		// uObj is used to access db, our target is uname
		try
		{
			String picFile = (String)userManager.getInstance().get(pstuser, uname).getAttribute("PictureFile")[0];
			if (picFile == null)
				return uname;
			else
				return picFile;
		}
		catch (PmpException e) {return uname;}
	}

	public static String getPicURL(PstAbstractObject obj)
	{
		return getPicURL(obj, null);
	}
	public static String getPicURL(PstAbstractObject obj, String defaultPic)
	{
		if (obj == null) return "";
		try
		{
			String picURL = (String)obj.getAttribute("PictureFile")[0];
			if (picURL == null)
			{
				if (defaultPic == null) {
					if (DEFAULT_USER_PIC != null) {
						picURL = USER_PIC_URL + "/" + DEFAULT_USER_PIC;
					}
				}
				else {
					picURL = defaultPic;
				}
			}
			else {
				picURL = USER_PIC_URL + "/" + picURL;
			}
			return picURL;
		}
		catch (PmpException e) {return "";}
	}

	public static int [] toIntArray(Object [] oArr)
	{
		// take an object array (of Integer object) and return an int array
		if (oArr==null || oArr.length==0 || oArr[0]==null)
			return new int[0];
		int [] iArr = new int [oArr.length];
		if (oArr[0] instanceof Integer) {
			// Integer
			for (int i=0; i<oArr.length; i++)
				iArr[i] = ((Integer)oArr[i]).intValue();
		}
		else {
			// String
			String s;
			for (int i=0; i<oArr.length; i++) {
				s = (String) oArr[i];
				if (StringUtil.isNullOrEmptyString(s)) iArr[i] = -9999;
				else {
					iArr[i] = Integer.parseInt(s.trim());
				}
			}
		}
		return iArr;
	}

	public static int [] mergeIntArray(int [] iArr1, int [] iArr2)
	{
		// sort merge two int arrays: will eliminate duplicates
		int [] tempArr = new int [iArr1.length + iArr2.length];
		int ct = 0;
		for (int i=0; i<iArr1.length; i++)
			tempArr[ct++] = iArr1[i];
		for (int i=0; i<iArr2.length; i++)
			tempArr[ct++] = iArr2[i];
		Arrays.sort(tempArr);
		if (tempArr.length <= 1) return tempArr;

		// now elimiate duplicate
		ct = 1;
		int num = tempArr[0];
		for (int i=0; i<tempArr.length-1; i++)
		{
			if (num == tempArr[i+1])
			{
				tempArr[i+1] = -99999;	// can skip this cell
			}
			else
			{
				num = tempArr[i+1];
				ct++;
			}
		}

		// copy result back
		iArr1 = new int[ct];
		ct = 0;
		for (int i=0; i<tempArr.length; i++)
		{
			if (tempArr[i] != -99999)
				iArr1[ct++] = tempArr[i];
		}

		return iArr1;
	}

	public static int [] mergeJoin(int [] iArr1, int [] iArr2)
	{
		// return an int array that contains ONLY duplicates
		//System.out.println("len1=" + iArr1.length + ", len2="+iArr2.length);
		int [] tempArr = new int [iArr1.length + iArr2.length];
		int ct = 0;
		for (int i=0; i<iArr1.length; i++)
			tempArr[ct++] = iArr1[i];
		for (int i=0; i<iArr2.length; i++)
			tempArr[ct++] = iArr2[i];
		Arrays.sort(tempArr);
		if (tempArr.length <= 1) return (new int[0]);

		ct = 0;
		int num = tempArr[0];
		for (int i=0; i<tempArr.length-1; i++)
		{
			if (num != tempArr[i+1])
			{
				tempArr[i] = -99999;
				num = tempArr[i+1];
			}
			else
			{
				tempArr[i+1] = -99999;			// retain the first one, remove the second
				i++;
				ct++;
				while (i<tempArr.length-1 && tempArr[i+1]==num)
					tempArr[++i] = -99999;		// skip all the same one's
				if (i < tempArr.length-1)
					num = tempArr[i+1];			// get the next new number
			}
		}
		tempArr[tempArr.length-1] = -99999;		// always remove the last number

		//for (int i=0; i<tempArr.length; i++) System.out.print(tempArr[i] + ", ");
		//System.out.println();
		//System.out.println("ct=" + ct);
		if (ct <= 0) return (new int[0]);

		// copy result back
		iArr1 = new int[ct];
		ct = 0;
		for (int i=0; i<tempArr.length; i++)
		{
			if (tempArr[i] != -99999)
				iArr1[ct++] = tempArr[i];
		}

		return iArr1;
	}
	public static int [] outerJoin(int [] iArr1, int [] iArr2)
	{
		// return only those elements that don't match in the two arrays
		if (iArr1.length == 0)
			return iArr2;
		else if (iArr2.length == 0)
			return iArr1;
		
		
		int [] tempArr = new int [iArr1.length + iArr2.length];
		int ct = 0;
		for (int i=0; i<iArr1.length; i++)
			tempArr[ct++] = iArr1[i];
		for (int i=0; i<iArr2.length; i++)
			tempArr[ct++] = iArr2[i];
		Arrays.sort(tempArr);
		if (tempArr.length <= 1) return (new int[0]);

		ct = 0;
		int num = tempArr[0];
		for (int i=0; i<tempArr.length-1; i++)
		{
			if (num != tempArr[i+1])
			{
				// tempArr[i] is unique, retain it
				num = tempArr[i+1];
				ct++;
			}
			else
			{
				tempArr[i] = -99999;			// duplicates: remove element i
				while (i<tempArr.length-1 && tempArr[i+1]==num)
					tempArr[++i] = -99999;		// skip all the same one's
				if (i < tempArr.length-1)
					num = tempArr[i+1];			// get the next new number
			}
		}
		if (tempArr[tempArr.length-1] != -99999)
			ct++;

		//for (int i=0; i<tempArr.length; i++) System.out.print(tempArr[i] + ", ");
		//System.out.println();
		//System.out.println("ct=" + ct);
		if (ct <= 0) return (new int[0]);

		// copy result back
		iArr1 = new int[ct];
		ct = 0;
		for (int i=0; i<tempArr.length; i++)
		{
			if (tempArr[i] != -99999)
				iArr1[ct++] = tempArr[i];
		}

		return iArr1;
	}
	
	/**
	 * merge two email arrays, but the arrays can be email, userId (Integer or String), or username
	 * @param pstuser
	 * @param arr1
	 * @param arr2
	 * @return
	 */
	public static String [] mergeEmails(PstUserAbstractObject pstuser, Object [] arr1, Object [] arr2)
	{
		// take two arrays of String or Integer, can be userId, username or Email, convert
		// them all to emails and then merge them.  If only one array is pass, only convert
		ArrayList <String> retArrList = new ArrayList <String> ();
		String [] sArr = toEmailArray(pstuser, arr1);
		retArrList.addAll(Arrays.asList(sArr));
		
		sArr = toEmailArray(pstuser, arr2);
		retArrList.addAll(Arrays.asList(sArr));
		
		return retArrList.toArray(new String[0]);
	}
	
	/**
	 * convert an array of Integer (userId) or String (userId, username) to array of Email address
	 * @param pstuser
	 * @param arr
	 * @return
	 */
	public static String [] toEmailArray(PstUserAbstractObject pstuser, Object [] arr)
	{
		ArrayList <String> retArrList = new ArrayList<String>();
		Object o;
		String s;
		PstAbstractObject uObj;
		
		if (arr != null) {
			// convert to email if it is not
			for (int i=0; i<arr.length; i++) {
				o = arr[i];
				s = null;
				uObj = null;
				try {
					if (o instanceof Integer) {
						uObj = uMgr.get(pstuser, ((Integer)o).intValue());
					}
					else if (o instanceof String) {
						s = (String) o;
						if (s.indexOf('@') == -1) {
							try {
								int id = Integer.parseInt(s);
								uObj = uMgr.get(pstuser, id);
							}
							catch (Exception ee) {
								// username
								uObj = uMgr.get(pstuser, s);
							}
						}
					}
					if (uObj != null) {
						s = uObj.getStringAttribute("Email");
					}
					if (s != null)
						retArrList.add(s);			// got email
				}
				catch (Exception e) {continue;}
			}	// END for each array element
		}	// END if !null
		return retArrList.toArray(new String[0]);
	}
	
	public static PstAbstractObject [] shortenPstArray(PstAbstractObject [] arr, int len)
	{
		if (arr.length <= len) return arr;
		PstAbstractObject [] newArr = new PstAbstractObject [len];
		for (int i=0; i<len; i++) {
			newArr[i] = arr[i];
		}
		return newArr;
	}

	// append or insert the meeting link onto the event expression on ep_home.jsp
	public static void displayMeetingLink(PstUserAbstractObject u, PstAbstractObject mObj, StringBuffer sBuf)
		throws PmpException
	{
		Date startD, endD;
		String start, end;

		String mtgTitle = "<a class='listlink' href='../meeting/mtg_view.jsp?mid=" + mObj.getObjectId() + "'>"
			+ mObj.getStringAttribute("Subject") + "</a>";

		userinfo.setTimeZone(u, df2);
		userinfo.setTimeZone(u, df3);

		// adjust and display meeting time
		startD = (Date)mObj.getAttribute("StartDate")[0];
		//startD = new Date(startD.getTime());
		start = df2.format(startD);
		
		endD = (Date)mObj.getAttribute("ExpireDate")[0];
		//endD = new Date(endD.getTime());
		end = df3.format(endD);

		String str = "<div class='evt_mtg'>" + start + " - " + end + "<br>" + mtgTitle + "</div>";

		int idx;
		if ((idx = sBuf.indexOf("<MTG/>")) != -1)
			sBuf.replace(idx, idx+6, str);
		else
			sBuf.append(str);
	}

	public static String displayQuestLink(PstUserAbstractObject u, PstAbstractObject qObj, StringBuffer sBuf)
		throws PmpException
	{
		if (sBuf == null)
			sBuf = new StringBuffer();
		Date startD, endD;
		String start=null, end=null;

		userinfo.setTimeZone(u, df2);
		userinfo.setTimeZone(u, df3);

		String qTitle = "<a class='listlink' href='../question/q_respond.jsp?qid=" + qObj.getObjectId() + "'>"
			+ (String)qObj.getAttribute("Subject")[0] + "</a>";

		// adjust and display quest time
		startD = (Date)qObj.getAttribute("StartDate")[0];
		if (startD != null)
		{
			//startD = new Date(startD.getTime() + diff);
			start = df2.format(startD);
			endD = (Date)qObj.getAttribute("ExpireDate")[0];
			//endD = new Date(endD.getTime() + diff);
			end = df3.format(endD);
		}

		String str = "<div class='evt_mtg'>";

		if (startD != null) {
			str += start + " - " + end + "<br>";
		}
		str += qTitle + "</div>";

		int idx;
		if ((idx = sBuf.indexOf("<MTG/>")) != -1)
			sBuf.replace(idx, idx+6, str);
		else
			sBuf.append(str);
		return sBuf.toString();
	}

	public static String displayAnswerLink(PstUserAbstractObject pstuser, PstAbstractObject aObj, PstAbstractObject qObj)
		throws PmpException
	{
		StringBuffer sBuf = new StringBuffer();

		String qTitle = "<a class='listlink' href='../question/q_answer.jsp?aid=" + aObj.getObjectId() + "'>"
			+ (String)qObj.getAttribute("Subject")[0] + "</a>";

		sBuf.append("<div class='evt_mtg'>");
		sBuf.append(qTitle);
		sBuf.append("</div>");
		return sBuf.toString();
	}

	public static String visitors(PstUserAbstractObject me,
			PstManager mgr, int uid, int max, boolean isAdmin)
		throws PmpException
	{
		int myUid = me.getObjectId();
		String myUidS = String.valueOf(myUid);
		String uidS = String.valueOf(uid);
		boolean isCirclePage;

		PstAbstractObject obj;
		if (mgr instanceof townManager)
		{
			isCirclePage = true;
			obj = mgr.get(me, uid);			// uid is the townId
		}
		else
		{
			isCirclePage = false;
			obj = mgr.get(me, uidS);		// get userinfo object to display viewBy
		}

		String visitors = (String)obj.getAttribute("ViewBy")[0];

		// insert my uid into the recent visitor string
		if ( !isAdmin && (isCirclePage || myUid!=uid) )
		{
			// check to see if I am already on the visitors string
			visitors = visited(visitors, myUidS, max);
			obj.setAttribute("ViewBy", visitors);
			mgr.commit(obj);
		}

		// use the uids to construct name list
		String visitorNames = getNames(me, visitors, max);

		return visitorNames;
	}	// END: visitors()

	public static String visited(String visitors, String uidS, int max)
	{
		// receive an userids string and insert uidS into the head
		if (visitors==null || visitors.length()<=0)
			return uidS;

		int idx1, idx2;
		String s;
		if ((idx1 = visitors.indexOf(uidS)) != 0)		// idx1==0 means uid is already the last visitor
		{
			if (idx1 != -1)
			{
				// need to take out uidS and put it in front of the queue
				s = visitors.substring(0, idx1);		// copy till myUid
				idx2 = visitors.indexOf(";", idx1);
				if (idx2 != -1)
					s += visitors.substring(idx2+1);	// copy all uids after this
				visitors = s;							// result after cutting out uidS
			}

			// put myUid onto the visitor list
			if (visitors.length() > 0) visitors = ";" + visitors;
			visitors = uidS + visitors;				// insert uidS to the head of queue
		}

		// need to make sure I won't exceed max
		String [] sa = visitors.split(";");
		int len = sa.length;
		idx1 = visitors.length();
		while (len > max)
		{
			idx1 = visitors.lastIndexOf(";", idx1-1);
			len--;
		}
		if (idx1 < visitors.length())
			visitors = visitors.substring(0, idx1);
		return visitors;
	}

	public static String getNames(PstUserAbstractObject me, String visitors, int showNum)
	{
		// get recent accessed users of an object
		if (visitors == null)
			return "";
		String visitorNames="", s;
		StringBuffer sBuf = new StringBuffer();
		if (visitors.length() > 0)
		{
			String [] sa = visitors.split(";");
			if (sa.length > 0)
			{
				for (int i=0; i<sa.length; i++)
				{
					if (i > showNum) break;
					try {s = ((user)uMgr.get(me, Integer.parseInt(sa[i]))).getFullName();}
					catch (PmpException e) {continue;}
					if (i > 0) sBuf.append("&nbsp; . &nbsp;");
					sBuf.append("<a href='../ep/ep1.jsp?uid=" + sa[i] + "' class='listlink'>" + s + "</a>");
				}
				visitorNames = "<span style='font-weight:normal'>" + sBuf.toString() + "</span>";
			}
		}
		else
			visitorNames = "<span style='color:#999999; font-weight:normal'>&nbsp;None</span>";
		return visitorNames;
	}

	public static Date getLocalTime(Date dt)
	{
		// we should use user profile time zone to adjust
		/*if (dt == null) return null;
		long t = dt.getTime() + userinfo.getServerUTCdiff();
		return new Date(t);*/
		return userinfo.getLocalTime(dt);
	}

	public static String getUserPreference(PstUserAbstractObject pstuser, String pref)
	{
		String s, ret=null;
		try
		{
			PstAbstractObject ui = uiMgr.get(pstuser, String.valueOf(pstuser.getObjectId()));
			Object [] oArr = ui.getAttribute("Preference");
			for (int i=0; i<oArr.length; i++)
			{
				s = (String)oArr[i];
				if (s == null) continue;
				if (s.startsWith(pref))
				{
					ret = s.substring(s.indexOf(":")+1);
					break;
				}
			}
		} catch (PmpException e) {l.error("Exception in Util2:getUserPreference() for [" + pstuser.getObjectId() + "]");}
		return ret;
	}
	
	public static String getUserNoteBkgd(PstUserAbstractObject pstuser) {
		String style = "";
		String noteBkgd = getUserPreference(pstuser, "NoteBackground");
		if (noteBkgd != null)
		{
			// background and text color
			String [] sa = noteBkgd.split("\\?");
			style += " style='";
			if (sa[0].length() > 0)
				style += "background:url(" + sa[0] + ") repeat;";
			if (sa.length > 1)
				style += " color:" + sa[1];
			style += "'";				// close the style
		}
		return style;
	}

	public static void setUserPreference(PstUserAbstractObject pstuser, String pref, String val)
	{
		String s;
		try
		{
			PstAbstractObject ui = uiMgr.get(pstuser, String.valueOf(pstuser.getObjectId()));
			Object [] oArr = ui.getAttribute("Preference");
			for (int i=0; i<oArr.length; i++)
			{
				s = (String)oArr[i];
				if (s == null) continue;
				if (s.startsWith(pref))
				{
					ui.removeAttribute("Preference", oArr[i]);
					break;
				}
			}
			if (val!=null && val.length()>0)
				ui.appendAttribute("Preference", pref + ":" + val);
			uiMgr.commit(ui);
		} catch (PmpException e) {l.error("Exception in Util2:setUserPreference() for [" + pstuser.getObjectId() + "]");}
	}

	// display meeting and quest blog
	public static String displayBlog(PstUserAbstractObject pstuser, String idS, String typeS)
		throws PmpException, UnsupportedEncodingException
	{
		StringBuffer sBuf = new StringBuffer(8192);

		// list the meeting blogs if any
		// meeting blog label
		sBuf.append("<tr><td colspan='3'><img src='../i/spacer.gif' height='5'></td></tr>");
		sBuf.append("<tr><td>&nbsp;<a name='blog'></a></td><td colspan='2'>");

		boolean isMtgBlog = true;
		String label1 = "&nbsp;";
		if (typeS.equals(result.TYPE_MTG_BLOG))
			label1 += "Topic";
		else
		{
			isMtgBlog = false;
			label1 += "Content";
		}
		String [] label = {label1, "Author", "Replies", "View #", "Posted On"};
		int [] labelLen = {480, 80, 50, 50, 80};
		boolean [] bAlignCenter = {false, true, true, true, true};
		sBuf.append(Util.showLabel(label, labelLen, bAlignCenter, true));		// showAll and align center

		// get all FORUM parent blogs (Name != null)
		int [] ids = rMgr.findId(pstuser, "Type='" + typeS + "' && TaskID='" + idS + "'");
		if (ids.length <= 0) {
			return "";	// no blog: return with empty string
		}
		
		Arrays.sort(ids); 		// ascending order
		PstAbstractObject [] objList = rMgr.get(pstuser, ids);
		PstAbstractObject blog;
		String topic, author, authorIdS;
		Date dt;
		int replies, views, blogId;
		Integer iObj;
		Object bTextObj;
		String bText;

		String bgcolor="", lnk;
		boolean even = false;
		String param = "type=" + typeS + "&id=" + idS;	// typeS = result.TYPE_MTG_BLOG or TYPE_QUEST_BLOG

		for (int i=objList.length-1; i >= 0 ; i--)
		{
			// list all blogs from latest to oldest
			blog = objList[i];
			blogId = blog.getObjectId();
			topic = (String)blog.getAttribute("Name")[0];
			authorIdS = (String)blog.getAttribute("Creator")[0];
			dt = (Date)blog.getAttribute("CreatedDate")[0];

			ids = rMgr.findId(pstuser, "ParentID='" + blogId + "'");
			replies = ids.length;
			iObj = (Integer)blog.getAttribute("ViewBlogNum")[0];
			if (iObj != null)
				views = iObj.intValue();
			else
				views = 0;

			if (even) bgcolor = "bgcolor='#EEEEEE'";
			else bgcolor = "bgcolor='#ffffff'";
			even = !even;

			lnk = "<a class='listlink' href='../blog/blog_comment.jsp?blogId=" + blogId
					+ "&" + param + "'>";	// take out &view=1 to add ViewBlogNum

			// prepare to display the blog content
			StringBuffer contentBuf = new StringBuffer(1024);
			bTextObj = blog.getAttribute("Comment")[0];
			bText = (bTextObj==null)?"":new String((byte[])bTextObj, "utf-8");
			bText = bText.replaceAll("<\\S[^>]*>", "");		// strip HTML tag
			if (bText.length() > 300)
			{
				int idx = bText.indexOf(" ", 300);
				if (idx != -1)
					bText = bText.substring(0,idx);
				else
					bText = bText.substring(0, 300);
			}
			contentBuf.append("<td class='blog_text'>" + bText + " ... (" + lnk + "read more or respond</a>)</td>");

			sBuf.append("<tr " + bgcolor + ">");

			sBuf.append("<td></td>");
			sBuf.append("<td width='" + labelLen[0] + "'>");
			if (isMtgBlog)
			{
				// topic
				if (topic != null)
				{
					sBuf.append(lnk);
					sBuf.append(topic);
					sBuf.append("</a></td>");
				}
				else
					sBuf.append("<span class='plaintext_grey'>No topic</span></td>");
			}
			else
			{
				// content: quest blog
				sBuf.append("<table><tr>");
				sBuf.append("<td><img src='../i/spacer.gif' width='5' /></td>");
				sBuf.append(contentBuf);
				sBuf.append("<td><img src='../i/spacer.gif' width='5' /></td>");
				sBuf.append("</tr></table></td>");
			}

			// author
			author = (String)uMgr.get(pstuser, Integer.parseInt(authorIdS)).getAttribute("FirstName")[0];
			sBuf.append("<td colspan='2'></td>");
			sBuf.append("<td align='center' valign='top' width='" + labelLen[1] + "'>");
			sBuf.append("<a class='listlink' href='../ep/ep1.jsp?uid=" + authorIdS + "'>");
			sBuf.append(author);
			sBuf.append("</a></td>");

			// replies
			sBuf.append("<td colspan='2'></td>");
			sBuf.append("<td class='plaintext' align='center' valign='top' width='" + labelLen[2] + "'>");
			sBuf.append(replies);
			sBuf.append("</td>");

			// views
			sBuf.append("<td colspan='2'></td>");
			sBuf.append("<td class='plaintext' align='center' valign='top' width='" + labelLen[3] + "'>");
			sBuf.append(views);
			sBuf.append("</td>");

			// posted date
			sBuf.append("<td colspan='2'></td>");
			sBuf.append("<td class='plaintext' align='center' valign='top' width='" + labelLen[4] + "'>");
			sBuf.append(df1.format(dt));
			sBuf.append("</td>");

			sBuf.append("</tr>");

			// content
			if (isMtgBlog)
			{
				sBuf.append("<tr " + bgcolor + "><td colspan='14'><table><tr>");
				sBuf.append("<td><img src='../i/spacer.gif' width='40' /></td>");
				sBuf.append(contentBuf);
				sBuf.append("<td><img src='../i/spacer.gif' width='40' /></td>");
				sBuf.append("</tr></table></td></tr>");
			}

			sBuf.append("<tr " + bgcolor + ">" + "<td colspan='14'><img src='../i/spacer.gif' width='2' height='2'></td></tr>");
		}

		if (objList.length <= 0)
			sBuf.append("<tr><td colspan='17' class='plaintext_grey'>&nbsp;&nbsp;None</td></tr>");
		sBuf.append("</table>");		// close table from Util.showLabel()
		return sBuf.toString();
	}

    // getOwnerFullName(): return the owner's FirstName and the LastName initial
    public static String getOwnerFullName(PstUserAbstractObject u, PstAbstractObject obj, String attName)
    	throws PmpException
    {
    	if (attName == null) attName = "Owner";
    	String idS = (String)obj.getAttribute(attName)[0];
    	if (idS.equals("-1"))
    		return "-";

		PstAbstractObject o = uMgr.get(u, Integer.parseInt(idS));
    	return ((user)o).getFullName();
    }

    public static void sendUserWelcome(PstUserAbstractObject gUser, String app, String uname, String pass, String email)
    {
		boolean isCRAPP = (app.indexOf("CR")!=-1);
		String subj = "[" + app+ "] Welcome to " + app;
		String msg= "A new user account has been created for you.  Please use the following Username and Password to login:";
		msg += "<blockquote><table>Username: <b>" + uname;
		msg += "</b><br>Password: <b>" + pass;
		msg += "</b></table></blockquote>";
		if (!isCRAPP)
		{
			msg += "On your first login you would be asked to change your password.  A valid password is 6-12 characters long with at least one numeric and one alphabet characters. ";
			msg += "<br><br>Please click this link to login:&nbsp;&nbsp;";
			msg += "<b><a href='" + NODE + "'>" + NODE + "</a></b>";
			msg += "<br><br>For a quick start, check out ";
			msg += "<b><a href='" + NODE + "/file/common/PRM Simple Instructions.doc'>PRM Simple Instructions.doc</a></b>";
		}
		else
		{
			msg += "<br><br>Please click this link to login:&nbsp;&nbsp;";
			msg += "<a href='" + NODE + "'>" + NODE + "</a>";
			msg += "<br><br>You can edit your password and personal profile after you login.";
		}

		Util.sendMailAsyn(gUser, FROM, email, null, FROM, subj, msg, MAILFILE);

    }

	/**
		Partial match the val (contains) with the existing multiple values of the attribute
	*/
	public static String matchAttribute(PstAbstractObject obj, String attName, String val)
		throws PmpException
	{
		Object [] varArr = obj.getAttribute(attName);
		for (int i=0; i<varArr.length; i++)
		{
			if (varArr[i] == null) break;
			if (((String)varArr[i]).contains(val))
				return (String)varArr[i];	// return first match
		}
		return null;
	}

    public static boolean foundAttribute(PstAbstractObject obj, String attName, String oldVal)
		throws PmpException
    {
		Object [] varArr = obj.getAttribute(attName);
		for (int i=0; i<varArr.length; i++)
		{
			if (varArr[i] == null) break;
			if (((String)varArr[i]).startsWith(oldVal))
				return true;	// found match
		}
		return false;
    }

    public static boolean foundAttribute(PstAbstractObject obj, String attName, int iVal)
		throws PmpException
    {
		Object [] varArr = obj.getAttribute(attName);
		for (int i=0; i<varArr.length; i++)
		{
			if (varArr[i] == null) break;
			if (((Integer)varArr[i]).intValue() == iVal)
				return true;	// found match
		}
		return false;
    }

    public static String removeAttribute(PstAbstractObject obj, String attName, String matchVal)
    	throws PmpException
    {
    	// multi-value attribute function
    	// find the attribute value that starts with oldVal, remove it and replace it with the newVal
    	String oldVal = null;
		Object [] varArr = obj.getAttribute(attName);
		for (int i=0; i<varArr.length; i++)
		{
			if (varArr[i] == null) break;
			if (((String)varArr[i]).startsWith(matchVal))
			{
				// found the backup area info
				oldVal = (String)varArr[i];
				obj.removeAttribute(attName, varArr[i]);
				break;
			}
		}
		return oldVal;
    }

    public static void replaceAttribute(PstAbstractObject obj, String attName, String oldVal, String newVal)
    	throws PmpException
    {
    	removeAttribute(obj, attName, oldVal);
		obj.appendAttribute(attName, newVal);
    }

    // return the multiple value separated by the separator
    public static String getAttributeString(PstAbstractObject obj, String attName, String separator)
		throws PmpException
    {
    	String res = "";	// return empty string if there is no value
    	Object [] valArr = obj.getAttribute(attName);
    	for (int i=0; i<valArr.length; i++)
    	{
    		if (valArr[i] == null) break;
    		if (res.length() > 0) res += separator;
    		res += valArr[i].toString();
    	}
    	return res;
    }

    public static void sortDirectory(File [] fList)
    {
    	if (fList == null) return;
		File o1, o2;
		boolean swap;
		do
		{
			swap = false;
			for (int i=0; i<fList.length-1; i++)
			{
				o1 = fList[i];
				o2 = fList[i+1];
				if (o2.isDirectory() && o1.isFile())
				{
					// swap the element
					fList[i]   = o2;
					fList[i+1] = o1;
					swap = true;
				}
			}
		} while (swap);
    }

    public static void sortFiles(File [] fList, String sortby)
    {
    	if (fList == null) return;
		File o1, o2;
		String s1, s2;
		boolean swap;
		do
		{
			swap = false;
			for (int i=0; i<fList.length-1; i++)
			{
				o1 = fList[i];
				if (o1.isDirectory()) continue;

				o2 = fList[i+1];
				if (sortby.equals("sz")
						&& o1.length() > o2.length())
				{
					swap = true;
				}
				else if (sortby.equals("dt")
						&& o1.lastModified() < o2.lastModified())
				{
					swap = true;
				}
				else if (sortby.equals("ty"))
				{
					s1 = getExt(o1);
					s2 = getExt(o2);
					if (s1 != null)
					{
						if (s2==null || s1.compareTo(s2)>0)
							swap = true;
					}
				}
				else if (sortby.equals("nm")
						&& o1.getName().compareTo(o2.getName())>0)
				{
					swap = true;
				}
				if (swap)
				{
					fList[i]   = o2;
					fList[i+1] = o1;
				}
			}
		} while (swap);
    }

    public static String getExt(File fObj)
    {
    	int idx;
		String ext = fObj.getName();
		if ((idx = ext.lastIndexOf(".")) != -1)
			ext = ext.substring(idx+1);
		else
			ext = null;		// no ext
		return ext;
    }

    public static String getSizeDisplay(int iSize, int min)
    {
    	// pass in size in MB and display either MB or GB
    	String sizeS = null;

		if (iSize <= 0)
			sizeS = min + " MB";
		else if (iSize >= 1000)
		{
			BigDecimal bd = new BigDecimal(iSize);
			bd = bd.movePointLeft(3);
			bd = bd.setScale(1, BigDecimal.ROUND_HALF_UP);
			sizeS = bd.toString() + " GB";
		}
		else
			sizeS = iSize + " MB";

		return sizeS;
    }

    public static String fileSizeDisplay(long size)
    {
    	String sizeS = "-";
		if (size > 1000000)
		{
			BigDecimal bd = new BigDecimal(size);
			bd = bd.movePointLeft(6);
			bd = bd.setScale(1, BigDecimal.ROUND_HALF_UP);
			sizeS = bd.toString() + " MB";
		}
		else if (size > 1000)
			sizeS = size/1000 + " KB";
		else if (size > 0)
			sizeS = String.valueOf(size) + " B";
		return sizeS;
    }

	public static boolean checkSpace(PstUserAbstractObject pstuser, int uid, String msg)
		throws PmpException
	{
		// check the space for a user.  If no space left, send email to user.
		// if msg is null, don't send email, otherwise append it to end of message body.
		PstAbstractObject uObj = uMgr.get(pstuser, uid);
		int iTotal = ((Integer)uObj.getAttribute("SpaceTotal")[0]).intValue();
		int iUsed  = ((Integer)uObj.getAttribute("SpaceUsed")[0]).intValue();
		if (iTotal == 0)
			iTotal = DEFAULT_TOTAL_SPACE;

		if ((iTotal - iUsed) <= 0 )
		{
			if (msg == null)
				return false;		// no sending of email

			// send email
			String total = Util2.getSizeDisplay(iTotal, 100);
			String used = Util2.getSizeDisplay(iUsed, 0);
			String free = Util2.getSizeDisplay(iTotal-iUsed, 0);

			String subj = "[" + Prm.getAppTitle() + "] Info on your remote space";
			String emsg = "Your remote space distribution is shown below:";
			emsg += "<blockquote><table>";
			emsg += "<tr><td class='plaintext'>Total remote space:</td><td class='plaintext'>" + total + "</td></tr>";
			emsg += "<tr><td class='plaintext'>Space used:</td><td class='plaintext'>" + used + "</td></tr>";
			emsg += "<tr><td class='plaintext'>Space free:</td><td class='plaintext'>" + free + "</td></tr>";
			emsg += "</table></blockquote>";
			emsg += "Click the link to add more space<br>";
			emsg += "<a href='" + NODE + "' class='listlink'>Manage CR remove space</a><br><br>";
			emsg += msg;
			Util.sendMailAsyn(pstuser, FROM, (String)uObj.getAttribute("Email")[0], null, FROM, subj, msg, MAILFILE);
			return false;	// no space left
		}
		return true;
	}

	// look at the stored space used in projects and in upload areas, sum them up and put them in the user's
	// SpaceUsed attribute, in MB
	public static int updateSpaceUsed(PstUserAbstractObject u)
	{
		int iTotal = 0;		// in MB

		try
		{
			// 1.  get all project space
			project pj;
			int iSize;
			int [] ids = pjMgr.findId(u, "Owner='" + u.getObjectId() + "'");
			for (int i=0; i<ids.length; i++)
			{
				pj = (project)pjMgr.get(u, ids[i]);
				iSize = ((Integer)pj.getAttribute("SpaceUsed")[0]).intValue();
				iTotal += iSize;
			}

			// 2.  now get the upload area space
			Object [] oArr = u.getAttribute("Backup");	// get it from DB, not cache
			String sizeS;
			int idx;
			for (int i=0; i<oArr.length; i++)
			{
				if (oArr[i] == null) break;
				sizeS = (String)oArr[i];	// peace$C:/Temp/folder1?@ADMIN;ENGR?#278 or peace$C:/Temp/folder1?#278
				if ((idx = sizeS.indexOf("?#")) != -1)
				{
					// extract size info
					sizeS = sizeS.substring(idx+2);		// ignore "?#" and get size value.  e.g. 278 (in MB)
					iTotal += Integer.parseInt(sizeS);
				}
			}

			//  3.  store iTotal back into user's SpaceUsed
			u.setAttribute("SpaceUsed", new Integer(iTotal));
			uMgr.commit(u);

			l.info("Update SpaceUsed for user [" + u.getObjectName() + "] - space used = " + iTotal + "MB");

			return iTotal;		// in MB
		}
		catch (PmpException e) {return 0;}
	}

	// return the MB under the parameter file/dir
	public static int getSize(File fObj)
	{
		long size;
		if (fObj.isDirectory())
		{
			// recursive call to get size of all files
			int iSize = 0;
			File [] fList = fObj.listFiles();
			for (int i=0; i<fList.length; i++)
				iSize +=  getSize(fList[i]);
			return iSize;
		}
		size = fObj.length();
		if (size <= 1000000)
			size = 1;
		else
			size = size/1000000;
		return (int)size;
	}

	/**
	 * add a string item to a list of items separated by the delimiter
	 * @param strList
	 * @param item
	 * @param delim
	 * @return
	 */
	public static String addSubString(String strList, String item, String delim)
	{
		// if the item is not found in the strList, add it to the strList and return it
		if (StringUtil.isNullOrEmptyString(strList)) return item;		// only element now
		if (StringUtil.isNullOrEmptyString(item)) return strList;
		
		String [] sa = strList.split(delim);
		for (int i=0; i<sa.length; i++) {
			if (sa[i].equals(item)) {
				// found: item already on the strList
				return strList;
			}
		}
		
		// come to this point means not found, add it to the end
		strList += delim + item;
		return strList;
	}

	public static String removeSubString(String strList, String item, String delim)
	{
		// remove an item from the strlist if it is found, otherwise do nothing
		if (StringUtil.isNullOrEmptyString(strList)) return "";		// not found
		if (StringUtil.isNullOrEmptyString(item)) return strList;
		
		boolean bFound = false;
		String [] sa = strList.split(delim);
		for (int i=0; i<sa.length; i++) {
			if (sa[i].equals(item)) {
				// found item: remove it
				sa[i] = null;
				bFound = true;
				break;
			}
		}
		
		if (bFound) {
			strList = "";
			for (int i=0; i<sa.length; i++) {
				if (sa[i] == null) continue;		// skip (remove)
				strList += sa[i];
				if (i < sa.length-1) strList += delim;
			}
		}
		
		if (strList.endsWith(delim)) {
			strList = strList.substring(0, strList.length()-delim.length());
		}
		
		return strList;
	}

}
