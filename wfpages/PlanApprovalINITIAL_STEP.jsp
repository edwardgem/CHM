<%@ page contentType="text/html; charset=utf-8"%>

<%
//
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: PlanApprovalINITIAL_STEP.jsp
//	Author: ECC
//	Date:	04/10/04
//	Description: Plan listing page for workflow
//
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>
<%@ page import = "util.*" %>

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

	String projId = request.getParameter("projId");


	PstManager objMgr;
	PstAbstractObject obj;
	Object [] Name;

	// project
	objMgr = projectManager.getInstance();
	obj = objMgr.get(pstuser, Integer.parseInt(projId));
	Name = new Object[1];
	Name[0] = (Object)obj.getObjectName();
	String projName = obj.getObjectName();					// actual name
	String projDispName = ((project)obj).getDisplayName();

	//Object [] Description = obj.getAttribute("Description");

	planManager targetObjMgr = planManager.getInstance();
	int [] targetObjIds = targetObjMgr.findId(pstuser,
		"Status='Latest' && ProjectID='" +projId+ "'");
	PstAbstractObject [] targetObjList = targetObjMgr.get(pstuser, targetObjIds);

	int [] alltargetObjIds = targetObjMgr.findId(pstuser,
		"(Status='Latest' || Status='Deprecated') && ProjectID='" + projId + "'");
	PstAbstractObject [] alltargetObjList = targetObjMgr.get(pstuser, alltargetObjIds);


	// Because there is only one Plan which is latest
	plan targetObj = (plan)targetObjList[0];		// latest plan

	//Object [] planVersion = targetObj.getAttribute("Version");
	String planVersionString = targetObj.getStringAttribute("Version");		//planVersion[0].toString();
	if (StringUtil.isNullOrEmptyString(planVersionString)) planVersionString = "1.0";
	String planmemname = targetObj.getObjectName();

	String newplanVersionString = "";
	try
	{
		int dot = planVersionString.lastIndexOf('.');
		int newPart = Integer.parseInt(planVersionString.substring(dot+1)) + 1;
		newplanVersionString = planVersionString.substring(0,dot+1) + newPart;
	}
	catch (Exception ee)
	{
		newplanVersionString = planVersionString + "1";
	}

	// Get plan task
	Stack planStack = (Stack)session.getAttribute("planStack");
	if((planStack == null) || planStack.empty())
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	Vector rPlan = (Vector)planStack.peek();
	
	// to check if session is CR or PRM
	boolean isCRAPP = false;
	String app = (String)session.getAttribute("app");
	if (app.equals("CR"))
		isCRAPP = true;
%>

<html>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">

<jsp:include page="../init.jsp" flush="true"/>

<title>
	<%=app%> Update Project Plan
</title>

</head>

<script language="JavaScript">
<!--


function selectAll()
{
	path = document.create;

	if (path.Version.value == "")
	{
		alert("New Version cannot be empty.");
		path.Version.focus();
		return false;
	}


<%
	for(int i = 0; i < alltargetObjList.length; i++)
	{
		plan targetObj1 = (plan)alltargetObjList[i];

		Object [] Version = targetObj1.getAttribute("Version");
%>
		if (path.Version.value == "<%=Version[0]%>")
		{
			alert("New Version cannot be duplicated.");
			path.Version.focus();
			return false;
		}
<% 	} %>

	if (path.Description.value == "")
	{
		alert("Remark cannot be empty.");
		path.Description.focus();
		return false;
	}

	return true;
}
//-->
</SCRIPT>

<body bgcolor="#FFFFFF" leftmargin="10" topmargin="10" marginwidth="0" marginheight="0">
<table width="715" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<table>
	<tr><td>
	<b class="head">
	Create a New Version of Project Plan
	</b>
	</td></tr>
	<tr><td valign="top" class="title">
		&nbsp;&nbsp;&nbsp;<%=projDispName%>
	</td>
	</td></tr>
	</table>

<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	<tr>
	<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	</tr>
</table>


<!-- Navigation SUB-Menu -->
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
<td width="100%" valign="top">

	<table border="0" width="100%" height="14" cellspacing="0" cellpadding="0">
		<tr>
			<td class='bgsubnav'><img src='../i/spacer.gif' width='80' height='1'/></td>
			<td valign="top" class="bgsubnav">
				<table border="0" cellspacing="0" cellpadding="0">
				<tr class="bgsubnav">
	<!-- File Repository -->
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<td width="20"><img src="../i/spacer.gif" width="10" height="1" border="0"></td>
					<td><a href="../project/cr.jsp?projId=<%=projId%>" class="subnav">File Repository</a></td>
					<td width="20"><img src="../i/spacer.gif" width="10" height="1" border="0"></td>
					
<%if (!isCRAPP){%>
	<!-- Project Plan -->
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="../project/proj_plan.jsp?projId=<%=projId%>" class="subnav">Project Plan</a></td>
					<td colspan="3" width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
<%} %>
					
	<!-- Create a New Plan Version -->
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<td width="20"><img src="../i/spacer.gif" width="7" height="1" border="0"></td>
					<td width="20" height="14"><img src="../i/nav_arrow.gif" width="20" height="14" border="0"></td>
					<td><a href="#" onClick="return false;" class="subnav"><u>Create New Version</u></a></td>
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
				</tr>
				</table>
			</td>
		</tr>
	</table>
	<table border="0" width="100%" height="1" cellspacing="0" cellpadding="0">
		<tr>
			<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
		</tr>
	</table>

</td>
</tr>
</table>
<!-- End of Navigation SUB-Menu -->


<!-- Content Table -->
 <table width="715" border="0" cellspacing="0" cellpadding="0">

	<tr>
		<td width="26"><img src="../i/spacer.gif" width="10" border="0"></td>
		<td class="plaintext_big">
			<p><em><font color='red'>* Please review the updated plan:</font></em></p>
			<table width="100%" border="0" cellspacing="0" cellpadding="0">
			<tr>
				<td>
<%


	String[] levelInfo = new String[10];
	// For insert choice 2
	String prelevelInfo = "";
	for(int i = 0; i < rPlan.size(); i++)
	{
		Hashtable rTask = (Hashtable)rPlan.elementAt(i);
		String status = (String)rTask.get("Status");
		String pName = (String)rTask.get("Name");
		Object [] pLevel = (Object [])rTask.get("Level");
		Object [] pOrder = (Object [])rTask.get("Order");
		Object [] pPreOrder = (Object [])rTask.get("PreOrder");

		int level = ((Integer)pLevel[0]).intValue();
		int order = ((Integer)pOrder[0]).intValue();

		int width = 5 + 22 * level;
		order++;
		if (level == 0)
		{
			levelInfo[level] = Integer.toString(order);
		}
		else
		{
			levelInfo[level] = levelInfo[level - 1] + "." + order;
		}
		level++;

		String picclass = "level" + level;

		out.println("<table width='100%' border='0' cellspacing='0' cellpadding='0' >");
		out.println("<tr><td width='" + width + "' height='20'>&nbsp;</td><td class='plaintext_big'>");
		switch (status.charAt(0))
		{
			case 'O':  // Original
				out.println(levelInfo[level-1] + ".&nbsp;" + "&nbsp;" + pName);
				break;
			case 'D':  // Old, Deprecated
				out.println("<strike>" + levelInfo[level-1] + ".&nbsp;" + "&nbsp;" + pName + "</strike>");
				break;
			case 'N':  // New
				out.println("<font color='red'>" + levelInfo[level-1] + ".&nbsp;" + "&nbsp;" + pName + "</font>");
				break;
			case 'C':  // Change
				out.println("<font color='green'>" + levelInfo[level-1] + ".&nbsp;" + "&nbsp;" + pName + "</font>");
				break;
		}
		out.println("</td></tr>");
		out.println("</table>");
	}

%>

							</td>
						</tr>
				</table>
				</td>
			</tr>

		</table>
<form method="post" name="create" action="postPlanApprovalINITIAL_STEP.jsp">
<input type="hidden" name="projName" value="<%=projName%>">
<input type="hidden" name="projId" value="<%=projId%>">
<input type="hidden" name="originalPlanName" value="<%=planmemname%>">
<table width="780" border="0" cellspacing="0" cellpadding="2">
  <tr>
    <td width="26" align="right"><img src="../i/spacer.gif" border="0" width="26" height="1"></td>
    <td width="754">&nbsp;</td>
  </tr>
  <tr>
  	<td>&nbsp;</td>
    <td class="plaintext_big">
		* Enter new version number and a remark about this new plan, then submit the changes for publication.
	</td>
  </tr>
  <tr>
    <td>&nbsp;</td>
    <td width="100%" valign="top">
		<table width="100%" border="0" cellspacing="2" cellpadding="4" bgcolor="#FFFFFF">
		  <tr>
		    <td width="165" class="td_field_bg" valign="top"><strong>Last Version Name:</strong></td>
		    <td width="607" class="td_value_bg"><%=planVersionString%></td>
		  </tr>
		  <tr>
		    <td width="165" class="td_field_bg" valign="top"><strong>Suggested New Version Name:</strong></td>
		    <td width="607" class="td_value_bg"><input type="text" name="Version" size="35" value="<%=newplanVersionString%>"></td>
		  </tr>
		  <tr>
		    <td width="165"  class="td_field_bg" valign="top"><strong>Remark:</strong></td>
		    <td width="607" class="td_value_bg"><textarea name="Description" rows="7" cols="60">Change to <%=newplanVersionString%></textarea></td>
		  </tr>
		</table>
		<table width="780" border="0" cellspacing="0" cellpadding="2">
		  <tr>
		    <td width="165" align="right">&nbsp;</td>
		    <td width="607">&nbsp;</td>
		  </tr>
		  <tr>
		    <td colspan="2" align="center">
				<input type='button' class='button_medium' onclick='document.create.submit();' value='Submit' style='width:100px';>
				&nbsp;&nbsp;
				<input type='button' class='button_medium' onclick='history.back(-1);' value='Cancel' style='width:100px';>
		    </td>
		  </tr>
		</table>
	</td>
  </tr>
</table>

 </form>
  <!-- End of Content Table -->
		<!-- End of Main Tables -->
	</td>
</tr>

<!-- Footer -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- End of Footer -->

</table>
</body>
</html>
