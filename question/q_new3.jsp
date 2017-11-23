<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2008, EGI Technologies, Co.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: q_new3.jsp
//	Author: ECC
//	Date:	01/02/08
//	Description: Create a new questionnaire.
//	Modification:
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
	// Step 3 of 3 in setting up meeting
	PstUserAbstractObject me = pstuser;

	String subject = request.getParameter("Subject");
	subject = Util.stringToHTMLString(subject);
	String qidS = request.getParameter("Qid");

	if ( (me instanceof PstGuest) || (subject==null && qidS==null) )
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}

	int myUid = me.getObjectId();
	userManager uMgr = userManager.getInstance();
	meetingManager mMgr = meetingManager.getInstance();
	dlManager dlMgr = dlManager.getInstance();
	questManager qMgr = questManager.getInstance();
	
	String s;
	
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	
	// to check if session is OMF or PRM
	boolean isOMFAPP = false;
	String appS = (String)session.getAttribute("app");
	if (appS.equals("OMF"))
	{
		appS = "MeetWE";
		isOMFAPP = true;
	}
	
	String type=null, agendaS=null, descStr=null;
	
	// support coming in this page to just send email reminder
	PstAbstractObject qObj = null;
	Object bTextObj;
	boolean bSendReminderOnly = (s=request.getParameter("send"))!=null && s.equals("1");
	if (qidS!=null && bSendReminderOnly) {
		// get the quest from database
		qObj = qMgr.get(pstuser, qidS);
		type = (String)qObj.getAttribute("Type")[0];
		bTextObj = qObj.getAttribute("Content")[0];
		agendaS = (bTextObj==null)?"":new String((byte[])bTextObj, "utf-8");
		bTextObj = qObj.getAttribute("Description")[0];
		descStr = (bTextObj==null)?"":new String((byte[])bTextObj, "utf-8");
	}

	boolean isEvent = false;
	String label1 = "";
	String subCatLabel;
	String qType;
	String qShare = "";
	
	if (type == null) {
		qType = request.getParameter("Qtype");
		qShare = request.getParameter("Qshare");
	}
	else {
		if (type.contains("event"))
			qType = quest.TYPE_EVENT;
		else
			qType = quest.TYPE_QUEST;
		
		if (type.contains(quest.NO_SHARE))
			qShare = quest.NO_SHARE;
	}
	
	if (qType.equals(quest.TYPE_EVENT))
	{
		isEvent = true;
		label1 = "Event";
		subCatLabel = "NewEvent";
	}
	else
	{
		label1 = "Questionnaire";
		subCatLabel = "NewQuestion";
	}

	String parentIdS = request.getParameter("ParentId");
	String location = request.getParameter("Location");
	if (location != null)
		location = Util.stringToHTMLString(location);
	String localDT = request.getParameter("LocalStartDT");
	String startDT = request.getParameter("StartDT");
	String expireDT = request.getParameter("ExpireDT");
	String endT = request.getParameter("ExpireTime");
	String sendDT = request.getParameter("SendDT");
	if (type == null)
		type = request.getParameter("Type");
	String templateName = request.getParameter("TemplateName");
	String meetingType = request.getParameter("meetingType");	
	String company = request.getParameter("company");
	String emailStr = request.getParameter("guestEmails");
	String selectGp = request.getParameter("SelectGroup");		// @ECC110206
	String mandatoryS = dlMgr.removeDuplicate(me, request.getParameter("Mandatory"), ";");
	String [] manArr = request.getParameterValues("MandatoryAttendee");
	if (agendaS == null)
		agendaS = request.getParameter("Agenda");
	String agendaS2 = Util.stringToHTMLString(agendaS);		// can't handle the HTML for the Prev button at the bottom of this file
	String midS = request.getParameter("mid");
	String projectS = request.getParameter("ProjectId");
	
	String optMsg = request.getParameter("message");
	if (optMsg == null || optMsg.length() <= 0 || optMsg.equals("null")) optMsg = "";

	if (descStr == null)
		descStr = request.getParameter("Description");
	descStr = Util.stringToHTMLString(descStr);

	String qDateS = request.getParameter("QstartDate");
	String qTimeS = request.getParameter("QstartTime");
	String expireDate = request.getParameter("ExpireDate");
	if (expireDate==null) expireDate="";		
	String expireTime = request.getParameter("ExpireTime");
	if (expireTime==null) expireTime="";
	String durationS = request.getParameter("Duration");
	if (durationS==null) durationS="";


// begin setting up questions

	Vector rAgenda = null;
	try {rAgenda = JwTask.getAgendaVector(agendaS);}
	catch (PmpException e)
	{
		String msg = e.toString();
		response.sendRedirect("../out.jsp?msg="+ msg);
	}

// end of setting up questions

	// get all attendees, plus owner if not on attendee list
	ArrayList attendeeList = new ArrayList();
	user u;
	boolean found = false;
	int id;
	String [] sa;
	if (mandatoryS!=null && mandatoryS.length()>0)
	{
		sa = mandatoryS.split(";");	// id1;id2;id3,...
		for (int i=0; i<sa.length; i++)
		{
			id = Integer.parseInt(sa[i]);
			if (id == myUid) found = true;
			u = (user)uMgr.get(me, id);
			attendeeList.add(u);
		}
	}
	if (!found)
		attendeeList.add(me);

	Object [] attendeeArr = attendeeList.toArray();
	Util.sortUserArray(attendeeArr, true);
	int numOfAttendee = attendeeArr.length;

%>


<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<jsp:include page="../init.jsp" flush="true"/>
<script language="JavaScript" src="../get-date.js"></script>
<script language="JavaScript" src="../date.js"></script>
<script language="JavaScript">
<!--
function validation()
{
/*
	var f = document.newQuestion;
	var dt = new Date(f.ReqDate.value + " " + f.ReqTime.value);
	var now = new Date();
	var tm = dt.getTime();
	if (tm <= now.getTime())
		f.qSend.value = "0";				// send it now; will ignore SendDT
	else
		f.SendDT.value = '' + tm;			// simply pass the msec as a string
*/	
	return true;
}

function showMessage()
{
	var e = document.getElementById('optMessage');
	if (newQuestion.SendAlert.checked == true)
		e.style.display = 'block';
	else
		e.style.display = 'none';
}

function goBack() {
	var backPage = "q_new2.jsp";
	newQuestion.action = backPage;
	newQuestion.submit();
}


function show_cal(e1)
{
	if (disableS != "") return;
	
	var dt;
	if (e1.value!=null)
		dt = new Date(e1.value);
	else
		dt = new Date();
	var mon = '' + dt.getMonth();
	var yr = '' + dt.getFullYear();
	if (yr.length==2) yr = '20' + yr;		// 13 change to 2013
	else if (yr.length==1) yr = '200' + yr;	// because 05 will become 5
	var es = 'newQuestion.' + e1.name;
	var number = parseInt(mon);
	var number2 = parseInt(yr);
// @AGQ050406a
	if (isNaN(number) || isNaN(number2)) {
		dt = new Date();
		mon = '' + dt.getMonth();
		yr = '' + dt.getFullYear();
	}
	show_calendar(es, mon, yr, null, null);
}

function enableDate(op)
{
	// for now, remove the EffectiveDate for schedule a notification
	// simply hide the option to send email when not sending now
	var e = document.getElementById('optMsg1');
	if (op == true)
		e.style.display = "block";
	else
		e.style.display = "none";
	newQuestion.SendAlert.checked = op;
	if (op) showMessage();
	
/*  // use the following when EffectiveDate is back in
	var s;
	if (op == true) s = "";
	else s = "disabled";

	// enable/disable entering date/time
	disableS = s;
	newQuestion.ReqDate.disabled = s;
	newQuestion.ReqTime.disabled = s;
*/
}

//-->
</script>

</head>

<title><%=appS%></title>
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
                	<td width="754" height="30" align="left" valign="bottom" class="head">
                	<b>Set Up 
<%
	if (isEvent) {out.print("an Invite for Party / Event");}
	else {out.print("a Questionnaire / Survey / Vote");}
%>
                	</b>
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
 <table width="715" border="0" cellspacing="0" cellpadding="0">
	<tr>
		<td width="15">&nbsp;</td>
		<td class="instruction_head"><br><b>Step 3 of 3: Review and Complete 
<%	if (isEvent) out.print("Party / Event Invitation");
	else out.print("Questionnaire / Survey / Vote Request");
%>
		</b></td>
	</tr>

	<tr>
		<td width="15"><img src="../i/spacer.gif" width="15" border="0"></td>
		<td class="plaintext_big">
			<br>
			<table width="100%" border="0" cellspacing="0" cellpadding="0">
			<tr>
				<td>
<form method="post" name="newQuestion" action="post_q_new.jsp">

<%
	//char a;
	StringBuffer summaryBuf = new StringBuffer();
	out.println("<table width='100%' border='0' cellspacing='0' cellpadding='0'><tr>");
	out.print("<td valign='top'><img src='../i/spacer.gif' width='20' /></td>");
	out.println("<td valign='top'><table width='100%' border='0' cellspacing='0' cellpadding='0'>");
	out.println(JwTask.printQuest(rAgenda, summaryBuf, numOfAttendee, null, null));
%>
				</td>
				</tr>
			</table>
			
			</td>
		</tr>

		</table>

<input type="hidden" name="Qid" value="<%=qidS%>">
<input type="hidden" name="ParentId" value="<%=parentIdS%>">
<input type="hidden" name="Qtype" value="<%=qType%>" >
<input type="hidden" name="Qshare" value="<%=qShare%>">
<input type="hidden" name="Subject" value="<%=subject%>" >
<input type="hidden" name="Location" value="<%=location%>" >
<input type="hidden" name="LocalStartDT" value="<%=localDT%>" >
<input type="hidden" name="StartDT" value="<%=startDT%>" >
<input type="hidden" name="ExpireDT" value="<%=expireDT%>" >
<input type="hidden" name="SendDT" value="<%=sendDT%>" >
<input type="hidden" name="Mandatory" value="<%=mandatoryS%>" >
<input type="hidden" name="Description" value="<%=descStr%>" >
<input type="hidden" name="guestEmails" value="<%=emailStr%>" >
<input type="hidden" name="SelectGroup" value="<%=selectGp%>" >
<input type="hidden" name="Summary" value="<%=summaryBuf.toString()%>" >
<input type="hidden" name="mid" value="<%=midS%>" >
<input type="hidden" name="ProjectId" value="<%=projectS%>" >

<%
if (manArr != null) {	
	for (int j=0;j<manArr.length;j++) {
		out.println("<input type='hidden' name='MandatoryAttendee' value='"+manArr[j]+"'>");
	}
}
%>
<input type="hidden" name="Agenda" value="<%=agendaS2%>" >
<%-- @AGQ081506 --%>
<input type="hidden" name="Type" value="<%=type%>">
<input type="hidden" name="TemplateName" value="<%=templateName%>">
<%-- @AGQ081606 --%>
<input type="hidden" name="meetingType" value="<%=meetingType%>" >
<input type="hidden" name="company" value="<%=company%>" >
<input type="hidden" name="StartNow" value="">
<%
	String startTime = request.getParameter("QstartTime");
	if (startTime==null) startTime="";
	String startDate = request.getParameter("QstartDate");
	if (startDate==null) startDate="";	
%>
<input type="hidden" name="StartDate" value="<%=startDate%>">
<input type="hidden" name="StartTime" value="<%=startTime%>">
<input type="hidden" name="ExpireDate" value="<%=expireDate%>">
<input type="hidden" name="ExpireTime" value="<%=expireTime%>">
<input type="hidden" name="Duration" value="<%=durationS%>">

<table width="715" border="0" cellspacing="0" cellpadding="2">
  <tr>
    <td width="15">&nbsp;</td>
    <td width="700">&nbsp;</td>
  </tr>

  <tr><td colspan='2'><img src="../i/spacer.gif" border="0" width="15" height="10" /></td></tr>

<%

	// whether the quest summary is shared among all participates
	s = qShare=="" ? "checked" : "";
	out.print("<tr><td></td><td><table border='0' cellpadding='0' cellspacing='0'>");
	out.print("<tr><td class='level2'><input type='checkbox' name=' " + s + "'>Responses open to all participants");
	out.print("</td></tr></table>");
	out.print("<tr><td colspan='2'><img src='../i/spacer.gif' width='1' height='10'/></td></tr>");

	//////////////////////////////////////////////////////////////////////////////////////
	// Date and Time to send invitation or survey
	if (!bSendReminderOnly) {
		out.print("<tr><td colspan='2'><table border='0' cellpadding='0' cellspacing='0'>");
		out.print("<tr><td></td><td colspan='2' class='level2'>Are you ready to send the ");
		if (isEvent)
			out.print("Invitation");
		else
			out.print("Questionnaire/Survey/Vote request");
		out.print(" to people now?</td></tr>");
		out.print("<tr><td colspan='3'><img src='../i/spacer.gif' height='5' /></td></tr>");

%>
<!-- send invite date -->
	<tr>
		<td width="20">&nbsp;</td>
		<td class="plaintext" colspan='2'><input type="radio" name="qSend" value="0" onclick='javascript:enableDate(true);' checked>Yes.</td>
	</tr>
	
	<tr>
		<td width="20">&nbsp;</td>
		<td class="plaintext"><input type="radio" name="qSend" value="1" onclick='javascript:enableDate(false);'>No. Save the <%=label1%> in the Event Calendar for further update.</td>
		<td>

<script language="JavaScript">
<!-- Begin
/*
	var disableS = "disabled";
	if (newQuestion.qSend.value=="1")
		disableS = "";
	var sTD = '<%=qDateS%>';
	if (sTD=="null" || sTD=="")
		sTD = formatDate(new Date(), "MM/dd/yyyy");
	document.write("<input class='formtext' type='Text' name='ReqDate' size='25' onClick='show_cal(newQuestion.ReqDate)' ");
	document.write("value='" + sTD + "' " + disableS + ">&nbsp;");

	document.write("<a href='javascript:show_cal(newQuestion.ReqDate);'>");
	document.write("<img src='../i/calendar.gif' border='0' align='absmiddle' alt='Click to view calendar.'></a>&nbsp;&nbsp;");

	document.write("<select class='formtext' name='ReqTime' " + disableS + ">");

	var stTS = '<%=qTimeS%>';	
	var hr = 0;
	var stMin = 0;
	var displayMins = "00";
	if (stTS=="null" || stTS=="")
	{
		hr = new Date().getHours();
		stMin = new Date().getMinutes();
		if (stMin >= 0)
			hr++;
		stTS = hr + ":00";
		if (hr > 23) {
			var f = document.newQuestion;
			var reqDate = getDateFromFormat(f.ReqDate.value, "MM/dd/yyyy");
			reqDate = new Date(reqDate + 86400000);
			f.ReqDate.value = formatDate(reqDate, "MM/dd/yyyy");
		}
	}

	var t = 11;
	for(i=0; i < 24; i++)
	{
		var ts = (t%12+1) + ":";
		var val = ((t-11)%24) + ":";
		ts += "00"; val += "00";
		if (i < 12) ts += " AM";
		else ts += " PM";
		document.write("<option value='" + val + "'");
		if (stTS==val) document.write(" selected");
		document.write(">" + ts + "</option>");
		t++;
	}
*/
// End -->
</script>
<%
		// out.print("</select>");
		out.print("</td></tr></table></td></tr>");
	}
	else {
		// bSendReminderOnly
		out.print("<input type='hidden' name='qSend' value='0'>");
	}
%>
	 <tr><td colspan='2'><img src="../i/spacer.gif" border="0" height="10" /></td></tr>
	
	<tr><td colspan='2'>
	<div id='optMsg1' style='display:block'>
	<table border='0' cellspacing='0' cellpadding='0'>

	 <tr>
		<td><img src="../i/spacer.gif" border="0" width="10" /></td>
		<td class="plaintext_big">
			<input class="plaintext_big" type="checkbox" name="SendAlert" onClick="showMessage()" checked
	<%	if (bSendReminderOnly) {out.print(" disabled");} %>		
			> Send reminder Email to all participants
		</td>
	</tr>

	<tr>
	<td colspan='2'>
	<div id='optMessage' name='optMessage' style='display:block'>
	<table>
		<tr>
			<td width="15">&nbsp;</td>
	        <td class="formtext">
           &nbsp;You may add an optional personal message to the recipients:
        	</td>
		</tr>
		<tr>
			<td width="15">&nbsp;</td>
		   	<td>
		      <textarea name="message" cols="58" rows="5"><%=optMsg%></textarea>
		   	</td>
		</tr>
	</table>
	</div>
	</td>
	</tr>
	
	</table>
	</div>
	</td>
	</tr>

  <tr>
  	<td><img src='../i/spacer.gif' width='20'/></td>
    <td class='plaintext_big'>
    	Click the <b>Finished Button</b> to
<%
	if (!bSendReminderOnly)
		out.print(" complete the ");
	else
		out.print(" send reminder Email of the ");
		
	if (isEvent) out.print("invitation.");
	else out.print("questionnaire.");
	
	if (!bSendReminderOnly) {
		out.print("To make any changes, click \"<b>&lt;&lt; Prev</b>\" to go back to the previous page.");
	}
%>
		
	</td>
  </tr>
  <tr>
    <td>&nbsp;</td>
    <td width="100%" valign="top">
		<table border="0" cellspacing="0" cellpadding="2">
		  <tr>
		    <td colspan="2">&nbsp;</td>
		  </tr>
		  <tr>
		    <td colspan="2" align="center">
<%	if (!bSendReminderOnly) { %>		    
		<input type="Button" class="button_medium" value="  << Prev  " onclick="goBack()">&nbsp;
<%	}
	else {
		out.print("<input type='hidden' name='sendReminderOnly' value='true'>");
	}
%>
				<input type="Submit" class="button_medium" name="Submit" value=" Finished " onclick="return validation();">
		    </td>
		  </tr>
		</table>
	</td>
  </tr>
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
