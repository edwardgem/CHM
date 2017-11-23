<%
//
//	Copyright (c) 2008, EGI Technologies, Co.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: q_answer.jsp
//	Author: ECC
//	Date:	01/09/08
//	Description: Display answer and summary of a quest.
//
//	Modification:
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


<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	String aidS = request.getParameter("aid");
	String qidS = request.getParameter("qid");
	String noSession = "../out.jsp?go=question/q_answer.jsp?aid="+aidS+":qid="+qidS;
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%
	////////////////////////////////////////////////////////
	final int MAX_NUM = 4;

	PstUserAbstractObject me = pstuser;

	if (me instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	int myUid = me.getObjectId();

	int iRole = ((Integer)session.getAttribute("role")).intValue();
	boolean isAdmin   = ((iRole & user.iROLE_ADMIN) > 0);
	boolean isProgMgr = ((iRole & user.iROLE_PROGMGR) > 0);

	// to check if session is OMF or PRM
	boolean isOMFAPP = Prm.isOMF();
	String appS = Prm.getAppTitle();	//(String)session.getAttribute("app");
	/*if (appS.equals("OMF"))
	{
		appS = "MeetWE";
		isOMFAPP = true;
	}*/

	questManager qMgr = questManager.getInstance();
	answerManager aMgr = answerManager.getInstance();
	userManager uMgr = userManager.getInstance();
	townManager tnMgr = townManager.getInstance();

	SimpleDateFormat df1 = new SimpleDateFormat ("MM/dd/yy (EEE) hh:mm a");
	SimpleDateFormat df2 = new SimpleDateFormat ("h:mm a");
	SimpleDateFormat df3 = new SimpleDateFormat ("MM/dd/yyyy (EEE) h:mm a");

	String uidS = request.getParameter("uid");
	String msg = request.getParameter("msg");
	if (msg == null) msg = "";

	String s;
	if (aidS!=null && (aidS.equals("null") || aidS.length()<=0) )
		aidS = null;
	if (qidS!=null && (qidS.equals("null") || qidS.length()<=0) )
		qidS = null;
	if (uidS!=null && (uidS.equals("null") || uidS.length()<=0) )
		uidS = null;

	quest qObj = null;
	answer aObj = null;
	int [] ids;

	if (uidS != null)
	{
		// uid is pass in only for getting the answer for this uid user.  In this case, qidS would not be null
		ids = aMgr.findId(me, "TaskID='" + qidS + "' && Creator='" + uidS + "'");
		aidS = String.valueOf(ids[0]);
	}

	if (aidS != null)
	{
		try {aObj = (answer)aMgr.get(me, aidS);}
		catch (PmpException e)
		{
			response.sendRedirect("../out.jsp?msg=The invite/event/quest is not found in MeetWE.  Please double-check the event.&go=meeting/cal.jsp");
			return;
		}
	}

	boolean bShowSummary = true;
	String showUserName = null;
	String ansDateS = "";
	
	if (aObj != null)
	{
		s = (String)aObj.getAttribute("Creator")[0];
		showUserName = ((user)uMgr.get(me, Integer.parseInt(s))).getFullName();
		bShowSummary = false;
		ansDateS = df1.format((Date)aObj.getAttribute("LastUpdatedDate")[0]);
	}

	if (qidS == null)
		qidS = (String)aObj.getAttribute("TaskID")[0];
	qObj = (quest)qMgr.get(me, qidS);
	
	String qState = (String)qObj.getAttribute("State")[0];

	String qType;		// event or quest
	String questType;	// Public or Private
	s = (String)qObj.getAttribute("Type")[0];
	if (s.length() > quest.TYPE_EVENT.length())
	{
		qType = s.substring(0,5);
		questType = s.substring(5);
	}
	else
	{
		qType = s;
		questType = quest.PUBLIC;
	}

	String townName = "Personal";
	if (!isAdmin && questType.equals(quest.PRIVATE))
	{
		s = (String)qObj.getAttribute("TownID")[0];
		if (s!=null && !s.equals("0"))
		{
			townName = (String)tnMgr.get(me, Integer.parseInt(s)).getAttribute("Name")[0];
		}
	}

	// for CR, events might be associated to a project
	String projName = null;
	if ((s = (String)qObj.getAttribute("ProjectID")[0]) != null)
	{
		try {s = ((project)projectManager.getInstance().get(me, Integer.parseInt(s))).getDisplayName();}
		catch (Exception e) {System.out.println("Failed to get project (" + s + ") in q_respond.jsp");}
	}

	boolean isEvent = true;
	String subjLabel, label1, label2, label3, label4, dateStr, loc=null;
	Date dt;
	if (qType.equals(quest.TYPE_EVENT))
	{
		isEvent = true;
		subjLabel = "Event / Party";
		label1 = "Response of the Party / Event invitation questions";
		label2 = "invitation";
		label3 = "RSVP";
		label4 = "Event date";
		dt = Util2.getLocalTime((Date)qObj.getAttribute("StartDate")[0]);
		dateStr = df1.format(dt);
		dt = Util2.getLocalTime((Date)qObj.getAttribute("ExpireDate")[0]);
		dateStr += " - " + df2.format(dt);

		loc = (String)qObj.getAttribute("Location")[0];
		if (loc == null) loc = "<font color='777777'>Not specified</font>";
	}
	else
	{
		isEvent = false;
		subjLabel = "Questionnaire";
		label1 = "Response of the Questionnaire / Survey / Vote request";
		label2 = "questionnaire";
		label3 = "Respond";
		label4 = "Deadline";
		dt = Util2.getLocalTime((Date)qObj.getAttribute("ExpireDate")[0]);
		dateStr = df3.format(dt);
	}
	if (showUserName != null)
		label1 += " by <b>" + showUserName + "</b> on " + ansDateS;
	else
		label1 = "Summary " + label1;

	String subj = (String)qObj.getAttribute("Subject")[0];

	// creator
	s = (String)qObj.getAttribute("Creator")[0];
	int creatorUid = Integer.parseInt(s);
	String creatorName = "<a href='../ep/ep1.jsp?uid=" + s + "' class='listlink'>"
				+ ((user)uMgr.get(me, creatorUid)).getFullName() + "</a>";

	boolean isOwner = (creatorUid == myUid);
	boolean bShareResponses = isOwner || isAdmin || isProgMgr;

	Object bTextObj = qObj.getAttribute("Description")[0];
	String desc = (bTextObj==null)? null : new String((byte[])bTextObj, "utf-8");

	bTextObj = qObj.getAttribute("Content")[0];
	String agendaS = (bTextObj==null)? "" : new String((byte[])bTextObj, "utf-8");

//	 begin setting up questions
	Vector rAgenda = null;
	try {rAgenda = JwTask.getAgendaVector(agendaS);}
	catch (PmpException e)
	{
		s = e.toString();
		response.sendRedirect("../out.jsp?msg="+ s);
	}
//	 end of setting up questions

	// extract the answer of the selected user
	Date now = new Date();
	boolean bIresponded = true;		// I have responded (or not)
	boolean bCanChangeAns = false;	// if I have submitted an ans but still before quest deadline, then i can change
	String [] ans = null;
	String [][] inputArr = null;
	String [] sa;
	int totalQuestion = 0;
	if (aObj != null)
	{
		bTextObj = aObj.getAttribute("Content")[0];
		s = (bTextObj==null)? "" : new String((byte[])bTextObj, "utf-8");
		sa = s.split(quest.DELIMITER1);		// get different questions
		totalQuestion = sa.length;
		ans = new String[totalQuestion];
		inputArr = new String[totalQuestion][quest.MAX_CHOICES+1];	// add 1 for last comment
		JwTask.parseAns(sa, ans, inputArr);

		if (now.before((Date)qObj.getAttribute("ExpireDate")[0]))
			bCanChangeAns = true;
	}

	// the following are for showing a quick summary info
	ids = aMgr.findId(me, "TaskID='" + qidS + "' && State='" + quest.ST_CLOSE + "'");
	int [] allAttendee = Util2.toIntArray(qObj.getAttribute("Attendee"));
	int [] responder = new int[ids.length];
	for (int i=0; i<ids.length; i++)
		responder[i] = Integer.parseInt((String)aMgr.get(me, ids[i]).getAttribute("Creator")[0]);
	int [] notRespond = Util2.outerJoin(allAttendee, responder);


	////////////////////////////////////////////////////////////////////////////////////////////////////
	// prepare the summary information
	// use a two 3D arrays to keep [quest#]{choice#][user#] for answer and for input(store in String)
	// *** ECC: if we are dealing with thousands of users responding to quest, this processing could be costly.
	// In that situation, we should rely on the Summary attribute in quest to show a quick summary info,
	// and have another link to show the details which include users text input.

	// ansUidArr stores the uids corresponding to who pick what choices in the various questions
	// inputAllArr stores the numeric/text inputs from all responders on each choices in various questions
	// note that the indices [][][] of both arrays correspond to the same user
	int [][][] ansUidArr = null;
	String [][][] inputAllArr = null;
	int numOfUsers = 0;
	int num, id;

	if (bShowSummary)
	{
		// get all the answer objects of this quest.  ids[] is set up to contain the answer objects id
		PstAbstractObject [] ansObjArr = aMgr.get(me, ids);
		Util.sortIndirectUserName(me, uMgr, ansObjArr, "Creator");	// ansObjArr is sorted by Creator FullName
		numOfUsers = ids.length;

		// need to get totalQuestion
		if (totalQuestion <= 0)
		{
			s = (String)qObj.getAttribute("Summary")[0];
			if (s != null) {
				sa = s.split(quest.DELIMITER1);
				totalQuestion = sa.length;
			}
		}

		ansUidArr = new int[totalQuestion][quest.MAX_CHOICES+1][numOfUsers];	// this can be large if thousands of votes
		inputAllArr = new String[totalQuestion][quest.MAX_CHOICES+1][numOfUsers];

		// init
		for (int i=0; i<totalQuestion; i++)
			for (int j=0; j<quest.MAX_CHOICES; j++)
				for (int k=0; k<numOfUsers; k++)
					ansUidArr[i][j][k] = 0;

		// need to find out for each ans to each question whether there is input field
		boolean [][] hasInputFld = new boolean[totalQuestion][quest.MAX_CHOICES];
		JwTask.locateInputField(rAgenda, hasInputFld);

		// now process the answer obj arr
		PstAbstractObject o;
		String [] sa1;
		String [] saAns;
		for (int i=0; i<ansObjArr.length; i++)
		{
			// for each user's answer obj: i am the ith user
			o = ansObjArr[i];
			id = Integer.parseInt((String)o.getAttribute("Creator")[0]);
			bTextObj = o.getAttribute("Content")[0];
			s = (bTextObj==null)? "" : new String((byte[])bTextObj, "utf-8");

			sa = s.split(quest.DELIMITER1);		// get different questions @@
			
			if (totalQuestion != sa.length)
				System.out.println("!!! error in q_answer.jsp: mismatch totalQuestion (" + totalQuestion + ") and answer length (" + sa.length + ")");

			for (int j=0; j<totalQuestion; j++)
			{
				// for each question, there might be numeric/text input
				// j is question # (starts from 0)
				if (sa.length <= j) break;

				// to support checkbox, there can be more than one answer
				// 3::this is good$@$5::another check mark$@$6::even another check mark
				// for checkbox, we do not support entering a paragraph
				saAns = sa[j].split("\\$@\\$");					// $@$
						
				for (int k=0; k<saAns.length; k++) {
					sa1 = saAns[k].split(quest.DELIMITER);		// :: one answer of a question  (3::This is good)

					try {num = Integer.parseInt(sa1[0]);}				// e.g. 3 (i.e. chose the 3rd choice in this question)
					catch (Exception e) {
						// just comment
						inputAllArr[j][quest.MAX_CHOICES][i] = sa1[0];
						continue;
					}
					if (num>0 && num<=quest.MAX_CHOICES)								// for option or paragraph question, user can skip
					{
						//System.out.println("sa1.len="+sa1.length);
						ansUidArr[j][num-1][i] = id;
						if (sa1.length > 1)
						{
							if (hasInputFld[j][num-1])
								inputAllArr[j][num-1][i] = sa1[1];	// the numeric/string/paragraph input; if not, the last parag input
							else
							{
								// this answer shouldn't have input, so the input must be for last comment
								ansUidArr[j][quest.MAX_CHOICES][i] = id;		// user has entered text input for last comment
								inputAllArr[j][quest.MAX_CHOICES][i] = sa1[1];	// must be input for last comment
							}
							//System.out.println("1. inputAllArr["+j+"][...]["+i+"]="+sa1[1]);
						}
						if (sa1.length > 2)
						{
							// the case e.g. 4::parag input on MC::last comment
							inputAllArr[j][quest.MAX_CHOICES][i] = sa1[2];// put last comment here
							ansUidArr[j][quest.MAX_CHOICES][i] = id;
							//System.out.println("2. inputAllArr["+j+"][max]["+i+"]="+sa1[2]);
						}
					}
				}	// END k: for each answer of a question
			}	// END j: for each question
		}	// END: for each answer object

	}	// END: bShowSummary

	////////////////////////////////////////////////////////
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html lang="en">

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

function show_summary()
{
	location = "q_answer.jsp?qid=<%=qidS%>";
}

function respond()
{
	location = "q_respond.jsp?qid=<%=qidS%>";
}

function deleteQuest()
{
	// user can delete the survey before it is ACTIVE (when updating a NEW quest)
	if (!confirm("Do you really want to remove this <%=label2%>?"))
		return;

	location = "post_q_del.jsp?qid=<%=qidS%>";
	return;
}

function showDetailAns(ques, choice)
{
	var e = document.getElementById("detailAns_" + ques + "-" + choice);
	if (e.style.display == "block")
		e.style.display = "none";
	else
		e.style.display = "block";
}
//-->
</script>


</head>

<style type="text/css">
.plaintext { font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 13px; color: #333333; line-height: 16px}
.plaintext_big {  font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 14px; color: #333333; line-height: 18px}
.instruction {  font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 14px; color: #333333; line-height: 18px}
.listlink { font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 13px; color: #3366aa; line-height: 16px; text-decoration: underline}
</style>


<title><%=appS%> Respond to Invite / Questionnaire</title>
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
                	<td height="30" align="left" valign="bottom" class="head">
                		<b>View Invite/Questionnaire Result</b>
					</td>
				  </tr>
	
<%
	// create followup quest
	if (!isEvent)
	{
		out.print("<tr><td></td><td><img src='../i/spacer.gif' height='15' width='650'>");
		out.print("<img src='../i/bullet_tri.gif' width='20' height='10' />");
		out.print("<a class='listlinkbold' href='q_new1.jsp?ParentId=" + qidS + "'>Create follow-up questionnaire</a>");
		out.print("</td></tr>");
	}

	// support saving to template library
	if (isOwner || isAdmin)
	{
		if (isOwner) {
			out.print("<tr><td></td><td><img src='../i/spacer.gif' height='15' width='650'>");
			out.print("<img src='../i/bullet_tri.gif' width='20' height='10' />");
			out.print("<a class='listlinkbold' href='../question/q_new3.jsp?Qid=" + qidS + "&send=1'>Send reminder to invitees</a>");
			out.print("</td></tr>");
		}
		
		if (!qState.equals(quest.ST_CANCEL))
		{
			out.print("<tr><td></td><td><img src='../i/spacer.gif' height='15' width='650'>");
			out.print("<img src='../i/bullet_tri.gif' width='20' height='10' />");
			out.print("<a class='listlinkbold' href='q_new1.jsp?qid=" + qidS + "'>Update this " + subjLabel + "</a>");
			out.print("</td></tr>");
		}

		out.print("<tr><td></td><td><img src='../i/spacer.gif' height='15' width='650'>");
		out.print("<img src='../i/bullet_tri.gif' width='20' height='10' />");
		out.print("<a class='listlinkbold' href='javascript:deleteQuest();'>Delete this " + label2 + "</a>");
		out.print("</td></tr>");

		out.print("<tr><td></td><td><img src='../i/spacer.gif' height='15' width='650'>");
		out.print("<img src='../i/bullet_tri.gif' width='20' height='10' />");
		out.print("<a class='listlinkbold' href='../plan/new_templ1.jsp?qid=" + qidS + "'>Save template to library</a>");
		out.print("</td></tr>");
	}
%>
	<tr><td colspan='2'><img src='../i/spacer.gif' height='30'/></td></tr>

	            </table>
	          </td>
	        </tr>
	</table>
	</td>
	</tr>

					<!-- Navigation Menu -->
			<tr>
          		<td width="100%">
<table width="90%" border="0" cellspacing="0" cellpadding="0">
<tr><td>
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Event" />
				<jsp:param name="subCat" value="" />
				<jsp:param name="role" value="<%=iRole%>" />
				<jsp:param name="roleType" value="1" />
			</jsp:include>
					<!-- End of Navigation Menu -->
</td></tr>
</table>					
				</td>
	        </tr>

<!-- Content Table -->

<tr><td>
<table width="90%" border="0" cellspacing="0" cellpadding="0">

<tr><td></td><td colspan='2' class='plaintext' style='padding-top:5px; color:#00bb00'><%=msg%>&nbsp;</td></tr>


<form method="post" name="newAnswer" id="newAnswer" action="post_q_respond.jsp">
<input type="hidden" name="qid" value="<%=qidS%>">

<!-- Subject -->
	<tr>
		<td width="25"><img src='../i/spacer.gif' width='25' /></td>
		<td width='150' class="plaintext_blue" valign='top'><%=subjLabel%>:</td>
		<td	class='plaintext_big' width='500'>
			<b><%=Util.stringToHTMLString(subj)%></b>
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
				out.print("<a href='q_answer.jsp?qid=" + prev + "'>&lt;&lt; Prev " + subjLabel + "</a>");
			}
			if (next != null)
			{
				if (prev != null) out.print("&nbsp; | &nbsp;");
				else out.print("<br>");
				out.print("<a href='q_answer.jsp?qid=" + next + "'>Next " + subjLabel + " &gt;&gt;</a>");
			}
			out.print("</span>");
%>
		</td>
	</tr>
	<tr><td colspan='3'><img src='../i/spacer.gif' height='10' /></td></tr>

<!-- Type -->
	<tr>
		<td width="25">&nbsp;</td>
		<td width='150' class="plaintext_blue">Privacy:</td>
		<td	class='plaintext' width='500'>
			<%=questType%>&nbsp;<%=townName%>
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

<!-- Sent by -->
	<tr>
		<td width="25">&nbsp;</td>
		<td width='150' class="plaintext_blue">Sent by:</td>
		<td	class='plaintext' width='500'>
			<%=creatorName%>
		</td>
	</tr>
	<tr><td colspan='3'><img src='../i/spacer.gif' height='10' /></td></tr>

<!-- Date -->
	<tr>
		<td width="25">&nbsp;</td>
		<td width='150' valign='top' class="plaintext_blue"><%=label4%>:</td>
		<td	class='plaintext' width='500'>
			<%=dateStr%>
		</td>
	</tr>
	<tr><td colspan='3'><img src='../i/spacer.gif' height='10' /></td></tr>

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
<%	} %>

	<tr><td colspan='3'><img src='../i/spacer.gif' height='10' /></td></tr>

<!-- Show a quick summary -->

	<tr>
		<td width="25">&nbsp;</td>
		<td colspan=2 class="instruction"><blockquote>
<%
		String name;
		PstAbstractObject [] oA;

		out.print("A total of <b>" + allAttendee.length + "</b> people receive this ");
		if (isEvent) out.print("invitation");
		else out.print("questionnaire");
		out.print("<br><b>");
		if (responder.length == 1)
			out.print("1</b> person");
		else
			out.print(responder.length + "</b> people");
		out.print(" responded to the request. ");
		
		
		if (bShareResponses) {
			if (responder.length>0)
			{
				out.print("Click on the name to see a participant's response:<blockquote>");
				out.print("<table border='0' cellspacing='0' cellpadding='0'>");
				oA = uMgr.get(me, responder);
				Util.sortUserArray(oA, true);
				for (num=0; num<oA.length; num++)
				{
					id = oA[num].getObjectId();
					name = ((user)oA[num]).getFullName();
					if (num%MAX_NUM == 0) out.print("<tr>");
					if (uidS!=null && Integer.parseInt(uidS)==id)
						out.print("<td width='150' class='plaintext'>" + name + "</td>");
					else
						out.print("<td width='150'><a href='q_answer.jsp?qid=" + qidS + "&uid=" + id + "' class='listlink'>" + name + "</a></td>");
					if (num%MAX_NUM == MAX_NUM-1) out.print("</tr>");
				}
				if (num%MAX_NUM != 0) out.print("</tr>");
				out.print("</table></blockquote>");
			}
			if (notRespond.length > 0)
			{
				out.print("<b>");
				if (notRespond.length == 1)
					out.print("1</b> person has");
				else
					out.print(notRespond.length + "</b> people have");
				out.print(" not yet responded:<blockquote>");
				out.print("<table border='0' cellspacing='0' cellpadding='0'>");
				oA = uMgr.get(me, notRespond);
				Util.sortUserArray(oA, true);
				for (num=0; num<oA.length; num++)
				{
					id = oA[num].getObjectId();
					if (id == myUid)
						bIresponded = false;
					name = ((user)oA[num]).getFullName();
					if (num%MAX_NUM == 0) out.print("<tr>");
					if (id == myUid)
						out.print("<td width='150'><a href='q_respond.jsp?qid=" + qidS + "' class='listlink'>");
					else
						out.print("<td width='150'><a href='../ep/ep1.jsp?uid=" + id + "' class='listlink'>");
					out.print(name + "</a></td>");
					if (num%MAX_NUM == MAX_NUM-1) out.print("</tr>");
				}
				if (num%MAX_NUM != 0) out.print("</tr>");
				out.print("</table></blockquote>");
			}
	
			out.println("</blockquote></td>");
			out.print("</tr>");
	
			out.print("<tr><td></td>");
		}	// END if: bShareResponses
		
		
		if (!bIresponded)
		{
			// provide a button for me to respond now
			out.print("<td colspan='2' class='instruction'>Click the button to respond to the " + label2 + " &nbsp;");
			out.print("<input type='Button' value='  " + label3 + "  ' class='button_medium' onclick='javascript:respond();'>");
			if (!bShowSummary && bShareResponses)
			{
				out.print("&nbsp;&nbsp;To view a summary click ");
				out.print("<input type='Button' value=' Show Summary ' class='button_medium' onclick='javascript:show_summary();'>");
			}
		}
		else
		{
			if (bCanChangeAns)
			{
				// allow the user to update his answer
				out.print("<td colspan='2' class='instruction'>Click the button to update your response to the " + label2 + " &nbsp;");
				out.print("<input type='Button' value='  Update  ' class='button_medium' onclick='javascript:respond();'>");
				out.print("</td></tr><tr><td></td>");
			}
			if (!bShowSummary && bShareResponses)
			{
				out.print("<td colspan='2' class='instruction'>Click the button to show the summary of all responses&nbsp;&nbsp;");
				out.print("<input type='Button' value=' Show Summary ' class='button_medium' onclick='javascript:show_summary();'>");
			}
			else
			{
				out.print("<td>");
			}
		}
		out.print("</td></tr>");
		out.print("<tr><td colspan='3'><img src='../i/spacer.gif' height='10' /></td></tr>");
%>

	<tr><td></td><td colspan='2' bgcolor="#bb5555" width="100%"><img src="../i/spacer.gif" width="1" height="1" border="0"></td></tr>

<!-- Show response -->
	<tr>
		<td width="25">&nbsp;</td>
		<td colspan=2 class="instruction" style="color:#336699"><br><%=label1%></td>
	</tr>

	<tr>
		<td colspan='3' class="plaintext_big">
			<table width="100%" border="0" cellspacing="0" cellpadding="0">
			<tr>
				<td>
<%
	//char a;
	out.println("<table width='100%' border='0' cellspacing='0' cellpadding='0'><tr>");
	out.print("<td valign='top'><img src='../i/spacer.gif' width='15' /></td>");
	out.println("<td valign='top'><table width='100%' border='0' cellspacing='0' cellpadding='0'>");

	if (bShowSummary)
		out.println(JwTask.printAnswer(me, rAgenda, null, null, qidS, numOfUsers, ansUidArr, inputAllArr));
	else
		out.println(JwTask.printAnswer(me, rAgenda, ans, inputArr, null, 0, null, null));

%>
				</td>
				</tr>
			</table>
			</td>
		</tr>
<!-- End questions -->


<!-- Submit Button -->
	<tr>
		<td width="25">&nbsp;</td>
		<td colspan=2 class="10ptype" align="left">
			<img src='../i/spacer.gif' width='1' height='40' />
			<span class='instruction'>
<%	if (bShareResponses) {
		if (bShowSummary) { %>
			Click on any name above to show the response of that particular person.</span>
<%		} else { %>
			Click the button to show the summary of all responses&nbsp;&nbsp;</span>
			<input type="Button" value=" Show Summary " class="button_medium" onclick="javascript:show_summary();">
<%		} 
	}
%>
		</td>
	</tr>

</form>

<tr><td colspan='3'><img src='../i/spacer.gif' height='20' /></td></tr>

<tr><td></td><td colspan='2' bgcolor="#bb5555" width="100%"><img src="../i/spacer.gif" width="1" height="1" border="0"></td></tr>

<tr><td colspan='3'><img src='../i/spacer.gif' height='20' /></td></tr>

<tr>
	<td width='25'></td>
	<td width='150' class="plaintext_blue" valign="top"><b><%=subjLabel%> Blogs:</b></td>
	<td valign='bottom'>
		<img src='../i/spacer.gif' width='330' height='1'>
		<img src='../i/bullet_tri.gif' width='20' height='10'>
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
