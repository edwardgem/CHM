//
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: TaskInfo.java
//	Author: ECC
//	Date:	10/18/04
//	Description: Review current project.
//
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//

package util;

import java.util.Arrays;
import java.util.Date;

import oct.codegen.planTask;
import oct.codegen.planTaskManager;
import oct.codegen.project;
import oct.codegen.projectManager;
import oct.codegen.task;
import oct.pmp.exception.PmpException;
import oct.pst.PstUserAbstractObject;

public class TaskInfo
{
	public String	name;
	public String	pTaskIdS;
	public String	owner;
	public String	status;
	public Date		startDate;
	public Date		expireDate;
	public Date		completeDate;
	public Date		updateDate;
	public int		daysElapsed;
	public int		daysLeft;
	public int		daysLate;
	public int		length;
	public int		blogNum;
	public double	weight;
	public int		level;
	public int		order;

	public TaskInfo() {}

	//
	//	getProjTaskStack()
	//		Return a String that captures the path name of the task with the proj name.
	//		Input parameter: task
	//		If this is a top task, return the task name.
	//		e.g. parent task name >> this task name
	//
	public static String getProjTaskStack(PstUserAbstractObject pstuser, task tk)
		throws PmpException
	{
		projectManager pjMgr = projectManager.getInstance();
		planTaskManager ptkMgr = planTaskManager.getInstance();

		String projIdS = (String)tk.getAttribute("ProjectID")[0];
		String projName = ((project)pjMgr.get(pstuser, Integer.parseInt(projIdS))).getDisplayName();

		int [] ids = ptkMgr.findId(pstuser, "TaskID='" + tk.getObjectId() +"' && Status !='Deprecated'");
		Arrays.sort(ids);
		planTask ptk = (planTask)ptkMgr.get(pstuser, ids[ids.length-1]);
		String stackName = getTaskStack(pstuser, ptk);
		stackName = projName + " >> " + stackName;
		return stackName;
	}

	//
	//	getTaskStack()
	//		Return a String that captures the path name of the task without the proj name.
	//		Input parameter: planTask
	//		If this is a top task, return the task name.
	//		e.g. parent task name >> this task name
	//
	public static String getTaskStack(PstUserAbstractObject pstuser, planTask pt)
	{
		// create task path name
		String stackName;
		try {
			stackName = (String)pt.getAttribute("Name")[0];
			String parentIdS = (String)pt.getAttribute("ParentID")[0];
	
			planTaskManager ptMgr = planTaskManager.getInstance();
			planTask parent;
			while (parentIdS != null && !parentIdS.equals("0"))
			{
				parent = (planTask)ptMgr.get(pstuser, Integer.parseInt(parentIdS));
				stackName = (String)parent.getAttribute("Name")[0] + " >> " + stackName;
				parentIdS = (String)parent.getAttribute("ParentID")[0];
			}
		}
		catch (Exception e) {
			return "";
		}

		return stackName;
	}
}
