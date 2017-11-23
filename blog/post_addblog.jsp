<%@ page contentType="text/html; charset=utf-8"%>

<%
////////////////////////////////////////////////////
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	post_addblog.jsp
//	Author:	ECC
//	Date:	03/18/04
//	Description:
//		Java to handle adding weblog (result) for bug, town, task and personal.  NO forum.
//	Modification:
//		@050605ECC	For PRM, support addblog of task and bug only. NO town, project, or forum.
//		@050705ECC	When adding comments, update the short lastest result.
//		@ECC090605	Support listening to bug/task blogs.
//		@ECC100605	Allow blog creator's manager to EDIT
//		@ECC102905	Support engineering logbook using blog to store contents.
//		@ECC022606	Support an option to turn on notification for all blogging in a project.
//		@ECC041006	Add blog support to action/decision/issue.
//		@AGQ041106	Fixed problem where blog removes the last char (e.g. "<ul>" becomes "<ul")
//		@ECC061206	Record project ID in the blog.
//		@AGQ072706	Escaped html special characters for comments to blogs
//		@ECC090806	Support forum blogging (Help forum).
//		@ECC110806a	Support meeting blog (id is the meeting ID)
//		@ECC101608	Private blog to personal.
//
////////////////////////////////////////////////////////////////////
%>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.PepCommentVector" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>
<%@ page import = "org.apache.log4j.Logger" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />


<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	// Add weblog.
	PstUserAbstractObject me = pstuser;
	if (me instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	Logger l = PrmLog.getLog();

	String NODE = Util.getPropKey("pst", "PRM_HOST");

	String s;
	int myUid = me.getObjectId();
	
	boolean isTicketSystem = (me.getObjectName().equalsIgnoreCase("ticket system"));
	
	// if coming in from subsystems such as Ticket or SAS, use this as creator
	// loginName is the actual frontline user's email, he might not be a CPM user
	String loginName = null;
	if (isTicketSystem)
		loginName = (String) session.getAttribute("loginName");

	// event flag
	s = Util.getPropKey("pst", "EVENT");
	boolean bSendEvent = (s!=null&&s.equalsIgnoreCase("true"))?true:false;

	String backPage = request.getParameter("backPage");
	String type = request.getParameter("type");		// Project, Task, Bug, Action, Personal, Forum, Meeting
	String idS = request.getParameter("id");		// task (task blog), bugId (bug blog), user id-might be null: will be filled later (logbook), projObj, town id
	if (idS!=null && idS.equals("null")) idS = null;
	String text = request.getParameter("logText");
	if (text == null) text = "";
	text = text.trim();
	text = text.replaceAll("&nbsp;(\\s)*&nbsp;", "&nbsp;");
	text = text.replaceAll("  ( )+", " ");
	if (text.length() <= 0) {
%>
<script language="JavaScript">
	history.back(-1);
</script>

<%
		return;
	}

	townManager tnMgr = townManager.getInstance();
	projectManager pjMgr = projectManager.getInstance();
	taskManager tMgr = taskManager.getInstance();
	resultManager rMgr = resultManager.getInstance();
	latest_resultManager lrMgr = latest_resultManager.getInstance();
	actionManager aMgr = actionManager.getInstance();
	meetingManager mtgMgr = meetingManager.getInstance();
	questManager qMgr = questManager.getInstance();
	userManager uMgr = userManager.getInstance();
	
	// change or keep the creation date
	s = request.getParameter("keepDate");
	boolean bKeepDate = (s!=null && s.equals("1"));
	
	// plaintext needs to replace "\n" with "<br>"
	s = request.getParameter("plainText");
	boolean bPlainText = (s!=null && s.equalsIgnoreCase("true"));
	if (bPlainText) {
		//text = text.replaceAll("\n","<br/>");
		text = text.replaceAll(" ", "&nbsp;");
	}
	

	// if the blog text is not HTML, then convert all "\n" to <p>
	if (text.indexOf("<p>")==-1 && text.indexOf("<span")==-1) {
		text = text.replaceAll("\n", "<p>");
	}


	String cont = request.getParameter("cont");
	boolean isContinue = cont!=null && cont.equals("true");
	String blogIdS = request.getParameter("update");
	if (blogIdS!=null && blogIdS.equals("none"))
	{
		// need to create: the param was there as a placeholder, will be replaced later
		blogIdS = null;
	}

	// @ECC101608
	boolean isPrivate = false;
	s = request.getParameter("private");
	if (s!=null && s.equals("true"))
		isPrivate = true;
	
	// isSendEmail can be null, True or False
	Boolean isSendEmail = null;		// may not be set at all
	// overrideSendEmail is NOT a check box, it is a hidden type
	s = request.getParameter("overrideSendEmail");
	if (s != null) {
		// need to check the checkbox
		s = request.getParameter("sendEmail");	// this is the checkbox
		if (s!=null && s.equals("on"))
			isSendEmail = true;
		else
			isSendEmail = false;
	}
	
	// isSendEmail2: whether user want to trigger email to Email2 (end user submitter)
	boolean isSendEmail2 = false;		// cannot be null
	// overrideSendEmail2 is NOT a check box, it is a hidden type
	s = request.getParameter("overrideSendEmail2");
	if (s != null) {
		// need to check the checkbox
		s = request.getParameter("sendEmail2");	// this is the checkbox
		if (s!=null && s.equals("on"))
			isSendEmail2 = true;
		else
			isSendEmail2 = false;
	}
	
	// isSendEmailSel can be null, True or False
	Boolean isSendEmailSel = false;		// may not be set at all
	// overrideSendEmail is NOT a check box, it is a hidden type
	s = request.getParameter("overrideSendEmailSel");
	if (s != null) {
		// need to check the checkbox
		s = request.getParameter("sendEmailSel");	// this is the checkbox
		isSendEmailSel = (s!=null && s.equals("on"));
	}
	
	s = request.getParameter("sendEmailToAuthor");
	boolean bSendEmailToAuthor = (!StringUtil.isNullOrEmptyString(s) && s.equals("on")) || isSendEmailSel;
	
	// other email address
	String [] emailArr = null;
	PstAbstractObject uObj;
	s = request.getParameter("otherEmail");
	if (s != null) {
		s = s.trim().replaceAll(";", ",");
		String [] sa = s.trim().split(",");
		// change all username into email
		ArrayList <String> al = new ArrayList <String> ();
		for (int i=0; i<sa.length; i++) {
			s = sa[i].trim();
			if (StringUtil.isNullOrEmptyString(s)) continue;
			if (s.indexOf('@') != -1) {
				// this is already in email format
				al.add(s);
				continue;
			}
			try {
				uObj = uMgr.get(me, s);
				al.add(uObj.getStringAttribute("Email"));
			}
			catch (PmpException e) {}	// user not found
		}
		if (al.size() > 0) emailArr = al.toArray(new String[0]);
	}
	
	boolean bUpdate = (blogIdS != null);
	String parentIdS = null;						// only set for adding comment to blog
	bug bugObj = null;
	bugManager bugMgr = null;
	PstAbstractObject obj = null;					// bug or task for sending email to listener
	String projIdS = null;
	town tn = null;
	Date now = new Date();
	project projObj = null;
	boolean bSendTeamNotification = false;			// @ECC022606
	String projName = "";
	boolean isMyPage = false;
	String bugSynopsis = "";
	String bugEmail2 = null;

	// forum blog is used to support blog on circle.  In which case the idS!=null and store the town Id
	boolean isBugBlog = false, isTaskBlog = false, isEngrBlog = false, isActnBlog = false,
		isFrumBlog = false, isMtgBlog = false, isQuestBlog = false, isProjBlog = false;
	
	int [] sameCircleUidArr = null;		// for forum blog trigger event and send Email
	PstAbstractObject forumCircle = null;

	// type can be Town, Project, Task, Bug, Action or Personal
	if (type.equals(result.TYPE_PROJ_BLOG))
	{
		projObj = (project)pjMgr.get(me, Integer.parseInt(idS));
		projObj.setAttribute("LastUpdatedDate", now);
		pjMgr.commit(projObj);
		tn = (town)tnMgr.get(me, Integer.parseInt((String)projObj.getAttribute("TownID")[0]));
		projIdS = idS;
		isProjBlog = true;
	}
	else if (type.equals(result.TYPE_ENGR_BLOG))
	{
		// @ECC102905
		isEngrBlog = true;		// Personal blog
		if (idS == null)
		{
			isMyPage = true;
			idS = String.valueOf(myUid);
		}
		else if (Integer.parseInt(idS) == myUid)
			isMyPage = true;

		parentIdS = request.getParameter("parentId");	// might be adding comments to blog
	}
	else if (type.equals(result.TYPE_TASK_BLOG)
			|| type.equals(result.TYPE_BUG_BLOG)
			|| type.equals(result.TYPE_ACTN_BLOG)
			|| type.equals(result.TYPE_FRUM_BLOG)
			|| type.equals(result.TYPE_MTG_BLOG)
			|| type.equals(result.TYPE_QUEST_BLOG)
			)
	{
		// get ready to send notifiation email
		
		parentIdS = request.getParameter("parentId");	// might be adding comments to blog
		//if (parentIdS != null)
		//	text = text.replaceAll("\n","<br>");

		// get ready to insert a short description into bug history
		if (type.equals(result.TYPE_MTG_BLOG))
		{
			obj = mtgMgr.get(me, idS);
			isMtgBlog = true;
		}
		else if (type.equals(result.TYPE_BUG_BLOG))
		{
			bugMgr = bugManager.getInstance();
			bugObj = (bug)bugMgr.get(me, idS);
			obj = bugObj;
			bugSynopsis = (String)obj.getAttribute("Synopsis")[0];
			if (isSendEmail2)
				bugEmail2 = bugObj.getStringAttribute("Email2");
			isBugBlog = true;
		}
		else if (type.equals(result.TYPE_TASK_BLOG))
		{
			obj = tMgr.get(me, idS);		// idS is the task ID
			isTaskBlog = true;
		}
		else if (type.equals(result.TYPE_ACTN_BLOG))
		{
			obj = aMgr.get(me, idS);
			isActnBlog = true;
		}
		else if (type.equals(result.TYPE_QUEST_BLOG))
		{
			obj = qMgr.get(me, idS);
			isQuestBlog = true;
		}
		else
		{
			obj = null;		// forum case
			if (idS != null) {
				forumCircle = tnMgr.get(me, Integer.parseInt(idS));
				sameCircleUidArr = uMgr.findId(me, "Towns=" + idS);
			}
			isFrumBlog = true;
		}

		// @ECC022606 find out if this project requires sending notification on blog
		if (obj != null)
			projIdS = (String)obj.getAttribute("ProjectID")[0];
		if (projIdS != null)
		{
			projObj = (project)pjMgr.get(me, Integer.parseInt(projIdS));
			
			// check to see if project block posting option is on
			if (projObj != null) {
				if (projObj.getOption(project.OP_NO_POST) != null) {
					response.sendRedirect("../out.jsp?msg=5004&go=project/proj_top.jsp");
					return;
				}
			}

			projName = projObj.getDisplayName();
			
			// check for override
			s = request.getParameter("forceSendEmail");			
			if ( s!=null && (s.equalsIgnoreCase("true") || s.equalsIgnoreCase("false")) ){
				// override project option
				bSendTeamNotification = s.equalsIgnoreCase("true");
			}
			else {
				if (projObj.getOption(project.OP_NOTIFY_BLOG) != null) {
					bSendTeamNotification = true;
				}
			}
		}
		
		// the following is used by addblog.jsp to override taskBlog send email
		if (isSendEmail != null) {
			bSendTeamNotification = isSendEmail.booleanValue();
		}
	}
	else if (type.equals("Town"))
	{
		// must be town weblog
		tn = (town)tnMgr.get(me, Integer.parseInt(idS));
	}
	else
	{
		response.sendRedirect("../out.jsp?e=Wrong blog type");
		return;
	}

	// last update date for town
	//tn.setAttribute("LastUpdatedDate", now);
	//tnMgr.commit(tn);

	String updatorIdS;
	if (loginName == null)
		updatorIdS = String.valueOf(myUid);
	else {
		// Ticket system or SAS
		try {
			PstAbstractObject u = uMgr.get(me, loginName);
			updatorIdS = String.valueOf(u.getObjectId());
		}
		catch (PmpException e) {
			/*response.sendRedirect("../out.jsp?e=Invalid subsystem login. Login name = "
				+ loginName);
			return;*/
			updatorIdS = String.valueOf(myUid);
		}
	}

	String myName = ((user)me).getFullName();
	SimpleDateFormat df = new SimpleDateFormat ("MMMMMMMM dd, yyyy (EEE) hh:mm a");
	userinfo.setTimeZone(me, df);
	String nowS = df.format(now);


	// replace "\n" with <br>
	// text = text.replaceAll("\n", "<br>");

	// handle comments on result and latest_result
	result blogObj = null;
	int [] ids;

	if (bUpdate)
	{
		blogObj = (result)rMgr.get(me, blogIdS);
		if (text.equals(""))
		{
			// delete this blog if content is wiped out (empty)
			if (!isContinue)
			{
				rMgr.delete(blogObj);

				// delete the comments
				ids = rMgr.findId(me, "ParentID='" + blogIdS + "'");
				for (int i=0; i<ids.length; i++)
				{
					rMgr.delete(rMgr.get(me, ids[i]));
				}
			}
			else
			{
				// user just wipe out the text and click continue: can't delete blog but just wipe out
				blogObj.setAttribute("Comment", null);
				rMgr.commit(blogObj);
			}

			// always delete the attachment
			s = Util.getPropKey("pst", "FILE_UPLOAD_PATH");	// Repository/PRM
			s += File.separator + blogIdS;
			File f = new File(s);
			File [] fList = f.listFiles();
			if (fList != null)
			{
				for (int i=0; i<fList.length; i++)
					fList[i].delete();
			}
			f.delete();				// delete the blogId directory
		}
		else
		{
			// update
			// @AGQ041206 remove extra spaces
			text = text.replaceAll("(<div [^>]*id=['|\"]del['|\"].*</div>)", "");			// remove <div id='del' ...> ... </div>
			text = text.replaceAll("(<span[^>]*></span>)|(<font[^>]*></font>)", "");
			text = text.replaceAll("<br />", "");
			text = text.replaceAll("(<(p|P)[^>]*>((&nbsp;)|( ))*</(p|P)>)", "").trim();		// <br>
			//text = text.replaceAll(PrmMtgConstants.REGEX, "<br>").trim();		//"(<p>[(&nbsp;) ]*</p>)|[<br /></p>]*$" //("<p>[(&nbsp;) ]*</p>$", "");
			blogObj.setAttribute("Comment", text.getBytes("UTF-8"));
			//blogObj.setAttribute("Creator", updatorIdS);		// @ECC100605
			s = request.getParameter("title");
			if (s != null)
				blogObj.setAttribute("Name", s);				// allow updating blog subject
		}
	}
	else if (text != null && !text.equals(""))
	{
		// *** ADD a NEW blog or a NEW comment
		// create a new result object and insert the data
		blogObj = (result)rMgr.create(me);
		blogIdS = String.valueOf(blogObj.getObjectId());	// for save and cont's backPage
		// @AGQ041206 remove extra spaces
		text = text.replaceAll(PrmMtgConstants.REGEX, " ").trim();		//"(<p>[(&nbsp;) ]*</p>)|[<br /></p>]*$" // ("<p>[(&nbsp;) ]*</p>$", "");
		
		blogObj.setAttribute("CreatedDate", now);		// new blog
		blogObj.setAttribute("Creator", updatorIdS);
		blogObj.setAttribute("Type", type);
		blogObj.setAttribute("ProjectID", projIdS);						// @ECC061206

		if (parentIdS == null)
		{
			if (idS != null) 	//(!isFrumBlog)
			{
				blogObj.setAttribute("TaskID", idS);	// can be taskId, bugId, mtgId, userId, projId, townId (null for forum)
			}
			if (isFrumBlog || isMtgBlog)
			{
				// Forum or meeting blog: save the title into Name attribute
				s = request.getParameter("title");
				if (s != null)
				{
					blogObj.setAttribute("Name", s);
					if (!isContinue) {
						backPage = "blog_comment.jsp?blogId=" + blogIdS + ":type=" + type;	// always go to blog_comment
						if (isMtgBlog)
							backPage += ":id=" + idS;
					}
				}
			}
		}
		else
		{
			blogObj.setAttribute("ParentID", parentIdS);
		}
		blogObj.setAttribute("Comment", text.getBytes("UTF-8"));
	}
	
	if (text.equals(""))
		text = null;			// blog is deleted
	
	// ECC: this is only implemented for MeetWE in my_page.jsp only
	// nice feature, should do it in result.displayBlog() also.
	boolean bSharedBlog = text.startsWith("!#");

	if (isEngrBlog)
	{
		// @ECC101608 personal blog and only viewed by owner
		if (isPrivate)
		{
			blogObj.appendAttribute("ShareID", String.valueOf(myUid));		// always allow author to access
			if (idS!=null && Integer.parseInt(idS)!=myUid)
				blogObj.appendAttribute("ShareID", idS);					// owner of the page
		}
		else
			blogObj.setAttribute("ShareID", null);							// wipe out
	}

	// ***** COMMIT the new or updated blog here *****
	String shortText = "";		// include the firstName::
	String bugShortText = "";	// w/o firstName::
	String stripText = null;
	if (text != null)
	{
		if (!bKeepDate)
			blogObj.setAttribute("CreatedDate", now);			// even update blog will reset date now
		rMgr.commit(blogObj);

		// only need short text (1-liner) for task blog and bug blog (activity history)
		if (isTaskBlog || isBugBlog)
		{
			stripText = result.stripText(text, 300);
			bugShortText = stripText;							// for bug activity history
			shortText = result.getShortText(me, stripText);
		}
	}
	else if (cont!=null && cont.equals("true") && blogIdS==null)
	{
		// click continue when there is no text: just create blog
		blogObj = (result)rMgr.create(me);
		blogObj.setAttribute("CreatedDate", now);			// it's a newly created blog
		rMgr.commit(blogObj);
		blogIdS = String.valueOf(blogObj.getObjectId());	// for save and cont's backPage
	}

	// Latest result (1 line description of the blog)
	// create or update the latest_result object associated to this blog
	// for adding comment, update the latest result to indicate no. of comment
	// note: TaskID here is used to store BugID or TaskID (also TownID and ProjID)
	planTask planTaskObj = null;
	String pTaskIdS = null;
	if (isTaskBlog)
	{
		if (stripText!=null)
		{
			result.createOneLiner(me, idS, blogIdS, shortText, parentIdS, bUpdate);
		}
		session.removeAttribute("planStack");		// cleanup cache for task blog

		// get plantask for trigger event and email below
		planTaskObj = planTask.getPlanTaskFromTask(me, idS);
		pTaskIdS = planTaskObj.getObjectName();
	}

	// add description to bug history if it is a newly post blog
	// don't do it if it is only adding a comment to the blog
	if ( (isBugBlog || isEngrBlog) && parentIdS==null && stripText!=null)
	{
		// adding comment to bug history (description)
		if (bugShortText.length() > result.BUG_LRESULT_LENGTH)
			bugShortText = bugShortText.substring(0, result.BUG_LRESULT_LENGTH);
		bugShortText = "<a class='listlink'  href='../blog/blog_task.jsp?projId="+projIdS
			+ "&bugId=" + idS + "#" + blogObj.getObjectId() + "'>" + bugShortText + "</a>";
		bugObj.addCommentHistory(me, bugShortText);	// this call will commit
	}

	// although this blog existed (bUpdated), it might only because an upload file has occured
	if (bUpdate)
	{
		s = (String)blogObj.getAttribute("Status")[0];
		if (s!=null && s.equals("New"))
		{
			bUpdate = false;						// so that i will trigger event and email below
			blogObj.setAttribute("Status", null);	// clear the status attr
			rMgr.commit(blogObj);
		}
	}

	// support save and continue
	if (cont!=null && cont.equals("true"))
	{
		backPage = backPage.replaceAll("::", "&");
		backPage = backPage.replaceAll("none", blogIdS);
	}
	else
	{
		// back to blog_task.jsp, worktray.jsp
		backPage = backPage.replaceAll(":", "&");
		backPage = backPage.replace('@', '#');

		// keep statistics
		Util.incUserinfo(me, "WriteBlogNum");
	}

	// post comment: tell the blog creator and all the responders
	int orgBlogCreatorId = 0;
	user orgBlogCreator = null;
	PstAbstractObject o = null;
	if (parentIdS != null) {
		o = rMgr.get(me, parentIdS);	// the parent blog object
		orgBlogCreatorId = Integer.parseInt((String)o.getAttribute("Creator")[0]);
		orgBlogCreator = (user)uMgr.get(me, orgBlogCreatorId);
	}

	/////////////////////////////////////////////////////////////
	// trigger event
	
	// shared blog, not text display
	if (bSharedBlog) text = "Shared blog ";
	
	// type is the event type
	
	String originalText = text;
	if (bSendEvent && (isEngrBlog || (isFrumBlog && idS!=null) || isMtgBlog
			|| isTaskBlog || isActnBlog || isQuestBlog || isFrumBlog || isBugBlog)
			&& !bUpdate )
	{
		// check for restricted task folder
		boolean bRestrictiveTask = false;
		if (isTaskBlog) {
			s = Util2.getAttributeString(obj, "TeamMembers", ";");
			bRestrictiveTask =  (s.length() > 0);
		}
		
		// trigger an event based on blog type
		if (!bRestrictiveTask)
		    result.triggerEvent(me, obj, null, text, bugSynopsis, type,
		    		parentIdS, blogIdS, projIdS, pTaskIdS, idS, isMyPage, isPrivate);

	}	// END: trigger event if !bUpdate

	// @ECC090605 Send email to all who listen to blogs (Listen is on bug or task object)
	// do not send email if it is only an update
	if (isTaskBlog || isBugBlog || isMtgBlog || isActnBlog || isQuestBlog || isFrumBlog)	//(!isEngrBlog && !isFrumBlog && !isMtgBlog)
	{
		Object [] userIdArr = null;
		Object [] alertArr = null;
		if (isTaskBlog) {
			userIdArr = obj.getAttribute("Listen");
			alertArr = obj.getAttribute("Alert");
		}
		else if (isBugBlog) {
			userIdArr = obj.getAttribute("Listen");
		}
		

		if (!bUpdate &&
			( bSendTeamNotification || isSendEmailSel || bSendEmailToAuthor || isSendEmail2
				|| (userIdArr!=null && userIdArr[0]!=null)
				|| (alertArr!=null && alertArr[0]!=null)
				|| (emailArr != null)
			))
		{
			// either a new blog or add comment to a blog
			String MAILFILE = "alert.htm";
			String from = (String)me.getAttribute("Email")[0];
			String hyperTxt = "";
			String typeStr = "";
			String objLink = "";		// link to object like task, bug, meeting, action, etc.

			// get either the task name or the bug synopsis
			String lnkS = null;
			if (isBugBlog)
			{
				s = bugSynopsis;
				hyperTxt = "<b>" + bugSynopsis + "</b>";
				//lnkS = "&bugId=" + idS;
				lnkS = "&id=" + idS;
				typeStr = " the issue ";
				objLink = NODE + "/bug/bug_update.jsp?bugId=" + idS;
			}
			else if (isActnBlog)
			{
				s = (String)obj.getAttribute("Subject")[0];
				hyperTxt = "<b>" + s + "</b>";
				//lnkS = "&aid=" + idS;
				lnkS = "&id=" + idS;
				userIdArr = ((action)obj).getAllResponsible().toArray();
				typeStr = " the action ";
				if (projIdS != null)
					objLink = NODE + "/project/proj_action.jsp?projId=" + projIdS + "&aid=" + idS;
			}
			else if (isMtgBlog)
			{
				s = (String)obj.getAttribute("Subject")[0];
				hyperTxt = "<b>" + s + "</b>";
				//lnkS = "&aid=" + idS;
				lnkS = "&id=" + idS;
				userIdArr = ((meeting)obj).getAllAttendees().toArray();
				typeStr = " the meeting ";
				objLink = NODE + "/meeting/mtg_view.jsp?mid=" + idS + "#blog";
			}
			else if (isTaskBlog)
			{
				// need to get it from the planTask.  Use stack name.
				s = (String)planTaskObj.getAttribute("Name")[0];
				
				// this is a great way to display task stack names
				hyperTxt = projName + "<br>>> " + TaskInfo.getTaskStack(me, planTaskObj);
				int idx = hyperTxt.lastIndexOf(">>");
				hyperTxt = hyperTxt.substring(0, idx+2) + "<b>" + hyperTxt.substring(idx+2) + "</b>";
				
				lnkS = "&id=" + pTaskIdS;
				typeStr = " the task ";
				//objLink = NODE + "/project/task_update.jsp?projId=" + projIdS + "&taskId=" + idS;
				objLink = NODE + "/project/proj_plan.jsp?projId=" + projIdS + "&boTaskId=" + idS
						+ "&tree=expandALL#" + idS;
			}
			else if (isQuestBlog) {
				s = (String)obj.getAttribute("Subject")[0];
				hyperTxt = "<b>" + s + "</b>";
				lnkS = "&id=" + idS;
				userIdArr = obj.getAttribute("Attendee");
				typeStr = " the event/survey ";
				objLink = NODE + "/question/q_answer.jsp?qid=" + idS;
			}
			else if (isFrumBlog && forumCircle!=null) {
				s = forumCircle.getStringAttribute("Name");
				hyperTxt = "<b>" + s + "</b>";
				lnkS = "&id=" + idS;
				userIdArr = Util3.toInteger(sameCircleUidArr);
				typeStr = " the circle ";
				objLink = NODE + "/ep/my_page.jsp?uid=" + idS;
			}

			// link to the blog
			String blogLink = NODE + "/blog/blog_comment.jsp?blogId=" + ((parentIdS==null)?blogIdS:parentIdS) + "&projId="
								+ projIdS + lnkS + "&blogNum=" + blogIdS + "&type=" + type;
			if (backPage == null) {
				backPage = blogLink;
			}
			String subj = "[" + Prm.getAppTitle() + " Blog] (" + myName + ") " + s;
			if (!StringUtil.isNullOrEmptyString(projName))
				subj += " (" + projName + ")";
			String msg = myName + " has posted a new blog on " + nowS;
			msg += typeStr;
			msg += "<blockquote>" + myName + " has posted a new blog on " + typeStr + "<a href='"
				+ objLink + "'>" + hyperTxt + "</a>";
			if (!type.equals(result.TYPE_TASK_BLOG) && !StringUtil.isNullOrEmptyString(projName))
				msg += " (" + projName + ")";
			msg += "<br>>> <a href='" + blogLink + "'>Click to access the blog</a>";
			msg += "</blockquote>";

			if (isTaskBlog || isBugBlog || isActnBlog) {
				if (bSendTeamNotification) {
// ECC: changed to always include the content of the blog
					// @ECC022606 send notification to the whole team without the blog text
					if (isActnBlog) {
						// owner and responsible won't repeat
						ArrayList <Object> ar;
						if (userIdArr!=null && userIdArr.length>0 && userIdArr[0]!=null) {
							ar = new ArrayList <Object> (userIdArr.length + 1);
							ar.addAll(Arrays.asList(userIdArr));
						}
						else {
							ar = new ArrayList <Object> (1);
						}
						ar.add(projObj.getStringAttribute("Owner"));
						userIdArr = ar.toArray(new Object[0]);				// String array
					}
					else
						userIdArr = projObj.getAttribute("TeamMembers");	// Integer array

					//msg += "Please click the above link to see the blog or to post a response.";
					//Util.sendMailAsyn(me, from, userIdArr, null, null, subj, msg, MAILFILE);
				}
				else if (bSendEmailToAuthor) {
					// send the comment to the original blog author and myself
					if (orgBlogCreatorId == myUid) {
						userIdArr = new String [1];
						userIdArr[0] = String.valueOf(orgBlogCreatorId);
					}
					else {
						userIdArr = new String [2];
						userIdArr[0] = String.valueOf(orgBlogCreatorId);
						userIdArr[1] = String.valueOf(myUid);
					}
				}
			}

			// xxx include blog text only if this is not a team notification
			// ECC: changed to include blog text always (originalText)
			if (parentIdS != null) {
				// for comment, need to replace linebreak with <br>
				originalText = originalText.replaceAll("\n", "<br>");
			}
			msg += "<table width='100%' border='0' cellspacing='0' cellpadding='0'>"
					+ "<tr><td bgcolor='#bbbbbb' width='100%' height='1'><img src='" + NODE + "/i/spacer.gif' height='1'/></td></tr></table><br>"
					+ originalText;
			
			// mergeEmails() can handle Integer and String arrays
			if (userIdArr!=null && userIdArr[0] != null) {
				emailArr = Util2.mergeEmails(me, emailArr, userIdArr);
			}
			else if (alertArr!=null && alertArr[0] != null) {
				emailArr = Util2.mergeEmails(me, emailArr, alertArr);
			}
			
			if (bugEmail2 != null) {
				String [] email = new String[1];
				email[0] = bugEmail2;
				emailArr = Util2.mergeEmails(me, emailArr, email);
			}
			
			// send Email
			if (emailArr!=null && emailArr.length>0) {
				Util.sendMailAsyn(me, from, emailArr, null, null, subj, msg, MAILFILE);
			}
		}
	}
	
	response.sendRedirect(backPage);
%>
