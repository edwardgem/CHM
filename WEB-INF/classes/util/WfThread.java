////////////////////////////////////////////////////
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	WfThread.java
//	Author:	ECC
//	Date:	06/28/05
//	Description:
//		Run parallel (thread) operations for Project Plan Change Workflow.
//		This is the workflow application for plan change.
//
//	Modification:
//			@ECC050406	Allow Admin to update plan and auto approve the process
//			@ECC071806	Allow Program Manager role to update plan and auto approve the process
//
////////////////////////////////////////////////////////////////////

package util;

import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Hashtable;
import java.util.List;
import java.util.Vector;

import oct.codegen.plan;
import oct.codegen.planManager;
import oct.codegen.planTask;
import oct.codegen.planTaskManager;
import oct.codegen.project;
import oct.codegen.projectManager;
import oct.codegen.task;
import oct.codegen.user;
import oct.pep.PepCommentVector;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstFlow;
import oct.pst.PstFlowDataObject;
import oct.pst.PstFlowDataObjectManager;
import oct.pst.PstFlowManager;
import oct.pst.PstFlowStep;
import oct.pst.PstFlowStepManager;
import oct.pst.PstUserAbstractObject;

import org.apache.log4j.Logger;


public class WfThread extends Thread
{
	public final static int WF_OP_INIT_PLAN_APPROVAL	= 101;
	public final static int WF_OP_LEADER_VERIFY_PLAN	= 102;

	private static Logger l = PrmLog.getLog();

	private static PstFlowManager fMgr = null;
	private static PstFlowStepManager fsMgr = null;
	private static PstFlowDataObjectManager fdataMgr = null;
	private static planManager planMgr = null;
	private static planTaskManager ptMgr = null;
	private static projectManager pjMgr = null;

	private static final SimpleDateFormat df = new SimpleDateFormat("MMM dd, yyyy");

	private int			m_op;
	private String		m_projIdS;
	private String		m_memName;
	//private String		m_planName;
	private String		m_stepName;
	private String		m_status;
	private String []	m_desc;
	private String []	m_version;
	private PstUserAbstractObject	m_pstuser;
	private boolean		m_bAutoApprove;

	private Object		m_obj1;					// other parameter
	private Object		m_rc1;					// return object
	private Exception	m_exception;			// in case it throws exception

	public Object 		getRC1() {return m_rc1;}
	public Exception	getException() {return m_exception;}


    static {
		try {
			fMgr = PstFlowManager.getInstance();
			fsMgr = PstFlowStepManager.getInstance();
			fdataMgr = PstFlowDataObjectManager.getInstance();
			planMgr = planManager.getInstance();
			ptMgr = planTaskManager.getInstance();
			pjMgr = projectManager.getInstance();
		}
		catch (PmpException e)
		{l.error("WfThread failed to init.");}
	}

	// init basic
	public WfThread()
		throws PmpException
	{
	}

	// init for WF_OP_INIT_PLAN_APPROVAL
	public WfThread(PstUserAbstractObject pstuser,
			int op, Object planObj,
			String projId, String originalPlanName,
		String [] description, String [] Version)
		throws PmpException
	{
		m_pstuser = pstuser;
		m_op = op;
		m_obj1 = planObj;
		m_projIdS = projId;
		//m_planName = originalPlanName;
		m_desc = description;
		m_version = Version;

		// @ECC050406
		//user u = (user)userManager.getInstance().get(pstuser, pstuser.getObjectId());
		int iRole = Util.getRoles(pstuser);
		if ( (iRole & (user.iROLE_ADMIN | user.iROLE_PROGMGR)) > 0 )	// @ECC071806
			m_bAutoApprove = true;
		else
			m_bAutoApprove = false;
	}

	// init for WF_OP_LEADER_VERIFY_PLAN
	public WfThread(PstUserAbstractObject pstuser,
			int op, String memname, String stepName,
			String status, String [] description)
		throws PmpException
	{
		m_pstuser = pstuser;
		m_op = op;
		m_memName = memname;
		m_stepName = stepName;
		m_status = status;
		m_desc = description;
	}

	public void run()
	{
		System.out.println("*** WfThread started");
		setPriority(Thread.MAX_PRIORITY);

		plan planObj;
		PstFlow flowObj;
		PstFlowStep stepObj, nextstepObj;

		try
		{
			switch (m_op)
			{
				//////////////////////////////////////////////////////////////////
				// only 2 cases for Change Plan workflow application
				case WF_OP_INIT_PLAN_APPROVAL:

					System.out.println("--- WF_OP_INIT_PLAN_APPROVAL");
					project projObj = (project)pjMgr.get(m_pstuser, Integer.parseInt(m_projIdS));
					String projOwner = (String)projObj.getAttribute("Owner")[0];

					// Create the plan
					planObj = (plan)planMgr.create(m_pstuser);
					if(m_desc != null && m_desc[0] != null && m_desc[0].length() > 0)
					{
						PepCommentVector commentVector = new PepCommentVector();
						commentVector.addComment(df.format(new Date()), m_pstuser.getObjectName(), (String)m_desc[0]);
						planObj.setAttribute("Description", commentVector.getBytes());
					}
					if(m_version != null && m_version[0] != null && m_version[0].length() > 0)
						planObj.setAttribute("Version", (String)m_version[0]);
					planObj.setAttribute("CreatedDate", new Date());
					planObj.setAttribute("Creator", String.valueOf(m_pstuser.getObjectId()));
					planObj.setAttribute("Status", "Proposed");
					planObj.setAttribute("ProjectID", m_projIdS);
					planMgr.commit(planObj);

					// Get plan task
					Vector rPlan = (Vector)m_obj1;

					String[] parentIDArray = new String[10];
					String lastObjectID = "0";
					String status;
					int lastLevel = 0;
					int nextPreorder = 0;
					parentIDArray[lastLevel] = lastObjectID;

					for(int i = 0; i < rPlan.size(); i++)
					{
						Hashtable rTask = (Hashtable)rPlan.elementAt(i);
						status = (String)rTask.get("Status");
						if (status.equals(task.DEPRECATED)) {
							continue;
						}

						planTask newPlanTask = (planTask)ptMgr.create(m_pstuser);

						Integer[] pPreOrder = new Integer[1];
						pPreOrder[0] = new Integer(nextPreorder++);

						Object [] levelArr = (Object [])rTask.get("Level");
						int level = ((Integer)levelArr[0]).intValue();


						if (lastLevel > level) {
							lastLevel = level;
						}
						else if (lastLevel < level) {
							for (int k = lastLevel + 1 ; k < level + 1; k++) {
								parentIDArray[k] = lastObjectID;
							}
						}

						newPlanTask.setAttribute("ParentID",parentIDArray[level]);
						newPlanTask.setAttribute("PlanID", planObj.getObjectName());
						newPlanTask.setAttribute("PreOrder", pPreOrder);
						newPlanTask.setAttribute("Level", (Object [])rTask.get("Level"));
						newPlanTask.setAttribute("Order", (Object [])rTask.get("Order"));
						newPlanTask.setAttribute("Status", rTask.get("Status"));
						newPlanTask.setAttribute("Name", rTask.get("Name"));
						newPlanTask.setAttribute("TaskID", rTask.get("TaskID"));

						if (newPlanTask.getAttribute("Status")[0].equals(task.ST_NEW))
						{
							// new task: pass startGap and length
							newPlanTask.setAttribute("int1", rTask.get("StartGap"));
							newPlanTask.setAttribute("int2", rTask.get("Length"));
						}

						ptMgr.commit(newPlanTask);

						lastLevel = level;
						lastObjectID = newPlanTask.getObjectName();
					}

					//////////////////////////////////////////////////////////////////////////////
					// Workflow code
					
					// STEP 1: set up flow data, specific to the application (e.g. plan change app)
					String flowDOName = planObj.getObjectName();	// this is the new proj plan unique name
					PstFlowDataObject flowDataObj = (PstFlowDataObject)fdataMgr.create(m_pstuser, flowDOName, "PlanApproval");
					flowDataObj.setAttribute("string1", planMgr.getOrgname());	// "plan"
					flowDataObj.setAttribute("string2", flowDOName);
					
					// assignto=$direct:int1.om_acctname;
					if (m_bAutoApprove)	//@ECC050406
						flowDataObj.setAttribute("int1", new Integer(m_pstuser.getObjectId()));
					else
						flowDataObj.setAttribute("int1", new Integer(projOwner));	// have the proj owner do the review

					// STEP 2: create (instantiate) the flow object
					// create flow instance from our specific flow definition "PlanApproval"
					// this would create the flow instance and the first step
					PstFlow currentFlow = (PstFlow)fMgr.create(m_pstuser, "PlanApproval",
								flowDataObj, PstFlow.TYPE_WORKFLOW);
System.out.println("!!! WfThread: currentFlow="+currentFlow.getObjectId());

					String strAry[] = new String[1];
					strAry[0] = new String(flowDOName);		// this is the proj plan object name
					currentFlow.setAttribute(PstFlow.CONTEXT_OBJECT, strAry);	// flow's context is the plan name
					currentFlow.setAttribute(PstFlow.CONTEXT_OBJECT_ORG, planMgr.getOrgname());

					// OK to hardwire the flow definition name because it is this application
					// that we are working on
					currentFlow.setAttribute(PstFlow.ATTR_FLOWDEF_NAME, "PlanApproval");	// ECC: redundant
					fMgr.commit(currentFlow);			// save (the flow instance is created in DB)

					/////////// Return RC
					m_rc1 = new Integer(currentFlow.getObjectId());	// return the current flow id


					// STEP 3: set up step(s) for processing
					// Look for the first step and add Signature into it
					Object [] tempList = currentFlow.getAttribute(PstFlow.CURRENT_ACTIVE_STEP);
System.out.println("tempList len="+tempList.length);
					for(int j = 0; j < tempList.length; j++)	// there should only be one
					{
						PstFlowStep tempStep = (PstFlowStep)fsMgr.get(m_pstuser, (String)tempList[j]);
						tempStep.setAttribute(PstFlowStep.SIGNATURE, "PlanApproval/plan");

						// for this application of flow approval, the Application is
						// revw_planchg.jsp
						tempStep.setAttribute("Application",
							"../project/revw_planchg.jsp?stepId="+ tempStep.getObjectId());
						fsMgr.commit(tempStep);		// !! this is NOT commitStep()
					}

					int count = 0;

					// STEP 4: commit step(s) if conditions are met
					// this can go on to the next step and the next step, etc. (do it in a while loop)
					String flowInstName;
					List pendingList;
					while (true)
					{
						stepObj = null;

						// Auto commit for the same person: check my in-tray (pendingList)
						// I will find the above created step if I were the step executor
						pendingList = PstFlowStepManager.
							getAllActiveStep((PstUserAbstractObject)m_pstuser);
						for(int j = 0; j < pendingList.size(); j++)
						{
							try {nextstepObj =
								(PstFlowStep)fsMgr.get(m_pstuser, (String)pendingList.get(j));}
							catch (PmpException e) {
								System.out.println("Corrupted step [" + pendingList.get(j) + "]");
								continue;
							}
							flowInstName = (String)
								nextstepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0];
							if(flowInstName == null)
								continue;

							flowObj = (PstFlow)fMgr.get(m_pstuser, flowInstName);
							// compare to see if we have the same data object (for the same flow inst)
							if (flowDOName.equals((String)flowObj.getAttribute(PstFlow.CONTEXT_OBJECT)[0]))
							{
								// Found that the next step of the flow belongs to me, set the stepObj
System.out.println("--- found revelant step [" + nextstepObj.getObjectId()+"]");
								stepObj = nextstepObj;
								break;
							}
						}

						// loop termination case
						// none of my active steps belong to this flow instance
						if (stepObj == null) break;		// no step to work on, break out!!

						// Auto commit for the same person.
						String flowDOName1 = flowDOName + new Date().getTime() + count++;
						PstFlowDataObject flowDataObj1 = (PstFlowDataObject)fdataMgr.create(m_pstuser, flowDOName1, "PlanApproval");

						flowDataObj1.setAttribute("string2", flowDOName);	// the plan unique name (used by Final)
						// get project owner
						//flowDataObj1.setAttribute("int1", new Integer(projOwner));

						// since I am the same person to execute next step (stepObj), go ahead and commit it
						// Final.lastStep() will be called in the next call
						stepObj.commitStep(m_pstuser, flowDataObj1);
System.out.println("WfThread done with commitStep() call [" + stepObj.getObjectId() + "]");

						// the state of the step would have changed by WF engine, refresh it now
						PstFlowStep refreshStep = (PstFlowStep)fsMgr.get(m_pstuser, stepObj.getObjectName());

						// Set the next step's signature
						Object [] nextStepList = refreshStep.getAttribute(PstFlowStep.OUTGOING_STEP_INSTANCE);
						for (int i = 0; i < nextStepList.length; i++)
						{
							if(nextStepList[i] != null)
							{
								PstFlowStep tempStep = (PstFlowStep)fsMgr.get(m_pstuser, (String)nextStepList[i]);
								tempStep.setAttribute(PstFlowStep.SIGNATURE, "PlanApproval/plan");
								fsMgr.commit(tempStep);
							}
						}
					}	// END while true loop
					break;

				//////////////////////////////////////////////////////////////////
				case WF_OP_LEADER_VERIFY_PLAN:
					System.out.println("--- WF_OP_LEADER_VERIFY_PLAN: "+m_status);

					planObj = (plan)planMgr.get(m_pstuser, m_memName);
					DateFormat DATE_FORMAT = new SimpleDateFormat("MMM dd, yyyy");
					String myUname = m_pstuser.getObjectName();

					stepObj = (PstFlowStep)fsMgr.get(m_pstuser, m_stepName);
					String currentFlowName = (String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0];

					if (m_status.length()<=0) m_status = "commit";	// force commit
					if(m_status.equalsIgnoreCase("commit"))
					{
						//Add PepComment to plan
						Object [] planDescription = planObj.getAttribute("Description");
						PepCommentVector commentVector = PepCommentVector.getComments((byte[]) planDescription[0]);
						if(m_desc != null && m_desc[0] != null && m_desc[0].length() > 0)
						{
							commentVector.addComment(DATE_FORMAT.format(new Date()), myUname, (String)m_desc[0]);
							planObj.setAttribute("Description", commentVector.getBytes());
							planMgr.commit(planObj);
						}

						// commit the step
						count = 0;
						while (stepObj != null)
						{
							flowDOName = planObj.getObjectName() + new Date().getTime() + count++;
							flowDataObj = (PstFlowDataObject)fdataMgr.create(m_pstuser, flowDOName, "PlanApproval");

							flowDataObj.setAttribute("string2", planObj.getObjectName());

							stepObj.commitStep(m_pstuser, flowDataObj);	// COMMIT with approve
							PstFlowStep refreshStep = (PstFlowStep)fsMgr.get(m_pstuser, stepObj.getObjectName());


							//Set the next step's signature
							Object [] nextStepList = refreshStep.getAttribute(PstFlowStep.OUTGOING_STEP_INSTANCE);
							for (int i = 0; i < nextStepList.length; i++)
							{
								if(nextStepList[i] != null)
								{
									PstFlowStep tempStep = (PstFlowStep)fsMgr.get(m_pstuser, (String)nextStepList[i]);
									tempStep.setAttribute(PstFlowStep.SIGNATURE, "PlanApproval/plan");
									fsMgr.commit(tempStep);
								}
							}

							// Auto commit for the same person.
							stepObj = null;
							pendingList = PstFlowStepManager.getAllActiveStep(m_pstuser);
							for(int j = 0; j < pendingList.size(); j++)
							{
								nextstepObj = (PstFlowStep)fsMgr.get(m_pstuser, (String)pendingList.get(j));
								flowInstName = (String)nextstepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0];
								if (flowInstName == null)
									continue;
								flowObj = (PstFlow)fMgr.get(m_pstuser, flowInstName);
								if (m_memName.equals((String)flowObj.getAttribute(PstFlow.CONTEXT_OBJECT)[0]))
								{
									// Found it, set the stepObj
									stepObj = nextstepObj;
									break;
								}
							}
						}
					}
					else if(m_status.equalsIgnoreCase("backward"))
					{
						flowDOName = planObj.getObjectName() + new Date().getTime();
						flowDataObj = (PstFlowDataObject)fdataMgr.create(m_pstuser, flowDOName, "PlanApproval");
						stepObj.abortStep(m_pstuser, flowDataObj);	// abort the step (move backward)
					}
					else if(m_status.equalsIgnoreCase("abort"))
					{
						//Add PepComment to plan
						Object [] planDescription = planObj.getAttribute("Description");
						PepCommentVector commentVector = PepCommentVector.getComments((byte[]) planDescription[0]);
						if(m_desc != null && m_desc[0] != null && m_desc[0].length() > 0)
						{
							commentVector.addComment(DATE_FORMAT.format(new Date()), myUname, (String)m_desc[0] + "<br> [<b>Plan is rejected by the user!</b>]");
							planObj.setAttribute("Description", commentVector.getBytes());
							planMgr.commit(planObj);
						}

						if(stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0] != null)
						{
							flowObj = (PstFlow)fMgr.get(m_pstuser, (String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0]);
							flowObj.abortFlow(m_pstuser);
						}
					}

					/////////// Return RC
					m_rc1 = new Integer(currentFlowName);	// return the current flow id
					break;

				//////////////////////////////////////////////////////////////////
				default:
					break;
			}
		}
		catch (Exception e)
		{
			m_rc1 = new Integer(-1);		// error
			System.out.println(e.toString());
			e.printStackTrace();
			m_exception = e;
		}
		System.out.println("*** WfThread exited");
	}

	public static Date setTaskDates(PstAbstractObject pjObj, PstAbstractObject tkObj, int startGap, int length)
		throws PmpException, ParseException
	{
		Date dt;
		Date startDate = (Date)pjObj.getAttribute("StartDate")[0];
		Date pjExpire  = (Date)pjObj.getAttribute("ExpireDate")[0];
		if (pjExpire == null) return null;		// container project

		if (startGap > 0)
			dt = new Date(startDate.getTime() + (long)startGap * 86400000);
		else
			dt = startDate;
		tkObj.setAttribute("StartDate", dt);

		if (length >= 0)
		{
			dt = new Date(dt.getTime() + (long)length * 86400000);	// because of day light saving, this may not be 00:00
			dt = new Date(df.format(dt));
			if (dt.after(pjExpire))
				pjExpire = dt;
		}
		else
			dt = pjExpire;
		tkObj.setAttribute("ExpireDate", dt);
		return pjExpire;
	}
	
	// generic methods for all applications to consider
	/**
	 * 
	 * @param uObj
	 * @param flowDefName the workflow definition to be instantiated
	 * @param dataObjectName data object name, cannot be full.
	 * @return PstFlow the newly created flow instance
	 * @throws PmpException
	 */
	public static PstFlow startFlow(PstUserAbstractObject uObj, String flowDefName, String dataObjectName)
		throws PmpException
	{
		// 1. create flow data object
		// caller is responsible to set the values in data object
		PstFlowDataObject flowDataObj = (PstFlowDataObject)fdataMgr.create(uObj, dataObjectName, flowDefName);
		
		// might have to customize for executedBy to work if it depends on Flow Data
		// example here assume: assignTo="$direct:int1.om_acctname";
		flowDataObj.setAttribute("int1", new Integer(uObj.getObjectId()));
		fdataMgr.commit(flowDataObj);
		
		// 2. create flow object
		// the first step would already be created in the flow create() call
		PstFlow newFlow = (PstFlow)fMgr.create(uObj, flowDefName,
				flowDataObj, PstFlow.TYPE_WORKFLOW);
		

		return newFlow;
	}
}