<%
////////////////////////////////////////////////////
//	Copyright (c) 2004-2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	deluser.jsp
//	Author:	ECC
//	Date:	04/22/05
//	Description:
//		Allow admin to delete a user.
//	Modification:
//
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>
<%@ page import = "util.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ((pstuser instanceof PstGuest) || ((iRole & user.iROLE_ADMIN) == 0) )
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}

	String msg = request.getParameter("msg");
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="../init.jsp" flush="true" />

<script language="JavaScript">
<!--
function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

function validation()
{
	if (document.DelUser.UserName.value =='')
	{
		fixElement(document.DelUser.UserName,
			"Please make sure that the USERNAME field was properly completed.");
		return false;
	}

	return;
}

//-->
</script>

<title>
	<%=Prm.getAppTitle()%> Administration
</title>

</head>

<body text="#000000" leftmargin="10" topmargin="10" marginwidth="0" marginheight="0">

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="715" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td width="20"><img src='../i/spacer.gif' width='20'/></td>
	<td valign="top">
	<b class="head">
	Delete a User
	</b><br><br>
	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="/i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- CONTENT -->
<table>
<form name='DelUser' method="post" action="post_deluser.jsp">

	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="instruction">
<%	if (msg != null)
	{%>
		<br><font color="#aa0000"><%=msg%></font><br><br>
<%	}%>
		<br>
		Please enter the name of the user to be deleted.
		<br><br></td>
	</tr>

<!-- email / username -->
	<tr>
		<td width="15">&nbsp;</td>
		<td class="formtext_blue"><font color="#000000">*</font> Username: </td>
		<td>
			<input type="text" name="UserName" size="35">
		</td>
	</tr>


<!-- Submit Button -->
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="10ptype" align="center"><br>
			<input type="Submit" class='button_medium' name="Submit" value="  Submit  " onclick="return validation();">
			<input type="Button" class='button_medium' value="   Cancel   " onClick="location='admin.jsp';">&nbsp;
		</td>
	</tr>

</form>
</table>


<tr><td>&nbsp;</td><tr>


<!-- BEGIN FOOTER TABLE -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

