<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
////////////////////////////////////////////////////
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	blog_task.jsp
//	Author:	ECC
//	Date:	03/25/04
//	Description:
//		Display the task weblog.
//	Modification:
//		@042805ECC	Support bug blog.
//		@ECC090605	Support listen to blog.
//		@ECC100605	Allow blog creator's manager to EDIT (ECC: commented out)
//		@ECC122305	Support archiving of bug blog.
//		@ECC022606	Support an option to turn on notification for all blogging in a project.
//		@ECC041006	Add blog support to action/decision/issue.
//		@SWS082906  Switch Menu tab if OMF application.
//		@AGQ091106	Bug fix: projIdS doesn't not equal null but ""
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.*" %>
<%@ page import = "util.*" %>
<%@ page import = "org.apache.log4j.Logger" %>

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	String projIdS = request.getParameter("projId");		// projId can be null in the case of action blog
	String pTaskIdS = request.getParameter("planTaskId");
	String taskIdS = request.getParameter("taskId");		// might use this or planTaskId
	String bugIdS = request.getParameter("bugId");
	String aIdS = request.getParameter("aid");				// @ECC041006
	String noSession = "../out.jsp?go=blog/blog_task.jsp?projId="+projIdS
		+ ":planTaskId=" +pTaskIdS+ ":bugId=" +bugIdS + ":taskId=" + taskIdS;
	
	// for project top
	if (aIdS==null && taskIdS==null) {
		if (projIdS==null || projIdS.equals("session"))
			projIdS = (String)session.getAttribute("projId");
		else
			session.setAttribute("projId", projIdS);

		if (projIdS == null || projIdS.equals("null")) {
			response.sendRedirect("../project/proj_select.jsp");
			return;
		}
	}

	
	final int MAX_DISPLAY	= 30;
	
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%!
	resultManager rMgr;
	TreeMap<Long, PstAbstractObject> getTreeMap(
			PstUserAbstractObject u, PstAbstractObject [] blogArr, String pidS)
		throws PmpException
	{
		// for each blog, look up its comments to get the last CreatedDate (comment date)
		// if none, use the blog's CreatedDate
		TreeMap<Long, PstAbstractObject> m = new TreeMap<Long, PstAbstractObject>();
		
		int [] ids;
		PstAbstractObject o;
		Date dt;
		long key;
		String idS;
		for (int i=0; i<blogArr.length; i++) {
			// get the last comment
			o = blogArr[i];
			idS = String.valueOf(o.getObjectId());
			ids = rMgr.findId(u, "ParentID == '" + idS + "'");
			if (ids.length > 0) {
				// there is at least one comment
				Arrays.sort(ids);
				o = rMgr.get(u, ids[ids.length-1]);			// the last comment blog
			}
			
			dt = (Date)o.getAttribute("CreatedDate")[0];// o is original if there is no comment
			key = -dt.getTime();	// - minus for reverse order
			
			// insert into TreeMap
			if (m.get(key) != null) {
				key++;			// to ensure unique key
			}
			m.put(key, blogArr[i]);
		}
		return m;
	}
	
	// for different locale date/time format, a simple sort on the Archieve attribute won't work
	// so we need this method
	void sortArchives(Object [] arcObjArr)
	{
		// archName are in the format of date:blogID_timestamp.jsp
		// so get the second part (blogID_timestamp.jsp) and then sort
		if (arcObjArr == null) return;
	
		int len = arcObjArr.length;
		String s;
		long [] timePartArr = new long[len];
		long lim = 1412450000000L;				// before this date archive is bad
		for (int i=0; i<len; i++) {
			s = (String) arcObjArr[i];
			try {
				s = s.substring(s.indexOf('_')+1, s.indexOf('.'));	// timestamp
				timePartArr[i] = Long.parseLong(s);
				if (timePartArr[i] < lim)
					throw new Exception();
			}
			catch (Exception e) {
				timePartArr[i]=-999;
				arcObjArr[i] = "";
			}
		}
		
		boolean swap;
		long i1, i2;
		Object tempObj;
		do
		{
			swap = false;
			for (int i=0; i<len-1; i++)
			{
					i1 = timePartArr[i];
					i2 = timePartArr[i+1];

					if (i1 > i2)
					{
						// swap the element
						timePartArr[i]   = i2;
						timePartArr[i+1] = i1;
						
						tempObj = arcObjArr[i];
						arcObjArr[i] = arcObjArr[i+1];
						arcObjArr[i+1] = tempObj;
						
						swap = true;
					}
			}
		} while (swap);
	}

%>

<%
	////////////////////////////////////////////////////////
	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	Logger l = PrmLog.getLog();
	boolean isPDA = Prm.isPDA(request);

	boolean isGuest = false;
	//if (session == null) session = request.getSession(true);
	//PstUserAbstractObject pstuser = (PstUserAbstractObject)session.getAttribute("pstuser");
	if (pstuser == null || pstuser instanceof PstGuest)
	{
		isGuest = true;
		pstuser = PstGuest.getInstance();
		session.setAttribute("pstuser", pstuser);
	}
	String blogIdS = request.getParameter("blogId");		// this is in the anchor (e.g. #12345)
	int selectedBlogId = 0;
	if (blogIdS != null)
		selectedBlogId = Integer.parseInt(blogIdS);

	// to check if session is OMF or PRM
	boolean isOMFAPP = Prm.isOMF();
	boolean isPRM = Prm.isPRM();

	if (bugIdS==null || bugIdS.equals("null"))
		bugIdS = "";
	if (pTaskIdS!=null && pTaskIdS.equals("null"))
		pTaskIdS = null;
	if (taskIdS!=null && taskIdS.equals("null"))
		taskIdS = null;
	if (aIdS!=null && aIdS.equals("null"))
		aIdS = null;
	// @AGQ091106
	if (projIdS!=null && (projIdS.equals("null") || projIdS.equals("") || projIdS.equals("0")) )
		projIdS = null;
	
	int projId = (projIdS==null) ? 0 : Integer.parseInt(projIdS);

////////
// check to see if a BLOG id is specified: might need to look through the archives
%>
<script type="text/javascript">
<!--
var anchor = location.hash;
if ('<%=blogIdS%>'=='null' && anchor != '' && !isNaN(anchor))
	location = "blog_task.jsp?projId=<%=projIdS%>&planTaskId=<%=pTaskIdS%>&bugId=<%=bugIdS%>&aid=<%=aIdS%>&blogId="
		+ anchor.substring(1) + anchor;
//-->
</script>
<%
////////
	String host = Util.getPropKey("pst", "PRM_HOST");

	// task blog or bug blog
	boolean isForumBlog = false;
	boolean isCircleBlog = false;
	boolean isMtgBlog = false;
	boolean isQuestBlog = false;
	boolean isTaskBlog = false;
	boolean isBugBlog = false;
	boolean isActnBlog = false;
	boolean isProjectBlog = false;
	
	String title = null;
	planTask pTask = null;
	String stackName = null;
	PstAbstractObject obj = null;
	PstManager mgr = null;
	String synopsis = null;
	String idS = null;			// bugId or taskId: pass to addblog.jsp
	String idS2= null;			// bugId or pTaskId: pass to blog_comment.jsp
	String backPage = null;
	String type = null;
	String midS = null;			// meeting ID for action blog

	int myUid = pstuser.getObjectId();

	rMgr = resultManager.getInstance();
	projectManager pjMgr = projectManager.getInstance();

	// note that for action/decision blog, there might not be a project associated
	String s;
	String townIdS = "0";
	int projCoordinatorId = 0;
	Object [] teamIdList = new Object[0];							// init
	PstAbstractObject [] memberList = new PstAbstractObject[0]; 	// init
	String optStr = null;
	project projObj = null;
	String projName = "";
	String bugEmail2 = null;

	if (projIdS != null)
	{
		projObj = (project)pjMgr.get(pstuser, projId);
		projName = projObj.getDisplayName();
		s = (String)projObj.getAttribute("Owner")[0];
		projCoordinatorId = Integer.parseInt(s);

		townIdS = (String)projObj.getAttribute("TownID")[0];
		if (townIdS == null)
			townIdS = "0";

		// team members
		teamIdList = projObj.getAttribute("TeamMembers");	// need this for comparison later
		memberList = ((user)pstuser).getTeamMembers(projObj);

		// project options
		optStr = (String)projObj.getAttribute("Option")[0];
	}
	
	int totalTeamMember = memberList.length;

	
	int [] resultIds = null;
	String blogTemplateText = "";

	if (bugIdS.length() > 0)
	{
		// display bug blog

		// @ECC122305 Check to see if the requested blog is in an archive file
		if (blogIdS != null)
		{
			try
			{
				obj = rMgr.get(pstuser, blogIdS);
				String archFile = (String)obj.getAttribute("ArchiveFile")[0];
				if (archFile != null)
				{
					// the blog is in the archive file
					response.sendRedirect(host + "/servlet/ShowFile?archiveFile=" + archFile + "#" + blogIdS);
					return;
				}
			}
			catch(PmpException e) { blogIdS=null; selectedBlogId=0;}
		}

		// in the active database
		mgr = bugManager.getInstance();
		
		isBugBlog = true;
		title = "CR Blog";
		try {obj = mgr.get(pstuser, Integer.parseInt(bugIdS));}
		catch (PmpException e)
		{
			response.sendRedirect("../out.jsp?msg=The PR (" + bugIdS + ") you tried to access has been removed from the database.");
			return;
		}
		idS = bugIdS;
		idS2 = bugIdS;
		
		// Email2 for Ticket submitter
		s = obj.getStringAttribute("Email2");
		if (s!=null && s.indexOf('@')!=-1)
			bugEmail2 = s;

				synopsis = (String)obj.getAttribute("Synopsis")[0];
		midS = (String)obj.getAttribute("MeetingID")[0];		// issue/PR may be connected to the meeting
		backPage = "../blog/blog_task.jsp?projId=" +projIdS+ ":bugId=" + bugIdS;
		type = result.TYPE_BUG_BLOG;
	}
	else if (aIdS != null)
	{
		// action/decision blog
		mgr = actionManager.getInstance();
		isActnBlog = true;
		title = "Action/Decision Blog";
		try {obj = mgr.get(pstuser, Integer.parseInt(aIdS));}
		catch (PmpException e)
		{
			response.sendRedirect("../out.jsp?msg=The Action/Decision (" + aIdS + ") you tried to access has been removed from the database.");
			return;
		}
		idS = aIdS;
		idS2 = aIdS;
		synopsis = (String)obj.getAttribute("Subject")[0];
		if (synopsis.length() > 100) synopsis = synopsis.substring(0, 100) + " ...";
		midS = (String)obj.getAttribute("MeetingID")[0];
		backPage = "../blog/blog_task.jsp?projId=" +projIdS+ ":aid=" + aIdS;
		type = result.TYPE_ACTN_BLOG;
	}
	else if (projIdS!=null && pTaskIdS==null && taskIdS==null)
	{
		// display project blog
		isProjectBlog = true;
		mgr = pjMgr;
		obj = mgr.get(pstuser, projId);
		title = "Project Blog";
		type = result.TYPE_PROJ_BLOG;
		idS = projIdS;
		backPage = "../blog/blog_task.jsp?projId=" +projIdS;
	}
	else
	{
		// display task blog
		planTaskManager ptMgr = planTaskManager.getInstance();
		if (pTaskIdS == null)
		{
			// planTaskId is optional for caller, if I don't receive it just get it now
			// taskIdS = request.getParameter("taskId");
			if (taskIdS == null)
			{
				response.sendRedirect("../out.jsp?e=Access is declined");
				return;
			}
			int [] ptId = ptMgr.findId(pstuser, "TaskID='" +taskIdS+ "' && Status!='Deprecated'");
			Arrays.sort(ptId);
			pTaskIdS = String.valueOf(ptId[ptId.length-1]);
		}
		try {pTask = (planTask)ptMgr.get(pstuser, Integer.parseInt(pTaskIdS));}
		catch (PmpException e)
		{
			response.sendRedirect("../out.jsp?msg=The task (" + pTaskIdS + ") you tried to access has been removed from the database.");
			return;
		}
		mgr = taskManager.getInstance();
		isTaskBlog = true;
		if (taskIdS == null)
			taskIdS = (String)pTask.getAttribute("TaskID")[0];
		stackName = ">>" + TaskInfo.getTaskStack(pstuser, pTask);
		int idx = stackName.lastIndexOf(">>");
		stackName = stackName.substring(0, idx+2) + "<span class='subtitle'>" + stackName.substring(idx+2) + "</span>";
		stackName = stackName.replaceAll(">>", "</td><tr><tr><td width='20' class='plaintext_grey' valign='top'>>></td><td class='plaintext_grey'>");

		obj = mgr.get(pstuser, Integer.parseInt(taskIdS));
		idS = taskIdS;
		idS2 = pTaskIdS;
		title = "Task Blog";
		backPage = "../blog/blog_task.jsp?projId=" +projIdS+ ":planTaskId=" +pTaskIdS;
		type = result.TYPE_TASK_BLOG;
		
		// ECC task blog template
		String taskBlogIdS = ((task)obj).getOption(task.TASK_BLOG_ID);
		if (taskBlogIdS == null) {
			// try project specific blog template
			taskBlogIdS = projObj.getOption(project.TASK_BLOG_ID);
		}
		
		// see if there is blog template specified
		if (taskBlogIdS != null) {
			// display the task blog template
			try {
				PstAbstractObject o = rMgr.get(pstuser, taskBlogIdS);
				Object bTextObj = o.getAttribute("Comment")[0];
				blogTemplateText = (bTextObj==null)?"":new String((byte[])bTextObj, "utf-8");
			}
			catch (PmpException e) {System.out.println("unknown task template: " + taskBlogIdS);}
		}
	}

	boolean isAdmin = false;
	Integer io = (Integer)session.getAttribute("role");
	int iRole = 0;
	if (io != null) iRole = io.intValue();
	if (iRole > 0)
	{
		if ((iRole & user.iROLE_ADMIN) > 0)
			isAdmin = true;
	}

	// only allow posting and reply if it is not Read-only
	boolean bReadOnly = false;
	boolean bFound = false;
	for (int i=0; i<teamIdList.length; i++)
	{
		if (((Integer)teamIdList[i]).intValue() == myUid)
		{
			bFound = true;	// I am a team member
			break;
		}
	}
	if (!bFound && ((iRole & user.iROLE_DIRECTOR)==0 && (iRole & user.iROLE_PROGMGR)==0) && !isAdmin && projIdS!=null)
	{
		bReadOnly = true;
	}

	// get the weblog (result) objects associated to this project (TaskID is used to
	// store ProjID or TownID or TaskID.  It all depends on the Type attribute.
	if (isBugBlog)
		resultIds = rMgr.findId(pstuser, "(TaskID='" + bugIdS + "') && (Type='" + result.TYPE_BUG_BLOG + "')");	//use task id to store bug id
	else if (isActnBlog)
		resultIds = rMgr.findId(pstuser, "(TaskID='" + aIdS + "') && (Type='" + result.TYPE_ACTN_BLOG + "')");	//use task id to store bug id
	else if (isProjectBlog) {
		// TaskID='%' means no comment blog
		//resultIds = rMgr.findId(pstuser, "(ProjectID='" + projIdS + "') && (Type='" + result.TYPE_TASK_BLOG + "') && (TaskID == '%')");
		resultIds = rMgr.findId(pstuser, "(ProjectID='" + projIdS + "') && (Type='" + result.TYPE_PROJ_BLOG + "')");
	}
	else
		resultIds = rMgr.findId(pstuser, "(TaskID='" + taskIdS + "') && (Type='" + result.TYPE_TASK_BLOG + "')");

	
	// it should already be sorted in descending order, but do it just for safety
	Util.sort(resultIds, true);
	
	// limit the display to MAX_DISPLAY
	if (resultIds.length > MAX_DISPLAY) {
		// limit # of blogs to get
		l.info("Too much to display, only displaying " + MAX_DISPLAY + " of "
						+ resultIds.length + " blogs.");
		resultIds = Arrays.copyOf(resultIds, MAX_DISPLAY);
		//resultIds = Util2.shortenPstArray(resultIds, MAX_DISPLAY);
	}

	// sort the result by create date.  Display latest postings first
	PstAbstractObject [] blogList = rMgr.get(pstuser, resultIds);
	
	if (!isProjectBlog) {
		Util.sortDate(blogList, "CreatedDate", true);
	}
	else {
		// all project blog listing: need to sort by comment dates
		// build a TreeMap (sorted) of <CommentCreateDate, blog>
		TreeMap<Long, PstAbstractObject> m = getTreeMap(pstuser, blogList, projIdS);
		blogList = m.values().toArray(new PstAbstractObject[0]);
		//Collections.reverse(Arrays.asList(blogList));
	}
	

	// @ECC022606
	boolean bSendTeamNotification = false;
	if (optStr!=null && optStr.indexOf(project.OP_NOTIFY_BLOG)!=-1)
		bSendTeamNotification = true;

	// @ECC090605
	boolean isListening = false;
	int listenNum = 0;
	if (!bSendTeamNotification)
	{
		String myUidS = String.valueOf(myUid);
		Object [] objIds;
		String listen = request.getParameter("listen");
		if (listen == null)
		{
			if (!isProjectBlog) {
				// check to see if I am currently listening this task
				objIds = obj.getAttribute("Listen");
				if (objIds[0] != null) {
					listenNum = objIds.length;
					for (int i=0; i<objIds.length; i++) {
						if (myUidS.equals(objIds[i])) {
							isListening = true;
							continue;
						}

						// cleanup for task object
						// check to see if this listener is authorized (team member),
						// if not, remove him
						bFound = false;
						for (int j=0; j<teamIdList.length; j++) {
							if (((Integer)teamIdList[j]) == Integer.parseInt((String)objIds[i])) {
								bFound = true;
								break;
							}
						}
						if (!bFound) {
							listenNum--;
							obj.removeAttribute("Listen", objIds[i]);
							mgr.commit(obj);	// not a team member, remove him															
						}
					}
				}
			}
		}
		else if (listen.equals("true"))
		{
			// I want to listen to this task/bug blog
			obj.appendAttribute("Listen", myUidS);
			mgr.commit(obj);
			listenNum = obj.getAttribute("Listen").length;
			isListening = true;
		}
		else if (listen.equals("false"))
		{
			// I don't want to listen to this task/bug anymore
			obj.removeAttribute("Listen", myUidS);
			mgr.commit(obj);
			objIds = obj.getAttribute("Listen");
			if (objIds[0] != null)
				listenNum = objIds.length;
		}
	}
	// @ECC090605 End
	boolean bCanPostNew = !bReadOnly;	// && !isProjectBlog;
	
	// check to see if project block posting option is on
	boolean bBlockPosting = false;
	if (projObj != null) {
		if (projObj.getOption(project.OP_NO_POST) != null) {
			bBlockPosting = true;
		}
	}
	
	s = request.getParameter("showEd");
	String showEditorS = (s!=null && s.equals("1")) ? "block" : "none";

%>


<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen" />
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print" />
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../errormsg.jsp" flush="true"/>
<script language="JavaScript" src="../ep/event.js"></script>
<script language="JavaScript" src="../ep/chat.js"></script>
<script type="text/javascript" src="../resize.js"></script>
<script type="text/javascript" src="<%=host%>/FCKeditor/fckeditor.js"></script>

<script language="JavaScript">
<!--
var oFCKeditor;
var uid = "<%=myUid%>";
frame = "parent";			// define in event.js
isCPM = <%=isPRM%>;			// define in event.js

window.onload = function()
{
	if (<%=isPDA%> == false) {
	
		// to enable dragging editor box
		oFCKeditor = new FCKeditor( 'logText', null, '300' ) ;
		oFCKeditor.ReplaceTextarea() ;
		initDrag(300);
		setTextBoxId('logText');
		new dragObject(handleBottom[0], null, new Position(0, beginHeight), new Position(0, 800),
						null, BottomMove, null, false, 0);
	}
	
	var fullURL = parent.document.URL;
	var idx = fullURL.indexOf("#com_"); 
	if (idx != -1) {
		blogId = fullURL.substring(idx+5)
		showComment(blogId);
	}
}

function validation()
{
	document.getElementById("cancelBut").disabled = true;
	document.getElementById("submitBut").disabled = true;
	addWeblog.submit();
}

function view_archive(e)
{
	var fname = e.options[e.selectedIndex].value;
	if (fname != "")
		location= '<%=host%>' + '/servlet/ShowFile?archiveFile=' + fname;
	return;
}

function skype(skypeName, fullName)
{
	if (skypeName == 'null')
		alert('Sorry!  The user ' + fullName + ' has not entered a Skype Name yet.');
	else
		location.href= 'skype:' + skypeName;
}

function showComment(id)
{
	var e = document.getElementById("com_"+id);
	if (e.style.display == 'block') {
		e.style.display = 'none';
	}
	else {
		e.style.display = 'block';
		location = '#com_' + id;	// jump to comment part
	}
}

function showEditor()
{
	var e = document.getElementById('editorPanel');
	if (e.style.display == 'block') {
		e.style.display = 'none';
		// expand to the big page
		//location = "addblog.jsp?type=<%=type%>&id=<%=idS%>&backPage=blog_task.jsp?projId=<%=projIdS%>:taskId=<%=idS%>";
		location = "addblog.jsp?type=<%=type%>&id=<%=idS%>&backPage=<%=backPage%>";
		return;
	}
	else {
		// check if posting is block
		if (<%=bBlockPosting%>) {	// MSG.5004
			location = "../out.jsp?go=project/proj_top.jsp&msg=Posting to this project is not allowed.  Please contact the project coordinator if you have any questions.";
			return;
		}
		
		e.style.display ='block';
	}
}
//-->
</script>

<title>
	<%=Prm.getAppTitle()%> <%=title%>
</title>

</head>

<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">
		<!-- Main Tables -->
		<table width="100%" border="0" cellspacing="0" cellpadding="0">
		  	<tr>
		    	<td width="100%" valign="top">
					<!-- Top -->
					<jsp:include page="../head.jsp" flush="true"/>
					<!-- End of Top -->
				</td>
			</tr>
		</table>
		
<table width="90%" border="0" cellspacing="0" cellpadding="0">
			<tr>
	          <td>
	            <table width="100%" border="0" cellspacing="0" cellpadding="0">
					<tr>
					<td width="15"><a name="top">&nbsp;</a></td>
					<td width="430" height="30" align="left" valign="bottom" class="head">
						<b><%=title%></b>
					</td>

<!-- @ECC090605 -->
					<td width='300' valign="top" align='right' class="formtext">
<% 	if (!isOMFAPP){
		if (bSendTeamNotification) {%>
					This blogging page is listened to by the project team
<% 		}
		else if (!isProjectBlog) { /*1*/ %>
					This blogging page is listened to by <%=listenNum%> person(s)<br/>
					<img src="../i/bullet_tri.gif" width="20" height="10"/>
<% 			if (isListening)
			{%>
					<a class="listlinkbold" href="blog_task.jsp?projId=<%=projIdS%>&planTaskId=<%=pTaskIdS%>&bugId=<%=bugIdS%>&aid=<%=aIdS%>&listen=false">
					Remove from my blog listening list</a>
<% 			}
			else 
			{ /*2*/ %>
					<a class="listlinkbold" href="blog_task.jsp?projId=<%=projIdS%>&planTaskId=<%=pTaskIdS%>&bugId=<%=bugIdS%>&aid=<%=aIdS%>&listen=true">
					Listen to blogs on this page</a>
<% 			} /*2*/
  		} /*1*/
   }%>
					</td>
<!-- @ECC090605 End -->



	              </tr>
	            </table>
	          </td>
	        </tr>
			<tr>
          		<td width="100%">
					<!-- Navigation Menu -->
<%
	if (isOMFAPP){%>
					<jsp:include page="../in/imtg.jsp" flush="true">
					<jsp:param name="role" value="<%=iRole%>" />
					</jsp:include>
<%	}
	else
	{
		int iBlogType = 0;
		if (isProjectBlog) iBlogType = 0;
		else if (isTaskBlog) iBlogType = 1;
		else if (isBugBlog) iBlogType = 2;
		else if (isActnBlog) iBlogType = 3;
		else iBlogType = 4;
%>
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Project" />
				<jsp:param name="subCat" value="ProjectBlog" />
				<jsp:param name="role" value="<%=iRole%>" />
				<jsp:param name="blogType" value="<%=iBlogType%>" />
				<jsp:param name="projId" value="<%=projIdS%>" />
				<jsp:param name="taskId" value="<%=taskIdS%>" />
			</jsp:include>
<%	}%>
<!-- End of Navigation SUB-Menu -->
				</td>
	        </tr>
		</table>
</td>
</tr>

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<table width='90%' border='0'>
	<tr>

<!-- Display Project Name -->
<%	if (isProjectBlog) { %>
	<td>
	<table border='0'>
	<tr><td><img src="../i/spacer.gif" height="5" width="20" /></td>
	<td width='450' class="heading">
<form>
		Project Name&nbsp;&nbsp;
		<select name="projId" class="formtext" onchange="submit()">
<%
		out.print(Util.selectProject(pstuser, projId));
%>
		</select>
			
		
</form>
	</td></tr>
	<tr><td colspan='2'><img src='../i/spacer.gif' height='15'/></td></tr>

<%	} else { %>
	<td width="450" valign="top">
	<table border='0'>
	<tr><td width='20'><img src="../i/spacer.gif" height="5" width="20" /></td><td></td></tr>
	<tr><td></td><td valign="top" class="title"><%=projName%></td>
	</tr>
<%	} %>


	<tr>
<%
	if (isTaskBlog) {%>
		<td>&nbsp;</td>
		<td><table border='0' cellspacing='0' cellpadding='0'><tr><td class='plaintext_grey'>
		<%=stackName%>
		</td></tr>
		</table>
		</td>
<%	}
	else if (!isProjectBlog)
	{%>
		<td></td>
		<td><table><tr>
			<td class="subtitle" valign='top' width='15'>&nbsp;&nbsp;&nbsp;>></td>
			<td class="subtitle"><%=synopsis%></td>
		</tr></table></td>
<%	}%>
	</tr>
	</table>
	</td>

	<td width='200'>
	<table cellspacing="0" cellpadding="0">
	
<%
	if (type.equals(result.TYPE_BUG_BLOG)) {
		out.print("<tr><td valign='middle'><br/>");
		out.print("<img src='../i/bullet_tri.gif' width='20' height='10'>");
		out.print("<a class='listlinkbold' href='../bug/bug_update.jsp?bugId=" + bugIdS + "'>Go to this CR</a>");
		out.print("</td></tr>");
	}
	else if (type.equals(result.TYPE_ACTN_BLOG)) {
		out.print("<tr><td valign='middle'><br/>");
		out.print("<img src='../i/bullet_tri.gif' width='20' height='10'>");
		out.print("<a class='listlinkbold' href='../meeting/upd_action.jsp?pid=" + projIdS
				+ "&oid=" + aIdS + "&type=Action'>Go to this Action Item</a>");
		out.print("</td></tr>");
	}
%>
	
	<tr><td valign="middle">
<%	if (bCanPostNew) {%>
		<img src="../i/bullet_tri.gif" width="20" height="10"/>
		<a class="listlinkbold" href="javascript:showEditor();">
		New Post</a>
<%	}%>
	</td></tr>

	<tr><td valign="bottom">
<form name='ArchiveForm'>
		<img src="../i/bullet_tri.gif" width="20" height="10"/>
	<select name="archive" onchange="view_archive(document.ArchiveForm.archive)">
		<option class="formtext" value="" selected>-- view archive --</option>
<%
		String [] st;
		String range;

		Object [] archives = obj.getAttribute("Archive");
		sortArchives(archives);
		for (int i=archives.length-1; i>=0; i--)
		{
			String arc = (String)archives[i];
			if (StringUtil.isNullOrEmptyString(arc)) continue;
			st = arc.split(":");
			range = st[0];
			out.print("<option class='formtext' value='" + st[1] + "'>" + range + "</option>");
		}
%>
	</select>
</form>
	</td></tr>
	</table>
	</td>
	</tr>

	</table>

<!-- Panel for editor -->
	<div id='editorPanel' style='display:<%=showEditorS%>;'>
	<form name="addWeblog" action="../blog/post_addblog.jsp" method="post">
		<input type="hidden" name="type" value="<%=type%>" />
		<input type="hidden" name="id" value="<%=idS%>"/>
		<input type="hidden" name="cont" value="" />
		<input type="hidden" name="backPage" value="<%=backPage%>"/>

	<table width='90%' border='0' cellspacing='0' cellpadding='0'>
	    <tr>
	    <td width='20'></td>
		<td>
			<div id='textDiv'>
				<textarea name="logText" id='logText' rows=10; style='width:90%'>
					<%=blogTemplateText%></textarea>
			</div>
			<div align='right'>
			<span id="handleBottom" ><img src='../i/drag.gif' style="cursor:s-resize;"/></span>
			<span><img src='../i/spacer.gif' width='20' height='1'/></span>
			</div>
		</td>
	    </tr>
<%
	// option to email or suppress
	if (bCanPostNew
			&& (isTaskBlog || isMtgBlog || isActnBlog || isQuestBlog || isCircleBlog || isBugBlog)) {
		String checkStr = "";
		if (projObj != null) {
			checkStr = projObj.getOption(project.OP_NOTIFY_BLOG)!=null?"checked":"";
		}
		out.print("<tr><td></td><td class='plaintext_big'>");
		out.print("<input type='checkbox' name='sendEmail' " + checkStr);
		out.print(">&nbsp;Send Email notification to ");
		if (isMtgBlog)
			out.print("meeting members");
		else if (isActnBlog)
			out.print("action item responsible members");
		else if (isQuestBlog)
			out.print("event/survey participants");
		else if (isCircleBlog)
			out.print("circle members");
		else	// isTaskBlog or isBugBlog
			out.print("team members");
			
		// I need the following because checkbox returns null in post page if it is uncheck
		out.print("<input type='hidden' name='overrideSendEmail' value='true'>");
		out.print("</td></tr>");
		
		// for Bug ticket, send email to submitted user
		if (bugEmail2 != null) {
			out.print("<tr><td></td><td class='plaintext_big'>");
			out.print("<input type='checkbox' name='sendEmail2' checked");
			out.print(">&nbsp;Send Email notification to ticket submitter: " + bugEmail2);
			out.print("<input type='hidden' name='overrideSendEmail2' value='true'>");
			out.print("</td></tr>");
		}
	}
%>

		<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>

		<tr><td></td>
		<td align="center">
			<input type='button' id='submitBut' class='button_medium' onclick='return validation();' value='Submit'/>
			<input type='button' id='cancelBut' class='button_medium' onclick='javascript:showEditor();' value='Cancel'/>&nbsp;
		</td></tr>

		<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>
		
	</table>
    </form>
	</div>


	<table width='90%' border='0' cellspacing='0' cellpadding='0'>
	    <tr>
	    <td width='20'></td>
		<td class='headlinerule'><img src='../i/spacer.gif' height='1' width='1' /></td>
	    </tr>
	</table>



<!-- CONTENT LEFT -->
<table width="100%" border="0" cellspacing="0" cellpadding="0">

<tr>

	<td width="70%" valign="top">


<!-- DISPLAY WEBLOG min height set to 110 -->
<table height="110" width="100%">

<tr>
	<td width="20"><img src="../i/spacer.gif" height="1" width="20" /></td>

	<td valign="top">

<%
	try {out.println(result.displayBlog(
			pstuser, blogList, type, idS, idS2,
			blogIdS, projCoordinatorId, townIdS, projIdS,
			taskIdS, aIdS, backPage, isAdmin, false));
	}
	catch (Exception e) {}

%>

	</td>

	<td width="5">&nbsp;</td>
</tr>
</table>
</td>
<%
	if (!isOMFAPP){
%>
<td class="headlinerule">
	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="100" width="1" alt=" " /></td>
	    </tr>
	</table>
</td>

<td valign="top">
	<table><tr>
	<td width="3">&nbsp;</td>
	<td>
	<div class="namelist_hdr">The Project Team&nbsp;
		(<%=totalTeamMember%>)&nbsp;&nbsp;
		<a href="addalert.jsp?townId=<%=townIdS%>&projId=<%=projIdS%>&taskId=<%=taskIdS%>&backPage=<%=backPage%>">
		<img src="../i/eml.gif" border="0"></a><br><br></div>

<%	
	out.print(Util3.listTeamMembers(memberList, projCoordinatorId));

	// keep statistics
	Util.incUserinfo(pstuser, "ViewBlogNum");
%>

	</td>
	</tr></table>

</td>
<%
	}	// end if !isOMFAPP
	else
		out.println("<td colspan=2 width='200'>");
%>
</tr>

</table>


	</td>
</tr>

<tr><td>&nbsp;</td></tr>

<tr><td>


<!-- BEGIN FOOTER TABLE -->
<jsp:include page="/foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->
</td></tr>


<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

