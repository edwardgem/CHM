<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html>
<%
//
//  Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   msg.jsp
//  Author: ECC
//  Date:   07/02/2005
//  Description:
//    Display a message.
//
//  Modification:
//
/////////////////////////////////////////////////////////////////////
//
//
//

%>

<%@ page import = "oct.omm.common.*" %>
<%@ page import = "oct.omm.client.*" %>
<%@ page import = "oct.omm.db.*" %>
<%@ page import = "oct.pep.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.Prm"%>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>

<%
	String msg = request.getParameter("msg");
	String go = request.getParameter("go");
	if (go != null)
	{
		go = go.replaceAll(":", "&");
	}
	
	String app = Prm.getAppTitle();

%>

<head>
<title><%=app%></title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<link href="oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<jsp:include page="init.jsp" flush="true"/>

</head>

<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" height="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">

<table width="100%" border="0" cellspacing="0" cellpadding="0">
	<tr align="left" valign="top">
	<td><jsp:include page="loginhead.jsp" flush="true"/></td>
	</tr>

	<tr><td>&nbsp;</td></tr>
	<tr><td>&nbsp;</td></tr>
	<tr><td>&nbsp;</td></tr>

	<tr valign="top">
	<td>
		<table width="600" border="0" cellspacing="0" cellpadding="0">
			<tr align="center">
				<td width="30">&nbsp;</td>
				<td class="verdana_11px_bold">
					<font color ="#333399"><strong><%=msg%></strong></font>
				</td>
			</tr>
			<tr><td colspan='2'><img src="i/spacer.gif" width="2" height="40"></td></tr>
			<tr>
				<td width="30">&nbsp;</td>
				<td align="center">
					<input type='button' class='button_medium' value='Continue' style='width:100px'; onclick="location='<%=go%>';">&nbsp;
				</td>
			</tr>
      	</table>
      </td>
      </tr>

	<tr>
	  <td>&nbsp;</td>
	</tr>
</td></tr>
</table>

<tr>
	<td valign="bottom">
		<table width="100%" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td>&nbsp;</td>
        </tr>
        <tr>
          <td height="2" width="100%" bgcolor="336699"><img src="ep/images/mid/336699-2by2-holder.gif" width="2" height="2"></td>
        </tr>
        <tr>
          <td height="32" width="780" align="center" valign="middle"><font size="1" face="Arial, Helvetica, sans-serif" color="#999999">Copyright
            &copy; 2008-2015, EGI Technologies</font></td>
        </tr>
      </table>
	</td>
</tr>

</table>
</body>
</html>
