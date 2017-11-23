<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2007, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: ep_circles.jsp
//	Author: ECC
//	Date:	11/05/07
//	Description: The frame file to display the friends and circle of ep_home.jsp
//
//	Modification:
//			@ECC020808	Show online status.  Whether we are showing My Friends
//						or circle members, those who are online will be shown first.
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
<%@ page import = "mod.mfchat.OmfPresence" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>

<%
	String noSession = "../index.jsp";	//"../out.jsp?go=ep/ep_home.jsp";
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%
	final int BATCH_SIZE	= 4;			// show 4 batch idx at a time
	PstUserAbstractObject me = pstuser;

	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if (iRole > 0)
	{
		if ((iRole & user.iROLE_ADMIN) > 0)
			isAdmin = true;
	}
	
	int myUid = me.getObjectId();
	OmfPresence.setOnline(myUid);
		
	// friends and circles
	int selectedCircleId;
	String selectedCircleName = null;
	String s = request.getParameter("circle");
	if (s != null)
	{
		session.setAttribute("circle", s);		// remember the circle
	}
	else
	{
		//selectedCircleId = 0;
		s = (String)session.getAttribute("circle");
		if (s == null) s = "0";
	}
	selectedCircleId = Integer.parseInt(s);
	if (selectedCircleId <= 0)
		selectedCircleName = "My friends";

	townManager tnMgr = townManager.getInstance();
	userManager uMgr = userManager.getInstance();
	PstAbstractObject detailUser = uMgr.get(me, me.getObjectId());
	String myFullName = ((user)detailUser).getFullName();
	
	// showing members in batches
	int beginIdx = 0;				// member object index (not batch #)
	int currentBatch = 1;			// default to start from batch #1
	int begBatch = 1;				// beginning batch # being shown
	int lastBegin;					// the last beginning batch #
	String idxS = request.getParameter("idx");
	if (idxS != null)
	{
		currentBatch = Integer.parseInt(idxS);
		beginIdx = (currentBatch-1) * OmfPresence.MAX_SHOWN;
	}
	String lastBeg = request.getParameter("lastBeg");
	if (lastBeg != null)
		lastBegin = Integer.parseInt(lastBeg);
	else
		lastBegin = 1;

	// the param pos indicates the clicked item's position on the batch < 1 2 3 4 >
	// note that the "<" has pos=0 and ">" has pos=5
	int pos=1;
	String posS = request.getParameter("pos");
	if (posS!=null) pos = Integer.parseInt(posS);
	if (pos==0 && currentBatch<lastBegin)
		begBatch = lastBegin - BATCH_SIZE;
	else if ( pos==(BATCH_SIZE+1) && currentBatch>=(lastBegin+BATCH_SIZE) )
		begBatch = lastBegin + BATCH_SIZE;
	else
		begBatch = lastBegin;
	if (begBatch <=0) begBatch = 1;
	
	// remove or block+remove from friend; or ignore a person from search;
	// or add a circle member as friend; or add a whole circle as friends
	int [] ids = null;
	int id = 0;
	String msg = "";
	Object [] tempA;
	user u;
	boolean bDisplayFromMem = false;
	s = request.getParameter("remove");
	if (s == null)
		s = request.getParameter("block");	
	if (s != null)
	{
		// block: first remove from my friends list
		detailUser.removeAttribute("TeamMembers", new Integer(s));
		uMgr.commit(detailUser);
		session.setAttribute("pstuser", detailUser);
		
		if (request.getParameter("block") != null)
		{
			// also remove me from the person's TeamMembers list
			PstAbstractObject o = uMgr.get(me, Integer.parseInt(s));
			o.removeAttribute("TeamMembers", new Integer(myUid));
			uMgr.commit(o);
		}
	}
	else if ((s = request.getParameter("ignore")) != null)
	{
		// ignore: remove from my friends list
		bDisplayFromMem = true;						// will get memId from session searchArr
		id = Integer.parseInt(s);
		ids = (int [])session.getAttribute("searchArr");
		int [] ids1 = new int[ids.length-1];		// user just click to take one person out
		int ct = 0;
		for (int i=0; i<ids.length; i++)
		{
			if (ids[i] != id)
				ids1[ct++] = ids[i];
		}
		session.setAttribute("searchArr", ids1);	// save the result after ignore
	}
	else if ((s = request.getParameter("add")) != null)
	{
		// add: add this to my friends list
		// submit the request for friend
		Util3.sendRequest(me, String.valueOf(id), req.REQ_FRIEND, null);		// quick add: no optional message	
		msg = "Your request for connection has been sent.";
	}
	else if ((s = request.getParameter("addAll")) != null)
	{
		// add all members of circle as My Friends
		
		// construct myFriends hash for comparison later
		Hashtable hsFriends = new Hashtable();
		Object [] oA = me.getAttribute("TeamMembers");
		for (int i=0; i<oA.length; i++)
		{
			if (oA[i] == null) break;
			hsFriends.put((Integer)oA[i], "");
		}

		id = Integer.parseInt(s);	// this is the circle id whose members to be added as my friends
		ids = uMgr.findId(me, "Towns=" + s);
		int ct = 0;
		for (int i=0; i<ids.length; i++)
		{
			// check to see if the person is already a friend
			if (hsFriends.containsKey(new Integer(ids[i])))
				continue;
			ct++;
			Util3.sendRequest(me, String.valueOf(ids[i]), req.REQ_FRIEND, null);		// quick add: no optional message	
		}
		if (ct > 0)
			msg = ct + " connection request(s) sent to circle members.";
		else
			msg = "All members of the circle are already your friends.  No new friend request sent.";
/*
		selectedCircleId = 0;				// display my friends after adding circle to friends
		selectedCircleName = "My friends";	// need to explicitly set this otherwise will call ep_circles.jsp below again
		id = 0;								// showing id
		ids = null;							// set to null otherwise I confuse myself below and perform mergeJoin
*/
	}
		
	/////////////////////////////////////////////////////
	// retrieve the members to be displayed
	String expr="", expr1;
	int [] memIds = new int[0];			// this array holds the memid to be displayed
	Object [] oA;
	
	if (bDisplayFromMem)
		memIds = (int [])session.getAttribute("searchArr");
	else if (selectedCircleId <= 0)
	{
		// need to list my friends
		oA = detailUser.getAttribute("TeamMembers");
		if (oA[0] != null)
			memIds = Util2.toIntArray(oA);
	}
	else
	{
		// list circle members
		expr = "(Towns=" + selectedCircleId + ")";
	}
	// by here, either memIds is filled or expr is set up
	
	// support look up within circle/friend
	int [] lastSearchArr = new int[0];
	String [] sa;
	s = request.getParameter("search");
	String searchStr = s;
	if (s != null)
	{
		// search: construct expression
		ids = new int[0];
		if (s.charAt(0) == '&')
		{
			// continue from last search
			lastSearchArr = (int [])session.getAttribute("searchArr");
			s = searchStr = s.substring(1).trim();
		}

		// there might be a number of search strings (e.g. mary & john & cheng)
		boolean bDoubleQuote = false;
		if (expr.length() > 0) expr += " && ";
		if (s.charAt(0) == '\"')
		{
			bDoubleQuote = true;
			s = searchStr = s.replaceAll("\"", "");			// remove the double quote
		}
		s = s.replaceAll(" ", "&");
		sa = s.split("&");
		for (int i=0; i<sa.length; i++)
		{
			s = sa[i].trim();
			if (s.length() == 0) continue;
			s = s.replaceAll("[*]+", "*");	// one * is good enough
			if (!(s.startsWith("*") || s.endsWith("*")))
				s = "%" + s + "%";
			s = s.replaceAll("\\*", "%");
			expr1 = expr + "(FirstName='" + s + "' || LastName='" + s + "' || Email='" + s + "' || om_acctname='" + s + "')";
			if (!bDoubleQuote)
				ids = Util2.mergeIntArray(ids, uMgr.findId(me, expr1));
			else
			{
				if (ids.length > 0)
					ids = Util2.mergeJoin(ids, uMgr.findId(me, expr1));
				else
					ids = uMgr.findId(me, expr1);
			}
		}
		if (lastSearchArr.length > 0)
			ids = Util2.mergeIntArray(ids, lastSearchArr);	// combine result from last search session
	}
	else if (expr.length() > 0)
		memIds = uMgr.findId(me, expr);	// not search, with selected circle
	
	if (ids != null)
	{
		if (memIds.length > 0)
			memIds = Util2.mergeJoin(memIds, ids);
		else
			memIds = ids;
	}

	if (searchStr != null)
		session.setAttribute("searchArr", memIds);	// remember search result
	else if (!bDisplayFromMem)
		session.removeAttribute("searchArr");		// !search && !ignore
		
%>

<head>
<title>MeetWE Home</title>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen" />
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print" />
<script type="text/javascript" src="../meeting/ajax_utils.js"></script>
<script language="JavaScript" src="event.js"></script>
<script language="JavaScript" src="chat.js"></script>
<script language="JavaScript">
<!--

var uid = "<%=myUid%>";
var act_hello = "<%=PrmEvent.ACT_HELLO%>";		// action() in event.js needs this
var selectedCircleId = "<%=selectedCircleId%>";
var bDisplaySearch = ("<%=searchStr%>"!="null" || <%=bDisplayFromMem%>);
frame = "child";			// define in event.js
myName = "<%=myFullName%>";

//////////////////
// check online is disabled when we do a search, display from memory, or when posting note
// this is controlled by bCheckOnline.
//
var cirTimerId;
var REG_SLEEP = 31000;
var FAST_SLEEP = 10000;
var sleepTime = 0;
var cirReqAuto;					// ajax variable for auto check online
var onlineS = "";				// remember who's online


window.onload = function()
{
	sleepTime = 0;				// skip the first call to checkOnline when first loaded
	window.parent.getChatIds();
	//setFrameHeight();
	if ("<%=msg%>" == "")
		show_action(null, null, <%=selectedCircleId%>);
	else
		show_msg("<%=msg%>", <%=id%>);
	if (!bDisplaySearch)
		cirTimer();		// auto check online users
	setFrameHeight();
}


function cirTimer()
{
	if (bCheckOnline)
	{
		if (sleepTime > 0)		// skip the first call
			ajaxCheckOnline();
		sleepTime = REG_SLEEP;
	}
	else
		sleepTime = FAST_SLEEP;
	
	cirTimerId = setTimeout("cirTimer();", sleepTime);	// every REG_SLEEP or FAST_SLEEP ms
}

function ajaxCheckOnline()
{
	// ajax check who's online
	if (window.XMLHttpRequest)
		cirReqAuto = new XMLHttpRequest(); 
	else if (window.ActiveXObject)
		cirReqAuto = new ActiveXObject("Microsoft.XMLHTTP");

	// sends last array of those who are online
	var url = "../servlet/OmfEventAjax?uid=" + uid + "&online=" + onlineS
				+ "&circle=<%=selectedCircleId%>"
				+ "&begIdx=<%=beginIdx%>";
		
	cirReqAuto.open("GET", url, true);
	cirReqAuto.onreadystatechange = callbackOnline;
	cirReqAuto.send(null);
}

function callbackOnline()
{
    if (cirReqAuto.readyState == 4)
    {
        if (cirReqAuto.status == 200)
        {
            // update the HTML DOM based on whether or not message is valid;
			parseXmlOnline(cirReqAuto);
			if (sleepTime == FAST_SLEEP)
				sleepTime = REG_SLEEP;	
        }
    }
}

function parseXmlOnline(l_req)
{
	// check any change of online users
	var newId;
	var str = getResponseXml("OnlineXml", l_req);
	if (str!=null && str!="no change")
	{
		// there is change on the online/offline list
		document.getElementById("memList").innerHTML = str;
		playSound("notify.wav");
		
		onlineS = getResponseXml("OnlineStr", l_req);
		if (onlineS == null) onlineS = "";
		setFrameHeight();
	}
}

function resetAction()
{
	bCheckOnline = true;
	if (showingId != "")
	{
		var e = document.getElementById(showingId);
		e.style.display = "none";
		e.innerHTML = "";
		showingId = "";
		setFrameHeight();
	}
}

function friend(op, id, name)
{
	// op = remove; block; or ignore
	if (op == "remove")
	{
		if (!confirm("Do you want to remove " + name + " from your friends' list?"))
			return;
	}
	else if (op == "block")
	{
		if (!confirm("Do you want to remove " + name + " from your friends' list\n and block " + name + " from interacting with you?"))
			return;
	}
	
	var param = "?circle=<%=selectedCircleId%>";
	if ("<%=posS%>" != "null")
		param += "&pos=<%=posS%>";
	if ("<%=idxS%>" != "null")
		param += "&idx=<%=idxS%>";
	location = "ep_circles.jsp" + param + "&" + op + "=" + id;
}

//-->
</script>
</head>
<body bgcolor="#FFFFFF" height='100%' leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<bgsound id="IESound">
<span id="FFSound"></span>

		<table id='Friends' width='100%' border='0' cellspacing='0' cellpadding='0'>
			<tr>
				<td colspan='2' class="level2" bgcolor='#2280dd' style='color:#ffffff'>&nbsp;&nbsp;Friends &amp; Circles</td>
			</tr>
			<tr><td colspan='2' bgcolor='#2060c0'><img src='../i/spacer.gif' height='3' /></td></tr>
			<tr><td colspan='2'><img src='../i/spacer.gif' height='10' /></td></tr>

<%

		// my friends
		int friendNum = 0;
		oA = detailUser.getAttribute("TeamMembers");
		if (oA[0] != null)
			friendNum = oA.length;
		
		// circles
		int num = 0;
		if (isAdmin)
			ids = tnMgr.findId(me, "om_acctname='%'");	// show all towns (circles) for Admin for now
		else
		{
			oA = detailUser.getAttribute("Towns");
			if (oA[0] != null)
			{
				// get the town (circle) ids
				ids = new int[oA.length];
				for (int i=0; i<oA.length; i++)
					ids[i] = ((Integer)oA[i]).intValue();
			}
		}
		
		// list my circles
		PstAbstractObject [] cirArr = null;
		if (ids != null)
		{
			cirArr = tnMgr.get(me, ids);
			Util.sortString(cirArr, "Name", true);
		}
		
		String imgS = "";
		s = "My friends";
		if (selectedCircleId == 0)
		{
			imgS = "<img src='../i/bullet_tri.gif' width='15' />";
			s = "<b>" + s + "</b>";
		}
		out.print("<tr><td>" + imgS + "</td>");
		out.print("<td width='100%' class='plaintext_grey'><a class='listlink' href='ep_circles.jsp?circle=0#cir'>"
				+ s + "</a> (" + friendNum + ")</td></tr>");
			
		String myMotto = (String)me.getAttribute("Motto")[0];
		if (ids != null)
		for (int i=0; i<cirArr.length; i++)
		{
			id = cirArr[i].getObjectId();
			num = uMgr.findId(me, "Towns=" + id).length; 
			s = (String)cirArr[i].getAttribute("Name")[0];
			imgS = "";
			if (id == selectedCircleId)
			{
				selectedCircleName = s;
				imgS = "<img src='../i/bullet_tri.gif' width='15' />";
				s = "<b>" + s + "</b>";
			}
			out.print("<tr><td>" + imgS + "</td><td class='plaintext_grey'>");
			out.print("<a class='listlink' href='ep_circles.jsp?circle=" + id + "#cir'>" + s + "</a>");
			out.print(" (" + num + ")</td></tr>");
		}
		if (selectedCircleName == null)
		{
			// the remembered circle has been deleted
			session.removeAttribute("circle");
			response.sendRedirect("ep_circles.jsp");
			return;
		}

		out.print("<tr><td colspan='2'><a name='cir'></a><img src='../i/spacer.gif' height='5' /></td></tr>");

		out.print("<tr><td colspan='2' align='right'><img src='../i/bullet_tri.gif' width='15' />");
		out.print("<a class='listlink' href='javascript:show_redirect(\"cir_update.jsp\")'>Add new circles&nbsp;&nbsp;</a></td></tr>");
		
		out.print("</table>");
		out.print("<table width='90%' border='0' cellspacing='0' cellpadding='0'><tr><td><hr /></td></tr></table>");
		
		///////////////////////////////////////////////////////////////////////////
		// start listing the members in selected circle / My friends
		// @ECC020808
		// We will split the memIds into two int arrays.  One contains all those who
		// are online now, and the other not online.  We will list those who are online
		// first.
		// This display mechanism is moved to OmfPresence.java so that the timer
		// can get the same XML return.
		
		// memIds contains either all circle members or all my friends
		int resNum = memIds.length;
		user uObj;
		String picURL;
		
		// total no. of batches
		int totalBatch = (int)Math.ceil(((double)resNum) / OmfPresence.MAX_SHOWN);
		
		out.print("<table width='100%' border='0' cellspacing='0' cellpadding='0'>");
		out.print("<tr><td colspan='2'><img src='../i/spacer.gif' height='5' /></td></tr>");
		
		// start showing the selected circle
		out.print("<tr><td width='150' class='plaintext_blue'><img src='../i/circle.jpg' border='0'/>&nbsp;");
		out.print("<a href='javascript:show_action(null, null, " +selectedCircleId+ ");'>" +selectedCircleName+ "</a></td>");
		out.print("<td class='plaintext'>");
		
		// show the batch index numbers on top and bottom of the list
		StringBuffer sBuf = new StringBuffer();
		int batchIdx;
		if (begBatch > 1)
			sBuf.append("<a class='listlink' href='ep_circles.jsp?circle=" + selectedCircleId + "&pos=0" + "&lastBeg=" + begBatch + "&idx=" + (currentBatch-1) + "'>&lt;&lt;</a>");
		if (totalBatch > 1)
		{
			pos = 1;	// position of the index on the current batch (start from 1)
			for (batchIdx=begBatch; batchIdx<=totalBatch && batchIdx<begBatch+BATCH_SIZE; batchIdx++)
			{
				if (batchIdx == currentBatch)
					sBuf.append("&nbsp;<font color='#bb0000'>" + currentBatch + "</font>");
				else
					sBuf.append("&nbsp;<a href='ep_circles.jsp?circle=" + selectedCircleId + "&idx=" + batchIdx + "&pos=" + pos + "&lastBeg=" + begBatch + "'><b>" + batchIdx + "</b></a>");
				pos++;
			}
			if (batchIdx < totalBatch+1)
				sBuf.append("&nbsp;<a class='listlink' href='ep_circles.jsp?circle=" + selectedCircleId + "&pos=" + pos + "&lastBeg=" + begBatch + "&idx=" + (currentBatch+1) + "'>&gt;&gt;</a>");
		}
		out.print(sBuf.toString());
		
		// circle action display (none/block)
		out.print("<tr><td colspan='2'><div id='" + selectedCircleId + "' class='plaintext' style='display:none;'></div></td></tr>");
		out.print("<tr><td colspan='2'><img src='../i/spacer.gif' height='5' /></td></tr>");
		out.print("</table>");
		
		// search result label and search icon
		out.print("<table width='100%' border='0' cellspacing='0' cellpadding='0'>");
		if (searchStr != null)
			out.print("<tr><td class='plaintext_grey'>Search <b>" + searchStr + "</b> result: " + resNum);
		else
			out.print("<tr><td class='plaintext_grey'>Total members: " + resNum);
		out.print("</td><td align='right'><a href='javascript:showLookUp("
				+ selectedCircleId + ");' class='listlink'><img src='../i/search.gif' border='0' title='Enter partial name or email to search' /></a>&nbsp;&nbsp;</td></tr>");
		out.print("</table>");
		
		///////////////////////////////////////////////////////////////////////
		// showing list of members or friends
		// @ECC020808 there are two (2) int arrays to be list
		// call OmfPresence to display the XML
		// StringBuffer xmlBuf contains the XML of the member list
		// String onlineStr is a string of uid who are online, separated by ";"
		out.print("<div id='memList'>");

		StringBuffer xmlBuf = new StringBuffer(4096);
		String onlineStr = OmfPresence.displayMemberList(me, xmlBuf, null, memIds, beginIdx,
				(selectedCircleId==0),
				(searchStr==null),
				 bDisplayFromMem );
		out.print(xmlBuf.toString());
		out.print("</div>");
		out.print("<hr class='evt_hr' align='left' />");
		
		// display the batch numbers of members
		out.print("<table><tr><td width='150'></td><td class='plaintext'>" + sBuf.toString() + "</td></tr></table>");

%>

<script language="JavaScript">
<!--
var curCircleName = "<%=selectedCircleName%>";
var myCurrentMotto = "<%=myMotto%>";
onlineS = "<%=onlineStr%>";
//-->
</script>

</body>
</html>
