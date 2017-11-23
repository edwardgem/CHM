<%
//
//  Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   postplanDelete.jsp
//  Author: ECC
//  Date:   04/10/04
//  Description:  Post page to take care deleting a task
//  Modification:
//
/////////////////////////////////////////////////////////////////////
//
%>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.JwTask" %>
<%@ page import = "util.Prm" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "com.oreilly.servlet.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	String projId = request.getParameter("projId");

	// Get plan task
	Stack planStack = (Stack)session.getAttribute("planStack");
	if((planStack == null) || planStack.empty())
	{
		response.sendRedirect("../out.jsp?msg=Emply plan stack.  Please start again!");
		return;
	}
	Vector oPlan = (Vector)planStack.peek();

	// Session will  hold a Stack of Plan
	// Plan is represented by a Vector of Task
	// Task is represented by a hashtable.
	Vector nPlan = new Vector();
	int delLevel = 0;
	int[] minus = {0,0,0,0,0,0,0,0,0,0};
	int currentLevel = 0;
	//int preorderminus = 0;
	boolean delAll = false;
	Object val;
	
	for (int i=0; i < oPlan.size(); i++)
	{
		// oTask is task of last change
		// nTask is task that we cloning the old one plus some changes
		Hashtable oTask = (Hashtable) oPlan.elementAt(i);

		Hashtable nTask = new Hashtable();
		nTask.put("PlanID", oTask.get("PlanID"));
		nTask.put("Order", oTask.get("Order"));
		nTask.put("Level", oTask.get("Level"));
		nTask.put("Status", oTask.get("Status"));
		nTask.put("Name", oTask.get("Name"));
		nTask.put("TaskID", oTask.get("TaskID"));
		if ((val = oTask.get("Task")) != null) {
			nTask.put("Task", val);
		}
		nTask.put("ProjectID", oTask.get("ProjectID"));

		currentLevel = ((Integer)((Object [])oTask.get("Level"))[0]).intValue();
		if (currentLevel <= delLevel) {
			delAll = false;
		}

		String currentStatus;
		if (delAll)
		{
			// I am sub-task of the task being deleted
			currentStatus = (String)oTask.get("Status");

			if (currentStatus.equals(task.DEPRECATED))
			{
				nPlan.addElement(nTask);
				//preorderminus--;

			}
			else if (currentStatus.equals(task.ORIGINAL))
			{
				nTask.put("Status", task.DEPRECATED);
				nPlan.addElement(nTask);
			}
			//preorderminus++;
		}
		else if ((request.getParameter(String.valueOf(i)) != null)
					&& (request.getParameter(String.valueOf(i)).equals("delete")))
		{
			// delete this task
			currentStatus = (String)oTask.get("Status");

			if (currentStatus.equals(task.NEW)) {
				// just created this task, so do nothing
			}
			else if (currentStatus.equals(task.ORIGINAL)) {
				nTask.put("Status", task.DEPRECATED);
				nPlan.addElement(nTask);
				
				// ECC Debug: request to delete a task
				// send a debug email msg
				Prm.sendEgiEmail("User [" + pstuser.getObjectId() + "] requested to delete task ["
				                 	+ nTask.get("TaskID") + "] (" + nTask.get("Name") + ")");
			}
			for (int j=currentLevel+1; j<delLevel+1 ; j++) {
				minus[j]=0;
			}

			minus[currentLevel]++;	// remember how many tasks on this level have been deleted
			//preorderminus++;
			delAll = true;			// ready to delete all my children tasks
			delLevel = currentLevel;
		}
		else
		{
			// for tasks behind or before the deleted task: could be siblings or other levels
			for (int j=currentLevel+1; j<delLevel+1 ; j++) {
				minus[j]=0;
			}

			int order = ((Integer)((Object [])oTask.get("Order"))[0]).intValue();
			Integer[] pOrder = new Integer[1];
			pOrder[0] = new Integer(order - minus[currentLevel]);
			nTask.put("Order", pOrder);

			nPlan.addElement(nTask);
		}
	}

	// the nPlan tasks can be out of order as in the case
	// when a moved task is deleted (Status==Change)
	// fix the plan order in header number
	JwTask.fixHeader(nPlan);

	planStack.push(nPlan);
	session.setAttribute("planStack", planStack);
	session.removeAttribute("redoStack");

	response.sendRedirect("updplan.jsp?projId=" + projId);

%>

