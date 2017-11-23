<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<%
//
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_mtg_upd1.jsp
//	Author: ECC
//	Date:		03/01/2005
//	Description:	Post file for mtg_update1.jsp (update meeting info before meeting starts)
//	Modification:
//
//		@AGQ030606	Goes through the list of attendees for DL and converts the DL to user Ids.
//		@AGQ030806	Support of GuestEmails
//		@AGQ040306	Support of multi upload files
//		@ECC061206a	Add project association to meeting.
//		@AGQ090606	Add user and guestEmail process
//		@ECC091506	Support authorization control for meeting attachments.
//		@ECC110206	Add Description attribute.
//		@ECC062807	Authorize multiple people to update meeting record.
//		@ECC100708	Clipboard actions.  Added link file option.
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "oct.util.file.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.PepCommentVector" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>
<%@ page import = "com.oreilly.servlet.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	PstUserAbstractObject me = pstuser;

	// update meeting object on basic information and attachments
	String repository = Util.getPropKey("pst", "FILE_UPLOAD_PATH");
	MultipartRequest mrequest = new MultipartRequest(request, repository, 100*1024*1024, "UTF-8");

	String appS = Prm.getAppTitle();

	String midS = mrequest.getParameter("mid");
	if ((me instanceof PstGuest) || (midS == null))
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	int myUid = me.getObjectId();
	String myName = ((user)me).getFullName();

	String from = (String)me.getAttribute("Email")[0];
	if (from == null)
		from = Util.getPropKey("pst", "FROM");

	meetingManager mMgr		= meetingManager.getInstance();
	userManager uMgr		= userManager.getInstance();
	attachmentManager attMgr = attachmentManager.getInstance();
	userinfoManager uiMgr	= userinfoManager.getInstance();
	
	userinfo myUI = (userinfo)uiMgr.get(pstuser, String.valueOf(myUid));

	meeting mtg = (meeting)mMgr.get(me, midS);

	// continue on the update?
	String cont = mrequest.getParameter("Continue");
	String projIdS = mrequest.getParameter("projId");		// @ECC061206a
	if (projIdS!=null && projIdS.length()<=0) projIdS = null;	// @ECC061206a
	
	// @AGQ070606 Reset all attachment ProjectIDs
	Object [] objArr;
	Object obj = mtg.getAttribute("ProjectID")[0];
	String curProjIdS = (obj!=null)?obj.toString():null;
	if ((curProjIdS != null && projIdS != null && !curProjIdS.equals(projIdS)) ||
			(curProjIdS == null && projIdS != null) || (curProjIdS != null && projIdS == null)) {
		objArr = mtg.getAttribute("AttachmentID");
		attachment att = null;
		for (int i=0; i<objArr.length; i++) {
			if (objArr[0] == null)
				break;
			att = (attachment)attMgr.get(me, objArr[i].toString());
			att.setAttribute("ProjectID",projIdS);
			attMgr.commit(att);
		}
	}
	
	// @ECC100708  Clipboard link file: do not allow uploading files that collide in link filenames
	String sessErrMsg = "";
	boolean bReject;
	PstAbstractObject [] linkDocArr = new PstAbstractObject[0];
	Enumeration enumeration = mrequest.getFileNames();
	if (enumeration.hasMoreElements())
	{
		// get all the documents linked to this meeting
		int [] ids = attMgr.findId(me, "Link='" + midS + "'");
		linkDocArr = attMgr.get(me, ids);
	}
	
	// @AGQ040306
	File AttachmentFileObj = null;
	while (enumeration.hasMoreElements()) {
		Object name = enumeration.nextElement();
		// file attachment upload		
		AttachmentFileObj = mrequest.getFile(name.toString());	
		if(AttachmentFileObj != null)
		{
			// error checking: if the filename match any linked file, reject the upload
			bReject = false;
			for (int i=0; i<linkDocArr.length; i++)
			{
				if (Util3.getOnlyFileName(linkDocArr[i]).equalsIgnoreCase(AttachmentFileObj.getName()))
				{
					bReject = true;
					if (sessErrMsg.length() <= 0)
						sessErrMsg = "The following file(s) are not uploaded:<br>";
					sessErrMsg += "- " + AttachmentFileObj.getName() + ": filename collides with a linked file.<br>";
					break;
				}
			}
			if (bReject) continue;

			FileTransfer ft = new FileTransfer(me);
			try
			{
				// don't use versioning
				attachment att = ft.saveFile(mtg.getObjectId(), projIdS, AttachmentFileObj,
						null, attachment.TYPE_MEETING, null, null, false);
				mtg.appendAttribute("AttachmentID", String.valueOf(att.getObjectId()));
			}
			catch(Exception e)
			{
				e.printStackTrace();
				String msg = e.getMessage();
				if (msg == null) msg = "";
				response.sendRedirect("../out.jsp?e=Failed to upload file for meeting [" + midS + "]. " + msg);
				return;
			}
		}
	}	// END while upload file loop
	if (sessErrMsg.length() > 0)
		session.setAttribute("errorMsg", sessErrMsg);
	
	// might just be uploading file
	String s = mrequest.getParameter("UploadOnly");
	if (s!=null && s.equals("true"))
	{
		if (AttachmentFileObj != null)
		{
			// @ECC091506 I need to set the authorization for all this meeting's attachment
			mtg.setAttachmentAuthority(me);
			mMgr.commit(mtg);
		}
		if (cont!=null && cont.equals("true"))
			response.sendRedirect("mtg_update1.jsp?mid="+midS);
		else
			response.sendRedirect("mtg_view.jsp?mid="+midS+"&refresh=1");
		return;
	}

	String subject = mrequest.getParameter("Subject");
	
	
	String location = null;
	String confRoom = mrequest.getParameter("confRoomSelect");
	if (confRoom.equals("other")){
	location = mrequest.getParameter("Location");
	} else {
		location = confRoom;
	}
	
	String owner = mrequest.getParameter("Owner");
	
	String startDT = mrequest.getParameter("StartDT");
	String endDT = mrequest.getParameter("ExpireDT");
	//long lStartDt = Long.parseLong(startDT) - myUI.getTimeZoneDiff()*3600000;	// back to PST time
	//long lEndDt = Long.parseLong(endDT) - myUI.getTimeZoneDiff()*3600000;	// back to PST time
	
	String descStr = mrequest.getParameter("Description");

	String recurring = mrequest.getParameter("Recurring");
	if (recurring != null)
	{
		s = mrequest.getParameter("RecurMultiple");
		int i;
		try {i = Integer.parseInt(s);}
		catch (Exception e){i = 1;}
		if (i <= 0) i = 1;
		recurring += meeting.DELIMITER + i;
	}

	//long diff = userinfo.getServerUTCdiff();
	long lo = Long.parseLong(startDT);	// - diff;
	Date startDate = new Date(lo);
	lo = Long.parseLong(endDT);	// - diff;
	Date expireDate = new Date(lo);
	//Date startDate = new Date(lStartDt);
	//Date expireDate = new Date(lEndDt);

	int uid = me.getObjectId();
	String uidS = String.valueOf(uid);

	// update the meeting object
	mtg.setAttribute("Owner", owner);
	mtg.setAttribute("Subject", subject);
	mtg.setAttribute("StartDate", startDate);
	mtg.setAttribute("ExpireDate", expireDate);
	mtg.setAttribute("Location", location);
	mtg.setAttribute("Status", meeting.NEW);
	mtg.setAttribute("ProjectID", projIdS);					// @ECC061206a
	// @ECC110206
	if (descStr!=null && (descStr.trim().length()<=0 || descStr.equals("null")) ) descStr = null;
	if (descStr != null)
	{
		// convert the plain text to HTML
		descStr = descStr.replaceAll("\n", "<br>");
		descStr = descStr.replaceAll("  ", " &nbsp;");
		mtg.setAttribute("Description", descStr.getBytes("UTF-8"));
	}
	else
		mtg.setAttribute("Description", null);
	//mtg.setAttribute("Recurring", recurring);

	// set attendee attributes (id::State)
	// first get current attendee list
	Object [] oldAttendeeArr = mtg.getAttribute("Attendee");
	int len = oldAttendeeArr.length;
	if (len >= meeting.MAX_ATT)
	{
		response.sendRedirect("../out.jsp?msg=You have exceeded the maximum number of attendees (" + meeting.MAX_ATT + ") to a meeting.");
		return;
	}

	String [] sa;
	int [] oldManArr = new int [meeting.MAX_ATT];
	int [] oldOptArr = new int [meeting.MAX_ATT];
	int idx;
	for (idx=0; idx<oldAttendeeArr.length; idx++)
	{
		s = (String)oldAttendeeArr[idx];
		if (s == null) break;
		sa = s.split(meeting.DELIMITER);
		if (sa[1].startsWith(meeting.ATT_MANDATORY))
		{
			oldManArr[idx] = Integer.parseInt(sa[0]);		// just need to compare the user id
			oldOptArr[idx] = 0;
		}
		else
		{
			oldOptArr[idx] = Integer.parseInt(sa[0]);		// just need to compare the user id
			oldManArr[idx] = 0;
		}
	}

	oldManArr[idx] = -1;		// end of list
	oldOptArr[idx] = -1;
	int oldManCt, oldOptCt;
	oldManCt = oldOptCt = idx;

	// by now oldOptArr and oldManArr contains the current attendees mandatory and optional respectively
	String [] mandatory = mrequest.getParameterValues("MandatoryAttendee");
	String [] optional = mrequest.getParameterValues("OptionalAttendee");
// @AGQ030606	
	dlManager dlMgr = dlManager.getInstance();
	mandatory = dlMgr.removeDuplicate(me, mandatory);
	optional = dlMgr.removeDuplicate(me, optional);
	optional = dlMgr.removeDuplicateFromOptIds(me, mandatory, optional);
	int id, oldId, j;
	boolean found;

	/////////////////////////////////////////////
	// ----- Start handling mandatory attendees
	if (mandatory != null)
	{
		idx = oldManCt;						// idx always points to -1 (i.e. the next space)
		for (int i=0; i<mandatory.length; i++)
		{
			found = false;
			id = Integer.parseInt(mandatory[i]);
			for (j=0; j<oldManCt; j++)
			{
				oldId = oldManArr[j];
				if (oldId == 0) continue;
				//if (oldId == -1) break;
				if (id == oldId)
				{
					found = true;
					break;
				}
			}
			if (!found)
			{
				oldManArr[idx++] = id;		// new attendee
				oldManArr[idx] = -1;
			}
		}
	}
	// now oldManArr contains both old and new attendees, we need to remove those old attendees
	// that are not on the new list
	for (int i=0; i<oldManCt; i++)
	{
		found = false;
		oldId = oldManArr[i];
		if (oldId == 0) continue;
		for (j=0; mandatory!=null && j<mandatory.length; j++)
		{
			if (oldId == Integer.parseInt(mandatory[j]))
			{
				found = true;
				break;
			}
		}
		if (!found)
		{
			// the user id in oldManArr[i] is not found in the new list, delete!
			mtg.removeAttribute("Attendee", oldAttendeeArr[i]);	// the index is aligned
		}
	}
	// now the old attendee list is cleaned up (for mandatory), I can add the new once
	for (int i=oldManCt; i<meeting.MAX_ATT; i++)
	{
		if (oldManArr[i] == -1) break;		// done
		s = oldManArr[i] + meeting.DELIMITER + meeting.ATT_MANDATORY;
		mtg.appendAttribute("Attendee", s);
	}
	// -- end handling mandatory attendees

	/////////////////////////////////////////////
	// ----- Start handling optional attendees
	if (optional != null)
	{
		idx = oldOptCt;						// idx always points to -1 (i.e. the next space)
		for (int i=0; i<optional.length; i++)
		{
			found = false;
			id = Integer.parseInt(optional[i]);
			for (j=0; j<oldOptCt; j++)
			{
				oldId = oldOptArr[j];
				if (oldId == 0) continue;
				//if (oldId == -1) break;
				if (id == oldId)
				{
					found = true;
					break;
				}
			}
			if (!found)
			{
				oldOptArr[idx++] = id;		// new attendee
				oldOptArr[idx] = -1;
			}
		}
	}
	// now oldOptArr contains both old and new attendees, we need to remove those old attendees
	// that are not on the new list
	for (int i=0; i<oldOptCt; i++)
	{
		found = false;
		oldId = oldOptArr[i];
		if (oldId == 0) continue;
		for (j=0; optional!=null && j<optional.length; j++)
		{
			if (oldId == Integer.parseInt(optional[j]))
			{
				found = true;
				break;
			}
		}
		if (!found)
		{
			// the user id in oldOptArr[i] is not found in the new list, delete!
			mtg.removeAttribute("Attendee", oldAttendeeArr[i]);	// the index is aligned
		}
	}
	// now the old attendee list is cleaned up (for optional), I can add the new once
	for (int i=oldOptCt; i<meeting.MAX_ATT; i++)
	{
		if (oldOptArr[i] == -1) break;		// done
		s = oldOptArr[i] + meeting.DELIMITER + meeting.ATT_OPTIONAL;
		mtg.appendAttribute("Attendee", s);
	}
	// -- end handling optional attendees
	
	// @ECC062807
	objArr = mrequest.getParameterValues("Responsible");
	mtg.setAttribute("Responsible", objArr);
	
// @AGQ081606
	String meetingType = mrequest.getParameter("meetingType");
	mtg.setAttribute(meeting.TYPE, meetingType);
	
	String townIdS = mrequest.getParameter("company");
	if (townIdS!=null && townIdS.equalsIgnoreCase("0")) townIdS = null;
	mtg.setAttribute("TownID", townIdS);

	// the current meeting must be new, feel free to carry forward the update
	if (mrequest.getParameter("UpdateRecur") != null)
	{
		mtg.updateRecurring(me, "Owner");
		mtg.updateRecurring(me, "Attendee");
		mtg.updateRecurring(me, "Location");
		mtg.updateRecurring(me, "ProjectID");		// @ECC061206a
		mtg.updateRecurring(me, "Type");
		mtg.updateRecurring(me, "TownID");
		// for date, recurring would not change the DATE but only the TIME
		mtg.updateRecurring(me, "StartDate");
		mtg.updateRecurring(me, "ExpireDate");
	}
	
	// Store Guest Emails
// @AGQ030806
	String emailStr = mrequest.getParameter("guestEmails");
	String [] guestEmails = Util.expandGuestEmails(emailStr);
	//if (guestEmails != null) 
	mtg.setAttribute("GuestEmails", guestEmails); // Guest list can be emptied by user.
	
	// @ECC091506 after setting meeting type, I need to set the authorization for all this meeting's attachment
	mtg.setAttachmentAuthority(me);
	
	mMgr.commit(mtg);
// @AGQ090606
	UtilThread uThread = new UtilThread(UtilThread.APPEND_CONTACTS, me, mtg);
	uThread.start();
	
	// set up email recipient address
	Object [] userIdArr = mtg.getAttribute("Attendee");
	for (int i=0; i<userIdArr.length; i++)
	{
		if (userIdArr[i] == null) break;
		s = (String)userIdArr[i];
		sa = s.split(meeting.DELIMITER);
		userIdArr[i] = sa[0];			// contain the user id (String) of the recipient
	}

	// send mail notification
	String sendMail = mrequest.getParameter("SendMail");
	if (sendMail!=null && sendMail.equals("true"))
	{
		// @ECC092005
		String agendaText = mtg.getAgendaString().replaceAll("@@", ":");	// the agenda may have this encoded
		if (agendaText.length() <= 0)
			agendaText = "<blockquote>No agenda specified</blockquote>";

		String MAILFILE = "alert.htm";
		String NODE = Util.getPropKey("pst", "PRM_HOST");
		String subj = "[" + appS + " Invite] "+ subject + " (update)";
		String userLink = NODE + "/meeting/mtg_view.jsp?mid=" + mtg.getObjectId(); // @SWS091906
		String guestLink = NODE + "/login_omf.jsp?mid=" + mtg.getObjectId()+ "&email=" ;
		SimpleDateFormat df = new SimpleDateFormat ("MMMMMMMM dd, yyyy (EEE) hh:mm a z");
		TimeZone myTimeZone = myUI.getTimeZone();
		if (!userinfo.isServerTimeZone(myTimeZone)) {
			df.setTimeZone(myTimeZone);
		}
		String msg = myName + " has updated the meeting on " + df.format(startDate);
		msg +="<br /><br />To join the meeting, click on the link below at the specified time."
			+  "<blockquote><b><a href='" + userLink
			+ "'>" + subject + "</a></b><br>"
			+ userLink + "\n</blockquote>";
		if (descStr != null)
			msg += "<b>Description:</b><blockquote>" + descStr + "</blockquote>";
		msg += "<b>Agenda:</b><p>" + agendaText;

		//Util.createAlert(me, subj, msg, 0, null, 0, 0, userIdArr);
		//Util.sendMailAsyn(me, from, userIdArr, null, null, subj, msg, MAILFILE, guestEmails);
		Util.sendMailAsyn(me, from, userIdArr, null, null, subj, msg, MAILFILE); // @SWS092006
		
		if (guestEmails != null && guestEmails.length > 0)
		{
			for (int i=0; i<guestEmails.length; i++)
			{
			msg = myName + " has updated the meeting on " + df.format(startDate);
			msg += "<br /><br />To join the meeting, click on the link below at the specified time."
				+ "<blockquote><b><a href='" + guestLink
				+ guestEmails[i] + "'>" + subject + "</a></b><br>"
				+ guestLink + guestEmails[i] + "\n</blockquote>";
			if (descStr != null)
				msg += "<b>Description:</b><blockquote>" + descStr + "</blockquote>";
			msg += "<b>Agenda:</b><p>" + agendaText;
			Util.sendMailAsyn(me, from, guestEmails[i].toString(), null, null, subj, msg, MAILFILE);
			}
		}
	}

	if (cont!=null && cont.equals("true"))
		response.sendRedirect("mtg_update1.jsp?mid="+midS);
	else
	{
		// tigger event
		PrmEvent.createTriggerEvent(me, PrmEvent.EVT_MTG_UPDATE, midS, (String)mtg.getAttribute("TownID")[0], null);
		response.sendRedirect("mtg_view.jsp?mid="+midS+"&refresh=1");
	}
%>
