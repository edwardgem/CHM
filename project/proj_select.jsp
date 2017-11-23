<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: proj_select.jsp
//	Author: ECC
//	Date:	10/18/04
//	Description: Empty page to direct user to select a project.
//	Modification:
//			@041906SSI	Added sort function to Project names.
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
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "util.*" %>

<%
	String backPage = request.getParameter("backPage");
	String noSession = "../out.jsp?go=project/proj_select.jsp?backPage="+backPage;
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%
	////////////////////////////////////////////////////////
	final String HEAD_LINE =
		"<table border='0' cellspacing='0' cellpadding='0'>"
		+ "<tr><td><img src='../i/spacer.gif' width='5' height='1' /></td><td bgcolor='#ee0000'><img src='../i/spacer.gif' height='1' width='30' /></td><td width='100'></td></tr>"
		+ "<tr><td></td><td colspan='2' width='150' bgcolor='#ee0000'><img src='../i/spacer.gif' width='100' height='1' /></td></tr>"
		+ "</table>";

		if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	projectManager pjMgr = projectManager.getInstance();
	int [] projectObjId;
	int myUid = pstuser.getObjectId();

	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ( (iRole & user.iROLE_ADMIN) > 0 )
		isAdmin = true;

	boolean isCRAPP = Prm.isCR();
	boolean isMeetWE = Prm.isMeetWE();
	String app = Prm.getAppTitle();
	
	if (backPage == null || backPage.equals("null")) {
		if (!isCRAPP)
			backPage = "../blog/blog_task.jsp";				// proj_top.jsp
		else
			backPage = "cr.jsp";
	}
		
	// first try using my last project
	String lastProjIdS = (String)pstuser.getAttribute("LastProject")[0];
	if (!StringUtil.isNullOrEmptyString(lastProjIdS)) {
		try {
			pjMgr.get(pstuser, Integer.parseInt(lastProjIdS));	// make sure the project is valid
			response.sendRedirect(backPage + "?projId=" + lastProjIdS);
			return;
		}
		catch (Exception e) {}
	}
	else {
		// second try using my personal space as a project if it exist
		projectObjId = pjMgr.findId(pstuser, "Owner='" + myUid + "' && Option='%" + project.PERSONAL + "%'");
		if (projectObjId.length > 0) {
			// found personal space, just use it
			try {
				pjMgr.get(pstuser, projectObjId[0]);	// make sure the project is valid
				response.sendRedirect(backPage + "?projId=" + projectObjId[0]);
				return;
			}
			catch (Exception e) {}
		}
	}
		
	// user has to select a project

	String label1 = "Plan";
	if (isCRAPP || isMeetWE)
		label1 = "Space";

	String pageTitle = null;
	boolean isReview = false;

	if (backPage.indexOf("review") != -1)
	{
		pageTitle = "Project Review";
		isReview = true;
	}
	else
	{
		pageTitle = "Project " + label1;
	}

	// if I am here, I will need to refresh the planStack
	session.removeAttribute("planStack");

	////////////////////////////////////////////////////////

%>


<head>
<title><%=app%></title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="../init.jsp" flush="true"/>

</head>

<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" height="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">
		<!-- Main Tables -->
		<table width="90%" border="0" cellspacing="0" cellpadding="0">
		  	<tr>
		    	<td width="100%" valign="top">
					<!-- Top -->
					<jsp:include page="../head.jsp" flush="true"/>
					<!-- End of Top -->
				</td>
			</tr>
			<tr>
	          <td>
	            <table width="100%" border="0" cellspacing="0" cellpadding="0">
					<tr>
					<td width="26" height="28"><a name="top">&nbsp;</a></td>
                	<td height="28" align="left" valign="bottom" class="head">
						<b><%=pageTitle%></b>
					</td></tr>
	            </table>
	          </td>
	        </tr>
			<tr>
          		<td width="100%">
					<!-- Navigation Menu -->
<%if (isReview) {%>
					<jsp:include page="../in/ireview.jsp" flush="true">
					<jsp:param name="role" value="<%=iRole%>" />
					</jsp:include>
<%} else if (isMeetWE) {%>
					<jsp:include page="../in/home.jsp" flush="true">
					<jsp:param name="role" value="<%=iRole%>" />
					</jsp:include>
<%} else {%>
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Project" />
				<jsp:param name="subCat" value="" />
				<jsp:param name="role" value="<%=iRole%>" />
			</jsp:include>
<%}%>
					<!-- End of Navigation Menu -->
				</td>
	        </tr>
			<tr>
          		<td width="100%" valign="top">
					<!-- Navigation SUB-Menu -->
					<!-- End of Navigation SUB-Menu -->
				</td>
	        </tr>
		</table>
		<!-- Content Table -->

		 <table border="0" cellspacing="0" cellpadding="0">


			<tr><td colspan="2">&nbsp;</td></tr>
			<tr>
				<td width="20"><img src="../i/spacer.gif" width="5" border="0"></td>
				<td width="100%">

<!-- Project Name -->
	<table border="0" cellpadding="0" cellspacing="0">

<%
	String tidS = "";
	if (isMeetWE)
	{
		tidS = request.getParameter("cid");
		projectObjId = pjMgr.findId(pstuser, "TownID='" + tidS + "'");
	}
	else {
		tidS = (String)pstuser.getAttribute("Company")[0];
		projectObjId = pjMgr.getProjects(pstuser);
	}
	
	out.println("<tr><td width='20'>&nbsp;</td>");
	
	if (projectObjId.length > 0)
	{
		out.print("<td class='plaintext_big'>");
		out.print("Please select a project from below:<br><br>");
		out.print("<table border='0' cellpadding='0' cellspacing='0'>");

		PstAbstractObject [] projectObjList = pjMgr.get(pstuser, projectObjId);
		//@041906SSI
		Util.sortName(projectObjList, true);

		String projName;
		project pj;
		Date expDate;
		String expDateS = new String();
		for (int i=0; i < projectObjList.length ; i++)
		{
			// project
			pj = (project) projectObjList[i];
			projName = pj.getDisplayName();

			out.print("<tr><td></td><td class='ptextS2' style='line-height:25px;'><img src='../i/bullet_tri.gif'>&nbsp;&nbsp;<a href='../project/"
				+ backPage + "?projId=" + pj.getObjectId() + "'>" + projName + "</a></td></tr>");
		}
		out.print("</table></td></tr>");
	}
	else
	{
		out.print("<td class='pTextS2'>");
		if (tidS != null) {
			String townName = (String)townManager.getInstance().get(pstuser, Integer.parseInt(tidS)).getAttribute("Name")[0];
			out.print("There is no project for you in " + townName + ".");
		}
		else {
			out.print("There is no project for you.");
		}
	}
	out.print("<tr><td><img src='../i/spacer.gif' height='20' /></td></tr>");

	out.print("<tr><td></td><td>" + HEAD_LINE + "</td></tr>");
	out.print("<tr><td><img src='../i/spacer.gif' height='5' /></td></tr>");

	out.print("<tr><td></td><td class='ptextS3'>&nbsp;");
	out.print("<a href='../project/proj_new1.jsp?tid=" + tidS + "'>Click to add a new project</a>");
	out.print("</td></tr>");
	
	out.print("<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>");

%>
	</table>


		<!-- End of Content Table -->
		<!-- End of Main Tables -->
	</td>
</tr>
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
