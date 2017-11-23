<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
	//
	//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
	//
	/////////////////////////////////////////////////////////////////////
	//
	//	File: proj_action.jsp
	//	Author: ECC
	//	Date:	05/01/05
	//	Description: List project action items and decision records of a project.
	//
	//	Modification:
	//			@ECC082305	Support adding issues and link action/decision to issue/PR
	//			@ECC090105	Added filters to screen displayed items.
	//			@ECC090905	Support quick update all.
	//			@ECC101305a	Support search keywords in Subject/Synopsis
	//			@ECC101305b	Support sorting of action items
	//			@ECC041006	Add blog support to action/decision/issue.
	//			@041906SSI	Added sort function to Project names.
	//			@ECC121306	Support showing action/decsion from linked meetings.
	//
	/////////////////////////////////////////////////////////////////////
	//
%>

<%@ page import="util.*"%>
<%@ page import="oct.codegen.*"%>
<%@ page import="oct.omm.common.*"%>
<%@ page import="oct.omm.client.*"%>
<%@ page import="oct.omm.db.*"%>
<%@ page import="oct.pst.*"%>
<%@ page import="oct.pmp.exception.*"%>
<%@ page import="oct.util.general.*"%>
<%@ page import="java.util.*"%>
<%@ page import="java.io.*"%>
<%@ page import="java.text.SimpleDateFormat"%>

<%
	String projIdS = request.getParameter("projId");
	if (StringUtil.isNullOrEmptyString(projIdS))
		projIdS = "";
	String projIdSub = request.getParameter("projIdSub"); // @AGQ072706 new Action already used projId
	if (projIdSub != null)
		projIdS = projIdSub;
	String aIdS = request.getParameter("aid");
	String midS = request.getParameter("mid");
	if (midS == null)
		midS = "";
	String noSession = "../out.jsp?go=project/proj_action.jsp?projId="
			+ projIdS + ":mid=" + midS + ":aid=" + aIdS;
		
	String locale = (String) session.getAttribute("locale");

%>

<%@ taglib uri="/pmp-taglib" prefix="pmp"%>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%!
	projectManager pjMgr = null;

	void sortActionByProject(Object [] aiArr)
	{
		// sort the array by object
		PstAbstractObject o1, o2;
		String v1, v2;
		Object obj1, obj2;
		String idS;
		String attName = "ProjectID";
		boolean swap;
		do
		{
			swap = false;
			for (int i=0; i<aiArr.length-1; i++)
			{
				o1 = (PstAbstractObject)aiArr[i];
				o2 = (PstAbstractObject)aiArr[i+1];
				try
				{
					idS = (String) o1.getAttribute(attName)[0];
					obj1 = getProjectNameFromHash(idS);
					
					idS = (String) o2.getAttribute(attName)[0];
					obj2 = getProjectNameFromHash(idS);
	
					v1 = (obj1 != null)?(String)obj1:"zzz";		// change from ""
					v2 = (obj2 != null)?(String)obj2:"zzz";

					int result;
					result = v2.compareToIgnoreCase(v1);		// note that caller displays the list in reverse
	
					if (result > 0)
					{
						// swap the element
						aiArr[i]   = o2;
						aiArr[i+1] = o1;
						swap = true;
					}
				}
				catch (Exception e) {}
			}
		} while (swap);
	}	// END: sortActionByProject()
	
	HashMap<String,String> projNameHash = new HashMap<String,String> (10);
	String getProjectNameFromHash(String pidS)
	{
		String pjName = projNameHash.get(pidS);
		if (pjName == null) {
			try {
				PstGuest guest = PstGuest.getInstance();
				project pj = (project) pjMgr.get(guest, Integer.parseInt(pidS));
				pjName = pj.getDisplayName();
				projNameHash.put(pidS, pjName);
			}
			catch (Exception e) {
				return null;
			}
		}
		return pjName;
	}	// END: getProjectNameFromHash()
%>

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	////////////////////////////////////////////////////////
	if (pstuser instanceof PstGuest) {
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}

	// to check if session is OMF or PRM
	boolean isOMFAPP = Prm.isOMF();
	boolean isPRMAPP = Prm.isPRM();
	boolean isCwModule = Prm.isCwModule(session);
	String app = Prm.getAppTitle();
	String HOST = Prm.getPrmHost();

	int selectedAId = 0;
	if (aIdS != null && !aIdS.equals("null"))
		selectedAId = Integer.parseInt(aIdS);

	int myUid = pstuser.getObjectId();
	boolean isAdmin = false;
	boolean isDirector = false;
	boolean isProgMgr = false;
	int iRole = ((Integer) session.getAttribute("role")).intValue();
	if (iRole > 0) {
		if ((iRole & user.iROLE_ADMIN) > 0)
			isAdmin = true;
		if ((iRole & user.iROLE_DIRECTOR) > 0)
			isDirector = true;
		if ((iRole & user.iROLE_PROGMGR) > 0)
			isProgMgr = true;
	}

	actionManager aMgr = actionManager.getInstance();
	userManager uMgr = userManager.getInstance();
	bugManager bMgr = bugManager.getInstance();
	resultManager rMgr = resultManager.getInstance();
	meetingManager mMgr = meetingManager.getInstance();
	townManager tnMgr = townManager.getInstance();
	pjMgr = projectManager.getInstance();

	String s;
	boolean isChief = false;
	String myTownID = ((user) pstuser).getUserCompanyID();
	if (!StringUtil.isNullOrEmptyString(myTownID)) {
		town myTownObj = (town) tnMgr.get(pstuser, Integer.parseInt(myTownID));
		s = myTownObj.getStringAttribute("Chief");
		isChief = (s!=null && myUid==Integer.parseInt(s));
	}
	isProgMgr |= isChief;

	// @ECC121306 show action/decision from linked meetings
	String meetingString = "";
	String backParam = "";
	if (midS.length() > 0) {
		if (midS.equals("null"))
			midS = "";
		else {
			// construct the match string for all linked meetings (after start)
			meetingString = Util2.getAllLinkedMeetings(pstuser, mMgr,
					midS, true);
		}
	} else
		backParam = "projId=" + projIdS;
	if (projIdS.length() > 0)
		midS = "";

	String projName = null;
	String projDisplayName = null;
	project projObj = null;
	int selectedPjId = 0;
	String coordinatorIdS;
	int coordinatorId = 0;
	
	meeting mtgObj = null;

	boolean canDelete = (isAdmin || isProgMgr);

	SimpleDateFormat df1 = new SimpleDateFormat("MM/dd/yy");
	SimpleDateFormat df3 = new SimpleDateFormat("MM/dd/yyyy");
	String todayS = df3.format(new Date());

	if (midS.length() <= 0) {
		if (StringUtil.isNullOrEmptyString(projIdS)) {
			projName = (String) session.getAttribute("projName"); // the case when projId is removed from an issue
			if (projName == null)
				projIdS = "0";
		}

		// the project might have been deleted
		try {
			if (projName == null) // then projIdS must have been specified
				projName = PstManager.getNameById(pstuser,
						Integer.parseInt(projIdS));
			projObj = (project) pjMgr.get(pstuser, projName);
			projIdS = String.valueOf(projObj.getObjectId());
		} catch (PmpException e) {}

		if (projObj != null) {
			coordinatorIdS = (String) projObj.getAttribute("Owner")[0];
			coordinatorId = Integer.parseInt(coordinatorIdS);
			projDisplayName = projObj.getDisplayName();
		}
		
		// check to see if we need to refresh cache
		if (!StringUtil.isNullOrEmptyString(projIdS) && !projIdS.equals("0")) {
			s = (String)session.getAttribute("projId");
			if (StringUtil.isNullOrEmptyString(s) || !s.equals(projIdS)) {
				Util3.refreshPlanHash(pstuser, session, projIdS);	// need to refresh cache
			}
		}

		if (myUid == coordinatorId)
			canDelete = true;		// project coordinator can delete

		// set an action to done or reopen
		s = request.getParameter("Done");
		if (s != null) {
			action aObj = (action) aMgr.get(pstuser, s);
			if (!aObj.getStringAttribute("Status").equals(action.DONE))
				aObj.setStatus(pstuser, action.DONE);			// will commit and send notification
		}
		s = request.getParameter("Reop");
		if (s != null) {
			action aObj = (action) aMgr.get(pstuser, s);
			if (!(aObj.getStringAttribute("Status").equals(action.OPEN)
					|| aObj.getStringAttribute("Status").equals(action.LATE)) )
				aObj.setStatus(pstuser, action.OPEN);			// will commit
		}

		// get potential proj team member and bugId list
		s = request.getParameter("pid");
		if (s == null || s.length() == 0)
			s = projIdS;
		selectedPjId = Integer.parseInt(s);
	}	// END if no midS
	
	// with midS, use meeting to find project
	else {
		mtgObj = (meeting) mMgr.get(pstuser, midS);
		if (mtgObj != null) {
			projIdS = mtgObj.getStringAttribute("ProjectID");
			if (projIdS != null)
				try {projObj = (project) pjMgr.get(pstuser, Integer.parseInt(projIdS));}
				catch (PmpException e) {}
		}
	}

	String type = request.getParameter("Type");
	if (type == null)
		type = action.TYPE_ACTION;

	String newPriority = request.getParameter("Priority");
	String newDescription = request.getParameter("Description");
	if (newDescription == null)
		newDescription = "";
	String newExpire = request.getParameter("Expire");
	if (newExpire == null)
		newExpire = "";

	// handle filter priority and status
	String filter1 = ""; // filter on priority
	String filter2 = ""; // filter on status (state)
	String filter3 = ""; // filter on keywords (subject)
	String filter4 = ""; // filter on owner or responsible person
	boolean bCheckPref = false;

	// filter priority
	String filPriority = request.getParameter("FilterPriority");
	if (filPriority == null) {
		filPriority = "";
		bCheckPref = true;
	}
	boolean addParen = false;
	s = "";
	if (filPriority.length() > 0) {
		if (filPriority.indexOf(action.PRI_HIGH) >= 0)
			s = "(Priority='" + action.PRI_HIGH + "')";
		if (filPriority.indexOf(action.PRI_MED) >= 0) {
			if (s.length() > 0) {
				s += " || ";
				addParen = true;
			}
			s += "(Priority='" + action.PRI_MED + "')";
		}
		if (filPriority.indexOf(action.PRI_LOW) >= 0) {
			if (s.length() > 0) {
				s += " || ";
				addParen = true;
			}
			s += "(Priority='" + action.PRI_LOW + "')";
		}
	}
	if (addParen)
		filter1 = " && (" + s + ")";
	else if (s.length() > 0)
		filter1 = " && " + s;

	// filter status
	String filStatus = request.getParameter("FilterStatus");
	if (filStatus == null)
		filStatus = "OpenLate"; // default to showing open or late items
	if (filStatus.equals("all"))
		filStatus = "OpenLateDoneCancel";
	addParen = false;
	s = "";
	if (filStatus.length() > 0) {
		if (filStatus.indexOf(action.OPEN) >= 0)
			s = "(Status='" + action.OPEN + "')";
		if (filStatus.indexOf(action.LATE) >= 0) {
			if (s.length() > 0) {
				s += " || ";
				addParen = true;
			}
			s += "(Status='" + action.LATE + "')";
		}
		if (filStatus.indexOf(action.DONE) >= 0) {
			if (s.length() > 0) {
				s += " || ";
				addParen = true;
			}
			s += "(Status='" + action.DONE + "')";
		}
		if (filStatus.indexOf(action.CANCEL) >= 0) {
			if (s.length() > 0) {
				s += " || ";
				addParen = true;
			}
			s += "(Status='" + action.CANCEL + "')";
		}
	}
	if (addParen)
		filter2 = " && (" + s + ")";
	else if (s.length() > 0)
		filter2 = " && " + s;

	// only my items
	s = request.getParameter("ShowItem");
	boolean myItemOnly = (s != null && s.equals("my"));
	boolean showPR = (request.getParameter("ShowPR") != null);

	// keywords
	addParen = false;
	String keywords = request.getParameter("Keyword");
	if (keywords == null)
		keywords = "";
	if (keywords.length() > 0) {
		// OR together multiple keywords
		String delim = " ";
		if (keywords.indexOf(",") != -1)
			delim = ",";
		else if (keywords.indexOf(";") != -1)
			delim = ";";
		String[] sa = keywords.split(delim);

		for (int i = 0; i < sa.length; i++) {
			// trim trailing spaces and remove trailing % and *
			s = sa[i].replaceAll("^[ \t%*]+|[ \t%*]+$", "");
			if (s.length() == 0)
				continue;
			if (filter3.length() > 0) {
				filter3 += " || ";
				addParen = true;
			}
			filter3 += "(Subject='%" + s + "%')";
		}
	}
	if (addParen)
		filter3 = " && (" + filter3 + ")";
	else if (filter3.length() > 0)
		filter3 = " && " + filter3;

	// filter on responsible person or owner
	String respIdS = request.getParameter("ResponsibleP");
	if (!StringUtil.isNullOrEmptyString(respIdS)) {
		filter4 = " && (Owner='" + respIdS + "' || Responsible='" + s + "')";
	}

	// see if I need to check my preference
	if (midS.length() <= 0 && bCheckPref) {
		userinfo ui = (userinfo) userinfoManager.getInstance().get(
				pstuser, String.valueOf(pstuser.getObjectId()));
		Object[] o = ui.getAttribute("Preference");
		for (int i = 0; i < o.length; i++) {
			s = (String) o[i];
			if (s.startsWith("ActionFilter")) {
				s = s.substring(s.indexOf(':') + 1);
				response.sendRedirect("proj_action.jsp?" + backParam
						+ "&aid=" + aIdS + "&pid=" + selectedPjId
						+ "&Type=" + type + "&Priority=" + newPriority
						+ "&Description=" + newDescription + "&Expire="
						+ newExpire + s);
				return;
			}
		}
	}

	// @ECC101305b sorting
	String sortby = (String) request.getParameter("sortby");
	if (StringUtil.isNullOrEmptyString(sortby)) {
		if (projIdS.equals("0"))
			sortby = "pj";
		else
			sortby = "du";
	}
	String bgcl = "bgcolor='#6699cc'";
	String srcl = "bgcolor='#66cc99'";
	
	// check to see if project block posting option is on
	boolean bBlockPosting = false;
	if (projObj != null) {
		if (projObj.getOption(project.OP_NO_POST) != null) {
			bBlockPosting = true;
		}
	}
	

	////////////////////////////////////////////////////////
%>


<head>
<title>Action and Decision</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<jsp:include page="../init.jsp" flush="true" />
<jsp:include page="../forms.jsp" flush="true" />
<jsp:include page="../errormsg.jsp" flush="true"/>
<script language="JavaScript" src="../get-date.js"></script>
<script language="JavaScript" src="../date.js"></script>
<script type="text/javascript" src="../meeting/mtg1.js"></script>
<script type="text/javascript" src="../util.js"></script>
<script type="text/javascript" src="../ajax_general.js"></script>

<script type="text/javascript">
<!--
var currentType = "";
HOST = "<%=Prm.getPrmHost()%>";		// use by ajax_general.js

function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

function validation()
{
	var f = addActionForm;
	
	if (<%=bBlockPosting%>) {	// MSG.5004?
		location = "../out.jsp?go=project/proj_top.jsp&msg=Posting to this project is not allowed.  Please contact the project coordinator if you have any questions.";
		return false;
	}

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

function resetAC()
{
	// reset button for action item/decision/issue
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


function editAC(id, iType)
{
	updActionDecision.type.value = iType;
	updActionDecision.oid.value = id;
	updActionDecision.pid.value = '<%=projIdS%>';

	updActionDecision.action = "../meeting/upd_action.jsp";
	updActionDecision.submit();
}

function deleteAC(id, iType)
{
	if (!confirm("Are you sure you want to delete this item?")) {
		return false;
	}
	
	updActionDecision.backPage.value = '../project/proj_action.jsp?projId=<%=projIdS%>&mid=<%=midS%>';
	updActionDecision.op.value = 'delete';
	updActionDecision.type.value = iType;
	updActionDecision.oid.value = id;
	updActionDecision.submit();
}

function isDecision()
{
	addActionForm.BugId.disabled = false;
	addActionForm.Responsible.disabled = true;
	addActionForm.Selected.disabled = true;
	addActionForm.Owner.disabled = true;
	addActionForm.Expire.disabled = true;
	currentType = "decision record";
}

function isAction()
{
	addActionForm.BugId.disabled = false;
	addActionForm.Responsible.disabled = false;
	addActionForm.Selected.disabled = false;
	addActionForm.Owner.disabled = false;
	addActionForm.Expire.disabled = false;
	currentType = "action item";
}

function isIssue()
{
	addActionForm.BugId.disabled = true;
	addActionForm.Responsible.disabled = true;
	addActionForm.Selected.disabled = true;
	addActionForm.Owner.disabled = false;
	addActionForm.Expire.disabled = true;
	addActionForm.Expire.disabled = true;
	currentType = "issue record";
}

function selectType(ty)
{
	if (ty=='Action') isAction();
	else if (ty=='Decision') isDecision();
	else isIssue();
}

function changeProject()
{
	// this is changing the project team select box at the bottom (where user adds an item)
	addActionForm.action = "proj_action.jsp";
	addActionForm.method = "get";

	copyRadioValue(addActionForm.Type, addActionForm.type);
	copySelectValue(addActionForm.projId, addActionForm.pid);	// for the team member
	addActionForm.submit();
}

function saveFilter()
{
	Filter.action = "../ep/save_pref.jsp";
	Filter.submit();
}

function sort(name)
{
	Filter.sortby.value = name;
	Filter.submit();
}

function popup_cal(aid)
{
	if (aid != null) {		
		show_calendar('updActionDecision.Du_' + aid);		
	}
	else if (currentType == "action item") {
		show_calendar('addActionForm.Expire');
	}
}

function setDue(aid)
{
	// use Ajax to change date
	var e = document.getElementsByName("Du_" + aid).item(0);
	var eTD = document.getElementById("DuA_" + aid);
	var dt = new Date(e.value);
	var dtS = formatDate(dt, "MM/dd/yy");
	eTD.innerHTML = dtS;
	
	// call ajax
	ajaxSetActionDueDate(aid, dtS);
}

function showWhatItem()
{
	var loc = parent.document.URL;
	loc = stripURLOption(loc, "Done");
	var val;
	
	// my item
	if (QuickCheckForm.myItem.checked) val = "my";
	else val = "all";
	loc = addURLOption(loc, "ShowItem=" + val);
	
	// open item
	if (QuickCheckForm.openItem.checked) val = "OpenLate";
	else val = "all";
	loc = addURLOption(loc, "FilterStatus=" + val);
	
	location = loc;
}

function doneAnItem(aid)
{
	// either set the item to Done or re-Open
	var e = document.getElementsByName("done_" + aid).item(0);
	var bSetDone = e.checked;
	var op;
	if (bSetDone) op = "Done=";
	else op = "Reop="
	var loc = parent.document.URL;
	loc = addURLOption(loc, op + aid);
	location = loc;
	//ajaxSetActionDone(aid, bSetDone);
}

function toggleDecision()
{
	var e = document.getElementById("decisionPanel");
	var eLabel = document.getElementById("decisionShowLabel");
	
	if (e.style.display == "block") {
		e.style.display = "none";
		eLabel.style.display = "block";
	}
	else {
		e.style.display = "block";
		eLabel.style.display = "none";
	}
}

function gotoMeeting(mid, aid)
{
	location = "../meeting/mtg_view.jsp?mid=" + mid + "&aid=" + aid + "#action";
}

function showAll()
{
	var loc = parent.document.URL;
	loc = addURLOption(loc, "projId=0");
	location = loc;
}

// send to-do reminders on all open items of the selected project to responsible team members
function sendReminders()
{
	var loc = escape(parent.document.URL);
	location = "post_sendAction.jsp?projId=<%=projIdS%>&bp=" + loc;
}

// show editor on page to add quick blog
var lastAddBlogDiv = null;
var addBlogActionId = "";
function addBlog(aid)
{
	var e = document.getElementById("addBlogDiv_" + aid);
	if (e.style.display == "none") {
		if (lastAddBlogDiv != null) {
			lastAddBlogDiv.innerHTML = "";
			lastAddBlogDiv.style.display = "none";
		}		
		
		// check if the project allows posting
		if (<%=bBlockPosting%>) {	// MSG.5004?
			location = "../out.jsp?go=project/proj_top.jsp&msg=Posting to this project is not allowed.  Please contact the project coordinator if you have any questions.";
			return false;
		}

		addBlogActionId = aid;		// remember the aid for submit form in postQuickBlog()
		
		var txt = "<table border='0' cellspacing='0' cellpadding='0' width='100%'>"
					+ "<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>"
					+ "<tr><td align='center'><textarea id='Comment' style='width:700px;' rows='5'></textarea></tr>"
					+ "<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>"
					+ "</table>"
		// buttons
					+ "<table width='100%'>"
					+ "<tr><td align='center'>"
					+ "<input type='button' class='button_medium' onclick='postQuickBlog();' id='SubButton' value='Submit'/>"
					+ "<img src='../i/spacer.gif' width='10'/>"
					+ "<input type='button' class='button_medium' onclick='addBlog(" + aid + ")' value='Cancel'/>"
					+ "</td></tr>"
					+ "</table>";
		e.innerHTML = txt;
		
		e.style.display = "block";
		lastAddBlogDiv = e;
		var ee = document.getElementById("Comment");
		ee.focus();
	}
	else {
		e.innerHTML = "";
		e.style.display = "none";
		lastAddBlogDiv = null;
	}
}

function postQuickBlog()
{
	var f = document.quickBlogForm;
	var ee = document.getElementById("Comment");
	var val = trim(ee.value);
	if (val == "")
	{
		ee.value = "";
		f.logText.focus();
		return false;
	}

	// save the new blog
	f.logText.value = ee.value;
	f.id.value = addBlogActionId;
	var loc = parent.document.URL;
	loc = loc.replace("<%=HOST%>", "..").replace("&", ":");
	f.backPage.value = loc;
	
	var but = document.getElementById("SubButton")
	but.disabled=true;
	
	f.submit();
}

//-->
</script>

<style type="text/css">
#bubbleDIV {position:relative; z-index:1; left:0em; top:0em; width:3em; height:3em; vertical-align:bottom; text-align:center;}
img#bg {position:relative; z-index:-1; top:-2.2em; left:-0.1em; width:3em; height:3em; border:0;}
img#bg1 {position:relative; z-index:-1; top:-2.9em; left:2.0em; width:1.2em; height:1.2em; border:0;}
.ptextS2 {font-size:12px; line-height:15px; letter-spacing:0.1em;}
</style>

</head>

<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0"
	marginheight="0">
<table width="100%" border="0" cellspacing="0" cellpadding="0">
	<tr>
		<td valign="top"><!-- Main Tables -->
		<table width="100%" border="0" cellspacing="0" cellpadding="0">
			<tr>
				<td width="100%" valign="top"><!-- Top --> <jsp:include
					page="../head.jsp" flush="true" /> <!-- End of Top --></td>
			</tr>
			<tr>
				<td>
				<table width="90%" border="0" cellspacing="0" cellpadding="0">
					<tr>
						<td width="26" height="30"><a name="top">&nbsp;</a></td>
						<td height="30" align="left" valign="bottom" class="head"><b>Action
						and Decision</b></td>
						<td width='225'>
						<%
							if (isAdmin || isProgMgr || myUid == coordinatorId) {
						%> <img
							src="../i/bullet_tri.gif" /> <a
							class="listlinkbold" href="action_updall.jsp?projId=<%=projIdS%>">
						Update All</a> <%
 	}
 %>
						</td>
					</tr>
				</table>
				</td>
			</tr>
		</table>

<%		
			out.print("<form name='quickBlogForm' action='../blog/post_addblog.jsp' method='post'>");
			out.print("<input type='hidden' name='type' value='" + result.TYPE_ACTN_BLOG + "'>");
			out.print("<input type='hidden' name='id' value=''>");
			out.print("<input type='hidden' name='backPage' value=''>");
			out.print("<input type='hidden' name='logText' value=''>");
			out.print("</form>");
%>

		<table width='90%' border="0" cellspacing="0" cellpadding="0">

			<%
				if (!isOMFAPP) {
			%>
			<tr>
				<td width="100%"><jsp:include page="<%=Prm.getTabFile()%>"
					flush="true">
					<jsp:param name="cat" value="Project" />
					<jsp:param name="subCat" value="Todo" />
					<jsp:param name="role" value="<%=iRole%>" />
					<jsp:param name="projId" value="<%=projIdS%>" />
				</jsp:include></td>
			</tr>
		</table>
		<%
			} else {
		%>
		
	<tr>
		<td width="100%"><!-- Navigation Menu --> <jsp:include
			page="../in/imtg.jsp" flush="true">
			<jsp:param name="role" value="<%=iRole%>" />
		</jsp:include> <!-- End of Navigation Menu --></td>
	</tr>
	<tr>
		<td width="100%" valign="top"><!-- Navigation SUB-Menu -->
		<table border="0" width="100%" height="1" cellspacing="0"
			cellpadding="0">
			<tr>
				<td width="20" height="1" bgcolor="#FFFFFF"><img
					src="../i/spacer.gif" width="20" height="1" border="0"></td>
				<td bgcolor="#CCCCCC" width="100%" height="1"><img
					src="../i/spacer.gif" width="1" height="1" border="0"></td>
			</tr>
		</table>
		<table border="0" width="100%" height="14" cellspacing="0"
			cellpadding="0">
			<tr>
				<td width="20" height="14" bgcolor="#FFFFFF"><img
					src="../i/spacer.gif" height="1" border="0"></td>
				<td valign="top" class="BgSubnav">
				<table border="0" cellspacing="0" cellpadding="0">
					<tr class="BgSubnav">
						<td width="40"><img src="../i/spacer.gif" width="15"
							height="1" border="0"></td>
						<!-- Calendar -->
						<td width="7" height="14"><img src="../i/sub_line.gif"
							width="7" height="14" border="0"></td>
						<td width="15"><img src="../i/spacer.gif" width="15"
							height="1" border="0"></td>
						<td><a href="../meeting/cal.jsp" class="subnav">Calendar</a></td>
						<td width="15"><img src="../i/spacer.gif" width="15"
							height="1" border="0"></td>
						<td width="7" height="14"><img src="../i/sub_line.gif"
							width="7" height="14" border="0"></td>
						<!-- Search -->
						<td width="15"><img src="../i/spacer.gif" width="15"
							height="1" border="0"></td>
						<td><a href="../meeting/mtg_search.jsp" class="subnav">Search
						Meeting</a></td>
						<td width="15"><img src="../i/spacer.gif" width="15"
							height="1" border="0"></td>
						<td width="7" height="14"><img src="../i/sub_line.gif"
							width="7" height="14" border="0"></td>
						<!-- Back to Meeting -->
						<td width="15"><img src="../i/spacer.gif" width="15"
							height="1" border="0"></td>
						<td><a href="../meeting/mtg_view.jsp?mid=<%=midS%>"
							class="subnav">Back to Meeting</a></td>
						<td width="15"><img src="../i/spacer.gif" width="15"
							height="1" border="0"></td>
						<td width="7" height="14"><img src="../i/sub_line.gif"
							width="7" height="14" border="0"></td>
					</tr>
				</table>
				</td>
			</tr>
		</table>
		<%
			}
		%> <!-- End of Navigation SUB-Menu --></td>
	</tr>
</table>
<!-- Content Table -->


<table width="90%" border="0" cellspacing="0" cellpadding="0">

<!-- Project list -->
<tr>
	<td colspan='3'>
		<table cellspacing='0' cellpadding='0' border='0' width='100%'><tr>
		<td width='25'><img src='../i/spacer.gif' width='25' height='1' border='0'/></td>
		<td class="heading" width='120'>
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Project Name")%>
		</td>
		<td>
<form>
		<select name="projId" class="formtext" onchange="submit()">
<%
		int pjId;
		if (StringUtil.isNullOrEmptyString(projIdS)) pjId = 0;
		else pjId = Integer.parseInt(projIdS);
		out.print(Util.selectProject(pstuser, pjId, true));
%>
		</select>
</form>
		</td>
<%
		// send to-do reminder to team
		if (pjId != 0) {
			// there is a selected project, support sending reminder to team
			out.print("<td width='225' class='listlinkbold'>");
			out.print("<img src='../i/bullet_tri.gif'/>");
			out.print("<a href='javascript:sendReminders();' ");
			out.print("title='Send reminders of action items listed on this page'>");
			out.print("Send reminders on Actions</a>");
			out.print("</td>");
		}
%>
		</tr></table>
	</td>
</tr>


	<!-- Top Left side: Project Name -->
	<form name='Filter'>
	<input type="hidden" name="filterType" value="ActionFilter"/>
	<input type="hidden" name="sortby"/>
	<input type="hidden" name="mid" value="<%=midS%>"/>
	
<%
 	////////////////////////////////////////////////////////////
 	////////////////////////////////////////////////////////////
 	// panel for filter
 	out.print("<tr><td colspan='3'>");
 	out.print(Util.getHeaderPartitionLine());
 	out.print("<img id='ImgFilterPanel' src='../i/bullet_tri.gif'/>");
 	out.print("<a id='AFilterPanel' href='javascript:togglePanel(\"FilterPanel\", \"Show filter\", \"Hide filter\");' class='listlinkbold'>Show filter</a>");

 	out.print("<DIV id='DivFilterPanel' style='display:none;'>");
 	out.print("<table border='0' cellspacing='0' cellpadding='0' width='100%'>"); // Filter panel table

 	int[] projectObjId = pjMgr.getProjects(pstuser);
 	PstAbstractObject[] projectObjList = null;

 %>

	<tr>
		<td><img src='../i/spacer.gif' height='10' /></td>
	</tr>

	<tr>
		<td width="30"><img src="../i/spacer.gif" width="30" border="0"></td>
		<td colspan='2'>

		<table border="0" cellpadding="0" cellspacing="0" width='100%'>
			<tr>

				<!-- Top Left side: Filter -->
				<td valign='top'>
				<table border='0' cellpadding='0' cellspacing='0'>


					<!-- Project Name -->
					<tr>
						<td width='110' height="28" class="plaintext_blue">
							<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Project")%>:
						</td>
						<td width='300'><select name="projId" class="formtext"
							style='width: 300px;'>
							<option value=''>- Select a project -</option>
							<%
								if (projectObjId.length > 0) {
									projectObjList = pjMgr.get(pstuser, projectObjId);
									Util.sortName(projectObjList, true);

									String pName;
									project pj;
									Date expDate;
									String expDateS = new String();
									for (int i = 0; i < projectObjList.length; i++) {
										// project
										pj = (project) projectObjList[i];
										pName = pj.getDisplayName();
										s = String.valueOf(pj.getObjectId());
										out.print("<option value='" + s + "' ");
										if (s.equals(projIdS))
											out.print("selected");
										out.print(">" + pName + "</option>");
									}
								}
							%>
						</select></td>
					</tr>


					<tr>
						<td class="plaintext_blue">
							<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Keyword")%>:
						</td>
						<td><input type="text" name="Keyword" class="formtext"
							style='width: 300px;' value="<%=keywords%>"/></td>
					</tr>
					
					<tr><td colspan='2'><img src='../i/spacer.gif' height='5'/></td></tr>

					<tr>
						<td class="plaintext_blue">
							<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Responsible")%>:
						</td>
		<td>
		<select class="formtext" name="ResponsibleP" style='width:300px;'/>
		<option value="">- select Responsible -</option>
<%

	if (projObj != null) {
		// all project team people
		Object[] projTeam = projObj.getAttribute("TeamMembers");
		PstAbstractObject[] teamMember = uMgr.get(pstuser, projTeam);
		Util.sortUserArray(teamMember, true);

		String uname;
		int id;
		for (int a = 0; a < teamMember.length; a++) {
			uname = ((user) teamMember[a]).getFullName();
			id = teamMember[a].getObjectId();

			out.print("<option value='" + id + "'");
			if (String.valueOf(id).equals(respIdS))
				out.print(" selected");
			out.println(">" + uname + "</option>");
		}
	}

	out.print("</select>");
	out.print("</td></tr>");

%>
							</tr>

				</table>
				</td>

				<td width='10'><img src='../i/spacer.gif' width='10' /></td>

				<!-- Top Right side: Filter -->
				<td>
				<table border='0' cellpadding='0' cellspacing='0'>
					<tr>
						<td width='60' class='plaintext_blue' valign='top'>
						<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Filter")%>:&nbsp;
						</td>
						<td width='200' valign='top'><select class='formtext'
							name='FilterPriority' style='width: 150px;'>
							<option value=''>- All Priority -</option>
							<option value='high'
								<%if (filPriority.equals("high"))
				out.print("selected");%>>High
							only</option>
							<option value='high medium'
								<%if (filPriority.equals("high medium"))
				out.print("selected");%>>High
							/ Medium</option>
							<option value='medium'
								<%if (filPriority.equals("medium"))
				out.print("selected");%>>Medium
							only</option>
							<option value='low'
								<%if (filPriority.equals("low"))
				out.print("selected");%>>Low
							only</option>
						</select></td>
						<td width='60' class='plaintext_blue' valign='top'>
						<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Show")%>:&nbsp;
						</td>
						<td class='formtext' width='155'>
						<%
							if (Prm.isCtModule()) {
								out.print("<input type='checkbox' name='ShowPR' ");
								if (showPR)
									out.print("checked");
								out.print(">" + StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Both Issue and PR") + "</input>");
							} else {
								out.print(StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Action items"));
							}
						%>
						</td>
					</tr>
					<tr>
						<td height="3"><img src="../i/spacer.gif" width="1"
							height="3" border="0"/></td>
					</tr>
					<tr>
						<td width='85' class='plaintext_blue' valign='top'>
						<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Both Issue and PR")%>:
						</td>
						<td><select class='formtext' type='select'
							name='FilterStatus' style='width: 150px;'>
							<option value='all'>- All Status -&nbsp;&nbsp;</option>
							<option value='OpenLate'
								<%if (filStatus.equals("OpenLate"))
				out.print("selected");%>>Open
							/ Late</option>
							<option value='Late'
								<%if (filStatus.equals("Late"))
				out.print("selected");%>>Late</option>
							<option value='Done'
								<%if (filStatus.equals("Done"))
				out.print("selected");%>>Done
							/ Close</option>
							<option value='Cancel'
								<%if (filStatus.equals("Cancel"))
				out.print("selected");%>>Cancel</option>
						</select></td>
						<td></td>
						<td class='formtext'><input type='radio' name='ShowItem'
							value='my' <%if (myItemOnly)
				out.print("checked");%>>Only
						my items</input> <br>
						<input type='radio' name='ShowItem' value='all'
							<%if (!myItemOnly)
				out.print("checked");%>>Everyone's
						items</input></td>
					</tr>
				</table>
				</td>
			</tr>

			<tr>
				<td><img src='../i/spacer.gif' height='10' /></td>
			</tr>
			<tr>
				<td align='center'>
				<table>
					<tr>
						<td><img src='../i/spacer.gif' width='300' height='1' /></td>
						<td><input type="button" class="button_medium" name="Go"
							value="&nbsp;&nbsp;Go &gt;&gt;&nbsp;&nbsp;" onClick="submit()"></td>
						<td><input type="button" class="button_medium"
							name="SaveDefault" value="Save as default" onClick="saveFilter()"></td>
					</tr>
				</table>
				</td>
			</tr>

		</table>
	</form>
	</td>
	</tr>

	<%
		/////////////////////////////////////////
		// close Filter panel
		out.print("</table></DIV>"); // END Filter panel table
		out.print("</td></tr>");
	%>

	<!-- *************************   Page Headers   ************************* -->

	<!-- LABEL -->
	<tr>
		<td width="20"><img src="../i/spacer.gif" border="0" width="20"
			height="1"></td>
		<td width="120"></td>
		<td width="600"></td>
	</tr>



	<!-- //////////////////////////////////////////////////// -->

	<!-- LIST OF ACTION / DECISION / ISSUE -->

<%

		// for Action Item, Decision Records and Issues
		int[] ids;
		ArrayList <PstAbstractObject> arrL = null;
		PstAbstractObject o;

		// get the list of action items
		String expr = null;
		if (midS.length() <= 0) {
			if (projIdS.equals("0")) {
				expr = "";
				// get all actions in the company
				/*s = "(ProjectID=null) && (Company='"
						+ pstuser.getAttribute("Company")[0] + "') && ";*/
			}
			else
				expr = "(ProjectID='" + projIdS + "') && ";
		} else {
			expr = "";
		}
		String temp = "Type='" + action.TYPE_ACTION + "'";
		if (myTownID != null && StringUtil.isNullOrEmptyString(projIdS)
				&& StringUtil.isNullOrEmptyString(midS))
			temp += " && Company='" + myTownID + "'";
		temp = "(" + temp + ")";
		expr += temp + filter1 + filter2 + filter3 + filter4;
		//System.out.println("action SQL: " + expr);
		
		// remember expr if we need to send reminder to these action owners
		session.setAttribute("aiExpr", expr);
		
		ids = aMgr.findId(pstuser, expr);

		Object[] aiObjList = aMgr.get(pstuser, ids);
		if (midS.length() > 0) {
			arrL = new ArrayList <PstAbstractObject> ();
			for (int i = 0; i < aiObjList.length; i++) {
				o = (PstAbstractObject) aiObjList[i];
				s = (String) o.getAttribute("MeetingID")[0];
				if (s == null || meetingString.indexOf(s) == -1)
					continue;
				arrL.add(o);
			}
			aiObjList = arrL.toArray();
		}

		String ownerIdS, mId, bugIdS, subject, priority, dot;
		int ownerId;
		user uObj;
		int aid, len;
		Object[] respA;
		Date expireDate, createdDate, doneDate;
		action obj;
		boolean found;
		
		// filter MY action item ONLY
		if (myItemOnly) {
			ArrayList<Object> resList = new ArrayList<Object> (50);
			for (int i=0; i<aiObjList.length; i++) {
				obj = (action) aiObjList[i];
				ownerIdS = (String) obj.getAttribute("Owner")[0];
				ownerId = Integer.parseInt(ownerIdS);
				respA = obj.getAttribute("Responsible");
	
				found = false;
				if (ownerId != myUid) {
					for (int j = 0; j < respA.length; j++) {
						if (respA[j] == null)
							break;
						if (Integer.parseInt((String) respA[j]) == myUid) {
							found = true;
							break;
						}
					}
					if (!found)
						continue; // don't show if not my item
				}
				resList.add(obj);
			}
			aiObjList = resList.toArray();
		}

		// @ECC101305b sort
		boolean isGroupByProject = false;
		String[] priArr = {"l", "m", "h"};
		String[] stArr = {"C", "D", "O", "L"};
		if (sortby != null) {
			if (sortby.equals("ow"))
				Util.sortIndirectUserName(pstuser, uMgr, aiObjList, "Owner");
			else if (sortby.equals("du"))
				Util.sortDate(aiObjList, "ExpireDate", true);
			else if (sortby.equals("pr"))
				Util.sortWithValues(aiObjList, "Priority", priArr);
			else if (sortby.equals("st"))
				Util.sortWithValues(aiObjList, "Status", stArr);
			else if (sortby.equals("pj") && projIdS.equals("0")) {
				isGroupByProject = true;
				sortActionByProject(aiObjList);
			}
		}
		
		// store the action item list in session if we need to send reminders
		// in post_sendAction.jsp
		session.setAttribute("actionList", aiObjList);

		// decisions
		if (midS.length() <= 0)
			s = "(ProjectID='" + projIdS + "') && ";
		else
			s = "";
		s += "(Type='" + action.TYPE_DECISION + "')" + filter1 + filter3;
		//System.out.println("decision SQL: " + s);
		ids = aMgr.findId(pstuser, s);
		//Arrays.sort(ids);
		Object[] dsObjList = aMgr.get(pstuser, ids);
		if (midS.length() > 0) {
			arrL = new ArrayList <PstAbstractObject> ();
			for (int i = 0; i < dsObjList.length; i++) {
				o = (PstAbstractObject) dsObjList[i];
				s = (String) o.getAttribute("MeetingID")[0];
				if (s == null || meetingString.indexOf(s) == -1)
					continue;
				arrL.add(o);
			}
			dsObjList = arrL.toArray();
		}

		// issues
		PstAbstractObject[] bgObjList = new PstAbstractObject[0];
		if (Prm.isCtModule()) {
			if (isPRMAPP && midS.length() <= 0) {
				if (filter2.length() > 0) {
					filter2 = filter2.replaceAll("Status", "State");
					filter2 = filter2.replaceAll(action.DONE, bug.CLOSE);
				}
				if (filter3.length() > 0)
					filter3 = filter3.replaceAll("Subject", "Synopsis");
				if (showPR) //s = "";
				{
					temp = "";
					if (filter2.indexOf(action.OPEN) != -1) {
						// Open include OPEN, ACTIVE, ANALYZED and FEEDBACK which is simply !CLOSED
						filter2 = " && (State!='" + bug.CLOSE + "')";
					}
				} else
					temp = " (Type='" + bug.CLASS_ISSUE + "')"; // show only issue
	
				if (midS.length() <= 0)
					s = "(ProjectID='" + projIdS + "')";
				else
					s = "";
				String tempS = temp + filter1 + filter2 + filter3;
				if (s.length() > 0 && tempS.length() > 0)
					s += " && ";
				s += tempS;
				//System.out.println("bug SQL: " + s);
				ids = bMgr.findId(pstuser, s);
				Arrays.sort(ids);
				bgObjList = bMgr.get(pstuser, ids);
			}
		}

		// variables
		String bgcolor = "";
		boolean even;

		if ((aiObjList.length > 0 || dsObjList.length > 0 || (bgObjList != null && bgObjList.length > 0))
				&& canDelete) {
			/*out.print("<tr><td>&nbsp;</td>");
			out.print("<td colspan='2' align='right'>");
			out.print("<a href='javascript:deleteAC()' class='listlinkbold'>>> Delete&nbsp;</a>");
			out.print("</td></tr>");
			 */
		} else {
			out.print("<tr><td colspan='3'><img src='../i/spacer.gif' width='5' height='5'></a></td></tr>");
		}
	%>


	<tr>
		<td colspan="3"><a name="action"></a></td>
	</tr>
	<%
		// by default show only: my items and open actions
		out.print("<form name=QuickCheckForm>");
		out.print("<tr><td></td>");
		out.print("<td colspan='2' align='right'>");
		out.print("<table cellspacing='0' cellpadding='0'><tr>");
		out.print("<td><input type='button' class='button_medium' onclick='showAll();' value='Show All'>");
		out.print("<img src='../i/spacer.gif' width='60' height='1'/></td>");
		out.print("<td class='plaintext_big'>Show&nbsp;&nbsp;</td>");
		out.print("<td><input type='checkbox' name='myItem' onclick='showWhatItem();' ");
		if (myItemOnly)
			out.print("checked");
		out.print("></td><td class='plaintext_big'>only my items&nbsp;&nbsp;&nbsp;&nbsp;</td>");
		out.print("<td><input type='checkbox' name='openItem' onclick='showWhatItem();' ");
		if (filStatus.equals("OpenLate"))
			out.print("checked");
		out.print("></td><td class='plaintext_big'>only open items</td>");
		out.print("</tr></table>");
		out.print("</td></tr>");
		out.print("</form>");
		
		int totalAI = aiObjList.length;
		if (totalAI > 0) {
			out.print("<tr><td colspan='2' class='plaintext_big'>"
				+ "<img src='../i/spacer.gif' width='22' />"
				+ "Total " + totalAI + " action item");
			if (totalAI > 1) out.print("s");
			out.print("</td></tr>");
		}

		// start row (table) listing action items
		out.print("<tr>");
		out.print("<td></td><td colspan='2'>");

	%>

<form method="post" name="updActionDecision" action="../meeting/post_updaction.jsp">
<input type="hidden" name="projId" value="<%=projIdS%>"/>
<input type="hidden" name="oid"/>
<input type="hidden" name="pid"/>
<input type="hidden" name="mid" value="<%=midS%>"/>
<input type="hidden" name="type"/>
<input type="hidden" name="backPage" value="../project/proj_action.jsp?<%=backParam%>"/>
<input type='hidden' name='op' value=''/>


<!-- List of Action Items -->
	<%
		String status, linkS, thisProjName, thisProjIdS, lastProjIdS="";
		String respStr;
		boolean updateOK, bHasResp;
		int count, colspanNum = 0;
		user u;

		if (totalAI > 0) {

			// label
			String[] label0 = {"&nbsp;Action Item", "Owner", "Blog", "Due",
					"Priority", "Status", "Edit", "Done"};
			int[] labelLen0 = {-58, 8, 6, 6, 5, 5, 7, 5};
			boolean[] bAlignCenter0 = {false, true, true, true, true, true, true, true};
			String[] sortArr = {"pj", "ow", null, "du", "pr", "st", null, null};
			out.print(Util.showLabel(label0, null, sortArr, sortby,
					labelLen0, bAlignCenter0, true)); // sort, showAll and align center

			colspanNum = label0.length * 3 - 1;

			even = false;
			count = 1;
			len = aiObjList.length - 1;

			for (int i = len; i >= 0; i--) { // the list of action item for this meeting object
				obj = (action) aiObjList[i];
				aid = obj.getObjectId();

				ownerIdS = (String) obj.getAttribute("Owner")[0];
				ownerId = Integer.parseInt(ownerIdS);
				respA = obj.getAttribute("Responsible");
				bHasResp = true;

				found = false;
				if (ownerId != myUid) {
					for (int j = 0; j < respA.length; j++) {
						if (respA[j] == null) {
							if (j == 0) bHasResp = false;	// no more responsible persons
							break;
						}
						if (Integer.parseInt((String) respA[j]) == myUid) {
							found = true;
							break;
						}
					}
					if (!found && myItemOnly)
						continue; // don't show if not my item
				}

				// update ok?
				if (isAdmin || ownerId == myUid || found || isProgMgr)
					updateOK = true;
				else
					updateOK = false;
				
				if (ownerId == myUid) canDelete = true;		// owner of item can delete

				subject = (String) obj.getAttribute("Subject")[0];
				priority = (String) obj.getAttribute("Priority")[0];
				status = (String) obj.getAttribute("Status")[0];
				expireDate = (Date) obj.getAttribute("ExpireDate")[0];
				mId = (String) obj.getAttribute("MeetingID")[0];
				bugIdS = (String) obj.getAttribute("BugID")[0];
				doneDate = (Date) obj.getAttribute("CompleteDate")[0];
				thisProjIdS = obj.getStringAttribute("ProjectID");
				
				// construct owner and responsible person string, list owner first
				respStr="";
				if (ownerId != -1) {
				try {
					u = (user)uMgr.get(pstuser, ownerId);
					respStr = "<a href='../ep/ep1.jsp?uid=" + ownerId + "'>" + u.getStringAttribute("FirstName") + "</a>*";
				}
				catch (PmpException e) {
					// failed to get the owner, might be deleted, update ownerId
					obj.setAttribute("OwnerId", "-1");
					aMgr.commit(obj);
				}}
				
				if (bHasResp) {
					// add the responsible persons in to the string
					int uid;
					for (int j=0; j<respA.length; j++) {
						if (respA[j]==null) break;
						s = respA[j].toString();
						uid = Integer.parseInt(s);
						if (uid == ownerId) continue;		// don't display again
						try {
							u = (user)uMgr.get(pstuser, uid);
							respStr += "; "
									+ "<a href='../ep/ep1.jsp?uid=" + s
											+ "'>" + u.getStringAttribute("FirstName") + "</a>";
						}
						catch (PmpException e) {}
					}
				}

				if (projIdS.equals("0") && thisProjIdS!=null && !isGroupByProject) {
					// showing all projects' item, need to display the proj name for each item
					o = pjMgr.get(pstuser, Integer.parseInt(thisProjIdS));
					thisProjName = ((project)o).getDisplayName();	// display at the end of action item
				}
				else
					thisProjName = null;

				if (even)
					bgcolor = Prm.DARK;
				else
					bgcolor = Prm.LIGHT;
				even = !even;

				out.print("<tr " + bgcolor + "><td colspan='" + colspanNum
						+ "'><img src='../i/spacer.gif' height='10'/></td></tr>");

				// group by project display name
				if (isGroupByProject &&
						((thisProjIdS==null && lastProjIdS!=null)
								|| (thisProjIdS!=null && !thisProjIdS.equals(lastProjIdS))) ) {
					String name = projNameHash.get(thisProjIdS);
					if (StringUtil.isNullOrEmptyString(name)) name = "No Project";
					out.print("<tr " + bgcolor + "><td class='plaintext_blue' colspan='" + colspanNum
							+ "'><img src='../i/spacer.gif' width='10' height='1'/>"
							+ name + "</td></tr>");
					out.print("<tr " + bgcolor + "><td colspan='" + colspanNum
							+ "'><img src='../i/spacer.gif' height='5'/></td></tr>");
				}
				out.print("<tr " + bgcolor + ">");

				// Subject: action item
				out.print("<td>&nbsp;</td>");
				out.print("<td valign='top'><table border='0'><tr>");
				out.print("<td class='ptextS2' valign='top' width='20'>"
						+ count++ + ".</td>");
				out.print("<td class='ptextS2' valign='top' title='Action ID: "
						+ aid + "'>");
				if (aid == selectedAId)
					out.print("<b>" + subject + "</b>");
				else
					out.print(subject);
				if (updateOK)
					out.print("</a>");
				if (thisProjName != null) {
					out.print("<div class='plaintext' style='margin:3 0 0 0;'>(<a href='proj_top.jsp?projId=" + thisProjIdS
							+ "'>" + thisProjName + "</a>)</div>");
				}
				out.println("</td></tr></table></td>");
				
				// owners or responsible persons
				out.print("<td colspan='2'>&nbsp;</td>");
				out.print("<td class='listtext' valign='top' align='center'>");
				out.print(respStr);
				out.println("</td>");

				// support blogging in action/decision
				ids = rMgr.findId(pstuser, "TaskID='" + aid + "'");
				if (ids.length > 0) {
					linkS = "../blog/blog_task.jsp?projId=" + projIdS
							+ "&aid=" + aid;
				} else {
					linkS = "../blog/addblog.jsp?type=Action&id="
							+ aid
							+ "&backPage=../project/proj_action.jsp?projId="
							+ projIdS;
				}
				out.print("<td colspan='2'>&nbsp;</td>");
				out.print("<td class='listtext' valign='top' align='center'>");
				out.print("<a class='listlink' href='" + linkS + "'>");
				out.print("<div id='bubbleDIV'>" + ids.length);
				out.print("<img id='bg' src='../i/bubble.gif' /></div></a>");
				
				out.print("<div id='bubbleDIV' style='height:0em;'>");
				out.print("<a class='listlink' href='javascript:addBlog(" + aid + ");'>");
				out.print("<img id='bg1' src='../i/plus_green.gif' /></a></div>");
				out.println("</td>");

				// Due date
				out.print("<td colspan='2'>&nbsp;</td>");
				out.print("<input type='hidden' name='Du_" + aid + "' value='' onchange='setDue(" + aid + ")'>");
				out.print("<td class='listtext' align='center' valign='top'>");
				out.print("<a id='DuA_" + aid + "' href='javascript:popup_cal(" + aid + ")'>"
						+ df1.format(expireDate) + "</a>");
				out.println("</td>");

				// Priority {HIGH, MEDIUM, LOW}
				dot = obj.getPriorityDisplay(pstuser);
				out.print("<td colspan='3' class='listlink' align='center' valign='top' style='padding-top:2px;'>");
				out.print(dot);
				out.println("</td>");

				// Status {OPEN, LATE, CANCEL, DONE}
				dot = obj.getStatusDisplay(pstuser);
				out.print("<td colspan='3' class='listlink' align='center' valign='top' style='padding-top:2px;'>");
				out.print(dot);
				out.println("</td>");

				// update icon
				out.print("<td colspan='2'></td>");
				out.print("<td align='center' valign='top'>");
				if (updateOK) {
					linkS = "javascript:editAC('" + aid + "', 'Action')";
					out.print("<img src='../i/clipboard.jpg' onclick=\""
							+ linkS + "\" title='Update'/>");
				}
				if (canDelete) {
					linkS = "javascript:deleteAC('" + aid + "', 'Action')";
					out.print("&nbsp;&nbsp;<img src='../i/delete.gif' style='margin-bottom:2px;' onclick=\""
							+ linkS + "\" title='Delete'/>");
				}				
				if (mId != null) {
					linkS = "gotoMeeting(" + mId + "," + aid + ")";
					out.print("&nbsp;&nbsp;<img src='../i/mtg.gif' onclick=\""
							+ linkS + "\" title='Go to meeting'/>");
				}
				out.print("</td>");

				// done checkbox
				out.print("<td colspan='2'>&nbsp;</td>");
				out.print("<td class='listtext' align='center' valign='top'>");
				out.print("<input type='checkbox' name='done_" + aid
						+ "' onclick='doneAnItem(" + aid + ")'");
				if (status.equals(action.DONE))
					out.print(" checked");
				out.print(">");
				out.println("</td>");

				out.println("</tr>");
				out.print("<tr " + bgcolor + "><td colspan='" + colspanNum
						+ "'><img src='../i/spacer.gif' height='2'/></td></tr>");
				
				// hidden DIV for add blog editor
				out.print("<tr " + bgcolor + "><td colspan='" + colspanNum + "'>");
				out.print("<div id='addBlogDiv_" + aid + "' style='display:none;'>");
				out.print("</div>");
				out.print("</td></tr>");
				
				lastProjIdS = thisProjIdS;
			} // END: for each action item
					
	%>
	
</table>
</td>
</tr>

<tr><td valign='top'><img src='../i/spacer.gif' height='20' width='1' /></td>
	<td colspan='3' class='plaintext'>&nbsp;&nbsp;* = Coordinator of the action item</td>
</tr>
<!-- End list of action items -->

<%
	} // END if (aiObjList.length > 0)
	else {
		out.print("<tr><td></td><td colspan='2' class='ptextS2'>"
				+ "&nbsp;&nbsp;&nbsp;<font color='#777777'>No action item");
		if (projDisplayName != null) {
			out.print(" for </font><a class='ptextS2' href='proj_top.jsp'>"
					+ projDisplayName + "</a>");
		} else if (!StringUtil.isNullOrEmptyString(midS)) {
			out.print(" for this meeting</font>");
		} else
			out.print("</font>");
		out.print("</td></tr>");
	}

%>



<!-- List of Decision Records -->
<tr>
	<td>&nbsp;</td>
	<td colspan="2">
	<%
		if (dsObjList.length > 0) {
			out.print("<table><tr><td><img src='../i/spacer.gif' width='5' height='20'></td></tr></table>");

			// panel for hide/show decision
			out.print("<div id='decisionShowLabel' style='display:none;' class='listlinkbold'>");
			out.print("<img src='../i/bullet_tri.gif'/>");
			out.print("<a href='javascript:toggleDecision();'>Show decision</a>");
			out.print("</div>");
			
			// label
			out.print("<div id='decisionPanel' style='display:block;'>");
			String[] label0 = {"&nbsp;Decision&nbsp;&nbsp;&nbsp;<a href='javascript:toggleDecision();' style='color:#ccf'>(hide)</a>",
								"Blog", "Filed Date", "Priority", "Edit"};
			int[] labelLen0 = {-65, 6, 10, 11, 8};
			boolean[] bAlignCenter0 = {false, true, true, true, true};
			out.print(Util.showLabel(label0, null, null, null, labelLen0,
					bAlignCenter0, true)); // no sort, showAll and align center

			colspanNum = label0.length * 3 - 1;

			/*if (isPRMAPP)
				out.print(Util.showLabel(PrmMtgConstants.label1, PrmMtgConstants.labelLen1, canDelete));
			else
				out.print(Util.showLabel(PrmMtgConstants.label1A, PrmMtgConstants.labelLen1A, canDelete));*/
			out.print("</div>");
		}
		else {
			out.print("<table cellspacing='0' cellpadding='0'><tr><td class='plaintext_grey'>"); // No decision record
		}

		even = false;

		//for (int i=0; i<dsObjList.length; i++)
		count = 1;
		len = dsObjList.length - 1;
		for (int i = len; i >= 0; i--) { // the list of decision records for this meeting object
			obj = (action) dsObjList[i];
			aid = obj.getObjectId();

			subject = (String) obj.getAttribute("Subject")[0];
			priority = (String) obj.getAttribute("Priority")[0];
			createdDate = (Date) obj.getAttribute("CreatedDate")[0];
			mId = (String) obj.getAttribute("MeetingID")[0];
			bugIdS = (String) obj.getAttribute("BugID")[0];

			if (even)
				bgcolor = Prm.DARK;
			else
				bgcolor = Prm.LIGHT;
			even = !even;

			out.print("<tr "
					+ bgcolor
					+ "><td colspan='"
					+ colspanNum
					+ "'><img src='../i/spacer.gif' height='10'/></td></tr>");
			out.print("<tr " + bgcolor + ">");

			// Subject
			out.print("<td>&nbsp;</td>");
			out.print("<td valign='top'><table border='0'><tr>");
			out.print("<td class='ptextS2' valign='top' width='20'>"
					+ count++ + ".</td>");
			out.print("<td class='ptextS2' valign='top' title='Decision ID: "
					+ aid + "'>");
			if (aid == selectedAId)
				out.print("<b>" + subject + "</b>");
			else
				out.print(subject);
			out.println("</td></tr></table></td>");

			// blog in action/decision
			ids = rMgr.findId(pstuser, "TaskID='" + aid + "'");
			if (ids.length > 0) {
				linkS = "../blog/blog_task.jsp?projId=" + projIdS + "&aid="
						+ aid;
			} else {
				linkS = "../blog/addblog.jsp?type=Action&id=" + aid
						+ "&backPage=../project/proj_action.jsp?projId="
						+ projIdS;
			}
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td class='listtext' valign='top' align='center'>");
			out.print("<a class='listlink' href='" + linkS + "'>");
			out.print("<div id='bubbleDIV'>" + ids.length);
			out.print("<img id='bg' src='../i/bubble.gif' /></div></a>");
			out.println("</td>");

			// CreatedDate
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td class='listtext' width='55' align='center' valign='top'>");
			out.print(df1.format(createdDate));
			out.println("</td>");

			// Priority {HIGH, MEDIUM, LOW}
			dot = obj.getPriorityDisplay(pstuser);
			out.print("<td colspan='3' class='listlink' align='center' valign='top'>");
			out.print(dot);
			out.println("</td>");

			/*
			 // Bug id
			 if (isPRMAPP)
			 {
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
			 }
			 */

			// update icon
			out.print("<td colspan='2'></td>");
			out.print("<td align='center' valign='top'>");
			if (canDelete) {
				linkS = "javascript:editAC('" + aid + "', 'Decision')";
				out.print("<img src='../i/clipboard.jpg' onclick=\""
						+ linkS + "\" title='Update'/>&nbsp;&nbsp;");
				linkS = "javascript:deleteAC('" + aid + "', 'Decision')";
				out.print("<img src='../i/delete.gif' style='padding-bottom:2px;' onclick=\"" + linkS
						+ "\" title='Delete'/>");
			}
			if (mId != null) {
				linkS = "gotoMeeting(" + mId + "," + aid + ")";
				out.print("&nbsp;&nbsp;<img src='../i/mtg.gif' onclick=\""
						+ linkS + "\" title='Go to meeting'/>");
			}
			out.print("</td>");

			out.println("</tr>");
			out.print("<tr " + bgcolor + "><td colspan='" + colspanNum
					+ "'><img src='../i/spacer.gif' height='2'/></td></tr>");
		}
	%>
	</table>
	</td>
</tr>
<!-- End list of decision records -->

<%
	if (isPRMAPP) {
%>
<!-- List of Issues -->
<tr>
	<td>&nbsp;</td>
	<td colspan="2">
	<%
		if (bgObjList.length > 0) {
				out.print("<tr><td><img src='../i/spacer.gif' height='5'/></td></tr>");
				out.print(Util.showLabel(PrmMtgConstants.vlabel2,
						PrmMtgConstants.vlabelLen2, canDelete));
			} else {
				out.print("<table cellspacing='0' cellpadding='0'><tr><td class='plaintext_grey'>"); // No issue
			}

			even = false;

			bug bObj;

			//for (int i=0; i<bgObjList.length; i++)
			count = 1;
			if (bgObjList != null)
				len = bgObjList.length - 1;
			else
				len = -1; // won't show bug for OMF or comes from meeting link
			for (int i = len; i >= 0; i--) { // the list of issues for this meeting object
				bObj = (bug) bgObjList[i];
				aid = bObj.getObjectId();

				ownerIdS = (String) bObj.getAttribute("Creator")[0];
				if (myItemOnly && Integer.parseInt(ownerIdS) != myUid)
					continue;

				subject = (String) bObj.getAttribute("Synopsis")[0];
				status = (String) bObj.getAttribute("State")[0];
				priority = (String) bObj.getAttribute("Priority")[0];
				createdDate = (Date) bObj.getAttribute("CreatedDate")[0];
				mId = (String) bObj.getAttribute("MeetingID")[0];

				if (even)
					bgcolor = Prm.DARK;
				else
					bgcolor = Prm.LIGHT;
				even = !even;
				out.print("<tr " + bgcolor + ">");

				// Subject
				s = (String) bObj.getAttribute("Type")[0];
				out.print("<td>&nbsp;</td>");
				out.print("<td valign='top'><table border='0'><tr>");
				out.print("<td class='plaintext' valign='top' width='20'>"
						+ count++ + ".</td>");
				out.print("<td class='plaintext' valign='top'>");
				if (s.equals(bug.CLASS_ISSUE))
					out.print("<a href='javascript:editAC(\"" + aid
							+ "\", \"Issue\")'>");
				else
					out.print("<a href='../bug/bug_update.jsp?bugId=" + aid
							+ "'>");
				if (aid == selectedAId)
					out.print("<b>" + subject + "</b>");
				else
					out.print(subject);
				out.println("</a></td></tr></table></td>");

				// Submitter
				uObj = (user) uMgr.get(pstuser, Integer.parseInt(ownerIdS));
				out.print("<td colspan='2'>&nbsp;</td>");
				out.print("<td class='listtext' valign='top'>");
				out.print("<a class='listlink' href='../ep/ep1.jsp?uid="
						+ ownerIdS + "'>");
				out.print((String) uObj.getAttribute("FirstName")[0]
						+ " "
						+ ((String) uObj.getAttribute("LastName")[0])
								.charAt(0) + ".");
				out.print("</a>");
				out.print("</td>");

				// Status {CLOSE or !CLOSE}
				dot = "../i/";
				if (!status.equals(bug.CLOSE)) {
					dot += "dot_lightblue.gif";
				} else {
					dot += "dot_green.gif";
				}
				//else {dot += "dot_grey.gif";}
				out.print("<td colspan='3' class='listlink' align='center' valign='top'>");
				out.print("<img src='" + dot + "' title='" + status + "'>");
				out.println("</td>");

				// Priority {HIGH, MEDIUM, LOW}
				dot = "../i/";
				if (priority.equals(bug.PRI_HIGH)) {
					dot += "dot_red.gif";
				} else if (priority.equals(bug.PRI_MED)) {
					dot += "dot_orange.gif";
				} else if (priority.equals(bug.PRI_LOW)) {
					dot += "dot_yellow.gif";
				} else {
					dot += "dot_grey.gif";
				}
				out.print("<td colspan='3' class='listlink' align='center' valign='top'>");
				out.print("<img src='" + dot + "' title='" + priority
						+ "'>");
				out.println("</td>");

				// @ECC041006 support blogging in action/decision/issue
				ids = rMgr.findId(pstuser, "TaskID='" + aid + "'");
				out.print("<td colspan='2'>&nbsp;</td>");
				out.print("<td class='listtext' width='30' valign='top' align='center'>");
				out.print("<a class='listlink' href='../blog/blog_task.jsp?projId="
						+ projIdS + "&bugId=" + aid + "'>");
				out.print(ids.length + "</a>");
				out.println("</td>");

				// Meeting id
				out.print("<td colspan='2'>&nbsp;</td>");
				out.print("<td class='listtext' width='40' valign='top' align='center'>");
				if (mId != null) {
					out.print("<a class='listlink' href='../meeting/mtg_view.jsp?mid="
							+ mId + "&aid=" + aid + "#action'>");
					out.print(mId + "</a>");
				} else
					out.print("-");
				out.println("</td>");

				// My id
				out.print("<td colspan='2'>&nbsp;</td>");
				out.print("<td class='listtext' width='40' valign='top' align='center'>");
				out.print(aid + "</td>");

				// CreatedDate
				out.print("<td colspan='2'>&nbsp;</td>");
				out.print("<td class='listtext_small' width='55' align='center' valign='top'>");
				out.print(df1.format(createdDate));
				out.println("</td>");

				// delete
				if (canDelete) {
					out.print("<td colspan='2'>&nbsp;</td>");
					out.print("<td width='35' class='plaintext' align='center' valign='top'>");
					out.print("<input type='checkbox' name='delete_" + aid
							+ "'></td>");
				}

				out.println("</tr>");
				out.println("<tr "
						+ bgcolor
						+ ">"
						+ "<td colspan='26'><img src='../i/spacer.gif' width='2' height='2'></td></tr>");
			}
	%>
	</table>
	</td>
</tr>
<!-- End list of issues -->

<%
	} // END isPRMAPP
%>

<%
	boolean bNoLegend = true;
	if (!bNoLegend && aiObjList.length > 0) {
%>
<tr>
	<td>&nbsp;</td>
	<td colspan="2">
	<table width="100%" border='0' cellspacing='0' cellpadding='0'>
		<tr>
			<td class="tinytype" width="250"><font color='#555555'>(*
			Action item coordinator)</font></td>
			<td align="right"></td>
		</tr>
	</table>
	</td>
</tr>
<%
	}
%>

</form>

<%
	if (!bNoLegend
			&& (aiObjList.length > 0 || dsObjList.length > 0 || bgObjList.length > 0)) {
%>
<tr>
	<td>&nbsp;</td>
	<td colspan='2'>
	<table class="tinytype">
		<tr>
			<td width='40' class="tinytype">Status:</td>
			<td class="tinytype">&nbsp;<img src="../i/dot_lightblue.gif"
				border="0"><%=action.OPEN%></td>
			<td class="tinytype">&nbsp;<img src="../i/dot_green.gif"
				border="0"><%=action.DONE%>/<%=bug.CLOSE%></td>
			<td class="tinytype">&nbsp;<img src="../i/dot_red.gif"
				border="0"><%=action.LATE%></td>
			<td class="tinytype">&nbsp;<img src="../i/dot_cancel.gif"
				border="0"><%=action.CANCEL%></td>
		</tr>
		<tr>
			<td class="tinytype">Priority:
			<td class="tinytype">&nbsp;<img src="../i/dot_red.gif"
				border="0"><%=action.PRI_HIGH%></td>
			<td class="tinytype">&nbsp;<img src="../i/dot_orange.gif"
				border="0"><%=action.PRI_MED%></td>
			<td class="tinytype">&nbsp;<img src="../i/dot_yellow.gif"
				border="0"><%=action.PRI_LOW%></td>
		</tr>
	</table>
	</td>
</tr>
<tr>
	<td><img src='../i/spacer.gif' height='10' /></td>
</tr>
<%
	} // END if any of the three lists is not empty
%>

<!-- END LIST OF ACTION / DECISION / ISSUE -->

<tr>
	<td colspan="3">
	<table border="0" width="320" height="1" cellspacing="0"
		cellpadding="0">
		<tr>
			<td width="20" height="1" bgcolor="#FFFFFF"><img
				src="../i/spacer.gif" width="20" height="1" border="0" /></td>
			<td bgcolor="#CCCCCC" width="100%" height="1"><img
				src="../i/spacer.gif" width="250" height="1" border="0" /></td>
		</tr>
	</table>
	</td>
</tr>


<tr>
	<td colspan="3"><img src="../i/spacer.gif" width="5" height="15" /></td>
</tr>


<%
	/*
	 *************************************************
	 * NEW ACTION / DECISION / ISSUE
	 *************************************************
	 */

	if (!isOMFAPP && midS.length() <= 0) {
		out.print(action.showAddActionPanel(pstuser, type,
				selectedPjId, projIdS, projectObjId, projectObjList,
				newDescription, newPriority, newExpire, null, null, locale,
				null, false, true));
	} // END if !isOMFAPP
%>
<!-- END Add Action / Decision / Issue-->

<!-- End of Content Table -->
<!-- End of Main Tables -->
</td>
</tr>
</table>
</td>
</tr>

<tr>
	<td><!-- Footer --> <jsp:include page="../foot.jsp" flush="true" />
	<!-- End of Footer --></td>
</tr>
</table>
</body>
</html>
