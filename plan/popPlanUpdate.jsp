<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<%
//
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: popPlanUpdate.jsp
//	Author: ECC
//	Date: 04/09/04
//	Description: Update a task item of a plan.
//
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
// popPlanUpdate.jsp :
//
%>

<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	String backPage = request.getParameter("backPage");

	String levelInfo = request.getParameter("levelInfo");
	String realorder = request.getParameter("realorder");

	// Get plan task
	Stack planStack = (Stack)session.getAttribute("planStack");
	if((planStack == null) || planStack.empty())
	{
		response.sendRedirect("/out.jsp?e=Access declined");
		return;
	}
	Vector rPlan = (Vector)planStack.peek();
	Hashtable rTask = (Hashtable)rPlan.elementAt(Integer.parseInt(realorder));
	String name = (String)rTask.get("Name");

%>

<html>
<head>
<title>PRM Update Project Plan</title>

<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<jsp:include page="../init.jsp" flush="true"/>

<script Language="JavaScript">
<!--

function checkEmpty()
{
	path = document.updatePlan;

	if (path.Name.value == "")
	{
		alert("The Task cannot be empty.");
		path.Name.value = "<%=name%>";
		path.Name.onFocus;
		return false;
	}

	path.submit();
	return true;
}

function reset()
{
	document.updatePlan.Name.value="<%=name%>";
}

//-->

</SCRIPT>

</head>

<body text="#000000" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">

<table width="715" border="0" cellspacing="0" cellpadding="0">


<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<table>
	<tr>
	<td width="450">

	<table>
	<tr><td width="10">&nbsp;</td>
	<td>
	<b class="head">
	Change Project Task
	</b>
	</td></tr>
	</table>

	</td>
	</tr>

	<tr><td height="3"><img src="../i/spacer.gif" width="1" height="3" border="0"></td></tr>
	</table>

	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>
	</td>
</tr>

<tr>
<td>
<!-- Content Table -->
<form method="post" name="updatePlan" action="postplanUpdate.jsp">
<input type="hidden" name="realorder" value='<%=realorder%>'>
<input type="hidden" name="backPage" value="<%=backPage%>">
	<table width="100%" border="0" cellspacing="0" cellpadding="0">
	<tr><td colspan="5">&nbsp;</td></tr>
	<tr><td colspan="5">&nbsp;</td></tr>
	<tr>
		<td width="20"><img src="../i/spacer.gif" width="20" height="2" border="0"></td>
		<td colspan="3" width='600' class="instruction">* Please type in the change of task <%=levelInfo%> and click save.
			To move this task and its subtasks, simply type the new header numeric (e.g. 2.1.3) and click save.</td>
		<td width="20"><img src="../i/spacer.gif" width="20" border="0"></td>
	</tr>
	<tr><td colspan='5'><img src="../i/spacer.gif" height="10" border="0"></td></tr>
	<tr>
		<td>&nbsp;</td>
		<td width="50" class="plaintext"><%=levelInfo%></td>
		<td width="6">&nbsp;</td>
		<td width="350" class="plaintext"><%=name%></td>
		<td width="20"><img src="../i/spacer.gif" width="20" height="10" border="0"></td>
	</tr>
	<tr>
		<td>&nbsp;</td>
		<td width="50" class="plaintext"><%=levelInfo%></td>
		<td width="6">&nbsp;</td>
		<td width="350"><input class="plaintext" type="text" name="Name" value="<%=name%>" size="80"></td>
		<td>&nbsp;</td>
	</tr>
	<tr><td colspan="5">&nbsp;</td></tr>
	<tr><td colspan="5">&nbsp;</td></tr>
	 <tr>
		<td colspan="4" align="center">
		  <table border="0" cellspacing="1" cellpadding="0">
			<tr>
				<td>
				<input type='button' class='button_medium' value='Save' style='width:100px'; onclick="return checkEmpty();" />&nbsp;
				<input type='button' class='button_medium' value='Reset' style='width:100px'; onclick="reset();" />&nbsp;
				<input type='button' class='button_medium' value='Cancel' style='width:100px'; onclick="history.back(-1);" />&nbsp;
				</td>
			</tr>
		  </table>
		</td>
		<td>&nbsp;</td>
	</tr>
  </table>
  </form>
<!-- End of Content Table -->
</td>
</tr>


</table>

	</td>
</tr>

<tr><td>&nbsp;</td><tr>


<!-- BEGIN FOOTER TABLE -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->

</table>
</body>
</html>
