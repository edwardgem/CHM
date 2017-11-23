<%@ page contentType="text/html; charset=utf-8"%>

<%
////////////////////////////////////////////////////
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	proj_new1.jsp
//	Author:	ECC
//	Date:	04/11/04
//	Description:
//		Create a new project.
//	Modification:
//		@071906ECC	Support multiple companies using PRM.
//		@ECC011707	Support Department Name in project, task and attachment for authorization.
//		@ECC030609	For CR MultiCorp, check membership level to decide if user can create more projects.
//					This check is done in proj_new1.jsp, post_add_member.jsp and post_updproj.jsp.
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "util.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	String s;
	PstAbstractObject o;
	
	String locale = (String) session.getAttribute("locale");

	// to check if session is CR
	boolean isCRAPP = Prm.isCR();
	boolean isMeetWE = Prm.isMeetWE();
	boolean isPRMAPP = Prm.isPRM();
	boolean isEnterprise = isPRMAPP;
	boolean isMultiCorp = Prm.isMultiCorp();

	townManager tnMgr = townManager.getInstance();
	projectManager pjMgr = projectManager.getInstance();

	// @071906ECC use the user's first town as the project town
	String townIdS = "";
	String tidS = request.getParameter("tid");	// for MeetWE to pass the circle ID or PRM company ID
	Integer iObj=null;
	if (StringUtil.isNullOrEmptyString(tidS)) {
		// try to get from users Company, then TownID
		tidS = pstuser.getStringAttribute("Company");			// use Company
		if (tidS != null)
			iObj = new Integer(tidS);
		else
			iObj = (Integer)pstuser.getAttribute("Towns")[0];	// get the first town
	}
	else {
		// user provide the company id
		iObj = new Integer(tidS);
	}
	String townName = "";		//(String)pstuser.getAttribute("TownID")[0];
	if (iObj != null)
	{
		townIdS = iObj.toString();	// numeric id
		PstAbstractObject tObj = tnMgr.get(pstuser, iObj.intValue());
		townName = tObj.getObjectName();
		//townName = PstManager.getNameById(pstuser, Integer.parseInt(townName));
	}
	if (StringUtil.isNullOrEmptyString(townName) && !isMultiCorp) {
		if ((townName = Util.getPropKey("pst", "COMPANY_NAME")) == null)
			townName = "";
	}

	String companyDisplayName = townName;
	town townObj = null;

	if (!StringUtil.isNullOrEmptyString(townName)) {
		try {
				townObj = (town)tnMgr.get(pstuser, townName);
				companyDisplayName = (String)townObj.getAttribute("Name")[0];
		}
		catch (PmpException e) {
			response.sendRedirect("../out.jsp?msg=This company ["
					+ townName + "] is not found in the database. "
					+ "Please contact Administration to fix the system configuration.");
			return;
		}
	}
	
	// with the town, check for create project limit
	// the project limit is set in the Town Option. The default is 5.
	int [] ids;
	if (!isMeetWE) {
		int maxProj;
		if (townObj != null) {
			maxProj = townObj.getLimit(town.MAX_PROJECT);
			if (maxProj <= 0) maxProj = town.DEFAULT_MAX_PROJ;
			ids = pjMgr.findId(pstuser, "TownID='" + townObj.getObjectId() + "'");
		}
		else {
			maxProj = town.DEFAULT_MAX_PROJ;
			ids = pjMgr.getProjects(pstuser);
		}
		
		if (ids.length >= maxProj) {
			// exceed max no. of projecs allowed - will check again in post_proj_new.jsp
			response.sendRedirect("../out.jsp?msg=5001&go=info/upgrade.jsp");
			return;
		}
	}

	String descStr = ">> "
		+ StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "NewProj-103");
	SimpleDateFormat df = new SimpleDateFormat ("MM/dd/yyyy");
	String todayS = df.format(new Date());

	// check to see level of service
	String levelS = null;
	if (isMultiCorp)
	{
		PstAbstractObject ui = userinfoManager.getInstance().get(pstuser, String.valueOf(pstuser.getObjectId()));
		levelS = town.getLevelString((String)ui.getAttribute("Status")[0]);
		if (levelS!=null && levelS.contains(userinfo.LEVEL_4))
			isEnterprise = true;
	}
	else
		isEnterprise = true;		// !isMultiCorp is alway enterprise

	// @ECC011707
	// try to get DepartmentName from the user company, if not from config file
	String [] allDept = null;
	s = null;
	String label1 = "Department";
	String label0 = "";
	if (isEnterprise)
	{
		if (isCRAPP || isPRMAPP)
		{
			s = (String)pstuser.getAttribute("Company")[0];
			if (s != null)
			{
				o = tnMgr.get(pstuser, Integer.parseInt(s));
				s = (String)o.getAttribute("DepartmentName")[0];
			}
			label0 = "Company";
			label1 = "Access Control";
		}
		else if (isMeetWE)
			label0 = "Circle";
		if (s == null)
			s = Util.getPropKey("pst", "DEPARTMENTS");

		if (s != null) allDept = s.split(";");
		// @ECC060407
		if (allDept != null)
		{
			for (int i=0; i<allDept.length; i++)
				allDept[i] = allDept[i].trim();
		}
	}
	
	// make sure to wipe out the current plan in memory
	session.removeAttribute("planStack");

%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">


<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../forms.jsp" flush="true"/>
<script language="JavaScript" src="../get-date.js"></script>

<script language="JavaScript">
<!--
window.onload = function () {
	document.newProjectForm.ProjName.focus();
}

function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

function validation()
{
	var f = document.newProjectForm;
	if (!checkProjName(f.ProjName.value)) {
		return false;
	}

	if (f.StartDate.value =='')
	{
		fixElement(f.StartDate,
			"Please make sure that the PROJECT START DATE field is properly completed.");
		return false;
	}
	if (f.ExpireDate.value =='')
	{
		f.ExpireDate.value = f.StartDate.value;
	}
	else
	{
		var now = new Date();
		var today = new Date(now.getYear(),now.getMonth(),now.getDate());
		var expire = new Date(f.ExpireDate.value);
		var start = new Date(f.StartDate.value);
		var diff = expire.getTime() - today.getTime();
		var days = Math.floor(diff / (1000 * 60 * 60 * 24));
		if (days < 0)
		{
			fixElement(f.ExpireDate,
				"The PROJECT DEADLINE must be in the future.  Please choose another date for PROJECT DEADLINE.");
			return false;
		}
		/*if (days >= 365)
		{
			fixElement(document.newProjectForm.ExpireDate,
				"The PROJECT DEADLINE cannot be more than a year (365 days) from now.  Please choose another date for PROJECT DEADLINE.  You may extend your deadline when the project has started.");
			return false;
		}
		if (start < today)
		{
			fixElement(document.newProjectForm.StartDate,
				"The PROJECT START DATE cannot be set to the past.  Please choose another date for PROJECT START DATE.");
			return false;
		}*/
		if (start > expire)
		{
			fixElement(f.StartDate,
				"The PROJECT START DATE cannot be later than or on the PROJECT DEADLINE.  Please choose another date for PROJECT START DATE or PROJECT DEADLINE.");
			return false;
		}
	}
	if (f.Description.value.substring(0,2) == ">>")
		f.Description.value = '';

	getall(f.Departments);	// @ECC060407
	return;
}

function checkProjName(projName)
{
	var f = document.newProjectForm;
	projName = trim(projName);	
	if (projName == '')
	{
		fixElement(f.ProjName,
			"Please make sure that the PROJECT NAME field is properly completed.");
		return false;
	}

	for (i=0;i<projName.length;i++) {
		char = projName.charAt(i);
		if (char == '\"' || char == '\\' || char == '~'
				|| char == '`' || char == '!' || char == '#' || char == '$'
				|| char == '%' || char == '^' || char == '*' || char == '('
				|| char == ')' || char == '+' || char == '=' || char == '['
				|| char == ']' || char == '{' || char == '}' || char == '|'
				|| char == '?' || char == '>' || char == '<') {
			fixElement(f.ProjName,
				"PROJECT NAME cannot contain these characters: \n  \" \\ ~ ` ! # $ % ^ * ( ) + = [ ] { } |  ? > <");
			return false;
		}
	}
	f.ProjName.value = projName;		// trimmed
	return true;
}

function doclear(e)
{
	if (e.value.substring(0,2) == ">>")
		e.value = '';
	return;
}

function defaultText(e)
{
	if (e.value == '')
		e.value = '<%=descStr%>';
	return;
}

function toggleDetailPanel()
{
	var e = document.getElementById("detailPanelDiv");
	var ee = document.getElementById("toggleStmt");
	if (e.style.display == 'none') {
		e.style.display = 'block';
		var temp = 
		ee.innerHTML = '<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Hide project details")%>';
	}
	else {
		e.style.display = 'none';
		ee.innerHTML = '<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Add more project details")%>';
	}
}

function createProjNow()
{
	// ignore the detailed project plan, take default values with no tasks
	var f = document.newProjectForm;
	
	if (!checkProjName(f.ProjName.value)) {
		return false;
	}

	f.ExpireDate.value = f.StartDate.value;		// same start/expire date
	f.action = "post_proj_new.jsp";
	f.submit();
}

//-->
</script>

<title>
	Create a New Project
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

	<table>

	<tr><td colspan="2">&nbsp;</td></tr>
	<tr>
	<td></td>
	<td>
	<b class="head">
	Create a New Project<br><br>
	</b>
	</td></tr>

	</table>

	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- CONTENT -->
<form method="post" name="newProjectForm" action="proj_new2.jsp">
<table border='0' width='100%' cellspacing='0' cellpadding='0'>

	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="instruction_head"><br><b>
		<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "NewProj-101")%>
		</b></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="instruction">
		<br>
		<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "NewProj-102")%>
		<p><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Common-101")%><br><br></td>
	</tr>

<!-- town name -->
<input type="hidden" name="TownName" value="<%=townName%>" >
<input type="hidden" name="TownID" value="<%=townIdS%>" >

<% if (!StringUtil.isNullOrEmptyString(companyDisplayName)) { %>
	<tr><td><img src='../i/spacer.gif' height='10' width='1'/></td></tr>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_blue" width='180'>&nbsp;&nbsp;&nbsp;
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, label0)%>:</td>
		<td class='plaintext_big'><%=companyDisplayName%></td>
	</tr>
<% } %>

<!-- Project Name -->
	<tr><td><img src='../i/spacer.gif' height='10' width='1'/></td></tr>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_blue"><font color="#000000">*</font> 
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Project Name")%>:</td>
		<td>
			<input type="text" class='plaintext_big' name="ProjName" size="50">
		</td>
	</tr>

	<tr><td><img src='../i/spacer.gif' height='20' width='1'/></td></tr>
	<tr>
		<td></td>
		<td colspan='2' >&nbsp;&nbsp;<img src='../i/bullet_tri.gif'/>
			<a id='toggleStmt' class='listlinkbold' href='javascript:toggleDetailPanel();'>
				<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Add more project details")%></a>
		</td>
	</tr>

	<tr>
		<td colspan='3'>
<div id='detailPanelDiv' style='display:none;'>
		<table border='0' cellspacing='0' cellpadding='0'>

	
<!-- Access Control -->
<%	if (allDept != null)
	{
%>
	<tr><td><img src='../i/spacer.gif' height='10' width='1'/></td></tr>
	<tr>
		<td width="15">&nbsp;</td>
		<td valign="top" width="180" class="plaintext_blue">&nbsp;&nbsp;&nbsp;
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, label1)%>: </td>
		<td class="plaintext_big">
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

			<td align="center" valign="middle">
				<input type="button" class="button" name="add" value='&nbsp;&nbsp;&nbsp;<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Add")%> &gt;&gt;&nbsp;&nbsp;' onClick="swapdata(this.form.AllDepartment,this.form.Departments)">
			<br><input type="button" class="button" name="remove" value='<< <%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Remove")%>'
					onClick="swapdata(this.form.Departments,this.form.AllDepartment)">
			</td>

			<td bgcolor="#FFFFFF">
				<select class="formtext_fix" name="Departments" multiple size="5">
				</select>
			</td>

		</tr>
		</table>
		</td>
	</tr>

<%	}	// END if (allDept!=null) %>


<!-- start date -->
	<tr><td><img src='../i/spacer.gif' height='10' width='1'/></td></tr>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_blue" valign='top'><font color="#000000">*</font> 
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Project Start Date")%>:</td>
		<td class="tinytype">Click calendar icon to select date:<br>
			<input class="formtext" type="Text" name="StartDate" size="30" onClick="javascript:show_calendar('newProjectForm.StartDate');" onKeyDown='return false;' value='<%=todayS%>'>
			&nbsp;<a href="javascript:show_calendar('newProjectForm.StartDate');"><img src="../i/calendar.gif" border="0" align="absmiddle" alt="Click to view calendar."></a>
		</td>
	</tr>

<!-- expire date -->
	<tr><td><img src='../i/spacer.gif' height='10' width='1'/></td></tr>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_blue" valign='top'>&nbsp;&nbsp;&nbsp;
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Project Deadline")%>:</td>
		<td class="tinytype">Click calendar icon to select date:<br>
			<input class="formtext" type="Text" name="ExpireDate" value="" size="30" onClick="javascript:show_calendar('newProjectForm.ExpireDate');" onKeyDown='return false;'>
			&nbsp;<a href="javascript:show_calendar('newProjectForm.ExpireDate');"><img src="../i/calendar.gif" border="0" align="absmiddle" alt="Click to view calendar."></a>
		</td>
	</tr>

<!-- Description -->
	<tr><td><img src='../i/spacer.gif' height='10' width='1'/></td></tr>
	<tr>
		<td width="15">&nbsp;</td>
		<td valign="top" width="180" class="plaintext_blue">&nbsp;&nbsp;&nbsp;
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Project Objective")%>: </td>
		<td>
			<textarea name="Description" class='plaintext_big' style='width:550px;'
				onFocus="return doclear(this);"
				onBlur="return defaultText(this);"
				rows="4" cols="50"><%=descStr%></textarea>
		</td>
	</tr>

<!-- Project Type -->
	<tr><td><img src='../i/spacer.gif' height='10' width='1'/></td></tr>
	<tr>
		<td width="15">&nbsp;</td>
		<td valign="top" width="180" class="plaintext_blue">&nbsp;&nbsp;&nbsp;
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Project Privacy")%>: </td>
		<td class="plaintext_big">
			<input type="radio" name="ProjectOption" value="Private" checked>
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Private")%>&nbsp;&nbsp;&nbsp;&nbsp;
			<input type="radio" name="ProjectOption" value="Public">
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Public")%>&nbsp;&nbsp;&nbsp;&nbsp;
			<input type="radio" name="ProjectOption" value="Public Read-only">
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Public Read-only")%>
		</td>
	</tr>

</table>
</div>
<!-- End detailPanelDiv -->
</td></tr>


<!-- Submit Button -->
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="10ptype">
			<img src='../i/spacer.gif' width='250' height='40'/>
			<input type="Button" class='button_medium'
				value='   <%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Done")%>   ' onclick='createProjNow();'>&nbsp;
			<input type="Submit" class='button_medium' name="Submit"
				value='  <%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Add Project Plan")%> >>  ' onclick="return validation();">
			<img src='../i/spacer.gif' width='50' height='1'/>
			<input type="Button" class='button_medium'
				value='  <%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Cancel")%>  ' onclick='location="../ep/ep_home.jsp";'>&nbsp;
		</td>
	</tr>

</table>
</form>


<tr><td>&nbsp;</td><tr>


<!-- BEGIN FOOTER TABLE -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

