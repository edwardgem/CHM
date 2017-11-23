<%
//
//  Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   postupdatePlan.jsp
//  Author: ECC
//  Date:   04/09/04
//  Description:  Post page to take care update plan
//  Modification:
//			@ECC042009	Allow update plan to insert new tasks with startGap and length specification.
//
/////////////////////////////////////////////////////////////////////
//
%>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "util.JwTask" %>
<%@ page import = "com.oreilly.servlet.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%

	String backPage = request.getParameter("backPage").replace(':','&');
	int realorder = Integer.parseInt((String)request.getParameter("realorder"));
	String Name = request.getParameter("Name");
	String s;

	// Get plan task
	Stack planStack = (Stack)session.getAttribute("planStack");
	if((planStack == null) || planStack.empty())
	{
		response.sendRedirect("../out.jsp?msg=Internal error - empty plan stack. Please start again!");
		return;
	}
	Vector oPlan = (Vector)planStack.peek();

	// Session will  hold a Stack of Plan
	// a Plan is a Vector of Task
	// a Task is a hashtable of info.
	Vector nPlan = new Vector();
	boolean bInserted = false;
	boolean bSameLevel = false;
	int addLevel = 0;
	int [] LevelOrder = {0,0,0,0,0,0,0,0};
	int lastLevel = 0;
	Object planIDArr = null;
	Object taskIDArr = null;
	Object val;

	for (int i=0; i < realorder; i++)
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
		String statusString = (String)oTask.get("Status");
		int order = ((Integer)((Object [])oTask.get("Order"))[0]).intValue();
		int thislevel = ((Integer)((Object [])oTask.get("Level"))[0]).intValue();

		if (!statusString.equals("Deprecated"))
		{
			LevelOrder[thislevel] = order;
			lastLevel = thislevel;
			planIDArr = oTask.get("PlanID");
			taskIDArr = oTask.get("TaskID");
		}

		nPlan.addElement(nTask);
	}

	// ECC: fix the bug for inserting new task to the beginning of a plan
	if (realorder==0 && oPlan!=null && oPlan.size()>0)
	{
		Hashtable oTask = (Hashtable) oPlan.elementAt(0);
		planIDArr = oTask.get("PlanID");
		taskIDArr = oTask.get("TaskID");
	}



	///////////////////////////
	StringTokenizer linetoken = new StringTokenizer(Name,"\n");
	while (linetoken.hasMoreTokens())
	{
		String lineString = linetoken.nextToken();

		int charCount = 0;
		int charCount1 = 0;
		int order = 0;
		// Either accept * or tab
		while (lineString.charAt(charCount++) == '*');
		//while (lineString.charAt(charCount1++) == '\t');
		if (charCount1 > charCount) charCount = charCount1;

		String title = lineString.substring(--charCount).trim();
		
		// @ECC042009 allow update plan to specify task start gap and length
		int idx;
		int startGap=0, length=0;
		if ((idx = title.indexOf(project.DELIMITER)) != -1)
		{
			s = title.substring(idx+project.DELIMITER.length()).trim();		// startGap:length
			title = title.substring(0, idx);
			if ((idx = s.indexOf(project.DELIMITER1)) != -1)
			{
				length = Integer.parseInt(s.substring(idx+project.DELIMITER1.length()).trim());	// extract length
				s = s.substring(0, idx);
			}
			try {startGap = Integer.parseInt(s);}
			catch (Exception e)
			{
				// assume user enter MM/dd/yyyy
				if (s.contains("/"))
				{
					java.text.SimpleDateFormat df = new java.text.SimpleDateFormat("MM/dd/yyyy");
					Date dt = df.parse(s);
					s = (String)session.getAttribute("projName");
					project pj = (project)projectManager.getInstance().get(pstuser, s);
					Date pjStart = (Date)pj.getAttribute("StartDate")[0];
					startGap = ((int)(dt.getTime() - pjStart.getTime())) / 86400000;	// in days
					if (startGap < 0)
						startGap = 0;
				}
			}
		}

		// insert a new one
		Hashtable newTask = new Hashtable();
		if (planIDArr != null) {
			newTask.put("PlanID", planIDArr);
			newTask.put("TaskID", taskIDArr);
		}

		newTask.put("Name", title);
		newTask.put("Status", task.NEW);
		Integer[] pLevel = new Integer[1];
		pLevel[0] = new Integer(charCount);
		newTask.put("Level", pLevel);
		newTask.put("StartGap", startGap);		// @ECC042009
		newTask.put("Length", length);			// @ECC042009

		if ((lastLevel < charCount) || (realorder <= 0))
		{
			order = 0;
			for (int j=charCount ; j < 5; j++)
			{
				LevelOrder[j] = 0;
			}
		}
		else
		{
			order = LevelOrder[charCount] + 1;
		}

		LevelOrder[charCount] = order;
		lastLevel = charCount;


		Integer[] pOrder = new Integer[1];
		pOrder[0] = new Integer(order);
		newTask.put("Order", pOrder);
		newTask.put("ProjectID", session.getAttribute("projectId"));
		nPlan.addElement(newTask);
	}

	for (int i=realorder; i < oPlan.size(); i++)
	{
		// oTask is task of last change
		// nTask is task that we cloning the old one plus some changes
		Hashtable oTask = (Hashtable) oPlan.elementAt(i);

		Hashtable nTask = new Hashtable();
		if (oTask.get("PlanID")!=null)
			nTask.put("PlanID", oTask.get("PlanID"));
		nTask.put("Level", oTask.get("Level"));
		nTask.put("Status", oTask.get("Status"));
		nTask.put("Name", oTask.get("Name"));
		if (oTask.get("TaskID")!=null)
			nTask.put("TaskID", oTask.get("TaskID"));
		if ((val = oTask.get("Task")) != null) {
			nTask.put("Task", val);
		}
		nTask.put("ProjectID", oTask.get("ProjectID"));
		nTask.put("Order", oTask.get("Order"));
		String statusString = (String)oTask.get("Status");
		//if (statusString.equals("Deprecated")) continue;

		int order = 0;
		int thislevel = ((Integer)((Object [])oTask.get("Level"))[0]).intValue();

		if (!statusString.equals("Deprecated"))
		{

			if (lastLevel < thislevel)
			{
				order = 0;
				for (int j=thislevel ; j < 5; j++)
				{
					LevelOrder[j] = 0;
				}
			}
			else
			{
				order = LevelOrder[thislevel] + 1;
			}

			LevelOrder[thislevel] = order;
			lastLevel = thislevel;


			Integer[] pOrder = new Integer[1];
			pOrder[0] = new Integer(order);
			nTask.put("Order", pOrder);
		}


		nPlan.addElement(nTask);
	}
	
	// to make sure that things are right
	JwTask.fixHeader(nPlan);


	planStack.push(nPlan);
	session.setAttribute("planStack", planStack);
	session.removeAttribute("redoStack");

	response.sendRedirect(backPage);
%>
