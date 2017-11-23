<%
//
//	Copyright (c) 2007, EGI Technologies, Co.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: corp_signup1.jsp
//	Author: ECC
//	Date:	01/04/07
//	Description: Signup a new company on MeetWE.
//
//
//	Modification:
// 
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "util.*" %>
<%@ page import = "oct.pst.*" %>

<%
	String COMPANY		= Util.getPropKey("pst", "COMPANY_NAME");
	String NODE			= Util.getPropKey("pst", "PRM_HOST");
	String ADMIN_MAIL	= Util.getPropKey("pst", "FROM");
	
	boolean isLogin = false;
	if (session != null)
	{
		PstUserAbstractObject pstuser = (PstUserAbstractObject)session.getAttribute("pstuser");
		if (pstuser != null && !(pstuser instanceof PstGuest))
			isLogin = true;
	}
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
function fo()
{
	var Form = document.newCompany;
	for (i=0;i < Form.length;i++)
	{
		if (Form.elements[i].type != "hidden")
		{
			Form.elements[i].focus();
			break;
		}
	}
}

function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

function validation()
{
	var f = document.newCompany;
	var comName = trim(f.CompanyName.value);
	if (comName.length <= 0)
	{
		fixElement(f.CompanyName,
			"Please make sure that the COMPANY NAME field is properly completed.");
		return false;
	}
	f.CompanyName.value = comName;
	
	var dom = trim(f.Domain.value);
	if (dom.length > 0)
	{
		if (!checkDomain(dom))
		{
			fixElement(f.Domain,
				"'" + dom + "' is not a valid email domain address, \nplease correct the error and submit again.");
			return false;
		}
	}
	else
	{
		fixElement(f.Domain,
			"Please make sure that the COMPANY EMAIL DOMAIN field is properly completed.");
		return false;
	}
	f.Domain.value = dom;

	return;
}



//-->
</script>

</head>

<title>New Corporate Account</title>
<body onLoad="fo();" bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" height="100%" border="0" cellspacing="0" cellpadding="0">

<!-- TOP BANNER -->
<jsp:include page="infohead.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<b class="head">
           &nbsp;&nbsp;<b>New Corporate Account</b>
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


<form method="post" name="newCompany" id="newCompany" action="corp_signup2.jsp">

	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="instruction_head"><br><b>Step 1 of 2: Enter Company Information</b></td>
	</tr>

	<tr>
		<td width="20">&nbsp;</td>
		<td colspan=2 class="instruction">
		<br>Please note that fields marked with an * are required.<br><br></td>
	</tr>

<!-- Company Name -->
	<tr>
		<td width="20">&nbsp;</td>
		<td width='250' class="plaintext_blue"><font color="#000000">*</font> Company Name:</td>
		<td>
			<input class="formtext" type="text" name="CompanyName" size="50" value=''>
		</td>
	</tr>
	
	<tr><td colspan='3'><img src='../i/spacer.gif' height='5'></td></tr>

<!-- Company Email Domain -->
	<tr>
		<td width="20">&nbsp;</td>
		<td width='250' class="plaintext_blue"><font color="#000000">*</font> Company Email Domain:</td>
		<td>
			<table border="0" cellspacing="0" cellpadding="0">
				<tr>
					<td><input class="formtext" type="text" name="Domain" size="30" value=''>&nbsp;&nbsp;&nbsp;</td>
					<td valign='bottom' class="footnotes">(E.g. aaa.com or bbb.com)</td>
				</tr>
			</table>
		</td>
	</tr>
	
	<tr><td colspan='3'><img src='../i/spacer.gif' height='15'></td></tr>
	
<!-- Terms and Conditions -->
	<tr>
		<td width="20">&nbsp;</td>
		<td width='250' class="plaintext_blue">Limited Time Offer:</td>
		<td>
		</td>
	</tr>
	<tr><td colspan='3'><img src='../i/spacer.gif' height='5'></td></tr>
	<tr>
		<td colspan='3' class='listtext_small'>
			<table border="0" cellspacing="0" cellpadding="0">
			<tr>
			<td width="40">&nbsp;</td>
			<td>
				<table border="0" cellspacing="0" cellpadding="0">
				<tr>
					<td valign='middle' width='20'><img src='../i/dot_darkgreen.gif'></td>
					<td class='plaintext_big' valign='middle' width='190'>Company 1-time setup fee:</td>
					<td valign='middle' width='120'><img src='../i/199.gif'><img src='../i/free.gif'></td>
					<td></td>
				</tr>
				<tr><td colspan='4'><img src='../i/spacer.gif' height='10'></td></tr>
				<tr>
					<td valign='middle' width='20'><img src='../i/dot_darkgreen.gif'></td>
					<td class='plaintext_big' valign='middle' width='190'>Annual user subscription fee:</td>
					<td valign='middle' class='plaintext_big' width='120'>$19.95/user/year</td>
					<td valign='middle' width='180'><img src='../i/3userFree.gif'></td>
				</tr>
				<tr><td colspan='4'><img src='../i/spacer.gif' height='5'></td></tr>
				<tr><td colspan='4'>
					<table border="0" cellspacing="0" cellpadding="0">
						<tr><td><ul>
							<li>The first 3 users of the company is FREE for the first year.
							<li>Additional user is $19.95/year.
							<li>You will be billed in the beginning of the month only for new user sign-up and for renewal of annual subscriptions.
						</ul></td></tr>
					</table>
					</td>
				</tr>
				<tr>
					<td valign='middle' width='20'><img src='../i/dot_darkgreen.gif'></td>
					<td colspan='2' class='plaintext_big' valign='middle'>FREE gift: iPod Nano 2GB or palmOne Tungsten E2 PDA</td>
					<td valign='middle'><img src='../i/ipod.gif'></td>
				</tr>
				<tr><td colspan='4'><img src='../i/spacer.gif' height='5'></td></tr>
				<tr><td colspan='4'>
					<table border="0" cellspacing="0" cellpadding="0">
						<tr><td><ul>
							<li>You are eligible to receive the free gift when there are 10 or more users registered from your company.
							<li>You must fill out and send in the gift claim form. &nbsp;&nbsp;<a href="../file/common/GiftClaimForm.pdf" class='formtext_small'>Click this to open and download the gift claim form.</a>
							<li>You must choose one of the two gift items.
							<li>Your gift claim will be processed in 45 days after we receive the corresponding user subscription fee from the company.
						</ul></td></tr>
					</table>
					</td>
				</tr>

				</table>
			</td>
			</tr>
			</table>
		</td>
	</tr>



<!-- Submit Button -->
	<tr>
		<td width="20">&nbsp;</td>
		<td colspan=2 class="10ptype" align="left"><br>
			<input type="Button" value="   Cancel  " class="button_medium" onclick="history.back(-1)">&nbsp;
			<input type="Submit" name="Submit" class="button_medium" value='  Continue  ' onclick="return validation();">
		</td>
	</tr>


</form>


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
