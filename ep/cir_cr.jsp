<%
////////////////////////////////////////////////////
//	Copyright (c) 2008, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	cir_cr.jsp
//	Author:	ECC
//	Date:	05/14/08
//	Description:
//		The central repository (CR) page for circles.
//
//	Modification:
//
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "util.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>
<%@ page import = "org.apache.log4j.Logger" %>

<%
	String idS = request.getParameter("id");
	String noSession = "../out.jsp?go=ep/cir_cr.jsp?id=" + idS;
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%
	PstUserAbstractObject me = pstuser;
	if (me instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	Logger l = PrmLog.getLog();
	String s;
	
	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if (iRole > 0)
	{
		if ((iRole & user.iROLE_ADMIN) > 0)
			isAdmin = true;
	}
	int myUid = me.getObjectId();
	String myUidS = String.valueOf(myUid);
	
	int circleId = Integer.parseInt(idS);
	
	townManager tnMgr = townManager.getInstance();
	userManager uMgr = userManager.getInstance();
	meetingManager mMgr = meetingManager.getInstance();
	resultManager rMgr = resultManager.getInstance();
	attachmentManager attMgr = attachmentManager.getInstance();
	actionManager actMgr = actionManager.getInstance();
	
	SimpleDateFormat df1 = new SimpleDateFormat ("MM/dd/yy");
	SimpleDateFormat df2 = new SimpleDateFormat ("MM/dd/yyyy hh:mm a");
	String host = Util.getPropKey("pst", "PRM_HOST");
	
	// get the circle object and info
	PstAbstractObject cirObj = null;

	try {cirObj = tnMgr.get(me, circleId);}
	catch (PmpException ee) {response.sendRedirect("../out.jsp?msg=Circle not found.&go=ep/ep_home.jsp"); return;}
	
	String circleName = (String)cirObj.getAttribute("Name")[0];
	String logbookTitle = circleName + " Page";
	
	// check authorization
	int [] ids;
	if (!isAdmin)
	{
		ids = uMgr.findId(me, "om_acctname='" + me.getObjectName()
				+ "' && Towns=" + idS);
		if (ids.length <=0)
		{
			response.sendRedirect("../out.jsp?msg=Access declined. Only members of " + circleName
					+ " are allowed to access this page.&go=ep/ep_home.jsp");
			return;
		}
	}

	// get circle info
	int totalMember, totalMtg, totalBlog, totalAttach;
	ids = uMgr.findId(me, "Towns=" + idS);				// total members
	totalMember = ids.length;
	
	// get all document attachments for this circle
	// they are either with the meeting or the blog
	PstAbstractObject o;
	Object [] oids = null;
	int [] attIds = new int[0];
	int [] mtgIds;
	mtgIds = mMgr.findId(me, "TownID='" + idS + "'");		// total meetings
	totalMtg = mtgIds.length;
	for (int i=0; i<totalMtg; i++)
	{
		o = mMgr.get(me, mtgIds[i]);
		oids = o.getAttribute("AttachmentID");
		attIds = Util2.mergeIntArray(attIds, Util2.toIntArray(oids));
	}
	
	ids = rMgr.findId(me, "TaskID='" + idS + "'");		// total blogs
	totalBlog = ids.length;
	for (int i=0; i<totalBlog; i++)
	{
		o = rMgr.get(me, ids[i]);
		oids = o.getAttribute("AttachmentID");
		attIds = Util2.mergeIntArray(attIds, Util2.toIntArray(oids));
	}
	totalAttach = attIds.length;

%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">

<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<script language="JavaScript" src="../date.js"></script>
<jsp:include page="../init.jsp" flush="true"/>

<script language="JavaScript">
<!--


//-->
</script>

<title>
	Circle Central Repository
</title>

</head>


<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">

<table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr align="left" valign="top">
    <td width="100%">
	<jsp:include page="../head.jsp" flush="true"/>
</table>
<table border="0" cellspacing="0" cellpadding="0">
  <tr align="left" valign="top">
    <td>
      <table width="780" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td>
            <table width="780" border="0" cellspacing="0" cellpadding="0">
              <tr>
                <td width="26" height="30"><a name="top">&nbsp;</a></td>
                <td width="754" height="30" align="left" valign="bottom" class="head">
				Circle's Central Repository
				 </td>
              </tr>
            </table>
          </td>
        </tr>
        <tr>
			<td width="100%">

<!-- TAB -->
			<jsp:include page="../in/home.jsp" flush="true">
			<jsp:param name="role" value="<%=iRole%>" />
			</jsp:include>

			</td>
        </tr>
		<tr>
          		<td width="100%" valign="top">
					<!-- Navigation SUB-Menu -->
					<table border="0" width="780" height="1" cellspacing="0" cellpadding="0">
						<tr>
							<td width="20" height="1" bgcolor="#FFFFFF"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
							<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
						</tr>
					</table>
					<table border="0" width="780" height="14" cellspacing="0" cellpadding="0">
						<tr>
							<td width="20" height="14" bgcolor="#FFFFFF"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
							<td valign="top" class="BgSubnav">
								<table border="0" cellspacing="0" cellpadding="0">
								<tr class="BgSubnav">
								<td width="40"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
					<!-- Home -->
						<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
						<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
						<td><a href="ep_home.jsp" class="subnav">Home</a></td>
						<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
					<!-- Search -->
						<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
						<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
						<td><a href="search.jsp" class="subnav">Search</a></td>
						<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
					<!-- Circle Page -->
						<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
						<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
						<td><a href="../ep/my_page.jsp?uid=<%=idS%>" class="subnav"><%=logbookTitle%></a></td>
						<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
					<!-- Circle Repository -->
						<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
						<td width="7"><img src="../i/spacer.gif" width="7" height="1" border="0"></td>
						<td width="15" height="14"><img src="../i/nav_arrow.gif" width="20" height="14" border="0"></td>
						<td><a href="#" onclick="return false;" class="subnav"><u>Circle Repository</u></a></td>
						<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
					<!-- Manage Circle -->
						<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
						<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
						<td><a href="../ep/cir_update.jsp?townId=<%=idS%>" class="subnav">Manage Circle</a></td>
						<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>

						<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

						</tr>
								</table>
							</td>
						</tr>
					</table>
					<table border="0" width="780" height="1" cellspacing="0" cellpadding="0">
						<tr>
							<td width="20" height="1" bgcolor="#FFFFFF"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
							<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
						</tr>
					</table>
					<!-- End of Navigation SUB-Menu -->
				</td>
	        </tr>
        <tr><td>&nbsp;</td></tr>

<tr>
	<td>
	<table border='0' cellspacing="0" cellpadding="0">
	<tr>
	<td><img src='../i/spacer.gif' width='20' /></td>
<%
		String picURL = null;
		String name;
		picURL = Util2.getPicURL(cirObj, "../i/group.jpg");
		name = circleName;

		// list summary info
		out.print("<td width='85' height='80' valign='top'>");
		out.print("<img src=" + picURL + " height='80' style='margin:10px; padding:5px; border:2px solid #6699cc;'/>");
		out.print("<td width='500' valign='bottom'>");
		out.print("<table><tr><td colspan='2' class='plaintext_bold'>" + name + "</td></tr>");
		out.print("<tr><td width='140' class='plaintext'>No. of members:</td>");
		out.print("<td class='plaintext'>" + totalMember + "</td></tr>");
		
		out.print("<tr><td class='plaintext'>No. of meetings:</td>");
		out.print("<td class='plaintext'>" + totalMtg + "</td></tr>");
		
		out.print("<tr><td class='plaintext'>No. of blogs:</td>");
		out.print("<td class='plaintext'>" + totalBlog + "</td></tr>");
		
		out.print("<tr><td class='plaintext'>No. of attachments:</td>");
		out.print("<td class='plaintext'>" + totalAttach + "</td></tr>");
		out.print("<tr><td>&nbsp;</td></tr>");
		out.print("</table></td>");
%>

</tr></table>

<!-- Ready to list circle objects -->


<table width="780" border="0" cellspacing="0" cellpadding="0">
<tr>
<td width="25">&nbsp;</td>

<td>
<!-- RED partition line -->
	<table border='0' cellpadding="0" cellspacing="0">
	<tr>
	<td bgcolor="#bb5555" height="1"><img src="../i/spacer.gif" width="750" height="1" border="0"></td>
	</tr>
	</table>
	
<!-- List all attachments -->
	<table border='0' cellpadding="0" cellspacing="0">
	<tr><td><img src='../i/spacer.gif' height='15' /></td></tr>
	<tr><td class='plaintext_blue'>File Attachments</td></tr>
	<tr><td><img src='../i/spacer.gif' height='5' /></td></tr>
	</table>
<%
	String [] label = {"File Name", "Owner", "Created Date", "Meeting ID", "Blog ID", "View #"};
	int [] labelLen = {310, 100, 96, 70, 80, 45};
	boolean [] bAlignCenter = {false, true, true, true, true, true};
	out.print(Util.showLabel(label, labelLen, bAlignCenter, true));		// showAll and align center

	attachment attObj;
	String fName, author, createDateS, midS, blogIdS, authIdS=null, lnkBlog=null;
	int frequency;
	Date dt;
	Integer io;
	String bgcolor="";
	boolean even = false;
	for (int i=totalAttach-1; i>=0; i--)
	{
		// get the attachment object
		try {attObj = (attachment)attMgr.get(me, attIds[i]);}
		catch (PmpException e) {l.error("error getting attachement [" + attIds[i] + "]"); continue;}
		fName = attObj.getFileName();
		try
		{
			authIdS = (String)attObj.getAttribute("Owner")[0];
			author = Util2.getOwnerFullName(me, attObj, null);
		}
		catch (PmpException e)
		{
			l.info("Removed bad ownerId (" + authIdS + ") from attachment [" + attIds[i] + "]");
			author = "-";
			authIdS = "-1";
			attObj.setAttribute("Owner", "-1");
			attMgr.commit(attObj);
		}
		dt = (Date)attObj.getAttribute("CreatedDate")[0];
		createDateS = df1.format(dt);
		
		io = (Integer)attObj.getAttribute("Frequency")[0];
		if (io != null) frequency = io.intValue();
		else frequency = 0;
		
		// see if the attachment is assoc with a meeting or a blog
		midS = blogIdS = null;
		ids = mMgr.findId(me, "AttachmentID='" + attIds[i] + "'");
		if (ids.length > 0)
		{
			// it is a meeting attachment
			midS = String.valueOf(ids[0]);
		}
		else
		{
			// see if the attachment is assoc with a blog
			ids = rMgr.findId(me, "AttachmentID='" + attIds[i] + "'");
			if (ids.length > 0)
			{
				// it is a blog attachment
				blogIdS = String.valueOf(ids[0]);
				o = rMgr.get(me, ids[0]);
				s = (String)o.getAttribute("Type")[0];
				if (s.equals(result.TYPE_FRUM_BLOG))
				{
					lnkBlog = "<a href='../ep/my_page.jsp?uid=" + o.getAttribute("TaskID")[0] + "#" + blogIdS + "'>"
							+ blogIdS + "</a>";
				}
				else if (s.endsWith(result.TYPE_ARCHIVE))
				{
					lnkBlog = "<a href='" + host + "/servlet/ShowFile?archiveFile=" + o.getAttribute("ArchiveFile")[0] + "#" + blogIdS + "'>"
							+ blogIdS + "</a>";
				}
			}
		}
		
		if (even)
			bgcolor = "bgcolor='#EEEEEE'";
		else
			bgcolor = "bgcolor='#ffffff'";
		even = !even;

		out.print("<tr " + bgcolor + ">");
		out.print("<td class='plaintext'></td>");
		out.print("<td class='plaintext'><a href='" + host + "/servlet/ShowFile?attId=" + attIds[i]
				+ "'>" + fName + "</a></td>");
		out.print("<td class='plaintext'></td>");
		
		out.print("<td class='plaintext'></td>");
		out.print("<td class='plaintext' align='center'><a href='../ep/ep1.jsp?uid=" + authIdS + "'>" + author + "</a></td>");
		out.print("<td class='plaintext'></td>");

		out.print("<td class='plaintext'></td>");
		out.print("<td class='plaintext' align='center'>" + createDateS + "</td>");
		out.print("<td class='plaintext'></td>");
		
		out.print("<td class='plaintext'></td>");
		if (midS != null)
			out.print("<td class='plaintext' align='center'><a href='../meeting/mtg_view.jsp?mid=" + midS + "#attachment'>"
					+ midS + "</a></td>");
		else
			out.print("<td class='plaintext' align='center'>-</td>");
		out.print("<td class='plaintext'></td>");
		
		out.print("<td class='plaintext'></td>");
		if (blogIdS != null)
			out.print("<td class='plaintext' align='center'>" + lnkBlog + "</td>");
		else
			out.print("<td class='plaintext' align='center'>-</td>");
		out.print("<td class='plaintext'></td>");
		
		out.print("<td class='plaintext'></td>");
		out.print("<td class='plaintext' align='center'>" + frequency + "</td>");
		out.print("<td class='plaintext'></td>");
		
		out.print("</tr>");
	}	// END for each attachment
	
	out.println("</table>");		// close table for attachment listing
%>
	
<!-- List all circle meetings -->
	<table border='0' cellpadding="0" cellspacing="0">
	<tr><td><img src='../i/spacer.gif' height='30' /></td></tr>
	<tr><td class='plaintext_blue'>Circle Meetings</td></tr>
	<tr><td><img src='../i/spacer.gif' height='5' /></td></tr>
	</table>
<%
	String [] labelMtg = {"Subject", "Schedule", "State", "Coordinator", "Action #", "Decision #", "Blog #", "View #"};
	int [] labelMtgLen = {160, 150, 35, 100, 50, 60, 45, 45};
	boolean [] bAlignCenterMtg = {false, true, true, true, true, true, true, true};
	out.print(Util.showLabel(labelMtg, labelMtgLen, bAlignCenterMtg, true));		// showAll and align center
	
	Arrays.sort(mtgIds);
	meeting mtgObj;
	String subject, startS, expireS, stateS, fn;
	int actionNum=0, decisionNum=0;
	even = false;

	for (int i=0; i<totalMtg; i++)
	{
		// list each meeting object
		try {mtgObj = (meeting)mMgr.get(me, mtgIds[i]);}
		catch (PmpException e) {l.error("error getting meeting [" + mtgIds[i] + "]"); continue;}

		if (even)
			bgcolor = "bgcolor='#EEEEEE'";
		else
			bgcolor = "bgcolor='#ffffff'";
		even = !even;
		out.print("<tr " + bgcolor + ">");
		
		subject = (String)mtgObj.getAttribute("Subject")[0];
		out.print("<td class='plaintext'></td>");
		out.print("<td class='plaintext' valign='top'><a href='../meeting/mtg_view.jsp?mid=" + mtgIds[i]
				+ "'>" + subject + "</a></td>");
		out.print("<td class='plaintext'></td>");
		
		// schedule
		startS  = df2.format((Date)mtgObj.getAttribute("StartDate")[0]);
		expireS = df2.format((Date)mtgObj.getAttribute("ExpireDate")[0]);
%>

<script language="JavaScript">
<!-- Begin
	var diff = getDiffUTC();
	var stD = new Date('<%=startS%>');
	var enD = new Date('<%=expireS%>');
	var tm = stD.getTime() + diff;
	stD = new Date(tm);

	tm = enD.getTime() + diff;
	enD = new Date(tm);

	document.write("<td class='plaintext'></td>");
	document.write("<td class='plaintext_grey'>" + formatDate(stD, "MM/dd/yy (E) hh:mm a") + "</td>");
	document.write("<td class='plaintext'></td>");
// End -->
</script>

<%
		// state
		stateS = (String)mtgObj.getAttribute("Status")[0];
		out.print("<td class='plaintext'></td>");
		if (stateS=="Live") {fn = "dot_red.gif"; s = "On Air";}
		else if (stateS=="New") {fn = "dot_orange.gif"; s = "New";}
		else if (stateS=="Finish") {fn = "dot_green.gif"; s = "Finished";}
		else {fn = "dot_lightblue.gif"; s = "Closed/Canceled";}
		out.print("<td align='center' title='" + s + "'><img src='../i/" + fn + "' border='0'></td>");
		out.print("<td class='plaintext'></td>");

		// coordinator
		try
		{
			authIdS = (String)mtgObj.getAttribute("Owner")[0];
			author = Util2.getOwnerFullName(me, mtgObj, null);
		}
		catch (PmpException e)
		{	// in case owner is deleted
			author = "-";
			authIdS = "-1";
		}
		out.print("<td class='plaintext'></td>");
		out.print("<td class='plaintext' align='center'><a href='../ep/ep1.jsp?uid=" + authIdS + "'>" + author + "</a></td>");
		out.print("<td class='plaintext'></td>");
		
		// action#
		ids = actMgr.findId(me, "MeetingID='" + mtgIds[i] + "' && Type='" + action.TYPE_ACTION + "'");
		actionNum += ids.length;
		out.print("<td class='plaintext'></td>");
		out.print("<td class='plaintext' align='center'><a href='../meeting/mtg_view.jsp?mid=" + mtgIds[i] + "#action'>"
				+ ids.length + "</a></td>");
		out.print("<td class='plaintext'></td>");
		
		// decision#
		ids = actMgr.findId(me, "MeetingID='" + mtgIds[i] + "' && Type='" + action.TYPE_DECISION + "'");
		decisionNum += ids.length;
		out.print("<td class='plaintext'></td>");
		out.print("<td class='plaintext' align='center'><a href='../meeting/mtg_view.jsp?mid=" + mtgIds[i] + "#action'>"
				+ ids.length + "</a></td>");
		out.print("<td class='plaintext'></td>");

		// blog#
		ids = rMgr.findId(me, "TaskID='" + mtgIds[i] + "' && Type='" + result.TYPE_MTG_BLOG + "'");
		out.print("<td class='plaintext'></td>");
		out.print("<td class='plaintext' align='center'><a href='../meeting/mtg_view.jsp?mid=" + mtgIds[i] + "#blog'>"
				+ ids.length + "</a></td>");
		out.print("<td class='plaintext'></td>");
		
		// view#
		io = (Integer)mtgObj.getAttribute("ViewBlogNum")[0];
		if (io != null) frequency = io.intValue();
		else frequency = 0;
		out.print("<td class='plaintext'></td>");
		out.print("<td class='plaintext' align='center'>" + frequency + "</td>");
		out.print("<td class='plaintext'></td>");

		out.print("</tr>");
	}
	
	// show total
	if (totalMtg > 0)
	{
		out.print("<tr><td colspan='13'></td>");
		out.print("<td><hr></td>");
		out.print("<td colspan='2'></td>");
		out.print("<td><hr></td>");
		out.print("</tr>");
		out.print("<tr><td colspan='9'></td>");
		out.print("<td colspan='2' align='right' class='plaintext'><b>Total</b>:</td>");
		out.print("<td colspan='2'></td>");
		out.print("<td class='plaintext' align='center'>" + actionNum + "</td>");
		out.print("<td colspan='2'></td>");
		out.print("<td class='plaintext' align='center'>" + decisionNum + "</td>");
		out.print("</tr>");
	}
	out.println("</table>");		// close table for meeting listing
	
	// review all actions and decisions
	if (totalMtg > 0)
	{
		out.print("<table>");
		out.print("<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>");
		out.print("<tr><td>");
		out.print("<img src='../i/spacer.gif' width='485' height='1'>");
		out.print("<img src='../i/bullet_tri.gif' width='20' height='10'>");
		out.print("<a class='listlinkbold' href='../project/proj_action.jsp?mid=" + mtgIds[0] + "'>Review all actions and decisions</a>");
		out.print("</td></tr>");
		out.print("</table>");
	}
	
%>


</td>
</tr>
</table>


<!-- ************************** -->

      </table>
    </td>
  	</tr>
  	
	<tr><td><img src='../i/spacer.gif' height='20' /></td></tr>
</table>


<jsp:include page="../foot.jsp" flush="true"/>
</body>
</html>

