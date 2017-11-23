<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
////////////////////////////////////////////////////
//	Copyright (c) 2004-2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	adduser.jsp
//	Author:	ECC
//	Date:	04/22/04
//	Description:
//		Allow admin to add a user.
//	Modification:
//		@SWS060106	added display assigned user name without space in last name for admin
//		@ECC071906	Support multiple companies using PRM together.
//		@SWS082306  Filter unused item for OMF, added input for simple version to registration.
//		@ECC060407	Support more flexible attachment authorization using department name combination.
//		@ECC060707	For OMF, allow admin to assign companies to a new user.
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>
<%@ page import = "util.*" %>
<%@ page import = "net.tanesha.recaptcha.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	String HOST	= Prm.getPrmHost();
	String title = "Sign-up Now";

	PstUserAbstractObject gUser = (PstUserAbstractObject)session.getAttribute("pstuser");
	boolean isLogin = false;
	boolean isAdmin = false;
	boolean isAcctMgr = false;
	boolean isProgMgr = false;

	String s;
	boolean isMultiCorp = Prm.isMultiCorp();
	boolean isSecureHost = Prm.isSecureHost();
	String HOST_COMPANY = Prm.getCompanyName();

	boolean isMeetWE = Prm.isOMF();
	boolean isCRAPP = Prm.isCR();
	boolean isPRMAPP = Prm.isPRM();
	if (isMeetWE) {
		title = "Join MeetWE";
	}

	boolean isAuto = false; // check if auto approval turn on
	String autoApprove = "";
	autoApprove = Util.getPropKey("pst", "NEW_USER_AUTO_APPROVAL");
	if (autoApprove != null && autoApprove.equals("true"))
		isAuto = true;

	s = Util.getPropKey("pst", "USERNAME_EMAIL");
	boolean isEmailUsername = s!=null && s.equalsIgnoreCase("true");
	
	boolean bAutoGenPassword = true;

	userManager uMgr = userManager.getInstance();
	userinfoManager uiMgr = userinfoManager.getInstance();
	townManager tnMgr = townManager.getInstance();

	String company = request.getParameter("company");		// admin might have selected a company
	String selectedCompName = "";
	PstAbstractObject o;
	userinfo ui = null;
	String myUidS = null;

	if (company != null)
	{
		o = tnMgr.get(gUser, Integer.parseInt(company));
		selectedCompName = (String)o.getAttribute("Name")[0];
	}

	if (gUser == null)
	{
		//if (!(isCRAPP && isMultiCorp))
		//	gUser = (PstUserAbstractObject) PstGuest.getInstance();
		// for CR Multicorp, do not allow outsider to adduser
		/*if (isCRAPP && isMultiCorp)
		{
			response.sendRedirect("../out.jsp?msg=Please contact EGI Technologies at <a href='mailto:info@egiomm.com'>info@egiomm.com</a> to get a user account");
			return;
		}*/
	}
	else
	{
		if (gUser instanceof PstGuest)
		{
			// for CR Multicorp, do not allow outsider to adduser
			// gUser is from Search: remove the pstuser from session
			session.removeAttribute("pstuser");
			gUser = null;
		}
		else
		{
			isLogin = true;
			myUidS = String.valueOf(gUser.getObjectId());

			// check admin
			int iRole = ((Integer)session.getAttribute("role")).intValue();
			if ( (iRole & user.iROLE_ADMIN) > 0 )
			{
				isAdmin = true;
				title = "Add a New User";
			}
			if ( (iRole & user.iROLE_ACCTMGR) > 0 )
				isAcctMgr = true;
			if ((iRole & user.iROLE_PROGMGR) > 0)
				isProgMgr = true;
			ui = (userinfo)uiMgr.get(gUser, myUidS);
		}
		
		// check to see if I have reached my max create user limit
		if (isMultiCorp) {
			// the limit is stored in my company
			town myTown = ((user)gUser).getUserTown();
			if (myTown!=null && myTown.isReachLimit(town.MAX_USER)) {
				response.sendRedirect("../out.jsp?msg=5003&go=info/upgrade.jsp");
				return;
			}
			if (myTown == null) {
				System.out.println("!!!!!! adduser.jsp found user [" + gUser.getObjectId() + "] has NO TownID or Company.");
			}
		}
	}

	String msg = request.getParameter("msg");
	if (msg == null) msg = "";

	String req = request.getParameter("req");	// Email param
	String fName = "";
	String lName = "";
	String uName = "";
	String eMail = "";
	String deptName = "";
	String pass = "";  // @SWS082306
	String rPass = "";

	int mgrId = 0;
	int [] selectedPjs = new int[0];
	if (req != null)
	{
		// approving new user request email
		if (!isAdmin && !isAuto)
		{
			response.sendRedirect("../out.jsp?msg=You must logon as administrator to approve for new user request&go=index.jsp");
			return;
		}

		// 0.email:1.firstName:2.lastName:3.auth_Depts:4.managerId:5.projIds
		// req = email : FirstName : LastName : deptName : manager : pid,pid,pid : senderId for CR and PRM
		// req = email : FirstName : LastName : UserName : Password : Re-type Password : senderId for OMF
		String [] sa = req.split(":");
		if (sa.length < 6) {
			response.sendRedirect("../out.jsp?msg=The request Email [" + req + "] is missing some parameters.");
			return;
		}

		eMail = sa[0];
		fName = sa[1];
		lName = sa[2];
		if (!isMeetWE)
		{
			// CR/PRM
			uName = fName.toLowerCase().charAt(0) + lName.toLowerCase().replaceAll(" ", "");	//@SWS060106
			deptName = sa[3];
			s = sa[4];
			if (s.length() > 0) {
				try {mgrId = Integer.parseInt(s);}
				catch (Exception e) {}	// might be "null" for deleted manager
			}

			// proj ids
			if (sa[5].length() > 0)
			{
				String [] saa = sa[5].split(",");
				selectedPjs = new int[saa.length];
				for (int i=0; i<saa.length; i++)
					selectedPjs[i] = Integer.parseInt(saa[i]);
			}
		}
		else if (!isAuto) // @SWS082306
		{
			uName = sa[3];
			pass = sa[4];
			rPass = sa[5];
		}
		else
			uName = sa[3];
	}

%>


<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen" />
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print" />
<jsp:include page="../init.jsp" flush="true" />
<jsp:include page="../forms.jsp" flush="true"/>
<script language="JavaScript" src="../validate.js"></script>

<script language="JavaScript">
<!--
window.onload = function()
{
	if (AddUser.Email) {
		AddUser.Email.focus();
	}
	changeTerms();
}

function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

function validation()
{
	var f = document.AddUser;
	
	// check term of use
	var e = f.Terms;
	if (e != null) {
		if (!e.checked) {
			fixElement(f.Terms,
					"You must accept the Terms of Use to proceed.");
			return false;
		}
	}

	// authorized department
	e = f.Departments;
	if (e != null)
	{
		getall(e);
	}
	
	// company name
	var companyNameField = f.NewCompanyName;
	if (companyNameField != null) {
		var companyName = trim(companyNameField.value);
		companyNameField.value = companyName;
		if (companyName == '') {
			fixElement(f.companyNameField,
				"Please make sure the COMPANY NAME field is properly completed.");
			return false;
		}
	}

	var email = trim(f.Email.value);
	f.Email.value = email;
	if (email =='')
	{
		fixElement(f.Email,
			"Please make sure the EMAIL field is properly completed.");
		return false;
	}
	if ((email.indexOf('@') == -1) ||
		(email.indexOf('.') == -1))
	{
		fixElement(f.Email,
			"Please make sure to enter a valid EMAIL address (e.g. xxx@gmail.com).");
		return false;
	}

	for (i=0;i<email.length;i++) {
		char = email.charAt(i);
		if (char == '\\') {
			fixElement(f.Email,
				"EMAIL cannot contain these characters: \n  \\");
			return false;
		}
	}

	e = f.FirstName;
	if (e != null)
	{
		var firstName = trim(e.value);
		e.value = firstName;

		if (foundBadChar(firstName))
		{
			fixElement(e,
				"FIRST NAME cannot contain these characters: \n  \" \\ ~ ` ! # $ % ^ * ( ) + = [ ] { } |  ? > <");
			return false;
		}
	}

	e = f.LastName;
	if (e != null)
	{
		var lastName = trim(e.value);
		e.value = lastName;

		if (foundBadChar(lastName))
		{
			fixElement(e,
				"LAST NAME cannot contain these characters: \n  \" \\ ~ ` ! # $ % ^ * ( ) + = [ ] { } |  ? > <");
			return false;
		}
	}

	e = f.UserName;
	if (e != null)
	{
		var userName = trim(e.value);
		e.value = userName;
		
		if (userName == '')
		{
			fixElement(e,
				"Please make sure that the USER NAME field is properly completed.");
			return false;
		}

		if (foundBadChar(userName))
		{
			fixElement(e,
				"USERNAME cannot contain these characters: \n  \" \\ ~ ` ! # $ % ^ * ( ) + = [ ] { } |  ? > <");
			return false;
		}
		return false;
	}

	e = f.SelectedProjects;
	if (e != null)
		getall(e);

	if (!<%=bAutoGenPassword%>) {
		e = f.newPass;
		if (e!=null && e.value =='')
		{
			fixElement(e,
				"Please make sure that the PASSWORD field is properly completed.");
			return false;
		}
	
		if (e != null)
		{
			var passVal = f.newPass.value;
			if (<%=isAdmin%>==false && passVal.length < 6)
			{
				fixElement(f.newPass,
					"Please make sure that the PASSWORD is at least 6 characters long.");
				return false;
			}
			else if (passVal.length > 12)
			{
				fixElement(f.newPass,
					"Please make sure that the PASSWORD is at most 12 characters long.");
				return false;
			}
			else if (passVal.length>0 && passVal != f.rePass.value)
			{
				fixElement(f.newPass,
					"Please make sure PASSWORD and RETYPE PASSWORD are the same.");
				return false;
			}
			else if (<%=isAdmin%>==false && passVal.length>0 && !hasAlpha(passVal))
			{
				fixElement(f.newPass,
					"Please make sure that the PASSWORD has at least one alphabet character in it.");
				return false;
			}
			/*else if (<%=isAdmin%>==false && passVal.length>0 && !hasNum(passVal))
			{
				fixElement(f.newPass,
					"Please make sure that the PASSWORD has at least one numeric character in it.");
				return false;
			}*/
		}
	}	// END if !bAutoGenPassword

	if (<%=isAdmin%>==true)
		getall(f.Company);

	return;
}

function addCompany(e1, e2)
{
	swapdata(e1, e2);
	if (<%=isAdmin%>==true && e2.length > 0)
		location = "adduser.jsp?company=" + e2.options[0].value;
}

function delCompany(e1, e2)
{
	swapdata(e1, e2);
	if (<%=isAdmin%>==true && e1.length <= 0)
		location = "adduser.jsp";
}

function changeTerms()
{
	//AddUser.SubmitBut.disabled = !AddUser.Terms.checked;
}
//-->
</script>

<title>
	Add New User
</title>

</head>

<body text="#000000" leftmargin="10" topmargin="10" marginwidth="0" marginheight="0">

<form name="AddUser" method="post" action="post_adduser.jsp">

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="715" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td><img src='../i/spacer.gif' width='20'/></td>
	<td valign="top">
	<b class="head">
		<%=title%>
	</b><br><br>
	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="/i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- CONTENT -->
<table border="0">

<%	if (!StringUtil.isNullOrEmptyString(msg)) { %>
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="plaintext"><font color="#aa0000">
		<%=msg%></font></td>
	</tr>
<%	}
%>

	<tr><td><img src='../i/spacer.gif' height='10' width='1'/></td></tr>
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2>
		<div class="instruction_head">Please enter the information below</div><br/>
		<div class='instruction'>(Note that fields marked with an * are required)</div><br/></td>
	</tr>


<%
	if (!isMeetWE) // @SWS082306
	{
		String [] allDept = null;
		String [] myDepts = null;
		s = null;
		if (isCRAPP && isMultiCorp)
		{
			// @ECC080108 check for company specific authorization departments
			if (!isAdmin && gUser!=null)
				company = (String)gUser.getAttribute("Company")[0];
			if (company != null)
			{
				//response.sendRedirect("adduser.jsp?company=");
				o = tnMgr.get(gUser, Integer.parseInt(company));
				s = (String)o.getAttribute("DepartmentName")[0];
			}
		}
		if (s == null)
			s = Util.getPropKey("pst", "DEPARTMENTS");
		if (s != null) allDept = s.split(";");
		// @ECC060407
		if (allDept!=null && deptName!=null && deptName.length()>0)
		{
			for (int i=0; i<allDept.length; i++)
			{
				allDept[i] = allDept[i].trim();
				if (deptName.indexOf(allDept[i]) != -1)
					allDept[i] = null;		// this is already selected as a department, ignored
			}
		}
		if (deptName.length() > 0)
			myDepts = deptName.split("@");

	// company
	boolean bShowAllTowns = false;
	if ((isAdmin || isProgMgr || isAcctMgr) && (isMeetWE || (!isMeetWE && isMultiCorp)) )
	{
		// @ECC060707
		// OMF Admin can add companies (towns) -->
		bShowAllTowns = true;

			// all towns in system
			int [] id = null;
			
			if (isAdmin || isAcctMgr)
				id = tnMgr.findId(gUser, "om_acctname='%'");
			else {
				// for PM, get all towns that he is PM
				id = tnMgr.findId(gUser, "Chief='" + gUser.getObjectId() + "'");
				//id = Util2.toIntArray(gUser.getAttribute("Towns"));
			}
			PstAbstractObject [] tnObjArr = tnMgr.get(gUser, id);
%>

		<tr>
			<td width="15">&nbsp;</td>
			<td class="formtext_blue" width="180" valign='top'>&nbsp;&nbsp;&nbsp;Company Name: </td>
			<td>
			<table border="0" cellspacing="4" cellpadding="0">
			<tr>
				<td bgcolor="#FFFFFF">
				<select class="formtext_fix" name="AllCompany" multiple size="5">
		<%			if (tnObjArr != null)
				for (int i=0; i<tnObjArr.length; i++)
				{
					if (tnObjArr[i] == null) continue;		// ignored
					if (isAdmin && company!=null && tnObjArr[i].getObjectId() == Integer.parseInt(company))
						continue;	// selected already
					s = (String)tnObjArr[i].getAttribute("Name")[0];
					out.print("<option value='" + tnObjArr[i].getObjectId() + "'");
					out.print(">" + s + "</option>");
				}
		%>
				</select>
				</td>

				<td align="center" valign="middle">
					<input type="button" class="button" name="add" value="&nbsp;&nbsp;&nbsp;Add &gt;&gt;&nbsp;&nbsp;" onClick="addCompany(this.form.AllCompany,this.form.Company)">
				<br><input type="button" class="button" name="remove" value="<< Remove" onClick="delCompany(this.form.Company,this.form.AllCompany)">
				</td>

				<td bgcolor="#FFFFFF">
					<select class="formtext_fix" name="Company" multiple size="5">
					<%if (company!=null) out.print("<option value='" + company + "'>" + selectedCompName + "</option>");%>
					</select>
				</td>

			</tr>
			</table>
			</td>
		</tr>
<%
	}	// end if OMFAPP || isMultiCorp (PRM/CR) - for Admin to specify which company to create this user
	
	// CPM need company name to register
	else if (isPRMAPP && isMultiCorp && !isLogin) {
		/*
		out.print("<tr><td></td>");
		out.print("<td class='formtext_blue' width'180' valign='top'><font color='#000000'>*</font> Company Name: </td>");
		out.print("<td><input type='text' name='NewCompanyName' value='' class='ptextS1' style='width:300px;'>");
		out.print("</td></tr>");
		*/
		out.print("<input type='hidden' name='NewCompanyName' value='" + HOST_COMPANY + "'>");
	}


	if (gUser != null) {
		// this is coming from a login user (to approve for new user) or Admin
		
		// company name
		if (!bShowAllTowns) {
			if (StringUtil.isNullOrEmptyString(selectedCompName)) {
				// get company name from user
				String townIdS = gUser.getStringAttribute("Company");
				if (townIdS == null) {
					townIdS = gUser.getStringAttribute("TownID");
					if (townIdS != null) {
						gUser.setAttribute("Company", townIdS);
						uMgr.commit(gUser);
					}
				}
				if (!StringUtil.isNullOrEmptyString(townIdS)) {
					town tnObj = (town)tnMgr.get(gUser, Integer.parseInt(townIdS));
					selectedCompName = tnObj.getStringAttribute("Name");
				}
				else {
					selectedCompName = Prm.getCompanyName();
				}
			}
			out.println("<tr><td></td>");
			out.print("<td class='formtext_blue'>&nbsp;&nbsp;&nbsp;Company Name: </td>");
			out.print("<td class='ptextS1'>&nbsp;" + selectedCompName + "</td>");
			out.print("</tr>");
			out.print("<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>");
		}

%>

<!-- division name -->
<!-- @ECC060407 support combination of departments -->
<%	if (allDept != null) {%>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="formtext_blue" width="180" valign='top'>&nbsp;&nbsp;&nbsp;Authorized Doc Type: </td>
		<td>
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
<%	} %>


<!-- ********************** projects ********************** -->
<%

		projectManager pjMgr = projectManager.getInstance();
		PstAbstractObject [] projectList = null;
		int ids [] = new int[0];
		if (isMultiCorp)
		{
			if (!isAdmin)
				s = (String)gUser.getAttribute("Company")[0];
			else
				s = request.getParameter("company");
			if (s != null) {
				// in case some old project has null Company but use TownID
				//ids = pjMgr.findId(gUser, "Company='" + s + "' || TownID='" + s + "'");
				ids = pjMgr.getProjects(gUser, false);	// not closed project
			}
		}
		else
			ids = pjMgr.findId(gUser, "om_acctname='%'");
		projectList = pjMgr.get(gUser, ids);
		Util.sortName(projectList, true);
%>

<tr>
		<td width="15">&nbsp;</td>
		<td class="formtext_blue" width="180" valign='top'>&nbsp;&nbsp;&nbsp;Authorized Project:</td>
		<td>
		<table border="0" cellspacing="4" cellpadding="0">
		<tr>
			<td>
			<select class="formtext_fix" name="AllProjects" multiple size="5">
<%
		if (projectList != null && projectList.length > 0)
		{
			boolean found;
			project pj;
			for (int i=0; i < projectList.length; i++)
			{
				found = false;
				pj = (project)projectList[i];
				if (!myUidS.equals(pj.getStringAttribute("Owner"))) {
					continue;			// only allow granting projects that I am owner
				}
					
				for (int j=0; j<selectedPjs.length; j++)
				{
					if (pj.getObjectId() == selectedPjs[j])
					{
						found = true;
						break;
					}
				}
				if (found) continue;
%>
			<option value="<%=pj.getObjectId() %>"><%=pj.getDisplayName()%></option>
<%
			}
		}
%>
			</select>
			</td>
			<td align="center" valign="middle" class="formtext">
				<input type="button" class="button" name="add" value="&nbsp;&nbsp;&nbsp;Add &gt;&gt;&nbsp;&nbsp;" onClick="swapdata(this.form.AllProjects,this.form.SelectedProjects)"/>
			<br/><input type="button" class="button" name="remove" value="<< Remove" onclick="swapdata(this.form.SelectedProjects,this.form.AllProjects)"/>
			</td>
<!-- child towns selected -->
			<td>
				<select class="formtext_fix" name="SelectedProjects" id="SelectedProjects" multiple size="5">
<%		for (int i=0; i<selectedPjs.length; i++)
		{
			project pj = (project)pjMgr.get(gUser, selectedPjs[i]);
			out.print("<option value='" + selectedPjs[i] + "'>" + pj.getDisplayName() + "</option>");
		}
%>
				</select>
			</td>
		</tr>
		</table>
</td>
</tr>
<!-- end of children town -->
<%
}	// end if gUser!=null
	} // end of if !OMFAPP
%>


	<tr><td><img src='../i/spacer.gif' height='5'/></td></tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="formtext_blue"><font color="#000000">*</font> Email: </td>
		<td>
			<input type="text" name="Email" value="<%=eMail%>" class='ptextS1' style='width:300px;'/>
		</td>
	</tr>

<%
	if (!isMultiCorp && !isMeetWE)
	{
%>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="formtext_blue">&nbsp;&nbsp; First Name: </td>
		<td>
		<input type="text" name="FirstName" value="<%=fName%>" class='ptextS1'  style='width:300px;'/>
		</td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="formtext_blue">&nbsp;&nbsp; Last Name: </td>
		<td>
			<input type="text" name="LastName" value="<%=lName%>" class='ptextS1'  style='width:300px;'/>
		</td>
	</tr>
<%
		out.print("<tr><td><img src='../i/spacer.gif' height='5'/></td></tr>");
	}	// END if !isMultiCorp


	if (isAdmin || isMeetWE || !isEmailUsername){%>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="formtext_blue"><font color="#000000">*</font> Username: </td>
		<td>
			<input type="text" name="UserName" value="<%=uName%>" class='ptextS1' style='width:300px;'/>
		</td>
	</tr>
<%	}
	if (!bAutoGenPassword && (isMeetWE || gUser==null)) { %>
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan="2" class="instruction">
		<br/>A valid password must be between 6 to 12 characters long.
			<!-- with at least one alphabet and one numeric characters in it -->
			<br/></td>
	</tr>

	<tr>
		<td width="50">&nbsp;</td>
		<td class="formtext_blue"><font color="#000000">*</font> Password:</td>
		<td>
<%		if (!isAuto){ %>
			<input type="password" name="newPass" value="<%=pass%>" class='formtext' style='width:300px;'/>
<%		}
		else {%>
			<input type="password" name="newPass" class='formtext' style='width:300px;'/>
<%		} %>
		</td>
	</tr>

	<tr>
		<td></td>
		<td class="formtext_blue"><font color="#000000">*</font> Re-type Password:</td>
		<td>
<% 		if (!isAuto){ %>
			<input type="password" name="rePass" value="<%=rPass%>" class='formtext' style='width:300px;'/>
<%		}
		else {%>
			<input type="password" name="rePass" class='formtext' style='width:300px;'/>
<%		} %>
		</td>
	</tr>

<%
		if (isSecureHost)
		{
			// recaptcha
			String pubK = Util.getPropKey("pst", "C_PUBLIC");
			String priK = Util.getPropKey("pst", "C_PRIVATE");

			ReCaptcha captcha = ReCaptchaFactory.newReCaptcha(pubK, priK, false);
			String captchaScript = captcha.createRecaptchaHtml(request.getParameter("error"), null);
			out.print("<tr><td></td><td colspan='2'>");
			out.print("<table><tr><td><img src='../i/spacer.gif' height='20' width='220' /></td><td>");
			out.print(captchaScript);
			out.print("</table></td></tr>");
		}

	}	// END if (bAutoGenPassword && (isMeetWE || gUser==null))

		
	out.print("<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>");

	/////////////////////////////////////////////////////////
	// Time Zone
	// ECC: no need to ask timezone here because we will ask when user successfully sign in
	// see post_updperson.jsp

	if (!isMeetWE && gUser!=null)
	{
%>

	<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>
	
	<tr>
		<td width="15">&nbsp;</td>
		<td class="formtext_blue">&nbsp;&nbsp;&nbsp;Manager: </td>
		<td>
		<select class="formtext" name="Manager" style='width:300px;'>
		<option value="">- select Manager -
<%
	//PstAbstractObject [] allMember = ((user)gUser).getAllUsers();

	int allEmpIds[] = null;
	if (isMultiCorp) {		
		allEmpIds = uMgr.findId(gUser, "Company='" + (String)gUser.getStringAttribute("Company") + "'");
	}
	else {
		allEmpIds = uMgr.findId(gUser, "om_acctname='%'");
	}
	PstAbstractObject [] allMember = uMgr.get(gUser, allEmpIds);

	// sort the user list for owner assignment
	Util.sortUserArray(allMember, true);

	user u;
	int id;

	for(int i=0; i < allMember.length; i++)
	{
		if (allMember[i]==null || allMember[i].getStringAttribute("FirstName")==null)
			continue;
		u = (user)allMember[i];
		id = u.getObjectId();
		out.print("<option value='" + id + "'");
		if (id == mgrId) out.print(" selected");
		out.println(">" + u.getFullName() + "</option>");
	}
%>
		</select>
		</td>
	</tr>

<%	}

	if (isAdmin) {%>
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan='2' class="formtext_blue">
			&nbsp;&nbsp;<input type="checkbox" name="SendEmail" checked />Send Email notification to new user
		</td>
	</tr>
<%	}

	String backBut;
	if (gUser == null)
		backBut = "javascript:location='" + HOST + "/index.jsp';";
	else if (isAdmin)
		backBut = "javascript:location='" + HOST + "/admin/admin.jsp';";
	else
		backBut = "javascript:location='" + HOST + "/ep/ep_home.jsp';";
			
%>

	<tr>
		<td></td>
        <td colspan='2' align="left" class="formtext_blue">
          	<input type="checkbox" name="Terms" onchange='changeTerms();' />
        	<font color="#336699">I accept <a href='../info/terms_omf.jsp'>the terms of use</a></font>
        </td>
	</tr>
	
	
	<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>

<!-- Submit Button -->
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="10ptype">
				<img src='../i/spacer.gif' width='280' height='15' />
			<input type="submit" class='button_medium' name="SubmitBut" value="  Submit  "  onclick="return validation();"/>&nbsp;
<%	if (isLogin) {%>
			<input type="submit" class='button_medium' name="AddMore" value="Add more user" onclick="return validation();"/>
<%	}%>
				<img src='../i/spacer.gif' width='30' height='1' />
			<input type="button" class='button_medium' value="   Cancel   " onclick="<%=backBut%>" />
		</td>
	</tr>

</table>


<tr><td>&nbsp;</td><tr>


<!-- BEGIN FOOTER TABLE -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</form>

</body>
</html>

