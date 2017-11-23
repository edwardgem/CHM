//
//	Copyright (c) 2006 EGI Technologies.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
// $Header$
//
//	File:	$RCSfile$
//	Author:	Allen G Quan
//	Date:	$Date$
//  Description:
//      This js file deals with ajax calls to servlets. The various 
//		methods helps the ajax functions get their required variables
//		and pass it to the servlets. A method called parseXml() will
//		read the returned XML and determine what needs to be refreshed.
//
//  Required:
//
//	Optional:
//
//	Modification:
//		@AGQ083006	Changed REGEX into global variable and updated REGEX to
//					reflect java
//					Sets the current cursor position within FCKeditor
//		@AGQ091506	Cannot change stop invite after timer has started
//		@ECC092806	Support send expression.
//
//		@AGQ092806	Retreived characters before and after cursor position
//		@AGQ100606	ajaxMFCCheck and ajaxMFCClearOnline calls the same servlet
//					servlet may be overwritten and ignores previous call.
//		@ECC101106	Input queue.
//
//		@AGQ101106	Force user to reload mtg notes
//		@AGQ101606	Removed all utils to ajax_util.js file
//		@ECC100507	check and show if user is typing in the chat box.
//
/////////////////////////////////////////////////////////////////////
var REGEX = "((\\s)+(&(nbsp|NBSP);))+|^(<(p|P)>((&(nbsp|NBSP);)|(\\s)|(<(br|BR)\\s?/?>))*</(p|P)>(\\s)*)+|(<(p|P)>((&(nbsp|NBSP);)|(\\s)|(<(br|BR)\\s?/?>))*</(p|P)>(\\s)*)+$|^((<(br|BR)\\s?/?>)|(&(nbsp|NBSP);)|\\s)+|((<(br|BR)\\s?/?>)|(&(nbsp|NBSP);)|\\s)+$";
var isMozilla = (navigator.userAgent.toLowerCase().indexOf('gecko')!=-1) ? true : false;

var req;					// ajax variable 
var reqAuto;				// ajax variable for autoSave
var mtgTimer;				// Timer till refresh
var RESTART = 30;			// Restart time 30s for auto save/load see @AGQ092906
var SAFENET = -131;			// Safety net for the timer to auto start again if network somehow failed to return
var run = false;			// Is auto refresh/save running?
var isRunning = false;		// confirmNullNotes; Is 'checking for null Meeting Notes' running?
var isRun = -1;				// 0 = attendee, 1 = recorder 
var debug;					// debug mode for testing
var parameters = null;		// used for parameters in url or POST
var isMtgNotesNull = true;	// Check to see if notes were previously null
var HOSTS;
var lastbText = "";			// @ECC100507
var checkChatTextCount = 5;	// @ECC100507

// Variables to store the version of attendee's page
var ADCOUNT = 0;
var ATCOUNT = 0;
var MNCOUNT = 0;
var AICOUNT = 0;
var DCCOUNT = 0;
var ISCOUNT = 0;
var INCOUNT = 0;
var UDCOUNT = 0;
var flag = -1;

// Index
var ADIDX = 0;
var ATIDX = 1;
var MNIDX = 2;
var AIIDX = 3;
var DCIDX = 4;
var ISIDX = 5;
var INIDX = 6;
var UDIDX = 7;
var flagIDX = 8; // Flag index is always the last one

var autoSaveTimer; // the SetTimeOut function

// Invite Participants for Feedback
var reqmfc;
var reqmfcFeedback;
var mfcTimer;
var mfcRESTART = 1;
var isParticipant = false;
var isOn = false;
var mfcTimeout = null;
var facilitator = argItems("run");
var position = null;
var charBefore = "";
var charAfter = "";
var redirect = true;	// Determines if I can redirect
// Used to determine is this is the beginning of a chat phase (so users will retrieve the open & close tag for chat session)
// This is introduced to prevent breaking the current usage of redirect.
var preRedirect = false;	
var SAFENETMFC = -5;	// Safety net for MFC in case direct response after submitting text does not return

var clearOnlineRs = 30;
var clearOnlineCt = clearOnlineRs;
var reqmfcSendExpr;		// @ECC092806 Send expression
var exprIdx = -1;		// @ECC092806 last received expression index (initialize to -1 to get from head)

var reqmfcSendQueue;	// @ECC101106 input queue

var isClicked = false;

// Chat enhancement
var chatColor = null;			// Stores the color of the current
var svrTime = null; 	// Stores the server time in milliseconds
var clientTime = null;			// Stores the local machines time when server time is received
var findColor = false;


function setClicked(clicked) {
	isClicked = clicked;
}
/**
*	Checks to see if Invite Participants for Feedback is turned on
*/
function ajaxMFCCheck() {
	mfcTimer = -1;
	var r = argItems("mid");
	var fac = argItems("run");
	var exprIdxS = "&exprIdx=" + exprIdx;		// @ECC092806 last received expression index
	if (window.XMLHttpRequest) {
       reqmfc = new XMLHttpRequest(); 
   } else if (window.ActiveXObject) {
       reqmfc = new ActiveXObject("Microsoft.XMLHTTP");
   }
	
	var url = HOSTS + "/servlet/PrmMtgParticipants?mid=" + escape(r[0]) + exprIdxS;
	if (isParticipant)
		url+="&revoke=revoke";
	if (isRun==1)
		url+="&isRun=isRun";
	if (fac == "true")
		url+="&run=true";
	if (chatColor != null)
		url+="&hasColor=true";
	reqmfc.open("GET", url, true);
	reqmfc.onreadystatechange = callbackMFC;
	reqmfc.send(null);
		
	// @ECC100507 check if user is entering chat text
	if (isOn && checkChatTextCount--<=0)
	{
		checkChatTextCount = 5;	// put this on top cause this method would get call multiple time
		var bText = document.getElementById("fbText").value;		
		bText = trim(bText);
		if (bText.length>0 && bText!=lastbText)
		{
			ajaxMFCSendExpr("typing", screenName);	// screenName is the user's screenName (def in mtg_live.jsp)
			lastbText = bText;
		}
	}
}

function ajaxMFCClearOnline() {
	var r = argItems("mid");
	if (window.XMLHttpRequest) {
		reqmfc = new XMLHttpRequest(); 
	} else if (window.ActiveXObject) {
		reqmfc = new ActiveXObject("Microsoft.XMLHTTP");
	}
	clearOnlineCt = clearOnlineRs
	var url = HOSTS + "/servlet/PrmMtgParticipants?mid=" + escape(r[0]) + "&clearOnline";
	reqmfc.open("GET", url, true);
	reqmfc.send(null);
}

function ajaxMFCSubmit() {
	mtgTimer = SAFENET-1;
	var r = argItems("mid");	
	var bText = document.getElementById("fbText").value;
	bText = trim(bText);
	if (bText.length > 0) {
		if (window.XMLHttpRequest) {
	       reqmfcFeedback = new XMLHttpRequest(); 
	   } else if (window.ActiveXObject) {
	       reqmfcFeedback = new ActiveXObject("Microsoft.XMLHTTP");
	   }
		
	   var chatIdxStr = "";		// @ECC100606
	   if (!redirect && !preRedirect)
			chatIdxStr = "&chatIdx=" + MNCOUNT;
		
		var url = HOSTS + "/servlet/PrmMtgParticipants?mid=" + escape(r[0]) + chatIdxStr;
		
		// Clear the text box
		var fbText = document.getElementById("fbText");
		if (fbText)	fbText.value = "";

		if ((chatColor!=null) && !redirect && !preRedirect) { // Paste text into div under similar condition
			// Paste Text into screen		
			var divTag = findChatDivTag();
			divTag.innerHTML+=createChatLine(bText);	
			element = document.getElementById("meetingNotes");
			scrollToNewText(element, null);
		}
		reqmfcFeedback.open("POST", url, true);
		reqmfcFeedback.onreadystatechange = callbackMFCFB;
		reqmfcFeedback.setRequestHeader("Content-Type", "application/x-www-form-urlencoded; charset=utf-8;");
		reqmfcFeedback.send("bText="+ URLencode(bText));
	}
}

function createChatLine(bText) {
	var chatLine;
	var clientTimeNow = (new Date()).getTime();
	var clientTimeThen = clientTime.getTime();
	var diff = clientTimeNow - clientTimeThen;
	var right_now = new Date(svrTime + diff);
	var hours = right_now.getHours();
	var minutes = right_now.getMinutes();
	if (hours > 12)
		hours = hours - 12;
	if (hours < 10)
		hours = "0"+hours;
	if (minutes < 10) 
		minutes = "0"+minutes;
	
	chatLine="<div>";
	chatLine+="<font color='#555555'>["+hours+":"+minutes+"]</font> <span style='color:"+chatColor+"; font-weight: normal;'>";
	chatLine+=screenName;
	chatLine+=": </span><span style='color: black; font-weight: normal;'>";
	chatLine+=bText;
	chatLine+="</span></div>";
	return chatLine;
}

// @ECC092806 send expression
function ajaxMFCSendExpr(id, str) {
	var r = argItems("mid");
	if (window.XMLHttpRequest) {
		reqmfcSendExpr = new XMLHttpRequest(); 
	} else if (window.ActiveXObject) {
		reqmfcSendExpr = new ActiveXObject("Microsoft.XMLHTTP");
	}
	var url = HOSTS + "/servlet/PrmMtgParticipants?mid=" + escape(r[0]);
	reqmfcSendExpr.open("POST", url, true);
	reqmfcSendExpr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
	reqmfcSendExpr.send("id="+id+"&str="+str);
	if (exprIdx < 0) exprIdx = -2;				// just to make sure I include the one I just sent
}

// @ECC101106 input queue
function ajaxMFCSendQueue(uid, bRemove) {
	mtgTimer = SAFENET-1;
	var r = argItems("mid");
	if (window.XMLHttpRequest) {
		reqmfcSendQueue = new XMLHttpRequest(); 
	} else if (window.ActiveXObject) {
		reqmfcSendQueue = new ActiveXObject("Microsoft.XMLHTTP");
	}
	var url = HOSTS + "/servlet/PrmMtgParticipants?mid=" + escape(r[0]);
	reqmfcSendQueue.open("POST", url, true);
	reqmfcSendQueue.onreadystatechange = callbackMFCIN;
	reqmfcSendQueue.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
	
	var sendParam = "qUid="+uid;
	if (bRemove) sendParam += "&removeQ=true";		// remove the uid from the queue
	reqmfcSendQueue.send(sendParam);
}

function callbackMFCIN() {	// @ECC101106 callback for enqueue to input queue
    if (reqmfcSendQueue.readyState == 4) {
        if (reqmfcSendQueue.status == 200) {
            // update the HTML DOM based on whether or not message is valid;
			parseXmlMFCIN(reqmfcSendQueue);
			// Restart the timer to retrieve user's text input
			mtgTimer = RESTART;
        }
    }
}

function parseXmlMFCIN(l_req) {	// @ECC101106
	var time = getResponseXml("counts", l_req);
	if (time != null && isRun == 0)	{
		// Check if value did not return
		var temp = time[flagIDX];
		if(temp != null && temp.length > 0) {
			INCOUNT = time[INIDX];
		}
    }
	updateInputQueue(getResponseXml("inputQString", l_req)); 	// update input queue
}

function callbackMFCFB() {
    if (reqmfcFeedback.readyState == 4) {
        if (reqmfcFeedback.status == 200) {
            // update the HTML DOM based on whether or not message is valid;
			parseXmlMFCFB(reqmfcFeedback);
			// Restart the timer to retrieve user's text input
			mtgTimer = RESTART;
        }
    }
}

function parseXmlMFCFB(l_req) {
	updateLastUpdateMFC(getResponseXml("counts", l_req));
	setElementInnerHTML("meetingNotes", getResponseXml("meetingNotes", l_req)); // Sets Meetings Notes
}

function callbackMFC() {
    if (reqmfc.readyState == 4) {
        if (reqmfc.status == 200) {
            // update the HTML DOM based on whether or not message is valid;
			parseXmlMFC(reqmfc);	
			
			// @AGQ091806
			if (facilitator=="true") {
				clearOnlineCt--;
				if (clearOnlineCt == 0) {	
					ajaxMFCClearOnline();
				}
				if (clearOnlineCt < -clearOnlineRs) {
					clearOnlineCt = clearOnlineRs;
				}
			}
			
			mfcTimer = mfcRESTART;
        }
    }
}

// @ECC092806 Received and parse the expressions
var justStartChat = false;
function parseXmlMFC(l_req) {
	var isRedirect = checkRedirect(getResponseXml("url", l_req), getResponseXml("alertMessage", l_req));
	if (!isRedirect) {
		// @AGQ101106 Update counter to force user to reload mtg notes
		updateLastUpdateMFCCheck(getResponseXml("counts", l_req));
		var prevOn = isOn;	
		if (chatColor==null) {
			chatColor = getResponseXml("chatColor", l_req);		
			svrTime = parseInt(getResponseXml("svrTime", l_req));
			clientTime = new Date();
		}
		
		var tempS = getResponseXml("isOn", l_req);
		if (tempS != null) isOn = (tempS.join("")=="true");
		    
	    // @ECC092806 always check for expression
	    if ( (rc = recvExpr(getResponseXml("exprString", l_req))) >= 0)	{	// Received expressions
			exprIdx = rc;
		}
		
		// Shorten the time to display feedback near instant time
		if (!prevOn && isOn) {
			RESTART = 1;
			mtgTimer = 1;
			justStartChat = true;
			// @AGQ101006 Reloads note to ensure invite chat quotes are inserted
			//preRedirect = true;
			redirect = false;
		}
		// Feedback is turned off
		else if (prevOn && !isOn) {
			isParticipant = false;
			//clearTimeout(mfcTimeout);
			// @AGQ091506						
			//if (facilitator)
				//document.getElementById("inviteInput").disabled = true;
			turnOffMFC(l_req);
		}
		
		if (isOn) {
			tempS = getResponseXml("isParticipant", l_req);
			var prevParticipant = isParticipant;
			if (tempS != null) isParticipant = (tempS.join("")=="true");
			
			if (!prevParticipant && isParticipant) {
				// start create a text box
				if (mfcTimeout != null) {
					clearTimeout(mfcTimeout); 
					displayTimer(null);
					mfcTimeout = null;
				}
				var feedbackBox = document.getElementById("feedback");
				feedbackBox.style.display = "block";
				setFocus("fbText");
				playSound("sound2");
			}
			else if (prevParticipant && !isParticipant) {
				isParticipant = false;
				//clearTimeout(mfcTimeout);	
				// @AGQ091506
				//if (facilitator)
					//document.getElementById("inviteInput").disabled = true;	
				turnOffMFC(l_req);
			}
			else
				return;
		}
		
	}
}

function turnOffMFC(l_req) {
	var revokeTime = getResponseXml("revokeTime", l_req);
	if (revokeTime!=null) revokeTime = revokeTime.join("");
	
	checkRevokeTime(l_req, revokeTime);
}

function checkRevokeTime(l_req, time) {
	if (time=="null" || time==null) time = 0;
	time--;
	if (time <= 0) {
		var feedbackBox = document.getElementById("feedback");
		feedbackBox.style.display = "none";
		playSound("sound3");
		displayTimer("");
		isParticipant = false;
		mfcTimeout = null; // Since mfcTimeout is null, page can now be redirected
		// @AGQ091506
		//if (facilitator)
			//document.getElementById("inviteInput").disabled = false;
		// Performs redirect for facilitator w/o breaking previous codes
		if (!isOn) {
			// Stops the current timer and starts it back at 1 seconds to redirect the page 
			stopAutoSaveTimer(); 
			RESTART = 5; // @AGQ092906
			mtgTimer = 1;
			run = true;
			redirect = true;
			timer();
		}
	}
	else {
		displayTimer(time+"");
		mfcTimeout = setTimeout(function () { checkRevokeTime(l_req, time); }, 1000);
	}
}

function displayTimer(text) {
	var spanBox = document.getElementById("timeLeft");
	if (text!=null && text.length > 0) {
		spanBox.innerHTML = "<span class='formtext' style='color: red'>Input from participants closing in "+text+" seconds</span>";
	}
	else {
		spanBox.innerHTML = "";
	}
}

/**
* Refreshes the meetings notes content
* @param save true - clicked; false - autosave
*/
function ajaxMtgNotes(save) {
   var r = argItems("mid");
   if (window.XMLHttpRequest) {
       reqAuto = new XMLHttpRequest(); 
   } else if (window.ActiveXObject) {
       reqAuto = new ActiveXObject("Microsoft.XMLHTTP");
   }
   
   // Attendee: sends counters to check for updated meeting notes
   var chatIdxStr = "";		// @ECC100606
   if (!redirect && !preRedirect)
		chatIdxStr = "&chatIdx=" + MNCOUNT;
	// @AGQ101106
	if (preRedirect)
		chatIdxStr += "&force=true";
   
   if (isRun == 0) {
		mtgTimer = -1;
		var count = "&ADCOUNT="+ADCOUNT+"&ATCOUNT="+ATCOUNT+"&MNCOUNT="+MNCOUNT
			+"&AICOUNT="+AICOUNT+"&DCCOUNT="+DCCOUNT+"&ISCOUNT="+ISCOUNT+chatIdxStr+"&INCOUNT="+INCOUNT;
		var url = HOSTS + "/servlet/PrmLiveMtg?mid=" + escape(r[0]) + count + "&debug=" + escape(debug[0]);
		
		reqAuto.open("GET", url, true);
		reqAuto.onreadystatechange = callbackAuto;
		reqAuto.send(null);
   }
   // Recorder: submits meeting notes
   else if (isRun == 1) {
		var oEditor = FCKeditorAPI.GetInstance('mtgText');
		var bText = oEditor.EditorDocument.body.innerHTML;
		var conf = confirmNullNotes(bText, save);
		if (conf) {
			// Remove saved message after autoSave
			var messageSpan = document.getElementById("time");
			if(messageSpan && !save && messageSpan.innerHTML.length > 0) {
				messageSpan.innerHTML = "";
			}
			mtgTimer = -1;
			var url = HOSTS + "/servlet/PrmLiveMtg?mid=" + escape(r[0]) + "&save=" + save + "&debug=" + escape(debug[0]);
			reqAuto.open("POST", url, true);
			//document.getElementById("debug").innerHTML += "New Auto Save " + Date() + "<br>";
			if (save)
				disableButton(document.getElementById("saveMtgNotes"));
			reqAuto.onreadystatechange = callbackAuto;
			
			// required to perform POST
			reqAuto.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
			reqAuto.send("bText=" + URLencode(bText) + "&" + getAttendeeList());
		}
	}
	else {
		// could not find isRun
		alert("Error: cannot find isRun tag on saving notes");
	}
}

/**
* Add attachments
*/
function ajaxAddAT() {
// @AGQ040406
	if (multi_selector.count == 1)
	{
		fixElement(document.getElementById("my_file_element"), "To add a file attachment, click the Browse button and choose a file to be attached, then click the Add button.");
		return false;
	}
	else {
		ajaxSaveAttendee();
		document.getElementById("SaveAttendee").value = false;
// @AGQ040406a		
		isOkay = validation()
		if (isOkay)
			stopAutoSaveTimer();
		return isOkay;
	}
}

/**
* Delete attachments
*/
function ajaxDeleteAT(fname) {
	var s = "This action is non-recoverable. Do you really want to delete the attachment file?";
	if (confirm(s)) {
		var r = argItems("mid");
		if (window.XMLHttpRequest) {
			req = new XMLHttpRequest(); 
		} else if (window.ActiveXObject) {
			req = new ActiveXObject("Microsoft.XMLHTTP");
		}
		url = HOSTS + "/servlet/PrmFileAttachment?mid=" + escape(r[0]);
		req.open("POST", url, true);
		req.onreadystatechange = callbackAT;
		// required to perform POST
		req.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
		req.send("fname=" + escape(fname) + "&" + getAttendeeList());
	}
}

/**
* Save attendee checkboxes
*/
function ajaxSaveAttendee() {
	var r = argItems("mid");
	if (window.XMLHttpRequest) {
		req = new XMLHttpRequest(); 
	} else if (window.ActiveXObject) {
		req = new ActiveXObject("Microsoft.XMLHTTP");
	}
	url = HOSTS + "/servlet/PrmFileAttachment?mid=" + escape(r[0]);
	req.open("POST", url, true);
	// required to perform POST
	req.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
	req.send(getAttendeeList());
	if (navigator.userAgent.indexOf("MSIE") > -1)
		document.getElementById("SaveAttendee").value = true;
	else
		document.getElementById("SaveAttendee").value = false;
	return true;
}

/**
* Sets the current cursor position within the textarea
* @AGQ083006
*/
function setCursorIndex() {
	var oEditor = FCKeditorAPI.GetInstance('mtgText');
	var posSet = "%OMF%"
	var tempStore = oEditor.EditorDocument.body.innerHTML;
	//oEditor.InsertHtml(posSet);
	
	var re = new RegExp(REGEX, "g");
	//var trimmedNotes = (oEditor.EditorDocument.body.innerHTML).replace(re, "");
	var trimmedNotes = tempStore.replace(re, "");	// ECC
	var length = trimmedNotes.length;

	//var i = trimmedNotes.indexOf(posSet);
	var i = tempStore.length;						// ECC: always go to the end

	//oEditor.EditorDocument.body.innerHTML = tempStore;
	oEditor.Focus();
	position = i;
	// @AGQ092806
	var prevI = i-1;
	var nextI = i+(posSet.length);
	if (prevI >= 0)
		charBefore = trimmedNotes.charAt(prevI);
	if (nextI < length)
		charAfter = trimmedNotes.charAt(nextI);
	// ECC: get to here when start chat session
}

/**
* Add attendee
*/
function ajaxAddAD() {
	var r = argItems("mid");
	if (window.XMLHttpRequest) {
		req = new XMLHttpRequest(); 
	} else if (window.ActiveXObject) {
		req = new ActiveXObject("Microsoft.XMLHTTP");
	}
	//var bText = ((document.getElementById('mtgText__Frame').contentWindow.document.getElementById('eEditorArea')).contentWindow.document.body.innerHTML);
	var oEditor = FCKeditorAPI.GetInstance('mtgText');
	var bText = oEditor.EditorDocument.body.innerHTML;
	var adSelect = document.getElementById('adNames');
	if (adSelect.selectedIndex != 0) {
		mtgTimer = -1;
		var adId = adSelect.options[adSelect.selectedIndex].value;
		adSelect.options[adSelect.selectedIndex] = null;
		adSelect.selectedIndex = 0;
		var url;
		url = HOSTS + "/servlet/PrmLiveMtg?mid=" + escape(r[0]) + "&save=" + true + "&debug=" + escape(debug[0]) + "&newAttendee=" + escape(adId);
		req.open("POST", url, true);
		disableButton(document.getElementById("addNewAD"));
		req.onreadystatechange = callbackAD;
		// required to perform POST
		req.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
		req.send("bText=" + URLencode(bText) + "&" + getAttendeeList());
	}
}

/**
* User changed Project. Update list for New Attendees, Responsible, Coordinator, and Issue.
*/
function changeAcProject() {
	var r = argItems("mid");
	var select = document.getElementById("pjNames");
	var projId = select.options[select.selectedIndex].value;
	if (window.XMLHttpRequest) {
		req = new XMLHttpRequest(); 
	} else if (window.ActiveXObject) {
 		req = new ActiveXObject("Microsoft.XMLHTTP");
	}
	var url = HOSTS + "/servlet/PrmAcManager?mid=" + escape(r[0]) + "&projId=" + escape(projId);
	req.open("GET", url, true);
	req.onreadystatechange = callback;
	req.send(null);
}

/**
* Submit Action Item, Decision, or Issue
*/
function ajaxSubmitAC() {
	disableButton(document.getElementById("addItem"));
	parameters = null; // used for parameters in url or post
	var projId = "";
	var prioId = "";
	var typeId = "";
	var project = document.getElementById("pjNames");
	var priority = document.getElementById("Priority");
	var description = document.getElementById("Description");
	
	var descId = description.value;
	
	var r = argItems("mid");
	if (project.selectedIndex > -1)
		projId = project.options[project.selectedIndex].value;
	if (priority.selectedIndex > -1)
		prioId = priority.options[priority.selectedIndex].value;
	var type = document.updMeeting.Type;
	for(var i = 0; i < type.length; i++) {
		if (type[i].checked == true) {
			typeId = type[i].value;
		}
	}

	if(descId.length > 255) {
		s = "The " + typeId + " is " + descId.length
				+ " characters long that is longer than the max allowed length (255), please shorten the description or break the item into multiple items.";
		alert(s);
		enableButton(document.getElementById("addItem"));
		return;
	}	
	
	var bug = document.getElementById("ibNames");
	var bugId = "";
	if (bug != null)
		bug.options[bug.selectedIndex].value;
	var owner = document.getElementById("acNames");
	var ownerId = owner.options[owner.selectedIndex].value;
	var responsible = document.getElementById("Responsible");
	var responLength = responsible.options.length;
	var expire = document.getElementById("Expire").value;
	if (window.XMLHttpRequest) {
		req = new XMLHttpRequest(); 
	} else if (window.ActiveXObject) {
 		req = new ActiveXObject("Microsoft.XMLHTTP");
	}
	var url = HOSTS + "/servlet/PrmAcManager";
	parameter = "mid=" + escape(r[0]) + "&projId=" + escape(projId) + "&Priority=" + escape(prioId);
	parameter += "&Type=" + escape(typeId) + "&Description=" + escape(descId) + "&Owner=" + escape(ownerId) + "&BugId=" + escape(bugId);
	parameter += "&Expire=" + escape(expire);
	
	for(var i = 0; i < responLength; i++) {
		parameter += "&Responsible=" + responsible.options[i].value;
	}
	req.open("POST", url, true);
	req.onreadystatechange = callbackAC;
	req.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
	req.send(parameter + "&" + getAttendeeList());
}

function ajaxDeleteAC() {
	var getstr = "";
	var counter = 0;
	var ckboxes = document.getElementById("ckbox"+counter);
	while(ckboxes) {
		if (ckboxes.checked)
			getstr += ckboxes.name + "=&";
		counter++;
		ckboxes = document.getElementById("ckbox"+counter);
	}
	var r = argItems("mid");
	getstr += "mid=" + escape(r[0]);
	submitDeleteAC(HOSTS + "/servlet/PrmAcManager", getstr + "&" + getAttendeeList());
}

function submitDeleteAC(url, parameters) {
	if (window.XMLHttpRequest) {
		req = new XMLHttpRequest(); 
	} else if (window.ActiveXObject) {
 		req = new ActiveXObject("Microsoft.XMLHTTP");
	}
	req.open("POST", url, true);
	req.onreadystatechange = callbackDeleteAC;
	req.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
	req.send(parameters);
	
}

function setParameters(paramName, paramValue) {
	if (parameters == null) {
		parameters = "?"+paramName+"="+escape(paramValue);
	} 
	else {
		parameters += "&"+paramName+"="+escape(paramValue);
	}
}

function callbackDoNothing() {
    if (req.readyState == 4) {
        if (req.status == 200) {
        	// do Nothing;
        	return;
        }
    }
}


function callbackDeleteAC() {
    if (req.readyState == 4) {
        if (req.status == 200) {
			parseXml(req);
			manageDeleteButton();
        }
        else
        	alert("Internal Error: Please contact PRM Administrator.");
    }
}


function callbackAC() {
   if (req.readyState == 4) {
        if (req.status == 200) {
			setFocus("Description");
			parseXml(req);
			resetAC();
			enableButton(document.getElementById("addItem"));
			manageDeleteButton();
        }
        else 
        	alert("Internal Error: Please contact PRM Administrator.");
    }
}

function callbackAT() {
    if (req.readyState == 4) {
        if (req.status == 200) {
            // update the HTML DOM based on whether or not message is valid;
			resetBrowseField()
        }
        else
        	alert("Internal Error: Please contact PRM Administrator.");
    }
}

function callbackAD() {
    if (req.readyState == 4) {
        if (req.status == 200) {
            // update the HTML DOM based on whether or not message is valid;
			parseXml(req);
			enableButton(document.getElementById("addNewAD"));
			if (mtgTimer > SAFENET) // Restart if time is greater than SAFENET, otherwise let MFC handle the restart
				mtgTimer = RESTART;	
        }
    }
}

function callback() {
    if (req.readyState == 4) {
        if (req.status == 200) {
            // update the HTML DOM based on whether or not message is valid;
			parseXml(req);
        }
    }
}

function callbackAuto() {
    if (reqAuto.readyState == 4) {
        if (reqAuto.status == 200) {
            // update the HTML DOM based on whether or not message is valid;
			parseXmlAuto(reqAuto);
			var button = document.getElementById("saveMtgNotes")
			if(button && button.disabled && (!isOn && mfcTimeout == null))
				enableButton(document.getElementById("saveMtgNotes"));
			if (mtgTimer > SAFENET) // Restart if time is greater than SAFENET, otherwise let MFC handle the restart
				mtgTimer = RESTART;	
        }
    }
}

// *************************************
// Setting XML information back to js or webpage
// *************************************

/**
* Checks to see if there is a value inside url
* and redirects to the page if it exist. 
* @param url retreived from Xml
*/
function checkRedirect(url, message) {
	// @AGQ082806 
	if (!redirect) {
		if (message == null || 
			message != "Your facilitator responsibility has been revoked.\n") {
			return false;
		}
	}
	if (url != null) {
		stopAutoSaveTimer();
		if (message!=null)
			alertMessage(message);
		location.href = url.join("")+"&isShow="+isShow+"&anchor=minute";
		return true;
	}
	return false;
}

function updateLastUpdateAuto(time) {
	if (time != null && isRun == 0)	{
		// Check if value did not return
		var temp = time[flagIDX];
		if(temp != null && temp.length > 0) {
			ADCOUNT = time[ADIDX];
			ATCOUNT = time[ATIDX];
			if (time[MNIDX] <= MNCOUNT)			// ECC: should not happen unless timing go crazy
				time[flagIDX] &= 251;			// ECC: compare id value to block old msg coming back because of timing issue
			else
				MNCOUNT = time[MNIDX];
			AICOUNT = time[AIIDX];
			DCCOUNT = time[DCIDX];
			INCOUNT = time[INIDX]
			ISCOUNT = time[ISIDX];
			flag = time[flagIDX];		
		}
		else {
			flag = 0;
		}
    }
}

/**
 * Update counter for receiving new Mtg Notes from MFC
 */
function updateLastUpdateMFC(time) {
	if (time != null && isRun == 0)	{
		// Check if value did not return
		var temp = time[flagIDX];
		if(temp != null && temp.length > 0) {
			if (MNCOUNT < time[MNIDX])
				MNCOUNT = time[MNIDX];
		}
    }
}

/**
 * @AGQ101106 Update counter for force update mtg notes
 */
function updateLastUpdateMFCCheck(time) {
	if (time != null && isRun == 0)	{
		// Check if value did not return
		var temp = time[flagIDX];
		if(temp != null && temp.length > 0) {
			if (UDCOUNT != time[UDIDX]) {
				preRedirect = true;
				UDCOUNT = time[UDIDX];
			}
		}
    }
}

/**
* Reads and sets the Xml information onto the webpage
* @param l_req Local version of global request object
*/
function parseXml(l_req) {
	// Check to see if there is a page redirect
	checkRedirect(getResponseXml("url", l_req), getResponseXml("alertMessage", l_req));

    setElementInnerHTML("meetingNotes", getResponseXml("meetingNotes", l_req)); // Sets Meetings Notes
    setElementInnerHTML("aiObjTable", getResponseXml("aiObjTable", l_req)); // Sets Action Item
    setElementInnerHTML("time", getResponseXml("time", l_req)); // Sets Messages for user (time, timeout, etc)
    setElementInnerHTML("dsObjTable", getResponseXml("dsObjTable", l_req)); // Sets Decisions
    setElementInnerHTML("bgObjTable", getResponseXml("bgObjTable", l_req)); // Sets Issues 
    setElementInnerHTML("atObjTable", getResponseXml("atObjTable", l_req)); // Sets Attachments
    setElementInnerHTML("adObjTable", getResponseXml("adObjTable", l_req)); // Sets Attendees
    setTotalOnline(getResponseXml("totalOnline", l_req)); // Sets totalOnline
    
    setSelect("rsNameText", "rsNameValue", "rsNames", 0, false, l_req); // Sets the Responsible list
    setSelect("ibNameText", "ibNameText", "ibNames", 1, false, l_req); // Sets Issue/PR list
    setSelect("rsNameText", "rsNameValue", "acNames", 0, true, l_req); // Sets Coordinator list
    setSelect("adNameText", "adNameValue", "adNames", 1, false, l_req); // Set Attendees list
    setSelect("rcNameText", "rcNameValue", "rcNames", 0, true, l_req); // Sets Change Recorder list
}

/** 
* Set the array into element in webpage
* @param id the element's id from the webpage
* @param array the data to be filled into the element
*/ 
function setElementInnerHTML(id, array) {
	if (array != null) {
		if (id == "meetingNotes") {
			setElementInnerHTMLMtgNotes(id, array);
			return;
		}
		setInnerHTML(id, array);
	}
}

var enteredLines = 3;
function setElementInnerHTMLMtgNotes(id, array) {
	if (array != null) {
		var oldMtgNotes = null;
		var newMtgNotes = null;
		var divTag = null;
		element = document.getElementById(id);
		if (id == "meetingNotes") {
			// Store original meeting notes
			if (redirect) { // participants are off. compare notes
				oldMtgNotes = trim(element.innerHTML); // Just to be safe
				oldMtgNotes = oldMtgNotes.replace(/\s+/g,' '); // IE converts the whitespaces; standarizes all whitespaces
			}
			else
				oldMtgNotes = "";
		}

		if (preRedirect) enteredLines = 3;
		
		if (!redirect && !preRedirect) { // Insert new chat notes into div
			divTag = findChatDivTag();
			
			var appendText = array.join("");
			// Remove own chat 
			if (chatColor!=null) {
				appendText = removeOwnChat(appendText);
				if (appendText.length == 0)
					return; // No new notes to append
			}
						
			divTag.innerHTML += appendText;
		}
		else {
			element.innerHTML = array.join("");
			if (preRedirect) {
				preRedirect = false;
			}	
		}
		if (oldMtgNotes != null) {
			// Find new text
			if (redirect) {
				newMtgNotes = trim(element.innerHTML);
				newMtgNotes = newMtgNotes.replace(/\s+/g,' ');
				var i;
				var ltIdx = 0;
				var curChar;
				if (oldMtgNotes != newMtgNotes) {
					for (i=0; i<oldMtgNotes.length; i++) {
						curChar = oldMtgNotes.charAt(i);
						if (curChar == ">") ltIdx = i+1;
						if (oldMtgNotes.charAt(i) != newMtgNotes.charAt(i)) {
							break;
						}
					}
				}
			}
				
			if (oldMtgNotes != newMtgNotes || !redirect) {
				var tempNotes = "";
				if (redirect) {
					tempNotes = newMtgNotes.substr(0, ltIdx) + "<var id='scrollMark'></var>" + newMtgNotes.substr(ltIdx);
					element.innerHTML = tempNotes;
				}
				scrollToNewText(element, newMtgNotes);
			}	
		}
	}
}

function scrollToNewText(element, newMtgNotes) {
	var varTagArray = document.getElementsByTagName("var");
	if (varTagArray.length>0) {
		if (true/*redirect || enteredLines++>=3*/) {	// ECC: change to always append chat text at bottom: always move
			enteredLines = 0;
			if (!isClicked) {
				var varTag = null;
				for (var i=0; i<varTagArray.length; i++) {
					varTag = varTagArray[i];
					if (varTag.id == "scrollMark") {
						break;
					}
				}
				
				// use scrollIntoView() to set the element.scrollTop and store it in location
				var curScrollTop = element.scrollTop;
				var curPageScrollTop = document.body.scrollTop;
				if (justStartChat)
				{
					justStartChat = false;			// only move the whole document the first time
					if (isMozilla)
						varTag.scrollIntoView(false);
					else
						varTag.scrollIntoView();	// for IE, if use false param the whole window will move unnecessarily
				}

				element.scrollLeft = 0;
				/*Don't change document body
				if (document.body.scrollTop != curPageScrollTop) {
					document.body.scrollTop = curPageScrollTop;
				}*/

				var isLastPage = false;
				var location = element.scrollTop;	// location is the line number
				//if (element.scrollHeight-location < element.offsetHeight)
				//	isLastPage = true;
				//if (curScrollTop >= location && isMozilla) {
				if (isMozilla) {
					element.scrollTop = location - element.offsetHeight + 1000;
					varTag.scrollIntoView(false);
					element.scrollLeft = 0;
					/* Don't change document body
					if (document.body.scrollTop != curPageScrollTop) {
						document.body.scrollTop = curPageScrollTop;
					}*/
					location = element.scrollTop;
				}
				//else if (!isLastPage)
				//	element.scrollTop = location - element.offsetHeight;	// mid needs this, bot don't like it
				
				
/* ECC: commented out because I now always go to the bottom
				var newLocation = 0;

				if (isOn || location > 0)
					newLocation = location + (element.offsetHeight/2);
//alert("locTop="+location+", newLoc="+newLocation+", offsetH="+element.offsetHeight+", scroHeight="+element.scrollHeight);
				if (redirect && newMtgNotes != null)
					element.innerHTML = newMtgNotes;
				if (isMozilla || location > 15)
				{
					element.scrollTop = newLocation;	// mid needs this, top don't like this
				}
*/				
			}
		}
		if (isOn)
		{
			element.scrollTop = location + 1000;		// ECC: always move to bottom
			playSound("sound1");	// this is the "chick" sound when chat text is received
		}
	}
}

// Detects the name and removed chat send by myself
function removeOwnChat(appendText) {
	var NAME_IDX = 87; // Index of name
	if (appendText.length > 0) {
		var textArray = appendText.split("<div>");
		for (var i=textArray.length-1; i>=0; i--) {
			if (textArray[i].length > 0) {
				var idx = textArray[i].indexOf(screenName);
				if (idx == NAME_IDX) {
					textArray[i] = null;
				}
				else
					textArray[i] = "<div>" + textArray[i];
			}	
		}
		appendText = textArray.join("");
	}
	return appendText;
}

function findChatDivTag() {
	var insertNotes = document.getElementsByTagName("div");
	var divTag = null;
	if (insertNotes.length > 0) {		
		for (var i=insertNotes.length-1; i>=0; i--) {
			divTag = insertNotes[i];
		
			if (divTag.id == "insertNotes") {
				break;
			}
		}
	}	
	return divTag;
}

// *************************************
// Delete Button
// *************************************

function manageDeleteButton() {
	var counter = 0;
	var ckboxes = document.getElementById("ckbox"+counter);
	if (ckboxes)
		showDelete();
	else
		hideDelete();
}

function showDelete() {
	var deleteTop = document.getElementById("deleteTop");
	var deleteBottom = document.getElementById("deleteBottom");
	if (trim(deleteTop.innerHTML).length <= 0)
		deleteTop.innerHTML = "<a href='javascript:ajaxDeleteAC()' class='listlinkbold'>>> Delete&nbsp;</a>";
	if (trim(deleteBottom.innerHTML).length <= 0)
		deleteBottom.innerHTML = "<a href='javascript:ajaxDeleteAC()' class='listlinkbold'>>> Delete&nbsp;</a>";
}

function hideDelete() {
	var deleteTop = document.getElementById("deleteTop");
	var deleteBottom = document.getElementById("deleteBottom");
	if (trim(deleteTop.innerHTML).length > 0)
		deleteTop.innerHTML = "";
	if (trim(deleteBottom.innerHTML).length > 0)
		deleteBottom.innerHTML = "";
}

// *************************************
// Helper Functions
// *************************************

function init(runner) {
	mtgTimer = RESTART;
	isRun = runner
	debug = argItems("debug");
	if (run)
		stopAutoSaveTimer();
	else {
		if (isRun != 1) 
			ajaxMtgNotes(false);
		// init HOSTS name;
		HOSTS = document.getElementById("HOSTS").value;
		stopAutoSaveTimer();
		run = true;
		timer();
	}
	showStatus(debug[0]);
}

function initMFC() {
	mfcTimer = mfcRESTART;
	mfChatTimer();
}

function isBackButton() {
	var isBack = document.getElementById("backButton");
	if(isBack.value == 2) {
		isBack.value = 1;
		isBack.defaultValue = 1;
		window.location.reload();
		return true;
	}
	else {
		isBack.value = 2;
		isBack.defaultValue = 2;
		return false;
	}
}

function manualSave() {
	isRun = 1;
	ajaxMtgNotes(true);
}

function showStatus(debug) {
	if (debug == "true") {
		spanStatus = document.getElementById("refreshStatus");
		if (run) {
			spanStatus.innerHTML = "ON";
			spanStatus.style.color = "red";
		} else {
			spanStatus.innerHTML = "OFF";
			spanStatus.style.color = "blue";
		}
	} 
}

function timer() {
	mtgTimer--;
	// was going to use mtgTimer <= 0 but the calls may perform twice in a row
	// mtgTimer < -15 is a safety net in case the first mtgTimer == 0 was missed
	if (mtgTimer == 0) {
		ajaxMtgNotes(true);		// ECC: save notes
	}
	if (mtgTimer == SAFENET) {
		mtgTimer = RESTART;
	}
	// Restart immediately after timer has fallen out of normal loop.
	if (mtgTimer < SAFENET + SAFENETMFC) {
		mtgTimer = RESTART;
	}
	
	if (run)
		autoSaveTimer = setTimeout("timer();", 1000);
}


/**
 * Timer to check if invite input session is on
 */ 
function mfChatTimer() {
	mfcTimer--;

	if (mfcTimer == 0) {
		ajaxMFCCheck();
		clearOnline = false;
	}
	if (mfcTimer < SAFENETMFC) {
		mfcTimer = mfcRESTART;
	}
/*	@AGQ100606 Moved clear timer to after completion of checking timer 
	see the parse method for ajaxMFCCheck();
*/	
	setTimeout("mfChatTimer();", 1000);
}

function stopAutoSaveTimer() {
	if (run)
		clearTimeout(autoSaveTimer);
	run = false;
}

/**
* Removes all the whitespace and see if the meeting notes is empty. If the notes became
* empty it will ask if the user wants to save the empty notes. 
*/
function confirmNullNotes(bText, save) {
	if (!isRunning) {
		isRunning = true;
		var re = new RegExp(REGEX, "g");
	  	var trimmedNotes = bText.replace(re, "");
		if (trimmedNotes != null) {
			if (trimmedNotes.length <= 0 && !isMtgNotesNull) {
				var results;
				stopAutoSaveTimer(); // stop timer in case it will show the message twice
				if (save)
					results = confirm("Your notes will be saved as empty. Is this okay?");
				else
					results = confirm("Your notes will be autosaved as empty. Is this okay?");
				isMtgNotesNull = true;
				// refresh page
				if (!results)
					location.href = location.href;
				else {
					run = true;
					//timer();
				}
				isRunning = false;
				return results;
			}
			else if (trimmedNotes.length > 0)
				isMtgNotesNull = false;
		}
		// In case some kind of error happened; i.e. browser does not support fckEditor
		else {
			isRunning = false;
			return false;
		}
		isRunning = false;
		return true;
	}
	return false;
}


/**
* Prevents the enter key to automatically select submit
*/
function onEnterSubmitFeedback(evt) {
	var code = evt.keyCode? evt.keyCode : evt.charCode;
	if (code == 13)
	{
		ajaxMFCSubmit();
		return;
	}
}

/**
* Looks through all the attendee's checkbox and saves all the
* checkbox's name into a string. The returned string is in POST
* format (ckboxname1=&chboxname2=&). 
*/
function getAttendeeList() {
	var getstr = "";
	var counter = 0;
	var ckboxes = document.getElementById("ckAD"+counter);
	while(ckboxes) {
		if (ckboxes.checked)
			getstr += ckboxes.name + "=&";
		counter++;
		ckboxes = document.getElementById("ckAD"+counter);
	}
	return getstr;
}

/**
* This function will reset the browse area for attachment. 
* Reset normally resets everything in a form, however in this case
* this function will save all the fields (manually specified), parse the XML,
* reset the form, and then replace the fields.
*/
function resetBrowseField() {
	// Save Modifiable Fields
	var rcIndex = getSelectedIndexValue("rcNames"); // Change Recorder
	var adIndex = getSelectedIndex("adNames"); // Attendee's List
	var typeIndex = getCheckedRadioType(); // AC Type
	var priorityIndex = getSelectedIndex("Priority"); // AC Priority
	var descValue = getValue("Description"); // AC Description
	var pjIndex = getSelectedIndex("pjNames"); // AC Project Name
	var ibIndex = getSelectedIndex("ibNames"); // AC Issue ID
	var acIndex = getSelectedIndex("acNames"); // AC Coordinator
	var expireValue = getValue("Expire"); // AC Expire Date

	// There is a bug here, if Change Recorder name list is updated after 
	// parsing the XML, then the index will not point back to the same person.
	// Need to check the id and loop through it.
	// Parse the Return XML
	parseXml(req);
	
	// Reset the Form
	document.updMeeting.reset();
	
	// Replace the Fields
	setSelectedIndexValue("rcNames", rcIndex);
	setSelectedIndex("adNames", adIndex);
	setCheckedRadioType(typeIndex);
	setSelectedIndex("Priority", priorityIndex);
	setValue("Description", descValue);
	setSelectedIndex("pjNames", pjIndex);
	setSelectedIndex("ibNames", ibIndex);
	setSelectedIndex("acNames", acIndex);
	setValue("Expire", expireValue);
}

/**
* Finds out which Radio is selected
*/
function getCheckedRadioType() {
	var type = document.updMeeting.Type; // Cannot use getElementById, unless I give all IDs
	if (type) {
		for(var i = 0; i < type.length; i++) {
			if (type[i].checked == true) {
				return i;
			}
		}
	}
	return 0
}

function setCheckedRadioType(check) {
	var type = document.updMeeting.Type;
	if (type) {
		for(var i = 0; i < type.length; i++) {
			if (i == check) {
				type[i].checked = true;
			}	
			else {
				type[i].checked = false;
			}	
		}
	}
}

var attendeeMO = false;

// *************************************
// AutoSave Methods Due to conflict
// *************************************
/**
* Reads and sets the Xml information onto the webpage
*/
function parseXmlAuto(l_req) {	
	// Check to see if there is a page redirect
	var isRedirect = checkRedirect(getResponseXml("url", l_req), getResponseXml("alertMessage", l_req));
	if(!isRedirect) {
		updateLastUpdateAuto(getResponseXml("counts", l_req)); // receives the current counters and flag
		setElementInnerHTML("time", getResponseXml("time", l_req)); // Sets Messages for user (time, timeout, etc)
		if (flag >= 0) {
			if ((flag & 1) == 1) {
				setElementInnerHTML("adObjTable", getResponseXml("adObjTable", l_req)); // Sets Attendees
    			setTotalOnline(getResponseXml("totalOnline", l_req)); // Sets totalOnline
			}
			if ((flag & 2) == 2) { 
				setElementInnerHTML("atObjTable", getResponseXml("atObjTable", l_req)); // Sets Attachments
			}
			if ((flag & 4) == 4) {
				setElementInnerHTML("meetingNotes", getResponseXml("meetingNotes", l_req)); // Sets Meetings Notes
			}
		    if ((flag & 8) == 8) {
		    	setElementInnerHTML("aiObjTable", getResponseXml("aiObjTable", l_req)); // Sets Action Item
		    }
		    if ((flag & 16) == 16) {
		    	setElementInnerHTML("dsObjTable", getResponseXml("dsObjTable", l_req)); // Sets Decisions
		    }
		    if ((flag & 32) == 32) {
		    	setElementInnerHTML("bgObjTable", getResponseXml("bgObjTable", l_req)); // Sets Issues 
		    }
		    if ((flag & 64) == 64) {
				updateInputQueue(getResponseXml("inputQString", l_req)); 	// @ECC101106 input queue
		    }
		    setSelect("rcNameText", "rcNameValue", "rcNames", 0, true, l_req); // Sets Change Recorder list
		} 
		// This is autoSave method, flag = -1
		else {
		    setElementInnerHTML("aiObjTable", getResponseXml("aiObjTable", l_req)); // Sets Action Item
		    setElementInnerHTML("dsObjTable", getResponseXml("dsObjTable", l_req)); // Sets Decisions
		    setElementInnerHTML("bgObjTable", getResponseXml("bgObjTable", l_req)); // Sets Issues 
		    setElementInnerHTML("atObjTable", getResponseXml("atObjTable", l_req)); // Sets Attachments
		    if (!attendeeMO) {
			    setElementInnerHTML("adObjTable", getResponseXml("adObjTable", l_req)); // Sets Attendees
    			setTotalOnline(getResponseXml("totalOnline", l_req)); // Sets totalOnline
    		}
		    updateInputQueue(getResponseXml("inputQString", l_req));
		    
		    setSelect("rsNameText", "rsNameValue", "rsNames", 0, false, l_req); // Sets the Responsible list
		    setSelect("ibNameText", "ibNameText", "ibNames", 1, false, l_req); // Sets Issue/PR list
		    setSelect("rsNameText", "rsNameValue", "acNames", 0, true, l_req); // Sets Coordinator list
		    setSelect("adNameText", "adNameValue", "adNames", 1, false, l_req); // Set Attendees list
		    setSelect("rcNameText", "rcNameValue", "rcNames", 0, true, l_req); // Sets Change Recorder list
		}   
	}   
}

function setTotalOnline(nameList)
{
	if (nameList == null) nameList = new Array();
	nameList = nameList.join("");
	sa = nameList.split(":");
	var len = sa.length - 1;	// i always has an extra ":" at end
	var uname;
	var cnt = 0;
	var pos = -1;
	var isChatting;

	var tableStr = "<table border='0' cellspacing='0' cellpadding='0'>";
	tableStr += "<tr><td class='plaintext_blue' width='150'><b>Meeting Minutes:</b></td>";
	tableStr += "<td class='plaintext'>" + len + " online participants</td></tr>";
	tableStr += "<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>";
	tableStr += "<tr><td colspan='2'><table border='0' cellspacing='0' cellpadding='0'>";
	for (i=0; i<len; i++)
	{
		isChatting = false;
		pos = cnt++ % 6;
		uname = sa[i];
		if (uname.charAt(0) == "*")
		{
			uname = uname.substring(1);
			isChatting = true;
		}
		if (uname == "admin") continue;		// don't show admin
		
		if (pos == 0)
			tableStr += "<tr><td><img src='../i/spacer.gif' width='15'></td>";	// start a new line
		tableStr += "<td><img src='../i/icon_on.gif'></td><td class='plaintext' valign='middle' width='80'>";
		if (isFacilitator && uname!=myObjName)
		{
			if (!isChatting)
				tableStr += "<a href='javascript:enableInputQHead(\"" +midS + "\", 4, \"" + uname + "\");' class='listlink' title='Click to add this person to chat session'>" + uname + "</a>";
			else
				tableStr += "<a href='javascript:enableInputQHead(\"" + midS + "\", 0, \"" + uname + "\");' class='listlink' title='Click to end input from this person'><font color='#dd0000'>" + uname + "</font></a></td>";
		}
		else if (isChatting)
			tableStr += "<font color='#ee0000' title='Currently in chat session'>" + uname + "</font>";
		else
			tableStr += uname;
		tableStr += "</td>";
		if (pos == 5)
			tableStr += "</tr>";	// close a line
	}
	if (pos!=-1 && pos!=5)
	{
		tableStr += "<td colspan='" + (5-pos) + "'></td>";
		tableStr += "</tr>";	// need to close the last line
	}
	tableStr += "</table></td></tr></table>";
	//setElementInnerHTML("totalOnline", tableStr); 		// Sets totalOnline
	var e = document.getElementById("totalOnline");
	e.innerHTML = tableStr;
}

// *************************************
// Debug Links
// *************************************
function xmlFile(link) {
	var r = argItems("mid");
	var select = document.getElementById("pjNames");
	var projId = 0;
	if (select)
		var projId = select.options[select.selectedIndex].value;
	location.href= HOSTS + "/servlet/"+link+"?mid=" + escape(r[0]) + "&debug=true" + "&projId=" + escape(projId);
}