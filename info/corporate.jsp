<%
////////////////////////////////////////////////////
//	Copyright (c) 2007, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	corporate.jsp
//	Author:	ECC
//	Date:	01/04/07
//	Description:
//		Describe corporate account and benefits.
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
	
	boolean isLogin = false;
	String home = null;
	if (session != null)
	{
		PstUserAbstractObject pstuser = (PstUserAbstractObject)session.getAttribute("pstuser");
		if (pstuser != null && !(pstuser instanceof PstGuest))
		{
			isLogin = true;
			home = "../ep/ep_home.jsp";
		}
		else
			home = "../index.jsp";
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

function newCorp()
{
	location = "corp_signup1.jsp";
}
//-->
</script>

<title>
	MeetWE Corporate Account
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

	&nbsp;&nbsp;Corporate Account

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
					<td><a href="<%=home%>" class="subnav">Home</a></td>
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
.headlnk_blue {  font-family: Verdana, Arial, Helvetica, sans-serif; color: 2255aa; font-size: 14px; font-weight: bold}
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
			<td colspan='2' class='headlnk_dark' align='center' width='400'>
			</td>
		</tr>
		
		<tr>
			<td colspan='2'>
			<table border="0" cellspacing="0" cellpadding="0"><tr>
				<td><img src="../i/corp.jpg"></td>
				<td><img src='../i/spacer.gif' width='20'></td>
				<td valign='top'>
					<table border="0" cellspacing="0" cellpadding="0">
					<tr><td class='headlnk_blue' colspan='2'>Benefits</td></tr>
					<tr><td><img src='../i/spacer.gif' height='5' width='1'></td></tr>
					<tr><td valign='baseline'><img src='../i/dot_darkgreen.gif'>&nbsp;</td><td class='plaintext'>Improve productivity of all your company and group meetings.</td></tr>
					<tr><td valign='baseline'><img src='../i/dot_darkgreen.gif'>&nbsp;</td><td class='plaintext'>Improve meeting experience and promote teamwork between local and global teams.</td></tr>
					<tr><td valign='baseline'><img src='../i/dot_darkgreen.gif'>&nbsp;</td><td class='plaintext'>Eliminate confusions in meeting coordination and preparation.</td></tr>
					<tr><td valign='baseline'><img src='../i/dot_darkgreen.gif'>&nbsp;</td><td class='plaintext'>Improve effectiveness in managing agenda, objectives, brainstorming, conclusions, actions and follow-ups.</td></tr>
					<tr><td valign='baseline'><img src='../i/dot_darkgreen.gif'>&nbsp;</td><td class='plaintext'>No dropping of followup action items or decisions over multiple meetings.</a></td></tr>
					<tr><td valign='baseline'><img src='../i/dot_darkgreen.gif'>&nbsp;</td><td class='plaintext'>Easy to record and distribute meeting minutes for each meeting.</td></tr>
					<tr><td valign='baseline'><img src='../i/dot_darkgreen.gif'>&nbsp;</td><td class='plaintext'>Easily link meeting instances together whether you are teleconferencing, video-conferencing, web-conferenting, or meeting face-to-face.</td></tr>
					<tr><td valign='baseline'><img src='../i/dot_darkgreen.gif'>&nbsp;</td><td class='plaintext'>Efficient pre-meeting preparations with file sharing and blogging.</td></tr>
					<tr><td valign='baseline'><img src='../i/dot_darkgreen.gif'>&nbsp;</td><td class='plaintext'>Enable multiple users to chat and brainstorm during meetings.</td></tr>
					<tr><td valign='baseline'><img src='../i/dot_darkgreen.gif'>&nbsp;</td><td class='plaintext'>1-Click integration with your favorite teleconferencing or video-conferencing program.</td></tr>
					<tr><td valign='baseline'><img src='../i/dot_darkgreen.gif'>&nbsp;</td><td class='plaintext'>Enable you to attend multiple meetings at the same time.</td></tr>
					</table>
				</td>
			</tr></table>
			</td>
		</tr>

		<tr><td colspan='2'><img src='../i/spacer.gif' height='20' width='1'></td></tr>
		<tr>
			<td><img src="../i/spacer.gif" width='10' height='1'></td>
			<td class='headlnk_dark' align='left' width='450'>
			Special Offer for a Limited Time Only
			</td>
		</tr>
		<tr><td colspan='2'><img src='../i/spacer.gif' height='10' width='1'></td></tr>
		<tr>
			<td><img src="../i/spacer.gif" width='10' height='1'></td>
			<td valign='top'>
				<table border="0" cellspacing="0" cellpadding="0">
					<tr><td valign='baseline'><img src='../i/dot_darkgreen.gif'>&nbsp;</td><td class='headlnk_blue'>FREE to setup a corporate account&nbsp;&nbsp;&nbsp;<span class='plaintext_grey'>(a $199 value)</span></td></tr>
					<tr><td valign='baseline'><img src='../i/dot_darkgreen.gif'>&nbsp;</td><td class='headlnk_blue'>FREE annual subscription for the first 3 employees&nbsp;&nbsp;&nbsp;<span class='plaintext_grey'>(a $59.85 value)</span></td></tr>
					<tr><td valign='baseline'><img src='../i/dot_darkgreen.gif'>&nbsp;</td><td class='headlnk_blue'>FREE <font color='#dd0000'>iPod Nano 2GB</font> or <font color='#dd0000'>palmOne Tungsten E2 </font>PDA&nbsp;&nbsp;&nbsp;<span class='plaintext_grey'>(a $199 value)</span></td></tr>
				</table>
			</td>
		</tr>

		<tr>
			<td colspan='2'><table border="0" cellspacing="0" cellpadding="0"><tr>
			<td><img src="../i/spacer.gif" width='600' height='60'></td>
	  		<td align='center' class='plaintext'><input type="submit" value='SET UP NOW' onclick='return newCorp();'>
	  		<br> ... and get a free iPod Nano</td>
	  		</tr></table></td>
		</tr>

	</table>



<span class="plaintext">

<!-- CONTENT -->

</p>



<p class="plaintext">
To learn more, please visit our <a href='help.jsp'>Help Forum</a> and <a href='faq_omf.jsp?home=<%=home%>'>FAQ</a> Page<br>
For any other questions, please e-mail
<a href="mailto:<%=ADMIN_MAIL%>">The MeetWE Team</a>
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
		<a href="<%=home%>" class="listlink">Home</a>
		&nbsp;|&nbsp;
		<a href="faq_omf.jsp?home=<%=home%>" class="listlink">FAQ</a>
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

