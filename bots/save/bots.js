//
//	Copyright (c) 2017 EGI Technologies.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	bots.js
//	Author:	ECC
//	Date:	04/15/07
//  Description:
//      This js file deals with ajax calls for OmmBots. botsCanvas.jsp calls this
//
//	Dependency:
//		ajax_util.js, botsCanvas.jsp
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////


var isMSIE = (navigator.userAgent.toLowerCase().indexOf('msie')!=-1)?true:false;
var fullURL = parent.document.URL;

var COLOR_GREEN		= '#00aa00';
var COLOR_ORANGE	= '#dd7700';
var COLOR_RED		= '#aa0000';
var COLOR_BLACK		= '#222222';
var COLOR_BLUE		= '#2222ee';

var LINE_WIDTH		= 250;
var LINE_HEIGHT		= 20;

// need to use array because there will be multiple nodes simultaneous Ajax calls
var reqCk = new Array();
var reqFire = new Array();

var gMsg;					// ajax return message

var Links = new Array();	// Links information
var hoverLink = "";			// Href of the link which cursor points at

var totalCheckNum = 0;


// defined in botsCanvas.jsp
// ctx


// fire bots request to a node
// others is used to specify other parameters, usually analysis charts to be displayed
function ajaxFire(botName, exprValue, others, nodeIdx, orgName)
{
	var req = reqFire[nodeIdx];
	var domURL = ipAddr[nodeIdx];
	
	if (window.XMLHttpRequest)
		req = new XMLHttpRequest();
	else if (window.ActiveXObject)
		req = new ActiveXObject("Microsoft.XMLHTTP");

	// parameters
	var bot = "&bot=" + botName;
	var org = "&org=" + orgName;
	
	var node = "";
	if (domURL!=null && domURL!="") {
		domURL = encodeURIComponent(domURL);
		node = "&node=" + domURL;
	}
	
	//var	expr = "";
	//if (exprValue!=null && exprValue!="")
	//	expr = "&expr=" + encodeURIComponent(exprValue);
	
	var oth = "";
	if (others!=null && others!="") {
		others = domURL + ";" + others;			// put the node IP Addr in front of other param
		oth = "&oth=" + others;
	}

	var url = "../servlet/ObdAjax?op=fire" + bot + oth + org + node;	// take out expr which cause problem

	req.open("GET", url, true);
	req.myData = {idx: nodeIdx, msg: ""};
	req.onreadystatechange = function() {
	    if (req.readyState == 4) {
	        if (req.status == 200) {
	        	var idx = req.myData.idx;
	        	printStatus(idx, "Robot completed", COLOR_GREEN);
				parseXmlAuto(req);
				var msg = req.myData.msg + "";

				if (msg.includes("Error")) {
					printStatus(idx, msg, COLOR_RED);
					cImg[idx].myData.st = "error";
				}
				else {
					// output result. Handle also image links
					// msg0 is the text message; msg1-n are the images
					var mMsg = msg.split("@");
					var newY = printStatus(idx, mMsg[0], COLOR_BLACK);

					var s, nm = "", href="";
					var idx1;
					if (mMsg.length > 1) {
						for (i=1; i<mMsg.length; i++) {
							// image links
							s = mMsg[i];
							idx1 = s.indexOf('$$');			// name$$Href
							nm = s.substring(0, idx1);
							href = s.substring(idx1+2);
							
							var linkWidth = ctx.measureText(nm).width;
							var linkHeight = LINE_HEIGHT;
			                ommCanvas.addEventListener("mousemove", on_MouseMove, false);
			                ommCanvas.addEventListener("click", on_click, false);
	
			                // Add link params to array
			                Links.push(ctX[idx] + ";" + (newY+LINE_HEIGHT) + ";" + linkWidth + ";" + linkHeight + ";" + href);
							
			                newY = printStatus(idx, nm, COLOR_BLUE, newY);
			                chart[i-1][idx] = href;
						}
					}
				}
				
				// clear wait image
				var wiObj = waitImg[idx];
				clearInterval(wiObj.interv);
				ctx.clearRect(waitX[idx], waitY[idx], 30, 30);

				if (--totalCheckNum <= 0) {
					document.botsCanvasForm.LaunchBut.disabled = false;
				}
	        }
	    }
	}	// END: callback function
	req.send(null);
	printStatus(i, "Robot " + botName + " evaluating ...", COLOR_GREEN);
}


function ajaxGetInfo(infoType, tkValue)
{
	if (window.XMLHttpRequest)
		reqInfo = new XMLHttpRequest();
	else if (window.ActiveXObject)
		reqInfo = new ActiveXObject("Microsoft.XMLHTTP");

	// parameters
	var type = "&type=" + infoType;
	
	var node = "";
	if (domURL!=null && domURL!="")
		node = "&node=" + domURL;
	
	var token = "";
	if (tkValue!=null && tkValue!="")
		token = "&tk=" + tkValue;

	var url = "../servlet/ObdAjax?op=getInfo" + type + token + node;

	reqInfo.open("GET", url, true);
	reqInfo.onreadystatechange = function() {
	    if (reqInfo.readyState == 4) {
	        if (reqInfo.status == 200) {
				parseXmlAuto(reqInfo);
	        }
	    }
	}
	reqInfo.send(null);
}

function checkStatus(nodeIPs)
{
	// output checking ...
	for (var i=0; i<nodeIPs.length; i++) {
		printStatus(i, "checking ...");
	}
	
	// ajax call to check node CPM login status
	totalCheckNum = nodeIPs.length;
	for (var i=0; i<nodeIPs.length; i++) {
		// check to see if the robot is deployed to these nodes
		ajaxCheckNodeReachable(nodeIPs[i], i);
	}
}

function printStatus(idx, stStr, color, Y)
{
	var imgObj = cImg[idx];
	
	var x = ctX[idx];
	var y = ctY[idx]+LINE_HEIGHT;		// skip the IP address line
	
	if (Y != null)
		y = Y;			// use user's specified Y
	
	// text color
	if (color == null) color = COLOR_ORANGE;
	// clear text
	var h = imgObj.txLines.length * LINE_HEIGHT;
	ctx.clearRect(x,y-10,LINE_WIDTH,h);
	
	// might be multiple lines for long text
	imgObj.txLines = getLines(ctx, stStr, LINE_WIDTH);
	ctx.fillStyle = color;
	
	for (var i=0; i<imgObj.txLines.length; i++) {
		ctx.fillText(imgObj.txLines[i], x, y);
		y += LINE_HEIGHT;
	}
	return y;
}

function ajaxCheckNodeReachable(nodeIP, nodeIdx)
{
	var req = reqCk[nodeIdx];
	
	if (window.XMLHttpRequest)
		req = new XMLHttpRequest();
	else if (window.ActiveXObject)
		req = new ActiveXObject("Microsoft.XMLHTTP");

	// parameter
	var ip = "&ip=" + nodeIP;
	
	var url = "../servlet/ObdAjax?op=ckNode" + ip;

	req.open("GET", url, true);
	req.myData = {idx: nodeIdx, msg: ""};
	req.onreadystatechange = function() {
	    if (req.readyState == 4) {
	        if (req.status == 200) {
	        	var idx = req.myData.idx;
				parseXmlAuto(req);
				
				var s = req.myData.msg + "";
				var color = COLOR_GREEN;
				if (s.includes("Error")) {
					color = COLOR_RED;
					cImg[idx].myData.st = "error";
				}
				printStatus(idx, s, color);
				
				// clear wait image
				var wiObj = waitImg[idx];
				clearInterval(wiObj.interv);
				ctx.clearRect(waitX[idx], waitY[idx], 30, 30);
				
				// enable Launch button
				if (--totalCheckNum <= 0) {
					document.botsCanvasForm.LaunchBut.disabled = false;
				}
	        }
	    }
	}
	req.send(null);
}

function getLines(ctx, text, maxWidth) {
	// replace \n with a word [newline]
	text = text.split("\n").join(" [newline] ");
    var words = text.split(" ");
    var lines = [];
    var currentLine = words[0];

    for (var i=1; i<words.length; i++) {
        var word = words[i];
        var width = ctx.measureText(currentLine + " " + word).width;
        
        if (width>=maxWidth || word=="[newline]") {
        	// save currentLine, then go to next line
            lines.push(currentLine);
            if (word != "[newline]")
            	currentLine = word;
            else
            	currentLine = "";
        }
        else {
        	if (currentLine != "") currentLine += " ";
            currentLine += word;
        }
    }
    lines.push(currentLine);
    return lines;
}

function on_MouseMove(e) {
    var x, y;
    if (e.layerX || e.layerX == 0) { // for firefox
        x = e.layerX;
        y = e.layerY;
    }
    x -= ommCanvas.offsetLeft;
    y -= ommCanvas.offsetTop-40;
    
    for (var i = Links.length - 1; i >= 0; i--) {
        var params = new Array();

        // Get link params back from array
        params = Links[i].split(";");

        var linkX = parseInt(params[0]),
            linkY = parseInt(params[1]),
            linkWidth = parseInt(params[2]),
            linkHeight = parseInt(params[3]),
            linkHref = params[4];

        // Check if cursor is in the link area
        if (x >= linkX && x <= (linkX + linkWidth) && y >= linkY && y <= (linkY + linkHeight)){
            document.body.style.cursor = "pointer";
            hoverLink = linkHref;
            break;
        }
        else {
            document.body.style.cursor = "";
            hoverLink = "";
        }
    }
}

function on_click (e) {
    if (hoverLink) {
        window.open(hoverLink, '_blank');
    }
}

function parseXmlAuto(l_req)
{
	// check returned string
	var str = getResponseXml("Message", l_req);		// there might be a message back (error)
	if (str != null) {
		// display the error message
		if (typeof l_req.myData != 'undefined')
			l_req.myData.msg = str;
		else
			gMsg = str;
		return;
	}

	// get result string
	str = getResponseXml("Result", l_req) + "";
	if (str != null) {
		
		var parsedJSON = JSON.parse(str);
		var evals = parsedJSON.evals;			// get evals

		// evals is an array containing result and domain
		str = evals[0].result;					// get result within evals
		if (l_req.myData != null)
			l_req.myData.msg = str;
		else
			alert("NO myData element to hold: " + str);
	}

	return;
}

/////////////////////////
// Animation

function draw_anim(context, x1, y1, iobj) { // context is the canvas 2d context.
    if (iobj == null) return;
    context.drawImage(iobj, iobj.current*iobj.w, 0,
                      iobj.w, iobj.h,
                      x1, y1, 30, 30);
    iobj.current = (iobj.current + 1) % iobj.total_frames;
}

function animate(x1, y1, obj)
{
	obj.interv = setInterval(function() {draw_anim(ctx, x1, y1, obj);}, 140);
}
