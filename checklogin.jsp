<%@ page contentType="text/html; charset=utf-8"%>

<%
////////////////////////////////////////////////////
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	checklogin.jsp
//	Author:	RPK
//	Date:	01/21/01
//	Last Modified:	03/12/03
//	Description:
//		Used to check whether a user has successfuly logged in
//	Modification:
//		@260101aRPK
//		@SWS082306  do not ask user for new password if in auto approval mode.
//		@ECC100309	Support FirstPage preference for user.
//
// checklogin.jsp :Used to check whether a user has successfuly logged in
//
////////////////////////////////////////////////////////////////////
%>


<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.*" %>
<%@ page import = "org.apache.log4j.Logger" %>

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");	

	Logger l = PrmLog.getLog();
	String HOST = Util.getPropKey("pst", "PRM_HOST");

	String srcPath = request.getRealPath(new String());
	srcPath = srcPath.replace('\\', '/');
	srcPath = srcPath + "/WEB-INF/lib/dataSource.xml";
	PstManager.initConnectionPool(srcPath);
	
	String path = request.getParameter("Go");			// go to a certain page
	
	if (path!=null && path.length()>0)
	{
		int idx;
		if ((idx = path.indexOf("?")) != -1)
			path = path.substring(0, idx) + path.substring(idx).replaceAll(":", "&");
	}

	boolean isOMFAPP = Prm.isOMF();

	String username = request.getParameter("Uid");
	String password = request.getParameter("Password");
	String next = request.getParameter("goto");
	String newuser = request.getParameter("user");
	String mid = request.getParameter ("mid");

	// @SWS082306
	boolean isAuto = false; // check if auto approval turn on
	String autoApprove = "";
	autoApprove = Util.getPropKey("pst", "NEW_USER_AUTO_APPROVAL");
	if (autoApprove != null && autoApprove.equals("true"))
		isAuto = true;

	user u;
	try
	{
		u = Util.login(session, username, password);
		l.info("User " + username + " login");

		if (StringUtil.isNullOrEmptyString(path)) {
			// try to go to the last project top page if it exist
			String lastProjIdS = u.getStringAttribute("LastProject");
			if (Prm.isPRM()) {
				if (Prm.isPDA(request))
					path = "ep/ep_prm_pda.jsp";
				else if (lastProjIdS != null) {
					path = "project/proj_top.jsp?projId=" + lastProjIdS;
				}
			}
		}
		if (StringUtil.isNullOrEmptyString(path)) {
			path = "ep/ep_home.jsp";
		}
	}
	catch (PmpException e)
	{
		//e.printStackTrace();
		if (e.toString().indexOf("license has expired") != -1)
			response.sendRedirect(HOST + "/login.jsp?error=Your software license has expired, please contact EGI administrator for license renewal.");
		else {
			l.info("User [" + username + "] failed to login " + Prm.getAppTitle());
			if (!isOMFAPP)
				response.sendRedirect(HOST + "/login.jsp?error=You have entered invalid login information. Please try again.");
			else
				response.sendRedirect(HOST + "/login_omf.jsp?error=You have entered invalid login information. Please try again.&goto=" + next);
		}
		return;
	}
	catch (Exception f)
	{
		//f.printStackTrace();
		String eMsg;
		if (f.toString().indexOf("license has expired") != -1)
			eMsg = "The PRM software license has expired, please contact the PRM administrator.";
		else
			eMsg = "Internal Error! Please contact the PRM Administrator.";
		response.sendRedirect("login.jsp?error=" + eMsg);
		return;
	}

	if (next != null)
	{
		if (next.equals("now"))
			path = HOST + "/meeting/mtg_new1.jsp?StartNow=true";
		else if (next.equals("setup"))
			path = HOST + "/meeting/mtg_new1.jsp";

	}
	else if (!path.startsWith("http"))
		path = HOST + "/" + path;				// change from https to http
		
	if (newuser!=null && newuser.equals("new"))
		response.sendRedirect(HOST + "/ep/post_updperson.jsp?&user=new&goto=" + next + "&uid=" + username + "&pass=" + password + "&mid=" + mid);
	else
		response.sendRedirect(path);

%>
