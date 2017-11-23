//
//	Copyright (c) 2006 EGI Technologies.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
// $Header$
//
//	File:	$RCSfile$
//	Author:	Allen G Quan (AGQ)
//	Date:	$Date$
//  Description:
//      Servlet to create Ajax response for meeting
//
//	Modification:
//		@AGQ090606	Removed Proj ID and Bug ID from listings of Action/Decision
//		@ECC101106	Input queue.
//
// 		@AGQ101106	Force user to reload mtg notes
/////////////////////////////////////////////////////////////////////

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.Enumeration;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import mod.mfchat.MeetingParticipants;
import mod.mfchat.PrmMeeting;
import oct.codegen.action;
import oct.codegen.actionManager;
import oct.codegen.attachment;
import oct.codegen.attachmentManager;
import oct.codegen.bug;
import oct.codegen.bugManager;
import oct.codegen.meeting;
import oct.codegen.meetingManager;
import oct.codegen.resultManager;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.pmp.exception.PmpException;
import oct.pmp.exception.PmpInternalException;
import oct.pmp.exception.PmpInvalidAttributeException;
import oct.pmp.exception.PmpManagerCreationException;
import oct.pmp.exception.PmpObjectException;
import oct.pmp.exception.PmpRawGetException;
import oct.pst.PstAbstractObject;
import oct.pst.PstGuest;
import oct.pst.PstUserAbstractObject;
import util.PrmMtgConstants;
import util.PrmUpdateCounter;
import util.StringUtil;
import util.Util;
import util.Util2;

public class PrmLiveMtg extends HttpServlet implements PrmMtgConstants{

	private static meetingManager	mMgr = null;
	private static actionManager	aMgr = null;
	private static bugManager		bMgr = null;
	private static userManager		uMgr = null;
	private static resultManager	rMgr = null;
	
	static {
		try {
			mMgr = meetingManager.getInstance();
			aMgr = actionManager.getInstance();
			bMgr = bugManager.getInstance();
			uMgr = userManager.getInstance();
			rMgr = resultManager.getInstance();
		}
		catch (PmpException e) {
			e.printStackTrace();
		}
	}
	
	/**
	 * Looks for midS and current user session to lookup meeting notes, action table, decision
	 * issue, attachment and return in Xml format. Used to create mtg_live have a live effect
	 * without reloading the whole page.
	 * @param mid (URL) Meeting ID
	 * @param date (URL Optional) Retreives LastUpdatedDate in long format
	 */
	public void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
		try {
			String bText = null;
			String adObjString = null;
			String aiObjString = null;
			String dsObjString = null;
			String bgObjString = null;
			String atObjString = null;
			String inputQueS   = null;

			int recorderId = 0; // Current recorder's id
			int[] ckbCounter = new int[1]; // Used to give checkboxes a unique id; I need to pass by reference
			ckbCounter[0] = 0; // Counter starts
			boolean isRun = false; // Only attendees will access doGet
			Date d = new Date();
			PstUserAbstractObject pstuser = null;
			HttpSession httpSession = request.getSession(false);
			String midS = request.getParameter(MID);

			String debugString = request.getParameter(DEBUG);
			boolean debug = (debugString == null)?false:(new Boolean(debugString)).booleanValue();

			// Check valid user
			if (httpSession != null)
				pstuser = (PstUserAbstractObject)httpSession.getAttribute(PSTUSER);
			if (pstuser == null || midS == null) {
				// Session Timeout (and users clicks Live) or Invalid Meeting ID
				createXmlMessage(USERTIMEOUT, response);
				return;
			}
			// get user id
			int myUid = pstuser.getObjectId();
			
			if (pstuser instanceof PstGuest)
				myUid = 0;				// so that my name (guest) won't show on the attendee list
			
			// to check if session is OMF or PRM
			boolean isOMFAPP = false;
			String app = (String)httpSession.getAttribute("app");
			if (app.equals("OMF"))
				isOMFAPP = true;
			
			// get meeting object
			meeting mtg = (meeting)mMgr.get(pstuser, midS);
			// get recorder id
			String s = (String)mtg.getAttribute("Recorder")[0]; // active recorder
			if (s != null)
				recorderId = Integer.parseInt(s);
			// Current attendee was chosen to become recorder, reload page
			String status = (String)mtg.getAttribute("Status")[0];
			if (status != null && !status.equals(meeting.LIVE)) {
				createXmlRedirect(null, "mtg_view.jsp?mid=" + midS, response);
				return;
			}
			// @AGQ082506 Participant feedback is in session - no facilitators
			if (recorderId==myUid && !debug && !MeetingParticipants.isOn(midS)) {
				createXmlRedirect(NEWRECORDER + d, "mtg_live.jsp?mid="+midS+"&run=true", response);
				return;
			}

			int[] localCounters = PrmUpdateCounter.getMtgCounters(midS);
			int[] userCounters = PrmUpdateCounter.getUserCounters(request);
			int flag = PrmUpdateCounter.checkUpdateCounters(midS, userCounters, localCounters);
			
			// @AGQ101106 Force user to reload mtg notes
			String forceS = request.getParameter("force"); // Forces user to get the full notes
			if((flag & MNBIT) != MNBIT && forceS != null) {
				flag = flag | MNBIT;
			}
			
			if(flag == 0) {
				createXmlUserCounters(localCounters, response);
				return;
			}

			// Creates different html strings to report
			String onlineString = null;
			ArrayList[] psNadLists = fetchPresentAttendeeList(mtg, myUid, mMgr);
			Util.sortExUserList(pstuser, psNadLists[2]); // exchange the list of ids with list of users and sort
			StringBuffer onlineStrBuf = new StringBuffer();
			if ((flag & ADBIT) == ADBIT) {
				adObjString = createADTable(pstuser, psNadLists, isRun, midS, onlineStrBuf); // Attendees Checkbox List
				onlineString = onlineStrBuf.toString();
			}
			if ((flag & ATBIT) == ATBIT) {
				atObjString = createATTable(pstuser, mtg.getAttribute(ATTACHMENTID), midS, isRun); //Attachment
			}
			if((flag & MNBIT) == MNBIT) {
				// @ECC100606 check for chat index (supply during an open input session)
				String chatIdxS = request.getParameter(CHATIDX);
				if (chatIdxS != null)
				{
					int idx = Integer.parseInt(chatIdxS) - 1;
					bText = MeetingParticipants.getUnreadChat(midS, idx, true);	// will cleanup
				}
				else
				{
					// get the blog text - meeting notes
					bText = getMeetingNotes(mtg);
				}

			}
			if ((flag & (AIBIT | DCBIT)) != 0) {
				if ((flag & AIBIT) == AIBIT) {
					PstAbstractObject[] aiObjList = fetchActnDecnArray(pstuser, midS, action.TYPE_ACTION, aMgr);
					aiObjString = createAITable(aiObjList, pstuser, isRun, midS, ckbCounter); // Action Item
				}
				if ((flag & DCBIT) == DCBIT) {
					PstAbstractObject[] dsObjList = fetchActnDecnArray(pstuser, midS, action.TYPE_DECISION, aMgr);
					dsObjString = createDSTable(dsObjList, pstuser, isRun, ckbCounter, isOMFAPP); // Decisions
				}
			}
			if ((flag & ISBIT) == ISBIT) {
				PstAbstractObject[] bgObjList = fetchIssuesArray(pstuser, midS);
				bgObjString = createISTable(bgObjList, pstuser, isRun, ckbCounter); // Issue
			}
			if ((flag & INBIT) == INBIT) {
				inputQueS = MeetingParticipants.getAllOnQueue(midS);
			}

			// Create response XML
			if (debug)
				createXml(null, aiObjString, dsObjString, bgObjString, bText, d.toString(), atObjString, null, adObjString, onlineString, psNadLists[2], recorderId, inputQueS, localCounters, flag, response);
			else
				createXml(null, aiObjString, dsObjString, bgObjString, bText, null, atObjString, null, adObjString, onlineString, psNadLists[2], recorderId, inputQueS, localCounters, flag, response);

		} catch (PmpException e) {
			String url = "../out.jsp?e=The meeting has been removed from the database.";
			createXmlRedirect(null, url, response);
		} catch (Exception e)	{
			e.printStackTrace();
		}
	}

	/**
	 * Updates meeting notes live. It finds the current meeting id and retrieves the lastest meeting notes
	 * and updates the database with the information. If meeting notes are the same, no updates are performed.
	 * It returns an Xml document with the time the meeting notes were saved.
	 * @param mid (URL) meeting id
	 * @param bText (URL POST) the lastest meeting notes
	 * @return XML &lt;time&gt; Last updated time
	 */
	public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
//		request.setCharacterEncoding("utf-8");
//		response.setCharacterEncoding("utf-8");

		try {
			boolean isCommit = false; // required commit
			boolean isNewAD = false;
			boolean isRun = true; // Only Recorder can access doPost
			int myUid = 0;
			int recorderId = 0;
			Date d = new Date();

			PstUserAbstractObject pstuser = null;
			HttpSession httpSession = request.getSession(false);
			String midS = request.getParameter(MID);
			String bText = request.getParameter(BTEXT);
System.out.println("PrmLiveMtg.doPost(): " + bText);

			String debugString = request.getParameter(DEBUG);
			String saveString = request.getParameter(SAVE);
			boolean isDebug = (debugString == null)?false:(new Boolean(debugString)).booleanValue();
			boolean isSaveButton = (saveString == null)?false:(new Boolean(saveString)).booleanValue();

			// the session might be timed out
			if (httpSession != null)
				pstuser = (PstUserAbstractObject)httpSession.getAttribute(PSTUSER);
			if (pstuser == null || midS == null) {
				// Only happens if Server is reloaded
				createXmlMessage(USERTIMEOUT, response);
				return;
			}
			
			// get meeting object
			meeting mtg = (meeting)mMgr.get(pstuser, midS);
			// get user id
			myUid = pstuser.getObjectId();


			// get Meeting Notes from recorder
			// ECC: this might be the cause of the bug for losing all notes
			if (bText != null) {
				String temp;
				temp = bText.replaceAll(REGEX, EMPTYSTRING).trim();		// wipe out some empty blank lines
				if (temp.length() > 0)
					bText = temp;			// OK: not an empty string
			}
			else
				bText = EMPTYSTRING;

			
			recorderId = getRecorderId(mtg);
			// Recorder status is revoked; do not save anything at all
			if (recorderId!=myUid && !isDebug) {
				createXmlRedirect(REVOKEDRECORDER + d, "mtg_live.jsp?mid="+midS, response);
				return;
			}

			isCommit = saveAttendeeList(request, mtg);
			if(isCommit) {
				PrmUpdateCounter.updateOrCreateCounterArray(midS, ADINDEX);
			}

			// check for adding new attendees and commits to changes
			String newAttendee = request.getParameter(NEWATTENDEE);
			if (newAttendee!=null && newAttendee.length()>0) {
				addNewAttendee(mMgr, mtg, newAttendee);
				isNewAD = true;
			}

			// get new attendee checkboxes (need to be done here to return new attendee list after adding new attendees)
			String onlineString = null;
			ArrayList[] psNadLists = fetchPresentAttendeeList(mtg, myUid, mMgr);
			StringBuffer onlineStrBuf = new StringBuffer();
			String adObjString = createADTable(pstuser, psNadLists, isRun, midS, onlineStrBuf);
			Util.sortExUserList(pstuser, psNadLists[2]); // exchange the list of ids with list of users and sort
			onlineString = onlineStrBuf.toString();
			
			// @ECC101106 input queue
			String inputQueS = MeetingParticipants.getAllOnQueue(midS);

			// Added new attendee; do nothing else
			if (isNewAD) {
				PrmUpdateCounter.updateOrCreateCounterArray(midS, ADINDEX);
				createXml(null, null, null, null, null, null, null, null, adObjString, onlineString, psNadLists[2], recorderId, inputQueS, null, -1, response);
				return;
			}

			// @AGQ100206 Check to see if chat session is on; if it is, do not save meeting notes.
			boolean isMFChatOn = MeetingParticipants.isOn(midS);
			
			//////////////////////////////////////
			// Update Meeting Notes
			
			// look at draft to decide if I need to save a draft (Draft is for backup)
			Object bTextObj = mtg.getAttribute(NOTE)[0];
			String oldText = (bTextObj==null)?EMPTYSTRING:new String((byte[])bTextObj, "utf-8");
			int oldLength = oldText.length();

			if ((bText.length() != oldLength || isSaveButton) && !isMFChatOn) {
				// Notes became null
				if (bText.length() == 0) {
					//System.out.println("*MEETING NOTES NULL, PrmLiveMtg.java BTEXT='"+bText+"'");
					//System.out.println("*TIME: "+(new Date()).toString()); 
					mtg.setAttribute(NOTE, null);
				}
				else {
					mtg.setAttribute(NOTE, bText.getBytes("utf-8"));
					
					// save current note to draft
					bTextObj = mtg.getAttribute(DRAFT)[0];
					String draftText = (bTextObj==null)?EMPTYSTRING:new String((byte[])bTextObj, "utf-8");
					int draftLength = draftText.length();
					
					if (oldLength>draftLength && oldLength>20) {
						// save oldText to draftText for backup
						draftText = oldText;
						mtg.setAttribute(DRAFT, draftText.getBytes("utf-8"));
					}

				}
				if (!isCommit)
					isCommit = true;
				PrmUpdateCounter.updateOrCreateCounterArray(midS, MNINDEX);
			}
			
			// Commit changes
			if (isCommit) {

				// for reliability safty net, try and catch to commit a few times if necessary before failing
				int ct = 1;
				while (true)
				{	try {mMgr.commit(mtg); break;}
					catch (Exception e)
					{	createXmlMessage(SAVEFAILED + d.toString(), response);
						e.printStackTrace();
					}
					if (ct++ > 3)
					{	createXmlMessage(SAVEFAILED + d.toString(), response);
						System.out.println("Internal error found in saving meeting");
						return;
					}
				}

				// User clicked Save
				if (isSaveButton) {
					createXmlMessage(SAVED + d.toString(), adObjString, onlineString, psNadLists[2], recorderId, inputQueS, response);
				}
				// Auto Save
				else {
					if (isDebug)
						createXmlMessage(d.toString(), adObjString, onlineString, psNadLists[2], recorderId, inputQueS, response);
					else
						createXmlMessage(null, adObjString, onlineString, null, -1, inputQueS, response);
				}
			}
			// No Updates
			else
				createXmlMessage(null, adObjString, onlineString, null, -1, inputQueS, response);
		} catch (Exception e)	{
			e.printStackTrace();
		}
	}

	/**
	 * Constructs a Xml response with meeting notes, action, decision, issue table, and time refreshed.
	 * <pre>
	 * &lt;response&gt;
	 * 	&lt;meetingNotes&gt;
	 * 		Meeting Notes
	 *	&lt;/meetingNotes&gt;
	 * &lt;/response&gt;
	 * </pre>
	 * @param aiObjString Action Item Table
	 * @param dsObjString Decision Table
	 * @param bgObjString Issue Table
	 * @param mtgSvrLastUpdate Server time in long format
	 * @param bText Meeting Notes
	 * @param lastUpdate Date in String format
	 * @param response
	 * @throws IOException
	 */
	public static void createXml(String alertMessage, String aiObjString, String dsObjString, String bgObjString, String bText, String lastUpdate, String atObjString, String url, String adObjString, String onlineString, ArrayList presentList, int recorderId, String inputQString, int[] counters, int flag, HttpServletResponse response) throws IOException {
		response.setContentType(XML_CONTENT);
		response.setHeader(XML_CACHECONTROL, XML_NOCACHE);
		response.getWriter().write(XML_RESPONSE_OP);
		createXmlChild(MEETINGNOTES, bText, response);
		createXmlChild(TIME, lastUpdate, response);
		createXmlChild(COUNTS, counters, flag, response);
		createXmlChild(AIOBJTABLE, aiObjString, response);
		createXmlChild(DSOBJTABLE, dsObjString, response);
		createXmlChild(BGOBJTABLE, bgObjString, response);
		createXmlChild(ATOBJTABLE, atObjString, response);
		createXmlChild(ADOBJTABLE, adObjString, response);
		createXmlChild(ONLINESTR, onlineString, response);
		createXmlChild(IQSTRING, inputQString, response);
		createXmlChild(ALERTMESSAGE, alertMessage, response);
		createXmlChild(URL, url, response);
		createRCNames(presentList, recorderId, response);
		response.getWriter().write(XML_RESPONSE_CL);
	}

//***********************************************
//* DB Calls
//***********************************************

	public static int getRecorderId(meeting mtg) throws PmpObjectException, PmpManagerCreationException, PmpInvalidAttributeException, PmpRawGetException, PmpInternalException, PmpException {
		String activeRecorder = (String)mtg.getAttribute(RECORDER)[0]; // active recorder
		if (activeRecorder != null)
			return Integer.parseInt(activeRecorder);
		else
			return 0;
	}

	/**
	 * Fetches Meeting Notes from DB. If Meeting Notes are empty, replace
	 * the meeting notes with Meeting Agenda.
	 * @param mtg
	 * @return Meeting Notes or if null, Meeting Agenda.
	 * @throws PmpException
	 */
	private String getMeetingNotes(meeting mtg) throws PmpException {
		Object bTextObj = mtg.getAttribute(NOTE)[0];
		String bText = EMPTYSTRING;
		try {bText = (bTextObj==null)?EMPTYSTRING:new String((byte[])bTextObj, "utf-8");}
		catch (UnsupportedEncodingException e) {}
		// Meeting Notes from DB is empty
		if (bText.length() == 0 ) {
			// put the agenda into the minute
			bText = mtg.getAgendaString().replaceAll("@@", ":");	// the agenda may have this encoded
			// Meeting Notes and Agenda are both null, return an empty String
			if(bText.length() == 0)
				bText = "<p></p>";
		}
		return bText;
	}

	/**
	 * Fetches action or decision items for current meeting from db.
	 * @param pstuser User
	 * @param midS Meeting ID
	 * @param type action.TYPE_ACTION or action.TYPE_DECISION
	 * @param aMgr null or an instance
	 * @return PstAbstractObject[] aiObjArray/dsObjArray
	 * @throws PmpException
	 */
	public static PstAbstractObject[] fetchActnDecnArray(PstUserAbstractObject pstuser, String midS, String type, actionManager aMgr) throws PmpException {
		int [] ids;
		// get the list of items
		ids = aMgr.findId(pstuser, "(MeetingID='" + midS + "') && (Type='" + type + "')");
		Arrays.sort(ids);
		return aMgr.get(pstuser, ids);
	}

	/**
	 * Fetches issue items for current meeting from db.
	 * @param pstuser User
	 * @param midS Meeting ID
	 * @return PstAbstractObject[] bgObjArray
	 * @throws PmpException
	 */
	public static PstAbstractObject[] fetchIssuesArray(PstUserAbstractObject pstuser, String midS) throws PmpException {
		int [] ids;
		ids = bMgr.findId(pstuser, "MeetingID='" + midS + "'");
		Arrays.sort(ids);
		return bMgr.get(pstuser, ids);
	}
	/**
	 * Fetches the presentList and AttendeeList from the db.
	 * @param mtg
	 * @param myUid
	 * @param mMgr
	 */
	public static ArrayList[] fetchPresentAttendeeList(meeting mtg, int myUid, meetingManager mMgr) throws PmpException {
		String s;
		// get attendee list
		Object [] attendeeArr = mtg.getAttribute(ATTENDEE);
		String [] sa;
		ArrayList attendeeList = new ArrayList();	// those who hasn't signed in yet
		ArrayList presentList = new ArrayList();	// those who has signed in
		ArrayList signedInList = new ArrayList();	// those who only signed in
		ArrayList[] psNadLists = new ArrayList[3];
		boolean found = false;
		for (int i=0; i<attendeeArr.length; i++)
		{
			s = (String)attendeeArr[i];
			if (s == null) break;
			sa = s.split(meeting.DELIMITER);
			if (StringUtil.isNullOrEmptyString(sa[0]))
				continue;
			int aId = Integer.parseInt(sa[0]);
			// This section may not be needed BEGIN
			if (aId == myUid)
			{
				if (!sa[1].endsWith(meeting.ATT_PRESENT))
				{
					// I just logon
					mtg.removeAttribute(ATTENDEE, s);
					s += meeting.ATT_LOGON + meeting.ATT_PRESENT;
					mtg.appendAttribute(ATTENDEE, s);
					mMgr.commit(mtg);
				}

				presentList.add(sa[0]);		// I just signed in
				signedInList.add(sa[0]);
				found = true;
				continue;
			}
			// This section may not be needed END
			if (sa[1].endsWith(meeting.ATT_LOGON + meeting.ATT_PRESENT))
				signedInList.add(sa[0]);
			if (sa[1].endsWith(meeting.ATT_PRESENT))
				presentList.add(sa[0]);
			else
				attendeeList.add(sa[0]);
		}
		if (!found) {
			presentList.add(String.valueOf(myUid));
			signedInList.add(String.valueOf(myUid));
		}
		psNadLists[0] = presentList;
		psNadLists[1] = attendeeList;
		psNadLists[2] = signedInList;
		return psNadLists;
	}

	/**
	 * Goes through the current list of parameters and check to see if any parameters
	 * begin with "present_". Those like will be saved as users that are present in
	 * the meeting. This process will also check to see if any attendees are accidently
	 * unchecked even though they have logged into the meeting.
	 * @param request
	 * @param mtg
	 * @return true if changes were made to db; false if no changes were made.
	 * @throws PmpException
	 */
	public static boolean saveAttendeeList(HttpServletRequest request, meeting mtg) throws PmpException {
		// Save present and unpresent attendee that the recorder has checked
		boolean found;
		boolean isCommit = false; // true when there were changes
		int uId;
		Object [] attendeeArr = mtg.getAttribute(ATTENDEE);
		String [] sa;
		String s;
		String logonS = meeting.ATT_LOGON + meeting.ATT_PRESENT;
		for (Enumeration e = request.getParameterNames() ; e.hasMoreElements() ;)
		{
			String temp = (String)e.nextElement();
			if (!temp.startsWith(TEMPPRESENT)) continue;

			s = request.getParameter(temp);
			if (s == null) continue;
			uId = Integer.parseInt(temp.substring(8));

			found = false;
			for (int i=0; i<attendeeArr.length; i++)
			{
				s = (String)attendeeArr[i];
				if (s == null) break;
				sa = s.split(meeting.DELIMITER);
				if (StringUtil.isNullOrEmptyString(sa[0]))
					continue;
				int aId = Integer.parseInt(sa[0]);

				if (aId == uId)
				{
					// check to see if his current value is LogonPresent, if so, ignored
					found = true;
					if (sa[1].endsWith(meeting.ATT_PRESENT))
						break;
					mtg.removeAttribute(ATTENDEE, s);		// remove old value
					s += meeting.ATT_PRESENT;
					mtg.appendAttribute(ATTENDEE, s);		// update attendee to present
					if (!isCommit)
						isCommit = true;
					break;
				}
			}
			if (!found)
			{
				s = uId + meeting.DELIMITER + meeting.ATT_OPTIONAL
						+ meeting.ATT_PRESENT;
				mtg.appendAttribute(ATTENDEE, s);		// newly appeared attendee
				if (!isCommit)
					isCommit = true;
			}
		}

		// now go through the loop to see if recorder has unchecked some wrongly checked user
		// cannot uncheck those that are present by logon
		for (int i=0; i<attendeeArr.length; i++)
		{
			s = (String)attendeeArr[i];
			if (s == null) break;
			sa = s.split(meeting.DELIMITER);
			if (StringUtil.isNullOrEmptyString(sa[0]) || !sa[1].endsWith(meeting.ATT_PRESENT) || sa[1].endsWith(logonS))
				continue;
			int aId = Integer.parseInt(sa[0]);

			found = false;
			for (Enumeration e = request.getParameterNames() ; e.hasMoreElements() ;)
			{
				String temp = (String)e.nextElement();
				if (!temp.startsWith(TEMPPRESENT)) continue;

				String s1 = request.getParameter(temp);
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
				mtg.removeAttribute(ATTENDEE, s);
				s = s.substring(0, s.length()-meeting.ATT_PRESENT.length());
				mtg.appendAttribute(ATTENDEE, s);
				if (!isCommit)
					isCommit = true;
			}
		}

		return isCommit;
	}

	/**
	 * Checks to see if there are new attendees to be added. If there are, adds the new
	 * attendee and then commits. After a new attendee is added, nothing else will be
	 * done.
	 * @param mMgr
	 * @param mtg
	 * @param newAttendee
	 * @return
	 * @throws PmpException
	 */
	private void addNewAttendee(meetingManager mMgr, meeting mtg, String newAttendee) throws PmpException {
		String s = newAttendee
			+ meeting.DELIMITER + meeting.ATT_OPTIONAL
			+ meeting.ATT_PRESENT;
		mtg.appendAttribute(ATTENDEE, s);
		mMgr.commit(mtg);
	}
//***********************************************
//* Helper functions
//***********************************************

	/**
	 * Writes multiple child nodes with text limiting to VAR_LENGTH (4095) chars per node. When returned to
	 * browser javascript, each node can be contained in a var or an array of var. There is a
	 * limit in 4096 chars stored in a var in js for firefox.
	 * @param child the name of the child nodes
	 * @param text the text to store inside the child nodes
	 * @throws IOException
	 */
	public static void createXmlChild(String child, String text, HttpServletResponse response) throws IOException {
		if (text != null) {
			int textLength = text.length() - 1; // Convert to index position
			int curIndex = 0;
			int endIndex = 0;
			// includes chars from index 0+
			while(curIndex <= textLength) {
				endIndex = curIndex + VAR_LENGTH;
				response.getWriter().write("\t<" + child + ">");
				if (endIndex <= textLength)
					response.getWriter().write(Util.stringToHTMLString(text.substring(curIndex, endIndex), false));
				else
					response.getWriter().write(Util.stringToHTMLString(text.substring(curIndex), false));
				response.getWriter().write("</" + child + ">\n");
				curIndex = endIndex;
			}
		}
	}

	/**
	 * Creates the variables for counters. The variables will show up as 6 individual xml tags
	 * and when the user receives it, it should be in order.
	 * @param child
	 * @param counters
	 * @param response
	 * @throws IOException
	 */
	public static void createXmlChild(String child, int[] counters, int flag, HttpServletResponse response) throws IOException {
		if(counters != null) {
			for(int i = 0; i < ARRAYSIZE; i++) {
				response.getWriter().write("\t<" + child + ">");
				response.getWriter().write(counters[i]+"");
				response.getWriter().write("</" + child + ">\n");
			}
		}
		response.getWriter().write("\t<" + child + ">");
		response.getWriter().write(flag+"");
		response.getWriter().write("</" + child + ">\n");
	}

	/**
	 * Create an empty Xml response
	 * @param response
	 * @throws IOException
	 */
	private void createXml(HttpServletResponse response) throws IOException {
		createXml(null, null, null, null, null, null, null, null, null, null, null, -1, null, null, -1,response);
	}

	/**
	 * Creates a response with the current counters back to the user.
	 * @param localCounter
	 * @param response
	 * @throws IOException
	 */
	private void createXmlUserCounters(int[] localCounter, HttpServletResponse response) throws IOException {
		createXml(null, null, null, null, null, null, null, null, null, null, null, -1, null, localCounter, 0, response);
	}

	/**
	 * Create an Xml with a message. This lets the recorder see the status of their
	 * or the system's actions.
	 * @param lastUpdate The time the meeting was last updated in Date.toString() format
	 * @param response
	 * @throws IOException
	 */
	private void createXmlMessage(String lastUpdate, HttpServletResponse response) throws IOException {
		createXml(null, null, null, null, null, lastUpdate, null, null, null, null, null, -1, null, null, -1, response);
	}

	private void createXmlMessage(String lastUpdate, String adObjString, String onlineString, ArrayList signedInList, int recorderId, String inputQString, HttpServletResponse response) throws IOException {
		createXml(null, null, null, null, null, lastUpdate, null, null, adObjString, onlineString, signedInList, recorderId, inputQString, null, -1, response);
	}

	/**
	 * Create an Xml with a &lt;url&gt; tag and a redirect url.
	 * @param url a complete url with http://
	 * @param response
	 * @throws IOException
	 */
	public static void createXmlRedirect(String alertMessage, String url, HttpServletResponse response) throws IOException {
		createXml(alertMessage, null, null, null, null, null, null, url, null, null, null, -1, null, null, -1, response);
	}



//***************************************************
//* Action, Decision, Issue Table Creators and Name List Creators
//***************************************************

	/**
	 * Create recorder names list into XML
	 * @param attendeeList
	 * @param response
	 * @throws IOException
	 */
	private static void createRCNames(ArrayList attendeeList, int recorderId, HttpServletResponse response) throws IOException {
		user u;
		int id;
		String firstName, lastName, uName;
		int counter = 0;
		try {
			if (attendeeList != null && attendeeList.size() > 0) {
				for (int i=0; i<attendeeList.size(); i++)
				{
					u = (user)attendeeList.get(i);
					id = u.getObjectId();
					firstName = (String)u.getAttribute(FIRSTNAME)[0];
					lastName = (String)u.getAttribute(LASTNAME)[0];
					uName = firstName + (lastName==null?EMPTYSTRING:(" "+lastName));
					if (id == recorderId)
						response.getWriter().write(XML_RCSELECTED_OP+counter+XML_RCSELECTED_CL);
					response.getWriter().write(XML_RCNAMETEXT_OP+Util.stringToHTMLString(uName, false)+XML_RCNAMETEXT_CL);
					response.getWriter().write(XML_RCNAMEVALUE_OP+id+XML_RCNAMEVALUE_CL);
					counter++;
				}
			}
		} catch (PmpException e) {
			// do nothing
			e.printStackTrace();
		}
	}

	/**
	 * Creates the table that displays the current user that are attending this meeting.
	 * @param pstuser
	 * @param psNadLists
	 * @return
	 * @throws PmpException
	 */
	public static String createADTable(PstUserAbstractObject pstuser, ArrayList[] psNadLists, boolean isRun, String midS, StringBuffer onlineStrBuf) throws PmpException {
		final int RADIO_NUM		= 4;
		boolean curOnline;
		int counterAD = 0;
		int id, num = 0, idx;
		String uname;
		String idS;
		user u;
		String UserEdit = ADDISABLE;
		
		if (isRun)
			UserEdit = EMPTYSTRING;
		StringBuffer out = new StringBuffer();
		ArrayList presentList = psNadLists[0];
		ArrayList attendeeList = psNadLists[1];

		Util.sortExUserList(pstuser, presentList);	// exchange the list of ids with list of users and sort
		out.append(OPENTABLE);
		for(int i=0; i<presentList.size(); i++)
		{
			u = (user)presentList.get(i);
			id = u.getObjectId();
			idS = String.valueOf(id);
			curOnline = MeetingParticipants.isOnline(midS, idS);
			uname = u.getObjectName();
			if (uname.equalsIgnoreCase("admin")) continue;	// don't show admin
			if ((idx = uname.indexOf("@")) != -1) uname = uname.substring(0, idx);
			
			if (num%RADIO_NUM == 0) out.append(OPENROW);
			out.append(ADTABLE01 + counterAD + ADTABLE02 + id + ADTABLE03 + UserEdit);
			out.append(ADTABLECK); // checked
			out.append(ADTABLE04 + id + ADTABLE05 + uname + ADTABLE06);
			
			if (curOnline)
			{
				if (MeetingParticipants.isParticipant(midS, idS))
					uname = "*" + uname;	// he is in the chat session now
				onlineStrBuf.append(uname + ":");
				//out.print("&nbsp;<img title='online' style='vertical-align: top;' src='../i/icon_on.gif'>");
			}
			
			out.append(ADTABLE07);
			
			if (num%RADIO_NUM == RADIO_NUM-1) out.append(CLOSEROW);
			num++;
			counterAD++;
		}
		Util.sortExUserList(pstuser, attendeeList);	// exchange the list of ids with list of users and sort
		for(int i=0; i<attendeeList.size(); i++)
		{
			u = (user)attendeeList.get(i);
			id = u.getObjectId();
			idS = String.valueOf(id);
			curOnline = MeetingParticipants.isOnline(midS, idS);
			uname = u.getObjectName();
			if ((idx = uname.indexOf("@")) != -1) uname = uname.substring(0, idx);

			if (num%RADIO_NUM == 0) out.append(OPENROW);
			out.append(ADTABLE01 + counterAD + ADTABLE02 + id + ADTABLE03 + UserEdit);
			out.append(ADTABLE04 + id + ADTABLE05 + uname + ADTABLE06);
			
			if (curOnline)
				out.append("&nbsp;<img title='online' style='vertical-align: top;' src='../i/icon_on.gif'>");
			
			out.append(ADTABLE07);
			
			if (num%RADIO_NUM == RADIO_NUM-1) out.append(CLOSEROW);
			num++;
			counterAD++;
		}
		if (num%RADIO_NUM != 0) out.append(CLOSEROW);
		out.append(CLOSETABLE);
		return out.toString();
	}

	/**
	 * Creates a table which contains the current attachments belonging to this meeting
	 * @param attmtList Array of attachment received from DB
	 * @param midS Meeting ID
	 */
	public static String createATTable(PstUserAbstractObject pstuser, Object[] attmtList, String midS, boolean isRun) throws PmpException{
		attachmentManager attMgr = attachmentManager.getInstance();
		attachment attmtObj = null;
		String fileName, user;
		Date attmtCreateDt;
		SimpleDateFormat df3 = new SimpleDateFormat ("MM/dd/yyyy");
		StringBuffer out = new StringBuffer();
		
		int [] aids = Util2.toIntArray(attmtList);
		int [] linkIds = attMgr.findId(pstuser, "Link='" + midS + "'");		// @ECC103008
		aids = Util2.mergeIntArray(aids, linkIds);

			// @AGQ070606 Translate all attachment id to attachment objects and fixed display
		out.append(OPENTABLE);

		if (aids.length <= 0)
		{
			out.append(ATTABLE01);
		}
		else
		{
			// ECC: need fix for SE - attmtList is now a list of ID's, we need to change
			// that into a list of filenames
			out.append("<tr>");
			out.append("<td width='4' bgcolor='#6699cc' class='10ptype'>&nbsp;</td>");
			out.append("<td width='250' bgcolor='#6699cc' class='td_header'><strong>&nbsp;File Name</strong></td>");
			out.append("<td width='2' bgcolor='#FFFFFF' class='10ptype'><img src='../i/spacer.gif' width='2' height='2'></td>");
			out.append("<td width='4' bgcolor='#6699cc' class='10ptype'>&nbsp;</td>");
			out.append("<td width='80' bgcolor='#6699cc' class='td_header'><strong>Owner</strong></td>");
			out.append("<td width='2' bgcolor='#FFFFFF' class='10ptype'><img src='../i/spacer.gif' width='2' height='2'></td>");
			out.append("<td width='4' bgcolor='#6699cc' class='10ptype'>&nbsp;</td>");
			out.append("<td width='120' bgcolor='#6699cc' class='td_header' align='left'><strong>Posted On</strong></td>");
			out.append("<td width='4' bgcolor='#6699cc' class='10ptype'>&nbsp;</td>");
			out.append("</tr>");
			
			Arrays.sort(aids);
			for (int i=0; i<aids.length; i++)
			{
				// BROKEN! list files by alphabetical order
				attmtObj = (attachment)attMgr.get(pstuser, aids[i]);
				user = attmtObj.getOwnerDisplayName(pstuser);
				attmtCreateDt = (Date)attmtObj.getAttribute("CreatedDate")[0];
				fileName = attmtObj.getFileName();
				
				out.append("<td>&nbsp;</td>");
				out.append("<td class='plaintext' width='320'>");
				out.append("<a class='listlink' href='"+HOSTS+"/servlet/ShowFile?attId="+aids[i]+"'>"+fileName+"</a>");
				out.append("</td>");
				out.append("<td colspan='2'>&nbsp;</td>");
				out.append("<td class='formtext'><a href='../ep/ep1.jsp?uid="+(String)attmtObj.getAttribute("Owner")[0]+"' class='listlink'>"+user+"</a></td>");
				out.append("<td colspan='2'>&nbsp;</td>");
				out.append("<td class='formtext'>"+df3.format(attmtCreateDt)+"</td>");

				if (isRun) {
					out.append("<td><input class='formtext' type='button' value='Delete'");
					out.append(" onclick='javascript: ajaxDeleteAT("+aids[i]+");' align='right'>");
					out.append("</td>");
				}
				out.append(ATTABLE14);
			}
		}
		out.append(ATTABLE15);
		return out.toString();
	}

	/**
	 * Creates Action Item table by looking through the database. Taken from mtg_live.jsp.
	 * @param aiObjArray
	 * @param pstuser
	 * @return
	 * @throws PmpObjectException
	 * @throws PmpInvalidAttributeException
	 * @throws PmpRawGetException
	 * @throws PmpException
	 */
	public static String createAITable(
			PstAbstractObject[] aiObjArray, 
			PstUserAbstractObject pstuser, 
			boolean isRun,
			String midS,
			int[] ckbCounter
			) 
	throws PmpException
	{
		return PrmMeeting.displayActionItems(aiObjArray, pstuser, isRun, midS, ckbCounter);
	}
	
	public static String createDSTable(PstAbstractObject[] dsObjArray, 
			PstUserAbstractObject pstuser, 
			boolean isRun, 
			int[] ckbCounter) 
	throws PmpException {
		return createDSTable(dsObjArray, pstuser, isRun, ckbCounter, false);
	}

	/**
	 * Creates decision table taken from mtg_live.jsp
	 * @param dsObjArray
	 * @param pstuser
	 * @return
	 * @throws PmpObjectException
	 * @throws PmpManagerCreationException
	 * @throws PmpInvalidAttributeException
	 * @throws PmpRawGetException
	 * @throws PmpInternalException
	 * @throws PmpException
	 */
	public static String createDSTable(PstAbstractObject[] dsObjArray, 
			PstUserAbstractObject pstuser, 
			boolean isRun, 
			int[] ckbCounter,
			boolean isOMFAPP) 
	throws PmpException {
		int aid;
		String bugIdS, bgcolor, dot, priority, projIdS, subject;
		Date createdDate;
		action obj;

		boolean even = false;
		StringBuffer out = new StringBuffer();
		SimpleDateFormat df1 = new SimpleDateFormat ("MM/dd/yy");

		if (isOMFAPP) // @AGQ090606
			out.append(Util.showLabel(label1OMF, labelLen1OMF, isRun));
		else
			out.append(Util.showLabel(label1, labelLen1, isRun));

		int [] ids;
		for (int i = 0; i < dsObjArray.length; i++)
		{	// the list of decision records for this meeting object
			obj = (action)dsObjArray[i];
			aid = obj.getObjectId();

			subject		= (String)obj.getAttribute("Subject")[0];
			priority	= (String)obj.getAttribute("Priority")[0];
			createdDate	= (Date)obj.getAttribute("CreatedDate")[0];
			projIdS		= (String)obj.getAttribute("ProjectID")[0];
			bugIdS		= (String)obj.getAttribute("BugID")[0];

			if (even)
				bgcolor = "bgcolor='#EEEEEE'";
			else
				bgcolor = "bgcolor='#ffffff'";
			even = !even;
			out.append("<tr " + bgcolor + ">");

			// Subject
			out.append("<td>&nbsp;</td>");
			out.append("<td valign='top'><table border='0'><tr>");
			out.append("<td class='plaintext' valign='top'>" + (i+1) + ". </td>");
			out.append("<td class='plaintext' valign='top'>");
			if (isRun)
				out.append("<a href='javascript:editAC(\""
					+ aid + "\", \"Decision\")'>" + subject + "</a>");
			else
				out.append(subject);
			out.append("</td></tr></table></td>\n");

			// Priority {HIGH, MEDIUM, LOW}
			dot = "../i/";
			if (priority.equals(action.PRI_HIGH)) {dot += "dot_red.gif";}
			else if (priority.equals(action.PRI_MED)) {dot += "dot_orange.gif";}
			else if (priority.equals(action.PRI_LOW)) {dot += "dot_yellow.gif";}
			else {dot += "dot_grey.gif";}
			out.append("<td colspan='3' class='listlink' align='center' valign='top'>");
			out.append("<img src='" + dot + "' alt='" + priority + "'>");
			out.append("</td>\n");

			// @ECC041006 support blogging in action/decision/issue
			ids = rMgr.findId(pstuser, "TaskID='" + aid + "'");
			out.append("<td colspan='2'>&nbsp;</td>");
			out.append("<td class='listtext' width='30' valign='top' align='center'>");
			out.append("<a class='listlink' href='../blog/blog_task.jsp?projId=" + projIdS + "&aid=" + aid + "'>");
			out.append(ids.length + "</a>");
			out.append("</td>\n");

			if (!isOMFAPP) { // @AGQ090606
				// Project id
				out.append("<td colspan='2'>&nbsp;</td>");
				out.append("<td class='listtext' width='40' valign='top' align='center'>");
				if (projIdS != null)
				{
					out.append("<a class='listlink' href='../project/proj_action.jsp?projId=" + projIdS + "&aid=" + aid + "'>");
					out.append(projIdS + "</a>");
				}
				else
					out.append("-");
				out.append("</td>\n");
	
				// Bug id
				out.append("<td colspan='2'>&nbsp;</td>");
				out.append("<td class='listtext' width='40' valign='top' align='center'>");
				if (bugIdS != null)
				{
					out.append("<a class='listlink' href='../bug/bug_update.jsp?bugId=" + bugIdS + "'>");
					out.append(bugIdS + "</a>");
				}
				else
					out.append("-");
				out.append("</td>\n");
			}

			// CreatedDate
			out.append("<td colspan='2'>&nbsp;</td>");
			out.append("<td class='listtext_small' width='50' align='center' valign='top'>");
			out.append(df1.format(createdDate));
			out.append("</td>\n");

			// delete
			if (isRun)
			{
				out.append("<td colspan='2'>&nbsp;</td>");
				out.append("<td width='35' class='plaintext' align='center'>");
				out.append("<input id='ckbox" + ckbCounter[0] + "' type='checkbox' name='delete_" + aid + "'></td>");
				ckbCounter[0]++;
			}

			out.append("</tr>\n");
			out.append("<tr " + bgcolor + ">" + "<td colspan='20'><img src='../i/spacer.gif' width='2' height='2'></td></tr>\n");
		}

		out.append(CLOSETABLE);
		return out.toString();
	}

	/**
	 * Creates the issues table.
	 * @param bgObjArray
	 * @param pstuser
	 * @return
	 * @throws PmpObjectException
	 * @throws PmpManagerCreationException
	 * @throws PmpInvalidAttributeException
	 * @throws PmpRawGetException
	 * @throws PmpInternalException
	 * @throws PmpException
	 */
	public static String createISTable(PstAbstractObject[] bgObjArray, PstUserAbstractObject pstuser, boolean isRun, int[] ckbCounter) throws PmpObjectException, PmpManagerCreationException, PmpInvalidAttributeException, PmpRawGetException, PmpInternalException, PmpException {
		int aid;
		String subject, priority, ownerIdS, projIdS, bgcolor, dot;
		Date createdDate;
		bug bObj;
		user uObj;

		boolean even = false;
		StringBuffer out = new StringBuffer();
		SimpleDateFormat df1 = new SimpleDateFormat ("MM/dd/yy");

		out.append(Util.showLabel(label2, labelLen2, isRun));

		int [] ids;
		for (int i = 0; i < bgObjArray.length; i++)
		{	// the list of issues for this meeting object
			bObj = (bug)bgObjArray[i];
			aid = bObj.getObjectId();

			subject		= (String)bObj.getAttribute("Synopsis")[0];
			priority	= (String)bObj.getAttribute("Priority")[0];
			createdDate	= (Date)bObj.getAttribute("CreatedDate")[0];
			projIdS		= (String)bObj.getAttribute("ProjectID")[0];
			ownerIdS	= (String)bObj.getAttribute("Creator")[0];

			if (even)
				bgcolor = "bgcolor='#EEEEEE'";
			else
				bgcolor = "bgcolor='#ffffff'";
			even = !even;
			out.append("<tr " + bgcolor + ">");

			// Subject
			out.append("<td>&nbsp;</td>");
			out.append("<td valign='top'><table border='0'><tr>");
			out.append("<td class='plaintext' valign='top'>" + (i+1) + ". </td>");
			out.append("<td class='plaintext' valign='top'>");
			if (isRun)
				out.append("<a href='javascript:editAC(\"" + aid + "\", \"Issue\")'>" + subject + "</a>");
			else
				out.append(subject);
			out.append("</td></tr></table></td>\n");

			// Submitter
			uObj = (user)uMgr.get(pstuser, Integer.parseInt(ownerIdS));
			out.append("<td colspan='2'>&nbsp;</td>");
			out.append("<td class='listtext' valign='top'>");
			out.append("<a class='listlink' href='../ep/ep1.jsp?uid=" + ownerIdS + "'>");
			out.append((String)uObj.getAttribute(FIRSTNAME)[0] + " " + ((String)uObj.getAttribute(LASTNAME)[0]).charAt(0) + ".");
			out.append("</a>");
			out.append("</td>");

			// Priority {HIGH, MEDIUM, LOW}
			dot = "../i/";
			if (priority.equals(bug.PRI_HIGH)) {dot += "dot_red.gif";}
			else if (priority.equals(bug.PRI_MED)) {dot += "dot_orange.gif";}
			else if (priority.equals(bug.PRI_LOW)) {dot += "dot_yellow.gif";}
			else {dot += "dot_grey.gif";}
			out.append("<td colspan='3' class='listlink' align='center' valign='top'>");
			out.append("<img src='" + dot + "' alt='" + priority + "'>");
			out.append("</td>\n");

			// @ECC041006 support blogging in action/decision/issue
			ids = rMgr.findId(pstuser, "TaskID='" + aid + "'");
			out.append("<td colspan='2'>&nbsp;</td>");
			out.append("<td class='listtext' width='30' valign='top' align='center'>");
			out.append("<a class='listlink' href='../blog/blog_task.jsp?projId=" + projIdS + "&bugId=" + aid + "'>");
			out.append(ids.length + "</a>");
			out.append("</td>\n");

			// Project id
			out.append("<td colspan='2'>&nbsp;</td>");
			out.append("<td class='listtext' width='40' valign='top' align='center'>");
			if (projIdS != null)
			{
				out.append("<a class='listlink' href='../project/proj_action.jsp?projId=" + projIdS + "&aid=" + aid + "'>");
				out.append(projIdS + "</a>");
			}
			else
				out.append("-");
			out.append("</td>\n");

			// My id
			out.append("<td colspan='2'>&nbsp;</td>");
			out.append("<td class='listtext' width='40' valign='top' align='center'>");
			out.append(aid + "</td>");

			// CreatedDate
			out.append("<td colspan='2'>&nbsp;</td>");
			out.append("<td class='listtext_small' width='50' align='center' valign='top'>");
			out.append(df1.format(createdDate));
			out.append("</td>\n");

			// delete
			if (isRun)
			{
				out.append("<td colspan='2'>&nbsp;</td>");
				out.append("<td width='35' class='plaintext' align='center'>");
				out.append("<input id='ckbox" + ckbCounter[0] + "' type='checkbox' name='delete_" + aid + "'></td>");
				ckbCounter[0]++;
			}

			out.append("</tr>\n");
			out.append("<tr " + bgcolor + ">" + "<td colspan='23'><img src='../i/spacer.gif' width='2' height='2'></td></tr>\n");
		}

		out.append(CLOSETABLE);
		return out.toString();
	}
}
