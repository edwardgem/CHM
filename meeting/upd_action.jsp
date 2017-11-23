<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
////////////////////////////////////////////////////
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	upd_action.jsp
//	Author:	ECC
//	Date:	08/28/05
//	Description:
//			Allow update the content of action/decision/issue.
//			User can reach this update action page from 3 places:
//			- mtg_live.jsp (when in live meeting)
//			- mtg_update2.jsp (when updating meeting record after the meeting is over)
//			- proj_action.jsp
//
//	Modification:
//			@ECC082305a	Save meeting minutes here, otherwise if user click Cancel
//						he will lose all his typing on the meeting minutes.
//			@ECC041006	Add blog support to action/decision/issue.
//			@041906SSI	Added sort function to Project names.
//			@AGQ081806	Support OMF application by remove project related items
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>
<%@ page import = "util.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	final int RADIO_NUM = 4;
	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}

	int myUid = pstuser.getObjectId();
	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if (iRole > 0)
	{
		if ((iRole & user.iROLE_ADMIN) > 0)
			isAdmin = true;
	}

	// to check if session is OMF or PRM
	boolean isOMFAPP = false;
	boolean isPRMAPP = false;
	String app = (String)session.getAttribute("app");
	if (app.equals("OMF")){
		isOMFAPP = true;
		app = "MeetWE";
	}
	else if (app.equals("PRM"))
		isPRMAPP = true;
	
	String s = null;
	String cancelPage = null, backPage = null;
	String bp = request.getParameter("backPage");	// proj_action.jsp, mtg_update2.jsp or mtg_view.jsp
	String type = request.getParameter("type");		// Action / Decision / Issue
	String oidS = request.getParameter("oid");		// the action/decision/issue being updated
	String pidS = request.getParameter("pid");		// project id for return page only
	String midS = request.getParameter("mid");		// meeting id for return
	String bugIdS = request.getParameter("BugId");	// bug id
	String run  = request.getParameter("run");		// used for mtg_live.jsp
	
	if (StringUtil.isNullOrEmptyString(pidS))
		pidS = (String) session.getAttribute("projId");
	if (StringUtil.isNullOrEmptyString(bp))
		bp = "../project/proj_action.jsp?projId=" + pidS;
	
	String userEdit = "";							// disallow change status when in live meeting

	if (pidS!=null && pidS.length()>0) s = "&projId=" + pidS;
	else s = "";

	// set up for the Cancel Button
	if (run==null || run.length()==0)
	{
		run = "";
		if (midS!=null && midS.length()>0)
		{
			// came from update record after meeting (mtg_update2.jsp or mtg_view.jsp)
			if (bp.indexOf("?") == -1) bp += "?";
			else bp += "&";
			backPage = cancelPage = bp + "mid=" + midS + s + "&refresh=1#action";
		}
		else
		{
			// from proj_action.jsp
			if (bp.indexOf("projId") == -1) {
				if (bp.indexOf("?") == -1) bp += "?";
				bp += "projId=" + pidS;
			}
			cancelPage = bp;		// it already has the ?projId=12345
			backPage = "";
			midS = "";
		}
	}
	else
	{
		// from Live meeting (mtg_live.jsp)
		cancelPage = "mtg_live.jsp?mid=" + midS + s + "&run=true#action";
		backPage = "";
		//userEdit = " disabled";
	}
	String mText = request.getParameter("mtext");
	if (mText == null) mText = "";

	projectManager pjMgr = projectManager.getInstance();
	bugManager bugMgr = bugManager.getInstance();
	userManager uMgr = userManager.getInstance();

	String title = type;
	String desc = request.getParameter("Description");		// in case of change project
	String status = request.getParameter("Status");			// might have changed
	PstAbstractObject [] projMember = null;
	Object [] responsibleIds = new Object[0];
	String firstName, lastName, uName;
	SimpleDateFormat df = new SimpleDateFormat ("MM/dd/yyyy");
	String acExpireS = null;
	int coordId = 0;
	String oidLink;
	String thisItemMidS = null;

	PstAbstractObject obj;
	PstManager mgr = null;
	if (type.equals(action.TYPE_ACTION) || type.equals(action.TYPE_DECISION))
	{
		mgr = actionManager.getInstance();
		obj = mgr.get(pstuser, oidS);
		if (desc == null)
			desc = (String)obj.getAttribute("Subject")[0];
		if (status == null)
			status = (String)obj.getAttribute("Status")[0];
		if (bugIdS == null)
			bugIdS = (String)obj.getAttribute("BugID")[0];
		oidLink = "&aid=" + oidS;
		
		thisItemMidS = obj.getStringAttribute("MeetingID");

		if (type.equals(action.TYPE_ACTION))
		{
			responsibleIds = obj.getAttribute("Responsible");
			acExpireS = df.format((Date)obj.getAttribute("ExpireDate")[0]);
			coordId = Integer.parseInt((String)obj.getAttribute("Owner")[0]);
			title = "Action Item";
		}
	}
	else
	{
		// Issue
		mgr = bugManager.getInstance();
		obj = mgr.get(pstuser, oidS);
		if (desc == null)
			desc = (String)obj.getAttribute("Synopsis")[0];
		if (status == null)
			status = (String)obj.getAttribute("State")[0];
		coordId = Integer.parseInt((String)obj.getAttribute("Creator")[0]);
		oidLink = "&bugId="+oidS;
	}

	int selectedPjId = 0;
	s = request.getParameter("projId");
	if (s == null)
		s = (String)obj.getAttribute("ProjectID")[0];
	if (s!=null && s.length()>0) selectedPjId = Integer.parseInt(s);

	int [] bIds = new int[0];
	if (selectedPjId > 0)
	{
		bIds = bugMgr.findId(pstuser, "ProjectID='" + selectedPjId + "'");
		projMember = ((user)pstuser).getTeamMembers(selectedPjId);
	}
	// @AGQ081806
	else if (!isOMFAPP)
		projMember = ((user)pstuser).getAllUsers();
	else {
		Object [] objArr = ((user) pstuser).getAttribute(user.TEAMMEMBERS);
		if (objArr[0]!=null)
			projMember = uMgr.get(pstuser, objArr);
		else
			projMember = new PstAbstractObject[0];
	}		
			
	String priority = (String)obj.getAttribute("Priority")[0];

	// @ECC082305a save meeting minutes for safety
	if (mText.length()>0 && midS!=null && midS.length()>0
		&& request.getParameter("noSaveMinute") == null)		// not triggered by changeProject()
	{
		meetingManager mMgr = meetingManager.getInstance();
		meeting mtg = (meeting)mMgr.get(pstuser, midS);
		//mText = mText.replaceAll("<p>[(&nbsp;) ]*</p>", "").trim();
		mtg.setAttribute("Note", mText.getBytes("utf-8"));
		mMgr.commit(mtg);
	}
	
	// authority: project coordinator or action responsible/coordinator
	boolean isAuthorized = false;
	if (myUid == coordId) {
		isAuthorized = true;
	}
	else if (responsibleIds.length > 0) {
		// this is an action item, see if 
		for (int i=0; i<responsibleIds.length; i++) {
			if (responsibleIds[i]!= null
					&& (Integer.parseInt((String)responsibleIds[i])) == myUid) {
				isAuthorized = true;
				break;
			}
		}
	}
	if (!isAuthorized && selectedPjId > 0) {
		// check to see if I am the project manaager
		PstAbstractObject p = pjMgr.get(pstuser, selectedPjId);
		s = p.getStringAttribute("Owner");
		if (!StringUtil.isNullOrEmptyString(s)) {
			int pjOwnerId = Integer.parseInt(s);
			isAuthorized = (pjOwnerId == myUid);
		}
	}

%>


<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen" />
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print" />
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../forms.jsp" flush="true"/>
<jsp:include page="../errormsg.jsp" flush="true"/>
<script type="text/javascript" src="mtg1.js"></script>
<script type="text/javascript" src="../get-date.js"></script>
<script type="text/javascript" src="../util.js"></script>

<script language="JavaScript">
<!--
window.onload = function()
{
	//Initialize the chars remaining number
	charRemain("Description", "charCount");
	loadErrPanel();
}

function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

function validation()
{
	if (updAction.Description.value == '')
	{
		fixElement(updAction.Description,
			"Please make sure that the DESCRIPTION field is properly completed.");
		return false;
	}
	
	var description = updAction.Description.value;
	for (i=0;i<description.length;i++) {
		char = description.charAt(i);
		if (char == '\\') {
			fixElement(updAction.Description,
				"DESCRIPTION cannot contain this character: \n  \\");
			return false;
		}
	}
	
	if (updAction.type.value == '<%=action.TYPE_ACTION%>')
		getall(updAction.Responsible);
	updAction.submit();
}

function changeProject()
{
	updAction.backPage.value = '<%=bp%>';
	updAction.action = "upd_action.jsp";
	updAction.submit();
}

function deleteItem()
{
	if (!confirm("Are you sure you want to delete this item?")) {
		return false;
	}
	
	updAction.backPage.value = '<%=cancelPage%>';
	updAction.op.value = 'delete';
	updAction.submit();
}

//send to-do reminders on this items to responsible team members
function sendReminderOnThis()
{
	var loc = parent.document.URL;
	if (loc.indexOf('?') == -1)
		loc += "?pid=<%=pidS%>&type=<%=type%>&oid=<%=oidS%>";
	loc = escape(loc);
	location = "../project/post_sendAction.jsp?projId=<%=selectedPjId%>&aid=<%=oidS%>&bp=" + loc;
}

//-->
</script>

<title>
	<%=Prm.getAppTitle()%> Update
</title>

</head>


<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="100%" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<table width='90%'>
	<tr><td colspan="3">&nbsp;</td></tr>
	<tr>
		<td></td>
		<td>
			<b class="head">Update <%=title%></b>
		</td>
		<td width='240'><table cellspacing='0' cellpadding='0' width='100%'>
			<tr><td class='formtext' valign='top'>
				<img src='../i/bullet_tri.gif' />
				<a class='listlinkbold' href='../blog/blog_task.jsp?projId=<%=pidS%><%=oidLink%>'>Go to Blog</a>
			</td></tr>
<%	if (thisItemMidS != null) { %>
			<tr><td class='listlinkbold'>
				<img src='../i/bullet_tri.gif'/>
				<a href='../meeting/mtg_view.jsp?mid=<%=thisItemMidS%>&aid=<%=oidS%>'>Go to associated meeting</a>
			</td></tr>
<%	}
	// support sending notification
	if (isAuthorized) { %>
		<tr><td class='listlinkbold'>
		<img src='../i/bullet_tri.gif'/>
		<a href='javascript:sendReminderOnThis();' title='Send reminder on this action item'>
					Send reminder</a>
	</td></tr>
<%	}
%>
		</table></td>
	</tr>


	<tr><td colspan="3">&nbsp;</td></tr>

	</table>

	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- CONTENT -->
<form method="post" name="updAction" action="post_updaction.jsp">
<input type="hidden" name="type" value="<%=type%>" />
<input type="hidden" name="run" value="<%=run%>" />
<input type="hidden" name="oid" value="<%=oidS%>" />
<input type="hidden" name="mid" value="<%=midS%>" />
<input type="hidden" name="pid" value="<%=pidS%>" />

<input type="hidden" name="mtext" value="<%=Util.stringToHTMLString(mText)%>" />
<input type="hidden" name="backPage" value="<%=backPage%>" />
<input type="hidden" name="noSaveMinute" value="true" />
<input type='hidden' name='op' value=''/>

<table width='90%'>
<tr>
	<td width='20'>&nbsp;</td>
	<td width='150'>&nbsp;</td>
	<td width='600'>&nbsp;</td>
</tr>


<!-- Description -->
<tr>
	<td width='20'>&nbsp;</td>
	<td class="plaintext_blue" valign="top" width='150'><font color="#000000">*</font> Description:</td>
	<td>
	<table border='0' cellpadding='0' cellspacing='0'>
		<tr><td>
		<textarea id="Description" name="Description" rows="4"
				style='width:700px;'
				onkeyup="return onEnterSubmitAC(event);"><%=desc%></textarea>
		</td></tr>
		<tr><td class="plaintext" align="right" style="color: green">chars remaining: <span id="charCount" style="color:green;">255</span></td>
		</tr></table>
	</td>
</tr>

<!-- status -->
<%	if (type.equals(action.TYPE_ACTION) || type.equals("Issue"))
	{%>

<tr>
	<td></td>
	<td class='plaintext_blue'>&nbsp;&nbsp;&nbsp;Status:</td>
	<td><table border='0' cellpadding='0' cellspacing='0'>
	<tr>

<%
	if (type.equals(action.TYPE_ACTION))
	{	// action item

		out.print("<td width='100' class='plaintext'><input type='radio' name='Status' value='");
		out.print(action.OPEN + "'");
		if (status.equals(action.LATE))
			out.print(" disabled ");		// always disabled
		else if (status.equals(action.OPEN))
			out.print(" checked ");
		out.print(userEdit + ">" + action.OPEN);

		out.print("</td><td width='100' class='plaintext'>");
		out.print("<input type='radio' name='Status' value='' disabled ");
		if (status.equals(action.LATE))
			out.print(" checked ");
		out.print(userEdit + ">" + action.LATE);

		out.print("</td><td width='100' class='plaintext'><input type='radio' name='Status' value='");
		out.print(action.DONE + "'");
		if (status.equals(action.DONE))
			out.print(" checked ");
		out.print(userEdit + ">" + action.DONE);

		out.print("</td><td width='100' class='plaintext'><input type='radio' name='Status' value='");
		out.print(action.CANCEL + "'");
		if (status.equals(action.CANCEL))
			out.print(" checked ");
		out.print(userEdit + ">" + action.CANCEL);

		out.print("</td>");
	}
	else
	{	// issue

		out.print("<td width='100' class='plaintext'><input type='radio' name='Status' value='");
		out.print(bug.OPEN + "'");
		if (status.equals(bug.OPEN))
			out.print(" checked ");
		out.print(userEdit + ">" + bug.OPEN);

		out.print("</td><td width='100' class='plaintext'><input type='radio' name='Status' value='");
		out.print(bug.CLOSE + "'");
		if (status.equals(bug.CLOSE))
			out.print(" checked ");
		out.print(userEdit + ">" + bug.CLOSE);

		out.print("</td>");

		if (status.equals(bug.OPEN))
		{
			// allow to move the opened issue to a PR
			out.print("<td>");
			out.print("<img src='../i/bullet_tri.gif' width='20' height='10'>");
			out.print("<a class='listlinkbold' href='../bug/bug_update.jsp?bugId=" + oidS + "&edit=true'>");
			out.print("Track this ISSUE as a PR</a>");
			out.print("</td>");
		}
	}
%>

	</tr></table>
	</td>
</tr>
<%	}	// END if Action || Issue
%>

<tr><td><img src='../i/spacer.gif' height='3'/></td></tr>

<!-- Due date -->
<%	if (type.equals(action.TYPE_ACTION))
	{
%>
<tr>
	<td></td>
	<td class="plaintext_blue"><font color="#000000">*</font> Due date:</td>
	<td>
		<input class="formtext" type="text" name="Expire" style='width:240px' onclick="javascript:show_calendar('updAction.Expire');"
			onkeydown='return false;' value='<%=acExpireS%>'/>
		&nbsp;<a href="javascript:show_calendar('updAction.Expire');"><img src="../i/calendar.gif" border="0" align="absmiddle" alt="Click to view calendar."/></a>
	</td>
</tr>
<%	}


	////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////
	// panel for more action info
	out.print("<tr><td colspan='3'>");
	out.print(Util.getHeaderPartitionLine());
	out.print("<img id='ImgInfoPanel' src='../i/bullet_tri.gif'/>");
	out.print("<a id='AInfoPanel' href='javascript:togglePanel(\"InfoPanel\", \"More info\", \"Hide info\");' class='listlinkbold'>Hide info</a>");
	
	out.print("<DIV id='DivInfoPanel' style='display:block;'>");
	out.print("<table border='0' cellspacing='0' cellpadding='0' width='100%'>");	// Info panel table

%>

<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>

<!-- priority -->
<tr>
	<td width='25'><img src='../i/spacer.gif' width='25' height='1'/></td>
	<td class="plaintext_blue" width='150'><font color="#000000">*</font> Priority:</td>
	<td>
		<select class='formtext' name='Priority' style='width:120px;'>
			<option value='<%=bug.PRI_HIGH%>' <%if (priority.equals(bug.PRI_HIGH)) out.print("selected");%>><%=bug.PRI_HIGH%></option>
			<option value='<%=bug.PRI_MED%>' <%if (priority.equals(bug.PRI_MED)) out.print("selected");%>><%=bug.PRI_MED%></option>
			<option value='<%=bug.PRI_LOW%>' <%if (priority.equals(bug.PRI_LOW)) out.print("selected");%>><%=bug.PRI_LOW%></option>
		</select>
	</td>
</tr>

<tr><td><img src='../i/spacer.gif' height='5'/></td></tr>

<%

	if (!isOMFAPP) {
%>
<!-- issue/bug -->
	<%	if (!type.equals("Issue") && isPRMAPP && Prm.isCtModule())
		{
	%>
	<tr>
		<td></td>
		<td class="plaintext_blue">&nbsp;&nbsp;&nbsp;Issue / PR:</td>
		<td>
			<select class='formtext' name='BugId'>
				<option value=''>- select issue/PR ID -</option>
	<%			int bugId = 0;
				if (bugIdS!=null && bugIdS.length()>0)
					bugId = Integer.parseInt(bugIdS);
				for (int i=0; i<bIds.length; i++)
				{
					out.print("<option value='" + bIds[i] + "'");
					if (bIds[i] == bugId) out.print(" selected");
					out.print(">" + bIds[i] + "</option>");
				}
	%>
			</select>
		</td>
	</tr>
	<%	}
	} 
	else {
		//out.println("<input type='hidden' name='projId' value=''>");
		out.println("<input type='hidden' name='BugId' value=''>");
	}
%>

<tr><td><img src='../i/spacer.gif' height='5'/></td></tr>

<!-- project name -->
<tr>
	<td>&nbsp;</td>
	<td class="plaintext_blue">&nbsp;&nbsp;&nbsp;Project Name:</td>
	<td class='plaintext'>
<%
	out.println("<select class='formtext' name='projId' onChange='changeProject();' style='width:240px;'>");
	out.println("<option value=''>- select project name -</option>");

	int [] pjObjId = pjMgr.getProjects(pstuser);
	if (pjObjId.length > 0)
	{
		PstAbstractObject [] projectObjList = pjMgr.get(pstuser, pjObjId);
		//@041906SSI
		Util.sortName(projectObjList, true);
		
		project pj;
		String pName;
		Date expDate;
		String expDateS = new String();
		int id;
		for (int i=0; i < projectObjList.length ; i++)
		{
			// project
			pj = (project) projectObjList[i];
			pName = pj.getDisplayName();
			id = pj.getObjectId();

			out.print("<option value='" + id +"' ");
			if (id == selectedPjId)
				out.print("selected");
			out.print(">" + pName + "</option>");
		}
	}
	out.println("</select>");
	out.print("&nbsp;&nbsp;&nbsp;");
	out.print("<input type='checkbox' name='ChangeProject'>Move action item to this project");
%>
	</td>
</tr>

<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>

<!-- Coordinator -->
<%	if (!type.equals(action.TYPE_DECISION))
	{
		if (type.equals(action.TYPE_ACTION))
			s = "Coordinator";
		else
			s = "Submitter";
%>
<tr>
	<td></td>
	<td class="plaintext_blue"><font color="#000000">*</font> <%=s%>:</td>
	<td>
		<select class="formtext" type="text" name="Owner" style='width:240px;'>
<%
		if (selectedPjId > 0)
			projMember = ((user)pstuser).getTeamMembers(selectedPjId);
		else if (!isOMFAPP)
			projMember = ((user)pstuser).getAllUsers();
		else {
			Object [] objArr = ((user) pstuser).getAttribute(user.TEAMMEMBERS);
			if (objArr[0]!=null)
				projMember = uMgr.get(pstuser, objArr);
			else
				projMember = new PstAbstractObject[0];
		}
		// sort by name
		Util.sortName(projMember, true);

		boolean found = false;
		for (int i=0; i<projMember.length; i++)
		{
			if (projMember[i] == null) continue;
			int id = projMember[i].getObjectId();
			uName = ((user)projMember[i]).getFullName();
			out.print("<option value='" + id + "'");
			if (id==coordId || (!found && id==myUid))
			{
				out.print(" selected");
				found = true;
			}
			out.println(">" +uName+ "</option>");
		}
		if (!found)
		{
			// coordinator not in this selected project member list
			uName = ((user)uMgr.get(pstuser, coordId)).getFullName();
			out.print("<option value='" + coordId + "' selected>" + uName + "</option>");
		}
%>
		</select>
	</td>
</tr>
<%	}	// end (type != Decision) %>

<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>

<!-- Responsible -->
<%	if (type.equals(action.TYPE_ACTION))
	{
%>

<tr>
	<td></td>
	<td valign="top" class="plaintext_blue">&nbsp;&nbsp;&nbsp;Responsible:</td>
	<td>
<%
	// projMember will be on the left while responsibleIds will be on the right	
	if (responsibleIds.length>0 && responsibleIds[0]!=null)
	for (int i = 0; i < responsibleIds.length; i++)
	{
		int id = Integer.parseInt((String)responsibleIds[i]);
		for (int j = 0; j < projMember.length; j++)
		{
			if (projMember[j] == null) continue;
			if (projMember[j].getObjectId() == id)
			{
				projMember[j] = null;
				break;
			}
		}
	}
%>
		<table border="0" cellspacing="0" cellpadding="0">
		<tr>
			<td class="formtext">
			<select class="formtext_fix" name="Selected" multiple size="5">
<%
	if (projMember != null && projMember.length > 0)
	{
		Util.sortName(projMember, true);
		for (int i=0; i < projMember.length; i++)
		{
			if (projMember[i] == null) continue;
			uName = ((user)projMember[i]).getFullName();
			out.println("<option value='" +projMember[i].getObjectId()+ "'>&nbsp;" +uName+ "</option>");
		}
	}
%>
			</select>
			</td>

			<td>&nbsp;&nbsp;&nbsp;</td>
			<td align="center" valign="middle">
				<input type="button" class="button" name="add" value="&nbsp;&nbsp;&nbsp;&nbsp;Add &gt;&gt;&nbsp;&nbsp;" onClick="swapdata(this.form.Selected,this.form.Responsible)">
			<br><input type="button" class="button" name="remove" value="<< Remove" onClick="swapdata(this.form.Responsible,this.form.Selected)">
			</td>
			<td>&nbsp;&nbsp;&nbsp;</td>

<!-- people selected -->
			<td class="formtext">
				<select class="formtext_fix" name="Responsible" multiple size="5">
<%
	if (responsibleIds.length>0 && responsibleIds[0]!=null)
	{
		PstAbstractObject [] selectedMember = uMgr.get(pstuser, Util2.toIntArray(responsibleIds));
		Util.sortName(selectedMember, true);
		user aUser;
		for (int i=0; i < selectedMember.length; i++)
		{
			aUser = (user)selectedMember[i];
			out.println("<option value='" + aUser.getObjectId() + "'>&nbsp;"
				+ aUser.getFullName() + "</option>");
		}
	}
%>
				</select>
			</td>
		</tr>
		</table>

</td>
</tr>
<%	}%>
<!-- End of Responsible -->

<%
	/////////////////////////////////////////
	// close more action info panel
	out.print("</table></DIV>");	// END Info panel table
	out.print("</td></tr>");


	////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////
	// panel for blog
	out.print("<tr><td colspan='3'>");
	out.print(Util.getHeaderPartitionLine());
	out.print("<img id='ImgBlogPanel' src='../i/bullet_tri.gif'/>");
	out.print("<a id='ABlogPanel' href='javascript:togglePanel(\"BlogPanel\", \"Add blog\", \"Hide blog\");' class='listlinkbold'>Add blog</a>");
	
	out.print("<DIV id='DivBlogPanel' style='display:none;'>");
	out.print("<table border='0' cellspacing='0' cellpadding='0' width='100%'>");	// Blog panel table

	out.print("<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>");

	// Enter blog
	out.print("<tr><td width='20'><img src='../i/spacer.gif' width='20'/></td>");
	out.print("<td class='plaintext_blue' valign='top' width='155'></td>");
	out.print("<td><textarea name='Comment' style='width:700px;' rows='5'></textarea>");
	out.print("</tr>");


	/////////////////////////////////////////
	// close blog panel
	out.print("</table></DIV>");	// END Blog panel table
	out.print("</td></tr>");


%>


<!-- Submit Button -->
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan='2'><br/>
			<img src='../i/spacer.gif' width='380' height='1'/>
			<input type='button' class='button_medium' onclick='validation();' value='Submit'/>
			<img src='../i/spacer.gif' width='10'/>
			<input type='button' class='button_medium' onclick='deleteItem();' value='Delete'/>
			<img src='../i/spacer.gif' width='30' height='1'/>
			<input type='button' class='button_medium' onclick="location='<%=cancelPage%>'" value='Cancel'/>
		</td>
	</tr>


</table>
</form>


<tr><td>&nbsp;</td></tr>


<!-- BEGIN FOOTER TABLE -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

