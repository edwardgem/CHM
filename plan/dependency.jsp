<%
////////////////////////////////////////////////////
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	dependency.jsp
//	Author:	ECC
//	Date:	04/10/04
//	Description:
//		Set task dependencies.
//
//	Modification:
//		@ECC112405	Added Duration and Gap to task.
//		@ECC120305a	Re-evaluate the dates for all the tasks that have dependencies or gap defined.
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	String projIdS = request.getParameter("projId");
	if ((pstuser instanceof PstGuest) || (projIdS == null))
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}

	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ( (iRole & user.iROLE_ADMIN) > 0 )
			isAdmin = true;

	projectManager pjMgr = projectManager.getInstance();
	taskManager tkMgr = taskManager.getInstance();

	String selectedTaskIdS = request.getParameter("taskId");
	int selectedTaskId = 0;
	int length = 0;
	int [] dependArr = new int[0];
	task selectedTask = null;

	if (selectedTaskIdS != null)
	{
		selectedTaskId = Integer.parseInt(selectedTaskIdS);

		// get dependency list: all those who depend on me
		dependArr = tkMgr.findId(pstuser, "Dependency='" + selectedTaskIdS + "'");
		selectedTask = (task)tkMgr.get(pstuser, selectedTaskIdS);
	}

	project projObj = (project)pjMgr.get(pstuser, Integer.parseInt(projIdS));
	String projName = projObj.getDisplayName();
	String version = (String)projObj.getAttribute("Version")[0];

	// @ECC120305a Optimize project schedule
	String s = request.getParameter("eval");
	if (s!=null && s.equals("true"))
	{
		projObj.setScheduleByDependencies(pstuser);
		projObj = (project)pjMgr.get(pstuser, Integer.parseInt(projIdS));	// need to refresh the cache after the call
		session.removeAttribute("planStack");		// cleanup cache
	}

	int coordinatorId = Integer.parseInt((String)projObj.getAttribute("Owner")[0]);
	boolean isCoordinator = (coordinatorId == pstuser.getObjectId());

	// get task path name
	String ptIdS = request.getParameter("planTaskId");
	String stackName = "";
	if (ptIdS != null)
	{
		planTask ptk = (planTask)planTaskManager.getInstance().get(pstuser, ptIdS);
		stackName = TaskInfo.getTaskStack(pstuser, ptk);
		stackName = stackName.replaceAll(">>", "<br>&nbsp;&nbsp;&nbsp;&nbsp;>>");
		stackName = "<br>&nbsp;&nbsp;&nbsp;&nbsp;>>" + stackName;
	}

	// get the latest plan
	planManager planMgr = planManager.getInstance();
	String [] planNames = planMgr.findName(pstuser, "(ProjectID='" +projIdS+ "') && (Status='Latest')");
	plan latestPlan = (plan)planMgr.get(pstuser, planNames)[0];

	// Get plan task (stack is constructed first time when going into a plan)
	Stack planStack = (Stack)session.getAttribute("planStack");
	if(planStack==null || planStack.empty())
	{
		response.sendRedirect("../project/proj_plan.jsp");
		return;
	}
	Vector rPlan = (Vector)planStack.peek();

%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">

<jsp:include page="../init.jsp" flush="true"/>

<title>
	<%=Prm.getAppTitle()%> Task Dependencies
</title>

<script type="text/javascript">

function validation()
{
	var msg = "Changing dependencies may cause the task and project schedule to change.  Do you want to proceed?\n\n";
		msg += "   OK = Yes\n";
		msg += "   CANCEL = No";
	if (!confirm(msg))
		return;
	setDepend.submit();
}

function eval_dependency()
{
	var msg  = "Evaluate the dependencies may cause the task and project schedule to change.\n";
	    msg += "Do you really want to proceed?\n\n";
		msg += "   OK = Yes\n";
		msg += "   CANCEL = No";
	if (confirm(msg))
		location = "dependency.jsp?projId=<%=projIdS%>&&eval=true";
}

//-->
</script>

</head>

<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="715" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<table>

	<tr><td colspan="2">&nbsp;</td></tr>
	<tr>
	<td></td>
	<td width="500">
	<b class="head">Task Dependencies</b>
	</td></tr>

	<tr>
	<td></td>
	<td valign="top" class="title">
		&nbsp;&nbsp;&nbsp;<%=projName%><%=stackName%>
	</td>

<%	if (isAdmin || isCoordinator)
	{%>
	<td valign="bottom">
		<img src="../i/bullet_tri.gif" width="20" height="10">
		<a class="listlinkbold" href="javascript:eval_dependency()">Evaluate All Dependencies</a>
	</td>
<%	}%>

	</tr>
	</table>

	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>


<!-- Navigation SUB-Menu -->
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
<td width="100%" valign="top">

	<table border="0" width="100%" height="14" cellspacing="0" cellpadding="0">
		<tr>
			<td bgcolor='#EBECED'><img src='../i/spacer.gif' width='50' height='1'/></td>
			<td valign="top" class="bgsubnav">
				<table border="0" cellspacing="0" cellpadding="0">
				<tr class="bgsubnav">
	<!-- Project Plan -->
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="../project/proj_plan.jsp?projName=<%=projName%>" class="subnav">Project Plan</a></td>
					<td colspan="3" width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- Task Management -->
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="../project/task_update.jsp?projId=<%=projIdS%>&pTaskId=<%=ptIdS%>" class="subnav">Task Management</a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- Task Management -->
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="../project/task_updall.jsp?projId=<%=projIdS%>" class="subnav">Update All Tasks</a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- Dependencies -->
					<td width="20"><img src="../i/spacer.gif" width="7" height="1" border="0"></td>
					<td width="20" height="14"><img src="../i/nav_arrow.gif" width="20" height="14" border="0"></td>
					<td><a href="#" onClick="return false;" class="subnav"><u>Dependencies</u></a></td>
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- Timeline -->
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="timeline.jsp?projId=<%=projIdS%>" class="subnav">Timeline</a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
				</tr>
				</table>
			</td>
		</tr>
	</table>
	<table border="0" width="100%" height="1" cellspacing="0" cellpadding="0">
		<tr>
			<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
		</tr>
	</table>

</td>
</tr>
</table>
<!-- End of Navigation SUB-Menu -->



<!-- CONTENT -->

<!-- ************************************************ -->
	<form method="post" name="setDepend" action="post_dependency.jsp">
	<input type="hidden" name="projId" value='<%=projIdS%>'>
	<input type="hidden" name="taskId" value='<%=selectedTaskIdS%>'>
	<input type="hidden" name="planTaskId" value='<%=ptIdS%>'>
	<table width="100%" border="0" cellspacing="0" cellpadding="0">
	<tr><td><img src="../i/spacer.gif" height="25" width='15' /></td></tr>
	<tr>
	<td width="10"><img src="../i/spacer.gif" height="1" width="10" /></td>
	<td>
<%
	if ( (isAdmin || isCoordinator) && selectedTaskIdS!=null )
	{%>
		<table border="0" cellspacing="0" cellpadding="0">
			<tr>
			<td  height="23">
				<a href="../project/proj_plan.jsp" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('cancel','','../i/cnln.gif',1)"><img src="../i/cnlf.gif" name="cancel" border="0"></a>
			</td>
			<td height="23">
				<a href="javascript:validation();" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('Submit1','','../i/sbtn.gif',1)"><img src="../i/sbtf.gif" name="Submit1" border="0"></a>
			</td>
			</tr>

			<tr><td height="10"><img src="../i/spacer.gif" height="10" width="1" alt=" " /></td></tr>
		</table>
		<span class='ptextS3'>Check the boxes of those tasks that depend on this task, and then click Submit.</span>
<%
	}
	else
	{
		out.println("<span class='ptextS3'>Click a task name below to set dependencies on the task</span>");
	}
	out.print("<table><tr><td><img src='../i/spacer.gif' height='5' /></td></tr></table>");


	String bgcolor="";
	String[] levelInfo = new String[JwTask.MAX_LEVEL];
	// For insert choice 2
	String lastlevelInfo = "";
	String taskName;
	boolean isDisabled;
	for(int i = 0; i < rPlan.size(); i++)
	{
		Hashtable rTask = (Hashtable)rPlan.elementAt(i);
		String tName = (String)rTask.get("Name");
		String taskIdS = (String)rTask.get("TaskID");
		int taskId = Integer.parseInt(taskIdS);
		int planTaskId = Integer.parseInt((String)rTask.get("PlanTaskID"));

		PstAbstractObject tk = tkMgr.get(pstuser, taskIdS);
		if (tk.getAttribute("StartDate")[0] == null)
			continue;		// this is a container

		Object [] pLevel = (Object [])rTask.get("Level");
		Object [] pOrder = (Object [])rTask.get("Order");

		int level = ((Integer)pLevel[0]).intValue();
		int order = ((Integer)pOrder[0]).intValue();

		int width = 10 + 22 * level;
		order++;
		if (level == 0)
			levelInfo[level] = Integer.toString(order);
		else
			levelInfo[level] = levelInfo[level - 1] + "." + order;
		level++;


		//bgcolor = "bgcolor='#CCCCCC'";

		out.println("<table width='100%' border='0' cellspacing='0' cellpadding='0' " + bgcolor + " >");

		if (level == 1)
		{
			out.println("<tr height='5'><td colspan='6'><img src='../i/spacer.gif' width='2' height='5' border='0'></td></tr>");
		}
		out.println("<tr>");
		if (taskId != selectedTaskId)
		{
			if ( selectedTask!=null
				&& (selectedTask.isMyAncestor(pstuser, taskIdS)
					|| selectedTask.isMyDecendent(pstuser, taskIdS)) )
				isDisabled = true;
			else
				isDisabled = false;

			out.print("<td height='23' width='20' align='center'>"
					+ "<input type='checkbox' name='append_" + taskId + "'");
			for (int j=0; j<dependArr.length; j++)
			{
				if (taskId == dependArr[j])
				{
					out.print(" checked");
					break;
				}
			}
			if (isDisabled || selectedTaskIdS==null)
				out.print(" disabled");
			taskName = tName;
		}
		else
		{
			out.print("<td height='23' width='20'");
			taskName = "<font color='#cc0000'><b>" + tName + "</b></font>";
		}
		out.println("><a name='" + taskId + "'></a></td>");

		out.println("<td width='" + width + "' height='20'><img src='../i/spacer.gif' width='" + width + "' height='2' border='0'></td><td class='ptextS2'>");
		if (taskId != selectedTaskId)
		{
			out.println(levelInfo[level-1] + "&nbsp;&nbsp;"
				+ "<a href='dependency.jsp?projId=" + projIdS + "&taskId=" + taskId
				+ "&planTaskId=" + planTaskId + "#" + taskId + "'>" + taskName + "</a>");
		}
		else
		{
			out.println(levelInfo[level-1] + "&nbsp;&nbsp;" + taskName);
		}
		out.println("</tr>");

		lastlevelInfo = levelInfo[level-1];
	}
%>
<!-- append at the end -->
		</tr>
		<tr>
			<td colspan="5"></td>
			<td width="20"><img src="../i/spacer.gif" height="1" width="20" alt=" " /></td>
		</tr>

		<tr height='5'><td colspan='6'><img src='../i/spacer.gif' width='2' height='5' border='0'></td></tr>
		</table>

<%	if ( (isAdmin || isCoordinator) && selectedTaskIdS!=null )
	{%>
		<table border="0" cellspacing="0" cellpadding="0">
			<tr><td colspan="3" height="10"><img src="../i/spacer.gif" height="10" width="1" alt=" " /></td></tr>
			<tr>
			<td  height="23">
				<a href="../project/proj_plan.jsp" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('cancel1','','../i/cnln.gif',1)"><img src="../i/cnlf.gif" name="cancel1" border="0"></a>
			<td height="23">
				<a href="javascript:validation();" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('Submit2','','../i/sbtn.gif',1)"><img src="../i/sbtf.gif" name="Submit2" border="0"></a>
			</td>
			</tr>
		</table>
<%	}%>
	</td>
	</tr>
	<tr><td colspan="2">&nbsp;</td></tr>

	</form>
	</table>


<!-- ************************************************ -->

	</td>
</tr>

<tr><td>&nbsp;</td><tr>


<!-- BEGIN FOOTER TABLE -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

