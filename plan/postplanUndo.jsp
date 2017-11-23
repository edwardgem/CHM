<%

//
//  Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   postplanUndo.jsp
//  Author: ECC
//  Date:   04/08/04
//  Description:  Post page to take care undo
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

	if((planStack == null) || planStack.empty())
	{
		response.sendRedirect("updplan.jsp?projId=" + projId);
		return;
	}


	Vector oPlan = (Vector)planStack.pop();

	// Last step , cannot undo
	if(planStack.empty())
	{
		planStack.push(oPlan);
		response.sendRedirect("updplan.jsp?projId=" + projId);
		return;
	}


	if(redoStack == null)
	{
		redoStack = new Stack();
	}

	redoStack.push(oPlan);
	session.setAttribute("planStack", planStack);
	session.setAttribute("redoStack", redoStack);

	response.sendRedirect("updplan.jsp?projId=" + projId);

%>

