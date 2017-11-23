<%
//
//	Copyright (c) 2009, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_proj_del.jsp
//	Author: ECC
//	Date:		01/15/2009
//	Description:	Add project members.  They might be current CR/CPM members,
//					if not, send them email invitation and put them on Guest.
//					Also see post_adduser.jsp.
//	Modification:
//					@ECC052714	Support adding guest members (Guest Town).
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "oct.util.file.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.util.regex.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>
<%@ page import = "org.apache.log4j.Logger" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	String NODE	= Util.getPropKey("pst", "PRM_HOST");
	String MAILFILE = "alert.htm"；

	String projIdS = request.getParameter("projId");
	if ((pstuser instanceof PstGuest) || (projIdS == null))
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	Logger l = PrmLog.getLog();
	
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	boolean isProgMgr = ((iRole & user.iROLE_PROGMGR) > 0);
	
	// to check if session is CR or PRM
	boolean isCRAPP = Prm.isCR();
	boolean isMultiCorp = Prm.isMultiCorp();
	String app = Prm.getAppTitle();

	int pjId = Integer.parseInt(projIdS);

	projectManager pjMgr	= projectManager.getInstance();
	userManager uMgr		= userManager.getInstance();
	townManager tnMgr		= townManager.getInstance();
	eventManager evMgr		= eventManager.getInstance();
	
	int myUid = pstuser.getObjectId();
	
	String s;
	boolean bUsernameEmail = (s=Util.getPropKey("pst", "USERNAME_EMAIL"))!=null && s.equalsIgnoreCase("true");
	
	PstAbstractObject pj = pjMgr.get(pstuser, pjId);
	String pjName = ((project)pj).getDisplayName();
	String ownerName = ((user)pstuser).getFullName();
	String ownerEmail = (String)pstuser.getAttribute("Email")[0];
	String optMsg = request.getParameter("optMsg");
	
	// optional message from owner
	if (optMsg != null && optMsg.length()>0 && !optMsg.equals("null"))
	{
		optMsg = optMsg.replaceAll("\n", "<br>");
		optMsg = "<b>Message from " + ownerName + "</b>: <hr><div STYLE='font-size:12px; font-family:Courier New'><br>"
	+ optMsg + "</div><hr><br><br>";
	}
	else
		optMsg = "";
	
	if (!pj.getStringAttribute("Owner").equals(String.valueOf(myUid)) && !isProgMgr)
	{
		response.sendRedirect("../out.jsp?msg=Access declined - only project owner may change project team memberships.");
		return;
	}
	
	// get ready for sending email to new user
	String subj = "[" + app + "] " + ownerName + " sends you a project invitation";
	String msg1 = ownerName + " invites you to share a project workspace.<br>";
	msg1 += "<blockquote>";
	msg1 += "<table border='0' cellspacing='2' cellpadding='2'>";
	msg1 += "<tr><td class='plaintext' width='150'><b>Project Name</b>:</td><td class='plaintext'>" + pjName + "</td></tr>";

	// for existing member
	String msg2 = "</table></blockquote><br><br>";
	msg2 += "Click the link below and use the above username to access the project.<br>";
	msg2 += "<a href='" + NODE + "'>" + NODE + "</a><br><br>";
	msg2 += optMsg;
	msg2 += "If you have any questions, please contact CR Support at <a href='mailto:support@egiomm.com'>";
	msg2 += "support@egiomm.com</a>";
	
	// for new member
	String msg3 = "</table></blockquote><br><br>";
	msg3 += "Click the link below and use the above username and password to access the project.<br>";
	msg3 += "<a href='" + NODE + "'>" + NODE + "</a><br><br>";
	msg3 += optMsg;
	msg3 += "If you have any questions, please contact CR Support at <a href='mailto:support@egiomm.com'>";
	msg3 += "support@egiomm.com</a>";
	
	String emails = request.getParameter("shareMember").trim();
	if (emails.indexOf(';') != -1)
		emails = emails.replaceAll(";", ",");
	if (emails.indexOf("\n") != -1)
		emails = emails.replaceAll("\n", ",");
	
	town myTown = ((user)pstuser).getUserTown();
	if (myTown==null && !isMultiCorp) {
		// fix this user's record with the config company
		try {
	myTown = (town) tnMgr.get(pstuser, Prm.getCompanyName());
	s = String.valueOf(myTown.getObjectId());
	pstuser.setAttribute("Company", s);
	pstuser.setAttribute("TownID", s);
	uMgr.commit(pstuser);
	l.info("post_add_member.jsp fixed user Company for [" + myUid + "]");
		}
		catch (Exception e) {
	response.sendRedirect("../out.jsp?msg=user [" + myUid + "] doesn't have a Company. Failed to create new user.");
	return;
		}
	}
	
	String username, msg, oriUsername, userEmail=null;
	int id;
	PstAbstractObject o;
	String [] eArr = emails.split(",");
	int newMemCt=0, existingMemCt=0, rejectCt=0, guestCt=0;
	String existingNameList="", newNameList="";
	String rejMsg = "<br><br>";
	String otherMsg = "";
	boolean bAddUserAsGuest;
	boolean bEmailNotMatch, bAddPjMemberOnly;
	String firstName, lastName;
	
	// check UNICODE character
	//Pattern p = Pattern.compile("[\\p{L}/]");
	
	for (int i=0; i<eArr.length; i++)
	{
		// check to see if the email is a CR member
		// if so, add to TeamMembers, else add to Guest
		o = null;
		bEmailNotMatch = false;
		bAddPjMemberOnly = false;
		
		firstName = lastName = null;
		username = eArr[i].trim();
		
		/*
		Matcher m = p.matcher(username);
		if (m.matches()) {
	// detected unicode in username
	otherMsg += "<br>Reject [" + username + "] because UNICODE character detected";
	continue;
		}
		*/
		
		// check to see if adding this user as a guest (i.e., not company member)
		if (username.endsWith("*")) {
			bAddUserAsGuest = true;
			username = username.substring(0, username.length()-1);
		}
		else {
			bAddUserAsGuest = false;
		}
		
		if (username.length() <= 0) continue;
		try
		{
	// if it is Email, need to convert to username if !bUsernameEmail
	boolean bAtSignInUsername = false;
	
	oriUsername = username;
	int idx = username.indexOf('@');
	if (idx != -1) {
		bAtSignInUsername = true;
		// input name is in email format
		// check to see if it is in the format "Ed Lam" <xxx@mmm.com>
		int idx1, idx2;
		if ((idx1=username.indexOf('<')) != -1) {
			// has <>: extract email
			if ((idx2=username.indexOf('>')) != -1) {
				userEmail = username.substring(idx1+1, idx2);	// xxx@mmm.com
				
				// now extract the first name and last name if they exist
				if (idx1 > 0) {
					String nameStr = username.substring(0, idx1);
					if (nameStr.indexOf('"') != -1) {
						nameStr = nameStr.replaceAll("\"", "");	// "Paul Lam" -> Paul Lam
					}
					if ((idx2=nameStr.indexOf(' ')) != -1) {
						// there exist both first and last name: Paul Lam
						firstName =nameStr.substring(0,idx2);
						lastName = nameStr.substring(idx2+1);
					}
					else {
						// only First name
						firstName = nameStr;
					}
				}
				
				// now name has been extracted, the username should be the userEmail
				username = userEmail;
				idx = userEmail.indexOf('@');	// recal the position of @
			}
			else {
				// error in unmatching <>
				if (rejectCt > 0) rejMsg += ", ";
				rejMsg += oriUsername;
				rejectCt++;
				continue;
			}
		}	// END if: has angle bracket <>
		
		// now username has been stripped to contain only email address
		userEmail = username;
		int [] ids = uMgr.findId(pstuser, "Email='" + username + "'");
		if (!bUsernameEmail) {
			// but this username can be duplicate to another person
			username = username.substring(0, idx);			// strip the domain name
		}

		if (ids.length <= 0) {
			// Email address not found: might need to create this user
			
			// check for Email username if the user exist
			try {o = uMgr.get(pstuser, username);
				// existing member, just need to add project membership
				bAddPjMemberOnly = true;
			}
			catch (PmpException e) {}	// fail to get then need to create
			
			// ECC: there is a case where email is not matched but his username is already a member
			// then we throws the next PmpException, but when create with this name, it fails
			if (!bAddPjMemberOnly) {
				bEmailNotMatch = true;
				throw new PmpException("member not found - will create a new member");	// create in the code below
			}
		}
		else {
			// found existing member, use the first one that matches
			o = uMgr.get(pstuser, ids[0]);
			username = o.getObjectName();	// OMM username
		}
	}	// END if: email format input
	
	
	if (bAtSignInUsername || bAddPjMemberOnly) {
		// non-Email name: I must find this user, if not found I can't create
		// because I don't have its Email address
		if (!bAddPjMemberOnly) {
			try {o = uMgr.get(pstuser, username);}
			catch (PmpException e){
				// fail to get user, reject
				System.out.println("Fail-1 add member to project, e="+e.getMessage());
				if (rejectCt > 0) rejMsg += ", ";
				rejMsg += oriUsername;
				rejectCt++;
				continue;
			}
		}
		if (o != null)
			userEmail = o.getStringAttribute("Email");
	}
	
	if (!bAtSignInUsername && o==null) {
		// not Email format, must be username
		try {o = uMgr.get(pstuser, username);}
		catch (PmpException e){
			System.out.println("Fail-2 add member to project, e="+e.getMessage());
			if (rejectCt > 0) rejMsg += ", ";
			rejMsg += oriUsername;
			rejectCt++;
			continue;
		}
		if (o != null)
			userEmail = o.getStringAttribute("Email");
	}
	
	if (isMultiCorp) {
		// check add project limit
		try {
			if (bAddUserAsGuest) {
				throw new PmpException("Cannot add existing member as Guest.");
			}
			if (o != null) {
				town aTown = ((user)o).getUserTown();	// throw exception on invalid town
				if (aTown!=null && aTown.isReachLimit(town.MAX_PROJECT)) {
					throw new PmpException("Exceed max projects allowed for this member.");
				}
			}
		}
		catch (PmpException e) {
			if (rejectCt > 0) rejMsg += ", ";
			rejMsg += oriUsername;
			rejectCt++;
			continue;
		}
	}
	
	// add project membership
	id = o.getObjectId();
	if (!Util2.foundAttribute(pj, "TeamMembers", id))
	{
		pj.appendAttribute("TeamMembers", new Integer(id));
		existingMemCt++;
		
		if (existingNameList.length() > 0) existingNameList += ", ";
		existingNameList += username;
	}
	
	// send invitation to existing member
	msg = msg1;
	msg += "<tr><td class='plaintext' width='150'><b>Username</b>:</td><td class='plaintext'>" + username + "</td></tr>";
	msg += msg2;
	Util.sendMailAsyn(pstuser, ownerEmail, userEmail, null, null, subj, msg, MAILFILE);
		}
		catch (PmpException e)
		{
	/////////////////////////////////
	// ***** CREATE NEW USER
	// not a member, create the membership and add the user to the project
	// check create user limit for this company
	if (myTown!=null && myTown.isReachLimit(town.MAX_USER)) {
		// don't do it anymore, tell him to upgrade
		response.sendRedirect("../out.jsp?msg=5003&go=info/upgrade.jsp");
		return;
	}
	
	String newPass = Util.createPassword();	// ironman12
	o= null;
	try {o = uMgr.createUser(pstuser, username, newPass, true);}	// create user, userinfo and set up base values
	catch (PmpException ee) {
		// this create should not fail
		//ee.printStackTrace();
		if (bEmailNotMatch) {
			if (!bUsernameEmail) {
			
				// try to create user with an digit added
				int ct = 1;
				for (; ct<10; ct++) {
					username += ct;
					o = null;
					try {o = uMgr.createUser(pstuser, username, newPass, true);}
					catch (PmpException eee) {
						if (eee.getMessage().contains("Duplicate")) {
							continue;
						}
					}
					// succeeded
					if (o != null) break;
				}
			}

			else if (ee.getMessage().contains("Duplicate")) {
				// username is Email but the Email attribute not matching
				// this is the case user is using a different email addr
				System.out.println("*** duplicate member found: " + username);
				o = uMgr.get(pstuser, username);
			}
		}
		if (o == null) {
			otherMsg += "<br>Create user [" + username + "] failed but email ["
					+ userEmail + "] is not found in database.";
			continue;
		}
	}
	s = String.valueOf(myTown.getObjectId());
	o.setAttribute("Email", userEmail);							// the above call doesn't set Email right if username is not an Email
	o.setAttribute("Company", s);
	o.setAttribute("TownID", s);
	o.setAttribute("Towns", new Integer(myTown.getObjectId()));
	o.setAttribute("LastProject", projIdS);						// set last accessed project to improve his first login experience
	
	if (firstName != null) o.setAttribute("FirstName", firstName);
	if (lastName != null) o.setAttribute("LastName", lastName);
	
	// @ECC052714
	// support adding as Guest for newly created members
	if (bAddUserAsGuest) {
		// set the role to be a Guest
		o.setAttribute("Role", user.ROLE_GUEST);
		guestCt++;
	}
	uMgr.commit(o);		// commit the new user object
	
	// personal project space option
	if (!bAddUserAsGuest) {
		s = Util.getPropKey("pst", "CREATE_PERSONAL_PROJECT");
		if (s!=null && s.equalsIgnoreCase("true")) {
			project.createPersonalProject((PstUserAbstractObject) o);	// also create a person project space for him
		}
	}
	
	id = o.getObjectId();
	pj.appendAttribute("TeamMembers", new Integer(id));
	newMemCt++;
	
	if (newNameList.length() > 0) newNameList += ", ";
	newNameList += username;
	
	// send invitation to new member
	msg = msg1;
	msg += "<tr><td class='plaintext' width='150'><b>Username</b>:</td><td class='plaintext'>" + username + "</td></tr>";
	msg += "<tr><td class='plaintext' width='150'><b>Password</b>:</td><td class='plaintext'>" + newPass + "</td></tr>";
	msg += msg3;
	Util.sendMailAsyn(pstuser, ownerEmail, userEmail, null, null, subj, msg, MAILFILE);
		}
	}	// END for each user to be added
	
	if (existingMemCt>0 || newMemCt>0)
		pjMgr.commit(pj);
			
	msg = existingMemCt + " existing members and " + newMemCt + " new members added to the project.";
	if (guestCt > 0) msg += " (" + guestCt + " of them are added as guest members).";
	if (rejectCt > 0) msg += rejMsg + " got rejected because they have exceeded the no. of workspaces allowed on their subscription level.";
	msg += otherMsg;
	l.info("Added new project membership to [" + projIdS + " - " + pjName + "].  " + msg);
	
	// send notification event to all project team members
	s = "";
	if (existingMemCt > 0)
		s = existingNameList;
	if (newMemCt > 0) {
		if (s.length() > 0) s += ", ";
		s += newNameList;
	}
	if (s.length() > 0) {
		String lnkStr = "<a href='" + NODE + "/project/proj_plan.jsp?projId=" + projIdS + "'>"
				+ pjName + "</a>";

		event evt = null;
		try {
			evt = PrmEvent.create(pstuser, "509", projIdS, null, null);
			
			PrmEvent.setValueToVar(evt, "var1", s);
			PrmEvent.setValueToVar(evt, "var2", lnkStr);
			evMgr.commit(evt);
			
			// send to project members
			int [] ids = Util2.toIntArray(pj.getAttribute("TeamMembers"));
			int ct = PrmEvent.stackEvent(pstuser, ids, evt);
	    	l.info(myUid + " triggered Event [509] - add team members to "
	    			+ ct + " users for project (" + projIdS + ").");
		}
		catch (PmpException e) {
			System.out.println("error creating event [" + evt.getObjectId() + "]");
		}
	}

	response.sendRedirect("proj_profile.jsp?projId=" + projIdS
			+ "&msg=" + msg); // default
%>
