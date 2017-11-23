<%
//
//	Copyright (c) 2009, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_day.jsp
//	Author: ECC
//	Date:		11/22/2009
//	Description:	Create and update of a day object.
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
%>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>
<%@ page import = "org.apache.log4j.Logger" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />


<%
	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	Logger l = PrmLog.getLog();
	SimpleDateFormat df3 = new SimpleDateFormat ("yyyy/MM/dd");
	
	String myUidS = String.valueOf(pstuser.getObjectId());
	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if (iRole > 0)
	{
		if ((iRole & user.iROLE_ADMIN) > 0)
			isAdmin = true;
	}

	String s;
	String type = request.getParameter("dayType");
	String title = request.getParameter("dayTitle");
	String desc = request.getParameter("dayDesc").trim();
	String scope = request.getParameter("scope");
	String notify = request.getParameter("notify");
	String recur;
	
	boolean bUpdate = false;
	String dayIdS = request.getParameter("dayID");
	if (dayIdS!=null && dayIdS.length()>0)
		bUpdate = true;

	dayManager dMgr = dayManager.getInstance();
	day dObj = null;

	// try to get the day object
	if (bUpdate)
	{
		dObj = (day)dMgr.get(pstuser, dayIdS);
		
		// safety check: update allow only if isAdmin or Owner
		if (!isAdmin && !myUidS.equals(dObj.getAttribute("Owner")[0]))
		{
			response.sendRedirect("cal.jsp");
			return;
		}
		
		// delete
		s = request.getParameter("delDay");
		if (s!=null && s.equals("true"))
		{
			dMgr.delete(dObj);
			l.info("Deleted day object [" + dayIdS + "]");
			response.sendRedirect("cal.jsp");
			return;
		}
	}
	else
	{
		dObj = (day)dMgr.create(pstuser);
		dObj.setAttribute("Owner", myUidS);
		dObj.setAttribute("CreatedDate", new Date());
		s = request.getParameter("date");
		Date dt = df3.parse(s);
		dt = new Date(dt.getTime() + 28800000);		// add 8 hr. to set it to 8AM
		dObj.setAttribute("StartDate", dt);
	}
	
	// set attributes
	dObj.setAttribute("Type", type);
	dObj.setAttribute("Title", title);
	dObj.setAttribute("TownID", scope);
	dObj.setAttribute("Notification", notify);
	if (desc.length() > 0)
		dObj.setAttribute("Description", desc.getBytes());
	else
		dObj.setAttribute("Description", null);
	
	dMgr.commit(dObj);
	l.info("Created/updated day object [" + dObj.getObjectId() + "]");
	
	// Google calendar
	// TODO: in the future we should support update/delete Google calendar meeting
	if (pstuser.getStringAttribute("GoogleID")!=null) {
		try {
			PrmGoogle googleHandler = new PrmGoogle(pstuser, true);		// handle for Google calendar
			googleHandler.addEvent(dObj, (TimeZone)session.getAttribute("javaTimeZone"));
		}
		catch (Exception e) {
			response.sendRedirect("../out.jsp?go=meeting/cal.jsp&msg=Failed to add Google Calendar event: " + e.getMessage());
			e.printStackTrace();
			return;
		}
	}
	
	// ready to jump to the right yr/mo on cal.jsp
	String yr=null, mo=null;
	Date dt = (Date)dObj.getAttribute("StartDate")[0];
	s = df3.format(dt);
	yr = s.substring(0,4);
	mo = s.substring(5,7);
	
	// create and sets the day object)
	response.sendRedirect("cal.jsp?year=" + yr + "&month=" + (Integer.parseInt(mo)-1));

%>
