
//
//	Copyright (c) 2005, EGI Technologies, Inc..  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	Final.java
//	Author:	ECC
//	Date:	03/19/03
//  Description:
//      Final Step to publish the latest plan and send e-mail for JW.
//
//	Modification:
//		@ECC071806	Expand Program Manager role to submit and auto-approve plan change.
//					In the case of admin and ProgMgr, the task owner will be set to
//					the project owner if they are not part of the proj team members.
//		@ECC011707	Support Department Name in project, task and attachment for authorization.
//
/////////////////////////////////////////////////////////////////////

package oct.codegen;
import java.util.Date;
import org.apache.log4j.Logger;

import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstFlowDataObject;
import oct.pst.PstFlowManager;
import oct.pst.PstFlowStep;
import oct.pst.PstFlowStepManager;
import oct.pst.PstSystem;
import util.PrmLog;
import util.WfThread;

public class Final
{
	private Logger l = PrmLog.getLog();
	
	public Boolean lastStep(PstFlowDataObject flowDataObj)
	{
		try
		{
			// Object [] orgnameArr = flowDataObj.getAttribute("string1");	// "project"
			Object [] memnameArr = flowDataObj.getAttribute("string2");	// the new plan Id

			planManager planMgr = planManager.getInstance();

			PstSystem pst = PstSystem.getInstance();
			plan newPlanObj = (plan)planMgr.get(pst, ((String)memnameArr[0]).toString());
			newPlanObj.setAttribute("Status", "Latest");
			newPlanObj.setAttribute("EffectiveDate", new Date());
			String ProjectID = (String)newPlanObj.getAttribute("ProjectID")[0];
			String Creator = (String)newPlanObj.getAttribute("Creator")[0];

			FlowDataManager fdMgr	= FlowDataManager.getInstance();
			PstFlowManager fiMgr	= PstFlowManager.getInstance();
			PstFlowStepManager fsMgr = PstFlowStepManager.getInstance();
			projectManager projMgr = projectManager.getInstance();
			taskManager tkMgr = taskManager.getInstance();
			planTaskManager planTaskMgr = planTaskManager.getInstance();

			// project
			project projObj = (project)projMgr.get(pst, Integer.parseInt(ProjectID));

			// delete all depreciated plan because I only want to keep two versions of plan
			int [] planIds = planMgr.findId(pst,
					"Status='Deprecated' && ProjectID='" +ProjectID+ "'");
			PstAbstractObject [] planList = planMgr.get(pst, planIds);
			for (int i=0; i<planList.length; i++) {
				// find all the plan task and delete them
				int planId = ((plan)planList[i]).getObjectId();
				int [] planTaskIds = planTaskMgr.findId(pst, "PlanID='" +planId+ "'");
				PstAbstractObject [] planTaskList = planTaskMgr.get(pst, planTaskIds);
				for (int j=0; j<planTaskList.length; j++) {
					planTaskMgr.delete(planTaskList[j]);
					l.info("Final: delete planTask [" + planTaskList[j].getObjectId() + "]");
				}

				// delete workflow obj: FlowData, PstFlow, PstFlowStep objects
				int [] ids = fdMgr.findId(pst, "string2='" + planId + "'");
				for (int j=0; j < ids.length; j++) {
					fdMgr.delete(fdMgr.get(pst, ids[j]));
				}
				int [] ids1 = fiMgr.findId(pst, "ContextObject='" + planId + "'");
				for (int j=0; j<ids1.length; j++) {
					int [] ids2 = fsMgr.findId(pst, "FlowInstanceName='" + ids1[j] + "'");
					for (int k=0; k < ids2.length; k++) {
						try {fsMgr.delete(fsMgr.get(pst, ids2[k]));}
						catch (PmpException e) {}
					}
					// need to delete the step instance first then delete the flow instance
					// otherwise we will fail to get the step instance
					fiMgr.delete(fiMgr.get(pst, ids1[j]));
				}

				// delete the plan
				planMgr.delete(planList[i]);
			}

			// Depreciate the old plan
			planIds = planMgr.findId(pst,
					"Status='Latest' && ProjectID='" +ProjectID+ "'");
			planList = planMgr.get(pst, planIds);
			// Because there is only one Plan which is latest
			plan oldPlanObj = (plan)planList[0];
			oldPlanObj.setAttribute("Status", "Deprecated");
			oldPlanObj.setAttribute("DeprecatedDate", new Date());

			// Get plan task.  Create task object if it is new.
			// get_plan_tasks: PlanID='$owner.om_acctname' && Status!='Deprecated'
			int [] ids = planTaskMgr.findId(pst, "PlanID='" + newPlanObj.getObjectId() + "'");
			PstAbstractObject [] newPlanTaskArr = planTaskMgr.get(pst, ids);

			// check to see if I am a project team member (e.g. admin or progMgr may not be a member)
			// if not, give ownership of the new tasks to proj coordinator
			String newTaskOwner = null;
			Object [] pjMembers = projObj.getAttribute("TeamMembers");
			int creatorId = Integer.parseInt(Creator);
			for (int i=0; i<pjMembers.length; i++)
			{
				if (creatorId == ((Integer)(pjMembers[i])).intValue())
				{
					newTaskOwner = Creator;
					break;
				}
			}
			if (newTaskOwner == null) newTaskOwner = (String)projObj.getAttribute("Owner")[0];

			Date expDate;
			Date now = new Date();
			java.text.SimpleDateFormat df = new java.text.SimpleDateFormat("MM/dd/yyyy");
			Date today = df.parse(df.format(new Date()));
			String deptName = (String)projObj.getAttribute("DepartmentName")[0];

			for(int i = 0; i < newPlanTaskArr.length; i++)
			{
				planTask ptObj = (planTask)newPlanTaskArr[i];

				String currentStatus = (String)ptObj.getAttribute("Status")[0];

				if (currentStatus.equals(planTask.ST_DEPRECATED)) {
					// delete the associated task step
					String tidS = (String)ptObj.getAttribute("TaskID")[0];
					task tObj = (task)tkMgr.get(pst, tidS);
					System.out.println("Found deprecated planTask [" + ptObj.getObjectId()
							+ "] for task [" + tidS + "] - check to remove task step");
					PstFlowStep step = tObj.getStep(pst);
					if (step != null) {
						fsMgr.delete(step);
						System.out.println("   Removed task step [" + step.getObjectId()
								+ "] for task [" + tidS + "]");
					}
					else {
						System.out.println("   No step to be removed.");
					}
				}
				else if (currentStatus.equals(task.NEW)) {
					// Create new task
					task taskobj = (task)tkMgr.create(pst);
					taskobj.setAttribute("CreatedDate", today);
					taskobj.setAttribute("Creator", Creator);
					taskobj.setAttribute("Status", "New");
					taskobj.setAttribute("Owner", newTaskOwner);
					taskobj.setAttribute("ProjectID", ProjectID);
					taskobj.setAttribute("DepartmentName", deptName);	// @ECC011707
					l.info("Final: created new task [" + taskobj.getObjectId()
							+ "] with planTask [" + ptObj.getObjectId() + "]");

					// set task dates
					if (!projObj.isContainer()) {
						Date pjExpire = null;
						int startGap = ((Integer)ptObj.getAttribute("int1")[0]).intValue();
						int length   = ((Integer)ptObj.getAttribute("int2")[0]).intValue();
						if (startGap>0 || length>0)
						{
							pjExpire = WfThread.setTaskDates(projObj, taskobj, startGap, length);
							if (pjExpire!=null && pjExpire.after((Date)projObj.getAttribute("ExpireDate")[0]))
							{
								projObj.setAttribute("ExpireDate", pjExpire);	// project deadline extended
								projMgr.commit(projObj);
							}
						}
						else
						{
							taskobj.setAttribute("StartDate", today);

							// get parent task expiration date as my expiration date
							// if no parent, use project expiration date
							expDate = null;
							String parentIdS = (String)ptObj.getAttribute("ParentID")[0];
							if (parentIdS != null && !parentIdS.equals("0"))
							{
								planTask pt = (planTask)planTaskMgr.get(pst, parentIdS);
								String tkIdS = (String)pt.getAttribute("TaskID")[0];
								if (tkIdS != null)
								{
									task t = (task)tkMgr.get(pst, tkIdS);
									expDate = (Date)t.getAttribute("ExpireDate")[0];
								}
							}
							if (expDate == null)
							{
								// whatever the reason, simply use project expiration date
								expDate = (Date)projObj.getAttribute("ExpireDate")[0];
							}
							if (expDate.before(today)) {
								expDate = today;
							}
							taskobj.setAttribute("ExpireDate", expDate);
						}
						taskobj.setAttribute("OriginalStartDate", taskobj.getStartDate());
						taskobj.setAttribute("OriginalExpireDate", taskobj.getExpireDate());

						// make sure I don't need to move project expire date
						pjExpire = projObj.getExpireDate();
						if (pjExpire.before(taskobj.getExpireDate())) {
							projObj.setAttribute("ExpireDate", taskobj.getExpireDate());	// move forward
							if (projObj.getState().equals(project.ST_LATE) && projObj.getExpireDate().after(today)) {
								projObj.setState(pst, project.ST_OPEN);	// re-open
							}
						}
					}	// END if !isContainer project, set task dates

					taskobj.setAttribute("LastUpdatedDate", now);
					tkMgr.commit(taskobj);

					// point planTask to the new TaskID
					l.info("Final: point planTask [" + ptObj.getObjectId() + "] to new task");
					l.info("       old Tid=" + ptObj.getStringAttribute("TaskID")
							+ "; new Tid=" + taskobj.getObjectName());
					ptObj.setAttribute("TaskID", taskobj.getObjectName());
					planTaskMgr.commit(ptObj);
				}
			}


			planMgr.commit(oldPlanObj);			// commit the last plan
			planMgr.commit(newPlanObj);			// commit the new plan

			// update project version number
			projObj.setAttribute("Version", (String)newPlanObj.getAttribute("Version")[0]);
			projObj.setAttribute("LastUpdatedDate", now);
			projMgr.commit(projObj);

			System.out.println(">>> Plugin class Final.lastStep() is done!");
			return new Boolean(true);

		}
		catch(Exception e)
		{
			e.printStackTrace();
			System.out.println("false!!");
			return new Boolean(false);
		}
	}
}
