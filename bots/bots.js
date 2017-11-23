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
var COLOR_BLACK		= '#333333';
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
// ipAddr


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
			                Links.push(ctX[idx] + ";"
			                		+ (newY)+ ";"				// +LINE_HEIGHT
			                		+ linkWidth + ";" + linkHeight + ";" + href);
							
			                newY = printStatus(idx, nm, COLOR_BLUE, newY);
			                chart[i-1][idx] = href;
						}
					}
				}
				
				// clear wait image
				clearWaitImage(idx);

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

function checkStatusAndDeploy(botName)
{
	// should check and see if the robot is deployed to these nodes
	// output checking ...
	totalCheckNum = ipAddr.length;
	for (var i=0; i<totalCheckNum; i++) {
		printStatus(i, "checking node ...");
		//animate(waitX[i], waitY[i], waitImg[i]);
		
		// this call will check the node, if OK, then deploy the bot if necessary
		ajaxCheckNodeReachable(i, botName);
		// ajaxCloneBot(i, botName);		// go directly to clone
	}
}

function printStatus(idx, stStr, color, Y)
{
	var imgObj = cImg[idx];
	
	var x = ctX[idx];
	var y;
	
	if (Y != null)
		y = Y;			// use user's specified Y
	else
		y = ctY[idx]+LINE_HEIGHT;		// skip the IP address line
	
	// text color
	if (color == null) color = COLOR_ORANGE;
	
	// clear text
	clearText(imgObj.txLines.length, x, y);
	
	// might be multiple lines for long text
	imgObj.txLines = getLines(ctx, stStr, LINE_WIDTH);
	ctx.fillStyle = color;
	
	for (var i=0; i<imgObj.txLines.length; i++) {
		ctx.fillText(imgObj.txLines[i], x, y);
		y += LINE_HEIGHT;
	}
	return y;
}

function clearText(numOfLines, x, y)
{
	var h = numOfLines * LINE_HEIGHT;
	ctx.clearRect(x,y-10,LINE_WIDTH,h);
}

function ajaxCheckNodeReachable(nodeIdx, botName)
{
	var req = reqCk[nodeIdx];
	var nodeIP = ipAddr[nodeIdx];
	
	if (window.XMLHttpRequest)
		req = new XMLHttpRequest();
	else if (window.ActiveXObject)
		req = new ActiveXObject("Microsoft.XMLHTTP");

	// parameter
	var idx0 = nodeIP.indexOf("//");		// skip http://
	if (idx0 == -1) idx0 = 0;
	else idx0 += 2;
	
	var idx = nodeIP.indexOf("/", idx0);
	if (idx != -1)
		nodeIP = nodeIP.substring(0, idx);
	var ip = "&ip=" + nodeIP;		// just the IP part for check node
	
	var url = "../servlet/ObdAjax?op=ckNode" + ip;

	req.open("GET", url, true);
	req.myData = {idx: nodeIdx, msg: ""};
	req.onreadystatechange = function() {
	    if (req.readyState == 4) {
	        if (req.status == 200) {
	        	var bError = false;
	        	var idx = req.myData.idx;
				parseXmlAuto(req);
				
				var s = req.myData.msg + "";
				var color = COLOR_GREEN;
				if (s.includes("Error")) {
					color = COLOR_RED;
					cImg[idx].myData.st = "error";
					bError = true;
				}
				printStatus(idx, s, color);
				
				// clear wait image
				clearWaitImage(idx);
				
				// Ajax call to clone robot on foreign node
				if (!bError) {			//  && !bReadOnly
					ajaxCloneBot(idx, botName);
				}
				else if (--totalCheckNum <= 0) {
					// enable Launch button
					document.botsCanvasForm.LaunchBut.disabled = false;
				}
	        }	// ==200
	    }	// ==4
	}	// callback function
	req.send(null);
}

// clone the bot if necessary (based on version)
function ajaxCloneBot(nodeIdx, botName) {
	printStatus(nodeIdx, "deploying Bot ...");
	
	var req;
	var domURL = ipAddr[nodeIdx];
	
	if (window.XMLHttpRequest)
		req = new XMLHttpRequest();
	else if (window.ActiveXObject)
		req = new ActiveXObject("Microsoft.XMLHTTP");

	// parameter
	var node = "&node=" + domURL;
	var bot = "&bot=" + botName;
	
	var url = "../servlet/ObdAjax?op=deploy" + node + bot;

	req.open("GET", url, true);
	req.myData = {idx: nodeIdx, msg: ""};
	
	// callback
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
				
				// enable Launch button
				if (--totalCheckNum <= 0) {
					document.botsCanvasForm.LaunchBut.disabled = false;
				}
	        }	// ==200
	    }	// ==4
	}	// callback function
	
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
		var res = parsedJSON.evals;			// get evals

		// evals is an array containing result and domain
		// deploy contains result and botId
		if (res!=null && typeof res!='undefined') {
			str = res[0].result;					// get result within evals
		}
		else {
			str = parsedJSON.result;
		}
		
		if (l_req.myData != null)
			l_req.myData.msg = str;
		else
			alert("NO myData element to hold: " + str);
	}

	return;
}

/////////////////////////
// Animation

function draw_anim(x1, y1, iobj) {
    if (iobj == null) return;
    ctx.drawImage(iobj, iobj.current*iobj.w, 0,
                      iobj.w, iobj.h,
                      x1, y1, 30, 30);
    iobj.current = (iobj.current + 1) % iobj.total_frames;
}

function clearWaitImage(i)
{
	var wiObj = waitImg[i];
	clearInterval(wiObj.interv);
	ctx.clearRect(waitX[i], waitY[i], 30, 30);
}

function animate(x1, y1, obj)
{
	obj.interv = setInterval(function() {draw_anim(x1, y1, obj);}, 140);
}

/////////////////////////
//SVG
function writeTable(x, y, color)
{
	var s = "";
	var i = 0;
	for (i=0; i<3; i++) {
		if (txArr[i]==undefined) break;
		s = "line" + i;
		var e = document.getElementById(s);
		e.innerHTML = txArr[i];
	}
	
	var h = 100 * i;
	if (color == null) color = COLOR_BLACK;

	var data = "<svg xmlns='http://www.w3.org/2000/svg' width='200' height='" + h + "'>" +
		"<style>td {font-size:12px;color:" + color + ";font-family:Verdana;}</style>" +
		"<foreignObject width='100%' height='100%'>" + $("#canvasTable").html() +
		"</foreignObject>" +
		"</svg>";
	var DOMURL = self.URL || self.webkitURL || self;
	var img = new Image();
	var svg = new Blob([data], {type: "image/svg+xml;charset=utf-8"});
	var url = DOMURL.createObjectURL(svg);
	img.onload = function() {
		ctx.drawImage(img, x, y-10);
		DOMURL.revokeObjectURL(url);
	};
	img.src = url;
	txArr = new Array();
}
