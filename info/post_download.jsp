<%
//
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_download.jsp
//	Author: ECC
//	Date:		09/17/2008
//	Description:	Post page for download.jsp to update the count for download.
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "util.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>

<%
	// use ViewBlogNum of special user to record the download number
	String NODE	= Util.getPropKey("pst", "PRM_HOST");
	String SPEC_UNAME = Util.getPropKey("pst", "PRIVILEGE_USER");

	if (session == null) session = request.getSession(true);
	PstUserAbstractObject pstuser = (PstUserAbstractObject)session.getAttribute("pstuser");
	if (pstuser == null || pstuser instanceof PstGuest)
		pstuser = PstGuest.getInstance();

	userManager uMgr = userManager.getInstance();
	userinfoManager uiMgr = userinfoManager.getInstance();
	
	PstAbstractObject o = uMgr.get(pstuser, SPEC_UNAME);
	o = uiMgr.get(pstuser, String.valueOf(o.getObjectId()));		// get the userinfo of the special user
	
	Integer io = (Integer)o.getAttribute("ViewBlogNum")[0];
	int count = io.intValue() + 1;
	o.setAttribute("ViewBlogNum", new Integer(count));
	uiMgr.commit(o);
%>

<script language="JavaScript">
<!--

	location = "download.jsp?file=setup#instruction";

//	-->
</script>
