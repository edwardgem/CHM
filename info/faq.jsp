<%
////////////////////////////////////////////////////
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	faq.jsp
//	Author:	ECC
//	Date:	09/07/06
//	Description:
//		FAQ page for CPM.  This is the top FAQ page which will redirect to other FAQ if needed.
//	Modification:
//
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "util.*" %>

<%
	if (Prm.isCR())
	{
		response.sendRedirect("faq_cr.jsp");
		return;
	}
	else if (Prm.isMeetWE())
	{
		response.sendRedirect("faq_omf.jsp");
		return;
	}
	else if (Prm.isPRM()) {
		// do nothing
		if (request.getParameter("Hm") != null) {
			response.sendRedirect("faq_home.jsp");
			return;
		}
	}

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
	<%=Prm.getAppTitle()%> FAQ
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

	&nbsp;&nbsp;FAQ

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
	<td><a class="listlink" href="#project">Project Management</a></td>
	</tr>

	<tr>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="#worktray">Worktray</a></td>
	</tr>

	<tr>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="#meeting">Meeting Facilitator</a></td>
	</tr>

	<tr>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="#bug">Case Tracker</a></td>
	</tr>

	<tr>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="#town">Company</a></td>
	</tr>

	<tr>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="#weblog">Blogging</a></td>
	</tr>

	<tr>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="#alert">Alert Message</a></td>
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
<li><b>What is CPM?</b>
<br>CPM is an online communication and management platform to support <%=COMPANY%> in the product
development process.  <%=COMPANY%> CPM has evolved into a global community with engineering,
marketing and program management personnel from all over the world.  Users apply different tools
in CPM to collaboratively manage distributive product development projects, track issues, and carry
meetings and online discussions.  Together we are defining our own processes and culture in creating
innovative products for our customers.
<br><br>
CPM uses a modeling technology to capture and refine the way engineers and managers are working together
in solving issues and accomplishing project objectives.  It consists of configurable toolsets to support
project management, issue and action-item tracking, decision and history recording, document management
and meeting facilitation.  It observes the existing methodologies the group uses in managing their
teamworks, such as Email threads, shared network drives, spreadsheet files, conference calls,
online meetings and other desktop applications, and
leverage them with newer and more effective communication paradigms such as blogging and forum discussions,
dynamic role-based matrix organizations, online project workflow processes, knowledge-based
intelligent systems and team formation tools.  The goals is to create an environment that
enables an innovative culture for effective product development management at <%=COMPANY%>.

<br><br>
<li><b>How do I get a user account on CPM?</b>
<br>
If you are a <%=COMPANY%> personnel, you may go to the <a href='<%=NODE%>'>CPM Login Page</a> and click
<b>Register New User</b> to register yourself.  Once your request is processed, CPM will notify you with an email.
<br><br>
You may also be invited by other members CPM to join a <a href="#project">Project</a>.  In this case, CPM will
automatically send you a notification message with a username and password.  You can logon to CPM
by clicking this link: <a href="<%=NODE%>"><%=COMPANY%> CPM</a> and using your username and password.
<br><br>
You may also request for adding your entire group or project team into CPM.  Please contact the
<a href="mailto:<%=ADMIN_MAIL%>">CPM Team</a> for more information.

<!--You may also register yourself to CPM and obtain a password.
You may then logon and create your own <a href="#town">town</a>
and invite others to join your town.-->

<br><br>

<li><b>What do I need to have in order to use <%=COMPANY%> CPM?</b>
<br>CPM is a Web browser-based service; all you need is an access to the Internet and World Wide Web in
order to use <%=COMPANY%> CPM.  As <%=COMPANY%> CPM is a private communication network and
knowledgebase, you would need to establish a user account on CPM to gain access.
You must also have a valid email address as all of the alert notification
and CPM communications are done through email.  If you desire to access <%=COMPANY%> CPM outside of a
<%=COMPANY%> facility, you would also need to have a VPN access.  Please contact the
<a href="mailto:<%=ADMIN_MAIL%>">CPM Team</a> if you need more information.

</ul>
</p>

<table width="700"><tr><td align="right"><a href="#" class="listlink">BACK TO TOP</a></td></tr></table>
<table border="0" width="700" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>


<!-- PROJECT -->
<a name="project" class="listlink">ABOUT PROJECT</a>

<ul type="square">
<li><b>What is a Project in CPM?</b>
<br>A project has a project plan which can be accessed online by all team members.  A project
has a set of objectives and is composed of a number of tasks and sub-tasks arranged in a hierachy (like an inversed tree).  Each task
is a piece of work that has an expected completion date (deadline) and is owned by a person (task owner).  Each
task goes through a lifecycle of <i>New, Open</i> and <i>Completed</i> or <i>Canceled</i>.  A task in its life time may also be
<i>On-hold</i> or <i>Late</i>.  Likewise, the project which owns all its tasks is
going through a lifecycle of <i>New, Open</i>, <i>Completed</i> or <i>Canceled</i> and <i>Closed</i>.  A completed
project will still remain in the database for members to access, while a closed project will
eventually be archived (stored) away.
<br><br>
Team members work collaborately on projects.  In the life-time of a project, users post progress,
ideas, problems, solutions, files and other information to different tasks or to the overall project.
They also track their decisions, action items and issues for the project as a means to strive towards
common project objectives. CPM reminds people
of critical deadlines or events by automatically sending out <a href="#alert">alert notification</a>
to different team members.
<br><br>
Authorized users may create projects within the <a href="#town">Town</a>.  By default the creator of the project is
the Project Coordinator.  S/he may assign another member to coordinate the project and regulate
the <a href='#weblog'>blog postings</a> on the project and tasks.  A Project Coordinator may transfer his/her
responsibility to other project team members by updating the Project Profile.
<br><br>
If you are a project leader and would like to create a project in CPM, please contact the
<a href="mailto:<%=ADMIN_MAIL%>">CPM Team</a>.

<br><br>
<li><b>What kind of projects can I work on in CPM?</b>
<br>You may work on any kind of projects in CPM, either by yourself or coordinating a joint effort
with a team of people.  At this point, <%=COMPANY%> CPM is focused on product development projects.
As a result, we provide you with a number of project templates which serves as initial guidelines
to give you a head start in creating and managing projects.
Project templates are categorized based on different technologies within <%=COMPANY%>: 446,
760, 765, 887, and others.  Within each
category there is a number of sample templates.  Users are encouraged to share their refined
project plans as standard templates by submitting them to the CPM Team.

<br><br>
<li><b>How do I form a Project Team?</b>
<br>When you create a project, you become the Project Coordinator who can perform task management such
as defining a project team, assigning task owners, setting timeline for the project, maintaining a
file repository for the project and others.  To create a project team for a project, update the
Project Profile by selecting people into the project team.  You may then assign team members to take
on different tasks.  A task owner may also transfer his task ownership to other people in
the team.

<br><br>
<li><b>Can I update a project plan after it is created?</b>
<br>A project may be frequently modified during its life time.  CPM provides a graphical user
interface for the Project Coordinator and the team to easily update the project plan.
You may insert, delete or modify any tasks of the project at any time.  CPM keeps the last
2 versions of the project plan in the database for your reference.
<br><br>
When a team member update the project plan, CPM will request for the project coordinator to review
and approve the changes.  Only upon approval by the coordinator will the new project plan be published
and replace the old version.

<br><br>
<li><b>Can other people see my project?</b>
<br>The project coordinator may specify whether a project is a <i><u>private</u></i>,
<i><u>public</u></i> or <i><u>public read-only</u></i> project.
A private project will only been seen by the project team.  If you are the only person on the
project team, then you are the only person who will see the project.  A public project will be
seen by the whole Town.  All the Town People may review and post <a href="#weblog">blogs<a>
of in the project.  Finally, public read-only project allows all Town people to view the posted
blogs but only the project team people may write blogs.

<br><br>
<li><b>Will CPM remind me when my project/task deadline is up?</b>
<br>Yes, although by default CPM will not send remind notification to you about task deadlines.  To
activate the automatic <a href="#alert">alert notification</a> agent on your task, simply click on the task name
on the project plan page and specify when you would like to receive a reminder notification
on that task.

<br><br>
<li><b>Can I attach files to a project and/or its tasks?</b>
<br>You may have file attachment on a project as well as its tasks.  People who has access to the project
may view or download the files.


</ul>
</p>

<table width="700"><tr><td align="right"><a href="#" class="listlink">BACK TO TOP</a></td></tr></table>
<table border="0" width="700" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>

<p>
<!-- WORKTRAY -->
<a name="worktray" class="listlink">ABOUT WORKTRAY</a>

<ul type="square">
<li><b>What is a Worktray in CPM?</b>
<br>Worktray in CPM contains the current active work of a project.  A user's Worktray is usally used to
contain and process his/her active work tasks.  However, through the Worktray, a user may also peek into
other people's active work.  Using the Worktray, a manager may move the work around between team members
and perform load balancing and resource management functions.


<br><br>
<li><b>How to create work tasks and assign them to people's worktray?</b>
<br>When a project is active, based on the project task and project timeline, CPM will automatically
creates tasks for the users.  In addition, users may create Action Items and request other users to perform
certain tasks.  These Action Items may or may not associate to projects.  In any event, users may review,
accept, commit and reject the work requests they received in their Worktray.

<br><br>
With the Worktray, users may easily review how much active works are scheduled for a project and who are
responsible for these work tasks.  It may also be used to track the contractors time and expense in
association to different projects.

</ul>
</p>

<table width="700"><tr><td align="right"><a href="#" class="listlink">BACK TO TOP</a></td></tr></table>
<table border="0" width="700" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>

<p>
<!-- CASE TRACK -->
<a name="bug" class="listlink">ABOUT CASE TRACKER</a>

<ul type="square">
<li><b>What is the function of the CPM Case Tracker (CT)?</b>
<br>In the product development process, the project team must manage the issues and customer cases carefully
in order to deliver a desirable result.  CPM CT has 3 major functions to assist project teams to
achieve this objective.  First, CT manages cases or service requests (SR) throughout their lifecycle:
<blockquote>
	Identify a Case > Define Case > Handle/Resolve Case > Verify Case Completion > Close the Case
</blockquote>
CT applies a workflow process to manage the above lifecycle transition.  Different personnel are
involved to manage different stages of this lifecycle.  Authorized users may assign and
transfer the Case to different team members across multiple functions.  As CPM has a blogging
environment, CT supports users to post blogs associated to the Case.  Users easily share test
reports, observations, and potential resolutions using <a href="#weblog">weblogs</a>.  In
addition, CPM keeps a history of all activities related to the Case.

<br><br>
Secondly, CT connects to other modules of CPM to support the project team in the business
process.  For instance, while using <a href="meeting">Meeting Facilitator</a> to run meetings,
the meeting coordinator may direct participants to review a Case by adding a link to the CT.  Similarly,
users may connect Cases to a specific task
<br><br>
<li><b>What is a Case? How is it different from a bug or a service request?</b>
<br>An issue is a predecessor of a formal PR (Problem Report) or bug.  An issue is simply a statement
capturing a potential problem or a problem that the project team has not decide how to or whether
it is necessary to tackle.  When an issue, need or request surface in a project, it may grow to a point that
the project team wants to track this issue/need as a Case.
Members of a project team may identify an issue either in a meeting or
simply directly in a project space.  At a later point in time, if the team decided this is a
formal problem, they may track this issue as a formal Case.  Once an issue is moved into a Case,
CPM CT will manage the Case through its lifecycle.  See the above note for a description of the
Case lifecycle.

</ul>
</p>

<table width="700"><tr><td align="right"><a href="#" class="listlink">BACK TO TOP</a></td></tr></table>
<table border="0" width="700" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>

<p>
<!-- MF -->
<a name="meeting" class="listlink">ABOUT MEETING FACILITATOR</a>

<ul type="square">

<li><b>What is Meeting Facilitator (MF)?</b>
<br>MF is one of the collaborative tools on the CPM platform.  It connects to other CPM modules to
support users in the product development process.
MF facilitates meeting activities in all 3 stages of a meeting.  First, before the
meeting starts, users use MF to create and prepare the meeting such as defining
a detailed meeting agenda, uploading files to be reviewed in a meeting and gathering other
information (such as bugs, online discussions, project/task status, etc.) for the meeting.  Note that
all participants (invitees) of a meeting may upload files and contribute to the preparation of a meeting.

<br><br>
Secondly, MF supports users during a live meeting.  Users may take turn to play the
recorder role and take meeting minutes during a meeting.  People who join the live meeting can
see the progress of the meeting by login to the MF meeting server.  Unlike the Net Meeting
environment which requires participants to surrender their desktop control, users in MF
have the autonomy to control their desktop and are free to navigate to other areas in CPM.
This helps users to formulate their ideas and contributions during a meeting.  The goal is to
encourage more vigorous interactions for the team in meetings.  In addition to taking meeting
notes, MF supports the recorder to record decisions made in the meeting, track newly identified
issues, and define action items assigned to different team members.

<br><br>
Finally, MF takes away most of the administrative burdens from users in following up after
the meeting adjourned.  One common challenge for project teams is that people often have
great ideas and discussions over a meeting but find it very difficult to follow-up with
concrete and result-oriented activities after the meeting.  MF keeps track of all discussions of
meetings in a central repository.  It also supports team members to extract decisions,
issues and action items from meetings and optionally associate them to a specific project.  Over time
the project team may review these items (actions, decisions and issues) and drive the project to
a definitive and desirable direction accordingly.
MF intelligently tracks the timeline requirements of these items and sends email notification
messages to responsible users in time.  Recurring meetings (such as weekly or bi-weekly events)
are connected together such that users can easily navigate back and forth between meetings to review
progress of their work over the life of a project.
<br><br>

<li><b>What is the difference between Meeting Facilitator (MF) and Net Meeting?</b>
<br>Net Meeting and tools of its kind allow users to share their desktop window with remote users.
They are very handy in supporting presentation type of meetings in which participants log on to the
meeting through the network and share the information presented by the meeting coordinator.  CPM MF
is created for an entirely different purpose.  MF looks at meetings as a means to achieve company
objectives.  Meetings are ways the project team uses to drive towards a common goal.  As a result,
a meeting does not exist by itself; meetings must be connected together and contribute to the
accomplishment of the project goals -- whether it is to resolve certain issues of a project or
to coordinate project activities towards the completion of a project.  Depending on the type of
meetings, it is sometimes benefitial to use CPM along with Net Meeting in running meetings.
<br><br>

<li><b>How do I prepare a meeting agenda in MF?</b>
<br>MF has a meeting agenda template library which contains <%=COMPANY%>'s common meeting agenda for
you to choose from.  To create a meeting, follow this sequence in CPM:
<blockquote>
Click Meeting Tab >> Click New Meeting >> Fill out basic meeting info >> Click Next
</blockquote>
An editor box will show up for you to type the agenda items.  You may select different
meeting agenda template by selected on the left.  Agena items are arranged as a table of
content with items and sub-items.  Use "*" to indent an agenda item.  When finished, click
the Next Button to review the agenda and define responsible person and time allocated
for each agenda item.

<br><br>

<li><b>How do I use MF to run a meeting?</b>
<br>Once a meeting is defined, it will show up in the MF Calendar.  Note that users only see meetings
that they involved.  Click on the meeting in the calendar to display the details of the meeting.
When the time comes to 15 minutes before the meeting, a link called <b>Start Meeting</b> will be
shown on the top right corner of the page.  Click on this link to start the meeting.  A popup window
will prompt you whether you want to host the meeting as a recorder or to join the meeting as a
participant.  If the meeting has already started, the link will say <b>Join Meeting</b>.

<br><br>

<li><b>How do I add a followup meeting?</b>
<br>You can create a followup meeting after a meeting is finished or cancelled.  This allows you to
create "ad hoc" meetings to followup issues after a meeting is completed, or you can use this
feature to extend a chain of recurring events.  Several things to bear in mind when using this
function:
<ol>
<li>After a meeting is <i>finished</i> or <i>expired (cancelled)</i>, a button called <b>Create Followup Meeting</b> will appear on the right-hand top portion of the View Meeting Page.  You can click that to add a followup meeting after this meeting.  And if this meeting is in the middle of a chain of recurring events, the newly added meeting will be inserted into the chain after the current meeting.
<li>When you have finished the very last meeting of a chain of recurring event, you can use this "Create Followup Meeting" feature to extend the recurring events.  For example, in the beginning you may have created 20 recurring meetings, and at the end of the last meeting (the 20th meeting) you realize that you need to continue on this recurring event.  You can use Create Followup Meeting at the 20th meeting to create another 10 (or any number of) recurring events.
<li>Note that if you are in the middle of a chain of recurring events and click Create Followup Meeting AND SPECIFY RECURRING EVENTS in this create, then the original chain will be broken and the newly created chain will be attached to the end of the current meeting.  However, the original tail of meetings will not be deleted; they will still be on the calendar until you explicitly delete them.
</ol>

</ul>
</p>

<table width="700"><tr><td align="right"><a href="#" class="listlink">BACK TO TOP</a></td></tr></table>
<table border="0" width="700" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>

<p>


<!-- COMPANY -->
<p>
<a name="town" class="listlink">ABOUT COMPANY</a>

<ul type="square">
<li><b>What is a Company in CPM?  How many Companies can I join?</b>
<br>A Company in CPM is equivalent to a company or an organization in the real world, except that a user
may be associated to multiple companies.  However, every user has a primary company s/he associated with,
and in addition, s/he may associate to more companies.
<p>
Conceptually, a Company in CPM are like settlements
to allow groups of people with common goals to stay and work together on <a href="#project">projects</a>,
and share ideas and thoughts.  It also serves as a security boundary to own and share proprietary
knowledge of the group.  A user associates his/her membership with the primary Company but may work in other
companies as a guest member when authorized by the foriegn Company; thus creates collaborative efforts
between partner companies.  A Company may
have a number of projects open (active) for its own Company members to work on.
Any authorized users within the Company
may create <a href="#project">projects</a> and invite other inside and outside members to participate.
Company members may post events and <a href="weblog">weblogs</a>, and respond to postings.
<br><br>


</ul>
</p>

<table width="700"><tr><td align="right"><a href="#" class="listlink">BACK TO TOP</a></td></tr></table>
<table border="0" width="700" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>

<p>
<!-- BLOG -->
<a name="weblog" class="listlink">ABOUT BLOGGING</a>

<ul type="square">
<li><b>What is blogging?</b>
<br>The word Blogging originally comes from the word WEBLOG, which literally means Web Log,
is like an online journal.  It allows users to capture and share their opinions, thoughts and ideas.
CPM provides blogging to users for keeping and sharing information, ideas, issues, solutions, records
in relate to project/task management, bug tracking and any other product development related
activities.  Users may attach files to their blogs, and may give comments to blogs posted by others.

<br><br>
<li><b>How do I use blogging in CPM?</b>
<br>In CPM, blogs can be posted in two areas.  Second users may write blogs on each of the tasks
within a project.  These task blogs are shared between the project team and serve as an organized
discussion area for people who have a stake in that task.  For public projects, task blogs can be
viewed by all CPM members at <%=COMPANY%>.  Blogs in CPM support file attachments, as a result
users may upload their presentations or data files when posting blogs.
Over time task blogs creates a knowledgebase in regard to certain project expert areas.

<br><br>
Blogs can also be posted on individual bugs (PR).  Again, users may attach multiple files to the
blogs they posted.

<br><br>
<li><b>Will blogs be archived (stored) away over time?</b>
<br>Blogs will be archived periodically depending on the among of blogs written to the task or bug.
But they will continue to be accessible by users as if they are stored in
the active database.  Author of a blog may only edit the weblog before it is archived.

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
<a name="alert" class="listlink">ABOUT ALERT MESSAGE</a>

<ul type="square">
<li><b>What are Alert Messages in CPM</b>
<br>Alert messages in CPM may be email message and/or Web page alerts.  Users may send an alert
message to other users or project team members to notify them about an event.  CPM may also trigger
an alert notification message to users when a project, task, bug and action event has occurred.
CPM may also send alert messages on system events.

<br><br>
<li><b>How do I send an alert message to people?</b>
<br>You can only send alert message to people whenever you see an email icon
(<img src="../i/eml.gif">).
To send an alert, click the icon and follow the instructions.

<br><br>
<li><b>What is the difference between using Email and Alert Message?</b>
<br>Email is a context free message from a sender to a recipient.  It relies on users to organize
the email by filing it in different folders.  CPM is an online community about team formation
and teamwork.  As a result, when you send an Alert Message, it is within the context of one or more
projects.  In addition, the page alert is shown and manage in CPM.  This helps
the user to organize his/her communications around the team and the project.
<br><br>
Once you initiated a communication by sending a CPM Alert Message, you are binding the message
with a certain project.  From that point on, you and the recipients may then use email reply
to keep the communication going.

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
<a href="mailto:<%=ADMIN_MAIL%>">The CPM Team</a>
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
      &copy; 2008-2010, EGI Technologies</font></td>
    <td height="32">&nbsp;</td>
  </tr>
</table>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

