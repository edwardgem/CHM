<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
	////////////////////////////////////////////////////
	//	Copyright (c) 2005, EGI Technologies.  All rights reserved.
	//
	//
	//	File:	bug_update.jsp
	//	Author:	ECC
	//	Date:	01/05/05
	//	Description:
	//		Display, new and update the CR.  Only allow bug owner, proj owner or Chief to update.
	//		NOTE: We must make sure all managers (bug assigner) of engineers involved in projects
	//		of their engineers, otherwise bug_update.jsp would not have the project the engineer chose.
	//
	//	Modification:
	//			@041905ECC	Construct workflow to manage the lifecycle of the bug.
	//			@ECC082605	Added Class ISSUE.  Issue can be elevated to a formal CR and be tracked in lifecycle.
	//			@ECC113005	Allow Site Admin to delete any bugs.
	//			@AGQ032906	Moved form to outside of table (for compatibility with Multi upload)
	//						Added multi upload feature.
	//			@ECC040506	Support multiple owners.
	//			@ECC041406	Support user-defined bug priority.
	//			@041906SSI	Added sort function to Project names.
	//			@SWS061406	Updated file listing and added show blog files.
	//
	////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>
<%@ page import = "javax.servlet.*" %>
<%@ page import = "javax.servlet.http.*" %>

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	String bugId = request.getParameter("bugId");
	String editS = request.getParameter("edit");
	String noSession = "../out.jsp?go=bug/bug_update.jsp?bugId="
			+ bugId + ":edit=" + editS;
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />


<%
	final int RADIO_NUM = 5;
	final int MAX_SCRUM_NUM = 12;
	final boolean bMustFillCategory = true;
	
	// ECC: customized categories
	// below are the defaults. Companies can customize these by changing the Category
	// attribute in town. Projects associated to the town will pick up the customized items.
	// @CAT=..;..;...@DEP=..;..;...@PRC=..;..;...
	
	//final String [] CAT1 = bug.BUG_CATEGORY_ARRAY;
	final String[] CAT2 = { "ABS", "CIS", "HIS", "CSS", "LIS", "PACS",
	"NIS", "HRP", "ORION", "ABS", "Dictionary", "Workflow", "Others" };
	//final String [] CAT2 = {"操作问题", "程序问题", "字典问题", "病历维护问题", "流程问题", "消息问题", "需求", "ABS", "CIS", "HIS", "CSS", "LIS", "PACS", "NIS", "HRP", "Dictionary", "Workflow", "Others"};
	final String[] USR2 = { "药剂科", "收费处", "门诊医生", "门诊护士", "住院医生",
	"住院护士", "影像科", "病理科", "院感科", "体检科", "-----", "人力资源部",
	"行政及后勤", "医疗物料采购部", "资讯科技部", "财务部", "ICS用户组", "CSSD用户组" };
	final String[] PRC2 = { "门诊挂号", "门诊收费", "收费报表", "分诊",
	"叫号屏显示", "处方打印", "手术申请", "入院登记", "住院结算", "医嘱处理", "电子病历",
	"执行单", "药品提交", "门诊发药", "住院发药", "药品字典界面", "医保相关", "出入库",
	"库存管理" };
	
	final String[] IT_BUG_TYPE = { bug.CLASS_ISSUE, bug.CLASS_DS,
			bug.CLASS_PS, bug.CLASS_HW, bug.CLASS_SW, "messaging-bug",
			"dictionary-bug", bug.CLASS_DOC, "database-issue",
			"medical record-issue", "UI-issue", "user-issue",
			bug.CLASS_SP, bug.CLASS_CH };

	final String [] SAS_BUG_TYPE = {"聘用制度", "绩效评核", "薪酬制度", "员工福利", "纪律管理", "培训发展", "其它"};



	final String P0 = "P0 - 系统瘫痪";
	final String P1 = "P1 - 病人安全";
	final String P2 = "P2 - 收费问题";
	final String P3 = "P3 - 政策要求";
	final String P4 = "P4 - 工作效率";
	final String[] P = { P0, P1, P2, P3, P4 };

	String[] CATEGORY = CAT2;
	
	String[] USER_DEPT = USR2;
	
	String[] PROCESS_TYPE = PRC2;

	if (pstuser instanceof PstGuest) {
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	String host = Util.getPropKey("pst", "PRM_HOST");
	int myId = pstuser.getObjectId();
	String pstuserIdS = String.valueOf(myId);

	String locale = (String) session.getAttribute("locale");

	int iRole = ((Integer) session.getAttribute("role")).intValue();
	boolean isAdmin = ((iRole & user.iROLE_ADMIN) > 0);
	boolean isManager = ((iRole & user.iROLE_MANAGER) > 0);
	boolean isProgMgr = ((iRole & user.iROLE_PROGMGR) > 0);

	boolean isEnableScrum = true;

	// bug
	String taskId = request.getParameter("taskId");
	String s;
	String[] sa;

	// @ECC040506 support for multiple owners
	int numOfOwner; // total no. of owners
	boolean isBugOwner = false;
	boolean isSubmitter = false;
	boolean isCoordinator = false;
	
	
	String[] ownerAttr; // array that holds the attribute names
	s = Util.getPropKey("pst", "BUG_OWNER_ATTRIBUTE");
	if (!StringUtil.isNullOrEmptyString(s)) {
		sa = s.split(";"); // e.g. Owner; Owner1
		numOfOwner = sa.length;
		ownerAttr = new String[numOfOwner];
		for (int i = 0; i < numOfOwner; i++)
			ownerAttr[i] = sa[i].trim();
	} else {
		numOfOwner = 1;
		ownerAttr = new String[1];
		ownerAttr[0] = "Owner"; // default owner attr name
	}
	int projId = 0;
	String projName = (String) session.getAttribute("projName");
	String title = null;
	String status = null;
	String bugClass = bug.CLASS_ISSUE; // default
	String bugPriority = bug.PRI_MED; // default
	String bugSeverity = bug.SEV_NCR; // default
	String bText = ""; //"<b>Description:</b><br><br><b>How To Repeat:</b><br><br><b>Fix:</b><br><br>";
	String synopsis = "";
	String release = ""; // the release the bug is found
	String category = ""; // the category of the bug
	String processType = ""; // the related process of this bug
	String userDepartment = ""; // the user department raising this request
	user u, submitter;
	String submitterFullname = null;

	Object bTextObj;
	String resoln = "", soln = "";

	Date lastUpdated = null;
	Date created = null;
	String creator = null;
	int coordinatorId = 0; // project coordinator
	int submitterId = 0;
	int managerId = 0; // @041905ECC
	String firstEmpName = null;
	String lastEmpName = null;
	boolean bDisplay = false;
	boolean bCreateNew = false;
	boolean bCanDelete = false;

	userManager uMgr = userManager.getInstance();
	projectManager pjMgr = projectManager.getInstance();
	bugManager bugMgr = bugManager.getInstance();
	attachmentManager aMgr = attachmentManager.getInstance();
	resultManager rMgr = resultManager.getInstance();
	townManager tnMgr = townManager.getInstance();
	userinfoManager uiMgr = userinfoManager.getInstance();

	PstUserAbstractObject owner;
	SimpleDateFormat df = new SimpleDateFormat("MM/dd/yyyy");
	userinfo.setTimeZone(pstuser, df);

	PstAbstractObject[] teamMember = null;
	project pj = null;
	bug bugObj = null;
	boolean bShowBfile = false;
	String bugReason = "";
	boolean bHasProcessType = true; // OMM DB contains this def
	boolean bHasUserDepartment = true; // OMM DB contains this def
	int thisBugId = 0;
	boolean isSAS = false;


	if (!StringUtil.isNullOrEmptyString(bugId)) {
		// either Edit or Display a specific bug
		try {
			thisBugId = Integer.parseInt(bugId);
			bugObj = (bug) bugMgr.get(pstuser, thisBugId);
		} catch (PmpException e) {
			response.sendRedirect("../out.jsp?e=The CR has been removed from the database.");
			return;
		}
		bTextObj = bugObj.getAttribute("Description")[0];
		if (bTextObj != null)
			bText = new String((byte[]) bTextObj, "utf-8");

		if (editS != null && editS.equals("true"))
			title = "Edit Change Request";
		else {
			title = "Review Change Request";
			bDisplay = true;
		}

		// get all the bug attributes
		bugObj = (bug) bugMgr.get(pstuser, bugId);
		s = (String) bugObj.getAttribute("ProjectID")[0];
		if (s != null) {
			projId = Integer.parseInt(s);
			projName = PstManager.getNameById(pstuser, projId);

			// need to get project coordinator
			pj = (project) pjMgr.get(pstuser, projId);
			coordinatorId = Integer.parseInt((String) pj
					.getAttribute("Owner")[0]);
		}

		isCoordinator = (coordinatorId == myId);

		if (projName.indexOf('@') != -1) {
			// I need the display name instead
			if (pj == null)
				pj = (project) pjMgr.get(pstuser, projName);
			projName = pj.getDisplayName();
			projId = pj.getObjectId();
		}
		isSAS = projName.equals("SAS");

		submitterId = Integer.parseInt((String) bugObj.getAttribute("Creator")[0]);
		submitter = (user) uMgr.get(pstuser, submitterId);
		submitterFullname = submitter.getFullName();

		isSubmitter = (submitterId == myId);

		status = (String) bugObj.getAttribute("State")[0];
		bugClass = (String) bugObj.getAttribute("Type")[0];
		
		if (bugClass.equals(bug.CLASS_ISSUE) && editS != null
				&& editS.equals("true"))// @ECC082605
			bugClass = bug.CLASS_DS; // default to design-bug
			
		bugPriority = (String) bugObj.getAttribute("Priority")[0];
		if (bugPriority == null)
			bugPriority = bug.PRI_MED;
		
		bugSeverity = (String) bugObj.getAttribute("Severity")[0];
		if (bugSeverity == null)
			bugSeverity = bug.SEV_NCR;
		//synopsis = Util.stringToHTMLString((String)bugObj.getAttribute("Synopsis")[0]);
		
		synopsis = (String) bugObj.getAttribute("Synopsis")[0];
		
		release = (String) bugObj.getAttribute("Release")[0];
		if (release == null)
			release = "";
		
		category = (String) bugObj.getAttribute("Category")[0];
		
		try {
			processType = (String) bugObj.getAttribute("ProcessType")[0];
		} catch (PmpException e) {
			bHasProcessType = false;
		}
		try {
			userDepartment = (String) bugObj
					.getAttribute("DepartmentName")[0];
		} catch (PmpException e) {
			bHasUserDepartment = false;
		}

		taskId = (String) bugObj.getAttribute("TaskID")[0];

		// check to see if show blog file
		s = request.getParameter("ShowBfile");
		if (s != null && s.equals("true"))
			bShowBfile = true;

		// allow removing bugs that are OPEN and MISTAKEN (@ECC113005)
		bugReason = (String) bugObj.getAttribute("Result")[0];
		if (bugReason == null)
			bugReason = "";
		if (isAdmin
				|| (status.equals(bug.OPEN) && (isCoordinator || isProgMgr))
				|| ((status.equals(bug.OPEN) || status.equals(bug.ACTIVE))
						&& bugReason.equals(bug.REA_MSTK) && (isSubmitter || isCoordinator))) {
			s = request.getParameter("delete");
			if (s != null && s.equals("true")) {
				bugObj.deleteBug(pstuser);
				response.sendRedirect("../out.jsp?msg=The CR ["
						+ bugId
						+ "] has been removed from the database successfully&go=bug/bug_search.jsp");
				return;
			}
			bCanDelete = true;
		}

		// @ECC040506 check to see if I am an owner of the bug
		for (int i = 0; i < numOfOwner; i++) {
			s = (String) bugObj.getAttribute(ownerAttr[i])[0];
			if (s == null)
				continue;
			if (Integer.parseInt(s) == myId) {
				isBugOwner = true;
				if (!status.equals(bug.CLOSE))
					bDisplay = false; // always in update mode
				break;
			}
		}
	}
	
	// file a new bug
	else {
		bCreateNew = true;
		title = "Submit New Change Request";
		submitter = (user) pstuser;
		
		// check user preference for default project in BugTrk
		// BugTrkNew:ProjId=12345;Cat=Workflow;Type=support;
		String [] newBugOptions = {"ProjId=", "Cat=", "Type="};
		String [] newBugValues = new String [newBugOptions.length];
		int idx1, idx2;
		userinfo ui = (userinfo) uiMgr.get(pstuser, String.valueOf(pstuser.getObjectId()));
		Object[] o = ui.getAttribute("Preference");
		for (int i = 0; i < o.length; i++) {
			s = (String) o[i];
			if (s!=null && s.startsWith("BugTrkNew")) {
				s = s.substring(s.indexOf(':') + 1).trim();
				if (s.length() > 0) {
					for (int j=0; j<newBugOptions.length; j++){
						if ((idx1 = s.indexOf(newBugOptions[j])) != -1) {
							idx1 += newBugOptions[j].length();
							if ((idx2 = s.indexOf(";", idx1)) != -1) {
								newBugValues[j] = s.substring(idx1, idx2);
							}
						}
					}
				}
				break;					// done
			}	// if BugTrkNew
		}
						

		// use session proj as default project
		if (newBugValues[0] == null)
			newBugValues[0] = (String) session.getAttribute("projId");
		if (newBugValues[0] != null) {
			projId = Integer.parseInt(newBugValues[0]);
			pj = (project) pjMgr.get(pstuser, projId);
		}
		
		// Category
		if (newBugValues[1] != null)
			category = newBugValues[1];
		
		// Type
		if (newBugValues[2] != null)
			bugClass = newBugValues[2];
	}

	// @041905ECC get submitter's manager
	boolean bAssignOwner = false;
	s = (String) submitter.getAttribute("Supervisor1")[0];
	if (s != null)
		managerId = Integer.parseInt(s);
	// isManager (Role=Manager); isProgMgr (Role=Prog Mgr)
	if (status != null) // only if it is NEW
	{
		if ((status.equals(bug.OPEN) || status.equals(bug.ACTIVE))
				&& (managerId == myId || isManager || isProgMgr
						|| isCoordinator || isSubmitter)) {
			// I am the submitter's manager or project coodinator or I am a manager: responsible to assign the bug
			bAssignOwner = true;
		} else if (status.equals(bug.ACTIVE) && isBugOwner) {
			// I am the responsible person and the bug is ACTIVE
			bAssignOwner = true;
		}
		/* don't allow this: even manager will go thru 2 steps of create and then assign (but by himself)
		 else if (bCreateNew && isManager)
		 {
		 // I am a manager filing bug, I can assign immediately
		 bAssignOwner = true;
		 }
		 */
	} else
		status = bug.OPEN; // if status is null, it is newly opened

	// bug verifier
	String verifier = null;
	if (bugObj != null) {
		verifier = (String) bugObj.getAttribute("Verifier")[0];
	}
	boolean isVerifier = verifier != null
			&& myId == Integer.parseInt(verifier);
	// update only authorized to bug owner, submitter, project coodinator and admin
	// *** changed for spansion: allow all team members to update
	String UserEditCal = "onClick='return false'";
	String UserEdit = "disabled";
	boolean isAuthorizedUser = false;

	// for non-edit, non-create case (ie. only display), don't allow any update
	if (!status.equals(bug.CLOSE)
	/*	&&
	 (bugId == null
	 || (isAdmin || myId==submitterId || pstuserIdS.equals(coordinatorIdS))
	 || (isBugOwner && !status.equals(bug.ANALYZED) && !status.equals(bug.FEEDBACK))
	 || (managerId==myId && status.equals(bug.FEEDBACK))
	 || (bAssignOwner) ) Let all team member update except closed
	 */
	) {
		if (!bDisplay) {
			UserEdit = "";
			UserEditCal = "";
		}
		isAuthorizedUser = true;
	}

	// all project team people
	if (!bDisplay && pj != null) {
		teamMember = ((user) pstuser).getTeamMembers(pj);
	}

	// parent-children CR
	boolean bHasParentChild = true;
	String parentIdS = null;
	int[] childrenIds = new int[0];
	try {
		parentIdS = bugObj.getStringAttribute("ParentID"); // can be null
		childrenIds = bugMgr
				.findId(pstuser, "ParentID='" + bugId + "'");
		if (parentIdS == null)
			parentIdS = "";
	} catch (Exception e) {
		// no ParentID defined in this database
		// OR creating a new bug
		bHasParentChild = false;
	}

	String blogLink = "../blog/blog_task.jsp?projId=" + projId
			+ "&bugId=" + bugId;

	// get category options from the Town object
	if (pj != null) {
		s = pj.getStringAttribute("Company");
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

	// @102104ECC
	/* Disable watch list for bug

	 Object [] idObjs;
	 String watch = request.getParameter("watch");
	 boolean isWatching = false;
	 int watchNum = 0;
	 if (bugId != null)
	 {
	 // do watch if not creating CR
	 if (watch == null)
	 {
	 // check to see if I am currently watching this task
	 ids = bugObj.getAttribute("Watch");
	 if (idObjs[0] != null)
	 {
	 watchNum = idObjs.length;
	 for (int i=0; i<watchNum; i++)
	 {
	 if (pstuserIdS.equals(idObjs[i]))
	 {
	 isWatching = true;
	 break;
	 }
	 }
	 }
	 }
	 else if (watch.equals("true"))
	 {
	 // I want to watch this task
	 bugObj.appendAttribute("Watch", pstuserIdS);
	 bugMgr.commit(bugObj);
	 watchNum = bugObj.getAttribute("Watch").length;
	 isWatching = true;
	 }
	 else if (watch.equals("false"))
	 {
	 // I don't want to watch this task anymore
	 bugObj.removeAttribute("Watch", pstuserIdS);
	 bugMgr.commit(bugObj);
	 idObjs = bugObj.getAttribute("Watch");
	 if (idObjs[0] != null)
	 watchNum = idObjs.length;
	 }
	 }
	 */
%>

<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8"/>
<%-- @AGQ032906 --%>
<script src="../multifile.js"></script>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>

<script language="JavaScript" src="../get-date.js"></script>

<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../forms.jsp" flush="true"/>
<script language="JavaScript">
<!--
window.onload = function()
{
	if (<%=bCreateNew%>)
		updateBug.synopsis.focus();
	else if (updateBug.comment)
		updateBug.comment.focus();
}

function validation()
{
	var synopsisElement = document.updateBug.synopsis;
	var synopsisValue = synopsisElement.value;
	if (synopsisValue == '')
	{
		fixElement(synopsisElement,
			"Please make sure that the SYNOPSIS field is properly completed.");
		return false;
	}
	for (i=0;i<synopsisValue.length;i++) {
		char = synopsisValue.charAt(i);
		if (char == '\\') {
			fixElement(synopsisElement,
				"SYNOPSIS cannot contain these characters: \n  \\");
			return false;
		}
	}

	var releaseElement = document.updateBug.release;
	var releaseValue = releaseElement.value;
	for (i=0;i<releaseValue.length;i++) {
		char = releaseValue.charAt(i);
		if (char == '\\') {
			fixElement(releaseElement,
				"SILICON RELEASE cannot contain these characters: \n  \\");
			return false;
		}
	}

	if (updateBug.projId.value == '')
	{
		fixElement(updateBug.projId,
			"Please make sure that the PROJECT NAME field is properly completed.");
		return false;
	}
	
	var fillCategory = '<%=bMustFillCategory%>';
	if (fillCategory == 'true') {
		if (updateBug.category.value == '') {
			fixElement(updateBug.type,
				"Please make sure that the CATEGORY field is properly completed.");
			return false;
		}
	}

	if (updateBug.type.value == '')
	{
		fixElement(updateBug.type,
			"Please make sure that the TYPE field is properly completed.");
		return false;
	}
	
	for (var i=0; i<updateBug.severity.length; i++) {
		if (!updateBug.severity[i].checked) continue;
		if (updateBug.severity[i].value == '<%=bug.SEV_SCRUM%>') {			
			updateBug.severity[i].value += '-' + updateBug.scrumLevel.value;
		}
	}

	if (updateBug.status.value=='<%=bug.ANALYZED%>' && updateBug.status.value=='<%=status%>')
	{
		if (!confirm("You did not check FEEDBACK / VERIFY for this CR.  Do you want to continue?"))
			return false;
	}

	if (multi_selector.count > 1)
	{
		formblock= document.getElementById('inputs');
		forminputs = formblock.getElementsByTagName('input');
		var isFileName = true;
		for (var i=0; i<forminputs.length; i++) {
			if (forminputs[i].type == 'file' && forminputs[i].value != '')
				if (isFileName)
					isFileName = affirm_addfile(forminputs[i].value);
				else
					break;
		}
		if (!isFileName)
			return isFileName;

		// @AGQ040406
		if(!findDuplicateFileName(forminputs))
			return false;
	}

	// @ECC040506
	var num = parseInt('<%=numOfOwner%>');
	for (var i=0; i<num-1; i++)
	{
		var e1 = document.getElementsByName("owner" + i)[0];
		if (!e1 || e1.value == null || e1.value == "") continue;
		for (var j=i+1; j<num; j++)
		{
			var e2 = document.getElementsByName("owner" + j)[0];
			if (e1.value == e2.value)
			{
				fixElement(e2,
					"You cannot assign the same person to different OWNER fields.");
				return false;
			}
		}
	}

	updateBug.submitButton.disabled = true;
	updateBug.submit();
}

function deletePR()
{
	var loc = "bug_update.jsp?bugId=<%=bugId%>&delete=true";
	var s = "This action is non-recoverable. Do you really want to delete the CR?";
	if (confirm(s))
		location = loc;
	else
		return false;
}

function check_UDefinePri()
{
	var eUDefPri = document.updateBug.priUDef;
	var ePri = document.updateBug.priority;
	var selectedPri = '';
	for (var i=0; i<ePri.length; i++)
		if (ePri[i].checked) {selectedPri = ePri[i].value; break;}

	if (selectedPri == '<%=bug.PRI_HIGH%>')
		eUDefPri.disabled = false;
	else
		eUDefPri.disabled = true;
}

function showBlogFile()
{
	var s = 'false';
	if (ShowBlogForm.ShowBlogFile.checked)
		s = 'true';
	location = 'bug_update.jsp?bugId=<%=bugId%>&ShowBfile=' + s;
}

//-->
</script>

<title>
	CR Management
</title>

<style type="text/css">
#bubbleDIV {position:relative;z-index:1;left:1em;top:.9em;width:3em;height:3em;vertical-align:bottom;text-align:center;}
img#bg {position:relative;z-index:-1;top:-2em;width:3em;height:3em;border:0;}
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
                	<td height="30" align="left" valign="bottom" class="head">
					<b><%=title%><br></b>
					</td>
<!-- @102104ECC -->
<%
	/*
	if (bDisplay)
	{
		out.print("<td valign='bottom' class='formtext'>");
		out.print("This bug is being watched by " + watchNum + " person(s)<br>");

		if (isWatching) {
			out.print("<img src='../i/bullet_tri.gif' width='20' height='10'>");
			out.print("<a class='listlinkbold' href='bug_update.jsp?bugId=" + bugId + "&watch=false'>");
			out.print("Remove from my watch list</a>");

		} else {
			out.print("<img src='../i/bullet_tri.gif' width='20' height='10'>");
			out.print("<a class='listlinkbold' href='bug_update.jsp?bugId=" + bugId + "&watch=true'>");
			out.print("Watch this bug on my home page</a>");
		}
	}
	*/
%>
					</td>
<!-- @102104ECC End -->

		<td width='200' align='left'>

<%
	if (bDisplay && (isAdmin || !status.equals(bug.CLOSE))) // take out isAuthorizedUser to allow all team member to update
	{
		if (bugClass != null && bugClass.equals(bug.CLASS_ISSUE))
			s = "Track this ISSUE as a CR";
		else
			s = "Update this CR";
%>
			<img src="../i/bullet_tri.gif" width="20" height="10"/>
			<a class="listlinkbold"
				href="bug_update.jsp?bugId=<%=bugId%>&edit=true&ShowBfile=<%=bShowBfile%>">
			<%=s%></a>
			<br/>
<%
	}
	if (bCanDelete) {
		out.print("<img src='../i/bullet_tri.gif' width='20' height='10'/>&nbsp;");
		out.print("<a class='listlinkbold' href='javascript:deletePR();'>");
		out.print("Remove this CR</a>");
	}
%>
					</td>
					</tr>
	            </table>
	          </td>
	        </tr>
	</table>

<table width='90%' border='0' cellspacing='0' cellpadding='0'>
			<tr>
          		<td width="100%">
<!-- Navigation Menu -->
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Tracker" />
				<jsp:param name="subCat" value="NewChange" />
				<jsp:param name="role" value="<%=iRole%>" />
				<jsp:param name="projId" value="<%=projId%>" />
			</jsp:include>
<!-- End of Navigation Menu -->
				</td>
	        </tr>
		</table>



<!-- MAIN CONTENT -->
<table width='100%'>
<tr>
    <td width="12">&nbsp;</td>
	<td class="plaintext" width='760'>
		<table border="0" width="90%">
		<tr>
		<td class="plaintext" valign="bottom">
			Please note fields marked with an * are required.</td>


<%
	// show blog number
	if (bugId != null) {
		int[] blogIdArr = null;
		blogIdArr = rMgr.findId(pstuser, "TaskID='" + bugId + "'");
		if (blogIdArr.length > 0)
			s = "../blog/blog_task.jsp?projId=" + projId + "&bugId="
					+ bugId;
		else
			s = "../blog/addblog.jsp?type=Bug&id=" + bugId
					+ "&backPage=../bug/bug_update.jsp?bugId=" + bugId;
		out.print("<td><a href='" + s + "'><div id='bubbleDIV'>");
		out.print(blogIdArr.length);
		out.print("<img id='bg' src='../i/bubble.gif' />");
		out.println("</div></a></td>");
		out.print("<td><img src='../i/spacer.gif' width='20' height='1'/></td>");
	}

	if (bDisplay) {
%>
		<form name="ShowBlogForm">
		<td colspan='2' align='left' width='80' class='plaintext'>
		<input type='checkbox' name='ShowBlogFile' onClick="javascript:showBlogFile()" <%if (bShowBfile)
					out.print("checked");%>>
			<b><font color='cc2222'>Show blog files</font></b>
		</td>
		</form>
<%
	}
%>
		</tr>
		</table>
	</td>
</tr>
<tr>
    <td width="12">&nbsp;</td>
<td>
<%-- @AGQ032906 --%>
	<form name="updateBug" action="../bug/post_updbug.jsp" method="post" enctype="multipart/form-data">
	<input type="hidden" name="edit" value="<%=editS%>">
<%
	if (bugId != null) {
%>
		<input type="hidden" name="bugId" value="<%=bugId%>" />
<%
	}
%>
<!-- start table -->
	<table width="90%" border="0" cellspacing="2" cellpadding="4" bgcolor="#FFFFFF">



<!-- CR Number -->
<%
	if (bugId != null) {
%>
		<tr bgcolor="#FFFFFF">
		<td class="td_field_bg" width="160">CR <%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,
						locale, "Number")%></td>
		<td class="td_value_bg" style="font-weight: bold; font-size: 12px; color: #DD0000">&nbsp;<%=bugId%></td>
		</tr>
<%
	}
%>

<!-- synopsis -->
		<tr bgcolor="#FFFFFF">
		<td class="td_field_bg">* <%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale,
					"Synopsis")%></td>
		<td class="td_value_bg" style="font-weight: bold; font-size: 12px;">
<%
	if (bDisplay) {
		out.print("&nbsp;" + synopsis);
	} else {
		out.print("<input class='plaintext_big' type='text' name='synopsis' size='80' value='"
				+ synopsis + "'>");
	}
%>
		</td>
		</tr>

<!-- Related CR -->
<%
	if (bHasParentChild) {
		out.print("<tr bgcolor='#FFFFFF'>");
		out.print("<td class='td_field_bg' valign='top'>"
				+ StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Related CR") + "</td>");
		out.print("<td class='td_value_bg'>");
		out.print("<table border='0' cellspacing='0' cellpadding='0'>");
		out.print("<tr>");
		out.print("<td class='formtext'>&nbsp;"
			+ StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Main CR") + ":&nbsp;<td>");
		out.print("<td class='formtext'>");
		if (bDisplay) {
			if (StringUtil.isNullOrEmptyString(parentIdS)) {
				out.print("None");
			}
			else {
				out.print("<a href='bug_update.jsp?bugId=" + parentIdS + "'>" + parentIdS + "</a>");
			}
		}
		else {
			out.print("<input class='formtext' type='text' name='mainCR' size='10' value='"
					+ parentIdS + "' />");
		}
		out.print("</td>");
		out.print("<td class='formtext' width='120' align='right'>"
				+ StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "Related CR") + ":</td>");
		out.print("<td class='formtext'>&nbsp;");
		if (childrenIds.length <= 0) out.print("None");
		else {
			StringBuffer sBuf = new StringBuffer();
			for (int i=0; i<childrenIds.length; i++) {
				if (sBuf.length() > 0) sBuf.append("; ");
				if (childrenIds[i] == thisBugId) {
					sBuf.append(thisBugId);		// it's me
				}
				else {
					sBuf.append("<a href='bug_update.jsp?bugId=" + childrenIds[i] + "'>"
							+ childrenIds[i] + "</a>");
				}
			}
			if (sBuf.length() > 0) out.print(sBuf.toString());
		}
		out.print("</td>");
		out.print("</tr>");
		out.print("</table>");
		out.print("</td></tr>");
	}
%>

<!-- initial note / description -->
<%
	String note = "";
	if (bugObj != null) {
		bTextObj = bugObj.getAttribute("Note")[0];
		note = (bTextObj==null)?"":new String((byte[])bTextObj, "utf-8");
		//note = bugObj.getRawAttributeAsString("Note");
		if (note == null)
			note = "";
		else {
			try {
				note = java.net.URLDecoder.decode(note, "UTF-8");
			} catch (Exception e) {
			}
		}

		// now in the Description, we may also embed Resolution and Solution text, separated by !@@!
		sa = note.split("!@@!");
		if (sa.length > 0)
			note = sa[0];
		else
			note = "";
		if (sa.length > 1)
			resoln = sa[1];
		if (sa.length > 2)
			soln = sa[2];
	}

	out.print("<tr bgcolor='#FFFFFF'>");
	out.print("<td class='td_field_bg' valign='top'>"
			+ StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale,
					"Description") + "</td>");
	out.print("<td class='td_value_bg' style='font-weight: bold; font-size: 12px;'>");
	out.print("<textarea name='note' class='plaintext_big' style='padding:3px;width:90%' rows='5' ");
	if (UserEdit != "")
		out.print("onKeyDown='return false;'");
	out.print(">" + note + "</textarea>");
	out.print("</td></tr>");
%>

<!-- Resolution -->
<%
	out.print("<tr bgcolor='#FFFFFF'>");
	out.print("<td class='td_field_bg' valign='top'>"
			+ StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale,
					"Resolution") + "</td>");
	out.print("<td class='td_value_bg' style='font-weight: bold; font-size: 12px;'>");
	out.print("<textarea name='resoln' class='plaintext_big' style='padding:3px;width:90%' rows='5' ");
	if (UserEdit != "")
		out.print("onKeyDown='return false;'");
	out.print(">" + resoln + "</textarea>");
	out.print("</td></tr>");
%>

<!-- project name -->
		<tr bgcolor="#FFFFFF">
		<td class="td_field_bg" width="160">* <%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale,
					"Project Name")%></td>
		<td class="td_value_bg">
<%
	if (bDisplay) {
		if (projId > 0) {
			out.print("&nbsp;<a class='listlink' href='../project/proj_plan.jsp?projName="
					+ projName + "'>");
			out.println(projName + "</a>");
		} else
			out.print("<span class='formtext'>&nbsp;Not specified</span>");
	} else {
		out.println("<select class='formtext' name='projId' "
				+ UserEdit + ">");
		out.println("<option value=''>- select project name -</option>");

		int[] projectObjId = pjMgr.getProjects(pstuser);
		if (projectObjId.length > 0) {
			PstAbstractObject[] projectObjList = pjMgr.get(pstuser,
					projectObjId);
			//@041906SSI
			Util.sortName(projectObjList, true);

			String pName;
			Date expDate;
			String expDateS = new String();
			for (int i = 0; i < projectObjList.length; i++) {
				// project
				pj = (project) projectObjList[i];
				pName = pj.getDisplayName();

				out.print("<option value='" + pj.getObjectId() + "' ");
				if (pj.getObjectId() == projId)
					out.print("selected");
				out.print(">" + pName + "</option>");
			}
		}
		out.println("</select>");
	}
%>
		</td>
		</tr>

<!-- task -->
	<tr bgcolor="#FFFFFF">
		<td class="td_field_bg" width="160"><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale,
					"Task ID")%></td>
		<td class='td_value_bg'>
<%
	if (bDisplay) {
		out.print("&nbsp;");
		if (taskId == null)
			out.print("<span class='formtext'>Not specified</span>");
		else {
			planTaskManager ptMgr = planTaskManager.getInstance();
			int[] ids1 = ptMgr.findId(pstuser, "TaskID='" + taskId
					+ "' && Status!='Deprecated'");
			if (ids1.length <= 0)
				out.print("Unrecognized task ID (" + taskId + ")");
			else {
				int ptId = ids1[ids1.length - 1];
				planTask pt = (planTask) ptMgr.get(pstuser, ptId);
				String pathName = TaskInfo.getTaskStack(pstuser, pt);
				int idx = pathName.lastIndexOf(">>");
				if (idx > 0)
					pathName = pathName.substring(0, idx + 2) + "<b>"
							+ pathName.substring(idx + 2) + "</b>";
				else
					pathName = "<b>" + pathName + "</b>";
				out.print("<a class='listlink' href='../project/task_update.jsp?projId="
						+ projId
						+ "&pTaskId="
						+ ptId
						+ "'>"
						+ pathName
						+ "</a>");
				out.print("&nbsp;(" + taskId + ")");
			}
		}
	} else {
		if (taskId == null)
			taskId = "";
		out.print("<input class='formtext' type='text' name='taskId' size='20' value='"
				+ taskId + "'>");
	}
%>
		</td>
	</tr>

<%	if (!isSAS) { %>
<!-- category -->
		<tr bgcolor="#FFFFFF">
		<td class="td_field_bg">* <%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale,
					"Category")%></td>
		<td class="td_value_bg">
<%
	if (bDisplay) {
		if (category != null)
			out.print("&nbsp;" + category);
		else
			out.print("<span class='formtext'>&nbsp;Not specified</span>");
	} else {
		out.println("<select class='formtext' name='category'  "
				+ UserEdit + ">");
		out.print("<option value=''>- select category -</option>");

		for (int i = 0; i < CATEGORY.length; i++) {
			out.print("<option value='" + CATEGORY[i] + "'");

			if (CATEGORY[i].equals(category))
				out.print(" selected");
			out.println(">" + CATEGORY[i] + "</option>");
		}
		out.println("</select>");
	}
%>
		</td>
		</tr>


<!-- Process Type -->
<%
	if (bHasProcessType) {
		out.print("<tr bgcolor=''#FFFFFF'>");
		out.print("<td class='td_field_bg'>"
				+ StringUtil.getLocalString(StringUtil.TYPE_LABEL,
						locale, "Process Type") + "</td>");
		out.print("<td class='td_value_bg'>");
		if (bDisplay) {
			if (processType != null)
				out.print("&nbsp;" + processType);
			else
				out.print("<span class='formtext'>&nbsp;Not specified</span>");
		} else {
			out.println("<select class='formtext' name='processType'  "
					+ UserEdit + ">");
			out.print("<option value=''>- select process type -</option>");

			for (int i = 0; i < PROCESS_TYPE.length; i++) {
				out.print("<option value='" + PROCESS_TYPE[i] + "'");

				if (PROCESS_TYPE[i].equals(processType))
					out.print(" selected");
				out.println(">" + PROCESS_TYPE[i] + "</option>");
			}
			out.println("</select>");
		}

		out.print("</td>");
		out.print("</tr>");
	} // END if bHasProcessType
%>

<!-- User Department -->
<%
	if (bHasUserDepartment) {
		out.print("<tr bgcolor=''#FFFFFF'>");
		out.print("<td class='td_field_bg'>"
				+ StringUtil.getLocalString(StringUtil.TYPE_LABEL,
						locale, "User Department") + "</td>");
		out.print("<td class='td_value_bg'>");
		if (bDisplay) {
			if (userDepartment != null)
				out.print("&nbsp;" + userDepartment);
			else
				out.print("<span class='formtext'>&nbsp;Not specified</span>");
		} else {
			out.println("<select class='formtext' name='userDept'  "
					+ UserEdit + ">");
			out.print("<option value=''>- select user department -</option>");

			for (int i = 0; i < USER_DEPT.length; i++) {
				out.print("<option value='");
				if (!USER_DEPT[i].startsWith("---"))
					out.print(USER_DEPT[i]);
				out.print("'");

				if (USER_DEPT[i].equals(userDepartment))
					out.print(" selected");
				out.println(">" + USER_DEPT[i] + "</option>");
			}
			out.println("</select>");
		}

		out.print("</td>");
		out.print("</tr>");
	} // END if bHasUserDepartment
}	// END if !isSAS
%>

<!-- bug type -->
	<tr bgcolor="#FFFFFF">
		<td class="td_field_bg" width="160" valign='top'>* <%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale,
					"Type")%></td>
		<td class="td_value_bg">
<%
	String[] classValAry;
	if (isSAS)
		classValAry = SAS_BUG_TYPE;
	else
		classValAry = IT_BUG_TYPE;
	//bug.CLASS_ARRAY;

	int num = 0;
	out.print("<select class='formtext' name='type' " + UserEdit + ">");
	out.print("<option value=''>- select type -</option>");
	for (int i = 0; i < classValAry.length; i++) {
		if (i == 0 && UserEdit.length() <= 0)
			continue; // do not allow update a CR back to issue
		out.print("<option value='" + classValAry[i] + "'");
		if (bugClass != null && bugClass.equals(classValAry[i]))
			out.print(" selected");
		out.println(">" + classValAry[i] + "</option>");
	}
%>
		</td>
	</tr>
	

<!-- priority -->
	<tr bgcolor="#FFFFFF">
		<td class="td_field_bg" width="160">* <%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale,
					"Priority")%></td>
		<td class="td_value_bg">
			<table>
<%
	// @ECC041406 support multiple user-defined priority option
	int numUDefPri = 0;
	String setUDefinePri = "";
	s = Util.getPropKey("pst", "BUG_MAX_DEFINE_PRI");
	if (s != null) {
		try {
			numUDefPri = Integer.parseInt(s.trim());
		} catch (Exception e) {/* invalid properties value */
		}
		if (numUDefPri > 0)
			setUDefinePri = " onClick='check_UDefinePri();' ";
	}
	String[] priorityValAry = bug.PRI_ARRAY;
	num = 0;
	for (int i = 0; i < priorityValAry.length; i++) {
		if (num % RADIO_NUM == 0)
			out.print("<tr>");
		if (priorityValAry[i].equals(bug.PRI_HIGH))
			s = "50";
		else
			s = "100";
		out.print("<td width='"
				+ s
				+ "' class='formtext'><input class='formtext' type='radio' name='priority' value='"
				+ priorityValAry[i] + "'" + setUDefinePri);
		if (bugPriority != null
				&& bugPriority.startsWith(priorityValAry[i]))
			out.print(" checked>" + priorityValAry[i] + "</td>");
		else
			out.println(" " + UserEdit + ">" + priorityValAry[i]
					+ "</td>");
		//if (num%RADIO_NUM == RADIO_NUM-1) out.print("</tr>");
		num++;
	}

	// @ECC041406 support multiple user-defined priority option
	int priNum = 0;
	if (bugPriority != null && bugPriority.startsWith(bug.PRI_HIGH)
			&& bugPriority.length() > bug.PRI_HIGH.length())
		priNum = Integer.parseInt(bugPriority.substring(bug.PRI_HIGH
				.length()));

	if (UserEdit == "") {
		if (numUDefPri > 0) {
			// allow choosing a digit to be appended to priority (High only)
			out.print("<td><select name='priUDef' class='formtext' "
					+ UserEdit + ">");
			out.print("<option value='0'>" + P[0] + "</option>");
			for (int i = 1; i <= numUDefPri; i++) {
				out.print("<option value='" + i + "' ");
				if (priNum == i)
					out.print("selected");
				out.print(">" + P[i] + "</option>");
			}
			out.print("</select></td>");
		}
	} else if (bugPriority.startsWith(bug.PRI_HIGH)) {
		// just display for read
		out.print("<td class='formtext' valign='bottom'>" + P[priNum]
				+ "</td>");
	}

	out.print("</tr>");
%>
			</table>
<script language="JavaScript">
<!--
	if ( ('<%=UserEdit%>' == "") && (parseInt('<%=numUDefPri%>') > 0) ) check_UDefinePri();
//-->
</script>
		</td>
	</tr>

<!-- severity -->
	<tr bgcolor="#FFFFFF">
		<td class="td_field_bg" width="160">* <%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale,
					"Severity")%></td>
		<td class="td_value_bg">
			<table>
<%
	ArrayList<String> sevArList = new ArrayList<String>(
			bug.SEV_ARRAY.length + 1);
	sevArList.addAll(Arrays.asList(bug.SEV_ARRAY));
	if (isEnableScrum)
		sevArList.add(bug.SEV_SCRUM);
	String[] severityValAry = sevArList.toArray(new String[0]);

	num = 0;
	for (int i = 0; i < severityValAry.length; i++) {
		if (num % RADIO_NUM == 0)
			out.print("<tr>");
		out.print("<td width='100' class='formtext'><input class='formtext' type='radio' name='severity' value='"
				+ severityValAry[i] + "'");
		if (bugSeverity != null
				&& bugSeverity.startsWith(severityValAry[i]))
			out.print(" checked>" + severityValAry[i]);
		else
			out.println(" " + UserEdit + ">" + severityValAry[i]);
		if (severityValAry[i].startsWith(bug.SEV_SCRUM)) {
			int scrumLevel = 0;
			if (bugSeverity.startsWith(bug.SEV_SCRUM)) {
				int idx = bugSeverity.indexOf('-');
				if (idx != -1) {
					s = bugSeverity.substring(idx + 1);
					scrumLevel = Integer.parseInt(s);
				}
			}
			if (UserEdit == "") {
				out.print("-");
				out.print("<td><select class='formtext' name='scrumLevel' "
						+ UserEdit + ">");
				for (int j = MAX_SCRUM_NUM; j > 0; j--) {
					out.print("<option value='" + j + "'");
					if (scrumLevel == j)
						out.print(" selected");
					out.print(">" + j + "</option>");
				}
				out.print("</select></td>");
			} else {
				if (scrumLevel > 0) {
					out.print("-" + scrumLevel);
				}
			}
		}
		out.print("</td>");
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

<!-- status -->
		<tr bgcolor="#FFFFFF">
		<td class="td_field_bg">* <%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale,
					"Status")%></td>
		<td class="td_value_bg">
			<table>
<%
	// 0=open 1=active 2=analyzed 3=feedback 4=close
	String[] StateValAry = bug.STATE_ARRAY;

	int current = -1;
	num = 0;
	for (int i = 0; i < StateValAry.length; i++) {
		s = "disabled";
		if (num % RADIO_NUM == 0)
			out.print("<tr>");
		out.print("<td width='100' class='formtext'><input class='formtext' type='radio' name='status' value='"
				+ StateValAry[i] + "'");
		if (status != null && status.equals(StateValAry[i])) {
			current = i;
			out.print(" checked>" + StateValAry[i] + "</td>");
		} else {
			if (!bDisplay && isAuthorizedUser) {
				if (status.equals(bug.ACTIVE)
						&& (isBugOwner || coordinatorId == myId)
						&& (i == 2))
					s = ""; // I am the owner: ok to move from ACTIVE to ANALYZED
				else if (status.equals(bug.ANALYZED)
						&& (isVerifier || isSubmitter || isCoordinator)
						&& (i == 1 || i == 3))
					s = ""; // I am the submitter: ok to move ANALYZED to either ACTIVE or FEEDBACK
				else if (status.equals(bug.FEEDBACK)
						&& (isVerifier || myId == managerId
								|| isManager || isCoordinator/*managerId==0*/)
						&& (i == 4))
					s = ""; // I am submitter's manager or a manager or project coordinator: ok to move FEEDBACK to CLOSE
			}
			out.println(" " + s + ">" + StateValAry[i] + "</td>");
		}
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


<!-- reason -->
		<tr bgcolor="#FFFFFF">
		<td class="td_field_bg" width="160"><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale,
					"Reason")%></td>
		<td class="td_value_bg">
<%
	String reasonUserEdit = "";
	if (status.equals(bug.OPEN) || status.equals(bug.CLOSE))
		reasonUserEdit = "disabled";
	if (reasonUserEdit.equals("")) {
		reasonUserEdit = UserEdit;
	}

	out.print("<select class='formtext' name='reason' "
			+ reasonUserEdit + ">");
	out.print("<option value=''>- select a reason -</option>");
	for (int i = 0; i < bug.REA_ARRAY.length; i++) {
		out.print("<option value='" + bug.REA_ARRAY[i] + "' ");
		if (bugReason.equals(bug.REA_ARRAY[i])) {
			out.print("selected");
		}
		out.print(">" + bug.REA_ARRAY[i] + "</option>");
	}
	out.print("</select>");
%>
		</td>
		</tr>


<!-- submitter -->
		<tr bgcolor="#FFFFFF">
		<td class="td_field_bg" width="160"><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale,
					"Submitter")%></td>
		<td class="td_value_bg">
<%
	String uName = submitter.getFullName();
	String outsideEmail = null;
	if (uName.equalsIgnoreCase("Ticket System")) {
		outsideEmail = bugObj.getStringAttribute("Email2");
	}
	out.print("&nbsp;<a class='listlink' href='../ep/ep1.jsp?uid="
			+ submitter.getObjectId() + "'>");
	out.print(uName + "</a>");
	if (outsideEmail != null) out.print("&nbsp;(" + outsideEmail + ")");
%>
		</td>
		</tr>


<!-- owner -->
		<tr bgcolor='#FFFFFF'>
		<td class='td_field_bg' width='160'><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale,
					"Owner")%></td>
		<td class='td_value_bg'><table border='0' cellspacing='0' cellpadding='0'><tr>
<%
	int oi = 0;
	sa = new String[0];
	if (numOfOwner > 1) {
		// need to insert label of multiple owner
		s = Util.getPropKey("pst", "BUG_OWNER_LABEL");
		if (s != null)
			sa = s.split(";");
	}
	s = null;

	for (int i = 0; i < numOfOwner; i++) {
		out.print("<td class='td_value_bg' width='200'>");
		if (sa.length > i)
			out.print("&nbsp;" + sa[i].trim() + ":"); // label
		if (bugObj != null)
			s = (String) bugObj.getAttribute(ownerAttr[i])[0];

		if (bDisplay || !bAssignOwner) {
			if (s != null) {
				u = (user) uMgr.get(pstuser, Integer.parseInt(s));
				uName = u.getFullName();
				out.print("&nbsp;<a class='listlink' href='../ep/ep1.jsp?uid="
						+ u.getObjectId() + "'>");
				out.print(uName + "</a>");
			} else {
				out.print("<span class='formtext'>&nbsp;"
				+ StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "To be assigned")
				+ "</span>");
			}
		} else {
			String fullName;
			out.print("<select class='formtext' name='owner" + i + "' "
					+ UserEdit + ">");
			out.print("<option value=''>- select owner -</option>");
			if (teamMember != null) {
				if (s != null)
					oi = Integer.parseInt(s);
				for (int a = 0; a < teamMember.length; a++) {
					fullName = ((user) teamMember[a]).getFullName();
					out.print("<option value='"
							+ teamMember[a].getObjectId() + "'");

					if (s != null
							&& (oi == teamMember[a].getObjectId()))
						out.print(" selected");
					out.println(">" + fullName + "</option>");
				}
			}
			out.println("</select>");
		}
		out.print("</td>");
	}
%>
		</tr></table>
		</td>
		</tr>


<!-- verifier -->
		<tr bgcolor='#FFFFFF'>
		<td class='td_field_bg' width='160'><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale,
					"Verifier")%></td>
		<td class='td_value_bg'>
<%
	if (status.equals(bug.OPEN) && !bAssignOwner) {
		out.print("<span class='formtext'>&nbsp;"
			+ StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, "To be assigned")
			+ "</span>");
	} else if (bDisplay || status.equals(bug.CLOSE)) {
		if (verifier != null) {
			u = (user) uMgr.get(pstuser, Integer.parseInt(verifier));
			uName = u.getFullName();
			out.print("&nbsp;<a class='listlink' href='../ep/ep1.jsp?uid="
					+ u.getObjectId() + "'>");
			out.print(uName + "</a>");
		} else
			out.print("<span class='formtext'>&nbsp;Not assigned</span>");
	} else {
		out.print("<select class='formtext' name='verifier' "
				+ UserEdit + ">");
		out.print("<option value=''>- select verifier -</option>");
		if (teamMember != null) {
			String fullName;
			if (verifier != null)
				oi = Integer.parseInt(verifier);
			for (int a = 0; a < teamMember.length; a++) {
				fullName = ((user) teamMember[a]).getFullName();
				out.print("<option value='"
						+ teamMember[a].getObjectId() + "'");

				if (verifier != null
						&& (oi == teamMember[a].getObjectId()))
					out.print(" selected");
				out.println(">" + fullName + "</option>");
			}
		}
		out.print("</select>");
	}
%>
		</td>
		</tr>


<!-- release -->
		<tr bgcolor="#FFFFFF">
		<td class="td_field_bg"><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale,
					"Fix in Revision/Due")%></td>
		<td class="td_value_bg">
<%
	if (bDisplay) {
		if (release != null)
			out.print("&nbsp;" + release);
		else
			out.print("<span class='formtext'>&nbsp;Not specified</span>");
	} else {
%>
		<input class='formtext' type='text' name='release' size='80' value='<%=release%>'>
<%
	}
%>
		</td>
		</tr>

<!-- Solution -->
<%
	out.print("<tr bgcolor='#FFFFFF'>");
	out.print("<td class='td_field_bg' valign='top'>"
			+ StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale,
					"Solution") + "</td>");
	out.print("<td class='td_value_bg' style='font-weight: bold; font-size: 12px;'>");
	out.print("<textarea name='soln' class='plaintext_big' style='padding:3px;width:90%' rows='5' ");
	if (UserEdit != "")
		out.print("onKeyDown='return false;'");
	out.print(">" + soln + "</textarea>");
	out.print("</td></tr>");
%>

<!-- New file attachment -->
<%
	if (!bDisplay) {
%>
<tr bgcolor="#FFFFFF">
	<td class="td_field_bg" width="160"><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,
						locale, "Add Attachment")%></td>
	<td class="td_value_bg">
<%-- @AGQ032806 --%>
		<div id="inputs"><input id="my_file_element" <%=UserEdit%> type="file" class="formtext" size="50" /></div>
		<span class='formtext'><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,
						locale, "Files to be uploaded")%>:<br /></span>
		<table><tbody id="files_list"></tbody></table>
		<script>
			var multi_selector = new MultiSelector( document.getElementById( 'files_list' ), 0, document.getElementById( 'my_file_element' ).className , document.getElementById( 'my_file_element' ).size );
			multi_selector.addElement( document.getElementById( 'my_file_element' ) );
		</script>
		<br />
		<!-- input class="formtext" <%=UserEdit%> type="file" name="Attachment" size="50" -->
	</td>
</tr>
<%
	}
%>

<!-- list file attachments -->
<%
	if (bugId != null) {
%>

<tr bgcolor="#FFFFFF">
	<td class="td_field_bg" width="160"><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,
						locale, "Attachments")%></td>
	<td class="td_value_bg">
		<table border="0" cellspacing="0" cellpadding="0">
<%
	// @SWS061406 begins
		Object[] attmtList = bugObj.getAttribute("AttachmentID");
		attachment attmtObj;
		String fileName, uname;
		Date attmtCreateDt;
		int[] ids = null;

		if (bShowBfile) {
			ids = rMgr.findId(pstuser, "TaskID='" + bugId + "'");
		}

		// display header for attachments
		if (attmtList[0] != null || (ids != null && ids.length > 0)) {
%>
	<tr>
	<td colspan='2' width="280" bgcolor="#6699cc" class="td_header"><strong>&nbsp;<%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,
							locale, "File Name")%></strong></td>
	<td class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="80" bgcolor="#6699cc" class="td_header"><strong><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,
							locale, "Owner")%></strong></td>
	<td class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="120" bgcolor="#6699cc" class="td_header" align="left"><strong><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,
							locale, "Posted On")%></strong></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	</tr>
<%
	}

		if (attmtList[0] == null) {
			out.println("<tr><td class='formtext'>&nbsp;"
					+ StringUtil.getLocalString(StringUtil.TYPE_LABEL,
							locale, "Posted On") + "None</td></tr>");
		} else {
			Arrays.sort(attmtList);
			for (int i = 0; i < attmtList.length; i++) {
				// list files by alphabetical order
				attmtObj = (attachment) aMgr.get(pstuser,
						(String) attmtList[i]);
				uname = attmtObj.getOwnerDisplayName(pstuser);
				attmtCreateDt = (Date) attmtObj
						.getAttribute("CreatedDate")[0];
				fileName = attmtObj.getFileName();
%>
			<tr>
			<td colspan='2' class="plaintext" width="280">
				<a class="listlink" href="<%=host%>/servlet/ShowFile?attId=<%=attmtObj.getObjectId()%>"><%=fileName%></a>
			</td>
			<td colspan='2'>&nbsp;</td>
			<td class="formtext" valign='top'><a href="../ep/ep1.jsp?uid=<%=(String) attmtObj.getAttribute("Owner")[0]%>" class="listlink"><%=uname%></a></td>
			<td colspan='2'>&nbsp;</td>
			<td class="formtext" valign='top'><%=df.format(attmtCreateDt)%></td>
			<td>&nbsp;</td>
<%
	if (isAuthorizedUser && !bDisplay) {
%>
				<td><input class="formtext" type="button" value="Delete"
					onclick="return affirm_delfile('../project/post_delfile.jsp?bugId=<%=bugId%>&fname=<%=fileName%>');" align="right"></td>
<%
	}
%>
			</tr>
<%
	} // END: for
		} // END: else
		if (bShowBfile) {
			out.print("<tr><td><img src='../i/spacer.gif' height='5' border='0'></td></tr>");
			out.print("<tr>");
			out.print("<td colspan='2' class='blog_line'><b>BLOG FILE</b></td></tr>");
			out.print("<tr><td colspan='2'><img src='../i/mid/wkln.gif' height='2' width='100' border='0'></td></tr>");
			out.print("<tr><td><img src='../i/spacer.gif' height='5' border='0'></td></tr>");

			// list the blog files now
			// first get all the blogs belonging to this bug
			Object[] attIds;
			for (int i = 0; i < ids.length; i++) {
				PstAbstractObject o = rMgr.get(pstuser, ids[i]);
				attIds = o.getAttribute("AttachmentID");
				if (attIds.length <= 0 || attIds[0] == null)
					continue;

				for (int j = 0; j < attIds.length; j++) {
					// list all the attachments from this one blog
					attmtObj = (attachment) aMgr.get(pstuser,
							(String) attIds[j]);
					uname = attmtObj.getOwnerDisplayName(pstuser);
					attmtCreateDt = (Date) attmtObj
							.getAttribute("CreatedDate")[0];
					fileName = attmtObj.getFileName();
%>
				<tr>
				<td colspan='2' class="plaintext" width="280">
					<a class="listlink" href="<%=host%>/servlet/ShowFile?attId=<%=attmtObj.getObjectId()%>"><%=fileName%></a>
				</td>
				<td colspan='2'>&nbsp;</td>
				<td class="formtext" valign='top'><a href="../ep/ep1.jsp?uid=<%=(String) attmtObj.getAttribute("Owner")[0]%>" class="listlink"><%=uname%></a></td>
				<td colspan='2'>&nbsp;</td>
				<td class="formtext" valign='top'><%=df.format(attmtCreateDt)%></td>
				<td>&nbsp;</td>
				</tr>
<%
	} // End: for each attachment in this blog
			} // End: for each blog
		} // End: if bShowFile
		// @SWS061406 ends
%>
		</table>
	</td>
</tr>

<%
	}
%>
<!-- End list existing file attachments -->

<!-- Comments -->
<%
	if (UserEdit == "") {
%>
<tr bgcolor="#FFFFFF">
	<td class="td_field_bg" valign='top'><%=StringUtil.getLocalString(StringUtil.TYPE_LABEL,
						locale, "Comments")%></td>
	<td class="td_value_bg">
		<textarea name='comment' class='plaintext_big' style='padding:3px; width:90%' rows='5'></textarea>
	</td>
</tr>
<%
	}
%>

<!-- history -->
<%
	if (!bCreateNew) {
		out.print("<tr bgcolor='#FFFFFF'>");
		out.print("<td class='td_field_bg' valign='top'>"
				+ StringUtil.getLocalString(StringUtil.TYPE_LABEL,
						locale, "Activity History") + "</td>");
		out.print("<td><table><tr><td class='plaintext_big'>" + bText
				+ "</td></tr></table></td>");
		out.print("</tr>");
	}
%>


</table>
<!-- end table -->

		<p align="center">
<%
	String cancelLink;
	if (editS != null)
		cancelLink = "location=\"bug_search.jsp\""; // cancel will put it to view
	else
		cancelLink = "location=\"bug_search.jsp\""; //"history.back(-1);";

	if (!bDisplay && (isAdmin || !UserEdit.equals("disabled"))) {
%>
		<input type='button' class='button_medium' name='submitButton' value='Submit' onclick='return validation();'>
		<input type='button' class='button_medium' value='Cancel' onclick='<%=cancelLink%>'>
<%
	} else {
%>
		<input type='button' class='button_medium' value='Update'
			onclick="location='bug_update.jsp?bugId=<%=bugId%>&edit=true&ShowBfile=<%=bShowBfile%>#top';">
		<input type='button' class='button_medium' value='Cancel' onclick='<%=cancelLink%>'>
<%
	}
%>
		<br></p>


	</td>
</tr>
</table>
<%--  @AGQ032906 --%>
</form>
<!-- END MAIN CONTENT -->
</td>
</tr>


<tr><td>&nbsp;</td></tr>


<!-- BEGIN FOOTER TABLE -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>
