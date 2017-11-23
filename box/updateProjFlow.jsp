<%
//
//	Copyright (c) 2010, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	updateProjFlow.java
//	Author: ECC
//	Date:		11/04/2010
//	Description:	Create or update the flowmap for a project.
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "oct.util.file.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "mod.box.PrmDrawFlow" %>
<%@ page import = "mod.box.PrmDrawFlow.Step" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.PepCommentVector" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>
<%@ page import = "com.oreilly.servlet.*" %>
<%@ page import = "org.apache.log4j.Logger" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%!
	final Logger l = PrmLog.getLog();
	taskManager tkMgr = null;
	PstFlowManager fMgr = null;
	int stepId = 1;		// monotonically increasing
	
	SimpleDateFormat df = PrmDrawFlow.Step.df;		// "MM/dd/yy h:mm a"

	/**
	 * this is the method to create the original flow and subflow from a project
	 * -- this should be maintained in a Java file
	 */
	void createProjectFlowXML(PstUserAbstractObject u, project pj, PstAbstractObject flowObj)
		throws PmpException
	{
		// create the flow XML in String and save into the project Content
	
		// top-level tasks
		int [] tids = pj.getTopLevelTasks(u);
System.out.println("top level = "+tids.length);
	
		// create the flow XML
		StringBuffer sBuf = null;
		if (tids.length > 0) {
			sBuf = new StringBuffer(8192);
			sBuf.append("<flow name=" + pj.getDisplayName() + ">\n");
		}
		
		// insert all the task steps into the buffer
		PstAbstractObject [] taskArr = tkMgr.get(u, tids);
		ArrayList<task> taskWithChildren = createTaskStepXML(u, taskArr, sBuf);
		
		// empty data section
		
		// closing flow XML
		if (sBuf != null) {
			sBuf.append("</flow>\n\n");
			
			// for each task with child, create a subflow
			for (task child: taskWithChildren) {
				createSubflowXML(u, child, sBuf);
			}
			
			// write it back to the flow object
			flowObj.setRawAttribute("Content", sBuf.toString());
			fMgr.commit(flowObj);
			l.info("Created flow XML for [" + flowObj.getObjectId() + "]");
		}

	}
	
	/**
	 * create the step XML represented by the tasks in the task Id array
	 * -- this should be maintained in a Java file
	 */
	ArrayList<task> createTaskStepXML(PstUserAbstractObject u, PstAbstractObject [] taskArr, StringBuffer sBuf)
		throws PmpException
	{
		ArrayList<task> taskWithChild = new ArrayList<task>();
		Date dt;
		String taskSt;
		task tObj;
		String TAB = "\t";

		for (int i=0; i<taskArr.length; i++) {
			// create a step XML for each task, all parallel by default
			tObj = (task) taskArr[i];
			sBuf.append("<step\n");		// step begin
			sBuf.append(TAB + "id=" + stepId++ + ";\n");
			sBuf.append(TAB + "name=\"" + tObj.getTaskName(u) + "\";\n");
			sBuf.append(TAB + "displayname=\"\";\n");
			sBuf.append(TAB + "taskid=" + taskArr[i].getObjectId() + ";\n");	// IMPORTANT
			
			// I need the step state, need to translate from task state
			// ECC: the key is just to get the taskId because in PrmDrawFlow
			// we will get the real-time info from existing step associated to the task
			taskSt = (String)tObj.getAttribute("Status")[0];
			sBuf.append(TAB + "taskState=" + taskSt + ";\n");
			sBuf.append(TAB + "state="
					+ PrmDrawFlow.Step.stateMapping(taskSt) + ";\n");
			
			if (!taskSt.equals(task.ST_NEW)) {
				dt = tObj.getStartDate();
				sBuf.append(TAB + "created=" + df.format(dt) + ";\n");
				dt = tObj.getExpireDate();
				sBuf.append(TAB + "expire=" + df.format(dt) + ";\n");
			}
			// ECC: see above comment, this block can be ignored
			
			sBuf.append(TAB + "creator=" + tObj.getAttribute("Owner")[0] + ";\n");
			sBuf.append(TAB + "asignto=" + tObj.getAttribute("Owner")[0] + ";\n");
			sBuf.append(TAB + "intoken=0;\n");
			// no outstep
			sBuf.append("/>\n\n");		// step end
			
			if (tObj.getChildren(u).size() > 0) {
				taskWithChild.add(tObj);
			}
		}	// END for each task
		return taskWithChild;
	}
	
	/**
	 * create the subflow XML of this tasks and put into the buffer
	 * -- this should be maintained in a Java file
	 */
	void createSubflowXML(PstUserAbstractObject u, task taskObj, StringBuffer sBuf)
		throws PmpException
	{
		// get all my children and create a step XML for each of them
		ArrayList<task> childrenTasks = taskObj.getChildren(u);
		if (childrenTasks.size() <= 0)
			return;
		
		// add subflow tag
		sBuf.append("<subflow name=" + taskObj.getTaskName(u) + "; id=" + taskObj.getObjectId() + ";>\n");
		
		// add step XML for each child task
		ArrayList<task> taskWithChildren = createTaskStepXML(u, childrenTasks.toArray(new PstAbstractObject[0]), sBuf);
		
		// add subflow end tag
		sBuf.append("</subflow>\n\n");

		// recursively create subflow for my children
		for (task child : childrenTasks) {
			createSubflowXML(u, child, sBuf);
		}
	}
	
%>

<%
	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	String projIdS = request.getParameter("projId");
	
	projectManager pjMgr = projectManager.getInstance();
	userManager uMgr = userManager.getInstance();
	tkMgr = taskManager.getInstance();
	fMgr = PstFlowManager.getInstance();

	project pj = (project) pjMgr.get(pstuser, Integer.parseInt(projIdS));
	
	// use the project to find the project flow object
	PstAbstractObject flowObj = pj.getProjectFlow(pstuser);
	
	// check to see if user is requesting to delete flow XML
	String op = request.getParameter("op");
	if (op!=null && op.equals("del")) {
		// delete the flow
		if (flowObj != null) {
			flowObj.setAttribute("Content", null);
			fMgr.commit(flowObj);
		}
		response.sendRedirect("flowMap.jsp?projId=" + projIdS);	// default
		return;
	}
	
	/////////////////
	// other operations: create or update
	
	String projDispName = pj.getDisplayName();

	String contentS = flowObj.getRawAttributeAsString("Content");
	
	if (Util.isNullOrEmptyString(contentS)) {
		// need to create the flow XML from project
		try {createProjectFlowXML(pstuser, pj, flowObj);}
		catch (PmpException e) {
			e.printStackTrace();
			response.sendRedirect("../out.jsp?e=Error in creating process map for the project.");
			return;
		}
	}
	
	// there is already a flow XML in contentS
	else {
		// augment the existing flow with the latest project object
	}

	response.sendRedirect("flowMap.jsp?projId=" + projIdS);	// default

%>
