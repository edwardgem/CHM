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
//  File:   project.java
//  Author: FastPath CodeGen Engine
//  Date:   03.18.2003
//  Description:
//		Implementation of project class
//  Modification:
//		@03.18.2003aFCE File created by FastPath
//		@AGQ050106	Check for null and created a method to replace date with 20xx with xx
//
/////////////////////////////////////////////////////////////////////
//
// project.java : implementation of the project class
//

package oct.codegen;
import java.io.File;
import java.io.UnsupportedEncodingException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.HashMap;
import java.util.Hashtable;
import java.util.LinkedList;
import java.util.Stack;
import java.util.Vector;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import oct.omm.client.OmsMember;
import oct.omm.client.OmsOrganization;
import oct.omm.client.OmsSession;
import oct.pep.PepCommentVector;
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
import oct.pst.PstFlow;
import oct.pst.PstFlowConstant;
import oct.pst.PstFlowManager;
import oct.pst.PstFlowStepManager;
import oct.pst.PstTimeAbstractObject;
import oct.pst.PstUserAbstractObject;

import org.apache.log4j.Logger;

import util.Prm;
import util.PrmLog;
import util.PrmProjThread;
import util.StringUtil;
import util.Util;
import util.Util2;

/**
*
* <b>General Description:</b>  project extends PmpAbstractObject.  This class
* encapsulates the data of a member from the "project" organization.
*
* The project class provides a facility to modify data of an existing project object.
*
*
*
* <b>Class Dependencies:</b>
*   oct.custom.projectManager
*   oct.pmp.PmpUser
*   oct.pmp.PmpUserManager
*
*
* <b>Miscellaneous:</b> There are methods that will be deprecated in future versions.
*
*/


public class project extends PstTimeAbstractObject

{
	public final static String NEXT_RECORD	= "<next>";
	public final static String DELIMITER2	= "@";
	public final static String INIT_VERSION_STR	= "1.0";
	
	public final static String TYPE_TIMETRACK	= "timeTrack";
	public final static String TYPE_CONTAINER	= "container";
	public final static String TYPE_ALL			= "all";

	// project lifecycle state (status)
	public final static String ST_NEW		= "New";
	public final static String ST_OPEN		= "Open";
	public final static String ST_ONHOLD	= "On-hold";
	public final static String ST_LATE		= "Late";
	public final static String ST_COMPLETE	= "Completed";
	public final static String ST_CANCEL	= "Canceled";
	public final static String ST_CLOSE		= "Closed";
	public static final String [] STATE_ARRAY	= {ST_NEW, ST_OPEN, ST_ONHOLD, ST_LATE, ST_COMPLETE, ST_CANCEL, ST_CLOSE};

	// status for each project phases
	public static final int MAX_PHASES		= 10;
	public static final int MAX_SUBPHASES	= 10;

	public final static String PH_NEW		= "Not Started";
	public final static String PH_START		= "Started";
	public final static String PH_COMPLETE	= "Completed";
	public final static String PH_LATE		= "Late";
	public final static String PH_CANCEL	= "Canceled";
	public final static String PH_RISKY		= "High Risk";
	public static final String [] PHASE_ARRAY	= {PH_NEW, PH_START, PH_COMPLETE, PH_LATE, PH_CANCEL, PH_RISKY};
	
	// privacy type
	public final static String PRIVACY_PRIVATE		= "Private";
	public final static String PRIVACY_PUBLIC		= "Public";
	public final static String PRIVACY_PUB_READONLY	= "Public Read-only";

	// system defined project phases
	// moved to bringup.properties

	// project options
	public static final String ATTR_OPTION			= "Option";
	public static final String OP_MEMBER_UPD_PLAN	= "OP_MEMUPDPLAN";
	public static final String OP_EXPAND_TREE		= "OP_EXPTREE";
	public static final String OP_RESOURCE_MGMT		= "OP_RSCMGMT";
	public static final String OP_NOTIFY_BLOG		= "OP_NOTIFYBLOG";
	public static final String OP_NOTIFY_TASK		= "OP_NOTIFYTASK";
	public static final String OP_NO_POST			= "OP_NOPOSTING";
	public static final String [] OPTION_ARRAY		=
		{OP_MEMBER_UPD_PLAN, OP_EXPAND_TREE, OP_RESOURCE_MGMT, OP_NOTIFY_BLOG, OP_NOTIFY_TASK, OP_NO_POST};
	public static final String [] OPTION_STR		= {
					"Submit project plan change by members",
					"Expand project tree at start",
					"Support resource management",
					"Notify all team members on new blog postings",
					"Notify owner when task fails deadline",
					"Block team members from posting to the project"
					};
	public static final String [] OPTION_STR_CR		= {
					"Submit project plan change by members",
					"Expand project tree at start",
					null,
					"Notify all team members on new file postings",
					"Notify owner when task fails deadline",
					"Block team members from posting to the project"
					};
	
	public static final String PERSONAL				= "PersonalSpace";

	// other options
	// (option) the task id that contains the executive summary blog (part of option)
	public static final String EXEC_SUMMARY	= "SUMMARY_ID";
	public static final String BUG_BLOG_ID	= "BUG_BLOG_ID";
	public static final String TASK_BLOG_ID	= "TASK_BLOG_ID";
	public static final String ABBREVIATION	= "ABBRV";

	// (option) report distribution frequency
	public static final String DISTRIBUTE_FREQ	= "DISTRIBUTE";

	// distribute frequency option
	public static final String DIST_MANUALLY	= "Manually";
	public static final String DIST_DAILY		= "Daily";
	public static final String DIST_WEEKLY		= "Weekly";
	public static final String DIST_MONTHLY		= "Monthly";
	public static final String DIST_POSTED		= "WhenPosted";

	// resource management
	public static final String DEFAULT_RSC_MGMT	= "float1@hr/wk";	// Attr@Unit

	// Email
	private final static String FROM = Util.getPropKey("pst", "FROM");
	private final static String MAILFILE = "alert.htm";

	// Phase record index
	public static final int IDX_PH_NAME		= 0;
	public static final int IDX_PH_START	= 1;
	public static final int IDX_PH_PLANEX	= 2;
	public static final int IDX_PH_EXPIRE	= 3;
	public static final int IDX_PH_DONE		= 4;
	public static final int IDX_PH_STATUS	= 5;
	public static final int IDX_PH_TASKID	= 6;
	public static final int IDX_PH_EXT		= 7;

	static Logger l = PrmLog.getLog();

    //Private attributes
	private static final String UPLOAD_PATH = Util.getPropKey("pst", "FILE_UPLOAD_PATH");
    private static projectManager manager;
    private static planManager plMgr;
    private static taskManager tkMgr;
    private static planTaskManager ptMgr;
    private static attachmentManager attMgr;
    private static PstFlowManager fMgr;
    private static PstFlowStepManager fsMgr;

	static {
		try {
			manager = projectManager.getInstance();
			plMgr = planManager.getInstance();
			tkMgr = taskManager.getInstance();
			ptMgr = planTaskManager.getInstance();
			attMgr = attachmentManager.getInstance();
			fMgr = PstFlowManager.getInstance();
			fsMgr = PstFlowStepManager.getInstance();
		}
		catch (PmpException e) {
			l.error("project.java failed to initialize manager instances.");
		}
	}

	// non-static members
	private HashMap<String, Object> _criticalPathTasks;
	private ArrayList<Path> _criticalPaths;

    /**
     * Constructor for instantiating a new project.
     * @param member An OmsMember representing a project.
     */
    public project(OmsMember member)
    {
        super(member);
    }//End Constructor


    /**
     * Constructor for instantiating a new project.
     * @param user A PmpUesr.
     * @param org An organization.
     * @param memberName The name of the member.
     * @param password The password of the member.
     */
	project(PstUserAbstractObject user, OmsOrganization org, String memberName, String password)
		throws PmpException
	{
		super(user, org, memberName, password);
	}



    /**
     * Constructor for creating a project.  Used by projectManager.
     * @param user A PmpUser.
     * @param org The OmsOrganization for the project.
     */
    project(PstUserAbstractObject user, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
		super(user, org, "");
    }

    /**
     * Constructor for creating a project.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the project.
     */
    project(OmsSession session, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, "");
    }

    /**
     * Constructor for creating a project using a member name.
     * @param user A PmpUser.
     * @param org The OmsOrganization for the project.
     * @param projectMemName The member name for the created project.
     */
    project(PstUserAbstractObject user, OmsOrganization org, String projectMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(user, org, projectMemName, null);
    }

    /**
     * Constructor for creating a project using a member name.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the project.
     * @param companyMemberName The member name for the created project.
     */
    project(OmsSession session, OmsOrganization org, String projectMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, projectMemName, null);
    }


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
    }//End appendAttribute

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

    public static String displayPhase(String bgcolor, String numS, String phName,
    		String oriStartDateS, String oriExpDateS,
    		String plStartDateS,  String plExpDateS,
    		String acStartDateS,  String acDoneDateS,
    		String phStatus, String host)
    {
// @AGQ050106
    	StringBuffer sBuf = new StringBuffer(4096);
		plStartDateS	= replaceYear(plStartDateS);	// replace 20xx with xx
		plExpDateS = replaceYear(plExpDateS);
		acStartDateS	= replaceYear(acStartDateS);
		acDoneDateS	= replaceYear(acDoneDateS);

		sBuf.append("<tr " + bgcolor + ">");

		sBuf.append("<td>&nbsp;</td>");
		sBuf.append("<td>");
		sBuf.append("<table width='100%' " + bgcolor +" border='0' cellspacing='2' cellpadding='2'>");
		sBuf.append("<tr>");
		if (numS.indexOf(".") != -1)
			sBuf.append("<td width='12'>&nbsp;</td>");
		sBuf.append("<td class='plaintext_grey' width='12' valign='top'>&nbsp;");
		sBuf.append(numS + "</td>");
		sBuf.append("<td>&nbsp;");
		sBuf.append(phName);
		sBuf.append("</td></tr></table></td>");

		// status
		if (host == null) host = "..";
		String dot = host + "/i/";
// @AGQ050106
		String s = (phStatus != null)?phStatus:"";
		if (s.equals(PH_NEW)) dot += "dot_white.gif";
		else if (s.equals(PH_START)) dot += "dot_lightblue.gif";
		else if (s.equals(PH_COMPLETE)) dot += "dot_green.gif";
		else if (s.equals(PH_LATE)) dot += "dot_red.gif";
		else if (s.equals(PH_CANCEL)) dot += "dot_cancel.gif";
		else if (s.equals(PH_RISKY)) dot += "dot_orange.gif";
		else {dot += "dot_grey.gif";}
		sBuf.append("<td colspan='2'>&nbsp;</td>");
		sBuf.append("<td class='listlink' width='42' align='center'>");
		sBuf.append("<img src='" + dot + "' title='" + s + "'>");
		sBuf.append("</td>");

		// original start date
		sBuf.append("<td colspan='2'><img src='" + host + "/i/dot_orange.gif' width='7'/></td>");
		sBuf.append("<td class='listtext_small' width='53' align='center'>");
		sBuf.append(oriStartDateS);
		sBuf.append("</td>");

		// original due date
		sBuf.append("<td colspan='2'>&nbsp;</td>");
		sBuf.append("<td class='listtext_small' width='53' align='center'>");
		sBuf.append(oriExpDateS);
		sBuf.append("</td>");

		// plan start date
		sBuf.append("<td colspan='2'><img src='" + host + "/i/dot_blue.gif' width='7'/></td>");
		sBuf.append("<td class='listtext_small' width='53' align='center'>");
		sBuf.append(plStartDateS);
		sBuf.append("</td>");

		// plan due date
		sBuf.append("<td colspan='2'>&nbsp;</td>");
		sBuf.append("<td class='listtext_small' width='53' align='center'>");
		sBuf.append(plExpDateS);
		sBuf.append("</td>");

		// actual start (effective) date
		sBuf.append("<td colspan='2'><img src='" + host + "/i/dot_green.gif' width='7'/></td>");
		sBuf.append("<td class='listtext_small' width='53' align='center'>");
		sBuf.append(acStartDateS);
		sBuf.append("</td>");

		// actual finish (completion date)
		sBuf.append("<td colspan='2'>&nbsp;</td>");
		sBuf.append("<td class='listtext_small' width='53' align='center'>");
		sBuf.append(acDoneDateS);
		sBuf.append("</td>");

		sBuf.append("</tr>");
		sBuf.append("<tr " + bgcolor + ">" + "<td colspan='23'><img src='"
				+ host + "spacer.gif' width='2' height='2'></td></tr>");

		return sBuf.toString();
	}//End displayPhase

    /**
     * Replace date from 20xx to xx
     * @param dateS
     * @return The correct date format or "" if null
     */
    private static String replaceYear(String dateS) {
// @AGQ050106
    	if (dateS != null && dateS.length() > 0) {
    		return dateS.replaceAll("(/20)(..$)", "/$2");
    	}
    	else
    		return "-";
    }

	// Calculate optimal schedule: shrink deadline based on duration and children.
	public void optimizeSchedule(PstUserAbstractObject u)
		throws PmpException
	{
		// get latest project plan: there is only one
		planManager planMgr = planManager.getInstance();
		int [] ids = planMgr.findId(u, "Status='Latest' && ProjectID='" +getObjectId()+ "'");

		// start from top level tasks, and then recursively optimize each subtree
		Date dt, bestExpD = (Date)getAttribute("StartDate")[0];
		bestExpD = new Date(bestExpD.getTime() + 86400000);		// project at least 1 day long
		int [] ptId = ptMgr.findId(u, "PlanID='" + ids[0] + "' && ParentID='0' && Status!='Deprecated'");
		for (int i=0; i<ptId.length; i++)
		{
			dt = optimizeSubtree(u, ptId[i]);	// recursively set and save optimal deadline
			if (dt!=null && dt.after(bestExpD))
				bestExpD = dt;
		}

		// check to see if I can move my deadline to end earlier
		if (bestExpD.compareTo((Date)getAttribute("ExpireDate")[0]) != 0)
		{
			setAttribute("ExpireDate", bestExpD);
			setAttribute("LastUpdatedDate", new Date());
			manager.commit(this);
		}
	}	// END optimizeSchedule()


	// Recursively calculate optimal schedule of a subtree.
	private Date optimizeSubtree(PstUserAbstractObject u, int ptId)
		throws PmpException
	{
		planTask pt = (planTask)ptMgr.get(u, ptId);
		task tk = (task)tkMgr.get(u, (String)pt.getAttribute("TaskID")[0]);
		Date tkExpD = (Date)tk.getAttribute("ExpireDate")[0];
		Date bestExpD = (Date)tk.getAttribute("StartDate")[0];
		bestExpD = new Date(bestExpD.getTime() + 86400000);		// task at least 1 day long

		// recursively check with all my immediate children to see if I can shrink my schedule
		int [] ptIdArr = ptMgr.findId(u, "ParentID='" +ptId+ "' && Status!='Deprecated'");
		Date childExpD;
		for (int i=0; i<ptIdArr.length; i++)
		{
			childExpD = optimizeSubtree(u, ptIdArr[i]);
			if (childExpD!=null && bestExpD!=null && childExpD.after(bestExpD))
				bestExpD = childExpD;			// I cannot end before my children (Task Rule 3)
		}

		if (bestExpD!=null && tkExpD!=null && bestExpD.before(tkExpD))
		{
			// check my duration requirement to see if I can move deadline to my children's expD
			int duration = ((Integer)tk.getAttribute("Duration")[0]).intValue();
			Date dt = (Date)tk.getAttribute("StartDate")[0];
			if (duration>0 && dt!=null)
			{
				// if there is a duration specified, you have to respect and enforce that
				GregorianCalendar cal = new GregorianCalendar();
				cal.setTime(dt);
				cal.add(Calendar.DATE, duration);
				dt = cal.getTime();		// ExpireDate based on duration
				if (dt.after(bestExpD))
					bestExpD = dt;
			}
		}

		if (bestExpD!=null && tkExpD!=null && bestExpD.compareTo(tkExpD) != 0)
		{
			// bestExpD shouldn't be after tkExpD if things were always right.  But just in case.
			tk.setAttribute("ExpireDate", bestExpD);
			tk.setAttribute("LastUpdatedDate", new Date());
			tkMgr.commit(tk);

			// whenever my ExpireDate is changed, I need to make sure my dependents are ok
			tk.setSaveMyDependentsDates(u);	// set and commit
		}

		return bestExpD;
	}	// END optimizeSubtree()

	// Calculate schedule by dependencies.  Leave the task if it has no dependencies defined
	// and Gap == 0.
	public void setScheduleByDependencies(PstUserAbstractObject u)
		throws PmpException
	{
		// this project will be updated if any of my tasks are updated
		task tk;
		int [] ids = tkMgr.findId(u, "ProjectID='" + getObjectId() + "'");
		for (int i=0; i<ids.length; i++)
		{
			tk = (task)tkMgr.get(u, ids[i]);
			if ((String)tk.getAttribute("Dependency")[0] == null)
			{
				// no dependency, check Gap
				if ( ((Integer)tk.getAttribute("Gap")[0]).intValue() == 0 )
					continue;	// no dependency and 0 Gap, leave intact
			}
			if (tk.setPlanDates(u))
			{
				tk.setAttribute("LastUpdatedDate", new Date());
				tkMgr.commit(tk);
			}
		}
	}	// END setScheduleByDependencies()
	
	/**
	 * Set the project's ExpireDate by evaluating all its tasks and adopt the latest ExpireDate
	 * @param u
	 * @return
	 */
	public Date setDueDateBySchedule(PstUserAbstractObject u)
		throws PmpException
	{
		Date oldExpire = getExpireDate();
		Date expireDt = new Date(0);
		Date dt;
		int [] ids = getCurrentTasks(u);
		for (int tid : ids) {
			task tObj = (task)tkMgr.get(u, tid);
			dt = tObj.getExpireDate();
			if (dt.after(expireDt)) {
				expireDt = dt;
			}
		}
		if (oldExpire.compareTo(expireDt) != 0) {
			setAttribute("ExpireDate", expireDt);
			setAttribute("LastUpdatedDate", new Date());
			save();
			l.info("setDueDateBySchedule() updated project [" + getObjectId() + "] due date to "
					+ expireDt.toString());
		}
		return expireDt;
	}

	// the project name now always append "@@12345" at the end where 12345 is the creator uId
	public String getDisplayName()
	{
		int idx;
		String displayName;
		String name = getObjectName();
		if ((idx = name.indexOf("@@")) != -1)
			displayName = name.substring(0, idx);
		else
			displayName = name;
		return displayName;
	}

	// calculate the total MB that the attachment of this project took up
	public int getProjectSpace(PstUserAbstractObject u)
	{
		try
		{
			long size = 0;
			File f;
			String path;
			PstAbstractObject att;
			int [] ids = attMgr.findId(u, "ProjectID='" + getObjectId() + "'");
			for (int i=0; i<ids.length; i++)
			{
				// go through each attachment and sum up the total size
				att = attMgr.get(u, ids[i]);
				path = UPLOAD_PATH + (String)att.getAttribute("Location")[0];
				f = new File(path);
				size += f.length();			// this is in B
			}
			if (size > 1000000)
				return (int)(size/1000000);	// convert to MB
			else
				return 1;					// less than 1 MB
		}
		catch (PmpException e)
		{
			e.printStackTrace();
			return -1;
		}
	}

	/**
	 * setOption() set the option value for the specified optionName.
	 * If the optionValue is null, then the option is removed entirely.
	 * If the optionName:optionValue already exists, then there is no action.
	 * Note that optionName may not have a value in which case the optionValue
	 * parameter should be an empty string.
	 * @param optionName name of the option.
	 * @param optionValue the value to be set.  Null to unset this option.
	 * @return void
	 * @throws PmpException
	 */
	public void setOption(String optionName, String optionValue)
		throws PmpException
	{
		setOption(manager, optionName, optionValue);
	}
	
	static final SimpleDateFormat df0 = new SimpleDateFormat ("MM/dd/yy");
	/**
	 * Display an <img> tag for the color dot that represent the project status
	 * @return return a self-contained <img> tag.  Caller should put it in a <td> of some sort.
	 */
	public String getStatusDisplay(PstUserAbstractObject u, boolean bUpdated)
		throws PmpException
	{
		String status = getStringAttribute("Status");
		String dot = "../i/";
		StringBuffer sBuf = new StringBuffer(256);
		
		// dates
		String doneDateS;
		Date dt = getCompleteDate();
		if (dt != null) doneDateS = df0.format(dt);
		else doneDateS = null;

		
		if (isContainer()) {dot += "db.jpg"; status = "Container";}	// container project
		else if (status.equals(project.ST_OPEN)) {dot += "dot_lightblue.gif";}
		else if (status.equals(project.ST_NEW)) {dot += "dot_orange.gif";}
		else if (status.equals(project.ST_ONHOLD)) {dot += "dot_grey.gif";}
		else if (status.equals(project.ST_CANCEL)) {dot += "dot_cancel.gif";}
		else if (status.equals(project.ST_COMPLETE)) {
			dot += "dot_green.gif";
			if (doneDateS != null) status += " on " + doneDateS;
		}
		else if (status.equals(project.ST_LATE)) {
			// Late can be completed depending on whether CompletedDate is set
			if (doneDateS != null) {
				sBuf.append("<img src='../i/dot_green.gif' title='Completed on " + doneDateS + "'>");
			}
			sBuf.append("<img src='../i/dot_red.gif' title='Late'>");
		}
		else if (status.equals(project.ST_CLOSE)) {
			// Closed can be coming from either Canceled or Completed
			String lastStatus = null;
			if (doneDateS != null) {
				dot += "dot_green.gif";
				lastStatus = project.ST_COMPLETE + " on " + doneDateS;
			}
			else {
				dot += "dot_cancel.gif";
				lastStatus = project.ST_CANCEL;
			}
			sBuf.append("<img src='" + dot + "' title='" + lastStatus + "'>");
			sBuf.append("<img src='../i/dot_black.gif' title='Closed'>");
		}
		else {dot += "dot_grey.gif";}

		if (!status.equals(project.ST_CLOSE) && !status.equals(project.ST_LATE)) {
			sBuf.append("<img src='" + dot + "' title='" + status + "'>");
		}

		if (bUpdated) {
			String updatedDtS = "";
			dt = (Date) getAttribute("LastUpdatedDate")[0];
			if (dt != null) updatedDtS = " on " + df0.format(dt);
			sBuf.append("<img src='../i/dot_redw.gif' title='Updated " + updatedDtS + "'>");
		}
		
		return sBuf.toString();
	}

	public String getTaskByHeader(PstUserAbstractObject u, String headerNumS)
		throws Exception
	{
		String latestPlanIdS = getLatestPlan(u).getObjectName();
		Stack planStack = PrmProjThread.setupPlan(
							0,		// fill all levels
							null,	// no HttpSession object
							null,	// no current stack
							u,
							String.valueOf(getObjectId()),
							latestPlanIdS,
							false	// not called by CR
							);
		HashMap<String, String> taskMap = new HashMap<String, String>(100);

		Object[] pLevel;
		Object[] pOrder;
		int level, order;
		Vector rPlan = (Vector) planStack.peek();
		String[] levelInfo = new String[10];

		for (int i = 0; i < rPlan.size(); i++) {
			Hashtable rTask = (Hashtable) rPlan.elementAt(i);
			String taskIdS = (String) rTask.get("TaskID");
			pLevel = (Object[]) rTask.get("Level");
			pOrder = (Object[]) rTask.get("Order");

			level = ((Integer) pLevel[0]).intValue();
			order = ((Integer) pOrder[0]).intValue() + 1;

			if (level == 0) {
				levelInfo[level] = Integer.toString(order);
			} else {
				levelInfo[level] = levelInfo[level - 1] + "." + order;
			}

			// save the taskID into map for later use in building dependencies
			taskMap.put(levelInfo[level], taskIdS);
		}
		return taskMap.get(headerNumS);
	}
	
	private int[] getTasksFromPlantasks(PstUserAbstractObject u, int[] ptIds)
		throws PmpException
	{
		PstAbstractObject [] oArr = ptMgr.get(u, ptIds);
		int [] tkIds = new int[ptIds.length];
		for (int i=0; i<oArr.length; i++) {
			tkIds[i] = Integer.parseInt((String) oArr[i].getAttribute("TaskID")[0]);
		}
		return tkIds;
	}

	public int [] getTopLevelTasks(PstUserAbstractObject u)
		throws PmpException
	{
		int [] ids = plMgr.findId(u, "ProjectID='" + getObjectId()
				+ "' && Status=='" + plan.ST_LATEST +"'");
		// there should only be one latest plan
		
		// the currently active plantasks
		int [] ptIds = ptMgr.findId(u, "PlanID='" + ids[0]
		                + "' && Status!='" + planTask.ST_DEPRECATED + "' && ParentID='0'");
		return getTasksFromPlantasks(u, ptIds);
	}
	
	public Date getLatestTaskExpireDate(PstUserAbstractObject u)
		throws PmpException
	{
		int [] tids = getTopLevelTasks(u);
		Date dt;
		Date latestDt = new Date(0);
		for (int i=0; i<tids.length; i++) {
			task t = (task) tkMgr.get(u, tids[i]);
			dt = t.getExpireDate();
			if (dt!=null && dt.after(latestDt)) latestDt = dt;
		}
		return latestDt;
	}

	public int [] getCurrentTasks(PstUserAbstractObject u)
		throws PmpException
	{
		int [] ids = plMgr.findId(u, "ProjectID='" + getObjectId()
						+ "' && Status=='" + plan.ST_LATEST +"'");
		// there should only be one latest plan

		// the currently active plantasks
		int [] ptIds = ptMgr.findId(u, "PlanID='" + ids[0]
		                + "' && Status!='" + planTask.ST_DEPRECATED + "'");

		// from the current plan tasks get the current tasks
		return getTasksFromPlantasks(u, ptIds);
	}

	public int [] mergeCurrentTasks(PstUserAbstractObject u, int [] tids)
		throws PmpException
	{
		int [] active = getCurrentTasks(u);
		return Util2.mergeJoin(tids, active);
	}

	public boolean isInCriticalPath(PstUserAbstractObject u, String taskIdS, boolean reCalculate)
		throws PmpException
	{
		if (_criticalPathTasks==null || reCalculate) {
			// need recal the critical path
			getCriticalPaths(u, true, null);
		}
		return _criticalPathTasks.containsKey(taskIdS);
	}

	public ArrayList<Path> getCriticalPaths()
	{
		return _criticalPaths;
	}

	/**
	  getCriticalPath evaluate all tasks of this project that have dependencies
	  and returns the longest paths.  Note that two paths may have the same
	  path length and therefore this method returns a list of paths, each being
	  a list of task.
	  @param user
	  @param force recalculate
	  @param if not null, allDepPaths will return all the dependency paths in the
	  project
	*/
	public ArrayList<Path> getCriticalPaths(
			PstUserAbstractObject u,
			boolean bRecalculate,
			ArrayList<Path> allDepPaths)
		throws PmpException
	{
		if (_criticalPaths!=null && !bRecalculate) {
			return _criticalPaths;
		}
		_criticalPaths = new ArrayList<Path>();
		_criticalPathTasks = new HashMap<String, Object>();

		boolean bSaveAllDepPaths = false;
		if (allDepPaths != null) {
			bSaveAllDepPaths = true;
			if (!allDepPaths.isEmpty()) {
				allDepPaths.clear();
			}
		}

		// start from all tasks that are dependent by others but not dependent on any,
		// i.e. the head of a network of activities (head tasks)
		int max = 0;

		// ECC: note that some tasks might be deleted from the current plan
		// but we still keep them for the sake of remembering the history.
		int [] taskIds = tkMgr.findId(u,
				"ProjectID='" + getObjectId() + "' && Dependency=null");	// I don't depend on anyone

		//need to get only the currently active tasks
		int [] active = getCurrentTasks(u);		// I need this below
		taskIds = Util2.mergeJoin(taskIds, active);
		PstAbstractObject [] tkArr = tkMgr.get(u, taskIds);

		for (int i=0; i<tkArr.length; i++) {
			task tk = (task)tkArr[i];
			if (!tk.hasNoDependentChild(u, active)) {
				// get the longest path of this task (inclusive)
				ArrayList<Path> tempLongest = new ArrayList<Path>();
				ArrayList<Path> tempAll = null;
				if (bSaveAllDepPaths) {
					tempAll = new ArrayList<Path>();
				}

				int len = longestPaths(u, tk, tempLongest, tempAll, active);
				if (len >= max) {
					// this is the longest, add to the result list
					if (len > max) {
						max = len;
						_criticalPaths = new ArrayList<Path>();	// empty the old ones
					}
					_criticalPaths.addAll(tempLongest);
				}

				if (bSaveAllDepPaths && tempAll.size()>0) {
					allDepPaths.addAll(tempAll);	// save all paths of this head task
				}
			}
		}

		// we now have the critical paths, remember the tasks that are in them in a Hash
		if (_criticalPaths.size() > 0) {
			for (Path path: _criticalPaths) {
				for (task tk: path.getPath()) {
					addToCriticalPath(tk);
				}
			}
		}
		return _criticalPaths;
	}

	/**
	    return the longest path of (including) the pass-in task.  There can be several paths
		of equally long paths.
		if this task has no child, then its duration is longest with itself put
		into the return list.
		@param u user.
		@param tk the task to be explored for longest path after it.
		@param pathsList contains the longest paths.
		@param allPathsList if this is not null, return all the paths after this task (inclusive).
	*/
	private static int longestPaths(
			PstUserAbstractObject u,
			task tk,
			ArrayList<Path> pathsList,
			ArrayList<Path> allPathsList,
			int [] activeTids)
		throws PmpException
	{
		if (tk.hasNoDependentChild(u, activeTids)) {
			Path resPath = new Path();
			resPath.addFirst(tk);
			pathsList.add(resPath);
			if (allPathsList != null) {
				allPathsList.add(resPath);
			}
			return resPath.min();
		}

		// explore all of my dependent children and return the longest path
		ArrayList<Path> resultLongest = new ArrayList<Path>();
		ArrayList<Path> resultAll = null;
		if (allPathsList != null) {
			resultAll = new ArrayList<Path>();
		}

		int max = 0;	// not counting myself
		PstAbstractObject [] depChildren = tk.getDependentChildren(u, activeTids);
		for (PstAbstractObject child: depChildren) {
			ArrayList<Path> tempLongest = new ArrayList<Path>();
			ArrayList<Path> tempAll = null;
			if (allPathsList != null) {
				tempAll = new ArrayList<Path>();
			}

			int len = longestPaths(u, (task)child, tempLongest, tempAll, activeTids);
			if (len >= max) {
				// this is the longest path, might have same length paths already
				if (len > max) {
					max = len;
					resultLongest = new ArrayList<Path>();	// empty the old ones
				}
				resultLongest.addAll(tempLongest);
			}

			if (allPathsList!=null && tempAll.size()>0) {
				resultAll.addAll(tempAll);
			}
		}

		// the longest path after this task is in result, include tk now
		// resultAll is a super set of resultLongest, if it exists
		if (allPathsList != null) {
			for (Path path: resultAll) {
				path.addFirst(tk);		// add to head
			}
			allPathsList.addAll(resultAll);
		}
		else {
			// we do not accumulate for all paths, just do it for longest
			for (Path path: resultLongest) {
				path.addFirst(tk);		// add to head
			}
		}

		pathsList.addAll(resultLongest);
		if (pathsList.size() <= 0) return 0;
		return pathsList.get(0).min();	// all path are of same length
	}


	private void addToCriticalPath (task tk)
	{
		_criticalPathTasks.put(String.valueOf(tk.getObjectId()), null);
	}

	////////////////////////////////////////////////////////////////////////
	// Workflow

	/**
	 * Create a <code>PstFlow</code> object as a flow instance representing this project.
	 * @param login user.
	 * @return <code>PstFlow</code> flow instance of this project.
	 * @throws PmpException
	 */
	public PstFlow createProjectFlow(PstUserAbstractObject u)
		throws PmpException
	{
		PstFlow projFlow = getProjectFlow(u);

		// do not create it if I already have one
		if (projFlow == null) {
			projFlow =
				(PstFlow)fMgr.create(u, PstFlowConstant.FLOW_TYPE_PROJECT, null, PstFlow.TYPE_PROJTASK);

			// set the project ID into the ContextObject
			projFlow.setAttribute(PstFlow.CONTEXT_OBJECT, String.valueOf(getObjectId()));
			fMgr.commit(projFlow);
		}

		return projFlow;
	}

	/**
	 * Get the flow instance object of this project
	 * @param u Login user.
	 * @return PstFlow instance.
	 * @throws PmpException
	 */
	public PstFlow getProjectFlow(PstUserAbstractObject u)
		throws PmpException
	{
		int [] ids = fMgr.findId(u,
				PstFlow.CONTEXT_OBJECT + "='" + getObjectId() + "'");
		if (ids.length <= 0)
			return null;	// no flow instance for this project

		return (PstFlow)fMgr.get(u, ids[0]);	// there should only be one project flow
	}

	/**
	 * Move the flow instance object of this project to <code>OPEN</code> state.
	 * Note that no step will be created here; they will be created when the task
	 * is <code>OPEN</code>
	 * @param u Login user.
	 * @throws PmpException
	 */
	public void startProjectFlow(PstUserAbstractObject u)
	throws PmpException
	{
		PstFlow projFlow = getProjectFlow(u);
		if (projFlow != null) {
			projFlow.setStatus(PstFlowConstant.ST_FLOW_OPEN);
		}
	}

	public plan getLatestPlan(PstUserAbstractObject u)
		throws PmpException
	{
		planManager planObjMgr = planManager.getInstance();
		int [] ids = planObjMgr.findId(u,
				"Status='Latest' && ProjectID='" + getObjectId() + "'");
		PstAbstractObject [] targetObjList = planObjMgr.get(u, ids);
		if (targetObjList.length <= 0)
		{
			String msg = "Corrupted project plan.  Cannot find plan object for project ["
				+ getObjectId() + "]";
			l.error(msg);
			throw new PmpException(msg);
		}

		// there is only one plan which is latest for this project
		return (plan)targetObjList[0];
	}

	/**
	 * set the state of the project.  This may impact the work steps of the tasks in
	 * this project.
	 *
	 */
	public void setState(PstUserAbstractObject u, String newState)
		throws PmpException
	{
		String currentState = getState();
		if (currentState == null) currentState = ST_NEW;

		if (newState==null || currentState.equals(newState) || currentState.equals(ST_CLOSE)) {
			return;
		}

		boolean bNeedToHandleChildrenTask = false;
		Date today = Util.getToday();
		String historyID = "";

		// NEW TO OPEN
		if (newState.equals(ST_OPEN)
				&& (currentState.equals(ST_NEW))
					|| (currentState.equals(ST_ONHOLD) || (currentState.equals(ST_LATE))) ) {
			// start or re-open the project
			if (currentState.equals(ST_NEW)) {
				Date startDt = getStartDate();
				if (startDt==null || startDt.after(today)) {
					setAttribute("StartDate", today);
				}
				bNeedToHandleChildrenTask = true;	// turn New tasks to Open

				// move the project flow to OPEN
				this.startProjectFlow(u);
			}
			else {
				// re-open: move steps from on-hold OR late to active again
			}
			historyID = "HIST.3110";
		}
		
		// CANCEL to OPEN
		else if (newState.equals(ST_OPEN) && currentState.equals(ST_CANCEL)) {
			bNeedToHandleChildrenTask = true;	// turn New tasks to Open

			// move the project flow to OPEN
			this.startProjectFlow(u);
			historyID = "HIST.3117";
		}

		// to COMPLETE
		else if (newState.equals(ST_COMPLETE) && !currentState.equals(ST_CLOSE)) {
			setAttribute("CompleteDate", today);
			bNeedToHandleChildrenTask = true;		// turn all tasks to Completed
			historyID = "HIST.3113";
		}

		// to ON-HOLD
		else if (newState.equals(ST_ONHOLD)
				&& !currentState.equals(ST_NEW) && !currentState.equals(ST_CANCEL)
				&& !currentState.equals(ST_COMPLETE) && !currentState.equals(ST_CLOSE) ) {
			// all step objects of this project are to be put on-hold
			// but there is no on-hold state for step: this has to be induced from project state
			// don't touch the task state
			historyID = "HIST.3111";
		}

		// to LATE
		else if (newState.equals(ST_LATE)
				&& !currentState.equals(ST_NEW) && !currentState.equals(ST_CANCEL)
				&& !currentState.equals(ST_COMPLETE) && !currentState.equals(ST_CLOSE) ) {
			// step state will be handled by themselves
			historyID = "HIST.3115";
		}

		// to CANCEL
		else if (newState.equals(ST_CANCEL)
				&& !currentState.equals(ST_COMPLETE) && !currentState.equals(ST_CLOSE) ) {
			// all step objects of this project are to be aborted
			// simply cancel the tasks, which will handle the steps
			task aTask;
			int [] ids = getCurrentTasks(u);
			for (int i=0; i<ids.length; i++) {
				aTask = (task) tkMgr.get(u, ids[i]);
				aTask.setState(u, task.ST_CANCEL);	// will abort step also
			}
			historyID = "HIST.3112";
		}

		// to CLOSE
		else if (newState.equals(ST_CLOSE)
				&& (currentState.equals(ST_CANCEL) || currentState.equals(ST_COMPLETE)) ) {
			// nothing to do
			historyID = "HIST.3114";
		}

		// invalid state transition
		else {
			throw new PmpException("Project [" + getDisplayName() + "] cannot transition " +
					"from " + currentState + " to " + newState);
		}


		///////////////////////////////////
		// commit the update
		setAttribute("Status", newState);
		setAttribute("LastUpdatedDate", new Date());
		manager.commit(this);

		if (historyID != "") {
			history.addRecord(u, historyID,
					(String)getAttribute("TownID")[0], null,
					String.valueOf(getObjectId()));
		}

		///////////////////////////////////
		// handle children tasks
		if (bNeedToHandleChildrenTask) {
			int [] tids = getCurrentTasks(u);
			task t;
			//Date today = new Date();
			for (int i=0; i<tids.length; i++)
			{
				t = (task)tkMgr.get(u, tids[i]);
				if (t.isContainer())
					continue;

				String taskStatus = (String)t.getAttribute("Status")[0];
				if (taskStatus.equals(task.ST_ONHOLD) && newState.equals(ST_COMPLETE)) {
					// Task Completed, Subtasks that are on-hold become Canceled
					t.setState(u, task.ST_CANCEL);
				}
				else if (!taskStatus.equals(task.ST_CANCEL)
						&& !taskStatus.equals(task.ST_LATE)
						&& newState.equals(task.ST_COMPLETE)) {
					// Tasks with Canceled or Late status will not be changed to Complete
					t.setState(u, newState);
				}
				else if (newState.equals(ST_OPEN) && currentState.equals(ST_NEW) && !Prm.isCR()) {
					// call task.setStatusByDate() which will check dependencies to make sure
					// I am OK to move to OPEN or LATE
					t.setStatusByDates(u);	// ECC
				}
				else if (newState.equals(ST_OPEN) && currentState.equals(ST_CANCEL)) {
					// re-open, need to first set the task to OPEN in order for setStatusByDates() to work
					t.setAttribute(task.ATTR_STATUS, task.ST_OPEN);
					t.setStatusByDates(u);
				}

				// set CompleteDate of tasks only if complete date is null
				if (newState.equals(ST_COMPLETE) && t.getCompleteDate()==null) {
					if(!taskStatus.equals(task.ST_CANCEL) && !taskStatus.equals(task.ST_ONHOLD)) {
						// @102504AGQ
						// Tasks with Canceled or On-hold Status will not have a CompletedDate
						t.setAttribute("CompleteDate", today);
					}
				}
				tkMgr.commit(t);
			}
		}	// END: if bNeedToHandleChildrenTask
		
		notify(currentState, newState);
	}	// END: setState()

	private void notify(String currentState, String newState)
	{
		// Email notification to team members
		String stS = "has been ";
		if (newState.equals(ST_NEW)) {
			if (currentState.equals(ST_CANCEL) || currentState.equals(ST_ONHOLD)) {
				stS += " RE-OPENED. ";
			}
			else {
				stS += "moved to OPEN. ";
			}
		}
		int pjId = getObjectId();
		
		Object [] toArr;
		try {toArr = getAttribute("TeamMembers");}
		catch (PmpException e) {
			l.error("project.notify() failed to get TeamMembers attribute.  No Email send.");
			return;
		}
		
		String subj = "[" + Prm.getAppTitle() + "] Re-open project: " + getDisplayName();
		String linkS = "<a href='" + Prm.getPrmHost() + "/project/proj_top.jsp?projId=" + pjId + "'>"
								+ getDisplayName() + "</a>";
		String msg = "The project [" + linkS + "] (" + pjId + ") ";
		msg += stS;
		msg += "You are invited to work on the project now.<br><br>";
		
		if (!Util.sendMailAsyn(FROM, toArr, null, null, subj, msg, MAILFILE)) {
			l.error("!!! Error sending task dependency notification message");
		}
	}


	/**
	 * Take an int array of step Ids and remove from it all those steps that
	 * have projects in the on-hold state.
	 * @return int array that contains only open steps.
	 */
	public static int [] filterOnHoldSteps(PstUserAbstractObject u, int [] stepIdArr)
		throws PmpException
	{
		String onHoldPjIdS = "";
		int [] ids = manager.findId(u, "Status='" + project.ST_ONHOLD + "'");
		for (int i=0; i<ids.length; i++) onHoldPjIdS += ids[i] + ";";
		return filterSteps(u, stepIdArr, onHoldPjIdS, true);
	}

	/**
	 *
	 * @param u
	 * @param stepIdArr
	 * @return
	 * @throws PmpException
	 */
	public static int [] filterMyProjectSteps(PstUserAbstractObject u, int [] stepIdArr)
		throws PmpException
	{
		String myProjectStr = "";
		int [] ids = manager.getProjects(u, false);
		for (int i=0; i<ids.length; i++) myProjectStr += ids[i] + ";";
		return filterSteps(u, stepIdArr, myProjectStr, false);
	}

	/**
	 * Either filter in or filter out the projects that is found in the filterPjStr
	 * @param u
	 * @param stepIdArr
	 * @param filterPjStr
	 * @param bFilterOut true if it is to exclude filterPjStr, false if to include only.
	 * @return
	 * @throws PmpException
	 */
	public static int [] filterSteps(PstUserAbstractObject u,
			int [] stepIdArr, String filterPjStr, boolean bFilterOut)
		throws PmpException
	{
		PstAbstractObject step;
		String s;

		if (filterPjStr != "") {
			int ct = stepIdArr.length;
			for (int i=0; i<stepIdArr.length; i++) {
				step = fsMgr.get(u, stepIdArr[i]);
				s = (String)step.getAttribute("ProjectID")[0];
				if ( s == null ||
						(bFilterOut && filterPjStr.contains(s)) ||
						(!bFilterOut && !filterPjStr.contains(s)) ) {
					stepIdArr[i] = -1;
					ct--;
				}
			}
			if (ct <= 0) {
				stepIdArr = new int[0];	// no WI left
			}
			else {
				int [] temp = new int[ct];
				ct = 0;
				for (int i=0; i<stepIdArr.length; i++) {
					if (stepIdArr[i] != -1) temp[ct++] = stepIdArr[i];
				}
				stepIdArr = temp;
			}
		}
		return stepIdArr;
	}

	/**
	 *
	 * @param u
	 * @param step
	 * @return the State of the project associated to the step.  If project is not found, return null.
	 * @throws PmpException
	 */
	public static String getStepProjectState(PstUserAbstractObject u, PstAbstractObject step)
		throws PmpException
	{
		String pjIdS = (String) step.getAttribute("ProjectID")[0];
		if (pjIdS == null) return null;
		PstAbstractObject pj = manager.get(u, Integer.parseInt(pjIdS));
		if (pj == null) return null;
		return (String)pj.getAttribute("Status")[0];
	}
	
	/**
	 */
	public void setAsContainer(boolean bSet)
		throws PmpException
	{
		if (bSet) {
			setAttribute("ExpireDate", null);
		}
		else {
			setAttribute("ExpireDate", new Date());
		}
		manager.commit(this);
		return;
	}
	
	/**
	 */
	public boolean isContainer()
		throws PmpException
	{
		return getExpireDate()==null;
	}
	
	/**
	 */
	public static project createPersonalProject(PstUserAbstractObject u)
		throws PmpException
	{
		int myUid = u.getObjectId();
		String name = u.getStringAttribute("FirstName");
		if (StringUtil.isNullOrEmptyString(name)) name = u.getStringAttribute("LastName");
		if (StringUtil.isNullOrEmptyString(name)) name = u.getObjectName();
		name += "'s Personal Space@@" + myUid;
		
		// check to make sure the personal space under the uid doesn't exist
		String tmp = "%Personal Space@@" + myUid;
		int [] ids = manager.findId(u, "om_acctname='" + tmp + "'");
		if (ids.length > 0) {
			// found existing personal space for this user
			throw new PmpException("Create failed - Duplicate Personal Space found for user [" + myUid + "].");
		}
		
		
		project newPj = (project) manager.create(u, name);
		
		// set basic attributes
		Date today = Util.getToday();
		newPj.setAttribute("Creator", String.valueOf(myUid));
		newPj.setAttribute("Owner", String.valueOf(myUid));
		newPj.setAttribute("Company", u.getStringAttribute("Company"));
		newPj.setAttribute("TownID", u.getStringAttribute("Company"));
		newPj.setAttribute("Type", PRIVACY_PRIVATE);
		newPj.setAttribute("Option", OP_EXPAND_TREE + DELIMITER + PERSONAL);	// key to identify this as personal space
		newPj.setAttribute("Status", ST_OPEN);
		newPj.setAttribute("TeamMembers", myUid);
		newPj.setAttribute("CreatedDate", today);
		newPj.setAttribute("StartDate", today);
		newPj.setAttribute("LastUpdatedDate", today);
		newPj.setAttribute("Version", INIT_VERSION_STR);
		
		String s = ((user)u).getFullName() + "'s personal project workspace";
		//newPj.setRawAttribute("Description", s);
		try {newPj.setAttribute("Description", s.getBytes("UTF-8"));}
		catch (UnsupportedEncodingException e) {} 	//UTF

		manager.commit(newPj);
		
		newPj.initPlan(u);			// create plan for the project
		newPj.createProjectFlow(u);	// workflow
		
		return newPj;
	}
	
	/**
	 */
	public plan initPlan(PstUserAbstractObject u)
		throws PmpException
	{
		Date today = new Date();
		SimpleDateFormat df1 = new SimpleDateFormat("MMM dd, yyyy");
		planManager planMgr = planManager.getInstance();
		
		plan planObj = (plan)planMgr.create(u);
		planObj.setAttribute("ProjectID", String.valueOf(getObjectId()));
		planObj.setAttribute("Status", plan.ST_LATEST);
		planObj.setAttribute("CreatedDate", today);
		planObj.setAttribute("EffectiveDate", today);
		planObj.setAttribute("Creator", String.valueOf(u.getObjectId()));
		planObj.setAttribute("Version", INIT_VERSION_STR);
		PepCommentVector commentVector = new PepCommentVector();
		commentVector.addComment(df1.format(today), u.getObjectName(), "Initial plan 1.0");
		try {
			planObj.setAttribute("Description",
					commentVector.getBytes().toString().getBytes("UTF-8"));
		} catch (UnsupportedEncodingException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		planMgr.commit(planObj);
		return planObj;
	}
	
	// called by proj_new3.jsp and new_templ2.jsp
	public static String lookUpDependency(String planString, String headerNum)
	{
		// format: @Dep 1.3: 1.1, 1.2   (that means 1.3 depends on 1.1 and 1.2)
		String target = "@Dep " + headerNum + ":";
		int idx1 = planString.indexOf(target);
		if (idx1 == -1)
			return "";

		idx1 += target.length();	// skip the header and colon
		int idx2 = planString.indexOf('\n', idx1);
		if (idx2 == -1)
			idx2 = planString.length();		// EOF
		String depStr = planString.substring(idx1, idx2);
		return depStr.trim();
	}

	private static final String PH_SUBFIX = "@Phase [0-9]+:";
	private static final String SUBPH_SUBFIX = "@Subphase [0-9]+\\.[0-9]+:";
	public static String lookUpPhase(String planString, String headerNum, String [] colorS)
	{
		// the target string is "@Phase 1:4:#336699" or "@Subphase 1.1:4.2:#336699"
		String retStr = "";
		Pattern p1 = Pattern.compile(PH_SUBFIX + headerNum + ":");
		Matcher matcher = p1.matcher(planString);
		int idx1, idx2=0;
		if (matcher.find()) {
			// found phase
			idx1 = matcher.start() + 1;					// skip @ in front of @Phase
			idx2 = planString.indexOf(':', idx1);
			retStr = planString.substring(idx1, idx2);	// extract "Phase 1"
		}
		else {
			// try subPhase
			p1 = Pattern.compile(SUBPH_SUBFIX + headerNum + ":");
			matcher = p1.matcher(planString);
			if (matcher.find()) {
				// found subphase
				idx1 = matcher.start() + 1;					// skip @ in front of @Subphase
				idx2 = planString.indexOf(':', idx1);
				retStr = planString.substring(idx1, idx2);	// extrace "Subphase 1"
			}
		}

		if (retStr!="" && colorS!=null) {
			// try to extract color
			idx1 = planString.indexOf(':', idx2+1);			// skip to the second ":"
			idx2 = planString.indexOf('\n', idx1);
			String s = planString.substring(idx1+1, idx2);	// #336699
			if (StringUtil.isNullOrEmptyString(s)) s = null;
			colorS[0] = s;
		}
		else if (colorS != null) colorS[0] = null;			// make sure to nullify

		return retStr;
	}

	////////////////////////////////////////////////////////////////////////////////////////////
	// Path

	public static class Path
	{
		private int _totalDays;			// in days
		private int _shortestDays;
		private LinkedList<task> _path;	// list of tasks

		public int max() {return _totalDays;}
		public int min() {return _shortestDays;}
		public LinkedList<task> getPath() {return _path;}
		public int size() {return _path.size();}

		public Path ()
		{
			_path = new LinkedList<task> ();
			_shortestDays = 0;
			_totalDays = 0;
		}

		// always add the task to the front
		public void addFirst(task tk)
			throws PmpException
		{
			_path.addFirst(tk);

			// we do not concern about gap because as long as the task
			// is floating, we can always move it up to shorten the
			// project timeline.
			int dur = tk.getDuration();
			
			// note: duration may not be reliable as it might not be set
			// also for task with actual start and finish, the planned duration is not what we want
			if (dur<=0 || tk.getCompleteDate()!=null) {
				// get an accurate task length
				Date begDt = tk.getEffectiveDate();
				if (begDt == null) begDt = tk.getStartDate();
				if (begDt == null) dur = 0;
				else {
					Date endDt = tk.getCompleteDate();
					if (endDt == null) endDt = tk.getExpireDate();
					if (endDt == null) dur = 0;
					else {
						dur = task.getDaysDiff(endDt, begDt);
					}
				}
			}

			// _totalDays
			_totalDays += dur + tk.getGap();

			// _shortestDays
			_shortestDays += dur;
		}

		public String toString() {return toString(null);}
		public String toString(HashMap<String,String> taskMap)
		{
			StringBuffer sBuf = new StringBuffer(1024);
			int tid;
			String name, durStr;
			for (task tk: _path) {
				if (sBuf.length() > 0) {
					sBuf.append(" -> ");
				}
				try {
					tid = tk.getObjectId();
					durStr = tk.getDuration() + " days";

					if (taskMap == null) {
						sBuf.append("[" + tid + "] (" + durStr + ")");
					}
					else {
						name = taskMap.get(String.valueOf(tid));
						if (name == null) {
							l.warn("project.toString() got NULL name with taskID [" + tid + "]");
							continue;		// shouldn't happen
						}
						name = name.substring(0, name.indexOf(' '));
						sBuf.append("[" + name + "] (" + durStr + ")");
					}
				}
				catch (PmpException e) {sBuf.append("[exception]");}
			}
			sBuf.append(" (total = " + min() + "-" + max() + " days)");
			return sBuf.toString();
		}
	}	//END: class Path

}//End class project
