<%
//
//	Copyright (c) 2008, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_q_del.java
//	Author: ECC
//	Date:		01/16/2008
//	Description:	Post file for deleting a new invite/quest when updating it.
//	Modification:
//				@ECC092408	Support canceling an event.  Cancel is only applicable to event,
//							not questionnaire.
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
<%@ page import = "org.apache.log4j.Logger" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	// create quest object
	PstUserAbstractObject me = pstuser;

	if (me instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	Logger l = PrmLog.getLog();
	String s, msg;
	
	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if (iRole > 0)
	{
		if ((iRole & user.iROLE_ADMIN) > 0)
			isAdmin = true;
	}
	
	String qidS = request.getParameter("qid");
	boolean isCanceling = false;
	s = request.getParameter("cancel");
	if (s != null)
		isCanceling = true;

	int myUid = me.getObjectId();
	String myUidS = String.valueOf(myUid);
	String myName = ((user)me).getFullName();

	questManager qMgr = questManager.getInstance();
	resultManager rMgr = resultManager.getInstance();
	
	PstAbstractObject obj = qMgr.get(me, qidS);
	s = (String)obj.getAttribute("Type")[0];
	if (s.indexOf(quest.TYPE_EVENT) != 0)
		s = "event invitation";
	else
		s = "questionnaire/survey/vote";
	
	// check for authorization
	if (!isAdmin && Integer.parseInt((String)obj.getAttribute("Creator")[0]) != myUid)
	{
		response.sendRedirect("../out.jsp?msg=Access declined.  Only " + s + " owner is allowed to perform this operation.");
		return;
	}

	if (isCanceling)
	{
		// only canceling the event: set the state accordingly and return
		obj.setAttribute("State", quest.ST_CANCEL);
		qMgr.commit(obj);
		msg = "Done! The " + s + " has been canceled successfully.";
		response.sendRedirect("../meeting/cal.jsp?msg="+msg);	// show the event calendar
		return;
	}
	
	// only get to this point if I am deleting the quest
	qMgr.delete(obj);
	
	// remove the answers to this quest
	answerManager aMgr = answerManager.getInstance();
	PstAbstractObject o;
	int ct = 0;
	int [] ids = aMgr.findId(me, "TaskID='" + qidS + "'");
	for (int i=0; i<ids.length; i++)
	{
		o = aMgr.get(me, ids[i]);
		aMgr.delete(o);
		ct++;
	}
	
	l.info(myName + " removed quest [" + qidS + "] and " + ct + " answers.");
	
	// check to see if I am parent of other quest, in that case I need to clean up ParentID
	ids = qMgr.findId(me, "ParentID='" + qidS + "'");
	for (int i=0; i<ids.length; i++)
	{
		obj = qMgr.get(me, ids[i]);
		obj.setAttribute("ParentID", null);
		qMgr.commit(obj);
	}
	
	// remove all blogs associated to this quest
	ids = rMgr.findId(me, "TaskID='" + qidS + "'");
	for (int i=0; i<ids.length; i++)
	{
		obj = rMgr.get(me, ids[i]);
		rMgr.delete(obj);
	}

	// no need to remove event because none has been created before ACTIVE
	
	msg = "Done! The " + s + " has been removed successfully.";
	response.sendRedirect("../meeting/cal.jsp?msg="+msg);	// show the event calendar

%>
