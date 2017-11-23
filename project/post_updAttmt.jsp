<%@ page contentType="text/html; charset=utf-8"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<meta http-equiv="content-type" content="text/html; charset=utf-8">

<%
//
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_updAttmt.jsp
//	Author: ECC
//	Date:		06/11/2008
//	Description:	Update attachment attributes.  Also support adding
//				Google link (versus uploading a file to Google Docs)
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "oct.util.file.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>
<%@ page import = "java.net.URLEncoder" %>


<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	String projIdS = request.getParameter("projId");
	int pTaskId = Integer.parseInt(request.getParameter("planTaskID"));

	// get parameters for update
	attachmentManager aMgr = attachmentManager.getInstance();
	PstAbstractObject att;
	
	// check to see if we are adding a link to Google Docs
	String op = request.getParameter("op");
	if (op!=null && op.equals("AddGoogleLink")) {
		// just add a Google link and return
		String fname = request.getParameter("GoogleFileName");
		String url = request.getParameter("GoogleExtLink");
		
		// create an attachment object and put the Google info into it
		// this is similar to attachmentManager.create()
		att = aMgr.create(pstuser);
		att.setAttribute("Name", fname);
		att.setAttribute("Location", url);
		att.setAttribute("Owner", String.valueOf(pstuser.getObjectId()));
		att.setAttribute("Type", attachment.TYPE_TASK);
		att.setAttribute("SecurityLevel", 0);
		att.setAttribute("Frequency", 0);
		att.setAttribute("ProjectID", projIdS);
		att.setAttribute("CreatedDate", new Date());
		aMgr.commit(att);
		
		// update the task
		taskManager tkMgr = taskManager.getInstance();
		String taskID = request.getParameter("taskID");
		task t = (task)tkMgr.get(pstuser, Integer.parseInt(taskID));
		t.appendAttribute("AttachmentID", String.valueOf(att.getObjectId()));
		tkMgr.commit(t);
	}

	// update an existing attachment
	else {
		// attachment object id
		String attIdS = request.getParameter("AttId");
		att = aMgr.get(pstuser, attIdS);
	
		// owner
		String owner = request.getParameter("AttOwner");
		att.setAttribute("Owner", owner);
	
		// description
		String desc = request.getParameter("AttDescription");
		//att.setRawAttribute("Description", desc);
		att.setAttribute("Description", desc.getBytes("utf-8"));
	
		// department
		String deptName = "";
		String [] deptNames = request.getParameterValues("AttDepartments");
		if (deptNames==null || deptNames.length<=0) deptName = null;
		else for (int i = 0; i<deptNames.length; i++)
		{
			if (deptName.length() > 0) deptName += "@";
			deptName += deptNames[i];
		}
		att.setAttribute("DepartmentName", deptName);
		
		// google link
		String loc = request.getParameter("GoogleLink");
		if (!Util.isNullOrEmptyString(loc)) {
			att.setAttribute("Location", loc.trim());
		}
	
		aMgr.commit(att);
		System.out.println("updated attachment attributes [" + attIdS + "]");
	}

	session.removeAttribute("planStack");

	response.sendRedirect("task_update.jsp?projId=" + projIdS + "&pTaskId=" + pTaskId);

%>