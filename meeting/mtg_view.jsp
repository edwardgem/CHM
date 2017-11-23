<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2005, EGI Technologies, Co.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: mtg_view.jsp
//	Author: ECC
//	Date:	02/24/05
//	Description: Display a meeting.
//	Modification:
//			@ECC041006	Add blog support to action/decision/issue.
//			@SWS061406	Updated file listing.
//			@AGQ081506	Changed Recorder -> Facilitator
//			@AGQ081606	Block user from entering private meetings
//			@AGQ090606	Removed Proj ID and Bug ID from listings of Action/Decision
//			@AGQ090606a	Display guest emails
//			@AGQ090606b	Allow direct access to live meeting
//			@AGQ091406	Handle reserve keyword to automatically accept meeting.
//			@ECC101006	Support guest to participate and view Public meetings
//			@ECC102706	Support company employees to see all company meetings.  Use TownID to match.
//			@ECC042507	Allow NONE or ALL to be responsible for an agenda item.
//			@ECC062807	Authorize multiple people to update meeting record.
//			@ECC071907	Put meeting blog at the bottom of this page.  Copy from help.jsp.
//			@ECC111708	Add RoboMail option.
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "util.*" %>
<%@ page import = "mod.mfchat.MeetingParticipants" %>
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
<%@ page import = "org.apache.log4j.Logger" %>

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	String midS = request.getParameter("mid");
	String aIdS = request.getParameter("aid");
	String noSession = "../out.jsp?go=meeting/mtg_view.jsp?mid="+midS+":aid="+aIdS;
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>

<%
	final int RADIO_NUM = 4;
	final int MAX_LINES = 4;

	if (/*(pstuser instanceof PstGuest) ||*/ (midS == null))
	{
		response.sendRedirect("../out.jsp?e=Access denied");
		return;
	}

	Logger l = PrmLog.getLog();
	String host = Util.getPropKey("pst", "PRM_HOST");
	String fbHost = host.contains(".com")? host : "http://cpm.egiomm.com";

	boolean isGuest = false;
	boolean isNotLogin = false;
	if (session == null) session = request.getSession(true);
	PstUserAbstractObject pstuser = (PstUserAbstractObject)session.getAttribute("pstuser");
	if (pstuser == null || pstuser instanceof PstGuest)
	{
		isGuest = isNotLogin = true;
		pstuser = PstGuest.getInstance();
		session.setAttribute("pstuser", pstuser);
	}

	int selectedAId = 0;
	if (aIdS!=null && !aIdS.equals("null"))
		selectedAId = Integer.parseInt(aIdS);

	int myUid = pstuser.getObjectId();
	String myUidS = Integer.toString(myUid);

	boolean bShowAllRecipient = (request.getParameter("showAll") != null);

	
	Integer io = (Integer)session.getAttribute("role");
	int iRole = 0;
	if (io != null) iRole = io.intValue();
	
	boolean isAdmin = (iRole & user.iROLE_ADMIN) > 0;
	boolean isProgMgr = (iRole & user.iROLE_PROGMGR) > 0;

	// to check if session is OMF or PRM or CR-OMF
	boolean isOMFAPPonly = Prm.isMeetWE();
	boolean isPRMAPP = Prm.isPRM();
	String app = Prm.getApp();
	String metaS;
	if (Prm.isMeetWE()) {
		metaS = "MeetWE is a social network for you and your friends to meet and share fun and useful information";
	}
	else {
		metaS = "EGI CPM is a platform solution to enable collaboration of a global community for innovation and fun";
	}
	
	userManager uMgr = userManager.getInstance();
	actionManager aMgr = actionManager.getInstance();
	meetingManager mMgr = meetingManager.getInstance();
	bugManager bMgr = bugManager.getInstance();
	resultManager rMgr = resultManager.getInstance();
	attachmentManager attMgr = attachmentManager.getInstance();
	questManager qMgr = questManager.getInstance();
	projectManager pjMgr = projectManager.getInstance();
	userinfoManager uiMgr = userinfoManager.getInstance();
	confManager cfMgr = confManager.getInstance();
	townManager tnMgr = townManager.getInstance();
	
	meeting mtg = null;
	try{
	mtg = (meeting)mMgr.get(pstuser, midS);}
	catch (PmpException e) {
		response.sendRedirect("../out.jsp?e=The meeting has been removed from the database .");
		return;
	}
	
	String s;
	
	// support facebook?
	s = Util.getPropKey("pst", "NO_FACEBOOK");
	boolean bNoFacebook = (s==null || s.equalsIgnoreCase("false"));

	// check for click coming from facebook
	s = request.getParameter("fb");
	boolean isFromFaceBook = (s!=null && s.equals("1"));
		
	// @ECC111708 check RoboMail call
	s = request.getParameter("robo");
	if (s!=null) {
		// construct an XML message based on the value of the object
		Util3.sendRoboMail(pstuser, mMgr, midS);
	}
	
	userinfo myUI = (userinfo) uiMgr.get(pstuser, String.valueOf(myUid));
	
	// @AGQ081606
	String meetingType = (String) mtg.getAttribute(meeting.TYPE)[0];
	if (meetingType == null) {
		l.error("Meeting TYPE information dissappeared (" + midS + ")"); // This should not happen
		meetingType = meeting.PRIVATE;
	}
	else if (meetingType.equals(meeting.PRIVATE) && isGuest && !isFromFaceBook) {
		//response.sendRedirect("../out.jsp?e=Sorry, this is a Private Meeting, you must login to access it.");
		response.sendRedirect(noSession + "&e=time out"
				+ "&msg=Sorry, this is a Private Meeting, you must login to access it.");
		return;
	}
	boolean isPublicMeeting  = meetingType.equals(meeting.PUBLIC);
	boolean isPrivateMeeting = meetingType.equalsIgnoreCase(meeting.PRIVATE);
	boolean isPublicReadURL  = meetingType.equals(meeting.PUBLIC_READ_URL);
	
	// @ECC102706
	Object [] myTownIds = null;
	if (!isGuest)
		myTownIds = pstuser.getAttribute("Towns");
	String myTownString = StringUtil.toString(myTownIds, ";");
	
	String mtgProjId = (String)mtg.getAttribute("ProjectID")[0];
	String mtgTownId = (String)mtg.getAttribute("TownID")[0];
	project mtgProjObj = null;

	// get attendee list
	Object [] attendeeArr = mtg.getAttribute("Attendee");
	String myAttStatus="";
	ArrayList<String> mandatoryIds = new ArrayList<String>();
	ArrayList<String> mandatorySts = new ArrayList<String>();
	ArrayList<String> optionalIds = new ArrayList<String>();
	ArrayList<String> optionalSts = new ArrayList<String>();
	String reserve = request.getParameter("reserve");
	String [] sa = null;
	
	for (int i=0; i<attendeeArr.length; i++)
	{
		s = (String)attendeeArr[i];
		if (s == null) break;
		sa = s.split(meeting.DELIMITER);
		int aId = 0;
		try {aId = Integer.parseInt(sa[0]);}
		catch (Exception e) {continue;}
		if (aId == myUid)
			myAttStatus = sa[1];

		// @AGQ091406
		if (reserve != null && reserve.length() > 0 && aId == myUid) {
			// find out what reserve contains
			mtg.removeAttribute(meeting.ATTENDEE, myUid + meeting.DELIMITER + myAttStatus);				
			if (myAttStatus.contains(meeting.ATT_MANDATORY)) {
				myAttStatus = meeting.ATT_MANDATORY + meeting.ATT_ACCEPT;
				mandatoryIds.add(String.valueOf(myUid));
				mandatorySts.add(myAttStatus);
			}
			else {
				myAttStatus = meeting.ATT_OPTIONAL + meeting.ATT_ACCEPT;
				optionalIds.add(String.valueOf(myUid));
				optionalSts.add(myAttStatus);
			}
			mtg.appendAttribute(meeting.ATTENDEE, myUid + meeting.DELIMITER + myAttStatus);
			mMgr.commit(mtg);
		}
		else {
			if (sa[1].startsWith(meeting.ATT_MANDATORY))
			{
				mandatoryIds.add(sa[0]);
				mandatorySts.add(sa[1]);
			}
			else
			{
				optionalIds.add(sa[0]);
				optionalSts.add(sa[1]);
			}
		}
	}

	// Guest attendees
	StringBuffer guestEmails = new StringBuffer();
	Object [] objArr = mtg.getAttribute(meeting.GUESTEMAILS);
	if (objArr[0] != null) {
		for (int i=0;i<objArr.length;i++) { 
			guestEmails.append(objArr[i]);
			if (i != objArr.length-1) {
				 guestEmails.append(", ");
			}
		}
	}

	// check to see if I am an invitee/attendee
	String myEmail = "";
	if (!isGuest) {
		myEmail = (String) pstuser.getAttribute("Email")[0];
	}
	
	String ownerIdS = (String)mtg.getAttribute("Owner")[0];
	int ownerId = 0;
	if (ownerIdS != null)		// should not be null but somehow there was this bug appeared at once
		ownerId = Integer.parseInt(ownerIdS);
	boolean isOwner = (ownerId==myUid);

	boolean iAmInvited = mandatoryIds.contains(myUidS) || optionalIds.contains(myUidS)
							|| guestEmails.toString().toLowerCase().contains(myEmail);

	if (!(isAdmin || isProgMgr)
			&& isPrivateMeeting && !iAmInvited)
	{
		// private meeting only allow attendees to access
		boolean found = false;
		if (mtgTownId == null) {
			// personal meeting
			if ( !myUidS.equals(mtg.getAttribute("Owner"))) {
				// only attendees can access
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
				if (!found && !isFromFaceBook) {
					// don't show this meeting
					response.sendRedirect("../out.jsp?e=Sorry, this is a Private/Personal Meeting - access denied");
					return;
				}
			}
		}	// END: if TownID==null
		

		// meeting has a TownID
		else {
			// company meeting: either same company or same project can access
			if (!myTownString.contains(mtgTownId)) {
				// not same company: check project
				if (mtgProjId != null) {
					mtgProjObj = (project)pjMgr.get(pstuser, Integer.parseInt(mtgProjId));
					String projTeam = StringUtil.toString(mtgProjObj.getAttribute("TeamMembers"), ";");
					if (!projTeam.contains(myUidS)) {
						isGuest = true;
						if (!isFromFaceBook) {
							response.sendRedirect("../out.jsp?e=Sorry, this is a Private Project Meeting - access denied");
							return;
						}
					}
				}
		
				else {
					isGuest = true;
					if (!isFromFaceBook) {
						response.sendRedirect("../out.jsp?e=Sorry, this is a Private Company Meeting - access denied");
						return;
					}
				}
			}	// END: if NOT same company
			
			// same company: if Private meeting, then check attendee/owner
			else if (isPrivateMeeting && !isOwner && !iAmInvited) {
				response.sendRedirect("../out.jsp?e=Sorry, this is a Private Meeting - access denied");
				return;
			}
		}
	}

	String status = (String)mtg.getAttribute("Status")[0];
	String subject = (String)mtg.getAttribute("Subject")[0];
	
	String locationName = (String)mtg.getAttribute("Location")[0];
	if (locationName != null) {
		try {
			PstAbstractObject confRm = cfMgr.get(pstuser, locationName);
			locationName = confRm.getStringAttribute("Name");
		}
		catch (PmpException e) {}	// might be an Other string, not conf room
	}
	
	String recurring = (String)mtg.getAttribute("Recurring")[0];

	// check to see if there is recurring event
	boolean bHasRecur = false;
	if (recurring != null)
	{
		sa = recurring.split(meeting.DELIMITER);
		if (sa.length>=2 && (Integer.parseInt(sa[1])>0))
			bHasRecur = true;
	}

	
	String ownerName;
	try {
		user ou = (user)uMgr.get(pstuser, ownerId);
		//ownerName = (String)ou.getAttribute("FirstName")[0] + " " + (String)ou.getAttribute("LastName")[0];
		ownerName = ou.getFullName();
	} catch (PmpObjectNotFoundException e) {
		ownerName = "User is Removed";
		l.error("Owner: " + ownerId + " not found in meeting: " + midS);
	}

	// authorize to update minute/action items?
	boolean canUpdate = false;
	int recorderId = 0;
	s = (String)mtg.getAttribute("Recorder")[0];
	if (s!=null) recorderId = Integer.parseInt(s);

	if (ownerId==myUid || recorderId==myUid)
		canUpdate = true;
	else
	{
		// @ECC062807 authorized multiple people to update meeting record and actions
		objArr = mtg.getAttribute("Responsible");
		for (int i=0; i<objArr.length; i++)
		{
			s = (String)objArr[i];
			if (s == null) break;
			if (Integer.parseInt(s) == myUid)
			{
				canUpdate = true;
				break;
			}
		}
	}

	int onlineCt = MeetingParticipants.usersOnline(midS);
	if (onlineCt < 30 || (myUid == recorderId)) {
		//	 @AGQ090606b Since meeting has start directly sent them into meeting
		if (status.equals(meeting.LIVE)) {
			StringBuffer url = new StringBuffer();
			url.append("mtg_live.jsp?mid="+midS);
			if (myUid == recorderId)
				url.append("&run=true");
			response.sendRedirect(url.toString());
			return;
		}	
	}
	
	// @ECC101706 keep ViewNum statistics
	boolean isSilence = true;
	int viewNum = 0;
	Object o = mtg.getAttribute("ViewBlogNum")[0];
	if (o != null) viewNum = ((Integer)o).intValue();
	if (!isAdmin && request.getParameter("refresh")==null && request.getParameter("rf")==null)
	{
		isSilence = false;
		mtg.setAttribute("ViewBlogNum", new Integer(++viewNum));
		try {mMgr.commit(mtg);} catch (PmpException e) {}
	}
	
	Date start = (Date)mtg.getAttribute("StartDate")[0];
	Date expire = (Date)mtg.getAttribute("ExpireDate")[0];
	Date adjourn = (Date)mtg.getAttribute("CompleteDate")[0];
	Date actual = (Date)mtg.getAttribute("EffectiveDate")[0];
	SimpleDateFormat df1 = new SimpleDateFormat ("MM/dd/yy");
	SimpleDateFormat df3 = new SimpleDateFormat ("MM/dd/yyyy");
	SimpleDateFormat df4 = new SimpleDateFormat ("MM/dd/yy (E) hh:mm a");
	SimpleDateFormat df5 = new SimpleDateFormat ("hh:mm a");
	
	userinfo.setTimeZone(pstuser, df1);
	userinfo.setTimeZone(pstuser, df3);
	userinfo.setTimeZone(pstuser, df4);
	userinfo.setTimeZone(pstuser, df5);

	String mtgLength = "";
	if (actual!=null && adjourn!=null)
	{
		long d = adjourn.getTime() - actual.getTime();
		int hr = 0;
		int min = (int)((d+1)/60000);
		if (min >= 60)
		{
			hr = min/60;
			min = min%60;
			mtgLength = "(" + hr + " hr " + min + " min)";
		}
		else
		{
			if (min == 0) min = 1;
			mtgLength = "(" + min + " min)";
		}
	}

	// check for expired meeting
	//Date now = new Date(new Date().getTime() - userinfo.getServerUTCdiff());
	Date now = new Date();
	if (status.equals(meeting.NEW))
	{
		if (now.after(expire))
		{
			// the meeting has expired
			mtg.setAttribute("Status", meeting.EXPIRE);
			mMgr.commit(mtg);
			response.sendRedirect("mtg_view.jsp?mid="+midS+"&rf=1");
			return;
		}
	}
	
	// my attending status
	if (myAttStatus=="" && ownerId==myUid)
		myAttStatus = meeting.ATT_ACCEPT;		// I am coordinator, consider accept
	
	if (reserve != null && reserve.length() > 0 && myAttStatus.length() == 0) {
		myAttStatus = meeting.ATT_OPTIONAL + meeting.ATT_ACCEPT;
		optionalIds.add(String.valueOf(myUid));
		optionalSts.add(myAttStatus);
		mtg.appendAttribute(meeting.ATTENDEE, myUid + meeting.DELIMITER + myAttStatus);
		mMgr.commit(mtg);
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
			} catch (Exception e) {
				return 0;}
		}
	});

	// get the blog text - meeting notes
	Object bTextObj = mtg.getAttribute("Note")[0];
	String bText = (bTextObj==null)?"":new String((byte[])bTextObj, "utf-8");

	// trigger iEVT_MTG_VIEW event
	if (!isSilence)
	{
		// I know this looks funny, but the loading of expr.jsp cause mtg_view.jsp to load twice
		if (session.getAttribute("dummy")==null && !isGuest)
		{
			PrmEvent.createTriggerEvent(pstuser, PrmEvent.EVT_MTG_VIEW, midS, mtgTownId, null);
			session.setAttribute("dummy", new Object());
		}
		else
			session.removeAttribute("dummy");
	}
	
	// need to refresh the screen?
	boolean bNeedRefreshScreen = false;
	long diffFromMtgStart = 0;	// + meeting.SERVER_UTC_DIFF;
	int minFromMtgStart = 0;
	if (status.equals(meeting.NEW)) {
		diffFromMtgStart = start.getTime() - now.getTime();
		minFromMtgStart = (int)(diffFromMtgStart/60000);
		if (minFromMtgStart<5)
			bNeedRefreshScreen = true;	// within -5, 5 min. of meeting start time
	}
%>

<head>
<%if (bNeedRefreshScreen) {%>
<meta http-equiv='Refresh' content='60; url=mtg_view.jsp?mid=<%=midS%>&rf=1'/>
<%}%>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>

<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<script language="JavaScript" src="../date.js"></script>
<script language="JavaScript" src="mtg_expr2.js"></script>
<script language="JavaScript" src="mtg_expr.js"></script>
<jsp:include page="../init.jsp" flush="true"/>
<script language="JavaScript" src="../util.js"></script>

<script type="text/javascript" language="javascript">
<!--
window.onload = function()
{
	if ("<%=status%>" == "<%=meeting.NEW%>")
		togglePanel("InfoPanel", null, "Hide meeting info");
}
var postMsg='nothing';

function delMeeting()
{
	var delRecur = 'false';
	if ('<%=bHasRecur%>' == 'true')
	{
		var msg = "Do you want to delete the recurring events of this meeting ";
		msg += "or only this instance of the meeting?\n\n";
		msg += "   OK = delete ALL recurring events after this\n";
		msg += "   CANCEL = delete only this instance";
		if (confirm(msg))
		{
			delRecur = 'true';
		}
	}
	if (!confirm("This action is non-recoverable. Do you really want to delete the meeting?"))
		return;
	location = "post_mtg_del.jsp?mid=<%=midS%>&delRecur=" + delRecur;
}

function goLive()
{
	// ask if the user really want to be the facilitator to run the meeting
	//c = confirm("Do you want to START the meeting? Click OK only if you want to start the meeting as the FACILITATOR of the meeting.  Click CANCEL if you want to JOIN the meeting as a participant.");
	<%-- @AGQ081506 --%>
<%
	if (ownerId==myUid) {%>	
		c = true;
<%	} else if (isPublicMeeting || isPublicReadURL) {%>	
		c = false;
<%	} else {%>
		c = confirm("Do you want to START the meeting?\n\n   OK = START the meeting as the FACILITATOR\n   CANCEL = JOIN the meeting as a participant");
<%	} %>
	if (c)
		location = "mtg_live.jsp?mid=<%=midS%>&run=true";
	else
		location = "mtg_wait.jsp?mid=<%=midS%>";	// auto refresh page to wait for meeting start
}

function editAC(id, type)
{
	updAction.type.value = type;
	updAction.oid.value = id;

	updAction.submit();
}

function roboMail()
{
	var fullURL = parent.document.URL;
	if (fullURL.indexOf("robo") == -1)
		fullURL += "&robo=1";
	location = fullURL;
	return;
}

function postQuickBlog()
{
	var f = document.quickBlogForm;
	if (trim(f.logText.value) == "")
	{
		f.logText.value = "";
		f.logText.focus();
		return false;
	}

	f.SubButton.disabled=true;
	return true;
}

//-->
</script>

<title><%=Prm.getAppTitle()%> <%=subject%></title>
<meta name="description" content="<%=metaS%>" />

<style type="text/css">
.plaintext {line-height:20px;}
#bubbleDIV {position:relative;z-index:1;left:0em;top:0em;width:3em;height:3em;vertical-align:bottom;text-align:center;}
img#bg {position:relative;z-index:-1;top:-2em;width:3em;height:3em;border:0;}
</style>

</head>

<body bgcolor="#FFFFFF" style="margin:0px;">
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
		</table>
	</td>
</tr>
</table>
		
<table width='90%' border='0' cellspacing='0' cellpadding='0'>
			<tr>
	          <td>
	            <table width="100%" border="0" cellspacing="0" cellpadding="0">
				  <tr>
					<td width="26" height="30"><a name="top">&nbsp;</a></td>
                	<td height="30" align="left" valign="bottom" class="head">
                	<b>View Meeting</b>
					</td>
					<td class="formtext" width='300'>
<%
	// only people involved in this meeting will come to this page
	boolean isOver = false;
	if (status.equals(meeting.NEW) && !isPublicMeeting)
	{
		if ((myAttStatus=="" && !isPublicMeeting) && !isAdmin)
		{
			// I am not on the attendee list.  Do nothing
		}
		else if (minFromMtgStart <= 15)
		{
			// if 15 min before meeting start, allow START MEETING
			if ((isPublicMeeting || isPublicReadURL) && ownerId!=myUid)
				s = "Join Meeting";
			else
				s = "Start Meeting";
			out.print("<img src='../i/bullet_tri.gif' width='20' height='10'>");
			out.println("<a class='listlinkbold' href='#' onClick='return goLive()'><font color='#dd0000'>" + s + "</font></a>");
		}
		else if (myAttStatus.endsWith(meeting.ATT_ACCEPT))
		{
			ResourceBundle filebundleFile = ResourceBundle.getBundle("pst");
			String vcsURL = filebundleFile.getString("URL_CAL_FILE_PATH") + File.separator + midS + ".vcs";

			out.println("You have accepted the meeting");
			out.print("<div><img src='../i/bullet_tri.gif' width='20' height='10'>");
			out.print("<a class='listlinkbold' href='" +vcsURL+ "'>Save Meeting to Outlook</a><br>");
			out.print("<img src='../i/bullet_tri.gif' width='20' height='10'>");
			out.print("<a class='listlinkbold' href='post_mtg_resp.jsp?mid=" +midS+ "&Response=" +meeting.ATT_DECLINE+ "'>Decline Meeting</a>");
		}
		else if (myAttStatus.endsWith(meeting.ATT_DECLINE))
		{
			out.println("You have declined the meeting<br>");
			out.print("<img src='../i/bullet_tri.gif' width='20' height='10'>");
			out.print("<a class='listlinkbold' href='post_mtg_resp.jsp?mid=" +midS+ "&Response=" +meeting.ATT_ACCEPT+ "'>Accept Meeting</a>");
		}
		else
		{
			// got to be not responded yet
			out.print("<img src='../i/bullet_tri.gif' width='20' height='10'>");
			out.print("<a class='listlinkbold' href='post_mtg_resp.jsp?mid=" +midS+ "&Response=" +meeting.ATT_ACCEPT+ "'>Accept Meeting</a>");
			out.print("<br><img src='../i/bullet_tri.gif' width='20' height='10'>");
			out.print("<a class='listlinkbold' href='post_mtg_resp.jsp?mid=" +midS+ "&Response=" +meeting.ATT_DECLINE+ "'>Decline Meeting</a>");
		}
	}
	else if (status.equals(meeting.LIVE))
	{
		out.println("<b>The meeting is in progress</b><br>");
		// @AGQ091906
		if (onlineCt >= 30) {
			out.print("<b>Meeting is Full: " + onlineCt + "/30 people online</b>");
		}
		else {
			out.print("<img src='../i/bullet_tri.gif' width='20' height='10'>");
			out.print("<a class='listlinkbold' href='mtg_live.jsp?mid=" +midS);
			if (myUid == recorderId)
				out.print("&run=true'>Back to Meeting</a>");
			else
				out.print("'>Join Meeting</a>");
		}
	}
	else if (status.equals(meeting.FINISH))
	{
		out.println("<font color='#aa0000'><b>The meeting is adjourned</b></font>");
		isOver = true;
	}
	else if (status.equals(meeting.COMMIT))
		out.println("<b>The meeting is closed</b>");
	else if (status.equals(meeting.ABORT) || status.equals(meeting.EXPIRE))
		out.println("The meeting is over");
%>
					</td>
					</tr>
	            </table>
	          </td>
	        </tr>
			<tr>
				<td width="100%">
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

<table width="90%" border="0" cellspacing="0" cellpadding="0">
<tr><td><img src="../i/spacer.gif" height="10"/></td></tr>

<!-- Grouping table: group subject, location, start, end, owner into a table to share with links -->
<tr><td colspan='3'>
<table width='100%' border='0' cellspacing="0" cellpadding="0">
<tr>

<!-- left side -->
<td>
<table width='100%' border='0' cellspacing="0" cellpadding="0">

<!-- Subject -->
<tr>
	<td width='30'><img src="../i/spacer.gif" width="30" height="1"/></td>
	<td width="180" class="plaintext" valign='top'><b>Subject
<%
		s = Util2.getUserPreference(pstuser, "RoboMail");
		if (s != null) {
			out.print("<a href='javascript:roboMail();'><img src='../i/export.jpg' border='0' /></a>");
		}
%>
	:</b></td>
	<td class="plaintext"><b><%=subject%></b></td>
</tr>

<!-- Project -->
<%
if (!isOMFAPPonly)
{
	if (mtgProjObj != null)
	{
		s = mtgProjObj.getDisplayName();
		s = "<a href='../project/proj_top.jsp?projId=" + mtgProjId + "'>" + s + "</a>";
%>
<tr>
	<td ></td>
	<td width="180" class="plaintext" valign='top'><b>Project:</b></td>
	<td class="plaintext"><%=s%></td>
</tr>
<%	}
}%>

<!-- Location -->
<%	if (locationName != null)
	{%>
<tr>
	<td></td>
	<td class="plaintext"><b>Location:</b></td>
	<td class="plaintext"><%=locationName%></td>
</tr>
<%	} %>

<!-- Meeting time -->
<tr>
	<td></td>
	<td class="plaintext" valign="top"><b>Meeting Schedule:</b></td>
	<td class="plaintext"><%=df4.format(start)%> - <%=df5.format(expire)%>
			<br>&nbsp;&nbsp;(<%=myUI.getZoneString()%>)


<%
	// prev and next meeting
	int [] ids;
	String nextMeetingIdS = null;
	if (recurring != null)
	{
		sa = recurring.split(meeting.DELIMITER);
		s = sa[0];
		if (s.equals(meeting.DAILY_NOWKEN))
			s = meeting.DAILY;
		out.print("&nbsp;&nbsp;&nbsp;(" + s + " event");
		int num = Integer.parseInt(sa[1]);
		if (num > 0)
			out.print(" for <b>" + (num+1) + "</b> occurrences)<br>");
		else
			out.print(")<br>");
	}
	
	// prev
	boolean hasPrev = false;
	ids = mMgr.findId(pstuser, "Recurring='%" + midS + "%'");
	if (ids.length > 0)
	{
		hasPrev = true;
		if (recurring == null) out.print("<br>");
		out.print("&nbsp;&nbsp;<a class='plaintext_big' href='mtg_view.jsp?mid=" + ids[0] + "&rf=1'><< Prev Meeting</a>");
	}

	// next
	if (recurring != null)
	{
		if (sa.length >=3 && sa[2]!=null)
		{
			nextMeetingIdS = sa[sa.length-1];
			if (!nextMeetingIdS.contains(";") && Integer.parseInt(nextMeetingIdS)>1000)
			{
				out.print("&nbsp;&nbsp;");
				if (hasPrev) out.print("| &nbsp;&nbsp;");
				out.print("<a class='plaintext_big' href='mtg_view.jsp?mid=" + nextMeetingIdS + "&rf=1'>Next Meeting >></a>");
			}
		}
	}
%>
	</td>
</tr>


</table></td>
<!-- end left side -->

<!-- right side: LINKS /////////////////////////////////////////////// -->
<td width='300' valign='top'>
	<table height='100%'>
<%
	boolean canUpdateAction = false;
	String backPage = "../meeting/mtg_view.jsp?mid=" + midS+"&rf=1";
	if (status.equals(meeting.NEW))
	{
		out.print("<tr><td class='formtext' valign='top'>");
		out.print("<img src='../i/bullet_tri.gif' width='20' height='10'>");
		out.print("<a class='listlinkbold' href='mtg_update1.jsp?mid=" +midS+ "'>Update Meeting</a>");
		out.print("</td></tr>");
	}
	if (isAdmin || (myUid==ownerId && (!status.equals(meeting.LIVE))) ) //&& !status.equals(meeting.FINISH) && !status.equals(meeting.COMMIT))))
	{
		out.print("<tr><td class='formtext' valign='top'>");
		out.print("<img src='../i/bullet_tri.gif' width='20' height='10'>");
		out.print("<a class='listlinkbold' href='#' onclick='return delMeeting();'>Delete Meeting</a>");
		out.print("</td></tr>");
	}
	if ((isAdmin || canUpdate) && (status.equals(meeting.FINISH) || status.equals(meeting.EXPIRE)) )
	{
		out.print("<tr><td class='formtext' valign='bottom'>");
		out.print("<img src='../i/bullet_tri.gif' width='20' height='10'>");
		out.print("<a class='listlinkbold' href='mtg_update2.jsp?mid="
			+ midS+ "'>Update Meeting Record</a>");
		out.print("</td></tr>");
		canUpdateAction = true;
	}

	if (!isNotLogin && (status.equals(meeting.FINISH) || status.equals(meeting.COMMIT)) )
	{
		out.print("<tr><td class='formtext' valign='bottom'>");
		out.print("<img src='../i/bullet_tri.gif' width='20' height='10'>");
		out.print("<a class='listlinkbold' href='../blog/addalert.jsp?type=meeting&list=-3&id=" +midS+ "&backPage=" + backPage +"'>Send Meeting Record</a>");
		out.print("</td></tr>");

	}
	
	int [] blogIds = rMgr.findId(pstuser, "Type='" + result.TYPE_MTG_BLOG + "' && TaskID='" + midS + "'");

	if (isAdmin || ( canUpdate /*&& !status.equals(meeting.NEW)*/ && !status.equals(meeting.LIVE) ) )
	{
		out.print("<tr><td class='formtext' valign='bottom'>");
		out.print("<img src='../i/bullet_tri.gif' width='20' height='10'>");
		out.print("<a class='listlinkbold' href='mtg_new1.jsp?mid=" +midS+ "'>Create Follow-up Meeting</a>");
		out.print("</td></tr>");
	}
	
	// check to see if there is a quest for this meeting, if not, allow create
	ids = qMgr.findId(pstuser, "MeetingID='" + midS + "'");
	if (ids.length <= 0)
	{
		if (isAdmin || (canUpdate && status.equals(meeting.NEW)))
		{
			out.print("<tr><td class='formtext' valign='bottom'>");
			out.print("<img src='../i/bullet_tri.gif' width='20' height='10'>");
			out.print("<a class='listlinkbold' href='../question/q_new1.jsp?mid=" +midS+ "'>Create Questionnaire/Survey</a>");
			out.print("</td></tr>");
		}
	}
	else
	{
		// there is a quest associated to this meeting
		out.print("<tr><td class='formtext' valign='bottom'>");
		out.print("<img src='../i/bullet_tri.gif' width='20' height='10'>");
		out.print("<a class='listlinkbold' href='../question/q_respond.jsp?qid=" +ids[0]+ "'>Goto Questionnaire/Survey</a>");
		out.print("</td></tr>");
	}
	if (status.equals(meeting.NEW))
	{
		out.print("<tr><td class='formtext' valign='top'>");
		out.print("<img src='../i/bullet_tri.gif' width='20' height='10'>");
		out.print("<a class='listlinkbold' href='../blog/addalert.jsp?type=meeting&list=-3&id=" +midS+ "&backPage=" + backPage +"'>Send Meeting Invite</a>");
		out.print("</td></tr>");
	}
%>

	</table>
</td>
<!-- end right side -->

</tr></table>
</td></tr>
<!-- end Grouping table -->

<!-- @ECC110206 Description -->
<%
	bTextObj = mtg.getAttribute("Description")[0];
	String descStr = (bTextObj==null)?null : new String((byte[])bTextObj, "utf-8");
	if (descStr != null)
	{%>
<tr><td colspan='3'><table width='100%' cellspacing='0' cellpadding='0'>
<tr>
	<td width='30'><img src='../i/spacer.gif' width='30' height='1'/></td>
	<td width='180' class='plaintext' valign='top'><b>Description:</b></td>
	<td class='plaintext'><%=descStr%></td>
</tr>
</table></td></tr>
<%	}
	
	// PST config tag NO_FACEBOOK to enable/disable Facebook features
	if (!bNoFacebook) {
%>
<!-- Facebook likes -->
<!-- appId=213394358683288 -->
<tr>
	<td width='30'><img src='../i/spacer.gif' width='30' height='40'/></td>
	<td colspan='2' align='left'>
	<div id="fb-root"></div><script src="http://connect.facebook.net/en_US/all.js#appId=213394358683288&amp;xfbml=1"></script>
		<fb:like href="<%=fbHost%>/meeting/mtg_view.jsp?mid=<%=midS%>&fb=1" send="true" width="450" show_faces="true" font="arial"></fb:like>
	</td>
</tr>
<%
	}	// Facebook Likes link
	
	
if (isPublicMeeting || isPublicReadURL || !isGuest) {

	
	
	////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////
	// panel for meeting info
	out.print("<tr><td colspan='3'>");
	out.print(Util.getHeaderPartitionLine());
	out.print("<img id='ImgInfoPanel' src='../i/bullet_tri.gif'/>");
	out.print("<a id='AInfoPanel' href='javascript:togglePanel(\"InfoPanel\", \"Meeting info\", \"Hide meeting info\");' class='listlinkbold'>Meeting info</a>");
	
	out.print("<DIV id='DivInfoPanel' style='display:none;'>");
	out.print("<table border='0' cellspacing='0' cellpadding='0' width='100%'>");	// Info panel table


	out.print("<tr><td><img src='../i/spacer.gif' height='5'/></td></tr>");

	// Meeting Actual Time
	if ((status.equals(meeting.FINISH) || status.equals(meeting.COMMIT)) && adjourn!=null)
	{
%>
<tr>
	<td width='30'><img src='../i/spacer.gif' width='30' height='1'></td>
	<td width='180' class="plaintext"><b>Actual Meeting:</b></td>
	<td class="plaintext"><%=df4.format(actual)%> - <%=df5.format(adjourn)%>
	</td>
</tr>
<%	}%>

<!-- Owner -->
<tr>
	<td></td>
	<td class="plaintext"><b>Coordinator:</b></td>
	<td class="plaintext">
		<a href="../ep/ep1.jsp?uid=<%=ownerId%>" class="listlink">
		<%=ownerName%></a>
	</td>
</tr>

<!-- Recorder -->
<%
	String uname;
	user u;
	if (recorderId != 0)
	{
		try {
			u = (user)uMgr.get(pstuser, recorderId);
			//uname = (String)u.getAttribute("FirstName")[0] + " " + (String)u.getAttribute("LastName")[0];
			uname = u.getFullName();
		} catch (PmpObjectNotFoundException e) {
			uname = "User is Removed";
			l.error("Facilitator: " + recorderId + " not found in meeting: " + midS);
		}
%>
<tr>
	<td ></td>
	<td class="plaintext"><b>Facilitator:</b></td>
	<td class="plaintext">
		<a href="../ep/ep1.jsp?uid=<%=recorderId%>" class="listlink">
		<%=uname%></a>
	</td>
</tr>
<%	}%>

<!-- Type -->
<%
	if (meetingType.equals(meeting.PRIVATE))
	{
		meetingType += " / ";		// Private / EGI
	}
	else if (meetingType.equals(meeting.PUBLIC_READ_URL)) {
		meetingType = "Public read-only (by invitation)";
	}
	else if (meetingType.equals(meeting.PUBLIC) && mtgTownId!=null) {
		meetingType += " / ";
	}
	/*else if (meetingType.equals(meeting.COMPANY)) {
		meetingType = "Company Meeting / ";
	}*/

	if (meetingType.endsWith(" / ")) {
		// add company name
		if (mtgTownId != null)
		{
			String townName = tnMgr.get(pstuser, Integer.parseInt(mtgTownId)).getStringAttribute("Name");
			if (!isPRMAPP)
				meetingType += "<a href='../ep/my_page.jsp?uid=" + s + "' class='listlink'>"
					+ townName + "</a>";
			else
				meetingType += townName;
		}
		else
			meetingType += "Personal";
	}
	//if (s == null) s = meetingType;
%>
<tr>
	<td width='30'><img src='../i/spacer.gif' width='30' height='1'></td>
	<td width='180' class="plaintext"><b>Type:</b></td>
	<td class="plaintext">
		<%=meetingType %>&nbsp;&nbsp;&nbsp;(Views: <%=viewNum%>)
	</td>
</tr>

<!-- Rating -->
<%
//if (isPublicMeeting)
//{
	int votes = ((Integer)mtg.getAttribute("VoteNum")[0]).intValue();
	int totalRating = ((Integer)mtg.getAttribute("Rating")[0]).intValue();	
	double rating = -1;
	if (votes > 0) rating = ((double)totalRating)/votes;
	String lnk = "../meeting/mtg_view.jsp?mid=" + midS+":rf=1";
%>
<tr>
	<td><img src='../i/spacer.gif' width='30' height='1'></td>
	<td width='180' class='plaintext' valign='top'><b>Rating:</b></td>
	<td class='plaintext'>
		<jsp:include page="../info/rating.jsp" flush="true">
		<jsp:param name="ratingS" value="<%=rating%>" />
		<jsp:param name="votes" value="<%=votes%>" />
		<jsp:param name="id" value="<%=midS%>" />
		<jsp:param name="uid" value="<%=myUid%>" />
		<jsp:param name="app" value="<%=app%>" />
		<jsp:param name="backPage" value="<%=lnk%>" />
		</jsp:include>
	</td>
</tr>
<%//}	// if isPublicMeeting%>

<!-- Attendee (Mandatory & Optional) -->

<%
	String bgcolor="";
	boolean even = false;
	String idS, stS;
	int num;
	int lineCt;

	// set up different status lists
	ArrayList posList = new ArrayList();		// present or accept
	ArrayList negList = new ArrayList();		// not present or decline
	ArrayList neuList = new ArrayList();		// only before mtg finish: waiting for response

	ArrayList idList = mandatoryIds;
	ArrayList stList = mandatorySts;

if (!isGuest && !isPublicMeeting) {
	// show attendee list only for non-guest

	for (int z=0; z<2; z++)
	{
		// do this for both mandatory and option list.
		// first time is mandatory list, second time is optional list
		out.print("<tr><td width='20'><img src='../i/spacer.gif' width='20' height='1'></td>");
		out.print("<td colspan='2' class='plaintext' valign='top'><b>");
		if (z == 1)
			out.print("Optional ");
		out.print("Attendee:</b></td></tr>");

		if (status.equals(meeting.FINISH) || status.equals(meeting.COMMIT) || status.equals(meeting.LIVE))
		{
			// only present (+ve) or absent (-ve)
			for (int i=0; i<idList.size(); i++)
			{
				idS = (String)idList.get(i);
				stS = (String)stList.get(i);
				try {u = (user)uMgr.get(pstuser, Integer.parseInt(idS));}
				catch (PmpException e) {System.out.println("***** Error: failed to get user " + idS); continue;}
				if (stS.endsWith(meeting.ATT_PRESENT))
					posList.add(u);
				else
					negList.add(u);
			}

			// list all present names
			num = 0;
			lineCt = 0;
			if (posList.size() > 0) {
				out.print("<tr><td width='30'><img src='../i/spacer.gif' width='30' height='1'></td>");
				out.print("<td width='180' class='plaintext' valign='top'><font color='#22aa22'>&nbsp;&nbsp;&nbsp;<b>Present</b></font></td>");
				out.print("<td>");
				out.print("<table border='0' cellspacing='0' cellpadding='0' width='100%'>");
	
				Util.sortUserList(posList);
				for(int i = 0; i < posList.size(); i++)
				{
					if (!bShowAllRecipient && lineCt>=MAX_LINES) break;
					u = (user)posList.get(i);
					//uname = (String)u.getAttribute("FirstName")[0];
					uname = u.getFullName();
					if (uname == null) continue;
					//uname = uname + " " + (String)u.getAttribute("LastName")[0];
					//if (uname.length() > 18) uname = (String)u.getAttribute("FirstName")[0] + " " + ((String)u.getAttribute("LastName")[0]).charAt(0) + ".";
	
					if (num%RADIO_NUM == 0) out.print("<tr>");
					out.print("<td width='150' class='plaintext'>");
					out.print("<a href='../ep/ep1.jsp?uid=" + u.getObjectId() + "' class='listlink'>");
					out.println(uname + "</a></td>");
					if (posList.size() < RADIO_NUM && i == (posList.size() - 1)) {
						for(int j = i; j < RADIO_NUM-1; j++)
							out.print("<td width='150'>&nbsp;</td>");
					}
					if (num%RADIO_NUM == RADIO_NUM-1) {out.print("</tr>"); lineCt++;}
					num++;
				}
				if (num%RADIO_NUM != 0) out.print("</tr>");
				if (posList.size() <= 0)
					out.print("<tr><td class='plaintext_grey'>None</td></tr>");
				out.print("</table></td></tr>");

				if (lineCt>=MAX_LINES)
					if (!bShowAllRecipient)
				{
					out.print("<tr><td colspan='2'></td>");
					out.print("<td align='right'><a class='listlink' href='mtg_view.jsp?mid=" + midS
						+ "&aid=" + aIdS + "&showAll=true&rf=1'>... <b>see all attendees</b></a></td>");
					out.print("</tr>");
				}
				else
				{
					out.print("<tr><td colspan='2'></td>");
					out.print("<td align='right'><a class='listlink' href='mtg_view.jsp?mid=" + midS
						+ "&aid=" + aIdS + "&rf=1'>... <b>close attendees list</b></a></td>");
					out.print("</tr>");
				}

				out.print("<tr><td colspan='3'><img src='../i/spacer.gif' width='5' height='5'></td></tr>");
			}

			// list all absent names
			num = 0;
			lineCt = 0;
			if (negList.size() > 0) {
				out.print("<tr><td width='30' align='right'><img src='../i/spacer.gif' border='0' width='30' height='1'></td>");
				out.print("<td width='180' class='plaintext' valign='top'><font color='#bb3333'>&nbsp;&nbsp;&nbsp;<b>Absent</b></font></td>");
				out.print("<td>");
				out.print("<table border='0' cellspacing='0' cellpadding='0' width='100%'>");
	
				Util.sortUserList(negList);
				for(int i = 0; i < negList.size(); i++)
				{
					if (!bShowAllRecipient && lineCt>=MAX_LINES) break;
					u = (user)negList.get(i);
					//uname = (String)u.getAttribute("FirstName")[0];
					uname = u.getFullName();
					if (uname == null) continue;
					//uname = uname + " " + (String)u.getAttribute("LastName")[0];
					//if (uname.length() > 18) uname = (String)u.getAttribute("FirstName")[0] + " " + ((String)u.getAttribute("LastName")[0]).charAt(0) + ".";
	
					if (num%RADIO_NUM == 0) out.print("<tr>");
					out.print("<td width='150' class='plaintext'>");
					out.print("<a href='../ep/ep1.jsp?uid=" + u.getObjectId() + "' class='listlink'>");
					out.println(uname + "</a></td>");
					if (num%RADIO_NUM == RADIO_NUM-1) {out.print("</tr>"); lineCt++;}
					num++;
				}
				if (num%RADIO_NUM != 0) out.print("</tr>");
				if (negList.size() <= 0)
					out.print("<tr><td class='plaintext_grey'>None</td></tr>");
				out.print("</table></td></tr>");

				if (lineCt>=MAX_LINES)
					if (!bShowAllRecipient)
				{
					out.print("<tr><td colspan='2'></td>");
					out.print("<td align='right'><a class='listlink' href='mtg_view.jsp?mid=" + midS
						+ "&aid=" + aIdS + "&showAll=true&rf=1'>... <b>see all attendees</b></a></td>");
					out.print("</tr>");
				}
				else
				{
					out.print("<tr><td colspan='2'></td>");
					out.print("<td align='right'><a class='listlink' href='mtg_view.jsp?mid=" + midS
						+ "&aid=" + aIdS + "&rf=1'>... <b>close attendees list</b></a></td>");
					out.print("</tr>");
				}
			}
		}
		else
		{
			// accept (+), decline (-), waiting for response (o)
			for (int i=0; i<idList.size(); i++)
			{
				idS = (String)idList.get(i);
				stS = (String)stList.get(i);
				try {u = (user)uMgr.get(pstuser, Integer.parseInt(idS));}
				catch (PmpException e) {System.out.println("***** Error: failed to get user " + idS); continue;}
				if (stS.endsWith(meeting.ATT_ACCEPT))
					posList.add(u);
				else if (stS.endsWith(meeting.ATT_DECLINE))
					negList.add(u);
				else
					neuList.add(u);
			}

			// list all accepted names
			if (idList.size() > 0) {
				out.print("<tr><td width='30'><img src='../i/spacer.gif' border='0' width='30' height='1'></td>");
				out.print("<td width='180' class='plaintext' valign='top'><font color='#22aa22'>&nbsp;&nbsp;&nbsp;<b>Accepted</b></font></td>");
				out.print("<td>");
				out.print("<table border='0' cellspacing='0' cellpadding='0' width='100%'>");
	
				num = 0;
				lineCt = 0;
				Util.sortUserList(posList);
				for(int i = 0; i < posList.size(); i++)
				{
					if (!bShowAllRecipient && lineCt>=MAX_LINES) break;
					u = (user)posList.get(i);
					uname = u.getFullName();
					if (uname == null) continue;
					//uname = (String)u.getAttribute("FirstName")[0];
					//uname = uname + " " + (String)u.getAttribute("LastName")[0];
					//if (uname.length() > 18) uname = (String)u.getAttribute("FirstName")[0] + " " + ((String)u.getAttribute("LastName")[0]).charAt(0) + ".";
	
					if (num%RADIO_NUM == 0) out.print("<tr>");
					out.print("<td width='150' class='plaintext'>");
					out.print("<a href='../ep/ep1.jsp?uid=" + u.getObjectId() + "' class='listlink'>");
					out.println(uname + "</a></td>");
					if (posList.size() < RADIO_NUM && i == (posList.size() - 1)) {
						for(int j = i; j < RADIO_NUM-1; j++)
							out.print("<td width='150'>&nbsp;</td>");
					}
					if (num%RADIO_NUM == RADIO_NUM-1) {out.print("</tr>"); lineCt++;}
					num++;
				}
				if (num%RADIO_NUM != 0) out.print("</tr>");
				if (posList.size() <= 0)
					out.print("<tr><td class='plaintext_grey'>None</td></tr>");
				out.print("</table></td></tr>");
	
				if (lineCt>=MAX_LINES)
					if (!bShowAllRecipient)
				{
					out.print("<tr><td colspan='2'></td>");
					out.print("<td align='right'><a class='listlink' href='mtg_view.jsp?mid=" + midS
						+ "&aid=" + aIdS + "&showAll=true&rf=1'>... <b>see all accepted</b></a></td>");
					out.print("</tr>");
				}
				else
				{
					out.print("<tr><td colspan='2'></td>");
					out.print("<td align='right'><a class='listlink' href='mtg_view.jsp?mid=" + midS
						+ "&aid=" + aIdS + "&rf=1'>... <b>close recipients list</b></a></td>");
					out.print("</tr>");
				}
	
				out.print("<tr><td colspan='3'><img src='../i/spacer.gif' width='5' height='5'></td></tr>");
			}

			// list all decline names
			num = 0;
			lineCt = 0;
			if (negList.size() > 0) {
				out.print("<tr><td width='30'><img src='../i/spacer.gif' border='0' width='30' height='1'></td>");
				out.print("<td width='180' class='plaintext' valign='top'><font color='#bb3333'>&nbsp;&nbsp;&nbsp;<b>Declined</b></font></td>");
				out.print("<td>");
				out.print("<table width='100%' border='0' cellspacing='0' cellpadding='0'>");
	
				Util.sortUserList(negList);
				for(int i = 0; i < negList.size(); i++)
				{
					if (!bShowAllRecipient && lineCt>=MAX_LINES) break;
					u = (user)negList.get(i);
					//uname = (String)u.getAttribute("FirstName")[0];
					uname = u.getFullName();
					if (uname == null) continue;
					//uname = uname + " " + (String)u.getAttribute("LastName")[0];
					//if (uname.length() > 18) uname = (String)u.getAttribute("FirstName")[0] + " " + ((String)u.getAttribute("LastName")[0]).charAt(0) + ".";
	
					if (num%RADIO_NUM == 0) out.print("<tr>");
					out.print("<td width='150' class='plaintext'>");
					out.print("<a href='../ep/ep1.jsp?uid=" + u.getObjectId() + "' class='listlink'>");
					out.println(uname + "</a></td>");
					if (num%RADIO_NUM == RADIO_NUM-1) out.print("</tr>");
					num++;
				}
				if (num%RADIO_NUM != 0) out.print("</tr>");
				if (negList.size() <= 0)
					out.print("<tr><td class='plaintext_grey'>None</td></tr>");
				out.print("</table></td></tr>");
	
				if (lineCt>=MAX_LINES)
					if (!bShowAllRecipient)
				{
					out.print("<tr><td colspan='2'></td>");
					out.print("<td align='right'><a class='listlink' href='mtg_view.jsp?mid=" + midS
						+ "&aid=" + aIdS + "&showAll=true&rf=1'>... <b>see all declined</b></a></td>");
					out.print("</tr>");
				}
				else
				{
					out.print("<tr><td colspan='2'></td>");
					out.print("<td align='right'><a class='listlink' href='mtg_view.jsp?mid=" + midS
						+ "&aid=" + aIdS + "&rf=1'>... <b>close recipients list</b></a></td>");
					out.print("</tr>");
				}
	
				out.print("<tr><td colspan='3'><img src='../i/spacer.gif' width='5' height='5'></td></tr>");
			}

			// list all not responded names
			num = 0;
			if (neuList.size() > 0) {
				out.print("<tr><td width='30'><img src='../i/spacer.gif' border='0' width='30' height='1'></td>");
				out.print("<td width='180' class='plaintext' valign='top'><font color='#3333bb'>&nbsp;&nbsp;&nbsp;<b>Not yet Respond</b></font></td>");
				out.print("<td>");
				out.print("<table width='100%' border='0' cellspacing='0' cellpadding='0'>");
	
				Util.sortUserList(neuList);
				for(int i = 0; i < neuList.size(); i++)
				{
					if (!bShowAllRecipient && lineCt>=MAX_LINES) break;
					u = (user)neuList.get(i);
					//uname = (String)u.getAttribute("FirstName")[0];
					uname = u.getFullName();
					if (uname == null) continue;
					//uname = uname + " " + (String)u.getAttribute("LastName")[0];
					//if (uname.length() > 18) uname = (String)u.getAttribute("FirstName")[0] + " " + ((String)u.getAttribute("LastName")[0]).charAt(0) + ".";
	
					if (num%RADIO_NUM == 0) out.print("<tr>");
					out.print("<td width='150' class='plaintext'>");
					out.print("<a href='../ep/ep1.jsp?uid=" + u.getObjectId() + "' class='listlink'>");
					out.println(uname + "</a></td>");
					if (num%RADIO_NUM == RADIO_NUM-1) {out.print("</tr>"); lineCt++;}
					num++;
				}
				if (num%RADIO_NUM != 0) out.print("</tr>");
				if (neuList.size() <= 0)
					out.print("<tr><td class='plaintext_grey'>None</td></tr>");
				out.print("</table></td></tr>");
	
				if (lineCt>=MAX_LINES)
					if (!bShowAllRecipient)
				{
					out.print("<tr><td colspan='2'></td>");
					out.print("<td align='right'><a class='listlink' href='mtg_view.jsp?mid=" + midS
						+ "&aid=" + aIdS + "&showAll=true&rf=1'>... <b>see all recipients</b></a></td>");
					out.print("</tr>");
				}
				else
				{
					out.print("<tr><td colspan='2'></td>");
					out.print("<td align='right'><a class='listlink' href='mtg_view.jsp?mid=" + midS
						+ "&aid=" + aIdS + "&rf=1'>... <b>close recipients list</b></a></td>");
					out.print("</tr>");
				}
			}
		}

		// the next time in the for loop will list the optional attendeeds
		if (z == 0)
		{
			// optional list
			posList.clear();
			negList.clear();
			neuList.clear();
			if (optionalIds.size()<=0 && optionalSts.size()<=0) {
				break;		// don't show empty optional list
			}
			idList = optionalIds;
			stList = optionalSts;
			out.print("<tr><td colspan='3'><img src='../i/spacer.gif' width='5' height='5'></td></tr>");
		}
	}
%>
<tr><td colspan="3"><img src="../i/spacer.gif" width="5" height="10"></td></tr>
<%

	// Guest Emails
	if (guestEmails.length() > 0) {
%>
<tr>
	<td width='30'><img src='../i/spacer.gif' width='30' height='1'/></td>
	<td width='180' class="plaintext" valign="top"><b>Guest Emails</b></td>
<%
		if (myUid==ownerId || isAdmin) {
	
			out.print("<td class='plaintext'>" + guestEmails.toString() + "</td>");
		} else {
			int len = guestEmails.toString().split(",").length;
			out.print("<td class='plaintext'>Total " + len + " guests are invited.</td>");
		}
	}
	out.print("</tr>");
	
}	// END if !isGuest
%>


<tr><td colspan="3"><img src="../i/spacer.gif" width="5" height="10"/></td></tr>

<!-- Agenda -->
<%
	boolean bCanUpdateAgenda = (canUpdate || isAdmin) && status.equals(meeting.NEW);
	if (bCanUpdateAgenda || agendaArr[0] != null) {
%>

<tr>
	<td width='30'><img src='../i/spacer.gif' width='30' height='1'/></td>
	<td width='180' class="plaintext" valign="top"><b>Agenda:</b></td>
	<td class="plaintext">
		<table width='100%' border="0" cellspacing="0" cellpadding="0">

<%
	if (bCanUpdateAgenda) {
		out.print("<tr><td colspan='8' valign='bottom'>");
		out.print("<table cellspacing='0' cellpadding='0' border='0' width='100%'>");
		out.print("<tr><td>&nbsp;</td>");
		out.print("<td class='formtext' valign='bottom' width='300'>");
		out.print("<img src='../i/bullet_tri.gif' width='20' height='10'>");
		out.print("<a class='listlinkbold' href='mtg_upd_agenda1.jsp?mid=" + midS + "'>Update Meeting Agenda</a>");
		out.print("</td></tr></table></td></tr>");
	}

	if (agendaArr[0] != null) {
%>

<!-- header -->
	<tr>
	<td colspan="8" bgcolor="#EBECED" height="3"><img src="../i/spacer.gif" width="1" height="3" border="0"/></td>
	</tr>

	<tr>
	<td colspan="8" height="2" bgcolor="#336699"><img src="../i/spacer.gif" width="2" height="2"/></td>
	</tr>

	<tr>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td bgcolor="#6699cc" class="td_header"><strong>&nbsp;Agenda Item</strong></td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"/></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="80" bgcolor="#6699cc" class="td_header"><strong>Time</strong></td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"/></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="120" bgcolor="#6699cc" class="td_header" align="left"><strong>Responsible</strong></td>
	</tr>
<!-- header end -->

<%
	even = false;
	int order, level, duration, width, hour, min;
	String[] levelInfo = new String[10];
	String itemName;
	for (int i=0; i<agendaArr.length; i++)
	{
		s = (String)agendaArr[i];			// (pre-order::order::level::item::duration::owner)
		
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
		{
			levelInfo[level] = String.valueOf(order);
		}
		else
		{
			levelInfo[level] = levelInfo[level - 1] + "." + order;
		}

		if (even) bgcolor = "bgcolor='#EEEEEE'";
		else bgcolor = "bgcolor='#ffffff'";
		even = !even;
		out.println("<tr " + bgcolor + ">");

		// -- list the item header no. and name
		out.print("<td colspan='2'><table border='0' cellspacing='0' cellpadding='2'><tr>");
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
		if (hour==0 && min == 0)
			out.print("-");
		else if (min != 0)
			out.print(min + " min");
		out.print("</td>");

		// -- responsible person @ECC042507
		out.print("<td colspan='3' class='plaintext' valign='top'>&nbsp;&nbsp;");
		int id = Integer.parseInt(idS);
		if (id > 0)
		{
			uname = "-";	// in case of trouble
			try{
				u = (user)uMgr.get(pstuser, id);
				uname = u.getFullName();
				//uname = (String)u.getAttribute("FirstName")[0] + " " + (String)u.getAttribute("LastName")[0];
				if (uname.length() > 18)
				{
					if ((s = (String)u.getAttribute("LastName")[0]) != null)
						uname = (String)u.getAttribute("FirstName")[0] + " " + s.charAt(0) + ".";
				}
			}
			catch (Exception e) {System.out.println("(mtg_view.jsp) got problem resolving agenda resp name: "+idS);}
			out.print("<a href='../ep/ep1.jsp?uid=" + idS + "' class='listlink'>" + uname + "</a>");
		}
		else if (id == meeting.iAGENDA_NONE)
			out.print("-");
		else if (id == meeting.iAGENDA_ALL)
			out.print("All");
		out.print("</td>");

		out.println("</tr>");
	}
}	// END if there is any agenda item
/*else {
	out.print("<tr><td class='plaintext_grey'>None</td></tr>");
}*/
	}	// END if bCanUpdateAgenda OR there is any agenda item
%>
		</table>
	</td>
</tr>
<!-- end Agenda -->
<tr><td colspan='3'><a name='attachment'>&nbsp;</a></td></tr>

<!-- File Attachment -->
<%
	Object [] attmtList = mtg.getAttribute("AttachmentID");
	int [] aids = Util2.toIntArray(attmtList);
	if (aids.length > 0) {
%>
<tr>
	<td width='30'>&nbsp;</td>
	<td width='180' class="plaintext" valign="top"><b>File Attachment:</b></td>
	<td class="plaintext" valign="top">
		<table width="100%" border="0" cellspacing="0" cellpadding="0">
<%
	// file name is: Attachment-name of doc.ext
	// @SWS061406 begins
	int [] linkIds = attMgr.findId(pstuser, "Link='" + midS + "'");		// @ECC103008
	aids = Util2.mergeIntArray(aids, linkIds);
	attachment attmtObj;
	String fileName, user;
	Date attmtCreateDt;
	int colSpanNum = 1;
	if (aids.length <= 0)
	{
		out.print("<tr><td class='plaintext_grey'>None</td></tr>");
	}
	else
	{
		out.print("<tr><td>");
		String [] label0 = {"&nbsp;File Name", "Owner", "Size", "View #", "Posted On"};
		int [] labelLen0 = {0, 80, 50, 50, 90};
		boolean [] bAlignCenter0 = {false, true, true, true, true};
		out.print(Util.showLabel(label0, null, null, null,
			labelLen0, bAlignCenter0, true));	// no sort, showAll and align center
			
		colSpanNum = label0.length * 3 - 1;

		Arrays.sort(aids);
		String link;
		Integer iObj;
		int views;
		
		for (int j=0; j<aids.length; j++)
		{
			// list files by alphabetical order
			//String attmt = (String)attmtList[j];
			attmtObj = (attachment)attMgr.get(pstuser, aids[j]);
			user = attmtObj.getOwnerDisplayName(pstuser);
			attmtCreateDt = (Date)attmtObj.getAttribute("CreatedDate")[0];
			fileName = attmtObj.getFileName();
			s = (String)attmtObj.getAttribute("Location")[0];
			link = host + "/servlet/ShowFile?attId=" + attmtObj.getObjectId();
			
			iObj = (Integer)attmtObj.getAttribute("Frequency")[0];
			if (iObj != null)
				views = iObj.intValue();
			else
				views = 0;

			out.print("<tr>");
			out.print("<td></td>");
			out.print("<td class='plaintext' valign='top'>"
				+ "<a class='listlink' href='" + link + "'>" + fileName + "</a>");
			if (Arrays.binarySearch(linkIds, aids[j]) >= 0)
				out.print("&nbsp;&nbsp;<a href='" + host + "/project/goto_link.jsp?attId=" + aids[j]
				+ "'><img src='../i/link.jpg' border='0' title='This is a link file' /></a>");
			out.print("</td>");
			
			// owner
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td class='formtext' align='center'><a href='../ep/ep1.jsp?uid="
					+ (String)attmtObj.getAttribute("Owner")[0] + "' class='listlink'>" + user + "</a></td>");

			// size
			out.print("<td colspan='2'></td>");
			out.print("<td class='formtext' align='right'>" + Util2.fileSizeDisplay(attmtObj.size()) + "&nbsp;</td>");

			// views
			out.print("<td colspan='2'></td>");
			out.print("<td class='plaintext' align='center'>" + views + "</td>");
			
			// posted date
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td class='formtext' align='center'>" + df3.format(attmtCreateDt) + "</td>");
			
			out.print("</tr>");
		}
		out.print("</table>");	// Table from showLabel()
		out.print("</td></tr>");
	}
%>
		</table>
	</td>
</tr>

<%
	}	// END: if there is any file attachment
	
	/////////////////////////////////////////
	// close meeting info panel
	out.print("</table></DIV>");	// END Info panel table
	out.print("</td></tr>");
	
	out.print("</table>");
	out.print("<table border='0' cellspacing='0' cellpadding='0' width='90%'>");
	
	if (bText.length() > 0)	
	{
	////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////
	// panel for meeting minute
	out.print("<tr><td colspan='3'>");
	out.print(Util.getHeaderPartitionLine());
	out.print("<img id='ImgMinutesPanel' src='../i/bullet_tri.gif'/>");
	out.print("<a id='AMinutesPanel' href='javascript:togglePanel(\"MinutesPanel\", \"Show meeting minutes\", \"Hide meeting minutes\");' class='listlinkbold'>Hide meeting minutes</a>");
	
	out.print("<DIV id='DivMinutesPanel' style='display:block;'>");
	out.print("<table border='0' cellspacing='0' cellpadding='0' width='100%'>");	// Minutes panel table
	
%>

<!-- Minute -->
<tr>
	<td width='30'><img src='../i/spacer.gif' width='30' height='1'/></td>
	<td width='180' class="plaintext" valign="top"></td>
	<% //if (bText.length() > 0) out.print("<td id='mtg_min' class='blog_text'>" + bText);
	   //else out.print("<td class='plaintext_grey'>None");
		out.print("<td id='mtg_min' class='blog_text'>" + bText);
	%>
	</td>
</tr>

<%
	/////////////////////////////////////////
	// close more meeting minute panel
	out.print("</table></DIV>");	// END Minutes panel table
	out.print("</td></tr>");
	}	// END if bText.length() > 0
%>

</table>
<table border='0' cellspacing='0' cellpadding='0' width='90%'>

<!-- ACTION / DECISION / ISSUE -->

<%

	////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////
	// panel for action/decision
	out.print("<tr><td colspan='3'>");
	out.print(Util.getHeaderPartitionLine());
	out.print("<img id='ImgActionPanel' src='../i/bullet_tri.gif'/>");
	out.print("<a id='AActionPanel' href='javascript:togglePanel(\"ActionPanel\", \"Show action / decision\", \"Hide action / decision\");' class='listlinkbold'>Hide action / decision</a>");
	
	out.print("<DIV id='DivActionPanel' style='display:block;'>");
	out.print("<table border='0' cellspacing='0' cellpadding='0' width='100%'>");	// Action panel table

	// for Action Item, Decision Records and Issues
	PstAbstractObject [] aiObjList = new PstAbstractObject[0];
	PstAbstractObject [] dsObjList = new PstAbstractObject[0];
	PstAbstractObject [] bgObjList = new PstAbstractObject[0];

	// get the list of action items
	ids = aMgr.findId(pstuser, "(MeetingID='" + midS + "') && (Type='" + action.TYPE_ACTION + "')");
	if (ids.length > 0)
	{
		Arrays.sort(ids);
		aiObjList = aMgr.get(pstuser, ids);
	}

	// decisions
	ids = aMgr.findId(pstuser, "(MeetingID='" + midS + "') && (Type='" + action.TYPE_DECISION + "')");
	if (ids.length > 0)
	{
		Arrays.sort(ids);
		dsObjList = aMgr.get(pstuser, ids);
	}

	// issues
	if (isPRMAPP)
	{
		ids = bMgr.findId(pstuser, "MeetingID='" + midS + "'");
		if (ids.length > 0)
		{
			Arrays.sort(ids);
			bgObjList = bMgr.get(pstuser, ids);
		}
	}
%> 
	<tr>
	<td width='20'></td>
	<td class="plaintext" valign="top"></td>
	<td valign='bottom'>
		<table cellpadding='0' cellspacing='0' width='100%'>
		<tr>
		<td>&nbsp;</td>
		<td width='300'>
		<img src='../i/bullet_tri.gif'/>
		<a class='listlinkbold' href='../project/proj_action.jsp?mid=<%=midS%>'>Show all from linked meetings</a>
		</td>
		</tr>
		</table>
	</td>
	</tr>

<%
if (aiObjList.length>0 || dsObjList.length>0 || bgObjList.length>0)
{	// if there is action or decision or issue

	String projIdS, bugIdS, priority, dot;
	user uObj;
	int aid;
	Object [] respA;
	Date expireDate, createdDate;
	action obj;
%>

<form name="updAction" action="upd_action.jsp" method="post">
<input type="hidden" name="mid" value="<%=midS%>"/>
<input type="hidden" name="oid"/>
<input type="hidden" name="type"/>
<input type="hidden" name="backPage" value="mtg_view.jsp"/>

<tr>
	<td>&nbsp;<a name="action"></a></td>
	<td colspan="2">

<!-- list of action items -->
<%
if (aiObjList.length > 0)
{
	if (isOMFAPPonly) {
		out.print(Util.showLabel(PrmMtgConstants.vlabel0OMF, PrmMtgConstants.vlabelLen0OMF, false));
	}
	else if (isPRMAPP) {
		String [] vlabel0 = {"&nbsp;Action Item", "Responsible", "State", "Priority", "Blog", "Project", "Due"};
		int [] vlabelLen0 = {-56, 14, 6, 6, 6, 6, 6};
		boolean [] bAlignCenter0 = {false, true, true, true, true, true, true};
		out.print(Util.showLabel(vlabel0, vlabelLen0, bAlignCenter0, true));
	}
	else {
		out.print(Util.showLabel(PrmMtgConstants.vlabel0CR, PrmMtgConstants.vlabelLen0CR, false));	// CR-OMF
	}

	boolean found;
	boolean updateOK;

	even = false;
	int idx = 0;
	
	for(int i = 0; i < aiObjList.length; i++)
	{	// the list of action item for this meeting object
		idx++;
			
		obj = (action)aiObjList[i];
		aid = obj.getObjectId();

		subject		= (String)obj.getAttribute("Subject")[0];
		status		= (String)obj.getAttribute("Status")[0];
		priority	= (String)obj.getAttribute("Priority")[0];
		expireDate	= (Date)obj.getAttribute("ExpireDate")[0];
		ownerIdS	= (String)obj.getAttribute("Owner")[0];		// action item coordinator
		projIdS		= (String)obj.getAttribute("ProjectID")[0];
		bugIdS		= (String)obj.getAttribute("BugID")[0];
		respA		= obj.getAttribute("Responsible");
		
		if (status==null || priority==null) {
			// should not be empty status, remove it!
			aMgr.delete(obj);
			idx--;
			continue;
		}

		found = false;
		if (Integer.parseInt(ownerIdS) != myUid)
		{
			for (int j=0; j<respA.length; j++)
			{
				if (respA[j] == null) break;
				if (Integer.parseInt((String)respA[j]) == myUid)
				{
					found = true;
					break;
				}
			}
		}

		// update ok?
		if (isAdmin || ownerId==myUid || found) updateOK = true;
		else updateOK = false;

		if (even)
			bgcolor = "bgcolor='#EEEEEE'";
		else
			bgcolor = "bgcolor='#ffffff'";
		even = !even;
		out.println("<tr " + bgcolor + ">" + "<td colspan='21'><img src='../i/spacer.gif' width='2' height='5'></td></tr>");
		out.print("<tr " + bgcolor + ">");

		// Subject
		out.print("<td>&nbsp;</td>");
		out.print("<td valign='top'><table border='0'><tr>");
		out.print("<td class='plaintext' valign='top' width='20'>" + idx + ". </td>");
		out.print("<td class='ptextS1' valign='top'>");
		if (canUpdateAction || (isOver && Integer.parseInt(ownerIdS) == myUid) || updateOK)
		{
			out.print("<a href='javascript:editAC(\"" + aid + "\", \"Action\")'>");
			if (aid == selectedAId) out.print("<b>" + subject + "</b>");
			else out.print(subject);
			out.print("</a>");
		}
		else
		{
			if (aid == selectedAId) out.print("<b>" + subject + "</b>");
			else out.print(subject);
		}
		out.println("</td></tr></table></td>");

		// Responsible
		out.print("<td colspan='2'>&nbsp;</td>");
		out.print("<td class='plaintext' valign='top' align='center'>");

		found = false;
		for (int j=0; j<respA.length; j++)
		{
			s = (String)respA[j];
			if (s == null) break;
			try{uObj = (user)uMgr.get(pstuser,Integer.parseInt(s));}
			catch (PmpException e) {l.error("user " + s + " not found in action item " + aid); continue;}
			out.print("<a class='listlink' href='../ep/ep1.jsp?uid=" + s + "'>");
			out.print((String)uObj.getAttribute("FirstName")[0]);
			out.print("</a>");
			if (s.equals(ownerIdS))
			{
				found = true;
				out.print("*");
			}
			if (j < respA.length-1 || !found) out.print(", ");
		}

		if (!found)
		{
			// include coordinator/owner into the list of responsible
			uObj = (user)uMgr.get(pstuser,Integer.parseInt(ownerIdS));
			out.print("<a class='listlink' href='../ep/ep1.jsp?uid=" + ownerIdS + "'>");
			out.print((String)uObj.getAttribute("FirstName")[0]);
			out.print("</a>*");
		}
		out.println("</td>");

		// Status {OPEN, LATE, CANCEL, DONE}
		dot = obj.getStatusDisplay(pstuser);
		out.print("<td colspan='3' class='listlink' align='center' valign='top' style='padding-top:3px;'>");
		out.print(dot);
		out.println("</td>");

		// Priority {HIGH, MEDIUM, LOW}
		dot = obj.getPriorityDisplay(pstuser);
		out.print("<td colspan='3' class='listlink' align='center' valign='top' style='padding-top:3px;'>");
		out.print(dot);
		out.println("</td>");

		// support blogging in action/decision/issue
		ids = rMgr.findId(pstuser, "TaskID='" + aid + "'");
		out.print("<td colspan='2'>&nbsp;</td>");
		out.print("<td class='listtext' valign='top' align='center'>");
		out.print("<a class='listlink' href='../blog/blog_task.jsp?projId=" + projIdS + "&aid=" + aid + "'>");
		out.print("<div id='bubbleDIV'>" + ids.length);
		out.print("<img id='bg' src='../i/bubble.gif' /></div></a>");
		out.println("</td>");

		if (!isOMFAPPonly) {
			// Project id
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td class='plaintext' valign='top' align='center'>");
			if (projIdS != null)
			{
				out.print("<a class='plaintext' href='../project/proj_action.jsp?projId=" + projIdS + "&aid=" + aid + "#action'>");
				out.print(projIdS + "</a>");
			}
			else
				out.print("-");
			out.println("</td>");
	
/*			if (isPRMAPP)
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
			*/
		}
		
		// ExpireDate
		out.print("<td colspan='2'>&nbsp;</td>");
		out.print("<td class='plaintext' align='center' valign='top'>");
		out.print(df1.format(expireDate));
		out.println("</td>");

		out.println("</tr>");
		out.println("<tr " + bgcolor + ">" + "<td colspan='21'><img src='../i/spacer.gif' width='2' height='3'></td></tr>");
	}
	if (aiObjList.length <= 0)
		out.print("<tr><td colspan='23' class='plaintext_grey'>&nbsp;&nbsp;None</td></tr>");
	out.println("</table>");
	
	out.println("<tr><td colspan='3'><img src='../i/spacer.gif' width='5' height='5'></td></tr>");

}	// end if there is action item

%>

	</td>
</tr>

<!-- END list of action items -->

<!-- List of Decision Records -->
<tr>
	<td>&nbsp;</td>
	<td colspan="2">

<%
if (dsObjList.length > 0)
{
	if (isOMFAPPonly) 
		out.print(Util.showLabel(PrmMtgConstants.vlabel1OMF, PrmMtgConstants.vlabelLen1OMF, false));
	else if (isPRMAPP)
		out.print(Util.showLabel(PrmMtgConstants.vlabel1, PrmMtgConstants.vlabelLen1, false));
	else
		out.print(Util.showLabel(PrmMtgConstants.vlabel1CR, PrmMtgConstants.vlabelLen1CR, false));

	even = false;
	for(int i = 0; i < dsObjList.length; i++)
	{	// the list of decision records for this meeting object
		obj = (action)dsObjList[i];
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
		out.println("<tr " + bgcolor + ">" + "<td colspan='14'><img src='../i/spacer.gif' width='2' height='2'></td></tr>");
		out.print("<tr " + bgcolor + ">");

		// Subject
		out.print("<td>&nbsp;</td>");
		out.print("<td valign='top'><table border='0'><tr>");
		out.print("<td class='plaintext' valign='top' width='20'>" + (i+1) + ". </td>");
		out.print("<td class='ptextS1' valign='top'>");
		if (canUpdateAction)
		{
			out.print("<a href='javascript:editAC(\"" + aid + "\", \"Decision\")'>");
			if (aid == selectedAId) out.print("<b>" + subject + "</b>");
			else out.print(subject);
			out.print("</a>");
		}
		else
		{
			if (aid == selectedAId) out.print("<b>" + subject + "</b>");
			else out.print(subject);
		}


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

		if (!isOMFAPPonly) { // @AGQ090606
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

		out.println("</tr>");
		out.println("<tr " + bgcolor + ">" + "<td colspan='17'><img src='../i/spacer.gif' width='2' height='3'></td></tr>");
	}
	
	if (dsObjList.length <= 0)
		out.print("<tr><td colspan='17' class='plaintext_grey'>&nbsp;&nbsp;None</td></tr>");
	out.println("</table>");

	out.println("<tr><td colspan='3'><img src='../i/spacer.gif' width='5' height='5'></td></tr>");
	
}	// end if there is decision records

%>
	</td>
</tr>
<!-- End list of decision records -->

<%	// @AGQ090606
	if (!isOMFAPPonly) { 
%>
<!-- List of Issues -->
<tr>
	<td>&nbsp;</td>
	<td colspan="2">

<%
if (bgObjList.length > 0)
{
	out.print(Util.showLabel(PrmMtgConstants.vlabel2, PrmMtgConstants.vlabelLen2, false));

	even = false;

	bug bObj;

	for(int i = 0; i < bgObjList.length; i++)
	{	// the list of issues for this meeting object
		bObj = (bug)bgObjList[i];
		aid = bObj.getObjectId();

		subject		= (String)bObj.getAttribute("Synopsis")[0];
		status		= (String)bObj.getAttribute("State")[0];
		priority	= (String)bObj.getAttribute("Priority")[0];
		createdDate	= (Date)bObj.getAttribute("CreatedDate")[0];
		projIdS		= (String)bObj.getAttribute("ProjectID")[0];
		ownerIdS	= (String)bObj.getAttribute("Creator")[0];		// issue submitter

		if (even)
			bgcolor = "bgcolor='#EEEEEE'";
		else
			bgcolor = "bgcolor='#ffffff'";
		even = !even;
		out.print("<tr " + bgcolor + ">");

		// Subject
		s = (String)bObj.getAttribute("Type")[0];
		out.print("<td>&nbsp;</td>");
		out.print("<td valign='top'><table border='0'><tr>");
		out.print("<td class='plaintext' valign='top' width='20'>" + (i+1) + ". </td>");
		out.print("<td class='ptextS1' valign='top'>");
		if (canUpdateAction || (isOver && Integer.parseInt(ownerIdS) == myUid))
		{
			if (s.equals(bug.CLASS_ISSUE))
				out.print("<a href='javascript:editAC(\"" + aid + "\", \"Issue\")'>");
			else
				out.print("<a href='../bug/bug_update.jsp?bugId=" + aid + "'>");
			if (aid == selectedAId) out.print("<b>" + subject + "</b>");
			else out.print(subject);
			out.print("</a>");
		}
		else
		{
			if (aid == selectedAId) out.print("<b>" + subject + "</b>");
			else out.print(subject);
		}
		out.println("</td></tr></table></td>");

		// Submitter
		uObj = (user)uMgr.get(pstuser, Integer.parseInt(ownerIdS));
		out.print("<td colspan='2'>&nbsp;</td>");
		out.print("<td class='listtext' valign='top'>");
		out.print("<a class='listlink' href='../ep/ep1.jsp?uid=" + ownerIdS + "'>");
		out.print((String)uObj.getAttribute("FirstName")[0] + " " + ((String)uObj.getAttribute("LastName")[0]).charAt(0) + ".");
		out.print("</a>");
		out.print("</td>");

		// Status {OPEN, CLOSE}
		dot = "../i/";
		if (status.equals(bug.OPEN)) {dot += "dot_lightblue.gif";}
		else if (status.equals(bug.CLOSE)) {dot += "dot_green.gif";}
		else {dot += "dot_grey.gif";}
		out.print("<td colspan='3' class='listlink' align='center' valign='top'>");
		out.print("<img src='" + dot + "' title='" + status + "'>");
		out.println("</td>");

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

		out.println("</tr>");
		out.println("<tr " + bgcolor + ">" + "<td colspan='23'><img src='../i/spacer.gif' width='2' height='2'></td></tr>");
	}
	
	if (bgObjList.length <= 0)
		out.print("<tr><td colspan='17' class='plaintext_grey'>&nbsp;&nbsp;None</td></tr>");
	out.println("</table>");
	
	out.println("<tr><td colspan='3'><img src='../i/spacer.gif' width='5' height='10'></td></tr>");

}	// end if there is issues

%>
	</td>
</tr>
<!-- End list of issues -->
<%	}
	// @AGQ090606	
%>

<%	if (aiObjList.length > 0)
	{%>
<tr>
	<td>&nbsp;</td>
	<td colspan='2' class="tinytype"><font color="#555555">(* Action item coordinator)</font></td>
</tr>
<%	} %>

<%	if (aiObjList.length>0 || dsObjList.length>0 || bgObjList.length>0)
	{%>
<tr>
	<td>&nbsp;</td>
	<td colspan='2'><table class="tinytype">
	<tr>
		<td width='40' class="tinytype">Status:</td>
		<td class="tinytype">&nbsp;<img src="../i/dot_lightblue.gif" border="0"><%=action.OPEN%></td>
		<td class="tinytype">&nbsp;<img src="../i/dot_green.gif" border="0"><%=action.DONE%>/<%=bug.CLOSE%></td>
		<td class="tinytype">&nbsp;<img src="../i/dot_red.gif" border="0"><%=action.LATE%></td>
		<td class="tinytype">&nbsp;<img src="../i/dot_cancel.gif" border="0"><%=action.CANCEL%></td>
	</tr>
	<tr>
		<td class="tinytype">Priority:
		<td class="tinytype">&nbsp;<img src="../i/dot_red.gif" border="0"><%=action.PRI_HIGH%></td>
		<td class="tinytype">&nbsp;<img src="../i/dot_orange.gif" border="0"><%=action.PRI_MED%></td>
		<td class="tinytype">&nbsp;<img src="../i/dot_yellow.gif" border="0"><%=action.PRI_LOW%></td>
	</tr>
	</table></td>
</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' height='10'></td></tr>
<%
	}
%>


<!-- End list of ACTION / DECISION / ISSUE -->
</form>
<%

	}	// End if !isPublicMeeting OR if there is action, decision or issue
	
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

<!-- @ECC071907 Meeting Blog -->
<tr>
	<td width='30'><a name='blog'></a></td>
	<td width='180' class="plaintext" valign="top"></td>
	<td valign='bottom'>
		<table cellpadding='0' cellspacing='0' width='100%'>
		<tr>
		<td>&nbsp;</td>
		<td width='300'>
		<img src='../i/bullet_tri.gif' width='20' height='10'/>
		<a class='listlinkbold' href='../blog/addblog.jsp?type=<%out.print(result.TYPE_MTG_BLOG + "&id=" + midS);%>'>New Blog Posting</a>
		</td>
		</tr>
		</table>
	</td>
</tr>

<%
	// list the meeting blogs
	out.println(Util2.displayBlog(pstuser, midS, result.TYPE_MTG_BLOG));
%>
	
<%
	/////////////////////////////////////////
	// close blog panel
	out.print("</table></DIV>");	// END Blog panel table
	out.print("</td></tr>");
%>
</table>

<%
if (!isGuest) {
%>
<table border='0' cellspacing='0' cellpadding='0' width='90%'>
<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='10'/></td></tr>

<tr>
	<td colspan='2'><img src='../i/spacer.gif' width='200' height='1'/></td>
	<td class='plaintext_bold' width='85%'>&nbsp;&nbsp;&nbsp;&nbsp;Enter your questions, comments or suggestions:</td>
</tr>

<form name='quickBlogForm' action='../blog/post_addblog.jsp' method='post'>
<tr>
	<td colspan='2'><img src='../i/spacer.gif' width='200' height='1'/></td>
	<td>
	<input type='hidden' name='type' value='<%=result.TYPE_MTG_BLOG%>'/>
	<input type='hidden' name='id' value='<%=midS%>'/>
	<input type='hidden' name='backPage' value='../meeting/mtg_view.jsp?mid=<%=midS%>:rf=1#blog'/>
		<table border='0' width='90%'><tr>
		<td width='90%' align='center'>
		<textarea class='plaintext' name='logText' rows='3' style='width:95%;'></textarea>&nbsp;&nbsp;</td>
		<td valign='top'><button type='submit' class='button_medium'
			onclick='javascript:return postQuickBlog();'>Submit</button></td>
		</tr></table>
	</td>
</tr>

<tr>
	<td colspan='2'></td>
	<td class='plaintext_big'>
		<img src='../i/spacer.gif' width='8' height='1'/>
		<input type='checkbox' name='sendEmail'>&nbsp;Send Email notification to meeting members</input>
		<input type='hidden' name='overrideSendEmail' value='true'/>
		<input type='hidden' name='plainText' value='true'/>
	</td>
</tr>
</form>

<%}	// END if (!isGuest)
	out.print("<tr><td colspan='3'>&nbsp;</td></tr>");

}	// END if isPublicMeeting || !isGuest


// request to login or register
if (isNotLogin) {
	out.print("<tr><td colspan='3'>");
	out.print("<table cellspacing='0' cellpadding='0' width='90%'><tr>");
	out.print("<td class='ptextS2'><img src='../i/spacer.gif' width='20' height='30'/>");
	out.print("<img src='../i/bullet_tri.gif'/>");
	out.print("<a href='../login.jsp' style='color:#ee0000'><b>Login to view this meeting</b></a></td>");
	out.print("<td align='right'>");
	out.print("<table cellspacing='0' cellpadding='0' width='100%'><tr><td>&nbsp;</td><td width='300'>");
	out.print("<img src='../i/bullet_tri.gif'/>");
	out.print("<a href='../admin/adduser.jsp?' class='listlinkbold'>Sign-up NOW</a></td></tr></table>");
	out.print("</td>");
	out.print("</tr></table>");
	out.print("</td></tr>");
	out.print("<tr><td colspan='3'>&nbsp;</td></tr>");
}

	if (!bNoFacebook) {
%>
<!-- facebook -->
<tr>
	<td colspan='3'>
	<table><tr>
		<td><img src='../i/spacer.gif' width='20' /></td>
		<td><fb:comments href="<%=fbHost%>/meeting/mtg_view.jsp?mid=<%=midS%>&fb=1" num_posts="2" width="500" publish_feed="true"></fb:comments></td>
	</tr></table>
	</td>
</tr>
<%	}	// bNoFacebook %>

</table>

</td>
</tr>

<tr>
	<td colspan='3'>
		<!-- Footer -->
		<jsp:include page="../foot.jsp" flush="true"/>
		<!-- End of Footer -->
	</td>
</tr>
</table>

<jsp:include page="expr.jsp" flush="true"/>

</body>
</html>
