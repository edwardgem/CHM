<%
//
//  Copyright (c) 2008, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   wf_sample1.jsp
//  Author: ECC
//  Date:   04/18/2008
//  Description:	A post page called by a form to start a workflow.  E.g. vacation request.
//					In this example, the user submit a workflow request and wait for a result.
//
/////////////////////////////////////////////////////////////////////
//
%>
<%@ page import = "util.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "com.oreilly.servlet.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	// use a thread to run
	String app = "Sample App";
	SampleWfThread wft = (SampleWfThread)session.getAttribute("wfThread");
	if (wft == null) {
		// no workflow thread working in this session, start working
		// receive data from form, it can be anything
		String dataS  = request.getParameter("title");
		
		String [] Description = request.getParameterValues("Description");
		String [] Version = request.getParameterValues("Version");

		// prepare a context object for this user application
		// put any info you want to pass onto the workflow stream
		Object workObj = new Object();

		// wfThread: SampleWfThread
		// call thread to do work: you can customize the thread code to fit your need
		wft = new SampleWfThread(pstuser, SampleWfThread.WF_OP_VACATION_REQ,
							workObj, dataS, Description, Version);
		session.setAttribute("wfThread", wft);
		wft.start();
		// the page will refresh itself and rerun this code and found the "wfThread"
		// from the session object.  It will then execute the below else block
	}
	else
	{
		// if the wfThread is still at work, the page will continue to refresh itself.
		// Otherwise it will execute the below code to render a message to user on the page.
		if (!wft.isAlive())
		{
			// thread exited: processing completed - chk status of flow
			session.removeAttribute("wfThread");

			Integer iRC = (Integer)wft.getRC1();
			if (iRC != null)
			{
				// the thread call returns the flow id
				int rc = iRC.intValue();
				if (rc < 0)
				{
					String exceptionMsg = wft.getException().getMessage();
					String redirectMsg =
						"../out.jsp?msg=Error processing VACATION REQ workflow." +
						" (" + exceptionMsg + ")";
					response.sendRedirect(redirectMsg + "&go=project/cr.jsp");
					return;
				}

				PstFlow flowObj = (PstFlow)PstFlowManager.getInstance().get(pstuser, rc);
				String status = flowObj.getStatus();

				String msg;
				if (status.equals(PstFlowConstant.ST_FLOW_COMMIT))
				{
					// The entire workflow is COMMITTED.  That means the whole thing is done.
					// no need to send email because commit once I submit (same person thru entire wf
					msg = "Your workflow has been completed and published.<br>Click Continue to view the new plan.";
				}
				else
				{
					// In this case, the workflow is going forward, but it is not completed yet.
					msg = "Your workflow has been submitted for approval.<br>You will receive an Email Notification when the processing is done.";

					// send email notification if CurrentExecutor != Owner
					PrmWf.notifyExecutor(pstuser, flowObj, app);
				}
				
				// post a page to inform the user about the status of his submission
				response.sendRedirect("../msg.jsp?msg="+msg+ "&go=project/cr.jsp");
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

<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">

<div id="fader" style="position:absolute; top:200px; left:50px; width:600px; text-align:center;"></div>
<!-- adjust style= to position messages -->

<SCRIPT LANGUAGE="JavaScript">
<!-- Begin
var texts = new Array(
"<font size='+2' color='{COLOR}' face='Arial'><strong>Processing Request</strong></font>",
"<font size='+2' color='{COLOR}' face='Arial'><strong>Please Wait</strong></font>");

<jsp:include page="../fade.js" flush="true"/>

//  End -->
</script>

</head>

<title>Workflow Processing</title>
<body onLoad="fade()"  bgcolor="#000000" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="100%" height="100%" border="0" cellspacing="0" cellpadding="0">

<!-- TOP BANNER -->

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">
		<table width="100%" border="0" cellspacing="0" cellpadding="0">
		  	<tr>
		    	<td width="100%" valign="top">
					<!-- Top -->
					<jsp:include page="../head.jsp" flush="true"/>
					<!-- End of Top -->
				</td>
			</tr>
			<tr>
				<td>
				<table><tr>
				<td width="20">&nbsp;</td>
				<td>
				<b class="head">Workflow Processing</b>
				</td></tr>
				</table>
				</td>
			</tr>

			<tr><td height="3"><img src="../i/spacer.gif" width="1" height="3" border="0"></td></tr>

			<tr>
				<td>
				<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
					<tr>
					<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
					</tr>
				</table>
				</td>
			</tr>
		</table>
	</td>
</tr>




<tr><td>&nbsp;</td><tr>


<tr>
	<td>
		<!-- Footer -->
		<jsp:include page="../foot.jsp" flush="true"/>
		<!-- End of Footer -->
	</td>
</tr>


<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>
