<%
////////////////////////////////////////////////////
//	Copyright (c) 2006, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	biz_mtg1.jsp
//	Author:	ECC
//	Date:	11/01/06
//	Description:
//		Describe business meeting (setup a meeting).
//	Modification:
//
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "util.*" %>
<%@ page import = "oct.pst.*" %>

<%
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
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">

<script language="JavaScript">
<!--

function newUser()
{
	location = "../login_omf.jsp?status=new";
}
//-->
</script>

<title>
	Business Meeting
</title>

</head>

<body text="#000000" leftmargin="10" topmargin="10" marginwidth="0" marginheight="0">

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="715" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="infohead.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<b class="head">

	&nbsp;&nbsp;Business Meeting (1 of 2)

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

<style type="text/css">
.headlnk_green {  font-family: Verdana, Arial, Helvetica, sans-serif; color: #30cc30; font-size: 16px; font-weight: bold}
.headlnk_blue {  font-family: Verdana, Arial, Helvetica, sans-serif; color: #3030cc; font-size: 14px; font-weight: bold}
a.headlnk_blue:link, a.headlnk_blue:active, a.headlnk_blue:visited {  font-family: Verdana, Arial, Helvetica, sans-serif; color: #3030cc; font-size: 14px; font-weight: bold}
.headlnk_pink {  font-family: Verdana, Arial, Helvetica, sans-serif; color: ee2288; font-size: 16px; font-weight: bold; text-decoration: none}
</style>

<!-- CONTENT -->
<table>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_head"><br>
		<br>

	<table border="0" width="100%" cellspacing="0" cellpadding="0">
		<tr>
			<td colspan='2' class='headlnk_blue' align='center' width='600'>
			<font size=+1>You Schedule and Prepare for a meeting with MeetWE</font>
			</td>
		</tr>
		<tr><td colspan='2'><img src='../i/spacer.gif' height='15' width='1'></td></tr>
		<tr>
			<td colspan='2' class='headlnk_dark' align='left' width='550'>
			<img src='../i/spacer.gif' height='1' width='50'>First, you may optionally prepare an agenda,<br>
				<img src='../i/spacer.gif' height='1' width='150'>or use any past agenda from the library
			</td>
		</tr>
		
		<tr>
			<td colspan='2'>
			<table border="0" cellspacing="0" cellpadding="0"><tr>
				<td><img src='../i/spacer.gif' height='1' width='100'><img src="../i/agenda.gif"></td>
			</tr></table>
			</td>
		</tr>

		<tr><td colspan='2'><img src='../i/spacer.gif' height='15' width='1'></td></tr>
		<tr>
			<td colspan='2' class='headlnk_dark' align='left' width='550'>
			<img src='../i/spacer.gif' height='1' width='50'>Second, you invite attendees to the meeting
			</td>
		</tr>
		
		<tr>
			<td colspan='2'>
			<table border="0" cellspacing="0" cellpadding="0"><tr>
				<td><img src="../i/attendee.gif"></td>
				<td valign='top'>
					<table border="0" cellspacing="0" cellpadding="0">
					<tr><td class='headlnk_green'>Learn More ...</td></tr>
					<tr><td><img src='../i/spacer.gif' height='5' width='1'></td></tr>
					<tr><td><img src='../i/spacer.gif' width='20'><a class='headlnk_blue' href='biz_mtg2.jsp'>Business Meetings<span class='headlnk_pink'> &raquo;</span></a></td></tr>
					<tr><td><img src='../i/spacer.gif' width='20'><a class='headlnk_blue' href='corporate.jsp'>Corporate Account<span class='headlnk_pink'> &raquo;</span></a></td></tr>
					</table>
				</td>
			</tr></table>
			</td>
		</tr>

		<tr><td colspan='2'><img src='../i/spacer.gif' height='15' width='1'></td></tr>
		<tr>
			<td colspan='2' class='headlnk_dark' align='left' width='600'>
			<img src='../i/spacer.gif' height='1' width='50'>Invitees will receive an email notification for the scheduled meeting.
				<br><img src='../i/spacer.gif' height='1' width='150'>You may also upload files for the meeting.
			</td>
		</tr>
		
		<tr><td colspan='2'><img src='../i/spacer.gif' height='15' width='1'></td></tr>
		
<%	if (!isLogin)
	{%>
		<tr>
			<td colspan='2'><table border="0" cellspacing="0" cellpadding="0"><tr>
			<td><img src="../i/spacer.gif" width='600' height='60'></td>
	  		<td align='center' class='plaintext'><input type="submit" value='SIGN UP NOW' onclick='return newUser();'>
	  		<br> ... and get a free account</td>
	  		</tr></table></td>
		</tr>
<%	}%>
	</table>

<span class="plaintext">

<!-- CONTENT -->

To learn more, please visit our <a href='help.jsp'>Help Forum</a> and <a href='faq_omf.jsp?home=../index.jsp'>FAQ</a> Page<br>
For any other questions, please e-mail
<a href="mailto:<%=ADMIN_MAIL%>">The MeetWE Team</a>


</span>
</td></tr>
</table>



<!-- BEGIN FOOTER TABLE -->
<table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td width="780" height="2" bgcolor="336699"><img src="../i/mid/u2x2.gif" width="2" height="2"></td>
    <td height="2" bgcolor="336699"><img src="../i/mid/u2x2.gif" width="2" height="2"></td>
  </tr>
  <tr>
    <td width="780" valign="middle" align="center">
		<a href="../index.jsp" class="listlink">Home</a>
		&nbsp;|&nbsp;
		<a href="faq_omf.jsp?home=../index.jsp" class="listlink">FAQ</a>
		&nbsp;|&nbsp;
		<a href="help.jsp" class="listlink">Help forum</a>
		&nbsp;|&nbsp;
		<a href="#top" class="listlink">Back to top</a></td>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td width="780" height="32" align="center" valign="middle"><font size="1" face="Arial, Helvetica, sans-serif" color="#999999" class="8ptype">Copyright
      &copy; 2006, MeetWE</font></td>
    <td height="32">&nbsp;</td>
  </tr>
</table>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

