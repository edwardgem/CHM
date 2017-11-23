<%
////////////////////////////////////////////////////
//	Copyright (c) 2008, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	faq.jsp
//	Author:	ECC
//	Date:	09/11/08
//	Description:
//		FAQ page for CR.
//	Modification:
//
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "util.*" %>
<%@ page import = "oct.codegen.userinfo" %>
<%
	String COMPANY		= Util.getPropKey("pst", "COMPANY_NAME");
	String NODE			= Util.getPropKey("pst", "PRM_HOST");
	String ADMIN_MAIL	= Util.getPropKey("pst", "FROM");

	boolean isLogin = false;
	String home = request.getParameter("home");
	if (home == null)
	{
		home = "../ep/ep_home.jsp";
		isLogin = true;
	}
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">

<title>
	CR FAQ
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

	&nbsp;&nbsp; FAQ

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
					<td width="20" height="14"><img src="../i/nav_arrow.gif" width="20" height="14" border="0"></td>
					<td><a href="#" onClick="return false;" class="subnav"><u>FAQ</u></a></td>
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

<!-- CONTENT -->
<table>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_head"><br>
		<br>

<span class="homenewsheader">Frequently Asked Questions:</span><br>
<p>
<table>
	<tr>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="#general">General</a></td>
	</tr>

	<tr>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="#project">Project Space</a></td>
	</tr>

	<tr>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="#repository">File Repository & Remote Backup</a></td>
	</tr>

	<tr>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="#search">Search Engine</a></td>
	</tr>

	<tr>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="#alert">Notification Message</a></td>
	</tr>

</table>
</p>
</span>

<table border="0" width="700" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>

<span class="plaintext">

<!-- GENERAL -->
<p>
<a name="general" class="listlink">GENERAL QUESTIONS</a>

<ul type="square">
<li><b>What is CR?</b>
<br>CR, or Central Repository, is an online facility for users to access and share files anywhere, anytime.
CR provides you with three main functions.
<br><br>
<ul>
	<li><u>Project Space</u> - allows you to organize, classify and share files between project team members.
	<li><u>File Repository</u> - creates a knowledgebase portal of files contributed by trusted contacts.
	<li><u>Remote Backup</u> - you may recover your critical files from CR in case if your computers become inaccessible.
</ul>
<br>
You apply CR to create Project Spaces to store files according to your desired project structure, customer cases,
organization infrastructure, subject matters, or any other ways that reflect how you would like to categorize
your information.  A Google-like search engine works continually on top of CR to return information to you
either on demand or around-the-clock to discover the latest matching information for you.
<br><br>
In addition to the Project Space, CR also enables you to handily upload folders and files from local machines
to the remote CR servers.  With a Web browser interface, you may access these files from
anywhere as long as there is Internet access.  CR has a sophisticated and easy-to-use security model that
allows you to securely share files with friends, coworkers and between multiple offices.  These upload folders
also provide remote backup functions.  You no longer have to concern about losing data or failing to find a file
when it is needed.

<br><br>
<li><b>How do I get a user account on CR?</b>
<br>
Simply go to <a href='http://cr.egiomm.com'>Central Repository Home Page</a> and click
<a href='http://cr.egiomm.com/info/upgrade.jsp'>Create a New User Account</a>.  With a few mouse clicks and
you are ready to start using the CR service to put your local data for secure remote access.
A Standard CR membership is totally FREE!
<br><br>
You may also add your entire group or company to CR by upgrading to the <%=userinfo.LEVEL_4%> membership.  To get more
information and compare between different levels of memberships, please go to
<a href='http://cr.egiomm.com/info/upgrade.jsp'>CR Memberships</a>

<br><br>

<li><b>What do I need to have in order to use CR?</b>
<br>CR is a Web browser-based service; all you need is a Web browser (IE6+ or Firefox) and access to the Internet in
order to use CR.  As CR is an online secured communication network and
knowledgebase, you would need to establish a user account on CR to gain access.
You must also have a valid email address as all of the alert notification
and CR communications are done through email.

</ul>
</p>

<table width="700"><tr><td align="right"><a href="#" class="listlink">BACK TO TOP</a></td></tr></table>
<table border="0" width="700" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>


<p>
<!-- PROJECT -->
<a name="project" class="listlink">ABOUT PROJECT SPACE</a>

<ul type="square">
<li><b>What is a Project Space in CR?</b>
<br>A Project Space is an online storage space organized in the form of a project tree.  Unlike a free-form
directory tree, once you create a Project Space, you may save that structure in the CR template library so that
when you start another project of a similar type, you can recall the same structure from the library and
then customize it to suit your needs.
<br><br>
Team members work collaborately on projects.  In the life-time of a project, you and other authorized team members
are free to upload files to different parts (task nodes) of the project tree.  You may set up the attributes of
different tasks such that when users upload files to certain task nodes, an email notification message is automatically
sent to relevant team members.

<br><br>
<li><b>What kind of projects are appropriate in using CR to store files?</b>
<br>You may work on any kind of projects in CR, either by yourself or coordinating a joint effort
with a team of people.  CR has a project space template library which includes various types of projects
such as Administrative, Customer Service, Financial, Marketing & Sales, and Product Management.  They
are not exhausive and are there for you to customize.  You may
also create and store your project space templates private to you and your team members.

<br><br>
<li><b>Can other people see my Project Space?</b>
<br>When you create a Project Space you may specify whether a project is a <i><u>private</u></i>,
<i><u>public</u></i> project.
A private project will only been seen by the project team - people who you invite to be on the team.
If you are the only person on the
project team, then you are the only person who will see the Project Space.  A public project will be
seen everyone.  You create a Public Project and store files there if you want to distribute information
to other people such that they will be able to search and find your information.


</ul>
</p>

<table width="700"><tr><td align="right"><a href="#" class="listlink">BACK TO TOP</a></td></tr></table>
<table border="0" width="700" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>


<p>
<!-- FILE REPOSITORY & REMOTE BACKUP -->
<a name="repository" class="listlink">ABOUT FILE REPOSITORY & REMOTE BACKUP</a>

<ul type="square">
<li><b>What is the difference betwen a file repository and project space?</b>
<br>A Project Space is an online storage space organized in the form of a project tree.  Authorized users upload
and share files in the Project Space.  Files are contributed by team members only and are classified and organized to
facilitate the collaboration of the project team.  Project space has a life span, it is active when the project
is active, and can be archived as the project is completed.
<br><br>
File repository is a central (usually remote) server allowing users to contribue (upload) their files to
create a common knowledgebase.  Note that your files are never shared in the public, only trusted contacts
that you specify on a file-by-file basis would have access to your files.
<br><br>
Another function
of file repository is for file backup.  It is a handy way to keep all files - past and present - in
a single location.  In an office environment, all employees may "dump" their files into the file repository.
File repository doesn't have a lifecycle.  It is a knowledgebase that just keep growing.  And with CR Search Engine,
you can find your needed information in seconds even when you are dealing with hundreds of thousands of files in
the repository.
<br><br>

<li><b>How is a file repository solution different from a remote backup facility?</b>
<br>Remote backup is a remote facility for a user to periodically upload critical files to
avoid data loss.  In case of a hardware failure or
other types of disasters that result in loss of data, the user may go to the remote backup facility to retrieve
the critical files back.  The primary function of remote backup is to allow a user to recover the loss data.  It
is not for sharing of information between team members or to build up a knowledgebase for a company.
<br><br>
File repository naturally provides the remote backup functions.  But it is not practical to simply use
a remote backup solution as a file repository, which is a technological solution that requires a collaborative
environment, a security model, a search engine, a scaleable solution and many others.

<br><br>
<li><b>How does CR File Repository work?</b>
<br>When you download the CR Remote Access module onto your laptop or desktop computer, you may run it
to specify what are the folders and files you want CR to upload to the File Repository.  CR remembers
these critical folders and you may run CR Remote Access to upload the latest change to the CR File Repository.
<br><br>
Now when you logon to your CR account with a Web browser, you will see those folders and files you uploaded
under your machine name.  You may decide to share any of these files with your friends, coworkers or
team members by just entering their email addresses.  CR will send them Email and provide them with a password
and a link to access the file.
<br><br>
The search engine also work on top of the File Repository just like in the Project Space.  People who has
authority to share your files will be able to search and access the files.

<br><br>
<li><b>Can I move files from my File Repository to my Project Space?</b>
<br>This is a planned feature for a near-future release.
The current version does not allow moving files between the two areas.


</ul>
</p>

<table width="700"><tr><td align="right"><a href="#" class="listlink">BACK TO TOP</a></td></tr></table>
<table border="0" width="700" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>

<p>
<!-- SEARCH ENGINE -->
<a name="search" class="listlink">ABOUT CR SEARCH ENGINE</a>

<ul type="square">
<li><b>Why do we need a search engine in CR?</b>
<br>Users working as individuals and teams store valuable data in CR.  Over time a large amount of useful
information would be available for users.  The problem is to find the relevant files when you need them.
CR search engine allows users to search by matching contents and file names, making it easy for users
to look up information even from hundreds of thousands of files in the repository.


<br><br>
<li><b>How do I issue a search in CR?</b>
<br>On almost every CR page there is a search box on the top right-hand corner.  Simply type in a string
that matches what you are looking for, CR search engine will do a partial match for you on both
filenames and contents.

<br><br>
<li><b>How do I use the Advanced Search capability in CR Search Engine?</b>
<br>You may use the Advance Search funtion by clicking on the magnify glass icon next to the search box.
Alternatively, after issuing a search, when you are on the search result page, click the "Show Filter" link,
which is located right above the word "Keyword:", this would open up a panel allowing you to provide information
for an advanced search.

<br><br>
<li><b>What is an Active Query (in advanced search)?</b>
<br>Usually when you issue a search, the search engine finds the result and come back to you, and that is the
end of that search session.  With Active Query, you specify a search clause, e.g. "2005 financial report" and
specify how frequently do you want CR Search Engine to look up the information for you (Daily, 3 times day or
hourly).  Once you submit the query, search engine will continually look for the latest information that
satisfies your search criteria and return only the newest result to you.  The active query continue to live
until you tell it to stop.


</ul>
</p>

<table width="700"><tr><td align="right"><a href="#" class="listlink">BACK TO TOP</a></td></tr></table>
<table border="0" width="700" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>


<p>
<!-- ALERT -->
<a name="alert" class="listlink">ABOUT NOTIFICATION MESSAGE</a>

<ul type="square">
<li><b>What are Notification Messages in CR</b>
<br>Notification messages in CR are email messages that sent to users when certain signficant events happened.
Typically a Project Space or task owner may set up the option to trigger notification message when user
upload files into the task area within the Project Space. 

<br><br>
<li><b>How do I trigger an alert message to people?</b>
<br>If you own a Project Space or a Task within a Project Space, you may set up the option of that task (or of
the whole project) to automatically send out a notification whenever user upload files to that area.
<br><br>

In addition, you can send Email message to people whenever you see an email icon
(<img src="../i/eml.gif">).
To send an alert, click the icon and follow the instructions.


</ul>
</p>

<table width="700"><tr><td align="right"><a href="#" class="listlink">BACK TO TOP</a></td></tr></table>
<table border="0" width="700" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>

<p class="plaintext">
For any other questions, please e-mail
<a href="mailto:<%=ADMIN_MAIL%>">The CR Team</a>
</p>

</span>
</td></tr>
<tr><td>&nbsp;</td><tr>
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
		<a href="#" onclick="return false;" class="listlink">Help</a>
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
      &copy; 2005-2008, EGI Technologies</font></td>
    <td height="32">&nbsp;</td>
  </tr>
</table>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

