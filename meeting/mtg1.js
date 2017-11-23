//
//	Copyright (c) 2006 EGI Technologies.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
// $Header: /cvsrepo/PRM/meeting/mtg1.js,v 1.1 2006/12/14 03:41:23 edwardc Exp $
//
//	File:	$RCSfile: mtg1.js,v $
//	Author:	ECC
//	Date:	$Date: 2006/12/14 03:41:23 $
//  Description:
//      Javascript for meetings.
//
//  Required:
//
//	Optional:
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////

/**
* Prevents the enter key to automatically select submit
*/

function onEnterSubmitAC(event) {
	charRemain("Description", "charCount")
	var code = event.keyCode? event.keyCode : event.charCode;
	if (code == 13)
		return false;
	/*if (window.event && window.event.keyCode == 13)
		return false;
	else if (event && event.which == 13)
		return false;*/
}

function charRemain(id, rid) {
	var length = getLength(id);
	var remain = 255 - length;
	var rspan = document.getElementById(rid);
	if(remain >= 0) {
		rspan.innerHTML = remain;
		rspan.style.color = "green";
	}
	else {
		rspan.innerHTML = remain;
		rspan.style.color = "red";
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
