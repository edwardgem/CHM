<%@ page contentType="text/html; charset=utf-8"%>


<%
////////////////////////////////////////////////////
//	Copyright (c) 2010, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	timeline.jsp
//	Author:	ECC
//	Date:	02/12/10
//	Description:
//		Use drag action to update task timeline including StartDate and ExpireDate.
//
//	Modification:
//	TODO:
//			- firefox is not working right when moving dots.
//			- future optimization for very large plan: a thread can be responsible to construct the
//				sBuf's for displaying the tasks/bars.  When it finishes constructing, say, 10 tasks
//				the sBufs can be saved in the session object.  In this JSP we grab from the
//				session these sBufs to display.  We may update the innerHTML of the scroll DIV
//				to display the latest sBufs.
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.codegen.project.Path" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>
<%@ page import = "org.apache.log4j.Logger" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%!
	final int DEFAULT_SIZE_FACTOR = 5;
	int SIZE_FACTOR = DEFAULT_SIZE_FACTOR;
	final int LEADING_GAP = 20;				// a gap before the bar starts
	final int BAR_HEADER_HEIGHT = 18;		// must agree with x.css
	final int MIN_TABLE_WIDTH = 600;
	final int MIN_DISP_DATES_LENGTH = 30;	// min bar length to display two dates
	final String MSG_ZOOM_NODRAG =
		"Note: you cannot use mouse drag to change the schedule when you are zoom in.";

	private Date _projStartDt = null;
	private HashMap<String, BarDim> _barMap = new HashMap<String, BarDim> (100);
	private ArrayList<Path> _depPaths = new ArrayList<Path>();

	private Locale usLocale = new Locale.Builder().setLanguage("en").setRegion("US").build();

	// date format
	String df2S = "M/dd/yyyy";		// also used by Javascript
	SimpleDateFormat df1 = new java.text.SimpleDateFormat("M/dd", usLocale);
	SimpleDateFormat df2 = new java.text.SimpleDateFormat(df2S, usLocale);

	private class BarDim
	{
		public int _head;
		public int _tail;
		public int _yPos;

		public BarDim(int h, int t, int y)
		{
			_head = h;
			_tail = t;
			_yPos = y;
		}
	}

	/**
	   set the month partition lines and the month headings
	*/
	private void setMonthGrid(StringBuffer buf, int lineHeight, int gridWidth)
	{
		
		// skip the initial gap
		int x = LEADING_GAP;

		// draw line for start of project
		buf.append("<div class='monthLine' style='left:" + x + "px; top:" + BAR_HEADER_HEIGHT
				+ "px; height:" + lineHeight + "; background-color: #ffaa33;'></div>");

		// draw first month line (remaining of project) if it is more than 15 days
		Calendar cal1 = Calendar.getInstance(usLocale);
		cal1.setTime(_projStartDt);
		cal1.add(Calendar.MONTH, 1);
		cal1.set(Calendar.DAY_OF_MONTH, 1);
		int dist = getDateDistance(_projStartDt, cal1.getTime());
		x += dist;
		if (dist >= 20)
		{
			buf.append("<div class='monthLine' style='left:" + x + "px; height:" + lineHeight + ";'></div>");
		}

		// loop through all remaining month lines and write month labels
		// month labels need to be on top so that it is outside of the overall DIV to be position absolute
		Date dt;
		String monthName;
		String [] monthNames = DateFormatSymbols.getInstance(usLocale).getShortMonths();
		while (x < gridWidth)
		{
			dt = cal1.getTime();
			monthName = monthNames[cal1.get(Calendar.MONTH)] + cal1.get(Calendar.YEAR);
			cal1.add(Calendar.MONTH, 1);
			dist = getDateDistance(dt, cal1.getTime());
			x += dist;
			buf.append("<div class='monthLine' style='left:" + x + "px; height:" + lineHeight + ";'></div>");
			if (x < gridWidth) {
				buf.append("<div class='barHdText' style='left:" + (x - dist/2 -25) + ";'>" + monthName + "</div>");
			}
		}

		// draw one more line for today
		Date today = new Date();
		try {today = df2.parse(df2.format(today));}
		catch (ParseException e) {System.out.println("error in parsing");}

		x = getDateDistance(_projStartDt, today) + LEADING_GAP;
		buf.append("<div class='monthLine' style='left:" + x + "px; top:" + BAR_HEADER_HEIGHT
				+ "px; height:" + lineHeight + "; width:2; background-color: #ff4444;'></div>");
	}

	private int getDateDistance(Date dt1, Date dt2)
	{
		int distDays = (int)((dt2.getTime() - dt1.getTime()) / 86400000);
		return distDays * SIZE_FACTOR;
	}

	/**
	*/
	private void setDependencyGraph(StringBuffer buf, PstUserAbstractObject u,
			project pj, StringBuffer jsBuf)
		throws PmpException
	{
		// for each dependency path, draw the graph
		String tidS1, tidS2, divId;
		BarDim bar;
		int begX, begY, endX, endY;
		for (Path path: _depPaths) {
			List<task> tkList = path.getPath();
			if (tkList.size() <= 1)
				continue;		// must have at list 2 points to draw graph

			// set the initial point to begin
			tidS1 = String.valueOf(tkList.get(0).getObjectId());
			bar = _barMap.get(tidS1);
			if (bar == null) continue;
			begX = bar._tail;
			begY = bar._yPos + 10;		// start from bar bottom, +10

			for (int i=1; i<tkList.size(); i++) {
				if (i >= tkList.size())
					break;		// must have at least two points to draw graph

				tidS2 = String.valueOf(tkList.get(i).getObjectId());
				bar = _barMap.get(tidS2);
				if (bar == null) continue;
				endX = bar._head;
				endY = bar._yPos;

				divId = tidS1 + "-" + tidS2;
				//System.out.println("Drawing dep " + divId);

				// draw the graph: horizontal line and vertical line
				// horizontal line
				int w = endX - begX;
				if (w <= 0) w = 1;
				buf.append("<div class='depLine' id='" + divId + "H' style='"
						+ "left:" + (begX+5) + "px; top:" + (begY-3) + "px;"
						+ "width:" + w + "px;"
						+ "border-top:dashed 1px #05e;'></div>");

				// vertical line
				buf.append("<div class='depLine' id='" + divId + "V' style='"
						+ "left:" + (endX+5) + "px; top:" + (begY-3)
						+ "px; height:" + (endY-begY)
						+ "px; border-right:dashed 1px #05e;'></div>");

				// Javascript to construct hash to remember the dependency
				jsBuf.append("saveDepPair(" + tidS1 + ", " + tidS2 + ");");

				// move end to beg
				// ECC: cannot use getDuration() to calculate the length of the bar because
				// if the task is completed, the true length depends on the CompletedDate
				begX = endX + (bar._tail - bar._head);	//tkList.get(i).getDuration()*SIZE_FACTOR;
				begY = endY + 10;
				tidS1 = tidS2;
			}
		}
	}

	/**
	   save the position of the bar so that we can build dependency graph later
	*/
	private void saveBarDimension(String tidS, int head, int tail, int yPos)
	{
		BarDim bar = new BarDim(head, tail, yPos);
		_barMap.put(tidS, bar);
	}

%>

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	String projIdS = request.getParameter("projId");
	if ((pstuser instanceof PstGuest) || (projIdS == null))
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	Logger l = PrmLog.getLog();

	String s = request.getParameter("sf");	// size factor for zoom
	if (s != null) {
		SIZE_FACTOR = Integer.parseInt(s);
	}
	else {
		SIZE_FACTOR = DEFAULT_SIZE_FACTOR;
	}


	//String browserType = request.getHeader("User-Agent");
	//if((browserType.toLowerCase().indexOf("msie") != -1))

	// all browsers are the same because in the dots DIV we use absolute to a relative parent
	int y_pos = 0; //32 + BAR_HEADER_HEIGHT;	// y-coordinate for the absolute bar position
	int init_GAP = -5;

	boolean isAdmin = false;
	boolean isProgMgr = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if (iRole > 0)
	{
		if ((iRole & user.iROLE_ADMIN) > 0)
			isAdmin = true;
		if ((iRole & user.iROLE_PROGMGR) > 0)
			isProgMgr = true;
	}

	// to check if session is CR or PRM
	boolean isCRAPP = util.Prm.isCR();
	boolean isCwModule = Prm.isCwModule(session);
	String app = Prm.getAppTitle();

	int myUid = pstuser.getObjectId();

	projectManager projMgr = projectManager.getInstance();
	taskManager tkMgr = taskManager.getInstance();
	userManager uMgr = userManager.getInstance();
	planManager planMgr = planManager.getInstance();
	planTaskManager ptMgr = planTaskManager.getInstance();

	////////////////////////////////////
	// Need to make sure that the plan is completely loaded by background thread
	s = (String)session.getAttribute("planComplete");
	while (s!=null && s.equals("false"))
	{
		try {Thread.sleep(200);}		// sleep for 0.2 sec
		catch (InterruptedException e) {}
		s = (String)session.getAttribute("planComplete");
	}

	// I might be coming in from anywhere (such as proj_summary.jsp) and the
	// session hash might not have my project to begin with, in which case
	// I need to refreshPlanHash()
	HashMap<String,String> taskNameMap =
		(HashMap<String,String>) session.getAttribute("taskNameMap");
	if (taskNameMap==null || !projIdS.equals((String)session.getAttribute("projId"))) {
		Util3.refreshPlanHash(pstuser, session, projIdS);
	}

	////////////////////////////////////

	project projObj = (project)projMgr.get(pstuser, Integer.parseInt(projIdS));
	boolean isUpdateOK = (myUid == Integer.parseInt((String)projObj.getAttribute("Owner")[0]));

	// this call will store the critical paths, all dep paths and the tasks involved
	// in the critical paths for later access
	String criticalPathString = "";
	List<Path> cPathList = projObj.getCriticalPaths(pstuser, true, _depPaths);

	for (int i=0; i<cPathList.size(); i++) {
		project.Path p = (project.Path)cPathList.get(i);
		criticalPathString +=
				p.toString((HashMap<String,String>)session.getAttribute("taskNameMap")) + "<br>";
	}
	criticalPathString = criticalPathString
		.replaceAll("\\[", "<b>\\[")
		.replaceAll("\\]", "\\]</b>")
		.replaceAll("\\(total", "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\\(<b>total</b>");

	String projDispName = projObj.getDisplayName();
	String version = (String)projObj.getAttribute("Version")[0];

	_projStartDt = (Date)projObj.getAttribute("StartDate")[0];
	long projStartTime = _projStartDt.getTime();

	// get the latest plan
	String [] planNames = planMgr.findName(pstuser, "(ProjectID='" +projIdS+ "') && (Status='Latest')");
	plan latestPlan = (plan)planMgr.get(pstuser, planNames)[0];

	// Get plan task (stack is constructed first time when going into a plan)
	Stack planStack = (Stack)session.getAttribute("planStack");
	if((planStack == null) || planStack.empty())
	{
		response.sendRedirect("../out.jsp?msg=Internal error in opening plan stack.  Please contact administrator.");
		return;
	}
	Vector rPlan = (Vector)planStack.peek();
	
	// view only or update
	boolean isViewOnly = (s=request.getParameter("vo"))==null || s.equals("true");

%>


<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<link href="../plan/x.css" rel="stylesheet" type="text/css" media="screen"/>
<script type='text/javascript' src='../plan/x_core.js'></script>
<script type='text/javascript' src='../plan/x_event.js'></script>
<script type='text/javascript' src='../plan/x_drag.js'></script>
<script type='text/javascript' src="../date.js"></script>
<jsp:include page="../init.jsp" flush="true"/>

<script type="text/javascript" language="javascript">
<!--
/************************************************
 * Drag DOTS
 * Each task has two dots; start and expire, A1 and B1 (the # is the task #)
 * Each dot has a low and high as its left/right boundaries
 */

window.setInterval("checkScroll(document.getElementById('div1'), document.getElementById('div2'))", 5);

var statusMsg;
window.onload = function () {
	statusMsg = document.getElementById("status");
}

var highZ = 3;
var max = <%=rPlan.size()%>;		// total # of task; there will be 2*max dots
var msecToDay = 86400000;
var fac = <%=SIZE_FACTOR%>;

var LEADING_GAP = <%=LEADING_GAP%>;
var LOW = LEADING_GAP;
var HIGH = 770;
var PjStartGap = LEADING_GAP + <%=init_GAP%>;	// where the project start line is

var lowA  = new Array(max);
var highA = new Array(max);
var lowB  = new Array(max);
var highB = new Array(max);
var children = new Array(max);		// keep track of my children in a idx string 3;4;5

var startDt  = new Array(max);		// remember start date for each task
var expireDt = new Array(max);		// remember expire date for each task

var maxWidth = 0;					// max width of all elements in table
var maxWidthIdx = -1;				// the item that is longest
var barTableW = 0;

var updatedBars = ";";				// String to remember which task get changed ";num;"

var tidArr = new Array();			// array to map idx with task Id
var headHash = new Object();		// hash to map taskId to divId of dependency
var tailHash = new Object();		// head maps begin task to divId; tail maps end task to divId

// the dots ID are (A1, B1)
function dotSetup(d, x, y, dt, dragOK, parentBeg, parentEnd, parentIdx)
{
	 var dd = xGetElementById(d);
	 xMoveTo(dd, x, y);	 
	 if (dragOK)
		xEnableDrag(dd, d1OnDragStart, d1OnDrag, d1OnDragEnd);
	 xShow(dd);

	 var i = parseInt(d.substring(1));
	 var type=d.charAt(0);				// either A or B

	 // set boundaries for the calling dot
	 if (type == 'A')
	 {
		if (parentBeg != -1)
			lowA[i] = parentBeg;
		else
			lowA[i] = PjStartGap;	//should be the low of parent task
		lowB[i] = x;
		startDt[i] = dt;
	 }
	 else
	 {
		if (parentEnd != -1)
			highB[i] = parentEnd;
		highA[i] = x;
		// highB can be bounded by project expire, or more flexibly not bounded.
		expireDt[i] = dt;
	 }
	 if (parentIdx != -1)
	 {
		 s = children[parentIdx];
		 if (s == null)
			 children[parentIdx] = ";" + i + ";";		// first child
		 else if (s.indexOf(";"+i+";") == -1)
			 children[parentIdx] += i + ";";	// append another child
	 }

	 if (x > barTableW)
	 	barTableW = x;
}

function d1OnDragStart(ele, mx, my)
{
	 //window.status = '';
	 xZIndex(ele, highZ++);
	 ele.totalMX = 0;
	 ele.totalMY = 0;
}
function d1OnDrag(ele, mdx, mdy)
{
	 //xMoveTo(ele, xLeft(ele) + mdx, xTop(ele) + mdy);
	 i = parseInt(ele.id.substring(1));
	 var low, high;
	 var type = ele.id.charAt(0);	// either A or B: A is startDate dot; B is expireDate dot
	 if (type == 'A')
		{high = highA[i]; low = lowA[i];}
	 else
		{high = highB[i]; low = lowB[i];}

	 var newX = xLeft(ele) + mdx;
	 if (newX < low) newX = low;
	 else if (newX > high) newX = high;

	 // must agree with children
	 if (children[i] != undefined)
	 {
		 var childArr = children[i].split(";");
		 for (j=0; j<childArr.length; j++)
		 {
			 if (childArr[j] == "") continue;
			 if (type == 'A')
			 {
				 // my lowA cannot be before my children's A
				 ce = document.getElementById("A" + childArr[j]);
				 if (newX > xLeft(ce))
					 newX = xLeft(ce);
			 }
			 else
			 {
				 // my highB cannot before my children's B
				 ce = document.getElementById("B" + childArr[j]);
				 if (newX < xLeft(ce))
					 newX = xLeft(ce);
			 }
		 }
	 }

	 if (newX < PjStartGap)
	 	newX = PjStartGap;

	 // move dependency lines if any attached to this task
	 var tid = tidArr[i];
	 var key = tid + ".";
	 var idx = 0;
	 var divId;
	 if (type == "A")
	 {
		 while ((divId = tailHash[key+idx++]) != undefined)
			newX = moveDep(divId, 0, newX, (mdx>0));
	 }
	 else
	 {
		 while ((divId = headHash[key+idx++]) != undefined)
		 	newX = moveDep(divId, newX, 0, (mdx>0));
	 }

	 //window.status = "(" + low + ", " + high + ") newX=" + newX;
	 xMoveTo(ele, newX, xTop(ele));
	 ele.totalMX += mdx;		// not used


	 var left = xLeft(document.getElementById("A"+i));
	 var right = xLeft(document.getElementById("B"+i));
	 if (right-left <= <%=MIN_DISP_DATES_LENGTH%>) {
		 // do not display ExpireDate
		 e = document.getElementById("Bdt" + i);
		 e.innerHTML = "";
		 if (type == 'B')
		 	return;
	 }

	 // output the StartDate or ExpireDate
	 var s = formatDate(new Date((xLeft(ele))*msecToDay/fac + <%=projStartTime%>), "M/dd");
	 var e = document.getElementById(type + "dt" + i);
	 e.innerHTML = s;
	 //window.status = ele.id + ': ' + xLeft(ele);
}

function d1OnDragEnd(ele, mx, my)
{
  	 //window.status = ele.id + ':  X: ' + ele.totalMX + ', Y: ' + ele.totalMY;
	 var i = parseInt(ele.id.substring(1));
	 var type = ele.id.charAt(0);		// either A or B: A is startDate dot; B is expireDate dot
	 var pos = xLeft(ele);

	 var s = formatDate(new Date((pos)*msecToDay/fac + <%=projStartTime%>), "<%=df2S%>");
	 //window.status = pos;

	 // set new boundaries and save dates
	 var w1, w2;
	 if (type == 'A')
	 {
		lowB[i] = pos;
		startDt[i] = s;
	 }
	 else
	 {
		highA[i] = pos;
		expireDt[i] = s;
	 }

	 var left = xLeft(document.getElementById("A"+i));
	 var right = xLeft(document.getElementById("B"+i));

	 // calculate duration of task (days)
	 // ECC: dangerous on date format
	 dt1 = new Date(startDt[i]);
	 dt2 = new Date(expireDt[i]);
	 var duration = ((dt2.getTime() - dt1.getTime()) / msecToDay);
	 temp = parseInt(duration);
	 //debug(temp+", " + duration);
	 if (duration > temp)
		 duration = temp + 1;
	 var e = document.getElementById("Days" + i);
	 e.innerHTML = "&nbsp;" + duration + " days";

	 // adjust the length of the brank space
	 var gap = ((dt1.getTime() - <%=projStartTime%>)/msecToDay);		// in days
	 //temp = parseInt(gap);
	 //if (gap != temp)
		 //gap = temp + 1;
	 gap = parseInt(gap);
	 w1 = gap * fac + LEADING_GAP;
	 if (w1 == 0) w1 = 1;		// e.width can't take 0
	 e = document.getElementById("Blank" + i);
	 e.width = left + 5; //w1;


	 // adjust the length of the bar
	 w2 = duration * fac;
	 //debug((right-left)+", " + w2);
	 var newBarWidth = right - left;
	 if (newBarWidth <= fac) newBarWidth = fac;

	 e = document.getElementById("Bar" + i);
	 e.width = newBarWidth;  //w2;	// set the width of the bar

	 // display only StartDate if the bar is too short
	 if (newBarWidth <= <%=MIN_DISP_DATES_LENGTH%>) {
		 e = document.getElementById("Bdt" + i);
		 e.innerHTML = "";
	 }

	 temp = w1+w2+200;
	 if (maxWidth < temp)
	 {
		 // just got longer than max width
		 maxWidth = temp;
		 maxWidthIdx = i;
	 }
	 else if (maxWidthIdx == i)
	 {
		 // the maxWidth item just got shorter, need to recalculate who is longest
		 maxWidth = temp;
		 for (j=0; j<max; j++)
		 {
			 e = document.getElementById("B" + j);
			 pos1 = xLeft(e);
			 if (pos1 > maxWidth)
			 {
				 maxWidth = pos1;
				 maxWidthIdx = j;
				 break;
			 }
		 }
	 }
	 ee = document.getElementById("BarTable");
	 if (maxWidth > ee.width)
		ee.width = maxWidth;

	 // my children would have a new high/low
	 if (children[i] != undefined)
	 {
		 var childArr = children[i].split(";");
		 for (j=0; j<childArr.length; j++)
		 {
			 if (childArr[j] == "") continue;
			 if (type == 'A')
				 lowA[childArr[j]] = pos;
			 else
				 highB[childArr[j]] = pos;
	 	}
	 }

	 // remember this task got changed
	 if (updatedBars.indexOf(";"+i+";") == -1)
		 updatedBars += i + ";";	// append another task's idx
}

function moveDep(divId, BPos, APos, bForward)
{
	//alert("calling moveDep(" + divId + "," + BPos+","+APos+")");
	if (BPos == 0)
	{
		// dot A (tail of a dep) got moved
		var e = document.getElementById(divId + "H");
		var l = stripPx(e.style.left);
		var min = l - 5;

		var wid = APos - l;
		debug(APos+","+l);
		if (APos<=min && !bForward) {
			APos = min;
		}
		if (wid <= 0) wid = 1;
		e.style.width = wid + "px";

		e = document.getElementById(divId + "V");
		e.style.left = APos+5;

		return APos;
	}
	else
	{
		// dot B (head of a dep) got moved
		var e = document.getElementById(divId + "V");
		var min = stripPx(e.style.left) - 5;
		debug(min+","+BPos);

		e = document.getElementById(divId + "H");
		var l = stripPx(e.style.left);
		var wid = stripPx(e.style.width);
		if (BPos>=min && bForward) {
			BPos = min;
			wid = 1;
			e.style.left = BPos;
		}
		else {
			wid += l-BPos-5;
			if (wid <= 0) wid = 1;
			e.style.left = BPos + 5;
		}
		e.style.width = wid + "px";
		return BPos;
	}
}

function stripPx(len)
{
	if (len.match(/px$/) != null)
		len = len.substring(0, len.length-2);
	return parseInt(len);
}

var lastSeen = [0, 0];
function checkScroll(div1, div2)
{
	if (!div1 || !div2) return;
	var control = null;
	if (div1.scrollTop != lastSeen[0]) control = div1;
	else if (div2.scrollTop != lastSeen[1]) control = div2;
	if (control == null) return;
	else div1.scrollTop = div2.scrollTop = control.scrollTop;
	lastSeen[0] = div1.scrollTop;
	lastSeen[1] = div2.scrollTop;
}

function resizeWindow()
{
	var windowW = parseInt(getViewportWidth() * 0.72);
	document.getElementById("div2").style.width = windowW;
	var e = document.getElementById("BarTable");
	if (e.width < windowW)
		e.width = windowW;
}

function validation()
{
	// update allow only if there is no zoom
	if (<%=SIZE_FACTOR%> != <%=DEFAULT_SIZE_FACTOR%>) {
		alert("<%=MSG_ZOOM_NODRAG%>" + " Press the Zoom link to return to normal size.");
		return;
	}

	// extract the A (beg dot) and B (end dot) positions of each updated bar
	updatedBars = updatedBars.substring(1);						// ignore the initial ";"
	if (updatedBars == "")
		return;
	updatedBars = updatedBars.substring(0, updatedBars.length-1);	// ignore the ending ";"

	var updatedArr = updatedBars.split(";");
	var idx;
	var begDtStr = "";
	var endDtStr = "";
	for (i=0; i<updatedArr.length; i++)
	{
		idx = parseInt(updatedArr[i]);
		begDtStr += startDt[idx] + ";";
		endDtStr += expireDt[idx] + ";";
	}

	f = document.TimeLineForm;
	f.updatedIdx.value = updatedBars;			// idx's separated by ";"
	f.begDt.value = begDtStr;
	f.endDt.value = endDtStr;
	document.TimeLineForm.submit();
}

function saveTaskIdArray(idx, tid)
{
	// save idx, taskId pair.  From taskId we will find the dependency pairs
	tidArr[idx] = tid;
}

function saveDepPair(tid1, tid2)
{
	// save 2 hashs to map head/tail tasks of a dependency
	//alert("calling saveDepPair(" + tid1 + "," + tid2 + ")");
	var divId = tid1 + "-" + tid2;	// the div ID actually append with "H" and "V"

	// each task may have more than one dependencies, so I need to append a digit to the key
	var key = tid1 + ".";
	var idx = 0;
	while (headHash[key + idx] != undefined)
		idx++;
	headHash[key+idx] = divId;
	key = tid2 + ".";
	idx = 0;
	while (tailHash[key + idx] != undefined)
		idx++;
	tailHash[key+idx] = divId;
}

var zoomPercentage = 100.0;
function zoom(zoomIn)
{
	if (zoomIn == 0) {
		zoomPercentage = 100.0;
	}
	else if (zoomIn == 1) {
		zoomPercentage *= 1.1;
	}
	else {
		zoomPercentage *= 0.9;
	}
	
	var leftTable  = document.getElementById("LeftTable");
	var rightTable = document.getElementById("BarTable");
	var rightHeaderDiv  = document.getElementById("BarHeaderDiv");
	leftTable.style.zoom = zoomPercentage + "%";
	rightHeaderDiv.style.zoom = zoomPercentage + "%";
	rightTable.style.zoom = zoomPercentage + "%";
	return;
}

function viewOnly(op)
{
	if (op == <%=isViewOnly%>) return;	// ignore
	else {
		location = "timeline.jsp?projId=<%=projIdS%>&vo=" + op;
	}
}

function debug(msg)
{
	statusMsg.innerHTML = msg;
}
//-->
</script>

<title>
	<%=app%> Project Timeline
</title>

</head>

<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0" onresize="resizeWindow();">

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="100%" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<table width='90%'>

	<tr><td colspan="2">&nbsp;</td></tr>
	<tr>
		<td></td>
		<td>
			<b class="head">Project Timeline</b>
		</td>
		<td align='right'><img src='../i/bullet_tri.gif'/>
			<a class='listlinkbold' href='../project/proj_top.jsp'>Back to Project Top</a>
		</td>
	</tr>

	<tr>
	<td></td>
	<td valign="top" class="title">
		&nbsp;&nbsp;&nbsp;<%=projDispName%>
	</td>
	</tr>
	</table>

	<table width="90%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>


<!-- Navigation SUB-Menu -->
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
<td width="100%" valign="top">

	<table border="0" height="14" cellspacing="0" cellpadding="0" width='90%'>
		<tr>
			<td valign="top" class="bgsubnav">
				<table border="0" cellspacing="0" cellpadding="0">
				<tr class="bgsubnav">

					<td width="20"><img src="../i/spacer.gif" width="30" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
	<!-- Top -->
					<td><img src="../i/spacer.gif" width="10" height="1" border="0"></td>
					<td><a href="../project/proj_top.jsp?projId=<%=projIdS%>" class="subnav">Top</a></td>
					<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
	<!-- File Repository -->
					<td width="20"><img src="../i/spacer.gif" width="10" height="1" border="0"></td>
					<td><a href="../project/cr.jsp?projId=<%=projIdS%>" class="subnav">File Repository</a></td>
					<td width="15"><img src="../i/spacer.gif" width="10" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
	<!-- Project Plan -->
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="../project/proj_plan.jsp?projId=<%=projIdS%>" class="subnav">Project Plan</a></td>
					<td colspan="3" width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
	<!-- Update All Tasks -->
					<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
					<td><a href="../project/task_updall.jsp?projId=<%=projIdS%>" class="subnav">Update All Tasks</a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
	<!-- Dependencies -->
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="../plan/dependency.jsp?projId=<%=projIdS%>" class="subnav">Dependencies</a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
	<!-- Timeline -->
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="20" height="14"><img src="../i/nav_arrow.gif" width="20" height="14" border="0"></td>
					<td><a href="#" onClick="return false;" class="subnav"><u>Timeline</u></a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
<%	if (isCwModule) {%>
	<!-- Work In-Tray -->
					<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
					<td><a href="../box/worktray.jsp" class="subnav">Work In-Tray</a></td>
					<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
<%	} %>
				</tr>
				</table>
			</td>
		</tr>

		<tr>
			<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
		</tr>
	</table>

</td>
</tr>
</table>
<!-- End of Navigation SUB-Menu -->



<!-- CONTENT -->

<!-- ************************************************ -->
<form method="post" name="TimeLineForm" action="post_timeline.jsp">
<input type="hidden" name="projId" value='<%=projIdS%>'>
<input type='hidden' name='updatedIdx' value=''>
<input type='hidden' name='begDt' value=''>
<input type='hidden' name='endDt' value=''>

<%
	for (int i=0; i<planStack.size(); i++) {
		out.print("<input type='hidden' name='startDT"+i+"' id='startDT"+i+"' value=''>");
		out.print("<input type='hidden' name='expireDT"+i+"' id='expireDT"+i+"' value=''>");
	}

%>
<table width="100%" border="0" cellspacing="0" cellpadding="0">
	<tr>
	<td><img src="../i/spacer.gif" height="1" width="10" /></td>
	<td>
		<table border="0" cellspacing="0" cellpadding="0">
			<tr>

			<td><img src='../i/spacer.gif' width='400' height='1'/><td>

<%
		// view only or update
		out.print("<td class='plaintext_blue'><input type='radio' name='viewOrUpdate' onClick='viewOnly(true);' ");
		if (isViewOnly) out.print("checked");
		out.print(">View Only</td>");

		if (isViewOnly) {
			// zoom
			out.print("<td width='200'><table border='0' cellspacing='0' cellpadding='0'><tr>");
			out.print("<td><img src='../i/spacer.gif' width='30'/></td>");
			out.print("<td class='plaintext_blue'><a href='javascript:zoom(2);'>-</a></td>");	// zoom out
			out.print("<td class='plaintext_blue'>&nbsp;<a href='javascript:zoom(0);'>Zoom</a>&nbsp;</td>");
			out.print("<td class='plaintext_blue'><a href='javascript:zoom(1);'>+</a></td>");	// zoom in
			out.print("</tr></table></td>");
		}
		else {
			// blank space
			out.print("<td><img src='../i/spacer.gif' width='200' height='1'/></td>");
		}
		
		out.print("<td class='plaintext_blue'><input type='radio' name='viewOrUpdate' onClick='viewOnly(false);' ");
		if (!isViewOnly) out.print("checked");
		out.print(">Update</td>");
		if (!isViewOnly) {
			out.print("<td><img src='../i/spacer.gif' width='20' height='1'/></td>");
			out.print("<td><input type='button' class='button_medium' value='Submit' onClick='validation();'/></td>");
		}
%>
			</tr>
			<tr><td height="10"><img src="../i/spacer.gif" height="10" width="1" /></td></tr>
		</table>

<%
	// left is task list; right is bar chart
	out.print("<table border='1' cellpadding='0' cellspacing='0' width='90%'>");
	out.print("<tr>");		// the whole box has one row, left is task name, right is timeline bars

	// task
	out.print("<td width='25%'>");	// left TD

	task t;
	String taskIdS;
	int [] ids;
	boolean isParentTask;
	PstAbstractObject ptObj;		// the current plan task
	String myParentID;				// planTask parent if I am a subtask
	String myParentIdxS;			// for JS index
	HashMap <String,String> JSIndexMap = new HashMap<String,String>();

	String[] levelInfo = new String[JwTask.MAX_LEVEL];
	String lastlevelInfo = "";
	String bgcolor="";
	boolean even = false;
	StringBuffer sBuf1 = new StringBuffer(8192);			// for task display
	StringBuffer sBuf2 = new StringBuffer(8192);			// for bar
	StringBuffer sJsBuf1 = new StringBuffer(8192);			// for javascript of dots
	StringBuffer sJsBuf2 = new StringBuffer(2048);			// for javascript of dependency

	Date startDt, expireDt, actualStartDt, finishedDt;
	String startDtS, expireDtS;
	long startTime;
	int gap;					// start gap from proj startDate
	int duration;				// task length, in days
	int dayMsec = 86400000;
	int rowHeight = 40;
	int maxTableWidth = 0;
	int count = 0;
	boolean dragOK;

	int head, tail;

	sBuf1.append("<table id='LeftTable' width='400' border='0' cellpadding='0' cellspacing='0'>");
	sBuf1.append("<tr><td class='barHeader'>Project Task</td></tr>");

	//sBuf2.append("<table id='BarTable' border='0' cellpadding='0' cellspacing='0'>");

	for(int i = 0; i < rPlan.size(); i++)
	{
		Hashtable rTask = (Hashtable)rPlan.elementAt(i);
		String tName = (String)rTask.get("Name");
		taskIdS = (String)rTask.get("TaskID");
		int planTaskId = Integer.parseInt((String)rTask.get("PlanTaskID"));
		t = (task)tkMgr.get(pstuser, Integer.parseInt(taskIdS));
		actualStartDt = t.getEffectiveDate();
		if (actualStartDt == null) {
			startDt = t.getStartDate();
			if (startDt == null)
				continue;	// container
		}
		else {
			startDt = actualStartDt;
		}
		
		finishedDt = t.getCompleteDate();
		if (finishedDt != null) {
			// use actual finish date if there is one
			expireDt = finishedDt;
		}
		else {
			expireDt = t.getExpireDate();
			if (expireDt==null || expireDt.before(startDt)) {
				expireDt = startDt;		// null Expire treats as same day
			}
		}

		boolean isInCriticalPath
			= projObj.isInCriticalPath(pstuser, taskIdS, false);

		dragOK = !isViewOnly && (finishedDt==null)
					&& (isUpdateOK || myUid==Integer.parseInt((String)t.getAttribute("Owner")[0]));

		// remember planTaskId w/ idx
		JSIndexMap.put(String.valueOf(planTaskId), String.valueOf(i));

		// am I a parent task?
		ids = ptMgr.findId(pstuser, "ParentID='" + planTaskId + "' && Status!='" + task.DEPRECATED + "'");
		isParentTask = ids.length > 0;

		// do I have a parent?
		ptObj = ptMgr.get(pstuser, planTaskId);
		myParentID = ((planTask)ptObj).getParentIdS();

		Object [] pLevel = (Object [])rTask.get("Level");
		Object [] pOrder = (Object [])rTask.get("Order");

		int level = ((Integer)pLevel[0]).intValue();
		int order = ((Integer)pOrder[0]).intValue();

		int width = 5 + 22 * level;	// 10 + 22 * level;
		order++;
		if (level == 0)
			levelInfo[level] = Integer.toString(order);
		else
			levelInfo[level] = levelInfo[level - 1] + "." + order;
		level++;

		if (even)
			bgcolor = "bgcolor='#EEEEEE'";
		else
			bgcolor = "bgcolor='#ffffff'";
		even = !even;

		sBuf1.append("<tr height='" + rowHeight + "' " + bgcolor + ">");

		// the index and task name: one TD
		sBuf1.append("<td><table border='0' cellspacing='0' cellpadding='0'><tr>");
		sBuf1.append("<td width='" + width + "' class='plaintext'><img src='../i/spacer.gif' width='" + width
				+ "' height='1' border='0'/></td>");
		sBuf1.append("<td width='20' class='plaintext_grey' valign='top'>");
		sBuf1.append(levelInfo[level-1] + "&nbsp;&nbsp;</td>");
		sBuf1.append("<td class='listlink' title='TaskID: " + taskIdS
				+ "'><a href='../project/task_update.jsp?projId=" + projIdS
				+ "&pTaskId=" + planTaskId + "'>" + tName + "</a></td>");
		sBuf1.append("</tr></table></td>");
		sBuf1.append("</tr>");

		//////////////////////////////////////////////////////////////////////////
		// bar
		// for each task:
		// use the StartDate distance from project StartDate to determine begin
		// use the ExpireDate distance to determine the end
		sBuf2.append("<tr><td><img src='../i/spacer.gif' height='5' /></td></tr>");	// space before

		// x: start task bar
		sBuf2.append("<tr height='" + (rowHeight-10) + "'><td>");	// subtract spaces before and after

		// leading (empty) space
		startTime = startDt.getTime();
		//gap = (int)((startTime - projStartTime)/dayMsec);				// in days
		gap = task.getDaysDiff(startDt, _projStartDt);
		//duration = (int)((expireDt.getTime() - startTime)/dayMsec) + 1;	// in days
		//int dur = t.getDuration();
		duration = task.getDaysDiff(expireDt, startDt);
		int dur = duration;
		if (dur <= 0) dur = 1;

		startDtS  = df1.format(startDt);
		expireDtS = df1.format(expireDt);

		int w1 = gap*SIZE_FACTOR + LEADING_GAP;		// leading blank (start gap)
		int w2 = (duration)*SIZE_FACTOR;			// bar length (duration)
		if (w2 <= MIN_DISP_DATES_LENGTH)
			expireDtS = "";	// don't show the expire date if the bar is too short

		sBuf2.append("<table border='0' cellpadding='0' cellspacing='0'><tr>");
		sBuf2.append("<td id='Blank" + i + "' width='" + w1
				+ "' height='1'/></td>");	// start gap (blank)

		// y: task bar (2 rows): dates follow by the bar
		sBuf2.append("<td><table border='0' cellpadding='0' cellspacing='0'>");
		sBuf2.append("<tr><td id='Adt" + i + "' class='barDigit'>" + startDtS + "</td>");
		sBuf2.append("<td id='Bdt" + i + "' class='barDigit' align='right'>" + expireDtS + "</td>");
		sBuf2.append("<td></td></tr>");		// empty column for below need it for # of days

		if (isParentTask)
		{
			// break the task bar into 2 colors
			sBuf2.append("<tr>");
			sBuf2.append("<td colspan='2'><table border='0' cellspacing='0' cellpadding='0'><tr>");
			sBuf2.append("<td id='Bar" + i + "' width='" + w2 +"'>");
			sBuf2.append("<table width='100%' border='0' cellspacing='0' cellpadding='0'>");
			sBuf2.append("<tr><td colspan='3' bgcolor='#3333aa' height='4'></td></tr>");
			sBuf2.append("<tr><td bgcolor='#3333aa' width='2'><img src='../i/spacer.gif' width='2'/></td>");
			if (!isInCriticalPath) {
				sBuf2.append("<td bgcolor='#cccccc' height='6'><img src='../i/spacer.gif' width='8' height='1'/></td>");
			}
			else {
				sBuf2.append("<td height='6'><table width='100%' cellspacing='0' cellpadding='0'>");
				sBuf2.append("<tr><td bgcolor='#ee0000' height='1'><img src='../i/spacer.gif' width='8' height='1'/></td></tr>");
				sBuf2.append("<tr><td bgcolor='#cccccc' height='5'></td></tr>");
				sBuf2.append("</table></td>");
			}
			sBuf2.append("<td bgcolor='#3333aa' width='2'></td></tr>");
			sBuf2.append("</table></td>");
			sBuf2.append("<td></td></tr></table></td>");
		}
		else
		{
			sBuf2.append("<tr>");
			if (!isInCriticalPath) {
				sBuf2.append("<td colspan='2'><table border='0' cellspacing='0' cellpadding='0'><tr>");
				sBuf2.append("<td id='Bar" + i + "' bgcolor='#3333aa' width='" + w2
						+ "' height='10'><img src='../i/spacer.gif' width='10' height='1'/></td>");
				sBuf2.append("<td></td></tr></table></td>");
			}
			else {
				sBuf2.append("<td colspan='2'><table border='0' cellspacing='0' cellpadding='0'><tr>");
				sBuf2.append("<td id='Bar" + i + "' width='" + w2 + "' height='10'>");
				sBuf2.append("<table width='100%' cellspacing='0' cellpadding='0'>");
				sBuf2.append("<tr><td bgcolor='#3333aa' height='4'><img src='../i/spacer.gif' width='10' height='1'/></td></tr>");
				sBuf2.append("<tr><td bgcolor='#ee0000' height='1'></td></tr>");
				sBuf2.append("<tr><td bgcolor='#3333aa' height='5'></td></tr>");
				sBuf2.append("</table></td>");
				sBuf2.append("<td></td></tr></table></td>");
			}
		}
		sBuf2.append("<td id='Days" + i +"' class='barDigit'>&nbsp;" + dur + " days");
		if (finishedDt != null) {
			sBuf2.append(" (<b>Done</b>)");
		}
		sBuf2.append("</td></tr>");
		sBuf2.append("</table></td>");
		// y: end task bar

		if (maxTableWidth < w1+w2)
			maxTableWidth = w1 + w2;

		sBuf2.append("</tr>");
		// x: end

		// z: declare moving dots (start and expire)
		sBuf2.append("<tr><td>");
		sBuf2.append("<div style='position:relative'>");
		sBuf2.append("<div id='A" + i + "' class='curBox'>");
		sBuf2.append("<table border='0' cellpadding='0' cellspacing='0'>");
		sBuf2.append("<tr><td><img src='../i/tri_blue.gif' border='0'></td></tr>");
		sBuf2.append("</table></div></div>");
		sBuf2.append("<div style='position:relative'>");
		sBuf2.append("<div id='B" + i + "' class='curBox'>");
		sBuf2.append("<table border='0' cellpadding='0' cellspacing='0'>");
		sBuf2.append("<tr><td><img src='../i/tri_red.gif' border='0'></td></tr>");
		sBuf2.append("</table></div></div>");
		sBuf2.append("</td>");

		// find min/max based on parent task
		int min=-1, max=-1;
		if (myParentID != null)
		{
			Date dt = t.getParentTaskStartDate(pstuser);
			if (dt != null)
			{
				//min = (int)((dt.getTime() - projStartTime)/dayMsec);	// in days
				min = task.getDaysDiff(dt, _projStartDt) - 1;
				min = init_GAP + min * SIZE_FACTOR + LEADING_GAP;

				dt = t.getParentTaskExpireDate(pstuser);
				if (dt == null) {
					// this should not happen, the parent should have both start and end dates
					l.error("Error: task [" + taskIdS
					        + "] has a parent without ExpireDate.  Perform data fix on parent.");
					// do nothing
				}
				else {
					max = task.getDaysDiff(dt, _projStartDt);
					max = max * SIZE_FACTOR - init_GAP;
				}
			}
			myParentIdxS = JSIndexMap.get(myParentID);
		}
		else
			myParentIdxS = "-1";	// no parent
			
		head = init_GAP + gap * SIZE_FACTOR + LEADING_GAP;
		tail = init_GAP + (gap + duration) * SIZE_FACTOR + LEADING_GAP;
		if (tail <= head) tail += SIZE_FACTOR;	// don't let the dots overlap

		// draw the dragging dots
		if (dragOK) {
			boolean dragable = !isViewOnly;		//SIZE_FACTOR==DEFAULT_SIZE_FACTOR;
			// the Y position is always 0 because we use relative DIV ontop of the absolute
			sJsBuf1.append("dotSetup('A" + i + "'," + head + "," + 0 + ",'"
					+ df2.format(startDt) + "'," + dragable + "," + min + "," + max + "," + myParentIdxS + ");");
			sJsBuf1.append("dotSetup('B" + i + "', " + tail + ", " + 0 + ",'"
					+ df2.format(expireDt) + "'," + dragable + "," + min + "," + max + "," + myParentIdxS + ");");
			sJsBuf1.append("saveTaskIdArray(" + i + ",'" + taskIdS + "');");
		}
		
		y_pos += 40;
		saveBarDimension(taskIdS, head, tail, y_pos);	// y offset by 400

		sBuf2.append("</tr>");
		// z: end declare moving dots

		sBuf2.append("</table>");
		sBuf2.append("</td></tr>");			// close the whole line for bar

		sBuf2.append("<tr><td><img src='../i/spacer.gif' height='5' /></td></tr>");	// space after

		// done with one task
		lastlevelInfo = levelInfo[level-1];
		count++;
	}	// END: for loop

	sBuf1.append("<tr><td><img src='../i/spacer.gif' height='20'/></td></tr>");	// space at bottom
	sBuf1.append("</table>");

	sBuf2.append("<tr><td><img src='../i/spacer.gif' height='20'/></td></tr>");	// space at bottom


	//////////////////////////////////////////////////////////////////////////////////
	// now, actual output to HTML
	int height = 500; //count * 42;		// full length (no vertical scroll bar)
	out.println("<div id='div1' class='scrollTask' style='height:" + height + "px; width:300;'>"
			+ sBuf1.toString() + "</div>");

	out.print("</td>");		// close the left TD

	//////////////////////////////////////////////////////////////////////////////////
	// right side is bar

	// construct overlay grid
	int tableWidth = maxTableWidth+200;
	if (tableWidth < MIN_TABLE_WIDTH)
		tableWidth = MIN_TABLE_WIDTH;
	int lineHeight = count * 42;						// the height of month marking lines
	if (lineHeight < 500) lineHeight = 500;

	StringBuffer gBuf = new StringBuffer(8192);
	gBuf.append("<table id='BarTable' width='" + tableWidth
			+ "' border='0' cellpadding='0' cellspacing='0'>");		// now set the BarTable width
	gBuf.append("<div id='BarHeaderDiv' style='position:relative;'>");
	setMonthGrid(gBuf, lineHeight, tableWidth);
	setDependencyGraph(gBuf, pstuser, projObj, sJsBuf2);

	// header
	gBuf.append("<tr><td class='barHeader'>&nbsp;</td></tr>");

	// insert the first part, header and grid, into the buffer
	sBuf2.insert(0, gBuf);
	sBuf2.append("</div>");
	sBuf2.append("</table>");

	out.println("<td>");	// right TD
	out.println("<div id='div2' class='scrollTask' style='height:" + height + "px; width:100%;'>");
	out.print(sBuf2.toString());

	out.print("</div>");		// close div2
	out.print("</td>");			// close the right TD
	out.print("</tr></table>");	// close both panels

	// now call javascript to set the dots in place
%>
<script type='text/javascript'>
<!--
<%
	out.println(sJsBuf1.toString());		// calling javascript to set initial dot positions
	out.println(sJsBuf2.toString());		// save dependency info for moving lines
%>
	resizeWindow();


//-->
</script>


<!-- append at the end -->

		<tr><td colspan='20'><img src='../i/spacer.gif' width='2' height='5' border='0'/></td></tr>
		</table>

		<table border="0" cellspacing="0" cellpadding="0">
			<tr><td><img src='../i/spacer.gif' height='10' width='1' /></td></tr>
			<tr><td></td>
				<td><img src='../i/spacer.gif' width=20' height='1'/></td>
				<td class='plaintext_blue' width='120' valign='top'>Critical path: </td>
				<td class='plaintext_big'><%=criticalPathString%></td>
			</tr>

			<tr><td><img src='../i/spacer.gif' height='10' width='1' /></td></tr>

<tr><td></td><td colspan='2'><div id='status'></div></td></tr>

		</table>
	</td>
	</tr>
	<tr><td colspan="2">&nbsp;</td></tr>

	</table>
</form>


<!-- ************************************************ -->

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

