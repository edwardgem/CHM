
<%
////////////////////////////////////////////////////
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	proj_profile.jsp
//	Author:	ECC
//	Date:	03/18/04
//	Description:
//		Display the project profile.
//	Modification:
//		@ECC063005	Add project options.  Enable member update plan.
//		@ECC092405	Handle special characters in uploading and downloading file names.
//		@ECC120305	Recalculate optimal deadline for the entire project tree.
//		@AGQ040306	Added support for multifile upload
//		@ECC062806	Support program manager change phase and milestone
//		@AGQ081506	Fetches attachment using attachmentID
//
////////////////////////////////////////////////////////////////////
%>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	//double SUMMARY_COST = 0.25;
	//double UPLOAD_COST  = 0.25;

	String projIdS = request.getParameter("projId");
	if ((pstuser instanceof PstGuest) || (projIdS == null))
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	String host = Util.getPropKey("pst", "PRM_HOST");

	String backPage = "../project/proj_report.jsp?projId=" + projIdS;
	boolean isDirector = false;
	boolean isAdmin = false;
	boolean isProgMgr = false;			// @ECC062806
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if (iRole > 0)
	{
		if ((iRole & user.iROLE_ADMIN) > 0)
			isAdmin = true;
		if ((iRole & user.iROLE_DIRECTOR) > 0)
			isDirector = true;
		if ((iRole & user.iROLE_PROGMGR) > 0)
			isProgMgr = true;
	}

	SimpleDateFormat df1 = new SimpleDateFormat ("MM/dd/yyyy");

	projectManager pjMgr = projectManager.getInstance();
	attachmentManager aMgr	= attachmentManager.getInstance();
	project proj = (project)pjMgr.get(pstuser, Integer.parseInt(projIdS));
	int projId = proj.getObjectId();
	String projName = proj.getDisplayName();
	String projDispName = proj.getDisplayName();
	String tidS = (String)proj.getAttribute("TownID")[0];

	// @ECC120305 Optimize project schedule
	String s;
	int uid = pstuser.getObjectId();
	String coordinatorIdS = (String)proj.getAttribute("Owner")[0];
	int coordinatorId = Integer.parseInt(coordinatorIdS);
	boolean isCoordinator = (uid == coordinatorId);

	userManager uMgr = userManager.getInstance();
	user aUser = (user)uMgr.get(pstuser, coordinatorId);
	String coordinator = aUser.getObjectName();
	String lname = (String)aUser.getAttribute("LastName")[0];
	String uname = aUser.getAttribute("FirstName")[0] + (lname==null?"":(" " + lname));

	// allow coordinator's manager to update project profile - only ADMIN can delete project
	boolean isOwnerManager = false;
	s = (String)aUser.getAttribute("Supervisor1")[0];
	if (s!=null && Integer.parseInt(s)==uid)
		isOwnerManager = true;

	// @ECC063005
	String optStr = (String)proj.getAttribute("Option")[0];
	if (optStr == null) optStr = "";
	
	// distribution frequency
	int idx;
	String currentDistFreq = proj.getOption(project.DISTRIBUTE_FREQ);
	String currentDistFreqSpec = "";
	if (currentDistFreq!=null && (idx=currentDistFreq.indexOf(':')) != -1) {
		currentDistFreqSpec = currentDistFreq.substring(idx+1);
		currentDistFreq = currentDistFreq.substring(0, idx);
	}
System.out.println("current freq=" + currentDistFreqSpec);	

	if (!(isCoordinator || isAdmin || isDirector || isProgMgr)) {
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}

	//Calendar cal = Calendar.getInstance();
	//System.out.println("today is " + cal.get(Calendar.DAY_OF_WEEK)
	//		+ "," + cal.get(Calendar.DAY_OF_MONTH));
%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<script src="../multifile.js"></script>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">

<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../forms.jsp" flush="true"/>

<script language="JavaScript">
<!--

var weekArr = new Array("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat");
var monthArr = new Array();
for (i=0; i<31; i++) monthArr[i] = i+1;

window.onload = function ()
{
	distFreqSpec();
}

function distFreqSpec()
{
	var e = reportDistributionForm.reportDistFrequency;
	var ee = document.getElementById("distributeFreqSpec");
	//var eeContent = document.getElementById("distributeSpecFreqTD");
	var specSelect = document.getElementsByName("freqSpec")[0];
	specSelect.options.length = 0;
	var idx=0;
	
	if (e.options[2].selected) {
		// weekly
		var s = "";	//"<select class='plaintext' name='freqSpec'>";
		for (i=0; i<weekArr.length; i++) {
			specSelect.options[idx] = new Option(weekArr[i],  (i+1));
			if ('<%=currentDistFreqSpec%>' == "" + (i+1))
				specSelect.options[idx].selected = true;
			idx++;
		}
		//s += "</select>";
		//eeContent.innerHTML = s;		
	}
	else if (e.options[3].selected) {
		// monthly
		var s = "";
		for (i=0; i<monthArr.length; i++) {
			specSelect.options[idx] = new Option(monthArr[i],  monthArr[i]);
			if (monthArr[i] == '<%=currentDistFreqSpec%>')
				specSelect.options[idx].selected = true;
			idx++;
		}
	}
	else {
		// other distribution options selected
		ee.style.display = 'none';
		return;
	}
	ee.style.display = 'block';
}

function affirm_summary(loc)
{
		location = loc;
}

function optimize_schedule()
{
	var msg  = "Optimize the schedule may cause the task and project schedule to change.\n";
	    msg += "You should only perform this operation if you are sure that all your\n";
	    msg += "task Durations and Gaps are set up already.  Do you really want to proceed?\n\n";
		msg += "   OK = Yes\n";
		msg += "   CANCEL = No";
	if (confirm(msg))
		location = "proj_profile.jsp?projId=<%=projIdS%>&&optimize=true";
}

function fixElement(e, msg)
{
	alert(msg);
	if (e)
		e.focus();
}

function setAddFile()
{
	if (multi_selector.count == 1)
	{
		fixElement(document.getElementById("my_file_element"), "To add a file attachment, click the Browse button and choose a file to be attached, then click the Add button.");
		return false;
	}
	if (!validation())
		return false;

	return true;
}

function validation()
{
	formblock= document.getElementById('inputs');
	forminputs = formblock.getElementsByTagName('input');
	var isFileName = true;
	for (var i=0; i<forminputs.length; i++) {
		if (forminputs[i].type == 'file' && forminputs[i].value != '') {
			if (isFileName)
				isFileName = affirm_addfile(forminputs[i].value);
			else
				break;
		}
	}
	if(!isFileName)
		return isFileName;

	if(!findDuplicateFileName(forminputs))
		return false;

	return true;
}

function handleDistribute(sendNow)
{
	var f = document.reportDistributionForm;
	if (sendNow)
		f.sendNow.value = "true";
	getall(f.DistributeMembers);		// @ECC060407
	f.submit();
}

//-->
</script>

<title>
	<%=Prm.getAppTitle()%> Upload Status Report
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
	            <table width="90%" border="0" cellspacing="0" cellpadding="0">
				  <tr>
					<td width="26" height="30"><a name="top">&nbsp;</a></td>
					<td height="30" align="left" valign="bottom" class="head">
						<b>Upload Status Report</b>
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
		<!-- Content Table -->

		 <table width="100%" border="0" cellspacing="0" cellpadding="0">


			<tr><td colspan="2">&nbsp;</td></tr>
			<tr>
				<td width="20"><img src="../i/spacer.gif" width="5" border="0"></td>
				<td width="734">

<!-- Page Headers -->
 	 <table width="90%" border="0" cellpadding="0" cellspacing="0">

			<tr>
				<td width="450" class="heading">
				<font size="3"></font>
				</td>

	<td valign="top">
	<table>

	</table>
	</td>

			</tr>
		</table>

		</tr>
		</table>



<!-- BEGIN INTERNAL CELL -->

	<br>
	<table width="100%" border="0" cellspacing="0" cellpadding="0">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>


<!-- CONTENT LEFT -->
<table width="100%" border="0" cellspacing="0" cellpadding="0">

<tr>

<td valign="top">
<!-- PROJ PROFILE -->
<table height="110">
	<tr>
		<td width="20">&nbsp;</td>
		<td colspan="2">
<!-- Project Name -->
<form action="proj_report.jsp" method="get">
	<table width="100%" border="0" cellpadding="0" cellspacing="0">

	<tr>

	<td class="heading">
		Project Name:&nbsp;&nbsp;
		<select name="projId" class="formtext" onchange="submit()">
<%
	int [] projectObjId;
	if (isDirector || isAdmin || isProgMgr)
		projectObjId = pjMgr.getProjects(pstuser);
	else
		projectObjId = pjMgr.findId(pstuser, "Owner='"+pstuser.getObjectId()+"'");

	if (projectObjId.length > 0)
	{
		PstAbstractObject [] projectObjList = pjMgr.get(pstuser, projectObjId);
		Util.sortName(projectObjList, true);

		String pName;
		int pid;
		project pj;
		Date expDate;
		String expDateS = new String();
		for (int i=0; i < projectObjList.length ; i++)
		{
			// project
			pj = (project) projectObjList[i];
			pid = pj.getObjectId();
			pName = pj.getDisplayName();

			out.print("<option value='" + pid +"' ");
			if (pid == projId)
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
	</td>
	</tr>

	<tr>
		<td width="20">&nbsp;</td>
		<td width="180">&nbsp;</td>
		<td>&nbsp;</td>
	</tr>

<!-- message -->
<%
	String msg = request.getParameter("msg");
	if (msg!=null && msg.length()>0) {
		out.print("<tr><td width='20'>&nbsp;</td>");
		out.print("<td colspan='2' class='message'>"
			+ msg
			+ "</td>");
		out.print("</tr>");
		out.print("<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>");
	}
%>

<!-- Executive Summary task ID -->
<%
	// get the current SUMMARY_ID from project option if any
	String summaryIdS = proj.getOption(project.EXEC_SUMMARY);
	if (summaryIdS == null) {
		summaryIdS = "";
	}
%>

<form name='projReportForm' action='post_proj_report.jsp' method='post'>
<input type='hidden' name='op' value='execSummary'>
<input type='hidden' name='projId' value='<%=projIdS%>'>

	<tr>
		<td>&nbsp;</td>
		<td class='plaintext_bold' valign='top'>Executive Summary:</td>
		<td>
		<table border='0' cellspacing='0' cellpadding='0'>
			<tr>
				<td class='plaintext' valign='top' width='80'>
					<input type='text' name='execSummaryId' size='5'
						class='plaintext' value='<%=summaryIdS%>'>
				</td>
				<td width='300'>
					<input type='button' class='button_medium' value='Save'
						onClick='submit();'>
				</td>
			</tr>
			<tr><td class='plaintext_grey' colspan='2'>
				(Enter the task ID that contains the blog for executive summary)
			</td></tr>
		</table>
		</td>
	</tr>
</form>

	<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>

<%
	// attach report file
	Object [] attmtList = proj.getAttribute("AttachmentID");
	ArrayList statusRepList = new ArrayList();
	String summaryDoc = null;
	String msProjDoc = null;
	String attmt = null;
	String fileName;
	attachment attmtObj;
	if (attmtList[0]!= null)
	{
		for (int i=0; i<attmtList.length; i++)
		{
			try {attmtObj = (attachment)aMgr.get(pstuser, (String)attmtList[i]);}
			catch (Exception e) {
				proj.removeAttribute("AttachmentID", attmtList[i]);
				pjMgr.commit(proj);
				System.out.println("proj_report.jsp: removed attachment ID [" + attmtList[i]
					+ "] from project [" + projIdS + "]");
				continue;
			}
			attmt = (String)attmtObj.getAttribute("Location")[0];
			fileName = attmtObj.getFileName();
			if (fileName == null) break;
			if (summaryDoc==null && fileName.startsWith("PRM_" + projIdS))
			{
				summaryDoc = fileName;
			}
			else if (msProjDoc==null && fileName.startsWith("PRM_MSP_" + projIdS))
			{
				msProjDoc = fileName;
			}
			else if (fileName.startsWith("PrmReport_" + projName))
			{
				statusRepList.add(fileName);
			}
		}
	}
%>

<!-- add file -->
	<tr>
		<td></td>
		<td class="plaintext" valign="top"><b>Add Status Report:</b></td>
		<td>
<form name="addFile" action="post_addfile.jsp" method="post" enctype="multipart/form-data">
<input type="hidden" name="projId" value="<%=projIdS%>">
<input type="hidden" name="backPage" value="<%=backPage %>">
<%
	Date d = new Date();
	SimpleDateFormat dF = new SimpleDateFormat("MM-dd-yy");
	fileName = "PrmReport_" + projName + "_" + dF.format(d);
%>
<input type="hidden" name="fileName" value="<%=fileName %>">
<table width="100%" cellpadding="0" cellspacing="0" border="0">
	<tr>
		<td class='plaintext'>
			<span id="inputs"><input id="my_file_element" type="file" class="formtext" size="41" />
			</span><br /><br />
			Files to be uploaded:<br />
			<table width="100%"><tbody id="files_list"></tbody></table>
			<script>
				var multi_selector = new MultiSelector( document.getElementById( 'files_list' ), 1, document.getElementById( 'my_file_element' ).className , document.getElementById( 'my_file_element' ).size );
				multi_selector.addElement( document.getElementById( 'my_file_element' ) );
			</script>
		</td>
	</tr>
	<tr>
		<td><input class="formtext_small" type="Submit" name="Submit" value="Upload Files"
			onClick="return setAddFile();">
		</td>
	</tr>
</table>
</form>
		</td>
	</tr>

<!-- file attachment -->
	<tr>
		<td></td>
		<td class="plaintext" valign="top"><b>Status Report:</b></td>
		<td class="plaintext">
			<table border="0" cellspacing="0" cellpadding="0">
<%
	// file name is: Attachment-name of doc.ext
	int size = statusRepList.size();
	if (size == 0)
	{%>
		<tr><td class="plaintext_grey">None</td></tr>
<%	}
	else
	{
		Collections.sort(statusRepList);
		for (int i=size-1; i>=0; i--)
		{
			// reverse order looks better
			attmt = (String)statusRepList.get(i);
%>
			<tr>
			<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
			<td align="left" class="listlink" width="250">
				<a class="listlink" href="<%=host%>/servlet/ShowFile?filePath=<%=projIdS%>/Attachment-<%=attmt%>"><%=attmt%></a>
			</td>
<%			if (isCoordinator || isAdmin || isDirector)
			{%>
				<td align="right"><img src="/i/spacer.gif" alt="" width="0">
					<input class="button_medium" type="button" value="delete"
						onclick="return affirm_delfile('post_delfile.jsp?report&projId=<%=projIdS%>&fname=Attachment-<%=attmt%>');">
				</td>
<%			}%>
			</tr>
<%
		}
	}
%>
			</table>
		</td>
	</tr>

<!-- Report Distribution -->
	<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>

<form name='reportDistributionForm' action='post_proj_report.jsp' method='post'>
<input type='hidden' name='op' value='distribute'>
<input type='hidden' name='projId' value='<%=projIdS%>'>
<input type='hidden' name='sendNow' value=''>

	<tr>
		<td></td>
		<td class="plaintext" valign="top"><b>Report Distribution:</b></td>
		<td>
		<table>
			<tr>
				<td class="plaintext_big" valign='top'>Email Distribution Frequency&nbsp;&nbsp;</td>
				<td>
				<select class='plaintext' name='reportDistFrequency' onChange='distFreqSpec();'>
<%
				String [] optArr = {project.DIST_MANUALLY, project.DIST_DAILY, project.DIST_WEEKLY,
									project.DIST_MONTHLY, project.DIST_POSTED};

				for (int i=0; i<optArr.length; i++) {
					out.print("<option value='" + optArr[i] + "'");
					if (optArr[i].equals(currentDistFreq))
						out.print(" selected");
					out.print(">" + optArr[i] + "</option>");
				}
%>
				</select>
				</td>

				<td>
				<input type='button' value='Distribute Report Now' onclick='handleDistribute(true);'>
				</td>
			</tr>
			<tr id='distributeFreqSpec' style='display:none'>
				<td></td>
				<td class='plaintext' id='distributeSpecFreqTD'>
						<select class='plaintext' name='freqSpec'>
						</select>
				
				</td>
			</tr>
		</table>

		<table>
			<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>
			<tr><td class="plaintext_big">Select Recipients</td></tr>


<!-- ********************** Project Team ********************** -->
<%
	// get all town people
	String townIdS = pstuser.getStringAttribute("Company");
	int [] allEmpIds = new int[0];
	Integer iObj = (Integer)pstuser.getAttribute("Towns")[0];
	if (townIdS==null && iObj!=null)
		townIdS = iObj.toString();
	if (isAdmin || townIdS==null)
		allEmpIds = uMgr.findId(pstuser, "om_acctname='%'");
	else {
		if (townIdS != null) {
			allEmpIds = uMgr.findId(pstuser, "Company='" + townIdS + "'");
		}
		// get members of the project
		if (proj != null) {			
			int [] ids = Util2.toIntArray(proj.getAttribute("TeamMembers"));			
			allEmpIds = Util2.mergeIntArray(allEmpIds, ids);
		}
	}

	PstAbstractObject [] allEmp = uMgr.get(pstuser, allEmpIds);
	Util.sortUserArray(allEmp, true);

	for (int i=0; i<allEmp.length; i++)
	{
		if (allEmp[i].getAttribute("FirstName")[0] == null)
			allEmp[i] = null;
	}

	// duplicate all town people list
	PstAbstractObject [] allEmp1 = new PstAbstractObject[allEmp.length];
	for (int i=0; i<allEmp.length; i++)
		allEmp1[i] = allEmp[i];
%>

<!-- Managed Team -->
<tr>
		<td class="plaintext">
<%
	// allEmp will be on the left while selected recipients of reort will be on the right
	Object [] dists = proj.getAttribute("Attendee");
	int [] selectedArr = Util2.toIntArray(dists);
	PstAbstractObject [] teamMember = uMgr.get(pstuser, selectedArr);
	for (int i=0; i<allEmp1.length; i++) {
		if (allEmp1[i] == null) continue;
		for (int j=0; j<selectedArr.length; j++) {
			if (allEmp1[i].getObjectId() == selectedArr[j]) {
				allEmp1[i] = null;	// selected to be shown on right hand side
				break;
			}
		}
	}


%>
		<table border="0" cellspacing="4" cellpadding="0">
		<tr>
			<td bgcolor="#FFFFFF">
			<select class="formtext_fix" name="WholeTown" id="WholeTown" multiple size="5">
<%
	String uName;

	if (allEmp1 != null && allEmp1.length > 0)
	{
		for (int i=0; i < allEmp1.length; i++)
		{
			if (allEmp1[i] == null) continue;
			uName = ((user)allEmp1[i]).getFullName();
%>
			<option value="<%=allEmp1[i].getObjectId()%>"><%=uName%></option>
<%
		}
	}

%>
			</select>
			</td>
			<td align="center" valign="middle" class="formtext">
				<input type="button" class="button" name="add" value="&nbsp;&nbsp;&nbsp;Add &gt;&gt;&nbsp;&nbsp;" onClick="swapdata(this.form.WholeTown,this.form.DistributeMembers)">
			<br><input type="button" class="button" name="remove" value="<< Remove" onClick="swapdata(this.form.DistributeMembers,this.form.WholeTown)">
			</td>
<!-- people selected -->
			<td bgcolor="#FFFFFF">
				<select class="formtext_fix" name="DistributeMembers" id="DistributeMembers" multiple size="5">

<%
	if (teamMember.length > 0 && teamMember[0] != null)
	{
		for (int i=0; i < teamMember.length; i++)
		{
			uName = ((user)teamMember[i]).getFullName();
%>
			<option value="<%=teamMember[i].getObjectId()%>"><%=uName %></option>
<%
		}
	}
%>
				</select>
			</td>
		</tr>

		<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>

		<tr>
			<td colspan='3' align='center'>
				<input type='button' class='button_medium' value='Submit'
					onClick='handleDistribute(false);'>
				<input type='button' class='button_medium' value='Cancel'
					onClick='location="proj_summary.jsp?projId=<%=projIdS%>"'>
			</td>
		</tr>
		</table>
</td>
</tr>
<!-- end of Project Team -->


		</table>

		</td>
	</tr>
</form>

</table>
</td>


</tr>
</table>


	</td>
</tr>

<!-- BEGIN FOOTER TABLE -->
<jsp:include page="/foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>
