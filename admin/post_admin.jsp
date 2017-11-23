<%
////////////////////////////////////////////////////
//	Copyright (c) 2004-2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	post_admin.jsp
//	Author:	ECC
//	Date:	04/22/04
//	Description:
//		Delete a weblog object.
//	Modification:
//
//
////////////////////////////////////////////////////////////////////
%>

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

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">
    <head>
        <meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">

<title>
	<%=session.getAttribute("app")%> Weblog
</title>

</head>

<%
	String op = request.getParameter("op");
	if ((pstuser instanceof PstGuest) || (op == null))
	{
		response.sendRedirect("/error.jsp?msg=Access declined");
		return;
	}
	String type = request.getParameter("type");

	// delete the blog object
	if (op.equals("reset"))			// reset userinfo
	{
		// reset login num
		userinfoManager uiMgr = userinfoManager.getInstance();
		userinfo ui;

		int [] uiId = uiMgr.findId(pstuser, "om_acctname='%'");

		for (int i=0; i<uiId.length; i++)
		{
			ui = (userinfo)uiMgr.get(pstuser, uiId[i]);
			ui.setAttribute(type, null);
			uiMgr.commit(ui);
		}
	}
	else if (op.equals("resetApp"))	// reset application attribute
	{
		application.setAttribute(type, new Integer(0));
	}

	response.sendRedirect("admin.jsp");
%>
