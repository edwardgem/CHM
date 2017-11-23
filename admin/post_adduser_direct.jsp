<%
////////////////////////////////////////////////////
//	Copyright (c) 2004-2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	post_adduser.jsp
//	Author:	ECC
//	Date:	04/22/05
//	Description:
//		Allow adding a user.
//	Modification:
//		@ECC090605	Allow regular users to submit add user request to admin.
//					What it does is to simply send a request email to admin.
//		@ECC092595	Changing this function to allow adding user in place -- not just submit
//					a request.  Even guest user can do this.
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "javax.servlet.*" %>
<%@ page import = "javax.servlet.http.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>

<%
	PstUserAbstractObject gUser = (PstUserAbstractObject)session.getAttribute("gUser");
	String home = null;

	if (gUser == null)
	{
		gUser = (PstUserAbstractObject) PstGuest.getInstance();
		home = "../index.jsp";
	}
	else
	{
		home = "../ep/ep_home.jsp";
	}

	String deptName = request.getParameter("DepartmentName");
	if (deptName != null) deptName = deptName.trim();
	String email = request.getParameter("Email").trim();
	String FirstName = request.getParameter("FirstName").trim();
	String LastName = request.getParameter("LastName").trim();
	String manager = request.getParameter("Manager");
	String [] projectIds = request.getParameterValues("SelectedProjects");

	String DEL = ":";

	// create user
	String sendEmail = request.getParameter("SendEmail");
	userManager uMgr = userManager.getInstance();
	user u = null;
	String uname = request.getParameter("UserName");
	if (uname==null || uname.length()==0)
		uname = FirstName.toLowerCase().charAt(0) + LastName.toLowerCase();
	String pass = uname;
	try
	{
		// attempt to create, might be duplicate and bomb out
		u = (user)uMgr.create(gUser, uname, pass);
		u.setAttribute("FirstName", FirstName);
		u.setAttribute("LastName", LastName);
		u.setAttribute("Email", email);
		u.setAttribute("DepartmentName", deptName);
		u.setAttribute("Supervisor1", manager);
		uMgr.commit(u);

		// create userinfo
		userinfoManager uiMgr = userinfoManager.getInstance();
		userinfo ui = (userinfo)uiMgr.create(gUser, String.valueOf(u.getObjectId()));

		//accountManager aMgr = accountManager.getInstance();
		//account acct = (account)aMgr.create(gUser, String.valueOf(u.getObjectId()));
		//acct.setAttribute("Balance", new Double(MARKETING_COST));
		//acct.setAttribute("Credit", new Double(MARKETING_COST));		// the Balance amount is actuall Credit

		//ui.setAttribute("LastLogin", new Date());
		ui.setAttribute("Preference", "BlogCheck:Mon");
		uiMgr.commit(ui);
	}
	catch (Exception e)
	{
		e.printStackTrace();
		response.sendRedirect("../out.jsp?msg=Error in creating new user [" + FirstName + " " + LastName + "]");
		return;
	}

	// add project membership
	if (projectIds != null && projectIds.length > 0)
	{
		Integer uidO = new Integer(u.getObjectId());
		projectManager pjMgr = projectManager.getInstance();
		for (int i=0; i<projectIds.length; i++)
		{
			project pj = (project)pjMgr.get(gUser, Integer.parseInt(projectIds[i]));
			pj.appendAttribute("TeamMembers", uidO);
			pjMgr.commit(pj);
		}
	}

	// send an email to the new user
	String s;
	if (sendEmail != null)
	{																				String MAILFILE = "alert.htm";
		String FROM = Util.getPropKey("pst", "FROM");
		String NODE = Util.getPropKey("pst", "PRM_HOST");
		String CO_NAME = Util.getPropKey("pst", "COMPANY_NAME");
		s = Prm.getAppTitle();
		String subj = "[" + s + "] Welcome to " + CO_NAME + " " + s;
		String msg= "A new " + s + " user account has been created for you.  Please use the following Username and Temporary Password to login:";
		msg += "<blockquote>Username: <b>" + uname;
		msg += "</b><br>Password: <b>" + pass;
		msg += "</b></blockquote>On your first login you would be asked to change your password.  A valid password is 6-12 characters long with at least one numeric and one alphabet characters. ";
		msg += "Depending on your browser settings, after changing password, you may need to close the window and login again.";
		msg += "<br><br>Please click this link to login:&nbsp;&nbsp;";
		msg += "<b><a href='" + NODE + "'>" + NODE + "</a></b>";

		Util.sendMailAsyn(gUser, FROM, email, null, null, subj, msg, MAILFILE);
	}

%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="../init.jsp" flush="true" />

<title>
	New User Registration
</title>

</head>

<body text="#000000" leftmargin="10" topmargin="10" marginwidth="0" marginheight="0">

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="715" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<b class="head">

	New User Registration Completed

	</b><br><br>
	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- CONTENT -->
<table>
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan="2" class="plaintext_big"><br>
		Your new user registration has been completed sucessfully.  Once the processing is done, the
		new user will receive a notification email with login instructions on it.
		<br><br>

		Thank you for using <%=Util.getPropKey("pst", "APPLICATION")%>!

<p align="center">
<a href="<%=home%>" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('homeBtn','','../i/homen.gif',1)"><img src="../i/homef.gif" border="0" name="homeBtn"></a>
</p>
		</td>
	</tr>

<tr><td>&nbsp;</td><tr>
</table>



<table width="100%">
<!-- BEGIN FOOTER TABLE -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>
