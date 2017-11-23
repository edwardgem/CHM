////////////////////////////////////////////////////
//	Copyright (c) 2008, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	VacationWfThread.java
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

public class VacationWfThread extends Thread
{
	
	public final static int WF_OP_HARDWARE_REQ		= 101;
	public final static int WF_OP_DEPT_GM_APPROVE	= 102;
	public final static int WF_OP_ADMIN_GM_APPROVE	= 103;
	public final static int WF_OP_IT_GM_APPROVE		= 104;
	public final static int WF_OP_IT_HANDLE_INFORM	= 105;
	public final static int WF_OP_VACATION_ATTENDANCE = 106;	
	public final static int WF_OP_VACATION_CHECK_DEPT = 107;	
	
	// comment type
	private final int COMMENT_DEPT		= 0;
	private final int COMMENT_ADMIN		= 1;
	private final int COMMENT_IT		= 2;
	private final int COMMENT_HANDLE	= 3;
	private final int COMMENT_ATTENDANCE= 4;
	private final int COMMENT_CHECK_DEPT= 5;	

	private final int [] OP_ARRAY = {
			WF_OP_HARDWARE_REQ, WF_OP_DEPT_GM_APPROVE,
			WF_OP_ADMIN_GM_APPROVE, WF_OP_IT_GM_APPROVE,
			WF_OP_IT_HANDLE_INFORM,WF_OP_VACATION_ATTENDANCE,WF_OP_VACATION_CHECK_DEPT}; 
	
	private final String THIS_WF_APP_NAME = "VacationApplication";
	
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
	
	private String m_gonghao;
	private String m_gangwei;
	private String m_time_qixin;
	private String m_va_type;
	private String m_va_other;
	private String m_time_start;
	private String m_time_end;
	private String m_day_va_total;
	private String m_day_va_finish;
	private String m_day_va_left;
	private String m_location;
	private String m_memo;
	private String m_up_files;		
	private String m_sign1;
	private String m_sign2;
	private String m_sign3;
	private String m_sign4;
	private String m_sign5;
	private String m_sign6;
	private String m_time_start_end;
	//---For my DB
	private String my_dept;
	private String wf_FlowDataid;
	private String wf_floadid;
	private String wf_stepid;
	private String wf_users;
	private String wf_owner;
	private String wf_CurrentExecutor;
	private String wf_opcode;
	private String back_time_type="0";
	private String back_time;
	private String back_time_memo;
    //-------------------
	private String 		m_deptApproval;
	private Date		m_deptApprovalDate;
	private String		m_adminApproval;
	private Date		m_adminApprovalDate;
	//perry
    private String		m_itApproval;
	private Date		m_itApprovalDate;
	private String		m_handleApproval;
	private Date		m_handleApprovalDate;
	//Vacation
	private String		m_attendanceApproval;
	private Date		m_attendanceApprovalDate;
	private String		m_checkdeptApproval;
	private Date		m_checkdeptApprovalDate;	
	

	private Object		m_rc1;					// return -1 for error or current flow Id
	private Exception	m_exception;			// in case it throws exception

	public Object 		getRC1() {return m_rc1;}
	public Exception	getException() {return m_exception;}
	
	private final String SIGNATURE_VAC = "Request for Vacation";


	// init basic
	public VacationWfThread()
		throws PmpException
	{
		fMgr = PstFlowManager.getInstance();
		fsMgr = PstFlowStepManager.getInstance();
		fdMgr = PstFlowDataObjectManager.getInstance();
		uMgr = userManager.getInstance();
		m_pst = PstSystem.getInstance();
	}

	// init for WF_OP_VACATION_REQ (by wf_sample1.jsp)
	public VacationWfThread(PstUserAbstractObject pstuser,
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
	public VacationWfThread(PstUserAbstractObject pstuser,
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
	public VacationWfThread(PstUserAbstractObject pstuser,
			int op, String workObjname, String stepName,
			String status, String [] description, String gonghao, String gangwei, String time_qixin, String va_type, String va_other, String time_start, 
			String time_end, String day_va_total, String day_va_finish, String day_va_left, String location, String memo, 
			String deptApproval, Date deptApprovalDate, String adminApproval, Date adminApprovalDate,
			String itApproval, Date itApprovalDate, String handleApproval, Date handleApprovalDate, String attendanceApproval, Date attendanceApprovalDate, String checkdeptApproval, Date checkdeptApprovalDate,String sign1,String sign2,String sign3,String sign4,String sign5,String sign6,String time_start_end,String up_files)
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
		m_gonghao=gonghao;
		m_gangwei=gangwei;
		m_time_qixin=time_qixin;
		m_va_type=va_type;
		m_va_other=va_other;
		m_time_start=time_start;
		m_time_end=time_end;
		m_day_va_total=day_va_total;
		m_day_va_finish=day_va_finish;
		m_day_va_left=day_va_left;
		m_location=location;
		m_memo=memo;
		m_up_files=up_files;		
		m_sign1=sign1;
		m_sign2=sign2;	
		m_sign3=sign3;	
		m_sign4=sign4;	
		m_sign5=sign5;	
		m_sign6=sign6;											
		m_time_start_end=time_start_end;		
		
		m_deptApproval = deptApproval;
		m_deptApprovalDate = deptApprovalDate;
		
		m_adminApproval = adminApproval;
		m_adminApprovalDate = adminApprovalDate;

		m_itApproval = itApproval;
		m_itApprovalDate = itApprovalDate;
		
		m_handleApproval = handleApproval;
		m_handleApprovalDate = handleApprovalDate;
		
		//Vacation
		m_attendanceApproval = attendanceApproval;
		m_attendanceApprovalDate = attendanceApprovalDate;
		m_checkdeptApproval = checkdeptApproval;
		m_checkdeptApprovalDate = checkdeptApprovalDate;		
		
		System.out.println("Constructed thread with parameters run!");
	}
	
	
	public void run()
	{
		System.out.println("*** VacationWfThread started running ...");
		setPriority(Thread.MAX_PRIORITY);	// can be adjusted

		PstAbstractObject workObj = null;
		PstFlow flowObj;
		PstFlowStep stepObj = null, nextstepObj;
		PstFlowDataObject flowDataObj = null;
		String flowDataId = null;
		String currentFlowName = null;

		try
		{
			System.out.println("===> Start running thread: VacationWfThread.java op = " + m_op);
			System.out.println("status = "+ m_status);
			
			if (!StringUtil.isNullOrEmptyString(m_stepName)) {
				System.out.println("m_stepName =" + m_stepName);
				stepObj = (PstFlowStep)fsMgr.get(m_pstuser, m_stepName);
				System.out.println("Current Executor = " + stepObj.getCurrentExecutor());
				
				flowDataId = (String) stepObj.getAttribute("FlowDataInstance")[0];
				flowDataObj = (PstFlowDataObject) fdMgr.get(m_pstuser, flowDataId);
				
				// SAVE
				// regardless of operation (step), if status is to SAVE, just save
				if (m_status.toLowerCase().equals("save")) {
					// save all attributes
					String [] commentArr = {m_deptApproval, m_adminApproval, m_itApproval, m_handleApproval, m_attendanceApproval,m_checkdeptApproval};
					for (int i=0; i<commentArr.length; i++) {
System.out.println("comment: " + commentArr[i]);						
						writeComment(flowDataObj, commentArr[i], i);
					}
					fdMgr.commit(flowDataObj);
					System.out.println("done saving flow data");
					return;
				}

				// SAVE Wokflow data
				// regardless of operation (step), if status is to SAVE, just save
				if (m_status.toLowerCase().equals("savewf")) {
					//set flow instance data
					flowDataObj.setAttribute("string1",m_gonghao);
					flowDataObj.setAttribute("string2",m_gangwei);
					flowDataObj.setAttribute("string3",m_time_qixin);
					flowDataObj.setAttribute("string4",m_va_type);
					flowDataObj.setAttribute("string5",m_va_other);
					flowDataObj.setAttribute("string6",m_time_start);
					flowDataObj.setAttribute("string7",m_time_end);
					//flowDataObj.setAttribute("string8",m_day_va_total);
					flowDataObj.setAttribute("string9",m_day_va_finish);
					flowDataObj.setAttribute("string10",m_day_va_left);
					flowDataObj.setAttribute("string11",m_location);
					flowDataObj.setAttribute("string12",m_memo);
					flowDataObj.setAttribute("string19",m_time_start_end);		
					flowDataObj.setAttribute("string20",flowDataObj.getAttribute("string19")[0]);
					flowDataObj.setAttribute("string21",m_up_files);
					fdMgr.commit(flowDataObj);
					System.out.println("done saving Wokflow data.");
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
					flowDataObj = (PstFlowDataObject)fdMgr.create(m_pstuser, myFlowDOId, "VacationApplication");
					currentFlowName = flowDataObj.getObjectName();		
					
					//set flow instance data
					flowDataObj.setAttribute("string1",m_gonghao);
					flowDataObj.setAttribute("string2",m_gangwei);
					flowDataObj.setAttribute("string3",m_time_qixin);
					flowDataObj.setAttribute("string4",m_va_type);
					flowDataObj.setAttribute("string5",m_va_other);
					flowDataObj.setAttribute("string6",m_time_start);
					flowDataObj.setAttribute("string7",m_time_end);
					flowDataObj.setAttribute("string8",m_day_va_total);
					flowDataObj.setAttribute("string9",m_day_va_finish);
					flowDataObj.setAttribute("string10",m_day_va_left);
					flowDataObj.setAttribute("string11",m_location);
					flowDataObj.setAttribute("string12",m_memo);
					flowDataObj.setAttribute("string19",m_time_start_end);
					flowDataObj.setAttribute("string21",m_up_files);
					flowDataObj.setAttribute("string22",myFlowDOId);																														
										
					flowDataObj.setAttribute("date1", new Date());
					//flowDataObj.setAttribute("raw1", m_equipList.getBytes());
					//fdMgr.commit(flowDataObj);		// no need to save because create flow will save the data object
					PstFlow currentFlow = (PstFlow)fMgr.create(m_pstuser, "VacationApplication",flowDataObj, PstFlow.TYPE_WORKFLOW);
					
					System.out.println("!!! VacationWfThread: created currentFlow="+currentFlow.getObjectId());
					
					//By Perry,Send email to executors at first Step.
					currentFlowName=String.valueOf(currentFlow.getObjectId());
									

					currentFlow.setAttribute(PstFlow.CONTEXT_OBJECT, myFlowDOId);	// flow's context. E.g. workObj name
					//currentFlow.setAttribute(PstFlow.CONTEXT_OBJECT_ORG, "xxx");// should store the orgName of workObj

					// OK to hardwire the flow definition name because it is this application
					// that we are working on.  If you don't like it, you can pass in the name.
					//currentFlow.setAttribute(PstFlow.ATTR_FLOWDEF_NAME, "VacationReq");
					currentFlow.setAttribute(PstFlow.ATTR_FLOWDEF_NAME, THIS_WF_APP_NAME);
					fMgr.commit(currentFlow);			// this will create the flow instance in OMM	
					
					/*String S_ObjectId =String.valueOf(currentFlow.getObjectId());
					stepObj = (PstFlowStep)fsMgr.get(m_pstuser,S_ObjectId);
					String executorIdS = stepObj.getCurrentExecutor();//(String)stepObj.getAttribute(PstFlowStep.CURRENT_EXECUTOR)[0];
				    System.out.println("Current Executor = " + executorIdS);
					if (executorIdS==null)// (stepObj.getCurrentExecutor()==null)
					{		
					Notify send_email = new Notify();
					send_email.SendEmail("notify_wf@hku-szh.org","perryc@hku-szh.org","PC Request(WF)-no executor","currentFlowName:"+flowDataObj.getObjectId());
					}*/								

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
						// requestVaction.jsp
						 tempStep.setAttribute("Application","requestVaction.jsp?stepId=" + tempStep.getObjectId()
								 + "&op=" + WF_OP_DEPT_GM_APPROVE );
						fsMgr.commit(tempStep);		// !! this is NOT commitStep(), just save changes to DB
		    //--------------Perry Insert into my DB.------------	
			//flowObj = (PstFlow)fMgr.get(m_pstuser, (String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0]);	
			wf_owner =(String)currentFlow.getStringAttribute(PstFlow.OWNER);
		    if (wf_owner != null) {
			user u = (user) uMgr.get(m_pstuser,Integer.parseInt(wf_owner));
			wf_users=String.valueOf(wf_owner);
			wf_owner = u.getStringAttribute("LastName")+u.getStringAttribute("FirstName");
			my_dept = u.getStringAttribute("DepartmentName");
			}
			wf_opcode=String.valueOf(WF_OP_DEPT_GM_APPROVE);
			wf_floadid =currentFlowName;// (String) stepObj.getAttribute("FlowInstanceName")[0];
			wf_stepid=tempStep.getObjectName();
			wf_CurrentExecutor=tempStep.getCurrentExecutor();
			if (wf_stepid==null) wf_stepid="null";
			if (wf_CurrentExecutor==null) wf_CurrentExecutor="null";
			DBAccess.Insert(myFlowDOId,m_gonghao,wf_owner,my_dept,m_up_files,m_va_type,m_time_start_end,"",m_day_va_finish,m_day_va_left,m_location,m_memo,THIS_WF_APP_NAME,wf_users,wf_opcode,wf_floadid,wf_stepid,wf_CurrentExecutor);		
			//---------------------------------------------------							
						
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
						System.out.println("VacationWfThread done with auto commitStep() call ["
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
										"requestVaction.jsp?stepId=" + tempStep.getObjectId()
										+ "&op=" + OP_ARRAY[nextIndex++]);
								fsMgr.commit(tempStep);
							}
						}
					}	// END: while TRUE loop to process my active step
					//By Perry:Send the email notification to executor.
					//flowObj = (PstFlow)fMgr.get(m_pstuser, (String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0]);
					//PrmWf.notifyExecutor(m_pstuser,flowObj,"VacationApplication");				
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
								flowDataObj.setAttribute("string13",m_sign1);
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
		    //--------------Perry Insert into my DB.------------	
			wf_FlowDataid=(String)flowDataObj.getAttribute("string22")[0];//(String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0];//(String)flowObj.getAttribute(PstFlow.CONTEXT_OBJECT)[0];
			wf_stepid=tempStep.getObjectName();
			if (OP_ARRAY[nextIndex-1] == WF_OP_DEPT_GM_APPROVE) {
			wf_opcode=String.valueOf(WF_OP_ADMIN_GM_APPROVE);
			}
			else{
			wf_opcode="";
			}
			wf_CurrentExecutor=tempStep.getCurrentExecutor();
			if (wf_stepid==null) wf_stepid="null";
			if (wf_CurrentExecutor==null) wf_CurrentExecutor="null";
			DBAccess.Update(wf_FlowDataid,"","","","","","","","","","","","","",wf_opcode,"",wf_stepid,wf_CurrentExecutor,"","","","","","","","","","","","","","","","","","");	
		    //DBAccess.Update(myFlowDOId,m_gonghao,wf_owner,my_dept,m_up_files,m_va_type,m_time_start,vacation_time_old,m_day_va_finish,m_day_va_left,m_location,m_memo,THIS_WF_APP_NAME,wf_users,wf_opcode,wf_floadid,wf_stepid,wf_CurrentExecutor,is_shenqing,change_type,change_reason,change_notice,wf_status,vacation_time_qixin,back_time_type,back_time,back_time_memo,modify_user,shenqing_time,modify_user_shenqin,modify_shenqin_time,is_reject,Flowdata_old,back_time_finished,change_finished,back_time_old);
		    //System.out.println("---!!wf_FlowDataid:"+wf_FlowDataid);
			//---------------------------------------------------										
									tempStep.setAttribute("Application",
											"requestVaction.jsp?stepId=" + tempStep.getObjectId()
											+ "&op=" + OP_ARRAY[nextIndex++] );
									fsMgr.commit(tempStep);								
									
								}
							}
							
							// auto commit
							// check to commit any steps that have been committed by previous approvers
							// refreshStep is the last committed step.
							stepObj = getAutoCommitStep(refreshStep, nextStepObjList, flowDataObj, nextIndex);//Perry-Vacation:Disabled the autocommit
							//stepObj = null;//Perry-Vacation:Disabled the autocommit
						}	// END: while loop to commit my connected steps
					}	// END: if approve
					
					// backward to request for more info from last executor
					else if(m_status.equalsIgnoreCase("backward")) {
						myFlowDOId = workObj.getObjectName() + new Date().getTime();
						flowDataObj = (PstFlowDataObject)fdMgr.create(m_pstuser, myFlowDOId, "VacationApplication");
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
							PrmWf.notifyReject(flowDataObj,m_deptApproval);
		    //--------------Perry Insert into my DB.------------	
			wf_FlowDataid=(String)flowDataObj.getAttribute("string22")[0];//(String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0];//(String)flowObj.getAttribute(PstFlow.CONTEXT_OBJECT)[0];
			DBAccess.Update(wf_FlowDataid,"","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","1","","","","");	
		    //DBAccess.Update(myFlowDOId,m_gonghao,wf_owner,my_dept,m_up_files,m_va_type,m_time_start,vacation_time_old,m_day_va_finish,m_day_va_left,m_location,m_memo,THIS_WF_APP_NAME,wf_users,wf_opcode,wf_floadid,wf_stepid,wf_CurrentExecutor,is_shenqing,change_type,change_reason,change_notice,wf_status,vacation_time_qixin,back_time_type,back_time,back_time_memo,modify_user,shenqing_time,modify_user_shenqin,modify_shenqin_time,is_reject,Flowdata_old,back_time_finished,change_finished,back_time_old);
		    //System.out.println("---!!wf_FlowDataid:"+wf_FlowDataid);
			//---------------------------------------------------													
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
								flowDataObj.setAttribute("string14",m_sign2);
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
												"requestVaction.jsp?stepId=" + tempStep.getObjectId()
												+ "&op=" + OP_ARRAY[nextIndex++] );
										fsMgr.commit(tempStep);
		    //--------------Perry Insert into my DB.------------	
			wf_FlowDataid=(String)flowDataObj.getAttribute("string22")[0];//(String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0];//(String)flowObj.getAttribute(PstFlow.CONTEXT_OBJECT)[0];
			wf_opcode=String.valueOf(WF_OP_IT_GM_APPROVE);
			wf_stepid=tempStep.getObjectName();
			wf_CurrentExecutor=tempStep.getCurrentExecutor();
			if (wf_stepid==null) wf_stepid="null";
			if (wf_CurrentExecutor==null) wf_CurrentExecutor="null";			
			DBAccess.Update(wf_FlowDataid,"","","","","","","","","","","","","",wf_opcode,"",wf_stepid,wf_CurrentExecutor,"","","","","","","","","","","","","","","","","","");	
		    //DBAccess.Update(myFlowDOId,m_gonghao,wf_owner,my_dept,m_up_files,m_va_type,m_time_start,vacation_time_old,m_day_va_finish,m_day_va_left,m_location,m_memo,THIS_WF_APP_NAME,wf_users,wf_opcode,wf_floadid,wf_stepid,wf_CurrentExecutor,is_shenqing,change_type,change_reason,change_notice,wf_status,vacation_time_qixin,back_time_type,back_time,back_time_memo,modify_user,shenqing_time,modify_user_shenqin,modify_shenqin_time,is_reject,Flowdata_old,back_time_finished,change_finished,back_time_old);
		    //System.out.println("---!!wf_FlowDataid:"+wf_FlowDataid);
			//---------------------------------------------------												
									}
								}

								
								// auto commit
								// check to commit any steps that have been committed by previous approvers
								// refreshStep is the last committed step.
								//stepObj = getAutoCommitStep(refreshStep, nextStepObjList, flowDataObj, nextIndex);//Perry-Vacation:Disabled the autocommit
								stepObj = null;//Perry-Vacation:Disabled the autocommit
							}	// END: while
						}	// END: if approve
						
						// backward to request for more info from last executor
						else if(m_status.equalsIgnoreCase("backward")) {
							myFlowDOId = workObj.getObjectName() + new Date().getTime();
							flowDataObj = (PstFlowDataObject)fdMgr.create(m_pstuser, myFlowDOId, "VacationApplication");
							stepObj.abortStep(m_pstuser, flowDataObj);	// abort the step (move backward on step)
						}
						
						// total reject
						else if(m_status.equalsIgnoreCase("abort")) {
							// save comments
							writeComment(flowDataObj, m_adminApproval, COMMENT_ADMIN);
							fdMgr.commit(flowDataObj);

							if(stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0] != null) {
								flowObj = (PstFlow)fMgr.get(m_pstuser, (String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0]);
								flowObj.abortFlow(m_pstuser);
								PrmWf.notifyReject(flowDataObj,m_adminApproval);
		    //--------------Perry Insert into my DB.------------	
			wf_FlowDataid=(String)flowDataObj.getAttribute("string22")[0];//(String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0];//(String)flowObj.getAttribute(PstFlow.CONTEXT_OBJECT)[0];
			DBAccess.Update(wf_FlowDataid,"","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","1","","","","");	
		    //DBAccess.Update(myFlowDOId,m_gonghao,wf_owner,my_dept,m_up_files,m_va_type,m_time_start,vacation_time_old,m_day_va_finish,m_day_va_left,m_location,m_memo,THIS_WF_APP_NAME,wf_users,wf_opcode,wf_floadid,wf_stepid,wf_CurrentExecutor,is_shenqing,change_type,change_reason,change_notice,wf_status,vacation_time_qixin,back_time_type,back_time,back_time_memo,modify_user,shenqing_time,modify_user_shenqin,modify_shenqin_time,is_reject,Flowdata_old,back_time_finished,change_finished,back_time_old);
		    //System.out.println("---!!wf_FlowDataid:"+wf_FlowDataid);
			//---------------------------------------------------										
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
								flowDataObj.setAttribute("string15", m_sign3);
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
												"requestVaction.jsp?stepId=" + tempStep.getObjectId()
												+ "&op=" + OP_ARRAY[nextIndex++] );
										fsMgr.commit(tempStep);
		    //--------------Perry Insert into my DB.------------	
			wf_FlowDataid=(String)flowDataObj.getAttribute("string22")[0];//(String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0];//(String)flowObj.getAttribute(PstFlow.CONTEXT_OBJECT)[0];
			wf_opcode=String.valueOf(WF_OP_IT_HANDLE_INFORM);
			wf_stepid=tempStep.getObjectName();
			wf_CurrentExecutor=tempStep.getCurrentExecutor();
			if (wf_stepid==null) wf_stepid="null";
			if (wf_CurrentExecutor==null) wf_CurrentExecutor="null";			
			DBAccess.Update(wf_FlowDataid,"","","","","","","","","","","","","",wf_opcode,"",wf_stepid,wf_CurrentExecutor,"","","","","","","","","","","","","","","","","","");	
		    //DBAccess.Update(myFlowDOId,m_gonghao,wf_owner,my_dept,m_up_files,m_va_type,m_time_start,vacation_time_old,m_day_va_finish,m_day_va_left,m_location,m_memo,THIS_WF_APP_NAME,wf_users,wf_opcode,wf_floadid,wf_stepid,wf_CurrentExecutor,is_shenqing,change_type,change_reason,change_notice,wf_status,vacation_time_qixin,back_time_type,back_time,back_time_memo,modify_user,shenqing_time,modify_user_shenqin,modify_shenqin_time,is_reject,Flowdata_old,back_time_finished,change_finished,back_time_old);
		    //System.out.println("---!!wf_FlowDataid:"+wf_FlowDataid);
			//---------------------------------------------------												
									}
								}

								
								// auto commit
								// check to commit any steps that have been committed by previous approvers
								// refreshStep is the last committed step.
								//stepObj = getAutoCommitStep(refreshStep, nextStepObjList, flowDataObj, nextIndex);//Perry-Vacation:Disabled the autocommit
								stepObj = null;//Perry-Vacation:Disabled the autocommit
							}
						}

						// backward to request for more info from last executor
						else if(m_status.equalsIgnoreCase("backward")) {
							myFlowDOId = workObj.getObjectName() + new Date().getTime();
							flowDataObj = (PstFlowDataObject)fdMgr.create(m_pstuser, myFlowDOId, "VacationApplication");
							stepObj.abortStep(m_pstuser, flowDataObj);	// abort the step (move backward on step)
						}

						// total reject
						else if(m_status.equalsIgnoreCase("abort")) {
							// save comments
							writeComment(flowDataObj, m_itApproval, COMMENT_IT);
							fdMgr.commit(flowDataObj);

							if(stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0] != null) {
								flowObj = (PstFlow)fMgr.get(m_pstuser, (String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0]);
								flowObj.abortFlow(m_pstuser);
								PrmWf.notifyReject(flowDataObj,m_itApproval);
		    //--------------Perry Insert into my DB.------------	
			wf_FlowDataid=(String)flowDataObj.getAttribute("string22")[0];//(String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0];//(String)flowObj.getAttribute(PstFlow.CONTEXT_OBJECT)[0];
			DBAccess.Update(wf_FlowDataid,"","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","1","","","","");	
		    //DBAccess.Update(myFlowDOId,m_gonghao,wf_owner,my_dept,m_up_files,m_va_type,m_time_start,vacation_time_old,m_day_va_finish,m_day_va_left,m_location,m_memo,THIS_WF_APP_NAME,wf_users,wf_opcode,wf_floadid,wf_stepid,wf_CurrentExecutor,is_shenqing,change_type,change_reason,change_notice,wf_status,vacation_time_qixin,back_time_type,back_time,back_time_memo,modify_user,shenqing_time,modify_user_shenqin,modify_shenqin_time,is_reject,Flowdata_old,back_time_finished,change_finished,back_time_old);
		    //System.out.println("---!!wf_FlowDataid:"+wf_FlowDataid);
			//---------------------------------------------------										
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
                         String [] temp_array;//For my DB.
							// commit the step
							nextIndex = 5;		// next step
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
								flowDataObj.setAttribute("string16",m_sign4);
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
												"requestVaction.jsp?stepId=" + tempStep.getObjectId()
												+ "&op=" + OP_ARRAY[nextIndex++] );
										fsMgr.commit(tempStep);
		    //--------------Perry Insert into my DB.------------	
			wf_FlowDataid=(String)flowDataObj.getAttribute("string22")[0];//(String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0];//(String)flowObj.getAttribute(PstFlow.CONTEXT_OBJECT)[0];
			wf_opcode=String.valueOf(WF_OP_VACATION_ATTENDANCE);
			wf_stepid=tempStep.getObjectName();
			wf_CurrentExecutor=tempStep.getCurrentExecutor();
			if (wf_stepid==null) wf_stepid="null";
			if (wf_CurrentExecutor==null) wf_CurrentExecutor="null";			
			if (m_handleApproval.indexOf("提前")>0) back_time_type="1";
			if (m_handleApproval.indexOf("推迟")>0) back_time_type="2";
			temp_array = m_handleApproval.split(",");
			back_time=temp_array[1].trim().replace("返岗时间：","");
			DBAccess.Update(wf_FlowDataid,"","","","","","","","","","","","","",wf_opcode,"",wf_stepid,wf_CurrentExecutor,"","","","","","",back_time_type,back_time,"","","","","","","","","","");	
		    //DBAccess.Update(myFlowDOId,m_gonghao,wf_owner,my_dept,m_up_files,m_va_type,m_time_start,vacation_time_old,m_day_va_finish,m_day_va_left,m_location,m_memo,THIS_WF_APP_NAME,wf_users,wf_opcode,wf_floadid,wf_stepid,wf_CurrentExecutor,is_shenqing,change_type,change_reason,change_notice,wf_status,vacation_time_qixin,back_time_type,back_time,back_time_memo,modify_user,shenqing_time,modify_user_shenqin,modify_shenqin_time,is_reject,Flowdata_old,back_time_finished,change_finished,back_time_old);
		    //System.out.println("---!!wf_FlowDataid:"+wf_FlowDataid);
			//---------------------------------------------------
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
							flowDataObj = (PstFlowDataObject)fdMgr.create(m_pstuser, myFlowDOId, "VacationApplication");
							stepObj.abortStep(m_pstuser, flowDataObj);	// abort the step (move backward on step)
						}

						// total reject
						else if(m_status.equalsIgnoreCase("abort")) {
							// save comments
							writeComment(flowDataObj, m_handleApproval, COMMENT_HANDLE);
							fdMgr.commit(flowDataObj);

							if(stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0] != null) {
								flowObj = (PstFlow)fMgr.get(m_pstuser, (String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0]);
								flowObj.abortFlow(m_pstuser);
								PrmWf.notifyReject(flowDataObj,m_handleApproval);
		    //--------------Perry Insert into my DB.------------	
			wf_FlowDataid=(String)flowDataObj.getAttribute("string22")[0];//(String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0];//(String)flowObj.getAttribute(PstFlow.CONTEXT_OBJECT)[0];
			DBAccess.Update(wf_FlowDataid,"","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","1","","","","");	
		    //DBAccess.Update(myFlowDOId,m_gonghao,wf_owner,my_dept,m_up_files,m_va_type,m_time_start,vacation_time_old,m_day_va_finish,m_day_va_left,m_location,m_memo,THIS_WF_APP_NAME,wf_users,wf_opcode,wf_floadid,wf_stepid,wf_CurrentExecutor,is_shenqing,change_type,change_reason,change_notice,wf_status,vacation_time_qixin,back_time_type,back_time,back_time_memo,modify_user,shenqing_time,modify_user_shenqin,modify_shenqin_time,is_reject,Flowdata_old,back_time_finished,change_finished,back_time_old);
		    //System.out.println("---!!wf_FlowDataid:"+wf_FlowDataid);
			//---------------------------------------------------									
							}
						}

						/////////// Return RC
						m_rc1 = new Integer(currentFlowName);	// return the current flow id
						break;
						
					///////////////////////VACATION///////////////////////////////////////////
					// 6. case WF_OP_VACATION_ATTENDANCE:
					case WF_OP_VACATION_ATTENDANCE:
						System.out.println("--- WF_OP_VACATION_ATTENDANCE: " + m_status);

						currentFlowName = (String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0];

						if (m_status.length()<=0) m_status = "commit";	// force commit (approve)

						// approve
						if (m_status.equalsIgnoreCase("commit"))
						{
							// update the application's work object

							// commit the step
							nextIndex = 6;		// next step
							count = 0;
							while (stepObj != null) {
								System.out.println("==== in stepObj! = null  =====");
								myFlowDOId = String.valueOf(new Date().getTime() + count++);
								//flowDataObj = (PstFlowDataObject) fdMgr.get(m_pstuser, flowDataId);

								//flowDataObj.setAttribute("string2", workObj.getObjectName());
								System.out.println("dept members: " + m_deptApproval + "\t" + m_deptApprovalDate);
								System.out.println("admin members: " + m_adminApproval + "\t" + m_adminApprovalDate);
								//flowDataObj.setAttribute("string6",m_handleApproval);
								writeComment(flowDataObj ,m_attendanceApproval, COMMENT_ATTENDANCE);
								flowDataObj.setAttribute("date5",m_attendanceApprovalDate);
								flowDataObj.setAttribute("string17",m_sign5);
								stepObj.commitStep(m_pstuser, flowDataObj);	// COMMIT with approve
								
		   /* //--------------Perry Insert into my DB.最后一个STEP不需要更新------------	
			wf_FlowDataid=(String)flowDataObj.getAttribute("string22")[0];//(String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0];//(String)flowObj.getAttribute(PstFlow.CONTEXT_OBJECT)[0];
			wf_opcode=String.valueOf(WF_OP_VACATION_CHECK_DEPT);
			wf_stepid=stepObj.getObjectName();
			wf_CurrentExecutor=stepObj.getCurrentExecutor();
			DBAccess.Update(wf_FlowDataid,"","","","","","","","","","","","","",wf_opcode,"",wf_stepid,wf_CurrentExecutor,"","","","","","","","","","","","","","","","","","");	
		    //DBAccess.Update(myFlowDOId,m_gonghao,wf_owner,my_dept,m_up_files,m_va_type,m_time_start,vacation_time_old,m_day_va_finish,m_day_va_left,m_location,m_memo,THIS_WF_APP_NAME,wf_users,wf_opcode,wf_floadid,wf_stepid,wf_CurrentExecutor,is_shenqing,change_type,change_reason,change_notice,wf_status,vacation_time_qixin,back_time_type,back_time,back_time_memo,modify_user,shenqing_time,modify_user_shenqin,modify_shenqin_time,is_reject,Flowdata_old,back_time_finished,change_finished,back_time_old);
		    //System.out.println("---!!wf_FlowDataid:"+wf_FlowDataid);
			//---------------------------------------------------*/									

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
												"requestVaction.jsp?stepId=" + tempStep.getObjectId()
												+ "&op=" + OP_ARRAY[nextIndex++] );
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
							flowDataObj = (PstFlowDataObject)fdMgr.create(m_pstuser, myFlowDOId, "VacationApplication");
							stepObj.abortStep(m_pstuser, flowDataObj);	// abort the step (move backward on step)
						}

						// total reject
						else if(m_status.equalsIgnoreCase("abort")) {
							// save comments
							writeComment(flowDataObj ,m_attendanceApproval, COMMENT_ATTENDANCE);
							fdMgr.commit(flowDataObj);

							if(stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0] != null) {
								flowObj = (PstFlow)fMgr.get(m_pstuser, (String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0]);
								flowObj.abortFlow(m_pstuser);
								PrmWf.notifyReject(flowDataObj,m_attendanceApproval);
		    //--------------Perry Insert into my DB.------------	
			wf_FlowDataid=(String)flowDataObj.getAttribute("string22")[0];//(String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0];//(String)flowObj.getAttribute(PstFlow.CONTEXT_OBJECT)[0];
			DBAccess.Update(wf_FlowDataid,"","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","1","","","","");	
		    //DBAccess.Update(myFlowDOId,m_gonghao,wf_owner,my_dept,m_up_files,m_va_type,m_time_start,vacation_time_old,m_day_va_finish,m_day_va_left,m_location,m_memo,THIS_WF_APP_NAME,wf_users,wf_opcode,wf_floadid,wf_stepid,wf_CurrentExecutor,is_shenqing,change_type,change_reason,change_notice,wf_status,vacation_time_qixin,back_time_type,back_time,back_time_memo,modify_user,shenqing_time,modify_user_shenqin,modify_shenqin_time,is_reject,Flowdata_old,back_time_finished,change_finished,back_time_old);
		    //System.out.println("---!!wf_FlowDataid:"+wf_FlowDataid);
			//---------------------------------------------------										
							}
						}

						/////////// Return RC
						m_rc1 = new Integer(currentFlowName);	// return the current flow id
						break;
						
					//////////////////////////////////////////////////////////////////
					// 7. case WF_OP_VACATION_CHECK_DEPT:
					case WF_OP_VACATION_CHECK_DEPT:
						System.out.println("--- WF_OP_VACATION_CHECK_DEPT: " + m_status);

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
								writeComment(flowDataObj, m_checkdeptApproval, COMMENT_CHECK_DEPT);
								flowDataObj.setAttribute("date6",m_checkdeptApprovalDate);
								flowDataObj.setAttribute("string18",m_sign6);
								stepObj.commitStep(m_pstuser, flowDataObj);	// COMMIT with approve
								
		    //--------------Perry Insert into my DB.------------	
			wf_FlowDataid=(String)flowDataObj.getAttribute("string22")[0];//(String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0];//(String)flowObj.getAttribute(PstFlow.CONTEXT_OBJECT)[0];
			wf_opcode="108";//String.valueOf(WF_OP_VACATION_CHECK_DEPT);
			wf_stepid=stepObj.getObjectName();
			wf_CurrentExecutor=stepObj.getCurrentExecutor();
			DBAccess.Update(wf_FlowDataid,"","","","","","","","","","","","","",wf_opcode,"",wf_stepid,wf_CurrentExecutor,"","","","","","","","","","","","","","","","","","");	
		    //DBAccess.Update(myFlowDOId,m_gonghao,wf_owner,my_dept,m_up_files,m_va_type,m_time_start,vacation_time_old,m_day_va_finish,m_day_va_left,m_location,m_memo,THIS_WF_APP_NAME,wf_users,wf_opcode,wf_floadid,wf_stepid,wf_CurrentExecutor,is_shenqing,change_type,change_reason,change_notice,wf_status,vacation_time_qixin,back_time_type,back_time,back_time_memo,modify_user,shenqing_time,modify_user_shenqin,modify_shenqin_time,is_reject,Flowdata_old,back_time_finished,change_finished,back_time_old);
		    //System.out.println("---!!wf_FlowDataid:"+wf_FlowDataid);
			//---------------------------------------------------									

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
							flowDataObj = (PstFlowDataObject)fdMgr.create(m_pstuser, myFlowDOId, "VacationApplication");
							stepObj.abortStep(m_pstuser, flowDataObj);	// abort the step (move backward on step)
						}

						// total reject
						else if(m_status.equalsIgnoreCase("abort")) {
							// save comments
							writeComment(flowDataObj, m_checkdeptApproval, COMMENT_CHECK_DEPT);
							fdMgr.commit(flowDataObj);

							if(stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0] != null) {
								flowObj = (PstFlow)fMgr.get(m_pstuser, (String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0]);
								flowObj.abortFlow(m_pstuser);
								PrmWf.notifyReject(flowDataObj,m_checkdeptApproval);
		    //--------------Perry Insert into my DB.------------	
			wf_FlowDataid=(String)flowDataObj.getAttribute("string22")[0];//(String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0];//(String)flowObj.getAttribute(PstFlow.CONTEXT_OBJECT)[0];
			DBAccess.Update(wf_FlowDataid,"","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","1","","","","");	
		    //DBAccess.Update(myFlowDOId,m_gonghao,wf_owner,my_dept,m_up_files,m_va_type,m_time_start,vacation_time_old,m_day_va_finish,m_day_va_left,m_location,m_memo,THIS_WF_APP_NAME,wf_users,wf_opcode,wf_floadid,wf_stepid,wf_CurrentExecutor,is_shenqing,change_type,change_reason,change_notice,wf_status,vacation_time_qixin,back_time_type,back_time,back_time_memo,modify_user,shenqing_time,modify_user_shenqin,modify_shenqin_time,is_reject,Flowdata_old,back_time_finished,change_finished,back_time_old);
		    //System.out.println("---!!wf_FlowDataid:"+wf_FlowDataid);
			//---------------------------------------------------											
							}
						}

						/////////// Return RC
						m_rc1 = new Integer(currentFlowName);	// return the current flow id
						break;												
						
				default:
					break;
			}
			
			// send email to executors of the next active steps
			if (m_op<WF_OP_VACATION_ATTENDANCE && currentFlowName != null && !m_status.equalsIgnoreCase("abort")) {
			System.out.println("Ready to send email,currentFlowName="+currentFlowName);
				PstFlow currentFlow = (PstFlow) fMgr.get(m_pstuser,currentFlowName);
				PrmWf.notifyExecutor(m_pstuser,flowDataObj,currentFlow,THIS_WF_APP_NAME);
			}
		}
		catch (Exception e)
		{
			m_rc1 = new Integer(-1);		// error
			System.out.println(e.toString());
			e.printStackTrace();
			m_exception = e;
		}
		System.out.println("<=== VacationWfThread run exited");
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
				/*if (StringUtil.isNullOrEmptyString(executorIdS)) {
					// send email to our WF admin person to handle separately
				Notify send_email = new Notify();
				send_email.SendEmail("notify_wf@hku-szh.org","perryc@hku-szh.org","PC Request(WF)-no executor","StepName:"+m_stepName);
					continue;
				}*/
				if (flowObj.isPreviousExecutor(executorIdS) ||
						flowObj.getStringAttribute(PstFlow.OWNER).equals(executorIdS)) {
					// auto commit
					System.out.println("+++ case 4: auto commit step ["
							+ aStep.getObjectId() + "] - found previous exector ["
							+ executorIdS + "]");
					aStep.setAttribute(PstFlowStep.CURRENT_EXECUTOR, "-1");
					fsMgr.commit(aStep);
		    //--------------Perry Insert into my DB.------------	
			wf_FlowDataid=(String)flowDataObj.getAttribute("string22")[0];//(String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0];//(String)flowObj.getAttribute(PstFlow.CONTEXT_OBJECT)[0];
			wf_opcode=String.valueOf(OP_ARRAY[nextIndex]);
			wf_stepid=aStep.getObjectName();
			wf_CurrentExecutor=executorIdS;//aStep.getCurrentExecutor();
			DBAccess.Update(wf_FlowDataid,"","","","","","","","","","","","","",wf_opcode,"",wf_stepid,wf_CurrentExecutor,"","","","","","","","","","","","","","","","","","");	
		    //DBAccess.Update(myFlowDOId,m_gonghao,wf_owner,my_dept,m_up_files,m_va_type,m_time_start,vacation_time_old,m_day_va_finish,m_day_va_left,m_location,m_memo,THIS_WF_APP_NAME,wf_users,wf_opcode,wf_floadid,wf_stepid,wf_CurrentExecutor,is_shenqing,change_type,change_reason,change_notice,wf_status,vacation_time_qixin,back_time_type,back_time,back_time_memo,modify_user);
		    //System.out.println("---!!wf_FlowDataid:"+wf_FlowDataid);
			//---------------------------------------------------						
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
		String uName =uObj.getStringAttribute("LastName")+uObj.getStringAttribute("FirstName");//uObj.getFullName();
		//System.out.println("+++ case 4: auto commit step Sign name-"+uName);
		//String comment = "*** Auto approval for [" + uName + "] ***";
		String comment = "同意";
		String strAttrName = null;
		String dtAttrName = null;
		String SignAttrName = null;		
		int iType = 0;
		
		switch (i) {
		case WF_OP_DEPT_GM_APPROVE:
			iType = COMMENT_DEPT;
			dtAttrName = "date1";
			SignAttrName = "string13";
			break;
			
		case WF_OP_ADMIN_GM_APPROVE:
			iType = COMMENT_ADMIN;
			dtAttrName = "date2";
			SignAttrName = "string14";
			break;
			
		case WF_OP_IT_GM_APPROVE:
			iType = COMMENT_IT;
			dtAttrName = "date3";
			SignAttrName = "string15";
			break;
			
		case WF_OP_IT_HANDLE_INFORM:
			iType = COMMENT_HANDLE;
			dtAttrName = "date4";
			SignAttrName = "string16";
			break;
			
		case WF_OP_VACATION_ATTENDANCE:
			iType = COMMENT_ATTENDANCE;
			dtAttrName = "date5";
			SignAttrName = "string17";
			break;
			
		case WF_OP_VACATION_CHECK_DEPT:
			iType = COMMENT_CHECK_DEPT;
			dtAttrName = "date6";
			SignAttrName = "string18";
			break;						
			
		default:
			return;
		}
		
		writeComment(flowDataObj, comment, iType);
		flowDataObj.setAttribute(dtAttrName, new Date());
		flowDataObj.setAttribute(SignAttrName,uName);
		fdMgr.commit(flowDataObj);
	}
	
	static class DBAccess {

		public static void Insert(String myFlowDOId, String m_gonghao,
				String wf_owner, String my_dept, String m_up_files,
				String m_va_type, String m_time_start_end, String string,
				String m_day_va_finish, String m_day_va_left,
				String m_location, String m_memo, String tHIS_WF_APP_NAME,
				String wf_users, String wf_opcode, String wf_floadid,
				String wf_stepid, String wf_CurrentExecutor) {
			// TODO Auto-generated method stub
			
		}

		public static void Update(String wf_FlowDataid, String string,
				String string2, String string3, String string4, String string5,
				String string6, String string7, String string8, String string9,
				String string10, String string11, String string12,
				String string13, String wf_opcode, String string14,
				String wf_stepid, String wf_CurrentExecutor, String string15,
				String string16, String string17, String string18,
				String string19, String string20, String string21,
				String string22, String string23, String string24,
				String string25, String string26, String string27,
				String string28, String string29, String string30,
				String string31, String string32) {
			// TODO Auto-generated method stub
			
		}
	}

}