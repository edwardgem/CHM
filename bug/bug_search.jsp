<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html lang="en">

<%
	//
	//	Copyright (c) 2005, EGI Technologies, Co.  All rights reserved.
	//
	/////////////////////////////////////////////////////////////////////
	//
	//	File: bug_search.jsp
	//	Author: ECC
	//	Date:	01/08/05
	//	Description: Search for bug summary.
	//	Modification:
	//
	//		@ECC090605	Optionally display top blog.
	//		@ECC110105	Support sorting.
	//		@ECC031406	State name change: PRM-open = New
	//		@ECC040506	Support multiple owners.
	//		@ECC041406	Support user-defined bug priority.
	//		@ECC071906	Support multiple companies using PRM.
	//
	/////////////////////////////////////////////////////////////////////
	//
%>

<%@ page import = "util.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.omm.common.*" %>
<%@ page import = "oct.omm.client.*" %>
<%@ page import = "oct.omm.db.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>
<%@ page import = "org.apache.log4j.Logger" %>

<%!
	String printChar(String str)
	{
		String retS = "";
		if (str != null && str.length() > 0) {
			if (str.matches("^[\u0000-\u0080]+$")) {
				// all ASCII
				if (!str.equals("?"))
					retS = " " + str.substring(0, 1).toUpperCase() + ". ";
			} else {
				// other character set
				retS = str; 	// the whole thing without "."
			}
		}
		return retS;
	}
%>

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	String noSession = "../out.jsp?go=bug/bug_search.jsp";
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%
	////////////////////////////////////////////////////////
	final int RADIO_NUM = 4;
	final int BUG_NUM_LIMIT = 200;
	
	// *** MUST copy from bug_update.jsp
	final String[] CAT2 = { "ABS", "CIS", "HIS", "CSS", "LIS", "PACS",
			"NIS", "HRP", "ORION", "ABS", "Dictionary", "Workflow", "Others", "" };
	final String[] USR2 = { "药剂科", "收费处", "门诊医生", "门诊护士", "住院医生",
			"住院护士", "影像科", "病理科", "院感科", "体检科", "-----", "人力资源部",
			"行政及后勤", "医疗物料采购部", "资讯科技部", "财务部", "ICS用户组", "CSSD用户组" };
	final String[] PRC2 = { "门诊挂号", "门诊收费", "收费报表", "分诊",
			"叫号屏显示", "处方打印", "手术申请", "入院登记", "住院结算", "医嘱处理", "电子病历",
			"执行单", "药品提交", "门诊发药", "住院发药", "药品字典界面", "医保相关", "出入库",
			"库存管理" };

	/*String[] classValAry = { bug.CLASS_ISSUE, bug.CLASS_DS,
			bug.CLASS_PS, bug.CLASS_HW, bug.CLASS_SW, "messaging-bug",
			"dictionary-bug", bug.CLASS_DOC, "database-issue",
			"medical record-issue", "UI-issue", "user-issue",
			bug.CLASS_SP, bug.CLASS_CH };*/

	final String[] IT_BUG_TYPE = { bug.CLASS_ISSUE, bug.CLASS_DS,
			bug.CLASS_PS, bug.CLASS_HW, bug.CLASS_SW, "messaging-bug",
			"dictionary-bug", bug.CLASS_DOC, "database-issue",
			"medical record-issue", "UI-issue", "user-issue",
			bug.CLASS_SP, bug.CLASS_CH };


	////////////////////////////	
	
	
	// need to list all scrum number
	String[] sevArr = { "scrum-10", "scrum-9", "scrum-8", "scrum-7",
			"scrum-6", "scrum-5", "scrum-4", "scrum-3", "scrum-2",
			"scrum-1", "c", "se", "n", "" };

	String[] priArr = { "h", "m", "l" }; // default

	

	String[] CATEGORY = CAT2;
	
	String[] USER_DEPT = USR2;
	
	String[] PROCESS_TYPE = PRC2;

	////////////////////////////

	if (pstuser instanceof PstGuest) {
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	Logger l = PrmLog.getLog();

	int uid = pstuser.getObjectId();
	boolean isAdmin = false;
	int iRole = ((Integer) session.getAttribute("role")).intValue();
	if ((iRole & user.iROLE_ADMIN) > 0)
		isAdmin = true;

	String locale = (String) session.getAttribute("locale");

	// Scrum
	boolean isEnableScrum = true;
	ArrayList<String> sevArList = new ArrayList<String>(
			bug.SEV_ARRAY.length + 1);
	sevArList.addAll(Arrays.asList(bug.SEV_ARRAY));
	if (isEnableScrum)
		sevArList.add(bug.SEV_SCRUM);
	String[] severityValAry = sevArList.toArray(new String[0]);

	projectManager pjMgr = projectManager.getInstance();
	userManager uMgr = userManager.getInstance();
	bugManager bMgr = bugManager.getInstance();
	townManager tnMgr = townManager.getInstance();

	SimpleDateFormat df1 = new SimpleDateFormat("MM/dd/yy");

	// @ECC040506 support for multiple owners
	String s;
	String[] sa;
	int numOfOwner; // total no. of owners
	String[] ownerAttr; // array that holds the attribute names
	s = Util.getPropKey("pst", "BUG_OWNER_ATTRIBUTE");
	int[] viewOwnerId;
	if (!StringUtil.isNullOrEmptyString(s)) {
		sa = s.split(";"); // e.g. Owner; Owner1
		numOfOwner = sa.length;
		ownerAttr = new String[numOfOwner];
		viewOwnerId = new int[numOfOwner];
		for (int i = 0; i < numOfOwner; i++) {
			ownerAttr[i] = sa[i].trim();
			viewOwnerId[i] = 0;
		}
	} else {
		numOfOwner = 1;
		ownerAttr = new String[1];
		ownerAttr[0] = "Owner"; // default owner attr name
		viewOwnerId = new int[1];
		viewOwnerId[0] = 0;
	}

	// construct the expression
	String expr = "";

	String bugIdS = request.getParameter("bugId");
	if (bugIdS == null)
		bugIdS = ""; // avoid showing null in the text box
	String projIdS = request.getParameter("projId");
	String synopsisS = request.getParameter("synopsis");
	if (synopsisS == null)
		synopsisS = ""; // avoid showing null in the text box
	int viewProjId = 0, viewSubmitterId = 0;
	String viewCategory = "";
	String viewProcessType = "";
	String viewUserDept = "";
	String revS = "";
	String createDate1S=null, createDate2S=null;

	String tempExpr;
	if (bugIdS != null && bugIdS.length() > 0) {
		expr = "om_acctname='" + bugIdS + "'";
	} else {
		// synopsis
		if (synopsisS != null && synopsisS.length() > 0) {
			expr = "(Synopsis='%" + synopsisS.replaceAll("\\s+", "%")
					+ "%')";
		}
		// project
		if (projIdS != null && projIdS.length() > 0)
			viewProjId = Integer.parseInt(projIdS);
		if (projIdS != null && projIdS.length() > 0) {
			if (expr.length() > 0)
				expr += " && ";
			expr += "(ProjectID='" + projIdS + "')";
		}

		// category
		viewCategory = request.getParameter("category");
		if (viewCategory == null)
			viewCategory = "";
		if (viewCategory.length() > 0) {
			if (expr.length() > 0)
				expr += " && ";
			expr += "(Category='" + viewCategory + "')";
		}
		
		// process type
		viewProcessType = request.getParameter("processType");
		if (!StringUtil.isNullOrEmptyString(viewProcessType)) {
			if (expr.length() > 0)
				expr += " && ";
			expr += "(ProcessType='" + viewProcessType + "')";
		}
		
		// user department
		viewUserDept = request.getParameter("userDept");
		if (!StringUtil.isNullOrEmptyString(viewUserDept)) {
			if (expr.length() > 0)
				expr += " && ";
			expr += "(DepartmentName='" + viewUserDept + "')";
		}

		// submitter
		String submitter = request.getParameter("submitter");
		if (submitter != null && submitter.length() > 0) {
			viewSubmitterId = Integer.parseInt(submitter);
			if (expr.length() > 0)
				expr += " && ";
			expr += "(Creator='" + submitter + "')";
		}

		// owner
		for (int i = 0; i < numOfOwner; i++) {
			s = request.getParameter("owner" + i);
			if (s != null && s.length() > 0) {
				viewOwnerId[i] = Integer.parseInt(s);
				if (expr.length() > 0)
					expr += " && ";
				expr += "(" + ownerAttr[i] + "='" + s + "')";
			}
		}

		// status
		tempExpr = "";
		for (int i = 0; i < bug.STATE_ARRAY.length; i++) {
			s = request.getParameter(bug.STATE_ARRAY[i]);
			if (s != null && s.length() > 0) {
				if (tempExpr.length() > 0)
					tempExpr += " || ";
				tempExpr += "State='" + bug.STATE_ARRAY[i] + "'";
			}
		}
		if (tempExpr.length() > 0) {
			tempExpr = "(" + tempExpr + ")";
			if (expr.length() > 0)
				expr += " && ";
			expr += tempExpr;
		}

		// type
		tempExpr = "";
		for (int i = 0; i < IT_BUG_TYPE.length; i++) {	// bug.CLASS_ARRAY
			s = request.getParameter(IT_BUG_TYPE[i]);
			if (s != null && s.length() > 0) {
				if (tempExpr.length() > 0)
					tempExpr += " || ";
				tempExpr += "Type='" + IT_BUG_TYPE[i] + "'";
			}
		}
		if (tempExpr.length() > 0) {
			tempExpr = "(" + tempExpr + ")";
			if (expr.length() > 0)
				expr += " && ";
			expr += tempExpr;
		}

		// priority
		tempExpr = "";
		for (int i = 0; i < bug.PRI_ARRAY.length; i++) {
			s = request.getParameter(bug.PRI_ARRAY[i]);
			if (s != null && s.length() > 0) {
				if (tempExpr.length() > 0)
					tempExpr += " || ";
				tempExpr += "Priority='" + bug.PRI_ARRAY[i] + "%'";
			}
		}
		if (tempExpr.length() > 0) {
			tempExpr = "(" + tempExpr + ")";
			if (expr.length() > 0)
				expr += " && ";
			expr += tempExpr;
		}

		// severity
		tempExpr = "";
		for (int i = 0; i < severityValAry.length; i++) {
			s = request.getParameter(severityValAry[i]);
			if (s != null && s.length() > 0) {
				if (tempExpr.length() > 0)
					tempExpr += " || ";
				tempExpr += "Severity='" + severityValAry[i] + "%'";
			}
		}
		if (tempExpr.length() > 0) {
			tempExpr = "(" + tempExpr + ")";
			if (expr.length() > 0)
				expr += " && ";
			expr += tempExpr;
		}

		// revision
		revS = request.getParameter("revision");
		if (revS == null)
			revS = "";
		if (revS != null && revS.length() > 0) {
			tempExpr = "(Release='%" + revS + "%')";
			if (expr.length() > 0)
				expr += " && ";
			expr += tempExpr;
		}
		
		// creation date
		createDate1S = request.getParameter("CreateDate1");		// 2014.05.28
		createDate2S = request.getParameter("CreateDate2");
		if (createDate1S == null) createDate1S = "";
		if (createDate1S.length()>0) {
			if (StringUtil.isNullOrEmptyString(createDate2S)) createDate2S = createDate1S;
			tempExpr = "(CreatedDate >= '" + createDate1S + "' && CreatedDate <= '" + createDate2S + "')";
			if (expr.length() > 0)
				expr += " && ";
			expr += tempExpr;
		}
	}
	System.out.println("expr1=" + expr);

	project pjObj = null;
	String projName = "";
	if (viewProjId > 0) {
		// check to see if the session projId is the same, if not, need to prepare for refresh cache
		s = (String)session.getAttribute("projId");
		if (!StringUtil.isNullOrEmptyString(s) && Integer.parseInt(s)!=viewProjId) {
			session.setAttribute("projId", String.valueOf(viewProjId));
		}
		
		try {
			pjObj = (project) pjMgr.get(pstuser, viewProjId);
			projName = pjObj.getDisplayName();
		}
		catch (PmpException e) {
			session.removeAttribute("projId");
		}
	}


	// get category options
	if (pjObj != null) {
		s = pjObj.getStringAttribute("Company");
		String optionStr;
		if (!StringUtil.isNullOrEmptyString(s)) {
			town tnObj = (town) tnMgr.get(pstuser, Integer.parseInt(s));

			String[] sArr;
			if ((sArr = tnObj.getTrackerOption("@CAT")) != null)
				CATEGORY = sArr;
			if ((sArr = tnObj.getTrackerOption("@PRC")) != null)
				PROCESS_TYPE = sArr;
			if ((sArr = tnObj.getTrackerOption("@DEP")) != null)
				USER_DEPT = sArr;
		}
	}

	// show blogs
	boolean bShowBlog = false;
	s = request.getParameter("ShowBlog");
	if (s != null && expr.length() == 0)
		expr = " "; // handle a bug of looping on some browser settings
	if (s != null && s.equals("true"))
		bShowBlog = true;

	// see if I need to use the user preference
	if (expr.length() == 0) {
		// check user Preference
		userinfo ui = (userinfo) userinfoManager.getInstance().get(
				pstuser, String.valueOf(pstuser.getObjectId()));
		Object[] o = ui.getAttribute("Preference");
		for (int i = 0; i < o.length; i++) {
			s = (String) o[i];
			if (s == null)
				break;
			if (s.startsWith("BugTrkFilter")) {
				s = s.substring(s.indexOf(':') + 1).trim();
				if (s.length() > 0) {
					if (!s.contains("ShowBlog=false"))
						s += "ShowBlog=false"; // default to don't show blog
					if (s.endsWith("&"))
						s = s.substring(0, s.length() - 1);
					response.sendRedirect("bug_search.jsp?" + s);
					return;
				}
			}
		}
	}
	expr = expr.trim();
	System.out.println("expr2=" + expr);

	s = request.getParameter("ShowMax");
	boolean bShowMax = (!StringUtil.isNullOrEmptyString(s) && s.equals("true"));
	
	s = request.getParameter("ExportNoDisplay");
	boolean bExportNoDisplay = (s!=null && s.equals("true"));
	if (bExportNoDisplay) bShowMax = true;			// for export, always include all bugs

	/////////////////////////////////////////////////////////////
	// ********************************
	// get the list of bugs
	int iSize = 0;
	
	if (!StringUtil.isNullOrEmptyString(expr))
		iSize = bMgr.getCount(pstuser, expr);	// faster call for total
	
	// show some?
	boolean bTooManyBugs = (iSize > BUG_NUM_LIMIT);
	int showBugNum, iRetrieveNum;
	if (bTooManyBugs && !bShowMax) {
		showBugNum = iRetrieveNum = BUG_NUM_LIMIT;	// show some
	}
	else {
		showBugNum = iSize;							// show all
		iRetrieveNum = -1;							// setup for PST call
	}

	int[] ids = new int[0];
	if (expr.length() > 0) {
		expr = expr.replaceAll("\\*", "%");
		ids = bMgr.findId(pstuser, expr, iRetrieveNum);
		session.setAttribute("expr", expr);		// remember for bug_updall.jsp
	}

	// @ECC110105 sorting, then fill the bug object list
	PstAbstractObject[] bugObjList = new PstAbstractObject[0];
	String sortby = (String) request.getParameter("sortby");
	if (sortby != null && sortby.length() == 0)
		sortby = null;
	//if (sortby == null)
	//	Arrays.sort(ids); // default sort by order of entry (i.e. id order) - latest first
	bugObjList = bMgr.get(pstuser, ids);
	
	session.setAttribute("bugList", bugObjList); // this will be used if we choose to export

	int idx;

	// @ECC20160705
	// allow specify a condition and then export to Excel without displaying on the Webpage
	if (bExportNoDisplay) {
		//response.sendRedirect("post_bug_export.jsp?projId=" + projIdS);
		//return;
	}

	else {
	// *************************************
	//////////////////////////////////////////////////////////////
	// SORT
	
	int numUDefPri = 0;
	s = Util.getPropKey("pst", "BUG_MAX_DEFINE_PRI");
	if (s != null) {
		try {
			numUDefPri = Integer.parseInt(s.trim());
		} catch (Exception e) {/* invalid properties value */
		}
		if (numUDefPri > 0) {
			priArr = new String[numUDefPri + 4]; // plus the default 3
			for (idx = 0; idx <= numUDefPri; idx++)
				priArr[idx] = bug.PRI_HIGH + (idx);
			// append the default value to after the user-defined levels
			priArr[idx++] = "h";
			priArr[idx++] = "m";
			priArr[idx] = "l";
		}
	}
	if (sortby != null) {
		if (sortby.equals("st"))
			Util.sortWithValues(bugObjList, "State", bug.STATE_ARRAY,
					true);
		else if (sortby.equals("ty"))
			Util.sortWithValues(bugObjList, "Type", IT_BUG_TYPE,	// bug.CLASS_ARRAY, classValAry
					true);
		else if (sortby.equals("ca"))
			Util.sortWithValues(bugObjList, "Category", CAT2, true);
		else if (sortby.equals("up"))
			Util.sortDate(bugObjList, "LastUpdatedDate");
		else if (sortby.equals("sv"))
			Util.sortWithValues(bugObjList, "Severity", sevArr, true);
		else if (sortby.equals("pr"))
			Util.sortWithValues(bugObjList, "Priority", priArr, true);
		else if (sortby.equals("su"))
			Util.sortUserId(pstuser, bugObjList, "Creator");
		else if (sortby.startsWith("ow")) {
			int i = Integer
					.parseInt(sortby.substring(sortby.length() - 1));
			Util.sortUserId(pstuser, bugObjList, ownerAttr[i]);
		}
	}
	}
	
	
	
	String bgcl = "bgcolor='#6699cc'";
	String srcl = "bgcolor='#66cc99'";

	// all users
	PstAbstractObject[] allMember = new PstAbstractObject[0];
	try {
		if (viewProjId != 0)
			allMember = ((user) pstuser).getTeamMembers(viewProjId);
		else
			allMember = ((user) pstuser).getAllUsers();
	} catch (Exception e) {
		System.out.println("failed to get project [" + viewProjId + "]");
		viewProjId = 0;
		bugObjList = new PstAbstractObject[0];
	}

	s = request.getParameter("ShowFilter");
	boolean bShowFilter = (s != null && s.equals("true")) ? true : false;

	
	////////////////////////////////////////////////////////
%>


<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../errormsg.jsp" flush="true"/>
<script type="text/javascript" src="../effect.js"></script>
<script language="JavaScript" src="../get-date.js"></script>

<script language="JavaScript">
<!--
var noCal = false;		// if noCal, don't show calendar

var tog0 = false;	// default hide filter to begin with
init_img(0, "../i/filter_show.gif", "../i/filter_hide.gif");
if ('<%=bShowFilter%>'=='true')
{
	tog0 = true;
}

function fo()
{
	if (!tog0) return;
	Form = document.bugSearch;
	for (i=0;i < Form.length;i++)
	{
		if (Form.elements[i].type != "hidden")
		{
			Form.elements[i].focus();
			break;
		}
	}
	
	// check if bExportNoDisplay, redirect to export post page
	if (<%=bExportNoDisplay%>) {
		//document.body.style.cursor = "wait";
		exportForm.submit();
	}
}

function saveFilter()
{
	bugSearch.action = "../ep/save_pref.jsp";
	bugSearch.ShowBlog.value = ShowBlogForm.ShowBlog.checked;
	bugSearch.submit();
}

function sort(name)
{
	bugSearch.sortby.value = name;
	bugSearch.ShowBlog.value = ShowBlogForm.ShowBlog.checked;
	bugSearch.submit();
}

function toggle(text, i)
{
	if (i==0) tog = tog0;

	if (!tog)
		appear(text, i);
	else
		disappear(text, i);

	if (i==0) tog0 = !tog0;

	bugSearch.ShowFilter.value = tog0;
}

function showBlog()
{
	bugSearch.ShowBlog.value = ShowBlogForm.ShowBlog.checked;
	bugSearch.submit();
}

function showMax(bMax)
{
	if (bMax)
		bugSearch.ShowMax.value = "true";
	else
		bugSearch.ShowMax.value = "false";
	bugSearch.submit();
}

function exportCSV(bNoDisplay)
{
	if (bNoDisplay) {
		bugSearch.ExportNoDisplay.value = 'true';
		bugSearch.submit();
	}
	else {
		exportForm.submit();
	}
}


function show_cal(e1, e2)
{
	if (noCal) return;

	if (e2==null) e2 = e1;
	if (e1.value == "")
	{
		var today = new Date();
		e1.value =  today.getFullYear() + "." + (today.getMonth()+1) + "." + today.getDate();
		e2 = e1;
	}
	if (e2.value=="") e2.value=e1.value;
	var dt = new Date(e1.value)
	var mon = '' + dt.getMonth();

	var yr = '' + dt.getFullYear();
	var es = 'bugSearch.' + e1.name;
	var number = parseInt(mon);
	var number2 = parseInt(yr);

	if (isNaN(number) || isNaN(number2)) {
		dt = new Date();
		mon = '' + dt.getMonth();
		yr = '' + dt.getFullYear();
	}
	show_calendar(es, mon, yr, "YYYY.MM.DD");
}

//-->
</script>

<style type="text/css">
#bubbleDIV {position:relative;z-index:1;left:1em;top:.1em;width:3em;height:3em;vertical-align:bottom;text-align:center;}
img#bg {position:relative;z-index:-1;top:-2em;width:3em;height:3em;border:0;}
img#sign {position:relative;top:.4em;}
</style>

</head>

<title><%=Prm.getAppTitle()%> Search</title>
<body onload="fo();"  bgcolor="#FFFFFF" >

<form name="exportForm" action="./post_bug_export.jsp" method="post" >
	<input type='hidden' name='projId' value='<%=projIdS%>'/>
</form>

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
						<b>Change Request Summary</b>
					</td>
				  </tr>
	            </table>
	          </td>
	        </tr>
			<tr>
          		<td width="100%">
<!-- Navigation Menu -->
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Tracker" />
				<jsp:param name="subCat" value="ChangeSummary" />
				<jsp:param name="role" value="<%=iRole%>" />
				<jsp:param name="projId" value="<%=projIdS%>" />
			</jsp:include>
<!-- End of Navigation Menu -->
				</td>
	        </tr>
		</table>
		<!-- Content Table -->

		 <table width="90%" border="0" cellspacing="0" cellpadding="0">
			<tr>
				<td width="20"><img src="../i/spacer.gif" width="20" border="0"></td>
				<td>

	<table width="100%" cellpadding="0" cellspacing="0" border="0">

<tr>
	<td>&nbsp;&nbsp;&nbsp;&nbsp;
<%
	if (bShowFilter)
		out.print("<img id='nav0' name='nav0' onClick='toggle(\"menu\",0)' src='../i/filter_hide.gif' alt='hide' border='0' />");
	else
		out.print("<img id='nav0' name='nav0' onClick='toggle(\"menu\",0)' src='../i/filter_show.gif' alt='expand' border='0' />");
%>
	</td>

	<td colspan='2' align='right' class='plaintext'>
	
<form name="ShowBlogForm">
		<input type='checkbox' name='ShowBlog' onclick="javascript:showBlog()" <%if (bShowBlog)
				out.print("checked");%> />
			<b><font color='cc2222'>
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Show last posted blog")%>
			</font></b>
			<img src='../i/spacer.gif' width='20' height='1' />
</form>
			
	</td>
</tr>

<tr>
	<td colspan='2'>
<%
	if (bShowFilter)
		out.print("<div id='menu0' style='display: block'>");
	else
		out.print("<div id='menu0' style='display: none'>");
%>


<form name="bugSearch" action="bug_search.jsp" method="post" >
<input type='hidden' name='filterType' value='BugTrkFilter'/>
<input type="hidden" name="sortby" value="<%=sortby%>"/>
<input type="hidden" name="ShowBlog"/>
<input type="hidden" name="ShowFilter" value="<%=bShowFilter%>"/>
<input type="hidden" name="ShowMax"/>
<input type='hidden' name='ExportNoDisplay' value = '' />

<table width='100%' cellpadding="0" cellspacing="0" border="0">

<!-- CR Number -->
	<tr>
	<td width="15">&nbsp;</td>
		<td width="160" class="plaintext_blue">
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "CR Number")%>:
		</td>
		<td>
			<input type='text' name='bugId' size='30' value='<%=bugIdS%>'/>
		</td>
	</tr>
	<tr><td colspan='3'><img src='../i/spacer.gif' height='5'/></td></tr>

<!-- CR Synopsis -->
	<tr>
	<td width="15">&nbsp;</td>
		<td class="plaintext_blue">
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Synopsis")%>:
		</td>
		<td>
			<input type='text' name='synopsis' size='30' value='<%=synopsisS%>' />
		</td>
	</tr>
	<tr><td colspan='3'><img src='../i/spacer.gif' height='5'/></td></tr>

<!-- Project Name -->
	<tr>
	<td width="15">&nbsp;</td>
		<td class="plaintext_blue">
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Project")%>:
		</td>
		<td>
			<select name="projId" class="formtext">
<%
	out.print(Util.selectProject(pstuser, viewProjId));
%>
			</select>

		</td>
	</tr>
	<tr><td colspan='3'><img src='../i/spacer.gif' height='5'/></td></tr>

<!-- category -->
	<tr>
	<td width="15">&nbsp;</td>
		<td class="plaintext_blue">
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Category")%>:
		</td>
		<td>
			<select name="category" class="formtext">
			<option value=""> - - Select - - </option>
<%
	//CATEGORY = bug.BUG_CATEGORY_ARRAY;
	for (int i = 0; i < CATEGORY.length; i++) {
		out.print("<option value='" + CATEGORY[i] + "' ");
		if (CATEGORY[i].equals(viewCategory))
			out.print("selected");
		out.print(">" + CATEGORY[i] + "</option>");
	}
%>

			</select>
		</td>
	</tr>
	<tr><td colspan='3'><img src='../i/spacer.gif' height='5'/></td></tr>

<!-- process type -->
	<tr>
		<td width="15">&nbsp;</td>
			<td class="plaintext_blue">
				<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Process Type")%>:
			</td>
			<td>
				<select name="processType" class="formtext">
				<option value=""> - - Select - - </option>
<%
				for (int i = 0; i < PROCESS_TYPE.length; i++) {
					out.print("<option value='" + PROCESS_TYPE[i] + "'");
				
					if (PROCESS_TYPE[i].equals(viewProcessType))
						out.print(" selected");
					out.println(">" + PROCESS_TYPE[i] + "</option>");
				}
%>				
				</select>
			</td>
	</tr>
	<tr><td colspan='3'><img src='../i/spacer.gif' height='5'/></td></tr>


<!-- user department -->
	<tr>
		<td width="15">&nbsp;</td>
			<td class="plaintext_blue">
				<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "User Department")%>:
			</td>
			<td>
				<select name="userDept" class="formtext">
				<option value=""> - - Select - - </option>
<%
				for (int i = 0; i < USER_DEPT.length; i++) {
					out.print("<option value='" + USER_DEPT[i] + "'");
				
					if (USER_DEPT[i].equals(viewUserDept))
						out.print(" selected");
					out.println(">" + USER_DEPT[i] + "</option>");
				}
%>								
				</select>
			</td>
	</tr>
	<tr><td colspan='3'><img src='../i/spacer.gif' height='5'/></td></tr>

<!-- bug submitter -->
	<tr>
	<td width="15">&nbsp;</td>
	<td align="left" valign="middle" class="plaintext_blue">
		<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Submitter")%>:
	</td>
	<td>
			<select name="submitter" class="formtext">
			<option value=""> - - Select - - </option>
<%
	String uname;
	int oid;
	for (int i = 0; i < allMember.length; i++) {
		if (allMember[i] == null)
			continue;
		oid = allMember[i].getObjectId();
		uname = ((user) allMember[i]).getFullName();
		out.print("<option value='" + oid + "' ");
		if (oid == viewSubmitterId)
			out.print("selected");
		out.print(">" + uname + "</option>");
	}
%>
			</select>
	</td>
	</tr>
	<tr><td colspan='3'><img src='../i/spacer.gif' height='5'/></td></tr>


<!-- bug owner -->
	<tr>
	<td width="15">&nbsp;</td>
	<td align="left" valign="middle" class="plaintext_blue">
		<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Owner")%>:
	</td>
	<td>
		<table border='0' cellspacing='0' cellpadding='0'><tr>

<%
	String[] ownerLabel = { "" };
	if (numOfOwner > 1) {
		// need to insert label of multiple owner
		s = Util.getPropKey("pst", "BUG_OWNER_LABEL");
		if (s != null)
			ownerLabel = s.split(";");
	}

	for (int m = 0; m < numOfOwner; m++) {
		out.print("<td class='formtext' width='250'>");
		if (ownerLabel.length > m)
			out.print(ownerLabel[m].trim()
					+ ((ownerLabel[m].length() > 0) ? ": " : "")); // label
		out.print("<select name='owner" + m + "' class='formtext'>");
		out.print("<option value=''> - - Select - - </option>");

		for (int i = 0; i < allMember.length; i++) {
			if (allMember[i] == null)
				continue;
			oid = allMember[i].getObjectId();
			uname = ((user) allMember[i]).getFullName();
			out.print("<option value='" + oid + "' ");
			if (oid == viewOwnerId[m])
				out.print("selected");
			out.print(">" + uname + "</option>");
		}
		out.print("</td>");
	}
%>

			</select>
	</tr></table>
	</td>
	</tr>
	<tr><td colspan='3'><img src='../i/spacer.gif' height='5'/></td></tr>


<!-- status -->
	<tr>
	<td width="15">&nbsp;</td>
	<td align="left" valign="top" class="plaintext_blue">
		<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Status")%>:
	</td>
	<td>
		<table border='0' cellspacing='0' cellpadding='0'>
<%
	int num = 0;
	for (int i = 0; i < bug.STATE_ARRAY.length; i++) {
		if (num % RADIO_NUM == 0)
			out.print("<tr>");
		out.print("<td class='formtext' width='180'><input type='checkbox' name='"
				+ bug.STATE_ARRAY[i] + "'");
		if (request.getParameter(bug.STATE_ARRAY[i]) != null)
			out.print(" checked");
		out.print(">" + bug.STATE_ARRAY[i] + "</td>");
		if (num % RADIO_NUM == RADIO_NUM - 1)
			out.print("</tr>");
		num++;
	}
	if (num % RADIO_NUM != 0)
		out.print("</tr>");
%>
		</table>
	</td>
	</tr>
	<tr><td colspan='3'><img src='../i/spacer.gif' height='5'/></td></tr>


<!-- type -->
	<tr>
	<td width="15">&nbsp;</td>
	<td align="left" valign="top" class="plaintext_blue">
		<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Type")%>:
	</td>
	<td>
		<table border='0' cellspacing='0' cellpadding='0'>
<%
	num = 0;
	String [] bugTypeArr = IT_BUG_TYPE;		// bug.CLASS_ARRAY
	for (int i = 0; i < bugTypeArr.length; i++) {
		if (num % RADIO_NUM == 0)
			out.print("<tr>");
		out.print("<td class='formtext' width='180'><input type='checkbox' name='"
				+ bugTypeArr[i] + "'");
		if (request.getParameter(bugTypeArr[i]) != null)
			out.print(" checked");
		out.print(">" + bugTypeArr[i] + "</td>");
		if (num % RADIO_NUM == RADIO_NUM - 1)
			out.print("</tr>");
		num++;
	}
	if (num % RADIO_NUM != 0)
		out.print("</tr>");
%>
		</table>
	</td>
	</tr>
	<tr><td colspan='3'><img src='../i/spacer.gif' height='5'/></td></tr>


<!-- priority -->
	<tr>
	<td width="15">&nbsp;</td>
	<td align="left" valign="top" class="plaintext_blue">
		<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Priority")%>:
	</td>
	<td>
		<table border='0' cellspacing='0' cellpadding='0'>
<%
	num = 0;
	for (int i = 0; i < bug.PRI_ARRAY.length; i++) {
		if (num % RADIO_NUM == 0)
			out.print("<tr>");
		out.print("<td class='formtext' width='180'><input type='checkbox' name='"
				+ bug.PRI_ARRAY[i] + "'");
		if (request.getParameter(bug.PRI_ARRAY[i]) != null)
			out.print(" checked");
		out.print(">" + bug.PRI_ARRAY[i] + "</td>");
		if (num % RADIO_NUM == RADIO_NUM - 1)
			out.print("</tr>");
		num++;
	}
	int ii = num - RADIO_NUM;
	while (ii++ < 0)
		out.print("<td class='formtext' width='180'></td>");
	if (num % RADIO_NUM != 0)
		out.print("</tr>");
%>
		</table>
	</td>
	</tr>
	<tr><td colspan='3'><img src='../i/spacer.gif' height='5'/></td></tr>


<!-- severity -->
	<tr>
	<td width="15">&nbsp;</td>
	<td align="left" valign="top" class="plaintext_blue">
		<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Severity")%>:
	</td>
	<td>
		<table border='0' cellspacing='0' cellpadding='0'>
<%
	num = 0;
	for (int i = 0; i < severityValAry.length; i++) {
		if (num % RADIO_NUM == 0)
			out.print("<tr>");
		out.print("<td class='formtext' width='180'><input type='checkbox' name='"
				+ severityValAry[i] + "'");
		if (request.getParameter(severityValAry[i]) != null)
			out.print(" checked");
		out.print(">" + severityValAry[i] + "</td>");
		if (num % RADIO_NUM == RADIO_NUM - 1)
			out.print("</tr>");
		num++;
	}
	ii = num - RADIO_NUM;
	while (ii++ < 0)
		out.print("<td class='formtext' width='180'></td>");
	if (num % RADIO_NUM != 0)
		out.print("</tr>");
%>
		</table>
	</td>
	</tr>
	<tr><td colspan='3'><img src='../i/spacer.gif' height='5'/></td></tr>


<!-- Silicon Rev -->
	<tr>
	<td width="15">&nbsp;</td>
		<td class="plaintext_blue">
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Revision")%>:
		</td>
		<td>
			<input type='text' name='revision' size='30' value='<%=revS%>'/>
		</td>
	</tr>

	<tr><td colspan='3'><img src="../i/spacer.gif" width="1" height="5" border="0"/></td></tr>
	
<!-- Creation Date -->
	<tr>
	<td width="15">&nbsp;</td>
		<td class="plaintext_blue">
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Creation Date")%>:
		</td>
		<td>
		<table border='0' cellspacing='0' cellpadding='0'>
			<tr>
			<td>
			<input class="formtext" type="text" name="CreateDate1" size="20" value='<%if (createDate1S !=null) out.print(createDate1S); %>'  onClick="show_cal(bugSearch.CreateDate1);"/>
			&nbsp;<a href="javascript:show_cal(bugSearch.CreateDate1);" ><img src="../i/calendar.gif" border="0" align="absmiddle" alt="Click to view calendar."/></a>
			</td>
			<td width='100' align='center'>to</td>
			<td>
			<input class="formtext" type="text" name="CreateDate2" size="20" value='<%if (createDate2S !=null) out.print(createDate2S); %>'  onClick="show_cal(bugSearch.CreateDate2);"/>
			&nbsp;<a href="javascript:show_cal(bugSearch.CreateDate2);" ><img src="../i/calendar.gif" border="0" align="absmiddle" alt="Click to view calendar."/></a>
			</td>
			</tr>
		</table>
		</td>
	</tr>

	<tr><td colspan='3'><img src="../i/spacer.gif" width="1" height="15" border="0"/></td></tr>
	
<!-- Submit Button -->
	<tr>
	<td colspan="3" align="center">

		<input type='button' class='button_medium' name='SubmitButton' onclick='return submit();'
			value='<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Submit")%>' />
		<input type='button' class='button_medium' name="SaveFilter" onclick='saveFilter();'
			value='<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Save Filter")%>' />
			&nbsp;&nbsp;&nbsp;
		<input type='button' class='button_medium' onclick='javascript:exportCSV(true);'
			value='<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Export to Excel")%>' />
		
	</td>
	</tr>

	<tr><td colspan='3'><img src="../i/spacer.gif" width="1" height="15" border="0"/></td></tr>
	
	</table>

</form>
</div>

<tr>
	<td id="adjust" height="100%"></td>
</tr>


</td></tr>
</table>

<%
	if (bExportNoDisplay)
		out.print("<div id='bugListDiv' style='display:none'>");
	else
		out.print("<div id='bugListDiv' style='display:block'>");
%>

<!-- ********************************************   Display Bug Headers   ******************************************** -->

<%
	int columnNum = 35 + 3 * numOfOwner;

%>

<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td>
	<table width='100%' border='0' cellspacing='0' cellpadding='0'>
	
	<tr>
	<td class='ptextS2' colspan='<%=columnNum - 6%>'>
		<b><%=projName%></b><img src='../i/spacer.gif' width='200' height='1'/>
		<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "No. of CR listed")%>
		&nbsp;= <%=showBugNum%> of <%=iSize%>
	</td>
	
<%	if (bTooManyBugs) { %>
				<td align='right'>
				<table width='100%' border='0' cellspacing='0' cellpadding='0'>
					<tr>
						<td align='right'>
							<img src='../i/bullet_tri.gif'/>
<%		if (bShowMax) {
			out.print("<a class='listlinkbold' href='javascript:showMax(false);'>Show top " + BUG_NUM_LIMIT + " items on the list</a>");
		}
		else {
			out.print("<a class='listlinkbold' href='javascript:showMax(true);'>Show ALL items (" + iSize + ")</a>");
		}
%>
							
							<img src='../i/spacer.gif' width='20' height='1' />
						</td>
					</tr>
				</table>
				</td>
<%	}	// END if: too many bugs %>

	</tr>
	</table>
	</td>
</tr>

<tr>
<td>
	<table width="100%" border='0' cellpadding="0" cellspacing="0">
	<tr>
	<td bgcolor="#EBECED" height="3"><img src="../i/spacer.gif" width="1" height="3" border="0"/></td>
	</tr>
	</table>
	<table width="100%" border="0" cellspacing="0" cellpadding="0">
	<tr>
	<td colspan="<%=columnNum%>" height="2" bgcolor="#336699"><img src="../i/spacer.gif" width="1"/></td>
	</tr>
	<tr>
<%
	if (sortby == null) {
		out.print("<td width='4' " + srcl
				+ " class='10ptype'>&nbsp;</td>");
		out.print("<td width='25' " + srcl
				+ " class='td_header'><b>&nbsp;CR #</b></td>");
	} else {
		out.print("<td width='4' " + bgcl + ">&nbsp;</td>");
		out.print("<td width='25' class='td_header' "
				+ bgcl
				+ "><a href='javascript:sort(\"\")'><font color='ffffff'><strong>&nbsp;CR #</strong></font></a></td>");
	}
%>

	<td width='1' bgcolor="#FFFFFF"><img src="../i/spacer.gif" width="1"></td>
<%
	if (sortby != null && sortby.equals("st")) {
		out.print("<td width='4' " + srcl + ">&nbsp;</td>");
		out.print("<td width='15' class='td_header' " + srcl
				+ "><b>St.</b></td>");
	} else {
		out.print("<td width='4' " + bgcl + ">&nbsp;</td>");
		out.print("<td width='15' class='td_header' "
				+ bgcl
				+ "><a href='javascript:sort(\"st\")'><font color='ffffff'><b>St.</b></font></a></td>");
	}

%>

	<td width='1' bgcolor="#FFFFFF" ><img src="../i/spacer.gif" width="1"/></td>

	<td width="2" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width='20%' bgcolor="#6699cc" class="td_header" align="left"><b>
		<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Synopsis")%></b></td>

	<td width='1' bgcolor="#FFFFFF"><img src="../i/spacer.gif" width="1"/></td>

<%
	s = StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Submit");
	if (sortby != null && sortby.equals("su")) {
		out.print("<td width='4' " + srcl + ">&nbsp;</td>");
		out.print("<td width='6%' class='td_header' " + srcl
				+ "><b>"
				+ s
				+ "</b></td>");
	} else {
		out.print("<td width='4' " + bgcl + ">&nbsp;</td>");
		out.print("<td width='6%' class='td_header' "
				+ bgcl
				+ "><a href='javascript:sort(\"su\")'><font color='ffffff'><b>"
				+ s
				+ "</b></font></a></td>");
	}

	// @ECC040506 support multiple owners
	s = StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Owner");
	for (int i = 0; i < numOfOwner; i++) {
		out.print("<td width='1' bgcolor='#FFFFFF'><img src='../i/spacer.gif' width='1'/></td>");
		if (sortby != null && sortby.equals("ow" + i)) {
			out.print("<td width='4' " + srcl + ">&nbsp;</td>");
			out.print("<td width='6%' class='td_header' align='center' "
					+ srcl
					+ "><b>"
					+ s + " "
					+ ownerLabel[i].trim()
					+ "</b>");
		} else {
			out.print("<td width='4' " + bgcl + ">&nbsp;</td>");
			out.print("<td width='6%' class='td_header' align='center' "
					+ bgcl
					+ "><a href='javascript:sort(\"ow"
					+ i
					+ "\")'><font color='ffffff'><b>"
					+ s + " "
					+ ownerLabel[i].trim()
					+ "</b></font></a></td>");
		}
	}
%>

	<td width='1'><img src="../i/spacer.gif" width="1"/></td>
	<td colspan='2' width="6%" bgcolor="#6699cc" class="td_header" align="center"><b>
		<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Proj ID")%></b></td>

	<td width='1' bgcolor="#FFFFFF"><img src="../i/spacer.gif" width="1"/></td>
	<td width="2" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td colspan='2' width="6%" bgcolor="#6699cc" class="td_header" align="center"><b>
		<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Blog")%></b></td>

	<td width='1' bgcolor="#FFFFFF"><img src="../i/spacer.gif" width="1"/></td>
<%
	s = StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Category");
	if (sortby != null && sortby.equals("ca")) {
		//out.print("<td width='4' " + srcl + ">&nbsp;</td>");
		out.print("<td colspan='2' width='10%' class='td_header' align='center' "
				+ srcl + "><b>"
				+ s
				+ "</b></td>");
	} else {
		//out.print("<td width='4' " + bgcl + ">&nbsp;</td>");
		out.print("<td colspan='2' width='10%' class='td_header' align='center' "
				+ bgcl
				+ "><a href='javascript:sort(\"ca\")'><font color='ffffff'><b>"
				+ s
				+ "</b></font></a></td>");
	}
%>

	<td width='1' bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="1"/></td>
<%
	s = StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Type");
	if (sortby != null && sortby.equals("ty")) {
		//out.print("<td width='4' " + srcl + ">&nbsp;</td>");
		out.print("<td colspan='2' width='10%' class='td_header' align='center' "
				+ srcl + "><b>"
				+ s
				+ "</b></td>");
	} else {
		//out.print("<td width='4' " + bgcl + ">&nbsp;</td>");
		out.print("<td colspan='2' width='10%' class='td_header' align='center' "
				+ bgcl
				+ "><a href='javascript:sort(\"ty\")'><font color='ffffff'><b>"
				+ s
				+ "</b></font></a></td>");
	}

	s = StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Pri");
	out.print("<td width='1' bgcolor='#FFFFFF'><img src='../i/spacer.gif' width='1'/></td>");
	if (sortby != null && sortby.equals("pr")) {
		out.print("<td colsapn='2' width='4%' class='td_header' align='center' "
				+ srcl + "><b>"
				+ s
				+ "</b></td>");
	} else {
		out.print("<td colsapn='2' width='4%' class='td_header' align='center' "
				+ bgcl
				+ "><a href='javascript:sort(\"pr\")'><font color='ffffff'><b>"
				+ s
				+ "</b></font></a></td>");
	}

	s = StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Sev");
	out.print("<td width='1' bgcolor='#FFFFFF'><img src='../i/spacer.gif' width='1'></td>");
	if (sortby != null && sortby.equals("sv")) {
		out.print("<td width='4' " + srcl + ">&nbsp;</td>");
		out.print("<td colsapn='2' width='3%' class='td_header' align='center' "
				+ srcl + "><b>"
				+ s
				+ "</b>");
	} else {
		out.print("<td width='4' " + bgcl + ">&nbsp;</td>");
		out.print("<td colsapn='2' width='3%' class='td_header' align='center' "
				+ bgcl
				+ "><a href='javascript:sort(\"sv\")'><font color='ffffff'><b>"
				+ s
				+ "</b></font></a>");
	}

	out.print("<td width='1' bgcolor='#FFFFFF'><img src='../i/spacer.gif' width='1'/></td>");
	
	s = StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Updated");
	if (sortby != null && sortby.equals("up")) {
		//out.print("<td width='4' " + srcl + ">&nbsp;</td>");
		out.print("<td colspan='2' width='5%' class='td_header' align='center' "
				+ srcl + "><b>"
				+ s
				+ "</b></td>");
	} else {
		out.print("<td width='4' " + bgcl + ">&nbsp;</td>");
		out.print("<td width='5%' class='td_header' align='center' "
				+ bgcl
				+ "><a href='javascript:sort(\"up\")'><font color='ffffff'><b>"
				+ s
				+ "</b></font></a></td>");
	}
%>

	<td width='1' bgcolor="#FFFFFF"><img src="../i/spacer.gif" width="1"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="5%"bgcolor="#6699cc" class="td_header" align="center"><b>
		<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Age")%></b></td>
	</tr>


<!-- list of bugs -->
<%

/***************************************************************************************/
	try {
		String bgcolor = "";
		boolean even = false;
		int bugId, blogNum;

		String dot;
		user empObj = null, subObj;
		String[] ownerIdS = new String[numOfOwner];

		String status, synopsis, submitter, projectID, taskID, type, priority, severity, release, category, linkS;
		String begB = "<B>", endB = "</B>";

		Date lastUpdate, dt;

		resultManager rMgr = resultManager.getInstance();
		result blog;
		int[] blogIds = null;
		String lName, completeDtS = "";
		user bUser;
		int count = 0;
		
		long toDayT = new Date().getTime();
		
		PstAbstractObject [] showBugList;
		if (bExportNoDisplay)
			showBugList = new PstAbstractObject[0];		// so to skip the for loop below
		else
			showBugList = bugObjList;

		////////////////////////////////////////////////////
		// show the list of bugs
		//
		for (int i = showBugList.length - 1; i >= 0; i--) { // a list of bugs satisfied the search expr
			bug bugObj = (bug) bugObjList[i];
			if (bugObj == null)
				continue;

			if (count++ > showBugNum) break;		// reach to the number of bugs to be shown on this page, stop
			
			bugId = bugObj.getObjectId();
			status = (String) bugObj.getAttribute("State")[0];
			synopsis = (String) bugObj.getAttribute("Synopsis")[0];
			submitter = (String) bugObj.getAttribute("Creator")[0];
			projectID = (String) bugObj.getAttribute("ProjectID")[0];
			taskID = (String) bugObj.getAttribute("TaskID")[0];
			type = (String) bugObj.getAttribute("Type")[0];
			priority = (String) bugObj.getAttribute("Priority")[0];
			severity = (String) bugObj.getAttribute("Severity")[0];
			lastUpdate = (Date) bugObj.getAttribute("LastUpdatedDate")[0];
			release = (String) bugObj.getAttribute("Release")[0];
			category = (String) bugObj.getAttribute("Category")[0];
			for (int j = 0; j < numOfOwner; j++) {
				ownerIdS[j] = (String) bugObj.getAttribute(ownerAttr[j])[0]; // @ECC040506
			}


			if (status == null) {
				l.error("Blank bug found [" + bugId + "]");
				continue;
			}

			if (even)
				bgcolor = "bgcolor='#EEEEEE'";
			else
				bgcolor = "bgcolor='#ffffff'";
			even = !even;
			out.print("<tr "
					+ bgcolor
					+ ">"
					+ "<td colspan='"
					+ columnNum
					+ "'><img src='../i/spacer.gif' width='2' height='10'></td></tr>");

			// CR Number
			out.print("<tr " + bgcolor + ">");
			out.print("<td colspan='2' class='listtext' valign='top'>&nbsp;");
			out.print("<a class='listlink' href='../bug/bug_update.jsp?bugId="
					+ bugId + "'>");
			out.print(bugId + "</a>");
			out.println("</td>");

			// status
			dot = "../i/";
			if (!status.equals(bug.OPEN) && !status.equals(bug.ACTIVE)) {
				dt = (Date) bugObj.getAttribute("CompleteDate")[0];
				if (dt != null) {
					completeDtS = " - completed on " + df1.format(dt);
				} else
					completeDtS = "";
			} else
				completeDtS = "";
			s = status;
			if (status.equals(bug.OPEN)) {
				dot += "dot_orange.gif";
				s = "new";
			} else if (status.equals(bug.ACTIVE)) {
				dot += "dot_lightblue.gif";
			} else if (status.equals(bug.ANALYZED)) {
				dot += "dot_blue.gif";
			} else if (status.equals(bug.FEEDBACK)) {
				dot += "dot_green.gif";
			} else if (status.equals(bug.CLOSE)) {
				dot += "dot_black.gif";
			} else {
				dot += "dot_grey.gif";
			}
			out.print("<td colspan='3' class='plaintext' align='center' valign='top'>");
			out.print("<img src='" + dot + "' title='" + status
					+ completeDtS + "'>");
			out.println("</td>");


			// synopsis
			out.print("<td></td>");
			out.print("<td colspan='2' class='plaintext' valign='top'><table border='0' cellspacing='0' cellpadding='0'>");
			out.print("<tr><td><img src='../i/spacer.gif' width='2' height='2'></td>");
			out.print("<td class='ptextS1' valign='top'>");
			out.print(synopsis);
			out.println("</td></tr></table></td>");


			// submitter
			out.print("<td></td>");
			out.print("<td colspan='2' class='listtext' align='center' valign='top'>");
			try {
				subObj = (user) uMgr.get(pstuser, Integer.parseInt(submitter));
			
				if (subObj.getObjectName().equalsIgnoreCase("ticket system")) {
					// Ticket System, just show Email2
					s = bugObj.getStringAttribute("Email2");
					if (StringUtil.isNullOrEmptyString(s))
						s = "Ticket";
					else if ((idx=s.indexOf('@')) != -1)
						s = "Ticket/" + s.substring(0,idx);
					out.print(s);
				}
				else {
					out.print("<a class='listlink' href='../ep/ep1.jsp?uid="
							+ subObj.getObjectId() + "'>");
		
					out.print((String) subObj.getAttribute("FirstName")[0]);
					lName = (String) subObj.getAttribute("LastName")[0];
					out.print(printChar(lName));
					out.print("</a>");
				}
			}
			catch (Exception e) {
				out.print("-");
			}

			out.println("</td>");


			// owner
			for (int j = 0; j < numOfOwner; j++) {
				out.print("<td></td>");
				out.print("<td colspan='2' class='listtext' align='center' valign='top'>");
				if (ownerIdS[j] != null) {
					// ECC: need to optimize this in the near future			
					try {
						empObj = (user) uMgr.get(pstuser, Integer.parseInt(ownerIdS[j]));
						uid = empObj.getObjectId();
						out.print("<a class='listlink' href='../ep/ep1.jsp?uid="
								+ uid + "'>");
						out.print(empObj.getFullName());
						//out.print((String) empObj.getAttribute("FirstName")[0]);
						//lName = (String) empObj.getAttribute("LastName")[0];
						//out.print(printChar(lName));
						out.print("</a>");					}
					catch (Exception e) {
						System.out.println("Error getting user [" + ownerIdS[j] + "]");
						out.print("-");
					}
								
				} else
					out.print("-");
				out.println("</td>");
			}


			// project ID
			out.print("<td></td>");
			out.print("<td colspan='2' class='listtext' align='center' valign='top'>");
			if (projectID == null)
				out.print("-");
			else {
				out.print("<a class='listlink' href='../project/proj_plan.jsp?projId="
						+ projectID + "'>");
				out.print(projectID + "</a>");
			}
			out.println("</td>");

			/*		// task ID
			 out.print("<td></td>");
			 out.print("<td colspan='2' class='listtext' align='center' valign='top'>");
			 if (taskID == null)
			 out.print("-");
			 else
			 {
			 out.print("<a class='listlink' href='../project/task_update.jsp?projId="
			 + projectID + "&taskId=" + taskID + "'>");
			 out.print(taskID);
			 out.print("</a>");
			 }
			 out.println("</td>");
			 */

			// blog Num
			//blogIds = rMgr.findId(pstuser, "TaskID='" + bugId + "'");
			//blogNum = blogIds.length;
			blogNum = rMgr.getCount(pstuser, "TaskID='" + bugId + "'");
			if (blogNum <= 0) {
				linkS = "../blog/addblog.jsp?type="
						+ result.TYPE_BUG_BLOG + "&id=" + bugId
						+ "&backPage=../bug/bug_update.jsp?bugId="
						+ bugId;
			} else {
				linkS = "../blog/blog_task.jsp?projId=" + projIdS
						+ "&bugId=" + bugId;
			}
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td><a href='" + linkS
					+ "'><div id='bubbleDIV'>");
			out.print(begB + blogNum + endB);
			out.print("<img id='bg' src='../i/bubble.gif' />");
			out.println("</div></a></td>");

			// category
			out.print("<td></td>");
			out.print("<td colspan='2' class='listtext_small' valign='top' align='center'>");
			out.print(category == null ? "-" : category);
			out.println("</td>");

			// type
			out.print("<td></td>");
			out.print("<td colspan='2' class='listtext_small' align='center' valign='top'>");
			out.print(type);
			out.println("</td>");

			// priority {HIGH, MEDIUM, LOW}
			out.print("<td></td>");
			out.print("<td colspan='2' class='listtext' align='center' valign='top'>");
			if (priority == null) priority = bug.PRI_MED;
			if (priority.startsWith(bug.PRI_HIGH)) {
				out.print("<font color=" + action.COLOR_HIGH + "><b>H");
				out.print("-");
				if (priority.length() > bug.PRI_HIGH.length())
					out.print(Integer.parseInt(priority
							.substring(bug.PRI_HIGH.length())));
				else
					out.print(0);
				out.print("</b>");
			} else if (priority.equals(bug.PRI_MED))
				out.print("<font color=" + action.COLOR_MED
						+ "><b>M</b>");
			else
				out.print("<font color=" + action.COLOR_LOW
						+ "><b>L</b>");
			out.print("</font>");
			out.println("</td>");

			// severity
			out.print("<td></td>");
			out.print("<td colspan='2' class='listtext' align='center' valign='top'>");
			if (severity == null)
				out.print("-");
			else {
				if (severity.equals(bug.SEV_CRI))
					out.print("<font color=" + action.COLOR_HIGH
							+ "><b>C</b>");
				else if (severity.equals(bug.SEV_SER))
					out.print("<font color=" + action.COLOR_MED
							+ "><b>S</b>");
				else if (severity.equals(bug.SEV_NCR))
					out.print("<font color=" + action.COLOR_LOW
							+ "><b>NC</b>");
				else {
					out.print("<font color=" + action.COLOR_HIGH
							+ "><b>Sc-");
					idx = severity.indexOf('-');
					if (idx != -1) {
						s = severity.substring(idx + 1);
						out.print(s);
					}
					out.print("</b></font>");
				}
			}
			out.println("</td>");

			// last updated date
			out.print("<td></td>");
			out.print("<td colspan='2' class='listtext_small' align='center' valign='top'>");
			if (lastUpdate != null)
				out.print(df1.format(lastUpdate));
			else
				out.print("-");
			out.println("</td>");

			// release (silicon revision) or Age
			out.print("<td></td>");
			out.print("<td colspan='2' class='listtext_small' align='center' valign='top'>");
			if (release == null) {
				// show age of bug
				dt = (Date)bugObj.getAttribute("CreatedDate")[0];
				release = String.valueOf((toDayT - dt.getTime())/86400000 + 1);		//"-"
			}
			out.print(release);
			out.print("</td>");

			out.print("</tr>");
			out.print("<tr "
					+ bgcolor
					+ ">"
					+ "<td colspan='"
					+ columnNum
					+ "'><img src='../i/spacer.gif' width='2' height='2'></td></tr>");

			// @ECC090605 display blog

			if (bShowBlog) {
				out.print("<tr " + bgcolor + "><td colspan='"
						+ columnNum + "' align='center'>");
				s = Util.showLastBlog(pstuser, projIdS,
						String.valueOf(bugId), "Bug", "100px", "auto",
						-1);
				out.println(s);
				out.print("</td></tr>");
			}

			//out.print("<tr " + bgcolor + ">" + "<td colspan='" +columnNum+ "'><img src='../i/spacer.gif' width='2' height='10'></td></tr>");
		}	// END: for loop of showBugList
		
		//out.println("</table>");
	} catch (Exception e) {
		response.sendRedirect("../out.jsp?msg=Internal error in displaying bug list.  Please contact administrator.");
		return;
	}

	// total
	out.print("<tr>"
			+ "<td colspan='"
			+ columnNum
			+ "'><img src='../i/spacer.gif' width='2' height='10'/></td></tr>");
%>


		<tr>
			<td class='ptextS2' colspan='<%=columnNum - 6%>'><b>
					<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "No. of CR listed")%> = <%=showBugNum%> of <%=iSize%></b></td>
			<td class='ptextS2' colspan='6'>
				<input type='button' class='button_medium' onclick='javascript:exportCSV(false);'
					value='<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Export to Excel")%>'
				/>
			</td>
		</tr>
		
	</table>

		</td>
		</tr>
		<tr><td colspan="2">&nbsp;</td></tr>
		

	</table>
<%	out.print("</div>");		// close bugListDiv

%>
	
<!-- END BUG LISTING -->



<table>
	<tr>
		<td width='40' class="tinytype">Status:</td>
		<td class="tinytype">&nbsp;<img src="../i/dot_orange.gif" border="0"/>
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "new")%></td>
		<td class="tinytype">&nbsp;<img src="../i/dot_lightblue.gif" border="0"/>
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, bug.ACTIVE)%></td>
		<td class="tinytype">&nbsp;<img src="../i/dot_blue.gif" border="0"/>
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, bug.ANALYZED)%></td>
		<td class="tinytype">&nbsp;<img src="../i/dot_green.gif" border="0"/>
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, bug.FEEDBACK)%></td>
		<td class="tinytype">&nbsp;<img src="../i/dot_black.gif" border="0"/>
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, bug.CLOSE)%></td>
	</tr>
	<tr>
		<td width='40' class="tinytype">Priority:</td>
		<td class="tinytype">&nbsp;&nbsp;<font color=<%=action.COLOR_HIGH%>><b>H</b></font> = 
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "High")%></td>
		<td class="tinytype">&nbsp;&nbsp;<font color=<%=action.COLOR_MED%>><b>M</b></font> = 
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Medium")%></td>
		<td class="tinytype">&nbsp;&nbsp;<font color=<%=action.COLOR_LOW%>><b>L</b></font> = 
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Low")%></td>
		<td></td>
		<td></td>
	</tr>
	<tr>
		<td width='40' class="tinytype">Severity:</td>
		<td class="tinytype">&nbsp;&nbsp;<font color=<%=action.COLOR_HIGH%>><b>Sc</b></font> = 
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Scrum")%></td>
		<td class="tinytype">&nbsp;&nbsp;<font color=<%=action.COLOR_HIGH%>><b>C</b></font> = 
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Critical")%></td>
		<td class="tinytype">&nbsp;&nbsp;<font color=<%=action.COLOR_MED%>><b>S</b></font> = 
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Serious")%></td>
		<td class="tinytype">&nbsp;&nbsp;<font color=<%=action.COLOR_LOW%>><b>NC</b></font> = 
			<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Non-Critical")%></td>
		<td></td>
		<td></td>
	</tr>
</table>

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


