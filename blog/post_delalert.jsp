<%
//
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_delalert.jsp
//	Author: ECC
//	Date:		03/31/2004
//	Description:	Delete the user from the checked alert
//	Modification:
//		@040405ECC	Alert becomes part of memoObj.  memoObj cannot be deleted
//					from the system.  It only get moved from the Home page.
//					Also we will keep track of who has read the memoObj.
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
	String memoIdS = request.getParameter("memoId");
	memoManager mMgr = memoManager.getInstance();

	if (memoIdS != null)
	{
		// ADMIN action: removing completely this memo and its comments
		int [] ids = mMgr.findId(pstuser, "ParentID='" + memoIdS + "'");
		for (int i=0; i<ids.length; i++)
			mMgr.delete(mMgr.get(pstuser, ids[i]));
		mMgr.delete(mMgr.get(pstuser, memoIdS));

		response.sendRedirect("../ep/ep_home.jsp");
		return;
	}

	// back to page
	String back = request.getParameter("back");

	// the notified user
	String uidS = request.getParameter("uid");

	// get the list of alert ids
	for (Enumeration e = request.getParameterNames() ; e.hasMoreElements() ;)
	{
		String temp = (String)e.nextElement();
		if (temp.startsWith("delete_"))
		{
			String memoId = temp.substring(7);
			memo memoObj = (memo)mMgr.get(pstuser, memoId);

			// if the alert list is empty, ready to actually remove the alert object
			// @040405ECC: changed to memoObj and permanently retain the alert object
			Object [] arr = memoObj.getAttribute("Alert");
			memoObj.appendAttribute("Attendee", uidS);		// consider acknowledged
			memoObj.removeAttribute("Alert", uidS);		// removed from the "sent" list
			mMgr.commit(memoObj);

/*
			if ((al.length == 1) && (al[0].equals(uidS)))
			{
				// delete the alert object altogether
				rMgr.delete(alert);
			}
			else
			{
				// there are other alert personnel,
				// only remove this person from the list
				alert.removeAttribute("Alert", uidS);
				rMgr.commit(alert);
			}
*/
		}
	}

	response.sendRedirect(back);

%>
