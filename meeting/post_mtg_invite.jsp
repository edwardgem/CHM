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
//
//		@AGQ092806	Set before and after characters from the position to 
//					compare w/ server side.
//		@ECC101106	Input queue.
//		@AGQ101106	Update counter to reload mtg ntoes
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
<%@ page import = "oct.pst.PstManager" %>
<%@ page import = "oct.pst.PstAbstractObject" %>

<%@ page import = "mod.mfchat.MeetingParticipants" %>

<%@ page import = "org.apache.log4j.Logger" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%	// Initialize java variables
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	int USER_ORG = 7;
	meetingManager 	mMgr = 		meetingManager.getInstance();
	userManager 	uMgr = 		userManager.getInstance();
	
	PstAbstractObject [] onlineParticipants;
	user curUser = (user) pstuser;
	meeting mtg;
	boolean isAdmin = false;
	int uid = curUser.getObjectId();
	String uidS = String.valueOf(uid);

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

	if ((pstuser instanceof PstGuest) || (mid == 0))
	{		
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	
	String [] selectedParticipants = null;
	
	// @ECC101106 check to see if it is input queue calling me
	String enableQ = request.getParameter("qInput");
	String qUname = null;		// the person at head to enter input
	String s;
	String [] sa;
	String [] allParticipants = null;
	if (enableQ!=null)
	{
		qUname = request.getParameter("uname");

		// update the input queue on the server side
		if (enableQ.equals("enable"))	// enable current head guy to enter input
		{
			// enable the head person to input, so remove him from the head
			MeetingParticipants.removeFromInputQueue(midS, qUname);
			
			// qUid is the user name, get the Uid
			s = String.valueOf(PstManager.getIdByName(curUser, USER_ORG, qUname));
			selectedParticipants = new String[2];
			selectedParticipants[0] = s;		// this is the numeric id
			selectedParticipants[1] = uidS;
			// below we will add this user as the Q input person
		}
		else if (enableQ.equals("queue"))	// enable all people in queue to enter input
		{
			// remove all people from the queue
			s = MeetingParticipants.getRemoveAllOnQueue(midS);	// return edwardc:allenq: ...
			
			// add all people in queue to selectedParticipants
			sa = s.split(":");
			selectedParticipants = new String[sa.length+1];
			for (int i=0; i<sa.length; i++)
			{
				s = String.valueOf(PstManager.getIdByName(curUser, USER_ORG, sa[i]));
				selectedParticipants[i] = s;
			}
			selectedParticipants[sa.length] = uidS;
		}
		else if (enableQ.equals("all"))	// enable all online users to enter input
		{
			MeetingParticipants.getRemoveAllOnQueue(midS);	// just for removing; type below will handle it right
			s = MeetingParticipants.getAllOnline(midS);
			sa = s.split(":");
			allParticipants = new String[sa.length];
			for (int i=0; i<sa.length; i++)
			{
				allParticipants[i] = sa[i];
			}
		}
		else if (enableQ.equals("add"))
		{
			// add this user to the chat session, if he is already in, do nothing
			boolean doNothing = false;
			String [] curParticipants = MeetingParticipants.getMeetingParticipants(midS);
			MeetingParticipants.removeFromInputQueue(midS, qUname);
			s = String.valueOf(PstManager.getIdByName(curUser, USER_ORG, qUname));
			if (curParticipants == null)
			{
				// no chat session at this pt: add the uid and me (facilitator)
				selectedParticipants = new String[2];
				selectedParticipants[0] = s;
				selectedParticipants[1] = uidS;
			}
			else
			{
				for (int i=0; i<curParticipants.length; i++)
				{
					if (s.equals(curParticipants[i]))
					{
						// this person is already in the current chat session
						response.sendRedirect("mtg_live.jsp?mid="+mid+"&run=true&isShow=none&anchor=minute#minute");
						return;
					}
				}
				// add this person to the chat session
				selectedParticipants = new String[curParticipants.length+1];
				for (int i=0; i<curParticipants.length; i++)
					selectedParticipants[i] = curParticipants[i];
				selectedParticipants[curParticipants.length] = s;
			}
		}
		else if (enableQ.equals("stop") && qUname!=null)
		{
			// remove this user from chat session
			String [] curParticipants = MeetingParticipants.getMeetingParticipants(midS);
			selectedParticipants = new String[curParticipants.length-1];
			s = String.valueOf(PstManager.getIdByName(curUser, USER_ORG, qUname));
			int idx = 0;
			for (int i=0; i<curParticipants.length; i++)
			{
				if (s.equals(curParticipants[i]))
					continue;		// remove this user
				selectedParticipants[idx++] = curParticipants[i];
			}
		}
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
	
	// @AGQ092806 Setting the position and characters for comparison if required.
	String posS = request.getParameter("pos");
	if (posS!=null && posS.length() > 0 && !posS.equals("null"))
		MeetingParticipants.setPosition(midS, posS);
	String charBefore = request.getParameter("charBefore");
	if (charBefore!=null)
		MeetingParticipants.setCharBefore(midS, charBefore);
	String charAfter = request.getParameter("charAfter");
	if (charAfter!=null)
		MeetingParticipants.setCharAfter(midS, charAfter);
	
	// Check type and retreive according actions
	String type = request.getParameter("type");
	if (type!=null) {
		if (type.equals("facilitator")) {
			String [] facilitator = new String[1];
			facilitator[0] = String.valueOf(mtgRID);
			MeetingParticipants.setMeetingParticipants(midS, null);
		}
		else
		{
			if (type.equals("allParticipants")) {
				if (allParticipants == null)
					allParticipants = request.getParameterValues("allParticipants");
				MeetingParticipants.setMeetingParticipants(midS, allParticipants);
			}
			else if (type.equals("selectParticipants")) {
				if (selectedParticipants == null)
				{
					// coming from popup dialog box
					selectedParticipants = request.getParameterValues("selectedParticipants");
					String [] sArr = new String[selectedParticipants.length+1];
					int i;
					for (i=0; i<selectedParticipants.length; i++)
						sArr[i] = selectedParticipants[i];
					sArr[i] = uidS;		// always include facilitator
					selectedParticipants = sArr;
				}
				MeetingParticipants.setMeetingParticipants(midS, selectedParticipants);
			}
			// Initialize Facilitator as Red
			MeetingParticipants.getMeetingColor(midS, uidS);
			
			// @AGQ101106 Users need to reload the meeting notes
			util.PrmUpdateCounter.updateOrCreateCounterArray(midS, util.PrmMtgConstants.UDINDEX);
			// initialize the index offset between the chatIdx and MNCOUNT
			MeetingParticipants.setMeetingChatIdx(midS);
		}
		MeetingParticipants.setInputUser(midS, qUname);		// this can be null
	}

	mod.mfchat.PrmMtgParticipants.appendStatus(curUser, mid, uid);
	
	// Set current revoke time
	String revokeTime = request.getParameter("seconds");
	if (revokeTime!=null) {
		MeetingParticipants.setMeetingRevokeTime(midS, revokeTime);
	}
	
	// This should be redirected to a page that'll close the invite
	
	if (enableQ == null)
		response.sendRedirect("mtg_invite.jsp?mid="+mid+"&close=close");
	else
		response.sendRedirect("mtg_live.jsp?mid="+mid+"&run=true&isShow=none&anchor=minute#minute");
%>
	