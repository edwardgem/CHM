<%@ page contentType="text/html; charset=utf-8"%>
<%
//
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_addalert.java
//	Author: ECC
//	Date:		02/27/2004
//	Description:	Add and send an alert message.
//	Modification:
//		@022704ECC	Created.
//		@040505ECC	Alert is changed to memo org.  Also support adding comments to alert.
//		@AGQ030106	Expand DL and remove duplicate users
//		@AGQ030806	Implemented Guest Emails
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
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	boolean NO_MAIL = false;
	String COMPANY_NAME = Util.getPropKey("pst", "COMPANY_NAME");
	String appS = Util.getPropKey("pst", "APPLICATION");
	if (appS == null || appS.equals("OMF")) appS = "MeetWE";		// for email to use

	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ( (iRole & user.iROLE_ADMIN) > 0 )
		isAdmin = true;

	// Check account balance and charge user
	String parentIdS = request.getParameter("parentId");
	String backPage = request.getParameter("backPage").replace(':','&');

	// msg text
	String alertMsg = request.getParameter("MsgText");
	if (parentIdS != null)
	{
		alertMsg = alertMsg.replaceAll("\n","<br>");	// using ASCII text editor
		backPage = "seealert.jsp?memoId=" + parentIdS + "&show=true&backPage=" + backPage;
	}

	int uid = pstuser.getObjectId();
	String uidS = String.valueOf(uid);
	userManager uMgr = userManager.getInstance();

	if (alertMsg.length() == 0)
	{
		response.sendRedirect(backPage);
		return;
	}

	Date today = new Date();
	String subject = null, taskIdS = null, projIdS = null;
	String [] alertPersonnel = null;
	boolean bHidden = false;
	if (isAdmin) bHidden = true;

	if (parentIdS == null)
	{
		// not adding comment but a top level memo

		// get mail host and all that

		// subject
		subject = request.getParameter("Subject");

		taskIdS = request.getParameter("taskId");	// this can be null
		projIdS = request.getParameter("projId");	// MUST provide this to proj team

		// receipients
		alertPersonnel = request.getParameterValues("AlertPersonnel");
// @AGQ030106
		dlManager dlMgr = dlManager.getInstance();
		alertPersonnel = dlMgr.removeDuplicate(pstuser, alertPersonnel);
		// check to see if Whole Town, Whole Proj Team, or Meeting Group exists
		// if so, only send to Whole, not individual
		String s;
		String [] sa;
		int wholeIdx = -1;
		String circleIdS = null;
		boolean isMeeting = false;
		for (int i=0; i<alertPersonnel.length; i++)
		{
			if (alertPersonnel[i].indexOf("-") != -1)
			{
				wholeIdx = i;
				if (alertPersonnel[i].equals("-3"))
					isMeeting = true;				// -1=Whole Company; -2=Whole Proj; -3=Meeting Gp; -4=circle
				else if (alertPersonnel[i].equals("-4"))
					circleIdS = request.getParameter("circleId");
				break;
			}
		}

		if (wholeIdx > -1)
		{
			// must be an tid or projId
			if (isMeeting)
			{
				int mid = Integer.parseInt(request.getParameter("mtgId"));	// send meeting note
				Object [] o = meetingManager.getInstance().get(pstuser, mid).getAttribute("Attendee");
				String [] temp = new String[alertPersonnel.length + o.length - 1];
				int j;
				for (j=0; j<o.length; j++)
				{
					s = (String) o[j];
					if (s == null) break;
					sa = s.split(meeting.DELIMITER);
					temp[j] = sa[0];
				}
				int idx = j;
				for (int i=0; i<alertPersonnel.length; i++)
				{
					if (alertPersonnel[i].charAt(0) == '-') continue;
					temp[idx++] = alertPersonnel[i];
				}
				alertPersonnel = temp;
			}
			else if (circleIdS != null)
			{
				// circle page blog to circle member
				int [] ids = uMgr.findId(pstuser, "Towns=" + circleIdS);
				alertPersonnel = new String[ids.length];
				for (int i=0; i<ids.length; i++)
					alertPersonnel[i] = String.valueOf(ids[i]);
			}
			else if (projIdS != null)
			{
				// send to project team
				project pj = (project)projectManager.getInstance().get(pstuser, Integer.parseInt(projIdS));
				Object [] teamIdList = pj.getAttribute("TeamMembers");
				alertPersonnel = new String[teamIdList.length];
				for (int i=0; i< teamIdList.length; i++)
					alertPersonnel[i] = ((Integer)teamIdList[i]).toString();
			}
			else
			{
				// send to everyone in the company
				int [] ids = uMgr.findId(pstuser, "om_acctname='%'");
				alertPersonnel = new String[ids.length];
				for (int i=0; i<ids.length; i++)
					alertPersonnel[i] = String.valueOf(ids[i]);
			}
			//bHidden = true;
		}
	}

	// check alert option type
	String option = request.getParameter("AlertOption");
	if (parentIdS!=null || option.equals("web") || option.equals("both"))
	{
		// put alert into database (result object)
		memoManager mMgr = memoManager.getInstance();
		memo memoObj = (memo)mMgr.create(pstuser);

		memoObj.setAttribute("Comment", alertMsg.getBytes("UTF-8"));
		memoObj.setAttribute("CreatedDate", today);
		memoObj.setAttribute("Creator", String.valueOf(pstuser.getObjectId()));
		//memoObj.setAttribute("Type", "Alert");		// Alert vs. Blog (=Town, Project, Task)
		if (parentIdS != null)
		{
			// adding comments to the memo
			memoObj.setAttribute("ParentID", parentIdS);
		}
		else
		{
			memoObj.setAttribute("Name", subject);
			memoObj.setAttribute("TaskID", taskIdS);		// TaskID can be null
			memoObj.setAttribute("ProjectID", projIdS);
			memoObj.setAttribute("Alert", alertPersonnel);
		}
		mMgr.commit(memoObj);		// save to disk
	}

	if (parentIdS==null && (option.equals("email") || option.equals("both")))
	{
		// get mail address
		String from = (String)pstuser.getAttribute("Email")[0];

		// add to subject
		String townN = null;
		if (appS.equals("MeetWE"))
		{
			if (subject.charAt(0) != '[')
				subject = "[MeetWE] " + subject;
		}
		/*else
		{
			String townIdS = request.getParameter("townId");
			if ((townIdS == null) || (townIdS.equals("null")))
				townN = COMPANY_NAME;
			else
				townN = PstManager.getNameById(pstuser, Integer.parseInt(townIdS));
			subject = "[" + townN +"] " + subject;
		}*/

		// add to msgText
		//alertMsg = alertMsg.replaceAll("/PRM/FCKeditor", host+"/FCKeditor");

		// from (firstName lastname)
		String lname = (String)pstuser.getAttribute("LastName")[0];
		String uname = ((user)pstuser).getFullName();

		String s = uname + " has sent you the following message:<br><br>";
		alertMsg = s + alertMsg;

		// to email addr
		for (int i=0; i<alertPersonnel.length; i++)
		{
			// alertPersonnel is the name array now, put Email into the same array
			if (StringUtil.isNullOrEmptyString(alertPersonnel[i])) continue;
			user touser = (user)uMgr.get(pstuser, Integer.parseInt(alertPersonnel[i]));
			s = (String)touser.getAttribute("Email")[0];
			if (s == null) continue;
			alertPersonnel[i] = s;			// change to email address
		}

		// Store Guest Emails
// @AGQ030806
		String emailStr = request.getParameter("guestEmails");
		String [] guestEmails = Util.expandGuestEmails(emailStr);

		// send mail
		String fileName = "alert.htm";		// this file is located at ???
		if (!NO_MAIL)
		{
			boolean rc = Util.sendMailAsyn(pstuser, from, alertPersonnel, null, null, subject,
							alertMsg, fileName, null, guestEmails, bHidden);
			if (rc)
				System.out.println("SendMail: "+ subject);
			else {
				System.out.println( "Failed in sendMail (post_addalert.jsp)");
				response.sendRedirect("../out.jsp?e=Failed in sending Email.");
				return;
			}
		}
	}

	if (backPage==null || backPage.length()<=0)
		backPage = "../ep_home.jsp";

	response.sendRedirect(backPage);
%>
