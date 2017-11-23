<%@ page contentType="text/html; charset=utf-8"%>

<%
//
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_proj_new.java
//	Author: ECC
//	Date:		04/15/2004
//	Description:	Create a new project, project plan, task, etc.
//					For delete project, refer to Util.deleteProject().
//	Modification:
//
//		@AGQ030906	New DL made
//		@ECC011907	Default to expand project tree.
//		@ECC090508	Add owner id to project name to avoid collision.
//		@ECC040615	Add project chat. Add back DL.
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
<%@ page import = "com.oreilly.servlet.*" %>
<%@ page import = "org.apache.log4j.Logger" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");
	
	// create project, plan, planTask and task
	//task.setDebug(true);
	String townName = request.getParameter("TownName");
	if ((pstuser instanceof PstGuest) || (townName == null))
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	Logger l = PrmLog.getLog();
	String s;

	boolean isMeetWE = Prm.isMeetWE();

	int uid = pstuser.getObjectId();
	String uidS = String.valueOf(uid);

	townManager tnMgr			= townManager.getInstance();
	projectManager pjMgr		= projectManager.getInstance();
	planManager planMgr			= planManager.getInstance();
	planTaskManager planTaskMgr = planTaskManager.getInstance();
	taskManager tkMgr			= taskManager.getInstance();
	userManager uMgr			= userManager.getInstance();
	dlManager dlMgr 			= dlManager.getInstance();
	phaseManager phMgr			= phaseManager.getInstance();
	chatManager cMgr			= chatManager.getInstance();

	
	String townIdS = request.getParameter("TownID");
	String projName = request.getParameter("ProjName");
	projName += "@@" + uidS;
	String desc = request.getParameter("Description");
	String start = request.getParameter("StartDate");
	String expire = request.getParameter("ExpireDate");
	String option = request.getParameter("ProjectOption");
	String deptName = request.getParameter("Department");		// can be null
	if (deptName!=null && (deptName.length()==0 || deptName.equals("null")))
		deptName = null;

	SimpleDateFormat df0 = new SimpleDateFormat ("MM/dd/yyyy");		// incoming date format
	SimpleDateFormat df1 = new SimpleDateFormat("MMM dd, yyyy");
	
	String version = "1.0";
	Date today = new Date();
	Date expireDate = df0.parse(expire);	//new Date(expire);
	Date startDate = df0.parse(start);		//new Date(start);

	// hashMap to map header# and taskID for building dependencies at the end
	HashMap<String,String> taskMap = new HashMap<String,String>(128);

	// get plan stack from session
	Vector rPlan = null;
	Stack planStack = (Stack)session.getAttribute("planStack");		// this is set in proj_new3.jsp
	if ((planStack != null) && !planStack.empty()) {
		// planStack can be null if we come directly from proj_new1.jsp
		//response.sendRedirect("../out.jsp?msg=You project plan cannot be empty.  Please try again.");
		//return;
		rPlan = (Vector)planStack.peek();
	}

	town townObj = null;
	if (!StringUtil.isNullOrEmptyString(townName)) {
		if (StringUtil.isNullOrEmptyString(townIdS)) {
			try {townObj = (town)tnMgr.get(pstuser, townName);}
			catch (PmpException e) {
				// this exception should have been caught in proj_new1.jsp
				response.sendRedirect("../out.jsp?msg=5002&var0=" + townName);
				return;
			}
			townIdS = String.valueOf(townObj.getObjectId());
		}
	}
	else if (!isMeetWE) {
		// use the user's company
		townIdS = (String)pstuser.getAttribute("TownID")[0];
	}
	if (townObj==null && townIdS!=null) {
		townObj = (town)tnMgr.get(pstuser, Integer.parseInt(townIdS));
	}
	
	//////////////////////////////
	// check to see if we reach max no. of project (also in proj_new1.jsp)
	// The limit is set in the Town Option, default is 5.
	int [] ids;
	int maxProj;
	if (townObj != null) {
		maxProj = townObj.getLimit(town.MAX_PROJECT);
		if (maxProj <= 0) maxProj = town.DEFAULT_MAX_PROJ;

		s = townObj.getStringAttribute("Category");
		if (!"CPM".equals(s)) {
			ids = pjMgr.findId(pstuser, "TownID='" + townObj.getObjectId()
					+ "' && Option!='%" + project.PERSONAL + "%'");		// don't count personal project
		}
		else {
			// open village user, count project by individual user
			ids = pjMgr.getProjects(pstuser);
		}
	}
	else {
		maxProj = town.DEFAULT_MAX_PROJ;
		ids = pjMgr.getProjects(pstuser);
	}
	if (ids.length >= maxProj) {
		// exceed max no. of projecs allowed - will check again in post_proj_new.jsp
		response.sendRedirect("../out.jsp?msg=5001&go=info/upgrade.jsp");
		return;
	}
	//////////////////////////////

	// create the project object
	project proj = null;
	try {proj = (project)pjMgr.create(pstuser, projName);}
	catch (PmpException e) {
		response.sendRedirect("../out.jsp?go=ep/ep_home.jsp&msg=Error creating new project.<br><br>["
			+ e.getMessage() + "]"
			+ "<br><br>Please try again.  If problem persists, contact your Administrator.");
		return;
	}

	proj.setAttribute("TownID", townIdS);
	proj.setAttribute("Type", option);
	proj.setAttribute("Description", desc.getBytes("utf-8"));
	proj.setAttribute("CreatedDate", today);
	proj.setAttribute("StartDate", startDate);
	proj.setAttribute("ExpireDate", expireDate);
	proj.setAttribute("LastUpdatedDate", today);
	proj.setAttribute("Creator", uidS);
	proj.setAttribute("Owner", uidS);
	proj.setAttribute("TeamMembers", new Integer(uid));
	proj.setAttribute("Status", project.ST_NEW);	// need initialization
	proj.setAttribute("Version", version);

	// @ECC080108 support multi corp for CR
	String company = (String)pstuser.getAttribute("Company")[0];
	if (company != null)
		proj.setAttribute("Company", company);
	else
		proj.setAttribute("Company", townName);

	proj.setAttribute("DepartmentName", deptName);
	proj.setAttribute("Option", project.OP_EXPAND_TREE);

	// need to do commit here because task dates might use project dates
	pjMgr.commit(proj);

	
	String projIdS = String.valueOf(proj.getObjectId());

	// create the plan object
	plan planObj = proj.initPlan(pstuser);

	// create the task and planTask objects if user has specified any task
	if (rPlan != null) {
		task taskObj;
		int count = 0;
		String[] levelInfo = new String[10];
		Date dt, pjExpire = expireDate;
		String [] pTaskIdArr = new String[JwTask.MAX_TASKS];	// remember the planTask Id
		for(int i = 0; i < rPlan.size(); i++)
		{
			Hashtable rTask = (Hashtable)rPlan.elementAt(i);
			String pName = (String)rTask.get("Name");
			Integer pLevel = (Integer)rTask.get("Level");
			Integer pOrder = (Integer)rTask.get("Order");
			Integer pPreOrder = (Integer)rTask.get("PreOrder");
	
			int level = pLevel.intValue();
			int order = pOrder.intValue();
			order++;
			if (level == 0) {
				levelInfo[level] = Integer.toString(order);
			}
			else {
				levelInfo[level] = levelInfo[level - 1] + "." + order;
			}
	
			taskObj = (task)tkMgr.create(pstuser);
			taskObj.setAttribute("ProjectID",projIdS);
			taskObj.setAttribute("Creator",uidS);
			taskObj.setAttribute("Owner", uidS);
			taskObj.setAttribute("CreatedDate", today);
			taskObj.setAttribute("DepartmentName", deptName);
	
			// no need to call setState() when the whole project is new
			taskObj.setAttribute("Status", task.ST_NEW);
	
			// save the taskID into map for later use in building dependencies
			taskMap.put(levelInfo[level], String.valueOf(taskObj.getObjectId()));
	
			planTask planTaskObj = (planTask)planTaskMgr.create(pstuser);
			planTaskObj.setAttribute("PlanID",planObj.getObjectName());
			planTaskObj.setAttribute("Order", pOrder);
			planTaskObj.setAttribute("PreOrder", pPreOrder);
			planTaskObj.setAttribute("Level", pLevel);
			planTaskObj.setAttribute("Status", planTask.ST_ORIGINAL);
			planTaskObj.setAttribute("Name", pName);
			planTaskObj.setAttribute("TaskID", taskObj.getObjectName());
	
			if (level == 0) {
				planTaskObj.setAttribute("ParentID", String.valueOf(0));
			}
			else {
				int parentId = Integer.parseInt((String)rTask.get("ParentID"));
				planTaskObj.setAttribute("ParentID", pTaskIdArr[parentId-1]);
			}
			planTaskMgr.commit(planTaskObj);
			pTaskIdArr[count++] = String.valueOf(planTaskObj.getObjectId());
	
			int startGap = ((Integer)rTask.get("StartGap")).intValue();
			int length = ((Integer)rTask.get("Length")).intValue();
	
			// setPlanDates() sets the StartDate and ExpireDate.  This might extend the pjExpire
			if (startGap>0 || length>0)
			{
				taskObj.setAttribute("Gap", new Integer(startGap));
				taskObj.setAttribute("Duration", new Integer(length));
			}
			else
			{
				// assume this node is a container, not a task
				taskObj.setAttribute("ExpireDate", pjExpire);
			}
			taskObj.setAttribute("LastUpdatedDate", today);
			tkMgr.commit(taskObj);
		}
	
		// build dependencies and phase
		final String prefixDep = "Depend_";
		final String prefixPhs = "Phase_";
		
		HashMap<String, PstAbstractObject> phaseMap = new HashMap<String, PstAbstractObject> (20);
		HashMap<String, PstAbstractObject> headerPhaseMap = new HashMap<String, PstAbstractObject> (64);
		ArrayList<PstAbstractObject> subPhaseArr = new ArrayList<PstAbstractObject> (20);
		
		String headerNum, taskIdS, valS, parentIdS;
		int phNum;
		PstAbstractObject ph;
		String [] sa;
		for (Enumeration e = request.getParameterNames() ; e.hasMoreElements() ;)
		{
			String temp = (String)e.nextElement();
			
			// A. dependency
			if (temp.startsWith(prefixDep)) {
				// saving dependencies for this task (taskIdS)
				valS = request.getParameter(temp);
				if (valS==null || valS.trim().length()<=0)
					continue;
	
				headerNum = temp.substring(prefixDep.length());
				taskIdS = taskMap.get(headerNum);
				taskObj = (task)tkMgr.get(pstuser, taskIdS);
	
				String depHeader, depIdS;
				sa = valS.split("(,|;)");
				for (int i=0; i<sa.length; i++) {
					depHeader = sa[i].trim();
					depIdS = taskMap.get(depHeader);
					if (depIdS == null) {
						l.error("post_proj_new.jsp: depend Id [" + depIdS + "] not found in hash map.");
						continue;
					}
					taskObj.appendAttribute("Dependency", depIdS);
				}
				// done with this task
				tkMgr.commit(taskObj);
				System.out.println("Saved dependency for [" + taskObj.getObjectId() + "]: "
						+ Util2.getAttributeString(taskObj, "Dependency", ", "));
			}
			
			// B. phase / subphase
			else if (temp.startsWith(prefixPhs)) {
				// creating phase/subphase for this task (taskIdS)
				valS = request.getParameter(temp);
				if (valS==null || valS.trim().length()<=0)
					continue;
	
				headerNum = temp.substring(prefixPhs.length());
				taskIdS = taskMap.get(headerNum);
				taskObj = (task)tkMgr.get(pstuser, taskIdS);
				ph = phMgr.create(pstuser);				// can be phase or subphase
				
				sa = valS.split(" ");					// "Phase 1" or "Subphase 2.1"
				if (sa[0].startsWith("Phase")) {
					parentIdS = null;
					phNum = Integer.parseInt(sa[1]);	// the numeric after "Phase"
					phaseMap.put(sa[1], ph);
				}
				else {
					int idx = sa[1].indexOf('.');
					parentIdS = sa[1].substring(0, idx);				// numeric before the "." (main Phase num)
					phNum = Integer.parseInt(sa[1].substring(idx+1));	// numeric after the "."  (subPhase num)
					subPhaseArr.add(ph);				// need to recall later to fix the parentID
				}
				headerPhaseMap.put(headerNum, ph);		// for phase color later
				System.out.println("PhaseMap: " + headerNum + ", " + valS);
				
				// create phase/subphase object
				//phase.addTaskPhase(pstuser, taskObj);
				ph.setAttribute(phase.PROJECTID, projIdS);
				ph.setAttribute(phase.TASKID, taskIdS);
				ph.setAttribute(phase.PARENTID, parentIdS);				// for subphase, store the main phase num
				ph.setAttribute(phase.PHASENUMBER, phNum);
				ph.setAttribute(phase.CREATEDDATE, new Date());
				ph.setAttribute(phase.LASTUPDATEDDATE, new Date());
				phMgr.commit(ph);
			}
		}
		
		// C. fix parentID for subphases
		for (PstAbstractObject o : subPhaseArr) {
			parentIdS = o.getStringAttribute("ParentID");		// main phase num
			ph = phaseMap.get(parentIdS);						// retrieve the parent phase
			o.setAttribute("ParentID", ph.getObjectName());
			phMgr.commit(o);
		}
		
		// D. phase color
		// must be set after phases are created above
		final String prefixColor = "PhColor_";
		for (Enumeration e = request.getParameterNames() ; e.hasMoreElements() ;) {
			String temp = (String)e.nextElement();

			if (temp.startsWith(prefixColor)) {
				valS = request.getParameter(temp);
				if (StringUtil.isNullOrEmptyString(valS))
					continue;
				
				headerNum = temp.substring(prefixColor.length());
				ph = headerPhaseMap.get(headerNum);
				ph.setAttribute(phase.COLOR, valS);
				phMgr.commit(ph);
			}
		}
	
		// setting task dates depends on having planTaskObj (for searching parent task)
		// therefore it must be done after creation of planTask and dependencies
		// setPlanDates() must be called in order of taskIds because there is date dependencies
		// from children to parent
		String [] tidSArr = taskMap.values().toArray(new String[0]);
		int [] tidArr = Util2.toIntArray(tidSArr);
		Arrays.sort(tidArr);
		task.setDebug(true);
		for (int tid : tidArr) {
			taskObj = (task)tkMgr.get(pstuser, tid);
			taskObj.setPlanDates(pstuser);		// it will adjust proj/parent task expiration
			taskObj.setAttribute("OriginalStartDate", taskObj.getStartDate());
			taskObj.setAttribute("OriginalExpireDate", taskObj.getExpireDate());
			tkMgr.commit(taskObj);
		}
	}	// END if there is any task specified by the user

	// workflow
	// create project flow for tracking
	proj.createProjectFlow(pstuser);

	// history recording
	history.addRecord(pstuser, "HIST.3101",
			(String)proj.getAttribute("TownID")[0], null,
			String.valueOf(proj.getObjectId()));

	// create distribution list (dl)
	dl dlObj = (dl) dlMgr.create(pstuser, "DL. " + projName);
	dlObj.setAttribute(dl.CREATEDDATE, today);
	dlObj.setAttribute(dl.LASTUPDATEDDATE, today);
	dlObj.setAttribute(dl.OWNER, uidS);
	dlObj.setAttribute(dl.PROJECTID, projIdS);
	dlMgr.commit(dlObj);
	
	// @ECC040615 create chatroom for project
	// create personal space will not go thru here but project.createPersonalProject().
	PstAbstractObject cObj = cMgr.create(pstuser);
	cObj.setAttribute("Creator", uidS);
	cObj.setAttribute("Name", proj.getDisplayName());
	cObj.setAttribute("ProjectID", projIdS);
	cObj.setAttribute("CreatedDate", today);
	cMgr.commit(cObj);
	l.info("Done create project [" + projIdS + " - " + projName + "]");

	if (Prm.isCR())
		response.sendRedirect("cr.jsp?projId="+proj.getObjectId());
	else
		response.sendRedirect("proj_top.jsp?projId="+proj.getObjectId());
%>
