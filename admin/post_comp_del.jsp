<%
////////////////////////////////////////////////////
//	Copyright (c) 2004-2008, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	post_comp_del.jsp
//	Author:	ECC
//	Date:	08/14/08
//	Description:
//		Delete a specified company.  Only admin can delete company.
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
	// init
	Logger l = PrmLog.getLog();
	
	// check authorized role
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ((pstuser instanceof PstGuest) || ((iRole & user.iROLE_ADMIN) == 0) )
	{
		response.sendRedirect("../out.jsp?msg=Access denied");
		return;
	}
	PstUserAbstractObject me = pstuser;
	
	String s;

	String errMsg = null;
	String tidS = request.getParameter("id");


	userManager uMgr = userManager.getInstance();
	townManager tnMgr = townManager.getInstance();
	projectManager pjMgr = projectManager.getInstance();
	PstAbstractObject o;

	l.info("Deleting company [" + tidS + "] ...");
	
	// delete all user of the company
	int [] ids;
	ids = uMgr.findId(me, "Company='" + tidS + "'");
	for (int i=0; i<ids.length; i++)
	{
		o = uMgr.get(me, ids[i]);
		uMgr.delete(o);
		l.info("Deleted user [" + ids[i] + "]");
	}
	
	// delete all projects (task, plan, blog, attachment)
	ids = pjMgr.findId(me, "Company='" + tidS + "'");
	for (int i=0; i<ids.length; i++)
		Util.deleteProject(me, ids[i]);			// Util will print out a statmt about the delete
		
	// delete the logo file if any
	o = tnMgr.get(me, Integer.parseInt(tidS));
	s = (String)o.getAttribute("PictureFile")[0];
	if (s != null)
	{
		s = Util.getPropKey("pst", "USER_PICFILE_PATH") + "/" + s;
		File logoF = new File(s);
		if (logoF.exists())
			logoF.delete();
		l.info("Deleted logo file [" + s + "]");
	}
	
	// delete the company
	tnMgr.delete(o);
	l.info("Deleted company [" + tidS + "]");

	response.sendRedirect("../ep/ep_home.jsp");
%>
