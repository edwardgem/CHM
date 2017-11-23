<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
////////////////////////////////////////////////////
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	updplan.jsp
//	Author:	ECC
//	Date:	04/10/04
//	Description:
//		Update the project plan and create a new version of the plan.
//		If the person is not the project coordinator, the system will
//		route the update as a request to the coordinator and ask for
//		approval.
//
//	Modification:
//
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.io.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />


<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	String projIdS = request.getParameter("projId");
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	boolean isGuestRole = ((iRole & user.iROLE_GUEST) > 0);


	if ((pstuser instanceof PstGuest) || projIdS == null || isGuestRole)
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	String backPage = "../plan/updplan.jsp?projId=" + projIdS;

	projectManager projMgr = projectManager.getInstance();
	project projObj = (project)projMgr.get(pstuser, Integer.parseInt(projIdS));
	String projDispName = projObj.getDisplayName();
	String version = (String)projObj.getAttribute("Version")[0];

	// get the latest plan
	planManager planMgr = planManager.getInstance();
	String [] planNames = planMgr.findName(pstuser, "(ProjectID='" +projIdS+ "') && (Status='Latest')");
	plan latestPlan = (plan)planMgr.get(pstuser, planNames)[0];

	// Get plan task (stack is constructed first time when going into a plan)
	Stack planStack = (Stack)session.getAttribute("planStack");
	if (planStack == null || planStack.empty())
	{
		response.sendRedirect("../out.jsp?msg=Internal error in opening plan stack.  Please contact administrator.");
		return;
	}
	Vector rPlan = (Vector)planStack.peek();
	user a = (user)pstuser;
	a.setAttribute("LastProject", null);
	userManager.getInstance().commit(a);
	
	// to check if session is CR or PRM
	boolean isCRAPP = Prm.isCR();
	String app = Prm.getAppTitle();

%>

<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>

<jsp:include page="../init.jsp" flush="true"/>

<title>
	<%=app%> Update Project Plan
</title>

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
	<td>
	<b class="head">
	Create a New Version of Project Plan
	</b>
	</td></tr>

	<tr>
	<td></td>
	<td valign="top" class="title">
		&nbsp;&nbsp;&nbsp;<%=projDispName%>&nbsp;(<%=version%>)
	</td>
	</td></tr>
	</table>

	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" /></td>
	    </tr>
	</table>


<!-- Navigation SUB-Menu -->
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
<td width="100%" valign="top">

	<table border="0" width="100%" height="14" cellspacing="0" cellpadding="0">
		<tr>
			<td valign="top" class="bgsubnav">
				<table border="0" cellspacing="0" cellpadding="0">
				<tr class="bgsubnav">
					<td width="20" height="14"><img src="../i/spacer.gif" width="20" height="1" border="0" /></td>
	<!-- File Repository -->
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"/></td>
					<td width="20"><img src="../i/spacer.gif" width="10" height="1" border="0"/></td>
					<td><a href="../project/cr.jsp?projId=<%=projIdS%>" class="subnav">File Repository</a></td>
					<td width="20"><img src="../i/spacer.gif" width="10" height="1" border="0"/></td>
					
<%if (!isCRAPP){%>
	<!-- Project Plan -->
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"/></td>
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"/></td>
					<td><a href="../project/proj_plan.jsp?projId=<%=projIdS%>" class="subnav">Project Plan</a></td>
					<td colspan="3" width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"/></td>
<%} %>
					
	<!-- Create a New Plan Version -->
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"/></td>
					<td width="20"><img src="../i/spacer.gif" width="7" height="1" border="0"/></td>
					<td width="20" height="14"><img src="../i/nav_arrow.gif" width="20" height="14" border="0"/></td>
					<td><a href="#" onclick="return false;" class="subnav"><u>Create New Version</u></a></td>
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"/></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"/></td>
				</tr>
				</table>
			</td>
		</tr>
	</table>
	<table border="0" width="100%" height="1" cellspacing="0" cellpadding="0">
		<tr>
			<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"/></td>
		</tr>
	</table>

</td>
</tr>
</table>
<!-- End of Navigation SUB-Menu -->



<!-- CONTENT -->

<!-- ************************************************ -->
	<form method="post" name="deletePlan" action="postplanDelete.jsp">
	<input type="hidden" name="projId" value='<%=projIdS%>'/>
	<table width="100%" border='0' cellspacing="0" cellpadding="0">
	
	<tr><td><img src="../i/spacer.gif" height="30" width='1'/></td></tr>
	
	
	<tr>
	<td width="10"><img src="../i/spacer.gif" height="1" width="10" alt=" " /></td>
	<td>
		<table border="0" cellspacing="0" cellpadding="0">
			<tr>
			<td  height="23">
				<input type='button' class='button_medium' value='Delete' style='width:100px'; onclick='deletePlan.submit();'/>&nbsp;
			</td>
			<td height="23">
				<input type='button' class='button_medium' value='Undo' style='width:100px'; onclick="location='postplanUndo.jsp?projId=<%=projIdS%>';"/>&nbsp;
			</td>
			<td height="23">
				<input type='button' class='button_medium' value='Redo' style='width:100px'; onclick="location='postplanRedo.jsp?projId=<%=projIdS%>';"/>&nbsp;
			</td>
			<td height="23">
				<input type='button' class='button_medium' value='Submit' style='width:100px'; onclick="location='../wfpages/PlanApprovalINITIAL_STEP.jsp?projId=<%=projIdS%>';"/>&nbsp;
			</td>
			</tr>

			<tr><td height="10"><img src="../i/spacer.gif" height="10" width="1" alt=" " /></td></tr>
		</table>


<%
	out.println("<table width='100%' border='0' cellspacing='0' cellpadding='0'>");

	String bgcolor="";
	String[] levelInfo = new String[JwTask.MAX_LEVEL];
	// For insert choice 2
	String lastlevelInfo = "";
	int i;
	for(i = 0; i < rPlan.size(); i++)
	{
		Hashtable rTask = (Hashtable)rPlan.elementAt(i);
		String status = (String)rTask.get("Status");
		String pName = (String)rTask.get("Name");
		//Object [] pTaskID = (Object [])rTask.get("TaskID");
		Object [] pLevel = (Object [])rTask.get("Level");
		Object [] pOrder = (Object [])rTask.get("Order");
		//Object [] pPreOrder = (Object [])rTask.get("PreOrder");
		//Object [] pPlanID = ptargetObj.getAttribute("PlanID");
		int level = ((Integer)pLevel[0]).intValue();
		int order = ((Integer)pOrder[0]).intValue();

		int width = 10 + 22 * level;
		order++;
		if (level == 0)
		{
			levelInfo[level] = Integer.toString(order);
		}
		else
		{
			levelInfo[level] = levelInfo[level - 1] + "." + order;
		}
		level++;

		//bgcolor = "bgcolor='#CCCCCC'";

		if (level == 1)
		{
			out.println("<tr height='5'><td colspan='6'><img src='../i/spacer.gif' width='2' height='5' border='0'></td></tr>");
		}
		out.println("<tr>");
		if (status.charAt(0) == 'D')
		{
			out.println("<td height='23' width='22' align='center'>&nbsp;</td>");
		}
		else
		{
			out.println("<td height='23' width='20' align='center'><input type='checkbox' name='" + i + "' value='delete'></td>");
		}
		out.println("<td width='" + width + "' class='plaintext_big' height='20'><img src='../i/spacer.gif' width='" + width + "' height='2' border='0'></td><td class='plaintext_big'>");
		switch (status.charAt(0))
		{
			case 'O':  // Original
				out.println(levelInfo[level-1] + "&nbsp;" + "&nbsp;" + pName);
				break;
			case 'D':  // Old, Deprecated
				out.println("<strike>" + levelInfo[level-1] + "&nbsp;" + "&nbsp;" + pName + "</strike>");
				break;
			case 'N':  // New
				out.println("<font color='red'>" + levelInfo[level-1] + "&nbsp;" + "&nbsp;" + pName + "</font>");
				break;
			case 'C':  // Change
				out.println("<font color='green'>" + levelInfo[level-1] + "&nbsp;" + "&nbsp;" + pName + "</font>");
				break;
		}
		if (status.charAt(0) == 'D')
		{
			out.println("<td width='45' align='right'>&nbsp;</td>");
			out.println("<td width='55' align='center'>&nbsp;</td>");
			out.println("<td width='20'>&nbsp;</td>");
		}
		else  // All other support change and insert
		{
			out.print("<td style='border-bottom:#777777 dotted 1px; min-width:200px;'><img src='../i/spacer.gif' width='100%' height='1'/></td>");
			out.println("<td width='45' align='right'><a class='plaintext_blue' href='popPlanUpdate.jsp?realorder=" + i + "&levelInfo=" + levelInfo[level-1] + "&backPage=" +backPage+ "'>change</a></td>");
			out.println("<td width='55' align='right'><a class='plaintext_blue' href='popPlanInsert.jsp?realorder=" + i + "&levelInfo=" + levelInfo[level-1] + "&lastlevelInfo=" + lastlevelInfo + "&backPage=" +backPage+ "'>insert</a></td>");
			lastlevelInfo = levelInfo[level-1];
			out.println("<td width='20'>&nbsp;</td>");
		}
	}
	//System.out.println("---------");
	//JwTask.printPlan(rPlan);
	//System.out.println("---------");

%>
<!-- append at the end -->
		</tr>
		<tr><td colspan='6'><img src='../i/spacer.gif' width='1' height='20'/></td></tr>
		<tr>
			<td colspan="4"></td>
			<td width="55" align="right"><a class='plaintext_blue' href="popPlanInsert.jsp?realorder=<%=i%>&levelInfo=&lastlevelInfo=<%=lastlevelInfo%>&backPage=<%=backPage%>">append</a></td>
			<td width="20"><img src="../i/spacer.gif" height="1" width="20" alt=" " /></td>
		</tr>

		<tr height='5'><td colspan='6'><img src='../i/spacer.gif' width='2' height='5' border='0'/></td></tr>
		</table>

		<table border="0" cellspacing="0" cellpadding="0">
			<tr><td colspan="3" height="10"><img src="../i/spacer.gif" height="10" width="1" alt=" " /></td></tr>
			<tr>
			<td  height="23">
				<input type='button' class='button_medium' value='Delete' style='width:100px'; onclick='deletePlan.submit();'/>&nbsp;
			</td>
			<td height="23">
				<input type='button' class='button_medium' value='Undo' style='width:100px'; onclick="location='postplanUndo.jsp?projId=<%=projIdS%>';"/>&nbsp;
			</td>
			<td height="23">
				<input type='button' class='button_medium' value='Redo' style='width:100px'; onclick="location='postplanRedo.jsp?projId=<%=projIdS%>';"/>&nbsp;
			</td>
			<td height="23">
				<input type='button' class='button_medium' value='Submit' style='width:100px'; onclick="location='../wfpages/PlanApprovalINITIAL_STEP.jsp?projId=<%=projIdS%>';"/>&nbsp;
			</td>
			</tr>
		</table>
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

