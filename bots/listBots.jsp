<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>

<%
////////////////////////////////////////////////////
//	Copyright (c) 2017, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	listBots.jsp
//	Author:	ECC
//	Date:	07/11/17
//	Description:
//		List Omm Robots page.
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
		OMM Robots for Machine Learning
	</td>
	<td align='right'>
		<img src='../i/bullet_tri.gif' width='20' height='10'/>
		<a class='listlinkbold' href='ommBots.jsp?cr=1'>Create New Model</a>
	</td>
	
	</tr>

	</table>

	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- CONTENT -->
<form method="post" name="goRobotForm" action="post_ommBots.jsp">
<input type='hidden' name='SaveOnly' value='' />
<input type='hidden' name='TotalXmlNodes' value='' />
<input type='hidden' name='XmlNodesOnPage' value='' />

<table border='0' cellspacing='0' cellpadding='0'>

	<tr>
		<td><img src='../i/spacer.gif' width='25' height='1'/></td>
		<td colspan='2' class='instruction_head'><br/><b>Healthcare Robot Models</b></td>
	</tr>

	<tr>
		<td></td>
		<td colspan='2' class="instruction">
		<br/>
		</td>
	</tr>
	
	<!-- set display format -->
	<tr>
		<td></td>
		<td colspan='2' width='100%'>
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

	
<!-- List all robots -->
<%
	robot rbObj;
	String botName, desc, picFile, linkS, priceS;
	double f;
				
	for (int i=0; i<rbArr.length; i++) {
		rbObj = (robot) rbArr[i];
		out.print("<tr><td valign='top'><table border='0'>");
		
		// display names
		linkS = "ommBots.jsp?id=" + rbObj.getObjectId();
		botName = rbObj.getObjectName();
		//out.print("<tr><td><img src='../i/spacer.gif' height='5' /></td></tr>");	// gap
		out.print("<tr><td><img src='../i/spacer.gif' width='3' /></td>");
		out.print("<td class='plaintext_big2' width='100'>");
		out.print("<a href='" + linkS + "'>");
		out.print(botName);
		out.print("</a></td>");
		out.print("<td class='plaintext_big2' width='600'>");
		out.print(rbObj.getStringAttribute("DisplayName"));
		out.print("</td></tr>");
		
		// company and description
		out.print("<tr><td colspan='3'>");
		out.print("<table>");
		
		// format
		out.print("<tr><td><img src='../i/spacer.gif' width='50' height='10' /></td>");
		out.print("<td><img src='../i/spacer.gif' width='100' height='1' /></td>");	// label
		out.print("<td><img src='../i/spacer.gif' width='600' height='1' /></td>");														// content
		out.print("</tr>");
		
		// company
		out.print("<tr><td></td>");
		out.print("<td class='plaintext_blue' valign='top'>Organization</td>");
		out.print("<td class='plaintext_big'>" + rbObj.getStringAttribute("Company") + "</td>");
		out.print("</tr>");
		
		out.print("<tr><td colspan='2'><img src='../i/spacer.gif' height='5' /></td></tr>");
		
		// description
		desc = rbObj.getRawAttributeAsUtf8("Description");
		if (desc == null) desc = "";
		out.print("<tr><td></td>");
		out.print("<td class='plaintext_blue' valign='top'>Description</td>");
		out.print("<td class='plaintext_big'>" + desc + "</td>");
		out.print("</tr>");
		
		out.print("<tr><td colspan='2'><img src='../i/spacer.gif' height='5' /></td></tr>");
		
		out.print("</table></td></tr>");
		
		// pricing
		f = (Double)rbObj.getAttribute("Price")[0];
		if (f <= 0)
			priceS = "Free";
		else
			priceS = new DecimalFormat("US$ #.## / year").format(f);
		out.print("<tr><td></td>");
		out.print("<td class='plaintext_blue' valign='top'>Price</td>");
		out.print("<td class='plaintext_big'>" + priceS + "</td>");
		out.print("</tr>");
		
		out.print("</table></td>");
		
		out.print("<td></td>");
		
		// robot image
		picFile = rbObj.getStringAttribute("PictureFile");
		if (picFile == null) picFile = DEF_ROBOT_FILE;				// default
		out.print("<td><a href='" + linkS + "'>");
		out.print("<img src='../i/" + picFile + "' height='160' title='" + botName + "'/></a>");
		out.print("</td></tr>");
		
		out.print("<tr><td><img src='../i/spacer.gif' height='30' /></td></tr>");	// gap
		out.print("<tr><td colspan='3'><hr class='style2'></hr></td></tr>");
		out.print("<tr><td><img src='../i/spacer.gif' height='20' /></td></tr>");	// gap
	}
%>

	</table>
	</td>
	</tr>

	
	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='20'/></td></tr>


<!-- Submit Button -->
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="10ptype" align="right"><br/>
			<input type="button" value="Close" onclick="window.close();" class='button_medium'/>
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

