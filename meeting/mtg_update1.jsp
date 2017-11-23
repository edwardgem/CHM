<%@ page contentType="text/html; charset=utf-8"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2005, EGI Technologies, Co.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: mtg_update1.jsp
//	Author: ECC
//	Date:	02/24/05
//	Description: Update a meeting before going live.
//
//
//	Modification:
//
//		@AGQ030606	Add support of DL 
//		@AGQ030606a	When changing projects, the current TeamMembers will still be selected
//		@AGQ030806	Support of GuestEmails
//		@AGQ033006	Added method to escape special chars into html codes
//		@AGQ040306	Support of multi upload files
//		@041906SSI	Added sort function to Project names.
//		@ECC061206a	Add project association to meeting.
//		@SWS061406	Updated file listing.
//		@AGQ081606	Changed option to include meeting Type (e.g. public or private)
//		@AGQ081806	Removed relationship to projects for OMF
//		@ECC110206	Add Description attribute.
//		@ECC121806	Allow choosing contacts from my companies.
//		@ECC062807	Authorize multiple people to update meeting record.
//		@ECC100708	Clipboard actions.
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

	String midS = request.getParameter("mid");
	PstUserAbstractObject me = pstuser;
	if ((me instanceof PstGuest) || (midS == null))
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	String host = Util.getPropKey("pst", "PRM_HOST");
	String s;

	int myUid = me.getObjectId();

	String updateRecur = "";
	if (request.getParameter("UpdateRecur") != null)
		updateRecur = "checked";

	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ( (iRole & user.iROLE_ADMIN) > 0 )
		isAdmin = true;
	
	// to check if session is OMF or PRM
	boolean isMeetWE = Prm.isMeetWE();
	String app = Prm.getAppTitle();		

	userManager uMgr = userManager.getInstance();
	meetingManager mMgr = meetingManager.getInstance();
	meeting mtg = (meeting)mMgr.get(me, midS);
	attachmentManager attMgr = attachmentManager.getInstance();
	projectManager pjMgr = projectManager.getInstance();
	questManager qMgr = questManager.getInstance();
	userinfoManager uiMgr = userinfoManager.getInstance();
	townManager tnMgr = townManager.getInstance();
	
	userinfo myUI = (userinfo) uiMgr.get(pstuser, String.valueOf(myUid));
	TimeZone myTimeZone = myUI.getTimeZone();
	int myTimeZoneOffset = myUI.getTimeZoneIdx();
	
	SimpleDateFormat df1 = new SimpleDateFormat ("MM/dd/yyyy hh:mm a");
	SimpleDateFormat df2 = new SimpleDateFormat ("MM/dd/yyyy");
	SimpleDateFormat df3 = new SimpleDateFormat ("H:mm");
	if (!userinfo.isServerTimeZone(myTimeZone)) {
		df1.setTimeZone(myTimeZone);
		df2.setTimeZone(myTimeZone);
		df3.setTimeZone(myTimeZone);
	}
	
	String status = (String)mtg.getAttribute("Status")[0];
	if (!status.equals(meeting.NEW))
	{
		if (status.equals(meeting.FINISH) || status.equals(meeting.EXPIRE))
		{
			// also allow owner/admin to update expired meeting: might have met outside of PRM
			response.sendRedirect("mtg_update2.jsp?mid="+midS);
			return;
		}
		else
		{
			response.sendRedirect("../out.jsp?msg=You cannot update the meeting information when the meeting is at the " + status + " state.");
			return;
		}
	}
	
	String companyLabel;
	if (isMeetWE)
		companyLabel = "Circle";
	else
		companyLabel = "Company";

	// date
	int duration = 60;		// default meeting duration: 60 min
	String stTimeS, exTimeS;
	String mtgDateS = request.getParameter("StartDate");
System.out.println("stDate=" + mtgDateS);
	Date dt, dt1;

	if (mtgDateS == null)
	{
		dt = (Date) mtg.getAttribute("StartDate")[0];
		dt1 = (Date) mtg.getAttribute("ExpireDate")[0];
		mtgDateS = df1.format(dt);
		stTimeS = df3.format(dt);
		exTimeS = df3.format(dt1);		
		duration = (int) (dt1.getTime() - dt.getTime())/60000;	// in min
	}
	else
	{
		stTimeS = request.getParameter("StartTime");
		exTimeS = request.getParameter("ExpireTime");	
		s = request.getParameter("Duration");
		if (!StringUtil.isNullOrEmptyString(s)) duration = Integer.parseInt(s);
	}

	// record user entered other location in loc
	String loc = null;
	if (loc == null)
	{
		loc = request.getParameter("Location");
		if (loc == null) loc = "";
	}
	
	// time

	String [] sa;
	int id;
	int recurMult = 1;
	String recurring = (String)mtg.getAttribute("Recurring")[0];
	if (recurring != null)
	{
		sa = recurring.split(meeting.DELIMITER);
		recurring = sa[0];
		recurMult = Integer.parseInt(sa[1]);
	}
	else recurring = "";

	s = request.getParameter("Owner");
	if (s==null)
		s = (String)mtg.getAttribute("Owner")[0];
	int ownerId = Integer.parseInt(s);
	user u = (user)uMgr.get(me, ownerId);
	String ownerName = u.getFullName();

	// get attendee list
	Object [] attendeeArr = mtg.getAttribute("Attendee");
	ArrayList mandatoryIds = new ArrayList();
	ArrayList optionalIds = new ArrayList();
	int [] iResponsibleArr = new int[attendeeArr.length];		// @ECC062807

	for (int i=0; i<attendeeArr.length; i++)
	{
		s = (String)attendeeArr[i];
		if (s == null) break;
		sa = s.split(meeting.DELIMITER);

		if (sa[1].startsWith(meeting.ATT_MANDATORY))
			mandatoryIds.add(sa[0]);
		else
			optionalIds.add(sa[0]);
		iResponsibleArr[i] = Integer.parseInt(sa[0]);			// @ECC062807
	}
	
	// @ECC062807 set up responsible list
	PstAbstractObject [] respObjArr = uMgr.get(me, iResponsibleArr);
	Object [] objArr = mtg.getAttribute("Responsible");
	for (int i=0; i<iResponsibleArr.length; i++)
	{
		for (int j=0; j<objArr.length; j++)
		{
			s = (String)objArr[j];
			if (s == null) break;
			id = Integer.parseInt(s);
			if (id==iResponsibleArr[i])
			{
				respObjArr[i] = null;	// already chosen as responsible persons
				break;
			}
		}
		if (ownerId==iResponsibleArr[i])
			respObjArr[i] = null;		// this is the owner
	}
	Util.sortName(respObjArr);

// @AGQ030606a	
	String [] prevManIds = request.getParameterValues("MandatoryAttendee");
	String [] prevOptIds = request.getParameterValues("OptionalAttendee");
	String prevChangeTeam = request.getParameter("isChangeTeam");
	if (prevChangeTeam != null) {
		mandatoryIds.clear();
		optionalIds.clear();
		if (prevManIds != null) {
			for (int i=0;i<prevManIds.length;i++) {
				mandatoryIds.add(prevManIds[i]);
			}
		}
		if (prevOptIds != null) {
			for (int i=0;i<prevOptIds.length;i++) {
				optionalIds.add(prevOptIds[i]);
			}
		}
	}
	// check to see if user just selected a Meeting Group to invite
	boolean bInviting = false;
	int projTeamId = -2;
	if (isMeetWE) projTeamId = 0;
	s = request.getParameter("SelectGroup");
	if (s!=null && s.length()>0) {
		bInviting = true;
		projTeamId = Integer.parseInt(s);
	}
	
	String subject = request.getParameter("Subject");
	if (subject == null)
		subject = (String)mtg.getAttribute("Subject")[0];
	subject = Util.stringToHTMLString(subject);

	String location = request.getParameter("Location");
	if (location == null)
	{
		// no form value, get it from the meeting object
		location = (String)mtg.getAttribute("Location")[0];
		if (location == null)
			location = "";
	}
	
	//String locationName = Util.stringToHTMLString(location);
	
	// this meeting is associated to a project?
	int thisMeetingPid = 0;
	s = (String)mtg.getAttribute("ProjectID")[0];
	if (s != null) {
		thisMeetingPid = Integer.parseInt(s);
		if (projTeamId == -2) projTeamId = thisMeetingPid;
	}

	PstAbstractObject [] mtgMember = null;
	PstAbstractObject [] dlArr = null;
	dlManager dlMgr = dlManager.getInstance();
	
	// dl 
	if (projTeamId == -1) {
		dlArr = dlMgr.getDLs(me);
		Util.sortName(dlArr);
	}
	// all users
	else if (projTeamId == 0) {
		if (!isMeetWE || isAdmin)
			mtgMember = ((user)me).getAllUsers();
		else {
			objArr = ((user) me).getAttribute(user.TEAMMEMBERS);
			if (objArr[0]!=null)
			{
				mtgMember = uMgr.get(me, objArr);
				Util.sortUserArray(mtgMember, true);
			}
			else
				mtgMember = new PstAbstractObject[0];
		}
	}
	else if (projTeamId > 0)
	{
		if (!isMeetWE)
			mtgMember = ((user)me).getTeamMembers(projTeamId);
		else
		{
			// ECC121806: for OMFAPP, support choosing contacts from my companies
			int [] ids = uMgr.findId(me, "Towns=" + projTeamId);
			mtgMember = uMgr.get(me, ids);
		}
	}
	
	// @ECC062807 authorized multiple people to update meeting record and actions
	boolean canUpdate = false;
	if (ownerId==myUid)
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

	// check authority
	boolean bUploadOnly = false;
	String UserEdit = "disabled";
	String UserEditCal = "onClick='return false'";
	if (isAdmin || canUpdate)
	{
		UserEdit = "";
		UserEditCal = "";
	}
	else
		bUploadOnly = true;
	
	// @ECC110206
	String defaultTxt = ">> (Optional) Enter a short paragraph to describe this meeting.";
	Object bTextObj = mtg.getAttribute("Description")[0];
	String descStr = (bTextObj==null)? defaultTxt : new String((byte[])bTextObj, "utf-8");
	descStr = descStr.replaceAll("<br>", "\n");
	descStr = descStr.replaceAll("&nbsp;", " ");
	
	confManager cfMgr = confManager.getInstance();
	int [] ids1 = cfMgr.findId(pstuser, "om_acctname='%'");
	PstAbstractObject [] roomArr = cfMgr.get(pstuser, ids1);

	////////////////////////////////////////////////////////
%>

<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<%-- @AGQ040406 --%>
<script src="../multifile.js"></script>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen" />
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print" />
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../formsM.jsp" flush="true"/>
<jsp:include page="../forms.jsp" flush="true"/>
<script language="JavaScript" src="../get-date.js"></script>
<script language="JavaScript" src="../date.js"></script>
<script language="JavaScript" src="../util.js"></script>

<script language="JavaScript">
<!--

function fo()
{
	f = document.updMeeting;
	for (i=0;i < f.length;i++)
	{
		if (f.elements[i].type!="hidden" && !f.elements[i].disabled)
		{
			f.elements[i].focus();
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
// @AGQ040306
	if (e)
		e.focus();
}

function validation()
{
	var f = document.updMeeting;
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
	
	var location = f.Location.value;
	for (i=0;i<location.length;i++) {
		char = location.charAt(i);
		if (char == '\\') {
			fixElement(f.Location,
				"LOCATION cannot contain these characters: \n  \\");
			return false;
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

	var dt = new Date(f.StartDate.value + " " + f.StartTime.value);
	var tm = dt.getTime();
	f.StartDT.value = tm;			// simply pass the msec as a string	
	f.ExpireDT.value = tm + f.Duration.value*60000;


	// check for illegal char in filename
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
	
	var s1 = '<%=bUploadOnly%>';
	if (s1=='true')
	{
		updMeeting.UploadOnly.value = "true";
	}
	else if ( (updMeeting.Continue.value != 'true')
		&& confirm("Do you want to resend the meeting requests? (OK=YES; Cancel=NO)"))
	{
		updMeeting.SendMail.value = "true";
	}

	// @ECC110206
	if (f.Description.value.substring(0,2) == ">>")
		f.Description.value = '';

	selectAll(updMeeting.MandatoryAttendee);
	selectAll(updMeeting.OptionalAttendee);
	selectAll(updMeeting.Responsible);
	updMeeting.encoding = "multipart/form-data";

	return true;
}

function setAddFile()
{
// @AGQ040306
	if (multi_selector.count == 1)
	{
		fixElement(document.getElementById("my_file_element"), "To add a file attachment, click the Browse button and choose a file to be attached, then click the Add button.");
		return false;
	}

	updMeeting.Continue.value = 'true';		// come back to this page
	return validation();
}

var nextDay = false;

function copyDate(Source, Target)
{
	// copy startDate to expireDate
	//var f = document.updMeeting;
	//f.ExpireDate.value = f.StartDate.value;
	var source = document.getElementsByName(Source).value;
	document.getElementsByName(Target).value = source;
	if (nextDay) nextDay = false;
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
	var es = 'updMeeting.' + e1.name;
	var es2 = null;
	if (e2 != null )
	{
		es2 = 'updMeeting.' + e2.name;
	}
	var number = parseInt(mon);
	var number2 = parseInt(yr);
	if (isNaN(number) || isNaN(number2)) {
		dt = new Date();
		mon = '' + dt.getMonth();
		yr = '' + dt.getFullYear();
	}
	show_calendar(es, mon, yr, null, es2);
}

function copyTime()
{
	var f = document.updMeeting;
	var ts = f.StartTime.value.split(":");
	if (ts[0] > 22) {
		if (f.ExpireDate.value == f.StartDate.value) {
			var expDate = getDateFromFormat(f.ExpireDate.value, "MM/dd/yyyy");
			expDate = new Date(expDate + 86400000);
			f.ExpireDate.value = formatDate(expDate, "MM/dd/yyyy");
			nextDay = true;
		}
		ts[0] = ts[0]-24;
	}
	else if (nextDay) {
		copyDate(f.StartDate, f.ExpireDate);
	}
	var s = parseInt(ts[0]) + 1;
	f.ExpireTime.value = s + ":" + ts[1];
}

function changeTeam()
{
	if (multi_selector.count > 1)
	{
		var isConfirm = confirm("Files to be upload will be removed. \nPlease click 'OK' to continue. \nOr click 'Cancel' and click 'Upload Files' to upload files.");
		if (!isConfirm) {
			var selectList = document.getElementById("SelectGroup");
			var isFound = false;
			for (var i=0; i<selectList.options.length; i++) {
				if (selectList.options[i].value == "<%=projTeamId %>") {
					selectList.options[i].selected = true;
					isFound = true;
					break;
				}
			}
			if (!isFound) {
				selectList.options[0].selected = true;
			}	
			return;
		}
	}
// @AGQ030606a
	selectAll(document.getElementById("MandatoryAttendee"));
	selectAll(document.getElementById("OptionalAttendee"));
	updMeeting.action = "mtg_update1.jsp";
	updMeeting.encoding = "application/x-www-form-urlencoded";
	updMeeting.submit();
}

function selectAll(select) {
	var length = select.length;
	for(var i = 0; i < length; i++) {
		select.options[i].selected = true;
	}
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
		e.value = '<%=defaultTxt%>';
	return;
}

function setPublic(public)
{
	if (updMeeting.company) {
		if (public)
			updMeeting.company.disabled = true;
		else
			updMeeting.company.disabled = false;
	}
}

function selectConfRoom()
{
	var e1 = document.getElementById("Location")
	var e2 = document.getElementById("confRoomSelect");
	if (e2.value == "other") {
		e1.disabled = false;
	}
	else {
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
.plaintext_blue {line-height: 30px}
.formtext {font-size: 12px;}
</style>


</head>

<title><%=app%> Update Meeting</title>
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
                	<b>Update Meeting Information</b>
					</td></tr>
	            </table>
	          </td>
	        </tr>
	    </table>
	    <table width="90%" border="0" cellspacing="0" cellpadding="0">
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
<%-- @AGQ040306 --%>
<form method="post" name="updMeeting" action="post_mtg_upd1.jsp" enctype="multipart/form-data">
<input type="hidden" name="mid" value="<%=midS%>">
<input type="hidden" name="SendMail">
<input type="hidden" name="UploadOnly">
<input type="hidden" name="Continue">
<input type="hidden" name="LocalStartDT" value="">
<input type="hidden" name="StartDT" value="">
<input type="hidden" name="ExpireDT" value="">
<input type="hidden" name="isChangeTeam" value="false">

<input type='hidden' name='ExpireDate' value='' />

<table width="90%" border="0" cellspacing="0" cellpadding="0">
<%
	// error message display
	String errmsg = (String)session.getAttribute("errorMsg");
	if (errmsg != null)
	{
		session.removeAttribute("errorMsg");
		out.print("<tr><td width='20'>&nbsp;</td>");
		out.print("<td colspan='2' class='plaintext' style='color:#ee0000'>" + errmsg + "</td></tr>");
	}
%>
<tr><td colspan="3">&nbsp;</td></tr>

<!-- Subject -->
	<tr>
		<td width="20">&nbsp;</td>
		<td class="plaintext_blue" width='200'><font color="#000000">*</font> Subject:</td>
		<td>
			<input class="formtext" type="text" name="Subject" style='width:575px'
				value="<%=subject%>" <%=UserEdit%>>
		</td>
	</tr>


<!-- start date -->
	<tr>
		<td width="20">&nbsp;</td>
		<td class="plaintext_blue"><font color="#000000">*</font> Start Time:</td>
		<td>
<script language="JavaScript">
<!-- Begin: Need local (user's laptop) time so must use JavaScript
	var stTS = null;
	var sTD = '<%=mtgDateS%>';
	var idx = sTD.indexOf(' ');
	
	if (idx != -1)
		sTD = sTD.substring(0, idx);

	//var dt = new Date(sTD);
	//sTD = formatDate(dt, "MM/dd/yyyy");
	
	if ("<%=stTimeS%>" == "null")
		stTS = sTD.substring(idx+1);	//formatDate(dt, "H:mm");
	else
		stTS = '<%=stTimeS%>';

	document.write("<input class='formtext' type='Text' name='StartDate' size='25'  onClick='show_cal(updMeeting.StartDate, updMeeting.ExpireDate)' onChange='copyDate(updMeeting.StartDate, updMeeting.ExpireDate)'");
	document.write("value='" + sTD + "' " + "<%=UserEdit%>" + ">&nbsp;");
// End -->
</script>
			<a href="javascript:show_cal(updMeeting.StartDate, updMeeting.ExpireDate);" <%=UserEditCal%>><img src="../i/calendar.gif" border="0" align="absmiddle" alt="Click to view calendar."></a>
			&nbsp;&nbsp;
			<select class="formtext" name="StartTime" <%=UserEdit%>>
<script language="JavaScript">
<!-- Begin

	var t = 11;
	//var half = false;
	var m = "00";
	for(i=0; i < 96; i++)
	{
		var ts = (t%12+1) + ":";
		var val = ((t-11)%24) + ":";
		/*if (half) {ts += "30"; val += "30"; t++;}
		else {ts += "00"; val += "00";}*/
		
		ts += m; val += m;
		if (m=="00") m="15";
		else if (m=="15") m="30";
		else if (m=="30") m="45";
		else if (m=="45") {m="00"; t++}
		
		if (i < 48) ts += " AM";
		else ts += " PM";
		document.write("<option value='" + val + "'");
		if (stTS==val) document.write(" selected");
		document.write(">" + ts + "</option>");
		//half = !half;
	}
// End -->
</script>
			</select>
			
		<span class='plaintext_blue'>
			<img src='../i/spacer.gif' width='100' height='1'/>
			Duration:
			<select class='formtext' name='Duration'  <%=UserEdit%>>
<%
			for (int i=1; i<=20; i++) {
				int val = i * 15;	// min
				String valS = Util3.getTimeString(val);
				out.print("<option value='" + val + "'");
				if (duration == val) out.print(" selected");
				out.print(">" + valS + "</option>");
			}
%>
			</select>
		</span>
		</td>
	</tr>
	
	<tr>
		<td colspan='2'></td>
		<td class='plaintext'>(<%=myUI.getZoneString()%>)</td>
		
	</tr>

<%

	out.print("<tr><td colspan='3'><img src='../i/spacer.gif' height='5'></td></tr>");

	String uName;
	boolean found;
	
	// invite panel
	out.print("<tr><td colspan='3'>");
	out.print(Util.getHeaderPartitionLine());
	out.print("<img id='ImgInvitePanel' src='../i/bullet_tri.gif'/>");
	if (bInviting) s = "Hide invite";
	else s = "Invite";
	out.print("<a id='AInvitePanel' href='javascript:togglePanel(\"InvitePanel\", \"Invite\", \"Hide invite\");' class='listlinkbold'>"
		+ s + "</a>");
	
	if (bInviting) s = "block";
	else s = "none";
	out.print("<DIV id='DivInvitePanel' style='display:" + s + ";'>");
	out.print("<table border='0' cellspacing='0' cellpadding='0'>");	// invite panel table
%>

<tr><td><img src='../i/spacer.gif' height='20' width='1'/></td></tr>


<!-- Meeting Group -->
<tr>
	<td width="20">&nbsp;</td>
	<td width='200' valign="top" class="plaintext_blue">&nbsp;&nbsp;&nbsp;Meeting Group:</td>
	<td class="formtext">
		<select class="formtext" name="SelectGroup" id="SelectGroup" onchange="changeTeam();" <%=UserEdit%>>
<%
	if (!isMeetWE) {
		out.print("<option value=''>- Select Project Team -</option>");
	}

	out.print("<option value='-1'");
	if (projTeamId == -1)
		out.print(" selected");
	out.print(">* User List</option>");
	
	out.print("<option value='0'");
	if (projTeamId == 0)
		out.print(" selected");
	
	if (isMeetWE)
	{
		// @ECC121806
		out.print(">My Contacts</option>");
		Object [] towns = me.getAttribute("Towns");
		for (int i=0; i<towns.length; i++)
		{
			if (towns[i] == null) break;
			int tid = ((Integer)towns[i]).intValue();
			out.print("<option value='"+ tid + "'");
			if (projTeamId == tid) out.print(" selected");
			out.print(">" + (String)tnMgr.get(me, tid).getAttribute("Name")[0] + "</option>");
		}
	}
	else
		out.print(">All</option>");
	
	// for !isMeetWE, use project to show contact lists
	int [] pjObjId = pjMgr.findId(me, "(TeamMembers=" +myUid+ ")||(Type='Public%')");
	if (pjObjId.length > 0 && !isMeetWE)
	{
		PstAbstractObject [] projectObjList = pjMgr.get(me, pjObjId);
		//@041906SSI
		Util.sortName(projectObjList, true);
	
		String projName;
		project pj;
		for (int i=0; i < projectObjList.length ; i++)
		{
			// project
			pj = (project) projectObjList[i];
			projName = pj.getDisplayName();
			id = pj.getObjectId();
	
			out.print("<option value='" + id + "'");
			if (id==projTeamId)
				out.print(" selected");
			out.print(">" + projName + "</option>");
		}
	}
	out.print("</select>");
%>

<tr><td colspan="3"><img src="../i/spacer.gif" height="5"></td></tr>

<!-- Owner -->
<tr>
	<td width="20">&nbsp;</td>
	<td class="plaintext_blue">&nbsp;&nbsp;&nbsp;Coordinator:</td>
	<td>
		<select class="formtext" type="text" name="Owner" <%=UserEdit%>>
<%
		String firstName, lastName;
		if (mtgMember != null && mtgMember.length > 0)
		{
			for (int i=0; i<mtgMember.length; i++)
			{
				if (mtgMember[i] == null) continue;
				id = mtgMember[i].getObjectId();
				firstName = (String)mtgMember[i].getAttribute("FirstName")[0];
				lastName = (String)mtgMember[i].getAttribute("LastName")[0];
				uName = firstName + (lastName==null?"":(" "+lastName));
				out.print("<option value='" + id + "'");
				if (!isAdmin && myUid==id) out.print(" selected");
				else if (ownerId == id) out.print(" selected");
				out.println(">&nbsp;" +uName+ "</option>");
			}
		}
		else
		{
			out.print("<option value='" + ownerId + "'>" + ownerName + "</option>");
		}
%>
		</select>
	</td>
</tr>

<tr><td colspan="3"><img src="../i/spacer.gif" height="10"></td></tr>

<!-- Mandatory Attendees -->
<tr>
	<td width="20">&nbsp;</td>
	<td valign="top" class="plaintext_blue">&nbsp;&nbsp;&nbsp;Attendee:</td>
	<td>

	<!-- Mandatory -->
	<table border="0" cellspacing="0" cellpadding="0">
	<tr>
		<td>
		<select class="formtext_fix" name="Select1" multiple size="5" <%=UserEdit%>>
<%

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
					id = dl.getId(mandatoryIds.get(j).toString());
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
				else
				{
					// check to see if the member is on the optional list
					for (int j=0; j<optionalIds.size(); j++)
					{
						id = dl.getId(optionalIds.get(j).toString());
						if (memId == id)
						{
							found = true;
							break;
						}
						// there are no more DL since the list is sorted
						else if (id == -1)
							break;
					}
				}
				if (found) continue;	// this member is in the optional list
		
				// not yet on neither the mandatory nor optional list
				dlSelectList.add(dlArr[i]);
			}
		}
//@AGQ030606
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
					if (dl.getId(mandatoryIds.get(j).toString()) != -1)
						continue;
					else {
						id = Integer.parseInt((String)mandatoryIds.get(j));
						if (memId == id)
						{
							found = true;
							break;
						}
					}
				}
				if (found) continue;	// this member is in the mandatory list
				else
				{
					// check to see if the member is on the optional list
					for (int j=0; j<optionalIds.size(); j++)
					{
						if (dl.getId(optionalIds.get(j).toString()) != -1)
							continue;
						else {
							id = Integer.parseInt((String)optionalIds.get(j));
							if (memId == id)
							{
								found = true;
								break;
							}
						}
					}
				}
				if (found) continue;	// this member is in the optional list

				// not yet on neither the mandatory nor optional list
				selectList.add(mtgMember[i]);
			}
		}

		for (int i=0; i<selectList.size(); i++)
		{
			u = (user)selectList.get(i);
			firstName = (String)u.getAttribute("FirstName")[0];
			lastName = (String)u.getAttribute("LastName")[0];
			uName = firstName + (lastName==null?"":(" "+lastName));
			out.println("<option value='" +u.getObjectId()+ "'>&nbsp;" +uName+ "</option>");
		}
%>
		</select>
		</td>
		<td>&nbsp;&nbsp;&nbsp;</td>
		<td align="center" valign="middle">
			<input type="button" class="button" name="add1" value="&nbsp;&nbsp;&nbsp;&nbsp;Add &gt;&gt;&nbsp;&nbsp;" onClick="swapdataM(this.form.Select1,this.form.MandatoryAttendee,this.form.Select2,this.form.OptionalAttendee)">
			<div><input type="button" class="button" name="remove1" value="<< Remove" onClick="swapdataM1(this.form.MandatoryAttendee,this.form.Select1,this.form.Select2)"></div>
		</td>
		<td>&nbsp;&nbsp;&nbsp;</td>
<!-- people selected -->
		<td bgcolor="#FFFFFF">
			<select class="formtext_fix" name="MandatoryAttendee" id="MandatoryAttendee" multiple size="5" <%=UserEdit%>>
<%
//@AGQ030606
			dl dlObj = null;
			for (int i=0; i<mandatoryIds.size(); i++)
			{
				dlObj = null;
				u = null;
				try{
					String temp = mandatoryIds.get(i).toString();
					if (dl.getId(temp) != -1) {
						dlObj = (dl)dlMgr.get(me, dl.getId(temp));
					}
					else
 						u = (user)uMgr.get(me, Integer.parseInt(temp));
				} catch (PmpException e){continue;}
				if (dlObj != null ) {
					out.print("<option value='" + dl.DLESCAPESTR + dlObj.getObjectId() + "'>* " + dlObj.getObjectName() + "</option>");	
				}
				else if ( u != null ) {
					firstName = (String)u.getAttribute("FirstName")[0];
					lastName = (String)u.getAttribute("LastName")[0];
					uName = firstName + (lastName==null?"":(" "+lastName));
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


<!-- Optional Attendees -->
<tr>
	<td width="20">&nbsp;</td>
	<td valign="top" class="plaintext_blue">&nbsp;&nbsp;&nbsp;Optional Attendee:</td>
	<td>

	<!-- Optional -->
	<table border="0" cellspacing="0" cellpadding="0">
	<tr>
		<td>
		<select class="formtext_fix" name="Select2" multiple size="5" <%=UserEdit%>>
<%
//@AGQ030606 
		// Display the DL 
		prevName = null;
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
		// set up select list on the left (same as the mandatory select list)
		for (int i=0; i<selectList.size(); i++)
		{
			u = (user)selectList.get(i);
			firstName = (String)u.getAttribute("FirstName")[0];
			lastName = (String)u.getAttribute("LastName")[0];
			uName = firstName + (lastName==null?"":(" "+lastName));
			out.println("<option value='" +u.getObjectId()+ "'>&nbsp;" +uName+ "</option>");
		}
%>
		</select>
		</td>
		<td>&nbsp;&nbsp;&nbsp;</td>
		<td align="center" valign="middle">
			<input type="button" class="button" name="add2" value="&nbsp;&nbsp;&nbsp;&nbsp;Add &gt;&gt;&nbsp;&nbsp;" onClick="swapdataM(this.form.Select2,this.form.OptionalAttendee,this.form.Select1,this.form.MandatoryAttendee)">
		<div><input type="button" class="button" name="remove2" value="<< Remove" onClick="swapdataM1(this.form.OptionalAttendee,this.form.Select2,this.form.Select1)"></div>
		</td>
		<td>&nbsp;&nbsp;&nbsp;</td>
<!-- people selected -->
		<td bgcolor="#FFFFFF">
			<select class="formtext_fix" name="OptionalAttendee" id="OptionalAttendee" multiple size="5" <%=UserEdit%>>
<%
//@AGQ030606
			for (int i=0; i<optionalIds.size(); i++)
			{
				dlObj = null;
				u = null;
				try{				
					String temp = optionalIds.get(i).toString();
					if (dl.getId(temp) != -1) {
						dlObj = (dl)dlMgr.get(me, dl.getId(temp));
					}
					else
						u = (user)uMgr.get(me, Integer.parseInt(temp));
				} catch (PmpException e){continue;}
				if (dlObj != null ) {
					out.print("<option value='" + dl.DLESCAPESTR + dlObj.getObjectId() + "'>* " + dlObj.getObjectName() + "</option>");	
				}
				else if (u != null) {
					firstName = (String)u.getAttribute("FirstName")[0];
					lastName = (String)u.getAttribute("LastName")[0];
					uName = firstName + (lastName==null?"":(" "+lastName));
					out.println("<option value='" +optionalIds.get(i)+ "'>&nbsp;" +uName+ "</option>");
				}
			}
%>
			</select>
		</td>
	</tr>
	</table>
</td>
</tr>
<!-- End of Optional Attendee -->
<%
	String prevGuestEmails = request.getParameter("guestEmails");
	StringBuffer guestEmails = new StringBuffer();
	if (prevGuestEmails != null) {
		guestEmails.append(prevGuestEmails);
	}
	// When this page is first called 
	else {
		Object [] obj = mtg.getAttribute("GuestEmails");
		
		if (obj[0] != null) {
			for (int i=0;i<obj.length;i++) 
				guestEmails.append(obj[i] + ", ");
		}
	}
	
	String guestStr;
	if (canUpdate || isAdmin)
		guestStr = guestEmails.toString();
	else
		guestStr = String.valueOf(guestEmails.toString().split(",").length) + " guests";
%>
<tr><td colspan="3">&nbsp;</td></tr>

<!-- Guest Emails -->
<tr>
<td width="20">&nbsp;</td>
<td valign="top" class="plaintext_blue">&nbsp;&nbsp;&nbsp;Invite Guests:</td>
<td>
	<table border="0" cellspacing="0" cellpadding="0">
		<tr>
			<td>
				<input id="guestEmails" name="guestEmails" class="formtext" type="text" style='width:575px;'
					value="<%=guestStr %>"/ <%=UserEdit%>>
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
<!-- End Guest Emails -->
<tr><td colspan="3">&nbsp;</td></tr>

<%
	////////////////////////////////////
	// close invite panel
	out.print("</table></DIV>");	// END invite panel table
	out.print("</td></tr>");


	////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////
	// panel for meeting info
	out.print("<tr><td colspan='3'>");
	out.print(Util.getHeaderPartitionLine());
	out.print("<img id='ImgInfoPanel' src='../i/bullet_tri.gif'/>");
	out.print("<a id='AInfoPanel' href='javascript:togglePanel(\"InfoPanel\", \"Meeting info\", \"Hide meeting info\");' class='listlinkbold'>Meeting info</a>");
	
	out.print("<DIV id='DivInfoPanel' style='display:none;'>");
	out.print("<table border='0' cellspacing='0' cellpadding='0'>");	// Info panel table
	
%>
	<tr><td><img src='../i/spacer.gif' height='20' width='1'/></td></tr>

	
<!-- Description -->
	<tr>
		<td width="20">&nbsp;</td>
		<td width='200' class="plaintext_blue" valign='top'>&nbsp;&nbsp;&nbsp;Description:</td>
		<td class="formtext">
			<textarea name="Description" onfocus="return doclear(this);"
				onBlur="return defaultText(this);"
				style='width:575px;'
				rows="4" <%=UserEdit%>><%=descStr%></textarea>
		</td>
	</tr>

	<tr><td colspan="3"><img src="../i/spacer.gif" height="5"/></td></tr>


<!-- Recurring -->
	<tr>
		<td width="20">&nbsp;</td>
		<td class="plaintext_blue">&nbsp;&nbsp;&nbsp;Recurring Event:</td>
		<td class="formtext">
			<select class="formtext" name="Recurring" disabled>
			<option value=''>- Not recurring -</option>
<%
	boolean isRecurring = false;
	for (int i=0; i<meeting.RECUR_ARR.length; i++)
	{
		out.print("<option value='" + meeting.RECUR_ARR[i] + "'");
		if (meeting.RECUR_ARR[i].equals(recurring))
		{
			out.print(" selected");
			isRecurring = true;
		}
		out.print(">" + meeting.RECUR_ARR[i] + "</option>");
	}
%>
			</select>

			&nbsp;&nbsp;End after:
			<input class="formtext" type="text" name="RecurMultiple" size="2" value="<%=recurMult%>" disabled>
			&nbsp;more occurrences
		</td>
	</tr>

<!-- Update all recurring event? -->
<%	if (isRecurring && recurMult>0)
	{%>
	<tr>
		<td colspan='2'></td>
		<td class="formtext">
		<input class="plaintext_big" type="checkbox" name="UpdateRecur" <%=UserEdit%> <%=updateRecur%>>Update all recurring events after this
		</td>
	</tr>
<%	}%>

<!-- Location -->
	<tr>
		<td width="20">&nbsp;</td>
		<td class="plaintext_blue">&nbsp;&nbsp;&nbsp;Location:</td>
		<td>
		<select id ='confRoomSelect' name='confRoomSelect' onchange='selectConfRoom();' <%=UserEdit%>>
		 
		<option value="">- select location -</option>
<%
		boolean isDefinedRoom = false;
		for (int i=0; i<roomArr.length; i++) {
			out.print("<option value='" + roomArr[i].getObjectId() + "' ");
			if (location.equals(roomArr[i].getObjectName())) {
				out.print(" selected");
				isDefinedRoom = true;
			}
			out.print(">" + roomArr[i].getStringAttribute("Name") + "</option>");
		}
		  
		out.print("<option value='other'");
		if (!isDefinedRoom) {
			// other location was selected
			out.print(" selected");
			if (StringUtil.isNullOrEmptyString(loc))
				loc = location;			// get it from the meeting object
		}
		out.print(">other</option>");
		
		out.print("</select> &nbsp;&nbsp;");
		
		out.print("<input class='formtext' type='text' id='Location' name='Location' size='20' value='" + loc + "' ");
		if (isDefinedRoom)
			out.print("disabled");
		else
			out.print(UserEdit);
		out.print(">");
%>
		
			</td>
	</tr>


<!-- Associated Project -->
<%
	if (!isMeetWE) {
%>
	<tr>
		<td width="20">&nbsp;</td>
		<td class="plaintext_blue">&nbsp;&nbsp;&nbsp;Project:</td>
		<td>
		<select name="projId" class="formtext" <%=UserEdit%>>
<%
	out.println("<option value=''>- select project name -</option>");
	
	int [] projectObjId = pjMgr.getProjects(me);
	if (projectObjId.length > 0)
	{
		PstAbstractObject [] projectObjList = pjMgr.get(me, projectObjId);
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
			id = pj.getObjectId();

			out.print("<option value='" + id +"' ");
			if (id == thisMeetingPid)
				out.print("selected");
			out.print(">" + pName + "</option>");
		}
	}
%>
		</select>
		</td>
	</tr>
<%	}
	else {
		out.println("<input type='hidden' value='' name='projId'");
	}
%>


<!-- Quest -->
<%
	int [] ids = qMgr.findId(me, "MeetingID='" + midS + "'");
	if (ids.length > 0)
		s = String.valueOf(ids[0]);		// just take the first one
	else
		s = "";
%>
<tr>
<td width="20">&nbsp;</td>
<td class="plaintext_blue">&nbsp;&nbsp;&nbsp;Questionnaire/Survey:</td>
<td>
	<input class='formtext' type='text' name='Quest' size='6' value='<%=s%>' <%=UserEdit%>>
</td>
</tr>

<!-- Type -->
<% 	// @AGQ081606
	String checked = "";
	String disabled = "";
	String meetingType = (String) mtg.getAttribute(meeting.TYPE)[0];
	if (meetingType == null) meetingType = meeting.PRIVATE;
	if (meetingType.equalsIgnoreCase(meeting.PUBLIC)) {
		checked="CHECKED='CHECKED'";
		//disabled="disabled";
	}
	
	String typeTooltip = "title='Public meeting is open for all " + app + " members"
			+ "\nPrivate meeting is only open for invitees'";

	// @ECC102706
	String companyTooltip = "";
	int townId = 0;
	s = (String)mtg.getAttribute("TownID")[0];
	if (s!=null && s.length()>0 && !s.equals("null")) townId = Integer.parseInt(s);
	String companyName = null;
	Object [] myTownIds = null;
	
	if (isAdmin) {
		ids = tnMgr.findId(me, "om_acctname='%'");
		myTownIds = Util3.toInteger(ids);
	}
	else
		myTownIds = me.getAttribute("Towns");
%>
	<tr>
		<td width="20">&nbsp;</td>
		<td colspan='2'>
		<table border='0' cellspacing='0' cellpadding='0'>
		<tr>
			<td width='200' class="plaintext_blue"><font color="#000000">*</font>&nbsp;Type:</td>
			<td width='300' class="formtext" <%=typeTooltip%>>
				<input type="radio" name="meetingType" value="<%=meeting.PUBLIC%>" <%=checked%> <%=UserEdit%> onClick='setPublic(true)'>Public
					&nbsp;
<%
	checked = "";
	if (meetingType.equalsIgnoreCase(meeting.PRIVATE)) {
		checked="CHECKED='CHECKED'";
	}
	
	out.print("<input type='radio' name='meetingType' value='"
			+ meeting.PRIVATE + "' " + checked + " onClick='setPublic(false)'>Private &nbsp;");
	
	checked = "";
	if (meetingType.equalsIgnoreCase(meeting.PUBLIC_READ_URL)) {
		checked="CHECKED='CHECKED'";
	}
	out.print("<input type='radio' name='meetingType' value='"
			+ meeting.PUBLIC_READ_URL + "' " + checked + " onClick='setPublic(false)'>Public Read-only &nbsp;");
	
	out.print("</td>");
			
	////////////////////////
	// @ECC102706
	if (myTownIds[0] != null)
	{
		companyTooltip = "title='Company meeting can be seen by all employees of the same company"
			+ "\nPersonal meeting is only seen by meeting invitees'";
%>
			<td width='80' class="plaintext_blue">&nbsp;<%=companyLabel%>:</td>
			<td class="formtext" <%=companyTooltip%>>
				<select name="company" class='formtext' <%=disabled%> <%=UserEdit%>>
				<option value='0'>Personal</option>
<%
		for (int i=0; i<myTownIds.length; i++)
		{
			id = ((Integer)myTownIds[i]).intValue();
			companyName = (String)tnMgr.get(me, id).getAttribute("Name")[0];
			out.print("<option value='" + id + "'");
			if (id == townId) out.print(" selected");
			out.print(">" + companyName + "</option>");
		}
		out.print("</select></td>");
	}
%>
			
		</tr>
		</table>
		</td>
	</tr>	
	<tr><td colspan="3"><img src='../i/spacer.gif' height='15'></td></tr>


<!-- Authorize to Update -->
<tr>
<td width="20">&nbsp;</td>
<td valign="top" class="plaintext_blue">&nbsp;&nbsp;&nbsp;Authorize to Update:</td>
<td>

<table border="0" cellspacing="0" cellpadding="0">
<tr>
	<td>
	<select class="formtext_fix" name="SelectR" multiple size="5" <%=UserEdit%>>
<%
	
	for (int i=0; i<respObjArr.length; i++)
	{
		u = (user)respObjArr[i];
		if (u == null) continue;
		uName = u.getFullName();
		out.println("<option value='" + u.getObjectId() + "'>&nbsp;" +uName+ "</option>");
	}
%>
	</select>
	</td>
	<td>&nbsp;&nbsp;&nbsp;</td>
	<td align="center" valign="middle">
		<input type="button" class="button" name="add3" value="&nbsp;&nbsp;&nbsp;&nbsp;Add &gt;&gt;&nbsp;&nbsp;" onClick="swapdata(this.form.SelectR,this.form.Responsible)">
		<div><input type="button" class="button" name="remove3" value="<< Remove" onClick="swapdata(this.form.Responsible,this.form.SelectR)"></div>
	</td>
	<td>&nbsp;&nbsp;&nbsp;</td>
<!-- people selected -->
	<td bgcolor="#FFFFFF">
		<select class="formtext_fix" name="Responsible" id="Responsible" multiple size="5" <%=UserEdit%>>
<%
		objArr = mtg.getAttribute("Responsible");
		found = false;
		for (int i=0; i<objArr.length; i++)
		{
			if (objArr[i] == null) break;
			if (Integer.parseInt((String)objArr[i]) == ownerId)
			{
				found = true;
				break;
			}
		}
		for (int i=0; i<objArr.length; i++)
		{
			if (objArr[i] == null) break;
			try {u = (user)uMgr.get(me, Integer.parseInt((String)objArr[i]));}
			catch (PmpException e){continue;}
			uName = u.getFullName();
			out.println("<option value='" + u.getObjectId() + "'>&nbsp;" +uName+ "</option>");
		}
		if (!found)
			out.println("<option value='" + ownerId + "'>&nbsp;" +ownerName+ "</option>");
%>
		</select>
	</td>
</tr>
</table>
</td>
</tr>

	<tr><td colspan="3"><img src='../i/spacer.gif' height='10'></td></tr>

<!-- New file attachment -->
<tr>
	<td width="20">&nbsp;</td>
	<td class="plaintext_blue" valign="top">&nbsp;&nbsp;&nbsp;Add File Attachment:</td>
	<td class="formtext">
		<span id="inputs"><input id="my_file_element" type="file" class="button_browse" size="50" /></span><br /><br />
		Files to be uploaded:<br />
		<table><tbody id="files_list"></tbody></table>
		<script>
			var multi_selector = new MultiSelector( document.getElementById( 'files_list' ), 0, document.getElementById( 'my_file_element' ).className , document.getElementById( 'my_file_element' ).size );
			multi_selector.addElement( document.getElementById( 'my_file_element' ) );
		</script>
		<div id='uploadButton' style='display:none;'>
			<input type="submit" class="button_medium" name="add"
				value="&nbsp;&nbsp;Upload Files&nbsp;&nbsp;" onClick="return setAddFile();">
		</div>
	</td>
</tr>
<tr>
	<td width="20">&nbsp;</td>
</tr>
<!-- list file attachments -->
<tr>
	<td width="20">&nbsp;</td>
	<td class="plaintext_blue" valign="top">&nbsp;&nbsp;&nbsp;File Attachment:</td>
	<td class="formtext">
		<table border="0" cellspacing="0" cellpadding="0">
<%
	// @SWS061406 begins
	Object [] attmtList = mtg.getAttribute("AttachmentID");
	int [] aids = Util2.toIntArray(attmtList);
	int [] linkIds = attMgr.findId(me, "Link='" + midS + "'");		// @ECC103008
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
	<td width="250" bgcolor="#6699cc" class="td_header"><strong>&nbsp;File Name</strong></td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="80" bgcolor="#6699cc" class="td_header"><strong>Owner</strong></td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="120" bgcolor="#6699cc" class="td_header" align="left"><strong>Posted On</strong></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	</tr>
<%
		Arrays.sort(aids);
		for (int i=0; i<aids.length; i++)
		{
			// list files by alphabetical order
			attmtObj = (attachment)attMgr.get(me, aids[i]);
			uName = attmtObj.getOwnerDisplayName(me);
			attmtCreateDt = (Date)attmtObj.getAttribute("CreatedDate")[0];
			fileName = attmtObj.getFileName();

			out.print("<tr>");
			out.print("<td class='plaintext' width='318'>"
				+ "&nbsp;<a class='listlink' href='" + host + "/servlet/ShowFile?attId=" + aids[i] + "'>" + fileName + "</a>");
			if (Arrays.binarySearch(linkIds, aids[i]) >= 0)
				out.print("&nbsp;&nbsp;<a href='" + host + "/project/goto_link.jsp?attId=" + aids[i] + "'>"
					+ "<img src='../i/link.jpg' border='0' title='This is a link file' /></a>");
			out.print("</td>");
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td class='formtext'><a href='../ep/ep1.jsp?uid=" + (String)attmtObj.getAttribute("Owner")[0] + "' class='listlink'>" + uName + "</a></td>");
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td class='formtext'>" + df2.format(attmtCreateDt) + "</td>");
			out.print("<td>&nbsp;</td>");
			out.print("<td><input class='formtext' type='button' class='button_medium' value='Delete'"
				+ "onclick='return affirm_delfile(\"../project/post_delfile.jsp?mid=" + midS + "&attId=" + aids[i] + "\");' align='right'></td>");
			out.println("</tr>");
		}
	}	// @SWS061406 ends
	out.println("</table></td></tr>");
%>

<!-- end file attachment -->

<%	
	// @ECC100708 paste from clipboard
	PstAbstractObject o;
	s = (String)session.getAttribute("clipboard");
	if (s != null)
	{
		out.print("<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>");
		out.print("<tr><td colspan='2'></td><td><table><tr>");
		out.print("<td><img src='../i/clipboard.jpg' /></td>");
		out.print("<td class='plaintext'><a href='javascript:paste();'>Paste files from Clipboard</a></td></tr></table></td></tr>");
		
		// put the form for selecting files as display:none
		out.print("<tr><td colspan='2'></td><td><div id='clipboard' style='display:none'>");
		out.print("<input type='hidden' name='op' value=''>");
		out.print("<input type='hidden' name='backPage' value='../meeting/mtg_update1.jsp?mid=" + midS + "'>");
		out.print("<table>");
		sa = s.split(";");
		for (int i=0; i<sa.length; i++)
		{
			o = attMgr.get(me, sa[i]);
			s = ((attachment)o).getFileName();
			out.print("<tr><td class='formtext'><input type='checkbox' name='clip_" + sa[i]
			      + "'>" + s + "</td></tr>");
		}
		
		// buttons
		out.print("<tr><td class='formtext' align='center'>"
				+ "<input class='formtext' type='button' name='Link' value='&nbsp;Link&nbsp;' onclick='clip(0, updMeeting);'>&nbsp;&nbsp;"
				+ "<input class='formtext' type='button' name='Copy' value='Copy' onclick='clip(1, updMeeting);'>&nbsp;&nbsp;"
				+ "<input class='formtext' type='button' name='Move' value='Move' onclick='clip(2, updMeeting);'>&nbsp;&nbsp;"
				+ "<input class='formtext' type='button' name='Cancel' value='Cancel' onclick='closeClip();'>"
				+ "</td></tr>");
		out.print("</table>");
		out.print("</div>");
		out.print("</td></tr>");
	}
%>

	<tr><td colspan='3'><img src='../i/spacer.gif' height='5'></td></tr>

<%
	/////////////////////////////////////////
	// close meeting info panel
	out.print("</table></DIV>");	// END Info panel table
	out.print("</td></tr>");
%>


<tr><td colspan="3">&nbsp;</td></tr>

<!-- Submit Button -->
	<tr>
		<td width="20">&nbsp;</td>
		<td colspan=2 class="10ptype" align="center"><br>
			<input type='submit' class='button_medium' value='Submit' onclick='return validation();'>
			&nbsp;
			<input type='button' class='button_medium' value='Cancel' onclick="location='mtg_view.jsp?mid=<%=midS%>&refresh=1';">
		</td>
	</tr>




		<!-- End of Content Table -->
		<!-- End of Main Tables -->

</table>

</form>
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
