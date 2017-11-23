<%
////////////////////////////////////////////////////
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	phase_update.jsp
//	Author:	ECC
//	Date:	09/28/05
//	Description:
//		Update project phases and sub-phases.  Only support max two levels of phases.
//	Modification:
//		@110705ECC	Add option to link a Phase or Sub-phase to Task.
//		@AGQ042506	Changed phase to objects
//		@AGQ050306	Support task w/ TBD and N/A characters
//		@AGQ050406A	Fixed bug 57057: task id is enabled even w/o checking the checkbox 
//					the page is loaded.
//		@AGQ050506	Added link to milestone page
//		@AGQ050506a	Support of 'and other special char in phase name 
//		@AGQ050806	Removed Late Status
//		@AGQ050806A	Detect if Start Date is after Due Date
//		@AGQ050906	Detect if task id is missing for phase
//		@AGQ050906A Did not user maxSubPhase because there may exist more subphases than
//					the maximum number of maxSubPhase. This happen when the Coordinator
//					previously added more subPhases and later on a lower number of maxSubPhase
//					is set in the properties file.
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
<%@ page import = "java.text.SimpleDateFormat" %>
<%@ page import = "javax.servlet.*" %>
<%@ page import = "javax.servlet.http.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	final String PROP_FILE = "bringup";

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	String pstuserIdS = String.valueOf(pstuser.getObjectId());
	boolean isAdmin = false;
	boolean isAboveUser = false;		// allow only above USER grade to update project phases
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if (iRole > 0)
	{
		if ((iRole & user.iROLE_ADMIN) > 0)
		{
			isAdmin = true;
			isAboveUser = true;
		}
		if ((iRole & user.iROLE_USER) == 0)
			isAboveUser = true;
	}
	int myUid = pstuser.getObjectId();

	// town
	/*String townName = (String)session.getAttribute("townName");
	town tObj = (town)townManager.getInstance().get(pstuser, townName);
	String townChiefIdS = (String)tObj.getAttribute("Chief")[0];*/

	// project
	String projIdS = request.getParameter("projId");

	projectManager projMgr = projectManager.getInstance();
	project projObj = (project)projMgr.get(pstuser, Integer.parseInt(projIdS));
	String projName = projObj.getDisplayName();
	String ownerIdS   = (String)projObj.getAttribute("Owner")[0];
	int ownerId = Integer.parseInt(ownerIdS);
	if (ownerId == myUid)
		isAboveUser = true;

	// update only authorized to project owner and for roles above user
	// just for double safety: actually I cannot get to this page from proj_profile.jsp unless
	// I am either admin, project owner, or the supervisor of the project owner
	if (ownerIdS == null || (ownerId!=pstuser.getObjectId() && !isAboveUser))
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}

	// get the expiration date
	String format = "MM/dd/yyyy";
	java.text.SimpleDateFormat df = new java.text.SimpleDateFormat(format);

	// project phases (name::StartDate::ExpireDate::CompleteDate::Status)
	int maxPhases = 7;	// default to 7
	int maxSubPhases = project.MAX_SUBPHASES; 
	String s = Util.getPropKey(PROP_FILE, "PHS.TOTAL");
	if (s != null) maxPhases = Integer.parseInt(s);
	
	s = Util.getPropKey(PROP_FILE, "SUBPHS.TOTAL");
	if (s != null) maxSubPhases = Integer.parseInt(s);

	String [] phaseS = new String[maxPhases];
	String [] phaseB = new String[maxPhases];	// begin (StartDate)
	String [] phaseD = new String[maxPhases];	// deadline
	String [] phaseC = new String[maxPhases];	// complete
	String [] phaseSt = new String[maxPhases];
	String [] phaseTask = new String[maxPhases];	// @110705ECC task link
	String [] phaseExt = new String[maxPhases];	// extension to sub-phases (store blogID)
	String [] phColor = new String[maxPhases];	// phase color
	String [] sa; 
	taskManager tkMgr = taskManager.getInstance();
	planTaskManager ptMgr = planTaskManager.getInstance();
	phaseManager phMgr = phaseManager.getInstance();
	PstAbstractObject tk, ptk;
	int [] ids;
	Date dt;
// @AGQ042506
	PstAbstractObject [] objArr = phMgr.getPhases(pstuser, String.valueOf(projObj.getObjectId()));
	phase ph = null;
	int totalPhases = objArr.length;
	if (isAboveUser)
	{
		for (int i=0; i<totalPhases; i++)
		{
			if (i < objArr.length)
			{
				// startDt and CompleteDt are implied by change of state
				ph = (phase) objArr[i];
				// @110705ECC
				Object obj = ph.getAttribute(phase.TASKID)[0];
				if (obj != null)
				{
					// use task to fill the phase info
					phaseTask[i] = obj.toString();
					try
					{
						tk = tkMgr.get(pstuser, phaseTask[i]);
						obj = ph.getAttribute(phase.NAME)[0];
						if (obj == null)
						{
							ids = ptMgr.findId(pstuser, "TaskID='" + phaseTask[i] + "' && Status!='Deprecated'");
							ptk = ptMgr.get(pstuser, ids[ids.length-1]);
							phaseS[i] = (String)ptk.getAttribute("Name")[0];
						}
						else
							phaseS[i] = obj.toString();

						dt = (Date)tk.getAttribute("EffectiveDate")[0];
						if (dt == null)
							dt = (Date)tk.getAttribute("StartDate")[0];
						if (dt != null)
							phaseB[i] = df.format(dt);
// @AGQ050306
						dt = (Date)tk.getAttribute("ExpireDate")[0];
						phaseD[i] = phase.parseDateToString(dt, format);

						dt = (Date)tk.getAttribute("CompleteDate")[0];
						phaseC[i] = phase.parseDateToString(dt, format);
						
						s = (String)tk.getAttribute("Status")[0];
						if (s.equals(task.ST_NEW)) s = project.PH_NEW;
						else if (s.equals(task.ST_OPEN) || s.equals(task.ST_ONHOLD)) s = project.PH_START;
						phaseSt[i] = s;
						
						// phase color
						phColor[i] = (String)ph.getAttribute("Color")[0];
					}
					catch (PmpException e){phaseS[i] = "*** Invalid task ID";}
				}
				else
				{
					phaseTask[i] = "";			// not using task link

					phaseS[i] = ph.getAttribute(phase.NAME)[0].toString();					

					dt = (Date)ph.getAttribute(phase.STARTDATE)[0];
					if (dt != null) phaseB[i] = df.format(dt);
					else phaseB[i] = "";
// @AGQ050306
					dt = (Date)ph.getAttribute(phase.EXPIREDATE)[0];
					phaseD[i] = phase.parseDateToString(dt, format);
					
					dt = (Date)ph.getAttribute(phase.COMPLETEDATE)[0];
					phaseC[i] = phase.parseDateToString(dt, format);
					
					phaseSt[i] =ph.getAttribute(phase.STATUS)[0].toString();
				}
				s = String.valueOf(ph.getObjectId());
				if (phMgr.hasSubPhases(pstuser, s))
					phaseExt[i] = s;
				else
					phaseExt[i] = null;
			}
			else
			{
				// use default phase name
				s = Util.getPropKey(PROP_FILE, "PHS." + (i+1));
				if (s == null) s = "";
				phaseS[i] = s;
				phaseTask[i] = "";				// not using task link
			}
			if (phaseB[i] == null || phaseB[i].length() == 0)
				phaseB[i] = "TBD";
		}
	}

	// add sub-phase
	int addSubPhaseId = -1;
	s = request.getParameter("addPhase");
	if (s != null)
		addSubPhaseId = Integer.parseInt(s);

%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">

<jsp:include page="../init.jsp" flush="true"/>
<script language="JavaScript" src="../get-date.js"></script>

<script type="text/javascript">

<!--
window.onload = function ()
{
	if (<%=totalPhases%> <= 0) {
		addp.addPhase()
	}
}

function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

function validation()
{
// @AGQ050806A
	// Detect if Start Date is after Expire Date
	for (i=0; i<<%=maxPhases%>; i++) {
		if (document.getElementsByName("PhaseTaskCheck"+i)[0] == null)
			break;
		var taskID = document.getElementsByName("PhaseTaskCheck"+i)[0].checked;
		var startS = document.getElementsByName("PhStart"+i)[0].value;
		var expireS = document.getElementsByName("Deadline"+i)[0].value;
		
		if (taskID) {
			continue;
		}	
		else if (startS == "") {
			//alert("Skipped " + (i+1));
			continue;
		}
		// not required
		else if (startS == null || expireS == null) {
			//alert("Ended " + (i+1));
			break;
		}
		
		dtS = new Date(startS);
		dtE = new Date(expireS);
		if (dtS.getTime() > dtE.getTime()) {
			alert("The START DATE cannot be after the DUE DATE for phase number: " + (i+1));
			return false;
		}
	}
// @AGQ050906
	for (i=0; i<<%=maxPhases%>; i++) {
		if (document.getElementsByName("Phase"+i)[0] == null)
			break;
		var phName = document.getElementsByName("Phase"+i)[0].value;
		
		var taskCkB = document.getElementsByName("PhaseTaskCheck"+i)[0].checked;
		var taskID = document.getElementsByName("PhaseTask"+i)[0].value;
		
		// Detect if NAME is null
		if (phName == '' || phName == null) {
			alert("NAME cannot remain blank for Phase number: " + (i+1));
			return false;
		}
		
		// Detect if TASK ID is null when box is checked	
		if (taskCkB) { 
			if (taskID == '' || taskID == null) {
				alert("TASK ID cannot remain blank for Phase number: " + (i+1));
				return false;
			}
			else if (isNaN(parseInt(taskID))) {
				alert("TASK ID must be a numeric value for Phase number: " + (i+1));
				return false;
			}
		}
// @AGQ050906A
		var j=0;
		var subTaskCkB = document.getElementsByName("SubPhaseTaskCheck"+i+"_"+j)[0];
		while (subTaskCkB != null) {
			var subphName = document.getElementsByName("SubPhase"+i+"_"+j)[0].value;
			var subTaskID = document.getElementsByName("SubPhaseTask"+i+"_"+j)[0].value;
			
			// Detect if NAME is null
			if (subphName == '' || subphName == null) {
				alert("NAME cannot remain blank for Milestone number: " + (i+1) + "." + (j+1));
				return false;
			}
			
			// Detect if TASK ID is null when box is checked	
			if (subTaskCkB.checked) {
				if (subTaskID == '' || subTaskID == null) {
				 	alert("TASK ID cannot remain blank for Milestone number: " + (i+1) + "." + (j+1));
				 	return false;
				 }
				 else if (isNaN(parseInt(subTaskID))) {
				 	alert("TASK ID must be a numeric value for Milestone number: " + (i+1) + "." + (j+1));
				 	return false; 
				 }
			}
			j++;
			subTaskCkB = document.getElementsByName("SubPhaseTaskCheck"+i+"_"+j)[0];
		}
	}			
		
	return true;
}

function checkStatus() {
	var i = arguments[0];
	var j = arguments[1];
	var name = null; 
	var completeDate = null;
	var completeCal = null;
	var deadlineDate = null;
	var deadlineCal = null;
	var startDate = null;
	var startCal = null;
	
	// get completeDate field
	if (j == null) {
		name = document.getElementsByName('Status'+i)[0];
		completeDate = document.getElementsByName('PhComplete'+i)[0];
		completeCal = document.getElementsByName('PhCompleteCal'+i)[0];
		deadlineDate = document.getElementsByName('Deadline'+i)[0];
		deadlineCal = document.getElementsByName('DeadlineCal'+i)[0];
		startDate = document.getElementsByName('PhStart'+i)[0];
		startCal = document.getElementsByName('PhStartCal'+i)[0];
	}
	else {
		name = document.getElementsByName('SubStatus'+i+'_'+j)[0];
		deadlineDate = document.getElementsByName('SubDeadline'+i+'_'+j)[0];
		deadlineCal = document.getElementsByName('SubDeadlineCal'+i+'_'+j)[0];
	}
	
<%--	
	// set to enable/disable depending on status
	if (name != null && completeDate != null) {
		var selectIdx = name.selectedIndex;
		if (name.options[selectIdx].value == '<%=phase.PH_COMPLETE%>') {
			completeDate.disabled = false;
			completeCal.onclick = '';
		}
		else { 
			completeDate.disabled = true;
			completeCal.onclick = my_onclick;	
		}		
	}
--%>
	
	// set to enable/disable when status is cancelled
	if (name != null) {
		var selectIdx = name.selectedIndex;
		if (name.options[selectIdx].value != '<%=phase.PH_CANCEL%>') {
			if (j == null) {
				completeDate.disabled = false;
				startDate.disabled = false;
				completeCal.onclick = '';
				startCal.onclick = '';
			}
			deadlineDate.disabled = false;
			deadlineCal.onclick = '';
		}
		else {
			if (j == null) {
				completeDate.disabled = true;
				startDate.disabled = true;
				completeCal.onclick = my_onclick;
				startCal.onclick = my_onclick;	
			}
			deadlineDate.disabled = true;
			deadlineCal.onclick = my_onclick;
		}		
	}
	
	if (name != null && name.options.length == 2) {
		var isOpen = false;
		var hasComplete = false;
		for (i=0; i<name.options.length; i++) {
			if (name.options[i].value == '<%=phase.PH_START%>' && name.options[i].selected)
				isOpen = true;
			if (name.options[i].value == '<%=phase.PH_COMPLETE%>')
				hasComplete = true;
		}
		
		if (isOpen && hasComplete && (completeDate == null || (completeDate != null && completeDate.value != ''))) {
			if (confirm("Changing the STATUS from COMPLETE back to STARTED will remove the previous ACTUAL COMPLETION date. \n Is this okay?")) {
				// remove previous complete date
				if (completeDate != null) {
					completeDate.value = '';
					//completeDate.disabled = true;
					//completeCal.onclick = my_onclick;	
				}
				return true;
			}
			// user hit cancel
			else {
				for (i=0; i<name.options.length; i++) {
					if (name.options[i].value == '<%=phase.PH_COMPLETE%>') {
						name.options[i].selected = true;
						// enable completeDate
						//if (completeDate != null) {
							//completeDate.disabled = false;
							//completeCal.onclick = '';
						//}		
					}
				}
				return false;
			}
		}
	}
}

function show_cal(e1, e2)
{
	var temp = document.getElementsByName(e1)[0];	
	if (temp != null)
		e1 = temp;	
	if (e2 == null) e2 = e1;
	var dt;
	if (e2.value!=null && e2.value!='')
		dt = new Date(e2.value);
	else
		dt = new Date();
	var mon = '' + dt.getMonth();
	var yr = '' + dt.getFullYear();
	if (yr.length==2) yr = '20' + yr;		// 13 change to 2013
	else if (yr.length==1) yr = '200' + yr;	// because 05 will become 5
	var es = 'updatePhase.' + e1.name;
	var number = parseInt(mon);
	var number2 = parseInt(yr);
// @AGQ050406a	
	if (isNaN(number) || isNaN(number2)) {
		dt = new Date();
		mon = '' + dt.getMonth();
		yr = '' + dt.getFullYear();
	}
	show_calendar(es, mon, yr);
}
function addSubPhase(phId, totalSubPhases)
{
	if (totalSubPhases >= <%=maxSubPhases%>) {
		alert("You have exceeded the max number of <%=maxSubPhases%> Milestones");
		return false;	
	}
	updatePhase.action = "phase_update.jsp";
	updatePhase.addPhase.value = phId;
	if ('<%=addSubPhaseId%>' != '-1')
		return confirm("You have not saved the added sub-phase yet, proceeding will lose the new information you entered.  Are you sure you want to proceed?");
	//updatePhase.encoding = "multipart/form-data";
}

function my_onclick(event) {
	return false;
}

function phase_use_task(i)
{
	var b = document.getElementsByName('PhaseTaskCheck' + i)[0].checked;
	document.getElementsByName('PhStart' + i)[0].disabled = b;
	document.getElementsByName('Deadline' + i)[0].disabled = b;
	document.getElementsByName('Status' + i)[0].disabled = b;
	document.getElementsByName('PhaseTask' + i)[0].disabled = !b;
	document.getElementsByName('PhComplete' + i)[0].disabled = b;
	if (b) {
		document.getElementsByName('PhStartCal'+i)[0].onclick = my_onclick;
		document.getElementsByName('DeadlineCal'+i)[0].onclick = my_onclick;
		document.getElementsByName('PhCompleteCal'+i)[0].onclick = my_onclick;
	}
	else {
		document.getElementsByName('PhStartCal'+i)[0].onclick = '';
		document.getElementsByName('DeadlineCal'+i)[0].onclick = '';
		document.getElementsByName('PhCompleteCal'+i)[0].onclick = '';
		checkStatus(i);
	}		
}

function subphase_use_task(i, j)
{
	var b = document.getElementsByName('SubPhaseTaskCheck' + i + "_" + j)[0].checked;
	var start = document.getElementsByName('SubPhStart' + i + "_" + j)[0];
	if (start != null)
		document.getElementsByName('SubPhStart' + i + "_" + j)[0].disabled = b;
	document.getElementsByName('SubDeadline' + i + "_" + j)[0].disabled = b;
	document.getElementsByName('SubStatus' + i + "_" + j)[0].disabled = b;
	document.getElementsByName('SubPhaseTask' + i + "_" + j)[0].disabled = !b;
	if (b) {
		document.getElementsByName('SubDeadlineCal'+i+'_'+j)[0].onclick = my_onclick;
	}
	else {
		document.getElementsByName('SubDeadlineCal'+i+'_'+j)[0].onclick = '';
		checkStatus(i, j);
	}
}

function removePhase(i) {
	var j = arguments[1];
	if (j != null) {
		var deletePhase = document.getElementsByName('SubDelete'+i+'_'+j)[0];
		if (confirm("Are you sure you want to remove Milestone " + (i+1) + "." + (j+1))) {
			deletePhase.value = true;
			if (validation())
				updatePhase.submit();
			else {
				deletePhase.value = false;
				return false;
			}
		}
	}
	else {
		var deletePhase = document.getElementsByName('Delete'+i)[0];
		if (confirm("This action will remove all the Milestones that belongs to this Phase and the Phase itself. \nAre you sure you want to remove Phase " + (i+1) + "?")) {
			deletePhase.value = true;
			if (validation())
				updatePhase.submit();
			else {
				deletePhase.value = false;
				return false;
			}	
		}
	} 	
	
	return false;
}

function getNames() {
	<%
	out.println("subPhaseName = new Array();");
	out.println("phaseName = new Array();");
	for (int m=0; m<maxPhases; m++) {
		s = Util.getPropKey(PROP_FILE, "PHS."+(m+1));
		if (s == null) s = "";
		out.println("phaseName["+m+"] = '"+s+"';");
		out.println("subPhaseName["+m+"] = new Array();");
		for (int n=0; n<maxSubPhases; n++) {
			s = Util.getPropKey(PROP_FILE, "PHS."+(m+1)+"."+(n+1));
			if (s == null) s = "";
			out.println("subPhaseName["+m+"]["+n+"] = '"+s+"';");
		}
	}
	%>

	this.getSubPhaseName = function( i, j ) {
		return subPhaseName[i][j];
	}

	this.getPhaseName = function( i ) {
		return phaseName[i];
	}	
}

function newPhases( id, i ) {
	this.body = document.getElementById(id);
	this.ct = i;
	
	this.removeMilestone = function (ct) {
		if(confirm("Are you sure you want to remove Phase " + (ct+1)))
			return this.shiftUp(ct);
		else
			return false;
	}
	
	this.shiftUp = function (ct) {
		if (ct == this.ct-1) {
			var curName = document.getElementsByName('Phase'+ct)[0];
			curName.parentNode.parentNode.parentNode.parentNode.parentNode.removeChild(curName.parentNode.parentNode.parentNode.parentNode);
			this.ct--;
			return true;
		}	
		// Copy over information
		else {
			var curName = document.getElementsByName('Phase'+ct)[0];
			var curTaskId = document.getElementsByName('PhaseTask'+ct)[0];
			var curTaskIdCk = document.getElementsByName('PhaseTaskCheck'+ct)[0];
			var curStatus = document.getElementsByName('Status'+ct)[0];
			var curDue = document.getElementsByName('Deadline'+ct)[0];
			var curStart = document.getElementsByName('PhStart'+ct)[0];
			var curComplete = document.getElementsByName('PhComplete'+ct)[0];
			
			var nextName = document.getElementsByName('Phase'+(ct+1))[0];
			var nextTaskId = document.getElementsByName('PhaseTask'+(ct+1))[0];
			var nextTaskIdCk = document.getElementsByName('PhaseTaskCheck'+(ct+1))[0];
			var nextStatus = document.getElementsByName('Status'+(ct+1))[0];
			var nextDue = document.getElementsByName('Deadline'+(ct+1))[0];
			var nextStart = document.getElementsByName('PhStart'+(ct+1))[0];
			var nextComplete = document.getElementsByName('PhComplete'+(ct+1))[0];
			
			curName.value = nextName.value;
			curTaskId.value = nextTaskId.value;
			curTaskIdCk.checked = nextTaskIdCk.checked;
			curStatus.selectedIndex = nextStatus.selectedIndex;
			curDue.value = nextDue.value;
			curStart.value = nextStart.value;
			curComplete.value = nextComplete.value;
 			// Disabled 
			curTaskId.disabled = !curTaskIdCk.checked;
			curStatus.disabled = curTaskIdCk.checked;
			curDue.disabled = curTaskIdCk.checked;
			curStart.disabled = curTaskIdCk.checked;
			curComplete.disabled = curTaskIdCk.checked;
			
			return this.shiftUp(ct+1);
		}
	}
	
	this.addPhase = function () {
		var ct = this.ct;
		var current = this
		
		if (ct >= <%=maxPhases%>) {
			alert("You have exceeded the max number of <%=maxPhases%> Phases");
			return;	
		}
		
		var new_table = document.createElement( 'table' );
		var new_tbody = document.createElement( 'tbody' );
		var new_row = document.createElement( 'tr' );
		var new_col_name = document.createElement( 'td' );
		var new_col_button = document.createElement( 'td' );
		var dummy_row = document.createElement( 'tr' );
		var dummy_col = document.createElement( 'td' );
		var dummy_col2 = document.createElement( 'td' );
		
		// create <a onclick='function'><img align='right' src='../i/delete.gif'></a>
		var new_delete_link = document.createElement( 'a' );
		var calander_link = document.createNamedElement( 'a', 'PhStartCal'+ct );
		var calander_1_link = document.createNamedElement( 'a', 'DeadlineCal'+ct );
		var calander_2_link = document.createNamedElement( 'a', 'PhCompleteCal'+ct );
		var calander = document.createElement( 'img' );
		var calander_1 = document.createElement( 'img' );
		var calander_2 = document.createElement( 'img' );
		var new_img = document.createElement( 'img' );
		new_img.setAttribute( 'align', 'right');
		calander.setAttribute( 'align', 'absmiddle' );
		calander_1.setAttribute( 'align', 'absmiddle' );
		calander_2.setAttribute( 'align', 'absmiddle' );
		new_img.setAttribute( 'src', '../i/delete.gif' );
		calander.setAttribute( 'src', '../i/calendar.gif' );
		calander_1.setAttribute( 'src', '../i/calendar.gif' );
		calander_2.setAttribute( 'src', '../i/calendar.gif' );
		
		calander.setAttribute( 'alt', 'Click to view calendar' );
		calander_1.setAttribute( 'alt', 'Click to view calendar' );
		calander_2.setAttribute( 'alt', 'Click to view calendar' );
		
		calander_link.setAttribute( 'href', 'javascript:show_cal(updatePhase.PhStart'+ct+')');
		calander_1_link.setAttribute( 'href', 'javascript:show_cal(updatePhase.Deadline'+ct+')');
		calander_2_link.setAttribute( 'href', 'javascript:show_cal(updatePhase.PhComplete'+ct+')');
		
		calander.style.cursor = 'pointer';
		calander_1.style.cursor = 'pointer';
		calander_2.style.cursor = 'pointer';
		calander.style.border = '0';
		calander_1.style.border = '0';
		calander_2.style.border = '0';
		
		// append
		new_delete_link.appendChild(new_img);
		calander_link.appendChild(calander);
		calander_1_link.appendChild(calander_1);
		calander_2_link.appendChild(calander_2);
		
		new_delete_link.onclick = function () {
			return current.removeMilestone(ct);
		}
		
		calander_link.onclick = function () {
			return show_cal('PhStart'+ct);
		}
		calander_1_link.onclick = function () {
			return show_cal('Deadline'+ct);
		}
		calander_2_link.onclick = function () {
			return show_cal('PhComplete'+ct);
		}
		
		// Create Text
		var name = document.createTextNode("Name: ");
		var taskId = document.createTextNode("Task ID: ");
		var status = document.createTextNode("Status: ");
		var due = document.createTextNode("Due: ");
		var start = document.createTextNode("Start:");
		var completeName = document.createTextNode("Actual Completion: ");
		var whitespace = document.createTextNode( " " );
		var whitespace2 = document.createTextNode( " " );
		var milestone = document.createTextNode("Phase " + (this.ct+1));
		// Create Elements
		var nameInput = document.createNamedElement( 'input', 'Phase'+this.ct );
		var taskIdInput = document.createNamedElement( 'input', 'PhaseTask'+this.ct );
		var taskIdInputCk = document.createNamedElement( 'input', 'PhaseTaskCheck'+this.ct );
		var statusSelect = document.createNamedElement( 'select', 'Status'+this.ct );
		var dueInput = document.createNamedElement( 'input', 'Deadline'+this.ct );
		var startInput = document.createNamedElement( 'input', 'PhStart'+this.ct );
		var completeInput = document.createNamedElement( 'input', 'PhComplete'+this.ct );
		// WhiteSpaces
		var br = document.createElement( 'br' );
		var br2 = document.createElement( 'br' );
		var spanNew = document.createElement( 'span' );
		var span1 = document.createElement( 'span' );
		var span1_1 = document.createElement( 'span' );
		var span1_2 = document.createElement( 'span' );
		var span1_3 = document.createElement( 'span' );
		var span2 = document.createElement( 'span' );
		var span2_1 = document.createElement( 'span' );
		var span3 = document.createElement( 'span' );
		var span4 = document.createElement( 'span' );
		var span4_1 = document.createElement( 'span' );
		var span5 = document.createElement( 'span' );
		
		var notStarted = document.createElement( 'option' ); // options
		var started = document.createElement( 'option' );
		var complete = document.createElement( 'option' );
		var canceled = document.createElement( 'option' );
		var highRisk = document.createElement( 'option' );
		
		// Set Attribute
		new_table.setAttribute( 'cellPadding', 4 );
		new_table.setAttribute( 'cellSpacing', 2 );
		new_table.setAttribute( 'border' , 0 );
		
		nameInput.setAttribute( 'type', 'text' );
		taskIdInput.setAttribute( 'type', 'text' );
		taskIdInputCk.setAttribute( 'type', 'checkbox' );
		dueInput.setAttribute( 'type', 'text' );
		startInput.setAttribute( 'type', 'text' );
		
		nameInput.setAttribute( 'size', '60' );
		taskIdInput.setAttribute( 'size', '5' );
		dueInput.setAttribute( 'size', '12' );
		startInput.setAttribute( 'size', '12' );
		completeInput.setAttribute( 'size', '12' );
		
		taskIdInput.setAttribute( 'disabled', 'disabled' );
		//completeInput.setAttribute( 'disabled', 'disabled' );
				
		statusSelect.setAttribute( 'width', '100' );		
		new_col_name.setAttribute( 'width', '160' );
		new_col_button.setAttribute( 'width', '593' );
		
		var names = new getNames();
		nameInput.setAttribute( 'value', names.getPhaseName(ct) );
		dueInput.setAttribute( 'value', "TBD");
		
		notStarted.setAttribute( 'value', '<%=phase.PH_NEW%>' );
		started.setAttribute( 'value', '<%=phase.PH_START%>' );
		complete.setAttribute( 'value', '<%=phase.PH_COMPLETE%>' );
		canceled.setAttribute( 'value', '<%=phase.PH_CANCEL%>' );
		highRisk.setAttribute( 'value', '<%=phase.PH_RISKY%>' );
		
		new_tbody.setAttribute( 'id', 'subphBody'+ct );
		
		notStarted.innerHTML = 'Not Started';
		started.innerHTML = 'Started';
		complete.innerHTML = 'Completed';
		canceled.innerHTML = 'Canceled';
		highRisk.innerHTML = 'High Risk';
		
		spanNew.innerHTML = "New ";
		span1.innerHTML = "&nbsp;";
		span1_1.innerHTML = "&nbsp;";
		span1_2.innerHTML = "&nbsp;";
		span1_3.innerHTML = "&nbsp;";
		span2.innerHTML = "&nbsp;&nbsp;";
		span2_1.innerHTML = "&nbsp;&nbsp;";
		span3.innerHTML = "&nbsp;&nbsp;&nbsp;";
		span4.innerHTML = "&nbsp;&nbsp;&nbsp;&nbsp;";
		span4_1.innerHTML = "&nbsp;&nbsp;&nbsp;&nbsp;";
		span5.innerHTML = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
		
		statusSelect.style.width = '100px';
		new_col_name.style.width = '166px';
		new_col_button.style.width = '600px';
		
		spanNew.style.color = 'rgb(221, 0, 0)';
		
		new_img.style.cursor = 'pointer';
		
		// Set ClassName
		nameInput.className = 'formtext';
		taskIdInput.className = 'formtext';
		taskIdInputCk.className = 'formtext';
		dueInput.className = 'formtext';
		startInput.className = 'formtext';
		completeInput.className = 'formtext';
		new_col_name.className = 'td_field_bg';
		new_col_button.className = 'td_value_bg_11';
		statusSelect.className = 'formtext';
		
		// Set onClick
		taskIdInputCk.onclick = function () {
			phase_use_task(ct);
		}
		dueInput.onclick = function () {
			show_cal('Deadline'+ct);
		}
		startInput.onclick = function () {
			show_cal('PhStart'+ct);
		}
		completeInput.onclick = function () {
			show_cal('PhComplete'+ct);
		}
		statusSelect.onchange = function () {
			checkStatus(ct)
		}
		
		// Append 
		statusSelect.appendChild( notStarted );
		statusSelect.appendChild( started );
		statusSelect.appendChild( complete );
		statusSelect.appendChild( canceled );
		statusSelect.appendChild( highRisk );
		
		new_col_button.appendChild( name );
		new_col_button.appendChild( span1 );
		new_col_button.appendChild( nameInput );
		new_col_button.appendChild( span5 );		
		new_col_button.appendChild( taskIdInputCk );
		new_col_button.appendChild( taskId );
		new_col_button.appendChild( taskIdInput );
		new_col_button.appendChild( br );
		new_col_button.appendChild( whitespace2 );
		new_col_button.appendChild( status );
		new_col_button.appendChild( statusSelect );
		new_col_button.appendChild( span4 );
		new_col_button.appendChild( start );
		new_col_button.appendChild( span2_1 );
		new_col_button.appendChild( startInput );
		new_col_button.appendChild( span1_3 );
		new_col_button.appendChild( calander_link );
		new_col_button.appendChild( span4_1 );
		new_col_button.appendChild( due );
		new_col_button.appendChild( dueInput );
		new_col_button.appendChild( span1_1 );
		new_col_button.appendChild( calander_1_link );
		new_col_button.appendChild( br );
		new_col_button.appendChild( new_delete_link );
		new_col_button.appendChild( completeName );
		new_col_button.appendChild( completeInput );
		new_col_button.appendChild( span1_2 );
		new_col_button.appendChild( calander_2_link );

		new_col_name.appendChild( spanNew );
		new_col_name.appendChild( whitespace );
		new_col_name.appendChild( milestone );
		
		new_row.appendChild( new_col_name );
		new_row.appendChild( new_col_button );
		
		dummy_row.appendChild( dummy_col );
		dummy_row.appendChild( dummy_col2 );
		
		new_tbody.appendChild( dummy_row );
		new_tbody.appendChild( new_row );
		new_table.appendChild( new_tbody );
		
		this.body.appendChild( new_table );
		
		this.ct++;
	}
	
}

function newSubPhases(id, i, j) {
	this.body = document.getElementById(id);
	this.i = i;
	this.j = j;
	this.ct = this.j;

	this.removeMilestone = function (ct) {
		if(confirm("Are you sure you want to remove Milestone " + (this.i+1) + "." + (ct+1)))
			return this.shiftUp(ct);
		else
			return false;
	}
	
	this.shiftUp = function (ct) {
		if (ct == this.ct-1) {
			var curName = document.getElementsByName('SubPhase'+this.i+'_'+ct)[0];
			curName.parentNode.parentNode.parentNode.removeChild(curName.parentNode.parentNode);
			this.ct--;
			return true;
		}	
		// Copy over information
		else {
			var curName = document.getElementsByName('SubPhase'+this.i+'_'+ct)[0];
			var curTaskId = document.getElementsByName('SubPhaseTask'+this.i+'_'+ct)[0];
			var curTaskIdCk = document.getElementsByName('SubPhaseTaskCheck'+this.i+'_'+ct)[0];
			var curStatus = document.getElementsByName('SubStatus'+this.i+'_'+ct)[0];
			var curDue = document.getElementsByName('SubDeadline'+this.i+'_'+ct)[0];
			
			var nextName = document.getElementsByName('SubPhase'+this.i+'_'+(ct+1))[0];
			var nextTaskId = document.getElementsByName('SubPhaseTask'+this.i+'_'+(ct+1))[0];
			var nextTaskIdCk = document.getElementsByName('SubPhaseTaskCheck'+this.i+'_'+(ct+1))[0];
			var nextStatus = document.getElementsByName('SubStatus'+this.i+'_'+(ct+1))[0];
			var nextDue = document.getElementsByName('SubDeadline'+this.i+'_'+(ct+1))[0];
			
			curName.value = nextName.value;
			curTaskId.value = nextTaskId.value;
			curTaskIdCk.checked = nextTaskIdCk.checked;
			curStatus.selectedIndex = nextStatus.selectedIndex;
			curDue.value = nextDue.value;
			// Disabled 
			curTaskId.disabled = !curTaskIdCk.checked;
			curStatus.disabled = curTaskIdCk.checked;
			curDue.disabled = curTaskIdCk.checked;
			
			return this.shiftUp(ct+1);
		}
	}

	this.addSubPhase = function () {
		
		var i = this.i;
		var ct = this.ct;
		var current = this
		
		if (ct >= <%=maxSubPhases%>) {
			alert("You have exceeded the max number of <%=maxSubPhases%> Milestones");
			return;	
		}
		
		var new_row = document.createElement( 'tr' );
		var new_col_name = document.createElement( 'td' );
		var new_col_button = document.createElement( 'td' );
		
		// create <a onclick='function'><img align='right' src='../i/delete.gif'></a>
		var new_delete_link = document.createElement( 'a' );
		var calander_link = document.createNamedElement( 'a', 'SubDeadlineCal'+i+"_"+ct );
		
		var calander = document.createElement( 'img' );
		var new_img = document.createElement( 'img' );
		new_img.setAttribute( 'align', 'right');
		calander.setAttribute( 'align', 'absmiddle' );
		new_img.setAttribute( 'src', '../i/delete.gif' );
		calander.setAttribute( 'src', '../i/calendar.gif' );
		
		calander.setAttribute( 'alt', 'Click to view calendar' );
		
		//calander.style.cursor = 'pointer';
		calander.style.border = '0';
		
		calander_link.setAttribute( 'href', 'javascript:show_cal(updatePhase.SubDeadline'+i+'_'+ct+')');
		
		// append
		new_delete_link.appendChild(new_img);
		calander_link.appendChild(calander);
		
		new_delete_link.onclick = function () {
			return current.removeMilestone(ct);
		}
		
		calander_link.onclick = function () {
			return show_cal('SubDeadline'+i+'_'+ct);
		}
		
		// Create Text
		var name = document.createTextNode("Name: ");
		var taskId = document.createTextNode("Task ID: ");
		var status = document.createTextNode("Status: ");
		var due = document.createTextNode("Due: ");
		var whitespace = document.createTextNode( " " );
		var milestone = document.createTextNode("Milestone " + (this.i+1) + "." + (this.ct+1));
		// Create Elements
		var nameInput = document.createNamedElement( 'input', 'SubPhase'+this.i+'_'+this.ct );
		var taskIdInput = document.createNamedElement( 'input', 'SubPhaseTask'+this.i+'_'+this.ct );
		var taskIdInputCk = document.createNamedElement( 'input', 'SubPhaseTaskCheck'+this.i+'_'+this.ct );
		var statusSelect = document.createNamedElement( 'select', 'SubStatus'+this.i+'_'+this.ct );
		var dueInput = document.createNamedElement( 'input', 'SubDeadline'+this.i+'_'+this.ct );
		// WhiteSpaces
		var br = document.createElement( 'br' );
		var spanNew = document.createElement( 'span' );
		var span1 = document.createElement( 'span' );
		var span1_1 = document.createElement( 'span' );
		var span2 = document.createElement( 'span' );
		var span3 = document.createElement( 'span' );
		var span4 = document.createElement( 'span' );
		var span5 = document.createElement( 'span' );
		
		var notStarted = document.createElement( 'option' ); // options
		var started = document.createElement( 'option' );
		var complete = document.createElement( 'option' );
		var canceled = document.createElement( 'option' );
		var highRisk = document.createElement( 'option' );
		
		// Set Attribute
		nameInput.setAttribute( 'type', 'text' );
		taskIdInput.setAttribute( 'type', 'text' );
		taskIdInputCk.setAttribute( 'type', 'checkbox' );
		dueInput.setAttribute( 'type', 'text' );
		
		nameInput.setAttribute( 'size', '60' );
		taskIdInput.setAttribute( 'size', '5' );
		dueInput.setAttribute( 'size', '12' );
		
		taskIdInput.setAttribute( 'disabled', 'disabled' );
				
		nameInput.setAttribute( 'id', 'SubPhase'+this.i+'_'+this.ct );
		taskIdInput.setAttribute( 'id', 'SubPhaseTask'+this.i+'_'+this.ct );
		taskIdInputCk.setAttribute( 'id', 'SubPhaseTaskCheck'+this.i+'_'+this.ct );
		statusSelect.setAttribute( 'id', 'SubStatus'+this.i+'_'+this.ct );
		dueInput.setAttribute( 'id', 'SubDeadline'+this.i+'_'+this.ct );

		statusSelect.setAttribute( 'width', '100' );		
		new_col_name.setAttribute( 'width', '160' );
		
		var names = new getNames();
		nameInput.setAttribute( 'value', names.getSubPhaseName(i, ct) );
		dueInput.setAttribute( 'value', "TBD");
		
		notStarted.setAttribute( 'value', '<%=phase.PH_NEW%>' );
		started.setAttribute( 'value', '<%=phase.PH_START%>' );
		complete.setAttribute( 'value', '<%=phase.PH_COMPLETE%>' );
		canceled.setAttribute( 'value', '<%=phase.PH_CANCEL%>' );
		highRisk.setAttribute( 'value', '<%=phase.PH_RISKY%>' );
		
		notStarted.innerHTML = 'Not Started';
		started.innerHTML = 'Started';
		complete.innerHTML = 'Completed';
		canceled.innerHTML = 'Canceled';
		highRisk.innerHTML = 'High Risk';
		
		spanNew.innerHTML = "New ";
		span1.innerHTML = "&nbsp;";
		span1_1.innerHTML = "&nbsp;";
		span2.innerHTML = "&nbsp;&nbsp;";
		span3.innerHTML = "&nbsp;&nbsp;&nbsp;";
		span4.innerHTML = "&nbsp;&nbsp;&nbsp;&nbsp;";
		span5.innerHTML = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
		
		statusSelect.style.width = '100px';
		spanNew.style.color = 'rgb(221, 0, 0)';
		
		new_img.style.cursor = 'pointer';
		
		// Set ClassName
		nameInput.className = 'formtext';
		taskIdInput.className = 'formtext';
		taskIdInputCk.className = 'formtext';
		dueInput.className = 'formtext';
		new_col_name.className = 'td_field_bg';
		statusSelect.className = 'formtext';
		new_col_button.className = 'td_subPhase';
		
		// Set onClick
		taskIdInputCk.onclick = function () {
			subphase_use_task(i,ct);
		}
		dueInput.onclick = function () {
			show_cal('SubDeadline'+i+'_'+ct);
		}
		
		statusSelect.onchange = function () {
			checkStatus(i, ct)
		}
		
		// Append 
		statusSelect.appendChild( notStarted );
		statusSelect.appendChild( started );
		statusSelect.appendChild( complete );
		statusSelect.appendChild( canceled );
		statusSelect.appendChild( highRisk );
		
		new_col_button.appendChild( name );
		new_col_button.appendChild( span1 );
		new_col_button.appendChild( nameInput );
		new_col_button.appendChild( span5 );		
		new_col_button.appendChild( taskIdInputCk );
		new_col_button.appendChild( taskId );
		new_col_button.appendChild( taskIdInput );
		new_col_button.appendChild( new_delete_link );
		new_col_button.appendChild( br );
		new_col_button.appendChild( status );
		new_col_button.appendChild( statusSelect );
		new_col_button.appendChild( span4 );
		new_col_button.appendChild( due );
		new_col_button.appendChild( span2 );
		new_col_button.appendChild( dueInput );
		new_col_button.appendChild( span1_1 );
		new_col_button.appendChild( calander_link );

		new_col_name.appendChild( spanNew );
		new_col_name.appendChild( whitespace );
		new_col_name.appendChild( milestone );
		
		new_row.appendChild( new_col_name );
		new_row.appendChild( new_col_button );
		
		this.body.appendChild( new_row );
		
		this.ct++;
	}
	
}

document.createNamedElement = function(type, name) {
  var element;
  try {
    element = document.createElement('<'+type+' name="'+name+'">');
  } catch (e) { }
  if (!element || !element.name) { // Not in IE, then
    element = document.createElement(type)
    element.setAttribute( 'name', name );
    //element.name = name;
  }
  return element;
}

//-->
</script>

<title>
	<%=Prm.getAppTitle()%> Update Phases
</title>

<style type="text/css">
.td_subPhase {font-family : Verdana, Arial, Helvetica, sans-serif; font-size: 11px; vertical-align : middle;
	color: #444444; background-color: #dddddd;
}</style>

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
		</table>
	
<table width='90%' border='0' cellspacing='0' cellpadding='0'>			
			<tr>
	          <td>
	            <table width="100%" border="0" cellspacing="0" cellpadding="0">
				  <tr>
					<td width="26" height="30"><a name="top">&nbsp;</a></td>
					<td height="30" align="left" valign="bottom" class="head">
						<b>Update Phase Definition</b>
					</td>
<%	// @AGQ050506
	if (isAboveUser) 
	{%>
		<td width='250'>
			<img src="../i/bullet_tri.gif" width="20" height="10">
			<a class="listlinkbold" href="phase_update2.jsp?projId=<%=projIdS%>">Update Milestone Schedule</a>
		</td>
	<% } 
	else {%>
		<td></td>
<% } %>	
				  </tr>
	            </table>
	          </td>
	        </tr>
			<tr>
          		<td width="100%">
<!-- Navigation Menu -->
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Project" />
				<jsp:param name="subCat" value="" />
				<jsp:param name="role" value="<%=iRole%>" />
			</jsp:include>
<!-- End of Navigation Menu -->
				</td>
	        </tr>
		</table>


<!-- MAIN CONTENT -->
<br>
<form name="updatePhase" action="post_updphase.jsp" method="post">
	<input type="hidden" name="projId" value="<%=projIdS%>">
	<input type="hidden" name="addPhase">
<table>
<tr>
    <td width="12">&nbsp;</td>
	<td class="plaintext" width="350">
		&nbsp;Please note fields marked with an * are required.</td>



</tr>
<tr>
    <td width="12">&nbsp;</td>
<td colspan='2'>

<!-- start table -->
	<table width="775" border="0" cellspacing="0" cellpadding="0" bgcolor="#FFFFFF">
	<tr><td colspan="2">
		<table cellpadding="4" cellspacing="2" border="0">
<!-- project ID -->
		<tr bgcolor="#FFFFFF">
		<td class="td_field_bg" width="160">Project ID</td>
		<td class="td_value_bg" width="593" style="font-weight: bold; font-size: 12px; color: #DD0000">&nbsp;<%=projIdS%></td>
		</tr>

<!-- project name -->
		<tr bgcolor="#FFFFFF">
		<td class="td_field_bg" width="160">Project Name</td>
		<td class="td_value_bg" valign="middle" style="font-weight: bold; font-size: 12px; color: #444444">&nbsp;<%=projName%></td>
		</tr>
		


<!-- ****************** Project Phases ******************* -->
<%if (isAboveUser)
{%>

	<tr><td colspan="2" class="title" valign="bottom"><br>Project Phases</td>
	</tr>
	</table>
	</td></tr>
	<tr><td colspan='2'>
	<table cellspacing="0" cellpadding="0" border="0">
		<tbody>
		<tr><td id='phBody'>

<!-- Phases -->
<%
	String [] saa;
	String subphTid=null, subphName=null, subphStart=null, subphDeadln=null, subphStatus=null;
	int totalSubPhases = 0;
	for (int i=0; i<totalPhases; i++)
	{	
		totalSubPhases = 0;
		out.println("<table width='100%' border='0' cellpadding='4' cellspacing='2'>");
		out.println("<tbody id='subphBody"+i+"'>");
		out.print("<tr><td></td></tr>");
		out.print("<tr bgcolor='#FFFFFF'>");
		out.print("<td class='td_field_bg' width='160'>Phase " + (i+1) + "</td>");
		out.print("<td class='td_value_bg_11' width='590'>Name:&nbsp;&nbsp;");
// @AGQ050506a
		out.print("<input class='formtext' type='Text' name='Phase" +i+ "' size='60' value=\"" +Util.stringToHTMLString(phaseS[i])+ "\">");
		out.print("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
		out.print("<input type='checkbox' name='PhaseTaskCheck" + i + "' onclick='phase_use_task(" + i + ")'");
		if (phaseTask[i]!="") out.print("checked");
		out.print(" >Task ID:&nbsp;&nbsp;");
		out.print("<input class='formtext' type='text' name='PhaseTask" + i + "' size='5' value='" + phaseTask[i] + "'>");
		out.print("<br>");

		out.print("Status: <select width='100' style='width:100px' class='formtext' onchange=\"checkStatus("+i+")\" name='Status" +i+ "'>");
// @AGQ050806		
		String [] phaseArr = phase.createStatusArray(phaseSt[i]);
		for (int j=0; j<phaseArr.length; j++)
		{
			out.print("<option value='" + phaseArr[j] + "'");
			if (phaseSt[i]!=null && phaseSt[i].equals(phaseArr[j]))
				out.print(" selected");
			out.print(">" + phaseArr[j]);
		}
		out.print("</select>");		// status
		out.print("&nbsp;&nbsp;&nbsp;&nbsp;");
				
		out.print("Start:&nbsp;&nbsp;");
		out.print("<input class='formtext' type='Text' name='PhStart" +i+ "' size='12' value='");
		if (phaseB[i] != null)
			out.print(phaseB[i]);
		out.print("' onClick='show_cal(updatePhase.PhStart" +i+ ");'>");
		out.print("&nbsp;<a href='javascript:show_cal(updatePhase.PhStart" +i+ ");' name='PhStartCal"+i+"' onclick='return true;'><img src='../i/calendar.gif' border='0' align='absmiddle' alt='Click to view calendar.'></a>");
		out.print("&nbsp;&nbsp;&nbsp;&nbsp;");

		out.print("Due: <input class='formtext' type='Text' name='Deadline" +i+ "' size='12' value='");
		if (phaseD[i] != null)
			out.print(phaseD[i]);
		out.print("' onClick='show_cal(updatePhase.Deadline" +i+ ");'>");
		out.print("&nbsp;<a href='javascript:show_cal(updatePhase.Deadline" +i+ ");' name='DeadlineCal"+i+"' onclick='return true;'><img src='../i/calendar.gif' border='0' align='absmiddle' alt='Click to view calendar.'></a>");
		out.print("&nbsp;&nbsp;&nbsp;&nbsp;");
		
		// phase color
		out.print("Color: <input class='formtext' type='Text' name='Color"+i+ "' size='6' value='");
		if (phColor[i] != null)
			out.print(phColor[i]);
		out.print("'>");
		
		out.print("<br />");
		
		//out.print("<img align='left' src='../i/spacer.gif' height='1' width='80'>");
		out.print("<input type='hidden' name='Delete"+i+"' value='false'>");
		out.print("<a onclick='javascript:removePhase("+i+")'><img style='border:0; cursor:pointer' align='right' alt='Delete' src='../i/delete.gif' /></a>");
		out.print("Actual Completion:&nbsp;&nbsp;");
		out.print("<input class='formtext' type='Text' name='PhComplete" +i+ "' size='12' value='");
		if (phaseC[i] != null)
			out.print(phaseC[i]);
		out.print("' onClick='show_cal(updatePhase.PhComplete" +i+ ");'>");
		out.print("&nbsp;<a href='javascript:show_cal(updatePhase.PhComplete" +i+ ");' name='PhCompleteCal"+i+"' onclick='return true;'><img src='../i/calendar.gif' border='0' align='absmiddle' alt='Click to view calendar.'></a>");
		out.print("&nbsp;&nbsp;&nbsp;&nbsp;");		
		
		out.print("</td></tr>");	// end a main phase

		// handle subphases if any
		int subCt = 0;
// @AGQ042506
		if (phaseExt[i] != null)
		{
			// there were sub-phase defined
			objArr = phMgr.getSubPhases(pstuser, phaseExt[i]);
			totalSubPhases = objArr.length;
			
			for (int m=0; m<objArr.length; m++)
			{
				subphTid = subphName = subphStart = subphDeadln = subphStatus=null;
				ph = (phase) objArr[m];
				Object obj = ph.getAttribute(phase.TASKID)[0];
				
				// it might be using task link
				if (obj != null)
				{
					// use task to fill the phase info
					subphTid = obj.toString();
					try {
						tk = tkMgr.get(pstuser, subphTid);
						obj = ph.getAttribute(phase.NAME)[0];
						if (obj == null)
						{
							ids = ptMgr.findId(pstuser, "TaskID='" + subphTid + "' && Status!='Deprecated'");
							ptk = ptMgr.get(pstuser, ids[ids.length-1]);
							subphName = (String)ptk.getAttribute("Name")[0];
						}
						else
							subphName = obj.toString();

						dt = (Date)tk.getAttribute("EffectiveDate")[0];
						if (dt == null)
							dt = (Date)tk.getAttribute("StartDate")[0];
						if (dt != null)
							subphStart = df.format(dt);
// @AGQ050306						
						dt = (Date)tk.getAttribute("ExpireDate")[0];
						subphDeadln = phase.parseDateToString(dt, format);

						s = (String)tk.getAttribute("Status")[0];
						if (s.equals(task.ST_NEW)) s = project.PH_NEW;
						else if (s.equals(task.ST_OPEN) || s.equals(task.ST_ONHOLD)) s = project.PH_START;
						subphStatus = s;
					}
					catch (PmpException e){subphName="*** Invalid task ID";}	// indicate error
				}
				else
				{
					subphTid	= "";
					subphName	= ph.getAttribute(phase.NAME)[0].toString();
// @AGQ050506a					
					subphName	= Util.stringToHTMLString(subphName);

					dt = (Date)ph.getAttribute(phase.STARTDATE)[0];
					if (dt != null)
						subphStart = df.format(dt);

					dt = (Date)ph.getAttribute(phase.EXPIREDATE)[0];
					subphDeadln = phase.parseDateToString(dt, format);
					
					subphStatus = ph.getAttribute(phase.STATUS)[0].toString();
				}

				// do for each sub-phase record of this phase [i]
				out.print("<tr bgcolor='#FFFFFF'>");
				out.print("<td class='td_field_bg' width='160'>Milestone " + (i+1) + "." + (subCt+1) + "</td>");
				out.print("<td class='td_subPhase'>Name:&nbsp;&nbsp;");
				out.print("<input class='formtext' type='Text' name='SubPhase" +i+"_"+subCt + "' size='60' value=\""
					+subphName+ "\">");
				out.print("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
				out.print("<input type='checkbox' name='SubPhaseTaskCheck" +i+"_"+subCt + "' onclick='subphase_use_task(" + i + "," + subCt +")'");
// @AGQ050406A
				String disabled = "";
				if (subphTid!="") {
					out.print("checked");
				}
				else
					disabled = "disabled='disabled'";
				
				out.print(" >Task ID:&nbsp;&nbsp;");
				out.print("<input class='formtext' type='text' name='SubPhaseTask" +i+"_"+subCt + "' size='5' value='" + subphTid + "' " + disabled + " >");
				out.print("<br>");

				out.print("<input type='hidden' name='SubDelete"+i+"_"+subCt+"' value='false'>");
				out.print("<a onclick='javascript:removePhase("+i+","+subCt+")'><img style='border:0; cursor:pointer' align='right' alt='Delete' src='../i/delete.gif' /></a>");
				
				out.print("Status: <select width='100' style='width:100px' class='formtext' onchange=\"checkStatus("+i+","+subCt+")\" name='SubStatus" +i+"_"+subCt + "'>");
// @AGQ050806
				String [] subPhaseArr = phase.createStatusArray(subphStatus);
				for (int j=0; j<subPhaseArr.length; j++)
				{
					out.print("<option value='" + subPhaseArr[j] + "'");
					if (subphStatus!=null && subphStatus.equals(subPhaseArr[j]))
						out.print(" selected");
					out.print(">" + subPhaseArr[j]);
				}
				
				out.print("</select>");		// status	
				out.print("&nbsp;&nbsp;&nbsp;&nbsp;");
/*				
				out.print("Start:&nbsp;&nbsp;");
				out.print("<input class='formtext' type='Text' name='SubPhStart" +i+"_"+subCt + "' size='12' value='");
				if (subphStart != null)
					out.print(subphStart);
				out.print("' onClick='show_cal(updatePhase.SubPhStart" +i+"_"+subCt + ");'>");
				out.print("&nbsp;<a href='javascript:show_cal(updatePhase.SubPhStart" +i+"_"+subCt + ");'><img src='../i/calendar.gif' border='0' align='absmiddle' alt='Click to view calendar.'></a>");
				out.print("&nbsp;&nbsp;&nbsp;&nbsp;");
*/
				//out.print("<img src='../i/spacer.gif' height='1' width='151'>");

				out.print("Due: &nbsp;&nbsp;<input class='formtext' type='Text' name='SubDeadline" +i+"_"+subCt + "' size='12' value='");
				if (subphDeadln != null)
					out.print(subphDeadln);
				out.print("' onClick='show_cal(updatePhase.SubDeadline" +i+"_"+subCt + ");'>");
				out.print("&nbsp;<a href='javascript:show_cal(updatePhase.SubDeadline" +i+"_"+subCt + ");' name='SubDeadlineCal"+i+"_"+subCt+"' onclick='javascript: return true;'><img src='../i/calendar.gif' border='0' align='absmiddle' alt='Click to view calendar.'></a>");
				out.print("&nbsp;&nbsp;&nbsp;&nbsp;");

				
				
				out.print("</td></tr>");
				// @AGQ041006 disable the subphase box
%>
					<script type="text/javascript">
					//<!-- 
					subphase_use_task(<%=i%>,<%=subCt%>); 
					//-->
					</script> 
<%					
				subCt++;					// end a sub-phase
			}
		}
%>
<script type="text/javascript">
<!--
	phase_use_task(<%=i%>);		// enable or disable phase fields based on the use of task link
//-->
</script>
<%
		// add a new subphase?
		if (addSubPhaseId == i)
		{
			out.println("<input type='hidden' name='subPhaseParent' value='" +i+ "'>");
			out.print("<tr bgcolor='#FFFFFF'>");
			out.print("<td class='td_field_bg' width='160'>&nbsp;&nbsp;&nbsp;");
			out.print("Milestone " + (i+1) + "." + (subCt+1) + "</td>");

			// attempt to get the default system subphase name if it exist
			s = Util.getPropKey(PROP_FILE, "PHS."+(i+1)+"."+(subCt+1));
			if (s == null) s = "";
			out.print("<td class='td_value_bg_11;'>Name:&nbsp;");
// @AGQ050506a		
			out.print("<input class='formtext' type='Text' name='SubPhase" +i+"_"+subCt+ "' size='60' value=\""
					+ Util.stringToHTMLString(s) + "\">");
			out.print("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
			out.print("<input type='checkbox' name='SubPhaseTaskCheck" +i+"_"+subCt + "' onclick='subphase_use_task(" + i + "," + subCt +")'");
			out.print(" >Task ID");
			out.print("<input class='formtext' type='text' name='SubPhaseTask" +i+"_"+subCt + "' size='5' value='' disabled='disabled'>");
			out.print("<br>");
			out.print("Start:&nbsp;&nbsp;");

			out.print("<input class='formtext' type='Text' name='SubPhStart" +i+"_"+subCt+ "' size='12' value=''");
			out.print(" onClick='show_cal(updatePhase.SubPhStart" +i+"_"+subCt+ ");'>");
			out.print("&nbsp;<a href='javascript:show_cal(updatePhase.SubPhStart" +i+"_"+subCt+ ");'><img src='../i/calendar.gif' border='0' align='absmiddle' alt='Click to view calendar.'></a>");
			out.print("&nbsp;&nbsp;&nbsp;&nbsp;");

			out.print("Due: <input class='formtext' type='Text' name='SubDeadline" +i+"_"+subCt+ "' size='12' value=''");
			out.print(" onClick='show_cal(updatePhase.SubDeadline" +i+"_"+subCt+ ");'>");
			out.print("&nbsp;<a href='javascript:show_cal(updatePhase.SubDeadline" +i+"_"+subCt+ ");'><img src='../i/calendar.gif' border='0' align='absmiddle' alt='Click to view calendar.'></a>");
			out.print("&nbsp;&nbsp;&nbsp;&nbsp;");

			out.print("Status: <select class='formtext' name='SubStatus" +i+"_"+subCt+ "'>");
			for (int j=0; j<project.PHASE_ARRAY.length; j++)
			{
				out.print("<option value='" + project.PHASE_ARRAY[j] + "'");
				out.print(">" + project.PHASE_ARRAY[j]);
			}

			out.print("</select>&nbsp;");		// status
			out.print("&nbsp;&nbsp;<font color='#ee2222'>Enter info and click submit</font>");

			out.print("</td></tr>");
		}

		// @AGQ042506 Adding a subphase
		int subPhases = 0;
		if (phaseExt[i] != null)
		{
			objArr = phMgr.getSubPhases(pstuser, phaseExt[i]);
			subPhases = objArr.length;
		}
		//out.print("<tr><td colspan='2' align='right'><input type='submit' class='button' name='addSubPhase_" +i+ "' value='Add Sub-phase' onclick=\"return addSubPhase('" +i+ "', "+subPhases+");\"></td></tr>");

		//out.print("<tr><td colspan='2' align='right'><img src='../i/bullet_tri.gif' width='20' height='10'>");
		//out.print("<a class='listlinkbold' href='javascript:addSubPhase(\"subphBody"+i+"\")'>Add Sub Phase</a></td></tr>");

		
		//out.print("<tr><td colspan='2'>&nbsp;</td></tr>");

%>
<script type="text/javascript">
	var addsp<%=i%> = new newSubPhases("subphBody<%=i%>", <%=i%>, <%=totalSubPhases%>);
</script>
<%		
		
		out.println("</tbody></table>");
		out.print("<div align='right'><img src='../i/bullet_tri.gif' width='20' height='10'>");
		out.print("<a class='listlinkbold' href='javascript:addsp"+i+".addSubPhase()'>Add Sub Phase</a></div>");
		out.println("<br />");
	}		// end for MAX_PHASES

%>
<script type="text/javascript">
	var addp = new newPhases("phBody", <%=totalPhases%>);
</script>
<%		

	out.println("</td></tr></tbody>");
	out.println("</table>");
	out.print("<div align='left'><img src='../i/bullet_tri.gif' width='20' height='10'>");
	out.print("<a class='listlinkbold' href='javascript:addp.addPhase()'>Add Phase</a></div>");	
}	// end isAboveUser
%>


</table>
<!-- end table -->

		<p align="center">
		<input type='button' class='button_medium' value='Submit' onClick='document.updatePhase.submit()'>
		&nbsp;&nbsp;&nbsp;
		<input type='button' class='button_medium' value='Cancel' onClick='location="proj_summary.jsp?projId=<%=projIdS%>"'>
		<br></p>


	</td>
</tr>
</table>
<!-- END MAIN CONTENT -->
</form>
</td>
</tr>


<tr><td>&nbsp;</td></tr>


<!-- BEGIN FOOTER TABLE -->
<jsp:include page="/foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>

<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

