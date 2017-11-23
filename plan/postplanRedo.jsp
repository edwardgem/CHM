<%

//
//  Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   postplanRedo.jsp
//  Author: ECC
//  Date:   04/08/04
//  Description:  Post page to take care Redo
//  Modification:
//
/////////////////////////////////////////////////////////////////////
//
%>
<%@ page import = "java.util.*" %>

<%
	String projId = request.getParameter("projId");
	String type = request.getParameter("type");

	// Get plan task
	Stack planStack = (Stack)session.getAttribute("planStack");
	Stack redoStack = (Stack)session.getAttribute("redoStack");

	if((redoStack == null) || redoStack.empty())
	{
		response.sendRedirect("updplan.jsp?projId=" + projId);
		return;
	}


	Vector oPlan = (Vector)redoStack.pop();

	planStack.push(oPlan);
	session.setAttribute("planStack", planStack);
	session.setAttribute("redoStack", redoStack);

	response.sendRedirect("updplan.jsp?projId=" + projId);

%>

