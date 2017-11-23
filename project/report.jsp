<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2011, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: report.jsp
//	Author: ECC
//	Date:	02/14/11
//	Description: A snapshot page to show overall info of selected projects.
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.codegen.phase.PhaseInfo" %>
<%@ page import = "oct.omm.common.*" %>
<%@ page import = "oct.omm.client.*" %>
<%@ page import = "oct.omm.db.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>
<%@ page import = "org.apache.log4j.Logger" %>

<%
	String projIdS = request.getParameter("projId");	// just highlight this project
	String noSession = "../out.jsp?go=project/report.jsp?projId="+projIdS;
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	////////////////////////////////////////////////////////
	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	Logger l = PrmLog.getLog();
	
	String browserType = request.getHeader("User-Agent");
	browserType = browserType.toLowerCase();
	boolean isIE = (browserType!=null && browserType.contains("msie"));

	projectManager pjMgr = projectManager.getInstance();
	taskManager tkMgr = taskManager.getInstance();
	userManager uMgr = userManager.getInstance();
	attachmentManager attMgr = attachmentManager.getInstance();
	resultManager rMgr = resultManager.getInstance();
	meetingManager mMgr = meetingManager.getInstance();
	townManager tnMgr = townManager.getInstance();
	
	SimpleDateFormat df0 = new SimpleDateFormat ("MM/dd/yy");

	String s;

	int myUid = pstuser.getObjectId();
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	boolean isAdmin = ((iRole & user.iROLE_ADMIN)>0);

	// to check if session is CR or PRM
	boolean isCRAPP = Prm.isCR();
	boolean isMeetWE = Prm.isMeetWE();
	boolean isPRMAPP = Prm.isPRM();
	
	// from the project get the company (town)
	if (StringUtil.isNullOrEmptyString(projIdS)) {
		projIdS = (String) session.getAttribute("projId");
	}
	project selectedPj = (project) pjMgr.get(pstuser, Integer.parseInt(projIdS));
	s = selectedPj.getStringAttribute("TownID");
	town townObj = (town) tnMgr.get(pstuser, Integer.parseInt(s));

	// filter
	boolean isShowFilter = false;
	String filterImage, filterText;
	if (!isShowFilter) {
		filterImage = "bullet_tri.gif";
		filterText = "Show Filter";
	}
	else {
		filterImage = "tri_dn.gif";
		filterText = "Hide Filter";
	}
	
	// filter by project owner
	String exec = "";
	String selectedOwner = request.getParameter("ow");
	if (!StringUtil.isNullOrEmptyString(selectedOwner)) {
		exec = "Owner='" + selectedOwner + "'";
	}
	else {
		selectedOwner = "0";
	}
	
	// filter by team member
	String selectedMember = request.getParameter("tm");
	if (!StringUtil.isNullOrEmptyString(selectedMember)) {
		if (exec != "") exec += " && ";
		exec += "TeamMembers=" + selectedMember;
	}
	else {
		selectedMember = "0";
	}
	
	// filter by status
	int ct = 0;
	String [] stArr = {project.ST_NEW, project.ST_OPEN, project.ST_COMPLETE, project.ST_LATE};
	String temp = "";
	String selectedProjStatus = "";
	for (String st : stArr) {
		s = request.getParameter(st);
		if (!StringUtil.isNullOrEmptyString(s)) {
			selectedProjStatus += st + ";";		// for comparison later to check mark choices
			if (temp != "") temp += " || ";
			temp += "Status='" + st + "'";
			ct++;
		}
	}
	if (temp!="" && ct<stArr.length) {
		if (exec != "") exec += " && ";
		exec += "(" + temp + ")";
	}
	
	
	// filter by category
	s = townObj.getStringAttribute("Category");
	String [] catArr = StringUtil.toStringArray(s, "::");
	String selectedCategory = "";
	if (catArr.length > 0) {
		ct = 0;
		temp = "";
		for (int i=0; i<catArr.length; i++) {
			s = request.getParameter("cat" + i);
			if (!StringUtil.isNullOrEmptyString(s)) {
				selectedCategory += catArr[i] + ";";		// for comparison later to check mark choices
				if (temp != "") temp += " || ";
				temp += "Category='" + catArr[i] + "'";
				ct++;
			}
		}
		if (temp!="" && ct<catArr.length) {
			if (exec != "") exec += " && ";
			exec += "(" + temp + ")";
		}
	}
	
	boolean bShowFilter = (exec!="");
	System.out.println(exec);
	
	// sortby
	String sortby = request.getParameter("sortby");
	if (sortby == null) sortby = "pn";		// default to project name

%>


<head>
<title><%=Prm.getAppTitle()%> Review Projects</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<link href="../plan/x.css" rel="stylesheet" type="text/css" media="screen">
<script type='text/javascript' src='../plan/x_core.js'></script>
<script type='text/javascript' src='../plan/x_event.js'></script>
<script type='text/javascript' src='../plan/x_drag.js'></script>
<jsp:include page="../init.jsp" flush="true"/>

<script language="JavaScript">
<!--

window.onload = function()
{
	if (<%=bShowFilter%>) {
		toggleFilter();
	}
}

function toggleFilter()
{
	var eDiv = document.getElementById("FilterDIV");
	var eA = document.getElementById("ToggleFilterA");
	var eImg = document.getElementById("ToggleFilterIMG");
	if (eA.innerHTML == "Show Filter") {
		eA.innerHTML = "Hide Filter";
		eImg.src = "../i/tri_dn.gif";
		eDiv.style.display = "block";
	}
	else {
		eA.innerHTML = "Show Filter";
		eImg.src = "../i/bullet_tri.gif";
		eDiv.style.display = "none";
	}
}

function toggleInfo(pid)
{
	var eDiv = document.getElementById("DIV_" + pid);
	var eA = document.getElementById("A_" + pid);
	var eImg = document.getElementById("Img_" + pid);
	if (eA.innerHTML == "Show more info") {
		eA.innerHTML = "Hide info";
		eImg.src = "../i/tri_dn.gif";
		eDiv.style.display = "block";
	}
	else {
		eA.innerHTML = "Show more info";
		eImg.src = "../i/bullet_tri.gif";
		eDiv.style.display = "none";
	}
}

function sort(type)
{
	// sort by type
	var fullURL = parent.document.URL;
	var opt = "sortby=" + type;
	var loc = addURLOption(fullURL, opt);
	location = loc;
}
//-->
</script>

<style type="text/css">
TABLE.taskDesc TD {
	font-family: "Lucida Sans Unicode", "Bitstream Vera Sans", "Trebuchet Unicode MS", "Lucida Grande", Verdana, Arial, Helvetica, sans-serif;
	font-size: 12px;
	font-color: #333;
	}
#val {width:60px; text-align: right;}
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
					<td width="26" height="30"><a name="top">&nbsp;</a></td>
					<td height="30" valign='middle' align="left" class="head">
						<b>Review Projects</b>
					</td>
				<td class='message' align='left'>
				</td>
					<td width="245">
					<table width='100%' border='0' cellspacing='0' cellpadding='0'>
						<tr><td>

						</td>
						<td align='right' valign='bottom' >
							<%out.print(Util4.showHelp("step3", "Click for help in project management")); %>
						</td>
						</tr>
					</table>
					</td>

					</tr>
	            </table>
	          	</td>
	        </tr>
</table>
	        
<table width='90%' border="0" cellspacing="0" cellpadding="0">
<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>

			<tr>
          		<td width="100%">
<!-- Navigation Menu -->
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Project" />
				<jsp:param name="subCat" value="ProjectReport" />
				<jsp:param name="role" value="<%=iRole%>" />
				<jsp:param name="projId" value="<%=projIdS%>" />
			</jsp:include>
<!-- End of Navigation SUB-Menu -->
				</td>
	        </tr>
		</table>


<!-- Content Table -->

 <table width="90%" border="0" cellspacing="0" cellpadding="0">
	
<!-- Filter -->
	<tr>
		<td width='26'><img src='../i/spacer.gif' width='26' border='0'/></td>
		<td>
			<img id='ToggleFilterIMG' src='../i/<%=filterImage%>' border='0'>
			<a id='ToggleFilterA' class='listlinkbold' href='javascript:toggleFilter();'><%=filterText%></a>
		</td>
	</tr>
	
	<tr>
		<td></td>
		<td>
<div id='FilterDIV' <%if (!isShowFilter) {out.print("style='display:none;'");} %>>
<form name='FilterForm'>
	<table width='100%'>

<!-- Project Category -->
<%
		if (catArr.length > 0) {
			out.print("<tr>");
			out.print("<td width='12'><img src='../i/spacer.gif' width='12'/></td>");
			out.print("<td width='200' valign='top' class='plaintext_blue'>Project Category</td>");
			out.print("<td><table border='0' cellspacing='0' cellpadding='0'>");
			String cat;
			for (int i=0; i<catArr.length; i++) {
				cat = catArr[i];
				if (i%4==0) out.print("<tr>");
				out.print("<td class='formtext' width='150'>");
				out.print("<input class='formtext' type='checkbox' name='cat" + i + "'");
				if (selectedCategory=="" || selectedCategory.contains(cat)) out.print(" checked");
				out.print(">" + cat + "</input></td>");
				if ((i+1)%4==0 || i==catArr.length-1) out.print("</tr>");
			}
			out.print("</table></td></tr>");
			out.print("<tr><td><img src='../i/spacer.gif' height='5'/></td></tr>");
		}
%>	

<!-- Project Coordinator -->
<tr>
	<td width='12'><img src='../i/spacer.gif' width='12'/></td>
	<td width='200' valign="top" class="plaintext_blue">Project Coordinator</td>
	<td class='formtext'>
		<select name='ow' class='formtext' style='width:200px;'>
		<option value=''>- select coordinator name -</option>
<%
		int id = Integer.parseInt(selectedOwner);
		String myCompany = pstuser.getStringAttribute("Company");
		int [] ids;
		ids = uMgr.findId(pstuser, "Company='" + myCompany + "'");
		PstAbstractObject [] oArr = uMgr.get(pstuser, ids);
		Util.sortUserArray(oArr, true);
		for (PstAbstractObject o : oArr) {
			user u = (user) o;
			out.print("<option value='" + u.getObjectId() + "'");
			if (id == u.getObjectId()) out.print(" selected");
			out.print(">" + u.getFullName() + "</option>");
		}
%>
		</select>
	</td>
</tr>

<tr><td><img src='../i/spacer.gif' height='5'/></td></tr>

<!-- Team Member -->
<tr>
	<td></td>
	<td valign="top" class="plaintext_blue">Team Member</td>
	<td class='formtext'>
		<select name='tm' class='formtext' style='width:200px;'>
		<option value=''>- select team member -</option>
<%
		id = Integer.parseInt(selectedMember);
		for (PstAbstractObject o : oArr) {
			user u = (user) o;
			out.print("<option value='" + u.getObjectId() + "'");
			if (id == u.getObjectId()) out.print(" selected");
			out.print(">" + u.getFullName() + "</option>");
		}
%>
		</select>
	</td>
</tr>

<tr><td><img src='../i/spacer.gif' height='5'/></td></tr>

<!-- Project Status -->
<tr>
	<td width='12'><img src='../i/spacer.gif' width='12'/></td>
	<td width='200' valign="top" class="plaintext_blue">Project Status</td>
	<td class='formtext'>
		<table border='0' cellspacing='0' cellpadding='0'>
		<tr>
<%
		for (String st : stArr) {
			out.print("<td class='formtext' width='150'>");
			out.print("<input type='checkbox' name='" + st + "'");
			if (selectedProjStatus=="" || selectedProjStatus.contains(st)) out.print(" checked");
			out.print(">" + st + "</input></td>");
		}
 %>
		</tr>
		</table>
	</td>
</tr>

<!-- Buttons -->
<tr>
	<td></td>
	<td colspan='2'>
		<img src='../i/spacer.gif' width='200' height='30'/>
		<input type='submit' class='button_medium' value='Submit'></input>
		<img src='../i/spacer.gif' width='20'/>
		<input type='button' class='button_medium' value='Cancel' onclick='toggleFilter();' />
	</td>
</tr>

	</table>
</form>
</div>
		</td>
	</tr>
	
	
<!-- Main content -->
	<tr>
		<td></td>
		<td>

<table width="100%" border="0" cellspacing="0" cellpadding="0">

<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>

<%

	out.print("<tr><td valign='top'>");

	// get the project list
	if (StringUtil.isNullOrEmptyString(exec)) {
		ids = pjMgr.getProjects(pstuser, false);
	}
	else {
		ids = pjMgr.findId(pstuser, exec);
	}
	
	// sort
	String [] sortStatusArr = {project.ST_LATE, project.ST_OPEN, project.ST_NEW, project.ST_COMPLETE,
							   project.ST_ONHOLD, project.ST_CANCEL, project.ST_CLOSE};
	PstAbstractObject [] pjArr = pjMgr.get(pstuser, ids);
	if (sortby.equals("ca")) {
		// category
		Util.sortString(pjArr, "Category", true);
	}
	else if (sortby.equals("co")) {
		// coordinator
		Util.sortIndirectUserName(pstuser, uMgr, pjArr, "Owner");
	}
	else if (sortby.equals("st")) {
		// start date
		Util.sortDate(pjArr, "StartDate", true);		// latest date first
	}
	else if (sortby.equals("du")) {
		// start date
		Util.sortDate(pjArr, "ExpireDate", true);		// latest date first
	}
	else if (sortby.equals("do")) {
		// start date
		Util.sortDate(pjArr, "CompleteDate", true);		// latest date first
	}
	else if (sortby.equals("ss")) {
		// status
		Util.sortWithValues(pjArr, "Status", sortStatusArr);
	}
	else {
		// default project name
		Util.sortName(pjArr, true);		// ignore case
	}

	// label
	String [] label0 = {"Rank", "&nbsp;Project Name", "Category", "Coordinator", "Start", "Due", "Done", "Status"};
	int [] labelLen0 = {-5, 44, 16, 12, 7, 7, 7, 2};
	boolean [] bAlignCenter0 = {false, false, false, true, true, true, true, true};
	String [] sortArr = {null, "pn", "ca", "co", "st", "du", "do", "ss"};
	out.print(Util.showLabel(label0, null, sortArr, sortby,
		labelLen0, bAlignCenter0, true));	// sort, showAll and align center
	
	int colSpanNum = label0.length * 3 - 1;
	
	// list projects
	String bgcolor="";
	boolean even = false;
	project pj;
	String projDisplayName, ownerIdS, ownerName, startDtS, expireDtS, doneDtS, status, category;
	Date startDt, expireDt, doneDt, effectiveDt;
	user u;
	int pjCt = 1;						// should use a db value
	int pid;
	
	for (int i=0; i<pjArr.length; i++) {
		pj = (project)pjArr[i];
		pid = pj.getObjectId();

		// only for time-tracking project
		if (pj.isContainer()) continue;
		
		// get project attributes
		projDisplayName = pj.getDisplayName();
		ownerIdS = pj.getStringAttribute("Owner");
		try {
			u = (user) uMgr.get(pstuser, Integer.parseInt(ownerIdS));
			ownerName = u.getFullName();
		}
		catch (PmpException e) {ownerName = "-";}

		// ECC: the following block can be modularized
		startDt = pj.getStartDate();
		expireDt = pj.getExpireDate();
		doneDt = pj.getCompleteDate();
		effectiveDt = pj.getEffectiveDate();

		//if (effectiveDt != null) startDtS = df0.format(effectiveDt);
		if (startDt != null) startDtS = df0.format(startDt);		// it won't be null for time-tracking project
		else startDtS = "-";

		if (expireDt != null) expireDtS = df0.format(expireDt);
		else expireDtS = "-";

		if (doneDt != null) doneDtS = df0.format(doneDt);
		else doneDtS = "-";

		status = pj.getStringAttribute("Status");
		
		category = pj.getStringAttribute("Category");
		if (category == null) category = "-";
		
		//////////////////////////////////////////
		// start the project mainline listing
		if (even) bgcolor = Prm.DARK;
		else bgcolor = Prm.LIGHT;
		even = !even;
		out.print("<tr " + bgcolor + ">");
		
		// ranking
		out.print("<td height='25'></td>");		// give each line more space
		out.print("<td class='plaintext' align='center'>");
		out.print(pjCt++ + "</td>");
		
		// project name
		out.print("<td colspan='2'></td>");
		out.print("<td class='ptextS1'>");
		out.print("<a href='../project/proj_summary.jsp?projId=" + pid + "'>");
		out.print(projDisplayName + "</a></td>");
		
		// category
		out.print("<td colspan='2'></td>");
		out.print("<td class='plaintext'>" + category + "</td>");

		// owner
		out.print("<td colspan='2'></td>");
		out.print("<td class='plaintext' align='center'><a href='../ep/ep1.jsp?uid=" + ownerIdS + "'>"
				+ ownerName + "</a></td>");

		// start date
		out.print("<td colspan='2'></td>");
		out.print("<td class='plaintext' align='center'>" + startDtS + "</td>");

		// due date
		out.print("<td colspan='2'></td>");
		out.print("<td class='plaintext' align='center'>" + expireDtS + "</td>");

		// done date
		out.print("<td colspan='2'></td>");
		out.print("<td class='plaintext' align='center'>" + doneDtS + "</td>");

		// status
		out.println("<td colspan='2'></td>");
		out.print("<td class='plaintext' align='center'>");
		out.print(pj.getStatusDisplay(pstuser, false));
		out.print("</td>");
		out.println("</tr>");
		
		out.print("<tr " + bgcolor + "><td colspan='" + colSpanNum + "'><img src='../i/spacer.gif' height='5'/></td></tr>");

		//////////////////////////////////////////
		// percentage time bar
		out.print("<tr " + bgcolor + ">");
		out.print("<td colspan='" + colSpanNum + "'>");
		out.print("<table border='0' cellspacing='0' cellpadding='0'>");
		out.print("<tr><td>");
		out.print(Util4.showProjectPercentageBar(pj));
		out.print("</td>");
		out.print("<td width='200' class='plaintext'>");
		out.print("<img id='Img_" + pid + "' src='../i/bullet_tri.gif'/>");
		out.print("<a id='A_" + pid + "' href='javascript:toggleInfo(" + pid + ");'>Show more info</a>");
		out.print("</td></tr></table>");
		out.println("</td></tr>");
		
		out.print("<tr " + bgcolor + "><td colspan='" + colSpanNum + "'><img src='../i/spacer.gif' height='10'/></td></tr>");

		out.print("<tr " + bgcolor + ">");
		out.print("<td colspan='" + colSpanNum + "'>");
		
		// bottom table include left and right panel
		out.print("<DIV id='DIV_" + pid + "' style='display:none;'>");	// DIV to hide/show panel
		out.print("<table width='100%'><tr>");	// bottom table
		
		//////////////////////////////////////////
		// LEFT: overall project status
		out.print("<td width='50%' valign='top'>");
		out.print("<table class='taskDesc' width='100%'>");	// Table A1
		out.print("<tr><td><img src='../i/spacer.gif' width='70' height='1'/></td>");
		out.print("<td><table>");	// Table A2
		out.print("<tr><td colspan='2' class='listlinkbold'>Total No. of</td></tr>");
		ct = pj.getAttribute("TeamMembers").length;
		out.print("<tr><td width='150'>Team members</td><td id='val'>" + ct + "</td></tr>");
		ct = attMgr.findId(pstuser, "ProjectID='" + pid + "' && Type='" + attachment.TYPE_TASK + "'").length;
		out.print("<tr><td width='150'>Files</td><td id='val'>" + ct + "</td></tr>");
		ct = mMgr.findId(pstuser, "ProjectID='" + pid + "'").length;
		out.print("<tr><td width='150'>Meetings</td><td id='val'>" + ct + "</td></tr>");
		ct = rMgr.findId(pstuser, "ProjectID='" + pid + "' && Type='" + result.TYPE_TASK_BLOG + "' && ParentID=null").length;
		out.print("<tr><td width='150'>Blogs</td><td id='val'>" + ct + "</td></tr>");
		int totalTasks = pj.getCurrentTasks(pstuser).length;	// tkMgr.findId(pstuser, "ProjectID='"+pid+"'").length;
		out.print("<tr><td width='150'>Tasks</td><td id='val'>" + totalTasks + "</td></tr>");
		out.print("</table></td>");	// Table A2 end
		out.print("</tr></table>");	// Table A1 end
		out.print("</td>");
		
		//////////////////////////////////////////
		// RIGHT: task status
		int newct = tkMgr.findId(pstuser, "ProjectID='"+pid+"' && Status='New'").length;
		int open = tkMgr.findId(pstuser, "ProjectID='"+pid+"' && Status='Open'").length;
		int completed = tkMgr.findId(pstuser, "ProjectID='"+pid+"' && Status='Completed'").length;
		int late = tkMgr.findId(pstuser, "ProjectID='"+pid+"' && Status='Late'").length;
		int onhold = tkMgr.findId(pstuser, "ProjectID='"+pid+"' && Status='On-hold'").length;
		int canceled = tkMgr.findId(pstuser, "ProjectID='"+pid+"' && Status='Canceled'").length;

		out.print("<td width='50%' valign='top'>");
		out.print("<table class='taskDesc' width='100%'>");	// Table B1
		out.print("<tr><td><img src='../i/spacer.gif' width='70' height='1'/></td>");
		out.print("<td><table>");	// Table B2
		out.print("<tr><td colspan='2' class='listlinkbold'>Task Statistics</td></tr>");
		out.print("<tr><td width='150'>New</td><td id='val'>" + newct + "</td><td id='val'>"
				+ (int)Math.round(newct*100.0/totalTasks) + "%</td></tr>");
		out.print("<tr><td>Open</td><td id='val'>" + open + "</td><td id='val'>"
				+ (int)Math.round(open*100.0/totalTasks) + "%</td></tr>");
		out.print("<tr><td>Completed</td><td id='val'>" + completed + "</td><td id='val'>"
				+ (int)Math.round(completed*100.0/totalTasks) + "%</td></tr>");
		out.print("<tr><td>Late:</td><td id='val'>" + late + "</td><td id='val'>"
				+ (int)Math.round(late*100.0/totalTasks) + "%</td></tr>");
		out.print("<tr><td>On-hold</td><td id='val'>" + onhold + "</td><td id='val'>"
				+ (int)Math.round(onhold*100.0/totalTasks) + "%</td></tr>");
		out.print("<tr><td>Canceled</td><td id='val'>" + canceled + "</td><td id='val'>"
				+ (int)Math.round(canceled*100.0/totalTasks) + "%</td></tr>");
		out.print("</table></td>");	// Table B2 end
		out.print("</tr></table>");	// Table B1 end
		out.print("</td>");
		
		out.print("</tr></table>");		// bottom table
		out.print("</DIV>");			// hide/show panel
		
		out.println("</td></tr>");
		
		out.print("<tr " + bgcolor + "><td colspan='" + colSpanNum + "'><img src='../i/spacer.gif' height='10'/></td></tr>");
	}
	
	out.println("</td></tr>");
	
%>

</table>
<!-- End Main content -->

</td>
</tr>
</table>

</td>
</tr>

<!-- Footer -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- End of Footer -->
</table>

</body>
</html>
