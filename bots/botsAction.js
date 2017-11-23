//
//	Copyright (c) 2017 EGI Technologies.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	bots.js
//	Author:	ECC
//	Date:	07/15/07
//  Description:
//      This js file deals with ajax calls for OmmBots actions. Used by ommBots.jsp.
//
//	Dependency:
//		ajax_util.js
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////


var isMSIE = (navigator.userAgent.toLowerCase().indexOf('msie')!=-1)?true:false;
var fullURL = parent.document.URL;



// defined in ommBots.jsp
// doneCloneBots()


// clone a robot from a model
function ajaxClone(botName)
{
	if (window.XMLHttpRequest)
		req = new XMLHttpRequest();
	else if (window.ActiveXObject)
		req = new ActiveXObject("Microsoft.XMLHTTP");

	// parameters
	var model = "&bot=" + botName;
	
	var url = "../servlet/ObdAjax?op=clone" + model;

	req.open("GET", url, true);
	req.myData = {msg: "", name:"", src:""};
	req.onreadystatechange = function() {
	    if (req.readyState == 4) {
	        if (req.status == 200) {
				parseXmlAuto(req);

	        	// draw new robot on page
	        	doneCloneBots(req.myData.name, req.myData.src);
	        }
	    }
	}	// END: callback function
	req.send(null);
}


function parseXmlAuto(l_req)
{
	// check returned string
	var str = getResponseXml("Message", l_req);		// there might be a message back (error)
	if (str != null) {
		// display the error message
		alert(str);
		req.myData.msg = str;
		return;
	}

	// get result string
	str = getResponseXml("Result", l_req) + "";
	if (str != null) {
		var parsedJSON = JSON.parse(str);
		var name = parsedJSON.botName;		// get new robot name
		var imgSrc = parsedJSON.imgSrc;

		// name is string
		if (l_req.myData != null) {
			l_req.myData.name = "" + name;
			l_req.myData.src = "" + imgSrc;
		}
		else
			alert(str+"");
	}

	return;
}