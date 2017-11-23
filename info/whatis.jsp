<%
////////////////////////////////////////////////////
//	Copyright (c) 2006, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	whatis.jsp
//	Author:	ECC
//	Date:	09/07/06
//	Description:
//		Describe what is MeetWE.
//	Modification:
//
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "util.*" %>
<%@ page import = "oct.pst.*" %>

<%
	String COMPANY		= Util.getPropKey("pst", "COMPANY_NAME");
	String NODE			= Util.getPropKey("pst", "PRM_HOST");
	String ADMIN_MAIL	= Util.getPropKey("pst", "FROM");
	
	String prodName;
	if (Prm.isMeetWE())
		prodName = "MeetWE";
	else
		prodName = "Collabris";
	
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
	What is <%=prodName%>
</title>

</head>

<body text="#000000" leftmargin="10" topmargin="10" marginwidth="0" marginheight="0">

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="90%" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="infohead.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<b class="head">

	&nbsp;&nbsp;What is <%=prodName%>?

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

	<table border="0" width="90%" height="14" cellspacing="0" cellpadding="0">
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
	<table border="0" width="90%" height="1" cellspacing="0" cellpadding="0">
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
<table width='100%'>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_head"><br>
		<br>

	<table border="0" width="100%" cellspacing="0" cellpadding="0">
		<tr>
			<td colspan='2' class='headlnk_dark' align='center' width='400'>
			<%=prodName%> is a Mobile-Cloud platform that provides free, virtual meeting rooms for groups of people
			<br>to collaborate online with chats, blogs, to-do's, meetings and discussions
			</td>
		</tr>
		
		<tr>
			<td colspan='2' align='center'>
			<table border="0" cellspacing="0" cellpadding="0"><tr>
				<td align='center'><img src="../i/MeetWEpic.gif" width='620'></td>
				<td>
					<table border="0" cellspacing="0" cellpadding="0">
					<tr><td class='headlnk_green'>Learn More ...</td></tr>
					<tr><td><img src='../i/spacer.gif' height='5' width='1'></td></tr>
					<tr><td><img src='../i/spacer.gif' width='20'><a class='headlnk_blue' href='biz_mtg1.jsp'>Business Meetings<span class='headlnk_pink'> &raquo;</span></a></td></tr>
					<tr><td><img src='../i/spacer.gif' width='20'><a class='headlnk_blue' href='chat_mtg1.jsp'>Chat Meetings<span class='headlnk_pink'> &raquo;</span></a></td></tr>
					<tr><td><img src='../i/spacer.gif' width='20'><a class='headlnk_blue' href='corporate.jsp'>Corporate Account<span class='headlnk_pink'> &raquo;</span></a></td></tr>
					</table>
				</td>
			</tr></table>
			</td>
		</tr>

		<tr>
			<td><img src="../i/spacer.gif" width='160' height='1'></td>
			<td class='headlnk_dark' align='center' width='450'>
			You and your group use <%=prodName%> to interact and</br>keep track of meeting minutes and follow-up action items
			</td>
		</tr>

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

</p>



<p class="plaintext">
To learn more, please visit our <a href='help.jsp'>Help Forum</a> and <a href='faq_omf.jsp?home=../index.jsp'>FAQ</a> Page<br>
For any other questions, please e-mail
<a href="mailto:<%=ADMIN_MAIL%>">The <%=prodName%> Team</a>
</p>

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
      &copy; 2011-2014, <%=prodName%></font></td>
    <td height="32">&nbsp;</td>
  </tr>
</table>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

