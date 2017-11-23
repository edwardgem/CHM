<%
////////////////////////////////////////////////////
//	Copyright (c) 2008, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	download.jsp
//	Author:	ECC
//	Date:	09/07/06
//	Description:
//		Download page.
//	Modification:
//
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "util.*" %>

<%
	String NODE	= Util.getPropKey("pst", "PRM_HOST");

	boolean isLogin = false;
	String home = request.getParameter("home");
	if (home == null)
	{
		home = "../ep/ep_home.jsp";
		isLogin = true;
	}
	String getFile = request.getParameter("file");
	if (getFile == null) getFile = "";
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">

<script language="JavaScript">
<!--
window.onload = function() {
	if ('<%=getFile%>' != '')
		location = "<%=NODE%>/file/common/RemoteSync.zip";
		//location = "<%=NODE%>/file/common/RemoteAccess.jar";
		//location = "<%=NODE%>/file/common/Setup.exe";
}

function download()
{
	document.downloadForm.submit();
}

//-->
</script>

<title>
	CR Download
</title>

</head>

<body text="#000000" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="715" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="infohead.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<b class="head">

	&nbsp;&nbsp;Download CR RemoteAccess

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

	<table border="0" width="100%" height="14" cellspacing="0" cellpadding="0">
		<tr>
			<td valign="top" class="bgsubnav">
				<table border="0" cellspacing="0" cellpadding="0">
				<tr class="bgsubnav">
	<!-- Home -->
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="<%=home%>" class="subnav">Home</a></td>
					<td colspan="3" width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- FAQ -->
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="faq.jsp" class="subnav">FAQ</a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- Download -->
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="20" height="14"><img src="../i/nav_arrow.gif" width="20" height="14" border="0"></td>
					<td><a href="#" onClick="return false;" class="subnav"><u>Download</u></a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- Upgrade -->
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="upgrade.jsp" class="subnav">Upgrade</a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

				</tr>
				</table>
			</td>
		</tr>
	</table>
	<table border="0" width="100%" height="1" cellspacing="0" cellpadding="0">
		<tr>
			<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
		</tr>
	</table>

</td>
</tr>
</table>
<!-- End of Navigation SUB-Menu -->

<style type="text/css">
table {border-collapse:collapse;}
.headlnk_blue {  font-family: Verdana, Arial, Helvetica, sans-serif; color: #202099; font-size: 14px;}
a.headlnk_blue:link, a.headlnk_blue:active, a.headlnk_blue:visited {  font-family: Verdana, Arial, Helvetica, sans-serif; color: #3030cc; font-size: 14px; font-weight: bold}
.headlnk_pink {  font-family: Verdana, Arial, Helvetica, sans-serif; color: ee2288; font-size: 16px; font-weight: bold; text-decoration: none}
.headlnk_green {  font-family: Verdana, Arial, Helvetica, sans-serif; color: #40a040; font-size: 14px; font-weight: bold}
.desc_text {  font-family: Verdana, Arial, Helvetica, sans-serif; color:#333333; font-size: 12px;line-height:1.6em}
.feature {  font-family: Verdana, Arial, Helvetica, sans-serif; color:#333333; font-size: 12px;line-height:2.0em}
</style>

<!-- CONTENT -->
<table border='0' cellspacing='0' cellpadding='0'>
		
	<tr><td><img src='../i/spacer.gif' height='20' /></td></tr>
		
	<tr><td></td><td><table>
		<tr><td valign='middle'><img src='../i/spacer.gif' width='30'>
		<img src='../i/download.jpg' border='0' /></td>
		<td><input type='submit' value='DOWNLOAD NOW' onclick='download()'></td>
		</tr></table>
	</td></tr>
		
	<tr><td><img src='../i/spacer.gif' height='20' /></td></tr>

	<tr>
		<td width="15"><img src='../i/spacer.gif' width='15' height='1' /></td>
		<td class="headlnk_green">Description</td>
	</tr>
		
	<tr><td><img src='../i/spacer.gif' height='3' /></td></tr>
	<tr><td></td><td><table cellspacing='0' cellpadding='0'><tr><td bgcolor="#40a040"><img src="../i/spacer.gif" height="2" width='650' border="0"></td>
		<td><img src='../i/spacer.gif' height='1' width='30' /></td></tr></table></td></tr>
	<tr><td><img src='../i/spacer.gif' height='5' /></td></tr>
	
	<tr>
		<td></td>
		<td width='650'><table border='0'>
			<tr><td><img src='../i/spacer.gif' width='22' /></td>
				<td class='desc_text'>
					EGI Central Repository (CR) provides a simple, all-in-one online portal solution for accessing
					and sharing files between friends, coworkers and project team members.
				</td>
			</tr>
			<tr><td><img src='../i/spacer.gif' height='2' /></td></tr>
			<tr><td></td>
				<td class='desc_text'>
					CR provides two major collaborative data repository functions.
					<ul type='square'>
					<li><b>CR Project Space</b> has an easy-to-use
					security framework for you to securely share files with others on a
					project-by-project basis.</li>
					<li><b>CR File Repository</b> enables you and your trusted contacts to
					upload and share selected files and folders of your local machines.</li>
					</ul>
					You can
					also silently synchronize or backup your local folders to the Central Repository
					such that you can always access these files securely.
				</td>
			</tr>
			<tr><td><img src='../i/spacer.gif' height='2' /></td></tr>
			<tr><td></td>
				<td class='desc_text'>
					CR has a Search Engine for you
					to quickly locate your needed knowledge from thousands of uploaded files.
					And you can access these files
					anywhere, anytime using your secured username and password
					as long as you have access to a Web browser connected to the Internet.
				</td>
			</tr>
			<tr><td><img src='../i/spacer.gif' height='2' /></td></tr>
			<tr><td></td>
				<td class='desc_text'>
					CR not only gives you the peace of mind in case of file loss, but it is a
					practical knowledgebase tool enabling you and your team members to access,
					search and share projects and files on your distributed machines.
				</td>
			</tr>
		</table>
		</td>
	</tr>
		
	<tr><td><img src='../i/spacer.gif' height='20' /></td></tr>
		
	<tr><td></td><td><table>
		<tr><td valign='middle'><img src='../i/spacer.gif' width='30'>
		<img src='../i/download.jpg' border='0' /></td>
		<td><input type='submit' value='DOWNLOAD NOW' onclick='download()'></td>
		</tr></table>
	</td></tr>
		
	<tr><td><img src='../i/spacer.gif' height='30' /></td></tr>

	<tr>
		<td width="15"><img src='../i/spacer.gif' width='15' height='1' /></td>
		<td class="headlnk_green">Features</td>
	</tr>
		
	<tr><td><img src='../i/spacer.gif' height='3' /></td></tr>
	<tr><td></td><td><table cellspacing='0' cellpadding='0'><tr><td bgcolor="#40a040"><img src="../i/spacer.gif" height="2" width='650' border="0"></td>
		<td><img src='../i/spacer.gif' height='1' width='30' /></td></tr></table></td></tr>
	<tr><td><img src='../i/spacer.gif' height='8' /></td></tr>
	
	<tr>
		<td></td>
		<td><table><tr><td><img src='../i/spacer.gif' width='22' height='1' /></td>
			<td>
			<table cellpadding='3' border='1' bgcolor='#efefef'>
				<tr>
					<td><img src='../i/spacer.gif' width='10' /></td>
					<td class='feature' width='150'><b>License:</b></td>
					<td class='feature' width='380'>Free for Standard service; $9.95 to upgrade (<a href='upgrade.jsp'>Buy it now</a>)</td>
				</tr>
				<tr>
					<td><img src='../i/spacer.gif' width='10' /></td>
					<td class='feature' width='150'><b>System requirements:</b></td>
					<td class='feature' width='380'>Windows 2000/XP/Vista/7.</td>
				</tr>
				<tr>
					<td><img src='../i/spacer.gif' width='10' /></td>
					<td class='feature' width='150' valign='top'><b>Other requirements:</b></td>
					<td class='feature' width='380'>You need a CR user account to use
					CR RemoteAccess and RemoteSync (<a href='upgrade.jsp'>Register now</a>)</td>
				</tr>
				<tr>
					<td><img src='../i/spacer.gif' width='10' /></td>
					<td class='feature' width='150'><b>Limitations:</b></td>
					<td class='feature' width='380'>No limitation</td>
				</tr>
				<tr>
					<td><img src='../i/spacer.gif' width='10' /></td>
					<td class='feature' width='150'><b>Date added:</b></td>
					<td class='feature' width='380'>November 18, 2008</td>
				</tr>
				<tr>
					<td><img src='../i/spacer.gif' width='10' /></td>
					<td class='feature' width='150'><b>Version:</b></td>
					<td class='feature' width='380'>1.7.011</td>
				</tr>
			</table>
			</td>
			</tr></table>
		</td>
	</tr>
		
	<tr><td><img src='../i/spacer.gif' height='40' /></td></tr>
	
	<tr>
		<td></td>
		<td class="headlnk_green">
			Download CR RemoteAccess and RemoteSync enables you to:
		</td>
	</tr>
		
	<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>
			
	<tr><td></td><td>
		<table>
			<tr><td class='headlnk_blue'><img src='../i/spacer.gif' width='20'><span class='headlnk_pink'> &raquo;</span>
				Access files on your desktop and laptop computers from anywhere, anytime
			</td></tr>
			<tr><td class='headlnk_blue'><img src='../i/spacer.gif' width='20'><span class='headlnk_pink'> &raquo;</span>
				Share files securely with friends and coworkers
			</td></tr>
			<tr><td class='headlnk_blue'><img src='../i/spacer.gif' width='20'><span class='headlnk_pink'> &raquo;</span>
				Remote backup machines and synchronize data between them
			</td></tr>
		</table>
		</td></tr>
		
		<tr><td><img src='../i/spacer.gif' height='20' /></td></tr>
		
		<tr><td></td><td><table>
			<tr><td><img src='../i/spacer.gif' width='30'>
			<img src='../i/download.jpg' border='0' /></td>
			<td><input type='submit' value='DOWNLOAD NOW' onclick='download()'></td>
			</tr></table>
	</td></tr>
		
	<tr><td><a name='instruction'><img src='../i/spacer.gif' height='40' /></a></td></tr>
	
	<tr>
		<td></td>
		<td class="headlnk_green">
			Instructions
		</td>
	</tr>
		
	<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>
		
	<tr><td><img src='../i/spacer.gif' height='3' /></td></tr>
	<tr><td></td><td><table cellspacing='0' cellpadding='0'><tr><td bgcolor="#40a040"><img src="../i/spacer.gif" height="2" width='650' border="0"></td>
		<td><img src='../i/spacer.gif' height='1' width='30' /></td></tr></table></td></tr>
	<tr><td><img src='../i/spacer.gif' height='5' /></td></tr>
		
	<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>
	
	<tr><td></td><td class='headlnk_pink'>* You now may just run CR RemoteAccess without downloading.</td></tr>
	
	<tr><td><img src='../i/spacer.gif' height='5' /></td></tr>
	
	<tr><td></td><td class='headlnk_blue'>Installing CR RemoteAccess</td></tr>
	<tr><td><img src='../i/spacer.gif' height='5' /></td></tr>
	<tr>
		<td></td>
		<td class='desc_text' width='650'>
			<ol>
				<li>After release 1.6, you may run CR RemoteAccess without downloading
				  or installing the application.  To do that click
				  <a href='../file/common/RemoteAccess.jar'>RemoteAccess</a> and choose Open.</li>
				<li>However, if you want to use RemoteSync as a Windows service to
				  automatically backup and synchronize selected files and folders, then
				  you must download the ZIP file and follow the instructions below.</li>
				<li>If you choose to download RemoteAccess and RemoteSync on your computer,
				  select SAVE after you click the DOWNLOAD NOW Button above and save the
				  WinZIP file (RemoteSync.zip) onto your local machine.</li>
				<li>Unzip the saved RemoteSync.zip anywhere you want to place it, or you
				  may put it on C:\</li>
				<li>The following is the folder structure after unzip:</li>
			</ol>
				<pre>
          (wherever installed)/RemoteSync
                                    +--- bin
                                    +--- classes
                                    +--- logs
				</pre>
			<ol start=6>
				<li>RemoteAccess is located in the <i>bin</i> folder.  Follow the below
				  section on <i>Running CR RemoteAccess</i> to run the program.</li>
				<li>NOTE: to run RemoteSync as a Windows service to automatically
				  and quietly backup your local folders/files, you must first run
				  RemoteAccess and select the folders and files to upload for
				  Remote Backup.</li>
				<li>To setup RemoteSync as an automated service, follow the instruction
				  in the below section on <i>Setup CR RemoteSync as Windows Service</i></li>
			</ol>
		</td>
	</tr>
	
	<tr><td></td><td class='headlnk_blue'>Running CR RemoteAccess</td></tr>
	<tr><td><img src='../i/spacer.gif' height='5' /></td></tr>
	<tr>
		<td></td>
		<td class='desc_text' width='650'>
			<ol>
				<li>You need Java SE 1.6 Runtime (free from Javasoft) to run RemoteAccess
				  and RemoteSync. <a href='http://www.java.com/en/download/manual.jsp'>
				  Click here to verify or download Java SE.</a></li>
				<li>Simply double-click on RemoteAccess.jar to start the Windows application.</li>
				<li>Enter your <b>CR Username</b> and <b>Password</b>
				  (<u>Note</u>: you need a CR user account in order to use RemoteAccess
				  or RemoteSync).  If you don't yet have a CR user account,
				  click <a href='<%=NODE%>/info/upgrade.jsp'>Register for CR</a>
				  to choose a service account before continuing.</li>
				<li>Click either the <b>Upload</b> or <b>Download</b> tab
				  to perform the corresponding actions.</li>
				<li>To upload files from your desktop to the CR online file repository,
				  click the <b>Upload</b> tab.</li>
				<li>Select an Upload Option.  You may either upload to the CR project/task
				  areas, or uploading for remote backup of your local machine.</li>
				<li>Use the left-hand-side panel to specify the folders you want to upload.
				  Press down the SHIFT key when checking or unchecking the checkbox
				  will select/deselect all the subfolders.</li>
				<li>When you are done specifying the upload folders,
				  click <b>Save Change</b>.</li>
				<li>Click the <b>Upload</b> button to start the upload on demand.
				  Upload will only affect the modified files since your last upload action.</li>
				<li>When upload is done, goto <a href='<%=NODE%>'>cr.egiomm.com</a>
				  and logon to CR online to see your files.</li>
				<li>To download files from CR online File Repository to your local machine,
				  click the <b>Download</b> tab in RemoteAccess.</li>
				<li>Use the left-hand-side panel to specify the files you want to download.</li>
				<li>Use the right-hand-side panel to specify the destination folder
				  you want to place the downloaded files.</li>
				<li>Click the <b>Download</b> button to start the download.</li>
			</ol>
		</td>
	</tr>
	
	<tr><td><img src='../i/spacer.gif' height='5' /></td></tr>
	
	<tr><td></td><td class='headlnk_blue'>Setup CR RemoteSync as Windows Service</td></tr>
	<tr><td><img src='../i/spacer.gif' height='5' /></td></tr>
	<tr>
		<td></td>
		<td class='desc_text' width='650'>
			<ol>
				<li>Download and install RemoteAccess as describe above (see above
				Section on <i>Installing CR RemoteAccess</i>).</li>
				<li>You must have a CR user account to run RemoteSync or RemoteAccess.
				  Goto the CR website <a href='http://cr.egiomm.com'>cr.egiomm.com</a>
				  to register a free user account.</li>
				<li>You must first run RemoteAccess to select the folders/files
				  on your local machine that you want to Remote Backup so that
				  RemoteSync will automatically backup these files.</li>
				<li>To setup RemoteSync as a Windows service, go to the <i>bin</i> folder
				  shown above and use DOS command prompt to run <i>setup.bat</i>.  This will
				  install and start RemoteSync as a background backup service.</li>
			</ol>
		</td>
	</tr>

	<tr><td><img src='../i/spacer.gif' height='30' /></td></tr>

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
		<a href="faq.jsp" class="listlink">Help</a>
<%if (isLogin){%>
		&nbsp;|&nbsp;
		<a href="../logout.jsp" class="listlink">Logout</a>
<%}%>
		&nbsp;|&nbsp;
		<a href="#top" class="listlink">Back to top</a></td>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td width="780" height="32" align="center" valign="middle"><font size="1" face="Arial, Helvetica, sans-serif" color="#999999" class="8ptype">Copyright
      &copy; 2005-2010, EGI Technologies</font></td>
    <td height="32">&nbsp;</td>
  </tr>
</table>
<!-- END FOOTER TABLE -->

<form name='downloadForm' method='post' action='post_download.jsp'>
</form>


<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

