<%
//
//	Copyright (c) 2008, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_q_new.java
//	Author: ECC
//	Date:		01/03/2008
//	Description:	Post file for creating a new invite/quest or updating it
//				Note: Qtype=(event/quest); QuestType=(Public/Private); Type=template type
//				The Qtype and QuestType will join together and stored in the Type attribute (eventPublic)
//				While the template type will be stored in Category attr.
//	Modification:
//				@ECC022009	Add event to Google Calendar if GoogleID exists.
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.PepCommentVector" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	// create quest object
	PstUserAbstractObject me = pstuser;

	if (me instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	String s;

	int myUid = me.getObjectId();
	String myUidS = String.valueOf(myUid);
	String myName = ((user)me).getFullName();

	String from = (String)me.getAttribute("Email")[0];
	if (from == null)
		from = Util.getPropKey("pst", "FROM");

	questManager qMgr		= questManager.getInstance();
	userManager uMgr		= userManager.getInstance();
	quest qObj = null;

	String qidS = request.getParameter("Qid");
	if (qidS == "") qidS = null;
	String origin = request.getParameter("Origin");			// @SWS082206
	
	String parentIdS = request.getParameter("ParentId");
	if (parentIdS!=null && parentIdS.equals("null")) parentIdS = null;

	String descStr = request.getParameter("Description");	// @ECC110206
	if (descStr!=null && (descStr.trim().length()<=0 || descStr.equals("null")) ) descStr = null;
	
	String optMsg = request.getParameter("message");  		// @SWS092706
	// get optional message
	if (optMsg != null && optMsg.length()>0 && !optMsg.equals("null")) {
		optMsg = optMsg.replaceAll("\n", "<br>");
		optMsg = "<b>Message from " + myName + ": </b><br><div STYLE='font-size: 12px; font-family: Courier New'><br>"
				+ optMsg + "</div><br />";
	}
	else {
		optMsg = "";
	}

	Object [] userIdArr = null;
	boolean bSendAlert = false;
	if (request.getParameter("SendAlert") != null || origin != null)
		bSendAlert = true;
	
	boolean bSendReminderOnly = request.getParameter("sendReminderOnly")!=null;
	
	String [] sa;
	String subject = null;
	String questType;	// public or private
	String qType;		// Qtype: invite or questionnaire
	long lo;
	boolean isEvent = false;
	boolean bNewQuest = false;		// creating a new meeting?
			
	String newSum = request.getParameter("Summary");
	if (qidS == null)
	{
		// creating new quest
		bNewQuest = true;
		qObj = (quest)qMgr.create(me);
		qObj.setAttribute("Creator", myUidS);		// if update, don't change creator just in case if it is Admin doing the update
		qObj.setAttribute("ParentID", parentIdS);
		
		qObj.setAttribute("Summary", newSum);
	}
	else
	{
		// update the existing quest
		// OR bSendReminderOnly, in which case I will not commit any changes
		qObj = (quest)qMgr.get(me, qidS);
		
		// init summary if it wasn't there
		String oldSum = (String)qObj.getAttribute("Summary")[0];
		if (oldSum == null)
			qObj.setAttribute("Summary", newSum);
		else
		{
			// allow appending new questions when update
			if (newSum != null)
			{
				String [] sa1 = oldSum.split("@@");
				String [] sa2 = newSum.split("@@");
				if (sa2.length > sa1.length)
				{
					int idx = sa1.length;
					s = oldSum;
					while (idx < sa2.length)
						s += quest.DELIMITER1 + sa2[idx++];
					qObj.setAttribute("Summary", s);				// updated the summary with new questions
				}
			}
		}
	}

	subject = request.getParameter("Subject");
	qObj.setAttribute("Subject", subject);
	String location = request.getParameter("Location");
	if (!Util.isNullString(location)) {
		qObj.setAttribute("Location", location);
	}
	
	s = request.getParameter("mid").trim();
	if (s!=null && s.length()<=0) s = null;
	qObj.setAttribute("MeetingID", s);
	
	// user click "Finish" on q_new1.jsp
	boolean clickFinish = false;
	s = request.getParameter("Finish");
	if (s!=null && s.equals("true"))
		clickFinish = true;					// in this case, don't touch the question set and don't send notification
	
	// @ECC102706
	String company = request.getParameter("company");
	if (company!=null && (company.equals("0") || company.equals("null")) )
		company = null;
	qObj.setAttribute("TownID", company);
	
	// @ECC022909 support project association of quest
	String projectS = request.getParameter("ProjectId");
	if (projectS!=null && (projectS.length()<=0 || projectS.equals("null")) )
		projectS = null;
	qObj.setAttribute("ProjectID", projectS);
		
	
	// Qtype: invite/quest
	qType = request.getParameter("Qtype");
	if (qType.equals(quest.TYPE_EVENT))
		isEvent = true;
	
	// Type public or private
	questType = request.getParameter("meetingType");
	if (questType == null) questType = quest.PUBLIC;
	
	// check to see if this quest is shared among all participants
	String qShare = (request.getParameter("Shared") == null) ? quest.NO_SHARE : "";

	// Type combines qType and questType (eventPublic)
	qObj.setAttribute("Type", qType+questType+qShare);
		
	// @ECC110206 Description
	if (descStr != null)
	{
		// convert the plain text to HTML
		descStr = descStr.replaceAll("\n", "<br>");
		descStr = descStr.replaceAll("  ", "&nbsp;");
		qObj.setAttribute("Description", descStr.getBytes("utf-8"));
	}
	
	String mandatoryS = request.getParameter("Mandatory");
	int tempLength = 0;
	if (mandatoryS != null && mandatoryS.length() > 0)
		tempLength += mandatoryS.split(";").length;
	
	// set attendee attributes (id::State)
	qObj.setAttribute("Attendee", null);			// clear it to begin with
	Object [] temp = new Object[tempLength];
	int num = 0;
	if (mandatoryS!=null && mandatoryS.length()>0)
	{
		sa = mandatoryS.split(";");	// id1;id2;id3,...
		for (int i=0; i<sa.length; i++)
		{
			qObj.appendAttribute("Attendee",sa[i]);
		}
	}

	// set up email recipient address
	userIdArr = new Object[num+1];		// contain the user id (String) of the recipient
	for (int i=0; i<num; i++)
		userIdArr[i] = temp[i];
	userIdArr[num] = myUidS;			// the quest creator

	// Dates: event has both start and expire; quest only expiredate
	long diff = 0;
	s = request.getParameter("LocalStartDT");		// ECC: not used?
	if (s!=null && s.length()>0 && !s.equals("null"))
		diff = Long.parseLong(s);
	if (isEvent)
	{
		String startDT = request.getParameter("StartDT");
		if (startDT!=null && startDT.length()>0 && !startDT.equals("null"))
		{
			lo = Long.parseLong(startDT);	// - diff;
			Date startDate = new Date(lo);
			qObj.setAttribute("StartDate", startDate);
		}
	}
	
	String endDT = request.getParameter("ExpireDT");
	if (endDT!=null && endDT.length()>0 && !endDT.equals("null"))
	{
		lo = Long.parseLong(endDT);			// - diff;
		Date expireDate = new Date(lo);
		qObj.setAttribute("ExpireDate", expireDate);
	}

	// for both create quest and update quest agenda (the questions)
	String agendaS = request.getParameter("Agenda");
	boolean bNoQuestion = false;
	if (agendaS != null)
		qObj.setAttribute("Content", agendaS.getBytes("utf-8"));
	if (agendaS==null || agendaS.length()<=0)
		bNoQuestion = true;
		
	String type = request.getParameter("Type");
	String templateName = request.getParameter("TemplateName");	
	if (type!=null && !type.equals("null")) {
		StringBuffer sb = new StringBuffer();
		if (type.length() > 0) {
			sb.append(type);
			sb.append(meeting.DELIMITER);
		}
		if (templateName!=null && templateName.length() > 0) {
			sb.append(templateName);
		}
		qObj.setAttribute(meeting.CATEGORY, sb.toString());
	}
	
	// Store guest's emails so user can update and resent emails later
	Object obj = session.getAttribute("guestEmails");
	Object [] guestEmails = null;
	if (obj == null) {
		guestEmails = Util.expandGuestEmails(request.getParameter("guestEmails"));
		if (guestEmails == null)
			guestEmails = qObj.getAttribute(meeting.GUESTEMAILS);
		else
			qObj.setAttribute("GuestEmails", guestEmails);
	}
	else {
		guestEmails = (Object [])obj;
		qObj.setAttribute("GuestEmails", guestEmails);
		session.removeAttribute("guestEmails");
	}
	
	// @AGQ091906
	if (guestEmails != null && guestEmails.length > 0)
	{
		// check to see if I need to convert guestEmails to user ids
		//Integer []	userIdArrT;	// Holds user Ids
		ArrayList	guestToUserId	= new ArrayList(); // Converted user Ids from emails
		ArrayList	emailArr 	= new ArrayList(); // GuestEmails
		int noOfConversion = 0; // Number of guestEmails converted to Users Ids
		Object [] objArrGE = qObj.getAttribute(meeting.GUESTEMAILS);
		// @AGQ cannot reuse same object array because of meeting commit
		Object [] objArrAtt = qObj.getAttribute(meeting.ATTENDEE); 	
		
		// Get all attendee IDs to compare w/ GuestEmails
		int [] attIArr = new int[objArrAtt.length];
		if (objArrAtt[0]!=null) {
			String tempS = null;
			String [] splitS = null;
			for (int i=0; i<objArrAtt.length; i++) {
				tempS = (String) objArrAtt[i];
				if (tempS != null) {
					splitS = tempS.split(meeting.DELIMITER);
					if (splitS.length > 0) {
						try {
							attIArr[i] = Integer.parseInt(splitS[0]);
						} catch (NumberFormatException e) {
							//e.printStackTrace();
							System.out.println("!! Error parsing [" + splitS[0] + "] in post_q_new.jsp");
							continue;
						}
					}
				}
			}
		}

		// Convert GuestEmails to User Ids					
		if (objArrGE[0] != null) {
			String email;
			int [] curIArr;
			for (int i=0; i<objArrGE.length; i++) {
				email = ((String) objArrGE[i]).trim();
				curIArr = uMgr.findId(me, "Email='"+email+"'");
				if (curIArr.length > 0) {
					for (int j=0; j<curIArr.length; j++) {
						guestToUserId.add(Integer.valueOf(curIArr[j]));
						// @AGQ090606
						qObj.removeAttributeIgnoreCase(meeting.GUESTEMAILS, email);
						// Compare attendee IDs with GuestEmail to remove duplicate
						// TODO: this algorithm is slow
						boolean found = false;
						for (int k=0; k<attIArr.length; k++) {
							if (attIArr[k] == curIArr[j]) {
								found = true;
								break;
							}
						}
						if (!found)
							qObj.appendAttribute(meeting.ATTENDEE, String.valueOf(curIArr[j]));
					}
				}
				else {
					emailArr.add(email);
				}
			}
		}

		noOfConversion = guestToUserId.size();
		
		// Convert Attendee to User Ids					
		int noOfUserIds; // Number of User Ids
		if (objArrAtt[0] != null) {
			noOfUserIds = objArrAtt.length;
			userIdArr = new Object[noOfUserIds + noOfConversion];
			for (int i=0; i<objArrAtt.length; i++) {
				userIdArr[i] = Integer.valueOf(attIArr[i]);
			}
		}
		// No user id found
		else {
			noOfUserIds = 0;
			userIdArr = new Object[noOfUserIds + noOfConversion];
		}
		
		// Add remaining converted users
		if (noOfConversion > 0) {
			for (int i=0; i<noOfConversion; i++) {
				userIdArr[i+noOfUserIds] = (Object) guestToUserId.get(i); 
			}
		}
		guestEmails = emailArr.toArray();
	}	// END if there are guestEmails

	// see if quest is to be sent immediately or at a schedule time
	boolean bSendQuestNow = false;
	s = request.getParameter("qSend");
	if (clickFinish || s.equals("0"))
	{
		bSendQuestNow = true;
		qObj.setAttribute("State", quest.ST_ACTIVE);
	}
	else
	{
		// to be sent at a later time
		String sendDT = request.getParameter("SendDT");
		if (sendDT!=null && !sendDT.equals("null"))
		{
			lo = Long.parseLong(sendDT) - userinfo.getServerUTCdiff();
			qObj.setAttribute("EffectiveDate", new Date(lo));
		}
		if (qObj.getAttribute("State")[0] == null)
			qObj.setAttribute("State", quest.ST_NEW);
	}
	
	// commit changes to quest
	if (!bSendReminderOnly) {
		qMgr.commit(qObj);
	}
	else {
		// I might have mess up the qObj above, retrieve it from DB again
		qObj = (quest)qMgr.get(me, qidS);
	}
	
	// send alert Email
	if (bSendReminderOnly || (!clickFinish && bSendAlert))
		Util2.sendInvitation(me, qObj, optMsg);
	
	if (!bSendReminderOnly) {
		UtilThread uThread = new UtilThread(UtilThread.APPEND_CONTACTS, me, qObj);
		uThread.start();
	
		// @ECC101807 event triggers
		if (bSendQuestNow && !bNoQuestion && bNewQuest)	// don't trigger event if there is no question ask
		{
			if (qidS == null) qidS = String.valueOf(qObj.getObjectId());
			String circleIdS = (String)qObj.getAttribute("TownID")[0];
			if (isEvent)
				s = PrmEvent.EVT_INV_NEW;
			else
				s = PrmEvent.EVT_QST_NEW;
		
				PrmEvent.createTriggerEvent(me, s, qidS, circleIdS, null);
		}
		
		// Google calendar
		// TODO: in the future we should support update/delete Google calendar event
		if (isEvent && bNewQuest && me.getStringAttribute("GoogleID")!=null) {
			try {
				PrmGoogle googleHandler = new PrmGoogle(me, true);		// handle for Google calendar
				googleHandler.addEvent(qObj, (TimeZone)session.getAttribute("javaTimeZone"));
			}
			catch (Exception e) {
				response.sendRedirect("../out.jsp?go=meeting/cal.jsp&msg=Failed to add Google Calendar event: " + e.getMessage());
				e.printStackTrace();
				return;
			}
		}
	}
	
	// ready to jump to the right yr/mo on cal.jsp
	String yr=null, mo=null;
	Date dt = (Date)qObj.getAttribute("StartDate")[0];
	if (dt == null) {
		dt = (Date) qObj.getAttribute("ExpireDate")[0];
		if (dt == null) {
			dt = new Date();
		}
	}
	SimpleDateFormat df0 = new SimpleDateFormat ("yyyy/MM");
	s = df0.format(dt);
	yr = s.substring(0,4);
	mo = s.substring(5,7);
	
	response.sendRedirect("../meeting/cal.jsp?year=" + yr + "&month=" + (Integer.parseInt(mo)-1));

%>
