<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2006, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: cr.jsp
//	Author: ECC
//	Date:	06/15/06
//	Description: Central Repository page.
//
//
//	Modification:
//			@ECC011607	Support sorting of files.
//			@ECC081407	Support Blog Module.
//			@ECC091107	Search page jumps to here with task tag location and highlight of corresponding doc.
//			@ECC091908	Allow file owner to share files to individual members outside of the project.
//			@ECC100708	Clipboard actions.
//			@ECC102108	Suggested email dropdown for share files.
//			@ECC031709	Restrictive access task.
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
	String noSession = "../out.jsp?go=project/cr.jsp?projId="+projIdS;
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />
<%!
	private boolean getSetOption(HttpServletRequest req, String prefS)
	{
		HttpSession sess = req.getSession(false);
		String s;
		if ((s=req.getParameter(prefS)) == null)
			s = (String)sess.getAttribute(prefS);
		else
			sess.setAttribute(prefS, s);
		return (s!=null && s.equals("true"));
	}

	static boolean hasChild(Vector rPlan, int i, int level)
	{
		if (i >= rPlan.size()-1)
			return false;		// no task behind me at all
		Hashtable ht = (Hashtable)rPlan.elementAt(i+1);
		int llevel = ((Integer)((Object [])ht.get("Level"))[0]).intValue();
		return (llevel == level+1);
	}
%>

<%
	////////////////////////////////////////////////////////
	final String OPENB = "<B>";
	final String CLOSEB = "</B>";

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
		response.sendRedirect("proj_select.jsp?backPage=cr.jsp");
		return;
	}
	Logger l = PrmLog.getLog();

	userManager userMgr = userManager.getInstance();
	attachmentManager aMgr = attachmentManager.getInstance();
	projectManager pjMgr = projectManager.getInstance();

	int projId = Integer.parseInt(projIdS);
	project projObj = null;
	try {projObj = (project)pjMgr.get(pstuser, projId);}
	catch (PmpException e)
	{
		// failed to get the project, go to select another project
		response.sendRedirect("proj_select.jsp?backPage=cr.jsp");
		return;
	}

	String projName = projObj.getObjectName();
	String projDispName = projObj.getDisplayName();

	String s;
	String backPage = "../project/cr.jsp?projId=" + projIdS;
	String host = Util.getPropKey("pst", "PRM_HOST");

	boolean bRefresh = false;
	if (request.getParameter("refresh") != null)
		bRefresh = true;

	int myUid = pstuser.getObjectId();
	boolean isAdmin = false;
	boolean isDirector = false;
	boolean bShowBfile = false;
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

	// to check if session is CR or PRM
	boolean isPRMAPP = Prm.isPRM();
	boolean isCRAPP = Prm.isCR();
	boolean isMeetWE = Prm.isMeetWE();
	boolean isCwModule = Prm.isCwModule(session);

	// @ECC080108 Multiple company
	boolean isMultiCorp = util.Prm.isMultiCorp();

	// @ECC081407 Blog Module
	boolean isBlogModule = util.Prm.isBlogModule();

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

	// @ECC091107 get highlight document id
	int highlightAttId = 0;
	s = request.getParameter("attId");
	if (s!=null) highlightAttId = Integer.parseInt(s);

	// @ECC011607 support sorting
	String sortby = request.getParameter("sortby");
	if (sortby==null) sortby = "dt";
	String bgcl = "bgcolor='#6699cc'";
	String srcl = "bgcolor='#66cc99'";

	// only show it to project team member unless it is public project
	boolean bReadOnly = false;
	String pjType = (String)projObj.getAttribute("Type")[0];
	String pjName = projName.replaceAll("'", "\\\\'");	// just for SQL
	int [] ids = pjMgr.findId(pstuser, "om_acctname='" + pjName + "' && TeamMembers=" + pstuser.getObjectId());
	if ((ids.length <= 0) && !(isAdmin || isDirector || isProgMgr))
	{
		if (pjType.equals("Private"))
		{
	response.sendRedirect("../out.jsp?e=Access declined.  You are not authorized to access this private workspace.");
	return;
		}
		else if (pjType.equals("Public Read-only"))
	bReadOnly = true;
	}

	s = request.getParameter("ShowBfile");	// check to see if show blog file
	if (s!=null && s.equals("true"))
		bShowBfile = true;

	String format = "MM/dd/yy";
	SimpleDateFormat Formatter;
	Formatter = new SimpleDateFormat (format);
	Date lastLogin = (Date)session.getAttribute("lastLogin");

	String coordinatorIdS = (String)projObj.getAttribute("Owner")[0];
	int coordinatorId = Integer.parseInt(coordinatorIdS);
	boolean isProjOwner = (coordinatorId==myUid);

	// project's TownID stores the TownID this proj belongs to
	String townIdS = (String)projObj.getAttribute("TownID")[0];
	int townId = 0;
	if (townIdS != null)
	{
		townId = Integer.parseInt(townIdS);
		String projTownName = PstManager.getNameById(pstuser, townId);
		session.setAttribute("townName", projTownName);
		//town tObj = (town)townManager.getInstance().get(pstuser, townId);
		//int sheriffId = Integer.parseInt((String)tObj.getAttribute("Chief")[0]);
	}

	user a = (user)pstuser;
	boolean bChangeCurrentPlan = false;
	String lastProjIdS = (String)a.getAttribute("LastProject")[0];
	if ((lastProjIdS == null) || (projId != Integer.parseInt(lastProjIdS)))
	{
		// cannot use pstuser which only has partial attributes
		// a.setAttribute("LastTown", townIdS);
		a.setAttribute("LastProject", projIdS);
		userMgr.commit(a);

		// session.setAttribute("planStack", null);	// ECC: do it later down the code
		bChangeCurrentPlan = true;					// notify plan stack to refresh
	}
	session.setAttribute("projectId", projIdS);		// for plan stack
	
	boolean isTreeExpandAll = !bChangeCurrentPlan && session.getAttribute("expandTree")!=null;

	// need to get the latest plan for this project
	plan latestPlan = projObj.getLatestPlan(pstuser);
	String latestPlanIdS = latestPlan.getObjectName();

	// Versioning
	String planVersion = (String)latestPlan.getAttribute("Version")[0];

	// @ECC063005
	String optStr = (String)projObj.getAttribute("Option")[0];
	if (optStr == null) optStr = "";

	// @ECC070307 option to show only latest revision file
	boolean bLatestRev = getSetOption(request, "LatestRev");

	s = request.getParameter("clipboard");
	if (s!=null && s.length()>0)
		session.setAttribute("clipboard", s);


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
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../file_action.jsp" flush="true"/>
<jsp:include page="../errormsg.jsp" flush="true"/>

<script language="JavaScript">
<!--
var bUsernameEmail = <%=Util.getPropKey("pst", "USERNAME_EMAIL")%>;	// for file_action.jsp

function toggleTree(loc, hasEffect)
{
	// here in cr.jsp, I always need to evaluate when user toggle tree because not only that
	// I depends on whether I have children or not, I also need to depend on whether I have files or not
	//if (hasEffect) {
		var now = new Date().getTime();
		location = "cr.jsp?dd=" + now + "&projId=<%=projId%>&toggle=" + loc + "#" +loc ;
	//}
}

function tree(all, bCheckAnchor, bFirstTime)
{
	var loc = parent.document.URL;
	var anchor = "";
	if (bCheckAnchor)
		anchor = getAnchor(loc);
	var idx, aidLnk="", fstLnk="";
	if ((idx = loc.indexOf("attId=")) != -1)
		aidLnk = "&attId=<%=highlightAttId%>";
	if (bFirstTime)
		fstLnk = "&fst=1";
	location = "cr.jsp?projId=<%=projId%>&tree=" + all + aidLnk + fstLnk + anchor;	// expandALL or closeALL
}

function showBlogFile()
{
	var s = 'false';
	if (ShowBlogForm.ShowBlogFile.checked)
		s = 'true';
	location = 'cr.jsp?projId=<%=projId%>&ShowBfile=' + s;
}

function sort(name)
{	// ECC011607
	location = "cr.jsp?projId=<%=projId%>&sortby=" + name;
}

function toggleOption(op)
{
	// @ECC070307
	var s = 'false';
	if (op==2 && optionForm.LatestRev.checked)
		s = "true";
	var sb = "";
	if ('<%=sortby%>' != "") sb = '&sortby=<%=sortby%>';
	sb += '&ShowBfile=<%=bShowBfile%>';
	if (op == 2)
		location = 'cr.jsp?projId=<%=projId%>&LatestRev=' + s + sb;
}

function copy()
{
	var fids = getCheckedFileIds("fileList");
	if (fids == "")
	{
		alert("To copy files to the clipboard, select one or more files before clicking the CLIPBOARD icon.");
		return false;
	}

	// copy the list of file IDs to the session object
	var e = FileAction.clipboard;
	e.value = fids;
	var len = fids.split(";").length;
	var msg;
	if (len <= 1)
		msg = "1 file copied to clipboard.  You may paste it ";
	else
		msg = len + " files copied to clipboard.  You may paste them ";
	msg += "into another project task or meeting event.";


    FileAction.action = "cr.jsp?msg=" + msg + "#end";
    FileAction.submit();
}

//-->
</script>

</head>
<style type="text/css">
.wrap_table {WORD-BREAK:BREAK-ALL;}
#img_dot {position:relative; top:-.2em; margin-right:5px;}
img#sign {position:relative;top:.4em;}
.ptextS1 {padding-top:5px;}
</style>

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
		</table>

<table width="90%" border="0" cellspacing="0" cellpadding="0">
			<tr>
	          <td>
	            <table width="100%" border="0" cellspacing="0" cellpadding="0">
				  <tr>
					<td width="26" height="30"><a name="top">&nbsp;</a></td>
					<td height="30" align="left" valign="bottom" class="head">
					  <b>File Repository</b>
					</td>
					<td align='right'>
					<table border='0' cellspacing='0' cellpadding='0'>
					<tr><td>
<!-- enter action links here -->					
					</td>
					<td><img src='../i/spacer.gif' width='98' height='1'/></td>
					</tr></table>

					</td>
				  </tr>
	            </table>
	          </td>
	        </tr>
			<tr>
          		<td width="100%">
					<!-- Navigation Menu -->
<%
	if (isMeetWE) {
%>
					<jsp:include page="../in/home.jsp" flush="true">
					<jsp:param name="role" value="<%=iRole%>" />
					</jsp:include>
<%
	} else {
%>
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="File" />
				<jsp:param name="subCat" value="FileRepository" />
				<jsp:param name="role" value="<%=iRole%>" />
				<jsp:param name="projId" value="<%=projIdS%>" />
			</jsp:include>
<%
	}
%>
					<!-- End of Navigation SUB-Menu -->
				</td>
	        </tr>
		</table>
<!-- Content Table -->

 <table width="100%" border="0" cellspacing="0" cellpadding="0">

	<tr>
		<td><img src="../i/spacer.gif" width="15" border="0"></td>
		<td>

<!-- Project Name -->
	<table width="90%" border="0" cellpadding="0" cellspacing="0">
	<tr>

<form>
	<td class="heading" valign='top'>
		Project Name&nbsp;&nbsp;
		<select name="projId" class="formtext" onchange="submit()">
<%
		out.print(Util.selectProject(pstuser, Integer.parseInt(projIdS)));
%>
		</select>

	</td>
</form>

<!-- @ECC070307 Show only latest revision option -->
	<td align='right'>
		<table border='0' cellspacing='0' cellpadding='0'>
<form name="optionForm">
			<tr><td class='plaintext_big'>
			<input type="checkbox" name="LatestRev" onClick="toggleOption(2);"
				<%if (bLatestRev) {%> checked <%}%>>
			Show Latest Revision Only
			</td></tr>
</form>

<%if (!isCRAPP){%>
			<tr><td class='plaintext_big'>
<form name="ShowBlogForm">
		<input type='checkbox' name='ShowBlogFile' onClick="javascript:showBlogFile()" <%if (bShowBfile) out.print("checked"); %>>
			Show blog files
			</td></tr>

</form>
<%} %>
		</table>
	</td>
	</tr>
	</table>


<!-- *************************   Page Headers   ************************* -->

<!-- LABEL -->
<table width="90%" border="0" cellspacing="0" cellpadding="0">
<tr>
<td>
	<table width="100%" border='0' cellpadding="0" cellspacing="0">
	<tr>
	<td bgcolor="#EBECED" height="3"><img src="../i/spacer.gif" width="1" height="3" border="0"></td>
	</tr>
	</table>

<!-- start Table 0 on task listing -->
	<table width="100%" border="0" cellspacing="0" cellpadding="0" >
	<tr><td colspan="20" bgcolor="#336699"><img src='../i/spacer.gif' width='2'></td></tr>
	
	<tr>
<%
	if (sortby.equals("fn")) {
		out.print("<td width='6' " + srcl + ">&nbsp;</td>");
		out.print("<td width='60%' class='td_header' " + srcl + "><b>&nbsp;");
	}
	else {
		out.print("<td width='6' " + bgcl + ">&nbsp;</td>");
		out.print("<td width='60%' class='td_header' " + bgcl + "><b>&nbsp;");
	}

	if (!isTreeExpandAll) {
		out.print("<img src='../i/plus.gif' onClick='tree(\"expandALL\", false, false)'>");
	}
	else {
		out.print("<img src='../i/minus.gif' onClick='tree(\"closeALL\", false, false)'>");
	}
	out.print("&nbsp;Task Folder / ");
	if (sortby.equals("fn")) {
		out.print("File Name");
	}
	else {
		out.print("<a href='javascript:sort(\"fn\")'><font color='ffffff'>File Name</font></a>");
	}
	out.print("</b></td>");
	out.print("<td width='2' bgcolor='#FFFFFF' class='10ptype'><img src='../i/spacer.gif' width='2'></td>");

	String fNameWidth = "228";
	int colspanNum0 = 4;
/*	ECC: don't show blog on cr.jsp
	if (!isCRAPP || isBlogModule) {
		// show blog #
		fNameWidth = "40%";
		colspanNum0 = 1;
		out.print("<td width='6' bgcolor='#6699cc' class='10ptype'>&nbsp;</td>");
		out.print("<td width='35' bgcolor='#6699cc' class='td_header' align='center'><b>Blog</b></td>");
		out.print("<td width='2' bgcolor='#FFFFFF' class='10ptype'><img src='../i/spacer.gif' width='2'></td>");
	}
*/

	// number of files
	out.print("<td width='6' bgcolor='#6699cc' class='10ptype'>&nbsp;</td>");
	out.print("<td width='35' bgcolor='#6699cc' class='td_header' align='center'><b>Files</b></td>");
	out.print("<td width='2' bgcolor='#FFFFFF' class='10ptype'><img src='../i/spacer.gif' width='2'></td>");

	// @ECC091908 share files to individual members
	out.print("<td width='6' " + bgcl + ">&nbsp;</td>");
	out.print("<td width='40' bgcolor='#6699cc' class='td_header' title='Share'><b>Share</b></a></td>");
	out.print("<td width='2' bgcolor='#FFFFFF'><img src='../i/spacer.gif' width='2'></td>");

	if (sortby.equals("au"))
	{
		out.print("<td width='6' " + srcl + ">&nbsp;</td>");
		out.print("<td width='150' class='td_header' align='center' " + srcl + ">&nbsp;<b>Owner</b></td>");
	}
	else
	{
		out.print("<td width='6' " + bgcl + ">&nbsp;</td>");
		out.print("<td width='150' class='td_header' align='center' " + bgcl + ">&nbsp;<a href='javascript:sort(\"au\")'><font color='ffffff'><strong>Owner</strong></font></a></td>");
	}
	out.print("<td width='2' bgcolor='#FFFFFF'><img src='../i/spacer.gif' width='2'></td>");

	if (sortby.equals("dt"))
	{
		out.print("<td width='6' " + srcl + ">&nbsp;</td>");
		out.print("<td width='120' class='td_header' align='center'" + srcl + "><b>Posted</b></td>");
	}
	else
	{
		out.print("<td width='6' " + bgcl + ">&nbsp;</td>");
		out.print("<td width='120' class='td_header' " + bgcl + "><a href='javascript:sort(\"dt\")'><font color='ffffff'><b>Posted</b></font></a></td>");
	}
	out.print("<td width='2' bgcolor='#FFFFFF'><img src='../i/spacer.gif' width='2'></td>");

	out.print("<td width='6' " + bgcl + ">&nbsp;</td>");
	out.print("<td width='80' bgcolor='#6699cc' class='td_header' align='center'><strong>View #</strong></a></td>");
	out.print("<td width='2' bgcolor='#FFFFFF'><img src='../i/spacer.gif' width='2'></td>");

	// checkbox for action
	out.print("<td width='6' " + bgcl + ">&nbsp;</td>");
	out.print("<td width='60' bgcolor='#6699cc' class='td_header'><b>Action</b></a></td>");
	out.println("</tr>");
%>


<!-- PROJ PLAN -->
<%
	String bgcolor="";
	boolean even = false;
	String[] levelInfo = new String[JwTask.MAX_LEVEL];
	String pName, taskIdS, pTaskIdS, expand;

	task t;
	task tkObj;
	int idx, level, order;
	String lastOwner = "";
	SimpleDateFormat dt = new SimpleDateFormat("MM/dd/yy");
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
	int iFilled = 0;
	Integer io = (Integer)session.getAttribute("filledInfo");
	if (io != null) iFilled = io.intValue();
	if ((planStack == null) || bChangeCurrentPlan || ((iFilled & PrmProjThread.CR) == 0) || bRefresh)
	{
		// @050605ECC Use background thread: the order of the following calls is important
		// if the bkgd thread is running to construct the plan stack, kill it
		PrmProjThread.backgroundConstructPlan(
				session, pstuser, latestPlanIdS, projIdS, bChangeCurrentPlan, true);
		if (optStr.contains(project.OP_EXPAND_TREE))
		{
			%><script language="JavaScript">tree("expandALL", true, true);</script><%
			return;
		}

		// Get plan tasks for this project plan
		// @050605ECC Only get top level planTask to display
		planStack = PrmProjThread.setupPlan(
				PrmProjThread.CR, null, null, pstuser, projIdS, latestPlanIdS, true);

		//session.setAttribute("planStack", planStack);
	}
	// end of setting up plan stack

	attachment attmtObj;
	String locS, shareStr, face, iconURL;
	int viewNum;
	int fileCt = 0;
	int noShowLevel = 9999;		// @ECC031709
	if((planStack != null) && !planStack.empty())
	{
		Vector rPlan = (Vector)planStack.peek();
		for(int i=0; i<rPlan.size(); i++)
		{
			Hashtable rTask = (Hashtable)rPlan.elementAt(i);
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
					if (expand==null || expand.equals(PLUS)) {
						expand = MINUS;		// open it now
					}
					else if (expand.equals(MINUS)) {
						// just click to close this item
						// unlike in proj_plan.jsp, here in cr.jsp, I always want to change sign regardless
						// of whether I have children or not because I have to also consider having files
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

			pTaskIdS = (String)rTask.get("PlanTaskID");
			backPage = "../blog/blog_task.jsp?projId=" +projId+ ":planTaskId=" +pTaskIdS;

			// @ECC031709 check restrictive access
			s = Util2.getAttributeString(tkObj, "TeamMembers", ";");
			if (s.length()>0 && !s.contains(String.valueOf(myUid)))
			{
				noShowLevel = level;
				continue;
			}

			int width = 5 + 22 * Math.min(level,3)-1;

			if (even)
			{
				bgcolor = Prm.DARK;
				face = "icon_face1.gif";
			}
			else
			{
				bgcolor = Prm.LIGHT;
				face = "icon_face.gif";
			}
			even = !even;
			out.print("<tr " + bgcolor + ">");		// start task name line
			out.print("<a name='" + taskIdS + "'></a>");
			out.print("<td>&nbsp;<a name='" + locS + "'></a></td>");

			out.print("<td valign='top' width='55%'>");		// the Task Name column
				
			out.println("<table width='100%' " + bgcolor +" border='0' cellspacing='2' cellpadding='2'>");
			out.print("<tr><td width='" + width + "'></td>");
			out.print("<td width='11' valign='top'><table cellspacing='0' cellpadding='0'>");
			out.print("<tr><td><img src='../i/spacer.gif' height='2'></td></tr><tr><td>");
			if (isExpand)
				out.print("<img id='sign' src='../i/minus.gif' onclick='toggleTree(\"" +locS+ "\", " + bHasChild + ")'>");
			else
				out.print("<img id='sign' src='../i/plus.gif' onclick='toggleTree(\"" +locS+ "\", true)'>");	// always evaluate
			out.print("&nbsp;");
			out.print("</td></tr></table></td>");
			out.println("<td class='ptextS1' width='12' valign='top'>");
			out.print(levelInfo[level] + "</td>");
			out.print("<td class='ptextS1' valign='top' title='TaskID: " + taskIdS + "'><a href='../project/task_update.jsp?projId="
				+projId+ "&pTaskId=" + pTaskIdS + "'>");
			out.print(pName + "</a>");
			out.println("</td></tr></table></td>");				// close the Task Name column
			
			// no. of files
			Object [] attInfoArr = (AttInfo [])rTask.get("AttInfo");
			if (attInfoArr == null) attInfoArr = new Object[0];
			out.print("<td colspan='2'></td>");
			out.print("<td class='plaintext' align='center'>" + attInfoArr.length + "</td>");
			
			// for the task name line, blank after showing file number
			if (attInfoArr.length>0) s = "another";
			else s = "a";
			out.print("<td colspan='15' class='ptextS1' valign='baseline'>");
			out.print("<img src='../i/spacer.gif' width='70' height='18'/>");
			out.print("<img src='../i/bullet_tri.gif'/>");
			out.print("<a href='task_update.jsp?taskId=" + taskIdS
					+ "'><i>Attach " + s + " file</i></a></td></tr>");	// close the task name line

			//////////////////////////////////////////////////
			// list file names

			AttInfo att;
			String aid, fileName, uname, dateS, dept;
			String pureName, nextFileName;
			String openB, closeB;
			if (attInfoArr.length>0 && isExpand)
			{
				// ECC011607 sort the files
				if (sortby != "")
					Util2.sortAttInfoArray(attInfoArr, sortby, true);
				for (int j=0; j<attInfoArr.length; j++)
				{
					att = (AttInfo)attInfoArr[j];
					if (att == null)
						continue;	// ECC: a bug appears at Pericom
					if (bLatestRev && !att.bShow)
						continue;	// @ECC070307 option to show only lastest revision files

					fileCt++;
					aid = att.attid;
					uname = att.author;
					dateS = att.dateS;
					dept = att.dept;
					shareStr = att.shareIds;
					attmtObj = (attachment) aMgr.get(pstuser, aid);

					if (dept == null) dept = "";
					else dept = dept.replaceAll("@", "; ");
					fileName = att.filename;
					viewNum = att.frequency;

					// @ECC091107
					if (highlightAttId == Integer.parseInt(aid)) {openB=OPENB; closeB=CLOSEB;}
					else openB = closeB = "";
					
					out.println("<tr " + bgcolor + ">");		// one line per file start
					
					// file name takes up 2 columns
					out.print("<td valign='top' colspan='5'>");		// File Name column (+ 2 if with blog #)
					out.print("<table class='wrap_table' width='100%' " + bgcolor +" border='0' cellspacing='0' cellpadding='0'>");

					out.print("<tr><td colspan='3'><img src='../i/spacer.gif' height='4'></td></tr>");	// add topline space before listing files
					
					out.print("<tr><td><img src='../i/spacer.gif' width='60' height='20'></td>");

					//iconURL = attmtObj.getIconURL();
					iconURL = null;
					if (iconURL == null) iconURL = "../i/ICON_file_t.gif";	//"../i/ICON_file.gif";
					out.print("<td><img id='img_dot' src='" + iconURL + "' /></td>");
					out.print("<td width='100%' valign='top' title='" + dept + "'>");
					out.print("<a class='plaintext' href='" + host + "/servlet/ShowFile?attId=" + aid
						+ "'>" + openB + fileName + closeB + "</a>");
					if (att.bLink) {
						out.print("&nbsp;<a href='goto_link.jsp?attId=" + aid
								+ "'><img src='../i/link.gif' style='position:relative;top:.4em;left:.3em;' border='0'  title='this is a linked file' /></a>");
					}
					else if (att.url!=null && att.url.startsWith("http:")) {
						if (even) s="Gdocs.gif"; else s="Gdocs_g.gif";
						out.print("&nbsp;<img src='../i/" + s + "' border='0' title='this is a Google Docs' />");
					}
					out.print("</td></tr></table></td>");	// close the File Name column
					

					// @ECC091908 share
					out.print("<td colspan='2'><img src='../i/spacer.gif' width='4'></td>");
					out.print("<td align='center' valign='top'>");
					if (shareStr.length() <= 0)
						out.print("<img src='../i/lock3.gif' width='16' title='Private' />");
					else
						out.print("<img src='../i/" + face + "' width='16' title='Share with:\n" + shareStr + "'/>");
					out.print("</td>");

					// owner, posted date, view#
					out.print("<td colspan='2'><img src='../i/spacer.gif' width='2'></td>");
					out.print("<td valign='top' style='word-break:normal' align='center'>");
					out.print("<a class='listlink' href='../ep/ep1.jsp?uid=" + att.uid + "'>" + uname + "</a></td>");
					out.print("<td colspan='2'><img src='../i/spacer.gif' width='4'></td>");
					out.print("<td class='plaintext' valign='top' align='center'>" + dateS + "</td>");
					out.print("<td colspan='2'><img src='../i/spacer.gif' width='2'></td>");
					out.print("<td class='plaintext' valign='top' align='middle'>" + viewNum + "</td>");

					// checkbox for action
					out.print("<td colspan='2'><img src='../i/spacer.gif' width='2'></td>");
					out.print("<td class='plaintext' valign='top' align='middle'>");
					out.print("<input type='checkbox' name='fileList' value='" + aid + "'>");
					out.print("</td>");

					out.print("</tr>");		// closing one file line
 				}	// END for each file
				if (attInfoArr.length > 0) {	// add gap at end of file listing
					out.print("<tr " + bgcolor + "><td colspan='20'><img src='../i/spacer.gif' height='10'/></td></tr>");
				}
			}
			
			if (bShowBfile)
			{
				// list the blog files now
				// first get all the blogs belonging to this bug

				Object [] attIds;
				resultManager rMgr = resultManager.getInstance();
				int [] ids2 = rMgr.findId(pstuser, "TaskID='" + taskIdS + "'");

				boolean bHasPrintedLabel = false;
				for (int j=0; j<ids2.length; j++)
				{
					PstAbstractObject o = rMgr.get(pstuser, ids2[j]);
					attIds = o.getAttribute("AttachmentID");
					if (attIds.length > 0 && attIds[0]!=null)
					{
						if (!bHasPrintedLabel)
						{
							// put the BLOG FILE label and the partition line
							out.print("<tr " + bgcolor + ">");
							out.print("<td colspan='20'><img src='../i/spacer.gif' height='5' border='0'></td></tr>");
							out.print("<tr " + bgcolor + ">");
							out.print("<td colspan='20' class='blog_line' align='left'><img src='../i/spacer.gif' width='55' height='1'/>");
							out.print("<b>BLOG FILE</b></td><td></td></tr>");
							out.print("<tr " + bgcolor + ">");
							out.print("<td colspan='20'><img src='../i/spacer.gif' width='55' height='1'/>");
							out.print("<img src='../i/mid/wkln.gif' height='2' width='100' border='0'></td></tr>");
							bHasPrintedLabel = true;
						}
						for (int k=0; k<attIds.length; k++)
						{
							// list all the attachments from this one blog
							fileCt++;
							attmtObj = (attachment)aMgr.get(pstuser, (String)attIds[k]);
							uname = attmtObj.getOwnerDisplayName(pstuser);
							Date attmtCreateDt = (Date)attmtObj.getAttribute("CreatedDate")[0];
							fileName = attmtObj.getFileName();
							if (fileName.length() > 40) fileName = fileName.substring(0,40) + " " + fileName.substring(40);
							io = (Integer)attmtObj.getAttribute("Frequency")[0];
							if (io != null) viewNum = io.intValue();
							else viewNum = 0;
%>
							<tr <%=bgcolor%>>
							<td colspan='5'><img src='../i/spacer.gif' width='70' height='20'>
								<a class="listlink" href="<%=host%>/servlet/ShowFile?attId=<%=attmtObj.getObjectId()%>"><%=fileName%></a>
							</td>
							<td colspan='5'></td>
							<td colspan='2' class="formtext" valign='top' align='center'><a href="../ep/ep1.jsp?uid=<%=(String)attmtObj.getAttribute("Owner")[0]%>" class="listlink"><%=uname%></a></td>
							<td></td>
							<td colspan='2' class="formtext" valign='top' align='center'><%=dt.format(attmtCreateDt)%></td>
							<td></td>
							<td colspan='2' class="formtext" valign='top' align='center'><%=viewNum%></td>
							<td colspan='2'></td>
							</tr>
	<%					}	// End: for each attachment in this blog
					}
				}			// End: for each blog
				out.print("<tr " + bgcolor + "><td colspan='20'><img src='../i/spacer.gif' height='5'/></td></tr>");
			}	// End: if bShowFile
		}	// END: for each task

		out.println("<form name='FileAction' method='post' action=''>");
		out.print("<input type='hidden' name='backPage' value='../project/cr.jsp'>");
		out.print("<input type='hidden' name='fname' value=''>");
		out.print("<input type='hidden' name='clipboard' value=''>");
		out.print("<input type='hidden' name='iTypeLabel' value=''>");

		// display the shared file and clipboard option
		if (isProjOwner) {
			out.println(Util3.displayShareOption(pstuser, colspanNum0, 14, fileCt, 2, true, true, false));
		}
		else {
			out.print("<tr><td id='total' align='right' class='plaintext' colspan='" + colspanNum0 + "'>");
			out.print("(<b>Total " + fileCt + " files</b>)");
			out.print("</td>");
			out.print("<td colspan='7'></td></tr>");
		}

		
		String msg = request.getParameter("msg");
		if (msg == null)
		{
			msg = (String)session.getAttribute("errorMsg");
			if (msg != null) session.removeAttribute("errorMsg");
		}
		if (msg!=null && msg.length()>0)
		{
			out.print("<tr><td></td><td id='msg' colspan='19' class='message'>"
					+ msg + "</td></tr>");
		}

		out.print("</form>");
		
		if (rPlan.size() <= 0) {
			// empty project plan: output a help line to guide the user
			out.print("<tr><td colspan='19'><img src='../i/spacer.gif' height='10' /></td></tr>");
			out.print("<tr><td colspan='19'><img src='../i/spacer.gif' height='20' /></td></tr>");
			out.print("<tr><td colspan='19'>&nbsp;&nbsp;<img src='../i/bullet_tri.gif'/>"
					+ "<a href='../plan/popPlanInsert.jsp?realorder=0&levelInfo=&lastlevelInfo=&backPage=../plan/updplan.jsp?projId="
					+ projIdS + "' class='ptextS3'><b>Add a task folder to store file</b></a></td>");
			out.print("<tr><td colspan='19'><img src='../i/spacer.gif' height='20' /></td></tr>");
		}
	}	// END if: planStack NOT empty

	out.println("</table>");

%>

		</td>
		</tr>
		<tr><td colspan="2"></td></tr>
	</table>
<!-- END PROJ PLAN -->

		<!-- End of Content Table -->
		<!-- End of Main Tables -->
	</td>
</tr>
</table>
</td>
</tr>

<tr>
	<td><a name='bottom'></a>
		<!-- Footer -->
		<jsp:include page="../foot.jsp" flush="true"/>
		<!-- End of Footer -->
	</td>
</tr>
</table>
</body>
</html>
