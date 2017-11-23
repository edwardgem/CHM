<%@ page contentType="text/html; charset=utf-8"%>

<%
////////////////////////////////////////////////////
//	Copyright (c) 2004-2008, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	post_comp_new.jsp
//	Author:	ECC
//	Date:	08/11/08
//	Description:
//		post action for comp_new.jsp.
//
//	Modification:
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.file.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>
<%@ page import = "com.oreilly.servlet.*" %>
<%@ page import = "org.apache.log4j.Logger" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");
	// init
	Logger l = PrmLog.getLog();
	String filepath = Util.getPropKey("pst", "FILE_UPLOAD_PATH");
	MultipartRequest mrequest = new MultipartRequest(request, filepath, 10*1024*1024, "UTF-8");

	// update user info, including set password
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ((pstuser instanceof PstGuest) || (((iRole & user.iROLE_ADMIN) == 0) && ((iRole & user.iROLE_ACCTMGR) == 0)) )
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	PstUserAbstractObject me = pstuser;

	userManager uMgr = userManager.getInstance();
	userinfoManager uiMgr = userinfoManager.getInstance();
	townManager tnMgr = townManager.getInstance();

	PstAbstractObject tObj, pmObj=null;
	boolean isPmUserExist = false;

	String s;

	String errMsg = null;
	String compDispName = mrequest.getParameter("CompanyName");
	String fName = mrequest.getParameter("FirstName");
	String lName = mrequest.getParameter("LastName");
	String email = mrequest.getParameter("Email");
	String uname = mrequest.getParameter("Username");	// the Program Manager
	if (uname == null) {
		// try to use email to find the user, if not found, then create an account for the user
		int [] ids = uMgr.findId(me, "Email='" + email + "'");
		if (ids.length > 0) {
			// found user with this email, use it
			pmObj = uMgr.get(me, ids[0]);
			uname = pmObj.getObjectName();
			isPmUserExist = true;
		}
		else {
			uname = email;			// use email as username
		}
	}
	String sendEmail = mrequest.getParameter("SendEmail");

	String compName = compDispName.replaceAll(" ", "-").toLowerCase();

	// department name
	String deptName = "";
	s = mrequest.getParameter("DeptName");
	if (s!=null && s.length()>0)
		s = s.trim().toUpperCase();
	else s = "";
	for (int i=0; i<s.length(); i++)
	{
		if (s.charAt(i) == ' ') continue;
		deptName += s.charAt(i);
	}
	if (deptName.length() <= 0)
		deptName = null;		// Util.getPropKey("pst", "DEPARTMENTS");

	// account manager
	String acctMgrIdS = mrequest.getParameter("AcctManager");
	if (acctMgrIdS == null)
		acctMgrIdS = String.valueOf(me.getObjectId());

	// create user: program manager
	// check to see if user name is already in use
	String passwd = null;
	if (!isPmUserExist) {
		try
		{
			pmObj = uMgr.get(me, uname);
			isPmUserExist = true;
		}
		catch (PmpException e) {}	// good: the user doesn't exist
	}

	// create company
	try {
		tObj = town.createCompany(compDispName, deptName, acctMgrIdS);
	}
	catch (PmpException e) {
		response.sendRedirect("../out.jsp?msg=Fail to create company (" + compDispName + ").  Please try another name.");
		return;
	}
	int tId = tObj.getObjectId();

	// upload logo file
	Enumeration enum0 = mrequest.getFileNames();
	while (enum0.hasMoreElements())
	{
		Object name = enum0.nextElement();
		File fileObj = mrequest.getFile(name.toString());	// file attachment upload

		if(fileObj != null)
		{
			FileTransfer ft = new FileTransfer(me);
			String fullFileName = ft.savePictureFile(fileObj, String.valueOf(tId));
			tObj.setAttribute("PictureFile", fullFileName);			// commit below
		}
	}

	// continue with create user
	boolean bCreatedNewPmUser = false;
	if (!isPmUserExist) {
		passwd = email.substring(0, email.indexOf("@"));
		pmObj = uMgr.createFull(me, uname, passwd);				// this will create the user and the userinfo
		pmObj.setAttribute("Company", String.valueOf(tId));
		pmObj.setAttribute("FirstName", fName);
		pmObj.setAttribute("LastName", lName);
		pmObj.setAttribute("Email", email);
		bCreatedNewPmUser = true;
	}

	pmObj.appendAttribute("Towns", new Integer(tId));
	pmObj.appendAttribute("Role", user.ROLE_PROGMGR);	// the new user is the Program Mgr of the new company

	// remember the initial Program Manager.  PM is a role that many user may have w/i the company.
	tObj.setAttribute("Chief", String.valueOf(pmObj.getObjectId()));

	// commit the objects
	tnMgr.commit(tObj);
	uMgr.commit(pmObj);

	l.info("Created new company [" + compName + "]");

	// send emails
	String FROM = Util.getPropKey("pst", "FROM");
	String MAILFILE = "alert.htm";
	String subj, msg;

	// notify admin about the created company and program manager
	subj = "[" + Prm.getAppTitle() + "] New Company (" + compName + ") created";
	msg= "A new company has been created by [" + me.getObjectName() + "].";
	msg += "<blockquote><table><tr><td width='100'>Company</td><td>: <b>" + compName + "</b></td></tr>";
	msg += "<tr><td>Display Name</td><td>: <b>" + compDispName + "</b></td></tr>";
	msg += "<tr><td>Departments</td><td>: <b>" + deptName + "</b></td></tr>";
	msg += "<tr><td>Username</td><td>: <b>" + uname + "</b></td></tr>";
	msg += "<tr><td>Password: <b>" + passwd + "</b></td></tr>";
	msg += "<tr><td>EGI Acct Manager: <b>" + acctMgrIdS + "</b></td></tr>";
	msg += "</table></blockquote>";
	Util.sendMailAsyn(me, FROM, FROM, null, null, subj, msg, MAILFILE);

	// send welcome msg to newly created (or existed) program manager
	if (sendEmail!=null) {
		if (bCreatedNewPmUser) {
			Util2.sendUserWelcome(me, Prm.getAppTitle(), uname, passwd, email);
		}
		else {
			// send notification to existing user that he is now PM for this company
			subj = "[" + Prm.getAppTitle() + "] You are the Program Manager of (" + compName + ")";
			msg= "A new company has been created by [" + ((user)me).getFullName() + "].";
			msg += "<blockquote><table><tr><td width='100'>Company</td><td>: <b>" + compName + "</b></td></tr>";
			msg += "<tr><td>Display Name</td><td>: <b>" + compDispName + "</b></td></tr>";
			msg += "</table></blockquote>";
			msg += "You are assigned to be the Program Manager of this company.";
			msg += "<br><br>Please contact EGI Admin if you have any questions.&nbsp;&nbsp;";
			Util.sendMailAsyn(me, FROM, email, null, null, subj, msg, MAILFILE);
		}
	}

	response.sendRedirect("../ep/ep_home.jsp");
%>
