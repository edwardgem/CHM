<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2005, EGI Technologies, Co.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: cal.jsp
//	Author: ECC
//	Date:	03/12/05
//	Description: Implement the calendar of MF.
//	Modification:
//		@ECC071906	Support multiple companies using PRM.  Only allow to show
//					meetings of my town.  Meetings doesn't associate to town directly,
//					The association is through project.
//		@AGQ081606	Filters private meeting from calendar view
//		@AGQ082106	Calendar does not display Project Name for OMF
//		@ECC102706	Support company employees to see all company meetings.  Use TownID to match.
//		@ECC011108	Support event/questionnaire
//		@ECC112209	Support day (holiday and special day)
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "util.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.text.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>


<%
	////////////////////////////////////////////////////////
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	String locale = (String) session.getAttribute("locale");

	final String [] MONTH_ARRAY_LONG	= {"January", "February", "March", "April", "May", "June",
		"July", "August", "September", "October", "November", "December"};
	final String [] MONTH_ARRAY	= {"Jan", "Feb", "Mar", "Apr", "May", "Jun",
		"Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};
	final String SPECIAL_DAY_COLOR = "#ee0000";
	final String HOLIDAY_COLOR = "#00ee00";
	
	final String CHECK_PPL_AVAIL		= StringUtil.getLocalString(StringUtil.TYPE_LABEL,
											locale, "Check people availability");

	boolean isGuest = false;
	if (session == null) session = request.getSession(true);
	PstUserAbstractObject pstuser = (PstUserAbstractObject)session.getAttribute("pstuser");
	if (pstuser == null || pstuser instanceof PstGuest)
	{
		isGuest = true;
		pstuser = PstGuest.getInstance();
		session.setAttribute("pstuser", pstuser);
	}
	int myUid = pstuser.getObjectId();
	
	String s;
	String checkAvailUnames = "";
	
	s = request.getParameter("checkAvail");
	boolean bCheckAvail = (s!=null && s.equals("1"));
	String [] checkUidArr = null;
	if (bCheckAvail) {
		// get check uids
		checkAvailUnames = request.getParameter("availUnames").trim();		// separated by ; , b
		checkUidArr = Util3.toUidArr(pstuser, checkAvailUnames);
		if (checkUidArr.length <= 0)
			bCheckAvail = false;						// checking no one
	}

	meetingManager mMgr = meetingManager.getInstance();
	questManager qMgr = questManager.getInstance();
	dayManager dMgr = dayManager.getInstance();
	userinfoManager uiMgr = userinfoManager.getInstance();
	townManager tnMgr = townManager.getInstance();
	projectManager pjMgr = projectManager.getInstance();
	
	userinfo myUI = (userinfo) uiMgr.get(pstuser, String.valueOf(myUid));
	TimeZone myTimeZone = myUI.getTimeZone();
	int myTimeZoneOffset = myUI.getTimeZoneIdx();

	String myUidS = String.valueOf(myUid);
	Integer io = (Integer)session.getAttribute("role");
	int iRole = 0;
	if (io != null) iRole = io.intValue();
	boolean isAdmin = (iRole & user.iROLE_ADMIN)>0;
	boolean isProgMgr = (iRole & user.iROLE_PROGMGR)>0;
	boolean isAdminAsst = (iRole & user.iROLE_ADMIN_ASST)>0;
	
	int iRoleType = (isAdmin|isProgMgr) ? 1 : 0;

	// to check if session is OMF or PRM
	boolean isOMFAPP = Prm.isOMF();
	boolean isPRMAPP = Prm.isPRM();

	// get message
	String msg = request.getParameter("msg");
	if (msg == null) msg = "";

	// get project
	String projIdS = request.getParameter("ProjId");
	if (projIdS!=null && projIdS.length()<=0) projIdS = null;

	// get month and year
	String monthS = request.getParameter("month");	// it is a digit here, will convert to January
	String yearS = request.getParameter("year");
	int month, year;
	
	Calendar today = Calendar.getInstance();

	if (monthS == null)
	{
		month = today.get(Calendar.MONTH);
		year  = today.get(Calendar.YEAR);
		monthS = MONTH_ARRAY[month];
		yearS  = String.valueOf(year);
	}
	else
	{
		month = Integer.parseInt(monthS);
		monthS = MONTH_ARRAY[month];
		year = Integer.parseInt(yearS);
	}

	// get the list of meeting events for this month
	long diff = -userinfo.getServerTimeZone()*3600000;
	Calendar ca = Calendar.getInstance();
	ca.set(Calendar.MONTH, month);
	int lastDay = ca.getActualMaximum(Calendar.DAY_OF_MONTH);
	ca.set(year, month, 1, 0, 0);
	Date firstD = ca.getTime();
	firstD = new Date(firstD.getTime() - diff*3);	// workaround to cover all timezones
	ca.set(year, month, lastDay, 23, 59);
	Date lastD = ca.getTime();
	lastD = new Date(lastD.getTime() + diff*2);		// workaround: include 8 more hours to get Asia
	
	SimpleDateFormat df = new SimpleDateFormat ("yyyy.MM.dd.HH.mm.ss");
	SimpleDateFormat df1 = new SimpleDateFormat("MM/dd/yyyy HH:mm");

	userinfo.setTimeZone(pstuser, df);
	userinfo.setTimeZone(pstuser, df1);

	// for faster comparision with multiple towns
	Object [] townIds = null;
	String myTownString = "";
	String myProjectString = "";
	PstAbstractObject o;

	if (!isGuest)
		townIds = pstuser.getAttribute("Towns");

	if (townIds!=null && townIds[0]!=null)
		for (int i=0; i<townIds.length; i++)
			myTownString += townIds[i].toString() + ";";
			
	if (myTownString.length() <= 0)
		myTownString = pstuser.getStringAttribute("TownID");
	
	if (StringUtil.isNullOrEmptyString(myTownString))
		myTownString = "";

	// filter the events (only show if I am owner or attendee)
	String showMy = request.getParameter("showMyMtg");
	if (showMy!=null && !showMy.equals("true")) showMy = null;

	/////////////////////////////////////////////////
	// retrieve the meeting array
	String expr = "(StartDate>='" + df.format(firstD)+ "') && (StartDate<='" + df.format(lastD) + "')";
	if (projIdS != null) expr = "(ProjectID='" + projIdS + "') && " + expr;

	int [] ids = mMgr.findId(pstuser, expr);
	PstAbstractObject [] mtgArr = mMgr.get(pstuser, ids);
	if (mtgArr.length > 1)
		Util.sortDate(mtgArr, "StartDate");

int mid;

	// filter meetings
	if (!isOMFAPP)
	{
		// this is filtering based on meetings associated with town projects
		// applicable to PRM and CR, but not OMF
		String myPjStr = StringUtil.toString(pjMgr.findId(pstuser, "TeamMembers=" + myUidS), ";");

		// filter meetings by town (only allow to see my town meetings)
		//if (!isAdmin && townIds != null && townIds[0] != null) {
		if (!isAdmin) {
			// a meeting might be associated to a project which is associated to town
			Object [] oArr;
			project pjObj;
			String pjTeam;
			String uidS;
			String mType;
			boolean bFound;
			
			for (int i = 0; i < mtgArr.length; i++) {
				meeting m = (meeting) mtgArr[i];

				s = (String) m.getAttribute("ProjectID")[0];	// meeting's projectID
				mType = m.getStringAttribute("Type");
				
				if (mType.startsWith("Public"))
					continue;
				
				// check to see if the project is in the same town as me
				if (!bCheckAvail) {
					if (s!=null && !Util.isMyTownProject(pstuser, s)) {

						// check to see if I am in the project
						if (!myPjStr.contains(s)) {
							mtgArr[i] = null; // filter out this meeting
							continue;
						}
					}
				}

				// didn't filter out by town, check to see if it is a PRIVATE project
				// if so, filter by attendee
				if (!bCheckAvail) {
					// also filter out private meeting that I am not an attendee or coordinator
					if (mType.equals(meeting.PRIVATE)) {
						oArr = m.getAttribute("Attendee");
						s = StringUtil.toString(oArr, ";");
						
						if (!myUidS.equals(m.getStringAttribute("Owner"))
								&& (s!=null && !s.contains(myUidS)) ) {
							mtgArr[i] = null;
						}
					}
				}
				else {
					// for bCheckAvail, filter out all meetings that the group of users
					// are not in the attendee list
					oArr = m.getAttribute("Attendee");
					s = StringUtil.toString(oArr, ";");
					bFound = false;
					for (int j=0; j<checkUidArr.length; j++) {
						uidS = checkUidArr[j];
						if (uidS.equals(m.getStringAttribute("Owner"))
								|| (s!=null && s.contains(uidS)) ) {
							bFound = true;
							break;
						}
					}
					if (!bFound)
						mtgArr[i] = null;		// none of the people in the group attendee this meeting, no conflict
				}
				
			}	// END: for all meetings
		}
	}
	
	if (bCheckAvail)
		Util3.removeDupMtgTime(mtgArr);
	
	
	StringBuffer sBuf;
	PstAbstractObject [] qstArr = new PstAbstractObject[0];
	Date dt;
	String dayStr = "";
	int id;
	int[] pjIds = new int[0];
					
					
	// ignore events, quests and days for checking availability
	if (!bCheckAvail) {

	/////////////////////////////////////////////////
	// retrieve the quest array
	expr = "(ExpireDate>='" + df.format(firstD)
			+ "') && (ExpireDate<='" + df.format(lastD) + "')";
	if (projIdS != null)
		expr = "(ProjectID='" + projIdS + "') && " + expr;
	ids = qMgr.findId(pstuser, expr);
	qstArr = qMgr.get(pstuser, ids);
	if (qstArr.length > 1)
		Util.sortDate(qstArr, "ExpireDate");

	/////////////////////////////////////////////////
	// @ECC112209 retrieve days (holiday & special)
	// days has to be handled separate from meetings and events because they are listed first,
	// despite of start time.
	String colorStr, descStr;
	Object bTextObj;
	sBuf = new StringBuffer(4096);
	expr = "(StartDate>='" + df.format(firstD) + "') && (StartDate<='"
			+ df.format(lastD) + "')";
	ids = dMgr.findId(pstuser, expr);
	
	
	PstAbstractObject[] dayArr = dMgr.get(pstuser, ids);
	if (dayArr.length > 1)
		Util.sortDate(dayArr, "StartDate");

	if (!isGuest) {
		pjIds = pjMgr.getProjects(pstuser, false);
		for (int i = 0; i < pjIds.length; i++)
			myProjectString += pjIds[i] + ";";
	}

	// filter only days relevant to me
	for (int i = 0; i < dayArr.length; i++) {
		o = dayArr[i];
		s = o.getStringAttribute("TownID"); 		// either town or project
		
		int scope = 0;
		try {scope = Integer.parseInt(s);}	// ECC: don't know why there was some garbage in here
		catch (Exception e) {
			System.out.println("Error in day, TownID: "+s);
			dMgr.delete(o);		// cleanup
			continue;
		}
		if ((scope == day.SCOPE_ALL)
				|| (scope == day.SCOPE_PERSONAL && myUidS.equals(o.getAttribute("Owner")[0]))
				|| (scope > 0 && myTownString.contains(s))
				|| (scope > 0 && myProjectString.contains(s))) // s can be 0
		{
			// put this day in the dayStr
			// day::dayStr::day:: ...  (e.g. 24::Thanksgiving ...::25:: ...)
			id = o.getObjectId();
			dt = (Date) o.getAttribute("StartDate")[0];
			ca.setTime(dt);
			if (o.getAttribute("Type")[0].equals(day.TYPE_HOLIDAY))
				colorStr = HOLIDAY_COLOR;
			else
				colorStr = SPECIAL_DAY_COLOR;
			bTextObj = o.getAttribute("Description")[0];
			descStr = (bTextObj == null) ? "" : new String(
					(byte[]) bTextObj);
			if (sBuf.length() > 0)
				sBuf.append("::");
			sBuf.append(ca.get(Calendar.DAY_OF_MONTH) + "::");
			sBuf.append("<span id=\"" + id
					+ "\"><a href=\"javascript:updateDay(" + id
					+ ");\" PRM_KEY=\"" + scope + "|"
					+ (String) o.getAttribute("Type")[0] + "|"
					+ (String) o.getAttribute("Notification")[0]);
			if (!myUidS.equals(o.getAttribute("Owner")[0]))
				sBuf.append("|NOEDIT");
			sBuf.append("\" TITLE=\"" + descStr + "\">");
			sBuf.append("<b><font COLOR=" + colorStr + ">"
					+ o.getAttribute("Title")[0]
					+ "</font></b></a></span>");

		}
	}
	dayStr = sBuf.toString();
	dayStr = dayStr.replaceAll("'", "&#39;");
	
	}	// END: if !bCheckAvail

	////////////////////////////////////////////////////////////////////////////
	// now ready to process the two arrays (mtg & event) to construct a display string: objStr
	//
	boolean found;
	String mtgTownId;
	String ownerAttrName = "", dateAttrName = "";

	String objStr = "";
	sBuf = new StringBuffer(4096);
	String ty, subj;
	String icon = "";
	String formatS1 = "", formatS2 = "";
	boolean isPrivate;
	
	if (bCheckAvail)
		formatS2 = "";			// "\" class=\"10xtype\" >"; -- no <a> tag
	else
		formatS2 = "\" class=\"10xtype\" title=\"@Ti@\">";

	// merge the meeting array and the quest array, sort it by date
	// for bCheckAvail, qstArr is empty, but for simplicity, just go thru the same code below
	
	int len = mtgArr.length + qstArr.length;
	PstAbstractObject[] objArr = new PstAbstractObject[len];
	int idx = 0;
	for (int i = 0; i < mtgArr.length; i++)
		objArr[idx++] = mtgArr[i];
	for (int i = 0; i < qstArr.length; i++)
		objArr[idx++] = qstArr[i];
	Util.sortDate(objArr, "ExpireDate");

	// do it twice: one for meeting and 2nd for quest
	boolean isMeeting;
	for (int i = 0; i < len; i++) {
		o = objArr[i];
		if (o instanceof meeting) {
			// meeting
			isMeeting = true;
			ownerAttrName = "Owner";
		} else {
			// quest
			isMeeting = false;
			ownerAttrName = "Creator";
		}

		found = false; // include if found any condition match
		if (o == null)
			continue; // might be filtered by town

		mtgTownId = (String) o.getAttribute("TownID")[0];
		if (showMy == null && townIds != null && townIds[0] != null
				&& mtgTownId != null
				&& myTownString.indexOf(mtgTownId) != -1)
			continue; // include this company meeting

		s = (String) o.getAttribute("Type")[0];
		if (s != null && s.indexOf(meeting.PRIVATE) != -1)
			isPrivate = true;
		else
			isPrivate = false;


		/*
		 *	A) Filter public meetings when showMy is clicked
		 *	B) Filter private meetings unless user is circle member, admin or program manager
		 *	C) Filter private meetings if showMy is clicked for admin or program manager
		 */
		if ((!isPrivate && showMy != null) || // A)
				(isPrivate && !(isAdmin || isProgMgr)) || // B)
				(isPrivate && (isAdmin || isProgMgr) && showMy != null)) // C)
		{
			if (myUidS.equals(o.getAttribute(ownerAttrName)[0]))
				continue; // found (I am owner)
			s = (String) o.getAttribute("TownID")[0];

			if (isPrivate && s != null && myTownString.indexOf(s) != -1)
				continue; // circle quest/meeting: show it

			if (!isMeeting) {
				// quest only
				if (o.getAttribute("State")[0].equals(quest.ST_NEW)) {
					objArr[i] = null; // new quest (not active yet) && not owner: don't show
					continue;
				}
			}

			// check attendees
			Object[] oArr = o.getAttribute("Attendee");
			for (int j = 0; j < oArr.length; j++) {
				s = (String) oArr[j];
				if (s == null)
					break; // no attendee
				if (s.startsWith(myUidS)) {
					found = true;
					break; // found
				}
			}
			if (!found) {
				objArr[i] = null; // i am not attendee: don't show this meeting
			}
		}
	}	// END: for each meeting/quest

	// 1st meeting (12::meetingsHTMLstring::18::)
	
	String DIVstr;
	String ICON_MTG = "";
	if (!bCheckAvail) {
		ICON_MTG = "../i/icon_meeting.gif";
	}
	
	boolean bCanceled;
	for (int i = 0; i < objArr.length; i++) {
		o = objArr[i];
		if (o == null)
			continue; // don't show this meeting
		if (o instanceof meeting) {
			isMeeting = true;
			dateAttrName = "StartDate";
			icon = ICON_MTG;
			if (bCheckAvail)
				formatS1 = "<BR><DIV class=\"divAvailStyle\">";
			else
				formatS1 = "<BR><DIV><a href=\"mtg_view.jsp?mid=";
		} else {
			isMeeting = false;
			dateAttrName = "StartDate"; // change from using ExpireDate because title needs this
			if (bCheckAvail)
				formatS1 = "<BR><DIV class=\"divAvailStyle\">";
			else
				formatS1 = "<BR><DIV><a href=\"../question/q_respond.jsp?qid=";
		}
		dt = (Date) o.getAttribute(dateAttrName)[0];
		if (dt == null)
			dt = (Date) o.getAttribute("ExpireDate")[0]; // for questionnaire, only has expire date
		if (sBuf.length() > 0)
			sBuf.append("@@@"); 		// separator for meetings
		sBuf.append(df1.format(dt)); 	// Date ECC: [+ field separator within a meeting] - put below
					
		// bCheckAvail only shows meeting, but need to show Start and Expire dates
		if (bCheckAvail && isMeeting) {
			dt = (Date) o.getAttribute("ExpireDate")[0];
			if (dt != null) {
				sBuf.append(" - ");
				sBuf.append(df1.format(dt) + "%@%");
			}
		}
		else {
			sBuf.append("%@%");			// field separator within a meeting
		}
					
		sBuf.append(formatS1); 						// <a href link (for !bCheckAvail)
		if (!bCheckAvail)
			sBuf.append(o.getObjectId()); // id
		sBuf.append(formatS2); 						// close href link

		bCanceled = false;
		if (bCheckAvail)
			subj = "@Ti@ - @Tii@";			// Start - Expire time  (e.g. 2:00 pm - 3:00 pm)
		else
			subj = " " + (String) o.getAttribute("Subject")[0];
		ty = (String) o.getAttribute("Type")[0];
		if (!isMeeting) {
			if (ty.indexOf(quest.TYPE_EVENT) != -1) {
				icon = "../i/icon_face.gif";
				if (o.getAttribute("State")[0].equals(quest.ST_CANCEL))
					bCanceled = true;
			} else
				icon = "../i/icon_note.gif";
		}
		if (bCanceled)
			sBuf.append("<img src=\"../i/delete.gif\" border=\"0\" alt=\"Canceled\" />");
		sBuf.append("<img src=\"" + icon + "\" border=\"0\"/>");
		if (ty == null || ty.indexOf(meeting.PRIVATE) == -1)
			subj = "<font color=\"#00aa00\">" + subj + "</font>";	// ECC: remove * on public meeting
		sBuf.append(subj + "</DIV>");
	}

	objStr = sBuf.toString();
	objStr = objStr.replaceAll("'", "&#39;");

	////////////////////////////////////////////////////////
%>

<head>
<style type="text/css">
.menu {display:none;position:relative;top:5px;font-family:Verdana;font-size:10px;color:#000044;}
.trans {left:10px;height:55px;width:100px;padding:8px;background:#999955;filter:alpha(opacity=70);-moz-opacity:70%;}
.tx {filter:none;-moz-opacity:100%;position:relative;top:-55px;}

.popMenu {display:none;position:absolute;}
.trans1 {position:absolute;left:400px;top:-400px;height:215px;width:370px;padding:10px;background:#eeeeee;filter:alpha(opacity=70);-moz-opacity:70%;}
.tx1 {filter:none;-moz-opacity:100%;position:relative;left:410px;top:-390px;}

.delWord {display:none;font-family:Verdana;font-size:10px;}
.divAvailStyle {background-color:#eeeeee;border:1px solid #000;}
</style>

<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../errormsg.jsp" flush="true"/>
<script language="JavaScript" src="cal-date.js"></script>
<script language="JavaScript" src="../date.js"></script>
<script language="JavaScript">
<!--

//var diff = getDiffUTC();
var formatS1 = "<BR><DIV><a href='mtg_view.jsp?mid=";
var formatS2 = "' class='10xtype'>";
var mStr = '<%=objStr%>';
var newMtgStr = "";
var msArr = mStr.split("@@@");
var lastDy = -1;
var requestedMonth = '<%=month%>';

var dtFormat;

if (<%=bCheckAvail%>)
	dtFormat = "hh:mm a";
else
	dtFormat = "MM/dd/yy (E) hh:mm a"; 

var dt, dt1;
for (i=0; i<msArr.length; i++)
{
	// date %@% URL-link on mtg subj
	if (msArr[i] == "") continue;
	var sa = msArr[i].split("%@%");
	
	// sa[0] can be one date, or two dates [dt1 - dt2]
	var saa = sa[0].split(" - ");
	if (saa.length == 1)
		dt = new Date(sa[0]);
	else {
		dt = new Date(saa[0]);
		dt1 = new Date(saa[1]);
	}
	
	// make sure it is the right month because our qurey expands to cover worldwide timezone
	var mo = dt.getMonth();
	if (mo != requestedMonth) {
		//alert("not right month " + mo + ", " + requestedMonth);
		continue;
	}

	var dy = dt.getDate();
	if (dy != lastDy)
	{
		if (newMtgStr!="") newMtgStr += "::";
		newMtgStr += dy + "::<BR>";
		lastDy = dy;
	}
	var s = formatDate(dt, dtFormat);	//dt.toString();
	var s2 = "";
	if (saa.length > 1)
		s2 = formatDate(dt1, dtFormat);
	
	//var idx = s.lastIndexOf(":");
	//s = s.substring(0, idx) + s.substring(idx+3);	// remove the :00
	newMtgStr += sa[1].replace("@Ti@", s).replace("@Tii@", s2);
}
var newDayStr = '<%=dayStr%>';

window.onload = function()
{
	toggleAvail();
}

function showCal()
{
	gCal = new Calendar(document.cal, null, '<%=month%>', '<%=year%>', 'MM/DD/YYYY',
			newMtgStr, newDayStr);
	gCal.show();
}

function backward()
{
	var mon = parseInt('<%=month%>');
	var yr = parseInt('<%=year%>');

	if (mon == 0)
	{
		mon = 11;
		yr -= 1;
	}
	else
		mon -= 1;

	var f = document.cal;
	f.month.value = mon;
	f.year.value  = yr;
	f.submit();
}

function forward()
{
	var mon = parseInt('<%=month%>');
	var yr = parseInt('<%=year%>');

	if (mon == 11)
	{
		mon = 0;
		yr += 1;
	}
	else
		mon += 1;

	var f = document.cal;
	f.month.value = mon;
	f.year.value  = yr;
	f.submit();
}

function goBck(loc)
{
	location = loc;
}

var selectedYrMoDy = "";
function validate()
{
	// submit form for Holiday/Special Day
	var f = document.dayForm;
	var val = trim(f.dayTitle.value);
	if (val.length <= 0)
	{
		fixElement(f.dayTitle, "Title must not be empty");
		return false;
	}

	val = f.scope.value;
	if (val == "")
	{
		fixElement(f.dayTitle, "Appear For must have a value");
		return false;
	}
	
	f.date.value = selectedYrMoDy;

	f.submit();
}

function updateDay(id)
{
	// I am doing a little trick here: extract from SPAN innerHTML all the info of the day
	var e = document.getElementById(id);
	var f = document.dayForm;
	f.dayID.value = id;
	f.delDay.value = '';

	var idx1, idx2;
	var str = e.innerHTML;
	//alert(str);

	// description
	f.dayDesc.value = extractValue(str, "TITLE=");

	// PRM_KEY:  scope|type|notification
	var sArr = extractValue(str, "PRM_KEY=").split("|");
	scopeS = sArr[0];
	typeS = sArr[1];
	notifyS = sArr[2];

	for (i=0; i<f.scope.length; i++)
	{
		if (f.scope.options[i].value == scopeS)
		{
			f.scope.options[i].selected = true;
			break;
		}
	}

	// type
	for (i=0; i<f.dayType.length; i++)
	{
		if (f.dayType.options[i].value == typeS)
		{
			f.dayType.options[i].selected = true;
			break;
		}
	}

	// notify
	for (i=0; i<f.notify.length; i++)
	{
		if (notifyS == "<%=day.NOTIFY_YES%>")
			f.notify[0].checked = true;
		else
			f.notify[1].checked = true;
	}

	// no edit
	var bDisable = false;
	var e = document.getElementById("delWord");
	if (sArr.length>3 && sArr[3]=="NOEDIT")
	{
		bDisable = true;
		e.style.display = "none";
	}
	else
		e.style.display = "block";

	f.dayTitle.disabled		= bDisable;
	f.dayDesc.disabled		= bDisable;
	f.scope.disabled		= bDisable;
	f.dayType.disabled		= bDisable;
	f.notify[0].disabled	= bDisable;
	f.notify[1].disabled	= bDisable;
	f.submitBut.disabled	= bDisable;

	// name or title
	strL = str.toLowerCase();
	idx1 = strL.indexOf("color=")+1;
	idx1 = strL.indexOf(">", idx1)+1;
	idx2 = strL.indexOf("<", idx1);
	f.dayTitle.value = str.substring(idx1, idx2);

	popMenu(1);
}

function delDay()
{
	var f = document.dayForm;
	f.delDay.value = 'true';
	f.submit();
}

function extractValue(str, key)
{
	strL = str.toLowerCase();
	key = key.toLowerCase();
	var idx1 = strL.indexOf(key);
	idx1 = idx1 + key.length + 1;
	var idx2 = strL.indexOf('"', idx1);
	return str.substring(idx1, idx2);
}

// toggle change display to enter username for checking availability
function toggleAvail(cancelX)
{
	if (cancelX != undefined)
		if (!confirm("Cancel operation?"))
			return false;
	
	var e = document.getElementById('availDiv');
	var s = trim(e.innerHTML);
	if (s.length > 7) s = s.substring(0,6);		// IE 11- doesn't support startsWith()

	if (cancelX==undefined && <%=bCheckAvail%>) {
		s = "xxx";		// we are checking availability, re-display the usernames
	}
	
	if (s=="" || s=="<table") {
		e.innerHTML="<img src='../i/bullet_tri.gif' width='20' height='10' />"
				+ "<a class='listlinkbold' href='javascript:toggleAvail();'><%=CHECK_PPL_AVAIL%></a>";
				
		if (<%=bCheckAvail%>) {
			// resubmit the form to reset checkAvail result to normal cal display
			var f = document.cal;
			f.checkAvail.value = "";
			f.submit();
		}
	}
	else {
		e.innerHTML = "<table border='0'><tr><td class='listlinkbold'>Enter usernames / emails:</td>"
				+ "<td><input type='text' size='50' name='availUnames' value='<%=checkAvailUnames%>'/></td>"
				+ "<td><img src='../i/goback.png' border='0' width='20' onclick='return toggleAvail(1);'/></td>"
				+ "<td><input type='button' class='button' name='goCheck' value=' Go ' onclick='goCheckAvail();'/></td>"
				+ "</tr></table>";
	}
}

// submit form to check for people's availability
function goCheckAvail()
{
	var f = document.cal;
	f.checkAvail.value = "1";		// usernames are in availUnames
	f.submit();
}

//-->
</script>

<title><%=Prm.getAppTitle()%> Calendar</title>

</head>


<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
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
			<tr>
	          <td>
	            <table width="100%" border="0" cellspacing="0" cellpadding="0">
				  <tr>
					<td width="26" height="30"><a name="top">&nbsp;</a></td>
                	<td width="535" height="30" align="left" valign="bottom" class="head">
                		<b>Calendar of Events</b>
					</td>
<%	s = request.getParameter("bck");
	if (s!=null) {%>
				<td><img src='../i/bullet_tri.gif' width='20' height='10' />
					<a class='listlinkbold' href='javascript:goBck("<%=s%>");'>Back to CR</a>
				</td>
<%	} %>
				  </tr>
	            </table>
	          </td>
	        </tr>
</table>
	        
<table width='90%' border="0" cellspacing="0" cellpadding="0">
			<tr>
          		<td width="100%">
<!-- Navigation Menu -->
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Event" />
				<jsp:param name="subCat" value="Calendar" />
				<jsp:param name="role" value="<%=iRole%>" />
				<jsp:param name="roleType" value="<%=iRoleType%>" />
			</jsp:include>
<!-- End of Navigation Menu -->
				</td>
	        </tr>
		</table>

<!-- Content Table -->
<form name="cal" action="cal.jsp" method="post">

<input type='hidden' name='checkAvail' value='' />

<table width="90%" border="0" cellspacing="0" cellpadding="0">

<%
	if (!StringUtil.isNullOrEmptyString(msg)) {
		out.print("<tr><td></td><td class='plaintext' style='padding-top:10px; color:#00bb00'>" + msg + "</td></tr>");
	}
%>

<!-- Show people availability -->
<tr>
	<td></td>
	<td>
		<table border='0'>
			<tr>
				<td><div id='availDiv'>
					
					</div>
				</td>
			</tr>
		</table>
	</td>
</tr>


<!-- Project Name -->
<tr>
	<td><img src="../i/spacer.gif" border="0" width="15"/></td>

	<td><table width="100%" border='0'>
		<tr>
			<td class="plaintext_blue">
<%
	if (!isOMFAPP && !isGuest)
	{
		out.print(StringUtil.getLocalString(StringUtil.TYPE_LABEL,
				locale, "Project Name"));
		out.print(":&nbsp;&nbsp;");
		out.print("<select name='ProjId' class='formtext' onchange='submit()' >");

		out.println("<option value=''>- select project name -</option>");
		int pid = 0;
		if (projIdS != null) pid = Integer.parseInt(projIdS);

		int [] projectObjId = 	pjMgr.getProjects(pstuser);	//pjMgr.findId(pstuser, "om_acctname='%'");
		if (projectObjId.length > 0)
		{
			PstAbstractObject [] projectObjList = pjMgr.get(pstuser, projectObjId);
			Util.sortName(projectObjList, true);

			String pName;
			project pj;
			for (int i=0; i < projectObjList.length ; i++)
			{
				// project
				pj = (project) projectObjList[i];
				pName = pj.getDisplayName();
				id = pj.getObjectId();

				out.print("<option value='" + id +"' ");
				if (id == pid)
					out.print("selected");
				out.print(">" + pName + "</option>");
			}
		}
		out.print("</select>");
	}
	out.print("</td>");
	if (!isGuest)
	{
		out.print("<td class='plaintext'>");
		out.print("<input type='checkbox' name='showMyMtg' value='true' ");
		if (showMy!=null && showMy.equals("true")) out.print("checked ");
		out.print("onClick='cal.submit()'> ");
		out.print(StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Show My Meetings Only"));
		out.print("</td>");

	}
%>
		</tr>
	</td></table>
</tr>


<tr>
	<td width='20'><img src='../i/spacer.gif' border='0' width='25' height='1'/></td>
	<td></td>
</tr>

<tr>
	<td>&nbsp;</td>
	<td>
		<table width="100%" border='0'>
		<tr>
			<td width='400' class="plaintext_blue"><a class='listlinkbold' href='javascript:backward();'><<</a>
				&nbsp;<%=monthS%>&nbsp;<%=yearS%>&nbsp;
				<a class='listlinkbold' href='javascript:forward();'>>></a>
			</td>


			<td class="plaintext" align='right'>&nbsp;<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Pick another month")%>:
				<select class="formtext" type="text" name="month">
<%
	for (int i=0; i<MONTH_ARRAY_LONG.length; i++)
	{
		out.print("<option value='" + i + "'");
		if (month == i)
			out.print(" selected");
		out.print(">&nbsp;" + MONTH_ARRAY_LONG[i] + "</option>");
	}
%>
				</select>

				<select class="formtext" type="text" name="year">
<%
	int maxYear = today.get(Calendar.YEAR) + 2;

	for (int i=2000; i<maxYear; i++)
	{
		out.print("<option value='" + i + "'");
		if (year == i)
			out.print(" selected");
		out.print(">&nbsp;" + i + "</option>");
	}
%>
				</select>

				&nbsp;&nbsp;<input type='submit' class='button' name='change' value=' Go '/>&nbsp;
			</td>
		</tr>
		</table>
	</td>
</tr>

<!-- show calendar -->
<tr>
	<td width="20">&nbsp;</td>
	<td width="100%">
<script language="JavaScript">
	showCal();
</script>
	</td>
</tr>

<!-- back and forth -->
<tr>
	<td width="20">&nbsp;</td>
	<td>
		<table width="100%">
		<tr>
			<td><a class='listlinkbold' href='javascript:backward();'><< <%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Last Month")%></a></td>
<%if (isAdmin || isProgMgr || isAdminAsst) { %>
			<td align="center"><a class='listlinkbold' href='conf_view.jsp?yr=<%=year%>&mn=<%=month%>'>
				<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "View Conference Room")%></a></td>
<%} %>
			<td align="right"><a class='listlinkbold' href='javascript:forward();'><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Next Month")%> >></a></td>
		</tr>
		</table>
	</td>
</tr>


</table>
</form>

</td></tr>
<tr>
	<td class="tinytype" ><img src='../i/spacer.gif' height='1' width='20'><font color='#00aa00'><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Public meeting")%></font></td>
</tr>

<!-- Popup menu for Holiday or Special Day -->
<tr><td>
<form name='dayForm' action='post_day.jsp' method="post">
<input type='hidden' name='date' value=''/>
<input type='hidden' name='dayID' value=''/>
<input type='hidden' name='delDay' value=''/>

<DIV class='popMenu' id='popMenu'>
	<div class='trans1'></div>
	<div class='tx1'>
		<table border='0' cellpadding='0' cellspacing='0'>
			<tr>
				<td class='plaintext_blue' width='100'>* Type:</td>
				<td>
					<select name='dayType' id='dayType' class='plaintext'>
						<option value='<%=day.TYPE_HOLIDAY%>'>Holiday</option>
						<option value='<%=day.TYPE_SPECIAL%>'>Special Day</option>
					</select>
				</td>
			</tr>
			<tr><td><img src='../i/spacer.gif' width='1' height='5'/></td></tr>
			<tr>
				<td class='plaintext_blue'>* Title:</td>
				<td>
					<input name='dayTitle' class='plaintext' type='text' size='20'/>
				</td>
			</tr>
			<tr><td><img src='../i/spacer.gif' width='1' height='5'/></td></tr>
			<tr>
				<td class='plaintext_blue' valign='top'>&nbsp;&nbsp;&nbsp;Description:</td>
				<td>
					<textarea name='dayDesc' class='plaintext' rows='4' cols='35'></textarea>
				</td>
			</tr>
			<tr><td><img src='../i/spacer.gif' width='1' height='5'/></td></tr>
			<tr>
				<td class='plaintext_blue'>* Appear for:</td>
				<td>
					<select name='scope' class='plaintext'>
						<option value=''>- select group -</option>
						<option value='<%=day.SCOPE_PERSONAL%>' selected>Personal</option>
<%
	if (isAdmin)
		out.print("<option value='" + day.SCOPE_ALL + "'>All people</option>");

	ids = tnMgr.findId(pstuser, "Chief='" + myUidS + "'");
	PstAbstractObject [] myModerateTown = tnMgr.get(pstuser, ids);
	for (int i=0; i<myModerateTown.length; i++)
	{
		town tn = (town)myModerateTown[i];
		out.print("<option value='" + tn.getObjectId() + "'>"
				+ (String)tn.getAttribute("Name")[0] + "</option>");
	}
	
	if (isPRMAPP && !isGuest) {
		for (int i=0; i<pjIds.length; i++) {
			project pj = (project)pjMgr.get(pstuser, pjIds[i]);
			out.print("<option value='" + pjIds[i] + "'>"
					+ pj.getDisplayName() + "</option>");
		}
	}
%>
					</select>
				</td>
			</tr>
			<tr><td><img src='../i/spacer.gif' width='1' height='5'/></td></tr>
			<tr>
				<td class='plaintext_blue'>* Send Email:</td>
				<td>
					<input type='radio' name='notify' class='plaintext' value='<%=day.NOTIFY_YES%>' checked>Yes&nbsp;&nbsp;
					<input type='radio' name='notify' class='plaintext' value='<%=day.NOTIFY_NO%>'>No
				</td>
			</tr>
			<tr><td><img src='../i/spacer.gif' width='1' height='15'/></td></tr>
			<tr>
				<td colspan='2' align='center'>
				<table><tr>
					<td><input type='button' class='button_medium' value='Submit' onClick='validate();' name='submitBut'></input></td>
					<td><input type='button' class='button_medium' value='Cancel' onClick='popMenu(false);'></input></td>
					<td id='delWord' class='delWord'>
						<table><tr>
							<td>&nbsp;&nbsp;<img src='../i/delete.gif' /></td>
							<td valign='middle'><a href='javascript:delDay();'>Delete</a></td>
						</tr></table>
					</td>
				</tr></table>
				</td>
			</tr>
		</table>
	</div>
</DIV>
</form>
</td></tr>

		<!-- End of Main Tables -->


<tr>
	<td>
		<!-- Footer -->
		<jsp:include page="../foot.jsp" flush="true"/>
		<!-- End of Footer -->
	</td>
</tr>
</table>
</body>
</html>
