
<%
////////////////////////////////////////////////////
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	all_attmt.jsp
//	Author:	ECC
//	Date:	10/18/04
//	Description:
//		Display all project and task attachments.
//	Modification:
//
//
////////////////////////////////////////////////////////////////////
%>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>
<%@ page import = "util.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	String projIdS = request.getParameter("projId");
	if ((pstuser instanceof PstGuest) || (projIdS == null))
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	String backPage = "../project/proj_profile.jsp?projId=" + projIdS;
	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ( (iRole & user.iROLE_ADMIN) > 0 )
		isAdmin = true;

	project proj = (project)projectManager.getInstance().get(pstuser, Integer.parseInt(projIdS));
	String projName = proj.getObjectName();

	int uid = pstuser.getObjectId();

	String coordinatorIdS = (String)proj.getAttribute("Owner")[0];
	int coordinatorId = Integer.parseInt(coordinatorIdS);

	String host = Util.getPropKey("pst", "PRM_HOST");

%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">

<jsp:include page="../init.jsp" flush="true"/>

<title>
	PRM View Attachments
</title>

</head>


<link rel="stylesheet" href="../ss/css.css">

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
					<b class="head">
					Project Profile
					</b>
					</td></tr>

	              <tr>
	                <td width="20">&nbsp;</td>
	                <td width="754">&nbsp;</td>
	              </tr>
	            </table>
	          </td>
	        </tr>
			<tr>
          		<td width="100%">
					<!-- Navigation Menu -->
					<jsp:include page="../in/iproj.jsp" flush="true">
					<jsp:param name="role" value="<%=iRole%>" />
					</jsp:include>
					<!-- End of Navigation Menu -->
				</td>
	        </tr>
			<tr>
          		<td width="100%" valign="top">
					<!-- Navigation SUB-Menu -->
					<table border="0" width="620" height="1" cellspacing="0" cellpadding="0">
						<tr>
							<td width="20" height="1" bgcolor="#FFFFFF"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
							<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
						</tr>
					</table>
					<table border="0" width="620" height="14" cellspacing="0" cellpadding="0">
						<tr>
							<td width="20" height="14" bgcolor="#FFFFFF"><img src="../i/spacer.gif" height="1" border="0"></td>
							<td valign="top" align="right" class="BgSubnav">
								<table border="0" cellspacing="0" cellpadding="0">
								<tr class="BgSubnav">
					<!-- Current Plan -->
									<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
									<td width="7"><img src="../i/spacer.gif" width="7" height="1" border="0"></td>
									<td><a href="proj_plan.jsp?projName=<%=projName%>" class="subnav">Current Plan</a></td>
									<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
									<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<!-- Project Profile -->
									<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
									<td><a href="proj_profile.jsp?projId=<%=projIdS%>" class="subnav">Project Profile</a></td>
									<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
									<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<!-- Update Project Plan -->
<%	if (uid == coordinatorId)
	{%>
									<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
									<td><a href="../plan/updplan.jsp?projId=<%=projIdS%>" class="subnav">Update Project Plan</a></td>
									<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
									<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
<%	}%>
					<!-- View All Attachments -->
									<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
									<td width="15" height="14"><img src="../i/nav_arrow.gif" width="20" height="14" border="0"></td>
									<td><a href="#" class="subnav" onclick="return false;"><u>View All Attachments</u></a></td>
									<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
								</tr>
								</table>
							</td>
						</tr>
					</table>
					<table border="0" width="620" height="1" cellspacing="0" cellpadding="0">
						<tr>
							<td width="20" height="1" bgcolor="#FFFFFF"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
							<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
						</tr>
					</table>
					<!-- End of Navigation SUB-Menu -->
				</td>
	        </tr>
		</table>
		<!-- Content Table -->

		 <table width="760" border="0" cellspacing="0" cellpadding="0">


			<tr><td colspan="2">&nbsp;</td></tr>
			<tr>
				<td width="20"><img src="../i/spacer.gif" width="5" border="0"></td>
				<td width="734">

<!-- Page Headers -->
		 <table width="100%" border="0" cellpadding="0" cellspacing="0">
			<tr>
				<td width="450" class="heading">
				<font size="3"><%=proj.getObjectName()%></font>
				</td>
			</tr>
		</table>

				</td>
			</tr>
		</table>



<!-- BEGIN INTERNAL CELL -->

	<br>
	<table width="760" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>



<!-- CONTENT LEFT -->
<table width="100%" border="0" cellspacing="0" cellpadding="0">

<tr>

<td width="700" valign="top">



<!-- PROJ PROFILE -->
<table height="110" width="100%" border="0">
	<tr>
		<td width="15">&nbsp;</td>
		<td width="150">&nbsp;</td>
		<td>&nbsp;</td>
	</tr>

<!-- *********** FILES *********** -->
<%
	Object [] attmtList = proj.getAttribute("Attachment");
// @AGQ042006
	ArrayList statusRepList = new ArrayList();
	ArrayList attmtArrList = new ArrayList();
	String summaryDoc = null;
	String msProjDoc = null;
	String attmt = null;
	for (int i=0; i<attmtList.length; i++)
	{
		attmt = (String)attmtList[i];
		if (attmt == null) break;
		if (summaryDoc==null && attmt.startsWith("PRM_" + projIdS))
		{
			summaryDoc = attmt;
		}
		else if (msProjDoc==null && attmt.startsWith("PRM_MSP_" + projIdS))
		{
			msProjDoc = attmt;
		}
		else if (attmt.startsWith("PrmReport_" + projName))
		{
			statusRepList.add(attmt);
		}
		else 
		{
			attmtArrList.add(attmt);
		}
	}
%>

<!-- project summary -->
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext" width="150" valign="top"><b>Project Summary:</b></td>
		<td class="plaintext" valign="top">
			<table border="0" cellspacing="0" cellpadding="2">
			<tr>
<%			if (summaryDoc == null)
			{%>
				<td class="plaintext_grey" width="250">None</td>
<%			} else
			{%>
				<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
				<td class="plaintext" width="250">
					<a class="listlink" href="<%=host%>/servlet/ShowFile?filePath=<%=projIdS%>/Attachment-<%=summaryDoc%>"><%=summaryDoc%></a>
				</td>
<%			}%>

			</tr>
			</table>
		</td>
	</tr>

<!-- MS Project -->
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext" width="150" valign="top"><b>MS Project File:</b></td>
		<td class="plaintext" valign="top">
			<table border="0" cellspacing="0" cellpadding="2">
			<tr>
<%			if (msProjDoc == null)
			{%>
				<td class="plaintext_grey" width="250">None</td>
<%			} else
			{%>
				<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
				<td class="plaintext" width="250">
					<a class="listlink" href="<%=host%>/servlet/ShowFile?filePath=<%=projIdS%>/Attachment-<%=msProjDoc%>"><%=msProjDoc%></a>
				</td>
<%			}%>

			</tr>
			</table>
		</td>
	</tr>

<!-- Status Reports -->
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext" width="150" valign="top"><b>Status Reports:</b></td>
		<td class="plaintext" valign="top">
			<table width="100%" border="0" cellspacing="0" cellpadding="2">
<%
	// file name is: Attachment-name of doc.ext
	int size = statusRepList.size();
	if (size == 0)
	{%>
		<tr><td class="plaintext_grey">None</td></tr>
<%	}
	else
	{
		boolean even = false;
		Collections.sort(statusRepList);
		for (int i=size-1; i>=0; i--) 
		{
			// list files by alphabetical order
			attmt = (String)statusRepList.get(i);
			if (!even) out.print("<tr>");
%>
			<td width="20"><img src="../i/bullet_tri.gif" width="20" height="10"></td>
			<td class="plaintext" width="250" valign="top">
				<a class="listlink" href="<%=host%>/servlet/ShowFile?filePath=<%=projIdS%>/Attachment-<%=attmt%>"><%=attmt%></a>
			</td>
<%
			if (even) out.print("</tr>");
			even = !even;
		}
		if (even) out.println("<td width='20'>&nbsp;</td><td width='250'>&nbsp;</td></tr>");
	}
%>
			</table>
		</td>
	</tr>

<!-- file attachment -->
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext" width="150" valign="top"><b>Project Files:</b></td>
		<td class="plaintext" valign="top">
			<table width="100%" border="0" cellspacing="0" cellpadding="2">
<%
	// file name is: Attachment-name of doc.ext
	size = attmtArrList.size();
	if (size == 0)
	{%>
		<tr><td class="plaintext_grey">None</td></tr>
<%	}
	else
	{
		Collections.sort(attmtArrList);
		boolean even = false;
		for (int i=0; i<size; i++)
		{
			// list files by alphabetical order
			attmt = (String)attmtArrList.get(i);
// @AGQ042006

			if (!even) out.print("<tr>");
%>
			<td width="20"><img src="../i/bullet_tri.gif" width="20" height="10"></td>
			<td class="plaintext" width="250" valign="top">
				<a class="listlink" href="<%=host%>/servlet/ShowFile?filePath=<%=projIdS%>/Attachment-<%=attmt%>"><%=attmt%></a>
			</td>
<%
			if (even) out.print("</tr>");
			even = !even;
		}
		if (even) out.println("<td width='20'>&nbsp;</td><td width='250'>&nbsp;</td></tr>");
	}
%>
			</table>
		</td>
	</tr>

	<tr><td colspan="3">
	<table width="760" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>
	</td></tr>


<!-- TASK FILES -->

<!-- *********** TASK LISTS *********** -->
<%
	// get all the tasks and from the planTask get the path name
	taskManager tMgr = taskManager.getInstance();
	task tk;
	planTaskManager ptMgr = planTaskManager.getInstance();
	planTask pt;
	String stackName;
	int [] ids = tMgr.findId(pstuser, "ProjectID='" + projIdS + "' && Attachment='%'");
	for (int i=0; i<ids.length; i++)
	{
		int [] ids1 = ptMgr.findId(pstuser, "TaskID='" + ids[i] + "' && Status!='Deprecated'");
		if(ids1.length == 0) {
			// This task has been deleted
			continue;
		}
		int ptId = ids1[ids1.length-1];
		pt = (planTask)ptMgr.get(pstuser, ptId);
		stackName = TaskInfo.getTaskStack(pstuser, pt);
		int idx = stackName.lastIndexOf(">>");
		if (idx > 0)
			stackName = stackName.substring(0, idx+2) + "<b>" + stackName.substring(idx+2) + "</b>";
		else
			stackName = "<b>" + stackName + "</b>";
%>
	<tr><td colspan="3" height="5">&nbsp;</td></tr>

<!-- task path -->
	<tr>
		<td width="15">&nbsp;</td>
		<td width="150" class="plaintext" valign="top"><b>Task Path:</b></td>
		<td class="plaintext" valign="top">
			<table><tr>
				<td width="2"></td>
				<td class="plaintext">
				<a class='listlink' href='../project/task_update.jsp?projId=<%=projIdS%>&
					pTaskId=<%=ptId%>'><%=stackName%></a>
				</td>
			</tr></table>
		</td>
	</tr>

<!-- task files -->
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext" width="150" valign="top"><b>Task Files:</b></td>
		<td class="plaintext" valign="top">
			<table width="100%" border="0" cellspacing="0" cellpadding="2">
<%
	// file name is: Attachment-name of doc.ext
	tk = (task)tMgr.get(pstuser, ids[i]);
	attmtList = tk.getAttribute("Attachment");
	if (attmtList[0] == null)
	{%>
		<tr><td class="plaintext_grey">None</td></tr>
<%	}
	else
	{
		Arrays.sort(attmtList);
		boolean even = false;
		for (int j=0; j<attmtList.length; j++)
		{
			// list files by alphabetical order
			attmt = (String)attmtList[j];
			if (!even) out.print("<tr>");
%>
			<td valign="top" width="20"><img src="../i/bullet_tri.gif" width="20" height="10"></td>
			<td class="plaintext" width="250" valign="top">
				<a class="listlink" href="<%=host%>/servlet/ShowFile?filePath=<%=ids[i]%>/Attachment-<%=attmt%>"><%=attmt%></a>
			</td>
<%
			if (even) out.print("</tr>");
			even = !even;
		}
		if (even) out.println("<td width='20'>&nbsp;</td><td width='250'>&nbsp;</td></tr>");
	}
%>
			</table>
		</td>
	</tr>

	<tr><td colspan="3" height="5">&nbsp;</td></tr>
	<tr><td colspan="3">
		<table width="760" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
			<tr>
			<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
			</tr>
		</table>
	</td></tr>

<%	}%>

</table>

	</td>
</tr>

	<tr><td>&nbsp;</td></tr>

<!-- BEGIN FOOTER TABLE -->
<jsp:include page="/foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

