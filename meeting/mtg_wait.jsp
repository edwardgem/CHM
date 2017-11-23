<%
//
//	Copyright (c) 2005, EGI Technologies, Co.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: mtg_wait.jsp
//	Author: ECC
//	Date:	02/24/05
//	Description: Waiting for a meeting to start.
//
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "util.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.omm.common.*" %>
<%@ page import = "oct.omm.client.*" %>
<%@ page import = "oct.omm.db.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />
<%

	String midS = request.getParameter("mid");
	if ((pstuser instanceof PstGuest) || (midS == null))
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}

	int myUid = pstuser.getObjectId();

	int iRole = ((Integer)session.getAttribute("role")).intValue();
	
	// to check if session is OMF or PRM
	boolean isOMFAPP = false;
	String appS = (String)session.getAttribute("app");
	if (appS.equals("OMF"))
	{
		appS = "MeetWE";
		isOMFAPP = true;
	}

	meetingManager mMgr = meetingManager.getInstance();
	meeting mtg = (meeting)mMgr.get(pstuser, midS);

	String status = (String)mtg.getAttribute("Status")[0];
	if (status!=null && status.equals(meeting.LIVE))		// timing window: status can be null
	{
		// go join the meeting
		response.sendRedirect("mtg_live.jsp?mid="+midS);
		return;
	}

%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html lang="en">

<head>
<META HTTP-EQUIV='Refresh' CONTENT='15'>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">

<div id="fader" style="position:absolute; top:200px; left:50px; width:600px; text-align:center;"></div>
<!-- adjust style= to position messages -->

<SCRIPT LANGUAGE="JavaScript">

<!-- Begin
//  texts:
//  Your messages wich may contain regular html tags but
//  must at least contain: [ <font color='{COLOR}'> ]
//  Use single quotes [ ' ] in your html only. If you need
//  a double quote in the message itself use an escape
//  sign like this: [ \" ]  (not including the brackets)

var texts = new Array(
"<font size='+2' color='{COLOR}' face='Arial'><strong>W A I T I N G</strong></font>",
"<font size='+3' color='{COLOR}' face='Arial'><strong>for</strong></font>",
"<font size='+4' color='{COLOR}' face='Arial'><strong>M e e t i n g</strong></font>",
"<font size='+3' color='{COLOR}' face='Arial'><strong>to</font>",
"<font size='+3' color='{COLOR}' face='Arial'><strong>Start</strong></font>");

var bgcolor = "#ffffff"; // background color, must be valid browser hex color (not color names)
var fcolor = "#FF8000";  // foreground or font color
var steps = 20; // number of steps to fade
var show = 500; // milliseconds to display message
var sleep = 30; // milliseconds to pause inbetween messages
var loop = true; // true = continue to display messages, false = stop at last message

// Do Not Edit Below This Line
var colors = new Array(steps);
getFadeColors(bgcolor,fcolor,colors);
var color = 0;
var text = 0;
var step = 1;

// fade: magic fader function
function fade()
{

	// insert fader color into message
	var text_out = texts[text].replace("{COLOR}", colors[color]); // texts should be defined in user script, e.g.: var texts = new Array("<font color='{COLOR}' sized='+3' face='Arial'>howdy</font>");

	// actually write message to document
	if (document.all) fader.innerHTML = text_out; // document.all = IE only
	if (document.layers)
	{
		document.fader.document.write(text_out); document.fader.document.close();
	} // document.layers = Netscape only

	// select next fader color
	color += step;

	// completely faded in?
	if (color >= colors.length-1)
	{
		step = -1; // traverse colors array backward to fade out

		// stop at last message if loop=false
		if (!loop && text >= texts.length-1) return; // loop should be defined in user script, e.g.: var loop=true;
	}

	// completely faded out?
	if (color == 0)
	{
		step = 1; // traverse colors array forward to fade in again

		// select next message
		text += 1;
		if (text == texts.length) text = 0; // loop back to first message
	}

	// subtle timing logic...
	setTimeout("fade()", (color == colors.length-2 && step == -1) ? show : ((color == 1 && step == 1) ? sleep : 50)); // sleep and show should be defined in user script, e.g.: var sleep=30; var show=500;
}
// getFadeColors: fills Colors (predefined Array)
// with color hex strings fading from ColorA to ColorB

// note: Colors.length equals the number of steps to fade
function getFadeColors(ColorA, ColorB, Colors)
{
	len = Colors.length;

	// strip '#' signs if present
	if (ColorA.charAt(0)=='#') ColorA = ColorA.substring(1);
	if (ColorB.charAt(0)=='#') ColorB = ColorB.substring(1);

	// substract rgb compents from hex string
	var r = HexToInt(ColorA.substring(0,2));
	var g = HexToInt(ColorA.substring(2,4));
	var b = HexToInt(ColorA.substring(4,6));
	var r2 = HexToInt(ColorB.substring(0,2));
	var g2 = HexToInt(ColorB.substring(2,4));
	var b2 = HexToInt(ColorB.substring(4,6));

	// calculate size of step for each color component
	var rStep = Math.round((r2 - r) / len);
	var gStep = Math.round((g2 - g) / len);
	var bStep = Math.round((b2 - b) / len);

	// fill Colors array with fader colors
	for (i = 0; i < len-1; i++)
	{
		Colors[i] = "#" + IntToHex(r) + IntToHex(g) + IntToHex(b);
		r += rStep;
		g += gStep;
		b += bStep;
	}
	Colors[len-1] = ColorB; // make sure we finish exactly at ColorB
}

// IntToHex: converts integers between 0-255 into a two digit hex string.
function IntToHex(n)
{
	var result = n.toString(16);
	if (result.length==1) result = "0"+result;
	return result;
}

// HexToInt: converts two digit hex strings into integer.
function HexToInt(hex)
{
	return parseInt(hex, 16);
}

// body tag must include: onload="fade()" bgcolor="#000000"  where bgcolor equals bgcolor in javascript above
//  End -->
</script>


</head>

<title><%=appS%> Wait Meeting</title>
<body onLoad="fade()"  bgcolor="#000000" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" height="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">
		<!-- Main Tables -->
		<table width="100%" border="0" cellspacing="0" cellpadding="0">
		  	<tr>
		    	<td width="100%" valign="top">
					<!-- Top -->
					<jsp:include page="../head.jsp" flush="true"/>
					<!-- End of Top -->
				</td>
			</tr>
			<tr>
	          <td>
	            <table width="780" border="0" cellspacing="0" cellpadding="0">
				  <tr>
					<td width="26" height="30"><a name="top">&nbsp;</a></td>
                	<td width="754" height="30" align="left" valign="bottom" class="head">
                	<b>Waiting for Meeting</b>
					</td>
					</tr>
	            </table>
	          </td>
	        </tr>
			<tr>
          		<td width="100%">
					<!-- Navigation Menu -->
					<jsp:include page="../in/imtg.jsp" flush="true">
					<jsp:param name="role" value="<%=iRole%>" />
					</jsp:include>
					<!-- End of Navigation Menu -->
				</td>
	        </tr>
			<tr>
          		<td width="100%" valign="top">
					<!-- Navigation SUB-Menu -->
					<table border="0" width="780" height="1" cellspacing="0" cellpadding="0">
						<tr>
							<td width="20" height="1" bgcolor="#FFFFFF"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
							<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
						</tr>
					</table>
					<table border="0" width="780" height="14" cellspacing="0" cellpadding="0">
						<tr>
							<td width="20" height="14" bgcolor="#FFFFFF"><img src="../i/spacer.gif" height="1" border="0"></td>
							<td valign="top" class="BgSubnav">
								<table border="0" cellspacing="0" cellpadding="0">
								<tr class="BgSubnav">
								<td width="40"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
					<!-- Calendar -->
									<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td><a href="cal.jsp" class="subnav">Calendar</a></td>
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<!-- Search -->
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td><a href="mtg_search.jsp" class="subnav">Search Meeting</a></td>
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<!-- New Meeting -->
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td><a href="mtg_new1.jsp" class="subnav">New Meeting</a></td>
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
								</tr>
								</table>
							</td>
						</tr>
					</table>
					<table border="0" width="780" height="1" cellspacing="0" cellpadding="0">
						<tr>
							<td width="20" height="1" bgcolor="#FFFFFF"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
							<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
						</tr>
					</table>
					<!-- End of Navigation SUB-Menu -->
				</td>
	        </tr>
		</table>

<!-- Content Table -->

<table width="770" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td width="20" align="right"><img src="../i/spacer.gif" border="0" width="15" height="1"></td>
	<td width="150">&nbsp;</td>
	<td width="600">&nbsp;</td>
</tr>


<tr><td colspan='3'>&nbsp;</td></tr>

</table>

</td>
</tr>

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
