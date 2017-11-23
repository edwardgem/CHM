<%
////////////////////////////////////////////////////
//	Copyright (c) 2008, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	account.jsp
//	Author:	ECC
//	Date:	09/05/08
//	Description:
//		Manage account, show quarterly account history, purchase credit.
//	Modification:
//
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "util.*" %>
<%@ page import = "net.tanesha.recaptcha.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>

<%
	String HOST			= Util.getPropKey("pst", "PRM_HOST");

	String s;
	String secureHost;
	boolean isSecureHost = false;
	if ((s = Util.getPropKey("pst", "SECURE_HOST"))!=null && s.equalsIgnoreCase("true"))
	{
		isSecureHost = true;
		secureHost = HOST.replace("http", "https");
	}
	else
		secureHost = HOST;

	String [] levelArray = {userinfo.LEVEL_1, userinfo.LEVEL_2, userinfo.LEVEL_3, userinfo.LEVEL_4};

	boolean isLogin = false;
	
	// create a user object as guest if I am not login yet
	PstUserAbstractObject pstuser = null;
	HttpSession sess = request.getSession(false);
	if (sess != null)
		pstuser = (PstUserAbstractObject)sess.getAttribute("pstuser");
	else
		sess = request.getSession(true);
	if (pstuser == null) {
		try {
			sess = request.getSession(true);
			pstuser = (PstUserAbstractObject) PstGuest.getInstance();
		} catch (PmpException e) {
			response.sendRedirect(HOST+ "/out.jsp?e=The requested page is temporarily unavailable, please try again later.");
			return;
		}
	}
	else
		isLogin = true;
	
	// get parameter from back page
	String msg = request.getParameter("msg");
	String email = request.getParameter("Email");
	if (email == null)
		email = "";
	String pass = request.getParameter("newPass");
	if (pass == null)
		pass = "";
	
	String home;
	userinfo ui = null;
	
	// check to see if user is attempting to downgrade
	String levelS = request.getParameter("level");
	int iCurrentLevel = 0;		// currently subscribed level
	int iLevel = 0;				// the newly selected level
	if (isLogin)
	{
		userinfoManager uiMgr = userinfoManager.getInstance();
		ui = (userinfo)uiMgr.get(pstuser, String.valueOf(pstuser.getObjectId()));
		home = HOST + "/ep/ep_home.jsp";

		for (int i=0; i<levelArray.length; i++)
		{
			if (levelS.equals(levelArray[i]))
			{
				iLevel = i;
				break;
			}
		}
		s = (String)ui.getAttribute("Status")[0];
		if (s == null)
			iCurrentLevel = 0;		// Standard level
		else
		{
			for (int i=0; i<levelArray.length; i++)
			{
				if (s.indexOf(levelArray[i]) != -1)
				{
					iCurrentLevel = i;
					break;
				}
			}
		}
		if (iCurrentLevel > iLevel)
		{
			response.sendRedirect("../out.jsp?msg=Please send email to <a href='mailto:support@egiomm.com'>support@egiomm.com</a> to downgrade or cancel your service.");
			return;
		}
	}
	else
	{
		home = HOST + "/index.jsp";
		
		// allow FREE account
		if (levelS.equals(userinfo.LEVEL_1))
		{
			// new user choosing Standard level: free!
			response.sendRedirect("../admin/adduser.jsp");
			return;
		}
	}
	
	// get parameter
	// space
	String payPalMethod = "M";
	String spaceS = request.getParameter("space");
	s = request.getParameter("spaceStmt");
	if (s != null)
		spaceS += " " + s;
	String paymentS = request.getParameter("paymentType");
	String serviceS = levelS + paymentS;					// to be saved to DB e.g. EliteMonthly
	
	// # of user
	String userLimitS = request.getParameter("userLimit");
	
	// # of project
	String projLimitS = request.getParameter("projLimit");
	if (projLimitS.equals("-1")) projLimitS = "Unlimited";

	String costS = "US$ ";
	String monthS="", yearS="";
	if (paymentS.equals(userinfo.PAYMT_MONTHLY))
		monthS = s = request.getParameter("monthCost");
	else
	{
		yearS = s = request.getParameter("yearCost");
		payPalMethod = "Y";
	}
	costS += s;  
	String payPalPrice = s;
	
	// check if the guy is on the old level and choose less space
	if (isLogin && iCurrentLevel==iLevel)
	{
		int iCurrentSpace = ((Integer)pstuser.getAttribute("SpaceTotal")[0]).intValue();
		if (iCurrentSpace == 0)
			iCurrentSpace = userinfo.DEFAULT_CR_SPACE;

		int idx = spaceS.indexOf(" GB");
		if (idx != -1)
		{
			// when we are in here it is always in GB unless the guy backout and change his mind
			s = spaceS.substring(0, idx);
			int iSpace = Integer.parseInt(s) * 1000;
			if (iCurrentSpace > iSpace)
			{
				response.sendRedirect("../out.jsp?msg=Please send email to <a href='mailto:support@egiomm.com'>support@egiomm.com</a> if you would like to reduce your storage space.");
				return;
			}
			else if (iCurrentSpace == iSpace)
			{
				response.sendRedirect("../out.jsp?msg=You are already on this level of service, please choose a higher level to upgrade.");
				return;
			}
		}
	}
	
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="../init.jsp" flush="true"/>
<script language="JavaScript" src="../validate.js"></script>

<script language="JavaScript">
<!--

function validation()
{
	var f = document.acctInfo;
	f.submit();
	return;
	
	var but = document.getElementById("button");
	if (<%=isLogin%> == true)
		but.innerHTML = "<b>Processing</b> ...";
	else
		but.disabled = true;
	
	if (<%=isLogin%> == false)
	{
		// Email (username)
		var email = trim(f.Email.value);
		f.Email.value = email;
		if (email =='')
		{
			fixElement(f.Email,
				"Please make sure that the EMAIL field was properly completed.");
			but.disabled = false;
			return false;
		}
		if ((email.indexOf('@') == -1) ||
			(email.indexOf('.') == -1))
		{
			fixElement(f.Email,
				"Please make sure to enter a valid EMAIL address (e.g. jdoe@gmail.com).");
			but.disabled = false;
			return false;
		}
		
		for (i=0;i<email.length;i++) {
			char = email.charAt(i);
			if (char == '\\') {
				fixElement(f.Email,
					"EMAIL cannot contain these characters: \n  \\");
				but.disabled = false;
				return false;
			}
		}
		
		// Password
		var e = f.newPass;
		if (e!=null && e.value =='')
		{
			fixElement(e,
				"Please make sure that the PASSWORD field was properly completed.");
			but.disabled = false;
			return false;
		}
	
		if (e != null)
		{
			var passVal = f.newPass.value;
			if (passVal.length < 6)
			{
				fixElement(f.newPass,
					"Please make sure that the PASSWORD is at least 6 characters long.");
				but.disabled = false;
				return false;
			}
			else if (passVal.length > 12)
			{
				fixElement(f.newPass,
					"Please make sure that the PASSWORD is at most 12 characters long.");
				but.disabled = false;
				return false;
			}
			else if (passVal.length>0 && passVal != f.rePass.value)
			{
				fixElement(f.newPass,
					"Please make sure PASSWORD and RETYPE PASSWORD are the same.");
				but.disabled = false;
				return false;
			}
			else if (passVal.length>0 && !hasNum(passVal))
			{
				fixElement(f.newPass,
					"Please make sure that the PASSWORD has at least one numeric character in it.");
				but.disabled = false;
				return false;
			}
			else if (passVal.length>0 && !hasAlpha(passVal))
			{
				fixElement(f.newPass,
					"Please make sure that the PASSWORD has at least one alphabet character in it.");
				but.disabled = false;
				return false;
			}
		}
	}	// END if !isLogin
	
	f.submit();
}

//-->
</script>

<title>
	CR Account Information
</title>

</head>

<body text="#000000" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="715" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<b class="head">

	&nbsp;&nbsp;Upgrade CR

	</b><br><br>
	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- Navigation SUB-Menu -->
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
<td width="100%" valign="top">

	<table border="0" width="100%" height="14" cellspacing="0" cellpadding="0">
		<tr>
			<td valign="top" class="bgsubnav">
				<table border="0" cellspacing="0" cellpadding="0">
				<tr class="bgsubnav">
	<!-- Home -->
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="<%=home%>" class="subnav">Home</a></td>
					<td colspan="3" width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- FAQ -->
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="<%=HOST%>/info/faq.jsp" class="subnav">FAQ</a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- Download -->
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="<%=HOST%>/info/download.jsp" class="subnav">Download</a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- Upgrade -->
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="20" height="14"><img src="../i/nav_arrow.gif" width="20" height="14" border="0"></td>
					<td><a href="#" onClick="return false;" class="subnav"><u>Upgrade</u></a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

				</tr>
				</table>
			</td>
		</tr>
	</table>
	<table border="0" width="100%" height="1" cellspacing="0" cellpadding="0">
		<tr>
			<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
		</tr>
	</table>

</td>
</tr>
</table>
<!-- End of Navigation SUB-Menu -->
<style type="text/css">
body,td,th,p,a{font-family:arial,verdana,sans-serif;font-size:12px;}
table {border-collapse:collapse;}
.headlnk_blue_13 {  font-family: Verdana, Arial, Helvetica, sans-serif; color: #202099; font-size: 13px; font-weight: bold}
a.headlnk_blue:link, a.headlnk_blue:active, a.headlnk_blue:visited {  font-family: Verdana, Arial, Helvetica, sans-serif; color: #3030cc; font-size: 14px; font-weight: bold}
.headlnk_pink {  font-family: Verdana, Arial, Helvetica, sans-serif; color: ee2288; font-size: 16px; font-weight: bold; text-decoration: none}
.headlnk_green {  font-family: Verdana, Arial, Helvetica, sans-serif; color: #40a040; font-size: 14px; font-weight: bold}
</style>

<!-- CONTENT -->

<table border='0'>
	
	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='10' /></td></tr>

	<tr>
		<td colspan='3'>
			<table><tr>
				<td><img src='../i/spacer.gif' width='50' height='1' /></td>
				<td class='headlnk_green'>Review your selected level of service</td>
			</tr></table>
		</td>
	</tr>
	
	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='3' /></td></tr>

	<!-- review service selection -->
	<tr>
	<td colspan='3'>
	<table>
		<tr><td><img src='../i/spacer.gif' width='50' height='1' /></td>
		<td>
		<table border='1' cellpadding='3' bgcolor='#efefef'>
			
			<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='5' /></td></tr>
			<tr>
				<td><img src='../i/spacer.gif' width='30' height='1' /></td>
				<td class='headlnk_blue_13' width='300'>Your Level of service</td>
				<td class='headlnk_blue_13' width='200'><%=levelS%></td>
			</tr>
		
			<tr>
				<td></td>
				<td class='headlnk_blue_13'>Total space</td>
				<td class='headlnk_blue_13'><%=spaceS%></td>
			</tr>
		
			<tr>
				<td></td>
				<td class='headlnk_blue_13'>Total # of users</td>
				<td class='headlnk_blue_13'><%=userLimitS%></td>
			</tr>
		
			<tr>
				<td></td>
				<td class='headlnk_blue_13'>Total # of projects</td>
				<td class='headlnk_blue_13'><%=projLimitS%></td>
			</tr>
		
			<tr>
				<td></td>
				<td class="headlnk_blue_13">Total cost</td>
				<td class="headlnk_blue_13"><%=costS %>&nbsp;<%=paymentS %></td>
			</tr>
			
			<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='5' /></td></tr>
			
		</table>
		</td>
		
		<td valign='bottom'>&nbsp;&nbsp;<input type='button' class='plaintext_big' value='Make Changes' onclick='location="upgrade.jsp"'></td>
		
		</tr>
	</table>
	</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='30' /></td></tr>

<%	if (msg != null)
	{
		// display a message
		out.print("<tr><td><img src='../i/spacer.gif' width='27' height='1' /></td>");
		out.print("<td colspan='2' class='plaintext_big' width='550'><font color='#ee0000'>" + msg + "</font></td>");
		out.print("</tr>");
	}
%>

<!-- ************* Transaction Processing ************ -->
<form name='acctInfo' method="post" action='<%=secureHost%>/info/post_account.jsp'>
<input type='hidden' name='login' value='<%=isLogin%>' >
<input type='hidden' name='level' value='<%=levelS%>' >
<input type='hidden' name='space' value='<%=spaceS%>' >
<input type='hidden' name='userLmt' value='<%=userLimitS%>' >
<input type='hidden' name='projLmt' value='<%=projLimitS%>' >
<input type='hidden' name='paymentType' value='<%=paymentS%>' >
<input type='hidden' name='monthCost' value='<%=monthS%>' >
<input type='hidden' name='yearCost' value='<%=yearS%>' >
<input type='hidden' name='payPalPrice' value='<%=payPalPrice%>' >
<input type='hidden' name='payPalMethod' value='<%=payPalMethod%>' >
	
	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='5' /></td></tr>
	
	<tr><td colspan='3'>
		<table>
		<tr>
			<td><img src='../i/spacer.gif' width='50' height='1' /></td>
			<td></td>
			<td></td>
		</tr>

		<tr>
			<td></td>
			<td colspan='2' class="headlnk_green">User Account Information</td>
		</tr>

<%	if (!isLogin) { %>
		<tr>
			<td></td>
			<td colspan=2 class="instruction">
				Note that fields marked with an * are required.</td>
		</tr>
<%	}%>
		
		<tr><td><img src='../i/spacer.gif' width='1' height='20' /></td></tr>
<%

if (!isLogin)
	{
		out.print("<tr><td></td>");
		out.print("<td class='headlnk_blue_13' width='200'><font color='#000000'>*</font> User email:</td>");
		out.print("<td><input type='text' name='Email' class='formtext' size='30' value='" + email + "'>");
		out.print("<span class='plaintext_small'>&nbsp;&nbsp;(This is your login name)</span>");
		out.print("</td></tr>");
		
		out.print("<td><img src='../i/spacer.gif' width='1' height='20' /></td>");

		out.print("<tr><td></td>");
		out.print("<td colspan='2' class='instruction' width='600'>");
		out.print("A valid password must be between 6 to 12 characters long with at least one alphabet and one numeric characters in it.</td></tr>");
		
		out.print("<tr><td></td>");
		out.print("<td class='headlnk_blue_13' width='200'><font color='#000000'>*</font> Password:</td>");
		out.print("<td><input type='password' name='newPass' class='formtext' size='20' value='" + pass + "'></td></tr>");
		
		out.print("<tr><td></td>");
		out.print("<td class='headlnk_blue_13' width='200'><font color='#000000'>*</font> Re-type password:</td>");
		out.print("<td><input type='password' name='rePass' class='formtext' size='20' value='" + pass + "'></td></tr>");
	}
	else
	{
		out.print("<tr><td></td>");
		out.print("<td class='headlnk_blue_13' width='200'>User account name:</td>");
		out.print("<td class='plaintext_big'>" + pstuser.getObjectName() + "</td></tr>");
	}

	// more user info
	// Time Zone
	int timeZone = userinfo.SERVER_TIME_ZONE;
	s = request.getParameter("TimeZone");
	if (s != null)
		timeZone = Integer.parseInt(s);
	if (isLogin)
		timeZone = ((Integer)ui.getAttribute("TimeZone")[0]).intValue();

	out.print("<tr><td><img src='../i/spacer.gif' height='8' width='1' /></td></tr>");

	out.print("<tr><td></td>");
	out.print("<td class='headlnk_blue_13'>Time Zone: </td>");
	out.print("<td class='formtext'>");
	out.print("<select name='TimeZone'>");
	for (int i=0; i<userinfo.TOTAL_TIMEZONE; i++)
	{
		String zoneStr = userinfo.getZoneString(i);		// auto adjust based on PST/DST
		if (zoneStr.length() <= 0)
			continue;
		int val = i + userinfo.SERVER_TIME_ZONE;
		out.println("<option value='" + val + "'");
		if (timeZone == val) out.print(" selected");
		out.print(">" + zoneStr + "</option>");
	}
	out.print("</select></td></tr>");
	
	// recaptcha
	if (!isLogin && isSecureHost)
	{
		out.print("<tr><td><img src='../i/spacer.gif' height='20' width='1' /></td></tr>");
		String pubK = Util.getPropKey("pst", "C_PUBLIC");
		String priK = Util.getPropKey("pst", "C_PRIVATE");

		ReCaptcha captcha = ReCaptchaFactory.newReCaptcha(pubK, priK, false);
		String captchaScript = captcha.createRecaptchaHtml(request.getParameter("error"), null);
		out.print("<tr><td></td><td colspan='2'>");
		out.print("<table><tr><td><img src='../i/spacer.gif' height='1' width='210' /></td><td>");
		out.print(captchaScript);
		out.print("</table></td></tr>");
	}
%>
		</table>
		</td>
	</tr>
	

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='20' /></td></tr>

<%	if (!isLogin)
	{
		// need to try create user before charging
%>	
		<tr>
			<td></td>
			<td id='button' class='plaintext_big' colspan="2">
				<img src='../i/spacer.gif' height='1' width='320' />
				<input type='button' value='CONTINUE' onclick='return validation()'>
			</td>
		</tr>
<%	}
	else
	{
		// the user is already login: get him to pay immediately
%>
		<tr><td></td>
			<td id='button' class='plaintext_big' colspan='2' align='center'>

			<img src="https://www.paypal.com/en_US/i/btn/btn_subscribeCC_LG.gif" border="0"
				alt="PayPal - The safer, easier way to pay online!"
				onclick='return validation();'>
		</td>
	</tr>
<%	} %>


</table>
</form>
<!-- ***** END ***** -->


	</td>
</tr>

<tr><td>&nbsp;</td><tr>


<!-- BEGIN FOOTER TABLE -->
<jsp:include page="/foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

