<%
//
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_rating.jsp
//	Author: ECC
//	Date:		11/03/2006
//	Description:	Handle rating.
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>

<%
	// update rating
	String s;
	if (session == null) session = request.getSession(true);
	PstUserAbstractObject pstuser = (PstUserAbstractObject)session.getAttribute("pstuser");
	if (pstuser == null || pstuser instanceof PstGuest)
	{
		pstuser = PstGuest.getInstance();
		session.setAttribute("pstuser", pstuser);
	}

	String app = request.getParameter("app");
	if (app == null) app = "OMF";
	String idS = request.getParameter("id");
	String uidS = request.getParameter("uid");
	int myRating = Integer.parseInt(request.getParameter("rating"));
	s = request.getParameter("old");
	int oldRating = (s==null)?0:Integer.parseInt(s);

	String backPage = request.getParameter("backPage");
	if (backPage != null)
		backPage = backPage.replaceAll(":", "&");

	PstManager mgr;
	if (app.contains("CR") && backPage!=null && backPage.contains("ep_"))
	{
		// rating attachment
		mgr = attachmentManager.getInstance();
		backPage += "#" + idS;					// jump to the share file on return
	}
	else
	{
		// rating meeting
		mgr = meetingManager.getInstance();
	}
	PstAbstractObject o = mgr.get(pstuser, idS);

	int votes = ((Integer)o.getAttribute("VoteNum")[0]).intValue();
	if (oldRating <= 0)
		o.setAttribute("VoteNum", new Integer(votes+1));		// one more voter
	int rating = ((Integer)o.getAttribute("Rating")[0]).intValue() + myRating - oldRating;
	o.setAttribute("Rating", new Integer(rating));
	mgr.commit(o);
%>

<script language="JavaScript" src="../login_cookie.js"></script>
<script language="JavaScript">
<!--
var now = new Date();
fixDate(now);
now.setTime(now.getTime() + 7776000000); // 90 * 24 * 60 * 60 * 1000
var cookieName = "<%=app%><%=idS%>-<%=uidS%>";
deleteCookie(cookieName);
setCookie(cookieName, "<%=myRating%>", now, "/");

location = "<%=backPage%>";
//	-->
</script>
