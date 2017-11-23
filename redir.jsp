<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//  Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   redirect index.jsp
//  Author: ECC
//  Date:   07/02/2005
//  Description:
//
//  Modification:
//
/////////////////////////////////////////////////////////////////////
//
%>


<%@ taglib uri="/pmp-taglib" prefix="pmp" %>


<head>
<title>CHM</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />



<link href="oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<jsp:include page="init.jsp" flush="true"/>
<script language="JavaScript" src="login_cookie.js"></script>
<script language="JavaScript">


//-->
</script>

</head>

<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" height="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">
<table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr align="left" valign="top">
    <td><jsp:include page="loginhead.jsp" flush="true"/></td>
  </tr>
  <tr align="left" valign="top">
    <td>
      <table width="90%" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td width="200">&nbsp;</td>
          <td>&nbsp;</td>
          <td width="200">&nbsp;</td>
        </tr>
		 <tr>
          <td colspan="3">&nbsp;</td>
        </tr>
		<tr>
          <td colspan="3">&nbsp;</td>
        </tr>
        <tr>
          <td width="200">&nbsp;</td>
          <td>
            <table width="100%" border="0" cellspacing="0" cellpadding="0">
			<tr valign="middle" align="center">
				<td class="ptextS2">
					<font color ="#ee3333">CHM has been moved. Please click the below link to go to the new service.<br/>
					CHM 已迁移到云端服务器，请点击下面的链接访问</font>
				</td>
			</tr>
			<tr><td><img src="i/spacer.gif" width="2" height="40"/></td></tr>
			<tr>
          		<td align="center">
          			<a href='http:://collabris.cn'>http://collabris.cn</a>
				</td>
       		</tr>

      </table>
    </td>
  </tr>
  </table>

	  <table height="220">
	  	<tr>
			<td>&nbsp;</td>
		</tr>
	  </table>
  </td>
  </tr>

  <tr>
  	<td valign='bottom'>
		<table width="100%" border="0" cellspacing="0" cellpadding="0">
	<tr>
		<td height="2" width="100%" bgcolor="336699"><img src="ep/images/mid/336699-2by2-holder.gif" width="2" height="2"/></td>
	</tr>

	<tr>
		<td height='30' width="770" valign='top' align="center">
			<a href="index.jsp" class="listlink">CHM Home</a>
			&nbsp;|&nbsp;
			<a href="info/faq.jsp?home=index.jsp" class="listlink">FAQ</a>
			&nbsp;|&nbsp;
			<a href="info/help.jsp" class="listlink">Help forum</a>
		</td>
	</tr>
	<tr valign="top">
		<td width="770" class="8ptype" align="center"><font color="#999999">Copyright © 2010-2017, EGI Technologies, Inc.</font></td>
	</tr>

		</table>
	</td>
  </tr>

</table>
</body>
</html>
