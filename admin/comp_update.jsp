<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<%@page import="util.Util2"%>
<%@page import="util.Util"%>
<%
////////////////////////////////////////////////////
//	Copyright (c) 2004-2015, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	comp_update.jsp
//	Author:	ECC
//	Date:	08/14/08
//	Description:
//		Update a company (town organization) for CR and MultiCorp.
//	Modification:
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");
	String tidS = request.getParameter("id");
	String noSession = "../out.jsp?go=admin/comp_update.jsp?id=" + tidS;
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%
	// only CR and multiCorp would come into this page

	PstUserAbstractObject me = pstuser;

	// check admin or acctMgr
	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ( (iRole & user.iROLE_ADMIN) > 0 )
		isAdmin = true;

	if (me==null || (me instanceof PstGuest) || tidS==null)
	{
		response.sendRedirect("../out.jsp?msg=Access Denied");
		return;
	}
	
	String s;
	PstAbstractObject o;
	String uname;
	int [] ids;
	int myUid = pstuser.getObjectId();
	
	townManager tnMgr = townManager.getInstance();
	userManager uMgr = userManager.getInstance();
	
	PstAbstractObject thisCompObj = null;
	int tid = Integer.parseInt(tidS);
	thisCompObj = tnMgr.get(me, tid);
	
	// get company attributes
	String dispName = (String)thisCompObj.getAttribute("Name")[0];
	String deptName = (String)thisCompObj.getAttribute("DepartmentName")[0];
	if (deptName == null)
		deptName = "";
	
	int progMgrId = 0;
	if ((s = (String)thisCompObj.getAttribute("Chief")[0]) != null)
		progMgrId = Integer.parseInt(s);
	boolean isChief = myUid==progMgrId;
	
	String currentProgMgr = "";
	if (progMgrId > 0)
		currentProgMgr = PstManager.getNameById(pstuser, progMgrId);
	if (currentProgMgr.equals("data not found"))	// ECC: getNameById() should throw exception
		currentProgMgr = "";
	
	int acctMgrId = 0;
	if ((s = (String)thisCompObj.getAttribute("AccountManager")[0]) != null)
		acctMgrId = Integer.parseInt(s);
	boolean isAcctMgr = (myUid==acctMgrId);
	
	boolean bUpdateOK = (isAdmin || isAcctMgr || isChief);
	String disabledStr = "";
	if (!bUpdateOK) disabledStr = " disabled ";
	
	// check access authority
	String allMyTowns = Util2.getAttributeString(pstuser, "Towns", ";");
	if (!bUpdateOK && !allMyTowns.contains(tidS)) {
		response.sendRedirect("../out.jsp?msg=Access Denied");
		return;
	}
	
	String msg = request.getParameter("msg");
	if (msg == null) msg = "";

	String fName = "";
	String lName = "";
	String eMail = "";
	
	// set the logo file
	Object oriLogo = session.getAttribute("comPicFile");
	session.setAttribute("comPicFile", thisCompObj.getAttribute("PictureFile")[0]);
	
	// company service agreement limit
	town tnObj = (town)thisCompObj;
	int maxProj = tnObj.getLimit(town.MAX_PROJECT);
	if (maxProj <= 0) maxProj = town.DEFAULT_MAX_PROJ;
	
	int maxUser = tnObj.getLimit(town.MAX_USER);
	if (maxUser <= 0) maxUser = town.DEFAULT_MAX_USER;

	int maxSpace = tnObj.getLimit(town.MAX_SPACE);
	if (maxSpace <= 0) maxSpace = town.DEFAULT_MAX_SPACE;
	
	// 1, 2, or 1@Monthly, etc.
	int idx;
	String paymentMethod;
	String serviceLevel = tnObj.getSubAttribute(town.ATTR_OPTION, town.SERVICE_LEVEL);
	if (serviceLevel!=null && (idx = serviceLevel.indexOf('@')) != -1) {
		paymentMethod = serviceLevel.substring(idx+1);
		serviceLevel = town.getLevelString(serviceLevel.substring(0,idx));
	}
	else {
		paymentMethod = town.DEFAULT_PAYMENT_METHOD;
		serviceLevel = town.DEFAULT_LEVEL;
	}

%>


<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen" />
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print" />
<jsp:include page="../init.jsp" flush="true" />
<jsp:include page="../forms.jsp" flush="true"/>
<script language="JavaScript" src="../validate.js"></script>

<script language="JavaScript">
<!--
function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

function validation()
{
	var compName = trim(UpdCompany.CompanyName.value);
	if (compName == '')
	{
		fixElement(UpdCompany.CompanyName,
			"Please make sure that the COMPANY DISPLAY NAME field is properly completed.");
		return false;
	}
	UpdCompany.CompanyName.value = compName;	// trimmed

	var deptName = trim(UpdCompany.DeptName.value);
	if (deptName!='' && (deptName.indexOf(".")!=-1 || deptName.indexOf(",")!=-1) )
	{
		fixElement(UpdCompany.DeptName,
			"Use semicolon (;) to separate departments.  DEPARTMENTS cannot contain period (.) or comma (,)");
		return false;
	}
	UpdCompany.DeptName.value = deptName;	// trimmed	
	
	return;
}

function delComp()
{
	if (!confirm("Deleting a company is a non-revokable action.  Do you really want to proceed?"))
		return;
	location = "post_comp_del.jsp?id=<%=tidS%>";
}

function cancelService()
{
	alert("During the beta period, please contact your Account Manager to cancel service.");
}

function createProject()
{
	location = "../project/proj_new1.jsp?tid=<%=tidS%>";
}

function createUser()
{
	location = "../admin/adduser.jsp?company=<%=tidS%>";
}

//-->
</script>

<title>
	Update Company
</title>

</head>

<body text="#000000" leftmargin="10" topmargin="10" marginwidth="0" marginheight="0">

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="100%" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">
	
	<table width='90%' border='0' cellspacing='0' cellpadding='0'>
	<tr>
		<td width='20'>&nbsp;</td>
		<td class='plaintext_head'><span class="head">
		Update Company </span><font color='#000055'><%=thisCompObj.getObjectName()%></font>
		</td>
<%	if (isAdmin) { %>		
		<td width='300'><img src='../i/bullet_tri.gif' width='20' height='10'/>
			<a class='listlinkbold' href='javascript:delComp()'>Delete this company</a></td>
<%	} %>
	</tr>
	</table>
	
	<br/><br/>
	
	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="/i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>


<form name="UpdCompany" method="post" action="post_comp_upd.jsp" enctype="multipart/form-data">
<input type="hidden" name="id" value="<%=tidS%>" >

<!-- CONTENT -->
<table border="0" width='90%'>

	<tr>
		<td width="15">&nbsp;</td>
		<td colspan='2' class="ptextS1"><font color="#00aa00">
		<%=msg%></font></td>
	</tr>

<%	if (msg!="") {out.print("<tr><td colspan='3'><img src='../i/spacer.gif' height='10' /></td></tr>");}%>

	<tr>
		<td width="15">&nbsp;</td>
		<td colspan='2'>
		<table width='100%' border='0' cellspacing='0' cellpadding='0'>
		<tr>
			<td class="ptextS2" width="180"><%=dispName%> Account Manager: </td>
			<td class="ptextS2">
<%	if (!isAdmin) {
		if (acctMgrId > 0) {
			o = uMgr.get(me, acctMgrId);
			uname = ((user)o).getFullName();
		}
		else {
			uname = "EGI Admin";
		}
		out.print(uname);
	}
	else {
		// isAdmin
		out.print("<select name='AcctManager' class='formtext'>");
		out.print("<option value=''>- select account manager -</option>");

		ids = uMgr.findId(me, "Role='" + user.ROLE_ACCTMGR + "'");

		for (int i=0; i<ids.length; i++)
		{
			o = uMgr.get(me, ids[i]);
			uname = ((user)o).getFullName();
			out.print("<option value='" + o.getObjectId() + "'");
			if (o.getObjectId() == acctMgrId)
				out.print(" selected");
			out.print(">" + uname + "</option>");
		}
		out.print("</select>");
	}	// else: isAdmin
%>
			</td>

<%	if (isAdmin || isChief || isAcctMgr) { %>
			<td width='300'>
				<table>
					<tr><td><img src='../i/bullet_tri.gif'/><a href='javascript:location="../info/upgrade.jsp";' class='listlinkbold'>Upgrade Your Service</a></td></tr>
					<tr><td><img src='../i/bullet_tri.gif'/><a href='javascript:cancelService();' class='listlinkbold'>Cancel Service</a></td></tr>
					<tr><td><img src='../i/bullet_tri.gif'/><a href='javascript:createProject();' class='listlinkbold'>New Project</a></td></tr>
					<tr><td><img src='../i/bullet_tri.gif'/><a href='javascript:createUser();' class='listlinkbold'>New User</a></td></tr>
				</table>
			</td>
<%	} %>
		</tr>
		</table>
		</td>
	</tr>
	
	<tr><td colspan='3'><img src='../i/spacer.gif' height='10' /></td></tr>
	
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan='2' class="ptextS2">
			<b>Company Service Agreement</b>
		</td>
	</tr>
	
	<tr><td colspan='3'><img src='../i/spacer.gif' height='5'/></td></tr>
	
	<tr>
		<td height='20'></td>
		<td class="formtext_blue">&nbsp;&nbsp; Subscription Level: </td>
		<td class='plaintext'><%=serviceLevel%> (<%=paymentMethod%>)</td>
	</tr>
	
	<tr>
		<td height='20'></td>
		<td class="formtext_blue">&nbsp;&nbsp; Max # of Projects: </td>
		<td class='plaintext'><%=maxProj%></td>
	</tr>
	
	<tr>
		<td height='20'></td>
		<td class="formtext_blue">&nbsp;&nbsp; Max # of Users: </td>
		<td class='plaintext'><%=maxUser%></td>
	</tr>
	
	<tr>
		<td height='20'></td>
		<td class="formtext_blue">&nbsp;&nbsp; Total Storage Space: </td>
		<td class='plaintext'><%=maxSpace%> GB</td>
	</tr>
	
	<tr><td colspan='3'><img src='../i/spacer.gif' height='30' /></td></tr>
	
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan='2' class="ptextS2">
			<b>Company Information</b>
		</td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="instruction">
		<br>
		Note that fields marked with an * are required.<br><br></td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' height='5' /></td></tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="formtext_blue" width="180" valign='top'><font color="#000000">*</font> Company Display Name: </td>
		<td><table border='0' cellspacing='0' cellpadding='0'>
			<tr>
				<td><input type="text" name="CompanyName" size="35" class="formtext" value="<%=dispName%>" <%=disabledStr%>></td>
				<td class="formtext_small">&nbsp;&nbsp;e.g. ABC Trading International, Inc.</td>
			</tr>
			</table>
		</td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="formtext_blue" width="180" valign='top'>&nbsp;&nbsp; Departments / Doc Types: </td>
		<td><table border='0' cellspacing='0' cellpadding='0'>
			<tr>
				<td><input type="text" name="DeptName" size="35" class="formtext" value="<%=deptName%>" <%=disabledStr%>></td>
				<td class="formtext_small">&nbsp;&nbsp;separated by semicolons. (e.g. ADMIN;HR;ENGR)</td>
			</tr>
			</table>
		</td>
	</tr>

<%	if (bUpdateOK) { %>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="formtext_blue">&nbsp;&nbsp; Change Company Logo: </td>
		<td class="formtext_small">
		 <input type="file" name="Picture" class="formtext" size="35" value="">&nbsp;The current logo is displayed above.
		</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' height='10' /></td></tr>
<%	} %>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="formtext_blue">&nbsp;&nbsp; Program Manager: </td>
		<td><table border='0' cellspacing='0' cellpadding='0'>
			<tr>
				<td><input type="text" name="ProgManager" size="35" class="formtext" value="<%=currentProgMgr%>" <%=disabledStr%>></td>
				<td class="formtext_small">&nbsp;&nbsp;enter a username</td>
			</tr>
			</table>
		</td>
	</tr>


	<tr><td colspan='3'><img src='../i/spacer.gif' height='10' /></td></tr>


<%
	String backBut = "javascript:location='../ep/ep_home.jsp';";
	session.setAttribute("comPicFile", oriLogo);
%>

<!-- Submit Button -->
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="10ptype" align="center"><br>
<%	if (bUpdateOK) { %>		
			<input type="submit" class='button_medium' name="Submit" value="  Submit  " onclick="return validation();"/>&nbsp;
<%	} %>
			<input type="button" class='button_medium' value="   Cancel   " onClick="<%=backBut%>" />&nbsp;
		</td>
	</tr>

</form>
</table>


<tr><td>&nbsp;</td><tr>


<!-- BEGIN FOOTER TABLE -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

