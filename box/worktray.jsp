<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2010, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: worktray.jsp
//	Author: ECC
//	Date:	01/01/10
//	Description:
//				Work item management with resource management.
//				Display work items in my in-tray for me to process.
//				It shows the process graph that a selected work item is
//				associated with.  And it shows the detail of the work item.
//				Managers may select their direct reports and see their work tray.
//
//	TODO:	When clicking on a step, show its detail info and allow update if adequate.
//			Create a similar page to allow selecting and starting a process.
//			worktray.jsp to commit/abort/update step, moving the flow forward.
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "util.*" %>
<%@ page import = "mod.box.PrmDrawFlow" %>
<%@ page import = "mod.box.FlowBase" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.omm.common.*" %>
<%@ page import = "oct.omm.client.*" %>
<%@ page import = "oct.omm.db.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.DecimalFormat" %>
<%@ page import = "java.text.SimpleDateFormat" %>
<%@ page import = "org.apache.log4j.Logger" %>

<%!
	final long DAY = 24 * 3600000;
	final long WEEK = DAY * 7;
	final long MONTH = DAY * 30;
	final String LARGE_STR = "zzzzz";

	final String HEAD_LINE =
		"<tr><td colspan='4'><table border='0' cellspacing='0' cellpadding='0'>"
		+ "<tr><td><img src='../i/spacer.gif' width='0' /></td><td bgcolor='#fe9900'><img src='../i/spacer.gif' height='1' width='30' /></td><td width='60'></td></tr>"
		+ "<tr><td></td><td colspan='2' width='150' bgcolor='#fe9900'><img src='../i/spacer.gif' width='100' height='1' /></td></tr>"
		+ "</table></td></tr>";

	final String HOST = Util.getPropKey("pst", "PRM_HOST");

	SimpleDateFormat df1 = new SimpleDateFormat ("MM/dd/yy");
	SimpleDateFormat df2 = new SimpleDateFormat ("h:mm a");
	SimpleDateFormat df3 = new SimpleDateFormat ("MM/dd/yy h:mm a");
	SimpleDateFormat df4 = new SimpleDateFormat ("MM/dd/yyyy");
	SimpleDateFormat df5 = new SimpleDateFormat ("dd");
	DecimalFormat dcf = new DecimalFormat("#0.0");

	final String todayS = df4.format(new Date());
	final Date today = new Date(); //df4.parse(todayS);

	userManager uMgr = null;
	projectManager pjMgr = null;
	PstFlowStepManager fsMgr = null;

	PstUserAbstractObject thisPageUser = null;

	class WI
	{
		String _processName;
		String _header;
		String _itemName;
		String _status;
		String _executorIdS;
		String _requestorIdS;
		Date   _createDt;
		Date   _expireDt;
		Double _weight;
		String _wtUnit;

		PstAbstractObject _step;

		WI(String pName, String header, String item, String st, String executorIdS,
			String requestorIdS, Date createDt, Date expireDt, Double wt, String unit,
			PstAbstractObject step)
		{
			_processName	= pName;
			_header			= header;
			_itemName		= item;
			_status			= st;
			_executorIdS	= executorIdS;
			_requestorIdS	= requestorIdS;
			_createDt		= createDt;
			_expireDt		= expireDt;
			_weight			= wt;
			_wtUnit			= unit;
			_step			= step;
		}
	}

	// need to take consideration that we are groupBy project and then
	// groupBy executor.  Sorting is within the group.
	void sortBy(ArrayList<WI> wiList, int sortCol)
	{
		// only support Date and String sort now
		// sortArr = {null, "wn", "req", "st", "age", "ex", null};
		// 6=expireDt
		WI w1, w2;
		Object val1, val2;
		boolean isDateType = true;
		boolean swap;
		int beg, end = 0;		// begin and end index of a project group
		String currentGroupName;
		String currentExecutor;

		while (end < wiList.size()) {
			beg = end;
			currentGroupName = wiList.get(beg)._processName;
			currentExecutor  = wiList.get(beg)._executorIdS;
			for (int i=beg+1; i<wiList.size(); i++) {
				if (!wiList.get(i)._processName.equals(currentGroupName) ||
						!wiList.get(i)._executorIdS.equals(currentExecutor)) {
					break;	// found new set to be sorted
				}
				end = i;
			}

			do {
				swap = false;
				for (int i=beg; i<end; i++) {
					w1 = wiList.get(i);
					w2 = wiList.get(i+1);
					switch (sortCol) {
						case 0:		// process name
							return;

						case 1:		// task name
							val1 = w1._itemName;
							val2 = w2._itemName;
							isDateType = false;
							break;

						case 2:		// requestor
							val1 = getUserName(w1._requestorIdS);
							val2 = getUserName(w2._requestorIdS);
							isDateType = false;
							break;

						case 3:		// state
							val1 = w1._status;
							if (((String)val1).startsWith("On-")) val1 = "z";
							val2 = w2._status;
							if (((String)val2).startsWith("On-")) val2 = "z";
							isDateType = false;
							break;

						case 4:		// age
							val1 = w1._createDt;
							val2 = w2._createDt;
							break;

						///////////////////////////
						case 5:		// expireDt
							val1 = w1._expireDt;
							val2 = w2._expireDt;
							break;

						case 6:		// resource (executor)
						default:
							return;	// don't do it
					}

					try {
						if (isDateType) {
							// Date sort
							if ( val1==null || ((Date)val1).compareTo((Date)val2) > 0 ) {
								swap = true;
								wiList.set(i, w2);
								wiList.set(i+1, w1);
							}
						}
						else {
							// String sort
							if ( val1==null || ((String)val1).compareTo((String)val2) > 0 ) {
								swap = true;
								wiList.set(i, w2);
								wiList.set(i+1, w1);
							}
						}
					}
					catch (Exception e) {}
				}
			} while (swap);
			end++;
		}
	}	// END: sortBy()

	void groupBy(PstUserAbstractObject u, int [] idArr, String groupCol1, String groupCol2)
		throws PmpException
	{
		// each element in the array is a stepID
		// for each step, sort by groupCol1, then within each group, sort by groupCol2
		// for now only support ProgramID and CurrentExecutor

		// get all the step object first
		PstAbstractObject [] objArr = fsMgr.get(u, idArr);
		PstAbstractObject o1, o2;
		String [] nameArr = new String[idArr.length];	// remember project names
		String name1, name2;
		boolean swap;

		// sort by project name, put those w/o projectID at the end
		do {
			swap = false;
			for (int i=0; i<objArr.length-1; i++) {
				o1 = objArr[i];
				o2 = objArr[i+1];

				name1 = nameArr[i]==null?getProjectName(u, o1):nameArr[i];
				name2 = nameArr[i+1]==null?getProjectName(u, o2):nameArr[i+1];
				if (name1.compareToIgnoreCase(name2)>0) {
					swap = true;
					objArr[i] = o2;
					objArr[i+1] = o1;
					nameArr[i] = name2;
					nameArr[i+1] = name1;
				}
				else {
					// remember names
					if (nameArr[i] == null) nameArr[i] = name1;
					if (nameArr[i+1] == null) nameArr[i+1] = name2;
				}
			}
		} while (swap);

		// within each project group, sort by executor name
		// nameArr is group by project name now
		int beg, end = 0;		// begin and end index of a project group
		String currentGroupName;
		String [] execNameArr = new String[idArr.length];
		while (end < objArr.length) {
			beg = end;
			currentGroupName = nameArr[beg];
			for (int i=beg+1; i<nameArr.length; i++) {
				if (!nameArr[i].equals(currentGroupName)) {
					break;
				}
				end = i;
			}

			// sort owner name between beg and end
			do {
				swap = false;
				for (int i=beg; i<end; i++) {
					o1 = objArr[i];
					o2 = objArr[i+1];
					name1 = execNameArr[i]==null?getExecutorName(u, o1):execNameArr[i];
					name2 = execNameArr[i+1]==null?getExecutorName(u, o2):execNameArr[i+1];
					if (name1.compareToIgnoreCase(name2)>0) {
						swap = true;
						objArr[i] = o2;
						objArr[i+1] = o1;
						execNameArr[i] = name2;
						execNameArr[i+1] = name1;
					}
					else {
						// remember names
						if (execNameArr[i] == null) execNameArr[i] = name1;
						if (execNameArr[i+1] == null) execNameArr[i+1] = name2;
					}
				}
			} while (swap);
			end++;		// move to first element of next group
		}	// END: entire while loop to sort by owner within group

		// copy the sorted ids back
		for (int i=0; i<objArr.length; i++) {
			idArr[i] = objArr[i].getObjectId();
		}
	}	// END: groupBy()

	private String getProjectName(PstUserAbstractObject u, PstAbstractObject o)
		throws PmpException
	{
		String idS = (String)o.getAttribute("ProjectID")[0];
		if (idS == null) return LARGE_STR;	// make sure null is the biggest

		project pj = (project)pjMgr.get(u, Integer.parseInt(idS));
		return pj.getDisplayName();
	}

	private String getExecutorName(PstUserAbstractObject u, PstAbstractObject o)
		throws PmpException
	{
		String idS = (String)o.getAttribute("CurrentExecutor")[0];
		if (idS == null) return LARGE_STR;	// make sure null is the biggest

		user uObj = (user)uMgr.get(u, Integer.parseInt(idS));
		return uObj.getFullName();
	}

	private String getUserName(String uIdS)
	{
		String name = "";
		try {name = ((user)uMgr.get(thisPageUser, Integer.parseInt(uIdS))).getFullName();}
		catch (PmpException e) {}
		return name;
	}

	private String getAge(Date dt)
	{
		Date now = new Date();
		long diff = now.getTime() - dt.getTime();
		if (diff > 3*MONTH)
			return "> 3 mo's";
		else if (diff > 2*MONTH)
			return "3 mo's";
		else if (diff > MONTH)
			return "2 mo's";
		else if (diff > WEEK)
		{
			//return df1.format(dt);		// return a date
			java.text.DecimalFormat df = new java.text.DecimalFormat("#0.0");
			return df.format((double)diff/WEEK) + " wks";
		}
		else if (diff > DAY)
		{
			int i = (int)(diff/DAY);
			return String.valueOf(i) + " dys";
		}
		else {
			String dd = df5.format(dt);
			String nowD = df5.format(now);
			String ret = df2.format(dt);
			if (Integer.parseInt(nowD) > Integer.parseInt(dd))
				return "yesterday " + ret;
			else
				return "today " + ret;
		}
	}

	private String stepInfoLine (
		String label1, String id1, String value1,
		String label2, String id2, String value2)
	{
		StringBuffer sBuf = new StringBuffer(512);
		sBuf.append("<tr>");
		sBuf.append("<td class='plaintext' width='120'>" + label1 + "</td>");
		sBuf.append("<td class='plaintext'>:&nbsp;</td>");
		sBuf.append("<td class='plaintext' width='250' id='" + id1 + "'>"
				+ value1 + "</td>");

		if (label2 != null) {
			sBuf.append("<td class='plaintext' width='120'>" + label2 + "</td>");
			sBuf.append("<td class='plaintext'>:&nbsp;</td>");
			sBuf.append("<td class='plaintext' width='250' id='" + id2 + "'>"
					+ value2 + "</td>");
		}
		else {
			sBuf.append("<td></td><td></td><td></td>");
		}
		sBuf.append("</tr>");
		return sBuf.toString();
	}

	private String getDateString(PstAbstractObject obj, String attrName, String defaultStr)
		throws PmpException
	{
		String ret = defaultStr;
		Date dt = (Date)obj.getAttribute(attrName)[0];
		if (dt != null)
			ret = df1.format(dt);
		else if (ret.charAt(0) == '^') {
			ret = "<span style='color:#999999'>" + ret.substring(1) + "</span>";
		}
		return ret;
	}

	private String getColorState(String state, boolean bShowLabel)
	{
		StringBuffer sBuf = new StringBuffer(512);
		String titleS = "";

		sBuf.append("<img src='../i/");
		if (state.equals(FlowBase.ST_COMMIT))
		{
			sBuf.append("dot_green.gif");
			titleS = "approved";			// commit -> approved
		}
		else if (state.equals(FlowBase.ST_ABORT))
			sBuf.append("dot_redw.gif");
		else if (state.equals(FlowBase.ST_ACTIVE)) {
			sBuf.append("dot_lightblue.gif");
			titleS = "active/pending";
		}
		else if (state.equals(task.ST_LATE)) {
		// action and task are the same "Late"
			sBuf.append("dot_red.gif");
			titleS = "late";
		}
		else {
			sBuf.append("dot_black.gif");	// on-hold and others
			titleS = state;
		}
		sBuf.append("' title='" + titleS + "'/>");

		// show label
		if (bShowLabel) {
			sBuf.insert(0, "<table border='0' cellpadding='0' cellspacing='0'><tr><td>");
			sBuf.append("</td><td class='plaintext'>&nbsp;" + titleS + "</td></tr></table>");
		}

		return sBuf.toString();
	}

%>

<%
	String noSession = "../out.jsp?go=box/worktray.jsp";
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%

	////////////////////////////////////////////////////////
	final String LIGHT		= Prm.LIGHT;
	final String DARK		= Prm.DARK;

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	Logger l = PrmLog.getLog();
	String s;
	thisPageUser = pstuser;

	int uid = pstuser.getObjectId();
	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ( (iRole & user.iROLE_ADMIN) > 0 )
		isAdmin = true;

	// @ECC061907 to check if session is CR or PRM
	boolean isCRAPP = false;
	String app = (String)session.getAttribute("app");
	if (app.contains("CR"))
		isCRAPP = true;

	uMgr = userManager.getInstance();
	fsMgr = PstFlowStepManager.getInstance();
	pjMgr = projectManager.getInstance();

	taskManager tkMgr = taskManager.getInstance();
	resultManager rMgr = resultManager.getInstance();
	PstFlowManager fiMgr = PstFlowManager.getInstance();
	actionManager aMgr = actionManager.getInstance();
	historyManager hMgr = historyManager.getInstance();
	PstAbstractObject o;

	int myUid = pstuser.getObjectId();

	// selectedIdx record the step Id
	boolean bIdxSpecified = false;
	int selectedIdx = 0;	// selected work item to be shown
	s = request.getParameter("idx");
	if (s!=null) {
		bIdxSpecified = true;
		selectedIdx = Integer.parseInt(s);
	}

	// pass-in project id
	int sessPid = 0;
	boolean bNeedRefreshPlanHash = false;
	boolean bDisplayAllWI = false;
	String sessProjIdS = request.getParameter("projId");
	if (sessProjIdS == "")
		sessProjIdS = null;
	if (sessProjIdS == null) {
		sessProjIdS = "0";	//(String)session.getAttribute("projId");
	}
	sessPid = Integer.parseInt(sessProjIdS);
	if (sessPid==0 || sessPid==-1) {
		// came from home page, display workitems of ALL projects
		// but use proj of the first workItem on the list to begin
		bDisplayAllWI = true;
		if (sessPid == 0)
			sessProjIdS = null;
		session.removeAttribute("projId");
	}
	else {
		bNeedRefreshPlanHash = true;
	}

	// pass-in employee id
	int selectedUserId;
	s = request.getParameter("employeeId");
	if (s==null || s=="")
		selectedUserId = pstuser.getObjectId();
	else
		selectedUserId = Integer.parseInt(s);

	// by default only show open WI: filter by project state, see below
	boolean bShowAllWI = false;
	s = request.getParameter("all");		// showAll
	if (s != null) {
		bShowAllWI = true;
	}

	// flows
	PstAbstractObject step=null, flow, selectedFlowInstance = null;
	String exec = "";
	if (selectedUserId != -1) {
		exec += "CurrentExecutor='" + selectedUserId + "' && ";
	}
	exec += "State='" + PstFlowConstant.ST_STEP_ACTIVE + "'";

	int [] ids = null;
	int [] stepIdArr = null;

	if (sessPid == 0) {
		// display everything
		stepIdArr = fsMgr.findId(pstuser, exec);
		stepIdArr = project.filterMyProjectSteps(pstuser, stepIdArr);

		// filter out all on-hold projects
		if (!bShowAllWI) {
			stepIdArr = project.filterOnHoldSteps(pstuser, stepIdArr);
		}
	}
	else if (sessPid == -1) {
		// plan change workflow
		stepIdArr = fsMgr.findId(pstuser, exec
				+ " && ProjectID=null && CurrentExecutor='" + myUid + "'");
	}
	else {
		// display task steps for the selected project
		if (!bShowAllWI) {
			// filter this project if it is on-hold
			project pj = (project)pjMgr.get(pstuser, Integer.parseInt(sessProjIdS));
			if (pj.getState().equals(project.ST_ONHOLD)) {
				stepIdArr = new int[0];
			}
			else {
				stepIdArr  = null;
			}
		}
		if (stepIdArr == null) {
			stepIdArr  = fsMgr.findId(pstuser, exec + " && ProjectID='" + sessProjIdS + "'");
		}
	}
	//stepIdArr = Util2.mergeIntArray(ids, ids1);

	////////////////////////////////////////
	// do group by project then employee
	groupBy(pstuser, stepIdArr, "ProjectID", "Owner");

	int selectedIndexInArray = 0;
	if (selectedIdx<=0 && stepIdArr.length>0) {
		// if idx is <=0, then negate it and grep the step from the array
		selectedIdx = stepIdArr[-selectedIdx];
	}
	for (int i=0; i<stepIdArr.length; i++) {
		// selectedIdx is 0 if user did not choose a step on the list
		if (stepIdArr[i]==selectedIdx) {
			step = fsMgr.get(pstuser, stepIdArr[i]);
			selectedIndexInArray = i;
			break;
		}
	}

	if (step != null) {
		String flowInstanceName = (String)step.getAttribute("FlowInstanceName")[0];
		if (flowInstanceName != null) {
			selectedFlowInstance = fiMgr.get(pstuser, flowInstanceName);	// flow instance ID
		}

		// if proj is not selected, need to get proj from step
		if (sessProjIdS == null) {
			sessProjIdS = (String)step.getAttribute("ProjectID")[0];
			if (sessProjIdS != null)
				bNeedRefreshPlanHash = true;
		}
	}

	// show which panel
	int showPanel = 0;	// default to flow panel
	s = request.getParameter("pn");
	if (s!=null && s.equals("c"))
		showPanel = 1;	// show comment panel

	// change flow map?
	Boolean bSelect = null;
	String changeOption = request.getParameter("co");	
	if (changeOption != null)
		bSelect = new Boolean(true);

	Boolean bDraft = null;
	s = request.getParameter("df");
	if (s != null)
		bDraft = new Boolean(true);

	// either explicitly click "New Work Item" or return from changeProject() in doing new WI
	boolean isCreateWI = (request.getParameter("newwi") != null) ||
					((s=request.getParameter("type"))!=null && s.equals(action.TYPE_ACTION));

	// construct the flow map
	PrmDrawFlow.Flow fObj = null;
	int selectedFlowInstId = 0;
	if (selectedFlowInstance != null) {
		selectedFlowInstId = selectedFlowInstance.getObjectId();
//System.out.println("flow inst ID="+selectedFlowInstId);
		try {fObj = PrmDrawFlow.parseXMLtoFlow(pstuser,
				selectedFlowInstId, bSelect, bDraft);
		} catch (Exception e) {e.printStackTrace();}
	}
	String selectedflowName = "", htmlStr = "";
	if (fObj != null) {
		selectedflowName = fObj.getName();
		htmlStr = PrmDrawFlow.getFlowDisplayHTML(fObj);
//System.out.println("html=\n"+htmlStr);
	}
	// else it may or may not be project flow.  This will be determined later.

	// hashmap of taskID to taskName (w/ header no.)
	if (bNeedRefreshPlanHash) {
		// projId specified, need to refresh the hash
		Util3.refreshPlanHash(pstuser, session, sessProjIdS);
	}
	HashMap<String,String> taskNameMap =
		(HashMap<String,String>) session.getAttribute("taskNameMap");


	// sort workitem list
	String sortBy = request.getParameter("sort");
	if (sortBy == null) sortBy = "ex";

	// work task list window size
	int winHeight;
	if (stepIdArr.length <= 0)
		winHeight = 100;
	else
		winHeight = 250;

	////////////////////////////////////////////////////////
%>


<head>
<title>CW Work Tray</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<link href="../tab.css" rel="stylesheet" type="text/css">
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../forms.jsp" flush="true"/>
<script language="JavaScript" src="../get-date.js"></script>
<script type="text/javascript" src="../meeting/mtg1.js"></script>
<script type="text/javascript" src="../login_cookie.js"></script>
<script type="text/javascript" src="../resize.js"></script>

<script language="JavaScript">
<!--
var _curPanel = 0;
var _currentFlowChangeOption = "<%=changeOption%>";
var _selectedStepIdForChange = 0;	// select at change flow
var _clickedStepId;
var winCookieName = "worktrayWinHeight";
var divHeight = getCookie(winCookieName);

window.onload = function()
{
	show(parseInt("<%=showPanel%>"));
	if (<%=isCreateWI%>)
		location = "#wi";

	if (divHeight != null) {
		var e = document.getElementById("mtgText0");	// the DIV scroll window
		e.style.height = divHeight;
	}
	else {
		divHeight = <%=winHeight%>;
	}

	// to enable dragging editor box	
	setCookieName(winCookieName);
	initDrag(divHeight, 0);	
	new dragObject(handleBottom[0], null, new Position(0, <%=winHeight%>), new Position(0, 1000),
					null, BottomMove, null, false, 0);	
}

function showBlogEditor()
{
	var e = document.getElementById("blogEditor");
	if (e.style.display == "none")
	{
		e.style.display = "block";
		var ee = document.getElementById("noneText");
		if (ee != undefined)
			ee.innerHTML = "";
		ee = document.getElementById("blogText");
		ee.focus();
	}
	else
	{
		e.style.display = "none";
		var ee = document.getElementById("noneText");
		if (ee != undefined)
			ee.innerHTML = "&nbsp;&nbsp;None";
	}
}

function show(type)
{
	// click to show one of the three tabs
	var flow = document.getElementById("flowDiv");		// 0
	var blog = document.getElementById("commentDiv");	// 1
	var hist = document.getElementById("historyDiv");	// 2

	var tabId = "tab" + type;
	var pan = document.getElementById(tabId);
	if (pan == null) return;	// only happens when user has nothing to show

	pan.className='selected';
	if (_curPanel != type)
	{
		pan = document.getElementById("tab" + _curPanel);
		pan.className = "";
		_curPanel = type;
	}

	if (type == 0)
	{
		// flow panel
		flow.style.display = "block";
		blog.style.display = "none";
		hist.style.display = "none";
	}
	else if (type == 1)
	{
		// blog panel
		flow.style.display = "none";
		blog.style.display = "block";
		hist.style.display = "none";
	}
	else
	{
		// history panel
		flow.style.display = "none";
		blog.style.display = "none";
		hist.style.display = "block";
	}
}

function showTab(type)
{
	show(type);
	location = stripURLOption(parent.document.URL, "pn") + "#tab";
}

function changeFlow(opt)
{
	// when click to select ADD or DEL step
	// opt: add step; del step
	var fullURL = parent.document.URL;
	_selectedStepIdForChange = 0;		// reset
	var loc;
	if (opt == undefined)
	{
		// Cancel
		_currentFlowChangeOption = "";
		loc = stripURLOption(fullURL, "co");	// cancel change flow
	}
	else
	{
		_currentFlowChangeOption = opt;
		loc = addURLOption(fullURL, "co=" + opt);
	}
	location = loc + "#flowMap";
}

function changeAtStep(stepType, stepId)
{
	// when clicking a radio button on a step
	_selectedStepIdForChange = stepId;
	if (_currentFlowChangeOption == "del")
	{
		// enable OK button
		disableChangeOKButton(false);
	}
	else if (_currentFlowChangeOption == "add")
	{
		// depending on begin, end or inbetween step, display the option of adding
		disableChangeOKButton(true);
		e = document.getElementById("addOption");
		e.style.display = "block";
		var msg = "</p>";
		var chkBefore = "&nbsp;&nbsp;&nbsp;<input type='radio' name='addStepPos' value='before' onClick='disableChangeOKButton(false);'>Add a new task before the selected task</option>";
		var chkAfter = "&nbsp;&nbsp;&nbsp;<input type='radio' name='addStepPos' value='after' onClick='disableChangeOKButton(false);'>Add a new task after the selected task</option>";
		var chkParellel = "&nbsp;&nbsp;&nbsp;<input type='radio' name='addStepPos' value='parellel' onClick='disableChangeOKButton(false);'>Add a new task parellel to the selected task</option>";

		if (stepType == "<%=PrmDrawFlow.Step.TYPE_BEGIN%>")
		{
			// can only add after
			msg += chkAfter + "</br>" + chkParellel;
		}
		else if (stepType == "<%=PrmDrawFlow.Step.TYPE_END%>")
		{
			// can only add before
			msg += chkBefore + "</br>" + chkParellel;
		}
		else
		{
			// can add before and after
			msg += chkBefore + "</br>" + chkAfter + "</br>" + chkParellel;
		}
		e.innerHTML = msg;
	}
}

function disableChangeOKButton(TorF)
{
	var e = document.getElementById("changeOKButton");
	e.disabled = TorF;		// true/false
}

function changeFlowOnOK()
{
	// Click OK button to start add (or del) of step
	var f = document.changeFlowForm;
	f.op.value = _currentFlowChangeOption;	// add or del (step)
	f.stepId.value = _selectedStepIdForChange;
	if (_currentFlowChangeOption == "add")
	{
		for (var i=0; i<f.addStepPos.length; i++)
		{
			if (f.addStepPos[i].checked)
			{
				f.addPosition.value = f.addStepPos[i].value;	// use only when add
				break;
			}
		}
	}
	f.submit();
}

function onClickStep(stepInfo)
{
	// when step is clicked, display the step info
	//_clickedStepId = stepId;
	//alert(stepInfo);
	var stepInfoArr = stepInfo.split(";");
	var key, val, e;
	for (i=0; i<stepInfoArr.length; i++)
	{
		pair = stepInfoArr[i].split(" = ");
		key = pair[0];
		val = pair[1];
		e = null;
		if (key == "<%=FlowBase.NAME%>")
		{
			e = document.getElementById("workTaskName");
		}
		else if (key == "<%=FlowBase.STATE%>")
		{
			if (val == "") val = "Not Started";
			e = document.getElementById("stateVal");
		}
		else if (key == "<%=FlowBase.CREATED%>")
		{
			if (val == "") val = "N/A";
			e = document.getElementById("createdDtVal");
		}
		else if (key == "<%=FlowBase.CREATOR%>")
		{
			if (val == "") val = "N/A";
			e = document.getElementById("creatorVal");
		}
		else if (key == "<%=FlowBase.EXPIRE%>")
		{
			if (val == "") val = "N/A";
			e = document.getElementById("expireDtVal");
		}
		else if (key == "<%=FlowBase.OUTSTEP%>")
		{
			if (val == "") val = "None";
			e = document.getElementById("outStepVal");
		}
		else if (key == "<%=FlowBase.ASSIGN%>")
		{
			if (val == "") val = "None";
			if (val == "<%=FlowBase.DUMMY%>") val = "<%=FlowBase.DUMAUTO%>";
			e = document.getElementById("assignToVal");
		}
		else if (key == "<%=FlowBase.WORKBY%>")
		{
			if (val == "") val = "None";
			e = document.getElementById("workByVal");
		}

		if (e != undefined)
			e.innerHTML = val;
	}
}

// commit, abort steps and post new blog
function submitForm(type, stepId, ff)
{
	var f;
	if (ff != null)
		f = ff;		// pass in a form
	else
		f = document.taskStepForm;

	if (type == "commit") {
		// commit the task step and move the task to Completed
		if (!confirm("Are you sure you want to commit this work item "
				+ "and move this task to the COMPLETED state?"))
			return;

		var temp = stripURLOption(parent.document.URL, "pn");	// strip pn and anchor
		f.backPage.value = stripURLOption(temp, "idx");			// committed and gone
		f.blogText.value = getBlogText(f);	// get blog text

		// handle the commit
	}
	else if (type == "abort") {
		// abort the task step and move the task to Cancel
		if (!confirm("Are you sure you want to abort this work item "
				+ "and move this task to the CANCELED state?"))
			return;

		var temp = stripURLOption(parent.document.URL, "pn");	// strip pn and anchor
		f.backPage.value = stripURLOption(temp, "idx");			// aborted and gone
		f.blogText.value = getBlogText(f);	// get blog text

		// handle the abort
	}
	else if (type == "save") {
		// save the blog to the task (or workflow)
		// open the tab on my return
		var text = getBlogText(f);
		if (text == "") {
			// no text, no need to go on
			alert("Please enter some blog text before Save.");
			f.blogText.focus();
			return;
		}
		f.blogText.value = text;
		if (ff != null) {
			type = "addBlog";	// save blog for workflow
		}
		else {
			// save task blog, need to come back with exactly the same params
			f.backPage.value = stripURLOption(parent.document.URL, "pn");	// strip pn and anchor
		}
	}

	f.op.value = type;		// commit, abort or save

	if (ff == null) {
		// task step
		f.stepId.value = stepId;

		// override send email on post blog
		var e = document.getElementById("sendEmail");
		if (e.checked) {
			f.forceSendEmail.value = "true";
		}
		else {
			f.forceSendEmail.value = "false";
		}
	}

	f.submit();
}

function getBlogText(f)
{
	var text = trim(f.blogText.value);
	if (text == "")
		text = trim(document.addBlogForm.blogText.value);
	return text;
}

function resetAC()
{
	// reset button for new action item
	addActionForm.Description.value = '';

	var e = addActionForm.Responsible;
	getall(e);
	swapdata(e, addActionForm.Selected);

	e = addActionForm.Owner;
	for(j = 0; j < e.length; j++)
	{
		if (e.options[j].value == '<%=myUid%>')
			e.options[j].selected = true;
		else
			e.options[j].selected = false;
	}

	addActionForm.Priority[1].selected = true;	// medium

	addActionForm.Expire.value = '<%=todayS%>';

}

function validation()
{
	// for add, update and commit action item
	// post to post_mtg_upd2.jsp (should refactor to action or use post_updaction.jsp)
	var f = addActionForm;

	// check for action item
	if (f.Description.value == '')
	{
		fixElement(f.Description,
			"Please make sure that the DESCRIPTION field is properly completed.");
		return false;
	}
	else if (f.Description.value.length > 255)
	{
		s = "The " + currentType + " is " + f.Description.value.length
			+ " characters long that is longer than the max allowed length (255), please shorten the description or break the item into multiple items.";
		fixElement(f.Description, s);
		return false;
	}

	for (i=0;i<f.Description.value.length;i++) {
		char = f.Description.value.charAt(i);
		if (char == '\\') {
			fixElement(f.Description,
				"DESCRIPTION cannot contain this character: \n  \\");
			return false;
		}
	}

	// create a new action item
	getall(f.Responsible);
}

function changeProject()
{
	// action item change project association
	// this is changing the project team select box at the bottom (where user adds an item)
	addActionForm.action = "worktray.jsp";
	addActionForm.method = "get";

	addActionForm.type.value = addActionForm.Type.value;
	copySelectValue(addActionForm.projId, addActionForm.pid);	// for the team member
	addActionForm.submit();
}

function popup_cal()
{
	// action item expire time
	show_calendar('addActionForm.Expire');
}

function sort(type)
{
	// label button: sort workitem list
	var loc = addURLOption(parent.document.URL, "sort=" + type);
	location = loc;
}

function showIdx(stepId)
{
	loc = stripURLOption(parent.document.URL, "newwi");
	location = addURLOption(loc, "idx=" + stepId + "#wi");
}

function toggleShowWI()
{
	// show only Open Items?
	var e = document.getElementById('showWI');
	var loc;
	if (e.checked) {
		loc = stripURLOption(parent.document.URL, "all");
	}
	else {
		loc = addURLOption(parent.document.URL, "all=1");
	}
	location = loc;
}

function showItem(n)
{
	if (n >= 0) {
		showIdx(-n);
	}
}

//-->
</script>

<style type="text/css">
.sd {font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 10px; color: #333333; width:143px; line-height: 20px; text-align:center; vertical-align:top;}
.blueNormal {font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 11px; color: #336699; line-height: 16px}
</style>

</head>

<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0" >
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
						<td align="left" valign="bottom" class="head">
							<b>Work Tray</b>
						</td>
<%	if (!bDisplayAllWI && sessProjIdS!=null) { %>
						<td width='245'>
						<img src='../i/bullet_tri.gif' width='20' height='10'>
						<a class='listlinkbold' href='../plan/timeline.jsp?projId=<%=sessProjIdS%>'>Timeline</a>
						<br />
						<img src='../i/bullet_tri.gif' width='20' height='10'>
						<a class='listlinkbold' href='../project/task_updall.jsp?projId=<%=sessProjIdS%>'>Update All Tasks</a>
	            		</td>
<%	} %>
	            	</tr>
	            	<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>
	            </table>
	          </td>
	        </tr>
</table>

<table width="90%" border="0" cellspacing="0" cellpadding="0">	        
			<tr>
          		<td width="100%">
<!-- Navigation Menu -->
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Project" />
				<jsp:param name="subCat" value="Worktray" />
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
				<td width="20"><img src="../i/spacer.gif" width="5" border="0"></td>
				<td>

<form>
	<table width="90%" border='0' cellpadding="0" cellspacing="0">
	<tr>
		<td><img src='../i/spacer.gif' width='15'/></td>

<!-- Project Name -->
		<td class="plaintext_big" width='380'>
			Project Name:&nbsp;&nbsp;
			<select name="projId" class="formtext" onchange="submit()">
			<option value='0'>- all projects -</option>
<%
		// display plan change workflow steps
		out.print("<option value='-1' ");
		if (sessPid == -1) out.print("selected");
		out.print(">None</option>");

		// display the select box
		out.print(Util.selectProject(pstuser, sessPid));
%>
			</select>
		</td>

<!-- Employee -->
		<td class='plaintext_big' width='300'>
			Employee:&nbsp;&nbsp;
			<select class="formtext" name="employeeId" onchange='submit()'>
			<option value='-1'>- all employees -</option>
<%

			// all project team people
			PstAbstractObject [] teamMember;
			if (!bDisplayAllWI && sessProjIdS!=null) {
				project sessionProj = (project)pjMgr.get(pstuser, Integer.parseInt(sessProjIdS));
				teamMember = ((user)pstuser).getTeamMembers(sessionProj);
			}
			else {
				ids = uMgr.findId(pstuser,
						"Company='" + (String)pstuser.getAttribute("Company")[0] + "'");
				teamMember = uMgr.get(pstuser, ids);
				Util.sortUserArray(teamMember, true);
			}
			out.print(Util.selectMember(teamMember, selectedUserId));

%>
		</select>
		</td>

<!-- Show Open Items Only -->
		<td class='plaintext_big' align='right'>
			<input type='checkbox' id='showWI'
				onClick='javascript:toggleShowWI();'
				<%if (!bShowAllWI) {out.print(" checked");}%>>Open Item Only
		</td>
	</tr>
	</table>
</form>

<!-- *************************   Page Headers   ************************* -->

<!-- LABEL -->
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<%
	// if there is no work items at all, just return
	if (stepIdArr.length<=0 && !isCreateWI) {
		out.print("<tr><td colspan='2'><img src='../i/spacer.gif' height='5'/></td></tr>");
		out.print("<tr><td class='message' colspan='2'><img src='../i/spacer.gif' width='30'/>This employee has no work items.</td></tr>");
		out.print("<tr><td>");
%>
<jsp:include page='../foot.jsp' flush='true'/>
<%
		out.print("</td></tr></table></body></html>");
		return;
	}
%>
<tr>
<td><img src='../i/spacer.gif' width='15'/></td>

<td class='plaintext'>
      &nbsp;Total (<b><%=stepIdArr.length%></b>) work items
      <table width="90%" border="0" cellspacing="0" cellpadding="0">

<!-- List my work items -->
		<tr>
			<td>
<%
		out.print("<div class='scroll' id='mtgText0' style='height:" + winHeight + "px;width:100%;");
		out.print("overflow-X:hidden;padding:2px;padding-top:0px;border:1px solid #909090;'>");


		// display all of my unfinished work items by default

		String [] label0 = {"&nbsp;Project / Process", "Task",
				"Requester", "State", "Age", "Deadline", "Resource"};
		String [] sortArr = {null, "wn", "req", "st", "age", "ex", null};
		int [] labelLen0 = {340, 330, 90, 30, 90, 90, 90};
		boolean [] bAlignCenter0 = {false, true, false, true, true, true, true};
		out.print(Util.showLabel(label0, null, sortArr, sortBy,
			labelLen0, bAlignCenter0, true));	// sort, showAll and align center

		int iSortBy = 5;	// default to "ex": 5 in sortArr
		for (int i=0; i<sortArr.length; i++) {
			if (sortArr[i]!=null && sortArr[i].equals(sortBy)) {
				iSortBy = i;
				break;
			}
		}

		String bgcolor="";
		boolean even = false;
		String flowName, wTaskName, sExecutor, sExecutorIdS,
				sCreator, sCreatorIdS, ageS, state, headerNum;
		String expireDtS;
		String imgS, begB, endB;
		PstAbstractObject selectedStep = null;
		String selectedWorkTaskName = "";
		String selectedTaskHeaderNum = "";
		String stepType;
		boolean isWorkFlowStep, isTaskStep, isActionStep;
		String actionDesc, optStr="", optAttr="", optUnit="", lastPjIdS="";
		Date expireDt=null, createDt;
		user u;
		int idx;
		int stepDisplayCount = 0;
		int pjOwnerId = 0;
		Double weightDbl;
		String wtUnit;
		int actionNum = 1;

		ArrayList<WI> wiList = new ArrayList<WI>(stepIdArr.length);

		// ids is the array of step instances I am showing
		// it is sorted by (group by) project
		// TODO: since it is sorted, we can remember the last project for faster performance
		for (int i=0; i<stepIdArr.length; i++)
		{
			try {step = fsMgr.get(pstuser, stepIdArr[i]);}
			catch (Exception e) {
				System.out.println("Fail to get step [" + stepIdArr[i] + "]");
				//e.printStackTrace();
				continue;
			}

			// step type
			stepType = (String) step.getAttribute("Type")[0];
			isWorkFlowStep = isTaskStep = isActionStep = false;
			if (stepType.equals(PstFlowStep.TYPE_ACTION)) {
				isActionStep = true;
			}
			else if (stepType.equals(PstFlowStep.TYPE_PROJTASK)) {
				isTaskStep = true;
			}
			else {
				isWorkFlowStep = true;
			}

			// flow definition name
			String flowInstanceName = (String)step.getAttribute("FlowInstanceName")[0];
			if (flowInstanceName != null) {
				flow = fiMgr.get(pstuser, flowInstanceName);	// flow instance ID
				flowName = (String)flow.getAttribute(PstFlow.ATTR_FLOWDEF_NAME)[0];
			}
			else {
				flowName = null;
			}

			headerNum = "";
			weightDbl = null;
			wtUnit = null;

			if (isWorkFlowStep) {
				// regular workflow step
				wTaskName = (String)step.getAttribute("FlowStepDefName")[0];
				expireDt = (Date)step.getAttribute("ExpireDate")[0];
			}
			else {
				// project step or action step
				flowName = wTaskName = "-";	// initialize
				String pjIdS = (String)step.getAttribute("ProjectID")[0];
				if (pjIdS != null) {
					project pj;
					try {pj = (project)pjMgr.get(pstuser, Integer.parseInt(pjIdS));}
					catch (PmpException e) {
						// clean up by removing this step
						l.warn("Step [" + step.getObjectId()
									  + "] has project ID [" + pjIdS
									  + "] that does not exist.  Remove step.");
						fsMgr.delete(step);
						continue;
					}
					flowName = pj.getDisplayName();

					if (isTaskStep && taskNameMap!=null) {
						// task step
						// display the task header no. and task name
						String tidS = (String)step.getAttribute("TaskID")[0];
						o = tkMgr.get(pstuser, tidS);
						wTaskName = taskNameMap.get(tidS);
						if (wTaskName == null) {
							Util3.refreshPlanHash(pstuser, session, pjIdS);
							taskNameMap =
								(HashMap<String,String>) session.getAttribute("taskNameMap");
							wTaskName = taskNameMap.get(tidS);
						}
						if (wTaskName!=null &&
							(idx = wTaskName.indexOf(' ')) != -1) {
							headerNum = wTaskName.substring(0, idx);
							wTaskName = wTaskName.substring(idx+1);	// name only
						}
						expireDt = (Date)o.getAttribute("ExpireDate")[0];

						// for task step, check for resource management
						if (!pjIdS.equals(lastPjIdS)) {
							optStr = pj.getOption(project.OP_RESOURCE_MGMT);
							if (optStr != null) {
								String [] sa = optStr.split(project.DELIMITER2);
								optAttr = sa[0];
								optUnit = sa[1];
							}
						}
						if (!Util.isNullString(optStr)) {
							weightDbl = (Double)o.getAttribute(optAttr)[0];
							wtUnit = optUnit;
						} else {
							weightDbl = null;
							wtUnit = null;
						}
					}
					if (wTaskName == null)
						wTaskName = "-";

					lastPjIdS = pjIdS;		// remember for optimization
				}	// END: if pjIdS != null
				else {
					if (isActionStep)
						flowName = "Action item (no project)";
					else
						flowName = "-";
				}

				if (isActionStep) {
					// action step
					headerNum = "A." + actionNum++;
					wTaskName = (String)step.getAttribute("TaskID")[0];	// actionID
					o = aMgr.get(pstuser, wTaskName);
					wTaskName = (String)o.getAttribute("Subject")[0];
					if (wTaskName == null) {
						l.error("Found an empty action [" + o.getObjectId() + "] - performed clean up.");
						aMgr.delete(o);
						continue;
					}
					if (wTaskName.length() > 100)
						wTaskName = wTaskName.substring(0, 65) + " ...";
					expireDt = (Date)o.getAttribute("ExpireDate")[0];
				}
			}	// END else

			// gather step info for display
			sCreatorIdS = (String)step.getAttribute("Owner")[0];	// it's name: should store ID
			if ((sExecutorIdS = (String)step.getAttribute("CurrentExecutor")[0]) == null)
				sExecutorIdS = "";
			createDt = (Date)step.getAttribute("CreatedDate")[0];
			state = (String)step.getAttribute("State")[0];
			s = project.getStepProjectState(pstuser, step);
			if (s!=null && s.equals(project.ST_ONHOLD)) {
				// !! simply use the project state because step doesn't have on-hold state
				state = project.ST_ONHOLD;
			}

			// pesimistic: show LATE if it expire today
			else if (state.equals(FlowBase.ST_ACTIVE) &&
					expireDt!=null && !expireDt.after(today)) {
					state = task.ST_LATE;	// action & task are the same
			}

			// construct WI
			WI w = new WI(flowName, headerNum, wTaskName, state,
				sExecutorIdS, sCreatorIdS, createDt, expireDt, weightDbl, wtUnit,
				step);
			wiList.add(w);
		}	// END: for each step


		/////////////////////////////////////////////////////////////////////
		// sort
		// by default sort by deadline
		sortBy(wiList, iSortBy);

		/////////////////////////////////////////////////////////////////////
		// display the work item list
		int stepId;
		String lastFlowName = "";
		String lastExecutorIdS = "";
		boolean isNewProject;
		String weightS;
		Double userTotalWt=null, pjTotalWt=null;
		WI lastW = null;

		for (int i=0; i<wiList.size(); i++) {
			WI w = wiList.get(i);
			flowName = w._processName;
			headerNum = w._header;
			wTaskName = w._itemName;
			state = w._status;
			sCreatorIdS = w._requestorIdS;
			sExecutorIdS = w._executorIdS;
			createDt = w._createDt;
			expireDt = w._expireDt;
			if (w._weight != null) {
				weightS = dcf.format(w._weight);	// + " " + w._wtUnit;
			}
			else {
				weightS = "";
			}
			step = w._step;

			stepId = step.getObjectId();
			if (!bIdxSpecified && i==0) {
				selectedIdx = stepId;
			}

			if (!isCreateWI && selectedIdx==stepId)
			{
				selectedStep = step;
				selectedWorkTaskName = wTaskName;
				selectedTaskHeaderNum = headerNum;
				begB = "<b>";
				endB = "</b>";
			}
			else {
				begB = endB = "";
			}

			////////////////////////////////////////
			// start a new flow/project
			isNewProject = false;
			if (!flowName.equals(lastFlowName)) {
				// project / process name
				isNewProject = true;
				if (lastFlowName != "") {
					// output the last executor total weight
					if (userTotalWt != null) {
						out.print("<tr " + bgcolor + "><td colspan='15'></td>");
						out.print("<td colspan='6'><hr/></td></tr>");
						out.print("<tr " + bgcolor + ">");
						out.print("<td colspan='19' class='plaintext_bold' align='right'>Subtotal:</td>");
						out.print("<td colspan='2' class='plaintext' align='center'>"
								+ dcf.format(userTotalWt) + " " + lastW._wtUnit + "</td></tr>");
						out.print("<tr " + bgcolor + "><td colspan='15'></td>");
						out.print("<td colspan='6'><hr/></td></tr>");
						userTotalWt = null;		// reset
					}

					// output the project total weight
					if (pjTotalWt != null) {
						out.print("<tr " + bgcolor + ">");
						out.print("<td colspan='19' class='plaintext_bold' align='right'>Project total:</td>");
						out.print("<td colspan='2' class='plaintext' align='center'>"
								+ dcf.format(pjTotalWt) + " " + lastW._wtUnit + "</td></tr>");
						out.print("<tr " + bgcolor + "><td colspan='15'></td>");
						out.print("<td colspan='6'><hr/></td></tr>");
						pjTotalWt = null;		// reset
					}

					// add a horizontal gap line between projects
					out.print("<tr " + bgcolor + "><td colspan='20'><img src='../i/spacer.gif' height='15'/></td></tr>");
				}
				// a dark thin line to separate projects
				out.print("<tr bgcolor='#cccccc'><td colspan='20'><img src='../i/spacer.gif' height='2'/></td></tr>");

				out.print("<tr bgcolor='#eeeeee' height='20'>");
				out.print("<td></td>");
				out.print("<td colspan='19' valign='top'><table border='0' cellspacing='0' cellpadding='0'><tr>");
				out.print("<td><img src='../i/spacer.gif' width='8'/></td>");
				out.print("<td class='plaintext'><b>" + flowName + "</b></td>");
				out.print("</tr></table></td><tr>");

				lastFlowName = flowName;
			}

			// flow step executor
			try {
				u = (user)uMgr.get(pstuser, Integer.parseInt(sExecutorIdS));
				sExecutor = u.getShortName();
			}
			catch (Exception e) {
				sExecutor = "None";
			}

			////////////////////////////////////////
			// start a new executor
			if (!sExecutorIdS.equals(lastExecutorIdS) || isNewProject) {
				// output the last executor's total weight
				if (userTotalWt != null && !isNewProject) {
					// output the last executor weight
					out.print("<tr " + bgcolor + "><td colspan='15'></td>");
					out.print("<td colspan='6'><hr/></td></tr>");
					out.print("<tr " + bgcolor + ">");
					out.print("<td colspan='19' class='plaintext_bold' align='right'>Subtotal:</td>");
					out.print("<td colspan='2' class='plaintext' align='center'>"
							+ dcf.format(userTotalWt) + " " + lastW._wtUnit + "</td></tr>");
					out.print("<tr " + bgcolor + "><td colspan='15'></td>");
					out.print("<td colspan='6'><hr/></td></tr>");
					userTotalWt = null;		// reset
				}

				out.print("<tr " + LIGHT + ">");		// always LIGHT on executor line
				out.print("<td colspan='17'><img src='../i/spacer.gif' height='20'/></td>");
				out.print("<td colspan='2'></td>");
				out.print("<td class='plaintext' align='center' valign='baseline' width='100'>");
				out.print("<a href='../ep/ep1.jsp?uid=" + sExecutorIdS + "'><u>"
						+ begB + sExecutor + endB + "</u></a>");
				out.print("</td></tr>");

				even = true;	// following line is DARK
				lastExecutorIdS = sExecutorIdS;
			}

			if (w._weight != null) {
				if (userTotalWt == null) {
					userTotalWt = 0.0;
					if (pjTotalWt == null) {
						pjTotalWt = 0.0;
					}
				}
				userTotalWt += w._weight;
				pjTotalWt   += w._weight;
			}

			if (even)
				bgcolor = DARK;
			else
				bgcolor = LIGHT;
			even = !even;

			////////////////////////////////////////
			// task/step details
			out.print("<tr " + bgcolor + ">");

			// header no.
			out.print("<td colspan='5'><table border='0' cellspacing='0' cellpadding='0'><tr>");
			out.print("<td><img src='../i/spacer.gif' width='40' height='20'/></td>");
			if (begB != "") {
				out.print("<td valign='middle'><img src='../i/bullet_tri.gif'/></td>");
			}
			else {
				out.print("<td><img src='../i/spacer.gif' width='15' height='1'/></td>");
			}
			out.print("<td class='plaintext' width='40' align='left' valign='middle'>");
			out.print("<a href='javascript:showIdx(" + stepId + ");'>"
						+ begB + headerNum + endB + "</a></td>");

			// work item name
			out.print("<td class='plaintext' align='left' valign='middle'>");
			out.print("<a href='javascript:showIdx(" + stepId + ");'>" + begB + wTaskName + endB + "</a>");
			out.print("</td></tr></table></td>");

			// flow step creator (requestor)
			u = (user)uMgr.get(pstuser, Integer.parseInt(sCreatorIdS));
			sCreator = u.getShortName();
			out.print("<td colspan='2'></td>");
			out.print("<td class='plaintext' align='center' valign='middle'>");
			out.print("<a href='../ep/ep1.jsp?uid=" + sCreatorIdS + "'>" + sCreator + "</a>");
			out.print("</td>");

			// status
			out.print("<td colspan='2'></td>");
			out.print("<td class='plaintext' align='center' valign='middle'>");
			out.print(getColorState(state, false));
			out.print("</td>");

			// age
			ageS = getAge(createDt);
			out.print("<td colspan='2'></td>");
			out.print("<td class='plaintext' align='center' valign='middle'>" + ageS + "</td>");

			// deadline
			if (expireDt != null)
				expireDtS = df1.format(expireDt);
			else
				expireDtS = "-";
			out.print("<td colspan='2'></td>");
			out.print("<td class='plaintext' align='center' valign='middle'>" + expireDtS + "</td>");

			// resource weight
			out.print("<td colspan='2'></td>");
			out.print("<td class='plaintext' align='center' valign='middle'>");
			out.print(weightS);	// # of hrs/week
			out.print("</td>");

			out.print("</tr>");
			lastW = w;
			stepDisplayCount++;
		}	// END: for displaying step list

		// output weight total for last person and project
		if (userTotalWt != null) {
			out.print("<tr " + bgcolor + "><td colspan='15'></td>");
			out.print("<td colspan='6'><hr/></td></tr>");
			out.print("<tr " + bgcolor + ">");
			out.print("<td colspan='19' class='plaintext_bold' align='right'>Subtotal:</td>");
			out.print("<td colspan='2' class='plaintext' align='center'>"
					+ dcf.format(userTotalWt) + " " + lastW._wtUnit + "</td></tr>");
			out.print("<tr " + bgcolor + "><td colspan='15'></td>");
			out.print("<td colspan='6'><hr/></td></tr>");
			userTotalWt = null;		// reset
		}

		// output the project total weight
		if (pjTotalWt != null) {
			out.print("<tr " + bgcolor + ">");
			out.print("<td colspan='19' class='plaintext_bold' align='right'>Project total:</td>");
			out.print("<td colspan='2' class='plaintext' align='center'>"
					+ dcf.format(pjTotalWt) + " " + lastW._wtUnit + "</td></tr>");
			out.print("<tr " + bgcolor + "><td colspan='15'></td>");
			out.print("<td colspan='6'><hr/></td></tr>");
			pjTotalWt = null;		// reset
		}

		out.println("</table></div>");	// close the table of showLabel()
%>
		<div align='right'>
		<span id='handleBottom0' ><img src='../i/drag.gif' style='cursor:s-resize;'/></span>
		<span><img src='../i/spacer.gif' width='15' height='1'/></span>
		</div>

			</td>
		</tr>
		<tr><td><img src='../i/spacer.gif' height='5'/></td></tr>
		<tr>
			<td>
<table>
	<tr>
		<td class="tinytype" align="center">Work Item Status:
			&nbsp;&nbsp;<img src="../i/dot_lightblue.gif">Active & Pending
			&nbsp;&nbsp;<img src="../i/dot_green.gif">Approved
			&nbsp;&nbsp;<img src="../i/dot_redw.gif">Rejected
			&nbsp;&nbsp;<img src="../i/dot_red.gif">Late
			&nbsp;&nbsp;<img src="../i/dot_cancel.gif">Canceled
			&nbsp;&nbsp;<img src="../i/dot_black.gif">Closed
		</td>
	</tr>
</table>
			</td>
		</tr>
<!-- End of list work items -->


<!-- Work item details -->
<%
String pjState = "";	// associated project state (track on-hold project case)

if ((stepDisplayCount>0 && selectedStep!=null) || isCreateWI) {

	// this can either be a regular workflow step or a project task step
	// or creating a new work item
	user uObj;
	String createdDateS="", expireDateS="", creator="", currentExecutor="";
	String assignTo = "";
	String nextStepName = null;
	String selectedPjIdS = null;
	project selectedProj = null;
	String selectedTaskId = null;
	task selectedTask = null;
	int selectedStepId = 0;
	isWorkFlowStep = isTaskStep = isActionStep = false;		// now display the selected step
	boolean bUserCanExecute = false;

	if (!isCreateWI) {
		if (selectedStep==null) {
			selectedStep = wiList.get(0)._step;
		}
		selectedStepId = selectedStep.getObjectId();
		selectedTaskId = (String)selectedStep.getAttribute("TaskID")[0];// flowInst, task or action ID

		// step type
		stepType = (String)selectedStep.getAttribute("Type")[0];
		if (stepType.equals(PstFlowStep.TYPE_ACTION)) {
			isActionStep = true;
		}
		else if (stepType.equals(PstFlowStep.TYPE_PROJTASK)) {
			isTaskStep = true;
			selectedTask = (task)tkMgr.get(pstuser, selectedTaskId);
		}
		else {
			isWorkFlowStep = true;
		}

		createdDateS = df3.format((Date)selectedStep.getAttribute("CreatedDate")[0]);
		expireDt = (Date)selectedStep.getAttribute("ExpireDate")[0];
		if (expireDt != null)
			expireDateS = df1.format(expireDt);
		else
			expireDateS  = "N/A";

		creator = (String)selectedStep.getAttribute("Owner")[0];
		if (creator == null)
			creator = "";
		else {
			uObj = (user)uMgr.get(pstuser, Integer.parseInt(creator));
			creator = "<a href='../ep/ep1.jsp?uid=" + creator + "'>"
					+ uObj.getFullName() + "</a>";
		}

		state = (String)selectedStep.getAttribute("State")[0];

		// get the step definition to get the next step name
		if (isWorkFlowStep) {
			// workflow step
			String flowInstanceName = (String)selectedStep.
										getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0];
			if (flowInstanceName == null) {
				l.error("Flow instance should not be null for workflow step [" + selectedStepId + "]");
				throw new PmpException();
			}
			PstFlow flowInstance = (PstFlow)fiMgr.get(pstuser, flowInstanceName);
			String flowXML = ((PstFlowStep)selectedStep).getFlowXML(pstuser);
			HashMap<String,String> stepHash =
				PstUtil.getStepAttributeHashFromXML(
						flowXML, (String)selectedStep.getAttribute(PstFlowStep.FLOW_STEP_DEF_NAME)[0]);
			nextStepName = PstUtil.getStepAttribute(stepHash, PstFlowConstant.STEP_OUTSTEP);
			if (nextStepName == null)
				nextStepName = "None";
		}
		else if (isTaskStep) {
			// task step
			if (project.getStepProjectState(pstuser, selectedStep).equals(project.ST_ONHOLD)) {
				// !! simply use the project state because step doesn't have on-hold state
				state = pjState = project.ST_ONHOLD;
			}
			// pessimistic: if expireDate is today, consider LATE
			if (expireDt == null)
				expireDt = selectedTask.getExpireDate();
			if (expireDt!=null && !expireDt.after(today)) {
				state = task.ST_LATE;
			}
		}
		else {
			// action step
			selectedWorkTaskName = "Action item";
		}
	}
	else {
		// create new work item (action step)
		bUserCanExecute = true;
		selectedWorkTaskName = "New work request";
		state = "new";	//PstFlowStep.ST_STEP_NEW;
		createdDateS = df3.format(new Date());
			creator = "<a href='../ep/ep1.jsp?uid=" + myUid + "'>"
					+ ((user)pstuser).getFullName() + "</a>";
	}

	out.print("<tr><td><table width='100%' border='0' cellspacing='0' cellpadding='0'>");
	out.print("<tr><td><img src='../i/spacer.gif' height='30'/><a name='wi'></a></td>");
	if (!isCreateWI && stepDisplayCount>0) {
		out.print("<td align='right'><table border='0' cellspacing='0' cellpadding='0'><tr>");
		if (selectedIndexInArray > 0)
			out.print("<td><a href='javascript:showItem(" + selectedIndexInArray + "-1);'>&lt;</a></td>");
		out.print("<td class='plaintext'>&nbsp;"
					+ (selectedIndexInArray+1) + " of " + stepDisplayCount + "&nbsp;</td>");
		if (selectedIndexInArray < stepDisplayCount-1)
			out.print("<td><a href='javascript:showItem(" + selectedIndexInArray + "+1);'>&gt;</a></td>");
		out.print("</tr></table></td>");
	}
	out.print("</tr></table></td></tr>");

	// surrounding table
	out.println("<tr><td><table border='1' cellspacing='0' width='100%'><tr><td><table width='100%'>");
	out.print("<tr><td bgcolor='#ffd27c' style='padding: 2px 5px 2px 5px;' width='100%'>");
	out.print("<div class='plaintext_blue' title='Work ID: " + selectedStepId
			+ "'>Work Item: <b><span class='plaintext_big' id='workTaskName'>"
			+ selectedWorkTaskName + "</span></b></div>");
	out.print("</tr></td>");
	out.print("<tr><td><img src='../i/spacer.gif' height='5'/></td></tr>");

	// !! start show task info with left and right panel (4 cols)
	out.print("<tr><td>");
	out.print("<table width='100%' border='0' cellspacing='0' cellpadding='0'>");
	out.print("<tr><td><img src='../i/spacer.gif' width='10'/></td>");
	out.print("<td><table border='0' cellspacing='0' cellpadding='0'>");

	// general info of step instance

	if (!isCreateWI) {
		currentExecutor = getExecutorName(pstuser, selectedStep);
		if (currentExecutor.equals(LARGE_STR)) {
			currentExecutor = "";
		}
		else {
			currentExecutor = "<a href='../ep/ep1.jsp?uid="
					+ (String)selectedStep.getAttribute("CurrentExecutor")[0]
					+ "'>" + currentExecutor + "</a>";
		}
		out.print(stepInfoLine("Step State", "stateVal", getColorState(state, true),
							"Step ID", null, String.valueOf(selectedStepId)));
		if (isWorkFlowStep) {
			// regular workflow step
			out.print(stepInfoLine("Created Date", "createdDtVal", createdDateS,
							 "Step Requestor", "creatorVal", creator));

			out.print(stepInfoLine("Expire Date", "expireDtVal", expireDateS,
							 "Assign To", "assignToVal", assignTo));

			out.print(stepInfoLine("Next Work Item", "outStepVal", nextStepName,
							 "Step Executor", "workByVal", currentExecutor));

			// data fields
			HashMap<String,String> dataMap = fObj.getDataMap();

			out.print("<tr><td colspan='6'><img src='../i/spacer.gif' height='15'/></td></tr>");
			out.print(HEAD_LINE);
			out.print("<tr><td class='plaintext_blue' colspan='6'>Data Fields</td></tr>");
			if (dataMap.size() <= 0)
				out.print("<tr><td class='plaintext' colspan='6'>&nbsp;&nbsp;None</td></tr>");
			else
			{
				// just get the dataMap from the flow object
				// Pairs (fieldLabel, attrName)
				out.println("<form name='dataFieldForm' method='post' action='post_worktray.jsp' enctype='multipart/form-data'>");

				String attrName;
				out.print("<tr><td colspan='6'><table border='0' cellspacing='0' cellpadding='0'>");
				for (String fieldLabel: dataMap.keySet())
				{
					attrName = dataMap.get(fieldLabel);
					out.print("<tr><td colspan='3'><img src='../i/spacer.gif' height='3'/></td></tr>");
					out.print("<tr><td class='blueNormal' width='118' valign='top'>" + fieldLabel + "</td>");
					if (attrName.startsWith("string"))
					{
						out.print("<td class='plaintext' valign='top'>:&nbsp;</td>"
								+ "<td class='plaintext' valign='top'>"
								+ "<input class='plaintext' type='text' name='" + attrName
								+ "' size='20'></td>");
					}
					else if (attrName.startsWith("int") || attrName.startsWith("float"))
					{

					}
					else if (attrName.startsWith("date"))
					{

					}
					else if (attrName.startsWith("raw"))
					{
						out.print("<td class='plaintext' valign='top'>: </td>"
								+ "<td class='plaintext' valign='top'>"
								+ "<textarea class='plaintext' name='" + attrName
								+ "' cols='70' rows='4'></textarea></td>");
					}
					else
					{
						l.error("Unexpected data field type found in step ["
									+ selectedStep.getObjectId() + "]");
					}
					out.print("</tr>");
				}
				out.print("</table></td></tr>");
			}
		}
		else if (isTaskStep) {
			// current selection is a project task step
			out.println("<form name='taskStepForm' method='post' action='post_worktray.jsp' enctype='multipart/form-data'>");
			out.print("<input type='hidden' name='op' value=''>");
			out.print("<input type='hidden' name='stepId' value=''>");
			// for coming back to select the same step
			out.print("<input type='hidden' name='idx' value='" + selectedIdx + "'>");
			out.print("<input type='hidden' name='backPage' value=''>");
			out.print("<input type='hidden' name='forceSendEmail' value=''>");

			String dtS1, dtS2, id;
			selectedPjIdS = (String)selectedStep.getAttribute("ProjectID")[0];
			selectedProj = (project)pjMgr.get(pstuser, Integer.parseInt(selectedPjIdS));
			selectedflowName = selectedProj.getDisplayName();

			pjOwnerId = Integer.parseInt((String)selectedProj.getAttribute("Owner")[0]);
			String pjOwner = "<a href='../ep/ep1.jsp?uid=" + pjOwnerId + "'>"
				+ ((user)uMgr.get(pstuser, pjOwnerId)).getFullName() + "</a>";

			id = (String)selectedTask.getAttribute("Owner")[0];
			String tkOwner = "<a href='../ep/ep1.jsp?uid=" + id + "'>"
				+ ((user)uMgr.get(pstuser, Integer.parseInt(id))).getFullName() + "</a>";

			out.print(stepInfoLine("Created Date", "createdDtVal", createdDateS,
							 "Step Requestor", "creatorVal", creator));

			if (assignTo==null || assignTo=="") assignTo = "<span style='color:#999999'>None</span>";
			out.print(stepInfoLine("Assign To", "assignToVal", assignTo,
							 "Step Executor", "workByVal", currentExecutor));

			out.print("<tr><td colspan='6'><img src='../i/spacer.gif' height='20'/></td></tr>");

			// task specific info
			out.print(HEAD_LINE);
			out.print("<tr><td class='plaintext_blue' colspan='6'>Task Information</td></tr>");
			out.print("<tr><td colspan='6'><img src='../i/spacer.gif' height='5'/></td></tr>");

			out.print(stepInfoLine("Project Name", "",
						"<a href='../project/proj_plan.jsp?projId=" + selectedPjIdS + "'>"
							+ selectedflowName + "</a>",
						"Project Owner", "", pjOwner));

			//out.print(stepInfoLine("Task Status", "", (String)selectedTask.getAttribute("Status")[0],
			//				 "Task Owner", "", tkOwner));
			out.print(stepInfoLine("Task Name", "",
						"<a href='../project/task_update.jsp?taskId=" + selectedTaskId + "'>"
						+ selectedWorkTaskName + "</a>",
						"Task Owner", "", tkOwner));

			out.print(stepInfoLine(
						"Task Header No.", "", selectedTaskHeaderNum,
						"Task ID", "",
						"<a href='../project/task_update.jsp?taskId=" + selectedTaskId + "'>"
							+ String.valueOf(selectedTask.getObjectId()) + "</a>"
						));

			out.print("<tr><td colspan='6'><img src='../i/spacer.gif' height='10'/></td></tr>");

			dtS1 = getDateString(selectedTask, "StartDate", "-");
			dtS2 = getDateString(selectedTask, "EffectiveDate", "^Not started");
			out.print(stepInfoLine("Planned Start", "", dtS1,
							 "Actual Start", "", dtS2));

			dtS1 = df1.format((Date)selectedTask.getAttribute("ExpireDate")[0]);

			dtS1 = getDateString(selectedTask, "ExpireDate", "-");
			dtS2 = getDateString(selectedTask, "CompleteDate", "^Not done");
			out.print(stepInfoLine("Planned Expire", "", dtS1,
							 "Completed", "", dtS2));

			out.print("<tr><td colspan='6'><img src='../i/spacer.gif' height='10'/></td></tr>");

			// end a task blog
			out.print("<tr><td><img src='../i/spacer.gif' height='5' /></td></tr>");
			out.print("<tr><td colspan='6'>");
			out.print("<table border='0' cellspacing='0' cellpadding='0'><tr>");
			out.print("<td class='plaintext' width='117' valign='top'>Blog Comment</td>");
			out.print("<td class='plaintext' valign='top'>:&nbsp;</td>");
			out.print("<td class='plaintext' valign='top'><textarea class='plaintext'"
					+ " name='blogText' cols='80' rows='4'></textarea></td></tr>");

			String checkStr = selectedProj.getOption(project.OP_NOTIFY_BLOG)==null ? "" : "checked";
			ids = rMgr.findId(pstuser, "TaskID='" + selectedTaskId + "' && ParentID=null");
			out.print("<tr><td colspan='3'><img src='../i/spacer.gif' width='485' height='1'/>");
			out.print("<a href='javascript:showTab(1);'>See other comments ("
					+ ids.length + ")</a></td></tr>");
			out.print("<tr><td colspan='2'></td><td class='plaintext'>");
			out.print("<input type='checkbox' id='sendEmail' value='true' ");
			out.print(checkStr + "/>&nbsp;Send Email notification to team members</td></tr>");
			out.print("</table></td></tr>");
		}
		else {
			// current selection is an action step
			//out.print("<input type='hidden' name='stepId' value=''>");
			// for coming back to select the same step
			//out.print("<input type='hidden' name='idx' value='" + selectedIdx + "'>");

			// step info
			out.print(stepInfoLine("Created Date", "createdDtVal", createdDateS,
							 "Step Requestor", "creatorVal", creator));

			out.print(stepInfoLine("Assign To", "assignToVal", assignTo,
							 "Step Executor", "workByVal", currentExecutor));

			// action specific info
			out.print("<tr><td colspan='6'><img src='../i/spacer.gif' height='15'/></td></tr>");
			out.print(HEAD_LINE);

			// use action display panel to show the action
			out.print("<tr><td class='plaintext_blue' colspan='6'>Action Item Information</td></tr>");
					out.print("<tr><td colspan='6'><img src='../i/spacer.gif' height='3'/></td></tr>");

			out.print("<tr><td colspan='6'>");

			// get the action object
			String aidS = (String) selectedStep.getAttribute(PstFlowStep.ATTR_TASKID)[0];
			PstAbstractObject aObj = aMgr.get(pstuser, aidS);
			String projIdS = (String)aObj.getAttribute("ProjectID")[0];
			int oriPjId = (projIdS==null)?0:Integer.parseInt(projIdS);

			String oriPriority = (String)aObj.getAttribute("Priority")[0];
			String oriSubject = (String)aObj.getAttribute("Subject")[0];
			if (oriSubject==null) oriSubject = "";
			String oriExpire = df4.format((Date)aObj.getAttribute("ExpireDate")[0]);
			if (oriExpire==null) oriExpire = "";
			String oriCoordinator = (String)aObj.getAttribute("Owner")[0];
			String oriStatus = (String)aObj.getAttribute("Status")[0];
			Object [] responsibleIds = aObj.getAttribute("Responsible");

			// display update action panel but I will show buttons myself
			try {out.print(action.showAddActionPanel(pstuser, action.TYPE_ACTION, oriPjId,
					 null, null, null, oriSubject, oriPriority, oriExpire, oriCoordinator,
					 oriStatus, null, responsibleIds, true, false));}
			catch (Exception e) {e.printStackTrace();}

			// show no. of blog comments for this action here
			ids = rMgr.findId(pstuser, "TaskID='" + aidS + "' && ParentID=null");
			out.print("<table><tr><td class='plaintext'><img src='../i/spacer.gif' width='540' height='1'/>"
				+ "<a href='javascript:showTab(1);'>See other comments (" + ids.length
				+ ")</a></td></tr></table>");

			// this denote an update of action
			out.print("<input type='hidden' name='aid' value='" + aidS + "'>");

			out.print("</td></tr>");
		}

		// SAVE, (DONE, REJECT) or CONTINUE
		currentExecutor = (String)selectedStep.getAttribute("CurrentExecutor")[0];
		if (currentExecutor == null)
			currentExecutor = "";
		else {
			int execId = Integer.parseInt(currentExecutor);
			uObj = (user)uMgr.get(pstuser, execId);
			currentExecutor = "<a href='../ep/ep1.jsp?uid=" + currentExecutor + "'>"
				+ uObj.getFullName() + "</a>";
			if (execId == pstuser.getObjectId() ||
					(isTaskStep && pjOwnerId==myUid) ) {
				bUserCanExecute = true;
			}
		}

		out.println("<tr><td colspan='6'><img src='../i/spacer.gif' height='5'/></td></tr>");
		out.print("<tr><td colspan='6' align='middle'>");
		if (isActionStep) {
			// state change is done by selecting State radio in the form and click Save
			out.print("<input type='Submit' class='button_medium' name='SaveAction' onClick='return validation();' value='  Submit  '>");
		}
		else {
			out.print("<input type='button' class='button_medium' onClick='submitForm(\"save\","
					+ selectedStepId + ");' value='Save'/>");
			out.print("&nbsp;&nbsp;");

			String applicationStr = (String)selectedStep.getAttribute("Application")[0];
			if (applicationStr==null)
			{
				// commit or abort task/workflow step
				if (!pjState.equals(project.ST_ONHOLD) && bUserCanExecute) {
					out.print("<input type='button' class='button_medium' onClick='submitForm(\"commit\","
						+ selectedStepId + ");' value='Commit'/>");
					out.print("&nbsp;&nbsp;");
					out.print("<input type='button' class='button_medium' onClick='submitForm(\"abort\","
						+ selectedStepId + ");' value='Abort'/>");
				}
			}
			else
			{
				// applicationStr contains the JSP page that is the app of this step instance
				out.print("<input type='button' class='button_medium' value='Continue' "
						+ "onClick=\"location='" + applicationStr + "'\" />");
			}
		}
		out.print("</td></tr>");
		out.print("</form>");
	}	// END if !isCreateWI

	///////////////////////////////////////////////////////////////////////////
	// create new work item (action item)
	else {
		// step info
		out.print(stepInfoLine("Status", "stateVal", state,
							"Step ID", null, "-"));

		out.print(stepInfoLine("Create Date", "createdDtVal", createdDateS,
						 	"Requestor", "creatorVal", creator));

		// action item info
		out.print("<tr><td colspan='6'><img src='../i/spacer.gif' height='15'/></td></tr>");
		out.print(HEAD_LINE);
		out.print("<tr><td class='plaintext_blue' colspan='6'>Action Item Information</td></tr>");
		out.print("<tr><td colspan='6'><img src='../i/spacer.gif' height='10'/></td></tr>");

		out.print("<tr><td colspan='6'>");

		int selectedPjId = (sessProjIdS==null)?0:Integer.parseInt(sessProjIdS);

		String newPriority = request.getParameter("Priority");
		String newDescription = request.getParameter("Description");
		if (newDescription==null) newDescription = "";
		String newExpire = request.getParameter("Expire");
		if (newExpire==null) newExpire = "";

		try {out.print(action.showAddActionPanel(pstuser, action.TYPE_ACTION, selectedPjId,
				 null, null, null, newDescription, newPriority, newExpire,
				 null, null, null, null, true, true));}
		catch (Exception e) {e.printStackTrace();}
		out.print("</td></tr>");

		// buttons are created inside showAddActionPanel()
	}

	out.print("</table></td></tr>");
	out.print("</table></td></tr>");
	out.print("</table></tr></td></table></tr></td>");	// surrounding table


	/////////////////////////////////////////////////////////////////////////////
	// TAB

	out.print("<tr><td><img src='../i/spacer.gif' height='25'/><a name='tab'></a></td></tr>");

	out.print("<tr><td>");
	out.print("<ul id='navigation'>");
	out.print("<li id='tab0'><a href='javascript:showTab(0);'><span>Process Map</span></a></li>");
	out.print("<li id='tab1'><a href='javascript:showTab(1);'><span>Comments</span></a></li>");
	out.print("<li id='tab2'><a href='javascript:showTab(2);'><span>History</span></a></li>");
	out.print("</ul>");
	out.print("</td></tr>");

	out.print("<tr><td bgcolor='#781351'><img src='../i/spacer.gif' height='2' width='90%'/></td></tr>");


	/////////////////////////////////////////////////////////////////////////////
	// Display the flow map
	String bgColor = "bgcolor='#ffaa55'";	// set bgColor based on step state

	String label;
	if (isTaskStep) {
		label = "Project Name";
		// just display the task step
		htmlStr = "<table border='0' cellspacing='0' cellpadding='0'>"
					+ "<tr><td class='plaintext_big'>"
					+ "This is a project flow.  No flow map is defined for this project.</td></tr>"
					+ "<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>"
					+ "<tr><td>"
					+ "<table cellpadding='3'><tr><td " + bgColor + ">"
					+ "<img src='../i/spacer.gif' width='10'/><img src='../box/i/step.gif' border='0'/></td>"
					+ "</td></tr></table>"
					+ "</td></tr></table>";
	}
	else if (isActionStep || isCreateWI) {
		label = "Work Item";
		selectedflowName = "Action Item";
		// just display a single step
		htmlStr = "<table border='0' cellspacing='0' cellpadding='0'>"
					+ "<tr><td class='plaintext_big'>"
					+ "This is an action item step.</td></tr>"
					+ "<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>"
					+ "<tr><td>"
					+ "<table cellpadding='3'><tr><td " + bgColor + ">"
					+ "<img src='../i/spacer.gif' width='10'/><img src='../box/i/step.gif' border='0'/></td>"
					+ "</td></tr></table>"
					+ "</td></tr></table>";
	}
	else {
		label = "Process Name";
	}

	out.print("<tr><td><img src='../i/spacer.gif' height='15'/><a name='flowMap'></a></td></tr>");
	out.print("<tr><td>");
	out.print("<div id='flowDiv' style='display:block;'>");
	out.print("<div class='plaintext_blue'>" + label + ": <b><span class='plaintext_big'>"
			+ selectedflowName + "</span></b></div>");
	out.print("<div><img src='../i/spacer.gif' height='10'/></div>");
	out.println("<div class='scroll' style='height:150px; width:100%;'>");
	out.print("<div><img src='../i/spacer.gif' height='30'/></div>");
	out.print(htmlStr);
	out.print("</div>");

	// link to add or delete work item
	if (!isTaskStep) {
		out.print("<div></p>");
		if (bSelect == null)
		{
			out.print("&nbsp;&nbsp;<img src='../i/bullet_tri.gif'/>");
			out.print("<a href='javascript:changeFlow(\"add\");' class='plaintext_bold'>Add a work item</a><br>");
			out.print("&nbsp;&nbsp;<img src='../i/bullet_tri.gif'/>");
			out.print("<a href='javascript:changeFlow(\"del\");' class='plaintext_bold'>Remove a work item</a>");
		}
		else
		{
			// add or del
			out.print("<form name='changeFlowForm' method='post' action='post_worktray.jsp' enctype='multipart/form-data'>");
			out.print("<input type='hidden' name='op' value=''>");		// add or del
			out.print("<input type='hidden' name='flowId' value='" + selectedFlowInstId + "'>");
			out.print("<input type='hidden' name='stepId' value=''>");	// step to be added around
			out.print("<input type='hidden' name='addPosition' value=''>");	// before, after, parallel
			out.print("<span class='plaintext_big'><img src='../i/bullet_tri.gif'/>");
			if (changeOption.equals("add"))
				out.print("Select from the flowmap the task which you want to add a task before or after.");
			else
				out.print("Select from the flowmap the task which you want to delete.");
			out.print("</span>");

			// choices for ADD step
			out.print("<div id='addOption' class='plaintext_big' style='display:none;'>");
			out.print("</div>");

			// OK or Cancel
			out.print("<span></p>");
			out.print("<img src='../i/spacer.gif' width='50' height='1'/>");
			out.print("<input type='button' id='changeOKButton' value='OK' class='button_medium' onClick='changeFlowOnOK();' style='width:80' disabled />&nbsp;&nbsp;&nbsp;");
			out.print("<input type='button' value='Cancel' class='button_medium' onClick='changeFlow();' style='width:80' />");
			out.print("</span>");
			out.print("</form>");
		}
		out.print("</div>");
	}

	out.print("</div>");		// display flowmap panel (block/none)
	out.print("</td></tr>");
	// End of display flow map


	//////////////////////////////////////////////////////////////////////////////
	// Process Blog

	int [] blogIds;
	String relatedObjIdS, blogType;
	if (isTaskStep) {
		relatedObjIdS = selectedTaskId;
		blogType = result.TYPE_TASK_BLOG;
	}
	else if (isActionStep) {
		relatedObjIdS = selectedTaskId;
		blogType = result.TYPE_ACTN_BLOG;
	}
	else {
		relatedObjIdS = String.valueOf(selectedFlowInstId);
		blogType = result.TYPE_WORKFLOW;
	}
	blogIds = rMgr.findId(pstuser, "TaskID='" + relatedObjIdS + "'");

	// !! start table for comment and link (with 2 cols)
	out.print("<tr><td>");
	out.print("<div id='commentDiv' style='display:none;'>");
	out.print("<table width='100%'>");
	out.print("<tr><td class='plaintext_blue' width='150'>Comments</td>");
	if (!isTaskStep) {
		out.print("<td class='plaintext'><img src='../i/bullet_tri.gif' />"
				+ "&nbsp;<b><a href='javascript:showBlogEditor();'>Post new comments</a></b></td>");
	}
	out.print("</tr>");
	// blog editor
	out.println("<form name='addBlogForm' method='post' action='post_worktray.jsp' enctype='multipart/form-data'>");
	out.print("<input type='hidden' name='op' value='addBlog'>");
	if (!isTaskStep)
		out.print("<input type='hidden' name='flowInstID' value='" + selectedFlowInstId + "'>");
	out.print("<tr><td></td><td>");
	out.print("<div id='blogEditor' style='display:none;'>");
	out.print("<table border='0' cellspacing='0' cellpadding='0'><tr>");
	out.print("<td valign='top'>");
	out.print("<textarea name='blogText' id='blogText' cols='80' rows='5' class='plaintext'></textarea>");
	out.print("</td>");
	out.print("<td valign='top'>&nbsp;&nbsp;"
		+ "<input type='button' value='Submit' class='button_medium' onClick='submitForm(\"save\","
			+ selectedStepId + ", document.addBlogForm);' /></td>");
	out.print("</tr></table>");
	out.print("</div>");
	out.print("</td></tr>");
	out.print("</form>");
	if (blogIds.length <= 0)
	{
		out.print("<tr><td class='plaintext' colspan='2' id='noneText'>&nbsp;&nbsp;None</td></tr>");
	}
	else
	{
		// list blogs
		PstAbstractObject [] blogList = rMgr.get(pstuser, blogIds);
		String idS2;
		if (blogType.equals(result.TYPE_TASK_BLOG)) {
			// for task blog, blog_comment.jsp expects planTaskID
			idS2 = String.valueOf(task.getPlanTaskId(pstuser, relatedObjIdS, selectedPjIdS));
		}
		else {
			idS2 = relatedObjIdS;	// action ID or flow inst ID
		}
		Util.sortDate(blogList, "CreatedDate", true);
		String backPage = "../box/worktray.jsp?idx=" + selectedIdx + "&pn=c";
		out.print("<tr><td colspan='2'>");
		out.println("<div class='scroll' style='height:250px; width:100%;'>");
		out.println(result.displayBlog(
				pstuser, blogList, blogType, relatedObjIdS, idS2,
				null, 0, null, selectedPjIdS,
				null, null, backPage, isAdmin));
		out.print("</div>");
		out.print("</td></tr>");
	}

	out.print("</table></td></tr>");

	out.print("</table>");
	out.print("</div>");
	out.print("</td></tr>");

	// End of work item details


	//////////////////////////////////////////////////////////////////////////////
	// History
	out.println("<tr><td></td><td>");
	out.print("<div id='historyDiv' style='display:none; width:90%; height=250px; border:1px solid #909090; padding:10px;'>");
	if (isTaskStep) {
		ids = hMgr.findId(pstuser, "TaskID='" + selectedTaskId + "'");
		if (ids.length > 0) {
			Util.sort(ids, true);
			for (int i=0; i<ids.length; i++) {
				history h = (history)hMgr.get(pstuser, ids[i]);
				out.print(h.getRecordHTML(pstuser, null));
			}
		}
		else {
			out.print("<span class='plaintext'>&nbsp;&nbsp;No history</span>");
		}
	}
	out.print("</div>");
	out.print("</td></tr>");


}	// END if (stepDisplayCount>0 || isCreateWI)
%>


      </table>
</td>
</tr>

</table>
<!-- END -->


		<!-- End of Content Table -->
			</td>
		</tr>
		</table>

		<!-- End of Main Tables -->

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
