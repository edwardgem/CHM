<%
////////////////////////////////////////////////////
//	Copyright (c) 2010, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	help_cpm.jsp
//	Author:	ECC
//	Date:	07/10/10
//	Description:
//		Help info for CPM particularly about the 5 stages of managing a project.
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
	CPM Help
</title>

<script type="text/javascript">
<!--

function openParent(url)
{
	window.opener.location = url; 
	//window.close();
}

//-->
</script>
</head>


<body text="#000000" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="100%" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<tr><td><img src='../i/spacer.gif' height='20' /></td></tr>

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<b class="head">

	&nbsp;&nbsp; CPM Help

	</b><br><br>
	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- Navigation SUB-Menu -->

<!-- End of Navigation SUB-Menu -->

<!-- CONTENT -->
<table>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_head"><br>
		<br>

<span class="homenewsheader">5 Steps to Collaborative Project Management</span><br>
<p>
<table>
	<tr>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="#step1">Step 1: Project Initialization</a></td>
	</tr>

	<tr>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="#step2">Step 2: Project Planning</a></td>
	</tr>

	<tr>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="#step3">Step 3: Project Tracking and Monitoring</a></td>
	</tr>

	<tr>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="#step4">Step 4: Project Review and Report</a></td>
	</tr>

	<tr>
	<td><img src="../i/bullet_tri.gif" width="20" height="10"></td>
	<td><a class="listlink" href="#step5">Step 5: Project Closing</a></td>
	</tr>

</table>
</p>
</span>

<table border="0" width="100%" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>

<span class="plaintext">
<!-- General Overview -->
<br><br>
<b>Collaborative Project Management (CPM)</b>
<br><br>
CPM provides a collaborative platform for a team to simultaneously work on a project.
It guides the team through every step in the lifecycle of the project.
<br><br>
<table border="0" width="100%" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>

<!-- STEP 1: PROJECT INITIALIZATION -->
<p>
<a name="step1" class="listlink">STEP 1: PROJECT INITIALIZATION</a>
<br><br>
You go through a few simple steps to create a <i>project</i>.
A project composed of a number of <i>tasks</i> and <i>sub-tasks</i> to be completed
within the project timeline.  A project is also a common workspace online
for a team to share and coordinate their works and resources.
This section shows you how to create and publish project.

<ul type="square">
<li><b>Create a New Project</b>
<br>
	<div>
	To begin, you click the following link (available on the Home Page).
	<br>&nbsp;&nbsp;&nbsp;<a href='javascript:openParent("../project/proj_new1.jsp");'>Click to add a new project</a>
	<br></br>
	Clicking the above link will put you into the page to Create a New Project.
	Fill out the Project Name and other information requested on this page.
	If you don't know what Project Privacy to pick, choose Private.  You can change that later.
	<br></br>
	<b>Private Projects</b> are only seen by project team members.
	<br></br>
	<b>Public Projects</b> can be seen, comment on and upload files by all people of your company.
	<br></br>
	<b>Public Read-only Projects</b> can be read by all people of your company, but only team-members can comment and upload files.
	</div>
<br><br>

<li><b>Choose a Project Template</b>
<br>
	<div>
	Continue from above and click <b>Next&gt;&gt;</b>
	<br></br>
	You will be asked to choose a <i>project template</i> from the <i>Library</i>.
	Pick a type of project that is closest to the project you want to create.
	If you or other people of your organization had run a similar project in CPM,
	you would probably have a <i>Project Plan Template</i> saved from before that you can choose from,
	otherwise either picks one from the default templates or you have to create one of your own.
	<br></br>
	Review the content in the Project Plan Layout window and feel free to
	modify the template plan to suit your need.  Click <b>Next&gt;&gt;</b> to review how the plan
	would look like, then click <b>&lt;&lt;Prev</b> to come back to the Template Layout
	to further your modification.
	<br></br>
	Note that some of the templates already have timeline specified for each task.
	This is done by specifying the GAP and DURATION for each task.
	And the format is by appending GAP and DURATION in Days at the end of the task name,
	with the notation:
	<br><b>Task name :: Gap, Duration</b>
	<br></br>For example,

	<pre>&nbsp;&nbsp;Finalize wedding card design :: 2, 10</pre>

	Please note the use of double-colon (::) and comma (,)
	This denotes a task with a start gap of 2 days and duration of 10 days.
	The gap of a task is defined as the buffered days between its
	last dependency fulfillment and its start date.
	The duration defines the length of the task in days.
	
	</div>
<br></br>

<li><b>Tasks versus Containers</b>
<br>
	<div>
If you do not specify both the Gap and the Duration of a task, then the task will be marked
as a Container (one that only holds documents and files for the task node,
but its timeline will be ignored) rather than a project timeline task.
You don't need to make a decision at this point; you can always change it in
<a href='#step2'>Step 2: Setting Project and Task Dates</a>
or at any point in the life of the project
	</div>
<br></br>

<li><b>Publish the Newly Created Project</b>
<br>
	<div>
When you are satisfied with the project plan, you can click the <b>Publish</b> button,
which is located at the bottom of the page <i>Review and Publish the Project Plan</i>.
Once published, you can access this project on the Web.
At this point, you are the only person in this project team and the project timeline
may not be set up.  We will do these in the next step,
<a href='#step2'>Step 2: Project Planning</a>.
	</div>
<br></br>

</ul>
</p>

<table width="100%"><tr><td align="right"><a href="#" class="listlink">BACK TO TOP</a></td></tr></table>
<table border="0" width="100%" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>


<p>
<!-- STEP 2: PROJECT PLANNING -->
<a name="step2" class="listlink">STEP 2: PROJECT PLANNING</a>
<br></br>
Now the project is created and published, you want to complete the project planning
before starting to run the project.  In this step, you will add members to the project team,
assign them with the responsibilities of certain tasks, and set the planned dates of the tasks.
At the end of this step you will see a timeline, in a Gnatt Chart, of the project.

<ul type="square">
<li><b>Add Project Team Members</b>
	<div>
You must be the project coordinator (owner) in order to add team members to the project.
<br></br>
If you do not have other members of your company or organization in CPM,
this is the time you can register them.  To do that,
click on the Home Tab to go to the Home Page,
and click <a href='javascript:openParent("../admin/adduser.jsp");'>New User</a> under the submenu.
For each person you added, CPM would automatically send account information to him/her.
<br></br>

To select and add members of your organization to the project team,
on the Home Page click on the name of the project you have just created,
or click the Project Tab and make sure the right project is selected.
<br></br>

In the Project Plan Page, under the Project Tab, click on the
submenu item <b>Project Profile</b>.  You will see the current project information,
with the project team on the right-hand-side column.
Click the link that says <b>Add project team member</b>,
and you will be in the Update Project Profile Page.
Now scroll down to the Team Members area, highlight the people on the left
and click the <b>Add</b> button to add them to the project team.  When you are done,
save your change by clicking the <b>Submit</b> button at the bottom of the Page.
	</div>
<br></br>

<li><b>Assign Tasks to Team Members</b>
	<div>
You must be the project coordinator (owner) in order to assign project tasks to team members.
<br></br>
Once you have added more members to the project team,
you can assign them to be owners of different tasks. 
Task owners are responsible on the task. 
Using CPM a task owner may report the status of the task to the team.
Unlike traditional Project Management tool which relies on a project manager
to collect status from team members and update the project status,
CPM empowers various task owners to report on different aspects of the project.
<br></br>

On the project plan page, click on the name of a task to go to the <b>Task Management Page</b>.
Here you can transfer ownership of a task, or of a group of tasks in a sub-tree,
to another project team member.
Task owners may further transfer some of their tasks to other users,
as long as these users are part of the project team.
<br></br>

Task owners will receive email notifications from CPM when their tasks are ready to start
(e.g. all dependencies are fulfilled), or when the task deadline is approaching.
See <a href='#step3'>Step 3: Email Notification and Watcher</a> for more details.
	</div>
<br></br>

<li><b>Setting Project Dates</b>
	<div>
The whole project has a Start Date and an Expire Date (deadline),
and between them each of the tasks also has Start Dates and Expire Dates.
Each of Start and Expire Dates are further split into three dates.
Therefore, for each task there are these dates:
<br></br>

<b>Original Start Date</b> This is set based on the project template.
The project owner and task owner change it to note the original plan.
Once the project started, only the project owner may change it.
<br></br>
<b>Planned Start Date</b> This is the current planned start date of the task.
This may change repeatedly due to the current project timeline situation.
The project owner or task owner may change this date.

<br></br>
<b>Actual Start Date</b> This is a date set by CPM either when user explicitly
starts a task or when the task is started by CPM because all conditions are fulfilled.

<br></br>
<b>Original Deadline</b> This is set based on the project template.
The project owner and task owner change it to note the original plan.
Once the project started, only the project owner may change it.

<br></br>
<b>Planned Deadline</b> This is the current planned deadline of the task.
This may change repeatedly due to the current project timeline situation.
The project owner or task owner may change this date.

<br></br>
<b>Actual Completion Date</b> This is a date set by CPM when user indicates that the task is completed.

<br></br>
At this planning stage of the project, either project owner or task owner may use CPM
to set the original and planned dates.  Once the project starts to run,
only the project owner may change the original dates.  To set the planned dates,
user may either set the planned dates explicitly, or they may set the Gap and Duration of the tasks.

<br>
<img src='../i/timeline.jpg' />

<br></br>
In the above figure, Task 1 has a Duration (or length) of 10 days while Task 2
has a Duration of 15 days.  Task 2 is dependent on Task 1 as denoted
by the dotted line between the two tasks.  Also note that Task 2 has a Gap
of 7 days, which is the gap (4/01-4/08) between Task 1 and Task 2.

<br></br>
<b>Gap</b> The gap is the buffered days before a task starts.
For a task which has a dependency on other tasks, when all the dependencies are fulfilled,
the task is ready to start.  But user may define a buffer (gap) to create some rooms
before the task is required to start.  The Planned Start Date of a task therefore is calculated
based on the Planned Deadline of the task's dependent tasks and its own Gap.

<br></br>
During the gap time, the task owner may freely start a task, so as to gain
a head-start on the task assignment.  If not, CPM will automatically start the task
on the Planned Start Date.

<br></br>
For a task without dependency, if a Gap is defined, the Start Date will be calculated
using the Start Date of its parent task, plus the Gap.  For a sub-task, say, 2.3.4,
the parent is its lower level task, in this example 2.3.  For a top-level task, say 2,
the parent is the project.

<br></br>
<b>Duration</b> This defines the length of the task in days.
The Planned Deadline is calculated based on the Planned Start Date and the Duration of a task.

<br></br>


<li><b>Phases or Milestones</b>
	<div>
Sometimes it is helpful to divide a project into multiple phases.
When the team exits a phase, it is considered to have reached a milestone.
You can easily define project phases in CPM by associating a top-level task to a phase.

<br></br>
Click the Project Tab and choose a project.  Click on the name of a task that you want to use as a phase.
When a task is chosen as a <b>Phase</b>, that means all the sub-tasks under this task
would be accounted for as tasks within this phase.
Note that a task must be a <i>non-container</i> type of task in order to be set as a Phase.

<br></br>
In the Task Management Page.  Check the checkbox "Set as phase",
which is located on the right side under the Tab menu-bar.
Click the Project Tab to go back to the project plan; you should see Phase 1
marked on the project plan tree.  Repeat this process to define other phases for the project.
	</div>
<br></br>


<li><b>Project Timeline</b>
	<div>
CPM only supports displaying the timeline in IE 6+ browsers.

<br></br>
Click the Project Tab to go to the Project Plan Page.
On the top right-hand corner click the link <b>Timeline</b>.
A Gnatt chart of the project should appear.  If you are the project owner you would be able
to change the timeline of each of the tasks by dragging the triangular dots (in blue and red)
associated to each task.  Task owner may only change timeline of the tasks they own.

<br></br>
Note also that the critical path of the project is listed at the bottom of the timeline window.

	</div>
<br></br>


</ul>
</p>

<table width="100%"><tr><td align="right"><a href="#" class="listlink">BACK TO TOP</a></td></tr></table>
<table border="0" width="100%" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>


<p>
<!-- STEP 3: PROJECT TRACKING AND MONITORING -->
<a name="step3" class="listlink">STEP 3: PROJECT TRACKING AND MONITORING</a>

<ul type="square">
<li><b>Starting a Project</b>
	<ul type="circle">
	<li>Project options</li>
	<div>
Before starting a project, you might want to set up some project options that
help in tracking and monitoring the project.  On the Project Plan Page,
click the submenu item Project Profile, then click the Update Project Profile link
on the upper right-hand corner.  Scroll to the Project Option area.
You have several options to set for the project.
		<ul type="disc">
			<li>Submit project plan change by members</li>
			<li>Expand project tree at start</li>
			<li>Notify all team members on new postings</li>
			<li>Notify owner when task fails deadline</li>
		</ul>
	</div>

<br>
	<li>Set project state to OPEN</li>
	<div>
A project goes from NEW to OPEN to COMPLETE to CLOSE.  To start a project,
go to the Update Project Profile Page and change the Project Status from NEW to OPEN,
and then click the Submit Button at the bottom of the page.
	</div>
	
	</ul>
<br></br>

<li><b>Starting a Task</b>
<div>
A task should be started when it hits the Start Date of the task according to the timeline.
However, if there are dependencies defined, then all tasks that this task depends on must be
completed before this task can start.

<br></br>
When a task is started (in the OPEN state), a work item will be created in association
to the task for user to track the on-going work of the task.

	<ul type="circle">
	<li>CPM automatically starting a task</li>
		<div>
CPM will automatically start a task if the following conditions are fulfilled:<br>
			<ul type="disc">
			<li>All dependencies of the task are fulfilled; and</li>
			<li>The Start Date of the task has arrived.</li>
			</ul>
<br>
When the task is started automatically, CPM will send a notification email to the task owner.			
		</div>

<br>
	<li>User sets the task state to OPEN</li>
		<div>
When all the dependencies of a task has been fulfilled but the Start Date has not
arrived yet (this is usually the case when there is a non-zero gap defined on the task),
the task owner may explicitly start a task.  To do so, in the Project Plan Page,
click the name of the task you want to start.  In the Task Management Page,
scroll to the area of the Task Status and change it from NEW to OPEN, and then click
the Submit Button at the bottom of the page.
		</div>
		
<br>
	<li>Complete a task's work item</li>
		<div>
When a task is OPEN, there is a work item associated to it.
You go to the worktray (see the Worktray and Task Management Section below)
and select the associated work item to report on the status, progress or issues of the task.

<br></br>
When the task's work has been done, you can move the task status to COMPLETE.
To do that, again, go to the Task Management Page and change the task status from
OPEN to COMPLETE.  Alternatively, just for convenience,
you may also commit the associated work item.  This would automatically move
the task to the COMPLETE state.
		</div>
	</ul>
</div>

<br></br>


<li><b>Worktray and Task Management</b>
<div>
The worktray is the place where the employee tracks and reviews all the work tasks
of all projects that is waiting for him/her to perform.  Managers can use the worktray
to monitor project progress and provide feedbacks to other team members.

<br></br>
The worktray of an employee holds all the active work items that are waiting for
him/her to perform.  For each open (active) task there is an associated work item
that is placed in the task owner's worktray.  To go to the worktray,
from the Project Plan Page click the submenu item Work In-Tray.
If there is any open task assigned to you, then a number of work items related to
this project will be shown.  Click on any of them and the details of the work item
and the associated task will be shown in the Work Item box (right beneath the work item list).

<br></br>
You may add a blog to the task here to report the current status or issues of the task.
Alternatively, if the task has been completed, you may click the <b>Commit</b> Button
to indicate the task has been completed.  Click Abort if the task has been cancelled.

</div>

<br></br>

<li><b>Updating a Task</b>
	<ul type="circle">
	<li>Post files and blogs</li>
		<div>
Team members can post files and blogs onto a task.  On the Project Plan Page, click on the task name you want to post files.  In the Task Management Page, scroll to the place for Add File Attachments.  Click the Browse Button to select a file.  Repeat the selection process for multiple files.  Click Upload Files Button to upload the selected files.  You may see all of the file postings on a project by clicking the Project Tab, then click the submenu item File Repository.
<br></br>
To post blog, in the Project Plan Page, scroll to the task you want to post a blog, click the link on the right-hand (last) column of the task line.  If there are already blog postings on this task, then in the Blog Page, click New Post link under the submenu bar to post a new blog.
		</div>

<br>
	<li>Update the dates</li>
		<div>
As stated in Step 2 in the section of Setting Project Dates, there are six (6) dates for each task that concern the schedule, namely Original Start, Original Deadline, Planned Start, Planned Deadline, Actual Start, Actual Completion.
<br></br>
While in Step 2 of Project Planning, the most convenient way to set the tasks' dates is to go to the Update All Tasks Page, which can be accessed through the Project Plan Page by click the corresponding link in the top right-hand corner.
<br></br>
You may also change the task's dates by going into the Task Management Page.  To do that simply go to the Project Plan Page and click on the task name.
		</div>

<br>	
	<li>Transfer ownership</li>
		<div>
If you are the project owner or task owner, you may transfer the ownership of a task to a project team member.  From the Project Plan Page, click on the task name to go to the Task Management Page.  You may transfer the task ownership here.
		</div>
	
	</ul>
	
<br></br>


<li><b>Email Notification and Watcher</b>
	<div>
CPM automatically sends out Email notification to the task owner one day before a task reaches its deadline.  It will send another email to the task owner when the task has expired.  On the Project Plan Page, the task status (a color ball icon) will change color to indicate the corresponding status.
	
<br></br>
Project owner may set the project option to also notify all team members when there are file or blog postings.  Alternatively, on the Task Management Page, the project or task owner may set finer option on the task level to send notification Email.
	
<br></br>
Finally, any team members may watch a task on his Home Page by clicking the link "Watch this task on my home page", which is on the top right-hand corner of the Task Management Page.
	</div>
	
<br></br>


</ul>
</p>

<table width="100%"><tr><td align="right"><a href="#" class="listlink">BACK TO TOP</a></td></tr></table>
<table border="0" width="100%" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>

<p>
<!-- STEP 4: PROJECT REVIEW AND REPORT -->
<a name="step4" class="listlink">STEP 4: PROJECT REVIEW AND REPORT</a>

<ul type="square">
<li><b>Blogging and Comments</b>
	<div>
CPM is a collaborative platform solution allowing users to exchange information through blogging on tasks.  See the details on Step 2 about posting blogs on a task and through the worktray.
	</div>
</li>
<br></br>

<li><b>Change Project Plan</b>
	<div>
You need to be the project coordinator (owner) or an authorized personnel to change the project plan.
<br></br>
There might be a time when you need to change the project plan, such as adding more tasks, deleting tasks or moving the tasks around.  Project owner can update the project plan.  If the project option of allowing team members to submit plan change is selected, then they may change the plan and CPM will send the change notification to the project owner for approval before publishing the change.
<br></br>
To change the project plan, click on the Project Tab, then click submenu item
<a href='javascript:openParent("../project/proj_profile.jsp");'>Project Profile</a>.
On the top right-hand corner, click the link <b>Update Plan</b>.  You will go through a few steps to update and publish the plan.  Just follow the instructions on the page.
	</div>
</li>
<br></br>

<li><b>Project Summary Review</b>
	<div>
With CPM, you no longer have to wait for a project manager to distribute project reports.  Management and team members can review the project status in real-time.  On the Project Plan Page, click the submenu item Project Summary to access the page.
	</div>
</li>
<br></br>


<li><b>Status Reports</b>
	<ul type="circle">
	<li>Executive Summary
		<div>
CPM uses the task blog to capture the status report(s).  You can select one of the tasks in the project plan, or create a task (container) at the end of the plan just to hold the executive summary report.  (See above section on Change Project Plan on how to change the project plan and add a task to it.)  To identify a task as the executive summary report, note the task ID (which is listed on the Task Management Page).  Then on the Project Summary Page, click the link Project Report located on the top right-hand corner of the page.  Here you can enter the Executive Summary task ID and click Save.
		</div>
	</li>
	
	<br>
	<li>Phase Reports
		<div>
For each of the tasks that is identified as a phase, the task blog will be used as the phase report and will show up in the Project Summary Page.
		</div>
	</li>
	
	<br>
	<li>Report Distribution
		<div>
The project owner may trigger to send a periodic project report to a group of recipients.  On the Project Summary Page, click the link Project Report located on the top right-hand corner of the page.  Here you may specify the frequency to send this auto report through Email.
<br></br>
The content of the periodic report Email can be customized through EGI Global Services Team.
		</div>
	</li>
	</ul>
</li>
<br></br>


</ul>
</p>

<table width="100%"><tr><td align="right"><a href="#" class="listlink">BACK TO TOP</a></td></tr></table>
<table border="0" width="100%" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>


<p>
<!-- STEP 5: PROJECT CLOSING -->
<a name="step5" class="listlink">STEP 5: PROJECT CLOSING</a>

<ul type="square">
<li><b>Save Project Template</b>
	<div>
CPM has a project plan template library that stores the projects plans for different types of projects.  Employees choose from the project template library a standard plan when they start their project.  This enables a user to quickly start a project by borrowing the expertise of other users in the organization; it also ensures high quality control over project management practice.  Projects of similar types may therefore have a consistent layout and timeline throughout a large and even distributive organization.
<br></br>
You may save the project plan anytime in the life of the project when you are satisfied with the current project plan.  Click the Project Tab and then the submenu item Project Profile.  On the top right-hand corner, click the link Save Plan Template and follow the instruction to indicate the type of project and give the template a name.
<br></br>
Note that CPM automatically calculates the time required for each task by noting your current dates.  It will be recorded at the end of each task name line using the convention:
<br></br>
<pre>task name :: Gap, Duration</pre>

See Step 1 on Choosing a Project Template for more details.
	</div>
</li>

<br></br>
<li><b>Completing and Closing a Project</b>
	<div>
When the project is completed (that means it completed all its tasks and reach its objectives), the project owner may indicate that moving the project status to COMPLETE.  Click the Project Tab, and then click the submenu item Project Profile.  On the upper right-hand corner, click Update Project Profile.  Change the Status of the project to COMPLETE.
<br></br>
After the project is completed, the project owner may want to CLOSE the project.  Note that once a project is closed, no one can further post files or blogs to the tasks.  A closed project is ready to be archived.
	</div>
</li>

<br></br>
<li><b>Project Analysis</b>
	<div>
CPM automatically performs statistic analysis on closed projects.  Regression analysis is done over history on a number of projects.  It would also evaluate your organizations project by applying hedonic regression analysis method over similar project type of the same industry.  The Project Analysis features will be available in future releases.
	</div>
</li>

</ul>
</p>

<table width="100%"><tr><td align="right"><a href="#" class="listlink">BACK TO TOP</a></td></tr></table>
<table border="0" width="100%" height="1" cellspacing="0" cellpadding="0">
	<tr>
		<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
	</tr>
</table>

<p class="plaintext">
If you have any questions or suggestions, please e-mail
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
    <td width="100%" height="2" bgcolor="336699"><img src="../i/mid/u2x2.gif" width="2" height="2"></td>
    <td height="2" bgcolor="336699"><img src="../i/mid/u2x2.gif" width="2" height="2"></td>
  </tr>
  <tr>
    <td width="100%" valign="middle" align="center">
		<a href="javascript:window.close()" class="listlink">Close</a>
		&nbsp;|&nbsp;
		<a href="#top" class="listlink">Back to top</a></td>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td width="100%" height="32" align="center" valign="middle"><font size="1" face="Arial, Helvetica, sans-serif" color="#999999" class="8ptype">Copyright
      &copy; 2005-2010, EGI Technologies</font></td>
    <td height="32">&nbsp;</td>
  </tr>
</table>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

