<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
////////////////////////////////////////////////////
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	proj_profile.jsp
//	Author:	ECC
//	Date:	03/18/04
//	Description:
//		Display the project profile.
//	Modification:
//		@ECC063005	Add project options.  Enable member update plan.
//		@ECC092405	Handle special characters in uploading and downloading file names.
//		@ECC120305	Recalculate optimal deadline for the entire project tree.
//		@AGQ040306	Added support for multifile upload
//		@AGQ042006	Support of Status Report Attachments
//		@SWS061406	Updated file listing.
//		@ECC112117	Added FirstPage attribute. Can take toppage or blogpage.
//
////////////////////////////////////////////////////////////////////
%>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	//double SUMMARY_COST = 0.25;
	//double UPLOAD_COST  = 0.25;
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");	

	String projIdS = request.getParameter("projId");
	if ((pstuser instanceof PstGuest))
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}

	if (projIdS==null || projIdS.equals("session"))
		projIdS = (String)session.getAttribute("projId");
	else
		session.setAttribute("projId", projIdS);

	if (projIdS == null || projIdS.equals("null"))
	{
		response.sendRedirect("proj_select.jsp?backPage=proj_profile.jsp");
		return;
	}
	
	String locale = (String) session.getAttribute("locale");

	String host = Prm.getPrmHost();

	String backPage = "../project/proj_profile.jsp?projId=" + projIdS;
	String s;

	int iRole = ((Integer)session.getAttribute("role")).intValue();
	boolean isAdmin = ((iRole & user.iROLE_ADMIN) > 0);
	boolean isProgMgr = ((iRole & user.iROLE_PROGMGR) > 0);
	boolean isGuestRole = ((iRole & user.iROLE_GUEST) > 0);

	// to check if session is CR or PRM
	boolean isCRAPP = Prm.isCR();
	boolean isMeetWE = Prm.isMeetWE();
	boolean isPRM = Prm.isPRM();

	// @ECC080108 Multiple company
	boolean isMultiCorp = Prm.isMultiCorp();

	// @ECC081407 Blog Module
	boolean isBlogModule = Prm.isBlogModule();

	SimpleDateFormat df1 = new SimpleDateFormat ("MM/dd/yyyy");

	projectManager pjMgr	= projectManager.getInstance();
	attachmentManager aMgr	= attachmentManager.getInstance();
	taskManager tkMgr		= taskManager.getInstance();
	planTaskManager ptMgr	= planTaskManager.getInstance();
	phaseManager phMgr		= phaseManager.getInstance();

	int pid = Integer.parseInt(projIdS);
	project proj = (project)pjMgr.get(pstuser, pid);
	String projName = proj.getDisplayName();
	String tidS = (String)proj.getAttribute("Company")[0];

	PstUserAbstractObject owner;

	// @ECC120305 Optimize project schedule
	s = request.getParameter("optimize");
	if (s!=null && s.equals("true"))
	{
		proj.optimizeSchedule(pstuser);
		proj = (project)pjMgr.get(pstuser, pid);	// need to refresh the cache after the call
		session.removeAttribute("planStack");		// cleanup cache
	}

	int myUid = pstuser.getObjectId();
	String coordinatorIdS = (String)proj.getAttribute("Owner")[0];
	int coordinatorId = Integer.parseInt(coordinatorIdS);
	boolean isCoordinator = (myUid == coordinatorId);

	userManager uMgr = userManager.getInstance();
	user aUser = null;
	String lname, uname, coordinator;
	try {
		aUser = (user)uMgr.get(pstuser, coordinatorId);
		coordinator = aUser.getObjectName();
		lname = (String)aUser.getAttribute("LastName")[0];
		uname = aUser.getFullName();
	}
	catch (Exception e) {
		uname = "* user deleted *";
		coordinator = null;
	}

	// allow coordinator's manager to update project profile - only ADMIN can delete project
	boolean isOwnerManager = false;
	if (aUser != null) {
		s = (String)aUser.getAttribute("Supervisor1")[0];
		if (s!=null && Integer.parseInt(s)==myUid)
			isOwnerManager = true;
	}

	// allow update project?
	String CLOSE_A_TAG = "";
	boolean isUpdateOk = false;
	if (isCoordinator || isAdmin || isProgMgr)
	{
		isUpdateOk = true;
		CLOSE_A_TAG = "</a>";
	}
	
	Date expireDt = (Date)proj.getAttribute("ExpireDate")[0];

	String status = (String)proj.getAttribute("Status")[0];
	String color = null;
	if (proj.isContainer()) {status = "Container project"; color = "#333333";}
	else if (status.equals("Open")) {color = "#2222aa";}
	else if (status.equals("New")) {color = "#cc7700";}
	else if (status.equals("Completed")) {color = "#22aa22";}
	else if (status.equals("Late")) {color = "#ff2222";}
	else if (status.equals("On-hold")) {color = "#777777";}
	else {color = "#333333";}

	String type = (String)proj.getAttribute("Type")[0];
	if (type == null) type = "Private";

	String startDate, createdDate, deadline, completeDate;
	Date dt = (Date)proj.getAttribute("StartDate")[0];
	if (dt != null)
		startDate = df1.format(dt);
	else
		startDate = "Not specified";

	dt = (Date)proj.getAttribute("CreatedDate")[0];
	if (dt != null)
		createdDate = df1.format(dt);
	else
		createdDate = "";

	if (expireDt != null)
		deadline = df1.format(expireDt);
	else
		deadline = "-";

	Date complete = (Date)proj.getAttribute("CompleteDate")[0];
	if (complete != null)
		completeDate = df1.format(complete);
	else
		completeDate = "Not yet completed";

	// get team members
	PstAbstractObject [] memberList = null;
	try {memberList = ((user)pstuser).getTeamMembers(pid);}
	catch (Exception e) {memberList = new PstAbstractObject[0];}
	
	int totalTeamMember = memberList.length;

	Object dObj = proj.getAttribute("Description")[0];
	String Desc = (dObj==null)?"Not specified":new String((byte[])dObj, "utf-8");

	// @ECC063005
	String optStr = (String)proj.getAttribute("Option")[0];
	if (optStr == null) optStr = "";
	
	String projAbbrev = proj.getOption(project.ABBREVIATION);
	if (projAbbrev == null) projAbbrev = "<span class='plaintext_big_grey'>None</span>";
	
	// Project Top page
	String topPageS = "Project Top";
	String topPage = proj.getStringAttribute("FirstPage");
	if (topPage!=null && topPage.equalsIgnoreCase("blogpage")) topPage = "Project Blog";
	
%>

<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8"/>
<script src="../multifile.js"></script>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>

<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../forms.jsp" flush="true"/>
<jsp:include page="../file_action.jsp" flush="true"/>
<script language="JavaScript" src="../ep/event.js"></script>
<script language="JavaScript" src="../ep/chat.js"></script>

<script language="JavaScript">
<!--
var uid = "<%=myUid%>";
frame = "parent";			// define in event.js
isCPM = <%=isPRM%>;			// define in event.js

function affirm_summary(loc)
{
		location = loc;
}

function optimize_schedule()
{
	var msg  = "Optimize the schedule may cause the task and project schedule to change.\n";
	    msg += "You should only perform this operation if you are sure that all your\n";
	    msg += "task Durations and Gaps are set up already.  Do you really want to proceed?\n\n";
		msg += "   OK = Yes\n";
		msg += "   CANCEL = No";
	if (confirm(msg))
		location = "proj_profile.jsp?projId=<%=projIdS%>&&optimize=true";
}

function fixElement(e, msg)
{
	alert(msg);
// @AGQ040306
	if (e)
		e.focus();
}

function setAddFile()
{
// @AGQ040306
	if (multi_selector.count == 1)
	{
		fixElement(document.getElementById("my_file_element"), "To add a file attachment, click the Browse button and choose a file to be attached, then click the Add button.");
		return false;
	}
	if (!validation())
		return false;

	return true;
}

function validation()
{
// @AGQ040306
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
	if(!isFileName)
		return isFileName;

	// @AGQ040406
	if(!findDuplicateFileName(forminputs))
		return false;

	return true;
}

function share()
{
/*
	if (<%=isMultiCorp%>==false)
	{
		location = "proj_update.jsp?projId=<%=projIdS%>";
		return;
	}
*/
	var e = document.getElementById("shareEmail");

	if (e.style.display == "none")
	{
		e.style.display = "block";
		addMember.shareMember.focus();
		var h = e.clientHeight;
		h = document.body.clientHeight + h;
		var px = "";
		if(navigator.userAgent.indexOf("Firefox") != -1) px = "px";
		document.body.style.height = h;
	}
	else
	{
		e.style.display = "none";
		addMember.shareMember.value = "";
	}

	e = document.getElementById("msg");
	if (e != null)
		e.innerHTML = "";
}

function add_pj_member()
{
	var ee = document.addMember.shareMember;
	if (trim(ee.value) == "")
		return false;
/*
	var val = addMember.shareMember.value;
	val = val.replace(/;/g, ",");
	var valArr = val.split(",");
	for (i=0; i<valArr.length; i++) {
		val = trim(valArr[i]);
		if (val == "") continue;
		if (!checkMail(val)) {
			fixElement(addMember.shareMember, "[" + val
				+ "] is not a valid email address.  You must enter valid email addresses to add team members.");
			return false;
		}
	}
*/
	addMember.submit();
}
//-->
</script>

<title>
	<%=Prm.getAppTitle()%> Project Profile
</title>

<style type="text/css">
.plaintext_big {line-height:20px;}
</style>

</head>

<link rel="stylesheet" href="../ss/css.css">

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
					<td height="30" align="left" valign="bottom" class="head">
						<b>Project Profile</b>
					</td>
					<td width='225'>
<%	if (isUpdateOk)			//  || isOwnerManager
	{
		out.print("<img src='../i/bullet_tri.gif' width='20' height='10'>");
		out.print("<a class='listlinkbold' href='proj_update.jsp?projId=" + projIdS + "'>Update Project Profile</a>");
		if (!isCRAPP && !isMeetWE && isAdmin) {
			out.print("<br><img src='../i/bullet_tri.gif' width='20' height='10'>");
			out.print("<a class='listlinkbold' href='javascript:optimize_schedule()'>Optimize Project Schedule</a>");
		}
	}

	if (isUpdateOk || optStr.contains(project.OP_MEMBER_UPD_PLAN)) {
		out.print("<br><img src='../i/bullet_tri.gif' />");
		out.print("<a class='listlinkbold' href='../plan/updplan.jsp?projId="
					+ projIdS + "'>Change Project Plan</a>");
	}
	if (isUpdateOk) {
		out.print("<br><img src='../i/bullet_tri.gif' />");
		out.print("<a class='listlinkbold' href='../plan/new_templ1.jsp?projId="
					+ projIdS + "'>Save Plan Template</a>");
		
		out.print("<br><img src='../i/bullet_tri.gif' width='20' height='10'>");
		out.print("<a class='listlinkbold' href='post_proj_del.jsp?projId=" + projIdS
				+ "' onClick=\"return confirm('When the Project is deleted, all its tasks and blogs will be gone. "
				+ "This action is non-recoverable. Do you really want to delete the Project?')\">Delete Project</a>");
	}

%>
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
<% if (isMeetWE) { %>
					<jsp:include page="../in/home.jsp" flush="true">
					<jsp:param name="role" value="<%=iRole%>" />
					</jsp:include>
<% } else { %>
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Project" />
				<jsp:param name="subCat" value="ProjectProfile" />
				<jsp:param name="role" value="<%=iRole%>" />
				<jsp:param name="projId" value="<%=projIdS%>" />
			</jsp:include>
<% } %>
<!-- End of Navigation SUB-Menu -->
				</td>
	        </tr>
		</table>
		<!-- Content Table -->

		 <table width="100%" border="0" cellspacing="0" cellpadding="0">


			<tr><td colspan="2">&nbsp;</td></tr>
			<tr>
				<td width="20"><img src="../i/spacer.gif" width="5" border="0"></td>
				<td>

<!-- Page Headers -->
		 <table width="100%" border="0" cellpadding="0" cellspacing="0">

			<tr>
				<td width="450" class="heading">
				<font size="3"><%=projName%></font>
				</td>


			</tr>
		</table>

		</tr>
		</table>

<!-- BEGIN INTERNAL CELL -->

	<br>
	<table width="90%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>


<!-- CONTENT LEFT -->
<table width="100%" height="100%" border="0" cellspacing="0" cellpadding="0">

<tr>

<td width="70%" valign="top">



<!-- PROJ PROFILE -->
<table height="110">
	<tr>
		<td width="15">&nbsp;</td>
		<td width="150">&nbsp;</td>
		<td>&nbsp;</td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_big"><b><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Project Name")%>:</b></td>
		<td class="plaintext_big"><%=projName%></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_big" valign="top"><b><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Objective")%>:</b></td>
		<td class="plaintext_big"><%=Desc%></td>
	</tr>
	
<%
	// Company
	//s = (String)proj.getAttribute("TownID")[0];
	s = proj.getStringAttribute("Company");
	if (s != null)
	{
		s = (String)(townManager.getInstance().get(pstuser, Integer.parseInt(s))).getAttribute("Name")[0];
%>
		<tr>
			<td width="15">&nbsp;</td>
			<td class="plaintext_big"><b><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Company")%>:</b></td>
			<td class="plaintext_big"><%=s%></td>
		</tr>
<%	}

	// DepartmentName (optional)
	s = (String)proj.getAttribute("DepartmentName")[0];
	if (s == null) s = "<td class='plaintext_big_grey'>None";
	else
	{
		s = s.replaceAll("@", "; ");
		s = "<td class='plaintext_big'>" + s;
	}
%>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_big"><b><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Department")%>:</b></td>
		<%=s%></td>
	</tr>

<%
	s = proj.getStringAttribute("Category");
	if (s == null) s = "<td class='plaintext_big_grey'>None";
	else s = "<td class='plaintext_big'>" + s;
%>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_big"><b><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Category")%>:</b></td>
		<%=s%></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_big"><b><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Project Status")%>:</b></td>
		<td class="plaintext_big">
		<% if (status.equals("Late") && complete != null)
			out.print("<font color='#22aa22'>Completed </font> - ");%>
		<font color="<%=color%>"><%=status%></font></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_big"><b><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Coordinator")%>:</b></td>
		<td class="plaintext_big"><a href="../ep/ep1.jsp?uid=<%=coordinatorIdS%>" class="listlink">
			<%=uname%></a> <%if (coordinator!=null) {%>&#60;<%=coordinator%>&#62;<%}%></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_big"><b><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Privacy Type")%>:</b></td>
		<td class="plaintext_big"><%=type%></td>
	</tr>
<%if (!isCRAPP){%>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_big"><b><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Creation Date")%>:</b></td>
		<td class="plaintext_big"><%=createdDate%></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_big"><b><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Start Date")%>:</b></td>
		<td class="plaintext_big"><%=startDate%></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_big"><b><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Deadline")%>:</b></td>
		<td class="plaintext_big"><%=deadline%></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_big"><b><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Completed Date")%>:</b></td>
		<td class="plaintext_big"><%=completeDate%></td>
	</tr>
	
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_big"><b><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Default Top Page")%>:</b></td>
		<td class="plaintext_big"><%=topPageS%></td>
	</tr>
	
<%} %>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_big" valign="top"><b><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Options")%>:</b></td>
		<td class="plaintext_big">
<%
		out.print("<table border='0' cellspacing='0' cellpadding='0'>");

		String [] optionStrArr;
		if (isCRAPP) {
			optionStrArr = project.OPTION_STR_CR;
		}
		else {
			optionStrArr = project.OPTION_STR;
		}
		for (int i=0; i<project.OPTION_ARRAY.length; i++) {
			if (optionStrArr[i] == null)
				continue;		// this option not supported in this App

			out.print("<tr><td class='plaintext_big'>" + optionStrArr[i] + "</td>");
			out.print("<td width='50' align='right'>");
			if (isUpdateOk) out.print("<a href='proj_update.jsp?projId=" + projIdS + "#option'>");
			out.print("<img src='../i/");
			if (optStr.contains(project.OPTION_ARRAY[i]))
				out.print("dot_green.gif' border='0' />" + CLOSE_A_TAG + "</td><td class='plaintext_big'>&nbsp;On</td>");
			else
				out.print("dot_white.gif' border='0' />" + CLOSE_A_TAG + "</td><td class='plaintext_big'>&nbsp;Off</td></tr>");
		}

		out.print("</table>");
%>
		</td>
	</tr>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_big" valign="top"><b><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Prefix")%>:</b></td>
		<td class="plaintext_big"><%=projAbbrev%></td>
	</tr>

<%if (!isCRAPP && !isMeetWE){%>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_big" valign="top"><b><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Phases")%>:</b></td>
		<td class="plaintext_big">
		<ol>
<%
	String [] sa;
	String st, tkidS, phaseName;
	String doneDtS, expDtS;
	PstAbstractObject [] objArr = phMgr.getPhases(pstuser, String.valueOf(proj.getObjectId()));
	phase ph = null;
	task tk;
	planTask ptk;
	int [] ids;
	String format = "MM/dd/yy";
	for (int i=0; i<objArr.length; i++)
	{
		ph = (phase) objArr[i];
		doneDtS = expDtS = st = "";
		// @110705ECC
		Object obj = ph.getAttribute(phase.TASKID)[0];
		if (obj != null)
		{
			// use task to fill the phase info
			tkidS = obj.toString();
			try
			{
				tk = (task)tkMgr.get(pstuser, tkidS);
				ids = ptMgr.findId(pstuser, "TaskID='" + tkidS + "' && Status!='Deprecated'");
				ptk = (planTask)ptMgr.get(pstuser, ids[ids.length-1]);
				obj = ph.getAttribute(phase.NAME)[0];
				if (obj == null)
					s = (String)ptk.getAttribute("Name")[0];
				else
					s = obj.toString();
				phaseName = "<a class='listlink' href='task_update.jsp?projId=" + projIdS
					+ "&pTaskId=" + ptk.getObjectId() + "'>" + s + "</a>";

				dt = (Date)tk.getAttribute("ExpireDate")[0];
				expDtS = phase.parseDateToString(dt, format);
				if (expDtS.length() <= 0)
				{
					dt = (Date)tk.getAttribute(phase.PLANEXPIREDATE)[0];
					expDtS = phase.parseDateToString(dt, format);
				}

				dt = (Date)tk.getAttribute("CompleteDate")[0];
				doneDtS = phase.parseDateToString(dt, format);

				st = (String)tk.getAttribute("Status")[0];
				if (s.equals(task.ST_NEW)) s = project.PH_NEW;
				else if (s.equals(task.ST_OPEN) || s.equals(task.ST_ONHOLD)) s = project.PH_START;
				st = s;
			}
			catch (PmpException e){phaseName = "*** Invalid task ID";}
		}
		else
		{
			phaseName = (String)ph.getAttribute(phase.NAME)[0];

			dt = (Date)ph.getAttribute(phase.STARTDATE)[0];

			dt = (Date)ph.getAttribute(phase.EXPIREDATE)[0];
			expDtS = phase.parseDateToString(dt, format);
			if (expDtS.length() <= 0)
			{
				dt = (Date)ph.getAttribute(phase.PLANEXPIREDATE)[0];
				expDtS = phase.parseDateToString(dt, format);
			}

			dt = (Date)ph.getAttribute(phase.COMPLETEDATE)[0];
			doneDtS = phase.parseDateToString(dt, format);

			st = ph.getAttribute(phase.STATUS)[0].toString();
		}
		out.print("&nbsp;&nbsp;<li>" + phaseName);
		out.print("<font color='#999999'> (");
		if (st.equals(project.PH_COMPLETE))
			out.print("Done " + doneDtS);
		else
		{
			if (expDtS.length() <= 0)
				expDtS = "TBD";
			out.print("Due " + expDtS);
		}
		out.print(")</font></li>");
	}

%>		</ol>
		</td>
	</tr>
<%} %>
<!-- *********** FILES *********** -->
<%
	// @SWS061406 begins
	Object [] attmtList = proj.getAttribute("AttachmentID");
// @AGQ042006
	ArrayList statusRepList = new ArrayList();
	ArrayList attmtArrList = new ArrayList();
	String summaryDoc = null;
	String msProjDoc = null;
	String attmt;
	attachment sumAttmtObj = null;
	attachment msAttmtObj = null;
	attachment attmtObj;
	String fileName, user;
	Date attmtCreateDt;
	if (attmtList[0]!= null)
	{
		for (int i=0; i<attmtList.length; i++)
		{
			try {attmtObj = (attachment)aMgr.get(pstuser, (String)attmtList[i]);}
			catch (Exception e) {continue;}
			attmt = (String)attmtObj.getAttribute("Location")[0];
			fileName = attmtObj.getFileName();

			if (fileName == null) break;
			if (summaryDoc==null && fileName.startsWith("PRM_" + projIdS))
			{
				sumAttmtObj = attmtObj;
			}
			else if (msProjDoc==null && fileName.startsWith("PRM_MSP_" + projIdS))
			{
				msAttmtObj = attmtObj;
			}
//	 @AGQ042006
			else if (fileName.startsWith("PrmReport_" + projName))
			{
				statusRepList.add(attmtObj);
			}
			else
				attmtArrList.add(attmtObj);
		}
	}
%>


<!-- project summary -->
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_big" valign="top"><b><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Project Summary")%>:</b></td>
		<td class="plaintext_big">
			<table border="0" cellspacing="0" width='100%'>

			<tr>
<%
			if (sumAttmtObj != null || statusRepList.size() != 0 || attmtArrList.size() != 0 || msAttmtObj != null)
			{%>
				<tr>
				<td bgcolor="#6699cc" class="td_header"><strong>&nbsp;<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "File Name")%></strong></td>
				<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
				<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
				<td width="80" bgcolor="#6699cc" class="td_header"><strong><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Owner")%></strong></td>
				<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
				<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
				<td width="90" bgcolor="#6699cc" class="td_header" align="left"><strong><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Posted On")%></strong></td>
				<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
				<td bgcolor="#6699cc"></td>
				</tr>
<%			}

			if (sumAttmtObj == null)
			{
				out.print("<td colspan = '8' class='plaintext_big_grey'>>> Click the Generate Button to create a summary file</td>");
				out.print("<td>&nbsp;</td>");
			}
			else
			{
				user =  sumAttmtObj.getOwnerDisplayName(pstuser);
				attmtCreateDt = (Date)sumAttmtObj.getAttribute("CreatedDate")[0];
				fileName = sumAttmtObj.getFileName();
%>
				<td class="listlink" valign='top'>
					<a class="listlink" href="<%=host%>/servlet/ShowFile?attId=<%=sumAttmtObj.getObjectId()%>"><%=fileName%></a>
				</td>
				<td colspan='2'>&nbsp;</td>
				<td class="formtext"><a href="../ep/ep1.jsp?uid=<%=(String)sumAttmtObj.getAttribute("Owner")[0]%>" class="listlink"><%=user%></a></td>
				<td colspan='2'>&nbsp;</td>
				<td class="formtext"><%=df1.format(attmtCreateDt)%></td>
				<td>&nbsp;</td>
<%			}%>

				<td align="right"><input class="button_medium" type="button" value="Generate"
					onclick="return affirm_summary('post_summary.jsp?projId=<%=projIdS%>');"></td>
			</tr>
			</table>
		</td>
	</tr>
<%	int size = 0;
	if (!isCRAPP && !isMeetWE){%>
<!-- Status Report -->
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_big" valign="top"><b><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Status Reports")%>:</b></td>
		<td class="plaintext_big">
			<table border="0" cellspacing="0" cellpadding="0">
<%
	// file name is: name of doc.ext
		size = statusRepList.size();
		if (size == 0)
		{%>
			<tr><td class="plaintext_big_grey"><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "None")%></td></tr>
<%		}
		else
		{
			//Collections.sort(statusRepList);
			for (int i=size-1; i>=0; i--)
			{
				// reverse order looks better
				attmtObj = (attachment)statusRepList.get(i);
				user = attmtObj.getOwnerDisplayName(pstuser);
				attmtCreateDt = (Date)attmtObj.getAttribute("CreatedDate")[0];
				fileName = attmtObj.getFileName();
%>
				<tr>
				<td class="listlink" width="250" valign='top'>
					<a class="listlink" href="<%=host%>/servlet/ShowFile?filePath=<%=projIdS%>/<%=fileName%>"><%=fileName%></a>
				</td>
				<td colspan='2'>&nbsp;</td>
				<td class="formtext" valign='top'><a href="../ep/ep1.jsp?uid=<%=(String)attmtObj.getAttribute("Owner")[0]%>" class="listlink"><%=user%></a></td>
				<td colspan='2'>&nbsp;</td>
				<td class="formtext" valign='top'><%=df1.format(attmtCreateDt)%></td>
				<td>&nbsp;</td>
<%				if (isUpdateOk)
				{%>
					<td><input class="button_medium" type="button" value="Delete"
						onclick="return affirm_delfile('post_delfile.jsp?projId=<%=projIdS%>&fname=<%=fileName%>');" align="right"></td>
<%				}%>
				</tr>
<%
			}
		}
%>
			</table>
		</td>
	</tr>

<!-- file attachment -->
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_big" valign="top"><b><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Project Files")%>:</b></td>
		<td class="plaintext_big">
			<table border="0" cellspacing="0" cellpadding="0">
<%
	// file name is: Attachment-name of doc.ext
	size = attmtArrList.size();
	if (size == 0)
	{
		out.print("<tr><td class='plaintext_big_grey'>None</td></tr>");
	}
	else
	{
		//Collections.sort(attmtArrList);
		for (int i=0; i<size; i++)
		{
			// reverse order looks better
			attmtObj = (attachment)attmtArrList.get(i);
			user =  attmtObj.getOwnerDisplayName(pstuser);
			attmtCreateDt = (Date)attmtObj.getAttribute("CreatedDate")[0];
			fileName = attmtObj.getFileName();

// @AGQ042006

%>
			<tr>
			<td class="listlink" width="250" valign='top'>
				<a class="listlink" href="<%=host%>/servlet/ShowFile?filePath=<%=projIdS%>/Attachment-<%=fileName%>"><%=fileName%></a>
			</td>
			<td colspan='2'>&nbsp;</td>
			<td class="formtext" valign='top'><a href="../ep/ep1.jsp?uid=<%=(String)attmtObj.getAttribute("Owner")[0]%>" class="listlink"><%=user%></a></td>
			<td colspan='2'>&nbsp;</td>
			<td class="formtext" valign='top'><%=df1.format(attmtCreateDt)%></td>
			<td width="10">&nbsp;</td>
<%			if (isUpdateOk)
			{%>
				<td><input class="button_medium" type="button" value="Delete" width="100"
					onclick="return affirm_delfile('post_delfile.jsp?projId=<%=projIdS%>&fname=<%=fileName%>');" align="right" valign="top"></td>
<%			}%>
			</tr>
<%
		}
	}
%>
			</table>
		</td>
	</tr>

<!-- add file -->
<%-- @AGQ040306 --%>

<%	if (!isGuestRole) { %>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_big" valign="top"><b><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Add Project File")%>:</b></td>
		<td>
<form name="addFile" action="post_addfile.jsp" method="post" enctype="multipart/form-data">
<input type="hidden" name="projId" value="<%=projIdS%>"/>
<table cellpadding="0" cellspacing="0" border="0">
	<tr>
		<td class='plaintext_big'>
			<input id="my_file_element" type="file" class="formtext" style='font-size:13px;' size="41" />
			<table><tbody id="files_list"></tbody></table>
			<script>
				var multi_selector = new MultiSelector( document.getElementById( 'files_list' ), 0, document.getElementById( 'my_file_element' ).className , document.getElementById( 'my_file_element' ).size );
				multi_selector.addElement( document.getElementById( 'my_file_element' ) );
			</script>
		</td>
	</tr>
	<tr><td><img src='../i/spacer.gif' width='1' height='10' /></td></tr>
	<tr><td class="formtext">Files to be uploaded:</td></tr>

	<tr>
		<td><input class="button_medium" type="submit" name="Submit" value="Upload Files"
			onclick="return setAddFile();"/>
		</td>
	</tr>
	<tr><td><img src='../i/spacer.gif' width='1' height='10' /></td></tr>

</table>
</form>
		</td>
	</tr>

<%	}	// END if !isGuestRole

	} 	// END if !isCRAPP


	if (!isCRAPP && !isMeetWE && (isCoordinator || isProgMgr) )
	{%>
<!-- MS Project Export -->
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_big" valign="top"><b><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "MS Project Export")%>:</b></td>
		<td class="plaintext_big">
			<table border="0" cellspacing="0" cellpadding="0" width='100%'>
			<tr>
<%			if (msAttmtObj == null) {%>
				<td class="plaintext_big_grey">>> Click the Export Button to create an MS Project CSV file</td>
<%			}
			else {
				user =  msAttmtObj.getOwnerDisplayName(pstuser);
				attmtCreateDt = (Date)msAttmtObj.getAttribute("CreatedDate")[0];
				fileName = msAttmtObj.getFileName();
%>
				<td class="listlink" width="250">
					<a class="listlink" href="<%=host%>/servlet/ShowFile?attId=<%=msAttmtObj.getObjectId()%>"><%=fileName%></a>
				</td>
				<td colspan='2'>&nbsp;</td>
				<td class="formtext"><a href="../ep/ep1.jsp?uid=<%=(String)msAttmtObj.getAttribute("Owner")[0]%>" class="listlink"><%=user%></a></td>
				<td colspan='2'>&nbsp;</td>
				<td class="formtext"><%=df1.format(attmtCreateDt)%></td>
				<td>&nbsp;</td>
<%			}	// @SWS061406 ends %>

				<td align="right"><input class="button_medium" type="button" value="Export"
					onclick="return affirm_summary('post_msp_export.jsp?projId=<%=projIdS%>');" align="right"/></td>
			</tr>
			</table>
		</td>
	</tr>

<!-- MS Project Import -->
<form name="msProject" action="post_msp_import.jsp" method="post" enctype="multipart/form-data">
<input type="hidden" name="projId" value="<%=projIdS%>"/>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_big" valign="top"><b><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "MS Project Import")%>:</b></td>
		<td><input class="formtext" style='font-size:13px;' type="file" name="Attachment" size="41"/>
		</td>
	</tr>
	<tr><td><img src='../i/spacer.gif' width='1' height='10' /></td></tr>
	<tr><td colspan='2'></td><td class="formtext">Files to be uploaded:</td></tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_big" valign="top">&nbsp;</td>
		<td><input class="button_medium" type="submit" name="Submit" value="Upload Files"
			onclick="return affirm_addfile(msProject.Attachment.value);"/>
		</td>
	</tr>
</form>
<%	}	// End isCoordinator || isProgMgr
%>

</table>
</td>

<td class="headlinerule">
	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" width="1" alt=" " /></td>
	    </tr>
	</table>
</td>

<td valign="top">
	<table>
	<tr>
	<td width="3">&nbsp;</td>
	<td>
	<div class="namelist_hdr"><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "The Project Team")%>&nbsp;
		(<%=totalTeamMember%>)&nbsp;&nbsp;<a href="../blog/addalert.jsp?townId=<%=tidS%>&projId=<%=projIdS%>&backPage=<%=backPage%>">
		<img src="../i/eml.gif" border="0"/></a><br/><br/></div>
<%
	out.print(Util3.listTeamMembers(memberList, coordinatorId));
%>
	</td>
	</tr>

	<tr><td colspan='2'><img src='../i/spacer.gif' height='20' /></td></tr>

<!-- partition line -->
	<tr><td></td><td><table cellspacing='0' cellpadding='0'>
	<tr><td bgcolor='#ee0000' height='1'><img src='../i/spacer.gif' height='1' /></td>
	<td></td></tr>
	<tr><td bgcolor='#ee0000' height='1' width='30'><img src='../i/spacer.gif' height='1' /></td>
	<td bgcolor='#ee0000' height='1'><img src='../i/spacer.gif' width='100' height='1' /></td>
	</tr></table></td></tr>

<%	if (isUpdateOk) { %>
	<tr>
		<td></td>
		<td>
			<img src='../i/bullet_tri.gif' width='20' height='10'/>
			<a href='javascript:share();' class='listlinkbold'><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Add project team member")%></a>
		</td>
	</tr>
<%
	}	// END if isUpdateOk

	String msg = request.getParameter("msg");
	if (msg!=null && msg.length()>0)
	{
		out.print("<tr><td></td><td id='msg' class='plaintext_big' width='220'><font color='#00aa00'>" + msg + "</font></td></tr>");
	}
%>
<form name='addMember' method='post' action='post_add_member.jsp'>
<input type='hidden' name='projId' value='<%=projIdS%>'>
<%
	out.print("<tr>");
	out.print("<td></td><td id='shareEmail' style='display:none' width='200'>");
	out.print("<table><tr><td class='inst'>To share this project space with other people, enter their ");
	out.print("email addresses separated by comma and click SAVE.</td></tr>");
	out.print("<tr><td class='plaintext_big'><b>Share with</b>: <span class='inst'>(e.g. jdoe@gmail.com)</span></td></tr>");
	out.print("<tr><td>");
	out.print("<textarea name='shareMember' cols='30' rows='5' onKeyDown='return entSub(event, document.addMember);'></textarea></td></tr>");

	// @ECC102108 dropdown for choosing emails
	out.print("<tr><td><div id='emails' style='display:none'><select id='emailSel' class='formtext_fix' multiple size='5' name='emails' "
			+ "onKeyDown='return entSub(event, document.addMember);' ondblClick='pickItem(document.addMember);'>");

	// @ECC102108 suggestive email dropdown
	String emailStr = null;
	try {emailStr = (String)pstuser.getAttribute("Remember")[0];}	// emails separated by ";"
	catch (PmpException e) {}
	if (emailStr == null) emailStr = "";
	if (emailStr.length() > 0)
	{
		String [] sa = emailStr.split(";");
		Arrays.sort(sa);
		for (int i=0; i<sa.length; i++)
			out.print("<option value='" + sa[i] + "'>" + sa[i] + "</option>");
	}
	out.print("</select></div></td></tr>");

	out.print("<tr><td class='plaintext_big'><b>Optional message</b>:</td></tr>");
	out.print("<tr><td><textarea name='optMsg' rows='3' cols='30' style='word-break:normal'></textarea></td></tr>");

	out.print("<tr><td align='center'>");
	out.print("<input type='button' class='button_medium' name='save' value=' SAVE ' onclick='javascript:add_pj_member();'>");
	out.print("<input type='button' class='button_medium' name='cancel' value='CANCEL' onclick='javascript:share();'>");
	out.print("</td></tr></table></td></tr>");
%>
</form>

	</table>

</td>

</tr>

</table>


	</td>
</tr>

<!-- BEGIN FOOTER TABLE -->
<jsp:include page="/foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

