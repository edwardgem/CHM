<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>

<%
////////////////////////////////////////////////////
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	addalert.jsp
//	Author:	ECC
//	Date:	03/25/04
//	Description:
//		Send alert messages.
//	Modification:
//		@082504ECC	Add taskId for PRM to capture task context.
//		@040505ECC	Support the option of only emailing a memo to people.
//		@041405ECC	Allow specifying a list of recipients when calling addalert.jsp.
//					This is to support ep1.jsp sending memo to direct reports
//		@042805ECC	Support forward meeting record.
//		@AGQ030106	Support of keeping AlertPersonnel list after changing Teams
// 		@AGQ030106a	Display of DL
//		@AGQ031006	Removed automatic generation of user names
//		@041906SSI	Added sort function to Project names.
//
////////////////////////////////////////////////////////////////////
%>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.*" %>
<%@ page import = "util.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	boolean isOMFAPP = false;
	boolean isCRAPP = false;
	String appS = (String)session.getAttribute("app");
	if (appS.equals("CR"))
		isCRAPP = true;
	else if (appS.equals("OMF"))
	{
		isOMFAPP = true;
		appS = "MeetWE";
	}

	boolean isAdmin = false;
	Integer io = (Integer)session.getAttribute("role");
	int iRole = 0;
	if (io != null) iRole = io.intValue();
	if ( (iRole > 0) && ((iRole & user.iROLE_ADMIN) > 0) )
			isAdmin = true;

	user curUser = (user)pstuser;
	int myUid = curUser.getObjectId();
	String myFullName = curUser.getFullName();
	
	userManager uMgr = userManager.getInstance();
	userinfoManager uiMgr = userinfoManager.getInstance();
	townManager tnMgr = townManager.getInstance();
	projectManager pjMgr = projectManager.getInstance();
	
	userinfo myUI = (userinfo) uiMgr.get(pstuser, String.valueOf(myUid));
	TimeZone myTimeZone = myUI.getTimeZone();
	int myTimeZoneOffset = myUI.getTimeZoneIdx();
	
	SimpleDateFormat df1  = new SimpleDateFormat ("MM/dd/yy '('EEE')' hh:mm a");
	SimpleDateFormat df2 = new SimpleDateFormat ("MM/dd/yy");
	if (!userinfo.isServerTimeZone(myTimeZone)) {
		df1.setTimeZone(myTimeZone);
		df2.setTimeZone(myTimeZone);
	}

	String host = Util.getPropKey("pst", "PRM_HOST");
	String tidS = request.getParameter("townId");			// always supply this for subject [townname]
	String pidS = request.getParameter("projId");			// MUST provide this to allow sending to team
	if (pidS!=null && pidS.equals("null")) pidS = null;
	String backPage = request.getParameter("backPage");
	String idS = request.getParameter("id");
	String tkidS = request.getParameter("taskId");			// if sending from task context
	String type = request.getParameter("type");				// forwarding memo, blog, meeting (both invite and record)
	String list = request.getParameter("list");				// recipient id separated by ","

	String [] alertPerArr = request.getParameterValues("AlertPersonnel");
	if (alertPerArr != null && alertPerArr.length > 0) {
		StringBuffer sb = new StringBuffer();
		for (int i = 0; i < alertPerArr.length; i++) {
			sb.append(alertPerArr[i] + ",");
		}
		list = sb.toString();
	}
	String prevMessage = request.getParameter("MsgText");
	String prevSubject = request.getParameter("Subject");

	StringBuffer guestEmails = new StringBuffer();

	int projTeamId = -2;
	if (pidS!=null && pidS.length()>0)
		projTeamId = Integer.parseInt(pidS);

	// @041405ECC
	String [] idSArr = null;
	ArrayList toIdArr = new ArrayList();
	if (list!=null && list.length()>0)
	{
		idSArr = list.split(",");			// caller must separate the memid with ","

		for (int i=0; i<idSArr.length; i++) {
			toIdArr.add(idSArr[i]);
		}
	}

	String lname, repname = null;
	String msg = "";
	user aUser = null;
	String subject = "";
	boolean emailOnly = false;
	boolean isMeeting = false;			// forward meeting record
	if (type!=null && type.length()>0)
	{
		// user want to forward thru email (like outlook) a memo or a blog to others
		emailOnly = true;

		PstManager mgr = null;
		PstAbstractObject obj;

		if (type.equalsIgnoreCase("memo"))
		{
			mgr = memoManager.getInstance();
		}
		else if (type.equalsIgnoreCase("meeting"))
		{
			mgr = meetingManager.getInstance();
			isMeeting = true;
		}
		else
		{
			mgr = resultManager.getInstance();
		}
		obj = mgr.get(pstuser, idS);			// memo, result, or meeting

		String createDate = null;
		String creatorIdS = null;
		Object bTextObj;
		String bText = null;
		String s;
		int [] ids;

		if (isMeeting)
		{
			StringBuffer sbuf = new StringBuffer(4096);
			long lo = ((Date)obj.getAttribute("StartDate")[0]).getTime();	// + userinfo.getServerUTCdiff();
			createDate = df1.format(new Date(lo)) + " PST";
			subject = (String)obj.getAttribute("Subject")[0];
			String status = (String)obj.getAttribute("Status")[0];

			if (!status.equals(meeting.NEW))
			{
				// forward meeting record
				sbuf.append("<p>Please click the following link to access the complete meeting record of");
				sbuf.append("<blockquote><a href='" +host+ "/meeting/mtg_view.jsp?mid=" + idS + "'><b>");
				sbuf.append(subject + "</b></a> on " + createDate + "</blockquote><br>");
				subject = "Meeting Minutes: " + subject + " - " + createDate;

				// list meeting minute
				sbuf.append("<b>Meeting Minutes:</b>");
				sbuf.append("<br><br>");
				PstAbstractObject mObj = mgr.get(pstuser, idS);
				bTextObj = mObj.getAttribute("Note")[0];
				bText = (bTextObj==null)?"none":new String((byte[])bTextObj, "utf-8");
				sbuf.append(bText);
				sbuf.append("<br><br><br>");

				// append action items to meeting notes
				actionManager aMgr = actionManager.getInstance();
				ids = aMgr.findId(pstuser, "(MeetingID='" + idS + "') && (Type='" + action.TYPE_ACTION + "')");
				Arrays.sort(ids);
				PstAbstractObject [] aiObjList = aMgr.get(pstuser, ids);
				user uObj;

				// list action items
				sbuf.append("<b>Action Items:</b>");
				if (aiObjList.length > 0)
				{
					sbuf.append("<p><table border='0' cellspacing='0' cellpadding='2'>");
					for (int i=0; i<aiObjList.length; i++)
					{
						action act = (action)aiObjList[i];
						Object []respA = act.getAttribute("Responsible");
						String ownerIdS	= (String)act.getAttribute("Owner")[0];		// action item coordinator
						sbuf.append("<tr><td width='20' valign='top' class='ac_item'>" + (i+1) + ".</td>");
						sbuf.append("<td width='430' valign='top' class='ac_item'>"
								+ (String)act.getAttribute("Subject")[0]
								+ " (by " + df2.format((Date)act.getAttribute("ExpireDate")[0]) + ")"
								+ "</td>");
						sbuf.append("<td width='20'>&nbsp;</td>");
						sbuf.append("<td width='150' valign='top' class='ac_item'>");
						boolean found = false;
						for (int j=0; j<respA.length; j++)
						{
							s = (String)respA[j];
							if (s == null) break;
							try{uObj = (user)uMgr.get(pstuser,Integer.parseInt(s));}
							catch (PmpException e) {continue;}
							sbuf.append((String)uObj.getAttribute("FirstName")[0]);
								//+ " " + ((String)uObj.getAttribute("LastName")[0]).charAt(0) + ".");
							if (s.equals(ownerIdS))
							{
								found = true;
								sbuf.append("*");
							}
							if (j < respA.length-1 || !found) sbuf.append(", ");
						}
						if (!found)
						{
							// include coordinator/owner into the list of responsible
							uObj = (user)uMgr.get(pstuser,Integer.parseInt(ownerIdS));
							sbuf.append((String)uObj.getAttribute("FirstName")[0]);
								//+ " " + ((String)uObj.getAttribute("LastName")[0]).charAt(0) + ".*");
						}
						sbuf.append("</td></tr>");
					}
					sbuf.append("</table>");
				}
				else
					sbuf.append("<font color='#666666'>&nbsp;&nbsp;none</font>");
			}
			else
			{
				// send meeting invite
				String agendaText = ((meeting)obj).getAgendaString().replaceAll("@@", ":");	// the agenda may have this encoded
				if (agendaText.length() <= 0)
					agendaText = "<div class='plaintext_grey'>&nbsp;no agenda specified</div>";

				bTextObj = obj.getAttribute("Description")[0];
				String descStr = (bTextObj==null)?null : new String((byte[])bTextObj);

				String NODE = Util.getPropKey("pst", "PRM_HOST");
				String userLink = NODE + "/meeting/mtg_view.jsp?mid=" + obj.getObjectId(); // @SWS091906
				//String guestLink = NODE + "/login_omf.jsp?mid=" + obj.getObjectId()+ "&email=" ;
				sbuf.append(myFullName + " invites you to the meeting on " + createDate);
				sbuf.append("<br /><br />To join the meeting, click on the link below at the specified time.");
				sbuf.append("<blockquote><b><a href='" + userLink);
				sbuf.append("'>" + subject + "</a></b><br>");
				sbuf.append(userLink + "\n</blockquote>");
				if (descStr != null)
					sbuf.append("<b>Description:</b><blockquote>" + descStr + "</blockquote>");
				sbuf.append("<b>Agenda:</b><blockquote>" + agendaText + "</blockquote>");

				// blog
				String blogText;
				ids = resultManager.getInstance().findId(pstuser, "Type='" + result.TYPE_MTG_BLOG + "' && TaskID='" + idS + "'");
				if (ids.length > 0)
					blogText = "A total of " + ids.length + " blog" + ((ids.length>1)?"s":"") + " posted. ";
				else
					blogText = "No blog posted on this meeting. ";
				blogText += "<a href='" + NODE + "/meeting/mtg_view.jsp?mid=" + idS + "#blog'>Click to access and post blog to this meeting.</a>";
				sbuf.append("</p><b>Blogs:</b><blockquote>" + blogText + "</blockquote>");

				subject = "[" + appS + " Invite] "+ subject + " - " + createDate;
			}
			msg = sbuf.toString();

			boolean isAuth = false;
			s = String.valueOf(myUid);
			if (s.equals(obj.getAttribute("Owner")[0]) || s.equals(obj.getAttribute("Owner")[0]))
				isAuth = true;

			if (isAdmin || isAuth)	// owner or recorder
			{
				Object [] dbGuestEmails = obj.getAttribute("GuestEmails");
				if (dbGuestEmails[0] != null) {
					for (int i=0; i<dbGuestEmails.length; i++) {
						guestEmails.append(dbGuestEmails[i] + ", ");
					}
				}
			}
		}
		else
		{
			// memo or blog
			createDate = df1.format((Date)obj.getAttribute("CreatedDate")[0]);
			creatorIdS = (String)obj.getAttribute("Creator")[0];

			if (creatorIdS==null || creatorIdS.equals("0"))
			{
				pidS = (String)obj.getAttribute("ProjectID")[0];	// reply to system alert
				repname = "System";
			}
			else
			{
				aUser = (user)uMgr.get(pstuser, Integer.parseInt(creatorIdS));
				repname =  aUser.getFullName();
			}

			bTextObj = obj.getAttribute("Comment")[0];
			bText = (bTextObj==null)?"":new String((byte[])bTextObj, "utf-8");
			msg = "<p><br>____________</p>";
			msg += "<p>On " + createDate + ", " + repname + " wrote:</p>";
			msg += bText;

			subject = "Re: ";
			s = (String)obj.getAttribute("Type")[0];
			if (s.equals(result.TYPE_BUG_BLOG))
			{
				// the only way I can get the bug id is from backpage
				String [] sa = backPage.split(":");
				int i = 0;
				while (i<sa.length && !sa[i].startsWith("bugId")) i++;
				if (i < sa.length)
				{
					String str = "";

					// get the bug's synopsis
					s = sa[i];
					sa = s.split("=");
					bug b = (bug)bugManager.getInstance().get(pstuser, sa[1]);
					str = (String)b.getAttribute("Synopsis")[0];
					subject += str;

					// get project name
					if (pidS != null) {
						//subject += " (" + PstManager.getNameById(pstuser, Integer.parseInt(pidS)) + ")";
						project pj = (project) pjMgr.get(pstuser, Integer.parseInt(pidS));
						subject += " (" + pj.getDisplayName() + ")";
					}

					// get bug link displayed on top of the message body
					msg = "<br><br><b>PR " + sa[i] + "</b>: <a href='" + host + "/bug/bug_update.jsp?bugId=" + sa[1] +"'>"
							+ str + "</a>"
							+ msg;
				}
			}
		}
	}

//	 @AGQ030106
	if (prevMessage != null && prevMessage.length() > 0)
		msg = prevMessage;

	if (prevSubject != null && prevSubject.length() > 0)
		subject = prevSubject;

	// the whole company or project team
/*	String toStr = null, toVal = null;
	if (pidS!=null && pidS.length()>0)
	{
		toStr = "The Whole Project Team";
		toVal = "-2";	//pidS;
	}
	else
	{
		toStr = "The Whole Company";
		toVal = "-1";
	}
*/
%>


    <head>
        <meta http-equiv="content-type" content="text/html; charset=utf-8"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>

<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../forms.jsp" flush="true"/>

<script language="JavaScript">
<!--
function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

function validation()
{
	if (document.sendAlert.Subject.value == "")
	{
		fixElement(document.sendAlert.Subject,
			"Please make sure that the SUBJECT field is not empty.");
		return false;
	}
	if (document.sendAlert.AlertPersonnel.length == 0)
	{
		fixElement(document.sendAlert.Selected,
			"Please specify the people you want to send this Alert Message to.");
		return false;
	}

/* I can't do this check with FCKeditor because the MsgText may not have been replaced if out of focus
	if (document.sendAlert.MsgText.value =='')
	{
		if (!confirm("Are you sure you want to send an empty Alert Message?"))
		{
			document.sendAlert.MsgText.focus();
			return false;
		}
	}
*/

	getall(document.sendAlert.AlertPersonnel);
	
	return true;
}

function changeTeam()
{
	if ('<%=idS%>' != 'null')
		sendAlert.id.value = '<%=idS%>';
	if ('<%=type%>' != 'null')
		sendAlert.type.value = '<%=type%>';

	selectAll(document.getElementById("AlertPersonnel"));
	sendAlert.action = "addalert.jsp";
	sendAlert.submit();
}
// @AGQ030106
function selectAll(select) {
	var length = select.length;
	for(var i = 0; i < length; i++) {
		select.options[i].selected = true;
	}
}

function submitAlert()
{
	if (!validation())
		return;

	sendAlert.submit();
}

//-->
</script>

<title>
	<%=appS%> Memo
</title>

<script type="text/javascript" src="<%=host%>/FCKeditor/fckeditor.js"></script>
<script type="text/javascript">
  var oFCKeditor;
  window.onload = function()
  {
	oFCKeditor = new FCKeditor( 'MsgText' ) ;
	oFCKeditor.ReplaceTextarea() ;
  	sortSelect(document.getElementById("AlertPersonnel"));
  }
</script>

</head>

<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="100%" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true"/>

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<table width='100%'>
	<tr>
	<td>

	<table>
	<tr><td>
	<b class="head">
	Send Memo
	</b>
	</td></tr>
	</table>

	</td>
	</tr>

	<tr><td height="3"><img src="../i/spacer.gif" width="1" height="3" border="0"></td></tr>
	</table>

	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- CONTENT -->
<table width='90%'>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_big">
		<br>Please enter Memo Message and choose recipients from below.  Click the <b>Submit</b> button to send the Memo.
		<br><br></td>
	</tr>

<!-- add comments -->
<form name="sendAlert" action="post_addalert.jsp" method="post" onSubmit="return validation();">
<input type="hidden" name="townId" value=<%=tidS%> >

<%if (tkidS!=null && tkidS.length()>0)
{%>
	<input type="hidden" name="taskId" value=<%=tkidS%> >
<%}%>
<input type="hidden" name="mtgId" value=<%=idS%> >
<input type="hidden" name="backPage" value="<%=backPage%>">
<input type="hidden" name="id">
<input type="hidden" name="type">
<input type="hidden" name="list">



	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_big">
		<table class="plaintext_big">

			Subject:
			<br><input name="Subject" size="118" value="<%=subject%>">
			<br><br>


<!-- Alerted Personnel -->
		Memo Recipients:
<table width="400" border="0" cellspacing="0" cellpadding="0">

<!-- Meeting Group -->
<tr>
		<td class="formtext">
			<select class="formtext" name="projId" onchange="changeTeam();">
			<option value=''>- Select Recipients -</option>
<%
	if (isMeeting) {
		out.print("<option value='-3'");
		if (projTeamId == -3)
			out.print(" selected");
		out.print(">The Meeting Group</option>");
	}
	out.print("<option value='-1'");
	if (projTeamId == -1)
		out.print(" selected");
	out.print(">* Group List</option>");

	if (!isOMFAPP)
	{
		// all members
		out.print("<option value='0'");
		if (projTeamId == 0)
			out.print(" selected");
		out.print(">All</option>");

		// all projects
		int [] pjObjId = pjMgr.getProjects(pstuser);
		if (pjObjId.length > 0)
		{
			PstAbstractObject [] projectObjList = pjMgr.get(pstuser, pjObjId);
			//@041906SSI
			Util.sortName(projectObjList, true);

			String projName;
			project pj;
			int id;
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
	else
	{
		// my contacts and my towns
		int [] myTownIds = Util2.toIntArray(pstuser.getAttribute("Towns"));
		PstAbstractObject [] myTowns = tnMgr.get(pstuser, myTownIds);
		Util.sortString(myTowns, "Name", true);
		out.print("<option value='0'");
		if (projTeamId == 0)
			out.print(" selected");
		out.print(">My contacts</option>");
		PstAbstractObject tnObj;
		for (int i=0; i<myTowns.length; i++) {
			tnObj = myTowns[i];
			out.print("<option value='" + tnObj.getObjectId() + "'");
			if (projTeamId == tnObj.getObjectId())		// this is the town selected
				out.print(" selected");
			out.print(">" + tnObj.getStringAttribute("Name") + "</option>");
		}
	}
	out.print("</select>");
%>
	</td>
</tr>



<tr>
		<td class="plaintext">
<%
	// get all town people or project team
	PstAbstractObject [] allEmp = null;
	PstAbstractObject [] dlArr = null;
	String meetingGroup = null;
	dlManager dlMgr = dlManager.getInstance();
	if (projTeamId == -1) {
		dlArr = dlMgr.getDLs(pstuser);
		Util.sortName(dlArr);
	}
	else if (projTeamId == -3)
		meetingGroup = "<option value='-3'>&nbsp;The Meeting Group</option>";
	else if (projTeamId > 0) {
		if (!isOMFAPP)
			allEmp = ((user)pstuser).getTeamMembers(projTeamId);
		else {
			// a town is selected for MeetWE
			int [] ids = uMgr.findId(pstuser, "Towns=" + projTeamId);
			allEmp = uMgr.get(pstuser, ids);
		}
	}
	else if (projTeamId == 0)
	{
		if (!isOMFAPP)
			allEmp = ((user)pstuser).getAllUsers();		// already sorted
		else
		{
			// get my contacts
			Object [] contacts = pstuser.getAttribute("TeamMembers");
			allEmp = new PstAbstractObject[contacts.length];
			for (int i=0; i<contacts.length; i++)
			{
				io = (Integer)contacts[i];
				if (io == null) break;
				allEmp[i] = uMgr.get(pstuser, io.intValue());
			}
		}
	}

	// there might be a list of specified recipients (e.g. direct report or vendor company colleague)
	PstAbstractObject [] toEmp = null;
	if (toIdArr != null && toIdArr.size() > 0)
	{
		int id;
		if (allEmp != null)
		{
			for (int i=0; i<allEmp.length; i++)
			{
				if (allEmp[i] == null) continue;
				id = allEmp[i].getObjectId();
				for (int j=0; j<toIdArr.size(); j++)
				{	int temp = dl.getId(toIdArr.get(j).toString());
					if (temp == -1)
						temp = Integer.parseInt(toIdArr.get(j).toString());
 					if (temp == id)
					{
						allEmp[i] = null;
						break;
					}
				}
			}
		}
		else if (dlArr != null) {
			for (int i=0; i<dlArr.length; i++) {
				if (dlArr[i] == null) continue;
				id = dlArr[i].getObjectId();
				for (int j=0; j<toIdArr.size(); j++) {
					int temp = dl.getId(toIdArr.get(j).toString());
					if (temp == id) {
						dlArr[i] = null;
						break;
					}
				}
			}
		}
		else if (meetingGroup != null) {
			for (int j=0; j<toIdArr.size(); j++) {
				int temp = dl.getId(toIdArr.get(j).toString());
				if (temp == -1)
					temp = Integer.parseInt(toIdArr.get(j).toString());
				if (temp == -3) {
					meetingGroup = null;
					break;
				}
			}
		}
		// at this point, allEmp may have some nulls but there will have no overlaps
		// between allEmp and toIdArr
// @AGQ030106a - used js's sortselect method instead
	}

	// allEmp will be on the left while alertEmp will be on the right
	int myid = pstuser.getObjectId();
	String uName;
	String myname = ((user)pstuser).getFullName();
%>
		<table border="0" cellspacing="0" cellpadding="0">
		<tr>
			<td bgcolor="#FFFFFF">
			<select class="formtext_fix" name="Selected" id="Selected" multiple size="5">
<%
// @AGQ031006

//@AGQ030106a
	if (dlArr != null) {
		String prevName = null;
		for(int i = 0; i < dlArr.length; i++) {
			dl curDl = (dl)dlArr[i];
			if(curDl == null) continue;
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
	}

	if (meetingGroup != null) {
		out.print(meetingGroup);
	}

	if (allEmp != null && allEmp.length > 0)
	{
		Util.sortUserArray(allEmp, true);
		for (int i=0; i < allEmp.length; i++)
		{
// @AGQ031006
			if (allEmp[i] == null) continue;
			uName = ((user)allEmp[i]).getFullName();
			out.print("<option value='" +allEmp[i].getObjectId()+ "'>&nbsp;" +uName+ "</option>");
		}
	}
%>
			</select>
			</td>
			<td align="center" valign="middle">
				&nbsp;<input type="button" class="button" name="add" value="&nbsp;&nbsp;&nbsp;Add &gt;&gt;&nbsp;&nbsp;&nbsp;" onClick="swapdata1(this.form.Selected,this.form.AlertPersonnel)">
			<br><input type="button" class="button" name="remove" value="<< Remove" onClick="swapdata(this.form.AlertPersonnel,this.form.Selected)">&nbsp;
			</td>
<!-- people selected -->
			<td bgcolor="#FFFFFF">
<%-- @AGQ030106 --%>
				<select class="formtext_fix" name="AlertPersonnel" id="AlertPersonnel" multiple size="5">
<%
	// check for circle from MyPage
	String circleName = "";
	String circleIdS = request.getParameter("circle");
	if (circleIdS != null)
	{
		PstAbstractObject o = tnMgr.get(pstuser, Integer.parseInt(circleIdS));
		circleName = (String)o.getAttribute("Name")[0];
		out.print("<option value='-4'>&nbsp;" + circleName + "</option>");
	}
	// a list of recipients specified
	if(toIdArr != null && toIdArr.size() > 0) {
		user u = null;
		dl dlObj = null;
		int aUserId = (aUser == null)?-1:aUser.getObjectId();
		for (int i =0; i <toIdArr.size();i++) {
			String temp = toIdArr.get(i).toString();
			int dlInt = dl.getId(temp);
			// user
			if (dlInt == -1) {
				dlInt = Integer.parseInt(temp);
				if (isMeeting && dlInt == -3) {
					out.print("<option value='-3'>&nbsp;The Meeting Group</option>");
				}
				else {
					try {u = (user)uMgr.get(pstuser, Integer.parseInt(temp));}
					catch (PmpException e) {continue;}
					int objId = u.getObjectId();
					//if (objId == myid || aUserId == objId) continue;
					uName = u.getFullName();
					out.print("<option value='" +objId+ "'>&nbsp;" +uName+ "</option>");
				}
			}
			// dl
			else {
				dlObj = (dl)dlMgr.get(pstuser, dlInt);
				out.print("<option value='" + dl.DLESCAPESTR + dlObj.getObjectId() + "'>* " + dlObj.getObjectName() + "</option>");
			}
		}
	}

%>
				</select>
			</td>
		</tr>
		<tr><td><span class="footnotes">* Group list</span></td></tr>
		</table>
</td>
</tr>
</table>
<!-- End Alert Personnel -->
<%
	String prevGuestEmails = request.getParameter("guestEmails");
	if (prevGuestEmails != null) {
		guestEmails.delete(0, guestEmails.length());
		guestEmails.append(prevGuestEmails);
	}

%>
<br />
Guests:<br />
<!-- Guest Emails -->
	<table border="0" cellspacing="0" cellpadding="0" >
		<tr>
			<td>
				<input id="guestEmails" name="guestEmails" class="formtext" type="text" size="120" value="<%=guestEmails.toString() %>"/>
			</td>
		</tr>
		<tr>
			<td>
				<span class="footnotes">Enter email addresses separated by commas (e.g. aaa@z.com, bbb@z.com)</span>
			</td>
		</tr>
	</table>
<!-- End of Guest Emails -->
<!-- Alert Message -->
		<br><br>
		<table width="100%" border="0" cellspacing="0" cellpadding="0">
		<tr><td colspan="2" valign="top">
			<textarea name="MsgText"><%=Util.stringToHTMLString(msg)%></textarea>
		</td></tr>
		</table>


<!-- Send Email Option -->
<%	if (!isOMFAPP)
	{
			if (isCRAPP) emailOnly = true;
%>
			<br><br>
			Send the Memo as:&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
			<input type="radio" name="AlertOption" value="web" <%if (emailOnly) out.print("disabled");%>>Webpage Memo&nbsp;&nbsp;&nbsp;&nbsp;
			<input type="radio" name="AlertOption" value="email" <%if (emailOnly) out.print("checked");%>>Email&nbsp;&nbsp;&nbsp;&nbsp;
			<input type="radio" name="AlertOption" value="both" <%if (emailOnly) out.print("disabled");else out.print("checked");%> >Both
<%	}
	else
	{
			out.print("<input type='hidden' name='AlertOption' value='email'>");
			if (circleIdS != null)
				out.print("<input type='hidden' name='circleId' value='" + circleIdS + "'>");
	}
%>
		<p align="center">
			<input type='button' class='button_medium' value='Submit' onclick='submitAlert();'>&nbsp;&nbsp;&nbsp;
			<input type='button' class='button_medium' value='Cancel' onclick='history.back(-1);'>
		</p>

		</table>
		</td>
	</tr>
</form>
<!-- End of add comments -->

<script language="JavaScript">
<!--
	document.sendAlert.Subject.focus();
//-->
</script>


	</td>
</tr>

<tr><td>&nbsp;</td><tr>


<!-- BEGIN FOOTER TABLE -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->

<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

