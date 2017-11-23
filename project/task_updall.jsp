<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>

<%
////////////////////////////////////////////////////
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	task_updall.jsp
//	Author:	ECC
//	Date:	07/19/05
//	Description:
//		One page update a number of tasks.  Proj owner can update all tasks.
//		Task members can update their own tasks.
//
//	Modification:
//		@ECC112405	Added Duration and Gap to task.  We can now calculate StartDate of a task
//					based on the Dependency and Gap.
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

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />


<%
	HashMap<String, String> taskIdMap = new HashMap<String, String> (512);
	String projIdS = request.getParameter("projId");
	if ((pstuser instanceof PstGuest) || (projIdS == null))
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	//task.setDebug(true);	// ECC

	boolean isAdmin = false;
	boolean isProgMgr = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if (iRole > 0)
	{
		if ((iRole & user.iROLE_ADMIN) > 0)
			isAdmin = true;
		if ((iRole & user.iROLE_PROGMGR) > 0)
			isProgMgr = true;
	}

	// to check if session is CR or PRM
	boolean isCRAPP = Prm.isCR();
	boolean isCwModule = Prm.isCwModule(session);

	projectManager projMgr = projectManager.getInstance();
	taskManager tkMgr = taskManager.getInstance();
	userManager uMgr = userManager.getInstance();

	int myUid = pstuser.getObjectId();

	////////////////////////////////////
	// Need to make sure that the plan is completely loaded by background thread
	String s = (String)session.getAttribute("planComplete");
	while (s!=null && s.equals("false"))
	{
		try {Thread.sleep(500);}		// sleep for 0.5 sec
		catch (InterruptedException e) {}
		s = (String)session.getAttribute("planComplete");
	}
	////////////////////////////////////

	project projObj = (project)projMgr.get(pstuser, Integer.parseInt(projIdS));
	String projDispName = projObj.getDisplayName();
	String version = (String)projObj.getAttribute("Version")[0];
	String projStatus = (String)projObj.getAttribute("Status")[0];
	int projOwnerId = Integer.parseInt((String)projObj.getAttribute("Owner")[0]);

	// get the latest plan
	planManager planMgr = planManager.getInstance();
	String [] planNames = planMgr.findName(pstuser, "(ProjectID='" +projIdS+ "') && (Status='Latest')");
	plan latestPlan = (plan)planMgr.get(pstuser, planNames)[0];

	// Get plan task (stack is constructed first time when going into a plan)
	Stack planStack = (Stack)session.getAttribute("planStack");
	if((planStack == null) || planStack.empty())
	{
		Util3.refreshPlanHash(pstuser, session, projIdS);
		planStack = (Stack)session.getAttribute("planStack");
		//response.sendRedirect("../out.jsp?msg=Internal error in opening plan stack.  Please contact administrator.");
		//return;
	}
	Vector rPlan = (Vector)planStack.peek();

	// all project team people
	PstAbstractObject [] teamMember = ((user)pstuser).getTeamMembers(projObj);
	
	// project option: send notification
	String checkStr = projObj.getOption(project.OP_NOTIFY_BLOG)==null ? "" : "checked";
	
	// dirty map
	HashMap<String, String> dirtyMap = (HashMap) session.getAttribute("taskDirtyMap");	// check the dirty map for update
	if (dirtyMap == null) {
		// init dirty map
		dirtyMap = new HashMap<String, String> (512);
		session.setAttribute("taskDirtyMap", dirtyMap);
	}

%>

<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>

<jsp:include page="../errormsg.jsp" flush="true"/>
<jsp:include page="../init.jsp" flush="true"/>
<script type="text/javascript" language="javascript">
<!--

function checkUpdate(e)
{
	e.checked = true;
}

function checkInt(type, tid)
{
	// specify Duration or Gap
	var e = document.getElementsByName(type + "_" + tid)[0];
	e.value = e.value.replace( /(^\s*)|(\s*$)/g, '' );		// trim spaces
	var i = parseInt(e.value);
	if (e.value!="" && (isNaN(i) || i<=0) )
	{
		if (type=='Gap' && i<0)
		{
			alert("To specify a GAP, you must enter an integer that is greater than or equal to 0.");
			e.value = "";
			return;
		}
		else if (type=='Dur')
		{
			alert("To specify a DURATION, you must enter an integer that is greater than 0.");
			e.value = "";
			return;
		}
	}

	// enable/disabled StartDate and ExpireDate
	var gapCell = document.getElementsByName("Gap_" + tid)[0];
	var durCell = document.getElementsByName("Dur_" + tid)[0];
	var startCell = document.getElementsByName("Start_" + tid)[0];
	var expireCell = document.getElementsByName("Expire_" + tid)[0];
	
	var changedCell = document.getElementsByName(type + "_" + tid)[0];	// the changed cell (gap or dur)
	if (changedCell.value != "")
	{
		if (type == "Gap") {
			// if Gap==0 and Dur is empty, then treats Gap as empty
			if (gapCell.value=="0" && durCell.value == "") {
				gapCell.value = "";
			}
		}
		else if (type == "Dur") {
			// when Dur is not empty, if Gap is empty, treats it as "0"
			if (gapCell.value == "") {
				gapCell.value = "0";
			}
		}
	}
	else
	{
		if (type == "Gap") {
			// Gap empty is consider 0 if Dur is not empty
			if (durCell.value != "") {
				gapCell.value = "0";
			}
		}
		else if (type == "Dur") {
			// when Dur is empty, if Gap is 0, treats it as empty
			if (gapCell.value == "0") {
				gapCell.value = "";
			}
		}
	}

	// now based on Gap and Dur is empty or not to enable/disable Planned Start/Expire
	if (gapCell.value == "") startCell.disabled = false;
	else startCell.disabled = true;
	if (durCell.value == "") expireCell.disabled = false;
	else expireCell.disabled = true;

	e = document.getElementsByName("update_" + tid)[0].checked = true;
}

var lastBlogTid = "";
function postBlog(tid)
{
	// open/close edit blog textarea
	var e;
	if (lastBlogTid != "") {
		e = document.getElementById("blogDiv_" + lastBlogTid);
		e.style.display = 'none';
	}
	if (tid==0 || lastBlogTid==tid) {
		lastBlogTid = "";
		return;	// just cancel
	}
	
	e = document.getElementById("blogDiv_" + tid);
	e.style.display = 'block';
	lastBlogTid = "" + tid;

	e = document.getElementById("blogEdit_" + tid);
	e.focus();
}

function saveBlog()
{
	// call post_addblog.jsp to save the blog
	var tidS = lastBlogTid;

	var e = document.getElementById("blogEdit_" + tidS);
	var text = trim(e.value);
	text = text.replace(/\n/g, "<br>");
	if (text == "") {
		postBlog(0);	// close the edit window
		return;
	}
	lastBlogTid = "";	//reset
	
	var loc = "../blog/post_addblog.jsp?type=<%=result.TYPE_TASK_BLOG%>"
		+ "&id=" + tidS + "&logText=" + text;
	var ee = document.getElementById("sendEmail_" + tidS);

	// override project option
	if (ee.checked)
		loc += "&forceSendEmail=true";
	else
		loc += "&forceSendEmail=false";
	loc	+= "&backPage=../project/task_updall.jsp?projId=<%=projIdS%>@" + tidS;
	
	location = loc;
}

function copyPlanToOrig()
{
	// copy original dates to planned dates
	if (!confirm("Are you sure you want to overwrite the ORIGINAL START/DUE DATES with the PLANNED START/DUE DATES?"))
		return false;
	var f = document.GroupUpdate;
	f.op.value = "copyPlanToOriginal";
	f.submit();
}

//-->
</script>

<title>
	<%=Prm.getAppTitle()%> Task Dependencies
</title>

</head>

<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="715" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<table width='90%'>

	<tr><td colspan="2">&nbsp;</td></tr>
	<tr>
		<td></td>
		<td>
			<b class="head">Update Tasks</b>
		</td>
		<td align='right'><img src='../i/bullet_tri.gif'/>
			<a class='listlinkbold' href='../project/proj_top.jsp'>Back to Project Top</a>
		</td>
	</tr>

	<tr>
	<td></td>
	<td valign="top" class="title">
		&nbsp;&nbsp;&nbsp;<%=projDispName%>
	</td>
	</tr>
	</table>

	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>


<!-- Navigation SUB-Menu -->
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
<td width="100%" valign="top">

	<table border="0" width="100%" height="14" cellspacing="0" cellpadding="0">
		<tr>
			<td bgcolor='#EBECED'><img src='../i/spacer.gif' width='50' height='1'/></td>
			<td valign="top" class="bgsubnav">
				<table border="0" cellspacing="0" cellpadding="0">
				<tr class="bgsubnav">
	<!-- Top -->
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<td><img src="../i/spacer.gif" width="10" height="1" border="0"></td>
					<td><a href="proj_top.jsp?projId=<%=projIdS%>" class="subnav">Top</a></td>
					<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
	<!-- File Repository -->
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="cr.jsp?projId=<%=projIdS%>" class="subnav">File Repository</a></td>
					<td colspan="3" width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
<%if (!isCRAPP){%>
	<!-- Project Plan -->
					<td width="20"><img src="../i/spacer.gif" width="10" height="1" border="0"></td>
					<td><a href="proj_plan.jsp?projId=<%=projIdS%>" class="subnav"><%=Prm.getProjectPlanLabel()%></a></td>
					<td width="15"><img src="../i/spacer.gif" width="10" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
<%} %>
	<!-- Update All Tasks -->
					<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
					<td width="20" height="14"><img src="../i/nav_arrow.gif" width="20" height="14" border="0"></td>
					<td><a href="#" onClick="return false;" class="subnav"><u>Update All Tasks</u></a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
<%if (!isCRAPP){%>
	<!-- Dependencies -->
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="../plan/dependency.jsp?projId=<%=projIdS%>" class="subnav">Dependencies</a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
	<!-- Timeline -->
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="../plan/timeline.jsp?projId=<%=projIdS%>" class="subnav">Timeline</a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
<%	if (isCwModule) {%>
	<!-- Work In-Tray -->
					<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
					<td><a href="../box/worktray.jsp?projId=<%=projIdS%>" class="subnav">Work In-Tray</a></td>
					<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
<%	}
}%>
				</tr>
				</table>
			</td>
		</tr>
	</table>
	<table border="0" width="100%" height="1" cellspacing="0" cellpadding="0">
		<tr>
			<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
		</tr>
	</table>

</td>
</tr>
</table>
<!-- End of Navigation SUB-Menu -->



<!-- CONTENT -->

<!-- ************************************************ -->
<form method="post" name="GroupUpdate" action="post_updall.jsp">
<input type="hidden" name="projId" value='<%=projIdS%>'>
<input type="hidden" name="op" value=''>

<table width="100%" border="0" cellspacing="0" cellpadding="0">
	<tr>
	<td width="10"><img src="../i/spacer.gif" height="1" width="10" alt=" " /></td>
	<td>
		<table border="0" cellspacing="0" cellpadding="0" width='100%'>
			<tr><td><img src="../i/spacer.gif" height="5" width="1" /></td></tr>
			<tr>
			<td width='80'>
				<input type='button' class='button_medium' value='Submit' onClick='this.disabled=true;document.GroupUpdate.submit();'>&nbsp;&nbsp;
			</td>
			<td width='80'>
<%			if (!isCRAPP){
				out.print("<input type='button' class='button_medium' value='Cancel' onClick='location=\"proj_plan.jsp?projId=" + projIdS + "\"'>");
			}
			else {
				out.print("<input type='button' class='button_medium' value='Cancel' onClick='location=\"cr.jsp?projId=" + projIdS + "\"'>");
			}
%>
			</td>
<%
			out.print("<td>&nbsp;</td>");
			// allow owner to copy planned dates to original dates
			if (projOwnerId == myUid) {
				out.print("<td align='right'>");
				out.print("<input type='button' class='button_medium' value='<< Copy Plan to Original' onClick='copyPlanToOrig();';>");
				out.print("</td>");
				out.print("<td><img src='../i/spacer.gif' width='10' height='1'/></td>");
			}
%>			
			</tr>
			<tr><td><img src="../i/spacer.gif" height="5" width="1" alt=" " /></td></tr>
		</table>

<%
	// project support resource management?
	String [] label;
	int [] labelLen;
	String optAttr = null;
	boolean bResourceMgmt = (s=projObj.getOption(project.OP_RESOURCE_MGMT)) != null;
	if (bResourceMgmt) {
		int idx = s.indexOf(project.DELIMITER2);
		optAttr = s.substring(0, idx);			// float1
		String optUnit = s.substring(idx+1);	// extract hr/wk from "float1@hr/wk"
		String [] rscMgmtLabel = {"Update", "Task Name", "Blog", "St.",
						"Wt<br>(" + optUnit + ")",
						"Owner", "Dependency", "Gap<br>(days)", "Length<br>(days)",
						"Original<br>Start", "Original<br>Due",
						"Planned<br>Start", "Planned<br>Due",
						"Actual<br>Start", "Actual<br>Finish"};
		label = rscMgmtLabel;
		int [] rscMgmtLabelLen = {30, 350, 30, 15, 30, 70, 80, 30, 30, 53, 53, 53, 53, 53, 53};
		labelLen = rscMgmtLabelLen;
	}
	else {
		String [] basicLabel = {"Update", "Task Name", "Blog", "St.",
			 			"Owner", "Dependency", "Gap<br>(days)", "Length<br>(days)",
						"Original<br>Start", "Original<br>Due",
						"Planned<br>Start", "Planned<br>Due",
						"Actual<br>Start", "Actual<br>Finish"};
		label = basicLabel;
		int [] basicLabelLen = {30, 350, 30, 15, 70, 80, 30, 30, 53, 53, 53, 53, 53, 53};
		labelLen = basicLabelLen;
	}
	out.print(Util.showLabel(label, labelLen));

	String format = "MM/dd/yy";
	SimpleDateFormat df = new SimpleDateFormat(format);//"MM/dd/yy");
	String bgcolor="";
	boolean even = false;
	String[] levelInfo = new String[JwTask.MAX_LEVEL];
	String lastlevelInfo = "";
	task t;
	String ownerIdS;
	int ownerId=0, id;
	Date oriStartD, startD, actualD, oriExpireD, expireD, completeD;
	String userEdit, dot, tStatus, gap=null, dur=null, planDtUpdate;
	String depString, blogNumS;
	Integer iObj;
	DecimalFormat dcf = new DecimalFormat("#0.0");
	String begB, endB;

	// allow update of original planned dates?
	String oriUserEdit = "disabled";
	if (projStatus.equals(project.ST_NEW) || projOwnerId==myUid) {
		oriUserEdit = "";
	}
	
	// first build the taskID hash before displaying the task list
	int level, order;
	Object [] pLevel, pOrder;
	String taskIdS;
	for (int i = 0; i < rPlan.size(); i++) {
		Hashtable rTask = (Hashtable) rPlan.elementAt(i);
		taskIdS = (String) rTask.get("TaskID");
		pLevel = (Object[]) rTask.get("Level");
		pOrder = (Object[]) rTask.get("Order");

		level = ((Integer) pLevel[0]).intValue();
		order = ((Integer) pOrder[0]).intValue() + 1;

		if (level == 0) {
			levelInfo[level] = Integer.toString(order);
		} else {
			levelInfo[level] = levelInfo[level - 1] + "." + order;
		}

		// save the taskId / header info in the map for dependency info
		taskIdMap.put(taskIdS, levelInfo[level]);
	}
	// done building taskIdMap for dependencies
	///////////////////////////////////////

	for(int i = 0; i < rPlan.size(); i++)
	{
		Hashtable rTask = (Hashtable)rPlan.elementAt(i);
		String tName = (String)rTask.get("Name");
		int taskId = Integer.parseInt((String)rTask.get("TaskID"));
		taskIdS = String.valueOf(taskId);
		int planTaskId = Integer.parseInt((String)rTask.get("PlanTaskID"));
		t = (task)tkMgr.get(pstuser, taskId);
		
		if (dirtyMap.get(taskIdS)!=null) {
			begB = "<b>"; endB = "</b>";
		}
		else {
			begB = endB = "";
		}

		// owner
		userEdit = " disabled";
		ownerIdS = (String)t.getAttribute("Owner")[0];
		if (ownerIdS != null)
		{
			ownerId = Integer.parseInt(ownerIdS);
			if (isAdmin || isProgMgr || t.isAuthorizedUser(pstuser, task.WRITE))
				userEdit = "";
		}

		// @ECC112405 Gap and Duration
		iObj = (Integer)t.getAttribute("Duration")[0];	// won't be null.  For INT, if no value, val=0
		if (iObj.intValue() > 0)
			dur = iObj.toString();
		else
			dur = "";

		iObj = (Integer)t.getAttribute("Gap")[0];
		if (iObj.intValue() > 0)
			gap = iObj.toString();
		else if (dur == "")
			gap = "";
		else
			gap = "0";	// dur is not empty, then gap is treated as 0 if empty

		// Date
		startD = (Date)t.getAttribute("StartDate")[0];
		actualD = (Date)t.getAttribute("EffectiveDate")[0];
		expireD = (Date)t.getAttribute("ExpireDate")[0];
		completeD = (Date)t.getAttribute("CompleteDate")[0];
		oriStartD = (Date)t.getAttribute("OriginalStartDate")[0];
		oriExpireD = (Date)t.getAttribute("OriginalExpireDate")[0];

		tStatus = (String)t.getAttribute("Status")[0];

		pLevel = (Object [])rTask.get("Level");
		pOrder = (Object [])rTask.get("Order");

		level = ((Integer)pLevel[0]).intValue();
		order = ((Integer)pOrder[0]).intValue();

		int width = 22 * level;	// 10 + 22 * level;
		order++;
		if (level == 0)
			levelInfo[level] = Integer.toString(order);
		else
			levelInfo[level] = levelInfo[level - 1] + "." + order;

		// dependency (those that I depend on)
		depString = "";
		Object [] depAttr = t.getAttribute("Dependency");
		for (int j=0; j<depAttr.length; j++) {
			s = (String)depAttr[j];
			if (s == null) break;
			if (depString.length() > 0) {
				depString += ", ";
			}
			s = taskIdMap.get(s);
			if (s == null)
				s = (String)depAttr[j];;
			depString += s;
		}
		//depString = Util2.getAttributeString(t, "Dependency", "; ");

		level++;

		if (even)
			bgcolor = Prm.DARK;
		else
			bgcolor = Prm.LIGHT;
		even = !even;

		if (level == 1) {
			// top level, put a partition
			if (order > 1) {
				out.println("<tr " + bgcolor + "><td colspan='45'><img src='../i/spacer.gif' height='2' /></td></tr>");
				out.println("<tr bgcolor='#aaaaaa'><td colspan='45'><img src='../i/spacer.gif' height='2' /></td></tr>");
			}
			out.println("<tr " + bgcolor + "><td colspan='42'><img src='../i/spacer.gif' height='5' /></td></tr>");
		}

		out.print("<tr " + bgcolor + ">");

		out.print("<td><a name='" + taskId + "'></a></td>");
		out.print("<td height='23' width='20' align='center'>");
		out.print("<input type='checkbox' name='update_" + taskId + "'" + userEdit + ">");
		out.println("</td>");

		// the index and task name: one TD
		out.print("<td colspan='2'></td>");
		out.print("<td width='370'><table width='100%' border='0' cellspacing='0' cellpadding='0'><tr>");
		out.print("<td width='" + width + "' class='plaintext' height='20'><img src='../i/spacer.gif' width='" + width + "' height='2' border='0'></td>");
		out.print("<td width='20' class='plaintext_grey' valign='top'>" + begB);
		out.print(levelInfo[level-1] + endB + "&nbsp;&nbsp;</td>");
		out.print("<td class='plaintext' title='TaskID: " + taskId + "'>");
		out.print("<a href='task_update.jsp?projId=" + projIdS
			+ "&pTaskId=" + planTaskId + "'>" + begB + tName + endB + "</a></td>");
		out.print("</tr></table></td>");
		
		// blog
		blogNumS = (String)rTask.get("BlogNum");
		out.print("<td colspan='2'></td>");
		out.print("<td class='listlink' align='center'>");
		out.print("<a href='javascript:postBlog(" + taskId + ");'>" + blogNumS + "</a>");
		out.println("</td>");

		// status
		dot = "../i/";
		if (t.isContainer()) {dot += "db.jpg"; tStatus="Container";}
		else if (tStatus.equals(task.ST_OPEN)) {dot += "dot_lightblue.gif";}
		else if (tStatus.equals(task.ST_NEW)) {dot += "dot_orange.gif";}
		else if (tStatus.equals(task.ST_COMPLETE)) {dot += "dot_green.gif";}
		else if (tStatus.equals(task.ST_LATE)) {dot += "dot_red.gif";}
		else if (tStatus.equals(task.ST_ONHOLD)) {dot += "dot_grey.gif";}
		else if (tStatus.equals(task.ST_CANCEL)) {dot += "dot_cancel.gif";}
		else {dot += "dot_grey.gif";}
		out.print("<td colspan='2'></td>");
		out.print("<td class='listlink' align='center'>");
		out.print("<img src='" + dot + "' alt='" + tStatus + "'>");
		out.println("</td>");
		
		// weight
		if (bResourceMgmt) {
			Double d = (Double)t.getAttribute(optAttr)[0];
			out.print("<td colspan='2'></td>");
			out.print("<td><input class='listtext' name='Wt_" + taskId + "' size='3' value='");
			out.print(dcf.format(d) + "' onChange='checkInt(\"Wt\", " + taskId + ")'" + userEdit + "></td>");
		}

		// owner
		out.print("<td colspan='2'></td><td>");
		out.print("<select class='formtext' name='Owner_" + taskId + "' ");
		out.print("' onChange='checkUpdate(GroupUpdate.update_" + taskId + ")'" + userEdit + ">");
		for(int a=0; a < teamMember.length; a++)
		{
			String firstEmpName = (String)teamMember[a].getAttribute("FirstName")[0];
			String lastEmpName = (String)teamMember[a].getAttribute("LastName")[0];
			if (lastEmpName == null) lastEmpName = " ";
			id = teamMember[a].getObjectId();

			out.print("<option value=" + id);
			if (ownerIdS!=null && ownerId==id)
				out.print(" selected");

			out.print(">" + firstEmpName + " " + lastEmpName.charAt(0) + "</option>");
		}
		out.print("</select></td>");

		// dependency
		out.print("<td colspan='2'></td>");
		out.print("<td><input class='listtext' type='text' name='Depend_" + taskId + "' size='10' value='");
		out.print(depString + "' onChange='checkUpdate(GroupUpdate.update_" + taskId + ")'" + userEdit + "></td>");

		// gap @ECC112405
		out.print("<td colspan='2'></td>");
		out.print("<td><input class='listtext' type='text' name='Gap_" + taskId + "' size='3' value='");
		out.print(gap + "' onChange='checkInt(\"Gap\", " + taskId + ")'" + userEdit + "></td>");

		// duration @ECC112405
		out.print("<td colspan='2'></td>");
		out.print("<td><input class='listtext' type='text' name='Dur_" + taskId + "' size='3' value='");
		out.print(dur + "' onChange='checkInt(\"Dur\", " + taskId + ")'" + userEdit + "></td>");

		// original start date
		out.print("<td colspan='2'><img src='../i/dot_orange.gif' width='7'/></td>");
		out.print("<td><input class='listtext' type='text' name='OriStart_" + taskId + "' size='8' value='");
		if (oriStartD != null) out.print(df.format(oriStartD));
		out.print("' onChange='checkUpdate(GroupUpdate.update_" + taskId + ")'" + oriUserEdit + "></td>");

		// original expire date
		out.print("<td colspan='2'></td>");
		out.print("<td><input class='listtext' type='text' name='OriExpire_" + taskId + "' size='8' value='");
		if (oriExpireD != null) out.print(df.format(oriExpireD));
		out.print("' onChange='checkUpdate(GroupUpdate.update_" + taskId + ")'" + oriUserEdit + "></td>");

		// planned start date
		if (gap.length() > 0)
			planDtUpdate = " disabled";
		else
			planDtUpdate = userEdit;

		out.print("<td colspan='2'><img src='../i/dot_blue.gif' width='7'/></td>");
		out.print("<td><input class='listtext' type='text' name='Start_" + taskId + "' size='8' value='");
		if (startD != null) out.print(df.format(startD));
		out.print("' onChange='checkUpdate(GroupUpdate.update_" + taskId + ")'" + planDtUpdate + "></td>");

		// planned expire date (deadline)
		if (dur.length() > 0)
			planDtUpdate = " disabled";
		else
			planDtUpdate = userEdit;

		out.print("<td colspan='2'></td>");
		out.print("<td><input class='listtext' type='text' name='Expire_" + taskId + "' size='8' value='");
		if (expireD != null) out.print(phase.parseDateToString(expireD, format));//df.format(expireD));
		out.print("' onChange='checkUpdate(GroupUpdate.update_" + taskId + ")'" + planDtUpdate + "></td>");

		// actual start date
		out.print("<td colspan='2'><img src='../i/dot_green.gif' width='7'/></td>");
		out.print("<td><input class='listtext' type='text' name='Actual_" + taskId + "' size='8' value='");
		if (actualD != null) out.print(df.format(actualD));
		out.print("' onChange='checkUpdate(GroupUpdate.update_" + taskId + ")'" + userEdit + "></td>");

		// actual finish date
		out.print("<td colspan='2'></td>");
		out.print("<td><input class='listtext' type='text' name='Finish_" + taskId + "' size='8' value='");
		if (completeD != null) out.print(phase.parseDateToString(completeD, format));//df.format(completeD));
		out.print("' onChange='checkUpdate(GroupUpdate.update_" + taskId + ")'" + userEdit + "></td>");

		// update columns
		out.print("<td colspan='3'></td>");

		out.println("</tr>");
		
		// postBlog window
		out.print("<tr " + bgcolor + "><td colspan='5'></td><td colspan='40'>"
				+ "<div id='blogDiv_" + taskId + "' style='display:none;'>"
				+ "<table><tr><td class='plaintext'>"
				+ "Enter blog for this task and click SAVE</td>"
				+ "<td align='right'><img src='../i/bullet_tri.gif'>"
						+ "<a href='../blog/blog_task.jsp?projId=" + projIdS
						+ "&taskId=" + taskId + "'>Go to blog</a>&nbsp;</td></tr>"
				+ "<tr><td colspan='2'><textarea class='plaintext' cols='80' rows='5' name='blogEdit_"
						+ taskId + "' id='blogEdit_" + taskId + "'>"
				+ "</textarea></td></tr>"
				+ "<tr><td colspan='2' class='plaintext'><input type='checkbox' id='sendEmail_" + taskId + "' value='true' "
						+ checkStr + "/>&nbsp;Send Email notification to team members</td></tr>"
				+ "<tr><td colspan='2' align='center'>"
				+ "<input type='button' class='button_medium' value=' Save ' onClick='saveBlog();' />&nbsp;&nbsp;"
				+ "<input type='button' class='button_medium' value='Cancel' onClick='postBlog(0);' />"
				+ "</td></tr></table>"
				+ "</div></td></tr>");

		lastlevelInfo = levelInfo[level-1];
	}
	
	// clear the dirty map after display
	dirtyMap.clear();

%>
<!-- append at the end -->

		<tr height='5'><td colspan='20'><img src='../i/spacer.gif' width='2' height='5' border='0'></td></tr>
		</table>

		<table border="0" cellspacing="0" cellpadding="0">
			<tr><td colspan="3" height="10"><img src="../i/spacer.gif" height="10" width="1" alt=" " /></td></tr>
			<tr>
			<td height="23">
				<input type='button' class='button_medium' value='Submit' onClick='this.disabled=true;document.GroupUpdate.submit();'>&nbsp;&nbsp;
			</td>
			<td height="23">
<%			if (!isCRAPP){
				out.print("<input type='button' class='button_medium' value='Cancel' onClick='location=\"proj_plan.jsp?projId=" + projIdS + "\"'>");
			}
			else {
				out.print("<input type='button' class='button_medium' value='Cancel' onClick='location=\"cr.jsp?projId=" + projIdS + "\"'>");
			}
%>
			</td>
			</tr>
		</table>
	</td>
	</tr>
	<tr><td colspan="2">&nbsp;</td></tr>

<table>
	<tr>
		<td width="10">&nbsp;</td>
		<td class="tinytype" align="center">Task Status:
			&nbsp;&nbsp;<img src="../i/dot_orange.gif" border="0">New
			&nbsp;&nbsp;<img src="../i/dot_lightblue.gif" border="0">Open
			&nbsp;&nbsp;<img src="../i/dot_green.gif" border="0">Completed
			&nbsp;&nbsp;<img src="../i/dot_red.gif" border="0">Late
			&nbsp;&nbsp;<img src="../i/dot_grey.gif" border="0">On-hold
			&nbsp;&nbsp;<img src="../i/dot_cancel.gif" border="0">Canceled
			&nbsp;&nbsp;<img src="../i/dot_redw.gif" border="0">Updated
		</td>
	</tr>
</table>

	</form>
	</table>


<!-- ************************************************ -->

	</td>
</tr>

<tr><td>&nbsp;</td><tr>


<!-- BEGIN FOOTER TABLE -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

