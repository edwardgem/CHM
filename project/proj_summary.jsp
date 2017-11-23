<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: proj_summary.jsp
//	Author: ECC
//	Date:	09/18/05
//	Description: Project summary page.  This is the proj_plan page for director role.
//	Modification:
//			@ECC110105 sorting
//			@110705ECC Add option to link a Phase or Sub-phase to Task.
//			@ECC040506	Support multiple owners.
//			@ECC041406	Support user-defined bug priority.
//			@041906SSI	Added sort function to Project names.
//			@AGQ042006	Detect Browser and added Upload Status Report link
//			@AGQ042506	Changed phase to objects
// 			@AGQ042506a	Added a for loop to create "dt"s
//			@ECC062806	Support program manager change phase and milestone
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

<%
	String projIdS = request.getParameter("projId");
	String noSession = "../out.jsp?go=project/proj_summary.jsp?projId="+projIdS;
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	////////////////////////////////////////////////////////
	final String BLOG_MIN_HEIGHT = "50px";

	String browserType = request.getHeader("User-Agent");
	String browser = new String("");
	String version = new String("");
	browserType = browserType.toLowerCase();
	if(browserType != null ){
		if((browserType.indexOf("msie") != -1)){
			browser = "Explorer";
			String tempStr = browserType.substring(browserType.indexOf("msie"),browserType.length());
			version = tempStr.substring(4,tempStr.indexOf(";"));
		}
		if ((browserType.indexOf("mozilla") != -1) &&
				(browserType.indexOf("spoofer")== -1) &&
				(browserType.indexOf("compatible") == -1)) {
			if (browserType.indexOf("firefox") != -1) {
				browser = "Firefox";
				int verPos = browserType.indexOf("/");
				if(verPos != -1)
				version = browserType.substring(verPos+1,verPos + 5);
			}
			else if (browserType.indexOf("netscape") != -1) {
				browser = "Netscape";
				int verPos = browserType.indexOf("/");
				if(verPos != -1)
				version = browserType.substring(verPos+1,verPos + 5);
			} else {
				browser = "Mozilla";
				int verPos = browserType.indexOf("/");
				if(verPos != -1)
				version = browserType.substring(verPos+1,verPos + 5);
			}
		}
		if (browserType.indexOf("opera") != -1) {
			browser = "Opera";
		}
		if (browserType.indexOf("safari") != -1) {
			browser = "Safari";
		}
		if (browserType.indexOf("konqueror") != -1) {
			browser = "Konqueror";
		}
	}

	int MAX_DECISION = 20;				// show only last 20 decisions
	int INIT_SPACING = 80;				// leading spacing for dots
	int Y_POSITION	 = 275;				// y-coordinate for the dots (242): Chrome
	if (browser.equals("Explorer")) Y_POSITION = 260;			// IE
	else if (browser.equals("Firefox")) Y_POSITION = 268;		// Firefox

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}

	boolean isAdmin = false;
	boolean isDirector = false;			// I won't get here unless I am director role
	boolean isProgMgr = false;			// @ECC062806
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if (iRole > 0)
	{
		if ((iRole & user.iROLE_ADMIN) > 0)
			isAdmin = true;
		if ((iRole & user.iROLE_DIRECTOR) > 0)
			isDirector = true;
		if ((iRole & user.iROLE_PROGMGR) > 0)
			isProgMgr = true;
	}

	String sessProjIdS = (String)session.getAttribute("projId");
	if (!StringUtil.isNullOrEmptyString(projIdS) && !projIdS.equals(sessProjIdS)) {
		// I just switch to this new project
		// refresh cache
		Util3.refreshPlanHash(pstuser, session, projIdS);
	}
	if (StringUtil.isNullOrEmptyString(projIdS) || projIdS.equals("session"))
		projIdS = sessProjIdS;

	// I cannot set the project ID in session because I didn't do a full
	// planStack rebuild
	//else
	//	session.setAttribute("projId", projIdS);
	if (projIdS == null || projIdS.equals("null"))
	{
		response.sendRedirect("proj_select.jsp");
		return;
	}

	String backPage = "../project/proj_summary.jsp?projId=" + projIdS;

	int myUid = pstuser.getObjectId();

	projectManager pjMgr = projectManager.getInstance();
	userManager uMgr = userManager.getInstance();
	resultManager rMgr = resultManager.getInstance();

	int projId = Integer.parseInt(projIdS);
	project projObj = (project)pjMgr.get(pstuser, projId);

	String projName = projObj.getObjectName();
	String projDispName = projObj.getDisplayName();

	String format = "MM/dd/yy";
	SimpleDateFormat df1 = new SimpleDateFormat (format);
	SimpleDateFormat df2 = new SimpleDateFormat ("MMM dd, yy (EEE) hh:mm a");
	SimpleDateFormat df3 = new SimpleDateFormat ("MM/dd/yyyy");
	Date lastLogin = (Date)session.getAttribute("lastLogin");
	Date pjStartDt = (Date)projObj.getAttribute("StartDate")[0];
	long startTime = pjStartDt.getTime();
	Date today = df3.parse(df3.format(new Date()));

	String coordinatorIdS = (String)projObj.getAttribute("Owner")[0];
	int coordinatorId = Integer.parseInt(coordinatorIdS);

	boolean updateOK = false;
	if (isAdmin || (coordinatorId == myUid) || isProgMgr)
		updateOK = true;

	user coordUser = (user)uMgr.get(pstuser, coordinatorId);
	String lname = (String)coordUser.getAttribute("LastName")[0];
	String uname = coordUser.getAttribute("FirstName")[0] + (lname==null?"":(" " + lname));
	String s;

	// project's TownID stores the TownID this proj belongs to
	String townIdS = (String)projObj.getAttribute("TownID")[0];
	int townId = Integer.parseInt(townIdS);
	String projTownName = PstManager.getNameById(pstuser, townId);
	session.setAttribute("townName", projTownName);
	town tObj = (town)townManager.getInstance().get(pstuser, townId);
	//int sheriffId = Integer.parseInt((String)tObj.getAttribute("Chief")[0]);

	//session.setAttribute("projectId", projIdS);		// for plan stack

	///////////////////////////////////
	// calculation for showing the project BAR
	int [] intArr = new int [5];		// see order below
	String [] sArr = new String [3];	// see order below
	boolean bReverseSizeFactor = Util4.prepareTimebarValues(projObj, intArr, sArr);
	int projLength = intArr[0];
	int daysElapsed = intArr[1];
	int daysLeft = intArr[2];
	int daysLate = intArr[3];
	int sizeFactor = intArr[4];
	String startDate = sArr[0];
	String deadline = sArr[1];
	String completeDate = sArr[2];

	////////////////////////////////////

	s = request.getParameter("showPhReport");
	boolean bShowPhReport = (s==null || s.equals("true"));	// by default, turn on

	s = request.getParameter("showBugBlog");
	boolean bShowBugBlog = (s!=null && s.equals("true"));

	////////////////////////////////////

	// support multiple bug owners
	int numOfOwner;								// total no. of owners
	String [] ownerAttr;						// array that holds the attribute names
	String [] sa;
	s = Util.getPropKey("pst", "BUG_OWNER_ATTRIBUTE");
	if (s != null)
	{
		sa = s.split(";");						// e.g. Owner; Owner1
		numOfOwner = sa.length;
		ownerAttr = new String[numOfOwner];
		for (int i=0; i<numOfOwner; i++)
		{
			ownerAttr[i] = sa[i].trim();
		}
	}
	else
	{
		numOfOwner = 1;
		ownerAttr = new String[1];
		ownerAttr[0] = "Owner";					// default owner attr name
	}

	int columnNum = 36 + 3*numOfOwner;

	String [] ownerLabel = {""};
	if (numOfOwner > 1)
	{
		// need to insert label of multiple owner
		s = Util.getPropKey("pst", "BUG_OWNER_LABEL");
		if (s != null) ownerLabel = s.split(";");
	}


	// @ECC110105 sorting
	bugManager bMgr = bugManager.getInstance();
	int [] bugIds = bMgr.findId(pstuser, "ProjectID='" + projIdS + "' && State!='" + bug.CLOSE + "'");

	String sortby = (String) request.getParameter("sortby");
	if (sortby!=null && sortby.length()==0) sortby = null;
	if (sortby == null)
		Arrays.sort(bugIds);		// default sort by order of entry (i.e. id order) - latest first
	PstAbstractObject [] bugObjList = bMgr.get(pstuser, bugIds);

	String [] sevArr = {"c", "s", "n", ""};

	// @ECC041406
	String [] priArr = {"h", "m", "l"};		// default
	int numUDefPri = 0;
	int idx;
	s = Util.getPropKey("pst", "BUG_MAX_DEFINE_PRI");
	if (s!=null)
	{
		try {numUDefPri = Integer.parseInt(s.trim());}
		catch (Exception e) {/* invalid properties value */}
		if (numUDefPri > 0)
		{
			priArr = new String[numUDefPri + 3];	// plus the default 3
			for (idx=0; idx<numUDefPri; idx++)
				priArr[idx] = bug.PRI_HIGH + (idx+1);
			// append the default value to after the user-defined levels
			priArr[idx++] = "h"; priArr[idx++] = "m"; priArr[idx] = "l";
		}
	}

	if (sortby != null)
	{
		if (sortby.equals("st"))
			Util.sortWithValues(bugObjList, "State", bug.STATE_ARRAY, true);
		else if (sortby.equals("ty"))
			Util.sortWithValues(bugObjList, "Type", bug.CLASS_ARRAY, true);
		else if (sortby.equals("up"))
			Util.sortDate(bugObjList, "LastUpdatedDate");
		else if (sortby.equals("sv"))
			Util.sortWithValues(bugObjList, "Severity", sevArr, true);
		else if (sortby.equals("pr"))
			Util.sortWithValues(bugObjList, "Priority", priArr, true);
		else if (sortby.equals("su"))
			Util.sortUserId(pstuser, bugObjList, "Creator");
		else if (sortby.startsWith("ow"))
		{
			int i = Integer.parseInt(sortby.substring(sortby.length()-1));
			Util.sortUserId(pstuser, bugObjList, ownerAttr[i]);
		}
	}
	String bgcl = "bgcolor='#6699cc'";
	String srcl = "bgcolor='#66cc99'";

	int maxPhases = Util4.getMaxPhases();
	////////////////////////////////////////////////////////
%>


<head>
<title><%=Prm.getAppTitle()%> Project Summary</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<link href="../plan/x.css" rel="stylesheet" type="text/css" media="screen">
<script type='text/javascript' src='../plan/x_core.js'></script>
<script type='text/javascript' src='../plan/x_event.js'></script>
<script type='text/javascript' src='../plan/x_drag.js'></script>
<script type='text/javascript' src="../date.js"></script>
<script type="text/javascript" src="../login_cookie.js"></script>
<script type="text/javascript" src="../resize.js"></script>
<jsp:include page="../init.jsp" flush="true"/>

<script type="text/JavaScript">
<!--

var highZ = 3;
var max = <%=maxPhases%>;
var fac = 86400000;
if ('<%=bReverseSizeFactor%>' == 'false')
	fac /= <%=sizeFactor%>;
else
	fac *= <%=sizeFactor%>;
var LOW = parseInt('<%=INIT_SPACING%>');
var HIGH = 770;
var low = new Array(max);
var high = new Array(max);
var expDt = new Array(max);
low[0] = LOW;
high[max-1] = HIGH;

var winCookieName = "execSumWinHeight";
var divHeight = getCookie(winCookieName);

window.onload = function()
{
	// divHeight must have been initialized by now, either from the cookie or from the body code
	var e = document.getElementById("mtgText0");	// Exec Summary is 0
	if (e != null)
		e.style.height = divHeight;
}

function dotSetup(d, x, y, dt, dragOK)
{
  var dd = xGetElementById(d);
  xMoveTo(dd, x, y);
  if (dragOK)
  	xEnableDrag(dd, d1OnDragStart, d1OnDrag, d1OnDragEnd);
  xShow(dd);

  var i = parseInt(d.substring(1));
  if (i < max-1)
  	low[i+1] = x;
  if (i > 0)
  	high[i-1] = x;

  expDt[i] = dt;		// remember the phase expire date
}
function d1OnDragStart(ele, mx, my)
{
  window.status = '';
  xZIndex(ele, highZ++);
  ele.totalMX = 0;
  ele.totalMY = 0;
}
function d1OnDrag(ele, mdx, mdy)
{
  //xMoveTo(ele, xLeft(ele) + mdx, xTop(ele) + mdy);
  i = parseInt(ele.id.substring(1));

  var newX = xLeft(ele) + mdx;
  if (newX <= low[i]) newX = low[i];
  else if (newX > high[i]) newX = high[i];
  xMoveTo(ele, newX, xTop(ele));
  ele.totalMX += mdx;
  //ele.totalMY += mdy;

  var sdt = new Date((xLeft(ele)-LOW)*fac + <%=startTime%>);
  window.status = formatDate(sdt, "M/d/yy");
  //window.status = ele.id + ': ' + xLeft(ele);
}
function d1OnDragEnd(ele, mx, my)
{
  //window.status = ele.id + ':  X: ' + ele.totalMX + ', Y: ' + ele.totalMY;
  var i = parseInt(ele.id.substring(1));
  var pos = xLeft(ele);
  if (i < max-1)
  	low[i+1] = pos;
  if (i > 0)
  	high[i-1] = pos;

  var s = formatDate(new Date((pos-LOW)*fac + <%=startTime%>), "MM/dd/yyyy");
  window.status = ' Updated deadline (' + (i+1) + '): ' + s + ".  Click Submit to save the change.";
  expDt[i] = s;
}

function saveDots()
{
	var ct = parseInt('<%=maxPhases%>');
	f = document.SavePhase;
	for (var i=0; i<ct; i++)
	{
		var e = document.getElementById('dt'+i);
		e.value = expDt[i];
	}
}

function displayBugBlog()
{
	var ck = "&showBugBlog=" + DisplayBugBlog.showBugBlog.checked
		+ "&showPhReport=" + DisplayPhaseBlog.showPhReport.checked;
	location = "proj_summary.jsp?projId=<%=projIdS%>&sortby=" + DisplayBugBlog.sortby.value
		+ ck + "#bug";
}

function displayPhaseBlog()
{
	var ck = "&showPhReport=" + DisplayPhaseBlog.showPhReport.checked
		+ "&showBugBlog=" + DisplayBugBlog.showBugBlog.checked;
	location = "proj_summary.jsp?projId=<%=projIdS%>&sortby=" + DisplayBugBlog.sortby.value
		+ ck;
}

function sort(name)
{
	location = "proj_summary.jsp?sortby=" + name + "&showBugBlog=" + DisplayBugBlog.showBugBlog.checked + "#bug";
}

//-->
</script>

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
						<td height="30" align="left" valign="bottom" class="head">
							<b>Project Summary</b>
						</td>
						<td width='350'>
						<table width='100%' border='0' cellspacing='0' cellpadding='0'>
						<tr><td width='215'>
<%	if (updateOK) {
		if (browser.equals("Explorer"))
			//Y_POSITION += 4;
%>
						<img src="../i/bullet_tri.gif" width="20" height="10">
						<a class="listlinkbold" href="phase_update.jsp?projId=<%=projIdS%>">Phase Definition</a><br />
						<img src="../i/bullet_tri.gif" width="20" height="10">
						<a class="listlinkbold" href="phase_update2.jsp?projId=<%=projIdS%>">Milestone Schedule</a>
						</td>
						<td width='135'>
						<img src="../i/bullet_tri.gif" width="20" height="10">
						<a class="listlinkbold" href="../plan/timeline.jsp?projId=<%=projIdS%>">Timeline</a><br />
<%	}
	if (!updateOK)
		out.print("</td><td>");
// @AGQ042006
	if (isDirector || updateOK) { %>
						<img src="../i/bullet_tri.gif" width="20" height="10">
						<a class="listlinkbold" href="proj_report.jsp?projId=<%=projIdS%>">Project Report</a>
						</td>
<%	}
%>
						</tr>
						</table>
						</td>
					</tr>
	            </table>
	          </td>
	        </tr>
</table>
	        
<table width='90%' border="0" cellspacing="0" cellpadding="0">
			<tr>
          		<td width="100%">
<!-- Navigation Menu -->
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Project" />
				<jsp:param name="subCat" value="ProjectSummary" />
				<jsp:param name="role" value="<%=iRole%>" />
				<jsp:param name="projId" value="<%=projIdS%>" />
			</jsp:include>
<!-- End of Navigation SUB-Menu -->
				</td>
	        </tr>
		</table>
		<!-- Content Table -->

		 <table width='90%' border="0" cellspacing="0" cellpadding="0">


			<tr><td colspan="2">&nbsp;</td></tr>
			<tr>
				<td width="20"><img src="../i/spacer.gif" width="5" border="0"></td>
				<td>


<!-- /////////////////////////////////////////////////////// -->
<!-- Project Name -->
<table width="100%" border="0" cellpadding="0" cellspacing="0">

<tr>
<form>
	<td class="heading" width="540">
		Project Name&nbsp;&nbsp;
		<select name="projId" class="formtext" onchange="submit()">
<%
		int [] projectObjId = pjMgr.getProjects(pstuser);
		if (projectObjId.length > 0)
		{
			PstAbstractObject [] projectObjList = pjMgr.get(pstuser, projectObjId);
			Util.sortName(projectObjList, true);

			int id;
			project pj;
			Date expDate;
			String expDateS = new String();
			for (int i=0; i < projectObjList.length ; i++)
			{
				// project
				pj = (project) projectObjList[i];
				id = pj.getObjectId();

				out.print("<option value='" + id +"' ");
				if (id == projId)
					out.print("selected");
				out.print(">" + pj.getDisplayName() + "</option>");
			}
		}
%>
		</select>
	</td>

</form>

</tr>

<tr><td colspan='2'><img src="../i/spacer.gif" width="1" height="15" border="0"></td></tr>

</table>


<!-- /////////////////////////////////////////////////////// -->
<!-- SECTION 1: Bar -->

<%
	taskManager tkMgr = taskManager.getInstance();
	planTaskManager ptMgr = planTaskManager.getInstance();
	phaseManager phMgr = phaseManager.getInstance();

	int uid;
	Date lastUpdated = null;
	int [] ids;
	Date adt;
	PhaseInfo [] phaseArr = new PhaseInfo[maxPhases];

	out.println(Util4.showProjectTimeBar(pstuser, projIdS,
			phaseArr,									// will get filled in the call
			sizeFactor, bReverseSizeFactor, updateOK,
			projLength, daysLate, daysElapsed, daysLeft,
			INIT_SPACING, Y_POSITION, false));

	int count = 0;		// the total no. of actual phases
	for (int i=0; i<maxPhases; i++) {
		if (phaseArr[i] == null) break;
		count++;
	}
%>



<!-- /////////////////////////////////////////////////////// -->
<!-- SECTION 2: Phase / Milestone -->

<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
<form name='DisplayPhaseBlog'>
	<td class="plaintext" align="right">
		<input type="checkbox" name="showPhReport"
			<%if (bShowPhReport) out.print(" checked ");%>
			onClick="displayPhaseBlog()">
		Show phase report
	</td>
</form>
</tr>

<tr>
<td>
<%

	String [] label0 = {"&nbsp;Phase / Milestone", "Status", "Orig Start", "Orig Due",
						"Plan Start", "Plan Due", "Actual Start", "Actual Finish"};
	int [] labelLen0 = {-44, 8, 8, 8, 8, 8, 8, 8};
	boolean [] bAlignCenter0 = {false, true, true, true, true, true, true, true};
	out.print(Util.showLabel(label0, labelLen0, bAlignCenter0, true));

	// Phases
	String [] saa;
	String outStr, numS;
	String subphTid=null, subphName=null, subphStart=null, subphPStart=null, subphPDeadln = null,
		subphDeadln=null, subphDone=null, subphStatus=null, subphOriStart=null, subphOriExpire=null;
	String oriExpDtS;
	int dragIdx = 0;
	String bgcolor="";
	boolean even = false;
	Date dt, dt1;

	for (int i=0; i<count; i++)
	{
		if (even)
			bgcolor = Prm.DARK;
		else
			bgcolor = Prm.LIGHT;
		even = !even;

		numS = String.valueOf(i+1);
		
		// check to see if we are late from the perspective of Original Expire Date
		oriExpDtS = phaseArr[i].origExpireDtS;
		if (!StringUtil.isNullOrEmptyString(oriExpDtS) && !oriExpDtS.equals("-")) {
			dt = df1.parse(oriExpDtS);
			s = phaseArr[i].doneDateS;
			if (!StringUtil.isNullOrEmptyString(s) && !s.equals("-")) {
				dt1 = df1.parse(s);		// compare oriExpireDate with actual complete date

				// also see if user beats the schedule
				if (dt1.before(dt)) {
					phaseArr[i].origExpireDtS = "<font color='#00aa00'>" + oriExpDtS + "</font>";
				}
			}
			else
				dt1 = today;			// not done yet: compare with today
			if (dt.before(dt1)) {
				phaseArr[i].origExpireDtS = "<font color='#ee0000'>" + oriExpDtS + "</font>";
			}
		}
		
		outStr = project.displayPhase(bgcolor, numS, phaseArr[i].htmlName,
							phaseArr[i].origStartDtS, phaseArr[i].origExpireDtS,
							phaseArr[i].startDateS, phaseArr[i].expireDateS,
							phaseArr[i].effectiveDateS, phaseArr[i].doneDateS,
							phaseArr[i].status, null);

		out.println(outStr);

		if (bShowPhReport && phaseArr[i].taskId!=null)
		{
			out.print("<tr " + bgcolor + "><td colspan='23' align='center'>");
			outStr = Util.showLastBlog(pstuser, projIdS, phaseArr[i].taskId,
							"Task", BLOG_MIN_HEIGHT, "95%", dragIdx);
			out.println(outStr);
%>
<script language="JavaScript">
			beginHeight=50;
			initDrag(beginHeight, <%=dragIdx%>);
			new dragObject(handleBottom[<%=dragIdx%>], null, new Position(0, beginHeight),
							new Position(0, 1000), null, BottomMove, null, false, <%=dragIdx++%>);
</script>
<%
			out.print("</td></tr>");
		}

		// show subphases
		result blog;
		PstAbstractObject [] objArr;
		phase ph;
		PstAbstractObject tk, ptk;

		if (phaseArr[i].phaseId != null)
		{
			objArr = phMgr.getSubPhases(pstuser, phaseArr[i].phaseId);
			for (int m=0; m<objArr.length; m++)
			{
				subphName = subphStart = subphPDeadln = subphDeadln = subphDone = subphStatus = "";
				ph = (phase) objArr[m];
				Object obj = ph.getAttribute(phase.TASKID)[0];
				if (obj != null)
				{
					// use task to fill the phase info
					subphTid = obj.toString();
					try
					{
						tk = tkMgr.get(pstuser, subphTid);
						ptk = ((task)tk).getPlanTask(pstuser);

						obj = ph.getAttribute(phase.NAME)[0];
						if (obj == null)
							s = (String)ptk.getAttribute("Name")[0];
						else
							s = obj.toString();
						subphName = "<a class='listlink' href='../blog/blog_task.jsp?projId=" + projIdS
							+ "&planTaskId=" + ptk.getObjectId() + "'>" + s + "</a>";

						dt = (Date)tk.getAttribute("OriginalStartDate")[0];
						subphOriStart = phase.parseDateToString(dt, format);

						dt = (Date)tk.getAttribute("OriginalExpireDate")[0];
						subphOriExpire = phase.parseDateToString(dt, format);
						if (dt != null) {
							dt1 = (Date) tk.getAttribute("CompleteDate")[0];
							if (dt1 != null) {
								// also see if user beats the schedule
								if (dt1.before(dt)) {
									subphOriExpire= "<font color='#00aa00'>" + subphOriExpire + "</font>";
								}
							}
							else
								dt1 = today;
							if (dt.before(dt1)) {
								subphOriExpire = "<font color='#ee0000'>" + subphOriExpire + "</font>";
							}
						}

						dt = (Date)tk.getAttribute("StartDate")[0];
						subphPStart = phase.parseDateToString(dt, format);

						dt = (Date)tk.getAttribute("ExpireDate")[0];
						subphPDeadln = phase.parseDateToString(dt, format);
						
						//dt = (Date)tk.getAttribute(phase.PLANEXPIREDATE)[0];
						//subphPDeadln = phase.parseDateToString(dt, format);
						
						dt = (Date)tk.getAttribute("EffectiveDate")[0];
						subphStart = phase.parseDateToString(dt, format);

						dt = (Date)tk.getAttribute("CompleteDate")[0];
						subphDone = phase.parseDateToString(dt, format);

						s = (String)tk.getAttribute("Status")[0];
						if (s.equals(task.ST_NEW)) s = project.PH_NEW;
						else if (s.equals(task.ST_OPEN) || s.equals(task.ST_ONHOLD)) s = project.PH_START;
						subphStatus = s;
					}
					catch (PmpException e){subphName = "*** Invalid task ID";}
				}
				
				else
				{
					// the case where the SubPhase is not a task
					// ECC: we should obsolete this case
					subphName	= "<span class='tinytype'>" + ph.getAttribute(phase.NAME)[0] + "</span>";

					subphOriExpire = subphOriStart = "-";
					
					dt = (Date)ph.getAttribute(phase.STARTDATE)[0];			// StartDate
					subphStart = phase.parseDateToString(dt, format);

					dt = (Date)ph.getAttribute(phase.PLANEXPIREDATE)[0];
					subphPDeadln = phase.parseDateToString(dt, format);

					dt = (Date)ph.getAttribute(phase.EXPIREDATE)[0];		// ExpireDate
					subphDeadln = phase.parseDateToString(dt, format);

					dt = (Date)ph.getAttribute(phase.COMPLETEDATE)[0];
					subphDone = phase.parseDateToString(dt, format);

					subphStatus = ph.getAttribute(phase.STATUS)[0].toString();
					subphTid	= null;
				}

				if (even)
					bgcolor = Prm.DARK;
				else
					bgcolor = Prm.LIGHT;
				even = !even;

				numS = (i+1) + "." + (m+1);

				outStr = project.displayPhase(bgcolor, numS, subphName,
							subphOriStart, subphOriExpire, subphPStart, subphPDeadln,
							subphStart, subphDone, subphStatus, null);
				out.println(outStr);

				if (bShowPhReport && subphTid!=null)
				{
					out.print("<tr " + bgcolor +"><td colspan='23' align='center'>");
					outStr = Util.showLastBlog(pstuser, projIdS, subphTid,
									"Task", BLOG_MIN_HEIGHT, "95%", dragIdx);
					out.println(outStr);
%>
<script language="JavaScript">
			beginHeight=50;
			initDrag(beginHeight, <%=dragIdx%>);
			new dragObject(handleBottom[<%=dragIdx%>], null, new Position(0, beginHeight),
							new Position(0, 1000), null, BottomMove, null, false, <%=dragIdx++%>);
</script>
<%
					out.print("</td></tr>");
				}
			}
		}
	}	// for each phase

	out.println("</table>");

%>

		</td>
		</tr>
	</table>
<!-- END PROJ PLAN -->

<table>
	<tr>
<%	if (count > 0)
	{%>
		<td width="10">&nbsp;</td>
		<td class="tinytype" align="center">Task Status:
			&nbsp;&nbsp;<img src="../i/dot_green.gif" border="0">Completed
			&nbsp;&nbsp;<img src="../i/dot_lightblue.gif" border="0">Open/Started
			&nbsp;&nbsp;<img src="../i/dot_orange.gif" border="0">High Risk
			&nbsp;&nbsp;<img src="../i/dot_red.gif" border="0">Late
			&nbsp;&nbsp;<img src="../i/dot_white.gif" border="0">Not Started
		</td>
<%	}
	else
	{%>
		<td class="plaintext_grey">&nbsp;&nbsp;No phase / milestone defined</td>
<%	}%>

	</tr>
</table>


<!-- /////////////////////////////////////////////////////// -->
<!-- SECTION 3: Executive Summary -->

<table width="100%" border="0" cellpadding="0" cellspacing="0">
	<tr><td colspan="2"><img src="../i/spacer.gif" width="1" height="20" border="0"></td></tr>
	<tr>
	<td class="heading">
		Executive Summary
	</td>

	<td></td>
	</tr>

<%
	// display the latest summary blog if it is specified
	boolean found = false;

	//s = (String)projObj.getAttribute("Option")[0];
	s = projObj.getOption(project.EXEC_SUMMARY);
	if (s != null)
	{
		// SUMMARY_ID:12345
		// the summary id is actually the TaskId
		out.print("<tr><td colspan='2' align='center'>");
		outStr = Util.showLastBlog(pstuser, projIdS, s, "Task", "100px", "95%", dragIdx);
		if (outStr.length() > 0)
		{
			out.print(outStr);
			found = true;
%>
<script language="JavaScript">
			setCookieName(winCookieName);	
			if (divHeight == null) divHeight = 100;	
			beginHeight = divHeight;
			initDrag(divHeight, <%=dragIdx%>);			
			new dragObject(handleBottom[<%=dragIdx%>], null, new Position(0, 100),
							new Position(0, 1000), null, BottomMove, null, false, <%=dragIdx++%>);
</script>
<%
		}
		out.print("</td></tr>");
	}

%>
</table>
<%	if (!found)
	{%>
		<table><tr><td class="plaintext_grey">&nbsp;&nbsp;No executive summary</td></tr></table>
<%	}%>


<!-- /////////////////////////////////////////////////////// -->
<!-- SECTION 4: Project Review -->
<%
	// task statistics
	ids = tkMgr.findId(pstuser, "ProjectID='"+projIdS+"'");
	int totalTasks = ids.length;
	ids = tkMgr.findId(pstuser, "ProjectID='"+projIdS+"' && Status='New'");
	int newct=ids.length;
	ids = tkMgr.findId(pstuser, "ProjectID='"+projIdS+"' && Status='Open'");
	int open=ids.length;
	ids = tkMgr.findId(pstuser, "ProjectID='"+projIdS+"' && Status='Completed'");
	int completed=ids.length;
	ids = tkMgr.findId(pstuser, "ProjectID='"+projIdS+"' && Status='Late'");
	int late=ids.length;
	ids = tkMgr.findId(pstuser, "ProjectID='"+projIdS+"' && Status='On-hold'");
	int onhold=ids.length;
	ids = tkMgr.findId(pstuser, "ProjectID='"+projIdS+"' && Status='Canceled'");
	int canceled=ids.length;
%>
<!-- Start Project Review -->
<table width="100%" cellpadding="0" cellspacing="0">
	<tr><td colspan="2"><img src="../i/spacer.gif" width="1" height="20" border="0"></td></tr>
	<tr>
	<td class="heading">
		Project Status
	</td>
	</tr>

	<tr>
		<td valign="top">

<!-- LEFT SIDE: PROJ OVERALL REVIEW -->
<table width="350">
	<tr><td colspan="3"><img src="../i/spacer.gif" width="1" height="5" border="0"></td></tr>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext"><b>Coordinator:</b></td>
		<td class="plaintext"><%=uname%></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext"><b>Start Date:</b></td>
		<td class="plaintext"><%=startDate%></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext"><b>Expiration Date:</b></td>
<%
		if (projObj.isContainer()) {
			deadline = "-";
		}
%>
		<td class="plaintext"><%=deadline%></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext"><b>Completion Date:</b></td>
		<td class="plaintext"><%=completeDate%></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext"><b>Project Length:</b></td>
		<td class="plaintext"><%=projLength%> Days</td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext"><b>Days Elapsed:</b></td>
		<td class="plaintext"><%=daysElapsed%> Days</td>
	</tr>

<% if (daysLate <= 0) {%>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext"><b>Days Left:</b></td>
		<td class="plaintext"><%=daysLeft%> Days</td>
	</tr>
<% } else {%>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext"><b>Days Late:</b></td>
		<td class="plaintext"><font color="#cc3300"><%=daysLate%> Days</font></td>
	</tr>
<% }%>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext"><b>Last Updated:</b></td>
		<td class="plaintext"><%=df1.format((Date)projObj.getAttribute("LastUpdatedDate")[0])%></td>
	</tr>

</table>
		</td>


<!-- RIGHT SIDE: TASK STAT -->
		<td valign="top" align="left">
<table width="280">
	<tr><td width="15">&nbsp;</td>
		<td class="plaintext"><b>Task Statistics:</b></td>
	</tr>
	<tr><td width="15">&nbsp;</td>
		<td>
		<table border cellpadding="5" cellspacing="0">
			<tr>
			<td bgcolor="#eeeeee" class="plaintext" width="50">New</td>
			<td class="plaintext" align="center" width="50"><%=newct%></td>
			<td class="plaintext" align="center" width="50"><%=newct*100/totalTasks%>%</td>
			</tr>
			<tr>
			<td bgcolor="#eeeeee" class="plaintext" width="50">Open</td>
			<td class="plaintext" align="center" width="50"><%=open%></td>
			<td class="plaintext" align="center" width="50"><%=open*100/totalTasks%>%</td>
			</tr>
			<tr>
			<td bgcolor="#eeeeee" class="plaintext" width="50">Completed</td>
			<td class="plaintext" align="center" width="50"><%=completed%></td>
			<td class="plaintext" align="center" width="50"><%=completed*100/totalTasks%>%</td>
			</tr>
			<tr>
			<td bgcolor="#eeeeee" class="plaintext" width="50">Late</td>
			<td class="plaintext" align="center" width="50"><%=late%></td>
			<td class="plaintext" align="center" width="50"><%=late*100/totalTasks%>%</td>
			</tr>
			<tr>
			<td bgcolor="#eeeeee" class="plaintext" width="50">On-hold</td>
			<td class="plaintext" align="center" width="50"><%=onhold%></td>
			<td class="plaintext" align="center" width="50"><%=onhold*100/totalTasks%>%</td>
			</tr>
			<tr>
			<td bgcolor="#eeeeee" class="plaintext" width="50">Canceled</td>
			<td class="plaintext" align="center" width="50"><%=canceled%></td>
			<td class="plaintext" align="center" width="50"><%=canceled*100/totalTasks%>%</td>
			</tr>
		</table>
	<tr><td width="15">&nbsp;</td>
		<td class="plaintext">&nbsp;Total no. of tasks: <%=totalTasks%></td>
	</tr>
	</td></tr>
</table>
	</td>
</tr>

</table>
<!-- End Project Review -->


<!-- /////////////////////////////////////////////////////// -->
<!-- SECTION 5: Bug Listing -->
<a name="bug"></a>
<table width="100%" border="0" cellpadding="0" cellspacing="0">
	<tr><td colspan="2"><img src="../i/spacer.gif" width="1" height="20" border="0"></td></tr>
	<tr>
	<td class="heading" width="600">
		Issue / Bug List
	</td>

<form name="DisplayBugBlog">
<input type="hidden" name="sortby" value="<%=sortby%>">

	<td class="plaintext" align="right">
		<input type="checkbox" name="showBugBlog" <%if (bShowBugBlog) out.print("checked");%>
			onClick="displayBugBlog()">&nbsp;Show bug blog
	</td>
</form>
	</tr>
</table>


<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
<td>
	<table width="100%" border='0' cellpadding="0" cellspacing="0">
	<tr>
	<td bgcolor="#EBECED" height="3"><img src="../i/spacer.gif" width="1" height="3" border="0"></td>
	</tr>
	</table>
	<table width="100%" border="0" cellspacing="0" cellpadding="0">
	<tr>
	<td colspan="38" height="2" bgcolor="#336699"><img src="../i/spacer.gif" width="2" height="2"></td>
	</tr>
	<tr>
<%	if (sortby==null)
	{
		out.print("<td width='4' " + srcl + " class='10ptype'>&nbsp;</td>");
		out.print("<td width='38' " + srcl + " class='td_header'><strong>&nbsp;PR #</strong></td>");
	}
	else
	{
		out.print("<td width='4' " + bgcl + ">&nbsp;</td>");
		out.print("<td class='td_header' " + bgcl + "><a href='javascript:sort(\"\")'><font color='ffffff'><strong>&nbsp;PR #</strong></font></a>");
	}
%>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
<%	if (sortby!=null && sortby.equals("st"))
	{
		out.print("<td width='4' " + srcl + ">&nbsp;</td>");
		out.print("<td width='15' class='td_header' " + srcl + "><strong>St.</strong>");
	}
	else
	{
		out.print("<td width='4' " + bgcl + ">&nbsp;</td>");
		out.print("<td width='15' class='td_header' " + bgcl + "><a href='javascript:sort(\"st\")'><font color='ffffff'><strong>St.</strong></font></a>");
	}
%>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td bgcolor="#6699cc" class="td_header" align="left"><strong>Synopsis</strong></td>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
<%	if (sortby!=null && sortby.equals("su"))
	{
		out.print("<td width='4' " + srcl + ">&nbsp;</td>");
		out.print("<td width='43' class='td_header' " + srcl + "><strong>Submit</strong>");
	}
	else
	{
		out.print("<td width='4' " + bgcl + ">&nbsp;</td>");
		out.print("<td width='43' class='td_header' " + bgcl + "><a href='javascript:sort(\"su\")'><font color='ffffff'><strong>Submit</strong></font></a>");
	}

// @ECC040506 support multiple owners
for (int i=0; i<numOfOwner; i++)
{
	out.print("<td width='2' bgcolor='#FFFFFF' class='10ptype'><img src='../i/spacer.gif' width='2' height='2'></td>");
	if (sortby!=null && sortby.equals("ow" + i))
	{
		out.print("<td width='4' " + srcl + ">&nbsp;</td>");
		out.print("<td width='43' class='td_header' align='center' " + srcl + "><strong>" + ownerLabel[i].trim() + " Owner</strong>");
	}
	else
	{
		out.print("<td width='4' " + bgcl + ">&nbsp;</td>");
		out.print("<td width='43' class='td_header' align='center' " + bgcl + "><a href='javascript:sort(\"ow" + i + "\")'><font color='ffffff'><strong>" + ownerLabel[i].trim() + " Owner</strong></font></a></td>");
	}
}
%>


	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="34" bgcolor="#6699cc" class="td_header" align="center"><strong>Proj ID</strong></td>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="34" bgcolor="#6699cc" class="td_header" align="center"><strong>Task ID</strong></td>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="48" bgcolor="#6699cc" class="td_header" align="center"><strong>Category</strong></td>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
<%	if (sortby!=null && sortby.equals("ty"))
	{
		out.print("<td width='4' " + srcl + ">&nbsp;</td>");
		out.print("<td width='38' class='td_header' align='center' " + srcl + "><strong>Type</strong>");
	}
	else
	{
		out.print("<td width='4' " + bgcl + ">&nbsp;</td>");
		out.print("<td width='38' class='td_header' align='center' " + bgcl + "><a href='javascript:sort(\"ty\")'><font color='ffffff'><strong>Type</strong></font></a>");
	}
%>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
<%	if (sortby!=null && sortby.equals("pr"))
	{
		out.print("<td width='4' " + srcl + ">&nbsp;</td>");
		out.print("<td width='22' class='td_header' align='center' " + srcl + "><strong>Pri</strong>");
	}
	else
	{
		out.print("<td width='4' " + bgcl + ">&nbsp;</td>");
		out.print("<td width='22' class='td_header' align='center' " + bgcl + "><a href='javascript:sort(\"pr\")'><font color='ffffff'><strong>Pri</strong></font></a>");
	}
%>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
<%	if (sortby!=null && sortby.equals("sv"))
	{
		out.print("<td width='4' " + srcl + ">&nbsp;</td>");
		out.print("<td width='18' class='td_header' align='center' " + srcl + "><strong>Sev</strong>");
	}
	else
	{
		out.print("<td width='4' " + bgcl + ">&nbsp;</td>");
		out.print("<td width='18' class='td_header' align='center' " + bgcl + "><a href='javascript:sort(\"sv\")'><font color='ffffff'><strong>Sev</strong></font></a>");
	}
%>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
<%	if (sortby!=null && sortby.equals("up"))
	{
		out.print("<td width='4' " + srcl + ">&nbsp;</td>");
		out.print("<td width='35' class='td_header' align='center' " + srcl + "><strong>Last Updated</strong>");
	}
	else
	{
		out.print("<td width='4' " + bgcl + ">&nbsp;</td>");
		out.print("<td width='35 class='td_header' align='center' " + bgcl + "><a href='javascript:sort(\"up\")'><font color='ffffff'><strong>Last Updated</strong></font></a>");
	}
%>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="30"bgcolor="#6699cc" class="td_header" align="center"><strong>Silicon Revision</strong></td>
	</tr>

<!-- list of bugs -->
<%

try {
	bgcolor="";
	even = false;
	int bugId;
	user empObj = null, subObj;
	String [] ownerIdS = new String[numOfOwner];

	String status, synopsis, submitter, projectID, taskID, type, priority, severity, release, category;
	Date lastUpdate;
	String dot;

	for(int i = bugObjList.length-1; i >= 0; i--)
	{	// a list of bugs satisfied the search expr
		bug bugObj = (bug)bugObjList[i];
		if (bugObj == null) continue;

		bugId = bugObj.getObjectId();

		status		= (String)bugObj.getAttribute("State")[0];
		synopsis	= (String)bugObj.getAttribute("Synopsis")[0];
		submitter	= (String)bugObj.getAttribute("Creator")[0];
		projectID	= (String)bugObj.getAttribute("ProjectID")[0];
		taskID		= (String)bugObj.getAttribute("TaskID")[0];
		type		= (String)bugObj.getAttribute("Type")[0];
		priority	= (String)bugObj.getAttribute("Priority")[0];
		severity	= (String)bugObj.getAttribute("Severity")[0];
		lastUpdate	= (Date)bugObj.getAttribute("LastUpdatedDate")[0];
		release		= (String)bugObj.getAttribute("Release")[0];
		category	= (String)bugObj.getAttribute("Category")[0];
		for (int j=0; j<numOfOwner; j++)
			ownerIdS[j] = (String)bugObj.getAttribute(ownerAttr[j])[0];	// @ECC040506

		if (even)
			bgcolor = Prm.DARK;
		else
			bgcolor = Prm.LIGHT;
		even = !even;

		// PR Number
		out.print("<tr " + bgcolor + ">");
		out.print("<td colspan='2' class='listtext' valign='top'>&nbsp;");
		out.print("<a class='listlink' href='../bug/bug_update.jsp?bugId=" + bugId + "'>");
		out.print(bugId + "</a>");
		out.println("</td>");

		// status
		dot = "../i/";
		if (status.equals(bug.OPEN)) {dot += "dot_orange.gif";}
		else if (status.equals(bug.ACTIVE)) {dot += "dot_red.gif";}
		else if (status.equals(bug.ANALYZED)) {dot += "dot_lightblue.gif";}
		else if (status.equals(bug.FEEDBACK)) {dot += "dot_green.gif";}
		else if (status.equals(bug.CLOSE)) {dot += "dot_black.gif";}
		else {dot += "dot_grey.gif";}
		out.print("<td colspan='3' class='plaintext' align='center' valign='top'>");
		out.print("<img src='" + dot + "' alt='" + status + "'>");
		out.println("</td>");

		// synopsis
		out.print("<td></td>");
		out.print("<td colspan='2' class='plaintext' valign='top'><table border='0' cellspacing='0' cellpadding='0'>");
		out.print("<tr><td><img src='../i/spacer.gif' width='4' height='2'></td>");
		out.print("<td class='plaintext' valign='top'>");
		out.print(synopsis);
		out.println("</td></tr></table></td>");

		// submitter
		// ECC: need to optimize this in the near future
		out.print("<td colspan='3' class='listtext' align='center' valign='top'>");
		subObj = (user)uMgr.get(pstuser,Integer.parseInt(submitter));
		out.print("<a class='listlink' href='../ep/ep1.jsp?uid=" + subObj.getObjectId() + "'>");
		out.print((String)subObj.getAttribute("FirstName")[0]);
		out.print("</a>");
		out.println("</td>");

		// owner
		for (int j=0; j<numOfOwner; j++)
		{
			out.print("<td colspan='3' class='listtext' width='50' align='center' valign='top'>");
			if (ownerIdS[j] != null)
			{
				// ECC: need to optimize this in the near future
				empObj = (user)uMgr.get(pstuser,Integer.parseInt(ownerIdS[j]));
				uid = empObj.getObjectId();
				out.print("<a class='listlink' href='../ep/ep1.jsp?uid=" + uid + "'>");
				out.print((String)empObj.getAttribute("FirstName")[0]);
				out.print("</a>");
			}
			else
				out.print("-");
			out.println("</td>");
		}

		// project ID
		out.print("<td colspan='3' class='listtext' align='center' valign='top'>");
		if (projectID == null)
			out.print("-");
		else
		{
			out.print("<a class='listlink' href='../project/proj_plan.jsp?projId=" + projectID + "'>");
			out.print(projectID + "</a>");
		}
		out.println("</td>");

		// task ID
		out.print("<td colspan='3' class='listtext' align='center' valign='top'>");
		if (taskID == null)
			out.print("-");
		else
		{
			out.print("<a class='listlink' href='../project/task_update.jsp?projId=" + projectID + "&taskId=" + taskID + "'>");
			out.print(taskID);
			out.print("</a>");
		}
		out.println("</td>");

		// category
		out.print("<td width='2'></td>");
		out.print("<td width='4'></td>");
		out.print("<td class='listtext_small' valign='top'>");
		out.print(category==null?"-":category);
		out.println("</td>");

		// type
		out.print("<td width='2''></td>");
		out.print("<td width='4'></td>");
		out.print("<td class='listtext_small' align='center' valign='top'>");
		out.print(type);
		out.println("</td>");

		// priority {HIGH, MEDIUM, LOW}
		out.print("<td colspan='3' class='listtext' align='center' valign='top'>");
		if (priority.startsWith(bug.PRI_HIGH))
		{
			out.print("<font color=" + action.COLOR_HIGH + "><b>H");
			if (priority.length()>bug.PRI_HIGH.length())
			{
				out.print("-");
				out.print(Integer.parseInt(priority.substring(bug.PRI_HIGH.length())));
			}
			out.print("</b>");
		}
		else if (priority.equals(bug.PRI_MED)) out.print("<font color=" + action.COLOR_MED + "><b>M</b>");
		else out.print("<font color=" + action.COLOR_LOW + "><b>L</b>");
		out.print("</font>");
		out.println("</td>");

		// severity
		out.print("<td colspan='3' class='listtext' align='center' valign='top'>");
		if (severity == null)
			out.print("-");
		else
		{
			if (severity.equals(bug.SEV_CRI)) out.print("<font color=" + action.COLOR_HIGH + "><b>C</b>");
			else if (severity.equals(bug.SEV_SER)) out.print("<font color=" + action.COLOR_MED + "><b>S</b>");
			else out.print("<font color=" + action.COLOR_LOW + "><b>NC</b>");
			out.print("</font>");
		}
		out.println("</td>");

		// last updated date
		out.print("<td colspan='3' class='listtext_small' align='center' valign='top'>");
		if (lastUpdate != null)
			out.print(df1.format(lastUpdate));
		else
			out.print("-");
		out.println("</td>");

		// release
		if (release == null) release = "-";
		out.print("<td colspan='3' class='listtext_small' align='center' valign='top'>");
		out.print(release);
		out.print("</td>");

		out.print("</tr>");
		out.print("<tr " + bgcolor + ">" + "<td colspan='38'><img src='../i/spacer.gif' width='2' height='2'></td></tr>");

		// @ECC090605 display blog
		if (bShowBugBlog)
		{
			outStr = Util.showLastBlog(pstuser, projIdS, String.valueOf(bugId),
								"Bug", BLOG_MIN_HEIGHT, null, dragIdx);

			if (outStr.length() > 0)
			{
				out.print("<tr " + bgcolor + ">");
				out.print("<td colspan='38' align='center'>");
				out.println(outStr);
%>
<script language="JavaScript">
			beginHeight=50;
			initDrag(beginHeight, <%=dragIdx%>);
			new dragObject(handleBottom[<%=dragIdx%>], null, new Position(0, beginHeight),
							new Position(0, 1000), null, BottomMove, null, false, <%=dragIdx++%>);
</script>
<%
				out.print("</td></tr>");
				out.print("<tr " + bgcolor + ">" + "<td colspan='38'><img src='../i/spacer.gif' width='2' height='15'></td></tr>");
			}
			else
				out.print("<tr " + bgcolor + ">" + "<td colspan='38'><img src='../i/spacer.gif' width='2' height='5'></td></tr>");
		}
	}

} catch (Exception e)
{
	response.sendRedirect("../out.jsp?msg=Internal error in displaying bug list.  Please contact administrator.");
	return;
}
%>
	</table>

		</td>
		</tr>
		<tr><td colspan="2"><img src="../i/spacer.gif" width="1" height="5" border="0"></td></tr>
	</table>


<table>
	<tr>
		<td width='40' class="tinytype">Status:</td>
		<td class="tinytype">&nbsp;<img src="../i/dot_orange.gif" border="0"><%=bug.OPEN%></td>
		<td class="tinytype">&nbsp;<img src="../i/dot_red.gif" border="0"><%=bug.ACTIVE%></td>
		<td class="tinytype">&nbsp;<img src="../i/dot_lightblue.gif" border="0"><%=bug.ANALYZED%></td>
		<td class="tinytype">&nbsp;<img src="../i/dot_green.gif" border="0"><%=bug.FEEDBACK%></td>
		<td class="tinytype">&nbsp;<img src="../i/dot_black.gif" border="0"><%=bug.CLOSE%></td>
	</tr>
	<tr>
		<td width='40' class="tinytype">Priority:</td>
		<td class="tinytype">&nbsp;&nbsp;<font color=<%=action.COLOR_HIGH%>><b>H</b></font> = High</td>
		<td class="tinytype">&nbsp;&nbsp;<font color=<%=action.COLOR_MED%>><b>M</b></font> = Medium</td>
		<td class="tinytype">&nbsp;&nbsp;<font color=<%=action.COLOR_LOW%>><b>L</b></font> = Low</td>
		<td></td>
		<td></td>
	</tr>
	<tr>
		<td width='40' class="tinytype">Severity:</td>
		<td class="tinytype">&nbsp;&nbsp;<font color=<%=action.COLOR_HIGH%>><b>C</b></font> = Critical</td>
		<td class="tinytype">&nbsp;&nbsp;<font color=<%=action.COLOR_MED%>><b>S</b></font> = Serious</td>
		<td class="tinytype">&nbsp;&nbsp;<font color=<%=action.COLOR_LOW%>><b>NC</b></font> = Non-Critical</td>
		<td></td>
		<td></td>
	</tr>
</table>
<!-- END BUG LISTING -->


<!-- /////////////////////////////////////////////////////// -->
<!-- SECTION 6: Decision Record -->

<table width="100%" border="0" cellpadding="0" cellspacing="0">
	<tr><td colspan="2"><img src="../i/spacer.gif" width="1" height="20" border="0"></td></tr>
	<tr>
	<td class="heading">
		Decision Record <span class="plaintext_grey">(most recently filed)</span>
	</td>
	<td align='right'><a class='listlink' href='proj_action.jsp?projId=<%=projIdS%>'>>> all actions / decisions</a></td>
	</tr>
</table>

<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td>&nbsp;</td>
	<td colspan="2">
		<table width="100%" border='0' cellpadding="0" cellspacing="0">
		<tr>
		<td bgcolor="#EBECED" height="3"><img src="../i/spacer.gif" width="1" height="3" border="0"></td>
		</tr>
		</table>

		<table width="100%" border="0" cellspacing="0" cellpadding="0">
		<tr>
		<td colspan="14" height="2" bgcolor="#336699"><img src="../i/spacer.gif" width="2" height="2"></td>
		</tr>

		<tr>
		<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td bgcolor="#6699cc" class="td_header"><strong>&nbsp;Decision Record</strong></td>

		<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
		<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td width="18" bgcolor="#6699cc" class="td_header"><strong>Pri.</strong></td>

		<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
		<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td width="40" bgcolor="#6699cc" class="td_header" align='center'><strong>Mtg ID</strong></td>

		<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
		<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td width="40" bgcolor="#6699cc" class="td_header" align='center'><strong>Issue</strong></td>

		<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
		<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td width="50" bgcolor="#6699cc" class="td_header" align='center'><strong>Filed On</strong></td>

		</tr>

<%
	actionManager aMgr = actionManager.getInstance();
	s = "(ProjectID='" + projIdS + "') && (Type='" + action.TYPE_DECISION + "')";
	ids = aMgr.findId(pstuser, s);
	Arrays.sort(ids);
	PstAbstractObject [] dsObjList = aMgr.get(pstuser, ids);
	String subject, priority, midS, bugIdS;
	Date createdDate;
	int aid;
	String dot;

	even = false;

	count = 1;
	int len = dsObjList.length-1;
	for (int i=len; i >= 0; i--)
	{	// the list of decision records for this meeting object
		if (count > MAX_DECISION) break;
		action obj = (action)dsObjList[i];
		aid = obj.getObjectId();

		subject		= (String)obj.getAttribute("Subject")[0];
		priority	= (String)obj.getAttribute("Priority")[0];
		createdDate	= (Date)obj.getAttribute("CreatedDate")[0];
		midS		= (String)obj.getAttribute("MeetingID")[0];
		bugIdS		= (String)obj.getAttribute("BugID")[0];

		if (even)
			bgcolor = Prm.DARK;
		else
			bgcolor = Prm.LIGHT;
		even = !even;
		out.print("<tr " + bgcolor + ">");

		// Subject
		out.print("<td>&nbsp;</td>");
		out.print("<td valign='top'><table border='0'><tr>");
		out.print("<td class='plaintext' valign='top' width='20'>" + count++ + ".</td>");
		out.print("<td class='plaintext' valign='top'>");
		out.print(subject);
		out.println("</td></tr></table></td>");

		// Priority {HIGH, MEDIUM, LOW}
		dot = "../i/";
		if (priority.equals(action.PRI_HIGH)) {dot += "dot_red.gif";}
		else if (priority.equals(action.PRI_MED)) {dot += "dot_orange.gif";}
		else if (priority.equals(action.PRI_LOW)) {dot += "dot_yellow.gif";}
		else {dot += "dot_grey.gif";}
		out.print("<td colspan='3' class='listlink' align='center' valign='top'>");
		out.print("<img src='" + dot + "' alt='" + priority + "'>");
		out.println("</td>");

		// Meeting id
		out.print("<td colspan='2'>&nbsp;</td>");
		out.print("<td class='listtext' width='40' valign='top' align='center'>");
		if (midS != null)
		{
			out.print("<a class='listlink' href='../meeting/mtg_view.jsp?mid=" + midS + "&aid=" + aid + "#action'>");
			out.print(midS + "</a>");
		}
		else
			out.print("-");
		out.println("</td>");

		// Bug id
		out.print("<td colspan='2'>&nbsp;</td>");
		out.print("<td class='listtext' width='40' valign='top' align='center'>");
		if (bugIdS != null)
		{
			out.print("<a class='listlink' href='../bug/bug_update.jsp?bugId=" + bugIdS + "'>");
			out.print(bugIdS + "</a>");
		}
		else
			out.print("-");
		out.println("</td>");

		// CreatedDate
		out.print("<td colspan='2'>&nbsp;</td>");
		out.print("<td class='listtext_small' width='50' align='center' valign='top'>");
		out.print(df1.format(createdDate));
		out.println("</td>");

		out.println("</tr>");
		out.println("<tr " + bgcolor + ">" + "<td colspan='14'><img src='../i/spacer.gif' width='2' height='2'></td></tr>");
	}

%>
		</table>
	</td>
</tr>

</table>
<table>
	<tr><td colspan="4"><img src="../i/spacer.gif" width="1" height="5" border="0"></td></tr>
	<tr>
		<td class="tinytype">Priority:
		<td class="tinytype">&nbsp;<img src="../i/dot_red.gif" border="0"><%=action.PRI_HIGH%></td>
		<td class="tinytype">&nbsp;<img src="../i/dot_orange.gif" border="0"><%=action.PRI_MED%></td>
		<td class="tinytype">&nbsp;<img src="../i/dot_yellow.gif" border="0"><%=action.PRI_LOW%></td>
	</tr>
</table>
<!-- End list of decision records -->



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
