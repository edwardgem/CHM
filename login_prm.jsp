
<%
//
//  Copyright (c) 2006, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   login.jsp
//  Author: ECC
//  Date:   06/12/2006
//  Description:
//    This is the login page for PRM and CR.
//
//  Modification:
//
/////////////////////////////////////////////////////////////////////
//
//

%>

<%@ page import = "oct.omm.common.*" %>
<%@ page import = "oct.omm.client.*" %>
<%@ page import = "oct.omm.db.*" %>
<%@ page import = "oct.pep.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "util.Util" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>


<%
	String error = request.getParameter("error");
	String HOST = Util.getPropKey("pst", "PRM_HOST");
	String crPage, cookiePrefix, companyName;
	boolean isCRAPP = util.Prm.isCR();
	boolean isMeetWE = util.Prm.isMeetWE();
	if (isCRAPP) {
		crPage = "ep_cr.jsp";
		cookiePrefix = "CR";
		companyName = "MeetWE, Inc.";
	}
	else if (isMeetWE) {
		crPage = "ep_omf.jsp";
		cookiePrefix = "OMF";
		companyName = "EGI Technologies, Inc.";
	}
	else {
		crPage = "ep_prm.jsp";
		cookiePrefix = "PRM";
		companyName = "EGI Technologies, Inc.";
	}

	// check to see if there is already a login session
	// if so, go to Home page directly
	PstUserAbstractObject u = null;
	if (session!=null && ((u = (PstUserAbstractObject)session.getAttribute("pstuser"))!=null)) {
		if (!(u instanceof PstGuest)) {
			// I am login already
			response.sendRedirect(HOST+ "/ep/" + crPage);
			return;
		}
	}

	String s;
	String secureHost;
	if ((s = Util.getPropKey("pst", "SECURE_HOST"))!=null && s.equalsIgnoreCase("true"))
		secureHost = HOST.replace("http", "https");
	else
		secureHost = HOST;

%>

<html>
<head>
<title>CPM 3.0</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<link href="oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="init.jsp" flush="true"/>

<script language="JavaScript" src="login_cookie.js"></script>

<%
	if (request.getParameter("logout")!=null || error!=null)
	{%>
<SCRIPT LANGUAGE="JavaScript">
<!--
	deleteCookie("<%=cookiePrefix%>username");
	deleteCookie("<%=cookiePrefix%>password");
//-->
</script>
<%	}
	else
	{
%>

<form name='LoginForm' method='post' action='<%=secureHost%>/checklogin.jsp'>
	<input type='hidden' name='Uid' value=''>
	<input type='hidden' name='Password' value=''>
</form>

<script language="JavaScript">
<!--
var username = getCookie("<%=cookiePrefix%>username");
if (username != null)
{
	var password = getCookie("<%=cookiePrefix%>password");
	LoginForm.Uid.value = username;
	LoginForm.Password.value = password;
	LoginForm.submit();
	//window.location = "checklogin.jsp?Uid=" + username + "&Password=" + password;
}
//-->
</script>
<%	}%>

<script language="JavaScript">
<!--

function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

function checkempty()
{
	if (Login.Uid.value == "")
	{
		fixElement(Login.Uid, "Please enter your Username.");
		return false;
	}

	if (Login.Password.value == "")
	{
		fixElement(Login.Password,"Please enter your Password.");
		return false;
	}

	// set cookie to remember username/passwd
	if (Login.Remember.checked)
	{
		var now = new Date();
		fixDate(now);
		now.setTime(now.getTime() + 7776000000); // 90 * 24 * 60 * 60 * 1000
		setCookie("<%=cookiePrefix%>username", Login.Uid.value, now);
		setCookie("<%=cookiePrefix%>password", Login.Password.value, now);
	}

	Login.action = "checklogin.jsp";
	//Login.submit();
}

function fo()
{
	Form = document.Login;
	for (i=0;i < Form.length;i++)
	{
		if (Form.elements[i].type != "hidden")
		{
			Form.elements[i].focus();
			break;
		}
	}
}

//-->
</script>


</head>

<body bgcolor="#FFFFFF" onLoad="fo();" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" height="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">
<table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr align="left" valign="top">
    <td><jsp:include page="loginhead.jsp" flush="true"/></td>
  </tr>
  <tr align="left" valign="top">
    <td>
      <table width="780" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td width="200">&nbsp;</td>
          <td width="380">&nbsp;</td>
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
          <td align="center" valign="middle" class="verdana_11px_bold" width="380"><b>
<%
	if(error == null || error.length() == 0 || error.equals("null"))
	{
          out.print("<font color='#336699'>");
          out.print("Please enter your Login Username and Password<br>Then click Login</font></b></td>");
	}
	else if (error.indexOf("expire") != -1)
	{
          out.print("<font color='#FF3333'>");
          out.print(error + "<br></font></b></td>");
	}
	else
	{
          out.print("<font color='#FF3333'>");
          out.print("You have entered an invalid username or password. Please try again.<br></font></b></td>");
	}
%>
          <td width="200">&nbsp;</td>
        </tr>
        <tr>
          <td width="200">&nbsp;</td>
          <td width="380">&nbsp;</td>
          <td width="200">&nbsp;</td>
        </tr>
        <tr>
<form method="post" action="javascript:checkempty();" name="Login">
          <td width="200">&nbsp;</td>
          <td width="380">
            <table width="380" border="0" cellspacing="0" cellpadding="0">
              <tr>
                <td class="10ptype" align="right" valign="top" width="120">User Name: </td>
                <td width="14" height="29">&nbsp;</td>
                <td width="246" align="left" valign="top" height="29">
					<input type="text" name="Uid">
                </td>
              </tr>
              <tr>
                <td width="120" align="right" valign="top" class="10ptype">Password: </td>
                <td width="14">&nbsp;</td>
                <td width="246" align="left" valign="top">
                    <input type="password" name="Password">
                </td>
              </tr>
              <tr>
                <td width="120" align="right" valign="top">
                	<input type="checkbox" name="Remember" checked>
                </td>
                <td width="14">&nbsp;</td>
                <td width="246" align="left" valign="top" class="plaintext">
                    <font color="#336699">Remember My ID & Password</font>
                </td>
              </tr>
              <tr>
                <td width="120">&nbsp;</td>
                <td width="14">&nbsp;</td>
                <td width="246">&nbsp;</td>
              </tr>
            </table>
          </td>
          <td width="250" align='left'>
          	<table border="0" cellspacing="0" cellpadding="0">
          	<tr>
          		<td><img src='i/light_bulb.jpg' border='0' width='20' height='20'>&nbsp;</td>
          		<td><a class="listlink" href='admin/adduser.jsp'>Register new user</a></td>
          	</tr>
          	<tr>
          		<td><img src='i/forgot.jpg' border='0' width='20' height='20'>&nbsp;</td>
          		<td><a class="listlink" href='ep/passwd_help.jsp'>I forgot</a></td>
          	</tr>
          	<tr><td colspan='2'>&nbsp;</td>
          	</tr>
          	</table>
          </td>
        </tr>
        <tr>
          <td width="200">&nbsp;</td>
          <td width="380" align="center" valign="top">
          	<input type='submit' name='login' class='button_medium' value='Login' onClick='return checkempty();'>
		  </td>
          <td width="200">&nbsp;</td>
		  </form>
        </tr>
        <tr>
          <td width="200">&nbsp;</td>
          <td width="380">&nbsp;</td>
          <td width="200">&nbsp;</td>
        </tr>
      </table>

	  <table height="200">
	  	<tr>
			<td>&nbsp;</td>
		</tr>
	  </table>
	</td>
</tr>
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
			<td width="780" valign="middle" align="center">
				<a href="info/faq.jsp?home=../index.jsp" class="listlink">FAQ</a>
				&nbsp;|&nbsp;
				<a href="file/common/PRM Simple Instructions.doc" class="listlink">Instructions</a>
			</td>
		</tr>
		<tr>
			<td height="32" width="780" align="center" valign="middle"><font size="1" face="Arial, Helvetica, sans-serif" color="#999999">Copyright
				&copy; 2005-2010, <%=companyName%></font></td>
		</tr>
      </table>
	</td>
</tr>
</table>
</body>
</html>
