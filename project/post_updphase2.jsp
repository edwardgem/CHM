<%
//
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_updphase2.java
//	Author: ECC
//	Date:		04/12/2006
//	Description:	Update sub-phase schedule.
//	Modification:
//	
//		@AGQ050306	Support TBD and N/A
//		@AGQ050806	Fixed bug; return out.jsp message when there is a date parse error
//		@AGQ051006	Only support saving the PlanExpireDate w/ Task ID
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


<%
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
	taskManager tkMgr = taskManager.getInstance();
	project p = (project)pMgr.get(pstuser, Integer.parseInt(projIdS));
	task tk = null;

	String format = "MM/dd/yy";
	java.text.SimpleDateFormat df = new java.text.SimpleDateFormat(format);
	Date now = new Date();
	Date today = df.parse(df.format(now));
	Date dt;
	
	// project phases (name::StartDate::ExpireDate::CompleteDate::Status)
	int maxPhases = 7;	// default to 7
	String s = Util.getPropKey("bringup", "PHS.TOTAL");
	if (s != null) maxPhases = Integer.parseInt(s);

	// retreive the list of phases to save
	ArrayList arr = new ArrayList();
	for (int i=0; i<maxPhases; i++) {
		s = request.getParameter("savePhase"+i);
		if ((Boolean.valueOf(s)).booleanValue()) {
			arr.add(String.valueOf(i));
		}
	}

	String ds, tks, mainPhaseAttrName, phString, subphString, oldPh, oldSt, phTID;
	String phName, phExpire, phStatus, phStart, phDone, phExt;
	String subphName, subphPlanExp, subphExpire, subphStatus, subphStart, subphDone, subphTID;
	String todayS = df.format(today);
	int i;
	int totalSubPhase;

	phaseManager phMgr = phaseManager.getInstance();
	PstAbstractObject [] objArr = null;
	phase ph = null;
	
	for (int idx=0; idx<arr.size(); idx++)
	{		
		try { i = Integer.parseInt(arr.get(idx).toString()); } catch (NumberFormatException e) {e.printStackTrace(); continue;}
		phExt = request.getParameter("phaseExt"+i); // this is actually phase id
		
		ph = (phase)phMgr.get(pstuser, phExt);
		phName = ph.getAttribute(phase.NAME)[0].toString();

		// get the subPhase
		totalSubPhase = 0;
		if (phExt.length() > 0)
		{
			objArr = phMgr.getSubPhases(pstuser, phExt);
			totalSubPhase = objArr.length;
		}

		// get the task id
		for (int j=0; j<totalSubPhase; j++)
		{
			ph = (phase)objArr[j];
			subphName = subphStatus = subphPlanExp = subphExpire = subphStart = subphDone = oldSt = subphTID = "";
			subphName = ph.getAttribute(phase.NAME)[0].toString();
			String taskIdS = request.getParameter("subPhaseTID"+i+"_"+j);
			if (taskIdS == null) break;
	
			// This is linked to a task id
			//if (taskIdS.length() > 0)
			//	continue;

			String initDateS = request.getParameter("SubInitDl"+i+"_"+j);
			String deadlDateS = request.getParameter("SubDeadline"+i+"_"+j);
			String complDateS = request.getParameter("SubComplete"+i+"_"+j);
			
			if (taskIdS.length() > 0)
			{
				try
				{
					tk = (task)tkMgr.get(pstuser, taskIdS);
// @AGQ050306		
// @AGQ050806
					try {
						tk.setAttribute("PlanExpireDate", phase.parseStringToDate(initDateS, format));
					} catch (ParseException e) {
						response.sendRedirect("../out.jsp?msg=You cannot set the Planned Due Date for Phase " + (i+1) + ": '" + phName + "' with Milestone " + (j+1) + ": '" + subphName + "' to: '" + initDateS + "'.");
						return;
					}
// @AGQ050406
// @AGQ051006
/* 
					try {
						dt = phase.parseStringToDate(deadlDateS, format);
					} catch (ParseException e) {
						response.sendRedirect("../out.jsp?msg=You cannot set the Estimated Due Date for Phase " + (i+1) + ": '" + phName + "' with Milestone " + (j+1) + ": '" + subphName + "' to: '" + deadlDateS + "'.");
						return;
					}
					tk.setAttribute("ExpireDate", dt);
					// Check status
					String status = (String)tk.getAttribute("Status")[0];
					if (dt != null && !phase.isSpecialDate(dt) && today.after(dt) &&
							!(status.equalsIgnoreCase(project.PH_COMPLETE) || status.equalsIgnoreCase(project.PH_CANCEL))) {
						status = project.PH_LATE;
					}
					else if (dt != null && !phase.isSpecialDate(dt) && today.before(dt) &&
							status.equalsIgnoreCase(project.PH_LATE)) {						
						status = project.PH_START;
					}
					
					try {
						dt = phase.parseStringToDate(complDateS, format);
					} catch (ParseException e) {
						response.sendRedirect("../out.jsp?msg=You cannot set the Actual Completion Date for Phase " + (i+1) + ": '" + phName + "' with Milestone " + (j+1) + ": '" + subphName + "' to: '" + complDateS + "'.");
						return;
					}
					tk.setAttribute("CompleteDate", dt);
					if (dt != null && !phase.isSpecialDate(dt)) 
						status = project.PH_COMPLETE;
					
					tk.setAttribute("Status", status);
					tk.setAttribute("LastUpdatedDate", now);
*/					
					tkMgr.commit(tk);
				}
				catch (PmpException e) {e.printStackTrace();}
			}
			else
			{
				// store into phase object
				try {
					ph.setAttribute(phase.PLANEXPIREDATE, phase.parseStringToDate(initDateS, format));
				} catch (ParseException e) {
					response.sendRedirect("../out.jsp?msg=You cannot set the Planned Due Date for Phase " + (i+1) + ": '" + phName + "' with Milestone " + (j+1) + ": '" + subphName + "' to: '" + initDateS + "'.");
					return;
				}
				
				// Check status 
				String status = (String)ph.getAttribute(phase.STATUS)[0];
				
				// Actual Completion
				try {
					dt = phase.parseStringToDate(complDateS, format);
				} catch (ParseException e) {
					response.sendRedirect("../out.jsp?msg=You cannot set the Actual Completion Date for Phase " + (i+1) + ": '" + phName + "' with Milestone " + (j+1) + ": '" + subphName + "' to: '" + complDateS + "'.");
					return;
				}
				ph.setAttribute(phase.COMPLETEDATE, dt);
				// Set from COMPLETED to STARTED when ACTUAL COMPLETION date is removed (see below to change to LATE)
				if ((dt == null || (dt != null && phase.isSpecialDate(dt))) && status.equals(phase.PH_COMPLETE))
					status = phase.PH_START;
				// Set to COMPLETED when ACTUAL COMPLETION date is filled (interface blocks Cancelled)
				else if (dt != null && !phase.isSpecialDate(dt)) 
					status = project.PH_COMPLETE;
				
				// Due Date
				try {
					dt = phase.parseStringToDate(deadlDateS, format);
				} catch (ParseException e) {
					response.sendRedirect("../out.jsp?msg=You cannot set the Estimated Due Date for Phase " + (i+1) + ": '" + phName + "' with Milestone " + (j+1) + ": '" + subphName + "' to: '" + deadlDateS + "'.");
					return;
				}			
				ph.setAttribute(phase.EXPIREDATE, dt);
				
				if (dt != null && !phase.isSpecialDate(dt) && today.after(dt) &&
						!(status.equalsIgnoreCase(project.PH_COMPLETE) || status.equalsIgnoreCase(project.PH_CANCEL))) {
					status = project.PH_LATE;
				}
				else if (dt != null && !phase.isSpecialDate(dt) && today.before(dt) &&
						status.equalsIgnoreCase(project.PH_LATE)) {
					status = project.PH_START;
				}

				ph.setAttribute(phase.STATUS, status);
				ph.setAttribute(phase.LASTUPDATEDDATE, now);
				phMgr.commit(ph);
			}
		}	// end for each subphase
	}	// end for each Phase block


	response.sendRedirect("phase_update2.jsp?projId="+projIdS);	// default
%>
