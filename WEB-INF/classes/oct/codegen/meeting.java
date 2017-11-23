
//
//  Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//	Licensee of FastPath (tm) is authorized to change, distribute
//	and resell this source file and the compliled object file,
//	provided the copyright statement and this statement is included
//	as header.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   meeting.java
//  Author: FastPath CodeGen Engine
//  Date:   03.18.2004
//  Description:
//		Implementation of meeting class
//  Modification:
//		@030904ECC	Created template file for class representation of OMM Organization.
//		@033004ECC	Support appending single data value to multiple data attribute.
//		@AGQ081706	Ignore Case for String Object
//		@SWS092806  Delete action item with its blogs and attachments once meeting gets 
//					to be deleted and action item does not associate with any projects.
//
/////////////////////////////////////////////////////////////////////
//
// meeting.java : implementation of the meeting class
//

package oct.codegen;

import java.io.File;
import java.io.FileOutputStream;
import java.io.FilenameFilter;
import java.io.IOException;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Comparator;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.SimpleTimeZone;
import java.util.TimeZone;

import oct.omm.client.OmsMember;
import oct.omm.client.OmsOrganization;
import oct.omm.client.OmsSession;
import oct.pmp.exception.PmpCommitObjectException;
import oct.pmp.exception.PmpDeleteObjectException;
import oct.pmp.exception.PmpException;
import oct.pmp.exception.PmpInternalException;
import oct.pmp.exception.PmpInvalidAttributeException;
import oct.pmp.exception.PmpManagerCreationException;
import oct.pmp.exception.PmpObjectCreationException;
import oct.pmp.exception.PmpObjectException;
import oct.pmp.exception.PmpRawGetException;
import oct.pmp.exception.PmpTypeMismatchException;
import oct.pmp.exception.PmpUnsupportedTypeException;
import oct.pst.PstAbstractObject;
import oct.pst.PstTimeAbstractObject;
import oct.pst.PstUserAbstractObject;
import oct.util.file.MyFileFilter;
import util.Util;

/**
*
* <b>General Description:</b>  meeting extends PmpAbstractObject.  This class
* encapsulates the data of a member from the "meeting" organization.
*
* The meeting class provides a facility to modify data of an existing meeting object.
*
*
*
* <b>Class Dependencies:</b>
*   oct.custom.meetingManager
*   oct.pmp.PmpUser
*   oct.pmp.PmpUserManager
*
*
* <b>Miscellaneous:</b> There are methods that will be deprecated in future versions.
*
*/


public class meeting extends PstTimeAbstractObject

{

	// static values
	public final static String DELIMITER	= "::";
	public final static int MAX_ATT			= 200;	// max attendees
	public final static int ERR_ALREADY_LIVE = -1;
	public final static int ERR_WRONG_PREV_STATE = -2;

	// meeting state
	public final static String NEW		= "New";
	public final static String LIVE		= "Live";
	public final static String FINISH	= "Finish";
	public final static String EXPIRE	= "Expire";
	public final static String COMMIT	= "Close";
	public final static String ABORT	= "Cancel";
	public static final String [] STATE_ARRAY	= {NEW, LIVE, FINISH, EXPIRE, COMMIT, ABORT};

	// recurring value
	public final static String DAILY_NOWKEN	= "Daily - weekdays only";
	public final static String DAILY		= "Daily";
	public final static String WEEKLY		= "Weekly";
	public final static String MONTHLY		= "Monthly";
	public final static String BIWEEKLY		= "Bi-weekly";
	public final static String BIMONTHLY	= "Bi-monthly";
	public final static String [] RECUR_ARR	= {DAILY_NOWKEN, DAILY, WEEKLY, MONTHLY};

	public final static String OCCASIONAL	= "Occasional";

	// attendee state
	// e.g. 12345::MandatoryAcceptPresent   12345::OptionalLogonPresent
	public final static String ATT_MANDATORY	= "Mandatory";
	public final static String ATT_OPTIONAL		= "Optional";
	public final static String ATT_ACCEPT		= "Accept";
	public final static String ATT_DECLINE		= "Decline";
	public final static String ATT_PRESENT		= "Present";
	public final static String ATT_LOGON		= "Logon";		// the person logon with a computer

	public final static String CATEGORY	= "Category";
	public final static String TYPE		= "Type";
	public final static String PUBLIC 	= "Public";
	public final static String PRIVATE 	= "Private";
	public final static String PUBLIC_READ_URL = "PublicRead";	// anyone can read with the meeting URL
	public final static String COMPANY 	= "Company";			// company meeting, seen by same company
	
	public final static String GUESTEMAILS 	= "GuestEmails";
	public final static String ATTENDEE 	= "Attendee";
	public final static String RECORDER		= "Recorder";
	public final static String NOTE			= "Note";
	
	public final static int	iAGENDA_NONE	= -1;
	public final static int	iAGENDA_ALL		= -2;
	
    //Private attributes


    static meetingManager manager;

    /**
     * Constructor for instantiating a new meeting.
     * @param member An OmsMember representing a meeting.
     */
    public meeting(OmsMember member)
    {
        super(member);
        try
        {
            manager = meetingManager.getInstance();
        }
        catch(PmpException pe)
        {
            //throw new PmpInternalException("Error getting meetingManager instance.");
        }
    }//End Constructor





    /**
     * Constructor for instantiating a new meeting.
     * @param userObj A PmpUesr.
     * @param org An organization.
     * @param memberName The name of the member.
     * @param password The password of the member.
     */
	meeting(PstUserAbstractObject userObj, OmsOrganization org, String memberName, String password)
		throws PmpException
	{
		super(userObj, org, memberName, password);
	}



    /**
     * Constructor for creating a meeting.  Used by meetingManager.
     * @param userObj A PmpUser.
     * @param org The OmsOrganization for the meeting.
     */
    meeting(PstUserAbstractObject userObj, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
		super(userObj, org, "");
		try
		{
			manager = meetingManager.getInstance();
		}
		catch(PmpManagerCreationException pe)
		{
			throw new PmpInternalException("Error getting meetingManager instance.");
		}
    }//End Constructor

    /**
     * Constructor for creating a meeting.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the meeting.
     */
    meeting(OmsSession session, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, "");
         try
         {
            manager = meetingManager.getInstance();
         }
         catch(PmpManagerCreationException pe)
         {
             throw new PmpInternalException("Error getting meetingManager instance.");
         }
    }//End Constructor

    /**
     * Constructor for creating a meeting using a member name.
     * @param userObj A PmpUser.
     * @param org The OmsOrganization for the meeting.
     * @param meetingMemName The member name for the created meeting.
     */
    meeting(PstUserAbstractObject userObj, OmsOrganization org, String meetingMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(userObj, org, meetingMemName, null);
        try
        {
          manager = meetingManager.getInstance();
        }
        catch(PmpManagerCreationException pe)
        {
            throw new PmpInternalException("Error getting meetingManager instance.");
        }
    }//End Constructor

    /**
     * Constructor for creating a meeting using a member name.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the meeting.
     * @param companyMemberName The member name for the created meeting.
     */
    meeting(OmsSession session, OmsOrganization org, String meetingMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, meetingMemName, null);
        try
        {
           manager = meetingManager.getInstance();
        }
        catch(PmpManagerCreationException pe)
        {
            throw new PmpInternalException("Error getting meetingManager instance.");
        }
    }//End Constructor


    /**
     * Currentyly Not Implemented.
     * Determine whether attribute is settable.
     * @param attributeName Name of attribute.
     */
    private boolean isSetAuthorized(String attributeName)
    {
        return true;

    }//End isSetAuthorized

    /**
     * Set attribute value.
     * @param attributeId The attribute id.
     * @param attributeValue The single value to set the attribute to.
     * @exception PmpInvalidAttributeException The attribute is invalid.
     * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
     * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
     * @exception PmpInteralException An internal error occurred.
     */
    public void setAttribute(int attributeId, Object attributeValue)
        throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
    {
        String attributeName = manager.getAttributeName(attributeId);
        setAttribute(attributeName, attributeValue, false);
    }//End setAttribute

    /**
     * Set attribute of multiple values.  Does not support setting raw datatype with multiple values.
     * @param attributeId The attribute id.
     * @param attributeValues The array of values to set the attribute to.
     * @exception PmpInvalidAttributeException The attribute is invalid.
     * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
     * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
     * @exception PmpInteralException An internal error occurred.
     */
    public void setAttribute(int attributeId, Object [] attributeValues)
        throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
    {
        String attributeName = manager.getAttributeName(attributeId);
        setAttribute(attributeName, attributeValues);
    }//End setAttribute

    /**
     * Append attribute value.
     * @param attributeId The attribute id.
     * @param attributeValue The single value to set the attribute to.
     * @exception PmpInvalidAttributeException The attribute is invalid.
     * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
     * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
     * @exception PmpInteralException An internal error occurred.
     */
    public void appendAttribute(int attributeId, Object attributeValue)
        throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
    {
        String attributeName = manager.getAttributeName(attributeId);
        setAttribute(attributeName, attributeValue, true);
    }//End setAttribute

    /**
     * Append attribute value.
     * @param attributeName The attribute name.
     * @param attributeValue The single value to set the attribute to.
     * @exception PmpInvalidAttributeException The attribute is invalid.
     * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
     * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
     * @exception PmpInteralException An internal error occurred.
     */
    public void appendAttribute(String attributeName, Object attributeValue)
        throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
    {
		setAttribute(attributeName, attributeValue, true);
	}

    /**
     * Set attribute value.
     * @param attributeName The attribute name.
     * @param attributeValue The single value to set the attribute to.
     * @exception PmpInvalidAttributeException The attribute is invalid.
     * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
     * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
     * @exception PmpInteralException An internal error occurred.
     */
    public void setAttribute(String attributeName, Object attributeValue)
        throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
    {
		setAttribute(attributeName, attributeValue, false);
	}


    /**
     * Set attribute value.
     * @param attributeName The attribute name.
     * @param attributeValue The single value to set the attribute to.
     * @param bAppend True if the attribute value is to append to the current value list
     * @exception PmpInvalidAttributeException The attribute is invalid.
     * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
     * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
     * @exception PmpInteralException An internal error occurred.
     */
    protected void setAttribute(String attributeName, Object attributeValue, boolean bAppend)
        throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
    {
        if(! manager.isValueValid(attributeName, attributeValue))
        {
            throw new PmpTypeMismatchException("Attribute value has an incorrect type.");
        }

        if(isSetAuthorized(attributeName) == false)
        {
            throw new PmpInvalidAttributeException("Not authorized to set.");
        }

        if(manager.getAttributeType(attributeName) == RAW)
        {
            if(attributeValue instanceof byte[] || attributeValue==null)
            {
                super.setRawData(attributeName, (byte [])attributeValue);
            }
            else
            {
                throw new PmpTypeMismatchException("Data is not of RAW type.");
            }
        }
        else
        {
            super.setData(attributeName, attributeValue, bAppend);	// support appending data
        }

    }//End setAttribute

    /**
     * Set attribute of multiple values.  Does not support setting raw datatype with multiple values.
     * @param attributeName The attribute name.
     * @param attributeValues The array of values to set the attribute to.
     * @exception PmpInvalidAttributeException The attribute is invalid.
     * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
     * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
     * @exception PmpInteralException An internal error occurred.
     */
    public void setAttribute(String attributeName, Object [] attributeValues)
        throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
    {
        if(! manager.isValueValid(attributeName, attributeValues))
        {
            throw new PmpTypeMismatchException("Attribute values has an incorrect type.");
        }
        else if(manager.getAttributeType(attributeName)== RAW)
        {
            //Delete raw data value if null
            if(attributeValues == null)
            {
                super.setRawData(attributeName,null);
            }
            else
            {
                throw new PmpUnsupportedTypeException("Raw data with multiple values is not supported.");
            }
        }

        if(isSetAuthorized(attributeName) == false)
        {
            throw new PmpInvalidAttributeException("Not authorized to set.");
        }

        super.setData(attributeName, attributeValues);

    }//End setAttribute

    /**
     * Remove an attribute value from a multi-value attribute.
     * @param attributeName The attribute name.
     * @param attributeValue The single value to be remove from the list.
     * @exception PmpInvalidAttributeException The attribute is invalid.
     * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
     * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
     * @exception PmpInteralException An internal error occurred.
     */
    public void removeAttribute(String attributeName, Object attributeValue)
        throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
    {
        if(! manager.isValueValid(attributeName, attributeValue))
        {
            throw new PmpTypeMismatchException("Attribute value has an incorrect type.");
        }

        if(manager.getAttributeType(attributeName) == RAW)
        {
            throw new PmpUnsupportedTypeException("This API does not support RAW datatype.");
        }
        else
        {
            super.removeData(attributeName, attributeValue);
        }

    }//End removeAttribute
// @AGQ081706    
    /**
     * Remove an attribute value from a multi-value attribute.
     * @param attributeName The attribute name.
     * @param attributeValue The single value to be remove from the list.
     * @exception PmpInvalidAttributeException The attribute is invalid.
     * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
     * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
     * @exception PmpInteralException An internal error occurred.
     */    
    public void removeAttributeIgnoreCase(String attributeName, Object attributeValue)
        throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
    {
        if(! manager.isValueValid(attributeName, attributeValue))
        {
            throw new PmpTypeMismatchException("Attribute value has an incorrect type.");
        }

        if(manager.getAttributeType(attributeName) == RAW)
        {
            throw new PmpUnsupportedTypeException("This API does not support RAW datatype.");
        }
        else
        {
            super.removeDataIgnoreCase(attributeName, attributeValue);
        }

    }//End removeAttribute

    /**
     * Get the attribute value.
     * @param attributeId The attribute id.
     * @exception PmpInvalidAttributeException The attribute does not exist.
     * @exception PmpRawGetException An error occurred obtaining the raw data.
     * @exception PmpInteralException An internal error occurred.
     * @return A non-empty array of Object values for that attribute.
     */
    public Object [] getAttribute(int attributeId)
        throws PmpObjectException, PmpManagerCreationException, PmpInvalidAttributeException, PmpRawGetException, PmpInternalException, PmpException
    {
        String attributeName = manager.getAttributeName(attributeId);
        return getAttribute(attributeName);
    }//End getAttribute

    /**
     * Get the attribute value.
     * @param attributeName The attribute name.
     * @exception PmpInvalidAttributeException The attribute does not exist.
     * @exception PmpRawGetException An error occurred obtaining the raw data.
     * @exception PmpInteralException An internal error occurred.
     * @return A non-empty array of Object values for that attribute.
     */
    public Object [] getAttribute(String attributeName)
        throws PmpObjectException, PmpManagerCreationException, PmpInvalidAttributeException, PmpRawGetException, PmpInternalException, PmpException
    {
        if(manager.getAttributeType(attributeName) == RAW)
        {
            byte [] rawResult = super.getRawData(attributeName);
            Object [] finalResult = new Object[1];
            finalResult[0] = rawResult;
            return finalResult;
        }

        if(manager.hasMultipleValues(attributeName))
        {
            return super.getMultipleData(attributeName, manager.getAttributeType(attributeName));
        }
        else
        {
            Object [] finalResult = new Object[1];
            finalResult[0] = super.getSingleData(attributeName, manager.getAttributeType(attributeName));
            return finalResult;
        }

    }//End getAttribute

	//////////////////////////////////////////////
	// Specialized functions only for meeting
	//
	public String getAgendaString()
        throws PmpException
	{
		return getAgendaString(true);
	}

	public String getAgendaString(boolean bHTML)
        throws PmpException
	{
		// get agenda items
		String bText = "";
		String P = null;
		String ENDP = null;
		String BREAK = null;
		String SP = null;

		if (bHTML)
		{
			P = "<p>";
			ENDP = "</p>";
			BREAK = "<br>";
			SP = "&nbsp;";
		}
		else
		{
			P = "=0D=0A=0D=0A";
			ENDP = "";
			BREAK = "=0D=0A";
			SP = " ";
		}

		Object [] agendaArr = getAttribute("AgendaItem");
		if (agendaArr==null || agendaArr.length<1 || agendaArr[0]==null)
			return bText;		// no agenda

		Arrays.sort(agendaArr, new Comparator <Object> ()
		{
			public int compare(Object o1, Object o2)
			{
				try{
				String [] sa1 = ((String)o1).split(meeting.DELIMITER);
				String [] sa2 = ((String)o2).split(meeting.DELIMITER);
				int i1 = Integer.parseInt(sa1[0]);	// pre-order
				int i2 = Integer.parseInt(sa2[0]);	// pre-order
				return ((i1>i2)?1:0);
				} catch(Exception e) {return 0;}
			}
		});

		int order, level;
		String[] levelInfo = new String[10];
		String[] sa;
		String itemName, s;
		for (int i=0; i<agendaArr.length; i++)
		{
			s = (String)agendaArr[i];			// (order::level::item::duration::owner)
			sa = s.split(meeting.DELIMITER);
			order = Integer.parseInt(sa[1]);
			level = Integer.parseInt(sa[2]);
			itemName = sa[3];

			// displace each item on a line
			order++;
			if (level == 0)
			{
				levelInfo[level] = String.valueOf(order);
				if (bText.length() == 0)
					bText = P;
				else
					bText += ENDP + BREAK + P;
			}
			else
			{
				levelInfo[level] = levelInfo[level - 1] + "." + order;
			}

			s = levelInfo[level] + SP + SP;
			s += itemName + BREAK;
			bText += s;
		}
		bText += ENDP;
		return bText;
	}

	// setStatus() for meeting
	public synchronized int setStatus(PstUserAbstractObject u, String state)
        throws PmpException
	{
		// set the meeting status and return a return code
		// 0 = successful

		String currentSt = (String)getAttribute("Status")[0];

		if (state.equals(LIVE))
		{
			// only one person can move meetint only from NEW to LIVE
			if (!currentSt.equals(NEW))
			{
				if (currentSt.equals(LIVE))
					return ERR_ALREADY_LIVE;
				else
					return ERR_WRONG_PREV_STATE;
			}
		}
		setAttribute("Status", state);
		manager.commit(this);

		return 0;
	}

	public void createVCS()
        throws IOException, PmpException, ParseException
	{
		// create a vCalendar file for this meeting event
		// if the file already exist, overwrite it
		String CAL_FILE_PATH = "CALENDAR_FILE_PATH";
		String calRepository = Util.getPropKey("pst", CAL_FILE_PATH);

		// filename: .../PRM/file/MF/12345.vcs
		String absFileName = calRepository + File.separator + getObjectId() + ".vcs";
		FileOutputStream oFile = new FileOutputStream(absFileName);

		// construct the file content
		String s;
		String NL = "\n";
		StringBuffer sbuf = new StringBuffer();
		sbuf.append("BEGIN:VCALENDAR\n");
		sbuf.append("VERSION:1.0\n");
		sbuf.append("PRODID:EGI PRM-MF\n");
		sbuf.append("TZ:-07\n");			// TZ:-07
		sbuf.append("BEGIN:VEVENT\n");
		sbuf.append("SUMMARY:" + getAttribute("Subject")[0] + NL);
		s = (String)getAttribute("Location")[0];
		if (s != null)
			sbuf.append("LOCATION:" + s + NL);
		s = getAgendaString(false);
		//ATTENDEE;ROLE=ATTENDEE;STATUS=TENTATIVE:Francois Meyer <fmeyer@egiomm.com>
		//ATTENDEE;ROLE=ATTENDEE;STATUS=NEEDS ACTION:jsmith@host1.com
		if (s.length() > 0)
			sbuf.append("DESCRIPTION;ENCODING=QUOTED-PRINTABLE:" + s + "\n\n");

		// use UTC for StartDate and ExpireDate
		int zoneDiff = (int)userinfo.getServerUTCdiff();		// time zone's diff from GMT
		String[] ids = TimeZone.getAvailableIDs(0); //zoneDiff * 60 * 60 * 1000);
		/*if (ids.length > 0)
		{
			System.out.println("createVCS() timezone error.");
		}*/
		SimpleTimeZone tz = new SimpleTimeZone(zoneDiff, ids[0]);

		// set up rules for daylight savings time
		//tz.setStartRule(Calendar.APRIL, 1, Calendar.SUNDAY, 2 * 60 * 60 * 1000);
		//tz.setEndRule(Calendar.OCTOBER, -1, Calendar.SUNDAY, 2 * 60 * 60 * 1000);
		SimpleDateFormat df1 = new SimpleDateFormat("MM/dd/yyyy HH:mm:ss");
		SimpleDateFormat df2 = new SimpleDateFormat ("yyyyMMdd'T'HHmmss'Z'");
		df1.setTimeZone(tz);

		// now create a Date object with the UTC time zone
		//Date dt = new Date(df1.format((Date)getAttribute("StartDate")[0]));
		Date dt = df1.parse(df1.format((Date)getAttribute("StartDate")[0]));
		sbuf.append("DTSTART:" + df2.format(dt) + "\n\n");

		//dt = new Date(df1.format((Date)getAttribute("ExpireDate")[0]));
		dt = df1.parse(df1.format((Date)getAttribute("ExpireDate")[0]));
		sbuf.append("DTEND:" + df2.format(dt) + "\n\n");
		sbuf.append("END:VEVENT\n");
		sbuf.append("END:VCALENDAR\n");

		byte [] buf = sbuf.toString().getBytes();
		oFile.write(buf, 0, buf.length);
		oFile.flush();
		oFile.close();

		return;
	}


	// @ECC030309 I need the two indices to the recurring string for monthly and weekly processing
	// Recurring - Monthly::repeat#::1;3::2;4 (i.e., monthly first and third Mon and Wed)
	// Recurring = Weekly::repeat#::3;5 (i.e., weekly tue and thu)
	public static meeting create(PstUserAbstractObject u, String ownerIdS, String subject,
			Date startDate, Date expireDate, String location, String recurring, String projIdS,
			String type, String company)
    	throws IOException, PmpException, ParseException
	{
		return create(u, ownerIdS, subject, startDate, expireDate, location, recurring, projIdS, type, company, 0, 0, false);
	}
	
    public static meeting create(
			PstUserAbstractObject u,
			String ownerIdS,
			String subject,
			Date startDate,
			Date expireDate,
			String location,
			String recurring,
			String projIdS,
			String type,
			String company,
			int idx1,					// index into recurring info for monthly and weekly
			int idx2,					// index into recurring info for monthly only
			boolean bIgnore)			// the meeting date spill to next month, ignore create
        throws IOException, PmpException, ParseException
    {
		// create a meeting object, takes care of create recurring (recursively)
		if (manager == null) manager = meetingManager.getInstance();

		meeting mtg = null;
		if (!bIgnore)					// spill to next month, ignore
		{
			mtg = (meeting)manager.create(u);
			mtg.setAttribute("Owner", ownerIdS);
			mtg.setAttribute("Subject", subject);
			mtg.setAttribute("StartDate", startDate);
			mtg.setAttribute("ExpireDate", expireDate);
			mtg.setAttribute("Location", location);
			mtg.setAttribute("Status", NEW);
			mtg.setAttribute("Recurring", recurring);
			mtg.setAttribute("ProjectID", projIdS);
			mtg.setAttribute("Type", type);
			mtg.setAttribute("TownID", company);
		}

		// check for recurring event, create them all
		if (recurring != null)
		{
			String [] sa = recurring.split(DELIMITER);
			String [] sa1;
			boolean bSpill = false;
			int num = 0;
			if (sa.length >= 2)
				num = Integer.parseInt(sa[1]);
			if (num > 1)
			{
				// first roll forward the dates
				// Set new time for: DAILY, WEEKLY, MONTHLY, BIWEEKLY, BIMONTHLY};
				int field = 0;
				int addSize = 1;
				GregorianCalendar cal = new GregorianCalendar();
				if (sa[0].equals(DAILY) || sa[0].equals(DAILY_NOWKEN)) field = Calendar.DATE;
				else if (sa[0].equals(WEEKLY)) field = Calendar.WEEK_OF_MONTH;
				else if (sa[0].equals(MONTHLY)) field = Calendar.MONTH;

				cal.setTime(startDate);
				if (sa[0].equals(MONTHLY))
				{
					//recurring - Monthly::10::1;3::2;4 (i.e., monthly first and third Mon and Wed)
					sa1 = sa[2].split(";");		// extract 1;3  (first and third)
					idx1++;						// I just created one meeting above
					if (idx1 > sa1.length-1)
					{
						// need to roll to next month
						cal.add(Calendar.MONTH, 1);
						idx1 = 0;			// reset
					}

					cal.set(Calendar.DAY_OF_MONTH, 1);	// start from 1st day
					int month = cal.get(Calendar.MONTH);
					
					int weekOfMonth = Integer.parseInt(sa1[idx1]);
					
					sa1 = sa[3].split(";");		// which day of week
					idx2++;
					if (idx2 > sa1.length-1) idx2 = 0;
					int dayOfWeek = Integer.parseInt(sa1[idx2]);

					cal.set(Calendar.DAY_OF_WEEK, dayOfWeek);
					if (cal.get(Calendar.MONTH) < month)
						cal.add(Calendar.DATE, 7);
					
					cal.add(Calendar.DATE, (weekOfMonth-1)*7);
					if (cal.get(Calendar.MONTH) != month)
					{
						bSpill = true;
						cal.add(Calendar.MONTH, -1);
					}
					GregorianCalendar aCal = (GregorianCalendar) cal.clone();
					aCal.add(Calendar.HOUR, userinfo.getServerTimeZone() /*meeting.SERVER_TIME_ZONE*/);
					if (aCal.get(Calendar.DAY_OF_WEEK) != dayOfWeek)
						cal.add(Calendar.DATE, 1);
				}
				else if (sa[0].equals(WEEKLY))
				{
					// recurring - Weekly::repeat#::3;5 (i.e., weekly tue and thu)
					sa1 = sa[2].split(";");
					idx1++;
					if (idx1 > sa1.length-1)
					{
						// need to roll to next week
						cal.add(Calendar.WEEK_OF_MONTH, 1);
						idx1 = 0;			// reset
					}
					cal.set(Calendar.DAY_OF_WEEK, Integer.parseInt(sa1[idx1]));
				}
				else
				{
					// DAILY or DAILY_NOWKEN
					cal.add(field, addSize);
					if (sa[0].equals(DAILY_NOWKEN))
					{
						// skip Sat and Sun
						int d = cal.get(Calendar.DAY_OF_WEEK);
						if (d==Calendar.SATURDAY)
							cal.add(field, 2);
						else if (d==Calendar.SUNDAY)
							cal.add(field, 1);
					}
				}
				
				Date stDt = cal.getTime();
				long diff = expireDate.getTime() - startDate.getTime();
				Date exDt = new Date(stDt.getTime() + diff);

				if (!bSpill) num--;
				recurring = sa[0] + DELIMITER + num;				// repeat# decremented by 1
				if (sa.length>=3) recurring += DELIMITER + sa[2];	// more recur info
				if (sa.length>=4) recurring += DELIMITER + sa[3];	// more recur info
				
				// roll forward subject if there is a digit at the end, like xxx (1)
				if (!bSpill && subject.endsWith(")"))
				{
					int idx3 = subject.lastIndexOf('(');
					int idx4 = subject.lastIndexOf(')');
					if (idx3 < idx4)
					{
						try
						{
							num = Integer.parseInt(subject.substring(idx3+1, idx4)) + 1;
							subject = subject.substring(0, idx3+1) + num + ")";		// increment subject #
						}
						catch (Exception e) {}
					}
				}

				meeting nxtMtg = create(u, ownerIdS, subject, stDt, exDt, location, recurring, projIdS, type, company, idx1, idx2, bSpill);
				if (bIgnore)
					return nxtMtg;
				if (nxtMtg != null)
					recurring = recurring + DELIMITER + nxtMtg.getObjectId();
				else
					recurring = sa[0] + DELIMITER + 0;
				mtg.setAttribute("Recurring", recurring);	// Weekly::3::2::21100 or Monthly::5::1;3::2;4::21000
			}
			else
			{
				if (mtg == null) return null;			// might not have created
				recurring = sa[0] + DELIMITER + 0;		// last one
				mtg.setAttribute("Recurring", recurring);
			}
		}
		manager.commit(mtg);

		// @041805ECC create a vcs file for this meeting
		mtg.createVCS();

		return mtg;		// return the top parent meeting

    }//End create

    public void updateRecurring(PstUserAbstractObject u, String attName)
        throws PmpException
    {
        // copy this attribute to my next event (if any) recursively
        String recurring = (String)getAttribute("Recurring")[0];	// Weekly::2::...::20011
        if (recurring == null) return;

		String [] sa = recurring.split(DELIMITER);
		int num = 0;
		if (sa.length >= 2)
			num = Integer.parseInt(sa[1]);
		if (num>0 && sa.length>=3)
		{
			// get my child and update the attribute
			int id;
			String idS = sa[sa.length-1];
			// make sure this is a meeting id
			if (!idS.contains(";") && (id = Integer.parseInt(idS))>1000)
			{
				meeting mtg = (meeting)manager.get(u, id);
				if (attName.equals("StartDate") || attName.equals("ExpireDate"))
				{
					// for Date attr, only change the Time, not the Date
					Calendar cal = Calendar.getInstance();
					cal.setTime((Date)getAttribute(attName)[0]);
					int hour = cal.get(Calendar.HOUR_OF_DAY);
					int min = cal.get(Calendar.MINUTE);
					cal.setTime((Date)mtg.getAttribute(attName)[0]);
					cal.set(Calendar.HOUR_OF_DAY, hour);
					cal.set(Calendar.MINUTE, min);
					mtg.setAttribute(attName, cal.getTime());
				}
				else
					mtg.setAttribute(attName, getAttribute(attName));
				manager.commit(mtg);
				mtg.updateRecurring(u, attName);
			}
		}
    }


    public void deleteRecursive(PstUserAbstractObject u, boolean bRecur)
        throws IOException, PmpException
    {
		actionManager aMgr = actionManager.getInstance();

		// delete action items of this meeting
		int [] ids = aMgr.findId(u, "MeetingID='" + getObjectId() + "'");
		PstAbstractObject [] aiObjList = aMgr.get(u, ids);
		action aObj;
		for (int i=0; i<aiObjList.length; i++)
		{
			aObj = (action)aiObjList[i];
			if (aObj.getAttribute("ProjectID")[0] == null)
				aObj.deleteAction(u);						// orphan action, delete @SWS092806
			else
			{
				aObj.setAttribute("MeetingID", null);	// remove the meeting id
				aMgr.commit(aObj);
			}
		}
		// find the parent and make sure to fix the recurring info
		String recurring;
		String [] sa;
		ids = manager.findId(u, "Recurring='%" + getObjectId() + "%'");	// there should only be one parent
		if (ids.length > 0)
		{
			PstAbstractObject o = manager.get(u, ids[0]);
			recurring = (String)o.getAttribute("Recurring")[0];
			sa = recurring.split(DELIMITER);
			recurring = sa[0] + DELIMITER + "0";
			o.setAttribute("Recurring", recurring);
			manager.commit(o);
		}

		// delete the next meeting (recursively)
		if (bRecur)
		{
			recurring = (String)getAttribute("Recurring")[0];
			if (recurring != null)
			{
				sa = recurring.split(DELIMITER);
				int num = 0;
				if (sa.length >= 2)
					num = Integer.parseInt(sa[1]);
				if (num>0 && sa.length>=3)
				{
					try
					{
						int id;
						String idS = sa[sa.length-1];
						// make sure it is a mtg id before delete
						if (!idS.contains(";") && (id=Integer.parseInt(idS))>1000)
						{
							meeting mtg = (meeting)manager.get(u, id);
							mtg.deleteRecursive(u, true);
						}
					}
					catch (PmpException e)
					{// the next meeting might be gone already
					}
				}
			}
		}

		// delete the vcs file of this meeting object
		String CAL_FILE_PATH = "CALENDAR_FILE_PATH";
		String calRepository = Util.getPropKey("pst", CAL_FILE_PATH);
		String absFileName = calRepository + File.separator + getObjectId() + ".vcs";
		File vFile = new File(absFileName);
		if (vFile.exists())
			vFile.delete();

		// delete attachment objects and remove from index
		attachmentManager attMgr = attachmentManager.getInstance();
		Object [] objArr = getAttribute("AttachmentID");
		for (int i=0; i<objArr.length; i++) {
			if (objArr[i] != null) {
				int aID = Integer.parseInt(objArr[i].toString());
				attachment att = (attachment)attMgr.get(u, aID);
				attMgr.delete(att); // removes from index
			}
		}
		
		// delete attachment files
		String FILE_PATH = "FILE_UPLOAD_PATH";
		calRepository = Util.getPropKey("pst", FILE_PATH);
		String subDirStr = calRepository + File.separator + getObjectId();
		File subDirectory = new File(subDirStr);

		// if exist, delete all the files that are in it
		if(subDirectory.exists())
		{
			// delete all files and then the directory
			String [] ls;
			FilenameFilter filter = new MyFileFilter(
					"",			// prefix
					"");		// subfix
			ls = subDirectory.list(filter);
			for (int i=0; i<ls.length; i++)
			{
				File f = new File(subDirStr + File.separator + ls[i]);
				f.delete();
			}
			subDirectory.delete();
		}

		// delete this meeting object (self)
		manager.delete(this);
	}

    public void setAttachmentAuthority(PstUserAbstractObject u)
    throws PmpException
    {
    	// set the authority of all attachment object
    	// if the meeting becomes Public, all documents are allowed to access
    	// if the meeting becomes Private, only invitees are allowed to access
    	Object [] oArr = getAttribute("AttachmentID");
		if (oArr[0] == null) return;		// no attachment for this meeting
    	attachment attObj;
    	attachmentManager attMgr = attachmentManager.getInstance();
    	for (int i=0; i<oArr.length; i++)
    	{
    		// the following call will update the auth list in the attachment object and commit
    		attObj = (attachment)attMgr.get(u, (String)oArr[i]);
    		attObj.setAuthorizedList(this);
    	}
    }

	/**
	 * return the invitees (mandatory and optional) including owner
	 * @return Object ArrayList
	 * @throws PmpException 
	 * @throws PmpInternalException 
	 * @throws PmpRawGetException 
	 * @throws PmpInvalidAttributeException 
	 * @throws PmpManagerCreationException 
	 * @throws PmpObjectException 
	 */
	public ArrayList<String> getAllAttendees()
		throws PmpException
	{
		ArrayList<String> allPeople = new ArrayList<String>(10);
		Object [] attArr = getAttribute("Attendee");
		
		String s;
		String [] sa;
		for (int i=0; i<attArr.length; i++) {
			s = (String) attArr[i];
			sa = s.split(DELIMITER1);		// 12345:MandatoryPresent
			allPeople.add(sa[0]);
		}
		return allPeople;
	}

	// Specialized functions end
	////////////////////////////////////////////////////////////////

    protected void delete()
        throws PmpDeleteObjectException
    {
        super.delete();
    }//End delete

    protected void save()
        throws PmpCommitObjectException
    {
        super.save();
    }//End save

    protected boolean refresh()
    {
        return super.refresh();
    }//End refresh

}//End class meeting
