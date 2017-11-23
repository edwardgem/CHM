<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2005, EGI Technologies, Co.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: mtg_update2.jsp
//	Author: ECC
//	Date:	03/04/05
//	Description: Update a meeting after it finishes.
//
//
//	Modification:
//			@ECC082305	Support adding issues and link action/decision to issue/PR
//			@AGQ040506	Support of multi upload files
//			@ECC041006	Add blog support to action/decision/issue.
//			@041906SSI	Added sort function to Project names.
//			@ECC061206a	Add project association to meeting.
//			@SWS061406	Updated file listing.
//			@AGQ081606	Allow user to edit meeting Type (e.g. public or private)
//			@AGQ090606	Removed Proj ID and Bug ID from listings of Action/Decision
//			@AGQ092906	Retreived FCKeditor text user FCKeditor's methods.
//			@ECC110206	Add Description attribute.
//			@ECC112806	Allow adding new attendee after the meeting.
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

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />
<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

////////////////////////////////////////////////////////
	final int RADIO_NUM		= 4;

	String midS = request.getParameter("mid");
	if ((pstuser instanceof PstGuest) || (midS == null))
	{
		response.sendRedirect("../out.jsp?e=Access declined when updating meeting record");
		return;
	}
	String host = Util.getPropKey("pst", "PRM_HOST");

	int myUid = pstuser.getObjectId();
	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if (iRole > 0)
	{
		if ((iRole & user.iROLE_ADMIN) > 0)
			isAdmin = true;
	}

	// to check if session is OMF or PRM
	boolean isPRMAPP = Prm.isPRM();
	boolean isOMFAPP = Prm.isMeetWE();
	String app = Prm.getAppTitle();

	userManager uMgr = userManager.getInstance();
	actionManager aMgr = actionManager.getInstance();
	meetingManager mMgr = meetingManager.getInstance();
	projectManager pjMgr = projectManager.getInstance();
	bugManager bMgr = bugManager.getInstance();
	resultManager rMgr = resultManager.getInstance();
	attachmentManager attMgr = attachmentManager.getInstance();
	userinfoManager uiMgr = userinfoManager.getInstance();
	
	userinfo myUI = (userinfo) uiMgr.get(pstuser, String.valueOf(myUid));
	TimeZone myTimeZone = myUI.getTimeZone();
	
	SimpleDateFormat df1 = new SimpleDateFormat ("MM/dd/yy");
	SimpleDateFormat df2 = new SimpleDateFormat ("MM/dd/yyyy");
	SimpleDateFormat df3 = new SimpleDateFormat ("MM/dd/yy (E) hh:mm a");
	SimpleDateFormat df4 = new SimpleDateFormat ("hh:mm a");
	if (!userinfo.isServerTimeZone(myTimeZone)) {
		df1.setTimeZone(myTimeZone);
		df2.setTimeZone(myTimeZone);
		df3.setTimeZone(myTimeZone);
		df4.setTimeZone(myTimeZone);
	}
	PstUserAbstractObject owner;

	meeting mtg = (meeting)mMgr.get(pstuser, midS);

	String s, uName;

	String status = (String)mtg.getAttribute("Status")[0];
	String subject = (String)mtg.getAttribute("Subject")[0];
	String location = (String)mtg.getAttribute("Location")[0];
	if (location == null) location = "";
	String recurring = (String)mtg.getAttribute("Recurring")[0];
	s = (String)mtg.getAttribute("Owner")[0];
	int ownerId = Integer.parseInt(s);
	user u = (user)uMgr.get(pstuser, ownerId);
	String ownerName = u.getFullName();

	// date
	Date start = (Date)mtg.getAttribute("StartDate")[0];
	Date expire = (Date)mtg.getAttribute("ExpireDate")[0];
	String todayS = df1.format(new Date());

	// get the blog text - meeting notes
	Object bTextObj = mtg.getAttribute("Note")[0];
	String bText = (bTextObj==null)?"":new String((byte[])bTextObj, "utf-8");
	if (bText.length()==0 || bText.equals("null"))
	{
		// put the agenda into the minute
		bText = mtg.getAgendaString().replaceAll("@@", ":");	// the agenda may have this encoded
	}
	
	String townIdS = (String)mtg.getAttribute("TownID")[0];
	if (townIdS==null || townIdS.length()<=0) townIdS = "0";

	// get potential proj team member and bugId list
	PstAbstractObject [] projMember = null;
	int selectedPjId = 0;
	int [] ids;
	int [] bIds = new int[0];
	Object [] objArr;
	if (isOMFAPP)
	{
		objArr = ((user) pstuser).getAttribute(user.TEAMMEMBERS);
		if (objArr[0] != null)
			projMember = uMgr.get(pstuser, objArr);
		else {
			if (townIdS.equals("0")) 
				projMember = new PstAbstractObject[0];
			else {
				// get the circle members if this is a circle meeting
				ids = uMgr.findId(pstuser, "Towns=" + townIdS);
				projMember = uMgr.get(pstuser, ids);
			}
		}
		// Sort
		Util.sortUserArray(projMember, true);
	}
	else
	{
		s = request.getParameter("projId");
		if (s!=null && s.length()>0)
			selectedPjId = Integer.parseInt(s);
		else
		{
			// @ECC061206a
			s = (String)mtg.getAttribute("ProjectID")[0];
			if (s!=null) selectedPjId = Integer.parseInt(s);
		}

		if (selectedPjId <= 0)
		{
			projMember = ((user)pstuser).getAllUsers();
			bIds = bMgr.findId(pstuser, "om_acctname='%'");
			objArr = ((user) pstuser).getAttribute(user.TEAMMEMBERS);
			if (objArr[0]!=null) {
				projMember = uMgr.get(pstuser, objArr);
				Util.sortUserArray(projMember, true);
			}
			else
				projMember = new PstAbstractObject[0];
		}
		else
		{
			projMember = ((user)pstuser).getTeamMembers(selectedPjId);
			bIds = bMgr.findId(pstuser, "ProjectID='" + selectedPjId + "'");
		}
	}

	// get attendee list
	Object [] attendeeArr = mtg.getAttribute("Attendee");
	String [] sa;
	ArrayList attendeeList = new ArrayList();	// those who hasn't signed in yet
	ArrayList presentList = new ArrayList();	// those who has signed in
	int [] iResponsibleArr = new int[attendeeArr.length];		// @ECC062807
	boolean found = false;
	for (int i=0; i<attendeeArr.length; i++)
	{
		s = (String)attendeeArr[i];
		if (StringUtil.isNullOrEmptyString(s)) break;
		sa = s.split(meeting.DELIMITER);
		if (StringUtil.isNullOrEmptyString(sa[0])) break;
		int aId = Integer.parseInt(sa[0]);
		iResponsibleArr[i] = aId;					// @ECC062807

		if (aId == myUid)
		{
			if (!sa[1].endsWith(meeting.ATT_PRESENT))
			{
				// I just logon
				mtg.removeAttribute("Attendee", s);
				s += meeting.ATT_LOGON + meeting.ATT_PRESENT;
				mtg.appendAttribute("Attendee", s);
				mMgr.commit(mtg);
			}
			presentList.add(sa[0]);		// I just signed in
			found = true;
			continue;
		}

		if (sa[1].endsWith(meeting.ATT_PRESENT))
			presentList.add(sa[0]);
		else
			attendeeList.add(sa[0]);
	}
	if (!found)
		presentList.add(String.valueOf(myUid));

	// @ECC062807 set up responsible list
	int id, respPersonId;
	PstAbstractObject [] respObjArr = uMgr.get(pstuser, iResponsibleArr);
	objArr = mtg.getAttribute("Responsible");
	for (int i=0; i<respObjArr.length; i++)
	{
		respPersonId = respObjArr[i].getObjectId();

		for (int j=0; j<objArr.length; j++)
		{
			s = (String)objArr[j];
			if (s == null) break;
			id = Integer.parseInt(s);
			if (id == respPersonId)
			{
				respObjArr[i] = null;	// already chosen as responsible persons
				break;
			}
		}
		if (ownerId==respPersonId)
			respObjArr[i] = null;		// this is the owner
	}
	Util.sortName(respObjArr);

	// @ECC112806 get new attendees
	ArrayList newAttendeeList = new ArrayList();
	for (int i=0; i<projMember.length; i++)
	{
		u = (user)projMember[i];
		if (u == null) continue;

		id = u.getObjectId();
		found = false;
		for (int j=0; j<presentList.size(); j++)
		{
			if (id == Integer.parseInt((String)presentList.get(j)))
			{
				found = true;
				break;
			}
		}
		for (int j=0; !found && j<attendeeList.size(); j++)
		{
			if (id == Integer.parseInt((String)attendeeList.get(j)))
			{
				found = true;
				break;
			}
		}
		if (!found)
			newAttendeeList.add(u);
	}

	// @ECC110206
	String defaultTxt = ">> (Optional) Enter a short paragraph to describe this meeting.";
	bTextObj = mtg.getAttribute("Description")[0];
	String descStr = (bTextObj==null)? defaultTxt : new String((byte[])bTextObj, "utf-8");
	descStr = descStr.replaceAll("<br>", "\n");
	descStr = descStr.replaceAll("&nbsp;", " ");

	// @ECC062807 authorized multiple people to update meeting record and actions
	boolean canUpdate = false;
	if (ownerId==myUid)
		canUpdate = true;
	else
	{
		// @ECC062807 authorized multiple people to update meeting record and actions
		objArr = mtg.getAttribute("Responsible");
		for (int i=0; i<objArr.length; i++)
		{
			s = (String)objArr[i];
			if (s == null) break;
			if (Integer.parseInt(s) == myUid)
			{
				canUpdate = true;
				break;
			}
		}
	}

	// check authority
	String UserEdit = "disabled";
	if (isAdmin || canUpdate)
		UserEdit = "";
	
	// child meeting (followup meeting)
	String followupMtgIdS = "";
	s = mtg.getStringAttribute("Recurring");
	if (s!=null && s.contains(meeting.OCCASIONAL)) {
		sa = s.split(meeting.DELIMITER);
		if (sa.length > 2)
			followupMtgIdS = sa[2];		// Occasional::0::12345
	}

	////////////////////////////////////////////////////////
%>

<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<%-- @AGQ040506--%>
<script src="../multifile.js"></script>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen" />
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print" />
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../formsM.jsp" flush="true"/>
<jsp:include page="../forms.jsp" flush="true"/>
<script language="JavaScript" src="../get-date.js"></script>
<script language="JavaScript" src="../date.js"></script>
<script type="text/javascript" src="ajax_utils.js"></script>
<script type="text/javascript" src="mtg.js"></script>
<script type="text/javascript" src="mtg1.js"></script>
<script type="text/javascript" src="<%=host%>/FCKeditor/fckeditor.js"></script>
<script type="text/javascript" src="../resize.js"></script>
<script type="text/javascript" src="../util.js"></script>

<script type="text/javascript" language="javascript">
window.onload = function()
{
	var oFCKeditor = new FCKeditor( 'mtgText' ) ;
	oFCKeditor.Height = 450;
	oFCKeditor.ReplaceTextarea() ;

	// to enable dragging editor box
	initDrag();
	new dragObject(handleBottom[0], null, new Position(0, beginHeight), new Position(0, 1000),
					null, BottomMove, null, false, 0);
}

<!--
var currentType = "";

function fixElement(e, msg)
{
	alert(msg);
// @AGQ040306
	if (e)
		e.focus();
}

function validation()
{
	var f = document.updMeeting;

	if (f.Subject.value =='')
	{
		fixElement(f.Subject,
			"Please make sure that the SUBJECT field is properly completed.");
		return false;
	}

	var subject = f.Subject.value;
	for (i=0;i<subject.length;i++) {
		char = subject.charAt(i);
		if (char == '\\') {
			fixElement(f.Subject,
				"SUBJECT cannot contain these characters: \n  \\");
			return false;
		}
	}

	if (f.status.value == '<%=meeting.COMMIT%>')
	{
		if (!confirm("Once the meeting is CLOSED, the meeting records can no longer be changed.  Do you really want to CLOSE the meeting?"))
			return false;
	}

	// check for action item
	if (f.Description.value != '')
	{
		// create a new action item
		if (f.Description.value.length > 255)
		{
			s = "The " + currentType + " is " + f.Description.value.length
				+ " characters long that is longer than the max allowed length (255), please shorten the description or break the item into multiple items.";
			if (f.Description.value.length > 255)
			{
				alert(s);
				return false;
			}
		}

		getall(f.Responsible);
	}

	var description = f.Description.value;
	for (i=0;i<description.length;i++) {
		char = description.charAt(i);
		if (char == '\\') {
			fixElement(f.Description,
				"DESCRIPTION cannot contain these characters: \n  \\");
			return false;
		}
	}

	// @ECC110206
	var desc = f.MtgDesc.value;
	if (desc.substring(0,2) == ">>")
		f.MtgDesc.value = '';
	for (i=0;i<desc.length;i++) {
		char = desc.charAt(i);
		if (char == '"') {
			fixElement(f.MtgDesc,
				"DESCRIPTION cannot contain double quote (\")");
			return false;
		}
	}

// @AGQ040406
	formblock= document.getElementById('inputs');
	forminputs = formblock.getElementsByTagName('input');
	var isFileName = true;
	for (var i=0; i<forminputs.length; i++) {
		if (forminputs[i].type == 'file' && forminputs[i].value != '') {
			if (isFileName)
				isFileName = affirm_addfile(forminputs[i].value);
			else
				break;
		}
	}
	if(!isFileName)
		return false;

// @AGQ040406
	if(!findDuplicateFileName(forminputs))
		return false;

	getall(f.ResponsibleR);

	updMeeting.encoding = "multipart/form-data";

	updMeeting.submit();
}

function setPageLocation(s)
{
	if (s == 'done')
		updMeeting.Continue.value = 'false';
	else
		updMeeting.PageLabel.value = s;
	updMeeting.NoSave.value = '';
	return validation();
}

function resetAC()
{
	// reset button for action item/decision/issue
	updMeeting.Description.value = '';

	var e = updMeeting.Responsible;
	getall(e);
	swapdata(e, updMeeting.Selected);

	e = updMeeting.Owner;
	for(j = 0; j < e.length; j++)
	{
		if (e.options[j].value == '<%=myUid%>')
			e.options[j].selected = true;
		else
			e.options[j].selected = false;
	}

	updMeeting.Priority[1].selected = true;	// medium

	updMeeting.Expire.value = '<%=todayS%>';

}

function editAC(id, type)
{
	setMtext();
	updateAction.type.value = type;
	updateAction.oid.value = id;

	var e = updMeeting.projId;
	for (i=0; i<e.length; i++)
		if (e.options[i].selected) updateAction.pid.value = e.options[i].value;

	updateAction.action = "upd_action.jsp";
	updateAction.submit();
}

function deleteAC()
{
	setMtext();
	updateAction.submit();
}

function setMtext()
{
	// @AGQ092906
	var oEditor = FCKeditorAPI.GetInstance('mtgText');
	var bText = oEditor.EditorDocument.body.innerHTML;
	updateAction.mtext.value = bText;
}

function isDecision()
{
	if (updMeeting.BugId)
		updMeeting.BugId.disabled = false;
	updMeeting.Responsible.disabled = true;
	updMeeting.Selected.disabled = true;
	updMeeting.Owner.disabled = true;
	updMeeting.Expire.disabled = true;
	currentType = "decision record";
}

function isAction()
{
	if (updMeeting.BugId)
		updMeeting.BugId.disabled = false;
	updMeeting.Responsible.disabled = false;
	updMeeting.Selected.disabled = false;
	updMeeting.Owner.disabled = false;
	updMeeting.Expire.disabled = false;
	currentType = "action item";
}

function isIssue()
{
	if (updMeeting.BugId)
		updMeeting.BugId.disabled = true;
	updMeeting.Responsible.disabled = true;
	updMeeting.Selected.disabled = true;
	updMeeting.Owner.disabled = false;
	updMeeting.Expire.disabled = true;
	updMeeting.Expire.disabled = true;
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
	// do this for action item / decision / issue
	updMeeting.PageLabel.value = 'action';
	updMeeting.NoSave.value = 'true';
	validation();
	updMeeting.submit();
}

function doclear(e)
{
	if (e.value.substring(0,2) == ">>")
		e.value = '';
	return;
}

function defaultText(e)
{
	if (e.value == '')
		e.value = '<%=defaultTxt%>';
	return;
}

function checkNewAtt()
{
	// @ECC112806
	if (document.updMeeting.newAttendee.value == '')
		return false;
}

function setPublic(public)
{
	if (updMeeting.company) {
		if (public)
			updMeeting.company.disabled = true;
		else
			updMeeting.company.disabled = false;
	}
}

//-->
</script>

<style type="text/css">
.plaintext {line-height:25px;}
.listlink {line-height:25px;}
.listtext_small {line-height:25px;}
</style>

</head>

<title><%=app%> Update Meeting Record</title>
<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" border="0" cellspacing="0" cellpadding="0">
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
                	<b class="head">
					Update Meeting Record
					</b>
					</td></tr>
	            </table>
	          </td>
	        </tr>
			<tr>
          		<td width="90%">
<!-- Navigation Menu -->
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Event" />
				<jsp:param name="subCat" value="" />
				<jsp:param name="role" value="<%=iRole%>" />
			</jsp:include>
<!-- End of Navigation Menu -->
				</td>
	        </tr>
					</table>
				</td>
	        </tr>
		</table>

<form name="updMeeting" action="post_mtg_upd2.jsp" method="post" enctype="multipart/form-data">
<input type="hidden" name="mid" value="<%=midS%>">
<input type="hidden" name="Continue" value="true">
<input type="hidden" name="PageLabel" value="">
<input type="hidden" name="NoSave" value="">

<!-- Content Table -->
<table width="90%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td width="20" align="right"><img src="../i/spacer.gif" border="0" width="15" height="1"></td>
	<td width="150">&nbsp;</td>
	<td>&nbsp;</td>
</tr>

<!-- Subject -->
<tr>
	<td width="20" align="right"><img src="../i/spacer.gif" border="0" width="20" height="1"></td>
	<td width='150' class="plaintext"><b>Subject:</b></td>
		<td>
			<input class="formtext" type="text" name="Subject" style='width:600;' value="<%=subject%>">
		</td>
</tr>

<%
	int pid = 0;
	s = (String)mtg.getAttribute("ProjectID")[0];
	if (s != null) pid = Integer.parseInt(s);

	int [] projectObjId = pjMgr.getProjects(pstuser);
	if (!isOMFAPP) {
%>
<!-- @ECC061206a: Associated Project -->
	<tr>
		<td width="20">&nbsp;</td>
		<td class="plaintext"><b>Project:</b></td>
		<td>
		<select name="ProjectId" class="formtext">
<%
	out.println("<option value=''>- select project name -</option>");

	if (projectObjId.length > 0)
	{
		PstAbstractObject [] projectObjList = pjMgr.get(pstuser, projectObjId);
		Util.sortName(projectObjList, true);

		String pName;
		project pj;
		Date expDate;
		String expDateS = new String();
		for (int i=0; i < projectObjList.length ; i++)
		{
			// project
			pj = (project) projectObjList[i];
			pName = pj.getDisplayName();
			id = pj.getObjectId();

			out.print("<option value='" + id +"' ");
			if (id == pid)
				out.print("selected");
			out.print(">" + pName + "</option>");
		}
	}
%>
		</select>
		</td>
	</tr>
<%	}
	else {
		out.println("<input type='hidden' name='ProjectId' value=''>");
	}
%>
<!-- Location -->
<tr>
	<td>&nbsp;</td>
	<td class="plaintext"><b>Location:</b></td>
	<td class="plaintext"><%=location%></td>
</tr>

<!-- Start time -->
<tr>
	<td>&nbsp;</td>
	<td class="plaintext"><b>Start Time:</b></td>
	<td class="plaintext"><%=df3.format(start)%> - <%=df4.format(expire)%>


<%
	if (recurring != null)
	{
		sa = recurring.split(meeting.DELIMITER);
		out.print("&nbsp;&nbsp;&nbsp;(" + sa[0] + " event");
		int num = Integer.parseInt(sa[1]);
		if (num > 0)
			out.print(" for <b>" + num + "</b> occurrences)");
		else
			out.print(")&nbsp;");
	}
%>
	</td>
</tr>

<%
	////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////
	// panel for meeting info
	out.print("<tr><td colspan='3'>");
	out.print(Util.getHeaderPartitionLine());
	out.print("<img id='ImgInfoPanel' src='../i/bullet_tri.gif'/>");
	out.print("<a id='AInfoPanel' href='javascript:togglePanel(\"InfoPanel\", \"Meeting info\", \"Hide meeting info\");' class='listlinkbold'>Meeting info</a>");
	
	out.print("<DIV id='DivInfoPanel' style='display:none;'>");
	out.print("<table border='0' cellspacing='0' cellpadding='0' width='100%'>");	// Info panel table
%>

<!-- Type -->
<%
	String checked = "";
	String disabled = "";
	String meetingType = (String) mtg.getAttribute(meeting.TYPE)[0];
	if (meetingType == null) meetingType = meeting.PRIVATE;
	if (meetingType.equalsIgnoreCase(meeting.PUBLIC)) {checked="CHECKED='CHECKED'"; disabled="disabled";}

	String typeTooltip = "title='Public meeting is open for all " + app + " members"
			+ "\nPrivate meeting is only open for invitees'";

	// @ECC102706
	townManager tnMgr = townManager.getInstance();
	String companyTooltip = "";
	String companyName = null;
	Object [] myTownIds = pstuser.getAttribute("Towns");

%>
	<tr>
		<td width="20">&nbsp;</td>
		<td colspan='2'>
		<table border='0' cellspacing='0' cellpadding='0'>
		<tr>
			<td width='150' class="plaintext"><b>Type:</b></td>
			<td width='350' class="formtext" <%=typeTooltip%>>
				<input type="radio" name="meetingType" value="<%=meeting.PUBLIC%>" <%=checked%> onclick='setPublic(true)'/>Public
					&nbsp;
<%
	checked = "";
	if (meetingType.equalsIgnoreCase(meeting.PRIVATE)) {
		checked="CHECKED='CHECKED'";
	}
	
	out.print("<input type='radio' name='meetingType' value='"
			+ meeting.PRIVATE + "' " + checked + " onClick='setPublic(false)'>Private &nbsp;");
	
	checked = "";
	if (meetingType.equalsIgnoreCase(meeting.PUBLIC_READ_URL)) {
		checked="CHECKED='CHECKED'";
	}
	out.print("<input type='radio' name='meetingType' value='"
			+ meeting.PUBLIC_READ_URL + "' " + checked + " onClick='setPublic(false)'>Public Read-only &nbsp;");
	
	out.print("</td>");
			
	////////////////////////
	// @ECC102706
	if (myTownIds[0] != null)
	{
		String label;
		if (isOMFAPP) label = "Circle";
		else label = "Company";
		companyTooltip = "title='Company meeting can be seen by all employees of the same company"
			+ "\nPersonal meeting is only seen by meeting invitees'";
		//if (townIdS != null) checked="CHECKED='CHECKED'"; else checked = "";
%>
			<td width='70' class="plaintext"><b><%=label%>:</b></td>
			<td class="formtext" <%=companyTooltip%>>
				<select name="company" class='formtext' <%=disabled%>>
				<option value='0'>Personal</option>
<%
		//if (checked.length() == 0) checked="CHECKED='CHECKED'"; else checked = "";
		for (int i=0; i<myTownIds.length; i++)
		{
			id = ((Integer)myTownIds[i]).intValue();
			companyName = (String)tnMgr.get(pstuser, id).getAttribute("Name")[0];
			out.print("<option value='" + id + "'");
			if (id == Integer.parseInt(townIdS)) out.print(" selected");
			out.print(">" + companyName + "</option>");
		}
		out.print("</select></td>");
	}

%>

		</tr>
		</table>
		</td>
	</tr>

<!-- @ECC110206 Meeting Description (not action item description) -->
	<tr>
		<td width="20">&nbsp;</td>
		<td class="plaintext" valign='top'><b>Description:</b></td>
		<td class="formtext">
			<textarea name="MtgDesc" onFocus="return doclear(this);"
				class='plaintext_big'
				style='width:600;'
				onBlur="return defaultText(this);"
				rows="4" cols='80'><%=descStr%></textarea>
		</td>
	</tr>

<tr><td colspan="3"><img src="../i/spacer.gif" width="5" height="10"></td></tr>

<!-- Status -->

<tr>
	<td>&nbsp;</td>
	<td class="plaintext"><b>Status:</b></td>
	<td class="plaintext">
<%
		String [] stValAry = {meeting.FINISH, meeting.COMMIT};
		out.println("<select class='formtext' name='status'>");
		for (int i=0; i<stValAry.length; i++)
		{
			out.println("<option value='" + stValAry[i] + "'");
			if (status.equals(stValAry[i]))
				out.print(" selected");
			out.print(">" + stValAry[i] + "</option>");
		}
%>
	</select>&nbsp;&nbsp;
	<span class='plainttext_grey' valign='bottom'>(Set status to Close only if you don't want to make further changes to this meeting.)</span>
	</td>
</tr>

<tr><td colspan="3"><img src="../i/spacer.gif" width="5" height="10"/></td></tr>

<tr>
	<td>&nbsp;</td>
	<td class="plaintext"><b>Followup Meeting ID:</b></td>
	<td class="plaintext">
		<input type='text' style='width:600;' size='6' name='FollowupMtgId' class='plaintext_big' value='<%=followupMtgIdS%>'/>
	</td>
</tr>

<tr><td colspan="3"><img src="../i/spacer.gif" width="5" height="10"/></td></tr>

<!-- Add New Attendee @ECC112806 -->
<tr>
	<td>&nbsp;</td>
	<td class="plaintext" valign="top"><b>Add Attendee:</b></td>
	<td class="plaintext">
		<select id="adNames" class="formtext" type="text" name="newAttendee">
		<option value=''>- new attendee -</option>
<%
		for (int i=0; i<newAttendeeList.size(); i++)
		{
			u = (user)newAttendeeList.get(i);
			id = u.getObjectId();
			uName = u.getFullName();	//firstName + (lastName==null?"":(" "+lastName));
			out.print("<option value='" + id + "'");
			out.println(">&nbsp;" +uName+ "</option>");
			}
%>
			</select>
			&nbsp;&nbsp;<input type="submit" class="button" name="addNew" value="  Add  " onclick="return checkNewAtt();"/>
	</td>
</tr>


<!-- Attendee List -->
<tr>
	<td>&nbsp;</td>
	<td class="plaintext" valign="top"><b>Attendee:</b></td>
	<td class="plaintext">
		<table border='0' cellspacing='0' cellpadding='0'>
<%

	int num = 0;
	String idS;
	for(int i=0; i<presentList.size(); i++)
	{
		idS = (String)presentList.get(i);
		u = (user)uMgr.get(pstuser, Integer.parseInt(idS));
		uName = u.getFullName();
		if (uName.length() > 16) uName = (String)u.getAttribute("FirstName")[0] + " " + ((String)u.getAttribute("LastName")[0]).charAt(0) + ".";

		if (num%RADIO_NUM == 0) out.print("<tr>");
		out.print("<td width='20' valign='center'><input type='checkbox' name='present_" + idS + "' ");
		out.print(" checked></td><td class='plaintext' width='115'><a href='../ep/ep1.jsp?uid=" + idS + "' class='listlink'>"
			+ uName + "</a></td>");
		if (num%RADIO_NUM == RADIO_NUM-1) out.print("</tr>");
		num++;
	}
	for(int i=0; i<attendeeList.size(); i++)
	{
		idS = (String)attendeeList.get(i);
		try{u = (user)uMgr.get(pstuser, Integer.parseInt(idS));}
		catch (PmpException e){continue;}
		uName = u.getFullName();
		if (uName.length() > 16) uName = (String)u.getAttribute("FirstName")[0];	// + " " + ((String)u.getAttribute("LastName")[0]).charAt(0) + ".";
		if (num%RADIO_NUM == 0) out.print("<tr>");
		out.print("<td width='20' valign='center'><input type='checkbox' name='present_" + idS + "' ");
		out.print("></td><td class='plaintext' width='115'><a href='../ep/ep1.jsp?uid=" + idS + "' class='listlink'>"
			+ uName + "</a></td>");
		if (num%RADIO_NUM == RADIO_NUM-1) out.print("</tr>");
		num++;
	}
	if (num%RADIO_NUM != 0) out.print("</tr>");

%>
		</table>
	</td>
</tr>

<%
	String guestEmails = Util2.getAttributeString(mtg, "GuestEmails", "; ");
%>
<tr><td colspan="3"><img src="../i/spacer.gif" width="5" height="10"/></td></tr>
<!-- Guest -->
<tr>
<td></td>
<td valign="top" class="plaintext"><b>Guest:</b></td>
<td>
	<input type='text' style='width:600;' size='80' name='Guest' class='plaintext_big' value='<%=guestEmails%>'/>
</td>
</tr>

<tr><td colspan="3"><img src="../i/spacer.gif" width="5" height="10"></td></tr>
<!-- @ECC062807 Responsible -->
<tr>

<td width="20">&nbsp;</td>
<td valign="top" class="plaintext"><b>Authorize to Update:</b></td>
<td>

<table border="0" cellspacing="0" cellpadding="0">
<tr>
	<td>
	<select class="formtext_fix" name="SelectR" multiple size="5" <%=UserEdit%>>
<%
	for (int i=0; i<respObjArr.length; i++)
	{
		u = (user)respObjArr[i];
		if (u == null) continue;
		uName = u.getFullName();
		out.println("<option value='" + u.getObjectId() + "'>&nbsp;" +uName+ "</option>");
	}
%>
	</select>
	</td>
	<td>&nbsp;&nbsp;&nbsp;</td>
	<td align="center" valign="middle">
		<input type="button" class="button" name="add3" value="&nbsp;&nbsp;&nbsp;&nbsp;Add &gt;&gt;&nbsp;&nbsp;" onClick="swapdata(this.form.SelectR,this.form.ResponsibleR)">
		<div><input type="button" class="button" name="remove3" value="<< Remove" onClick="swapdata(this.form.ResponsibleR,this.form.SelectR)"></div>
	</td>
	<td>&nbsp;&nbsp;&nbsp;</td>
<!-- people selected -->
	<td bgcolor="#FFFFFF">
		<select class="formtext_fix" name="ResponsibleR" id="ResponsibleR" multiple size="5" <%=UserEdit%>>
<%
		objArr = mtg.getAttribute("Responsible");
		found = false;
		for (int i=0; i<objArr.length; i++)
		{
			if (objArr[i] == null) break;
			if (Integer.parseInt((String)objArr[i]) == ownerId)
			{
				found = true;
				break;
			}
		}
		for (int i=0; i<objArr.length; i++)
		{
			if (objArr[i] == null) break;
			try {u = (user)uMgr.get(pstuser, Integer.parseInt((String)objArr[i]));}
			catch (PmpException e){continue;}
			uName = u.getFullName();
			out.println("<option value='" + u.getObjectId() + "'>&nbsp;" +uName+ "</option>");
		}
		if (!found)
			out.println("<option value='" + ownerId + "'>&nbsp;" +ownerName+ "</option>");
%>
		</select>
	</td>
</tr>
</table>
</td>
</tr>

<tr><td colspan="3">&nbsp;</td></tr>

<!-- New file attachment -->
<tr>
	<td></td>
	<td class="plaintext" valign="top"><b>Add File Attachment:</b></td>
	<td class="formtext">
<%-- @AGQ040506 --%>
		<span id="inputs"><input id="my_file_element" type="file" class="button_browse" size="50" /></span><br /><br />
		Files to be uploaded:<br />
		<table><tbody id="files_list"></tbody></table>
		<script>
			var fileNumbers = 0;
			if(navigator.userAgent.indexOf("Firefox") != -1)
				fileNumbers = 1;
			var multi_selector = new MultiSelector( document.getElementById( 'files_list' ), fileNumbers, document.getElementById( 'my_file_element' ).className , document.getElementById( 'my_file_element' ).size );
			multi_selector.addElement( document.getElementById( 'my_file_element' ) );
		</script><br />
	</td>
</tr>

<!-- list file attachments -->
<tr>
	<td width="20">&nbsp;</td>
	<td class="plaintext" valign="top"><b>File Attachment:</b></td>
	<td class="formtext">
		<table border="0" cellspacing="0" cellpadding="0">
<%
	// ECC: include link files
	Object [] attmtList = mtg.getAttribute("AttachmentID");
	int [] aids = Util2.toIntArray(attmtList);
	int [] linkIds = attMgr.findId(pstuser, "Link='" + midS + "'");		// @ECC103008
	aids = Util2.mergeIntArray(aids, linkIds);
	attachment attmtObj;
	String fileName;
	Date attmtCreateDt;
	if (aids.length <= 0)
	{%>
		<tr><td class="plaintext_grey">None</td></tr>
<%	}
	else
	{%>
	<tr>
	<td width="250" bgcolor="#6699cc" class="td_header"><strong>&nbsp;File Name</strong></td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="80" bgcolor="#6699cc" class="td_header"><strong>Owner</strong></td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="120" bgcolor="#6699cc" class="td_header" align="left"><strong>Posted On</strong></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	</tr>
<tr>
<%
		Arrays.sort(aids);
		for (int i=0; i<aids.length; i++)
		{
			// list files by alphabetical order
			attmtObj = (attachment)attMgr.get(pstuser, aids[i]);
			uName = attmtObj.getOwnerDisplayName(pstuser);
			attmtCreateDt = (Date)attmtObj.getAttribute("CreatedDate")[0];
			fileName = attmtObj.getFileName();
%>
			<td class="plaintext" width="318">
				&nbsp;<a class="listlink" href="<%=host%>/servlet/ShowFile?attId=<%=attmtObj.getObjectId()%>"><%=fileName%></a>
			</td>
			<td colspan='2'>&nbsp;</td>
			<td class="formtext"><a href="../ep/ep1.jsp?uid=<%=(String)attmtObj.getAttribute("Owner")[0]%>" class="listlink"><%=uName%></a></td>
			<td colspan='2'>&nbsp;</td>
			<td class="formtext"><%=df2.format(attmtCreateDt)%></td>
			<td>&nbsp;</td>
			<td><input class="formtext_small" type="button" class="button_medium" value="delete"
				onclick="return affirm_delfile('../project/post_delfile.jsp?mid=<%=midS%>&fname=<%=fileName%>');" align="right"></td>
<%
			out.println("</tr>");
		}
	}	// @SWS061406 ends
	out.println("</table></td>");
%>
</tr>
<!-- end file attachment -->

<%
	// @ECC100708 paste from clipboard
	PstAbstractObject o;
	s = (String)session.getAttribute("clipboard");
	if (s != null)
	{
		out.print("<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>");
		out.print("<tr><td colspan='2'></td><td><table><tr>");
		out.print("<td><img src='../i/clipboard.jpg' /></td>");
		out.print("<td class='plaintext'><a href='javascript:paste();'>Paste files from Clipboard</a></td></tr></table></td></tr>");

		// put the form for selecting files as display:none
		out.print("<tr><td colspan='2'></td><td><div id='clipboard' style='display:none'>");
		out.print("<input type='hidden' name='op' value=''>");
		out.print("<input type='hidden' name='backPage' value='../meeting/mtg_update1.jsp?mid=" + midS + "'>");
		out.print("<table>");
		sa = s.split(";");
		for (int i=0; i<sa.length; i++)
		{
			o = attMgr.get(pstuser, sa[i]);
			s = (String)o.getAttribute("Location")[0];
			s = s.substring(s.lastIndexOf("/")+1);
			out.print("<tr><td class='formtext'><input type='checkbox' name='clip_" + sa[i]
			      + "'>" + s + "</td></tr>");
		}

		// buttons
		out.print("<tr><td class='formtext' align='center'>"
				+ "<input class='formtext' type='button' name='Copy' value='Copy' onclick='clip(1);'>&nbsp;&nbsp;"
				+ "<input class='formtext' type='button' name='Move' value='Move' onclick='clip(2);'>&nbsp;&nbsp;"
				+ "<input class='formtext' type='button' name='Cancel' value='Cancel' onclick='closeClip();'>"
				+ "</td></tr>");
		out.print("</table>");
		out.print("</div>");
		out.print("</td></tr>");
	}


	/////////////////////////////////////////
	// close meeting info panel
	out.print("</table></DIV>");	// END Info panel table
	out.print("</td></tr>");
%>

<tr><td colspan="3"><a name="minute">
	<img src="../i/spacer.gif" width="5" height="10"></a></td></tr>

<!-- meeting minutes -->
<tr>
	<td>&nbsp;</td>
	<td colspan="2" class="plaintext_blue"><b>Meeting Minutes:</b></td>
</tr>
<tr><td colspan="3"><img src="../i/spacer.gif" width="5" height="10"></td></tr>
<tr>
	<td>&nbsp;</td>
	<td colspan="2">
	<table width="85%" border="0" cellspacing="0" cellpadding="0" align="center">
	<tr><td colspan="2" valign="top" >
		<div id='textDiv'>
		<textarea name="mtgText" id='mtgText'><%=Util.stringToHTMLString(bText)%></textarea>
		</div>
		<div align='right'>
		<span id="handleBottom" ><img src='../i/drag.gif' style="cursor:s-resize;"/></span>
		<span><img src='../i/spacer.gif' width='20' height='1'/></span>
		</div>
	<p align="center">
		<input type="Button" class="button_medium" name="Submit" onClick="return setPageLocation('minute');" value="Save & Continue">
		&nbsp;
		<input type="Button" class="button_medium" value="  Cancel  " onclick="location='mtg_view.jsp?mid=<%=midS%>&refresh=1'">&nbsp;
	</p>
	</td></tr>
	</table>
	</td>
</tr>

<!-- End of add meeting notes -->

<tr><td colspan="3"><a name="action">
	<img src="../i/spacer.gif" width="5" height="10"></a></td></tr>

<!-- //////////////////////////////////////////////////// -->
<!-- ADD ACTION ITEMS / DECISIONS / ISSUES -->
<%
	String desc = (String)session.getAttribute("action");
	if (desc != null)
		session.removeAttribute("action");
	else
		desc = "";
	Object [] responsibleIds = new Object[0];
	String acExpireS = df2.format(new Date().getTime() + 604800000);	// give it one week by default

	String type = request.getParameter("type");
	if (type == null) type = action.TYPE_ACTION;
%>

<tr>
	<td>&nbsp;</td>
	<td colspan="2" class="plaintext_blue"><b>Action / Decision
<%	// @AGQ081806
	if (isPRMAPP) { %>
	/ Issue:
<%	} %>
	</b></td>
</tr>
<tr><td colspan="3"><img src="../i/spacer.gif" width="5" height="10"></td></tr>

<tr>
	<td>&nbsp;</td>
	<td class="plaintext"><b>Type:</b></td>
	<td><table border='0' cellpadding='0' cellspacing='0'><tr>
	<td class="plaintext" width="450">
		<input type="radio" name="Type" value="<%=action.TYPE_ACTION%>" onClick="isAction();" <%if (type.equals(action.TYPE_ACTION)) out.print("checked");%>> Action
		<input type="radio" name="Type" value="<%=action.TYPE_DECISION%>" onClick="isDecision();" <%if (type.equals(action.TYPE_DECISION)) out.print("checked");%>> Decision
<%	// @AGQ081806
	if (isPRMAPP) {
%>
		<input type="radio" name="Type" value="Issue" onClick="isIssue();" <%if (type.equals("Issue")) out.print("checked");%>> Issue
<% 	} %>
	</td>

	<td class="plaintext" width='80'><b>Priority:</b>&nbsp;</td>
	<td>
			<select class='formtext' name='Priority'>
				<option value='<%=bug.PRI_HIGH%>'><%=bug.PRI_HIGH%></option>
				<option value='<%=bug.PRI_MED%>' selected><%=bug.PRI_MED%></option>
				<option value='<%=bug.PRI_LOW%>'><%=bug.PRI_LOW%></option>
			</select>
	</td>
	</tr></table></td>
</tr>

	<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>

<!-- Description -->
<tr>
	<td>&nbsp;</td>
	<td class="plaintext" valign="top"><b>Description:</b></td>
	<td><table border='0' cellpadding='0' cellspacing='0' width='100%'>
		<tr><td>
		<textarea id="Description" type="text" name="Description" style='width:90%;'
			rows="4" onkeyup="return onEnterSubmitAC(event);"><%=desc%></textarea>
		</td></tr>
		<tr><td class="plaintext" align="right" style="color: green">chars remaining: <span id="charCount" style="color:green;">255</span>
		<img src='../i/spacer.gif' width='100' height='1'/></td>
		</tr></table>
	</td>
</tr>

<tr><td colspan="3"><img src="../i/spacer.gif" width="5" height="3"></td></tr>
<%
	if (!isOMFAPP) {
%>
<!-- LINK to project name & Issue/Bug -->
<tr>
	<td>&nbsp;</td>
	<td class="plaintext"><b>Project Name:</b></td>
	<td>
	<table border='0' cellpadding='0' cellspacing='0'>

<!-- project name -->
<tr>
	<td class="plaintext" width='315'>
<%
	out.println("<select class='formtext' name='projId' onChange='changeProject();'>");
	out.println("<option value=''>- select project name -</option>");

	projectObjId = pjMgr.getProjects(pstuser);
	if (projectObjId.length > 0)
	{
		PstAbstractObject [] projectObjList = pjMgr.get(pstuser, projectObjId);
		//@041906SSI
		Util.sortName(projectObjList, true);

		project pj;
		String pName;
		Date expDate;
		String expDateS = new String();
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
%>
	</td>

<!-- related issue/bug -->
<%	if (Prm.isCtModule()) {
		out.print("<td class='plaintext' width='80'><b>Issue / PR:</b>&nbsp;</td>");
		out.print("<td><select class='formtext' name='BugId'>");
		out.print("<option value=''>- select issue/PR ID -</option>");
		for (int i=0; i<bIds.length; i++) {
			out.print("<option value='" + bIds[i] + "'>" + bIds[i] + "</option>");
		}
		out.print("</select></td>");
	}
%>
	</tr></table></td>
</tr>
<%	}
	else {
		out.println("<input type='hidden' name='projId' value=''>");
		out.println("<input type='hidden' name='BugId' value=''>");
	}
%>


<tr><td colspan="3"><img src="../i/spacer.gif" height="10"/></td></tr>

<!-- Action Item Coordinator -->
<tr>
	<td>&nbsp;</td>
	<td class="plaintext"><b>Coordinator:</b></td>
	<td>
		<select class="formtext" type="text" name="Owner">
<%
		for (int i=0; i<projMember.length; i++)
		{
			if (projMember[i] == null) continue;
			id = projMember[i].getObjectId();
			uName = ((user)projMember[i]).getFullName();
			out.print("<option value='" + id + "'");
			if (id==myUid) out.print(" selected");
			out.println(">&nbsp;" +uName+ "</option>");
		}
%>
		</select>
	</td>
</tr>

<tr><td colspan="3"><img src="../i/spacer.gif" height="10"/></td></tr>

<!-- Responsible -->
<tr>
	<td>&nbsp;</td>
	<td valign="top" class="plaintext"><b>Responsible:</b></td>
	<td>
<%
	// projMember will be on the left while alertEmp will be on the right
	String [] fName = new String [responsibleIds.length];
	String [] lName = new String [responsibleIds.length];
	if (responsibleIds.length>0 && responsibleIds[0]!=null)
	for (int i = 0; i < responsibleIds.length; i++)
	{
		id = Integer.parseInt((String)responsibleIds[i]);
		for (int j = 0; j < projMember.length; j++)
		{
			if (projMember[j] == null) continue;
			if (projMember[j].getObjectId() == id)
			{
				fName[i] = (String)projMember[j].getAttribute("FirstName")[0];
				lName[i] = (String)projMember[j].getAttribute("LastName")[0];
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
		for (int i=0; i < responsibleIds.length; i++)
		{
			out.println("<option value='" +responsibleIds[i]+ "'>&nbsp;" +fName[i]+ "&nbsp;" +lName[i]+ "</option>");
		}
	}
%>
				</select>
			</td>
		</tr>
		</table>

</td>
</tr>
<!-- End of Responsible -->

<tr><td colspan="3"><img src="../i/spacer.gif" height="10"/></td></tr>

<!-- Done By -->
<tr>
	<td>&nbsp;</td>
	<td class="plaintext"><b>Done By:</b></td>
	<td>
		<input class="formtext" type="Text" name="Expire" size="25" onClick="javascript:show_calendar('updMeeting.Expire');"
			onKeyDown='return false;' value='<%=acExpireS%>'>
		&nbsp;<a href="javascript:show_calendar('updMeeting.Expire');"><img src="../i/calendar.gif" border="0" align="absmiddle" title="Click to view calendar."></a>
	</td>
</tr>

<tr><td colspan="3"><img src="../i/spacer.gif" width="5" height="10"></td></tr>

<script type="text/javascript">
<!--
	selectType('<%=type%>');	// Need to enable/disable widgets based on type: action/decision/issue
//-->
</script>

<tr>
	<td>&nbsp;</td>
	<td colspan="2">
	<p align="center">
		<input type="Button" class="button_medium" name="Submit" onClick="return setPageLocation('action');" value="Save & Continue">
		&nbsp;
		<input type="Button" class="button_medium" value="  Reset  " onclick="resetAC();">
	</p>
	</td>
</tr>

</form>
<!-- //////////////////////////////////////////////////// -->


<tr><td colspan="3"><img src="../i/spacer.gif" width="5" height="10"/></td></tr>

<!-- LIST OF ACTION / DECISION / ISSUE -->

<form method="post" name="updateAction" action="post_updaction.jsp">
<input type="hidden" name="mid" value="<%=midS%>"/>
<input type="hidden" name="oid"/>
<input type="hidden" name="pid"/>
<input type="hidden" name="type"/>
<input type="hidden" name="mtext"/>
<input type="hidden" name="backPage" value="mtg_update2.jsp"/>

<%
	// for Action Item, Decision Records and Issues

	// get the list of action items
	ids = aMgr.findId(pstuser, "(MeetingID='" + midS + "') && (Type='" + action.TYPE_ACTION + "')");
	Arrays.sort(ids);
	PstAbstractObject [] aiObjList = aMgr.get(pstuser, ids);

	// decisions
	ids = aMgr.findId(pstuser, "(MeetingID='" + midS + "') && (Type='" + action.TYPE_DECISION + "')");
	Arrays.sort(ids);
	PstAbstractObject [] dsObjList = aMgr.get(pstuser, ids);

	// issues
	ids = bMgr.findId(pstuser, "MeetingID='" + midS + "'");
	Arrays.sort(ids);
	PstAbstractObject [] bgObjList = bMgr.get(pstuser, ids);

	// variables
	boolean even;
	String bgcolor = null;
	String ownerIdS, projIdS, bugIdS, priority, dot;
	user uObj;
	int aid;
	Object [] respA;
	Date expireDate, createdDate;
	action obj;

	if (aiObjList.length>0 || dsObjList.length>0 || bgObjList.length>0)
	{%>
<tr>
	<td>&nbsp;</td>
	<td colspan="2" align="right">
		<a href="javascript:deleteAC()" class="listlinkbold">>> Delete&nbsp;</a>
	</td>
</tr>
<%	}%>


<!-- List of Action Items -->
<tr>
	<td>&nbsp;</td>
	<td colspan="2">

<%
	if (aiObjList.length > 0) {
		if (isOMFAPP)
			out.print(Util.showLabel(PrmMtgConstants.vlabel0OMF, PrmMtgConstants.vlabelLen0OMF, true));
		else if (isPRMAPP)
			out.print(Util.showLabel(PrmMtgConstants.vlabel0, PrmMtgConstants.vlabelLen0, true));
		else
			out.print(Util.showLabel(PrmMtgConstants.vlabel0CR, PrmMtgConstants.vlabelLen0CR, true));	// CR-OMF

		even = false;
	
		for(int i = 0; i < aiObjList.length; i++)
		{	// the list of action item for this meeting object
			obj = (action)aiObjList[i];
			aid = obj.getObjectId();
	
			subject		= (String)obj.getAttribute("Subject")[0];
			status		= (String)obj.getAttribute("Status")[0];
			priority	= (String)obj.getAttribute("Priority")[0];
			expireDate	= (Date)obj.getAttribute("ExpireDate")[0];
			ownerIdS	= (String)obj.getAttribute("Owner")[0];
			projIdS		= (String)obj.getAttribute("ProjectID")[0];
			bugIdS		= (String)obj.getAttribute("BugID")[0];
			respA		= obj.getAttribute("Responsible");
	
			if (even)
				bgcolor = Prm.DARK;
			else
				bgcolor = Prm.LIGHT;
			even = !even;
			out.println("<tr " + bgcolor + ">" + "<td colspan='26'><img src='../i/spacer.gif' height='10'></td></tr>");

			out.print("<tr " + bgcolor + ">");
	
			// Subject
			out.print("<td></td>");
			out.print("<td valign='top'><table border='0'><tr>");
			out.print("<td class='plaintext' valign='top' style='line-height:15px'>" + (i+1) + ". </td>");
			out.print("<td class='plaintext' valign='top' style='line-height:15px'>");
			out.print("<a href='javascript:editAC(\""
				+ aid + "\", \"Action\")'>" + subject + "</a>");
			out.println("</td></tr></table></td>");
	
			// Responsible
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td class='listtext' width='100'>");
	
			found = false;
			for (int j=0; j<respA.length; j++)
			{
				s = (String)respA[j];
				if (s == null) break;
				uObj = (user)uMgr.get(pstuser,Integer.parseInt(s));
				out.print("<a class='listlink' style='line-height:12px' href='../ep/ep1.jsp?uid=" + s + "'>");
				out.print((String)uObj.getAttribute("FirstName")[0]);
				out.print("</a>");
				if (s.equals(ownerIdS))
				{
					found = true;
					out.print("*");
				}
				if (j < respA.length-1 || !found) out.print(", ");
			}
			if (!found)
			{
				// include coordinator/owner into the list of responsible
				uObj = (user)uMgr.get(pstuser,Integer.parseInt(ownerIdS));
				out.print("<a class='listlink' style='line-height:12px' href='../ep/ep1.jsp?uid=" + ownerIdS + "'>");
				out.print((String)uObj.getAttribute("FirstName")[0]);
				out.print("</a>*");
			}
			out.println("</td>");
	
			// Status {OPEN, LATE, CANCEL, DONE}
			dot = "../i/";
			if (status.equals(action.OPEN)) {dot += "dot_lightblue.gif";}
			else if (status.equals(action.LATE)) {dot += "dot_red.gif";}
			else if (status.equals(action.DONE)) {dot += "dot_green.gif";}
			else if (status.equals(action.CANCEL)) {dot += "dot_cancel.gif";}
			else {dot += "dot_grey.gif";}
			out.print("<td colspan='3' class='listlink' align='center' valign='top' style='padding-top:7px'>");
			out.print("<img src='" + dot + "' title='" + status + "'>");
			out.println("</td>");
	
			// Priority {HIGH, MEDIUM, LOW}
			dot = "../i/";
			if (priority.equals(action.PRI_HIGH)) {dot += "dot_red.gif";}
			else if (priority.equals(action.PRI_MED)) {dot += "dot_orange.gif";}
			else if (priority.equals(action.PRI_LOW)) {dot += "dot_yellow.gif";}
			else {dot += "dot_grey.gif";}
			out.print("<td colspan='3' class='listlink' align='center' valign='top' style='padding-top:7px'>");
			out.print("<img src='" + dot + "' title='" + priority + "'>");
			out.println("</td>");
	
			// @ECC041006 support blogging in action/decision/issue
			ids = rMgr.findId(pstuser, "TaskID='" + aid + "'");
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td class='listtext' width='30' valign='top' align='center'>");
			out.print("<a class='listlink' href='../blog/blog_task.jsp?projId=" + projIdS + "&aid=" + aid + "'>");
			out.print(ids.length + "</a>");
			out.println("</td>");
	
			if (!isOMFAPP) {
				// Project id
				out.print("<td colspan='2'>&nbsp;</td>");
				out.print("<td class='listtext' valign='top' align='center'>");
				if (projIdS != null)
				{
					out.print("<a class='listlink' href='../project/proj_action.jsp?projId=" + projIdS + "&aid=" + aid + "'>");
					out.print(projIdS + "</a>");
				}
				else
					out.print("-");
				out.println("</td>");
	
				if (isPRMAPP)
				{
					// Bug id
					out.print("<td colspan='2'>&nbsp;</td>");
					out.print("<td class='listtext' valign='top' align='center'>");
					if (bugIdS != null)
					{
						out.print("<a class='listlink' href='../bug/bug_update.jsp?bugId=" + bugIdS + "'>");
						out.print(bugIdS + "</a>");
					}
					else
						out.print("-");
					out.println("</td>");
				}
			}
	
			// ExpireDate
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td class='listtext_small' align='center' valign='top'>");
			out.print(df1.format(expireDate));
			out.println("</td>");
	
			// update status and delete action item
	
			// delete
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td width='35' class='plaintext' align='center' valign='top'>");
			out.print("<input type='checkbox' name='delete_" + aid + "'></td>");
	
			out.println("</tr>");
			out.println("<tr " + bgcolor + ">" + "<td colspan='26'><img src='../i/spacer.gif' height='10'></td></tr>");
		}
	out.print("</table>");
	
	}	// END if there is any AI

%>
	</td>
</tr>
<!-- End list of action items -->

<tr><td colspan="3"><img src="../i/spacer.gif" width="5" height="5"></td></tr>

<!-- List of Decision Records -->
<tr>
	<td>&nbsp;</td>
	<td colspan="2">

<%
	if (dsObjList.length > 0) {
		if (isOMFAPP)
			out.print(Util.showLabel(PrmMtgConstants.vlabel1OMF, PrmMtgConstants.vlabelLen1OMF, true));
		else
			out.print(Util.showLabel(PrmMtgConstants.vlabel1, PrmMtgConstants.vlabelLen1, true));

		even = false;
	
		for(int i = 0; i < dsObjList.length; i++)
		{	// the list of decision records for this meeting object
			obj = (action)dsObjList[i];
			aid = obj.getObjectId();
	
			subject		= (String)obj.getAttribute("Subject")[0];
			priority	= (String)obj.getAttribute("Priority")[0];
			createdDate	= (Date)obj.getAttribute("CreatedDate")[0];
			projIdS		= (String)obj.getAttribute("ProjectID")[0];
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
			out.print("<td class='plaintext' valign='top'>" + (i+1) + ". </td>");
			out.print("<td class='plaintext' valign='top'>");
			out.print("<a href='javascript:editAC(\""
				+ aid + "\", \"Decision\")'>" + subject + "</a>");
			out.println("</td></tr></table></td>");
	
			// Priority {HIGH, MEDIUM, LOW}
			dot = "../i/";
			if (priority.equals(action.PRI_HIGH)) {dot += "dot_red.gif";}
			else if (priority.equals(action.PRI_MED)) {dot += "dot_orange.gif";}
			else if (priority.equals(action.PRI_LOW)) {dot += "dot_yellow.gif";}
			else {dot += "dot_grey.gif";}
			out.print("<td colspan='3' class='listlink' align='center' valign='top'>");
			out.print("<img src='" + dot + "' title='" + priority + "'>");
			out.println("</td>");
	
			// @ECC041006 support blogging in action/decision/issue
			ids = rMgr.findId(pstuser, "TaskID='" + aid + "'");
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td class='listtext' width='30' valign='top' align='center'>");
			out.print("<a class='listlink' href='../blog/blog_task.jsp?projId=" + projIdS + "&aid=" + aid + "'>");
			out.print(ids.length + "</a>");
			out.println("</td>");
	
			if (!isOMFAPP) { // @AGQ090606
				// Project id
				out.print("<td colspan='2'>&nbsp;</td>");
				out.print("<td class='listtext' width='40' valign='top' align='center'>");
				if (projIdS != null)
				{
					out.print("<a class='listlink' href='../project/proj_action.jsp?projId=" + projIdS + "&aid=" + aid + "'>");
					out.print(projIdS + "</a>");
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
			}
	
			// CreatedDate
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td class='listtext_small' width='50' align='center' valign='top'>");
			out.print(df1.format(createdDate));
			out.println("</td>");
	
			// delete
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td width='35' class='plaintext' align='center'>");
			out.print("<input type='checkbox' name='delete_" + aid + "'></td>");
	
			out.println("</tr>");
			out.println("<tr " + bgcolor + ">" + "<td colspan='20'><img src='../i/spacer.gif' width='2' height='2'></td></tr>");
		}
		out.print("</table>");
	}	// END if there is any decision record

%>
	</td>
</tr>
<!-- End list of decision records -->

<tr><td colspan="3"><img src="../i/spacer.gif" width="5" height="5"></td></tr>

<%
	if (isPRMAPP) {
%>
<!-- List of Issues -->
<tr>
	<td>&nbsp;</td>
	<td colspan="2">

<%
	if (bgObjList.length > 0) {
		out.print(Util.showLabel(PrmMtgConstants.vlabel2, PrmMtgConstants.vlabelLen2, true));
	
		even = false;
	
		bug bObj;
	
		for(int i = 0; i < bgObjList.length; i++)
		{	// the list of issues for this meeting object
			bObj = (bug)bgObjList[i];
			aid = bObj.getObjectId();
	
			subject		= (String)bObj.getAttribute("Synopsis")[0];
			status		= (String)bObj.getAttribute("State")[0];
			priority	= (String)bObj.getAttribute("Priority")[0];
			createdDate	= (Date)bObj.getAttribute("CreatedDate")[0];
			projIdS		= (String)bObj.getAttribute("ProjectID")[0];
			ownerIdS	= (String)bObj.getAttribute("Creator")[0];
	
			if (even)
				bgcolor = Prm.DARK;
			else
				bgcolor = Prm.LIGHT;
			even = !even;
			out.print("<tr " + bgcolor + ">");
	
			// Subject
			s = (String)bObj.getAttribute("Type")[0];
			out.print("<td>&nbsp;</td>");
			out.print("<td valign='top'><table border='0'><tr>");
			out.print("<td class='plaintext' valign='top'>" + (i+1) + ". </td>");
			out.print("<td class='plaintext' valign='top'>");
			if (s.equals(bug.CLASS_ISSUE))
				out.print("<a href='javascript:editAC(\"" + aid + "\", \"Issue\")'>");
			else
				out.print("<a href='../bug/bug_update.jsp?bugId=" + aid + "'>");
			out.print(subject + "</a>");
			out.println("</td></tr></table></td>");
	
			// Submitter
			uObj = (user)uMgr.get(pstuser, Integer.parseInt(ownerIdS));
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td class='listtext' valign='top'>");
			out.print("<a class='listlink' href='../ep/ep1.jsp?uid=" + ownerIdS + "'>");
			out.print((String)uObj.getAttribute("FirstName")[0] + " " + ((String)uObj.getAttribute("LastName")[0]).charAt(0) + ".");
			out.print("</a>");
			out.print("</td>");
	
			// Status {OPEN, CLOSE}
			dot = "../i/";
			if (status.equals(bug.OPEN)) {dot += "dot_lightblue.gif";}
			else if (status.equals(bug.CLOSE)) {dot += "dot_green.gif";}
			else {dot += "dot_grey.gif";}
			out.print("<td colspan='3' class='listlink' align='center' valign='top'>");
			out.print("<img src='" + dot + "' title='" + status + "'>");
			out.println("</td>");
	
			// Priority {HIGH, MEDIUM, LOW}
			dot = "../i/";
			if (priority.equals(bug.PRI_HIGH)) {dot += "dot_red.gif";}
			else if (priority.equals(bug.PRI_MED)) {dot += "dot_orange.gif";}
			else if (priority.equals(bug.PRI_LOW)) {dot += "dot_yellow.gif";}
			else {dot += "dot_grey.gif";}
			out.print("<td colspan='3' class='listlink' align='center' valign='top'>");
			out.print("<img src='" + dot + "' title='" + priority + "'>");
			out.println("</td>");
	
			// @ECC041006 support blogging in action/decision/issue
			ids = rMgr.findId(pstuser, "TaskID='" + aid + "'");
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td class='listtext' width='30' valign='top' align='center'>");
			out.print("<a class='listlink' href='../blog/blog_task.jsp?projId=" + projIdS + "&bugId=" + aid + "'>");
			out.print(ids.length + "</a>");
			out.println("</td>");
	
			// Project id
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td class='listtext' width='40' valign='top' align='center'>");
			if (projIdS != null)
			{
				out.print("<a class='listlink' href='../project/proj_action.jsp?projId=" + projIdS + "&aid=" + aid + "'>");
				out.print(projIdS + "</a>");
			}
			else
				out.print("-");
			out.println("</td>");
	
			// My id
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td class='listtext' width='40' valign='top' align='center'>");
			out.print(aid + "</td>");
	
			// CreatedDate
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td class='listtext_small' width='50' align='center' valign='top'>");
			out.print(df1.format(createdDate));
			out.println("</td>");
	
			// delete
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td width='35' class='plaintext' align='center'>");
			out.print("<input type='checkbox' name='delete_" + aid + "'></td>");
	
			out.println("</tr>");
			out.println("<tr " + bgcolor + ">" + "<td colspan='26'><img src='../i/spacer.gif' width='2' height='2'></td></tr>");
		}
		out.print("</table>");
	}	// END: if there is any bug

%>
	</td>
</tr>
<%	} %>
<!-- End list of issues -->


<tr><td colspan="3"><img src="../i/spacer.gif" width="5" height="10"></td></tr>

<tr>
	<td>&nbsp;</td>
	<td colspan="2">
	<table width="100%" border='0' cellspacing='0' cellpadding='0'>
	<tr>
		<td class="tinytype" width="250">
	<%	if (aiObjList.length>0) {out.print("<font color='#555555'>(* Action item coordinator)</font>");}%>
		</td>
		<td align="right">
	<%	if (aiObjList.length>0 || dsObjList.length>0 || bgObjList.length>0) {%>
			<a href="javascript:deleteAC()" class="listlinkbold">>> Delete&nbsp;</a>
	<%	}%>
		</td>
	</tr>
	</table>
	</td>
</tr>

</form>

<%
	if (aiObjList.length>0 || dsObjList.length>0 || bgObjList.length>0) {
%>
<tr>
	<td>&nbsp;</td>
	<td colspan='2'><table class="tinytype">
	<tr>
		<td width='40' class="tinytype">Status:</td>
		<td class="tinytype">&nbsp;<img src="../i/dot_lightblue.gif" border="0"><%=action.OPEN%></td>
		<td class="tinytype">&nbsp;<img src="../i/dot_green.gif" border="0"><%=action.DONE%>/<%=bug.CLOSE%></td>
		<td class="tinytype">&nbsp;<img src="../i/dot_red.gif" border="0"><%=action.LATE%></td>
		<td class="tinytype">&nbsp;<img src="../i/dot_cancel.gif" border="0"><%=action.CANCEL%></td>
	</tr>
	<tr>
		<td class="tinytype">Priority:
		<td class="tinytype">&nbsp;<img src="../i/dot_red.gif" border="0"><%=action.PRI_HIGH%></td>
		<td class="tinytype">&nbsp;<img src="../i/dot_orange.gif" border="0"><%=action.PRI_MED%></td>
		<td class="tinytype">&nbsp;<img src="../i/dot_yellow.gif" border="0"><%=action.PRI_LOW%></td>
	</tr>
	</table></td>
</tr>
<%	} %>

<!-- END LIST OF ACTION / DECISION / ISSUE -->
<%	if (aiObjList.length>0 || dsObjList.length>0 || bgObjList.length>0) {
	}
	else {
		out.print("<tr><td><td>");
		out.print("<td colspan='2' class='ptextS2'>(There is no action item or decision record for this meeting)</td></tr>");
	}
	out.print("<tr><td colspan='3'><img src='../i/spacer.gif' width='5' height='20'></td></tr>");
%>

<tr>
	<td>&nbsp;</td>
	<td colspan="2">
	<p align="center">
		<input type="Button" class="button_medium" name="Submit" onClick="return setPageLocation('done');" value="Save & Close">
		&nbsp;
		<input type="Button" class="button_medium" value="  Cancel  " onclick="location='mtg_view.jsp?mid=<%=midS%>'">&nbsp;
	</p>
	</td>
</tr>

<tr><td colspan="3"><img src="../i/spacer.gif" width="5" height="3"></td></tr>


		<!-- End of Content Table -->
</table>
</td></tr>

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
