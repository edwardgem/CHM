<%
//
//	Copyright (c) 2011, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_sendAction.java
//	Author: ECC
//	Date:		05/19/2011
//	Description:	Send action reminder to relevant team members.
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "oct.util.file.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.PepCommentVector" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>
<%@ page import = "java.net.URLDecoder" %>
<%@ page import = "org.apache.log4j.Logger" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%!
	userManager uMgr = null;

	// associate an action item to a user
	void addItem(HashMap<String,ArrayList<String>> map, String uidS, String aidS)
	{
		if (uidS == null) return;
		
		ArrayList<String> aidList = map.get(uidS);
		if (aidList == null) {
			// initialize for this user
			aidList = new ArrayList<String>();
			map.put(uidS, aidList);
		}
		aidList.add(aidS);
		return;
	}
%>

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");


	// 1.  called by proj_action.jsp to send reminder on all action items selected on the page
	// 2.  called by upd_action.jsp to sendreminder to one action item

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	Logger l = PrmLog.getLog();
	String HOST = Prm.getPrmHost();
	
	String msg = "Send reminder Email to:";
	ArrayList<String> errList = new ArrayList<String>();
	errList.add(msg);
	session.setAttribute("errorList", errList);
	
	String backPage = request.getParameter("bp");
	backPage = URLDecoder.decode(backPage, "UTF-8");
	
	String projIdS = request.getParameter("projId");
	String aidS = request.getParameter("aid");		// for sending reminder on one action item only
	if (StringUtil.isNullOrEmptyString(aidS)) aidS = null;
	
	/////////////////////////
	// send reminder Email to relevant team members group by his/her items
	actionManager aMgr = actionManager.getInstance();
	projectManager pjMgr = projectManager.getInstance();
	uMgr = userManager.getInstance();
	
	String pjName = null;
	String s, pjOwnerEmail = null;
	PstAbstractObject uObj;
	
	try {
		project projObj = (project) pjMgr.get(pstuser, Integer.parseInt(projIdS));
		pjName = projObj.getDisplayName();
		s = projObj.getStringAttribute("Owner");
		uObj = uMgr.get(pstuser, Integer.parseInt(s));
		pjOwnerEmail = uObj.getStringAttribute("Email");
	}
	catch (Exception e) {
		pjOwnerEmail = pstuser.getStringAttribute("Email");
	}
	if (pjName == null) {
		// might be personal to-do
		pjName = "Personal to-do item";
	}
	
	// get one or more action items to send reminder
	int [] ids = null;
	
	if (aidS != null) {
		// for a specific action item reminder
		ids = new int[1];
		ids[0] = Integer.parseInt(aidS);
	}
	else {
		// use expr to find the list of actions
		
		// use the expression from proj_action.jsp to get the same list of action items
		String expr = (String) session.getAttribute("aiExpr");
		
		// if no remembered expression, construct an expr
		if (StringUtil.isNullOrEmptyString(expr)) {
			// get all the open/late action items of this project
			expr = "";
			if (!StringUtil.isNullOrEmptyString(projIdS))
				expr = "ProjectID='" + projIdS + "' && ";
			expr += "Type='" + action.TYPE_ACTION + "' && (Status='Open' || Status='Late')";
		}
		else {
			session.removeAttribute("aiExpr");
		}
		ids = aMgr.findId(pstuser, expr);
	}

	
	HashMap<String,ArrayList<String>> userActionMap = new HashMap<String,ArrayList<String>>(20);
	action actionObj;
	ArrayList<Object> respList;
	String actionIdS;
	
	for (int i=0; i<ids.length; i++) {
		actionObj = (action) aMgr.get(pstuser, ids[i]);
		actionIdS = String.valueOf(ids[i]);
		respList = actionObj.getAllResponsible();
		for (int j=0; j<respList.size(); j++) {
			addItem(userActionMap, (String)respList.get(j), actionIdS);
		}
	}
	

	// now I have a map of all users, each has a list of action items
	SimpleDateFormat df1 = new SimpleDateFormat("MM/dd/yy");
	String expDtS;
	StringBuffer sBufA = new StringBuffer(256);
	sBufA.append("Below are your open/late action items in the project ");
	sBufA.append("<a href='" + HOST + "/project/proj_top.jsp?projId=" + projIdS + "'>" + pjName + "</a>. ");
	sBufA.append("Please complete and close these items before the due date.");
	sBufA.append("<blockquote>");
	
	String updateLnk = HOST + "/project/proj_action.jsp?projId=" + projIdS;
	StringBuffer sBufB = new StringBuffer(256);
	sBufB.append("</blockquote><p>");
	sBufB.append("You may click the following link to blog or update the status of your action items:<br/><br/>");
	sBufB.append("<a href='" + updateLnk + "'>" + updateLnk + "</a>");
	
	String subj = "[" + Prm.getAppTitle() + "] action item reminder on (" + pjName + ")";
	for (String uidS : userActionMap.keySet()) {
		// for each user, construct a list of action item display
		StringBuffer tempBuf = new StringBuffer(512);
		tempBuf.append(sBufA);
		tempBuf.append("<table border='0' width='100%'><tr>");
		tempBuf.append("<td class='plaintext'><b>Action Item</b></td>");
		tempBuf.append("<td class='plaintext'><b>Status</b></td>");
		tempBuf.append("<td class='plaintext'><b>Priority</b></td>");
		tempBuf.append("<td class='plaintext'><b>Due Date</b></td>");
		tempBuf.append("<td class='plaintext'><b>Responsible</b></td>");
		tempBuf.append("</tr>");
		
		ArrayList<String> aidList = userActionMap.get(uidS);
		String [] aidArr = aidList.toArray(new String[0]);
		PstAbstractObject [] aObjList = aMgr.get(pstuser, aidArr);
		Util.sortDate(aObjList, "ExpireDate", false);
		
		int num = 1;
		for (PstAbstractObject aObj : aObjList) {
			actionObj = (action) aObj;
			expDtS = df1.format(actionObj.getExpireDate());
			tempBuf.append("<tr>");
			tempBuf.append("<td width='50%' valign='top'><table width='100%'><tr>");
			tempBuf.append("<td class='plaintext' width='20' valign='top'>" + num++ + ".</td>");
			tempBuf.append("<td class='plaintext' valign='top'>" + actionObj.getStringAttribute("Subject") + "</td>");
			tempBuf.append("</tr></table></td>");
			tempBuf.append("<td class='plaintext' width='10%' valign='top'>" + actionObj.getStatusDisplay(pstuser) + "</td>");
			tempBuf.append("<td class='plaintext' width='15%' valign='top'>" + actionObj.getStringAttribute("Priority") + "</td>");
			tempBuf.append("<td class='plaintext' width='15%' valign='top'>" + expDtS + "</td>");
			tempBuf.append("<td class='plaintext' width='25%' valign='top'>"
							+ actionObj.getResponsibleStr(pstuser) + "</td>");
			tempBuf.append("</tr>");
		}
		tempBuf.append("<tr><td class='plaintext' colspan='4'><img src='"
							+ HOST + "/i/spacer.gif' height='20' width='1'/>");
		tempBuf.append("* = Coordinator of the action item.</td></tr>");
		tempBuf.append("</table>");
		tempBuf.append(sBufB);
		
		// ready to send Email to this user
		if (!Util.sendMailAsyn(pstuser, pjOwnerEmail, uidS, null, null, subj, tempBuf.toString(), "alert.htm")) {
			l.error("Error sending reminder message in post_sendAction.jsp.");
		}
		
		uObj = uMgr.get(pstuser, Integer.parseInt(uidS));
		msg = "- " + ((user)uObj).getFullName() + " (" + aObjList.length + " items)";
		errList.add(msg);
	}	// END: for each relevant user
	
	if (errList.size() <= 1) errList.add("None");

	l.info("Send reminder email to " + userActionMap.size() + " users.");
	response.sendRedirect(backPage);

%>

