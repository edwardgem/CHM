<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2009, EGI Technologies. All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: ep_cr.jsp (for CR and CR-OMF)
//	Author: ECC
//	Date:	07/05/05
//	Description: PRM home page.
//
//
//	Modification:
//		@051109ECC	Separate ep_home.jsp for CR from PRM.
//		@051209ECC	Added description and blog attached to files (attachments)
//
/////////////////////////////////////////////////////////////////////
//

%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.omm.common.*" %>
<%@ page import = "oct.omm.client.*" %>
<%@ page import = "oct.omm.db.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>

<%
	String noSession = "../index.jsp";	//"../out.jsp?go=ep/ep_cr.jsp";
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	String HOST = Util.getPropKey("pst", "PRM_HOST");
	String UPLOAD_PATH = Util.getPropKey("pst", "FILE_UPLOAD_PATH");
	String VIEWONLY = "VIEWONLY";
	final String SIZE_TERM		= "?#";			// must be the same as UploadFile.java
	final String LIGHT			= "bgcolor='#ffffff'";
	final String DARK			= "bgcolor='#fafafa'";
	final String HEAD_LINE =
		"<tr><td><table border='0' cellspacing='0' cellpadding='0'>"
		+ "<tr><td><img src='../i/spacer.gif' width='26' height='1' /></td><td bgcolor='#ee0000'><img src='../i/spacer.gif' height='1' width='30' /></td><td width='100'></td></tr>"
		+ "<tr><td></td><td colspan='2' width='150' bgcolor='#ee0000'><img src='../i/spacer.gif' width='100' height='1' /></td></tr>"
		+ "</table></td></tr>";

	final String DEFAULT_EDIT_STR = "Enter description ...";
	final String DEFAULT_COMMENT_STR = "Write a comment ...";
	
	PstUserAbstractObject me = pstuser;
	if (me instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?go=ep/ep_cr.jsp?e=time out");
		return;
	}
	
	// @ECC042309 get short profile
	String FirstName = (String)me.getAttribute("FirstName")[0];
	String LastName  = (String)me.getAttribute("LastName")[0];
	if (FirstName==null || LastName==null || FirstName.length()<=0 || LastName.length()<=0)
	{
		response.sendRedirect("profiling.jsp");
		return;
	}
	
	String backPage = "../ep/ep_cr.jsp";
	Date lastLogin = (Date)session.getAttribute("lastLogin");
	String s;
	PstAbstractObject obj;
	Date dt, complete;

	boolean isAdmin = false;
	boolean isProgMgr = false;			// @ECC062806
	boolean isAcctMgr = false;			// @ECC081108
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if (iRole > 0)
	{
		if ((iRole & user.iROLE_ADMIN) > 0)
			isAdmin = true;
		if ((iRole & user.iROLE_PROGMGR) > 0)
			isProgMgr = true;
		if ((iRole & user.iROLE_ACCTMGR) > 0)
			isAcctMgr = true;
	}

	// to check if session is CR, OMF, or PRM
	boolean isCRAPP = false;
	String app = (String)session.getAttribute("app");
	if (app.indexOf("CR")!=-1)
		isCRAPP = true;
	
	// @ECC081407 Blog Module
	boolean isBlogModule = false;
	s = Util.getPropKey("pst", "MODULE");
	if (s!=null && s.equalsIgnoreCase("Blog"))
		isBlogModule = true;
	
	// @ECC080108 Multiple company
	boolean isMultiCorp = false;
	s = Util.getPropKey("pst", "MULTICORPORATE");
	if (s!=null && s.equalsIgnoreCase("true"))
		isMultiCorp = true;
	
	String label1;
	if (isCRAPP)
		label1 = "Workspace";
	else
		label1 = "Projects";

	taskManager tkMgr = null;
	planTaskManager ptMgr = null;
	userManager uMgr = userManager.getInstance();
	townManager tnMgr = townManager.getInstance();
	resultManager rMgr = resultManager.getInstance();

	int myUid = me.getObjectId();
	String uid = request.getParameter("uid");
	int uidInt = 0;

	if ((uid == null) || (uid.equals("null")))
	{
		uidInt = myUid;
		uid = String.valueOf(myUid);
	}
	else
	{
		uidInt = Integer.parseInt(request.getParameter("uid"));
	}

	me = (user)uMgr.get(me, uidInt);			// get it from the database
	String sortby = (String) request.getParameter("sortby");

	String Title = (String)me.getAttribute("Title")[0];
	String fName = (String)me.getAttribute("FirstName")[0];
	
	// userinfo
	userinfo myUi = (userinfo)userinfoManager.getInstance().get(me, uid);


	Date now = Calendar.getInstance().getTime();
	//SimpleDateFormat df1 = new SimpleDateFormat ("yyyy.MM.dd");
	SimpleDateFormat df0 = new SimpleDateFormat ("MM/dd/yy");
	SimpleDateFormat df1 = new SimpleDateFormat ("yyyy.MM.dd.hh.mm");
	SimpleDateFormat df2 = new SimpleDateFormat ("MMM dd, yyyy h:mm a");
	SimpleDateFormat df3 = new SimpleDateFormat ("MM/dd/yy h:mm a");
	SimpleDateFormat df4 = new SimpleDateFormat ("MM dd yyyy hh mm");
	SimpleDateFormat df5 = new SimpleDateFormat ("hh:mm a MMM dd");

	// @ECC050307 Option to show closed projects
	boolean bShowClosedPj = false;
	s = request.getParameter("ShowCProj");
	if (s!=null && s.equals("true"))
		bShowClosedPj = true;
	
	// Option to show/hide shared files
	boolean bShowShared = true;
	s = request.getParameter("showShare");
	if (s != null)
	{
		session.setAttribute("showShare", s);
	}
	else
		s = (String)session.getAttribute("showShare");
	if (s!=null && s.equals("false"))
		bShowShared = false;
	
	boolean bUseEmailUserName = false;
	s = Util.getPropKey("pst", "USERNAME_EMAIL");
	if (s!=null && s.equalsIgnoreCase("true"))
		bUseEmailUserName = true;
	
	// display options on Shared Files
	boolean bShowAllNames = ((s = request.getParameter("ShowAllNm"))!=null && s.equals("true"));
	s = request.getParameter("ShowSimple");
	if (s == null)
		s = Util2.getUserPreference(me, "ShowSimple");
	else
		Util2.setUserPreference(me, "ShowSimple", s);
	boolean bShowSimple = (s!=null && s.equals("true"));

%>


<head>
<title><%=app%> Home</title>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<script language="JavaScript" src="../get-date.js"></script>
<script language="JavaScript" src="../date.js"></script>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../file_action.jsp" flush="true"/>

<%
	response.setHeader("Pragma", "No-Cache");
	response.setDateHeader("Expires", 0);
	response.setHeader("Cache-Control", "no-Cache");
%>

<script type="text/javascript">
<!--
var bUsernameEmail = <%=bUseEmailUserName%>;	// for file_action.jsp

// @ECC050307
function toggleClosedProject()
{
	var e = document.getElementById("ShowClosedProj");
	location = 'ep_cr.jsp?ShowCProj=' + e.checked;
}

function toggleAllShare(ch)
{
	var e1 = document.getElementById("ShowAllNm");
	var e2 = document.getElementById("ShowSimple");
	if (ch != null)
		e1.checked = ch;
	location = 'ep_cr.jsp?ShowAllNm=' + e1.checked + "&ShowSimple=" + e2.checked;
}

function toggleShowSimple()
{
	var e1 = document.getElementById("ShowAllNm");
	var e2 = document.getElementById("ShowSimple");
	location = 'ep_cr.jsp?ShowSimple=' + e2.checked + "&ShowAllNm=" + e1.checked;
}

function showAllComment(id)
{
	var e1 = document.getElementById("ShowAllNm");
	var e2 = document.getElementById("ShowSimple");
	location = 'ep_cr.jsp?ShowAllNm=' + e1.checked + "&ShowSimple=" + e2.checked + "&sa=" + id + "#" + id;
}

function goOMF()
{
	location = "http://www.MeetWE.com/meeting/cal.jsp?bck=" + location.href;
}

function upgrade()
{
	location = "../info/upgrade.jsp";
}


function del()
{
	if (!hasCheckFile("fileList"))
	{
		alert("To remove files from your SHARE FILE LIST, select one or more files before clicking the REMOVE icon.");
		return false;
	}

	var s = "If you are not the owner of the file, once you remove it from your SHARE FILE LIST, you would not be able to access the file.\n\nDo you really want to remove the file from your list?";
	if (!confirm(s))
		return false;
		
	// remove all checked items: just remove the ShareID from the attachment
	var f = document.FileAction;
	var fIds = getCheckedFileIds("fileList");
	if (fIds != "")
	{
		f.ids.value = fIds;
		f.action = "post_del_share.jsp"
		f.submit();
	}
}

function showShare(op)
{
	if (op == 1)
		location = 'ep_cr.jsp?showShare=false';
	else
		location = 'ep_cr.jsp?showShare=true';
}

function enterDesc(type, id)
{
	// the textarea was onfocus
	if (type == 0)
		defStr = "<%=DEFAULT_EDIT_STR%>";
	else
		defStr = "<%=DEFAULT_COMMENT_STR%>";
	var e = document.getElementById(id);
	if (e.value == defStr)
		e.value = "";
	e.focus();
}

function leftDesc(type, id)
{
	if (type == 0)
		defStr = "<%=DEFAULT_EDIT_STR%>";
	else
		defStr = "<%=DEFAULT_COMMENT_STR%>";
	var e = document.getElementById(id);
	var str = trim(e.value);
	if (str == "")
		e.value = defStr;
}

function checkKey(obj, evt)
{
	var mlength = obj.getAttribute? parseInt(obj.getAttribute("maxlength")) : "";
	if (obj.getAttribute && obj.value.length>mlength)
		obj.value=obj.value.substring(0,mlength);

	var code = evt.keyCode? evt.keyCode : evt.charCode;
	if (code == 13)
	{
		// submit the entry
		var f = document.FileAction;
		f.entry.value = obj.getAttribute("id");
		if (f.entry.value.indexOf("desc_") != -1)
			return;									// desc is saved by explicitly clicking SAVE
		f.action = "post_ep_home.jsp"
		f.submit();
	}
}

function editDesc(id)
{
	// the Edit icon is clicked: toggle the description edit panel
	var e = document.getElementById("editDescPanel_" + id);
	if (e.style.display == "none")
	{
		e.style.display = "block";
		enterDesc(0, "desc_" + id);
	}
	else
		e.style.display = "none";
}

function saveDesc(id)
{
	// save button clicked on share file description
	var f = document.FileAction;
	f.entry.value = "desc_" + id;
	f.action = "post_ep_home.jsp"
	f.submit();
}
//-->
</script>

<style type="text/css">
.comment {font-family: Verdana, Arial, Helvetica, sans-serif; width:98%; height:30px; font-size: 11px; color: #777777; padding-top:3px; line-height: 16px; overflow:hidden; }
.desc {font-family: Verdana, Arial, Helvetica, sans-serif; width:98%; height:50px; font-size: 11px; color: #777777; padding-top:3px; line-height: 16px; overflow:hidden; }
</style>

</head>

<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">
	<table width="100%" border="0" cellspacing="0" cellpadding="0">
  		<tr align="left" valign="top">
    	<td width="100%">
		<jsp:include page="../head.jsp" flush="true"/>
	</table>
<table border="0" cellspacing="0" cellpadding="0">
  <tr align="left" valign="top">
    <td>
      <table width="780" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td>
            <table width="780" border="0" cellspacing="0" cellpadding="0">
              <tr>
                <td width="26" height="30"><a name="top">&nbsp;</a></td>
                <td width="528" height="20" align="left" valign="bottom" class="head">
				Hi, <%=fName%>
				</td>
<%	if (isMultiCorp)
	{
				int idx;
				String levelS = (String)myUi.getAttribute("Status")[0];
				if (levelS == null)
					levelS = userinfo.LEVEL_1;
				else if ((idx = levelS.indexOf('@')) != -1)
					levelS = levelS.substring(0, idx);
				out.print("<td align='right'><a href='../info/upgrade.jsp' class='listlink'><b>" + levelS + " Membership</a></b></td>");
	}
%>
              </tr>
            </table>
          </td>
        </tr>
        <tr>
          <td width="100%">
<!-- TAB -->
			<jsp:include page="../in/home.jsp" flush="true">
			<jsp:param name="role" value="<%=iRole%>" />
			</jsp:include>
		  </td>
        </tr>
		<tr>
          <td width="100%" valign="top">
			<!-- Navigation SUB-Menu -->
			<table border="0" width="780" height="1" cellspacing="0" cellpadding="0">
				<tr>
					<td width="20" height="1" bgcolor="#FFFFFF"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
				</tr>
			</table>
			<table border="0" width="780" height="14" cellspacing="0" cellpadding="0">
				<tr>
					<td width="20" height="14" bgcolor="#FFFFFF"><img src="../i/spacer.gif" width="20" height="1" border="0" /></td>
					<td valign="top" align="left" class="BgSubnav">
						<table border="0" cellspacing="0" cellpadding="0">
						<tr class="BgSubnav">
						<td width="40"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
					<!-- Home -->
						<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
						<td width="7"><img src="../i/spacer.gif" width="7" height="1" border="0"></td>
						<td width="15" height="14"><img src="../i/nav_arrow.gif" width="20" height="14" border="0"></td>
						<td><a href="#" onClick="return false;" class="subnav"><u>Home</u></a></td>
						<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
						<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<!-- Search -->
						<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
						<td><a href="search.jsp" class="subnav">Search</a></td>
						<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
						<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
<%	if (isCRAPP && isMultiCorp){ %>
					<!-- Download -->
						<td width="7"><img src="../i/spacer.gif" width="7" height="1" border="0"></td>
						<td><a href="../info/download.jsp" class="subnav">Download for Remote Backup</a></td>
						<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
						<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
<%	}

	if (isCRAPP && isMultiCorp && (isAdmin || isAcctMgr) ) {%>
				<!-- New Company -->
								<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
								<td><a href="../admin/comp_new.jsp" class="subnav">New Company</a></td>
								<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
								<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
<%	}
%>
						</tr>
								</table>
							</td>
						</tr>
					</table>
					<table border="0" width="780" height="1" cellspacing="0" cellpadding="0">
						<tr>
							<td width="20" height="1" bgcolor="#FFFFFF"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
							<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
						</tr>
					</table>
					<!-- End of Navigation SUB-Menu -->
				</td>
	        </tr>

        <tr><td>&nbsp;</td></tr>
<!-- ********* Begin List of Companies -->
<%
	String uname;
	projectManager pjMgr = projectManager.getInstance();
	int [] ids;

	String bgcolor="";
	boolean even = false;
	boolean bBold;
	int maxPhases = 0;

	/////////////////////////////////////////////////////////////
	if (isCRAPP && isMultiCorp && (isAdmin || isAcctMgr))
	{
%>
		<tr>
		<td>
           <table width="780" border="0" cellspacing="0" cellpadding="0">
		  	<tr>
             		<td width="26">&nbsp;</td>
               	<td width="754">
			  		<table width="100%" border='0' cellpadding="0" cellspacing="0">
						<tr>
							<td class="heading">Companies</td>
						</tr>
					</table>
				</td>
			</tr>

		
			<tr>
			<td></td>
			<td>
<%
			// list companies
			if (isAdmin)
				ids = tnMgr.findId(me, "om_acctname='%'");
			else
				ids = tnMgr.findId(me, "AccountManager='" + myUid + "'");

			// show label for companies
			String [] label0 = {"&nbsp;Company Name", "Program Mgr", "Start Date", "# of Employee", "Departments"};
			int [] labelLen0 = {280, 100, 96, 96, 126};
			boolean [] bAlignCenter0 = {false, true, true, true, true};
			if (ids.length > 0)
				out.print(Util.showLabel(label0, labelLen0, bAlignCenter0, true));		// showAll and align center
			
			PstAbstractObject tn;
			String compName, progMgrIdS, startDtS, deptNames;
			int [] ids1;
			int num;
			for (int i=0; i<ids.length; i++)
			{
				tn = tnMgr.get(me, ids[i]);
				compName = (String)tn.getAttribute("Name")[0];
				
				uname = "-";
				progMgrIdS = (String)tn.getAttribute("Chief")[0];
				if (progMgrIdS != null)
				{
					obj = uMgr.get(me, Integer.parseInt(progMgrIdS));
					uname = ((user)obj).getFullName();
				}
				deptNames = (String)tn.getAttribute("DepartmentName")[0];
				if (deptNames == null) deptNames = "-";
				else deptNames = deptNames.replaceAll(";", "; ");
				
				startDtS = "-";
				dt = (Date)tn.getAttribute("StartDate")[0];
				if (dt != null)
					startDtS = df0.format(dt);
				
				ids1 = uMgr.findId(me, "Company='" + ids[i] + "'");
				num = ids1.length;
				
				if (even)
					bgcolor = DARK;
				else
					bgcolor = LIGHT;
				even = !even;
				
				out.print("<tr " + bgcolor + ">");
				
				// name
				out.print("<td></td>");
				out.print("<td class='plaintext' valign='top'><a href='../admin/comp_update.jsp?id=" + ids[i] + "'>" + compName + "</a></td>");
				
				// program mgr
				out.print("<td colspan='2'></td>");
				out.print("<td class='plaintext' align='center' valign='top'>");
				if (progMgrIdS != null)
					out.print("<a href='../ep/ep1.jsp?uid=" + progMgrIdS + "'>" + uname + "</a>");
				out.print("</td>");
				
				// start date
				out.print("<td colspan='2'></td>");
				out.print("<td class='listtext_small' align='center' valign='top'>" + startDtS + "</td>");
				
				// total employees of the company
				out.print("<td colspan='2'></td>");
				out.print("<td class='listtext_small' align='center' valign='top'>" + num + "</td>");
				
				// departments
				out.print("<td colspan='2'></td>");
				out.print("<td class='plaintext' valign='top' style='word-break:break-all;'>" + deptNames + "</td>");
				
				out.print("</tr>");
			}
			if (ids.length <= 0)
			{
				out.print("<tr><td><img src='../i/spacer.gif' height='5' /></td></tr>");
				out.print("<tr><td></td><td colspan='5' class='plaintext_big'>");
				out.print("<img src='../i/bullet_tri.gif' width='20' height='10'>");
				out.print("<a href='../admin/comp_new.jsp'>Click to add a new company</a></td></tr>");
			}
%>
				</table>
				</td>
				</tr>
			</table>
			</td>
			</tr>
			
			<tr><td><img src='../i/spacer.gif' height='30' /></td></tr>
<%		} 	// END if isCRAPP && isMultiCorp && isProgMgr||isAdmin

%>

		<tr>
          <td>
            <table width="798" border="0" cellspacing="0" cellpadding="0">


<%
		///////////////////////////////////////////////////////////////
		// get project list
		ids = pjMgr.getProjects(me, bShowClosedPj);	// @ECC050307
%>

<!-- Start project listing label -->
			  	<tr>
              		<td width="26">&nbsp;</td>
                	<td width="754">
				  		<table border='0' width='100%' cellpadding="0" cellspacing="0">
							<tr>
								<td width='16'><img src='../i/globe.jpg' /></td>
								<td class="heading">&nbsp;<%=label1%></td>
<!-- // @ECC050307 -->
<%	if (ids.length > 0) { %>
								<td class='formtext' align='right'>
									<input type='checkbox' id='ShowClosedProj' onClick="toggleClosedProject();"
										<%if (bShowClosedPj) {out.print("checked");}%>>Show closed projects</input>
								</td>
<%	} %>								
						    </tr>
						</table>
<%
		String planPage = null;
		int len1 = 290, len2 = 96;
		String lab1 = "Expire Date";
		String lab2 = "Complete Date";
		if (isCRAPP)
		{
			planPage = "cr.jsp";	// default to cr.jsp rather than proj_plan.jsp
			if (isMultiCorp)
			{
				len1 = 335;
				len2 = 50;
				lab1 = "Expire / Done";
				lab2 = "Size";
			}
		}
		else
		{
			planPage = "proj_plan.jsp";
		}
		if (isCRAPP)
		{
			String [] label = {"&nbsp;Project Name", "Coordinator", "Start Date", lab1, lab2, "Status"};
			int [] labelLen = {len1, 105, 96, 96, len2, 30};
			boolean [] bAlignCenter = {false, true, true, true, true, true};
			if (ids.length > 0)
				out.print(Util.showLabel(label, labelLen, bAlignCenter, true));		// showAll and align center

			planPage = "cr.jsp";
		}
		PstAbstractObject personObj = null;
		int iTotal = 0;

		if (ids.length > 0)
		{
			PstAbstractObject [] pjObjList = pjMgr.get(me, ids);
			Util.sortName(pjObjList, true);  //@041906SWS
			even = false;
			
			int iSize;
			String dot, sizeS;
			dt = complete = null;
			Date today = new Date(df0.format(new Date()));
			String expDateS = "-";
			String startDateS = "-";
			String doneDateS = "-";

			for (int i=0; i < pjObjList.length; i++)
			{
				// project
				project pjObj = (project) pjObjList[i];
				String projName = pjObj.getDisplayName();
				int projId = pjObj.getObjectId();

				// updated since my lastLogin
				bBold = false;
				Date lastUpdated = (Date)pjObj.getAttribute("LastUpdatedDate")[0];
				if ( lastUpdated != null && lastLogin!=null && lastUpdated.compareTo(lastLogin) > 0)
					bBold = true;

				// status
				String color;
				String status = (String)pjObj.getAttribute("Status")[0];
				if (status == null)
				{
					response.sendRedirect("../out.jsp?e=Data integrity error: project Status is undefined.  Please contact administrator.");
					return;
				}
				// Arrays.sort(planTaskObjId);

				// get owner's first name
				String name = new String();
				String owner = (String)pjObj.getAttribute("Owner")[0];
				if(owner != null)
				{
					personObj = uMgr.get(me, Integer.parseInt(owner));
					if(personObj.getAttribute("FirstName")[0] != null)
						name = (String)personObj.getAttribute("FirstName")[0];
					//if(personObj.getAttribute("LastName")[0] != null)
					//	name = name + " " + (String)personObj.getAttribute("LastName")[0];
				}

				// get dates
				dt = (Date)pjObj.getAttribute("StartDate")[0];
				if (dt != null)
					startDateS = df0.format(dt);
				dt = (Date)pjObj.getAttribute("ExpireDate")[0];
				if (dt != null)
					expDateS = df0.format(dt);
				if (complete != null)
					doneDateS = df0.format(complete);
				else
					doneDateS = "-";

				complete = (Date)pjObj.getAttribute("CompleteDate")[0];
				
				// get project size
				iSize = ((Integer)pjObj.getAttribute("SpaceUsed")[0]).intValue();	// in MB
				iTotal += iSize;
				sizeS = Util2.getSizeDisplay(iSize, 1);

				if (even)
					bgcolor = DARK;
				else
					bgcolor = LIGHT;
				even = !even;
%>

			<tr <%=bgcolor%>>
					<td class="plaintext"></td>
				<td class="plaintext"><a href='../project/<%=planPage%>?projId=<%=projId%>' class='listlink'><%=projName%></a></td>
					<td class="plaintext"></td>
					<td class="plaintext"></td>
				<td class="plaintext" align="center"><a href="../ep/ep1.jsp?uid=<%=owner%>"><%=name%></a></td>
					<td class="plaintext"></td>

<%
					out.print("<td></td>");
					out.print("<td class='listtext_small' align='center'>" + startDateS + "</td>");
					out.print("<td></td>");
					out.print("<td></td>");
					out.print("<td class='listtext_small' align='center'>");
					if (isMultiCorp && !doneDateS.equals("-"))
						out.print(doneDateS);
					else
						out.print(expDateS);
					out.print("</td><td></td>");
					out.print("<td></td>");
					out.print("<td class='listtext_small' align='right'>");
					if (isMultiCorp)
						out.print(sizeS + "&nbsp;");
					else
						out.print(doneDateS);
					out.print("</td><td></td>");
			///////////////////////////////////////////////////////

			out.println("<td class='plaintext'></td>");
			dot = "../i/";
			if (status.equals("Open")) {dot += "dot_lightblue.gif";}
			else if (status.equals("New")) {dot += "dot_orange.gif";}
			else if (status.equals("Completed")) {dot += "dot_green.gif";}
			else if (status.equals("On-hold")) {dot += "dot_grey.gif";}
			else if (status.equals("Canceled")) {dot += "dot_cancel.gif";}
			else if (status.equals("Late"))
			{
				// Late can be completed depending on whether CompletedDate is set
				out.print("<td class='plaintext' " + bgcolor + " width='42' align='center'>");
				if (complete != null)
				{
					out.print("<img src='../i/dot_green.gif' alt='Completed'>");
				}
				out.print("<img src='../i/dot_red.gif' alt='Late'>");
			}
			else if (status.equals("Closed"))
			{
				// Closed can be coming from either Canceled or Completed
				out.print("<td class='listlink' " + bgcolor + " width='42' align='center'>");
				String lastStatus = null;
				if (complete != null)
				{
					dot += "dot_green.gif";
					lastStatus = "Completed";
				}
				else
				{
					dot += "dot_cancel.gif";
					lastStatus = "Canceled";
				}
				out.print("<img src='" + dot + "' alt='" + lastStatus + "'>");
				out.print("<img src='../i/dot_black.gif' alt='Closed'>");
			}
			else {dot += "dot_grey.gif";}

			if (!status.equals("Closed") && !status.equals("Late"))
			{
				out.print("<td class='listlink' " + bgcolor + " width='42' align='center'>");
				out.print("<img src='" + dot + "' alt='" + status + "'>");
			}

			if (bBold)
				out.print("<img src='../i/dot_redw.gif' alt='Updated'>");

			out.print("</td>");%>

					<td class="plaintext"></td>
			</tr>
<%
			}	// for each project in the list
		}	// if there is any project defined
		
		if (isCRAPP && isMultiCorp)
		{
			if (ids.length > 0)
			{
				out.print("<tr><td><img src='../i/spacer.gif' height='3' /></td></tr>");
				out.print("<tr><td></td><td colspan='5' class='plaintext'>(Total space used:"
					+ Util2.getSizeDisplay(iTotal, 1) + ")");
			}
		}
		if (isCRAPP)
		{
			out.print("<tr><td><img src='../i/spacer.gif' height='15' width='1' /></td></tr>");
			out.print("<tr><td></td><td colspan='5' class='plaintext_big'>");
			out.print("<img src='../i/bullet_tri.gif' width='20' height='10'>");
			out.print("<a href='../project/proj_new1.jsp'>Click to add a new workspace</a></td></tr>");
		}
%>
				</table>

			  	 	</td>
				 	<td width="20">&nbsp;</td>
			 	</tr>
			 </table>

<%	if (ids.length > 0) { %>
<table border="0" width="120" height="1" cellspacing="0" cellpadding="0">
	<tr><td colspan='2'><img src='../i/spacer.gif' height='20' /></td></tr>
	<tr><td></td><td><table cellspacing='0' cellpadding='0'>
		<tr><td bgcolor='#CCCCCC' height='1' width='30'><img src="../i/spacer.gif" height="1" /></td><td></td></tr>
		</table></td></tr>
	<tr>
		<td width="30" height="1"><img src="../i/spacer.gif" width="26" height="1" /></td>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" /></td>
	</tr>
</table>
<table>
	<tr>
		<td width="25">&nbsp;</td>
		<td class="tinytype" align="center">Project Status:
			&nbsp;&nbsp;<img src="../i/dot_orange.gif" border="0">New
			&nbsp;&nbsp;<img src="../i/dot_green.gif" border="0">Completed
			&nbsp;&nbsp;<img src="../i/dot_lightblue.gif" border="0">Open
			&nbsp;&nbsp;<img src="../i/dot_red.gif" border="0">Late
			&nbsp;&nbsp;<img src="../i/dot_grey.gif" border="0">On-hold
			&nbsp;&nbsp;<img src="../i/dot_cancel.gif" border="0">Canceled
			&nbsp;&nbsp;<img src="../i/dot_black.gif" border="0">Closed
			&nbsp;&nbsp;<img src="../i/dot_redw.gif" border="0">Updated
		</td>
	</tr>
</table>
<%	} %>

			</td>
		</tr>
		<tr><td><img src='../i/spacer.gif' height='30' /><a name='ShareFile'></a></td></tr>

<!-- End of List of Projects -->
<!-- ************************* -->

<!-- Start Share Files listing label -->

<%
	// @ECC091708
	PstAbstractObject [] pstArr;
	if (isCRAPP)
	{
		attachmentManager aMgr = attachmentManager.getInstance();
		ids = aMgr.findId(pstuser, "ShareID='" + myUid + "'");
		PstAbstractObject [] aObjArr = aMgr.get(pstuser, ids);
		attachmentManager.sortByName(aObjArr, true);

		int showAllId = ((s = request.getParameter("sa"))!=null)?Integer.parseInt(s):0;

		// print the header
		String moreLink = "";
		out.print("<tr><td>");
		out.print("<table width='780' border='0' cellspacing='0' cellpadding='0'>");
  		out.print("<tr><td width='26'>&nbsp;</td>");
    	out.print("<td width='754'>");
	  	out.print("<table width='100%' border='0' cellpadding='0' cellspacing='0'><tr>");
	  	out.print("<td width='16'><img src='../i/globe_green.jpg' alt='Shared Files'/></td>");
		out.print("<td class='heading' title='Shared Files'>&nbsp;Shared Files</td>");
		if (ids.length > 0)
		{
			out.print("<td class='formtext' align='right' width='180'>");
			out.print("<input type='checkbox' id='ShowSimple' onClick='toggleShowSimple();'");
			if (bShowSimple) out.print("checked");
			out.print(">Show simple list</input></td>");
			out.print("<td class='formtext' align='right' width='180'>");
			out.print("<input type='checkbox' id='ShowAllNm' onClick='toggleAllShare();'");
			if (bShowAllNames) out.print("checked");
			else moreLink = " ... <a href='javascript:toggleAllShare(true);'>@@ more</a>";	// @@ will be replaced below
			out.print(">Show all collaborators</input></td>");
		}								
		out.print("</tr></table></td></tr>");
		out.print("<tr><td></td>");
		
		if (ids.length > 0)
		{
			// list the share files
			// label for each hostname
			out.print("<td>");
			out.print("<form name='FileAction' method='post' action=''>");
			out.print("<input type='hidden' name='ids' value=''>");
			out.print("<input type='hidden' name='fname' value=''>");
			out.print("<input type='hidden' name='label' value=''>");
			out.print("<input type='hidden' name='backPage' value='" + backPage + "'>");
			out.print("<input type='hidden' name='iTypeLabel' value=''>");
			out.print("<input type='hidden' name='entry' value=''>");		// for add/update of desc and comment
			
			even = false;
			String [] label = {"&nbsp;File / Folder Name", "Owner", "Last Modified", "Size", "View #", "Shared By", "Action"};
			int [] labelLen = {290, 95, 85, 55, 40, 135, 30};
			boolean [] bAlignCenter = {false, true, true, true, true, false, true};
			out.print(Util.showLabel(label, labelLen, bAlignCenter, true));		// showAll and align center
			
			String dispName, fPathName, sizeS, shareStr="", desc, fLnk;
			Object bTextObj;
			int attId, iView, fOwnerId;
			PstAbstractObject aObj, fOwner, o;
			Object [] oArr;
			boolean isGoogle, isShareFolder;

			bgcolor = "";

			if (bShowShared)
			for (int i=0; i<aObjArr.length; i++)
			{
				// start listing the shared files
				aObj = (attachment)aObjArr[i];
				attId = aObj.getObjectId();			//ids[i];
				dispName = ((attachment)aObj).getFileName();	//fPathName.substring(fPathName.lastIndexOf('/')+1);
				if (dispName.indexOf('$') != -1)
				{
					isShareFolder = true;
					dispName = "(" + dispName.replace("$", ") ");	// peace$C:/Doc to (peace) C:/Doc
				}
				else
					isShareFolder = false;
				fPathName = (String)aObj.getAttribute("Location")[0];
				if (fPathName.startsWith("http:")) isGoogle = true;
				else isGoogle = false;
				if (fPathName.charAt(0) == '/')
					fPathName = UPLOAD_PATH + "/" + fPathName;		// it's relative path name
				uname = "-";
				fOwnerId = -1;
				
				try
				{
					fOwnerId = Integer.parseInt((String)aObj.getAttribute("Owner")[0]);
					fOwner = uMgr.get(pstuser, fOwnerId);
					uname = (String)fOwner.getAttribute("FirstName")[0];
					if (uname==null || uname.length()<=0)
						uname = ((user)me).getFullName();
				}
				catch (Exception e) {}
				
				// list all sharing parties
				shareStr = "";
				oArr = aObj.getAttribute("ShareID");
				int [] iArr = Util2.toIntArray(oArr);
				pstArr = uMgr.get(pstuser, iArr);
				Util.sortString(pstArr, "FirstName", true);
				for (int j=0; j<pstArr.length; j++)
				{
					if (!bShowAllNames && j>=3) {shareStr += moreLink.replace("@@", "("+pstArr.length+")"); break;}
					o = pstArr[j];	//uMgr.get(pstuser, Integer.parseInt((String)oArr[j]));
					s = (String)o.getAttribute("FirstName")[0];
					if (shareStr.length() > 0) shareStr += ", ";
					shareStr += "<a href='ep1.jsp?uid=" + pstArr[j].getObjectId() + "'>" + s + "</a>";
				}

				// view
				iView = ((Integer)aObj.getAttribute("Frequency")[0]).intValue();
				
				if (bShowSimple)
				{
					if (even)
						bgcolor = DARK;
					else
						bgcolor = LIGHT;
					even = !even;
				}
				
				out.print("<tr " + bgcolor + ">");
				
				// shared file/folder
				out.print("<td><a name='" + attId + "'></a></td>");
				out.print("<td class='plaintext' valign='top'><a href='");
				if (!isShareFolder)
					fLnk = HOST + "/servlet/ShowFile?attId=" + attId;
				else
					fLnk = "rdata.jsp?attId=" + attId;
				out.print(fLnk);
				out.print("'>" + dispName + "</a>");
				if (isGoogle)
				{
					out.print("&nbsp;<img src='../i/");
					if (even) out.print("Gdocs.gif'");
					else out.print("Gdocs_g.gif'");
					out.print(" title='This is a Google Docs' />");
				}
				out.print("</td>");

				// owner: for personal backup, must be me.  But it can be shared folder.
				out.print("<td colspan='2'></td>");
				out.print("<td class='plaintext' align='center' valign='top'>");
				out.print("<a href='../ep/ep1.jsp?uid=" + fOwnerId + "'>" + uname + "</a>");
				out.print("</td>");
				
				// created date
				File fObj = new File(fPathName);
				dt = new Date(fObj.lastModified());
				out.print("<td colspan='2'></td>");
				out.print("<td class='listtext_small' align='center' valign='top'>");
				if (fObj.exists()) out.print(df0.format(dt));
				else out.print("-");
				out.print("</td>");
				
				// size
				sizeS = Util2.fileSizeDisplay(fObj.length());
				out.print("<td colspan='2'></td>");
				out.print("<td class='listtext_small' align='right' valign='top'>" + sizeS + "&nbsp;</td>");
				
				// view #
				sizeS = Util2.fileSizeDisplay(fObj.length());
				out.print("<td colspan='2'></td>");
				out.print("<td class='listtext_small' align='center' valign='top'>" + iView + "&nbsp;</td>");
				
				// shared by 
				out.print("<td colspan='2'></td>");
				out.print("<td class='plaintext' align='left' valign='top'>");
				if (!bShowAllNames)
					out.print(shareStr);		// if bShowAllNames, show all in a separate line
				out.print("</td>");
				
				// delete 
				out.print("<td colspan='2'></td>");
				out.print("<td align='center' valign='top'><input type='checkbox' name='fileList' value=\"" + attId + "\"></td>");
				
				out.println("</tr>");
				
				if (bShowAllNames)
				{
					out.print("<tr><td colspan='17'><table><tr><td><img src='../i/spacer.gif' width='20' height='1' /></td>");
					out.print("<td class='plaintext'>Shared by (" + pstArr.length + "): " + shareStr
							+ " &nbsp; (<a href='javascript:toggleAllShare(false);'>hide</a>)</td></tr></table></td></tr>");
					out.print("<tr><td><img src='../i/spacer.gif' height='5' /></td></tr>");
				}

				if (!bShowSimple)
				{
					// show file description and thrumb nail
					bTextObj = aObj.getAttribute("Description")[0];
					desc = (bTextObj==null) ? null : new String((byte[])bTextObj);
					s = desc;					// s is to be display in textarea
					if (desc == null)
					{
						desc = "<tr><td><table cellspacing='0' cellpadding='0'><tr><td class='plaintext_grey'>&nbsp;&nbsp;No description</td>";
						s = DEFAULT_EDIT_STR;
					}
					else
					{
						// display the discription: need to change \n into <br>
						desc = "<tr><td><table cellspacing='0' cellpadding='5'><tr><td width='354' bgcolor='#eeeeff' class='plaintext'>"
							+ desc.replaceAll("\n", "<br>") + "</td>";
					}
					if (fOwnerId == myUid)
					{
						// textarea to enter desc
						desc += "<td valign='top'>&nbsp;&nbsp;<a onclick='editDesc(" + attId + ");'><img src='../i/icon_note.gif' border='0' title='Edit description'></a></td>"
							+ "</tr></table></td></tr>"
							+ "<tr><td><div id='editDescPanel_" + attId + "' style='display:none;'>"
							+ "<table border='0' cellspacing='0' cellpadding='5'><tr>"
							+ "<td bgcolor='#eeeeff' width='354'><textarea id='desc_" + attId + "' name='desc_" + attId + "' "
							+ "class='desc' rows='1' cols='58' onKeyUp='checkKey(this, event);' maxlength='300' "
							+ "onFocus='enterDesc(0, \"desc_" + attId + "\");' onBlur='leftDesc(0, \"desc_" + attId + "\");'>" + s + "</textarea></td>"
							+ "<td valign='top'>&nbsp;&nbsp;<input type='button' class='button' value='Save' onClick='saveDesc(" + attId + ");'></td>"
							+ "</tr></table></div></td></tr>";
					}
					else
						desc += "</tr></table></td></tr>";
	
					String visitorNames = Util2.getNames(me, (String)aObj.getAttribute("ViewBy")[0], 15);
					String thNail = Util3.getThrumbNail(aObj, 80, 80, 50);
					int idx = dispName.lastIndexOf("/");
					if (idx != -1)
						dispName = dispName.substring(idx+1);
					s = (String)aObj.getAttribute("Type")[0];
					if (s!=null && s.equals(attachment.TYPE_FOLDER))
						dispName = "Folder: " + dispName;
	
					// description
					out.print("<tr " + bgcolor + "><td></td><td colspan='19'><table><tr>");
					out.print("<td valign='top' width='85' height='80'>");
					out.print("<a href='" + fLnk + "'><img src=" + thNail + " height='");
					if (thNail.indexOf("/i/") != -1)
						out.print("30");
					else
						out.print("80");
					out.print("' style='margin:10px; padding:5px; border:2px solid #aaaaaa;'/></a>");				
					out.print("<td width='650' valign='bottom'>");
					out.print("<table cellspacing='0' cellpadding='0'><tr><td class='plaintext_bold'>" + dispName + "</td></tr>");
					out.print(desc);
					out.print("<tr><td><img src='../i/spacer.gif' height='5'/></td></tr>");
					out.print("<tr><td class='plaintext'>Recently opened by: " + visitorNames + "</td></tr>");
					out.print("<tr><td>&nbsp;</td></tr>");
					
					// rating
					int votes = ((Integer)aObj.getAttribute("VoteNum")[0]).intValue();
					int totalRating = ((Integer)aObj.getAttribute("Rating")[0]).intValue();	
					double rating = -1;
					if (votes > 0) rating = ((double)totalRating)/votes;
					String lnk = "../ep/ep_cr.jsp";

					out.print("<tr><td><table cellspacing='0' cellpadding='0'><tr>");
					//out.print("<td class='plaintext' valign='top'><b>Rating:</b></td>");
					out.print("<td class='plaintext'>");
%>
		<jsp:include page="../info/rating.jsp" flush="true">
		<jsp:param name="ratingS" value="<%=rating%>" />
		<jsp:param name="votes" value="<%=votes%>" />
		<jsp:param name="id" value="<%=attId%>" />
		<jsp:param name="uid" value="<%=myUid%>" />
		<jsp:param name="app" value="<%=app%>" />
		<jsp:param name="backPage" value="<%=lnk%>" />
		</jsp:include>
<%					
					out.print("</td></tr></table></td></tr>");
					
					// list comments
					String author, commentS, timeS, picURL, lnkS;
					user uObj;
					int [] ids1 = rMgr.findId(me, "TaskID='" + attId + "' && Type='" + result.TYPE_ATTMT_BLOG + "'");
					int ct = 0;
					for (int j=ids1.length-1; j>=0; j--)
					{
						if (++ct > 10)
							break;					// at most show 15 comments (should delete the others)
						out.print("<tr><td><table cellpadding='5' cellspacing='0'><tr>");
						out.print("<td width='354' bgcolor='#eeeeff'><table width='100%' cellspacing='0' cellpadding='0'>");
						if (ct>3 && showAllId!=attId)
						{
							out.print("<tr><td class='plaintext'><a href='javascript:showAllComment(" + attId + ");'>Show more comments ...</a></td></tr>");
							out.print("</table></td></table></td></tr>");
							out.print("<tr><td><img src='../i/space.gif' height='2' /></td></tr>");
							break;
						}
						try
						{
							o = rMgr.get(me, ids1[j]);
							bTextObj = o.getAttribute("Comment")[0];
							if (bTextObj == null) continue;
							commentS = new String((byte[])bTextObj);
							s = (String)o.getAttribute("Creator")[0];
							uObj = (user)uMgr.get(me, Integer.parseInt(s));
							lnkS = "<a href='ep1.jsp?uid=" + s + "'>";
							author = lnkS + (String)uObj.getFullName() + "</a>";
							timeS = " at " + df5.format((Date)o.getAttribute("CreatedDate")[0]);
							picURL = Util2.getPicURL(uObj);
						}
						catch (Exception e) {continue;}
						out.print("<tr><td width='40'>" + lnkS + "<img src='" + picURL + "' width='40' border='0'/></a></td>");
						out.print("<td><img src='../i/spacer.gif' width='2'/></td>");
						out.print("<td valign='top'><table>");
						out.print("<tr><td class='plaintext_small'>" + author + timeS + "</td></tr>");
						out.print("<tr><td class='plaintext'>" + commentS + "</td></tr>");
						out.print("</table></td></tr></table></td></table></td></tr>");
						
						out.print("<tr height='2'><td><img src='../i/space.gif' height='2' /></td></tr>");
					}
						
					// add a comment
					out.print("<tr><td><table cellpadding='5' cellspacing='0'><tr>");
					out.print("<td width='354' bgcolor='#eeeeff'><textarea id='comm_" + attId + "' name='comm_" + attId + "' "
							+ "onFocus='enterDesc(1, \"comm_" + attId + "\");' onBlur='leftDesc(1, \"comm_" + attId + "\");' "
							+ "onKeyUp='checkKey(this, event);' class='comment' cols='58' rows='1' maxlength='250'>");
					out.print(DEFAULT_COMMENT_STR + "</textarea></td>");
					out.print("</tr></table></td></tr>");
							
					out.print("</table></td></tr>");
					
					out.print("</table></td></tr>");
					
					out.print("<tr><td colspan='20'><img src='../i/spacer.gif' height='3'/></td></tr>");
					out.println("<tr><td colspan='20' bgcolor='#aaaaaa'><img src='../i/spacer.gif' height='1' width='30' /></td></tr>");
					out.print("<tr><td colspan='20'><img src='../i/spacer.gif' height='3'/></td></tr>");
				}	// END if !bShowSimple
				
			}	// END for each file
			out.print("<tr><td colspan='20'><img src='../i/spacer.gif' height='5' /></td></tr>");

			if (bShowShared)
			{
				out.println(Util3.displayShareOption(pstuser, 1, 13, ids.length, 2, false, false, true));		// display the shared file w/o clipboard option
				
				String msg = request.getParameter("msg");
				if (msg!=null && msg.length()>0)
				{
					out.print("<tr><td></td><td id='msg' colspan='16' class='plaintext' style='color:#00cc00'>" + msg + "</td></tr>");
				}
			}
			else
			{
				out.print("<tr><td></td>");
				out.print("<td colspan='13' id='total' class='plaintext'>&nbsp;(Total " + ids.length + " files)</td>");
				out.print("</tr>");
			}

			out.print("</table></td></tr>");
			out.print("</form>");
			
			out.println("<tr><td colspan='20'><img src='../i/spacer.gif' height='5' /></td></tr>");
			if (ids.length > 10)
			{
				out.println("<tr><td colspan='20'><img src='../i/spacer.gif' height='5' /></td></tr>");
				if (bShowShared)
					out.println("<tr><td></td><td class='plaintext_big'>&nbsp;<img src='../i/tri_up.gif' border='0' /><img src='../i/spacer.gif' width='6' /><a href='javascript:showShare(1);'>Hide the list of shared files</a></td></tr>");
				else
					out.println("<tr><td></td><td class='plaintext_big'>&nbsp;<img src='../i/tri_dn.gif' /><img src='../i/spacer.gif' width='6' /><a href='javascript:showShare(2);'>Show the list of shared files</a></td></tr>");
			}
			
			out.println("<tr><td colspan='20'><img src='../i/spacer.gif' height='5' /></td></tr>");
			out.print("<tr><td></td><td class='plaintext_big'>&nbsp;<img src='../i/bullet_tri.gif' border='0' /><a href='../file/common/RemoteAccess.jar'>Click to download shared files</a></td></tr>");
			out.print("<tr><td></td><td class='plaintext'>&nbsp;<img src='../i/spacer.gif' width='20' />(You will need Java Runtime to use CR Remote Access.) <img src='../i/bullet_tri.gif' border='0' /><a href='http://www.java.com/en/download/manual.jsp'>Click to verify/download Java SE on your computer</a></td></tr>");
		}	// END if there is any shared file
		else
		{
			out.print("<td class='plaintext'>&nbsp;&nbsp;You have no shared file.</td></tr>");
		}
		out.print("<tr><td><img src='../i/spacer.gif' height='30' /></td></tr>");
		out.print("</td></tr></table></td></tr>");
	}	// END if isCRAPP && isMultiCorp
%>
<!-- End of List of Shared Files -->
<!-- ********************* -->


<!-- Start Remote Backup listing label -->
<%
	// @ECC082008
	if (isCRAPP && isMultiCorp)
	{
		// get a list of backup areas based either in userId or companyId
		// the info is in the Backup Attr of user and company
		Object [] oArr = me.getAttribute("Backup");	// get it from DB, not cache

		if (oArr.length>0 && oArr[0]!=null)
		{
			Arrays.sort(oArr);						// peace$C:/Temp/folder1@ADMIN;ENGR
			
			// set up the form
			out.println("<form name='FolderAction' method='post' action=''>");
			out.print("<input type='hidden' name='backPage' value='" + backPage + "'>");
			out.print("<input type='hidden' name='fname' value=''>");
			out.print("<input type='hidden' name='iTypeLabel' value=''>");
			
			String path = Util.getPropKey("pst", "FILE_UPLOAD_PATH");
			String hostname="", HOSTname, dir;
			String dispName, dept, sizeS, shareName;
			String [] sa;
			int idx, hostIdx=0;
			int [] totalSize = new int[userinfo.MAX_BACKUP_HOST];
			for (int i=0; i<userinfo.MAX_BACKUP_HOST; i++) totalSize[i] = 0;

			// personal backup
			path += "/" + myUid;					// C:/Repository/CR/12345
			
			for (int i=0; i<oArr.length; i++)
			{
				s = (String)oArr[i];				// peace$C:/Temp/folder1?@ADMIN;ENGR?#278 or peace$C:/Temp/folder1?#278
				sizeS = "-";
				if ((idx = s.indexOf(SIZE_TERM)) != -1)
				{
					// extract size info
					sizeS = s.substring(idx+SIZE_TERM.length());		// e.g. 278 (in MB)
					s = s.substring(0, idx);		// cut the size info before continuing
				}
				sa = s.split("@");
				s = shareName = sa[0];				// peace$C:/Temp/folder1  (ignore access control spec)
				if (sa.length > 1)
					dept = sa[1].trim();
				else
					dept = "Private";
				
				sa = s.split("\\$");				// peace$C:/Temp/folder1
				dispName = sa[1];					// C:/Temp/folder1
	
				if (!sa[0].equals(hostname))
				{
					// start a new hostname display
					if (hostname.length() > 0)
					{
						// print the size info for the last host
						out.print("</table></td></tr>");
						out.print("<tr><td></td><td colspan='13'><table cellspacing='0' cellpadding='0'>");
						out.print("<tr><td colspan='3' class='plaintext' valign='top' width='370'>&nbsp;&nbsp;&nbsp;(Total space used: " + totalSize[hostIdx] + " MB)</td>");
						out.print("<td><table cellspacing='0' cellpadding='0'>");
						out.println(Util3.displayShareOption(pstuser, 1, 1, hostIdx, 3, true, false, false));		// display the shared file w/o clipboard option
						out.print("</table></td></tr></table></td></tr>");
						out.print("</table></td></tr>");
						out.print("<tr><td><img src='../i/spacer.gif' height='30' /></td></tr>");
						hostIdx++;
					}
					hostname = sa[0];				// peace
					int c = hostname.charAt(0);
					if (c>=97 && c<=122)
						HOSTname = (char)(c - 32) + hostname.substring(1);
					else
						HOSTname = hostname;
					
					// label for each hostname
					out.print("<tr><td>");
					out.print("<table width='780' border='0' cellspacing='0' cellpadding='0'>");
			  		out.print("<tr><td width='26'>&nbsp;</td>");
	            	out.print("<td width='754'>");
				  	out.print("<table border='0' cellpadding='0' cellspacing='0'><tr>");
				  	out.print("<td><img src='../i/host.jpg' alt='Remote data'/></td>");
					out.print("<td class='heading' title='Remote data'>&nbsp;<font color='#336699'>" + HOSTname + "</font></td>");
					out.print("</tr></table></td></tr>");
					out.print("<tr><td></td>");
					out.print("<td>");
					
					even = false;
					String [] label = {"&nbsp;Source Area", "Owner", "Last Upload", "Size", "Access Control"};
					int [] labelLen = {325, 100, 105, 50, 126};
					boolean [] bAlignCenter = {false, true, true, true, true};
					out.print(Util.showLabel(label, labelLen, bAlignCenter, true));		// showAll and align center
				}
				if (!sizeS.equals("-"))
				{
					int iSize = Integer.parseInt(sizeS);
					totalSize[hostIdx] += iSize;
					sizeS = Util2.getSizeDisplay(iSize, 1);		// will display in MB or GB
				}
	
				// start listing the backup area info
				if (even)
					bgcolor = DARK;
				else
					bgcolor = LIGHT;
				even = !even;
				
				out.print("<tr " + bgcolor + ">");
				
				// source area name
				out.print("<td></td>");
				out.print("<td class='plaintext' valign='top' width='325'><a href='rdata.jsp?id="
						+ myUid + "&host=" + hostname + "&idx=" + i + "'>" + dispName + "</a></td>");
				
				// owner: for personal backup, must be me
				uname = (String)me.getAttribute("FirstName")[0];
				if (uname==null || uname.length()<=0)
					uname = ((user)me).getFullName();
				out.print("<td colspan='2'></td>");
				out.print("<td class='plaintext' align='center' valign='top'>");
				out.print("<a href='../ep/ep1.jsp?uid=" + myUid + "'>" + uname + "</a>");
				out.print("</td>");
				
				// created date
				s = path + "/" + hostname + "/" + dispName.replace(":", "-drive");	// C:/Repository/CR/12345/peace/C-drive/Temp/folder1
				File dirObj = new File(s);
				dt = new Date(dirObj.lastModified());
				out.print("<td colspan='2'></td>");
				out.print("<td class='listtext_small' align='center' valign='top'>" + df3.format(dt) + "</td>");
				
				// size
				out.print("<td colspan='2'></td>");
				out.print("<td class='listtext_small' align='right' valign='top'>" + sizeS + "&nbsp;</td>");
				
				// access control
				out.print("<td colspan='2'></td>");
				out.print("<td align='center' valign='top'><table cellspacing='0' cellpadding='0'><tr>");
				out.print("<td valign='bottom' colspan='2' width='126'><table width='100%' cellspacing='0' cellpadding='0'>");
				out.print("<tr><td><img src='../i/lock.jpg' />&nbsp;</td>");
				out.print("<td class='plaintext'>" + dept + "</td>");
				out.print("<td align='right'><input type='checkbox' name='folderList' value='" + shareName + "'>&nbsp;&nbsp;&nbsp;</td>");	// @ECC032509
				out.print("</tr></table></td>");
				out.print("</tr></table></td>");
				
				out.println("</tr>");	
			}	// END for each backup record

			out.print("</table></td></tr>");

			// print total space for the last host
			out.print("</table></td></tr>");
			out.print("<tr><td><table border='0' cellpadding='0' cellspacing='0'>");
			out.print("<tr><td width='25'>&nbsp;</td>");
			out.print("<td class='plaintext' valign='top' width='370'>&nbsp;&nbsp;&nbsp;(Total space used: " + totalSize[hostIdx] + " MB)</td>");
			out.print("<td><table cellpadding='0' cellspacing='0'>");
			out.println(Util3.displayShareOption(pstuser, 1, 1, hostIdx, 3, true, false, false));		// display the shared file w/o clipboard option
			out.print("</table></td></tr></table></td></tr>");
			out.print("</table></td></tr>");
			
			out.print("<tr><td><img src='../i/spacer.gif' height='15' /></td></tr>");
			out.print("<tr><td class='plaintext_big'>");
			out.print("<img src='../i/spacer.gif' width='30' height='1' />");
			out.print("<img src='../i/bullet_tri.gif' width='20' height='10'>");
			out.print("<a href='../file/common/RemoteSync.zip'>Click to upload or backup remote machines</a></td></tr>");
			
			out.print("<tr><td><img src='../i/spacer.gif' height='20' /></td></tr>");
			
			out.println("</form>");		// close FolderAction form
		}
		else
		{
			// no backup area
			// label for each hostname
			out.print("<tr><td>");
			out.print("<table width='780' border='0' cellspacing='0' cellpadding='0'>");
	  		out.print("<tr><td width='26'>&nbsp;</td>");
        	out.print("<td width='754'>");
		  	out.print("<table border='0' cellpadding='0' cellspacing='0'><tr>");
		  	out.print("<td><img src='../i/host.jpg' /></td>");
			out.print("<td class='heading'>&nbsp;Remote data</td>");
			out.print("</tr></table></td></tr></table></td></tr>");
			
			out.print("<tr><td><img src='../i/spacer.gif' height='5' /></td></tr>");
			out.print("<tr><td class='plaintext_big'>");
			out.print("<img src='../i/spacer.gif' width='26' height='1' />");
			out.print("<img src='../i/bullet_tri.gif' width='20' height='10'>");
			out.print("<a href='../file/common/RemoteAccess.jar'>Click to access or backup remote data</a></td></tr>");
			out.print("<tr><td><img src='../i/spacer.gif' height='40' /></td></tr>");
		}
		
		// print the free space left for this user
		String total, used, free;
		int iUsed;
		iTotal = ((Integer)me.getAttribute("SpaceTotal")[0]).intValue();
		if (iTotal == 0) iTotal = userinfo.DEFAULT_CR_SPACE;
		total = Util2.getSizeDisplay(iTotal, userinfo.DEFAULT_CR_SPACE);
		
		iUsed = ((Integer)me.getAttribute("SpaceUsed")[0]).intValue();
		used = Util2.getSizeDisplay(iUsed, 0);
		
		free = Util2.getSizeDisplay(iTotal-iUsed, 0);
		if (free.charAt(0) == '0')
			free = "<font color='#ee0000'>" + free + "</font>";
		
		out.print(HEAD_LINE);
		out.println("<tr><td><table border='0' cellspacing='0' cellpadding='0'>");
		out.print("<tr><td><img src='../i/spacer.gif' width='26' /></td>");
		out.print("<td class='plaintext_big'>"
				+ "Your total remote space: <b>" + total + "</b>"
				+ "&nbsp;&nbsp;&nbsp;Space used: <b>" + used + "</b>"
				+ "&nbsp;&nbsp;&nbsp;Space free: <b>" + free + "</b></td>");
		out.print("<td width='150' align='right'><img src='../i/storage.jpg' /></td>");
		out.print("<td>&nbsp;<input type='submit' value='UPGRADE' onclick='upgrade();'></td>");
		out.print("</tr></table></tr></td>");
	}	// ENDIF: isCRAPP
%>
<!-- End of List of Backup -->
<!-- ********************* -->


      <jsp:include page="../foot.jsp" flush="true"/>
      </table>
    </td>
  </tr>

</table>
	</td>
</tr>

</table>
<p>&nbsp;</p>

</body>
</html>
