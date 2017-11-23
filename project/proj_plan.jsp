<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: proj_plan.jsp
//	Author: ECC
//	Date:	03/18/04
//	Description: Project listing page.
//
//	Modification:
//		@081503ECC	Change code for release 2.0.
//		@050605ECC	Only get top level plantask in proj_plan.jsp.  Use
//					Background process to get the complete project plan.
//		@ECC063005	Add project options.  Enable member update plan.
//		@041906SSI	Added sort function to Project names.
//		@ECC081407	Support Blog Module.
//		@ECC031709	Restrictive access task.
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "oct.codegen.*" %>
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
	String noSession = "../out.jsp?go=project/proj_plan.jsp?projId="+projIdS;
	//System.out.println("projId=" + projIdS);
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%!
	static boolean hasChild(Vector rPlan, int i, int level)
	{
		if (i >= rPlan.size()-1) {
			return false;		// no task behind me at all
		}
		Hashtable ht = (Hashtable)rPlan.elementAt(i+1);
		int llevel = ((Integer)((Object [])ht.get("Level"))[0]).intValue();
		return (llevel == level+1);
	}
%>

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

////////////////////////////////////////////////////////
	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}

	if (projIdS==null || projIdS.equals("session"))
		projIdS = (String)session.getAttribute("projId");
	else
		session.setAttribute("projId", projIdS);

	if (projIdS == null || projIdS.equals("null"))
	{
		// proj_select.jsp will retrieve my last opened project
		response.sendRedirect("proj_select.jsp?backPage=proj_plan.jsp");
		return;
	}
	Logger l = PrmLog.getLog();

	projectManager pjMgr = projectManager.getInstance();
	userManager uMgr = userManager.getInstance();

	int projId = Integer.parseInt(projIdS);
	project projObj = null;
	try {projObj = (project)pjMgr.get(pstuser, projId);}
	catch (PmpException e)
	{
		// failed to get the project, go to select another project
		response.sendRedirect("proj_select.jsp");
		return;
	}
	String projName = projObj.getObjectName();
	String projDispName = projObj.getDisplayName();

	String s;
	String backPage = "../project/proj_plan.jsp?projId=" + projIdS;
	
	// check if I need to update cache
	Date pjUpdatedTime = (Date) projObj.getAttribute("LastUpdatedDate")[0];
	Date cachedTime = (Date) session.getAttribute("cachePlanTime");
	boolean bNeedRefreshCache =  (cachedTime!=null && pjUpdatedTime.after(cachedTime));
	//System.out.println("bNeedRefreshCache=" + bNeedRefreshCache);

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

	// @ECC081407 Blog Module
	boolean isBlogModule = util.Prm.isBlogModule();
	
	// showing bold face on a task
	int selectedTaskId = 0;
	s = request.getParameter("boTaskId");
	if (s != null) {
		selectedTaskId = Integer.parseInt(s);
	}


	// about tree expansion/collapse
	String toggle = request.getParameter("toggle");
	if (toggle == null)
		toggle = "";
	else
		session.removeAttribute("expandTree");

	String wholeTree = request.getParameter("tree");	// expandALL or closeALL
	if (wholeTree!=null) {
		if (wholeTree.equals("expandALL"))
			session.setAttribute("expandTree", "true");	// entire tree expanded
		else
			session.removeAttribute("expandTree");
	}
	
	// if first time opening the tree, respect task override on expand
	boolean bFirstTime = request.getParameter("fst")!=null;

	// show latest blog
	s = request.getParameter("showBlog");
	boolean bShowLastBlog = s!=null && s.equals("1");

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
	try {uMgr.get(pstuser, coordinatorId);}
	catch (PmpException e) {
		// project owner does not exist
		coordinatorId = 0;
		coordinatorIdS = null;
		l.error("The project owner is not found for project [" + projIdS + "]");
	}

	// project's TownID stores the TownID this proj belongs to
	String townIdS = null;
	int townId = 0;
	if ((townIdS = (String)projObj.getAttribute("TownID")[0]) != null)
	{
		townId = Integer.parseInt(townIdS);
		s = PstManager.getNameById(pstuser, townId);
		session.setAttribute("townName", s);
	}
	//town tObj = (town)townManager.getInstance().get(pstuser, townId);
	//int sheriffId = Integer.parseInt((String)tObj.getAttribute("Chief")[0]);

	user me = (user)pstuser;
	boolean bChangeCurrentPlan = false;
	String lastProjIdS = (String)me.getAttribute("LastProject")[0];
	//System.out.println("lastPJ=" + lastProjIdS);

	if ((lastProjIdS == null) || (projId != Integer.parseInt(lastProjIdS)))
	{
		// cannot use pstuser which only has partial attributes
		// a.setAttribute("LastTown", townIdS);
		me.setAttribute("LastProject", projIdS);
		uMgr.commit(me);

		// session.setAttribute("planStack", null);	// ECC: do it later down the code
		bChangeCurrentPlan = true;					// notify plan stack to refresh
	}
	session.setAttribute("projectId", projIdS);		// for plan stack
	//System.out.println("bChangeCurrentPlan=" + bChangeCurrentPlan);
	
	boolean isTreeExpandAll = !bChangeCurrentPlan && session.getAttribute("expandTree")!=null;

	// need to get the latest plan for this project
	plan latestPlan = projObj.getLatestPlan(pstuser);
	String latestPlanIdS = latestPlan.getObjectName();

	// Versioning
	String planVersion = (String)latestPlan.getAttribute("Version")[0];

	// @ECC063005
	String optStr = (String)projObj.getAttribute("Option")[0];
	if (optStr == null) optStr = "";

	////////////////////////////////////////////////////////

	////////////////////////////////////
	// @050605ECC Need to make sure that the plan is completely loaded by background thread
	s = (String)session.getAttribute("planComplete");
	while (s!=null && s.equals("false"))
	{
		try {Thread.sleep(500);}		// sleep for 0.5 sec
		catch (InterruptedException e) {}
		s = (String)session.getAttribute("planComplete");
	}

	////////////////////////////////////
	
%>


<head>
<title><%=Prm.getAppTitle()%></title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../errormsg.jsp" flush="true"/>

<script language="JavaScript">
<!--

function toggleTree(loc, hasEffect)
{
	// evaluate only if I have children
	if (hasEffect) {
		var now = new Date().getTime();
		location = "proj_plan.jsp?dd=" + now + "&projId=<%=projId%>&toggle=" + loc + "#" +loc ;
	}
}

function tree(all, bAnchor, bFirstTime)
{
	var jump = "";
	var oriLoc = parent.document.URL;
	if (bAnchor) {
		jump = getAnchor(oriLoc);
	}
	oriLoc = addURLOption(oriLoc, "tree=" + all);
	if (bFirstTime)
		oriLoc = addURLOption(oriLoc, "fst=1");
	if ('<%=selectedTaskId%>' != '0')
		oriLoc += "#" + "<%=selectedTaskId%>";
	location = oriLoc;
}

//-->
</script>

<style type="text/css">
#bubbleDIV {position:relative;z-index:1;left:1em;top:.9em;width:3em;height:3em;vertical-align:bottom;text-align:center;}
img#bg {position:relative;z-index:-1;top:-2em;width:3em;height:3em;border:0;}
img#sign {position:relative;top:.4em;}
.ptextS1 {padding-top:5px;}
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
					<td height="30" align="left" valign="middle" class="head">
						<b><%=Prm.getProjectPlanLabel()%></b>
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
	}
%>
						</td>
						<td valign='bottom' align='right' width='80'>
							<%out.print(Util4.showHelp("step3", "Click for help in project management")); %>
						</td>
						</tr>
					</table>

					</tr>
	            </table>
	          	</td>
	        </tr>
</table>
	        
<table width='90%' border="0" cellspacing="0" cellpadding="0">
<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>

			<tr>
          		<td width="100%">
					<!-- Navigation Menu -->
<% if (isMeetWE) { %>
					<jsp:include page="../in/home.jsp" flush="true">
					<jsp:param name="role" value="<%=iRole%>" />
					</jsp:include>
<% } else { %>
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Project" />
				<jsp:param name="subCat" value="ProjectPlan" />
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

	<tr><td colspan="2"><img src='../i/spacer.gif' height='5'/></td></tr>

	<tr>
		<td><img src='../i/spacer.gif' width='15' border='0'/></td>
		<td>

<!-- Project Name -->
	<table width="90%" border="0" cellpadding="0" cellspacing="0">

	<tr>
<form>
	<td class="heading">
		Project Name&nbsp;&nbsp;
		<select name="projId" class="formtext" onchange="submit()">
<%
		out.print(Util.selectProject(pstuser, projId));
		out.print("</select>");

		if (!isGuestRole) {
%>
		&nbsp;&nbsp;
		<a href="../blog/addalert.jsp?townId=<%=townId%>&projId=<%=projId%>&backPage=<%=backPage%>">
		<img src="../i/eml.gif" border="0"/></a>
<%		} %>

	</td>
</form>

		<form method="post" name="showDateType" action="proj_plan.jsp">
			<input type="hidden" name="projId" value="<%=projIdS%>" >

		<td class="plaintext_big" align="right">
			<input type="checkbox" name="showBlog" value="1"
				<%if (bShowLastBlog) {%>checked<%}%>
				onClick="document.showDateType.submit()">
			Show Latest Blog&nbsp;&nbsp;&nbsp;
		</td>

		</form>
	</tr>
	
	<tr><td><img src='../i/spacer.gif' height='5'/></td></tr>

	</table>

<!-- *************************   Page Headers   ************************* -->

<!-- LABEL -->
<table width="90%" border="0" cellspacing="0" cellpadding="0">
<tr>
<td>
	<table width="100%" border='0' cellpadding="0" cellspacing="0">
	<tr><td bgcolor="#EBECED" height="3"><img src="../i/spacer.gif" width="1" height="3" border="0"/></td></tr>
	</table>
	<table width="100%" border="0" cellspacing="0" cellpadding="0">
	<tr><td colspan="20" height="2" bgcolor="#336699"><img src="../i/spacer.gif" width="2" height="2"/></td></tr>

	<tr>
	<td width="6" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width='55%' bgcolor="#6699cc" class="td_header"><strong>&nbsp;
<%
	if (isTreeExpandAll) {%>
		<img src='../i/minus.gif' onclick='tree("closeALL", false, false)'/>&nbsp;Task Folder</strong></td>
<%	} else {%>
		<img src='../i/plus.gif' onclick='tree("expandALL", false, false)'/>&nbsp;Task Folder</strong></td>
<%	}%>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"/></td>
	<td width="6" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="25" bgcolor="#6699cc" class="td_header" align="center"><strong>St.</strong></td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2"/></td>
	<td width="6" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="55" bgcolor="#6699cc" class="td_header" align="center"><strong>Owner</strong></td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2"/></td>
	<td width="6" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="40" bgcolor="#6699cc" class="td_header" align="center"><strong>Blog</strong></td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2"/></td>
	<td width="6" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="53" bgcolor="#6699cc" class="td_header" align="center"><strong>Start</strong></td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2"/></td>
	<td width="6" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="53" bgcolor="#6699cc" class="td_header" align="center"><strong>Due</strong></td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2"/></td>
	<td width="6" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="53" bgcolor="#6699cc" class="td_header" align="center"><strong>Updated</strong></td>
	</tr>


<!-- PROJ PLAN -->
<%
	String bgcolor="";
	boolean even = false;
	String[] levelInfo = new String[JwTask.MAX_LEVEL];
	String ownerIdS, tStatus, latestComment, pName, taskIdS, pTaskIdS, expand;
	task tkObj;
	int idx, level, order;

	taskManager tkMgr = taskManager.getInstance();
	latest_resultManager lrMgr = latest_resultManager.getInstance();
	latest_result lResultObj = null;
	user empObj = null;
	String lastOwner = "";
	String dot=null;
	Date showDate, lastUpdated, dt1;
	Object [] pLevel;
	Object [] pOrder;
	String PLUS = "+", MINUS = "-", NO_CHILD = "";
	boolean [] showTree = new boolean[JwTask.MAX_LEVEL+1];
	for (int i=1; i<=JwTask.MAX_LEVEL; i++)
		showTree[i] = false;
	showTree[0] = true;		// always show root

	// begin setting up plan stack
	Stack planStack = (Stack)session.getAttribute("planStack");

	// Plan is represented by a Vector of Task
	// Task is represented by a hashtable.

	int iFilled = 0;		// 0, PRM, and/or CR
	Integer io = (Integer)session.getAttribute("filledInfo");
	if (io != null) iFilled = io.intValue();

	if ((planStack == null) || bChangeCurrentPlan || bNeedRefreshCache
			|| ((iFilled & PrmProjThread.PTM) == 0))
	{
		// @050605ECC Use background thread: the order of the following calls is important
		// if the bkgd thread is running to construct the plan stack, kill it
		session.setAttribute("cachePlanTime", new Date());
		PrmProjThread.backgroundConstructPlan(
				session, pstuser, latestPlanIdS, projIdS, bChangeCurrentPlan, false);
		if (optStr.contains(project.OP_EXPAND_TREE) || isTreeExpandAll)
		{
			%><script language="JavaScript">tree("expandALL", true, true);</script><%
			return;
		}
		// Get plan tasks for this project plan
		// @050605ECC Only get top level temporary planTask to display
		planStack = PrmProjThread.setupPlan(PrmProjThread.PTM, null, null, pstuser, projIdS, latestPlanIdS, false);
		//session.setAttribute("planStack", planStack);
	}
	// end of setting up plan stack
	
	Date today = Util.getToday();

	String locS;
	String phLabel;			// phase label
	int phNumber = 0;		// phase number (monotonically increasing)
	String phColor = "";	// color of different phases
	String mainPhColor = "";
	int phLevel = -1;		// phase level
	int uid;
	int noShowLevel = 9999;		// @ECC031709
	Date startDt, expireDt, completeDt, dt2, lastUpdateJustDate;
	boolean isContainer;
	String begB, endB;		// bold face
	String taskMgmtLink, taskBlogLink;
	Vector rPlan = null;
	
	if((planStack != null) && !planStack.empty())
	{
		rPlan = (Vector)planStack.peek();

		// double check to make sure the plan is the project we try to display
		if (false && rPlan.size() > 0) {	// ECC debug
			Hashtable rTask = (Hashtable)rPlan.elementAt(0);
			String cacheProjIdS = (String) rTask.get("ProjectID");
			if (!cacheProjIdS.equals(projIdS)) {
				// clear session and try again
				//session.removeAttribute("projId");
				response.sendRedirect("proj_plan.jsp?projId=" + projIdS);
				return;
			}
		}
		//JwTask.fixHeader(rPlan, pstuser, true);
						
		String restrictiveImg;
						
		for(int i=0; i < rPlan.size(); i++)
		{
			Hashtable rTask = (Hashtable)rPlan.elementAt(i);
			//status = (String)rTask.get("Status");
			pName = (String)rTask.get("Name");
			taskIdS = (String)rTask.get("TaskID");
			expand = (String)rTask.get("Expand");
			pLevel = (Object [])rTask.get("Level");
			pOrder = (Object [])rTask.get("Order");

			level = ((Integer)pLevel[0]).intValue();
			order = ((Integer)pOrder[0]).intValue() + 1;

			// @ECC031709
			if (level > noShowLevel)
				continue;
			else if (noShowLevel != 9999)
				noShowLevel = 9999;

			tkObj = (task)rTask.get("Task");

			if (level == 0)
				levelInfo[level] = String.valueOf(order);
			else
				levelInfo[level] = levelInfo[level - 1] + "." + order;
			locS = levelInfo[level];

			////// Code to support expand and shrink
			boolean isExpand = false;
			boolean bHasChild = hasChild(rPlan, i, level);		// || !isTreeExpandAll

			if (wholeTree!=null)	// whole tree expand or close
			{
				if (wholeTree.equals("expandALL"))
				{
					if (!showTree[level]) {
						// not show me
						showTree[level+1] = false;		// don't show my children also
						continue;
					}
					
					// expand the whole tree, I am not checking showTree anymore
					boolean bOverrideTreeExpand = tkObj.getSubAttribute("Option", "OverrideExpand")!=null;
					if (bFirstTime && bOverrideTreeExpand) {
						// allow override by task option not to show my children
						if (bHasChild)
							expand = PLUS;
						else
							expand = MINUS;
						isExpand = false;
						showTree[level+1] = false;		// don't show my children
					}
					else {
						expand = MINUS;
						isExpand = true;
						showTree[level+1] = true;		// show my children
					}
					rTask.put("Expand", expand);
				}
				else
				{
					// close the whole tree: only show toplevel
					if (expand==null || expand.equals(MINUS)) {
						expand = PLUS;
						rTask.put("Expand", PLUS);
					}
					if (level > 0) continue;
				}
			}
			else if (isTreeExpandAll && toggle.length()<=0)
			{
				if (expand==null || expand.equals(PLUS)) {
					expand = MINUS;
					rTask.put("Expand", MINUS);
				}
				isExpand = true;
			}
			else
			{
				if (toggle.equals(locS))	// I just click this item
				{
					// ECC: I don't have to worry about bHasChild because if it doesn't have children
					// the MINUS sign would not be clickable
					if (expand==null || expand.equals(PLUS)) {
						expand = MINUS;		// open it now
					}
					else if (expand.equals(MINUS)) {
						// just click to close this item
						expand = PLUS;
					}
					rTask.put("Expand", expand);// toggled
				}
				else if (showTree[level])
				{
					if (expand==null)	// shown first time
					{
						if (bHasChild)
							expand = PLUS;
						else
							expand = MINUS;
						rTask.put("Expand", expand);
					}
				}
				else
				{
					// not show me
					showTree[level+1] = false;		// don't show my children also
					continue;
				}

				if (expand==null)
					continue;

				if (expand.equals(MINUS)) {
					isExpand = true;
					showTree[level+1] = true;	// show the immedate children
				}
				else {
					showTree[level+1] = false;
				}
			}
			////// End of expand and shrink

			// phase display
			boolean isPhase;
			phLabel = null;			// always reset label
			if (tkObj.isPhase(pstuser)) {
				// found a new phase
				isPhase = true;
				phLevel = level;
				phColor = tkObj.getPhaseColor(pstuser);
				if (phColor!=null && phColor.length()>0) {
					phColor = "bgcolor='" + phColor + "'";
				}
				phLabel = "Phase " + tkObj.getPhaseString(pstuser);
				if (phLabel.indexOf('.') != -1) {
					phColor = mainPhColor;		// use top phase color
				}
				else {
					mainPhColor = phColor;		// remember main (top) phase color
				}
			}
			else if (level <= phLevel) {
				isPhase = false;
				phColor = "";
			}

			// @ECC031709 check restrictive access
			s = Util2.getAttributeString(tkObj, "TeamMembers", ";");
			if (s.length() > 0) {
				restrictiveImg =
						"&nbsp;<img src='../i/lock3.gif' border='0' width='15' title='" + s + "'/>";
				if (!s.contains(String.valueOf(myUid)))
				{
					noShowLevel = level;
					continue;
				}
			}
			else
				restrictiveImg = "";
			
			pTaskIdS = (String)rTask.get("PlanTaskID");
			backPage = "../blog/blog_task.jsp?projId=" +projId+ ":planTaskId=" +pTaskIdS;

			Date tLastUpdated = (Date)tkObj.getAttribute("LastUpdatedDate")[0];

			ownerIdS = (String)tkObj.getAttribute("Owner")[0];
			tStatus = (String)tkObj.getAttribute("Status")[0];
			startDt = (Date)tkObj.getAttribute("StartDate")[0];
			if (startDt == null) {		// use startDate to denote container task
				isContainer = true;
				startDt = (Date)tkObj.getAttribute("OriginalStartDate")[0];
			}
			else {
				isContainer = false;
			}

			// last blog
			latestComment = (String)rTask.get("LastComment");
			lastUpdated = (Date)rTask.get("LastUpdatedDate");
			if (lastUpdated == null)
				lastUpdated = tLastUpdated;
			lastUpdateJustDate = Formatter.parse(Formatter.format(lastUpdated));
			
			int width = 5 + 22 * Math.min(level,3)-1;

			if (even)
				bgcolor = Prm.DARK;
			else
				bgcolor = Prm.LIGHT;
			even = !even;

			// phase label
			if (phLabel != null) {
				out.print("<tr><td><img src='../i/spacer.gif' height='5'/></td></tr>");
				out.print("<tr " + bgcolor + ">");
				out.print("<td " + phColor + "></td>");
				out.print("<td colspan='19'><table border='0' cellspacing='0' cellpadding='0'><tr>");
				out.print("<td><img src='../i/spacer.gif' width='10'/></td>");
				out.print("<td class='plaintext_big'><b>" + phLabel + "</b></td>");
				out.print("</tr></table></td></tr>");
			}

			//////////////////////////////////////////////////////////////////////
			// start displaying a task
			
			// prepare URL links
			taskMgmtLink = "../project/task_update.jsp?projId=" +projId+ "&pTaskId=" + pTaskIdS;
			s = (String)rTask.get("BlogNum");
			if (s.equals("0")) {
				taskBlogLink = "../blog/addblog.jsp?type=" + result.TYPE_TASK_BLOG
						+ "&id=" + taskIdS + "&backPage=../project/proj_plan.jsp?projId=" + projIdS + "&taskId=" + taskIdS;
			}
			else {
				taskBlogLink = "../blog/blog_task.jsp?projId=" + projIdS + "&taskId=" + taskIdS;
			}
				
			out.print("<tr " + bgcolor + ">");

			// task folder name
			out.print("<td " + phColor + ">&nbsp;<a name='" + locS + "'></a>");
			out.print("<a name='" + taskIdS + "'></a>");
			out.print("</td><td>");
			out.println("<table width='100%' " + bgcolor +" border='0' cellspacing='2' cellpadding='2'>");
			out.print("<tr><td width='" + width + "'></td>");
			out.print("<td width='11' valign='top'><table cellspacing='0' cellpadding='0'>");
			out.print("<tr><td><img src='../i/spacer.gif' height='2'></td></tr><tr><td>");
			if (isExpand)
				out.print("<img id='sign' src='../i/minus.gif' onclick='toggleTree(\"" +locS+ "\", " + bHasChild + ")'>");
			else
				out.print("<img id='sign' src='../i/plus.gif' onclick='toggleTree(\"" +locS+ "\", true)'>");	// always evaluatge
			out.print("&nbsp;");
			out.print("</td></tr></table></td>");
			
			out.print("<td><table border='0' cellpadding='0' cellspacing='0'><tr>");
			out.print("<td class='ptextS1' width='12' valign='top'>");
			out.print(locS + "&nbsp;</td>");
			out.print("<td class='ptextS1' valign='top' title='TaskID: " + taskIdS + "'><a href='"
					+ taskBlogLink + "'>");
			if (selectedTaskId == tkObj.getObjectId()) out.print("<b>" + pName + "</b>");
			else out.print(pName);
			out.print("</a></td>");
			out.print("<td>" + restrictiveImg + "</td>");
			out.print("</tr></table></td>");
			out.print("</tr></table></td>");

			boolean bUpdated = false;			// show the red dot
			if (lastUpdated!=null && (lastUpdated.after(lastLogin) || today.equals(lastUpdateJustDate))) {	// check last blog
				begB = "<b><font color='red'>";
				endB = "</font></b>";
			}
			else {
				begB = endB = "";
			}

			if (tLastUpdated.after(lastLogin))	// tLastUpdated should not be null
				bUpdated = true;
			if (tLastUpdated.after(lastUpdated))
				lastUpdated = tLastUpdated;		// show the latest date

			if (isContainer) {
				expireDt = null;
				completeDt = null;
			}
			else {
				expireDt = tkObj.getExpireDate();
				completeDt = tkObj.getCompleteDate();
			}

			// status
			dot = "../i/";
			if (isContainer) {dot += "db.jpg"; tStatus="Container";}
			else if (tStatus.equals("Open")) {dot += "dot_lightblue.gif";}
			else if (tStatus.equals("New")) {dot += "dot_orange.gif";}
			else if (tStatus.equals("Completed")) {dot += "dot_green.gif";}
			else if (tStatus.equals("Late")) {dot += "dot_red.gif";}
			else if (tStatus.equals("On-hold")) {dot += "dot_grey.gif";}
			else if (tStatus.equals("Canceled")) {dot += "dot_cancel.gif";}
			else {dot += "dot_grey.gif";}
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td class='listlink' align='center'>");
			out.print("<a href='" + taskMgmtLink + "'>");
			out.print("<img src='" + dot + "' title='" + tStatus + "' border='0'>");
			if (bUpdated)
				out.print("<img src='../i/dot_redw.gif' title='Updated'>");
			out.println("</a></td>");

			// owner
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td width='55' align='center'>");
			if (ownerIdS != null)
			{
				// ECC: need to optimize this in the near future
				if (!ownerIdS.equals(lastOwner))
				{
					try {empObj = (user)uMgr.get(pstuser,Integer.parseInt(ownerIdS));}
					catch (PmpException e)
					{
						// switch to project owner
						if (coordinatorId > 0) {
							l.info("Replace task owner (" + ownerIdS + ") with project owner for task [" + taskIdS + "]");
							tkObj.setAttribute("Owner", coordinatorIdS);
							tkMgr.commit(tkObj);
							ownerIdS = coordinatorIdS;
							empObj = (user)uMgr.get(pstuser, Integer.parseInt(ownerIdS));
						}
						else {
							empObj = null;
							ownerIdS = "";
						}
					}
				}
				lastOwner = ownerIdS;
				if (empObj != null) {
					out.print("<a class='listlink' href='../ep/ep1.jsp?uid=" + empObj.getObjectId() + "'>");
					out.print((String)empObj.getAttribute("FirstName")[0]);
					out.print("</a>");
				}
				else {
					out.print("-");
				}
			}
			out.println("</td>");

			// blog Num
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td><a href='" + taskBlogLink + "'><div id='bubbleDIV'>");
			out.print(begB + s + endB);
			out.print("<img id='bg' src='../i/bubble.gif' />");
			out.println("</div></a></td>");

			// StartDate
			// if there is an Actual StartDate (EffectiveDate), use that
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td class='listtext' align='center'>");
			dt1 = (Date)tkObj.getAttribute("EffectiveDate")[0];
			if (dt1 == null) dt1 = startDt;
			if (dt1 != null)
				out.print(Formatter.format(dt1));
			else
				out.print("-");
			out.println("</td>");

			// ExpireDate
			// if there is an Actual Finish Date (CompleteDate), use that
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td class='listtext' align='center'>");
			dt2 = completeDt;
			if (dt2 == null) {
				dt2 = expireDt;
			}
			if (dt2 != null) {
				out.print(Formatter.format(dt2));
			}
			/*
			if ( expireDt!=null && (dt1==null || !expireDt.before(dt1)) ) {
				// do not show ExpireDate if it is before the StartDate
				out.print(phase.parseDateToString(expireDt, format));//Formatter.format(showDate));
			}*/
			else {
				out.print("-");
			}
			out.println("</td>");
			
			// LastUpdatedDate
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td class='listtext' align='center'>" + begB);
			if (lastUpdated != null) {
				out.print(Formatter.format(lastUpdated));
			}
			else {
				out.print("-");
			}
			out.println(endB + "</td>");
			
			out.println("</tr>");
			out.println("<tr " + bgcolor + ">"
					+ "<td " + phColor + "></td>"
					+ "<td colspan='19'><img src='../i/spacer.gif' width='2' height='2'></td></tr>");
			
			// option to display the latest blog
			if (bShowLastBlog) {
				out.print("<tr " + bgcolor + ">"
						+ "<td " + phColor + "></td>"
						+ "<td colspan='19' align='center'>");
				out.print(Util.showLastBlog(pstuser, projIdS, taskIdS, "Task", "100px", "auto", -1));
				out.print("</td></tr>");
				
				out.println("<tr " + bgcolor + ">"
						+ "<td " + phColor + "></td>"
						+ "<td colspan='19'><img src='../i/spacer.gif' width='2' height='10'></td></tr>");
			}
		}	// END: for loop for the rPlan

		if (rPlan.size() <= 0) {
			// empty project plan: output a help line to guide the user
			out.print("<tr><td colspan='20'><img src='../i/spacer.gif' height='10' /></td></tr>");
			out.print("<tr><td colspan='20'><img src='../i/spacer.gif' height='20' /></td></tr>");
			out.print("<tr><td colspan='20'>&nbsp;&nbsp;<img src='../i/bullet_tri.gif'/>"
					+ "<a href='../plan/popPlanInsert.jsp?realorder=0&levelInfo=&lastlevelInfo=&backPage=../plan/updplan.jsp?projId="
					+ projIdS + "' class='ptextS3'><b>Add a project task</b></a></td>");
			out.print("<tr><td colspan='20'><img src='../i/spacer.gif' height='20' /></td></tr>");
			out.print("<tr><td colspan='20' class='plaintext'>");
			out.print("&nbsp;You have an empty project plan.  Click");
			out.print(Util4.showHelp("step4", "Click for help to Change Project Plan"));
			out.print(" and follow the instruction to Change Project Plan and add tasks to the project.</td></tr>");
			out.print("<tr><td colspan='20'><img src='../i/spacer.gif' height='30' /></td></tr>");
		}
	}

	out.println("</table>");

%>

		</td>
		</tr>
		<tr><td colspan="2">&nbsp;</td></tr>
	</table>
<!-- END PROJ PLAN -->

<%
	if (rPlan!=null && rPlan.size() > 0) {
		out.print("<table><tr>");
		out.print("<td width='10'>&nbsp;</td>");
		out.print("<td class='tinytype' align='center'><b>Task Status</b>:");
		out.print("&nbsp;&nbsp;<img src='../i/dot_orange.gif' border='0'>New");
		out.print("&nbsp;&nbsp;<img src='../i/dot_lightblue.gif' border='0'>Open");
		out.print("&nbsp;&nbsp;<img src='../i/dot_green.gif' border='0'>Completed");
		out.print("&nbsp;&nbsp;<img src='../i/dot_red.gif' border='0'>Late");
		out.print("&nbsp;&nbsp;<img src='../i/dot_grey.gif' border='0'>On-hold");
		out.print("&nbsp;&nbsp;<img src='../i/dot_cancel.gif' border='0'>Canceled");
		out.print("&nbsp;&nbsp;<img src='../i/dot_redw.gif' border='0'>Updated");
		out.print("&nbsp;&nbsp;&nbsp;&nbsp;");
		out.print("<img src='../i/db.jpg' border='0'/> Container");
		out.print("</td></tr>");
	
		// link for easy update plan
		out.print("<tr><td colspan='20'><img src='../i/spacer.gif' height='20' /></td></tr>");
		out.print("<tr><td colspan='20'>&nbsp;&nbsp;<img src='../i/bullet_tri.gif'/>"
				+ "<a href='../plan/updplan.jsp?projId=" + projIdS
				+ "' class='ptextS3'><b>Change the project plan</b></a></td></tr>");
		out.print("<tr><td colspan='20'><img src='../i/spacer.gif' height='20' /></td></tr>");

		out.print("</table>");
	}
%>


		<!-- End of Content Table -->
		<!-- End of Main Tables -->
	</td>
</tr>
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
