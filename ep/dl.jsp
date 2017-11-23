<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2006, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: dl.jsp
//	Author: AGQ
//	Date:	03/01/06
//	Description: User list modifcation page
//
//	Modification:
//			@AGQ061706	Displays all contact list's information
//			@AGQ061806 	Handles validation for contact list
//
/////////////////////////////////////////////////////////////////////
//
// dl.jsp :
//

%>

<%@ page import = "util.*" %>
<%@ page import = "oct.omm.common.*" %>
<%@ page import = "oct.omm.client.*" %>
<%@ page import = "oct.omm.db.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />
<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	user curUser = (user) pstuser;
	String host = Util.getPropKey("pst", "PRM_HOST");
	String uid = request.getParameter("uid");
	String backPage = "../ep/dl.jsp";

	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ( (iRole & user.iROLE_ADMIN) > 0 )
		isAdmin = true;

	// to check if session is OMF or PRM
	boolean isCRAPP = false;
	boolean isOMFAPP = false;
	boolean isPRMAPP = false;
	String app = (String)session.getAttribute("app");
	if (app.equals("OMF"))
		isOMFAPP = true;
	else if (app.equals("CR"))
		isCRAPP = true;
	else if (app.equals("PRM"))
		isPRMAPP = true;
	
	// set up labels for CR/OMF
	String label1, label2;
	if (isOMFAPP) {label1="Circles & Friends"; label2="Add New Friends";}
	else {label1="Contacts & User Lists"; label2="Add New Contacts";}
	
	userManager uMgr = userManager.getInstance();
	int uidInt = 0;

	if ((uid == null) || (uid.equals("null")))
	{
		uidInt = curUser.getObjectId();
		uid = String.valueOf(curUser.getObjectId());
	}
	else
	{
		uidInt = Integer.parseInt(uid);
	}

	user detailUser = (user)uMgr.get(curUser, uidInt);

	int selectedTownId = -1;
	String s = request.getParameter("townId");
	if (s != null) selectedTownId = Integer.parseInt(s);

	String valueDLView = request.getParameter("selectedDLView");
	String valueDLEdit = request.getParameter("selectedDLEdit");
	String valueDLPick = request.getParameter("selectedDLPick");
	String [] selected = request.getParameterValues("selectedDLMem");
	String prevDlName = request.getParameter("dlName");
	String prevDlOwner = request.getParameter("dlOwner");
	String prevChangedTeam = request.getParameter("changedTeam");
	String prevChanges = request.getParameter("changes");
	boolean changedTeam = false;
	boolean changes = false;
	if (prevChangedTeam != null) 
		changedTeam = (prevChangedTeam.equalsIgnoreCase("true"))? true:false;
	if (prevChanges != null) 
		changes = (prevChanges.equalsIgnoreCase("true"))? true:false;
	user u = null;
	
	String uName = "";
	String disable = "";
	String disableName = "";
	String disableDelete = "return false;";
	int dlOwner = -1;
	String dlID = "none";
	String dlName = "";
	
	String dlProjectId = null;
	String prevName = null;
	dl dlObj = null;
	
	int value = (valueDLEdit != null)?dl.getId(valueDLEdit):-1;
	
	// Get related projects
	projectManager pjMgr = projectManager.getInstance();
	String projListS = "";
	String [] pjNames = pjMgr.findName(curUser, "TeamMembers=" + detailUser.getObjectId());
	for (int i=0; i<pjNames.length; i++)
	{
		if (pjNames[i] == null) break;
		if (projListS.length() > 0) projListS += ", ";
		projListS += pjNames[i];
	}

	// Get all related DLs
	dlManager dlMgr = dlManager.getInstance();
	int [] intArr;
	PstAbstractObject [] dlArr;
	if (isAdmin)
		dlArr = dlMgr.getAlldl(curUser);
	else {
		intArr = dlMgr.findId(curUser, dl.OWNER + "='" + uidInt +"'");
	 	dlArr = dlMgr.get(curUser, intArr);
	}
	Util.sortName(dlArr);
	
	// Set disable fields
	if(value != -1) {
		dlID = String.valueOf(value);
		dlObj = (dl)dlMgr.get(curUser, value);
		Object tempObj = dlObj.getAttribute(dl.OWNER)[0];
		if (tempObj != null)
			dlOwner = Integer.parseInt(tempObj.toString());
		dlProjectId = (String)dlObj.getAttribute("ProjectID")[0];
		if (dlProjectId != null && !isAdmin) 
			disable = " disabled='disabled'";
		else {
			disableDelete = "return true;";
		}
		
		disableName = " disabled='disabled'";	
	}
	
	if (changedTeam) {
		dlName = "";
		// New DL or init
		if (prevDlName != null && prevDlName.length() > 0) {
			dlName = prevDlName;
		}
		
		// Set prev info
		if (prevDlOwner != null) {
			int temp = Integer.parseInt(prevDlOwner);
			// Does not include 0 because we always want a user to be selected
			if (temp > 0) {
				dlOwner = temp;
			}
		}
	}
%>


<head>
<title><%=app%> User List</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../forms.jsp" flush="true"/>
<style type="text/css">
table {
/*	border: thin solid blue; */
}
</style>

<%
//	response.setHeader("Pragma", "No-Cache");
//	response.setDateHeader("Expires", 0);
//	response.setHeader("Cache-Control", "no-Cache");
%>
<script type="text/javascript">
var name="<%=dlName %>";

window.onload = function() {

}

function deleteDL() {
	if (newDL.selectedDLEdit.value == "0") {
		alert("Please select an existing User List to be deleted.");
		return;
	}
	var isSure = confirm("Delete this User List?");
	if(isSure) {
		document.getElementById("dlDelete").value = true;
		document.newDL.submit();
	}
}

// @AGQ061806
function removeContacts() {
	var actionTag = document.getElementsByName("action1");  // @SWS092906 IE doesn't take 'action' as tag name
	if (actionTag.length > 0) {
		actionTag[0].value = "contacts";
	}
	// See if there are checked items
	var contacts = document.getElementsByName("contacts");
	var checked = false;
	for (i=0;i<contacts.length;i++) {
		if (contacts[i].checked) {
			checked = true;
			break;
		}
	}
	if (checked) {
		return confirm("CHECKED CONTACTS will be REMOVED from this circle or friend list. Is this okay?");
	}
	else { 
		alert("Please CHECK all the CONTACTS to remove");
		return false;
	}
}
// @AGQ061806
function checkGuests(action) {
	var actionTag = document.getElementsByName("action1");
	if (actionTag.length > 0) {
		actionTag[0].value = "guests";
	}
	// See if there are checked items
	var contacts = document.getElementsByName("guests");
	var checked = false;
	for (i=0;i<contacts.length;i++) {
		if (contacts[i].checked) {
			checked = true;
			break;
		}
	}
	if (checked) {
		if (action == "remove")
			return confirm("CHECKED GUESTS will be REMOVED. Is this okay?");
		else
			return true;
	}
	else { 
		if (action == "remove")
			alert("Please CHECK all the GUESTS to remove");
		else
			alert("Please CHECK all the GUESTS to invite");
		return false;
	}
}
// @AGQ061806
function submitContacts() {
	var contactList = document.getElementsByName("contactList")[0];
	contactList.submit();
}

function inviteContacts() {
	var contactList = document.getElementsByName("contactList")[0];
	contactList.action = "add_contact.jsp?action=invite&type=case2";
	contactList.submit();
}

function validate() {
	var dlName = document.getElementById("dlName");
	var dlOwner = document.getElementById("dlOwner");
<% if (isAdmin) { %>
	var projId = document.getElementById("projectId");
	if (!isInt(projId.value)) {
		alert("Project Id: " + projId.value + 
			"\nis not an integer");
		return false;
	}
<% } %>
	if (containsBadChar(dlName.value)) {
		alert("New List Name: " +  dlName.value + 
			"\ncontains one of these bad characters: *!~#$%^|?`&\\=+()<>[]{}");
		return false;
	}
	else if (dlOwner.value == 0) {
		alert("Please select an owner");
		return false;
	}
	else {
		selectAll(document.getElementById("selectedDLMem"));
		document.getElementById("dlOwner").disabled = false;
		return true;
	}		
}

function changeTeam(reset)
{	
	var confirmed = true;
	// Changing team 
	if (!reset) {
		document.getElementById("changedTeam").value = true;
		selectAll(document.getElementById("selectedDLMem"));
		if (document.getElementById("dlName").value != name) 
			document.getElementById("changes").value = true;
	}
	// Changing user lists
	else {
		// Detect if there are changes
		if (document.getElementById("changes").value == 'true' || document.getElementById("dlName").value != name) {
			confirmed = confirm("Unsaved changes will be discarded. Continue?");
		}
		// Reset the information
		if (confirmed) {
			document.getElementById("changes").value = false;
			document.getElementById("changedTeam").value = false;
			document.getElementById("dlOwner").value = 0;
			document.getElementById("dlName").value = "";
			deSelectAll(document.getElementById("selectedDLMem"));
		}
		// Select Back to previous selected DL
		else {
			var dlName = document.getElementById("selectedDLEdit");
			var isFound = false;
			for (var i=0; i<dlName.options.length; i++) {
				if (dlName.options[i].value == "<%=valueDLEdit %>") {
					dlName.options[i].selected = true;
					isFound = true;
					break;
				}
			}
			if (!isFound) {
				dlName.options[0].selected = true;
			}
				
		}
	}
	
	if(confirmed) {
		document.newDL.action = location.href;
		document.newDL.submit();
	}
}

function selectAll(select) {
	var length = select.length;
	for(var i = 0; i < length; i++) {
		select.options[i].selected = true;
	}
}

function deSelectAll(select) {
	var length = select.length;
	for(var i=0; i<length; i++) {
		select.options[i].selected = false;
	}
}

function hasChanged() {
	document.getElementById("changes").value = true;
}
</script>

<style type="text/css">
.formtext {line-height:25px;}
</style>

</head>

<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" height="100%" border="1" cellspacing="0" cellpadding="0">

<tr>
	<td valign="top">

<table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr align="left" valign="top">
    <td width="100%">
	<jsp:include page="../head.jsp" flush="true"/>
</table>
<table width='90%' border="0" cellspacing="0" cellpadding="0">
  <tr align="left" valign="top">
    <td>
      <table width="100%" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td>
            <table width="100%" border="0" cellspacing="0" cellpadding="0">
              <tr>
                <td width="26" height="28"><a name="top">&nbsp;</a></td>
                <td height="28" align="left" valign="bottom" class="head">
				User List
				 </td>
              </tr>
            </table>
          </td>
        </tr>
        <tr>
				<td width="100%">
<!-- Navigation Menu -->
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="MyAccount" />
				<jsp:param name="subCat" value="DistList" />
				<jsp:param name="role" value="<%=iRole%>" />
			</jsp:include>
<!-- End of Navigation Menu -->
				</td>
		</tr>
		<tr>
		<td><table><tr><td width="20"></td><td>

<% if (isOMFAPP) { %>
<!-- start table for Contact List -->
<table bgcolor="#ffffff" border="0" cellpadding="0" cellspacing="0" width="100%">

<tr><td class="title" valign="bottom" colspan="2"><br>My Friends & Circles</td></tr>

<tr><td></td>
<td width='100%'>
	<table width='100%' border='0' cellspacing='0' cellpadding='0'><tr>
	<td align='left' valign='bottom'>
	<form method='post'>
		<select class='formtext' name='townId' onChange='submit();'>
<%
		townManager tnMgr = townManager.getInstance();
		int [] ids = null;
		if (isAdmin)
			ids = tnMgr.findId(pstuser, "om_acctname='%'");
		else
		{
			Object [] oA = pstuser.getAttribute("Towns");
			if (oA[0] != null)
			{
				ids = new int[oA.length];
				for (int i=0; i<oA.length; i++)
					ids[i] = ((Integer)oA[i]).intValue();
			}
		}
		int [] tnChief = null;							// store the chief Id
		int selectedTnIdx = -1;							// the idx of the town selected in the option list

		out.print("<option value='0'>-- show circle --</option>");
		out.print("<option value='-1'");
		if (selectedTownId == -1) out.print(" selected");
		out.print(">" + (isAdmin?"All":"My friends") + "</option>");
		if (ids != null)
		{
			tnChief = new int[ids.length];
			PstAbstractObject [] oArr = tnMgr.get(pstuser, ids);
			Util.sortString(oArr, "Name", true);
			for (int i=0; i<oArr.length; i++)
			{
				int id = oArr[i].getObjectId();
				s = (String)oArr[i].getAttribute("Chief")[0];
				if (s == null) tnChief[i] = 0;
				else tnChief[i] = Integer.parseInt(s);
				if (selectedTownId == id) selectedTnIdx = i;
				out.print("<option value='" + id + "'");
				if (id == selectedTownId)
					out.print(" selected");
				out.print(">" + (String)oArr[i].getAttribute("Name")[0] + "</option>");
			}
		}

%>
		</select>
	</form>
	</td>
	
		<td style="font-weight: bold; font-size: 12px;" valign='top'>
			<img src="../i/bullet_tri.gif">
			<a href="cir_update.jsp">New and Update Circles</a>
		</td>
	
	
<form action="post_contact.jsp" method="post" name="contactList">
<input type="hidden" name="action1" value="">
<input type="hidden" name="selectedTownId" value="<%=selectedTownId%>">
	<td style="font-weight: bold; font-size: 12px;" align='right' valign='bottom'>
		<a href="javascript: submitContacts();" onclick="javascript: return removeContacts();">&gt;&gt; Delete</a>
	</td>
	</tr></table>
<%
	int [] teamIdArray = null;
	String townName = "";
	if (selectedTownId > 0)
	{
		teamIdArray = uMgr.findId(detailUser, "Towns=" + selectedTownId);
		townName = PstManager.getNameById(detailUser, selectedTownId);
	}
	else if (selectedTownId == -1)
	{
		// display all
		if (isAdmin)
			teamIdArray = uMgr.findId(detailUser, "LastName='%'");
		else
		{
			Object [] oA = detailUser.getAttribute("TeamMembers");
			if (oA[0] != null)
			{
				teamIdArray = new int[oA.length];
				for (int i=0; i<oA.length; i++)
					teamIdArray[i] = ((Integer)oA[i]).intValue();
			}
			townName = "My Friends";
		}
	}
	else
		teamIdArray = null;
	
	PstAbstractObject [] pstArr = null;
	if (teamIdArray != null)
		pstArr = uMgr.get(detailUser, teamIdArray);

	
	String [] label = {"Full Name", "MeetWE Name", "Skype Name", "Delete"};
	int [] labelLength = { 146, 146, 146, 52 };
	out.println(Util.showLabel(label, labelLength, true));
	out.print("</table>");
  	out.print("<div class='scroll' style='height:150px; width:800px; padding:0px;'>");
	out.print("<table width='100%' border='0' cellpadding='0' cellspacing='0'>");
  	
	boolean isEven = false;
	String bgGrey = "style='background-color: #eeeeee'";
	String bgColor;
	String empty = "";
	int curUserId = 0;
	int totalMember = 0;
	if (teamIdArray != null)
	{
		Util.sortUserArray(pstArr, true);	// Sort by username
		totalMember = pstArr.length;		// need to subtract 1 in the case of My Friends
		for (int i=0; i<pstArr.length; i++)
		{
			u = (user) pstArr[i];
			curUserId = u.getObjectId();
			if (selectedTownId==-1 && curUserId==uidInt) {totalMember--; continue;} // Skip myself when counting my friends
			String fullName = u.getFullName();
			String screenName = u.getObjectName();
			String skypeName = (String) u.getAttribute(user.SKYPENAME)[0];
			if (screenName == null) screenName = "";
			if (skypeName == null) skypeName = "";
			
			if (isEven) bgColor = Prm.DARK;
			else bgColor = Prm.LIGHT;
			isEven = (!isEven);
			
			out.println	("<tr " + bgColor + ">");
			out.print	("<td colspan='2'></td>");
			out.println	("<td width='240' class='formtext'>"
					+ "<a href='ep1.jsp?uid=" + curUserId + "'>&nbsp;&nbsp;" +fullName+"</a></td>");
			out.print	("<td colspan='2'></td>");
			out.println	("   <td width='240' class='formtext'>"+screenName+"</td>");
			out.print	("<td colspan='2'></td>");
			out.println	("   <td width='240' class='formtext'>" +skypeName+ "</td>");
			out.print	("<td colspan='2'></td>");
			out.println	("   <td class='formtext'>");
			out.print	("<input type='checkbox' value='"+curUserId+"' name='contacts'");
			if (selectedTnIdx>=0 && tnChief[selectedTnIdx]!=uidInt && tnChief[selectedTnIdx]!=0 && curUserId!=uidInt)
				out.print(" disabled");
			out.print	("></td>");
			out.println	("</tr>");
		}
	}
	else
	{
		out.println("<tr><td></td><td colspan='10' class='formtext'>&nbsp;&nbsp;None </td></tr>");
	}
%>
      </table>
      </div>
      <div>
      <table width='100%'><tr>
      <td class='plaintext'><b>Total members in <font color='#00bb00'><%=townName%></font> circle = <%=totalMember %></b></td>
      <td align="right" style="font-weight: bold; font-size: 12px;"><a href="javascript: submitContacts();" onclick="javascript: return removeContacts();">&gt;&gt; Delete</a></td>
      </tr></table>
      </div>
   </td>
</tr>   

<tr><td colspan='2'><img src='../i/spacer.gif' height='25'/></td></tr>

<tr><td valign="bottom" colspan="2">
	<table border='0' width='100%' cellspacing='0' cellpadding='0'>
	<tr>
		<td width='550' class="title">My Guests</td>
		<td style="font-weight: bold; font-size: 12px;">
			<img src="../i/bullet_tri.gif" width="20" height="10">
			<a href="javascript: inviteContacts();" onclick="javascript: return checkGuests('invite');">Send MeetWE Invitation email to guests</a>
		</td>
	</tr>
	<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>
	</table>
	</td>
</tr>
<tr><td width="50"></td>
<td align="right">
   <span style="font-weight: bold; font-size: 12px;"><a href="javascript: submitContacts();" onclick="return checkGuests('remove');">&gt;&gt; Delete</a></span>
<%
	// Get Guest Emails
	int guestColumns = 1; // Number of columns to display names
	Object [] objArr = curUser.getAttribute(user.GUESTEMAILS);
	
	String [] hLabel2 = {"Email Address", "Delete"};
	int [] labelLength2 = { 438, 52 };
	out.println(Util.showLabel(hLabel2, labelLength2, true));
	out.print("</table>");
  	out.print("<div class='scroll' style='height:150px; width:800px; padding:0px;'>");
	out.print("<table width='100%' border='0' cellpadding='0' cellspacing='0'>");
	
	if (objArr[0] != null) {
		Arrays.sort(objArr); // Sort email string
		isEven = false;

		for (int i=0; i<objArr.length; i++) {			
			if (isEven) bgColor = Prm.DARK;
			else bgColor = Prm.LIGHT;
			isEven = (!isEven);

			out.println	("<tr " + bgColor + ">");
			out.print	("<td></td>");
			out.println	("<td class='formtext'>&nbsp;&nbsp;"+objArr[i]+"</td>");
			out.print	("<td></td>");
			out.print	("<td></td>");
			out.println	("<td class='formtext'><input type='checkbox' value='"+objArr[i]+"' name='guests'></td>");
			out.println	("</tr>");
		}
	}
	else {
		out.println("<tr><td></td><td colspan='4' class='formtext'>&nbsp;&nbsp;None </td></tr>");
	}
%>
    </table>
      </div>
      <span align="right" style="font-weight: bold; font-size: 12px;"><a href="javascript: submitContacts();" onclick="javascript: return checkGuests('remove');">&gt;&gt; Delete</a></span>
</td>
</tr>
</form>
<% }	// END if isOMFAPP

	if (!isOMFAPP)
	{
%>
<!-- start table for User List-->
<form action="post_dl.jsp" method="post" name="newDL" onSubmit="return validate()">
<input type="hidden" name="dlID" id="dlID" value="<%=dlID %>" />
<input type="hidden" name="dlDelete" id="dlDelete" value="false" />
<input type="hidden" name="changes" id="changes" value="<%=changes %>" />
<input type="hidden" name="changedTeam" id="changedTeam" value="false" />
<%
if (isAdmin) {
	out.println("<input type='hidden' name='isAdmin' id='isAdmin' value='true' />");
}
%>

<table bgcolor="#ffffff" border="0" cellpadding="4" cellspacing="2" width="100%">

<!-- View User List -->
<tr><td class="title" valign="bottom" colspan="2"><br>View User List</td></tr>
<!-- List Name -->
<tr>
	<td class="td_field_bg" width="120"><strong>List Name</strong></td>
	<td class="td_value_bg" width='1000'>
		<select class="formtext" name="selectedDLView" id="selectedDLView" onchange="changeTeam(false);">
			<option value="0">- Select List -</option>
<%
	int valueView = (valueDLView != null)?dl.getId(valueDLView):-1;
	// get all related Lists
	PstAbstractObject [] dlArrView = dlMgr.getDLs(curUser);
	Util.sortName(dlArrView);
	
	// display Lists to select
	prevName = null;
	for(int i = 0; i < dlArrView.length; i++) {
		dl curDl = (dl)dlArrView[i];		
		String curName = curDl.getObjectName();
		if(prevName != null) {
			if(!prevName.equalsIgnoreCase(curName)) {
				out.print("<option value='" + dl.DLESCAPESTR + curDl.getObjectId() + "'");
				if (curDl.getObjectId() == valueView)
					out.print(" selected=selected");
				out.println(">&nbsp;" + curName + "</option>");
			}
		}
		else {
			out.print("<option value='" + dl.DLESCAPESTR + curDl.getObjectId() + "'");
			if (curDl.getObjectId() == valueView)
				out.print(" selected=selected");
			out.println(">&nbsp;" + curName + "</option>");
		}		
		prevName = curName;
	}
%>

		</select>
	</td>
</tr>
<!-- List Owner -->
<%
	dl dlObjView = null;
	if (!isOMFAPP) {
		if (valueView != -1) {
			try {
				dlObjView = (dl)dlMgr.get(curUser, valueView);
				Object dlOwnerView = dlObjView.getAttribute(dl.OWNER)[0];
				if (dlOwnerView != null) {
					int ownerId = Integer.parseInt(dlOwnerView.toString());
					u = (user)uMgr.get(curUser, ownerId);
					uName = u.getFullName();
				}
			} catch (Exception e) {
				
			}
		}

%>
		<tr bgcolor="#ffffff">
		<td class="td_field_bg" width="160">List Owner</td>
		<td class="td_value_bg" style="font-weight: bold; font-size: 12px; color: rgb(221, 0, 0);">&nbsp;<%=uName %></td>
		</tr>
<%	} %>		
<!-- List Members -->
<tr>
		<td class="td_field_bg"><strong>List Members</strong></td>
		<td class="td_value_bg">
		<!-- Managed Pesonnel -->

		<table border="0" cellpadding="0" cellspacing="4">
		<tr>
			<td bgcolor="#ffffff">
			<select class="formtext_fix" name="selectedMem" id="selectedMem" multiple="multiple" size="5">

<%
	//Display the users in the currently selected value
	if (valueView != -1) {
		try {
			dlObjView = (dl)dlMgr.get(curUser, valueView);		
			ArrayList arrList = (ArrayList) dlObjView.getUserIds(curUser, true);
			// Remove Duplicates
			arrList = new ArrayList(new TreeSet(arrList));
			if (arrList != null && arrList.size() > 0) {
				Util.sortExUserList(curUser, arrList);
				for (int i=0; i<arrList.size(); i++) {
					u = (user) arrList.get(i);
					uName = u.getFullName();
					out.println("<option value='" +u.getObjectId()+ "'>&nbsp;" +uName+ "</option>");				
				}
			}
		} catch (PmpException e) {
			// Cannot find List
		}	
	}
%>
			</select>
			</td>

			<td class="td_value_bg" align="center" valign="middle">
			</td>
			<td bgcolor="#ffffff">
			</td>
		</tr>
		</table>
</td>
</tr>


<!-- End of List Members -->
<!-- End of Alert -->



<!-- New/Edit User List -->
<tr><td class="title" valign="bottom" colspan="2"><br>New/Edit User List</td>
</tr>

<!-- Select List -->
<tr>
	<td class="td_field_bg" width="120"><strong>List Name</strong></td>
	<td class="td_value_bg">
		<select class="formtext" name="selectedDLEdit" id="selectedDLEdit" onchange="changeTeam(true);">
			<option value="0">- Select List -</option>
<%
	
	// display Lists to select
	prevName = null;
	for(int i = 0; i < dlArr.length; i++) {
		dl curDl = (dl)dlArr[i];		
		String curName = curDl.getObjectName();
		if(prevName != null) {
			if(!prevName.equalsIgnoreCase(curName)) {
				out.print("<option value='" + dl.DLESCAPESTR + curDl.getObjectId() + "'");
				if (curDl.getObjectId() == value)
					out.print(" selected=selected");
				out.println(">&nbsp;" + curName + "</option>");
			}
		}
		else {
			out.print("<option value='" + dl.DLESCAPESTR + curDl.getObjectId() + "'");
			if (curDl.getObjectId() == value)
				out.print(" selected=selected");
			out.println(">&nbsp;" + curName + "</option>");
		}		
		prevName = curName;
	}
%>

		</select>
	</td>
</tr>
<!-- New List Name -->
		<tr bgcolor="#ffffff">
		<td class="td_field_bg" width="160">New List Name</td>
		<td class="td_value_bg">
			<input type="text" class="formtext" size="40" name="dlName" id="dlName"<%=disableName%> value="<%=dlName%>" /></td>
		</tr>
<%	if (!isOMFAPP || isAdmin) { %>		
<!-- List ID -->
		<tr bgcolor="#ffffff">
		<td class="td_field_bg" width="160">List ID</td>
		<td class="td_value_bg" style="font-weight: bold; font-size: 12px; color: rgb(221, 0, 0);">&nbsp;<%=dlID %></td>
		</tr>
<% 
		if (isAdmin) {
			String projectId = "";
			if (dlObj != null) {
				Object obj = dlObj.getAttribute(dl.PROJECTID)[0];
				if (obj != null)
					projectId = obj.toString();
			}
			// TODO: handle onchange event
%>
	<!-- List Project ID -->
			<tr bgcolor="#ffffff">
			<td class="td_field_bg" width="160">List Project ID</td>
			<td class="td_value_bg">
				<input type="text" class="formtext" size="40" name="projectId" id="projectId" value="<%=projectId %>" />
			</td>
			</tr>
<%
		}
	} 
%>	
<%	if (!isOMFAPP || isAdmin) { %>
<!-- List Owner -->
		<tr bgcolor="#ffffff">
		<td class="td_field_bg" width="160">* List Owner</td>
		<td class="td_value_bg">
		<select class="formtext" name="dlOwner" onchange="hasChanged()" id="dlOwner"<%=disable %>>
			<option value='0'>- Select Owner -</option>
<%
	// Admin can select any user to edit
	if (isAdmin) {
		PstAbstractObject [] userObj = uMgr.getAlluser(curUser);
		if (userObj[0] != null || userObj.length > 0) {
			Util.sortUserArray(userObj);;
			for (int i=0; i<userObj.length; i++) {
				u = (user)userObj[i];
				if (u.getAttribute("FirstName")[0] == null) continue;
				uName = u.getFullName();
				out.print("<option value='" + u.getObjectId() + "'");
				if (u.getObjectId() == dlOwner)
					out.println(" selected='selected'");
				out.println(">" + uName + "</option>");
			}
		}
	}
	// Cannot change Owner, the owner of this list is the project owner
	else if (dlProjectId != null) {
		try {
			u = (user)uMgr.get(curUser, dlOwner);
			uName = u.getFullName();
			out.println("<option value='" + dlOwner + "' selected='selected'>" + uName + "</option>");
		} catch (PmpException e) {
			// cannot find owner, this should not happen
		}
	}
	// Display all the List Members inside List Obj
	else if (dlObj != null) {
		Object [] objArr = dlObj.getAttribute("TeamMembers");
		if (objArr[0] != null) {
			PstAbstractObject [] userObj = uMgr.get(curUser, objArr);
			Util.sortUserArray(userObj);
			for (int i=0; i<userObj.length; i++) {
				u = (user)userObj[i];
				uName = u.getFullName();
				out.print("<option value='" + u.getObjectId() + "'");
				if (u.getObjectId() == dlOwner)
					out.println(" selected='selected'");
				out.println(">" + uName + "</option>");
			}
		}
	}
	// New Owner
	else {
		uName = detailUser.getFullName();
		out.println("<option value='" + uidInt + "' selected='selected'>" + uName + "</option>");
	}
%>

		</select>
		</td>
		</tr>
<%	}
	else {
		out.println("<input type='hidden' name='dlOwner' id='dlOwner' value='"+ uidInt +"'>");
	}
%>
<%	// @AGQ081806
	PstAbstractObject [] otherUArr = null;
	PstAbstractObject [] defaultUArr = null;
	Object [] otherTeamMem = null;
	
	if (!isOMFAPP) {
%>	
<!-- List Default Members -->
<tr>
		<td class="td_field_bg"><strong>List Default Members </strong></td>
		<td class="td_value_bg">
		<!-- Managed Pesonnel -->

		<table border="0" cellpadding="0" cellspacing="4">
		<tr>
			<td bgcolor="#ffffff">
			<select class="formtext_fix" name="defaultDLMem" id="defaultDLMem" multiple="multiple" size="5">
<%	} %>			
<%
	if (dlObj != null) {
		try {		
	    	Object [] allTeamMem = dlObj.getAllTeamMembers(curUser);
	    	Object [] defaultTeamMem = (Object[])allTeamMem[0];
	    	// Show current List's teamMember
	    	otherTeamMem = (Object[])allTeamMem[1];
	    	
	    	if (defaultTeamMem[0] != null && !isOMFAPP) {
	    		defaultUArr = uMgr.get(curUser, defaultTeamMem);
	    		if (defaultUArr[0] != null) {
					Util.sortUserArray(defaultUArr);
					for (int i=0; i<defaultUArr.length; i++) {
						u = (user)defaultUArr[i];
						uName = u.getFullName();
						out.println("<option value='" +u.getObjectId()+ "'>&nbsp;" +uName+ "</option>");
					}
				}
	    	}
		} catch (PmpException e) {
			// Cannot find List
		}	
	}
	
	// Restore previous selected list if there was one
	if (changedTeam) {
		otherTeamMem = null;
		if (selected != null) {
			otherTeamMem = new Object[selected.length];
			for (int i=0; i<selected.length; i++)
				otherTeamMem[i] = Integer.valueOf(selected[i]);
		}
	}
	if (otherTeamMem != null && otherTeamMem.length > 0 && otherTeamMem[0] != null) {
		otherUArr = uMgr.get(curUser, otherTeamMem);
		if (otherUArr[0] != null) 
			Util.sortUserArray(otherUArr);	
	}
%>
<%	if (!isOMFAPP) { %>
			</select>
			</td>

			<td class="td_value_bg" align="center" valign="middle">
			</td>
			<td bgcolor="#ffffff"></td>
		</tr>
		</table>
</td>
</tr>

<%	} %>
<!-- End of List Default Members -->

<!-- Add/Remove List Members -->
<tr>
		<td class="td_field_bg"><strong>Add/Remove List Members </strong></td>
		<td class="td_value_bg">
		<!-- Managed Pesonnel -->

		<table border="0" cellpadding="0" cellspacing="4">

<!-- Selected List -->
			<tr>
			<td colspan="3">
			<select class="formtext" name="selectedDLPick" id="selectedDLPick" onchange="changeTeam(false)">
<%	// @AGQ081806
	if (!isOMFAPP) { %>			
			<option value="-2">- Select Members -</option>
<%	} %>
<%
	dlArr = dlMgr.getDLs(curUser);
	Util.sortName(dlArr);
	value = (valueDLPick != null)?dl.getId(valueDLPick):-1;
	
	int tempValue = 0;
	if (value == -1) {
		if(valueDLPick != null) 
			tempValue = Integer.parseInt(valueDLPick);
	}
	
	out.print("<option value='-1'");
	if (tempValue == -1)
		out.println(" selected='selected'");
	if (!isOMFAPP)
		out.println(">&nbsp;All&nbsp;</option>");
	else {
		if (tempValue == 0) tempValue = -1;
		out.println(">&nbsp;Contacts&nbsp;</option>");
	}

	
	// display Lists to select
	prevName = null;
	for(int i = 0; i < dlArr.length && !isOMFAPP; i++) {
		dl curDl = (dl)dlArr[i];		
		String curName = curDl.getObjectName();
		if(prevName != null) {
			if(!prevName.equalsIgnoreCase(curName)) {
				out.print("<option value='" + dl.DLESCAPESTR + curDl.getObjectId() + "'");
				if (curDl.getObjectId() == value)
					out.print(" selected=selected");
				out.println(">&nbsp;" + curName + "</option>");
			}
		}
		else {
			out.print("<option value='" + dl.DLESCAPESTR + curDl.getObjectId() + "'");
			if (curDl.getObjectId() == value)
				out.print(" selected=selected");
			out.println(">&nbsp;" + curName + "</option>");
		}		
		prevName = curName;
	}
%>			
			</select>
			</td>
			</tr>
<!-- Select List Members -->
			<tr><td>
			<select class="formtext_fix" name="selectDLMem" id="selectDLMem" multiple="multiple" size="5">

<%	
	//Display the users in the currently selected value
	if (value > -1) {
		try {
			dlObj = (dl)dlMgr.get(curUser, value);		
			ArrayList arrList = (ArrayList) dlObj.getUserIds(curUser, true);
			// Remove Duplicates between List
			arrList = new ArrayList(new TreeSet(arrList));
			if (arrList != null && arrList.size() > 0) {
				Util.sortExUserList(curUser, arrList);
				// Remove Duplicate between Default
				dlMgr.removeDuplicateInt(defaultUArr, arrList);
				dlMgr.removeDuplicateInt(otherUArr, arrList);
				for (int i=0; i<arrList.size(); i++) {
					if (arrList.get(i) == null) continue;
					u = (user) arrList.get(i);
					uName = u.getFullName();
					out.println("<option value='" +u.getObjectId()+ "'>&nbsp;" +uName+ "</option>");				
				}
			}
		} catch (PmpException e) {
			// Cannot find List
		}	
	}
	else if (tempValue == -1) {
		PstAbstractObject [] userArr = null;
		// @AGQ081806
		if (!isOMFAPP)
			userArr = uMgr.getAlluser(curUser);
		else {
			Object [] objArr = curUser.getAttribute(user.TEAMMEMBERS);
			if (objArr[0] != null)
				userArr = uMgr.get(curUser, objArr);
			else
				userArr = null;
		}
		if (userArr != null && userArr[0] != null) {
			Util.sortUserArray(userArr);
			dlMgr.removeDuplicateInt(defaultUArr, userArr);
			dlMgr.removeDuplicateInt(otherUArr, userArr);
			Object nullName;
			for (int i=0; i<userArr.length; i++) {
				if (userArr[i] == null) continue;
				u = (user)userArr[i];
				nullName = u.getAttribute("FirstName")[0];
				// Only happens when getting all users	
				if (nullName == null) continue;
				uName = u.getFullName();
				out.println("<option value='" +u.getObjectId()+ "'>&nbsp;" +uName+ "</option>");
			}
		}
	}
%>
			</select>
			</td>

			<td class="td_value_bg" align="center" valign="middle">
				<input class="button" name="add" value="&nbsp;&nbsp;&nbsp;Add &gt;&gt;&nbsp;&nbsp;" onclick="javascript: hasChanged(); swapdata(document.getElementById('selectDLMem'),document.getElementById('selectedDLMem'));" type="button">
			<br><input class="button" name="remove" value="&lt;&lt; Remove" onclick="javascript: hasChanged(); swapdata(document.getElementById('selectedDLMem'),document.getElementById('selectDLMem'));" type="button">
			</td>
<!-- Selected List Members -->
			<td>
				<select class="formtext_fix" name="selectedDLMem" id="selectedDLMem" multiple="multiple" size="5">
<%
	if (otherUArr != null && otherUArr[0] != null) {
		dlMgr.removeDuplicateInt(defaultUArr, otherUArr);
		for (int i=0; i<otherUArr.length; i++) {
			if (otherUArr[i] == null) continue;
			u = (user)otherUArr[i];
			uName = u.getFullName();
			out.println("<option value='" +u.getObjectId()+ "'>&nbsp;" +uName+ "</option>");
		}
	}	
%>
				</select>

			</td>
		</tr>
		</table>
</td>
</tr>


<tr>
<td colspan="2">
<div align="center">
	<input type='button' class='button_medium' value='Submit' onclick='if (validate()) submit();'>
	<img src='../i/spacer.gif' width='30'/>
	<input type='button' class='button_medium' value='Delete' onclick='deleteDL();'>
	<input type='button' class='button_medium' value='Cancel' onclick='location.href="ep_home.jsp";'>

</div>
</td>
</tr>

<!-- End of Add/Remove List Members -->
<!-- End of New/Edit User List -->

</form>

<%	}	// END if !isOMFAPP %>

</table>
</td></tr>
</table>
<!-- end table -->
</td>
</tr>

<tr>
	<td valign="bottom">
		<jsp:include page="../foot.jsp" flush="true"/>
	</td>
</tr>
</table>
</td>
</tr>
</table>


</body>
</html>
