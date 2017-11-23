//
//	Copyright (c) 2007 EGI Technologies.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
// $Header: /cvsrepo/PRM/ep/event.js,v 1.26 2008/01/05 02:15:10 edwardc Exp $
//
//	File:	event.js
//	Author:	ECC
//	Date:	10/25/07
//  Description:
//      This js file deals with ajax calls to servlets for events.
//
//  Required:		ep_home.jsp for variable declaration.
//					meeting/ajax_utils.js and chat.js for methods.
//					Also see OmfEventAjax.java.
//					The expression functions at the end requires meeting/mtg_expr.js
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////


var reqAuto;				// ajax variable for auto check event
var run = false;			// is auto check on?
var evtTimer;				// Timer till refresh
var RESTART = 10;			// Restart time for auto check of events
var SAFENET = -20;			// Safety net for the timer to auto start again if network somehow failed to return
var autoCheckTimerId;		// timer id for windows

var reqSendAct;				// Send action

var showingId = "";
var bGroupAction = false;	// group (circle/friends/search) or individual
var blockEvent = 0;			// when posting note or retriving notes, block events processing
var bCheckOnline = true;	// when posting note, block check online on ep_circles.jsp
var utcDiff;

var showChatNum = "default";	// regular default value is showing the most recent 4
var nothing = "<div class='plaintext_grey'>&nbsp;Nothing ...</div>";
var frame;					// ep_home.jsp is parent; ep_circles.jsp is child
var isMSIE = (navigator.userAgent.toLowerCase().indexOf('msie')!=-1)?true:false;

var fullURL = parent.document.URL;
var isCPM = (fullURL.indexOf("ep_db.jsp")!=-1);


// initialize the Ajax call timer mechanism
function ajax_init()
{
	evtTimer = RESTART;		// init
	utcDiff = getDiffUTC();
	ajaxCheckEvent();
	run = true;
	timer();
}

function timer()
{
	evtTimer--;
	// was going to use evtTimer <= 0 but the calls may perform twice in a row
	// evtTimer < -15 is a safety net in case the first evtTimer == 0 was missed
	if (evtTimer == 0)
		ajaxCheckEvent();

	if (evtTimer <= SAFENET)
		evtTimer = RESTART;

	if (run)
		autoCheckTimerId = setTimeout("timer();", 1000);
}

function stopAutoCheckTimer()
{
	if (run)
		clearTimeout(autoCheckTimerId);
	run = false;
}

function ajaxCheckEvent(op)
{
	if (window.XMLHttpRequest)
		reqAuto = new XMLHttpRequest();
	else if (window.ActiveXObject)
		reqAuto = new ActiveXObject("Microsoft.XMLHTTP");

	// sends last eventId to check for updated event
	var evtIdStr = "&lastEvtId=" + current_eid;
	var UTCdiffStr = "&UTCdiff=" + utcDiff;

	if (op == null)
		op = "&op=" + showChatNum;
	else
		op = "&op=" + op;			// this is forcing a retrieval

	var url = "../servlet/OmfEventAjax?uid=" + uid + evtIdStr + UTCdiffStr + op;

	reqAuto.open("GET", url, true);
	reqAuto.onreadystatechange = callbackAuto;
	reqAuto.send(null);
}

function callbackAuto()
{
    if (reqAuto.readyState == 4)
    {
        if (reqAuto.status == 200)
        {
            // update the HTML DOM based on whether or not message is valid;
			parseXmlAuto(reqAuto);
			if (evtTimer > SAFENET) // Restart if evtTimer > SAFENET, otherwise let timer() handle the restart
				evtTimer = RESTART;
        }
    }
}

function parseXmlAuto(l_req)
{
	var bNoEvent = true;

	var bJustLoaded = false;
	if (current_eid == -1) bJustLoaded = true;		// just loaded the page

	// check and save the last event Id
	var newId;
	var str = getResponseXml("EventId", l_req);		// there must be an event id back
	newId = parseInt(str);
	if (newId == current_eid)
	{
		//bNoEvent = true;					// no new event: ignore the response
	}
	else if (newId == 0)
	{
		// event all removed
		document.getElementById("Events").innerHTML = nothing;
	}
	else if (newId == -1)
	{
		// error condition detacted on Ajax
	}
	else
	{
		// update the event display
		if (blockEvent <= 0)
		{
			current_eid = newId;
			str = getResponseXml("Events", l_req);
			if (str == null)
			{
				document.getElementById("Events").innerHTML = nothing;
			}
			else
			{
				bNoEvent = false;
				setInnerHTML("Events", str);
			}
		}
		else
			blockEvent--;
	}

	// update the chat list if necessary
	str = getResponseXml("ChatList", l_req);
	if (str != null)
		setInnerHTML("chatList", str);

	if (bNoEvent)
		return;

	if (!bJustLoaded) playSound("notify.wav");

	// certain event needs to be animated immediately
	// for each, call showExpr()
	str = getResponseXml("Expr", l_req);
	str = str + "";								// somehow this is necessary
	if (str!=null && str!="")
	{
		var exprPairArr = str.split("@");		// hello:John Smith@...
		var lastExpr = "";
		for (var i=0; i<exprPairArr.length; i++)
		{
			if (exprPairArr[i] == lastExpr) continue;	// repeated expr: just show once
			showExpr(exprPairArr[i]);
			lastExpr = exprPairArr[i];
		}
	}

}

//////////////////////////////////// Friends & Circles Actions //////////////////////////////////////////////


function ajaxSendAction(id, type)
{
	// type: hello, remove_event, accept/reject friend
	// id can be uid, evId, or showingId
	if (window.XMLHttpRequest) {
		reqSendAct = new XMLHttpRequest();
	} else if (window.ActiveXObject) {
		reqSendAct = new ActiveXObject("Microsoft.XMLHTTP");
	}
	if (bDisplaySearch && bGroupAction) id = 999;

	var url = "../servlet/OmfEventAjax";
	reqSendAct.open("POST", url, true);
	reqSendAct.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
	reqSendAct.send("uid=" + id + "&type=" + type);
}

function ajaxPostNote(uid, note, motto, thing, fName, bEmail, thoughtComment)
{
	// post note and send Turkey
	if (window.XMLHttpRequest) {
		reqSendAct = new XMLHttpRequest();
	} else if (window.ActiveXObject) {
		reqSendAct = new ActiveXObject("Microsoft.XMLHTTP");
	}
	if (bDisplaySearch && bGroupAction) uid = 999;

	var url = "../servlet/OmfEventAjax";
	var param = "uid=" + uid;
	if (note != null)
		param += "&note=" + escape(note);
	if (thoughtComment != null)
		param += "&thoughtComment=" + escape(thoughtComment);
	if (motto != null)
		param += "&motto=" + escape(motto);
	if (thing != null)
		param += "&thing=" + thing + "&thingFile=" + fName;
	if (bEmail)
		param += "&email=true";
	reqSendAct.open("POST", url, true);
	reqSendAct.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
	reqSendAct.send(param);
}

function ajaxGetNote(eid, label, op)
{
	// retrieve note with id, or get parent or child note
	if (window.XMLHttpRequest) {
		reqSendAct = new XMLHttpRequest();
	} else if (window.ActiveXObject) {
		reqSendAct = new ActiveXObject("Microsoft.XMLHTTP");
	}

	// label is fixed, eid changes when traverse through the thread
	var url = "../servlet/OmfEventAjax";
	var UTCdiffStr = "&UTCdiff=" + utcDiff;
	var evtIdStr = "&lastEvtId=" + current_eid;
	url += "?eid=" + eid + "&op=" + op + "&label=" + label + UTCdiffStr + evtIdStr;

	reqSendAct.open("GET", url, true);
	reqSendAct.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
	reqSendAct.onreadystatechange = callbackNote;
	reqSendAct.send(null);
}

function callbackNote()
{
    if (reqSendAct.readyState == 4)
    {
        if (reqSendAct.status == 200)
        {
            // update the HTML DOM based on whether or not message is valid;
			var str = getResponseXml("Note", reqSendAct);		// check the note back
			str = str + "";										// somehow this is necessary
			if (str!=null && str!="" && str!="null")
			{
				var label = getResponseXml("NoteLabel", reqSendAct);
				if (label == "Error")
					alert(str);
				else
					document.getElementById(label).innerHTML = str;
			}
		}
    }
}

////////////////////////////////////////////  Expressions  ////////////////////////////////////////////

var SIZE_OF_QUEUE = 10;

var queueIds  = new Array(SIZE_OF_QUEUE);
var queueFrom = new Array(SIZE_OF_QUEUE);

function showExpr(exprStr)
{
	// the exprStr format: id1:str1@id2:str2 ...  e.g. hello:edwardgem (ie. edwardgem says hello)
	// the first element nextIdx is the next index on the server expr queue to be read
	if (exprStr==null || exprStr=="")
	{
		if (!showing) dequeue();	// just in case if there are leftover items
		return -1;					// return -1 will not set nextIdx
	}

	exprArr = exprStr.split(":");	// id:str  i.e., divId:userId

	enqueue(exprArr[0], exprArr[1]);

	// start to dequeue: note that dequeue is a loop and will finish when there is no item left
	if (!showing)
		dequeue();
}

///////////////////////////////////////// action functions /////////////////////////////////////
// used by ep_circles.jsp; ep_home.jsp
//

var actions = ""
	 //+ ". <a href='javascript:action(3);' class='listlink'>Send turkey dinner to @UNAME@</a><br>"
	 + ". <a href='javascript:show_redirect(\"my_page.jsp\", @UID@)' class='listlink'>Go to @UNAME@'s page</a><br>"
	 + ". <a href='javascript:action(2);' class='listlink'>Say hello to @UNAME@</a><br>"
	 + ". <a href='javascript:action(1);' class='listlink'>Post a note to @UNAME@</a>";

var actionsCPM = ""
	 + ". <a href='javascript:show_redirect(\"../ep/ep1.jsp\", @UID@)'>View @UNAME@'s profile</a>";

var act_chat = "<br>. <a href='javascript:action(4, @UID@);'>Chat with @UNAME@</a>";
var act_join = "<br>. <a href='javascript:action(5);' class='listlink'>Add @UNAME@ to current chat</a>";

var actionSelf = ". <a href='javascript:show_redirect(\"my_page.jsp\")'>My Page</a>"
	 + "<br>. <a href='javascript:show_redirect(@PAGE@)'>My Profile</a>"
 	 + "<br>. <a href='javascript:action(7)'>Change my Motto</a>";

var actionSelfCPM = ""
	 + ". <a href='javascript:show_redirect(@PAGE@)'>View my profile</a>";

var actionCircle = ""
	 //+ ". <a href='javascript:action(3);' class='listlink'>Send turkey dinner to @UNAME@</a><br>"
	 + ". <a href='javascript:action(2);' class='listlink'>Say hello to circle</a><br>"
	 + ". <a href='javascript:action(1);' class='listlink'>Post a note to circle</a><br>"
	 + ". <a href='javascript:action(12, @UID@);' class='listlink'>Write an Email letter to circle</a>";

var actionSearch = ". <a href='javascript:action(2);' class='listlink'>Say hello to members below</a><br>"
	 + ". <a href='javascript:action(1);' class='listlink'>Post a note members below</a>";

var actionCir = ""
	+ "<br>. <a href='javascript:show_redirect(@INVITE@)' class='listlink'>Invite a friend to join circle</a>"
	+ "<br>. <a href='javascript:show_redirect(@PAGE@)' class='listlink'>Manage circle</a>"
	+ "<br>. <a href='javascript:make_circle_frn(@UID@, \"@UNAME@\");' class='listlink'>Add all circle members to My Friends</a>";

var actCir_view = ". <a href='javascript:show_redirect(\"my_page.jsp\", @UID@)' class='listlink'>Go to @UNAME@ page</a><br>";

var actionCirFriend =  "<br>. <a href='javascript:show_redirect(\"add_contact.jsp\")'>Add more friends</a>"
	+ "<br>. <a href='javascript:show_redirect(\"add_contact.jsp?type=case2&action=invite\")'>Invite a friend to join MeetWE</a>";
var actCir_chat = "<br>. <a href='javascript:action(6);' class='listlink'>Chat with @UNAME@</a>";


function show_action(id, eid, circleId, uName)
{
	//globalResetAction();
	window.parent.rename_chat(null, 1);		// remove the rename chat box on screen

	var e, replyE=null;
	var idS = "" + id;
	var divId = idS;
	if (eid != null)
		divId = idS + "-" + eid;		// userId-eventId  e.g. 12345-44432
	if (circleId != null)
		divId = circleId + "";

	var thisAction;
	if (circleId != null)
	{
		// circle & friends OR search result
		bGroupAction = true;
		if (bDisplaySearch)
			thisAction = actionSearch;
		else
		{
			// circle & friends
			thisAction = actionCircle;
			if (circleId == "0")
			{
				// my friends
				thisAction += actionCirFriend + "";
				while (thisAction.indexOf("circle") != -1)
					thisAction = thisAction.replace("circle", "friends");
			}
			else
			{
				// circle
				if (chatingCircle!=curCircleName) thisAction += actCir_chat;	// no join chat for circle
				thisAction = actCir_view + thisAction + actionCir;
				thisAction = thisAction.replace(/@PAGE@/, "\"cir_update.jsp?townId=" + circleId + "\"");
				thisAction = thisAction.replace(/@INVITE@/, "\"add_contact.jsp?type=case2&action=invite&tid=" + circleId + "\"");
				while (thisAction.indexOf("@UID@") != -1)
					thisAction = thisAction.replace(/@UID@/, circleId);
			}
			curCircleName = curCircleName.replace("'", "&#39;");
			while (thisAction.indexOf("@UNAME@") != -1)
				thisAction = thisAction.replace(/@UNAME@/, curCircleName);
		}
	}
	else
	{
		// individual users
		bGroupAction = false;
		if (divId == uid) {
			if (isCPM)
				thisAction = actionSelfCPM;
			else
				thisAction = actionSelf;
		}
		else
		{
			if (isCPM) {
				thisAction = actionsCPM + act_chat;
			}
			else if (chatObjIdS == "0" || chatingCircle!="") {
				thisAction = actions + act_chat;
			}
			else {
				if (chatingTarget.indexOf(idS) != -1)
					thisAction = actions;			// already chating with this guy
				else
					thisAction = actions + act_join;
			}
			
			//thisAction = thisAction.replace(/@UID@/, idS);
			while (thisAction.indexOf("@UID@") != -1)
				thisAction = thisAction.replace(/@UID@/, idS);			
			while (thisAction.indexOf("@UNAME@") != -1)
				thisAction = thisAction.replace(/@UNAME@/, uName);			
		}

		while (thisAction.indexOf("@PAGE@") != -1)
			thisAction = thisAction.replace(/@PAGE@/, "\"../ep/ep1.jsp\"");

		replyE = document.getElementById("reply-" + divId);
		if (replyE == null)
			replyE = document.getElementById("chatReply-" + divId);
	}

	if (divId == showingId)
	{
		// toggle the same person		
		e = document.getElementById(divId);		
		if (e.style.display == "block")
		{
			if (e.innerHTML.charAt(0) == ".")
			{
				// assume action list always start with a "."
				// currently showing action list, turn it off
				e.style.display = "none";
				e.innerHTML = "";
				if (replyE != null) replyE.style.display = "block";
			}
			else
			{
				// currently showing message: show action list
				e.innerHTML = thisAction;
				if (replyE != null) replyE.style.display = "none";
			}
		}
		else
		{
			// nothing is showing: show action list
			e.style.display = "block";
			e.innerHTML = thisAction;
			if (replyE != null) replyE.style.display = "none";
		}
	}
	else
	{
		// a new person is clicked: show action list
		e = document.getElementById(divId);
		e.innerHTML = thisAction;
		e.style.display = "block";
		if (showingId != "")
			document.getElementById(showingId).style.display = "none";
		if (replyE != null) replyE.style.display = "none";
		showingId = divId;		
	}

	setFrameHeight();
}

function showLookUp(circleId)
{
	// first close all other displays
	globalResetAction();
	window.parent.rename_chat(null, 1);		// remove the rename chat box on screen
	resetAction;
	
	var eL = document.getElementById("lookup");
	if (eL != null) {
		// just go search
		goSearchFriend(eL);
		return;
	}

	// now open search box
	showingId = "" + circleId;
	var e = document.getElementById(showingId);
	e.innerHTML = "<br><input id='lookup' type='text' class='formtext' size='30' value='Lookup'"
		+ " style='color:#777;padding-left:5px' onClick='if (this.value==\"Lookup\") this.value=\"\";' onkeypress='return onEnterSubmit(event);'>";
	e.style.display = "block";
	document.getElementById('lookup').focus();
	setFrameHeight();
}
function onEnterSubmit(evt)
{
	// this is for lookup
	var e = document.getElementById("lookup");
	if (e.value=='Lookup') e.value = '';

	var code = evt.keyCode? evt.keyCode : evt.charCode;
	if (code == 13)
	{
		goSearchFriend(e);
	}
	return;
}

function goSearchFriend(e)
{
	var s = trim(e.value);
	if (s.length<=0 || s=='Lookup') return;
	s = s.replace("+", "&");

	location = "ep_circles.jsp?circle=" + selectedCircleId + "&search=" + escape(s);
}


function globalResetAction()
{
	// NOTE: only reset the other frame, not myself
	if (frame == "parent" && window.frames[0]!=null)
		window.frames[0].resetAction();
	else	// if (frame == "child")
		window.parent.resetAction();
}

function action(opcode, id, chatId)
{
	// click friend's name to choose an action
	var e;
	if (showingId=="" && id!=null)
		showingId = id;			// the case of "Add Motto"
	else if (id != null)
	{
		// this is coming from reply or chatReply: need to reset all open display
		globalResetAction();
		resetAction();
		showingId = id;		// resetAction(0 wipe out my showingId
		e = document.getElementById("reply-"+id);
		if (e == null)
			e = document.getElementById("chatReply-"+id);
		if (e != null)
			e.style.display = "none"; 	// hide reply link
	}

	e = document.getElementById(showingId);
	var msg = "";
	var chatWithUid = "";
	
	// handle CPM cases for chat - need to go to another page to continue
	// CPM should go to the chat page
	if (isCPM) {
		switch (opcode)
		{
			case 4:
			case 5:
			case 6:
			case 8:
				//location = "../ep/ep_chat.jsp?op=" + opcode + "&showId=" + showingId + "&chatId=" + chatId;
				var h = 440, w = 330,
				l = window.screen.width - w - 30,
				t = window.screen.height - h - 60;
				if (chatId == undefined)
					chatWithUid = id;
				window.open('../ep/pop_chat.jsp?chatId=' + chatId + '&uid=' + chatWithUid, '',
						'scrollbars=no,menubar=no,' +
						'left=' + l + ',top=' + t + ',' +
						'height=' + h + ',width=' + w + ',' +
						'resizable=yes,toolbar=no,location=no,status=no');
				return;
			default:
				break;	// do nothing special
		}
	}

	switch (opcode)
	{
		case 1:		// post a note
			// show an edit box to enter note
			if (frame == "parent")
				blockEvent = 90;		// give 15 min. to type the note (1=10sec)
			else
				bCheckOnline = false;
			e.innerHTML = "<textarea id='note' class='formtext' wrap='logical' rows='5' style='width:95%;padding:2px'></textarea>"
				+ "<br>"
				+ "<input type='submit' value='Cancel' onClick='resetAction();' class='button_small'/>&nbsp;"
				+ "<input type='submit' value='Post' onClick='post_note(1);' class='button_small'/>&nbsp;"
				+ "<input type='submit' value='Post & Email' onClick='post_note(2);' class='button_small'/>"
				+ "<img src='../i/spacer.gif' width='1' height='18'/>";
			e.style.display = "block";
			document.getElementById("note").focus();
			return;
		case 2:		// say hello
			ajaxSendAction(showingId, act_hello);
			msg = "Your hello message(s) have been sent.";
			break;
		case 4:
			// request to start a chat: might have more than one chats to choose from.
			//window.parent.initChatWindow();
			start_chat(showingId, chatId);
			if (chatId==null)
				resetAction();
			return;
		case 5:
			// invite a user to join me on this current chat: simply send event
			join_chat(showingId);
			msg = "Your chat invitation(s) have been sent.";
			break;
		case 6:
			// start chat with circle
			start_chat(null, chatId, showingId);	// the showingId is circleId under ep_circle.jsp, for response, use chatid
			resetAction();
			return;
		case 8:
			// start chat with a chatId but no chatTarget (click on a specific chat item)
			start_chat(null, chatId, "");	// just have a chatId
			resetAction();
			return;
		case 7:
			// add or change my Motto
			e.innerHTML = "<textarea id='motto' class='formtext' wrap='logical' rows='3' style='width:95%;padding:2px'>" + myCurrentMotto + "</textarea>"
				+ "<br><input type='submit' value='Cancel' onClick='resetAction();' class='button_small'>&nbsp;"
				+ "<input type='submit' value='Save' onClick='save_motto();' class='button_small'>"
				+ "<img src='../i/spacer.gif' width='1' height='18'/>";
			e.style.display = "block";
			document.getElementById("motto").focus();
			setFrameHeight();
			return;
		case 9:
			// request ajax to show all chat list
			showChatNum = "all";		// change the default to all
			ajaxCheckEvent("0");		// force a retrieval of all items
			return;
		case 10:
			// request ajax to show only the most recent chat list (default)
			showChatNum = "default";	// change back to regular default
			ajaxCheckEvent("4");		// force a retrieval of 4 items
			return;
		case 11:
			// post a comment to a personal thought
			e.innerHTML = "<textarea id='note' class='formtext' wrap='logical' rows='4' cols='28' style='width:95%;padding:2px'></textarea>"
				+ "<br><input type='submit' value='Cancel' onClick='resetAction();' class='button_small'>&nbsp;"
				+ "<input type='submit' value='Post' onClick='post_note(3);' class='button_small'>&nbsp;"
				+ "<input type='submit' value='Post & Email' onClick='post_note(4);' class='button_small' style='width:78px'>";
			e.style.display = "block";
			document.getElementById("note").focus();
			return;
		case 12:
			// write email letter to circle members
			window.parent.location = "../memo/memo_1.jsp?tid=" + id;
			return;
		case 0:
			// feature not ready
			msg = "This feature is coming soon.";
			break;
/*		case 3:		// seasonal action (Nov:turkey)
			e.innerHTML =
				"<div class='plaintext'><font color='#00bb00'><b>Choose a turkey:</b></font></div>"
				+ "<div style='position:relative; border:solid 1px #333333; width: 200px; height:118px; left: 0; top: 0; overflow:auto;'>"
				+ "<table>"
				+ "<tr>"
				+ "<td><img id='obj1' class='x' src='../file/action/nov/turkey1.jpg' width='60' onmouseover='colorObj(1);' onclick='pickObj(1);'/></a></td>"
				+ "<td><img id='obj2' class='x' src='../file/action/nov/turkey2.jpg' width='60' onmouseover='colorObj(2);' onclick='pickObj(2);'/></a></td>"
				+ "<td><img id='obj3' class='x' src='../file/action/nov/turkey3.jpg' width='60' onmouseover='colorObj(3);' onclick='pickObj(3);'/></a></td>"
				+ "</tr>"
				+ "</table>"
				+ "</div>"
				+ "<div><input type='submit' value='Cancel' onClick='resetAction();' class='button_small'>&nbsp;&nbsp;"
				+ "<input type='submit' value='Send' onClick='sendSeason();' class='button_small'></div>";
			e.style.display = "block";
			setFrameHeight();
			return;*/
		default:
			break;
	}
	e.innerHTML = "<font color='#00bb00'>" + msg + "</font>";
}

function show_msg(msg, id)
{
	showingId = "" + id;
	var e = document.getElementById(id);
	e.innerHTML = "<font color='#00bb00'>" + msg + "</font>";
	e.style.display = "block";
}

function show_redirect(page, uid)
{
	var s = "";
	if (uid != null)
		s = "?uid=" + uid;
	if (frame == "parent")
		location = page + s;
	else if (frame == "child")
		window.parent.location = page + s;
}

function make_circle_frn(circleId, cirName)
{
	// the current showed circle will become my friends
	if (!confirm("Do you want to send connection requests to members of " + cirName + " to be your friends?"))
		return;
	location = "ep_circles.jsp?addAll=" + circleId;
}

function setFrameHeight()
{
	// dynamically set the parent window height based on the circle frame
	var parentDoc, childDoc;
	if (frame == "parent" && window.frames[0] != null)
	{		
		parentDoc = document;
		childDoc  = window.frames[0].document;
	}
	else
	{		
		parentDoc = window.parent.document;
		childDoc  = document;
	}
	var h = childDoc.body.clientHeight + 100;
	if (h <= 200) h = 1200;
	var e = parentDoc.getElementById("childFrame");
	if (e != null) {
		var px = "";
		if(!isMSIE) px = "px";
		e.style.height = h + px;
	}
}

function post_note(op)
{
	// op: 1=post note; 2=post & email
	// op: 3=comment thought; 4=comment thought & email
	// validate and submit posted note
	var e = document.getElementById(showingId);
	var ee = document.getElementById("note");
	var note = trim(ee.value);
	blockEvent = 1;				// give time to type the note (by this time the note is posting)
	bCheckOnline = true;		// for ep_circle.jsp
	if (note == "")
	{
		ee.value = "";
		return fixElement(ee, "Please enter some note in the text box before posting.");
	}
	else if (note.length > 350)
		return fixElement(ee, "Your note cannot be longer than 350 characters (" + note.length + ").");

	var bEmail = false;
	var s = "";
	if (op==2 || op==4)
	{
		bEmail = true;
		s = " and emailed";
	}
	if (op==1 || op==2)
		ajaxPostNote(showingId, note, null, null, null, bEmail, null);	//post note
	else
		ajaxPostNote(showingId, null, null, null, null, bEmail, note);	//post comment on thought

	e.innerHTML = "<font color='#00bb00'>Your note has been posted" + s + ".</font>";
}

function get_note(eid, label, op)
{
	// @ECC041808 Ajax retrieve a note event
	if (op == null) op = 0;
	blockEvent = 6;					// block event for 1 min. (1=10sec)
	ajaxGetNote(eid, label, op);
}

function save_motto()
{
	// validate and submit motto
	var e = document.getElementById(showingId);
	var ee = document.getElementById("motto");
	var motto = trim(ee.value);
	if (motto == "")
	{
		ee.value = "";
		return fixElement(ee, "Please enter your Motto in the text box before saving.");
	}
	else if (motto.length > 100)
		return fixElement(ee, "Your Motto cannot be longer than 100 characters (" + motto.length + ").");

	ajaxPostNote(showingId, null, motto, null, null, false, null);
	e.style.display = "none";

	e = document.getElementById("myMotto");
	e.innerHTML = motto;
	myCurrentMotto = motto;
}

function remove_evt(eId)
{
	ajaxSendAction(eId, "removeEvent");
	var e = document.getElementById(eId + "");
	if (e) e.style.display = "none";
}

function accept_friend(eId)
{
	ajaxSendAction(eId, "acceptFriend");	// it will accept the friend and remove the event
	var e = document.getElementById(eId + "");
	if (e) e.innerHTML = "<font color='#00bb00'>You have accepted the connection request.</font>";
}

function reject_friend(eId)
{
	ajaxSendAction(eId, "rejectFriend");	// it will reject the friend and remove the event
	var e = document.getElementById(eId + "");
	if (e) e.innerHTML = "<font color='#00bb00'>You have rejected the connection request.</font>";
}

function accept_circle(eId)
{
	ajaxSendAction(eId, "acceptCircle");	// it will accept the friend and remove the event
	var e = document.getElementById(eId + "");
	if (e) e.innerHTML = "<font color='#00bb00'>You have approved the Join Circle request.</font>";
}

function reject_circle(eId)
{
	ajaxSendAction(eId, "rejectCircle");	// it will accept the friend and remove the event
	var e = document.getElementById(eId + "");
	if (e) e.innerHTML = "<font color='#00bb00'>You have rejected the Join Circle request.</font>";
}

function accept_intro(eId)
{
	ajaxSendAction(eId, "acceptIntro");	// it will accept the friend and remove the event
	var e = document.getElementById(eId + "");
	if (e) e.innerHTML = "<font color='#00bb00'>You have accepted the introduction.</font>";
}

function reject_intro(eId)
{
	ajaxSendAction(eId, "removeEvent");	// simply remove the event
	var e = document.getElementById(eId + "");
	if (e) e.innerHTML = "<font color='#00bb00'>You have rejected the introduction.</font>";
}

function accept_introCir(eId)
{
	ajaxSendAction(eId, "acceptIntroCir");	// it will trigger the request to join circle and remove the event
	var e = document.getElementById(eId + "");
	if (e) e.innerHTML = "<font color='#00bb00'>You have accepted the recommendation. Your request to join the circle has been sent</font>";
}

function reject_introCir(eId)
{
	ajaxSendAction(eId, "removeEvent");	// simply remove the event
	var e = document.getElementById(eId + "");
	if (e) e.innerHTML = "<font color='#00bb00'>You have rejected the circle recommendation.</font>";
}

function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

function prtDebug(msg)
{
	// only for ep_omf_pda.jsp for now
	var e = document.getElementById('debug');
	if (e != null) {
		e.innerHTML = " - " + msg;
	}
}

///////////////////////////////////////////////////////////////////////////////////////
// TURKEY
//
/*
var colorId = 0;
function colorObj(id)
{
	if (colorId > 0)
		document.getElementById("obj" + colorId).style.border = "2px solid #3333aa";
	document.getElementById("obj" + id).style.border = "2px solid #ee0000";
	colorId = id;
}
function pickObj(id)
{
	document.getElementById("obj1").onmouseover = "";
	document.getElementById("obj2").onmouseover = "";
	document.getElementById("obj3").onmouseover = "";
	colorObj(id);
}

function sendSeason(id)
{
	var fname = "turkey" + colorId + ".jpg";
	ajaxPostNote(showingId, null, null, "turkey", fname, false, null);
	colorId = 0;
	document.getElementById(showingId).innerHTML = "<font color='#00bb00'>Your turkey has been sent.</font>";
}
*/