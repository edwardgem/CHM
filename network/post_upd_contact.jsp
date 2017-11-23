<%
//
//	Copyright (c) 2008, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:		post_upd_contact.java
//	Author: 	ECC
//	Date:		12/1/08
//	Description:	Update the user's contact categories and other info.
//
//	Modification:
//				@ECC021009	Support introducing a friend to other friends.
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
	// called by network/contacts.jsp with the following possible actions:
	// 1. block/remove a friend
	// 2. introduce a friend to other friends
	// 3. request a friend connection
	// 4. update friends' category and/or priority
	
	final int OP_BLOCK		= 1;
	final int OP_INTRO		= 2;
	final int OP_REQ_FRIEND	= 3;
	final int OP_UPDATE		= 4;
	
	PstUserAbstractObject me = pstuser;
	if ((me instanceof PstGuest))
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	userManager uMgr = userManager.getInstance();
	
	PstAbstractObject o;
	String s, idS;
	int myUid = me.getObjectId();
	me = (PstUserAbstractObject)uMgr.get(me, myUid);
	
	///////////////////////////////////
	// construct the Hash for contact type
	Hashtable hsWork, hsAlumni, hsSocial, hsReligion, hsFamily;
	Hashtable hsHigh, hsMed, hsLow;
	
	Object bObj = me.getAttribute("ContactType")[0];
	String bStr = (bObj==null)?"":new String((byte[])bObj);

	hsWork = Util3.fillHash(bStr, "work");
	hsAlumni = Util3.fillHash(bStr, "alumni");
	hsSocial = Util3.fillHash(bStr, "social");
	hsReligion = Util3.fillHash(bStr, "religion");
	hsFamily = Util3.fillHash(bStr, "family");
	
	hsHigh = Util3.fillHash(bStr, "high");
	hsMed  = Util3.fillHash(bStr, "medium");
	hsLow  = Util3.fillHash(bStr, "low");
	
	Hashtable [] hsArr1 = {hsWork, hsAlumni, hsSocial, hsReligion, hsFamily, hsHigh, hsMed, hsLow};
	
	int op = 0;
	String msg = null;
	
	// case 1: block a friend
	if ((idS = request.getParameter("block"))!=null && idS.length()>0)
	{
		op = OP_BLOCK;

		// first remove from my friends list
		me.removeAttribute("TeamMembers", new Integer(idS));
		uMgr.commit(me);
		session.setAttribute("pstuser", me);
		
		// also remove me from the person's TeamMembers list
		o = uMgr.get(me, Integer.parseInt(idS));
		o.removeAttribute("TeamMembers", new Integer(myUid));
		uMgr.commit(o);

		// remove the id from all the hashes
		for (int i=0; i<hsArr1.length; i++)
			hsArr1[i].remove(idS);
		
		msg = "The connection has been revoked successfully.";
	}
	
	// case 2: introduce a friend to other friends (this has to be in position 2)
	else if (request.getParameter("introFriend").equals("true"))
	{
		op = OP_INTRO;

		// send a request to the friends to intro a friend
		s = request.getParameter("optMsg");
		idS = request.getParameter("reqFriend");			// the friend to be introduced to others
		o = uMgr.get(me, Integer.parseInt(idS));			// idS is the user I am introducing to others
		String introName = "<a href='ep1.jsp?uid=" + idS + "'>" + ((user)o).getFullName() + "</a>";
		String [] friendIds = request.getParameterValues("IntroFriends");
		if (friendIds!=null && friendIds.length>0)
		{
			// don't do it if this is already a current friend
			String currentFriendListS = "";
			Object [] fArr = o.getAttribute("TeamMembers");
			for (int i=0; i<fArr.length; i++)
			{
				if (fArr[i] == null) break;
				currentFriendListS += fArr[i] + ";";
			}
			int ct = 0;
			for (int i=0; i<friendIds.length; i++)
			{
				if (currentFriendListS.indexOf(friendIds[i]) != -1) continue;
				Util3.sendRequest(me, friendIds[i], req.REQ_INTROF, s, introName, null);
				ct++;
			}
			msg = "Your request to introduce friends has been sent to " + ct
				+ " people.  The request would not be sent if they are already friends.";
		}
	}
	
	// case 3: request a friend connection
	else if ((idS = request.getParameter("reqFriend"))!=null && idS.length()>0)
	{
		op = OP_REQ_FRIEND;
		
		// create a request object
		s = request.getParameter("optMsg");
		Util3.sendRequest(me, idS, req.REQ_FRIEND, s);
		msg = "Your request for connection has been sent.";
	}
	
	// case 4: update a friends' category and/or priority
	else
	{
		op = OP_UPDATE;

		// update contact category
		String [] paramArr = {"cat_wrk_", "cat_alm_", "cat_soc_", "cat_rel_", "cat_fam_"};
		Hashtable [] hsArr = {hsWork, hsAlumni, hsSocial, hsReligion, hsFamily};
		
		String pri;
		for (Enumeration e = request.getParameterNames() ; e.hasMoreElements() ;)
		{
			String temp = (String)e.nextElement();
			if (temp.startsWith("update_"))
			{
				idS = temp.substring(7);
				
				// go thru each of the category
				for (int i=0; i<hsArr.length; i++)
				{
					if (request.getParameter(paramArr[i] + idS) != null)
						hsArr[i].put(idS, "");
					else
						hsArr[i].remove(idS);
				}
				
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
	
	// now write the hash back to the ContactType attribute if necessary
	if (op==OP_UPDATE || op==OP_BLOCK)
	{
		String [] keywordArr = {"work", "alumni", "social", "religion", "family", "high", "medium", "low"};
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
		me.setAttribute("ContactType", bText.getBytes());
		uMgr.commit(me);
	}
	
	if (msg != null)
		session.setAttribute("errorMsg", msg);

	switch (op)
	{
		case OP_BLOCK:
		case OP_INTRO:
		case OP_REQ_FRIEND:
			response.sendRedirect(request.getParameter("backPage"));
			break;
		case OP_UPDATE:
			response.sendRedirect("contacts.jsp?cId=" + request.getParameter("cirId"));
			break;
		default:
			response.sendRedirect("contacts.jsp");		// shouldn't happen
			break;
	}
%>
