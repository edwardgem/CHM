<%
//
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_updADI.jsp
//	Author: ECC
//	Date:		09/9/2005
//	Description:	Update a number of actions, decisions and issues
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
%>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />


<%

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}

	// back to page
	String projIdS = request.getParameter("projId");

	actionManager aMgr = actionManager.getInstance();
	bugManager bMgr = bugManager.getInstance();

	java.text.SimpleDateFormat df = new java.text.SimpleDateFormat("MM/dd/yy");
	Date now = new Date();
	Date today = new Date(df.format(now));

	// get the list of ADI that are updated
	PstAbstractObject obj = null;
	PstManager mgr;
	String s, st;
	Date expireD;
	boolean isBug;
	boolean isAction;

	for (Enumeration e = request.getParameterNames() ; e.hasMoreElements() ;)
	{
		// updateA_12345, updateD_12345 or updateI_12345
		String temp = (String)e.nextElement();
		if (temp.startsWith("update"))
		{
			// only those that are checked would be included
			isAction = false;
			String aId = temp.substring(8);			// skip updateX_
			if (temp.charAt(6) == 'I')
			{
				isBug = true;
				mgr = bMgr;
			}
			else
			{
				isBug = false;
				mgr = aMgr;
				if (temp.charAt(6) == 'A') isAction = true;
			}
			obj = mgr.get(pstuser, aId);

			// expire date (deadline)
			s = request.getParameter("Expire_"+aId);
			if (s!=null && s.length()>0)
			{
				expireD = new Date(s);
				obj.setAttribute("ExpireDate", expireD);
			}
			else
				expireD = null;

			//status
			s = request.getParameter("Status_"+aId);
			if (s!=null)
			{
				// action or issue
				if (isBug)
					obj.setAttribute("State", s);
				else
				{
					// set action status by referencing the expiration date
					if (expireD == null)
						expireD = (Date)obj.getAttribute("ExpireDate")[0];
					if (s.equals(action.OPEN) && expireD.before(today))
						obj.setAttribute("Status", action.LATE);
					else if (s.equals(action.LATE) && !expireD.before(today))
						obj.setAttribute("Status", action.OPEN);
					else
						obj.setAttribute("Status", s);
				}
			}

			// priority
			s = request.getParameter("Priority_"+aId);
			obj.setAttribute("Priority", s);

			mgr.commit(obj);
		}
	}

	response.sendRedirect("proj_action.jsp?projId="+projIdS);

%>
