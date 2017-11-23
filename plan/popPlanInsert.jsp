<%
//
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: popPlanUpdate.jsp
//	Author: ECC
//	Date: 04/10/04
//	Description: Update plan.
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
<%@ page import = "util.Prm" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />
<%
	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	String backPage = request.getParameter("backPage");

	String levelInfo = request.getParameter("levelInfo");
	String realorder = request.getParameter("realorder");
	String lastlevelInfo = request.getParameter("lastlevelInfo");

	// Get plan task
	Stack planStack = (Stack)session.getAttribute("planStack");
	if((planStack == null) || planStack.empty())
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}

	int beginLevel = 0;
	int endLevel = 0;
	for(int i=0; i < levelInfo.length(); i++)
	{
		if (levelInfo.charAt(i) == '.')
			endLevel++;
	}
	for(int i=0; i < lastlevelInfo.length(); i++)
	{
		if (lastlevelInfo.charAt(i) == '.')
			beginLevel++;
	}

	String levelInfo1 = "";

%>

<html>
<head>
<title><%=Prm.getAppTitle()%> Insert Project Task</title>

<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<jsp:include page="../init.jsp" flush="true"/>

<script Language="JavaScript">
<!--
window.onload = function () {
	insertPlanForm.Name.focus();
}
function checkEmpty()
{
	path = document.insertPlanForm;
	var beginLevel = <%=beginLevel%>;
	var endLevel = <%=endLevel%>;

	if (path.Name.value == "")
	{
		alert("The Task cannot be empty.");
		path.Name.onFocus;
		return false;
	}
	var myToken = path.Name.value.split("\n");
	var regexp = /[A-Za-z0-9]/;
	//alert("level = " + beginLevel);
	var lastLevel = beginLevel;
	for (i=0; i < myToken.length; i++)
	{
		var counttab= 0;
		var countstar= 0;
		var name = myToken[i];
		var found = name.search(regexp);
		if (found == -1)
		{
			var k = i + 1;
			alert("Please remove line " + k + " because it is an empty line!");
			return false;
		}
		for (j=0; j < name.length; j++)
		{
			if (name.charAt(j) == '\t')
			{
				counttab++;
			}
			else if (name.charAt(j) == '*')
			{
				countstar++;
			}
			else
			{
				break;
			}
		}
		if (countstar > counttab) counttab = countstar;
		if (counttab - lastLevel > 1)
		{
			alert("Sytax Error after line " + i + "! Make sure that the sub-level is indented correctly!");
			return false;
		}
		lastLevel = counttab;
	}
	if (endLevel - lastLevel > 1)
	{
		alert("Sytax Error in line " + myToken.length + " (The last line)! Make sure that the sub-level is indented correctly!");
		return false;
	}
	return true;
}

function reset()
{
	document.insertPlanForm.Name.value="";
}


//-->

</SCRIPT>

</head>

<body text="#000000" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">

<table width="100%" border="0" cellspacing="0" cellpadding="0">


<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<table>
	<tr>
	<td>

	<table>
	<tr><td width="10">&nbsp;</td>
	<td>
	<b class="head">
	Insert a Project Task
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
<form method="post" name="insertPlanForm" action="postplanInsert.jsp">
<input type="hidden" name="realorder" value='<%=realorder%>'>
<input type="hidden" name="backPage" value="<%=backPage%>">
	<table border='0' cellspacing="0" cellpadding="0">
	<tr><td colspan="5">&nbsp;</td></tr>
	<tr><td colspan="5">&nbsp;</td></tr>
	<tr>
		<td width="20"><img src="../i/spacer.gif" width="20" height="2" border="0"></td>
		<td colspan="3" class="instruction">Please enter new tasks below. Each line is a new task. Use * at the beginning of each line to indicate sub-levels.</td>
		<td>&nbsp;</td>
	</tr>
	<tr>
		<td width="20"><img src="../i/spacer.gif" width="20" height="2" border="0"></td>
		<td colspan="3" class="instruction"><br>(e.g. ** Two stars represent a level 3 heading like 1.1.1 or 3.2.2)</td>
		<td>&nbsp;</td>
	</tr>
	<tr><td colspan="5">&nbsp;</td></tr>

<%	if (!lastlevelInfo.equals("")) {%>
	<tr>
		<td>&nbsp;</td>
		<td width="120" class="ptextS2">Insert After: &nbsp;</td>
		<td width="6">&nbsp;</td>
		<td class="plaintext"><%=lastlevelInfo%>
		<td>&nbsp;</td>
	</tr>
<%	} %>

	<tr>
		<td>&nbsp;</td>
			<td class="ptextS2">Task Name: &nbsp;</td>
		<td width="6">&nbsp;</td>
		<td class="plaintext"><textarea name="Name" rows="4" cols="60"></textarea></td>
			<td>&nbsp;</td>
	</tr>
	
<%	if (!levelInfo.equals("")) {%>
	<tr>
		<td>&nbsp;</td>
		<td width="120" class="ptextS2">Insert Before: &nbsp;</td>
		<td width="6">&nbsp;</td>
		<td class="plaintext"><%=levelInfo%>
			<!--select name="insetUnder">
				<option> <%=levelInfo1%>
				<option> <%=levelInfo%>
			</select-->
		<td>&nbsp;</td>
	</tr>
<%	}%>

	<tr><td colspan="5">&nbsp;</td></tr>
	<tr><td colspan="5">&nbsp;</td></tr>
	 <tr>
		<td>&nbsp;</td>
		<td>&nbsp;</td>
		<td colspan="2">
		  <table border="0" cellspacing="1" cellpadding="0">
			<tr>
			  <td><img src='../i/spacer.gif' width='150' height='1'/></td>
			  <td>
				<input type='button' class='button_medium' value='Save' style='width:100px';' onclick='insertPlanForm.submit();'>&nbsp;
			  </td>
			  <td width="10"><img src="../i/spacer.gif" width="10" height="2" border="0"></td>
			  <td>
				<input type='button' class='button_medium' value='Cancel' style='width:100px';' onclick='history.back(-1);'>&nbsp;
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
