<%
//
//	Copyright (c) 2010, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_worktray.java
//	Author: ECC
//	Date:		01/05/2010
//	Description:	post file to handle worktray actions.
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "oct.util.file.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "mod.box.PrmDrawFlow" %>
<%@ page import = "mod.box.PrmDrawFlow.Step" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.PepCommentVector" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>
<%@ page import = "com.oreilly.servlet.*" %>
<%@ page import = "org.apache.log4j.Logger" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	final Logger l = PrmLog.getLog();
	String repository = Util.getPropKey("pst", "FILE_UPLOAD_PATH");
	String host = Util.getPropKey("pst", "PRM_HOST");
	MultipartRequest mrequest = new MultipartRequest(request, repository, 100*1024*1024);

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	resultManager rMgr = resultManager.getInstance();
	taskManager tkMgr = taskManager.getInstance();
	PstFlowStepManager fsMgr = PstFlowStepManager.getInstance();

	String bpParam = "";	// backPage param
	boolean bNeedToRefreshSessionProject = false;
	PstAbstractObject step = null;

	String backPage = mrequest.getParameter("backPage");

	String tidS = null;
	String flowId = mrequest.getParameter("flowId");
	String stepId = mrequest.getParameter("stepId");
	String op = mrequest.getParameter("op");
	l.info("post_worktray.jsp op = " + op);

	boolean bSaveTaskBlog = false;
	boolean bGoToBlogPage = false;

	if (op.equals("addBlog"))
	{
		// add comment blog for workflow
		String text = mrequest.getParameter("blogText").trim();
		if (text.length() > 0)
		{
			String type = result.TYPE_WORKFLOW;
			String flowInstId = mrequest.getParameter("flowInstID");
			PstAbstractObject blogObj = rMgr.create(pstuser);

			blogObj.setAttribute("CreatedDate", new Date());
			blogObj.setAttribute("Creator", String.valueOf(pstuser.getObjectId()));
			blogObj.setAttribute("Type", type);
			blogObj.setAttribute("TaskID", flowInstId);
			blogObj.setAttribute("Comment", text.getBytes());
			rMgr.commit(blogObj);
		}
		response.sendRedirect("worktray.jsp?pn=c#tab");	// show comment panel
		return;
	}
	else if (op.equals("add"))
	{
		// add a step
		String addPosition = mrequest.getParameter("addPosition");	// add step before, after or parallel
		Step newStep = new Step(Step.NEW_NAME);
		newStep.setCreator(pstuser.getObjectName());	// should use ID
		if (addPosition.equals("after"))
		{
			newStep.addParent(stepId);		// add parent
			newStep.setInToken(1);			// one single token
		}
		else if (addPosition.equals("before"))
		{
			newStep.setOutStep(stepId);
			// might be more than one inToken, need to copy from existing step
		}

		// add the new step to the draft XML
		PrmDrawFlow.addStepToFlow(pstuser, flowId, newStep);
		bpParam = "?df=1";
	}
	else if (op.equals("del"))
	{
		// delete a step
		PrmDrawFlow.delStepFromFlow(pstuser, flowId, stepId);
		bpParam = "?df=1";
	}

	// task step operations
	else if (op.equals("commit"))
	{
		step = fsMgr.get(pstuser, stepId);
		tidS = (String)step.getAttribute("TaskID")[0];
		task tObj = (task)tkMgr.get(pstuser, tidS);

		// move the task to Completed state and commit the step
task.setDebug(true);
		tObj.setState(pstuser, task.ST_COMPLETE);
		if (backPage!=null && backPage.indexOf('?')!=-1) {
			backPage = backPage.replace(host, "..").replaceAll("&", ":");
			backPage += ":pn=c@wi";
		}
		bSaveTaskBlog = true;
		bNeedToRefreshSessionProject = true;
	}
	else if (op.equals("abort"))
	{
		step = fsMgr.get(pstuser, stepId);
		tidS = (String)step.getAttribute("TaskID")[0];
		task tObj = (task)tkMgr.get(pstuser, tidS);

		// move the task to Canceled state
		tObj.setState(pstuser, task.ST_CANCEL);
		if (backPage!=null && backPage.indexOf('?')!=-1) {
			backPage = backPage.replace(host, "..").replaceAll("&", ":");
			backPage += ":pn=c@wi";
		}
		bSaveTaskBlog = true;
		bNeedToRefreshSessionProject = true;
	}
	else if (op.equals("save"))
	{
		// save the task blog
		step = fsMgr.get(pstuser, stepId);
		tidS = (String)step.getAttribute("TaskID")[0];

		String idxS = mrequest.getParameter("idx");
		if (backPage == null) {
			backPage = "../box/worktray.jsp?idx=" + idxS + ":pn=c@tab";		//@ will be replaced to #
		}
		else {
			backPage = backPage.replace(host, "..").replaceAll("&", ":");
			backPage += ":pn=c@tab";
		}
		bSaveTaskBlog = true;
		bGoToBlogPage = true;	// this will jump to blog_comment page
		bNeedToRefreshSessionProject = true;
	}


	///////////////////////////////////////////
	if (bNeedToRefreshSessionProject) {
		// this will do the trick to force a refresh in proj_plan.jsp and cr.jsp
		pstuser.setAttribute("LastProject", null);
	}

	// check to save task blog
	if (bSaveTaskBlog) {
		// this is only for task blog, NOT workflow blog which is done above
		String text = mrequest.getParameter("blogText");
		if (text!=null && text.trim().length()<=0)
			text = null;

		// TODO: save task blog should just be done simply locally here
		// No need to call post_addblog.jsp.  Also need to support save action blog
		if (text!=null) {
			// this is only for saving task blog.
			// Saving workflow comment is done above.

			text = text.replaceAll("\n", "<br>");	// to HTML text
			String type = result.TYPE_TASK_BLOG;

			// override send email option
			String forceEmail = mrequest.getParameter("forceSendEmail");
			if (forceEmail==null || forceEmail=="") forceEmail = "";
			else forceEmail = "&forceSendEmail=" + forceEmail;

			if (!bGoToBlogPage && backPage==null) {
				backPage = "../box/worktray.jsp";
			}

			// call post_addblog.jsp to save the blog
			response.sendRedirect("../blog/post_addblog.jsp?type=" + type
				+ "&id=" + tidS
				+ forceEmail
				+ "&logText=" + text + "&backPage=" + backPage);
			return;
		}
	}

	response.sendRedirect("worktray.jsp" + bpParam);	// default

%>
