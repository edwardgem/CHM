<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2008, EGI Technologies, Co.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: q_respond.jsp
//	Author: ECC
//	Date:	01/08/08
//	Description: Respond to a quest.
//
//
//	Modification:
//				@ECC020408	Link quest together as a series.
//				@ECC111708	Add RoboMail option.
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


<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	String qidS = request.getParameter("qid");
	String noSession = "../out.jsp?go=question/q_respond.jsp?qid="+qidS;
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%
	////////////////////////////////////////////////////////
	final int RADIO_NUM = 4;
	PstUserAbstractObject me = pstuser;

	if (me instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	int myUid = me.getObjectId();
	String myUidS = String.valueOf(myUid);
	String myName = ((user)me).getFullName();
	
	String s;
	
	questManager qMgr = questManager.getInstance();
	answerManager aMgr = answerManager.getInstance();
	userManager uMgr = userManager.getInstance();
	townManager tnMgr = townManager.getInstance();
	userinfoManager uiMgr = userinfoManager.getInstance();
	
	userinfo myUI = (userinfo) uiMgr.get(pstuser, myUidS);
	TimeZone myTimeZone = myUI.getTimeZone();
	
	SimpleDateFormat df1 = new SimpleDateFormat ("MM/dd/yyyy (EEE) hh:mm");
	SimpleDateFormat df2 = new SimpleDateFormat ("h:mm a");
	SimpleDateFormat df3 = new SimpleDateFormat ("MM/dd/yyyy (EEE) h:mm a");
	if (!userinfo.isServerTimeZone(myTimeZone)) {
		df1.setTimeZone(myTimeZone);
		df2.setTimeZone(myTimeZone);
		df3.setTimeZone(myTimeZone);
	}
	
	
	// @ECC111708 check RoboMail call
	s = request.getParameter("robo");
	if (s!=null) {
		// construct an XML message based on the value of the object
		Util3.sendRoboMail(me, qMgr, qidS);
	}

	String townStr = "";
	Object [] townIds = me.getAttribute("Towns");
	if (townIds[0]!=null) {
		for (int i=0; i<townIds.length; i++)
			townStr += townIds[i].toString() + ";";
	}
	else {
		townStr = me.getStringAttribute("Company");
		if (townStr == null) townStr = "";
	}

	int iRole = ((Integer)session.getAttribute("role")).intValue();
	
	boolean isAdmin   = ((iRole & user.iROLE_ADMIN) > 0);
	boolean isProgMgr = ((iRole & user.iROLE_PROGMGR) > 0);

	// to check if session is OMF or PRM
	boolean isOMFAPP = false;
	String appS = (String)session.getAttribute("app");
	if (appS.equals("OMF"))
	{
		appS = "MeetWE";
		isOMFAPP = true;
	}
	
	quest qObj = null;
	try {qObj = (quest)qMgr.get(me, qidS);}
	catch (PmpException e)
	{
		response.sendRedirect("../out.jsp?msg=The invite/event/quest is not found in MeetWE.  Please double-check the event.&go=meeting/cal.jsp");
		return;
	}

	String qType;		// event or quest
	String questType;	// Public or Private
	String qShare;
	s = (String)qObj.getAttribute("Type")[0];
	if (s.length() > quest.TYPE_EVENT.length())
	{
		qType = s.substring(0,5);		// event/quest
		//questType = s.substring(5);		// Public/Private
		questType = (s.contains(quest.PRIVATE)) ? quest.PRIVATE : quest.PUBLIC;
		qShare = (s.contains(quest.NO_SHARE)) ? quest.NO_SHARE : "";
	}
	else
	{
		qType = s;
		questType = quest.PUBLIC;
		qShare = quest.NO_SHARE;
	}
	
	String qState = (String)qObj.getAttribute("State")[0];
	
	int creatorUid = 0;
	String creatorName = "";
	s = qObj.getStringAttribute("Creator");
	
	if (!StringUtil.isNullOrEmptyString(s)) {
		creatorUid = Integer.parseInt(s);
		creatorName = "<a href='../ep/ep1.jsp?uid=" + s + "' class='listlink'>"
			+ ((user)uMgr.get(me, creatorUid)).getFullName() + "</a>";
	}
			
	boolean isOwner = (creatorUid == myUid);
	
	// ECC: temp fix company
	if (townStr == "") {
		townStr = qObj.getStringAttribute("TownID");
		me.setAttribute("Company", townStr);
		uMgr.commit(me);
	}
	// ECC: this code can be removed
	
	// check authority
	boolean canRespond = false;
	Object [] oa = null;
	String attendeeStr = "";
	String townIdS = (String)qObj.getAttribute("TownID")[0];
	if (questType.contains(quest.PRIVATE))
	{
		//if (townIdS==null || townIdS.equals("0")) {
			// private and personal
			attendeeStr = StringUtil.toString(qObj.getAttribute("Attendee"), ";");
			/*oa = qObj.getAttribute("Attendee");
			for (int i=0; i<oa.length; i++)
				attendeeStr += oa[i].toString() + ";";*/
		//}
	}
	if (questType.equals(quest.PUBLIC) || isOwner || attendeeStr.contains(myUidS)
			|| (questType.equals(quest.PRIVATE) && townIdS!=null && townStr.indexOf(townIdS)!=-1) )
		canRespond = true;

	// check for authorization to access
	// for circle quest, only circle member is allowed
	String townName = "Personal";
	if (!isAdmin && questType.equals(quest.PRIVATE))
	{
		// check to see if I am an attendee (invited to respond)
		s = (String)qObj.getAttribute("TownID")[0];

		if (!isAdmin && !isProgMgr && !attendeeStr.contains(myUidS)) {
		
			// not an attendee
			if (s==null || s.equals("0"))
			{
				// personal friends: check to see if I am creator's friend
				PstAbstractObject creator = uMgr.get(me, Integer.parseInt((String)qObj.getAttribute("Creator")[0]));
				//Object [] oA = creator.getAttribute("TeamMembers");
				String teamStr = StringUtil.toString(creator.getAttribute("TeamMembers"), ";");
				if (!teamStr.contains(myUidS))
				{
					// not creator's friend
					response.sendRedirect("../out.jsp?msg=You are not authorized to access this event (101).&go=ep/ep_home.jsp");
					return;
				}
			}
			else if (townStr.indexOf(s) == -1)
			{
				response.sendRedirect("../out.jsp?msg=You are not authorized to access this event (102).&go=ep/ep_home.jsp");
				return;
			}
		}

		if (s!=null && !s.equals("0"))
			townName = (String)tnMgr.get(me, Integer.parseInt(s)).getAttribute("Name")[0];
	}

	Object bTextObj = qObj.getAttribute("Description")[0];
	String desc = (bTextObj==null)? null : new String((byte[])bTextObj, "utf-8");
	
	bTextObj = qObj.getAttribute("Content")[0];
	String agendaS = (bTextObj==null)? "" : new String((byte[])bTextObj, "utf-8");

//	 begin setting up questions
	Vector rAgenda = null;
	try {rAgenda = JwTask.getAgendaVector(agendaS);}
	catch (PmpException e)
	{
		String msg = e.toString();
		response.sendRedirect("../out.jsp?msg="+ msg);
	}
// end of setting up questions

	int totalQuestion = JwTask.getTotalQuestion(rAgenda);
	
	// for CR, events might be associated to a project
	String projName = null;
	if ((s = (String)qObj.getAttribute("ProjectID")[0]) != null)
	{
		try {projName = "<a href='../project/cr.jsp?projId=" + s + "'>"
			+ ((project)projectManager.getInstance().get(me, Integer.parseInt(s))).getDisplayName()
			+ "</a>";
		}
		catch (Exception e) {System.out.println("Failed to get project (" + s + ") in q_respond.jsp");}
	}

	s = request.getParameter("forceUpdate");
	if (qState.equals(quest.ST_NEW)
			|| (s!=null && s.equals("true") && (isOwner || isAdmin)) )
	{
		response.sendRedirect("q_new1.jsp?qid=" + qidS);
		return;			// it is new, must be called by owner, go update
	}
	
	// I need to try retrieving my own answer if it exist
	answer aObj = null;
	int [] ids = aMgr.findId(me, "TaskID='" + qidS + "' && Creator='" + me.getObjectId() + "'");
	if (ids.length > 0)
		aObj = (answer)aMgr.get(me, ids[0]);
	
			
	// make sure the answer is not COMMITTED, if it is and we already
	// pass the deadline of the quest, then redirect to q_answer.jsp
	boolean bAlreadySubmit = false;
	Date now = new Date();
	String aidS = "";
	if (aObj != null)
	{
		if (aObj.getAttribute("State")[0].equals(quest.ST_CLOSE))
		{
			bAlreadySubmit = true;
			if (now.after((Date)qObj.getAttribute("ExpireDate")[0]))
			{
				response.sendRedirect("q_answer.jsp?aid="+aObj.getObjectId());
				return;
			}
		}
		aidS = String.valueOf(aObj.getObjectId());
	}
		
	// extract the answer of the selected user
	String [] ans = null;
	String [][] inputArr = null;
	String [] sa;
	if (aObj != null)
	{
		bTextObj = aObj.getAttribute("Content")[0];
		s = (bTextObj==null)? "" : new String((byte[])bTextObj, "utf-8");
		sa = s.split(quest.DELIMITER1);		// get different questions
		//totalQuestion = sa.length;
		ans = new String[totalQuestion];
		inputArr = new String[totalQuestion][quest.MAX_CHOICES+1];	// add 1 for last comment
		JwTask.parseAns(sa, ans, inputArr);
	}
	
	// need to pass totalQuestion to post_q_respond.jsp
	if (totalQuestion == 0)
	{
		// get it from qObj
		s = (String)qObj.getAttribute("Summary")[0];
		if (s != null)
		{
			sa = s.split(quest.DELIMITER1);
			totalQuestion = sa.length;
		}
	}

	boolean isEvent = true;
	String subjLabel, label1, label2, dateStr, loc=null;
	Date dt;
	if (qType.equals(quest.TYPE_EVENT))
	{
		isEvent = true;
		subjLabel = "Event";
		label1 = "Party / Event invitation questions";
		label2 = "Event date";
		dt = (Date)qObj.getAttribute("StartDate")[0];	//Util2.getLocalTime((Date)qObj.getAttribute("StartDate")[0]);
		dateStr = df1.format(dt);
		dt = (Date)qObj.getAttribute("ExpireDate")[0];	//Util2.getLocalTime((Date)qObj.getAttribute("ExpireDate")[0]);
		dateStr += " - " + df2.format(dt);
		loc = (String)qObj.getAttribute("Location")[0];
		if (loc == null) loc = "<font color='777777'>Not specified</font>";
	}
	else
	{
		isEvent = false;
		subjLabel = "Questionnaire";
		label1 = "Questionnaire / Survey / Vote request";
		label2 = "Deadline";
		dt = Util2.getLocalTime((Date)qObj.getAttribute("ExpireDate")[0]);
		dateStr = df3.format(dt);
	}
	
	String subj = (String)qObj.getAttribute("Subject")[0];
	subj = Util.stringToHTMLString(subj);

	////////////////////////////////////////////////////////
%>

<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../forms.jsp" flush="true"/>
<script language="JavaScript" src="../get-date.js"></script>
<script language="JavaScript" src="../date.js"></script>

<script language="JavaScript">
<!--
function fo()
{
	Form = document.newAnswer;
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

function validation(op)
{
	var f = document.newAnswer;
	if (f.Save != null)
		f.Save.disabled = true;
	if (f.Submit != null)
		f.Submit.disabled = true;
	
	if (op == 1)
		f.save.value = "true";		// save for later, don't generate summary yet
	else
		f.save.value= "false";
	f.submit();
}

function show_summary()
{
	location = "q_answer.jsp?qid=<%=qidS%>";
}

function deleteQuest()
{
	// user can delete the survey before it is ACTIVE (when updating a NEW quest)
	if (!confirm("Do you really want to remove this <%=subjLabel%>?"))
		return;
		
	location = "post_q_del.jsp?qid=<%=qidS%>";
	return;
}

function cancelQuest()
{
	if (!confirm("Do you really want to cancel this <%=subjLabel%>?"))
		return;
		
	location = "post_q_del.jsp?qid=<%=qidS%>&cancel=1";
	return;
}

function roboMail()
{
	location = "q_respond.jsp?qid=<%=qidS%>&robo=1";
	return;
}
//-->
</script>

</head>

<title><%=appS%> Respond to Invite / Questionnaire</title>

<body onload="fo();" bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" border="0" cellspacing="0" cellpadding="0">
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
                	<b>View an Event/Questionnaire</b>
					</td>
				  </tr>
<%
	// show summary
	if (!qShare.equals(quest.NO_SHARE) || isOwner || isProgMgr || isAdmin) {
		out.print("<tr><td></td><td><img src='../i/spacer.gif' height='15' width='650'>");
		out.print("<img src='../i/bullet_tri.gif' width='20' height='10' />");
		out.print("<a class='listlinkbold' href='q_answer.jsp?qid=" + qidS + "'>Show responses of this " + subjLabel + "</a>");
		out.print("</td></tr>");
	}

	// support update of evnet
	if (isEvent && (isOwner || isAdmin))
	{
		if (!qState.equals(quest.ST_CANCEL))
		{
			out.print("<tr><td></td><td><img src='../i/spacer.gif' height='15' width='650'>");
			out.print("<img src='../i/bullet_tri.gif' width='20' height='10' />");
			out.print("<a class='listlinkbold' href='q_new1.jsp?qid=" + qidS + "'>Update this " + subjLabel + "</a>");
			out.print("</td></tr>");
		}

		out.print("<tr><td></td><td><img src='../i/spacer.gif' height='15' width='650'>");
		out.print("<img src='../i/bullet_tri.gif' width='20' height='10' />");
		out.print("<a class='listlinkbold' href='javascript:deleteQuest();'>Delete this " + subjLabel + "</a>");
		out.print("</td></tr>");

		if (isEvent && !qState.equals(quest.ST_CANCEL))
		{
			out.print("<tr><td></td><td><img src='../i/spacer.gif' height='15' width='650'>");
			out.print("<img src='../i/bullet_tri.gif' width='20' height='10' />");
			out.print("<a class='listlinkbold' href='javascript:cancelQuest();'>Cancel this " + subjLabel + "</a>");
			out.print("</td></tr>");
		}
		
		// create followup event
		out.print("<tr><td></td><td><img src='../i/spacer.gif' height='15' width='650'>");
		out.print("<img src='../i/bullet_tri.gif' width='20' height='10' />");
		out.print("<a class='listlinkbold' href='q_new1.jsp?ParentId=" + qidS + "'>Create follow-up " + subjLabel + "</a>");
		out.print("</td></tr>");
	}
	
	out.print("<tr><td colspan='2'><img src='../i/spacer.gif' height='20' /></td></tr>");

%>

	            </table>
	          </td>
	        </tr>
			<tr>
          		<td width="100%">
<table width="90%" border="0" cellspacing="0" cellpadding="0">
<tr><td>
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Event" />
				<jsp:param name="subCat" value="" />
				<jsp:param name="role" value="<%=iRole%>" />
			</jsp:include>
					<!-- End of Navigation Menu -->
</td></tr>
</table>					
				</td>
	        </tr>
		</table>
<!-- Content Table -->

<table width="90%" border="0" cellspacing="0" cellpadding="0">
<tr><td colspan="3">&nbsp;</td></tr>

<form method="post" name="newAnswer" id="newAnswer" action="post_q_respond.jsp">
<input type="hidden" name="qid" value="<%=qidS%>"/>
<input type="hidden" name="aid" value="<%=aidS%>"/>
<input type="hidden" name="save" value=""/>
<input type="hidden" name="totalQuestion" value="<%=totalQuestion%>"/>

<!-- Subject -->
	<tr>
		<td width="25"><img src='../i/spacer.gif' width='25' /></td>
		<td width='150' class="plaintext_blue" valign='top'><%=subjLabel%>
<%
		s = Util2.getUserPreference(me, "RoboMail");
		if (s != null)
		{
			out.print("<a href='javascript:roboMail();'><img src='../i/export.jpg' border='0' /></a>");
		}
%>
			:</td>
		<td	class='plaintext_big' width='500'>
			<b><%=subj%></b>
<%
			// @ECC020408 previous and next
			String prev = (String)qObj.getAttribute("ParentID")[0];
			String next = null;
			ids = qMgr.findId(me, "ParentID='" + qidS + "'");
			if (ids.length > 0)
				next = String.valueOf(ids[0]);
			
			out.print("<span class='plaintext'>");
			if (prev != null)
			{
				out.print("<br>");
				out.print("<a href='q_respond.jsp?qid=" + prev + "'>&lt;&lt; Prev " + subjLabel + "</a>");
			}
			if (next != null)
			{
				if (prev != null) out.print("&nbsp; | &nbsp;");
				else out.print("<br>");
				out.print("<a href='q_respond.jsp?qid=" + next + "'>Next " + subjLabel + " &gt;&gt;</a>");
			}
			out.print("</span>");
			
			if (qState.equals(quest.ST_CANCEL))
			{
				out.print("<img src='../i/spacer.gif' width='20' height='1'/>");
				out.print("<span style='color:#ee0000; font-size:14px;'>(<b>Canceled</b>)</span>");
			}
%>
		</td>
	</tr>
	<tr><td colspan='3'><img src='../i/spacer.gif' height='10' /></td></tr> 

<!-- From -->
	<tr>
		<td width="25">&nbsp;</td>
		<td width='150' class="plaintext_blue" valign='center'>From:</td>
		<td	class='plaintext' width='500'>
			<%=creatorName%>
		</td>
	</tr>
	<tr><td colspan='3'><img src='../i/spacer.gif' height='10' /></td></tr> 

<!-- To -->
<%
	// list all present names
		StringBuffer sBuf = new StringBuffer(1024);
		
		Object [] attIdArr = qObj.getAttribute("Attendee");
		int num = 0;
		int len = attIdArr.length;
		user u;
		String uname;
		String emailList = "";
		
	if (isOwner || len < 30) {
		for (int i = 0; i < len; i++) {
			try {
				u = (user) uMgr.get(me,
						Integer.parseInt((String) attIdArr[i]));
			} catch (PmpException e) {
				continue;
			}
			uname = u.getFullName();
			if (uname == null)
				continue;

			emailList += (String) u.getAttribute("Email")[0] + "; ";

			if (num % RADIO_NUM == 0)
				sBuf.append("<tr>");
			sBuf.append("<td width='150' class='plaintext'>");
			sBuf.append("<a href='../ep/ep1.jsp?uid=" + u.getObjectId()
					+ "' class='listlink'>");
			sBuf.append(uname + "</a></td>");
			if (len < RADIO_NUM && i == (len - 1)) {
				for (int j = i; j < RADIO_NUM - 1; j++)
					sBuf.append("<td width='150'>&nbsp;</td>");
			}
			if (num % RADIO_NUM == RADIO_NUM - 1) {
				sBuf.append("</tr>");
			}
			num++;
		}
		
		if (num % RADIO_NUM != 0)
			sBuf.append("</tr>");
		
		if (len <= 0)
			sBuf.append("<tr><td class='plaintext_grey'>None</td></tr>");
	}	// END: if < 30 people
	
	else {
		sBuf.append(myName + " (total " + len + " people)");
	}

	sBuf.append("</table>");

	// now the emaillist is constructed, ready to output the HTML
	out.print("<tr><td width='25'>&nbsp;</td>");
	out.print("<td width='150' class='plaintext_blue' valign='top'>To");
	if (isOwner || isProgMgr || isAdmin) {
		out.print("&nbsp;&nbsp;<a href=\"mailto:" + emailList
				+ "?subject=Re: " + subj
				+ "\"><img src='../i/eml.gif' border='0' /></a>");
	}
	out.print(":</td>");
	out.print("<td	class='plaintext' width='500'>");
	out.print("<table width='600' border='0' cellspacing='0' cellpadding='0'>");
	out.print(sBuf.toString());

%>
		</td>
	</tr>
	<tr><td colspan='3'><img src='../i/spacer.gif' height='10' /></td></tr> 

<!-- Type -->
	<tr>
		<td width="25">&nbsp;</td>
		<td width='150' class="plaintext_blue">Privacy:</td>
		<td	class='plaintext' width='500'>
			<%
				out.print(questType);
				if (!questType.equals(quest.PUBLIC))
					out.print(" / " + townName);
			%>
		</td>
	</tr>
	<tr><td colspan='3'><img src='../i/spacer.gif' height='10' /></td></tr> 

<!-- Project (only for CR) -->
<%	if (projName != null) { %>
	<tr>
		<td width="25">&nbsp;</td>
		<td width='150' class="plaintext_blue">Project:</td>
		<td	class='plaintext' width='500'><%=projName%></td>
	</tr>
	<tr><td colspan='3'><img src='../i/spacer.gif' height='10' /></td></tr> 
<%	} %>

<!-- Date -->
	<tr>
		<td width="25">&nbsp;</td>
		<td width='150' valign='top' class="plaintext_blue"><%=label2%>:</td>
		<td	class='plaintext' width='500'>
			<%=dateStr%>
			<span class='plaintext'>&nbsp;(<%=myUI.getZoneString()%>)</span>
		</td>
	</tr>
	<tr><td colspan='3'><img src='../i/spacer.gif' height='10' /></td></tr> 

<%	if (isEvent) { %>
<!-- Location -->
	<tr>
		<td width="25">&nbsp;</td>
		<td width='150' valign='top' class="plaintext_blue">Location:</td>
		<td	class='plaintext' width='500'>
			<%=loc%>
		</td>
	</tr>
	<tr><td colspan='3'><img src='../i/spacer.gif' height='10' /></td></tr> 
<%	} %>

<!-- Description -->
<%	if (desc != null) { %>
	<tr>
		<td width="25">&nbsp;</td>
		<td width='150' valign='top' class="plaintext_blue">Description:</td>
		<td	class='plaintext' width='500'>
			<%=desc%>
		</td>
	</tr>
	<tr><td colspan='3'><img src='../i/spacer.gif' height='10' /></td></tr> 
<%	}


	// responding and showing summary
	if (totalQuestion>0 && !qState.equals(quest.ST_CANCEL)) {
		if (isAdmin || isProgMgr || isOwner) {
%>
	<tr>
		<td width="25">&nbsp;</td>
		<td colspan='2' align="left">
			<img src='../i/spacer.gif' width='1' height='30' />
			<span class='instruction'>
			Click the button to show the summary of all responses&nbsp;&nbsp;</span>
			<input type="button" value=" Show Summary " class="button_medium" onclick="javascript:show_summary();"/>
		</td>
	</tr>
	<tr><td colspan='3'><img src='../i/spacer.gif' height='10' /></td></tr> 
<%	}%>

	<tr><td></td><td colspan='2' bgcolor="#bb5555" width="100%"><img src="../i/spacer.gif" width="1" height="1" border="0"/></td></tr>


	<tr><td colspan='3'><img src='../i/spacer.gif' height='10' /></td></tr> 

	<tr>
		<td width="25">&nbsp;</td>
		<td colspan=2 class="instruction" style="color:#336699"><br/><b>Please respond to the <%=label1%> and click the Submit button</b></td>
	</tr>

<!-- Questions -->
	<tr>
		<td colspan='3' class="plaintext_big">
			<table width="100%" border="0" cellspacing="0" cellpadding="0">
			<tr>
				<td>
<%
	//char a;
	out.println("<table width='100%' border='0' cellspacing='0' cellpadding='0'><tr>");
	out.print("<td valign='top'><img src='../i/spacer.gif' width='10' /></td>");
	out.println("<td valign='top'><table width='100%' border='0' cellspacing='0' cellpadding='0'>");

	out.println(JwTask.printQuest(rAgenda, null, 0, ans, inputArr));	// no need to initialize summary
	

%>

				</td>
				</tr>
			</table>
			</td>
		</tr>
<!-- End questions -->


<!-- Submit Button -->
<%	if (canRespond)
	{%>
	<tr>
		<td width="25">&nbsp;</td>
		<td colspan='2' class="10ptype" align="left">
			<img src='../i/spacer.gif' width='150' height='40' />
			<input type="button" value="   Cancel  " class="button_medium" onclick="history.back(-1)"/>&nbsp;
<%	if (!bAlreadySubmit)
	{%>
			<input type="submit" name="Save" value="   Save   " class="button_medium" onclick="return validation(1);"/>&nbsp;
<%	}%>
			<input type="submit" name="Submit" value="  Submit  " class="button_medium" onclick="return validation(2);"/>
		</td>
	</tr>
<%	}%>
<%	} // END if totalQuestion > 0 && !Canceled
	else if (isEvent)
	{	// totalQuestion == 0
		out.println("<tr><td></td><td></td>");
		out.print("<td class='instruction'><b>(No RSVP needed for this event)</b></td></tr>");
	}
%>

</form>

<tr><td colspan='3'><img src='../i/spacer.gif' height='20' /></td></tr> 

<tr><td></td><td colspan='2' bgcolor="#bb5555" width="100%"><img src="../i/spacer.gif" width="1" height="1" border="0"/></td></tr>

<tr><td colspan='3'><img src='../i/spacer.gif' height='20' /></td></tr> 

<tr>
	<td width='25'></td>
	<td width='150' class="plaintext_blue" valign="top"><b><%=subjLabel%> Blogs:</b></td>
	<td valign='bottom'>
		<img src='../i/spacer.gif' width='330' height='1'/>
		<img src='../i/bullet_tri.gif' width='20' height='10'/>
		<a class='listlinkbold' href='../blog/addblog.jsp?type=<%out.print(result.TYPE_QUEST_BLOG + "&id=" + qidS);%>'>New Blog Posting</a>
	</td>
</tr>

<%
	// list the meeting blogs
	out.print("<tr><td colspan='3'>");
	out.println(Util2.displayBlog(me, qidS, result.TYPE_QUEST_BLOG));
	out.print("</td></tr>");
%>

		<!-- End of Content Table -->
		<!-- End of Main Tables -->

</table>
</td>
</tr>

<tr><td><img src='../i/spacer.gif' height='10' /></td></tr> 

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
