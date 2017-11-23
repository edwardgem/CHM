<%@ page import = "oct.pst.PstUserAbstractObject" %>
<%@ page import = "oct.pst.PstGuest" %>
<%@ page import="util.StringUtil"%>
<%@ page import="java.util.HashMap"%>
<%@ page import="util.Prm"%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>

<link href="../in/tab.css" rel="stylesheet" type="text/css" media="screen">

<%
	boolean isPRM = Prm.isPRM();
	boolean isMeetWE = Prm.isMeetWE();
	boolean isCtModule = Prm.isCtModule(session);
	boolean isCwModule = Prm.isCwModule(session);
	
	String cat = request.getParameter("cat");
	String subcat = request.getParameter("subCat");

	// check user locale if login
	String locale = null;
	if (session!=null) {
		locale = (String) session.getAttribute("locale");
	}

	int iRoleType = 0;
	String roleType = request.getParameter("roleType");
	if (roleType != null)
		iRoleType = Integer.parseInt(roleType);

	
	int iBlogType = 0;
	String blogType = request.getParameter("blogType");
	if (blogType != null)
		iBlogType = Integer.parseInt(blogType);
	
	String projIdS = request.getParameter("projId");
	String taskIdS = request.getParameter("taskId");
	
	if (!StringUtil.isNullOrEmptyString(projIdS) && !projIdS.equals("0") && subcat.equals("NewChange")) {
		subcat = "";	// for tracker: this is update CR, not new CR
	}

	String linkS;
	int topArrIdx = 0;
	String rightMenuItems = "MyAccount;Logout";
	boolean bFloatRight;

	///////////////////////////////////////////////////////////////////////////////////
	// Main Menu
	String[] topArr;
	if (isCtModule) topArr = Prm.topArrCT;
	else if (isMeetWE) topArr = Prm.topArrOMF;
	else topArr = Prm.topArrDefault;
	
	out.println("<div id='topnav' style='white-space:nowrap;'>");
	out.print("<ul>");
	for (int i = 0; i < topArr.length; i++) {
		linkS = Prm.linkMap.get(topArr[i]);
		if (linkS == null)
			continue; // this module link is not supported by this deployment

		if (rightMenuItems.contains(topArr[i])) {
			bFloatRight = true;
			out.print("<li style='float:right;width:110px;text-align:center'><a href='" + linkS + "' ");
		}
		else {
			bFloatRight = false;
			out.print("<li style='width:120px;'><a href='" + linkS + "' ");
		}
		if (cat.equalsIgnoreCase(topArr[i])) {
			out.print("class='here'");
			topArrIdx = i;
		}
		out.print(">" + StringUtil.getLocalString(StringUtil.TYPE_LABEL, locale, topArr[i]) + "</a></li>");
		out.print("<li class='gap'");
		if (bFloatRight) {
			out.print(" style='float:right;'");
		}
		out.print("><img src='../i/spacer.gif' width='3' height='1'/></li>"); // gap between tabs
	}
	
	out.print("</ul><br /></div>");

	out.print("<div class='rule'></div>");

	
	///////////////////////////////////////////////////////////////////////////////////
	// Sub-Menu
	
	String[] thisSubArr;
	if (isMeetWE) {
		if (!cat.equals("Home")) {
			thisSubArr = Prm.subArrOMF[topArrIdx];
		}
		else {
			if (iRoleType != 1) iRoleType = 0;	// only support admin(1) and non-admin
			thisSubArr = Prm.homeSubArrByRoleOMF[iRoleType];
		}
	}
	else
		thisSubArr = Prm.subArrDef[topArrIdx];
	
	if (!isMeetWE) {
		if (cat.equals("Home")) {
			thisSubArr = Prm.homeSubArrByRole[iRoleType];
		}
		else if (blogType != null) {
			// use blogType to decide on sub-menu
			thisSubArr = Prm.projSubArrByBlogType[iBlogType];
			// adjust subCat
			switch (iBlogType) {
				case 0: subcat = "ProjectBlog"; break;
				case 1: subcat = "TaskBlog"; break;
				case 2: subcat = "BugBlog"; break;
				case 3: subcat = "ActionBlog"; break;
				case 4: subcat = "MeetingBlog"; break;
			}
		}
		else if (cat.equals("Tracker")) {
			if (projIdS==null || projIdS.equals("0")) {
				thisSubArr = Prm.trackerSubArr[0];
			}
		}
		else if (cat.equals("Event")) {
			thisSubArr = Prm.evtSubArrByRole[iRoleType];	// support 0 or 1
		}
	}
		
	String localString;
	if (subcat != null && thisSubArr != null) {
		out.println("<div id='subnav' style='white-space:nowrap;'>");
		out.print("<ul>");
		for (int i = 0; i < thisSubArr.length; i++) {
			linkS = Prm.linkMap.get(thisSubArr[i]);
			if (linkS == null) {
				continue; // this module link is not supported by this deployment
			}
				
			// parameters
			if (projIdS != null) {
				linkS = linkS.replace("$projId", projIdS);			
			}
			if (taskIdS != null) {
				linkS = linkS.replace("$taskId", taskIdS);
			}

			localString = StringUtil.getLocalString(
					StringUtil.TYPE_LABEL, locale, thisSubArr[i]);
			out.print("<li>");			
			if (thisSubArr[i].equalsIgnoreCase(subcat)) {
				out.print("<a href='#' class='here'>");
				out.print("&nbsp;&nbsp;<u>" + localString + "</u>");
			} else {
				out.print("<a href='" + linkS + "'>" + localString);
			}
			out.print("</a></li>");
		}
		out.print("</ul><br /></div>");
	}
%>

