<%
////////////////////////////////////////////////////
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	phase_update.jsp
//	Author:	ECC
//	Date:	09/28/05
//	Description:
//		Update project phases and sub-phases.  Only support max two levels of phases.
//	Modification:
//		@ECC041206	Added PlanExpireDate to task and phase/subphase.  Also switch TID and SubPhaseExt in Phase record.
//		@041906SSI	Added sort function to Project names.
//		@AGQ050306	Supporting task with TBD and N/A
// 		@AGQ050406A	Changed calender to not display if not a number
// 		@AGQ050506	Added link to phase definition page.
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>
<%@ page import = "javax.servlet.*" %>
<%@ page import = "javax.servlet.http.*" %>

<%
	String projIdS = request.getParameter("projId");
	String noSession = "../out.jsp?go=project/phase_update2.jsp?projId="+projIdS;
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%
	final String PROP_FILE = "bringup";

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	String pstuserIdS = String.valueOf(pstuser.getObjectId());
	boolean isAdmin = false;
	boolean isPM = false;
	boolean isAboveUser = false;		// allow only above USER grade to update project phases
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if (iRole > 0)
	{
		if ((iRole & user.iROLE_ADMIN) > 0)
		{
			isAdmin = true;
			isAboveUser = true;
		}
		if ((iRole & user.iROLE_PROGMGR) > 0)
			isPM = true;

		if ((iRole & user.iROLE_USER) == 0)
			isAboveUser = true;
	}
	int myUid = pstuser.getObjectId();

	// town
	/*String townName = (String)session.getAttribute("townName");
	town tObj = (town)townManager.getInstance().get(pstuser, townName);
	String townChiefIdS = (String)tObj.getAttribute("Chief")[0];*/

	// project

	projectManager pjMgr = projectManager.getInstance();
	resultManager rMgr = resultManager.getInstance();

	project projObj = (project)pjMgr.get(pstuser, Integer.parseInt(projIdS));
	String projName = projObj.getDisplayName();
	String ownerIdS   = (String)projObj.getAttribute("Owner")[0];
	int ownerId = Integer.parseInt(ownerIdS);
	if (ownerId == myUid)
		isAboveUser = true;

	// update only authorized to project owner and for roles above user
	// just for double safety: actually I cannot get to this page from proj_profile.jsp unless
	// I am either admin, project owner, or the supervisor of the project owner
	if (ownerIdS == null || (ownerId!=pstuser.getObjectId() && !isAboveUser))
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}

	// get the expiration date
	String format = "MM/dd/yyyy";
	java.text.SimpleDateFormat df = new java.text.SimpleDateFormat(format);

	// project phases (name::StartDate::ExpireDate::CompleteDate::Status)
	int maxPhases = 7;	// default to 7
	String s = Util.getPropKey(PROP_FILE, "PHS.TOTAL");
	if (s != null) maxPhases = Integer.parseInt(s);

	String [] phaseS = new String[maxPhases];
	String [] phaseB = new String[maxPhases];	// begin (StartDate)
	String [] phasePlanD = new String[maxPhases];	// plan deadline
	String [] phaseD = new String[maxPhases];	// deadline
	String [] phaseSt = new String[maxPhases];
	String [] phaseTask = new String[maxPhases];	// @110705ECC task link
	String [] phaseExt = new String[maxPhases];	// extension to sub-phases (store blogID)
	String [] sa;
	taskManager tkMgr = taskManager.getInstance();
	planTaskManager ptMgr = planTaskManager.getInstance();
	phaseManager phMgr = phaseManager.getInstance();
	PstAbstractObject tk, ptk;
	int [] ids;
	Date dt;

	PstAbstractObject [] objArr = phMgr.getPhases(pstuser, String.valueOf(projObj.getObjectId()));
	phase ph = null;
	if (isAboveUser)
	{
		for (int i=0; i<maxPhases; i++)
		{
			if (i < objArr.length)
			{
				// startDt and CompleteDt are implied by change of state
				ph = (phase) objArr[i];
				// @110705ECC
				Object obj = ph.getAttribute(phase.TASKID)[0];
				if (obj != null)
				{
					// use task to fill the phase info
					phaseTask[i] = obj.toString();
					try
					{
						tk = tkMgr.get(pstuser, phaseTask[i]);
						obj = ph.getAttribute(phase.NAME)[0];
						if (obj == null)
						{
							ids = ptMgr.findId(pstuser, "TaskID='" + phaseTask[i] + "' && Status!='Deprecated'");
							ptk = ptMgr.get(pstuser, ids[ids.length-1]);
							phaseS[i] = (String)ptk.getAttribute("Name")[0];
						}
						else
							phaseS[i] = obj.toString();

						dt = (Date)tk.getAttribute("EffectiveDate")[0];
						if (dt == null)
							dt = (Date)tk.getAttribute("StartDate")[0];
						if (dt != null)
							phaseB[i] = df.format(dt);
// @AGQ050306
						dt = (Date)tk.getAttribute("ExpireDate")[0];
						phaseD[i] = phase.parseDateToString(dt, format);

						s = (String)tk.getAttribute("Status")[0];
						if (s.equals(task.ST_NEW)) s = project.PH_NEW;
						else if (s.equals(task.ST_OPEN) || s.equals(task.ST_ONHOLD)) s = project.PH_START;
						phaseSt[i] = s;
					}
					catch (PmpException e){phaseS[i] = "*** Invalid task ID";}
				}
				else
				{
					phaseTask[i] = "";			// not using task link
					phaseS[i] = ph.getAttribute(phase.NAME)[0].toString();
					dt = (Date)ph.getAttribute(phase.STARTDATE)[0];
					if (dt != null) phaseB[i] = df.format(dt);
					else phaseB[i] = "";
// @AGQ050306
					dt = (Date)ph.getAttribute(phase.PLANEXPIREDATE)[0];
					phasePlanD[i] = phase.parseDateToString(dt, format);

					dt = (Date)ph.getAttribute(phase.EXPIREDATE)[0];
					phaseD[i] = phase.parseDateToString(dt, format);

					phaseSt[i]		= ph.getAttribute(phase.STATUS)[0].toString();
				}
				s = String.valueOf(ph.getObjectId());
				if (phMgr.hasSubPhases(pstuser, s))
					phaseExt[i] = s;
				else
					phaseExt[i] = null;
			}
			else
			{
				// use default phase name
				s = Util.getPropKey(PROP_FILE, "PHS." + (i+1));
				if (s == null) s = "";
				phaseS[i] = s;
				phaseTask[i] = "";				// not using task link
			}
		}
	}

%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">

<jsp:include page="../init.jsp" flush="true"/>
<script language="JavaScript" src="../get-date.js"></script>

<script type="text/javascript">

<!--
function fixElement(e, msg)
{
	alert(msg);
	if (e)
		e.focus();
}

function validation()
{
	return true;
}

function show_cal(i, e1, e2)
{
	savePhase(i);
	var dt;
	if (e1.value!=null && e1.value!='')
		dt = new Date(e1.value);
	else
		dt = new Date();
	var mon = '' + dt.getMonth();
	var yr = '' + dt.getFullYear();
	if (yr.length==2) yr = '20' + yr;		// 13 change to 2013
	else if (yr.length==1) yr = '200' + yr;	// because 05 will become 5
	var es = 'updatePhase.' + e1.name;
	var es2 = null;
	if (e2 != null && (e2.value == null || e2.value == ''))
	{
		es2 = 'updatePhase.' + e2.name;
	}
	var number = parseInt(mon);
	var number2 = parseInt(yr);
// @AGQ050406a
	if (isNaN(number) || isNaN(number2)) {
		dt = new Date();
		mon = '' + dt.getMonth();
		yr = '' + dt.getFullYear();
	}
	show_calendar(es, mon, yr, null, es2);
}

function savePhase(idx) {
	var phase = document.getElementById("savePhase" + idx);
	if (phase && phase.value != 'true')
		phase.value = 'true';
}

function copyDate(nameSource, nameTarget, i, j) {
	var target = document.getElementsByName(nameTarget+i+"_"+j)[0].value;
	var source = document.getElementsByName(nameSource+i+"_"+j)[0].value;
	if ((target == '' || target == null) &&
			(source != '' && source != null)) {
		document.getElementsByName(nameTarget+i+"_"+j)[0].value = source;
	}
}

function phase_use_task(i)
{
	var b = document.getElementsByName('PhaseTaskCheck' + i)[0].checked;
	document.getElementsByName('PhStart' + i)[0].disabled = b;
	document.getElementsByName('Deadline' + i)[0].disabled = b;
	document.getElementsByName('Status' + i)[0].disabled = b;
	document.getElementsByName('PhaseTask' + i)[0].disabled = !b;
}

function subphase_use_task(i, j)
{
	var b = document.getElementsByName('SubPhaseTaskCheck' + i + "_" + j)[0].checked;
	document.getElementsByName('SubPhStart' + i + "_" + j)[0].disabled = b;
	document.getElementsByName('SubDeadline' + i + "_" + j)[0].disabled = b;
	document.getElementsByName('SubStatus' + i + "_" + j)[0].disabled = b;
	document.getElementsByName('SubPhaseTask' + i + "_" + j)[0].disabled = !b;
}

function cancel()
{
	location="proj_summary.jsp?projId=<%=projIdS%>";
}
//-->
</script>

<title>
	<%=Prm.getAppTitle()%> Update Phases
</title>

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
					<td width="26" height="30"><a name="top">&nbsp;</a></td>
					<td height="30" align="left" valign="bottom" class="head">
						<b>Update Milestone Schedule</b>
					</td>
					<td>
<%	// @AGQ050506
	if (isAboveUser) {
%>
					<img src="../i/bullet_tri.gif" width="20" height="10">
					<a class="listlinkbold" href="phase_update.jsp?projId=<%=projIdS%>">Update Phase Definition</a><br />
<% } %>
					</td>
				  </tr>
	            </table>
	          </td>
	        </tr>
</table>
	        
<table width='90%' border="0" cellspacing="0" cellpadding="0">
			<tr>
          		<td width="100%">
<!-- Navigation Menu -->
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Project" />
				<jsp:param name="subCat" value="" />
				<jsp:param name="role" value="<%=iRole%>" />
				<jsp:param name="projId" value="<%=projIdS%>" />
			</jsp:include>
<!-- End of Navigation SUB-Menu -->
				</td>
	        </tr>
		</table>

<!-- MAIN CONTENT -->
<br>

<table>
<tr>
    <td width="12">&nbsp;</td>
<td>

<!-- start table -->
	<table width="90%" border="0" cellspacing="2" cellpadding="4" bgcolor="#FFFFFF">

<tr><td colspan='2'>

<!-- Project Name -->
<form>
	<table width="100%" border="0" cellpadding="0" cellspacing="0">
	<tr valign="top">
	<td class="heading">
		Project Name:&nbsp;&nbsp;
		<select name="projId" class="formtext" onchange="submit()">
<%
	int [] projectObjId = null;
	if (isAdmin || isPM)
		projectObjId = pjMgr.findId(pstuser, "om_acctname='%'");
	else
		projectObjId = pjMgr.findId(pstuser, "Owner='" + myUid + "'");
	if (projectObjId.length > 0)
	{
		PstAbstractObject [] projectObjList = pjMgr.get(pstuser, projectObjId);
		//@041906SSI
		Util.sortName(projectObjList, true);

		String pName;
		project pj;
		Date expDate;
		String expDateS = new String();
		for (int i=0; i < projectObjList.length ; i++)
		{
			// project
			pj = (project) projectObjList[i];
			pName = pj.getDisplayName();
			out.print("<option value='" + pj.getObjectId() +"' ");
			if (pName.equals(projName))
				out.print("selected");
			out.print(">" + pName + "</option>");
		}
	}
%>
		</select>
	</td>
	</tr>
	</table>
</form>
</td></tr>

<form name="updatePhase" action="post_updphase2.jsp" method="post">
	<input type="hidden" name="projId" value="<%=projIdS%>">
	<input type="hidden" name="addPhase">
<%
	for (int i=0; i<maxPhases; i++) {
		out.println("<input type='hidden' id='savePhase" + i + "' name='savePhase" + i + "' value='false'>");
	}
%>
<!-- ****************** Project Phases ******************* -->
<%if (isAboveUser)
{%>

<!-- Phases -->
	<tr bgcolor='#FFFFFF'>
		<td colspan='2'>
			<table border="0" cellspacing="2" cellpadding="4" bgcolor="#FFFFFF">
<%
	String [] saa;
	String subphTid=null, subphName=null, subphPED=null, subphDeadln=null, subphStatus=null, subphComplete=null, disabled="", disableCal="";
	for (int i=0; i<maxPhases; i++)
	{
		// handle subphases if any
		int subCt = 0;
// @AGQ042506
		if (phaseExt[i] != null)
		{
			objArr = phMgr.getSubPhases(pstuser, phaseExt[i]);

			// Create the header, test to see if blog object really has subphases
			if (objArr.length > 0) {
				// Create header rows
				out.println("<tr><td colspan='4'></td></tr>");
				out.println("<tr><td class='title'>Phase Name:</td><td class='plaintext_bold' colspan='3'>" + phaseS[i] + "</td></tr>");
				out.println("<tr><td class='td_value_bg' align='center' style='font-size: 13px;'><b>Milestones</b></td><td class='td_field_bg' align='center'>Planned Due<br>Date</td>"
					+ "<td class='td_field_bg' align='center'>Estimated<br>Due Date</td>"
					+ "<td class='td_field_bg' align='center'>Actual<br>Completion Date</td>");
				out.println("<input type='hidden' name='phaseExt"+i+"' value='"+phaseExt[i]+"'>");
			}

			// Create rows for each subphase: each sa[] is a subphase
			for (int m=0; m<objArr.length; m++)
			{
				subphPED = subphDeadln = subphComplete = null;
				// it might be using task link
				ph = (phase) objArr[m];
				Object obj = ph.getAttribute(phase.TASKID)[0];
				disabled="";
				disableCal="";

				if (obj != null)
				{
					StringBuffer name = new StringBuffer();
					name.append("<a class='listlink' href='task_update.jsp?projId=");
					name.append(projIdS);
					name.append("&taskId=");
					// use task to fill the phase info
					subphTid = obj.toString();
					name.append(subphTid);
					name.append("'>");
					try {
						tk = tkMgr.get(pstuser, subphTid);
						obj = ph.getAttribute(phase.NAME)[0];
						if (obj == null)
						{
							ids = ptMgr.findId(pstuser, "TaskID='" + subphTid + "' && Status!='Deprecated'");
							ptk = ptMgr.get(pstuser, ids[ids.length-1]);
							subphName = (String)ptk.getAttribute("Name")[0];
						}
						else
							subphName = obj.toString();
// @AGQ050306
						name.append(subphName);
						name.append("</a>");
						subphName = name.toString();
						dt = (Date)tk.getAttribute("PlanExpireDate")[0];
						subphPED = phase.parseDateToString(dt, format);
						dt = (Date)tk.getAttribute("ExpireDate")[0];
						subphDeadln = phase.parseDateToString(dt, format);
						dt = (Date)tk.getAttribute("CompleteDate")[0];
						subphComplete = phase.parseDateToString(dt, format);
						s = (String)tk.getAttribute("Status")[0];
						if (s.equals(task.ST_NEW)) s = project.PH_NEW;
						else if (s.equals(task.ST_OPEN) || s.equals(task.ST_ONHOLD)) s = project.PH_START;
						subphStatus = s;
						disabled="disabled=disabled";
						disableCal="onclick='return false;'";
					}
					catch (PmpException e){e.printStackTrace(); subphName="*** Invalid task ID";}	// indicate error
				}
				else
				{
					subphTid		= "";
					subphName		= ph.getAttribute(phase.NAME)[0].toString();
// @AGQ050306
					dt = (Date)ph.getAttribute(phase.PLANEXPIREDATE)[0];
					subphPED = phase.parseDateToString(dt, format);
					dt = (Date)ph.getAttribute(phase.EXPIREDATE)[0];
					subphDeadln = phase.parseDateToString(dt, format);
					dt = (Date)ph.getAttribute(phase.COMPLETEDATE)[0];
					subphComplete = phase.parseDateToString(dt, format);

					subphStatus 	= ph.getAttribute(phase.STATUS)[0].toString();
				}

				// display informatin for each subphase
				out.println("<tr><td class='td_value_bg' width='200'><b>" + subphName + "</b></td>");
				out.println("<input type='hidden' name='subPhaseTID"+i+"_"+subCt+"' value='"+subphTid+"'>");
				out.print("<td><input class='formtext' type='text' name='SubInitDl" +i+"_"+subCt + "' size='12' value='");
				if (subphPED != null)
					out.print(subphPED);
				if (disabled.length() > 0)
					s = "show_cal("+i+",updatePhase.SubInitDl" +i+"_"+subCt + ")";
				else
					s = "show_cal("+i+",updatePhase.SubInitDl" +i+"_"+subCt + ", updatePhase.SubDeadline" +i+"_"+subCt + ")";
				out.print("' onChange='savePhase("+i+"); copyDate(\"SubInitDl\", \"SubDeadline\", "+i+", "+subCt+")' onClick='"+s+";'>");
				out.print("&nbsp;<a href='javascript:"+s+";'><img src='../i/calendar.gif' border='0' align='absmiddle' alt='Click to view calendar.'></a></td>");

				out.print("<td><input class='formtext' type='text' name='SubDeadline" +i+"_"+subCt + "' size='12' value='");
				if (subphDeadln != null)
					out.print(subphDeadln);
				out.print("' onChange='savePhase("+i+"); copyDate(\"SubDeadline\", \"SubInitDl\", "+i+", "+subCt+")' onClick='show_cal("+i+",updatePhase.SubDeadline" +i+"_"+subCt + ",updatePhase.SubInitDl" +i+"_"+subCt + ");' " + disabled + ">");
				out.print("&nbsp;<a href='javascript:show_cal("+i+",updatePhase.SubDeadline" +i+"_"+subCt + ",updatePhase.SubInitDl" +i+"_"+subCt + ");' "+disableCal+"><img src='../i/calendar.gif' border='0' align='absmiddle' alt='Click to view calendar.'></a></td>");

				out.print("<td><input class='formtext' type='text' name='SubComplete" +i+"_"+subCt + "' size='12' value='");
				if (subphComplete != null)
					out.print(subphComplete);
				if (subphStatus.equals(phase.PH_CANCEL)) {
					disabled = "disabled=disabled";
					disableCal = "onclick='return false;'";
				}
				out.print("' onChange='savePhase("+i+");' onClick='show_cal("+i+",updatePhase.SubComplete" +i+"_"+subCt + ");' " + disabled + ">");

				out.print("&nbsp;<a href='javascript:show_cal("+i+",updatePhase.SubComplete" +i+"_"+subCt + ");' "+disableCal+"><img src='../i/calendar.gif' border='0' align='absmiddle' alt='Click to view calendar.'></a></td>");

				subCt++;
			}	// end for each subphase record
			out.println("<tr><td><img src='../i/spacer.gif' height='15' border='0'></td></tr>");
		}	// endif blog != null (has subphase)
	}
%>
	<tr><td colspan='4' align='center'>
		<input type='submit' class='button_medium' onclick='return validation();'>
		<input type='button' class='button_medium' onclick='cancel();' value='Cancel'>
		<br></p>
	</td></tr>
			</table>
		</td>
	</tr>
<%
}	// end isAboveUser
%>


</table>
<!-- end table -->



	</td>
</tr>
</table>
</form>
<!-- END MAIN CONTENT -->
</td>
</tr>

<tr><td>&nbsp;</td></tr>
<tr><td>
<!-- BEGIN FOOTER TABLE -->
<jsp:include page="/foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->
</td></tr>
<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

