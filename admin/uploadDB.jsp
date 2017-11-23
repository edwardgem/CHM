<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>

<%
////////////////////////////////////////////////////
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	uploadDB.jsp
//	Author:	ECC
//	Date:	04/11/05
//	Description:
//		Upload Excel files to OMM DB.
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
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

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
	Upload Database<br/><br/>
	</b>
	</td></tr>

	</table>

	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- CONTENT -->
<form method="post" name="UploadForm" action="post_uploadDB.jsp" enctype="multipart/form-data">
<table>

	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="instruction_head"><br><b>Upload database with Excel spreadsheet (.XLS)</b></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td colspan='2' class="instruction">
		<br/>
		Click the below button to specify a file that contains source data.
		</td>
	</tr>


<!-- Get organization name -->
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_blue">Organization name:&nbsp;&nbsp;</td>
		<td>
			<input type="text" name="orgName" size="40" value=''/>
		</td>
	</tr>

<!-- Get upload file -->
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_blue">Upload file:&nbsp;&nbsp;</td>
		<td>
			<input type="file" name="uploadFile" size="40"/>
		</td>
	</tr>


<!-- Submit Button -->
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="10ptype" align="center"><br/>
			<input type="submit" class='button_medium' name="Submit" value="  Submit  "/>&nbsp;
			<input type="reset" class='button_medium' value="   Reset   "/>
		</td>
	</tr>


</table>
</form>

</td>
</tr>

<tr><td>&nbsp;</td></tr>


<!-- BEGIN FOOTER TABLE -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

