<%
//
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_mtg_del.jsp
//	Author: ECC
//	Date:		03/9/2005
//	Description:	Delete a meeting.
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
%>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />


<%
	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	String midS = request.getParameter("mid");
	String delRecurS = request.getParameter("delRecur");
	boolean bRecur = false;
	if (delRecurS!=null && delRecurS.equals("true"))
		bRecur = true;

	meetingManager mMgr = meetingManager.getInstance();

	// delete the meeting object
	meeting mtgObj = (meeting)mMgr.get(pstuser, midS);
	Thread th = PrmEvent.createTriggerEvent(pstuser, PrmEvent.EVT_MTG_DELETE, midS, (String)mtgObj.getAttribute("TownID")[0], null);
	if (th != null) th.join();	// need to wait for event trigger to complete before deleting the meeting obj
	
	mtgObj.deleteRecursive(pstuser, bRecur);	// this may recursively delete next meeting and all action items

	response.sendRedirect("cal.jsp");

%>
