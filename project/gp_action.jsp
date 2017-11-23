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
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "util.PageViewCountData" %>

<%@taglib uri='/WEB-INF/cewolf.tld' prefix='cewolf' %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}

%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">


<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">

<script language="JavaScript">
<!--

//-->
</script>

<title>
	PRM Graphs
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
	Action Item Analysis<br><br>
	</b>
	</td></tr>

	</table>

	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- CONTENT -->
<table>
<tr>
<td>

<jsp:useBean id="pageViews" class="util.PageViewCountData"/>
<cewolf:chart
	showlegend="true"
	id="pieChart"
	title="Page View Statistics"
	yaxislabel="View Frequency"
	xaxislabel="Day of Week"
	type="pie">
    <cewolf:gradientpaint>
        <cewolf:point x="0" y="0" color="#FFFFFF" />
        <cewolf:point x="300" y="0" color="#DDDDFF" />
    </cewolf:gradientpaint>
	<cewolf:data>
	<cewolf:producer id="pageViews"/>
	</cewolf:data>
</cewolf:chart>

<p>

<cewolf:img chartid="pieChart" renderer="/cewolf" width="400" height="300">
	<cewolf:map useJFreeChartTooltipGenerator="pageViews" />
</cewolf:img>
<p>
</td></tr>
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
