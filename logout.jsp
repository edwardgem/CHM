<%

//
//  Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//	Licensee of FastPath (tm) is authorized to change, distribute
//	and resell this source file and the compliled object file,
//	provided the copyright statement and this statement is included
//	as header.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   logout.jsp
//  Author: FastPath CodeGen Engine
//  Date:   03.18.2003
//  Description:
//  Modification:
//		@03.18.2003aFCE File created by FastPath
//
/////////////////////////////////////////////////////////////////////
//
//
/**
* $Log$
* Revision 1.6  2007/12/30 04:16:05  edwardc
* Allow accumulation on search result and send hello and post message to the result.
*
* Revision 1.5  2007/12/07 00:40:05  edwardc
* Implemented My Page and Circle Page.
*
* Revision 1.4  2007/11/02 22:17:06  edwardc
* Implemented Events for OMF.
*
* Revision 1.3  2007/06/04 22:08:22  edwardc
* Remove cookie when logout.
*
* Revision 1.2  2005/11/07 07:03:29  edwardc
* Synchronize prayer (laptop) to merciful CVS
*
* Revision 1.1  2003/06/16 18:39:47  eddiel
* initial release
*
* Revision 1.2  2003/01/28 20:57:04  marcush
* added comments for generated files
*
*/

/**
* Class Description
* @author FastPath CodeGen Engine
* @version $Revision$
*/
%>
<%@ page import = "util.*" %>
<%@ page import = "mod.mfchat.OmfPresence" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "org.apache.log4j.Logger" %>


<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="index.jsp?"/>

<%
	boolean isCRAPP = util.Prm.isCR();
	boolean isMeetWE = util.Prm.isMeetWE();
	String cookiePrefix;
	if (isCRAPP) {
		cookiePrefix = "CR";
	}
	else if (isMeetWE) {
		cookiePrefix = "OMF";
	}
	else {
		cookiePrefix = "PRM";
	}
%>

<script language="JavaScript" src="login_cookie.js"></script>
<SCRIPT LANGUAGE="JavaScript">
<!--
	// ECC: deleteCookie must be done in index.jsp by redirect at the end
	//deleteCookie("<%=cookiePrefix%>username");
	//deleteCookie("<%=cookiePrefix%>password");
//-->
</script>


<%
	Logger l = PrmLog.getLog();

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("index.jsp");
		return;
	}

	try
	{
		if (pstuser instanceof user)
		{
			// update last login timestamp to now
			String myUidS = String.valueOf(pstuser.getObjectId());
			userinfoManager uiMgr = userinfoManager.getInstance();
			userinfo uif = (userinfo)uiMgr.get(pstuser, myUidS);
			uif.setAttribute("LastLogin", new Date());
			uiMgr.commit(uif);

			// trigger event
			//Thread th = PrmEvent.createTriggerEvent(pstuser, PrmEvent.EVT_USR_LOGOUT, null, null, null);
			//if (th != null) th.join();
			
			OmfPresence.setOffline(myUidS);
			
			// logout
			userManager.getInstance().logout(pstuser);
			l.info("User " + pstuser.getObjectName() + " logout");
		}
	}
	catch (PmpException e)
	{
		System.out.println("Error logging out user : " + e.toString());		
		//return;
	}

	pageContext.removeAttribute("pstuser");
	pageContext.removeAttribute("pstuser", PageContext.SESSION_SCOPE);

	session.removeAttribute("pstuser");
	session.removeAttribute("projId");
	session.removeAttribute("planStack");
	session.removeAttribute("taskNameMap");
	session.removeAttribute("role");
	session.removeAttribute("dType");
	session.removeAttribute("circle");
	session.removeAttribute("searchArr");	// ep_circles.jsp search result
	session.removeAttribute("comPicFile");
	session.removeAttribute("clipboard");
	session.removeAttribute("errorList");
	session.removeAttribute("expandTree");
	session.removeAttribute("showPjType");
	session.removeAttribute("app");
	session.removeAttribute("taskDirtyMap");
	session.removeAttribute("timeZone");
	session.removeAttribute("javaTimeZone");
	session.removeAttribute("locale");
	session.removeAttribute("cachePlanTime");
	session.removeAttribute("aiExpr");
	session.removeAttribute("bugList");

	response.sendRedirect("index.jsp?logout=true");
%>
