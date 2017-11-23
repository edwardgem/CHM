<%@ page contentType="text/html; charset=utf-8"%>

<%
//
//  Copyright (c) 2006, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   index.jsp
//  Author: ECC
//  Date:   07/02/2004
//  Description:		This is the index page for PRM.  We will start from the Search Page.
//  Modification:
//
/////////////////////////////////////////////////////////////////////
//
//
%>

<%@ page import = "util.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "mod.se.SearchResult" %>
<%@ page import = "mod.se.FilteredResult" %>
<%@ page import = "mod.se.QueryManagement" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	String crPage, cookiePrefix, companyName, uNameExample, systemName, systemDesc, meta;
	boolean isCRAPP = util.Prm.isCR();
	boolean isMeetWE = util.Prm.isMeetWE();

	if (isCRAPP) {
		crPage = "ep_cr.jsp";
		cookiePrefix = "CR";
		companyName = "EGI Technologies, Inc.";
		uNameExample = "xxx@gmail.com";
		systemName = "Central Repository";
		systemDesc = "An Online Portal for File & Event Sharing";
		meta = "EGI Central Repository (CR) is a turnkey collaboration solution to enable a global knowledge portal for file & event sharing and collaboration";
	}
	else if (isMeetWE) {
		crPage = "ep_omf.jsp";
		cookiePrefix = "OMF";
		companyName = "MeetWE, Inc.";
		uNameExample = "batman7";
		systemName = "";
		systemDesc = "Social Meeting with Fun";
		meta = "MeetWE is a social network for you and your friends to meet and share fun and useful information";
	}
	else {
		crPage = "ep_prm_db.jsp";
		cookiePrefix = "PRM";
		companyName = "EGI Technologies, Inc.";
		uNameExample = "batman7";
		systemName = "Collaborative Hospital Management";
		systemDesc = "Global Team Collaboration";
		meta = "EGI CPM is a turnkey collaboration solution to enable a global knowledge portal for file & event sharing and collaboration";
	}
	String appS = util.Prm.getAppTitle();

%>
<html>
<head>
<title><%=appS%></title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta name="description" content="<%=meta%>">
<meta name="keywords" content="file sharing, collaboration, knowledgebase portal, remote backup" />
<link href="oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="init.jsp" flush="true"/>

</head>

<script language="JavaScript" src="login_cookie.js"></script>

<%
	String s;
	String HOST = Util.getPropKey("pst", "PRM_HOST");
	String errMsg = request.getParameter("error");
	String uid = request.getParameter("Uid");

	String secureHost;
	if ((s = Util.getPropKey("pst", "SECURE_HOST"))!=null && s.equalsIgnoreCase("true"))
		secureHost = HOST.replace("http", "https");
	else
		secureHost = HOST;

	// @ECC080108 Multiple company
	boolean isMultiCorp = Prm.isMultiCorp();

	PstUserAbstractObject u = null;

	String topHeadS = null;
	boolean bIsLogin = false;

	if (uid!=null)
	{
		// try to login
		String passwd = request.getParameter("Passwd");
		try
		{
			String srcPath = request.getRealPath(new String());
			srcPath = srcPath.replace('\\', '/');
			srcPath = srcPath + "/WEB-INF/lib/dataSource.xml";
			PstManager.initConnectionPool(srcPath);

			u = Util.login(session, uid, passwd);
			bIsLogin = true;

			String lname = (String)u.getAttribute("LastName")[0];
			String uname = ((user)u).getFullName();
			topHeadS = "<b>" + uname + "</b>"
				+ " | <a href='ep/ep_home.jsp'>Home</a>"
				+ " | <a href='ep/ep1.jsp?uid=" + u.getObjectId() + "'>My Account</a>"
				+ " | <a href='logout.jsp'>Sign out</a> &nbsp;&nbsp;";
		}
		catch (Exception e)
		{
			errMsg = "Failed to login.";		// do nothing: only the cookies will be removed
		}
	}
	else
	{
		if (session!=null && (u = (PstUserAbstractObject)session.getAttribute("pstuser"))!=null)
			if (!(u instanceof PstGuest))
				bIsLogin = true;
	}

	// already login
	if (bIsLogin)
	{
%>
<SCRIPT LANGUAGE="JavaScript">
<!--
		if (parent.document.URL.indexOf("index.jsp") == -1) {
			// just go to ep_home.jsp
			location = "ep/ep_home.jsp";
			return;
		}
//-->
</script>
<%
		String lname = (String)u.getAttribute("LastName")[0];
		String uname = ((user)u).getFullName();
		topHeadS = "<b>" + uname + "</b>"
			+ " | <a href='ep/ep_home.jsp'>Home</a>"
			+ " | <a href='ep/ep1.jsp?uid=" + u.getObjectId() + "'>My Account</a>"
			+ " | <a href='logout.jsp'>Sign out</a> &nbsp;&nbsp;";
	}

	// called by logout.jsp?
	boolean bLogout = request.getParameter("logout")!=null;
	if (bLogout || errMsg!=null)
	{	// ECC: must do deleteCookie here, won't work to do it in logout.jsp
%>
<SCRIPT LANGUAGE="JavaScript">
<!--
	deleteCookie("<%=cookiePrefix%>username");
	deleteCookie("<%=cookiePrefix%>password");
//-->
</script>
<%	}

	if (!bIsLogin)
	{
		// try to get cookie to auto login
%>

<form name='LoginForm' method='post' action='<%=secureHost%>/checklogin.jsp'>
	<input type='hidden' name='Uid' value=''>
	<input type='hidden' name='Password' value=''>
</form>

<script language="JavaScript">
<!--
var username = getCookie("<%=cookiePrefix%>username");
if (!<%=bLogout%> && username!=null)
{
	var password = getCookie("<%=cookiePrefix%>password");
	LoginForm.Uid.value = username;
	LoginForm.Password.value = password;
	LoginForm.submit();		// attempt login, if succeed it will go to the right default page
}

//-->
</script>
<%	}%>

<script language="JavaScript">
<!--

function checkempty1()
{
	// existing user login
	if (Login.Uid.value == "")
	{
		fixElement(Login.Uid, "Please enter your Username, e.g. <%=uNameExample%>");
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
	Login.submit();
}

var nextField = "Password";
function entSub(event, ii)
{
  if (window.event && window.event.keyCode == 13)
  {
  	if (ii == 1)
		checkempty1();
	else
		eval('Login.' + nextField + '.focus()');
	return false;
  }
  else if (event && event.which == 13)
  {
  	if (ii == 1)
		checkempty1();
	else
		eval('Login.' + nextField + '.focus()');
	return false;
  }
  return true;
}

//-->
</script>
<%
	if (topHeadS == null)
	{
		topHeadS = "<a href='";
		if (isMultiCorp)
			topHeadS += "info/upgrade.jsp";
		else
			topHeadS += secureHost + "/admin/adduser.jsp";
		topHeadS += "'><b>New User</b></a>"
			+ " | <a href='ep/passwd_help.jsp'>Forgot Password</a>"
			+ " | <a href='info/faq.jsp?home=index.jsp'>Help</a> &nbsp;&nbsp;";
	}
%>

<script language="JavaScript">
<!--

function fo()
{
	f = document.Login;
	if (f == null)
		f = document.SearchForm;
	for (i=0;i < f.length;i++)
	{
		if (f.elements[i].type != "hidden")
		{
			f.elements[i].focus();
			break;
		}
	}
}

//-->
</script>


<body bgcolor="#FFFFFF" onLoad="fo();" leftmargin="0" topmargin="5" marginwidth="0" marginheight="0">

<table width="100%" height="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">

<table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr valign="top">
  	<td colspan='2'>
  	<table border="0" cellspacing="0" cellpadding="0">
  	<tr>
		<td valign='top'><img src='i/spacer.gif' width='22' height='1' /><img src='i/logo.gif' height='70' /></td>
		<td>
	  		<table border="0" cellspacing="0" cellpadding="0">
	   		<tr>
		   		<td><img src='i/spacer.gif' width='10'></td>
				<td style='font-size:14px; font-family:Verdana, Arial, Helvetica, sans-serif; color:#004492; font-weight:bold'>
					<%=systemName%></td>
			</tr>
			<tr><td><img src='i/spacer.gif' height='3' width='1' /></td></tr>
			<tr><td></td><td style='font-size:12px; color:#004492; font-family:Verdana, Arial, Helvetica, sans-serif; font-weight:bold'>
					<%=systemDesc%></td>
			</tr>
			</table>
		</td>
	</tr></table>
  	</td>
    <td colspan='2' align='right' width='400' class='ptextS1'><%=topHeadS %></td>
  </tr>

  <tr><td colspan='4'><img src='i/spacer.gif' height='50'></td></tr>

  <tr>
  	<td width='25%'></td>
    <td align="center" valign="top" width='400'>
      <table border="0" cellspacing="0" cellpadding="0">
      <tr>
      	<td align='center' colspan='2'>
      		<table border="0" cellspacing="0" cellpadding="0">
 	 		<tr><td><img src='i/spacer.gif' height='20'></td></tr>

<%	if (!isCRAPP) { 	// isMultiCorp || isMeetWE
%>
		 	 <tr>
			  	<td>
				<img src="i/bullet_tri.gif" width="20" height="10">
				<a class="listlinkbold2" href='meeting/cal.jsp'>Event Calendar</a>
		 	  	</td>
		 	 </tr>
<%	} %>
 	 		<tr><td><img src='i/spacer.gif' height='5'></td></tr>

		 	 <tr>
			  	<td>

<%
	out.print("<img src='i/bullet_tri.gif' width='20' height='10'>");
	if (bIsLogin) {
		if (isMultiCorp) {
			out.print("<a class='listlinkbold2' href='project/proj_new1.jsp'> Add a New Project</a></td></tr>");
			out.print("<tr><td><img src='i/spacer.gif' height='5'></td></tr>");
			out.print("<tr><td><img src='i/bullet_tri.gif' width='20' height='10'>");
			out.print("<a class='listlinkbold2' href='info/upgrade.jsp'> Upgrade My "
				+ appS + " Service</a></td></tr>");
			out.print("<tr><td><img src='i/spacer.gif' height='10'>");
		}
		else
			out.print("<a class='listlinkbold2' href='ep/ep_home.jsp'>Goto My Home Page</a>");
	}
	else {
		out.print("<a class='listlinkbold2' href='");
		if (isMultiCorp)
			out.print("info/upgrade.jsp");
		else
			out.print(secureHost + "/admin/adduser.jsp");
		out.print("'>Create a New User Account</a>");
	}
%>

		 	  	</td>
		 	 </tr>

			</table>
		</td>
 	  </tr>

 	  <tr><td><img src='i/spacer.gif' height='20'></td></tr>

<%	if (bIsLogin || !isMultiCorp) { %>
<form name='SearchForm' method='get' action='servlet/PostSearch'>
 	  <tr>
 	  		<td><input type='text' size='60' name='query' value=''></td>
 	  </tr>
 	  <tr><td><img src='i/spacer.gif' height='10'></td></tr>
 	  <tr><td align='center'><input type="submit" class='button_medium' value='<%=appS%> Search'></td></tr>
<%	} %>

	  <tr><td colspan='3'><img src='i/spacer.gif' height='30'></td></tr>

	  <tr><td colspan='3' align='center'>
	  	<a href='info/faq.jsp?home="../index.jsp"'>HELP</a> -
	  	<a href='file/common/CPM_User_Manual.pdf'>Instruction</a> -
<!--	  	<a href='info/faq.jsp?home="../index.jsp"'>About <%=Util.getPropKey("pst", "COMPANY_NAME")%> <%=appS%></a> -->
	  	<a href='info/faq.jsp?home="../index.jsp"'>About <%=appS%></a>
	  </td></tr>

	  <tr><td colspan='3'><img src='i/spacer.gif' height='5'></td></tr>

	  <tr><td colspan='3' align='center'><a HREF='<%=HOST%>' onClick="this.style.behavior='url(#default#homepage)';this.setHomePage('<%=HOST%>/');">Make <%=appS%> Your Home Page</a></td></tr>

	  <tr><td colspan='3'><img src='i/spacer.gif' height='10'></td></tr>

	  <tr>
	    <td colspan='3' height="32" align="center" valign="middle"><font size="1" face="Arial, Helvetica, sans-serif" color="#aaaaaa" class="8ptype">
	    	&copy; Copyright 2013-2016, <%=companyName%></font></td>
	  </tr>

	  </table>
	</td>
</form>



<!-- Login window -->
<%	if (!bIsLogin)
	{%>
		<td>&nbsp;&nbsp;</td>
		
		<td valign='top'>
		<form method="post" action="<%=secureHost%>/checklogin.jsp" name="Login">
		<table border='0' cellspacing='0' cellpadding='0'>
		<tr><td><img src='i/spacer.gif' height='10' /></td></tr>

		<tr>
		    <td width="180" valign='top' style='border:1px solid #6699cc; padding:5; padding-right:8;'>
		    <table border='0' cellspacing="0" cellpadding="0">
		      <tr><td colspan='3'><img src='i/spacer.gif' height='5' width='1' /></td></tr>
		      <tr>
		        <td width="70" class="ptextS1" align="right" valign="middle"><font color="#336699">Username:</font></td>
		        <td>&nbsp;&nbsp;</td>
		        <td width="80" align="left" valign="center" height="29">
					<input class='ptextS1' type="text" size='15' name="Uid" onfocus="nextField='Password';">
		        </td>
		      </tr>
		      <tr>
		        <td width="70" align="right" valign="middle" class="ptextS1"><font color="#336699">Password:</font></td>
		        <td></td>
		        <td width="80" align="left" valign="center">
		            <input class='ptextS1' type="password" size='15' name="Password" onKeyDown="return entSub(event, 1);">
		        </td>
		      </tr>
		      <tr>
		        <td width="70" align="right">
		        	<input type="checkbox" name="Remember" onKeyPress="return entSub(event, 1);" checked="checked">
		        </td>
		        <td></td>
		        <td width="85" align="left" valign="middle" class="formtext" height="29">
		            <font color="#336699">Remember me</font>
		        </td>
		      </tr>
		      <tr><td colspan='3'><img src='i/spacer.gif' height='5' width='1' /></td></tr>
			  <tr>
			    <td colspan='3' align="center">
					<input class='button_medium' type="Button" name="Submit1" value="Sign-In" onclick="return checkempty1();">
				</td>
			  </tr>
		      <tr><td colspan='3'><img src='i/spacer.gif' height='5' width='1' /></td></tr>

		    </table>
		  	</td>

	  		<td></td>
	  	</tr>

	  	<tr><td colspan='2' align='right'><a href='info/upgrade.jsp' class='plaintext_big'><b>Sign-up now</b></a></td></tr>

	  	<tr><td colspan='2'><img src='i/spacer.gif' height='50' width='1' /></td></tr>

	  	</table>
	  	</form>
	  	</td>
<%	}
	else
	{
%>
	<td></td>
<%	} %>



  </tr>

	  <tr><td><img src='i/spacer.gif' height='30'></td></tr>

<%	if (isMultiCorp || isMeetWE) {%>
<tr><td colspan='4' align='center'>
<script type="text/javascript"><!--
google_ad_client = "pub-8652216983185669";
google_ad_width = 728;
google_ad_height = 90;
google_ad_format = "728x90_as";
google_ad_type = "text_image";
//2006-11-10: IndexHead
google_ad_channel = "5572881579";
google_color_border = "0066BB";
google_color_bg = "EEEEEE";
google_color_link = "0066BB";
google_color_text = "000000";
google_color_url = "22CC22";
//--></script>
<script type="text/javascript"
  src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
</script>
</td></tr>
<%	} %>


</table>

</body>
</html>
