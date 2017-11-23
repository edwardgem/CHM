<html>
<%
//
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: review.jsp
//	Author: ECC
//	Date:	10/18/04
//	Description: Review current project.
//
//
//	Modification:
//			@041906SSI	Added sort function to Project names.
//
/////////////////////////////////////////////////////////////////////
//
%>

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
<%@ page import = "util.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />
<%
	////////////////////////////////////////////////////////
	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}

	String projIdS = null;
	String projName = request.getParameter("projName");
	if (projName!=null && projName.equals("session")) {
		projName = null;
	}
	else if (projName == null) {
		projIdS = request.getParameter("projId");
	}
	
	if (projName==null && projIdS==null) {
		projIdS = (String)session.getAttribute("projId");
		if (projIdS == null) {
			response.sendRedirect("proj_select.jsp?backPage=review.jsp");
			return;
		}
	}

	int uid = pstuser.getObjectId();
	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ( (iRole & user.iROLE_ADMIN) > 0 )
		isAdmin = true;

	projectManager pjMgr = projectManager.getInstance();
	project proj;
	if (projName != null) {
		proj = (project)pjMgr.get(pstuser, projName);
		projIdS = String.valueOf(proj.getObjectId());
	}
	else {
		proj = (project)pjMgr.get(pstuser, Integer.parseInt(projIdS));
		projName = proj.getObjectName();
	}
	session.setAttribute("projId", projIdS);

	String backPage = "../project/review.jsp?projId=" + projIdS;

	// only show it to project team member unless it is public project
	boolean bReadOnly = false;
	String pjType = (String)proj.getAttribute("Type")[0];
	String pjName = projName.replaceAll("'", "\\\\'");	// just for SQL
	int [] ids = pjMgr.findId(pstuser, "om_acctname='" + pjName + "' && TeamMembers=" + pstuser.getObjectId());
	if ((ids.length <= 0))
	{
		if (pjType.equals("Private"))
		{
			response.sendRedirect("../out.jsp?e=Access declined");
			return;
		}
		else if (pjType.equals("Public Read-only"))
			bReadOnly = true;
	}

	SimpleDateFormat Formatter;
	Formatter = new SimpleDateFormat ("MM/dd/yy");

	userManager uMgr = userManager.getInstance();
	int projId = proj.getObjectId();
	String coordinatorIdS = (String)proj.getAttribute("Owner")[0];
	int coordinatorId = Integer.parseInt(coordinatorIdS);

	// project's TownID stores the TownID this proj belongs to
	String townIdS = (String)proj.getAttribute("TownID")[0];
	int townId = Integer.parseInt(townIdS);
	String projTownName = PstManager.getNameById(pstuser, townId);
	session.setAttribute("townName", projTownName);

	user a = (user)session.getAttribute("pstuser");
	boolean bChangeCurrentPlan = false;
	String lastProjIdS = (String)a.getAttribute("LastProject")[0];
	if ((lastProjIdS == null) || (projId != Integer.parseInt(lastProjIdS)))
	{
		// cannot use pstuser which only has partial attributes
		a.setAttribute("LastTown", townIdS);
		a.setAttribute("LastProject", String.valueOf(projId));
		uMgr.commit(a);
		bChangeCurrentPlan = true;		// notify plan stack to refresh
	}
	session.setAttribute("projectId",  String.valueOf(projId));		// for plan stack


	user aUser = (user)uMgr.get(pstuser, coordinatorId);
	String coordinator = aUser.getObjectName();
	String lname = (String)aUser.getAttribute("LastName")[0];
	String uname = aUser.getAttribute("FirstName")[0] + (lname==null?"":(" " + lname));

	String status = (String)proj.getAttribute("Status")[0];
	String color = null;
	if (status.equals("Open")) {color = "#2222aa";}
	else if (status.equals("New")) {color = "#cc7700";}
	else if (status.equals("Completed")) {color = "#22aa22";}
	else if (status.equals("Late")) {color = "#ff2222";}
	else if (status.equals("On-hold")) {color = "#777777";}
	else {color = "#333333";}

	String type = (String)proj.getAttribute("Type")[0];
	if (type == null) type = "Private";

	Date today = new Date();
	int daysElapsed = 0;
	String startDate, createdDate, deadline, completeDate;

	Date compDt = (Date)proj.getAttribute("CompleteDate")[0];
	Date dt = (Date)proj.getAttribute("CreatedDate")[0];
	if (dt != null)
		createdDate = Formatter.format(dt);
	else
		createdDate = "";

	dt = (Date)proj.getAttribute("StartDate")[0];
	if (dt != null)
	{
		startDate = Formatter.format(dt);
		if (compDt != null)
			daysElapsed = (int)Math.ceil((compDt.getTime() - dt.getTime())/86400000);
		else
			daysElapsed = (int)Math.ceil((today.getTime() - dt.getTime())/86400000);
		if (daysElapsed < 0) daysElapsed = 0;
	}
	else
		startDate = "Not specified";

	int daysLeft = 0;
	int daysLate = 0;
	int projLength = 0;
	Date dt1 = (Date)proj.getAttribute("ExpireDate")[0];
	if (dt1 != null)
	{
		deadline = Formatter.format(dt1);
		daysLeft = (int)Math.ceil((dt1.getTime() - today.getTime())/86400000+1);
		if (daysLeft < 0)
		{
			daysLate = -(int)Math.ceil((dt1.getTime() - today.getTime())/86400000); //- daysLeft;
			daysLeft = 0;
		}

		projLength = (int)Math.ceil((dt1.getTime() - dt.getTime())/86400000);
		if (projLength < 0) projLength = 0;
	}
	else
		deadline = "Not specified";

	if (compDt != null)
		completeDate = Formatter.format(compDt);
	else
		completeDate = "Not yet completed";

	int sizeFactor = 1;
	int ii = projLength;
	while (ii < 200)
		ii = projLength * ++sizeFactor;		// setting sizeFactor

	// task statistics
	taskManager tkMgr = taskManager.getInstance();
	int [] ids1 = tkMgr.findId(pstuser, "ProjectID='"+projId+"'");
	int totalTasks = ids1.length;
	ids = tkMgr.findId(pstuser, "ProjectID='"+projId+"' && Status='New'");
	int newct=ids.length;
	ids = tkMgr.findId(pstuser, "ProjectID='"+projId+"' && Status='Open'");
	int open=ids.length;
	ids = tkMgr.findId(pstuser, "ProjectID='"+projId+"' && Status='Completed'");
	int completed=ids.length;
	ids = tkMgr.findId(pstuser, "ProjectID='"+projId+"' && Status='Late'");
	int late=ids.length;
	ids = tkMgr.findId(pstuser, "ProjectID='"+projId+"' && Status='On-hold'");
	int onhold=ids.length;
	ids = tkMgr.findId(pstuser, "ProjectID='"+projId+"' && Status='Canceled'");
	int canceled=ids.length;

	// task dependencies
	// future: depends on others = risk factor; others depend on me = impact factor
	int totalDep = 0;
	Object [] dep;
	for (int i=0; i<ids1.length; i++)
	{
		task tk = (task)tkMgr.get(pstuser, ids1[i]);
		dep = tk.getAttribute("Dependency");
		if (dep[0] != null)
			totalDep += dep.length;
	}


	////////////////////////////////////////////////////////

%>


<head>
<title>PRM Review</title>
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
						<b>Project Review</b>
						</td>
					</tr>
	            </table>
	          </td>
	        </tr>
			<tr>
          		<td width="100%">
					<!-- Navigation Menu -->
					<jsp:include page="../in/ireview.jsp" flush="true">
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
							<td valign="top" align="left" class="BgSubnav">
								<table border="0" cellspacing="0" cellpadding="0">
								<tr class="BgSubnav">
								<td width="40"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
					<!-- Current Project -->
									<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
									<td width="7"><img src="../i/spacer.gif" width="7" height="1" border="0"></td>
									<td width="15" height="14"><img src="../i/nav_arrow.gif" width="20" height="14" border="0"></td>
									<td><a href="#" onClick="return false;" class="subnav"><u>Current Project</u></a></td>
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<!-- Task Analysis -->
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td><a href="revw_task.jsp?projId=<%=projIdS%>" class="subnav">Task Analysis</a></td>
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<!-- Project History -->
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td><a href="history.jsp" class="subnav">Project History</a></td>
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<!-- Project Plan Change -->
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td><a href="revw_planchg.jsp" class="subnav">Project Plan Change</a></td>
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
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

		 <table width="760" border="0" cellspacing="0" cellpadding="0">


			<tr><td colspan="2">&nbsp;</td></tr>
			<tr>
				<td width="734">

<!-- Project Name -->

	<table width="100%" cellpadding="0" cellspacing="0">
	<form>
	<tr>
		<td width="20"><img src="../i/spacer.gif" width="5" border="0"></td>
		<td class="heading">
			Project Name:&nbsp;&nbsp;
			<select name="projId" class="formtext" onchange="submit()">
<%
	int [] projectObjId = pjMgr.getProjects(pstuser);
	if (projectObjId.length > 0)
	{
		PstAbstractObject [] projectObjList = pjMgr.get(pstuser, projectObjId);
		//@041906SSI
		Util.sortName(projectObjList, true);
		
		String pName;
		project pj;
		Date expDate;
		String expDateS = new String();
		for (int i=0; i < projectObjList.length ; i++)
		{
			// project
			pj = (project) projectObjList[i];
			pName = pj.getDisplayName();

			out.print("<option value='" + pj.getObjectId() +"' ");
			if (pj.getObjectId() == projId)
				out.print("selected");
			out.print(">" + pName + "</option>");
		}
	}
%>
			</select>

		</td>
	</tr>
	</form>

	<tr><td>&nbsp;<br><br></td></td>
	</table>
	</td>
	</tr>

	<tr>
		<td>
		<table border=0 cellpadding=0 cellspacing=1><tr>
			<td class="bar" width="20"><img src="../i/spacer.gif" border="0"></td>
			<td class="bar">Days:&nbsp;&nbsp;</td>
<%	if (daysElapsed > 0)
	{
		int d = 0;
		if (daysElapsed <= projLength) d = daysElapsed;
		else d = projLength;
		ii=d*sizeFactor;
		if (ii<15) ii=15;
		out.println("<td class='bar' bgcolor='#0033bb' height='10' width='"
			+ ii + "' align='center'><img src='../i/spacer.gif' border='0'><font color='white'>"
			+ d + "</font></td>");
	}
	if (daysLeft > 0)
	{
		ii=daysLeft*sizeFactor;
		if (ii<15) ii=15;
		out.println("<td class='bar' bgcolor='#cccccc' height='10' width='"
			+ ii +"' align='center'><img src='../i/spacer.gif' border='0'>"
			+ daysLeft + "</td>");
	}
	else if (daysLate > 0)
	{
		ii=daysLate*sizeFactor;
		if (ii<15) ii=15;
		out.println("<td class='bar' bgcolor='#dd0000' height='10' width='"
			+ ii + "' align='center'><img src='../i/spacer.gif' border='0'><font color='white'>"
			+ daysLate + "</font></td>");
	}
%>

		</tr></table>
		</td>
	</tr>
	<tr>
		<td>&nbsp;</td>
	</tr>

<tr><td>
<table width="100%" cellpadding="0" cellspacing="0">

	<tr>
		<td>
<!-- PROJ OVERALL REVIEW -->
<table width="350">

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext"><b>Project Status:</b></td>
		<td class="plaintext"><font color="<%=color%>"><%=status%></font></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext"><b>Coordinator:</b></td>
		<td class="plaintext"><%=uname%> &#60;<%=coordinator%>&#62;</td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext"><b>Project Type:</b></td>
		<td class="plaintext"><%=type%></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext"><b>Creation Date:</b></td>
		<td class="plaintext"><%=createdDate%></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext"><b>Start Date:</b></td>
		<td class="plaintext"><%=startDate%></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext"><b>Expiration Date:</b></td>
		<td class="plaintext"><%=deadline%></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext"><b>Completion Date:</b></td>
		<td class="plaintext"><%=completeDate%></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext"><b>Project Length:</b></td>
		<td class="plaintext"><%=projLength%> Days</td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext"><b>Days Elapsed:</b></td>
		<td class="plaintext"><%=daysElapsed%> Days</td>
	</tr>

<% if (daysLate <= 0) {%>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext"><b>Days Left:</b></td>
		<td class="plaintext"><%=daysLeft%> Days</td>
	</tr>
<% } else {%>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext"><b>Days Late:</b></td>
		<td class="plaintext"><font color="#cc3300"><%=daysLate%> Days</font></td>
	</tr>
<% }%>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext"><b>No. of Dependencies:</b></td>
		<td class="plaintext"><%=totalDep%></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext"><b>Last Updated:</b></td>
		<td class="plaintext"><%=Formatter.format((Date)proj.getAttribute("LastUpdatedDate")[0])%></td>
	</tr>

</table>
		</td>


<!-- RIGHT SIDE: TASK STAT -->
		<td valign="top" align="left">
<table width="280">
	<tr><td width="15">&nbsp;</td>
		<td class="plaintext"><b>Task Statistics:</b></td>
	</tr>
	<tr><td width="15">&nbsp;</td>
		<td>
		<table border cellpadding="5" cellspacing="0">
			<tr>
			<td bgcolor="#eeeeee" class="plaintext" width="50">New</td>
			<td class="plaintext" align="center" width="50"><%=newct%></td>
			<td class="plaintext" align="center" width="50"><%=newct*100/totalTasks%>%</td>
			</tr>
			<tr>
			<td bgcolor="#eeeeee" class="plaintext" width="50">Open</td>
			<td class="plaintext" align="center" width="50"><%=open%></td>
			<td class="plaintext" align="center" width="50"><%=open*100/totalTasks%>%</td>
			</tr>
			<tr>
			<td bgcolor="#eeeeee" class="plaintext" width="50">Completed</td>
			<td class="plaintext" align="center" width="50"><%=completed%></td>
			<td class="plaintext" align="center" width="50"><%=completed*100/totalTasks%>%</td>
			</tr>
			<tr>
			<td bgcolor="#eeeeee" class="plaintext" width="50">Late</td>
			<td class="plaintext" align="center" width="50"><%=late%></td>
			<td class="plaintext" align="center" width="50"><%=late*100/totalTasks%>%</td>
			</tr>
			<tr>
			<td bgcolor="#eeeeee" class="plaintext" width="50">On-hold</td>
			<td class="plaintext" align="center" width="50"><%=onhold%></td>
			<td class="plaintext" align="center" width="50"><%=onhold*100/totalTasks%>%</td>
			</tr>
			<tr>
			<td bgcolor="#eeeeee" class="plaintext" width="50">Canceled</td>
			<td class="plaintext" align="center" width="50"><%=canceled%></td>
			<td class="plaintext" align="center" width="50"><%=canceled*100/totalTasks%>%</td>
			</tr>
		</table>
	<tr><td width="15">&nbsp;</td>
		<td class="plaintext">&nbsp;Total no. of tasks: <%=totalTasks%></td>
	</tr>
	</td></tr>
</table>
	</td>
</tr>

</table>

	</td>
	</tr>
	</table>


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
