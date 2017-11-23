<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2014, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: ep_chat.jsp
//	Author: ECC
//	Date:	02/23/14
//	Description: Chat-only page. The page is only for chat room purpose.
//					Also see chat.js, OmsChatAjax.java, OmfChatObject.java, etc.
//
//	Modification:
//
//	TODO:
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
	String op = request.getParameter("op");
	String showId = request.getParameter("showId");
	String cId = request.getParameter("chatId");
	String pId = request.getParameter("projId");
	String noSession = "../out.jsp?go=ep/ep_chat.jsp?op="+op+":showId="+showId+":chatId="+cId;
	System.out.println("op=" + op + ", sId=" + showId + ", cId=" + cId + ", pId=" + pId);
	int idx;
	if (showId!=null && (idx=showId.indexOf('-')) != -1) {
		showId = showId.substring(0, idx);
	}
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	final String PUBLIC_IND = "<span style='color:#00bb00; font-size:13px; font-weight:bold;'> *</span>";

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../index.jsp");
		return;
	}
	try {
		if (((user)pstuser).isCircleGuest()) {
			response.sendRedirect("../ep/my_page.jsp");
			return;
		}
	}
	catch (PmpException e) {
		response.sendRedirect("../out.jsp?e=time out");
		return;
	}

	String s;
	String appS = Prm.getAppTitle();
	int chatBoxWidth = 300;
	String winWidthPercent = "90%";

	// @ECC042309 get short profile
	String FirstName = (String)pstuser.getAttribute("FirstName")[0];
	String LastName  = (String)pstuser.getAttribute("LastName")[0];

	s = request.getParameter("full");
	String browserType = request.getHeader("User-Agent").toLowerCase();
	boolean isPDA = (browserType.contains("android") || browserType.contains("mobile"));
	if (s==null && isPDA) {
		chatBoxWidth = 700;
		winWidthPercent = "100%";
	}

	String backPage = "../ep/ep_chat.jsp";

	boolean isAdmin = false;
	boolean isDirector = false;
	boolean isProjAdmin = false;
	if (session.getAttribute("role") == null)
		session.setAttribute("role", new Integer(0));
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if (iRole > 0)
	{
		if ((iRole & user.iROLE_ADMIN) > 0)
			isAdmin = true;
		if ((iRole & user.iROLE_DIRECTOR) > 0)
			isDirector = true;
		if ((iRole & user.iROLE_ADD_PROJ) > 0)
			isProjAdmin = true;
	}
	
	int roleType = 0;		// default sub-menu
	if (isAdmin)
		roleType = 1;		// new user, new project, new company

	userManager uMgr = userManager.getInstance();
	eventManager evtMgr = eventManager.getInstance();
	chatManager cMgr = chatManager.getInstance();

	String myUidS = request.getParameter("uid");
	int myUid = 0;
	if ((myUidS == null) || (myUidS.equals("null")))
		myUidS = String.valueOf(pstuser.getObjectId());
	myUid = Integer.parseInt(myUidS);

	user detailUser = (user)uMgr.get(pstuser, myUid);

	Object [] townIds = pstuser.getAttribute("Towns");
	String townString = "";
	if (townIds!=null && townIds[0]!=null)
		for (int i=0; i<townIds.length; i++)
			townString += townIds[i].toString() + ";";

	// there might be a message about chat being moved to meeting
	String msg = request.getParameter("msg");
	if (msg != null) {
		// show message
	}
System.out.println("msg=" + msg);	

	boolean bShowChatList = true;
	s = request.getParameter("showChatList");
	if (s!=null && s.equals("false"))
		bShowChatList = false;

	// to check if session is CR, OMF, or PRM

	String sortby = (String) request.getParameter("sortby");

	String Title = (String)detailUser.getAttribute("Title")[0];
	String fName = (String)detailUser.getAttribute("FirstName")[0];
	String picFile = Util2.getPicURL(detailUser);
	String myFullName = detailUser.getFullName();

	// Events
	String evtS = (String)detailUser.getAttribute("Events")[0];
	String lastEid;
	if (evtS!=null && (idx=evtS.indexOf(";"))!=-1)
		lastEid = evtS.substring(0,idx);
	else
		lastEid = evtS;

%>


<head>
<title><%=appS%> Chat</title>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta name="description" content="CPM is a social networking site for innovation and achievement" />
<meta name="keywords" content="enterprise social networking, chat, meeting, conferencing" />
<script language="JavaScript" src="../get-date.js"></script>
<script language="JavaScript" src="../date.js"></script>
<script type="text/javascript" src="../meeting/ajax_utils.js"></script>
<script language="JavaScript" src="../meeting/mtg_expr.js"></script>
<script language="JavaScript" src="event.js"></script>
<script language="JavaScript" src="chat.js"></script>
<script src="201a.js" type="text/javascript"></script>
<script language="JavaScript" src="color_picker.js"></script>
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
isPDA = <%=isPDA%>;			// define in ajax_util.js

window.onload = function()
{
	if ("<%=msg%>" == "null")
		initChatWindow();
	ajax_init();
	if (<%=bShowChatList%> == false)
		toggle_chat_list("Hide");
	
	// might need to start/join chat with a person if coming from ep_db.jsp (dashboard)
	// refer to event.js action() to interpret the opcode
	var opcode = <%=op%>;
	var showingId = <%=showId%>;
	var chatId = <%=cId%>;
	var projId = <%=pId%>;

	switch (opcode)
	{
		case 4:
			start_chat(showingId, chatId);
			if (typeof chatId == "undefined")
				resetAction();
			break;
		case 5:
			join_chat(showingId);
			break;
		case 6:
			start_chat(null, chatId, showingId);	// the showingId is circleId under ep_circle.jsp, for response, use chatid
			resetAction();
			break;
		case 8:
			start_chat(null, chatId, "");	// just have a chatId
			resetAction();
			break;
		case 9:
			start_chat(null, null, null, projId);	// project chat
			resetAction();
			break;
		default:
			showChatNum = "default";	// change back to regular default
			ajaxCheckEvent("4");		// force a retrieval of 4 items
			break;
	}
}

function showStatus(st)
{
	var fn;
	var s;
	if (st=='Live') {fn = 'dot_red.gif'; s = 'On Air';}
	else if (st=='New') {fn = 'dot_green.gif'; s = 'New';}
	else if (st=='Finish') {fn = 'dot_blue.gif'; s = 'Finished'}
	else {fn = 'dot_black.gif'; s = 'Closed/Canceled';}
	document.write("<td valign='baseline' title='" + s + "'><img src='../i/" + fn + "' border='0'></td>");
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

function show_msg(msg)
{
	var e = document.getElementById('chatParent');
	e.style.display = "block";
	e.innerHTML = "<table width='100%' border='0' cellspacing='0'><tr>"
		+ "<td class='level2' align='left' bgcolor='#2280dd' style='color:#ffffff'>&nbsp;&nbsp;Chat Session</td>"
		+ "<td align='right' bgcolor='#2280dd'><a href='javascript:closeWin();'><font color='#dddddd'><b>Close</b></font></a>&nbsp;&nbsp;</td>"
		+ "</tr><tr><td colspan='2' bgcolor='#2060c0'><img src='../i/spacer.gif' height='1' /></td></tr>"
		+ "</table>"
		+ "<div align='left'>" + msg + "</div>"
		+ "<img src='../i/spacer.gif' height='10' />"
		+ "</div>";
}

function closeWin()
{
	var e = document.getElementById('chatParent');
	e.style.display = "none";
	initChatWindow();
}

function initChatWindow()
{
	var e = document.getElementById('chatParent');
	e.innerHTML =
		"<table width='100%' border='0' cellspacing='0'><tr bgcolor='#2280dd'>"
		+	"<td class='level2' align='left' width='200' style='color:#ffffff'>&nbsp;&nbsp;Chat Session</td>"
		+	"<td align='left' width='15'><img src='../i/sel.gif' border='0' onclick='chooseColor(1);' /></td>"
		+	"<td align='left' valign='baseline'>&nbsp;&nbsp;&nbsp;<img src='../i/pop.gif' border='0' onclick='popChat();' /></td>"
		+	"<td align='right'><a class='listlink' href='javascript:closeChat();'><font color='#dddddd'><b>Close</b></font></a>&nbsp;&nbsp;</td>"
		+   "</tr><tr><td colspan='4' bgcolor='#2060c0'><img src='../i/spacer.gif' height='1' /></td></tr>"
		+"</table>"
		+"<div id='chatName' class='plaintext_blue' style='padding-left:7px;' align='left'></div>"
		+"<div id='chatUser' class='plaintext' style='padding-left:7px; padding-bottom:3px;' align='left'></div>"
		+"<div id='selColor' class='plaintext' align='left' style='display:none'></div>"
		+"<div id='chat' style='height:300px; width:90%; border:1px solid #6699cc;' align='left'></div>"
		+"<img src='../i/spacer.gif' height='3' />"
		+"<div align='center'>"
		+"	<textarea class='plaintext' rows='3' style='padding:3px; overflow:auto; width:93%;' id='chatInput' onkeyup='return onEnterChatText(event);'></textarea>"
		+ " <input type='hidden' name='myColor' id='myColor' value=''>"
		+"</div>"
		+"<div align='right'>"
		+"	<img src='../i/bullet_tri.gif' width='15' />"
		+"	<a href='javascript:closeChat(true)' class='listlink'><b>Save chat as a Meeting Event&nbsp;</b></a>"
		+"</div>"
		+"<img src='../i/spacer.gif' height='10' />";
	e.style.display = "none";
}

function toggle_chat_list(op)
{
	var e = document.getElementById("chatListToggle");
	var ee = document.getElementById("chatList");
	var op;
	if (op == null)
		op = e.innerHTML;
	if (op.indexOf("Hide") != -1)
	{
		e.innerHTML = "<b>Show&nbsp;</b>";
		ee.style.display = "none";
	}
	else
	{
		e.innerHTML = "<b>Hide&nbsp;</b>";
		ee.style.display = "block";
	}
}

function checkKey(obj, evt, parentID)
{
	var mlength = obj.getAttribute? parseInt(obj.getAttribute("maxlength")) : "";
	if (obj.getAttribute && obj.value.length>mlength)
		obj.value=obj.value.substring(0,mlength);

	// note: this object can be in the event and I may not have it in the form

	var code = evt.keyCode? evt.keyCode : evt.charCode;
	if (code == 13)
	{
		// submit the entry
		var f = document.myThoughtForm;
		if (parentID != null) {
			// it is a comment, I need to pass the value in the textarea
			f.parentId.value = "" + parentID;
			f.content.value = obj.value;
		}
		f.entry.value = obj.getAttribute("id");
		f.action = "post_ep_home.jsp"
		f.submit();
	}
}

function saveDesc(id)
{
	// save button clicked on share file description
	var f = document.myThoughtForm;
	f.entry.value = "myThought_" + id;
	f.action = "post_ep_home.jsp"
	f.submit();
}

var popChatWin = null;
function popChat()
{
	var popChatId = chatObjIdS;		// remember before closing
	closeChat();
	if (popChatWin != null && !popChatWin.closed)
		popChatWin.close();

	var h = 440, w = 330,
		l = window.screen.width - w - 30,
		t = window.screen.height - h - 60;
	popChatWin = window.open('pop_chat.jsp?chatId=' + popChatId, '',
			'scrollbars=no,menubar=no,' +
			'left=' + l + ',top=' + t + ',' +
			'height=' + h + ',width=' + w + ',' +
			'resizable=yes,toolbar=no,location=no,status=no');

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
<div id="colorpicker201" class="colorpicker201"></div>

<style type="text/css">
.comment {font-family: Verdana, Arial, Helvetica, sans-serif; width:98%; height:40px; font-size: 11px; color:#777777; padding-top:3px; line-height: 16px; overflow:hidden; }
.desc {font-family: Verdana, Arial, Helvetica, sans-serif; width:98%; height:50px; font-size: 11px; color:#777777; padding-top:3px; line-height: 16px; overflow:hidden; }
.response {background:#ffffbb; padding:5px}


<% if (isPDA) {%>
.plaintext {font-size: 30px; color: #333333; line-height: 40px}
.plaintext_small {font-size: 28px; font-weight:normal;color: #999999; line-height: 40px; padding-bottom:5px; padding-left:50px;}
.plaintext_grey {font-size: 28px; color: #777777; line-height: 34px}
.plaintext_blue { font-size: 34px; font-weight: bold; color: #336699; line-height: 40px}
.listlink { font-size: 28px; color: #3366aa; line-height: 40px; text-decoration: underline}
.comment {width:98%; height:32px; font-size: 34px; color: #777777; padding-top:3px; line-height: 34px; overflow:hidden; }
.com_date, td#Events SPAN {color:#ff9933; font-size:25px;padding-bottom:10px;}
.head {font-size: 42px; font-weight: bold; color: #55cc22; padding-top: 10px; padding-bottom: 20px; padding-right: 10px}
.listlinkbold {font-size: 36px; line-height: 16px;}
#evtPic {width:150px;margin-right:5px;}
#evtImg {width:40px;}
.online {font-size: 32px;}
.offline {font-size: 32px;}
.level2 {font-size:28px; line-height: 40px}
div#chat {font-size: 20px; line-height: 30px}
<%}%>

</style>

<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">

<% if (!isPDA) { %>
	<table width="100%" border="0" cellspacing="0" cellpadding="0">
  		<tr align="left" valign="top">
    	<td width="100%">
		<jsp:include page="../head.jsp" flush="true"/></td></tr>
	</table>
<% } %>

<table width='<%=winWidthPercent%>' border="0" cellspacing="0" cellpadding="0">
  <tr align="left" valign="top">
    <td>
      <table width="100%" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td>
            <table width="100%" border="0" cellspacing="0" cellpadding="0">
              <tr>
                <td width="26" height="30"><a name="top">&nbsp;</a></td>
                <td width="554" height="20" align="left" valign="bottom" class="head">
				Welcome, <%=fName%>
				</td>
                <td colspan='2'><span id='debugMsg'></span></td>

<%
	if (isPDA) {
		out.print("<td width='300'>");
		out.print("<a class='listlinkbold' href='ep_prm_pda.jsp'>Home</a></td>");
	}
%>
              </tr>

            </table>
          </td>
        </tr>
        
<% if (!isPDA) {%>        
        <tr>
          <td width="100%">
<!-- TAB -->
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Home" />
				<jsp:param name="subCat" value="ChatRoom" />
				<jsp:param name="role" value="<%=iRole%>" />
			</jsp:include>
			</td>
		</tr>
<% } %>

        <tr><td>&nbsp;</td></tr>

<%

	String bgcolor="";
	boolean even = false;
	boolean bBold;
	int [] ids = null;
	int id;

	/////////////////////////////////////////////////////////////

	// @SWS082106
%>

	<tr><td>
	<table border='0' cellspacing='0' cellpadding='0'>
		<tr>
		<td width='20' valign="top"><img src='../i/spacer.gif' width='20' /></td>

		<td><img src='../i/spacer.gif' width='20' /></td>

<!--  ****************************************************************************************************** -->
<!-- CENTER PANEL -->
		<td width='<%=chatBoxWidth%>' valign="top" align='left'>

<!-- ***** List of Chats ***** -->
		<table width='100%' border='0' cellspacing='0' cellpadding='0'>
			<tr>
				<td class='level2' bgcolor='#bbbbbb' style='color:#ffffff'>&nbsp;&nbsp;My Chats</td>
				<td bgcolor='#bbbbbb' align='right'><a id='chatListToggle' href='javascript:toggle_chat_list();' class='listlink'><b>Hide</b></a>&nbsp;</td>
			</tr>
			<tr><td colspan='2' bgcolor='#aaaaaa'><img src='../i/spacer.gif' height='3' /></td></tr>
			<tr><td colspan='2'><img src='../i/spacer.gif' height='3' /></td></tr>
			<tr><td colspan='2'>
			<div id='chatList' class='chatText' style='display:block'>

			</div>
			</td></tr>

			<tr><td height="3" colspan='2'><img src="../i/spacer.gif" width="1" height="20"/></td></tr>
		</table>




<!-- Chat Window -->
	<div id='chatParent' style='display:none;' align='center'>
	</div>

<!-- Message to be displayed -->
<%	if (msg != null)
	{%>
<script language="JavaScript">
<!--
		show_msg("<%=msg%>");
//-->
</script>
<%	} %>

</td></tr>

		</table>
</td>
<!-- END CENTER PANEL -->

		<td><img src='../i/spacer.gif' width='20'/></td>


			<tr><td colspan='4'><img src='../i/spacer.gif' height='15'></img></td></tr>
			</table>


		</tr>
	</table>
	</td>
	</tr>
	</table>
	</tr>

</table>
	</td>
</tr>

</table>
<p>&nbsp;</p>

<jsp:include page="ep_expr.jsp" flush="true"/>

</body>
</html>
