<%@ page contentType="text/html; charset=utf-8"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<%
//
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_updall.jsp
//	Author: ECC
//	Date:		07/19/2005
//	Description:	Update a number of tasks
//	Modification:
//		@ECC112405	Added Duration and Gap to task.  We can now calculate StartDate of a task
//					based on the Dependency and Gap, and ExpireDate by Duration.  Rules follow:
//					0.  No Duration or Duration==0 - ignore Gap, use entered SD and ED
//					1.  With Duration and LDT (last dep task) - simple calculation of SD and ED
//					2.  With Duration and NO LDT - use Project StartDate (SD) to calculate
//		@AGQ050306	Support of TBD, N/A
//		@AGQ050406	Handled parse exceptions
//
/////////////////////////////////////////////////////////////////////
//%>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.PmpException" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.text.*" %>
<%@ page import = "org.apache.log4j.Logger" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%!
	final static String format = "MM/dd/yy";
	final static SimpleDateFormat df = new java.text.SimpleDateFormat(format);

	static Integer getIntegerValue(String val) {
		Integer retInt;
		if (val != null && val.length() > 0 && !val.equals("0"))
			retInt = new Integer(val);
		else
			retInt = null;
		return retInt;
	}

	static Date getDateValue(String val) {
		if (val == null)
			return null;
		val = val.trim();

		try {
			Date dt = df.parse(val);
			return dt;
		} catch (ParseException e) {
			return null;
		}
	}

	static String fixDateString(String dtS)
	{
		String retS = "";
		StringTokenizer tk = new StringTokenizer(dtS, "/");
		while (tk.hasMoreTokens()) {
			if (retS != "") retS += "/";
			String s = tk.nextToken();
			if (s.length() == 1) {
				retS += "0" + s;
			}
			else {
				retS += s;
			}
		}
		return retS;
	}
%>

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");
	
	// TODO: Rules (not done):
	// 1. StartDate must be after parent StartDate (done)
	// 2. Actual Start (EffectiveDate) cannot be in the future (done).
	// 3. Actual Finish (CompleteDate) cannot be in the future (done).
	// 4. CompleteDate !before EffectiveDate
	// 5. ExpireDate !before StartDate

	if (pstuser instanceof PstGuest) {
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	Logger l = PrmLog.getLog();

	boolean isAdmin = false;
	int iRole = ((Integer) session.getAttribute("role")).intValue();
	if ((iRole & user.iROLE_ADMIN) > 0)
		isAdmin = true;
	// for admin, only take the face value, do not change anything implicit
	// or follow any rules.  Just change the values as submitted by the form.

	// back to page
	String projIdS = request.getParameter("projId");

	taskManager tkMgr = taskManager.getInstance();
	projectManager pjMgr = projectManager.getInstance();
	project pj = (project) pjMgr.get(pstuser, Integer.parseInt(projIdS));

	// check authority, only admin and project owner can perform this page action
	int myUid = pstuser.getObjectId();
	int pjOwnerId = Integer.parseInt((String) pj.getAttribute("Owner")[0]);
	boolean bAuthorizedUpdate = isAdmin || myUid==pjOwnerId;
	
	ArrayList<String> errList = new ArrayList<String>();
	session.setAttribute("errorList", errList);
	
	////////////////////////////////////////////////////
	// perform specific operations
	String op = request.getParameter("op");
	if (!StringUtil.isNullOrEmptyString(op)) {
		if (op.equals("copyPlanToOriginal")) {
			// copy planned dates to original dates
			if (bAuthorizedUpdate) {
				int [] ids = pj.getCurrentTasks(pstuser);
				task tkObj;
				Date dt;
				for (int tid : ids) {
					tkObj = (task) tkMgr.get(pstuser, tid);
					dt = tkObj.getStartDate();
					tkObj.setAttribute("OriginalStartDate", dt);
					dt = tkObj.getExpireDate();
					tkObj.setAttribute("OriginalExpireDate", dt);
					tkMgr.commit(tkObj);
				}
				Util3.refreshPlanHash(pstuser, session, projIdS);
				String msg = StringUtil.getLocalString(StringUtil.TYPE_MESSAGE, null, "MSG.10101");
				errList.add(msg);
			}
		}
		response.sendRedirect("task_updall.jsp?projId=" + projIdS);
		return;
	}
	////////////////////////////////////////////////////
	
	
/*
	if (!isAdmin && myUid != pjOwnerId) {
		response.sendRedirect("../out.jsp?msg=You are not authorized to perform this action. "
						+ "Please contact Administration for further assistance.");
		return;
	}
*/

	////////////////////////////////////////
	// begin build taskMap for dependencies

	// hashMap to map header# and taskID for building dependencies at the end
	HashMap<String, String> taskMap = new HashMap<String, String>(100);

	// hashMap for reverse map taskID to header number for output error message
	HashMap<String, String> taskReverseMap = new HashMap<String, String>(100);

	// get plan stack from session
	Stack planStack = (Stack) session.getAttribute("planStack");
	if ((planStack == null) || planStack.empty()) {
		response.sendRedirect("../out.jsp?msg=You project plan cannot be empty.  Please try again.");
		return;
	}

	Object[] pLevel;
	Object[] pOrder;
	int level, order;
	Vector rPlan = (Vector) planStack.peek();
	String[] levelInfo = new String[10];

	for (int i = 0; i < rPlan.size(); i++) {
		Hashtable rTask = (Hashtable) rPlan.elementAt(i);
		String taskIdS = (String) rTask.get("TaskID");
		pLevel = (Object[]) rTask.get("Level");
		pOrder = (Object[]) rTask.get("Order");

		level = ((Integer) pLevel[0]).intValue();
		order = ((Integer) pOrder[0]).intValue() + 1;

		if (level == 0) {
			levelInfo[level] = Integer.toString(order);
		} else {
			levelInfo[level] = levelInfo[level - 1] + "." + order;
		}

		// save the taskID into map for later use in building dependencies
		taskMap.put(levelInfo[level], taskIdS);
		taskReverseMap.put(taskIdS, levelInfo[level]);	// for output error msg
	}
	// done building taskMap for dependencies
	///////////////////////////////////////
	
	Date now = new Date();
	Date latestDate = new Date(0);
	Date today = Util.getToday();
	String[] sa;

	// get the list of tasks that are updated
	task tk = null;
	String s, st;
	Date oriStartD, oriExpireD, startD, expireD, actualD, completeD, oldStart, dt;
	Integer gapI, durI;
	boolean bUpdated = false;
	Double weightDbl;

	// to check if session is CR or PRM
	boolean isCRAPP = false;
	String app = (String) session.getAttribute("app");
	if (app.equals("CR"))
		isCRAPP = true;

	ArrayList<String> updateTaskList = new ArrayList<String>(100);
	for (Enumeration e = request.getParameterNames(); e.hasMoreElements();) {
		String temp = (String) e.nextElement();
		if (temp.startsWith("update_")) {
			// only those that are checked would be included
			updateTaskList.add(temp.substring(7));
		}
	}

	int [] tidArr = Util2.toIntArray(updateTaskList.toArray(new String[0]));
	Arrays.sort(tidArr);	// sort int is most reliable like in 999, 1000, ...
	
	HashMap<String,String> dirtyMap = (HashMap) session.getAttribute("taskDirtyMap");

	for (int z=0; z<tidArr.length; z++)
	{
		int tId = tidArr[z];
		System.out.println("*** tid=" + tId);
		tk = (task) tkMgr.get(pstuser, tId);
		tk.setDirtyMap(dirtyMap);		// assoc the dirty map to keep update info on task.save()

		// check authority
		if (!bAuthorizedUpdate) {
			s = (String)tk.getAttribute("Owner")[0];
			if (myUid != Integer.parseInt(s)) {
				l.warn("Unauthorized user [" + s + "] attempts to update task [" + tId + "] - rejected.");
				continue;		// simply ignore the update of this task
			}
		}

		// get the input parameters
		s = (String) request.getParameter("Dur_" + tId);
		durI = getIntegerValue(s);
		s = (String) request.getParameter("Gap_" + tId);
		gapI = getIntegerValue(s);

		s = (String) request.getParameter("OriStart_" + tId);
		oriStartD = getDateValue(s);
		s = (String) request.getParameter("OriExpire_" + tId);
		oriExpireD = getDateValue(s);

		// resource management: weight
		s = request.getParameter("Wt_" + tId);
		if (s != null) {
			weightDbl = Double.parseDouble(s);
		}
		else {
			weightDbl = null;
		}

		// for Admin, just take the face value and ignore any rule
		// nothing is disabled for Admin, everything has a value or blank
		if (isAdmin) {
			// Duration, Gap, StartDate, ExpireDate, EffectiveDate, CompleteDate
			// Owner, Dependency
			if (durI != null && gapI == null) {
				gapI = new Integer(0); // default gap to 0 if there is a duration specified
			}

			s = (String) request.getParameter("Start_" + tId);
			startD = getDateValue(s);
			s = (String) request.getParameter("Expire_" + tId);
			expireD = getDateValue(s);
			s = (String) request.getParameter("Actual_" + tId);
			actualD = getDateValue(s);
			s = (String) request.getParameter("Finish_" + tId);
			completeD = getDateValue(s);

			if (expireD != null && expireD.after(latestDate))
				latestDate = expireD;

			s = (String) request.getParameter("Owner_" + tId);
			tk.setOwner(pstuser, s); // might need to change owner of step

			///////////////////////////////////////////////////////
			// build dependencies
			String depS;
			depS = request.getParameter("Depend_" + tId);
			tk.setAttribute("Dependency", null);

			if (depS != null && depS.trim().length() > 0) {
				String depHeader, depIdS;
				sa = depS.split("(,|;)");
				for (int i = 0; i < sa.length; i++) {
					depHeader = sa[i].trim();
					if (depHeader.endsWith(".0")) {
						depHeader = depHeader.substring(0, depHeader
								.lastIndexOf(".0"));
					}
					depIdS = taskMap.get(depHeader);
					if (depIdS == null) {
						System.out
								.println("post_updall.jsp: depend Id ["
										+ depIdS
										+ "] not found in hash map.");
						continue;
					}
					tk.appendAttribute("Dependency", depIdS);
				}
				// done with this task
				System.out.println("Saved dependency for ["
						+ tk.getObjectId()
						+ "]: "
						+ Util2.getAttributeString(tk, "Dependency",
								", "));
			}

			tk.setAttribute("Duration", durI);
			tk.setAttribute("Gap", gapI);
			tk.setAttribute("OriginalStartDate", oriStartD);
			tk.setAttribute("StartDate", startD);
			tk.setAttribute("OriginalExpireDate", oriExpireD);
			tk.setAttribute("ExpireDate", expireD);
			tk.setAttribute("EffectiveDate", actualD);
			tk.setAttribute("CompleteDate", completeD);
			tk.setPlanDates(pstuser);

			tk.setWeight(pj, weightDbl);
			tkMgr.commit(tk);

			// TODO: need to set gap/dur by date also
		
			// if StartDate, ExpireDate, Gap and Duration are all null/zero, set State to NEW and leave
			if (startD==null && expireD==null && tk.getGap()==0 && tk.getDuration()==0) {
				tk.setAttribute(task.ATTR_STATUS, task.ST_NEW);		// force setting
				tkMgr.commit(tk);
			}
			else {
				tk.setStatusByDates(pstuser); // need to fix state and step
			}
			bUpdated = true;

			continue;
		} // END if isAdmin()

		////////////////////////////////////////////////////////////////////////////////////////////////////
		// normal user

		// original planned dates
		// only project owner can update
		if (myUid == pjOwnerId) {
			tk.setAttribute("OriginalStartDate", oriStartD);
			tk.setAttribute("OriginalExpireDate", oriExpireD);
		}

		///////////////////////////////////////////////////////////
		// duration and gap

		// duration @ECC112405
		tk.setAttribute("Duration", durI);

		// gap @ECC112405
		if (durI != null && gapI == null)
			gapI = new Integer(0); // default gap to 0 if there is a duration specified
		tk.setAttribute("Gap", gapI);

		///////////////////////////////////////////////////////////
		// start date
		if (gapI == null || gapI.intValue() == 0) {
			// use the user's input dates
			oldStart = (Date) tk.getAttribute("StartDate")[0];

			s = (String) request.getParameter("Start_" + tId);
			if (s != null && s.length() > 0) {
				try {
					startD = df.parse(s);
					dt = tk.getParentTaskStartDate(pstuser); // Rule 1: StartDate must after parent's StartDate
					if (dt != null && dt.after(startD)) {
						// relax Rule1: optimize StartDate schedule by extending parent as much as possible
						// this will be done alright in setPlanDates() below
						//startD = dt;
					}
				} catch (ParseException pe) {
					response.sendRedirect("../out.jsp?msg=You cannot set the START DATE to '"
							+ s + "' for task [" + taskReverseMap.get(String.valueOf(tId)) + "].");
					return;
				}
			} else if (s != null) {
				startD = null; // blank
			} else {
				// null input: disabled
				startD = (Date) tk.getAttribute("StartDate")[0];
			}
			tk.setAttribute("StartDate", startD);
			System.out.println("!!!!!!! set STartDate=" + startD);

			if (!isAdmin && durI == null && startD != null
					&& oldStart != null && startD.after(oldStart)) {
				// No need to do this if I am to call setPlanDates() later
				// (i.e. if durI != null)
				// my schedule may be extended because of the following call,
				// but don't worry, it will get fixed when enhandling ExpireDate
				// or by calling setPlanDates()

				// Rule 3: recursive ensure my children start after me.
				tk.moveChildrenForward(pstuser);
			}
		} // if no Gap specified, take consideration of StartDate

		///////////////////////////////////////////////////////////
		// expire date
		if (durI == null) {
			s = (String) request.getParameter("Expire_" + tId);
			if (s != null && s.length() > 0) {
				s = fixDateString(s);
				try {
					expireD = df.parse(s);	//phase.parseStringToDate(s, format);
				} catch (ParseException pe) {
					response.sendRedirect("../out.jsp?msg=You cannot set the DEADLINE DATE to '"
							+ s + "' for task [" + taskReverseMap.get(String.valueOf(tId)) + "].");
					return;
				}
				dt = tk.getChildrenLatestExpireDate(pstuser);
				if (dt != null && dt.after(expireD))
					expireD = dt; // need to extend the schedule to enclose children
				tk.setAttribute("ExpireDate", expireD); // need this before calling setSaveMyDependentsDates()
				if (gapI == null) {
					// No need to do this if I am to call setPlanDates() later (i.e. if gapI != null)
					tk.setSaveMyDependentsDates(pstuser);
				}
				// @AGQ050306 Ignore special dates when comparing the lastest expire date
				if (!phase.isSpecialDate(expireD)
						&& expireD.after(latestDate))
					latestDate = expireD;
			} else if (s != null) {
				// blank because s.length() is 0
				// set expire date based on latest child
				expireD = tk.getChildrenLatestExpireDate(pstuser);
			} else {
				// null input: disabled
				expireD = (Date) tk.getAttribute("ExpireDate")[0];
			}
			System.out.println("!!!!!!! set ExpireDate=" + expireD);
			tk.setAttribute("ExpireDate", expireD);
			if (!isAdmin && gapI == null)
				tk.checkExtendParent(pstuser); // ensure Rule 3
				
			// set Duration now
			tk.setDuration();
		} // if no Duration specified, take consideration of ExpireDate

		////////////////////////////
		// consider copyover original dates to plan dates
		if (tk.getState().equals(task.ST_NEW) &&
			oriStartD!=null && oriExpireD!=null) {
			// both original start and original expire are filled
			if (tk.getStartDate() == null) tk.setAttribute("StartDate", oriStartD);
			if (tk.getExpireDate() == null) tk.setAttribute("ExpireDate", oriExpireD);
		}

		///////////////////////////////////////////////////////////
		// effective date (actual start)
		s = (String) request.getParameter("Actual_" + tId);
		if (s != null && s.length() > 0) {
			try {
				actualD = df.parse(s);
				if (actualD.after(today)) {
					response.sendRedirect("../out.jsp?msg=You cannot set the ACTUAL START DATE to '" + s
							+ "' in the future for task [" + taskReverseMap.get(String.valueOf(tId)) + "].");
					return;
				}
			} catch (ParseException pe) {
				response.sendRedirect("../out.jsp?msg=You cannot set the ACTUAL START DATE to '"
							+ s + "' for task [" + taskReverseMap.get(String.valueOf(tId)) + "].");
				return;
			}
		} else if (s != null) {
			actualD = null; // blank
		} else {
			// null input: disabled
			actualD = (Date) tk.getAttribute("EffectiveDate")[0];
		}
		tk.setAttribute("EffectiveDate", actualD);

		///////////////////////////////////////////////////////////
		// complete date (actual finish)
		s = (String) request.getParameter("Finish_" + tId);
		if (s != null && s.length() > 0) {
			s = fixDateString(s);
			try {
				completeD = df.parse(s);	//phase.parseStringToDate(s, format);
				if (completeD.after(today)) {
					response.sendRedirect("../out.jsp?msg=You cannot set the ACTUAL FINISH DATE to '"
							+ s + "' in the future for task [" + taskReverseMap.get(String.valueOf(tId)) + "].");
					return;
				}
			} catch (ParseException pe) {
				response.sendRedirect("../out.jsp?msg=You cannot set the ACTUAL FINISH DATE to '"
							+ s + "' for task [" + taskReverseMap.get(String.valueOf(tId)) + "].");
				return;
			}
			dt = (Date) tk.getAttribute("CompleteDate")[0]; // old CompleteDate
			tk.setAttribute("CompleteDate", completeD);
			if (dt != null && completeD.compareTo(dt) != 0)
				tk.setSaveMyDependentsDates(pstuser);

			// if user fills completeD but effectiveD is empty, fill it for him
			if (tk.getEffectiveDate() == null) {
				tk.setAttribute("EffectiveDate", completeD);
			}
		} else {
			completeD = null;
			tk.setAttribute("CompleteDate", null);
		}

		///////////////////////////////////////////////////////
		// build dependencies
		String depS;
		depS = request.getParameter("Depend_" + tId);
		tk.setAttribute("Dependency", null);

		if (depS != null && depS.trim().length() > 0) {
			String depHeader, depIdS;
			sa = depS.split("(,|;)");
			for (int i = 0; i < sa.length; i++) {
				depHeader = sa[i].trim();
				if (depHeader.endsWith(".0")) {
					depHeader = depHeader.substring(0, depHeader
							.lastIndexOf(".0"));
				}
				depIdS = taskMap.get(depHeader);
				if (depIdS == null) {
					l.error("post_updall.jsp: depend Id ["
							+ depIdS + "] not found in hash map.");
					continue;
				}
				if (Integer.parseInt(depIdS) == tId) {
					l.error("post_updall.jsp: a task cannot depend on itself.  Ignored.");
					continue;
				}
				tk.appendAttribute("Dependency", depIdS);
			}
			// done with this task
			System.out.println("Saved dependency for ["
					+ tk.getObjectId() + "]: "
					+ Util2.getAttributeString(tk, "Dependency", ", "));
		}

		///////////////////////////////////////////////////////////
		// @ECC112405
		// do this after attempt to set all the Dates
		// setPlanDates() has the intelligent to figure out the StartDate and ExpireDate based
		// on Dependency, Gap and Duration.  It will also check EffectiveDate and CompleteDate
		// to set the Status.
		task.setDebug(true);
		try {
			tk.setPlanDates(pstuser);
		} catch (PmpException ee) {
			response.sendRedirect("../out.jsp?msg=" + ee.getMessage());
			return;
		}

		// I need to set the status by dates
		try {
			tk.setStatusByDates(pstuser);
		} catch (PmpException ee) {
			response.sendRedirect("../out.jsp?msg=" + ee.getMessage());
			return;
		}

		// @ECC112405 No need to set task status based on new dates: done in setPlanDates()

		///////////////////////////////////////////////////////////
		// check for updating owner
		s = request.getParameter("Owner_" + tId);
		if (!s.equals(tk.getAttribute("Owner")[0]))
			tk.setOwner(pstuser, s);

		tk.setWeight(pj, weightDbl);

		///////////////////////////////////////////////////////////
		//
		tk.setAttribute("LastUpdatedDate", now);
		tkMgr.commit(tk);
		bUpdated = true;
		// System.out.println("Updated task [" +tId+ "]");
	} // END: for each updated task line

	// check to see if I need to extend project deadline
	if (bUpdated) {
		pj = tk.getProject(pstuser);	// refresh: might have changed
		if (!pj.isContainer()) {
			dt = (Date) pj.getAttribute("ExpireDate")[0];
			if (dt!=null && latestDate.after(dt)) {
				System.out.println("post_updall.jsp moving project ExpireDate to " + latestDate);
				pj.setAttribute("ExpireDate", latestDate);
			}
		}
		pj.setAttribute("LastUpdatedDate", now);
		pjMgr.commit(pj);
		Util3.refreshPlanHash(pstuser, session, projIdS);
	}

	if (!isCRAPP)
		response.sendRedirect("task_updall.jsp?projId=" + projIdS);
	else
		response.sendRedirect("cr.jsp?projId=" + projIdS);
%>
