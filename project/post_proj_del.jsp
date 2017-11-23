<%
//
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_proj_del.jsp
//	Author: ECC
//	Date:		04/15/2004
//	Description:	Delete a project.
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "oct.util.file.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	String projIdS = request.getParameter("projId");
	if ((pstuser instanceof PstGuest) || (projIdS == null))
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	int pjId = Integer.parseInt(projIdS);

	userManager uMgr		= userManager.getInstance();
	projectManager pjMgr	= projectManager.getInstance();

	// I need to do the history record before deletion start
	// otherwise all info are gone.
	PstAbstractObject pj = pjMgr.get(pstuser, pjId);
	history.addRecord(pstuser, "HIST.3102",
			(String)pj.getAttribute("TownID")[0], null, projIdS);
	int active = Thread.activeCount();
    Thread all[] = new Thread[active];
    Thread.enumerate(all);
    for (int i = 0; i < active; i++) {
    	Thread aThread = all[i];
		if (aThread.getName().equals(UtilThread.CREATE_EVENT)) {
System.out.println(">>> delete proj event: wait for event thread to end");			
			aThread.join(5000);		// wait at most 5 sec
System.out.println("<<< event thread ended");			
			break;
		}
    }


	// change identity to special user
	//ResourceBundle prop = ResourceBundle.getBundle("pst");
	//String spec_uname = prop.getString("PRIVILEGE_USER");
	//String spec_passwd = prop.getString("PRIVILEGE_PASSWD");
	// ECC: with encryption, cannot use ResourceBundle directly
	String spec_uname = Util.getPropKey("pst", "PRIVILEGE_USER");
	String spec_passwd = Util.getPropKey("pst", "PRIVILEGE_PASSWD");
	
	String oldname = pstuser.getObjectName();
	String oldpass = (String)session.getAttribute("password");
	user specialuser = (user)uMgr.login(pstuser, spec_uname, spec_passwd);

	// remove all projects, plan, planTask, task, result, latest_result
	try
	{
		Util.deleteProject(specialuser, pjId);
	}
	catch (PmpException e)
	{
		// return to original identity
		user olduser = (user)uMgr.login(specialuser, oldname, oldpass);
		session.setAttribute("pstuser", olduser);

		e.printStackTrace();
		response.sendRedirect("../out.jsp?msg=Error in removing Project ("+projIdS+")");
		return;
	}

	// return to original identity
	user olduser = (user)uMgr.login(specialuser, oldname, oldpass);
	session.setAttribute("pstuser", olduser);
	session.removeAttribute("projName");
	session.removeAttribute("planStack");

	// update login user, reset LastProject to null
	user u = (user)uMgr.get(olduser, pstuser.getObjectId());
	u.setAttribute("LastTown", null);
	u.setAttribute("LastProject", null);
	uMgr.commit(u);

	response.sendRedirect("../ep/ep_home.jsp");	// default
%>
