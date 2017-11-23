<html>
<%
//
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: revw_planchg.jsp
//	Author: ECC
//	Date:	10/18/04
//	Description: Review project history.  Only closed project has history.
//		Get all the history records of the projects that I am authorized to see.
//		Display them in the table.
//		For now, show all history record without authorization check.
//
//
//	Modification:
//		@ECC063005
//			Enable the option of member update plan.  User may need to
//			process workflow steps now.
//		@ECC061907 Support CR to enable team member to submit plan change request for approval.
//		@ECC112609	Add Tab in project page to access workflow approval.
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "util.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.omm.common.*" %>
<%@ page import = "oct.omm.client.*" %>
<%@ page import = "oct.omm.db.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>
<%@ page import = "org.apache.log4j.Logger" %>

<%
	String noSession = "../out.jsp?go=project/revw_planchg.jsp";
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%
	////////////////////////////////////////////////////////
	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	Logger l = PrmLog.getLog();

	int uid = pstuser.getObjectId();
	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ( (iRole & user.iROLE_ADMIN) > 0 )
		isAdmin = true;

	// @ECC061907 to check if session is CR or PRM
	boolean isCRAPP = false;
	String app = (String)session.getAttribute("app");
	if (app.contains("CR"))
		isCRAPP = true;

	projectManager pjMgr = projectManager.getInstance();
	userManager uMgr = userManager.getInstance();

	String myUidS = String.valueOf(pstuser.getObjectId());

	SimpleDateFormat Formatter;
	Formatter = new SimpleDateFormat ("MM/dd/yy");


	////////////////////////////////////////////////////////
%>


<head>
<title>PRM</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="../init.jsp" flush="true"/>

</head>

<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" height="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">
		<!-- Main Tables -->
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
	            <table width="780" border="0" cellspacing="0" cellpadding="0">
					<tr>
						<td width="26" height="30"><a name="top">&nbsp;</a></td>
						<td width="754" height="30" align="left" valign="bottom" class="head">
						<b>Project Plan Changes</b>
					</td></tr>
	            </table>
	          </td>
	        </tr>
			<tr>
          		<td width="100%">
					<!-- Navigation Menu -->
					<jsp:include page="../in/iproj.jsp" flush="true">
					<jsp:param name="role" value="<%=iRole%>" />
					</jsp:include>
					<!-- End of Navigation Menu -->
				</td>
	        </tr>
			<tr>
          		<td width="100%" valign="top">
					<!-- Navigation SUB-Menu -->
					<table border="0" width="780" height="1" cellspacing="0" cellpadding="0">
						<tr>
							<td width="20" height="1" bgcolor="#FFFFFF"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
							<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../images/spacer.gif" width="1" height="1" border="0"></td>
						</tr>
					</table>
					<table border="0" width="780" height="14" cellspacing="0" cellpadding="0">
						<tr>
							<td width="20" height="14" bgcolor="#FFFFFF"><img src="../i/spacer.gif" height="1" border="0"></td>
							<td valign="top" class="BgSubnav">
								<table border="0" cellspacing="0" cellpadding="0">
								<tr class="BgSubnav">
								<td width="40"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>

					<!-- File Repository -->
									<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td><a href="cr.jsp" class="subnav">File Repository</a></td>
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<!-- Project Plan -->
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td><a href="proj_plan.jsp" class="subnav">Project Plan</a></td>
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
<!-- Task Analysis
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td><a href="revw_task.jsp" class="subnav">Task Analysis</a></td>
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
-->
					<!-- Plan Change -->
									<td width="7"><img src="../i/spacer.gif" width="7" height="1" border="0"></td>
									<td width="15" height="14"><img src="../i/nav_arrow.gif" width="20" height="14" border="0"></td>
									<td><a href="#" class="subnav" onClick="return false;"><u>Plan Change</u></a></td>
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<!-- Work In-Tray -->
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td><a href="../box/worktray.jsp" class="subnav">Work In-Tray</a></td>
									<td width="15" onClick="return false;"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
								</tr>
								</table>
							</td>
						</tr>
					</table>
					<table border="0" width="780" height="1" cellspacing="0" cellpadding="0">
						<tr>
							<td width="20" height="1" bgcolor="#FFFFFF"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
							<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../images/spacer.gif" width="1" height="1" border="0"></td>
						</tr>
					</table>
					<!-- End of Navigation SUB-Menu -->
				</td>
	        </tr>
		</table>
		<!-- Content Table -->

		 <table width="855" border="0" cellspacing="0" cellpadding="0">


			<tr><td colspan="2">&nbsp;</td></tr>
			<tr>
				<td width="20"><img src="../i/spacer.gif" width="5" border="0"></td>
				<td width="835">

<!-- Project Name -->

	<table width="100%" cellpadding="0" cellspacing="0">
	<tr>
		<td class="heading">
		</td>
	</tr>

	</table>

<!-- *************************   Page Headers   ************************* -->

<!-- LABEL -->
<table width="100%" border="0" cellspacing="0" cellpadding="0">

<tr>
<td>

            <table width="780" border="0" cellspacing="0" cellpadding="0">
<!--  Flow Status -->
			  <tr>
                <td width="0"></td>
                <td width="734">
				  <table width="734" border="0" cellspacing="0" cellpadding="0">
                    <tr>
                      <td colspan="14" height="2" bgcolor="#336699"><img src="../i/spacer.gif" width="2" height="2"></td>
                    </tr>
		<tr>
			<td width="6"  bgcolor="#6699cc" class="10ptype">&nbsp;</td>
			<td width="200" bgcolor="#6699cc" class="td_header"><strong>Project Name</strong></td>

			<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
			<td width="6"  bgcolor="#6699cc" class="10ptype">&nbsp;</td>
			<td width="70"  bgcolor="#6699cc" class="td_header"><strong>Version</strong></td>

			<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
			<td width="6"  bgcolor="#6699cc" class="10ptype">&nbsp;</td>
			<td width="100"  bgcolor="#6699cc" class="td_header"><strong>Changed By</strong></td>

			<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
			<td width="6"  bgcolor="#6699cc" class="10ptype">&nbsp;</td>
			<td width="100"  bgcolor="#6699cc" class="td_header"><strong>Waiting For</strong></td>

			<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
			<td width="6"  bgcolor="#6699cc" class="10ptype">&nbsp;</td>
			<td bgcolor="#6699cc" class="td_header"><strong>Approval Status</strong></td>
		</tr>
<%
	PstFlowManager fMgr			= PstFlowManager.getInstance();
	PstFlowStepManager fsMgr	= PstFlowStepManager.getInstance();
	int idAry[] = fMgr.findId(pstuser, "om_acctname='%'");

	if(idAry != null)
	{
		boolean even = false;
		String bgcolor="";
		String name;
		PstAbstractObject personObj;
		PstAbstractObject [] flowArr = fMgr.get(pstuser, idAry);
		Util.sortDate(flowArr, "CreatedDate");

		for(int j = flowArr.length-1 ; j >= 0; j--)
		{
			if (even)
				bgcolor="bgcolor='#EEEEEE'";
			else
				bgcolor="bgcolor='#ffffff'";
            even = !even;

			PstFlow flowObj = (PstFlow)flowArr[j];	//(PstFlow)fMgr.get(pstuser, idAry[j]);

			// CONTEXT_OBJECT is the plan id (name)
			String objId = (String)flowObj.getAttribute(PstFlow.CONTEXT_OBJECT)[0];

			//Show the version number instead
			planManager planMgr = planManager.getInstance();
			project pj;
			String conObj;

			try {
				plan planObj = (plan)planMgr.get(pstuser, objId);
				conObj = (String)planObj.getAttribute("Version")[0];

				// get project name
				pj = (project)pjMgr.get(pstuser,
								Integer.parseInt((String)planObj.getAttribute("ProjectID")[0]));
			}
			catch (PmpException e) {
				// most likely project flow: ignore for plan change
				continue;
			}

			// filter only see project that I am a member of
			String pjMemberS = Util2.getAttributeString(pj, "TeamMembers", ";");
			if (!pjMemberS.contains(myUidS))
				continue;

			// get change submitter name (changed by)
			name = (String)flowObj.getAttribute("Owner")[0];
			user flowInitiator = null;
			try {
				flowInitiator = (user)uMgr.get(pstuser, Integer.parseInt(name));
				name = flowInitiator.getFullName();
			}
			catch (PmpException e) {
				l.error("Flow initiator " + name + " is not found in database.  Please clean up flow object " + flowObj.getObjectId());
			}

			personObj = null;
			String activeStep = (String)flowObj.getAttribute(PstFlow.CURRENT_ACTIVE_STEP)[0];
			String currentExecutorStr = "-";
			String displayName = "-";

			if(activeStep != null) {
				PstFlowStep stepObj = (PstFlowStep)fsMgr.get(pstuser, activeStep);
				String currentExecutor = (String)stepObj.getAttribute(PstFlowStep.CURRENT_EXECUTOR)[0];
				if (currentExecutor == null) currentExecutor = "0";

				personObj = null;
				try {
					personObj = uMgr.get(pstuser, Integer.parseInt(currentExecutor));
					currentExecutorStr = ((user)personObj).getFullName();
				}
				catch (PmpException e) {
					l.error("Current executor " + currentExecutor + " is not found in database.  Please clean up step object " + activeStep);
				}

				String stepDefName = (String)stepObj.getAttribute(PstFlowStep.FLOW_STEP_DEF_NAME)[0];
				if(stepDefName != null) {
					displayName = (String)stepObj.getAttribute(PstFlowStep.DISPLAY_NAME)[0];
					if (displayName == null)
						displayName = stepDefName;
					if (currentExecutor.equals(String.valueOf(pstuser.getObjectId()))) {
						// I am responsible to execute this active step, enable link
						displayName = "<a href='../wfpages/PlanApprovalGroupLeaderVerify.jsp?stepName="
							+ activeStep + "'><font color='#aa0000'>Pending: " + displayName + "</font></a>";
					}
					else
						displayName = "Pending: " + displayName;
				}
			}
			else {
				// Showing more info after the flow is ended
				if (flowObj.getAttribute(PstFlow.STATUS)[0] != null) {
					String state = flowObj.getAttribute(PstFlow.STATUS)[0].toString();
					if (state.equals(PstFlowConstant.ST_FLOW_ABORT)) {
						displayName = "Rejected";
					}
					else if (state.equals(PstFlowConstant.ST_FLOW_COMMIT)) {
						displayName = "Approved and published";
					}
				}

				activeStep = (String)flowObj.getAttribute(PstFlow.FIRST_STEP_INSTANCE)[0];
			}
%>
			<tr <%=bgcolor %>>
				<td class="plaintext">&nbsp;</td>
				<td class="plaintext" valign="top"><%=pj.getDisplayName()%></td>

				<td class="plaintext"></td>
				<td class="plaintext"></td>
				<td class="plaintext" valign="top"><a href="../wfpages/PlanApprovalGroupLeaderVerify.jsp?stepName=<%=activeStep%>&mode=VIEWONLY"><%=conObj%></a></td>

				<td class="plaintext"></td>
				<td class="plaintext"></td>
				<td class="plaintext" valign="top">
					<%if (flowInitiator!=null)
						out.print("<a href='../ep/ep1.jsp?uid=" +flowInitiator.getObjectId()+ "'>" +name+ "</a>");
					  else
					  	out.print("-");
					%>
				</td>

				<td class="plaintext"></td>
				<td class="plaintext"></td>
				<td class="plaintext" valign="top">
<%
				if (personObj != null)
					out.print("<a href='../ep/ep1.jsp?uid=" +personObj.getObjectId()+ "'>" +currentExecutorStr+ "</a>");
				else
				  	out.print("-");
%>
				</td>

				<td class="plaintext"></td>
				<td class="plaintext"></td>
				<td class="plaintext" valign="top"><%=displayName%></td>
			</tr>
<%
			// there can have more than one pending step (parallel branches in WF)
			// show for the other pending steps below
			for (int i = 1; i < flowObj.getAttribute(PstFlow.CURRENT_ACTIVE_STEP).length; i++)
			{
				activeStep = (String)flowObj.getAttribute(PstFlow.CURRENT_ACTIVE_STEP)[i];
				if (activeStep == null) continue;

				PstFlowStep stepObj = (PstFlowStep)fsMgr.get(pstuser, activeStep);
				String currentExecutor = (String)stepObj.getAttribute(PstFlowStep.CURRENT_EXECUTOR)[0];
				if (currentExecutor == null) currentExecutor = "0";


				try {personObj = uMgr.get(pstuser, Integer.parseInt(currentExecutor));}
				catch (PmpException e)
				{
					l.error("Current executor " + currentExecutor + " is not found in database.  Please clean up step object " + activeStep);
					currentExecutorStr = ((user)personObj).getFullName();
				}

				String stepDefName = (String)stepObj.getAttribute(PstFlowStep.FLOW_STEP_DEF_NAME)[0];
				if(stepDefName != null)
				{
					displayName = (String)stepObj.getAttribute(PstFlowStep.DISPLAY_NAME)[0];
					if (displayName == null)
						displayName = stepDefName;
					if (currentExecutor.equals(String.valueOf(pstuser.getObjectId())))
					{
						// I am responsible to execute this active step, enable link
						displayName = "<a href='../wfpages/PlanApprovalGroupLeaderVerify.jsp?stepName="
							+ activeStep + "'><font color='#aa0000'>Pending: " + displayName + "</font></a>";
					}
					else
						displayName = "Pending: " + displayName;
				}


%>
				<tr <%=bgcolor %>>
					<td colspan='8'></td>
					<td class="plaintext"></td>
					<td class="plaintext"></td>
					<td class="plaintext" valign="top">
						<a href="../ep/ep1.jsp?uid=<%=personObj.getObjectId()%>">
						<%=currentExecutorStr%></a></td>

					<td class="plaintext"></td>
					<td class="plaintext"></td>
					<td class="plaintext" valign="top"><%=displayName%></td>
				</tr>
<%
			}
			out.println("<tr " + bgcolor + ">" + "<td colspan='14'><img src='../i/spacer.gif' width='2' height='3'></td></tr>");
		}
	}
%>
					</table>
			  	 </td>
				 <td width="20">&nbsp;</td>
			  </tr>
<!-- End of Flow Status -->

      </table>
</td>
</tr>

</table>
<!-- END HISTORY -->


		<!-- End of Content Table -->
		<!-- End of Main Tables -->
	</td>
</tr>
</table>
</td>
</tr>

<tr>
	<td>
		<!-- Footer -->
		<jsp:include page="../foot.jsp" flush="true"/>
		<!-- End of Footer -->
	</td>
</tr>
</table>
</body>
</html>
