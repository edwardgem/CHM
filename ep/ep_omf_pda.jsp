<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2010, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: ep_omf_pda.jsp
//	Author: ECC
//	Date:	07/05/10
//	Description: MeetWE home page for PDA.
//
/////////////////////////////////////////////////////////////////////
//

%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.omm.common.*" %>
<%@ page import = "oct.omm.client.*" %>
<%@ page import = "oct.omm.db.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "mod.mfchat.OmfEventAjax" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>

<%
	String noSession = "../index.jsp";	//"../out.jsp?go=ep/ep_omf.jsp";
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../index.jsp");
		return;
	}
	String browserType = request.getHeader("User-Agent").toLowerCase();
	boolean isPDA = (browserType.contains("android") || browserType.contains("mobile"));

	userManager uMgr = userManager.getInstance();

	String myUidS = request.getParameter("uid");
	int uidInt = 0;

	int iRole = ((Integer)session.getAttribute("role")).intValue();

	if ((myUidS == null) || (myUidS.equals("null")))
		myUidS = String.valueOf(pstuser.getObjectId());
	uidInt = Integer.parseInt(myUidS);

	user detailUser = (user)uMgr.get(pstuser, uidInt);

	String Title = (String)detailUser.getAttribute("Title")[0];
	String fName = (String)detailUser.getAttribute("FirstName")[0];
	String myFullName = detailUser.getFullName();


%>


<head>
<title>MeetWE Home</title>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta name="description" content="MeetWE is a social networking site for the enterprise" />
<meta name="keywords" content="social networking, chat, meeting" />
<script language="JavaScript" src="../get-date.js"></script>
<script language="JavaScript" src="../date.js"></script>
<script type="text/javascript" src="../meeting/ajax_utils.js"></script>
<script language="JavaScript" src="../meeting/mtg_expr.js"></script>
<script language="JavaScript" src="event.js"></script>
<script language="JavaScript" src="chat.js"></script>
<script src="201a.js" type="text/javascript"></script>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="../init.jsp" flush="true"/>
<script language="JavaScript">
<!--

// the followings are declared in event.js
var uid = "<%=myUidS%>";
var current_eid = -1;		// last received event Id
var act_hello = "<%=PrmEvent.ACT_HELLO%>";		// action() in event.js needs this
var diff = getDiffUTC();
var bDisplaySearch = false;
frame = "parent";			// define in event.js
myName = "<%=myFullName%>";

window.onload = function()
{
	ajax_init();
}

function resetAction()
{
	if (showingId != "")
	{
		var e = document.getElementById(showingId);
		if (e != null)
		{
			e.style.display = "none";
			e.innerHTML = "";
		}

		// make sure if a reply button (on posted note or join chat) has been hidden, make it seen now
		if (showingId.indexOf("-") != -1)
		{
			e = document.getElementById("reply-" + showingId);
			if (e == null)
				e = document.getElementById("chatReply-" + showingId);
			if (e != null) e.style.display = "block";
		}

		showingId = "";
	}
	rename_chat(null, 1);		// remove the rename chat box on screen
}

//-->
</script>

<%
	response.setHeader("Pragma", "No-Cache");
	response.setDateHeader("Expires", 0);
	response.setHeader("Cache-Control", "no-Cache");
%>

</head>

<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<bgsound id="IESound">
<span id="FFSound"></span>

<% if (isPDA) {%>
<style type="text/css">
.plaintext {font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 32px; color: #333333; line-height: 34px}
.plaintext_small {  font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 34px; font-weight:normal;color: #999999; line-height: 36px; padding-bottom:5px;}
.plaintext_grey {  font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 36px; color: #777777; line-height: 34px}
.plaintext_blue {  font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 32px; font-weight: bold; color: #336699; line-height: 36px}
.listlink { font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 34px; color: #3366aa; line-height: 32px; text-decoration: underline}
.bq_note { border:1px solid #ddd; margin: 5px; margin-right:12px; padding: 5px; padding-top:3px; background: #ffffbb; text-wrap:normal;word-wrap:break-word }
.comment {font-family: Verdana, Arial, Helvetica, sans-serif; width:98%; height:32px; font-size: 34px; color: #777777; padding-top:3px; line-height: 34px; overflow:hidden; }
.com_date, td#Events SPAN {color:#ff9933; font-size:30px;}
.head {  font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 40px; font-weight: bold; color: #55cc22; padding-top: 10px; padding-bottom: 10px; padding-right: 10px}
.listlinkbold { font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 36px; font-weight: bold; color: #3366aa; line-height: 16px; text-decoration: underline}
#evtPic {width:150px;margin-right:5px;}
#evtImg {width:40px;}
.online {font-size: 32px;}
.offline {font-size: 32px;}
</style>
<%}%>

<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">



<table border="0" cellspacing="0" cellpadding="0">
  <tr align="left" valign="top">
    <td>
      <table width="700" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td>
            <table width="700" border="0" cellspacing="0" cellpadding="0">
              <tr>
                <td width="26" height="30"><a name="top">&nbsp;</a></td>
                <td width="550" height="20" align="left" valign="bottom" class="head">
				Welcome, <%=fName%>
				</td>

              </tr>
            </table>
          </td>
        </tr>

		<tr><td>
			<table>
			<tr><td><img src='../i/spacer.gif' width='15'/></td>
				<td>
					<img src='../i/bullet_tri.gif' width='40' />
					<a class='listlinkbold' href='ep_omf.jsp?full=1'>MeetWE Home Page</a>
				</td>
				<td>
					<img src='../i/spacer.gif' width='50' height='1'/>
					<img src='../i/bullet_tri.gif' width='40' />
					<a class='listlinkbold' href='../meeting/cal.jsp'>Calendar</a>
				</td>
				<td id='debug' class='plaintext'></td>
			</tr>
			</table>
		</td></tr>

        <tr><td>&nbsp;</td></tr>

<%

	String bgcolor="";
	boolean even = false;
	boolean bBold;
	int [] ids = null;
	int id;

	/////////////////////////////////////////////////////////////

%>

	<tr><td>
	<table width='100%' border='0' cellspacing='0' cellpadding='0'>
		<tr>
		<td width='20' valign="top"><img src='../i/spacer.gif' width='20' /></td>

<!--  ****************************************************************************************************** -->

<!-- RIGHT PANEL -->
<td valign='top'>
		<table width='100%' border='0' cellspacing='0' cellpadding='0'>
		<tr>
		<td width='100%' valign="top">
		<!-- ***** List of News -->
			<table border='0' cellspacing='0' cellpadding='0' style='word-wrap:break-word;'>

<!--  ******************************   W H A T ' S   H A P P E N I N G  *************************************  -->

		<tr>
			<td width='100%' class="level2" colspan='4' bgcolor='#2280dd' style='color:#ffffff'>&nbsp;&nbsp;What's Happening ...</td>
		</tr>
			<tr><td colspan='4' bgcolor='#2060c0'><img src='../i/spacer.gif' height='3' /></td></tr>
		<tr>
			<td height="3" colspan='4'><img src="../i/spacer.gif" width="1" height="15" border="0"/></td>
	    </tr>

	    <tr><td colspan='4' id='Events' class='plaintext'>
			Gathering info ...
		</td></tr>

<!--  ******************************   E N D   W H A T ' S   H A P P E N I N G  ***************************  -->



			<tr><td colspan='4'><img src='../i/spacer.gif' height='15'></img></td></tr>
			</table>


</td>
<!-- END RIGHT PANEL -->

		</tr>
	</table>
	</td>
	</tr>
	</table>
	</td>
	</tr>


</table>
	</td>
</tr>

</table>
</bgsound>
<p>&nbsp;</p>

<jsp:include page="ep_expr.jsp" flush="true"/>

</body>
</html>
