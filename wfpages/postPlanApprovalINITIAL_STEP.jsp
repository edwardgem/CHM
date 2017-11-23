
<%@ page contentType="text/html; charset=utf-8"%>
<%
	//
	//  Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
	//
	/////////////////////////////////////////////////////////////////////
	//
	//  File:   postPlanApprovalINITIAL_STEP.jsp
	//  Author: ECC
	//  Date:   04/18/2004
	//  Description:
	//  Modification:
	//
	/////////////////////////////////////////////////////////////////////
	//
%>
<%@ page import="util.*"%>
<%@ page import="oct.codegen.*"%>
<%@ page import="oct.pst.*"%>
<%@ page import="oct.pmp.exception.*"%>
<%@ page import="java.util.*"%>
<%@ page import="java.io.*"%>
<%@ page import="com.oreilly.servlet.*"%>

<%@ taglib uri="/pmp-taglib" prefix="pmp"%>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	// to check if session is CR or PRM
	boolean isCRAPP = false;
	String app = (String) session.getAttribute("app");
	if (app.indexOf("CR") != -1)
		isCRAPP = true;

	// use a thread to run
	WfThread wft = (WfThread) session.getAttribute("wfThread");
	if (wft == null) {
		//String projName  = request.getParameter("projName");
		String projIdS = request.getParameter("projId");
		String originalPlanName = request
				.getParameter("originalPlanName");
		String[] Description = request
				.getParameterValues("Description");
		String[] Version = request.getParameterValues("Version");
		if (Version.length == 0
				|| StringUtil.isNullOrEmptyString(Version[0])) {
			Version = new String[1];
			Version[0] = "1.0";
		}

		// Get plan task
		Stack planStack = (Stack) session.getAttribute("planStack");
		if ((planStack == null) || planStack.empty()) {
			if (!isCRAPP)
				response.sendRedirect("../out.jsp?msg=Empty plan stack.  Please start again.&go=project/proj_plan.jsp?projName=session");
			else
				response.sendRedirect("../out.jsp?msg=Empty plan stack.  Please start again.&go=project/cr.jsp?projName=session");
			return;
		}
		Vector rPlan = (Vector) planStack.peek();

		// call thread to do work
		wft = new WfThread(pstuser, WfThread.WF_OP_INIT_PLAN_APPROVAL,
				rPlan, projIdS, originalPlanName, Description, Version);
		session.setAttribute("wfThread", wft);
		wft.start();
		// the page will refresh itself and rerun this code and found the "wfThread"
		// from the session object.  It will then execute the below else block
	}
	
	else {
		// if the wfThread is still at work, the page will continue to refresh itself.
		// Otherwise it will execute the below code to render a message to user on the page.
		if (!wft.isAlive()) {
			// thread exited: processing completed - chk status of flow
			session.removeAttribute("planStack");
			session.removeAttribute("redoStack");
			session.removeAttribute("wfThread");

			Integer iRC = (Integer) wft.getRC1();
			if (iRC != null) {
				// the thread call returns the flow id
				int rc = iRC.intValue();
				if (rc < 0) {
					String exceptionMsg = wft.getException()
							.getMessage();
					String redirectMsg = "../out.jsp?msg=Error processing Plan Approval workflow."
							+ " (" + exceptionMsg + ")";
					if (!isCRAPP)
						response.sendRedirect(redirectMsg
								+ "&go=project/proj_plan.jsp");
					else
						response.sendRedirect(redirectMsg
								+ "&go=project/cr.jsp");
					return;
				}

				PstFlow flowObj = (PstFlow) PstFlowManager
						.getInstance().get(pstuser, rc);
				String status = flowObj.getStatus();

				String msg;
				if (status.equals(PstFlowConstant.ST_FLOW_COMMIT)) {
					// no need to send email because commit once I submit (same person thru entire wf
					msg = "Your plan change has been completed and published.<br>Click Continue to view the new plan.";
				} else {
					msg = "Your plan change has been submitted for approval.<br>You will receive an Email Notification when the processing is done.";

					// send email notification if CurrentExecutor != Owner
					PrmWf.notifyExecutor(pstuser, flowObj, app);
				}

				if (!isCRAPP)
					response.sendRedirect("../msg.jsp?msg=" + msg
							+ "&go=project/proj_plan.jsp");
				else
					response.sendRedirect("../msg.jsp?msg=" + msg
							+ "&go=project/cr.jsp");
				return;
			}
		}
	}
%>

<!-- Generic Wait Code Begin -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html lang="en">

<head>
<META HTTP-EQUIV='Refresh' CONTENT='10'>

<link href="../oct-basic.css" rel="stylesheet" type="text/css"
	media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css"
	media="print">

<div id="fader"
	style="position: absolute; top: 200px; left: 50px; width: 600px; text-align: center;"></div>
<!-- adjust style= to position messages -->

<SCRIPT LANGUAGE="JavaScript">
<!-- Begin
	var texts = new Array(
			"<font size='+2' color='{COLOR}' face='Arial'><strong>Processing Plan Change Request</strong></font>",
			"<font size='+2' color='{COLOR}' face='Arial'><strong>Please Wait</strong></font>");

	<jsp:include page="../fade.js" flush="true"/>

	// body tag must include: onload="fade()" bgcolor="#000000"  where bgcolor equals bgcolor in javascript above
//  End -->
</script>

</head>

<title><%=Prm.getAppTitle()%> Plan Change Processing</title>
<body onLoad="fade()" bgcolor="#000000" leftmargin="0" topmargin="0"
	marginwidth="0" marginheight="0">

	<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
	<table width="100%" height="100%" border="0" cellspacing="0"
		cellpadding="0">

		<!-- TOP BANNER -->

		<!-- BEGIN INTERNAL CELL -->
		<tr>
			<td valign="top">
				<table width="100%" border="0" cellspacing="0" cellpadding="0">
					<tr>
						<td width="100%" valign="top">
							<!-- Top --> <jsp:include page="../head.jsp" flush="true" /> <!-- End of Top -->
						</td>
					</tr>
					<tr>
						<td>
							<table>
								<tr>
									<td width="20">&nbsp;</td>
									<td><b class="head">Plan Change Processing</b></td>
								</tr>
							</table>
						</td>
					</tr>

					<tr>
						<td height="3"><img src="../i/spacer.gif" width="1"
							height="3" border="0"></td>
					</tr>

					<tr>
						<td>
							<table width="100%" border="0" cellspacing="0" cellpadding="0"
								class="headlinerule">
								<tr>
									<td><img src="../i/spacer.gif" height="1" width="1"
										alt=" " /></td>
								</tr>
							</table>
						</td>
					</tr>
				</table>
			</td>
		</tr>




		<tr>
			<td>&nbsp;</td>
		<tr>
		<tr>
			<td>
				<!-- Footer --> <jsp:include page="../foot.jsp" flush="true" /> <!-- End of Footer -->
			</td>
		</tr>


		<!-- END INTERNAL CELL -->

	</table>
	<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>
