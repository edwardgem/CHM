<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>

<%
//
//	Copyright (c) 2006, EGI Technologies, Co.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: mtg_invite.jsp
//	Author: AGQ
//	Date:	08/22/06
//	Description: 
//		Invites all or selected current meeting attendees to participate
//		in the meeting records. Once new participates are invited, the 
//		current participate(s) will be revoked after the specified
//		time (0, 5, 10, 15, 30, 60 sec).
//
//	Modification:
//		@AGQ092806	Sends the characters before and after the current position
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "java.util.ArrayList" %>

<%@ page import = "util.PrmLog" %>
<%@ page import = "util.Util" %>

<%@ page import = "oct.codegen.meeting" %>
<%@ page import = "oct.codegen.meetingManager" %>
<%@ page import = "oct.codegen.user" %>
<%@ page import = "oct.codegen.userManager" %>
<%@ page import = "oct.pst.PstGuest" %>
<%@ page import = "oct.pst.PstAbstractObject" %>

<%@ page import = "org.apache.log4j.Logger" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%	// Initialize java variables
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	meetingManager 	mMgr = 		meetingManager.getInstance();
	userManager 	uMgr = 		userManager.getInstance();
	
	PstAbstractObject [] onlineParticipants;
	user curUser = (user) pstuser;
	meeting mtg;
	boolean isAdmin = false;
	int uid = curUser.getObjectId();

	Logger l = PrmLog.getLog();
	
	// Find current user's role
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if (iRole > 0)
	{
		if ((iRole & user.iROLE_ADMIN) > 0)
			isAdmin = true;
	}
	
	// Verifications
	String midS = request.getParameter("mid");
	int mid = 0;
	if (midS != null) {
		try {
			mid = Integer.parseInt(midS);
		} catch (NumberFormatException e) {
			l.error("Meeting ID parse exception for mid " + midS + " user " + uid);
		}
	}
	
	String close = request.getParameter("close");
	
	String posS = request.getParameter("pos");
	if (posS == null) posS = "";
	// @AGQ092806
	String charBefore = request.getParameter("charBefore");
	if (charBefore == null) charBefore = "";
	String charAfter = request.getParameter("charAfter");
	if (charAfter == null) charAfter = "";
	
	String isInvite = request.getParameter("isInvite");
	if (isInvite == null) isInvite = "true";
	
	if ((pstuser instanceof PstGuest) || (mid == 0))
	{		
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	
	// Check if I am the Facilitator
	mtg = (meeting) mMgr.get(curUser, mid);
	Object obj = mtg.getAttribute(meeting.RECORDER)[0];
	int mtgRID = 0; // Meeting Recorder ID
	if (obj!=null) {
		try {
			mtgRID = Integer.parseInt((String) obj);
		} catch (NumberFormatException e) {
			l.error("Invalid meeting Recorder ID value " + obj + " for meeting " + mid);
		}
	}
	
	if ((mtgRID == 0 || (mtgRID != uid)) && !isAdmin) {
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}

	// Get list of active meeting attendees
	// This process along w/ other filtering should be a bean
	Object [] objArr = mtg.getAttribute(meeting.ATTENDEE);
	ArrayList presentIds = new ArrayList();
	Integer curInt;
	if (objArr[0]!=null) {
		// Filter out non-online users
		String curObj;
		String [] curArr;
		for (int i=0; i<objArr.length; i++) {
			curObj = (String) objArr[i];
			if (curObj!=null) {
				curArr = curObj.split(meeting.DELIMITER);
				if (curArr.length == 2) {
					if(curArr[1].contains(meeting.ATT_LOGON)) { // Present Participants
						if (curArr[0]!=null) {
							try {
								curInt = Integer.valueOf(curArr[0]);
								presentIds.add(curInt);
							} catch (NumberFormatException e) {
								l.error("User ID parse error: " + curArr[0]);
							}
						}
					}
				}
			}
		}
	}
	
	objArr = presentIds.toArray();
	onlineParticipants = uMgr.get(curUser, objArr);
	Util.sortUserArray(onlineParticipants);

%>

<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>Meeting Input</title>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>

<script type="text/javascript">
<!--
var isMozilla = (navigator.userAgent.toLowerCase().indexOf('gecko')!=-1) ? true : false;

if ("close" == "<%=close%>") window.close();

window.onload = function() {
	if ("close" != "<%=close%>") {
		var items = <%=objArr.length %> - 1;
		var reHeight;
		if (isMozilla)
			reHeight = items * 19;
		else 
			reHeight = items * 20;
		var scr_w = screen.availWidth;
		var scr_h = screen.availHeight;
		var browseWidth, browseHeight;
		
		if(document.layers||(document.getElementById&&!document.all)){
		   browseWidth=window.outerWidth;
		   browseHeight=window.outerHeight;
		}else if(document.all){
		   browseWidth=document.body.clientWidth;
		   browseHeight=document.body.clientHeight;
		}
		
		var winw = (screen.width - browseWidth) / 2;
		var winh = (screen.height - (browseHeight+reHeight)) / 2;	
		window.resizeTo(browseWidth, browseHeight+reHeight);
		window.moveTo(winw, winh);
	}
}

// Disables or Enables all the online participants checkboxes
function disableCB(disable) {
	if (disable != true || disable != false)
		disable == true;
	var selectedParticipants = document.getElementsByName("selectedParticipants");
	for (i=0; i<selectedParticipants.length; i++) {
		if (selectedParticipants[i].disabled == disable) // They are all disabled already
			break;
		selectedParticipants[i].disabled = disable;
	}
}

function validate() {
	var type = document.getElementsByName("type")[2]; // selectParticipants
	if (type.checked == true) {
		var selectedParticipants = document.getElementsByName("selectedParticipants");
		var checked = false;
		for (i=0; i<selectedParticipants.length; i++) {
			if (selectedParticipants[i].checked) { // They are all disabled already
				checked = true;
				break;
			}
		}
		if (!checked) {
			alert("Please select attendees to particapate in the meeting minutes");
			return false;
		}
	}
	return true;
}
//-->
</script>

</head>
<body>

<table cellpadding="0" cellspacing="0" border="0" width="300">
	<tr><td class="formtext">Enable writing meeting minutes by:</td></tr>
	<tr><td>&nbsp;</td></tr>
	<tr>
		<td>
		<form action="post_mtg_invite.jsp" method="post" onsubmit="return validate()">
		<input type="hidden" name="mid" value="<%=mid %>">
		<input type="hidden" name="pos" value="<%=posS %>">
<%-- @AGQ092806 --%>
		<input type="hidden" name="charBefore" value="<%=charBefore %>">
		<input type="hidden" name="charAfter" value="<%=charAfter %>">
			<table cellpadding="0" cellspacing="0" border="0">
				<tr>
					<td>&nbsp;</td>
					<td><input type="radio" name="type" value="facilitator" onclick="javascript: disableCB(true)" 
<% if (isInvite.equals("false")) { %>					
					checked="checked"
<% } %>					
					></td>
					<td>&nbsp;</td>
					<td class="formtext">Facilitator</td>
				</tr>
				<tr>
					<td>&nbsp;</td>
					<td><input type="radio" name="type" value="allParticipants" onclick="javascript: disableCB(true)"
<% if (isInvite.equals("true")) { %>
					checked="checked"
<% } %>					
					></td>
					<td>&nbsp;</td>
					<td align="left" class="formtext">All online participants</td>
				</tr>
				<tr>
					<td>&nbsp;</td>
					<td><input type="radio" name="type" value="selectParticipants" onclick="javascript: disableCB(false)"></td>
					<td>&nbsp;</td>
					<td align="left" class="formtext">Selected online participants</td>
				</tr>	
				<tr>
					<td colspan="3">&nbsp;</td>
					<td>
<!-- Display Participant Names Begin -->
						<table cellpadding="0" cellspacing="0" border="0">
						
<%	// Display online participant names 
	user curParticipant;
	int curId;
	for (int i=0; i<onlineParticipants.length; i++) {
		curParticipant = (user) onlineParticipants[i];
		curId = curParticipant.getObjectId();
		out.print("<tr>");
		out.println("<td><input type='hidden' name='allParticipants' value='"+curId+"'></td>");
		if (uid != curId)
		{
			out.println("<td><input type='checkbox' name='selectedParticipants' value='"+curId+"' disabled='disabled'></td>");
			out.println("<td class='formtext'>&nbsp;"+curParticipant.getFullName()+"</td>");
		}
		else
			out.print("<td></td><td></td>");
		out.print("</tr>");
	}
%>

						</table>
<!-- Display Participant Names End -->						
					</td>
				</tr>				
				<tr><td colspan="4">&nbsp;</td></tr>
				<tr>
					<td colspan="4" class="formtext">
					Give 
					<select name="seconds" class="formtext">
						<option value="0">0</option> 
						<option value="5" selected="selected">5</option>
						<option value="10">10</option>
						<option value="15">15</option>
						<option value="30">30</option>	
						<option value="60">60</option>	
					</select>
					seconds before stopping input from participants.
					</td>
				</tr>		
				<tr><td colspan="4">&nbsp;</td></tr>
				<tr><td colspan="4">
					<table cellpadding="0" cellspacing="0" border="0">
						<tr>
							<td><input type="submit" class="button_medium" value="  OK  "></td>
							<td><input type="button" class="button_medium" value="  Cancel  " onclick="javascript: window.close();"></td>
						</tr>
					</table>
					</td>
				</tr>
			</table>
							
		</form> 
		</td>
	</tr>
</table>
</body>
</html>