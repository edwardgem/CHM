<%
//
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_updphase.java
//	Author: ECC
//	Date:		09/28/2005
//	Description:	Update project phases.
//				To enter a sub-phase (one at a time), phase_update.jsp calls this
//				with the main phase ID (starts from 0) and the info of all its sub-phases.
//				The sub-phases info are stored in a blog (result) in a certain format.
//				Name::StartDate::ExpireDate::CompleteDate::Status<next> ...
//	Modification:
//		@110705ECC	Add option to link a Phase or Sub-phase to Task.  New sub-phase record:
//					Name::StartDate::ExpireDate::CompleteDate::Status::TaskID<next>
//		@ECC041206	Added PlanExpireDate to task and phase/subphase.  Also switch TID and SubPhaseExt in Phase record.
//					Phase record - Name::StartDate::PlanExpDate::ExpireDate::CompleteDate::Status::TaskID::Sub-PhaseExt
//					Sub-Phase re - Name::StartDate::PlanExpDate::ExpireDate::CompleteDate::Status::TaskID<next>
//		@AGQ042606	Changed from reading phase attribute to phase objects
//		@AGQ050306	Added TBD N/A support
//		@AGQ050406	Ignore TBD in start date
//		@AGQ050506	Support porting over information from taskID to phase.
//					Replaced getting previous information from phase to previous task instead.
//		@AGQ050806	Caught ParseException errors for Expire Date
//		@AGQ050906	Fix Bug 57060 & 57010: Support to detect if there are duplicated TASK ID and if TASK ID belongs to this project
//		@AGQ051106	Remove only 1 phase when delete is called
//		@AGQ051206	Set null due dates to TBD
//		@AGQ051606	Fix bug 57295 where Phase and Milestone name does not accept "\".
// 		@AGQ051706	Add in a default TBD expire date when a new cancelled phase is created
// 		@AGQ051706A	Copied over previous information when cancelled is selected
//		@AGQ071906A	Reedit @AGQ051206 to display empty dates instead of TBD
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

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%!
	private String trimOrNull(String val)
	{
		if (val != null) {
			val = val.trim();
			if (val.length()==0)
				val = null;
		}
		return val;
	}
%>

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");
	
	final String PROP_FILE = "bringup";

	String projIdS = request.getParameter("projId");
	if ((pstuser instanceof PstGuest) || (projIdS == null))
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}

	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ( (iRole & user.iROLE_ADMIN) > 0 )
		isAdmin = true;

	projectManager pMgr = projectManager.getInstance();
	resultManager rMgr = resultManager.getInstance();

	project p = (project)pMgr.get(pstuser, Integer.parseInt(projIdS));

	String format = "MM/dd/yy";
	java.text.SimpleDateFormat df = new java.text.SimpleDateFormat(format);
	Date now = new Date();
	Date today = df.parse(df.format(now));
	Date dt;

	int maxPhases = 7;	// default to 7
	int maxSubPhases = project.MAX_SUBPHASES;
	String s = Util.getPropKey(PROP_FILE, "PHS.TOTAL");
	if (s != null) maxPhases = Integer.parseInt(s);

	s = Util.getPropKey(PROP_FILE, "SUBPHS.TOTAL");
	if (s != null) maxSubPhases = Integer.parseInt(s);

	////////////////////////////////////////////////////////
	// update project phases
	// for each phase (PhaseName::StartDate::ExpireDate::CompleteDate::Status::Extension)
	// user enters the StartDate, ExpireDate and Status
	// note that the Start and Complete is implicitely applied when the Status is changed
	// in this case Start becomes Actual Start when Status changes from New to Open
	String ds, tks, oldSt, phTID;;
	String phName, phPlanExp, phExpire, phStatus, phStart, phDone, phExt, phColor;
	String subphName, subphPlanExp, subphExpire, subphStatus, subphStart,
			subphDone, subphTID, subDelete;
	String todayS = df.format(today);
	Date oldDone = null;
// @AGQ042606
	phaseManager phMgr = phaseManager.getInstance();
	taskManager tkMgr = taskManager.getInstance();
	PstAbstractObject [] objArr = null;
	PstAbstractObject deletePhase = null;
	PstAbstractObject [] subObjArr = null;
	phase ph = null;
	PstAbstractObject aObj = null;
	PstAbstractObject subAObj = null;
	phase subPh = null;
	Object obj = null;
	Map hashMap = new HashMap();
	Map tkMap = new HashMap();
	boolean isSubCancelled, isCancelled, isEnd;
// @AGQ050906
	int [] tksIds = tkMgr.findId(pstuser, "ProjectID='"+projIdS+"'");
	for (int i=0; i<tksIds.length; i++) {
		tks = String.valueOf(tksIds[i]);
		tkMap.put(tks, tks);
	}

	objArr = phMgr.getPhases(pstuser, projIdS);

	for (int i=0; i<maxPhases; i++)
	{
		aObj = null;
		isEnd = true;		// continuous phases to determine last phase
		isCancelled = false;
		phName = phStatus = phPlanExp = phExpire = phStart = phDone
					= phExt = oldSt = phTID = "";
		s = (request.getParameter("Phase"+i));
		ds = request.getParameter("Deadline"+i);
		tks = request.getParameter("PhaseTask"+i);
		subDelete = request.getParameter("Delete"+i);
		phDone = request.getParameter("PhComplete"+i);
		phStatus = request.getParameter("Status"+i);
		phColor = request.getParameter("Color"+i);
		phColor = trimOrNull(phColor);
		tks = trimOrNull(tks);
		if (ds!=null) ds = ds.trim();
// @AGQ051606
		if (s!=null) s = s.replaceAll("\\\\", "").trim();
		phName = s; // name used for cancelled
		if (subDelete != null && subDelete.equalsIgnoreCase("true")) {
			deletePhase = objArr[i];
		}

// @AGQ071906A
		if (ds != null && ds.length() == 0) // Blank Due Date -> " "
			ds = " ";

		if (tks!=null)
		{
			// @110705ECC Use task link
			isEnd = false;
			if (s != null) phName = s;
			phTID = tks;
// @AGQ050906
			if (hashMap.containsKey(phTID)) {
				response.sendRedirect("../out.jsp?msg=Cannot contain duplicate TASK ID: '"+phTID+"' for Phase " + (i+1) + ": '" + phName + "'.");
				return;
			}
			else if (!tkMap.containsKey(phTID)) {
				response.sendRedirect("../out.jsp?msg=The TASK ID: '"+phTID+"' for Phase " + (i+1) + ": '" + phName + "' must belong to this Project.");
				return;
			}
			hashMap.put(phTID, phTID);
		}
		// Check to see if there is a name and expire date
		else if (s!=null && s.length()>0 && ds!=null && ds.length()>0)
		{
			isEnd = false;
			phName = s;			// phase name
			phExpire = ds;		// phase deadline
// @AGQ050306
			try {
				dt = phase.parseStringToDate(phExpire, format);
			} catch (ParseException e) {
				response.sendRedirect("../out.jsp?msg=You cannot set the DUE Date for Phase " + (i+1) + ": '" + phName + "' to: '" + phExpire + "'.");
				return;
			}
			phExpire = phase.parseDateToString(dt, format);		// ensure correct date format
			try {
				dt = phase.parseStringToDate(phDone, format);
			} catch (ParseException e) {
				response.sendRedirect("../out.jsp?msg=You cannot set the ACTUAL COMPLETION Date for Phase " + (i+1) + ": '" + phName + "' to: '" + phDone + "'.");
				return;
			}
			phDone = phase.parseDateToString(dt, format);
			phStart  = request.getParameter("PhStart"+i).trim();
			if (phStart.length() > 0)
			{
// @AGQ050406
				if (phStart.equalsIgnoreCase("TBD")) {
						phStart = "";
				}
				else {
					try {
						dt = df.parse(phStart);
						Util.validCalanderDate(phStart, dt);
						phStart = df.format(dt);	// ensure correct date format
					} catch (ParseException e) {
						response.sendRedirect("../out.jsp?msg=You cannot set the START Date for Phase " + (i+1) + ": '" + phName + "' to: '" + phStart + "'.");
						return;
					}
				}
			}
		}
// @AGQ051606
		if (phStatus != null && phStatus.equals(project.PH_CANCEL)) {
			isEnd = false;
			isCancelled = true;
		}

		if (isEnd)
		{
			if (i <objArr.length) {
				ph = (phase) objArr[i];
// @AGQ051106
				phMgr.removePhase(pstuser, String.valueOf(ph.getObjectId()));
			}
			break;
		}

		// use existing phase
		if (i < objArr.length) {
			ph = (phase)objArr[i];
// @AGQ051706A
			// try to get previous dates since the fields are disabled
			if (isCancelled) {
				aObj = ph;
				obj = ph.getAttribute(phase.TASKID)[0];
				if (obj != null) {
					try
					{
						aObj = (task)tkMgr.get(pstuser, obj.toString());
					}
					catch (PmpException e) {e.printStackTrace(); aObj = ph;}
				}
				obj = aObj.getAttribute(phase.EXPIREDATE)[0];
				phExpire = phase.parseDateToString((Date)obj, format);
				obj = aObj.getAttribute(phase.STARTDATE)[0];
				phStart = phase.parseDateToString((Date)obj, format);
				obj = aObj.getAttribute(phase.PLANEXPIREDATE)[0];
				phPlanExp = phase.parseDateToString((Date)obj, format);
			}
		}
		// new phases
		else {
			ph = (phase)phMgr.create(pstuser);
			ph.setAttribute(phase.PROJECTID, projIdS);
			ph.setAttribute(phase.PHASENUMBER, Integer.valueOf(i+1));
			ph.setAttribute(phase.CREATEDDATE, now);
// @AGQ051706
			if (isCancelled) // in case use creates a new but cancelled phase
				phExpire = "TBD";
		}

		// compare and set project dates
		if (i < objArr.length && !isCancelled)
		{
			aObj = ph;
			if (tks==null) // no task ID
			{
// @AGQ050506
				// check if previously linked
				obj = ph.getAttribute(phase.TASKID)[0];
				if (obj != null) {
					try
					{
						aObj = (task)tkMgr.get(pstuser, obj.toString());
					}
					catch (PmpException e) {e.printStackTrace(); aObj = ph;}
				}

				obj = aObj.getAttribute(phase.STATUS)[0];
				oldSt = (obj != null)?obj.toString():"";

				// compare to determine setting StartDate or CompleteDate
				if (oldSt.equals(project.PH_NEW) && !phStatus.equals(project.PH_NEW))
					phStart = todayS;	// set StartDate
				if (!oldSt.equals(project.PH_COMPLETE) && phStatus.equals(project.PH_COMPLETE) && phDone.length() == 0)
					phDone = todayS;	// set CompleteDate
// @AGQ050506
//				if (phStart.length()==0) {
//					obj = aObj.getAttribute(phase.STARTDATE)[0];
//					phStart = (obj != null)?df.format((Date)obj):"";
//				}
// @AGQ051606
				// Set Status to Complete when a phDone is filled
				if (!phStatus.equals(project.PH_COMPLETE) && !oldSt.equals(project.PH_COMPLETE) && phDone.length() > 0)
					phStatus = project.PH_COMPLETE;
				// Remove Complete Date when changed from Complete -> Started
				if (oldSt.equals(project.PH_COMPLETE) && !phStatus.equals(project.PH_COMPLETE))
					phDone = "";
// @AGQ050306	// User removed complete date
				if (phStatus.equals(project.PH_COMPLETE) && phDone.length()==0) {
					obj = aObj.getAttribute(phase.COMPLETEDATE)[0];
					phDone = (obj != null)?phase.parseDateToString((Date)obj, format):todayS;
				}
			}

			// copy old phase values
// @AGQ050306
			obj = aObj.getAttribute(phase.PLANEXPIREDATE)[0];
			phPlanExp = (obj!=null)?phase.parseDateToString((Date)obj, format):"";
		}

		// set implicit phase status
		if (tks == null && !isCancelled)
		{
			try {
				dt = phase.parseStringToDate(phExpire, format);
			} catch (ParseException e) {
				response.sendRedirect("../out.jsp?msg=You cannot set the DUE Date for Phase " + (i+1) + ": '" + phName + "' to: '" + phExpire + "'.");
				return;
			}
			if (!(phStatus.equalsIgnoreCase(project.PH_COMPLETE) || phStatus.equalsIgnoreCase(project.PH_CANCEL))) {
				if (today.after(dt))
					phStatus = project.PH_LATE;
				else {
					if (phStatus.equalsIgnoreCase(project.PH_LATE))
						phStatus = project.PH_START;
				}
			}

//			if ( (phStatus.equals(project.PH_START) || phStatus.equals(project.PH_COMPLETE) || phStatus.equals(project.PH_LATE))
//					&& phStart.length()==0)
//				phStart = todayS;
		}

		if (phPlanExp.length()==0 && phExpire.length()>0)
			phPlanExp = phExpire;			// copy planExpire from Expire

		/////////////////////////////////////////////////////////////////
		////////////////
		// set SUB-PHASES
		int newSubPhaseParent = -1;
		s = request.getParameter("subPhaseParent");
		if (s!=null && s.length()>0)
			newSubPhaseParent = Integer.parseInt(s);

		subObjArr = phMgr.getSubPhases(pstuser, String.valueOf(ph.getObjectId()));
		int totalSubPhase = subObjArr.length;
// @AGQ050506 this way use can still save all existing subphases
		if (totalSubPhase > maxSubPhases) {
			maxSubPhases = totalSubPhase;
		}

		for (int j=0; j<maxSubPhases; j++)
		{
			// put every sub-phase info into the blog
			subAObj = null;
			oldDone = null;
			isSubCancelled = false;
			isEnd = true;
			subphName = subphStatus = subphPlanExp = subphExpire = subphStart = subphDone = oldSt = subphTID = "";
			s = request.getParameter("SubPhase"+i+"_"+j);
			ds = request.getParameter("SubDeadline"+i+"_"+j);
			tks = request.getParameter("SubPhaseTask" +i+"_"+j);
			subDelete = request.getParameter("SubDelete"+i+"_"+j);
			subphStatus = request.getParameter("SubStatus"+i+"_"+j);

			if (tks!=null) {tks = tks.trim(); if (tks.length()==0) tks = null;}
			if (ds!=null) ds = ds.trim();
// @AGQ051606
			if (s!=null) s = s.replaceAll("\\\\", "").trim();
			subphName = s; // name used for cancelled
// @AGQ071906A
			if (ds != null && ds.length() == 0) // all empty Due Date -> " "
				ds = " ";

			if (subDelete != null && subDelete.equalsIgnoreCase("true")) {
				deletePhase = subObjArr[j];
			}

			if (tks!=null) // no task id
			{
				// @110705ECC Use task link
				isEnd = false;
				if (s != null) subphName = s;
				subphTID = tks;
// @AGQ050906
				if (hashMap.containsKey(subphTID)) {
					response.sendRedirect("../out.jsp?msg=Cannot contain duplicate TASK ID: '"+subphTID+"' for Milestone " + (i+1) + "." + (j+1) + ": '" + subphName + "'.");
					return;
				}
				else if (!tkMap.containsKey(subphTID)) {
					response.sendRedirect("../out.jsp?msg=The TASK ID: '"+subphTID+"' for Milestone " + (i+1) + "." + (j+1) + ": '" + subphName + "' must belong to this Project.");
					return;
				}
				hashMap.put(subphTID, subphTID);
			}
			else if (s!=null && ds!=null) // check for name and expire date
			{
				if (s.length()>0 && ds.length()>0)
				{
					isEnd = false;
					subphName = s;			// phase name
					subphExpire = ds;		// phase deadline
// @AGQ050306
					try {
					dt = phase.parseStringToDate(subphExpire, format);
					} catch (ParseException e) {
						response.sendRedirect("../out.jsp?msg=You cannot set the DUE Date for Milestone " + (i+1) + "." + (j+1) + ": '" + subphName + "' to: '" + subphExpire + "'.");
						return;
					}
					subphExpire = phase.parseDateToString(dt, format); 		// ensure correct date format
					//subphStatus = request.getParameter("SubStatus"+i+"_"+j);
					subphStart  = "";//request.getParameter("SubPhStart"+i+"_"+j).trim();
					if (subphStart.length() > 0)
					{	try {
							dt = df.parse(subphStart);
							Util.validCalanderDate(subphStart, dt);
							subphStart = df.format(dt);	// ensure correct date format
						} catch (ParseException e) {
							response.sendRedirect("../out.jsp?msg=You cannot set the START Date for Milestone " + (i+1) + "." + (j+1) + ": '" + subphName + "' to: '" + subphStart + "'.");
							return;
						}
					}
				}
			}

			if (subphStatus != null && subphStatus.equals(project.PH_CANCEL)) {
				isEnd = false;
				isSubCancelled = true;
			}

			if (isEnd) {
				break;
			}

			// use existing subphase
			if (j < totalSubPhase) {
				subPh = (phase)subObjArr[j];
// @AGQ051706A
				// try to get previous dates since the fields were disabled
				if (isSubCancelled) {
					subAObj = subPh;
					obj = subPh.getAttribute(phase.TASKID)[0];
					if (obj != null) {
						try
						{
							subAObj = (task)tkMgr.get(pstuser, obj.toString());
						}
						catch (PmpException e) {e.printStackTrace(); subAObj = subPh;}
					}
					obj = subAObj.getAttribute(phase.EXPIREDATE)[0];
					subphExpire = phase.parseDateToString((Date)obj, format);
					obj = subAObj.getAttribute(phase.PLANEXPIREDATE)[0];
					subphPlanExp = phase.parseDateToString((Date)obj, format);
				}

			}
			// create new subphase
			else {
				subPh = (phase)phMgr.create(pstuser);
				subPh.setAttribute(phase.PARENTID, String.valueOf(ph.getObjectId()));
				subPh.setAttribute(phase.PHASENUMBER, Integer.valueOf(j+1));
				subPh.setAttribute(phase.CREATEDDATE, now);
// @AGQ051706
				if (isSubCancelled) // in case a use creates a new cancelled subphase
					subphExpire = "TBD";
			}

			if (tks == null && !isSubCancelled) // no task id
			{
				subAObj = subPh;
				if (j<totalSubPhase) // using existing subphase
				{
					obj = subPh.getAttribute(phase.TASKID)[0];
					if (obj != null) {
						try
						{
							subAObj = (task)tkMgr.get(pstuser, obj.toString());
						}
						catch (PmpException e) {e.printStackTrace(); subAObj = subPh;}
					}

					obj = subAObj.getAttribute(phase.COMPLETEDATE)[0];
					oldDone = (obj != null)?(Date)obj:null;

					obj = subAObj.getAttribute(phase.STATUS)[0];
					oldSt = (obj != null)?obj.toString():"";

					if (oldSt.equals(project.PH_NEW) && !subphStatus.equals(project.PH_NEW))
						subphStart = todayS;	// set StartDate
					if (!oldSt.equals(project.PH_COMPLETE) && subphStatus.equals(project.PH_COMPLETE)) {
						if (oldDone == null || (oldDone != null && phase.isSpecialDate(oldDone)))
							subphDone = todayS;	// set CompleteDate
						else
							subphDone = phase.parseDateToString(oldDone, format);
					}

					if (subphStart.length()==0) {
						obj = subAObj.getAttribute(phase.STARTDATE)[0];
						subphStart = (obj != null)? df.format((Date)obj):"";
					}
// @AGQ050306
					if (subphStatus.equals(project.PH_COMPLETE) && subphDone.length()==0) {
						subphDone = (oldDone != null)?phase.parseDateToString(oldDone, format):"";
					}

					// copy old phase values
					obj = subAObj.getAttribute(phase.PLANEXPIREDATE)[0];
					subphPlanExp = (obj != null)?phase.parseDateToString((Date)obj, format):"";
				}
				else // checking status
				{
					if (subphStatus.equals(project.PH_COMPLETE))
						subphDone = todayS;
				}

				// set implicit sub-phase status
// @AGQ050306
// @AGQ050806
				try {
				dt = phase.parseStringToDate(subphExpire, format);
				} catch (ParseException e) {
					response.sendRedirect("../out.jsp?msg=You cannot set the DUE Date for Milestone " + (i+1) + "." + (j+1) + ": '" + subphName + "' to: '" + subphExpire + "'.");
					return;
				}
// @AGQ051906
				// Corrects the status when a complete date is filled but status is not correct.
				if (oldDone != null &&
						(!oldSt.equals(phase.PH_COMPLETE) && !oldSt.equals(phase.PH_CANCEL)) &&
						oldSt.equals(subphStatus)) {
					subphDone = phase.parseDateToString(oldDone, format);
					if (!phase.isSpecialDate(oldDone))
						subphStatus = phase.PH_COMPLETE;
				}

				// Check to see if status should be late or start depending on exp date and previous status
				if (!(subphStatus.equalsIgnoreCase(project.PH_COMPLETE) || subphStatus.equalsIgnoreCase(project.PH_CANCEL))) {
					if (today.after(dt))
						subphStatus = project.PH_LATE;
					else {
						if (subphStatus.equalsIgnoreCase(project.PH_LATE))
							subphStatus = project.PH_START;
					}
				}

				if ( (subphStatus.equals(project.PH_START) || subphStatus.equals(project.PH_COMPLETE) || subphStatus.equals(project.PH_LATE))
						&& subphStart.length()==0)
					subphStart = todayS;
				if (subphPlanExp.length()==0 && subphExpire.length()>0)
					subphPlanExp = subphExpire;			// copy planExpire from Expire
			}

			// contruct the sub-phase records
			subPh.setAttribute(phase.NAME, subphName);

			if (subphStart != null && subphStart.length() > 0)
				subPh.setAttribute(phase.STARTDATE, df.parse(subphStart));
			else
				subPh.setAttribute(phase.STARTDATE, null);
// @AGQ050306
			subPh.setAttribute(phase.PLANEXPIREDATE, phase.parseStringToDate(subphPlanExp, format));
			try {
			subPh.setAttribute(phase.EXPIREDATE, phase.parseStringToDate(subphExpire, format));
			} catch (ParseException e) {
				response.sendRedirect("../out.jsp?msg=You cannot set the DUE Date for Milestone " + (i+1) + "." + (j+1) + ": '" + subphName + "' to: '" + subphExpire + "'.");
				return;
			}
			subPh.setAttribute(phase.COMPLETEDATE, phase.parseStringToDate(subphDone, format));

			if (subphTID != null && subphTID.length() > 0)
				subPh.setAttribute(phase.TASKID, subphTID);
			else
				subPh.setAttribute(phase.TASKID, null);
			subPh.setAttribute(phase.STATUS, subphStatus);
			subPh.setAttribute(phase.LASTUPDATEDDATE, now);

			phMgr.commit(subPh);
		}		// end if there is a sub-phase

		// END set sub-phases
		////////////////
		/////////////////////////////////////////////////////////////////

		// check to see if I am adding new sub-phase to this phase
		// save this phase to the project attribute

		ph.setAttribute(phase.NAME, phName);
// @AGQ051606
		if (phStart != null && phStart.length() > 0)
			ph.setAttribute(phase.STARTDATE, df.parse(phStart));
		else
			ph.setAttribute(phase.STARTDATE, null);
// @AGQ050306
		ph.setAttribute(phase.PLANEXPIREDATE, phase.parseStringToDate(phPlanExp, format));
		ph.setAttribute(phase.COMPLETEDATE, phase.parseStringToDate(phDone, format));
		ph.setAttribute(phase.COLOR, phColor);

		try {
			ph.setAttribute(phase.EXPIREDATE, phase.parseStringToDate(phExpire, format));
		} catch (ParseException e) {
			response.sendRedirect("../out.jsp?msg=You cannot set the DUE Date for Phase " + (i+1) + ": '" + phName + "' to: '" + phExpire + "'.");
			return;
		}
		if (phTID != null && phTID.length() > 0)
			ph.setAttribute(phase.TASKID, phTID);
		else
			ph.setAttribute(phase.TASKID, null);
		ph.setAttribute(phase.STATUS, phStatus);
		ph.setAttribute(phase.LASTUPDATEDDATE, now);

		phMgr.commit(ph);
	}	// end for loop for each phase

	// delete subphase
	if (deletePhase != null) {
		subPh = (phase) deletePhase;
//@AGQ051106
		phMgr.removePhase(pstuser, String.valueOf(subPh.getObjectId()));
	}

	// commit the project object
	p.setAttribute("LastUpdatedDate", now);
	pMgr.commit(p);

	response.sendRedirect("phase_update.jsp?projId="+projIdS);	// default
%>
