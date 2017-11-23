////////////////////////////////////////////////////
//	Copyright (c) 2010, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	Prm.java
//	Author:	ECC
//	Date:	2/25/10
//	Description:
//		PRM constants.  To use this class, you must first initialize it by calling setInitParameters().
//
////////////////////////////////////////////////////////////////////

package util;

import java.util.HashMap;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import oct.codegen.user;
import oct.codegen.userManager;
import oct.pst.PstGuest;
import oct.pst.PstUserAbstractObject;

import org.apache.log4j.Logger;

public class Prm {
	public static final String DARK		= "bgcolor='#F5F5F5'";
	public static final String LIGHT	= "bgcolor='#FFFFFF'";
	
	public static final String [] ALL_AVAILABLE_MODULES		= {"Blog", "CT", "CW"};
	
	private static final String MAILFILE = "alert.htm";
	
	private static String app;
	private static String appTitle;
	private static String host;
	private static String resource_path;		// RESOURCE_FILE_PATH
	private static String upload_path;			// FILE_UPLOAD_PATH
	private static String tabFilename;			// Menu tab file
	private static String fromEmail;
	private static String egiEmail;
	private static String companyName;			// for non-multi-corp
	private static String siteDefaultFirstPage;
	
	private static boolean isCR = false;
	private static boolean isOMF = false;
	private static boolean isMeetWE = false;
	private static boolean isPRM = false;

	private static boolean isMultiCorp = false;
	
	// optional app modules
	private static boolean isBlogModule	= false;
	private static boolean isCtModule	= false;
	private static boolean isCwModule	= false;
	
	private static boolean isSecureHost = false;	// if the App deployment use https
	
	private static String projPlanLabel = null;
	private static user jwu = null;

	private static Logger l;

	public static void setInitParameters() throws Exception
	{
		if (jwu != null) return;		// already initialized
		
		l = PrmLog.getLog();
		String s;
		
		app = Util.getPropKey("pst", "APPLICATION");
		if (app == null) {
			String msg = "APPLICATION key is not set in PST properties.";
			l.error(msg);
			throw new Exception(msg);
		}
		appTitle = app;					// default to the same label except for MeetWE and CPM, see below
		
		// get default special user
		if (jwu == null)
		{
			PstUserAbstractObject gUser = (PstUserAbstractObject) PstGuest.getInstance();
			String spec_uname = Util.getPropKey("pst", "PRIVILEGE_USER");
			String spec_passwd = Util.getPropKey("pst", "PRIVILEGE_PASSWD");
			jwu = (user)userManager.getInstance().login(gUser, spec_uname, spec_passwd);
		}
		
		// HOST
		host = Util.getPropKey("pst", "PRM_HOST");
		
		// Secure host
		isSecureHost = (s = Util.getPropKey("pst", "SECURE_HOST"))!=null
						&& s.equalsIgnoreCase("true");
		
		// APP related booleans

		if (app.indexOf("CR") != -1) {
			isCR = true;
		}
		if (app.indexOf("OMF") != -1) {
			isOMF = true;
		}
		
		if (app.equals("OMF")) {
			isMeetWE = true;
			appTitle = "MeetWE";
		}
		else if (app.equals("PRM")) {
			isPRM = true;
			appTitle = "CPM";
		}
		tabFilename = "tab_prm.jsp";
		tabFilename = "../in/" + tabFilename;	// it has to be relative path for jsp:include to work

		// Multiple company
		s = Util.getPropKey("pst", "MULTICORPORATE");
		if (s!=null && s.equalsIgnoreCase("true"))
			isMultiCorp = true;
		
		// company name on config file (needed for non-multi-company)
		companyName = Util.getPropKey("pst", "COMPANY_NAME");

		// Modules
		s = Util.getPropKey("pst", "MODULE");
		if (s == null) s = "";
		else s = s.toLowerCase();
		if (!isPRM && s.contains("blog")) {
			isBlogModule = true;
			projPlanLabel = "Project Blog";
		}
		else {
			projPlanLabel = "Project Plan";
		}
		
		if (s.contains("ct")) {
			isCtModule = true;
		}
		
		if (s.contains("cw")) {
			isCwModule = true;
		}
		
		// file path
		resource_path = Util.getPropKey("pst", "RESOURCE_FILE_PATH");
		upload_path = Util.getPropKey("pst", "FILE_UPLOAD_PATH");
		
		// FROM email
		fromEmail = Util.getPropKey("pst", "FROM");
		egiEmail  = Util.getPropKey("pst", "EGI_EMAIL");
		if (StringUtil.isNullOrEmptyString(egiEmail)) {
			egiEmail = Util.getPropKey("pst", "ADMIN_EMAIL");
		}
		
		// site wide default first page, user preference will override this
		siteDefaultFirstPage = Util.getPropKey("pst", "DEFAULT_FIRST_PAGE");
		
		// prepare tab menu
		initTabMenu();
	}

	public static boolean isPDA(HttpServletRequest req)
	{
		String browserType = req.getHeader("User-Agent").toLowerCase();
		return (browserType.contains("android")
				|| browserType.contains("iphone")
				|| browserType.contains("mobile")
				|| browserType.contains("blackberry"));
	}
	
	public static boolean isCtModule(HttpSession sess)
	{
		if (isCtModule) return true;
		String modOption = (String)sess.getAttribute("app");
		if (modOption!=null && modOption.contains("CT")) return true;
		return false;
	}
	
	public static boolean isCwModule(HttpSession sess)
	{
		if (isCwModule) return true;
		String modOption = (String)sess.getAttribute("app");
		if (modOption!=null && modOption.contains("CW")) return true;
		return false;
	}
	
	public static void sendEgiEmail(String msg)
	{
		// send email to lab
		if (StringUtil.isNullOrEmptyString(egiEmail))
			return;
		
		String subj = "[" + companyName + "] Mail from (" + app + ")";
		if (!Util.sendMailAsyn(fromEmail, egiEmail, null, null,
				subj, msg, MAILFILE)) {
			l.error("!!! Error sending " + app + " Email at sendEgiEmail()");
		}
	}

	public static String getApp() {return app;}
	public static String getAppTitle() {return appTitle;}
	public static String getResourcePath() {return resource_path;}
	public static String getUploadPath() {return upload_path;}
	public static String getTabFile() {return tabFilename;}
	public static String getFromEmail() {return fromEmail;}
	
	public static user getSpecialUser() {return jwu;}
	
	public static boolean isCR() {return isCR;}
	public static boolean isOMF() {return isOMF;}
	public static boolean isMeetWE() {return isMeetWE;}
	public static boolean isPRM() {return isPRM;}

	public static boolean isBlogModule() {return isBlogModule;}
	public static boolean isCtModule() {return isCtModule;}
	public static boolean isCwModule() {return isCwModule;}

	public static boolean isMultiCorp() {return isMultiCorp;}
	
	public static boolean isSecureHost() {return isSecureHost;}

	public static String getProjectPlanLabel() {return projPlanLabel;}
	
	public static String getPrmHost() {return host;}
	
	public static String getCompanyName() {return companyName;}
	
	public static String getSiteDefFirstPage() {return siteDefaultFirstPage;}
	
	
	/*****************************************************************************************
	 * Initialize Tab Menu
	 */
	
	public static HashMap<String, String> linkMap = new HashMap<String, String>(40);

	// contents of these arrays are keys in label.csv
	
	///////////////////////////////
	// TOP MENU
	// the float right items must be in reverse order
	public static final String[] topArrDefault = { "Home", "Project", "File", "Event", "Logout", "", "MyAccount" };
	public static final String[] topArrCT = { "Home", "Project", "File", "Event", "Tracker", "Logout", "MyAccount" };
	public static final String[] topArrOMF = { "Home", "Event", "Network", "Logout", "MyAccount" };

	///////////////////////////////
	// SUB MENU
	// default sub-menu (PRM)
	public static final String[][] subArrDef = {
			{ "SubHome", "Dashboard", "ChatRoom", "Search", "eLogBook" },	// Home
			{ "Top", "ProjectPlan", "ProjectProfile", "ProjectBlog", "ProjectSummary", "Worktray", "Todo", "ChangeProjPlan", "ProjectReport" },	// Project
			{ "Top", "FileRepository", "ProjectProfile", "ChangeFolderPlan" },	//File
			{ "Calendar", "ProjectMeeting", "SearchMeeting", "NewMeeting", "NewEvent" },	// Meeting
			{ "ChangeSummary", "NewChange", "CRAnalysis"},	// Tracker
			{ },	// Logout
			{ "UserAccount", "MyNote", "DistList" }		// My Account
	};
	
	// default sub-menu (MeetWE)
	public static final String[][] subArrOMF = {
		{ "Home", "Search", "MyPage", "MyNote", "MyLetter" },	// Home
		{ "Calendar", "SearchMeeting", "NewMeeting", "NewEvent", "NewQuestion" },	// Meeting
		{ "Contacts", "Circle", "NewCircle", "SearchFriend", "InviteFriend", "Guest"},	// Network
		{ },	// Logout
		{ "UserAccount" }	// My Account
	};
	
	public static final String [][] homeSubArrByRole = {
			// 0: regular role
			subArrDef[0], 	// default
			// 1: admin
			{ "SubHome", "Dashboard", "ChatRoom", "Search", "eLogBook", "NewUser", "NewProject", "NewCompany", "Admin" },
			// 2: program manager
			{ "SubHome", "Dashboard", "ChatRoom", "Search", "eLogBook", "NewUser", "NewProject" },
	};
	
	public static final String [][] homeSubArrByRoleOMF = {
			// 0: regular role
			subArrOMF[0], 	// default
			// 1: admin
			{ "Home", "Search", "MyPage", "MyNote", "NewUser", "Admin" },
	};
	
	public static final String [][] evtSubArrByRole = {
			// 0: regular role
			subArrDef[3], 	// default for event
			// 1: admin or PM
			{ "Calendar", "ProjectMeeting", "SearchMeeting", "NewMeeting", "NewEvent", "NewQuestion" },
	};
	
	public static final String [][] projSubArrByBlogType = {
			// 0:project blog
			subArrDef[1], 	// default
			// 1:task blog
			{ "Top", "ProjectPlan", "ProjectProfile", "TaskManagement", "TaskBlog", "ProjectBlog" },
			// 2:bug blog
			{ "Top", "ProjectPlan", "ChangeSummary", "ChangeBlog", "ProjectBlog" },
			// 3:action blog
			{ "Top", "ProjectPlan", "ProjectAction", "ActionBlog", "ProjectBlog" },
			// 4:meeting blog
			{ "Top", "ProjectPlan", "MeetingAction", "MeetingIssue", "MeetingBlog", "ProjectBlog" }
	};
	
	// based on projId
	public static final String [][] trackerSubArr = {
			// 0:no projId, no analysis sub-menu
			{ "ChangeSummary", "NewChange" },
			// 1: with projId
			{ "ChangeSummary", "NewChange", "CRAnalysis" }
	};

	private static void initTabMenu()
	{
		String projectPage;
		if (isPRM)
			projectPage = "proj_top.jsp";		// ../blog/blog_task.jsp
		else
			projectPage = "cr.jsp";

		// links
		linkMap.put("Home", "../ep/ep_home.jsp");
		linkMap.put("Project", "../project/" + projectPage);
		linkMap.put("Event", "../meeting/cal.jsp");
		linkMap.put("MyAccount", "../ep/ep1.jsp");
		linkMap.put("Logout", "../logout.jsp");

		if (isPRM) {
			// File TAB only for PRM
			linkMap.put("File", "../project/cr.jsp");
			linkMap.put("SubHome", "../ep/ep_prm.jsp");	// classic home
			linkMap.put("ChatRoom", "../ep/ep_chat.jsp");
		}
		else {
			linkMap.put("SubHome", "../ep/ep_home.jsp");
		}
		linkMap.put("Tracker", "../bug/bug_search.jsp");

		// sub-link
		linkMap.put("Dashboard", "../ep/ep_db.jsp?full=1");
		linkMap.put("Search", "../ep/search.jsp");
		linkMap.put("NewUser", "../admin/adduser.jsp");
		linkMap.put("NewProject", "../project/proj_new1.jsp");
		linkMap.put("FileRepository", "../project/cr.jsp");
		linkMap.put("ProjectPlan", "../project/proj_plan.jsp");
		linkMap.put("ProjectSummary", "../project/proj_summary.jsp");
		linkMap.put("ProjectProfile", "../project/proj_profile.jsp");
		linkMap.put("ProjectBlog", "../blog/blog_task.jsp?projId=$projId");
		linkMap.put("TaskBlog", "#");		// can only display the same page
		linkMap.put("ChangeBlog", "#");		// can only display the same page
		linkMap.put("ActionBlog", "#");		// can only display the same page
		linkMap.put("MeetingBlog", "#");		// can only display the same page
		linkMap.put("ChangeSummary", "../bug/bug_search.jsp");
		linkMap.put("Calendar", "../meeting/cal.jsp");
		linkMap.put("SearchMeeting", "../meeting/mtg_search.jsp");
		linkMap.put("NewMeeting", "../meeting/mtg_new1.jsp");
		linkMap.put("NewEvent", "../question/q_new1.jsp?Qtype=event");
		linkMap.put("NewQuestion", "../question/q_new1.jsp?Qtype=quest");
		linkMap.put("UserAccount", "../ep/ep1.jsp");
		linkMap.put("NewChange", "../bug/bug_update.jsp");
		linkMap.put("CRAnalysis", "../bug/bug_analysis.jsp?projId=$projId");
		linkMap.put("ChangeFolderPlan", "../plan/updplan.jsp?projId=$projId");
		linkMap.put("ChangeProjPlan", "../plan/updplan.jsp?projId=$projId");
		linkMap.put("Admin", "../admin/admin.jsp");
		linkMap.put("TaskManagement", "../project/task_update.jsp?projId=$projId&taskId=$taskId");
		linkMap.put("ProjectReport", "../project/report.jsp?projId=$projId");
		linkMap.put("Todo", "../project/proj_action.jsp?projId=$projId");
		linkMap.put("ProjectMeeting", "../meeting/meeting.jsp");
		
		
		if (isMultiCorp) {
			linkMap.put("NewCompany", "../admin/comp_new.jsp");
		}
		else if (isPRM) {
			linkMap.put("DistList", "../ep/dl.jsp");
		}

		if (isPRM) {
			linkMap.put("eLogBook", "../ep/logbook.jsp");
			linkMap.put("Top", "../project/proj_top.jsp?projId=$projId&top=1");
		}
		else if (isMeetWE) {
			linkMap.put("Network", "../network/contacts.jsp");
			linkMap.put("MyPage", "../ep/my_page.jsp");
			linkMap.put("MyNote", "../ep/my_page.jsp?type=note");
			linkMap.put("MyLetter", "../memo/my_memo.jsp");
			linkMap.put("Contacts", "../network/contacts.jsp");
			linkMap.put("Circle", "../network/circles.jsp");
			linkMap.put("NewCircle", "../ep/cir_update.jsp");
			linkMap.put("SearchFriend", "../ep/add_contact.jsp");
			linkMap.put("InviteFriend", "../ep/add_contact.jsp?type=case2&action=invite");
			linkMap.put("Guest", "../ep/dl.jsp");
		}
		if (isCwModule) {
			linkMap.put("Worktray", "../box/worktray.jsp?projId=$projId");
		}
	}
}
