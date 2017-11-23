<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
////////////////////////////////////////////////////
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//	File:	proj_update.jsp
//	Author:	ECC
//	Date:	03/22/04
//	Description:
//		Display and update the project info.  Only allow proj owner or Chief to update.
//	Modification:
//		@AGQ101804
//			Implement the logic to enforce state tansition diagram in project.
//		@AGQ102004
//			Alert user that changing  will affect all the tasks
//		@ECC063005
//			Turned off FCKeditor for project description update
//		@ECC063005
//			Add project options.  Enable member update plan.
//		@100905ECC
//			Support bug blog template.
//		@110705ECC
//			Add option to link a Phase or Sub-phase to Task.
//		@AGQ022406
//			Add display of distribution list
//		@AGQ050506
//			Removed links to milestone and phase definition
//		@071906ECC	Support multiple companies using PRM.
//		@AGQ072606	States that the project coordinator is required to
//						be part of the team.
//		@ECC011707	Support Department Name in project, task and attachment for authorization.
//		@ECC060407	Support more flexible attachment authorization using department name combination.
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
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");	

// 0 = 'New', 1 = 'Open', 2 = 'On-hold', 3 = 'Late', 4 = 'Completed',
// 5 = 'Canceled', 6 = 'Closed'
	final int iNEW		= 0;
	final int iOPEN		= 1;
	final int iONHOLD	= 2;
	final int iLATE		= 3;
	final int iCOMPLETE = 4;
	final int iCANCEL	= 5;
	final int iCLOSE	= 6;

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	String host = Prm.getPrmHost();
	String pstuserIdS = String.valueOf(pstuser.getObjectId());
	boolean isAdmin = false;
	boolean isProgMgr = false;
	boolean isPjOwner = false;			// project coordinator
	boolean isAboveUser = false;		// allow only above USER grade to update project phases

	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if (iRole > 0)
	{
		if ((iRole & user.iROLE_ADMIN) > 0)
		{
			isAdmin = true;
			isAboveUser = true;
		}
		if ((iRole & user.iROLE_PROGMGR) > 0)
		{
			isProgMgr = true;
			isAboveUser = true;
		}
		//if ((iRole & user.iROLE_USER) == 0)
		//	isAboveUser = true;
	}
	int myUid = pstuser.getObjectId();
	String s;
	String [] sa;
	PstAbstractObject o;

	// to check if session is CR or PRM
	boolean isCRAPP = Prm.isCR();
	String app = Prm.getAppTitle();
	boolean isMultiCorp = Prm.isMultiCorp();

	// town
	/*String townName = (String)session.getAttribute("townName");
	town tObj = (town)townManager.getInstance().get(pstuser, townName);
	String townChiefIdS = (String)tObj.getAttribute("Chief")[0];*/

	townManager tnMgr = townManager.getInstance();
	projectManager projMgr = projectManager.getInstance();

	// project
	String projIdS = request.getParameter("projId");

	project projObj = (project)projMgr.get(pstuser, Integer.parseInt(projIdS));

	// check to see if it is self-calling to set/unset container project
	s = request.getParameter("setAsContainer");	
	if (s != null) {
		// called by ContainerForm
		if (s.equals("true")) {
			// set the project to a container project
			projObj.setAsContainer(true);
		}
		else {
			if (projObj.isContainer()) {
				projObj.setAsContainer(false);
			}
		}
	}

	String projName = projObj.getObjectName();
	String projDisplayName = projObj.getDisplayName();
	
	boolean isPersonalSpace = projName.contains("Personal Space@@");
	
	
	String townIdS = (String)projObj.getAttribute("Company")[0];	// was using TownID
	town townObj = null;
	if (townIdS != null) {
		townObj = (town) tnMgr.get(pstuser, Integer.parseInt(townIdS));
	}
	String ownerIdS   = (String)projObj.getAttribute("Owner")[0];
	int ownerId = Integer.parseInt(ownerIdS);
	if (ownerId == myUid)
	{
		isPjOwner = true;
		isAboveUser = true;
	}

	String tStatus = (String)projObj.getAttribute("Status")[0];
	
	java.text.SimpleDateFormat df = new java.text.SimpleDateFormat("MM/dd/yyyy");
	String doneDtS = "-";
	Date doneDt = (Date)projObj.getAttribute("CompleteDate")[0];
	if (doneDt != null) {
		doneDtS = df.format(doneDt);
		if (tStatus.equals(project.ST_LATE))
			tStatus = project.ST_COMPLETE;
	}

	String option = (String)projObj.getAttribute("Type")[0];
	if (option == null) option = "Private";		// default
	
	String userCompanyIdS = pstuser.getStringAttribute("Company");

	// @ECC011707
	String deptName = (String)projObj.getAttribute("DepartmentName")[0];
	if (deptName == null) deptName = "";
	// try to get DepartmentName from the user company, if not from config file
	s = userCompanyIdS;
	if (isCRAPP) {
		if (s != null) {
			o = tnMgr.get(pstuser, Integer.parseInt(s));
			s = (String)o.getAttribute("DepartmentName")[0];
		}
	}
	if (s == null)
		s = Util.getPropKey("pst", "DEPARTMENTS");

	String [] allDept = null;
	if (s != null) allDept = s.split(";");
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
		myDepts = deptName.split("@");

	// update only authorized to project owner and for roles above user
	// just for double safety: actually I cannot get to this page from proj_profile.jsp unless
	// I am either admin, project owner, or the supervisor of the project owner
	if (ownerIdS == null || (ownerId!=pstuser.getObjectId() && !isAboveUser))
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}

	// get the expiration date
	String expDateS = null;
	Date expireDt = (Date)projObj.getAttribute("ExpireDate")[0];
	if (expireDt == null) {
		expDateS = "-";
	}
	else {
		expDateS = df.format(expireDt);
	}
	long createdDate = ((Date)projObj.getAttribute("CreatedDate")[0]).getTime();

	// project start date
	String startDateS = null;
	Date startDate = (Date)projObj.getAttribute("StartDate")[0];
	if (startDate != null)
	{
		startDateS = df.format(startDate);
	}

	// all project team people
	Object [] projTeam = projObj.getAttribute("TeamMembers");
	userManager uMgr = userManager.getInstance();
	PstAbstractObject [] teamMember = uMgr.get(pstuser, projTeam);
	Util.sortUserArray(teamMember, true);

	// all people I can choose to be included on the project team

	// executive summary task
	String sumTaskIdS = projObj.getOption(project.EXEC_SUMMARY);
	if (sumTaskIdS == null) sumTaskIdS = "";
	String taskBlogIdS = projObj.getOption(project.TASK_BLOG_ID);
	if (taskBlogIdS == null) taskBlogIdS = "";
	String bugBlogIdS = projObj.getOption(project.BUG_BLOG_ID);
	if (bugBlogIdS == null) bugBlogIdS = "";
	String projAbbrev = projObj.getOption(project.ABBREVIATION);
	if (projAbbrev == null) projAbbrev = "";

	// authority
	String disableStr = "";
	if (!isAdmin && !isProgMgr && !isPjOwner) {
		disableStr = "disabled";
	}
%>

<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>

<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../forms.jsp" flush="true"/>
<script language="JavaScript" src="../get-date.js"></script>
<!--script type="text/javascript" src="<%=host%>/FCKeditor/fckeditor.js"></script-->
<!--
window.onload = function()
{
	var oFCKeditor = new FCKeditor( 'Description' ) ;
	oFCKeditor.ReplaceTextarea() ;
}-->

<script type="text/javascript">

<!--
window.onload = function() {
	sortSelect(document.getElementById("WholeTown"));
	sortSelect(document.getElementById("Selected"));
}

function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

function validation()
{
	if (!<%=projObj.isContainer()%> && updateProject.ExpireDate.value == '')
	{
		fixElement(updateProject.ExpireDate,
			"Please make sure that the EXPIRATION DATE field is properly completed.");
		return false;
	}

	if (updateProject.Owner.value =='')
	{
		fixElement(updateProject.Owner,
			"Please make sure to select a PROJECT COORDINATOR.");
		return false;
	}

	// @AGQ072606
	var ownerId = updateProject.Owner.value;
	var hasOwner= false;
	var opts = updateProject.TeamMembers.options;
	for (var i=0; i<opts.length; i++) {
		if (opts[i].value == ownerId) {
			hasOwner = true;
			break;
		}
	}
	if (!hasOwner) {
		fixElement(updateProject.Owner,
			"PROJECT COORDINATOR needs to be part of the TEAM MEMBERS.");
		return false;
	}

	if (updateProject.TeamMembers.length == 0)
	{
		fixElement(updateProject.TeamMembers,
			"A project must contain one or more team members.  Please choose your team members for the project.");
		return false;
	}

	var today = new Date();
	today = new Date(today.getFullYear(),today.getMonth(),today.getDate());
	var startDate = new Date('<%=startDateS%>');
	var c = true;

	if (!<%=projObj.isContainer()%>) {
		var s = '<%=tStatus%>';
		var newSt = updateProject.Status.value;
	
		// @AGQ102004
		if (newSt == 'Completed' && s != newSt)
		{	// Confirm User with subtasks also being completed
			c = confirm("Moving a project to the COMPLETED state will trigger all of its NEW, OPEN and LATE subtasks to COMPLETE. " +
							"Do you want to proceed?");
		}
		else if (newSt == 'Canceled' && s != newSt)
		{	// Confirm User with subtasks also being canceled
			c = confirm("Once the project is CANCELED, you would not be allowed to make any changes on this project nor its tasks. " +
							"Do you want to proceed?");
		}
		else if ( s == 'On-hold' && newSt == 'Open')
		{	// Confirm User that all subtasks that was onhold will become open
			c = confirm("Moving a project from the ON-HOLD state to OPEN will trigger all of its subtasks to resume their previous states. " +
							"Do you want to proceed?");
		}
		else if ( newSt == 'On-hold' && s != newSt)
		{	// Confirm user that all subtasks will be on-hold
			c = confirm("Moving a project to the ON-HOLD state will trigger all of its working subtasks to become ON-HOLD. " +
							"Do you want to proceed?");
		}
		else if ( s == 'New' && newSt == 'Open' && today.toString()!=startDate.toString())
		{	// Confirm user the start date will be set to today
			c = confirm("Are you sure you want to START tracking this project?")
		}
		else if ( (s == 'Completed' && newSt == 'Closed') ||
					s == 'Canceled' && newSt == 'Closed')
		{
			// Confirm user that closed project will be archieved and stored into history
			c = confirm("Moving a project to the CLOSED state will trigger the project to be archieved." +
							" Do you want to proceed?");
		}
		
		// check date validity
		var startDtFld = updateProject.StartDate;
		var completeDtFld = updateProject.CompletionDate;
		if (completeDtFld != null) {
			var startDt = new Date(startDtFld.value);
			var completeDt = new Date(completeDtFld.value);
			if (startDt > completeDt) {
				fixElement(completeDtFld,
						"Project COMPLETION DATE cannot be earlier than project START DATE.");
				return false;
			}
		}
	}	// END: for non-container project
	

<%	if (!isCRAPP)
	{%>
		getall(updateProject.AlertPersonnel);
		var alertMessage = updateProject.AlertMessage.value;
		for (i=0;i<alertMessage.length;i++) {
			char = alertMessage.charAt(i);
			if (char == '\\') {
				fixElement(updateProject.AlertMessage,
					"ALERT MESSAGE cannot contain these characters: \n  \\");
				return false;
			}
		}
<%	}%>
	getall(updateProject.Departments);	// @ECC060407
	getall(updateProject.TeamMembers);
	if(c) {
		updateProject.submitButton.disabled = true;
		updateProject.submit();
	}
}

function show_cal(e1, e2)
{
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
	var es = 'updateProject.' + e1.name;
	show_calendar(es, mon, yr);
}

function setContainer()
{
	var f = document.ContainerForm;
	if (f.SetAsContainerBox.checked) {
		f.setAsContainer.value = "true";
	}
	else {
		f.setAsContainer.value = "false";
	}
	f.submit();
}

function setProjectDue()
{
	// set project due date based on project schedule
	var f = document.updateProject;
	f.op.value = "setDueDate";
	f.submit();
}
//-->
</script>

<title>
	<%=app%> Update Project
</title>

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
						<b>Update Project Profile</b>
					</td>
					<td valign="bottom">
<%-- @AGQ050506	if (isAboveUser)
	{%>
			<img src="../i/bullet_tri.gif" width="20" height="10">
			<a class="listlinkbold" href="phase_update.jsp?projId=<%=projIdS%>">Update Phase Definition</a><br />
			<img src="../i/bullet_tri.gif" width="20" height="10">
			<a class="listlinkbold" href="phase_update2.jsp?projId=<%=projIdS%>">Update Milestone Schedule</a>
<%	} --%>
					</td>
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
				<jsp:param name="projId" value="<%=projIdS%>" />
			</jsp:include>
<!-- End of Navigation Menu -->
				</td>
	        </tr>
		</table>


<!-- MAIN CONTENT -->
<br>
<table width='90%'>
<tr>
    <td width="12">&nbsp;</td>
	<td class="plaintext" >
		&nbsp;Please note fields marked with an * are required.</td>
</tr>

<!-- set as container project -->
<tr>
	<td colspan='2' class='plaintext_blue' align='right'>
		<form name='ContainerForm'>
		<input type='hidden' name='projId' value='<%=projIdS%>'>
		<input type='hidden' name='setAsContainer' value=''>
<%
		out.print("<input type='checkbox' name='SetAsContainerBox' onclick='setContainer();' ");
		if (projObj.isContainer()) out.print("checked");
		out.print(">&nbsp;<b>Set as container project</b>&nbsp;&nbsp;");
%>
		</form>
	</td>
</tr>


<tr>
    <td width="12">&nbsp;</td>
<td>

<form name="updateProject" action="post_updproj.jsp" method="post" enctype="multipart/form-data">
<input type="hidden" name="projId" value="<%=projIdS%>"/>
<input type="hidden" name="Charge" value='false'/>
<input type='hidden' name='op' value=''/>

<!-- start table -->
	<table width="100%" border="0" cellspacing="2" cellpadding="4" bgcolor="#FFFFFF">

<!-- Project Compnay -->
<%	if (isAdmin || isProgMgr)
	{
%>
	<tr bgcolor="#FFFFFF">
		<td class="td_field_bg">Project Company</td>
		<td class="td_value_bg">
		<select class="formtext" name="TownId">
		<option value="">- select Company -</option>
<%
		// ECC: need to take care of the case where the project is belonging to one company
		// but the ProgMgr doesn't have that company. In that case, post page need to ignore
		// the NULL uplate.  Done.
		boolean bNoMatch = true;
		
		int townId = 0;
		if (townIdS != null) {
			townId = Integer.parseInt(townIdS);
		}

		int [] ids = null;
		if (isAdmin)
			ids = tnMgr.findId(pstuser, "om_acctname='%'");
		else {
			Object [] iArr = pstuser.getAttribute("Towns");
			ids = Util2.toIntArray(iArr);
		}
				
		// just check through the login user's towns
		PstAbstractObject [] towns = tnMgr.get(pstuser, ids);
		int id;
		for (int i=0; i<towns.length; i++) {
			String compName = towns[i].getObjectName();
			id = towns[i].getObjectId();
			out.write("<option value='" + id +"'");
			if (id == townId) {
				out.write(" selected");
				bNoMatch = false;
			}
			out.write(">" + compName + "</option>");
		}
		
		if (bNoMatch && townIdS!=null) {
			if (townIdS.equals(userCompanyIdS)) {
				o = tnMgr.get(pstuser, Integer.parseInt(userCompanyIdS));
				s = o.getObjectName();
				out.write("<option value='" + userCompanyIdS +"' selected>"
						+ s + "</option>");
			}
			// ECC: else optionally repair user Towns to add this project town
		}
%>
		</select>
		</td>
	</tr>
	
<%	}	// isAdmin || isProgMgr
%>

<!-- Project Name -->
<%
	String disS = disableStr;
	if (isPersonalSpace && !disS.contains("disabled"))
		disS += "disabled";
%>
	<tr bgcolor="#FFFFFF">
		<td class="td_field_bg" width="180" valign='top'>* Project Name</td>
		<td class="td_value_bg">
			<input class='formtext' name='ProjDispName' value="<%=projDisplayName%>"
				style='width:75%;'
				<%=disS%>></input>
		</td>
	</tr>


<!-- Project Coordinator -->
	<tr bgcolor="#FFFFFF">
		<td class="td_field_bg" valign='top'>* Project Coordinator</td>
		<td class="td_value_bg">
		<select class="formtext" name="Owner">
		<option value="">- select Coordinator -</option>
<%
	String uname;
	for(int a=0; a < teamMember.length; a++)
	{
		uname = ((user)teamMember[a]).getFullName();

		out.print("<option value='" + teamMember[a].getObjectId() + "'");
		if (ownerIdS != null && (ownerId == teamMember[a].getObjectId()))
		{
			out.print(" selected");
		}
		out.println(">" + uname + "</option>");
	}

	out.print("</select>");

	out.print("&nbsp;&nbsp;&nbsp;<input class='formtext' type='checkbox' name='TaskOwner'>");
	out.print("<span class='plaintext'>Transfer ownership of all the tasks of this project to this person</span>");
	out.print("</td></tr>");
		
// category
	// if the company has defined a list of category, show it here
	/* ECC: I have changed category to store the option lists for bug tracker
	
	if (townObj != null) {
		s = townObj.getStringAttribute("Category");
		String [] catArr = StringUtil.toStringArray(s, "::");
		if (catArr.length > 0) {
			String projCategory = projObj.getStringAttribute("Category");
			out.print("<tr><td class='td_field_bg' valign='top'>&nbsp;&nbsp;&nbsp;Category</td>");
			out.print("<td class='td_value_bg'>");
			out.print("<table border='0' cellspacing='0' cellpadding='0'>");
			String cat;
			for (int i=0; i<catArr.length; i++) {
				cat = catArr[i];
				if (i%4==0) out.print("<tr>");
				out.print("<td class='td_value_bg' width='150'>");
				out.print("<input class='formtext' type='radio' name='Category' value='" + cat + "'");
				if (cat.equals(projCategory)) out.print(" checked");
				out.print(">" + cat + "</td>");
				if ((i+1)%4==0 || i==catArr.length-1) out.print("</tr>");
			}
			out.print("</table>");
			out.print("</td></tr>");
		}
	}
*/
%>

<!-- privacy type -->
	<tr bgcolor="#FFFFFF">
		<td class="td_field_bg">* Privacy Type</td>
		<td class="td_value_bg">
		<table border='0' cellspacing='0' cellpadding='0'><tr>
			<td class='td_value_bg' width='150'>
				<input class="formtext" type="radio" name="ProjectPrivacy" value="Private"
				<%if (option.equals("Private")){out.print(" checked");}%> >Private</td>
			<td class='td_value_bg' width='150'>
				<input class="formtext" type="radio" name="ProjectPrivacy" value="Public"
				<%if (option.equals("Public")){out.print(" checked");}%> >Public</td>
			<td class='td_value_bg' width='150'>
				<input class="formtext" type="radio" name="ProjectPrivacy" value="Public Read-only"
				<%if (option.equals("Public Read-only")){out.print(" checked");}%> >Public Read-only</td>
		</tr></table>
		</td>
	</tr>

<!-- @ECC011707 project DepartmentName -->
<!-- @ECC060407 support combination of departments -->
	<tr bgcolor="#FFFFFF">
		<td class="td_field_bg" valign='top'>&nbsp;&nbsp;&nbsp;Access Control</td>
		<td class="td_value_bg">
		<table border="0" cellspacing="4" cellpadding="0">
		<tr>
			<td bgcolor="#FFFFFF">
			<select class="formtext_fix" name="AllDepartment" multiple size="5">
<%			if (allDept != null)
			for (int i=0; i<allDept.length; i++)
			{
				if (allDept[i] == null) continue;		// ignored
				s = allDept[i];
				out.print("<option value='" + s + "'");
				out.print(">" + s + "</option>");
			}
%>
			</select>
			</td>

			<td align="center" valign="middle" class="td_value_bg">
				<input type="button" class="button" name="add" value="&nbsp;&nbsp;&nbsp;Add &gt;&gt;&nbsp;&nbsp;" onClick="swapdata(this.form.AllDepartment,this.form.Departments)">
			<br><input type="button" class="button" name="remove" value="<< Remove" onClick="swapdata(this.form.Departments,this.form.AllDepartment)">
			</td>

			<td bgcolor="#FFFFFF">
				<select class="formtext_fix" name="Departments" multiple size="5">

<%
			if (myDepts!= null && myDepts.length > 0 && myDepts[0] != null)
			{
				for (int i=0; i < myDepts.length; i++)
				{
					out.print("<option value='" +myDepts[i]+ "'>" +myDepts[i]+ "</option>");
				}
			}
%>
				</select>
			</td>

		</tr>
		</table>
		</td>
	</tr>

<%	if (!projObj.isContainer()) { %>
<!-- status -->
		<tr bgcolor="#FFFFFF">
		<td class="td_field_bg">* Project Status</td>
		<td class="td_value_bg">
		<select class="formtext" name="Status">

<%
		String [] StateValAry = project.STATE_ARRAY;

	// @AGQ101804
	// These section of jsp handles the options list avaliable to user
	//				when the user wants to update their project
	// variable test = 0 if we want all the options of New, Open, On-hold, Late, Completed, Canceled
	//			test = 1 if we don't want the user to be able to select any wrong state transitions

	int test = 1;
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
	 	// 0 = 'New', 1 = 'Open', 2 = 'On-hold', 3 = 'Late', 4 = 'Completed',
		// 5 = 'Canceled', 6 = 'Closed'

		// : 		New Transition
		// Options: 	Open Transition
		// Comments: 	New -> Open
		// System: 		New -> Open, New -> Late, New -> Canceled (by parent)
		if (tStatus != null && tStatus.equals("New")) {
			out.println("<option name='" + StateValAry[iNEW] + "' value='" + StateValAry[iNEW] + "' selected>" + StateValAry[iNEW]);
			out.println("<option name='" + StateValAry[iOPEN] + "' value='" + StateValAry[iOPEN] + "'>" + StateValAry[iOPEN]);
		}
		// : 		Open Transition
		// Options: 	On-hold, Completed, Canceled Transition
		// Comments: 	Open -> On-hold, Open -> Completed, Open -> Canceled
		// System: 		Open -> Late

		else if (tStatus != null && tStatus.equals("Open")) {
			out.println("<option name='" + StateValAry[iOPEN] + "' value='" + StateValAry[iOPEN] + "' selected>" + StateValAry[iOPEN]);
			out.println("<option name='" + StateValAry[iONHOLD] + "' value='" + StateValAry[iONHOLD] + "'>" + StateValAry[iONHOLD]);
			out.println("<option name='" + StateValAry[iCOMPLETE] + "' value='" + StateValAry[iCOMPLETE] + "'>" + StateValAry[iCOMPLETE]);
			out.println("<option name='" + StateValAry[iCANCEL] + "' value='" + StateValAry[iCANCEL] + "'>" + StateValAry[iCANCEL]);
		}

		// : 		On-hold Transition
		// Options: 	Open, Canceled Transition
		// Comments: 	On-hold -> Open, On-hold -> Canceled
		// System: 		On-hold -> Late

		else if (tStatus != null && tStatus.equals("On-hold")) {
			out.println("<option name='" + StateValAry[iONHOLD] + "' value='" + StateValAry[iONHOLD] + "' selected>" + StateValAry[iONHOLD]);
			out.println("<option name='" + StateValAry[iOPEN] + "' value='" + StateValAry[iOPEN] + "'>" + StateValAry[iOPEN]);
			out.println("<option name='" + StateValAry[iCANCEL] + "' value='" + StateValAry[iCANCEL] + "'>" + StateValAry[iCANCEL]);
		}
		// : 		Late Transition
		// Options: 	Completed, Canceled Transition
		// Comments: 	Late -> Completed, Late -> Canceled
		// System: 		Late -> Open (changing the expiration date)

		else if (tStatus != null && tStatus.equals("Late")) {
			out.println("<option name='" + StateValAry[iLATE] + "' value='" + StateValAry[iLATE] + "' selected>" + StateValAry[iLATE]);
			out.println("<option name='" + StateValAry[iCOMPLETE] + "' value='" + StateValAry[iCOMPLETE] + "'>" + StateValAry[iCOMPLETE]);
			out.println("<option name='" + StateValAry[iCANCEL] + "' value='" + StateValAry[iCANCEL] + "'>" + StateValAry[iCANCEL]);

		}
		// : 		Completed Transition
		// Options: 	null
		// Comments: 	Completed tasks are finished.
		// System: 		none

		else if (tStatus != null && tStatus.equals("Completed")) {
			out.println("<option name='" + StateValAry[iCOMPLETE] + "' value='" + StateValAry[iCOMPLETE] + "' selected>" + StateValAry[iCOMPLETE]);
			out.println("<option name='" + StateValAry[iCLOSE] + "' value='" + StateValAry[iCLOSE] + "'>" + StateValAry[iCLOSE]);


		}

		// : 		Canceled Transition
		// Options: 	null
		// Comments: 	Canceled tasks are closed, unless specified as service to do so.
		// System: 		none
		else if (tStatus != null && tStatus.equals("Canceled")) {
			out.println("<option name='" + StateValAry[iCANCEL] + "' value='" + StateValAry[iCANCEL] + "' selected>" + StateValAry[iCANCEL]);
			out.println("<option name='" + StateValAry[iCLOSE] + "' value='" + StateValAry[iCLOSE] + "'>" + StateValAry[iCLOSE]);
			out.println("<option name='" + StateValAry[iOPEN] + "' value='" + StateValAry[iOPEN] + "'>Re-Open");
		}
		else if (tStatus != null && tStatus.equals("Closed")) {
			out.println("<option name='" + StateValAry[iCLOSE] + "' value='" + StateValAry[iCLOSE] + "' selected>" + StateValAry[iCLOSE]);
		}
	}
%>
		</select>
<%	if (doneDt!=null) out.print("<b>Completed on " + df.format(doneDt) + "</b>");%>
		</td>
		</tr>
<%	} %>


<!-- start date -->
	<tr bgcolor="#FFFFFF">
		<td class="td_field_bg">&nbsp;&nbsp;&nbsp;Start Date</td>
		<td class="td_value_bg">
			<input class="formtext" type="text" name="StartDate" size="30" value='<%if (startDateS !=null) out.print(startDateS); %>'  onClick="show_cal(updateProject.StartDate);" />
			<a href="javascript:show_cal(updateProject.StartDate);"><img src="../i/calendar.gif" border="0" align="absmiddle" title="Click to view calendar." /></a>
		</td>
	</tr>

<!-- expire date -->
<%
	if (!projObj.isContainer()) {
		out.print("<tr bgcolor='#FFFFFF'>");
		out.print("<td class='td_field_bg'>&nbsp;&nbsp;&nbsp;Expiration Date</td>");
		out.print("<td class='td_value_bg'>");
		out.print("<input class='formtext' type='Text' name='ExpireDate' size='30' value='");
		if (expDateS !=null) out.print(expDateS);
		out.print("'  onClick='show_cal(updateProject.ExpireDate);'>");
		out.print("&nbsp;<a href='javascript:show_cal(updateProject.ExpireDate);'>");
		out.print("<img src='../i/calendar.gif' border='0' align='absmiddle' title='Click to view calendar.'></a>");
		out.print("<span>");
		out.print("<img src='../i/spacer.gif' width='20' height='1'/>");
		out.print("<img src='../i/bullet_tri.gif'/>");
		out.print("<a href='javascript:setProjectDue();'>Set due date based on project schedule</a>");
		out.print("</span></td></tr>");

// completion date
		if (tStatus.equals(project.ST_COMPLETE)) {
			out.print("<tr><td class='td_field_bg'>&nbsp;&nbsp;&nbsp;Completion Date</td>");
			out.print("<td class='td_value_bg'>");
			out.print("<input class='formtext' type='Text' name='CompletionDate' size='30' value='");
			out.print(doneDtS);
			out.print("'  onClick='show_cal(updateProject.CompletionDate);'>");
			out.print("&nbsp;<a href='javascript:show_cal(updateProject.CompletionDate);'>");
			out.print("<img src='../i/calendar.gif' border='0' align='absmiddle' title='Click to view calendar.'></a>");
			out.print("</td></tr>");
		}
	}
%>

<!-- ********************** Project Team ********************** -->
<%
	// get all town people
	int [] allEmpIds;
	Integer iObj = (Integer)pstuser.getAttribute("Towns")[0];
	if (townIdS==null && iObj!=null)
		townIdS = iObj.toString();
	if (isAdmin || townIdS==null || !isMultiCorp)
		allEmpIds = uMgr.findId(pstuser, "om_acctname='%'");
	else
		allEmpIds = uMgr.findId(pstuser, "(Towns="
				+ townIdS + ") || (TownID='" + pstuser.getStringAttribute("TownID") + "')");

	PstAbstractObject [] allEmp = uMgr.get(pstuser, allEmpIds);
	Util.sortUserArray(allEmp);

	for (int i=0; i<allEmp.length; i++)
	{
		if (allEmp[i].getAttribute("FirstName")[0] == null)
			allEmp[i] = null;
	}

	// duplicate all town people list
	PstAbstractObject [] allEmp1 = new PstAbstractObject[allEmp.length];
	for (int i=0; i<allEmp.length; i++)
		allEmp1[i] = allEmp[i];
%>

<!-- Managed Team -->
<tr>
		<td class="td_field_bg" valign='top'>&nbsp;&nbsp;&nbsp;Team Members</td>
		<td class="td_value_bg">
<%
	// allEmp will be on the left while team members will be on the right
// @AGQ022806
	String [] usrName = new String [teamMember.length];
	//String [] lName = new String [teamMember.length];
	String firstName, lastName, uName;

	if (teamMember[0] != null) {
		for (int i = 0; i < teamMember.length; i++)
		{
			int id = teamMember[i].getObjectId();
			boolean found = false;
			for (int j = 0; j < allEmp1.length; j++)
			{
				if (allEmp1[j] == null) continue;
				if (allEmp1[j].getObjectId() == id)
				{
					usrName[i] = ((user)allEmp[i]).getFullName();
//					fName[i] = (String)allEmp1[j].getAttribute("FirstName")[0];
//					lName[i] = (String)allEmp1[j].getAttribute("LastName")[0];
					allEmp1[j] = null;
					found = true;
					break;
				}
			}
		}
	}

	dlManager dlMgr = dlManager.getInstance();
	PstAbstractObject [] dlArr = dlMgr.getDLs(pstuser);
	Util.sortName(dlArr);

%>
		<table border="0" cellspacing="4" cellpadding="0">
		<tr>
			<td bgcolor="#FFFFFF">
			<select class="formtext_fix" name="WholeTown" id="WholeTown" multiple size="5">
<%
	String prevName = null;

	if (allEmp1 != null && allEmp1.length > 0)
	{
		for (int i=0; i < allEmp1.length; i++)
		{
			if (allEmp1[i] == null) continue;
			uName = ((user)allEmp1[i]).getFullName();
%>
			<option value="<%=allEmp1[i].getObjectId()%>"><%=uName%></option>
<%
		}
	}

%>
			</select>
			</td>
			<td align="center" valign="middle" class="td_value_bg">
				<input type="button" class="button" name="add" value="&nbsp;&nbsp;&nbsp;Add &gt;&gt;&nbsp;&nbsp;" onClick="swapdata(this.form.WholeTown,this.form.TeamMembers)">
			<br><input type="button" class="button" name="remove" value="<< Remove" onClick="swapdata(this.form.TeamMembers,this.form.WholeTown)">
			</td>
<!-- people selected -->
			<td bgcolor="#FFFFFF">
				<select class="formtext_fix" name="TeamMembers" id="TeamMembers" multiple size="5">

<%
	if (teamMember.length > 0 && teamMember[0] != null)
	{
		for (int i=0; i < teamMember.length; i++)
		{
			uName = ((user)teamMember[i]).getFullName();
%>
			<option value="<%=teamMember[i].getObjectId()%>"><%=uName %></option>
<%
		}
	}
%>
				</select>
			</td>
		</tr>
		</table>
</td>
</tr>
<!-- end of Project Team -->


<%	if (isMultiCorp) {%>
<!-- Guest Member -->
	<tr bgcolor="#FFFFFF">
		<td class="td_field_bg" valign='top'>&nbsp;&nbsp;&nbsp;Guest Members</td>
		<td class="td_value_bg"><input type='text' class="formtext" name="Guest" style='width:75%;'>
		<div class='formtext'>Use Email or <%=Prm.getAppTitle()%> username, separated by comma (e.g. johns@abc.com, susano)</div>
		</td>
	</tr>
<%	}%>


<!-- Description -->
<%
	Object descObj = projObj.getAttribute("Description")[0];
	String desc = (descObj==null)?"":new String((byte[])descObj, "utf-8");
	desc = desc.replaceAll("<p>", "\n");

%>
	<tr bgcolor="#FFFFFF">
		<td class="td_field_bg" valign='top'>&nbsp;&nbsp;&nbsp;Project Objective</td>
		<td class="td_value_bg"><textarea class="formtext" name="Description" rows="4" style='width:75%;'><%=desc%></textarea>
		</td>
	</tr>
<!-- end of Description -->


<!-- @ECC063005 Options -->
<%
	if (isAdmin || isProgMgr || isPjOwner)
	{
		String optionStr = (String)projObj.getAttribute("Option")[0];
		if (optionStr == null) optionStr = "";
		String select = null;
%>
	<tr bgcolor="#FFFFFF">
		<td class="td_field_bg" valign='top'><a name='option'>&nbsp;&nbsp;&nbsp;Options</a></td>
		<td class="td_value_bg">
			<table border='0'  cellspacing="0" cellpadding="0">
<%
			String [] optionStrArr;
			if (isCRAPP) {
				optionStrArr = project.OPTION_STR_CR;
			}
			else {
				optionStrArr = project.OPTION_STR;
			}
			for (int i=0; i<project.OPTION_ARRAY.length; i++)
			{
				if (optionStrArr[i] == null)
					continue;		// this option not supported in this App
				if (optionStr.indexOf(project.OPTION_ARRAY[i]) != -1)
					select = " checked";
				else
					select = "";
				//if (isCRAPP && i==2) disable = "disabled";	// for CR only allow certain options
				//else disable = "";
				out.print("<tr><td class='plaintext'>");
				out.print("<input type='checkbox' name='"
						+ project.OPTION_ARRAY[i] + "'" +select+ " " + disableStr + ">&nbsp;");
				out.print(optionStrArr[i]);
				out.print("</td></tr>");
			}
%>
			</table>
		</td>
	</tr>

<%		if (!isCRAPP){%>
<!-- Executive Summary Task -->
	<tr bgcolor='#FFFFFF'>
		<td class='td_field_bg'>&nbsp;&nbsp;&nbsp;Exec Summary Task</td>
		<td class='td_value_bg'>
			<input class='formtext' type='text' size='8' name='SummeryTaskId' value='<%=sumTaskIdS%>'/>
		</td>
	</tr>
<!-- @100905ECC Task Blog Template -->
	<tr bgcolor='#FFFFFF'>
		<td class='td_field_bg'>&nbsp;&nbsp;&nbsp;Task Blog Template</td>
		<td class='td_value_bg'>
			<input class='formtext' type='text' size='8' name='TaskBlogId' value='<%=taskBlogIdS%>'/>
		</td>
	</tr>
<!-- @100905ECC Bug Blog Template -->
	<tr bgcolor='#FFFFFF'>
		<td class='td_field_bg'>&nbsp;&nbsp;&nbsp;Bug Blog Template</td>
		<td class='td_value_bg'>
			<input class='formtext' type='text' size='8' name='BugBlogId' value='<%=bugBlogIdS%>'/>
		</td>
	</tr>
<!-- Abbreviation -->
	<tr bgcolor='#FFFFFF'>
		<td class='td_field_bg'>&nbsp;&nbsp;&nbsp;Project Prefix</td>
		<td class='td_value_bg'>
			<input class='formtext' type='text' size='8' name='Abbrev' value='<%=projAbbrev%>'/>
			<span class='formtext'>(Max. 5 characters long)</span>
		</td>
	</tr>
<%		}%>
<%	}%>
<!-- end of Options -->


<%	if (!isCRAPP){%>
<!-- ****************** Alert Message ******************* -->
<tr><td colspan="2" class="title" valign="bottom"><br>Project Reminder Alert</td>
</tr>

<!-- Alert Condition (get options from Config file) -->
<tr>
	<td width="120" class="td_field_bg">&nbsp;&nbsp;&nbsp;Alert Condition</td>
	<td  class="td_value_bg">
		<select class="formtext" name="AlertCondition">
<%
		// get option values from config file
		ResourceBundle prop = ResourceBundle.getBundle("bringup");
		int condition = 0;	// from database
		iObj = (Integer)projObj.getAttribute("AlertCondition")[0];
		if (iObj != null) condition = iObj.intValue();
		int optionTotal = Integer.parseInt(prop.getString("TASK.ALERT.CONDITION"));
		String [] optionValue = null;

		for (int i = 0; i < optionTotal;)
		{
			// option value will be 1, 2, 3, ... etc.
			out.print("<option value="+ ++i);
			if (condition == i) out.print(" selected>");
			else out.print(">");
			s = prop.getString("TASK.ALERT.CONDITION."+i);
			s = s.replaceAll("task", "project");
			out.println(s);
		}
%>
		</select>

	</td>
</tr>


<!-- Alerted Personnel -->
<tr>
		<td class="td_field_bg" valign='top'>&nbsp;&nbsp;&nbsp;Alert Personnel</td>
		<td class="td_value_bg">
		<!-- Managed Pesonnel -->
<%
	// allEmp will be on the left while alertEmp will be on the right
// @AGQ022806
	PstAbstractObject [] alertIdS = null;
	Object [] alertIdObjArr = projObj.getAttribute("Alert");
	int alertLength = (alertIdObjArr[0] != null)?alertIdObjArr.length:0;
	if (alertLength > 0) {
		// Duplicate the list into an int []
		int [] alertIdIntArr = new int[alertLength];
		for(int i = 0; i < alertLength; i++)
			alertIdIntArr[i] = Integer.parseInt(alertIdObjArr[i].toString());

		alertIdS = uMgr.get(pstuser, alertIdIntArr);
		alertLength = alertIdS.length;		// ECC: the get() might shrink the array!!!
		Util.sortName(alertIdS);
		usrName = new String [alertLength];
		//lName = new String [alertLength];
		int id=0;
		for (int i=0; i<alertLength; i++) {
			if (alertIdS[i] == null) continue;
			id = alertIdS[i].getObjectId();
			for (int j = 0; j < allEmp.length; j++)
			{
				if (allEmp[j] == null) continue;
				if (allEmp[j].getObjectId() == id)
				{
					usrName[i] = ((user)allEmp[i]).getFullName();
//					fName[i] = (String)allEmp[j].getAttribute("FirstName")[0];
//					lName[i] = (String)allEmp[j].getAttribute("LastName")[0];
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
			<select class="formtext_fix" name="Selected" id="Selected" multiple size="5">
<%
//@AGQ022406
	String curName;
	int idx;
	prevName = null;
	for(int i=0; i<dlArr.length; i++) {
		dl curDl = (dl)dlArr[i];
		curName = curDl.getObjectName();
		idx = curName.indexOf("@@");
		if (idx != -1)
			curName = curName.substring(0, idx);
		if (prevName != null) {
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
			if (allEmp[i] == null) continue;
			firstName = (String)allEmp[i].getAttribute("FirstName")[0];
			lastName = (String)allEmp[i].getAttribute("LastName")[0];
			uName = firstName + (lastName==null?"":(" " + lastName));
%>
			<option value="<%=allEmp[i].getObjectId()%>"><%=uName%></option>
<%
		}
	}

%>
			</select>
			</td>
			<td align="center" valign="middle" class="td_value_bg">
				 <input type="button" class="button" name="add" value="&nbsp;&nbsp;&nbsp;Add &gt;&gt;&nbsp;&nbsp;" onclick="swapdata(this.form.Selected,this.form.AlertPersonnel)"/>
			<br/><input type="button" class="button" name="remove" value="<< Remove" onclick="swapdata(this.form.AlertPersonnel,this.form.Selected)"/>
			</td>
<!-- people selected -->
			<td bgcolor="#FFFFFF">
				<select class="formtext_fix" name="AlertPersonnel" multiple size="5">
<%
	if (alertLength > 0)
	{
		for (int i=0; i<alertLength; i++)
		{
			if (alertIdS[i]==null || usrName[i]==null) continue;
			out.print("<option value='" + alertIdS[i].getObjectId() + "'>" + usrName[i] + "</option>");
		}
	}
%>
				</select>
			</td>
		</tr>
		<tr><td><span class="footnotes">* Distribution list</span></td></tr>
		</table>
</td>
</tr>


<!-- End of Alerted Personnel -->

<!-- Alert Message Content -->
<%

	String msg = (String)projObj.getAttribute("AlertMessage")[0];
	if (msg != null)
		msg = "<input class='formtext' type='input' name='AlertMessage' value='"
			+Util.stringToHTMLString(msg) + "' size='80'>";
	else
		msg = "<input class='formtext' type='input' name='AlertMessage' size='80'>";
%>
	<tr>
		<td class="td_field_bg">&nbsp;&nbsp;&nbsp;Alert Message</td>
		<td class="td_value_bg"><%=msg%></td>
	</tr>
<!-- End of Alert -->
<%	}%>
</table>
<!-- end table -->

		<p align="center">
		<input type='button' name='submitButton' class='button_medium' value='Submit' onclick='return validation();'/>
		<input type='button' class='button_medium' value='Cancel' onclick='location="proj_profile.jsp?projId=<%=projIdS%>";'/>
		<br/></p>
		</form>

	</td>
</tr>
</table>

<!-- END MAIN CONTENT -->
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

