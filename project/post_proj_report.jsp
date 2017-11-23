<%
//
//	Copyright (c) 2010, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_proj_report.jsp
//	Author: ECC
//	Date:		03/29/2010
//	Description:	Update info regarding project reporting.
//	Modification:
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

	projectManager pjMgr = projectManager.getInstance();
	String msg = "";

	String op = request.getParameter("op");
	if (op == null) op = "";

	String projIdS = request.getParameter("projId");
	project pj = (project)pjMgr.get(pstuser, Integer.parseInt(projIdS));

	// update exec summary task id
	if (op.equals("execSummary")) {
		String execSummaryId = request.getParameter("execSummaryId");
		if (execSummaryId != null) {
			execSummaryId = execSummaryId.trim();
			if (execSummaryId.length() <= 0)
				execSummaryId = null;

			// check to see if the ID is a valid Integer type
			try {Integer.parseInt(execSummaryId);}
			catch (Exception e) {execSummaryId = null;}

			pj.setOption(project.EXEC_SUMMARY, execSummaryId);

			msg = "Set executive summary task ID completed successfully.";
		}
	}

	// distribute project report
	else if (op.equals("distribute")) {
		// first save distribution options, then check if send report now
		String distFreq = request.getParameter("reportDistFrequency");
		if (distFreq.equals(project.DIST_WEEKLY) ||
			distFreq.equals(project.DIST_MONTHLY)) {
			distFreq = distFreq + ":" + request.getParameter("freqSpec");
		}
		String [] distMembers = request.getParameterValues("DistributeMembers");

		pj.setAttribute("Attendee", distMembers);	// need to do this before setOption()
		pj.setOption(project.DISTRIBUTE_FREQ, distFreq);
		pjMgr.commit(pj);	// setOption() commits only if option has changed

		boolean sendReportNow = request.getParameter("sendNow").equals("true");

		if (sendReportNow) {
			// distribute the report now
			Util4.sendReport(pstuser, pj.getObjectId(), null);
			msg = "Distribute report by Email completed successfully.";
		}
		else {
			msg = "Save report distribution completed successfully.";
		}
	}

	response.sendRedirect("proj_report.jsp?projId="+projIdS
							+ "&msg=" + msg);

%>
