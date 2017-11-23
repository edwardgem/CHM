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
//      This js file contains ajax utils. The various 
//		methods helps the ajax functions parse the returning XML.
//
//  Required:
//
//	Optional:
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////

// *************************************
// Ajax Helper Functions
// *************************************

/**
* Retrieves all the values from XML document and places then into an array. 
* @param xmlTag The name of the tag
* @param l_req	The request object from Ajax
*/
var isMozilla = (navigator.userAgent.toLowerCase().indexOf('gecko')!=-1) ? true : false;
var isPDA = false;	// set in JSP like ep_chat.jsp
var isOSX;			// set in pop_chat.jsp

function getResponseXml(xmlTag, l_req) {
	var response = l_req.responseXML;
	var numOfChild = 0;
	if (response) {
		numOfChild = response.getElementsByTagName(xmlTag).length;
	}
//if (xmlTag=='LastChatId') alert("num=" +numOfChild);
	
	if (numOfChild > 0) {
		var xmlTagArray = new Array(numOfChild);
		for(var i = 0; i < xmlTagArray.length; i++) {
			var tag = response.getElementsByTagName(xmlTag)[i];
			xmlTagArray[i] = tag.childNodes[0].nodeValue;
//if (xmlTag=='LastChatId') alert("--" + xmlTagArray[i]);
		}
	}
	// numOfChild == 0 which means <xmlTag> does not exist in XML
	else 
		xmlTagArray = null;
	return xmlTagArray;
}

/**
* Looks through the xml for valueTag and nameTag. After retrieving these
* information, it will create new Option onto the select list with the 
* supplied element id. If there exist a nameTag + "Empty", then the list
* will be emptied. If there exist a nameTag + "Selected" then that Option
* will be selected. 
* @param valueTag Xml tag with the "value"
* @param nameTag Xml tag with the "name"
* @param id The element id of the select list to create the Option into
* @param start The number to start the list (0 will create a new list, 1+ will save the previous 1st+ item)  
* @param l_req Local version of global request object
*/
function setSelect(nameTag, valueTag, id, start, select, l_req) {
	var space = "&nbsp;";
	var empty = "";
	var nameLength = l_req.responseXML.getElementsByTagName(nameTag).length;
	var valueLength = l_req.responseXML.getElementsByTagName(valueTag).length;
	if (nameLength != valueLength) {
		// Should never happen unless data was lost in transaction
		alert(id + ": Names and Value do not match");
	}
	if (nameLength > 0) {
		document.getElementById(id).options.length = start; // set original length to start (or null)
		if (valueTag != nameTag) { // Value and Name are not the same items
			for(var i = 0; i < valueLength; i++) {
				var nameNode = l_req.responseXML.getElementsByTagName(nameTag)[i];
				var valueNode = l_req.responseXML.getElementsByTagName(valueTag)[i];
				var nameText = trim(nameNode.childNodes[0].nodeValue);
				var valueText = trim(valueNode.childNodes[0].nodeValue);
				document.getElementById(id).options[start+i] = new Option(empty, valueText);
				document.getElementById(id).options[start+i].innerHTML = space + nameText;
			}
		} else { // Value and Name are the same
			for(var i = 0; i < valueLength; i++) {
				var nameNode = l_req.responseXML.getElementsByTagName(nameTag)[i];
				var nameText = trim(nameNode.childNodes[0].nodeValue);
				document.getElementById(id).options[start+i] = new Option(empty, nameText);
				document.getElementById(id).options[start+i].innerHTML = space + nameText;
			}
		}
		// Set the selected Options only if xml node exists and select == true
		var selectedLength = l_req.responseXML.getElementsByTagName(nameTag+"Selected").length;
		if (selectedLength > 0 && select) {
			for(var i = 0; i < selectedLength; i++) {
				var selectedNode = l_req.responseXML.getElementsByTagName(nameTag+"Selected")[i];
				var selectedIndex = selectedNode.childNodes[0].nodeValue;
				var index = eval(start) + eval(selectedIndex);
				document.getElementById(id).options[index].selected = true;
			}
		}
	}
	// nameLength <= 0 tag does not exist in XML, check to see if we need to empty the list
	else {
		nameLength = l_req.responseXML.getElementsByTagName(nameTag+"Empty").length;
		if (nameLength > 0)
			document.getElementById(id).options.length = start; // set original length to start (or null)
	} 	
}

/** 
* Set the array into element in webpage
* @param id the element's id from the webpage
* @param array the data to be filled into the element
*/ 
function setInnerHTML(id, array) {
	if (array != null) {
		var element = document.getElementById(id);
		if (element != null)
			element.innerHTML = array.join("");
	}
}

// *************************************
// Helper Functions
// *************************************
function URLencode(sStr) {
	var newStr = escape(sStr).
             replace(/\+/g, '%2B').
                replace(/\"/g,'%22').
                   replace(/\'/g, '%27').
                     replace(/\//g,'%2F');
    return newStr;
}

function alertMessage(message) {
	if (message != null)
		alert(message);
}

function trim(str) {
	if (str != null)
		return str.replace(/^\s*|\s*$/g,"");
	else
		return null;
}

/**
* Collects data from url
*/
function argItems (theArgName) {
	sArgs = location.search.slice(1).split('&');
    r = '';
    for (var i = 0; i < sArgs.length; i++) {
        if (sArgs[i].slice(0,sArgs[i].indexOf('=')) == theArgName) {
            r = sArgs[i].slice(sArgs[i].indexOf('=')+1);
            break;
        }
    }
    return (r.length > 0 ? unescape(r).split(',') : '')
}

/**
* Select all the options in select list id. 
*/
function selectAll(id) {
	var select = document.getElementById(id);
	if (select != null) {
		var selectLength = select.options.length;
		for(var i = 0; i < selectLength; i++) {
			select.options[i].selected = true;
		}
	}
}

/**
* Deselect all the options in the select list with id = "id".
*/
function selectNone(id) {
	var select = document.getElementById(id);
	if (select != null) {
		var selectLength = select.options.length;
		for(var i = 0; i < selectLength; i++) {
			select.options[i].selected = false;
		}
	}
}

/**
* Set the cursor to focus on this location
*/
function setFocus(id) {
	if (document.getElementById(id)) {
		document.getElementById(id).focus();
	}
}

function getValue(id) {
	var value = "";
	var textbox = document.getElementById(id);
	if (textbox) {
		value = textbox.value;
	}
	return value;
}

function setValue(id, value) {
	var textbox = document.getElementById(id);
	if (value.length > 0 && textbox) {
		textbox.value = value;
	}
}

function getLength(id) {
	var length = 0;
	var textbox = document.getElementById(id);
	if (textbox) {
		length = textbox.value.length;
	}
	return length;
}

function getSelectedIndex(id) {
	var index = -1;
	var select = document.getElementById(id);
	if (select) {
		index = select.selectedIndex;
	}
	return index;
}

function setSelectedIndex(id, index) {
	var select = document.getElementById(id);
	if (index > -1 && select) {
		select.selectedIndex = index;
	}
}

function getSelectedIndexValue(id) {
	var value = null;
	var select = document.getElementById(id);
	if (select) {
		value = select.options[select.selectedIndex].value;
	}
	return value;	
}

/**
* Sets the select list's selectedIndex to the option with given value. 
* Loops through the select lists, finds the matching value and sets
* the value to become the selectedIndex. If none is found, does nothing.
* (This will select the first one the list, or if a previous options 
* was already selected, then that will be used instead)
*/
function setSelectedIndexValue(id, value) {
	var select = document.getElementById(id);
	for(var i = 0; i < select.length; i++) {
		if (select.options[i].value == value) {
			select.selectedIndex = i;
		}
	}
}

function disableButton (button) {
  if (document.all || document.getElementById)
    button.disabled = true;
  else if (button) {
    button.oldOnClick = button.onclick;
    button.onclick = null;
    button.oldValue = button.value;
    button.value = 'DISABLED';
  }
}
function enableButton (button) {
  if (document.all || document.getElementById)
    button.disabled = false;
  else if (button) {
    button.onclick = button.oldOnClick;
    button.value = button.oldValue;
  }
}

function playSound(soundobj) {
	if (isPDA || isOSX) return;		// ECC: can't make sound work on mobile or Mac
	
	var url;
	if (soundobj == "sound1")
		url = "../i/clickerx.wav";
	else if (soundobj == "sound2")
		url = "../i/chimes.wav";
	else if (soundobj == "sound3")
		url = "../i/recycle.wav";
	else
		url = "../i/" + soundobj;

	if (!isMozilla) {
		document.getElementById("IESound").src = url;
	}
	else {
		setEmbed('FFSound', url);
	}
}

function setEmbed(ID, dir) {
	var element = document.getElementById(ID);
	element.innerHTML = '<embed src="'+dir+'" autostart=true loop=false width=0 height=0 type="'+getMimeType()+'"></embed>';
}

function getMimeType(){
var mimeType = "application/x-mplayer2"; //default
var agt=navigator.userAgent.toLowerCase();
if (navigator.mimeTypes && agt.indexOf("windows")==-1) {
//non-IE, no-Windows
  var plugin=navigator.mimeTypes["audio/mpeg"].enabledPlugin;
  if (plugin) mimeType="audio/mpeg" //Mac/Safari & Linux/FFox
}//end no-Windows
return mimeType
}//end function getMimeType
