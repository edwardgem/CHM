<%
////////////////////////////////////////////////////
//	Copyright (c) 2004-2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	admin.jsp
//	Author:	ECC
//	Date:	03/22/05
//	Description:
//		Perform admin function for PRM.
//	Modification:
//
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ((pstuser instanceof PstGuest) || ((iRole & user.iROLE_ADMIN) == 0) )
	{
		response.sendRedirect("/error.jsp?msg=Access declined");
		return;
	}
	
	String msg = request.getParameter("msg");
	if (msg == null) msg = "";

	// to check if session is CR or PRM
	boolean isCRAPP = false;
	String app = (String)session.getAttribute("app");
	if (app.equals("CR"))
		isCRAPP = true;

	// total user and user activities
	int totalLogin = 0;
	userinfoManager uiMgr = userinfoManager.getInstance();
	userinfo ui;

	int [] uiId = uiMgr.findId(pstuser, "om_acctname='%'");
	int totalRegister = uiId.length;

	for (int i=0; i<totalRegister; i++)
	{
		ui = (userinfo)uiMgr.get(pstuser, uiId[i]);
		totalLogin += ((Integer)ui.getAttribute("LoginNum")[0]).intValue();
	}

	// check application acts
	int totalActs = 0;
	//totalActs = ((Integer)application.getAttribute("activities")).intValue();

	// town
	townManager tMgr = townManager.getInstance();
	int [] ids = tMgr.findId(pstuser, "om_acctname='%'");
	int totalTown = ids.length;

	// project
	ids = projectManager.getInstance().findId(pstuser, "om_acctname='%'");
	int totalProj = ids.length;
	
	// bug
	ids = bugManager.getInstance().findId(pstuser, "om_acctname='%'");
	int totalBug = ids.length;

	// completed meeting
	ids = meetingManager.getInstance().findId(pstuser,
		"Status='" + meeting.FINISH + "' || Status='" + meeting.COMMIT + "'");
	int totalDoneMtg = ids.length;

	// live meeting
	ids = meetingManager.getInstance().findId(pstuser, "Status='" + meeting.LIVE + "'");
	int totalLiveMtg = ids.length;

	// taskBlog
	ids = resultManager.getInstance().findId(pstuser, "Type='Task'");
	int totalTaskBlog = ids.length;

	// bugBlog
	ids = resultManager.getInstance().findId(pstuser, "Type='Bug'");
	int totalBugBlog = ids.length;

	// Personal Blog
	ids = resultManager.getInstance().findId(pstuser, "Type='" + result.TYPE_ENGR_BLOG + "'");
	int totalEngBlog = ids.length;

	// Decision
	ids = actionManager.getInstance().findId(pstuser, "Type='" + action.TYPE_DECISION + "'");
	int totalDecision = ids.length;

	// Action Item
	ids = actionManager.getInstance().findId(pstuser, "Type='" + action.TYPE_ACTION + "'");
	int totalAction = ids.length;

%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="../init.jsp" flush="true"/>

<title>
	<%=app%> Administration
</title>

</head>

<body text="#000000" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="715" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td width="26">&nbsp;</td>
	<td valign="top">

	<b class="head">

	Administration

	</b><br><br>
	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- CONTENT -->
<table width="770">
	<tr>
		<td width="26">&nbsp;</td>
		<td width="450">&nbsp;</td>
		<td>&nbsp;</td>
		<td width="100"></td>
	</tr>

	<tr>
		<td></td>
		<td colspan='2' class="plaintext_big"><font color="#cc0000">
		<%=msg%></font></td>
		<td></td>
	</tr>

	<tr>
		<td></td>
		<td class="plaintext">Total number of Registered Users:</td>
		<td class="plaintext_blue"><%=totalRegister%></td>
		<td></td>
	</tr>

	<tr>
		<td></td>
		<td class="plaintext">Total number of Towns:</td>
		<td class="plaintext_blue"><%=totalTown%></td>
		<td></td>
	</tr>

	<tr>
		<td></td>
		<td class="plaintext">Total number of Projects:</td>
		<td class="plaintext_blue"><%=totalProj%></td>
		<td></td>
	</tr>
<%	if (!isCRAPP){%>
	<tr>
		<td></td>
		<td class="plaintext">Total number of Bugs:</td>
		<td class="plaintext_blue"><%=totalBug%></td>
		<td></td>
	</tr>

	<tr><td colspan='4'><img src="../i/spacer.gif" height="5"></td></tr>

	<tr>
		<td></td>
		<td class="plaintext">Total number of Task Blogs:</td>
		<td class="plaintext_blue"><%=totalTaskBlog%></td>
		<td></td>
	</tr>

	<tr>
		<td></td>
		<td class="plaintext">Total number of Bug Blogs:</td>
		<td class="plaintext_blue"><%=totalBugBlog%></td>
		<td></td>
	</tr>

	<tr>
		<td></td>
		<td class="plaintext">Total number of Personal Blogs:</td>
		<td class="plaintext_blue"><%=totalEngBlog%></td>
		<td></td>
	</tr>

	<tr><td colspan='4'><img src="../i/spacer.gif" height="5"></td></tr>

	<tr>
		<td></td>
		<td class="plaintext">Total number of Completed Meetings:</td>
		<td class="plaintext_blue"><%=totalDoneMtg%></td>
		<td></td>
	</tr>

	<tr>
		<td></td>
		<td class="plaintext">Total number of Live Meetings:</td>
		<td class="plaintext_blue"><%=totalLiveMtg%></td>
		<td></td>
	</tr>

	<tr><td colspan='4'><img src="../i/spacer.gif" height="5"></td></tr>

	<tr>
		<td></td>
		<td class="plaintext">Total number of Decisions:</td>
		<td class="plaintext_blue"><%=totalDecision%></td>
		<td></td>
	</tr>

	<tr>
		<td></td>
		<td class="plaintext">Total number of Action Items:</td>
		<td class="plaintext_blue"><%=totalAction%></td>
		<td></td>
	</tr>
<%	} %>

	<tr><td colspan='4'><img src="../i/spacer.gif" height="5"></td></tr>

	<tr>
		<td></td>
		<td class="plaintext">Total number of login since last Statistics Reset:</td>
		<td class="plaintext_blue"><%=totalLogin%></td>
		<td align="right">
			<a class="blog_by" href="post_admin.jsp?op=reset&type=LoginNum"
			onClick="return confirm('Are you sure you want to reset LoginNum?')">
			RESET</a>
		</td>
	</tr>

	<tr>
		<td></td>
		<td class="plaintext">Total number of user activities since last check:</td>
		<td class="plaintext_blue"><%=totalActs%></td>
		<td align="right">
			<a class="blog_by" href="admin.jsp">CHECK</a>&nbsp;&nbsp;&nbsp;
			<a class="blog_by" href="post_admin.jsp?op=resetApp&type=activities">RESET</a>
		</td>
	</tr>

</table>

<p>
<table>

	<tr>
	<td width="26">&nbsp;</td>
	<td colspan="2" class="homenewsheader">Adminstrative Tasks:</td>
	</tr>

	<tr>
	<td></td>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="../ep/ep_admin.jsp"><b>Project List</b></a></td>
	</tr>

	<tr>
	<td></td>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="wf.jsp"><b>Workflow Management</b></a></td>
	</tr>

	<tr>
	<td></td>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="fix_db.jsp"><b>Patch Database</b></a></td>
	</tr>

	<tr>
	<td></td>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="uploadDB.jsp"><b>Upload Database</b></a></td>
	</tr>

	<tr>
	<td></td>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="adduser.jsp"><b>Add New User</b></a></td>

	<tr>
	<td></td>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="deluser.jsp"><b>Delete a User</b></a></td>

	<tr>
	<td></td>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="proj.jsp"><b>View Users By Project</b></a></td>
	</tr>

</table>
</p>

<p align="center">
	<input type='button' class='button_medium' value='Back' onclick='location="../ep/ep_admin.jsp";'>
</p>

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

