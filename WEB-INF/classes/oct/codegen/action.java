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
//  File:   action.java
//  Author: FastPath CodeGen Engine
//  Date:   03.18.2004
//  Description:
//		Implementation of action class
//  Modification:
//		@030904ECC	Created template file for class representation of OMM Organization.
//		@033004ECC	Support appending single data value to multiple data attribute.
//		@SWS092806	Delete action blogs' comment.
//
/////////////////////////////////////////////////////////////////////
//
// action.java : implementation of the action class
//

package oct.codegen;
import java.io.File;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
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
import oct.pst.PstFlowStep;
import oct.pst.PstFlowStepManager;
import oct.pst.PstGuest;
import oct.pst.PstTimeAbstractObject;
import oct.pst.PstUserAbstractObject;

import org.apache.log4j.Logger;

import util.Prm;
import util.PrmLog;
import util.StringUtil;
import util.Util;

/**
*
* <b>General Description:</b>  action extends PmpAbstractObject.  This class
* encapsulates the data of a member from the "action" organization.
*
* The action class provides a facility to modify data of an existing action object.
* The front-end is primarily triggered from post_mtg_upd2.jsp (which can be called
* by mtg_update2.jsp or worktray.jsp (thru action.showAddActionPanel() ).
* An action object goes through a number of state transitions through setStatus().
*
*
* <b>Class Dependencies:</b>
*   oct.custom.actionManager
*   oct.pmp.PmpUser
*   oct.pmp.PmpUserManager
*
*
* <b>Miscellaneous:</b> There are methods that will be deprecated in future versions.
*
*/


public class action extends PstTimeAbstractObject

{
	// Public attributes
	// action item state
	public final static String OPEN		= "Open";
	public final static String LATE		= "Late";
	public final static String CANCEL	= "Cancel";
	public final static String DONE		= "Done";
	public static final String [] STATE_ARRAY	= {OPEN, LATE, CANCEL, DONE};

	// action priority
	public static final String PRI_LOW		= "low";
	public static final String PRI_MED		= "medium";
	public static final String PRI_HIGH		= "high";
	public static final String [] PRI_ARRAY	= {PRI_HIGH, PRI_MED, PRI_LOW};

	// color code
	public static final String COLOR_HIGH	= "'#ee0000'";
	public static final String COLOR_MED	= "'#ff9900'";
	public static final String COLOR_LOW	= "'#00dd22'";

	public final static String	TYPE_ACTION		= "Action";
	public final static String	TYPE_DECISION	= "Decision";

	private final static String MAILFILE = "alert.htm";
	final static String HOST = Util.getPropKey("pst", "PRM_HOST");

    //Private attributes

	static Logger l = PrmLog.getLog();


    static actionManager manager;
	static PstFlowStepManager fsMgr;
	static userManager uMgr;
	static resultManager rMgr;

	static {
		try {
			manager = actionManager.getInstance();
			fsMgr = PstFlowStepManager.getInstance();
			uMgr = userManager.getInstance();
			rMgr = resultManager.getInstance();
		}
		catch (PmpException e) {
			l.error("action.java failed to initialize manager instances.");
		}
	}

    /**
     * Constructor for instantiating a new action.
     * @param member An OmsMember representing a action.
     */
    public action(OmsMember member)
    {
        super(member);
    }//End Constructor





    /**
     * Constructor for instantiating a new action.
     * @param userObj A PmpUesr.
     * @param org An organization.
     * @param memberName The name of the member.
     * @param password The password of the member.
     */
	action(PstUserAbstractObject userObj, OmsOrganization org, String memberName, String password)
		throws PmpException
	{
		super(userObj, org, memberName, password);
	}



    /**
     * Constructor for creating a action.  Used by actionManager.
     * @param userObj A PmpUser.
     * @param org The OmsOrganization for the action.
     */
    action(PstUserAbstractObject userObj, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException, PmpException
    {
		super(userObj, org, "");
		// don't create step here because I don't even know who are responsible for the action
		// check and perform create/delete of step when I commit update of the object or setStatus()
		//createStep(userObj);
    }//End Constructor

    /**
     * Constructor for creating a action.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the action.
     */
    action(OmsSession session, OmsOrganization org)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, "");
    }//End Constructor

    /**
     * Constructor for creating a action using a member name.
     * @param userObj A PmpUser.
     * @param org The OmsOrganization for the action.
     * @param actionMemName The member name for the created action.
     */
    action(PstUserAbstractObject userObj, OmsOrganization org, String actionMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(userObj, org, actionMemName, null);
    }//End Constructor

    /**
     * Constructor for creating a action using a member name.
     * @param session An OmsSession.
     * @param org The OmsOrganization for the action.
     * @param companyMemberName The member name for the created action.
     */
    action(OmsSession session, OmsOrganization org, String actionMemName)
        throws PmpObjectCreationException, PmpInternalException
    {
        super(session, org, actionMemName, null);
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

    }//End getAttribute


    protected void delete()
        throws PmpDeleteObjectException
    {
    	try {
        	// delete all of the steps first
    		PstGuest u = PstGuest.getInstance();
    		PstAbstractObject [] stepArr = getStep(u);
    		for (PstAbstractObject aStep : stepArr) {
    			fsMgr.delete(aStep);
    		}
    		
    		// delete all the blogs
    		int [] ids = rMgr.findId(u, "TaskID='" + getObjectId() + "'");
    		for (int i=0; i<ids.length; i++) {
    			PstAbstractObject o = rMgr.get(u, ids[i]);
    			rMgr.delete(o);
    			l.info("Deleted blog [" + ids[i] + "] for action [" + getObjectId() + "]");
    		}
    	}
    	catch (PmpException e) {
    		throw new PmpDeleteObjectException(e.getMessage());
    	}
        super.delete();
        l.info("Delete action [" + getObjectId() + "] done.");
    }//End delete
    
    /**
     * perform checking on associated steps to make sure that all people
     * responsible for the action have a step for him/her
     * @throws PmpException
     */
    private PstAbstractObject [] checkSteps()
    	throws PmpException
    {
        ArrayList<PstAbstractObject> finalStepList = new ArrayList<PstAbstractObject>();
		PstUserAbstractObject guest = PstGuest.getInstance();
        
        // Owner of the step is the requester; the responsible person is the CurrentExecutor
        // Assumption: Creator of the action object is already set
        // Note: the initial Creator of the action is the requester of the step

		// note: decision doesn't track Creator
        String requesterIdS = getStringAttribute("Creator");
        PstUserAbstractObject requester = null;
        try {requester = (PstUserAbstractObject) uMgr.get(guest, Integer.parseInt(requesterIdS));}
        catch (Exception e) {
        	l.info("Failed to checkSteps() because no requester [" + requesterIdS + "] found.");
        	return new PstAbstractObject [0];
        }
        
        String currentSt = getStringAttribute("Status");
        
        // get all the responsible persons including owner
		ArrayList<Object> responsible = getAllResponsible();

		// get all the steps currently existed
		PstAbstractObject [] originalStepArr = getStep(guest);
		finalStepList.addAll(Arrays.asList(originalStepArr));
		ArrayList<String> stepOwnerList = new ArrayList<String>();
		for (PstAbstractObject aStep : originalStepArr) {
			String stepOwner = aStep.getStringAttribute("CurrentExecutor");
			if (stepOwner != null) {
				stepOwnerList.add(stepOwner);
			}
		}

		// compare responsible persons with the stepOwnerStr to decide
		// adding or deleting steps for this action
		ArrayList<Object> cloneResponsible = (ArrayList<Object>) responsible.clone();
		for (Object uidS : cloneResponsible) {
			if (stepOwnerList.contains(uidS)) {
				// this responsible person has a step already
				stepOwnerList.remove(uidS);
				responsible.remove(uidS);
			}
		}
		
		// by now, the responsible list has people without step
		// the stepOwnerList has people that should not have a step
		// first, add the new steps
		if (currentSt==null ||
				(!currentSt.equals(CANCEL) && !currentSt.equals(DONE))) {
			for (Object uidS : responsible) {
				if (uidS == null) continue;
				// create a step for each person who has no step on this action yet
				// the requester is the person who initially created the action object
				PstFlowStep newStep = createStep(requester);
				newStep.setAttribute("CurrentExecutor", uidS);
				newStep.setAttribute("ProjectID", getStringAttribute("ProjectID"));
				newStep.setCurrentState(PstFlowStep.ST_STEP_ACTIVE);
				fsMgr.commit(newStep);
				finalStepList.add(newStep);
			}
		}
		
		// second, remove step from those who are no longer responsible for this action
		for (String uidS : stepOwnerList) {
			for (PstAbstractObject aStep: originalStepArr) {
				if (uidS.equals(aStep.getStringAttribute("CurrentExecutor"))) {
					fsMgr.delete(aStep);
					finalStepList.remove(aStep);
					l.info("Removed step for action [" + getObjectId() + "] : user [" + uidS + "]");
					break;
				}
			}
		}
		
    	l.info("Completed check action [" + getObjectId() + "] - total steps = " + finalStepList.size());
    	return (PstAbstractObject []) finalStepList.toArray(new PstAbstractObject[0]);
    }	// END: checkSteps()
    
    private void saveInternal(boolean bCheckSteps)
    	throws PmpCommitObjectException
	{
        super.save();
        if (bCheckSteps) {      
	    	try {
	    		checkSteps();
	    	}
	    	catch (PmpException e) {
	    		throw new PmpCommitObjectException(e.getMessage());
	    	}
        }
	}

    protected void save()
        throws PmpCommitObjectException
    {
    	// save and check action steps to make sure every responsible person has a step
    	saveInternal(true);
    }//End save

    public String getStatus() throws PmpException
    {
		return (String)getAttribute("Status")[0];
	}

	/**
	 * setStatus() is called to change status of the action item.
	 * It may in turn change the state of the corresponding action
	 * step according to the Status of the action item.  It will also
	 * send notification Email to relevant personnel when the item
	 * is first Open (created) and when it is Done or Canceled.
	 * The notification for being Late is sent by alert thread.
	 * @param u
	 * @param newStatus
	 */
	public void setStatus(PstUserAbstractObject u, String newStatus)
		 throws PmpException
	{
		// insanity check
		boolean bFound = false;
		for (int i=0; i<STATE_ARRAY.length; i++) {
			if (newStatus.equals(STATE_ARRAY[i])) {
				bFound = true;
				break;
			}
		}
		if (!bFound)
			throw new PmpException("setStatus() failed: found unknown action state [" + newStatus + "]");
		
		if (isDecision()) {
			setAttribute("Status", newStatus);	// for decision object
			saveInternal(false);
			return;	// nothing more to do for decision
		}
		
		String oldStatus = getStringAttribute("Status");
		
		PstAbstractObject [] stepArr = checkSteps();
    	if ((oldStatus==null || oldStatus.equals(OPEN)) && stepArr.length <= 0) {
    		// for DONE and CANCEL action, there is no step
    		l.info("No step found for this action [" + getObjectId() + "]");	// meeting step is not implemented yet
    	}

        // for each step that associated to this action
    	// change state
        for (PstAbstractObject step : stepArr) {
			String stepSt = (String)step.getAttribute(PstFlowStep.ATTR_STATE)[0];
			if (newStatus.equals(OPEN) || stepSt.equals(PstFlowStep.ST_STEP_NEW)) {
				// initialize action step object
				// everything on step is done in checkSteps()
				l.info("Initialized step [" + step.getObjectId() + "] for action [" + getObjectId() + "]");
			}
			
			// Note: for commit and abort, I must use the CurrentExecutor to
			// perform the commit/abort, or else I am unauthorized
			else if (stepSt.equals(PstFlowStep.ST_STEP_ACTIVE)) {
				PstUserAbstractObject executor = (PstUserAbstractObject)
							uMgr.get(u, Integer.parseInt(step.getStringAttribute("CurrentExecutor")));
				if (newStatus.equals(DONE)) {
					((PstFlowStep)step).commitStep(executor, null);
					setAttribute("CompleteDate", new Date());
					fsMgr.delete(step);		// go ahead and remove the step
					l.info("Action [" + getObjectId() + "] is Done.  Step ["
							+ step.getObjectId() + "] moved to commit.");
				}
				else if (newStatus.equals(CANCEL)) {
					((PstFlowStep)step).abortStep(executor, null);
					fsMgr.delete(step);		// go ahead and remove the step
					l.info("Action [" + getObjectId() + "] is Canceled.  Step ["
							+ step.getObjectId() + "] moved to abort.");
				}
			}
        }
        
        // for re-opening an action
        if (newStatus.equals(OPEN) && getExpireDate().before(Util.getToday())) {
        	newStatus = LATE;
        }

		setAttribute("Status", newStatus);	// for action object
		saveInternal(false);				// no need to checkStep again

		// send notification for Open, Done and Cancel
		if (oldStatus==null || !oldStatus.equals(newStatus)) {
			// there is a state transition: notify users
			notify(u, newStatus);
		}
	}


	public boolean isAction()
		throws PmpException
	{
		String type = getStringAttribute("Type");
		return (type!=null && type.equals(TYPE_ACTION));
	}


	public boolean isDecision()
		throws PmpException
	{
		String type = getStringAttribute("Type");
		return (type!=null && type.equals(TYPE_DECISION));
	}


	protected boolean refresh()
    {
        return super.refresh();
    }//End refresh

    public void deleteAction(PstUserAbstractObject u)
    	throws PmpException
    {
		// delete this action/decision (itself) and remove all its blogs and uploaded files

		// remove blog
		resultManager rMgr = resultManager.getInstance();
		result rObj = null;
		int [] ids = rMgr.findId(u, "TaskID='" + getObjectId() + "'");
		//for (int i=0; i<ids.length; i++)
		//	rMgr.delete(rMgr.get(u, ids[i]));

		for (int i=0; i<ids.length; i++) // @SWS092806
		{
			// delete all comments associated to this blog
			int [] ids1 = rMgr.findId(u, "ParentID='" + ids[i] + "'");
			for (int j=0; j<ids1.length; j++)
			{
				rMgr.delete(rMgr.get(u, ids1[j])); // delete the comments to the blog
			}
			//rMgr.delete(rMgr.get(u, ids[i]));
			rObj = (result) rMgr.get(u, ids[i]); // @SWS092806 delete the parent blog
			rObj.deleteResult(u);
		}

		// remove all files here
		String repository = Util.getPropKey("pst", "FILE_UPLOAD_PATH");
		String pathName = repository + File.separator + getObjectId();
		File f = new File(pathName);
		File [] fList = f.listFiles();
		if (fList != null)
		{
			for (int i=0; i<fList.length; i++)
				fList[i].delete();
		}
		f.delete();		// delete the directory

		// delete myself
		manager.delete(this);
	}

	/**
	 */
	public static String showAddActionPanel(PstUserAbstractObject pstuser, String type,
		int selectedPjId, String projIdS,
		int [] projectObjId, PstAbstractObject [] projectObjList,
		String newDescription,
		String newPriority,
		String newExpire,
		String coordinatorIdS,
		String status,
		String locale,
		Object [] responsibleIds,
		boolean isActionOnly,
		boolean isShowButton		// for update action, do not show button here
		)
	throws PmpException
	{
		StringBuffer sBuf = new StringBuffer(8192);
		SimpleDateFormat df3 = new SimpleDateFormat ("MM/dd/yyyy");
		PstAbstractObject [] projMember;
		int [] bugIds;

		boolean isCW = Prm.isCtModule();
		int myUid = pstuser.getObjectId();

		// only coordinator can update State
		int coordinatorId;
		if (coordinatorIdS == null)
			coordinatorId = myUid;
		else
			coordinatorId = Integer.parseInt(coordinatorIdS);
		String userEdit = (coordinatorId == myUid)?"":"disabled";

		bugManager bMgr = bugManager.getInstance();

		if (selectedPjId <= 0)
		{
			String expr = "Company='" + (String)pstuser.getAttribute("Company")[0] + "'";
			int [] ids = uMgr.findId(pstuser, expr);
			projMember = uMgr.get(pstuser, ids);
			bugIds = bMgr.findId(pstuser, expr);
		}
		else
		{
			projMember = ((user)pstuser).getTeamMembers(selectedPjId);
			bugIds = bMgr.findId(pstuser, "ProjectID='" + selectedPjId + "'");
		}

		if (projectObjId == null) {
			projectManager pjMgr = projectManager.getInstance();
			projectObjId = pjMgr.getProjects(pstuser, false);
			if (projectObjId.length > 0) {
				projectObjList = pjMgr.get(pstuser, projectObjId);
				Util.sortName(projectObjList, true);
			}
		}

		if (projIdS == null)
			projIdS = String.valueOf(selectedPjId);

		if (newPriority == null)
			newPriority = bug.PRI_MED;

		sBuf.append("<table width='100%' border='0' cellspacing='0' cellpadding='0'>");

		sBuf.append("<form name='addActionForm' action='../meeting/post_mtg_upd2.jsp' method='post' enctype='multipart/form-data'>");
		sBuf.append("<input type='hidden' name='projIdSub' value='" + projIdS + "'>");
		sBuf.append("<input type='hidden' name='pid'>");	// used in changeProject()
		sBuf.append("<input type='hidden' name='type'>");	// used in changeProject()

		String desc = "";
		if (newDescription!=null && newDescription.length()>0)
			desc = newDescription;

		if (responsibleIds == null)
			responsibleIds = new Object[0];

		String acExpireS = df3.format(new Date().getTime() + 604800000);	// give it one week by default
		if (newExpire!=null && newExpire.length()>0)
			acExpireS = newExpire;

		// type: action or decision
		if (!isActionOnly) {
			sBuf.append("<tr><td>&nbsp;</td>");
			sBuf.append("<td width='150' class='plaintext'><b></b></td>");	// no label
			sBuf.append("<td class='plaintext'>");
			sBuf.append("<input type='radio' name='Type' value='" 
					+ action.TYPE_ACTION
					+ "' onClick='isAction();' ");
			if (type.equals(action.TYPE_ACTION))
				sBuf.append("checked");
			sBuf.append("> ");
			sBuf.append(StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, action.TYPE_ACTION));
			sBuf.append("<input type='radio' name='Type' value='"
					+ action.TYPE_DECISION
					+ "' onClick='isDecision();' ");
			if (type.equals(action.TYPE_DECISION))
				sBuf.append("checked");
			sBuf.append("> ");
			sBuf.append(StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, action.TYPE_DECISION));
			if (isCW) {
				sBuf.append("<input type='radio' name='Type' value='Issue' onClick='isIssue();' ");
				if (type.equals("Issue"))
					sBuf.append("checked");
				sBuf.append("> ");
				sBuf.append(StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Issue"));
			}
			sBuf.append("</td></tr>");
		}
		else {
			// calling from worktray.jsp
			sBuf.append("<input type='hidden' name='Type' value='" + TYPE_ACTION + "'>");
			sBuf.append("<input type='hidden' name='Caller' value='worktray'>");
		}
		
		// Description
		sBuf.append("<tr><td width='25'><img src='../i/spacer.gif' width='25' height='1'></td>");
		sBuf.append("<td class='plaintext' valign='top' width='150'><b>");
		sBuf.append(StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "New Item"));
		sBuf.append(":</b></td>");
		sBuf.append("<td><table border='0' cellpadding='0' cellspacing='0'>");
		sBuf.append("<tr><td>&nbsp;");
		sBuf.append("<textarea input id='Description' type='text' name='Description' ");
		sBuf.append("style='width:700px;' rows='4' onkeyup='return onEnterSubmitAC(event);'>");
		sBuf.append(desc + "</textarea></td>");
		sBuf.append("<td valign='top'><img src='../i/spacer.gif' width='10'/>");
		sBuf.append("<input type='Submit' class='button_medium' name='Submit' onClick='return validation();' value='  Save  '>");
		sBuf.append("</td></tr>");
		
		sBuf.append("<tr><td class='plaintext' align='right' style='color: green'>chars remaining: <span id='charCount' style='color:green;'>255</span></td>");
		sBuf.append("<td></td></tr></table>");

		// Initialize the chars remaining number
		sBuf.append("<script type='text/javascript'>");
		sBuf.append("charRemain('Description', 'charCount');");
		sBuf.append("</script>");
		sBuf.append("</td></tr>");

		// status
		if (status != null) {
			// only use for update action
			sBuf.append("<tr><td>&nbsp;</td>");
			sBuf.append("<td class='plaintext' valign='top'><b>Status:</b></td>");
			sBuf.append("<td><table border='0' cellpadding='0' cellspacing='0'><tr>");
			sBuf.append("<td width='100' class='plaintext'><input type='radio' name='Status' value='");
			sBuf.append(action.OPEN + "'");
			if (status.equals(action.LATE))
				sBuf.append(" disabled ");		// always disabled
			else if (status.equals(action.OPEN))
				sBuf.append(" checked ");
			sBuf.append(userEdit + ">" + action.OPEN);

			sBuf.append("</td><td width='100' class='plaintext'>");
			sBuf.append("<input type='radio' name='Status' value='' disabled ");
			if (status.equals(action.LATE))
				sBuf.append(" checked ");
			sBuf.append(userEdit + ">" + action.LATE);

			sBuf.append("</td><td width='100' class='plaintext'><input type='radio' name='Status' value='");
			sBuf.append(action.DONE + "'");
			if (status.equals(action.DONE))
				sBuf.append(" checked ");
			sBuf.append(userEdit + ">" + action.DONE);

			sBuf.append("</td><td width='100' class='plaintext'><input type='radio' name='Status' value='");
			sBuf.append(action.CANCEL + "'");
			if (status.equals(action.CANCEL))
				sBuf.append(" checked ");
			sBuf.append(userEdit + ">" + action.CANCEL);

			sBuf.append("</td></tr></table>");
			sBuf.append("</td></tr>");
			
			sBuf.append("<tr><td colspan='3'><img src='../i/spacer.gif' height='5'></td></tr>");
		}
		
		// Done By
		sBuf.append("<tr><td width='25'><img src='../i/spacer.gif' width='25' height='1'></td>");
		sBuf.append("<td class='plaintext' width='150'><b>");
		sBuf.append(StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Due date"));
		sBuf.append(":</b></td>");
		sBuf.append("<td><input class='formtext' type='Text' name='Expire' style='width:240px;' onClick=\"javascript:show_calendar('addActionForm.Expire');\" ");
		sBuf.append("onKeyDown='return false;' value='" + acExpireS + "'>");
		sBuf.append("&nbsp;<a href='javascript:popup_cal();'><img src='../i/calendar.gif' border='0' align='absmiddle' alt='Click to view calendar.'></a>");
		sBuf.append("</td></tr>");


		////////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////
		// panel for more action info
		sBuf.append("<tr><td colspan='3'>");
		sBuf.append(Util.getHeaderPartitionLine());
		sBuf.append("<img id='ImgInfoPanel' src='../i/bullet_tri.gif'/>");
		sBuf.append("<a id='AInfoPanel' href='javascript:togglePanel(\"InfoPanel\", \"More action info\", \"Hide action info\");' class='listlinkbold'>More action info</a>");
		
		sBuf.append("<DIV id='DivInfoPanel' style='display:none;'>");
		sBuf.append("<table border='0' cellspacing='0' cellpadding='0' width='100%'>");	// Info panel table

		sBuf.append("<tr><td colspan='3'><img src='../i/spacer.gif' height='10'></td></tr>");

		// priority
		sBuf.append("<tr><td width='25'><img src='../i/spacer.gif' width='25' height='1'></td>");
		sBuf.append("<td class='plaintext' width='150'><b>Priority:</b></td>");		
		sBuf.append("<td><select class='formtext' name='Priority' style='width:120px;'>");
		sBuf.append("<option value='" + action.PRI_HIGH + "' ");
		if (newPriority.equals(action.PRI_HIGH))
			sBuf.append("selected");
		sBuf.append(">" + action.PRI_HIGH + "</option>");
		sBuf.append("<option value='" + action.PRI_MED + "' ");
		if (newPriority.equals(action.PRI_MED))
			sBuf.append("selected");
		sBuf.append(">" + action.PRI_MED + "</option>");
		sBuf.append("<option value='" + action.PRI_LOW + "' ");
		if (newPriority.equals(action.PRI_LOW))
			sBuf.append("selected");
		sBuf.append(">" + action.PRI_LOW + "</option>");
		sBuf.append("</select></td></tr>");

		sBuf.append("<tr><td colspan='3'><img src='../i/spacer.gif' height='10'></td></tr>");

		// LINK to project name & Issue/Bug
		sBuf.append("<tr><td>&nbsp;</td>");
		sBuf.append("<td colspan='2'><table border='0' cellpadding='0' cellspacing='0'><tr>");

		// project name
		sBuf.append("<td class='plaintext' width='150'><b>Project Name:</b></td>");
		sBuf.append("<td class='plaintext' width='400' align='left'>");

		sBuf.append("<select class='formtext' name='projId' onChange='changeProject();' style='width:240px;'>");
		sBuf.append("<option value=''>- select project name -</option>");

		if (projectObjList!=null && projectObjList.length > 0)
		{
			project pj;
			String pName;
			int id;

			for (int i=0; i < projectObjList.length ; i++)
			{
				// project
				pj = (project) projectObjList[i];
				pName = pj.getDisplayName();
				id = pj.getObjectId();

				sBuf.append("<option value='" + id +"' ");
				if (id == selectedPjId)
					sBuf.append("selected");
				sBuf.append(">&nbsp;" + pName + "</option>");
			}
		}
		sBuf.append("</select></td>");

		// related issue/bug
		if (isCW) {
			sBuf.append("<td class='plaintext' width='80'><b>Issue / PR:</b>&nbsp;</td>");
			sBuf.append("<td><select class='formtext' name='BugId'>");
			sBuf.append("<option value=''>- select issue/PR ID -</option>");
			for (int i=0; i<bugIds.length; i++)
			{
				sBuf.append("<option value='" + bugIds[i] + "'>" + bugIds[i] + "</option>");
			}
	
			sBuf.append("</select></td>");
		}
		sBuf.append("</tr></table></td></tr>");

		sBuf.append("<tr><td colspan='3'><img src='../i/spacer.gif' height='10'></td></tr>");

		// Coordinator
		String name;
		sBuf.append("<tr><td>&nbsp;</td>");
		sBuf.append("<td class='plaintext'><b>Coordinator:</b></td>");
		sBuf.append("<td><select class='formtext' type='text' name='Owner' style='width:240px;' ");
		sBuf.append(userEdit + " >");

		for (int i=0; i<projMember.length; i++)
		{
			if (projMember[i] == null) continue;
			int id = projMember[i].getObjectId();
			name = ((user)projMember[i]).getFullName();
			sBuf.append("<option value='" + id + "'");
			if (id==coordinatorId)
				sBuf.append(" selected");
			sBuf.append(">&nbsp;" +name+ "</option>");
		}
		sBuf.append("</select></td></tr>");

		sBuf.append("<tr><td colspan='3'><img src='../i/spacer.gif' height='5'></td></tr>");

		// Responsible
		sBuf.append("<tr><td>&nbsp;</td>");
		sBuf.append("<td valign='top' class='plaintext'><b>Responsible:</b></td><td>");

		// projMember will be on the left while alertEmp will be on the right
		String [] uName = new String [responsibleIds.length];
		if (responsibleIds.length>0 && responsibleIds[0]!=null)
		for (int i = 0; i < responsibleIds.length; i++)
		{
			int id = Integer.parseInt((String)responsibleIds[i]);
			for (int j = 0; j < projMember.length; j++)
			{
				if (projMember[j] == null) continue;
				if (projMember[j].getObjectId() == id)
				{
					uName[i] = ((user)projMember[j]).getFullName();
					projMember[j] = null;
					break;
				}
			}
		}

		sBuf.append("<table border='0' cellspacing='0' cellpadding='0'>");
		sBuf.append("<tr><td class='formtext'>");
		sBuf.append("<select class='formtext_fix' name='Selected' multiple size='5' "
				+ userEdit + ">");

		if (projMember != null && projMember.length > 0)
		{
			for (int i=0; i < projMember.length; i++)
			{
				if (projMember[i] == null) continue;
				name = ((user)projMember[i]).getFullName();
				sBuf.append("<option value='" +projMember[i].getObjectId()+ "'>&nbsp;" +name+ "</option>");
			}
		}

		sBuf.append("</select></td>");

		sBuf.append("<td>&nbsp;&nbsp;&nbsp;</td>");
		sBuf.append("<td align='center' valign='middle'>");
		sBuf.append("<input type='button' class='button' name='add' value='&nbsp;&nbsp;&nbsp;&nbsp;Add &gt;&gt;&nbsp;&nbsp;' onClick='swapdata(this.form.Selected,this.form.Responsible)'>");
		sBuf.append("<br><input type='button' class='button' name='remove' value='<< Remove' onClick='swapdata(this.form.Responsible,this.form.Selected)'>");
		sBuf.append("</td><td>&nbsp;&nbsp;&nbsp;</td>");

		// people selected
		sBuf.append("<td class='formtext'>");
		sBuf.append("<select class='formtext_fix' name='Responsible' multiple size='5' "
				+ userEdit + ">");

		if (responsibleIds.length>0 && responsibleIds[0]!=null)
		{
			for (int i=0; i < responsibleIds.length; i++)
			{
				sBuf.append("<option value='" +responsibleIds[i]+ "'>&nbsp;" + uName[i] + "</option>");
			}
		}

		sBuf.append("</select></td></tr></table></td></tr>");
		// End of Responsible

		sBuf.append("<tr><td colspan='3'><img src='../i/spacer.gif' height='10'></td></tr>");

		// Enter comment
		sBuf.append("<tr><td>&nbsp;</td>");
		sBuf.append("<td class='plaintext' valign='top'><b>Blog comment:</b></td>");
		sBuf.append("<td><textarea name='Comment' style='width:700px;' rows='5'></textarea>");
		sBuf.append("</tr>");

		// display buttons
		if (isShowButton) {
			sBuf.append("<tr><td colspan='3'><img src='../i/spacer.gif' height='10'></td></tr>");
			sBuf.append("<tr><td colspan='3' align='center'>");
			sBuf.append("<input type='Submit' class='button_medium' name='Submit' onClick='return validation();' value='  Save  '>");
			sBuf.append("<input type='Button' class='button_medium' value='  Reset  ' onclick='resetAC();'>&nbsp;");
			sBuf.append("</td></tr>");
			sBuf.append("</form>");
		}
		
		/////////////////////////////////////////
		// close more action info panel
		sBuf.append("</table></DIV>");	// END Info panel table
		sBuf.append("</td></tr>");

		sBuf.append("</td></tr></table>");

		return sBuf.toString();
	}

	
	/**
	 * Display an <img> tag for the color dot that represent the action status
	 * @return return a self-contained <img> tag.  Caller should put it in a <td> of some sort.
	 */
	public String getStatusDisplay(PstUserAbstractObject u)
		throws PmpException
	{
		SimpleDateFormat df1 = new SimpleDateFormat ("MM/dd/yy");
		String status = getStringAttribute("Status");
		if (status==null) return null;
		
		Date completeDt = getCompleteDate();
		String dot = HOST + "/i/";
		StringBuffer sBuf = new StringBuffer(64);
		
		if (status.equals(action.OPEN)) {dot += "dot_lightblue.gif";}
		else if (status.equals(action.LATE)) {dot += "dot_red.gif";}
		else if (status.equals(action.DONE)) {
			dot += "dot_green.gif";
			if (completeDt!=null) status+= " " + df1.format(completeDt);
		}
		else if (status.equals(action.CANCEL)) {dot += "dot_cancel.gif";}
		else {dot += "dot_grey.gif";}

		sBuf.append("<img src='" + dot + "' title='" + status + "'>");
		return sBuf.toString();
	}
	
	/**
	 * Display an <img> tag for the color dot that represent the action priority
	 * @return return a self-contained <img> tag.  Caller should put it in a <td> of some sort.
	 */
	public String getPriorityDisplay(PstUserAbstractObject u)
		throws PmpException
	{
		String pri = getStringAttribute("Priority");
		if (pri==null) return null;
		
		String dot = HOST + "/i/";
		StringBuffer sBuf = new StringBuffer(64);
		
		if (pri.equals(action.PRI_HIGH)) {dot += "dot_red.gif";}
		else if (pri.equals(action.PRI_MED)) {dot += "dot_orange.gif";}
		else if (pri.equals(action.PRI_LOW)) {dot += "dot_yellow.gif";}
		else {dot += "dot_grey.gif";}

		sBuf.append("<img src='" + dot + "' title='" + pri + "'>");
		return sBuf.toString();
	}

	///////////////////////////////////////////////////////////////////////
	// Workflow

	/**
	 * Create a step to track this action item for this user.
	 * This API should only be called internally by the action class
	 * after it saves its updates of attributes.  Caller should make sure
	 * that a step does not exist for this action and for this user.
	 * @param u login user.
	 * @return the task step corresponding to this task.
	 * @throws PmpException
	 */
	public PstFlowStep createStep(PstUserAbstractObject u)
		throws PmpException
	{
		// create the step object and put it in NEW state	
		 PstFlowStep step = (PstFlowStep)fsMgr.create(u, null, null, null, null, PstFlowStep.TYPE_ACTION);
		 // the above call only sets up the Owner, not the CurrentExecutor

		// all other action related info in the step will be set at setStatus()
		step.setAttribute("TaskID", String.valueOf(getObjectId()));		// the action ID
		fsMgr.commit(step);
		l.info("Created a step for action [" + getObjectId() + "] : requester [" + u.getObjectId() + "]");
 
		return step;
	}

	/**
	 * get the step corresponding to this action if it exists.
	 * @param u login user.
	 * @return the action step if it exists, else return null.
	 * @throws PmpException
	 */
	private PstAbstractObject [] getStep(PstUserAbstractObject u)
		throws PmpException
	{
		PstAbstractObject [] stepArr = new PstAbstractObject[0];
		int [] ids = fsMgr.findId(u, "TaskID='" + getObjectId() + "'");
		if (ids.length > 0) {
			stepArr = fsMgr.get(u, ids);
		}
		return stepArr;
	}

	/**
	 * send notification to team when the action item change state.
	 * Note that when PRM moves the action to late, the notification
	 * is sent by the system separately in PrmAlert class.
	 * @param u
	 * @param status
	 * @throws PmpException
	 */
	private void notify(PstUserAbstractObject u, String status)
		throws PmpException
	{
		// send notification on Open, Done and Cancel
		boolean bSend = false;
		Object [] toArr = null;
		String from = null;
		String statusStr = null;
		int myUid = u.getObjectId();
		String subj = "[" + Prm.getAppTitle() + "] ";
		String person = "";

		projectManager pjMgr = projectManager.getInstance();
		meetingManager mtgMgr = meetingManager.getInstance();

		PstAbstractObject o;
		String requestorIdS = (String)getAttribute("Creator")[0];
		String requestorEmail = null;
		try {
			o = uMgr.get(u, Integer.parseInt(requestorIdS));
			requestorEmail = (String)o.getAttribute("Email")[0];
		}
		catch (Exception e) {requestorEmail = Prm.getFromEmail();}

		String ownerIdS = (String)getAttribute("Owner")[0];
		int ownerId = Integer.parseInt(ownerIdS);
		o = uMgr.get(u, ownerId);
		String ownerEmail = (String)o.getAttribute("Email")[0];
		
		// email to all responsible persons
		boolean bIncludeOwner = (myUid != ownerId);	// if I am the one who causes the change of state, do not notify me
		ArrayList<Object> recipients = getAllResponsible(bIncludeOwner);
		if (recipients.size() <= 0) {
			return;
		}

		if (status.equals(OPEN)
				|| status.equals(LATE)) {	// late is possible for re-open
			// from requester to owner
			bSend = true;
			subj += "new work request [" + getObjectId() + "]";
			statusStr = "Opened";
			from = requestorEmail;
			toArr = recipients.toArray();
		}
		else if (status.equals(DONE)) {
			// from owner to requester and to responsible persons
			bSend = true;
			subj += "action item " + getObjectId() + " is DONE";
			statusStr = "Done";
			from = ownerEmail;
			if (!recipients.contains(requestorIdS))
				recipients.add(requestorIdS);
			toArr = recipients.toArray();
			person = " by " + ((user)u).getFullName() + " ";
		}
		else if (status.equals(CANCEL)) {
			// from this user to requester, owner and responsible
			bSend = true;
			subj += "action item " + getObjectId() + " is Canceled";
			statusStr = "Canceled";
			from = (String)u.getAttribute("Email")[0];
			if (!recipients.contains(requestorIdS))
				recipients.add(requestorIdS);
			toArr = recipients.toArray();
			person = " by " + ((user)u).getFullName() + " ";
		}

		if (!bSend)
			return;

		// send email notification
		String msg = "The following Action Item is <b>" + statusStr + "</b>" + person + "<blockquote>";
		String mid = (String)getAttribute("MeetingID")[0];
		String pjIdS = (String)getAttribute("ProjectID")[0];
		String pjName = null;
		int aid = getObjectId();

		msg += "<a href='" + HOST;
		if (mid != null)
		{
			msg += "/meeting/mtg_view.jsp?mid=" + mid + "&aid=" + aid + "#action'>";
			o = mtgMgr.get(u, mid);
			if (pjIdS != null)
				pjName = ((project)pjMgr.get(u, Integer.parseInt(pjIdS))).getDisplayName();
		}
		else
		{
			if (pjIdS == null) pjIdS = "0";		// all projects
			msg += "/project/proj_action.jsp?projId=" + pjIdS + "&aid=" + aid + "'>";
			if (pjIdS != null) {
				o = pjMgr.get(u, Integer.parseInt(pjIdS));	// if mid==null, there must be a pjIdS
				pjName = ((project)o).getDisplayName();
			}
		}
		msg += (String)getAttribute("Subject")[0] + "</a>";
		if (pjName != null)
			msg += "<br>(Project: <a href='" + HOST + "/project/proj_top.jsp?projId="
				+ pjIdS + "'>" + pjName + "</a>)";
		msg += "</blockquote>";
		
		// also show no. of blogs
		String s;
		int [] ids = rMgr.findId(u, "TaskID='" + aid + "'");
		if (ids.length <= 1) s = " blog";
		else s = " blogs";
		msg += "<br/><br/>";
		msg += "There are a total of " + ids.length + s + " on this action item.";
		
		/* ECC: we use an proj_action.jsp to process action item now.  Don't use worktray.
		if (status.equals(OPEN)) {
			String link = HOST + "/box/worktray.jsp";
			if (pjIdS != null)
				link += "?projId=" + pjIdS;
			msg += "Please click the link below to access your worktray for processing:"
			+ "<p>"
			+ "<a href='" + link + "'>" + link + "</a>"
			+ "<br>";
		}
		*/

		if (!Util.sendMailAsyn(u, from, toArr, null, null, subj, msg, MAILFILE)) {
			l.error("Error sending notification message in action.notify().");
		}
	}


	/**
	 * return the responsible personnel including owner
	 * @return Object ArrayList
	 */
	public ArrayList<Object> getAllResponsible()
	{
		return getAllResponsible(true);
	}
	
	public ArrayList<Object> getAllResponsible(boolean bIncludeOwner)
	{
		ArrayList<Object> recipients = new ArrayList<Object>();
		try {
			Object [] respA = getAttribute("Responsible");
			if (respA!=null && respA[0]!=null)
				recipients.addAll(Arrays.asList(respA));
			if (bIncludeOwner) {
				String ownerIdS = getStringAttribute("Owner");
				if (ownerIdS!=null && !recipients.contains(ownerIdS)) {
					recipients.add(ownerIdS);
				}
			}
		}
		catch (PmpException e) {
			l.error("Error in action.getAllResponsible()");
			e.printStackTrace();
		}
		return recipients;
	}


	public String getResponsibleStr(PstUserAbstractObject u)
	{
		StringBuffer sBuf = new StringBuffer(512);
		ArrayList<Object> uidList = this.getAllResponsible();
		String ownerIdS = "";
		user uObj;
		String uidS;
		int ownerId=0, uid;
		try {
			ownerIdS = (String) this.getStringAttribute("Owner");
			ownerId = Integer.parseInt(ownerIdS);
			uObj = (user) uMgr.get(u, ownerId);
			sBuf.append(uObj.getFullName() + "*");			// coordinator
		}
		catch (PmpException e) {}
		
		for (int i=0; i<uidList.size(); i++) {
			uidS = (String) uidList.get(i);
			uid = Integer.parseInt(uidS);
			if (uid == ownerId) continue;		// skip duplicate coordinator
			try {uObj = (user) uMgr.get(u, uid);}
			catch (PmpException e) {continue;}
			if (sBuf.length() > 0) sBuf.append(", ");
			sBuf.append(uObj.getFullName());
		}
		return sBuf.toString();
	}


}//End class action
