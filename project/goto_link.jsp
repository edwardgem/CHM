<%
//
//	Copyright (c) 2009, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	goto_link.jsp
//	Author: ECC
//	Date:	02/10/2009
//	Description:	Go to the project central repository page that contains this Attachment ID.
//	Modification:
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

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%

	String attIdS = request.getParameter("attId");

	// get the task that contains this attId
	taskManager tMgr = taskManager.getInstance();
	int [] ids = tMgr.findId(pstuser, "AttachmentID='" + attIdS + "'");
	if (ids.length <= 0)
	{
		// it is possible that the file is from remote machine (rdata.jsp)
		// try to get the attObj and see if that is the case
		attachmentManager aMgr = attachmentManager.getInstance();
		PstAbstractObject aObj = aMgr.get(pstuser, attIdS);
		String loc = (String)aObj.getAttribute("Location")[0];
		if (Util.isAbsolutePath(loc))
			response.sendRedirect("../out.jsp?e=This is a remote machine file.");
		else
			response.sendRedirect("../out.jsp?e=Internal error: the source of the linked document is not found.");
		return;
	}
	
	// from the task, get the project Id
	PstAbstractObject tObj = tMgr.get(pstuser, ids[0]);		// there should only be one task
	String projIdS = (String)tObj.getAttribute("ProjectID")[0];
	
	// goto the cr.jsp page to display the attachment
	response.sendRedirect("cr.jsp?projId=" + projIdS + "&attId=" + attIdS);

%>