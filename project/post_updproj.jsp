<%@ page contentType="text/html; charset=utf-8"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<%
//
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_updproj.java
//	Author: ECC
//	Date:		04/05/2004
//	Description:	Update project.
//	Modification:
//			@AGQ101904
//				Enforce state transition rules
//				Change Project Status to Closed
//			@AGQ102004
//				CompleteDate is set to "today date" only if CompleteDate is null.
//				Modified: Project is canceled, there are no status changes. but tasks cannot be modified
// 				Changes all tasks to be open if startdate is today
//			@102504AGQ
//				Tasks their subtasks that are Canceled & On-hold will not have a completedDate
//				 when the project status is set to Completed
//			@102604AGQ
//				Set Conditions for StartDate and ExpireDate
//			@ECC063005
//				Support project options.  Enable member update project plan.
//			@100905ECC
//				Support bug blog template.
//			@110705ECC
//				Add option to link a Phase or Sub-phase to Task.
//			@AGQ022806
//				Added expansion of distribution list
//			@AGQ030606
//				Change the owner of the DL when the project owner has changed
//			@AGQ050306
//				Supported to ignore special expire date (TBD, N/A) when child task has these dates
//			@ECC011707	Support Department Name in project, task and attachment for authorization.
//			@ECC060407	Support flexible combination of dept name for attachment authorization.
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
<%@ page import = "org.apache.log4j.Logger" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />


<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");	

	String repository = Util.getPropKey("pst", "FILE_UPLOAD_PATH");
	MultipartRequest mrequest = new MultipartRequest(request, repository, 100*1024*1024, "utf8");

	String projIdS = mrequest.getParameter("projId");
	if ((pstuser instanceof PstGuest) || (projIdS == null))
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	Logger l = PrmLog.getLog();

	boolean isAdmin = false;
	boolean isProgMgr = false;
	int iRole = Util.getRoles(pstuser);
	if ( (iRole & user.iROLE_ADMIN) > 0 )
		isAdmin = true;
	if ((iRole & user.iROLE_PROGMGR) > 0)
		isProgMgr = true;
	boolean isAcctMgr = ((iRole & user.iROLE_ACCTMGR) > 0);

	boolean isCRAPP = false;
	String app = (String)session.getAttribute("app");
	if (app.indexOf("CR")!=-1)
		isCRAPP = true;

	// @ECC080108 Multiple company
	boolean isMultiCorp = false;
	String s = Util.getPropKey("pst", "MULTICORPORATE");
	if (s!=null && s.equalsIgnoreCase("true"))
		isMultiCorp = true;

	int myUid = pstuser.getObjectId();

	String Owner = mrequest.getParameter("Owner");
	String privacyType = mrequest.getParameter("ProjectPrivacy");
	String Status = mrequest.getParameter("Status");
	String StartDate = mrequest.getParameter("StartDate");
	String ExpireDate = mrequest.getParameter("ExpireDate");
	if (StringUtil.isNullOrEmptyString(ExpireDate)) {
		ExpireDate = null;		// set to container project
	}
	String doneDate = mrequest.getParameter("CompletionDate");
	if (StringUtil.isNullOrEmptyString(doneDate) || doneDate.equals("-")) {
		doneDate = null;
	}
	String descText = mrequest.getParameter("Description");
	String [] TeamMembers = mrequest.getParameterValues("TeamMembers");
	String AlertCondition = mrequest.getParameter("AlertCondition");
	String [] AlertPersonnel = mrequest.getParameterValues("AlertPersonnel");
	String AlertMessage = mrequest.getParameter("AlertMessage");
	String taskOwner = mrequest.getParameter("TaskOwner");
	String townIdS = mrequest.getParameter("TownId");
	String [] deptNames = mrequest.getParameterValues("Departments");	// @ECC060407
	String guestListS = mrequest.getParameter("Guest");
	String category = mrequest.getParameter("Category");
	String projDispName = mrequest.getParameter("ProjDispName");	// allow changing project display name
	if (projDispName != null) projDispName = projDispName.trim();
	
	String op = mrequest.getParameter("op");

	taskManager tMgr = taskManager.getInstance();
	planTaskManager ptMgr = planTaskManager.getInstance();
	projectManager pjMgr = projectManager.getInstance();
	project p = (project)pjMgr.get(pstuser, Integer.parseInt(projIdS));
	
	// see if we are performing specific operations for the project
	if (!StringUtil.isNullOrEmptyString(op)) {
		l.info("Operation on project [" + p.getDisplayName() + "] - " + op);
		if (op.equals("setDueDate")) {
			p.setDueDateBySchedule(pstuser);
		}
	
		// done
		response.sendRedirect("proj_profile.jsp?projId="+projIdS);	// default
		return;
	}

	// handle task
	String currentStatus = (String)p.getAttribute("Status")[0];

	//Date today = new Date();

	java.text.SimpleDateFormat df = new java.text.SimpleDateFormat("MM/dd/yyyy");
	Date now = new Date();
	Date today = df.parse(df.format(now));
	Date dt;

	// @102604AGQ added variables
	Date ExpireDateVal, StartDateVal, currentExpireDate, currentStartDate, currentCompleteDate, taskStartDate;
	int [] ptId;
	int [] ids;
	planTask pt;
	String [] sa;

	currentExpireDate = (Date)p.getAttribute("ExpireDate")[0];	// ECC: don't need to format
	currentStartDate = (Date)p.getAttribute("StartDate")[0];	// ECC: don't need to format
	currentCompleteDate = p.getCompleteDate();

	// Moved StartDate to top so it will not affect Status Change when Status Change modifies the StartDate
	if(StartDate != null)
	{
		if (StartDate.length() > 0)
		{
			StartDateVal = df.parse(StartDate);		//new Date(StartDate);

			// need to check if theres changes
			if (StartDateVal.compareTo(currentStartDate) != 0) {

				// Start Date cannot be changed if status is already opened
				if (!isAdmin && !isAcctMgr && !currentStatus.equals("New")) {
					response.sendRedirect("../out.jsp?msg=You cannot set the PROJECT START DATE if the PROJECT STATUS is not NEW.");
					return;
				}
				// Need to check that PROJECT START DATE is not after TASK START DATE
				// only need to check children.
				ids = planManager.getInstance().findId(pstuser, "Status='Latest' && ProjectID='"+projIdS+"'");

				ptId = ptMgr.findId(pstuser, "Status!='Deprecated' && ParentID='0' && PlanID='" + ids[0] + "'");
				Arrays.sort(ptId);		// ascending order

				//ptId = ptMgr.findId(pstuser, "ParentID='" + pt.getObjectId() + "'");
				for (int i=0; i<ptId.length; i++)
				{
					// for each child task, compare the start date
					pt = (planTask)ptMgr.get(pstuser, ptId[i]);
					task childTask = (task)tMgr.get(pstuser, (String)pt.getAttribute("TaskID")[0]);
					dt = (Date)childTask.getAttribute("StartDate")[0];
					if (dt != null)
					{
						dt = df.parse(df.format(dt));	// ECC: need to format because of older data has non 0:0 time
						if (StartDateVal.after(dt))
						{
System.out.println("name=" + pt.getStringAttribute("Name"));
System.out.println("stDt=" + dt);
System.out.println("startVal="+ StartDateVal);
							response.sendRedirect("../out.jsp?msg=You cannot set the PROJECT START DATE to be after the Task ("
								+ (String)pt.getAttribute("Name")[0] + ") start date.");
							return;
						}
					}
				}

				p.setAttribute("StartDate", StartDateVal);
			}
		}
		else // Copied this from ExpireDate logic
			p.setAttribute("StartDate", null);
	}

	// cannot change to New or Late
	// cannot change if it is already Closed
	// handle Late elsewhere

	p.setState(pstuser, Status);


	p.setAttribute("Type", privacyType);

	// transfer ownership
	if(!Owner.equals(p.getAttribute("Owner")[0]))
	{
		// new owner selected
		p.setAttribute("Owner", Owner);
// @AGQ030606
		// set DL owner to new owner
		try {
		dlManager dlMgr = dlManager.getInstance();
		dl dlObj = (dl)dlMgr.get(pstuser, dl.DLESCAPESTR + p.getObjectName());
		dlObj.setAttribute(dl.OWNER, Owner);
		dlMgr.commit(dlObj);
		} catch (PmpException e) {
			// Cannot find dlObj by name
		}
	}

	// check if need to transfer ownership for all tasks
	if (taskOwner != null)
	{
		ids = tMgr.findId(pstuser, "ProjectID='" + projIdS + "'");
		for (int i=0; i<ids.length; i++)
		{
			task t = (task)tMgr.get(pstuser, ids[i]);
			if (!Owner.equals(t.getAttribute("Owner")[0]))
			{
				t.setAttribute("Owner", Owner);
				t.setAttribute("LastUpdatedDate", today);
				tMgr.commit(t);
			}
		}
	}

	// description
	if (descText != null) {
		descText = descText.replaceAll("\n", "<p>");
		p.setAttribute("Description", descText.getBytes("utf-8"));
	}
	else
		p.setAttribute("Description", null);
// @AGQ022806
	// team
	int length = 0;
	if (TeamMembers != null) length = TeamMembers.length;

	// @ECC030609 check for limit on subscription level
	userManager uMgr = userManager.getInstance();
	PstAbstractObject ui, u;
	if (isCRAPP && isMultiCorp)
	{
		ArrayList al = new ArrayList();
		String levelS;
		for (int i=0; i<length; i++)
		{
			ui = userinfoManager.getInstance().get(pstuser, TeamMembers[i]);
			levelS = town.getLevelString((String)ui.getAttribute("Status")[0]);
			if (levelS==null || (!levelS.contains(userinfo.LEVEL_4) && !levelS.contains(userinfo.LEVEL_3)) )
			{
				u = uMgr.get(pstuser, Integer.parseInt(TeamMembers[i]));
				ids = pjMgr.getProjects((user)u, true);
				if (ids.length>=3 && !Util2.foundAttribute(p, "TeamMembers", myUid))
					continue;
			}
			al.add(TeamMembers[i]);
		}
		TeamMembers = (String [])al.toArray(new String [0]);	// this code helps to make the type cast works
		length = TeamMembers.length;
	}

	// get all team members from DL and normal user Ids
	if (length > 0) {
		dlManager dlMgr = dlManager.getInstance();
		Object [] objArr = dlMgr.getUsers(pstuser, TeamMembers, false);
		p.setAttribute(dl.TEAMMEMBERS, objArr);
	}
	//else
		//p.setAttribute(dl.TEAMMEMBERS, null);

	// add guest members if any
	if (!Util.isNullOrEmptyString(guestListS)) {
		sa = guestListS.split("(,|;)");
		for (int i=0; i<sa.length; i++) {
			s = sa[i].trim();
			if (s.indexOf('@') == -1) {
				// regular username in PRM
				try {u = uMgr.get(pstuser, s);}
				catch (PmpException e) {System.out.println("Cannot find guest " + s); continue;}
			}
			else {
				// email
				try {
					ids = uMgr.findId(pstuser, "Email='" + s + "'");
					if (ids.length <= 0) {System.out.println("Cannot find guest with email " + s); continue;}
					u = uMgr.get(pstuser, ids[0]);
				}
				catch (PmpException e) {continue;}
			}
			p.appendAttribute("TeamMembers", new Integer(u.getObjectId()));
		}
	}
	
	// by this time, the TeamMembers are all set, read to do cross adding of contacts between members
	// use thread for performance
	UtilThread uThread = new UtilThread(UtilThread.APPEND_CONTACTS, pstuser, p);
	uThread.start();
	

	// @ECC063005 project options
	String optStr = null;
	for (int i=0; i<project.OPTION_ARRAY.length; i++)
	{
		if ((mrequest.getParameter(project.OPTION_ARRAY[i])) != null) {
			if (project.OPTION_ARRAY[i].equals(project.OP_RESOURCE_MGMT)) {
				// for resource mgmt, put more info for easier customization
				optStr = project.DEFAULT_RSC_MGMT;
			}
			else {
				optStr = "";
			}
			p.setOption(project.OPTION_ARRAY[i], optStr);	// set
		}
		else {
			p.setOption(project.OPTION_ARRAY[i], null);		// unset
		}
	}

	// @071906ECC
	if (!StringUtil.isNullOrEmptyString(townIdS)) {
		p.setAttribute("Company", townIdS);
		p.setAttribute("TownID", townIdS);		// should obsolete
	}

	// @ECC011707
	// @ECC060407
	s = "";
	if (deptNames!=null)
	for (int i=0; i<deptNames.length; i++)
	{
		if (s.length() > 0) s += "@";		// construct DepartmentName string "dept1@dpet2@dept3 ..."
		s += deptNames[i];
	}
	if (s.length() <= 0) s = null;
	p.setAttribute("DepartmentName", s);


	// alert
	if (!isCRAPP)
	{
		p.setAttribute("AlertCondition", Integer.valueOf(AlertCondition));
		// @AGQ022806
		length = (AlertPersonnel != null)?AlertPersonnel.length:0;
		if(length > 0) {
			dlManager dlMgr = dlManager.getInstance();
			Object [] objArr = dlMgr.getUsers(pstuser, AlertPersonnel, true);
			p.setAttribute("Alert", objArr);
		}
		else
			p.setAttribute("Alert", null);

		p.setAttribute("AlertMessage", AlertMessage);
	}

	// handle expiration date which may need to charge the user
	if(ExpireDate != null)
	{
		if (ExpireDate.length() > 0)
		{
			ExpireDateVal = new Date(ExpireDate);

			// need to check if theres changes
			if (ExpireDateVal.compareTo(currentExpireDate) != 0)
			{
				// cannot be before today
				if (ExpireDateVal.before(today)
						&& (Status.equals(project.ST_OPEN) || Status.equals(project.ST_LATE)) )
				{
					response.sendRedirect("../out.jsp?msg=You cannot set the PROJECT EXPIRATION DATE to the past.");
					return;
				}

				// cannot be before task expiredate
				Date latestDt = p.getLatestTaskExpireDate(pstuser);
				if (ExpireDateVal.before(latestDt)) {
					response.sendRedirect("../out.jsp?msg=You cannot set the PROJECT EXPIRATION DATE to before the LASTEST TASK EXPIRATION DATE ("
							+ df.format(latestDt) +").");
					return;
				}

				// cannot be before or on startdate
				if (!ExpireDateVal.after(currentStartDate))
				{
					response.sendRedirect("../out.jsp?msg=You cannot set the PROJECT EXPIRATION DATE to before or on the START DATE.");
					return;
				}

				ids = planManager.getInstance().findId(pstuser, "Status='Latest' && ProjectID='"+projIdS+"'");

				ptId = ptMgr.findId(pstuser, "Status!='Deprecated' && ParentID='0' && PlanID='" + ids[0] + "'");
				Arrays.sort(ptId);		// ascending order

				//ptId = ptMgr.findId(pstuser, "ParentID='" + pt.getObjectId() + "'");
				for (int i=0; i<ptId.length; i++)
				{
					// for each child task, compare the start date
					pt = (planTask)ptMgr.get(pstuser, ptId[i]);
					task childTask = (task)tMgr.get(pstuser, (String)pt.getAttribute("TaskID")[0]);
					dt = (Date)childTask.getAttribute("ExpireDate")[0];	// ECC: don't need to format
					if (dt == null) continue;
					//dt = new Date(df.format(dt));
// @AGQ050306
					if (ExpireDateVal.before(dt) && !phase.isSpecialDate(dt))
					{
						response.sendRedirect("../out.jsp?msg=You cannot set the PROJECT EXPIRE DATE to be before the Task ("
							+ (String)pt.getAttribute("Name")[0] + ") expire date.");
						return;
					}
				}
				if(ExpireDateVal.after(today) && currentStatus.equals("Late") && Status.equals(currentStatus))
				{
					// if user set ExpireDateVal to a future date and
					// current Status is Late and User did not change Status to something else like Canceled"
					// then we'll set the Status back to Open
					p.setAttribute("Status", "Open");
				}


				p.setAttribute("ExpireDate", ExpireDateVal);
			}

		}
		else
		{
			p.setAttribute("ExpireDate", null);		// container project
		}
	}
	
	// completion date
	if (!StringUtil.isNullOrEmptyString(doneDate)) {
		dt = df.parse(doneDate);
		if (currentCompleteDate==null || dt.compareTo(currentCompleteDate)!=0)
			p.setAttribute("CompleteDate", dt);
	}
	
	// category
	if (!StringUtil.isNullOrEmptyString(category)) {
		p.setAttribute("Category", category);
	}


	// project summery
	s = mrequest.getParameter("SummeryTaskId");
	if (!StringUtil.isNullOrEmptyString(s)) {
		try {
			s = s.trim();
			Integer.parseInt(s);
			p.setOption(project.EXEC_SUMMARY, s);		// valid int
		}
		catch (Exception e) {/*ignore*/}
	}
	else {
			p.setOption(project.EXEC_SUMMARY, null);	// unset
	}

	// task blog id
	s = mrequest.getParameter("TaskBlogId");
	if (!StringUtil.isNullOrEmptyString(s)) {
		try {
			s = s.trim();
			Integer.parseInt(s);
			p.setOption(project.TASK_BLOG_ID, s);		// valid int
		}
		catch (Exception e) {/*ignore*/}
	}
	else {
			p.setOption(project.TASK_BLOG_ID, null);	// unset
	}

	// @100905ECC bug blog id
	s = mrequest.getParameter("BugBlogId");
	if (!StringUtil.isNullOrEmptyString(s)) {
		try {
			s = s.trim();
			Integer.parseInt(s);
			p.setOption(project.BUG_BLOG_ID, s);		// valid int
		}
		catch (Exception e) {/*ignore*/}
	}
	else {
			p.setOption(project.BUG_BLOG_ID, null);		// unset
	}

	// abbreviation
	s = mrequest.getParameter("Abbrev");
	if (!Util.isNullOrEmptyString(s)) {
		if (s.length()>5) s = s.substring(0,5);			// max 5 chars for abbreviation
		p.setOption(project.ABBREVIATION, s);
	}
	else {
		p.setOption(project.ABBREVIATION, null);			// unset
	}
	
	// change project display name
	String oriDisplayName = p.getDisplayName();
	if (!StringUtil.isNullOrEmptyString(projDispName) && !oriDisplayName.equals(projDispName)) {
		s = p.getObjectName();
		int idx;
		if ((idx = s.indexOf("@@")) != -1) {
			projDispName += s.substring(idx);	// suffix: @@12345
		}
		//projDispName = Util.stringToHTMLString(projDispName, false);
		p.setObjectName(projDispName);
	}

	// commit the project object
	p.setAttribute("LastUpdatedDate", now);
	pjMgr.commit(p);
	session.removeAttribute("planStack");		// cleanup cache


	response.sendRedirect("proj_profile.jsp?projId="+projIdS);	// default
%>
