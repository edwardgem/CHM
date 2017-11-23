<%
////////////////////////////////////////////////////
//	Copyright (c) 2008, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	faq.jsp
//	Author:	ECC
//	Date:	09/11/08
//	Description:
//		FAQ page for EGI Home Page.
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
		home = "http://www.egiomm.com/";
		isLogin = true;
	}
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>

<title>
	EGI Collabris FAQ
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

	&nbsp;&nbsp; FAQ on Collabris

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
	<td><a class="listlink" href="#bd">Data Unification for Big Data</a></td>
	</tr>

	<tr>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="#ml">Machine Learning in Collabris</a></td>
	</tr>

	<tr>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="#genApp">General Collabris Application</a></td>
	</tr>

	<tr>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="#healthApp">Healthcare Collabris Application</a></td>
	</tr>

	<tr>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="#semiconApp">Semiconductor Collabris Application</a></td>
	</tr>

</table>
</p>
</span>

<table border="0" width="95%" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>

<span class="plaintext">

<!-- GENERAL -->
<p>
<a name="general" class="listlink">GENERAL QUESTIONS</a>

<ul type="square">
<li><b>What is Collabris?</b>
<br>Collabris is a Cloud platform for intelligent connections between people and knowledge.
Its purpose is to discover knowledge through Machine Learning in a Big Data store. By using
EGI's proprietary Data Unification technology (OMM), Collabris enables an enterprise to quickly
establish her own Big Data Center on the Cloud with existing databases and a Big Data space
for capturing new data streams such as those from Mobile App, Web and IoT applications.  Once the
Big Data store is set up, users may apply Machine Learning (ML) algorithms to analyze their
integrated data.  Collabris will also run general ML algorithms to establish intelligent connections
between people and knowledge for the company, resulting in a more intelligent team collaborating
together to meet common business objectives.


<br><br>
<li><b>How do I get a user account on Collabris?</b>
<br>
Simply go to the <a href='http://collabris.egiomm.com'>Collabris Home Page</a> and click
<a href='http://collabris.egiomm.com/info/upgrade.jsp'>Create a New User Account</a>.  With a few mouse clicks and
you are ready to start using the Collabris service to put your local data for secure remote access.
A Standard, individual Collabris membership is totally FREE!
<br><br>
You may also add your entire group or company to Collabris by upgrading to the <%=userinfo.LEVEL_4%> membership.  To get more
information and compare between different levels of memberships, please go to
<a href='http://collabris.egiomm.com/info/upgrade.jsp'>Collabris Memberships</a>

<br><br>

<li><b>What do I need to have in order to use Collabris?</b>
<br>Collabris is a Web browser and Mobile-based SaaS (Software-as-a-Service);
all you need is a Web browser (IE7+ or Firefox) and/or Android Phone or iPhone
and access to the Internet/4G in
order to use Collabris.  As Collabris is an online secured communication network and
knowledgebase, you would need to establish a user account on Collabris to gain access.
You must also have a valid email address and optionally a smart phone
as all of the alert notifications
and Collabris communications are done through email and/or mobile App.

</ul>
</p>

<table width="95%"><tr><td align="right"><a href="#" class="listlink">BACK TO TOP</a></td></tr></table>
<table border="0" width="95%" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>


<p>
<!-- Big Data -->
<a name="bd" class="listlink">ABOUT DATA UNIFICATION FOR BIG DATA</a>

<ul type="square">
<li><b>What is Big Data to Collabris?</b>
<br>Collabris considers Big Data to be a rapidly changing database environment
that contains multiple data models from potentially various data sources.
These data models are volatile in nature in that there can be
unannounced changes to the existing models and newer models may be added to the Big Data store
at any time. Much of the data inserted into the Big Data store are Write-Once-Read-Many (WORM)
data with frequent read accesses by users and by software robots in performing Machine Learning
tasks.  The complex, numerous and volatile data models, high number and constantly growing
data sources, along with the high insertion rate of data tuples make it impossible for
traditional database technology to manage Big Data.  Collabris is an ideal solution
to provide a flexible model and changing environment to manage Big Data.

<br><br>
<li><b>What is the Data Unification technology in Collabris?</b>
<br>The Data Unification technology in Collabris is called OMM (Object Modeling and Management).
It is EGI's patented technology to bring together different data models without performing
traditional data migration in order to unify the data into a Big Data store.
OMM combines an Object-Oriented model with ER (Entity Relationship) Diagram to abstract both data definition and
relationship management.  As such when newer data models are added to the Big Data store,
OMM is able to wrap around the data model such that the reference model of the new data
source appears to be the same as the rest of the data in the store.  By applying Unsupervised
ML, Collabris will further discover the characteristics of data and in turn establish
linkages between different classes of objects from different data sources.


</ul>
</p>

<table width="95%"><tr><td align="right"><a href="#" class="listlink">BACK TO TOP</a></td></tr></table>
<table border="0" width="95%" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>


<p>
<!-- FILE REPOSITORY & REMOTE BACKUP -->
<a name="ml" class="listlink">ABOUT MACHINE LEARNING IN COLLABRIS</a>

<ul type="square">
<li><b>What kind of Machine Learning does Collabris perform?</b>
<br>Collabris uses Machine Learning (ML) to achieve intelligent connections between people
and knowledge.  With the intrinsic characteristics of the OMM model, Collabris is able to
establish type connections between different classes of objects.  Thus blogs, chats, files,
meeting records, to-do items, news items, staff, partners, customers, existing active transactional
databases, data-warehouse, Mobile App data streams, Web applications and Fit Bits and others are all analyzed
and connected based on their attributes and type definitions in OMM.

<br><br>
Collabris engages NLP (Natural Language Processing) algorithms to tokenize
and find collocations (common ngrams) of data to create linkage
between artifacts in real time.  Hence recommending newer knowledge to users while they are
interacting with Collabris.

<br><br>
With Unsupervised Learning and by clustering the data into groups and analyzing the geometry between data groups, Collabris
is able to establish connections between various data groups that represent newer understandings
of data.

<br><br>
Users may use existing domain specific ML algorithms on the Collabris platform to analyze their
data to discover newer knowledge and observations that are not known before.
<br><br>



</ul>
</p>

<table width="95%"><tr><td align="right"><a href="#" class="listlink">BACK TO TOP</a></td></tr></table>
<table border="0" width="95%" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>

<p>
<!-- SEARCH ENGINE -->
<a name="genApp" class="listlink">ABOUT GENERAL COLLABRIS APPLICATIONS</a>

<ul type="square">
<li><b>Why do we need Machine Learning in Collabris?</b>
<br>Today's Unified Communication software in the market enables people and
knowledge (files, blogs, etc.) to be connected by simple linkages, such as people in the
same team or there is a match on the keywords.  Such mechanical ways of establishing
connections cause disconnects and breakdowns between people and information.  And much
of the information and knowledge accumulated in this environment are being burried and
wasted.

<br><br>
Collabris
uses Artificial Intelligence to discover relationships between people and knowledge
resulting in a much more intelligent and dynamic environment of bringing the pieces together
for better decision-making.  Furthermore, contacts, relationships and artifacts are
made available for users to accomplish their goals at hand much more efficiently.


<br><br>
<li><b>What can my company do with Collabris?</b>
<br>With Collabris your company immediately deploys your own Big Data Center on the Cloud
without the heavy investment of establishing the solution stack involving both
hardware and software.  Your company staff will start contributing to the Big Data store
simply by using Collabris to interact with one another and manage their day-to-day tasks.

<br><br>
Once your Big Data store reaches a certain critical size, you may start performing ML to
discover newer knowledge and wisdom that would impact your business decisions.

<br><br>
<li><b>What do ML Robots do in Collabris?</b>
<br>Usually when performing ML, whether in linear regression or in Artificial Neural Network
(Deep Learning), data scientists apply a certain learning algorithm on a set of learning data
to land on a hypothesis, which is an activation function for prediction. Upcoming data are fed to the
hypothesis and give you the result. With Collabris, since the Big Data is growing continually
both in size and in structure, it is necessary that we enable software robots to be running
continually and take in newer learning data as they appear.  This will constantly mode the
hypothesis to improve its accuracy (or intelligence) and provide users with newly discovered
knowledge.


</ul>
</p>

<table width="95%"><tr><td align="right"><a href="#" class="listlink">BACK TO TOP</a></td></tr></table>
<table border="0" width="95%" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>


<p>
<!-- ALERT -->
<a name="healthApp" class="listlink">ABOUT HEALTHCARE COLLABRIS APPLICATIONS</a>

<ul type="square">
<li><b>How do doctors use Collabris?</b>
<br>On the Collabris platform, doctors in various specialty departments coordinate their
activities and work with various communication tools available for them. These include chat,
blogs, e-Calendar, to-do items, meeting records, file uploads, and others.  In addition,
there are hospital specific applications running on the Collabris platform that they use
to achieve their work objectives by collaborating with other doctors, nurses, lab technicians
and even patients.

<br><br>
While doctors are using Collabris, the system will quietly collect access behavior patterns
and content from users to establish connections between people and knowledge. In time newer
knowledge and connections will be introduced to them to assist their work.

<br><br>
<li><b>Do doctors actively query Collabris for knowledge discovery?</b>
<br>Since Collabris includes existing databases such as the Clinical Data Repository (CDR) of
the hospital or the Hospital Information System (HIS), a doctor may query Collabris for the
corresponding information.  For instance, what lab tests have been prescribed to his patients and
what are the results? Among the patients who have a certain ICD code and had taken undergone
operation? Who are my in-patients to be discharged in the next 24 hours?

<br><br>
In future releases, with NLP and ML supports, we will enable doctors to issue more complicated
queries in voice commands.

<br><br>
<li><b>Can Collabris support Precision Medicine with Genome data included as a data source?</b>
<br>The goal of Collabris is to support all kinds of data model in the Big Data Center. For
Collabris, to integrate different data sources might not be a challenge but users must first
understand the semantics of such integration to make a relevant application.
For Precision Medicine, one of the common practice is to be able to focus on certain
genes and perform matching of a patient's genome sequence against the genomic data center
in order to identify similar patient group for effective treatment methods or drugs
for the patient.  In the scheme of a Global Healthcare Big Data Center (GHBD),
the approach therefore is not to integrate the CDR with the genome data but
to be able to incorporate the result of such match into the total knowledge.
Since Collabris is an open architecture to incorporate different libraries
and data sources, it is open to exchange data with an external library of a Genomic Data Center
that aims at genome matching, and include the result into the Precision Medicine query.

<br><br>
EGI has developed cohort programs with biomedical researchers to focus on certain clinical
research topics related to particular disease groups.  Working with the researchers we
identify CDR attributes and genes that might give an impact to the outcome of treatments
of a particular disease.  In addition, by applying ANN and Deep Learning, we hope to feed large
dimensions of data back to the network to learn potential combinations of treatments that
might result in newer ideas of treatments.  We recognize this work requires a very large
amount of data to obtain meaningful result. The expansion of virtual GHBD Center is design
in particular to address this issue.

<br><br>
<li><b>Since a patient may visit multiple hospitals with a different UPID,
will Collabris miss some useful information that is not in a hospital's Big Data store?</b>
<br>Obviously searches to a Big Data store is limited to the data available at hand.
For instance, a patient may have an experience in a hospital of using a certain drug, but when
he comes to another hospital, this experience would not be captured in the database of this
second hospital (assuming the first hospital neither has a Big Data store nor sharing
its data with the second hospital).  However, note that Collabris is not only
interested in reviewing knowledge
of this one patient; it is to review this patient in the backdrop of millions of patients.
As such Big Data and ML are not relying on the information of this one patient to
learn and respond to queries, it is looking at all the available patient data and
recommend a treatment method.  As such, the above missing data will become less important.

</ul>

</ul>
</p>

<table width="95%"><tr><td align="right"><a href="#" class="listlink">BACK TO TOP</a></td></tr></table>
<table border="0" width="95%" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>


<p>
<!-- ALERT -->
<a name="semiconApp" class="listlink">ABOUT SEMICONDUCTOR COLLABRIS APPLICATIONS</a>

<ul type="square">
<li><b>How is a semiconductor company being benefited by Collabris?</b>
<br>With Intelligent Connectivity, employees, partners, vendors, customers are all connected
seamlessly with one another in achieving their common business objectives.  This is done
through an intelligent Unified Communication platform with all sorts of tools such as chats, blogs,
file sharing, e-Calendar, meeting record management, to-do's, task management, team
management, etc. And when users are using the platform to coordinate their interactions
or to organize their work tasks, Collabris will collect information and access patterns of
the users, and to recommend newer information and contacts to them.

<br><br>
Domain specific and company specific intelligent applications can be deployed on Collabris
to support deeper and closer connections between people and knowledge. Newer applications
such as Mobile Apps and IoT applications can be added to collect more data for the company. All these
data are no longer silos but are integrated into the Big Data store for future analysis.

<br><br>
When the company's Big Data Center has reached to a certain critical size, users may
perform ML to discover knowledge and wisdom that would impact their way of doing business
for improved results.


</ul>
</p>

<table width="95%"><tr><td align="right"><a href="#" class="listlink">BACK TO TOP</a></td></tr></table>
<table border="0" width="95%" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>

<p class="plaintext">
For any other questions, please e-mail
<a href="mailto:<%=ADMIN_MAIL%>">The Collabris Team</a>
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
      &copy; 2012-2016, EGI Technologies</font></td>
    <td height="32">&nbsp;</td>
  </tr>
</table>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

