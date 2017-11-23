<%@page import="sun.swing.StringUIClientPropertyKey"%>
<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>

<%
////////////////////////////////////////////////////
//	Copyright (c) 2017, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	botsCanvas.jsp
//	Author:	ECC
//	Date:	04/11/17
//	Description:
//		Omm Robot canvas page for graphics display of distributive Big Data.
//		Supports the deploy and launch functions.
//
//	Modification:
//
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>

<%@ page import = "javax.xml.parsers.*" %>
<%@ page import = "org.w3c.dom.*" %>
<%@ page import = "org.xml.sax.SAXException" %>
<%@ page import = "org.xml.sax.InputSource" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />


<%
	// the top-left of Central image.  All canvas coordinates depend on these
	final int OM_X					= 430;
	final int OM_Y					= 100;
	
	final String EXT_XML			= ".xml";
	final String TAG_DOMAIN			= "Domain";				// distributive domain specification
	final String TAG_EVAL_METHOD	= "Eval_Method";
	final String TAG_EXPR			= "Expr";
	final String TAG_OTHERS			= "Chart";
	
	// require login
	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	robotManager rbMgr = robotManager.getInstance();
	
	String s;
	int canvasHeight = 300;		// change based on how many nodes to be put on canvas
	
	String evalClassName = "";
	String evalMethodName = "";
	String expr = "None";
	String otherParams = "";
	String orgName = "";
	int idx;
	
	//boolean isReadOnly = pstuser.getStringAttribute("Title").toLowerCase().contains("demo");

	
	String botId = request.getParameter("id");
	robot rbObj = (robot) rbMgr.get(pstuser, Integer.parseInt(botId));
	
	String botName = rbObj.getObjectName();
	String botDispName = rbObj.getStringAttribute("DisplayName");
	
	String xml = rbObj.getRawAttributeAsUtf8("Content");
	if (StringUtil.isNullOrEmptyString(xml)) {
		response.sendRedirect("../out.jsp?msg=Specify the launching parameter before deployment.");
		return;
	}
	
	
	if (xml.indexOf('&')!=-1 && xml.indexOf("&amp;")==-1) {
		// Document parser can't take && or < signs
		xml = xml.replaceAll("&", "&amp;");		// escape & sign in the condition expression &\\s+
		xml = xml.replaceAll("<=", "&lt;&#61;");
	}
	DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
	DocumentBuilder builder = factory.newDocumentBuilder();
	InputSource is = new InputSource(new StringReader(xml));
	Document document = builder.parse(is);

	Element root = document.getDocumentElement();
	
	// get eval() class method
	if ((s = XML.getXMLString(TAG_EVAL_METHOD, root)) != null) {
		idx = s.lastIndexOf(".");
		if (idx == -1) {
			response.sendRedirect("../out.jsp?msg=<"+TAG_EVAL_METHOD+"> tag illegal class.method expression: " + s);
			return;
		}
		evalClassName  = s.substring(0,idx).trim();
		evalMethodName = s.substring(idx+1).trim() + "()";
	}
	
	// expression
	if ((s = XML.getXMLString(TAG_EXPR, root)) != null) {
		expr = s.replaceAll("&amp;", "&").replaceAll("&lt;", "<").replaceAll("&gt;", ">");
		//expr = Util.stringToHTMLString(s.trim());
	}
	
	// other parameters
	if ((s = XML.getXMLString(TAG_OTHERS, root)) != null) {
		otherParams = Util.stringToHTMLString(s.trim());
	}
	
	// ECC: orgname (temp)
	if ((s = XML.getXMLString("Org_Name", root)) != null) {
		orgName = Util.stringToHTMLString(s.trim());
	}

	// nodes URL only
	ArrayList <String> nodeList = new ArrayList<String>();
	int totalNodesInXML;

	//XML.getNodeIpAddr(nodeList, root, TAG_DOMAIN);
	XML.getNodeArray(nodeList, root, TAG_DOMAIN);

	if (nodeList.size() <= 0) {
		// just run local
		nodeList.add("localhost/PRM");
	}
	totalNodesInXML = nodeList.size();
	
	String nodeStr = Arrays.toString(nodeList.toArray());
	nodeStr = nodeStr.substring(1, nodeStr.length()-1);			// strip [...] from string
	 
	if (totalNodesInXML > 2)
		canvasHeight = 400;

%>



<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<link href="oct-bots.css" rel="stylesheet" type="text/css" />
<script language="JavaScript" src="../meeting/ajax_utils.js"></script>
<script language="JavaScript" src="bots.js"></script>

<script src="https://code.jquery.com/jquery-1.10.1.min.js"></script>
<script src="https://code.jquery.com/jquery-migrate-1.2.1.min.js"></script>

<script language="JavaScript">


<!--

var totalNodes = <%=totalNodesInXML%>;

var cubeImgSrc = "../i/cube.png";
var waitImgSrc = "../i/wait-sprite.png";


var ommCanvas;		// canvas
var ctx;			// context

var chart = [[],[]];

////

var animate_obj = {
	    'source': null,
	    'current': 0,
	    'total_frames': 12,
	    'width': 75,
	    'height': 75
	};


/////

// *** all coordinates depend on omX and omY ***
// center image coordinates
var omX = <%=OM_X%>;
var omY = <%=OM_Y%>;

if (totalNodes <= 1) omX -= 50;

// nodes images coordinates
var cX = [(omX+260), (omX-160), (omX+260), (omX-150), 0];
var cY = [(omY-90), (omY-70),  (omY+130), (omY+160), 0];

// nodes images
var cImg  = [new Image(), new Image(), new Image(), new Image(), new Image()];
var MAX_NODES = cImg.length;

// wait images
var waitImg = [new Image(), new Image(), new Image(), new Image(), new Image()];

// remember lines of text to wipe out
for (var i=0; i<MAX_NODES; i++){
	cImg[i].txLines = [];
}

//lines coordinates
var lineX = [(cX[0]+60), (cX[1]+60), cX[2]+60, cX[3]+60, 0];
var lineY = [(cY[0]+30), (cY[1]+55), cY[2]+50, cY[3]+30, 0];

// text coordinates
var ctX = [(cX[0]+75), (cX[1]-140), (cX[2]+75),  (cX[3]-140), 0];
var ctY = [(cY[0]+35), (cY[1]+65),  (cY[2]+35),  (cY[3]+65), 0];

// wait coordinates
var waitX = [ctX[0],    ctX[1],    ctX[2],    ctX[3], 0];
var waitY = [ctY[0]-45, ctY[1]-45, ctY[2]-45, ctY[3]-45, 0];

// arrays for IP and Authcode
var ipAddr = '<%=nodeStr%>'.split(", ");

var x, y;
var txArr = new Array();

window.onload = function()
{
	drawNodes();
}

// get the Robot content from XML
function drawNodes()
{
	ommCanvas = document.getElementById("ommCanvas");
    ctx = ommCanvas.getContext("2d");

    ctx.font = "14px Lucida Grande";
    
    var img = new Image();
    img.src = "../i/cloud.png";

    // =====
    // draw lines
    for (var i=0; i<totalNodes; i++) {
        x = omX+130; y = omY+80;
        ctx.moveTo(x, y);
    	ctx.lineTo(lineX[i], lineY[i]);
    	ctx.stroke();
    }
    
	// =====
	// draw Central
    img.onload = function() {
        ctx.drawImage(img, omX, omY);
    };
    
    // =====
    // cubes
    for (i=0; i<totalNodes; i++) {
	    cImg[i].myData = {x:cX[i], y:cY[i], st:""};
	    cImg[i].onload = myImageOnload;
	    cImg[i].src = cubeImgSrc;
	    
	    // wait image
	    if (waitX[i] > 0) {
	    	waitImg[i].idx = i;
	    	waitImg[i].onload = waitImageOnload;
	    	waitImg[i].src = waitImgSrc;
	    }
	    
	    // text
	    //ctx.fillText("IP: " + ipAddr[i], ctX[i], ctY[i]);
	    txArr[0] = "IP: " + ipAddr[i];
	    writeTable(ctX[i], ctY[i]);
	}
    
    // =============================
    // check node status and deploy (in bots.js)
    checkStatusAndDeploy("<%=botName%>");		// check and output status (ajax)
  
}

function myImageOnload ()
{
	ctx.drawImage(this, this.myData.x, this.myData.y);
}

function waitImageOnload ()
{
    this.current = -1;
    this.total_frames = 12;
    this.w = 75;
    this.h = 75;
    this.interv = null;
	
	//animate(waitX[this.idx], waitY[this.idx], this);
}

function backToBot()
{
	location = "ommBots.jsp?id=<%=botId%>";
}

// fire the remote request through Ajax
function fire()
{
	chart = [[],[]];
	botsCanvasForm.LaunchBut.disabled = true;
	totalCheckNum = 0;
	for (i=0; i<totalNodes; i++) {
		if (cImg[i].myData.st != 'error') {
			totalCheckNum++;
			clearText(6, ctX[i], ctY[i]+LINE_HEIGHT);	// clear 6 lines of text
		}
	}
	
	for (i=0; i<totalNodes; i++) {
		if (cImg[i].myData.st != 'error') {
			animate(waitX[i], waitY[i], waitImg[i]);
			ajaxFire("<%=botName%>", "<%=expr%>", "<%=otherParams%>", i, "<%=orgName%>");
		}
	}
	return;
}

function analyze()
{
	// combine the graphics together
	analyzeForm.Histogram.value = chart[0].join();
	analyzeForm.Scattergram.value = chart[1].join();
	if (analyzeForm.Histogram.value=='' || analyzeForm.Scattergram.value=='')
	{
		alert("Please make sure you have fired a Robot on more than one nodes to perform comparison.");
		return false;
	}
	analyzeForm.submit();
}

//-->
</script>

<style type="text/css">
.inst1 { font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 12px; color: #333333; line-height: 16px; vertical-align:top;} 
</style>

<title>
	Omm Robots
</title>

</head>


<body bgcolor="#FFFFFF" >

<div id="canvasTable" style='display:none;'>
    <div xmlns="http://www.w3.org/1999/xhtml" style='font-size:12px'>      
        <table border='0' class="aTable" cellspacing='0' cellpadding='0'>
			<tr><td id='line0'></td></tr>        
			<tr><td id='line1'></td></tr>        
        </table>
    </div>
</div>

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="100%" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<table>

	<tr><td colspan="2">&nbsp;</td></tr>
	<tr>
	<td></td>
	<td class="head">
		Big Data Analytics
	</td></tr>

	</table>

	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- CONTENT -->
<form method="post" name="botsCanvasForm" action="post_ommBots.jsp">

<table border='0' cellspacing='0' cellpadding='0' width='90%'>

	<tr>
		<td width='30'>&nbsp;</td>
		<td colspan='2' class='instruction_head'><br/>OMM Robot: <font color='#336699'><%=botDispName%></font></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td colspan='2'>
			<table width='500'>
			<tr>
				<td><img src='../i/spacer.gif' width='20' height='5'/></td>
				<td><img src='../i/spacer.gif' width='150' height='1'/></td>
				<td></td>
				<td></td>
			</tr>
			
			<tr>
				<td></td>
				<td class='inst1'>Distributive nodes</td>
				<td class='inst1'>:</td><td class='inst1'><%=totalNodesInXML%></td>
			</tr>
			
			<tr>
				<td></td>
				<td class='inst1'>Program</td>
				<td class='inst1'>:</td><td class='inst1'><%=evalClassName%>.<%=evalMethodName%></td>
			</tr>
			
			<tr>
				<td></td>
				<td class='inst1'>Condition</td>
				<td class='inst1'>:</td><td class='inst1'><%=expr%></td>
			</tr>
			</table>
		</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='30'/></td></tr>


<!-- Canvas -->
	<tr><td><img src='../i/spacer.gif' width='15' height='1'/></td>
	<td colspan='2' width='100%'>
		<canvas id="ommCanvas" width='1050' height='<%=canvasHeight%>' style="border:0px solid #555555;">
		</canvas>
	</td></tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='20'/></td></tr>


<!-- Submit Button -->
	<tr>
		<td width="15"></td>
		<td colspan='2' class="10ptype" align="right"><br/>
		<table border='0'><tr>
			<td><img src='../i/chartComp.png' width='35' onclick='analyze();' />&nbsp;</td>
			<td><input type="button" name="LaunchBut" value="  Launch  " onclick='return fire();' class='button_medium' disabled /></td>
			<td><input type="button" value="Back" onclick="backToBot();" class='button_medium'/>&nbsp;&nbsp;&nbsp;</td>
			<td><input type="button" value="Close" onclick="window.close();" class='button_medium'/></td>
		</tr></table>
		</td>
	</tr>

	
</table>

</form>

<form method="post" name="analyzeForm" action="botsAnalysis.jsp">
<input type='hidden' name='BotName' value='<%=botDispName%>' />
<input type='hidden' name='Histogram' value='' />
<input type='hidden' name='Scattergram' value='' />
</form>


<!-- BEGIN FOOTER TABLE -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</td></tr>
</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

