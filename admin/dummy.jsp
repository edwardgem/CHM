<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>

<%
////////////////////////////////////////////////////
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	dummy.jsp
//	Author:	ECC
//	Date:	04/11/05
//	Description:
//		Dummy file.
//	Modification:
//
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "util.*" %>
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

%>



<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>

<script language="JavaScript">
<!--
function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

function validation()
{
	if (document.NewForm.ProjName.value =='')
	{
		fixElement(document.NewForm.ProjName,
			"Please make sure that the PROJECT NAME field is properly completed.");
		return false;
	}
	return;
}

//-->
</script>

<title>
	PRM
</title>

</head>


<body bgcolor="#FFFFFF" >

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
	<td class="head">
		Dummy
	</td></tr>

	</table>

	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- CONTENT -->
<form method="post" name="NewForm" action="proj_new2.jsp">
<table>

	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="instruction_head"><br><b>Instruction Header</b></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="instruction">
		<br>
		Detailed instruction.
		<p>2nd line instruction.<br><br></td>
	</tr>

<!-- town name -->
<input type="hidden" name="TownName" value="">

<!-- Project Name -->
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_blue"><font color="#000000">*</font> Project Name:</td>
		<td>
			<input type="text" name="ProjName" size="50">
		</td>
	</tr>

<%
	out.print("<tr><td></td><td colspan'2'><table>");
	PrmColor color = new PrmColor();
	int max = color.getMax();
	String colStr;
	for (int i=0; i<max; i++)
	{
		colStr = color.getColor();
		out.print("<tr><td class='plaintext'>" + i + ".&nbsp;<font color='" + colStr
					+ "'><b>Edward C.</b>&nbsp;&nbsp;" + colStr + "</font></td></tr>");
	}
	out.print("</table></td></tr>");
%>

<!-- Submit Button -->
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="10ptype" align="center"><br>
			<input type="reset" value="   Reset   "/>&nbsp;
			<input type="submit" name="Submit" value="  Next >>  " onclick="return validation();"/>
		</td>
	</tr>

	
</table>

</form>



<!-- BEGIN FOOTER TABLE -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</td></tr>
</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

