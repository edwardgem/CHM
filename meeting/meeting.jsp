<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>

<%
//
//	Copyright (c) 2010, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: meeting.jsp
//	Author: ECC
//	Date:	01/17/11
//	Description: Show meetings of a project.
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.codegen.phase.PhaseInfo" %>
<%@ page import = "oct.omm.common.*" %>
<%@ page import = "oct.omm.client.*" %>
<%@ page import = "oct.omm.db.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.ParseException" %>
<%@ page import = "java.text.SimpleDateFormat" %>
<%@ page import = "org.apache.log4j.Logger" %>

<%
	String projIdS = request.getParameter("projId");
	String noSession = "../out.jsp?go=meeting/meeting.jsp?projId="+projIdS;
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%!
	final int SHOW_MAX	= 10;
	SimpleDateFormat df0 = new SimpleDateFormat ("MM/dd/yy (E)");
	SimpleDateFormat df1 = new SimpleDateFormat ("h:mm a");
	SimpleDateFormat df2 = new SimpleDateFormat ("MM/dd/yyyy");
	
	void initDF(PstUserAbstractObject u)
		throws PmpException
	{
		int myUid = u.getObjectId();
		userinfoManager uiMgr = userinfoManager.getInstance();
		userinfo myUI = (userinfo) uiMgr.get(u, String.valueOf(myUid));
		TimeZone myTimeZone = myUI.getTimeZone();
		if (!userinfo.isServerTimeZone(myTimeZone)) {
			df0.setTimeZone(myTimeZone);
			df1.setTimeZone(myTimeZone);
			df2.setTimeZone(myTimeZone);
		}
	}

	String todayS, yesterdayS, tomorrowS;
	Date yesterday, twoDaysAgo, twoWeeksAgo, oneWeekAgo, nextTwoWeek;

	String getTimeLabel(Date dt)
		throws ParseException
	{
		if (dt == null) return null;
		if (dt.before(twoWeeksAgo)) {
			return "More than a few weeks ago";	// too long ago
		}
		if (dt.before(oneWeekAgo) && dt.after(twoWeeksAgo)) {
			return "Two Weeks Ago";
		}
		
		if (dt.before(twoDaysAgo) && dt.after(oneWeekAgo)) {
			return "Last Week";
		}
		
		String dtDateOnly = df2.format(dt);		
		
		if (dtDateOnly.equals(yesterdayS) || (dt.before(yesterday) && dt.after(twoDaysAgo)) ) {
			return "Yesterday";
		}
		
		if (dtDateOnly.equals(todayS)) {
			return "Today";
		}
		
		tomorrowS = df2.format(df2.parse(todayS).getTime() + 3600000*24);
		if (dtDateOnly.equals(tomorrowS)) {
			return "Tomorrow";
		}
		
		if (dt.before(nextTwoWeek)) {
			return "Upcoming ...";
		}
		return null;		// too far away
	}
	
	void evaluateTime()
	{
		Date now = new Date();
		todayS = df2.format(now);
		yesterday = new Date(now.getTime() - 3600000*24);
		yesterdayS = df2.format(yesterday);
		twoDaysAgo = new Date(now.getTime() - 3600000*24*2);
		twoWeeksAgo = new Date(now.getTime() - 3600000*24*14);			// 14 days ago
		oneWeekAgo = new Date(now.getTime() - 3600000*24*7);			// 7 days ago
		nextTwoWeek = new Date(now.getTime() + 3600000*24*14);
	}
%>

<%
	////////////////////////////////////////////////////////
	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	initDF(pstuser);

	if (StringUtil.isNullOrEmptyString(projIdS) || projIdS.equals("session"))
		projIdS = (String)session.getAttribute("projId");	
	else
		session.setAttribute("projId", projIdS);

	if (StringUtil.isNullOrEmptyString(projIdS))
	{
		//response.sendRedirect("proj_select.jsp");
		response.sendRedirect("../meeting/cal.jsp");
		return;
	}
	Logger l = PrmLog.getLog();
	
	String browserType = request.getHeader("User-Agent");
	browserType = browserType.toLowerCase();
	boolean isIE = (browserType!=null && browserType.contains("msie"));

	projectManager pjMgr = projectManager.getInstance();
	userManager uMgr = userManager.getInstance();
	meetingManager mMgr = meetingManager.getInstance();
	resultManager rMgr = resultManager.getInstance();

	int projId = Integer.parseInt(projIdS);
	project projObj = null;
	try {projObj = (project)pjMgr.get(pstuser, projId);}
	catch (PmpException e)
	{
		response.sendRedirect("../project/proj_select.jsp");
		return;
	}
	String projName = projObj.getObjectName();
	String projDispName = projObj.getDisplayName();

	String s;

	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if (iRole > 0)
	{
		if ((iRole & user.iROLE_ADMIN) > 0)
			isAdmin = true;
	}

	// to check if session is CR or PRM
	boolean isCRAPP = Prm.isCR();
	boolean isMeetWE = Prm.isMeetWE();
	boolean isPRMAPP = Prm.isPRM();

	// only show it to project team member unless it is public project
	boolean bReadOnly = false;
	String pjType = (String)projObj.getAttribute("Type")[0];
	String pjName = projName.replaceAll("'", "\\\\'");	// just for SQL
	int [] ids = pjMgr.findId(pstuser, "om_acctname='" + pjName + "' && TeamMembers=" + pstuser.getObjectId());
	if ((ids.length <= 0) && !isAdmin )
	{
		if (pjType.equals("Private")) {
			response.sendRedirect("../out.jsp?e=Access declined");
			return;
		}
	}

	String format = "MM/dd/yy";
	SimpleDateFormat Formatter;
	Formatter = new SimpleDateFormat (format);
	
	boolean bShowAll = request.getParameter("all")!=null;

	// project's TownID stores the TownID this proj belongs to
	String townIdS = null;
	int townId = 0;
	if ((townIdS = (String)projObj.getAttribute("TownID")[0]) != null)
	{
		townId = Integer.parseInt(townIdS);
		s = PstManager.getNameById(pstuser, townId);
		session.setAttribute("townName", s);
	}
	
	// get the total meeting held number
	ids = mMgr.findId(pstuser, "ProjectID='" + projIdS
			+ "' && Status!='" + meeting.NEW
			+ "' && Status!='" + meeting.EXPIRE
			+ "' && Status!='" + meeting.ABORT + "'");
	String totalPuralS = (ids.length>1)?"s":"";
	int totalMeetingHeld = ids.length;
	
	// get meeting list
	ids = mMgr.findId(pstuser, "ProjectID='" + projIdS
			+ "' && Status!='" + meeting.EXPIRE
			+ "' && Status!='" + meeting.ABORT + "'");

%>


<head>
<title><%=Prm.getAppTitle()%></title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../errormsg.jsp" flush="true"/>

<script language="JavaScript">
<!--

//-->
</script>

<style type="text/css">
#bubbleDIV {position:relative;z-index:1;left:0em;top:0em;width:3em;height:3em;vertical-align:bottom;text-align:center;}
img#bg {position:relative;z-index:-1;top:-2.2em;width:3em;height:3em;border:0;}
</style>

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
		</table>
		
<table width='90%' border='0' cellspacing='0' cellpadding='0'>
			<tr>
	        	<td>
	            <table width="100%" border="0" cellspacing="0" cellpadding="0">
					<tr>
					<td width="26" height="30"><a name="top">&nbsp;</a></td>
					<td height="30" align="left" valign="bottom" class="head">
						<b>Project Meeting</b>
					</td>
					<td width="245" align='right'>
					<table width='100%' border='0' cellspacing='0' cellpadding='0'>
						<tr><td>
						</td>
						<td><img src='../i/spacer.gif' width='21' height='1'/></td>
						</tr>
					</table>

					</tr>
	            </table>
	          	</td>
	        </tr>
			<tr>
          		<td width="100%">
<!-- Navigation Menu -->
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Event" />
				<jsp:param name="subCat" value="ProjectMeeting" />
				<jsp:param name="role" value="<%=iRole%>" />
			</jsp:include>
<!-- End of Navigation SUB-Menu -->
				</td>
	        </tr>
		</table>
<!-- Content Table -->

 <table width="100%" border="0" cellspacing="0" cellpadding="0">

	<tr><td colspan="2">&nbsp;</td></tr>

	<tr>
		<td><img src='../i/spacer.gif' width='15' border='0'></td>
		<td>


<!-- *************************   Page Headers   ************************* -->

<!-- Main content -->
<table width="100%" border="0" cellspacing="0" cellpadding="0">

<form>
<tr>
	<td class="heading">
		Project Name&nbsp;&nbsp;
		<select name="projId" class="formtext" onchange="submit()">
<%
		out.print(Util.selectProject(pstuser, projId));
%>
		</select>
	</td>
</tr>
</form>

<tr><td>
	<table cellspacing='0' cellpadding='0' width='90%'>
		
<%		
		// display total meeting held for this project so far
		out.print("<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>");
		out.print("<tr><td class='plaintext'>&nbsp;(Total meeting" + totalPuralS + " held: <b>"
				+ totalMeetingHeld + "</b>)</td></tr>");

		// label
		out.print("<tr><td valign='top'>");

		String [] label0 = {"&nbsp;When", "Location", "Subject", "Organizer", "Blog", "Status"};
		int [] labelLen0 = {-20, 13, 45, 12, 5, 5};
		boolean [] bAlignCenter0 = {false, true, false, true, true, true};
		out.print(Util.showLabel(label0, null, null, null,
			labelLen0, bAlignCenter0, true));	// sort, showAll and align center
			
		int colspanNum = label0.length*3 - 1;
		
		String bgcolor="";
		boolean even = false;
		meeting mObj;
		Date startDt, endDt;
		String dateStr, timeStr=null, location, subject, ownerIdS, ownerName, status, dot;
		String desc;
		PstAbstractObject uObj;
		String lastTimeLabel="", timeLabel;
		int ct=0, processed=0;
		Object bTextObj;
		
		evaluateTime();		// need to get date/time at the time this is called
		
		for (int i=0; i<ids.length; i++) {
			mObj = (meeting)mMgr.get(pstuser, ids[i]);
						
			// meeting info
			startDt = mObj.getStartDate();
			endDt = mObj.getExpireDate();

			// filter meeting
			// time label
			timeLabel = getTimeLabel(startDt);	
			if (timeLabel == null) continue;		// either too old or too far away
			
			// do not show more than 10 on this page
			if (!bShowAll && ct<=0 && totalMeetingHeld-processed++ > SHOW_MAX) continue;

			if (startDt!=null && endDt!=null) {
				dateStr = df0.format(startDt);
				timeStr = df1.format(startDt) + " - " + df1.format(endDt);
			}
			else {
				dateStr = null;
			}
			
			location = mObj.getStringAttribute("Location");
			if (StringUtil.isNullOrEmptyString(location)) {
				location = "-";
			}
			subject = mObj.getStringAttribute("Subject");
			ownerIdS = mObj.getStringAttribute("Owner");
			uObj = uMgr.get(pstuser, Integer.parseInt(ownerIdS));
			ownerName = ((user)uObj).getFullName();
			status = mObj.getStringAttribute("Status");
			bTextObj = mObj.getAttribute("Description")[0];
			if (bTextObj != null)
				desc = new String((byte[]) bTextObj, "utf-8");
			else
				desc = null;
			
			if (even)
				bgcolor = Prm.DARK;
			else
				bgcolor = Prm.LIGHT;
			even = !even;
			
			if (!timeLabel.equals(lastTimeLabel)) {
				// display new time label
				out.print("<tr " + bgcolor + "><td colspan='" + colspanNum + "' class='plaintext_blue'>");
				out.print("<img src='../i/spacer.gif' height='20' width='5'/>");
				out.print(timeLabel + "</td></tr>");
				out.print("<tr " + bgcolor + "><td colspan='" + colspanNum + "'><img src='../i/spacer.gif' height='10' width='1'/></td></tr>");
				lastTimeLabel = timeLabel;
			}
			else {
				// top space line			
				out.print("<tr " + bgcolor + "><td colspan='" + colspanNum
						+ "'><img src='../i/spacer.gif' height='10' width='1'/></td></tr>");
			}
			
			//////////
			// link to show/hide some old meetings
			if (totalMeetingHeld>SHOW_MAX && ct<=0) {
				if (bShowAll) {
					out.print("<tr><td colspan='" + colspanNum + "' class='listlinkbold'>");
					out.print("<img src='../i/bullet_tri.gif'/>");
					out.print("<a href='meeting.jsp?projId=" + projIdS + "'>Hide older meetings</a></td></tr>");
				}
				else {
					out.print("<tr><td colspan='" + colspanNum + "' class='listlinkbold'>");
					out.print("<img src='../i/bullet_tri.gif'/>");
					out.print("<a href='meeting.jsp?projId=" + projIdS + "&all=1'>Show more ... (" + (totalMeetingHeld-SHOW_MAX) + ")</a></td></tr>");
				}
				out.print("<tr " + bgcolor + "><td colspan='" + colspanNum
						+ "'><img src='../i/spacer.gif' height='10' width='1'/></td></tr>");
			}
			
			////////////////////////////////////////
			// meeting details
			ct++;
			out.print("<tr " + bgcolor + ">");
			
			// when
			out.print("<td></td>");
			out.print("<td class='plaintext' valign='top'>");
			if (dateStr != null) {
				out.print(dateStr + "<br>&nbsp;&nbsp;&nbsp;" + timeStr);
			}
			else {
				out.print("-");
			}
			out.print("</td>");
			
			// location
			out.print("<td colspan='2'></td>");
			out.print("<td class='plaintext' align='center' valign='top'>" + location + "</td>");
			
			// subject
			out.print("<td colspan='2'></td>");
			out.print("<td class='ptextS1'><a href='mtg_view.jsp?mid=" + ids[i] + "'>"
					+ subject + "</a>");
			if (desc != null) {
				out.print("<div class='plaintext' style='padding:5px 5px 5px 10px;'>" + desc + "</div>");
			}
			out.print("</td>");
			
			// organizer
			out.print("<td colspan='2'></td>");
			out.print("<td class='plaintext' align='center' valign='top'><a href='../ep/ep1.jsp?uid=" + ownerIdS + "'>"
					+ ownerName + "</a></td>");
			
			// blog
			int num = rMgr.findId(pstuser, "TaskID='" + ids[i] + "' && ParentID==null").length;
			out.print("<td colspan='2'></td>");
			out.print("<td class='plaintext' align='center' valign='top'>");
			out.print("<a href='mtg_view.jsp?mid=" + ids[i] + "#blog'><div id='bubbleDIV'>" + num);
			out.print("<img id='bg' src='../i/bubble.gif' />");
			out.println("</div></a></td>");
			
			// status
			dot = "../i/";
			if (status.equals(meeting.LIVE)) {dot += "dot_lightblue.gif"; status="In Progress";}
			else if (status.equals(meeting.NEW)) {dot += "dot_orange.gif";}
			else if (status.equals(meeting.FINISH)) {dot += "dot_blue.gif"; status="Finished";}
			else if (status.equals(meeting.ABORT)) {dot += "dot_cancel.gif"; status="Canceled";}
			else if (status.equals(meeting.COMMIT)) {dot += "dot_black.gif"; status="Closed";}
			else {dot += "dot_grey.gif";}
			out.print("<td colspan='2'></td>");
			out.print("<td class='listlink' align='center' valign='top'>");
			out.print("<img src='" + dot + "' title='" + status + "'>");
			out.println("</td>");

			// close the meeting line
			out.print("</tr>");

			// bottom space line
			out.print("<tr " + bgcolor + "><td colspan='" + colspanNum + "'><img src='../i/spacer.gif' height='10' width='1'/></td></tr>");
		}	// END for each meeting

		out.print("</td></tr>");

		if (ct > 0) {
			out.print("<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>");
			out.print("<tr><td colspan='14'><table><tr>");
			out.print("<td width='10'>&nbsp;</td>");
			out.print("<td class='tinytype' align='center'><b>Meeting Status</b>:");
			out.print("&nbsp;&nbsp;<img src='../i/dot_orange.gif' border='0'>New");
			out.print("&nbsp;&nbsp;<img src='../i/dot_lightblue.gif' border='0'>In Progress");
			out.print("&nbsp;&nbsp;<img src='../i/dot_darkgreen.gif' border='0'>Finished");
			out.print("&nbsp;&nbsp;<img src='../i/dot_cancel.gif' border='0'>Canceled");
			out.print("&nbsp;&nbsp;<img src='../i/dot_black.gif' border='0'>Closed");
			out.print("</td></tr></table></td></tr>");
		}
		
		// link for add a new meeting
		out.print("<tr><td><img src='../i/spacer.gif' height='20'/></td></tr>");
		out.print("<tr><td colspan='14'><table><tr><td>");
		out.print("<img src='../i/spacer.gif' height='20' />");
		out.print("<img src='../i/bullet_tri.gif'/>"
				+ "<a href='mtg_new1.jsp?ProjectId=" + projIdS
				+ "' class='ptextS3'><b>New Meeting</b></a>");
		out.print("</td></tr></table></td></tr>");

%>
		
	</table>
</td>
</tr>
</table>
<!-- End Main content -->

</td>
</tr>

<tr>
	<td colspan='2'>
		<!-- Footer -->
		<jsp:include page="../foot.jsp" flush="true"/>
		<!-- End of Footer -->
	</td>
</tr>
</table>

</td>
</tr>
</table>

</body>
</html>
