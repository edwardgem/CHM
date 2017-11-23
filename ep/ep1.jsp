<%@page import="java.text.ParseException"%>
<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<%
//
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: ep1.jsp
//	Author: ECC
//	Date:	07/05/04
//	Description: Employee personal profile.
//
//	Modification:
//			@ECC071906	Support multiple companies using PRM.  For vendor, instead of
//						using the Company attribute, use the TownID attribute.  But the
//						Role will still identify the person as vendor.
//			@SWS081706  Filter memo link and project related information for OMF application.
//			@ECC110706	Privacy: limit the display of user info based on whether the person is my contact or not.
//			@ECC121206	Support a user to belong to multiple companies.
//			@ECC122106	List members by company for Admin.
//			@ECC081407	Support Blog Module.
//			@ECC080108	Multiple company support for CR.
//			@ECC100309	Support FirstPage preference for user.
//
/////////////////////////////////////////////////////////////////////
//

%>

<%@ page import = "util.*" %>
<%@ page import = "oct.omm.common.*" %>
<%@ page import = "oct.omm.client.*" %>
<%@ page import = "oct.omm.db.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>

<%
	String uid = request.getParameter("uid");
	String noSession = "../out.jsp?go=ep/ep1.jsp?uid="+uid;
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />
<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	String TOP_TITLE = "CEO";

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	String host = Util.getPropKey("pst", "PRM_HOST");
	String backPage = "../ep/ep1.jsp";

	String s;

	// to check if session is CR, OMF, or PRM
	boolean isCRAPP = Prm.isCR();
	boolean isOMFAPP = Prm.isOMF();
	boolean isPRMAPP = Prm.isPRM();
	boolean isMeetWE = Prm.isMeetWE();

	// @ECC081407 Blog Module
	boolean isBlogModule = false;
	s = Util.getPropKey("pst", "MODULE");
	if (s!=null && s.equalsIgnoreCase("Blog"))
		isBlogModule = true;

	// @ECC080108 Multiple company
	boolean isMultiCorp = Prm.isMultiCorp();

	boolean isAdmin = false;
	boolean isProgMgr = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ( (iRole & user.iROLE_ADMIN) > 0 )
		isAdmin = true;
	else if ((iRole & user.iROLE_PROGMGR) > 0)
		isProgMgr = true;
	boolean isAcctMgr = ((iRole & user.iROLE_ACCTMGR) > 0);

	boolean isGuestRole = ((iRole & user.iROLE_GUEST) > 0);

	userManager uMgr = userManager.getInstance();
	userinfoManager uiMgr = userinfoManager.getInstance();
	townManager tnMgr = townManager.getInstance();
	projectManager pjMgr = projectManager.getInstance();

	// ECC: used to be only for Admin
	int selectedTownId = 0;
	s = request.getParameter("townId");		// select town/company to display peers
	if (s != null) selectedTownId = Integer.parseInt(s);

	int [] allMyTownIds;	// a user can have more than one town belonging
	if (isAdmin)
		allMyTownIds = tnMgr.findId(pstuser, "om_acctname='%'");
	else
	{
		Object [] oA = pstuser.getAttribute("Towns");
		allMyTownIds = Util2.toIntArray(oA);		// won't return null
	}
	if (selectedTownId==0 && allMyTownIds.length==1)
		selectedTownId = allMyTownIds[0];	// I have a single town, display it as default

	s = request.getParameter("dr");
	boolean bShowDirectReportOnly = s!=null && s.equals("on");

	// set up labels for CR/OMF
	String label1, label2;
	if (!isCRAPP && !isPRMAPP) {label1="Circles & Friends"; label2="Add New Friends";}
	else {label1="Contacts & User Lists"; label2="Add New Contacts";}

	// @ECC080108 support multi corp
	if (isCRAPP && isMultiCorp && isProgMgr)
		label2 = "Add New Users";

	int managerId = 0;
	user manager = null;
	String mgrName = new String();
	int uidInt = 0;

	if (StringUtil.isNullOrEmptyString(uid))
	{
		uidInt = pstuser.getObjectId();
		uid = String.valueOf(pstuser.getObjectId());
	}
	else
	{
		uidInt = Integer.parseInt(uid);
	}

	String loginUserCompanyId = (String)pstuser.getAttribute("Company")[0];
	if (loginUserCompanyId == null) {
		loginUserCompanyId = "";
	}

	boolean isLoginUser  = (uidInt == pstuser.getObjectId());
	boolean isCircleGuest = false;		// for MeetWE

	user displayUser = null;
	userinfo uiObj = null;
	try
	{
		displayUser = (user)uMgr.get(pstuser, uidInt);
		uiObj = (userinfo)uiMgr.get(pstuser, uid);
	}
	catch (PmpException e)
	{
		response.sendRedirect("../out.jsp?e=The user has been removed from the repository (" + uidInt + ").");
		return;
	}
	
	boolean isDisplayUserGuest = ((Util.getRoles(displayUser) & user.iROLE_GUEST) > 0);


	String userFullName = displayUser.getFullName();
	String sortby = (String) request.getParameter("sortby");
	String bgcl = "bgcolor='#6699cc'";
	String srcl = "bgcolor='#66cc99'";

	String FirstName = (String)displayUser.getAttribute("FirstName")[0];
	String LastName = (String)displayUser.getAttribute("LastName")[0];
	String MiddleInitial = (String)displayUser.getAttribute("MiddleInitial")[0];
	String Title = (String)displayUser.getAttribute("Title")[0];
	String Email = (String)displayUser.getAttribute("Email")[0];
	String WorkPhone = (String)displayUser.getAttribute("WorkPhone")[0];
	String Extension = String.valueOf(displayUser.getAttribute("Extension")[0]);
	String CellPhone = (String)displayUser.getAttribute("CellPhone")[0];
	String DepartmentName = (String)displayUser.getAttribute("DepartmentName")[0];
	if (DepartmentName != null)
		DepartmentName = DepartmentName.replaceAll("@", "; ");
	else
		DepartmentName = "";
	String skypeName = (String)displayUser.getAttribute("SkypeName")[0];
	if (skypeName == null) skypeName = "";

	// @ECC080108
	String companyName = "";
	int thisUserCompanyId = 0;
	String thisUserCompanyIdS = (String)displayUser.getAttribute("Company")[0];
	if (thisUserCompanyIdS == null) thisUserCompanyIdS = displayUser.getStringAttribute("TownID");	
	if (thisUserCompanyIdS != null)
	{
		try {
			thisUserCompanyId = Integer.parseInt(thisUserCompanyIdS);
			PstAbstractObject tn = tnMgr.get(pstuser, thisUserCompanyId);
			companyName = (String)tn.getAttribute("Name")[0];
		}
		catch (NumberFormatException e) {
			companyName = thisUserCompanyIdS;	// it is not a numeric: might be a plain name
		}
		catch (Exception e) {
			// might not be an valid ID
		}
		if (companyName == null) companyName = "";		
	}

	boolean isSameCompany = loginUserCompanyId.equals(thisUserCompanyIdS);
	
	boolean isSameProjectTeam = false;
	String thisUserPjId = StringUtil.toString(pjMgr.getProjects(displayUser), ";");
	String myPjId = StringUtil.toString(pjMgr.getProjects(pstuser), ";");
	if (!StringUtil.isNullOrEmptyString(thisUserPjId) && !StringUtil.isNullOrEmptyString(myPjId)) {
		String [] sa = thisUserPjId.split(";");
		for (int i=0; i<sa.length; i++) {
			if (myPjId.contains(sa[i])) {
				isSameProjectTeam = true;
				break;
			}
		}
	}
		
	int thisUserIRole = Util.getRoles(displayUser);
	boolean thisIsVendor = false;
	if ( (thisUserIRole & user.iROLE_VENDOR) > 0 )
		thisIsVendor = true;

	// @071906ECC
	String circleS = "";
	Object [] townIdS = displayUser.getAttribute("Towns");
	if (townIdS[0] != null)
	{
		String [] sArr = new String[townIdS.length];
		for (int i=0; i<townIdS.length; i++)
		{
			int id = ((Integer)townIdS[i]).intValue();
			try {sArr[i] = (String)tnMgr.get(pstuser, id).getAttribute("Name")[0];}
			catch (Exception e)
			{
				sArr[i] = "";
				displayUser.removeAttribute("Towns", id);
				uMgr.commit(displayUser);
				System.out.println("ep1.jsp fixed user: remove town ["+id+"]");
			}
		}
		Arrays.sort(sArr);
		for (int i=0; i<sArr.length; i++)
		{
			if (sArr[i] == "") continue;
			if (circleS.length() > 0) circleS += ", ";
			circleS += sArr[i];
		}

		// check for circle guest login
		if (isOMFAPP && sArr.length==1) {
			if (((user)pstuser).isCircleGuest()) {
				isLoginUser = false;
				isCircleGuest = true;
			}
		}
	}


	Date HireDate = new Date();
	SimpleDateFormat df = new SimpleDateFormat ("MM/dd/yyyy");
	String StartDate = new String();
	if (displayUser.getAttribute("HireDate")[0] != null)
	{
		HireDate = (Date)displayUser.getAttribute("HireDate")[0];
		StartDate = df.format(HireDate);
	}
	String Supervisor1 = (String)displayUser.getAttribute("Supervisor1")[0];
	// get Managers info
	if (!isOMFAPP && Supervisor1!=null)
	{
		//manager = (PmpUser)userMgr.get(displayUser, Supervisor1);
		try
		{
			manager = (user)uMgr.get(displayUser, Integer.parseInt(Supervisor1));
			mgrName = manager.getFullName();
			managerId = manager.getObjectId();
		}
		catch (Exception e) {mgrName = "";}		// in case if manager has been deleted
	}

	String memberTitle = null;
	String memberNullString = null;
	int [] teamIdArray = new int[0];
	if (thisIsVendor)
	{
		if (townIdS != null)
			teamIdArray = uMgr.findId(pstuser, "Towns='" +townIdS+ "' && om_acctname!='" + displayUser.getObjectName() + "'");
		memberTitle = "Vendor Company Employee";
		memberNullString = "No other employee in the same company";
	}
	else
	{

		if (isAdmin || isLoginUser)		// used to be &&
		{
			//teamIdArray = uMgr.findId(pstuser, "om_acctname='%' && LastName='%'");
			if (isOMFAPP)
			{
				if (selectedTownId > 0)
					teamIdArray = uMgr.findId(pstuser, "Towns=" + selectedTownId);
				else if (selectedTownId == -1)
				{
					// display all
					if (isAdmin)
						teamIdArray = uMgr.findId(pstuser, "FirstName='%'");
					else
					{
						Object [] oA = pstuser.getAttribute("TeamMembers");
						if (oA[0] != null)
						{
							teamIdArray = new int[oA.length];
							for (int i=0; i<oA.length; i++)
								teamIdArray[i] = ((Integer)oA[i]).intValue();
						}
					}
				}
			}
			else
			{
				String exec = "";
				if (selectedTownId > 0) {
					exec = "Company='" + selectedTownId + "'";
				}
				if (bShowDirectReportOnly) {
					if (exec != "") exec += " && ";
					exec += "Supervisor1='" + uidInt + "'";
				}
				teamIdArray = uMgr.findId(pstuser, exec);
				// teamIdArray = uMgr.findId(pstuser, "om_acctname='%' && FirstName='%'");
			}
			if (isMultiCorp)
				memberTitle = "Company User";
			else if (isOMFAPP)
				memberTitle = "Friend's List";
			else
				memberTitle = "Direct Report";
			memberNullString = "None";
		}

		// !isLoginUser && !isAdmin
		else if ((isCRAPP||isPRMAPP) && isProgMgr)
		{
			// all people of my company
			teamIdArray = uMgr.findId(pstuser, "Company='" + (String)pstuser.getAttribute("Company")[0] + "'");
			memberTitle = "Company User";
		}
		else
		{
			// Direct report
			teamIdArray = uMgr.findId(pstuser, "Supervisor1='" + uidInt + "'");
			if (isCRAPP || isPRMAPP)
				memberTitle = "Direct Report";
			else
				memberTitle = "Friend's List";
			if (!isCRAPP && !isPRMAPP)
				memberNullString = "No friends yet";
			else
				memberNullString = "No assigned direct report";
		}
	}
	memberTitle += " (" + teamIdArray.length  +")";

	String emailList = new String();
	if (teamIdArray != null)
	{
		for (int i=0; i < teamIdArray.length; i++)
		{
			// direct report (or vendor colleague) member id list
			emailList = emailList +	teamIdArray[i];
				if (i < (teamIdArray.length-1))
					emailList = emailList + ",";
		}
	}
	
	
	// create personal space: do this before constructing project list
	int ppsId = 0;
	if (isAdmin || isProgMgr) {
		s = request.getParameter("pps");
		if (s!=null && s.equals("1")) {
			// create personal space for the display user
			try {
				project ppsObj = project.createPersonalProject(displayUser);
				ppsId = ppsObj.getObjectId();
			}
			catch (PmpException e) {
				System.out.println("Exception in creating Personal Space: " + e.getMessage());
				if (e.getMessage().contains("Duplicate")) {
					ppsId = -1;
				}
			}
		}
	}


	// project list
	if (isPRMAPP)
		s = "../project/proj_plan.jsp?projId=";
	else
		s = "../project/cr.jsp?projId=";

	String projListS = "", pjName;
	int [] ids = pjMgr.findId(pstuser, "TeamMembers=" + displayUser.getObjectId());
	for (int i=0; i<ids.length; i++)
	{
		PstAbstractObject o = pjMgr.get(pstuser, ids[i]);
		pjName = ((project)o).getDisplayName();
		if (projListS.length() > 0) projListS += ", ";
		// add link
		pjName = "<a href='" + s + ids[i] + "'>" + pjName + "</a>";
		projListS += pjName;
	}

	dlManager dlMgr = dlManager.getInstance();
	String dlListS = "";
	String [] dlNames = dlMgr.findName(pstuser, dl.TEAMMEMBERS + "=" + displayUser.getObjectId());
	for (int i=0; i<dlNames.length; i++) {
		if (dlNames[i] == null) break;
		if (dlListS.length() > 0) dlListS += ", ";
		dlListS += dlNames[i];
	}

	// @ECC110706: Privacy - check to see if this user is my contact, if so, display FULL info
	boolean bFull = false;
	if (isLoginUser || isAdmin || !isMultiCorp)
		bFull = true;
	else
	{
		Object [] contacts = pstuser.getAttribute("TeamMembers");
		for (int i=0; i<contacts.length; i++)
		{
			if (contacts[i] == null) break;
			if (uidInt == ((Integer)contacts[i]).intValue())
			{
				// this is my contact: display in full
				bFull = true;
				break;
			}
		}
	}

	// eLogbook or My Page
	String logbookTitle = null;
	if (!isCRAPP && !isPRMAPP)
	{
		if (isLoginUser)
			logbookTitle = "My Page";
		else
			logbookTitle = userFullName + "'s Page";
	}
	else
		logbookTitle = "eLogbook";

	String msg = request.getParameter("msg");
	if (msg == null) msg = "";

	String updateProfileURL = "updperson.jsp?uid=" + uid + "&backPage=../ep/ep1.jsp";

%>


<head>
<title>My Profile</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<jsp:include page="../init.jsp" flush="true"/>
<script src="201a.js" type="text/javascript"></script>
<script language="JavaScript" src="color_picker.js"></script>

<%
	response.setHeader("Pragma", "No-Cache");
	response.setDateHeader("Expires", 0);
	response.setHeader("Cache-Control", "no-Cache");
%>

<div id="colorpicker201" class="colorpicker201"></div>

<script language="JavaScript">
<!--
window.onload = function()
{
	var s = "<%=ppsId%>";
	if (s == '-1') {
		alert("Create Failed! Personal Space for <%=FirstName%> already exist.");
	}
	else if (s != '0') {
		alert("Personal Space for <%=FirstName%> created successfully!");
	}
}


function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

function foundBadChar(str)
{
	for (i=0;i<str.length;i++)
	{
		char = str.charAt(i);
		if (char == '\"' || char == '\\' || char == '~'
				|| char == '`' || char == '#'
				|| char == '%')
		{
			return true;	// bad
		}
	}
	return false;			// good
}

function check_motto()
{
	var e = document.mottoForm.motto;
	e.value = trim(e.value);
	if (e.value.length > 100)
	{
		fixElement(e,
			"Please make sure that your MOTTO is no longer than 100 characters (" + e.value.length + ").");
		return false;
	}
	if (foundBadChar(e.value))
	{
		fixElement(e,
			"MOTTO cannot contain these characters: \n  \" \\ ~ ` # %");
		return false;
	}
	return true;
}

function showNewColor(newColor)
{
	var e = document.getElementById("showColor");
	var txt = e.innerHTML;

	var idx1 = txt.toLowerCase().indexOf("color:");
	if (idx1 != -1)
	{
		var idx2 = txt.indexOf(";", idx1);
		if (idx2 == -1)
			idx2 = txt.indexOf(">", idx1) - 1;			// include the double quote
		txt = txt.substring(0, idx1) + "color:" + newColor + txt.substring(idx2);
	}
	else
	{
		// no previous text color spec
		idx1 = txt.indexOf("style=");
		idx1 = idx1 + 7;
		txt = txt.substring(0, idx1) + "color:" + newColor + ";" + txt.substring(idx1);
	}
	e.innerHTML = txt;
}

function bgChange(fname)
{
	var e = document.getElementById("showColor");
	var txt = e.innerHTML;

	var idx1 = txt.toLowerCase().indexOf("background:");
	if (idx1 != -1)
	{
		var idx2 = txt.indexOf(")", idx1);
		if (fname != null)
			txt = txt.substring(0, idx1) + "background:url(../i/" + fname + txt.substring(idx2);
		else
			txt = txt.substring(0, idx1) + txt.substring(idx2);		// remove the background
	}
	else if (fname != null)
	{
		// no previous background spec
		idx1 = txt.indexOf("style=");
		idx1 = idx1 + 7;
		txt = txt.substring(0, idx1) + "background:url(../i/" + fname + ");" + txt.substring(idx1);
	}
	e.innerHTML = txt;
}

function saveFirstPage()
{
	var e = firstPageForm.firstPageGp;
	alert(e[0].value);
}

function createPersonaSpace()
{
	var fullURL = parent.document.URL;
	if (fullURL.indexOf("pps=1") == -1) {
		if (fullURL.indexOf("?") == -1) {
			fullURL += "?pps=1";
		}
		else {
			fullURL += "&pps=1";
		}
	}
	location = fullURL;
}

//-->
</script>

<style type="text/css">
.plaintext {line-height: 20px;}
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
<table width='100%' border="0" cellspacing="0" cellpadding="0">
  <tr align="left" valign="top">
    <td>
      <table width="90%" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td>
            <table width="100%" border="0" cellspacing="0" cellpadding="0">
              <tr>
                <td width="26" height="30"><a name="top">&nbsp;</a></td>
                <td height="20" align="left" valign="top" class="head">
					Welcome, <%=pstuser.getStringAttribute("FirstName")%>
				 </td>
				 
				 
<!-- Update Links -->
<%
	out.print("<td align='left' width='300' valign='top'>");
	out.print("<img src='../i/bullet_tri.gif' width='20' height='10'/>");
	
	if (isLoginUser || isAdmin || isProgMgr)
	{
		if (!isOMFAPP && !isMultiCorp){ // @SWS081706
			out.print("<a class='listlinkbold' href='"
				+ updateProfileURL + "'>Update Employee Profile</a>");
		}
		else{
			out.print("<a class='listlinkbold' href='"
					+ updateProfileURL + "'>Update Employee Profile</a>");
		}
		out.print("<br/>");
		
		if (!isLoginUser || isProgMgr) {
			// enable ProgMgr and Admin to create Personal Space for users
			out.print("<img src='../i/bullet_tri.gif' width='20' height='10'/>");
			out.print("<a class='listlinkbold' href='javascript:createPersonaSpace();'>"
					+ "Create " + FirstName + "'s Personal Space</a>");
		}
	}
	else if (!isLoginUser) {
		out.print("<a class='listlinkbold' href='my_page.jsp?uid=" + uid
				+ "'>View " + FirstName + "'s Page</a>");
	}
	out.print("</td>");
%>
				 
				 
              </tr>
            </table>
          </td>
        </tr>
        <tr>
          <td width="100%">
<!-- Navigation Menu -->
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="MyAccount" />
				<jsp:param name="subCat" value="UserAccount" />
				<jsp:param name="role" value="<%=iRole%>" />
			</jsp:include>
<!-- End of Navigation Menu -->
			</td>
        </tr>
        <tr>
          <td>&nbsp;</td>
        </tr>

<%if (thisIsVendor){%>
	<tr><td>
		<table><tr>
			<td width="24">&nbsp;</td>
			<td class="heading"><font color="#336699">Vendor</font></td>
		</tr></table>
	</td></tr>
<%}%>

<%
	// update completed message
	if (!StringUtil.isNullOrEmptyString(msg)) { %>
			<tr>
			  <td class='ptextS2'><img src='../i/spacer.gif' width='250' height='1'/>
			  	<font color='#00bb00'><%=msg%></font>
			  </td>
			</tr>
			<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>
<%	} %>

<!-- Personal Info -->
        <tr>
          <td width='100%'>
	<table width="100%" border="0" cellspacing="2" cellpadding="0">
	  <tr>
		<td width="26" align="left" valign="top">&nbsp;</td>
		<td align="left" valign="top" width='100'>
<%
	String picURL = Util2.getPicURL(displayUser);
	out.print("<img src=" + picURL + " border='0' width='94' >");
	// displayUser.getObjectId() + "&user=pstuser&img=../i/thumbnail.gif' border='0' width='94'>");

%>
		</td>
		<td align="left" valign="top">
		  <table width="100%" border="0" cellspacing="0" cellpadding="0">
			<tr>
			
			  <td width="5">&nbsp;</td>
			  <td valign="middle" width="150" class="plaintext"><b>Name</b></td>
			  <td width="10" class="plaintext"></td>
			  <td>
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
			  <td class="plaintext"><b>:
				<%=userFullName%>
				</b>
				&nbsp;(<%=displayUser.getObjectName()%>)
<%
	if (displayUser.isInactive()) {
		out.print("<span class='error'>** INACTIVE **</span>");
	}
%>
			  </td>
<!-- ECC moved section of update link to above -->
</tr>
</table>
			</td>
			</tr>
<%
	if (!isOMFAPP || isCRAPP || isPRMAPP)
	{
%>
			<tr>
			  <td width="5">&nbsp;</td>
			  <td valign="middle" class="plaintext"><b>Primary Company</b></td>
			  <td width="10"></td>
			  <td class="plaintext"><b>:</b>
<%			if (thisUserCompanyId > 0)
				out.print("<a href='../admin/comp_update.jsp?id=" + thisUserCompanyIdS + "'>"
					+ companyName + "</a>");
			else
				out.print(companyName);
%>
				  <%if (isDisplayUserGuest) out.print(" (Guest)");%>
			  </td>
			</tr>
			
			<tr>
			  <td width="5">&nbsp;</td>
			  <td valign="middle" class="plaintext"><b>Other Companies</b></td>
			  <td width="10"></td>
			  <td class="plaintext"><b>:</b>
<%
			Object [] townIdArr = displayUser.getAttribute("Towns");
			boolean bNeedSemiColon = false;
			for (int i=0; i<townIdArr.length; i++) {
				Integer tidO = (Integer) townIdArr[i];
				if (tidO==null || tidO.intValue()<=0) break;
				int tid = tidO.intValue();
				if (tid == thisUserCompanyId) continue;		// don't display again
				s = tnMgr.get(pstuser, tid).getStringAttribute("Name");
				if (bNeedSemiColon) out.print(";&nbsp;");
				else bNeedSemiColon = true;
				out.print("<a href='../admin/comp_update.jsp?id=" + tid
						  + "'>" + s + "</a>");
			}
%>
			  </td>
			</tr>


			<tr>
			  <td width="5">&nbsp;</td>
			  <td valign="middle" class="plaintext"><b>Department
				</b></td>
			  <td width="10"></font></td>
			  <td class="plaintext"><b>:</b>
			  <%=DepartmentName%></td>
			</tr>

<%	if (isAdmin || isLoginUser || isAcctMgr) {
		String thisURoles = "";
		int thisUiRole = Util.getRoles(displayUser);
		for (int i=0; i<user.iROLE_ARRAY.length; i++)
		{
			if ((thisUiRole&user.iROLE_ARRAY[i]) != 0)
			{
				if (thisURoles.length() > 0) thisURoles += "; ";
				thisURoles += user.ROLE_ARRAY[i];
			}
		}
		if (thisURoles == "") thisURoles = "User";
%>
			<tr>
			  <td width="5">&nbsp;</td>
			  <td valign="middle" class="plaintext"><b>Roles
				</b></td>
			  <td width="10"></font></td>
			  <td class="plaintext"><b>:</b>
			  <%=thisURoles%></td>
			</tr>
<%	} %>

			<tr>
			  <td width="5">&nbsp;</td>
			  <td valign="middle" class="plaintext"><b>Title
				</font></b></td>
			  <td width="10"></td>
			  <td class="plaintext"><b>:</b>
			  <%=(Title == null || Title.length() == 0 || Title.equals(" "))? "" : Title %>
			  </td>
			</tr>
<%	}


	if ( !isGuestRole && (bFull || isSameCompany || isSameProjectTeam || isLoginUser) )
	{%>
			<tr>
			  <td width="5">&nbsp;</td>
			  <td valign="middle" class="plaintext"><b>Email
				</b></td>
			  <td width="10"></td>
			  <td class="plaintext"><b>:</b>
			  <a href="mailto:<%=Email%>"><%=(Email == null || Email.length() == 0 || Email.equals(" "))? "" : Email %></a></td>
			</tr>
			<tr>
			  <td width="5">&nbsp;</td>
			  <td valign="middle" class="plaintext"><b>Work Phone
				</b></td>
			  <td width="10"></td>
			  <td class="plaintext"><b>:</b>
			  <%=((WorkPhone == null) || (WorkPhone.length() == 0) || (WorkPhone.equals("null")) || (WorkPhone.equals("")))? "" : WorkPhone %>
			  <%=(Extension == null || Extension.length() == 0 || Extension.equals("null") || Extension.equals("0"))? "" : "(" + Extension + ")" %></td>
			</tr>
			 <tr>
			  <td width="5">&nbsp;</td>
			  <td valign="middle" class="plaintext"><b>Cell Phone
				</b></td>
			  <td width="10"></td>
			  <td class="plaintext"><b>:</b>
			  <%=((CellPhone == null) || (CellPhone.length() == 0) || (CellPhone.equals("null")) || (CellPhone.equals("")) )? "" : CellPhone %>
			  </td>
			</tr>

			 <tr>
			  <td width="5">&nbsp;</td>
			  <td valign="middle" class="plaintext"><b>Skype Name</b></td>
			  <td width="10"></td>
			  <td class="plaintext"><b>:</b>
<%	if (skypeName.length() > 0)
	{
		out.print("<a class='listlink' href='skype:" + skypeName + "'> " + skypeName + "</a>");
	}
%>
				</td>
			</tr>

<%
		// GoogleID
		if (isLoginUser || isAdmin)
		{
			String googleIdS = (String)displayUser.getAttribute("GoogleID")[0];
			boolean bNoGooglePasswd = false;
			if (googleIdS!=null && googleIdS.length()>0)
			{
				String [] sa = googleIdS.split(":");
				googleIdS = sa[0];						// only shows the Google userId, no passwd
				if (sa.length < 2) bNoGooglePasswd = true;
			}
			out.print("<tr><td width='5'>&nbsp;</td>");
			out.print("<td valign='middle' class='plaintext'><b>Google ID</b></td>");
			out.print("<td width='10'></td>");
			out.print("<td class='plaintext'><b>:</b>");
			if (googleIdS!=null && googleIdS.length()>0)
			{
				out.print("&nbsp;" + googleIdS);
				if (bNoGooglePasswd) out.print("&nbsp;&nbsp;<a href='" + updateProfileURL + "#googleId'>Enter GoogleID password</a>");
			}
			out.print("</td></tr>");
		}

	}	// if (bFull)
%>

			 <tr>
			  <td width="5">&nbsp;</td>
			  <td class="plaintext"><b>Start Date</b></td>
			  <td width="10"></td>
			  <td class="plaintext"><b>:</b>
				<%=((StartDate == null) || (StartDate.length() == 0) || (StartDate.equals(" ")) || (StartDate.equals("null")))? "" : StartDate %></td>
			</tr>

<% 	//if ((Title == null) || (!Title.equals(TOP_TITLE)))
	//{
		if (!isOMFAPP && !(isGuestRole && !isLoginUser))
		{
			out.print("<tr><td width='5'>&nbsp;</td>");
			out.print("<td valign='top' class='plaintext'><b>Projects</b></td>");
			out.print("<td width='10'></font></td>");
			out.print("<td><table border='0' cellspacing='0' cellpadding='0'><tr>");
			out.print("<td class='plaintext' valign='top'><b>:&nbsp;</b></td>");
			out.print("<td class='plaintext'>" + projListS + "</td>");
			out.print("</tr></table></td></tr>");
		}
			int timeZone = 0;
			Integer io = (Integer)uiObj.getAttribute("TimeZone")[0];
			if (io != null)
				timeZone = io.intValue();
			int tIdx = timeZone - userinfo.SERVER_TIME_ZONE;
			String tzS = userinfo.getZoneString(tIdx);
%>
			 <tr>
			  <td width="5">&nbsp;</td>
			  <td valign='top' class="plaintext"><b>Time Zone
				</b></td>
			  <td width="10"></td>
			  <td><table border='0' cellspacing='0' cellpadding='0'><tr>
			  	<td class="plaintext" valign='top'><b>:&nbsp;</b></td>
			  	<td class="plaintext"><%=tzS%>
			  	</td>
			  	</tr></table>
			  </td>
			</tr>

<!-- Locale -->
<%
			String locale = uiObj.getLocale();
			if (StringUtil.isNullOrEmptyString(locale))
				locale = userinfo.DEFAULT_LOCALE + " (default)";
%>		
			 <tr>
			  <td width="5">&nbsp;</td>
			  <td valign='top' class="plaintext"><b>Language/Locale
				</b></td>
			  <td width="10"></td>
			  <td><table border='0' cellspacing='0' cellpadding='0'><tr>
			  	<td class="plaintext" valign='top'><b>:&nbsp;</b></td>
			  	<td class="plaintext"><%=locale%>
			  	</td>
			  	</tr></table>
			  </td>
			</tr>
			
			
<%

		// optional application module
	if ((!isGuestRole || isLoginUser) && !isMeetWE) {
		String appModule = uiObj.getStringAttribute("Application");
		if (appModule == null) appModule = "";
		else appModule = appModule.replaceAll("::", "; ");		// better display

%>
			 <tr>
			  <td width="5">&nbsp;</td>
			  <td valign='top' class="plaintext"><b>Optional Applications
				</b></td>
			  <td width="10"></td>
			  <td><table border='0' cellspacing='0' cellpadding='0'><tr>
			  	<td class="plaintext" valign='top'><b>:&nbsp;</b></td>
			  	<td class="plaintext"><%=appModule%>
			  	</td>
			  	</tr></table>
			  </td>
			</tr>

<%
	

		try
		{
			String firstPage = (String)displayUser.getAttribute("FirstPage")[0];
			if (firstPage == null) {
				s = Util.getPropKey("pst", "DEFAULT_FIRST_PAGE");
				if (!StringUtil.isNullOrEmptyString(s)) firstPage = s;
				else firstPage = "";
			}
%>
			 <tr>
			  <td width="5" height='30'>&nbsp;</td>
			  <td class="plaintext"><b>Default Home Page</b></td>
			  <td width="10"></td>
			  <td><table border='0' cellspacing='0' cellpadding='0'><tr>
			  	<td class="plaintext"><b>:&nbsp;</b></td>
			  	<td class="plaintext" style='padding-top:10px;'>
			  	
			  	<form name='firstPageForm' method='post' action='post_ep1.jsp'>
			  	<input type='hidden' name='op' value='setHomePage'>
		  		<input type='radio' name='firstPageGp' value='dashboard' 
		  			<%if (StringUtil.isNullOrEmptyString(firstPage) || firstPage.equalsIgnoreCase("dashboard")) out.print("checked");%>>Dashboard
		  		&nbsp;&nbsp;&nbsp;
		  		<input type='radio' name='firstPageGp' value='classicHome'
		  			<%if (firstPage!=null && firstPage.equalsIgnoreCase("classichome")) out.print("checked");%>>Classic Home
		  		&nbsp;&nbsp;&nbsp;
		  		<input type='button' class='button_medium' value='Save' onclick='submit();'>
		  		</form>

			  	</td>
			  	</tr></table>
			  </td>
			</tr>
<%			}
		catch (PmpException e) {}
	}	// !isMeetWE: options: appModule; firstPage

		// @ECC071906
		if (isMeetWE)
		{%>
			<tr>
			  <td width="5">&nbsp;</td>
			  <td valign="top" class="plaintext"><b>My Circles
				</b></td>
			  <td width="10"></td>
			  <td class="plaintext"><b>:</b>
			  <%=circleS%></td>
			</tr>

			<tr><td colspan='4'><img src='../i/spacer.gif' height='5' /></td>

<%	if (isLoginUser || isAdmin)
	{
		String motto = (String)displayUser.getAttribute("Motto")[0];
		if (motto == null) motto = "No Motto";
%>
			<form name='mottoForm' method='post' onSubmit="return check_motto();" action='post_ep1.jsp'>
			<tr>
			  <td width="5">&nbsp;</td>
			  <td valign="middle" class="plaintext"><b>My Motto
				</b></td>
			  <td width="10"></td>
			  <td class="plaintext"><b>:</b>
			  	<input name="motto" type='text' class='formtext' size='60' value="<%=motto%>" />
			  	<input type="submit" value='Save' class='button_medium'>
			  </td>
			</tr>
			</form>

<%	}	// END if uid==myUid

		}%>
			<!--  tr>
			  <td width="5">&nbsp;</td>
			  <td valign='top' class="plaintext"><b>User List
				</b></td>
			  <td width="10"></font></td>
			  <td><table border='0' cellspacing='0' cellpadding='0'><tr>
			  	<td class="plaintext" valign='top'><b>:&nbsp;</b></td>
			  	<td class="plaintext"><%=dlListS%></td>
			  	</tr></table>
			  </td>
			</tr-->
<%

		if (!isOMFAPP) // @SWS081706
		{
%>
			<tr>
			  <td width="5">&nbsp;</td>
			  <td valign="middle" class="plaintext"><b>Managed by</b></td>
			  <td width="10"></td>
			  <td class="plaintext"><b>:</b>
			  <a href="ep1.jsp?uid=<%=managerId %>"><%=(mgrName == null || mgrName.length() == 0 || mgrName.equals(""))? "" : mgrName %></a></font></td>
			</tr>
<%		}%>
			<tr><td colspan="3">&nbsp;</td></tr>
		  </table>
		</td>
	  </tr>
	</table>
          </td>
        </tr>
<!-- End Personal Info -->

        <tr>
          <td>&nbsp;</td>
        </tr>


<%//if (!isOMFAPP || isAdmin)
//{ %>
        <tr>
          <td>

            <table width="100%" border="0" cellspacing="0" cellpadding="0">

			   <tr>
                <td width="26"><img src='../i/spacer.gif' width='26' height='1' /></td>
                <td class="12ptype" valign="bottom" align="left">

<!-- User Preference -->
<%
	if (!isCRAPP && isLoginUser && !isPRMAPP)
	{
		// get current preference
%>

		<form name='postPreference' method='post' action='post_ep1.jsp'>
		<table width="100%" border='0' cellpadding="0" cellspacing="0">
		<tr><td></td><td colspan='3' bgcolor="#bb5555" width="100%"><img src="../i/spacer.gif" width="1" height="1" border="0"></td></tr>
		<tr><td colspan='4'><img src='../i/spacer.gif' height='5' /></td></tr>

		<tr>
			<td colspan='4' class="heading" valign="top">User Preference</td>
		</tr>

		<tr><td colspan='4'><img src='../i/spacer.gif' height='10' /></td></tr>


<%
		s = Util2.getUserPreference(pstuser, "BlogCheck");	// CheckEvent
		if (s==null || s.length()<=0) s = "Yes";	// default
		String yesLabel=s;
		if (yesLabel.equalsIgnoreCase("no")) yesLabel="Daily";	// Daily, Mon, ...
%>
		<tr>
			<td><img src='../i/spacer.gif' width='3' height='1' /></td>
			<td width='155' class='plaintext'><b>Receive events daily</b></td>
			<td><b>:</b></td>
			<td>
				&nbsp;<input type='radio' name='checkEvent' value='<%=yesLabel%>' <%if (!s.equalsIgnoreCase("no")) out.print("checked");%>><%=yesLabel%>
				&nbsp;&nbsp;<input type='radio' name='checkEvent' value='No' <%if (s.equalsIgnoreCase("no")) out.print("checked");%>>No
			</td>
		</tr>

		<tr><td colspan='4'><img src='../i/spacer.gif' height='10' /></td></tr>

<%

		s = Util2.getUserPreference(pstuser, "RoboMail");
		if (s != null)
		{
%>
		<tr>
			<td><img src='../i/spacer.gif' width='3' height='1' /></td>
			<td width='155' class='plaintext'><b>RoboMail</b></td>
			<td><b>:</b></td>
			<td>
				&nbsp;&nbsp;&nbsp;<input type='text' class='formtext' size='20' name='roboMail' value='<%=s%>' />
				&nbsp;<span class='plaintext_grey'>(Email address for XML export option)</span>
			</td>
		</tr>

		<tr><td colspan='4'><img src='../i/spacer.gif' height='10' /></td></tr>

<%
		}	// END if RoboMail is specified in user preference

		String bgS = "";
		String txS = "";
		s = Util2.getUserPreference(pstuser, "NoteBackground");
		if (!StringUtil.isNullOrEmptyString(s) && !s.equals("?"))
		{
			String [] sa = s.split("\\?");
			bgS = sa[0];
			if (sa.length > 1)
				txS = sa[1];
		}
		else
			s = "";	// default


%>
		<tr>
			<td><img src='../i/spacer.gif' width='3' height='1' /></td>
			<td width='155' class='plaintext'><b>Postnote background</b></td>
			<td><b>:</b></td>
			<td></td>
		</tr>
		<tr>
			<td colspan='3'></td>
			<td>
				<table border='0'>
				<tr>
				<td width='150'><table border='0' cellspacing='0' cellpadding='0'>
					<tr><td>
						<input type='radio' onclick='bgChange();' name='noteBkgd' value='' <%if (bgS=="") out.print("checked");%>></td>
						<td class='plaintext'>None (default)</td>
					</tr>

					<tr><td valign='top'>
						<input type='radio' onclick='bgChange("yellowpad.gif");' name='noteBkgd' value='../i/yellowpad.gif' <%if (bgS.contains("yellowpad.gif")) out.print("checked");%>></td>
						<td width='120' height='80' style='background:url(../i/yellowpad.gif) repeat; border: 1px solid #aaaaaa;'>&nbsp;</td>
					</tr>

					<tr><td valign='top'>
					<input type='radio' onclick='bgChange("bluepad.gif");' name='noteBkgd' value='../i/bluepad.gif' <%if (bgS.contains("bluepad.gif")) out.print("checked");%>></td>
					<td width='120' height='80' style='background:url(../i/bluepad.gif) repeat; border: 1px solid #aaaaaa;'>&nbsp;</td>
					</tr>

					<tr><td valign='top'>
					<input type='radio' onclick='bgChange("pinkpad.gif");' name='noteBkgd' value='../i/pinkpad.gif' <%if (bgS.contains("pinkpad.gif")) out.print("checked");%>></td>
					<td width='120' height='80' style='background:url(../i/pinkpad.gif) repeat; border: 1px solid #aaaaaa;'>&nbsp;</td>
					</tr>

					<tr><td valign='top'>
					<input type='radio' onclick='bgChange("bg-01.gif");' name='noteBkgd' value='../i/bg-01.gif' <%if (bgS.contains("bg-01.gif")) out.print("checked");%>></td>
					<td width='120' height='80' style='background:url(../i/bg-01.gif) repeat; border: 1px solid #aaaaaa;'>&nbsp;</td>
					</tr>
				</table></td>

				<td width='150'><table border='0' cellspacing='0' cellpadding='0'>
					<tr><td></td>
						<td>&nbsp;</td>
					</tr>

					<tr><td valign='top'>
						<input type='radio' onclick='bgChange("bg-02.jpg");' name='noteBkgd' value='../i/bg-02.jpg' <%if (bgS.contains("bg-02.jpg")) out.print("checked");%>></td>
						<td width='120' height='80' style='background:url(../i/bg-02.jpg) repeat; border: 1px solid #aaaaaa;'>&nbsp;</td>
					</tr>

					<tr><td valign='top'>
					<input type='radio' onclick='bgChange("bg-03.gif");' name='noteBkgd' value='bg-03.gif' <%if (bgS.contains("bg-03.gif")) out.print("checked");%>></td>
					<td width='120' height='80' style='background:url(../i/bg-03.gif) repeat; border: 1px solid #aaaaaa;'>&nbsp;</td>
					</tr>

					<tr><td valign='top'>
					<input type='radio' onclick='bgChange("bg-04.gif");' name='noteBkgd' value='../i/bg-04.gif' <%if (bgS.contains("bg-04.gif")) out.print("checked");%>></td>
					<td width='120' height='80' style='background:url(../i/bg-04.gif) repeat; border: 1px solid #aaaaaa;'>&nbsp;</td>
					</tr>

					<tr><td valign='top'>
					<input type='radio' onclick='bgChange("bg-05.gif");' name='noteBkgd' value='../i/bg-05.gif' <%if (bgS.contains("bg-05.gif")) out.print("checked");%>></td>
					<td width='120' height='80' style='background:url(../i/bg-05.gif) repeat; border: 1px solid #aaaaaa;'>&nbsp;</td>
					</tr>
				</table></td>

				<td><table border='0' cellspacing='0' cellpadding='0'>
					<tr><td class='plaintext' width='300'><b>Text color:</b> <img src='../i/sel.gif' border='0' onclick='chooseColor(2);' />
						<div id='selColor' class='plaintext' align='left' style='display:none'></div>
						<input type='hidden' name='myColor' id='myColor' value='<%=txS%>'>
					</td></tr>

<%
					out.println("<tr><td width='300' height='250' class='plaintext' valign='top'><div id='showColor'><blockquote class='bq_note'");
					out.print(" style='");		// i need this for showNewColor()
					if (bgS.length()>0 || txS.length()>0)
					{
						if (txS.length() > 0)
							out.print("color:" + txS + ";");
						if (bgS.length() > 0)
							out.print("background:url(" + bgS + ") repeat;");
					}
					out.print("'");
					out.print("><br>Hello, this is how my note look like!<br><br></blockquote></div>");
					out.print("</td></tr>");
%>

				</table></td>

				</tr>
				</table>
			</td>
		</tr>
		<tr>
			<td></td>
			<td colspan='3'>
				<img src='../i/spacer.gif' width='200' height='25' />
		  		<input type="submit" value='Save Preference' class='button_medium'>
			</td>
		</tr>
		</table>
		</form>
<%
	}
%>

<!-- Direct Report -->

<%	if ((isCRAPP || isPRMAPP)  && !isGuestRole && isLoginUser)
	{
%>

<table width="100%" border='0' cellpadding="0" cellspacing="0">
	<tr>
		<td class="heading" valign="top" width='300'><a name='pplList'></a>
<%	if (emailList.length() > 0)
	{%>
		<a href="../blog/addalert.jsp?list=<%=emailList%>&backPage=<%=backPage%>">
			<img src="../i/but/eml.gif" border=0></a>&nbsp;
<%	}%>
		<%=memberTitle%></td>

<%

	// admin's default My Profile page
	if (isLoginUser)
	{
		// @ECC122106
		out.print("<form method='post' action='#pplList'>");
		out.print("<input type='hidden' name='uid' value='" + uid + "'>");

		// option to show direct report
		out.print("<td class='plaintext'>");
		out.print("<input type='checkbox' name='dr' ");
		if (bShowDirectReportOnly)
			out.print(" checked");
		out.print(" onClick='submit();'>Show my direct reports only");
		out.print("</td>");

		if (isMultiCorp)
		{
			// choose a company
			out.print("<td valign='top' width='140' align='right'>");
				
			out.print("<select class='formtext' name='townId' onChange='submit();'>");
			if (isOMFAPP)
				out.print("<option value='0'>-- Choose Circle --</option>");
			else
				out.print("<option value='0'>-- Choose Company --</option>");
			if (isOMFAPP) {
				// for MeetWE: show all my friends
				out.print("<option value='-1'");
				if (selectedTownId == -1) out.print(" selected");
				out.print(">" + (isAdmin?"All":"My friends") + "</option>");
			}
			if (allMyTownIds!=null && allMyTownIds.length>0)
			{
				PstAbstractObject [] oArr = tnMgr.get(pstuser, allMyTownIds);
				Util.sortString(oArr, "Name", true);
				for (int i=0; i<oArr.length; i++)
				{
					int id = oArr[i].getObjectId();
					out.print("<option value='" + id + "'");
					if (id == selectedTownId)
						out.print(" selected");
					s = (String)oArr[i].getAttribute("Name")[0];
					out.print(">" + s + "</option>");
				}
			}
			out.print("</select>");
			out.print("</td>");
		}
		else {
			out.print("<td valign='top' width='140' align='right'></td>");
		}
		out.print("</form>");
	}
	else
	{
		out.print("<td valign='top' width='140' align='right'></td>");
	}
%>
				</tr>
				<tr>
					<td bgcolor="#EBECED" colspan="2" height="3"><img src="../i/spacer.gif" width="1" height="3" border="0"></td>
				</tr>
			</table>
                </td>
                <td width="20">&nbsp;</td>
              </tr>
			  <tr>
                <td width="26">&nbsp;</td>
                <td>
                  <table width="100%" border="0" cellspacing="0" cellpadding="0">
                    <tr>
                      <td colspan="14" height="2" bgcolor="#336699"><img src="../i/mid/u2x2.gif" height="2"></td>
                    </tr>
                    <tr>
<%	if (sortby==null || sortby.equals("fn"))
	{
		out.print("<td width='6' " + srcl + ">&nbsp;</td>");
		out.print("<td width='150' class='td_header' " + srcl + "><strong>First Name</strong></td>");
		out.print("<td width='2' bgcolor='#FFFFFF'>&nbsp;</td>");
		out.print("<td width='6' " + bgcl + ">&nbsp;</td>");
		out.print("<td class='td_header' " + bgcl + "><a href='ep1.jsp?uid=" +uid+ "&sortby=ln'><font color='ffffff'><strong>Last Name</strong></font></a></td>");
	}
	else if (sortby.equals("ln"))
	{
		out.print("<td width='6' " + bgcl + ">&nbsp;</td>");
		out.print("<td class='td_header' " + bgcl + "><a href='ep1.jsp?uid=" +uid+ "&sortby=fn'><font color='ffffff'><strong>First Name</strong></font></a></td>");
		out.print("<td width='2' bgcolor='#FFFFFF'>&nbsp;</td>");
		out.print("<td width='6' " + srcl + ">&nbsp;</td>");
		out.print("<td width='150' class='td_header' " + srcl + "><strong>Last Name</strong></td>");
	}
%>

				<td width="2" bgcolor="#FFFFFF">&nbsp;</td>
				<td width="4" bgcolor="#6699cc">&nbsp;</td>
				<td width="80" bgcolor="#6699cc" class="td_header"><strong>Username</strong></td>
				<td width="2" bgcolor="#FFFFFF">&nbsp;</td>
				<td width="4" bgcolor="#6699cc">&nbsp;</td>
				<td width="180" bgcolor="#6699cc" class="td_header"><strong>Email</strong></td>
				<td width="2" bgcolor="#FFFFFF">&nbsp;</td>
				<td width="4" bgcolor="#6699cc">&nbsp;</td>
				<td width="130" bgcolor="#6699cc" class="td_header"><strong>
					<%if (!isOMFAPP){%>Phone<%}else{%>Created Date<%}%></strong></td>
                    </tr>
<!-- Managed Personnel -->
<%
	boolean even = false;
	String bgcolor = new String();
	Object empArray[] = new Object[0];
	if (teamIdArray != null)
		empArray = uMgr.get(displayUser, teamIdArray);

	if (sortby != null && sortby.equals("ln"))
		Util.sortString(empArray, "LastName", true);
	else if (sortby == null || sortby.equals("fn"))
		Util.sortString(empArray, "FirstName", true);

	String electField = null;
	String extNum = null;
	if (empArray.length > 0)
	{
			for (int i=0; i < empArray.length; i++)
			{
				user emp = (user)empArray[i];
				String firstName = (String)emp.getAttribute("FirstName")[0];
				String lastName = (String)emp.getAttribute("LastName")[0];
				String email = (String)emp.getAttribute("Email")[0];
				if (!isOMFAPP)
				{
					electField = (String)emp.getAttribute("WorkPhone")[0];
					if (electField == null) electField = "";
					//extNum = (String)emp.getAttribute("Extension")[0];
					//if (extNum!=null) electField += extNum;
				}
				else
				{
					Date dt = (Date)emp.getAttribute("HireDate")[0];
					if (dt == null) electField = "";
					else electField = df.format(dt);
				}
				int userId = teamIdArray[i];

				if (even)
					bgcolor="bgcolor='#EEEEEE'";
				else
					bgcolor="bgcolor='#ffffff'";
                even = !even;
%>
                    <tr <%=bgcolor%>>
                      <td width="4">&nbsp;</td>
                      <td width="150" class="plaintext" valign='top'>
					  <a href="ep1.jsp?uid=<%=emp.getObjectId() %>"><strong><%=(firstName == null || firstName.length() == 0 || firstName.equals(" "))? "" : firstName %></strong></a></td>
                      <td width="2">&nbsp;</td>
					  <td width="4">&nbsp;</td>
                      <td width="150" class="plaintext" valign='top'>
					  <a href="ep1.jsp?uid=<%=emp.getObjectId() %>"><strong><%=(lastName == null || lastName.length() == 0 || lastName.equals(" "))? "" : lastName %></strong></a></td>
                      <td width="2">&nbsp;</td>
                      <td width="4">&nbsp;</td>
                      <td width="80" class="plaintext" valign='top'><%=emp.getObjectName()%></td>
                      <td width="2">&nbsp;</td>
                      <td width="4">&nbsp;</td>
                      <td width="180" class="plaintext" valign='top'>
					  <a href="mailto:<%=email%>"><%=(email == null || email.length() == 0 || email.equals(" "))? "" : email %></a></td>
                      <td width="2">&nbsp;</td>
                      <td width="4">&nbsp;</td>
                      <td width="130" class="plaintext" valign='top'>
					  <%=electField%>
					  </td>
                    </tr>
<%
		}
	}
	else
	{
%>
					<tr>
                      <td bgcolor="#F3F6F9">&nbsp;</td>
					  <td bgcolor="#F3F6F9" colspan="14" class="plaintext"><%=memberNullString%></td>
                    </tr>
<%
	}
%>

                  </table>
                </td>
                <td width="20">&nbsp;</td>
              </tr>
              <tr>
                <td width="26">&nbsp;</td>
                <td>&nbsp;</td>
                <td width="20">&nbsp;</td>
              </tr>


				<tr>
                	<td width="26">&nbsp;</td>
                	<td valign="bottom" align="left">&nbsp;</td>
                	<td width="20">&nbsp;</td>
              	</tr>


            </table>
<%//} 	// endif !isOMFAPP%>
         </td>
        </tr>

        </table>
<%	} %>
    </td>
  </tr>

</table>

</td>
</tr>
<tr>
	<td valign="bottom">
		<jsp:include page="../foot.jsp" flush="true"/>
	</td>
</tr>
</table>

</body>
</html>
