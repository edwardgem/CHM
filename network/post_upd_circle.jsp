<%
//
//	Copyright (c) 2008, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:		post_upd_circle.java
//	Author: 	ECC
//	Date:		12/1/08
//	Description:	Update the user's circle priority and other info.
//
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
	// called by network/circles.jsp with the following possible actions:
	// 1. drop membership from a circle
	// 2. recommend a circle to selected friends
	// 3. request to join a circle
	// 4. update circles' priority
	
	final int OP_DROP_CIRCLE	= 1;
	final int OP_INTRO			= 2;
	final int OP_REQ_CIRCLE		= 3;
	final int OP_UPDATE			= 4;
	
	PstUserAbstractObject me = pstuser;
	if ((me instanceof PstGuest))
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	userManager uMgr = userManager.getInstance();
	townManager tMgr = townManager.getInstance();
	
	PstAbstractObject o;
	String s, idS;
	int myUid = me.getObjectId();
	me = (PstUserAbstractObject)uMgr.get(me, myUid);
	
	///////////////////////////////////
	// construct the Hash for circle type
	Hashtable hsHigh, hsMed, hsLow;
	
	Object bObj = me.getAttribute("CircleType")[0];
	String bStr = (bObj==null)?"":new String((byte[])bObj);
	
	hsHigh = Util3.fillHash(bStr, "high");
	hsMed  = Util3.fillHash(bStr, "medium");
	hsLow  = Util3.fillHash(bStr, "low");
	
	Hashtable [] hsArr1 = {hsHigh, hsMed, hsLow};
	
	int op = 0;
	String msg = null;
	
	// case 1: drop membership from this circle
	if ((idS = request.getParameter("drop"))!=null && idS.length()>0)
	{
		op = OP_DROP_CIRCLE;
		
		// remove the town from my attribute
		me.removeAttribute("Towns", new Integer(idS));
		uMgr.commit(me);
		session.setAttribute("pstuser", me);

		// remove the id from all the hashes
		for (int i=0; i<hsArr1.length; i++)
			hsArr1[i].remove(idS);
	}
	
	// case 2: recommend a circle to selected friends (this has to be in position 2)
	else if (request.getParameter("introCircle").equals("true"))
	{
		op = OP_INTRO;

		// send a request to the friends to intro a friend
		s = request.getParameter("optMsg");
		idS = request.getParameter("reqCircle");			// the friend to be introduced to others
		o = tMgr.get(me, Integer.parseInt(idS));			// idS is the user I am introducing to others
		String cirName = (String)o.getAttribute("Name")[0];
		String introName = "<a href='my_page.jsp?uid=" + idS + "'>" + cirName + "</a>";
		String [] friendIds = request.getParameterValues("IntroFriends");
		if (friendIds!=null && friendIds.length>0)
		{
			// don't do it if this is already a current member
			String currentMemberListS = "";
			int [] ids = uMgr.findId(me, "Towns=" + idS);
			for (int i=0; i<ids.length; i++)
			{
				currentMemberListS += ids[i] + ";";
			}
			int ct = 0;
			for (int i=0; i<friendIds.length; i++)
			{
				if (currentMemberListS.indexOf(friendIds[i]) != -1) continue;
				Util3.sendRequest(me, friendIds[i], req.REQ_INTROC, s, introName, idS);	// idS is circleId
				ct++;
			}
			msg = "Your request to recommend " + cirName + " has been sent to " + ct
				+ " people.  The request would not be sent if they are already members of the circle.";
		}
	}
	
	// case 3: request to join a circle
	else if ((idS = request.getParameter("reqCircle"))!=null && idS.length()>0)
	{
		op = OP_REQ_CIRCLE;

		// create a request object
		s = request.getParameter("optMsg");
		Util3.sendRequest(me, null, req.REQ_CIRCLE, s, null, idS);				// idS is the circleId	
		msg = "Your request to join the circle has been sent.";

	}
	
	// case 4: update circles' priority
	else
	{
		op = OP_UPDATE;

		// update circle priority
		String pri;
		for (Enumeration e = request.getParameterNames() ; e.hasMoreElements() ;)
		{
			String temp = (String)e.nextElement();
			if (temp.startsWith("update_"))
			{
				idS = temp.substring(7);
				
				// go thru the priorities
				if ((pri = request.getParameter("pri_" + idS)) != null)
				{
					if (pri.equals("h")) hsHigh.put(idS, ""); else hsHigh.remove(idS);
					if (pri.equals("m")) hsMed.put(idS, "");  else hsMed.remove(idS);
					if (pri.equals("l")) hsLow.put(idS, "");  else hsLow.remove(idS);
				}
			}
		}
	}	// END else update category
	
	// now write the hash back to the CircleType attribute if necessary
	if (op==OP_UPDATE)
	{
		String [] keywordArr = {"high", "medium", "low"};
		StringBuffer sBuf = new StringBuffer(4096);
		Enumeration k;
		for (int i=0; i<hsArr1.length; i++)
		{
			if (hsArr1[i].size() > 0)
			{
				sBuf.append(keywordArr[i]);
				for (k = hsArr1[i].keys() ; k.hasMoreElements() ;)
				{
					idS = (String)k.nextElement();
					sBuf.append("@" + idS);
				}
				sBuf.append("@@");
			}
		}
		
		String bText = sBuf.toString();
		me.setAttribute("CircleType", bText.getBytes());
		uMgr.commit(me);
	}
	
	if (msg != null)
		session.setAttribute("errorMsg", msg);
		
	switch (op)
	{
		case OP_DROP_CIRCLE:
			response.sendRedirect("circles.jsp");		// the circle is removed from my list
			break;
		case OP_INTRO:
		case OP_REQ_CIRCLE:
			response.sendRedirect(request.getParameter("backPage"));
			break;
		case OP_UPDATE:
			response.sendRedirect("circles.jsp?my=" + request.getParameter("my"));
			break;
		default:
			response.sendRedirect("circles.jsp");		// shouldn't happen
			break;
	}
%>
