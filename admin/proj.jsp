<%@ page contentType="text/html; charset=utf-8"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html>
<%
////////////////////////////////////////////////////
//	Copyright (c) 2004-2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	proj.jsp
//	Author:	ECC
//	Date:	04/22/05
//	Description:
//		Project and user statistics.
//	Modification:
//		@041906SSI	Added sort function to Project names.
//		@ECC071607	For CR/PRM, display the user's DepartmentName.
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>
<%@ page import = "util.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");
	
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ((pstuser instanceof PstGuest) || ((iRole & user.iROLE_ADMIN) == 0) )
	{
		response.sendRedirect("/error.jsp?msg=Access declined");
		return;
	}
	String projIdS = request.getParameter("projId");
	int viewProjId = 0;
	if (projIdS!=null && projIdS.length()>0)
		viewProjId = Integer.parseInt(projIdS);

	// to check if session is CR or PRM
	boolean isCRAPP = Prm.isCR();
	String app = Prm.getAppTitle();
	
	// get all the user object of this project
	userManager uMgr = userManager.getInstance();
	userinfoManager uiMgr = userinfoManager.getInstance();
	projectManager pjMgr = projectManager.getInstance();

	PstAbstractObject [] userList = null;
	if (viewProjId > 0)
		userList = ((user)pstuser).getTeamMembers(viewProjId);
	else
		userList = ((user)pstuser).getAllUsers();
	
	// get active user number
	int totalRegUser = userList.length;
	int totalInactive = 0;

	String status, uname, s;
	SimpleDateFormat df = new SimpleDateFormat ("MM/dd/yy (EEE) hh:mm a");
	user u;
	userinfo ui;
	Date lastLogin;
	int uid, num;
	Integer iObj;

	// get the ui object
	PstAbstractObject [] uiList = new PstAbstractObject[userList.length];
	for (int i=0; i<userList.length; i++)
	{
		u = (user)userList[i];
		if (u==null) {uiList[i] = null; continue;}

		// user info
		uid = u.getObjectId();
		try {uiList[i] = (userinfo)uiMgr.get(pstuser, String.valueOf(uid));}
		catch (PmpException e) {uiList[i] = null;}
	}

	// sorting
	String sortby = (String) request.getParameter("sortby");
	if (sortby!=null && sortby.length()==0) sortby = null;
	if (sortby != null)
	{
		// LastLogin
		if (sortby.equals("lg"))
		{
			PstAbstractObject o1, o2, otemp;
			Date v1, v2;
			Date oldDate = new Date(0);
			boolean swap;
			do
			{
				swap = false;
				for (int i=0; i<userList.length-1; i++)
				{
					o1 = uiList[i];
					o2 = uiList[i+1];
					try
					{
						if (o1 == null) v1 = null;
						else v1 = (Date)o1.getAttribute("LastLogin")[0];
						if (o2 == null) v2 = null;
						else v2 = (Date)o2.getAttribute("LastLogin")[0];
						if (v1 == null) v1 = oldDate;
						if (v2 == null) v2 = oldDate;
						if (v2.compareTo(v1)>0)
							swap = true;

						if (swap)
						{
							// swap the element
							uiList[i]   = o2;
							uiList[i+1] = o1;
							otemp = userList[i];
							userList[i] = userList[i+1];
							userList[i+1] = otemp;
						}
					}
					catch (Exception e) {}
				}
			} while (swap);
		}

		// Total Login
		else
		{
			String attName = "";
			if (sortby.equals("tl")) attName = "LoginNum";
			else if (sortby.equals("vb")) attName = "ViewBlogNum";
			else if (sortby.equals("wb")) attName = "WriteBlogNum";
			else if (sortby.equals("mt")) attName = "AttendMtgNum";

			PstAbstractObject o1, o2, otemp;
			Integer v1, v2;
			Integer least = new Integer(-1);
			boolean swap;
			do
			{
				swap = false;
				for (int i=0; i<userList.length-1; i++)
				{
					o1 = uiList[i];
					o2 = uiList[i+1];
					try
					{
						if (o1 == null) v1 = null;
						else v1 = (Integer)o1.getAttribute(attName)[0];
						if (o2 == null) v2 = null;
						else v2 = (Integer)o2.getAttribute(attName)[0];
						if (v1 == null) v1 = least;
						if (v2 == null) v2 = least;
						if (v2.compareTo(v1)>0)
							swap = true;

						if (swap)
						{
							// swap the element
							uiList[i]   = o2;
							uiList[i+1] = o1;
							otemp = userList[i];
							userList[i] = userList[i+1];
							userList[i+1] = otemp;
						}
					}
					catch (Exception e) {}
				}
			} while (swap);
		}
	}

	boolean even = false;
	String bgcolor = "";
	String bgcl = "bgcolor='#6699cc'";
	String srcl = "bgcolor='#66cc99'";
%>

<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="../init.jsp" flush="true" />

<script type="text/javascript">
<!--

function showInactive(num)
{
	var e = document.getElementById("totalInactiveTD");
	e.innerHTML = "<b>" + num + "</b>";
}

function sort(name)
{
	ShowUser.sortby.value = name;
	ShowUser.submit();
}
//-->
</script>

<title>
	<%=app%>
</title>

</head>

<body text="#000000" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="715" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td width="26">&nbsp;</td>
	<td valign="top">

	<b class="head">

	User Statistics By Project

	</b><br><br>
	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- CONTENT -->
<p>

		 <table width="90%" border="0" cellspacing="0" cellpadding="0">


			<tr><td colspan="2">&nbsp;</td></tr>
			<tr>
				<td width="20"><img src="../i/spacer.gif" width="5" border="0"></td>
				<td>

<!-- Project Name -->
	<table width="100%" border="0" cellpadding="0" cellspacing="0">

	<tr>
<form name="ShowUser">
<input type="hidden" name="sortby" value="">

	<td class="heading">
		Project Name:&nbsp;&nbsp;
		<select name="projId" class="formtext" onchange="submit()">
<%
		out.print(Util.selectProject(pstuser, viewProjId, true));
%>

		</select>

	</td>
</form>

<table width="100%" border="0" cellspacing="0" cellpadding="0">

<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>

<tr>
	<td><table>
		<tr>
			<td class='ptextS2' width='250'>Total # of Registered User: </td>
			<td class='ptextS2' align='right'><b><%=totalRegUser%></b></td>
		</tr>
		<tr>
			<td class='ptextS2'>Total # of Inactive User: </td>
			<td class='ptextS2' id='totalInactiveTD' align='right'></td>
		</tr>
	</table></td>
</tr>

<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>

<tr>
<td>
<table width="100%" border="0" cellspacing="0" cellpadding="0">
	<tr>
		<td colspan="20" height="2" ><img src="../i/spacer.gif" width="2" height="2"></td>
	</tr>
	<tr>
		<td colspan="20" height="2" bgcolor="#EBECED"><img src="../i/spacer.gif" width="2" height="2"></td>
	</tr>
	<tr>
		<td colspan="20" height="2" bgcolor="#336699"><img src="../i/spacer.gif" width="2" height="2"></td>
	</tr>
	<tr>
<%	if (sortby==null)
	{
		out.print("<td width='4' " + srcl + " class='10ptype'>&nbsp;</td>");
		out.print("<td width='25%' " + srcl + " class='td_header'><strong>&nbsp;Member Name</strong></td>");
	}
	else
	{
		out.print("<td width='4' " + bgcl + ">&nbsp;</td>");
		out.print("<td width='25%' class='td_header' " + bgcl + "><a href='javascript:sort(\"\")'><font color='ffffff'><strong>&nbsp;Member Name</strong></font></a>");
	}
%>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td bgcolor="#6699cc" class='td_header' align='center'><strong>Authorized Department</strong></td>
	
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
<%	if (sortby!=null && sortby.equals("lg"))
	{
		out.print("<td width='4' " + srcl + ">&nbsp;</td>");
		out.print("<td width='150' class='td_header' " + srcl + " align='center'><strong>Last Login</strong></td>");
	}
	else
	{
		out.print("<td width='4' " + bgcl + ">&nbsp;</td>");
		out.print("<td width='150' class='td_header' " + bgcl + " align='center'><a href='javascript:sort(\"lg\")'><font color='ffffff'><strong>Last Login</strong></font></a></td>");
	}
%>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
<%	if (sortby!=null && sortby.equals("tl"))
	{
		out.print("<td width='4' " + srcl + ">&nbsp;</td>");
		out.print("<td width='80' class='td_header' " + srcl + "><strong>Total Login</strong></td>");
	}
	else
	{
		out.print("<td width='4' " + bgcl + ">&nbsp;</td>");
		out.print("<td width='80' class='td_header' " + bgcl + "><a href='javascript:sort(\"tl\")'><font color='ffffff'><strong>Total Login</strong></font></a></td>");
	}
%>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
<%if (!isCRAPP){	
	if (sortby!=null && sortby.equals("vb"))
	{
		out.print("<td width='4' " + srcl + ">&nbsp;</td>");
		out.print("<td width='80' class='td_header' " + srcl + "><strong>View Blog</strong></td>");
	}
	else
	{
		out.print("<td width='4' " + bgcl + ">&nbsp;</td>");
		out.print("<td width='80' class='td_header' " + bgcl + "><a href='javascript:sort(\"vb\")'><font color='ffffff'><strong>View Blog</strong></font></a></td>");
	}
%>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
<%	if (sortby!=null && sortby.equals("wb"))
	{
		out.print("<td width='4' " + srcl + ">&nbsp;</td>");
		out.print("<td width='80' class='td_header' " + srcl + "><strong>Write Blog</strong></td>");
	}
	else
	{
		out.print("<td width='4' " + bgcl + ">&nbsp;</td>");
		out.print("<td width='80' class='td_header' " + bgcl + "><a href='javascript:sort(\"wb\")'><font color='ffffff'><strong>Write Blog</strong></font></a></td>");
	}
%>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
<%	if (sortby!=null && sortby.equals("mt"))
	{
		out.print("<td width='4' " + srcl + ">&nbsp;</td>");
		out.print("<td width='90' class='td_header' " + srcl + "><strong>Mtg Attended</strong></td>");
	}
	else
	{
		out.print("<td width='4' " + bgcl + ">&nbsp;</td>");
		out.print("<td width='90' class='td_header' " + bgcl + "><a href='javascript:sort(\"mt\")'><font color='ffffff'><strong>Mtg Attended</strong></font></a></td>");
	}
}
%>

	</tr>

<%
	int ct = 1;
	String deptName = null;
	for(int i = 0; userList!=null && i<userList.length; i++)
	{
		// a list of user
		u = (user)userList[i];
		if (u==null) continue;

		// user info
		ui = (userinfo)uiList[i];
		if (ui == null) {
			System.out.println("Error: null userinfo found for [" + u.getObjectId() + "], remove user object");
			//if (!u.getObjectName().equals("guest"))
			//	uMgr.delete(u);
			continue;
		}

		uid = u.getObjectId();
		s = (String)u.getAttribute("FirstName")[0];
		uname = (String)u.getAttribute("LastName")[0];
		if (uname==null) System.out.println("***** null user: uid="+uid);
		uname = s + (uname==null?"":(" " + uname));

		if (even)
			bgcolor = "bgcolor='#EEEEEE'";
		else
			bgcolor = "bgcolor='#ffffff'";
		even = !even;
		out.print("<tr " + bgcolor + ">");

		// user name
		if (u.isInactive()) {
			uname += "&nbsp;&nbsp;<span class='error'>** INACTIVE **</span>";
			totalInactive++;
		}
		
		out.print("<td class='10ptype'><img src='../i/spacer.gif' width='5' height='20'/></td>");
		out.print("<td class='listtext' valign='middle' align='left'>");
		out.print("<a href='../ep/ep1.jsp?uid=" + uid + "'>" + ct++ + ".&nbsp;&nbsp;"
			+ uname + "</a></td>");
		
		// @ECC071607 DepartmentName
		deptName = (String)u.getAttribute("DepartmentName")[0];
		if (deptName == null) deptName = "";
		else deptName = deptName.replaceAll("-", "; ");
		out.print("<td class='10ptype'><img src='../i/spacer.gif' width='2'></td>");
		out.print("<td></td>");
		out.print("<td class='listtext_small' width='120' valign='top' align='center'>");
		out.print(deptName + "</td>");

		// last login
		lastLogin = (Date)ui.getAttribute("LastLogin")[0];
		if (lastLogin != null)
			s = df.format(lastLogin);
		else
			s = "-";
		out.print("<td class='10ptype'><img src='../i/spacer.gif' width='2'></td>");
		out.print("<td></td>");
		out.print("<td class='listtext_small' valign='top' align='center'>");
		out.print(s + "</td>");
		
		// total login num
		iObj = (Integer)ui.getAttribute("LoginNum")[0];
		if (iObj != null)
			s = iObj.toString();
		else
			s = "-";
		
		out.print("<td class='10ptype'><img src='../i/spacer.gif' width='2'></td>");
		out.print("<td></td>");
		out.print("<td class='homenewsteaser' align='right' valign='top'>");
		out.print(s + "&nbsp;&nbsp;</td>");

		if (!isCRAPP){
			// view blog
			iObj = (Integer)ui.getAttribute("ViewBlogNum")[0];
			if (iObj != null)
				s = iObj.toString();
			else
				s = "-";
			out.print("<td class='10ptype'><img src='../i/spacer.gif' width='2'></td>");
			out.print("<td></td>");
			out.print("<td class='homenewsteaser' align='right'>");
			out.print(s + "&nbsp;&nbsp;</td>");
	
			// write blog
			iObj = (Integer)ui.getAttribute("WriteBlogNum")[0];
			if (iObj != null)
				s = iObj.toString();
			else
				s = "-";
			out.print("<td class='10ptype'><img src='../i/spacer.gif' width='2'></td>");
			out.print("<td></td>");
			out.print("<td class='homenewsteaser' align='right' valign='top'>");
			out.print(s + "&nbsp;&nbsp;</td>");
			
			// attended meetings
			iObj = (Integer)ui.getAttribute("AttendMtgNum")[0];
			if (iObj != null)
				s = iObj.toString();
			else
				s = "-";

			out.print("<td class='10ptype'><img src='../i/spacer.gif' width='2'></td>");
			out.print("<td></td>");
			out.print("<td class='homenewsteaser' align='right' valign='top'>");
			out.print(s + "&nbsp;&nbsp;</td>");
		}
		out.print("</tr>");
		out.println("<tr " + bgcolor + ">" + "<td colspan='20'><img src='../i/spacer.gif' width='2' height='2'></td></tr>");
	}	// End else for
%>
</table>
</td></tr>

</table>

</form>
</p>


<p align="center">
<input type='button' class='medium_button' value='Back' onclick="location='admin.jsp';">
</p>

	</td>
</tr>

<tr><td>&nbsp;</td><tr>

<script type="text/javascript">
showInactive(<%=totalInactive%>);
</script>

<!-- BEGIN FOOTER TABLE -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

