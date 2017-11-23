<%
////////////////////////////////////////////////////
//	Copyright (c) 2004-2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	wf.jsp
//	Author:	ECC
//	Date:	04/22/05
//	Description:
//		Workflow management.
//	Modification:
//
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "oct.pep.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "util.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ((pstuser instanceof PstGuest) || ((iRole & user.iROLE_ADMIN) == 0) )
	{
		response.sendRedirect("/error.jsp?msg=Access declined");
		return;
	}

	// get all the workflow object
	PstFlowManager fMgr = PstFlowManager.getInstance();
	int [] fId = fMgr.findId(pstuser, "om_acctname='%'");
	PstAbstractObject [] fObjList = fMgr.get(pstuser, fId);

	// sort the flow instance by create date.  Display latest postings first.
	Util.sortDate(fObjList, "CreatedDate");

	boolean even = false;
	String bgcolor = "";
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="../init.jsp" flush="true" />

<title>
	<%=session.getAttribute("app")%>
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

	Workflow Management

	</b><br><br>
	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- CONTENT -->
<p>
	<form method="post" name="deleteWF" action="post_delWF.jsp">
	<table width="770" border="0" cellspacing="0" cellpadding="0">
		<tr>
		<td width="26">&nbsp;</td>
		<td class="homenewsheader" valign="bottom">
			Workflow Instances
		</td>
<%	if (fObjList.length > 0)
	{%>
		<td valign="bottom" align="right">
			<a href="javascript:document.deleteWF.submit()" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('delete','','../i/deln.gif',1)"><img src="../i/delf.gif" name="delete" border="0"></a>
		</td>
<%	}%>
		</tr>
	</table>

<table width="770" border="0" cellspacing="0" cellpadding="0">
<tr>
<td>
<table width="100%" border="0" cellspacing="0" cellpadding="0">
	<tr>
		<td colspan="14" height="2" ><img src="../i/spacer.gif" width="2" height="2"></td>
	</tr>
	<tr>
		<td colspan="14" height="2" bgcolor="#336699"><img src="../i/spacer.gif" width="2" height="2"></td>
	</tr>
	<tr>
		<td width="3"  bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td width="80" bgcolor="#6699cc" class="td_header"><strong>Workflow ID</strong></td>
		<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2"></td>
		<td width="3"  bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td width="100" bgcolor="#6699cc" class="td_header"><strong>Creator</strong></td>
		<td width="2"  bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2"></td>
		<td width="3"  bgcolor="#6699cc" class="10ptype"><img src="../i/spacer.gif"></td>
		<td bgcolor="#6699cc" class="td_header"><strong>Create Date</strong></td>
		<td width="2"  bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2"></td>
		<td width="3"  bgcolor="#6699cc" class="10ptype"><img src="../i/spacer.gif"></td>
		<td width="50" bgcolor="#6699cc" class="td_header"><strong>Status</strong></td>
		<td width="2"  bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2"></td>
		<td width="3"  bgcolor="#6699cc" class="10ptype"><img src="../i/spacer.gif"></td>
		<td width="50" bgcolor="#6699cc" class="td_header"><strong>Delete</strong></td>
	</tr>

<%

String status, uname, bText;
Object bTextObj;
SimpleDateFormat Formatter = new SimpleDateFormat ("MM/dd/yyyy");
user u;
userManager uMgr = userManager.getInstance();

if (fObjList.length <= 0)
{
%>
	<tr>
		<td class="10ptype">&nbsp;</td>
		<td colspan="14" class="homenewsteaser" <%=bgcolor%>>
			There is no workflow object in the database
		</td>
	</tr>
<%
}
else for(int i = 0; i < fObjList.length; i++)
{
	// a list of flow instance messages
	PstFlow fObj = (PstFlow) fObjList[i];
	try
	{
		u = (user)uMgr.get(pstuser, (String)fObj.getAttribute("Owner")[0]);
		uname = (String)u.getAttribute("FirstName")[0] + " " + (String)u.getAttribute("LastName")[0];
	}
	catch (PmpException e)
	{
		uname = "-";
	}
	status = (String)fObj.getAttribute("State")[0];

	if (even)
		bgcolor = "bgcolor='#EEEEEE'";
	else
		bgcolor = "bgcolor='#ffffff'";
	even = !even;
%>
	<tr <%=bgcolor%>>
		<td class="10ptype">&nbsp;</td>
		<td width="80" class="homenewsteaser" valign="top">
			<%=fObj.getObjectId()%></td>
		<td class="10ptype"><img src="../i/spacer.gif" width="2"></td>
		<td class="10ptype" >&nbsp;</td>
		<td width="100" class="homenewsteaser" valign="top">
			<%=uname%></td>
		<td class="10ptype"><img src="../i/spacer.gif" width="2"></td>
		<td class="10ptype" >&nbsp;</td>
		<td width="65" class="homenewsteaser" valign="top">
			<%=Formatter.format((Date)fObj.getAttribute("CreatedDate")[0])%></td>
		<td class="10ptype"><img src="../i/spacer.gif" width="2"></td>
		<td class="10ptype" >&nbsp;</td>
		<td class="homenewsteaser" <%=bgcolor%>><%=status%></a></td>
		<td class="10ptype"><img src="../i/spacer.gif" width="2"></td>
		<td class="10ptype" >&nbsp;</td>
		<td class="homenewsteaser" align="center" valign="top">
			<input type="checkbox" name="delete_<%=fObj.getObjectId()%>"></td>
	</tr>
<%	}	// End else for
%>
</table>
</td></tr>
</table>

</form>
</p>


<p align="center">
<a href="admin.jsp" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('backBtn','','../i/bakn.gif',1)"><img src="../i/bakf.gif" border="0" name="backBtn"></a>
</p>

	</td>
</tr>

<tr><td>&nbsp;</td><tr>


<!-- BEGIN FOOTER TABLE -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

