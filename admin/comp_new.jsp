<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<%
////////////////////////////////////////////////////
//	Copyright (c) 2004-2008, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	comp_new.jsp
//	Author:	ECC
//	Date:	08/11/08
//	Description:
//		Add a new company (town organization).  Only CR and MultiCorp support adding new company.
//
//	Modification:
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "util.Util" %>

<%
	String noSession = "../out.jsp?go=admin/comp_new.jsp";
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%
	// only CR and multiCorp would come into this page
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	PstUserAbstractObject me = pstuser;

	// check admin or acctMgr
	boolean isAdmin = false;
	boolean isAcctMgr = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ( (iRole & user.iROLE_ADMIN) > 0 )
		isAdmin = true;
	if ( (iRole & user.iROLE_ACCTMGR) > 0 )
		isAcctMgr = true;
	
	String s;
	PstAbstractObject o;
	
	townManager tnMgr = townManager.getInstance();

	if (me==null || (me instanceof PstGuest) || (!isAdmin && !isAcctMgr) )
	{
		response.sendRedirect("../out.jsp?msg=Please contact EGI Technologies at <a href='mailto:info@egiomm.com'>info@egiomm.com</a> to create a new company account");
		return;
	}
	
	String msg = request.getParameter("msg");
	if (msg == null) msg = "";

	String fName = "";
	String lName = "";
	String eMail = "";
	
	s = Util.getPropKey("pst", "USERNAME_EMAIL");
	boolean isEmailUsername = (s!=null && s.equalsIgnoreCase("true"));

%>

<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
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
	var compName = trim(AddCompany.CompanyName.value);
	if (compName == '')
	{
		fixElement(AddCompany.CompanyName,
			"Please make sure that the COMPANY DISPLAY NAME field is properly completed.");
		return false;
	}
	AddCompany.CompanyName.value = compName;	// trimmed

	var deptName = trim(AddCompany.DeptName.value);
	if (deptName!='' && (deptName.indexOf(".")!=-1 || deptName.indexOf(",")!=-1) )
	{
		fixElement(AddCompany.DeptName,
			"Use semicolon (;) to separate departments.  DEPARTMENTS cannot contain period (.) or comma (,)");
		return false;
	}
	AddCompany.DeptName.value = deptName;	// trimmed

	var uname = trim(AddCompany.Username.value);
	if (uname == '')
	{
		fixElement(AddCompany.Username,
			"Please make sure that the USERNAME field is properly completed.");
			return false;
	}
	AddCompany.Username.value = uname;				// trimmed

	var email = trim(AddCompany.Email.value);
	if (email.length > 0)
	{
		if (!checkMail(email))
		{
			fixElement(AddCompany.Email,
				"'" + email + "' is not a valid email address, \nplease correct the error and submit again.");
			return false;
		}
	}
	else
	{
		fixElement(AddCompany.Email,
			"Please make sure that the EMAIL field is properly completed.");
		return false;
	}
	AddCompany.Email.value = email;				// trimmed

	var firstName = trim(AddCompany.FirstName.value);
	if (firstName == '')
	{
		fixElement(AddCompany.FirstName,
			"Please make sure that the FIRST NAME field is properly completed.");
		return false;
	}
	
	if (containsBadChar(firstName))
	{
		fixElement(AddCompany.FirstName,
			"FIRST NAME cannot contain these characters: \n  \" \\ ~ ` ! # $ % ^ * ( ) + = [ ] { } |  ? > <");
		return false;
	}
	AddCompany.FirstName.value = firstName;		// trimmed
		
	var lastName = trim(AddCompany.LastName.value);
	if (lastName =='')
	{
		fixElement(AddCompany.LastName,
			"Please make sure that the LAST NAME field is properly completed.");
		return false;
	}
	
	if (containsBadChar(lastName))
	{
		fixElement(AddCompany.LastName,
			"LAST NAME cannot contain these characters: \n  \" \\ ~ ` ! # $ % ^ * ( ) + = [ ] { } |  ? > <");
		return false;
	}
	AddCompany.LastName.value = lastName;		// trimmed
	
	
	return;
}

//-->
</script>

<title>
	Add New Company
</title>

</head>

<body text="#000000" leftmargin="10" topmargin="10" marginwidth="0" marginheight="0">

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="715" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td width='20'>&nbsp;&nbsp;&nbsp;</td>
	<td valign="top">
	<b class="head">
	Add New Company
	</b><br><br>
	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="/i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- CONTENT -->
<table border="0">

	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="plaintext"><font color="#aa0000">
		<%=msg%></font></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="instruction">
		<br>
		Please enter the information of the new company.
		<p>Note that fields marked with an * are required.<br><br></td>
	</tr>


<form name="AddCompany" method="post" action="post_comp_new.jsp" enctype="multipart/form-data">

	<tr><td colspan='3'><img src='../i/spacer.gif' height='5' /></td></tr>
	
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan='2' class="instruction">
			<b>Company Information</b>
		</td>
	</tr>
	
	<tr><td colspan='3'><img src='../i/spacer.gif' height='10' /></td></tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="formtext_blue" width="180" valign='top'><font color="#000000">*</font> Company Display Name: </td>
		<td><table border='0' cellspacing='0' cellpadding='0'>
			<tr>
				<td><input type="text" name="CompanyName" size="35" class="formtext"></td>
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
				<td><input type="text" name="DeptName" size="35" class="formtext"></td>
				<td class="formtext_small">&nbsp;&nbsp;separated by semicolons (e.g. ADMIN;HR;ENGR)</td>
			</tr>
			</table>
		</td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="formtext_blue">&nbsp;&nbsp; Upload Company Logo: </td>
		<td class="formtext">
		 <input type="file" name="Picture" class="formtext" size="35" value="">
		</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' height='20' /></td></tr>
	
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan='2' class="instruction">
			<b>Program Manager Information</b>
		</td>
	</tr>
	
	<tr><td colspan='3'><img src='../i/spacer.gif' height='10' /></td></tr>

<%	if (!isEmailUsername) { %>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="formtext_blue"><font color="#000000">*</font> Username: </td>
		<td>
			<input type="text" name="Username" value="" size="35" class="formtext">
		</td>
	</tr>
<%	} %>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="formtext_blue"><font color="#000000">*</font> Email: </td>
		<td>
			<input type="text" name="Email" value="<%=eMail%>" size="35" class="formtext">
		</td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="formtext_blue"><font color="#000000">*</font> First Name: </td>
		<td>
		<input type="text" name="FirstName" value="<%=fName%>" size="20" class="formtext">
		</td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="formtext_blue"><font color="#000000">*</font> Last Name: </td>
		<td>
			<input type="text" name="LastName" value="<%=lName%>" size="20" class="formtext">
		</td>
	</tr>
	
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan='2' class="formtext_blue">
			&nbsp;&nbsp;<input type="checkbox" name="SendEmail" checked>Send Email notification to Program Manager
		</td>
	</tr>
	
<%
	String backBut = "javascript:location='../ep/ep_home.jsp';";
%>

<!-- Submit Button -->
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="10ptype" align="center"><br>
			<input type="Button" value="   Cancel   " onClick="<%=backBut%>">&nbsp;
			<input type="Submit" name="Submit" value="  Submit  " onclick="return validation();">&nbsp;
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

