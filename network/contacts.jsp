<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>

<%
////////////////////////////////////////////////////
//	Copyright (c) 2008, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	contacts.jsp
//	Author:	ECC
//	Date:	12/01/08
//	Description:
//		A social networking page to manage and prioritize personal contacts.
//	Modification:
//
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	PstUserAbstractObject me = pstuser;
	if (me instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	if (((user)me).isCircleGuest()) {
		response.sendRedirect("../ep/my_page.jsp");
		return;
	}
	String HOST = Util.getPropKey("pst", "PRM_HOST");

	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if (iRole > 0)
	{
		if ((iRole & user.iROLE_ADMIN) > 0)
			isAdmin = true;
	}
	String s;

	userManager uMgr = userManager.getInstance();
	townManager tMgr = townManager.getInstance();

	int myUid = me.getObjectId();
	user detailUser = (user)uMgr.get(me, myUid);

	// construct myFriends hash for comparison later
	Hashtable hsFriends = new Hashtable();
	Object [] oA = detailUser.getAttribute("TeamMembers");
	for (int i=0; i<oA.length; i++)
	{
		if (oA[i] == null) break;
		hsFriends.put(((Integer)oA[i]).toString(), "");
	}

	// construct the Hash for contact type
	Hashtable hsWork, hsAlumni, hsSocial, hsReligion, hsFamily;
	Hashtable hsHigh, hsMed, hsLow;
	hsWork = hsAlumni = hsSocial = hsReligion = hsFamily = hsHigh = hsMed = hsLow = null;
	Object bObj = detailUser.getAttribute("ContactType")[0];
	String bStr = (bObj==null)?"":new String((byte[])bObj);

	hsWork = Util3.fillHash(bStr, "work");
	hsAlumni = Util3.fillHash(bStr, "alumni");
	hsSocial = Util3.fillHash(bStr, "social");
	hsReligion = Util3.fillHash(bStr, "religion");
	hsFamily = Util3.fillHash(bStr, "family");

	hsHigh = Util3.fillHash(bStr, "high");
	hsMed  = Util3.fillHash(bStr, "medium");
	hsLow  = Util3.fillHash(bStr, "low");

	// display My Friends or Circle
	int selectedCirId = 0;
	if ((s = request.getParameter("cId")) != null)
		selectedCirId = Integer.parseInt(s);

	// sort
	String sortby = request.getParameter("sb");
	String bgcl = "bgcolor='#6699cc'";
	String srcl = "bgcolor='#66cc99'";

	// display a certain member details
	int showUid = 0;
	if ((s = request.getParameter("uid")) != null)
		showUid = Integer.parseInt(s);

	// user selected circle to display members to intro a friend
	int introCirId = 0;
	boolean bSelectedIntroCir = false;
	if ((s = request.getParameter("IntroCir")) != null)
	{
		bSelectedIntroCir = true;
		introCirId = Integer.parseInt(s);
	}
%>


<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../forms.jsp" flush="true"/>

<script language="JavaScript">
<!--
var bUpdated = false;
function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

function validate()
{
	if (!bUpdated)
	{
		alert("Please use the Checkbox and/or Radio Buttons to make changes to the contact list before clicking the UPDATE button.");
		return false;
	}
	return;
}

function updated(id)
{
	var e = document.getElementById("update_" + id);
	e.checked = true;
	bUpdated = true;
}

function sort(ty)
{
	// 0=name; 1=category; 2=priority
	var str = "";
	if (ty == 0) str = "fn";
	else if (ty == 1) str = "ca";
	else if (ty == 2) str = "pr";

	var queryStr = "";
	var fullURL = parent.document.URL;
	var idx;
	if ((idx = fullURL.indexOf("#")) != -1)
		fullURL = fullURL.substring(0, idx);			// remove "#"
	if ((idx = fullURL.indexOf("?")) != -1)
		queryStr = fullURL.substring(idx);				// include the "?"
	else
	{
		location = "contacts.jsp?sb=" + str;
		return;
	}
	if ((idx = queryStr.indexOf("&sb")) != -1)
		queryStr = queryStr.substring(0, idx);
	location = "contacts.jsp" + queryStr + "&sb=" + str;
	return;
}

function showMem(uid)
{
	var fullURL = removeParam(parent.document.URL, "uid");
	fullURL = removeParam(fullURL, "IntroCir");
	if (fullURL.indexOf("?") == -1)
		fullURL += "?";
	else
		fullURL += "&";
	location = fullURL + "uid=" + uid + "#" + uid;
	return;
}

function closeInfo()
{
	var fullURL = parent.document.URL;
	var idx = fullURL.indexOf("uid");
	var loc = fullURL.substring(0, idx);
	if ((idx = fullURL.indexOf("&", idx)) != -1)
		loc += fullURL.substring(idx+1);
	else
		loc = loc.substring(0, loc.length-1);
	location = loc;
	return;
}

function displayOptPanel(panel)
{
	// toggle
	var toggle = false;
	if (panel == null)
	{
		panel = "reqPanel";
		toggle = true;
	}

	var e = document.getElementById(panel);
	if (!toggle)
	{
		// just display
		e.style.display = "block";
	}
	else
	{
		if (e.style.display == "block")
			e.style.display = "none";
		else
		{
			e.style.display = "block";
			updateContact.optMsg.focus();
		}
	}
}

function closeOptPanel()
{
	var f = document.updateContact;
	f.introFriend.value = "";			// reset

	var e = document.getElementById("introPanel");
	e.style.display = "none";
	e = document.getElementById("reqPanel");
	e.style.display = "none";
}

function requestFriend(uid)
{
	// this takes care of two requests, determined by the value of updateContact.introFriend
	// 1. send request to make friend
	// 2. send intro friend event
	var f = document.updateContact;
	f.reqFriend.value = "" + uid;

	if (<%=bSelectedIntroCir%>==true)
		f.introFriend.value = "true";			// need this be set in the post page
	if (f.introFriend.value == "true")
		getall(f.IntroFriends);					// introduce a friend to others

	f.backPage.value = removeParam(parent.document.URL, "IntroCir");
	f.submit();
}

function removeFriend(uid)
{
	// bidirectionally remove & block this friend
	// code from ep_circles.jsp for block/remove
	if (!confirm("Are you sure you want to remove and block this person from your Friend's list?"))
		return;

	var f = document.updateContact;
	f.block.value = "" + uid;
	f.backPage.value = parent.document.URL;
	f.submit();
}

function introFriend()
{
	// display panel to allow introduce this friend to others
	var f = document.updateContact;
	if (f.introFriend.value == "true")
	{
		closeOptPanel();
		f.introFriend.value = "";			// toggle intro friend panel
		return;
	}

	f.introFriend.value = "true";
	displayOptPanel("introPanel");
	displayOptPanel("reqPanel");
	return;
}

function getIntroCircle()
{
	// selected a new circle to intro a friend to, display the members of the circle for selection
	var f = document.updateContact;
	var ic = f.IntroCir.value;			// circle Id

	var loc = removeParam(parent.document.URL, "IntroCir");
	var idx = loc.indexOf("?");
	loc = loc.substring(0, idx+1) + "IntroCir=" + ic + "&" + loc.substring(idx+1);
	location = loc;
}

function removeParam(locStr, par)
{
	var parS = par + "=";
	var fullURL = locStr;
	var idx1, idx2;
	if ((idx1 = fullURL.indexOf("?")) == -1)
		return fullURL;							// no parameter at all

	var prefix = fullURL.substring(0, idx1+1);	// remember contacts.jsp?

	fullURL = fullURL.substring(idx1+1);		// only params, ignore "contacts.jsp?"
	idx1 = fullURL.indexOf(parS);
	if (idx1 == -1)
		return parent.document.URL;				// par not found
	idx2 = fullURL.indexOf("&", idx1);
	if (idx2 == -1)
		fullURL = fullURL.substring(0, idx1);
	else
		fullURL = fullURL.substring(0, idx1) + fullURL.substring(idx2+1);
	if (fullURL.charAt(0) == '&')
		fullURL = fullURL.substring(1);
	if (fullURL.charAt(fullURL.length-1) == '&')
		fullURL = fullURL.substring(0, fullURL.length-1);

	if (fullURL.length==0)
		fullURL = prefix.substring(0, prefix.length-1);
	else
		fullURL = prefix + fullURL;

	return fullURL;
}
//-->
</script>

<title>
	OMF Contact Management
</title>

<style type="text/css">
.wrap_table {WORD-BREAK:BREAK-ALL; }
.plaintext {line-height:25px;}
#detailTable TD {line-height:20px;}
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
					<td width="20" height="30"><a name="top">&nbsp;</a></td>
					<td width="570" height="30" align="left" valign="bottom" class="head">
					  <b>Contact Management</b>
					</td>
					<td>
<!-- Add links here -->
					</td>
				  </tr>
	            </table>
	          </td>
	        </tr>
</table>
	        
<table width='90%' border='0' cellspacing='0' cellpadding='0'>
			<tr>
				<td width="100%">
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Network" />
				<jsp:param name="subCat" value="Contacts" />
				<jsp:param name="role" value="<%=iRole%>" />
			</jsp:include>
<!-- End of Navigation Menu -->
				</td>
	        </tr>
		</table>
		<!-- Content Table -->

		 <table width="90%" border="0" cellspacing="0" cellpadding="0">


			<tr><td colspan="2"><img src='../i/spacer.gif' height='20' /></td></tr>
			<tr>
				<td width="20"><img src="../i/spacer.gif" width="5" height="0"></td>
				<td>

<!-- My Friends / Circle Name -->
<form>
	<table width="100%" border="0" cellpadding="0" cellspacing="0">
	<tr>
	<td class="heading">
		Contacts from:&nbsp;&nbsp;
		<select name="cId" class="formtext" onchange="submit()">
<%
	out.print("<option value='0' ");
	if (selectedCirId == 0)
		out.print("selected");
	out.print(">My Friends</option>");

	int [] ids;
	oA = detailUser.getAttribute("Towns");
	if (oA[0] == null) oA = new Object[0];
	PstAbstractObject [] cirArr = tMgr.get(me, oA);
	Util.sortString(cirArr, "Name", true);

	int id;
	PstAbstractObject o;
	for (int i=0; i < cirArr.length ; i++)
	{
		// circles
		o = cirArr[i];
		id = o.getObjectId();

		out.print("<option value='" + id +"' ");
		if (id == selectedCirId)
			out.print("selected");
		out.print(">" + (String)o.getAttribute("Name")[0] + "</option>");
	}
%>
		</select>
	</td>
	</tr>
	</table>
</form>
			</td>
			</tr>

			<tr>
				<td width="20"><img src="../i/spacer.gif" width="20" border="0"></td>
				<td>

<!-- *************************   Page Headers   ************************* -->

<!-- LABEL -->
<%	int totalCol = 25; %>
<table width='100%' border="0" cellspacing="0" cellpadding="0">
<tr>
<td>
	<table width="100%" border='0' cellpadding="0" cellspacing="0">
		<tr>
		<td bgcolor="#EBECED" height="3"><img src="../i/spacer.gif" width="1" height="3" border="0"></td>
		</tr>
		<tr>
			<td height="2" bgcolor="#336699"><img src="../i/spacer.gif" width="2" height="2"></td>
		</tr>
	</table>

	<table width="100%" border="0" cellspacing="0" cellpadding="0">
	<tr>
<%
	// Name
	if (sortby==null || sortby.equals("fn"))
	{
		out.print("<td width='6' " + srcl + ">&nbsp;</td>");
		out.print("<td width='200' class='td_header' " + srcl + "><b>Name</b></td>");
	}
	else
	{
		out.print("<td width='6' " + bgcl + ">&nbsp;</td>");
		out.print("<td width='200' class='td_header' " + bgcl + "><a href='javascript:sort(0);'><font color='ffffff'><b>Name</b></font></a></td>");
	}

	// My Friend
%>
		<td width='2' bgcolor='#FFFFFF' class='10ptype'><img src='../i/spacer.gif' width='2' height='2'></td>
		<td width='6' bgcolor='#6699cc' class='10ptype'>&nbsp;</td>
		<td width='60' bgcolor='#6699cc' class='td_header'><b>My Friend</b></td>
		<td width='2' bgcolor='#FFFFFF' class='10ptype'><img src='../i/spacer.gif' width='2' height='2'></td>

<%
	// Category
	out.print("<td colspan='9' align='center'><table width='100%' cellspacing='0' cellpadding='0'><tr>");
	if (sortby!=null && sortby.equals("ca"))
	{
		out.print("<td width='6' " + srcl + ">&nbsp;</td>");
		out.print("<td class='td_header' align='center' " + srcl + "><b>Category</b></td>");
	}
	else
	{
		out.print("<td width='6' " + bgcl + ">&nbsp;</td>");
		out.print("<td class='td_header' align='center' " + bgcl + "><a href='javascript:sort(1);'><font color='ffffff'><b>Category</b></font></a></td>");
	}
	out.print("</tr></table></td>");
%>

		<td width='2' bgcolor='#FFFFFF' class='10ptype'><img src='../i/spacer.gif' width='2' height='2'></td>

<%
	// Priority
	out.print("<td colspan='6' align='center'><table width='100%' cellspacing='0' cellpadding='0'><tr>");
	if (sortby!=null && sortby.equals("pr"))
	{
		out.print("<td width='6' " + srcl + ">&nbsp;</td>");
		out.print("<td width='165' class='td_header' align='center' " + srcl + "><b>Priority</b></td>");
	}
	else
	{
		out.print("<td width='6' " + bgcl + ">&nbsp;</td>");
		out.print("<td width='165' class='td_header' align='center' " + bgcl + "><a href='javascript:sort(2);'><font color='ffffff'><b>Priority</b></font></a></td>");
	}
	out.print("</tr></table></td>");

	// Update
%>
		<td width='2' bgcolor='#FFFFFF' class='10ptype'><img src='../i/spacer.gif' width='2' height='2'></td>
		<td width='6' bgcolor='#6699cc' class='10ptype'>&nbsp;</td>
		<td width='45' bgcolor='#6699cc' class='td_header'><b>Update</b></td>
	</tr>

	<tr>
		<td colspan='6'></td>

		<td width='54' bgcolor='#dddddd' class='td_header' align='center'>Work</td>
		<td width='1' bgcolor='#ffffff' class='10ptype'><img src='../i/spacer.gif' width='1' /></td>
		<td width='54' bgcolor='#dddddd' class='td_header' align='center'>Alumni</td>
		<td width='1' bgcolor='#ffffff' class='10ptype'><img src='../i/spacer.gif' width='1' /></td>
		<td width='54' bgcolor='#dddddd' class='td_header' align='center'>Social</td>
		<td width='1' bgcolor='#ffffff' class='10ptype'><img src='../i/spacer.gif' width='1' /></td>
		<td width='54' bgcolor='#dddddd' class='td_header' align='center'>Religion</td>
		<td width='1' bgcolor='#ffffff' class='10ptype'><img src='../i/spacer.gif' width='1' /></td>
		<td width='54' bgcolor='#dddddd' class='td_header' align='center'>Family</td>

		<td></td>
		
		<td width='1' bgcolor='#dddddd' class='10ptype'><img src='../i/spacer.gif' width='1' /></td>
		<td width='54' bgcolor='#dddddd' class='td_header' align='center'><font color='Red'>High</font></td>
		<td width='1' bgcolor='#ffffff' class='10ptype'><img src='../i/spacer.gif' width='1' /></td>
		<td width='54' bgcolor='#dddddd' class='td_header' align='center'><font color='Orange'>Med</font></td>
		<td width='1' bgcolor='#ffffff' class='10ptype'><img src='../i/spacer.gif' width='1' /></td>
		<td width='54' bgcolor='#dddddd' class='td_header' align='center'><font color='yellow'>Low</font></td>
	</tr>

	<!-- Table for listing members -->
<form name='updateContact'  method='post' action='post_upd_contact.jsp'>
<input type='hidden' name='cirId' value='<%=selectedCirId%>' >
<input type='hidden' name='block' value=''>
<input type='hidden' name='backPage' value=''>
<input type='hidden' name='reqFriend' value=''>
<input type='hidden' name='introFriend' value=''>

<%
	//////////////////////////////////////
	// Either circle members or friends
	// start listing members
	int [] memIds = null;
	if (selectedCirId == 0)
	{
		// My Friends
		oA = detailUser.getAttribute("TeamMembers");
		if (oA[0] != null)
			memIds = Util2.toIntArray(oA);
	}
	else
	{
		// list circle members
		memIds = uMgr.findId(me, "Towns=" + selectedCirId);
	}

	Object [] memArr = null;

	// handle sorting, by name, category or priority
	Hashtable [] hsArr = null;
	if (sortby!=null)
	{
		if (sortby.equals("ca"))
		{
			Hashtable [] hsCatArr = {hsWork, hsAlumni, hsSocial, hsReligion, hsFamily};
			hsArr = hsCatArr;
		}
		else if (sortby.equals("pr"))
		{
			Hashtable [] hsPriArr = {hsHigh, hsMed, hsLow};
			hsArr = hsPriArr;
		}
		else
			sortby = null;
	}

	if (sortby != null)
	{
		// rearrange memIds based on the hash tables
		ArrayList al = new ArrayList(100);
		int ct, total = 0;
		PstAbstractObject [] tempArr;
		for (int i=0; i<hsArr.length; i++)
		{
			ids = new int [hsArr[i].size()];
			ct = 0;
			for (int j=0; j<memIds.length && ct<ids.length; j++)
			{
				if (hsArr[i].containsKey(String.valueOf(memIds[j])))
				{
					ids[ct++] = memIds[j];
					memIds[j] = -1;				// nullify this
				}
			}
			if (ct <= 0) continue;

			total += ct;
			tempArr = uMgr.get(me, ids);	// get the PstAbstractObjects
			Util.sortUserArray(tempArr, true);
			Collection l = Arrays.asList(tempArr);
			al.addAll(l);
		}

		// get the rest of the members who are not categorized
		tempArr = new PstAbstractObject[memIds.length - total];
		ct = 0;
		for (int i=0; i<memIds.length; i++)
		{
			if (memIds[i] < 0) continue;
			tempArr[ct++] = uMgr.get(me, memIds[i]);
		}

		if (ct > 0)
		{
			Util.sortUserArray(tempArr, true);
			Collection l = Arrays.asList(tempArr);
			al.addAll(l);
		}
		al.trimToSize();

		memArr = al.toArray();
	}	// END if sortby category or priority

	if (memArr == null)
	{
		memArr = uMgr.get(me, memIds);		// if not filled yet (no sortby case)
		Util.sortUserArray(memArr, true);
	}

	String bgcolor="";
	boolean even = false, isFriend;
	user u, u1;
	String email, idS, uname;
	int ctWk, ctAl, ctSo, ctRe, ctFm, ctH, ctM, ctL;
	ctWk = ctAl = ctSo = ctRe = ctFm = ctH = ctM = ctL = 0;
	int tempId;
	
	out.print("<tr><td><img src='../i/spacer.gif' height='5'/></td></tr>");

	for (int i=0; i<memArr.length; i++)
	{
		u = (user)memArr[i];
		id = u.getObjectId();
		if (id == myUid) continue;				// don't list self
		idS = String.valueOf(id);
		if (selectedCirId==0 || hsFriends.containsKey(idS))
			isFriend = true;
		else
			isFriend = false;
		uname =  u.getFullName();
		email = (String)u.getAttribute("Email")[0];

		if (even)
			bgcolor = Prm.DARK;
		else
			bgcolor = Prm.LIGHT;
		even = !even;

		// full name
		out.print("<tr " + bgcolor + ">");
		out.print("<td><a name='" + idS + "'></a></td>");
		out.print("<td valign='top'><table border='0' cellspacing='0' cellpadding='0'><tr>");
		out.print("<td class='plaintext' valign='top' width='35'>" + (i+1) + ". &nbsp;</td>");
		out.print("<td class='plaintext' valign='top'><a href='javascript:showMem(" + idS + ");'"
				+ ">" + uname + "</a></td>");
		out.print("</tr></table></td>");

		// My Friends
		out.print("<td colspan='2'></td>");
		out.print("<td class='plaintext' align='center'>");
		if (isFriend) {if (even) s="icon_face.gif"; else s="icon_face1.gif"; out.print("<img src='../i/" + s + "' width='18' border='0' />");}
		out.print("</td>");

		// category
		out.print("<td colspan='2' class='formtext' align='center'><input type='checkbox' name='cat_wrk_" + id + "' onclick='updated(" + id + ");'");
		if (!isFriend) out.print(" disabled"); else if (hsWork.get(idS)!=null) {out.print("checked"); ctWk++;}
		out.print("></td>");
		out.print("<td colspan='2' class='formtext' align='center'><input type='checkbox' name='cat_alm_" + id + "' onclick='updated(" + id + ");'");
		if (!isFriend) out.print(" disabled"); else if (hsAlumni.get(idS)!=null) {out.print("checked"); ctAl++;}
		out.print("></td>");
		out.print("<td colspan='2' class='formtext' align='center'><input type='checkbox' name='cat_soc_" + id + "' onclick='updated(" + id + ");'");
		if (!isFriend) out.print(" disabled"); else if (hsSocial.get(idS)!=null) {out.print("checked"); ctSo++;}
		out.print("></td>");
		out.print("<td colspan='2' class='formtext' align='center'><input type='checkbox' name='cat_rel_" + id + "' onclick='updated(" + id + ");'");
		if (!isFriend) out.print(" disabled"); else if (hsReligion.get(idS)!=null) {out.print("checked"); ctRe++;}
		out.print("></td>");
		out.print("<td colspan='2' class='formtext' align='center'><input type='checkbox' name='cat_fam_" + id + "' onclick='updated(" + id + ");'");
		if (!isFriend) out.print(" disabled"); else if (hsFamily.get(idS)!=null) {out.print("checked"); ctFm++;}
		out.print("></td>");

		// priority
		out.print("<td colspan='2'></td>");
		out.print("<td class='formtext' align='center'><input type='radio' name='pri_" + id + "' value='h' onclick='updated(" + id + ");'");
		if (!isFriend) out.print(" disabled"); else if (hsHigh.get(idS)!=null) {out.print("checked"); ctH++;}
		out.print("></td>");
		out.print("<td colspan='2' class='formtext' align='center'><input type='radio' name='pri_" + id + "' value='m' onclick='updated(" + id + ");'");
		if (!isFriend) out.print(" disabled"); else if (hsMed.get(idS)!=null) {out.print("checked"); ctM++;}
		out.print("></td>");
		out.print("<td colspan='2' class='formtext' align='center'><input type='radio' name='pri_" + id + "' value='l' onclick='updated(" + id + ");'");
		if (!isFriend) out.print(" disabled"); else if (hsLow.get(idS)!=null) {out.print("checked"); ctL++;}
		out.print("></td>");

		// update
		out.print("<td colspan='2'></td>");
		out.print("<td class='plaintext' align='center'><input type='checkbox' name='update_" + id + "' id='update_' " + id + "'");
		if (!isFriend) out.print(" disabled></td>");
		out.println("</tr>");

		//////////////////////////////////////////
		// show detail info of the member
		if (showUid == id)
		{
			out.print("<tr><td colspan='" + totalCol + "'><table id='detailTable'>");
			out.print("<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>");
			out.print("<tr><td colspan='18'>");
			out.print("<table border='0' cellspacing='0' cellpadding='0'><tr>");
			out.print("<td><img src='../i/spacer.gif' width='10' /></td>");	// left partition

			// picture on left
			out.print("<td align='left' valign='top'>");
			String picURL = Util2.getPicURL(u);
			out.print("<img src=" + picURL + " border='0' width='90' >");
			out.print("</td>");

			out.print("<td><img src='../i/spacer.gif' width='10' /></td>");	// middle partition

			// info on right
			out.print("<td valign='top'><table bgcolor='#ffffcc' width='400' border='2' cellspacing='0' cellpadding='0' style='border-collapse:collapse;'>");
			out.print("<tr><td class='plaintext' width='100'>&nbsp;<b>Name</b></td><td class='plaintext' width='10' align='center'>:</td>");
			out.print("<td class='plaintext'><a href='../ep/ep1.jsp?uid="+ id + "'>&nbsp;" + u.getFullName() + "</a></td></tr>");

			out.print("<tr><td class='plaintext' width='85'>&nbsp;<b>Email</b></td><td class='plaintext' align='center'>:</td>");
			if (isFriend) s = (String)u.getAttribute("Email")[0];
			else s = "";
			out.print("<td class='plaintext'><a href='mailto:" + s + "'>&nbsp;" + s + "</a></td>");

			out.print("<tr><td class='plaintext'>&nbsp;<b>Work phone</b></td><td class='plaintext' align='center'>:</td>");
			if (isFriend) {s = (String)u.getAttribute("WorkPhone")[0]; if (s == null) s = "";}
			else s = "";
			out.print("<td class='plaintext'>" + s + "</td></tr>");

			out.print("<tr><td class='plaintext'>&nbsp;<b>Cell phone</b></td><td class='plaintext' align='center'>:</td>");
			if (isFriend) {s = (String)u.getAttribute("CellPhone")[0]; if (s == null) s = "";}
			else s = "";
			out.print("<td class='plaintext'>&nbsp;" + s + "</td></tr>");

			out.print("<tr><td class='plaintext'>&nbsp;<b>Skypename</b></td><td class='plaintext' align='center'>:</td>");
			if (isFriend) s = (String)u.getAttribute("SkypeName")[0];
			else s = null;
			out.print("<td class='plaintext'>");
			if (s != null)
				out.print("<a class='listlink' href='skype:" + s + "'>&nbsp;" + s + "</a>");
			out.print("</td></tr>");

			out.print("<tr><td class='plaintext'>&nbsp;<b>Time zone</b></td><td class='plaintext' align='center'>:</td>");
			o = userinfoManager.getInstance().get(me, idS);
			int iVal = ((Integer)o.getAttribute("TimeZone")[0]).intValue();
			int tIdx = iVal - userinfo.SERVER_TIME_ZONE;
			if (tIdx < 0) tIdx = 0;
			if (iVal == 0) s = "";
			else s = userinfo.getZoneString(tIdx);
			out.print("<td class='plaintext'>&nbsp;" + s + "</td></tr>");

			out.print("<tr><td class='plaintext' valign='top'>&nbsp;<b>Motto</b></td><td class='plaintext' valign='top' align='center'>:</td>");
			s = (String)u.getAttribute("Motto")[0];
			if (s == null) s = "";
			out.print("<td class='plaintext'>&nbsp;" + s + "</td></tr>");

			out.print("<tr><td class='plaintext' valign='top'>&nbsp;<b># of friends</b></td><td class='plaintext' valign='top' align='center'>:</td>");
			oA = u.getAttribute("TeamMembers");
			out.print("<td class='plaintext'>&nbsp;" + oA.length + "</td></tr>");

			out.print("<tr><td class='plaintext' valign='top'>&nbsp;<b># of circles</b></td><td class='plaintext' valign='top' align='center'>:</td>");
			oA = u.getAttribute("Towns");
			out.print("<td class='plaintext'>&nbsp;" + oA.length + "</td></tr>");

			out.print("</table></td>");			// close the info column

			out.print("<td><img src='../i/spacer.gif' width='10' /></td>");	// right partition

			// links on far right
			out.print("<td valign='top'><table border='0' cellspacing='0' cellpadding='0' style='word-break:normal'>");
			out.print("<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>");
			out.print("<tr><td valign='top'><img src='../i/bullet_tri.gif' />&nbsp;</td>");
			if (!isFriend)
			{
				out.print("<td><a class='listlinkbold' href='javascript:displayOptPanel();'>Request " + uname + " to be my friend</a></td></tr>");
				out.print("<tr><td><img src='../i/spacer.gif' height='50' /></td></tr>");
			}
			else
			{
				out.print("<td><a class='listlinkbold' href='javascript:introFriend();'>Introduce " + uname + " to my other friends</a></td></tr>");
				out.print("<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>");
				out.print("<tr><td valign='top'><img src='../i/bullet_tri.gif' />&nbsp;</td>");
				out.print("<td><a class='listlinkbold' href='javascript:removeFriend(" + idS + ");'>Remove " + uname + " from My Friends list</a></td></tr>");
				out.print("<tr><td><img src='../i/spacer.gif' height='20' /></td></tr>");
			}
			out.print("<tr valign='bottom'><td colspan='2'><input type='button' value='Close' onClick='closeInfo();' class='button_medium'></td></tr>");
			out.print("</table></td>");

			out.print("</tr></table></td></tr>");
			out.print("<tr><td colspan='18'><img src='../i/spacer.gif' height='10' /></td></tr>");

			// return message display
			String errmsg = (String)session.getAttribute("errorMsg");
			if (errmsg != null)
			{
				session.removeAttribute("errorMsg");
				out.print("<tr><td width='2'>&nbsp;</td>");
				out.print("<td colspan='16' class='plaintext' style='color:#00bb00'>" + errmsg + "</td></tr>");
				out.print("<tr><td><img src='../i/spacer.gif' height='5' /></td></tr>");
			}

			// the panel for optional selecting people to introduce friend
			out.print("<tr><td colspan='22'><div id='introPanel' ");
			PstAbstractObject [] friendArr;
			if (bSelectedIntroCir)
				out.print("style='display:block'>");
			else
				out.print("style='display:none'>");

			out.print("<table>");
			out.print("<tr><td><img src='../i/spacer.gif' width='100' height='1' /></td>");
			out.print("<td colspan='3' class='plaintext'><b>Select friends you want to introduce " + uname + " to</b>:</td></tr>");

			out.print("<tr><td></td><td colspan='3'>");
			out.print("<select name='IntroCir' class='formtext' onchange='getIntroCircle()'>");
			out.print("<option value='0' ");
			if (introCirId == 0)
				out.print("selected");
			out.print(">My Friends</option>");
			for (int j=0; j < cirArr.length ; j++)
			{
				// circles
				o = cirArr[j];
				id = o.getObjectId();
				out.print("<option value='" + id +"' ");
				if (id == introCirId)
					out.print("selected");
				out.print(">" + (String)o.getAttribute("Name")[0] + "</option>");
			}
			out.print("</select>");
			out.print("</td></tr>");

			// get list of contacts to choose from
			if (introCirId == 0)
			{
				oA = me.getAttribute("TeamMembers");
				friendArr = uMgr.get(me, oA);
			}
			else
			{
				ids = uMgr.findId(me, "Towns=" + introCirId);
				friendArr = uMgr.get(me, ids);
			}
			Util.sortUserArray(friendArr, true);


			out.println("<tr><td></td>");
			out.print("<td><select class='formtext_fix' name='AllFriends' multiple size='5'>");
			for (int j=0; j<friendArr.length; j++)
			{
				u1 = (user)friendArr[j];
				tempId = u1.getObjectId();
				if (tempId==showUid || tempId==myUid)
					continue;
				out.print("<option value='" + tempId + "'>" + u1.getFullName() + "</option>");
			}
			out.print("</select></td>");
			out.print("<td align='center' valign='middle'>");
			out.print("<input type='button' class='button' name='add' value='&nbsp;&nbsp;&nbsp;Add &gt;&gt;&nbsp;&nbsp;' onClick='swapdata(updateContact.AllFriends,updateContact.IntroFriends)'>");
			out.print("<br><input type='button' class='button' name='remove' value='<< Remove' onClick='swapdata(updateContact.IntroFriends,updateContact.AllFriends)'>");
			out.print("</td>");
			out.print("<td><select class='formtext_fix' name='IntroFriends' multiple size='5'>");
			out.print("</select></td>");
			out.print("</tr>");
			out.print("</table></td></tr>");
			out.print("</div></td></tr>");

			// the panel for optional msg to request friend
			out.print("<tr><td colspan='22'><div id='reqPanel' ");
			if (bSelectedIntroCir)
				out.print("style='display:block'>");
			else
				out.print("style='display:none'>");
			out.print("<table>");
			out.print("<tr><td><img src='../i/spacer.gif' width='100' height='1' /></td>");
			out.print("<td class='plaintext'><b>Optional message</b>:</td></tr>");
			out.print("<tr><td></td>");
			out.print("<td><textarea name='optMsg' rows='4' cols='80' style='word-break:normal' class='formtext'></textarea></td></tr>");

			out.print("<tr><td></td><td align='center'>");
			out.print("<input type='button' class='plaintext' name='save' value='SEND REQUEST' onclick='requestFriend(" + idS + ");'>&nbsp;&nbsp;");
			out.print("<input type='button' class='plaintext' name='cancel' value='CANCEL' onclick='closeOptPanel();'>");
			out.print("</td></tr>");
			out.print("<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>");
			out.print("</table></td></tr>");
			out.print("</div></td></tr>");
			
			out.print("</table></td></tr>");
		}	// END if this is the user to be shown
	}	// END for each member

	// print summary
	out.println("<tr class='plaintext'><td colspan='5' class='plaintext' align='right'><b>Sub-Total:</b></td>");
	out.print("<td colspan='2' class='plaintext' align='center'>" + ctWk + "</td>");
	out.print("<td colspan='2' class='plaintext' align='center'>" + ctAl + "</td>");
	out.print("<td colspan='2' class='plaintext' align='center'>" + ctSo + "</td>");
	out.print("<td colspan='2' class='plaintext' align='center'>" + ctRe + "</td>");
	out.print("<td colspan='2' class='plaintext' align='center'>" + ctFm + "</td>");
	out.print("<td></td>");
	out.print("<td colspan='2' class='plaintext' align='center'>" + ctH+ "</td>");
	out.print("<td colspan='2' class='plaintext' align='center'>" + ctM + "</td>");
	out.print("<td colspan='2' class='plaintext' align='center'>" + ctL + "</td>");
	out.print("</tr>");

	// All friends summary
	if (selectedCirId > 0)
	{
		out.println("<tr class='plaintext'><td colspan='5' class='plaintext' align='right'><b>Total (My Friends):</b></td>");
		out.print("<td></td>");
		out.print("<td colspan='2' class='plaintext' align='center'>" + hsWork.size() + "</td>");
		out.print("<td colspan='2' class='plaintext' align='center'>" + hsAlumni.size() + "</td>");
		out.print("<td colspan='2' class='plaintext' align='center'>" + hsSocial.size() + "</td>");
		out.print("<td colspan='2' class='plaintext' align='center'>" + hsReligion.size() + "</td>");
		out.print("<td colspan='2' class='plaintext' align='center'>" + hsFamily.size() + "</td>");
		out.print("<td></td>");
		out.print("<td colspan='2' class='plaintext' align='center'>" + hsHigh.size() + "</td>");
		out.print("<td colspan='2' class='plaintext' align='center'>" + hsMed.size() + "</td>");
		out.print("<td colspan='2' class='plaintext' align='center'>" + hsLow.size() + "</td>");
		out.print("</tr>");
	}
%>
	</table>

	<!-- buttons -->
	<table width='100%'><tr><td align='right'>
	<input type='submit' value='Update' onClick='return validate();' class='button_medium'>
	</td></tr></table>

</form>

</td>
</tr>


<tr><td>&nbsp;</td></tr>
</table>

</td></tr>
</table>

<!-- BEGIN FOOTER TABLE -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

