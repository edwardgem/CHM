<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//  Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   out.jsp
//  Author: ECC
//  Date:   07/02/2005
//  Description:
//    This message page
//
//  Modification:
//
/////////////////////////////////////////////////////////////////////
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
<%@ page import = "util.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>

<%
	final String goodStringRegex = "(?i).*( success| done).*";

	String cookiePrefix;
	String HOST = Prm.getPrmHost();
	boolean isCRAPP = util.Prm.isCR();
	boolean isMeetWE = util.Prm.isMeetWE();
	if (isCRAPP) {
		cookiePrefix = "CR";
	}
	else if (isMeetWE) {
		cookiePrefix = "OMF";
	}
	else {
		cookiePrefix = "PRM";
	}

	String s;
	String secureHost;
	if (Prm.isSecureHost())
		secureHost = HOST.replace("http", "https");
	else
		secureHost = HOST;

	// whenever use "go", must not use "e" but "msg" to specify message.  "e" will be set to "time out" here.
	String errorType = request.getParameter("e");
	String errorMsg = request.getParameter("msg");
	//System.out.println("errorType=" + errorType + "; errorMsg=" + errorMsg);

	if (StringUtil.isInteger(errorMsg)) {
		// get it from the message file
		String errmsgIdS = "MSG." + errorMsg;		// MSG.1001
		ArrayList<String> varList = new ArrayList<String>();
		for (int i=0; i<5; i++) {
			// get up to 5 parameters
			if ((s = request.getParameter("var" + i)) != null) {
				varList.add(s);
			}
			else {
				break;	// no more parameter for error message
			}
		}
		errorMsg = StringUtil.getLocalString(StringUtil.TYPE_MESSAGE, null, errmsgIdS, varList.toArray(new String[0]));
	}
	String dest = "javascript:history.back()";
	String go = request.getParameter("go");

	String msgTextColor = "red";
	if (errorMsg!=null && errorMsg.matches(goodStringRegex))
		msgTextColor = "green";

	String app = Prm.getAppTitle();

	boolean isGuest = false;
	PstUserAbstractObject pstuser = (PstUserAbstractObject)session.getAttribute("pstuser");
	if (pstuser!=null && pstuser instanceof PstGuest)
		isGuest = true;

	//System.out.println("go1="+ go);
	if (go != null)
	{
		String lowerGo = go.toLowerCase();
		if (errorMsg == null)
		{
			// coming from some pages like mtg_view.jsp, which get hit through email links
			if (lowerGo.indexOf("time out") != -1) {
				// only remove time out. Calls coming from cr.jsp, etc.
				// also has parameters with ? and should not be removed
				go = go.substring(0, lowerGo.indexOf("e=time out")-1);	// remove the "&e=time out" part
				errorType = "time out";
			}
		}
		else
		{
			// other error, go is set to some destination page
			dest = go;
			dest = dest.replaceAll(":", "&");
		}
	}
	//System.out.println("go2="+ go);

	String butName = "Back";
	boolean isTimeOut = false;
	if (errorType!=null && errorType.equalsIgnoreCase("time out"))
	{
		butName = "Login";
		dest = "index.jsp";
		errorType = "Your session has timed out. Please log in again.";	// consistent timeout message
		isTimeOut = true;
		if (go == null)
			go = "";
	}
	else if (isGuest && isMeetWE)
	{
		// OMF guest response
		butName = "Login";
		dest = "login_omf.jsp";
		if (StringUtil.isNullOrEmptyString(errorType)) {
			errorType = "You need to login in order to use this feature.</br>"
							+ "Please click the Button below to login or to create a free MeetWE account.";
		}
		if (go == null)
			go = "";
	}
	else if (go != null)
	{
		butName = "Continue";
	}

%>

<head>
<title><%=app%></title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />

<form name='QuickLogin' method='post' action='<%=secureHost%>/checklogin.jsp'>
	<input type='hidden' name='Uid' value=''>
	<input type='hidden' name='Password' value=''>
	<input type='hidden' name='Go' value=''>
</form>

<link href="oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="init.jsp" flush="true"/>
<script language="JavaScript" src="login_cookie.js"></script>
<script language="JavaScript">
<!--

var username = getCookie("<%=cookiePrefix%>username");
var timeOut = '<%=isTimeOut%>';

var f = document.QuickLogin;
var goPath = '<%=go%>';
if (goPath == '')
	goPath = document.referrer.replace(/&/g, ":");
f.Go.value = goPath;

if (timeOut=='true' && username!=null)
{
	// this is a timeout error, try to login and go to the destination page
	var password = getCookie("<%=cookiePrefix%>password");
	f.Uid.value = username;
	f.Password.value = password;
	f.submit();	// this will go to checklogin and leave the page
	// cannot have return;
}

window.onload = function()
{
	fo();
}

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
		setCookie("PRMusername", Login.Uid.value, now);
		setCookie("PRMpassword", Login.Password.value, now);
	}

	// set up the Go path for checkLogin
	if ('<%=go%>' != '')
		Login.Go.value = '<%=go%>';
	else if (timeOut=='true')
		Login.Go.value = document.referrer.replace(/&/g, ":");

	Login.action = "<%=secureHost%>/checklogin.jsp";
	Login.submit();
}

function goButton()
{
	if ("<%=dest%>".indexOf("javascript") != -1)
		<%=dest%>
	else
		location = "<%=dest%>";
}

function fo()
{
	if (typeof Login != 'undefined')
		Login.Uid.focus();
}

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
<%
			if (errorMsg != null)
			{
%>
			<tr valign="middle" align="center">
				<td class="ptextS2">
					<font color ="<%=msgTextColor%>"><%=errorMsg %></font>
				</td>
			</tr>
			<tr><td><img src="i/spacer.gif" width="2" height="40"></td></tr>
			<tr>
          		<td align="center">
          			<input type='submit' class='button_medium' value='<%=butName%>' onClick='location="<%=dest%>"'>
				</td>
       		</tr>
<%
			}
			else if (errorType != null)
			{
%>
			<tr valign="middle" align="center">
				<td class="ptextS2">
					<font color ="red"><%=errorType%></font>
				</td>
			</tr>
			<tr><td><img src="i/spacer.gif" width="2" height="40"></td></tr>

<%				if (isTimeOut)
				{%>
<form method="post" action="javascript:checkempty();" name="Login">
<input type="hidden" name="Go" value="">
        <tr>
          <td align="center">
            <table width="380" border="0" cellspacing="0" cellpadding="0">
              <tr>
                <td class="ptextS1" align="right" valign="top" width="120">Username: </td>
                <td width="14" height="29">&nbsp;</td>
                <td width="246" align="left" valign="top" height="29">
					<input type="text" name="Uid" class='ptextS1'>
                </td>
              </tr>
              <tr>
                <td width="120" align="right" valign="top" class="ptextS1">Password: </td>
                <td width="14">&nbsp;</td>
                <td width="246" align="left" valign="top">
                    <input type="password" name="Password" class='ptextS1'>
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
        </tr>
        <tr>
          <td align="center" valign="top">
          	<input type='submit' name='login' class='button_medium' value='Login' onClick='return checkempty();'>
		  </td>
        </tr>

<%				}
				else if (isGuest)
				{
					out.print("<tr><td align='center'>");
					out.print("<input type='submit' value='LOGIN' onclick='javascript:location=\"login_omf.jsp\";'>");
					out.print("&nbsp;&nbsp; OR &nbsp;&nbsp;");
					out.print("<input type='submit' value='SIGN UP NOW' onclick='javascript:location=\"login_omf.jsp?status=new\";'>");
					out.print("</td></tr>");
				}
				else
				{
%>
			<tr>
          			<td align="center">
          				<input type='submit' class='button_medium' value='<%=butName%>' onClick='location="<%=dest%>";'>
					</td>
       		</tr>
<%				}
			}
			else
			{
%>
				<tr valign="middle" align="center">
					<td class="verdana_11px_bold">
						<font color ="red"><strong>Your session has timed out. Please log in again.</strong></font>
					</td>
				</tr>
				<tr><td><img src="i/spacer.gif" width="2" height="40"></td></tr>
				<tr>
          			<td align="center">
          				<input type='submit' class='button_medium' value='Login' onClick='return checkempty();'>
					</td>
       			</tr>
<%
			}
%>

</form>

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
		<td height="2" width="100%" bgcolor="336699"><img src="ep/images/mid/336699-2by2-holder.gif" width="2" height="2"></td>
	</tr>

	<tr>
		<td height='30' width="770" valign='top' align="center">
			<a href="index.jsp" class="listlink"><%=app%> Home</a>
			&nbsp;|&nbsp;
			<a href="info/faq.jsp?home=index.jsp" class="listlink">FAQ</a>
			&nbsp;|&nbsp;
			<a href="info/help.jsp" class="listlink">Help forum</a>
		</td>
	</tr>
	<tr valign="top">
		<td width="770" class="8ptype" align="center"><font color="#999999">Copyright © 2009, EGI Technologies, Inc.</font></td>
	</tr>

		</table>
	</td>
  </tr>

</table>
</body>
</html>
