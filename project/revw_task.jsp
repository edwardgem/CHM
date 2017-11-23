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
//			@AGQ050506	Renamed Done Date to Completion Date & Expire to Due
//			@AGQ050506	Support of TBD and N/A
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
<%@ page import = "java.text.*" %>
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

	String projIdS = request.getParameter("projId");
	if (projIdS == null) {
		projIdS = (String)session.getAttribute("projId");
	}
	String viewStatus = request.getParameter("status");
	if (viewStatus == null) viewStatus = "all";
	String s = request.getParameter("owner");
	int viewOwnerId = 0;
	if (s != null) viewOwnerId = Integer.parseInt(s);

	String backPage = "../project/review.jsp?projId=" + projIdS;

	int uid = pstuser.getObjectId();
	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ( (iRole & user.iROLE_ADMIN) > 0 )
		isAdmin = true;

	projectManager pjMgr = projectManager.getInstance();
	project proj = (project)pjMgr.get(pstuser, Integer.parseInt(projIdS));
	String projName = proj.getObjectName();

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
// @AGQ050506	
	String format = "MM/dd/yy";
	Formatter = new SimpleDateFormat (format);

	userManager uMgr = userManager.getInstance();
	int projId = proj.getObjectId();

	// task statistics
	taskManager tkMgr = taskManager.getInstance();

	// need to get the latest plan for this project
	planManager planObjMgr = planManager.getInstance();
	ids = planObjMgr.findId(pstuser, "Status='Latest' && ProjectID='"+projId+"'");
	PstAbstractObject [] targetObjList = planObjMgr.get(pstuser, ids);

	// there is only one plan which is latest for this project
	plan latestPlan = (plan)targetObjList[0];

	// Get plan tasks for this project plan
	planTaskManager ptkMgr = planTaskManager.getInstance();
	ids = ptkMgr.findId(pstuser, "get_plan_tasks", latestPlan);
	targetObjList = ptkMgr.get(pstuser, ids);

	Arrays.sort(targetObjList, new Comparator() {
		public int compare(Object o1, Object o2)
		{
			try{
			Integer d2 = (Integer)((planTask)o2).getAttribute("PreOrder")[0];
			Integer d1 = (Integer)((planTask)o1).getAttribute("PreOrder")[0];
			return d1.compareTo(d2);
			}catch(Exception e){System.out.println("Internal error sorting plan task list [currentProject.jsp].");
				return 0;}
		}
	});

	// all project team people
	Object [] projTeam = proj.getAttribute("TeamMembers");
	PstAbstractObject [] teamMember = uMgr.get(pstuser, projTeam);

	// sort the employee list for owner assignment
	Arrays.sort(teamMember, new Comparator() {
			public int compare(Object o1, Object o2)
		      {
			   user emp1 = (user) o1;
			   user emp2 = (user) o2;

			   try
			   {
					String eName1 = emp1.getAttribute("FirstName")[0] + " " +
							emp1.getAttribute("LastName")[0];
			  		String eName2 = emp2.getAttribute("FirstName")[0] + " " +
							emp1.getAttribute("LastName")[0];

					   return eName1.compareToIgnoreCase(eName2);
			   }
			   catch(Exception e)
			   {
			       throw new ClassCastException("Could not compare.");
			   }
		      }
	});
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
						<b>Task Analysis</b>
					</td></tr>
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
							<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
						</tr>
					</table>
					<table border="0" width="780" height="14" cellspacing="0" cellpadding="0">
						<tr>
							<td width="20" height="14" bgcolor="#FFFFFF"><img src="../i/spacer.gif" height="1" border="0"></td>
							<td valign="top" class="BgSubnav">
								<table border="0" cellspacing="0" cellpadding="0">
								<tr class="BgSubnav">
								<td width="40"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
					<!-- Current Project -->
									<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td><a href="review.jsp?projId=<%=projIdS%>" class="subnav">Current Project</a></td>
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<!-- Task Analysis -->
									<td width="7"><img src="../i/spacer.gif" width="7" height="1" border="0"></td>
									<td width="15" height="14"><img src="../i/nav_arrow.gif" width="20" height="14" border="0"></td>
									<td><a href="#" onClick="return false;" class="subnav"><u>Task Analysis</u></a></td>
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
							<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
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
<form>
	<tr>
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
	<tr><td>&nbsp;<br></tr></td>
	</table>

<!-- *************************   Page Headers   ************************* -->

<!-- LABEL -->
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td align="left" valign="middle" class="level2">
		<form name="reviewTask" action="revw_task.jsp" method="post" >
			<input type="hidden" name="projId" value="<%=projIdS%>">
		&nbsp;
		Task Owner:&nbsp;&nbsp;&nbsp;
			<select name="owner" class="formtext" onchange="submit()">
			<option value="0" <%if (viewOwnerId==0) {%> selected <%}%>> - - All - - </option>
<%
		for(int i=0; i < teamMember.length; i++)
		{
			String firstEmpName = (String)teamMember[i].getAttribute("FirstName")[0];
			String lastEmpName = (String)teamMember[i].getAttribute("LastName")[0];
%>
			<option value="<%=teamMember[i].getObjectId() %>"
<%
			if (viewOwnerId == teamMember[i].getObjectId())
			{
%>				selected
<%			}
%>				><%=((user)teamMember[i]).getFullName()%></option>
<%		}
%>



			</select>
		&nbsp;&nbsp;&nbsp;
		Task Status:&nbsp;&nbsp;&nbsp;
			<select name="status" class="formtext" onchange="submit()">
			<option value="all" <%if (viewStatus.equals("all")) {%> selected <%}%>> - - All - - </option>
			<option value="New" <%if (viewStatus.equals("New")) {%> selected <%}%>> New </option>
			<option value="Open" <%if (viewStatus.equals("Open")) {%> selected <%}%>> Open </option>
			<option value="Completed" <%if (viewStatus.equals("Completed")) {%> selected <%}%>> Completed </option>
			<option value="On-hold" <%if (viewStatus.equals("On-hold")) {%> selected <%}%>> On-hold </option>
			<option value="Late" <%if (viewStatus.equals("Late")) {%> selected <%}%>> Late </option>
			<option value="Canceled" <%if (viewStatus.equals("Canceled")) {%> selected <%}%>> Canceled </option>
			</select>
		</form>
	</td>
</tr>

<tr>
<td>
	<table width="100%" border='0' cellpadding="0" cellspacing="0">
	<tr>
	<td bgcolor="#EBECED" height="3"><img src="../i/spacer.gif" width="1" height="3" border="0"></td>
	</tr>
	</table>
	<table width="100%" border="0" cellspacing="0" cellpadding="0">
	<tr>
	<td colspan="38" height="2" bgcolor="#336699"><img src="../i/spacer.gif" width="2" height="2"></td>
	</tr>
	<tr>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="244" bgcolor="#6699cc" class="td_header"><strong>&nbsp;Task Name</strong></td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="50" bgcolor="#6699cc" class="td_header" align="center"><strong>Owner</strong></td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="24" bgcolor="#6699cc" class="td_header"><strong>St.</strong></td>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="55" bgcolor="#6699cc" class="td_header" align="center"><strong>Start Date</strong></td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="55" bgcolor="#6699cc" class="td_header" align="center"><strong>Due Date</strong></td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="55" bgcolor="#6699cc" class="td_header" align="center"><strong>Complete Date</strong></td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="55" bgcolor="#6699cc" class="td_header" align="center"><strong>Last Updt</strong></td>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="35" bgcolor="#6699cc" class="td_header" align="center"><strong>Len</strong></td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="35" bgcolor="#6699cc" class="td_header" align="center"><strong>Days Pass</strong></td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="35" bgcolor="#6699cc" class="td_header" align="center"><strong>Days Left</strong></td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="35" bgcolor="#6699cc" class="td_header" align="center"><strong>Days Late</strong></td>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="35"bgcolor="#6699cc" class="td_header" align="center"><strong># of Blog</strong></td>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="38" bgcolor="#6699cc" class="td_header" align="center"><strong>Wt.</strong></td>
	</tr>
	</table>


<!-- PROJ PLAN -->
<%

try {
	String bgcolor="";
	boolean even = false;
	String[] levelInfo = new String[JwTask.MAX_LEVEL];
	String ownerIdS, tStatus, currentStatus;
	task t;
	int pTaskId;
	int count = 0;
	DecimalFormat df = new DecimalFormat("0.00");

	user empObj = null;
	String lastOwner = "";
	String dot=null;

	Date today = new Date(Formatter.format(new Date()));
	Date dt;
	int length, daysElapsed, daysLeft, daysLate, blogNum;
	double weight;
	int totalDays = 0;
	TaskInfo ati;

	// for all the planTask of the latest plan
	TaskInfo [] ti = new TaskInfo[targetObjList.length];

	for(int i = 0; i < targetObjList.length; i++)
	{	// a list of plan task
		planTask ptargetObj = (planTask)targetObjList[i];
		pTaskId = ptargetObj.getObjectId();
		backPage = "../blog/blog_task.jsp?projId=" +projId+ ":planTaskId=" +pTaskId;

		// only show non-DEPRECATED plantask
		currentStatus = (String)ptargetObj.getAttribute("Status")[0];
		if (currentStatus.equals(task.DEPRECATED))
			continue;

		int taskID = Integer.parseInt((String)ptargetObj.getAttribute("TaskID")[0]);
		Object [] pLevel = ptargetObj.getAttribute("Level");
		Object [] pOrder = ptargetObj.getAttribute("Order");

		// Owner must be stored in task, otherwise once you load a new version
		// of plan (a new set of plantask), you lost the owner in history.
		// First get the task associated to this taskplan
		t = (task)tkMgr.get(pstuser, taskID);
		ati = new TaskInfo();
		ati.name			= (String)ptargetObj.getAttribute("Name")[0];
		ati.pTaskIdS		= ptargetObj.getObjectName();
		ati.owner			= (String)t.getAttribute("Owner")[0];
		ati.status		= (String)t.getAttribute("Status")[0];
		ati.startDate		= (Date)t.getAttribute("CreatedDate")[0];
		ati.expireDate	= (Date)t.getAttribute("ExpireDate")[0];
		ati.completeDate	= (Date)t.getAttribute("CompleteDate")[0];
		ati.updateDate	= (Date)t.getAttribute("LastUpdatedDate")[0];

		daysElapsed = 0;
		daysLeft = 0;
		daysLate = 0;
		length = 0;
		dt = ati.startDate;
		if (dt != null)
		{
			if (ati.completeDate != null)
				daysElapsed = (int)Math.ceil((ati.completeDate.getTime() - dt.getTime())/86400000);
			else
				daysElapsed = (int)Math.ceil((today.getTime() - dt.getTime())/86400000);
			if (daysElapsed < 0) daysElapsed = 0;
		}
		ati.daysElapsed = daysElapsed;

		Date dt1 = ati.expireDate;
		if (dt1 != null && !phase.isSpecialDate(dt1))
		{
			daysLeft = (int)Math.ceil((dt1.getTime() - today.getTime())/86400000+1);
			if (daysLeft < 0)
			{
				daysLate = - daysLeft;
				daysLeft = 0;
			}

			length = (int)Math.ceil((dt1.getTime() - dt.getTime())/86400000+1);
			if (length < 0) length = 0;
		}
		ati.daysLeft = daysLeft;
		ati.daysLate = daysLate;
		ati.length = length;
		totalDays += length;	//daysElapsed;

		// # of blogs posted
		ids = resultManager.getInstance().findId(pstuser, "TaskID='" + taskID + "' && Type!='Alert'");
		ati.blogNum = ids.length;

		ati.level	= ((Integer)pLevel[0]).intValue();
		ati.order	= ((Integer)pOrder[0]).intValue() + 1;

		ti[count++] = ati;
	}

	boolean bShowAllStatus = false;
	if (viewStatus.equals("all"))
		bShowAllStatus = true;

	for (int i=0; i<count; i++)
	{
		ati = ti[i];
		if (ati == null) break;

		int level		= ati.level;
		int order		= ati.order;
		int width = 5 + 22 * Math.min(level,3);

		if (level == 0)
			levelInfo[level] = String.valueOf(order);
		else
			levelInfo[level] = levelInfo[level - 1] + "." + order;

		if (!bShowAllStatus && !ati.status.equals(viewStatus))
			continue;

		ownerIdS = ati.owner;
		if (viewOwnerId != 0 && viewOwnerId != Integer.parseInt(ownerIdS))
			continue;

		length		= ati.length;
		daysElapsed	= ati.daysElapsed;
		daysLeft	= ati.daysLeft;
		daysLate	= ati.daysLate;
		blogNum		= ati.blogNum;
		weight		= (double)length * 100 / (double)totalDays;

		if (even)
			bgcolor = "bgcolor='#EEEEEE'";
		else
			bgcolor = "bgcolor='#ffffff'";
		even = !even;

		out.println("<table width='100%' " + bgcolor +" cellspacing='2' cellpadding='2'>");
		out.print("<tr><td width='229'><table width='210' cellspacing='0' cellpadding='0'><tr>");
		out.print("<td width='" + width + "' height='20'>&nbsp;</td>");
		out.println("<td class='plaintext_grey' width='10' valign='top'>");
		out.print(levelInfo[level] + "&nbsp;" + "&nbsp;</td>");
		out.print("<td class='listlink'>");
		out.print("<a class='listlink' href='../project/task_update.jsp?projId="
			+projId+ "&pTaskId=" + ati.pTaskIdS + "'>");
		out.print(ati.name + "</a>");
		out.println("</td>");
		out.print("</tr></table></td>");

		out.print("<td class='listlink' align='center' width='45'>");
		if (ownerIdS != null)
		{
			// ECC: need to optimize this in the near future
			if (!ownerIdS.equals(lastOwner))
				empObj = (user)uMgr.get(pstuser,Integer.parseInt(ownerIdS));
			uid = empObj.getObjectId();
			lastOwner = ownerIdS;
			out.print("<a class='listlink' href='../ep/ep1.jsp?uid=" + uid + "'>");
			out.print((String)empObj.getAttribute("FirstName")[0]);
			out.print("</a>");
		}
		out.println("</td>");

		// status
		tStatus = ati.status;
		dot = "../i/";
		if (tStatus.equals("Open")) {dot += "dot_lightblue.gif";}
		else if (tStatus.equals("New")) {dot += "dot_orange.gif";}
		else if (tStatus.equals("Completed")) {dot += "dot_green.gif";}
		else if (tStatus.equals("Late")) {dot += "dot_red.gif";}
		else if (tStatus.equals("On-hold")) {dot += "dot_grey.gif";}
		else if (tStatus.equals("Canceled")) {dot += "dot_cancel.gif";}
		else {dot += "dot_grey.gif";}
		out.print("<td class='listlink' width='20' align='center'>");
		out.print("<img src='" + dot + "' alt='" + tStatus + "'>");
		out.println("</td>");

		out.print("<td class='listtext_small' width='47' align='center'>");
		out.print(Formatter.format(ati.startDate));
		out.println("</td>");

		out.print("<td class='listtext_small' width='47' align='center'>");
// @AGQ050506		
		out.print(phase.parseDateToString(ati.expireDate, format));
		out.println("</td>");

		dt = ati.completeDate;
		if (dt == null) s = "-";
		else s = Formatter.format(dt);
		out.print("<td class='listtext_small' width='48' align='center'>");
		out.print(s);
		out.println("</td>");

		dt = ati.updateDate;
		if (dt == null) s = "-";
		else s = Formatter.format(dt);
		out.print("<td class='listtext_small' width='48' align='center'>");
		out.print(s);
		out.println("</td>");

		out.print("<td class='listtext_small' width='30' align='center'>");
		out.print(length);
		out.println("</td>");

		out.print("<td class='listtext_small' width='30' align='center'>");
		out.print(daysElapsed);
		out.println("</td>");

		out.print("<td class='listtext_small' width='30' align='center'>");
		out.print(daysLeft);
		out.println("</td>");

		out.print("<td class='listtext_small' width='30' align='center'>");
		out.print(daysLate);
		out.println("</td>");

		out.print("<td class='listtext_small' width='30' align='center'>");
		out.print(blogNum);
		out.println("</td>");

		out.print("<td class='listtext_small' width='35' align='right'>");
		out.print(df.format(weight));
		out.println("</td>");

		out.print("</td>");
		out.println("</tr>");
		out.println("</table>");

	}

} catch (Exception e)
{
	response.sendRedirect("../out.jsp?msg=Internal error in displaying project plan.  Please contact administrator.");
	return;
}
%>

		</td>
		</tr>
		<tr><td colspan="2">&nbsp;</td></tr>
	</table>
<!-- END PROJ PLAN -->



<table>
	<tr>
		<td width="10">&nbsp;</td>
		<td class="tinytype" align="center">Task Status:
			&nbsp;&nbsp;<img src="../i/dot_orange.gif" border="0">New
			&nbsp;&nbsp;<img src="../i/dot_lightblue.gif" border="0">Open
			&nbsp;&nbsp;<img src="../i/dot_green.gif" border="0">Completed
			&nbsp;&nbsp;<img src="../i/dot_red.gif" border="0">Late
			&nbsp;&nbsp;<img src="../i/dot_grey.gif" border="0">On-hold
			&nbsp;&nbsp;<img src="../i/dot_cancel.gif" border="0">Canceled
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
