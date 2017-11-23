<%
//
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_msp_import.java
//	Author: ECC
//	Date:		11/10/2004
//	Description:	Import MS Project CSV file.
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "oct.util.file.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.PepCommentVector" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>
<%@ page import = "com.oreilly.servlet.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />


<%
	// Attachment-JW_12345_06-10-04.txt
	String FILE_CONFIG_NAME = "pst";
	String FILE_PATH = "FILE_UPLOAD_PATH";
	String DELIMITER = ";";
	ResourceBundle filebundleFile = ResourceBundle.getBundle(FILE_CONFIG_NAME);
	String repository = filebundleFile.getString(FILE_PATH);
	MultipartRequest mrequest = new MultipartRequest(request, repository, 100*1024*1024);

	String projIdS = mrequest.getParameter("projId");
	if ((pstuser instanceof PstGuest) || (projIdS == null))
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}

	userManager uMgr = userManager.getInstance();
	planManager planObjMgr = planManager.getInstance();
	planTaskManager ptMgr = planTaskManager.getInstance();
	taskManager tkMgr = taskManager.getInstance();
	latest_resultManager lResultObjMgr = latest_resultManager.getInstance();
	projectManager pMgr = projectManager.getInstance();
	project p = (project)pMgr.get(pstuser, Integer.parseInt(projIdS));
	String currentUserId = String.valueOf(pstuser.getObjectId());

	SimpleDateFormat df = new SimpleDateFormat("MM/dd/yyyy");
	Date now = new Date();		// with date and time
	Date today = new Date(df.format(now));

	// need to get the latest plan for this project
	int [] ids = planObjMgr.findId(pstuser, "Status='Latest' && ProjectID='"+projIdS+"'");
	PstAbstractObject [] targetObjList = planObjMgr.get(pstuser, ids);

	// there is only one plan which is latest for this project
	plan latestPlan = (plan)targetObjList[0];

	// Versioning
	String planVersion = (String)latestPlan.getAttribute("Version")[0];

	////////////////////////////////////////////////////
	// Import of MS Project

	// ID;TaskID;Level;Outline;Name;Predecessors;StartDate;ActualStartDate;ExpireDate;CompleteDate;Resource

	File AttachmentFileObj = mrequest.getFile("Attachment");
	BufferedReader in = new BufferedReader(
						   new FileReader(AttachmentFileObj));

	String inputLine;
	inputLine = in.readLine();
	String [] attr = inputLine.split(DELIMITER);
	int count = attr.length;

	String attName, attValue, name;
	String [] attValueArr;
	task tk;
	planTask planTaskObj;
	Date dt;
	boolean bCreate, bBlankLine;
	int level, order, preOrder, idx, attrIdx, valIdx, valNum, lastLevel = -1;
	ArrayList depArr = new ArrayList();			// remember those have dependency
	ArrayList tkIdArr = new ArrayList(300);		// store the task Id
	Stack ptParentStack = null;					// remember the planTask Id
	String lastPlanTaskId = null;
	Date pjStart = (Date)p.getAttribute("StartDate")[0];
	Date pjEnd   = (Date)p.getAttribute("ExpireDate")[0];

	while ((inputLine = in.readLine()) != null)
	{
		// start processing the data content, each line is a task
		//System.out.println(inputLine);
		bCreate = false;
		bBlankLine = false;
		name = null;
		preOrder = -1;
		level = -1;
		order = -1;
		tk = null;
		attrIdx = 0;
		valIdx = 0;

		attValueArr = inputLine.split(";");
		valNum = attValueArr.length;

		for (int i=0; i<count; i++, valIdx++)
		{
			// process each line
			attName = attr[attrIdx++];

			if (valIdx >= valNum)		// end of value on this line
				attValue = null;
			else
				attValue = attValueArr[valIdx];
			if (attValue!=null && attValue.length() == 0)
				attValue = null;

			if (attName.equals("TaskID"))
			{
				if (attValue != null)
				{
					try{tk = (task)tkMgr.get(pstuser, attValue);}
					catch (PmpException e) {}
				}

				if (tk == null)
				{
					// create the task
					tk = (task)tkMgr.create(pstuser);
					bCreate = true;
				}
			}
			else if (attName.equals("Predecessors"))
			{
				tk.setAttribute("Dependency", null);		// no matter what nullify it first
				if (attValue == null)
					continue;
				if (attValue.startsWith("\"") && attValue.endsWith("\""))
					attValue = attValue.substring(1, attValue.length()-1);	// strip double-quote
				String [] sArr = attValue.split(",");
				for (int j=0; j<sArr.length; j++)
				{
					try {Integer.parseInt(sArr[j]);} catch (NumberFormatException e) {continue;}
					tk.appendAttribute("Dependency", sArr[j]);	// note that this is count starts from 1
				}
				depArr.add(String.valueOf(tk.getObjectId()));	// fix dependency at the end
			}
			else if (attName.endsWith("Date"))
			{
				if (attValue==null || attValue.equals("NA"))
					continue;				// don't want to wipe out any date from PRM
				if (attName.equals("ActualStartDate"))
					attName = "EffectiveDate";

				idx = attValue.indexOf(" ");	// skip day of week (Wed 11/20/04)
				dt = new Date(attValue.substring(idx+1));
				tk.setAttribute(attName, dt);	// StartDate, EffectiveDate, ExpireDate, CompleteDate
				// need to check the impact to Status
			}
			else if (attName.equals("Resource"))
			{
				try
				{
					if (attValue == null) throw new PmpException();
					user u = (user)uMgr.get(pstuser, attValue);
					tk.setAttribute("Owner", String.valueOf(u.getObjectId()));
				}
				catch (PmpException e)
				{
					// if the resource doesn't exist, assign the task to the current user
					tk.setAttribute("Owner", currentUserId);
				}
			}
			else if (attName.equals("Name"))
			{
				if (attValue==null)
				{
					if (bCreate) tkMgr.delete(tk);
					bBlankLine = true;
					break;				// this is a blank line, go to next line
				}
				if (attValue.startsWith("\""))
				{
					while (!attValue.endsWith("\""))
						attValue += attValueArr[++valIdx];		// get the other parts
					attValue = attValue.substring(1, attValue.length()-1);	// strip double-quote
					attValue = attValue.replace(';', ',');		// replace ; with comma
				}
				name = attValue;
			}
			else if (attName.equals("ID"))
			{
				if (attValue==null)
				{
					if (bCreate) tkMgr.delete(tk);
					bBlankLine = true;
					break;				// this is a blank line, go to next line
				}
				preOrder++; // = Integer.parseInt(attValue) - 1;	// use ID to set preOrder
			}
			else if (attName.equals("Level"))
			{
				if (attValue==null)
				{
					if (bCreate) tkMgr.delete(tk);
					bBlankLine = true;
					break;				// this is a blank line, go to next line
				}
				level = Integer.parseInt(attValue) - 1;		// PRM level starts from 0 but MSProj starts from 1
			}
			else if (attName.equals("Outline"))
			{
				if (attValue==null)
				{
					if (bCreate) tkMgr.delete(tk);
					bBlankLine = true;
					break;				// this is a blank line, go to next line
				}
				idx = attValue.lastIndexOf(".");
				if (idx == -1)
					order = Integer.parseInt(attValue) - 1;
				else
					order = Integer.parseInt(attValue.substring(idx+1)) - 1;
			}
			else
			{
				System.out.println("MS Project upload: ignoring attribute " + attName);
			}
		}	// end of for loop for each line

		if (bBlankLine)
		{
			tkIdArr.add("");
			continue;		// go to next line
		}

		///////////////////
		// handle correponding planTask
		// if create new task, need to also create planTask
		if (bCreate)
		{
			tk.setAttribute("ProjectID",projIdS);
			tk.setAttribute("Creator",currentUserId);
			tk.setAttribute("CreatedDate", today);

			// create the planTask
			planTaskObj = (planTask)ptMgr.create(pstuser);
			planTaskObj.setAttribute("PlanID",latestPlan.getObjectName());
			planTaskObj.setAttribute("Status","Original");
			planTaskObj.setAttribute("Name", name);
			planTaskObj.setAttribute("TaskID", tk.getObjectName());
			System.out.println("Created task [" + tk.getObjectId() + "]");
		}
		else
		{
			// retrieve the planTask
			int [] ptids = ptMgr.findId(pstuser, "(TaskID='" + tk.getObjectId() + "') && (Status!='Deprecated')");
			planTaskObj = (planTask)ptMgr.get(pstuser, ptids[ptids.length-1]);		// there should be exactly one
			System.out.println("Updated task [" + tk.getObjectId() + "]");
		}

		// set task status
		if (tk.getAttribute("CompleteDate")[0] != null)
			tk.setAttribute("Status", task.ST_COMPLETE);
		else if (today.after((Date)tk.getAttribute("ExpireDate")[0]))
			tk.setAttribute("Status", task.ST_LATE);
		else if (!today.before((Date)tk.getAttribute("StartDate")[0]))
			tk.setAttribute("Status", task.ST_OPEN);
		else
			tk.setAttribute("Status", task.ST_NEW);

		// order of the task (planTask) can be freely changed by user using MS Project
		planTaskObj.setAttribute("PreOrder", new Integer(preOrder));
		planTaskObj.setAttribute("Level", new Integer(level));
		planTaskObj.setAttribute("Order", new Integer(order));
		if (level == 0)
		{
			ptParentStack = new Stack();		// start all over
			planTaskObj.setAttribute("ParentID", String.valueOf(0));
		}
		else
		{
			if (level < lastLevel)
				ptParentStack.pop();				// reduce in level, back to older parent
			else if (level > lastLevel)
				ptParentStack.push(lastPlanTaskId);	// last planTask is my parent
			planTaskObj.setAttribute("ParentID", ptParentStack.peek());
		}
		ptMgr.commit(planTaskObj);
		lastPlanTaskId = String.valueOf(planTaskObj.getObjectId());
		lastLevel = level;
		/////////// planTask done

		// at the end of the for loop, I am ready to save the attribute
		tk.setAttribute("LastUpdatedDate", now);
		tkMgr.commit(tk);

		// check to see if the project begin/end dates have to be moved
		if (pjStart.after((Date)tk.getAttribute("StartDate")[0]))
			pjStart = (Date)tk.getAttribute("StartDate")[0];
		if (pjEnd.before((Date)tk.getAttribute("ExpireDate")[0]))
			pjEnd = (Date)tk.getAttribute("ExpireDate")[0];

		// remember task id for fixing dependency at the end of program
		tkIdArr.add(String.valueOf(tk.getObjectId()));
	}
	in.close();

	// fix the dependency: change preOrder to taskId
	for (int i=0; i<depArr.size(); i++)
	{
		String tkId = (String)depArr.get(i);
		if (tkId == null) break;		// done
		tk = (task)tkMgr.get(pstuser, tkId);
		Object [] id = tk.getAttribute("Dependency");
		tk.setAttribute("Dependency", null);
		for (int j=0; j<id.length; j++)
		{
			if (id[j]==null || ((String)id[j]).equals("0")) continue;
			tk.appendAttribute("Dependency", tkIdArr.get(Integer.parseInt((String)id[j])-1));
		}
		tkMgr.commit(tk);
	}

	// project get updated
	p.setAttribute("LastUpdatedDate", now);
	p.setAttribute("StartDate", pjStart);
	p.setAttribute("ExpireDate", pjEnd);
	pMgr.commit(p);

	session.setAttribute("planStack", null);	// so that planStack will be rebuilt in proj_plan.jsp
	System.out.println("Import of MS Project done.");

	response.sendRedirect("proj_profile.jsp?projId="+projIdS);	// default

%>
