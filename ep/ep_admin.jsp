<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2004, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: ep_admin.jsp
//	Author: ECC
//	Date:	07/05/03
//	Description: Employee personal profile.
//
//
//	Modification:
//	@081403ECC	Add PRM and SBM configurable option
//
/////////////////////////////////////////////////////////////////////
//
// ep_admin.jsp :
//

%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.omm.common.*" %>
<%@ page import = "oct.omm.client.*" %>
<%@ page import = "oct.omm.db.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>
<%@ page import = "util.*" %>
<%@ page import = "org.apache.log4j.Logger" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />
<%

	String VIEWONLY = "VIEWONLY";
	Logger l = PrmLog.getLog();

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	String backPage = "../ep/ep_home.jsp";
	Date lastLogin = (Date)session.getAttribute("lastLogin");

	// to check if session is CR or PRM
	boolean isCRAPP = false;
	String app = (String)session.getAttribute("app");
	if (app.equals("CR"))
		isCRAPP = true;
	

	if (session.getAttribute("role") == null)
		session.setAttribute("role", new Integer(0));
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	boolean isAdmin = (iRole & user.iROLE_ADMIN) > 0;
	int roleType = 0;		// default sub-menu
	if (isAdmin)
		roleType = 1;		// new user, new project, new company

	projectManager pjMgr = projectManager.getInstance();
	userManager uMgr = userManager.getInstance();

	String uid = request.getParameter("uid");
	int uidInt = 0;

	if ((uid == null) || (uid.equals("null")))
	{
		uidInt = pstuser.getObjectId();
		uid = Integer.toString(pstuser.getObjectId());
	}
	else
	{
		uidInt = Integer.parseInt(request.getParameter("uid"));
	}

	user detailUser = (user)uMgr.get(pstuser, uidInt);
	String sortby = (String) request.getParameter("sortby");

	SimpleDateFormat Formatter;
	String FirstName = (String)detailUser.getAttribute("FirstName")[0];
	String LastName = (String)detailUser.getAttribute("LastName")[0];
	String Title = (String)detailUser.getAttribute("Title")[0];

	// Workflow related pending list and status list
	List pendingList = PstFlowStepManager.getAllActiveStep((PstUserAbstractObject)pstuser);
%>


<head>
<title><%=app%> Admin</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<jsp:include page="../init.jsp" flush="true"/>

<script language="JavaScript">
<!--
function confirm_del()
{
	if (confirm('Do you want to delete the project and all its associated objects?')) {
		document.deleteProj.submit();
	}
}
//-->
</SCRIPT>

<%
	response.setHeader("Pragma", "No-Cache");
	response.setDateHeader("Expires", 0);
	response.setHeader("Cache-Control", "no-Cache");
%>

</head>

<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" height="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">
		<table width="100%" border="0" cellspacing="0" cellpadding="0">
		  <tr align="left" valign="top">
		    <td width="100%">
			<jsp:include page="../head.jsp" flush="true"/>
		</table>
<table border="0" cellspacing="0" cellpadding="0" width='100%'>
<tr>
</td>
  </tr>
  <tr align="left" valign="top">
    <td>
      <table width="90%" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td>
            <table width="100%" border="0" cellspacing="0" cellpadding="0">
              <tr>
                <td width="26" height="30"><a name="top">&nbsp;</a></td>
                <td height="30" align="left" valign="bottom" class="head">
				Welcome, <%=pstuser.getAttribute("FirstName")[0] %>.
				 </td>
              </tr>
            </table>
          </td>
        </tr>
        <tr>
          <td width="100%">
<!-- TAB -->
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Home" />
				<jsp:param name="subCat" value="Admin" />
				<jsp:param name="roleType" value="<%=roleType%>" />
			</jsp:include>
			</td>
	        </tr>

        <tr><td>&nbsp;</td></tr>


<!-- ********* Begin List of Projects -->
<%
	PstAbstractObject personObj = null;

	String bgcolor="";
	boolean even = false;
	//if (((String)session.getAttribute("app")).equals("PRM"))
	if (true)
	{	// show project list only if it is PRM
%>
		<tr>
          <td>
			<form method="post" name="deleteProj" action="postProjDelete.jsp">
            <table width="100%" border="0" cellspacing="0" cellpadding="0">
			  	<tr>
              		<td width="26">&nbsp;</td>
                	<td width="734">
				  		<table width="100%" border='0' cellpadding="0" cellspacing="0">
							<tr>
								<td class="heading">List of All Projects</td>
						    </tr>
							<tr>
								<td bgcolor="#EBECED" height="3"><img src="../images/spacer.gif" width="1" height="3" border="0"></td>
						    </tr>
						</table>
						<table width=100%"" border="0" cellspacing="0" cellpadding="0">
	              	<tr>
	                      <td colspan="14" height="2" bgcolor="#336699"><img src="../i/spacer.gif" width="2" height="2"></td>
	                </tr>
			<tr>
				<td width="6" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
				<td width="260" bgcolor="#6699cc" class="td_header"><strong>Project Name</strong></td>
				<td width="1" bgcolor="#FFFFFF" class="10ptype">&nbsp;</td>
				<td width="6"  bgcolor="#6699cc" class="10ptype">&nbsp;</td>
				<td width="150" bgcolor="#6699cc" class="td_header"><strong>Coordinator</strong></td>
				<td width="2" bgcolor="#FFFFFF" class="10ptype">&nbsp;</td>
				<td width="6"  bgcolor="#6699cc" class="10ptype">&nbsp;</td>
				<td width="125" bgcolor="#6699cc" class="td_header"><strong>Target Date</strong></td>
				<td width="2" bgcolor="#FFFFFF" class="10ptype">&nbsp;</td>
				<td width="6"  bgcolor="#6699cc" class="10ptype">&nbsp;</td>
				<td width="40" bgcolor="#6699cc" class="td_header"><strong>Status</strong></td>
				<td width="2" bgcolor="#FFFFFF" class="10ptype">&nbsp;</td>
				<td width="6"  bgcolor="#6699cc" class="10ptype">&nbsp;</td>
				<td  width="50" bgcolor="#6699cc" class="td_header"><strong>Delete</strong></td>
			</tr>

<%
	int [] projectObjId = pjMgr.findId(pstuser, "om_acctname='%'");
	if (projectObjId.length > 0)
	{
	PstAbstractObject [] projectObjList = pjMgr.get(pstuser, projectObjId);
	Util.sortName(projectObjList, true);

	String dot=null;
	Date expDate;
	String expDateS = new String();
	Formatter = new SimpleDateFormat ("MM/dd/yyyy");
	for (int i=0; i < projectObjList.length ; i++)
	{
		// project
		project projectObj = (project) projectObjList[i];
		String projDispName = projectObj.getDisplayName();
		int projId = projectObj.getObjectId();

		// updated since my lastLogin
		boolean bBold = false;
		Date lastUpdated = (Date)projectObj.getAttribute("LastUpdatedDate")[0];
		if ( lastUpdated != null && lastUpdated.compareTo(lastLogin) > 0)
			bBold = true;

		// status
		String color;
		String status = (String)projectObj.getAttribute("Status")[0];
		if (status == null)
		{
			//response.sendRedirect("../out.jsp?e=Data integrity error: project Status is undefined.  Please contact administrator.");
			//return;
			status = "";
			l.error("Data integrity error: project Status is undefined.");
		}

		// Arrays.sort(planTaskObjId);

		// get owner's full name
		String name = new String();
		String owner = (String)projectObj.getAttribute("Owner")[0];
		if(owner != null)
		{
			try {
				personObj = uMgr.get(pstuser, Integer.parseInt(owner));
				name = ((user)personObj).getFullName();
			} catch (PmpException e) {name = "-";}
		}

		// get expiration date
		expDate = (Date)projectObj.getAttribute("ExpireDate")[0];
		if (expDate != null)
			expDateS = Formatter.format(expDate);

		if (even)
		{
			bgcolor = "bgcolor='#EEEEEE'";
		}
		else
		{
			bgcolor = "bgcolor='#ffffff'";
		}
		even = !even;
%>
			<tr <%=bgcolor%>>
					<td class="plaintext"></td>
<%		if (!isCRAPP){%>
				<td class="plaintext"><a href="../project/proj_plan.jsp?projId=<%=projId%>"><%=projDispName%></a></td>
<%		}
		else{ %>
				<td class="plaintext"><a href="../project/cr.jsp?projId=<%=projId%>"><%=projDispName%></a></td>
<%		} %>
					<td class="plaintext"></td>
					<td class="plaintext"></td>
				<td class="plaintext"><a href="../ep/ep1.jsp?uid=<%=owner%>"><%=name%></a></td>
					<td class="plaintext"></td>
					<td class="plaintext"></td>
				<td class="plaintext"><%=expDateS%></td>
					<td class="plaintext"></td>
					<td class="plaintext"></td>

<%
			dot = "../i/";
			if (status.equals("Open")) {dot += "dot_lightblue.gif";}
			else if (status.equals("New")) {dot += "dot_orange.gif";}
			else if (status.equals("Completed")) {dot += "dot_green.gif";}
			else if (status.equals("Late")) {dot += "dot_red.gif";}
			else if (status.equals("On-hold")) {dot += "dot_grey.gif";}
			else if (status.equals("Close")) {dot += "dot_blue.gif";}
			else {dot += "dot_grey.gif";}
			out.print("<td class='listlink' " + bgcolor + " width='42' align='center'>");
			if (status != null)
			{
				out.print("<img src='" + dot + "' alt='" + status + "'>");
				if (bBold)
					out.print("<img src='../i/dot_redw.gif' alt='Updated'>");
			}
			out.print("</td>");
%>
					<td class="plaintext"></td>
					<td class="plaintext"></td>
				<td class="plaintext" align="center"><input type="checkbox" name="delete_<%=projectObj.getObjectId()%>"></td>
				<td class="plaintext" align="center"></td>
			</tr>
<%

	}	// for each project in the list
	}	// if there is any project defined
%>
				</table>
			 	</tr>
			 </table>
			 </form>

<table border="0" width="120" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td width="26" height="1" bgcolor="#FFFFFF"><img src="../i/spacer.gif" width="26" height="1" border="0"></td>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>
<table width="770">
	<tr>
		<td width="25">&nbsp;</td>
		<td class="tinytype" align="left">Project Status:
			&nbsp;&nbsp;<img src="../i/dot_orange.gif" border="0">New
			&nbsp;&nbsp;<img src="../i/dot_lightblue.gif" border="0">Open
			&nbsp;&nbsp;<img src="../i/dot_green.gif" border="0">Completed
			&nbsp;&nbsp;<img src="../i/dot_red.gif" border="0">Late
			&nbsp;&nbsp;<img src="../i/dot_grey.gif" border="0">On-hold
			&nbsp;&nbsp;<img src="../i/dot_black.gif" border="0">Closed
			&nbsp;&nbsp;<img src="../i/dot_redw.gif" border="0">Updated
		</td>
		<td align="right">
			<input type='button' class='button_medium' value='Delete' onclick='confirm_del();'>
		</td>
	</tr>
	<tr><td>&nbsp;<br><br></td></tr>
</table>

			</td>
		</tr>
<%	}%>

<!-- End of List of Projects -->


<!-- ****** WorkFlow ****** -->

        <tr>
          <td>
            <table width="100%" border="0" cellspacing="0" cellpadding="0">
<!--  Flow Status -->
			  <tr>
                <td><img src='../i/spacer.gif' width='26'/></td>
                <td width="100%">
				  		<table width="100%" border='0' cellpadding="0" cellspacing="0">
							<tr>
								<td class="heading">Project Plan Workflow</td>
						    </tr>
							<tr>
								<td bgcolor="#EBECED" height="3"><img src="../images/spacer.gif" width="1" height="3" border="0"></td>
						    </tr>
						</table>
						<table width=100%"" border="0" cellspacing="0" cellpadding="0">

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
		even = false;
		String name;

		for(int j = idAry.length - 1 ; j >= 0; j--)
		{
			PstFlow flowObj = (PstFlow)fMgr.get(pstuser, idAry[j]);

			// CONTEXT_OBJECT is the plan id (name)
			String objId = (String)flowObj.getAttribute(PstFlow.CONTEXT_OBJECT)[0];
			if (objId == null)
				continue;

			//Show the version number instead
			planManager planMgr = planManager.getInstance();
			plan planObj = null;
			try {planObj = (plan)planMgr.get(pstuser, objId);}
			catch (PmpException e) {
				System.out.println("fail to find plan for id = " + objId
						+ " from flow; might be a project flow instead.");
				continue;
			}
			String conObj = (String)planObj.getAttribute("Version")[0];

			if (even)
				bgcolor="bgcolor='#EEEEEE'";
			else
				bgcolor="bgcolor='#ffffff'";
            even = !even;

			// get project name
			project pj = (project)pjMgr.get(pstuser,
					Integer.parseInt((String)planObj.getAttribute("ProjectID")[0]));

			// get change submitter name (changed by)
			name = (String)flowObj.getAttribute("Owner")[0];
			user flowInitiator = null;
			if (name != null)
			{
				try
				{
					flowInitiator = (user)uMgr.get(pstuser, name);
					if(flowInitiator.getAttribute("FirstName")[0] != null)
						name = (String)flowInitiator.getAttribute("FirstName")[0];
					if(flowInitiator.getAttribute("LastName")[0] != null)
						name = name + " " + (String)flowInitiator.getAttribute("LastName")[0];
				}
				catch (PmpException e)
				{
					l.error("Flow initiator " + name + " is not found in database.  Please clean up flow object " + idAry[j]);
				}
			}

			personObj = null;
			String activeStep = (String)flowObj.getAttribute(PstFlow.CURRENT_ACTIVE_STEP)[0];
			String currentExecutorStr = "-";
			String displayName = "-";

			if(activeStep != null)
			{
				PstFlowStep stepObj = (PstFlowStep)fsMgr.get(pstuser, activeStep);
				String currentExecutor = (String)stepObj.getAttribute(PstFlowStep.CURRENT_EXECUTOR)[0];
				if (currentExecutor == null) currentExecutor = "0";
				personObj = null;
				try
				{
					personObj = uMgr.get(pstuser, Integer.parseInt(currentExecutor));
					currentExecutorStr = ((user)personObj).getFullName();
				} catch (Exception e) {
					currentExecutorStr = "-";
					l.error("Current executor " + currentExecutor + " is not found in database.  Please clean up step object " + activeStep);
				}

				String stepDefName = (String)stepObj.getAttribute(PstFlowStep.FLOW_STEP_DEF_NAME)[0];
				if(stepDefName != null)
				{
					displayName = (String)stepObj.getAttribute(PstFlowStep.DISPLAY_NAME)[0];
					if (displayName == null)
						displayName = stepDefName;

					if (currentExecutor.equals(pstuser.getObjectName()))
					{
						// I am responsible to execute this active step, enable link
						displayName = "<a href='../wfpages/PlanApprovalGroupLeaderVerify.jsp?stepName="
							+ activeStep + "'><font color='#aa0000'>Pending: " + displayName + "</font></a>";
					}
					else
						displayName = "Pending: " + displayName;
				}
			}
			else
			{
				// Showing more info after the flow is ended
				if (flowObj.getAttribute(PstFlow.STATUS)[0] != null)
				{
					String state = flowObj.getAttribute(PstFlow.STATUS)[0].toString();
					if (state.equals(PstFlowConstant.ST_FLOW_ABORT))
					{
						displayName = "Rejected";
					}
					else if (state.equals(PstFlowConstant.ST_FLOW_COMMIT))
					{
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
				<%if (personObj != null)
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
				catch (PmpException e) {
					l.error("Current executor " + currentExecutor + " is not found in database.  Please clean up step object " + activeStep);
					currentExecutorStr = ((user)personObj).getFullName();
				}

				String stepDefName = (String)stepObj.getAttribute(PstFlowStep.FLOW_STEP_DEF_NAME)[0];
				if(stepDefName != null)
				{
					displayName = (String)stepObj.getAttribute(PstFlowStep.DISPLAY_NAME)[0];
					if (displayName == null)
						displayName = stepDefName;

					if (currentExecutor.equals(pstuser.getObjectName()))
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
					<td class="10ptype"></td>
					<td class="10ptype"></td>
					<td class="10ptype"></td>
					<td class="10ptype"></td>
					<td class="10ptype"></td>
					<td class="10ptype"></td>
					<td class="10ptype"></td>
					<td class="10ptype"></td>
					<td class="plaintext"></td>
					<td class="plaintext"></td>
					<td class="plaintext" valign="top"><a href="../ep/ep1.jsp?uid=<%=personObj.getObjectId()%>"><%=currentExecutorStr%></a></td>

					<td class="plaintext"></td>
					<td class="plaintext"></td>
					<td class="plaintext" valign="top"><%=displayName%></td>
				</tr>
<%
			}	// END for i
			out.println("<tr " + bgcolor + ">" + "<td colspan='14'><img src='../i/spacer.gif' width='2' height='3'></td></tr>");
		}	// END for j
	}
%>
					</table>
			  	 </td>
				 <td width="20">&nbsp;</td>
			  </tr>
<!-- End of Flow Status -->

			  <tr><td colspan="3">&nbsp;</td></tr>
		   	  <tr><td colspan="3">&nbsp;</td></tr>

      </table>
    </td>
  </tr>

</table>
	</td>
</tr>

</table>
<p>&nbsp;</p>
<jsp:include page="../foot.jsp" flush="true"/>
</body>
</html>
