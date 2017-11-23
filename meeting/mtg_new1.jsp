<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2005, EGI Technologies, Co.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: mtg_new1.jsp
//	Author: ECC
//	Date:	02/24/05
//	Description: Create a new meeting.
//				 The look of this file should match with mtg_update1.jsp
//
//	Modification:
//			@ECC100605	Support create follow meeting either from a standalone meeting or
//						at the end of a recurring event.
//			@AGQ022806	Made the Select list retain the members after selecting a different 
//						Meeting group.
//						Add Distribution list 
//			@AGQ030606	Added guestEmails
//			@AGQ031006	Resort list incase the sorting algorithm does not match with javascript's sorting
//						This will be used to benefit a faster Add & Remove method (to be implemented)
//			@AGQ041306	Changed getYear() to getFullYear(); this fix is for firefox
//			@041906SWS	Added sort function to Project names.
//			@ECC061206a	Add project association to meeting.
//			@AGQ072706	The time will begin at a more accurate time
//						curTime is between hh:10 - hh:40 start time will be hh:30
//						curTime is less than hh:10 start time will be hh:00
//						curTime is greater than hh:40 start time will be hh+1:00
//						When 11:00pm or 11:30pm is selected the day will change to the
//						next day if required
//						Also added some special requirements when the current time is near 11:00pm
//						and the user start a new meeting. (Changes to the next day if requires)
//			@AGQ080206	Changed the add/remove algorithm to a faster one 
//			@AGQ081606	Changed option to include meeting Type (e.g. public or private)
//			@AGQ081706	Support of displaying Contact List for OMF
//			@AGQ081806	Removed support of Projects when application is OMF
//			@SWS082206  Filter non-OMF related items, add option to start meetings immediately,
//						and finish setup meeting from this page.
//			@AGQ091206	Detect error emails 
//			@SWS101606  Save agenda entered in mtg_new2.
//			@ECC110206	Add Description attribute.
//			@ECC121806	Allow choosing contacts from my companies.
// 
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import="util.*"%>
<%@ page import="oct.codegen.*"%>
<%@ page import="oct.omm.common.*"%>
<%@ page import="oct.omm.client.*"%>
<%@ page import="oct.omm.db.*"%>
<%@ page import="oct.pst.*"%>
<%@ page import="oct.pmp.exception.*"%>
<%@ page import="oct.util.general.*"%>
<%@ page import="java.util.*"%>
<%@ page import="java.io.*"%>
<%@ page import="java.text.*"%>

<%@ taglib uri="/pmp-taglib" prefix="pmp"%>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

////////////////////////////////////////////////////////

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	String HOST = Util.getPropKey("pst", "PRM_HOST");

	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ( (iRole & user.iROLE_ADMIN) > 0 )
		isAdmin = true;

	// to check if session is OMF or PRM
	boolean isOMFAPP = Prm.isOMF();
	String appS = Prm.getAppTitle();
	
	String label1;
	if (isOMFAPP) label1 = "Circle";
	else label1 = "Company";
	
	String startNow = request.getParameter("StartNow"); // @SWS082206 to check if meeting starts immediately
	boolean isNow = false;
	if (startNow != null && startNow.equals("true")) 
		isNow = true;
	String nextButton="";
	String action="";
	String finish="";
	String hide="";
	if (isNow)
	{
		nextButton=" value='  Start Meeting  ' ";
		action=" action='post_mtg_new.jsp' ";
		hide=" Style='display:none' ";
	}
	else
	{
		nextButton=" value='  Agenda >>  ' ";
		action=" action='mtg_new2.jsp' ";
		finish="<input type='button' class='button_medium' value='  Finished  ' onclick='finish();'>&nbsp;";
	} // @SWS082206 ends
	
	Vector rAgenda = null;
	session.setAttribute("agenda", rAgenda);
	
	int myUid = pstuser.getObjectId();

	// @ECC100605 check to see if it is creating followup meeting
	String s;
	String [] sa;
	PstAbstractObject obj;
	meetingManager mMgr = meetingManager.getInstance();
	projectManager pjMgr = projectManager.getInstance();
	userManager uMgr = userManager.getInstance();
	userinfoManager uiMgr = userinfoManager.getInstance();
	townManager tnMgr = townManager.getInstance();
	confManager cfMgr = confManager.getInstance();
	
	userinfo myUI = (userinfo) uiMgr.get(pstuser, String.valueOf(myUid));
	TimeZone myTimeZone = myUI.getTimeZone();
	int myTimeZoneOffset = myUI.getTimeZoneIdx();

	SimpleDateFormat df1 = new SimpleDateFormat ("MM/dd/yyyy");
	SimpleDateFormat df2 = new SimpleDateFormat ("H:mm");
	SimpleDateFormat df3 = new SimpleDateFormat ("yyyy/MM/dd");
	SimpleDateFormat df4 = new SimpleDateFormat ("yyyy/M/d H:mm");
	SimpleDateFormat df5 = new SimpleDateFormat ("M/d/yyyy H:mm");
	if (!userinfo.isServerTimeZone(myTimeZone)) {
		df1.setTimeZone(myTimeZone);
		df2.setTimeZone(myTimeZone);
		df3.setTimeZone(myTimeZone);
		df4.setTimeZone(myTimeZone);
		df5.setTimeZone(myTimeZone);
	}
	
	String lastMtgIdS = request.getParameter("mid");
	String subj = null;
	String loc = null;
	
	// time
	int duration = 60;		// default meeting duration: 60 min
	String stTimeS = null;
	String exTimeS = null;

	if (!StringUtil.isNullOrEmptyString(lastMtgIdS))
	{
		// @ECC100605
		// follow-up meeting (caller passing in mid)
		obj = mMgr.get(pstuser, lastMtgIdS);
		loc = (String)obj.getAttribute("Location")[0];
		//loc = Util.stringToHex(loc);
		
		// automatic bump followup meeting number
		subj = (String)obj.getAttribute("Subject")[0];
		if (subj.endsWith(")")) {
			int idx = subj.lastIndexOf('(') + 1;
			s = subj.substring(idx, subj.length() - 1);
			try {
				int num = Integer.parseInt(s);
				subj = subj.substring(0, idx) + (num + 1) + ")";
			} 
			catch (NumberFormatException e) {}
		} 
		
		else {
			subj += " (2)"; // second meeting by default
		}

		// meeting start and end time (not date)
		Date dt = (Date) obj.getAttribute("StartDate")[0];
		//dt = new Date(dt.getTime() + userinfo.getServerUTCdiff());
		stTimeS = df2.format(dt);
		Date dt1 = (Date) obj.getAttribute("ExpireDate")[0];
		//dt = new Date(dt.getTime() + userinfo.getServerUTCdiff());
		exTimeS = df2.format(dt1);
		duration = (int) (dt1.getTime() - dt.getTime()) / 60000; // in min
	} 
	else {
		lastMtgIdS = request.getParameter("Lastmid");
	}

	// when I get to here, I am either from a truly NEW MEETING call or I am called by ECC100605
	String lastProjIdS = null;
	ArrayList mandatoryIds = new ArrayList();
	ArrayList optionalIds = new ArrayList();
	String desc = null;
	String company = null;
	String meetingType = request.getParameter("meetingType"); // use this to detact if I am from mtg_new2.jsp

	if (lastMtgIdS != null && lastMtgIdS.length() > 0) {
		obj = mMgr.get(pstuser, lastMtgIdS);
		lastProjIdS = (String) obj.getAttribute("ProjectID")[0];

		// get attendee list
		Object[] attendeeArr = obj.getAttribute(meeting.ATTENDEE);

		for (int i = 0; i < attendeeArr.length; i++) {
			s = (String) attendeeArr[i];
			if (s == null)
				break;
			sa = s.split(meeting.DELIMITER);

			if (sa[1].startsWith(meeting.ATT_MANDATORY))
				mandatoryIds.add(sa[0]);
			else
				optionalIds.add(sa[0]);
		}

		if (meetingType == null) {
			// not coming from mtg_view2.jsp: get value from pass in meeting if there is one
			// get description
			Object bTextObj = obj.getAttribute("Description")[0];
			desc = (bTextObj == null) ? "" : new String(
					(byte[]) bTextObj, "utf-8");
			desc = desc.replaceAll("<br>", "\n");

			// company and type
			company = (String) obj.getAttribute("TownID")[0];
			meetingType = (String) obj.getAttribute("Type")[0];
		}
	} else {
		// new meeting
		lastMtgIdS = "";
	}

	if (mandatoryIds.size() == 0)
		mandatoryIds.add(String.valueOf(myUid)); // default to include me

	// Perform a check to see if MandatoryId already exist, if it does replace the current arraylist
	String[] manAttArr = request
			.getParameterValues("MandatoryAttendee");
	String[] optAttArr = request.getParameterValues("OptionalAttendee");
	int manAttArrLength = (manAttArr != null) ? manAttArr.length : 0;
	int optAttArrLength = (optAttArr != null) ? optAttArr.length : 0;
	if (manAttArrLength > 0) {
		mandatoryIds.clear();
		for (int i = 0; i < manAttArrLength; i++) {
			mandatoryIds.add(manAttArr[i]);
		}
	}
	if (optAttArrLength > 0) {
		optionalIds.clear();
		for (int i = 0; i < optAttArrLength; i++) {
			optionalIds.add(optAttArr[i]);
		}
	}

	//////////////////////////////////////////////////////////
	// project
	String projName;
	String selectedProjIdS = null;

	String projectS = request.getParameter("ProjectId");

	if (!StringUtil.isNullOrEmptyString(projectS)) {
		selectedProjIdS = projectS;
	} 
	else if (!StringUtil.isNullOrEmptyString(lastProjIdS)) {
		selectedProjIdS = lastProjIdS;
	} 
	else {
		selectedProjIdS = (String) session.getAttribute("projId");
	}

	if (selectedProjIdS != null)
		projName = ((project) pjMgr.get(pstuser,
				Integer.parseInt(selectedProjIdS))).getDisplayName();
	else
		projName = "";

	// for OMF, SelectGroup can be company (town) id
	// get the current form values
	int projTeamId = -2;
	s = request.getParameter("SelectGroup");
	if (s != null && s.length() > 0)
		projTeamId = Integer.parseInt(s);
	else if (s == null && isOMFAPP)
		projTeamId = 0;
	else if (selectedProjIdS != null)
		projTeamId = Integer.parseInt(selectedProjIdS);

	if (subj == null) {
		subj = request.getParameter("Subject");
		if (subj == null)
			subj = "";
		if (isNow) {
			subj = (String) pstuser.getAttribute("FirstName")[0];
			subj = subj.concat("'s meeting");
		}
	}

	if (loc == null) {
		loc = request.getParameter("Location");
		if (loc == null)
			loc = "";
	}

	int confRoomId = 0;
	s = request.getParameter("confRoomSelect");
	if (!StringUtil.isNullOrEmptyString(s))
		if (s.equals("other"))
			confRoomId = -1;
		else
			confRoomId = Integer.parseInt(s);

	// date
	String initialDate = request.getParameter("D");

	String mtgDateS = request.getParameter("StartDate");
	String mtgDateES = request.getParameter("ExpireDate");
	if (mtgDateS == null && initialDate != null)
		mtgDateS = df1.format(df3.parse(initialDate)); // check to see if Start Date is passed in

	// time
	if (stTimeS == null) {
		stTimeS = request.getParameter("StartTime");
		exTimeS = request.getParameter("ExpireTime");
		s = request.getParameter("Duration");
		if (!StringUtil.isNullOrEmptyString(s))
			duration = Integer.parseInt(s);
	}

	// recur
	int recurMult = 1;
	String recurS = request.getParameter("Recurring");
	if (recurS == null)
		recurS = "";
	s = request.getParameter("RecurMultiple");
	if (s != null && s.length() > 0 && !s.equals("null"))
		recurMult = Integer.parseInt(s);

	// @ECC030309
	String recur1 = request.getParameter("Recur1");
	String recur2 = request.getParameter("Recur2");
	String recur3 = request.getParameter("Recur3");
	String recur4 = request.getParameter("Recur4");
	String recur5 = request.getParameter("Recur5");
	String recurSun = request.getParameter("RecurSun");
	String recurMon = request.getParameter("RecurMon");
	String recurTue = request.getParameter("RecurTue");
	String recurWed = request.getParameter("RecurWed");
	String recurThu = request.getParameter("RecurThu");
	String recurFri = request.getParameter("RecurFri");
	String recurSat = request.getParameter("RecurSat");

	// @AGQ081606 Type public or private
	if (meetingType == null)
		meetingType = request.getParameter("meetingType");
	if (meetingType == null) {
		String defaultMtgType = Util.getPropKey("pst",
				"MEETING_DEFAULT_TYPE");
		if (defaultMtgType == null
				|| defaultMtgType.equalsIgnoreCase(meeting.PRIVATE))
			meetingType = meeting.PRIVATE;
		else
			meetingType = meeting.PUBLIC;
	}

	// @ECC102706
	if (company == null) {
		company = request.getParameter("company");
		if (company != null
				&& (company.length() <= 0 || company.equals("null")))
			company = null;
	}

	// Category
	String type = request.getParameter("Type");
	String templateName = request.getParameter("TemplateName");

	String optMsg = request.getParameter("message");
	String location = request.getParameter("location");
	String confRoomSelect = request.getParameter("confRoomSelect");
	String agendaS = request.getParameter("Agenda"); // @SWS101606
	if (agendaS == null || agendaS.length() <= 0)
		agendaS = "";

	PstAbstractObject[] mtgMember = null;
	PstAbstractObject[] dlArr = null;
	dlManager dlMgr = dlManager.getInstance();

	// dl 
	if (projTeamId == -1) {
		dlArr = dlMgr.getDLs(pstuser);
		Util.sortName(dlArr);
	}
	// all users
	else if (projTeamId == 0 && !isOMFAPP)
		mtgMember = ((user) pstuser).getAllUsers();
	else if (projTeamId == 0 && isOMFAPP) {
		Object[] objArr = pstuser.getAttribute(user.TEAMMEMBERS);
		if (objArr[0] != null) {
			mtgMember = uMgr.get(pstuser, objArr);
			Util.sortUserArray(mtgMember, true);
		} 
		else
			mtgMember = new PstAbstractObject[0];
	} 
	else if (projTeamId > 0) {
		if (!isOMFAPP)
			mtgMember = ((user) pstuser).getTeamMembers(projTeamId);
		else {
			// ECC121806: for OMFAPP, support choosing contacts from my companies
			int[] ids = uMgr.findId(pstuser, "Towns=" + projTeamId);
			mtgMember = uMgr.get(pstuser, ids);
		}
	}

	// @ECC110206 Description
	String DEFAULT_TXT = ">> Enter a short paragraph to describe this meeting.  You may edit this later.";
	String descStr = "";
	if (desc != null)
		descStr = desc;
	else
		descStr = Util.stringToHTMLString(request
				.getParameter("Description"));
	if (descStr == null)
		descStr = DEFAULT_TXT;

	////////////////////////
	// @ECC102706
	int[] ids = null;
	Object[] myTownIds = pstuser.getAttribute("Towns");
	PstAbstractObject[] tnArr = null;
	if (myTownIds[0] != null) {
		if (myTownIds[0] != null) {
			ids = new int[myTownIds.length];
			for (int i = 0; i < myTownIds.length; i++)
				ids[i] = ((Integer) myTownIds[i]).intValue();
		}
		tnArr = tnMgr.get(pstuser, ids);
		Util.sortString(tnArr, "Name", true);
	}

	////////////////////////////////////////////////////////

	String roomName;
	PstAbstractObject[] roomArr = new PstAbstractObject[0];

	long d = 0;
	final long oneMinInMillis = 60000;
	Date stDateReq = null, exDateReq = null;
	s = request.getParameter("stDt");
	if (s != null)
		stDateReq = new Date(d);
	s = request.getParameter("enDt");
	if (s != null)
		exDateReq = new Date(d);

	Date now = new Date();
	boolean bHasChangedDate = (initialDate == null);

	if (!bHasChangedDate || mtgDateS==null) { // initialDate != null
		// when I first come in, "D" is passed in, use my current time to set meeting
		initialDate = df1.format(now);
		
		Calendar cal = Calendar.getInstance(myTimeZone);
		int hour24 = cal.get(Calendar.HOUR_OF_DAY);
		int min = cal.get(Calendar.MINUTE);
		String minS = "00";
		if (min > 15 && min < 45)
			minS = "30";
		else if (min >= 45)
			hour24++;
		int idx = initialDate.indexOf(' ');
		if (idx != -1)
			initialDate = initialDate.substring(0, idx);
		//System.out.println(initialDate + " " + hour24 + ":" + minS);

		stDateReq = df4.parse(initialDate + " " + hour24 + ":" + minS);
		long t = stDateReq.getTime();
		exDateReq = new Date(t + (60 * oneMinInMillis));
	}

	else {
		// called when the date/time/duration got changed
		// when the date, time or duration is changed, need to evaluate the stDateReq

		stDateReq = df5.parse(mtgDateS + " " + stTimeS);
		long t = stDateReq.getTime();
		exDateReq = new Date(t + (duration * oneMinInMillis));
	}
	roomArr = conf.getAvailableConf(pstuser, stDateReq, exDateReq);

	// check if I should open invite panel
	s = request.getParameter("invite");
	boolean bOpenInvitePanel = (s != null && s.equals("1"));
%>


<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<link href="../oct-basic.css" rel="stylesheet" type="text/css"
	media="screen" />
<link href="../oct-print.css" rel="stylesheet" type="text/css"
	media="print" />
<jsp:include page="../init.jsp" flush="true" />
<jsp:include page="../formsM.jsp" flush="true" />
<script language="JavaScript" src="../get-date.js"></script>
<script language="JavaScript" src="../date.js"></script>
<script language="JavaScript" src="../util.js"></script>

<script language="JavaScript">

<!--

window.onload = function()
{
	checkMonthly();
	fo();

	if ("<%=bOpenInvitePanel%>"=="true") {
		togglePanel("InvitePanel", "Invite", "Hide invite");
	}
}

function fo()
{
	Form = document.newMeeting;
	for (i=0;i < Form.length;i++)
	{
		if (Form.elements[i].type != "hidden")
		{
			Form.elements[i].focus();
			break;
		}
	}
	// @AGQ031006
	sortSelect(document.getElementById("Select1"));
	sortSelect(document.getElementById("Select2"));
	sortSelect(document.getElementById("MandatoryAttendee"));
	sortSelect(document.getElementById("OptionalAttendee"));
}

function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

function validation()
{
	var f = document.newMeeting;
	if (f.Subject.value =='')
	{
		fixElement(f.Subject,
			"Please make sure that the SUBJECT field is properly completed.");
		return false;
	}

	var subject = f.Subject.value;
	for (i=0;i<subject.length;i++) {
		char = subject.charAt(i);
		if (char == '\\') {
			fixElement(f.Subject,
				"SUBJECT cannot contain these characters: \n  \\");
			return false;
		}
	}
	
	
	// store location depending on input
	var location;
	if (!f.Location.disabled) {
		location = f.Location.value;
		for (i=0;i<location.length;i++) {
			char = location.charAt(i);
			if (char == '\\') {
				fixElement(f.Location,
					"LOCATION cannot contain these characters: \n  \\");
				return false;
			}
		}
	}
	
	
	// check on recurring
	if (f.Recurring.value != "")
	{
		var recur = f.RecurMultiple.value;
		var ival = parseInt(recur);
		if (ival < 2)
		{
			fixElement(f.RecurMultiple,
			"You have to choose at least two occurrence for recurring to be meaningful.");
			return false;
		}
		if (ival > 10)
		{
			fixElement(f.RecurMultiple,
				"You cannot create more than 10 recurring meetings.");
			return false;
		}

		// for monthly and weekly, must check mon, tue, etc.
		if (f.Recurring.value == '<%=meeting.MONTHLY%>' || f.Recurring.value == '<%=meeting.WEEKLY%>')
		{
			if (!f.RecurSun.checked && !f.RecurMon.checked && !f.RecurTue.checked && !f.RecurWed.checked
					&& !f.RecurThu.checked && !f.RecurFri.checked && !f.RecurSat.checked)
			{
				fixElement(f.RecurSun, "Select the day(s) of week to be recurring.");
				return false;
			}
		}

		// for monthly, also need to check 1st, 2nd, etc. week.
		if (f.Recurring.value == '<%=meeting.MONTHLY%>')
		{
			if (!f.Recur1.checked && !f.Recur2.checked && !f.Recur3.checked && !f.Recur4.checked && !f.Recur5.checked)
			{
				fixElement(f.RecurSun, "To set monthly meetings, specify which week(s) you want the recurring event to occur.");
				return false;
			}
		}
	}

	var guestEmail = f.guestEmails.value;
	for (i=0;i<guestEmail.length;i++) {
		char = guestEmail.charAt(i);
		if (char == '\\') {
			fixElement(f.guestEmails,
				"INVITE GUESTS cannot contain these characters: \n  \\");
			return false;
		}
	}
	
	guestEmail = guestEmail.replace(new RegExp("[,;]", "g"), " ");
	var guestEmailArr = guestEmail.split(" ");
	for (var i=0; i < guestEmailArr.length; i++) {
		if (trim(guestEmailArr[i]).length > 0) {
			if (!checkMail(guestEmailArr[i])) {
				alert("'" + guestEmailArr[i] + "' is not a valid email address, \nplease correct the error and submit again.");
				return false;
			}
		}
	}
	
	if ((f.MandatoryAttendee.options.length + f.OptionalAttendee.options.length) == 0) {
		fixElement(f.MandatoryAttendee, 
			"Please make sure there are attendees for this meeting");
		return false;
	}

	// date and time
	var now = new Date();
	var today = new Date(now.getFullYear(),now.getMonth(),now.getDate());
	var start = new Date(f.StartDate.value);

	if (start < today)
	{
		if (!confirm("This meeting event is in the past, do you really want to set this meeting?"))
			return false;
	}

	// ECC: the start time would be right if it is the same as the CPM server timezone
	// but otherwise this would be wrong.  StartDT is used to create meeting StartDate in post file.
	var dt = new Date(f.StartDate.value + " " + f.StartTime.value);
	var tm = dt.getTime();
	f.StartDT.value = tm;			// simply pass the msec as a string	
	f.ExpireDT.value = tm + f.Duration.value*60000;


	var s = '';
	for (i=0; i<f.MandatoryAttendee.length; i++)
	{
		if (s != '') s += ";";
		s += f.MandatoryAttendee.options[i].value;
	}
	f.Mandatory.value = s;

	s = '';
	for (i=0; i<f.OptionalAttendee.length; i++)
	{
		if (s != '') s += ";";
		s += f.OptionalAttendee.options[i].value;
	}
	f.Optional.value = s;

	var desc = f.Description.value;
	if (desc.substring(0,2) == ">>")
		f.Description.value = '';
	for (i=0;i<desc.length;i++) {
		char = desc.charAt(i);
		if (char == '"') {
			fixElement(f.Description,
				"DESCRIPTION cannot contain double quote (\")");
			return false;
		}
	}

	selectAll(f.MandatoryAttendee);
	selectAll(f.OptionalAttendee);
	
	return true; // @SWS082206
}

function doclear(e)
{
	if (e.value.substring(0,2) == ">>")
		e.value = '';
	return;
}

function defaultText(e)
{
	if (e.value == '')
		e.value = '<%=DEFAULT_TXT%>';
	return;
}

function show_cal(e1, e2)
{
	var dt;
	if (e2 == null) e2 = e1;
	if (e1.value!=null && e1.value!='')
		dt = new Date(e1.value);
	else
		dt = new Date();
	var mon = '' + dt.getMonth();
	var yr = '' + dt.getFullYear();
	if (yr.length==2) yr = '20' + yr;		// 13 change to 2013
	else if (yr.length==1) yr = '200' + yr;	// because 05 will become 5
	var es = 'newMeeting.' + e1.name;
	var es2 = null;
	if (e2 != null )
	{
		es2 = 'newMeeting.' + e2.name;
	}
	var number = parseInt(mon);
	var number2 = parseInt(yr);
// @AGQ050406a
	if (isNaN(number) || isNaN(number2)) {
		dt = new Date();
		mon = '' + dt.getMonth();
		yr = '' + dt.getFullYear();
	}
	show_calendar(es, mon, yr, null, es2);
}

var nextDay = false;

function changeTeam(op)
{
	if (op==1)
		newMeeting.SelectGroup.value = newMeeting.ProjectId.value;
	selectAll(document.getElementById("MandatoryAttendee"));
	selectAll(document.getElementById("OptionalAttendee"));

	newMeeting.invite.value = "1";
	
	document.newMeeting.action = "mtg_new1.jsp";
	document.newMeeting.submit();
}

function selectAll(select) {
	var length = select.length;
	for(var i = 0; i < length; i++) {
		select.options[i].selected = true;
	}
}

function finish()
{ // @SWS082206
	if (!validation()){
		return false;
		}
	var origin = document.getElementsByName("Origin")[0];
	origin.value = "mtg_new1";
	document.newMeeting.action = "post_mtg_new.jsp";

	document.newMeeting.submit();
}

function setPublic(public)
{
	if (newMeeting.company == undefined)
		return;
	if (public)
		newMeeting.company.disabled = true;
	else
		newMeeting.company.disabled = false;
}

function checkMonthly()
{
	var e1 = document.getElementById("recurMonthWeek");
	var e2 = document.getElementById("recurMonth");
	var val = newMeeting.Recurring.value; 
	if (val == "<%=meeting.MONTHLY%>")
	{
		e1.style.display = 'block';
		e2.style.display = 'block';
	}
	else if (val == "<%=meeting.WEEKLY%>")
	{
		e1.style.display = 'block';
		e2.style.display = 'none';
	}
	else
	{
		e1.style.display = 'none';
		e2.style.display = 'none';
	}
	if (val == "")
		newMeeting.RecurMultiple.disabled = true;
	else
		newMeeting.RecurMultiple.disabled = false;
}

function selectConfRoom()
{
	var e1 = document.getElementById("Location")
	var e2 = document.getElementById("confRoomSelect");
	if (e2.value == "other") {
		e1.disabled = false;
	}
	else {
		e1.value = "";
		e1.disabled = true;
	}
}

function changeDate()
{
	var f = document.newMeeting;
	f.action = "mtg_new1.jsp";
	f.submit();
}

//-->
</script>

<style type="text/css">
.plaintext_blue {
	line-height: 30px
}

.formtext {
	font-size: 12px;
}
</style>

</head>

<title><%=appS%> New Meeting</title>
<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0"
	marginheight="0">
	<table width="100%" height="100%" border="0" cellspacing="0"
		cellpadding="0">
		<tr>
			<td valign="top">
				<!-- Main Tables -->
				<table width="100%" border="0" cellspacing="0" cellpadding="0">
					<tr>
						<td width="100%" valign="top">
							<!-- Top --> <jsp:include page="../head.jsp" flush="true" /> <!-- End of Top -->
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
						<td width="754" height="30" align="left" valign="bottom"
							class="head"><b>Schedule a Meeting</b></td>
					</tr>
				</table>
			</td>
		</tr>
		<tr>
			<td width="100%">
				<!-- Navigation Menu --> <jsp:include page="<%=Prm.getTabFile()%>"
					flush="true">
					<jsp:param name="cat" value="Event" />
					<jsp:param name="subCat" value="NewMeeting" />
					<jsp:param name="role" value="<%=iRole%>" />
				</jsp:include> <!-- End of Navigation SUB-Menu -->
			</td>
		</tr>
	</table>
	<!-- Content Table -->

	<table width="100%" border="0" cellspacing="0" cellpadding="0">
		<tr>
			<td colspan="2">&nbsp;</td>
		</tr>

		<form method="post" name="newMeeting" id="newMeeting" <%=action%>>
			<input type="hidden" name="Mandatory" value="" /> <input
				type="hidden" name="Optional" value="" />
			<!-- input type="hidden" name="LocalStartDT" value=""/-->
			<input type="hidden" name="StartDT" value="" /> <input type="hidden"
				name="ExpireDT" value="" /> <input type="hidden" name="Lastmid"
				value="<%=lastMtgIdS%>" /> <input type="hidden" name="Agenda"
				value="<%=agendaS%>" /> <input type="hidden" name="Origin" value="" />
			<input type="hidden" name="StartNow" value="<%=isNow%>" /> <input
				type="hidden" name="message" value="<%=optMsg%>" /> <input
				type='hidden' name='ExpireDate' value='' /> <input type='hidden'
				name='invite' value='' />



			<%-- @AGQ081506 --%>
			<%
				if (type != null) {
			%>
			<input type="hidden" name="Type" value="<%=type%>" /> <input
				type="hidden" name="TemplateName" value="<%=templateName%>" />
			<%
				}
			%>
			<tr>
				<td width="15">&nbsp;</td>
				<td colspan=2 class="instruction_head" <%=hide%>><br><b>Step
							1 of 3: Enter Meeting Information</b></td>
			</tr>

			<tr>
				<td width="20">&nbsp;</td>
				<td colspan=2 class="instruction"><br>Please note that
						fields marked with an * are required.<br><br></td>
			</tr>

			<!-- Subject -->
			<tr>
				<td width="20">&nbsp;</td>
				<td width='200' class="plaintext_blue"><font color="#000000">*</font>
					Subject:</td>
				<td><input class="formtext" type="text" style='width: 650px'
					name="Subject" value='<%=Util.stringToHTMLString(subj)%>'></td>
			</tr>

			<!-- start date -->
			<tr <%=hide%>>
				<td width="20">&nbsp;</td>
				<td class="plaintext_blue"><font color="#000000">*</font> Start Time:</td>
				<td><script language="JavaScript">
<!-- Begin
	var sTD = '<%=mtgDateS%>';
	var eTD = '<%=mtgDateES%>';
	if (sTD=="null" || sTD=="")
		sTD = "<%=df1.format(new Date())%>";	//formatDate(new Date(), "MM/dd/yyyy");
	if (eTD=="null" || eTD=="")
		eTD = sTD;	
	document.write("<input class='formtext' type='Text' name='StartDate' size='25' onClick='show_cal(newMeeting.StartDate, newMeeting.ExpireDate)' onchange='changeDate();' ");
	document.write("value='" + sTD + "'>&nbsp;");
// End -->
</script>

	<a href='javascript:show_cal(newMeeting.StartDate, newMeeting.ExpireDate);'>
		<img src="../i/calendar.gif" border="0" align="absmiddle" alt="Click to view calendar." />
		</a> &nbsp;&nbsp; <select class="formtext" name="StartTime" onchange='changeDate();'>

<script language="JavaScript">
<!-- Begin

	var stTS = '<%=stTimeS%>';
			var hr = 0;
			var stMin = 0;
			var displayMins = "00";
			if (stTS == "null" || stTS == "") {
				localDt = getLocalDate(new Date(), <%=myTimeZoneOffset%>);
				hr = localDt.getHours();
				stMin = localDt.getMinutes();
				if (stMin > 15 && stMin < 45)
					displayMins = "30";
				else if (stMin >= 45)
					hr++;
				stTS = hr + ":" + displayMins;
				if (hr > 23) {
					var f = document.newMeeting;
					var startDate = getDateFromFormat(
							f.StartDate.value, "MM/dd/yyyy");
					startDate = getLocalDate(new Date(
							startDate + 86400000), <%=myTimeZoneOffset%>);
					f.StartDate.value = formatDate(startDate,"MM/dd/yyyy");
				}
			}

			var t = 11;
			//var half = false;
			var m = "00";
			for (i = 0; i < 96; i++) // 12*4
			{
				var ts = (t % 12 + 1) + ":";
				var val = ((t - 11) % 24) + ":";
				/*if (half) {ts += "30"; val += "30"; t++;}
				else {ts += "00"; val += "00";}*/

				ts += m;
				val += m;
				if (m == "00")
					m = "15";
				else if (m == "15")
					m = "30";
				else if (m == "30")
					m = "45";
				else if (m == "45") {
					m = "00";
					t++
				}

				if (i < 48)
					ts += " AM";
				else
					ts += " PM";
				document.write("<option value='" + val + "'");
				if (stTS == val)
					document.write(" selected");
				document.write(">" + ts + "</option>");
				//half = !half;
			}
// End -->
</script>

		</select> <span class='plaintext_blue'> <img src='../i/spacer.gif'
				width='100' height='1' /> Duration: <select class='formtext'
				name='Duration' onchange='changeDate();'>
<%
	for (int i = 1; i <= 20; i++) {
		int val = i * 15; // min
		String valS = Util3.getTimeString(val);
		out.print("<option value='" + val + "'");
		if (duration == val)
			out.print(" selected");
		out.print(">" + valS + "</option>");
	}
%>
			</select>
		</span></td>
	</tr>

	<tr>
		<td colspan='2'></td>
		<td class='plaintext'>(<%=myUI.getZoneString()%>)
		</td>

	</tr>


<%
	////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////
	// panel for meeting info
	out.print("<tr><td colspan='3'>");
	out.print(Util.getHeaderPartitionLine());
	out.print("<img id='ImgInfoPanel' src='../i/bullet_tri.gif'/>");
	out.print("<a id='AInfoPanel' href='javascript:togglePanel(\"InfoPanel\", \"Meeting info\", \"Hide meeting info\");' class='listlinkbold'>Meeting info</a>");

	out.print("<DIV id='DivInfoPanel' style='display:none;'>");
	out.print("<table border='0' cellspacing='0' cellpadding='0' width='100%'>"); // Info panel table
%>
		<tr>
			<td><img src='../i/spacer.gif' height='20' width='1' /></td>
		</tr>


		<!-- @ECC110206 Description -->
		<tr <%=hide%>>
			<td width="20">&nbsp;</td>
			<td class="plaintext_blue" valign='top'=>&nbsp;&nbsp;&nbsp;Description:</td>
			<td class="formtext"><textarea name="Description"
					wrap="physical" onFocus="return doclear(this);"
					onBlur="return defaultText(this);" style='width: 650px;' rows="4"><%=descStr%></textarea>
			</td>
		</tr>

		<tr>
			<td colspan='3'><img src='../i/spacer.gif' height='5'/></td>
		</tr>


	<!-- Recurring -->
	<tr <%=hide%>>
		<td width="20">&nbsp;</td>
		<td class="plaintext_blue">&nbsp;&nbsp;&nbsp;Recurring Event:</td>
		<td class="formtext"><select class="formtext" name="Recurring"
			onChange='checkMonthly();'>
				<option value=''>- Not recurring -</option>
				<%
					for (int i = 0; i < meeting.RECUR_ARR.length; i++) {
						out.print("<option value='" + meeting.RECUR_ARR[i] + "'");
						if (recurS.equals(meeting.RECUR_ARR[i]))
							out.print(" selected");
						out.print(">" + meeting.RECUR_ARR[i] + "</option>");
					}
				%>
		</select> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;End after: <select class="formtext"
			name="RecurMultiple" disabled>
				<%
					for (int i = 1; i <= 10; i++) {
						out.print("<option value='" + i + "'");
						if (recurMult == i)
							out.print(" selected");
						out.print(">" + i + "</option>");
					}
					out.print("</select>");
				%> &nbsp;occurrences </td>
	</tr>

	<!-- Location -->
	<tr <%=hide%>>
		<td width="20">&nbsp;</td>
		<td class="plaintext_blue">&nbsp;&nbsp;&nbsp;Location:</td>
		<td><select id='confRoomSelect' name='confRoomSelect'
			class='formtext' onchange='selectConfRoom();'>
				<option value="">- select location -</option>
				<%
					String disabledLoc = "disabled";
					for (int i = 0; i < roomArr.length; i++) {
						out.print("<option value='" + roomArr[i].getObjectId() + "'>"
								+ roomArr[i].getStringAttribute("Name") + "</option>");
					}

					out.print("<option value ='other' ");
					if (confRoomId == -1) {
						disabledLoc = "";
						out.print("selected");
					}
					out.print(">other</option>");
				%>
		</select>&nbsp; <input class="formtext" type="text" id="Location"
			name="Location" size="20" value="<%=loc%>" <%=disabledLoc%> /></td>
	</tr>

	<tr>
		<td colspan='2'></td>
		<td>
			<div id="recurMonthWeek" style="display: none">
				<table border='0' cellspacing='0' cellpadding='0'>
					<tr>
						<td class='formtext' width='100'>Recur every:</td>
						<td class='formtext' width='400'>
							<div id='recurMonth' style='display: none'>
								<input type='checkbox' name='Recur1'
									<%if (recur1 != null && recur1.equals("on"))
		out.print("checked");%>>1st&nbsp;
									<input type='checkbox' name='Recur2'
									<%if (recur2 != null && recur2.equals("on"))
		out.print("checked");%>>2nd&nbsp;
										<input type='checkbox' name='Recur3'
										<%if (recur3 != null && recur3.equals("on"))
		out.print("checked");%>>3rd&nbsp;
											<input type='checkbox' name='Recur4'
											<%if (recur4 != null && recur4.equals("on"))
		out.print("checked");%>>4th&nbsp;
												<input type='checkbox' name='Recur5'
												<%if (recur5 != null && recur5.equals("on"))
		out.print("checked");%>>5th&nbsp;
											
							</div>
						</td>
					</tr>
					<tr>
						<td colspan='2'>
							<table border='0' cellspacing='0' cellpadding='0'>
								<tr>
									<td><img src='../i/spacer.gif' width='10' /></td>
									<td class='formtext' width='90'><input type='checkbox'
										name='RecurSun'
										<%if (recurSun != null && recurSun.equals("on"))
		out.print("checked");%>>Sunday</td>
									<td class='formtext' width='90'><input type='checkbox'
										name='RecurMon'
										<%if (recurMon != null && recurMon.equals("on"))
		out.print("checked");%>>Monday</td>
									<td class='formtext' width='90'><input type='checkbox'
										name='RecurTue'
										<%if (recurTue != null && recurTue.equals("on"))
		out.print("checked");%>>Tuesday</td>
									<td class='formtext' width='90'><input type='checkbox'
										name='RecurWed'
										<%if (recurWed != null && recurWed.equals("on"))
		out.print("checked");%>>Wednesday</td>
								</tr>
								<tr>
									<td></td>
									<td class='formtext'><input type='checkbox'
										name='RecurThu'
										<%if (recurThu != null && recurThu.equals("on"))
		out.print("checked");%>>Thursday</td>
									<td class='formtext'><input type='checkbox'
										name='RecurFri'
										<%if (recurFri != null && recurFri.equals("on"))
		out.print("checked");%>>Friday</td>
									<td class='formtext'><input type='checkbox'
										name='RecurSat'
										<%if (recurSat != null && recurSat.equals("on"))
		out.print("checked");%>>Saturday</td>
									<td></td>
								</tr>
							</table>
						</td>
					</tr>
				</table>
			</div>
		</td>
	</tr>


<%
	//////////////////////////////////////////////
	// Associated Project

	if (!isOMFAPP) {

		out.print("<tr><td colspan='3'><img src='../i/spacer.gif' height='5'></td></tr>");

		out.print("<tr><td width='20'>&nbsp;</td>");
		out.print("<td width='200' class='plaintext_blue'>&nbsp;&nbsp;&nbsp;Project:</td>");
		out.print("<td><select name='ProjectId' class='formtext' onchange='changeTeam(1);'>");

		out.println("<option value=''>- select project name -</option>");

		int[] projectObjId = pjMgr.getProjects(pstuser);
		if (projectObjId.length > 0) {
			PstAbstractObject[] projectObjList = pjMgr.get(pstuser,
					projectObjId);
			Util.sortName(projectObjList, true);

			String pName;
			project pj;
			Date expDate;
			String expDateS = new String();
			for (int i = 0; i < projectObjList.length; i++) {
				// project
				pj = (project) projectObjList[i];
				pName = pj.getDisplayName();

				out.print("<option value='" + pj.getObjectId() + "' ");
				if (pName.equals(projName))
					out.print("selected");
				out.print(">" + pName + "</option>");
			}
		}

		out.print("</select>");
		out.print("</td></tr>");
		out.print("<tr><td><img src='../i/spacer.gif' height='2' /></td></tr>");
	} else {
		out.println("<input type='hidden' name='ProjectId' value=''>");
	}

	//////////////////////////////
	// privacy type
	String checked = "";
	String disabled = "";
	if (meetingType.equalsIgnoreCase(meeting.PUBLIC)) {
		checked = "CHECKED='CHECKED'";
		disabled = "disabled";
	}

	String typeTooltip = "title='Public meeting is open for all "
			+ appS + " members"
			+ "\nPrivate meeting is only open for invitees'";

	// @ECC102706 (company is the same as circle)
	String companyTooltip = "";
	String companyName = null;
	if (myTownIds[0] != null) {
		//if (company==null || !company.equals("personal")) company = myTownIdS;
		//companyName = tnMgr.get(pstuser, Integer.parseInt(myTownIdS)).getObjectName();
		if (company == null)
			company = myTownIds[0].toString(); // default to first company
		companyTooltip = "title='Circle meeting can be seen by members of the Circle"
				+ "\nwhile Personal meeting is only seen by meeting invitees'";
	} else if (company == null)
		company = "0"; // personal
%>
	<tr>
		<td width="20">&nbsp;</td>
		<td colspan='2'>
			<table border='0' cellspacing='0' cellpadding='0'>
				<tr>
					<td width='200' class="plaintext_blue"><font color="#000000">*</font>&nbsp;Privacy
						Type:</td>
					<td class="formtext" <%=typeTooltip%>><input type="radio"
						name="meetingType" value="<%=meeting.PUBLIC%>" <%=checked%>
						onClick='setPublic(true)'>Public &nbsp;
<%
 	checked = "";
 	if (meetingType.equalsIgnoreCase(meeting.PRIVATE)) {
 		checked = "CHECKED='CHECKED'";
 	}

 	out.print("<input type='radio' name='meetingType' value='"
 			+ meeting.PRIVATE + "' " + checked
 			+ " onClick='setPublic(false)'>Private &nbsp;");

 	checked = "";
 	if (meetingType.equalsIgnoreCase(meeting.PUBLIC_READ_URL)) {
 		checked = "CHECKED='CHECKED'";
 	}
 	out.print("<input type='radio' name='meetingType' value='"
 			+ meeting.PUBLIC_READ_URL + "' " + checked
 			+ " onClick='setPublic(false)'>Public Read-only &nbsp;");

 	out.print("</td>");

 	if (myTownIds[0] != null) {
 %>
			<td><img src='../i/spacer.gif' width='110' height='1' /></td>
			<td width='80' class="plaintext_blue">&nbsp;<%=label1%>:
		</td>
			<td class="formtext" <%=companyTooltip%>><select
				name="company" class='formtext' <%=disabled%>>
					<option value='0'>Personal</option>
<%
		for (int i = 0; i < tnArr.length; i++) {
				int id = tnArr[i].getObjectId();
				companyName = (String) tnArr[i].getAttribute("Name")[0];
				out.print("<option value='" + id + "'");
				if (id == Integer.parseInt(company))
					out.print(" selected");
				out.print(">" + companyName + "</option>");
			}
			out.print("</select>");
		}
%>
									
				</tr>
			</table>
		</td>
	</tr>

	<tr>
		<td colspan="3">&nbsp;</td>
	</tr>

<%
	/////////////////////////////////////////
	// close meeting info panel
	out.print("</table></DIV>"); // END Info panel table
	out.print("</td></tr>");

	out.print("<tr><td colspan='3'><img src='../i/spacer.gif' height='5'></td></tr>");
%>

<%
	////////////////////////////////////////
	////////////////////////////////////////
	// invite panel
	out.print("<tr><td colspan='3'>");
	out.print(Util.getHeaderPartitionLine());
	out.print("<img id='ImgInvitePanel' src='../i/bullet_tri.gif'/>");
	out.print("<a id='AInvitePanel' href='javascript:togglePanel(\"InvitePanel\", \"Invite\", \"Hide invite\");' class='listlinkbold'>Invite</a>");

	out.print("<DIV id='DivInvitePanel' style='display:none;'>");
	out.print("<table border='0' cellspacing='0' cellpadding='0'>"); // invite panel table
%>

			<tr>
				<td><img src='../i/spacer.gif' height='20' width='1' /></td>
			</tr>

			<!-- Meeting Group -->
			<tr>
				<td width="20">&nbsp;</td>
				<td width='200' valign="top" class="plaintext_blue">&nbsp;&nbsp;&nbsp;Meeting
					Group:</td>
				<td class="formtext"><select class="formtext"
					name="SelectGroup" onchange="changeTeam(0);">
<%
	if (!isOMFAPP) {
%>
<option value=''>- Select Project Team -</option>
<%
	}
%>
<%
	out.print("<option value='-1'");
	if (projTeamId == -1)
		out.print(" selected");
	out.print(">* User List</option>");

	out.print("<option value='0'");
	if (projTeamId == 0)
		out.print(" selected");
	// @AGQ081706
	if (isOMFAPP) {
		// @ECC121806
		out.print(">My Friends</option>");
		//Object [] towns = pstuser.getAttribute("Towns");
		if (tnArr != null)
			for (int i = 0; i < tnArr.length; i++) {
				int tid = tnArr[i].getObjectId();
				out.print("<option value='" + tid + "'");
				if (projTeamId == tid)
					out.print(" selected");
				out.print(">"
						+ (String) tnArr[i].getAttribute("Name")[0]
						+ "</option>");
			}
	} else
		out.print(">All</option>");

	// for !isOMFAPP, use project to show contact lists
	int[] pjObjId = pjMgr.getProjects(pstuser);
	if (pjObjId.length > 0 && !isOMFAPP) {
		PstAbstractObject[] projectObjList = pjMgr
				.get(pstuser, pjObjId);
		//@041906SWS
		Util.sortName(projectObjList, true);

		project pj;
		int id;
		for (int i = 0; i < projectObjList.length; i++) {
			// project
			pj = (project) projectObjList[i];
			projName = pj.getDisplayName();
			id = pj.getObjectId();

			out.print("<option value='" + id + "'");
			if (id == projTeamId)
				out.print(" selected");
			out.print(">" + projName + "</option>");
		}
	}
	out.print("</select>");
%>
	<!-- End of Meeting Group -->
	<tr>
		<td colspan="3"><img src="../i/spacer.gif" width="5"
			height="3"></td>
	</tr>

	<!-- Mandatory Attendees -->
	<tr>
		<td width="20">&nbsp;</td>
		<td valign="top" class="plaintext_blue">&nbsp;&nbsp;&nbsp;Attendee:</td>
		<td>
			<!-- Mandatory -->
			<table border="0" cellspacing="0" cellpadding="0">
				<tr>
					<td><select class="formtext_fix" name="Select1"
						id="Select1" multiple size="5">
							<%
								boolean found;
								user u;
								String firstName, lastName, uName;
								ArrayList dlSelectList = new ArrayList(); // this list contain all members not on optional or mandatory list yet
								if (dlArr != null && dlArr.length > 0) {
									for (int i = 0; i < dlArr.length; i++) {
										if (dlArr[i] == null)
											continue;
										found = false;
										int memId = dlArr[i].getObjectId();
										for (int j = 0; j < mandatoryIds.size(); j++) {
											int id = dl.getId(mandatoryIds.get(j).toString());
											if (memId == id) {
												found = true;
												break;
											}
											// there are no more DL since the list is sorted
											else if (id == -1)
												break;
										}
										if (found)
											continue; // this member is in the mandatory list
										else {
											// check to see if the member is on the optional list
											for (int j = 0; j < optionalIds.size(); j++) {
												int id = dl.getId(optionalIds.get(j).toString());
												if (memId == id) {
													found = true;
													break;
												}
												// there are no more DL since the list is sorted
												else if (id == -1)
													break;
											}
										}
										if (found)
											continue; // this member is in the optional list

										// not yet on neither the mandatory nor optional list
										dlSelectList.add(dlArr[i]);
									}
								}
								//	 @AGQ022806
								String prevName = null;
								for (int i = 0; i < dlSelectList.size(); i++) {
									dl curDl = (dl) dlSelectList.get(i);
									String curName = curDl.getObjectName();
									if (prevName != null) {
										if (!prevName.equalsIgnoreCase(curName)) {
											out.print("<option value='" + dl.DLESCAPESTR
													+ curDl.getObjectId() + "'>* " + curName
													+ "</option>");
										}
									} else {
										out.print("<option value='" + dl.DLESCAPESTR
												+ curDl.getObjectId() + "'>* " + curName
												+ "</option>");
									}
									prevName = curName;
								}
								ArrayList selectList = new ArrayList(); // this list contain all members not on optional or mandatory list yet
								if (mtgMember != null && mtgMember.length > 0) {
									for (int i = 0; i < mtgMember.length; i++) {
										if (mtgMember[i] == null)
											continue;
										found = false;
										int memId = mtgMember[i].getObjectId();
										for (int j = 0; j < mandatoryIds.size(); j++) {
											// @AGQ022806
											if (dl.getId(mandatoryIds.get(j).toString()) != -1)
												continue;
											else {
												int id = Integer.parseInt((String) mandatoryIds
														.get(j));
												if (memId == id) {
													found = true;
													break;
												}
											}
										}
										if (found)
											continue; // this member is in the mandatory list
										else {
											// check to see if the member is on the optional list
											for (int j = 0; j < optionalIds.size(); j++) {
												// @AGQ022806
												if (dl.getId(optionalIds.get(j).toString()) != -1)
													continue;
												else {
													try {
														int id = Integer
																.parseInt((String) optionalIds
																		.get(j));
														if (memId == id) {
															found = true;
															break;
														}
													} catch (Exception e) {
													}
												}
											}
										}
										if (found)
											continue; // this member is in the optional list

										// not yet on neither the mandatory nor optional list
										selectList.add(mtgMember[i]);
									}
								}

								for (int i = 0; i < selectList.size(); i++) {
									u = (user) selectList.get(i);
									firstName = (String) u.getAttribute("FirstName")[0];
									lastName = (String) u.getAttribute("LastName")[0];
									uName = firstName + (lastName == null ? "" : (" " + lastName));
									out.println("<option value='" + u.getObjectId() + "'>&nbsp;"
											+ uName + "</option>");
								}
							%>
					</select></td>
					<td>&nbsp;&nbsp;&nbsp;</td>
					<td align="center" valign="middle">
						<%-- @AGQ080206 --%> <input type="button" class="button"
						name="add1"
						value="&nbsp;&nbsp;&nbsp;&nbsp;Add &gt;&gt;&nbsp;&nbsp;"
						onClick="swapdataMFast(this.form.Select1,this.form.MandatoryAttendee,this.form.Select2,this.form.OptionalAttendee)">
							<div>
								<input type="button" class="button" name="remove1"
									value="<< Remove"
									onClick="swapdataM1Fast(this.form.MandatoryAttendee,this.form.Select1,this.form.Select2)">
							</div>
					</td>
					<td>&nbsp;&nbsp;&nbsp;</td>
					<!-- people selected -->
					<td bgcolor="#FFFFFF"><select class="formtext_fix"
						name="MandatoryAttendee" id="MandatoryAttendee" multiple
						size="5">
							<%
								// @AGQ022806
								dl dlObj = null;
								for (int i = 0; i < mandatoryIds.size(); i++) {
									dlObj = null;
									u = null;
									try {
										// @AGQ022806
										String temp = mandatoryIds.get(i).toString();
										if (dl.getId(temp) != -1) {
											dlObj = (dl) dlMgr.get(pstuser, dl.getId(temp));
										} else
											u = (user) uMgr.get(pstuser, Integer.parseInt(temp));
									} catch (Exception e) {
										continue;
									}
									if (dlObj != null) {
										out.print("<option value='" + dl.DLESCAPESTR
												+ dlObj.getObjectId() + "'>* "
												+ dlObj.getObjectName() + "</option>");
									} else if (u != null) {
										firstName = (String) u.getAttribute("FirstName")[0];
										lastName = (String) u.getAttribute("LastName")[0];
										uName = firstName
												+ (lastName == null ? "" : (" " + lastName));
										out.println("<option value='" + mandatoryIds.get(i)
												+ "'>&nbsp;" + uName + "</option>");
									}
								}
							%>
					</select></td>
				</tr>
			</table>
		</td>
	</tr>
	<!-- End of Mandatory Attendee -->
	<tr>
		<td colspan="3"><img src="../i/spacer.gif" width="5" height="3"/></td>
	</tr>


<!-- Optional Attendees -->
<tr <%=hide%>>
	<td width="20">&nbsp;</td>
	<td valign="top" class="plaintext_blue">&nbsp;&nbsp;&nbsp;Optional
		Attendee:</td>
	<td>
		<!-- Optional -->
		<table border="0" cellspacing="0" cellpadding="0">
			<tr>
				<td><select class="formtext_fix" name="Select2"
					id="Select2" multiple size="5">
						<%
							// set up select list on the left (same as the mandatory select list)

							//@AGQ022806
							prevName = null;
							for (int i = 0; i < dlSelectList.size(); i++) {
								dl curDl = (dl) dlSelectList.get(i);
								String curName = curDl.getObjectName();
								if (prevName != null) {
									if (!prevName.equalsIgnoreCase(curName)) {
										out.print("<option value='" + dl.DLESCAPESTR
												+ curDl.getObjectId() + "'>* " + curName
												+ "</option>");
									}
								} else {
									out.print("<option value='" + dl.DLESCAPESTR
											+ curDl.getObjectId() + "'>* " + curName
											+ "</option>");
								}
								prevName = curName;
							}

							for (int i = 0; i < selectList.size(); i++) {
								u = (user) selectList.get(i);
								firstName = (String) u.getAttribute("FirstName")[0];
								lastName = (String) u.getAttribute("LastName")[0];
								uName = firstName + (lastName == null ? "" : (" " + lastName));
								out.println("<option value='" + u.getObjectId() + "'>&nbsp;"
										+ uName + "</option>");
							}
						%>
				</select></td>
				<td>&nbsp;&nbsp;&nbsp;</td>
				<td align="center" valign="middle">
					<%-- @AGQ080206 --%> <input type="button" class="button"
					name="add2"
					value="&nbsp;&nbsp;&nbsp;&nbsp;Add &gt;&gt;&nbsp;&nbsp;"
					onClick="swapdataMFast(this.form.Select2,this.form.OptionalAttendee,this.form.Select1,this.form.MandatoryAttendee)">
						<div>
							<input type="button" class="button" name="remove2"
								value="<< Remove"
								onClick="swapdataM1Fast(this.form.OptionalAttendee,this.form.Select2,this.form.Select1)">
						</div>
				</td>
				<td>&nbsp;&nbsp;&nbsp;</td>
				<!-- people selected -->
				<td bgcolor="#FFFFFF"><select class="formtext_fix"
					name="OptionalAttendee" id="OptionalAttendee" multiple
					size="5">
						<%
							//@AGQ022806
							for (int i = 0; i < optionalIds.size(); i++) {
								dlObj = null;
								u = null;
								try {
									//@AGQ022806
									String temp = optionalIds.get(i).toString();
									if (dl.getId(temp) != -1) {
										dlObj = (dl) dlMgr.get(pstuser, dl.getId(temp));
									} else
										u = (user) uMgr.get(pstuser, Integer.parseInt(temp));
								} catch (Exception e) {
									continue;
								}
								if (dlObj != null) {
									out.print("<option value='" + dl.DLESCAPESTR
											+ dlObj.getObjectId() + "'>* "
											+ dlObj.getObjectName() + "</option>");
								} else if (u != null) {
									firstName = (String) u.getAttribute("FirstName")[0];
									lastName = (String) u.getAttribute("LastName")[0];
									uName = firstName
											+ (lastName == null ? "" : (" " + lastName));
									out.println("<option value='" + optionalIds.get(i)
											+ "'>&nbsp;" + uName + "</option>");
								}
							}
						%>
				</select></td>
			</tr>
			<!-- <tr><td><span class="footnotes">* Use list</span></td></tr> -->
		</table>
	</td>
</tr>
<!-- End of Optional Attendee -->

<%
	//@AGQ030606 
	String guestEmails = request.getParameter("guestEmails");
	if (guestEmails == null) {
		guestEmails = "";
	}
%>
<tr>
	<td colspan="3">&nbsp;</td>
</tr>

<!-- Guest Emails -->
<tr>
	<td width="20">&nbsp;</td>
	<td valign="top" class="plaintext_blue">&nbsp;&nbsp;&nbsp;Invite
		Guests:</td>
	<td>
		<table border="0" cellspacing="0" cellpadding="0">
			<tr>
				<td><input id="guestEmails" name="guestEmails"
					class="formtext" type="text" style='width: 650px;'
					value="<%=guestEmails %>" /></td>
			</tr>
			<tr>
				<td><span class="footnotes">
					Enter email addresses separated by commas (e.g. aaa@z.com, bbb@z.com)</span></td>
			</tr>
		</table>
	</td>
</tr>
<!-- End of Guest Emails -->

<%
	////////////////////////////////////
	// close invite panel
	out.print("</table></DIV>");	// END invite panel table
	out.print("</td></tr>");

%>

		<!-- Submit Button -->
		<tr>
			<td width="20">&nbsp;</td>
			<td colspan=2 class="10ptype"><br />
				<img src='../i/spacer.gif' height='1' width='375' />
				<input type="button" value="   Cancel  " class="button_medium"
					onclick="history.back(-1)" />&nbsp; <%=finish%>
				<img src='../i/spacer.gif' width='20' />
				<input type="submit" name="Submit" class="button_medium" <%=nextButton%>
					onclick="return validation();">
			</td>
		</tr>
</form>


		<!-- End of Content Table -->
		<!-- End of Main Tables -->

	</table>
	</td>
	</tr>

	<tr>
		<td>
			<!-- Footer --> <jsp:include page="../foot.jsp" flush="true" /> <!-- End of Footer -->
		</td>
	</tr>
	</table>
</body>
</html>
