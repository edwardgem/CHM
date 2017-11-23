<%@ page contentType="text/html; charset=utf-8"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<%
//
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_updbug.java
//	Author: ECC
//	Date:		01/06/2005
//	Description:	Add and update a bug.
//	Modification:
//		@010605ECC	Created.
//		@041905ECC	Support workflow and notification for bug state tx.
//		@ECC082605	Added Class ISSUE.  Issue can be elevated to a formal CR and be tracked in lifecycle.
//		@AGQ032906	Support of multiple files
//		@ECC040506	Support multiple owners.
//		@ECC041406	Support user-defined bug priority.
//		@AGQ071906	Support of setting default owner to project coordinator
//		@AGQ080406 	Fixed problem with missing owner id
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.util.file.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.PepCommentVector" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>
<%@ page import = "java.net.URLEncoder" %>
<%@ page import = "com.oreilly.servlet.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />


<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	String repository = Util.getPropKey("pst", "FILE_UPLOAD_PATH");
	MultipartRequest mrequest = new MultipartRequest(request, repository, 100*1024*1024, "UTF-8");

	int myUid = pstuser.getObjectId();
	String myUidS = String.valueOf(myUid);

	bugManager bugMgr = bugManager.getInstance();
	userManager uMgr = userManager.getInstance();
	projectManager pjMgr = projectManager.getInstance();
	resultManager rMgr = resultManager.getInstance();
	userinfoManager uiMgr = userinfoManager.getInstance();

	String s;
	String myName = ((user)pstuser).getFullName();

	int iRole = ((Integer)session.getAttribute("role")).intValue();

	Date today = new Date();

	// get parameters
	String bugIdS = mrequest.getParameter("bugId");		// this can be null
	String projIdS = mrequest.getParameter("projId");
	String taskIdS = mrequest.getParameter("taskId");	// this can be null
	String type = mrequest.getParameter("type");
	String state = mrequest.getParameter("status");
	String priority = mrequest.getParameter("priority");
	String severity = mrequest.getParameter("severity");
	String release = mrequest.getParameter("release");
	String synopsis = mrequest.getParameter("synopsis").trim();
	String category = mrequest.getParameter("category");
	String processType = mrequest.getParameter("processType");
	String userDepartment = mrequest.getParameter("userDept");
	String priUDef = mrequest.getParameter("priUDef");	// @ECC041406
	String verifier = mrequest.getParameter("verifier");
	String reason = mrequest.getParameter("reason"); 
	String parentIdS = mrequest.getParameter("mainCR");
	
	String townIdS = mrequest.getParameter("townId");
	if (StringUtil.isNullOrEmptyString(townIdS))
		townIdS = pstuser.getStringAttribute("Company");
	
	project pjObj = (project)pjMgr.get(pstuser, Integer.parseInt(projIdS));

	
	//add by zhaoyf
	String username2 = mrequest.getParameter("Username2");
	username2 = ( StringUtil.isNullOrEmptyString(username2) ) ? "" : username2.trim(); 
	String email2 = mrequest.getParameter("Email2");
	email2 = ( StringUtil.isNullOrEmptyString(email2) ) ? "" : email2.trim(); 
	//boolean isTicketSystem = (s=mrequest.getParameter("isTicketSystem"))!=null && s.equals("true");
	
	// ECC: this might not be very intuitive that
	// the Description attribute stores the history of this bug
	// the initial note/description is stored in the note attribute
	String note = mrequest.getParameter("note");
	note = (note==null)?"":note.trim();
	
	String resoln = mrequest.getParameter("resoln");
	resoln = (resoln==null)?"":resoln.trim();
	
	String soln = mrequest.getParameter("soln");
	soln = (soln==null)?"":soln.trim();
	
	// combine note (Description), resoln and soln into one string
	note += "!@@!";
	if (resoln != "") note += resoln + "!@@!";
	if (soln != "") note += soln;

	String comment = mrequest.getParameter("comment");
	comment = (comment==null)?"":comment.trim();

	//boolean newBug = false;
	String setDefaultOwner = Util.getPropKey("pst", "BUG_SET_DEFAULT_OWNER");

	if (priUDef != null)
		priority += priUDef;

	// @ECC040506 support for multiple owners
	String [] sa;
	int numOfOwner;								// total no. of owners
	String [] ownerAttr;						// array that holds the attribute names
	s = Util.getPropKey("pst", "BUG_OWNER_ATTRIBUTE");
	if (!StringUtil.isNullOrEmptyString(s))
	{
		sa = s.split(";");						// e.g. Owner; Owner1
		numOfOwner = sa.length;
		ownerAttr = new String[numOfOwner];
		for (int i=0; i<numOfOwner; i++)
			ownerAttr[i] = sa[i].trim();
	}
	else
	{
		numOfOwner = 1;
		ownerAttr = new String[1];
		ownerAttr[0] = "Owner";					// default owner attr name
	}

	boolean hasOwner = false;
	String [] owner = new String[numOfOwner];
	for (int i=0; i<numOfOwner; i++)
	{
		owner[i] = mrequest.getParameter("owner" + i);
		if (!StringUtil.isNullOrEmptyString(owner[i]))
			hasOwner = true;
	}

	// status: move an open bug to active when assign owner
	if (state.equals(bug.OPEN) && hasOwner)
		state = bug.ACTIVE;

	// description text (ECC: not used)
	// String description = mrequest.getParameter("bugText");

	// create the bug object if it is a New Create
	boolean isCreateNew;
	String oldPriority = "";
	String oldSeverity = "";
	String oldVerifier = "";
	String oldProcessType = null;
	String oldUserDepartment = null;

	bug bugObj = null;
	if (bugIdS == null)
	{
		// this is a create
		bugObj = (bug)bugMgr.create(pstuser);
		oldPriority = bug.PRI_MED;
		isCreateNew = true;
	}
	else
	{
		// this is an update of an existing bug
		bugObj = (bug)bugMgr.get(pstuser, bugIdS);
		oldPriority = (String)bugObj.getAttribute("Priority")[0];
		oldSeverity = (String)bugObj.getAttribute("Severity")[0];
		oldVerifier = (String)bugObj.getAttribute("Verifier")[0];
		if (oldVerifier == null) oldVerifier = "";

		try {oldProcessType = (String)bugObj.getAttribute("ProcessType")[0];}
		catch (PmpException e) {oldProcessType = null;}	// ProcessType probably not define
		if (oldProcessType == null) oldProcessType = "none";

		try {oldUserDepartment = (String)bugObj.getAttribute("DepartmentName")[0];}
		catch (PmpException e) {oldUserDepartment = null;}	// DepartmentName probably not define
		if (oldUserDepartment == null) oldUserDepartment = "none";

		isCreateNew = false;
	}

	// @AGQ071906 & @AGQ080406 (moved code)
	if (setDefaultOwner!=null && setDefaultOwner.equalsIgnoreCase("true") && !hasOwner && projIdS!=null) {
		try {
			Object obj = pjObj.getAttribute("Owner")[0];
			if (obj!=null) {
				owner[0] = obj.toString();
				hasOwner = true;
				state = bug.ACTIVE;
			}
		} catch (NumberFormatException e) {}
	}


	////////////////////////////////////////////////////////
	// find out old state and new state early on to decide what to do
	String oldState = (String)bugObj.getAttribute("State")[0];
	if (oldState == null) oldState = "";
	int oldSt = -1, newSt = -1;

	for (int i=0; i<bug.STATE_ARRAY.length; i++)
	{
		if (oldState.equals(bug.STATE_ARRAY[i]))
		{
			oldSt = i;
			break;
		}
	}
	for (int i=0; i<bug.STATE_ARRAY.length; i++)
	{
		if (state.equals(bug.STATE_ARRAY[i]))
		{
			newSt = i;
			break;
		}
	}

	// upon resolved and beyond, must supply reason
	if (newSt >= 2) {
		if (reason==null || reason.length()<=0) {
			response.sendRedirect("../out.jsp?e=You must supply a reason when the bug is "
				+ bug.STATE_ARRAY[newSt]);
			return;
		}
	}

	// creating the bug
	if (bugObj.getAttribute("Creator")[0] == null)
	{
		bugObj.setAttribute("Creator", String.valueOf(pstuser.getObjectId()));
		bugObj.setAttribute("CreatedDate", today);
		bugObj.setAttribute("Company", townIdS);
	}

	// @041905ECC remember old values
	String oldType = (String)bugObj.getAttribute("Type")[0];		// see if it was an Issue
	String [] oldOwner = new String[numOfOwner];
	for (int i=0; i<numOfOwner; i++) {
		oldOwner[i] = (String)bugObj.getAttribute(ownerAttr[i])[0];
	}

	// check to see if there is transfer of ownership
	boolean bTransferOwner = false;
	for (int i=0; i<numOfOwner; i++)
	{
		if (StringUtil.isNullOrEmptyString(owner[i]) && oldOwner[i]==null) continue;
		if (owner[i]==null || owner[i].equals(oldOwner[i])) continue;	// owner field disabled or match
		bTransferOwner = true;
		break;
	}
	
	try {
		if (type.equals("ticket") || type.equals("sas")){
			bugObj.setAttribute("Username2", username2);
			bugObj.setAttribute("Email2", email2);
		}
	} catch (PmpException e) {}
	
	// parentID
	if (parentIdS != null) {
		parentIdS = parentIdS.trim();
		// see if the entered ID is a valid ID
		try {
			bugMgr.get(pstuser, parentIdS);
		}
		catch (PmpException e) {
			parentIdS = null;		// the entered parentID (mainCR) is invalid
		}
		bugObj.setAttribute("ParentID", parentIdS);
	}
	
	//
	bugObj.setAttribute("LastUpdatedDate", today);
	bugObj.setAttribute("ProjectID", projIdS);
	bugObj.setAttribute("TaskID", taskIdS);
	bugObj.setAttribute("Type", type);						// class of bug
	bugObj.setAttribute("State", state);
	bugObj.setAttribute("Priority", priority);
	bugObj.setAttribute("Severity", severity);
	bugObj.setAttribute("Release", release);
	bugObj.setAttribute("Category", category);
	try {
		bugObj.setAttribute("ProcessType", processType);		// can be null
		bugObj.setAttribute("DepartmentName", userDepartment);	// can be null
	}
	catch (PmpException e) {}	// ProcessType/DepartmentName probably not defined

	bugObj.setAttribute("Note", URLEncoder.encode(note, "UTF-8").getBytes());
	bugObj.setAttribute("Result", reason);
	bugObj.setAttribute("Verifier", verifier);

	// update owner?
	for (int i=0; i<numOfOwner; i++)
	{
		if (owner[i] == null) continue;		// field disabled
		//if ( owner[i]=="" || oldState.equals(bug.OPEN) || oldState.equals(bug.ACTIVE) ) {
		if (!owner[i].equals(oldOwner[i])) {
			// might be "" in which case is to remove owner
			bugObj.setAttribute(ownerAttr[i], owner[i]);
		}
	}

	if (synopsis != "")
		bugObj.setAttribute("Synopsis", synopsis);

	SimpleDateFormat df = new SimpleDateFormat ("MMMMMMMM dd, yyyy (EEE) hh:mm a");
	
	userinfo myUI = (userinfo) uiMgr.get(pstuser, myUidS);
	TimeZone myTimeZone = myUI.getTimeZone();
	if (!userinfo.isServerTimeZone(myTimeZone)) {
		df.setTimeZone(myTimeZone);
	}

	String todayS = df.format(today);
	boolean bNewHistory = false;
	Object bTextObj;
	String bText = "";

// @AGQ032906
	Enumeration enumeration = mrequest.getFileNames();
	while (enumeration.hasMoreElements()) {
		Object name = enumeration.nextElement();
		File AttachmentFileObj = mrequest.getFile(name.toString());
		if(AttachmentFileObj != null)
		{
			FileTransfer ft = new FileTransfer(pstuser);
			try
			{
				attachment att = ft.saveFile(bugObj.getObjectId(), projIdS, AttachmentFileObj,
						null, attachment.TYPE_BUG, null, null, false);
				bugObj.appendAttribute("AttachmentID", String.valueOf(att.getObjectId()));
				String fname = AttachmentFileObj.getName();

				// keep history of upload file
				if (!bNewHistory)
				{
					bTextObj = bugObj.getAttribute("Description")[0];
					if (bTextObj != null)
						bText = new String((byte[])bTextObj, "utf-8");
				}
				s = "<font color='#003399'><b>" + myName + "</b> uploaded file <b>" + fname + "</b> on " + todayS + "</font><br><br>";
				bText = s + bText;
				bNewHistory = true;
			}
			catch(Exception e)
			{
				if (bugIdS == null) bugMgr.delete(bugObj);
				e.printStackTrace();
				String msg = e.getMessage();
				if (msg == null) msg = "";
				response.sendRedirect("../out.jsp?e=Failed to upload file. "+ msg);
				return;
			}
		}
	}

	// get project coordinator for notification
	String coordinatorIdS = (String)pjObj.getAttribute("Owner")[0];

	// @041905ECC Send notification memo according to workflow
	// ***** 0=open 1=active 2=analyzed 3=feedback 4=close *****
	String MAILFILE = "alert.htm";
	String FROM = (String)pstuser.getAttribute("Email")[0];	//Util.getPropKey("pst", "FROM");
	String NODE = Util.getPropKey("pst", "PRM_HOST");
	String subj=null, msg=null;
	String head = "[CPM Tracker] ";
	user u;
	String uName, lastName;
	int id = bugObj.getObjectId();
	boolean bSendAlert = false;
	Object [] userIdArr = new Object[1];		// contain the user id (String) of the recipient
	String sysHistory = null;

	String bugCreatorIdS = (String)bugObj.getAttribute("Creator")[0];

	// case 1: file a new bug (open) (@ECC082605 or move an issue to a CR)
	// @AGQ071906 Extra case: New to Assigned
	if ((oldSt==-1 && newSt==0) || (oldSt==-1 && newSt==1) || (oldType!=null && oldType.equals(bug.CLASS_ISSUE)) )
	{
		// notify submitter's manager
		/*if ( (iRole & user.iROLE_MANAGER) > 0 )
			s = myUidS;			// send notification to myself
		else
		{
			u = (user)pstuser;
			s = (String)u.getAttribute("Supervisor1")[0];
			if (s == null)
				s = myUidS;		// I have no manager, I will assign the bug myself
		}*/
		s = coordinatorIdS;		// ECC: notify project coordinator

		subj = head + "New CR " + bugObj.getObjectId() + " filed";
		msg  = "A new change request has been filed by <b>" + myName + "</b> on " + today.toString();
		msg += "<blockquote>CR <b><a href='" + NODE + "/bug/bug_update.jsp?bugId="
			+ id + "&edit=true'>" + id + "</a></b> : " + synopsis + "</blockquote>";
		userIdArr[0] = s;		// recipient user id
		bSendAlert = true;

		// @AGQ071906 Attach history if bug is assigned
		if (setDefaultOwner!=null && setDefaultOwner.equalsIgnoreCase("true")) {
			StringBuffer sb = new StringBuffer();
			if (owner.length > 0) {
				try {
				PstAbstractObject pstObj = uMgr.get(pstuser, Integer.parseInt(owner[0]));
				Object obj = pstObj.getAttribute("FirstName")[0];
				if (obj!=null) sb.append(obj.toString() + " ");
				obj = pstObj.getAttribute("LastName")[0];
				if (obj!=null) sb.append(obj.toString());
				sysHistory = "<font color='#aa0000'><b>CR Assigned</b> by CPM to " + sb.toString()
									+ " on " + todayS + "</font><p>";
				} catch (NumberFormatException e) {}
			}
		}
		else
			sysHistory = "";

		sysHistory += "<font color='#aa0000'><b>CR Created</b> by " + myName
							+ " on " + todayS + "</font><p>";
							
		// event		
		PrmEvent.createTriggerEvent(pstuser, "701",			// event.csv 701 = filed
				projIdS,									// evt idS1 (project ID)
				String.valueOf(bugObj.getObjectId()),		// evt idS2 (bug ID)
				null);
		
	}	// END: case 1

	// case 2: open to active
	else if (oldSt==0 && newSt==1)
	{
		// notify the new owner
		// I am the assignee (manager of submitter or the submitter himself if he is a Manager)
		subj = head + "New CR " + bugIdS + " assigned";
		msg = "A new change request has been assigned by <b>" + myName + "</b> to you.";
		msg += "<blockquote>CR <b><a href='" + NODE + "/bug/bug_update.jsp?bugId="
			+ id + "&edit=true'>" + id + "</a></b> : " + synopsis + "</blockquote>";

		sysHistory = "<font color='#aa0000'><b>CR Assigned</b> by " + myName + " to ";
		userIdArr = new String[numOfOwner];
		hasOwner = false;
		for (int i=0; i<numOfOwner; i++)
		{
			userIdArr[i] = owner[i];		// recipient user id
			if (StringUtil.isNullOrEmptyString(owner[i])) continue;
			if (hasOwner) sysHistory += ", ";

			System.out.println("owners: " + numOfOwner + " owner" + i + ":" + owner[i]);

			u = (user)uMgr.get(pstuser, Integer.parseInt(owner[i]));
			uName = (String)u.getAttribute("FirstName")[0];
			lastName = (String)u.getAttribute("LastName")[0];
			uName = uName + (lastName==null?"":(" "+lastName));			// s is the owner's full name
			sysHistory += uName;
			hasOwner = true;
		}
		sysHistory += " on " + todayS + "</font><p>";
		bSendAlert = true;
	}

	// case 3: active to active (transfer ownership)
	else if (oldSt==1 && newSt==1 && bTransferOwner)
	{
		// notify the new owner
		// I am the old owner
		subj = head + "CR " + bugIdS + " re-assigned";
		msg = "A change request has been re-assigned by <b>" + myName + "</b> to you.";
		msg += "<blockquote>CR <b><a href='" + NODE + "/bug/bug_update.jsp?bugId="
			+ id + "&edit=true'>" + id + "</a></b> : " + synopsis + "</blockquote>";

		sysHistory = "<font color='#aa0000'><b>CR Re-assigned</b> by " + myName + " to ";
		userIdArr = new String[numOfOwner];
		hasOwner = false;

		for (int i=0; i<numOfOwner; i++)
		{
			if ( (StringUtil.isNullOrEmptyString(owner[i]))
				|| (!StringUtil.isNullOrEmptyString(oldOwner[i]) && owner[i].equals(oldOwner[i])) )
				continue;

			if (hasOwner) sysHistory += ", ";
			
			// owner has changed
			userIdArr[i] = owner[i];		// recipient user id
			u = (user)uMgr.get(pstuser, Integer.parseInt(owner[i]));
			uName = (String)u.getAttribute("FirstName")[0];
			lastName = (String)u.getAttribute("LastName")[0];
			uName = uName + (lastName==null?"":(" "+lastName));			// s is the owner's full name
			sysHistory += uName;
			hasOwner = true;
		}
		if (!hasOwner) sysHistory += "(null - owner removed)";
		sysHistory += " on " + todayS + "</font><p>";
		if (hasOwner) bSendAlert = true;
	}

	// case 4: active to analyzed (resolved)
	else if (oldSt==1 && newSt==2)
	{
		// notify the submitter and verifier
		// I am the owner
		verifier = (String)bugObj.getAttribute("Verifier")[0];
		if (verifier!=null && !verifier.equals(bugCreatorIdS) && !verifier.equals(myUidS)) {
			userIdArr = new String[2];
			userIdArr[1] = verifier;	// userIdArr[0] is filled below
		}
		bugObj.setAttribute("CompleteDate", today);

		subj = head + "CR " + bugIdS + " resolved";
		msg = "A change request has been resolved by <b>" + myName + "</b>.  It is ready to be verified.";
		msg += "<blockquote>CR <b><a href='" + NODE + "/bug/bug_update.jsp?bugId="
			+ id + "&edit=true'>" + id + "</a></b> : " + synopsis + "</blockquote>";
		userIdArr[0] = bugCreatorIdS;		// recipient user id
		bSendAlert = true;
		sysHistory = "<font color='#aa0000'><b>CR Analyzed/Resolved</b> by " + myName + " on " + todayS + "</font><p>";
		
		// event
		PrmEvent.createTriggerEvent(pstuser, "710",			// event.csv, 710 = resolved
				projIdS,									// evt idS1 (project ID)
				String.valueOf(bugObj.getObjectId()),		// evt idS2 (bug ID)
				null);
	}	// END: case 4

	// case 5: analyzed (resolved) back-to active (re-open)
	else if (oldSt==2 && newSt==1)
	{
		// notify the owner
		// I am the submitter
		bugObj.setAttribute("CompleteDate", null);	// not completed

		subj = head + "CR " + bugIdS + " re-activated";
		msg = "A change request is re-activated by <b>" + myName + "</b>.  It is waiting for your analysis.";
		msg += "<blockquote>CR <b><a href='" + NODE + "/bug/bug_update.jsp?bugId="
			+ id + "&edit=true'>" + id + "</a></b> : " + synopsis + "</blockquote>";

		sysHistory = "<font color='#aa0000'><b>CR Re-activated</b> by " + myName + " and transfered back to ";
		userIdArr = new String[numOfOwner];
		hasOwner = false;
		for (int i=0; i<numOfOwner; i++)
		{
			userIdArr[i] = owner[i];		// alert all owners, recipient user id
			if (StringUtil.isNullOrEmptyString(owner[i])) continue;
			//if (owner[i] == null) continue;
			if (hasOwner) sysHistory += ", ";
			System.out.println("=====");

			u = (user)uMgr.get(pstuser, Integer.parseInt(owner[i]));
			uName = (String)u.getAttribute("FirstName")[0];
			lastName = (String)u.getAttribute("LastName")[0];
			uName = uName + (lastName==null?"":(" "+lastName));			// s is the owner's full name
			sysHistory += uName;
			hasOwner = true;
		}
		sysHistory += " on " + todayS + "</font><p>";
		bSendAlert = true;
	}

	// case 6: analyzed (resolved) to feedback (verified)
	else if (oldSt==2 && newSt==3)
	{
		// notify the submitter's manager (to close)
		/*if ( (iRole & user.iROLE_MANAGER) > 0 )
			s = myUidS;			// send notification to myself
		else
		{
			u = (user)pstuser;
			s = (String)u.getAttribute("Supervisor1")[0];
			if (s == null)
				s = myUidS;		// I have no manager, I will assign the bug myself
		}*/
		user creator = (user)uMgr.get(pstuser, Integer.parseInt(bugCreatorIdS));// bug creater person
		if("Ticket".equals(creator.getAttribute("FirstName")[0])
				&& "System".equals(creator.getAttribute("LastName")[0])){
			String subject = head + "CR " + bugIdS + " resolved";
			String messsage = "A change request has been verified by <b>" + myName + "</b>.  It is ready to be closed.";
			messsage += "<blockquote>CR <b><a href='" + NODE + "/ticket/index.jsp?bugId="
				+ id + "'>" + id + "</a></b> : " + synopsis + "</blockquote>";
			Object [] emailTo = new Object[]{bugObj.getAttribute("Email2")[0]};
			Util.sendMailAsyn(pstuser, (String)pstuser.getAttribute("Email")[0],
					emailTo, null, null, subject, messsage, MAILFILE);
		}
		bugObj.setAttribute("VerifiedDate", today);
		s = coordinatorIdS;

		subj = head + "CR " + bugIdS + " is ready to be closed";
		msg  = "A change request has been resolved.  It is verified by <b>" + myName + "</b>.  You can close this CR now.";
		msg += "<blockquote>CR <b><a href='" + NODE + "/bug/bug_update.jsp?bugId="
			+ id + "&edit=true'>" + id + "</a></b> : " + synopsis + "</blockquote>";
		userIdArr[0] = s;		// recipient user id
		bSendAlert = true;
		sysHistory = "<font color='#aa0000'><b>CR Feedback/Verified</b> by " + myName + " on " + todayS + "</font><p>";
	}

	// case 7: closed
	else if (oldSt==3 && newSt==4)
	{
		// no notification
		sysHistory = "<font color='#aa0000'><b>CR Closed</b> by " + myName + " on " + todayS + "</font><p>";
	}

	// save bug object before sending email
	if (sysHistory != null)
	{
		if (!bNewHistory)
		{
			bTextObj = bugObj.getAttribute("Description")[0];
			if (bTextObj != null)
				bText = new String((byte[])bTextObj, "utf-8");
		}

		if (oldSt < 0)
			bText += sysHistory;			// for newly create, put the history at bottom
		else
			bText = sysHistory + bText;
	}
	if (bNewHistory || sysHistory!=null)
	{
		//bugObj.setAttribute("Description", bText.getBytes());
		bugObj.setAttribute("Description", bText.getBytes("UTF-8")); //Aaron
	}

	// history management
	// change processType?
	if (StringUtil.isNullOrEmptyString(processType)) processType = "none";
	if (!isCreateNew && !oldProcessType.equals(processType)) {
		sysHistory = "<b>Process-type changed </b> from " + oldProcessType + " to " + processType;
		bugObj.appendSystemHistory(pstuser, sysHistory);		// this call will not commit
	}
	
	// change user department?
	if (StringUtil.isNullOrEmptyString(userDepartment)) userDepartment = "none";
	if (!isCreateNew && !oldUserDepartment.equals(userDepartment)) {
		sysHistory = "<b>User-department changed </b> from " + oldUserDepartment + " to " + userDepartment;
		bugObj.appendSystemHistory(pstuser, sysHistory);		// this call will not commit
	}

	// change priority?
	if (!isCreateNew && !oldPriority.equals(priority)) {
		sysHistory = "<b>Priority changed </b> from " + oldPriority + " to " + priority;
		bugObj.appendSystemHistory(pstuser, sysHistory);		// this call will not commit
	}

	// change severity?
	if (!isCreateNew && !oldSeverity.equals(severity)) {
		sysHistory = "<b>Severity changed </b> from " + oldSeverity + " to " + severity;
		bugObj.appendSystemHistory(pstuser, sysHistory);		// this call will not commit
	}

	// change verifier?
	if (verifier == null) verifier = "";
	if (!isCreateNew && !oldVerifier.equals(verifier)) {
		String oldName, newName;
		newName = user.getFullName(pstuser, verifier);
		if (oldVerifier == "") {
			sysHistory = "<b>Verifier assigned</b> to " + newName;
		}
		else {
			oldName = user.getFullName(pstuser, oldVerifier);
			sysHistory = "<b>Verifier assigned</b> from " + oldName + " to " + newName;
		}
		bugObj.appendSystemHistory(pstuser, sysHistory);		// this call will not commit
	}

	bugMgr.commit(bugObj);		// save to disk
	
	// save the comment (blog) text if any
	if (bugIdS == null)
		bugIdS = String.valueOf(bugObj.getObjectId());	// in the case of create new

	if (comment.length() > 0) {
		PstAbstractObject blog = rMgr.create(pstuser);
		blog.setAttribute("Creator", myUidS);
		blog.setAttribute("ProjectID", projIdS);
		blog.setAttribute("TaskID", bugIdS);
		blog.setAttribute("Type", result.TYPE_BUG_BLOG);
		blog.setAttribute("CreatedDate", today);
		comment = comment.replaceAll("\n", "<p>");
		blog.setAttribute("Comment", comment.getBytes("UTF-8"));
		rMgr.commit(blog);

		// need to add to the bug history
		String shortText = result.stripText(comment, 180);
		s = "<a class='listlink'  href='../blog/blog_task.jsp?projId="+projIdS
			+ "&bugId=" + bugIdS + "#" + blog.getObjectId() + "'>" + shortText + "</a>";
		bugObj.addCommentHistory(pstuser, s);	// this call will commit
		
		// trigger event
		String temp = "<a href='" + NODE + "/bug/bug_update.jsp?bugId=" + bugIdS
				+ "'>" + synopsis + "</a>";
		String lnkStr = "<blockquote class='bq_com'>" + shortText
				+ "... <a href='" + NODE + "/blog/blog_task.jsp?projId=" + projIdS + "&bugId="
				+ bugIdS + "#" + blog.getObjectId() + "'>read more & reply</a></blockquote>";

		event evt = PrmEvent.create(pstuser, PrmEvent.EVT_BLG_BUG, projIdS, bugIdS, null);


		PrmEvent.setValueToVar(evt, "var1", temp);
		PrmEvent.setValueToVar(evt, "var2", lnkStr);
		int [] ids = Util2.toIntArray(pjObj.getAttribute("TeamMembers"));
		int ct = PrmEvent.stackEvent(pstuser, ids, evt);
    	System.out.println(myUid + " triggered Event [" + PrmEvent.EVT_BLG_BUG + "] to "
    			+ ct + " users for bug (" + bugIdS + ") blog.");
	}

	if (bSendAlert)
	{
		/*
		System.out.println("projID = " + projIdS);
		System.out.println("taskID = " + taskIdS);
		Util.createAlert(pstuser, subj, msg, 0, null,
			Integer.parseInt(projIdS), (StringUtil.isNullOrEmptyString(taskIdS)?0:Integer.parseInt(taskIdS)), userIdArr);
		*/
		Util.sendMailAsyn(pstuser, FROM, userIdArr, null, null, subj,
			msg, MAILFILE);
	}
	
	// save user preference
	if (isCreateNew) {
		// replace BugTrkNew:ProjId=12345;Cat=Workflow;Type=support;
		// String [] newBugOptions = {"ProjId=", "Cat=", "Type="};

		String prefS = null;
		Object[] o = myUI.getAttribute("Preference");
		
		// 1. remove the existing BugTrkNew preference and save the new values
		for (int i = 0; i < o.length; i++) {
			s = (String) o[i];
			if (s!=null && s.startsWith("BugTrkNew")) {
				myUI.removeAttribute("Preference", s);
				break;		// done
			}
		}	// for all existing preference
		
		// 2. construct the new BugTrkNew preference and save it
		prefS = "BugTrkNew:"
			+ "ProjId=" + projIdS + ";"
			+ "Cat=" + category + ";"
			+ "Type=" + type + ";";
		myUI.appendAttribute("Preference", prefS);
		uiMgr.commit(myUI);
	}

	//add by zhaoyanfeng on 2014-02-12
	Object[] email;
	if (type.equals("ticket")) {
		email = new Object[]{email2};
		subj = "New CR " + bugIdS + " filed" ; 
		msg  = "A new change request has been filed on " + today.toString();
		msg += "<blockquote>CR <b><a href='" + NODE + "/ticket/index.jsp?bugId="
			+ bugIdS + "'>" + bugIdS + "</a></b> : " + synopsis + "</blockquote>";
			
		Util.sendMailAsyn(pstuser, FROM, email, null, null, subj,msg, MAILFILE);
		response.sendRedirect("../ticket/ticketDone.jsp?id=" + bugIdS
				+ "&tId=" + townIdS + "&pId=" + projIdS);
	}
	else if (type.equals("sas")) {
		String sasMgrEmail = "tleung@hku-szh.org";
		email = new Object[]{email2, sasMgrEmail};
		subj = "New Appeal Case No. " + bugIdS + " filed" ; 
		msg  = "A New Appeal Request has been filed on " + today.toString();
		msg += "<blockquote>Appeal Case <b><a href='" + NODE + "/sas/index.jsp?bugId="
			+ bugIdS + "'>" + bugIdS + "</a></b> : " + synopsis + "</blockquote>";
			
		Util.sendMailAsyn(pstuser, FROM, email, null, null, subj,msg, MAILFILE);
		response.sendRedirect("../sas/sasDone.jsp?id=" + bugIdS);
	}
	else {
		response.sendRedirect("bug_update.jsp?bugId="+bugIdS + "&edit=true");
	}
%>
