<%
//
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_dependency.jsp
//	Author: ECC
//	Date:		03/31/2004
//	Description:	Set task dependencies
//	Modification:
//		@ECC112405	Added Duration and Gap to task.
//
/////////////////////////////////////////////////////////////////////
//
%>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />


<%
	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}

	// back to page
	String projId = request.getParameter("projId");
	String pTaskId = request.getParameter("planTaskId");

	// the notified user
	String taskIdS = request.getParameter("taskId");
	taskManager tkMgr = taskManager.getInstance();
	task tk = (task)tkMgr.get(pstuser, taskIdS);
	tk.setAttribute("Dependency", null);			// empty it

	// get the list of dependencies ids
	boolean debug = false;
	if (debug) task.setDebug(true);		// need to turn this off later
	
	HashSet<String>depSet = new HashSet<String>(100);

	for (Enumeration e = request.getParameterNames() ; e.hasMoreElements() ;)
	{
		String temp = (String)e.nextElement();
		if (temp.startsWith("append_"))
		{
			String tId = temp.substring(7);
			depSet.add(tId);
		}
	}
	
	// walk through the list of task that currently depend on me
	// and remove them from the Set to eliminate unnecessary updates
	String s;
	int [] currentDep = tkMgr.findId(pstuser, "Dependency='" + taskIdS + "'");
	for (int i=0; i<currentDep.length; i++) {
		s = String.valueOf(currentDep[i]);
		if (depSet.contains(s)) {
			depSet.remove(s);	// already dependent, remove from update list
			currentDep[i] = 0;
			System.out.println("eliminate duplicate dependency update on [" + s + "]");
		}
	}
	
	// first need to remove the original but just removed dependencies
	PstAbstractObject o;
	for (int oldDep : currentDep) {
		if (oldDep <= 0) continue;
		o = tkMgr.get(pstuser, oldDep);
		o.removeAttribute("Dependency", taskIdS);
		tkMgr.commit(o);
		System.out.println("removed old dependency [" + taskIdS + "] from [" + oldDep + "]");
	}
	
	// then walk through the Set to add dependency on the new guys setDependency()
	// will recursively adjust the dates according to the new dependency
	for (String tidS : depSet) {
		if (debug) System.out.println(">>> Add dependency on: " + tidS);
		int rc = tk.addDependency(pstuser, tidS);
		if (rc == task.ERR_DEP_ON_CHILD)
		{
			response.sendRedirect("../out.jsp?msg=A task cannot build a dependency on its children or descendant task.");
			return;
		}
		else if (rc == task.ERR_DEP_ON_PARENT)
		{
			response.sendRedirect("../out.jsp?msg=A task cannot build a dependency on its parent or ancestor task.");
			return;
		}
		else if (rc == task.ERR_DEP_CYCLE)
		{
			response.sendRedirect("../out.jsp?msg=This dependency will result in a cyle.");
			return;
		}
	}

	//session.removeAttribute("planStack");		// cleanup cache

	String loc = "../plan/dependency.jsp?projId="+projId+"&taskId="
		+taskIdS+"&planTaskId="+pTaskId + "#" + taskIdS;

%>
<script type="text/javascript">
	location = '<%=loc%>';
//-->
</script>
