<%

//
//  Copyright (c) 2010, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   post_timeline.jsp
//  Author: ECC
//  Date:   02/15/10
//  Description:  Post page to update timeline for timeline.jsp
//  Modification:
//
/////////////////////////////////////////////////////////////////////
//
%>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "org.apache.log4j.Logger" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>

<%@page import="java.text.SimpleDateFormat"%><pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	Logger l = PrmLog.getLog();
	final int LEADING_GAP = 20;				// this must agree with timeline.jsp
	final int SIZE_FACTOR = 10;				// must be the same as in timeline.jsp
	SimpleDateFormat df = new SimpleDateFormat("MM/dd/yyyy");

	String projIdS = request.getParameter("projId");
	String updatedIdx = request.getParameter("updatedIdx");		// idx of updated tasks separated by ";"
	String begPos = request.getParameter("begPos");
	String endPos = request.getParameter("endPos");
	String begDt = request.getParameter("begDt");
	String endDt = request.getParameter("endDt");

	projectManager pjMgr = projectManager.getInstance();
	taskManager tkMgr = taskManager.getInstance();

	// use project start date as reference point
	PstAbstractObject pjObj = pjMgr.get(pstuser, Integer.parseInt(projIdS));
	long projStartTime = ((Date)pjObj.getAttribute("StartDate")[0]).getTime();
	int dayMsec = 86400000;

	// Get plan task
	Stack planStack = (Stack)session.getAttribute("planStack");
	Vector rPlan = (Vector)planStack.peek();
	Hashtable rTask;
	int idx;

	String [] updatedArr = updatedIdx.split(";");	// already strip the beginning and ending ";" in timeline.jsp
	String [] begDtArr	 = begDt.split(";");
	String [] endDtArr   = endDt.split(";");

	String taskIdS;
	task tObj;
	int gap, dur;
	Date startDt, expireDt;
	Date latestDate = (Date)pjObj.getAttribute("ExpireDate")[0];

	for (int i=0; i<updatedArr.length; i++)
	{
		// for each modified task (bar), update the StartDate, ExpireDate, Duration
		idx = Integer.parseInt(updatedArr[i]);
		rTask = (Hashtable)rPlan.elementAt(idx);
		taskIdS = (String)rTask.get("TaskID");
		tObj = (task)tkMgr.get(pstuser, Integer.parseInt(taskIdS));

		startDt = df.parse(begDtArr[i]);
		expireDt = df.parse(endDtArr[i]);

		tObj.setAttribute("StartDate", startDt);
		tObj.setAttribute("ExpireDate", expireDt);
		if (expireDt.after(latestDate))
			latestDate = expireDt;

		// set my true gap and duration, it will impact other tasks' timeline
		//task.setDebug(true);
		tObj.setTimeLine(pstuser);		// will commit in this call
		//task.setDebug(false);


		l.info("Updated task [" + taskIdS + "] timeline.");
	}

	if (latestDate.after((Date)pjObj.getAttribute("ExpireDate")[0])) {
		// project needs to be extended
		pjObj.setAttribute("ExpireDate", latestDate);
		pjObj.setAttribute("LastUpdatedDate", new Date());
		pjMgr.commit(pjObj);
		l.info("Extended project deadline to " + latestDate);
	}

	response.sendRedirect("timeline.jsp?projId=" + projIdS);

%>

