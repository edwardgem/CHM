<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>

<%
//
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: PlanApprovalGroupLeaderVerify.jsp
//	Author: Eddie Lo
//	Date:	03/18/03
//	Description: Plan listing page for workflow
//				Used for managed WF and to view the flow obj
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
// index.jsp :
//
/**
* @author $Author$
* @version $Revision$
*/
/**
* $Log$
* Revision 1.6  2007/06/19 23:38:18  edwardc
* Support CR to enable team member to submit plan change request.
*
* Revision 1.5  2006/09/12 17:49:18  sandras
* Fix page title tag with correct application name.
*
* Revision 1.4  2006/07/07 02:35:50  sandras
* Handle CR application.
*
* Revision 1.3  2006/06/23 03:31:01  edwardc
* SE project check-in
*
* Revision 1.2  2005/11/07 07:03:37  edwardc
* Synchronize prayer (laptop) to merciful CVS
*
* Revision 1.2  2003/06/18 17:38:25  eddiel
* improve performance
*
* Revision 1.1  2003/06/17 18:53:59  eddiel
* initial release
*
*/
%>

<%@ page import = "util.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.omm.common.*" %>
<%@ page import = "oct.omm.client.*" %>
<%@ page import = "oct.omm.db.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
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

	//to check if session is CR or PRM
	boolean isCRAPP = false;
	String app = (String)session.getAttribute("app");
	if (app.contains("CR"))
		isCRAPP = true;

	String VIEWONLY = "VIEWONLY";
	String mode = (String)request.getParameter("mode");

	// Original workflow code - Begin
	String stepName = (String)request.getParameter("stepName");
	String flowIntName = new String();
	PstFlowStep stepObj = (PstFlowStep)PstFlowStepManager.getInstance().get(pstuser, stepName);
	if(stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0] != null)
		flowIntName = stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0].toString();

	PstFlow flowObj = (PstFlow)PstFlowManager.getInstance().get(pstuser, flowIntName);
	Object [] conObjList = flowObj.getAttribute(PstFlow.CONTEXT_OBJECT);
	planManager objMgr = planManager.getInstance();
	plan targetObj = (plan)objMgr.get(pstuser, ((String)conObjList[0]).toString());

	Object [] planDescription = targetObj.getAttribute("Description");
	Object [] CreatedDate = targetObj.getAttribute("CreatedDate");
	Object [] ProjectID = targetObj.getAttribute("ProjectID");

	// Use PepComment
	PepCommentVector commentVector = PepCommentVector.getComments((byte[]) planDescription[0]);
	PepComment firstcomment = commentVector.getCommentAt(0);
	String firstDescription = firstcomment.getContent();

	// Original workflow code - End

	// @082603ECC handle both product and project plan approval
	String planType = (String)targetObj.getAttribute("Type")[0];
	PstManager objMgr1;
	PstAbstractObject obj;
	Object [] Name;

	// project plan
	objMgr1 = projectManager.getInstance();
	String projIdS = (String)ProjectID[0];
	obj = objMgr1.get(pstuser, Integer.parseInt(projIdS));
	Name = new Object[1];
	Name[0] = (Object)obj.getObjectName();		// actual project name e.g. abc@@12345
	String projDispName = ((project)obj).getDisplayName();

	Object [] Description = obj.getAttribute("Description");


	// Will show later  ***
	//Object [] planDescription = targetObj.getAttribute("Description");
	//Object [] planStatus = targetObj.getAttribute("Status");
	//Object [] planCreatedDate = targetObj.getAttribute("CreatedDate");
	//Object [] planEffectiveDate = targetObj.getAttribute("EffectiveDate");
	//Object [] planDeprecatedDate = targetObj.getAttribute("DeprecatedDate");

	user u;
	String s;
	userManager uMgr = userManager.getInstance();

	Object [] Version = targetObj.getAttribute("Version");
	String planVersion = (String)Version[0];
	String planmemname = targetObj.getObjectName();
	String proposor = firstcomment.getByUser();
	try
	{
		u = (user)uMgr.get(pstuser, proposor);
		proposor = u.getFullName();
	}
	catch (PmpException e)
	{
		// the proposor is not found in the db
		proposor += " (person not found in database)";
	}

	SimpleDateFormat df1 = new SimpleDateFormat ("MMMMMMMM dd, yyyy (EEE) hh:mm a");
	SimpleDateFormat df2 = new SimpleDateFormat ("MM/dd/yy");
	String proposedDate = df1.format(CreatedDate[0]);

	// Get plan task
	planTaskManager ptargetObjMgr = planTaskManager.getInstance();
	int [] targetObjIds = ptargetObjMgr.findId(pstuser, "PlanID='" + targetObj.getObjectName() + "'");
	PstAbstractObject [] targetObjList = ptargetObjMgr.get(pstuser, targetObjIds);
	Util.sortString(targetObjList, "PreOrder");
%>


<head>
<title><%=app%> Project Plan Revision</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>

<script type="text/javascript" language="javascript">
<!--
function setResponse(stat)
{
	StepForm.status.value = stat.value;
	StepForm.submit();
}
//-->
</script>

</head>

<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" height="100%" border="0" cellspacing="0" cellpadding="0">

<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true" />

<tr>
	<td valign="top">


		<!-- Main Tables -->
	<table>
	<tr><td>
	<b class="head">
	&nbsp;&nbsp;Review Project Plan Revision
	</b><br><br>
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
			<td valign="top" align="right" class="bgsubnav" width="760">
				<table border="0" cellspacing="0" cellpadding="0">
				<tr class="bgsubnav">
<%if (!isCRAPP){%>	
	<!-- Project Blog -->
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="../project/proj_plan.jsp?projId=<%=projIdS%>" class="subnav">Project Blog</a></td>
					<td colspan="3" width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
<%}
 if (isCRAPP){%>					
	<!-- Central Repository -->
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="../project/cr.jsp?projId=<%=projIdS%>" class="subnav">Central Repository</a></td>
					<td colspan="3" width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
<%} %>
	<!-- Review Plan Revision -->
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<td width="20"><img src="../i/spacer.gif" width="7" height="1" border="0"></td>
					<td width="20" height="14"><img src="../i/nav_arrow.gif" width="20" height="14" border="0"></td>
					<td><a href="#" onClick="return false;" class="subnav"><u>Review Plan Revision</u></a></td>
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
		 <table width="760" border="0" cellspacing="0" cellpadding="0">
			<tr>
				<td>&nbsp;</td>
				<td>
		<!-- Page Headers -->
					 <table width="100%" border="0" cellpadding="0" cellspacing="0">
					 	<tr><td>&nbsp;</td></tr>
						<tr>
							<td class="heading" colspan="2"><%=projDispName%> (<%=planVersion%>)</td>
					    </tr>
					 	<tr><td>&nbsp;</td></tr>

						<tr>
							<td colspan="2" class="plaintext">&nbsp;
								<b><%if(Description != null && Description[0] != null) out.print(new String((byte[])Description[0]));%></b>
							</td>
					    </tr>
						<tr>
							<td colspan="2">&nbsp;</td>
					    </tr>
					</table>
		<!-- Page Headers -->

					<table width="100%" border="0" cellspacing="2" cellpadding="4" bgcolor="#FFFFFF">
						<tr>
							<td width="150" class="td_field_bg"><strong>Proposed plan version</strong></td>
							<td class="td_value_bg"><%=planVersion%></td>
						</tr>
						<tr>
							<td class="td_field_bg"><strong>Change submitted by</strong></td>
							<td class="td_value_bg"><%=proposor%></td>
						</tr>
						<tr>
							<td class="td_field_bg"><strong>Revision date</strong></td>
							<td class="td_value_bg"><%=proposedDate%></td>
						</tr>
						<tr>
							<td class="td_field_bg"><strong>Change remark</strong></td>
							<td class="td_value_bg">
								<%=firstDescription%>
							</td>
						</tr>
					</table>

				</td>
			</tr>


			<tr><td colspan="2">&nbsp;</td></tr>
			<tr>
				<td width="26"><img src="../i/spacer.gif" width="10" border="0"></td>
				<td>
					<table width="100%" border="0" cellspacing="0" cellpadding="0">
					<tr>
						<td>
<%


	String bgcolor="";
	String[] levelInfo = new String[JwTask.MAX_LEVEL];
	for(int i = 0; i < targetObjList.length; i++)
	{
		planTask ptargetObj = (planTask)targetObjList[i];
		Object [] pStatus = ptargetObj.getAttribute("Status");
		Object [] pName = ptargetObj.getAttribute("Name");
		Object [] pTaskID = ptargetObj.getAttribute("TaskID");
		Object [] pLevel = ptargetObj.getAttribute("Level");
		Object [] pOrder = ptargetObj.getAttribute("Order");
		//Object [] pPlanID = ptargetObj.getAttribute("PlanID");

		int level = ((Integer)pLevel[0]).intValue();
		int order = ((Integer)pOrder[0]).intValue();
		String status = (String)pStatus[0];

		int width = 10 + 22 * level;
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

		//bgcolor = "bgcolor='#CCCCCC'";
		out.println("<table width='100%' border='0' cellspacing='0' cellpadding='0' " + bgcolor + " >");
		if (level <= 1)
			out.print("<tr><td " + bgcolor + "><img src='../i/spacer.gif' height='7'></td></tr>");
		out.println("<tr><td " + bgcolor + " width='" + width + "'><img src='../i/spacer.gif' width='" + width + "' height='2' border='0'></td><td class='plaintext_big'>");
		switch (status.charAt(0))
		{
			case 'O':  // Original
				out.println(levelInfo[level-1] + ".&nbsp;" + "&nbsp;" + pName[0].toString());
				break;
			case 'D':  // Old, Deprecated
				out.println("<font color='red'><strike>" + levelInfo[level-1] + ".&nbsp;" + "&nbsp;" + pName[0].toString() + "</strike></font>");
				break;
			case 'N':  // New
				out.println("<font color='red'>" + levelInfo[level-1] + ".&nbsp;" + "&nbsp;" + pName[0].toString() + "</font>");
				break;
			case 'C':  // Change
				out.println("<font color='green'>" + levelInfo[level-1] + ".&nbsp;" + "&nbsp;" + pName[0].toString() + "</font>");
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


<table width="780" border="0" cellspacing="0" cellpadding="2">
  <tr>
    <td width="26" align="right"><img src="..i/spacer.gif" border="0" width="26" height="1"></td>
    <td width="754">&nbsp;</td>
  </tr>
  <tr>
    <td>&nbsp;</td>
    <td width="100%" valign="top">
		<table width="100%" border='0' cellpadding="0" cellspacing="0">
			<tr>
				<td class="heading">Comments</td>
		    </tr>
			<tr>
				<td bgcolor="#EBECED" height="3"><img src="../images/spacer.gif" width="1" height="3" border="0"></td>
		    </tr>
		</table>
		<table width="100%" border='0' cellpadding="0" cellspacing="0">
			<tr>
				<td height="2" width="5" bgcolor="#336699" colspan="8"><img src="../i/mid/u2x2.gif" width="2" height="2"></td>
		    </tr>
			<tr>
				<td width="4" class="td_header" bgcolor="#6699cc">&nbsp;</td>
				<td width="120" class="td_header" bgcolor="#6699cc"><strong>Date</strong></td>
				<td width="2" bgcolor="#FFFFFF">&nbsp;</td>
				<td width="4" class="td_header" bgcolor="#6699cc">&nbsp;</td>
				<td width="150" class="td_header" bgcolor="#6699cc"><strong>Name</strong></td>
				<td width="2" bgcolor="#FFFFFF">&nbsp;</td>
				<td width="4" class="td_header" bgcolor="#6699cc">&nbsp;</td>
				<td  class="td_header" bgcolor="#6699cc"><strong>Comments</strong></td>
			</tr>
<%
	if (commentVector != null)
	{
		for (int i = 0; i < commentVector.size(); i++)
		{
			PepComment comment = commentVector.getCommentAt(i);
			s = comment.getByUser();
			try
			{
				u = (user)uMgr.get(pstuser, s);
				s = u.getFullName();
			}
			catch (PmpException e)
			{
				// obsolete user
			}
%>

			<tr  <%=bgcolor %>>
				<td width="4">&nbsp;</td>
				<td width="150" class="plaintext"><%=df2.format(comment.getDate())%></td>
				<td width="2">&nbsp;</td>
				<td width="4">&nbsp;</td>
				<td class="plaintext"><%=s%></td>
				<td width="2">&nbsp;</td>
				<td width="4">&nbsp;</td>
				<td class="plaintext"><%=comment.getContent()%></td>
			</tr>
			<tr>
				<td colspan="8" class="td_header" <%=bgcolor%>><img src="../images/spacer.gif" width="1" height="3" border="0"></td>
			</tr>
<%
		}
	}
	else
	{
%>
			<tr bgcolor="#EEEEEE">
				<td colspan="6" class="plaintext">There is no comment on this plan.</td>
			</tr>
<%
	}
%>
		</table>

	</td>
  </tr>
  <tr>
  	<td colspan="2">&nbsp;</td>
  </tr>
<%
	if (!VIEWONLY.equals(mode))
	{
%>
  <tr>
  	<td>&nbsp;</td>
    <td class="td_all">
		* Please review the changes and enter comment if neccessery.
	</td>
  </tr>
  <tr>
    <td>&nbsp;</td>
    <td width="100%" valign="top">

		 <form method="post" name="StepForm" action="postPlanApprovalGroupLeaderVerify.jsp">
	     <input type='hidden' name='memname' value='<%=planmemname%>'>
	     <input type='hidden' name='stepName' value='<%=stepObj.getObjectName()%>'>
	     <input type='hidden' name='commit' value='commit'>
	     <input type='hidden' name='backward' value='backward'>
	     <input type='hidden' name='abort' value='abort'>
	     <input type='hidden' name='status'>
		<table width="100%" border="1" cellspacing="0" cellpadding="2" bordercolordark="#D4D4D4" bordercolorlight="#FFFFFF" bordercolor="#D4D4D4">
		  <tr>
		    <td width="165"  class="td_field_bg" valign="top"><b>Enter Comment:</b></td>
		    <td width="607" class="td_value_bg"><textarea name="Description" rows="7" cols="60"></textarea></td>
		  </tr>
		</table>
		<table width="780" border="0" cellspacing="0" cellpadding="2">
		  <tr>
		    <td width="165" align="right">&nbsp;</td>
		    <td width="607">&nbsp;</td>
		  </tr>
		  <tr>
		    <td colspan="2" align="center">

		<input type='button' class='button_medium' name='submitButton' value='Approve' onclick='return setResponse(document.StepForm.commit);' />
		&nbsp;&nbsp;&nbsp;
		<input type='button' class='button_medium' value='Reject' onclick='return setResponse(document.StepForm.abort);' />



		    </td>
		  </tr>
		</table>
	</td>
  </tr>

<%
	}
%>
</table>
</form>
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
