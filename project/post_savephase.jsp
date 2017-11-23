<%
//
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_savephase.jsp
//	Author: ECC
//	Date:		09/15/2005
//	Description:	Save the phase expiration date from the summary page.
//	Modification:
//		@AGQ032306
//			Previous s becomes null. Added a null detection.
//		@AGQ042506a
//			Fixed error when date (04/25/05) is parsed into a MM/dd/yyyy format (becomes 04/25/0005)
//		@AGQ042506
//			Changed usage of phase to phase object
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "oct.util.file.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
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
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}

	projectManager pjMgr = projectManager.getInstance();
	project projObj = (project)pjMgr.get(pstuser, Integer.parseInt(projIdS));
	
	int maxPhases = 7;	// default to 7
	String s = Util.getPropKey("bringup", "PHS.TOTAL");
	if (s != null) maxPhases = Integer.parseInt(s);

	// save phase
	String phS, oldPhS, status, phExt;
	String [] sa;
	boolean bNeedSave = false;
// @AGQ042506a
	SimpleDateFormat df = new SimpleDateFormat ("MM/dd/yy");
	Date dt;
	Date today = df.parse(df.format(new Date()));
	phaseManager phMgr = phaseManager.getInstance();
	PstAbstractObject [] objArr = phMgr.getPhases(pstuser, String.valueOf(projObj.getObjectId()));
	phase ph = null;
	Object obj = null;
	
	for (int i=0; i<maxPhases; i++)
	{	
// @AGQ032306
		s = request.getParameter("dt" + i);
		if (s != null && s.length() > 0 && !s.equals("undefined"))
		{
// @AGQ042506
			if (i < objArr.length)
				ph = (phase) objArr[i];
			else
				break;
			
			obj = ph.getAttribute(phase.TASKID)[0];
			if (obj != null)
				continue;

			// update status based on expire date
			status = ph.getAttribute(phase.STATUS)[0].toString();
			dt = df.parse(s);
			if (!dt.before(today))
			{
				if (status.equals(project.PH_LATE))
					status = project.PH_START;
			}
			else
			{
				if (status.equals(project.PH_START))
					status = project.PH_LATE;
			}
			if (s != null && s.length() > 0)
				ph.setAttribute(phase.EXPIREDATE, df.parse(s));
			else
				ph.setAttribute(phase.EXPIREDATE, null);
			ph.setAttribute(phase.STATUS, status);
			ph.setAttribute(phase.LASTUPDATEDDATE, today);
			
			phMgr.commit(ph);
		}
	}
	

	response.sendRedirect("proj_summary.jsp?projId=" + projIdS);	// default
%>
