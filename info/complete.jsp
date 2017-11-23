<%
////////////////////////////////////////////////////
//	Copyright (c) 2008, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	complete.jsp
//	Author:	ECC
//	Date:	09/05/08
//	Description:
//		The callback page for payment gateway to return successful message.
//		Update membership level.
//
//	Modification:
//
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.net.*" %>
<%@ page import = "java.text.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "util.*" %>
<%@ page import = "org.apache.log4j.Logger" %>


<%@ taglib uri="/pmp-taglib" prefix="pmp" %>

<%
	Logger l = PrmLog.getLog();
	final String NODE = Prm.getPrmHost();
	final String FROM = Prm.getFromEmail();
	final String BCC = Util.getPropKey("pst", "BCC");
	final String MAILFILE = "alert.htm";

	// there must be a login user object by the time when complete.jsp is called
	PstUserAbstractObject pstuser = null;
	HttpSession sess = request.getSession(false);
	if (sess != null)
		pstuser = (PstUserAbstractObject)sess.getAttribute("pstuser");
	
	if (pstuser == null)
	{
		// something is wrong, don't serve the page
		response.sendRedirect(NODE + "/out.jsp?msg=1001");
		return;
	}
	String username = pstuser.getObjectName();

	//////////////////////////////////////////////////////////////////////////////////
	//read GET from PayPal system
	final String RESPOND_SUCCESS	= "SUCCESS";
	final String RESPOND_FAIL		= "FAIL";
	final String PAYPAL_SITE		= "https://www.paypal.com/cgi-bin/webscr";

	String authToken = "ragpR67RUL5OPA5dvAG74X4NhMIQhQMJU1LuZNlRUMPSAAxdYYmnq4kQKfu";
	String txToken = request.getParameter("tx");
	String query = "cmd=_notify-synch&tx=" + txToken + "&at=" + authToken;
	
	// post back to PayPal system to validate
	URL u = new URL(PAYPAL_SITE);
	URLConnection uc = u.openConnection();
	uc.setDoOutput(true);
	uc.setRequestProperty("Content-Type","application/x-www-form-urlencoded");
	PrintWriter pw = new PrintWriter(uc.getOutputStream());
	pw.println(query);			// POST it to PayPal
	pw.close();
	
	BufferedReader in = new BufferedReader(new InputStreamReader(uc.getInputStream()));
	String res = in.readLine();
	String [] sa;
	String key, val;
	String fName=null, lName=null, itemName=null, paymentAmount=null, paymentCurrency=null;
	if (res.trim().equals(RESPOND_SUCCESS))
	{
		while ((res = in.readLine()) != null)
		{
			// each following lines will be KEY = VALUE
			sa = res.trim().split("=");
			key = sa[0].trim();
			val = sa[1].trim();
			if (key.equals("first_name"))
				fName = val;
			else if (key.equals("last_name"))
				lName = val;
			else if (key.equals("item_name"))
				itemName = val;
			else if (key.equals("mc_gross"))
				paymentAmount = val;
			else if (key.equals("mc_currency"))
				paymentCurrency = val;
		}
	}
	else
	{
		// error processing: log for manual check
		l.error(res + ": Error exchanging info with PayPal for user [" + username + "]");
		response.sendRedirect(NODE+ "/out.jsp?msg=There is an issue with processing your payment, please contact EGI Support at <a href='mailto:support@egiomm.com'>support@egiomm.com</a>.");
		return;
	}
	in.close();


//////////////////////////////////////////////////////////////////////////////////////////////////


	boolean isLogin = false;
	String home = NODE + "/ep/ep_home.jsp";
	String app = Prm.getAppTitle();
	
	// get the userinfo object
	userManager uMgr = userManager.getInstance();
	userinfoManager uiMgr = userinfoManager.getInstance();
	PstAbstractObject ui = uiMgr.get(pstuser, String.valueOf(pstuser.getObjectId()));
	
	// handle upgrade
	String upgradeStatus = (String)sess.getAttribute("upgradeStatus");	// 1@Monthly, from post_account.jsp
	String spaceS = (String)sess.getAttribute("spaceS");
	String userS = (String)sess.getAttribute("userS");
	String projS = (String)sess.getAttribute("projS");
	String payment = (String)sess.getAttribute("payment");
	sess.removeAttribute("upgradeStatus");
	sess.removeAttribute("spaceS");
	sess.removeAttribute("userS");
	sess.removeAttribute("projS");
	sess.removeAttribute("payment");
	String levelS = null;
	
	int idx;
	String msg = "";

	if (upgradeStatus == null)
	{
		// this can't be unless the user is hacking the system to this page
		//levelS = (String)ui.getAttribute("Status")[0];		// 1@Monthly or 4@Yearly, etc.
		//msg = "Your membership is on the ";
		// access deny
		response.sendRedirect("../out.jsp?msg=1001&go=info/upgrade.jsp");
		return;
	}
	else
	{
		// the status is actually saved in the town object
		// in fact we don't care about the user object
		// get the town from the current user
		townManager tnMgr = townManager.getInstance();
		String townIdS = pstuser.getStringAttribute("TownID");
		town townObj = (town)tnMgr.get(pstuser, Integer.parseInt(townIdS));
		
		townObj.setLimit(town.MAX_PROJECT, projS);
		townObj.setLimit(town.MAX_USER, userS);
		townObj.setLimit(town.MAX_SPACE, spaceS);
		townObj.setLimit(town.SERVICE_LEVEL, upgradeStatus);	// 1, 2, or 1@Monthly, etc.
		tnMgr.commit(townObj);
		
		// save the new user status (no need)
		levelS = upgradeStatus;
		ui.setAttribute("Status", upgradeStatus);				// 1, 2, or 1@Monthly, etc.
		uiMgr.commit(ui);
		
		// update the total space
		if ((idx = spaceS.indexOf(" GB")) != -1)
		{
			spaceS = spaceS.substring(0, idx);		// just the number of "30 GB (...)"
			int iSpace = Integer.parseInt(spaceS) * 1000;
			pstuser.setAttribute("SpaceTotal", new Integer(iSpace));
			sess.setAttribute("pstuser", pstuser);
			uMgr.commit(pstuser);
		}
		msg = "You have successfully upgraded your membership to the ";
		
		l.info("Upgraded [" + username + "] to " + levelS + " with total space = " + spaceS + " GB");
	}
	
	// extra only the level info for display
	if ((idx = levelS.indexOf('@')) != -1)
		levelS = levelS.substring(0, idx);		// extract only the service level digit from 1@Monthly
		
	levelS = town.getLevelString(levelS);	// Basic, Team, etc.
	msg += levelS + " level with a total of " + spaceS + " GB space.";	// this is only for this Webpage display
	
	// send notification email to new user
	String subj = "[" + app + "] You new subscription to " + app;
	String msg1 = "Thank you for your subscription and upgrade of membership in " + app + " .<br>";
	msg1 += "<blockquote>";
	msg1 += "<table border='0' cellspacing='2' cellpadding='2'>";
	msg1 += "<tr><td class='plaintext' width='150'><b>Your username</b>:</td><td class='plaintext'>" + username + "</td></tr>";
	msg1 += "<tr><td class='plaintext' width='150'><b>Membership level</b>:</td><td class='plaintext'>" + levelS + "</td></tr>";
	msg1 += "<tr><td class='plaintext' width='150'><b>Remote storage</b>:</td><td class='plaintext'>" + spaceS + " GB</td></tr>";
	msg1 += "<tr><td class='plaintext' width='150'><b>Max # of projects</b>:</td><td class='plaintext'>" + projS + "</td></tr>";
	msg1 += "<tr><td class='plaintext' width='150'><b>Max # of users</b>:</td><td class='plaintext'>" + userS + "</td></tr>";
	msg1 += "<tr><td class='plaintext' width='150'><b>Payment</b>:</td><td class='plaintext'>" + payment + "</td></tr>";
	msg1 += "</table></blockquote><br><br>";
	msg1 += "Click the link below to access " + app + " now.<br>";
	msg1 += "<a href='" + NODE + "'>" + NODE + "</a><br><br>";
	msg1 += "If you have any questions, please contact " + app + " Support at <a href='mailto:support@egiomm.com'>";
	msg1 += "support@egiomm.com</a>";
	Util.sendMailAsyn(pstuser, FROM, username, null, BCC, subj, msg1, MAILFILE);

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
function goCR()
{
	location = "<%=home%>";
}

function download()
{
	location = "<%=NODE%>/info/download.jsp";
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
</style>

<!-- CONTENT -->

<table border='0'>
	
	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='30' /></td></tr>

	<tr>
		<td></td>
		<td>
			<table>
			<tr>
				<td><img src='../i/spacer.gif' width='20' height='1' /></td>
				<td class='headlnk_blue_13' width='600'><%=msg%></td>
			</tr>
			<tr><td><img src='../i/spacer.gif' height='5' width='1' /></td></tr>
			<tr>
				<td></td>
				<td class='headlnk_blue_13' width='600'>Please make sure to download CR Remote Access if you have not done so.  Thank you for using CR.</td>
			</tr>
			</table>
		</td>
	</tr>
	
	<tr><td colspan='2'><img src='../i/spacer.gif' width='1' height='30' /></td></tr>

	<tr>
		<td><img src='../i/spacer.gif' height='1' width='20' /></td>
		<td id='button' class='plaintext_big' align='center'>
			<input type='button' value='DOWNLOAD NOW' onclick='download();'>&nbsp;&nbsp;&nbsp;
			<input type='button' value='CONTINUE' onclick='goCR();'>
		</td>
	</tr>

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

