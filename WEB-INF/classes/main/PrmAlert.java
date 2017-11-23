
//
//  Copyright (c) 2009, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   PrmAlert.java
//  Author:	ECC
//  Date:   05/15/04
//  Description:
//			Background work to check and send alert messages.
//			- at night: close meetings, cleanup meetings, etc.
//			- sends reminder email at night for meetings and quests
//
//  Modification:
//		@110705ECC	Add option to link a Phase or Sub-phase to Task.
//		@ECC112405	Added Duration and Gap to task.  Need to check for Dependency fulfillment
//					before starting a task.
//		@AGQ042706	Changed phase to support phase object
//		@AGQ042706a	Removed code to alert start of an milestone
//		@SWS060206  Filter out deprecated tasks for update status
//		@ECC120106	Send reminder email to invitees the night before the meeting
//		@ECC061308	Send reminder email to invitees the night before for events and questionnaire
//		@ECC112309	Send reminder email for special days and holidays.
//
/////////////////////////////////////////////////////////////////////
//
// PrmAlert.java : implementation of the PrmAlert class for PRM
//

package main;

import java.io.File;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;

import oct.codegen.action;
import oct.codegen.actionManager;
import oct.codegen.day;
import oct.codegen.dayManager;
import oct.codegen.meeting;
import oct.codegen.meetingManager;
import oct.codegen.memo;
import oct.codegen.memoManager;
import oct.codegen.phase;
import oct.codegen.phaseManager;
import oct.codegen.planTask;
import oct.codegen.planTaskManager;
import oct.codegen.project;
import oct.codegen.projectManager;
import oct.codegen.quest;
import oct.codegen.questManager;
import oct.codegen.resultManager;
import oct.codegen.task;
import oct.codegen.taskManager;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.codegen.userinfo;
import oct.codegen.userinfoManager;
import oct.pmp.exception.PmpException;
import oct.pmp.exception.PmpObjectNotFoundException;
import oct.pst.PstAbstractObject;
import oct.pst.PstFlowStep;
import oct.pst.PstFlowStepManager;
import oct.pst.PstManager;
import oct.pst.PstUserAbstractObject;

import org.apache.log4j.Logger;

import util.Prm;
import util.PrmLog;
import util.PrmUpdateCounter;
import util.StringUtil;
import util.TaskInfo;
import util.Util;
import util.Util2;
import util.Util3;

public class PrmAlert
{
	static final String APPS = Prm.getAppTitle();
	static final String PH_ALERT_SUBJ = "[" + APPS + "] Milestone: ";
	static final String PROJ_ALERT_SUBJ = "[" + APPS + "] Project: ";
	static final String ACTION_ALERT_SUBJ = "[" + APPS + "] action item ";
	static final String TASK_ALERT_SUBJ = "[" + APPS + "] Task: ";
	static final String FROM = Util.getPropKey("pst", "FROM");
	static final String HOST = Util.getPropKey("pst", "PRM_HOST");
	static final String SEND_TASK_ALERT_OPEN = Util.getPropKey("pst", "SEND_TASK_ALERT_OPEN");
	static final String MTG_FINISH_TO_CLOSE = Util.getPropKey("pst", "MTG_FINISH_TO_CLOSE");
	static final String CAL_PATH = Util.getPropKey("pst", "CALENDAR_FILE_PATH");
	static final String SHOW_FILE_PATH = Util.getPropKey("pst", "SHOW_FILE_PATH");
	static final String MAILFILE = "alert.htm";

	static final boolean isCRAPP = (APPS.contains("CR"));

	// make sure userinfo of the special user has the following labels and timestamps
	public static final String PJ_ALERT	= "ProjectAlert";
	static final String MTG_CLEANUP	= "MeetingCleanup";
	static final String STAT_ACTIVITY = "StatActivity";

	static final int PJ_WORK_HOUR	= 1;			// 1 AM
	static final int MTG_WORK_HOUR	= 3;			// 3 AM
	static final long ONE_HOUR		= 3600000;
	static final long ONE_DAY		= 24 * ONE_HOUR;
	static final long TWO_WEEKS		= 14 * ONE_DAY;
	static final long FOUR_WEEKS	= 2 * TWO_WEEKS;
	static final long FIVE_HOURS	= 5 * ONE_HOUR;
	static final long MTG_CLOSE_TIME= Long.parseLong(MTG_FINISH_TO_CLOSE) * ONE_DAY;

	static projectManager pjMgr = PrmThread.getpjMgr();
	static taskManager tkMgr = PrmThread.gettkMgr();
	static planTaskManager ptMgr = PrmThread.getptMgr();
	static resultManager rsMgr = PrmThread.getrsMgr();
	static userinfoManager uiMgr = PrmThread.getuiMgr();
	static userManager uMgr = PrmThread.getuMgr();
	static actionManager aMgr = PrmThread.getaMgr();
	static memoManager mmMgr = PrmThread.getmmMgr();
	static meetingManager mtgMgr = PrmThread.getmtgMgr();
	static phaseManager phMgr = PrmThread.getphMgr();
	static questManager qMgr = PrmThread.getqMgr();
	static PstFlowStepManager fsMgr = PrmThread.getfsMgr();
	static dayManager dMgr;

	static SimpleDateFormat df = new java.text.SimpleDateFormat("MM/dd/yyyy");
	static user jwu = PrmThread.getuser();

	static DateFormat DF = DateFormat.getDateInstance(DateFormat.SHORT);
	static long thisMoment;
	static Date now;			// the date at the current hour when the background thread runs
	static Date today;			// the date at 0:0:0
	static Date yesterday;

	static Logger l = PrmLog.getLog();

	static {
		try {
			dMgr = dayManager.getInstance();
		}
		catch (PmpException e){}
	}

	public static int projTaskAlert(boolean bTest)
		throws Exception
	{
		// for each project, check the alert condition and trigger alert msg
		// for each task, check the alert condition and trigger alert msg
		now = new Date();
		//today = DF.parse(df.format(now));	// just the date
		today = df.parse(df.format(now));	// just the date
		yesterday = new Date(today.getTime() - ONE_DAY);

		if (!bTest && !isTime(PJ_ALERT, PJ_WORK_HOUR, null))
			return 0;

		////////////////////////////////////////////////////////////////
		// Need to work
		l.info("*** PrmThread " + PJ_ALERT + " starts");
		PrmThread.lateProjNum = 0;
		PrmThread.lateTaskNum = 0;
		PrmThread.openProjNum = 0;
		PrmThread.openTaskNum = 0;
		PrmThread.taskAlertNum = 0;
		PrmThread.projAlertNum = 0;
		PrmThread.lateActionNum = 0;
		PrmThread.delMemoNum = 0;

		// now check each project and task

		// policy follows:
		// for each project and task, check to see if alert condition is set
		// follow the alert condition to send alert (email and web) messages

		// for every project
		int [] pjids = pjMgr.findId(jwu, "om_acctname='%'");	// 1=Never
		project pj = null;
		for (int i=0; i<pjids.length; i++)
		{
			// for every project check the expiration date against the alert conditions
			pj = (project)pjMgr.get(jwu, pjids[i]);				// proj Id
			String status = pj.getState();
			if (status==null || status.equals(project.ST_NEW))
				continue;	// don't care about non-open project

			try {if (checkSendAlert(pj) > 0)
				PrmThread.projAlertNum++;
			} catch (PmpException e) {e.printStackTrace();}
		}

		// for every task
		int [] tkids = tkMgr.findId(jwu, "om_acctname='%'");
		task tk = null;
		for (int i=0; i<tkids.length; i++)
		{
			//@SWS060206
			int [] ptids = ptMgr.findId(jwu, "TaskID='" + tkids[i] + "' && Status='Deprecated'");
			if (ptids.length > 0)
				continue;

			tk = (task)tkMgr.get(jwu, tkids[i]);	// task Id
			if (tk.isContainer())
				continue;	// container has no checking on dates

			// for every task check the expiration date against the alert conditions
			try {if (checkSendAlert(tk) > 0)
				PrmThread.taskAlertNum++;
			} catch (PmpException e) {e.printStackTrace();}
		}

		// for every action item
		int [] actids = aMgr.findId(jwu, "Type='" + action.TYPE_ACTION + "' && Status='" + action.OPEN + "'");
		action ai;
		for (int i=0; i<actids.length; i++)
		{
			// for every open action item, check the expire date to see if it is late
			ai = (action)aMgr.get(jwu, actids[i]);
			checkActionItem(ai);
		}

		// remove alert (memo) if there is no people (Alert) associated to it
		cleanupMemo();

		// clean up all dead items (self-sustaining system)
		cleanupOthers();

		l.info("*** PrmThread " + PJ_ALERT + " ends");
		return 1;	// just completed my work
	}

	public static void cleanupOthers()
		throws PmpException
	{
		PstAbstractObject o;

		// cleanup tasks that has no project association
		l.info("Running cleanupOthers()");
		int [] ids = tkMgr.findId(jwu, "ProjectID=null");
		for (int tid : ids) {
			o = tkMgr.get(jwu, tid);
			tkMgr.delete(o);
			l.info("  removed orphan task [" + tid + "]");
		}

		// cleanup dead documents
		// cleanup display documents that are old
		File fileDir = new File(SHOW_FILE_PATH);
		File [] fList = fileDir.listFiles();
		for (File aFile : fList) {
			String fName = aFile.getName();
			if (aFile.isDirectory()) {continue;}
			Date modifiedDate = new Date(aFile.lastModified());
			if (modifiedDate.before(yesterday)) {
				aFile.delete();
				l.info("   removed show file: " + fName);
			}
		}

		// cleanup steps
		// 1. task step without a project ID
		ids = fsMgr.findId(jwu, "Type='" + PstFlowStep.TYPE_PROJTASK
				+ "' && ProjectID=null");
		for (int sid : ids) {
			o = fsMgr.get(jwu, sid);
			fsMgr.delete(o);
			l.info("   removed step [" + sid + "] that has no project ID");
		}
		l.info("Done running cleanupOthers()\n");
	}

	///////////////////////////////////////////////////////
	//
	//	checkActionItem()
	//	Perform checking of condition to send deadline alerts
	//
	///////////////////////////////////////////////////////
	//
	protected static void checkActionItem(action obj)
		throws Exception
	{
		Date expire = (Date)obj.getAttribute("ExpireDate")[0];
		if (expire == null)
		{
			l.error("!!! Internal Error: Action item [" + obj.getObjectId() + "] has a null expiration date.");
			return;
		}
		if (expire.before(today))
		{
			// late action item
			obj.setAttribute("Status", action.LATE);
			aMgr.commit(obj);

			// send late alert
			int aid = obj.getObjectId();
			PstAbstractObject o, u;
			if (PrmThread.isSendActionAlert())
			{
				String msg = "The following Action Item is now past due <blockquote>";
				String mid = (String)obj.getAttribute("MeetingID")[0];
				String from = null;
				String pjIdS = (String)obj.getAttribute("ProjectID")[0];
				String pjName = null;
				msg += "<a href='" + HOST;
				if (mid != null)
				{
					msg += "/meeting/mtg_view.jsp?mid=" + mid + "&aid=" + aid + "#action'>";
					o = mtgMgr.get(jwu, mid);
					if (pjIdS != null)
						pjName = ((project)pjMgr.get(jwu, Integer.parseInt(pjIdS))).getDisplayName();
				}
				else
				{
					msg += "/project/proj_action.jsp?projId=" + pjIdS + "&aid=" + aid + "'>";
					o = pjMgr.get(jwu, Integer.parseInt(pjIdS));	// if mid==null, there must be a pjIdS
					pjName = ((project)o).getDisplayName();
				}
				msg += (String)obj.getAttribute("Subject")[0] + "</a>";
				if (pjName != null) {
					msg += "<br>(Project: <a href='" + HOST + "/project/proj_top.jsp?projId="
								+ pjIdS + "'>" + pjName + "</a>)";
				}
				msg += "</blockquote>";

				u = uMgr.get(jwu, Integer.parseInt((String)o.getAttribute("Owner")[0]));
				from = (String)u.getAttribute("Email")[0];

				String subject = ACTION_ALERT_SUBJ + aid + " is past due";
				ArrayList<Object> responsible = ((action)obj).getAllResponsible();

				//Util.createAlert(jwu, subject, msg, 0, "Alert", 0, 0, owner);
				// send email to everyone who are responsible including owner
				Util.sendMailAsyn(jwu, from, responsible.toArray(), null, null, subject, msg, MAILFILE);
			}

			l.info("*** Move action item [" + obj.getObjectId() + "] to Late");
			PrmThread.lateActionNum++;
		}
	}

	///////////////////////////////////////////////////////
	//
	//	checkSendAlert()
	//	Perform checking of condition to send deadline alerts
	//
	///////////////////////////////////////////////////////
	//
	protected static int checkSendAlert(PstAbstractObject obj)
		throws PmpException, ParseException
	{
		int alertNum = 0;

		// obj can be project or task
		PstManager mgr = null;
		String typeS = null;
		project pj = null;
		int taskId = 0;
		String s;
		String objName;
		String subj;
		String tkStatus;
		
		if (obj instanceof project)
		{
			// project
			mgr = pjMgr;
			typeS = "project";
			pj = (project)obj;
			objName = pj.getDisplayName();
			subj = PROJ_ALERT_SUBJ + objName;
			tkStatus = "";		// not a task
		}
		else
		{
			// task
			mgr = tkMgr;
			typeS = "task";
			taskId = obj.getObjectId();
			tkStatus = (String) obj.getAttribute("Status")[0];
			if (tkStatus == null) tkStatus = "";
			s = (String)obj.getAttribute("ProjectID")[0];
			if (s == null) {
				// try to clean up task left over in failing to create project
				// XXX but there is a timing window here that user might be
				// in the middle of create.  I should use a semaphore here.
				if (!StringUtil.isNullOrEmptyString(tkStatus)) {
					// clean up task without project id
					mgr.delete(obj);
					l.info("Deleted orphan task [" + taskId + "] - null ProjectID.");
					return -1;
				}
				return 0;
			}
			try {pj = (project)pjMgr.get(jwu, Integer.parseInt(s));}
			catch (PmpObjectNotFoundException e) {
				// this task belongs to a project that doesn't exist
				mgr.delete(obj);	// cleanup by removing the task
				l.info("Deleted orphan task [" + taskId + "] - project of ProjectID doesn't exist.");
				return -1;
			}

			planTask pt = ((task)obj).getPlanTask(jwu);
			if (pt == null)
				return 0;		// no planTask for this task, just return
			objName = (String)pt.getAttribute("Name")[0];
			subj = TASK_ALERT_SUBJ + objName;
		}

		// do not send notification if project is inactive
		String pjStatus = pj.getState();
		if (pjStatus==null || pjStatus.equals(project.ST_NEW)
				|| pjStatus.equals(project.ST_ONHOLD)
				|| pjStatus.equals(project.ST_CANCEL)
				|| pjStatus.equals(project.ST_COMPLETE)
				|| pjStatus.equals(project.ST_CLOSE) ) {
			return 0;	// don't do anything if project is at inactive states
		}

		// for CR, check if send notification option is on
		s = (String)pj.getAttribute("Option")[0];
		boolean isPjOptionNotifyTaskOnLate = (s!=null && s.contains(project.OP_NOTIFY_TASK));
		
		// ECC: the below check is such that if the option is OFF, then no proj/task expiration related
		// alert would be check at all.  I don't think that is a good option.  Rather, when the option
		// is ON, then always send alert when the task fails due date.  If it is OFF, fall back to check
		// the alert option in each task. (3/1/12)
		//if (isCRAPP && !isPjOptionNotifyTaskOnLate)		// if CR and task notification option OFF
		//	return 0;

		// get proj/task expiration date
		long diff = 10;
		Date expire = (Date)obj.getAttribute("ExpireDate")[0];
		if (expire == null)
		{
			if (obj instanceof project)
			{
				l.info(typeS + " [" + obj.getObjectId() + "] has null expiration date - might be container project.");
				return -1;
			}
		}
		else
		{
			expire = df.parse(df.format(expire));
			diff = expire.getTime() - today.getTime();		// everything use 0 hour
		}

		// check alert condition
		int condition = ((Integer)obj.getAttribute("AlertCondition")[0]).intValue();
		long lagTime = 0;
		String msg, lagS = "";	// ECC: to be accurate, I should use calendar to calculate the lag
		boolean bNeedAlert = true;
		Object [] alertPersons = obj.getAttribute("Alert");
		if (alertPersons[0] == null)
		{
			// simply put the project owner and task owner into alertPersons
			alertPersons = new Object[2];
			alertPersons[0] = pj.getAttribute("Owner")[0];
			alertPersons[1] = obj.getAttribute("Owner")[0];
		}
		
		// override by project option
		// condition 6 is a volatile value, won't save to DB
		if (condition==1		// task level says Never
				&& isPjOptionNotifyTaskOnLate && diff<0
				&& !tkStatus.equals(task.ST_COMPLETE) && !tkStatus.equals(task.ST_CANCEL) && !tkStatus.equals(task.ST_ONHOLD))
		{
			condition = 6;		// special case: proj option: alert as long as the status is late
		}
		
		if (typeS.equals("task") &&
				(tkStatus.equals(task.ST_CANCEL) || tkStatus.equals(task.ST_COMPLETE) || tkStatus.equals(task.ST_ONHOLD))) {
			bNeedAlert = false;
		}

		if (bNeedAlert)			// bNeedAlert might be changed in switch
		{
			switch (condition)
			{
				case 1:	// Never
					bNeedAlert = false;
					break;

				case 2:	// 1 week before due day
				{
					lagTime = 604800000;		// 7 * 24 * 3600000
					lagS = "1 week before";
					break;
				}

				case 0:	// this should default to project overall default setting
				case 3:		// 1 day before due day
				{
					lagTime = 86400000;			// 24 * 3600000
					lagS = "1 day before";
					break;
				}

				case 4:		// on due day
				{
					lagTime = 0;
					lagS = "on";
					break;
				}

				case 5:		// 1 day after due day
				{
					lagTime = -36000000;		// 10 hours after
					lagS = "1 day afer";
					break;
				}
				
				// 6 is a volatile value, won't save to DB
				case 6:		// project option: send late notification to owner as long as it is late
				{
					lagTime = 0;	// ignored
					int dys = (int) (-diff/86400000);	// diff is in -ve and in msec; change it to days
					if (dys < 1) dys = 1;
					lagS = dys + " day" + (dys>1?"s":"") + " after";
					break;
				}
				
				case 99:	// already handled, ignore
				{
					bNeedAlert = false;
					break;
				}

				default:
					//l.error("Error: alert condition (" + condition + ") is invalid.");
					// use negative value to denote alert already sent
					return 0;
			}

			// see if we need to trigger an alert message to users
			if (bNeedAlert && (
					(condition==5 && diff<0) ||		// since I wipe out the alert after sent, if case 5, do it anyway
					(condition==6) ||				// project alert option on
					((diff < lagTime)
					&& ((diff > -7200000)			// give a window of 2 hr after
						|| (lagTime < 0 && diff > -172800000)))
						// give a window of 2 days after
					)
				)
			{
				// need to send alert!
				msg = "<b>" + APPS + " " + typeS + " reminder (";
				msg += lagS + " due day)";
				msg += "</b>:<blockquote>";

				// get project/task stack
				msg += getStackString(jwu, pj, obj) + "</blockquote>";

				// AlertMessage
				s = (String)obj.getAttribute("AlertMessage")[0];
				if (s != null)
					msg += "<br>" + s;

				subj += " is " + lagS + " due day";
				if (!isCRAPP)
					Util.createAlert(jwu, subj, msg, 0, "Alert",
						pj.getObjectId(), taskId, alertPersons);
				Util.sendMailAsyn(jwu, FROM, alertPersons, null, null, subj,
					msg, MAILFILE);

				// clear the alert list if continuous notification option (proj alert option) is not on
				if (!isPjOptionNotifyTaskOnLate) {
					obj.setAttribute("AlertCondition", new Integer(99));	// already handled
					mgr.commit(obj);
				}
				alertNum += 1;
			}
		}	// END if bNeedAlert

		// Changing Status
		boolean bDoNotMoveTask = false;

		// if project is New, Completed, Canceled, On-hold or Closed, don't move task status
		// i.e. only move task if project is now Open or Late
		if (!pjStatus.equals(project.ST_OPEN) && !pjStatus.equals(project.ST_LATE))
			bDoNotMoveTask = true;

		////////////////////////
		// Check Phase Start and Expiration Date (only if !new)
		//
		if (obj instanceof project)
		{
// @AGQ042706
			int maxPhases = 7;	// default to 7
			s = Util.getPropKey("bringup", "PHS.TOTAL");
			if (s != null) maxPhases = Integer.parseInt(s);
			PstAbstractObject [] objArr = phMgr.getPhases(jwu, String.valueOf(obj.getObjectId()));
			phase ph, subPh;
			String phIDS;
			for (int i=0; i<maxPhases; i++)
			{
				//s = (String)obj.getAttribute("Phase"+(i+1))[0];
				if (i < objArr.length) // s!= null
				{
					ph = (phase)objArr[i];
					phIDS = String.valueOf(ph.getObjectId());
					// check main phase:
					checkPhase(obj, ph, "phase", String.valueOf(i+1));

					// check sub-phases
					if (phMgr.hasSubPhases(jwu, phIDS))
					{
						PstAbstractObject [] subObjArr = phMgr.getSubPhases(jwu, phIDS);

						for (int m=0; m<subObjArr.length; m++)
						{
							subPh = (phase)subObjArr[m];
							String numS = (i+1) + "." + (m+1);
							checkPhase(obj, subPh, "subphase", numS);
						}
					}
				}
				else
					break;		// reach last phase
			}	// END for loop
		}

		//////////////////////
		// STATUS Change 1: (New, Open) to Late
		// take this opportunity to change project/task to LATE
		String status;
		if (diff < 0)	// don't change if ExpireDate is today, change to late tomorrow
		{
			task t = null;
			if (obj instanceof task) {
				if (bDoNotMoveTask)
					return alertNum;		// don't do anything
				t = (task)obj;
			}

			status = (String)obj.getAttribute("Status")[0];
			if (status.equals("New") || status.equals("Open"))
			{
				// handle task and project differently
				// ECC: for task, I can simply call setStatusByDates()
				try {
					// for task setState() will handle step and commit
					if (status.equals("New")) {
						if (t != null)
							t.setState(jwu, task.ST_OPEN);	// this will create workflow step
					}
					if (t != null) {
						t.setState(jwu, task.ST_LATE);
					}
					else {
						obj.setAttribute("Status", project.ST_LATE);
						obj.setAttribute("LastUpdatedDate", now);
						mgr.commit(obj);
					}
					l.info("*** Move " + typeS + " [" + obj.getObjectId() + "] to Late");
				}
				catch (PmpException e) {
					l.error("PmpException in checkSendAlert()\n" + e.getMessage());
				}
				if (obj instanceof task)
					PrmThread.lateTaskNum++;
				else
					PrmThread.lateProjNum++;
			}
		}

		//////////////////////
		// STATUS Change 2: (New) to Open
		// if the StartDate is !after Today, then the task is moved to Open
		// ECC: do not move New project to Open, require a manual move.  This way
		// we can review the new project set up and allow the proj coordinator to make
		// changes over several days.  Tasks of New project should not be moved to open either.
		Date start = null;
		start  = (Date)obj.getAttribute("StartDate")[0];
		status = (String)obj.getAttribute("Status")[0];

		if ((obj instanceof task) && start!=null && !start.after(today) && status.equals(project.ST_NEW))
		{
			// @ECC112405 For task, need to check for fulfilling all dependencies
			boolean bReady = true;
			if (obj instanceof task)
			{
				bReady = !bDoNotMoveTask && ((task)obj).dependencyFulFilled(jwu);
			}

			// ready to move new task to open
			if (bReady)
			{
				task t = (task)obj;
				try {
					// setState() may move to open or late, and it will save
					t.setState(jwu, task.ST_OPEN);
					l.info("*** PrmAlert moves " + typeS + " [" + obj.getObjectId() + "] to Open");
				}
				catch (PmpException e) {
					l.error("PmpException in checkSendAlert() (2)\n" + e.getMessage());
					return alertNum;		// failed to setState(), no Email send
				}

				if (obj instanceof task)
					PrmThread.openTaskNum++;
				else
					PrmThread.openProjNum++;
				
				// if we send alert in task.setState(), then we do not need to do it here
				// today task.java will only trigger alert when task is completed.
				if (SEND_TASK_ALERT_OPEN!=null && SEND_TASK_ALERT_OPEN.equalsIgnoreCase("true"))
				{

					user objOwner = (user)uMgr.get(jwu, Integer.parseInt((String)obj.getAttribute("Owner")[0]));
					Object [] toArr = null;
					String from = (String)objOwner.getAttribute("Email")[0];

					if (obj instanceof task)
					{
						// task: send alert to both task and project owner
						planTask pt = ((task)obj).getPlanTask(jwu);
						toArr = new Object[2];
						toArr[0] = obj.getAttribute("Owner")[0];
						toArr[1] = pj.getAttribute("Owner")[0];
						subj = TASK_ALERT_SUBJ + (String)pt.getAttribute("Name")[0] + " has now started";

						msg = "The following task has started <blockquote>";
						String stackName = pj.getDisplayName() + "<br>>>" + TaskInfo.getTaskStack(jwu, pt);
						int idx = stackName.lastIndexOf(">>");
						stackName = stackName.substring(0, idx+2) + "<b>" + stackName.substring(idx+2) + "</b>";
						msg += "<a class='listlink' href='" + HOST + "/project/proj_plan.jsp?projId=" + pj.getObjectId() + "'>";
						msg += stackName + "</a></blockquote>";
						alertNum += 2;

						Util.createAlert(jwu, subj, msg, 0, "Alert", 0, 0, toArr);
						Util.sendMailAsyn(jwu, from, toArr, null, null, subj, msg, MAILFILE);
					}
					/*else	// commented out because we don't auto move project to open now
					{
						// project: only send to project owner
						toArr = new Object[1];
						toArr[0] = obj.getAttribute("Owner")[0];
						subj = PROJ_ALERT_SUBJ + ": " + ((project)obj).getDisplayName() + " is now started";

						msg = "The following project has now started <blockquote>";
						msg += "<a class='listlink' href='" + HOST + "/project/proj_plan.jsp?projId=" + pj.getObjectId() + "'>";
						msg += pj.getDisplayName() + "</a></blockquote>";
						alertNum += 1;
					}*/
				}
			}
		}

		return alertNum;

	}	// end checkSendAlert()


	///////////////////////////////////////////////////////
	//
	//	cleanupMemo()
	//	Remove alerts (memo) that has no more personnel (Alert) associated to it
	//
	///////////////////////////////////////////////////////
	//
	protected static void cleanupMemo()
		throws PmpException
	{
		// for every alert
		int [] ids = mmMgr.findId(jwu, "om_acctname='%'");
		memo mm;
		String alert;
		for (int i=0; i<ids.length; i++)
		{
			mm = (memo)mmMgr.get(jwu, ids[i]);
			alert = (String)mm.getAttribute("Alert")[0];
			if (alert == null)
			{
				// no people: delete
				l.info("Deleted memo [" + ids[i] + "]");
				mmMgr.delete(mm);
				PrmThread.delMemoNum++;
			}
		}
	}


	///////////////////////////////////////////////////////
	//
	//	cleanupMtg()
	//	Get an HTML string representing the printout of project/task tree.
	//
	///////////////////////////////////////////////////////
	//
	public static int mtgCleanup(boolean bTest)
		throws Exception
	{
		// 1. Close meeting after they are FINISHED for 2 weeks
		// 2. Remove meeting after they are CANCELLED for 2 weeks (Can't do this if multi parent/children)
		// 3. Finish meeting if they are 5 hrs after the expire time

		if (!bTest && !isTime(MTG_CLEANUP, MTG_WORK_HOUR, null))
			return 0;

		////////////////////////////////////////////////////////////////
		// Need to work
		l.info("*** PrmThread [" + APPS + "] " + MTG_CLEANUP + " starts");
		PrmThread.closeMtgNum = 0;
		PrmThread.delMtgNum = 0;
		PrmThread.finishMtgNum = 0;
		String s;

		Date dt = null;
		meeting mtg;
		long lo;
		if (now==null || today==null)
		{
			now = new Date();
			today = df.parse(df.format(now));
		}

		// finish meeting after 5 hours
		int [] ids = mtgMgr.findId(jwu, "Status='" + meeting.LIVE + "'");
		for (int i=0; i<ids.length; i++)
		{
			mtg = (meeting)mtgMgr.get(jwu, ids[i]);
			dt = (Date)mtg.getAttribute("ExpireDate")[0];
			lo = now.getTime() - (dt.getTime() + userinfo.getServerUTCdiff());
			if (lo > FIVE_HOURS)
			{
				mtg.setAttribute("Status", meeting.FINISH);
				mtg.setAttribute("CompleteDate", dt);		// take the expire time as actual completion
				mtgMgr.commit(mtg);

				// clean up the hash map counters from live meeting
				PrmUpdateCounter.removeCounterArray(String.valueOf(ids[i]));
				PrmThread.finishMtgNum++;
				l.info("Move LIVE meeting to FINISH [" + ids[i] + "]");
			}
		}

		// close finished meeting after X weeks (default to 3)
		ids = mtgMgr.findId(jwu, "Status='" + meeting.FINISH + "'");
		for (int i=0; i<ids.length; i++)
		{
			mtg = (meeting)mtgMgr.get(jwu, ids[i]);
			dt = (Date)mtg.getAttribute("CompleteDate")[0];
			if (dt == null)		// should not be null but this was found in db
				continue;		// dt = (Date)mtg.getAttribute("ExpireDate")[0];
			lo = today.getTime() - (dt.getTime() + userinfo.getServerUTCdiff());
			if (lo > MTG_CLOSE_TIME)
			{
				mtg.setAttribute("Status", meeting.COMMIT);
				mtgMgr.commit(mtg);

				// delete the vcs file of this meeting object
				String absFileName = CAL_PATH + File.separator + ids[i] + ".vcs";
				File vFile = new File(absFileName);
				if (vFile.exists())
					vFile.delete();

				PrmThread.closeMtgNum++;
				l.info("Move FINISH meeting to COMMIT [" + ids[i] + "]");
			}
		}

		///////////////////////////////
		// @ECC120106 Send reminder message to all invitees the night before the meeting
		SimpleDateFormat df1 = new SimpleDateFormat ("yyyy.MM.dd.HH.mm");
		//Date mtgNow = new Date(now.getTime()-userinfo.getServerUTCdiff());
		Date mtgNow = now;
		lo = mtgNow.getTime()+ 86400000;		// for tomorrow, add 1 day = 24*3600*1000
		Date tomorrow = new Date(lo);
		ids = mtgMgr.findId(jwu, "(Status='" + meeting.NEW + "') && (StartDate>='" + df1.format(mtgNow)+ "') && (StartDate<'" + df1.format(tomorrow) + "')");
		int ct = 0;
		for (int i=0; i<ids.length; i++)
		{
			// get all tomorrow's meetings and send reminder message
			mtg = (meeting)mtgMgr.get(jwu, ids[i]);
			Util2.sendInvitation(jwu, mtg, null);
			ct++;
		}
		l.info("Send " + ct + " meeting invite reminders.");


		///////////////////////////////
		// @ECC061308 Send reminder message to all invitees the night before the event or questionnaire
		String expr = "(ExpireDate>='" + df1.format(mtgNow)
						+ "') && (ExpireDate<'" + df1.format(tomorrow)
						+ "') && (State!='" + quest.ST_CANCEL + "')";
		ids = qMgr.findId(jwu, expr);
		ct = 0;
		quest qObj;
		for (int i=0; i<ids.length; i++)
		{
			// get all tomorrow's meetings and send reminder message
			qObj = (quest)qMgr.get(jwu, ids[i]);
			Util2.sendInvitation(jwu, qObj, null);
			ct++;
		}
		l.info("Send " + ct + " event/quest reminders.");

		/////////////////////////////////
		// @ECC112309 Send reminder message the night before the holiday/event
		// should check a notification flag
		ids = dMgr.findId(jwu, "(StartDate>='" + df1.format(mtgNow)
				+ "') && (StartDate<'" + df1.format(tomorrow) + "')");
		day dObj;
		String msg, descStr;
		Object bTextObj;
		String subj, subjH;
		if (APPS!=null && APPS.equals("OMF"))
			subjH = "[MeetWE] ";
		else
			subjH = "[" + APPS + "] ";
		int [] uids;
		for (int i=0; i<ids.length; i++)
		{
			dObj = (day)dMgr.get(jwu, ids[i]);
			if (dObj.getAttribute("Notification")[0].equals(day.NOTIFY_NO))
				continue;
			s = (String)dObj.getAttribute("TownID")[0];
			msg = (String)dObj.getAttribute("Title")[0];	// e.g. Thanksgiving Day
			subj = subjH + msg;
			msg = "Today is <b>" + msg + "</b><br><br>";
			bTextObj = dObj.getAttribute("Description")[0];
			descStr = (bTextObj==null)?"":new String((byte[])bTextObj);
			msg += descStr;
			if (s!=null && s.equals(String.valueOf(day.SCOPE_ALL))) {
				// send email to all members of the site
				uids = uMgr.findId(jwu, "om_accountname='%'");
			}
			else if (s!=null && s.equals(String.valueOf(day.SCOPE_PERSONAL))) {
				// send email to the owner
				uids = new int[1];
				uids[0] = Integer.parseInt((String)dObj.getAttribute("Owner")[0]);
			}
			else {
				// send email to the group
				// for MeetWE, this is town
				// for PRM, this is project
				if (Prm.isOMF()) {
					uids = uMgr.findId(jwu, "Towns=" + s);	// only possible for MeetWE
				}
				else {
					// CPM
					try {
						PstAbstractObject pj = pjMgr.get(jwu, Integer.parseInt(s));
						uids = Util2.toIntArray(pj.getAttribute("TeamMembers"));
					}
					catch (PmpException e) {
						continue;
					}
				}
			}
			if (uids.length > 0) {
				Util.sendMailAsyn(jwu, FROM, Util3.toInteger(uids), null, null, subj, msg, MAILFILE);
			}
		}


		/////////////////////////////////
		// remove canceled meeting (ABORT or EXPIRE) after 4 weeks: need to reconnect link
		// !!! Note: we can't do this if a meeting can have multiple children.  Today, mtg can only have 1 child
		s = Util.getPropKey("pst", "MTG_REMOVE_CANCEL");
		if (s==null || !s.equalsIgnoreCase("true"))
			return 1;				// don't delete canceled meeting

		String [] sa;
		String rec, nxt;
		ids = mtgMgr.findId(jwu, "Status='" + meeting.EXPIRE + "' || Status='" + meeting.ABORT + "'");
		for (int i=0; i<ids.length; i++)
		{
			mtg = (meeting)mtgMgr.get(jwu, ids[i]);
			dt = (Date)mtg.getAttribute("ExpireDate")[0];
			lo = today.getTime() - (dt.getTime() + userinfo.getServerUTCdiff());
			if (lo > FOUR_WEEKS)
			{
				// reconstruct the link before deleting the meeting
				rec = (String)mtg.getAttribute("Recurring")[0];
				if (rec!=null)
				{
					sa = rec.split(meeting.DELIMITER);
					if (sa.length >= 3)
					{
						nxt = sa[2];
						int [] tempId = mtgMgr.findId(jwu, "Recurring='%" + mtg.getObjectId() + "'");
						if (tempId.length == 1)
						{
							// it should only have at max one parent
							meeting tempMtg = (meeting)mtgMgr.get(jwu, tempId[0]);
							sa = ((String)tempMtg.getAttribute("Recurring")[0]).split(meeting.DELIMITER);
							rec = sa[0] + meeting.DELIMITER + (Integer.parseInt(sa[1])-1) + meeting.DELIMITER + nxt;
							tempMtg.setAttribute("Recurring", rec);
							mtgMgr.commit(tempMtg);
							l.info("Fixed connection from meeting [" + tempId[0] + "] to [" + nxt + "]");
						}
						else
							l.error("Detacted non-singular parents for meeting [" + ids[i] + "]");
					}
				}

				// now ready to delete meeting
				l.info("Removed " + (String)mtg.getAttribute("Status")[0] + " meeting [" + ids[i] + "]");
				mtgMgr.delete(mtg);

				// delete the vcs file of this meeting object
				String absFileName = CAL_PATH + File.separator + ids[i] + ".vcs";
				File vFile = new File(absFileName);
				if (vFile.exists())
					vFile.delete();

				PrmThread.delMtgNum++;
			}
		}

		l.info("*** PrmThread [" + APPS + "] " + MTG_CLEANUP + " ends");

		return 1;
	}



	///////////////////////////////////////////////////////
	//
	//	checkPhase()
	//	check project phase and subphase to send out alert for OPEN or LATE.
	//	If the phase being checked is a main phase, the return is either null or the blogId of subphase extension.
	//  if the phase being checked is a sub-phase, then the return is a string represented the updated
	//  subphase string to be inserted back to the extension blog -- usually it is the status get updated.
	//	2 possible formats:
	//	  a.  Main phase record- name::StartDt::ExpireDt::CompleteDt::Status::(opt)subPhase-Extension::(opt)taskId
	//	  b.  Sub- phase record- name::StartDt::ExpireDt::CompleteDt::Status::(opt)taskId
	//  @param pj - project


	///////////////////////////////////////////////////////
	//
	protected static String checkPhase(PstAbstractObject pj, PstAbstractObject ph, String title, String numS)
		throws PmpException
	{
		String phName, exDateS, phTask, status, msg = null; //stDateS,
		String planExDateS = "";
		String s = null;
		Object object;
		Date dt;
		boolean bSend = false;
		PstAbstractObject tk, ptk;
		int [] ids;
// @AGQ042706

		// @110705EC
		object = ph.getAttribute(phase.NAME)[0];
		phName = (object != null)?object.toString():"";

		object = ph.getAttribute(phase.TASKID)[0];
		phTask = (object != null)?object.toString():null;

		if (phTask != null && phTask.length() > 0)
		{
			// use task to fill the phase info
			try
			{

				tk = tkMgr.get(jwu, phTask);
				ids = ptMgr.findId(jwu, "TaskID='" + phTask + "' && Status!='Deprecated'");
				ptk = ptMgr.get(jwu, ids[ids.length-1]);
				if (phName == null || phName.length() == 0)
					phName = (String)ptk.getAttribute("Name")[0];

				//dt = (Date)tk.getAttribute("EffectiveDate")[0];
				//if (dt == null) dt = (Date)tk.getAttribute("StartDate")[0];
				//if (dt != null) stDateS = df.format(dt);
				//else stDateS = "";

				dt = (Date)tk.getAttribute("ExpireDate")[0];
				if (dt != null) exDateS = df.format(dt);
				else exDateS = "";

				//dt = (Date)tk.getAttribute("CompleteDate")[0];
				//if (dt != null) dnDateS = df.format(dt);
				//else dnDateS = "";

				s = (String)tk.getAttribute("Status")[0];
				if (s.equals(task.ST_NEW)) s = project.PH_NEW;
				else if (s.equals(task.ST_OPEN) || s.equals(task.ST_ONHOLD)) s = project.PH_START;
				status = s;
			}
			catch (PmpException e){l.error("Invalid task id [" + ph.getObjectId() +"] in phase/sub-phase"); return null;}
		}
		else
		{
			phTask	= null;

			object = ph.getAttribute(phase.PLANEXPIREDATE)[0];
			planExDateS = (object != null)?df.format((Date)object):"";

			//object = ph.getAttribute(phase.STARTDATE)[0];
			//stDateS = (object != null)?df.format((Date)object):"";

			object = ph.getAttribute(phase.EXPIREDATE)[0];
			exDateS = (object != null)?df.format((Date)object):"";

			//object = ph.getAttribute(phase.COMPLETEDATE)[0];
			//dnDateS = (object != null)?df.format((Date)object):"";

			status  = ph.getAttribute(phase.STATUS)[0].toString();
		}

		if (planExDateS == null || planExDateS.length() == 0) {
			planExDateS = exDateS;
		}

		// check for LATE
		if (exDateS.length()>0)
		{
			try {
				dt = df.parse(exDateS);
				if (dt.before(today) && (status.equals(project.PH_NEW) || status.equals(project.PH_START)) )
				{
					// this phase has expired
					bSend = true;
					msg = "The following project " + title + "/milestone has passed its deadline:";
					msg += "<blockquote><table>";
					msg += "<tr><td class='plaintext' width='100'>Project</td>";
					msg += "<td class='linklist'><a href='"
								+ HOST + "/project/proj_plan.jsp?projId="
								+ pj.getObjectId() + "'>" + ((project)pj).getDisplayName()
								+ "</a></td></tr>";
					msg += "<tr><td class='plaintext'>Phase " + numS + "</td>";
					msg += "<td class='linklist'><a href='"
								+ HOST + "/project/proj_summary.jsp?projId="
								+ pj.getObjectId() + "'>" + phName
								+ "</a></td></tr>";
					msg += "</table></blockquote>";

					// update status to LATE
					if (phTask == null) {
						object = (planExDateS != null)?df.parse(planExDateS):null;
						ph.setAttribute(phase.PLANEXPIREDATE, object);
						ph.setAttribute(phase.STATUS, project.PH_LATE);
						ph.setAttribute(phase.LASTUPDATEDDATE, now);
						phMgr.commit(ph);
					}
				}
			} catch (ParseException e) {
				System.out.println("ERROR in parsing expire Date: " + exDateS + " for phase: " + ph.getObjectId());
				e.printStackTrace();
			}
		}

/* @AGQ042706a Removed: decided that milestone does not require a alert for starting.

  		We will not send a start date for milestones since it does not apply
		if (!bSend && stDateS.length()>0)
		{
			// check from NEW to START
			dt = new Date(stDateS);
			if (!dt.after(today) && status.equals(project.PH_NEW))
			{
				// this phase has just started
				if (!dt.before(today)) {
					bSend = true;
					msg = "The following project " + title + "/milestone is scheduled to start on " + stDateS + ":";
					msg += "<blockquote>" + numS + ". ";
					msg += "<a href='" + HOST + "/project/proj_summary.jsp?projId="
						+ obj.getObjectId() + "'>" + phName + "</a></blockquote>";
				}
				// update status to START
				//s = phName + project.DELIMITER + stDateS + project.DELIMITER
				//	+ planExDateS + project.DELIMITER
				//	+ exDateS + project.DELIMITER + dnDateS + project.DELIMITER
				//	+ project.PH_START;
				//
				ph.setAttribute(phase.STATUS, project.PH_START);
				ph.setAttribute(phase.LASTUPDATEDDATE, now);
				phMgr.commit(ph);
			}
		}
*/
		if (bSend)
		{
			String subj = PH_ALERT_SUBJ + phName + " has passed deadline";
			/*Util.createAlert(jwu, subj, msg, 0, "Alert",
				pj.getObjectId(), 0, pj.getAttribute("Owner"));*/
			Util.sendMailAsyn(jwu, FROM, pj.getAttribute("Owner"),
				null, FROM, subj, msg, MAILFILE);
		}
		return null;
	}


	///////////////////////////////////////////////////////
	//
	//	getStackString()
	//	Get an HTML string representing the printout of project/task tree.
	//
	///////////////////////////////////////////////////////
	//
	protected static String getStackString(PstUserAbstractObject jwu, project pj, PstAbstractObject obj)
		throws PmpException
	{
		String hyperTxt = "";
		
		if (obj instanceof task)
		{
			String pjNameLink = "<a href='" + HOST + "/project/proj_plan.jsp?projId=" + pj.getObjectId() + "'>"
			+ pj.getDisplayName() + "</a>";

			// it is a task, get all its ancestors
			// get parent from plan task

			planTask pt = ((task)obj).getPlanTask(jwu);
			
			// this is a great way to display task stack names (got this code from post_addblog.jsp)
			hyperTxt = ">> " + TaskInfo.getTaskStack(jwu, pt);
			int idx = hyperTxt.lastIndexOf(">>");
			hyperTxt = hyperTxt.substring(0, idx+2) + "<b>" + hyperTxt.substring(idx+2) + "</b>";
			
			// add link to task management
			hyperTxt = "<a href='" + HOST + "/project/task_update.jsp?projId=" + pj.getObjectId()
							+ "&taskId=" + obj.getObjectId() + "'>"
							+ hyperTxt + "</a>";

			// when done with the task stack, put the project name on top
			hyperTxt = pjNameLink + "<br>" + hyperTxt;
		}
		return hyperTxt;
	}

	// check to see if it is time to work
	public static boolean isTime(String op, int workingHour, String dayOfWeek)
		throws PmpException, ParseException
	{
		if (workingHour == -1)
			return true;

		boolean found = false;
		userinfo ui = null;

		// do this once a day at WORK_HOUR
		Calendar rightNow = Calendar.getInstance();
		int hour = rightNow.get(Calendar.HOUR_OF_DAY);
		int day = rightNow.get(Calendar.DAY_OF_WEEK);
		String todayWeekDay = PrmThread.WEEK_DAY[day-1];

		now = new Date();
		thisMoment = now.getTime();
		ui = (userinfo)uiMgr.get(jwu, String.valueOf(jwu.getObjectId()));
		String lastwork = ui.getPreference(op);		// thread's last work history

		if (lastwork != null)
		{
			String [] st = lastwork.split(":");
			long diff = thisMoment - Long.parseLong(st[1]);

			// check to see if it is time to work (more than 1 day ago)
			if (dayOfWeek == null)
			{
				if ( (diff < ONE_DAY)
					 && (hour != workingHour) )
					return false;				// last work was within 12 hours, back to sleep for an hour
			}
			else
			{
				if ((diff < ONE_DAY)
					|| (!todayWeekDay.equals(dayOfWeek))
					|| (hour != workingHour))
					return false;
			}
			ui.removeAttribute("Preference", lastwork);		// remove the last value
		}
		// if !found: preference missing this op, do the work and add the op into preference

		////////////////////////////////////////////
		// Need to work

		// record the time before actually working
		lastwork = op + ":" + String.valueOf(thisMoment);
		ui.appendAttribute("Preference", lastwork);
		uiMgr.commit(ui);

		return true;
	}
}
