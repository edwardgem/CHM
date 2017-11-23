<%
//
//	Copyright (c) 2009, EGI Technologies, Co.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: flowMap.jsp
//	Author: ECC
//	Date:	11/03/10
//	Description: Display a flow map of a project.
//
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "mod.box.PrmDrawFlow" %>
<%@ page import = "java.io.*" %>
<%@ page import = "util.*" %>

<%
	String projIdS = request.getParameter("projId");
	String noSession = "../out.jsp?go=box/flowMap.jsp?projId=" + projIdS;
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%
	if (Util.isNullString(projIdS)) {
		response.sendRedirect("../out.jsp?msg=Need to choose a project to display process flow map.");
		return;
	}
	PstFlowManager fsMgr = PstFlowManager.getInstance();
	projectManager pjMgr = projectManager.getInstance();

	project pj = (project) pjMgr.get(pstuser, Integer.parseInt(projIdS));
	String projDispName = pj.getDisplayName();
	
	// use the project to find the project flow object
	PstAbstractObject flowObj = pj.getProjectFlow(pstuser);
	if (flowObj == null) {
		response.sendRedirect("../out.jsp?msg=No flow object found for project [" + projDispName + "]");
		return;
	}
	// TODO: if there is no flow instance for this project, create one now
	
	//PstAbstractObject o = fdMgr.get(pstuser, "FlowSample1");
	PrmDrawFlow.Flow fObj = PrmDrawFlow.parseXMLtoFlow(pstuser, flowObj.getObjectId(), null);
	String flowName = "", htmlStr = "";
	String stepInfoStr = "";		// for passing step info to Javascript
	
	if (fObj != null) {
		flowName = fObj.getName();
		System.out.println("************** " + flowName);
		
		htmlStr = PrmDrawFlow.getFlowDisplayHTML(fObj);
		stepInfoStr = fObj.getStepInfoString();		// used by Javascript to display step info
		System.out.println(stepInfoStr);
		//System.out.println("htmlStr = " + htmlStr);
	}

	int winHeight = 400;
	String stackName = projDispName;

	// call a Java method to process the XML into an HTML table for display
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html lang="en">

<head>
<title><%=Prm.getAppTitle()%> Process Map</title>

<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<script type="text/javascript" src="../login_cookie.js"></script>
<script type="text/javascript" src="../resize.js"></script>

<style type="text/css">
.sd {font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 12px; color: #666666; height:46px; width:120px; line-height: 22px; text-align:center; vertical-align:middle; border:1px solid #656565;}
.sysSd {font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 12px; font-weight: bold; color: #cc0000; height:46px; width:100px; line-height: 22px; text-align:center; vertical-align:middle;}
.box {position:absolute; left:20; top:20; height:20; width:120; border-style:solid; border-color:grey; border-width:1;}
div.scrollFlow {overflow: auto; border: 1px solid #666; background-color: #ffffff; padding: 0px;
	font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 11px; color: #333333; line-height: 16px;}

.popInfo {display:none;position:absolute;}
.trans1 {position:absolute;left:400px;top:-400px;height:240px;width:350px;padding:10px;background:#eeeeee;filter:alpha(opacity=70);-moz-opacity:70%;}
.tx1 {filter:none;-moz-opacity:100%;position:relative;left:410px;top:-390px;}
.popTxt {font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 12px; color: #333333; line-height: 25px; vertical-align:middle;}
.tx_blue {  font-family: Verdana, Arial, Helvetica, sans-serif;font-size:12px;font-weight:bold; color:#336699;line-height:25px;}

</style>

<script language="JavaScript">
<!--
var IE = document.all?true:false;
document.onmousemove = getMouseXY;
document.onmouseup = mouseUp;
if (!IE) document.captureEvents(Event.MOUSEMOVE)

//Temporary variables to hold mouse x-y pos.s
var tempX = 0
var tempY = 0
var boxW = 120;
var boxH = 20;

var winCookieName = "flowWinHeight";
var divHeight = getCookie(winCookieName);

// step info arrays
var stepIdArr = new Array(0);
var stepInfoArr = new Array(0);

window.onload = function()
{	
	if (divHeight != null) {		
		var e = document.getElementById("mtgText0");	// the DIV scroll window
		e.style.height = divHeight;
	}
	else {		
		divHeight = <%=winHeight%>;
	}

	// to enable dragging editor box	
	setCookieName(winCookieName);
	initDrag(divHeight, 0);	
	new dragObject(handleBottom[0], null, new Position(0, <%=winHeight%>), new Position(0, 1000),
					null, BottomMove, null, false, 0);

	// get Java array
	var str = "<%=stepInfoStr%>";				// from Java
	var stepArr = str.split("@@");					// each element is a step
	stepIdArr = new Array(stepArr.length);			// step id array
	stepInfoArr = new Array(stepArr.length);		// step info array, same order as stepIdArr

	for (i=0; i<stepArr.length; i++) {
		str1 = stepArr[i];		// one step string
		var idx = str1.indexOf("|");
		stepIdArr[i] = str1.substring(0,idx);
		stepInfoArr[i] = str1.substring(idx+1);		// skip the first "|"
	}
}

function showStepInfoHTML(stepId)
{
	// display step info on a panel
	var infoHTML = "";
	
	// first look up the step by id
	var key, val;
	for (i=0; i<stepIdArr.length; i++) {
		if (stepIdArr[i] == ""+stepId) {
			// found step
			var str = stepInfoArr[i];
			var infoArr = str.split("|");
			infoHTML = "<table border='0' cellpadding='0' cellspacing='0'>";

			for (j=0; j<infoArr.length; j++) {
				var str1 = infoArr[j];
				var infoPair = str1.split("::");
				key = infoPair[0];
				val = infoPair[1];
				if (val == "null") val = "";
				
				infoHTML += "<tr><td class='tx_blue' width='100'>";
				infoHTML += key.capitalize() + "</td><td>:&nbsp;</td>";
				infoHTML += "<td class='poptxt' width='300'>";
				infoHTML += val + "</td></tr>";
			}
			infoHTML += "<tr><td><img src='../i/spacer.gif' width='1' height='5'/></td></tr></table>";
			break;
		}
	}

	// now display the info in the panel
	var e = document.getElementById("infoPanel");
	e.innerHTML = infoHTML;
}

function getMouseXY(e)
{
	if (IE) { // grab the x-y pos.s if browser is IE
		tempX = event.clientX + document.body.scrollLeft
		tempY = event.clientY + document.body.scrollTop
	} else {  // grab the x-y pos.s if browser is NS
		tempX = e.pageX
		tempY = e.pageY
	}
	
	// catch possible negative values
	if (tempX < 0){tempX = 0}
	if (tempY < 0){tempY = 0}

	if (bCapture) {
		moveBox();
	}
	return false;	// so that text will not be highlighted
}

function mouseUp()
{
	bCapture = false;
	var e;
	if (bSelectedPopInfo) {
		// moving the popInfo box
		bSelectedPopInfo = true;;
	}
	else {
		e = document.getElementById("boxId");
		if (e.style.display == "block") {
			// I am moving a box
			e.style.display = 'none';
		}
	}
}

function moveBox()
{
	var e;
	if (bSelectedPopInfo) {
		// moving popInfo box
		e = document.getElementById("popInfo");
		e.style.left = tempX - infoX;
		e.style.top  = tempY - infoY;
	}
	else {
		// moving a step retangle
		e = document.getElementById("boxId");
		e.style.left = tempX - boxW/2;
		e.style.top  = tempY - boxH/2;
	}
	return e;
}

var bCapture = false;
var selectedStepId = "";
function onClickStep(id)
{
	// click on a step retangle
	selectedStepId = "" + id;
	var eTD = document.getElementById("step_" + id);
	boxW = eTD.offsetWidth;
	boxH = eTD.offsetHeight;	
	//bCapture = true;
	//var e = moveBox();
	//e.style.width = boxW;
	//e.style.height = boxH;
	//e.style.display = 'block';

	// display step info
	popInfo(true, id);
}

function onDblClickStep(id)
{
	// doubleclick a step retangle
	// open its children task steps if there is any
}

function popInfo(op, id)
{
	// show the panel to display step/task info
	var e = document.getElementById("popInfo");
	if (op==true) {
		showStepInfoHTML(id);
		e.style.display = "block";
	}
	else
		e.style.display = "none";
}

var bSelectedPopInfo = false;
var infoX, infoY;
function clickOnPopInfoPanel()
{
	bSelectedPopInfo = true;
	bCapture = true;

	var e = document.getElementById('popInfo');
	infoX = tempX - e.offsetLeft;
	infoY = tempY - e.offsetTop;

	//window.status = infoX + "," + infoY + " | " + e.offsetLeft + "," + e.offsetTop + " | " + tempX + "," + tempY;
}

String.prototype.capitalize = function(){
	   return this.replace( /(^|\s)([a-z])/g , function(m,p1,p2){ return p1+p2.toUpperCase(); } );
	  };
	  
//-->
</script>

</head>

<!-- //////////////////////////////////////////// -->
<!-- Background white, links blue (unvisited), navy (visited), red (active) -->
<body bgcolor="#FFFFFF" text="#000000" link="#0000FF" leftmargin='20' topmargin='20'
vlink="#000080" alink="#FF0000">


<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="100%" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<table width='100%'>
	<tr><td colspan="2">&nbsp;</td></tr>
	<tr>
	<td></td>
	<td>
		<b class="head">Process Map</b>
	</td>
<%	if (htmlStr != "") { %>	
	<td width='30%'>
		<img src='../i/bullet_tri.gif'/>
		<a class='listlinkbold' href='updateProjFlow.jsp?projId=<%=projIdS%>&op=del'>Delete Process Map</a>
	</td>
<%	} %>	
	</tr>

	<tr>
		<td></td>
		<!-- td valign="top" class="title">
			&nbsp;&nbsp;&nbsp;<%=projDispName%>
		</td-->
	</tr>
	</table>

	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>


<!-- Navigation SUB-Menu -->
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
<td width="100%" valign="top">

	<table border="0" height="14" cellspacing="0" cellpadding="0">
		<tr>
			<td valign="top" align="right" class="bgsubnav">
				<table border="0" cellspacing="0" cellpadding="0">
				<tr class="bgsubnav">

					<td width="20"><img src="../i/spacer.gif" width="30" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
	<!-- File Repository -->
					<td width="20"><img src="../i/spacer.gif" width="10" height="1" border="0"></td>
					<td><a href="../project/cr.jsp?projId=<%=projIdS%>" class="subnav">File Repository</a></td>
					<td width="15"><img src="../i/spacer.gif" width="10" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
	<!-- Project Plan -->
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="../project/proj_plan.jsp?projId=<%=projIdS%>" class="subnav">Project Plan</a></td>
					<td colspan="3" width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
	<!-- Update All Tasks -->
					<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
					<td><a href="../project/task_updall.jsp?projId=<%=projIdS%>" class="subnav">Update All Tasks</a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
	<!-- Dependencies -->
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="../plan/dependency.jsp?projId=<%=projIdS%>" class="subnav">Dependencies</a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
	<!-- Timeline -->
					<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
					<td><a href="../plan/timeline.jsp?projId=<%=projIdS%>" class="subnav">Timeline</a></td>
					<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
	<!-- Work In-Tray -->
					<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
					<td><a href="../box/worktray.jsp" class="subnav">Work In-Tray</a></td>
					<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
	<!-- Process Map -->
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="20" height="14"><img src="../i/nav_arrow.gif" width="20" height="14" border="0"></td>
					<td><a href="#" onClick="return false;" class="subnav"><u>Process Map</u></a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

				</tr>
				</table>
			</td>
		</tr>
	</table>
	<table border="0" height="1" cellspacing="0" cellpadding="0">
		<tr>
			<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
		</tr>
	</table>

</td>
</tr>
</table>
<!-- End of Navigation SUB-Menu -->

</td>
</tr>

<!-- CONTENT -->
<tr><td><img src='../i/spacer.gif' height='20'/></td></tr>

<!-- Stack name -->
<tr>
	<td>
		<table>
			<tr>
				<td><img src='../i/spacer.gif' width='15'/></td>
				<td class='title'><%=stackName%></td>
			</tr>
		</table>
	</td>
</tr>

<tr>
<td>
<%
	if (htmlStr == "") {
		// need to generate flow XML from project plan
		out.println("<div class='plaintext_big'>No process map found for this project.</div><br/>");
		out.print("<div class='plaintext_bold'><img src='../i/bullet_tri.gif'/>");
		out.print("<a href='updateProjFlow.jsp?projId=" + projIdS + "'>Click to generate process map now</a></div>");
	}
	else {
		//htmlStr = htmlStr.replaceAll("border='0'", "border='1'");
		
		out.println("<div id='mtgText0' class='scrollFlow' style='height:" + winHeight + "px; width:95%;"
			+ "overflow-X:hidden;padding:2px;padding-top:0px;border:1px solid #909090;'>"
			+ "<table><tr><td><img src='../i/spacer.gif' height='20'/></td></tr></table>");
		out.print(htmlStr);
		out.print("<table><tr><td><img src='../i/spacer.gif' height='20'/></td></tr></table>");
		out.print("</div>");
		//out.println(htmlStr);
		
		out.print("<div align='right'>");
		out.print("<span id='handleBottom0' ><img src='../i/drag.gif' style='cursor:s-resize;'/></span>");
		out.print("<span><img src='../i/spacer.gif' width='70' height='1'/></span>");
		out.print("</div>");
	}
%>

<div class='box' id='boxId' style='display:none;'>
</div>


<DIV class='popInfo' id='popInfo' onmousedown='clickOnPopInfoPanel();'>
	<div class='trans1' id='popInfoBkg'></div>
	<div class='tx1' id='infoPanel'>
<!-- step info table will be placed here -->
	</div>
</DIV>


</td>
</tr>
<!-- Close CONTENT -->
<tr>
	<td>
		<!-- Footer -->
		<jsp:include page="../foot.jsp" flush="true"/>
		<!-- End of Footer -->
	</td>
</tr>
</table>
</body>
</html>

