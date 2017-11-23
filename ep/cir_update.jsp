<%
//
//	Copyright (c) 2007, EGI Technologies, Co.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: cir_update.jsp
//	Author: ECC
//	Date:	10/15/07
//	Description: Create, delete, update circle.
//
//	Modification:
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
	////////////////////////////////////////////////////////
	String HOST = Util.getPropKey("pst", "PRM_HOST");

	PstUserAbstractObject me = pstuser;
	if (me instanceof PstGuest
		|| ((user)me).isCircleGuest())
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}

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

	int myUid = me.getObjectId();
	int chiefId = 0;

	String msg = request.getParameter("msg");

	townManager tnMgr	= townManager.getInstance();
	userManager uMgr	= userManager.getInstance();
	PstAbstractObject detailUser = uMgr.get(me, myUid);

	PstAbstractObject obj;
	Object [] availFriend = null;			// available friends
	user [] curTownMember = null;
	int selectedTownId = -1;
	String s = request.getParameter("townId");
	if (s != null) selectedTownId = Integer.parseInt(s);
	String selectedTownName = "";
	String desc = "";
	boolean isChief = false;
	String disabledS = "";
	String townType = "";
	int [] ids = null;
	String circleGuestURL = "";

	if (selectedTownId > 0)
	{
		// 0. check authority
		ids = uMgr.findId(me, "om_acctname='" + me.getObjectName()
				+ "' && Towns=" + selectedTownId);
		if (ids.length <=0)
		{
			response.sendRedirect("cir_update.jsp");
			return;
		}

		// 1. construct my friend's list
		int [] myFriendIdArr = null;
		Object [] objArr = detailUser.getAttribute("TeamMembers");
		if (objArr[0] != null)
		{
			myFriendIdArr = new int[objArr.length];
			for (int i=0; i<objArr.length; i++)
			{
				// need int array for comparison
				myFriendIdArr[i] = ((Integer)objArr[i]).intValue();
			}
		}
		Arrays.sort(myFriendIdArr);			// need this sort to merge delete below

		// 2. get the selected town members' list
		int [] curTownMemberIdArr = null;
		curTownMemberIdArr = uMgr.findId(me, "Towns=" + selectedTownId);
		Arrays.sort(curTownMemberIdArr);	// need this sort to merge delete below
		if (curTownMemberIdArr.length > 0)
			curTownMember = new user[curTownMemberIdArr.length];
		for (int i=0; i<curTownMemberIdArr.length; i++)
		{
			// save the current selected town members
			curTownMember[i] = (user)uMgr.get(me, curTownMemberIdArr[i]);
		}
		Util.sortUserArray(curTownMember, true);		// names in alpha order

		// 3. remove current town members from my friend's list
		ArrayList aList = new ArrayList();
		if (selectedTownId > 0)
		{
			for (int i=0; i<myFriendIdArr.length; i++)
			{
				for (int j=0; j<curTownMemberIdArr.length; j++)
				{
					if (myFriendIdArr[i] == curTownMemberIdArr[j])
					{
						// found
						myFriendIdArr[i] = -1;
						break;
					}
					else if (myFriendIdArr[i] < curTownMemberIdArr[j])
						break;		// in order compare: no match
				}
				if (myFriendIdArr[i] != -1) aList.add(uMgr.get(me, myFriendIdArr[i]));
			}
			availFriend = aList.toArray();
		}
		else
		{
			if (myFriendIdArr != null)
			{
				availFriend = new String[myFriendIdArr.length];
				for (int i=0; i<myFriendIdArr.length; i++)
				{
					availFriend[i] = uMgr.get(me, myFriendIdArr[i]);
				}
			}
		}
		if (availFriend != null)
			Util.sortUserArray(availFriend, true);

		// get the selectedTownName
		PstAbstractObject o = tnMgr.get(me, selectedTownId);
		selectedTownName = Util.stringToHTMLString((String)o.getAttribute("Name")[0]);
		s = (String)o.getAttribute("Chief")[0];
		chiefId = Integer.parseInt(s);
		if (s!=null && chiefId==myUid)
			isChief = true;
		if (!isAdmin && !isChief)
			disabledS = "disabled";

		townType = (String)o.getAttribute("Type")[0];
		if (townType == null) townType = "";

		// get description
		Object bTextObj = o.getAttribute("Description")[0];
		if (bTextObj != null)
			desc = new String((byte[])bTextObj);

		// ECC: email back the town member email addrs to System
		if (request.getParameter("email")!=null)
		{
			// send an email to System to get all email addr
			StringBuffer emailBuf = new StringBuffer();
			for (int i=0; i<curTownMember.length; i++)
				emailBuf.append(curTownMember[i].getAttribute("Email")[0]+", ");		// email list
			String from = Util.getPropKey("pst", "FROM");
			Util.sendMailAsyn(me, from, from, null, null, "Emails of " + selectedTownName, emailBuf.toString(), "alert.htm");
		}

		// circle guest info
		circleGuestURL = HOST + "/circle/"
			+ ((String)o.getAttribute("Name")[0])
			.replaceAll(" ", "").replaceAll("'", "").replaceAll("/", "");

	}	// END if selectedTownId > 0

	////////////////////////////////////////////////////////
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html lang="en">

<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../forms.jsp" flush="true"/>
<script language="JavaScript" src="../get-date.js"></script>
<script language="JavaScript" src="../date.js"></script>

<script language="JavaScript">
<!--
function fo()
{
	Form = document.newCircle;
	for (i=0;i < Form.length;i++)
	{
		if (Form.elements[i].type != "hidden")
		{
			Form.elements[i].focus();
			break;
		}
	}
	// @AGQ031006
	//sortSelect(document.getElementById("Select1"));
}

function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

function validation(op)
{
	var f = document.getElementById(op);	// get the form

	if (op == 'add')
	{
		if (f.addCircleName.value =='')
		{
			fixElement(f.addCircleName,
				"Please make sure that the NEW CIRCLE NAME field is properly completed.");
			return false;
		}

		var cirName = f.addCircleName.value;
		for (i=0;i<cirName.length;i++) {
			char = cirName.charAt(i);
			if (char == '\\') {
				fixElement(f.addCircleName,
					"NEW CIRCLE NAME cannot contain these characters: \n  \\");
				return false;
			}
		}
		return true;
	}

	if (op == 'update')
	{
		f = document.updateCircle;
		if ('<%=selectedTownId%>' == '-1')
		{
			fixElement(f.townId,
				"Please select a circle to be updated.");
			return false;
		}
		getall(f.members);
		return true;
	}

	if (op == 'changeType')
	{
		if ('<%=selectedTownId%>' == '-1')
		{
			f = document.getElementById('selectCircle');
			fixElement(f.townId,
				"Please select a circle to change its TYPE.");
			return false;
		}
		var e = updateCircle.Type;
		var typeS = null;
		for (var i=0; i<e.length; i++)
		{
			if (e[i].checked)
			{
				typeS = e[i].value;
				break;
			}
		}

		if (typeS==null)
		{
			alert("Please select a circle type before clicking the Save Type button.");
			return false;
		}
		updateCircle.op.value = op;
		return true;
	}

	if (op == 'changeName')
	{
		if ('<%=selectedTownId%>' == '-1')
		{
			f = document.getElementById('selectCircle');
			fixElement(f.townId,
				"Please select a circle to change its NAME.");
			return false;
		}
		f = document.getElementById('newName');
		var e = trim(f.value);
		if (e.length <= 0)
		{
			fixElement(f.townId,
				"Please enter the new name for the selected circle.");
			return false;
		}
		document.updateCircle.op.value = op;
		return true;
	}

	if (op == 'changeDesc')
	{
		if ('<%=selectedTownId%>' == '-1')
		{
			f = document.getElementById('selectCircle');
			fixElement(f.townId,
				"Please select a circle to update DESCRIPTION.");
			return false;
		}
		var e = document.getElementById('desc');
		e.value = trim(e.value);
		document.updateCircle.op.value = op;
		return true;
	}

	if (op == 'delete')
	{
		if (f.delCircleId.value =='0')
		{
			fixElement(f.delCircleId,
				"Please select a circle to be deleted.");
			return false;
		}
		return true;
	}

	if (op == 'uploadIcon')
	{
		if ('<%=selectedTownId%>' == '-1')
		{
			f = document.getElementById('selectCircle');
			fixElement(f.townId,
				"Please select a circle to update the ICON.");
			return false;
		}
		f = document.updateCircle;
		f.op.value = op;
		if (f.Picture.value == '')
		{
			fixElement(f.Picture,
				"Please click the Browse Button to select an image file as circle icon.");
			return false;
		}
		return true;
	}

	if (op == 'updateGuestPasswd')
	{
		if ('<%=selectedTownId%>' == '-1')
		{
			f = document.getElementById('selectCircle');
			fixElement(f.townId,
				"Please select a circle to update the Guest Password.");
			return false;
		}
		f = document.updateCircle;
		f.op.value = op;
		var e = f.GuestPasswd;
		e.value = trim(e.value);
		if (e.value.length > 15 ||
			e.value.length < 4) {
			fixElement(e,
				"Please enter a valid password.  A valid circle password is between 4 to 15 characters.");
			return false;
		}
		return true;
	}

	return false;
}

//-->
</script>

</head>

<title>Update Circle</title>
<body onLoad="fo();" bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
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
                	<td width="754" height="30" align="left" valign="bottom" class="head">
                	<b>Manage Circle</b>
					</td></tr>
	            </table>
	          </td>
	        </tr>
</table>
	        
<table width='90%' border='0' cellspacing='0' cellpadding='0'>
			<tr>
				<td width="100%">
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Network" />
				<jsp:param name="subCat" value="NewCircle" />
				<jsp:param name="role" value="<%=iRole%>" />
			</jsp:include>
<!-- End of Navigation Menu -->
				</td>
	        </tr>
		</table>
<!-- Content Table -->

<table width="90%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td width="20" height='20'>&nbsp;</td>
	<td></td>
	<td></td>
</tr>


<!-- ******************** Add New Circle ******************** -->

<tr>
	<td></td>
	<td class="title" colspan='2'>Add New Circle</td>
</tr>

<form name='newCircle' id='add' method='post' action='post_cirUpdate.jsp' enctype="multipart/form-data">
		<input type='hidden' name='op' value=''>
<tr>
	<td></td>
	<td width='300' class="plaintext_blue" valign='middle' height='35'>New Circle Name:</td>
	<td valign='middle'>
		<input class="formtext" type="text" name="addCircleName" size="60" >&nbsp;
		<input type="Submit" name="Submit1" class="button_medium" value='Add Circle' onclick="return validation('add');">
	</td>
</tr>
</form>

<tr><td colspan='3'><img src='../i/spacer.gif' height='20'></td></tr>

<%	if (msg != null)
	{
		out.print("<tr><td></td>");
		out.print("<td colspan='2' class='plaintext' style='color:");
		if (msg.startsWith("Done"))
			out.print("#00bb00");
		else
			out.print("#dd0000");
		out.print("'>" + msg + "</td></tr>");
	} %>

<!--  ******************** Update Circles ******************** -->
<tr>
	<td></td>
	<td colspan='2'><hr></td>
</tr>

<tr><td colspan='3'><img src='../i/spacer.gif' height='10'><a name='update'></a></td></tr>

<tr>
	<td></td>
	<td class="title" colspan='2'>Add/Remove Circle Members</td>
</tr>

<tr>
	<td></td>
	<td colspan='2' valign='middle' class='plaintext'>&nbsp;

<form name='selectCircle' id='selectCircle' method='post' action='cir_update.jsp'>
		<input type='hidden' name='op' value=''>
		<select class='formtext' name='townId' onChange='submit();'>
<%
		PstAbstractObject [] tnArr = null;
		PstAbstractObject selectedTownObj = null;
		if (isAdmin)
			ids = tnMgr.findId(me, "om_acctname='%'");
		else
		{
			Object [] oA = detailUser.getAttribute("Towns");
			if (oA[0] != null)
			{
				ids = new int[oA.length];
				for (int i=0; i<oA.length; i++)
					ids[i] = ((Integer)oA[i]).intValue();
			}
		}

		out.print("<option value='0'>-- select circle --</option>");
		if (ids != null)
		{
			tnArr = tnMgr.get(me, ids);
			Util.sortString(tnArr, "Name", true);
			for (int i=0; i<tnArr.length; i++)
			{
				int id = tnArr[i].getObjectId();
				out.print("<option value='" + id + "'");
				if (id == selectedTownId)
				{
					selectedTownObj = tnArr[i];
					out.print(" selected");
				}
				out.print(">" + (String)tnArr[i].getAttribute("Name")[0] + "</option>");
			}
		}
%>

</select>
</form>
	</td>
</tr>

<tr><td colspan='3'><img src='../i/spacer.gif' height='5'></td></tr>

<%
	// update chief
	if (selectedTownObj != null)
	{
		out.print("<form name='changeChief' method='post' action='post_cirUpdate.jsp' enctype='multipart/form-data'>");
		out.print("<input type='hidden' name='updateCircleId' value='" + selectedTownId + "'>");
		out.print("<input type='hidden' name='op' value='changeChief'>");
		out.print("<tr><td></td>");
		out.print("<td valign='baseline' class='plaintext_blue'>Owner:</td>");
		out.print("<td><select class='formtext' name='chief' " + disabledS + ">");
		out.print("<option value='0'>-- select circle owner --</option>");
		int id;
		for (int i=0; i<curTownMember.length; i++) {
			id = curTownMember[i].getObjectId();
			out.print("<option value='" + id + "' ");
			if (chiefId == id) out.print("selected ");
			out.print(">" + ((user)curTownMember[i]).getFullName() + "</option>");
		}
		out.print("</select>&nbsp;&nbsp;&nbsp;");
		out.print("<input type='button' class='button_medium' " + disabledS
					+ " onclick='submit();' value='Save Change'>");
		out.print("</form></td></tr>");
	}
%>

<form name='updateCircle' id='update' method='post' action='post_cirUpdate.jsp' enctype="multipart/form-data">
<input type='hidden' name='updateCircleId' value='<%=selectedTownId%>'>
<input type='hidden' name='op' value=''>
<tr>
	<td></td>
	<td colspan='2'>
		<table border="0" cellspacing="4" cellpadding="0">
		<tr>
<%
			out.print("<td class='plaintext'>");
			if (selectedTownId > 0)
				out.print("Select friends to add to circle</br>");
			out.print("<select class='formtext_fix' name='friends' multiple size='5'>");

			if (availFriend != null)
			for (int i=0; i<availFriend.length; i++)
			{
				if (availFriend[i] == null) continue;		// ignored
				out.print("<option value='" + ((PstUserAbstractObject)availFriend[i]).getObjectId() + "'");
				out.print(">" + ((user)availFriend[i]).getFullName() + "</option>");
			}
%>
			</select>
			</td>

			<td align="center" valign="middle">
				<input style='width:90px' type="button" class="button" name="add" value="&nbsp;&nbsp;&nbsp;Add &gt;&gt;&nbsp;&nbsp;" onClick="swapdata(this.form.friends,this.form.members)">
			<br><input style='width:90px' type="button" class="button" name="remove" value="<< Remove" onClick="swapdata(this.form.members,this.form.friends)">
			</td>


<%
			out.print("<td class='plaintext'>");
			if (selectedTownId > 0)
				out.print("Current and new circle members</br>");
			out.print("<select class='formtext_fix' name='members' multiple size='5'>");

			if (curTownMember!= null && curTownMember.length > 0)
			{
				for (int i=0; i < curTownMember.length; i++)
				{
					out.print("<option value='" +curTownMember[i].getObjectId()+ "'>" +curTownMember[i].getFullName()+ "</option>");
				}
			}
%>
				</select>
			</td>
<%
		// add a link to invite new friends to join a circle
		out.print("<td valign='bottom'><table><tr><td><img src='../i/bullet_tri.gif'></td>");
		out.print("<td><a class='listlink_big' href='../ep/add_contact.jsp?type=case2&action=invite");
		if (selectedTownId > 0)
			out.print("&tid=" + selectedTownId);
		out.print("'>Invite new friends to circle</a></td></tr></table></td>");
%>
		</tr>
		</table>
	</td>

</tr>

<tr><td colspan='3'><img src='../i/spacer.gif' height='5'></td></tr>

<tr>
	<td></td>
	<td colspan='2' class="10ptype" align="left">
		<img src='../i/spacer.gif' width='130' height='1' />
		<input style='width=100px' type="Button" value="Cancel" class="button_medium" onclick="history.back(-1)">&nbsp;
		<input style='width=150px' type="Submit" name="Submit2" class="button_medium" value="Save Circle Member" onclick="return validation('update');">
	</td>
</tr>

<tr><td colspan='3'><img src='../i/spacer.gif' height='20'></td></tr>

<tr>
	<td></td>
	<td class="plaintext_blue" valign='bottom' height='20'>Circle Type:</td>
	<td class='formtext' valign='top'>
<%
		out.print("<input type='radio' name='Type' value='" + town.TYPE_CIR_WORK + "' " + disabledS);
		if (townType.equals(town.TYPE_CIR_WORK)) out.print("checked"); out.print(">" + town.TYPE_CIR_WORK);
		out.print("<img src='../i/spacer.gif' width='10' />");

		out.print("<input type='radio' name='Type' value='" + town.TYPE_CIR_ALUMNI + "' " + disabledS);
		if (townType.equals(town.TYPE_CIR_ALUMNI)) out.print("checked"); out.print(">" + town.TYPE_CIR_ALUMNI);
		out.print("<img src='../i/spacer.gif' width='10' />");

		out.print("<input type='radio' name='Type' value='" + town.TYPE_CIR_SOCIAL + "' " + disabledS);
		if (townType.equals(town.TYPE_CIR_SOCIAL)) out.print("checked"); out.print(">" + town.TYPE_CIR_SOCIAL);
		out.print("<img src='../i/spacer.gif' width='10' />");

		out.print("<input type='radio' name='Type' value='" + town.TYPE_CIR_RELIGION + "' " + disabledS);
		if (townType.equals(town.TYPE_CIR_RELIGION)) out.print("checked"); out.print(">" + town.TYPE_CIR_RELIGION);
		out.print("<img src='../i/spacer.gif' width='10' />");

		out.print("<input type='radio' name='Type' value='" + town.TYPE_CIR_FAMILY + "' " + disabledS);
		if (townType.equals(town.TYPE_CIR_FAMILY)) out.print("checked"); out.print(">" + town.TYPE_CIR_FAMILY);
		out.print("<img src='../i/spacer.gif' width='65' height='1'/>");

		out.print("<input type='Submit' name='Submit0' class='button_medium' value='Save Type' onclick='return validation(\"changeType\");' " + disabledS + ">");
%>
	</td>
</tr>

<%

	if (isAdmin || isChief)
	{%>
<tr><td colspan='3'><img src='../i/spacer.gif' height='20'></td></tr>

<tr>
	<td></td>
	<td class="plaintext_blue" valign='middle' height='40'>Change Circle Name:</td>
	<td class='formtext'>
		<input class='formtext' type='text' name='newName' id='newName' size="40" value='<%=selectedTownName%>'>&nbsp;
		<input type="Submit" name="Submit4" class="button_medium" value='Save Name' onclick="return validation('changeName');">
	</td>
</tr>
<%	} %>

<tr><td colspan='3'><img src='../i/spacer.gif' height='20'></td></tr>

<tr>
	<td></td>
	<td class="plaintext_blue" valign='top' height='35'>Change Description:</td>
	<td class='formtext'>
		<textarea name='desc' id='desc' class='formtext' wrap='logical' rows='3' cols='60' style='padding:2px' <%=disabledS%>><%=desc%></textarea>&nbsp;
		<input type="Submit" name="Submit5" class="button_medium" value='Save Description' onclick="return validation('changeDesc');" <%=disabledS%>>
	</td>
</tr>

<tr><td colspan='3'><img src='../i/spacer.gif' height='20'></td></tr>

<tr>
	<td></td>
	<td class="plaintext_blue" height='35'>Upload Circle Icon:</td>
	<td class="formtext">
		<input type="file" name="Picture" size="30" value="" <%=disabledS%>>
		<input type="Submit" name="Submit6" class="button_medium" value='Upload Icon' onclick="return validation('uploadIcon');" <%=disabledS%>>
	</td>
</tr>

<tr><td colspan='3'><img src='../i/spacer.gif' height='20'></td></tr>

<tr>
	<td></td>
	<td class="plaintext_blue" height='35'>Update Guest Password:</td>
	<td class="formtext">
		<input type='password' name='GuestPasswd' size='20' value='' <%=disabledS%>>
		<input type="Submit" name="Submit7" class="button_medium" value='Save'
			onclick="return validation('updateGuestPasswd');" <%=disabledS%>><br>
		<span type='plaintext'>Guest Forum Website:
			<a href='<%=circleGuestURL%>'><%=circleGuestURL.replace("http://", "")%></span>
	</td>
</tr>

</form>

<tr><td colspan='3'><img src='../i/spacer.gif' height='20'></td></tr>


<!--  ******************** Remove Circles ******************** -->
<tr>
	<td></td>
	<td colspan='2'><hr></td>
</tr>

<tr><td colspan='3'><img src='../i/spacer.gif' height='20'></td></tr>

<tr>
	<td></td>
	<td class="title" colspan='2'>Delete Circle</td>
</tr>

<tr>
	<td></td>
	<td class="plaintext_blue" valign='middle' height='35'>Circle Name:</td>
	<td valign='middle'>
<form name='changeCircle' id='delete' method='post' action='post_cirUpdate.jsp' enctype="multipart/form-data">
		<input type='hidden' name='op' value=''>
		<select class='formtext' name='delCircleId'>
<%
		out.print("<option value='0'>-- select circle --</option>");
		if (tnArr != null)
		{
			Util.sortString(tnArr, "Name", true);
			for (int i=0; i<tnArr.length; i++)
			{
				int id = tnArr[i].getObjectId();
				if (!isAdmin)
				{
					// check delete authority: only Chief can delete
					s = (String)tnArr[i].getAttribute("Chief")[0];
					if (s==null || Integer.parseInt(s)!=myUid)
						continue;
				}
				out.print("<option value='" + id + "'");
				out.print(">" + (String)tnArr[i].getAttribute("Name")[0] + "</option>");
			}
		}

%>
		</select>&nbsp;
		<input type="Submit" name="Submit3" class="button_medium" value='Delete Circle' onclick="return validation('delete');">
</form>
	</td>
</tr>


<tr><td colspan='3'><img src='../i/spacer.gif' height='10'></td></tr>


		<!-- End of Content Table -->
		<!-- End of Main Tables -->

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
