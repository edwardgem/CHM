<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>

<%
////////////////////////////////////////////////////
//	Copyright (c) 2017, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	openAI.jsp
//	Author:	ECC
//	Date:	07/11/17
//	Description:
//		Start page for openAI.
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
<%@ page import = "java.net.URL" %>
<%@ page import = "java.net.URLConnection" %>

<%@ page import = "java.text.DecimalFormat" %>

<%
	final String HOST = Util.getPropKey("pst", "PRM_HOST");
%>
<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="http://lofty/out.jsp?go=bots/listBots.jsp" />

<%
	final String DEF_ROBOT_FILE			= "robot1.jpg";

	// require login
	if (pstuser instanceof PstGuest) {
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	String s;

	// get the list of robots
	robotManager rbMgr = robotManager.getInstance();
	
	int [] ids = rbMgr.findId(pstuser, "ParentID=null");
	PstAbstractObject [] rbArr = rbMgr.get(pstuser, ids);
	
	Util.sortName(rbArr);
	
%>


<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>

<script language="JavaScript">
<!--


//-->
</script>

<title>
	Omm Robots
</title>

<style type="text/css">
.aa:link {color:#ffffff; text-decoration: none;}
.aa:visited {color:#ffffff; text-decoration: none;}
.aa:active {color:#225588; text-decoration: underline;}
.aa:hover {color: #ee8800; text-decoration: none;}
</style>


</head>


<body bgcolor="#FFFFFF" >

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="100%" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<table width='83%'>

	<tr><td colspan="2">&nbsp;</td></tr>
	<tr>
	<td></td>
	<td class="head">
		Open AI Platform
	</td>
	<td align='right'>
		<img src='../i/bullet_tri.gif' width='20' height='10'/>
		<a class='listlinkbold' href='javascript:window.close();'>Close</a>
	</td>
	
	</tr>

	</table>

	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- CONTENT -->

<table border='0' cellspacing='0' cellpadding='0'>

	<tr>
		<td><img src='../i/spacer.gif' width='10' height='1'/></td>
		<td colspan='2' class='instruction_head'><br/><b></b></td>
	</tr>
	
	<!-- set display format -->
	<tr>
		<td></td>
		<td colspan='2' width='100%'>

<!-- Display the banner image -->
		<table border='0' cellspacing='0' cellpadding='0' width='100%'>
		<tr>
			<td style='background-image:url(../i/openAI.jpg);
				background-repeat:no-repeat;background-size:100% 100%;
				width:100%; height:280px; vertical-align:top;
				padding:60px 60px;
				font-size:60px; color:white'
			>
			Collabris
			<span style='font-size:30px;'>Open AI Platform</span>
			<span style='font-size:40px;'><br/><br/></span>
			<span style='font-size:35px; padding-left:600px; line-height:45px'>
				<a class='aa' href='challenge.jsp'>Challenge</a></span><br/>
			<span style='font-size:35px; padding-left:600px; line-height:45px'>
				<a class='aa' href='dataMart.jsp'>Data</a></span><br/>
			<span style='font-size:35px; padding-left:600px; line-height:45px'>
				<a class='aa' href='listBots.jsp'>Solution</a></span><br/>
			</td>
		</tr>
		</table>
		
		
<!-- List the three components in Open AI Platform -->
		<table border='0'>
		
		<tr>
			<td width='600'>
				<table>
				<tr>
				<td><img src='../i/spacer.gif' width='20'  height='1' /></td>
				<td><img src='../i/spacer.gif' width='60' height='1' /></td>
				<td><img src='../i/spacer.gif' width='500' height='1' /></td>
				</tr>
				</table>
			</td>
			
			<td><img src='../i/spacer.gif' width='50'  height='1' /></td>
			
			<td>
				<img src='../i/spacer.gif' width='200' height='1' />
			</td>
		</tr>	
		</table>




<!-- BEGIN FOOTER TABLE -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</td></tr>
</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</td>
</tr>
</table>

</body>
</html>

