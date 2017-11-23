
//
//  Copyright (c) 2004, eGuanxi, Inc.  All rights reserved.
//
//	Licensee of FastPath (tm) is authorized to change, distribute
//	and resell this source file and the compliled object file,
//	provided the copyright statement and this statement is included
//	as header.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   phase.java
//  Author: FastPath CodeGen Engine
//  Date:   03.18.2004
//  Description:
//		Implementation of phase class
//  Modification:
//		@030904ECC	Created template file for class representation of OMM Organization.
//		@033004ECC	Support appending single data value to multiple data attribute.
//
/////////////////////////////////////////////////////////////////////
//
// phase.java : implementation of the phase class
//

package oct.codegen;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;

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
import oct.pst.PstUserAbstractObject;

import org.apache.log4j.Logger;

import util.PrmLog;
import util.Util;

/**
*
* <b>General Description:</b>  phase extends PmpAbstractObject.  This class
* encapulates the data of a member from the "phase" organization.
*
* The phase class provides a facility to modify data of an existing phase object.
*
*
*
* <b>Class Dependencies:</b>
*   oct.custom.phaseManager
*   oct.pmp.PmpUser
*   oct.pmp.PmpUserManager
*
*
* <b>Miscellaneous:</b> There are methods that will be deprecated in future versions.
*
*/


public class phase extends PstAbstractObject
{
	// list of db attributes
	public static final String COMPLETEDATE = "CompleteDate";
	public static final String CREATEDDATE = "CreatedDate";
	public static final String EXPIREDATE = "ExpireDate";
	public static final String LASTUPDATEDDATE = "LastUpdatedDate";
	public static final String NAME = "Name";
	public static final String PARENTID = "ParentID";
	public static final String PHASENUMBER = "PhaseNumber";			// starts from 0
	public static final String PLANEXPIREDATE = "PlanExpireDate";
	public static final String PROJECTID = "ProjectID";
	public static final String STARTDATE = "StartDate";
	public static final String STATUS = "Status";
	public static final String TASKID = "TaskID";
	public static final String COLOR = "Color";

	// default phase color
	public static final String [] DEF_COLOR = {
		"#ee0000", "#00aa00", "#0033ee", "#aa5500", "#aaaa00", "5500aa", "#3366aa"};

	// Private attributes
	private static final int MAXOPTIONS = 3;
	private static final int TBDINT = 0;
	private static final int NAINT = 1;
	private static final int BLANKINT = 2;

	private static final String TBD = "TBD";
	private static final String NSA = "N/A";
	private static final String NA = "NA";
	private static final String BLANK = " ";

	// statics for comparing largest time
	private static final String FORMAT = "MM/dd/yyyy ss z";
	private static final SimpleDateFormat SDF = new SimpleDateFormat(FORMAT);
	private static final String DATE = "12/31/9999 01 PST";
	private static final Date SD = getStaticDate();
	private static final long MINDATE = (SD != null)?SD.getTime():0; // need to handle 0
	private static final long MAXDATE = MINDATE + (MAXOPTIONS * 1000);

	public final static String PH_NEW		= "Not Started";
	public final static String PH_START		= "Started";
	public final static String PH_COMPLETE	= "Completed";
	public final static String PH_LATE		= "Late";
	public final static String PH_CANCEL	= "Canceled";
	public final static String PH_RISKY		= "High Risk";
	public static final String [] PHASE_ARRAY	= {PH_NEW, PH_START, PH_COMPLETE, PH_LATE, PH_CANCEL, PH_RISKY};
	public static final String [] PHASE_ARRAY_LATE = {PH_COMPLETE, PH_LATE, PH_CANCEL};
	public static final String [] PHASE_ARRAY_REG = {PH_NEW, PH_START, PH_COMPLETE, PH_CANCEL, PH_RISKY};
	public static final String [] PHASE_ARRAY_COM = {PH_START, PH_COMPLETE};
	public static final String [] PHASE_ARRAY_CAN = {PH_START, PH_CANCEL};

	static Logger l = PrmLog.getLog();
    static phaseManager manager;
    static projectManager pjMgr;
    static taskManager tkMgr;

    static {
		try {
			manager = phaseManager.getInstance();
			pjMgr = projectManager.getInstance();
			tkMgr = taskManager.getInstance();
		}
		catch (PmpException e) {}
	}

    /**
     * Constructor for instantiating a new phase.
     * @param member An OmsMember representing a phase.
     */
    public phase(OmsMember member)
    {
        super(member);
    }//End Constructor





    /**
     * Constructor for instantiating a new phase.
     * @param userObj A PmpUesr.
     * @param org An organization.
     * @param memberName The name of the member.
     * @param password The password of the member.
     */
	phase(PstUserAbstractObject userObj, OmsOrganization org, String memberName, String password)
		throws PmpException
	{
		super(userObj, org, memberName, password);
	}



    /**
     * Constructor for creating a phase.  Used by phaseManager.
     * @param userObj A PmpUser.
     * @param org The OmsOrganization for the phase.
     */
    phase(PstUserAbstractObject userObj, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
		super(userObj, org, "");
    }//End Constructor

    /**
     * Constructor for creating a phase.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the phase.
     */
    phase(OmsSession session, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, "");
    }//End Constructor

    /**
     * Constructor for creating a phase using a member name.
     * @param userObj A PmpUser.
     * @param org The OmsOrganization for the phase.
     * @param phaseMemName The member name for the created phase.
     */
    phase(PstUserAbstractObject userObj, OmsOrganization org, String phaseMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(userObj, org, phaseMemName, null);
    }//End Constructor

    /**
     * Constructor for creating a phase using a member name.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the phase.
     * @param companyMemberName The member name for the created phase.
     */
    phase(OmsSession session, OmsOrganization org, String phaseMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, phaseMemName, null);
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

    }

    private static Date getStaticDate() {
    	try {
    		return SDF.parse(DATE);
    	} catch (ParseException e) {
    		return null;
    	}
    }

    /**
     * Receives a String and how the String is suppose to be formatted. If
     * formatFrom is null or if the String date cannot be parsed it will
     * check to see if this is a special string with a special date value.
     * @see getDateFromString(String text)
     * @param date 	The text received from user as the current date.
     * @param formatFrom This String will be used to create a SimpleDateFormat
     * @return 	Date object for the date submitted or a special Date the represents
     * 			a special string (@see getDateFromString) or null if neither.
     */
    public static Date parseStringToDate(String date, String formatFrom) throws ParseException {
    	if (date != null && date.length() > 0 &&
    			formatFrom != null && formatFrom.length() > 0) {
    		SimpleDateFormat df = new SimpleDateFormat(formatFrom);
    		try {
    			// Check to see if date is in valid format (not 13/22/2006)
    			Date d = df.parse(date);
    			Util.validCalanderDate(date, d);
    			return d;
    		} catch (ParseException e) {
    			return getDateFromString(date);
    		}
    	}
    	else {
    		return getDateFromString(date);
    	}
    }

    /**
     * Receives the Date object from database and parses the string into
     * the format formatTo. If the Date contains certain special Dates (e.g.
     * getTime() value is < 2), it will return the correct string value for the
     * time @see getStringFromInt.
     * @param date The date object from db
     * @param formatTo A constructor value for SimpleDateFormat
     * @return The date parsed into the correct format or the special string or "";
     */
    public static String parseDateToString(Date date, String formatTo) {
    	if (date != null) {
    		long time = date.getTime();
    		if (time < MAXDATE && time >= MINDATE) {
    			int timeInt = (Long.valueOf(time - MINDATE).intValue())/1000;
    			switch (timeInt) {
    			case TBDINT:
    				return TBD;
    			case NAINT:
    				return NSA;
    			case BLANKINT:
    				return BLANK;
    			default:
    				l.info("Cannot find TimeInt: " + timeInt);
    			}
    		}
    	}
    	String result = Util.formatToDate(date, formatTo);
    	return (result != null)?result:"";
    }

    /**
     * Reads the String and determines the value of the date to parse into
     * @param text TBD or N/A
     * @return 	Date object with a special time for TBD or N/A, anything else
     * 			returns null
     */
    private static Date getDateFromString(String text) throws ParseException{
    	if (text != null && text.length() > 0) {
	    	if (text.equalsIgnoreCase(TBD))
	    		return new Date(MINDATE + (TBDINT * 1000)); // Date are created from milliseconds
	    	else if (text.equalsIgnoreCase(NSA)) {
	    		return new Date(MINDATE + (NAINT * 1000));
	    	}
	    	else if (text.equalsIgnoreCase(NA)) {
	    		return new Date(MINDATE + (NAINT * 1000));
	    	}
	    	else if (text.equalsIgnoreCase(BLANK)) {
	    		return new Date(MINDATE + (BLANKINT * 1000));
	    	}
	    	else {
	    		l.info("Cannot parse to Date for text: " + text);
	    		throw new ParseException(text, 0);
	    	}
    	}
    	return null;
    }

    public static boolean isSpecialDate(String date, String formatFrom) {
    	if (date != null && date.length() > 0 &&
    			formatFrom != null && formatFrom.length() > 0) {
    		SimpleDateFormat df = new SimpleDateFormat(formatFrom);
    		try {
    			return isSpecialDate(df.parse(date));
    		} catch (ParseException e) {
    			return false;
    		}
    	}
    	return false;
    }

    public static String[] createStatusArray(String status) {
    	if (status == null)
    		return PHASE_ARRAY_REG;
    	if (status.equalsIgnoreCase(project.PH_LATE))
    		return PHASE_ARRAY_LATE;
    	else if (status.equalsIgnoreCase(project.PH_COMPLETE))
    		return PHASE_ARRAY_COM;
    	else if (status.equalsIgnoreCase(project.PH_CANCEL))
    		return PHASE_ARRAY_CAN;
    	else
    		return PHASE_ARRAY_REG;
    }

    /**
     * Reads to see if the date is within the special time zone used
     * to determine N/A, TBD
     * @param date
     * @return true if date is special; otherwise false
     */
    public static boolean isSpecialDate(Date date) {
    	if (date != null) {
    		long time = date.getTime();
    		if (time >= MINDATE && time < MAXDATE)
    			return true;
    	}
    	return false;
    }

    /**
     * Assumes all phases are tasks, add this task to the phase list.
     * The phase number will be arranged correctly depending on the task IDs.
     * @param u
     * @param tkObj the task to be added.
     */
	public static void addTaskPhase(PstUserAbstractObject u, task tkObj)
		throws PmpException
	{
		int thisTaskId = tkObj.getObjectId();
		PstAbstractObject pt = tkObj.getPlanTask(u);
		int thisPreOrder = ((Integer)pt.getAttribute("PreOrder")[0]).intValue();
		String projIdS = (String)tkObj.getAttribute(PROJECTID)[0];
		int [] ids = manager.findId(u, "ProjectID='" + projIdS + "'");

		PstAbstractObject [] phArr = manager.get(u, ids);
		Util.sortInteger(phArr, PHASENUMBER);

		PstAbstractObject ph, tk;
		int idx, phNum = 0;		// phase number starts from 1
		int tid;
		int preOrder;
		
		for (idx=0; idx<phArr.length; idx++) {
			//ph = manager.get(u, ids[idx]);
			ph = phArr[idx];

			String tidS = (String)ph.getAttribute("TaskID")[0];
			if (tidS == null) {
				// should not support non-task phase in the future
				// even if task id is null, look at its phase number
				phNum = ((Integer)ph.getAttribute(PHASENUMBER)[0]).intValue();
				continue;
			}

			tid = Integer.parseInt(tidS);
			if (tid == thisTaskId) {
				// already in the phase list, do nothing
				return;
			}
			
			// try to see where to insert this phase
			// the planTask PreOrder give an absolute order of the task tree
			tk = tkMgr.get(u, tidS);
			pt = ((task)tk).getPlanTask(u);
			preOrder = ((Integer)pt.getAttribute("PreOrder")[0]).intValue();


			if (preOrder < thisPreOrder) {
				// I need to remember phase num because there might not
				// be more phase after this
				phNum = ((Integer)ph.getAttribute(PHASENUMBER)[0]).intValue();
				continue;
			}
			else {
				// this task's preOrder is bigger than me, insert me into
				// the phase list before this task
				break;
			}
		}

		// create the phase for this task
		phNum++;		// this is my phase number
		ph = (phase)manager.create(u);
		ph.setAttribute(PROJECTID, projIdS);
		ph.setAttribute(TASKID, String.valueOf(thisTaskId));
		ph.setAttribute(PHASENUMBER, phNum);
		ph.setAttribute(COLOR, DEF_COLOR[phNum]);	// phNum starts with 0
		ph.setAttribute(CREATEDDATE, new Date());
		ph.setAttribute(LASTUPDATEDDATE, new Date());
		manager.commit(ph);
		l.info("Added task [" + thisTaskId + "] as phase [" + phNum + "]");

		// now I need to re-arrange the phase number behind
		for (; idx<phArr.length; idx++) {
			//ph = manager.get(u, ids[idx]);
			ph = phArr[idx];
			phNum = ((Integer)ph.getAttribute(PHASENUMBER)[0]).intValue();
			ph.setAttribute(PHASENUMBER, ++phNum);	// inc by 1
			manager.commit(ph);
		}
	}

	/**
	 * Assumes all phases are tasks, remove this task from the phase list.
	 * The phase number will be re-arranged correctly depending on the task IDs.
	 * @param u
	 * @param tkObj the task to be removed.
	 */
	public static void removeTaskPhase(PstUserAbstractObject u, task tkObj)
		throws PmpException
	{
		int thisTaskId = tkObj.getObjectId();
		String projIdS = (String)tkObj.getAttribute(PROJECTID)[0];
		int [] ids = manager.findId(u, "ProjectID='" + projIdS + "'");
		PstAbstractObject [] phArr = manager.get(u, ids);
		
		// sort by phase so that I process the following correctly
		Util.sortInteger(phArr, PHASENUMBER);

		PstAbstractObject ph;
		int idx, phNum = -1;
		for (idx=0; idx<phArr.length; idx++) {
			//ph = manager.get(u, ids[idx]);
			ph = phArr[idx];
			String tidS = (String)ph.getAttribute("TaskID")[0];
			if (tidS == null) continue;

			if (thisTaskId == Integer.parseInt(tidS)) {
				// found the task in the phase list
				phNum = ((Integer)ph.getAttribute(PHASENUMBER)[0]).intValue();
				manager.delete(ph);
				
				// also remove all the sub-phases
				ids = manager.findId(u, "ParentID='" + ph.getObjectId() + "'");
				for (int i=0; i<ids.length; i++) {
					ph = manager.get(u, ids[i]);
					manager.delete(ph);
				}
				break;
			}
		}

		if (phNum == -1) {
			l.info("Fail to remove task phase.  Task [" + thisTaskId + "] not found in phase.");
		}
		else {
			l.info("Removed task [" + thisTaskId + "] as phase [" + phNum + "]");

			// now I need to re-arrange the phase number behind the deleted phase
			// begin with idx++ to skip the deleted phase
			for (idx++; idx<phArr.length; idx++) {			
				//ph = manager.get(u, ids[idx]);
				ph = phArr[idx];
				phNum = ((Integer)ph.getAttribute(PHASENUMBER)[0]).intValue();
				ph.setAttribute(PHASENUMBER, --phNum);	// decrement by 1
				manager.commit(ph);
			}
		}
	}

	/**
	 */
	public project getProject(PstUserAbstractObject u)
		throws PmpException
	{
		String pjId = (String)getAttribute(PROJECTID)[0];
		if (pjId == null) return null;

		project pj = (project)pjMgr.get(u, Integer.parseInt(pjId));
		return pj;
	}

    protected void delete()
        throws PmpDeleteObjectException
    {
        super.delete();
        l.info("Deleted phase [" + getObjectId() + "]");

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

    public static class PhaseInfo
    {
    	public String phaseId;
    	public String name;
    	public String htmlName;
    	public String origStartDtS;
    	public String origExpireDtS;
    	public String startDateS;			// planned start date
    	public String effectiveDateS;		// actual start date
    	public String pExpDateS;			// plan expire date (?? ECC:what is this ??)
    	public String expireDateS;			// phase expire date (planned)
    	public String doneDateS;			// actual completion date
    	public String status;
    	public String taskId;

    	public PhaseInfo() {}
    }

}//End class phase

