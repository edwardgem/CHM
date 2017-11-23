<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: action_updall.jsp
//	Author: ECC
//	Date:	09/09/05
//	Description: Allow updating selected fields of action, decision, issue.
//
//	Modification:
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
<%@ page import = "util.JwTask" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");
	
	String projIdS = request.getParameter("projId");
	String noSession = "../out.jsp?go=project/action_updall.jsp?projId="+projIdS;
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%
	////////////////////////////////////////////////////////
	if (pstuser instanceof PstGuest || projIdS==null)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
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

	projectManager pjMgr = projectManager.getInstance();
	actionManager aMgr = actionManager.getInstance();
	userManager uMgr = userManager.getInstance();
	bugManager bMgr = bugManager.getInstance();

	String s;
	String projName = null;
	project projObj = null;
	if (projIdS.length()==0)
	{
		projName = (String)session.getAttribute("projName");	// the case when projId is removed from an issue
		projObj = (project)pjMgr.get(pstuser, projName);
		projIdS = String.valueOf(projObj.getObjectId());
	}
	else
	{
		projName = PstManager.getNameById(pstuser, Integer.parseInt(projIdS));
		projObj = (project)pjMgr.get(pstuser, projName);
	}
	projName = projObj.getDisplayName();

	String coordinatorIdS = (String)projObj.getAttribute("Owner")[0];
	int coordinatorId = Integer.parseInt(coordinatorIdS);

	SimpleDateFormat df1 = new SimpleDateFormat ("MM/dd/yy");
	SimpleDateFormat df3 = new SimpleDateFormat ("MM/dd/yyyy");
	String todayS = df1.format(new Date());

	////////////////////////////////////////////////////////
%>


<head>
<title>Project Items</title>
<meta http-equiv="content-type" content="text/html; charset=utf-8"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../forms.jsp" flush="true"/>
<script language="JavaScript" src="../get-date.js"></script>

<script type="text/javascript">

<!--

function checkUpdate(e)
{
	e.checked = true;
}

function goBack()
{
	location = "proj_action.jsp?projId=<%=projIdS%>";
}
//-->
</script>

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
	            <table width="780" border="0" cellspacing="0" cellpadding="0">

					<tr><td colspan="2">&nbsp;</td></tr>
					<tr>
					<td></td>
					<td>
						<b class="head">Update Action, Decision and Issue</b>
					</td></tr>

					<tr>
					<td></td>
					<td valign="top" class="title">
						&nbsp;&nbsp;&nbsp;<%=projName%>
					</td>
					</tr>

	              <tr>
	                <td width="20">&nbsp;</td>
	                <td width="754">&nbsp;</td>
	              </tr>
	            </table>

	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>
	          </td>
	        </tr>

<!-- Navigation SUB-Menu -->
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
<td width="100%" valign="top">

	<table border="0" width="100%" height="14" cellspacing="0" cellpadding="0">
		<tr>
			<td bgcolor='#EBECED'><img src='../i/spacer.gif' width='10' height='1'/></td>
			<td valign="top" class="bgsubnav">
				<table border="0" cellspacing="0" cellpadding="0">
				<tr class="bgsubnav">
	<!-- Action Decision Issue -->
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"/></td>
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"/></td>
					<td><a href="../project/proj_action.jsp?projId=<%=projIdS%>" class="subnav">Action - Decision - Issue</a></td>
					<td colspan="3" width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"/></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"/></td>

	<!-- Update All -->
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"/></td>
					<td width="20" height="14"><img src="../i/nav_arrow.gif" width="20" height="14" border="0"/></td>
					<td><a href="#" onclick="return false;" class="subnav"><u>Update All</u></a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"/></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"/></td>

				</tr>
				</table>
			</td>
		</tr>
	</table>
	<table border="0" width="620" height="1" cellspacing="0" cellpadding="0">
		<tr>
			<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"/></td>
		</tr>
	</table>

</td>
</tr>
</table>
<!-- End of Navigation SUB-Menu -->

<!-- Content Table -->

<table width="90%" border="0" cellspacing="0" cellpadding="0">


<tr>
	<td width="20">&nbsp;</td>
	<td colspan="2"></td>
</tr>

<!-- *************************   Page Headers   ************************* -->


<!-- //////////////////////////////////////////////////// -->

<!-- LIST OF ACTION / DECISION / ISSUE -->
<form method="post" name="updADI" action="post_updADI.jsp">
<input type="hidden" name="projId" value="<%=projIdS%>">

<%
	// for Action Item, Decision Records and Issues
	int [] ids;

	// get the list of action items
	s = "(ProjectID='" + projIdS + "') && (Type='" + action.TYPE_ACTION + "')";
	ids = aMgr.findId(pstuser, s);
	Arrays.sort(ids);
	PstAbstractObject [] aiObjList = aMgr.get(pstuser, ids);

	// decisions
	s = "(ProjectID='" + projIdS + "') && (Type='" + action.TYPE_DECISION + "')";
	ids = aMgr.findId(pstuser, s);
	Arrays.sort(ids);
	PstAbstractObject [] dsObjList = aMgr.get(pstuser, ids);

	// issues
	s = "(ProjectID='" + projIdS + "') && (Type='" + bug.CLASS_ISSUE + "')";
	ids = bMgr.findId(pstuser, s);
	Arrays.sort(ids);
	PstAbstractObject [] bgObjList = bMgr.get(pstuser, ids);

	// variables
	String bgcolor="";
	boolean even;

	String ownerIdS, midS, bugIdS, subject, priority, dot;
	user uObj;
	int aid, len;
	Object [] respA;
	Date expireDate, createdDate;
	action obj;

%>


<tr><td colspan="3"><a name="action">
	<img src="../i/spacer.gif" width="5" height="5"></a></td></tr>

<tr>
	<td>&nbsp;</td>
	<td colspan='2'>
	<table border="0" cellspacing="0" cellpadding="0">
		<tr>
			<td>
			<input type='button' class='button_medium' value='Submit' onclick='updADI.submit();'/>
			<img src='../i/spacer.gif' width='20' />
			<input type='button' class='button_medium' value='Cancel' onclick='goBack();'/>
			</td>
		</tr>

		<tr><td colspan='2' height="10"><img src="../i/spacer.gif" height="10" width="1" alt=" " /></td></tr>
	</table>
	</td>
</tr>


<!-- List of Action Items -->
<%
	String status;
	int ownerId;
	boolean found;

	if (aiObjList.length > 0) { %>
<tr>
	<td>&nbsp;</td>
	<td colspan="2">
		<table width="100%" border='0' cellpadding="0" cellspacing="0">
		<tr>
		<td bgcolor="#EBECED" height="3"><img src="../i/spacer.gif" width="1" height="3" border="0"/></td>
		</tr>
		</table>

		<table width="100%" border="0" cellspacing="0" cellpadding="0">
		<tr>
		<td colspan="14" height="2" bgcolor="#336699"><img src="../i/spacer.gif" width="2" height="2"></td>
		</tr>

		<tr>
		<td width="3" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td width="30" bgcolor="#6699cc" class="td_header" align="center"><strong>Update</strong></td>

		<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"/></td>
		<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td bgcolor="#6699cc" class="td_header"><strong>&nbsp;Action Item</strong></td>

		<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"/></td>
		<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td width="72" bgcolor="#6699cc" class="td_header" align="center"><strong>Status</strong></td>

		<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"/></td>
		<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td width="72" bgcolor="#6699cc" class="td_header" align="center"><strong>Priority</strong></td>

		<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"/></td>
		<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td width="65" bgcolor="#6699cc" class="td_header" align="center"><strong>Deadline</strong></td>

		</tr>

<%
	even = false;

	for (int i=0; i<aiObjList.length; i++)
	{	// the list of action item for this meeting object
		obj = (action)aiObjList[i];
		aid = obj.getObjectId();

		ownerIdS	= (String)obj.getAttribute("Owner")[0];
		ownerId 	= Integer.parseInt(ownerIdS);
		subject		= (String)obj.getAttribute("Subject")[0];
		priority	= (String)obj.getAttribute("Priority")[0];
		status		= (String)obj.getAttribute("Status")[0];
		expireDate	= (Date)obj.getAttribute("ExpireDate")[0];

		if (even)
			bgcolor = "bgcolor='#EEEEEE'";
		else
			bgcolor = "bgcolor='#ffffff'";
		even = !even;
		out.print("<tr " + bgcolor + ">");

		// update checkbox
		out.print("<td></td>");
		out.print("<td height='23' width='30' align='center'>");
		out.print("<input type='checkbox' name='updateA_" + aid + "'>");
		out.println("</td>");

		// Subject
		out.print("<td colspan='2'>&nbsp;</td>");
		out.print("<td valign='top'><table border='0'><tr>");
		out.print("<td class='ptextS2' valign='top' width='20'>" + (i+1) + ".</td>");
		out.print("<td class='ptextS2' valign='top'>");
		out.print(subject);
		out.println("</td></tr></table></td>");

		// Status {OPEN, LATE, CANCEL, DONE}
		out.print("<td colspan='2'></td><td width='72' align='center'>");
		out.print("<select class='formtext' name='Status_" + aid + "' onChange='checkUpdate(updADI.updateA_" + aid + ")'>");
		out.print("<option value='" + action.OPEN + "'");
		if (status.equals(action.OPEN) || status.equals(action.LATE)) out.print(" selected");
		out.print(">" + action.OPEN + "</option>");
		out.print("<option value='" + action.DONE + "'");
		if (status.equals(action.DONE)) out.print(" selected");
		out.print(">" + action.DONE + "</option>");
		out.print("<option value='" + action.CANCEL + "'");
		if (status.equals(action.CANCEL)) out.print(" selected");
		out.print(">" + action.CANCEL + "</option>");
		out.print("</select>");
		out.println("</td>");

		// Priority {HIGH, MEDIUM, LOW}
		out.print("<td colspan='2'></td><td width='72' align='center'>");
		out.print("<select class='formtext' name='Priority_" + aid + "' onChange='checkUpdate(updADI.updateA_" + aid + ")'>");
		out.print("<option value='" + action.PRI_LOW + "'");
		if (priority.equals(action.PRI_LOW)) out.print(" selected");
		out.print(">" + action.PRI_LOW + "</option>");
		out.print("<option value='" + action.PRI_MED + "'");
		if (priority.equals(action.PRI_MED)) out.print(" selected");
		out.print(">" + action.PRI_MED + "</option>");
		out.print("<option value='" + action.PRI_HIGH + "'");
		if (priority.equals(action.PRI_HIGH)) out.print(" selected");
		out.print(">" + action.PRI_HIGH + "</option>");
		out.print("</select>");
		out.println("</td>");

		// ExpireDate
		out.print("<td colspan='2'></td>");
		out.print("<td width='65'><input class='listtext' type='text' name='Expire_" + aid + "' size='8' value='");
		if (expireDate != null) out.print(df1.format(expireDate));
		out.print("' onChange='checkUpdate(updADI.updateA_" + aid + ")'></td>");


		out.println("</tr>");
		out.println("<tr " + bgcolor + ">" + "<td colspan='14'><img src='../i/spacer.gif' width='2' height='2'></td></tr>");
	}

%>
		</table>
	</td>
</tr>
<!-- End list of action items -->

<tr><td colspan="3"><img src="../i/spacer.gif" width="5" height="5"/></td></tr>
<%	}	// END: if aiObjList > 0 %>

<!-- List of Decision Records -->
<%	if (dsObjList.length > 0) { %>
<tr>
	<td>&nbsp;</td>
	<td colspan="2">
		<table width="100%" border='0' cellpadding="0" cellspacing="0">
		<tr>
		<td bgcolor="#EBECED" height="3"><img src="../i/spacer.gif" width="1" height="3" border="0"/></td>
		</tr>
		</table>

		<table width="100%" border="0" cellspacing="0" cellpadding="0">
		<tr>
		<td colspan="11" height="2" bgcolor="#336699"><img src="../i/spacer.gif" width="2" height="2"/></td>
		</tr>

		<tr>
		<td width="3" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td width="30" bgcolor="#6699cc" class="td_header" align="center"><strong>Update</strong></td>

		<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
		<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td bgcolor="#6699cc" class="td_header"><strong>&nbsp;Decision Record</strong></td>

		<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
		<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td width="72" bgcolor="#6699cc" class="td_header" align="center"><strong>Priority</strong></td>

		<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
		<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td width="65" bgcolor="#6699cc" class="td_header" align='center'><strong>Filed On</strong></td>

		</tr>

<%
	even = false;

	for (int i=0; i<dsObjList.length; i++)
	{	// the list of decision records for this meeting object
		obj = (action)dsObjList[i];
		aid = obj.getObjectId();

		subject		= (String)obj.getAttribute("Subject")[0];
		priority	= (String)obj.getAttribute("Priority")[0];
		createdDate	= (Date)obj.getAttribute("CreatedDate")[0];

		if (even)
			bgcolor = "bgcolor='#EEEEEE'";
		else
			bgcolor = "bgcolor='#ffffff'";
		even = !even;
		out.print("<tr " + bgcolor + ">");

		// update checkbox
		out.print("<td></td>");
		out.print("<td height='23' width='30' align='center'>");
		out.print("<input type='checkbox' name='updateD_" + aid + "'>");
		out.println("</td>");

		// Subject
		out.print("<td colspan='2'>&nbsp;</td>");
		out.print("<td valign='top'><table border='0'><tr>");
		out.print("<td class='ptextS2' valign='top' width='20'>" + (i+1) + ".</td>");
		out.print("<td class='ptextS2' valign='top'>");
		out.print(subject);
		out.println("</a></td></tr></table></td>");

		// Priority {HIGH, MEDIUM, LOW}
		out.print("<td colspan='2'></td><td width='72' align='center'>");
		out.print("<select class='formtext' name='Priority_" + aid + "' onChange='checkUpdate(updADI.updateD_" + aid + ")'>");
		out.print("<option value='" + action.PRI_LOW + "'");
		if (priority.equals(action.PRI_LOW)) out.print(" selected");
		out.print(">" + action.PRI_LOW + "</option>");
		out.print("<option value='" + action.PRI_MED + "'");
		if (priority.equals(action.PRI_MED)) out.print(" selected");
		out.print(">" + action.PRI_MED + "</option>");
		out.print("<option value='" + action.PRI_HIGH + "'");
		if (priority.equals(action.PRI_HIGH)) out.print(" selected");
		out.print(">" + action.PRI_HIGH + "</option>");
		out.print("</select>");
		out.println("</td>");

		// CreatedDate
		out.print("<td colspan='2'>&nbsp;</td>");
		out.print("<td class='listtext' width='65' align='center' valign='top'>");
		out.print(df1.format(createdDate));
		out.println("</td>");


		out.println("</tr>");
		out.println("<tr " + bgcolor + ">" + "<td colspan='11'><img src='../i/spacer.gif' width='2' height='2'></td></tr>");
	}

%>
		</table>
	</td>
</tr>
<!-- End list of decision records -->

<tr><td colspan="3"><img src="../i/spacer.gif" width="5" height="5"/></td></tr>
<%	}	// END: if dsObjList > 0 %>
</td>
<!-- List of Issues -->
<%	if (bgObjList.length > 0) { %>
<tr>
	<td>&nbsp;</td>
	<td colspan="2">
		<table width="100%" border='0' cellpadding="0" cellspacing="0">
		<tr>
		<td bgcolor="#EBECED" height="3"><img src="../i/spacer.gif" width="1" height="3" border="0"/></td>
		</tr>
		</table>

		<table width="100%" border="0" cellspacing="0" cellpadding="0">
		<tr>
		<td colspan="14" height="2" bgcolor="#336699"><img src="../i/spacer.gif" width="2" height="2"></td>
		</tr>

		<tr>
		<td width="3" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td width="30" bgcolor="#6699cc" class="td_header" align="center"><strong>Update</strong></td>

		<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"/></td>
		<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td bgcolor="#6699cc" class="td_header"><strong>&nbsp;Issue</strong></td>

		<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"/></td>
		<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td width="72" bgcolor="#6699cc" class="td_header" align="center"><strong>Status</strong></td>

		<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"/></td>
		<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td width="72" bgcolor="#6699cc" class="td_header" align="center"><strong>Priority</strong></td>

		<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"/></td>
		<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td width="65" bgcolor="#6699cc" class="td_header" align='center'><strong>Filed On</strong></td>

		</tr>

<%
	even = false;

	bug bObj;

	for (int i=0; i<bgObjList.length; i++)
	{	// the list of issues for this meeting object
		bObj = (bug)bgObjList[i];
		aid = bObj.getObjectId();

		subject		= (String)bObj.getAttribute("Synopsis")[0];
		status		= (String)bObj.getAttribute("State")[0];
		priority	= (String)bObj.getAttribute("Priority")[0];
		createdDate	= (Date)bObj.getAttribute("CreatedDate")[0];

		if (even)
			bgcolor = "bgcolor='#EEEEEE'";
		else
			bgcolor = "bgcolor='#ffffff'";
		even = !even;
		out.print("<tr " + bgcolor + ">");

		// update checkbox
		out.print("<td></td>");
		out.print("<td height='23' width='30' align='center'>");
		out.print("<input type='checkbox' name='updateI_" + aid + "'>");
		out.println("</td>");

		// Subject
		out.print("<td colspan='2'>&nbsp;</td>");
		out.print("<td valign='top'><table border='0'><tr>");
		out.print("<td class='ptextS2' valign='top' width='20'>" + (i+1) + ".</td>");
		out.print("<td class='ptextS2' valign='top'>");
		out.print(subject);
		out.println("</td></tr></table></td>");

		// Status {OPEN, CLOSE}
		out.print("<td colspan='2'></td><td width='72' align='center'>");
		out.print("<select class='formtext' name='Status_" + aid + "' onChange='checkUpdate(updADI.updateI_" + aid + ")'>");
		out.print("<option value='" + bug.OPEN + "'");
		if (status.equals(bug.OPEN)) out.print(" selected");
		out.print(">" + bug.OPEN + "</option>");
		out.print("<option value='" + bug.CLOSE + "'");
		if (status.equals(bug.CLOSE)) out.print(" selected");
		out.print(">" + bug.CLOSE + "</option>");
		out.print("</select>");
		out.println("</td>");

		// Priority {HIGH, MEDIUM, LOW}
		out.print("<td colspan='2'></td><td width='72' align='center'>");
		out.print("<select class='formtext' name='Priority_" + aid + "' onChange='checkUpdate(updADI.updateI_" + aid + ")'>");
		out.print("<option value='" + action.PRI_LOW + "'");
		if (priority.equals(action.PRI_LOW)) out.print(" selected");
		out.print(">" + action.PRI_LOW + "</option>");
		out.print("<option value='" + action.PRI_MED + "'");
		if (priority.equals(action.PRI_MED)) out.print(" selected");
		out.print(">" + action.PRI_MED + "</option>");
		out.print("<option value='" + action.PRI_HIGH + "'");
		if (priority.equals(action.PRI_HIGH)) out.print(" selected");
		out.print(">" + action.PRI_HIGH + "</option>");
		out.print("</select>");
		out.println("</td>");

		// CreatedDate
		out.print("<td colspan='2'>&nbsp;</td>");
		out.print("<td class='listtext' width='65' align='center' valign='top'>");
		out.print(df1.format(createdDate));
		out.println("</td>");


		out.println("</tr>");
		out.println("<tr " + bgcolor + ">" + "<td colspan='14'><img src='../i/spacer.gif' width='2' height='2'></td></tr>");
	}
%>
		</table>
	</td>
</tr>
<!-- End list of issues -->
<%	}	// END if bgObjList > 0 %>


<tr>
	<td>&nbsp;</td>
	<td colspan='2'>
	<table border="0" cellspacing="0" cellpadding="0">
		<tr><td colspan='2' height="10"><img src="../i/spacer.gif" height="10" width="1" alt=" " /></td></tr>

		<tr>
		<td height="23">
			<input type='button' class='button_medium' value='Submit' onclick='updADI.submit();'/>
			<img src='../i/spacer.gif' width='20' />
			<input type='button' class='button_medium' value='Cancel' onclick='goBack();'/>
		</td>
		</tr>

	</table>
	</td>
</tr>

</form>

<tr><td colspan="3"><img src="../i/spacer.gif" width="5" height="10"/></td></tr>


<!-- END LIST OF ACTION / DECISION / ISSUE -->


</table>


		<!-- End of Content Table -->
		<!-- End of Main Tables -->
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
