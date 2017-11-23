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
//    This is the login page for MeetWE.
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
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>


<%
	String error = request.getParameter("error");	// comes from checklogin.jsp
	String next = request.getParameter("goto");
	String terms = request.getParameter("terms");
	String req = request.getParameter("req");
	String msg = request.getParameter("msg");		// comes from post_adduser.jsp
	String status = request.getParameter ("status");
	String mid = request.getParameter ("mid");
	String email = request.getParameter ("email");
	String circles = request.getParameter("circle");
	if (circles == null) circles = "";
	
	if (msg == null) msg = "";
	if (mid == null) mid = "";
	if (email == null) email = "";
	
	if (msg.length()<=0 && error!=null)
		msg = "<b>" + error + "</b>";
	
	String button = "";
	String checked = "";
	if (next != null)
	{
		if (next.equals("now") || next.equals("setup"))
			button = "Continue";
		else
			button = "Submit";
	}
	else
		button = "Submit";
	
	if (terms != null && terms.equals("on"))
		checked = " checked";
	
	//req = username : email : senderId 
	String uname = "";
	//String email = "";
	if (req != null)
	{
		String [] sa = req.split(":");
		uname = sa[0];
		email = sa[1];
	}
	
%>

<html>
<head>
<title>MeetWE</title>
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
	deleteCookie("OMFusername");
	deleteCookie("OMFpassword");
//-->
</script>
<%	}
	else
	{
%>

<script language="JavaScript">
<!--
var username = getCookie("OMFusername");
if (username != null)
{
	var password = getCookie("OMFpassword");
	var goto = "<%=next%>";
	window.location = "checklogin.jsp?Uid=" + username + "&Password=" + password + "&goto=" + goto;
}

//-->
</script>
<%	}%>

<script language="JavaScript">
var nextField = "Uid";
<!--
function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

function checkempty1()
{
	// existing user login
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
		setCookie("OMFusername", Login.Uid.value, now);
		setCookie("OMFpassword", Login.Password.value, now);
	}

	Login.submit();
}
function checkempty2()
{
	// new user registration
	if (Login.UserName.value =='')
	{
		fixElement(Login.UserName,
			"Please make sure that the USERNAME field was properly completed.");
		return false;
	}
	// @SWS090506
	var userName = trim(Login.UserName.value);
	if (userName.length<5 || userName.length>15)
	{
		fixElement(Login.UserName,
				"USERNAME must be between 5 to 15 characters long.");
		return false;
	}
	for (i=0;i<userName.length;i++) {
		char = userName.charAt(i);
		if (char == '\"' || char == '\\' || char == '~'
				|| char == '`' || char == '!' || char == '#' || char == '$' 
				|| char == '%' || char == '^' || char == '*' || char == '(' 
				|| char == ')' || char == '+' || char == '=' || char == '['
				|| char == ']' || char == '{' || char == '}' || char == '|'
				|| char == '?' || char == '>' || char == '<' || char == ' '
				|| char == '\t') {
			fixElement(Login.UserName,
				"USERNAME cannot contain these characters: \n  \t \" \\ ~ ` ! # $ % ^ * ( ) + = [ ] { } |  ? > <");
			return false;
		}
	}
	
	var email = trim(Login.Email.value);
	if (email.length > 0)
	{
		if (!checkMail(email))
		{
			fixElement(Login.Email,
				"'" + email + "' is not a valid email address, \nplease correct the error and submit again.");
			return false;
		}
	}
	else
	{
		fixElement(Login.Email,
			"Please make sure that the EMAIL field was properly completed.");
		return false;
	}

	if (Login.Terms.checked == false){
		fixElement(Login.Terms,
				"Please check to accept the terms of use.");
		return false;
	}

	Login.method="post" 
	Login.action="admin/post_adduser.jsp"

	Login.submit();
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

	if("<%=status%>" == "new" || "<%=mid%>" != "")
		Login.UserName.focus();
}

function entSub(event, ii)
{
  if (window.event && window.event.keyCode == 13)
  {
  	if (ii == 1)
		checkempty1();
  	else if (ii == 2)
		checkempty2();
	else
		eval('Login.' + nextField + '.focus()');
	return false;
  }
  else if (event && event.which == 13)
  {
  	if (ii == 1)
		checkempty1();
  	else if (ii == 2)
		checkempty2();
	else
		eval('Login.' + nextField + '.focus()');
	return false;
  }
  return true;
}
    
//-->

</script>


</head>

<body bgcolor="#FFFFFF" onLoad="MM_preloadImages('i/but/lgin.gif');fo();" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" height="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">
<table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr align="left" valign="top">
    <td><jsp:include page="loginhead.jsp" flush="true"/></td>
  </tr>
  <tr align="left" valign="top">
    <td>
      <table width="100%" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td width="50">&nbsp;</td>
          <td width="270">&nbsp;</td>
          <td width="70">&nbsp;</td>
          <td width="400">&nbsp;</td>
        </tr>
		<tr>
		<td width="50">&nbsp;</td>
		<td colspan=3 class="plaintext"><font color="#FF3333">
		<%=msg%></font></td>
        </tr>
		<tr>
          <td colspan="4">&nbsp;</td>
        </tr>
        <tr>
          <td width="50">&nbsp;</td>
          <td align="center" valign="top" class="10ptype" width="300"><b>

          <font color='#336699'>
          <b>Already registered?</font></b>

		  </td>
		  <td width="50">&nbsp;</td>
		  
          <td valign="top" class="10ptype" align='center'>
          	<font color='#336699'>
          	<b>New user?</b></font>
          </td>
        </tr>
        <tr>
          <td width="50">&nbsp;</td>
          <td width="270">&nbsp;</td>
          <td width="70">&nbsp;</td>
         <td width="360">&nbsp;</td>
        </tr>
        <tr>
          <td width="50">&nbsp;</td>
          <form method="post" action="checklogin.jsp" name="Login">
          <input type="hidden" name="goto" value="<%=next%>">
          <input type="hidden" name="status" value="<%=status%>">
          <input type="hidden" name="mid" value="<%=mid%>">
          <input type="hidden" name="circle" value="<%=circles%>">
          
<!-- LEFT TABLE -->
          <td width="270">
            <table width="300" border="0" cellspacing="0" cellpadding="0">
              <tr>
                <td width="70" class="ptextS1" align="right" valign="top">Username: </td>
                <td width="14" height="29">&nbsp;</td>
                <td width="190" align="left" valign="top" height="29">
					<input type="text" name="Uid" onfocus="nextField='Password';" onKeyDown="return entSub(event, 0);" class='ptextS1'>
                </td>
              </tr>
              <tr>
                <td width="70" align="right" valign="top" class="ptextS1">Password: </td>
                <td width="14">&nbsp;</td>
                <td width="190" align="left" valign="top">
                    <input type="password" name="Password" onKeyDown="return entSub(event, 1);" class='ptextS1'>
                </td>
              </tr>
              <tr>
                <td width="70" align="right">
                	<input type="checkbox" name="Remember" onKeyPress="return entSub(event, 1);" checked>
                </td>
                <td width="14">&nbsp;</td>
                <td width="190" align="left" valign="middle" class="ptextS1">
                    <font color="#336699">Remember me</font>
                </td>
              </tr>
              <tr>
                <td colspan='3'>&nbsp;</td>
               </tr>
            </table>
          </td>
          
          <td valign='top' width='70'>
			<table>
				<tr><td><img src='i/spacer.gif' width='1' height='5'></td></tr>
				<tr>
			  	<td class="10ptype" valign='top'><font color='#336699' size='+1'>
			      		OR</font></td></tr>
			</table>
	      </td>
          
<!-- RIGHT TABLE -->
          <td width="500" align='left' valign='top'>
        <table border="0" cellspacing="0" cellpadding="0">
        <tr>
            <td width="200" class="ptextS1" align="right" valign="top">New Username: </td>
            <td width="14" height="29">&nbsp;</td>
            <td width="400" align="left" valign="top" height="29" class="formtext">
				<input type="text" name="UserName" value="<%=uname%>" class='ptextS1'
					onfocus="nextField='Email';" onKeyDown="return entSub(event, 0);"> (e.g. batman07)
            </td>
        </tr>
        <tr>
            <td width="100" align="right" valign="top" class="ptextS1">Email: </td>
            <td width="14">&nbsp;</td>
            <td width="160" align="left" valign="top">
                <input type="text" name="Email" value="<%=email%>" onKeyDown="return entSub(event, 2);" class='ptextS1'>
            </td>
        </tr>
        <tr>
          <td width="100" align="right" valign="top">
          	<input type="checkbox" name="Terms" onKeyPress="return entSub(event, 2);" <%=checked%>>
          </td>
          <td width="14">&nbsp;</td>
          <td width="160" align="left" valign="middle" class="ptextS1">
              <font color="#336699">I accept <a href='info/terms_omf.jsp' class='ptextS1'>the terms of use</a></font>
          </td>
        </tr>
          	</table>
          </td>
          
        </tr>
        
        <tr>
          <td width="50">&nbsp;</td>
          <td width="270" align="center">
			<input type="Button" class='button_medium' name="Submit1" value="<%=button%>" onclick="return checkempty1();">
		  </td>
          <td width="50">&nbsp;</td>
          <td width="360" align="center">
			<input type="Button" class='button_medium' name="Submit2" value="Submit" onclick="return checkempty2();">
          </td>
		  </form>
        </tr>
        <tr>
          <td colspan='4'>&nbsp;</td>
        </tr>
      </table>

	  <table height="80">
      	<tr>
      	<td><img src='i/spacer.gif' width='60' height='1'></td>
  		<td><img src='i/forgot.jpg' border='0' width='20' height='20'>&nbsp;</td>
  		<td><a class="listlink" href='ep/passwd_help.jsp'>Forgot your password?</a></td>
  		</tr>
	  </table>
	</td>
</tr>
<tr>
	<td valign="bottom">
		<table width="90%" border="0" cellspacing="0" cellpadding="0">
		<tr>
		  <td>&nbsp;</td>
		</tr>
		<tr>
			<td height="2" width="100%" bgcolor="336699"><img src="ep/images/mid/336699-2by2-holder.gif" width="2" height="2"></td>
		</tr>
		<tr>
			<td width="780" valign="middle" align="center">
				<a href="info/faq_omf.jsp" class="listlink">FAQ</a>
				&nbsp;|&nbsp;
				<a href="info/privacy_omf.jsp" class="listlink">Privacy Statement</a>
				&nbsp;|&nbsp;
				<a href="info/terms_omf.jsp" class="listlink">Terms of Use</a>
				&nbsp;|&nbsp;
				<a href="info/help.jsp" class="listlink">Help</a>
			</td>
		</tr>
		<tr>
			<td height="32" width="780" align="center" valign="middle"><font size="1" face="Arial, Helvetica, sans-serif" color="#999999">Copyright
				&copy; 2008-11, MeetWE, Inc.</font></td>
		</tr>
      </table>
	</td>
</tr>
</table>
</body>
</html>
