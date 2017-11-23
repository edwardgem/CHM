<%
////////////////////////////////////////////////////
//	Copyright (c) 2008, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	circles.jsp
//	Author:	ECC
//	Date:	12/01/08
//	Description:
//		A social networking page to manage and prioritize circles.
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
<%@ page import = "java.util.regex.*" %>
<%@ page import = "java.io.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	PstUserAbstractObject me = pstuser;
	if (me instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
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
	
	// construct my circle hash for comparison later
	Hashtable hsCircles = new Hashtable();
	Object [] oA = detailUser.getAttribute("Towns");
	for (int i=0; i<oA.length; i++)
	{
		if (oA[i]==null || ((Integer)oA[i]).intValue()==0) break;
		hsCircles.put(((Integer)oA[i]).toString(), "");
	}
	
	// construct the Hash for contact type
	Hashtable hsHigh, hsMed, hsLow;
	hsHigh = hsMed = hsLow = null;
	Object bObj = detailUser.getAttribute("CircleType")[0];
	String bStr = (bObj==null)?"":new String((byte[])bObj);
	hsHigh = Util3.fillHash(bStr, "high");
	hsMed  = Util3.fillHash(bStr, "medium");
	hsLow  = Util3.fillHash(bStr, "low");
	
	// display My Circles or search
	boolean bDisplayMyCircles = true;
	if ((s = request.getParameter("my"))!=null && s.equals("false"))
		bDisplayMyCircles = false;
	
	// sort
	String sortby = request.getParameter("sb");
	String bgcl = "bgcolor='#6699cc'";
	String srcl = "bgcolor='#66cc99'";
	
	// display a certain member details
	int showCid = 0;
	if ((s = request.getParameter("cid")) != null)
		showCid = Integer.parseInt(s);
	
	// search
	String keyword = "";
	boolean bSrWk, bSrAl, bSrSo, bSrRe, bSrFa;
	bSrWk = bSrAl = bSrSo = bSrRe = bSrFa = false;
	String expr = "";
	if (!bDisplayMyCircles)
	{
		if (bSrWk = (request.getParameter("sr_wk") != null))
		{
			if (expr.length() > 0) expr += " || ";
			expr += " (Type='" + town.TYPE_CIR_WORK + "')";
		}
		if (bSrAl = (request.getParameter("sr_al") != null))
		{
			if (expr.length() > 0) expr += " || ";
			expr += " (Type='" + town.TYPE_CIR_ALUMNI + "')";
		}
		if (bSrSo = (request.getParameter("sr_so") != null))
		{
			if (expr.length() > 0) expr += " || ";
			expr += " (Type='" + town.TYPE_CIR_SOCIAL + "')";
		}
		if (bSrRe = (request.getParameter("sr_re") != null))
		{
			if (expr.length() > 0) expr += " || ";
			expr += " (Type='" + town.TYPE_CIR_RELIGION + "')";
		}
		if (bSrFa = (request.getParameter("sr_fa") != null))
		{
			if (expr.length() > 0) expr += " || ";
			expr += " (Type='" + town.TYPE_CIR_FAMILY + "')";
		}

		keyword = request.getParameter("keyword");
		if (keyword != null)
		{
			keyword = keyword.trim();
			if (keyword.length() > 0)
			{
				if (keyword.equals("*"))
					keyword = "";			// wildcard
				if (expr.length() > 0)
				{
					expr = "(" + expr + ")";
					expr += " && (Name='%" + keyword + "%')";
				}
				else
					expr = "Name='%" + keyword + "%'";
			}
		}
		else keyword = "";
		
	}
//System.out.println("expr="+expr);
	
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">


<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
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
	// 0=name; 1=(circle)type; 2=priority
	var str = "";
	if (ty == 0) str = "fn";
	else if (ty == 1) str = "ty";		// not supported now
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
		location = "circles.jsp?sb=" + str;
		return;
	}
	if ((idx = queryStr.indexOf("&sb")) != -1)
		queryStr = queryStr.substring(0, idx);
	location = "circles.jsp" + queryStr + "&sb=" + str;
	return;
}

function showMem(cid)
{
	var fullURL = parent.document.URL;
	var idx;
	if ((idx = fullURL.indexOf("?")) != -1)
		queryStr = fullURL.substring(idx);				// include the "?"
	else
	{
		location = "circles.jsp?cid=" + cid + "#" + cid;
		return;
	}
	if ((idx = queryStr.indexOf("cid")) != -1)
		queryStr = queryStr.substring(0, idx-1);
	if (queryStr.length <= 0)
		queryStr = "?";
	else
		queryStr += "&";
	location = "circles.jsp" + queryStr + "cid=" + cid + "#" + cid;
	return;
}

function closeInfo()
{
	var fullURL = parent.document.URL;
	var idx = fullURL.indexOf("cid");
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
			updateCircle.optMsg.focus();
		}
	}}

function closeOptPanel()
{
	var f = document.updateCircle;
	f.introCircle.value = "";			// reset

	var e = document.getElementById("introPanel");
	e.style.display = "none";
	e = document.getElementById("reqPanel");
	e.style.display = "none";
}

function requestCircle(cid)
{
	// this takes care of two requests, determined by the value of updateCircle.introCircle
	// 1. send request to join a circle
	// 2. send intro circle event
	var f = document.updateCircle;
	f.reqCircle.value = "" + cid;
	if (f.introCircle.value == "true")
		getall(f.IntroFriends);					// introduce a circle to selected friends
		
	f.backPage.value = parent.document.URL;
	f.submit();
}

function removeCircle(uid)
{
	// bidirectionally remove & block this friend
	// code from ep_circles.jsp for block/remove
	if (!confirm("Are you sure you want to drop your membership from this circle?"))
		return false;
	
	var f = document.updateCircle;
	f.drop.value = "" + uid;
	f.backPage.value = parent.document.URL;
	f.submit();
}

function introCircle()
{
	// recommend this circle to others
	// display panel to allow introduce this circle to selected friends
	var f = document.updateCircle;
	if (f.introCircle.value == "true")
	{
		closeOptPanel();
		f.introCircle.value = "";			// toggle intro friend panel
		return;
	}
	
	f.introCircle.value = "true";
	displayOptPanel("introPanel");
	displayOptPanel("reqPanel");
	return;
}

function switchDisplay(type)
{
	// either show my circles or search
	if ((type==0 && <%=bDisplayMyCircles%>==true)
		|| (type!=0 && <%=bDisplayMyCircles%>==false))
		return;

	if (type == 0)
		location = 'circles.jsp';
	else
		location = 'circles.jsp?my=false';
}
//-->
</script>

<title>
	OMF Circle Management
</title>

</head>
<style type="text/css">
.wrap_table {WORD-BREAK:BREAK-NORMAL; }
</style>


<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" height="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">
		<!-- Main Tables -->
		<table width="100%" border="0" cellspacing="0" cellpadding="0">
		  	<tr>
		    	<td width="90%" valign="top">
					<!-- Top -->
					<jsp:include page="../head.jsp" flush="true"/>
					<!-- End of Top -->
				</td>
			</tr>
			<tr>
	          <td>
	            <table width="100%" border="0" cellspacing="0" cellpadding="0">
				  <tr>
					<td width="20" height="30"><a name="top">&nbsp;</a></td>
					<td width="570" height="30" align="left" valign="bottom" class="head">
					  <b>Circle Management</b>
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
				<jsp:param name="subCat" value="Circle" />
				<jsp:param name="role" value="<%=iRole%>" />
			</jsp:include>
<!-- End of Navigation Menu -->
				</td>
	        </tr>
		</table>
		<!-- Content Table -->

		 <table width="90%" border="0" cellspacing="0" cellpadding="0">


			<tr><td colspan="2"><img src='../i/spacer.gif' height='20' /></td></tr>
			
<%			
			// select display my circle or search
			out.print("<tr><td width='20'></td>");
			out.print("<td class='plaintext_big'>");
			out.print("<input type='radio' name='display' value='myCircles' onclick='switchDisplay(0);' ");
			if (bDisplayMyCircles) out.print("checked");
			out.print(">Show my circles");
			out.print("<img src='../i/spacer.gif' width='30' height='1' />");
			out.print("<input type='radio' name='display' value='search' onclick='switchDisplay(1);' ");
			if (!bDisplayMyCircles) out.print("checked");
			out.print(">Search circles");
			out.print("</td></tr>");
			
			// panel for search
			if (!bDisplayMyCircles)
			{
				out.print("<div id='searchPanel'>");
				out.print("<form>");
				out.print("<input type='hidden' name='my' value='false'>");
				out.print("<tr><td><img src='../i/spacer.gif' height='5' /></td></tr>");
				out.print("<tr><td></td>");
				out.print("<td>");
				out.print("<table border='0' cellspacing='0' cellpadding='0'>");
				
				// circle type
				out.print("<tr><td><img src='../i/spacer.gif' width='50' height='1' /></td>");
				out.print("<td class='plaintext' width='100'><b>Circle type</b>:</td>");
				out.print("<td class='plaintext'>");
				out.print("<input type='checkbox' name='sr_wk' "); if (bSrWk) out.print("checked"); out.print(">Work<img src='../i/spacer.gif' width='10'/>");
				out.print("<input type='checkbox' name='sr_al' "); if (bSrAl) out.print("checked"); out.print(">Alumni<img src='../i/spacer.gif' width='10'/>");
				out.print("<input type='checkbox' name='sr_so' "); if (bSrSo) out.print("checked"); out.print(">Social<img src='../i/spacer.gif' width='10'/>");
				out.print("<input type='checkbox' name='sr_re' "); if (bSrRe) out.print("checked"); out.print(">Religion<img src='../i/spacer.gif' width='10'/>");
				out.print("<input type='checkbox' name='sr_fa' "); if (bSrFa) out.print("checked"); out.print(">Family<img src='../i/spacer.gif' width='10'/>");
				out.print("</td></tr>");
				out.print("<tr><td><img src='../i/spacer.gif' height='5' /></td></tr>");
				
				// keywords
				out.print("<tr><td></td><td class='plaintext'><b>Keywords</b>:</td>");
				out.print("<td class='plaintext'>");
				out.print("&nbsp;<input type='text' size='40' name='keyword' class='formtext' value='" + keyword + "'>");
				out.print("</td></tr>");
				
				// buttons
				out.print("<tr><td></td><td colspan='2'>");
				out.print("<img src='../i/spacer.gif' width='160' height='25'/>");
				out.print("<input type='submit' value='Submit' class='plaintext'>");
				out.print("<img src='../i/spacer.gif' width='10' />");
				out.print("<input type='button' value='Cancel' class='plaintext' onClick='switchDisplay(0);'>");
				out.print("</td></tr>");
				
				out.print("</table>");
				out.print("</td></tr>");
				out.print("</form>");
				out.print("</div>");
			}
%>					

			<tr><td colspan="2"><img src='../i/spacer.gif' height='10' /></td></tr>
			
			<tr>
				<td width="20"><img src="../i/spacer.gif" width="20" border="0"></td>
				<td>

<!-- *************************   Page Headers   ************************* -->

<!-- LABEL -->
<%	int totalCol = 20; %>
<table width='100%' border="0" cellspacing="0" cellpadding="0">
<tr>
<td>
	<table width="100%" border='0' cellpadding="0" cellspacing="0">
		<tr>
		<td bgcolor="#EBECED" height="3"><img src="../i/spacer.gif" width="1" height="3" border="0"></td>
		</tr>
	</table>
	
	<table width="100%" border="0" cellspacing="0" cellpadding="0">
	<tr>
		<td colspan="<%=totalCol%>" height="2" bgcolor="#336699"><img src="../i/spacer.gif" width="2" height="2"></td>
	</tr>
	<tr>
<%	if (sortby==null || sortby.equals("fn"))
	{
		out.print("<td width='6' " + srcl + ">&nbsp;</td>");
		out.print("<td width='210' class='td_header' " + srcl + "><b>Circle Name</b></td>");
	}
	else
	{
		out.print("<td width='6' " + bgcl + ">&nbsp;</td>");
		out.print("<td width='210' class='td_header' " + bgcl + "><a href='javascript:sort(0);'><font color='ffffff'><b>Name</b></font></a></td>");
	}
%>
		<td width='2' bgcolor='#FFFFFF' class='10ptype'><img src='../i/spacer.gif' width='2' height='2'></td>
		<td width='6' bgcolor='#6699cc' class='10ptype'>&nbsp;</td>
		<td width='50' bgcolor='#6699cc' class='td_header'><b>My Cir</b></td>
		
		<td width='2' bgcolor='#FFFFFF' class='10ptype'><img src='../i/spacer.gif' width='2' height='2'></td>
		<td width='6' bgcolor='#6699cc' class='10ptype'>&nbsp;</td>
		<td width='100' bgcolor='#6699cc' class='td_header'><b>Moderator</b></td>
		
		<td width='2' bgcolor='#FFFFFF' class='10ptype'><img src='../i/spacer.gif' width='2' height='2'></td>
		<td width='6' bgcolor='#6699cc' class='10ptype'>&nbsp;</td>
		<td width='60' bgcolor='#6699cc' class='td_header' align='center'><b>Type</b></td>
		
		<td width='2' bgcolor='#FFFFFF' class='10ptype'><img src='../i/spacer.gif' width='2' height='2'></td>
		
<%	if (sortby!=null && sortby.equals("pr"))
	{
		out.print("<td width='6' " + srcl + ">&nbsp;</td>");
		out.print("<td width='165' class='td_header' align='center' " + srcl + "><b>Priority</b></td>");
	}
	else
	{
		out.print("<td width='6' " + bgcl + ">&nbsp;</td>");
		out.print("<td width='165' class='td_header' align='center' " + bgcl + "><a href='javascript:sort(2);'><font color='ffffff'><b>Priority</b></font></a></td>");
	}
%>
		
		<td width='2' bgcolor='#FFFFFF' class='10ptype'><img src='../i/spacer.gif' width='2' height='2'></td>
		<td width='6' bgcolor='#6699cc' class='10ptype'>&nbsp;</td>
		<td width='80' bgcolor='#6699cc' class='td_header' align='center'><b>Members #</b></td>
		
		<td width='2' bgcolor='#FFFFFF' class='10ptype'><img src='../i/spacer.gif' width='2' height='2'></td>
		<td width='6' bgcolor='#6699cc' class='10ptype'>&nbsp;</td>
		<td width='45' bgcolor='#6699cc' class='td_header'><b>Update</b></td>
	</tr>
	
	<tr>
		<td colspan='12'></td>
		<td colspan='2'><table width='100%' border='0' cellspacing='0' cellpadding='0'>
			<tr>
			<td width='1' bgcolor='#dddddd' class='10ptype'><img src='../i/spacer.gif' width='1' /></td>
			<td width='54' bgcolor='#dddddd' class='td_header' align='center'><font color='Red'>High</font></td>
			<td width='1' bgcolor='#ffffff' class='10ptype'><img src='../i/spacer.gif' width='1' /></td>
			<td width='54' bgcolor='#dddddd' class='td_header' align='center'><font color='Orange'>Med</font></td>
			<td width='1' bgcolor='#ffffff' class='10ptype'><img src='../i/spacer.gif' width='1' /></td>
			<td width='54' bgcolor='#dddddd' class='td_header' align='center'><font color='yellow'>Low</font></td>
			<td width='1' bgcolor='#dddddd' class='10ptype'><img src='../i/spacer.gif' width='1' /></td>
			</tr></table>
		</td>
	</tr>
	</table>
	
	<!-- Table for listing members -->
<form name='updateCircle'  method='post' action='post_upd_circle.jsp'>
<input type='hidden' name='my' value='<%=bDisplayMyCircles%>' >
<input type='hidden' name='drop' value=''>
<input type='hidden' name='backPage' value=''>
<input type='hidden' name='reqCircle' value=''>
<input type='hidden' name='introCircle' value=''>

	<table width="100%" border="0" cellspacing="0" cellpadding="0" class='wrap_table'>
	<tr>
		<td width='6'>&nbsp;</td><td width='210'>&nbsp;</td>
		<td width='2'><img src='../i/spacer.gif' width='2' /></td><td width='6'>&nbsp;</td><td width='50'>&nbsp;</td>
		<td width='2'><img src='../i/spacer.gif' width='2' /></td><td width='6'>&nbsp;</td><td width='100'>&nbsp;</td>
		<td width='2'><img src='../i/spacer.gif' width='2' /></td><td width='6'>&nbsp;</td><td width='60'>&nbsp;</td>
		<td width='2'><img src='../i/spacer.gif' width='2' /></td>
			<td width='55' class='plaintext'>&nbsp;</td>
			<td width='55' class='plaintext'>&nbsp;</td>
			<td width='55' class='plaintext'>&nbsp;</td>
		<td width='2'><img src='../i/spacer.gif' width='2' /></td><td width='6'>&nbsp;</td><td width='80'>&nbsp;</td>
		<td width='2'><img src='../i/spacer.gif' width='2' /></td><td width='6'>&nbsp;</td><td width='45'>&nbsp;</td>
	</tr>
<%
	//////////////////////////////////////
	// start listing circles
	int [] ids;
	int [] memIds = new int[0];
	
	if (bDisplayMyCircles)
		memIds = Util2.toIntArray(detailUser.getAttribute("Towns"));	// my circles
	else if (expr.length() > 0)
	{
		// search
		memIds = tMgr.findId(me, expr);

		if (keyword!=null && keyword.length()>0)
		{
			// to search Description (binary) I need to use manual method
			Pattern p = null;
			Matcher m = null;
			p = Pattern.compile(keyword, Pattern.CASE_INSENSITIVE);
			m = p.matcher("");
			ids = tMgr.findId(me, "om_acctname='%'");
			PstAbstractObject o;
			Object [] tempArr = null;
			ArrayList al0 = new ArrayList();
			for (int i=0; i<ids.length; i++)
			{
				o = tMgr.get(me, ids[i]);
				Object obj = o.getAttribute("Description")[0];
				String text = (obj!=null)?new String((byte[])obj):"";
				String plainText = text.replaceAll("<\\S[^>]*>", "");
				m.reset(plainText);
				if (m.find())
				{
					al0.add(new Integer(ids[i]));
				}
			}
			if (al0.size() > 0)
				tempArr = al0.toArray();
			ids = Util2.toIntArray(tempArr);
			memIds = Util2.mergeIntArray(memIds, ids);
		}
	}

	// handle sorting, by name, category or priority
	Hashtable [] hsArr = null;
	Object [] memArr = null;
	
	if (sortby!=null)
	{
		if (sortby.equals("pr"))
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
			tempArr = tMgr.get(me, ids);	// get the PstAbstractObjects
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
			tempArr[ct++] = tMgr.get(me, memIds[i]);
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
		memArr = tMgr.get(me, memIds);		// if not filled yet (no sortby case)
		Util.sortString(memArr, "Name", true);
	}

	int id, tempId;
	String bgcolor="";
	boolean even = false, isMyCircle, isChief;
	town tObj;
	Object bTextObj;
	String idS, email, cirName, bText, chiefIdS;
	user u, u1;
	int ctH, ctM, ctL;
	ctH = ctM = ctL = 0;

	for (int i=0; i<memArr.length; i++)
	{
		tObj = (town)memArr[i];
		id = tObj.getObjectId();
		idS = String.valueOf(id);
		if (hsCircles.containsKey(idS))
			isMyCircle = true;
		else
			isMyCircle = false;
		cirName =  (String)tObj.getAttribute("Name")[0];
		email = (String)tObj.getAttribute("Email")[0];
		
		u = null;
		isChief = false;
		if ((chiefIdS = (String)tObj.getAttribute("Chief")[0]) != null)
		{
			u = (user)uMgr.get(me, Integer.parseInt(chiefIdS));
			if (myUid == Integer.parseInt(chiefIdS))
				isChief = true;
		}

		if (even)
			bgcolor = "bgcolor='#EEEEEE'";
		else
			bgcolor = "bgcolor='#ffffff'";
		even = !even;

		// full name
		out.print("<tr " + bgcolor + ">");
		out.print("<td><a name='" + id + "'></a></td>");
		out.print("<td valign='top'><table border='0' cellspacing='0' cellpadding='0'><tr>");
		out.print("<td class='plaintext' valign='top' width='35'>" + (i+1) + ". &nbsp;</td>");
		out.print("<td class='plaintext' valign='top'><a href='javascript:showMem(" + idS + ");'"
				+ ">" + cirName + "</a></td>");
		out.print("</tr></table></td>");
		
		// My Circle
		out.print("<td colspan='2'></td>");
		out.print("<td class='plaintext' align='center' valign='top'>");
		if (isMyCircle) {if (even) s="circle.jpg"; else s="circle.jpg"; out.print("<img src='../i/" + s + "' border='0' />");}
		out.print("</td>");

		// moderator
		out.print("<td colspan='2'></td>");
		out.print("<td class='plaintext' valign='top'>");
		if (u != null)
			out.print("<a href='../ep/ep1.jsp?uid=" + u.getObjectId() + "'>" + u.getFullName() + "</a>");
		else
			out.print("&nbsp;&nbsp;-");
		out.print("</td>");
		
		// circle type
		if ((s = (String)tObj.getAttribute("Type")[0]) == null)
			s = "";
		out.print("<td colspan='2'></td>");
		out.print("<td class='plaintext' align='center' valign='top'>" + s);
		out.print("</td>");

		// priority
		out.print("<td></td>");
		out.print("<td class='formtext' align='center' valign='top'><input type='radio' name='pri_" + id + "' value='h' onclick='updated(" + id + ");'");
		if (!isMyCircle) out.print(" disabled"); else if (hsHigh.get(idS)!=null) {out.print("checked"); ctH++;}
		out.print("></td>");
		out.print("<td class='formtext' align='center' valign='top'><input type='radio' name='pri_" + id + "' value='m' onclick='updated(" + id + ");'");
		if (!isMyCircle) out.print(" disabled"); else if (hsMed.get(idS)!=null) {out.print("checked"); ctM++;}
		out.print("></td>");
		out.print("<td class='formtext' align='center' valign='top'><input type='radio' name='pri_" + id + "' value='l' onclick='updated(" + id + ");'");
		if (!isMyCircle) out.print(" disabled"); else if (hsLow.get(idS)!=null) {out.print("checked"); ctL++;}
		out.print("></td>");
		
		// # of members
		ids = uMgr.findId(me, "Towns=" + id);
		out.print("<td colspan='2'></td>");
		out.print("<td class='plaintext' align='center' valign='top'>" + ids.length + "</td>");
		
		// update
		out.print("<td colspan='2'></td>");
		out.print("<td class='plaintext' align='center' valign='top'><input type='checkbox' name='update_" + id + "' id='update_' " + id + "'");
		if (!isMyCircle) out.print(" disabled></td>");
		out.println("</tr>");
		
		//////////////////////////////////////////
		// show detail info of the member
		if (showCid == id)
		{
			out.print("<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>");
			out.print("<tr><td colspan='21'>");
			out.print("<table border='0' cellspacing='0' cellpadding='0'><tr>");
			out.print("<td><img src='../i/spacer.gif' width='10' /></td>");	// left partition

			// picture on left
			out.print("<td align='left' valign='top'>");
			String picURL = Util2.getPicURL(tObj, "../i/group.jpg");
			out.print("<img src=" + picURL + " border='0' width='90' >");
			out.print("</td>");
			
			out.print("<td><img src='../i/spacer.gif' width='10' /></td>");	// middle partition

			// info on right
			out.print("<td valign='top'><table bgcolor='#ffffcc' width='380' border='2' cellspacing='0' cellpadding='0' style='border-collapse:collapse;'>");
			out.print("<tr><td class='plaintext' width='100'>&nbsp;<b>Name</b></td><td class='plaintext' width='10'>:</td>");
			out.print("<td class='plaintext'>" + cirName + "</td></tr>");

			out.print("<tr><td class='plaintext' width='85'>&nbsp;<b>Moderator</b></td><td class='plaintext'>:</td>");
			out.print("<td class='plaintext'>");
			if (u != null)
				out.print("<a href='mailto:" + u.getAttribute("Email")[0] + "'>" + u.getFullName() + "</a>");
			out.print("</td>");

			if ((s = (String)tObj.getAttribute("Type")[0]) == null) s = "";
			out.print("<tr><td class='plaintext' valign='top'>&nbsp;<b>Type</b></td><td class='plaintext' valign='top'>:</td>");
			out.print("<td class='plaintext'>" + s + "</td></tr>");

			out.print("<tr><td class='plaintext' valign='top'>&nbsp;<b># of members</b></td><td class='plaintext' valign='top'>:</td>");
			out.print("<td class='plaintext'>" + ids.length + "</td></tr>");

			out.print("<tr><td class='plaintext' valign='top'>&nbsp;<b>Description</b></td><td class='plaintext' valign='top'>:</td>");
			bTextObj = tObj.getAttribute("Description")[0];
			bText = (bTextObj==null)?"":new String((byte[])bTextObj);
			out.print("<td class='plaintext'>" + bText + "</td></tr>");

			out.print("</table></td>");			// close the info column
			
			out.print("<td><img src='../i/spacer.gif' width='10' /></td>");	// right partition
			
			// links on far right
			out.print("<td valign='top'><table border='0' cellspacing='0' cellpadding='0' style='word-break:normal'>");
			out.print("<tr><td><img src='../i/spacer.gif' height='5' /></td></tr>");
			out.print("<tr><td valign='top'><img src='../i/bullet_tri.gif' />&nbsp;</td>");
			if (!isMyCircle)
			{
				out.print("<td><a class='listlinkbold' href='javascript:displayOptPanel();'>Request to join " + cirName + "</a></td></tr>");
				out.print("<tr><td><img src='../i/spacer.gif' height='50' /></td></tr>");
			}
			else
			{
				out.print("<td><a class='listlinkbold' href='javascript:introCircle(" + idS + ");'>Recommend " + cirName + " to my friends</a></td></tr>");
				out.print("<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>");
				if (!isChief)
				{
					// drop membership
					out.print("<tr><td valign='top'><img src='../i/bullet_tri.gif' />&nbsp;</td>");
					out.print("<td><a class='listlinkbold' href='javascript:removeCircle(" + idS + ");'>Remove " + cirName + " from My Circles list</a></td></tr>");
				}
				else
				{
					// update circle
					out.print("<tr><td valign='top'><img src='../i/bullet_tri.gif' />&nbsp;</td>");
					out.print("<td><a class='listlinkbold' href='../ep/cir_update.jsp?townId=" + idS + "#update'>Update " + cirName + "</a></td></tr>");
				}
				out.print("<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>");
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
			oA = me.getAttribute("TeamMembers");
			PstAbstractObject [] friendArr = uMgr.get(me, oA);
			Util.sortUserArray(friendArr, true);
			out.print("<tr><td colspan='22'><div id='introPanel' style='display:none'>");
			out.print("<table>");
			out.print("<tr><td><img src='../i/spacer.gif' width='100' height='1' /></td>");
			out.print("<td colspan='3' class='plaintext'><b>Select friends you want to recommend <font color='#ee0000'>" + cirName + "</font> to</b>:</td></tr>");
			out.print("<tr><td></td>");
			out.print("<td><select class='formtext_fix' name='AllFriends' multiple size='5'>");
			for (int j=0; j<friendArr.length; j++)
			{
				u1 = (user)friendArr[j];
				tempId = u1.getObjectId();
				if (tempId==myUid)
					continue;
				out.print("<option value='" + tempId + "'>" + u1.getFullName() + "</option>");
			}
			out.print("</select></td>");
			out.print("<td align='center' valign='middle'>");
			out.print("<input type='button' class='button' name='add' value='&nbsp;&nbsp;&nbsp;Add &gt;&gt;&nbsp;&nbsp;' onClick='swapdata(updateCircle.AllFriends,updateCircle.IntroFriends)'>");
			out.print("<br><input type='button' class='button' name='remove' value='<< Remove' onClick='swapdata(updateCircle.IntroFriends,updateCircle.AllFriends)'>");
			out.print("</td>");
			out.print("<td><select class='formtext_fix' name='IntroFriends' multiple size='5'>");
			out.print("</select></td>");
			out.print("</tr>");
			out.print("</table></td></tr>");
			out.print("</div></td></tr>");
			
			// the panel for optional msg to request friend 
			out.print("<tr><td colspan='22'><div id='reqPanel' style='display:none'>");
			out.print("<table>");
			out.print("<tr><td><img src='../i/spacer.gif' width='100' height='1' /></td>");
			out.print("<td class='plaintext'><b>Optional message</b>:</td></tr>");
			out.print("<tr><td></td>");
			out.print("<td><textarea name='optMsg' rows='4' cols='80' style='word-break:normal' class='formtext'></textarea></td></tr>");
			
			out.print("<tr><td></td><td align='center'>");
			out.print("<input type='button' class='button_medium' name='save' value='SEND REQUEST' onclick='requestCircle(" + idS + ");'>&nbsp;&nbsp;");
			out.print("<input type='button' class='button_medium' name='cancel' value='CANCEL' onclick='closeOptPanel();'>");
			out.print("</td></tr>");
			out.print("<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>");
			out.print("</table></td></tr>");
			out.print("</div></td></tr>");
		}
	}	// END for each member
	
	// print summary
	out.println("<tr class='plaintext'><td colspan='11' class='plaintext' align='right'><b>Sub-Total:</b></td>");
	out.print("<td></td>");
	out.print("<td class='plaintext' align='center'>" + ctH+ "</td>");
	out.print("<td class='plaintext' align='center'>" + ctM + "</td>");
	out.print("<td class='plaintext' align='center'>" + ctL + "</td>");
	out.print("</tr>");
	
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

