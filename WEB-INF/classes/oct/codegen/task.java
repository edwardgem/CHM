
//
//  Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//	Licensee of FastPath (tm) is authorized to change, distribute
//	and resell this source file and the compiled object file,
//	provided the copyright statement and this statement is included
//	as header.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   task.java
//  Author: FastPath CodeGen Engine
//  Date:   03.18.2003
//  Description:
//		Implementation of task class
//  Modification:
//		@03.18.2003aFCE File created by FastPath
//		@ECC112405	Added Duration and Gap to task.
//		@AGQ050306	Ignored the special date
//
/////////////////////////////////////////////////////////////////////
//
// task.java : implementation of the task class
//

package oct.codegen;
import java.text.ParseException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
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
import oct.pst.PstFlowConstant;
import oct.pst.PstFlowStep;
import oct.pst.PstFlowStepManager;
import oct.pst.PstTimeAbstractObject;
import oct.pst.PstUserAbstractObject;

import org.apache.log4j.Logger;

import util.Prm;
import util.PrmLog;
import util.StringUtil;
import util.TaskInfo;
import util.Util;
import util.Util2;

/**
*
* <b>General Description:</b>  task extends PmpAbstractObject.  This class
* encapsulates the data of a member from the "task" organization.
*
* The task class provides a facility to modify data of an existing task object.
*
*
*
* <b>Class Dependencies:</b>
*   oct.custom.taskManager
*   oct.pmp.PmpUser
*   oct.pmp.PmpUserManager
*
*
* <b>Miscellaneous:</b> There are methods that will be deprecated in future versions.
*
*/


public class task extends PstTimeAbstractObject
{
	static final long serialVersionUID = 1L;

    //Private attributes
    private final static long DayInMsec = 86400000;

	public final static String CHANGE = "Change";
	public final static String DEPRECATED = "Deprecated";
	public final static String NEW = "New";
	public final static String ORIGINAL = "Original";

	// task lifecycle state (status)
	public final static String ST_NEW		= "New";
	public final static String ST_OPEN		= "Open";
	public final static String ST_ONHOLD	= "On-hold";
	public final static String ST_LATE		= "Late";
	public final static String ST_COMPLETE	= "Completed";
	public final static String ST_CANCEL	= "Canceled";
	public static final String [] STATE_ARRAY	= {ST_NEW, ST_OPEN, ST_ONHOLD, ST_LATE, ST_COMPLETE, ST_CANCEL};

	public final static char C = CHANGE.charAt(0);
	public final static char D = DEPRECATED.charAt(0);
	public final static char N = NEW.charAt(0);
	public final static char O = ORIGINAL.charAt(0);

	public final static int READ		= 1;
	public final static int WRITE		= 2;
	
	public static final String ATTR_OPTION			= "Option";
	public static final String TASK_BLOG_ID			= "TASK_BLOG_ID";

	private final static String APP = Util.getPropKey("pst", "APPLICATION");
	private final static String FROM = Util.getPropKey("pst", "FROM");
	private final static String EMAIL_SUBJ = "[" + APP + "] Project Alert";
	private final static String MAILFILE = "alert.htm";

	java.text.SimpleDateFormat df = new java.text.SimpleDateFormat("MM/dd/yyyy");

	static boolean bDEBUG = false;

	static Logger l = PrmLog.getLog();
	private HashMap<String, String> _dirtyMap = null;

    static taskManager manager;
	static projectManager pjMgr;
	static planManager pnMgr;
	static planTaskManager ptMgr;
	static PstFlowStepManager fsMgr;
	static phaseManager phMgr;

	static {
		try {
			manager = taskManager.getInstance();
			pjMgr = projectManager.getInstance();
			pnMgr = planManager.getInstance();
			ptMgr = planTaskManager.getInstance();
			fsMgr = PstFlowStepManager.getInstance();
			phMgr = phaseManager.getInstance();
		}
		catch (PmpException e) {
			l.error("task.java failed to initialize manager instances.");
		}
	}


    /**
     * Constructor for instantiating a new task.
     * @param member An OmsMember representing a task.
     */
    public task(OmsMember member)
    {
        super(member);
    }


    /**
     * Constructor for instantiating a new task.
     * @param user A PmpUesr.
     * @param org An organization.
     * @param memberName The name of the member.
     * @param password The password of the member.
     */
	task(PstUserAbstractObject user, OmsOrganization org, String memberName, String password)
		throws PmpException
	{
		super(user, org, memberName, password);
	}


    /**
     * Constructor for creating a task.  Used by taskManager.
     * @param user A PmpUser.
     * @param org The OmsOrganization for the task.
     */
    task(PstUserAbstractObject user, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
		super(user, org, "");
    }

    /**
     * Constructor for creating a task.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the task.
     */
    task(OmsSession session, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, "");
    }

    /**
     * Constructor for creating a task using a member name.
     * @param user A PmpUser.
     * @param org The OmsOrganization for the task.
     * @param taskMemName The member name for the created task.
     */
    task(PstUserAbstractObject user, OmsOrganization org, String taskMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(user, org, taskMemName, null);
    }

    /**
     * Constructor for creating a task using a member name.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the task.
     * @param companyMemberName The member name for the created task.
     */
    task(OmsSession session, OmsOrganization org, String taskMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, taskMemName, null);
    }

    /**
     */
    public void setDirtyMap(HashMap<String, String> hash) {_dirtyMap = hash;}
    public HashMap<String, String> getDirtyMap() {return _dirtyMap;}
    
    /**
     * Currently Not Implemented.
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
    	if (_dirtyMap != null) _dirtyMap.put(this.getObjectName(), "1");	// mark dirty
        super.save();
    }//End save

    protected boolean refresh()
    {
        return super.refresh();
    }//End refresh

    // addDependency()
    public static final int ERR_DEP_CYCLE		= -1;
    public static final int ERR_DEP_ON_CHILD	= -2;
    public static final int ERR_DEP_ON_PARENT	= -3;
	/**
	   addDependency add a dependency from the task represented by the pass-in tidS
	   to this task object.  It checks for erroneous condition that child cannot
	   depend on parent; parent cannot depend on child; and there cannot be a
	   cycle.  It will record the dependency attribute on the tid task and also
	   re-evaluate the planned date to ensure the new dependency is uphold.

	   This method would not change my dates.  It only changes dates of the task
	   (tidS) that depends on me.

	   @param u
	   @param tidS the taskID of the task that depends on this task
	 */
    public int addDependency(PstUserAbstractObject u, String tidS)
        throws PmpException
    {
		// tidS (task) depends on me
		if (bDEBUG) debugPrt("================");

		// check to see if T is my ancestor
		if (isMyAncestor(u, tidS))
			return ERR_DEP_ON_CHILD;			// can't build a dependency on a child

		// check to see if T is my descendant
		if (isMyDecendent(u, tidS))
			return ERR_DEP_ON_PARENT;				// can't build a dependency on my ancestor

		// check for cycles
		task tk = (task)manager.get(u, tidS);
		if (this.dependOn(u, tk.getObjectId(), 0, true))
			return ERR_DEP_CYCLE;

		// recalculate T's StartDate and ExpireDate
		// gap and duration should not change
		task depTk = tk.getLDT(u);
		if (depTk==null || depTk.getObjectId()==this.getObjectId()) {
			// need to recalculate T's dates
			tk.setDatesByDependentObj(u, this, false);	// might extend project schedule
		}


		// save the Dependency
		tk.appendAttribute("Dependency", String.valueOf(this.getObjectId()));
		tk.setAttribute("LastUpdatedDate", new Date());
		manager.commit(tk);

		return 0;
	}

	public boolean isMyAncestor(PstUserAbstractObject u, String tidS)
		 throws PmpException
	{
		planTask pt;
		String s;
		String parentTidS;						// parent's task id
		int myPtId = getPlanTaskId(u);
		pt = (planTask)ptMgr.get(u, myPtId);	// the last planTask is current
		while (true)
		{
			s = (String)pt.getAttribute("ParentID")[0];
			if (s==null || s.equals("0"))
				break;							// no parent
			pt = (planTask)ptMgr.get(u, s);		// this is my parent planTask
			parentTidS = (String)pt.getAttribute("TaskID")[0];
			if (parentTidS.equals(tidS))
				return true;
		}
		return false;
	}

	public boolean isMyDecendent(PstUserAbstractObject u, String tidS)
		 throws PmpException
	{
		task tk = (task)manager.get(u, tidS);
		int ptId = tk.getPlanTaskId(u);
		return isChild(u, getPlanTaskId(u), ptId);
	}

	// check to see if checkId (a plantask id) is my child
	protected boolean isChild(PstUserAbstractObject u, int myPtId, int checkId)
        throws PmpException
	{
		// first get my planTask and use that planTask id to find my children
		if (myPtId == checkId)
			return true;			// checkId is my a child

		// check thru my children
		int [] ids = ptMgr.findId(u, "ParentID='" +myPtId+ "' && Status!='Deprecated'");
		for (int i=0; i<ids.length; i++)
		{
			if (isChild(u, ids[i], checkId))		// my child's child
				return true;
		}
		return false;
	}

	protected boolean dependOn(PstUserAbstractObject u, int tid, int callerId, boolean checkParent)
        throws PmpException
	{
		// check to see if the task depends tid
		if (bDEBUG) debugPrt("-- checking " + getObjectId() + " --> " + tid);
		task tk;
		Object [] id = getAttribute("Dependency");

		// look thru my dependency and check recursively
		for (int i=0; i<id.length; i++)
		{
			if (id[i] == null) break;
			if (bDEBUG) debugPrt("  dependent " + (String)id[i]);
			if (tid == Integer.parseInt((String)id[i]))
				return true;

			// recursively check the dependent
			tk = (task)manager.get(u, (String)id[i]);
			if (tk.dependOn(u, tid, 0, checkParent))	// check parent
				return true;
		}

		// look through my ancestors and check recursively
		int myPtId = getPlanTaskId(u);
		planTask pt = (planTask)ptMgr.get(u, myPtId);	// my planTask

		// if they have the same parent, no need to check
		int depPtId = getPlanTaskId(u, String.valueOf(tid));
		planTask depPt = (planTask)ptMgr.get(u, depPtId);	// the last planTask is current
		if (!((String)pt.getAttribute("ParentID")[0]).equals((String)depPt.getAttribute("ParentID")[0])
			&& checkParent)
		{
			String s = (String)pt.getAttribute("ParentID")[0];
			if (s!=null && !s.equals("0"))
			{
				pt = (planTask)ptMgr.get(u, s);			// this is my parent planTask
				if (pt.getObjectId() != callerId)
				{
					tk = (task)manager.get(u, (String)pt.getAttribute("TaskID")[0]);
					if (bDEBUG) debugPrt("   " + getObjectId() + ": check parent " + tk.getObjectId());
					if (tk.dependOn(u, tid, myPtId, checkParent))
						return true;
				}
			}
		}


		// look thru my children and check recursively
		// IMPORTANT: don't check parent of child or else would be infinite loop.  Parent is taken
		// care of right above already.
		int ptId = myPtId;
		int [] ids = ptMgr.findId(u, "ParentID='" +myPtId+ "' && Status!='Deprecated'");
		for (int i=0; i<ids.length; i++)
		{
			pt = (planTask)ptMgr.get(u, ids[i]);	// this is my child planTask
			if (pt.getObjectId() == callerId)
				continue;
			tk = (task)manager.get(u, (String)pt.getAttribute("TaskID")[0]);
			if (tk.getObjectId() == tid) continue;			// I can't have dependency on myself
			if (bDEBUG) debugPrt("   " + getObjectId() + ": check child " + tk.getObjectId());
			if (tk.dependOn(u, tid, ptId, false))	// no parent check
				return true;
			ptId = pt.getObjectId();
		}
		if (bDEBUG) debugPrt("-- done with "+getObjectId());
		return false;
	}

/*	@ECC112405 no need for this anymore
	protected void moveTask(PstUserAbstractObject u, long msec)
        throws PmpException
	{
		// when I move, all my dependents and children must also move
		Date dt;
		task t;

		// move my dependents
		int [] tIdList = manager.findId(u, "Dependency='" + getObjectId() + "'");
		for (int i=0; i<tIdList.length; i++)
		{
			t = (task)manager.get(u, tIdList[i]);
			t.moveTask(u, msec);
		}

		// find and move my children
		planTask pt;
		String s;
		int [] ids = ptMgr.findId(u, "TaskID='" +getObjectId()+ "' && Status!='Deprecated'");
		if (ids.length > 0)
		{
			Arrays.sort(ids);
			pt = (planTask)ptMgr.get(u, ids[ids.length-1]);	// the lastest planTask is current
			ids = ptMgr.findId(u, "ParentID='" + pt.getObjectId() + "' && Status!='Deprecated'");
			for (int i=0; i<ids.length; i++)
			{
				pt = (planTask)ptMgr.get(u, ids[i]);
				t = (task)manager.get(u, (String)pt.getAttribute("TaskID")[0]);
				t.moveTask(u, msec);
			}
		}

		// move this task
		String st = (String)getAttribute("Status")[0];
		java.text.SimpleDateFormat df = new java.text.SimpleDateFormat("MM/dd/yyyy");
		Date today = new Date(df.format(new Date()));

		// if the new start is after today and current Status is Open/Late, set Status to New
		dt = new Date(((Date)getAttribute("CreatedDate")[0]).getTime() + msec);
		setAttribute("CreatedDate", dt);
		if ((st.equals(ST_OPEN) || st.equals(ST_LATE)) && dt.after(today))
			setAttribute("Status", ST_NEW);

		// if ExpireDate is after today and current Status is Late, change to Open
		dt = new Date(((Date)getAttribute("ExpireDate")[0]).getTime() + msec);
		setAttribute("ExpireDate", dt);
		if (st.equals(ST_LATE) && dt.after(today))
			setAttribute("Status", ST_OPEN);

		setAttribute("LastUpdatedDate", new Date());
		manager.commit(this);

		// whenever I move my ExpireDate, I need to check my parent to see if that needs to be moved
		Date expire;
		ids = ptMgr.findId(u, "TaskID='" +getObjectId()+ "' && Status!='Deprecated'");
		Arrays.sort(ids);
		pt = (planTask)ptMgr.get(u, ids[ids.length-1]);	// the last planTask is current
		while (true)
		{
			s = (String)pt.getAttribute("ParentID")[0];
			if (s==null || s.equals("0"))
			{
				// do it for project
				projectManager pjMgr = projectManager.getInstance();
				project pj = (project)pjMgr.get(u,
					Integer.parseInt((String)getAttribute("ProjectID")[0]));
				expire = (Date)pj.getAttribute("ExpireDate")[0];
				if (expire.before(dt))
				{
					pj.setAttribute("ExpireDate", dt);	// set to the new expire date
					st = (String)pj.getAttribute("Status")[0];
					if (st.equals(ST_LATE) && dt.after(today))
						pj.setAttribute("Status", ST_OPEN);

					pj.setAttribute("LastUpdatedDate", new Date());
					pjMgr.commit(pj);
				}
				break;								// no more parent
			}
			pt = (planTask)ptMgr.get(u, s);			// this is my parent planTask
			task parentTask = (task)manager.get(u, (String)pt.getAttribute("TaskID")[0]);
			expire = (Date)parentTask.getAttribute("ExpireDate")[0];
			if (expire.before(dt))
			{
				parentTask.setAttribute("ExpireDate", dt);	// set to the new expire date
				st = (String)parentTask.getAttribute("Status")[0];
				if (st.equals(ST_LATE) && dt.after(today))
					parentTask.setAttribute("Status", ST_OPEN);

				parentTask.setAttribute("LastUpdatedDate", new Date());
				manager.commit(parentTask);
			}
		}
	}
*/

	public boolean isAuthorizedUser(PstUserAbstractObject u, int opType)
        throws PmpException
	{
		int myUid = u.getObjectId();
		
		// ECC: do preventive care
		// in reality, Owner should not be null, somewhere must be wrong
		String ownerIdS = (String)getAttribute("Owner")[0];
		if (StringUtil.isNullOrEmptyString(ownerIdS)) {
			l.error("task [" + getObjectId() + "] has null owner");
			ownerIdS = getStringAttribute("Creator");
			if (StringUtil.isNullOrEmptyString(ownerIdS)) {
				throw new PmpException("Owner and Creator are null in task [" + getObjectId() + "]");
			}
			this.setAttribute("Owner", ownerIdS);
		}
			
		if (opType == WRITE)
		{
			// allow project owner, task owner, or task ancestor owner to update

			// 1. task owner
			int ownerId   = Integer.parseInt(ownerIdS);
			if (myUid == ownerId)
				return true;

			// 2. project owner
			project pj = getProject(u);
			ownerId = Integer.parseInt((String)pj.getAttribute("Owner")[0]);
			if (myUid == ownerId)
				return true;

			// 3. go up to the project tree, owner of any tasks are authorized
			// get planTask of this task
			int ptId = getPlanTaskId(u);
			planTask pt = (planTask)ptMgr.get(u, ptId);
			while (true)
			{
				int parentId = Integer.parseInt((String)pt.getAttribute("ParentID")[0]);
				if (parentId == 0)
					return false;		// tk is a top task, no parent status
				pt = (planTask)ptMgr.get(u, parentId);
				task tk = (task)manager.get(u, (String)pt.getAttribute("TaskID")[0]);
				ownerId = Integer.parseInt((String)tk.getAttribute("Owner")[0]);
				if (myUid == ownerId)
					return true;
			}
		}
		return false;
	}

	//
	// setPlanDates()
	// Top method: call setDatesByDependentObj() to set the StartDate and ExpireDate of a task
	// gap and duration should not be changed.  The caller needs to commit this task.
	public boolean setPlanDates(PstUserAbstractObject u)
        throws PmpException
	{
		// use Duration and Gap to set the StartDate and ExpireDate.  If Dur=0, don't do anything.
		if (bDEBUG) debugPrt("Calling setPlanDates() on task [" + getObjectId() + "]");
		boolean rc = false;

		Date oldStart  = getStartDate();
		Date oldExpire = getExpireDate();
		int dur = getDuration();

		if (dur <= 0) {
			if (oldStart==null || oldExpire==null || phase.isSpecialDate(oldExpire))
				return false;	// nothing I can do
		}

		Date myDependentStartDt = null;
		int gap=0;
		project pj = null;

		// first try to use LDT to calculate StartDate
		task ldt = getLDT(u);

		if (ldt != null)
		{
			if (bDEBUG) debugPrt("setPlanDates() use LDT task [" + ldt.getObjectId() + "]");
			if (_dirtyMap!=null) ldt.setDirtyMap(_dirtyMap);
			rc = setDatesByDependentObj(u, ldt, true);		// I depend on LDT
			myDependentStartDt = ldt.getStartDate();
		}

		// no ldt, use parent or project to set dates
		else
		{
			System.out.println("-- No LDT, use parent as LDT");
			ldt = getParentTask(u);

			Date pStart = null;
			pj = getProject(u);
			if (ldt != null
					&& ((pStart=ldt.getStartDate()) != null) )
			{
				// use parent to set the dates
				if (bDEBUG) debugPrt("setPlanDates() use parent task [" + ldt.getObjectId() + "]");
				if (_dirtyMap!=null) ldt.setDirtyMap(_dirtyMap);
				gap = getGap();
				Date dateFromParent = new Date(pStart.getTime() + ((long)gap)*DayInMsec);
				if (oldStart == null) {
					pStart = dateFromParent;
					setAttribute("StartDate", pStart);
				}
				else if (pStart.after(oldStart)) {
					// try to extend the parent StartDate
					if (bDEBUG) debugPrt("<<< setPlanDates() begin optimizedStartDate()");
					pStart = extendParentStartDate(u, oldStart);
					if (bDEBUG) debugPrt("<<< setPlanDates() end optimizedStartDate() with return date: " + pStart);
						
					// I have done my best already, now adjust the gap if necessary to follow rules
					if (pStart.compareTo(oldStart) != 0) {
						gap = getDaysDiff(pStart, oldStart);
						setAttribute("Gap", gap);
						if (bDEBUG) debugPrt("   bounded by parent StartDate, introduce a gap (" + gap + ") to solve the conflict.");
						setAttribute("StartDate", pStart);
					}					
				}


				if (dur>0 || oldExpire.before(pStart)) {
					setAttribute("ExpireDate", new Date(getStartDate().getTime() + ((long)dur)*DayInMsec));
					// ECC: it was using pStart, I changed it to getStartDate()
				}


				myDependentStartDt = ldt.getStartDate();
			}
			else
			{
				// use project to set the dates
				System.out.println("--         use project as LDT");
				if (bDEBUG) debugPrt("setPlanDates() use project");
				rc = setDatesByDependentObj(u, pj, true);
				myDependentStartDt = pj.getStartDate();
			}
		}
		save();
		
		// check to see if I am a parent and extend (or shrink) my ExpireDate based on children
		extendShrinkExpireDateByChildren(u);

		// may have to extend parent's expire date (recursive)
		extendShrinkParentExpireDateIfNeeded(u);

		if (myDependentStartDt != null) {
			if (pj == null)
				pj = getProject(u);
			extendPjExpireDateIfNeeded(pj);
		}

		// ECC: why do this? This might have an issue of changing what user specified
		// recalculate Gap and Duration
		/*
		if (myDependentStartDt != null)
		{
			gap = (int)((((Date)getAttribute("StartDate")[0]).getTime() - myDependentStartDt.getTime())/DayInMsec);
			dur = (int)((((Date)getAttribute("ExpireDate")[0]).getTime() - ((Date)getAttribute("StartDate")[0]).getTime())/DayInMsec);
			setAttribute("Gap", new Integer(gap));
			setAttribute("Duration", new Integer(dur));
		}
		*/

		// check to see if my dates impact my children
		setSaveMyDependentsDates(u);

		if (bDEBUG) {
			debugPrt("  StartDate  = " + getStartDate());
			debugPrt("  ExpireDate = " + getExpireDate());
			debugPrt("  Gap = " + gap + "; duration = " + dur + "\n");
			debugPrt("Done calling setPlanDates()\n------------\n\n");
		}

		return rc;
	}

	private void extendShrinkParentExpireDateIfNeeded(PstUserAbstractObject u)
		throws PmpException
	{
		if (bDEBUG) debugPrt(">>> calling extendParentExpireDateIfNeeded() [" + getObjectId() + "]");
		task parent = getParentTask(u);
		if (parent == null) return;
		parent.extendShrinkExpireDateByChildren(u);
		if (bDEBUG) debugPrt("<<< Done calling extendParentExpireDateIfNeeded() [" + getObjectId() + "]");
	}
	
	private void extendShrinkExpireDateByChildren(PstUserAbstractObject u)
		throws PmpException
	{
		if (bDEBUG) debugPrt(">>> calling extendShrinkExpireDateByChildren() [" + getObjectId() + "]");
		
		if (_dirtyMap!=null) setDirtyMap(_dirtyMap);
		
		Date latestChildExpireDate = getChildrenLatestExpireDate(u);
		if (latestChildExpireDate == null) return;
		
		boolean hasChanged = false;
		Date parentExpireDate = getExpireDate();
		
		if (bDEBUG) debugPrt("   ExpireDate = " + parentExpireDate);

		// ECC: if parent's ExpireDate is null, there might be a problem with the schedule
		// I am only not sure if we should allow container to be a parent of a schedule
		// my gut feeling is we should not.  We should block that from happening.
		// Here we perform a fix on the parent to update its ExpireDate.
		// But its StartDate may also be null.
		if ( parentExpireDate==null || latestChildExpireDate.after(parentExpireDate) )
		{
			if (parentExpireDate == null) {
				System.out.println("*** extendShrinkExpireDateByChildren(): fix task ["
						+ getObjectId() + "] has null ExpireDate.");
			}
			setAttribute("ExpireDate", latestChildExpireDate);
			
			// fix parent's null StartDate
			if (getStartDate() == null) {
				setAttribute("StartDate", getChildrenEarlestStartDate(u));
				System.out.println("*** extendShrinkExpireDateByChildren(): fix task ["
						+ getObjectId() + "] has null StartDate.");
			}
			hasChanged = true;
			
			if (bDEBUG) debugPrt("   extend ExpireDate by children to " + latestChildExpireDate + "\n");
		}
		else if (latestChildExpireDate.before(parentExpireDate)) {
			// parentExpireDate is after child latest expire date, optimize (shrink)
			setAttribute("ExpireDate", latestChildExpireDate);
			hasChanged = true;
			
			if (bDEBUG) debugPrt("   optimze ExpireDate by children to " + latestChildExpireDate + "\n");
		}

		// recursive up ancestor tree
		if (hasChanged) {
			setDuration();
			save();
			setSaveMyDependentsDates(u);		// my expire date has changed, it will impact my dependents
			extendShrinkParentExpireDateIfNeeded(u);
		}
		if (bDEBUG) debugPrt("<<< Done calling extendShrinkExpireDateByChildren() [" + getObjectId() + "]");
		return;
	}


	//
	// setDuration()
	// set the Duration based on StartDate and ExpireDate
	// Duration is a plan, not actual
	public int setDuration()
        throws PmpException
	{
		Date startD  = getStartDate();
		Date expireD = getExpireDate();
		if (startD==null || expireD==null || phase.isSpecialDate(expireD))
			return 0;

		int dur = getDaysDiff(expireD, startD);
		if (dur < 0) dur = 0;
		setAttribute("Duration", new Integer((int)dur));
		return dur;

/*		long diff = expireD.getTime() - startD.getTime();
		if (diff <=0) return 0;

		diff = (long)Math.ceil(diff/DayInMsec);
		setAttribute("Duration", new Integer((int)diff));

		return ((int)diff);	// return days
*/
	}

	/**
		getLDT()
		@return the Last Dependent Task (LDT), which is the task I depend on that
		has the latest ExpireDate.
	 */
	private task getLDT(PstUserAbstractObject u)
        throws PmpException
	{
		// get the last dependent task.  If none, return null
		PstAbstractObject obj;
		Date latestD = new Date(0);
		Date dt;
		task ldt = null;

		Object [] depArr = getAttribute("Dependency");
		for (int i=0; i<depArr.length; i++)
		{
			String tidS = (String)depArr[i];
			if (tidS == null) break;

			obj = manager.get(u, tidS);
			dt = (Date)obj.getAttribute("CompleteDate")[0];
			if (dt == null) dt = (Date)obj.getAttribute("ExpireDate")[0];
			if (dt == null) continue;
			else if (dt.after(latestD))
			{
				latestD = dt;
				ldt = (task)obj;
			}
		}
		return ldt;	// return null if no LDT
	}

	/**
		setDatesByDependentObj()
		caller should first call getLDT() to make sure getting the right depObj.
		I depend on depObj (either a task or a project), call this to set my dates based
		on depObj.
		If Duration==0, do not do anything.
		If Gap==0 and is depending on project, then use current StartDate unless it is null
		If my ExpireDate is changed here, check if we need to recalculate others' StartDate.
		@param current user
		@param the task I depend on
		@param true to force evaluating my dependents' dates
		@return true if made changes on my dates.
	 */
	private boolean setDatesByDependentObj(PstUserAbstractObject u,
										   PstAbstractObject depObj,
										   boolean bHasChanged)
        throws PmpException
	{
		if (getObjectId() == depObj.getObjectId()) {
			// error checking: cannot depend on self
			return false;
		}
		int dur = ((Integer)getAttribute("Duration")[0]).intValue();
		int gap = ((Integer)getAttribute("Gap")[0]).intValue();
		if (bDEBUG) debugPrt("Enter setDatesByDependentObj(" + getObjectId()
				+ ") with gap = " + gap + ", dur = " + dur
				+ "; depend on [" + depObj.getObjectId() + "]");

		// if ldt has completed, use the CompleteDate to calculate my StartDate
		Date dt = null;
		Date oldStart  = getStartDate();
		Date oldExpire = getExpireDate();
		boolean rc;

		if (depObj instanceof task)
		{
			// depend on a task: use CompleteDate or ExpireDate to calculate StartDate
			dt = (Date)depObj.getAttribute("CompleteDate")[0];
			if (dt == null || phase.isSpecialDate(dt))
				dt = (Date)depObj.getAttribute("ExpireDate")[0];
		}
		else
		{
			// for depending on project, use project StartDate to calculate my StartDate.
			// But if gap<0, then see if my own StartDate is set, if so, leave it.
			if (gap<0 && oldStart!=null)
				dt = oldStart;
			else
				dt = (Date)depObj.getAttribute("StartDate")[0];
		}
		if (bDEBUG) debugPrt("   depObj date is " + dt);

		if (dt == null)
		{
			// depObj has null ExpireDate: nullify my plan dates
			setAttribute("StartDate", null);
			setAttribute("ExpireDate", null);
			rc = (oldStart!=null || oldExpire!=null);
			return rc;
		}

		if (phase.isSpecialDate(dt)) // may not be used
			return false;

		project pj = getProject(u);

		/////////////////////////
		// set my StartDate
		// Rule 1: I cannot move my StartDate to before my parent in the project tree
		//		   relax this rule such that I will recursively move my ancestor unless
		//		   it is blocked by a dependency on my ancestor - an optimized way.
		// Rule 1A: Handle task that is completed but without an effective date.
		// Rule 2: My children must not end after me (extend my expire date accordingly)
		// Rule 3: My children must not start before me (move my children accordingly)
		// Rule 4: My parent must not end before me (extend parent accordingly)

		// save (dt+gap) in newStart
		Date newStart, newExpire;
		Calendar cal = Calendar.getInstance();
		cal.setTime(dt);				// dt is the date of the obj I am dependent on
		cal.add(Calendar.DATE, gap);
		newStart = cal.getTime();		// newStart is the gap + depObj expireDate
		if (bDEBUG) debugPrt("   newStart to be used: " + newStart);
		if (gap<=0 && dur<=0 && oldStart!=null && (newStart==null || oldStart.after(newStart)) ) {
			// ECC: *** we can't respect gap and dur when they are both 0.
			// Because we need some way to know when to respect the planned dates
			// and it is when gap = dur = 0.
			// don't change the StartDate if gap==dur==0 and StartDate has a gap
			newStart = oldStart;
			if (bDEBUG) debugPrt("   since gap=dur=0, set newStart to oldStart: " + newStart);
		}

		// now make sure the newStart date does not violate the rules with parent/child
		// if it does, we need to add a gap to the task to solve the conflict
		// basically user need to ensure the parent has enough room.

		/////////////////////////
		// enforce Rule 1
		// my StartDate must be after my parent's StartDate
		dt = getParentTaskStartDate(u);		// Rule 1: only consider parent task
		if (bDEBUG) debugPrt("   getParentTaskStartDate() is " + dt);
		if (dt == null) {
			// use project start date
			dt = pj.getStartDate();
System.out.println("***** parent StartDate is null: just use project StartDate = " +dt);
		}
		if (dt!=null && dt.after(newStart)) {
			// optimize schedule as much as possible: go up the ancestor's tree to expand
			// my parent's Start Date to accommodate the newStart date unless I am blocked
			// by a parent's dependency, in which case I do my best and extend the schedule
			// as much as possible and then adjust my gap to take care of the basic rules.
			if (bDEBUG) debugPrt("   >>> start optimizedStartDate() attempt to extend parent StartDate");
			Date optimizedStartDate = extendParentStartDate(u, newStart);
			if (bDEBUG) debugPrt("   <<< end optimizedStartDate() with return date: " + optimizedStartDate);
				
			// I have done by best already, now adjust the gap if necessary to follow rules
			if (optimizedStartDate.compareTo(newStart) != 0) {
				gap = getDaysDiff(optimizedStartDate, newStart);
				setAttribute("Gap", gap);
				newStart = optimizedStartDate;
				if (bDEBUG) debugPrt("   bounded by parent StartDate, introduce a gap (" + gap + ") to solve the conflict.");
			}
		}
		if (bDEBUG) debugPrt("   rule 1 [" + getObjectId() + "]: set StartDate to " + newStart);
		setAttribute("StartDate", newStart);
		rc = (oldStart==null || oldStart.compareTo(newStart)!=0);		// changed

		if (phase.isSpecialDate(newStart)) // may not be used
			return false;
		
		/////////////////////////
		// Rule 1A
		// if I have an CompleteDate but w/o an ActualStart Date,
		// and if my parent has an CompleteDate, fill my ActualStart Date
		// because otherwise it would be confusing when retrieving StartDate
		if (getCompleteDate()!=null && getEffectiveDate()==null) {
			Date depCompleteDt = (Date)depObj.getAttribute("CompleteDate")[0];
			if (depCompleteDt != null) {
				// need to fill my EffectiveDate
				if (!getCompleteDate().before(depCompleteDt)) {
					// as long as my CompleteDate is after this new EffectiveDate, set it
					setAttribute("EffectiveDate", depCompleteDt);
				}
			}
		}

		/////////////////////////
		// set my ExpireDate
		if (dur > 0) {
			cal.setTime(newStart);		// this is my StartDate
			cal.add(Calendar.DATE, dur);
			newExpire = cal.getTime();
		}
		else {
			if (oldExpire.before(newStart))
				newExpire = newStart;		// expire the same day as start
			else
				newExpire = oldExpire;		// keep the old expire date
		}

		/////////////////////////
		// enforce Rule 2
		Date oldestChildExpDt = getChildrenLatestExpireDate(u, getPlanTaskId(u));
		if (oldestChildExpDt!=null && newExpire.before(oldestChildExpDt)) {
			newExpire = oldestChildExpDt;
		}

		if (bDEBUG) debugPrt("   rule 2 [" + getObjectId() + "]: set ExpireDate to " + newExpire);
		setAttribute("ExpireDate", newExpire);
		rc = (rc || (oldExpire==null || oldExpire.compareTo(newExpire)!=0) );

		// *** By now, StartDate and ExpireDate has been set according to Dependency object
		setDuration();	// re-cal duration using new StartDate and ExpireDate

		/////////////////////////
		// enforce Rule 3
		// recursive ensure my children start after me. Extend schedule if necessary.
		if (oldStart==null || newStart.after(oldStart)) {
			dt = moveChildrenForward(u);
			// ECC: ? should I check dt to make sure I (as parent) don't need to move
			// my ExpireDate forward?
			rc = (rc || (oldExpire!=null && dt!=null && oldExpire.compareTo(dt)!=0) );
		}

		/////////////////////////
		// enforce Rule 4
		// extend parent if necessary
		if (oldExpire!=null && dt!=null) {
			if (!phase.isSpecialDate(dt) && dt.after(oldExpire)) {
				checkExtendParent(u);		// recursively ensure all ancestors enforce Rule 3
			}
			oldExpire = dt;					// schedule may have been extended
		}
		
		save();

		// whenever dates are changed, need to check for re-eval of Status
System.out.println("call setStatusByDates or not? " + rc);
		if (rc) setStatusByDates(u);

		// if my ExpireDate has changed, re-cal the StartDate of those that I am the LDT
		if (bHasChanged || (oldExpire!=null && newExpire.compareTo(oldExpire)!=0) ) {
			setSaveMyDependentsDates(u);	// set and commit

			// also might impact recursively my parent's expire date
			// recursively check parent's parent
			checkExtendParent(u);
		}

		// NOTE: setStatusByDates() above will commit all changes
		return rc;
	}

	/**
	 * Recursive method to extend parent StartDate up the tree.
	 * It will stop either at the top level task or if a parent hits a dependency.
	 * In the latter case we will move the schedule out as much as possible.
	 * @param newStart
	 * @return the new StartDate the parent is set to.
	 */
	private Date extendParentStartDate(PstUserAbstractObject u, Date newStart)
		throws PmpException
	{
		if (bDEBUG) debugPrt("Calling extendParentStartDate() on [" + getObjectId() + "] for " + newStart);
		
		task parent = getParentTask(u);
		if (parent == null) return newStart;

		Date parentStartDate = parent.getStartDate();
		if (parentStartDate == null) return newStart;	// parent is container, no problem
		
		Date bestStartDate;
		if (!parentStartDate.after(newStart)) {
			// no need to move parent StartDate
			if (bDEBUG) debugPrt("   extendParentStartDate() ["
					+ getObjectId() + "] return no change: " + newStart);
			return newStart;
		}
		
		if (_dirtyMap!=null) parent.setDirtyMap(_dirtyMap);
		
		//
		// checking parent from this point onward
		//
		
		// A. check to see if I have a dependency
		int diff;
		task ldt = parent.getLDT(u);
		int gap = parent.getGap();
		
		if (ldt != null) {
			// check to see if I can move because of a gap (buffer) exist
			bestStartDate = ldt.getExpireDate();
			if (gap > 0) {
				diff = getDaysDiff(newStart, bestStartDate);
				if (!bestStartDate.after(newStart)) {
					// good, my parent and I can accommodate the newStart
					gap -= diff;				// new gap
					if (gap < 0) gap = 0;		// should not be
				}
				else {
					// check to see what is my earliest possible date
					if (gap >= diff) {
						// use gap to accommodate
						gap -= diff;
					}
					else {
						// although not enough, use all of gap as my best day
						diff -= gap;
						gap = 0;
						bestStartDate = new Date(bestStartDate.getTime() - gap*DayInMsec);
					}
				}
			}	// END: if gap > 0
			
			// gap == 0
			else {
				// my StartDate should already be same as bestStartDate
				// if not it must be because of parent and I should have a gap
				if (parentStartDate.compareTo(bestStartDate) != 0) {
					// if current gap=0 the two dates should be the same, if not I fix it
					// with a gap now
					diff = getDaysDiff(parentStartDate, bestStartDate);
					if (diff < 0) {
						// problem: it will be fixed below by using bestStartDate,
						// but all my children might have to move!!!
						l.error("!!! extendParentStartDate() found task [" + parent.getObjectId()
								+ "] not keeping dependency rule with LDT [" + ldt.getObjectId() + "]");
					}
				}
			}	// END: else gap == 0
		}	// END: if there is an LDT
		
		else {
			// no dependency, I can move freely to accommodate
			bestStartDate = newStart;
		}
		// at this point bestStartDate is the best I can do to extend, and gap is the new gap
		
		//
		// although I have found a bestStartDate based on LDT, it really doesn't mean I can just do that
		// I still have to see if I am bounded by my parent's StartDate
		//
		
		
		// B. check if parent's parent StartDate needs to and can be extended recursively
		Date ancestorStartDate = parent.extendParentStartDate(u, bestStartDate);
		
		
		// C. Closing
		if (ancestorStartDate.after(bestStartDate)) {
			// not good: need to keep the rule to start on/after my parent's StartDate
			bestStartDate = ancestorStartDate;
			gap += getDaysDiff(ancestorStartDate, bestStartDate);
		}
		
		parent.setAttribute("Gap", gap);
		parent.setAttribute("StartDate", bestStartDate);
		parent.setDuration();
		manager.commit(parent);
		if (bDEBUG) debugPrt("   extendParentStartDate() [" + getObjectId() + "] return: set ["
				+ parent.getObjectId() + "] gap=" + gap + ", StartDate=" + bestStartDate);
		
		return bestStartDate;
	}	// END: extendParentStartDate()


	private void extendPjExpireDateIfNeeded(project pj)
		throws PmpException
	{
		if (bDEBUG) System.out.println("calling extendPjExpireDateIfNeeded()");
		Date newExpire = getExpireDate();
		Date dt = pj.getExpireDate();
		if (bDEBUG) System.out.println("   pjExpire=" + dt + "; tkExpire=" + newExpire);
		if (!pj.isContainer() && dt!=null && newExpire.after(dt))
		{
			Date today = Util.getToday();
			pj.setAttribute("ExpireDate", newExpire);
			if ( ((String)pj.getAttribute("Status")[0]).equals(project.ST_LATE) &&
					newExpire.after(today) )
					pj.setAttribute("Status", project.ST_OPEN);		// re-open
			pj.setAttribute("LastUpdatedDate", new Date());
			pjMgr.commit(pj);
		}
	}

	/**
	 *
	 * Set and save the StartDate and ExpireDate of those tasks that consider this task
	 * the LDT.  Note that unlike the other methods in this category, this method will
	 * commit the change of those tasks that depend on this LDT.
	 */
	public void setSaveMyDependentsDates(PstUserAbstractObject u)
        throws PmpException
	{
		task tk, depTk;
		int thisTaskId = getObjectId();
		if (bDEBUG) debugPrt(">>> Call setSaveMyDependentsDates [" + getObjectId() + "]");

		// some task might not be current but it doesn't hurt to set them
		int [] ids = manager.findId(u, "Dependency='" + thisTaskId + "'");
		if (bDEBUG) debugPrt("     total " + ids.length + " dependents");
		for (int i=0; i<ids.length; i++) {
			tk = (task)manager.get(u, ids[i]);
			if (bDEBUG) debugPrt("     checking [" + ids[i] + "]");
			// getLDT() may still return null if all tasks I depend on
			// do not have an expire date, such as when project is created.
			depTk = tk.getLDT(u);
			if (depTk == null)
				continue;

			if (depTk.getObjectId() == thisTaskId) {
				if (bDEBUG) debugPrt("        > found to be LDT.  Calling setDatesByDependentObj()");
				// yes, I am the LDT: need to re-cal the dates of tk
				// this will recursively ripple down the dependent chain
				if (_dirtyMap!=null) tk.setDirtyMap(_dirtyMap);
				if (tk.setDatesByDependentObj(u, this, true)) {
					tk.setAttribute("LastUpdatedDate", new Date());
					manager.commit(tk);
					
					// my dates change might impact my parents
					tk.extendShrinkParentExpireDateIfNeeded(u);
				}
			}
		}
		if (bDEBUG) debugPrt(">>> Done call setSaveMyDependentsDates [" + getObjectId() + "]");
	}

	//
	// setStatusByDates()
	// Set the Status of this task based on its Start, Expire, Complete, Effective Dates.
	// Note that it won't commit the change: caller is responsible to commit.
	// Currently only called by post_updall.jsp.
	//
	public String setStatusByDates(PstUserAbstractObject u)
        throws PmpException
	{
		project pj = getProject(u);
		if (pj.getState().equals(project.ST_NEW)) {
			// don't touch the status of the task if the project is not OPEN yet
			return null;
		}

		String st = getState();
		Date startD = getStartDate();
		Date expireD = getExpireDate();
		Date actualD = (Date)getAttribute("EffectiveDate")[0];
		Date completeD = (Date)getAttribute("CompleteDate")[0];

		Date today = Util.getToday();
		String newState = null;
		int caseNum = 0;

		try {
			if (!st.equals(ST_CANCEL) && !st.equals(ST_ONHOLD))
			{
				// move to ST_COMPLETE
				if (completeD != null && !phase.isSpecialDate(completeD)) {
					caseNum = 2;
					newState = ST_COMPLETE;
					setState(u, newState);// Completed
				}

				// move to ST_LATE (might have to go thru ST_OPEN first)
				else if (expireD!=null && expireD.before(today) && !st.equals(ST_LATE)) {
					// if the state is ST_NEW, then I need to OPEN first before setting to late
					caseNum = 3;
					if (st.equals(ST_NEW)) {
						newState = ST_OPEN;
						setState(u, newState);	// this will create step
					}
					newState = ST_LATE;
					setState(u, newState);		// now immediately set to Expired
				}

				// move to ST_OPEN (StartDate in the past) ||
				// move to ST_OPEN (has actual start date)
				else if ( (startD!=null && !startD.after(today) && st.equals(ST_NEW))
							|| (actualD!=null && !st.equals(ST_OPEN) && !expireD.before(today)) ) {
					caseNum = 5;
					newState = ST_OPEN;
					setState(u, newState);
				}

				// newly created ST_NEW
				else if (startD == null)
				{
					caseNum = 1;
					newState = ST_NEW;
					setAttribute("Status", newState);
					setAttribute("EffectiveDate", null);
					setAttribute("CompleteDate", null);
				}

				// StartDate in the future, move to ST_NEW
				else if (startD.after(today) && actualD==null && !st.equals(ST_NEW)) {
					caseNum = 4;
					newState = ST_NEW;
					setState(u, newState);
				}

				// move from ST_LATE back to ST_OPEN or ST_NEW
				else if (expireD!=null && !expireD.before(today) && st.equals(ST_LATE)) {
					caseNum = 6;
					if (actualD != null)
						newState = ST_OPEN;
					else
						newState = ST_NEW;
					setState(u, newState);		// reopen
				}
			}
		}
		catch (PmpException e) {
			l.warn("setStatusByDates got exception (case " + caseNum + ").\n" +
						"   Failed to move task [" + getObjectId()
						+ "] from " + st + " to " + newState + ".  Ignored.\n"
						+ e.getMessage());
		}

		return newState;
	}	// END setStatusByDates()

	//
	// getParentTaskStartDate()
	// Get the parent task StartDate.  If I am top task, return null
	//
	public Date getParentTaskStartDate(PstUserAbstractObject u)
		throws PmpException
	{
		task parent = getParentTask(u);
		if (parent==null) return null;
		return (parent.getStartDate());
	}	// END getParentTaskStartDate()

	//
	// getParentTaskStartDate()
	// Get the parent task StartDate.  If I am top task, return null
	//
	public Date getParentTaskExpireDate(PstUserAbstractObject u)
		throws PmpException
	{
		task parent = getParentTask(u);
		if (parent==null) return null;
		return parent.getExpireDate();
	}	// END getParentTaskExpireDate()

	//
	// getParentTaskStatus()
	// Get the Status of my parent task
	//
	public String getParentTaskStatus(PstUserAbstractObject u)
		throws PmpException
	{
		task parent = getParentTask(u);
		if (parent==null) return null;
		return ((String)parent.getAttribute("Status")[0]);
	}	// END getParentTaskStatus()

	public task getParentTask(PstUserAbstractObject u)
		throws PmpException
	{
		planTask pt = getPlanTask(u);
		if (pt == null)
			return null;
		int parentId = Integer.parseInt((String)pt.getAttribute("ParentID")[0]);
		if (parentId == 0)
			return null;		// t is a top task, no parent status
		pt = (planTask)ptMgr.get(u, parentId);
		return ( (task)manager.get(u, (String)pt.getAttribute("TaskID")[0]) );
	}	// END getParentTask()

	public project getProject(PstUserAbstractObject u)
		throws PmpException
	{
		return (project)pjMgr.get(u, Integer.parseInt((String)getAttribute("ProjectID")[0]));
	}

	public Date getProjectStartDate(PstUserAbstractObject u)
		throws PmpException
	{
		return getProject(u).getStartDate();
	}

	public planTask getPlanTask(PstUserAbstractObject u)
		throws PmpException
	{
		int ptId = getPlanTaskId(u);
		if (ptId <= 0)
			return null;
		planTask pt = (planTask)ptMgr.get(u, ptId);
		return pt;
	}

	public int getPlanTaskId(PstUserAbstractObject u)
		throws PmpException
	{
		return getPlanTaskId(u, String.valueOf(getObjectId()));
	}

	public static int getPlanTaskId(PstUserAbstractObject u, String tidS)
		throws PmpException
	{
		return getPlanTaskId(u, tidS, null);
	}

	public static int getPlanTaskId(PstUserAbstractObject u, String tidS, String pidS)
		throws PmpException
	{
		int idx = 0;
		PstAbstractObject thisTask;
		if (pidS == null) {
			thisTask = manager.get(u, tidS);
			pidS = (String)thisTask.getAttribute("ProjectID")[0];
		}

		int [] ids = pnMgr.findId(u, "ProjectID='" + pidS
						+ "' && Status='" + plan.ST_LATEST + "'");
		if (ids.length <= 0) {
			l.error("getPlanTaskId() cannot find latest plan for project [" + pidS + "]");
			return 0;
		}

		ids = ptMgr.findId(u, "TaskID='" + tidS + "' && PlanID='" + ids[0]
		                      + "' && Status!='" + planTask.ST_DEPRECATED + "'");
		if (ids.length > 1) {
			l.info("task.getPlanTaskId() returns [" + ids.length + "] planTaskIds for task ["
						+ tidS + "].  It should have only one.");
			Arrays.sort(ids);
for (int i=0; i<ids.length; i++) System.out.print(ids[i] + " ");
System.out.println("");
			idx = ids.length-1;
		}
		else if (ids.length <= 0) {
			// possible if the task has been deleted
			l.info("task.getPlanTaskId() returns [" + ids.length + "] planTaskIds for task ["
					+ tidS + "].  The task must have been obsoleted. Perform auto clean up to delete task [" + tidS + "].");
			try {
				thisTask = manager.get(u, tidS);
				manager.delete(thisTask);
			} catch (PmpException e) {}
			return 0;
		}
		return ids[idx];					// should have only 1
	}

	public String getTaskName(PstUserAbstractObject u)
	{
		try {
			planTask pt = getPlanTask(u);
			if (pt != null) {
				return (String) pt.getAttribute("Name")[0];
			}
		}
		catch (PmpException e) {}
		return null;
	}

	// recursively update the StartDate of the children tasks of this planTask in a tree
	public void setChildrenStartDate(PstUserAbstractObject u, int pTaskId)
		throws PmpException
	{
		// whenever changing the start date, need to consider changing status to Open if the
		// start date is today
		planTask pt;
		int [] ptId = ptMgr.findId(u, "ParentID='" +pTaskId+ "' && Status!='Deprecated'");
		Date stDt = getStartDate();

		Date today = Util.getToday();
		boolean bOpen = false;
		boolean bNew = false;
		if (stDt!=null && stDt.compareTo(today) == 0) bOpen = true;
		if (stDt==null || stDt.after(today)) bNew = true;

		for (int i=0; i<ptId.length; i++)
		{
			pt = (planTask)ptMgr.get(u, ptId[i]);
			task tk = (task)manager.get(u, (String)pt.getAttribute("TaskID")[0]);
			tk.setAttribute("StartDate", stDt);
			if (((String)tk.getAttribute("Status")[0]).equals("New") && bOpen) {
				//tk.setAttribute("Status", "Open");
				tk.setState(u, ST_OPEN);
			}
			else if (bNew) {
				//tk.setAttribute("Status", "New");
				tk.setState(u, ST_NEW);
			}
			manager.commit(tk);

			// recursive call
			tk.setChildrenStartDate(u, ptId[i]);
		}
	}	// END setChildrenStartDate()

	// recursively update the ExpireDate of the children tasks of this planTask in a tree
	public void setChildrenExpireDate(PstUserAbstractObject u, int pTaskId)
		throws PmpException
	{
		planTask pt;
		int [] ptId = ptMgr.findId(u, "ParentID='" +pTaskId+ "' && Status!='Deprecated'");
		Date expDt = getExpireDate();
		for (int i=0; i<ptId.length; i++)
		{
			pt = (planTask)ptMgr.get(u, ptId[i]);
			task tk = (task)manager.get(u, (String)pt.getAttribute("TaskID")[0]);
			tk.setAttribute("ExpireDate", expDt);
			if (((String)tk.getAttribute("Status")[0]).equals(ST_LATE))
				tk.setAttribute("Status", ST_OPEN);
			manager.commit(tk);

			// when my ExpireDate has change, tasks that see me as LDT needs to be changed
			tk.setSaveMyDependentsDates(u);	// set and commit

			// recursive call
			tk.setChildrenExpireDate(u, ptId[i]);
		}
	}	// END setChildrenExpireDate()

	//
	// moveChildrenForward(): recursive
	// This is call after a task schedule has been delayed.
	// Move my children StartDate to ensure that they start after me.  The ExpireDate will be
	// moved to keep the same duration.  At the end, all parents in the sub-tree will ensure:
	// (1) children start after parent starts; (2) parent ends after children end.
	// Note that the caller's ExpireDate is also changed.
	// Return the latest ExpireDate in the sub-tree.
	//
	public Date moveChildrenForward(PstUserAbstractObject u)
		throws PmpException
	{
		Date parentStartDate = getStartDate();
		Date parentExpireDate = getExpireDate();
		Date dt;
		Date now = new Date();
		long diff;
		Calendar cal = Calendar.getInstance();

		planTask pt = getPlanTask(u);
		if (pt == null) return null;	// the task might have been deleted

		// ECC: should use getChildren() to retrieve the children list
		int [] ptId = ptMgr.findId(u, "ParentID='" +pt.getObjectId()+ "' && Status!='Deprecated'");
		for (int i=0; i<ptId.length; i++)
		{
			// go thru my children
			pt = (planTask)ptMgr.get(u, ptId[i]);
			task tk = (task)manager.get(u, (String)pt.getAttribute("TaskID")[0]);
			if (_dirtyMap!=null) tk.setDirtyMap(_dirtyMap);
			dt = tk.getStartDate();
			if (dt!=null && dt.before(parentStartDate))
			{
				// move my StartDate according to my parent
				cal.setTime(parentStartDate);
				cal.add(Calendar.DATE, getGap());
				Date newStart = cal.getTime();			// newStart is the gap + parent's StartDate
				tk.setAttribute("StartDate", newStart);	// moving forward would not violate dependency

				// move ExpireDate according to Duration
				int dur = getDuration();
				Date newExpire;
				if (dur > 0) {
					cal.add(Calendar.DATE, dur);
					newExpire = cal.getTime();
					tk.setAttribute("ExpireDate", newExpire);
				}
				else {
					// if no duration specified, calculate Duration based on Start/Expire
					diff = dt.getTime();
					dt = tk.getExpireDate();	// dt becomes ExpireDate
					if (dt != null)
					{
						diff = dt.getTime() - diff;		// my original task length

						// move task ExpireDate to keep the duration
						newExpire = new Date(newStart.getTime() + diff);
						tk.setAttribute("ExpireDate", newExpire);

						// extend the caller's schedule if necessary
						if (parentExpireDate.before(newExpire))
							parentExpireDate = newExpire;
					}
					//tk.setDuration();
				}
				tk.setAttribute("LastUpdatedDate", now);
				manager.commit(tk);			// commit my change of StartDate and ExpireDate

				// move my dependents if there is any
				tk.setSaveMyDependentsDates(u);

				// recursive call
				dt = tk.moveChildrenForward(u);
				if (dt.after(parentExpireDate))
					parentExpireDate = dt;
			}
		}

		// check to see if I need to extend my schedule
		if (parentExpireDate!=null && parentExpireDate.after(getExpireDate()))
		{
			// my schedule has been extended
			setAttribute("ExpireDate", parentExpireDate);
			setAttribute("LastUpdatedDate", now);
			manager.commit(this);
		}

		return parentExpireDate;

	}	// END moveChildrenForward()

	// get the latest ExpireDate of the children tasks of this planTask in a tree
	public Date getChildrenLatestExpireDate(PstUserAbstractObject u)
		throws PmpException
	{
		return getChildrenLatestExpireDate(u, getPlanTaskId(u));
	}
	public Date getChildrenLatestExpireDate(PstUserAbstractObject u, int pTaskId)
		throws PmpException
	{
		planTask pt;
		int [] ptId = ptMgr.findId(u, "ParentID='" + pTaskId
								+ "' && Status!='" + planTask.ST_DEPRECATED + "'");
		Date dt, expDt = null;
		for (int i=0; i<ptId.length; i++)
		{
			pt = (planTask)ptMgr.get(u, ptId[i]);
			task tk = (task)manager.get(u, (String)pt.getAttribute("TaskID")[0]);
			dt = tk.getExpireDate();
			if (expDt==null || (dt!=null && !phase.isSpecialDate(dt) && dt.after(expDt)) )
				expDt = dt;
		}
		return expDt;
	}	// END getChildrenLatestExpireDate()

	public ArrayList<task>getChildren(PstUserAbstractObject u)
		throws PmpException
	{
		ArrayList<task>children = new ArrayList<task>();
		task tk;
		planTask pt;
		int [] ptId = ptMgr.findId(u, "ParentID='" + getPlanTaskId(u)
								+ "' && Status!='" + planTask.ST_DEPRECATED + "'");
		for (int i=0; i<ptId.length; i++)
		{
			pt = (planTask)ptMgr.get(u, ptId[i]);
			tk = (task)manager.get(u, (String)pt.getAttribute("TaskID")[0]);
			children.add(tk);
		}
		return children;
	}

	private Date getChildrenEarlestStartDate(PstUserAbstractObject u)
		throws PmpException
	{
		planTask pt;
		int [] ptId = ptMgr.findId(u, "ParentID='" + getPlanTaskId(u)
								+ "' && Status!='" + planTask.ST_DEPRECATED + "'");
		Date dt, startDt = null;
		for (int i=0; i<ptId.length; i++)
		{
			pt = (planTask)ptMgr.get(u, ptId[i]);
			task tk = (task)manager.get(u, (String)pt.getAttribute("TaskID")[0]);
			dt = tk.getStartDate();
			if (startDt==null || (dt!=null && dt.before(startDt)) )
				startDt = dt;
		}
		return startDt;
	}

	// recursively check and extend parent ExpireDate to ensure my parent won't end before me (Rule 3)
	public void checkExtendParent(PstUserAbstractObject u)
		throws PmpException
	{
		Date expD = getExpireDate();
		if (expD == null) return;

		task parent = getParentTask(u);
		if (parent == null) return;

		Date parentExpireD = parent.getExpireDate();

		if (parentExpireD == null || phase.isSpecialDate(parentExpireD)) return;

		if (expD != null && expD.after(parentExpireD))
		{
			if (_dirtyMap!=null) parent.setDirtyMap(_dirtyMap);
			parent.setAttribute("ExpireDate", expD);
			parent.setAttribute("LastUpdatedDate", new Date());
			manager.commit(parent);

			// when a task changed its deadline, its depends may need to change
			parent.setSaveMyDependentsDates(u);

			// recursively check parent's parent
			parent.checkExtendParent(u);
		}
	}	// END checkExtendParent()

	/**
	 */
	private int [] getDependentChildIds(PstUserAbstractObject u, int [] activeTids)
		throws PmpException
	{
		int [] ids = manager.findId(u, "Dependency='" + getObjectId() + "'");
		if (activeTids == null) {
			project pj = getProject(u);
			ids = pj.mergeCurrentTasks(u, ids);
		}
		else {
			ids = Util2.mergeJoin(ids, activeTids);
		}
		return ids;
	}

	/**
	*/
	public boolean hasNoDependentChild(PstUserAbstractObject u, int [] activeTids)
		throws PmpException
	{
		int [] ids = getDependentChildIds(u, activeTids);
		if (ids.length > 0)
			return false;
		else
			return true;
	}

	/**
	*/
	public PstAbstractObject [] getDependentChildren(
			PstUserAbstractObject u, int [] activeTids)
		throws PmpException
	{
		// ECC: would there be deprecated tasks included?
		int [] ids = getDependentChildIds(u, activeTids);
		PstAbstractObject [] objArr = manager.get(u, ids);
		return objArr;
	}

	/**
	 * set the gap and duration based on the StartDate and ExpireDate
	 * call this method after you set the StartDate and/or ExpireDate
	 * this may also impact the timeline of those tasks that depend on me
	 * and my children tasks.
	 * @param b
	 */
	public void setTimeLine(PstUserAbstractObject u)
		throws PmpException
	{
		Date startDt = getStartDate();
		Date expireDt = getExpireDate();
		Date dt;
		task parent;
		int myId = getObjectId();

		/////////////////////////////////////
		// A. set gap and duration

		// set gap has 3 rules
		// gap rule 1: based on LDT
		int gap;
		task ldt = getLDT(u);
		if (ldt != null) {
			// calculate gap based on ldt expireDate
			dt = ldt.getExpireDate();
			gap = getDaysDiff(startDt, dt);
		}

		// gap rule 2: based on parent task startDate
		else if ((parent=getParentTask(u)) != null) {
			// calculate gap based on parent
			dt = parent.getStartDate();
			gap = getDaysDiff(startDt, dt);
		}

		// gap rule 3: based on project startDate
		else {
			// calculate gap based on project
			dt = getProjectStartDate(u);
			gap = getDaysDiff(startDt, dt);
		}

		// now set the gap attribute
		if (gap < 0) {
			// this shouldn't happen
			l.error("task [" + myId
					+ "] startDate is before dependent - force move task startDate.");
			gap = 0;
			setAttribute("StartDate", dt);
		}
		setAttribute("Gap", gap);


		// set duration
		int dur = getDaysDiff(expireDt, startDt);
		setAttribute("Duration", dur);
		if (bDEBUG) debugPrt("setTimeline() duration = " + dur);

		// all of my updates are done
		manager.commit(this);

		/////////////////////////////////////
		// B. set my dependent's timeline based on my dates
		int [] ids = manager.findId(u, "Dependency='" + myId + "'");
		ids = getProject(u).mergeCurrentTasks(u, ids);
		task tk;
		for (int tid : ids) {
			tk = (task)manager.get(u, tid);
			if (tk.getLDT(u).getObjectId() == myId) {
				// might need to change the gap of my dependent
				int tkGap = tk.getGap();
				dt = tk.getStartDate();
				gap = getDaysDiff(dt, expireDt);
				if (gap != tkGap) {
					Date newStartDate = null;
					if (gap < 0) {
						gap = 0;
						newStartDate = expireDt;
					}
					else if (gap < tkGap) {
						newStartDate = addDays(expireDt, gap);
					}
					else {
						gap = tkGap;
						newStartDate = addDays(expireDt, gap);
					}
					tk.setAttribute("Gap", gap);
					tk.moveStartDate(newStartDate);

					manager.commit(tk);
					l.info("setTimeline() has updated dep task [" + tid + "] gap.");
				}
			}
		}

		/////////////////////////////////////
		// C. set gap of my children who do not have an LDT
		// their startDate are set correctly by the client
		ArrayList<task>children = getChildren(u);
		for (task child : children) {
			int childGap = child.getGap();
			ldt = child.getLDT(u);
			if (ldt != null) {
				// since the child's startDate may have changed, need to check gap by LDT
				dt = ldt.getExpireDate();
			}
			else {
				// no LDT, use me (parent) to set gap
				dt = startDt;
			}
			gap = getDaysDiff(child.getStartDate(), dt);
			if (gap != childGap) {
				if (gap < 0) {
					gap = 0;
					child.setAttribute("StartDate", dt);
				}
				child.setAttribute("Gap", gap);
				manager.commit(child);
				l.info("setTimeline() has updated child task [" + child.getObjectId() + "] gap.");
			}
		}

	}

	/**
	 * setStartDate set the task StartDate accordingly and move the ExpireDate
	 * based on the Duration
	 * @param expireDt
	 */
	private void moveStartDate(Date dt)
		throws PmpException
	{
		setAttribute("StartDate", dt);
		int dur = ((Integer)getAttribute("Duration")[0]).intValue();
		Date newExpire = addDays(dt, dur);
		setAttribute("ExpireDate", newExpire);
	}

	///////////////////////////////////////////////////////////////////////
	// Workflow

	// TODO: to be more consistent, the step should be created when the
	// task is created.  It then goes thru state tx along with the task.
	/**
	 * Create a step to track this task.  This API should be called when
	 * a task is moved from <code>ST_NEW</code> to <code>ST_OPEN</code>.
	 * @param u login user.
	 * @return the task step corresponding to this task.
	 * @throws PmpException
	 */
	public PstFlowStep createStep(PstUserAbstractObject u)
		throws PmpException
	{
		if (getStartDate() == null)
			return null;			// container task: no step

		project pj = getProject(u);
		if (pj == null)
			return null;			// no project found

		String tkState = getState();
		if (tkState.equals(ST_NEW))
			return null;			// task not started yet

		PstFlowStep step = getStep(u);
		if (step != null) {
			// a step is already created for this task
			l.info("Step [" + step.getObjectId() + "] already exists for task ["
					+ getObjectId() + "], no step created.");
			if (!step.getState().equals(PstFlowConstant.ST_STEP_ACTIVE)) {
				step.setState(PstFlowConstant.ST_STEP_ACTIVE);
			}
		}

		// create the step
		else {
			//PstFlow projFlow = pj.getProjectFlow(u);
			// this has nothing to do with the project flow instance even if it exist
			// every task is on its own and may contain its own ad-hoc flowMap.

			// create the step object and put it in ACTIVE state
			step = (PstFlowStep)fsMgr.create(u, null, null, null, null, PstFlowStep.TYPE_PROJTASK);
			l.info("Created a step [" + step.getObjectId() + "] for task ["
				+ getObjectId() + "]");

			// set info for the task step object
			step.setAttribute("ProjectID", String.valueOf(pj.getObjectId()));
			step.setAttribute("TaskID", String.valueOf(getObjectId()));
			step.setAttribute("Owner", (String)getAttribute("Owner")[0]);
			step.setAttribute("CurrentExecutor", (String)getAttribute("Owner")[0]);

			// no need to handle in-coming/out-going arc
			// because task dependencies will handle that w/o workflow
		}

		// set step state based on task state
		if (tkState.equals(ST_COMPLETE))
			step.setCurrentState(PstFlowConstant.ST_STEP_COMMIT);
		else if (tkState.equals(ST_CANCEL))
			step.setCurrentState(PstFlowConstant.ST_STEP_ABORT);
		else
			// for all others, set it to active
			step.setCurrentState(PstFlowConstant.ST_STEP_ACTIVE);

		fsMgr.commit(step);

		return step;
	}

	/**
	 * get the flow step corresponding to this task if it exists.
	 * @param u login user.
	 * @return the task step if it exists, else return null.
	 * @throws PmpException
	 */
	public PstFlowStep getStep(PstUserAbstractObject u)
		throws PmpException
	{
		PstFlowStep step = null;
		int [] ids = fsMgr.findId(u, "TaskID='" + getObjectId() + "'");
		if (ids.length > 0) {
			step = (PstFlowStep) fsMgr.get(u, ids[0]);
		}
		return step;
	}

	/**
	 * When the task change State, it has implications to the step State as well.
	 * This call will commit the task upon successfully setting the Status attribute.
	 * @param login user.
	 * @param the new state to be set for this task.
	 * @return
	 * @throws PmpException
	 * @throws ParseException
	 */
	public void setState(PstUserAbstractObject u, String newState)
		throws PmpException
	{
		// ST_NEW, ST_OPEN, ST_ONHOLD, ST_LATE, ST_COMPLETE, ST_CANCEL
		String currentState = (String)getAttribute(ATTR_STATUS)[0];
		Date actualD = getEffectiveDate();

		if (bDEBUG) debugPrt(">>> setState() for task [" + getObjectId()
				+ "] from " + currentState + " to " + newState);

		if (newState==null || newState.equals(currentState)) {
			return;				// no change
		}

		String parentSt;
		String historyID = "";
		project pj = getProject(u);

		/////////////////////////////
		// task first created
		if (newState.equals(ST_NEW)) {
			if (currentState==null || actualD==null) {
				setAttribute(ATTR_STATUS, ST_NEW);
			}
			else
				badState(currentState, newState);
		}

		/////////////////////////////
		// task started (open)
		else if (newState.equals(ST_OPEN)) {
			if (currentState==null || currentState.equals(ST_NEW)
					|| currentState.equals(ST_LATE)
					|| currentState.equals(ST_ONHOLD)) {

				// my parent must be open before I can open
				parentSt = getParentTaskStatus(u);
				if ( parentSt != null &&
						!(parentSt.equals(ST_OPEN) ||
						  parentSt.equals(ST_LATE) ||
						  parentSt.equals(ST_COMPLETE)) ) {
					throw new PmpException("Cannot move task [" + getObjectId()
						+ "] to OPEN unless its parent task is in the OPEN, LATE or COMPLETE state.");
				}

				// make sure my dependencies are fulfilled
				if (!dependencyFulFilled(u)) {
					throw new PmpException("Cannot move task [" + getObjectId()
						+ "] to OPEN until all of its dependent tasks are COMPLETED or CANCELED.");
				}

				// go ahead and open now
				setAttribute(ATTR_STATUS, ST_OPEN);
				if (getEffectiveDate() == null) {
					// if EffectiveDate is already set, do not fill it
					setAttribute("EffectiveDate",  Util.getToday());
				}

				// *** create and start a workflow step ***
				createStep(u);
				historyID = "HIST.4101";
			}
			else
				badState(currentState, newState);
		}

		/////////////////////////////
		// task on-hold
		else if (newState.equals(ST_ONHOLD)) {
			if (!currentState.equals(ST_COMPLETE) && !currentState.equals(ST_CANCEL)) {
				setAttribute(ATTR_STATUS, ST_ONHOLD);
				historyID = "HIST.4105";
			}
			else
				badState(currentState, newState);
		}

		/////////////////////////////
		// task late
		else if (newState.equals(ST_LATE)) {
			if (currentState.equals(ST_OPEN)) {
				setAttribute(ATTR_STATUS, ST_LATE);
				historyID = "HIST.4104";
			}
			else
				badState(currentState, newState);
		}

		/////////////////////////////
		// task completed
		else if (newState.equals(ST_COMPLETE)) {
			String pjStatus = pj.getState();
			parentSt = getParentTaskStatus(u);
			if (pjStatus.equals(project.ST_COMPLETE) ||
				(parentSt!=null && parentSt.equals(ST_COMPLETE)) ||
				( dependencyFulFilled(u) &&
						(currentState.equals(ST_OPEN)
						|| currentState.equals(ST_LATE)
						|| getEffectiveDate() != null) )) {

				// if project or parent is completed, absolutely fine and go ahead
				// otherwise I need to make sure all dependencies are fulfilled
				setAttribute(ATTR_STATUS, ST_COMPLETE);
				if (getCompleteDate() == null) {
					// if CompleteDate is already set, don't fill it
					setAttribute("CompleteDate", Util.getToday());

					// fix Start and Expire if null - for plan template calculation
					if (getStartDate() == null) {
						setAttribute("StartDate", getCompleteDate());
					}
					Date dt = getExpireDate();
					if (dt==null || dt.before(getStartDate())) {
						setAttribute("ExpireDate", getStartDate());
					}
				}
				save();		// needs to save in order for notifyOnTaskComplete() to work
				historyID = "HIST.4103";

				// *** commit the workflow step ***
				PstFlowStep myStep = getStep(u);
				if (myStep != null) {
					myStep.commitStep(Prm.getSpecialUser(), null);
				}

				// based on dependencies notify the task owners that if
				// the dependent tasks are ready to start
				notifyOnTaskComplete(u);

				notifyChildrenComplete(u);
			}
			else
				badState(currentState, newState);
		}

		/////////////////////////////
		// task canceled
		else if (newState.equals(ST_CANCEL)) {
			if (!currentState.equals(ST_COMPLETE)) {
				setAttribute(ATTR_STATUS, newState);
				historyID = "HIST.4106";

				// *** abort the workflow step ***
				PstFlowStep myStep = getStep(u);
				if (myStep != null) {
					myStep.abortStep(Prm.getSpecialUser(), null);
				}
			}
			else
				badState(currentState, newState);
		}
		else
			badState(currentState, newState);

		save();

		if (historyID != "") {
			history.addRecord(u, historyID,
					null, null,
					String.valueOf(pj.getObjectId()),
					String.valueOf(getObjectId()));
		}

		// change my children's state based on my new state
		updateTaskStatusRecursive(u, getPlanTaskId(u), newState);

		if (bDEBUG) debugPrt("<<< setState() for task [" + getObjectId()
				+ "] from " + currentState + " to " + newState + " done");
	}


	public boolean dependencyFulFilled(PstUserAbstractObject u)
		throws PmpException
	{
		boolean depFulFill = true;
		Object [] depArr = getAttribute("Dependency");
		for (int i=0; i<depArr.length; i++) {
			if (depArr[i] == null)
				break;
			task atask = (task)manager.get(u, (String)depArr[i]);
			String depState = (String)atask.getAttribute("Status")[0];
			if (!depState.equals(ST_COMPLETE) && !depState.equals(ST_CANCEL)) {
				depFulFill = false;
				break;
			}
		}
		return depFulFill;
	}


	private void badState(String currentState, String newState)
		throws PmpException
	{
		String msg = "Task [" + getObjectId() + "] cannot setState() from "
						+ currentState + " to " + newState;
		l.error(msg);
		throw new PmpException(msg);
	}

	/**
	 * Check on all tasks dependent on me, if a task has its dependencies all
	 * fulfilled, send Email notification to its owners to tell them the task
	 * is ready to start.  But if the dependent task has its StartDate on or
	 * before today, then the task would be set to OPEN/LATE.
	 * @param u
	 * @throws PmpException
	 * @throws ParseException
	 */
	private void notifyOnTaskComplete(PstUserAbstractObject u)
		throws PmpException
	{
		Date today = null;
		try {today = df.parse(df.format(new Date()));}
		catch (ParseException e) {throw new PmpException(e.getMessage());}
		String status = (String)getAttribute(ATTR_STATUS)[0];
		int taskID = getObjectId();
		String s;

		userManager uMgr = userManager.getInstance();

		if (status.equals(ST_COMPLETE))
		{
			// @041805ECC when task is complete, send notification to all those task
			// owners who are depending on this task

			int [] ids = manager.findId(u, "Dependency='" + taskID + "'");
			boolean depFulfill;
			Object [] depArr;

			for (int i=0; i<ids.length; i++)
			{
				task depT = (task)manager.get(u, ids[i]);
				depFulfill = true;
				String msg = "All dependencies of the following task have been fulfilled. ";

				// check all the dependencies of depT
				depArr = depT.getAttribute("Dependency");
				for (int j=0; j<depArr.length; j++)
				{
					if (depArr[j] == null) break;
					if (Integer.parseInt((String)depArr[j]) == taskID) {
						continue;	// this is me
					}
					task atask = (task)manager.get(u, (String)depArr[j]);
					s = (String)atask.getAttribute(ATTR_STATUS)[0];
					if (!s.equals(ST_COMPLETE) && !s.equals(ST_CANCEL))
					{
						depFulfill = false;
						break;
					}
				}
				if (!depFulfill) continue;

				Date startDate = depT.getStartDate();
				if (!startDate.after(today) || depT.getGap()<=0) {
					// ready to start the task
					if (depT.getEffectiveDate() == null) {
						depT.setAttribute("EffectiveDate", today);
					}
					depT.setStatusByDates(u);	// this will do the trick
					msg += "Based on the Planned Start Date of the task, it has been started automatically.";

					history.addRecord(u, "HIST.4102", null, null,
							String.valueOf(getProject(u).getObjectId()),
							String.valueOf(getObjectId()));
					//continue;
				}
				else {
					msg += "You can start working on the task now.";
				}
				msg += "<br><br>";

				// all the dependencies of depT have been fulfilled, the msg
				// is either (1) task has been auto started; (2) you can start it now.
				// msg to task owner (or project owner).
				msg += TaskInfo.getProjTaskStack(u, depT) + "<br>";
				user owner = (user)uMgr.get(u, Integer.parseInt((String)depT.getAttribute("Owner")[0]));
				s = (String)owner.getAttribute("Email")[0];
				if (s == null) {
					// no task owner, send to project owner instead
					project pj = getProject(u);
					s = (String)pj.getAttribute("Owner")[0];
					if (s == null)
						continue;
				}
				if (!Util.sendMailAsyn(FROM, s, null, null, EMAIL_SUBJ, msg, MAILFILE)) {
					l.error("!!! Error sending task dependency notification message");
				}
				// PrmAlert.checkSendAlert() will move the task to OPEN automatically
			}
		}
	}

	/**
	 * Move all my children to complete and notify the task owner.
	 * @param u
	 */
	private void notifyChildrenComplete(PstUserAbstractObject u)
		throws PmpException
	{
		// for now, regardless of dependencies, if the parent
		// move to COMPLETE, all children must also move to
		// COMPLETE.
		ArrayList<task> children = getChildren(u);
		for (task child : children) {
			child.setState(u, ST_COMPLETE);		// it will recursive and will save
		}
	}

	// recursively update the Status of the children task of this planTask in a tree
	/**
	 * This method is to change children Status when the parent task has
	 * changed Status.
	 * 1.  When parent is Completed
	 *     - On-hold children are canceled.
	 * 2.  When parent is Open
	 *     - On-hold children might go to New, Open or Late.
	 */
	private static void updateTaskStatusRecursive(
			PstUserAbstractObject u,
			int pTaskId,					// parent (my) planTask
			String parentSt					// parent (my) Status
			)
		throws PmpException
	{
		if (parentSt.equals(ST_LATE))
			return;			// nothing to do to children

		int [] ptId = ptMgr.findId(u, "ParentID='" +pTaskId+ "' && Status!='Deprecated'");
		int jj = 0;
		Date today = Util.getToday();
		Date now = new Date();
		for (int i=0; i<ptId.length; i++)
		{
			planTask apt = (planTask)ptMgr.get(u, ptId[i]);
			String tidS = (String)apt.getAttribute("TaskID")[0];
			task childTask = (task)manager.get(u, Integer.parseInt(tidS));
			String childSt = (String)(childTask.getAttribute("Status")[0]);
			Date expDt = childTask.getExpireDate();
			Date staDt = childTask.getStartDate();

			// @AGQ101904
			if(parentSt.equals(ST_COMPLETE) && childSt.equals(ST_ONHOLD))
			{	// Task Completed, change on-hold subtasks to canceled.
				jj = 1;
			}

			// cases with no change on state
			else if ((parentSt.equals(ST_CANCEL) && childSt.equals(ST_COMPLETE))
				|| (parentSt.equals(ST_COMPLETE) && childSt.equals(ST_CANCEL))
				|| (parentSt.equals(ST_ONHOLD) && childSt.equals(ST_CANCEL))
				|| (parentSt.equals(ST_ONHOLD) && childSt.equals(ST_COMPLETE))
				|| (parentSt.equals(ST_OPEN) && childSt.equals(ST_COMPLETE))
				|| (parentSt.equals(ST_OPEN) && childSt.equals(ST_CANCEL)))
			{	jj=2;
			}

			else if (parentSt.equals(ST_OPEN) && childSt.equals(ST_ONHOLD))
			{	// Changes all task from On-hold to Open and determine if its new, open, or late
				jj = 3;
			}

			else if (parentSt.equals(ST_OPEN)) // Do not automatically open all child
				continue;

			if(parentSt.equals(ST_COMPLETE) && childTask.getCompleteDate() == null)
			{ 	//The children will also be set w/ a CompleteDate if there isn't one.
				if (!childSt.equals(ST_CANCEL) && !childSt.equals(ST_ONHOLD)) {
					// Canceled and On-hold status will not have a CompletedDate
					childTask.setAttribute("CompleteDate", new Date());
				}
			}


			if (jj == 1) {
				childTask.setAttribute("Status", ST_CANCEL);
			}
			else if (jj == 3)
			{	// check ExpireDate, CreatedDate and determine if it is late
				if (today.before(staDt))
					childTask.setAttribute("Status", ST_NEW);
				else if ( today.after(expDt) )
					childTask.setAttribute("Status", ST_LATE);
				else
					childTask.setAttribute("Status", parentSt);
			}
			else if (jj == 0) {
				childTask.setAttribute("Status", parentSt);
			} else {
				jj = 0;
			}
			childTask.setAttribute("LastUpdatedDate", now);
			manager.commit(childTask);
			updateTaskStatusRecursive(u, ptId[i], parentSt);
		}
		return;
	}

	/**
	 *  Set the Owner attribute of the task with the new owner ID String.
	 *  This call will change the owner of the step.  It will the change
	 *  to the step but not to the task object.  Caller must commit the
	 *  task.
	 *  @param newOwner is the new user ID String to be set.
	 */
	public void setOwner(PstUserAbstractObject u, String newOwner)
		throws PmpException
	{
		String oldOwner = (String)getAttribute("Owner")[0];
		if (oldOwner==null || !oldOwner.equals(newOwner)) {
			setAttribute("Owner", newOwner);	// no commit

			// change currentExecutor of the associated step if any
			PstFlowStep step = getStep(u);
			if (step != null) {
				step.setAttribute("CurrentExecutor", newOwner);
				fsMgr.commit(step);
			}
		}
		// do nothing if the new and old ID are the same
	}

	/**
	 * get the color scheme for displaying the phase in the project plan.
	 * @return the phase color as specified by user.  Return empty string if
	 * this is not a phase or if user did not choose a color for the phase.
	 */
	public String getPhaseColor(PstUserAbstractObject u)
		throws PmpException
	{
		phase phObj = getPhase(u);
		if (phObj == null) return "";	// not a phase

		String color = (String) phObj.getAttribute("Color")[0];
		if (color == null)
			color = "";					// no color specified
		return color;
	}

	/**
	 *
	 * @param u
	 * @return the phase object of this task.
	 */
	public phase getPhase(PstUserAbstractObject u)
		throws PmpException
	{
		int [] ids = phMgr.findId(u, "TaskID='" + getObjectId() + "'");
		if (ids.length <= 0)
			return null;
		if (ids.length > 1) {
			l.warn("task [" + getObjectId() + "] found "
					+ ids.length + " phases; should have at most one.");
		}
		return (phase)phMgr.get(u, ids[0]);
	}


	/**
	 *
	 * @return true if this task is a phase or subphase, otherwise false.
	 */
	public boolean isPhase(PstUserAbstractObject u)
		throws PmpException
	{
		return getPhase(u)!=null;
	}
	
	/**
	 * 
	 * @return the phase string such as 1 or 1.1
	 */
	public String getPhaseString(PstUserAbstractObject u)
		throws PmpException
	{
		String phStr;
		phase ph = getPhase(u);
		if (ph == null) return null;
		
		phStr = ((Integer)ph.getAttribute("PhaseNumber")[0]).toString();
		String parentIdS = ph.getStringAttribute("ParentID");
		if (parentIdS != null) {
			// this is a milestone (sub-phase)
			phase parentPh = (phase)phMgr.get(u, parentIdS);
			phStr = ((Integer)parentPh.getAttribute("PhaseNumber")[0]).toString() + "." + phStr;
		}
		return phStr;
	}
	
	/**
	 * 
	 * @param u
	 * @return
	 * @throws PmpException
	 */
	public boolean isTopLevel(PstUserAbstractObject u)
		throws PmpException
	{
		planTask pt = getPlanTask(u);
		String parentIdS = pt.getStringAttribute("ParentID");
		return (parentIdS==null || parentIdS.equals("0"));
	}


	// we can move the following into an Interface TimeOperation
	public int getGap() throws PmpException {return ((Integer)getAttribute("Gap")[0]).intValue();}
	public int getDuration() throws PmpException {return ((Integer)getAttribute("Duration")[0]).intValue();}

	public static void setDebug(boolean b) {bDEBUG = b;}
	private void debugPrt(String msg) {System.out.println(msg);}


	public boolean isContainer() {
		try {return getStartDate()==null;}
		catch (PmpException e ) {return true;}	// fail to get StartDate, consider a container
	}

	public void setWeight(project pj, Double wDbl)
		throws PmpException
	{
		String optStr;
		if ((optStr = pj.getOption(project.OP_RESOURCE_MGMT)) != null) {
			// with resource management, allow user to input the weight of this task
			String [] sa = optStr.split(project.DELIMITER2);		// float@hr/wk
			String optAttr = sa[0];
			setAttribute(optAttr, wDbl);
		}
	}
	

	/**
		get the option identified by optionName.  If the optionName
		does not exist, return null.  If it exist and has a value
		separated by ":", return only the value.  Otherwise return
		the optionName.
	*/
	public String getOption(String optionName)
		throws PmpException
	{
		return getSubAttribute(ATTR_OPTION, optionName);
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
		setSubAttribute(manager, ATTR_OPTION, optionName, optionValue);
	}

}
