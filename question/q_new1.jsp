<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2008, EGI Technologies, Co.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: q_new1.jsp
//	Author: ECC
//	Date:	12/31/07
//	Description: Create a new questionnaire.
//
//
//	Modification:
//				@ECC011408	Support update of a new quest.
//				@ECC020408	Link quest together as a series.
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
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />
<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	////////////////////////////////////////////////////////

	PstUserAbstractObject me = pstuser;
	if (me instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	String s;
	boolean isEvent = false;
	String endLabel = "";
	int myUid = me.getObjectId();
	
	questManager qMgr = questManager.getInstance();
	userManager uMgr = userManager.getInstance();
	projectManager pjMgr = projectManager.getInstance();
	userinfoManager uiMgr = userinfoManager.getInstance();
	
	userinfo myUI = (userinfo) uiMgr.get(pstuser, String.valueOf(myUid));
	TimeZone myTimeZone = myUI.getTimeZone();
	int myTimeZoneOffset = myUI.getTimeZoneIdx();
	
	SimpleDateFormat df1 = new SimpleDateFormat ("MM/dd/yyyy");
	SimpleDateFormat df2 = new SimpleDateFormat ("H:mm");
	SimpleDateFormat df3 = new SimpleDateFormat ("yyyy/MM/dd");
	if (!userinfo.isServerTimeZone(myTimeZone)) {
		df1.setTimeZone(myTimeZone);
		df2.setTimeZone(myTimeZone);
		df3.setTimeZone(myTimeZone);
	}

	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ( (iRole & user.iROLE_ADMIN) > 0 )
		isAdmin = true;

	// to check if session is OMF or PRM
	boolean isOMFAPP = Prm.isOMF();
	String appS = Prm.getAppTitle();
	
	// @ECC080108 Multiple company
	boolean isMultiCorp = Prm.isMultiCorp();
	
	String label0;
	if (isOMFAPP) label0 = "Circle";
	else label0 = "Company";
	
	boolean isUpdate = false;
	boolean isClone = false;
	boolean isFollowupLink = false;			// linking a series
	String parentIdS = null;
	String qType=null, subj=null, loc=null, meetingType=null, company=null,
		agendaS=null, desc=null, guestEmails=null, midS=null, qShare="";
	String mtgDateS=null, mtgDateES=null, stTimeS=null, exTimeS=null, sendDT;
	int duration = 60;		// default meeting duration: 60 min
	String [] manAttArr = null;
	String lastProjIdS = null;

	String qidS = request.getParameter("qid");	// note that this is only from q-respond.jsp, but not q_new2.jsp or else I will lose all changes
	if (qidS == null)
	{
		parentIdS = request.getParameter("ParentId");	// @ECC020408
		if (parentIdS!=null && parentIdS.equals("null"))
			parentIdS = null;
		if (parentIdS != null) {
			s = request.getParameter("ComeBack");		// back from q_new2.jsp
			if (s==null || !s.equals("true")) {
				isFollowupLink = true;
				qidS = parentIdS;						// don't reload if it is back
			}
		}
		
		// new creation and first call		
		s = request.getParameter("D");					// check to see if Start Date is passed in
		if (s != null)
			mtgDateS = df1.format(df3.parse(s));
	}

	if (qidS != null)
	{
		PstAbstractObject qObj = qMgr.get(me, qidS);
		s = (String)qObj.getAttribute("Type")[0];		// e.g. eventPublic
		if (s.startsWith(quest.TYPE_EVENT))
			qType = quest.TYPE_EVENT;
		else
			qType = quest.TYPE_QUEST;
		if (s.indexOf(quest.PUBLIC) != -1)
			meetingType = quest.PUBLIC;
		else
		{
			meetingType = quest.PRIVATE;
			company = (String)qObj.getAttribute("TownID")[0];
		}
		if (s.contains(quest.NO_SHARE))
			qShare = quest.NO_SHARE;

		subj = (String)qObj.getAttribute("Subject")[0];
		loc  = (String)qObj.getAttribute("Location")[0];
		midS = (String)qObj.getAttribute("MeetingID")[0];
		Object bTextObj = qObj.getAttribute("Content")[0];
		agendaS = (bTextObj==null)? "" : new String((byte[])bTextObj, "utf-8");
		bTextObj = qObj.getAttribute("Description")[0];
		desc = (bTextObj==null)? null : new String((byte[])bTextObj, "utf-8");
		if (desc != null)
			desc = desc.replaceAll("<br>", "\n");
		Object [] oA = qObj.getAttribute("Attendee");
		manAttArr = new String[oA.length];
		for (int i=0; i<oA.length; i++)
			manAttArr[i] = (String)oA[i];
		guestEmails = (String)qObj.getAttribute("GuestEmails")[0];
		lastProjIdS = (String)qObj.getAttribute("ProjectID")[0];
		
		// @ECC011408 either update of an existing new quest
		// @ECC012108 or clone a quest from an existing quest
		s = request.getParameter("clone");
		if (s!=null && s.equals("true"))
			isClone = true;
		else if (isFollowupLink) {
			// create followup event
			// automatic bump followup event number
			if (subj.endsWith(")")) {
				int idx = subj.lastIndexOf('(') + 1 ;
				s = subj.substring(idx, subj.length()-1);
				try {int num = Integer.parseInt(s); subj = subj.substring(0, idx) + (num+1) + ")";}
				catch (NumberFormatException e) {}
			}
			
			// copy the same time but leave the date alone
			Date dt = (Date)qObj.getAttribute("StartDate")[0];
			stTimeS = df2.format(dt);
			Date dt1 = (Date)qObj.getAttribute("ExpireDate")[0];
			exTimeS = df2.format(dt1);
			duration = (int) (dt1.getTime() - dt.getTime())/60000;	// in min
		}
		else {
			isUpdate = true;
		}
		
		// get dates
		if (isUpdate)
		{
			Date dt = (Date)qObj.getAttribute("StartDate")[0];	//Util2.getLocalTime((Date)qObj.getAttribute("StartDate")[0]);
			if (dt != null)
			{
				// questionnaire doesn't have start date/time
				mtgDateS = df1.format(dt);
				stTimeS = df2.format(dt);
			}
			Date dt1 = (Date)qObj.getAttribute("ExpireDate")[0];	//Util2.getLocalTime((Date)qObj.getAttribute("ExpireDate")[0]);
			mtgDateES = df1.format(dt1);
			exTimeS = df2.format(dt1);
			if (dt!=null && dt1!=null) {
				duration = (int) (dt1.getTime() - dt.getTime())/60000;	// in min
			}
		}
	}

	if (!isUpdate)
		qidS = "";
	
	String nextButton="";
	String action="";
	String hide="";

	nextButton=" value='  Continue  ' ";
	action=" action='q_new2.jsp' ";
	
	String [] sa;
	ArrayList mandatoryIds = new ArrayList();
	String createLabel = "Update";
	
	if (!isUpdate && !isClone && !isFollowupLink)
	{
		// either a real Create quest or an Update but back from q_new2.jsp
		qType = request.getParameter("Qtype");
		subj = request.getParameter("Subject");
		loc = request.getParameter("Location");
		meetingType = request.getParameter("meetingType");
		company = request.getParameter("company");
		agendaS = request.getParameter("Agenda");
		desc = request.getParameter("Description");
		manAttArr = request.getParameterValues("MandatoryAttendee");
		mandatoryIds.add(String.valueOf(myUid));	// default to include me
		guestEmails = request.getParameter("guestEmails");
		if (mtgDateS == null)
			mtgDateS = request.getParameter("StartDate");
		stTimeS = request.getParameter("StartTime");
		exTimeS = request.getParameter("ExpireTime");
		s = request.getParameter("Duration");
		if (!StringUtil.isNullOrEmptyString(s)) duration = Integer.parseInt(s);
		mtgDateES = request.getParameter("ExpireDate");
		midS = request.getParameter("mid");
		
		// check to see if this is from q_new2.jsp
		s = request.getParameter("updateQid");
		if (s!=null && s.length()>0)
		{
			isUpdate = true;						// isUpdate but has been to q_new2.jsp and back
			qidS = s;
		}
	}
	agendaS = Util.stringToHTMLString(agendaS);

	if (!isUpdate)
		createLabel = "Create";

	if (guestEmails == null) {
		guestEmails = "";
	}

	if (midS == null) midS = "";

	// qType (event or quest) and associated labels
	String subCatLabel;
	String label1, label2="";
	if (qType==null || qType.equals("quest"))
	{
		qType = "quest";
		endLabel = "Deadline";
		label1 = "Questionnaire/Survey/Vote";
		if (!isUpdate)
			label2 = "New Questionnaire";
		else
			label2 = "Update Questionnaire";
		subCatLabel = "NewQuestion";
	}
	else
	{
		isEvent = true;
		endLabel = "End Time";
		label1 = "Event/Party";
		if (!isUpdate)
			label2 = "New Event";
		else
			label2 = "Update Event";
		subCatLabel = "NewEvent";
	}
	
	// Perform a check to see if MandatoryId already exist, if it does replace the current arraylist
	int manAttArrLength = (manAttArr != null)?manAttArr.length:0;
	if (manAttArrLength > 0) {
		mandatoryIds.clear();
		for (int i = 0; i < manAttArrLength; i++) {
			mandatoryIds.add(manAttArr[i]);
		}
	}	

	// for OMF, SelectGroup can be company (town) id
	// get the current form values
	int projTeamId = -2;
	s = request.getParameter("SelectGroup");
	if (s!=null && s.length()>0)
		projTeamId = Integer.parseInt(s);
	// @AGQ081706
	else if (s == null && isOMFAPP) 
		projTeamId = 0;

	if (subj == null) subj = "";
	if (loc == null) loc = "";

	// @AGQ081606 Type public or private
	if (meetingType == null) {
		String defaultMtgType = Util.getPropKey("pst", "MEETING_DEFAULT_TYPE");		
		if (!Util.isNullString(defaultMtgType) && defaultMtgType.equalsIgnoreCase(meeting.PUBLIC))
			meetingType = meeting.PUBLIC;
		else
			meetingType = meeting.PRIVATE;			
	}		
	
	if ( company==null || company.length()<=0 || company.equals("null") )
		company = "0";			// personal

	// time
	sendDT = request.getParameter("SendDT");

	// Category
	String type = request.getParameter("Type");
	String templateName = request.getParameter("TemplateName");
	
	String optMsg = request.getParameter("message");
	if (agendaS == null || agendaS.length() <= 0)
		agendaS = "";
	
// @AGQ022806	
	PstAbstractObject [] mtgMember = null;
	PstAbstractObject [] dlArr = null;
	dlManager dlMgr = dlManager.getInstance();
	
	// all users
	int [] ids;
	if (projTeamId == 0 && !isOMFAPP && !isMultiCorp)
		mtgMember = ((user)me).getAllUsers();
	else if (projTeamId == 0 && isOMFAPP) {
		Object [] objArr = me.getAttribute(user.TEAMMEMBERS);
		if (objArr[0]!=null) {
			mtgMember = uMgr.get(me, objArr);
			Util.sortUserArray(mtgMember, true);
		}
		else
			mtgMember = new PstAbstractObject[0];
	}
	else if (projTeamId==0 && isMultiCorp)
	{
		// CR MultiCorp:
		// get people of my company
		ids = uMgr.findId(me, "Company='" + (String)me.getAttribute("Company")[0] + "'");
		mtgMember = uMgr.get(me, ids);
/*		
		s = (String)me.getAttribute("Remember")[0];	// emails separated by ";"
		if (s == null) s = "";
		sa = s.split(";");
		mtgMember = new PstAbstractObject[sa.length];
		PstAbstractObject o;
		for (int i=0; i<sa.length; i++)
		{
			try {o = uMgr.get(me, sa[i]);}
			catch (PmpException e) {continue;}
			mtgMember[i] = o;
		}
*/
	}
	else if (projTeamId > 0)
	{
		if (!isOMFAPP) {
			mtgMember = ((user)me).getTeamMembers(projTeamId);
System.out.println("mem num="+mtgMember.length);			
		}
		else
		{
			// ECC121806: for OMFAPP, support choosing contacts from my companies
			ids = uMgr.findId(me, "Towns=" + projTeamId);
			mtgMember = uMgr.get(me, ids);
		}
	}
	else {
	}
	
	// @ECC110206 Description
	String DEFAULT_TXT = ">> Enter a short paragraph to describe this event/questionnaire.  You may edit this later.";
	String descStr = null;
	if (desc != null)
		descStr = desc;
	if (descStr==null || descStr.length()==0)
		descStr = DEFAULT_TXT;

	////////////////////////////////////////////////////////
%>


<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../forms.jsp" flush="true"/>
<script language="JavaScript" src="../get-date.js"></script>
<script language="JavaScript" src="../date.js"></script>

<script language="JavaScript">
<!--
var sTD = null;
var eTD = null;
var hr = 0;
var stMin = 0;
var displayMins = "00";

function fo()
{
	Form = document.newQuestion;
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
	//sortSelect(document.getElementById("Select2"));
	sortSelect(document.getElementById("MandatoryAttendee"));
}

function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

function validation()
{
	var f = document.newQuestion;
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
	
	if (<%=isEvent%> == true)
	{
		var location = f.Location.value;
		for (i=0;i<location.length;i++) {
			char = location.charAt(i);
			if (char == '\\') {
				fixElement(f.Location,
					"LOCATION cannot contain these characters: \n  \\");
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
	
	// @AGQ091206
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
	
	if ((f.MandatoryAttendee.options.length) == 0) {
		fixElement(f.MandatoryAttendee, 
			"Please make sure there are attendees for this meeting");
		return false;
	}
	
	if (<%=isEvent%> == true)
	{
		var now = new Date();
		var today = new Date(now.getFullYear(),now.getMonth(),now.getDate());
		var start = new Date(f.StartDate.value);
		//var expire = new Date(f.ExpireDate.value);
		//var diff = expire.getTime() - start.getTime();
		//var days = Math.floor(diff / (1000 * 60 * 60 * 24));

		//var startT = f.StartTime.value;
		//var startTval = parseFloat(startT.substring(0, startT.length-3));
		//if (startT.charAt(startT.length-2) == '3') startTval += 0.5;
		//var endT = f.ExpireTime.value;
		//var endTval = parseFloat(endT.substring(0, endT.length-3));
		//if (endT.charAt(endT.length-2) == '3') endTval += 0.5;

		if (start < today)
		{
			if (!confirm("This meeting event is in the past, do you really want to set this meeting?"))
				return false;
		}
	}
	else {
		if (f.ExpireDate.value =='')
		{
			fixElement(f.ExpireDate,
				"Please make sure that the <%=endLabel%> field is properly completed.");
			return false;
		}		
	}

	// convert date/time to UTC
	// the basic idea here is that I need to adjust based on diff of laptop to UTC (done here) AND
	// diff of server and UTC (done in post_mtg_new): together I adjust based on diff of laptop & server
	var diff = getDiffUTC();	// ECC: not use
	var dt, tm;

	if (<%=isEvent%> == true) {
		dt = new Date(f.StartDate.value + " " + f.StartTime.value);
		tm = dt.getTime();
		//var tm1 = tm + diff;
	
		f.StartDT.value = '' + tm;			// simply pass the msec as a string
		f.ExpireDT.value = tm + f.Duration.value*60000;
	}
	else {
		// ExpireTime only for quest, event use Duration
		dt = new Date(f.ExpireDate.value + " " + f.ExpireTime.value);
		tm = dt.getTime();
		f.ExpireDT.value = '' + tm;			// simply pass the msec as a string
	}
	
	f.LocalStartDT.value = '' + diff; //tm1;	pass the local time (msec) as a string  ECC: not use.

	var s = '';
	for (i=0; i<f.MandatoryAttendee.length; i++)
	{
		if (s != '') s += ";";
		s += f.MandatoryAttendee.options[i].value;
	}
	f.Mandatory.value = s;

	var desc = trim(f.Description.value);
	f.Description.value = desc;
	if (desc.substring(0,2) == ">>")
		f.Description.value = '';

	selectAll(f.MandatoryAttendee);

	return true;
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
	var es = 'newQuestion.' + e1.name;
	var es2 = null;
	if (e2 != null )
	{
		es2 = 'newQuestion.' + e2.name;
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

function copyDate(Source, Target)
{
	var source = document.getElementsByName(Source).value;
	document.getElementsByName(Target).value = source;
	if (nextDay) nextDay = false;
}

function copyTime()
{
	// copy startDate to expireDate
	var f = document.newQuestion;
	var ts = f.StartTime.value.split(":");
	if (ts[0] > 22) {
		if (!<%=isEvent%> && f.ExpireDate.value==f.StartDate.value) {
			var expDate = getDateFromFormat(f.ExpireDate.value, "MM/dd/yyyy");
			expDate = new Date(expDate + 86400000);
			f.ExpireDate.value = formatDate(expDate, "MM/dd/yyyy");
			nextDay = true;
		}
		ts[0] = ts[0]-24;
	}
	// @AGQ072706
	else if (nextDay) {
		copyDate(f.StartDate, f.ExpireDate);
	}
	var s = parseInt(ts[0]) + 1;
	if (!<%=isEvent%>) {
		f.ExpireTime.value = s + ":" + ts[1];
	}
}

function changeTeam(op)
{
	if (op==1)
		newQuestion.SelectGroup.value = newQuestion.ProjectId.value;
	selectAll(document.getElementById("MandatoryAttendee"));
	newQuestion.ComeBack.value = "true";				// don't change values
	newQuestion.updateQid.value = "<%=qidS%>";
	newQuestion.action = "q_new1.jsp";
	document.newQuestion.submit();
}

function selectAll(select) {
	var length = select.length;
	for(var i = 0; i < length; i++) {
		select.options[i].selected = true;
	}
}

function setPublic(public)
{
	var e = newQuestion.company;
	if (e == null)
		return;
	if (public)
	{
		e.disabled = true;
		e.options[0].selected = true;
	}
	else
	{
		e.disabled = false;
		e.options[1].selected = true;		// Personal
	}
}

function deleteQuest()
{
	// user can delete the survey before it is ACTIVE (when updating a NEW quest)
	if (!confirm("Do you really want to remove this <%=label1%>?"))
		return;
		
	location = "post_q_del.jsp?qid=<%=qidS%>";
	return;
}

function finish()
{
	// click finish: save the quest without touching the questions portion
	if (!validation())
		return;
	document.newQuestion.Finish.value = "true";
	document.newQuestion.action = "post_q_new.jsp";
	document.newQuestion.submit();
}

function add_map()
{
	var f = document.newQuestion;
	var loc = f.Location.value;
	loc = "<a href='http://maps.google.com?q=" + loc + "'>Direction</a>";
	doclear(f.Description);
	var val = f.Description.value;
	if (val != "") val += "\n";
	f.Description.value = val + loc;
}

//-->
</script>

</head>

<title><%=appS%> <%=label2%></title>
<body onLoad="fo();" bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
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
                	<td height="30" align="left" valign="bottom" class="head">
                	<b><%=createLabel%> an Invite/Questionnaire/Survey</b>
					</td></tr>
	            </table>
	          </td>
	        </tr>
</table>
	        
<table width='90%' border='0' cellspacing='0' cellpadding='0'>
			<tr>
          		<td width="100%">
<!-- Navigation Menu -->
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Event" />
				<jsp:param name="subCat" value="<%=subCatLabel%>" />
				<jsp:param name="role" value="<%=iRole%>" />
				<jsp:param name="roleType" value="1" />
			</jsp:include>
<!-- End of Navigation Menu -->
				</td>
	        </tr>
		</table>
<!-- Content Table -->

<table width="770" border="0" cellspacing="0" cellpadding="0">
<tr><td colspan="2">&nbsp;</td></tr>


<form method="post" name="newQuestion" id="newQuestion"<%=action%>>
<input type="hidden" name="Qid" value="<%=qidS%>">
<input type="hidden" name="ParentId" value="<%=parentIdS%>">
<input type="hidden" name="Qtype" value="<%=qType%>">
<input type="hidden" name="Qshare" value="<%=qShare%>">
<input type="hidden" name="Mandatory" value="">
<input type="hidden" name="LocalStartDT" value="">
<input type="hidden" name="StartDT" value="">
<input type="hidden" name="ExpireDT" value="">
<input type="hidden" name="SendDT" value="<%=sendDT%>">

<input type="hidden" name="Agenda" value="<%=agendaS%>" >
<input type="hidden" name="Origin" value="">
<input type="hidden" name="message" value="<%=optMsg%>" >
<input type="hidden" name="mid" value="<%=midS%>" >
<input type="hidden" name="ComeBack" value="">
<input type="hidden" name="Finish" value="">
<input type="hidden" name="updateQid" value="">


<%-- @AGQ081506 --%>
<% if (type != null) { %>
<input type="hidden" name="Type" value="<%=type%>">
<input type="hidden" name="TemplateName" value="<%=templateName%>">
<% } %>
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="instruction_head"><br><b>Step 1 of 3: Enter 
<%	if (isEvent) out.print("Party / Event");
	else out.print("Questionnaire / Survey / Vote");
%>
		Information</b></td>
	</tr>

	<tr>
		<td width="20">&nbsp;</td>
		<td colspan=2 class="instruction">
		<br>Please note that fields marked with an * are required.<br><br></td>
	</tr>

<!-- Subject -->
	<tr>
		<td width="20">&nbsp;</td>
		<td width='158' class="plaintext_blue"><font color="#000000">*</font> Subject:</td>
		<td>
			<input class="formtext" type="text" name="Subject" size="80" value='<%=Util.stringToHTMLString(subj)%>'>
		</td>
	</tr>
	<tr><td colspan='3'><img src='../i/spacer.gif' height='5' /></td></tr> 

<%	if (isEvent)
	{
%>	

<!-- Project (only for CR) -->
<%	if (!isOMFAPP)
	{
		String projectS = request.getParameter("ProjectId");
		String projName;
		out.print("<tr><td width='20'>&nbsp;</td>");
		out.print("<td class='plaintext_blue'>&nbsp;&nbsp;&nbsp;Project:</td>");
		out.print("<td><select name='ProjectId' class='formtext' onchange='changeTeam(1);'>");
		out.println("<option value=''>- select project name -</option>");
		
		if (projectS != null && projectS.length() > 0)
			projName = ((project)pjMgr.get(pstuser, Integer.parseInt(projectS))).getDisplayName();	//PstManager.getNameById(pstuser, Integer.parseInt(projectS));
		else if (lastProjIdS != null)
			projName = ((project)pjMgr.get(pstuser, Integer.parseInt(lastProjIdS))).getDisplayName();	//PstManager.getNameById(pstuser, Integer.parseInt(lastProjIdS));
		else
			projName = (String)session.getAttribute("projName");
		if (projName == null) projName = "";

		int [] projectObjId = pjMgr.getProjects(pstuser);
		if (projectObjId.length > 0)
		{
			PstAbstractObject [] projectObjList = pjMgr.get(pstuser, projectObjId);
			Util.sortName(projectObjList, true);
			
			String pName;
			project pj;
			Date expDate;
			String expDateS = new String();
			for (int i=0; i < projectObjList.length ; i++)
			{
				// project
				pj = (project) projectObjList[i];
				pName = pj.getDisplayName();

				out.print("<option value='" + pj.getObjectId() +"' ");
				if (pName.equals(projName))
					out.print("selected");
				out.print(">" + pName + "</option>");
			}
		}		
		out.print("</select></td>");
		out.print("</tr>");
		out.print("<tr><td colspan='3'><img src='../i/spacer.gif' height='5' /></td></tr>");
	}	// END if !isOMFAPP
	else
		out.println("<input type='hidden' name='ProjectId' value=''>");
%>

<!-- Location -->
	<tr>
		<td width="20">&nbsp;</td>
		<td class="plaintext_blue">&nbsp;&nbsp;&nbsp;Location:</td>
		<td>
			<input class="formtext" type="text" name="Location" size="25" value="<%=loc%>">
		</td>
	</tr>
	<tr><td colspan='3'><img src='../i/spacer.gif' height='5' /></td></tr> 

<!-- start date -->
	<tr>
		<td width="20">&nbsp;</td>
		<td class="plaintext_blue"><font color="#000000">*</font> Party/Event Time:</td>
		<td>

<script language="JavaScript">
<!-- Begin
	sTD = '<%=mtgDateS%>';
	if (sTD=="null" || sTD=="")
		sTD = "<%=df1.format(new Date())%>";	//formatDate(new Date(), "MM/dd/yyyy");

	document.write("<input class='formtext' type='Text' name='StartDate' size='25' onClick='show_cal(newQuestion.StartDate, newQuestion.ExpireDate)' ");
	document.write("value='" + sTD + "'>&nbsp;");
// End -->
</script>
			<a href='javascript:show_cal(newQuestion.StartDate, newQuestion.ExpireDate);'>
			<img src="../i/calendar.gif" border="0" align="absmiddle" alt="Click to view calendar."></a>
			&nbsp;&nbsp;
			<select class="formtext" name="StartTime" onChange="copyTime()">

<script language="JavaScript">
<!-- Begin

	var stTS = '<%=stTimeS%>';
	if (stTS=="null" || stTS=="")
	{
		localDt = getLocalDate(new Date(), <%=myTimeZoneOffset%>);
		hr = localDt.getHours();
		stMin = localDt.getMinutes();
		if (stMin > 15 && stMin < 45)
			displayMins = "30";
		else if (stMin >= 45)
			hr++;
		stTS = hr + ":" + displayMins;
		if (hr > 23) {
			var f = document.newQuestion;
			var startDate = getDateFromFormat(f.StartDate.value, "MM/dd/yyyy");
			startDate = getLocalDate(new Date(startDate + 86400000), <%=myTimeZoneOffset%>);
			f.StartDate.value = formatDate(startDate, "MM/dd/yyyy");
		}
	}

	var t = 11;
	var half = false;
	for(i=0; i < 48; i++)
	{
		var ts = (t%12+1) + ":";
		var val = ((t-11)%24) + ":";
		if (half) {ts += "30"; val += "30"; t++;}
		else {ts += "00"; val += "00";}
		if (i < 24) ts += " AM";
		else ts += " PM";
		document.write("<option value='" + val + "'");
		if (stTS==val) document.write(" selected");
		document.write(">" + ts + "</option>");
		half = !half;
	}
// End -->
</script>

			</select>
<%
		out.print("<span class='plaintext_blue'>");
		out.print("<img src='../i/spacer.gif' width='100' height='1'/>");
		out.print("Duration:");
		out.print("<select class='formtext' name='Duration' >");

		for (int i=1; i<=20; i++) {
			int val = i * 15;	// min
			String valS = Util3.getTimeString(val);
			out.print("<option value='" + val + "'");
			if (duration == val) out.print(" selected");
			out.print(">" + valS + "</option>");
		}

		out.print("</select></span>");
	}
	else {
		// is quest
%>

<!-- expire date -->
	<tr<%=hide%>>
		<td width="20">&nbsp;</td>
		<td class="plaintext_blue"><font color="#000000">*</font> <%=endLabel%>:</td>
		<td>

<script language="JavaScript">
<!-- Begin
	eTD = '<%=mtgDateES%>';
	if (eTD=="null" || eTD=="")
	{
		if (sTD != null)
			eTD = sTD;
		else
			eTD = "<%=df1.format(new Date())%>";	//formatDate(new Date(), "MM/dd/yyyy");
	}

		document.write("<input class='formtext' type='Text' name='ExpireDate' size='25' onClick='show_cal(newQuestion.ExpireDate, newQuestion.StartDate)' ");
		document.write("value='" + eTD + "'>");
// End -->
</script>
			&nbsp;<a href="javascript:show_cal(newQuestion.ExpireDate, newQuestion.StartDate);"><img src="../i/calendar.gif" border="0" align="absmiddle" alt="Click to view calendar."></a>
			&nbsp;&nbsp;
			<select class="formtext" name="ExpireTime">

<script language="JavaScript">
<!-- Begin

	var exTS = '<%=exTimeS%>';

	if (exTS=="null" || exTS=="") {
		if (sTD == null)
		{
			hr = new Date().getHours();
			exMin = new Date().getMinutes();
			if (exMin > 15 && exMin < 45)
				displayMins = "30";
			else if (exMin >= 45)
				hr++;
			exTS = hr + ":" + displayMins;
		}

		if (hr > 22) {
			var f = document.newQuestion;
			var expDate = getDateFromFormat(f.ExpireDate.value, "MM/dd/yyyy");
			expDate = new Date(expDate + 86400000);
			f.ExpireDate.value = formatDate(expDate, "MM/dd/yyyy");
			nextDay = true;
			hr = hr-24;
		}
		exTS = (hr+1) + ":" + displayMins;
	}

	var t = 11;
	var half = false;
	for(i=0; i < 48; i++)
	{
		var ts = (t%12+1) + ":";
		var val = ((t-11)%24) + ":";
		if (half) {ts += "30"; val += "30"; t++;}
		else {ts += "00"; val += "00";}
		if (i < 24) ts += " AM";
		else ts += " PM";
		document.write("<option value='" + val + "'");
		if (exTS==val) document.write(" selected");
		document.write(">" + ts + "</option>");
		half = !half;
	}
// End -->
</script>
	
<%	
	}	// END: else is quest
%>

		</td>
	</tr>
	
	<tr>
		<td colspan='2'></td>
		<td class='plaintext'>(<%=myUI.getZoneString()%>)</td>
	</tr>
	
	<tr><td colspan='3'><img src='../i/spacer.gif' height='15' /></td></tr>


<!-- Type -->
<%
	///////////////////////////////////////////////////////////////////////////////////
	String checked = "";
	String disabled = "";
	if (meetingType.equalsIgnoreCase(meeting.PUBLIC)) {checked="CHECKED='CHECKED'"; disabled="disabled";}
	
	String typeTooltip = "title='Public " + label1 + " can be seen by all " + appS + " members."
			+ "\nPrivate " + label1 + " can only be seen by invitees'";

	// @ECC102706 (company is the same as circle)
	townManager tnMgr = townManager.getInstance();
	String companyTooltip = "";
	String companyName = null;
	Object [] myTownIds = me.getAttribute("Towns");
	if (myTownIds[0] != null)
	{
		companyTooltip = "title='" + label0 + " " + label1 + " can be seen by " + label0 + " members."
			+ "\nPrivate Personal " + label1 + " is only seen by invitees'";
	}
%>
	<tr><td colspan="3"><img src='../i/spacer.gif' height='5'></td></tr>

	<tr>
		<td width="20">&nbsp;</td>
		<td colspan='2'>
		<table border='0' cellspacing='0' cellpadding='0'>
		<tr>
			<td width='158' class="plaintext_blue"><font color="#000000">*</font>&nbsp;Privacy:</td>
			<td width='200' class="formtext" <%=typeTooltip%>>
				<input type="radio" name="meetingType" value="<%=meeting.PUBLIC%>" <%=checked%> onClick='setPublic(true)'>Public
					&nbsp;
<% 	checked = "";
	if (meetingType.equalsIgnoreCase(meeting.PRIVATE)) checked="CHECKED='CHECKED'";
%>
				<input type="radio" name="meetingType" value="<%=meeting.PRIVATE %>" <%=checked%> onClick='setPublic(false)'>Private
			</td>
			
<%	////////////////////////
	// @ECC102706
	ids = null;
	PstAbstractObject [] tnArr = null;
	if (myTownIds[0] != null)
	{
		if (myTownIds[0] != null)
		{
			ids = new int[myTownIds.length];
			for (int i=0; i<myTownIds.length; i++)
				ids[i] = ((Integer)myTownIds[i]).intValue();
		}
		// Company or Circle
%>
			<td width='80' class="plaintext_blue">&nbsp;<%=label0%>:</td>
			<td class="formtext" <%=companyTooltip%>>
				<select name="company" class='formtext' <%=disabled%>>
				<option value='0'>- -</option>
				
<%
		int iCompany = Integer.parseInt(company);
		out.print("<option value='0'");
		if (iCompany==0 && meetingType.equals(quest.PRIVATE))
			out.print(" selected");
		out.print(">Personal</option>");
		tnArr = tnMgr.get(me, ids);
		Util.sortString(tnArr, "Name", true);
		for (int i=0; i<tnArr.length; i++)
		{
			int id = tnArr[i].getObjectId();
			companyName = (String)tnArr[i].getAttribute("Name")[0];
			out.print("<option value='" + id + "'");
			if (id == iCompany) out.print(" selected");
			out.print(">" + companyName + "</option>");
		}
		out.print("</select>");
	}
%>
		</tr>
		</table>
		</td>
	</tr>

<tr><td colspan="3"><img src='../i/spacer.gif' height='5'></td></tr>
	
<!-- @ECC110206 Description -->
	<tr <%=hide%>>
		<td width="20">&nbsp;</td>
		<td class="plaintext_blue" valign='top'=>&nbsp;&nbsp;&nbsp;Description:</td>
		<td><table border='0' cellspacing='0' cellpadding='0'><tr>
			<td class="formtext">
			<textarea name="Description" wrap="physical" onFocus="return doclear(this);"
				onBlur="return defaultText(this);"
				rows="4" cols="59"><%=descStr%></textarea>
			</td>
			<td class='plaintext' valign='top'>&nbsp;
			<input type="Button" value="Add Map" class="button_medium" onclick="javascript:add_map();">
			</td>
			</tr></table>
		</td>
	</tr>

<tr><td colspan="3">&nbsp;</td></tr>

<!-- Target Group -->
<tr>
		<td width="20">&nbsp;</td>
		<td valign="top" class="plaintext_blue">&nbsp;&nbsp;&nbsp;Target Group:</td>
		<td class="formtext">
			<select class="formtext" name="SelectGroup" onchange="changeTeam(0);">
<%
//@AGQ022806	
	out.print("<option value='-1'");
	if (projTeamId == -1)
		out.print(" selected");
	if (!isOMFAPP)
		out.print(">- select project team -</option>");
	else
		out.print(">- select target group -</option>");

	out.print("<option value='0'");
	if (projTeamId == 0)
		out.print(" selected");
	// @AGQ081706
	if (isOMFAPP)
	{
		// @ECC121806
		out.print(">My Friends</option>");
		if (tnArr != null)
		for (int i=0; i<tnArr.length; i++)
		{
			int tid = tnArr[i].getObjectId();
			out.print("<option value='"+ tid + "'");
			if (projTeamId == tid) out.print(" selected");
			out.print(">" + (String)tnArr[i].getAttribute("Name")[0] + "</option>");
		}
	}
	else
	{
		out.print(">My Contacts</option>");

		// for !isOMFAPP, use project to show contact lists
		int [] pjObjId = pjMgr.getProjects(pstuser);
		if (pjObjId.length > 0 && !isOMFAPP)
		{
			PstAbstractObject [] projectObjList = pjMgr.get(pstuser, pjObjId);
			//@041906SWS
			Util.sortName(projectObjList, true);

			project pj;
			int id;
			String projName;
			for (int i=0; i < projectObjList.length ; i++)
			{
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
	}
	out.print("</select>");
%>
<!-- End of Meeting Group -->
<tr><td colspan="3"><img src="../i/spacer.gif" width="5" height="3"></td></tr>


<!-- Mandatory Attendees -->
<tr>
		<td width="20">&nbsp;</td>
		<td valign="top" class="plaintext_blue">&nbsp;&nbsp;&nbsp;Participants:</td>
		<td>

		<!-- Mandatory -->
		<table border="0" cellspacing="0" cellpadding="0">
		<tr>
			<td>
			<select class="formtext_fix" name="Select1" id="Select1" multiple size="5">
<%
		boolean found;
		user u;
		String firstName, lastName, uName;
		ArrayList dlSelectList = new ArrayList();		// this list contain all members not on optional or mandatory list yet
		if (dlArr != null && dlArr.length > 0)
		{
			for (int i=0; i < dlArr.length; i++)
			{
				if (dlArr[i] == null) continue;
				found = false;
				int memId = dlArr[i].getObjectId();
				for (int j=0; j<mandatoryIds.size(); j++)
				{	
					int id = dl.getId(mandatoryIds.get(j).toString());
					if (memId == id)
					{
						found = true;
						break;
					}
					// there are no more DL since the list is sorted
					else if (id == -1)
						break;
				}
				if (found) continue;	// this member is in the mandatory list
		
				// not yet on neither the mandatory nor optional list
				dlSelectList.add(dlArr[i]);
			}
		}
//	 @AGQ022806
		String prevName = null;
		for(int i = 0; i < dlSelectList.size(); i++) {
			dl curDl = (dl)dlSelectList.get(i);
			String curName = curDl.getObjectName();
			if(prevName != null) {
				if(!prevName.equalsIgnoreCase(curName)) {
					out.print("<option value='" + dl.DLESCAPESTR + curDl.getObjectId() + "'>* " + curName + "</option>");
				}
			}
			else {
					out.print("<option value='" + dl.DLESCAPESTR + curDl.getObjectId() + "'>* " + curName + "</option>");
			}		
			prevName = curName;
		}
			ArrayList selectList = new ArrayList();		// this list contain all members not on optional or mandatory list yet
			if (mtgMember != null && mtgMember.length > 0)
			{
				for (int i=0; i < mtgMember.length; i++)
				{
					if (mtgMember[i] == null) continue;
					found = false;
					int memId = mtgMember[i].getObjectId();
					for (int j=0; j<mandatoryIds.size(); j++)
					{
// @AGQ022806
						if (dl.getId(mandatoryIds.get(j).toString()) != -1)
								continue;
						else {
							int id = Integer.parseInt((String)mandatoryIds.get(j));
							if (memId == id)
							{
								found = true;
								break;
							}
						}
					}
					if (found) continue;	// this member is in the mandatory list

					// not yet on neither the mandatory nor optional list
					selectList.add(mtgMember[i]);
				}
			}

			for (int i=0; i<selectList.size(); i++)
			{
				u = (user)selectList.get(i);
				uName = u.getFullName();
				out.println("<option value='" +u.getObjectId()+ "'>&nbsp;" +uName+ "</option>");
			}
%>
			</select>
			</td>
			<td>&nbsp;&nbsp;&nbsp;</td>
			<td align="center" valign="middle">
<%-- @AGQ080206 --%>			
				<input type="button" class="button" name="add1" value="&nbsp;&nbsp;&nbsp;&nbsp;Add &gt;&gt;&nbsp;&nbsp;" onClick="swapdata(this.form.Select1,this.form.MandatoryAttendee)">
				<div><input type="button" class="button" name="remove1" value="<< Remove" onClick="swapdata(this.form.MandatoryAttendee,this.form.Select1)"></div>
			</td>
			<td>&nbsp;&nbsp;&nbsp;</td>
<!-- people selected -->
			<td bgcolor="#FFFFFF">
				<select class="formtext_fix" name="MandatoryAttendee" id="MandatoryAttendee" multiple size="5">
<%
// @AGQ022806
				dl dlObj = null;
				for (int i=0; i<mandatoryIds.size(); i++)
				{
					dlObj = null;
					u = null;
					try{					
// @AGQ022806
						String temp = mandatoryIds.get(i).toString();
						if (dl.getId(temp) != -1) {
							dlObj = (dl)dlMgr.get(me, dl.getId(temp));
						}
						else
	 						u = (user)uMgr.get(me, Integer.parseInt(temp));
					}
					catch (PmpException e){continue;}
					if (dlObj != null ) {
						out.print("<option value='" + dl.DLESCAPESTR + dlObj.getObjectId() + "'>* " + dlObj.getObjectName() + "</option>");	
					}
					else if ( u != null ) {
						uName = u.getFullName();
						out.println("<option value='" +mandatoryIds.get(i)+ "'>&nbsp;" +uName+ "</option>");
					}
				}
%>
				</select>
			</td>
		</tr>
		</table>
</td>
</tr>
<!-- End of Mandatory Attendee -->
<tr><td colspan="3"><img src="../i/spacer.gif" width="5" height="3"></td></tr>


<tr><td colspan="3">&nbsp;</td></tr>

<!-- Guest Emails -->
<tr>
	<td width="20">&nbsp;</td>
	<td valign="top" class="plaintext_blue">&nbsp;&nbsp;&nbsp;Invite Guests:</td>
	<td>
		<table border="0" cellspacing="0" cellpadding="0">
			<tr>
				<td>
					<input id="guestEmails" name="guestEmails" class="formtext" type="text" size="80" value="<%=guestEmails %>" />
				</td>
			</tr>
			<tr>
				<td>
					<span class="footnotes">Enter email addresses separated by commas (e.g. aaa@z.com, bbb@z.com)</span>
				</td>
			</tr>
		</table>
	</td>
</tr>
<!-- End of Guest Emails -->


<!-- Submit Button -->
	<tr>
		<td width="20">&nbsp;</td>
		<td colspan=2 class="10ptype" align="center"><br>
			<input type="Button" value="   Cancel  " class="button_medium" onclick="history.back(-1)">&nbsp;
<% if (isUpdate) { %> <input type="Button" value="   Delete  " class="button_medium" onclick="javascript:deleteQuest();">&nbsp;<%} %>
			<input type="Button" value="   Finish  " class="button_medium" onclick="javascript:finish();">&nbsp;
			<input type="Submit" name="Submit" class="button_medium" <%=nextButton%> onclick="return validation();">
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
		<!-- Footer -->
		<jsp:include page="../foot.jsp" flush="true"/>
		<!-- End of Footer -->
	</td>
</tr>
</table>
</body>
</html>
