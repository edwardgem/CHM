<%
//
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_mtg_resp.java
//	Author: ECC
//	Date:		03/01/2005
//	Description:	Respond to a meeting invitation
//	Modification:
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
	// create meeting object

	String midS = request.getParameter("mid");
	if ((pstuser instanceof PstGuest) || (midS == null))
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}

	String respS = request.getParameter("Response");	// accept, decline, present

	meetingManager mMgr		= meetingManager.getInstance();
	int uid = pstuser.getObjectId();

	meeting mtgObj = (meeting)mMgr.get(pstuser, midS);
	Object [] attendeeA = mtgObj.getAttribute("Attendee");

	String s, attval = null;
	String [] sa;
	int aId;
	boolean bFound = false;
	for (int i=0; i<attendeeA.length; i++)
	{
		s = (String)attendeeA[i];
		sa = s.split(meeting.DELIMITER);
		aId = Integer.parseInt(sa[0]);

		if (aId == uid)
		{
			// found my id on the attendee list
			bFound = true;
			attval = sa[0] + meeting.DELIMITER;			// the uid
			if (sa[1].startsWith(meeting.ATT_MANDATORY)) {
				attval += meeting.ATT_MANDATORY + respS;	// e.g. 12345::MandatoryAccept
			}
			else {
				attval += meeting.ATT_OPTIONAL + respS;	// e.g. 12345::OptionalAccept
			}
			mtgObj.removeAttribute("Attendee", s);
			mtgObj.appendAttribute("Attendee", attval);
			break;
		}
	}
	
	if (!bFound && mtgObj.getAttribute("Type")[0].equals(meeting.PUBLIC)) {
		s = uid + meeting.DELIMITER + meeting.ATT_OPTIONAL + respS;	//meeting.ATT_ACCEPT;
		mtgObj.appendAttribute("Attendee", s);
	}

	mMgr.commit(mtgObj);
	
	// Google Calendar (code from post_mtg_new.jsp)
	// TODO: in the future we should support update/delete Google calendar meeting
	if (respS.equalsIgnoreCase(meeting.ATT_ACCEPT) && pstuser.getStringAttribute("GoogleID")!=null) {
		try {
			PrmGoogle googleHandler = new PrmGoogle(pstuser, true);		// handle for Google calendar
			googleHandler.addEvent(mtgObj, (TimeZone)session.getAttribute("javaTimeZone"));
		}
		catch (Exception e) {
			//response.sendRedirect("../out.jsp?e=Failed to add Google Calendar event: " + e.getMessage());
			System.out.println("(post_mtg_resp.jsp) Failed to add Google Calendar event: " + e.getMessage());
			e.printStackTrace();
			return;
		}
	}

	response.sendRedirect("mtg_view.jsp?mid=" + midS + "&refresh=1");
%>
