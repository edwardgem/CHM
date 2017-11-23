<%
////////////////////////////////////////////////////
//	Copyright (c) 2010, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	circle_visitor.jsp
//	Author:	ECC
//	Date:	10/11/10
//	Description:
//		Allow a circle visitor to enter circle password to visit the forum page.
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>

<%
	final String HOST = Util.getPropKey("pst", "PRM_HOST");
	String circleName = request.getParameter("cir");

	// try to login with default (no) password, if failed, then ask for passwd
	boolean bNeedPasswd = false;
	String defPasswd = circleName;
	try {
		Util.login(session, circleName, defPasswd);
	}
	catch (PmpException e) {
		bNeedPasswd = true;
	}
	if (!bNeedPasswd) {
		// go ahead and show the circle page
		response.sendRedirect("../ep/my_page.jsp");
		return;
	}
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html lang="en">


<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<link href="../menu.css" rel="stylesheet" type="text/css" media="screen">
<jsp:include page="../init.jsp" flush="true"/>

<script language="JavaScript">
<!--


function entSub(event)
{
  if (window.event &&
  	(window.event.keyCode==13 || event.which==13) )
  {
	checkempty();
	return false;
  }
  return true;
}


function checkempty()
{
	// user login
	if (LoginForm.Password.value == "")
	{
		fixElement(LoginForm.Password,"Please enter circle guest Password.");
		return false;
	}

	LoginForm.submit();
}

//-->
</script>

<title>
	<%=Prm.getAppTitle()%>
</title>

</head>


<body bgcolor="#FFFFFF" onLoad="fo(document.LoginForm);" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">

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
	<%=circleName%><br><br>
	</b>
	</td></tr>

	</table>

	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- CONTENT -->
<table border='0'>
<form method="post" name="LoginForm" action="../checklogin.jsp">
<input type="hidden" name="Uid" value="<%=circleName%>">
<input type="hidden" name="Go" value="<%=HOST%>/ep/my_page.jsp">

	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="instruction_head"><br><b>Welcome to
			<span class='head'><%=circleName%></span>Circle Forum</b></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="instruction">
		<br>
		Please enter circle guest password
		</td>
	</tr>

<!-- enter circle guest passwd -->
	<tr>
		<td width="15">&nbsp;</td>
		<td class='plaintext_bold' width='100' align='right'>Password:</td>
		<td class="plaintext" align='center' width='200'>
			<input type="password" name="Password" size='25' onKeyDown="return entSub(event);">
		</td>
	</tr>



<!-- Submit Button -->
	<tr>
		<td width="15">&nbsp;</td>
		<td></td>
		<td align="center"><br>
			<input type="Button" name="Submit" class='button_medium' value="Continue" onclick="return checkempty();">
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

