<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<%
//
//  Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   postplanUpdate.jsp
//  Author: ECC
//  Date:   04/08/04
//  Description:  Post page to take care update plan
//  Modification:
//		@ECC021207	Support moving of node and its subtree (Singapore)
//		@ECC060507	There is a bug in getHeaderIntValue(), obsolete that and use JwTask.compare()
//
/////////////////////////////////////////////////////////////////////
//
%>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "util.JwTask" %>
<%@ page import = "java.util.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	String backPage = request.getParameter("backPage").replace(':','&');
	int realOrder = Integer.parseInt((String)request.getParameter("realorder"));
	String Name = request.getParameter("Name");
	//String oldLevelInfo = request.getParameter("levelInfo");	// old 2.1

	// Get plan task
	Stack planStack = (Stack)session.getAttribute("planStack");
	if((planStack == null) || planStack.empty())
	{
		response.sendRedirect("../out.jsp?msg=Internal error on plan stack. Please start again!");
		return;
	}
	Vector oPlan = (Vector)planStack.peek();
	
	// @ECC021207 moving node
	Hashtable moveTask = null;
	int newLevel = 0;
	boolean isMoving = true;
	String [] sa = Name.split(" ");
	String newLevelInfo = sa[0].trim();		// e.g. 3.2.4
	
	char c = 0;
	for (int i=0; i<newLevelInfo.length(); i++)
	{
		// check to see if this is moving node: number or .
		if (c == '.') newLevel++;	// based on the last char
		c = newLevelInfo.charAt(i);
		if ((c>='0' && c<='9') || c=='.')
			continue;
		else
		{
			isMoving = false;
			break;
		}
	}

	int level, order, moveTaskNum = 1;
	int moveTaskLevel = -1;
	int levelDiff = 0;
	int [] orderOfLevel = new int[JwTask.MAX_LEVEL];
	//long iNewHeader = 0;	// the int value of the header numeric
	if (isMoving)
	{
		for (int i=0; i<JwTask.MAX_LEVEL; i++)
			orderOfLevel[i] = 0;	// init
		
		// evaluate the int value of the header
		//iNewHeader = JwTask.getHeaderIntValue(newLevelInfo);

		// find out how many tasks are there in the group to be moved
		moveTask = (Hashtable)oPlan.elementAt(realOrder);
		moveTaskLevel = ((Integer)((Object [])moveTask.get("Level"))[0]).intValue();
		levelDiff = newLevel - moveTaskLevel;
		for (int i=realOrder+1; i<oPlan.size(); i++)
		{
			Hashtable oTask = (Hashtable) oPlan.elementAt(i);
			if (moveTaskLevel >= ((Integer)((Object [])oTask.get("Level"))[0]).intValue())
				break;
			moveTaskNum++;	// total number of tasks being moved
		}
	}

	// Session will  hold a Stack of Plan
	// Plan is represented by a Vector of Task
	// Task is represented by a hashtable.
	String currentStatus;
	Vector nPlan = new Vector();
	String [] levelInfo = new String[JwTask.MAX_LEVEL];
	Hashtable oTask = null;
	int realOrderPos = -1;
	int count = 0;					// index on nPlan
	//long iHeader;
	int iCompareLevel;				// @ECC060507
	boolean bFoundPos = false;		// found the new move to position
	boolean bAppendedToEnd = false;	// take care of the case when moving to end of plan
	Object val;
	Hashtable aTask = null;

	for (int i=0; i < oPlan.size(); i++)
	{
		// oTask is task of last change
		// nTask is task that we cloning the old one plus some changes
		oTask = (Hashtable) oPlan.elementAt(i);
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

		if (isMoving)
		{
			Integer [] io;
			level = ((Integer)((Object [])oTask.get("Level"))[0]).intValue();
			order = ((Integer)((Object [])oTask.get("Order"))[0]).intValue() + 1;
			orderOfLevel[level] = order;
			if (level == 0)
				levelInfo[level] = String.valueOf(order);
			else
				levelInfo[level] = levelInfo[level - 1] + "." + order;
			//System.out.println("levelInfo[" + level + "] = " + levelInfo[level]);

			//iHeader = JwTask.getHeaderIntValue(levelInfo[level]);	// int value of this header
			iCompareLevel = JwTask.compare(newLevelInfo, levelInfo[level]);
			//System.out.println("comparing " + newLevelInfo + " and " + levelInfo[level] +" result "+iCompareLevel);

			//if (!bFoundPos && (iNewHeader<=iHeader || i==oPlan.size()-1) )	// @ECC060507 use compare()
			if (!bFoundPos && (iCompareLevel<=0 || i==oPlan.size()-1) )
			{
				if (realOrder==i && iCompareLevel==0)
				{
					// I am moving to the same location as where I am now
					response.sendRedirect(backPage);
					return;
				}

				// the moving one is to insert before this one (position)
				bFoundPos = true;
				
				// create and insert the new task into here
				int newOrder;
				//if (iNewHeader<iHeader)
				//System.out.println("iCompareLevel=" + iCompareLevel);
				if (iCompareLevel < 0)		// @ECC060507 use compare()
				{
					//System.out.println("   LevelInfo[" + newLevel + "]="+levelInfo[newLevel]);
					//System.out.println("order-1=" + (order-1));
					if (levelInfo[newLevel] == null)
						newOrder = 0;
					else
						newOrder = Integer.parseInt(levelInfo[newLevel].substring(levelInfo[newLevel].lastIndexOf(".") + 1));
					order--;
				}
				else if (iCompareLevel == 0)
				{
					newOrder = order - 1;
				}
				else
				{
					// iCompareLevel > 0
					// iNewHeader>iHeader
					// oTask is the last task in the plan, the move must be appending to the end
					// insert the last task before inserting the new task group
					newOrder = Integer.parseInt(levelInfo[newLevel].substring(levelInfo[newLevel].lastIndexOf(".") + 1));
					order--;
					nPlan.addElement(nTask);
					bAppendedToEnd = true;
				}
				JwTask.insertTask(nPlan, oPlan, moveTask, newLevel, newOrder, i+1);

				io = new Integer[1];
				io[0] = new Integer(order);
				nTask.put("Order", io);
				count++;
				
				// create and insert the children also
				int num = moveTaskNum;
				for (int j=realOrder+1; j<oPlan.size() && --num>0; j++)
				{
					oTask = (Hashtable)oPlan.elementAt(j);
					int l = ((Integer)((Object [])oTask.get("Level"))[0]).intValue();
					if (moveTaskLevel >= l)
						break;		// done with group
					//if (oTask.get("Status").equals(task.DEPRECATED))
					//	continue;	// this task has already been moved or changed
					l += levelDiff;
					int o = ((Integer)((Object [])oTask.get("Order"))[0]).intValue();
					//orderOfLevel[l] += 1;	// add one more
					JwTask.insertTask(nPlan, oPlan, oTask, l, o, j);
					count++;
				}
				if (bAppendedToEnd) break;	// I am all done
			}
			
			if (i == realOrder)		// ECC: I change else if to if
			{
				// this is the old task I want to move away
				// change the status of this task
				nTask.put("Status", task.DEPRECATED);
				
				if (bFoundPos)
				{
					// already moved the new task to pos, needs to decrement the old order by 1
					int o = ((Integer)((Object [])nTask.get("Order"))[0]).intValue() - 1;
					io = new Integer[1];
					io[0] = new Integer(o);
					nTask.put("Order", io);
				}
				
				// change the status of all its children
				for (int j=i+1; j<oPlan.size(); j++)
				{
					oTask = (Hashtable)oPlan.elementAt(j);
					int l = ((Integer)((Object [])oTask.get("Level"))[0]).intValue();
					if (moveTaskLevel >= l)
						break;		// done with group
					oTask.put("Status", task.DEPRECATED);
					// I don't need to insert into new plan because the big for loop will do it
				}
				
				// decrement the order of all tasks after this group on the same level
				for (int j=i+moveTaskNum; j<oPlan.size(); j++)
				{
					oTask = (Hashtable)oPlan.elementAt(j);
					int l = ((Integer)((Object [])oTask.get("Level"))[0]).intValue();
					if (moveTaskLevel == l)
					{
						int o = ((Integer)((Object [])oTask.get("Order"))[0]).intValue() - 1;
						io = new Integer[1];
						io[0] = new Integer(o);
						oTask.put("Order", io);
					}
					else if (l < moveTaskLevel)
						break;
				}
			}
		}	// END if isMoving
		else if (i == realOrder)
		{
			// NOT isMoving
			currentStatus = (String)oTask.get("Status");

			if (currentStatus.equals(task.CHANGE) || currentStatus.equals(task.NEW))
			{
				//System.out.println("*** Change name=" + Name + ", status=" + currentStatus);				
				nTask.put("Name", Name);
			}
			else if (currentStatus.equals(task.ORIGINAL))
			{
				nTask.put("Status", task.DEPRECATED);

				// insert a new one
				Hashtable newTask = new Hashtable();
				newTask.put("PlanID", oTask.get("PlanID"));
				newTask.put("Order", oTask.get("Order"));
				newTask.put("Level", oTask.get("Level"));
				newTask.put("TaskID", oTask.get("TaskID"));
				if ((val = oTask.get("Task")) != null) {
					newTask.put("Task", val);
				}
				newTask.put("ProjectID", oTask.get("ProjectID"));

				newTask.put("Name", Name);
				newTask.put("Status", task.CHANGE);

				nPlan.addElement(newTask);
			}
		}
		
		nPlan.addElement(nTask);
		count++;
	}	// END for loop through the old plan
	
	// ECC: for safety, if isMoving, perform a fix number to get it perfectly right
	// obviously I am doing this because I have a bug somewhere that mess up the numerics
	// it is in a tricky case though.  I am paying a price for very large plan.
	//if (isMoving) - ECC: do fixHeader() always, just to be sure.
	
	// ECC
	for(int i = 0; i < nPlan.size(); i++)
	{
		Hashtable rTask = (Hashtable)nPlan.elementAt(i);
		String status = (String)rTask.get("Status");
		String pName = (String)rTask.get("Name");
	}
	
	JwTask.fixHeader(nPlan);

	planStack.push(nPlan);
	
	session.setAttribute("planStack", planStack);
	session.removeAttribute("redoStack");

	response.sendRedirect(backPage);
%>
