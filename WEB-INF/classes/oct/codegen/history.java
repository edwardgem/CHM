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
//  File:   history.java
//  Author: FastPath CodeGen Engine
//  Date:   03.18.2004
//  Description:
//		Implementation of history class
//  Modification:
//
/////////////////////////////////////////////////////////////////////
//
// history.java : implementation of the history class
//

package oct.codegen;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;

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

import util.Prm;
import util.PrmEvent;
import util.PrmLog;
import util.StringUtil;
import util.Util3;

/**
*
* <b>General Description:</b>  history extends PmpAbstractObject.  This class
* encapsulates the data of a member from the "history" organization.
*
* The history class provides a facility to modify data of an existing history object.
*
*
*
* <b>Class Dependencies:</b>
*   oct.custom.historyManager
*   oct.pmp.PmpUser
*   oct.pmp.PmpUserManager
*
*
* <b>Miscellaneous:</b> There are methods that will be deprecated in future versions.
*
*/


public class history extends PstAbstractObject
{

    //Private attributes
	public static final SimpleDateFormat df0 = new SimpleDateFormat("MM/dd/yyyy hh:mm:ss a");
	private static final String RESOURCE_FILE_PATH = Prm.getResourcePath();
	private static final String APP = Prm.getAppTitle();
    
    // constants for IDs and tags.  Tags start with "$"
	// this also map to the Attribute Names
    private static final String APPLICATION	= "Application";
    private static final String CREATOR		= "Creator";
    private static final String TOWNID		= "TownID";
    private static final String USERID		= "UserID";
    private static final String PROJECTID	= "ProjectID";
    private static final String TASKID		= "TaskID";
    private static final String MEETINGID	= "MeetingID";
    private static final String BUGID		= "BugID";
    private static final String ATTID		= "AttachmentID";
    
    private static final String TOWNNAME	= "TownName";
    private static final String USERNAME	= "UserName";
    private static final String PROJNAME	= "ProjectName";
    private static final String TASKNAME	= "TaskName";
    private static final String ATTNAME		= "AttachmentName";
    private static final String MTGNAME		= "MeetingName";
       
    private static String [] recordIdType = {	// 7 types
    	TOWNID, USERID, PROJECTID, TASKID, MEETINGID, BUGID, ATTID};

    static private historyManager manager;
    static private userManager uMgr;
    static private projectManager pjMgr;
    static private taskManager tkMgr;
    static private attachmentManager attMgr;
    static private meetingManager mtgMgr;
    static private townManager tnMgr;

	static Logger l = PrmLog.getLog();
	
	// hashmap for history code to messages
	private static HashMap<String,String> _histHash;		// for default (en_US) locale
	
	// hashmap mapping history to event
	private static HashMap<String,String> _histEventMap;
    
    static {
    	try {
    		manager = historyManager.getInstance();
    		uMgr = userManager.getInstance();
    		pjMgr = projectManager.getInstance();
    		tkMgr = taskManager.getInstance();
    		attMgr = attachmentManager.getInstance();
    		mtgMgr = meetingManager.getInstance();
    		tnMgr = townManager.getInstance();
    		
    		// initiate the history hash
    		_histHash = fillHistoryHash(null);		// fill default locale hash
    		
    		// define some history records that will trigger events
    		_histEventMap = new HashMap<String, String>(20);
    		
    		// project
    		_histEventMap.put("HIST.3101", "EVENT.501");
    		_histEventMap.put("HIST.3102", "EVENT.502");
    		_histEventMap.put("HIST.3110", "EVENT.503");
    		_histEventMap.put("HIST.3111", "EVENT.504");
    		_histEventMap.put("HIST.3112", "EVENT.505");
    		_histEventMap.put("HIST.3113", "EVENT.506");
    		_histEventMap.put("HIST.3114", "EVENT.507");
    		_histEventMap.put("HIST.3115", "EVENT.508");
    		_histEventMap.put("HIST.3117", "EVENT.510");

    		// task
    		_histEventMap.put("HIST.4101", "EVENT.551");
    		_histEventMap.put("HIST.4102", "EVENT.552");
    		_histEventMap.put("HIST.4103", "EVENT.553");
    		_histEventMap.put("HIST.4104", "EVENT.554");
    		_histEventMap.put("HIST.4105", "EVENT.555");
    		_histEventMap.put("HIST.4106", "EVENT.556");
    		
    		// files
    		_histEventMap.put("HIST.7101", "EVENT.601");
    		_histEventMap.put("HIST.7102", "EVENT.602");
    		_histEventMap.put("HIST.7103", "EVENT.603");
    		_histEventMap.put("HIST.7104", "EVENT.604");
    		_histEventMap.put("HIST.7105", "EVENT.605");
    	}
    	catch (Exception e) {
			l.error("history.java failed to initialize manager instance.");
    	}
    }

    /**
     * Constructor for instantiating a new history.
     * @param member An OmsMember representing a history.
     */
    public history(OmsMember member)
    {
        super(member);
    }//End Constructor





    /**
     * Constructor for instantiating a new history.
     * @param userObj A PmpUesr.
     * @param org An organization.
     * @param memberName The name of the member.
     * @param password The password of the member.
     */
	history(PstUserAbstractObject userObj, OmsOrganization org, String memberName, String password)
		throws PmpException
	{
		super(userObj, org, memberName, password);
	}



    /**
     * Constructor for creating a history.  Used by historyManager.
     * @param userObj A PmpUser.
     * @param org The OmsOrganization for the history.
     */
    history(PstUserAbstractObject userObj, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
		super(userObj, org, "");
    }//End Constructor

    /**
     * Constructor for creating a history.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the history.
     */
    history(OmsSession session, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, "");
    }//End Constructor

    /**
     * Constructor for creating a history using a member name.
     * @param userObj A PmpUser.
     * @param org The OmsOrganization for the history.
     * @param historyMemName The member name for the created history.
     */
    history(PstUserAbstractObject userObj, OmsOrganization org, String historyMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(userObj, org, historyMemName, null);
    }//End Constructor

    /**
     * Constructor for creating a history using a member name.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the history.
     * @param companyMemberName The member name for the created history.
     */
    history(OmsSession session, OmsOrganization org, String historyMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, historyMemName, null);
    }//End Constructor


    /**
     * Currently Not Implemented.
     * Determine whether attribute is set-able.
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

    }//End getAttribute


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
    
    /////////////////////////////////////////////////////////
    // Other methods
    
    /**
     * create a history record in the database.
     * @param u the user who created this record
     * @param typeCode a numeric string mapping to the history.csv
     * @param ids one or more IDs to be stored in the record.  This must be in the order
     * of town, user, project, task, meeting, case/bug, attachment
     * resource file for the type of history record
     */
    public static String addRecord(
    		PstUserAbstractObject u,
    		String typeCode,
    		String ... ids 
    		)
    {
    	try {
    		history hist = (history)manager.create(u);
    		
    		// set save history record value
    		hist.setAttribute("Type", typeCode);	// HIST.1234
    		hist.setAttribute(CREATOR, String.valueOf(u.getObjectId()));
    		hist.setAttribute("CreatedDate", new Date());
    		
    		int idx = 0;
    		for (String idValue : ids) {
    			// 7: town, user, project, task, meeting, case/bug, attachment
    			hist.setAttribute(recordIdType[idx++], idValue);
    		}
    		
    		// get the string just in case if some ID's got deleted in the future
    		hist.setAttribute("LastComment", hist.getRecordString(u, null, false));
    		
    		manager.commit(hist);
    		l.info("Created history record [" + hist.getObjectId() + "] of type (" + typeCode + ")");
    		
    		// trigger event
    		String evtIdS;
    		if ((evtIdS = _histEventMap.get(typeCode)) != null) {
    			evtIdS = evtIdS.substring(evtIdS.indexOf('.')+1);	// only numeric of EVENT.1234
    			String secondIdS = (String)hist.getAttribute("TaskID")[0];
    			if (secondIdS == null) {
    				secondIdS = (String)hist.getAttribute("AttachmentID")[0];
    			}
    			PrmEvent.createTriggerEvent(u, evtIdS,
    					(String)hist.getAttribute("ProjectID")[0],	// evt midS
    					secondIdS,									// evt townIdS, we pass taskId or attId
    					null);
    		}
    		
    		return String.valueOf(hist.getObjectId());
    	}
    	catch (Exception e) {
    		l.error("Fail to create history record.\n");
    		e.printStackTrace();
    	}
    	return null;
    }	// END: addRecord()
    
    /**
     * return a complete history record string by extracting the message string
     * and filling in all the necessary info as deem possible.
     * @param u caller
     * @param locale
     */
    public String getRecordString(PstUserAbstractObject u, String locale, boolean bWithTimestamp)
		throws FileNotFoundException, IOException, PmpException
    {
    	// TODO: need to handle other locale
    	if (_histHash == null) {
    		_histHash = fillHistoryHash(null);		// fill default locale hash
    	}
    	
    	String typeCode = (String)getAttribute("Type")[0];	// "HIST.1234"
    	String creatorName;
    	try {
    		user creator = (user)uMgr.get(u, Integer.parseInt((String)getAttribute("Creator")[0]));
    		creatorName = creator.getFullName();
    	}
    	catch (PmpException e) {creatorName = "-";}
    	
    	String townIdS = (String)getAttribute(TOWNID)[0];
    	String userIdS = (String)getAttribute(USERID)[0];
    	String projIdS = (String)getAttribute(PROJECTID)[0];
    	String taskIdS = (String)getAttribute(TASKID)[0];
    	String meetingIdS = (String)getAttribute(MEETINGID)[0];
    	String bugIdS = (String)getAttribute(BUGID)[0];
    	String attIdS = (String)getAttribute(ATTID)[0];

    	String msg = _histHash.get(typeCode);		// typeCode is like "HIST.1234" in history.csv
    	if (msg != null) {
    		// basic ids
    		msg = msg.replace("$" + APPLICATION, APP);
    		msg = msg.replace("$" + CREATOR, creatorName);
    		if (townIdS!=null) msg = msg.replace("$" + TOWNID, townIdS);
    		if (userIdS!=null) msg = msg.replace("$" + USERID, userIdS);
    		if (projIdS!=null) msg = msg.replace("$" + PROJECTID, projIdS);
    		if (taskIdS!=null) msg = msg.replace("$" + TASKID, taskIdS);
    		if (meetingIdS!=null) msg = msg.replace("$" + MEETINGID, meetingIdS);
    		if (bugIdS!=null) msg = msg.replace("$" + BUGID, bugIdS);
    		if (attIdS!=null) msg = msg.replace("$" + ATTID, attIdS);

    		try {
    			// project name
    			if (projIdS!=null && msg.contains("$"+PROJNAME)) {
    				project pj = (project)pjMgr.get(u, Integer.parseInt(projIdS));
    				msg = msg.replace("$" + PROJNAME, pj.getDisplayName());
    			}

    			// task name
    			if (taskIdS!=null && msg.contains("$"+TASKNAME)) {
    				task tk = (task)tkMgr.get(u, taskIdS);
    				msg = msg.replace("$" + TASKNAME, tk.getTaskName(u));
    			}

    			// attachment name
    			if (attIdS!=null && msg.contains("$"+ATTNAME)) {
    				attachment att = (attachment)attMgr.get(u, attIdS);
    				msg = msg.replace("$" + ATTNAME, Util3.getOnlyFileName(att));
    			}

    			// user name
    			if (userIdS!=null && msg.contains("$"+USERNAME)) {
    				user uObj = (user)uMgr.get(u, Integer.parseInt(userIdS));
    				msg = msg.replace("$" + USERNAME, uObj.getFullName());
    			}

    			// meeting name
    			if (meetingIdS!=null && msg.contains("$"+MTGNAME)) {
    				meeting mtg = (meeting)mtgMgr.get(u, Integer.parseInt(meetingIdS));
    				msg = msg.replace("$" + MTGNAME, (String)mtg.getAttribute("Subject")[0]);
    			}

    			// town name
    			if (townIdS!=null && msg.contains("$"+TOWNNAME)) {
    				town tn = (town)tnMgr.get(u, Integer.parseInt(townIdS));
    				msg = msg.replace("$" + TOWNNAME, (String)tn.getAttribute("Name")[0]);
    			}
    		}
    		catch (PmpException e) {
    			// cannot get the info, use the saved record
    			l.warn("Fail to construct history [" + getObjectId() + "], use saved record.");
    			msg = (String)getAttribute("LastComment")[0];
    		}
    	
	    	if (bWithTimestamp && msg!=null) {
		    	Date dt = (Date)getAttribute("CreatedDate")[0];
		    	String createDtS = "[" + df0.format(dt) + "] ";   	
		    	msg = createDtS + msg;
	    	}
    	}
    	else {
    		l.error("History message of [" + typeCode + "] not found in hash.");
    		msg = getStringAttribute("LastComment");
    	}
    	
    	return msg;
    }
    
    public String getRecordHTML(PstUserAbstractObject u, String locale)
		throws FileNotFoundException, IOException, PmpException
    {
    	StringBuffer sBuf = new StringBuffer(1024);
    	
    	Date dt = (Date)getAttribute("CreatedDate")[0];
    	String createDtS = df0.format(dt);
    	String plainRec = getRecordString(u, locale, false).replace("[", "<b>").replace("]", "</b>");
    	
    	sBuf.append("<DIV><table><tr><td width='150' valign='baseline' class='hist_date'>");
    	sBuf.append(createDtS);
    	sBuf.append("</td><td class='blog_text'>");
    	sBuf.append(new StringBuffer(plainRec));
    	sBuf.append("</td></tr></table></DIV>");
    	
    	return sBuf.toString();
    }
    
    public static HashMap<String, String> fillHistoryHash(String locale)
    	throws FileNotFoundException, IOException
    {
    	if (locale == null) locale = "en_US";
		File histFile = new File(RESOURCE_FILE_PATH + "/" + locale + "/history.csv");
    	return StringUtil.putResourceInHash(histFile);
	}

}//End class history
