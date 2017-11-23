////////////////////////////////////////////////////
//	Copyright (c) 2008, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	SampleWfThread.java
//	Author:	ECC
//	Date:	06/28/08
//	Description:
//		Run parallel (thread) operations for user's workflow applications.
//		string1 - equipment list
//		string2 - location;
//		raw1    - dept_approval@@admin_approval@@it_approval@@it_handle
//		date1 - submit req / dept approve
//		date2 - admin approve
//		date3 - it approve
//		date4 - it handle
//
////////////////////////////////////////////////////////////////////

package util;

import java.util.Date;
import java.util.List;

import oct.codegen.user;
import oct.codegen.userManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstFlow;
import oct.pst.PstFlowDataObject;
import oct.pst.PstFlowDataObjectManager;
import oct.pst.PstFlowManager;
import oct.pst.PstFlowStep;
import oct.pst.PstFlowStepManager;
import oct.pst.PstSystem;
import oct.pst.PstUserAbstractObject;

public class SampleWfThread extends Thread
{
	
	public final static int WF_OP_HARDWARE_REQ		= 101;
	public final static int WF_OP_DEPT_GM_APPROVE	= 102;
	public final static int WF_OP_ADMIN_GM_APPROVE	= 103;
	public final static int WF_OP_IT_GM_APPROVE		= 104;
	public final static int WF_OP_IT_HANDLE_INFORM	= 105;
	
	private static final String FROM = Util.getPropKey("pst", "FROM");
	private static final String MAILFILE = "alert.htm";
	
	// comment type
	private final int COMMENT_DEPT		= 0;
	private final int COMMENT_ADMIN		= 1;
	private final int COMMENT_IT		= 2;
	private final int COMMENT_HANDLE	= 3;

	private final int [] OP_ARRAY = {
			WF_OP_HARDWARE_REQ, WF_OP_DEPT_GM_APPROVE,
			WF_OP_ADMIN_GM_APPROVE, WF_OP_IT_GM_APPROVE,
			WF_OP_IT_HANDLE_INFORM}; 
	
	private final String THIS_WF_APP_NAME = "HardwareApplication";
	
	private static PstFlowManager fMgr = null;
	private static PstFlowStepManager fsMgr = null;
	private static PstFlowDataObjectManager fdMgr = null;
	private static userManager uMgr = null;

	private int			m_op;
	private String		m_memName;
	private String		m_stepName;
	private String		m_status;
	private PstUserAbstractObject	m_pstuser;
	private PstSystem	m_pst = null;
	
	private String 		m_equipList;
	private String 		m_location;
	private String 		m_deptApproval;
	private Date		m_deptApprovalDate;
	private String		m_adminApproval;
	private Date		m_adminApprovalDate;
	//perry
    private String		m_itApproval;
	private Date		m_itApprovalDate;
	private String		m_handleApproval;
	private Date		m_handleApprovalDate;

	private Object		m_rc1;					// return -1 for error or current flow Id
	private Exception	m_exception;			// in case it throws exception

	public Object 		getRC1() {return m_rc1;}
	public Exception	getException() {return m_exception;}
	
	private final String SIGNATURE_VAC = "Request for IT Hardware";


	// init basic
	public SampleWfThread()
		throws PmpException
	{
		fMgr = PstFlowManager.getInstance();
		fsMgr = PstFlowStepManager.getInstance();
		fdMgr = PstFlowDataObjectManager.getInstance();
		uMgr = userManager.getInstance();
		m_pst = PstSystem.getInstance();
	}

	// init for WF_OP_VACATION_REQ (by wf_sample1.jsp)
	public SampleWfThread(PstUserAbstractObject pstuser,
			int op, Object workObj, String dataS,
		String [] description, String [] Version)
		throws PmpException
	{
		this();
		m_pstuser = pstuser;
		m_op = op;
		// optional
		// an example to support automatic approval depending on the role of user starting the workflow
		// for vacation request, there should not be auto approval
		int iRole = Util.getRoles(pstuser);
		if ( (iRole & (user.iROLE_ADMIN | user.iROLE_PROGMGR)) > 0 ) {
		} else {
		}
	}

	// init for WF_OP_VACATION_APPROVE (by wf_sample2.jsp)
	public SampleWfThread(PstUserAbstractObject pstuser,
			int op, String workObjname, String stepName,
			String status, String [] description)
		throws PmpException
	{
		this();
		m_pstuser = pstuser;		// login user
		m_op = op;
		m_memName = workObjname;	// used to store the name of the object the thread needs to reference to
		m_stepName = stepName;		// this currently executed step
		m_status = status;
		System.out.println("construction with parameters run!");
	}

	
	// init for WF_OP_VACATION_APPROVE (by wf_sample2.jsp)
	public SampleWfThread(PstUserAbstractObject pstuser,
			int op, String workObjname, String stepName,
			String status, String [] description, String equipList, String location,
			String deptApproval, Date deptApprovalDate, String adminApproval, Date adminApprovalDate,
			String itApproval, Date itApprovalDate, String handleApproval, Date handleApprovalDate)
		throws PmpException
	{
		this();
		m_pstuser = pstuser;
		m_op = op;
		m_memName = workObjname;
		m_stepName = stepName;
		m_status = status;
		
		// the below approval comments should be combined and stored in a RAW attribute
		// but currently we have a problem with storing and retrieving Chinese characters
		// temporary solution is to just use separate String attributes
		m_equipList = equipList;
		m_location = location;
		
		m_deptApproval = deptApproval;
		m_deptApprovalDate = deptApprovalDate;
		
		m_adminApproval = adminApproval;
		m_adminApprovalDate = adminApprovalDate;

		m_itApproval = itApproval;
		m_itApprovalDate = itApprovalDate;
		
		m_handleApproval = handleApproval;
		m_handleApprovalDate = handleApprovalDate;
		
		System.out.println("Constructed thread with parameters run!");
	}
	
	
	public void run()
	{
		System.out.println("*** SampleWfThread started running ...");
		setPriority(Thread.MAX_PRIORITY);	// can be adjusted

		PstAbstractObject workObj = null;
		PstFlow flowObj;
		PstFlowStep stepObj = null, nextstepObj;
		PstFlowDataObject flowDataObj = null;
		String flowDataId = null;
		String currentFlowName = null;

		try
		{
			System.out.println("===> Start running thread: SampleWFThread.java op = " + m_op);
			System.out.println("status = "+ m_status);
			
			// if workflow already started, then there is a step I am executing
			if (!StringUtil.isNullOrEmptyString(m_stepName)) {
				System.out.println("m_stepName =" + m_stepName);
				stepObj = (PstFlowStep)fsMgr.get(m_pstuser, m_stepName);
				String executorIdS = stepObj.getCurrentExecutor();
				System.out.println("Current Executor = " + executorIdS);
				if (StringUtil.isNullOrEmptyString(executorIdS)) {
					// send email to our WF admin person to handle separately
					if (!Util.sendMailAsyn(null, FROM, null, null,
							"WF - no executor", m_stepName, MAILFILE));
				}
				
				flowDataId = (String) stepObj.getAttribute("FlowDataInstance")[0];
				flowDataObj = (PstFlowDataObject) fdMgr.get(m_pstuser, flowDataId);
				
				// SAVE
				// regardless of operation (step), if status is to SAVE, just save
				if (m_status.toLowerCase().equals("save")) {
					// save all attributes
					String [] commentArr = {m_deptApproval, m_adminApproval, m_itApproval, m_handleApproval};
					for (int i=0; i<commentArr.length; i++) {
System.out.println("comment: " + commentArr[i]);						
						writeComment(flowDataObj, commentArr[i], i);
					}
					fdMgr.commit(flowDataObj);
					System.out.println("done saving flow data");
					return;
				}
			}

			
			// other status: commit or abort
			switch (m_op)
			{
				//////////////////////////////////////////////////////////////////
				// 1. case WF_OP_HARDWARE_REQ:
				// when user first submit the request form
				case WF_OP_HARDWARE_REQ:
					System.out.println("--- WF_OP_HARDWARE_REQ");

					// Workflow code begin!!
					// set up flow data, specific to plan change app
					String myFlowDOId = String.valueOf(System.currentTimeMillis()) ;
					
					// PstFlowDataObject is the data object associated to each workflow instance
					// It is used to transport data across each step of the flow.  Steps have to know the semantics of these attributes.
					flowDataObj = (PstFlowDataObject)fdMgr.create(m_pstuser, myFlowDOId, "HardwareApplication");
					currentFlowName = flowDataObj.getObjectName();
					
					
					//set flow instance data
					flowDataObj.setAttribute("string1",m_equipList);
					flowDataObj.setAttribute("string2", m_location);					
					flowDataObj.setAttribute("date1", new Date());
					//flowDataObj.setAttribute("raw1", m_equipList.getBytes());
					//fdMgr.commit(flowDataObj);		// no need to save because create flow will save the data object

					PstFlow currentFlow = (PstFlow)fMgr.create(m_pstuser, "HardwareApplication",flowDataObj, PstFlow.TYPE_WORKFLOW);
					
					System.out.println("!!! SampleWfThread: created currentFlow="+currentFlow.getObjectId());


					currentFlow.setAttribute(PstFlow.CONTEXT_OBJECT, myFlowDOId);	// flow's context. E.g. workObj name
					//currentFlow.setAttribute(PstFlow.CONTEXT_OBJECT_ORG, "xxx");// should store the orgName of workObj

					// OK to hardwire the flow definition name because it is this application
					// that we are working on.  If you don't like it, you can pass in the name.
					//currentFlow.setAttribute(PstFlow.ATTR_FLOWDEF_NAME, "VacationReq");
					currentFlow.setAttribute(PstFlow.ATTR_FLOWDEF_NAME, THIS_WF_APP_NAME);
					fMgr.commit(currentFlow);			// this will create the flow instance in OMM

					/////////// Return RC
					m_rc1 = new Integer(currentFlow.getObjectId());	// return the current flow id

					
					///////////////////////////////////////////////////////////////////////////////
					// Now the workflow instance is created.  We can move on to start processing the
					// first step.
					///////////////////////////////////////////////////////////////////////////////
					
					
					/////////////////////////////////////////////////////
					// Start setting up for processing steps
					// Look for the first step and add Signature into it
					Object [] tempList = currentFlow.getAttribute(PstFlow.CURRENT_ACTIVE_STEP);
					for(int j = 0; j < tempList.length; j++) {
						PstFlowStep tempStep = (PstFlowStep)fsMgr.get(m_pstuser, (String)tempList[j]);
						//get attribute of current executor
						tempStep.setAttribute(PstFlowStep.SIGNATURE, SIGNATURE_VAC);

						// The application (JSP Page) of the first step
						// for this application of flow approval, the Application is
						// requestPC.jsp
						 tempStep.setAttribute("Application","requestPC.jsp?stepId=" + tempStep.getObjectId()
								 + "&op=" + WF_OP_DEPT_GM_APPROVE );
						fsMgr.commit(tempStep);		// !! this is NOT commitStep(), just save changes to DB
					}

					int count = 0;

					/////////////////////////////////////////////////////
					// Now I am ready to start processing the steps
					// this can go on to the next step and the next step, etc. (do it in a while loop)
					String flowInstName;
					List pendingList;
					int nextIndex = 2;		// points to OP_ARRAY: ADMIN_GM_APPROVE
					while (true) {
						stepObj = null;

						// Auto commit for the same person: check my in-tray (pendingList)
						// I will find the above created step if I were the step executor
						// This is the call to get the WORKTRAY.
						pendingList = PstFlowStepManager.
							getAllActiveStep((PstUserAbstractObject)m_pstuser);
						
						// note that in my worktray there might be a lot of work (step) waiting
						// for me to process.  I am only interested in the steps related to this workflow instance.
						for(int j = 0; j < pendingList.size(); j++) {
							// get the active step object of this workflow instance
							try {nextstepObj =
									(PstFlowStep)fsMgr.get(m_pstuser, (String)pendingList.get(j));}
							catch (PmpException e) {
								System.out.println("Corrupted step [" + pendingList.get(j) + "]");
								continue;
							}
							flowInstName = (String)
								nextstepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0];
							if(flowInstName == null)
								continue;	// shouldn't be null

							flowObj = (PstFlow)fMgr.get(m_pstuser, flowInstName);
							
							// compare to see if we have the same data object (i.e. the same flow instance)
							if (myFlowDOId.equals((String)flowObj.getAttribute(PstFlow.CONTEXT_OBJECT)[0])) {
								// Found that the next step of the flow belongs to me, set the stepObj
								System.out.println("--- found revelant step ["
										+ nextstepObj.getObjectId()+"] to process for auto commit.");
								nextstepObj.setAttribute(PstFlowStep.CURRENT_EXECUTOR, "-1");
								fsMgr.commit(nextstepObj);
								stepObj = nextstepObj;
								break;
							}
						}

						//////////////////////////
						// loop termination case
						// none of my active steps belong to this flow instance
						if (stepObj == null) break;		// no step to work on, break out!!

						// I am the person who started the flow, so just go ahead and move forward
						// no need to ask me to approve one more time.  This is the case a middle manager
						// is submitting for vacation request.
						
						// Since I am the same person to execute next step (stepObj), go ahead and commit it
						stepObj.commitStep(m_pstuser, flowDataObj);	// auto commit Dept GM approval
						System.out.println("SampleWfThread done with auto commitStep() call ["
								+ stepObj.getObjectId() + "]");
						
						// set auto approve comment
						setAutoApproveComment(flowDataObj, OP_ARRAY[nextIndex-1],
								String.valueOf(m_pstuser.getObjectId()));

						// the state of the step would have changed by WF engine, refresh it from OMM now
						PstFlowStep refreshStep = (PstFlowStep)fsMgr.get(m_pstuser, stepObj.getObjectName());

						// Set the next step's signature
						Object [] nextStepList = refreshStep.getAttribute(PstFlowStep.OUTGOING_STEP_INSTANCE);
						for (int i = 0; i < nextStepList.length; i++) {
							if(nextStepList[i] != null) {
								// prepare the next step after auto commit
								PstFlowStep tempStep = (PstFlowStep)fsMgr.get(m_pstuser, (String)nextStepList[i]);
								tempStep.setAttribute(PstFlowStep.SIGNATURE, SIGNATURE_VAC);
								tempStep.setAttribute("Application",
										"requestPC.jsp?stepId=" + tempStep.getObjectId()
										+ "&op=" + OP_ARRAY[nextIndex++]);
								fsMgr.commit(tempStep);
							}
						}
					}	// END: while TRUE loop to process my active step
					
					System.out.println("--- done with HARDWARE_APPROV");
					break;	// END case: HARDWARE_APPROV

					
				//////////////////////////////////////////////////////////////////
				// this case will be triggered by the JSP that approves the workflow
				// 2. case WF_OP_DEPT_GM_APPROVE:
				case WF_OP_DEPT_GM_APPROVE:
					System.out.println("--- WF_OP_DEPT_GM_APPROVE: " + m_status);
					
					currentFlowName = (String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0];

					if (m_status.length()<=0) m_status = "commit";	// force commit (approve)
					
					// approve
					if (m_status.equalsIgnoreCase("commit"))
					{
						// update the application's work object

						// commit the step
						count = 0;
						nextIndex = 2;		// next is WF_OP_ADMIN_GM_APPROVE
						while (stepObj != null) {
							if (OP_ARRAY[nextIndex-1] == WF_OP_DEPT_GM_APPROVE) {	// check current step
								System.out.println("dept members: " + m_deptApproval + "\t" + m_deptApprovalDate);
								System.out.println("admin members: " + m_adminApproval + "\t" + m_adminApprovalDate);
								flowDataObj.setAttribute("date1", m_deptApprovalDate);
								writeComment(flowDataObj, m_deptApproval, COMMENT_DEPT);	// was string3
							}
							
							stepObj.commitStep(m_pstuser, flowDataObj);	// COMMIT with approve
							PstFlowStep refreshStep = (PstFlowStep)fsMgr.get(m_pstuser, stepObj.getObjectName());


							//Set the next step's signature and app
							Object [] nextStepList = refreshStep.getAttribute(PstFlowStep.OUTGOING_STEP_INSTANCE);
							Object [] nextStepObjList = new PstFlowStep[nextStepList.length];
							for (int i = 0; i < nextStepList.length; i++) {
								if(nextStepList[i] != null) {
									PstFlowStep tempStep = (PstFlowStep)fsMgr.get(m_pstuser, (String)nextStepList[i]);
									nextStepObjList[i] = tempStep;
									tempStep.setAttribute(PstFlowStep.SIGNATURE, SIGNATURE_VAC);
									
									tempStep.setAttribute("Application",
											"requestPC.jsp?stepId=" + tempStep.getObjectId()
											+ "&op=" + OP_ARRAY[nextIndex++] );
									fsMgr.commit(tempStep);
								}
							}
							
							// auto commit
							// check to commit any steps that have been committed by previous approvers
							// refreshStep is the last committed step.
							stepObj = getAutoCommitStep(refreshStep, nextStepObjList, flowDataObj, nextIndex);

						}	// END: while loop to commit my connected steps
					}	// END: if approve
					
					// backward to request for more info from last executor
					else if(m_status.equalsIgnoreCase("backward")) {
						myFlowDOId = workObj.getObjectName() + new Date().getTime();
						flowDataObj = (PstFlowDataObject)fdMgr.create(m_pstuser, myFlowDOId, "HardwareApplication");
						stepObj.abortStep(m_pstuser, flowDataObj);	// abort the step (move backward on step)
					}
					
					// total reject
					else if(m_status.equalsIgnoreCase("abort")) {
						// save comments
						writeComment(flowDataObj, m_deptApproval, COMMENT_DEPT);
						fdMgr.commit(flowDataObj);

						if(stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0] != null) {
							flowObj = (PstFlow)fMgr.get(m_pstuser, (String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0]);
							flowObj.abortFlow(m_pstuser);
						}
					}

					/////////// Return RC
					m_rc1 = new Integer(currentFlowName);	// return the current flow id
					break;

					
					
					
					//////////////////////////////////////////////////////////////////
					// 3. case WF_OP_ADMIN_GM_APPROVE:
					case WF_OP_ADMIN_GM_APPROVE:
						System.out.println("--- WF_OP_ADMIN_GM_APPROVE: " + m_status);						
						
						currentFlowName = (String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0];

						if (m_status.length()<=0) m_status = "commit";	// force commit (approve)
						
						// approve
						if (m_status.equalsIgnoreCase("commit"))
						{
							// commit the step
							nextIndex = 3;		// next is WF_OP_IT_GM_APPROVE
							count = 0;
							while (stepObj != null) {
								System.out.println("==== in stepObj! = null  =====");
								myFlowDOId = String.valueOf(new Date().getTime() + count++);
								//flowDataObj = (PstFlowDataObject) fdMgr.get(m_pstuser, flowDataId);
								
								System.out.println("dept members: " + m_deptApproval + "\t" + m_deptApprovalDate);
								System.out.println("admin members: " + m_adminApproval + "\t" + m_adminApprovalDate);
								//flowDataObj.setAttribute("string4", m_adminApproval);
								writeComment(flowDataObj, m_adminApproval, COMMENT_ADMIN);
								flowDataObj.setAttribute("date2", m_adminApprovalDate);		
								
								stepObj.commitStep(m_pstuser, flowDataObj);	// COMMIT with approve
								
								PstFlowStep refreshStep = (PstFlowStep)fsMgr.get(m_pstuser, stepObj.getObjectName());


								//Set the next step's signature
								Object [] nextStepList = refreshStep.getAttribute(PstFlowStep.OUTGOING_STEP_INSTANCE);
								Object [] nextStepObjList = new PstFlowStep[nextStepList.length];
								for (int i = 0; i < nextStepList.length; i++) {
									if (nextStepList[i] != null) {
										PstFlowStep tempStep = (PstFlowStep)fsMgr.get(m_pstuser, (String)nextStepList[i]);
										nextStepObjList[i] = tempStep;
										tempStep.setAttribute(PstFlowStep.SIGNATURE, SIGNATURE_VAC);
										tempStep.setAttribute("Application",
												"requestPC.jsp?stepId=" + tempStep.getObjectId()
												+ "&op=" + OP_ARRAY[nextIndex++] );
										fsMgr.commit(tempStep);
									}
								}

								
								// auto commit
								// check to commit any steps that have been committed by previous approvers
								// refreshStep is the last committed step.
								stepObj = getAutoCommitStep(refreshStep, nextStepObjList, flowDataObj, nextIndex);
							}	// END: while
						}	// END: if approve
						
						// backward to request for more info from last executor
						else if(m_status.equalsIgnoreCase("backward")) {
							myFlowDOId = workObj.getObjectName() + new Date().getTime();
							flowDataObj = (PstFlowDataObject)fdMgr.create(m_pstuser, myFlowDOId, "HardwareApplication");
							stepObj.abortStep(m_pstuser, flowDataObj);	// abort the step (move backward on step)
						}
						
						// total reject
						else if(m_status.equalsIgnoreCase("abort")) {
							// save comments
							writeComment(flowDataObj, m_deptApproval, COMMENT_DEPT);
							fdMgr.commit(flowDataObj);

							if(stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0] != null) {
								flowObj = (PstFlow)fMgr.get(m_pstuser, (String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0]);
								flowObj.abortFlow(m_pstuser);
							}
						}

						/////////// Return RC
						m_rc1 = new Integer(currentFlowName);	// return the current flow id
						break;					
					
					
					
					//////////////////////////////////////////////////////////////////
					// 4. case WF_OP_IT_GM_APPROVE:
					case WF_OP_IT_GM_APPROVE:
						System.out.println("--- WF_OP_IT_GM_APPROVE: " + m_status);

						currentFlowName = (String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0];

						if (m_status.length()<=0) m_status = "commit";	// force commit (approve)

						// approve
						if (m_status.equalsIgnoreCase("commit"))
						{
							// commit the step
							nextIndex = 4;		// next is WF_OP_IT_HANDLE_INFORM
							count = 0;
							while (stepObj != null) {
								System.out.println("==== in stepObj! = null  =====");
								myFlowDOId = String.valueOf(new Date().getTime() + count++);
								//flowDataObj = (PstFlowDataObject) fdMgr.get(m_pstuser, flowDataId);

								//flowDataObj.setAttribute("string2", workObj.getObjectName());
								System.out.println("dept members: " + m_deptApproval + "\t" + m_deptApprovalDate);
								System.out.println("admin members: " + m_adminApproval + "\t" + m_adminApprovalDate);
								//flowDataObj.setAttribute("string5", m_itApproval);
								writeComment(flowDataObj, m_itApproval, COMMENT_IT);
								flowDataObj.setAttribute("date3", m_itApprovalDate);

								stepObj.commitStep(m_pstuser, flowDataObj);	// COMMIT with approve

								//stepObj.commitStep(m_pstuser, myFlowDOId);	// COMMIT with approve
								PstFlowStep refreshStep = (PstFlowStep)fsMgr.get(m_pstuser, stepObj.getObjectName());


								//Set the next step's signature and app
								Object [] nextStepList = refreshStep.getAttribute(PstFlowStep.OUTGOING_STEP_INSTANCE);
								Object [] nextStepObjList = new PstFlowStep[nextStepList.length];
								for (int i = 0; i < nextStepList.length; i++) {
									if(nextStepList[i] != null) {
										PstFlowStep tempStep = (PstFlowStep)fsMgr.get(m_pstuser, (String)nextStepList[i]);
										nextStepObjList[i] = tempStep;
										tempStep.setAttribute(PstFlowStep.SIGNATURE, SIGNATURE_VAC);

										tempStep.setAttribute("Application",
												"requestPC.jsp?stepId=" + tempStep.getObjectId()
												+ "&op=" + OP_ARRAY[nextIndex++] );
										fsMgr.commit(tempStep);
									}
								}

								
								// auto commit
								// check to commit any steps that have been committed by previous approvers
								// refreshStep is the last committed step.
								stepObj = getAutoCommitStep(refreshStep, nextStepObjList, flowDataObj, nextIndex);
							}
						}

						// backward to request for more info from last executor
						else if(m_status.equalsIgnoreCase("backward")) {
							myFlowDOId = workObj.getObjectName() + new Date().getTime();
							flowDataObj = (PstFlowDataObject)fdMgr.create(m_pstuser, myFlowDOId, "HardwareApplication");
							stepObj.abortStep(m_pstuser, flowDataObj);	// abort the step (move backward on step)
						}

						// total reject
						else if(m_status.equalsIgnoreCase("abort")) {
							// save comments
							writeComment(flowDataObj, m_deptApproval, COMMENT_DEPT);
							fdMgr.commit(flowDataObj);

							if(stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0] != null) {
								flowObj = (PstFlow)fMgr.get(m_pstuser, (String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0]);
								flowObj.abortFlow(m_pstuser);
							}
						}

						/////////// Return RC
						m_rc1 = new Integer(currentFlowName);	// return the current flow id
						break;

					//////////////////////////////////////////////////////////////////
					// 5. case WF_OP_IT_HANDLE_INFORM:
					case WF_OP_IT_HANDLE_INFORM:
						System.out.println("--- WF_OP_IT_HANDLE_INFORM: " + m_status);

						currentFlowName = (String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0];

						if (m_status.length()<=0) m_status = "commit";	// force commit (approve)

						// approve
						if (m_status.equalsIgnoreCase("commit"))
						{
							// update the application's work object

							// commit the step
							count = 0;
							while (stepObj != null) {
								System.out.println("==== in stepObj! = null  =====");
								myFlowDOId = String.valueOf(new Date().getTime() + count++);
								//flowDataObj = (PstFlowDataObject) fdMgr.get(m_pstuser, flowDataId);

								//flowDataObj.setAttribute("string2", workObj.getObjectName());
								System.out.println("dept members: " + m_deptApproval + "\t" + m_deptApprovalDate);
								System.out.println("admin members: " + m_adminApproval + "\t" + m_adminApprovalDate);
								//flowDataObj.setAttribute("string6",m_handleApproval);
								writeComment(flowDataObj, m_handleApproval, COMMENT_HANDLE);
								flowDataObj.setAttribute("date4",m_handleApprovalDate);

								stepObj.commitStep(m_pstuser, flowDataObj);	// COMMIT with approve

								//stepObj.commitStep(m_pstuser, myFlowDOId);	// COMMIT with approve
								PstFlowStep refreshStep = (PstFlowStep)fsMgr.get(m_pstuser, stepObj.getObjectName());


								//Set the next step's signature (there is no next step after this)
								Object [] nextStepList = refreshStep.getAttribute(PstFlowStep.OUTGOING_STEP_INSTANCE);
								for (int i = 0; i < nextStepList.length; i++) {
									if(nextStepList[i] != null) {
										PstFlowStep tempStep = (PstFlowStep)fsMgr.get(m_pstuser, (String)nextStepList[i]);
										tempStep.setAttribute(PstFlowStep.SIGNATURE, SIGNATURE_VAC);
										fsMgr.commit(tempStep);										
									}
								}

								// Auto commit for the same person (there is no next step after this)
								//stepObj = getAutoCommitStep(refreshStep, nextStepList, flowDataObj, nextIndex);
								stepObj = null;		// no more step after this, no auto commit check needed
							}
						}

						// backward to request for more info from last executor
						else if(m_status.equalsIgnoreCase("backward")) {
							myFlowDOId = workObj.getObjectName() + new Date().getTime();
							flowDataObj = (PstFlowDataObject)fdMgr.create(m_pstuser, myFlowDOId, "HardwareApplication");
							stepObj.abortStep(m_pstuser, flowDataObj);	// abort the step (move backward on step)
						}

						// total reject
						else if(m_status.equalsIgnoreCase("abort")) {
							// save comments
							writeComment(flowDataObj, m_deptApproval, COMMENT_DEPT);
							fdMgr.commit(flowDataObj);

							if(stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0] != null) {
								flowObj = (PstFlow)fMgr.get(m_pstuser, (String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0]);
								flowObj.abortFlow(m_pstuser);
							}
						}

						/////////// Return RC
						m_rc1 = new Integer(currentFlowName);	// return the current flow id
						break;

				default:
					break;
			}
			
			// send email to executors of the next active steps
			if (currentFlowName != null) {
				PstFlow currentFlow = (PstFlow) fMgr.get(m_pstuser, currentFlowName);
				PrmWf.notifyExecutor(m_pstuser, null, currentFlow, null);
			}
		}
		catch (Exception e)
		{
			m_rc1 = new Integer(-1);		// error
			System.out.println(e.toString());
			e.printStackTrace();
			m_exception = e;
		}
		System.out.println("<=== SampleWfThread run exited");
	}
	
	
	private void writeComment(PstFlowDataObject flowDataObj,
			String comment, int iType)
		throws Exception
	{
		// write comment into flow data obj
		// NOTE: this method won't save to OMM
		// construct the comment based on type
		// format: dept_com@@admin_com@@it_com@@handle_com
		if (StringUtil.isNullOrEmptyString(comment))
			return;		// do nothing
		
		String newComments = "";
		String oldComments = "";
		Object rawData = flowDataObj.getAttribute("raw1")[0];
		if (rawData != null)
			oldComments = new String ((byte []) rawData, "utf-8");
		if (StringUtil.isNullOrEmptyString(oldComments)) oldComments = "";
		
		String [] sa = oldComments.split("@@");
		if (iType >= sa.length) {
			// just append comment at end
			newComments = oldComments;
			if (newComments.length() > 0) newComments += "@@";
			newComments += comment;
		}
		else {
			// need to replace old comment
			for (int i=0; i<sa.length; i++) {
				if (iType == i) {
					if (newComments.length() > 0) newComments += "@@";
					newComments += comment;	// replace with new
				}
				else {
					if (newComments.length() > 0) newComments += "@@";
					newComments += sa[i];	// copy old
				}
			}
		}

System.out.println("final new comment: " + newComments);	
		flowDataObj.setAttribute("raw1", newComments.getBytes("utf-8"));
		//flowDataObj.setRawAttribute("raw1", newComments);
	}
	
	/**
	 * find candidate for auto commit
	 * @param refreshStep
	 * @param nextStepList
	 * @param flowDataObj
	 * @param nextIndex
	 * @return
	 * @throws PmpException
	 */
	private PstFlowStep getAutoCommitStep(PstFlowStep refreshStep, Object [] nextStepList,
			PstFlowDataObject flowDataObj, int nextIndex)
		throws Exception
	{
		PstFlowStep stepObj = null;
		PstFlow flowObj = (PstFlow)fMgr.get(m_pstuser,
				refreshStep.getStringAttribute(PstFlowStep.FLOW_INSTANCE_NAME));
		for (int i = 0; i < nextStepList.length; i++) {
			PstFlowStep aStep = (PstFlowStep) nextStepList[i];
			if (aStep != null) {
				// if the step is already approved by previous approver, auto commit it
				String executorIdS = aStep.getCurrentExecutor();
				if (StringUtil.isNullOrEmptyString(executorIdS)) {
					// send email to our WF admin person to handle separately
					if (!Util.sendMailAsyn(null, FROM, null, null,
							"WF - no executor", m_stepName, MAILFILE));
					continue;
				}

				if (flowObj.isPreviousExecutor(executorIdS) ||
						flowObj.getStringAttribute(PstFlow.OWNER).equals(executorIdS)) {
					// auto commit
					System.out.println("+++ case 4: auto commit step ["
							+ aStep.getObjectId() + "] - found previous exector ["
							+ executorIdS + "]");
					aStep.setAttribute(PstFlowStep.CURRENT_EXECUTOR, "-1");
					fsMgr.commit(aStep);
					
					// set auto approve comment
					setAutoApproveComment(flowDataObj, OP_ARRAY[nextIndex-1], executorIdS);

					stepObj = aStep;	// stepObj will be committed in the next loop iteration
					break;				// found auto commit candidate
				}
			}
		}
		return stepObj;
	}
	
	
	/**
	 * In case of auto approval, we need to put auto commit text in the approval box
	 * @param flowDataObj
	 * @param i
	 * @param uidS
	 * @throws PmpException
	 */
	private void setAutoApproveComment(PstFlowDataObject flowDataObj, int i, String uidS)
		throws Exception
	{
		// set auto comments for auto commit step
		
		user uObj = (user) uMgr.get(m_pst, Integer.parseInt(uidS));
		String uName = uObj.getFullName();
		String comment = "*** Auto approval for [" + uName + "] ***";
		String strAttrName = null;
		String dtAttrName = null;
		int iType = 0;
		
		switch (i) {
		case WF_OP_DEPT_GM_APPROVE:
			iType = COMMENT_DEPT;
			dtAttrName = "date1";
			break;
			
		case WF_OP_ADMIN_GM_APPROVE:
			iType = COMMENT_ADMIN;
			dtAttrName = "date2";
			break;
			
		case WF_OP_IT_GM_APPROVE:
			iType = COMMENT_IT;
			dtAttrName = "date3";
			break;
			
		case WF_OP_IT_HANDLE_INFORM:
			iType = COMMENT_HANDLE;
			dtAttrName = "date4";
			break;
			
		default:
			return;
		}
		
		writeComment(flowDataObj, comment, iType);
		flowDataObj.setAttribute(dtAttrName, new Date());
		fdMgr.commit(flowDataObj);
	}

}