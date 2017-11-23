<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>

<%
////////////////////////////////////////////////////
//	Copyright (c) 2017, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	botsAnalysis.jsp
//	Author:	ECC
//	Date:	04/25/17
//	Description:
//		Omm Robot page for putting all charts together for easy eyeball analysis.
//		We can evenually put something in here to compare and analyze the data also.
//
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

<%@ page import = "javax.xml.parsers.*" %>
<%@ page import = "org.w3c.dom.*" %>
<%@ page import = "org.xml.sax.SAXException" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />


<%


	// require login
	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	String s;

	String botName = request.getParameter("BotName");
	String hist = request.getParameter("Histogram");
	String scat = request.getParameter("Scattergram");
	
	String [] chartArr = {hist, scat};

%>



<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<script language="JavaScript" src="../meeting/ajax_utils.js"></script>
<script language="JavaScript" src="bots.js"></script>

<script language="JavaScript">
<!--

var histChart = '<%=hist%>'.split(",");
var scatChart = '<%=scat%>'.split(",");


//-->
</script>

<style type="text/css">
.inst1 { font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 12px; color: #333333; line-height: 16px; vertical-align:top;} 
</style>

<title>
	Omm Big Data Analytics
</title>

</head>


<body bgcolor="#FFFFFF" >

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="100%" border="0" cellspacing="0" cellpadding="0" align="left">

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
		Big Data Analytics
	</td></tr>

	</table>

	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- CONTENT -->

<table border='0' cellspacing='0' cellpadding='0' width='100%'>

	<tr>
		<td width='30'>&nbsp;</td>
		<td colspan='2' class='instruction_head'><br/>OMM Robot: <font color='#336699'><%=botName%></font></td>
	</tr>


	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='30'/></td></tr>

<!-- showing Histograms horizontally -->
	<tr><td></td>
	<td colspan='2'>
	<table>
<%
	String [] sa;

	// histogram, scattergram
	
	for (int i=0; i<chartArr.length; i++) {
		out.print("<tr><td>");
		sa = chartArr[i].split(",");
		for (int j=0; j<sa.length; j++) {
			out.print("<img src='" + sa[j] + "' width='380' />");
			if (j<sa.length-1)
				out.print("<img src='../i/spacer.gif' width='10'/>");
		}
		out.print("</td></tr>");
		out.print("<tr><td><img src='../i/spacer.gif' height='30' /></td></tr>");
	}
%>
	</table>
	</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='20'/></td></tr>


<!-- Submit Button -->
	<tr>
		<td width="15"></td>
		<td colspan='2' class="10ptype" align="right"><br/>
		<table border='0'><tr>
			<td><input type="button" value="Back" onclick="history.back();" class='button_medium'/>&nbsp;&nbsp;&nbsp;</td>
		</tr></table>
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

</body>
</html>

