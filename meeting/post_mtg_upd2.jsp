<%@ page contentType="text/html; charset=utf-8"%>

<%
//
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_mtg_upd2.java
//	Author: ECC
//	Date:		03/07/2005
//	Description:	Post file for (1) mtg_update2.jsp (update meeting record after finish)
//				and for (2) mtg_live.jsp (update meeting while it is live OR adjourn meeting)
//				and for (3) proj_action.jsp (from the project action/decision page)
//	Modification:
//		@043005ECC	Support Decision Records (in addition to action)
//		@050105ECC	Support adding Action/Decision from project (no link to meeting)
//		@051505ECC	Allow adding file attachment during and after meeting
//		@ECC080905	Allow the meeting coordinator to retrieve recorder role
//		@ECC082305	Support adding issues and link action/decision to issue/PR
//		@AGQ010506  Set LastUpdatedDate into meeting attribute
//		@AGQ020906	Modified the regular expression
//		@AGQ021606	Added update counters calls to attendees, attachments, meetings notes, and action/decision/issue
//					Removed @AGQ010506 since we are using counters instead.
//		@AGQ040406	Support of multi file upload
//		@AGQ041206	Remodified @AGQ020906
//		@ECC061206a	Add project association to meeting.
//		@ECC091506	Support authorization control for meeting attachments.
//		@ECC110206	Add Description attribute.
//		@ECC112806	Allow adding new attendee after the meeting.
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
<%@ page import = "org.apache.log4j.Logger" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");
	
	// update meeting object on status, note, action items
	Logger l = PrmLog.getLog();

	String repository = Util.getPropKey("pst", "FILE_UPLOAD_PATH");
	MultipartRequest mrequest = new MultipartRequest(request, repository, 104857600, "UTF-8");	// 100*1024*1024)

	String midS = mrequest.getParameter("mid");
	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}

	boolean isMeeting = true;
	if (midS == null)
		isMeeting = false;

	String cont = mrequest.getParameter("Continue");		// come from mtg_live.jsp = "runMeeting" or "retrieveRecorder"
	if (cont!=null && cont.equals("false"))
		cont = null;
	String status = mrequest.getParameter("status");
	String adjourn = mrequest.getParameter("adjourn");
	String noSave = mrequest.getParameter("NoSave");		// just change proj name, don't save action
	String pageLabel = mrequest.getParameter("PageLabel");
	if (pageLabel == null)
		pageLabel = "";
	else
		pageLabel = "#" + pageLabel;

	String type = mrequest.getParameter("Type");
	String priority = mrequest.getParameter("Priority");
	String subject = mrequest.getParameter("Description");	// this is action item subject
	String mtgSubject = mrequest.getParameter("Subject");	// this is meeting subject
	String followupMtgIdS = mrequest.getParameter("FollowupMtgId");
	
	if (noSave!=null && noSave.equals("true"))
	{
		// just change proj name, (only get here if !issue) remember the ai name and type
		if (subject!=null && subject.length()>0)
			session.setAttribute("action", subject);
		pageLabel = "&type=" + type + "&prio=" + priority + pageLabel;
	}
	else
		noSave = null;

	Date now = new Date();

	////////////////////////////////////////////////////
	// action/decision/issue item info: create new only
	String projIdS = mrequest.getParameter("projId");
	String bugIdS = mrequest.getParameter("BugId");
	String s;
	boolean isCreateNewAction = false;
	String [] respA = null;
	String expireDtS = "";

	if (subject!=null && subject.length()>0)
	{
		if (noSave == null)
		{
			String owner = mrequest.getParameter("Owner");
			if (type.equalsIgnoreCase("Issue"))
			{
				// issue
				bugManager bugMgr = bugManager.getInstance();
				bug bObj = (bug)bugMgr.create(pstuser);

				bObj.setAttribute("Synopsis", subject);
				bObj.setAttribute("Creator", owner);		// submitter
				bObj.setAttribute("State", bug.OPEN);
				bObj.setAttribute("Type", bug.CLASS_ISSUE);
				bObj.setAttribute("CreatedDate", now);
				bObj.setAttribute("Priority", priority);
				bObj.setAttribute("MeetingID", midS);
				bObj.setAttribute("ProjectID", projIdS);

				SimpleDateFormat df = new SimpleDateFormat ("MMMMMMMM dd, yyyy (EEE) hh:mm a");
				String myName = (String)pstuser.getAttribute("FirstName")[0];
				s = "<font color='#aa0000'><b>Issue Filed</b> by " + myName + " on " + df.format(now) + "</font>";
				bObj.setAttribute("Description", s.getBytes("UTF-8"));
// @AGQ021606
				PrmUpdateCounter.updateOrCreateCounterArray(midS, PrmUpdateCounter.ISINDEX);
				bugMgr.commit(bObj);
			}
			else
			{
				// action or decision
				action aiObj;
				actionManager aMgr = actionManager.getInstance();
				String aidS = mrequest.getParameter("aid");		// update existing action?
				if (aidS == null) {
					// create new
					isCreateNewAction = true;
					aiObj = (action)aMgr.create(pstuser);
					aiObj.setAttribute("Creator", String.valueOf(pstuser.getObjectId()));
				}
				else {
					// update
					aiObj = (action)aMgr.get(pstuser, aidS);
				}

				if (type.equals(action.TYPE_ACTION))
				{
					respA = mrequest.getParameterValues("Responsible");
					if (owner != null) {
						aiObj.setAttribute("Owner", owner);
						aiObj.setAttribute("Responsible", null);						
						if (respA != null) {						
							for (int i=0; i<respA.length; i++) {
								aiObj.appendAttribute("Responsible", respA[i]);
							}
						}
					}
					expireDtS = mrequest.getParameter("Expire");
					SimpleDateFormat df = new SimpleDateFormat ("MM/dd/yyyy");
					aiObj.setAttribute("ExpireDate", df.parse(expireDtS));
					if (owner != null)

					// ECC: update meeting counter to sync content across multiple users
					if (midS != null)
						PrmUpdateCounter.updateOrCreateCounterArray(midS, PrmUpdateCounter.AIINDEX);
				}
				// Decision
				else {
					// ECC: update meeting counter to sync content across multiple users
					if (midS != null)
						PrmUpdateCounter.updateOrCreateCounterArray(midS, PrmUpdateCounter.DCINDEX);
				}

				aiObj.setAttribute("Type", type);
				aiObj.setAttribute("Company", (String)pstuser.getAttribute("Company")[0]);
				aiObj.setAttribute("MeetingID", midS);
				aiObj.setAttribute("ProjectID", projIdS);
				aiObj.setAttribute("BugID", bugIdS);
				aiObj.setAttribute("Subject", subject);
				aiObj.setAttribute("CreatedDate", now);
				aiObj.setAttribute("Priority", priority);

				// check to see if I am changing status
				String oldSt = aiObj.getStatus();
				if (oldSt == null)
					s = action.OPEN;
				else
					s = mrequest.getParameter("Status");
				if (oldSt==null || (s!=null && !s.equals(oldSt))) {
					aiObj.setStatus(pstuser, s);	// may initialize/commit/abort step
					// commit in setStatus()
				}
				else {
					aMgr.commit(aiObj);		// whenever commit will check for associated steps
				}

				// check if adding comment (blog) to action
				String text = mrequest.getParameter("Comment");
				if (text != null) {
					text = text.trim();
					if (text.length() > 0) {
						resultManager rMgr = resultManager.getInstance();
						PstAbstractObject blogObj = rMgr.create(pstuser);

						blogObj.setAttribute("CreatedDate", new Date());
						blogObj.setAttribute("Creator", String.valueOf(pstuser.getObjectId()));
						blogObj.setAttribute("Type", result.TYPE_ACTN_BLOG);
						blogObj.setAttribute("TaskID", String.valueOf(aiObj.getObjectId()));
						blogObj.setAttribute("Comment", text.getBytes("UTF-8"));
						rMgr.commit(blogObj);
					}
				}

				// workflow create step is done in actionManager.create() called above
			}

			if (!isMeeting)
			{
				// coming from project action or worktray: I am all done
				if (projIdS == null) projIdS = "";
				s = mrequest.getParameter("Caller");
				if (s!=null && s.contains("worktray")) {
					response.sendRedirect("../box/worktray.jsp?projId="+projIdS);
				}
				else {
					response.sendRedirect("../project/proj_action.jsp?projId="+projIdS);
				}
				return;
			}
		}
	}
	if (projIdS == null) projIdS = "";
	///////////////////////////////////////////////////////
	// Start saving meeting minutes, recorder, attendees

	userManager uMgr		= userManager.getInstance();
	meetingManager mMgr		= meetingManager.getInstance();
	meeting mtg = (meeting)mMgr.get(pstuser, midS);
	String currentStatus = (String)mtg.getAttribute("Status")[0];

	boolean meetingRunner = false;
	boolean retrieveRecorder = false;
	boolean isAdjourn = false;
	String runStr = null;

	if (cont!=null)
	{
		// I am in a LIVE meeting: 2 cases - running meeting & retrieve recorder
		if (cont.equals("runMeeting"))
		{
			// check to see if I am the current recorder
			s = (String)mtg.getAttribute("Recorder")[0];
			if (s!=null && Integer.parseInt(s)!=pstuser.getObjectId())
			{
				// assume my recorder responsibility just get revoked
				response.sendRedirect("../out.jsp?msg=Your recorder responsibility has been revoked.  You do not have authority to update the meeting.<br>If you think this is a mistake, ask the meeting coordinator to assign the recorder role back to you.&go=meeting/mtg_live.jsp?mid="+midS);
				return;
			}
			else
				meetingRunner = true;
		}
		else if (cont.equals("retrieveRecorder"))
		{
			// @ECC080905 mtg coordinator forcefully retrieve recorder responsibility back to himself
			retrieveRecorder = true;
		}
	}

	// @ECC112806
	String newAttendee = mrequest.getParameter("newAttendee");
	if (!StringUtil.isNullOrEmptyString(newAttendee))
	{
		newAttendee += meeting.DELIMITER + meeting.ATT_OPTIONAL + meeting.ATT_PRESENT;
		mtg.appendAttribute("Attendee", newAttendee);
	}

	if (meetingRunner || retrieveRecorder)
	{
		runStr = "&run=true";	// in both cases, the caller will continue as meeting runner

		// check for adding new attendees

		if (newAttendee!=null && newAttendee.length()>0)
		{
// @AGQ021606
			PrmUpdateCounter.updateOrCreateCounterArray(midS, PrmUpdateCounter.ADINDEX);
			mMgr.commit(mtg);
			response.sendRedirect("mtg_live.jsp?mid="+midS+runStr);
			return;		// in the case of adding attendees, only do this job and ignore other changes
		}

		// check if this is adjourn meeting
		if (adjourn!=null && adjourn.length()>0)
		{
			// don't worry about recurring because we already created all of them at create time
			mtg.setAttribute("Status", meeting.FINISH);
			long lo = now.getTime();	// - userinfo.getServerUTCdiff();
			mtg.setAttribute("CompleteDate", new Date(lo));
			isAdjourn = true;
// @AGQ021606
			PrmUpdateCounter.removeCounterArray(midS);
		}
		else
		{
			// check for change recorder
			String changeRecorder = mrequest.getParameter("recorder");
			if (changeRecorder!=null && !changeRecorder.equals(mtg.getAttribute("Recorder")[0]))
			{
				mtg.setAttribute("Recorder", changeRecorder);
				mtg.appendAttribute("Responsible", changeRecorder);		// @062807
				runStr = "";
				// continue to below to save all meeting info
			}
		}
	}

	// for canceled meeting (but the meeting could have been run outside of PRM), allow update
	if (currentStatus.equals(meeting.EXPIRE))
	{
		meetingRunner = true;
		isAdjourn = true;		// treat it like I am adjourning the meeting
		mtg.setAttribute("Status", meeting.FINISH);
		mtg.setAttribute("Recorder", String.valueOf(pstuser.getObjectId()));
	}

	if (!meetingRunner && !retrieveRecorder && !currentStatus.equals(meeting.FINISH))
	{
		response.sendRedirect("../out.jsp?msg=You cannot update the meeting record when the meeting is at the <b>" + status + "</b> state.");
		return;
	}

	// @ECC062807
	// meeting responsible personnel: those who are auth to update meeting
	Object [] objArr = mrequest.getParameterValues("ResponsibleR");
	mtg.setAttribute("Responsible", objArr);


	String note = mrequest.getParameter("mtgText");
// @AGQ041206
	if (note != null) // "(<p>[(&nbsp;) ]*</p>)|[<br /></p>]*$"
	{
		note = note.replaceAll(PrmMtgConstants.REGEX, " ").trim();		// wipe out some empty blank lines
		//note = note.replaceAll("(<span[^>]*></span>)|(<font[^>]*></font>)", "").trim();
		//note = note.replaceAll("(<(p|P)[^>]*>((&nbsp;)|( ))*</(p|P)>)", "<br>");
		note = note.replaceAll("<p>&nbsp;</p>", "");
	}
	else
		note = "";
// @AGQ021606
	s = mrequest.getParameter("SaveAttendee");
	boolean saveAttendee = (s == null)?true:(new Boolean(s)).booleanValue();
	if (!retrieveRecorder && saveAttendee/*true meetingRunner*/)	// used to allow only meetingRunner to update attendee list, now OK even when updating record after the meeting
	{
		// update the attendee present list.  Need to consider some others may have
		// join the meeting and set the PRESENT bit on.
		// Only take the present list and update the value if currently they are NOT present
		boolean found;
		int uId;
		Object [] attendeeArr = mtg.getAttribute("Attendee");
		String [] sa;
		String logonS = meeting.ATT_LOGON + meeting.ATT_PRESENT;
		for (Enumeration e = mrequest.getParameterNames() ; e.hasMoreElements() ;)
		{
			String temp = (String)e.nextElement();
			if (!temp.startsWith("present_")) continue;

			s = mrequest.getParameter(temp);
			if (s == null) continue;
			uId = Integer.parseInt(temp.substring(8));

			found = false;
			for (int i=0; i<attendeeArr.length; i++)
			{
				s = (String)attendeeArr[i];
				if (s == null) break;
				sa = s.split(meeting.DELIMITER);
				int aId = Integer.parseInt(sa[0]);

				if (aId == uId)
				{
					// check to see if his current value is LogonPresent, if so, ignored
					found = true;
					if (sa[1].endsWith(meeting.ATT_PRESENT))
						break;
					mtg.removeAttribute("Attendee", s);		// remove old value
					s += meeting.ATT_PRESENT;
					mtg.appendAttribute("Attendee", s);		// update attendee to present
					break;
				}
			}
			if (!found)
			{
				s = uId + meeting.DELIMITER + meeting.ATT_OPTIONAL
						+ meeting.ATT_PRESENT;
				mtg.appendAttribute("Attendee", s);		// newly appeared attendee
			}
		}

		// now go through the loop to see if recorder has unchecked some wrongly checked user
		// cannot uncheck those that are present by logon
		for (int i=0; i<attendeeArr.length; i++)
		{
			s = (String)attendeeArr[i];
			if (s == null) break;
			sa = s.split(meeting.DELIMITER);
			if (!sa[1].endsWith(meeting.ATT_PRESENT) || sa[1].endsWith(logonS))
				continue;
			int aId = 0;
			try {aId = Integer.parseInt(sa[0]);}
			catch (Exception e) {continue;}

			found = false;
			for (Enumeration e = mrequest.getParameterNames() ; e.hasMoreElements() ;)
			{
				String temp = (String)e.nextElement();
				if (!temp.startsWith("present_")) continue;

				String s1 = mrequest.getParameter(temp);
				if (s1 == null) continue;
				uId = Integer.parseInt(temp.substring(8));
				if (uId == aId)
				{
					found = true;
					break;
				}
			}
			if (!found)
			{
				// recorder uncheck this non-Logon presenter
				mtg.removeAttribute("Attendee", s);
				s = s.substring(0, s.length()-meeting.ATT_PRESENT.length());
				mtg.appendAttribute("Attendee", s);
			}
		}
// @AGQ021606
		PrmUpdateCounter.updateOrCreateCounterArray(midS, PrmUpdateCounter.ADINDEX);
	}
	
	// guests
	mtg.setAttribute("GuestEmails", null);		// clear to begin with
	s = mrequest.getParameter("Guest");
	if (s != null) {	
		String [] sa = s.split("(,|;)");
		PstAbstractObject u=null;
		for (int i=0; i<sa.length; i++) {
			s = sa[i].trim();
			if (s.contains("@")) {
				// it is Email
				int [] ids = uMgr.findId(pstuser, "Email='" + s + "'");
				if (ids.length > 0) {
					u = uMgr.get(pstuser, ids[0]);
				}
				else {
					// can't find this user, save it as guest email
					mtg.appendAttribute("GuestEmails", s);
				}
			}
			else {
				// username
				try {u = uMgr.get(pstuser, s);}
				catch (PmpException e) {System.out.println("Cannot find guest " + s); continue;}
			}
			if (u != null) {
				// found: put guest as an optional attendee
				s = String.valueOf(u.getObjectId()) + meeting.DELIMITER + meeting.ATT_OPTIONAL + meeting.ATT_PRESENT;
				mtg.appendAttribute("Attendee", s);
			}
		}
	}

// @AGQ040406
	Enumeration enumeration = mrequest.getFileNames();
	while (enumeration.hasMoreElements()) {
		Object name = enumeration.nextElement();
		// file attachment upload
		File AttachmentFileObj = mrequest.getFile(name.toString());
		if(AttachmentFileObj != null)
		{
			FileTransfer ft = new FileTransfer(pstuser);
			try
			{
				// don't use versioning
				attachment att = ft.saveFile(mtg.getObjectId(), projIdS, AttachmentFileObj,
						null, attachment.TYPE_MEETING, null, null, false);
				mtg.appendAttribute("AttachmentID", String.valueOf(att.getObjectId()));

				// @AGQ021606
				PrmUpdateCounter.updateOrCreateCounterArray(midS, PrmUpdateCounter.ATINDEX);
			}
			catch(Exception e)
			{
				e.printStackTrace();
				String msg = e.getMessage();
				if (msg == null) msg = "";
				response.sendRedirect("../out.jsp?e=Failed to upload file for meeting [" + midS + "]. "+msg);
				return;
			}
		}
	}

	// update the meeting object
	if (!meetingRunner && !retrieveRecorder)
	{
		// updating meeting record
		mtg.setAttribute("Status", status);
		if (status.equals(meeting.COMMIT)) cont = null;		// just closed the meeting
	}
	if (!retrieveRecorder)
	{
		if (note.length() > 0)
			mtg.setAttribute("Note", note.getBytes("UTF-8"));
		else {
			//System.out.println("*MEETING NOTES NULL, post_mtg_upd2.jsp NOTE='"+note+"'");
			//System.out.println("*TIME: "+(new Date()).toString());
			mtg.setAttribute("Note", null);
		}
// @AGQ021606
		PrmUpdateCounter.updateOrCreateCounterArray(midS, PrmUpdateCounter.MNINDEX);
	}

	// @ECC061206a: update meeting record after meeting: might change project association
	String assocProjIdS = mrequest.getParameter("ProjectId");
	if (assocProjIdS!=null && assocProjIdS.length()<=0) assocProjIdS = null;

	// @AGQ070606 Reset all attachment ProjectIDs
	Object obj = mtg.getAttribute("ProjectID")[0];
	String curProjIdS = (obj!=null)?obj.toString():null;
	if ((curProjIdS != null && assocProjIdS != null && !curProjIdS.equals(assocProjIdS)) ||
			(curProjIdS == null && assocProjIdS != null) || (curProjIdS != null && assocProjIdS == null)) {
		attachmentManager attMgr = attachmentManager.getInstance();
		objArr = mtg.getAttribute("AttachmentID");
		attachment att = null;
		for (int i=0; i<objArr.length; i++) {
			if (objArr[0] == null)
				break;
			att = (attachment)attMgr.get(pstuser, objArr[i].toString());
			att.setAttribute("ProjectID",assocProjIdS);
			attMgr.commit(att);
		}
	}

	mtg.setAttribute("ProjectID", assocProjIdS);

// @AGQ081606
	String meetingType = mrequest.getParameter("meetingType");
	if (meetingType != null)
		mtg.setAttribute(meeting.TYPE, meetingType);

	String townIdS = mrequest.getParameter("company");
	if (townIdS != null)
	{
		if (townIdS.equals("0")) townIdS = null;
		mtg.setAttribute("TownID", townIdS);
	}

	if (mtgSubject != null)
		mtg.setAttribute("Subject", mtgSubject);
	
	String oldFollowup = mtg.getStringAttribute("Recurring");
	if (StringUtil.isNullOrEmptyString(followupMtgIdS)) {
		if (oldFollowup!=null && oldFollowup.contains(meeting.OCCASIONAL)) {
			mtg.setAttribute("Recurring", null);		// remove the single follow-up meeting
		}
	}
	else {
		// might be new followup meeting specified
		// check
		if (oldFollowup!=null && !oldFollowup.contains(followupMtgIdS)) {
			// check for validity first
			try {
				mMgr.get(pstuser, followupMtgIdS);
				s = meeting.OCCASIONAL + meeting.DELIMITER + "0" + meeting.DELIMITER + followupMtgIdS;
				mtg.setAttribute("Recurring", s);	// Occasional::0::12345
			}
			catch (PmpException e) {}	// entered followup meeting ID is invalid, ignore entry
		}
	}

	// @ECC110206
	if (runStr==null && !isAdjourn)
	{
		String descStr = mrequest.getParameter("MtgDesc");
		if (descStr!=null && descStr.equals("null")) descStr = null;
		if (descStr == null)
			mtg.setAttribute("Description", null);
		else
		{
			descStr = descStr.replaceAll("\n", "<br>");
			descStr = descStr.replaceAll("  ", " &nbsp;");
			mtg.setAttribute("Description", descStr.getBytes("UTF-8"));
		}
	}

	// @ECC091506 after setting meeting type, I need to set the authorization for all this meeting's attachment
	mtg.setAttachmentAuthority(pstuser);

	// for reliability safty net, try and catch to commit a few times if necessary before failing
	int ct = 1;
	while (true)
	{
		try {mMgr.commit(mtg); break;}
		catch (PmpException e)
		{
			l.error("Failed to commit meeting [" + midS + "] (" + ct++ + ")");
			e.printStackTrace();
		}
		if (ct > 3)
		{
			s = "Internal error found in saving meeting [" + midS + "].<br>"
					+ "You might want to go back to the meeting and try to save again.  If problem persist, please contact PRM Administrator.";
			response.sendRedirect("../out.jsp?e=" + s);
			return;
		}
	}

	// keep statistics
	if (isAdjourn)
	{
		mod.mfchat.MeetingParticipants.removeHashMap(midS);
		try {Util.meetingStat(pstuser, mtg);
			Util.sendMailAsyn(pstuser, (String)pstuser.getAttribute("Email")[0],
				Util.getPropKey("pst", "FROM"), null, null, "[" + Prm.getAppTitle() + "] Close meeting " + midS,
				note, "alert.htm");
		}
		catch (PmpException e) {}	// admin will get an exception because of its diff userinfo record

	}

	String loc = null;
	if ( (meetingRunner || retrieveRecorder) && !isAdjourn)
		loc = "mtg_live.jsp?mid=" + midS + "&projId=" + projIdS + runStr + pageLabel;
	else if (cont!=null && !isAdjourn)
		loc = "mtg_update2.jsp?mid=" + midS + "&projId=" + projIdS + pageLabel;
	else
	{
		if (!isAdjourn)
			PrmEvent.createTriggerEvent(pstuser, PrmEvent.EVT_MTG_UPDATE, midS, (String)mtg.getAttribute("TownID")[0], null);
		else
			PrmEvent.createTriggerEvent(pstuser, PrmEvent.EVT_MTG_DONE, midS, (String)mtg.getAttribute("TownID")[0], null);
		loc = "mtg_view.jsp?mid=" + midS + "&refresh=1";	// adjourn
	}

%>
<script language="JavaScript">
<!--
	window.location='<%=loc%>';
//-->
</script>
