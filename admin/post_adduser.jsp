<%
////////////////////////////////////////////////////
//	Copyright (c) 2004-2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	post_adduser.jsp
//	Author:	ECC
//	Date:	04/22/05
//	Description:
//		Adding a user, either by Admin or by registration to the website. Also see post_add_member.jsp.
//
//	Modification:
//		@ECC090605	Allow regular users to submit add user request to admin.
//					What it does is to simply send a request email to admin.
//		@ECC071906	Support multiple companies using PRM together.
//		@AGQ081606	Converts all GuestEmail to User Id for this new user
//		@SWS082506  Simplify create account process for OMF
//					Detect used user name and return with a meaningful message in auto approval mode.
//		@ECC121306	Set user town by comparing user email with town domain.
//		@ECC060407	Support more flexible attachment authorization using department name combination.
//		@ECC060707	For OMF, allow admin to assign companies to a new user.
//		@ECC062607	Support other apps (e.g. CR) calling OMF to set up new account
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
<%@ page import = "net.tanesha.recaptcha.*" %>
<%@ page import = "org.apache.log4j.Logger" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	Logger l = PrmLog.getLog();
	String HOST = Prm.getPrmHost();

	// recaptcha
	/*
	String pubK = Util.getPropKey("pst", "C_PUBLIC");
	String priK = Util.getPropKey("pst", "C_PRIVATE");
	ReCaptcha captcha = ReCaptchaFactory.newReCaptcha(pubK, priK, false);
	ReCaptchaResponse resp = captcha.checkAnswer(request.getRemoteAddr(), request.getParameter("recaptcha_challenge_field"), request.getParameter("recaptcha_response_field"));

	if (!resp.isValid())
	{
		response.sendRedirect("../out.jsp?msg=Error authenticating image text.  Please try again.&go=admin/adduser.jsp");
		return;
	}
	*/

	boolean isLogin = false;
	boolean isAdmin = false;
	String new_user = null;
	String home = null;
	String msgS = "added user successfully";
	String s = null;
	String FirstName = "";
	String LastName = "";
	userManager uMgr = userManager.getInstance();
	townManager tnMgr = townManager.getInstance();

	boolean isOMFAPP = Prm.isOMF();
	boolean isCRAPP = Prm.isCR();
	boolean isPRM = Prm.isPRM();

	// @ECC080108 Multiple company
	boolean isMultiCorp = Prm.isMultiCorp();
	String HOST_COMPANY = Prm.getCompanyName();
	
	s = Util.getPropKey("pst", "CREATE_PERSONAL_PROJECT");
	boolean isCreatePersonalSpace = s!=null && s.equalsIgnoreCase("true");

	// @SWS082506
	boolean isAuto = false; // check if auto approval turn on
	String autoApprove = "";
	autoApprove = Util.getPropKey("pst", "NEW_USER_AUTO_APPROVAL");
	if (autoApprove != null && autoApprove.equals("true"))
		isAuto = true;

	boolean isGuest = false;
	PstUserAbstractObject gUser = (PstUserAbstractObject)session.getAttribute("pstuser");
	if (gUser == null || (gUser instanceof PstGuest))
	{
		gUser = (PstUserAbstractObject) PstGuest.getInstance();
		isGuest = true;
		new_user = "you";
		home = "../index.jsp";
	}
	else
	{
		isLogin = true;
		new_user = "the new user";
		home = "../ep/ep_home.jsp";

		if (session.getAttribute("role") != null)
		{
			// check admin
			int iRole = ((Integer)session.getAttribute("role")).intValue();
			if ( (iRole & user.iROLE_ADMIN) > 0 )
				isAdmin = true;
		}
	}

	String DEL = ":";
	
	// @ECC062607 support other apps (e.g. CR) calling OMF to set up account
	String extern = request.getParameter("Extern");

	String email = request.getParameter("Email").trim();
	String uname = request.getParameter("UserName"); // @SWS082506
	String next = request.getParameter("goto");
	String terms = request.getParameter("Terms");
	String mid = request.getParameter ("mid");
	String manager = request.getParameter("Manager");
	String [] projectIds = request.getParameterValues("SelectedProjects");

	String pass = request.getParameter("newPass");
	if (pass == null) pass = "";
	//String rePass = request.getParameter("rePass");

	s = null;
	Object [] comArr = request.getParameterValues("Company");
	if (comArr==null && isMultiCorp && !isGuest) {
		s = (String)gUser.getStringAttribute("Company");
	}
	else if (!Prm.isMeetWE()) {		// removed !isMultiCorp && 
		// just one company
		s = Prm.getCompanyName();
		try {s = String.valueOf(tnMgr.get(gUser, s).getObjectId());}
		catch (Exception e)
		{
			s = "Fail to get company (town) [" + s + "] from PRM in post_adduser.jsp";
			l.error(s);
			response.sendRedirect("../out.jsp?msg=" + s);
			return;
		}
	}
	if (s != null)
	{
		comArr = new Object [1];
		comArr[0] = s;
	}

	String circles = request.getParameter("circle");
	if (circles!=null && circles.length()<=0) circles = null;

	// @ECC060407
	String deptName = "";
	String [] deptNames = request.getParameterValues("Departments");
	if (deptNames==null || deptNames.length<=0) deptName = "";
	else for (int i = 0; i<deptNames.length; i++)
	{
		if (deptName.length() > 0) deptName += "@";
		deptName += deptNames[i].trim();
	}

	if (!isOMFAPP || isAdmin)
	{
		s = request.getParameter("FirstName");
		if (s==null || s.length()<=0)
			FirstName = email.substring(0, email.indexOf('@'));
		else
		{
			FirstName = s.substring(0,1).toUpperCase();
			if (s.length() > 1) FirstName += s.substring(1);
		}

		s = request.getParameter("LastName");
		if (s!=null && s.length()>0)
		{
			LastName = s.substring(0,1).toUpperCase();
			if (s.length() > 1) LastName += s.substring(1);
		}
	}
	else
	{
		// isOMFAPP && !isADMIN && !external caller
		FirstName = uname;
		LastName = "";				// ECC: it was "?";
		if (extern == null)
		{
			String req;

			// check to see if there is a duplicate email address
			int [] ids = uMgr.findId(gUser, "Email='" + email + "'");
			if (ids.length > 0)
			{
				// Email already exist, advise user to use forget password.
				req = uname + DEL + email + DEL + gUser.getObjectId();
				msgS = "The EMAIL address you provide already has a user account on MeetWE.";
					msgS += "If you have forgotten your username or password, click ";
					msgS += "<a href='ep/passwd_help.jsp?email=" + email + "'><b>Forgot Password</b></a> ";
					msgS += "to receive your old username and password.";
				response.sendRedirect("../login_omf.jsp?&goto=" + next + "&req=" + req + "&msg=" + msgS + "&mid=" + mid + "&terms=on&status=new");
				return;
			}
			if (uname!=null && (uname.length()<5 || uname.length()>15) )
			{
				req = uname + DEL + email + DEL + gUser.getObjectId();
				msgS = "<b>The USERNAME must be between 5 to 15 characters long.</b>";
				response.sendRedirect("../login_omf.jsp?&goto=" + next + "&req=" + req + "&msg=" + msgS + "&mid=" + mid + "&terms=on&status=new" );
				return;
			}

			if (terms == null)
			{
				req = uname + DEL + email + DEL + gUser.getObjectId();
				msgS = "<b>You must check to accept the terms of use in order to proceed further.</b>";
				response.sendRedirect("../login_omf.jsp?&status=new&goto=" + next + "&req=" + req + "&mid=" + mid + "&msg=" + msgS);
				return;
			}
		}
	}

	// @ECC090605 Submit add user request
	String MAILFILE = "alert.htm";
	String FROM = null;
	String subj, msg;
	String addMore = request.getParameter("AddMore");

	if (!isAdmin && !isAuto)
	{
		// need approval
		String req = "";
		if (!isOMFAPP)
		{
			if (projectIds != null)
			{
				for (int i=0; i<projectIds.length; i++)
				{
					if (req.length() > 0) req += ",";
					req += projectIds[i];
				}
			}
			req = email + DEL + FirstName + DEL + LastName + DEL
				+ deptName + DEL + manager + DEL + req + DEL + gUser.getObjectId();
		}
		else
		{ // @SWS082506
			//req = email + DEL + FirstName + DEL + LastName + DEL
			//+ uname + DEL + pass + DEL + rePass + DEL + gUser.getObjectId();
			req = uname + DEL + email + DEL + gUser.getObjectId();
			if (circles != null)
				req += DEL + circles;
		}

		// create the request email to admin
		if (isLogin)
			FROM = (String)gUser.getAttribute("Email")[0];
		else
			FROM = email;
		String TO = Util.getPropKey("pst", "FROM");
		subj = "[" + Prm.getAppTitle() + " New User Request] " + FirstName + " " + LastName;
		msg= "Please click on the following to approve the new user request<blockquote>";
		msg += "<a href='" + HOST + "/admin/adduser.jsp?req=" + req + "'>" + FirstName + " " + LastName + "</a></blockquote>";
		Util.sendMailAsyn(gUser, FROM, TO, null, null, subj, msg, MAILFILE);

		if (addMore != null)
		{
			if (!isOMFAPP)
				response.sendRedirect("adduser.jsp?msg=New user request submitted successfully");
			else
				response.sendRedirect("../login.jsp");
			return;
		}
	}
	
	/////////////////////////////////////////////
	// this is CPM Multicorp Auto create user
	else
	{
		// isAdmin or isAuto: actually create user
		String sendEmail = request.getParameter("SendEmail");
		//if (sendEmail==null && isMultiCorp) 
		sendEmail = "true";		// ECC: always send Email

		boolean bAddProjOnly = false;
		user u = null;
		//String uname = request.getParameter("UserName");

		// create user name if necessary
		if (uname==null || uname.length()==0) {
			if (isCRAPP || isPRM)
			{
				// check to see if Email format username is enforced
				if ((s=Util.getPropKey("pst", "USERNAME_EMAIL"))!=null && s.equalsIgnoreCase("true"))
					uname = email;
				else
					uname = email.substring(0, email.indexOf('@'));
			}
			else
				uname = FirstName.toLowerCase().charAt(0) + LastName.toLowerCase().replaceAll(" ", "");
		}

		// create password if necessary
		if (pass.length() <= 0)
			pass = Util.createPassword();
		
		// check to make sure username does not exist
		// there is a time window that this check is fine and then after company is created
		// the username is taken.  I will remove the company if create user failed.
		try {
			u = (user)uMgr.get(gUser, uname);
			response.sendRedirect("../out.jsp?msg=User [" + uname + "] already exists in database.");
			return;
		}
		catch (PmpException e) {}	// good: the user doesn't exist
		
		/////////////////////////////////
		// create new company
		// the regular CPM Mutlicorp path
		// check to see if new user supplied a New Company to create
		town newTownObj = null;
		String townIdS = null;
		String newCompanyName = request.getParameter("NewCompanyName");
		if (newCompanyName != null) {
			if (newCompanyName.equals(HOST_COMPANY)) {
				try {townIdS = String.valueOf(tnMgr.get(gUser, newCompanyName).getObjectId());}
				catch (PmpException e) {
					response.sendRedirect("../out.jsp?msg=Fail to get OPEN company (" + newCompanyName 
							+ ").  Please contact administrator.");
					return;
				}
			}
			else {
				try {
					newTownObj = town.createCompany(newCompanyName, null, null);
					townIdS = String.valueOf(newTownObj.getObjectId());
				}
				catch (PmpException e) {
					response.sendRedirect("../out.jsp?msg=Fail to create company (" + newCompanyName
							+ ").  Please try another name.");
					return;
				}
			}
		}

		// create user
		try
		{
			// attempt to create, might be duplicate and bomb out
			u = (user)uMgr.create(gUser, uname, pass);
			u.appendAttribute(user.TEAMMEMBERS, Integer.valueOf(u.getObjectId())); // Append myself to my Contact List
			u.setAttribute("FirstName", FirstName);
			u.setAttribute("LastName", LastName);
			u.setAttribute("Email", email);
			u.setAttribute("HireDate", new Date());		// ECC: use HireDate as CreatedDate
			if (isCRAPP && isMultiCorp)
			{
				u.setAttribute("SpaceTotal", new Integer(userinfo.DEFAULT_CR_SPACE));
				u.setAttribute("SpaceUsed", new Integer(0));
			}
			if (!isOMFAPP)
			{
				if (deptName!=null && deptName.length()<=0) deptName = null;
				u.setAttribute("DepartmentName", deptName);
				u.setAttribute("Supervisor1", manager);
			}
			else
			{
				// circles for OMF
				if (circles != null)
				{
					String [] sa;
					sa = circles.split(",");
					for (int i=0; i<sa.length; i++)
						u.appendAttribute("Towns", new Integer(sa[i]));
				}
			}

			// @ECC060707 companies
			if (comArr!=null && comArr.length > 0)
			{
				Integer [] iArr = new Integer[comArr.length];
				for (int i=0; i<comArr.length; i++)
				{
					if (extern == null) {
						iArr[i] = new Integer((String)comArr[i]);	// Towns expects Integer object
					}
					else
					{
						// for EXTERN request, company is a name like "Pericom"
						int [] id = tnMgr.findId(gUser, "om_acctname='" + (String)comArr[i] + "'");
						if (id.length <= 0) iArr = null;
						else iArr[0] = new Integer(id[0]);
					}
				}

				u.setAttribute("Towns", iArr);
				if (iArr[0].intValue() > 0)
					u.setAttribute("Company", String.valueOf(iArr[0]));

			}
			
			///////////////////////////////////////////
			// regular CPM Multicorp Auto Free user
			else if (newTownObj != null) {
				newTownObj.setAttribute("Chief", String.valueOf(u.getObjectId()));
				newTownObj.setLimit(town.MAX_PROJECT, String.valueOf(town.DEFAULT_MAX_PROJ));
				newTownObj.setLimit(town.MAX_USER, String.valueOf(town.DEFAULT_MAX_USER));
				newTownObj.setLimit(town.MAX_SPACE, String.valueOf(town.DEFAULT_MAX_SPACE));
				tnMgr.commit(newTownObj);
			}
			
			if (townIdS != null) {
				// townIdS can be from newTownObj or from OPEN company
				u.setAttribute("Company", townIdS);
				u.setAttribute("TownID", townIdS);
			}
			uMgr.commit(u);

			// @AGQ081706
			if (isOMFAPP)
			{
				// convert guest email to user
				UtilThread uThread = new UtilThread(UtilThread.CONVERT_EMAILS, u);
				uThread.start();
			}

			// create userinfo
			userinfoManager uiMgr = userinfoManager.getInstance();
			userinfo ui = (userinfo)uiMgr.create(gUser, String.valueOf(u.getObjectId()));

			//ui.setAttribute("LastLogin", new Date());
			ui.setAttribute("Preference", "BlogCheck:Mon");
			uiMgr.commit(ui);

			// optionally send alert email to people
			s = Util.getPropKey("pst", "SEND_ALERT_ON_NEW_USER");	// contains emails
			if (s != null)
			{
				String [] sa = s.split(";");
				FROM = Util.getPropKey("pst", "FROM");
				subj = "[" + Prm.getAppTitle() + "] Welcome to Collabris";
				msg = "New user account added successfully.<blockquote>";
				msg += "<table border='0' cellspacing='0' cellpadding='0'>";
				msg += "<tr><td class='plaintext' width='150'>Account Name:</td><td class='plaintext'>" + u.getObjectName() + "</td></tr>";
				msg += "<tr><td class='plaintext'>Full Name:</td><td class='plaintext'>" + FirstName + "&nbsp;" + LastName + "</td></tr>";
				msg += "<tr><td class='plaintext'>Email:</td><td class='plaintext'>" + email + "</td></tr>";
				//msg += "<tr><td class='plaintext'>Department:</td><td class='plaintext'>" + deptName + "</td></tr>";
				//msg += "<tr><td class='plaintext'>Circle:</td><td class='plaintext'>" + circles + "</td></tr>";
				msg += "</table>";
				msg += "</blockquote><br><br>";
				msg += "If you have any questions, please contact " + Prm.getAppTitle() + " Admin at " + FROM;
				Util.sendMailAsyn(gUser, FROM, sa, null, null, subj, msg, MAILFILE);
			}

			// send event to circle members
			if (circles != null)
			{
				String [] sa;
				sa = circles.split(",");
				for (int i=0; i<sa.length; i++)
				{
					PrmEvent.createTriggerEvent(u, PrmEvent.EVT_CIR_JOIN, null, sa[i], null);
				}
			}
		}
		catch (Exception e)
		{
			// failed to create user
			if (extern != null) s = " from " + extern + " for [" + uname + "]";
			else s = "";
			l.info("Exception in create new user (post_adduser.jsp)" + s);

			if (extern != null)
				return;
			
			// duplicate user found
			if (isMultiCorp && newTownObj!=null && e.getMessage().contains("duplicate")) {
				tnMgr.delete(newTownObj);		// remove the newly created company
				response.sendRedirect("../out.jsp?msg=Fail to create user.  Please try to use another username.");
				return;
			}

			// need to trap the case of reaching max registered user allowed
			int idx;
			if (extern==null && (idx = e.toString().indexOf("reached the maximum number")) != -1)
			{
				response.sendRedirect("../out.jsp?msg=" + e.toString().substring(idx)
						+ " Please contact EGI Technologies, Inc. to expand your license.");
				return;
			}
			// try to get the user and this might just be adding project membership
			if (!isOMFAPP && u==null)
			{
				// failed to create user, try to get the user to see if he exists
				user au = (user)uMgr.get(gUser, uname);

				if (!isMultiCorp && email.equalsIgnoreCase((String)au.getAttribute("Email")[0]))
				{
					u = au;
					bAddProjOnly = true;
					msgS = "add project membership completed";
				}
				else
				{
					response.sendRedirect("../out.jsp?msg=Error in creating new user.  The username ["+ uname + "] is already taken.");
					return;
				}
			}
		}	// END: catch create user exception

		// create personal project space
		if (isCreatePersonalSpace) {
			project.createPersonalProject(u);
			l.info("Created personal project space for new user [" + u.getObjectName() + "]");
		}
		
		// add project membership
		if (!isOMFAPP && projectIds!=null && projectIds.length>0)
		{
			Integer uidO = new Integer(u.getObjectId());
			projectManager pjMgr = projectManager.getInstance();
			for (int i=0; i<projectIds.length; i++)
			{
				project pj = (project)pjMgr.get(gUser, Integer.parseInt(projectIds[i]));
				pj.removeAttribute("TeamMembers", uidO);
				pj.appendAttribute("TeamMembers", uidO);
				pjMgr.commit(pj);
			}
		}

		// @ECC121306 set town by comparing email with domains
		// For now, as long as the email matches a town domain, we will set the user to be
		// a member of that town.  In the future, better security should be imposed:
		// Create and email a secret code to user (also store it in user object), when the
		// user comes back with the secret code in the welcome page, then we will set the town.
		// This way he will only be included in the town if he has a valid company email address.
		// Format of secret code can be TownID + 5-digit random
		String townName = "";
		if (isOMFAPP && comArr==null)
		{
			// Company is not specified in the request, so use Email address to determine company
			email = email.toLowerCase();		// new user's email
			int [] ids1 = tnMgr.findId(gUser, "om_acctname='%'");
			PstAbstractObject o;
			for (int i=0; i<ids1.length; i++)
			{
				o = tnMgr.get(gUser, ids1[i]);
				s = (String)o.getAttribute("Email")[0];
				if (s == null) continue;	// no domain email for this town
				s = s.toLowerCase();
				if (email.endsWith(s))
				{
					// domain and email matched, set town
					u.appendAttribute("Towns", new Integer(ids1[i]));
					uMgr.commit(u);
					townName = " - " + o.getObjectName();
					PrmEvent.createTriggerEvent(u, PrmEvent.EVT_CIR_JOIN, null, String.valueOf(ids1[i]), null);
					break;
				}
			}
		}

		// send an email to the new user
		if (!isOMFAPP && !bAddProjOnly && sendEmail!=null)
		{
			Util2.sendUserWelcome(gUser, Prm.getAppTitle(), uname, pass, email);
		}

		// @ECC062607 check to see if I need to call other app to create new accounts
		s = Util.getPropKey("pst", "ADD_EXTERN_ACCT");	// host name of the other app e.g. www.meetwe.com
		if (s != null)
		{
			// use thread to call external app to create account on that app
			UtilThread uThread = new UtilThread(UtilThread.ADD_EXTERN_ACCT, u);
			uThread.setParam(0, email);
			uThread.setParam(1, uname);
			uThread.setParam(2, pass);
			uThread.setParam(3, deptName);
			uThread.start();
			l.info("Spawned thread to create new user account on EXTERN: " + s);
		}

		// @SWS082506
		if (!isAuto || isAdmin)
		{
			if (isAdmin && addMore==null)
				response.sendRedirect("admin.jsp?msg="+msgS);
				//response.sendRedirect("adduser.jsp?msg="+msgS);
		}
		else if (isCRAPP)
		{
			if (isGuest)
				response.sendRedirect("../checklogin.jsp?Uid=" + uname + "&Password=" + pass + "&goto=ep/ep_home.jsp");
			else
				response.sendRedirect("adduser.jsp?msg=" + msgS);
		}
		else if (extern == null) {
			// regular CPM case
			if (isGuest) {
				response.sendRedirect("../checklogin.jsp?Uid=" + uname + "&Password=" + pass + "&mid=" + mid + "&goto=" + next + "&user=new");
			}
			else {
				response.sendRedirect("adduser.jsp?msg=" + msgS);
			}
		}
		else
		{
			if (comArr!=null) s = (String)comArr[0];
			else s = "";
			l.info("Created an EXTERN user [" + uname + "] for [" + s + "] from [" + extern + "]");
		}

		// @ECC062607 if calling from extern app (using Java thread), simply terminate after create

		return;
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
	New User Request
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
	<img src='../i/spacer.gif' width='20' height='1'/>
	<b class="head">New User Request Submitted
	</b><br><br>
	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- CONTENT -->
<table width='700'>
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan="2" class="plaintext_big"><br>
		Your new user request has been submitted sucessfully.  Once the processing is done, <%=new_user%>
		will receive a notification email with login instructions on it.
		<br><br>

		Thank you for using <%=Prm.getAppTitle()%>!

<p align="center">
	<input type='button' class='button_medium' value='Home' onClick="location='<%=home%>'">
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
