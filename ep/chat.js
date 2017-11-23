//
//	Copyright (c) 2007 EGI Technologies.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
// $Header: /cvsrepo/PRM/ep/chat.js,v 1.12 2008/01/13 01:47:09 edwardc Exp $
//
//	File:	chat.js
//	Author:	ECC
//	Date:	11/14/07
//  Description:
//      This js file deals with ajax calls for OMF chats.
//
//  Required:		ep_home.jsp for variable declaration.
//					meeting/ajax_utils.js for methods.
//					The expression at the end requires meeting/mtg_expr.js
//
//	Optional:
//
//	Modification:
//					@20150216ECC
//					I need to make the interactions between mobiles and browsers work. For Android
//					when submitting a text, it will tell the server its timestamp and the server will
//					take it.  As a result, Android can compare userId, msgText and timestamp to
//					decide if that chat msg should be displayed.  For Web browsers, it will append
//					a DEV_ID tag to the chat msg, this will be stored in the DB, but when mobile
//					(Android or iPhone) calls the webservice to retrieve the chats, I will remove
//					the DEV_ID tag before returning them.  For Web browser, it will receive the DEV_ID
//					tag and therefore can compare in this js file to decide if to display a chat msg or not.
//
/////////////////////////////////////////////////////////////////////

var reqSendChat;				// Ajax send chat
var reqChatAuto;				// auto check chat text from server

var DEV_ID = "";				// this browser session's ID (for web browser not to display my own posted chat)
var C_RESTART = 8;				// Restart time for auto check of chat
var C_SAFENET = -20;			// Safety net for the timer to auto start again if network somehow failed to return
var c_run = false;				// is auto check on?
var chatTimer;					// Timer till refresh
var autoChatTimerId;			// timer id for windows

var chatText = "Start chat ...<br>";
var myLabel="", myLabelFont;
var myName;
var lastChatId = -1;			// -1:before start chat; 0:i submitted the first chat text; >0:chat already goes on
var chatObjIdS = "0";
var chatingTarget = "";			// the persons I am chatting with 12345;22333; ...
var chatingCircle = "";			// the circle name if a chat session is going on
var omf_myColor = "";			// user choose a specific color

function ajaxSendChat(chatWithUid, text, op, circleId, projId)
{
	// start chat or send chat text over
	// op: start, check, submit, join, close, save_mtg, remove
	// chatWithUid: uid, circleId or 0 (my friend)
	if (window.XMLHttpRequest) {
		reqSendChat = new XMLHttpRequest(); 
	} else if (window.ActiveXObject) {
		reqSendChat = new ActiveXObject("Microsoft.XMLHTTP");
	}
	var url = "../servlet/OmfChatAjax";
	

	var param = "chatObjId=" + chatObjIdS + "&op=" + op;
	
	// I am actually starting a chat and the join chat oldID might be bad
	if (op == "start") chatObjIdS = "0";	// ECC: just to reset?

	if (chatWithUid != null)
		param += "&chatWith=" + chatWithUid;
	if (circleId != null)
		param += "&circleId=" + circleId;
	if (projId != null)
		param += "&projId=" + projId;
	if (text != null)
		param += "&text=" + encodeURI(text);
	param += "&lastChatId=" + lastChatId;
	if (omf_myColor != "")
	{
		param += "&color=" + omf_myColor;
		omf_myColor = "";
	}
	
	// debug option
	param += "&debug=0";	// just one level for now

	reqSendChat.open("POST", url, true);
	reqSendChat.setRequestHeader("Content-Type", "application/x-www-form-urlencoded; charset=utf-8");
	//reqSendChat.setRequestHeader("Content-Type", "text/plain;charset=UTF-8");
	if (op=="check" || op=="submit" || op=="start" || op=="save_mtg")
		reqSendChat.onreadystatechange = callbackSend;
	

	reqSendChat.send(param);
}

function callbackSend()
{
    if (reqSendChat.readyState == 4)
    {
        if (reqSendChat.status == 200)
        {
            // update the HTML DOM based on whether or not message is valid;
			parseXmlSend(reqSendChat);
			//if (chatTimer > SAFENET) // Restart if chatTimer > SAFENET, otherwise let timer() handle the restart
			//	chatTimer = RESTART;	
        }
    }
}

function parseXmlSend(l_req)
{	
	// start chat needs to get and remember the chat object id
	var chatArray, str;
	var bStartChat = false;

	if (chatObjIdS == "0")
	{		
		// start a chat
		// but there might be more than one chat satisfying the requested attendees
		chatArray = getResponseXml("ChatObjId", l_req);
		if (chatArray != null) {
			chatObjIdS = chatArray.join("");
		}
		else {
			// more than one chats.  Ask user to choose from a list.
			chatArray = getResponseXml("ChatList", l_req);
			if (chatArray != null)
				window.parent.setInnerHTML("chatList", chatArray);
			return;
		}
		
		
		bStartChat = true;
		start_chat_complete();
		
		// get circle name if it is a circle chat
		chatArray = getResponseXml("CircleName", l_req);
		if (chatArray != null)
			chatingCircle = chatArray.join("");
	}
	else if (chatObjIdS == "-1")
	{
		str = "?msg=We are not able to start your chat session now.  Please try later.";
		// reload the page
		window.location = "ep_home.jsp" + str;
		return;
	}

	// check if this is save meeting
	chatArray = getResponseXml("SavedMtgId", l_req);
	if (chatArray != null)
	{
		var midS = chatArray.join("");
		if (midS == "-1")
			str = "?msg=Request rejected.  Only the owner of the chat is authorized to save chat to a meeting event.";
		else
			str = "?msg=This chat has been moved to a meeting event.&mid=" + midS;
		// reload the page
		window.location = "ep_home.jsp" + str + "&showChatList=false";
		return;
	}

	// check new chat arrival: if has new text, save the last chat Id
	var newId = 0;
	str = getResponseXml("LastChatId", l_req);
	if (str != null) {		// shouldn't be null, but just in case don't want it to bomb
		str = str.join("");
		newId = parseInt(str);
	}


	if (newId>lastChatId || lastChatId<0)
	{
		// update the chat display
		var tagId;
		var newText = "";
		
		if (lastChatId < 0)
		{
			// just start chat, get all chat blocks at once and dump it into the chat box
			chatText = "";
			chatArray = getResponseXml("ChatBlocks", l_req);
			if (chatArray != null)
				newText = chatArray.join("");

			// set up my color
			chatArray = getResponseXml("MyChatLabel", l_req);
			if (chatArray != null)
			{
				myLabel = chatArray.join("");
				myLabelFont = myLabel.substring(0, myLabel.indexOf(">"));  //ECC: remove +1
			}
		}
		else
		{
			// either I have type some text or the chat has been going on
			// e.g. lastChatId=5; newId=8; copy from 6 to 8
//alert(lastChatId + ", " + newId);				
			for (i=lastChatId+1; i<=newId; i++)
			{
				// get the new chat texts
				tagId = "chat-" + i;
				chatArray = getResponseXml(tagId, l_req);
//alert("here: " + chatArray);		
				if (chatArray == null) continue;
				str = chatArray.join("");
				// if it is my own post [from the same device], then don't post again
				//if (lastChatId>=0 && (str.indexOf(myLabel)!=-1 || str.indexOf(myLabelFont+myName)!=-1))
				if (str.indexOf(DEV_ID) != -1)
					continue;			// ignore my own text
				newText += "<DIV>" + str + "</DIV>";
			}
		}

		// update the chat box
		var doc = window.parent.document;
		var e = doc.getElementById("chat");
		
		if (newText != "")
		{
			if (lastChatId >= 0)
				window.parent.playSound("sound1");
			chatText += newText;
			e.innerHTML = chatText;
			e.scrollTop = e.scrollHeight;
			e.scrollTop = e.scrollHeight;		// IE 6 has a bug req me to call this twice
		}
		
		// remember the last chat id
		lastChatId = newId;
		
		// Done update chat text with new posts
		//////////////////////////////////////////////////////
		
		// update chat name
		chatArray = getResponseXml("ChatName", l_req);
		if (chatArray != null)
		{
			str = chatArray.join("");
			e = doc.getElementById("chatName");
			e.innerHTML = str;
		}
		
		// update chat users
		chatArray = getResponseXml("ChatUsers", l_req);
		if (chatArray != null)
		{
			str = chatArray.join("");
			e = doc.getElementById("chatUser");
			if (chatingCircle == null) chatingCircle = "";
			if (chatingCircle != "") chatingCircle += ": ";
			e.innerHTML = chatingCircle + str;
			//e.innerHTML = "<b>" + chatingCircle + " Chat users</b> (" + str.split(";").length + "): " + str;
		}
	}
		
	// for Start Chat or Finish submit chatText (c_run==false), start the timer for auto check on main window
	if (frame!="parent" || c_run==false)
		window.parent.chat_init();

	// if I am calling from child frame, I need to pass the latest info to parent, and vice versa
	if (bStartChat)
	{
		if (frame != "parent")
			e = window.parent;
		else
			e = window.frames[0];
		e.initChatValues(chatObjIdS, lastChatId, chatingTarget, chatText, myLabel, chatingCircle);
	}
}

function chat_init()
{
	chatTimer = C_RESTART;
	// ajaxCheckChat();		don't call now, let the c_timer() call when time's up
	c_run = true;
	c_timer();
	
	// setup DEV_ID
	if (DEV_ID == "") {
		DEV_ID = "<DEV_ID=" + Math.floor(Math.random()*10000) + "/>"
	}
}

function c_timer()
{
	chatTimer--;
	// was going to use evtTimer <= 0 but the calls may perform twice in a row
	// evtTimer < -15 is a safety net in case the first evtTimer == 0 was missed
	if (chatTimer <= 0)
	{
		chatTimer = C_RESTART;
		if (c_run) {
			stop_c_timer();
			ajaxSendChat(null, null, "check");
		}
	}

	if (chatTimer <= C_SAFENET)
		chatTimer = C_RESTART;
	
	if (c_run)
		autoChatTimerId = setTimeout("c_timer();", 1000);
}

function stop_c_timer()
{
	c_run = false;		// stop auto check
	clearTimeout(autoChatTimerId);
}

//
///////////////////////////////////////////////////////////////////////////////////////////////
//
function start_chat(chatWithUid, chatId, circleId, projId)
{
	// request to start chat: might have more than one chats to choose from.
	// send an ajax event to server to notify for the chat session
	// In case of responding to a chat request, chatId is the one I want to start
	
	var idx = -1;

	if (circleId == null)
	{
		if (chatWithUid != null)
		{
			chatingTarget = "" + chatWithUid;
			if ((idx=chatingTarget.indexOf("-")) != -1)
				chatingTarget = chatingTarget.substring(0,idx);
		}
		else
			chatingTarget = null;
		chatingCircle = "";
	}
	else if (circleId.indexOf("-") != -1)
	{
		circleId = null;
	}

	// re-init the values (might have been chatting before this time)
	chatText = "Start chat ...<br>";
	lastChatId = -1;
	
	if (chatId == null)
		chatObjIdS = "0";
	else
		chatObjIdS = chatId;


	// send start chat event to server
	if (circleId == null)
		ajaxSendChat(chatingTarget, null, "start", null, projId);
	else
		ajaxSendChat(null, null, "start", circleId);
}

function start_chat_complete()
{
	// display the chat window on ep_home.jsp or ep_chat.jsp
	window.parent.toggle_chat_list("Hide");		// this will close the display
	window.parent.playSound("sound2");
	window.parent.scrollTo(0,0);

	var doc = window.parent.document;
	
	var e = doc.getElementById("chat");
	if (chatText != "")
		e.innerHTML = chatText;

	// display the chat area
	e = doc.getElementById("chatParent");
	e.style.display = "block";
	
	// hide chat list
	e = doc.getElementById("chatList");
	e.style.display = "none";

	// ECC: need the below call because ep_omf.jsp's chatObjIdS is not updated
	// with the newly created chatObjIdS
	window.parent.copyChatIdToParent(chatObjIdS);	// called by ep_omf.jsp and pop_chat.jsp


	e = doc.getElementById("chatInput");
	e.value = "";
	e.focus();e.focus();	// double call for IE to work
}

function join_chat(joinChatUid)
{
	chatingTarget += ";" + joinChatUid;
	ajaxSendChat(joinChatUid, null, "join");
}

/**
* Prevents the enter key to automatically select submit
*/
function onEnterChatText(evt) {
	var code = evt.keyCode? evt.keyCode : evt.charCode;
	if (code == 13)
	{	
		var doc = window.parent.document;
		var e = doc.getElementById("chatInput");
		var text = trim(e.value);
		e.value = "";				// reset input textbox
		if (text.length <= 0)
			return;
		stop_c_timer();

		// append my input immediately
		var today = new Date();
		hh = checkPos(today.getHours());
		mm = checkPos(today.getMinutes());
		var timeS = " <span class='hist_date'>(" + hh + ":" + mm + ")</span>:&nbsp;"
		text = text + DEV_ID;			// append the DEV_ID to identify myself in the posted chat
		if (text.indexOf("/me")!=-1)
		{
			text = text.replace("/me", myName);
			chatText += "<DIV>" + myLabelFont + timeS + text + "</font></DIV>";
			text = "@@" + text;
		}
		else {
			chatText += "<DIV>" + myLabel + timeS + text + "</DIV>";		// add </font> because I only remember the front part now
		}
		e = doc.getElementById("chat");
		e.innerHTML = chatText;
		window.parent.playSound("sound1");
		e.scrollTop = e.scrollHeight;
		

		// send text to Ajax
		ajaxSendChat(null, text, "submit");
		return;
	}
}

function closeChat(saveMeeting)
{
	if (saveMeeting==true
		&& !confirm("You are about to move this chat conversation into a new meeting event. "
			+ "You can then click on the meeting to review it.  Would you like to proceed?"))
		return;		// do nothing

	stop_c_timer();
	
	window.parent.playSound("sound3");
	document.getElementById("chatParent").style.display = "none";
	document.getElementById("chat").value = "";
	document.getElementById("chatInput").value = "";
	
	// send Ajax
	if (saveMeeting == true)
		ajaxSendChat(null, null, "save_mtg");
	else
		ajaxSendChat(null, null, "close");

	// re-initialize the static values on parent
	chatText = "Start chat ...<br>";
	lastChatId = -1;
	chatObjIdS = "0";
	chatingTarget = "";
	
	// copy init values to child
	var e;
	if (window.frames[0] != null)
		e = window.frames[0];
	else
		e = window.parent;
	e.initChatValues(chatObjIdS, lastChatId, chatingTarget, chatText, null, null);
	resetAction();		// show the "Join chat" reply link
	globalResetAction();

	// show the chat list
	if (!saveMeeting)
		toggle_chat_list("Show");
}

function remove_chat(chatId)
{
	// delete this chat
	if (!confirm("Continue on this action will remove the chat.  Do you want to continue?"))
		return;
	chatObjIdS = chatId + "";
	ajaxSendChat(null, null, "remove");
	chatObjIdS = "0";
	var e = document.getElementById("chat-" + chatId);
	e.innerHTML = "";	// removed
}

function rename_chat(chatId, op)
{
	// op: 0=show boxes; 1=cancel; 2=save new name
	var e;
	if (op==null || op==0)
	{
		// show input box to allow renaming
		globalResetAction();
		resetAction();

		var oldName = document.getElementById("chatName-" + chatId).innerHTML;
		e = document.getElementById("chat-" + chatId);
		e.innerHTML += "<div id='changeChatName'>Rename chat:<br/>"
			+ "<input type='text' id='nameInput' class='formtext' style='padding:2px' size='40' value=\"" + oldName + "\"><br/>"
			+ "<input type='submit' value='Cancel' onClick='rename_chat(null, 1);' class='button_small'>&nbsp;"
			+ "<input type='submit' value='Save' onClick='rename_chat(" + chatId + ",2)' class='button_small'>&nbsp;"
			+ "</div>";
		document.getElementById("nameInput").focus();
	}
	else if (op == 1)
	{
		// cancel
		e = document.getElementById('changeChatName');
		if (e != null)
			e.parentNode.removeChild(e);		// remove the last one there
	}
	else
	{
		// actually rename it
		var newName = document.getElementById("nameInput").value;
		e = document.getElementById("chatName-" + chatId);
		e.innerHTML = newName;
		rename_chat(null, 1);		// remove the boxes on screen
		chatObjIdS = chatId + "";
		ajaxSendChat(null, newName, "rename");
		chatObjIdS = "0";
	}
	
}

function saveChatToMeeting()
{
	stop_c_timer();
}

function initChatValues(chatId, lastId, chatUid, cText, label, cirName)
{
	// this is called by child frame to parent frame for setting the values at start chat
	// also called by parent to child at closeChat time
	chatObjIdS = chatId;
	lastChatId = lastId;
	chatingTarget = chatUid;
	chatText = cText;
	myLabel = label;
	chatingCircle = cirName;
}

function getChatIds()
{
	// parent's function called by child frame to copy the chat ids from parent to child if it is going on
	window.frames[0].setChatIds(chatObjIdS, chatingTarget);
}

function setChatIds(chatId, uId)
{
	chatObjIdS = chatId;
	chatingTarget = uId;
}

//ECC: above caller on why this is needed - pass chatObjIdS from child to here (parent)
function copyChatIdToParent(idS)
{
	chatObjIdS = idS;
}

function checkPos(i)
{
    if (i < 10) {
        i = "0" + i;
    }
    return i;
}

