<%
//
//	Copyright (c) 2007, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_corp_signup.jsp
//	Author: ECC
//	Date:		1/09/2007
//	Description:	Handle corporate account signup and display a successful message on page.
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>

<%
	// update rating
	if (session == null) session = request.getSession(true);
	PstUserAbstractObject pstuser = (PstUserAbstractObject)session.getAttribute("pstuser");
	if (pstuser == null || pstuser instanceof PstGuest)
	{
		pstuser = PstGuest.getInstance();
		session.setAttribute("pstuser", pstuser);
	}

	String compName = request.getParameter("CompanyName");
	String domain = request.getParameter("Domain");
	String fName = request.getParameter("FirstName");
	String lName = request.getParameter("LastName");
	String phone = request.getParameter("Phone");
	String contactEmail = request.getParameter("ContactEmail");
	String addr1 = request.getParameter("Address1");
	String addr2 = request.getParameter("Address2");
	String city = request.getParameter("City");
	String state = request.getParameter("State");
	String country = request.getParameter("Country");

	townManager tnMgr = townManager.getInstance();
	userManager uMgr = userManager.getInstance();
	
	// create the new town
	PstAbstractObject tn = tnMgr.create(pstuser, compName);
System.out.println(tn.getObjectId());

	// store the attributes of the town
	tn.setAttribute("Email", domain);
	tn.setAttribute("FirstName", fName);
	tn.setAttribute("LastName", lName);
	tn.setAttribute("Phone", phone);
	tn.setAttribute("ContactEmail", contactEmail);
	
	tn.setAttribute("Address", addr1);
	if (addr2.length() > 0)
		tn.setAttribute("Address2", addr2);
	tn.setAttribute("City", city);
	if (state.length()>0 && !state.equals("none"))
		tn.setAttribute("State", state);
	else
		state = null;
	tn.setAttribute("Country", country);
	
	Date now = new Date();
	tn.setAttribute("CreatedDate", now);
	tn.setAttribute("LastUpdatedDate", now);

	tnMgr.commit(tn);
	
	// all users that match this domain address will be added to the company
	PstAbstractObject o;
	int [] id = uMgr.findId(pstuser, "Email='%" + domain + "'");
	for (int i=0; i<id.length; i++)
	{
		// there can only have one user with this Email
		o = uMgr.get(pstuser, id[i]);
		o.appendAttribute("Towns", new Integer(tn.getObjectId()));
		uMgr.commit(o);
	}
	
	// send mail to MeetWE admin and to the contact person for confirmation
	String subject = "[MeetWE] Welcom to MeetWE-" + compName;
	String msg= "Thank you for using MeetWE.  Your company account has been set up successfully.";
	msg += "<br />Please keep this email for your record.  You will need a copy of this email to claim any rebate or free gift."
		+ "<br />"
		+ "<table border='0' cellspacing='0' cellpadding='0'><tr><td width='20'>&nbsp;</td><td>"
		+ "<table border='0' cellspacing='0' cellpadding='0'>"
		+ "<tr><td width='100'>Company Name:</td><td>" + compName + "</td></tr>"
		+ "<tr><td width='100'>Company Email Domain:</td><td>" + domain + "</td></tr>"
		+ "<tr><td width='100'>Contact Person:</td><td>" + fName + " " + lName + "</td></tr>"
		+ "<tr><td width='100'>Phone:</td><td>" + phone + "</td></tr>"
		+ "<tr><td width='100'>Email:</td><td>" + contactEmail + "</td></tr>"
		+ "<tr><td colspan='2'>&nbsp;</td></tr>"
		+ "<tr><td width='100'>Billing Address:</td><td>" + addr1;
	if (addr2.length() > 0)
		msg += ", " + addr2;
	msg += ", " + city;
	if (state != null)
		msg += ", " + state;
	msg += ", " + country + "</td></tr>";
	msg += "</table></td></tr></table>";
	msg += "<br /><br />";
	msg += "You and anyone from your company can now register as MeetWE-" + compName + " users.";
	msg += "Please click the following link to register: <blockquote>";
	msg += "<a href='http://www.MeetWE.com/login_omf.jsp?status=new'>Register user</a>";
	msg += "<br />http://www.MeetWE.com/login_omf.jsp?status=new</blockquote>";
	msg += "Please make sure to use the same email domain (<b>" + domain
			+ "</b>) when submitting the email address in registration in order to be recognized as a user under "
			+ compName + ".";
	msg += "<br /><br />";
	msg += "If you have any questions, please contact us by sending email to ";
	msg += "<a href='mailto: support@meetwe.com'>support@MeetWE.com</a>";
	msg += "<br /><br />";
	msg += "Thank you again for choosing MeetWE.";
	msg += "<br /><br />";
	msg += "Best Regards,<br />";
	msg += "The MeetWE Team";
	String from = Util.getPropKey("pst", "FROM");
	Util.sendMailAsyn(pstuser, from, contactEmail, null, from, subject, msg, "alert.htm"); 

%>


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html lang="en">

<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../formsM.jsp" flush="true"/>
<script language="JavaScript" src="../get-date.js"></script>
<script language="JavaScript" src="../date.js"></script>

<script language="JavaScript">
<!--


//-->
</script>

</head>

<title>New Corporate Account</title>
<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" height="100%" border="0" cellspacing="0" cellpadding="0">

<!-- TOP BANNER -->
<jsp:include page="infohead.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<b class="head">
           &nbsp;&nbsp;<b>Welcome to MeetWE</b>
	</b><br><br>
	
	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- Navigation SUB-Menu -->
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
<td width="100%" valign="top">

	<table border="0" width="620" height="14" cellspacing="0" cellpadding="0">
		<tr>
			<td valign="top" align="right" class="bgsubnav">
				<table border="0" cellspacing="0" cellpadding="0">
				<tr class="bgsubnav">
	<!-- Home -->
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="../index.jsp" class="subnav">Home</a></td>
					<td colspan="3" width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- FAQ -->
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="faq_omf.jsp" class="subnav">FAQ</a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- Terms of Use -->
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="terms_omf.jsp" class="subnav">Terms of Use</a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- Help Forum -->
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="help.jsp" class="subnav">Help Forum</a></td>
					<td colspan="3" width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

				</tr>
				</table>
			</td>
		</tr>
	</table>
	<table border="0" width="620" height="1" cellspacing="0" cellpadding="0">
		<tr>
			<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
		</tr>
	</table>

</td>
</tr>
</table>
<!-- End of Navigation SUB-Menu -->

<!-- Content Table -->
<table width="770" border="0" cellspacing="0" cellpadding="0">
<tr><td colspan="2">&nbsp;</td></tr>


	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="instruction">
		<br>
		Thank you for using MeetWE.  Your company account has been set up successfully.
		<br><br>
		If you are not
		a user of MeetWE, please click the following link to join.  Anyone from your company can also
		join MeetWE-<%=compName%>.  In the user registration, please make sure to use a Email address that matches the company domain
		(<%=domain%>).<br><br>
		<a href='http://www.MeetWE.com/login_omf.jsp?status=new'>Please click to register as a user of MeetWE-<%=compName%></a>
		<br><br>
		If you are already a user of MeetWE and are using the company domain email address,
		you don't need to do anything; you are now automatically included in the <b><%=compName%></b> account.
		</td>
	</tr>

		<!-- End of Content Table -->
		<!-- End of Main Tables -->

</table>
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
