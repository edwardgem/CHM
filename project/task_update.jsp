<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<%
////////////////////////////////////////////////////
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	task_update.jsp
//	Author:	ECC
//	Date:	03/22/04
//	Description:
//		Display and update the project task.  Only allow task owner, proj owner or Chief to update.
//	Modification:
//		@AGQ101804
//			Implement the logic to enforce state tansition diagram in tasks
//		@AGQ102004
//			Implement the confirm dialog to confirm user the status settings of
//				Completed, Canceled, On-hold, Open
//		@102104ECC	Added watcher feature.
//		@102604ECC	Support attaching multiple files.
//		@012505ECC	Bug track for task.
//		@ECC112405	Added Duration and Gap to task.
//		@AGQ022406	Display of DL
//		@AGQ032806	Moved form to outside of table (for compatibility with Multi upload)
//					Added multi upload feature
//		@AGQ050806	Calendar will still show if it is not a date value is not a date
//		@SWS061406	Updated file listing and added show blog files.
//		@ECC011707	Support Department Name in project, task and attachment for authorization.
//		@ECC060407	Support more flexible attachment authorization using department name combination.
//		@ECC062107	Allow CR to add alert personnel for post file notification.
//		@ECC071807	Add optional Subject and Guest list in notification email.
//		@ECC081407	Support Blog Module.
//		@ECC061108	Update attachment attributes.
//		@ECC100708	Clipboard actions.
//		@ECC012909	Google docs.
//		@ECC031709	Restrictive access to task.
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.DecimalFormat" %>
<%@ page import = "java.text.SimpleDateFormat" %>
<%@ page import = "javax.servlet.*" %>
<%@ page import = "javax.servlet.http.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

// @082003ECC project task is implemented with planTask
	boolean MOD_BUG_TRACK = true;

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	String host = Util.getPropKey("pst", "PRM_HOST");
	int myUid = pstuser.getObjectId();
	String myUidS = String.valueOf(myUid);
	boolean isAdmin = false;
	boolean isProgMgr = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ((iRole & user.iROLE_ADMIN) > 0)
		isAdmin = true;
	if ((iRole & user.iROLE_PROGMGR) > 0)
		isProgMgr = true;

	// to check if session is CR or PRM
	boolean isCRAPP = false;
	boolean isMeetWE = false;
	String app = (String)session.getAttribute("app");
	if (app.indexOf("CR") != -1)	// CR or CR-OMF
		isCRAPP = true;
	else if (app.equals("OMF"))
		isMeetWE = true;

	String s;
	PstAbstractObject o;

	// @ECC081407 Blog Module
	boolean isBlogModule = false;
	s = Util.getPropKey("pst", "MODULE");
	if (s!=null && s.equalsIgnoreCase("Blog"))
		isBlogModule = true;

	// @ECC080108 Multiple company
	boolean isMultiCorp = false;
	s = Util.getPropKey("pst", "MULTICORPORATE");
	if (s!=null && s.equalsIgnoreCase("true"))
		isMultiCorp = true;

	projectManager projMgr = projectManager.getInstance();
	planTaskManager pTaskMgr = planTaskManager.getInstance();
	taskManager tkMgr = taskManager.getInstance();
	userManager uMgr = userManager.getInstance();
	attachmentManager attMgr = attachmentManager.getInstance();
	townManager tnMgr = townManager.getInstance();

	PstUserAbstractObject owner;
	// project and task objects
	String projIdS = request.getParameter("projId");
	String pTaskId = request.getParameter("pTaskId");
	int taskID = 0;
	if (pTaskId == null)
	{
		// support passing taskId
		taskID = Integer.parseInt((String)request.getParameter("taskId"));
		int [] ids1 = pTaskMgr.findId(pstuser, "TaskID='" + taskID + "' && Status!='Deprecated'");
		if (ids1.length <= 0)
		{
			// cannot find this task ID
			response.sendRedirect("../out.jsp?e=The task you requested is not found in the database.  (" + taskID + ")");
			return;
		}
		pTaskId = String.valueOf(ids1[ids1.length-1]);
	}
	System.out.println("opening pTaskId=" + pTaskId);

	planTask pTaskObj = (planTask)pTaskMgr.get(pstuser, pTaskId);
	String stackName = ">>" + TaskInfo.getTaskStack(pstuser, pTaskObj);
	int idx = stackName.lastIndexOf(">>");
	stackName = stackName.substring(0, idx+2) + "<span class='subtitle'>" + stackName.substring(idx+2) + "</span>";
	stackName = stackName.replaceAll(">>", "</td><tr><tr><td width='25' class='plaintext_grey' valign='top'>>></td><td class='plaintext_grey'>");

	String taskName = pTaskObj.getStringAttribute("Name");
	
	if (taskID <= 0)
		taskID = Integer.parseInt((String)pTaskObj.getAttribute("TaskID")[0]);
	task taskObj = (task)tkMgr.get(pstuser, taskID);

	if (projIdS == null)
		projIdS = (String)taskObj.getAttribute("ProjectID")[0];

	project projObj = (project)projMgr.get(pstuser, Integer.parseInt(projIdS));
	String projName = projObj.getObjectName();
	String projDisplayName = projObj.getDisplayName();
	int projOwnerId = Integer.parseInt((String)projObj.getAttribute("Owner")[0]);
	String projStatus = (String)projObj.getAttribute("Status")[0];

	// set session attributes
	s = (String)session.getAttribute("projId");
	if (s == null || !projIdS.equals(s)) {
		Util3.refreshPlanHash(pstuser, session, projIdS);
		if (s == null) {
			// in PRM now, there is only one town, as long as it is not null, it is the right town
			// ECC: not necessarily true!
			s = (String)projObj.getAttribute("TownID")[0];
			if (s != null) {
				int townId = Integer.parseInt(s);
				session.setAttribute("townName", PstManager.getNameById(pstuser, townId));
			}
		}
	}

	// get the underlying task object
	int taskOwnerId = 0;
	String taskOwnerIdS   = (String)taskObj.getAttribute("Owner")[0];
	if (taskOwnerIdS != null)
		taskOwnerId = Integer.parseInt(taskOwnerIdS);
	String tStatus = (String)taskObj.getAttribute("Status")[0];
	
	// task option
	String taskBlogIdS = taskObj.getOption(task.TASK_BLOG_ID);
	if (taskBlogIdS == null) taskBlogIdS = "";


	// @ECC011707
	String deptName = (String)taskObj.getAttribute("DepartmentName")[0];
	if (deptName == null) deptName = "";
	else deptName = deptName.replaceAll("@", "; ");

	// try to get DepartmentName from the user company, if not from config file
	s = null;
	boolean bHasCompany = true;
	if (isCRAPP)
	{
		s = (String)pstuser.getAttribute("Company")[0];
		if (s != null)
		{
			o = tnMgr.get(pstuser, Integer.parseInt(s));
			s = (String)o.getAttribute("DepartmentName")[0];
		}
		else
			bHasCompany = false;
	}
	if (s == null)
		s = Util.getPropKey("pst", "DEPARTMENTS");
	String [] configDept = null;
	String [] allDept = null;
	if (s != null) {allDept = s.split(";"); configDept=s.split(";");}
	// @ECC060407
	if (allDept != null)
	{
		for (int i=0; i<allDept.length; i++)
		{
			allDept[i] = allDept[i].trim();
			if (deptName.indexOf(allDept[i]) != -1)
				allDept[i] = null;		// this is already selected as a department, ignored
		}
	}
	String [] myDepts = null;
	if (deptName.length() > 0)
		myDepts = deptName.split("; ");

	String expDateS = null;
	Date expireDate = (Date)taskObj.getAttribute("ExpireDate")[0];
	String format = "MM/dd/yyyy";
	SimpleDateFormat df = new SimpleDateFormat(format);
	SimpleDateFormat df1 = new SimpleDateFormat("MM/dd/yy hh:mm a");
	if (expireDate != null)
	{
		expDateS = phase.parseDateToString(expireDate, format);//df.format(expireDate);
	}

	// start date
	String startDateS = null;
	Date startDate = (Date)taskObj.getAttribute("StartDate")[0];
	if (startDate != null)
		startDateS = df.format(startDate);

	// actual start date
	String actualDateS = "N/A";
	Date actualDate = (Date)taskObj.getAttribute("EffectiveDate")[0];
	if (actualDate != null)
		actualDateS = df.format(actualDate);

	// completion date
	Date completeDt = (Date)taskObj.getAttribute("CompleteDate")[0];

	// @ECC112405
	int gap = ((Integer)taskObj.getAttribute("Gap")[0]).intValue();
	int duration = ((Integer)taskObj.getAttribute("Duration")[0]).intValue();
	/*if (duration == 0)
	{
		// automatically calculate duration based on StartDate and ExpireDate
		Date dt1=null, dt2=null;
		if (actualDate != null) dt1 = actualDate;
		else dt1 = startDate;
		if (completeDt != null) dt2 = completeDt;
		else dt2 = expireDate;

		if (dt1!=null && dt2!=null)
			duration = (int)Math.ceil((dt2.getTime() - dt1.getTime())/86400000);
	}*/

	// update only authorized to task owner, project owner and Town Chief
	String UserEditCal = "onClick='return false'";
	String UserEdit = "disabled";
	boolean isAuthorizedUser = false;

	// @102604AGQ
	// Handle Status Change and Disable changes

	// Task is not New, Disable UserEditCal Calender Start Date Only

	// Task is Completed, or Canceled, disable all everything

	// Task is On-hold, disable calender

	String parentStatus = taskObj.getParentTaskStatus(pstuser);
	boolean isBranchOwner = taskObj.isAuthorizedUser(pstuser, task.WRITE);
	if ( isAdmin ||
		//((!tStatus.equals(task.ST_CANCEL) && !tStatus.equals(task.ST_COMPLETE) && (parentStatus==null || !parentStatus.equals(task.ST_ONHOLD) ))
		 (isBranchOwner || isProgMgr) )
	{
		UserEdit = "";
		UserEditCal = "";
		isAuthorizedUser = true;
	}

	boolean isTaskProjOwner = (taskOwnerId==myUid || projOwnerId==myUid);	// @ECC031709: I am proj or task owner

	// check to see if show blog file
	boolean bShowBfile = false;
	s = request.getParameter("ShowBfile");
	if (s!=null && s.equals("true"))
		bShowBfile = true;

	// check if setting this task as phase
	boolean isPhaseTask = taskObj.isPhase(pstuser);
	s = request.getParameter("SetAsPhase");
	if (s!=null) {
		// see if I need to update
		if (s.equals("true") && !isPhaseTask && isAuthorizedUser) {
			// add this task as a phase
			phase.addTaskPhase(pstuser, taskObj);
			isPhaseTask = true;
		}
		else if (s.equals("false") && isPhaseTask && isAuthorizedUser) {
			// remove this task from the phase list
			phase.removeTaskPhase(pstuser, taskObj);
			isPhaseTask = false;
		}
	}
	
	// check if override tree expand option
	boolean bOverrideTreeExpand = taskObj.getSubAttribute("Option", "OverrideExpand")!=null;
	s = request.getParameter("SetOVT");
	if (s!=null) {
		if (s.equals("true") && projOwnerId==myUid && !bOverrideTreeExpand) {
			// set override option
			taskObj.setSubAttribute(tkMgr, "Option", "OverrideExpand", "");
			bOverrideTreeExpand = true;
		}
		else if (s.equals("false") && projOwnerId==myUid && bOverrideTreeExpand) {
			// unset override option
			taskObj.setSubAttribute(tkMgr, "Option", "OverrideExpand", null);
			bOverrideTreeExpand = false;
		}
		session.removeAttribute("planStack");		// cleanup cache
	}
	
	// @102104ECC
	Object [] oArr;
	String watch = request.getParameter("watch");
	boolean isWatching = false;
	int watchNum = 0;
	if (watch == null)
	{
		// check to see if I am currently watching this task
		oArr = taskObj.getAttribute("Watch");
		if (oArr[0] != null)
		{
			watchNum = oArr.length;
			for (int i=0; i<watchNum; i++)
			{
				if (myUidS.equals(oArr[i]))
				{
					isWatching = true;
					break;
				}
			}
		}
	}
	else if (watch.equals("true"))
	{
		// I want to watch this task
		taskObj.appendAttribute("Watch", myUidS);
		tkMgr.commit(taskObj);
		watchNum = taskObj.getAttribute("Watch").length;
		isWatching = true;
	}
	else if (watch.equals("false"))
	{
		// I don't want to watch this task anymore
		taskObj.removeAttribute("Watch", myUidS);
		tkMgr.commit(taskObj);
		oArr = taskObj.getAttribute("Watch");
		if (oArr[0] != null)
			watchNum = oArr.length;
	}
	// @102104ECC End

	// @ECC070307a check whether need to send alert message earlier
	boolean bSendUploadFileEmail = false;
	Object [] alertIdObjArr = taskObj.getAttribute("Alert");
	int alertLength = (alertIdObjArr[0] != null)?alertIdObjArr.length:0;

	String optStr = (String)projObj.getAttribute("Option")[0];
	if ( (optStr!=null && optStr.indexOf(project.OP_NOTIFY_BLOG)!=-1)
			|| alertLength > 0 )
		bSendUploadFileEmail = true;

	String optMsg = request.getParameter("message");
	if (optMsg == null || optMsg.length() <= 0 || optMsg.equals("null")) optMsg = "";

	// @ECC012909 Google ID
	boolean bGoogleReady = false;
	String [] sa;
	s = (String)pstuser.getAttribute("GoogleID")[0];
	if (s != null)
	{
		sa = s.split(":");			// userId:passwd
		if (sa.length == 2)
			bGoogleReady = true;
	}

	// check project option on task deadline notification
	boolean isTaskDeadline = false;
	s = (String)projObj.getAttribute("Option")[0];
	if (!isCRAPP || s.contains(project.OP_NOTIFY_TASK))		// either PRM or task notification option ON
		isTaskDeadline = true;

	PstAbstractObject [] teamMember = ((user)pstuser).getTeamMembers(projObj);
	
	// task blog
	int [] blogIdArr = null;
	resultManager rMgr = resultManager.getInstance();
	blogIdArr = rMgr.findId(pstuser, "TaskID='" + taskID + "'");
	
	// check to see if project block posting option is on
	boolean bBlockPosting = false;
	if (projObj != null) {
		if (projObj.getOption(project.OP_NO_POST) != null) {
			bBlockPosting = true;
		}
	}

%>

<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<%-- @AGQ032806 --%>
<script src="../multifile.js"></script>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen" />
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print" />

<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../forms.jsp" flush="true"/>
<script language="JavaScript" src="../get-date.js"></script>

<script type="text/javascript">
<!--
var noCal = false;		// if noCal, don't show calendar

function validate()
{
	var f = document.updateTask;

	var e = f.TaskName;
	e.value = trim(e.value);
	if (e.value == '')
	{
		alert("Please make sure to enter a TASK NAME.");
		e.focus();
		return false;
	}

	if (f.Owner.value == '')
	{
		alert("Please make sure to select a TASK OWNER.");
		f.Owner.focus();
		return false;
	}

	if ('<%=isAdmin%>' == 'true')
		getall(f.AlertPersonnel);

	startDate = '<%=startDate%>';
	var today = new Date();
	today = new Date(today.getFullYear(),today.getMonth(),today.getDate());
	s = '<%=projStatus%>';
	ts = '<%=tStatus%>';
	newSt = f.Status.value;
	c = true;
	if (s!='<%=task.ST_OPEN%>' && s!='<%=task.ST_NEW%>' && s!='<%=task.ST_LATE%>')
	{
		alert("You cannot update the Task unless the Project is in the NEW, OPEN or LATE state.  Please make sure that the project status is changed to OPEN.");
		return false;
	}
	if (s=='<%=task.ST_NEW%>' && ts != newSt)
	{
		alert("You cannot change the Task to OPEN unless the Project is in the OPEN state.");
		return false;
	}

	if (multi_selector.count > 1)
	{
		formblock= document.getElementById('inputs');
		forminputs = formblock.getElementsByTagName('input');
		var isFileName = true;
		for (var i=0; i<forminputs.length; i++) {
			if (forminputs[i].type == 'file' && forminputs[i].value != '') {
				if (isFileName)
					isFileName = affirm_addfile(forminputs[i].value);
				else
					break;
			}
		}
		if (!isFileName)
			return isFileName;

		// @AGQ040406
		if(!findDuplicateFileName(forminputs))
			return false;
	}

	if (newSt == '<%=task.ST_COMPLETE%>' && ts != newSt)
	{	// Confirm User with subtasks also being completed
		c = confirm("Moving a task to the COMPLETED state will trigger all of its NEW, OPEN and LATE subtasks to COMPLETE. " +
						"Do you want to proceed?");
	}
	if (newSt == '<%=task.ST_CANCEL%>' && ts != newSt)
	{	// Confirm User with subtasks also being canceled
		c = confirm("Moving a task to the CANCELED state will trigger all of its incomplete subtasks to CANCEL. " +
						"Do you want to proceed?");
	}
	if ( ts == '<%=task.ST_ONHOLD%>' && newSt == '<%=task.ST_OPEN%>')
	{	// Confirm User that all subtasks that was onhold will become open
		c = confirm("Moving a task from the ON-HOLD state to OPEN will trigger all of its subtasks to resume their previous states. " +
						"Do you want to proceed?");
	}
	if ( newSt == '<%=task.ST_ONHOLD%>' && ts != newSt)
	{	// Confirm user that all subtasks will be on-hold
		c = confirm("Moving a task to the ON-HOLD state will trigger all of its working subtasks to become ON-HOLD. " +
						"Do you want to proceed?");
	}
	if ( ts == '<%=task.ST_NEW%>' && newSt == '<%=task.ST_OPEN%>' && today.toString()!=startDate)
	{	// Confirm user the start date will be set to today
		c = confirm("Moving a task to the OPEN state will set its Start Date to TODAY. Do you want to proceed?")
	}

if (<%=isCRAPP%> != true)
{
	// do not allow setting children to null StartDate
	if (f.StartDate.value=="" && f.ChildStart.checked)
	{
		alert("You cannot set all the sub-task of this task to a NULL START DATE");
		return false;
	}
	if (f.ExpireDate.value=="" && f.ChildExpire.checked)
	{
		alert("You cannot set all the sub-task of this task to a NULL EXPIRATION DATE");
		return false;
	}

	// check duration and gap.  Gap must be >0.  For Duration, if Dur==0, we will use the
	// StartDate and ExpireDate to calculate the duration.
	e = f.Gap;
	e.value = e.value.replace( /(^\s*)|(\s*$)/g, '' );		// trim spaces
	var i = parseInt(e.value);
	if (e.value!="" && (isNaN(i) || i<0) )
	{
		alert("To specify a GAP, you must enter an integer that is greater than or equal to 0.");
		e.focus();
		return false;
	}

	e = f.Dur;
	e.value = e.value.replace( /(^\s*)|(\s*$)/g, '' );		// trim spaces
	i = parseInt(e.value);
	if (e.value!="" && (isNaN(i) || i<=0) )
	{
		if (i == 0)
		{
			// use the implied (auto calculated) duration based on StartDate and ExpireDate
			var dt1 = new Date(f.StartDate.value);
			var dt2 = new Date(f.ExpireDate.value);
			duration = Math.ceil((dt2.getTime() - dt1.getTime())/86400000);
			e.value = duration;
		}
		else
		{
			alert("To specify a DURATION, you must enter an integer that is greater than 0.");
			e.focus();
			return false;
		}
	}

	// resource management: weight
	e = f.Weight;
	if (f.Weight) {
		e.value = trim(e.value);
		var flt = parseFloat(e.value);
		if (e.value!="" && (isNaN(flt) || flt<=0)) {
			alert("To specify a WEIGHT, you must enter a number that is greater than 0, or remove the value in the cell.");
			e.focus();
			return false;
		}
	}

	// open task changing start date to future will change task to new
	if (ts == '<%=task.ST_OPEN%>' && f.StartDate.value!=startDate)
	{
		var d = new Date(f.StartDate.value);
		if (d.getTime() > today.getTime())
		{
			c = confirm("Moving the START DATE of an OPEN task to the future will change the state to NEW. Do you want to proceed?")
		}
	}
}	// !isCRAPP

	if (c) {
		if (<%=isCRAPP%> != true)
		{
			var alertMessage = f.AlertMessage.value;
			for (i=0;i<alertMessage.length;i++) {
				char = alertMessage.charAt(i);
				if (char == '\\') {
					fixElement(f.AlertMessage,
						"ALERT MESSAGE cannot contain these characters: \n  \\");
					return false;
				}
			}
		}
		getall(f.AlertPersonnel);	// @ECC062107
		if (f.Departments != null)
			getall(f.Departments);		// @ECC060407
	}
	else
		return false;

	// @ECC031709
	if (<%=isTaskProjOwner%>)
	{
		f.RestrictIgnore.value = "false";
		if (f.RestrictCheck.checked)
			getall(f.RestrictAccess);
	}
	else
		f.RestrictIgnore.value = "true";

	f.submit();
}

function show_cal(e1, e2)
{
	if (noCal) return;

	if (e2==null) e2 = e1;
	if (e1.value == "")
	{
		var today = new Date();
		e1.value = today.getMonth()+1 + "/" + today.getDate()+ "/" + today.getFullYear();
		e2 = e1;
	}
	if (e2.value=="") e2.value=e1.value;
	var dt = new Date(e1.value)
	var mon = '' + dt.getMonth();

	var yr = '' + dt.getFullYear();
	var es = 'updateTask.' + e1.name;
	var number = parseInt(mon);
	var number2 = parseInt(yr);

	if (isNaN(number) || isNaN(number2)) {
		dt = new Date();
		mon = '' + dt.getMonth();
		yr = '' + dt.getFullYear();
	}
	show_calendar(es, mon, yr);
}

function fixElement(e, msg)
{
	alert(msg);
	if (e)
		e.focus();
}

var isUploading = false;	// disable uploading to avoid multiple submit
function setAddFile()
{
	if (isUploading) return false;
	isUploading = true;

	if (multi_selector.count == 1)
	{
		fixElement(document.getElementById("my_file_element"), "To add a file attachment, click the Browse button and choose a file to be attached, then click the Add button.");
		isUploading = false;
		return false;
	}
	formblock= document.getElementById('inputs');
	forminputs = formblock.getElementsByTagName('input');
	var isFileName = true;
	for (var i=0; i<forminputs.length; i++) {
		if (forminputs[i].type == 'file' && forminputs[i].value != '')
			if (isFileName)
				isFileName = affirm_addfile(forminputs[i].value);
			else
				break;
	}

	if (!isFileName)
	{
		isUploading = false;
		return isFileName;
	}

	if(!findDuplicateFileName(forminputs))
	{
		isUploading = false;
		return false;
	}

	if (document.updateTask.Departments != null)
		getall(document.updateTask.Departments);	// @ECC060407
	getall(document.updateTask.AlertPersonnel);	// @ECC062107

	return true;
}

function check_dateSetting()
{
	if (updateTask.Gap.value!='' || updateTask.Dur.value!='')
	{
		updateTask.StartDate.disabled = true;
		updateTask.ExpireDate.disabled = true;
		noCal = true;
	}
	else
	{
		updateTask.StartDate.disabled = false;
		updateTask.ExpireDate.disabled = false;
		noCal = false;
	}
}
function showBlogFile()
{
	var s = 'false';
	if (OptionForm.ShowBlogFile.checked)
		s = 'true';
	location = 'task_update.jsp?projId=<%=projIdS%>&pTaskId=<%=pTaskId%>&ShowBfile=' + s;
}
function setPhase()
{
	var s = 'false';
	if (OptionForm.SetAsPhaseBox.checked) {
		s = 'true';
	}
	else {
		// user just uncheck the box, need to confirm for removing phase
		if (!confirm("Are you sure you want to unset this task as a phase?")) {
			OptionForm.SetAsPhaseBox.checked = true;
			return false;
		}
	}
	location = 'task_update.jsp?projId=<%=projIdS%>&pTaskId=<%=pTaskId%>&SetAsPhase=' + s;
}

function overrideTreeExpand()
{
	var s = 'false';
	if (OptionForm.OverrideTreeExpandBox.checked)
		s = 'true';
	location = "task_update.jsp?projId=<%=projIdS%>&pTaskId=<%=pTaskId%>&SetOVT=" + s;
}

function showMessage(id)
{
	var e = document.getElementById(id);
	var e1 = document.getElementById('OptSubject');
	var msg;
	if (updateTask.OptMsg.checked == true)
	{
		e.style.display = 'block';

		if (e1.value=='' && filenameList != '')
		{
			if (filenameList.indexOf(", ") == -1) msg = "File";
			else msg = "Files";
			e1.value = msg + " (" + filenameList + ") posted on (<%=projDisplayName%>)";			// this is remembered in multifile.js
		}
	}
	else
	{
		e.style.display = 'none';
		e1.value = '';
	}

}

function updateAttmt(attId)
{
	var f = document.updateTask;
	if (f.AttDepartments != null)
		getall(f.AttDepartments);	// @ECC061108
	f.AttId.value = attId + "";
	f.action = "post_updAttmt.jsp";
	f.encoding = "application/x-www-form-urlencoded";
	f.submit();
}

function checkGoogle()
{
	var f = document.updateTask;
	if (f.google.checked && <%=bGoogleReady%>==false)
	{
		fixElement(f.google,
			"You need to update your User Profile to include your Google ID and password before uploading Google Docs.");
		f.google.checked = false;
		return false;
	}
}

function toggleRestrict()
{
	var f = document.updateTask;
	var e = document.getElementById("restrictTR");
	if (f.RestrictCheck.checked)
	{
		e.style.display = "block";
	}
	else
	{
		e.style.display = "none";
	}
}

function taskMgmt()
{
	// show/hide the panel for task management
	var e = document.getElementById('DIV_TaskMgmt');
	var ee = document.getElementById('taskMgmtHint');
	if (e.style.display == 'none') {
		e.style.display = 'block';
		ee.innerHTML = 'Hide details';
	}
	else {
		e.style.display = 'none';
		ee.innerHTML = 'Click to manage task';
	}
}

function addGoogleLink()
{
	// show/hide the panel for adding an external Google Docs link
	var e = document.getElementById('DIV_GoogleLink');
	if (e.style.display == 'none') {
		e.style.display = 'block';
	}
	else {
		e.style.display = 'none';
		var ee = document.getElementById('Gfname');
		ee.value = '';
		ee = document.getElementById('Glink');
		ee.value = '';
	}
}

function submitAddGoogleExtFile()
{
	// error check
	var e = document.getElementById('Gfname');
	var val = trim(e.value);
	if (val == "") {
		fixElement(e, "Enter a FILENAME for the Google document you want to attach here.");
		return false;
	}
	e.value = val;

	e = document.getElementById('Glink');
	val = trim(e.value);
	if (val == "") {
		fixElement(e, "Enter the URL that opens the Google Docs");
		return false;
	}
	e.value = val;
	
	var f = document.updateTask;
	f.op.value = "AddGoogleLink";
	f.action = "post_updAttmt.jsp";
	f.encoding = "application/x-www-form-urlencoded";
	f.submit();
}

//-->
</script>

<title>
	<%=Prm.getAppTitle()%> Task Management
</title>


<style type="text/css">
#bubbleDIV {position:relative;z-index:1;left:1em;top:.9em;width:3em;height:3em;vertical-align:bottom;text-align:center;}
img#bg {position:relative;z-index:-1;top:-2em;width:3em;height:3em;border:0;}
.ptextS1 {padding-top:5px;}
</style>

</head>

<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" height="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">
		<!-- Main Tables -->
		<table width="100%" border="0" cellspacing="0" cellpadding="0">
		  	<tr>
		    	<td width="100%" valign="top">
					<!-- Top -->
					<jsp:include page="../head.jsp" flush="true"/>
					<!-- End of Top -->
				</td>
			</tr>
			<tr>
	          <td>
	            <table width="90%" border="0" cellspacing="0" cellpadding="0">
					<tr>
					<td></td>
					<td>
					<table border='0' cellspacing='0' cellpadding='0'>
						<tr><td colspan='2' class="head"><b>Task Management</b></td></tr>
						<tr><td width='10'>&nbsp;</td>
						<td>
							<table border='0' cellspacing='0' cellpadding='0'><tr><td class='plaintext_grey'>
							<%=stackName%>
							</td></tr></table>
						</td>
						</tr>
					</table>
					</td>

					<td width='280' valign="bottom" class="formtext">
<% if (!isCRAPP) {%>
					This task is being watched by <%=watchNum%> person(s)<br>

<% if (isWatching) {%>
					<img src="../i/bullet_tri.gif"/>
					<a class="listlinkbold" href="task_update.jsp?projId=<%=projIdS%>&pTaskId=<%=pTaskId%>&watch=false">
					Remove from my watch list</a>
<% } else {%>
					<img src="../i/bullet_tri.gif"/>
					<a class="listlinkbold" href="task_update.jsp?projId=<%=projIdS%>&pTaskId=<%=pTaskId%>&watch=true">
					Watch this task on my home page</a>
<% }	// end else !isWatching

}		// end if !isCRAPP
%>

					</td>
					</tr>

	              <tr><td><img src='../i/spacer.gif' height='10'/></td></tr>
	              
	            </table>
	          </td>
	        </tr>
</table>
	        
<table width='90%' border="0" cellspacing="0" cellpadding="0">
			<tr>
          		<td width="100%">
					<!-- Navigation Menu -->
<% if (isMeetWE) { %>
					<jsp:include page="../in/home.jsp" flush="true">
					<jsp:param name="role" value="<%=iRole%>" />
					</jsp:include>
<% } else { %>
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Project" />
				<jsp:param name="subCat" value="" />
				<jsp:param name="role" value="<%=iRole%>" />
				<jsp:param name="projId" value="<%=projIdS%>" />
			</jsp:include>
<% } %>
					<!-- End of Navigation Menu -->
				</td>
	        </tr>
		</table>

<!-- MAIN CONTENT -->

<table border='0' cellspacing='0' cellpadding='0' width='90%'>
<%
	// error message display
	String errmsg = (String)session.getAttribute("errorMsg");
	if (errmsg != null)
	{
		session.removeAttribute("errorMsg");
		out.print("<tr><td width='12'>&nbsp;</td>");
		out.print("<td class='plaintext' style='color:#ee0000'>" + errmsg + "</td></tr>");
	}
%>
<tr>
    <td><img src='../i/spacer.gif' width='15' /></td>
	<td class="plaintext">
		&nbsp;Please note fields marked with an * are required.</td>
<%
	if (!isCRAPP) {
		out.print("<form name='OptionForm'>");
		out.print("<tr><td colspan='2' align='right'>");
		out.print("<table><tr>");
		
		// blog num
		out.print("<td><a href='../blog/blog_task.jsp?projId="
				+ projIdS + "&taskId=" + taskID + "'><div id='bubbleDIV'>");
		out.print(blogIdArr.length);
		out.print("<img id='bg' src='../i/bubble.gif' />");
		out.println("</div></a></td>");
		out.print("<td><img src='../i/spacer.gif' width='20' height='1'/></td>");
		
		//planTask pt = taskObj.getPlanTask(pstuser);		// should just call task.isTopLevel
		//s = pt.getStringAttribute("ParentID");
		out.print("<td class='plaintext_blue'>");
		boolean isTopLevel = taskObj.isTopLevel(pstuser);	//(s==null || s.equals("0"));
		if (!taskObj.isContainer() && isTopLevel) {
			out.print("<input type='checkbox' name='SetAsPhaseBox' onClick='javascript:setPhase()'"
				+ UserEdit);
			if (isPhaseTask) out.print(" checked");
			out.print(">");
			out.print("<b>Set as phase</font></b>");
			out.print("&nbsp;&nbsp;&nbsp;");
		}
		
		// override tree expansion
		if (isAuthorizedUser || isTaskProjOwner) {
			out.print("<input type='checkbox' name='OverrideTreeExpandBox' onClick='javascript:overrideTreeExpand()'");
			if (bOverrideTreeExpand) out.print(" checked");
			out.print(">");
			out.print("<b>Override tree expansion</font></b>&nbsp;&nbsp;&nbsp;");
		}
		out.print("<input type='checkbox' name='ShowBlogFile' onClick='javascript:showBlogFile()'");
		if (bShowBfile) out.print(" checked");
		out.print(">");
		out.print("<b>Show blog files</font></b>&nbsp;");
		out.print("</td></tr></table>");
		out.print("</td></tr>");
		out.print("</form>");
	}
%>
</tr>
<tr>
    <td></td>
<td>
<form name="updateTask" action="../project/post_updtask.jsp" method="post" enctype="multipart/form-data">
<input type="hidden" name="projId" value="<%=projIdS%>">
<input type="hidden" name="planTaskID" value="<%=pTaskId%>">
<input type="hidden" name="taskID" value="<%=taskID%>">
<input type="hidden" name="AttId" value="">
<input type="hidden" name="op" value="">

<!-- start table -->
	<table width="100%" border="0" cellspacing="2" cellpadding="4" bgcolor="#FFFFFF">

<!-- Task ID -->
		<tr bgcolor="#FFFFFF">
		<td class="td_field_bg" width="200">Task ID</td>
		<td class="td_value_bg" style="font-weight: bold; font-size: 12px; color: #DD0000">&nbsp;<%=taskID%></td>
		</tr>

<!-- New file attachment -->
<tr bgcolor="#FFFFFF">
	<td class="td_field_bg" width="160">Upload Files</td>
	<td class="td_value_bg"><table border='0' cellspacing='0' cellpadding='0' width='100%'>
		<tr>
		<td class="td_value_bg">
		Click the below <b>Button</b> to select files for upload:<p>
		<span id="inputs"><input id="my_file_element" type="file" class="plaintext" size="50" multiple /></span><br /><br />
		Files to be uploaded:<br />
		<table><tbody id="files_list"></tbody></table>
		<script>
			var multi_selector =
				new MultiSelector( document.getElementById( 'files_list' ), 0,
						document.getElementById( 'my_file_element' ).className ,
						document.getElementById( 'my_file_element' ).size, <%=bBlockPosting%> );
			multi_selector.addElement( document.getElementById( 'my_file_element' ) );
		</script>
		</td>
		</tr>

<%	if (bSendUploadFileEmail || true)
	{
%>
		<tr><td class="td_value_bg"><img src='../i/spacer.gif' width='10'/></td></tr>

	    <tr><td class="td_value_bg">
		<input type="checkbox" name="OptMsg" onclick="showMessage('optMessage')" />&nbsp;Add personal message to notification Email
		</td></tr>

		<tr><td class="td_value_bg">
		<div id='optMessage' style='display:none'>
		<table>
			<tr>
				<td width="15">&nbsp;</td>
		        <td class="plaintext_grey">
				You may add an optional personal message to the notification Email:
	        	</td>
			</tr>
			<tr>
				<td width="15">&nbsp;</td>
				<td><table border='0' cellspacing='0' cellpadding='0'>
					<tr>
		        		<td class="formtext" width='90'><b>Subject:</b></td>
		        		<td><input type='text' class='formtext' size='63' id='OptSubject' name='OptSubject'></input></td>
		        	</tr></table>
	        	</td>
			</tr>
			<tr>
				<td width="15">&nbsp;</td>
			   	<td>
			      <textarea name="message" cols="58" rows="5"><%=optMsg%></textarea>
			   	</td>
			</tr>
			<tr>
				<td width="15">&nbsp;</td>
				<td><table border='0' cellspacing='0' cellpadding='0'>
					<tr>
						<td class="formtext" width='90'><b>Guest Email:</b></td>
						<td><input type='text' class='formtext' size='63' name='OptGuest'></input></td>
					</tr>
					<tr>
						<td></td>
						<td class='plaintext_grey'>E.g. john@abc.com, mary@xyz.com</td>
					</tr></table>
	        	</td>
			</tr>
<%	if (!isMultiCorp) { %>
			<tr>
				<td width="15">&nbsp;</td>
				<td><table border='0' cellspacing='0' cellpadding='0'>
					<tr>
						<td class="formtext" width='90'><b>User List:</b></td>
						<td><input type='text' class='formtext' size='63' name='UserList'></input></td>
					</tr>
					<tr>
						<td></td>
						<td class='plaintext_grey'>E.g. PE Distribution_List, DL.Marketing</td>
					</tr></table>
	        	</td>
			</tr>
<%	} %>
		</table>
		</div>
		</td></tr>
<%	}
%>

		<tr><td class="td_value_bg"><img src='../i/spacer.gif' width='5'/></td></tr>

		<tr id='uploadButton' style='display:none;'><td class="td_value_bg">
		<input class="plaintext" type="submit" id='uploadBut' name="add" value="Upload Files" onclick="return setAddFile();" />
		<span class='plaintext_grey'>Click to complete uploading files <%if (bSendUploadFileEmail) {out.print("and send notification Email");} %></span>
<%	if (isMultiCorp) { %>
		<span class='plaintext'>&nbsp;&nbsp;<input type='checkbox' name='google' onclick='checkGoogle();' />as Google Docs</span>
<%	} %>
		</td></tr>

	</table>
	</td>
</tr>

<!-- add Google Docs -->
<tr bgcolor="#FFFFFF">
	<td class="td_field_bg" width="160"><a name='updAtt'></a>Add Google Docs</td>
	<td class="td_value_bg">
		<table border="0" cellspacing="0" cellpadding="0">
			<tr>
				<td class='td_value_bg'>
					<img src='../i/bullet_tri.gif'/>
						<a href='javascript:addGoogleLink();'>Click to add a link to a Google Docs</a>
				</td>
			</tr>
			<tr>
				<td>
				<div id='DIV_GoogleLink' style='display:none'>
					<table>
						<tr>
						<td class='td_value_bg' width='120'>Filename:</td>
						<td><input type='text' name='GoogleFileName' id='Gfname' size='50'/></td>
						</tr>
						<tr>
						<td class='td_value_bg' style='vertical-align:top;'>Location:</td>
						<td><input type='text' name='GoogleExtLink' id='Glink' size='80'/>
						</td>
						</tr>
						<tr><td></td>
						<td class='plaintext_grey'>(Copy-and-paste the Google Docs URL here)</td>
						</tr>
						<tr>
						<tr><td colspan='2'><img src='../i/spacer.gif' height='5'/></td></tr>
						<td colspan='2' align='center'>
							<input type='button' class='Button_Medium' value='Submit' onclick='submitAddGoogleExtFile();' />
							<input type='button' class='Button_Medium' value='Cancel' onclick='addGoogleLink();' />
						</td>
						</tr>
					</table>
				</div>
				</td>
			</tr>
		</table>
	</td>
</tr>


<!-- list file attachments -->
<tr bgcolor="#FFFFFF">
	<td class="td_field_bg" width="160"><a name='updAtt'></a>File Attachments</td>
	<td class="td_value_bg">


<%
	////////////////////////////////////
	// @102604ECC
	// @SWS061406 begins
	Object [] attmtList = taskObj.getAttribute("AttachmentID");
	int [] aids = Util2.toIntArray(attmtList);
	int [] linkIds = attMgr.findId(pstuser, "Link='" + taskID + "'");		// @ECC103008
	aids = Util2.mergeIntArray(aids, linkIds);
	attachment attmtObj;
	String fileName, desc;
	Date attmtCreateDt;
	
	out.print("<table width='100%' border='0' cellspacing='0' cellpadding='0'>");

	// display header for attachments
	int colSpanNum = 1;
	if ( aids.length>0 || (bShowBfile && blogIdArr!=null && blogIdArr.length>0) ) {
		out.print("<tr><td>");
		String [] label0 = {"&nbsp;File Name", "Posted On", "Size", "Owner", "Action"};
		int [] labelLen0 = {0, 140, 50, 90, 60};
		boolean [] bAlignCenter0 = {false, true, true, true, true};
		out.print(Util.showLabel(label0, null, null, null,
			labelLen0, bAlignCenter0, true));	// sort, showAll and align center
		
		colSpanNum = label0.length * 3 - 1;
	}

	String uname;
	int attId;
	if (aids.length > 0)
	{		
		// sort the attachment by dates, show the latest first
		PstAbstractObject [] attObjArr = attMgr.get(pstuser, aids);
		Util.sortDate(attObjArr, "CreatedDate", true);

		String dept;
		Object bTextObj;
		boolean isLink;
		for (int i=0; i<attObjArr.length; i++)
		{
			// list files by chronological order
			attmtObj = (attachment) attObjArr[i];
			isLink=false;
			for (int q=0;q<linkIds.length;q++) if (linkIds[q]==attmtObj.getObjectId()) {isLink=true;break;}
			uname = attmtObj.getOwnerDisplayName(pstuser);
			Date attmtCreate = (Date)attmtObj.getAttribute("CreatedDate")[0];
			fileName = attmtObj.getFileName();
			dept = (String)attmtObj.getAttribute("DepartmentName")[0];
			if (dept == null) dept = "";
			else dept = dept.replaceAll("@", "; ");
			attId = attmtObj.getObjectId();
			desc = null;
			bTextObj = attmtObj.getAttribute("Description")[0];
			if (bTextObj != null)
				desc = new String((byte[]) bTextObj, "utf-8");
			
			// file name
			out.print("<tr>");
			out.print("<td></td>");
			out.print("<td><table width='100%' border='0' cellspacing='0' cellpadding='5'>");
			out.print("<tr><td class='ptextS1' width='20'>"
						+ (i+1) + ".</td>" );
			out.print("<td title='" + dept + "'><a class='ptextS1' href='" + host + "/servlet/ShowFile?attId="
					+ attId + "'>" + fileName + "</a>");
			if (attmtObj.isGoogle())
				out.print("&nbsp;<img src='../i/Gdocs_b.gif' title='this is a Google Docs' />");
			out.print("</td></tr></table></td>");

			// date posted on
			out.print("<td colspan='2'></td>");
			out.print("<td class='formtext' align='center'>" + df1.format(attmtCreate) + "</td>");

			// size
			out.print("<td colspan='2'></td>");
			out.print("<td class='formtext' align='right'>" + Util2.fileSizeDisplay(attmtObj.size()) + "&nbsp;</td>");

			// owner
			out.print("<td colspan='2'></td>");
			out.print("<td class='formtext' align='center'><a href='../ep/ep1.jsp?uid="
					+ (String)attmtObj.getAttribute("Owner")[0] + "' class='listlink'>"
					+ uname + "</a></td>");

			// action
			out.print("<td colspan='2'></td>");
			out.print("<td align='center'><table cellspacing='0' cellpadding='0'><tr>");
			if (isLink) {
				out.println("<td><img src='../i/spacer.gif' width='10' />"
						+ "<img src='../i/link.gif' title='this is a linked file' /></td>");
			}
			else {
				// edit
				out.println("<td><img src='../i/spacer.gif' width='10' />"
						+ "<a href='task_update.jsp?projId=" + projIdS
						+ "&pTaskId=" + pTaskId + "&update=" + attId + "#updAtt"
						+ "'><img src='../i/note_tr.gif' border='0' title='file details' /></a></td>");
			}

			// support update/review of attachment attributes
			fileName = fileName.replaceAll("'", "@@");
			
			if (isAuthorizedUser)
			{
				// delete
				out.println("<td><img src='../i/spacer.gif' width='10' />"
						+ "<a href=\"javascript:affirm_delfile('post_delfile.jsp?projId=" + projIdS
						+ "&taskId=" + taskID + "&pTaskId=" + pTaskId + "&attId=" + attId	//"&fname=Attachment-" + fileName
						+ "');\"><img src='../i/delete.gif' border='0' title='delete' /></a></td>");
			}
			out.print("</tr></table></td>");	// close: action
			out.print("</tr>");					// close: one line of file attachment

			// now display the description
			if (!StringUtil.isNullOrEmptyString(desc)) {
				out.print("<tr>");
				out.print("<td colspan='" + colSpanNum + "' class='plaintext' style='padding:0 5em 0 4em;'>");	// t,b,r,l
				out.print(desc + "</td>");
				//out.print("<td colspan='6'></td>");
				out.print("</tr>");
			}
			
			out.println("<tr><td colspan='" + colSpanNum + "'><img src='../i/spacer.gif' height='3'/></td></tr>");
		}	// END for each task attachment
	}
	else {
		// no task files
		out.print("<tr><td class='plaintext_grey'>None</td></tr>");
	}

	// @102604ECC End
	////////////////////////////////
	if (bShowBfile)
	{
		out.print("<tr><td><img src='../i/spacer.gif' height='5' border='0'></td></tr>");
		out.print("<tr>");
		out.print("<td class='blog_line' colspan='" + colSpanNum + "' ><b>");
		out.print("BLOG FILE");
		out.print("</b></td></tr>");
		out.print("<tr><td colspan='" + colSpanNum + "'><img src='../i/mid/wkln.gif' height='2' width='100' border='0'></td></tr>");
		out.print("<tr><td colspan='" + colSpanNum + "'><img src='../i/spacer.gif' height='5' border='0'></td></tr>");

		// list the blog files now
		// first get all the blogs belonging to this bug
		Object [] attIds;
		int ct = 0;
		for (int i=0; i<blogIdArr.length; i++)
		{
			o = rMgr.get(pstuser, blogIdArr[i]);
			attIds = o.getAttribute("AttachmentID");
			if (attIds.length<=0 || attIds[0]==null) continue;

			for (int j=0; j<attIds.length; j++)
			{
				// list all the attachments from this one blog
				attmtObj = (attachment)attMgr.get(pstuser, (String)attIds[j]);
				uname = attmtObj.getOwnerDisplayName(pstuser);
				attmtCreateDt = (Date)attmtObj.getAttribute("CreatedDate")[0];
				fileName = attmtObj.getFileName();
				ct++;
				
				out.print("<tr><td><table border='0' cellspacing='0' cellpadding='5'>");
				out.print("<tr><td class='ptextS1' width='20'>" + ct + ".</td>");
				out.print("<td><a class='ptextS1' href='" + host + "/servlet/ShowFile?attId="
						+ attmtObj.getObjectId() + "'>" + fileName + "</a></td>");
				out.print("</tr></table></td>");
				
				out.print("<td colspan='2'>&nbsp;</td>");
				out.print("<td class='formtext' valign='top'><a href='../ep/ep1.jsp?uid="
					+ (String)attmtObj.getAttribute("Owner")[0] + "' class='listlink'>" + uname + "</a></td>");
				out.print("<td colspan='2'>&nbsp;</td>");
				out.print("<td class='formtext' valign='top'>" + df1.format(attmtCreateDt) + "</td>");
				out.print("<td>&nbsp;</td></tr>");
			}	// End: for each attachment in this blog
		}		// End: for each blog
	}			// End: if bShowFile

	if ( aids.length>0 || (bShowBfile && blogIdArr!=null && blogIdArr.length>0) ) {
		out.print("</table>");	// close the table in showLabel()
	}

%>
		</table>
	</td>
</tr>

<%
	// @ECC061108 Support update attachment attributes
	s = request.getParameter("update");
	if (s!=null)
	{
		// get the update document info
		String disabledStr;
		if (isAuthorizedUser) disabledStr = "";
		else disabledStr = " disabled";

		attmtObj = (attachment)attMgr.get(pstuser, s);
		attId = attmtObj.getObjectId();
		int attOwnerId = 0;
		try {attOwnerId = Integer.parseInt((String)attmtObj.getAttribute("Owner")[0]);}
		catch (Exception e) {}
		fileName = attmtObj.getFileName();
		deptName = (String)attmtObj.getAttribute("DepartmentName")[0];
		if (deptName == null) deptName = "";
		else deptName = deptName.replaceAll("@", "; ");
		desc = attmtObj.getRawAttributeAsString("Description");
		if (desc == null) desc = "";

		out.print("<tr><td></td>");
		out.print("<td class='td_value_bg'><table width='100%' border='0' cellspacing='0' cellpadding='0'>");
		out.print("<tr><td class='plaintext_blue'>Update File Attributes</td></tr>");
		out.print("<tr><td><table width='100%' border='0' cellspacing='0' cellpadding='0'>");
		out.print("<tr><td colspan='2'><img src='../i/spacer.gif' height='5' /></td></tr>");

		// file name
		out.print("<tr><td class='plaintext'><b>File</b>:</td>");
		out.print("<td class='plaintext'>&nbsp;<b>" + fileName + "</b></td></tr>");
		out.print("<tr><td colspan='2'><img src='../i/spacer.gif' height='5' /></td></tr>");

		// owner
		out.print("<tr><td class='plaintext'><b>Owner</b>:</td>");
		out.print("<td class='plaintext'>&nbsp;");
		out.print("<select class='formtext' name='AttOwner'" + disabledStr + ">");
		out.print("<option value=''>- select owner -</option>");
		for(int a=0; a < teamMember.length; a++)
		{
			int id = teamMember[a].getObjectId();
			uname = ((user)teamMember[a]).getFullName();
			out.print("<option value=" + id);
			if (attOwnerId == id)
				out.print(" selected");
			out.print(">" + uname + "</option>");
		}
		out.print("</select>");
		out.print("</td></tr>");
		out.print("<tr><td colspan='2'><img src='../i/spacer.gif' height='5' /></td></tr>");

		// description
		out.print("<tr><td class='plaintext' valign='top'><b>Description</b>:</td>");
		out.print("<td class='plaintext'>&nbsp;");
		out.print("<textarea class='formtext' name='AttDescription' rows='4' style='width:93%'" + disabledStr + ">");
		out.print(desc);
		out.print("</textarea></td></tr>");
		out.print("<tr><td colspan='2'><img src='../i/spacer.gif' height='5' /></td></tr>");

		// file classification (department)
		out.print("<tr><td class='plaintext' valign='top'><b>Department</b>:</td>");
		out.print("<td class='plaintext'>");
		out.print("<table border='0' cellspacing='4' cellpadding='0'>");
		out.print("<tr>");
		out.print("<td bgcolor='#FFFFFF'>");
		out.print("<select class='formtext_fix' name='AttAllDepartment' multiple size='5'" + disabledStr + ">");
		if (allDept != null)
		for (int i=0; i<allDept.length; i++)
		{
			if (allDept[i] == null) continue;		// ignored
			s = allDept[i];
			if (deptName.indexOf(s) != -1)
				continue;							// already chosen as the attmt dept
			out.print("<option value='" + s + "'");
			out.print(">" + s + "</option>");
		}
		out.print("</select>");
		out.print("</td>");

		out.print("<td align='center' valign='middle' class='td_value_bg'>");
		out.print("<input type='button' class='button' name='add' value='&nbsp;&nbsp;&nbsp;Add &gt;&gt;&nbsp;&nbsp;' onClick='swapdata(this.form.AttAllDepartment,this.form.AttDepartments)'>");
		out.print("<br><input type='button' class='button' name='remove' value='<< Remove' onClick='swapdata(this.form.AttDepartments,this.form.AttAllDepartment)'>");
		out.print("</td>");

		out.print("<td bgcolor='#FFFFFF'>");
		out.print("<select class='formtext_fix' name='AttDepartments' multiple size='5'" + disabledStr + ">");

		if (deptName.length() > 0)
			myDepts = deptName.split("; ");
		else
			myDepts = null;
		if (myDepts!= null && myDepts.length > 0 && myDepts[0] != null)
		{
			for (int i=0; i < myDepts.length; i++)
				out.print("<option value='" +myDepts[i]+ "'>" +myDepts[i]+ "</option>");
		}
		out.print("</select>");
		out.print("</td>");
		out.print("</tr>");
		out.print("</table>");
		out.print("</td>");
		out.print("<tr><td colspan='2'><img src='../i/spacer.gif' height='5' /></td></tr>");
		// END: department
		
		// Google link
		if (attmtObj.isGoogle()) {
			out.print("<tr><td class='plaintext'><b>Google Doc</b>:</td>");
			out.print("<td class='plaintext'>&nbsp;");
			out.print("<input type='text' class='formtext' name='GoogleLink' style='width:98%' value='"
					+ attmtObj.getStringAttribute("Location") + "'>");
			out.print("</td></tr>");
			out.print("<tr><td colspan='2'><img src='../i/spacer.gif' height='5' /></td></tr>");
		}
		out.print("<tr><td colspan='2'><img src='../i/spacer.gif' height='10' /></td></tr>");

		// buttons for form
		if (isAuthorizedUser) {
			out.print("<tr><td colspan='2'>");
			out.print("<img src='../i/spacer.gif' width='310' height='1' />");
			out.print("<input type='Button' value='Update' class='button_medium' onclick='javascript:updateAttmt(" + attId + ");'>");
			out.print("<img src='../i/spacer.gif' width='30' height='1' />");
			out.print("<input type='Button' value='Cancel' class='button_medium'");
			out.print("onclick='location=\"task_update.jsp?projId=" + projIdS + "&pTaskId=" + pTaskId + "\"'>");
			out.print("</td></tr>");
		}

		out.print("</table></td></tr>");
		out.print("</table>");
		out.print("</td>");
		out.println("<tr>");
	}	// END update attachment attributes

	// after the list of attachment
	out.println("<tr><td></td><td class='plaintext' align='right'><a href=''>Download all files</a></td></tr>");
	
	// @ECC100708 paste from clipboard
	s = (String)session.getAttribute("clipboard");
	if (s != null)
	{
		out.print("<tr><td></td><td><table><tr>");
		out.print("<td><img src='../i/clipboard.jpg' /></td>");
		out.print("<td class='plaintext'><a href='javascript:paste();'>Paste from Clipboard</a></td></tr></table></td></tr>");

		// put the form for selecting files as display:none
		out.print("<tr><td></td><td><div id='clipboard' style='display:none'>");
		out.print("<input type='hidden' name='backPage' value='task_update.jsp?projId="
				+ projIdS + "&pTaskId=" + pTaskId + "'>");
		out.print("<table>");
		sa = s.split(";");
		int ct = 0;
		for (int i=0; i<sa.length; i++)
		{
			try {o = attMgr.get(pstuser, sa[i]);}
			catch (PmpException e) {continue;}
			ct++;
			s = (String)o.getAttribute("Location")[0];
			s = s.substring(s.lastIndexOf("/")+1);
			out.print("<tr><td class='formtext'><input type='checkbox' name='clip_" + sa[i]
			      + "'>" + s + "</td></tr>");
		}
		if (ct <= 0) {
			// no files in the list; might be deleted
			session.removeAttribute("clipboard");
%>		
<script language="JavaScript">
<!--
			location = parent.document.URL;
//-->
</script>
<%			
		}

		// buttons: clip() is in multifile.js which calls post_clipAction.jsp
		out.print("<tr><td class='formtext' align='center'>"
				+ "<input class='formtext' type='button' name='Link' value='&nbsp;Link&nbsp;' onclick='clip(0, updateTask);'>&nbsp;&nbsp;"
				+ "<input class='formtext' type='button' name='Copy' value='Copy' onclick='clip(1, updateTask);'>&nbsp;&nbsp;"
				+ "<input class='formtext' type='button' name='Move' value='Move' onclick='clip(2, updateTask);'>&nbsp;&nbsp;"
				+ "<input class='formtext' type='button' name='Cancel' value='Cancel' onclick='closeClip();'>"
				+ "</td></tr>");
		out.print("</table>");
		out.print("</div>");
		out.print("</td></tr>");
	}

	///////////////////////////////////////////////////////////////////////////
%>

<tr><td class="title" valign="bottom"><br/>Task Management</td>
<td></td>
</tr>

<tr>
	<td colspan='2'>
		<img src='../i/bullet_tri.gif'/>
			<a class='listlinkbold' id='taskMgmtHint' href='javascript:taskMgmt();'>Click to manage task</a>
	</td>
</tr>

<!-- Manage task Panel begins -->
<tr>
	<td colspan='2'>
	<div id='DIV_TaskMgmt' style='display:none'>
	<table width="100%" border="0" cellspacing="2" cellpadding="4" bgcolor="#FFFFFF">

<!-- Task Name -->
		<tr bgcolor="#FFFFFF">
		<td class="td_field_bg" width="200">* Task Name</td>
		<td class="td_value_bg">
			<input type='text' class='formtext' name='TaskName' size='100'
				value='<%=taskName%>' <%=UserEdit%> />
		</td>
		</tr>

<!-- Task Owner -->
		<tr bgcolor="#FFFFFF">
		<td class="td_field_bg" width="200">* Task Owner</td>
		<td class="td_value_bg">
		<select class="formtext" name="Owner"  <%=UserEdit %>>
		<option value=''>- select owner -</option>
<%

	// all project team people
	out.print(Util.selectMember(teamMember, taskOwnerId));

%>
		</select>

		&nbsp;&nbsp;&nbsp;<input class="formtext" <%=UserEdit%> type="checkbox" name="ChildOwner" />
			<span class='plaintext'>Transfer ownership of all the sub-tasks of this task to this person</span>
		</td>
		</tr>

<!-- @ECC011707 task DepartmentName -->
<!-- @ECC060407 support combination of departments -->
<%
	if (bHasCompany)
	{
		out.print("<tr bgcolor='#FFFFFF'>");
		out.print("<td class='td_field_bg' width='160'>Access Control</td>");
		out.print("<td class='td_value_bg'>");
		out.print("<table border='0' cellspacing='4' cellpadding='0'>");
		out.print("<tr>");
		out.print("<td bgcolor='#FFFFFF'>");
		out.print("<select class='formtext_fix' name='AllDepartment' multiple size='5'>");
		if (allDept != null)
		for (int i=0; i<allDept.length; i++)
		{
			if (allDept[i] == null) continue;		// ignored
			s = allDept[i];
			out.print("<option value='" + s + "'");
			out.print(">" + s + "</option>");
		}

		out.print("</select>");
		out.print("</td>");

		out.print("<td align='center' valign='middle' class='td_value_bg'>");
		out.print("<input type='button' class='button' name='add' value='&nbsp;&nbsp;&nbsp;Add &gt;&gt;&nbsp;&nbsp;' onClick='swapdata(this.form.AllDepartment,this.form.Departments)'>");
		out.print("<br><input type='button' class='button' name='remove' value='<< Remove' onClick='swapdata(this.form.Departments,this.form.AllDepartment)'>");
		out.print("</td>");

		out.print("<td bgcolor='#FFFFFF'>");
		out.print("<select class='formtext_fix' name='Departments' multiple size='5'>");

		if (myDepts!= null && myDepts.length > 0 && myDepts[0] != null)
		{
			for (int i=0; i < myDepts.length; i++)
				out.print("<option value='" +myDepts[i]+ "'>" +myDepts[i]+ "</option>");
		}
		out.print("</select>");
		out.print("</td>");

		out.print("</tr>");
		out.print("</table>");
		out.print("</td>");
		out.print("</tr>");
	}	// END if bHasCompany
%>

<!-- status -->
		<tr bgcolor="#FFFFFF">
		<td class="td_field_bg">* Task Status</td>
		<td class="td_value_bg">
		Select status:<br/>
		<select class="formtext" <%=UserEdit %>  name="Status">

<%
		String [] StateValAry = task.STATE_ARRAY;

	// @AGQ101804
	// These section of jsp handles the options list avaliable to user
	//			when the user wants to update their task
	// variable test = 0 if we want all the options of New, Open, On-hold, Late, Completed, Canceled
	//			test = 1 if we don't want the user to be able to select any wrong state transitions

	int test = 1;
	if (isAdmin) test = 0;
	if(test == 0) {
		for(int i = 0; i < StateValAry.length; i++)
		{
			if (tStatus != null && tStatus.equals(StateValAry[i]))
				out.println("<option name='" + StateValAry[i] + "' value='" + StateValAry[i] + "' selected>" + StateValAry[i]);
			else
				out.println("<option name='" + StateValAry[i] + "' value='" + StateValAry[i] + "'>" + StateValAry[i]);
		}
	}
	else {
		int ii;		// 0 = task.ST_NEW, 1 = task.ST_OPEN, 2 = task.ST_ONHOLD, 3 = task.ST_LATE, 4 = task.ST_COMPLETE,
					// 5 = task.ST_CANCEL


		// Status: 		New Transition
		// Options: 	Open Transition
		// Comments: 	New -> Open
		// System: 		New -> Open, New -> Late, New -> Canceled (by parent)
		if (tStatus != null && tStatus.equals(task.ST_NEW)) {
			ii = 0;
			out.println("<option name='" + StateValAry[ii] + "' value='" + StateValAry[ii] + "' selected>" + StateValAry[ii]);
			ii = 1;
			out.println("<option name='" + StateValAry[ii] + "' value='" + StateValAry[ii] + "'>" + StateValAry[ii]);
		}
		// Status: 		Open Transition
		// Options: 	On-hold, Completed, Canceled Transition
		// Comments: 	Open -> On-hold, Open -> Completed, Open -> Canceled
		// System: 		Open -> Late

		else if (tStatus != null && tStatus.equals(task.ST_OPEN)) {
			ii = 1;
			out.println("<option name='" + StateValAry[ii] + "' value='" + StateValAry[ii] + "' selected>" + StateValAry[ii]);
			ii = 2;
			out.println("<option name='" + StateValAry[ii] + "' value='" + StateValAry[ii] + "'>" + StateValAry[ii]);
			ii = 4;
			out.println("<option name='" + StateValAry[ii] + "' value='" + StateValAry[ii] + "'>" + StateValAry[ii]);
			ii = 5;
			out.println("<option name='" + StateValAry[ii] + "' value='" + StateValAry[ii] + "'>" + StateValAry[ii]);
		}

		// Status: 		On-hold Transition
		// Options: 	Open, Canceled Transition
		// Comments: 	On-hold -> Open, On-hold -> Canceled
		// System: 		On-hold -> Late

		else if (tStatus != null && tStatus.equals(task.ST_ONHOLD)) {
			ii = 2;
			out.println("<option name='" + StateValAry[ii] + "' value='" + StateValAry[ii] + "' selected>" + StateValAry[ii]);
			ii = 1;
			out.println("<option name='" + StateValAry[ii] + "' value='" + StateValAry[ii] + "'>" + StateValAry[ii]);
			ii = 5;
			out.println("<option name='" + StateValAry[ii] + "' value='" + StateValAry[ii] + "'>" + StateValAry[ii]);
		}
		// Status: 		Late Transition
		// Options: 	Completed, Canceled Transition
		// Comments: 	Late -> Completed, Late -> Canceled
		// System: 		Late -> Open (changing the expiration date)

		else if (tStatus != null && tStatus.equals(task.ST_LATE)) {
			ii = 3;
			out.println("<option name='" + StateValAry[ii] + "' value='" + StateValAry[ii] + "' selected>" + StateValAry[ii]);
			ii = 4;
			out.println("<option name='" + StateValAry[ii] + "' value='" + StateValAry[ii] + "'>" + StateValAry[ii]);
			ii = 5;
			out.println("<option name='" + StateValAry[ii] + "' value='" + StateValAry[ii] + "'>" + StateValAry[ii]);

		}
		// Status: 		Completed Transition
		// Options: 	null
		// Comments: 	Completed tasks are finished.
		// System: 		none

		else if (tStatus != null && tStatus.equals(task.ST_COMPLETE)) {
			ii = 4;
			out.println("<option name='" + StateValAry[ii] + "' value='" + StateValAry[ii] + "' selected>" + StateValAry[ii]);
		}

		// Status: 		Canceled Transition
		// Options: 	null
		// Comments: 	Canceled tasks are closed, unless specified as service to do so.
		// System: 		none
		else if (tStatus != null && tStatus.equals(task.ST_CANCEL)) {
			ii = 5;
			out.println("<option name='" + StateValAry[ii] + "' value='" + StateValAry[ii] + "' selected>" + StateValAry[ii]);
		}
	}

%>
		</select>
<%	if (completeDt != null && !phase.isSpecialDate(completeDt))
	{%>
		&nbsp;&nbsp;&nbsp;<b>Completed on <%=df.format(completeDt)%></b>
<%	}
%>
		</td>
		</tr>
<%if (!isCRAPP || isTaskDeadline) {

	// ECC: support Original Plan Dates
	Date oriStDate, oriExDate;
	String oriStDateS="", oriExDateS="";

	oriStDate = (Date)taskObj.getAttribute("OriginalStartDate")[0];
	if (oriStDate != null) oriStDateS = df.format(oriStDate);

	oriExDate = (Date)taskObj.getAttribute("OriginalExpireDate")[0];
	if (oriExDate != null) oriExDateS = df.format(oriExDate);

	String oriUserEdit = "disabled";
	String oriUserEditCal = "onClick='return false'";
	if (projStatus.equals(project.ST_NEW) || projOwnerId==myUid) {
		oriUserEdit = "";
		oriUserEditCal = "";
	}
%>
<!-- original start/expire dates -->
	<tr bgcolor="#FFFFFF">
		<td class="td_field_bg" width="160">Original Dates</td>
		<td class="td_value_bg">Start Date:
			<input class="formtext" <%=oriUserEdit %>  type="text" name="OriStartDate" size="23" value='<%=oriStDateS%>'  onclick="show_cal(updateTask.OriStartDate);"/>
			&nbsp;<a href="javascript:show_cal(updateTask.OriStartDate);" <%=oriUserEditCal%> ><img src="../i/calendar.gif" border="0" align="absmiddle" alt="Click to view calendar."/></a>

			&nbsp;&nbsp;&nbsp;

			Expire Date:
			<input class="formtext" <%=oriUserEdit %>  type="text" name="OriExpireDate" size="23" value='<%=oriExDateS%>'  onclick="show_cal(updateTask.OriExpireDate);"/>
			&nbsp;<a href="javascript:show_cal(updateTask.OriExpireDate);" <%=oriUserEditCal%> ><img src="../i/calendar.gif" border="0" align="absmiddle" alt="Click to view calendar."/></a>
		</td>
	</tr>

<!-- start date -->
	<tr bgcolor="#FFFFFF">
		<td class="td_field_bg" width="160">Plan Start Date</td>
		<td class="td_value_bg">
			<input class="formtext" <%=UserEdit %>  type="text" name="StartDate" size="30" value='<%if (startDateS !=null) out.print(startDateS); %>'  onclick="show_cal(updateTask.StartDate);" />
			&nbsp;<a href="javascript:show_cal(updateTask.StartDate);" <%=UserEditCal%> ><img src="../i/calendar.gif" border="0" align="absmiddle" alt="Click to view calendar." /></a>

			&nbsp;&nbsp;&nbsp;<input class="formtext" <%=UserEdit%> type="checkbox" name="ChildStart" />
				<span class='plaintext'>Set all the sub-tasks of this task to this Start Date</span>
		</td>
	</tr>

<!-- expire date -->
	<tr bgcolor="#FFFFFF">
		<td class="td_field_bg" width="160">Plan Expire Date</td>
		<td class="td_value_bg">
			<input class="formtext" <%=UserEdit %>  type="text" name="ExpireDate" size="30" value='<%if (expDateS !=null) out.print(expDateS); %>'  onclick="show_cal(updateTask.ExpireDate, updateTask.StartDate);"/>
			&nbsp;<a href="javascript:show_cal(updateTask.ExpireDate, updateTask.StartDate);"  <%=UserEditCal%> ><img src="../i/calendar.gif" border="0" align="absmiddle" alt="Click to view calendar."/></a>

			&nbsp;&nbsp;&nbsp;<input class="formtext" <%=UserEdit%> type="checkbox" name="ChildExpire" />
				<span class='plaintext'>Set all the sub-tasks of this task to this Expire Date</span>
		</td>
	</tr>

<!-- actual start date -->
	<tr bgcolor="#FFFFFF">
		<td class="td_field_bg" width="160">Actual Start Date</td>
		<td class="td_value_bg">
			<%=actualDateS%>
		</td>
	</tr>

<%	if (completeDt != null) { %>
<!-- actual finish date -->
	<tr bgcolor="#FFFFFF">
		<td class="td_field_bg" width="160">Actual Finish Date</td>
		<td class="td_value_bg">
			<%=df.format(completeDt)%>
		</td>
	</tr>
<%	}


	if (!isCRAPP)
	{
	if (gap==0) s = ""; else s = String.valueOf(gap);%>
<!-- gap -->
	<tr>
		<td class="td_field_bg" width="160">Gap</td>
		<td class="td_value_bg">
			<input class="formtext" type="text" name="Gap" size="3" value="<%=s%>"
				onchange='check_dateSetting()' <%=UserEdit%> />
			<span class='plaintext'><b>Days</b> after the latest dependent task completed,
				or after project starts if no dependency</span>
		</td>
	</tr>

<%	if (duration==0) s=""; else s = String.valueOf(duration);%>
<!-- duration -->
	<tr>
		<td class="td_field_bg" width="160">Duration</td>
		<td class="td_value_bg">
			<input class="formtext" type="text" name="Dur" size="3" value="<%=s%>"
				onchange='check_dateSetting()' <%=UserEdit%> />
			<span class='plaintext'><b>Days</b> representing the length of this task
				including weekends and holidays</span>
		</td>
	</tr>

<script type="text/javascript">
<!--
	check_dateSetting();	// chk to see if we need to disable StartDate and ExpireDate
//-->
</script>

<!-- Resource Management -->
<%
	if ((optStr = projObj.getOption(project.OP_RESOURCE_MGMT)) != null) {
		// with resource managment, allow user to input the weight of this task
		sa = optStr.split(project.DELIMITER2);		// float@hr/wk
		String optAttr = sa[0];
		String optUnit = sa[1];

		// get current value
		DecimalFormat dcf = new DecimalFormat("#0.0");
		Double d = (Double)taskObj.getAttribute(optAttr)[0];
		s = dcf.format(d);
		out.print("<tr><td class='td_field_bg' width='160'>Weight</td>");
		out.print("<td class='td_value_bg'>");
		out.print("<input class='formtext' type='text' name='Weight' size='3' value='" + s + "'>");
		out.print("<span class='plaintext'><b>&nbsp;&nbsp;" + optUnit + "</b></span>");
		out.print("</td></tr>");
	}
%>


<!-- PR -->
<%
	if (MOD_BUG_TRACK)
	{%>
<tr bgcolor="#FFFFFF">
	<td class="td_field_bg" width="160">Problem Reports</td>
	<td class="td_value_bg">
		<table border="0" cellspacing="0" cellpadding="0">
		<tr><td width="235">
		<table border="0" cellspacing="0" cellpadding="0">
<%
	////////////////////////////////////
	// @012505ECC
		bugManager bMgr = bugManager.getInstance();
		int bugIdList[] = bMgr.findId(pstuser, "TaskID='" + taskID + "'");
		if (bugIdList.length <= 0)
		{
			out.println("<tr><td class='plaintext_grey'>None</td></tr>");
		}
		else
		{
			Arrays.sort(bugIdList);
			int bId, num=0;
			for (int i=0; i<bugIdList.length; i++)
			{
				// list bugs associated to this task
				if (num%3 == 0) out.print("<tr>");
				bId = bugIdList[i];
				out.print("<td class='plaintext' width='75'>");

				out.print("<a class='listlink' href='../bug/bug_update.jsp?bugId="
					+ bId + "'>" + bId + "</a></td>");
				if (num%3 == 2) out.print("</tr>");
				num++;
			}
			if (num%3 != 0) out.print("</tr>");
		}
	// @012505ECC End
	////////////////////////////////
%>
		</table>
		</td>

		<td><b>&gt;&gt;&nbsp;<a class='listlink' href='../bug/bug_update.jsp?edit=true&taskId=<%=taskID%>'>
			Add New PR</a></b></td>
		</tr>
		</table></td></tr>
<%	}	// end if MOD_BUG_TRACK
	} 	// end of if !isCRAPP || !isTaskDeadline
%>
<!-- Task Blog Template -->
	<tr bgcolor='#FFFFFF'>
		<td class='td_field_bg'>Task Blog Template</td>
		<td class='td_value_bg'>
			<input class='formtext' type='text' size='8' name='TaskBlogId' value='<%=taskBlogIdS%>' />
		</td>
	</tr>

<%
	}	// END if !isCRAPP
%>
	</table>
	</div>
	</td>
</tr>
<!-- Manage task panel ends -->


<!-- Alert Message -->
<tr><td class="title" valign="bottom"><br/>Task Reminder Alert</td>
<td></td>
</tr>

<%if (!isCRAPP || isTaskDeadline){%>
<!-- Alert Condition (get options from Config file) -->
<tr>
	<td width="120" class="td_field_bg"><strong>Alert Condition</strong></td>
	<td  class="td_value_bg">
		<select class="formtext" name="AlertCondition" <%=UserEdit%>>
<%
		// get option values from config file
		int condition = 0;	// from database
		Integer iObj = (Integer)taskObj.getAttribute("AlertCondition")[0];
		if (iObj != null) condition = iObj.intValue();
		int optionTotal = Integer.parseInt(Util.getPropKey("bringup", "TASK.ALERT.CONDITION"));
		String [] optionValue = null;

		for (int i = 0; i < optionTotal;)
		{
			// option value will be 1, 2, 3, ... etc.
			out.print("<option value="+ ++i);
			if (condition == i) out.print(" selected>");
			else out.print(">");
			out.println(Util.getPropKey("bringup", "TASK.ALERT.CONDITION."+i));
		}
%>
		</select>

	</td>
</tr>
<%}	// end if !isCRAPP %>


<!-- Alerted Personnel -->
<tr>
		<td class="td_field_bg"><strong>Alert Personnel </strong></td>
		<td class="td_value_bg">
		<!-- Managed Pesonnel -->
<%
//@AGQ022406
	// get all distribution lists
	dlManager dlMgr = dlManager.getInstance();
	PstAbstractObject [] dlArr = dlMgr.getDLs(pstuser);
	Util.sortName(dlArr);

	// get all town people
	// PstAbstractObject [] allEmp = ((user)pstuser).getAllUsers();
	PstAbstractObject [] allEmp = null;
	if (isMultiCorp)
	{
		//int [] ids = uMgr.findId(pstuser, "Company='" + (String)pstuser.getAttribute("Company")[0] + "'");
		int [] ids = Util2.toIntArray(projObj.getAttribute("TeamMembers"));
		//ids = Util2.mergeIntArray(ids, ids1);
		allEmp = uMgr.get(pstuser, ids);
	}
	else
		allEmp = ((user)pstuser).getAllUsers();
	Util.sortUserArray(allEmp);

	// allEmp will be on the left while alertEmp will be on the right
	PstAbstractObject [] alertIdS = null;
	String [] fName = null;
	String [] lName = null;
	if(alertLength > 0) {
		// Duplicate the list into an int []
		int [] alertIdIntArr = new int[alertLength];
		for(int i = 0; i < alertLength; i++)
			alertIdIntArr[i] = Integer.parseInt(alertIdObjArr[i].toString());

		alertIdS = uMgr.get(pstuser, alertIdIntArr);
		Util.sortUserArray(alertIdS);
		alertLength = alertIdS.length;		// ECC bug fix: some users in the alert list might be deleted
		fName = new String [alertLength];
		lName = new String [alertLength];

		for (int i = 0; i < alertLength; i++)
		{
			int id = alertIdS[i].getObjectId();
			for (int j = 0; j < allEmp.length; j++)
			{
				if (allEmp[j] == null) continue;
				if (allEmp[j].getObjectId() == id)
				{
					fName[i] = (String)allEmp[j].getAttribute("FirstName")[0];
					lName[i] = (String)allEmp[j].getAttribute("LastName")[0];
					allEmp[j] = null;
					break;
				}
			}
		}
	}

%>
		<table border="0" cellspacing="4" cellpadding="0">
		<tr>
			<td bgcolor="#FFFFFF">
			<select class="formtext_fix" name="Selected" multiple size="5" <%=UserEdit%>>
<%
// @AGQ022806

	String prevName = null;
	if (!isMultiCorp)
	for(int i = 0; i < dlArr.length; i++) {
		dl curDl = (dl)dlArr[i];
		String curName = curDl.getObjectName();
		if ((idx=curName.indexOf("@@")) != -1) {
			curName = curName.substring(0, idx);
		}
		if(prevName != null) {
			if(!prevName.equalsIgnoreCase(curName)) {
				out.print("<option value='" + dl.DLESCAPESTR + curDl.getObjectId() + "'>* " + curName + "</option>");
			}
		}
		else {
				out.print("<option value='" + dl.DLESCAPESTR + curDl.getObjectId() + "'>* " + curName + "</option>");
		}
		prevName = curName;
	}

	if (allEmp != null && allEmp.length > 0)
	{
		for (int i=0; i < allEmp.length; i++)
		{	
			if (allEmp[i]==null || Util.isNullString(allEmp[i].getStringAttribute("FirstName"))) continue;
%>
			<option value="<%=allEmp[i].getObjectId()%>"><%=((user)allEmp[i]).getFullName()%></option>
<%
		}
	}

%>
			</select>
			</td>
			<td align="center" valign="middle" class="td_value_bg">
			<input type="button" class="button" <%=UserEdit%> name="add" value="&nbsp;&nbsp;&nbsp;Add &gt;&gt;&nbsp;&nbsp;" onclick="swapdata(this.form.Selected,this.form.AlertPersonnel)"/>
			<br/><input type="button" class="button" <%=UserEdit%> name="remove" value="<< Remove" onclick="swapdata(this.form.AlertPersonnel,this.form.Selected)"/>
			</td>
<!-- people selected -->
			<td bgcolor="#FFFFFF">
				<select class="formtext_fix" name="AlertPersonnel" multiple size="5" >

<%
	if (alertLength > 0)
	{
		for (int i=0; i < alertLength; i++)
		{
			if (fName[i] == null) continue;
			out.println("<option value='" + alertIdS[i].getObjectId() + "'>" + ((user)alertIdS[i]).getFullName() + "</option>");
		}
	}
	out.print("</select></td></tr>");
	if (!isMultiCorp)
		out.print("<tr><td><span class='footnotes'>* Distribution list</span></td></tr>");
%>


		</table>
</td>
</tr>


<!-- End of Alerted Personnel -->

<% if (!isCRAPP) {%>

<!-- Alert Message Content -->
<%
	String msg = (String)taskObj.getAttribute("AlertMessage")[0];
	if (msg != null)
		msg = "<input class='formtext' " +UserEdit+ " type='input' name='AlertMessage' value='"
			+Util.stringToHTMLString(msg) + "' style='width:100%'>";
	else
		msg = "<input class='formtext' " +UserEdit+ " type='input' name='AlertMessage' style='width:90%'>";
%>
	<tr>
		<td width="160" class="td_field_bg"><b>Alert Message</b></td>
		<td class="td_value_bg"><%=msg%></td>
	</tr>
<!-- End of Alert -->
<%} // end if !isCRAPP %>

<%
	// @ECC031709 restrictive access to task
	PstAbstractObject [] restrictMems = new PstAbstractObject[0];
	oArr = taskObj.getAttribute("TeamMembers");
	int [] restrictIds = Util2.toIntArray(oArr);
	String check = "";
	if (restrictIds.length>0 && restrictIds[0]>0)
		check = "checked";

	// add the owners to the list
	int [] owners = {taskOwnerId, projOwnerId};
	restrictIds = Util2.mergeIntArray(restrictIds, owners);
	restrictMems = uMgr.get(pstuser, restrictIds);
	Util.sortUserArray(restrictMems, true);

	String restrictIdStr = "";	//Util2.getAttributeString(taskObj, "TeamMembers", ";");
	for (int i=0; i<restrictIds.length; i++) restrictIdStr += String.valueOf(restrictIds[i]) + ";";

	// use this in the post file to decide if I need to change restrictive access attribute (TeamMembers)
	if (!isTaskProjOwner)
		out.print("<input type='hidden' name='RestrictIgnore' value='true'>");
	else
		out.print("<input type='hidden' name='RestrictIgnore' value='false'>");

	out.print("<tr><td colspan='2'><img src='../i/spacer.gif' height='10' width='1' /></td></tr>");
	out.print("<tr><td colspan='2' class='plaintext_big'>");
	out.print("<input type='checkbox' name='RestrictCheck' onClick='toggleRestrict();' ");
	if (!isTaskProjOwner)
		out.print("disabled ");
	out.print(check + ">&nbsp;Restrict access to this task");
	out.print("</td></tr>");

	// the selection box to choose restrictive access member

	out.println("<tr><td colspan='2'><table width='100%' border='0' cellspacing='2' cellpadding='4'>");	// ECC  bgcolor='#DEEBF7'
	out.print("<tr id='restrictTR' style='display:");
	if (!isTaskProjOwner || check=="")
		out.print("none");
	else
		out.print("block");
	out.print("'><td class='td_field_bg' width='190'><b>Restrictive Access</b></td>");
	out.print("<td class='td_value_bg'>");
	out.print("<table width='100%' border='0' cellspacing='0' cellpadding='4'>");

	out.print("<tr><td colspan='2'></td><td class='plaintext'>Access only by these members:</td></tr>");

	out.print("<tr><td><select class='formtext_fix' name='RestAll' multiple size='5'>");
	int id;
	for (int i=0; i<teamMember.length; i++)
	{
		id = teamMember[i].getObjectId();
		if (restrictIdStr.contains(String.valueOf(id))) continue;
		uname = ((user)teamMember[i]).getFullName();
		out.print("<option value='" + id + "'>&nbsp;" + uname + "</option>");
	}
	out.print("</select></td>");

	out.print("<td align='center' valign='middle' class='td_value_bg'>");
	out.print("<input type='button' class='button' value='&nbsp;&nbsp;&nbsp;Add &gt;&gt;&nbsp;&nbsp;' onclick='swapdata(this.form.RestAll,this.form.RestrictAccess);'/>");
	out.print("<br/><input type='button' class='button' value='<< Remove' onclick='swapdata(this.form.RestrictAccess,this.form.RestAll);'/>");
	out.print("</td>");

	out.print("<td><select class='formtext_fix' name='RestrictAccess' multiple size='5'>");
	for (int i=0; i<restrictMems.length; i++)
	{
		uname = ((user)restrictMems[i]).getFullName();
		out.print("<option value='" + restrictMems[i].getObjectId() + "'>&nbsp;" + uname + "</option>");
	}
	out.print("</select></td></tr>");

	out.print("</table>");
	out.print("</td></tr>");
	
	out.print("</table></td></tr>");	// ECC
	
%>
</table>
<!-- end table -->

		<p align="center">

<%
	// submit button
	if (!UserEdit.equals("disabled"))
		out.print("<input type='Button' value='Submit' class='button_medium' onclick='return validate();'/>");
	else
		out.print("<img src='../i/spacer.gif' width='250' height='1' />");

	out.print("<img src='../i/spacer.gif' width='20' height='1' />");
	// cancel button
	if (!isCRAPP)
			out.print("<input type='Button' value='Cancel' class='button_medium' "
					+ "onclick=\"location='proj_plan.jsp?projId=" + projIdS + "'\"/>");
	else
		out.print("<input type='Button' value='Cancel' class='button_medium' "
				+ "onclick=\"location='cr.jsp?projId=" + projIdS + "'\"/>");

	if (UserEdit.equals("disabled"))
		out.print("<span class='plaintext'>&nbsp;&nbsp;&nbsp;(You are only authorized to UPLOAD FILES.)</span>");

%>

		<br/></p>

	</td>
</tr>
</table>
</form>
<%-- @AGQ032806 --%>
<!-- END MAIN CONTENT -->
</td>
</tr>


<tr><td>&nbsp;</td></tr>


<!-- BEGIN FOOTER TABLE -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

