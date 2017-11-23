<%@ page contentType="text/html; charset=utf-8"%>

<%
//
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: proj_new3.jsp
//	Author: ECC
//	Date:	04/10/04
//	Description: Plan listing page for creating new plan
//
//	Modification:
//		@ECC011707	Support Department Name in project, task and attachment for authorization.
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "util.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	// Step 3 of 3: review and publish project plan
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	String townName = request.getParameter("TownName");
	if ((pstuser instanceof PstGuest) || (townName == null))
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	String townIdS = request.getParameter("TownID");

	// to check if session is CR
	boolean isCRAPP = false;
	String app = (String)session.getAttribute("app");
	if (app.indexOf("CR")!=-1)
		isCRAPP = true;

	String label1 = "Plan";
	if (isCRAPP)
		label1 = "Space";

	String projName = request.getParameter("ProjName");
	String desc = request.getParameter("Description");
	String start = request.getParameter("StartDate");
	String expire = request.getParameter("ExpireDate");
	String planString = request.getParameter("Plan");
	String option = request.getParameter("ProjectOption");
	String deptName = request.getParameter("Department");		// can be null

// begin setting up plan stack

	// Plan is represented by a Vector of Task
	// Task is represented by a hashtable.
	Stack planStack = null;
	Vector rPlan = new Vector();

	// process the plan script to create a list of JwTask
	JwTask [] taskArray = null;
	try
	{
		JwTask jw = new JwTask();
		taskArray = jw.processScript(planString);
	}
	catch (PmpException e)
	{
		StringTokenizer st = new StringTokenizer(e.toString(), ":");
		st.nextToken();
		String msg = st.nextToken();
		msg += ": \"<b>" + st.nextToken() + "</b>\"";
		response.sendRedirect("../out.jsp?msg="+ msg);
		return;
	}
	int i = 0;
	while (true)
	{
		// pTask is the persistent Task
		// rTask is the ram task which is in cache
		if (taskArray==null || taskArray[i] == null) break;

		JwTask pTask = taskArray[i++];
		Hashtable rTask = new Hashtable();
		rTask.put("Order", pTask.getOrder());
		rTask.put("Level", pTask.getLevel());
		rTask.put("Name", pTask.getName());
		rTask.put("ParentID", pTask.getParentId());
		rTask.put("StartGap", pTask.getStartGap());
		rTask.put("Length", pTask.getLength());
		rPlan.addElement(rTask);
	}

	planStack = new Stack();
	planStack.push(rPlan);
	session.setAttribute("planStack", planStack);

// end of setting up plan stack

%>

<html>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">

<jsp:include page="../init.jsp" flush="true"/>

<script language="JavaScript">
<!--
function affirm()
{
	CreatePlan.Submit.disabled = true;
	CreatePlan.Prev.disabled = true;
	CreatePlan.submit();
}

//-->
</script>


<title>
	Create a New Project <%=label1%>
</title>

<style type="text/css">

</style>

</head>

<body text="#000000" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="100%" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<b class="head">

	&nbsp;&nbsp;Create a New Project <%=label1%>

	</b><br><br>
	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="..../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>


<!-- Content Table -->
 <table width="100%" border="0" cellspacing="0" cellpadding="0">
	<tr>
		<td width="15">&nbsp;</td>
		<td class="instruction_head">
			<br><b>Step 3 of 3: Review and Publish the Project <%=label1%></b><br><br></td>
	</tr>

	<tr>
		<td><img src="../i/spacer.gif" width="15" border="0"></td>
		<td>
			<table width="100%" border="0" cellspacing="0" cellpadding="0">
			<tr>
				<td>

<form method="post" name="CreatePlan" action="post_proj_new.jsp">
<input type="hidden" name="TownName" value="<%=townName%>" >
<input type="hidden" name="TownID" value="<%=townIdS%>" >
<input type="hidden" name="ProjName" value="<%=Util.stringToHTMLString(projName)%>" >
<input type="hidden" name="Department" value="<%=deptName%>" >
<input type="hidden" name="Description" value="<%=Util.stringToHTMLString(desc)%>" >
<input type="hidden" name="StartDate" value="<%=start%>" >
<input type="hidden" name="ExpireDate" value="<%=expire%>" >
<input type="hidden" name="ProjectOption" value="<%=option%>" >

<%

	out.print("<table width='100%' border='0' cellspacing='0' cellpadding='0' >");	// table 3
	out.print("<tr><td colspan='2'></td>");
	out.print("<td colspan='2'class='formtext_small'>(Enter header# that depends on this task, separated by comma)</td>");
	out.print("</tr>");

	out.print("<tr><td><img src='../i/spacer.gif' width='15' height='1'/></td>");
	out.print("<td class='plaintext_big' width='300'><b>Task Name</b></td>");
	out.print("<td class='plaintext_big' width='200' align='center'><b>Dependencies</b></td>");
	out.print("<td class='plaintext_big' width='200' align='center'><b>Phase/Subphase</b></td>");
	out.print("</tr>");
	out.print("<tr><td colspan='4'><img src='../i/spacer.gif' height='10' /></td></tr>");

	String [] colorStr = new String[1];
	String [] levelInfo = new String[10];
	String prelevelInfo = "";
	for(i = 0; i < rPlan.size(); i++)
	{
		Hashtable rTask = (Hashtable)rPlan.elementAt(i);
		String pName = (String)rTask.get("Name");
		Integer pLevel = (Integer)rTask.get("Level");
		Integer pOrder = (Integer)rTask.get("Order");
		Integer pPreOrder = (Integer)rTask.get("PreOrder");

		int level = pLevel.intValue();
		int order = pOrder.intValue();
		int width = 10 + 22 * level;
		order++;
		if (level == 0) {
			out.println("<tr><td colspan='4'><img src='../i/spacer.gif' height='15'/></td></tr>");
			levelInfo[level] = Integer.toString(order);
		}
		else {
			levelInfo[level] = levelInfo[level - 1] + "." + order;
		}
		
		out.print("<tr><td></td>");
		out.print("<td><table border='0' cellspacing='0' cellpadding='0' width='100%'><tr>");	// table A
		out.println("<td class='plaintext_big' valign='top' width='30'>" + levelInfo[level] + "&nbsp;&nbsp;</td>");

		out.print("<td><table border='0' width='100%' cellspacing='0' cellpadding='0'><tr>");	// table B
		out.println("<td class='plaintext_big' valign='top' style='max-width:600px;'>" + pName + "</td>");
		out.print("<td width='10'><img src='../i/spacer.gif' width='10' height='1'/></td>");
		out.print("<td style='border-bottom:#777777 dotted 1px; min-width:200px;'><img src='../i/spacer.gif' width='100%' height='1'/></td>");
		out.print("</tr></table></td>");			// END table B
		
		out.print("</tr></table></td>");		// END table A

		// get the dependency values from template if any
		String depStr = project.lookUpDependency(planString, levelInfo[level]);
		out.print("<td><img src='../i/spacer.gif' width='10' height='1'/><input type='text' name='Depend_"
				+ levelInfo[level] + "' class='plaintext' size='25' value='" + depStr + "'></td>");
		
		// get the phase subphase values from template if any
		depStr = project.lookUpPhase(planString, levelInfo[level], colorStr);
		out.print("<td valign='top'><input type='text' name='Phase_"
				+ levelInfo[level] + "' class='plaintext' size='25' value='" + depStr + "'></td>");
//System.out.println("color=" + colorStr[0]);

		if (colorStr[0] != null) {
//System.out.println(depStr + " found color [" + colorStr[0] + "] for header " + levelInfo[level]);			
System.out.println(depStr + " found color :" + colorStr[0]);			
			out.print("<input type='hidden' name='PhColor_" + levelInfo[level] + "' value='" + colorStr[0] + "'>");
		}

		out.print("</tr>");
	}
	
	out.print("</ul></td></tr>");
	out.println("</table>");	// table 3

%>

							</td>
						</tr>
				</table>
				</td>
			</tr>

		</table>

<table width="715" border="0" cellspacing="0" cellpadding="2">
  <tr>
    <td width="15" align="right"><img src="../i/spacer.gif" border="0" width="15" height="1"></td>
    <td width="700">&nbsp;</td>
  </tr>
  <tr>
  	<td>&nbsp;</td>
    <td class="plaintext_big">
		Click the <b>Publish Button</b> to publish the new project.
		To make any changes, click "<< Prev" to go back to the previous page.
	</td>
  </tr>
  <tr>
    <td>&nbsp;</td>
    <td width="100%" valign="top">
		<table width="715" border="0" cellspacing="0" cellpadding="2">
		  <tr>
		    <td colspan="2">&nbsp;</td>
		  </tr>
		  <tr>
		    <td colspan="2" align="center">
				<input type="Button" name='Prev' value="  << Prev  " onclick="history.back(-1)">&nbsp;
				<input type="Button" name="Submit" value=" Publish " onClick="return affirm()";>

		    </td>
		  </tr>
		</table>
	</td>
  </tr>
</table>

 </form>
  <!-- End of Content Table -->
		<!-- End of Main Tables -->
	</td>
</tr>

<!-- Footer -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- End of Footer -->

</table>
</body>
</html>
