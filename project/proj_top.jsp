<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2010, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: proj_head.jsp
//	Author: ECC
//	Date:	11/17/10
//	Description: Project top page for a selected project.
//		@ECC112117	Clicking "Project" Tab will visit this page without parameter. Clicking submenu
//					"Project >> Top" will hit this page with param: ?...&top=1
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
<%@ page import = "java.text.SimpleDateFormat" %>
<%@ page import = "org.apache.log4j.Logger" %>

<%
	String projIdS = request.getParameter("projId");
	String noSession = "../out.jsp?go=project/proj_top.jsp?projId="+projIdS;
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%
	////////////////////////////////////////////////////////
	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}

	String s;
	s = request.getParameter("top");
	boolean isFromTop = (s!=null && s.equals("1"));

	if (projIdS==null || projIdS.equals("session")) {
		projIdS = (String)session.getAttribute("projId");
	}
	else
		session.setAttribute("projId", projIdS);

	if (projIdS == null || projIdS.equals("null"))
	{
		response.sendRedirect("proj_select.jsp?backPage=proj_top.jsp");
		return;
	}
	
	projectManager pjMgr = projectManager.getInstance();

	int projId = Integer.parseInt(projIdS);
	project projObj = null;
	try {projObj = (project)pjMgr.get(pstuser, projId);}
	catch (PmpException e) {
		response.sendRedirect("proj_select.jsp");
		return;
	}
	
	// check project first page
	String topPage = projObj.getStringAttribute("FirstPage");		
	if (!isFromTop && topPage!=null && topPage.equalsIgnoreCase("blogpage")) {
		// display project blog page as Top
		response.sendRedirect("../blog/blog_task.jsp?projId=" + projIdS);
		return;
	}
	///////////////////////////////////////////////////////////////////////////

	
	userManager uMgr = userManager.getInstance();
	meetingManager mMgr = meetingManager.getInstance();
	actionManager aMgr = actionManager.getInstance();
	resultManager rMgr = resultManager.getInstance();
	attachmentManager attMgr = attachmentManager.getInstance();

	Logger l = PrmLog.getLog();
	
	String locale = (String) session.getAttribute("locale");
	
	String browserType = request.getHeader("User-Agent");
	browserType = browserType.toLowerCase();
	boolean isIE = browserType.contains("msie");
	boolean isFirefox = browserType.contains("firefox");


	String projName = projObj.getObjectName();
	String projDispName = projObj.getDisplayName();
	int projNameLength = projDispName.length();
	String popName = "Pop_" + projIdS;				// for popup chat window name of this project

	String backPage = "../project/proj_plan.jsp?projId=" + projIdS;

	int myUid = pstuser.getObjectId();
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	boolean isAdmin = ((iRole & user.iROLE_ADMIN) > 0);
	boolean isDirector = ((iRole & user.iROLE_DIRECTOR) > 0);
	boolean isProgMgr = ((iRole & user.iROLE_PROGMGR) > 0);			// @ECC062806
	boolean isGuestRole = ((iRole & user.iROLE_GUEST) > 0);

	// to check if session is CR or PRM
	boolean isCRAPP = Prm.isCR();
	boolean isMeetWE = Prm.isMeetWE();
	boolean isPRMAPP = Prm.isPRM();
	boolean isCwModule = Prm.isCwModule(session);
	boolean isMultiCorp = Prm.isMultiCorp();

	// @ECC081407 Blog Module
	boolean isBlogModule = util.Prm.isBlogModule();

	// only show it to project team member unless it is public project
	boolean bReadOnly = false;
	String pjType = (String)projObj.getAttribute("Type")[0];
	String pjName = projName.replaceAll("'", "\\\\'");	// just for SQL
	int [] ids = pjMgr.findId(pstuser, "om_acctname='" + pjName + "' && TeamMembers=" + pstuser.getObjectId());
	if ((ids.length <= 0) && !(isAdmin || isDirector || isProgMgr) )
	{
		if (pjType.equals("Private"))
		{
			response.sendRedirect("../out.jsp?e=Access declined");
			return;
		}
		else if (pjType.equals("Public Read-only"))
			bReadOnly = true;
	}

	String format = "MM/dd/yy";
	SimpleDateFormat Formatter;
	Formatter = new SimpleDateFormat (format);
	Date lastLogin = (Date)session.getAttribute("lastLogin");
	if (lastLogin == null) lastLogin = new Date();

	String coordinatorIdS = (String)projObj.getAttribute("Owner")[0];
	int coordinatorId = Integer.parseInt(coordinatorIdS);

	// project's TownID stores the TownID this proj belongs to
	String townIdS = null;
	int townId = 0;
	if ((townIdS = (String)projObj.getAttribute("TownID")[0]) != null)
	{
		townId = Integer.parseInt(townIdS);
		s = PstManager.getNameById(pstuser, townId);
		session.setAttribute("townName", s);
	}

	user a = (user)pstuser;
	boolean bChangeCurrentPlan = false;
	String lastProjIdS = (String)a.getAttribute("LastProject")[0];
	if ((lastProjIdS == null) || (projId != Integer.parseInt(lastProjIdS)))
	{
		// cannot use pstuser which only has partial attributes
		// a.setAttribute("LastTown", townIdS);
		a.setAttribute("LastProject", projIdS);
		uMgr.commit(a);

		// session.setAttribute("planStack", null);	// ECC: do it later down the code
		bChangeCurrentPlan = true;					// notify plan stack to refresh
	}
	session.setAttribute("projectId", projIdS);		// for plan stack
	
	// last meeting link
	String mtgLinkS = "../meeting/meeting.jsp?projId=" + projIdS;
	
	// action link
	String actionLinkS = "../project/proj_action.jsp?projId=" + projIdS;
	
	// plan link
	String planLinkS = "../project/proj_plan.jsp?projId=" + projIdS;
			
	// cr link
	String crLinkS = "../project/cr.jsp?projId=" + projIdS;
	
	// blog link
	String blogLinkS = "../project/proj_plan.jsp?projId=" + projIdS + "&showBlog=1";

	// display project index
	int currentIdx = -1;
	int [] pjIdArr = pjMgr.getProjects(pstuser, false);
	for (int i=0; i<pjIdArr.length; i++) {
		if (projId == pjIdArr[i]) {
			currentIdx = i;
			break;
		}
	}
	String pjIdxStr = (currentIdx+1) + " of " + pjIdArr.length;
	int idx = (currentIdx - 1 + pjIdArr.length) % pjIdArr.length;
	int prevPjId = pjIdArr[idx];
	
	idx = (currentIdx + 1) % pjIdArr.length;
	int nextPjId = pjIdArr[idx];
	
	// background construction of plan
	Stack planStack = (Stack)session.getAttribute("planStack");
	if ((planStack == null) || bChangeCurrentPlan)
	{
		// @050605ECC Use background thread: the order of the following calls is important
		// if the bkgd thread is running to construct the plan stack, kill it
		String latestPlanIdS = projObj.getLatestPlan(pstuser).getObjectName();
		PrmProjThread.backgroundConstructPlan(
				session, pstuser, latestPlanIdS, projIdS, bChangeCurrentPlan, false);
		if (projObj.getOption(project.OP_EXPAND_TREE) != null) {
			session.setAttribute("expandTree", "true");
		}
		else {
			session.removeAttribute("expandTree");
		}
	}

%>


<head>
<title><%=Prm.getAppTitle()%></title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<link href="../plan/x.css" rel="stylesheet" type="text/css" media="screen"/>
<script type='text/javascript' src='../plan/x_core.js'></script>
<script type='text/javascript' src='../plan/x_event.js'></script>
<script type='text/javascript' src='../plan/x_drag.js'></script>
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../errormsg.jsp" flush="true"/>

<script language="JavaScript">
<!--

function prev()
{
	location = "proj_top.jsp?projId=<%=prevPjId%>";
}

function next()
{
	location = "proj_top.jsp?projId=<%=nextPjId%>";
}

function dotSetup(d, x, y, dt, dragOK)
{
  var dd = xGetElementById(d);
  xMoveTo(dd, x, y);
  //if (dragOK)
  //	xEnableDrag(dd, d1OnDragStart, d1OnDrag, d1OnDragEnd);
  xShow(dd);
/*
  var i = parseInt(d.substring(1));
  if (i < max-1)
  	low[i+1] = x;
  if (i > 0)
  	high[i-1] = x;

  expDt[i] = dt;		// remember the phase expire date
 */
}


var <%=popName%> = null;
function popChat()
{
	if (<%=popName%> != null && !<%=popName%>.closed)
		<%=popName%>.close();

	var h = 440, w = 330,
		l = window.screen.width - w - 30,
		t = window.screen.height - h - 60;
	<%=popName%> = window.open('../ep/pop_chat.jsp?projId=<%=projIdS%>', '',
			'scrollbars=no,menubar=no,' +
			'left=' + l + ',top=' + t + ',' +
			'height=' + h + ',width=' + w + ',' +
			'resizable=yes,toolbar=no,location=no,status=no');
}

//-->
</script>

<style type="text/css">
.pjhead {font-family: "Lucida Sans Unicode", "Bitstream Vera Sans", "Trebuchet Unicode MS", "Lucida Grande", Verdana, Arial, Helvetica, sans-serif; font-size: 35px; font-weight:bold; color: #666666; line-height: 50px; vertical-align:middle;}
.pjhead_small {font-family: "Lucida Sans Unicode", "Bitstream Vera Sans", "Trebuchet Unicode MS", "Lucida Grande", Verdana, Arial, Helvetica, sans-serif; font-size: 30px; font-weight:bold; color: #666666; line-height: 50px; vertical-align:middle;}
.linkItem TD {font-family: "Lucida Sans Unicode", "Bitstream Vera Sans", "Trebuchet Unicode MS", "Lucida Grande", Verdana, Arial, Helvetica, sans-serif; font-size: 20px; line-height: 30px; vertical-align:middle}
.pt {font-family: "Trebuchet Unicode MS", "Lucida Grande", Verdana, Arial, Helvetica, sans-serif; font-size: 12px; color: #666666; line-height: 20px; vertical-align:middle}
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
			<tr>
	        	<td>
	            <table width="90%" border="0" cellspacing="0" cellpadding="0">
					<tr>
					<td width="26" height="30"><a name="top">&nbsp;</a></td>
					<td height="20" valign='middle' align="left" class="head">
						<b>Project Top</b>
					</td>
				<td class='message' align='left'>
<%
	if (isCwModule) {
		ids = PstFlowStepManager.getInstance().findId(pstuser, "CurrentExecutor='" + myUid
			+ "' && State='" + PstFlowStep.ST_STEP_ACTIVE + "' && ProjectID='" + projIdS + "'");
		ids = project.filterOnHoldSteps(pstuser, ids);		// only consider open items
		String itemN = "";
		if (ids.length > 1)
			itemN = "s";
		out.println("<img src='../i/bullet_tri.gif'/><a href='../box/worktray.jsp?projId=" + projIdS
			+ "'>you have <b>" + ids.length + "</b> work item" + itemN + " pending on this project</a>");
	}
%>
				</td>
					<td width="225">
					<table width='100%' border='0' cellspacing='0' cellpadding='0'>
						<tr><td>
<%
	if (isMeetWE) {
		out.println("<img src='../i/bullet_tri.gif' width='20' height='10'/>");
		out.print("<a class='listlinkbold' href='../ep/my_page.jsp?uid=" + townIdS + "'>Goto Circle Page</a><br />");
	}
	else {
		// not MeetWE
		if (!isCRAPP) {
			if (isCwModule) {
				out.print("<img src='../i/bullet_tri.gif' width='20' height='10'/>");
				out.print("<a class='listlinkbold' href='../box/flowMap.jsp?projId="
						+ projId + "'>Process Map</a><br />");
			}
			if (!bReadOnly)
			{
				out.print("<img src='../i/bullet_tri.gif' width='20' height='10'/>");
				out.print("<a class='listlinkbold' href='../plan/timeline.jsp?projId="
						+ projId + "'>Timeline</a><br />");
				out.print("<img src='../i/bullet_tri.gif' width='20' height='10'/>");
				out.print("<a class='listlinkbold' href='task_updall.jsp?projId="
						+ projId + "'>Update All Tasks</a><br />");
			}
		}
	}%>
						</td>
						<td align='right' valign='bottom' >
							<%out.print(Util4.showHelp("step3", "Click for help in project management")); %>
						</td>
						</tr>
					</table>
					</td>

					</tr>
	            </table>
	          	</td>
	        </tr>
</table>
	        
<table width='90%' border='0' cellspacing='0' cellpadding='0'>
<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>

			<tr>
          		<td width="100%">
					<!-- Navigation Menu -->
<% if (isMeetWE) { %>
					<jsp:include page="../in/home.jsp" flush="true">
					<jsp:param name="role" value="<%=iRole%>" />
					</jsp:include>
<% } else {%>
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Project" />
				<jsp:param name="subCat" value="Top" />
				<jsp:param name="role" value="<%=iRole%>" />
				<jsp:param name="projId" value="<%=projIdS%>" />
			</jsp:include>
<% } %>
<!-- End of Navigation SUB-Menu -->
				</td>
	        </tr>
		</table>
<!-- Content Table -->

 <table width="100%" border="0" cellspacing="0" cellpadding="0">

	<tr>
		<td><img src='../i/spacer.gif' width='15' border='0'/></td>
		<td>


<!-- *************************   Page Headers   ************************* -->

<!-- Main content -->
<table width="90%" border="0" cellspacing="0" cellpadding="0">

<!-- Project list -->
<tr>
	<td>
		<table width='100%' cellspacing='0' cellpadding='0'><tr>
		<td><img src='../i/spacer.gif' width='10' height='1' border='0'/></td>
		<td class="heading" width='120'>
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Project Name")%></td>
		<td>
<form>
		<select name="projId" class="formtext" onchange="submit()">
<%
		out.print(Util.selectProject(pstuser, projId));
%>
		</select>
</form>
		</td>

<% if (!isGuestRole) { %>		
		<td width="228">
			<table width='100%' border='0' cellspacing='0' cellpadding='0'>
				<tr><td>
					<img src='../i/bullet_tri.gif' width='20' height='10'/>
					<a class='listlinkbold' href='javascript:popChat();'>Chat room</a>
					<!-- a class='listlinkbold' href='../ep/ep_chat.jsp?op=9&projId=<++projIdS+>'>Chat room</a> -->
				</td></tr>
			</table>
		</td>
<% } %>		
		</tr>
		</table>
	</td>
</tr>

<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>

<tr><td>
	<table><tr>
		<td><img src='../i/spacer.gif' width='100' height='80'/></td>
		<td valign='top'>
<%
	///////////////////////////////////////////////////////////////////////////////////////
	// project time bar
	///////////////////////////////////////////////////////////////////////////////////////
	int INIT_SPACING = 183;				// leading spacing for dots
	int Y_POSITION	 = 260;				// y-coordinate for the dots (242, 277)
	if (isIE) Y_POSITION = 260;			// IE
	else if (isFirefox) Y_POSITION = 265;
	int maxPhases = Util4.getMaxPhases();
	PhaseInfo [] phaseArr = new PhaseInfo[maxPhases];
	int [] intArr = new int [5];		// see order below
	String [] sArr = new String [3];	// see order below
	boolean bReverseSizeFactor = Util4.prepareTimebarValues(projObj, intArr, sArr);
	int projLength = intArr[0];
	int daysElapsed = intArr[1];
	int daysLeft = intArr[2];
	int daysLate = intArr[3];
	int sizeFactor = intArr[4];
	
	//System.out.println("pjLen=" + projLength + ", elapsed=" + daysElapsed
	//		+ ", left=" + daysLeft + ", late=" + daysLate + ", sf=" + sizeFactor + ", reverseF=" + bReverseSizeFactor);
	
	StringBuffer sBuf = new StringBuffer(4096);
	sBuf.append(Util4.showProjectTimeBar(pstuser, String.valueOf(projId),
			phaseArr,									// will get filled in the call
			sizeFactor, bReverseSizeFactor, true,
			projLength, daysLate, daysElapsed, daysLeft,
			INIT_SPACING, Y_POSITION, false));
	out.println(sBuf.toString());
	
	
	int totalTasks = projObj.getCurrentTasks(pstuser).length;
	String projPlanLinkS = "proj_plan.jsp?projId=" + projIdS;
%>
	</td>
	</tr></table>
</td></tr>

<tr>
	<td align='center'>
	<table>
	<tr>
		<td><table><tr><td><img src='../i/spacer.gif' height='2'/></td></tr>
					<tr><td><a href='javascript:prev();'><img src='../i/tri_left.jpg' width='22' border='0'/></a></td></tr></table></td>
		<td><img src='../i/spacer.gif' width='10'/></td>
<%if (projNameLength <= 20) {%>
		<td class='pjhead'><a class='pjhead' href='<%=projPlanLinkS%>'><%=projDispName%></a></td>
<%} else { %>
		<td class='pjhead_small'><a class='pjhead_small' href='<%=projPlanLinkS%>'><%=projDispName%></a></td>
<%} %>
		<td><img src='../i/spacer.gif' width='10'/></td>
		<td><table><tr><td><img src='../i/spacer.gif' height='2'/></td></tr>
					<tr><td><a href='javascript:next();'><img src='../i/tri_right.jpg' width='22' border='0'/></a></td></tr></table></td>
	</tr>
	<tr><td colspan='4' class='pt' align='right'><a href='<%=projPlanLinkS%>'><%=totalTasks%> 
		<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "task folders")%></a></td></tr>
	<!-- tr><td colspan='4' class='pt' align='right'><%=pjIdxStr%></td></tr-->
	</table>
	</td>
</tr>

<tr>
<td align='center'>
	<table>
		<tr><td><img src='../i/spacer.gif' height='10' width='5'/></td></tr>
		<tr><td><table border='0' class='linkItem'>
<%

				if (!isMultiCorp) {
					out.print("<tr><td width='25'><img src='../i/arrow_bullet.jpg' width='20'/></td>"
							+ "<td><a href='" + projPlanLinkS + "'>Project Tasks</a>"
							+ "<span class='pt'>&nbsp;&nbsp;(" + totalTasks + ")</span></td>");
				}

				ids = rMgr.findId(pstuser, "ProjectID='" + projIdS + "' && Type='" + result.TYPE_PROJ_BLOG + "' && ParentID=null");
				out.print("<tr><td width='25'><img src='../i/arrow_bullet.jpg' width='20' /></td>"
						+ "<td align='left'><a href='" + blogLinkS + "'>" + StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Project Blogs") + "</a>"
						+ "<span class='pt'>&nbsp;&nbsp;(" + ids.length + ")</span></td>");

				ids = rMgr.findId(pstuser, "ProjectID='" + projIdS + "' && Type='" + result.TYPE_TASK_BLOG + "' && ParentID=null");
				out.print("<tr><td width='25'><img src='../i/arrow_bullet.jpg' width='20' /></td>"
						+ "<td align='left'><a href='" + blogLinkS + "'>" + StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Task Blogs") + "</a>"
						+ "<span class='pt'>&nbsp;&nbsp;(" + ids.length + ")</span></td>");
				
				ids = attMgr.findId(pstuser, "ProjectID='" + projIdS + "' && Type='" + attachment.TYPE_TASK + "'");
				out.print("<tr><td width='25'><img src='../i/arrow_bullet.jpg' width='20'/></td>"
						+ "<td align='left'><a href='" + crLinkS + "'>" + StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Files") + "</a>"
						+ "<span class='pt'>&nbsp;&nbsp;(" + ids.length + ")</span></td>");
				
				ids = mMgr.findId(pstuser, "ProjectID='" + projIdS + "'");
				out.print("<tr><td width='25'><img src='../i/arrow_bullet.jpg' width='20' /></td>"
						+ "<td align='left'><a href='" + mtgLinkS + "'>" + StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "Meetings") + "</a>"
						+ "<span class='pt'>&nbsp;&nbsp;(" + ids.length + ")</span></td>");
				
				if (isCwModule || isMultiCorp) {
					ids = aMgr.findId(pstuser, "ProjectID='" + projIdS + "' && (Status='Open' || Status='Late')");
					out.print("<tr><td width='25'><img src='../i/arrow_bullet.jpg' width='20' /></td>"
							+ "<td align='left'><a href='" + actionLinkS + "'>" + StringUtil.getLocalString(StringUtil.TYPE_LABEL,locale, "To-do List") + "</a>"
							+ "<span class='pt'>&nbsp;&nbsp;(" + ids.length + ")</span></td>");
				}
				
				/*ids = rMgr.findId(pstuser, "ProjectID='" + projIdS + "' && Type='" + result.TYPE_TASK_BLOG + "' && ParentID=null");
				out.print("<tr><td width='25'><img src='../i/green_light.gif'/></td>"
						+ "<td><a href='" + blogLinkS + "'>Blogs</a>"
						+ "<span class='pt'>&nbsp;&nbsp;(" + ids.length + ")</span></td>");*/
%>
			</table></td>
		</tr>
		<tr><td><img src='../i/spacer.gif' height='20' width='5'/></td></tr>
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
</body>
</html>
