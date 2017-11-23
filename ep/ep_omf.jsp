<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2005, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: ep_home.jsp
//	Author: ECC
//	Date:	07/05/05
//	Description: PRM home page.  This is customized for MeetWE only.
//				 See also OmfEventAjax.java.
//
//	Modification:
//		@081403ECC	Add PRM and SBM configurable option
//		@102104ECC	Added watcher feature.
//		@110705ECC	Add option to link a Phase or Sub-phase to Task.
//		@041906SWS	Added sort function to Project names.
//		@AGQ051806	Changed from reading project's phase to phase object
//		@SWS082106  Added new look for OMF: list of meetings only.
//		@ECC102507	Display events.
//
//	TODO:
//		- process comments by friends, display in group
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
	String noSession = "../out.jsp?go=ep/ep_omf.jsp";
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

	// @ECC042309 get short profile
	String FirstName = (String)pstuser.getAttribute("FirstName")[0];
	String LastName  = (String)pstuser.getAttribute("LastName")[0];
	if (FirstName==null || LastName==null || FirstName.length()<=0 || LastName.length()<=0)
	{
		response.sendRedirect("profiling.jsp");
		return;
	}

	s = request.getParameter("full");
	String browserType = request.getHeader("User-Agent").toLowerCase();
	boolean isPDA = (browserType.contains("android") || browserType.contains("mobile"));
	if (s==null && isPDA) {
		response.sendRedirect("ep_omf_pda.jsp");
		return;
	}

	String backPage = "../ep/ep_omf.jsp";

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
	meetingManager mtgMgr = meetingManager.getInstance();
	eventManager evtMgr = eventManager.getInstance();
	chatManager cMgr = chatManager.getInstance();
	resultManager rMgr = resultManager.getInstance();
	userinfoManager uiMgr = userinfoManager.getInstance();

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
	if (msg != null)
	{
		msg = "<font color='#00bb00'>" + msg + "</font>";
		s = request.getParameter("mid");
		if (s != null)
		{
			PstAbstractObject o = mtgMgr.get(pstuser, s);
			if (o != null)
			{
				// display the meeting info (subject and date/time) and link
				StringBuffer sBuf = new StringBuffer(512);
				userinfo myUI = (userinfo) uiMgr.get(pstuser, myUidS);
				TimeZone tZone = myUI.getTimeZone();
				try {Util2.displayMeetingLink(pstuser, o, sBuf);}	// tZone
				catch (PmpException e) {}
				if (sBuf.length() > 0)
					msg += sBuf.toString();
			}
		}
	}

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
	int idx;
	String evtS = (String)detailUser.getAttribute("Events")[0];
	String lastEid;
	if (evtS!=null && (idx=evtS.indexOf(";"))!=-1)
		lastEid = evtS.substring(0,idx);
	else
		lastEid = evtS;

	Date now = Calendar.getInstance().getTime();
	SimpleDateFormat df1 = new SimpleDateFormat ("yyyy.MM.dd.hh.mm");
	SimpleDateFormat df2 = new SimpleDateFormat ("MM/dd/yy (EEE)");
	SimpleDateFormat df3 = new SimpleDateFormat ("MM/dd/yyyy hh:mm a");
	SimpleDateFormat df4 = new SimpleDateFormat ("MM dd yyyy hh mm");
	SimpleDateFormat df5 = new SimpleDateFormat ("h:mm a");
	SimpleDateFormat df6 = new SimpleDateFormat ("MM/dd (EEE) h:mm");
	
	// localize timezone
	
	userinfo myUI = (userinfo) uiMgr.get(pstuser, String.valueOf(myUid));
	TimeZone myTimeZone = myUI.getTimeZone();
	if (!userinfo.isServerTimeZone(myTimeZone)) {
		df1.setTimeZone(myTimeZone);
		df2.setTimeZone(myTimeZone);
		df3.setTimeZone(myTimeZone);
		df4.setTimeZone(myTimeZone);
		df5.setTimeZone(myTimeZone);
		df6.setTimeZone(myTimeZone);
	}
	
	// Workflow related pending list and status list

	// thought question
	Random random = new Random(new Date().getTime());
	int thoughtId = random.nextInt(PrmEvent.THOUGHT_QUESTION.length);		// one of the thoughts
	String question = PrmEvent.THOUGHT_QUESTION[thoughtId];
	
	//PrmEvent.setUpThoughtQuestions(pstuser);

%>


<head>
<title>MeetWE Home</title>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
<meta name="description" content="MeetWE is a social networking site for the enterprise" />
<meta name="keywords" content="enterprise social networking, chat, meeting, conferencing" />
<script language="JavaScript" src="../get-date.js"></script>
<script language="JavaScript" src="../date.js"></script>
<script type="text/javascript" src="../meeting/ajax_utils.js"></script>
<script language="JavaScript" src="../meeting/mtg_expr.js"></script>
<script language="JavaScript" src="event.js"></script>
<script language="JavaScript" src="chat.js"></script>
<script src="201a.js" type="text/javascript"></script>
<script language="JavaScript" src="color_picker.js"></script>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
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
	if ("<%=msg%>" == "null")
		initChatWindow();
	ajax_init();
	if (<%=bShowChatList%> == false)
		toggle_chat_list("Hide");
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
		+ "<div class='plaintext' align='left'>" + msg + "</div>"
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
		+	"<td class='level2' align='left' width='100' style='color:#ffffff'>&nbsp;&nbsp;Chat Session</td>"
		+	"<td align='left' width='15'><img src='../i/sel.gif' border='0' onclick='chooseColor(1);' /></td>"
		+	"<td align='left' valign='baseline'>&nbsp;&nbsp;&nbsp;<img src='../i/pop.gif' border='0' onclick='popChat();' /></td>"
		+	"<td align='right'><a class='listlink' href='javascript:closeChat();'><font color='#dddddd'><b>Close</b></font></a>&nbsp;&nbsp;</td>"
		+   "</tr><tr><td colspan='4' bgcolor='#2060c0'><img src='../i/spacer.gif' height='1' /></td></tr>"
		+"</table>"
		+"<div id='chatUser' class='plaintext' align='left'></div>"
		+"<div id='selColor' class='plaintext' align='left' style='display:none'></div>"
		+"<div id='chat' style='height:300px; width:90%; border:1px solid #6699cc;' align='left'></div>"
		+"<img src='../i/spacer.gif' height='3' />"
		+"<div align='center'>"
		+"	<textarea rows='2' style='padding:3px; overflow:auto; width:94%;' id='chatInput' onkeyup='return onEnterChatText(event);'></textarea>"
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

function enterDesc(type, id)
{
	// the textarea was onfocus
	var idS="", defStr="";
	if (type == 0)
	{
		idS = "myThought_" + id;
		defStr = "<%=question%>";
	}
	else
	{
		idS = id;
		defStr = "<%=PrmEvent.DEFAULT_COMMENT_STR%>";
	}
	var e = document.getElementById(idS);
	if (e.value == defStr)
	{
		e.style.color = '#222222';	// darker color
		e.value = "";
	}
	e.focus();
}

function leftDesc(type, id)
{
	var idS="", defStr="";
	if (type == 0)
	{
		idS = "myThought_" + id;
		defStr = "<%=question%>";
	}
	else
	{
		idS = id;
		defStr = "<%=PrmEvent.DEFAULT_COMMENT_STR%>";
	}
	var e = document.getElementById(idS);
	var str = trim(e.value);
	e.value = str;
	if (str == "")
	{
		e.style.color = '#777777';
		e.value = defStr;
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
		l = window.screen.width - w,
		t = window.screen.height - h;
	popChatWin = window.open('pop_chat.jsp?chatId=' + popChatId, '',
			'scrollbars=no,menubar=no,' +
			'left=' + l + ',top=' + t + ',' +
			'height=' + h + ',width=' + w + ',' +
			'resizable=yes,toolbar=no,location=no,status=no');

}

// transfer Java array to Javascript array
var ct=0;
var Q = new Array();
<% for (String ele : PrmEvent.THOUGHT_QUESTION) { %>
		Q[ct++] = "<%= ele %>"; 
<% } %>


function changeQuestion(id)
{
	var idx = Math.floor(Math.random() * (Q.length - 0) + 0);
	var e = document.getElementById("myThought_" + id);
	e.value = Q[idx];
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
</style>

<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">

	<table width="100%" border="0" cellspacing="0" cellpadding="0">
  		<tr align="left" valign="top">
    	<td width="100%">
		<jsp:include page="../head.jsp" flush="true"/></td></tr>
	</table>


<table width='90%' border="0" cellspacing="0" cellpadding="0">
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

<%
	if (isPDA) {
		out.print("<td width='200'><img src='../i/bullet_tri.gif' width='20' height='10' />");
		out.print("<a class='listlinkbold' href='ep_omf_pda.jsp'>Goto PDA Page</a></td>");
	}
%>

              </tr>

            </table>
          </td>
        </tr>
        <tr>
          <td width="100%">
<!-- TAB -->
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Home" />
				<jsp:param name="subCat" value="Home" />
				<jsp:param name="role" value="<%=iRole%>" />
				<jsp:param name="roleType" value="<%=roleType%>" />
			</jsp:include>
			</td>
		</tr>

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
	<table width='100%' border='0' cellspacing='0' cellpadding='0'>
		<tr>
		<td width='20' valign="top"><img src='../i/spacer.gif' width='20' /></td>

<!--  ****************************************************************************************************** -->
<!-- LEFT PANEL -->
		<td id='childFrame' width='32%' style="height:100px;" valign="top">

		<!-- ***** List of Circles -->

			<iframe id='child' src='ep_circles.jsp' style='position:relative; z-index:0;' frameborder='0' width='100%' height='100%' scrolling='no'>Problem</iframe>

		</td>

<!-- END LEFT PANEL -->

		<td><img src='../i/spacer.gif' width='20' /></td>

<!--  ****************************************************************************************************** -->
<!-- CENTER PANEL -->
		<td width='30%' valign="top" align='left'>

<%
	// **** Enter personal thoughts/feelings
	out.println("<form name='myThoughtForm' method='post' action=''>");
	out.print("<input type='hidden' name='entry' value=''>");		// for adding my thought or comment
	out.print("<input type='hidden' name='parentId' value=''>");	// comment on parent thought
	out.print("<input type='hidden' name='content' value=''>");
	out.print("<table width='100%' border='0' cellspacing='0' cellpadding='0'>");

	out.print("<tr><td>");
	out.print("<table width='100%' border='0' cellspacing='0' cellpadding='0'><tr bgcolor='#2280dd'>");
	out.print("<td class='level2' style='color:#ffffff'>&nbsp;&nbsp;My Thoughts</td>");
	out.print("<td align='right'></td>");
	out.print("</tr></table>");
	out.print("</td></tr>");
	out.print("<tr><td bgcolor='#2060c0'><img src='../i/spacer.gif' height='3' /></td></tr>");
	out.print("<tr><td><img src='../i/spacer.gif' width='1' height='5'></td></tr>");

	// add a new thought
	out.print("<tr><td><table width='100%' cellpadding='5' cellspacing='0'><tr>");
	out.print("<td width='100%' bgcolor='#ffffbb'>");
	out.print("<table width='100%' cellpadding='0' cellspacing='0'>");
	out.print("<tr><td><textarea id='myThought_" + thoughtId + "' name='myThought_" + thoughtId + "' "
			+ "onFocus='enterDesc(0, " + thoughtId + ");' onBlur='leftDesc(0, " + thoughtId + ");' "
			+ "onKeyUp='checkKey(this, event);' class='comment' cols='35' rows='2' maxlength='250'>");
	out.print(question + "</textarea></td></tr>");
	out.print("<tr><td><table width='100%' cellpadding='0' cellspacing='0'><tr>");
	out.print("<td><a href='javascript:changeQuestion(" + thoughtId + ");'><img src='../i/refresh.png' width='25'/></a></td>");
	out.print("<td align='right'><a href='javascript:saveDesc(" + thoughtId + ");'><b>Save</b></a></td>");
	out.print("</tr></table></td></tr>");
	out.print("</table>");
	out.print("</table></td></tr>");

	out.print("<tr><td><img src='../i/spacer.gif' height='10' width='1'/></td></tr>");


	// list thoughts and people's comment to it
	// list the top one and then people's comment up to 5
	// use the ProjectID to store question #
	String author, commentS, timeS, picURL, lnkS;
	user uObj;
	// ProjectID is the idx of the kind of thoughts you wrote
	int [] ids1 = rMgr.findId(pstuser,
			"TaskID='" + myUidS + "' && Type='" + result.TYPE_ENGR_BLOG + "' && ProjectID='%'");
	int ct = 0;
	
	Arrays.sort(ids1);	// the return of ids1 might not be sorted

	// display the last thought you entered, along with people's comment to it
	int qid = -1;
	String qest = null;
	if (ids1.length > 0)
	{
		// first display my own thought
		int rId = ids1[ids1.length-1];		// only display last thought
		PstAbstractObject myThought = rMgr.get(pstuser, rId);
		qest = myThought.getStringAttribute("Alert");
		if (StringUtil.isNullOrEmptyString(qest)) {
			s = myThought.getStringAttribute("ProjectID");
			if (s != null)
				qid = Integer.parseInt(s);
			if (qid >= PrmEvent.THOUGHT_QUESTION.length) qid = -1;
			if (qid != -1)
				qest = PrmEvent.THOUGHT_QUESTION[qid];
		}
		Object bTextObj = myThought.getAttribute("Comment")[0];
		commentS = (bTextObj==null) ? "" : new String((byte[])bTextObj);
		
		// note background (of me)
		String style = Util2.getUserNoteBkgd(pstuser);

		if (qest != null) {
			out.print("<tr><td class='plaintext_blue'>" + qest + "</td></tr>");
		}
		out.print("<tr><td class='plaintext_big'>You said ...</td></tr>");
		out.print("<tr><td><img src='../i/spacer.gif' height='5'/></td></tr>");
		out.print("<tr class='response'><td width='100%' class='plaintext'");
		out.print(style);
		out.print(">&nbsp;&nbsp;&nbsp;" + commentS + "</td></tr>");
		out.print("<tr><td><img src='../i/spacer.gif' height='10' width='1'/></td></tr>");

		// second: list my friends' comment if any
		out.print("<tr><td><table width='100%' cellpadding='0' cellspacing='0'>");
		ids1 = rMgr.findId(pstuser, "ParentID='" + rId + "'");
		for (int j=ids1.length-1; j>=0; j--)
		{
			if (++ct > 10)
				break;					// at most show 10 comments (should delete the others)
			out.print("<tr><td width='100%' bgcolor='#ffffbb'><table width='100%' cellspacing='0' cellpadding='3'>");
			if (ct>3)
			{
				out.print("<tr><td class='plaintext'><a href='javascript:showAllComment();'>Show more comments ...</a></td></tr>");
				out.print("</table></td></table></td></tr>");
				out.print("<tr><td><img src='../i/spacer.gif' height='2' /></td></tr>");
				break;
			}
			try
			{
				PstAbstractObject o = rMgr.get(pstuser, ids1[j]);
				bTextObj = o.getAttribute("Comment")[0];
				if (bTextObj == null) continue;
				commentS = new String((byte[])bTextObj);
				s = (String)o.getAttribute("Creator")[0];
				uObj = (user)uMgr.get(pstuser, Integer.parseInt(s));
				lnkS = "<a href='ep1.jsp?uid=" + s + "'>";
				author = lnkS + (String)uObj.getFullName() + "</a>";
				timeS = " at " + df5.format((Date)o.getAttribute("CreatedDate")[0]);
				picURL = Util2.getPicURL(uObj);
			}
			catch (Exception e) {continue;}
			out.print("<tr><td width='40'>" + lnkS + "<img src='" + picURL + "' width='40' border='0'/></a></td>");
			out.print("<td><img src='../i/spacer.gif' width='2'/></td>");
			out.print("<td valign='top'><table>");
			out.print("<tr><td class='plaintext_small'>" + author + timeS + "</td></tr>");
			out.print("<tr><td class='plaintext'>" + commentS + "</td></tr>");
			out.print("</table></td></tr></table></td></tr>");

			out.print("<tr><td><img src='../i/spacer.gif' height='2' /></td></tr>");
		}	// END: for loop of all people's comments on my thought

		out.print("</table></td></tr>");
		out.print("<tr><td><img src='../i/spacer.gif' height='5'/></td></tr>");
	}	// END if: I have at least one thought

	out.print("</table>");	// close table of my thoughts
%>

<!-- ***** List of Chats ***** -->
		<table width='100%' border='0' cellspacing='0' cellpadding='0'>
			<tr>
				<td class='level2' bgcolor='#bbbbbb' style='color:#ffffff'>&nbsp;&nbsp;My Chats</td>
				<td bgcolor='#bbbbbb' align='right'><a id='chatListToggle' href='javascript:toggle_chat_list();' class='listlink'><b>Hide</b></a>&nbsp;</td>
			</tr>
			<tr><td colspan='2' bgcolor='#aaaaaa'><img src='../i/spacer.gif' height='3' /></td></tr>
			<tr><td colspan='2'><img src='../i/spacer.gif' height='3' /></td></tr>
			<tr><td colspan='2'>
			<div id='chatList' style='display:block'>

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

<!-- ***** List of Meetings -->

<%
///////////// CENTER COLUMN ///////////////////

Calendar ca = Calendar.getInstance();
	now = ca.getTime();
	now = new Date(now.getTime());
	String [] sa = df4.format(now).split(" ");
	sa[3] = "00";
	sa[4] = "00";
	s = "";
	for (int i = 0; i<sa.length; i++)
	{
		s = s.concat(sa[i]);
		s = s.concat(" ");
	}
	now = df4.parse(s);
	now = new Date(now.getTime() + 7*3600000);

	long temp = now.getTime();
	Long day = new Long(86400000);
	long temp2 = day.longValue();
	temp = temp + temp2;
	Date tomorrow = new Date(temp);

	temp = temp + temp2;
	Date nextD = new Date(temp);

	//String expr = "Type='Private' && (StartDate>='" + df1.format(now)+ "') && (StartDate<'" + df1.format(tomorrow) + "')";
	// @ECC102607 Change to list both public and private meetings in this section
	String expr = "(StartDate>='" + df1.format(now)+ "') && (StartDate<'" + df1.format(tomorrow) + "')";
	int [] mIds1 = mtgMgr.findId(pstuser, expr);
	int count = 0;
	PstAbstractObject [] mtgArr = mtgMgr.get(pstuser, mIds1);
	int len = mtgArr.length;
	if (len > 1)
		Util.sortDate(mtgArr, "StartDate");

	boolean found;
	PstAbstractObject m;
	for (int i=0; i<mtgArr.length; i++)
	{
		found = false;
		m = mtgArr[i];

		if (m.getAttribute("Type")[0].equals(meeting.PUBLIC))
			{count++; continue;}		// include public meeting

		if (myUidS.equals(m.getAttribute("Owner")))
			{count++; continue;}		// found

		s = (String)m.getAttribute("TownID")[0];
		if (s!=null && townString.indexOf(s)!=-1)
			{count++; continue;}		// found same town

		Object [] oArr = m.getAttribute("Attendee");
		for (int j=0; j<oArr.length; j++)
		{
			s = (String)oArr[j];
			if (s == null) break;		// no attendee
			if (s.startsWith(myUidS))
			{
				found = true;
				count++;
				break;					// found
			}
		}
		if (!found)
			mtgArr[i] = null;			// don't show this meeting
	}

%>
		<table width='100%' border='0' cellspacing='0' cellpadding='0'>
			<tr>
				<td colspan='4'>
					<table width='100%' border='0' cellspacing='0' cellpadding='0'><tr bgcolor='#2280dd'>
					<td class="level2" style='color:#ffffff'>&nbsp;&nbsp;My Meetings</td>
					<td align='right'><a href='../meeting/cal.jsp' class='listlink' style='color:#ffffff'}><b>Calendar</b></a>&nbsp;</td>
					</tr></table>
				</td>
			</tr>
			<tr><td colspan='4' bgcolor='#2060c0'><img src='../i/spacer.gif' height='3' /></td></tr>
			<tr><td height="3" colspan='4'><img src="../i/spacer.gif" width="1" height="15"/></td></tr>
			<tr>
				<td class="plaintext_blue" colspan='4'>Today</td>
			</tr>
			<tr><td height="3" colspan='4'><img src="../i/spacer.gif" width="1" height="3"/></td></tr>
<%

	String typeInd, start, end, subj;
	String mtgState = null;
	Date startD, endD;
	if (count != 0)
	{
		for (int i=0; i<mtgArr.length; i++)
		{
			m = mtgArr[i];
			if (m != null)
			{
				startD = (Date)m.getAttribute("StartDate")[0];
				start = df6.format(startD);
				endD = (Date)m.getAttribute("ExpireDate")[0];
				end = df5.format(endD);
				id = m.getObjectId();
				subj = (String)m.getAttribute("Subject")[0];
				if (m.getAttribute("Type")[0].equals(meeting.PUBLIC))
					typeInd = PUBLIC_IND;
				else
					typeInd = "";
				mtgState = (String)m.getAttribute("Status")[0];
				out.println("<tr><td width='2'>&nbsp;</td>");
				out.print("<td class='plaintext' valign='top' colspan='3'>");
				out.print(start + " - " + end);

				out.print("</td></tr>");
				out.print("<tr><td width='5'></td>");
				out.print("<td><img src='../i/spacer.gif' width='10'></td>");
				%><script language="JavaScript">showStatus('<%=mtgState%>');</script><%
				out.print("<td width='100%' valign='middle'><a class='listlink' href='../meeting/mtg_view.jsp?mid=" + id + "'>" + subj + "</a>" + typeInd + "</td></tr>");
				out.print("<tr><td colspan='4'><img src='../i/spacer.gif' width='1' height='5' border='0'></td></tr>");
			}
		}
	}
	else
	{
		out.println("<tr><td><img src='../i/spacer.gif' width='5' height='2'></td>");
		out.println("<td class='plaintext_grey' valign='top' colspan='3'>&nbsp;None</td></tr>");
	}
%>
			<tr>
				<td height="5" colspan='4'><img src="../i/spacer.gif" width="1" height="5" border="0"></td>
		    </tr>
			<tr>
				<td class="plaintext_blue" colspan='4'>Tomorrow</td>
			</tr>
			<tr>
			<td height="3" colspan='4'><img src="../i/spacer.gif" width="1" height="3" border="0"></td>
	    </tr>
<%
	expr = "(StartDate>='" + df1.format(tomorrow)+ "') && (StartDate<'" + df1.format(nextD) + "')";
	int [] mIds2 = mtgMgr.findId(pstuser, expr);
	count = 0;

	mtgArr = mtgMgr.get(pstuser, mIds2);
	len = mtgArr.length;
	if (len > 1)
		Util.sortDate(mtgArr, "StartDate");

	for (int i=0; i<mtgArr.length; i++)
	{
		found = false;
		m = mtgArr[i];

		if (m.getAttribute("Type")[0].equals(meeting.PUBLIC))
			{count++; continue;}		// include public meeting

		if (myUidS.equals(m.getAttribute("Owner")))
			{count++; continue;}		// found

		s = (String)m.getAttribute("TownID")[0];
		if (s!=null && townString.indexOf(s)!=-1)
			{count++; continue;}		// found same town

		Object [] oArr = m.getAttribute("Attendee");
		for (int j=0; j<oArr.length; j++)
		{
			s = (String)oArr[j];
			if (s == null) break;		// no attendee
			if (s.startsWith(myUidS))
			{
				found = true;
				count++;
				break;					// found
			}
		}
		if (!found)
			mtgArr[i] = null;			// don't show this meeting
	}

	if (count != 0)
	{
		for (int i=0; i<mtgArr.length; i++)
		{
			m = mtgArr[i];
			if (m != null)
			{
				startD = (Date)m.getAttribute("StartDate")[0];
				start = df6.format(startD);
				endD = (Date)m.getAttribute("ExpireDate")[0];
				end = df5.format(endD);
				id = m.getObjectId();
				subj = (String)m.getAttribute("Subject")[0];
				mtgState = (String)m.getAttribute("Status")[0];
				if (m.getAttribute("Type")[0].equals(meeting.PUBLIC))
					typeInd = PUBLIC_IND;
				else
					typeInd = "";
				out.println("<tr><td width='2'>&nbsp;</td>");
				out.print("<td class='plaintext' valign='top' colspan='3'>");
				out.print(start + " - " + end);

				out.print("</td></tr>");
				out.print("<tr><td width='5'></td>");
				out.print("<td><img src='../i/spacer.gif' width='10'></td>");
				%><script language="JavaScript">showStatus('<%=mtgState%>');</script><%
				out.print("<td width='100%' valign='middle'><a class='listlink' href='../meeting/mtg_view.jsp?mid=" + id + "'>" + subj + "</a>" + typeInd + "</td></tr>");
				out.print("<tr><td colspan='4'><img src='../i/spacer.gif' width='1' height='5' border='0'></td></tr>");
			}
		}
	}
	else
	{
		out.println("<tr><td><img src='../i/spacer.gif' width='5' height='2' border='0'></td>");
		out.println("<td class='plaintext_grey' valign='top' colspan='3'>&nbsp;None</td></tr>");
	}
%>
		<tr>
			<td height="5" colspan=4><img src="../i/spacer.gif" width="1" height="5" border="0"/></td>
	    </tr>
		<tr>
			<td class="plaintext_blue" colspan=4>Other Days of the Week</td>
		</tr>
		<tr>
			<td colspan='4'><img src="../i/spacer.gif" width="1" height="3" border="0"/></td>
	    </tr>
<%
	GregorianCalendar thisSat = new GregorianCalendar();
	GregorianCalendar lastSun = new GregorianCalendar();
	thisSat.setTime(now);
	lastSun.setTime(now);
	while (thisSat.get(Calendar.DAY_OF_WEEK) != Calendar.SATURDAY)
	{
		thisSat.add(Calendar.DATE, 1);
	}
	while (lastSun.get(Calendar.DAY_OF_WEEK) != Calendar.SUNDAY)
	{
		lastSun.add(Calendar.DATE, -1);
	}

	Date lastSunD = lastSun.getTime();
	Date thisSatD = thisSat.getTime();
	temp = thisSatD.getTime();
	temp = temp + temp2;
	thisSatD = new Date(temp);

	expr = "(StartDate>='" + df1.format(lastSunD)+ "') && (StartDate<'" + df1.format(thisSatD) + "')";

	int [] mIds = mtgMgr.findId(pstuser, expr);

	// take out all those that appear in the first two int arrays mIds1 and mIds2
	ct = 0;
	for (int i=0; i<mIds.length; i++)
	{	if (mIds[i] > 0)
		{
			found = false;
			for (int j=0; j<mIds1.length; j++)
				if (mIds[i] == mIds1[j]) {mIds[i]=-1; found=true; ct++; break;}
			if (!found)
				for (int j=0; j<mIds2.length; j++)
					if (mIds[i] == mIds2[j]) {mIds[i]=-1; ct++; break;}
		}
	}
	// now re-construct the rest of the week mId array
	idx = 0;
	if (ct > 0)
	{
		mIds1 = new int[mIds.length - ct];
		for (int i=0; i<mIds.length; i++)
			if (mIds[i] > 0) mIds1[idx++] = mIds[i];
	}
	else
		mIds1 = mIds;

	mtgArr = mtgMgr.get(pstuser, mIds1);
	len = mtgArr.length;
	if (len > 1)
		Util.sortDate(mtgArr, "StartDate");

	for (int i=0; i<mtgArr.length; i++)
	{
		m = mtgArr[i];

		if (m.getAttribute("Type")[0].equals(meeting.PUBLIC))
			continue;					// include public meeting

		if (myUidS.equals(m.getAttribute("Owner")))
			continue;					// found

		s = (String)m.getAttribute("TownID")[0];
		if (s!=null && townString.indexOf(s)!=-1)
			{count++; continue;}		// found same town

		found = false;
		Object [] oArr = m.getAttribute("Attendee");
		for (int j=0; j<oArr.length; j++)
		{
			s = (String)oArr[j];
			if (s == null) break;		// no attendee
			if (s.startsWith(myUidS))
			{
				found = true;
				break;					// found
			}
		}
		if (!found)
			mtgArr[i] = null;			// don't show this meeting
	}

	count = 0;
	for (int i=0; i<mtgArr.length; i++)
	{
		m = mtgArr[i];
		if (m != null)
		{
			mtgState = (String)m.getAttribute("Status")[0];
			if (mtgState.equals(meeting.EXPIRE))
				continue;
			count++;
			startD = (Date)m.getAttribute("StartDate")[0];
			start = df6.format(startD);
			endD = (Date)m.getAttribute("ExpireDate")[0];
			end = df5.format(endD);
			id = m.getObjectId();
			subj = (String)m.getAttribute("Subject")[0];
			if (m.getAttribute("Type")[0].equals(meeting.PUBLIC))
				typeInd = PUBLIC_IND;
			else
				typeInd = "";
			out.println("<tr><td width='2'>&nbsp;</td>");
			out.print("<td class='plaintext' valign='top' colspan='3'>");
			out.print(start + " - " + end);

			out.print("</td></tr>");
			out.print("<tr><td width='5'></td>");
			out.print("<td><img src='../i/spacer.gif' width='10'></td>");
			%><script language="JavaScript">showStatus('<%=mtgState%>');</script><%
			out.print("<td width='100%' valign='middle'><a class='listlink' href='../meeting/mtg_view.jsp?mid=" + id + "'>" + subj + "</a>" + typeInd + "</td></tr>");
			out.print("<tr><td colspan='4'><img src='../i/spacer.gif' width='1' height='5' border='0'></td></tr>");
		}
	}

	if (count <= 0)
	{
		out.print("<tr><td><img src='../i/spacer.gif' width='5' height='2'></td>");
		out.print("<td class='plaintext_grey' valign='top' colspan='3'>&nbsp;None</td></tr>");
	}
%>
		<tr>
			<td height="5" colspan=4><img src="../i/spacer.gif" width="1" height="5" border="0"></td>
	    </tr>
		<tr>
			<td class="plaintext_blue" colspan=4>Upcoming ...</td>
		</tr>
		<tr>
			<td colspan='4'><img src="../i/spacer.gif" width="1" height="3" border="0"></td>
	    </tr>
<%

	GregorianCalendar future = (GregorianCalendar)thisSat.clone();
	future.add(Calendar.MONTH, 1);
	expr = "(StartDate>'" + df1.format(thisSatD) + "') && (StartDate<'" + df1.format(future.getTime()) + "')";
	mIds = mtgMgr.findId(pstuser, expr);

	// take out all those that appear in the tomorrow array mIds2
	ct = 0;
	for (int i=0; i<mIds.length; i++)
	{	if (mIds[i] > 0)
		{
			for (int j=0; j<mIds2.length; j++)
				if (mIds[i] == mIds2[j]) {mIds[i]=-1; ct++; break;}
		}
	}
	// now re-construct the upcoming mId array
	idx = 0;
	if (ct > 0)
	{
		mIds1 = new int[mIds.length - ct];
		for (int i=0; i<mIds.length; i++)
			if (mIds[i] > 0) mIds1[idx++] = mIds[i];
	}
	else
		mIds1 = mIds;


	mtgArr = mtgMgr.get(pstuser, mIds1);
	len = mtgArr.length;
	if (len > 1)
		Util.sortDate(mtgArr, "StartDate");

	for (int i=0; i<mtgArr.length; i++)
	{
		found = false;
		m = mtgArr[i];

		if (m.getAttribute("Type")[0].equals(meeting.PUBLIC))
			continue;					// include public meeting

		if (myUidS.equals(m.getAttribute("Owner")))
			continue;					// found

		s = (String)m.getAttribute("TownID")[0];
		if (s!=null && townString.indexOf(s)!=-1)
			{count++; continue;}		// found same town

		Object [] oArr = m.getAttribute("Attendee");
		for (int j=0; j<oArr.length; j++)
		{
			s = (String)oArr[j];
			if (s == null) break;		// no attendee
			if (s.startsWith(myUidS))
			{
				found = true;
				break;					// found
			}
		}
		if (!found)
			mtgArr[i] = null;			// don't show this meeting
	}

	count = 0;
	for (int i=0; i<mtgArr.length; i++)
	{
		m = mtgArr[i];
		if (m != null)
		{
			mtgState = (String)m.getAttribute("Status")[0];
			if (mtgState.equals(meeting.EXPIRE))
				continue;
			count++;
			startD = (Date)m.getAttribute("StartDate")[0];
			start = df6.format(startD);
			endD = (Date)m.getAttribute("ExpireDate")[0];
			end = df5.format(endD);
			id = m.getObjectId();
			subj = (String)m.getAttribute("Subject")[0];
			if (m.getAttribute("Type")[0].equals(meeting.PUBLIC))
				typeInd = PUBLIC_IND;
			else
				typeInd = "";
			out.println("<tr><td width='2'>&nbsp;</td>");
			out.print("<td class='plaintext' valign='top' colspan='3'>");
			out.print(start + " - " + end);

			out.print("</td></tr>");
			out.print("<tr><td width='5'></td>");
			out.print("<td><img src='../i/spacer.gif' width='10'></td>");
			%><script language="JavaScript">showStatus('<%=mtgState%>');</script><%
			out.print("<td width='100%' valign='middle'><a class='listlink' href='../meeting/mtg_view.jsp?mid=" + id + "'>" + subj + "</a>" + typeInd + "</td></tr>");
			out.print("<tr><td colspan='4'><img src='../i/spacer.gif' width='1' height='5' border='0'></td></tr>");
		}
	}

	if (count <= 0)
	{
		out.print("<tr><td><img src='../i/spacer.gif' width='5' height='2'></td>");
		out.print("<td class='plaintext_grey' valign='top' colspan='3'>&nbsp;None</td></tr>");
	}

%>

<tr>
	<td colspan='4' class="tinytype" ><img src="../i/spacer.gif" width="1" height="20" /><span style='color:#00bb00;'>* = Public meeting</span></td>
</tr>

		<tr><td colspan='4'><img src='../i/spacer.gif' height='25'></img></td></tr>

		<!--  *******************   D O   S O M E  W O R K S  *******************  -->
		<tr><td colspan='4'>
		<table width='100%' border='0' cellpadding='0' cellspacing='0'>
			<tr>
				<td colspan='2' class="level2" colspan='4' bgcolor='#bbbbbb' style='color:#ffffff'>&nbsp;&nbsp;Do Some Works</td>
			</tr>
			<tr><td colspan='2' bgcolor='#aaaaaa'><img src='../i/spacer.gif' height='3' /></td></tr>
			<tr><td colspan='2'><img src="../i/spacer.gif" width="1" height="10"/></td></tr>

			<tr>
				<td valign="baseline"><img src="../i/bullet_tri.gif" width="20" height="8"/></td>
				<td><a class="listlink_big" href="../question/q_new1.jsp?Qtype=event">New Invite for Party or Event</a></td>
			</tr>
			<tr><td colspan='2'><img src='../i/spacer.gif' height='8'/></td></tr>
			<tr>
				<td valign="baseline"><img src="../i/bullet_tri.gif" width="20" height="8"/></td>
				<td><a class="listlink_big" href="../question/q_new1.jsp?Qtype=quest">New Questionnaire, Survey or Vote</a></td>
			</tr>
			<tr><td colspan='2'><img src='../i/spacer.gif' height='8'/></td></tr>
			<tr>
				<td valign="baseline"><img src="../i/bullet_tri.gif" width="20" height="8"/></td>
				<td><a class="listlink_big" href="../meeting/mtg_new1.jsp?StartNow=true">Start meeting NOW</a></td>
			</tr>
			<tr><td colspan='2'><img src='../i/spacer.gif' height='8'/></td></tr>
			<tr>
				<td valign="baseline"><img src="../i/bullet_tri.gif" width="20" height="8"/></td>
				<td><a class="listlink_big" href="../meeting/mtg_new1.jsp?Subject=<%=fName%>&#39s Meeting">Schedule a New Meeting</a></td>
			</tr>
			<tr><td colspan='2'><img src='../i/spacer.gif' height='8'/></td></tr>
			<tr>
				<td valign="baseline"><img src="../i/bullet_tri.gif" width="20" height="8"/></td>
				<td><a class="listlink_big" href="add_contact.jsp?type=case2&action=invite">Invite a friend to join MeetWE</a></td>
			</tr>
			<tr><td colspan='2'><img src='../i/spacer.gif' height='8'/></td></tr>
			<tr>
				<td valign="baseline"><img src="../i/bullet_tri.gif" width="20" height="8"/></td>
				<td><a class="listlink_big" href="cir_update.jsp">Create a New Circle</a></td>
			</tr>
			<tr><td colspan='2'><img src='../i/spacer.gif' height='8'/></td></tr>
			<tr>
				<td valign="baseline"><img src="../i/bullet_tri.gif" width="20" height="8"/></td>
				<td><a class="listlink_big" href="ep1.jsp">Update My Profile</a></td>
			</tr>
			<tr><td><img src='../i/spacer.gif' height='15'/></td></tr>
			<tr>
				<td colspan='2' align='center'><input type="button" value='QUICK TOUR' onclick="javascript:location='../info/whatis.jsp'"/></td>
			</tr>
<%	if (isAdmin)
	{%>
			<tr><td colspan='2'><img src='../i/spacer.gif' height='8'/></td></tr>
			<tr>
				<td valign="baseline"><img src="../i/bullet_tri.gif" width="20" height="8"/></td>
				<td><a class="listlink_big" href="../plan/new_templ1.jsp">Add Meeting Template</a></td>
			</tr>
<%	} %>
		</table>
		</td></tr>
		<!--  **************   E N D   D O   S O M E T H I N G  *****************  -->

		<tr><td colspan='4'><img src='../i/spacer.gif' height='20'/></td></tr>

<tr><td colspan='4'>
<!-- GOOGLE ADS -->
<table border='0' cellspacing='0' cellpadding='0'>

<tr><td colspan='3' align='center'>
<script type="text/javascript"><!--
google_ad_client = "pub-8652216983185669";
google_ad_width = 250;
google_ad_height = 250;
google_ad_format = "250x250_as";
google_ad_type = "text_image";
//2006-11-10: HomeSide
google_ad_channel = "5358245164";
google_color_border = "2299BB";
google_color_bg = "F0F0F0";
google_color_link = "006699";
google_color_text = "333333";
google_color_url = "00BB00";
//--></script>
<!-- >script type="text/javascript"
  src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
</script-->
</td></tr>

<tr><td colspan='3'><img src='../i/spacer.gif' height='1' title='social network, chat, meeting' /></td></tr>
</table>
<!-- END GOOGLE ADS -->
</td></tr>

		</table>
</td>
<!-- END CENTER PANEL -->

		<td><img src='../i/spacer.gif' width='20' /></td>


<!-- RIGHT PANEL -->
<td width='30%' valign='top'>
		<table width='100%' border='0' cellspacing='0' cellpadding='0'>
		<tr><td valign="top">
		<!-- ***** List of News -->
			<table width='100%' border='0' cellspacing='0' cellpadding='0' style='word-wrap:break-word;'>

<!--  ******************************   W H A T ' S   H A P P E N I N G  *************************************  -->

		<tr>
			<td width='100%' class="level2" colspan='4' bgcolor='#2280dd' style='color:#ffffff'>&nbsp;&nbsp;What's Happening ...</td>
		</tr>
		<tr>
			<td colspan='4' bgcolor='#2060c0'><img src='../i/spacer.gif' height='3' /></td></tr>
		<tr>
			<td height="3" colspan='4'><img src="../i/spacer.gif" width="1" height="15" border="0"/></td>
	    </tr>

	    <tr><td colspan='4' id='Events' class='plaintext'>

		</td></tr>

<!--  ******************************   E N D   W H A T ' S   H A P P E N I N G  ***************************  -->



			<tr><td colspan='4'><img src='../i/spacer.gif' height='15'/></td></tr>
			</table>


</td>
<!-- END RIGHT PANEL -->

		</tr>
	</table>
	</td>
	</tr>
	</table>
	</tr>
</form>
      <jsp:include page="../foot.jsp" flush="true"/>
      </table>
    </td>
  </tr>

</table>
	</td>
</tr>

</table>
<p>&nbsp;</p>

<jsp:include page="ep_expr.jsp" flush="true"/>

</body>
</html>
