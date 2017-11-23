<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2005, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: ep_home.jsp (for PRM and CR and CR-OMF)
//	Author: ECC
//	Date:	07/05/05
//	Description: PRM home page.
//	Modification:
//		@081403ECC	Add PRM and SBM configurable option
//		@102104ECC	Added watcher feature.
//		@110705ECC	Add option to link a Phase or Sub-phase to Task.
//		@041906SWS	Added sort function to Project names.
//		@AGQ051806	Changed from reading project's phase to phase object
//		@SWS082106  Added new look for OMF: list of meetings only.
//		@ECC050307	Option to show or hide closed projects
//		@ECC081407	Support Blog Module.
//		@ECC081108	Added Account Manager role.
//		@ECC082008	Add remote backup function for CR.
//		@ECC091708	Show shared files for CR.
//		@ECC032509	Allow sharing folder.
//
/////////////////////////////////////////////////////////////////////
//

%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.omm.common.*" %>
<%@ page import = "oct.omm.client.*" %>
<%@ page import = "oct.omm.db.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>
<%@ page import = "org.apache.log4j.Logger" %>

<%
	String noSession = "../index.jsp";	//"../out.jsp?go=ep/ep_prm.jsp";
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%!
	/**
	 *  take a string and transform with CPM keywords
	 *  For now I just hard coded some keywords, future should support storing these keywords in OMM.
	 */
	String transform(PstUserAbstractObject uObj, String str)
	{
		String retStr = "";
		
		if (!StringUtil.isNullOrEmptyString(str)) {
			retStr = str.replaceAll("\\$username\\$", uObj.getObjectName());
		}
		return retStr;
	}
%>

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	String HOST = Prm.getPrmHost();
	String UPLOAD_PATH = Prm.getUploadPath();
	String VIEWONLY = "VIEWONLY";
	final String SIZE_TERM		= "?#";			// must be the same as UploadFile.java
	final String LIGHT			= Prm.LIGHT;
	final String DARK			= Prm.DARK;
	final String HEAD_LINE =
		"<tr><td><table border='0' cellspacing='0' cellpadding='0'>"
		+ "<tr><td><img src='../i/spacer.gif' width='26' height='1' /></td><td bgcolor='#ee0000'><img src='../i/spacer.gif' height='1' width='30' /></td><td width='100'></td></tr>"
		+ "<tr><td></td><td colspan='2' width='150' bgcolor='#ee0000'><img src='../i/spacer.gif' width='100' height='1' /></td></tr>"
		+ "</table></td></tr>";


	PstUserAbstractObject me = pstuser;
	if (me instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?go=ep/ep_prm.jsp?e=time out");
		return;
	}
	Logger l = PrmLog.getLog();
	
	projectManager pjMgr = projectManager.getInstance();
	taskManager tkMgr = null;
	planTaskManager ptMgr = null;
	userManager uMgr = userManager.getInstance();
	townManager tnMgr = townManager.getInstance();
	resultManager rMgr = resultManager.getInstance();
	attachmentManager attMgr = attachmentManager.getInstance();
	applicationManager appMgr = applicationManager.getInstance();
	
	int myUid = me.getObjectId();
	String myUidS = String.valueOf(myUid);

	// @ECC042309 get short profile
	String FirstName = (String)me.getAttribute("FirstName")[0];
	String LastName  = (String)me.getAttribute("LastName")[0];
	if (FirstName==null || LastName==null || FirstName.length()<=0 || LastName.length()<=0)
	{
		response.sendRedirect("profiling.jsp");
		return;
	}
	String s;

	s = request.getParameter("full");
	boolean isPDA = Prm.isPDA(request);
	if (s==null && isPDA) {
		response.sendRedirect("ep_prm_pda.jsp");
		return;
	}

	String backPage = "../ep/ep_prm.jsp";
	Date lastLogin = (Date)session.getAttribute("lastLogin");
	PstAbstractObject obj;
	Date dt, complete;

	int iRole = ((Integer)session.getAttribute("role")).intValue();
	boolean isAdmin = ((iRole & user.iROLE_ADMIN) > 0);
	boolean isDirector = ((iRole & user.iROLE_DIRECTOR) > 0);
	boolean isProjAdd = ((iRole & user.iROLE_ADD_PROJ) > 0);
	boolean isProgMgr = ((iRole & user.iROLE_PROGMGR) > 0);			// @ECC062806
	boolean isAcctMgr = ((iRole & user.iROLE_ACCTMGR) > 0);			// @ECC081108
	
	// now program manager is also the person who owns his town/company
	if (!isAdmin) {
		String myTownID = me.getStringAttribute("TownID");
		if (myTownID == null) {
			myTownID = me.getStringAttribute("Company");	// should be the same
			// fix this TownID with Company
			if (myTownID != null) {
				me.setAttribute("TownID", myTownID);
				uMgr.commit(me);
			}
		}
		if (myTownID != null) {
			town myTownObj = (town) tnMgr.get(me, Integer.parseInt(myTownID));
			s = myTownObj.getStringAttribute("Chief");
			if (s!=null && s.equals(myUidS)) {
				iRole |= user.iROLE_PROGMGR;
				isProgMgr = true;
			}
		}
	}

	// to check if session is CR, OMF, or PRM
	boolean isCRAPP = Prm.isCR();
	boolean isOMFAPP = Prm.isOMF();
	boolean isPRMAPP = Prm.isPRM();
	boolean isCwModule = Prm.isCwModule(session);

	// @ECC081407 Blog Module
	boolean isBlogModule = false;
	s = Util.getPropKey("pst", "MODULE");
	if (s!=null && s.equalsIgnoreCase("Blog"))
		isBlogModule = true;

	// @ECC080108 Multiple company
	boolean isMultiCorp = false;
	s = Util.getPropKey("pst", "MULTICORPORATE");
	if (s!=null && s.equalsIgnoreCase("true"))
		isMultiCorp = true;

	String label1;
	if (isCRAPP)
		label1 = "Workspace";
	else
		label1 = "My Projects";

	String uid = request.getParameter("uid");
	int uidInt = 0;

	if ((uid == null) || (uid.equals("null")))
	{
		uidInt = myUid;
		uid = myUidS;
	}
	else
	{
		uidInt = Integer.parseInt(request.getParameter("uid"));
	}

	me = (user)uMgr.get(me, uidInt);			// get it from the database
	String sortby = (String) request.getParameter("sortby");

	String Title = (String)me.getAttribute("Title")[0];
	String fName = (String)me.getAttribute("FirstName")[0];

	// userinfo
	userinfo myUi = (userinfo)userinfoManager.getInstance().get(me, uid);


	Date now = Calendar.getInstance().getTime();
	//SimpleDateFormat df1 = new SimpleDateFormat ("yyyy.MM.dd");
	SimpleDateFormat df0 = new SimpleDateFormat ("MM/dd/yy");
	SimpleDateFormat df1 = new SimpleDateFormat ("yyyy.MM.dd.hh.mm");
	SimpleDateFormat df2 = new SimpleDateFormat ("MMM dd, yyyy h:mm a");
	SimpleDateFormat df3 = new SimpleDateFormat ("MM/dd/yy h:mm a");
	SimpleDateFormat df4 = new SimpleDateFormat ("MM dd yyyy hh mm");

	// Workflow related pending list and status list

	// @102104ECC
	boolean bFound = false;
	task tk = null;
	if (!isOMFAPP || isCRAPP)
	{
		ptMgr = planTaskManager.getInstance();
		tkMgr = taskManager.getInstance();
		for (Enumeration e = request.getParameterNames() ; e.hasMoreElements() ;)
		{
			String temp = (String)e.nextElement();
			if (temp.startsWith("delete_"))
			{
				String tkId = temp.substring(7);
				tk = (task)tkMgr.get(me, Integer.parseInt(tkId));

				tk.removeAttribute("Watch", uid);
				bFound = true;
			}
		}
		if (bFound) tkMgr.commit(tk);
	}

	boolean isAutoUserApproval = false;
	s = Util.getPropKey("pst", "NEW_USER_AUTO_APPROVAL");
	if (s != null && s.equals("true"))
		isAutoUserApproval = true;

	// Option to show differt project types
	// timeTrack, container, close
	String showPjType = request.getParameter("showPjType");
		
	if (StringUtil.isNullOrEmptyString(showPjType)) {
		showPjType = (String)session.getAttribute("showPjType");
		if (showPjType == null) {
			showPjType = Util.getPropKey("pst", "DEFAULT_PROJ_TYPE");
			if (showPjType == null) {
				showPjType = project.TYPE_CONTAINER;		// default
			}
		}
	}
	session.setAttribute("showPjType", showPjType);
	boolean bShowClosedPj = showPjType.equals(project.TYPE_ALL);

	int [] myPjIds = pjMgr.getProjects(me, bShowClosedPj);
	
	// if the user only have one project, it might just be a new user with personal project space
	// make sure it is showing all project if that is the case
	// This ensure at least one project is being shown
	if (myPjIds.length == 1) {
		if (request.getParameter("showPjType") == null) {
			response.sendRedirect("ep_prm.jsp?showPjType=" + project.TYPE_ALL);
			return;
		}
	}

	// Option to show/hide shared files
	boolean bShowShared = true;
	s = request.getParameter("showShare");
	if (s != null)
	{
		session.setAttribute("showShare", s);
	}
	else
		s = (String)session.getAttribute("showShare");
	if (s!=null && s.equals("false"))
		bShowShared = false;

	boolean bUseEmailUserName = false;
	s = Util.getPropKey("pst", "USERNAME_EMAIL");
	if (s!=null && s.equalsIgnoreCase("true"))
		bUseEmailUserName = true;
	
	int roleType = 0;		// default sub-menu
	if (isAdmin)
		roleType = 1;		// new user, new project, new company
	else if (isProgMgr || isProjAdd || isAcctMgr)
		roleType = 2;		// new user, new project
		
	// manual option to create personal project space
	s = request.getParameter("pps");
	if (s!=null && s.equals("1")) {
		if (isMultiCorp) {
			project.createPersonalProject(pstuser);
			l.info("Created personal project space for existing user [" + pstuser.getObjectName() + "]");
		}
		response.sendRedirect("ep_prm.jsp");
		return;
	}
	
	// check to see if there is any CPM applications on this domain that are
	// applicable (seen) by this user
	int [] ids = appMgr.findId(me, "om_acctname='%'");		// get all app
	ArrayList <Object> appList = new ArrayList <Object> ();
	application app;
	for (int i=0; i<ids.length; i++) {
		app = (application) appMgr.get(me, ids[i]);
		if (app.isMyApp(me))
			appList.add(app);
	}
	boolean bHasApplication = appList.size()>0;
	if (bHasApplication) {
		Object [] arr = appList.toArray();
		Util.sortName(arr);
		appList = new ArrayList(Arrays.asList(arr));
	}
%>


<head>
<title><%=Prm.getAppTitle()%> Home</title>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
<script language="JavaScript" src="../get-date.js"></script>
<script language="JavaScript" src="../date.js"></script>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<link href="../omf.css" rel="stylesheet" type="text/css" media="screen"/>

<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../file_action.jsp" flush="true"/>
<jsp:include page="../errormsg.jsp" flush="true"/>

<%
	response.setHeader("Pragma", "No-Cache");
	response.setDateHeader("Expires", 0);
	response.setHeader("Cache-Control", "no-Cache");
%>

<script type="text/javascript">
<!--
var bUsernameEmail = <%=bUseEmailUserName%>;	// for file_action.jsp

window.onload = function()
{
	// show or hide the application section
	var e = document.getElementById("appSection");
	if (<%=bHasApplication%>) {
		e.style.display = 'block';
	}
	else {
		e.style.display = 'none';
	}
}


// @ECC050307
function showProjectType()
{
	var type;
	var radioObj = document.getElementsByName("ShowProjType");
	if (!radioObj) return;
	var len = radioObj.length;
	for (var i=0; i<len; i++) {
		if (radioObj[i].checked) {
			type = radioObj[i].value;
			break;
		}
	}
	location = 'ep_prm.jsp?showPjType=' + type;
}

function toggleAllShare(ch)
{
	var e = document.getElementById("ShowAllSh");
	if (ch != null)
		e.checked = ch;
	location = 'ep_prm.jsp?ShowAllNm=' + e.checked;
}

function goOMF()
{
	location = "http://www.MeetWE.com/meeting/cal.jsp?bck=" + location.href;
}

function upgrade()
{
	location = "../info/upgrade.jsp";
}


function del()
{
	if (!hasCheckFile("fileList"))
	{
		alert("To remove files from your SHARE FILE LIST, select one or more files before clicking the REMOVE icon.");
		return false;
	}

	var s = "If you are not the owner of the file, once you remove it from your SHARE FILE LIST, you would not be able to access the file.\n\nDo you really want to remove the file from your list?";
	if (!confirm(s))
		return false;

	// remove all checked items: just remove the ShareID from the attachment
	var f = document.FileAction;
	var fIds = getCheckedFileIds("fileList");
	if (fIds != "")
	{
		f.ids.value = fIds;
		f.action = "post_del_share.jsp"
		f.submit();
	}
}

function showShare(op)
{
	if (op == 1)
		location = 'ep_prm.jsp?showShare=false';
	else
		location = 'ep_prm.jsp?showShare=true';
}
//-->
</script>

<style type="text/css">
#bubbleDIV {position:relative;z-index:1;left:0em;top:.8em;width:3em;height:3em;vertical-align:bottom;text-align:center;}
img#bg {position:relative;z-index:-1;top:-2.2em;width:3em;height:3em;border:0;}
</style>

</head>

<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">
	<table width="100%" border="0" cellspacing="0" cellpadding="0">
  		<tr align="left" valign="top">
    	<td width="100%">
		<jsp:include page="../head.jsp" flush="true"/>
		</td>
		</tr>
	</table>


<table width='90%' border='0' cellspacing='0' cellpadding='0'>

  <tr align="left" valign="top">
    <td>
      <table width="100%" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td>
            <table width="100%" border="0" cellspacing="0" cellpadding="0">
              <tr>
                <td width="26" height="30"><a name="top">&nbsp;</a></td>
                <td height="20" width='200' align="left" valign="middle" class="head">
				Hi, <%=fName%>
				</td>
				<td width='50%' class='message' align='left'>
<%
	if (isCwModule) {
		ids = PstFlowStepManager.getInstance().findId(pstuser, "CurrentExecutor='" + myUid
			+ "' && State='" + PstFlowStep.ST_STEP_ACTIVE + "'");
		ids = project.filterOnHoldSteps(pstuser, ids);		// only consider open items
		String itemN = "";
		if (ids.length > 1)
			itemN = "s";
		out.println("<img src='../i/bullet_tri.gif'/><a href='../box/worktray.jsp?projId=0'>you have <b>"
			+ ids.length + "</b> work item" + itemN + " pending in your in-tray</a>");
	}
	else {
		out.print("&nbsp;");
	}
%>
				</td>
<%	if (isCRAPP && !isOMFAPP && !isMultiCorp) {%>
				<td><img src='../i/bullet_tri.gif' width='20' height='10'/>
					<a class='listlinkbold' href='javascript:goOMF()'>Open Meeting Facilitator</a>
				</td>
<%	}
	else if (isMultiCorp)
	{
			int idx;
			String levelS = (String)myUi.getAttribute("Status")[0];			
			if (levelS == null)
				levelS = userinfo.LEVEL_1;
			else if ((idx = levelS.indexOf('@')) != -1)
				levelS = levelS.substring(0, idx);
			levelS = town.getLevelString(levelS);
			out.print("<td align='right'><a href='../info/upgrade.jsp' class='listlink'><b>" + levelS + " Membership</a></b></td>");
	}
	else {
		out.print("<td>&nbsp;</td>");
	}

	out.print("</tr>");

	
	if (isPDA) {
		out.print("<tr><td colspan='4' align='right'><img src='../i/bullet_tri.gif' width='20' height='10' />");
		out.print("<a class='listlinkbold' href='ep_prm_pda.jsp'>Goto PDA Page</a></td></tr>");
	}

%>

            </table>
          </td>
        </tr>
        <tr>
          <td width="100%">
<!-- TAB -->
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Home" />
				<jsp:param name="subCat" value="SubHome" />
				<jsp:param name="role" value="<%=iRole%>" />
				<jsp:param name="roleType" value="<%=roleType%>" />
			</jsp:include>
			</td>
		</tr>
        <tr><td><img src='../i/spacer.gif' height='5'/></td></tr>


		<tr id='appSection'>
			<td><table>
			<tr>
            <td><img src='../i/spacer.gif' width='26' height='1'/></td>
              	
			<td>
<div class='divShadow'>
			<table border='0'>
			
<%
			String name, url;
			for (int i=0; i<appList.size(); i++) {
				app = (application) appList.get(i);
				name = app.getStringAttribute("Name");
				
				// transform url with keywords
				url  = transform(me, app.getStringAttribute("URL"));
				
				out.print("<tr><td><img src='../i/bullet_tri.gif' width='30' /></td>");
				out.print("<td class='apptext'><a href='" + url + "' target='_blank' style='color:#404040'>");
				out.print(name + "</a></td></tr>");
				out.print("<tr><td><img src='../i/spacer.gif' height='3'/></td></tr>");
			}
%>
			
			</table>
</div>
			</td>
			</tr>
		
        	<tr><td><img src='../i/spacer.gif' height='20'/></td></tr>
			</table></td>
		</tr>
		
		
<!-- Project list -->
		<tr>
          <td>
            <table width="100%" border="0" cellspacing="0" cellpadding="0">

<%
		/////////////////////////////////////////////////////////////////////////////////////////
		// get project list
		/////////////////////////////////////////////////////////////////////////////////////////
		String uname;
	
		String bgcolor="";
		boolean even = false;
		boolean bBold;
		int maxPhases = 0;

%>

<!-- Start project listing label -->
			  	<tr>
              		<td><img src='../i/spacer.gif' width='26' height='1'/></td>
                	<td width='100%'>
				  		<table width='100%' border='0' cellpadding="0" cellspacing="0">
							<tr>
								<td width='16'><img src='../i/globe.jpg' /></td>
								<td class="heading">&nbsp;<%=label1%></td>
<!-- // @ECC050307 -->
<%	if (myPjIds.length > 0) { %>
					<td class='ptextS1' align='right'>
						<input type='radio' name='ShowProjType' onClick='showProjectType();' value='container'
							<%if (showPjType.equals(project.TYPE_CONTAINER)) {out.print("checked");}%>>Container Project</input>&nbsp;&nbsp;
						<input type='radio' name='ShowProjType' onClick='showProjectType();' value='timeTrack'
							<%if (showPjType.equals(project.TYPE_TIMETRACK)) {out.print("checked");}%>>Time-tracking Project</input>&nbsp;&nbsp;
						<input type='radio' name='ShowProjType' onClick='showProjectType();' value='all'
							<%if (showPjType.equals(project.TYPE_ALL)) {out.print("checked");}%>>All</input>
					</td>
<%	} %>
						    </tr>
						</table>
<%
		String planPage = null;
		if (!isDirector)
		{
			int len1 = -50, len2 = 6;
			String lab1 = "Due";
			String lab2 = "Done";
			if (isCRAPP)
			{
				planPage = "cr.jsp";	// default to cr.jsp rather than proj_plan.jsp
				if (isMultiCorp)
				{
					len1 = -35;
					len2 = 5;
					lab1 = "Expire / Done";
					lab2 = "Size";
				}
			}
			else
			{
				planPage = "proj_top.jsp";	//"proj_plan.jsp";
			}
			String [] label = {"&nbsp;Project Name", "Coordinator", "Team", "Blogs", "Files", "Start", lab1, lab2, "Status"};
			int [] labelLen = {len1, 10, 5, 5, 5, 7, 7, len2, 5};
			boolean [] bAlignCenter = {false, true, true, true, true, true, true, true, true};
			if (myPjIds.length > 0)
				out.print(Util.showLabel(label, labelLen, bAlignCenter, true));		// showAll and align center
		}
		else
		{
			// isDirector
			planPage = "proj_summary.jsp";
			s = Util.getPropKey("bringup", "PHS.TOTAL");
			if (s != null) maxPhases = Integer.parseInt(s);
			else maxPhases = project.MAX_PHASES;
			int totalCol = maxPhases*3 - 1;

			// ECC: code deleted - need to reconstruct header for Director if I want to use it
			
		}	// END: else isDirector
		
		if (isCRAPP)
			planPage = "cr.jsp";
		PstAbstractObject personObj = null;
		int iTotal = 0;	// total space
		int ct = 0;

		if (myPjIds.length > 0)
		{
			PstAbstractObject [] pjObjList = pjMgr.get(me, myPjIds);
			Util.sortName(pjObjList, true);  //@041906SWS
			even = false;

			int iSize = 0;
			String dot, sizeS;
			dt = complete = null;
			Date today = Util.getToday();
			String expDateS = "-";
			String startDateS = "-";
			String doneDateS = "-";
			Date expireDt = null;
			int projCt = 1;

			for (int i=0; i < pjObjList.length; i++)
			{
				// project
				project pjObj = (project) pjObjList[i];
				String status = (String)pjObj.getAttribute("Status")[0];

				if (status == null)
				{
					System.out.println("Data integrity error in project [" + pjObj.getObjectId() + "]");
					Util.deleteProject(pstuser, pjObj.getObjectId());
					continue;
					/*response.sendRedirect("../out.jsp?e=Data integrity error: project Status of project ["
						+ pjObj.getObjectId() + "] is undefined.  Please contact administrator.");
					return;*/
				}

				// filter display by type
				String owner = (String)pjObj.getAttribute("Owner")[0];
				if (!showPjType.equals(project.TYPE_ALL)) {
					if (!showPjType.equals(project.TYPE_CONTAINER) && pjObj.isContainer()) {
						continue;
					}
					if (showPjType.equals(project.TYPE_CONTAINER) && !pjObj.isContainer()) {
						continue;
					}
					if (bShowClosedPj && !status.equals(project.ST_CLOSE)) {
						continue;
					}
				}
				
				if (!isAdmin && !myUidS.equals(owner)
					&& (pjObj.getObjectName().contains("Personal Space@@")) ) {
						continue;	// filter other's personal space
				}
				ct++;
				
				
				String projName = pjObj.getDisplayName();
				int projId = pjObj.getObjectId();

				// updated since my lastLogin
				bBold = false;
				Date lastUpdated = (Date)pjObj.getAttribute("LastUpdatedDate")[0];
				if ( lastUpdated != null && lastLogin!=null && lastUpdated.compareTo(lastLogin) > 0)
					bBold = true;

				String color;

				// get owner's first name
				name = new String();
				if (owner != null)
				{
					try {
						personObj = uMgr.get(me, Integer.parseInt(owner));
						if(personObj.getAttribute("FirstName")[0] != null)
							name = (String)personObj.getAttribute("FirstName")[0];
					}
					catch (Exception e) {
						System.out.println("project [" + projId + "] has invalid Owner (" + owner + ")");
						name = "-";		// user deleted
					}
				}

				// get dates
				if (!isDirector)
				{
					dt = (Date)pjObj.getAttribute("StartDate")[0];
					if (dt != null)
						startDateS = df0.format(dt);
					expireDt = (Date)pjObj.getAttribute("ExpireDate")[0];
					if (expireDt != null)
						expDateS = df0.format(expireDt);

					complete = (Date)pjObj.getAttribute("CompleteDate")[0];
					if (complete != null)
						doneDateS = df0.format(complete);
					else
						doneDateS = "-";
				}

				if (even)
					bgcolor = DARK;
				else
					bgcolor = LIGHT;
				even = !even;
				
				out.print("<tr " + bgcolor + ">");
				out.print("<td class='plaintext'></td>");
				out.print("<td><table border='0' cellspacing='0' cellpadding='0'>");
				out.print("<tr><td class='ptextS1' width='20' height='35'>" + (projCt++) + ".</td><td><a href='../project/" + planPage
						+ "?projId=" + projId + "' class='ptextS1'>" + projName + "</a></td></tr>");
				out.print("</table></td>");
				
				// coordinator
				out.print("<td colspan='2'></td>");
				out.print("<td class='plaintext' align='center'><a href='../ep/ep1.jsp?uid="
						+ owner + "'>" + name + "</a></td>");
				
				// # of team members
				out.print("<td colspan='2'></td>");
				out.print("<td class='plaintext' align='center'><a href='../project/proj_profile.jsp?projId="
						+ projId + "'>" + pjObj.getAttribute("TeamMembers").length + "</a></td>");
				
				// blogs
				int num = rMgr.findId(pstuser, "ProjectID='" + projId + "' && Type='" + result.TYPE_TASK_BLOG + "' && ParentID=null").length;
				out.print("<td colspan='3' class='plaintext' align='center'><a href='../project/proj_plan.jsp?projId="
						+ projId + "&showBlog=1'><div id='bubbleDIV'>" + num);
				out.print("<img id='bg' src='../i/bubble.gif' />");
				out.println("</div></a></td>");
				
				// files
				num = attMgr.findId(pstuser, "ProjectID='" + projId + "' && Type='" + attachment.TYPE_TASK + "'").length;
				out.print("<td colspan='2'></td>");
				out.print("<td class='plaintext' align='center'><a href='../project/cr.jsp?projId="
						+ projId + "'>" + num + "</a></td>");
						
			if (!isDirector) {
							out.print("<td colspan='2' height='25'></td>");	// give a little more vertical spacing
							out.print("<td class='plaintext' align='center'>" + startDateS + "</td>");

							out.print("<td colspan='2'></td>");
							out.print("<td class='plaintext' align='center'>" + expDateS + "</td>");
							
							if (isMultiCorp) {
								// get project size
								iSize = ((Integer)pjObj.getAttribute("SpaceUsed")[0]).intValue();	// in MB
								iTotal += iSize;
							}
								
							out.print("<td colspan='2'></td>");
							if (isCRAPP) {
								sizeS = Util2.getSizeDisplay(iSize, 1);
								out.print("<td class='plaintext' align='right'>");
								out.print(sizeS + "&nbsp;");
							}
							else {
								out.print("<td class='plaintext' align='center'>");
								out.print(doneDateS);
							}
							out.print("</td>");
			}
			else
			{
				if (isPRMAPP)
				{
					///////////////////////////////////////////////////////
					// Director Phases Display
					//out.print("<td><table><tr>");	// use an inner table to align columns
					// @AGQ051806
					phaseManager phMgr = phaseManager.getInstance();
					PstAbstractObject [] ph = phMgr.getPhases(me, String.valueOf(pjObj.getObjectId()));
					boolean isEnd = false;
					String phaseSt = null;
					String [] sa;
					Object object = null;
					for (int j=0; j<maxPhases; j++)
					{
						obj = null;
						object = null;
						phaseSt = null;
						if (!isEnd)
						{
							if (j >= ph.length)
								isEnd = true;
							else
							{
								// @AGQ051806
								obj = ph[j];
								object = obj.getAttribute(phase.TASKID)[0];
								// 110705ECC
								if (object != null)
								{
									// use task to fill the phase info
									try
									{
										// @AGQ051806
										obj = tkMgr.get(me, (String)object);
										s = (String)obj.getAttribute("Status")[0];
										if (s.equals(task.ST_NEW)) s = project.PH_NEW;
										else if (s.equals(task.ST_OPEN) || s.equals(task.ST_ONHOLD)) s = project.PH_START;
										phaseSt = s;
									}
									catch (PmpException e){phaseSt = "unknown state";}
								}
								else
								{
									// @AGQ051806
									object =  obj.getAttribute(phase.STATUS)[0];
									phaseSt = (object != null)?(String)object:null;
									if (phaseSt.equals(project.PH_NEW) || phaseSt.equals(project.PH_START)
											|| phaseSt.equals(project.PH_RISKY))
									{
										// compare expire date to check for late
										object = obj.getAttribute(phase.EXPIREDATE)[0];
										dt = (object != null)?(Date)object:null;
										if (!phase.isSpecialDate(dt) && dt.before(today))
											phaseSt = project.PH_LATE;
										else if (!phase.isSpecialDate(dt) && !dt.after(today))
											phaseSt = project.PH_RISKY;
									}
								}
							}
						}

						dot = "../i/";
						if (phaseSt != null)
						{
							if (phaseSt.equals(project.PH_NEW)) dot += "dot_white.gif";
							else if (phaseSt.equals(project.PH_START)) dot += "dot_lightblue.gif";
							else if (phaseSt.equals(project.PH_COMPLETE)) dot += "dot_green.gif";
							else if (phaseSt.equals(project.PH_LATE)) dot += "dot_red.gif";
							else if (phaseSt.equals(project.PH_CANCEL)) dot += "dot_cancel.gif";
							else if (phaseSt.equals(project.PH_RISKY)) dot += "dot_orange.gif";
							else dot += "dot_white.gif";
						}
						out.print("<td width='4' class='plaintext'></td>");
						out.print("<td width='41' class='plaintext' " + bgcolor + " align='center'>");
						if (phaseSt != null)
							out.print("<img src='" + dot + "' alt='" + phaseSt + "'>");
						else
							out.print("-");
						out.print("</td><td width='2' class='plaintext'></td>");
					}
				}
			}		// end Director
					///////////////////////////////////////////////////////

			// project status
			out.println("<td colspan='2'></td>");
			out.print("<td class='plaintext' align='center'>");
			out.print(pjObj.getStatusDisplay(pstuser, bBold));
			out.print("</td>");

			out.print("</tr>");

			}	// for each project in the list
		}	// if there is any project defined

		if (isMultiCorp)
		{
			if (ct > 0) {
				out.print("<tr><td><img src='../i/spacer.gif' height='3' /></td></tr>");
				out.print("<tr><td></td><td colspan='5' class='plaintext'>(Total space used:"
					+ Util2.getSizeDisplay(iTotal, 1) + ")</td></tr>");
			}
			else {
				out.print("<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>");
				out.print("<tr><td></td><td colspan='5' class='plaintext_grey'>You have no ");
				if (showPjType.equals(project.TYPE_TIMETRACK)) {
					out.print("Time-tracking ");
				}
				else if (showPjType.equals(project.TYPE_CONTAINER)) {
					out.print("Container ");
				}
				out.print("project</td></tr>");
			}
		}
		
		// add new project
		if ((isCRAPP || isPRMAPP) && (isMultiCorp || roleType==1 || roleType==2))
		{
			out.print("<tr><td><img src='../i/spacer.gif' height='15' width='1' /></td></tr>");
			out.print("<tr><td></td><td colspan='5' class='plaintext_big'>");
			out.print("<img src='../i/bullet_tri.gif' width='20' height='10'><b>");
			out.print("<a href='../project/proj_new1.jsp'>Click to add a new project</a></b>");
			out.print(Util4.showHelp("step1", "Click for help in creating new project"));
			out.print("</td></tr>");
		}
%>
				</table>

			  	 	</td>
				 	<td width="20">&nbsp;</td>
			 	</tr>
			 </table>

<%	if (myPjIds.length > 0) { %>
<table border="0" width="120" height="1" cellspacing="0" cellpadding="0">
	<tr><td colspan='2'><img src='../i/spacer.gif' height='20' /></td></tr>
	<tr><td></td><td><table cellspacing='0' cellpadding='0'>
		<tr><td bgcolor='#CCCCCC' height='1' width='30'><img src="../i/spacer.gif" height="1" /></td><td></td></tr>
		</table></td></tr>
	<tr>
		<td width="30" height="1"><img src="../i/spacer.gif" width="26" height="1" /></td>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" /></td>
	</tr>
</table>
<table>
	<tr>
		<td width="25">&nbsp;</td>
		<td class="tinytype" align="center">Project Status:
			<% if (!isDirector) {%>&nbsp;&nbsp;<img src="../i/dot_orange.gif" border="0">New<%}%>
			&nbsp;&nbsp;<img src="../i/dot_green.gif" border="0">Completed
			&nbsp;&nbsp;<img src="../i/dot_lightblue.gif" border="0">Open
			<% if (isDirector) {%>&nbsp;&nbsp;<img src="../i/dot_orange.gif" border="0">High Risk<%}%>
			&nbsp;&nbsp;<img src="../i/dot_red.gif" border="0">Late
			<% if (isDirector) {%>&nbsp;&nbsp;<img src="../i/dot_white.gif" border="0">Not Started<%}%>
			&nbsp;&nbsp;<img src="../i/dot_grey.gif" border="0">On-hold
			&nbsp;&nbsp;<img src="../i/dot_cancel.gif" border="0">Canceled
			&nbsp;&nbsp;<img src="../i/dot_black.gif" border="0">Closed
			&nbsp;&nbsp;<img src="../i/dot_redw.gif" border="0">Updated
		</td>
	</tr>
</table>
<%	}	// if id.length>0 (proj list)
%>

			</td>
		</tr>
		<tr><td><img src='../i/spacer.gif' height='50' /></td></tr>



<!-- End of List of Projects -->

<!-- ********* Begin List of Companies -->
<%
	/////////////////////////////////////////////////////////////////////////////////////////
	// Company List
	/////////////////////////////////////////////////////////////////////////////////////////

	if (isPRMAPP || isCRAPP)
	{
		if (isMultiCorp && (isAdmin || isAcctMgr))
		{
%>
			<tr>
			<td>
            <table width="100%" border="0" cellspacing="0" cellpadding="0">
			  	<tr>
              		<td width="26">&nbsp;</td>
                	<td>
				  		<table width="100%" border='0' cellpadding="0" cellspacing="0">
							<tr>
								<td width='16'><img src='../i/globe.jpg' /></td>
								<td class="heading">&nbsp;Companies</td>
							</tr>
						</table>
					</td>
				</tr>


				<tr>
				<td></td>
				<td>
<%
			// list companies
			if (isAdmin)
				ids = tnMgr.findId(me, "om_acctname='%'");
			else
				ids = tnMgr.findId(me, "AccountManager='" + myUid + "'");

			// show label for companies
			String [] label0 = {"&nbsp;Company Name", "Program Mgr", "Start Date", "# of Employee", "Departments"};
			int [] labelLen0 = {280, 100, 96, 96, 126};
			boolean [] bAlignCenter0 = {false, true, true, true, true};
			if (ids.length > 0)
				out.print(Util.showLabel(label0, labelLen0, bAlignCenter0, true));		// showAll and align center

			PstAbstractObject tn;
			String compName, progMgrIdS, startDtS, deptNames;
			int [] ids1;
			int num;
			for (int i=0; i<ids.length; i++)
			{
				tn = tnMgr.get(me, ids[i]);
				compName = (String)tn.getAttribute("Name")[0];

				uname = "-";
				progMgrIdS = (String)tn.getAttribute("Chief")[0];
				if (progMgrIdS != null)
				{
					try {
						obj = uMgr.get(me, Integer.parseInt(progMgrIdS));
						uname = ((user)obj).getFullName();
					}
					catch (Exception e) {
						System.out.println("Chief [" + progMgrIdS
							+ "] not found for town [" + ids[i] + "]");
						progMgrIdS = null;
						// should replace Chief with Admin
					}
				}
				deptNames = (String)tn.getAttribute("DepartmentName")[0];
				if (deptNames == null) deptNames = "-";
				else deptNames = deptNames.replaceAll(";", "; ");

				startDtS = "-";
				dt = (Date)tn.getAttribute("StartDate")[0];
				if (dt != null)
					startDtS = df0.format(dt);

				ids1 = uMgr.findId(me, "Company='" + ids[i] + "'");
				num = ids1.length;

				if (even)
					bgcolor = DARK;
				else
					bgcolor = LIGHT;
				even = !even;


				out.print("<tr " + bgcolor + "><td colspan='20'><img src='../i/spacer.gif' height='5'/></td></tr>");	// top spacing

				out.print("<tr " + bgcolor + ">");

				// name
				out.print("<td></td>");
				out.print("<td class='ptextS1' valign='top'><a href='../admin/comp_update.jsp?id=" + ids[i] + "'>" + compName + "</a></td>");

				// program mgr
				out.print("<td colspan='2'></td>");
				out.print("<td class='plaintext' align='center' valign='top'>");
				if (progMgrIdS != null)
					out.print("<a href='../ep/ep1.jsp?uid=" + progMgrIdS + "'>" + uname + "</a>");
				out.print("</td>");

				// start date
				out.print("<td colspan='2'></td>");
				out.print("<td class='plaintext' align='center' valign='top'>" + startDtS + "</td>");

				// total employees of the company
				out.print("<td colspan='2'></td>");
				out.print("<td class='plaintext' align='center' valign='top'>" + num + "</td>");

				// departments
				out.print("<td colspan='2'></td>");
				out.print("<td class='plaintext' valign='top' style='word-break:break-all;'>" + deptNames + "</td>");

				out.print("</tr>");

				out.print("<tr " + bgcolor + "><td colspan='20'><img src='../i/spacer.gif' height='5'/></td></tr>");	// bottom spacing
			}
			if (ids.length <= 0)
			{
				out.print("<tr><td><img src='../i/spacer.gif' height='5' /></td></tr>");
				out.print("<tr><td></td><td colspan='5' class='plaintext_big'>");
				out.print("<img src='../i/bullet_tri.gif' width='20' height='10'>");
				out.print("<a href='../admin/comp_new.jsp'>Click to add a new company</a></td></tr>");
			}
%>
				</table>
				</td>
				</tr>
			</table>
			</td>
			</tr>

			<tr><td><img src='../i/spacer.gif' height='50' /></td></tr>
			
<%		} 	// END if isCRAPP && isMultiCorp && isProgMgr||isAdmin
	}
%>


<!-- ***** Watch List -->
<%
	/////////////////////////////////////////////////////////////////////////////////////////
	// Watch list and alert messages
	/////////////////////////////////////////////////////////////////////////////////////////
	
if (isPRMAPP)
{
	ids = tkMgr.findId(me, "Watch='" + myUid + "'");

	// sort the watch list by create date.  Display latest postings first.
%>
<form name="delWatch">
	<tr>
	<td>
		<table width="100%" border="0" cellspacing="0" cellpadding="0">
			<tr>
				<td width="26">&nbsp;</td>
				<td>
		<table width="100%" border='0' cellpadding="0" cellspacing="0">
			<tr>
				<td width='16'><img src='../i/globe_green.jpg' /></td>
				<td class="heading" width="120">&nbsp;Watch List</td>
				<td class="formtext" align="left">(you are watching <b><%=ids.length%></b> task<%if (ids.length>1) out.print("s");%>)
				</td>
				<td align="right">
<%	if (ids.length > 0)
	{%>
			<!--a href="javascript:document.delWatch.submit()" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('delete0','','../i/but/deln.gif',1)"><img src="../i/but/delf.gif" name="delete0" border="0"></a-->
			<a href="javascript:document.delWatch.submit()" class="listlinkbold">>> Delete&nbsp;</a>
<%	}%>
				</td>
			</tr>
			<tr>
				<td colspan="3" bgcolor="#EBECED" height="3"><img src="../i/spacer.gif" width="1" height="3" border="0"></td>
			</tr>
		</table>
		<table width="100%" border="0" cellspacing="0" cellpadding="0">
			<tr>
				  <td colspan="20" height="2" bgcolor="#336699"><img src="../i/spacer.gif" width="2"></td>
			</tr>
			<tr>
				<td width="6" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
				<td bgcolor="#6699cc" class="td_header"><strong>&nbsp;Project/Task Name</strong></td>
				<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2"></td>
				<td width="6" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
				<td width="50" bgcolor="#6699cc" class="td_header" align="center"><strong>Owner</strong></td>
				<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2"></td>
				<td width="6" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
				<td width="30" bgcolor="#6699cc" class="td_header" align="center"><strong>St.</strong></td>
				<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2"></td>
				<td width="6" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
				<td width="53" bgcolor="#6699cc" class="td_header" align="middle"><strong>Due</strong></td>
				<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2"></td>
				<td width="6" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
				<td width="53" bgcolor="#6699cc" class="td_header" align="middle"><strong>Updated</strong></td>
				<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2"></td>
				<td width="6" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
				<td width="30%" bgcolor="#6699cc" class="td_header"><strong>Task Blog</strong></td>
				<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2"></td>
				<td width="6"  bgcolor="#6699cc" class="10ptype">&nbsp;</td>
				<td width="45" bgcolor="#6699cc" class="td_header"><strong>Delete</strong></td>
			</tr>
<%
	even = false;

	planTask ptk;
	String tName;
	int id, len, idx;
	String stackName;

	user empObj = null;
	String ownerIdS, lastOwner = "";
	String tStatus, dot;
	Date lastUpdatedDate, lastBlogDate;
	String latestBlog;
	boolean bUpdated;

	latest_resultManager lrMgr = latest_resultManager.getInstance();
	latest_result lresultObj = null;
	int [] ids1;
	String pidS;

	//out.println("<table width='100%' " + bgcolor +" cellspacing='2' cellpadding='2'>");
	for (int i=0; i<ids.length; i++)
	{
		if (even)
			bgcolor = DARK;
		else
			bgcolor = LIGHT;
		even = !even;

		// display the task and pTask
		tk = (task)tkMgr.get(me, ids[i]);
		pidS = (String)tk.getAttribute("ProjectID")[0];
		s = ((project)pjMgr.get(me, Integer.parseInt(pidS))).getDisplayName();
		ids1 = ptMgr.findId(me, "TaskID='" + ids[i] +"' && Status !='Deprecated'");
		Arrays.sort(ids1);
		id = ids1[ids1.length-1];
		ptk = (planTask)ptMgr.get(me, id);
		stackName = TaskInfo.getTaskStack(me, ptk);
		idx = stackName.lastIndexOf(">>");
		if (idx > 0)
			stackName = stackName.substring(0, idx+2) + "<b>" + stackName.substring(idx+2) + "</b>";
		else
			stackName = "<b>" + stackName + "</b>";
		stackName = s + " >> " + stackName;

		out.print("<tr " + bgcolor + "><td colspan='20'><img src='../i/spacer.gif' height='5'/></td></tr>");	// top spacing
		
		// task path name
		out.print("<tr " + bgcolor + ">");
		out.print("<td></td>");
		out.print("<td valign='top'><table cellspacing='0' cellpadding='0'><tr>");
		out.print("<td>");
		out.print("<a class='ptextS1' href='../project/task_update.jsp?projId="
			+pidS+ "&pTaskId=" + ptk.getObjectId() + "'>");
		out.print(stackName + "</a>");
		out.println("</td>");
		out.print("</tr></table></td>");

		// owner
		out.print("<td colspan='2'></td>");
		out.print("<td align='center' valign='top'>");
		ownerIdS = (String)tk.getAttribute("Owner")[0];
		if (ownerIdS != null)
		{
			// ECC: need to optimize this in the near future
			try {
				if (!ownerIdS.equals(lastOwner))
					empObj = (user)uMgr.get(me,Integer.parseInt(ownerIdS));
				id = empObj.getObjectId();
				lastOwner = ownerIdS;
				out.print("<a class='listlink' href='../ep/ep1.jsp?uid=" + id + "'>");
				out.print((String)empObj.getAttribute("FirstName")[0]);
				out.print("</a>");
			}
			catch (Exception e) {
				out.print("-");
			}
		}
		out.println("</td>");

		// status
		out.print("<td colspan='2'></td>");
		tStatus = (String)tk.getAttribute("Status")[0];
		lastUpdatedDate = (Date)tk.getAttribute("LastUpdatedDate")[0];
		dot = "../i/";
		if (tStatus.equals("Open")) {dot += "dot_lightblue.gif";}
		else if (tStatus.equals("New")) {dot += "dot_orange.gif";}
		else if (tStatus.equals("Completed")) {dot += "dot_green.gif";}
		else if (tStatus.equals("Late")) {dot += "dot_red.gif";}
		else if (tStatus.equals("On-hold")) {dot += "dot_grey.gif";}
		else if (tStatus.equals("Canceled")) {dot += "dot_cancel.gif";}
		else {dot += "dot_grey.gif";}
		out.print("<td class='listlink' width='30' align='center' valign='top'>");
		out.print("<img src='" + dot + "' alt='" + tStatus + "'>");
		if (lastUpdatedDate!= null && lastUpdatedDate.after(lastLogin))
			out.print("<img src='../i/dot_redw.gif' alt='Updated'>");
		out.println("</td>");

		// expire date
		out.print("<td colspan='2'></td>");
		dt = (Date)tk.getAttribute("ExpireDate")[0];
		if (dt == null) s = "-";
		else s = df0.format(dt);
		out.print("<td class='plaintext' align='center' valign='top'>");
		out.print(s);
		out.println("</td>");

		// last updated date
		out.print("<td colspan='2'></td>");
		latestBlog = null;
		lastBlogDate = null;
		ids1 = lrMgr.findId(me, "get_latest_result", tk);
		if (ids1.length > 0)
		{
			lresultObj = (latest_result)lrMgr.get(me, ids1[0]);
			latestBlog = (String)lresultObj.getAttribute("LastComment")[0];
			lastBlogDate = (Date)lresultObj.getAttribute("LastUpdatedDate")[0];
		}

		// the display of last updated date include blog update
		if (lastUpdatedDate == null)
		{
			if (lastBlogDate != null)
				lastUpdatedDate = lastBlogDate;
		}
		else if (lastBlogDate != null && lastBlogDate.after(lastUpdatedDate))
			lastUpdatedDate = lastBlogDate;

		if (lastUpdatedDate == null) s = "-";
		else s = df0.format(lastUpdatedDate);
		out.print("<td class='plaintext' align='center' valign='top'>");
		out.print(s);
		out.println("</td>");

		// blog
		out.print("<td colspan='2'></td>");
		out.print("<td align='left' valign='top'>");
		out.print("<a class='listlink'  href='../blog/blog_task.jsp?projId="+pidS + "&planTaskId=" + ptk.getObjectId() + "'>");
		bBold = (lastBlogDate!=null && lastBlogDate.after(lastLogin))?true:false;
		if (latestBlog != null)
		{
			if (bBold) {
				out.print("<b>");
			}
			latestBlog = latestBlog.replaceAll("<\\S[^>]*>", "");		// strip HTML tag
			idx = latestBlog.indexOf("::");
			if (idx != -1) {
				out.print("<font color='#0000ff'>" + latestBlog.substring(0,idx));
				out.print("</font>" + latestBlog.substring(idx+1,latestBlog.length()));
			}
			else
				out.print(latestBlog + " ...");
			if (bBold) out.print("</b>");
		}
		else
		{
			out.println("no blog");
		}
		out.println("</a>");
		out.print("</td>");

		// delete watch
		out.print("<td colspan='2'></td>");
		out.println("<td class='plaintext' align='center'><input type='checkbox' name='delete_"
			+ ids[i] + "'></td>");

		out.println("</tr>");

		out.print("<tr " + bgcolor + "><td colspan='20'><img src='../i/spacer.gif' height='5'/></td></tr>");	// bottom spacing
	}
	out.print("</table>");
%>
			</td>
			</tr>
			<tr>
			<td width="26">&nbsp;</td>
			<td align="right">
<%	if (ids.length > 0) {%>
		<a href="javascript:document.delWatch.submit()" class="listlinkbold">>> Delete</a>
<%	}%>
			&nbsp;</td>
			</tr>
		</table>

<!-- Legend -->

	<table border="0" width="120" height="1" cellspacing="0" cellpadding="0">
		<tr>
			<td width="26" height="1" bgcolor="#FFFFFF"><img src="../i/spacer.gif" width="26" height="1" border="0"></td>
			<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
		</tr>
	</table>
	<table>
		<tr>
			<td width="25">&nbsp;</td>
			<td class="tinytype" align="center">Task Status:
				&nbsp;&nbsp;<img src="../i/dot_orange.gif" border="0">New
				&nbsp;&nbsp;<img src="../i/dot_lightblue.gif" border="0">Open
				&nbsp;&nbsp;<img src="../i/dot_green.gif" border="0">Completed
				&nbsp;&nbsp;<img src="../i/dot_red.gif" border="0">Late
				&nbsp;&nbsp;<img src="../i/dot_grey.gif" border="0">On-hold
				&nbsp;&nbsp;<img src="../i/dot_cancel.gif" border="0">Canceled
				&nbsp;&nbsp;<img src="../i/dot_redw.gif" border="0">Updated
			</td>
		</tr>
			<tr><td>&nbsp;<br><br></td></tr>

	</table>
	</td>
	</tr>
</form>

<!-- ************************* -->

<% } // end if isPRMAPP
	// End Watch list and alert messages
	////////////////////////////////////////////////////////////////////////////////////
%>

      </table>
    </td>
  </tr>
  <jsp:include page="../foot.jsp" flush="true"/>

</table>
	</td>
</tr>


</table>
<p>&nbsp;</p>

</body>
</html>
