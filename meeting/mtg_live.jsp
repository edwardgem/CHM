<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2005, EGI Technologies, Co.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: mtg_live.jsp
//	Author: ECC
//	Date:	02/24/05
//	Description: Start a meeting or join a meeting.  Use mtg.js for Ajax.
//				- When click Save, post_mtg_upd2.jsp will be called to update meeting contents such
//				  as note, recorder, attendees and file attachments.  At the same time, if there is
//				  content in NEW action/decision/issue box, post_mtg_upd2.jsp will save the item.
//				- When deleting the meeting's action/decision/issue, post_updaction.jsp will be called.
//				- When clicking on the action/decision/issue name, upd_action.jsp will be called
//				  to display the update page.  post_updaction.jsp will then be called to process.
//
//	Modification:
//			@ECC080905	Allow the meeting coordinator to retrieve recorder role
//			@ECC082305	Support adding issues and link action/decision to issue/PR
//			@AGQ120105	Added AJAX support to meeting. Auto refresh meeting.
//			@AGQ120705  Remove auto refresh
//			@AGQ010506  Added span tags around Action, Decision and Issue Table
//			@AGQ011206	Added debug mode and removed [Live] button. Also turned Live to be always on.
//			@AGQ011706  Support of AJAX in Submitting Action/Decision/Issue
//			@AGQ011906  Modified meeting minutes to load "Draft", if null "Note". Also made Delete button automatically appear.
//			@AGQ013106	Changed "Change Recorder" list to only show attendees who has signed in and ordered them into alphabetical order.
//			@AGQ020106	Modified "Change Recorder" and "Meeting Adjourn" to save Attendee's List before going to post_mtg_upd2 page.
//						This modification is for FF which cannot save the Attendee's List correct after Ajax replaced the checkboxes.
//			@AGQ021506	Handle if user clicks Back Button; Reload the page; count characters
//			@AGQ040406	Support of multi upload files
//			@AGQ040406a	Removed unused method and made sure validation is called correctly
//			@ECC041006	Add blog support to action/decision/issue.
//			@041906SSI	Added sort function to Project names.
//			@AGQ052306	Fix Alignment
//			@ECC061206a	Add project association to meeting.
//			@SWS061406	Updated file listing.
//			@AGQ081606	Block non Team Members from accessing the meeting for Private Type
//			@AGQ081706	Lengthen the size of the text box for meeting minutes
//			@AGQ082106	Removed project related items for OMF. Contact members are
//						under user's TeamMembers.
//			@AGQ082206	Added pop up to invite attendee to participate in meeting minutes
//			@AGQ090806	Added Filter
//			@AGQ091906	Limit Users
//			@ECC092806	Support send/show expression
//			@AGQ100306	Support of fixed position for IE and FF. Moved expression to lower right.
//			@ECC101006	Support guest to participate and view Public meetings
//			@ECC101106	Input queue.
//			@ECC110806	Modify input queue to support more options: ALL People, All of the Above
//			@ECC042507	Allow NONE or ALL to be responsible for an agenda item.
//			@ECC101807	Support trigger events.
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
<%@ page import = "java.util.regex.Pattern" %>
<%@ page import = "java.util.regex.Matcher" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>
<%@ page import = "org.apache.log4j.Logger" %>
<%@ page import = "mod.mfchat.MeetingParticipants" %>
<%@ page import = "mod.mfchat.OmfQueue" %>
<%@ page import = "mod.mfchat.PrmMeeting" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	final int RADIO_NUM			= 4;
	final int SKYPE_CONF_LIMIT	= 8;

	String midS = request.getParameter("mid");

	boolean isGuest = false;
	if (session == null) session = request.getSession(true);
	PstUserAbstractObject pstuser = (PstUserAbstractObject)session.getAttribute("pstuser");
	if (pstuser == null || pstuser instanceof PstGuest)
	{
		isGuest = true;
		if (pstuser == null) {
			pstuser = PstGuest.getInstance();
			session.setAttribute("pstuser", pstuser);
		}
	}

	Logger l = PrmLog.getLog();
	String host = Util.getPropKey("pst", "PRM_HOST");
	String USER_PIC_URL = Util.getPropKey("pst", "USER_PICFILE_URL");	// used by mtg_expr.js

	// @AGQ082406
	boolean isInvInput = true;
	String inviteInput = Util.getPropKey("pst", "MEETING_INVITE_INPUT");
	if (inviteInput!=null && inviteInput.equalsIgnoreCase("false")) isInvInput = false;

	// to check if session is OMF or PRM
	boolean isOMFAPP = Prm.isOMF();
	boolean isPRMAPP = Prm.isPRM();
	boolean isCtModule = Prm.isCtModule(session);
	String app = Prm.getAppTitle();

	int myUid = pstuser.getObjectId();
	boolean isAdmin = false;
	boolean isProgMgr = false;
	Integer io = (Integer)session.getAttribute("role");
	int iRole = 0;
	if (io != null) iRole = io.intValue();
	if (iRole > 0)
	{
		if ((iRole & user.iROLE_ADMIN) > 0)
			isAdmin = true;
		if ((iRole & user.iROLE_PROGMGR) > 0)
			isProgMgr = true;
	}

	// @AGQ090806
	String isShow = request.getParameter("isShow");
	if (isShow == null) isShow = "none";

	String imageHide = "../i/tri_up.gif";
	String imageShow = "../i/tri_dn.gif";
	String filterHide = "Hide meeting info";
	String filterShow = "Meeting info";

	// @AGQ082406
	boolean isOnParticipant = MeetingParticipants.isOn(midS);

	// only one person can run the meeting, others join
	boolean isRun = (request.getParameter("run") != null);

	// @AGQ091906 Limit Users
	int onlineCt = MeetingParticipants.usersOnline(midS);
	if (onlineCt > 30 && !isRun) {
		response.sendRedirect("mtg_view.jsp?mid="+midS);
		return;
	}

	boolean isRunPart = (isRun && isOnParticipant);
	if (isRunPart) isRun = false;
	boolean isFacilitator = (isRunPart || isRun);

	userManager uMgr = userManager.getInstance();
	actionManager aMgr = actionManager.getInstance();
	meetingManager mMgr = meetingManager.getInstance();
	projectManager pjMgr = projectManager.getInstance();
	bugManager bMgr = bugManager.getInstance();
	resultManager rMgr = resultManager.getInstance();
	attachmentManager attMgr = attachmentManager.getInstance();
	userinfoManager uiMgr = userinfoManager.getInstance();
	
	userinfo myUI = (userinfo) uiMgr.get(pstuser, String.valueOf(myUid));
	TimeZone myTimeZone = myUI.getTimeZone();
	int myTimeZoneOffset = myUI.getTimeZoneIdx();

	PstUserAbstractObject owner;

	meeting mtg = (meeting)mMgr.get(pstuser, midS);
	String status = (String)mtg.getAttribute("Status")[0];

	MeetingParticipants.setOnline(midS, String.valueOf(myUid));
	PrmUpdateCounter.updateOrCreateCounterArray(midS, PrmMtgConstants.ADINDEX);

	// @AGQ081606
	String meetingType = (String) mtg.getAttribute(meeting.TYPE)[0];
	if (meetingType == null) {
		l.error("Meeting TYPE information dissappeared"); // This should not happen
		meetingType = meeting.PRIVATE;
	}
	else if (meetingType.equals(meeting.PRIVATE) && isGuest)
	{
		response.sendRedirect("../out.jsp?e=Sorry, this is a Private Meeting - access denied");
		return;
	}
	if (!(isAdmin || isProgMgr) && meetingType.equalsIgnoreCase(meeting.PRIVATE)){
		boolean found = false;
		String myUidS = Integer.toString(myUid);
		if (!myUidS.equals(mtg.getAttribute("Owner"))) {
			String s;
			Object [] oArr = mtg.getAttribute("Attendee");
			for (int j=0; j<oArr.length; j++)
			{
				s = (String)oArr[j];
				if (s == null) break;		// no attendee
				if (s.startsWith(myUidS))
				{
					found = true;
					break;					// found
				}
			}
			if (!found) {
				// don't show this meeting
				response.sendRedirect("../out.jsp?e=Sorry, this is a Private Meeting - access denied");
				return;
			}
		}
	}

	// active recorder
	int recorderId = 0;
	String s = (String)mtg.getAttribute("Recorder")[0];
	if (s != null)
	{
		recorderId = Integer.parseInt(s);
	}
	if (recorderId==myUid && !isRun && !isRunPart)
	{
		// just changed recorder to me
		response.sendRedirect("mtg_live.jsp?mid="+midS+"&run=true&isShow="+isShow+"&anchor=minute");
		return;
	}

	String anchor = request.getParameter("anchor");
	if (anchor == null) anchor = "";
	
	SimpleDateFormat df1 = new SimpleDateFormat ("MM/dd/yy");
	SimpleDateFormat df2 = new SimpleDateFormat ("MM/dd/yyyy hh:mm a");
	SimpleDateFormat df3 = new SimpleDateFormat ("MM/dd/yyyy");
	SimpleDateFormat df4 = new SimpleDateFormat ("MM/dd/yy (E) hh:mm a");
	SimpleDateFormat df5 = new SimpleDateFormat ("hh:mm a");
	if (!userinfo.isServerTimeZone(myTimeZone)) {
		df1.setTimeZone(myTimeZone);
		df2.setTimeZone(myTimeZone);
		df3.setTimeZone(myTimeZone);
		df4.setTimeZone(myTimeZone);
		df5.setTimeZone(myTimeZone);
	}

	// meeting start time
	String title = null;
	String UserEdit = "disabled";
	Date mtgStartTime = (Date)mtg.getAttribute("EffectiveDate")[0];
	if (isRun)
	{
		// this might be a true start of meeting or simply come back from other page
		UserEdit = "";
		title = "Running Meeting";

		// set meeting state to LIVE
		int rc = mtg.setStatus(pstuser, meeting.LIVE);	// sync
		if (rc < 0)
		{
			if (rc == meeting.ERR_ALREADY_LIVE)
			{
				if (recorderId != myUid)
				{
					response.sendRedirect("mtg_wait.jsp?mid="+midS);
					return;
				}
			}
			else
			{
				response.sendRedirect("../out.jsp?msg=Error changing meeting state in mtg_live.jsp (Error code: "+rc+")");
				return;
			}
		}

		if (mtgStartTime == null)
		{
			// new start
			//mtgStartTime = new Date(new Date().getTime() - userinfo.getServerUTCdiff());	// UTC time
			mtgStartTime = new Date();
			mtg.setAttribute("EffectiveDate", mtgStartTime);
			mtg.setAttribute("Recorder", String.valueOf(myUid));
			mMgr.commit(mtg);

			// @ECC101807 this must be the first recorder just started the meeting
			PrmEvent.createTriggerEvent(pstuser, PrmEvent.EVT_MTG_START, midS,
					(String)mtg.getAttribute("TownID")[0], null);
		}
		else
		{
			// check and set recorder
			if (recorderId == 0)
			{
				recorderId = myUid;
				mtg.setAttribute("Recorder", String.valueOf(recorderId));
				mMgr.commit(mtg);
			}
			else
			{
				// check to see if I am the recorder, if not, redirect to join
				if (recorderId != myUid)
				{
					response.sendRedirect("mtg_live.jsp?mid="+midS);
					return;
				}
			}
		}
	}
	else
	{
		// join meeting
		if (!status.equals(meeting.LIVE))
		{
			// meeting is over
			response.sendRedirect("mtg_view.jsp?mid="+midS);
			return;
		}
		title = "Join Meeting";
		// @ECC101807 trigger join meeting event
		if (anchor.length() <= 0)
			PrmEvent.createTriggerEvent(pstuser, PrmEvent.EVT_MTG_JOIN, midS,
					(String)mtg.getAttribute("TownID")[0], null);
	}

	// @ECC080905	remember recorder's full name
	user u;
	String uName;
	String recorderName = null;
	if (recorderId > 0)
	{
		u = (user)uMgr.get(pstuser, recorderId);
		recorderName = u.getFullName();
	}

	String subject = (String)mtg.getAttribute("Subject")[0];
	String location = (String)mtg.getAttribute("Location")[0];
	if (location == null) location = "";
	String recurring = (String)mtg.getAttribute("Recurring")[0];

	String ownerIdS = (String)mtg.getAttribute("Owner")[0];
	int ownerId = Integer.parseInt(ownerIdS);
	user ou = (user)uMgr.get(pstuser, ownerId);
	String ownerName = ou.getFullName();
	
	Date start = (Date)mtg.getAttribute("StartDate")[0];
	Date expire = (Date)mtg.getAttribute("ExpireDate")[0];
	
	String todayS = df1.format(new Date());
	String startS = df2.format(start);
	String expireS = df2.format(expire);

	// get potential proj team member list and bugId list
	int selectedPjId = 0;
	s = request.getParameter("projId");
	if (s!=null && s.length()>0)
		selectedPjId = Integer.parseInt(s);
	else
	{
		// @ECC061206a
		s = (String)mtg.getAttribute("ProjectID")[0];
		if (s!=null) selectedPjId = Integer.parseInt(s);
	}

	PstAbstractObject [] projMember = null;
	int [] bIds = new int[0];
	// @AGQ82106 OMF uses personal contacts
	if (isRun)
	{
		if (isOMFAPP) {
			Object [] objArr = ((user) pstuser).getAttribute(user.TEAMMEMBERS);
			if (objArr[0] != null)
				projMember = uMgr.get(pstuser, objArr);
			else
				projMember = new PstAbstractObject[0];
			// Sort
			Util.sortUserArray(projMember, true);
		}
		else if (selectedPjId <= 0)
		{
			projMember = ((user)pstuser).getAllUsers();
			bIds = bMgr.findId(pstuser, "om_acctname='%'");
		}
		else
		{
			projMember = ((user)pstuser).getTeamMembers(selectedPjId);
			bIds = bMgr.findId(pstuser, "ProjectID='" + selectedPjId + "'");
		}
	}

	// get attendee list
	Object [] attendeeArr = mtg.getAttribute("Attendee");
	String [] sa;
	ArrayList attendeeList = new ArrayList();	// those who hasn't signed in yet
	ArrayList presentList = new ArrayList();	// those who has physically present or logon
	ArrayList signedInList = new ArrayList();	// those who logon to signed in
	boolean found = false;
	for (int i=0; i<attendeeArr.length; i++)
	{
		s = (String)attendeeArr[i];
		if (s == null) break;
		sa = s.split(meeting.DELIMITER);
		if (StringUtil.isNullOrEmptyString(sa[0]))
			continue;
		int aId = Integer.parseInt(sa[0]);

		if (aId == myUid)
		{
			if (!sa[1].endsWith(meeting.ATT_LOGON + meeting.ATT_PRESENT))
			{
				// I just logon
				mtg.removeAttribute("Attendee", s);
				s += meeting.ATT_LOGON + meeting.ATT_PRESENT;
				mtg.appendAttribute("Attendee", s);
				mMgr.commit(mtg);
				PrmUpdateCounter.updateOrCreateCounterArray(midS, PrmMtgConstants.ADINDEX);
			}
			presentList.add(sa[0]);		// I just signed in
			signedInList.add(sa[0]);
			found = true;
			continue;
		}

		if (sa[1].endsWith(meeting.ATT_LOGON + meeting.ATT_PRESENT))
			signedInList.add(sa[0]);
		if (sa[1].endsWith(meeting.ATT_PRESENT))
			presentList.add(sa[0]);
		else
			attendeeList.add(sa[0]);
	}
	if (!found && !isGuest) {
		presentList.add(String.valueOf(myUid));
		signedInList.add(String.valueOf(myUid));

		// Public meeting add user to list
		if (!isAdmin) {
			s = myUid + meeting.DELIMITER + meeting.ATT_OPTIONAL + meeting.ATT_LOGON + meeting.ATT_PRESENT;
			mtg.appendAttribute(meeting.ATTENDEE, s);
			mMgr.commit(mtg);
			PrmUpdateCounter.updateOrCreateCounterArray(midS, PrmMtgConstants.ADINDEX);
		}
	}

	// get potential new attendee list
	ArrayList newAttendeeList = new ArrayList();
	int id;
	if (isRun)
	{
		for (int i=0; i<projMember.length; i++)
		{
			u = (user)projMember[i];
			if (u == null) continue;

			id = u.getObjectId();
			found = false;
			for (int j=0; j<presentList.size(); j++)
			{
				if (id == Integer.parseInt((String)presentList.get(j)))
				{
					found = true;
					break;
				}
			}
			for (int j=0; !found && j<attendeeList.size(); j++)
			{
				if (id == Integer.parseInt((String)attendeeList.get(j)))
				{
					found = true;
					break;
				}
			}
			if (!found)
				newAttendeeList.add(u);
		}
	}

	// get agenda items
	Object [] agendaArr = mtg.getAttribute("AgendaItem");
	Arrays.sort(agendaArr, new Comparator <Object> ()
	{
		public int compare(Object o1, Object o2)
		{
			try{
			String [] sa1 = ((String)o1).split(meeting.DELIMITER);
			String [] sa2 = ((String)o2).split(meeting.DELIMITER);
			int i1 = Integer.parseInt(sa1[0]);	// pre-order
			int i2 = Integer.parseInt(sa2[0]);	// pre-order
			return (i1-i2);
			} catch (Exception e) {return 0;}
		}
	});

	// meeting minutes
	// get the blog text - meeting notes
// @AGQ011906
	Object bTextObj = mtg.getAttribute("Note")[0];
	String bText = (bTextObj==null)?"":new String((byte[])bTextObj, "utf-8");
	if (bText.length() == 0) {
		// put the agenda into the minute
		bText = mtg.getAgendaString().replaceAll("@@", ":");	// the agenda may have this encoded
	}

	if (isRun) {
		// @AGQ091306 Removes extra var tags
		Pattern p = Pattern.compile("<var id=['\"]scrollMark['\"]></var>");
		Matcher m = p.matcher(bText);
		bText = m.replaceAll("");
		// @AGQ100606 Remove insertNotes id
		p = Pattern.compile(" id=['\"]insertNotes['\"]");
		m = p.matcher(bText);
		bText = m.replaceAll("");
	}

	// get initial skype names.  First stuff the attendeeList and presentList with actual user objects.
	Util.sortExUserList(pstuser, attendeeList);	// exchange the list of ids with list of users and sort
	Util.sortExUserList(pstuser, presentList);	// exchange the list of ids with list of users and sort
	String skypeName = "";
	int ct = 0;
	for (int i=0; ct<SKYPE_CONF_LIMIT && i<presentList.size(); i++)
	{
		u = (user)presentList.get(i);
		if (u.getObjectId() == myUid) continue;
		s = (String)u.getAttribute("SkypeName")[0];
		if (s != null)
		{
			skypeName += s + ";";
			ct++;
		}
	}
	for (int i=0; ct<SKYPE_CONF_LIMIT && i<attendeeList.size(); i++)
	{
		u = (user)attendeeList.get(i);
		if (u.getObjectId() == myUid) continue;
		s = (String)u.getAttribute("SkypeName")[0];
		if (s != null)
		{
			skypeName += s + ";";
			ct++;
		}
	}

	// @ECC100606 get meeting save counter to support minimizing chat session traffic
	int mnCount = PrmUpdateCounter.getMtgCounters(midS)[PrmMtgConstants.MNINDEX];

	String ua = request.getHeader( "User-Agent" );
	boolean isFirefox = ( ua != null && ua.indexOf( "Firefox/" ) != -1 );
	boolean isMSIE = ( ua != null && ua.indexOf( "MSIE" ) != -1 );

	int idx;
	String screenName = pstuser.getObjectName();
	if ((idx = screenName.indexOf('@')) != -1) screenName = screenName.substring(0, idx);
%>

<head>
<title>Meeting Online</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<%-- @AGQ040406--%>
<script src="../multifile.js"></script>
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../forms.jsp" flush="true"/>
<script language="JavaScript" src="../get-date.js"></script>
<script language="JavaScript" src="../date.js"></script>
<script language="JavaScript" src="mtg_expr1.js"></script>
<script language="JavaScript" src="mtg_expr.js"></script>
<script type="text/javascript" src="<%=host%>/FCKeditor/fckeditor.js"></script>
<%--  @AGQ120705 --%>
<script type="text/javascript" src="ajax_utils.js"></script>
<script type="text/javascript" src="mtg.js"></script>
<script type="text/javascript" src="mtg1.js"></script>
<script type="text/javascript" src="../resize.js"></script>
<script type="text/javascript" src="../util.js"></script>

<script type="text/javascript">
<%--
<% System.out.println(Util.stringToHTMLStringSimple(bText)); %>
var old = "<%=Util.stringToHTMLStringSimple(bText) %>";
--%>
var screenName = "<%=screenName%>";
var jUSER_PIC_URL = "<%=USER_PIC_URL%>";

window.onload = function()
{
<% if(isRun) { %>
		var oFCKeditor = new FCKeditor( 'mtgText' ) ;
		oFCKeditor.Height = 450;
		oFCKeditor.ReplaceTextarea() ;

		if(!isBackButton()) {
			init(1);
			initDrag();
		}
<% } else { %>
		init(0);
		setTextBoxId("meetingNotes");
		initDrag(300);
<% } %>

	// to enable dragging editor box
	new dragObject(handleBottom[0], null, new Position(0, beginHeight),
					new Position(0, 1000), null, BottomMove, null, false, 0);

<%	if (isInvInput)
		out.println("initMFC();");
%>
	startclock();

	if (("<%=anchor%>" != "") && location.href.indexOf("#") == -1) {
		location.href = location.href + "#" + "<%=anchor%>";
	}
}

<!--
var diff = getDiffUTC();
var begin = <%=mtgStartTime.getTime()%>;	//new Date('<%=df2.format(mtgStartTime)%>').getTime() + diff;
var timerRunning = false;
var currentType = "";
var myObjName = "<%=pstuser.getObjectName()%>";
var inputQhead = "<%=MeetingParticipants.getInputQHead(midS)%>";
var isFacilitator = <%=isFacilitator%>;
var midS = '<%=midS%>';
var isGuest = false;
if ('<%=isGuest%>' == 'true') isGuest = true;

if (MNCOUNT<=0 && '<%=mnCount%>'!='0')
{
	var mnc = parseInt('<%=mnCount%>');
	MNCOUNT = mnc;
}

function stopclock ()
{
	if(timerRunning)
		clearTimeout(timerID);
	timerRunning = false;
}

function startclock ()
{
	stopclock();
	showtime();
}

function showtime ()
{
	var now = new Date().getTime();
 	var elapsed = (now - begin)/1000;
	var hours = Math.floor(elapsed/3600);
	var minutes = Math.floor(elapsed/60) - 60*hours;
	var seconds = Math.floor(elapsed%60);
	timeValue = "";
	timeValue += hours;
	timeValue += ((minutes < 10) ? ":0" : ":") + minutes;
	timeValue += ((seconds < 10) ? ":0" : ":") + seconds;
	var clock = document.getElementById('clock');
	clock.value = timeValue;

	timerID = setTimeout("showtime()",1000);
	timerRunning = true;
}

function fixElement(e, msg)
{
	alert(msg);
// @AGQ040306
	if (e)
		e.focus();
}

function validation()
{
	// @AGQ040406
	formblock= document.getElementById('inputs');
	forminputs = formblock.getElementsByTagName('input');
	var isFileName = true;
	for (var i=0; i<forminputs.length; i++) {
		if (forminputs[i].type == 'file' && forminputs[i].value != '') {
			if (isFileName)
				isFileName = affirm_addfile(forminputs[i].value);
			else
				break;
		}
	}
	if(!isFileName)
		return false;

// @AGQ040406
	if(!findDuplicateFileName(forminputs))
		return false;	

	return validationAC();
}

function validationAC()
{
	if ('<%=isRun%>' != 'true')
		return false;

	var f = document.updMeeting;

		// check for action item
	if (f.Description.value != '')
	{
		// create a new action item
		if (f.Description.value.length > 255)
		{
			s = "The " + currentType + " is " + f.Description.value.length
				+ " characters long that is longer than the max allowed length (255), please shorten the description or break the item into multiple items.";
			if (f.Description.value.length > 255)
			{
				alert(s);
				return false;
			}
		}
		getall(f.Responsible);
	}
	f.newAttendee.value = '';

	if (f.recorder.value == '<%=recorderId%>')
		f.recorder.value = '';		// no change of recorder
		
	return true;
}

function setPageLocation(s)
{
	var updMeeting = document.getElementsByName("updMeeting")[0];
	updMeeting.PageLabel.value = s;
	updMeeting.NoSave.value = '';
	return validation();
}

function resetAC()
{
	// reset button for action item/decision/issue
	var updMeeting = document.getElementsByName("updMeeting")[0];
	updMeeting.Description.value = '';
	// @AGQ021506
	charRemain("Description", "charCount");
	var e = updMeeting.Responsible;
	getall(e);
	swapdata(e, updMeeting.Selected);

	e = updMeeting.Owner;
	for(j = 0; j < e.length; j++)
	{
		if (e.options[j].value == '<%=myUid%>')
			e.options[j].selected = true;
		else
			e.options[j].selected = false;
	}

	updMeeting.Priority[1].selected = true;	// medium

	updMeeting.Expire.value = '<%=todayS%>';
}

function editAC(id, type)
{
	setMtext();
	var updateAction = document.getElementsByName("updateAction")[0];
	updateAction.type.value = type;
	updateAction.oid.value = id;

	var e = updMeeting.projId;
	for (i=0; i<e.length; i++)
		if (e.options[i].selected) updateAction.pid.value = e.options[i].value;

	updateAction.action = "upd_action.jsp";
	updateAction.submit();
}

function deleteAC()
{
	setMtext();
	var updateAction = document.getElementsByName("updateAction")[0];
	updateAction.submit();
}

function setMtext()
{
	// @AGQ092906	Retreived FCKeditor text using FCKeditor's methods.
	var oEditor = FCKeditorAPI.GetInstance('mtgText');
	var bText = oEditor.EditorDocument.body.innerHTML;
	var updateAction = document.getElementsByName("updateAction")[0];
	updateAction.mtext.value = bText;
}

function checkNewAtt()
{
	if (document.updMeeting.newAttendee.value == '')
		return false;
}

function newRecorder()
{
	var e = document.updMeeting.recorder;
	if (e.value == '<%=recorderId%>')
		return false;
// @AGQ040406a
	ajaxSaveAttendee();
	document.getElementById("SaveAttendee").value = false;
	isOkay = validation();
	if (isOkay)
		stopAutoSaveTimer();
	return isOkay;
}

function retrieveRecorder()
{
	var msg = "Do you really want to retrieve the facilitator responsibility from " + '<%=recorderName%>' + "?\n\n";
		msg += "   OK = Yes\n";
		msg += "   CANCEL = No";
	if (!confirm(msg))
		return false;

	var readOnly = document.getElementsByName("readOnly")[0];
	readOnly.Continue.value = "retrieveRecorder";
	readOnly.recorder.disabled = false;
	readOnly.recorder.value = '<%=myUid%>';
	readOnly.encoding = "multipart/form-data";
	readOnly.action = "post_mtg_upd2.jsp";
}

var isAdjourning = false;
function goAdjourn()
{
	// this function should only work once to avoid user clicking goAdjourn() multiple of times
	if (isAdjourning)
		return false;
	else
		isAdjourning = true;
	
	document.updMeeting.adjourn.value = 'true';
// @AGQ040406a
	ajaxSaveAttendee();
	document.getElementById("SaveAttendee").value = false;
	isOkay = validation();
	if (isOkay)
		stopAutoSaveTimer();
	return isOkay;
}

function isDecision()
{
	var updMeeting = document.getElementsByName("updMeeting")[0];
	if (updMeeting.BugId != null)
		updMeeting.BugId.disabled = false;
	updMeeting.Responsible.disabled = true;
	updMeeting.Selected.disabled = true;
	updMeeting.Owner.disabled = true;
	updMeeting.Expire.disabled = true;
	currentType = "decision record";
}

function isAction()
{
	var updMeeting = document.getElementsByName("updMeeting")[0];
	if (updMeeting.BugId != null)
		updMeeting.BugId.disabled = false;
	updMeeting.Responsible.disabled = false;
	updMeeting.Selected.disabled = false;
	updMeeting.Owner.disabled = false;
	updMeeting.Expire.disabled = false;
	currentType = "action item";
}

function isIssue()
{
	var updMeeting = document.getElementsByName("updMeeting")[0];
	if (updMeeting.BugId != null)
		updMeeting.BugId.disabled = true;
	updMeeting.Responsible.disabled = true;
	updMeeting.Selected.disabled = true;
	updMeeting.Owner.disabled = false;
	updMeeting.Expire.disabled = true;
	updMeeting.Expire.disabled = true;
	currentType = "issue record";
}

function selectType(ty)
{
	if (ty=='Action') isAction();
	else if (ty=='Decision') isDecision();
	else isIssue();
}

function popup_cal()
{
	if (currentType == "action item")
		show_calendar('updMeeting.Expire');
}

<%-- @AGQ082206 --%>
<%	if (isFacilitator) { %>
function inviteParti(isInvite) {
	var w = 350;
	var h
	if (isMozilla)
		h = 200;
	else
		h = 270;
	var winw = (screen.width - w) / 2;
	var winh = (screen.height - h) / 2;

	if (isRun == 1) {
		// Save meetings notes when users click to invite participants
		setCursorIndex();
		ajaxMtgNotes(false);
	}
	var load = window.open('mtg_invite.jsp?mid=<%=midS %>&pos='+position+'&isInvite='+isInvite+'&charBefore='+charBefore+'&charAfter='+charAfter,'',
		'scrollbars=no,menubar=no,height='+h+',width='+w+',resizable=yes,toolbar=no,location=no,status=yes,top='+winh+',left='+winw);
}
<% 	} %>

//-->
</script>

<style type="text/css">
.plaintext {line-height: 20px}
</style>

</head>

<title><%=app%> Meeting Live</title>
<%-- @AGQ021506 --%>
<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0" onpageshow="if(event.persisted) window.location.reload();">
<bgsound id="IESound">
<span id="FFSound"></span>

<table width="90%" height="100%" border="0" cellspacing="0" cellpadding="0">
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
	            <table width="100%" border="0" cellspacing="0" cellpadding="0">
				  <tr>
					<td width="26" height="30"><a name="top">&nbsp;</a></td>
                	<td height="30" align="left" valign="bottom" class="head">
                	<b><%=title%></b>
					</td>
					<td class="formtext" width='300'>
<%
	// only people involved in this meeting will come to this page
	if (isRun)
	{
		out.print("<img src='../i/bullet_tri.gif' width='20' height='10'>");
		out.print("<a href='javascript:document.updMeeting.submit()' onClick='javascript: return goAdjourn();' class='listlinkbold'>Meeting Adjourn</a>");
	}
%>
					</td>
					</tr>
	            </table>
	          </td>
	        </tr>
			<tr>
          		<td width="100%">
<!-- Navigation Menu -->
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Event" />
				<jsp:param name="subCat" value="" />
				<jsp:param name="role" value="<%=iRole%>" />
			</jsp:include>
<!-- End of Navigation Menu -->
				</td>
	        </tr>
		</table>

<!-- Content Table -->

<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr><td colspan="3"><img src="../i/spacer.gif" width="5" height="10"/></td></tr>

<!-- Grouping table: group subject, location, start, end, owner into a table to share with links -->
<tr><td colspan='3'>
<table border='0' cellspacing="0" cellpadding="0" width='100%'>
<tr>

<!-- left side -->
<td valign="top" width='70%'>
<table width='100%' border='0' cellspacing="0" cellpadding="0">

<!-- Subject -->
<tr>
	<td width='30'><img src="../i/spacer.gif" border="0" width='30' height="1"/></td>
	<td width="150" class="plaintext"><b>Subject:</b></td>
	<td class="plaintext"><b><%=subject%></b></td>
</tr>

<!-- Project Name -->
<%
	String projIdS = (String)mtg.getAttribute("ProjectID")[0];
	if (projIdS != null)
	{
		s = ((project)pjMgr.get(pstuser, Integer.parseInt(projIdS))).getDisplayName();
		s = "<a href='../project/proj_top.jsp?projId=" + projIdS + "'>" + s + "</a>";
%>
<!-- Project -->
<tr>
	<td></td>
	<td width="150" class="plaintext" valign='top'><b>Project:</b></td>
	<td class="plaintext"><%=s%></td>
</tr>
<%	}
	else
	{
		projIdS = "";
	}
%>

<!-- Location -->
<tr>
	<td>&nbsp;</td>
	<td class="plaintext"><b>Location:</b></td>
	<td class="plaintext"><%=location%></td>
</tr>

<!-- Meeting time -->
<tr>
	<td>&nbsp;</td>
	<td width='150' class="plaintext" valign="top"><b>Schedule:</b></td>
	<td class="plaintext">

<script language="JavaScript">
<!-- Begin
	var stD = new Date('<%=startS%>');
	var enD = new Date('<%=expireS%>');

	var tm = stD.getTime() + diff;
	stD = new Date(tm);

	tm = enD.getTime() + diff;
	enD = new Date(tm);

	document.write("<%=df4.format(start)%>" + " - " + "<%=df5.format(expire)%>");
// End -->
</script>

<%
	// prev and next meeting
	int [] ids;
	if (recurring != null)
	{
		sa = recurring.split(meeting.DELIMITER);
		s = sa[0];
		if (s.equals(meeting.DAILY_NOWKEN))
			s = meeting.DAILY;
		out.print("&nbsp;&nbsp;&nbsp;(" + s + " event for <b>" + (Integer.parseInt(sa[1])+1) + "</b> occurrences)");

		// prev
		ids = mMgr.findId(pstuser, "Recurring='%" + midS + "%'");
		if (ids.length > 0)
		{
			out.print("&nbsp;&nbsp;&nbsp;<a href='mtg_view.jsp?mid=" + ids[0] + "'><< Prev Meeting</a>");
		}

		// next
		if (sa.length >=3 && sa[2]!=null)
		{
			s = sa[sa.length-1];
			if (!s.contains(";") && Integer.parseInt(s)>1000)
				out.print("&nbsp;&nbsp;&nbsp;| &nbsp;&nbsp;<a href='mtg_view.jsp?mid=" + s + "'>Next Meeting >></a>");
		}
	}
%>
	</td>
</tr>

</table></td>
<!-- end left side -->

<td><img src='../i/spacer.gif' width='20'/></td>

<!-- right side: CLOCK  /////////////////////////////////////////////// -->
<td valign="top">
<table width='100%' border='0' cellpadding='0' cellspacing='0'>
<tr>
<td>
	<table height='100%' border='0' cellpadding='0' cellspacing='0'>

	<tr>
		<td valign="top" align="left" class="plaintext_blue">
			Elapsed time:
		</td>
	</tr>
	<tr><td valign="top" align="right">
		<input id="clock" type="text" size="8" value="00:00:00"
			style="text-align: center; font-family: Verdana, Arial, Helvetica, sans-serif;
			font-size: 20px; font-weight: bold;
			color: #FFFFFF; background-color: #000099" readonly />
	</td></tr>
	<tr>
<!-- SKYPE -->
<td align='left' valign='bottom'>
<%
	if (skypeName.length() > 0)
		out.print("<a href='skype:" + skypeName + "'>");
	else
		out.print("<a href='javascript:alert(\"Sorry, none of the users in this meeting has entered a Skype name.\");'>");
	out.print("<img src='../i/skype.gif' border='0'></a>");
%>
</td>
	</tr>
	</table>
</td>
</tr>

</table>
<!-- end right side -->

</tr></table>
</td></tr>
<!-- end Grouping table -->


<%
	////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////
	// panel for meeting info
	out.print("<tr><td colspan='3'>");
	out.print(Util.getHeaderPartitionLine());
	out.print("<img id='ImgInfoPanel' src='../i/bullet_tri.gif'/>");
	out.print("<a id='AInfoPanel' href='javascript:togglePanel(\"InfoPanel\", \"Meeting info\", \"Hide meeting info\");' class='listlinkbold'>Meeting info</a>");
	
	out.print("<DIV id='DivInfoPanel' style='display:" + isShow + ";'>");
	out.print("<table border='0' cellspacing='0' cellpadding='0' width='100%'>");	// Info panel table
%>

<!-- Type -->
<%
	//String meetingType = (String) mtg.getAttribute(meeting.TYPE)[0];
	if (meetingType.equals(meeting.PRIVATE))
	{
		meetingType += " / ";
		if ((s = (String)mtg.getAttribute("TownID")[0]) != null)
			meetingType += townManager.getInstance().get(pstuser, Integer.parseInt(s)).getObjectName();
		else
			meetingType += "Personal";
	}
%>
<tr>
	<td width='30'><img src='../i/spacer.gif' width='30' height='1'/></td>
	<td title="Public meetings are opened to all users. Private meeting are only viewable by attendees." class="plaintext"><b>Type:</b></td>
	<td class="plaintext">
		<%=meetingType %>
	</td>
</tr>

<!-- Owner -->
<tr>
	<td >&nbsp;</td>
	<td class="plaintext"><b>Coordinator:</b></td>
	<td class="plaintext">
		<a href="../ep/ep1.jsp?uid=<%=ownerId%>" class="listlink">
		<%=ownerName%></a>
	</td>
</tr>

<tr><td colspan="3" width="10"><img src="../i/spacer.gif" border="0" width="10" height="3"/></td></tr>

<% if (isRun){%>
<form name="updMeeting" action="post_mtg_upd2.jsp" method="post" enctype="multipart/form-data" onSubmit="return (validation())?ajaxSaveAttendee():false;">
<input type="hidden" id="mid" name="mid" value="<%=midS%>"/>
<input type="hidden" id="Continue" name="Continue" value="runMeeting"/>
<input type="hidden" id="adjourn" name="adjourn" value=""/>
<input type="hidden" id="PageLabel" name="PageLabel" value=""/>
<input type="hidden" id="NoSave" name="NoSave" value=""/>
<input type="hidden" id="SaveAttendee" name="SaveAttendee" value="true"/>
<input type="hidden" id="ProjectId" name="ProjectId" value="<%=projIdS%>"/>

<input style="visibility:hidden" id="backButton" name="backButton" value="1" defaultvalue="1"/>
	<% if (isOMFAPP) { %>
		<input type="hidden" id="HOSTS" value=".."/>
	<%	} else { %>
		<input type="hidden" id="HOSTS" value="<%=host%>"/>
	<%	} %>
<% } else {%>
<form name="readOnly" action="mtg_live.jsp?mid=<%=midS%>" method="post">
<input type="hidden" name="Continue"/>
	<% if (isOMFAPP) { %>
		<input type="hidden" id="HOSTS" value=".."/>
	<%	} else { %>
		<input type="hidden" id="HOSTS" value="<%=host%>"/>
	<%	} %>
<% }%>

<!-- Recorder -->
<tr>
	<td >&nbsp;</td>
	<td class="plaintext" width='120'><b>Facilitator:</b></td>
	<td class="plaintext">
		<select id="rcNames" class="formtext" type="text" name="recorder" <%=UserEdit%>>
<%

	Util.sortExUserList(pstuser, signedInList);	// exchange the list of ids with list of users and sort
	for (int i=0; i<signedInList.size(); i++)
	{
		u = (user)signedInList.get(i);
		id = u.getObjectId();
		uName = u.getFullName();
		out.print("<option value='" + id + "'");
		if (id == recorderId) out.print(" selected");
		out.println(">&nbsp;" +uName+ "</option>");
	}
	out.println("</select>");
	if (isRun)
		out.println("&nbsp;&nbsp;<input type='submit' class='button' name='changeRecorder' value='Change Facilitator' onclick='return newRecorder();'>");
	else if (myUid == ownerId && !isRunPart)
	{
		// @ECC080905	Allow meeting coordinator to retrieve the recorder role
		out.println("&nbsp;&nbsp;<input type='submit' class='button' name='forceRetrieveRecorder' value='Retrieve Facilitator Role' onclick='return retrieveRecorder();'>");
	}
%>

	</td>
</tr>

<tr>
	<td width="20" align="right"><img src="../i/spacer.gif" border="0" width="20" height="5"/></td>
	<td width="150"></td>
	<td></td>
</tr>

<!-- New Attendee -->
<% if (isRun) {%>
<tr>
	<td>&nbsp;</td>
	<td class="plaintext" valign="top"><b>Attendee:</b></td>
	<td class="plaintext">
		<select id="adNames" class="formtext" type="text" name="newAttendee">
		<option value=''>- new attendee -</option>
<%
		for (int i=0; i<newAttendeeList.size(); i++)
		{
			u = (user)newAttendeeList.get(i);
			id = u.getObjectId();
			uName = u.getFullName();
			out.print("<option value='" + id + "'");
			out.println(">&nbsp;" +uName+ "</option>");
		}
%>
			</select>
		&nbsp;&nbsp;<input type="button" class="button" name="addNew" id="addNewAD" value="  Add  " onclick="javascript:ajaxAddAD();"/>
	</td>
</tr>
<%	}%>

<!-- Attendee List -->
<tr>
	<td >&nbsp;</td>
	<td class="plaintext" valign="top"><%if (!isRun){out.print("<b>Attendee:</b>");}%></td>
	<td class="plaintext">
<%	if (isRun) { %>
		<span id="adObjTable" onMouseover="javascript: attendeeMO = true" onMouseout="javascript: attendeeMO = false">
<%	}
	else { %>
		<span id="adObjTable">
<%	} %>
		<table border='0' cellspacing='0' cellpadding='0'>
<%
	int counterAD = 0;
	int num = 0;
	String idS, uname;
	boolean curOnline;
	StringBuffer onlineStrBuf = new StringBuffer();
	int cnt=0, pos=-1;
	for(int i=0; i<presentList.size(); i++)
	{
		u = (user)presentList.get(i);
		id = u.getObjectId();
		idS = String.valueOf(id);
		curOnline = MeetingParticipants.isOnline(midS, idS);
		uname = u.getObjectName();
		if (uname.equalsIgnoreCase("admin")) continue;	// don't show admin
		if ((idx = uname.indexOf("@")) != -1) uname = uname.substring(0, idx);

		if (num%RADIO_NUM == 0) out.print("<tr>");
		out.print("<td valign='top' width='20'><input id='ckAD" + counterAD + "' type='checkbox' name='present_"
			+ id + "' " + UserEdit);
		out.print(" checked></td><td class='plaintext' width='115'><a href='../ep/ep1.jsp?uid=" + id + "' class='listlink'>"
			+ uname + "</a>");

		if (curOnline)
		{
			boolean isChatting = MeetingParticipants.isParticipant(midS, idS);
			pos = cnt++ % 6;
			if (pos == 0)
				onlineStrBuf.append("<tr><td><img src='../i/spacer.gif' width='15' height='1'></td>");	// start a new row
			onlineStrBuf.append("<td><img src='../i/icon_on.gif'></td><td class='plaintext' valign='middle' width='80'>");
			if (isFacilitator && id!=myUid)
			{
				if (!isChatting)
					onlineStrBuf.append("<a href='javascript:enableInputQHead(\"" +midS + "\", 4, \"" + uname + "\");' class='listlink' title='Click to add this person to chat session'>" + uname + "</a>");
				else
					onlineStrBuf.append("<a href='javascript:enableInputQHead(\"" + midS + "\", 0, \"" + uname + "\");' class='listlink' title='Click to end input from this person'><font color='#dd0000'>" + uname + "</font></a></td>");
			}
			else if (isChatting)
				onlineStrBuf.append("<font color='#ee0000' title='Currently in chat session'>" + uname + "</font>");
			else
				onlineStrBuf.append(uname);
			onlineStrBuf.append("</td>");
			if (pos == 5)
				onlineStrBuf.append("</tr>");
		}

		out.print("</td>");
		if (num%RADIO_NUM == RADIO_NUM-1) out.print("</tr>");
		num++;
		counterAD++;
	}
	if (pos!=-1 && pos!=5)
	{
		onlineStrBuf.append("<td colspan='" + (5-pos) + "'></td>");
		onlineStrBuf.append("</tr>");	// need to close the last line
	}

	for(int i=0; i<attendeeList.size(); i++)
	{
		u = (user)attendeeList.get(i);
		id = u.getObjectId();
		idS = String.valueOf(id);
		curOnline = MeetingParticipants.isOnline(midS, idS);
		uname = u.getObjectName();
		if ((idx = uname.indexOf("@")) != -1) uname = uname.substring(0, idx);

		if (num%RADIO_NUM == 0) out.print("<tr>");
		out.print("<td valign='top' width='20'><input id='ckAD" + counterAD + "' type='checkbox' name='present_"
			+ id + "' " + UserEdit);
		out.print("></td><td class='plaintext' width='115'><a href='../ep/ep1.jsp?uid=" + id + "' class='listlink'>"
			+ uname + "</a>");

		if (curOnline)
			out.print("&nbsp;<img title='online' style='vertical-align: top;' src='../i/icon_on.gif'>");

		out.print("</td>");
		if (num%RADIO_NUM == RADIO_NUM-1) out.print("</tr>");
		num++;
		counterAD++;
	}
	if (num%RADIO_NUM != 0) out.print("</tr>");
%>
		</table>
		</span>
	</td>
</tr>

<tr><td colspan="3"><img src="../i/spacer.gif" width="5" height="10"/></td></tr>

<!-- Agenda -->
<tr>
	<td>&nbsp;</td>
	<td class="plaintext" valign="top"><b>Agenda:</b></td>
<%
	boolean even = false;
	String bgcolor = null;
	int order, level, duration, width, hour, min;
	String[] levelInfo = new String[10];
	String itemName;

if (agendaArr[0] != null)
{%>
	<td class="plaintext">
		<table width='100%' border="0" cellspacing="0" cellpadding="0">

<!-- header -->
	<tr>
	<td colspan="8" bgcolor="#EBECED" height="3"><img src="../i/spacer.gif" width="1" height="3" border="0"/></td>
	</tr>

	<tr>
	<td colspan="8" height="2" bgcolor="#336699"><img src="../i/spacer.gif" width="2" height="2"/></td>
	</tr>

	<tr>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="300" bgcolor="#6699cc" class="td_header"><strong>&nbsp;Agenda Item</strong></td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"/></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="100" bgcolor="#6699cc" class="td_header"><strong>Time</strong></td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"/></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="120" bgcolor="#6699cc" class="td_header" align="left"><strong>Responsible</strong></td>
	</tr>
<!-- header end -->

<%
	for (int i=0; i<agendaArr.length; i++)
	{
		s = (String)agendaArr[i];			// (order::level::item::duration::owner)
		if (s == null) break;
		sa = s.split(meeting.DELIMITER);
		order = Integer.parseInt(sa[1]);
		level = Integer.parseInt(sa[2]);
		itemName = sa[3].replaceAll("@@", ":");
		duration = Integer.parseInt(sa[4]);
		idS = sa[5];

		// displace each item on a line
		width = 10 + 22 * level;
		order++;
		if (level == 0)
			levelInfo[level] = String.valueOf(order);
		else
			levelInfo[level] = levelInfo[level - 1] + "." + order;

		if (even) bgcolor = Prm.DARK;
		else bgcolor = Prm.LIGHT;
		even = !even;
		out.println("<tr " + bgcolor + ">");

		// -- list the item header no. and name
		out.print("<td colspan='2'><table border='0' cellspacing='0' cellpadding='2' width='100%'></tr>");
		out.print("<td class='plaintext' valign='top' width='" + width + "'><img src='../i/spacer.gif' width='" + width + "' height='2' border='0'></td>");
		out.print("<td class='plaintext' valign='top' width='3'>" + levelInfo[level] + "&nbsp;&nbsp;</td>");
		out.print("<td class='plaintext' valign='top'>" + itemName + "</td>");
		out.print("<td width='10'>&nbsp;</td>");
		out.println("</tr></table></td>");

		// -- duration time for each item
		out.print("<td colspan='3' class='plaintext' valign='top'>&nbsp;&nbsp;");
		hour = duration/60;
		if (hour > 0) out.print(hour + " hr ");
		min = duration%60;
		if (min == 0)
			out.print("-");
		else
			out.print(min + " min");
		out.print("</td>");

		// -- responsible person @ECC042507
		out.print("<td colspan='3' class='plaintext' valign='top'>&nbsp;&nbsp;");
		id = Integer.parseInt(idS);
		if (id > 0)
		{
			uname = "-";	// in case of trouble
			try {
				u = (user)uMgr.get(pstuser, id);
				uname = u.getFullName();
				if (uname.length() > 16) uname = (String)u.getAttribute("FirstName")[0] + " " + ((String)u.getAttribute("LastName")[0]).charAt(0) + ".";
			}
			catch (Exception e) {System.out.println("(mtg_live.jsp) got problem resolving agenda resp name: "+idS);}
			out.print("<a href='../ep/ep1.jsp?uid=" + idS + "' class='listlink'>" + uname + "</a>");
		}
		else if (id == meeting.iAGENDA_NONE)
			out.print("-");
		else if (id == meeting.iAGENDA_ALL)
			out.print("All");
		out.print("</td>");

		out.print("</td>");

		out.println("</tr>");
	}
%>
		</table>
<%} else {%>
	<td class="plaintext_grey">None
<%}%>
	</td>
</tr>
<!-- end Agenda -->
<tr><td colspan='3'>&nbsp;</td></tr>


<% if (isRun){%>
<!-- New file attachment -->
<tr>
	<td></td>
	<td class="plaintext" valign="top"><b>Add File Attachment:</b></td>
	<td class="formtext">
<%-- @AGQ032806 --%>
		<span id="inputs"><input id="my_file_element" type="file" class="button_browse" size="50" /></span><br /><br />
		Files to be uploaded:<br />
		<table><tbody id="files_list"></tbody></table>
		<script>
			var fileNumbers = 0;
			if(navigator.userAgent.indexOf("Firefox") != -1)
				fileNumbers = 1;
			var multi_selector = new MultiSelector( document.getElementById( 'files_list' ), fileNumbers, document.getElementById( 'my_file_element' ).className , document.getElementById( 'my_file_element' ).size );
			multi_selector.addElement( document.getElementById( 'my_file_element' ) );
		</script><br />
		<div id='uploadButton' style='display:none;'>
			<input type="submit" class="button_medium" name="add"
				value="&nbsp;&nbsp;Upload Files&nbsp;&nbsp;" onClick="javascript:return ajaxAddAT();"/>
		</div>
	</td>
</tr>
<tr>
	<td width="20">&nbsp;</td>
</tr>
<% } %>

<!-- list file attachments -->
<tr>
	<td width="20">&nbsp;</td>
	<td class="plaintext" valign="top"><b>File Attachment:<b></td>
	<td class="formtext">
<%-- @AGQ010506 --%>
		<span id="atObjTable">
		<table border="0" cellspacing="0" cellpadding="0" width='100%'>
<%
	// ECC: include link files
	Object [] attmtList = mtg.getAttribute("AttachmentID");
	int [] aids = Util2.toIntArray(attmtList);
	int [] linkIds = attMgr.findId(pstuser, "Link='" + midS + "'");		// @ECC103008
	aids = Util2.mergeIntArray(aids, linkIds);
	attachment attmtObj;
	String fileName;
	Date attmtCreateDt;
	if (aids.length <= 0)
	{%>
		<tr><td class="plaintext_grey">None</td></tr>
<%	}
	else
	{%>
	<tr>
	<td colspan="9" bgcolor="#EBECED" height="3"><img src="../i/spacer.gif" width="1" height="3" border="0"/></td>
	</tr>

	<tr>
	<td colspan="9" height="2" bgcolor="#336699"><img src="../i/spacer.gif" width="2" height="2"/></td>
	</tr>
	<tr>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="300" bgcolor="#6699cc" class="td_header"><strong>&nbsp;File Name</strong></td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"/></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="100" bgcolor="#6699cc" class="td_header"><strong>Owner</strong></td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"/></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="80" bgcolor="#6699cc" class="td_header" align="left"><strong>Posted On</strong></td>
	<td width="20" bgcolor="#6699cc" class="10ptype">&nbsp;</td>		<!-- delete button -->
	</tr>
<%
		Arrays.sort(aids);
		for (int i=0; i<aids.length; i++)
		{
			// list files by alphabetical order
			attmtObj = (attachment)attMgr.get(pstuser, aids[i]);
			uname = attmtObj.getOwnerDisplayName(pstuser);
			attmtCreateDt = (Date)attmtObj.getAttribute("CreatedDate")[0];
			fileName = attmtObj.getFileName();
%>
			<td>&nbsp;</td>
			<td class="plaintext" width="320">
				<a class="listlink" href="<%=host%>/servlet/ShowFile?attId=<%=aids[i]%>"><%=fileName%></a>
			</td>
			<td colspan='2'>&nbsp;</td>
			<td class="formtext"><a href="../ep/ep1.jsp?uid=<%=(String)attmtObj.getAttribute("Owner")[0]%>" class="listlink"><%=uname%></a></td>
			<td colspan='2'>&nbsp;</td>
			<td class="formtext"><%=df3.format(attmtCreateDt)%></td>
<%	if (isRun)
	{%>
	 		<td><input class="button_medium" type="button" value="Delete"
				onclick="javascript: ajaxDeleteAT('<%=aids[i]%>');" align="right" />
			</td>

<%	}
	else {out.print("<td></td>");}
		out.println("</tr>");
	}
	}		// @SWS061406 ends
// @AGQ010506
	out.println("</table></span></td>");
%>
</tr>
<!-- end file attachment -->

<%
	/////////////////////////////////////////
	// close meeting info panel
	out.print("</table></DIV>");	// END Info panel table
	out.print("</td></tr>");
%>


<tr><td colspan="3"><img src="../i/spacer.gif" width="5" height="10"/></td></tr>

<!-- add meeting notes -->

<tr>
	<td width='25'>&nbsp;<a name="minute" id="minute"></a><img src='../i/spacer.gif' width='25' height='30'/></td>
	<td colspan='2'>
	<span id='totalOnline'>
	<table border='0' cellspacing='0' cellpadding='0'>
		<tr>
			<td class="plaintext_blue" width='150'><b>Meeting Minutes:</b></td>
			<td class='plaintext'><%=MeetingParticipants.usersOnline(midS)%> online participants</td>
		</tr>
		<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>
		<tr>
			<td colspan='2'><table border='0' cellspacing='0' cellpadding='0'>
					<%=onlineStrBuf.toString()%>
				</table>
			</td>
		</tr>
	</table>
	</span>
	</td>
</tr>
<tr><td colspan="3"><img src="../i/spacer.gif" width="5" height="10"/></td></tr>

<tr>
	<td>&nbsp;</td>
	<td colspan="2">
	<table width="95%" border="0" cellspacing="0" cellpadding="0" align="center">
	<tr><td valign="top">
<!-- @AGQ120105 -->
<% String debugString = request.getParameter("debug");
   boolean debug = (debugString == null)?false:(new Boolean(debugString)).booleanValue();
   if (isRun){%>
		<div id='textDiv'>
		<textarea name="mtgText" id='mtgText'><%=Util.stringToHTMLStringFCK(bText)%></textarea>
		</div>
		<div align='right'>
		<!--span id='debugX'>debug</span-->
		<span id="handleBottom" ><img src='../i/drag.gif' style="cursor:s-resize;"/></span>
		<span><img src='../i/spacer.gif' width='20' height='1'/></span>
		</div>
		<span>&nbsp;</span>
<!-- @AGQ011206 -->
<% 		if(debug) {%>
			[<span onclick="javascript:xmlFile('GetNames');" style="cursor: pointer">FireFox: XML Names</span>]&nbsp;
			[<span onclick="javascript:init(1);" style="cursor: pointer">Live :</span> <span style="color: blue" id="refreshStatus">ON</span>]
			&nbsp;
<% 		} %>
		<span id="time"></span>
	<div align="center">
		<table border='0' cellspacing='0' cellpadding='0'>
		<tr>
		<td><input type="button" class="button_medium" onclick="javascript:manualSave();" id="saveMtgNotes" value="Save Meeting Notes"/></td>
<%	// @AGQ082206
		if (isInvInput) {
%>
			<%-- <td>&nbsp;<input type="Button" class="button_medium" onclick="javascript: inviteParti(true);" id="inviteInput" value="Invite Input"></td>
			&nbsp;<input type="Button" class="button_medium" onclick="javascript: alert('hurray');" id="chat" value="Chat">
			--%>
<%		}
	} else {%>
		<div class="scroll" style="height:300px;width:98%;font-size:13px;" id="meetingNotes"><%=bText%></div>
		<div align='right'>
		<!--span id='debugX'>debug</span-->
		<span id="handleBottom" ><img src='../i/drag.gif' style="cursor:s-resize;"/></span>
		<span><img src='../i/spacer.gif' width='20' height='1'/></span>
		</div>
<%-- @AGQ011206 --%>
<% 	if (debug) { %>
		[<span onclick="javascript:xmlFile('LiveMtg');" style="cursor: pointer">FireFox: XML Msg</span>]&nbsp;
		[<span onclick="javascript:init(0);" style="cursor: pointer">Live</span> <span style="color: blue" id="refreshStatus">ON</span>]
		&nbsp;
<% 	} %>
		<span id="time"></span>
<%-- @AGQ082406 --%>
		<div>&nbsp;</div>
		<div align="center" id="feedback" style="display: none">
			<table cellpadding="0" cellspacing="0" border="0"><tr>
			<td><textarea cols="60" rows="2" id="fbText" onkeyup="return onEnterSubmitFeedback(event);"></textarea></td>
			<td valign="top">&nbsp;<input type="button" class="button_medium" value=" Send " onclick="ajaxMFCSubmit(); document.getElementById('fbText').focus();"/></td>
			</tr></table>
		</div>
		<span id="timeLeft"></span>
<%
		out.println("<div align='center'>");
		out.println("<table border='0' cellspacing='0' cellpadding='0'><tr>");
		if (isRunPart) {

			out.println("<td><input type='button' class='button_medium' onclick='javascript:manualSave();' id='saveMtgNotes' value='Save Meeting Notes' disabled='disabled'></td>");
			if (isInvInput) {
				//out.println("<td>&nbsp;<input type='button' class='button_medium' onclick='javascript: inviteParti(false);' id='inviteInput' value='Stop Input'></td>");
				//out.println("&nbsp;<input type='button' class='button_medium' onclick='window.scrollTo(0, 0); scrolling()' id='chat' value='Chat'>");
			}
		}
	} %>

<!-- @ECC092806 Send Expression -->
			<td><img src='../i/spacer.gif' width='30'/></td>
			<td>
				<select id="expression" name="expression" class="formtext">
					<option value="">- Select Expression -</option>
					<option value="hello">Hello</option>
					<option value="cool">Cool!</option>
					<option value="ques">Question</option>
					<option value="hand">Raise hand</option>
					<option value="thank">Thank you</option>
					<option value="yes">Yes</option>
					<option value="no">No</option>
					<option value="maybe">Maybe</option>
				</select>
			</td>
			<td>
			<input type='button' class='button_medium' onclick='javascript: sendExpr("<%=pstuser.getObjectName()%>");' id='sendExprButn' value='Send'>
			</td>
			</tr></table>
			</div>
	</div>

	</td>

	<td><img src='../i/spacer.gif' width='5'></td>

<!-- @ECC101106 INPUT QUEUE Begin-->
	<td valign='top' width='85'>
	<span id='InputQTable'>
	<table width='100%' border='0' cellspacing='0' cellpadding='0'>
<%
	// get the input queue elements and display them
	String inQ = MeetingParticipants.getAllOnQueue(midS);

	int len = 0;
	sa = null;
	if (inQ != null)
	{
		sa = inQ.split(":");
		len = sa.length;
	}
	int nxt = 0;

	// check to see if there is an input person on the queue
	if (len>0 && sa[0].length()>0 && sa[0].charAt(0)=='*')
	{
		// input person found
		nxt = 1;
	}
	out.print("<tr><td class='plaintext_blue' align='center' colspan='3'>");
	out.print("<b>Input<br>Queue</b></td></tr>");

	out.print("<tr><td colspan='3'><img src='../i/spacer.gif' height='15'></td></tr>");

	if (isFacilitator)
	{
		if (len-nxt>0 && sa[nxt].length()>0)
		{
			// show users in queue
			String dispName;
			for (int i=nxt; i<len; i++)
			{
				if ((idx=sa[i].indexOf('@')) != -1)
					dispName = sa[i].substring(0, idx);
				else
					dispName = sa[i];
				out.print("<tr><td class='plaintext'>[</td>");
				out.print("<td width='80' align='center' title='Click to enable only this person to enter input'>");
				out.print("<a href='javascript:enableInputQHead(\""
						+ midS + "\", 1, \"" + sa[i] + "\");' class='listlink'>" + dispName + "</a></td>");
				out.print("<td class='plaintext'>]</td></tr>");
			}

			// @ECC110806
			// after showing all queuing users' name, add buttons for All People and All of the Above
			out.print("<tr><td colspan='3'>&nbsp;</td></tr>");

			// all of above
			out.print("<tr><td class='plaintext'>[</td>");
			out.print("<td width='80' align='center' title='Click to enable all of the above users in the queue to enter input'>");
			out.print("<a href='javascript:enableInputQHead(\"" + midS + "\", 2);' class='listlink'><b>All Above</b></a></td>");
			out.print("<td class='plaintext'>]</td></tr>");
		}

		// all users: may press to include all newly sign-in users
		out.print("<tr><td class='plaintext'>[</td>");
		out.print("<td width='80' align='center' title='Click to enable all online participants to enter input'>");
		out.print("<a href='javascript:enableInputQHead(\"" + midS + "\", 3);' class='listlink'><b>All&nbsp;&nbsp;Users</b></a></td>");
		out.print("<td class='plaintext'>]</td></tr>");

		if (MeetingParticipants.isOn(midS))
		{
			// allow to STOP input
			out.print("<tr><td class='plaintext'>[</td>");
			out.print("<td width='80' align='center' title='Click to END all participants from entering input'>");
			out.print("<a href='javascript:enableInputQHead(\"" + midS + "\", 0, \"all\");' class='listlink'><font color='dd0000'><b>Stop</b></font></a></td>");
			out.print("<td class='plaintext'>]</td></tr>");
		}
	}
	else
	{
		String myObjName = pstuser.getObjectName();
		boolean foundSelf = false;
		for (int i=nxt; i<len; i++)
		{
			if (sa[i].length() <= 0) break;
			out.print("<tr><td class='plaintext'>[</td>");
			out.print("<td width='80' align='center' ");
			if (myObjName.equals(sa[i]))
			{
				// this is my name on the queue
				foundSelf = true;
				out.print("title='Click to remove yourself from the queue'>");
				out.print("<a href='javascript:sendInputQueue(\""
						+ myObjName + "\", \"remove\");' class='listlink'>" + sa[i] + "</a></td>");
			}
			else
			{
				out.print("class='plaintext'>" + sa[i] + "</td>");
			}
			out.print("<td class='plaintext'>]</td></tr>");
		}
		if (!foundSelf && len < OmfQueue.MAX_INPUT_QUEUE_NUM)
		{
			out.print("<tr><td class='plaintext'>[</td>");
			out.print("<td class='listlink' width='80' align='center'><a href='javascript:sendInputQueue(\""
					+ myObjName + "\");'><b>Enter</b></a></td>");
			out.print("<td class='plaintext'>]</td></tr>");
		}
	}

%>
	</table>
	</span>

	</td>
<!-- @ECC101106 INPUT QUEUE End-->

	</tr>
	</table>
	</td>
</tr>
<!-- End of add meeting notes -->

<tr><td colspan='3'>&nbsp;<a name="action"></a></td></tr>


<tr><td colspan="3"><img src="../i/spacer.gif" width="5" height="10"></td></tr>

<!-- //////////////////////////////////////////////////// -->
<!-- Add Action Items / Decisions / Issues -->
<%
	String desc = (String)session.getAttribute("action");
	if (desc != null)
		session.removeAttribute("action");
	else
		desc = "";
	Object [] responsibleIds = new Object[0];
	String acExpireS = df3.format(new Date().getTime() + 604800000);	// give it one week by default

if (isRun)
{
	String type = request.getParameter("type");
	if (type == null) type = action.TYPE_ACTION;

	String prio = request.getParameter("prio");
	if (prio == null) prio = bug.PRI_MED;


	////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////
	// panel for action/decision
	out.print("<tr><td colspan='3'>");
	out.print(Util.getHeaderPartitionLine());
	out.print("<img id='ImgActionPanel' src='../i/bullet_tri.gif'/>");
	out.print("<a id='AActionPanel' href='javascript:togglePanel(\"ActionPanel\", \"Show action / decision\", \"Hide action / decision\");' class='listlinkbold'>Hide action / decision</a>");
	
	out.print("<DIV id='DivActionPanel' style='display:block;'>");
	out.print("<table border='0' cellspacing='0' cellpadding='0' width='100%'>");	// Action panel table
%>


<tr><td colspan='3'><img src='../i/spacer.gif' width='5' height='10'></td></tr>

<tr>
	<td width='30'><img src='../i/spacer.gif' width='30'/></td>
	<td class="plaintext"><b>Type:</b></td>
	<td><table border='0' cellpadding='0' cellspacing='0'><tr>
	<td class="plaintext" width="315">
		<input type="radio" id="TypeAction" name="Type" value="<%=action.TYPE_ACTION%>" onClick="isAction();" <%if (type.equals(action.TYPE_ACTION)) out.print("checked");%>> Action
		<input type="radio" id="TypeDecision" name="Type" value="<%=action.TYPE_DECISION%>" onClick="isDecision();" <%if (type.equals(action.TYPE_DECISION)) out.print("checked");%>> Decision
<%	if (isCtModule) { %>
		<input type="radio" id="TypeIssue" name="Type" value="Issue" onClick="isIssue();" <%if (type.equals("Issue")) out.print("checked");%>> Issue
<%	} %>
	</td>

	<td class="plaintext" width='80'><b>Priority:</b>&nbsp;</td>
	<td>
			<select id='Priority' class='formtext' name='Priority'>
				<option value='<%=bug.PRI_HIGH%>' <%if (prio.equals(bug.PRI_HIGH)) out.print("selected");%>><%=bug.PRI_HIGH%></option>
				<option value='<%=bug.PRI_MED%>'  <%if (prio.equals(bug.PRI_MED)) out.print("selected");%>><%=bug.PRI_MED%></option>
				<option value='<%=bug.PRI_LOW%>'  <%if (prio.equals(bug.PRI_LOW)) out.print("selected");%>><%=bug.PRI_LOW%></option>
			</select>
	</td>
	</tr></table></td>
</tr>

<!-- Description -->
<tr>
	<td>&nbsp;</td>
	<td class="plaintext" valign="top"><b>Description:</b></td>
	<td><table border='0' cellpadding='0' cellspacing='0' width='85%'>
		<tr><td>
		<textarea id="Description" type="text" name="Description"
			style='width:100%;'
			rows="4" value="<%=desc%>" onkeyup="return onEnterSubmitAC(event);"></textarea>
		</td></tr>
		<tr><td class="plaintext" align="right" style="color: green">chars remaining: <span id="charCount" style="color:green;">255</span></td>
		</tr></table>
	</td>
</tr>

<tr><td colspan='3'><img src='../i/spacer.gif' width='5' height='3'></td></tr>

<%
	if (!isOMFAPP) {
%>
<!-- LINK to project name & Issue/Bug -->
<tr>
	<td>&nbsp;</td>
	<td class="plaintext" valign="top"><b>Project Name:</b></td>
<%-- @AGQ052306 --%>
	<td><table border='0' cellpadding='0' cellspacing='0'><tr>

<!-- project name -->
	<td class="plaintext" width='315'>
<%
	// @AGQ011006
	out.println("<select id='pjNames' class='formtext' name='projId' onChange='javascript:changeAcProject();'>");
	out.println("<option value=''>- select project name -</option>");

	int [] projectObjId = pjMgr.getProjects(pstuser);
	if (projectObjId.length > 0)
	{
		PstAbstractObject [] projectObjList = pjMgr.get(pstuser, projectObjId);
		//@041906SSI
		Util.sortName(projectObjList, true);

		project pj;
		String pName;
		Date expDate;
		String expDateS = new String();
		for (int i=0; i < projectObjList.length ; i++)
		{
			// project
			pj = (project) projectObjList[i];
			pName = pj.getDisplayName();
			id = pj.getObjectId();

			out.print("<option value='" + id +"' ");
			if (id == selectedPjId)
				out.print("selected");
			out.print(">" + pName + "</option>");
		}
	}
	out.println("</select>");
	out.print("</td>");
	
	if (isPRMAPP && isCtModule)
	{
%>
<!-- related issue/bug -->
	<td class="plaintext" width='80'><b>Issue / PR:</b>&nbsp;</td>
	<td>
		<select id="ibNames" class='formtext' name='BugId'>
			<option value=''>- select issue/PR ID -</option>
<%			for (int i=0; i<bIds.length; i++)
			{
				out.print("<option value='" + bIds[i] + "'>" + bIds[i] + "</option>");
			}
%>
		</select>
	</td>
<%	}	// END if isPRMAPP %>

	</tr></table></td>
</tr>
<%	}
	// @AGQ082106
	else {
		out.println("<tr style='display: none;'><td colspan='3'>");
		out.println("<select id='pjNames'  name='projId'>");
		out.println("<option value=''></option>");
		out.println("</select>");
		out.println("<select id='ibNames' name='BugId'>");
		out.println("<option value=''></option>");
		out.println("</select>");
		out.println("</td></tr>");
	}
%>

<tr><td colspan="3"><img src="../i/spacer.gif" height="15"></td></tr>

<!-- Responsible -->
<tr>
	<td>&nbsp;</td>
	<td valign="top" class="plaintext"><b>Responsible:</b></td>
	<td>
<%
	// projMember will be on the left while alertEmp will be on the right
	String [] fName = new String [responsibleIds.length];
	String [] lName = new String [responsibleIds.length];
	if (responsibleIds.length>0 && responsibleIds[0]!=null)
	for (int i = 0; i < responsibleIds.length; i++)
	{
		id = Integer.parseInt((String)responsibleIds[i]);
		for (int j = 0; j < projMember.length; j++)
		{
			if (projMember[j] == null) continue;
			if (projMember[j].getObjectId() == id)
			{
				fName[i] = (String)projMember[j].getAttribute("FirstName")[0];
				lName[i] = (String)projMember[j].getAttribute("LastName")[0];
				if (lName[i]==null) lName[i] = "";
				projMember[j] = null;
				break;
			}
		}
	}
%>
		<table border="0" cellspacing="0" cellpadding="0">
		<tr>
			<td class="formtext">
			<select id="rsNames" class="formtext_fix" name="Selected" multiple size="5">
<%
	if (projMember != null && projMember.length > 0)
	{
		for (int i=0; i < projMember.length; i++)
		{
			if (projMember[i] == null) continue;
			uName = ((user)projMember[i]).getFullName();
			out.println("<option value='" +projMember[i].getObjectId()+ "'>&nbsp;" +uName+ "</option>");
		}
	}
%>
			</select>
			</td>

			<td>&nbsp;&nbsp;&nbsp;</td>
			<td align="center" valign="middle">
				<input type="Button" class="button" name="add" value="&nbsp;&nbsp;&nbsp;&nbsp;Add &gt;&gt;&nbsp;&nbsp;" onClick="swapdata(this.form.Selected,this.form.Responsible)"><br>
				<input type="Button" class="button" name="remove" value="<< Remove" onClick="swapdata(this.form.Responsible,this.form.Selected)">
			</td>
			<td>&nbsp;&nbsp;&nbsp;</td>

<!-- people selected -->
			<td class="formtext">
				<select id="Responsible" class="formtext_fix" name="Responsible" multiple size="5">
<%
	if (responsibleIds.length>0 && responsibleIds[0]!=null)
	{
		for (int i=0; i < responsibleIds.length; i++)
		{
			out.println("<option value='" +responsibleIds[i]+ "'>&nbsp;" +fName[i]+ "&nbsp;" +lName[i]+ "</option>");
		}
	}
%>
				</select>
			</td>
		</tr>
		</table>

</td>
</tr>
<!-- End of Responsible -->

<tr><td colspan="3"><img src="../i/spacer.gif" height="15"></td></tr>

<!-- Action Item Coordinator -->
<tr>
	<td>&nbsp;</td>
	<td class="plaintext"><b>Coordinator:</b></td>
	<td>
		<select id="acNames" class="formtext" type="text" name="Owner">
<%
		for (int i=0; i<projMember.length; i++)
		{
			if (projMember[i] == null) continue;
			id = projMember[i].getObjectId();
			uName = ((user)projMember[i]).getFullName();
			out.print("<option value='" + id + "'");
			if (id==myUid) out.print(" selected");
			out.println(">&nbsp;" +uName+ "</option>");
		}
%>
		</select>
	</td>
</tr>

<tr><td colspan="3"><img src="../i/spacer.gif" height="10"></td></tr>

<!-- Done By -->
<tr>
	<td>&nbsp;</td>
	<td class="plaintext"><b>Done By:</b></td>
	<td>
		<input id="Expire" class="formtext" type="Text" name="Expire" size="25" onClick="javascript:show_calendar('updMeeting.Expire');"
			onKeyDown='return false;' value='<%=acExpireS%>'>
		&nbsp;<a href="javascript:popup_cal();"><img src="../i/calendar.gif" border="0" align="absmiddle" title="Click to view calendar."></a>
	</td>
</tr>

<tr><td colspan="3"><img src="../i/spacer.gif" height="10"></td></tr>

<script type="text/javascript">
<!--
	selectType('<%=type%>');	// Need to enable/disable widgets based on type: action/decision/issue
//-->
</script>
<tr>
	<td>&nbsp;</td>
	<td colspan="2">
	</td>
</tr>
<tr>
	<td>&nbsp;</td>
	<td colspan="2">
	<p align="center">
		<input type="Button" value="  Reset  " class="button_medium" onclick="resetAC();">&nbsp;
		<input type="Button" value="Add Item" id="addItem" class="button_medium" onclick="javascript:if(validationAC() != false) ajaxSubmitAC();">
	</p>
	</td>
</tr>

</form>
<!-- //////////////////////////////////////////////////// -->

<%}	// End if (isRun) %>

<!-- LIST OF ACTION / DECISION / ISSUE -->

<form method="post" name="updateAction" action="post_updaction.jsp">
<input type="hidden" name="mid" value="<%=midS%>">
<input type="hidden" name="run" value="true">
<input type="hidden" name="oid">
<input type="hidden" name="pid">
<input type="hidden" name="type">
<input type="hidden" name="mtext">

<%
	// for Action Item, Decision Records and Issues
	int counterAC = 0;
	// get the list of action items
	ids = aMgr.findId(pstuser, "(MeetingID='" + midS + "') && (Type='" + action.TYPE_ACTION + "')");
	Arrays.sort(ids);
	PstAbstractObject [] aiObjList = aMgr.get(pstuser, ids);
	
	// decisions
	ids = aMgr.findId(pstuser, "(MeetingID='" + midS + "') && (Type='" + action.TYPE_DECISION + "')");
	Arrays.sort(ids);
	PstAbstractObject [] dsObjList = aMgr.get(pstuser, ids);

	// issues
	ids = bMgr.findId(pstuser, "MeetingID='" + midS + "'");
	Arrays.sort(ids);
	PstAbstractObject [] bgObjList = bMgr.get(pstuser, ids);

	// variables
	String bugIdS, priority, dot;
	user uObj;
	int aid;
	Object [] respA;
	Date expireDate, createdDate;
	action obj;
%>
<tr>
	<td>&nbsp;</td>
	<td colspan="2" align="right">
	<span id="deleteTop">
<%
	if (isRun && aiObjList.length>0)
	{
		out.print("<a href='javascript:ajaxDeleteAC()' class='listlinkbold'>>> Delete&nbsp;</a>");
	}
%>
	</span>
	</td>
</tr>


<!-- List of Action Items -->
<tr>
	<td>&nbsp;</td>
	<td colspan="2" width="100%">
		<span id="aiObjTable">

<%
		int [] counterArr = new int[1];
		counterArr[0] = counterAC;
		String aiStr = PrmMeeting.displayActionItems(aiObjList, pstuser, true, midS, counterArr);
		out.print(aiStr);
		counterAC = counterArr[0];


		out.print("</span></td></tr>");

		if (aiObjList.length>0) out.print("<tr><td colspan='3'><img src='../i/spacer.gif' width='5' height='5'></td></tr>");
%>
<!-- End list of action items -->


<!-- List of Decision Records -->
<tr>
	<td>&nbsp;</td>
	<td colspan='2'>
		<span id='dsObjTable'>

<%
if (dsObjList.length > 0) {
	
	if (isOMFAPP)
		out.print(Util.showLabel(PrmMtgConstants.label1OMF, PrmMtgConstants.labelLen1OMF, isRun));
	else if (isPRMAPP)
		out.print(Util.showLabel(PrmMtgConstants.label1, PrmMtgConstants.labelLen1, isRun));
	else
		out.print(Util.showLabel(PrmMtgConstants.label1CR, PrmMtgConstants.labelLen1CR, isRun));	// CR-OMF

	even = false;

	for (int i = 0; i < dsObjList.length; i++)
	{	// the list of decision records for this meeting object
		obj = (action)dsObjList[i];
		aid = obj.getObjectId();

		subject		= (String)obj.getAttribute("Subject")[0];
		priority	= (String)obj.getAttribute("Priority")[0];
		createdDate	= (Date)obj.getAttribute("CreatedDate")[0];
		projIdS		= (String)obj.getAttribute("ProjectID")[0];
		bugIdS		= (String)obj.getAttribute("BugID")[0];

		if (even)
			bgcolor = Prm.DARK;
		else
			bgcolor = Prm.LIGHT;
		even = !even;
		out.print("<tr " + bgcolor + ">");

		// Subject
		out.print("<td>&nbsp;</td>");
		out.print("<td valign='top'><table border='0'><tr>");
		out.print("<td class='plaintext' valign='top'>" + (i+1) + ". </td>");
		out.print("<td class='plaintext' valign='top'>");
		if (isRun)
			out.print("<a href='javascript:editAC(\""
				+ aid + "\", \"Decision\")'>" + subject + "</a>");
		else
			out.print(subject);
		out.println("</td></tr></table></td>");

		// Priority {HIGH, MEDIUM, LOW}
		dot = "../i/";
		if (priority.equals(action.PRI_HIGH)) {dot += "dot_red.gif";}
		else if (priority.equals(action.PRI_MED)) {dot += "dot_orange.gif";}
		else if (priority.equals(action.PRI_LOW)) {dot += "dot_yellow.gif";}
		else {dot += "dot_grey.gif";}
		out.print("<td colspan='3' class='listlink' align='center' valign='top'>");
		out.print("<img src='" + dot + "' title='" + priority + "'>");
		out.println("</td>");

		// @ECC041006 support blogging in action/decision/issue
		ids = rMgr.findId(pstuser, "TaskID='" + aid + "'");
		out.print("<td colspan='2'>&nbsp;</td>");
		out.print("<td class='listtext' width='30' valign='top' align='center'>");
		out.print("<a class='listlink' href='../blog/blog_task.jsp?projId=" + projIdS + "&aid=" + aid + "'>");
		out.print(ids.length + "</a>");
		out.println("</td>");

		if (!isOMFAPP) {
			// Project id
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td class='listtext' width='40' valign='top' align='center'>");
			if (projIdS != null)
			{
				out.print("<a class='listlink' href='../project/proj_action.jsp?projId=" + projIdS + "&aid=" + aid + "'>");
				out.print(projIdS + "</a>");
			}
			else
				out.print("-");
			out.println("</td>");

			if (isPRMAPP)
			{
				// Bug id
				out.print("<td colspan='2'>&nbsp;</td>");
				out.print("<td class='listtext' width='40' valign='top' align='center'>");
				if (bugIdS != null)
				{
					out.print("<a class='listlink' href='../bug/bug_update.jsp?bugId=" + bugIdS + "'>");
					out.print(bugIdS + "</a>");
				}
				else
					out.print("-");
				out.println("</td>");
			}
		}

		// CreatedDate
		out.print("<td colspan='2'>&nbsp;</td>");
		out.print("<td class='listtext_small' width='50' align='center' valign='top'>");
		out.print(df1.format(createdDate));
		out.println("</td>");

		// delete
		if (isRun)
		{
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td width='35' class='plaintext' align='center'>");
			out.print("<input id='ckbox" + counterAC + "' type='checkbox' name='delete_" + aid + "'></td>");
			counterAC++;
		}

		out.println("</tr>");
		out.println("<tr " + bgcolor + ">" + "<td colspan='20'><img src='../i/spacer.gif' width='2' height='2'></td></tr>");
	}
	out.print("</table>");
}	// END: if there is any decision

	out.print("</span></td></tr>");
	if (dsObjList.length > 0) out.print("<tr><td colspan='3'><img src='../i/spacer.gif' width='5' height='5'></td></tr>");

%>
<!-- End list of decision records -->


<%
	if (isCtModule) {
%>
<!-- List of Issues -->
<tr>
	<td>&nbsp;</td>
	<td colspan="2">
		<span id="bgObjTable">

<%
if (bgObjList.length > 0) {
	out.print(Util.showLabel(PrmMtgConstants.label2, PrmMtgConstants.labelLen2, isRun));

	even = false;

	bug bObj;

	for(int i = 0; i < bgObjList.length; i++)
	{	// the list of issues for this meeting object
		bObj = (bug)bgObjList[i];
		aid = bObj.getObjectId();

		subject		= (String)bObj.getAttribute("Synopsis")[0];
		priority	= (String)bObj.getAttribute("Priority")[0];
		createdDate	= (Date)bObj.getAttribute("CreatedDate")[0];
		projIdS		= (String)bObj.getAttribute("ProjectID")[0];
		ownerIdS	= (String)bObj.getAttribute("Creator")[0];

		if (even)
			bgcolor = Prm.DARK;
		else
			bgcolor = Prm.LIGHT;
		even = !even;
		out.print("<tr " + bgcolor + ">");

		// Subject
		out.print("<td>&nbsp;</td>");
		out.print("<td valign='top'><table border='0'><tr>");
		out.print("<td class='plaintext' valign='top'>" + (i+1) + ". </td>");
		out.print("<td class='plaintext' valign='top'>");
		if (isRun)
			out.print("<a href='javascript:editAC(\""
				+ aid + "\", \"Issue\")'>" + subject + "</a>");
		else
			out.print(subject);
		out.println("</td></tr></table></td>");

		// Submitter
		uObj = (user)uMgr.get(pstuser, Integer.parseInt(ownerIdS));
		out.print("<td colspan='2'>&nbsp;</td>");
		out.print("<td class='listtext' valign='top'>");
		out.print("<a class='listlink' href='../ep/ep1.jsp?uid=" + ownerIdS + "'>");
		out.print((String)uObj.getAttribute("FirstName")[0] + " " + ((String)uObj.getAttribute("LastName")[0]).charAt(0) + ".");
		out.print("</a>");
		out.print("</td>");

		// Priority {HIGH, MEDIUM, LOW}
		dot = "../i/";
		if (priority.equals(bug.PRI_HIGH)) {dot += "dot_red.gif";}
		else if (priority.equals(bug.PRI_MED)) {dot += "dot_orange.gif";}
		else if (priority.equals(bug.PRI_LOW)) {dot += "dot_yellow.gif";}
		else {dot += "dot_grey.gif";}
		out.print("<td colspan='3' class='listlink' align='center' valign='top'>");
		out.print("<img src='" + dot + "' title='" + priority + "'>");
		out.println("</td>");

		// @ECC041006 support blogging in action/decision/issue
		ids = rMgr.findId(pstuser, "TaskID='" + aid + "'");
		out.print("<td colspan='2'>&nbsp;</td>");
		out.print("<td class='listtext' width='30' valign='top' align='center'>");
		out.print("<a class='listlink' href='../blog/blog_task.jsp?projId=" + projIdS + "&bugId=" + aid + "'>");
		out.print(ids.length + "</a>");
		out.println("</td>");

		// Project id
		out.print("<td colspan='2'>&nbsp;</td>");
		out.print("<td class='listtext' width='40' valign='top' align='center'>");
		if (projIdS != null)
		{
			out.print("<a class='listlink' href='../project/proj_action.jsp?projId=" + projIdS + "&aid=" + aid + "'>");
			out.print(projIdS + "</a>");
		}
		else
			out.print("-");
		out.println("</td>");

		// My id
		out.print("<td colspan='2'>&nbsp;</td>");
		out.print("<td class='listtext' width='40' valign='top' align='center'>");
		out.print(aid + "</td>");

		// CreatedDate
		out.print("<td colspan='2'>&nbsp;</td>");
		out.print("<td class='listtext_small' width='50' align='center' valign='top'>");
		out.print(df1.format(createdDate));
		out.println("</td>");

		// delete
		if (isRun)
		{
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td width='35' class='plaintext' align='center'>");
			out.print("<input id='ckbox" + counterAC + "' type='checkbox' name='delete_" + aid + "'></td>");
			counterAC++;
		}

		out.println("</tr>");
		out.println("<tr " + bgcolor + ">" + "<td colspan='23'><img src='../i/spacer.gif' width='2' height='2'></td></tr>");
	}
	out.print("</table>");
}		// END if there is any issue



		out.print("</span></td></tr>");
		//<!-- End list of issues -->
	}

	else {
		out.println("<tr style='display: none'><td colspan='3'><span id='bgObjTable'></span></td></tr>");
	}

%>
<tr>
	<td>&nbsp;</td>
	<td colspan="2">
	<table width="100%" border='0' cellspacing='0' cellpadding='0'>
	<tr>
		<td class="tinytype" width="250">
	<%	if (aiStr.length() > 0) {out.print("<font color='#555555'>(* Action item coordinator)</font>");}%>
		</td>
		<td align="right">
		<span id="deleteBottom">

	<%	if (isRun && (aiStr.length()>0 || dsObjList.length>0 || bgObjList.length>0)) {%>
			<a href="javascript:ajaxDeleteAC()" class="listlinkbold">>> Delete&nbsp;</a>
	<%	}%>
		</span>
		</td>
	</tr>
	</table>
	</td>
</tr>

</form>

<%	if (aiStr.length()>0 || dsObjList.length>0 || bgObjList.length>0) {%>
<tr>
	<td>&nbsp;</td>
	<td colspan="2" class="tinytype">Priority:
		&nbsp;&nbsp;<img src="../i/dot_red.gif" border="0"><%=action.PRI_HIGH%>
		&nbsp;&nbsp;<img src="../i/dot_orange.gif" border="0"><%=action.PRI_MED%>
		&nbsp;&nbsp;<img src="../i/dot_yellow.gif" border="0"><%=action.PRI_LOW%>
	</td>
</tr>
<%	} %>

<!-- END LIST OF ACTION / DECISION / ISSUE -->
<%
	/////////////////////////////////////////
	// close action panel
	out.print("</table></DIV>");	// END Action panel table
	out.print("</td></tr>");


	////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////
	// panel for meeting blog
	out.print("<tr><td colspan='3'>");
	out.print(Util.getHeaderPartitionLine());
	out.print("<img id='ImgBlogPanel' src='../i/bullet_tri.gif'/>");
	out.print("<a id='ABlogPanel' href='javascript:togglePanel(\"BlogPanel\", \"Show meeting blog\", \"Hide meeting blog\");' class='listlinkbold'>Hide meeting blog</a>");
	
	out.print("<DIV id='DivBlogPanel' style='display:block;'>");
	out.print("<table border='0' cellspacing='0' cellpadding='0' width='100%'>");	// Blog panel table
%>

<tr><td><img src='../i/spacer.gif' width='1' height='20'/></tr>

<!-- @ECC071907 Meeting Blog -->
<%
	String blogHTML = Util2.displayBlog(pstuser, midS, result.TYPE_MTG_BLOG);
%>
<tr>
	<td width='30'><img src='../i/spacer.gif' width='30'/></td>
	<td width='150' class="plaintext" valign="top"><b>Meeting Blogs:</b></td>
	<td><table cellspacing='0' cellpadding='0' width='100%'>
	<tr>
		<td>
			<%if (StringUtil.isNullOrEmptyString(blogHTML)) out.print("<span class='plaintext_grey'>None</span>");%>
		</td>
		<td width='300'>
			<img src='../i/bullet_tri.gif' width='20' height='10'>
			<a class='listlinkbold' href='../blog/addblog.jsp?type=<%out.print(result.TYPE_MTG_BLOG + "&id=" + midS);%>'>New Blog Posting</a>
		</td>
	</tr>
	</table>
	</td>
</tr>

<%
	// list the meeting blogs
	out.println(blogHTML);


	/////////////////////////////////////////
	// close blog panel
	out.print("</table></DIV>");	// END Blog panel table
	out.print("</td></tr>");
%>

<tr><td colspan='3'>&nbsp;</td></tr>

<%
	// only people involved in this meeting will come to this page
	if (isRun)
	{
		out.print("<tr><td colspan='3' class='formtext'>");
		out.print("<table cellspacing='0' cellpadding='0' width='100%'>");
		out.print("<tr><td>&nbsp;</td><td width='300'>");
		out.print("<img src='../i/bullet_tri.gif'>");
		out.print("<a href='javascript:document.updMeeting.submit()' onClick='javascript: return goAdjourn();' class='listlinkbold'>Meeting Adjourn</a>");
		out.print("</td></tr></table>");

		out.print("</td></tr>");
	}
%>

</table>
</td>
</tr>

<tr>
	<td>
		<!-- div class="scroll" style="height: 150px;" id="debug"></div -->
		<!-- Footer -->
		<jsp:include page="../foot.jsp" flush="true"/>
		<!-- End of Footer -->
	</td>
</tr>

</table>

<jsp:include page="expr.jsp" flush="true"/>

</body>
</html>
