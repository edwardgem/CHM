<%
////////////////////////////////////////////////////
//	Copyright (c) 2006, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	faq_omf.jsp
//	Author:	ECC
//	Date:	09/07/06
//	Description:
//		FAQ page for OMF.
//	Modification:
//
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "util.*" %>

<%
	String COMPANY		= Util.getPropKey("pst", "COMPANY_NAME");
	String NODE			= Util.getPropKey("pst", "PRM_HOST");
	String ADMIN_MAIL	= Util.getPropKey("pst", "FROM");

	boolean isLogin = false;
	String home = request.getParameter("home");
	
	if (home == null)
		home = "../index.jsp";
	if (home.equals("../ep/ep_home.jsp"))
		isLogin = true;

%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">

<title>
	MeetWE FAQ
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

	<!-- Terms of Use -->
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="terms_omf.jsp?home=<%=home%>" class="subnav">Terms of Use</a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- Help Forum -->
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="help.jsp?home=<%=home%>" class="subnav">Feedback Forum</a></td>
					<td colspan="3" width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
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
	<td><a class="listlink" href="#meeting">The Open Meeting Facilitator</a></td>
	</tr>

	<tr>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="#pre-meeting">Create and Prepare for a Meeting</a></td>
	</tr>

	<tr>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="#run-meeting">Running a Meeting</a></td>
	</tr>

	<tr>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="#post-meeting">After a Meeting</a></td>
	</tr>

	<tr>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="#search">Search Functions</a></td>
	</tr>

</table>
</p>
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
<li><b>What is MeetWE?</b>
<br>Simply put, MeetWE is a second generation social networking site.  Compare to its predecessor, MeetWE
is similar in providing an open networking environment for members to casually share and interact with one
another.  What is new is that MeetWE also allows members to continually nurture and deepen relationships
between members, and enables them to conveniently set up sub-circles within the social networking environment.
<br><br>MeetWE provides an open interactive environment which supports users to share ideas, meet with friends,
organize activities, and coordinate efforts through posting, blogging, chattting and meeting together online.
MeetWE has evolved into a global community with users of different backgrounds from all over the world.
You will expand your network naturally when participating in interactivities organized by your trusted friends
or contacts. And you can contribute to the MeetWE community by sharing your ideas and suggesting
best practices in achieving various objectives.
<br><br>
MeetWE provides you with a myriad of meeting templates to jumpstart your efforts in organizing events for
family and friends, as well as coordinating business activities.  These may include leisure events such as travel plans,
parties, showers, or review of a movie; or business events such as planning to start a business,
writing a business plan, creating a new product, working on a joint project, coordinating a conferent event, and others.
<br><br>
You may also start a spontaneous online discussion with a few friends or with anyone interested to join in, to review
a book or a movie, share a political point fo view, or discuss any subject of their choice.
<br><br>
MeetWE enables you to have an organized discussion over any topic and keep notes on what each participant
has said.  It also helps to create follow-up action items and track the progress of each action over time.
You can easily organize a continuous effort by linking multiple meetings together and tracking all the action
items and decisions the group has made in all those meetings.
<br><br>
Whether you are meeting face-to-face, teleconferencing, video conferencing, or holding chat meeting online, MeetWE can
assist you to have a more productive and organized meeting.

<br><br>
<li><b>Why use MeetWE?  Why not just meet face-to-face?</b>
<br>Even if you are meeting face-to-face, MeetWE can assist you to better prepare and run the meeting.  However, 
there is more with MeetWE.  With MeetWE, you can choose to meet face-to-face or simply meeting online.  MeetWE
allows you to meet in virtual meeting rooms online, which means you and your friends can be in different
locations getting together to accomplish most of what you can by meeting face-to-face, and more.
<br><br>
MeetWE provides you and your group with an environment to facilitate and track your ideas and efforts,
very much like having a secretary or administrator to help organize things for you and your group.
In addition, you will be able to expand your network and meet new contacts by sitting or
participating in casual and/or professional meetings with your friends.

<br><br>
<li><b>Why use MeetWE?  Why not use teleconferencing if we cannot meet face-to-face?</b>
<br>First, MeetWE can assist you to prepare and run the meeting even if you are using teleconferencing or
video conferencing.  Furthermore, MeetWE is free and it does not have the performance limitation that free IP teleconferencing
has today.  More importantly, you and your group can meet in the virtual meeting rooms at MeetWE without
saying a word but accomplish most of what teleconferencing can do.  The fact that you can carry out
a meeting without disturbing others around you can be a big advantage.  Besides, you can always
use MeetWE along with teleconferencing facility if it is available.  MeetWE
helps you organize and keep track of the inputs from all meeting participants, identify action items
and decision records from the meeting, and enables you to distribute a neatly organized meeting
record to the meeting group.  This is something that teleconferencing cannot yet offer today.
<br><br>
Finally, MeetWE allows you to participate in multiple meetings at the same time.  You can simply open two
Web browser windows and attend two separate meetings that overlap with one another.

<br><br>
<li><b>What do I need to have in order to use MeetWE?</b>
<br>MeetWE is a free Web browser-based service; all you need is a Web browser and Internet access in
order to use MeetWE.  You may also participate a meeting through an Internet-enabled PDA.

<br><br>
<li><b>How do I get a login account on MeetWE?</b>
<br>
MeetWE is free; simply go to the <a href='<%=NODE%>/login_omf.jsp'><b>MeetWE Login Page</b></a> and 
register yourself as a New User.  You will immediately be able to use MeetWE to participate in meetings or to create
facilitate meetings and discussions in real-time.

<br><br>
<li><b>Can I use Net Meeting and/or teleconferencing while using MeetWE?</b>
<br>Yes.  You can certainly use MeetWE alone to run an interactive meeting online.  However, depending on
the purpose and format of your meeting, it is sometimes benefitial to use MeetWE along with Net Meeting
and/or teleconfenerce facility in running meetings.

<br><br>
<li><b>How do I join a meeting in MeetWE?</b>
<br>You can go to the <a href='<%=NODE%>/login_omf.jsp'><b>MeetWE Login Page</b></a> to either login
or create a New User account if you are not yet a MeetWE member.  Remember, MeetWE is free.
When you have login, simply click the <b>Meeting</b> tab and then click the sub-menu item <b>Calendar</b>.
All of your meetings are shown on the calendar page.  Note that a user only see meetings
that s/he is invited - meaning either <i>Public Meetings</i> or <i>Private Meetings</i> in which s/he is an invitee.
Click on the meeting in the calendar, if the meeting has already started, you will now be inside the meeting
room.  If the meeting has not started, it will display the detailed information of the meeting on the screen.
When the time comes to 15 minutes before the meeting, a link called <b>Start Meeting</b> will appear
on the top right-hand corner of the page.  Click on this link to join the meeting.  A popup window
will prompt you whether you want to run the meeting as a facilitator.  Click <b>Cancel</b> if you are
a participant but not a facilitator.  You will now either be waiting for the meeting to start or be in
the meeting room if the facilitator has already started the meeting.


</ul>
</p>

<table width="95%"><tr><td align="right"><a href="#" class="listlink">BACK TO TOP</a></td></tr></table>
<table border="0" width="95%" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>

<p>
<!-- MF -->
<a name="meeting" class="listlink">THE OPEN MEETING FACILITATOR</a>

<ul type="square">

<li><b>What is the Open Meeting Facilitator (OMF)?</b>
<br>MeetWE does not only provide you with free, online meeting rooms; it also has a collaborative tool called
the Open Meeting Facilitator (OMF) to enhance your experience in facilitating discussions or running meetings.
<br><br>
MF facilitates meeting activities in all 3 stages of a meeting,
namely <a href='#pre-meeting'><b>pre-meeting</b></a>, <a href='#run-meeting'><b>during meeting</b></a>
and <a href='#post-meeting'><b>post-meeting</b></a>.

<br><br>

<li><b>What is the difference between MeetWE and Net Meeting?</b>
<br>Net Meeting and tools of its kind allow users to share their desktop window with remote users.
They are very useful in supporting presentation type of meetings in which participants log on to the
meeting through the network and share the information presented by the meeting coordinator.  MeetWE
is created for entirely different but complementary purposes.  First MeetWE provides free meeting rooms
online for a group of people to meet and share ideas in a control but real-time environment.  Instead of having
a single presentor, MeetWE enables all of the people in the meeting room to volunteer ideas and thoughts
simultaneously.  Second MeetWE provides a tool called the Open Meeting Facilitator (OMF)
to support users in preparing, running and following up meetings.

<br><br>

<li><b>How do I prepare a meeting agenda on MeetWE?</b>
<br>MeetWE has a meeting agenda template library which contains MeetWE's common meeting agenda for
you to choose from.  All of them are contributed by users of the MeetWE community.
To create a meeting, follow this sequence in MeetWE:
<blockquote>
Click <b>Meeting</b> Tab >> Click <b>New Meeting</b> >> Fill out basic meeting info >> Click <b>Set Agenda</b>
</blockquote>
An editor box will show up for you to type the agenda items.  You may select different
meeting agenda template by selected on the left.  Agena items are arranged as a table of
content with items and sub-items.  Use "*" to indent an agenda item.  When finished, click
the <b>Time Allocation</b> Button to review the agenda and define responsible person and time allocated
for each agenda item.  Finally, click the <b>Finished</b> Button to complete the process.


</ul>
</p>

<table width="95%"><tr><td align="right"><a href="#" class="listlink">BACK TO TOP</a></td></tr></table>
<table border="0" width="95%" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>

<p>
<!-- Pre-Meeting -->
<a name="pre-meeting" class="listlink">CREATE AND PREPARE FOR A MEETING</a>

<ul type="square">
<li><b>Public and Private Meetings</b>
<br>You may create a Public or Private Meeting by clicking on the Schedule a Meeting link.  Alternatively, when
you are logon to MeetWE, you can click the top "Meeting" Tab and then the sub-menu item "New Meeting".
<br><br>
A <b>Public Meeting</b> is one that can be seen and participated by any of the members in the MeetWE community.  If you
have a general topic that you would like to chat with people about and to get valuable insights or input from
the community, this would be the type of meeting you want to choose.
<br><br>
A <b>Private Meeting</b> can only be seen and participated by people who you invited to the meeting.  It is adequate for
business meeting or if you want to chat with a few close friends of yours.

<br><br>
<li><b>Company Meetings</b>
<br>Corporate pay users would have the option to create Company Meetings.  When scheduling a meeting, simply select the
radio button next to your company name, and all of the company employees would see that meeting on their calendar.  If you
don't want the meeting to be seen by other employees but only your meeting invitees, check the radio buttons to indicate
<b>Private</b> and <b>Personal</b>.

<br><br>
<li><b>Pre-Meeting Support</b>
<br>Before the meeting starts, MeetWE helps you create and prepare a meeting such as choosing and defining
a meeting agenda, uploading files to be reviewed in the meeting, and inviting people to the meeting.
Note that not only the creator of the meeting
can upload files, but also all invitees of a meeting may upload files and contribute to
the preparation of a meeting.  All invitees can then download the files before the meeting, or open the files
online during the meeting time.  As the creator of a meeting, you can invite people to the meeting by
simply picking and choosing from your MeetWE contacts.  You may also desire to invite guests to join
in by specifying their email addresses.

<br><br>
<li><b>Who can upload files to meetings?  How do I upload a file to a meeting in MeetWE?</b>
<br>All people who are invited to a meeting may upload files before the meeting start.  The
facilitator of the meeting may also upload more files after the meeting is finished.

<br><br>
<li><b>Can I change the meeting before it starts?</b>
<br>Yes, you may change the subject, date and time of a meeting before it starts.  You may add
or remove invitees to the meeting, change the agenda, and/or upload more files to be used in the meeting.

</ul>
</p>

<table width="95%"><tr><td align="right"><a href="#" class="listlink">BACK TO TOP</a></td></tr></table>
<table border="0" width="95%" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>

<p>
<!-- RUN MEETING -->
<a name="run-meeting" class="listlink">RUNNING A MEETING</a>

<ul type="square">
<li><b>Live Meeting Support</b>
<br>MeetWE has an Open Meeting Facilitator (OMF) tool to support users during a live meeting.
You choose and walk-in to a live meeting room after you login to MeetWE.  Meetings can be <a href='#pre-meeting'>public</a> or
<a href='#pre-meeting'>private</a>.  Public meetings are seen by all MeetWE users and anyone can walk-in and participate.
Private meetings are only seen and available for people who are invited to the meeting.
People who walk into a meeting room can see the real-time progress of the meeting.  Unlike most Net Meeting
environment which requires participants to surrender their desktop control, MeetWE users
have the autonomy to control their desktop and are free to navigate to other areas in MeetWE.
This helps users to freely formulate their ideas and thoughts during a meeting.  The goal is to
encourage more vigorous interactions of the group in the live meeting room.

<br><br>
<li><b>How do I run a meeting in MeetWE?</b>
<br>Once a meeting is created by doing a New Meeting, it will show up in your MeetWE <b>Event Calendar</b>.
Note that users only see meetings
that they are invited - meaning either Public Meeting or Private Meeting in which s/he is an invitee.
Click on the meeting in the calendar to display the details of the meeting.
When the time comes to 15 minutes before the meeting, a link called <b>Start Meeting</b> will appear
on the top right-hand corner of the page.
Click on this link to start the meeting.  A popup window
will prompt you whether you want to run the meeting as a facilitator.  Click <b>OK</b> to confirm.

<br><br>
<li><b>What can a meeting Participant do in a Live Meeting?</b>
All meeting participants can see in real-time what the meeting facilitator is typing in the meeting
minutes box.  The facilitator controls the input to the meeting.  If a participant wants to say something,
s/he may use the following mechanism:

<ol>
<li><b>Send Expressions</b>: The Send Expression feature is located under the Meeting Minutes Box.  The user simply chooses the expression s/he wants to send and then click the <b>Send</b> Button.  All participants will see the graphical expression on the lower right-hand corner of their web browser.
<li><b>Input Queue</b>: A number of participants may line up on a queue to request the facilitator for an opportunity to enter text to the meeting.  The input queue is located on the right-hand side of the Meeting Minutes Box.  Click the <b>ENTER</b> link under the queue will enter your name to the queue.  When the facilitator sees it, s/he may click to <b>ENABLE</b> one person at a time to enter a dialogue with him/her through a chat session.  The text of the chat session will get entered into the meeting minutes.
<li><b>Invite Input</b>: The meeting facilitator may select to invite any number of participants to enter a multi-chat session.  When the facilitator click on the <b>Invite Input</b> Button under the Meeting Minutes Box, s/he may choose all or some participants to enter a multi-people chat with him/her.  Again, the text of the chat session will be entered into the meeting minutes.  Clicking on the <b>Stop Input</b> Button allows the facilitator to change the participants to the chat session.
</ol>

<br><br>
<li><b>What does a facilitator do during a Live Meeting?</b>
By default, the creator of the meeting will assume the facilitator role.  However, s/he may choose to pass
the facilitator role to another attendee online.  At any point in time, the creator may choose to
retrieve his/her facilitator role from the current facilitator.

<br><br>
In general, the facilitator is
responsible for running the meeting.  S/he has control over entering the meeting note (commonly known as
the meeting minutes).  Again, the facilitator role can be passed around to anyone inside the virtual meeting
room.  The facilitator may also decide to open up the "floor" and allow multiple people in the meeting
room to simultaneously writing to the meeting note.  This is particularly handy for brainstorming or for
soliciting input from a group of users in real-time.  In addition to taking meeting
notes, MF allows the facilitator to define action items and decision records.  Action items can be assigned to
multiple people either inside or outside of the meeting room.  A deadline is associated with an action item.
MeetWE will remind the responsible persons when the deadline is up.


<br><br>
<li><b>How do I add an action item or decision record during a meeting?</b>
<br>When you are in a live meeting, the facilitator may add action items and decision records to
be attached to the meeting by scrolling to the bottom of the Live Meeting Page.  The section to
add and update action items and decision records is self-explanatory.

</ul>
</p>

<table width="95%"><tr><td align="right"><a href="#" class="listlink">BACK TO TOP</a></td></tr></table>
<table border="0" width="95%" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>

<p>
<!-- POST MEETING -->
<a name="post-meeting" class="listlink">AFTER A MEETING</a>

<ul type="square">
<li><b>Post-Meeting Support</b>
<br>OMF takes away most of the administrative tasks from users in following up after
the meeting is over.  When the meeting is over, the facilitator may polish the meeting note, action items and
decision records.  When it is ready, MF allows the facilitator to send all of these meeting information to
the meeting group or to anyone.  Since multiple meetings can be linked together in a chain, a group fo contacts
may continue to meet over a topic or a common objective and handily follow-up with all of the action items
and decisions they have identified over time.

<br><br>
MF intelligently tracks the timeline requirements of these items and sends email notification
messages to responsible users in time.  Recurring meetings (such as weekly or bi-weekly events)
are automatically connected together such that users can easily navigate back and forth between meetings to review
progress of their work over the life of a project.


<br><br>
<li><b>How do I send out the meeting minutes to people?</b>
<br>When you click on the calendar to review a finished meeting, a link called <b>Send Meeting Record</b>
is available on the top right-hand corner.  Click that link to forward the meeting minutes and action items
to the meeting group or to any guests.

<br><br>
<li><b>How do I follow-up with the Action Items after a meeting?</b>
<br>First MeetWE will automatically send out reminder notification email to people who are responsible for
the action items.  You may review the action items and their blogs anytime when you click on the calendar
to review a particular meeting.

<br><br>
<li><b>What is the action item blog used for?  How do I open the blogs?</b>
<br>The action item blogs can be used to maintain any discussions or progress report over the action
item.  Anyone who is invited to the meeting can read and post blogs associated to the action items of
the meeting.  The action items are listed at the bottom of the View Meeting Page which you can access by
clicking the meeting event on the calendar.  On each of the action item, there is a digit
showing the number of blogs posted on that action item.
Click on this number will bring you to the page to view and post blog on this action item.

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


<table width="95%"><tr><td align="right"><a href="#" class="listlink">BACK TO TOP</a></td></tr></table>
<table border="0" width="95%" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>

<p>
<!-- SEARCH FUNCTIONS -->
<a name="search" class="listlink">SEARCH FUNCTIONS</a>

<ul type="square">
<li><b>MeetWE Search Engine</b>
<br>You can use the MeetWE Search Engine to look for past meeting minutes, action item blogs and files you and
your contacts have uploaded to meetings.  There are two ways to use the search engine.  Anywhere in MeetWE
you will see a search box on the top right-hand corner of the page.  You can enter a search text into the box
and click return.  Files that you are authorized to see (i.e. those that are attached to public meetings or
to private meetings which you are invited to attend) that contain these text will return to you.  Below
are some examples of entering search text.
<blockquote>
<table>
	<tr><td width='200' class='plaintext'>suzanne wedding</td>
	<td class='plaintext'>(files that contain either <u>suzanne</u> OR <u>wedding</u> will return)</td></tr>
	<tr><td width='200' class='plaintext'>"suzanne wedding"</td>
	<td class='plaintext'>(files that contain the phrase <u>suzanne wedding</u> will return)</td></tr>
	<tr><td width='200' class='plaintext'>+suzanne +wedding</td>
	<td class='plaintext'>(files that contain both words <u>suzanne</u> and <u>wedding</u> will return)</td></tr>
</table>
</blockquote>

In addition, by using the Advanced Search function in MeetWE you can search meeting
minutes, blogs and files by content.

<br><br>
<li><b>Can I search for meeting minutes and action item blogs by content?</b>
<br>Yes.  Using use the <b>Advanced Search</b> function in MeetWE, you can search meeting
minutes, action item blogs, as well as files by content.
To open Advanced Search, click on the magnifying glass icon next to the search
box on every page of MeetWE.
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
<a href="mailto:<%=ADMIN_MAIL%>">The MeetWE Team</a>
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
		<a href="#" onclick="return false;" class="listlink">FAQ</a>
		&nbsp;|&nbsp;
		<a href="help.jsp?home=<%=home%>" class="listlink">Feedback</a>
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

