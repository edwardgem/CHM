<%@ page contentType="text/html; charset=utf-8"%>

<%
//
//	Copyright (c) 2009, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_newtempl.jsp
//	Author: ECC
//	Date:		10/15/2004
//	Description:	Create or update a project/meeting/quest template
//	Modification:
//				@ECC011608	Support quest.
//				@ECC111909  Admin saving template would be available to all users.
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.PepCommentVector" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

// create project, plan, planTask and task
	PstUserAbstractObject me = pstuser;
	if (me instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}

	String prefix = "";
	boolean isCRAPP = false;
	boolean isOMFAPP = false;
	boolean isPRMAPP = false;
	String app = (String)session.getAttribute("app");
	if (app.indexOf("CR")!=-1)
		isCRAPP = true;
	else if (app.equals("OMF"))
		isOMFAPP = true;
	else if (app.equals("PRM"))
		isPRMAPP = true;

	// @ECC111909
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	boolean isAdmin = ((iRole & user.iROLE_ADMIN) > 0);

	boolean isQuest=false, isEvent=false;
	String templateType = request.getParameter("TemplateType");
	String templateName = request.getParameter("TemplateName");
	String s;
	s = templateType;
	String newTemplName = null;
	
	if (isOMFAPP)
	{
		if (!s.startsWith("Mtg_"))
		{
			isQuest = true;
			if (s.startsWith("Evt_"))
			{
				isEvent = true;
				prefix = "Evt_";
			}
			else
				prefix = "Qst_";
		}
		else
			prefix = "Mtg_";
	}
	else
	{
		int idx;
		if ((idx = templateName.indexOf("@@")) == -1) {
			if (!isAdmin)
				templateName += "@@" + me.getObjectId();	// add @@uid
		}
		else if (isAdmin){
			// isAdmin case:
			// the templateName already retain the @@uid in new_templ2.jsp
			newTemplName = templateName.substring(0, idx);	// take only the name
		}
	}

	String qidS = request.getParameter("qid");
	String content = request.getParameter("Content");
	String update = request.getParameter("Update");

	projTemplateManager ptmMgr	= projTemplateManager.getInstance();
	userManager uMgr = userManager.getInstance();
	questManager qMgr = questManager.getInstance();

	// get circle id if any
	// for template: circleId=0 means for All ppl; =null for Owner only; otherwise for the circle
	String circleIdS = null;
	if (isOMFAPP)
	{
		PstAbstractObject o = qMgr.get(me, qidS);
		circleIdS = (String)o.getAttribute("TownID")[0];		// either null or a valid circle Id
	}

	// create the project object
	// check to see if the tempalte name is unique (ECC: need change when using ID as obj names)
	projTemplate templ = null;
	
	if (update.equals("true")) {
		templ = (projTemplate)ptmMgr.get(me, prefix + templateName);
		if (isAdmin && newTemplName!=null) {
			templ.setObjectName(newTemplName);
		}
	}
	else
		templ = (projTemplate)ptmMgr.create(me, prefix + templateName);

	templ.setAttribute("Type", prefix + templateType);
	templ.setAttribute("Content", content.getBytes("UTF-8"));
	if (!isAdmin)
	{
		templ.setAttribute("Owner", String.valueOf(me.getObjectId()));
		if (circleIdS != null)
			templ.appendAttribute("Towns", new Integer(circleIdS));
	}
	ptmMgr.commit(templ);

	if (isCRAPP || isPRMAPP)
		response.sendRedirect("../project/cr.jsp");
	else if (isQuest)
		response.sendRedirect("../question/q_answer.jsp?qid=" + qidS + "&msg=Done! The template <b>" + templateName + "</b> has been saved successfully");
	else if (isOMFAPP)
		response.sendRedirect("../ep/ep_home.jsp");
	else
		response.sendRedirect("../project/proj_plan.jsp");
%>
