<%
////////////////////////////////////////////////////
//	Copyright (c) 2004-2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	post_deluser.jsp
//	Author:	ECC
//	Date:	04/22/05
//	Description:
//		Allow admin to delete a user.
//	Modification:
//
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
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	// update user info, including set password
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ((pstuser instanceof PstGuest) || ((iRole & user.iROLE_ADMIN) == 0) )
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}

	String uname = request.getParameter("UserName").trim();
	String errMsg = null;

	// delete user
	userManager uMgr = userManager.getInstance();
	user u = null;
	try {u = (user)uMgr.get(pstuser, uname);}
	catch (PmpException e)
	{
		response.sendRedirect("../out.jsp?msg=User " + uname + " not found in database.");
		return;
	}
	int uid = u.getObjectId();
	uMgr.delete(u);			// will delete the userinfo object and the private projects

	// remove project membership of this user
	projectManager pjMgr = projectManager.getInstance();
	int [] ids = pjMgr.findId(pstuser, "TeamMembers=" + uid);
	for (int i=0; i<ids.length; i++)
	{
		project pj = (project)pjMgr.get(pstuser, ids[i]);
		pj.removeAttribute("TeamMembers", new Integer(uid));
		pjMgr.commit(pj);
	}

	response.sendRedirect("deluser.jsp?msg=[" + uname + "] deleted.");
%>
