<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<%
////////////////////////////////////////////////////
//	Copyright (c) 2008, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	post_account.jsp
//	Author:	ECC
//	Date:	09/05/08
//	Description:
//		Creditcard processing.
//
//	Modification:
//
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.net.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "net.tanesha.recaptcha.*" %>
<%@ page import = "org.apache.log4j.Logger" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>

<%
	// for new user, create the account before asking to submitting credit card
	// for existing user, save the timezone value and auto redirect to PayPal
	final String NODE	= Prm.getPrmHost();
	final String PAYPAL_URL = "https://www.paypal.com/cgi-bin/webscr";
	//final String PAYPAL_URL = "https://www.sandbox.paypal.com/cgi-bin/webscr";
	Logger l = PrmLog.getLog();
	
	// create a user object as guest if I am not login yet
	String home = NODE + "/ep/ep_home.jsp";
	PstUserAbstractObject pstuser = null;
	HttpSession sess = request.getSession(false);
	if (sess != null)
		pstuser = (PstUserAbstractObject)sess.getAttribute("pstuser");
	else
		sess = request.getSession(true);
	if (pstuser == null) {
		try {
			home = NODE + "/index.jsp";
			sess = request.getSession(true);
			pstuser = (PstUserAbstractObject) PstGuest.getInstance();
			sess.setAttribute("pstuser", pstuser);
		} catch (PmpException e) {
			response.sendRedirect(NODE+ "/out.jsp?e=The requested page is temporarily unavailable, please try again later.");
			return;
		}
	}
	
	userManager uMgr = userManager.getInstance();
	userinfoManager uiMgr = userinfoManager.getInstance();
	user u = null;
	userinfo ui = null;

	String s;
	String msg = "";
	
	boolean isLogin = false;
	if (request.getParameter("login").equals("true"))
		isLogin = true;

	String email = request.getParameter("Email");
	String pass = request.getParameter("newPass");
	String levelS = request.getParameter("level");	// here levelS is userinfo.LEVEL_1, etc. which is Basic, etc.
	String spaceS = request.getParameter("space");
	
	// # of user
	String userLimitS = request.getParameter("userLmt");
	
	// # of project
	String projLimitS = request.getParameter("projLmt");
	if (projLimitS.equals("-1")) projLimitS = "Unlimited";

	String paymentS = request.getParameter("paymentType");
	String monthS = request.getParameter("monthCost");
	String yearS = request.getParameter("yearCost");

	String timeZoneS = request.getParameter("TimeZone");
	String payPalPrice = request.getParameter("payPalPrice");
	String payPalMethod = request.getParameter("payPalMethod");
	String costS = "US$ ";
	if (paymentS.equals(userinfo.PAYMT_MONTHLY))
		costS += monthS;
	else
		costS += yearS;
	
	String upgradeStatus = town.getLevelNum(levelS) + "@" + paymentS;		// 1@Monthly or 4@Yearly, etc.

%>
<form name='payment' action="<%=PAYPAL_URL%>" method="post">
<input type="hidden" name="cmd" value="_xclick-subscriptions">
<input type="hidden" name="business" value="edwardgem@gmail.com">
<input type="hidden" name="item_name" value="Collaborative Project Management - CPM (<%=levelS%>)">
<input type="hidden" name="no_shipping" value="1">
<input type="hidden" name="no_note" value="1">
<input type="hidden" name="currency_code" value="USD">
<input type="hidden" name="lc" value="US">
<input type="hidden" name="bn" value="PP-SubscriptionsBF">
<input type="hidden" name="a3" value="<%=payPalPrice%>">
<input type="hidden" name="p3" value="1">
<input type="hidden" name="t3" value="<%=payPalMethod%>">
<input type="hidden" name="src" value="1">
<input type="hidden" name="sra" value="1">
</form>

<form name='resubmit' method='post' action='account.jsp'>
<input type='hidden' name='Email' value='<%=email%>' >
<input type='hidden' name='newPass' value='<%=pass%>' >
<input type='hidden' name='msg' value="" >
<input type='hidden' name='level' value='<%=levelS%>' >
<input type='hidden' name='space' value='<%=spaceS%>' >
<input type='hidden' name='paymentType' value='<%=paymentS%>' >
<input type='hidden' name='monthCost' value='<%=monthS%>' >
<input type='hidden' name='yearCost' value='<%=yearS%>' >
<input type='hidden' name='TimeZone' value='<%=timeZoneS%>' >
</form>

<script language="JavaScript">
<!--
function need_resubmit(msgS)
{
	document.resubmit.msg.value = msgS;
	document.resubmit.submit();
	return;
}

function pay()
{
	var e = document.getElementById("button");
	if (e != null)
		e.innerHTML = "<b>Processing</b> ...";
	document.payment.submit();
	return;
}
//-->
</script>

<%
	if (!isLogin)
	{
		// recaptcha
		/*
		String pubK = Util.getPropKey("pst", "C_PUBLIC");
		String priK = Util.getPropKey("pst", "C_PRIVATE");
		ReCaptcha captcha = ReCaptchaFactory.newReCaptcha(pubK, priK, false);
		ReCaptchaResponse resp = captcha.checkAnswer(request.getRemoteAddr(), request.getParameter("recaptcha_challenge_field"), request.getParameter("recaptcha_response_field"));
		
		if (!resp.isValid())
		{
			response.sendRedirect("../out.jsp?msg=Error authenticating image text.  Please try again.&go=info/account.jsp");
			return;
		}
		*/
		
		// attempt to create the new user account		
		try
		{
			// attempt to create, might be duplicate and bomb out
			u = (user)uMgr.createUser(pstuser, email, pass);		// user and userinfo are created
		}
		catch (PmpException e)
		{
			// create failed: check to see if the user exist
			s = e.toString();
			if (s.indexOf("Duplicate") != -1)
			{
				msg = "! Error creating new user [" + email + "].  The Email is already in use.";
				l.error(msg);
				msg += " If you have forgotten your password, click <a href='" + NODE + "/ep/passwd_help.jsp'>&nbsp;<b>Forget Password</b></a>.";
%>
<script language="JavaScript">
	// go back to account.jsp
	need_resubmit("<%=msg%>");
</script>
<%
			}
			return;
		}
		
		String FirstName = request.getParameter("FirstName");
		if (FirstName==null || FirstName.length()<=0)
			FirstName = email.substring(0, email.indexOf('@'));
		String LastName = request.getParameter("LastName");
		if (LastName!=null && LastName.length()<=0)
			LastName = null;
		
		u.appendAttribute(user.TEAMMEMBERS, Integer.valueOf(u.getObjectId())); // Append myself to my Contact List
		u.setAttribute("FirstName", FirstName);
		u.setAttribute("LastName", LastName);
		u.setAttribute("Email", email);
		u.setAttribute("HireDate", new Date());		// ECC: use HireDate as CreatedDate
		u.setAttribute("SpaceTotal", new Integer(userinfo.DEFAULT_CR_SPACE));
		u.setAttribute("SpaceUsed", new Integer(0));
		uMgr.commit(u);
		
		// user the new user to login
		Util.login(sess, email, pass);
		
		// don't send notification email now, send it at complete.jsp
		
	}	// END if !isLogin
	else
	{
		// a login user, update the timezone
		u = (user) pstuser;
	}
	
	// update timezone
	ui = (userinfo)uiMgr.get(u, String.valueOf(u.getObjectId()));
	if (ui != null)
	{
		sess.setAttribute("upgradeStatus", upgradeStatus);		// 1@Monthly, save the upgrade status for complete.jsp
		sess.setAttribute("spaceS", spaceS);
		sess.setAttribute("userS", userLimitS);
		sess.setAttribute("projS", projLimitS);
		sess.setAttribute("payment", costS + " " + paymentS);
		ui.setAttribute("TimeZone", new Integer(timeZoneS));
		uiMgr.commit(ui);
	}
	
	// for login user, ready to redirect to payment now
	if (isLogin)
	{
%>
<script language="JavaScript">
		// for login user, no display on this page, just go pay
		pay();
</script>
<%		
	}
%>

<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="../init.jsp" flush="true"/>

<script language="JavaScript">
<!--

//-->
</script>

<title>
	CR Subscription
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

	&nbsp;&nbsp;<%=Prm.getAppTitle()%> Subscription

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
					<td><a href="<%=NODE%>/info/faq.jsp" class="subnav">FAQ</a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- Download -->
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="<%=NODE%>/info/download.jsp" class="subnav">Download</a></td>
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
				<td class='headlnk_green'>Your new CR user account has been created.  Please proceed to payment.</td>
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
				<td class='headlnk_blue_13' width='300'>Your login name:</td>
				<td class='headlnk_blue_13' width='200'><%=email%></td>
			</tr>
		
			<tr>
				<td><img src='../i/spacer.gif' width='30' height='1' /></td>
				<td class='headlnk_blue_13' width='300'>Level of service:</td>
				<td class='headlnk_blue_13' width='200'><%=levelS%></td>
			</tr>
		
			<tr>
				<td></td>
				<td class='headlnk_blue_13'>Total space:</td>
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
				<td class="headlnk_blue_13">Payment:</td>
				<td class="headlnk_blue_13"><%=costS %>&nbsp;<%=paymentS %></td>
			</tr>
			
			<tr><td><img src='../i/spacer.gif' width='1' height='5' /></td></tr>
			
		</table>
		</td>		
		</tr>
	</table>
	</td>
	</tr>
	
	<tr><td colspan='2'><img src='../i/spacer.gif' width='1' height='10' /></td></tr>

	<tr>
		<td><img src='../i/spacer.gif' width='50' height='1' /></td>
		<td>
			<table>
				<tr><td class='plaintext_big' width='550'>
					Please proceed to fulfill payment in order to complete the subscription of CR.
				</td></tr>

				<tr><td><img src='../i/spacer.gif' width='1' height='10' /></td></tr>

				<tr><td class='plaintext_big' width='550'>
					You will be redirected to PayPal and may fulfill your payment
					with either Credit Card or PayPal.
				</td></tr>
			</table>
		</td>
	</tr>
	
	<tr><td colspan='2'><img src='../i/spacer.gif' width='1' height='20' /></td></tr>

	<tr>
		<td><img src='../i/spacer.gif' width='50' height='1' /></td>
		<td id='button' class='plaintext_big' align='center'>
		<img src="https://www.paypal.com/en_US/i/btn/btn_subscribeCC_LG.gif" border="0"
				alt="PayPal - The safer, easier way to pay online!"
				onclick='pay();'>
		</td>
	</tr>
	
</table>

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

