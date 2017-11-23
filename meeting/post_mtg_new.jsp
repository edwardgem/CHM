<%@ page contentType="text/html; charset=utf-8"%>

<%
//
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_mtg_new.java
//	Author: ECC
//	Date:		03/01/2005
//	Description:	Create a new meeting or update meeting agenda
//	Modification:
//			@041805ECC	Support creating VCS (vCalendar) file for meeting.
//			@ECC092005	Attach agenda to meeting invitation
//			@ECC100605	Support create follow meeting either from a standalone meeting or
//						at the end of a recurring event.
//			@AGQ030106	Support of over 100 meeting attendees
//			@ECC061206a	Add project association to meeting.
//			@AGQ081506	Sends exchange calendar emails
//			@SWS082206  Redirect to live meeting page of from startNow new meetings.
//						Takes empty agenda for new meeting setup procedure can be end before page mtg_new3.jsp
//			@AGQ091906	Convert all Emails to Users
//			@ECC110206	Add Description attribute.  Only saved to this one meeting, no recurring.
//			@ECC101807	Support event triggers.
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
<%@ page import = "com.oreilly.servlet.*" %>
<%@ page import = "mod.xcalendar.XCalendarBean" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	// create meeting object
	PstUserAbstractObject me = pstuser;
	if (me instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	String s;
	String appS = Util.getPropKey("pst", "APPLICATION");
	if (appS == null || appS.equals("OMF")) appS = "MeetWE";		// for email to use

	int myUid = me.getObjectId();
	String uidS = String.valueOf(myUid);
	String myName = ((user)me).getFullName();
	//String myName = (String)me.getAttribute("FirstName")[0];
	//s = (String)me.getAttribute("LastName")[0];
	//if (!s.equals("?")) myName = myName + (s==null?"":(" " + s));

	String from = (String)me.getAttribute("Email")[0];
	if (from == null)
		from = Util.getPropKey("pst", "FROM");

	meetingManager mMgr		= meetingManager.getInstance();
	userManager uMgr		= userManager.getInstance();
	userinfoManager uiMgr	= userinfoManager.getInstance();
	
	userinfo myUI = (userinfo)uiMgr.get(pstuser, String.valueOf(myUid));
	meeting mtg = null;

	String midS = request.getParameter("mid");
	String origin = request.getParameter("Origin");			// @SWS082206

	String descStr = request.getParameter("Description");	// @ECC110206
	if (descStr!=null && (descStr.trim().length()<=0 || descStr.equals("null")) ) descStr = null;
	
	String optMsg = request.getParameter("message");  		// @SWS092706
	// get optional message
	if (optMsg != null && optMsg.length()>0 && !optMsg.equals("null"))
	{
		optMsg = optMsg.replaceAll("\n", "<br>");
		optMsg = "<b>Message from " + myName + ": </b><br><div STYLE='font-size: 12px; font-family: Courier New'><br>"
				+ optMsg + "</div><br />";
	}
	else
		optMsg = "";

	Object [] userIdArr = null;
	boolean bSendAlert = false;
	if (request.getParameter("SendAlert") != null || origin != null)
		bSendAlert = true;

	String [] sa;
	String subject = null;
	int recurNum = 0;
	String recurring = null;
	String meetingType;
	
	boolean bNewMeeting = false;		// creating a new meeting?
	if (midS == null) // @SWS082206
	{
		bNewMeeting = true;
		if (origin != null && origin.equalsIgnoreCase("mtg_new2"))
		{
			String agendaS = request.getParameter("Agenda");
			String lastmidS = request.getParameter("Lastmid");		// @ECC100605
			if (lastmidS == null) lastmidS = "";

			Object [] agendaArr = new Object[0];
			if (lastmidS.length()>0)
			{
				PstAbstractObject obj = mMgr.get(me, lastmidS);
				agendaArr = obj.getAttribute("AgendaItem");
			}

			// begin setting up plan stack
			// Agenda is represented by a Vector of Task
			// Task is represented by a hashtable.
			Vector rAgenda = new Vector();
			String itemName;
			int i = 0;

			// process the plan script to create a list of JwTask
			JwTask [] taskArray = null;
			try
			{
				JwTask jw = new JwTask();
				taskArray = jw.processScript(agendaS);
			}
			catch (PmpException e)
			{
				String [] st = e.toString().split(":");
				String msg = st[1];
				msg += ": \"<b>" + st[2] + "</b>\"";
				response.sendRedirect("../out.jsp?msg="+ msg);
				return;
			}

			while (true)
			{
				// pTask is the persistent Task
				// rTask is the ram task which is in cache
				if (taskArray==null || taskArray[i] == null) break;

				JwTask pTask = taskArray[i++];
				s = pTask.getName();
				if (s.length() >= 240)
				{
					s = "The following agenda item is longer than the maximum length (240) allowed:<blockquote>" + s + "</blockquote>";
					response.sendRedirect("../out.jsp?msg="+ s);
					return;
				}
				Hashtable rTask = new Hashtable();
				rTask.put("Order", pTask.getOrder());
				rTask.put("Level", pTask.getLevel());
				rTask.put("Name", s);

				// @ECC100605
				for (int j=0; j<agendaArr.length; j++)
				{
					String ss = (String)agendaArr[j];		// (pre-order::order::level::item::duration::owner)
					sa = ss.split(meeting.DELIMITER);
					try{
						itemName = sa[3].replaceAll("@@", ":");
						if (itemName.equals(s))
						{
							rTask.put("Duration", sa[4]);
							rTask.put("Responsible", sa[5]);
						}
					}
					catch (Exception e) {break;}
				}

				rAgenda.addElement(rTask);
			}
			session.setAttribute("agenda", rAgenda);
		}
		// this is to create a new meeting
		subject = request.getParameter("Subject");
		
		// confRoomSelect
		String location = null;
		String confRoom = request.getParameter("confRoomSelect");
		System.out.println(">>>>>>>>>>>>" + confRoom);
		
		if (confRoom.equals("other")) {
			// user specify his own meeting location
			location = request.getParameter("Location");
			System.out.println(location);
		}
		
		else {
			// user chooses a conference room for booking
			// need to book a room
			location = confRoom;
		}
		
//System.out.println(">>>>> conf = " + confRoom);
//System.out.println(">>>>> loc = " + location);
		
		String startDT = request.getParameter("StartDT");	// in msec obtained using a local time
		String endDT = request.getParameter("ExpireDT");
		long lStartDt = Long.parseLong(startDT);	// - myUI.getTimeZoneDiff()*3600000;	// back to PST time
		long lEndDt = Long.parseLong(endDT);	// - myUI.getTimeZoneDiff()*3600000;	// back to PST time

		String projIdS = request.getParameter("ProjectId");			// @ECC061206a
		recurring = request.getParameter("Recurring");
		if (recurring.length() == 0) recurring = null;
		if (recurring != null)
		{
			s = request.getParameter("RecurMultiple");
			try {recurNum = Integer.parseInt(s);}
			catch (Exception e){recurNum = 1;}
			if (recurNum <= 0) recurNum = 1;
			recurring += meeting.DELIMITER + recurNum;
			
			// @ECC030309: possible Monthly::3::13::mon;wed
			String temp = "";
			if (recurring.contains(meeting.MONTHLY))
			{
				if ((s = request.getParameter("Recur1"))!=null && s.length()>0 && s.equals("on"))
					temp += "1;";
				if ((s = request.getParameter("Recur2"))!=null && s.length()>0 && s.equals("on"))
					temp += "2;";
				if ((s = request.getParameter("Recur3"))!=null && s.length()>0 && s.equals("on"))
					temp += "3;";
				if ((s = request.getParameter("Recur4"))!=null && s.length()>0 && s.equals("on"))
					temp += "4;";
				if ((s = request.getParameter("Recur5"))!=null && s.length()>0 && s.equals("on"))
					temp += "5;";
				if (temp.length() > 0)
					recurring += meeting.DELIMITER + temp.substring(0, temp.length()-1);
			}
			if (recurring.contains(meeting.MONTHLY) || recurring.contains(meeting.WEEKLY))
			{
				temp = "";
				if ((s = request.getParameter("RecurSun"))!=null && s.length()>0 && s.equals("on"))
					temp += Calendar.SUNDAY + ";";
				if ((s = request.getParameter("RecurMon"))!=null && s.length()>0 && s.equals("on"))
					temp += Calendar.MONDAY + ";";
				if ((s = request.getParameter("RecurTue"))!=null && s.length()>0 && s.equals("on"))
					temp += Calendar.TUESDAY + ";";
				if ((s = request.getParameter("RecurWed"))!=null && s.length()>0 && s.equals("on"))
					temp += Calendar.WEDNESDAY + ";";
				if ((s = request.getParameter("RecurThu"))!=null && s.length()>0 && s.equals("on"))
					temp += Calendar.THURSDAY + ";";
				if ((s = request.getParameter("RecurFri"))!=null && s.length()>0 && s.equals("on"))
					temp += Calendar.FRIDAY + ";";
				if ((s = request.getParameter("RecurSat"))!=null && s.length()>0 && s.equals("on"))
					temp += Calendar.SATURDAY + ";";
				if (temp.length() > 0)
					recurring += meeting.DELIMITER + temp.substring(0, temp.length()-1);
			}
		}
		/*long diff = userinfo.getServerUTCdiff();
		long lo = Long.parseLong(startDT) - diff;
		Date startDate = new Date(lo);
		lo = Long.parseLong(endDT) - diff;
		Date expireDate = new Date(lo);*/
		Date startDate = new Date(lStartDt);
		Date expireDate = new Date(lEndDt);
System.out.println("*** post - ready to create");
System.out.println("   startDT=" + startDT);
System.out.println("   startDate=" + startDate);


		// Type public or private
		meetingType = request.getParameter("meetingType");
		if (meetingType == null) meetingType = meeting.PRIVATE;
		
		// @ECC102706
		String company = request.getParameter("company");
		if (company!=null && (company.equals("0") || company.equals("null")) )
			company = null;

		// create the meeting object (including all the recurring events)
		mtg = meeting.create(me,
			uidS, subject, startDate, expireDate, location, recurring, projIdS, meetingType, company);		// @ECC061206a
		
		// set meeting status
		if (expireDate.before(new Date()))
			mtg.setAttribute("Status", meeting.EXPIRE);		// the meeting is in the past
		else
			mtg.setAttribute("Status", meeting.NEW);
			
		// @ECC110206 Description
		if (descStr != null)
		{
			// convert the plain text to HTML
			descStr = descStr.replaceAll("\n", "<br>");
			descStr = descStr.replaceAll("  ", " &nbsp;");
			mtg.setAttribute("Description", descStr.getBytes("utf-8"));
		}
		
		String mandatoryS = request.getParameter("Mandatory");
		String optionalS = request.getParameter("Optional");
// @AGQ030106
		int tempLength = 0;
		if (mandatoryS != null && mandatoryS.length() > 0)
			tempLength += mandatoryS.split(";").length;
		if (optionalS != null && optionalS.length() > 0)
			tempLength += optionalS.split(";").length;
		
		if (tempLength >= meeting.MAX_ATT)
		{
			response.sendRedirect("../out.jsp?msg=You have exceeded the maximum number of attendees (" + meeting.MAX_ATT + ") to a meeting.");
			return;
		}
		
		// set attendee attributes (id::State)
		Object [] temp = new Object[tempLength];
		int num = 0;
		if (mandatoryS!=null && mandatoryS.length()>0)
		{
			sa = mandatoryS.split(";");	// id1;id2;id3,...
			for (int i=0; i<sa.length; i++)
			{
				s = sa[i] + meeting.DELIMITER + meeting.ATT_MANDATORY;
				if (sa[i].equals(uidS))
				{
					s += meeting.ATT_ACCEPT;		// coordinator must accept
				}
				else
					temp[num++] = sa[i];
				mtg.appendAttribute("Attendee",s);
			}
		}
		if (optionalS!=null && optionalS.length()>0)
		{
			sa = optionalS.split(";");	// id1;id2;id3,...
			for (int i=0; i<sa.length; i++)
			{
				s = sa[i] + meeting.DELIMITER + meeting.ATT_OPTIONAL;
				mtg.appendAttribute("Attendee",s);
				temp[num++] = sa[i];
			}
		}
		mtg.updateRecurring(me, "Attendee");		// copy attendee attribute to all recurring events

		// set up email recipient address
		userIdArr = new Object[num+1];		// contain the user id (String) of the recipient
		for (int i=0; i<num; i++)
			userIdArr[i] = temp[i];
		userIdArr[num] = uidS;				// the meeting coordinator
	}	// END: if new Meeting
	else
	{
		// this is update meeting agenda
		mtg = (meeting)mMgr.get(me, midS);
		mtg.setAttribute("AgendaItem", null);		// clear agenda
		subject = (String)mtg.getAttribute("Subject")[0];
		meetingType = (String)mtg.getAttribute("Type")[0];

		// set up email recipient address
		userIdArr = mtg.getAttribute("Attendee");
		for (int i=0; i<userIdArr.length; i++)
		{
			if (userIdArr[i] == null) break;
			s = (String)userIdArr[i];
			sa = s.split(meeting.DELIMITER);
			userIdArr[i] = sa[0];			// contain the user id (String) of the recipient
		}
	}

	// for both create meeting and update meeting agenda
	// set agenda item attributes (preorder::order::level::item::duration::owner)
	Vector rAgenda = (Vector)session.getAttribute("agenda");
	session.removeAttribute("agenda");		// free memory
	Integer pLevel, pOrder;
	int level, order;
	String pName, duration, owner;
	Hashtable rTask;
	if (rAgenda != null && rAgenda.size()>0) // @SWS082206
	{
		for(int i = 0; i < rAgenda.size(); i++)
		{
			rTask = (Hashtable)rAgenda.elementAt(i);
			pName = (String)rTask.get("Name");
			pName = pName.replaceAll(":", "@@");		// COLOR (:) will be confused with DELIMITER
			pLevel = (Integer)rTask.get("Level");
			pOrder = (Integer)rTask.get("Order");

			level = pLevel.intValue();
			order = pOrder.intValue();

			duration = request.getParameter("ItemTime_" + i);
			owner = request.getParameter("Owner_" + i);
	
			if (duration == null) duration = "0";
			if (owner == null) owner = uidS;
			s = i + meeting.DELIMITER
						+ order + meeting.DELIMITER
						+ level + meeting.DELIMITER
						+ pName + meeting.DELIMITER
						+ duration + meeting.DELIMITER
						+ owner;
			mtg.appendAttribute("AgendaItem", s);
		}
	}
	

	// always copy agenda to recurring for new mtg
	// for update agenda, only copy if checkbox is checked
	if (midS==null || request.getParameter("UpdateRecur") != null)
		mtg.updateRecurring(me, "AgendaItem");		// copy agenda to all recurring events

	// @ECC100605: create followup meeting
	String lastmidS = request.getParameter("Lastmid");
	if (lastmidS!=null && lastmidS.length()>0)
	{
		PstAbstractObject last = mMgr.get(me, lastmidS);
		s = (String)last.getAttribute("Recurring")[0];
		String lastLink = "";
		if (s != null)
		{
			sa = s.split(meeting.DELIMITER);
			s = sa[0] + meeting.DELIMITER + sa[1] + meeting.DELIMITER + mtg.getObjectId();
			if (sa.length >= 3)
				lastLink = sa[2];
		}
		else
			s = "Occasional" + meeting.DELIMITER + recurNum + meeting.DELIMITER + mtg.getObjectId();
		last.setAttribute("Recurring", s);
		mMgr.commit(last);			// save the link to this new meeting

		if (recurring == null)
		{
			// connect the link by stuffing new meeting into the chain of events
			recurring = "Occasional" + meeting.DELIMITER + 0;
			if (lastLink.length() > 0) recurring += meeting.DELIMITER + lastLink;
			mtg.setAttribute("Recurring", recurring);
		}
	}
	
	// @AGQ081506
	String type = request.getParameter("Type");
	String templateName = request.getParameter("TemplateName");	
	if (type != null) {
		StringBuffer sb = new StringBuffer();
		if (type.length() > 0) {
			sb.append(type);
			sb.append(meeting.DELIMITER);
		}
		if (templateName!=null && templateName.length() > 0) {
			sb.append(templateName);
		}
		mtg.setAttribute(meeting.CATEGORY, sb.toString());
	}
	
	// Store guest's emails so user can update and resent emails later
	Object obj = session.getAttribute("guestEmails");
	Object [] guestEmails = null;
	if (obj == null) {
		guestEmails = Util.expandGuestEmails(request.getParameter("guestEmails"));
		if (guestEmails == null)
			guestEmails = mtg.getAttribute(meeting.GUESTEMAILS);
		mtg.setAttribute("GuestEmails", guestEmails);
	}
	else {
		guestEmails = (Object [])obj;
		mtg.setAttribute("GuestEmails", guestEmails);
		session.removeAttribute("guestEmails");
	}
	mMgr.commit(mtg);		// commit new meeting
	
	// @AGQ091906
	if (guestEmails != null && guestEmails.length > 0) {
		//Integer []	userIdArrT;	// Holds user Ids
		ArrayList	guestToUserId	= new ArrayList(); // Converted user Ids from emails
		ArrayList	emailArr 	= new ArrayList(); // GuestEmails
		int noOfConversion = 0; // Number of guestEmails converted to Users Ids
		Object [] objArrGE = mtg.getAttribute(meeting.GUESTEMAILS);
		// @AGQ cannot reuse same object array because of meeting commit
		Object [] objArrAtt = mtg.getAttribute(meeting.ATTENDEE); 	
		
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
							e.printStackTrace();
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
						mtg.removeAttributeIgnoreCase(meeting.GUESTEMAILS, email);
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
							mtg.appendAttribute(meeting.ATTENDEE, curIArr[j]+meeting.DELIMITER+meeting.ATT_OPTIONAL);				
					}
				}
				else {
					emailArr.add(email);
				}
			}
		}
		// @AGQ090606
		mMgr.commit(mtg);
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
	}

	// send alert message
	if (bSendAlert)
		Util2.sendInvitation(me, mtg, optMsg);
	
	UtilThread uThread = new UtilThread(UtilThread.APPEND_CONTACTS, me, mtg);
	uThread.start();
	
	String now = request.getParameter("StartNow"); // @SWS091206
	if (now!=null && now.equals("true"))
	{
		// ECC: trigger event for live meeting is done in mtg_live.jsp
		// @AGQ091206 Wait for the thread to complete or else starting meeting 
		// may overwrite users information 
		uThread.join(); 
		response.sendRedirect("mtg_live.jsp?mid=" + mtg.getObjectId() + "&run=true"); // @SWS082206
	}
	else
	{
		// @ECC101807 event triggers
		if (midS == null) midS = String.valueOf(mtg.getObjectId());
		String circleIdS = (String)mtg.getAttribute("TownID")[0];
		if (bNewMeeting)
			PrmEvent.createTriggerEvent(me, PrmEvent.EVT_MTG_NEW, midS, circleIdS, null);
		else
			PrmEvent.createTriggerEvent(me, PrmEvent.EVT_MTG_UPDATE, midS, circleIdS, null);
		
		// Google calendar
		// TODO: in the future we should support update/delete Google calendar meeting
		if (bNewMeeting && me.getStringAttribute("GoogleID")!=null) {
			try {
				PrmGoogle googleHandler = new PrmGoogle(me, true);		// handle for Google calendar
				googleHandler.addEvent(mtg, (TimeZone)session.getAttribute("javaTimeZone"));
			}
			catch (Exception e) {
				response.sendRedirect("../out.jsp?go=meeting/cal.jsp&msg=Meeting is created but failed to add Google Calendar event: " + e.getMessage());
				e.printStackTrace();
				return;
			}
		}
		
		response.sendRedirect("mtg_view.jsp?mid="+midS+"&refresh=1");
	}
%>
