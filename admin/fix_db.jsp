<%
//
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	fix_db.java
//	Author: ECC
//	Date:		04/15/2004
//	Description:	temp tool to fix the database.
//	Modification:
//		@041504ECC	First fix of db: add ProjectID to task.
//		@AGQ022406	Patch distribution list
//		@AGQ051106	Changed PhaseNumber to Integer
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "main.PrmArchive" %>
<%@ page import = "oct.util.file.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>
<%@ page import = "org.apache.soap.util.mime.ByteArrayDataSource" %>
<%@ page import = "org.jfree.chart.ChartFactory" %>
<%@ page import = "org.jfree.chart.ChartUtilities" %>
<%@ page import = "org.jfree.chart.JFreeChart" %>
<%@ page import = "org.jfree.data.general.DefaultPieDataset" %>
<%@ page import = "org.jfree.chart.plot.PiePlot" %>
<%@ page import = "javax.activation.DataSource" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />


<%
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ((pstuser instanceof PstGuest) || ((iRole & user.iROLE_ADMIN) == 0) )
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}

	// do this for all projects in the database

	userManager uMgr		= userManager.getInstance();
	projectManager pjMgr	= projectManager.getInstance();
	planManager plMgr		= planManager.getInstance();
	planTaskManager ptMgr	= planTaskManager.getInstance();
	taskManager tkMgr		= taskManager.getInstance();
	userinfoManager uiMgr	= userinfoManager.getInstance();
	memoManager mMgr		= memoManager.getInstance();
	resultManager rMgr		= resultManager.getInstance();
	latest_resultManager lrMgr	= latest_resultManager.getInstance();
	meetingManager mtgMgr	= meetingManager.getInstance();
	actionManager aMgr		= actionManager.getInstance();
	attachmentManager attMgr	= attachmentManager.getInstance();
	bugManager bMgr			= bugManager.getInstance();
	townManager tnMgr		= townManager.getInstance();
	chatManager cMgr		= chatManager.getInstance();
	eventManager eMgr		= eventManager.getInstance();
	questManager qMgr		= questManager.getInstance();
	PstFlowStepManager fsMgr= PstFlowStepManager.getInstance();
	PstFlowManager fMgr		= PstFlowManager.getInstance();
	projTemplateManager pjtMgr = projTemplateManager.getInstance();

	Date today = Util.getToday();
	Date now = new Date();
	String s;
	String [] sa;
	String [] saa;
	int [] ids;
	int [] ids1;
	PstAbstractObject o, oo;
	Object [] oArr;
	PstManager mgr;
	Object bTextObj;
	String bText;
	Integer io;

	/////////////////////////////////////////////////////////////
	// PROJECT

	// add projId to tasks
	// project (TownID)
	// plan (ProjectID)
	// planTask (PlanID)
	/*int [] pjIds = pjMgr.findId(pstuser, "om_acctname='%'");
	for (int i=0; i<pjIds.length; i++)
	{
		String pjIdS = String.valueOf(pjIds[i]);
		System.out.println("Processing project "+pjIdS);

		// get the plans
		int [] planIds =  plMgr.findId(pstuser, "ProjectID='"+pjIdS+"'");
		for (int j=0; j<planIds.length; j++)
		{
	System.out.println("   plan id: "+planIds[j]);

	// get the planTasks
	int [] ptaskIds = ptMgr.findId(pstuser, "PlanID='"+planIds[j]+"'");
	for (int k=0; k<ptaskIds.length; k++)
	{
		// use planTask to get the TaskID
		planTask ptask = (planTask)ptMgr.get(pstuser, ptaskIds[k]);
		String taskIdS = (String)ptask.getAttribute("TaskID")[0];

		task tk = (task)tkMgr.get(pstuser, taskIdS);	// task use id as name
		System.out.println("   updating task: "+tk.getObjectId());
		tk.setAttribute("ProjectID", pjIdS);
		tkMgr.commit(tk);
	}
		}
	}*/

	/////////////////////////////////////////////////////////////
	// USER

	// add people to a certain town
/*	int [] uids = uMgr.findId(pstuser, "Towns=31552 || Towns=29594 || Towns=29307");
	for (int i=0; i<uids.length; i++)
	{
		user u = (user)uMgr.get(pstuser, uids[i]);
		u.appendAttribute("Towns", new Integer(30759));
		uMgr.commit(u);
	}
*/
/*
	// fix user attributes
	int [] uids = uMgr.findId(pstuser, "om_acctname='%'");
	for (int i=0; i<uids.length; i++)
	{
		user u = (user)uMgr.get(pstuser, uids[i]);
		String supervisor = (String)u.getAttribute("Supervisor1")[0];
		if (supervisor != null)
		{
	// change name to id
	int id = uMgr.get(pstuser, supervisor).getObjectId();
	u.setAttribute("Supervisor1", String.valueOf(id));
	uMgr.commit(u);
	System.out.println("fixed " + uids[i]);
		}
	}
*/

	/////////////////////////////////////////////////////////////
	// USERINFO
	// fix the userinfo LastLogin
/*
	// update userinfo
	int [] uids = uMgr.findId(pstuser, "om_acctname='%'");
	for (int i=0; i<uids.length; i++)
	{
		userinfo ui = null;
		try
		{
	ui = (userinfo)uiMgr.get(pstuser, String.valueOf(uids[i]));

	ui.setAttribute("Preference", "BlogCheck:Mon");
	uiMgr.commit(ui);
	System.out.println("updated userinfo for "+uids[i]);
		}
		catch (Exception e)
		{
	// assume not found, create it
	System.out.println("userinfo not found for "+uids[i]);
		}
	}
*/

	/////////////////////////////////////////////////////////////
	// TASK & PLANTASK
/*
	// update task attribute
	// make sure task has expiration date
	int [] tkIds = tkMgr.findId(pstuser, "om_acctname='%'");
	for (int i=0; i<tkIds.length; i++)
	{
		task tk = (task)tkMgr.get(pstuser, tkIds[i]);
		//tk.setAttribute("Alert", null);
		//tk.setAttribute("AlertCondition", null);
		//tk.setAttribute("AlertMessage", null);
		Date expDate = null;
		if (tk.getAttribute("ExpireDate")[0] == null)
		{
	// get the planTask
	int [] ptids = ptMgr.findId(pstuser, "(TaskID='" + tk.getObjectId() + "') && (Status!='Deprecated')");
	if (ptids.length <=0)
	{
		System.out.println("deleted "+tk.getObjectId());
		tkMgr.delete(tk);
		continue;
	}
	planTask pt = (planTask)ptMgr.get(pstuser, ptids[0]);		// there should be exactly one
	String parentIdS = (String)pt.getAttribute("ParentID")[0];
	if (parentIdS != null)
	{
		pt = (planTask)ptMgr.get(pstuser, parentIdS);
		String tkId = (String)pt.getAttribute("TaskID")[0];
		if (tkId != null)
		{
	task t = (task)tkMgr.get(pstuser, tkId);
	expDate = (Date)t.getAttribute("ExpireDate")[0];
		}
	}
	if (expDate == null)
	{
		// whatever the reason, simply use project expiration date
		project pj = (project)pjMgr.get(pstuser, Integer.parseInt((String)tk.getAttribute("ProjectID")[0]));
		expDate = (Date)pj.getAttribute("ExpireDate")[0];
	}

	tk.setAttribute("ExpireDate", expDate);
	tkMgr.commit(tk);
	System.out.println("processed " + tkIds[i]);
		}
	}
*/
/*
	// update task dates: set startDate and actualStartDate, use createDate if there is none
	int [] tkIds = tkMgr.findId(pstuser, "om_acctname='%'");
	boolean bUpd;
	int i;
	for (i=0; i<tkIds.length; i++)
	{
		task tk = (task)tkMgr.get(pstuser, tkIds[i]);
		bUpd = false;
		Date createDate = (Date)tk.getAttribute("CreatedDate")[0];
		if (tk.getAttribute("StartDate")[0] == null)
		{
	tk.setAttribute("StartDate", createDate);
	bUpd = true;
		}
		if (!tk.getAttribute("Status")[0].equals("New") && tk.getAttribute("EffectiveDate")[0]==null)
		{
	tk.setAttribute("EffectiveDate", (Date)tk.getAttribute("StartDate")[0]);
	bUpd = true;
		}
		if (bUpd)
		{
	tkMgr.commit(tk);
	System.out.println("Updated task [" + tk.getObjectId() + "]");
		}
	}
	System.out.println("A total of " + i + " tasks are updated");
*/
/*
	// delete planTask that doesn't have a corresponding task
	int [] ptIds = ptMgr.findId(pstuser, "om_acctname='%'");
	for (int i=0; i<ptIds.length; i++)
	{
		planTask pt = (planTask)ptMgr.get(pstuser, ptIds[i]);
		try
		{
	task tk = (task)tkMgr.get(pstuser, (String)pt.getAttribute("TaskID")[0]);
		}
		catch (PmpException e)
		{
	// failed to find task, delete the planTask
	ptMgr.delete(pt);
	System.out.println("Deleted planTask: "+ptIds[i]);
		}
	}
*/
/*
	// delete alerts
	int [] ids = rMgr.findId(pstuser, "Type='Alert'");
	Date dt;
	for (int i=0; i<ids.length; i++)
	{
		rMgr.delete(rMgr.get(pstuser, ids[i]));
		System.out.println("deleted alert: "+ids[i]);
	}
*/
/*
	// re-evaluate all task status (should be a permanent admin function)
	// should be called after admin update task dates
	//int [] tkIds = tkMgr.findId(pstuser, "om_acctname='%'");
	int [] tkIds = tkMgr.findId(pstuser, "ProjectID='63530'");
	Date startD, expireD, actualD, completeD;
	Date now = new Date();
	String st, newSt = null;
	boolean updated;
	for (int i=0; i<tkIds.length; i++)
	{
		updated = false;
		task tk = (task)tkMgr.get(pstuser, tkIds[i]);
		st = (String)tk.getAttribute("Status")[0];
		startD = (Date)tk.getAttribute("StartDate")[0];
		expireD = (Date)tk.getAttribute("ExpireDate")[0];
		actualD = (Date)tk.getAttribute("EffectiveDate")[0];
		completeD = (Date)tk.getAttribute("CompleteDate")[0];

		if (!st.equals(task.ST_CANCEL) && !st.equals(task.ST_ONHOLD))
		{
	if (startD==null)
	{
		if (!st.equals(task.ST_NEW))
		{
	newSt = task.ST_NEW;
	tk.setAttribute("EffectiveDate", null);
	tk.setAttribute("CompleteDate", null);
	updated = true;
		}
	}
	else if (completeD != null)
	{
		if(!st.equals(task.ST_COMPLETE))
		{
	newSt = task.ST_COMPLETE;
	updated = true;
		}
	}
	else if (expireD!=null && expireD.before(today))
	{
		if(!st.equals(task.ST_LATE))
		{
	newSt = task.ST_LATE;
	updated = true;
		}
	}
	else if (startD.after(today) && actualD==null)
	{
		if (!st.equals(task.ST_NEW))
		{
	newSt = task.ST_NEW;
	updated = true;
		}
	}
	else if (actualD!=null)
	{
		if (!st.equals(task.ST_OPEN))
		{
	newSt = task.ST_OPEN;
	updated = true;
		}
	}
	else if (expireD!=null && !expireD.before(today) && st.equals(task.ST_LATE))
	{
		if (actualD != null)
	newSt = task.ST_OPEN;	// reopen
		else
	newSt = task.ST_NEW;	// not started
		updated = true;
	}
		}
		if (updated)
		{
	tk.setAttribute("Status", newSt);
	tk.setAttribute("LastUpdatedDate", now);
	tkMgr.commit(tk);
	System.out.println("Fixed status: move task [" + tkIds[i] + "] to " + newSt);
		}
	}
*/

	/////////////////////////////////////////////////////////////
	// BLOGS & RESULTS
/*
	// clean up blogs (take out extra space lines)
	ids = rMgr.findId(pstuser, "type='Bug'");
	for (int i=0; i<ids.length; i++)
	{
		result r = (result)rMgr.get(pstuser, ids[i]);
		Object bTextObj = r.getAttribute("Comment")[0];
		String bText = (bTextObj==null)?"":new String((byte[])bTextObj);
		if (bText.length() > 0)
		{
	bText = bText.replaceAll("<p>&nbsp;</p>", "");
	r.setAttribute("Comment", bText.getBytes());
	rMgr.commit(r);
	System.out.println("cleaned blog (" + ids[i] + ")");
		}
	}
*/
	// clean up latest result
/*	ids = lrMgr.findId(pstuser, "om_acctname='%'");
	for (int i=0; i<ids.length; i++)
	{
		latest_result lr = (latest_result)lrMgr.get(pstuser, ids[i]);

		String S = "";		// plural?
		String idS = (String)lr.getAttribute("TaskID")[0];	// task or bug id
		// with the task or bug, get the last blog
		int ids2 [] = rMgr.findId(pstuser, "TaskID='" + idS + "' && Type='Task'");
		if (ids2.length > 0)
		{
	Arrays.sort(ids2);
	result r = (result)rMgr.get(pstuser, ids2[ids2.length-1]);
	ids2 = rMgr.findId(pstuser, "ParentID='"+r.getObjectId()+ "'");
	int commentNum = ids2.length;
	if (commentNum > 1) S = "s";
	Object bTextObj = r.getAttribute("Comment")[0];
	s = (bTextObj==null)?"":new String((byte[])bTextObj);
	if (s.length() > 300) s = s.substring(0,300);
	s = s.replaceAll("<\\S[^>]*>", "");		// strip HTML tag
	s = s.replaceAll("&nbsp;", " ");		// replace &nbsp;
	if (s.length() > 60) s = s.substring(0,60);
	s += " ... (" + commentNum + " comment" +S+ ")";
	lr.setAttribute("LastComment", s);
	lrMgr.commit(lr);
	System.out.println("fixed latest_comment " + ids[i]);
		}
		else
	lrMgr.delete(lr);
	}
*/
	/////////////////////////////////////////////////////////////
	// MEETING
/*
	// fix meeting: remove Sat/Sun and connect Fri with Mon
	Calendar cal = Calendar.getInstance();
	meeting mtg = (meeting)mtgMgr.get(pstuser, 57215);
	int delNum = 12;			// total to be deleted
	String [] sa;

	boolean noMore = false;
	while (true)
	{
		s = (String)mtg.getAttribute("Recurring")[0];
		sa = s.split(meeting.DELIMITER);

		if (sa.length<3)
	break;

		String recur = sa[0];
		int num = Integer.parseInt(sa[1]) - delNum;
		String nxtId = sa[2];

		Date dt = (Date)mtg.getAttribute("StartDate")[0];
		cal.setTime(dt);
		int d = cal.get(Calendar.DAY_OF_WEEK);
		if (d == Calendar.FRIDAY)
		{
	while (true)
	{
		if (noMore)
		{
	s = recur + meeting.DELIMITER + 0;
	mtg.setAttribute("Recurring", s);
	mtgMgr.commit(mtg);
	break;
		}
		meeting m1 = (meeting)mtgMgr.get(pstuser, nxtId);	// next meeting: Sat/Sun/Mon
		dt = (Date)m1.getAttribute("StartDate")[0];
		cal.setTime(dt);
		d = cal.get(Calendar.DAY_OF_WEEK);
		if (d==Calendar.MONDAY)
		{
	// found next mon mtg
	s = recur + meeting.DELIMITER + num + meeting.DELIMITER + m1.getObjectId();
	mtg.setAttribute("Recurring", s);
	mtgMgr.commit(mtg);
	System.out.println("Updated meeting " + mtg.getObjectId());
	mtg = m1;	// this is the mon meeting
	break;
		}
		else
		{
	// remove Sat and Sun
	s = (String)m1.getAttribute("Recurring")[0];
	sa = s.split(meeting.DELIMITER);
	if (sa.length<3 || Integer.parseInt(sa[1])<=0)
		noMore = true;
	else
		nxtId = sa[2];
	delNum--;
	System.out.println("Removed meeting " + m1.getObjectId() + " [" + d + "]");
	mtgMgr.delete(m1);
		}
	}
		}
		else
		{
	s = recur + meeting.DELIMITER + num + meeting.DELIMITER + sa[2];
	mtg.setAttribute("Recurring", s);
	mtgMgr.commit(mtg);
	System.out.println("Updated meeting " + mtg.getObjectId());
	mtg = (meeting)mtgMgr.get(pstuser, sa[2]);	// get next meeting
		}
		if (noMore) break;
	}
*/

/*	// patch meeting Start, Expire, Actual, Complete to UTC time (PST+7hr)
	ids = mtgMgr.findId(pstuser, "om_acctname='%'");
	Date dt;
	long tm;
	String [] sa = {"StartDate", "ExpireDate", "EffectiveDate", "CompleteDate"};
	for (int i=0; i<ids.length; i++)
	{
		meeting mtg = (meeting)mtgMgr.get(pstuser, ids[i]);
		for (int j=0; j<sa.length; j++)
		{
	dt = (Date)mtg.getAttribute(sa[j])[0];
	if (dt == null) continue;
	tm = dt.getTime() + 7 * 3600000;	// convert to UTC (from PST)
	dt = new Date(tm);
	mtg.setAttribute(sa[j], dt);
		}
		mtgMgr.commit(mtg);
		System.out.println("Updated meeting [" + mtg.getObjectId() + "] to UTC");
	}
*/
/*
	// move meetings from Close back to Finish based on time
	ids = mtgMgr.findId(pstuser, "om_acctname='%'");
	Date dt;
	long tm, ts = new Date().getTime() - ((long)30*24*3600000);
	String st;
	for (int i=0; i<ids.length; i++)
	{
		meeting mtg = (meeting)mtgMgr.get(pstuser, ids[i]);
		dt = (Date)mtg.getAttribute("CompleteDate")[0];
		if (dt == null) continue;
		if ( !((String)mtg.getAttribute("Status")[0]).equals(meeting.COMMIT))
	continue;
		tm = dt.getTime() + 7 * 3600000;	// convert to UTC (from PST)
		if (tm > ts)
		{
	mtg.setAttribute("Status", meeting.FINISH);
	mtgMgr.commit(mtg);
	System.out.println("Updated meeting [" + ids[i] + "] to Finish");
		}
	}
*/
	// remove old VCS files
/*	String CAL_PATH = Util.getPropKey("pst", "CALENDAR_FILE_PATH");
	ids = mtgMgr.findId(pstuser,
		"Status='" + meeting.EXPIRE + "' || Status='" + meeting.ABORT +
		"' || Status='" + meeting.COMMIT + "'");
	for (int i=0; i<ids.length; i++)
	{
		// delete the vcs file of this meeting object
		String absFileName = CAL_PATH + File.separator + ids[i] + ".vcs";
		File vFile = new File(absFileName);
		if (vFile.exists())
		{
	vFile.delete();
	System.out.println("deleted file " + ids[i] + ".vcs");
		}
	}
*/
	/////////////////////////////////////////////////////////////
	// ACTION & DECISION
/*
	// add priority to action/decision
	ids = aMgr.findId(pstuser, "om_acctname='%'");
	for (int i=0; i<ids.length; i++)
	{
		action obj = (action)aMgr.get(pstuser, ids[i]);
		obj.setAttribute("Priority", "medium");
		aMgr.commit(obj);
		System.out.println("Updated action [" + ids[i] + "]");
	}


	/////////////////////////////////////////////////////
	// Migration Script
	// 1.  Change all blogs with slt:8080/PRM to prm
	int ct = 0;
	ids = rMgr.findId(pstuser, "om_acctname='%'");
	for (int i=0; i<ids.length; i++)
	{
		result r = (result)rMgr.get(pstuser, ids[i]);
		bText = r.getRawAttributeAsUtf8("Comment");
		//bTextObj = r.getAttribute("Comment")[0];
		//bText = (bTextObj==null)?"":new String((byte[])bTextObj);
		if (!StringUtil.isNullOrEmptyString(bText))
		{
			if (bText.indexOf("collabris.cn//servlet") == -1) continue;
			//bText = bText.replaceAll("183.238.5.149/PRM", "collabris.cn");
			bText = bText.replaceAll("collabris.cn//servlet/ShowFile", "58.60.186.58/servlet/ShowFile");
			r.setRawAttributeUtf("Comment", bText);
			//r.setAttribute("Comment", bText.getBytes());
			rMgr.commit(r);
			System.out.println("changed blog (" + ids[i] + ")");
			ct++;
		}
	}
	System.out.println("Total blog changed = " + ct + "********************");
	

	// 2.  Change all agenda with slt@@8080/PRM to prm.  Also minute with slt:8080/PRM to prm
	ct = 0;
	ids = mtgMgr.findId(pstuser, "AgendaItem='%slt%'");
	for (int i=0; i<ids.length; i++)
	{
		meeting m = (meeting)mtgMgr.get(pstuser, ids[i]);

		// change agenda
		Object [] oArr = m.getAttribute("AgendaItem");
		for (int j=0; j<oArr.length; j++)
		{
	if (oArr[j] == null) break;
	s = (String)oArr[j];
	if (s.indexOf("slt") != -1)
	{
		m.removeAttribute("AgendaItem", oArr[j]);
		s = s.replaceAll("slt@@8080/PRM", "prm");
		m.appendAttribute("AgendaItem", s);
		mtgMgr.commit(m);
		System.out.println("changed agenda " + j + " for meeting (" + ids[i] + ")");
		ct++;
	}
		}
	}
	System.out.println("Total agenda item changed = " + ct);


	ct = 0;
	ids = mtgMgr.findId(pstuser, "om_acctname='%'");
	for (int i=0; i<ids.length; i++)
	{
		meeting m = (meeting)mtgMgr.get(pstuser, ids[i]);

		// meeting notes
		Object bTextObj = m.getAttribute("Note")[0];
		String bText = (bTextObj==null)?"":new String((byte[])bTextObj);
		if (bText.length() > 0)
		{
	if (bText.indexOf("slt") == -1) continue;
	bText = bText.replaceAll("slt:8080/PRM", "prm");
	m.setAttribute("Note", bText.getBytes());
	mtgMgr.commit(m);
	System.out.println("changed minute for meeting (" + ids[i] + ")");
	ct++;
		}
	}
	System.out.println("Total minutes changed = " + ct);


	// End Migration
	/////////////////////////////////////////////////////
*/
/*
	// For testing of jfree multipart graphical email
	DefaultPieDataset pieDataset = new DefaultPieDataset();
	pieDataset.setValue("JavaWorld", new Integer(25));
	pieDataset.setValue("Other", new Integer(25));
	pieDataset.setValue("Other1", new Integer(0));
	pieDataset.setValue("Other2", new Integer(25));
	pieDataset.setValue("Other3", new Integer(25));
	// Create Pie Chart
	JFreeChart chart = ChartFactory.createPieChart
	                     ("Sample Pie Chart",   // Title
	                      pieDataset,           // Dataset
	                      true,                  // Show legend
	                      true,
	                      false
	                     );
	// Setting colors on pie chart!
	PiePlot plot = (PiePlot) chart.getPlot();
	plot.setSectionPaint(0, new java.awt.Color(0,0,0));
	plot.setSectionPaint(1, new java.awt.Color(127,127,127));
	plot.setSectionPaint(2, new java.awt.Color(255,255,255));
	plot.setSectionPaint(3, new java.awt.Color(0,255,0));
	plot.setSectionPaint(4, new java.awt.Color(0,255,255));

    String alertMsg = "<H1>Test on Multipart email with graphics</H1>" +
    "<img src=\"cid:prm_img0\">";

	try {
		// Convert Chart to a DataSource so mail can embed the image
		byte[] byteImage = ChartUtilities.encodeAsPNG(chart.createBufferedImage(500, 300));
		DataSource [] dsArr = new DataSource[1];
		dsArr[0] = new ByteArrayDataSource(byteImage, "image/png");
		//String emailAddr = (String)pstuser.getAttribute("Email")[0];
		String emailAddr = "allenq@egiomm.com";
		Util.sendMailAsyn(pstuser, emailAddr, emailAddr, null, null, "Graphics Test",
	alertMsg, "alert.htm", dsArr);

	} catch (Exception e) {
		e.printStackTrace();
	}
*/



/*
	// remove orphans in blog (result)
	ids = rMgr.findId(pstuser, "ParentID='%'");
	for (int i=0; i<ids.length; i++)
	{
		o = rMgr.get(pstuser, ids[i]);
		String pid = (String)o.getAttribute("ParentID")[0];
		try {rMgr.get(pstuser, pid);}
		catch (PmpException e)
		{
	rMgr.delete(o);		// found orphan
	System.out.println("deleted orphan [" + ids[i] + "]");
		}
	}
*/
/*
	// fix a meeting
	o = mtgMgr.get(pstuser, 59406);
	Object [] agendaArr = o.getAttribute("AgendaItem");
	for (int i=0; i<agendaArr.length; i++)
	{
		s = (String)agendaArr[i];			// (pre-order::order::level::item::duration::owner)
		sa = s.split(meeting.DELIMITER);
		int level = Integer.parseInt(sa[2]) - 1;
		s = sa[0] + meeting.DELIMITER + sa[1] + meeting.DELIMITER + level + meeting.DELIMITER
	+ sa[3] + meeting.DELIMITER + sa[4] + meeting.DELIMITER + sa[5];
		agendaArr[i] = s;
	}
	o.setAttribute("AgendaItem", agendaArr);
	mtgMgr.commit(o);
	System.out.println("fixed meeting");
*/

/*
	// Testing: sending out meeting request
	int zoneDiff = 0;		// time zone's hourly diff from GMT
	String[] tzs = TimeZone.getAvailableIDs(0);		// GMT timezone
	SimpleTimeZone tz = new SimpleTimeZone(0, tzs[0]);

	// set up rules for daylight savings time
	//tz.setStartRule(Calendar.APRIL, 1, Calendar.SUNDAY, 2 * 60 * 60 * 1000);
	//tz.setEndRule(Calendar.OCTOBER, -1, Calendar.SUNDAY, 2 * 60 * 60 * 1000);
	//SimpleDateFormat df1 = new SimpleDateFormat("MM/dd/yyyy HH:mm:ss");
	SimpleDateFormat df2 = new SimpleDateFormat ("yyyyMMdd'T'HHmmss'Z'");
	df2.setTimeZone(tz);

	Calendar cal = Calendar.getInstance();
	cal.setTimeZone(tz);
	cal.add(Calendar.HOUR, 1);
	Date dt = cal.getTime();

	StringBuffer buf = new StringBuffer();
	buf.append("BEGIN:VCALENDAR\n"+
	"PRODID:-//Microsoft Corporation//Outlook 9.0 MIMEDIR//EN\n"+
	"VERSION:2.0\n"+
	"METHOD:REQUEST\n"+
	"BEGIN:VEVENT\n");

	// attendee and organizer
	buf.append(
	"ATTENDEE;CN=\"Allen, Quan (Gmail)\";ROLE=OPT-PARTICIPANT;MAILTO:ahlun4211@gmail.com\n"+
	"ATTENDEE;CN=\"Edward, Cheng (Spansion)\";ROLE=OPT-PARTICIPANT;MAILTO:edward.cheng@spansion.com\n"+
	"ORGANIZER:MAILTO:edward.cheng@spansion.com\n");

	// meeting time
	buf.append(
	"DTSTART:" + df2.format(dt) + "\n");
	cal.add(Calendar.MINUTE, 90);
	dt = cal.getTime();
	buf.append(
	"DTEND:" + df2.format(dt) + "\n");
	// location
	buf.append(
	"LOCATION:Conf Room\n"+
	"TRANSP:OPAQUE\n"+
	"SEQUENCE:0\n"+
	"UID:040000008200E00074C5B7101A82E00800000000A0A742E5073AC5010000000000000000100\n"+
	" 0000029606C073D82204AB6C77ACE6BC2FBE2\n"+
	"DTSTAMP:" + df2.format(dt) + "\n"+
	"CATEGORIES:Meeting\n");

	// agenda
	buf.append(
	"DESCRIPTION:Agenda is shown below\n\n");

	buf.append(
	"SUMMARY:PRM Meeting invitation\n"+
	"PRIORITY:5\n"+
	"CLASS:PUBLIC\n"+
	"BEGIN:VALARM\n"+
	"TRIGGER:PT1440M\n"+
	"ACTION:DISPLAY\n"+
	"DESCRIPTION:Reminder\n"+
	"END:VALARM\n"+
	"END:VEVENT\n"+
	"END:VCALENDAR\n");

	String calBufTxt = buf.toString();
	String subject = "Test Meeting Request 18";
	Email em = new Email();
	em.sendMtgReq("ahlun4211@gmail.com edward.cheng@spansion.com", "edward.cheng@spansion.com", null, null,
	subject, calBufTxt, false);
*/

	// ************ SE Migration starts
/*
	// for Merciful
	String [] mtgName = {"EGI", "Bug", "Product", "Development", "Bible", "Transition"};
	String [] pidMap = {"55445", "55445", "55445", "55445", "56376", "55629"};
*/
/*
	String path = Util.getPropKey("pst", "FILE_UPLOAD_PATH");
	String absPath, relPath, tempRelPath;
	File f, f1;
	Date dt;
	int ct;
	int sum, total=0;
*/
/*
	// for Spansion
	String [] mtgName = {"880", "Agilent", "887", "760", "521", "Genesis", "ORNAND", "PRM", "447", "257", "WS Bi-w",
			"MegaSIM", "PE/TE", "U08", "446", "765"};
	String [] pidMap = {"63530", "63530", "58653", "51727", "59602", "73902", "59671", "46143", "68945", "68945", "68945",
			"56269", "56269", "43575", "44899", "56071"};

	// add project association to meeting
	// use meeting name to identify the project

	int len = mtgName.length;

	System.out.println("Patch Proj ID for meetings");
	ids = mtgMgr.findId(pstuser, "om_acctname='%'");
	for (int i=0; i<ids.length; i++)
	{
		o = mtgMgr.get(pstuser, ids[i]);
		s = (String)o.getAttribute("Subject")[0];
		if (s == null)
		{
	mtgMgr.delete(o);
	System.out.println("remove empty meeting [" + ids[i] + "]");
	continue;
		}
		for (int j=0; j<len; j++)
		{
	if (s.indexOf(mtgName[j]) != -1)
	{
		o.setAttribute("ProjectID", pidMap[j]);
		mtgMgr.commit(o);
		//System.out.println("Set PID for meeting [" + ids[i] + "]");
		break;
	}
		}
	}

	// add project association to blog
	System.out.println("Patch Proj ID for blogs");
	ids = rMgr.findId(pstuser, "om_acctname='%'");
	for (int i=0; i<ids.length; i++)
	{
		mgr = null;
		o = rMgr.get(pstuser, ids[i]);	// can be blog for task, bug, action or personal
		s = (String)o.getAttribute("Type")[0];
		if (s == null)
		{
	rMgr.delete(o);
	System.out.println("remove empty blog [" + ids[i] + "]");
	continue;
		}
		if (s.startsWith(result.TYPE_BUG_BLOG))
	mgr = bMgr;
		else if (s.startsWith(result.TYPE_TASK_BLOG))
	mgr = tkMgr;
		else if (s.startsWith(result.TYPE_ACTN_BLOG))
	mgr = aMgr;
		if (mgr == null) continue;
		s = (String)o.getAttribute("TaskID")[0];
		if (s==null || s.equalsIgnoreCase("null")) continue;						// TaskID is null for blog comments
		PstAbstractObject oo = mgr.get(pstuser, s);		// oo can be task, bug or action
		o.setAttribute("ProjectID", (String)oo.getAttribute("ProjectID")[0]);			// set blog's projectID
		rMgr.commit(o);
		//System.out.println("added projectID to blog ["+ids[i]+"]");
	}

	// patch database for move attachments into its object class
	// do this for each project, task, bug, meeting and blog (only these + memo has the Attachment attribute)

	// project
	sum = 0;
	System.out.println("\n----- patch attachment for project files");
	ids = pjMgr.findId(pstuser, "om_acctname='%'");
	for (int i=0; i<ids.length; i++)
	{
		ct = 0;
		o = pjMgr.get(pstuser, ids[i]);
		Object [] oArr = o.getAttribute("Attachment");
		for (int j=0; j<oArr.length; j++)
		{
	if (oArr[j] == null) break;
	s = (String)oArr[j];		// this is the filename

	relPath = "/" + ids[i] + "/" + s;
	tempRelPath = relPath.replaceAll("'", "\\\\'");
	int [] ids2 = attMgr.findId(pstuser, "Location='" + tempRelPath + "'");
	if (ids2.length > 0) continue;		// already done with this

	String ext = null;
	int iExt = s.lastIndexOf(".");
	if (iExt != -1) ext = s.substring(iExt+1);

	absPath = path + "/" + ids[i] + "/Attachment-" + s;
	f = new File(absPath);
	f1 = new File(path + relPath);
	if (f.exists())
	{
		// found physical file in the drive
		dt = new Date(f.lastModified());
		f.renameTo(f1);				// rename file (remove Attachment-)
	}
	else
	{
		// might be our development machine: no physical files
		if (f1.exists())
		{
	System.out.println("   file already renamed");
	dt = new Date(f1.lastModified());
		}
		else
		{
	System.out.println("   cannot find file [" + absPath + "]");
	dt = new Date(0);
		}
	}

	// create new attachment object
	attachment att = (attachment)attMgr.create(pstuser);
	att.setAttribute("Owner", (String)o.getAttribute("Owner")[0]);
	att.setAttribute("CreatedDate", dt);
	att.setAttribute("LastUpdatedDate", dt);
	att.setAttribute("Location", relPath);			// relative path
	att.setAttribute("Frequency", new Integer(0));
	att.setAttribute("ProjectID", String.valueOf(ids[i]));
	att.setAttribute("Type", attachment.TYPE_PROJECT);
	att.setAttribute("FileExt", ext);
	att.setAttribute("SecurityLevel", new Integer(0));
	attMgr.commit(att);
	ct++;

	// update object
	o.setAttribute("Attachment", null);		// remove old values
	o.appendAttribute("AttachmentID", String.valueOf(att.getObjectId()));
		}
		if (ct>0)
		{
	pjMgr.commit(o);
	System.out.println("project " + ids[i] + " done with " + ct + " files");
	sum += ct;
		}
	}
	System.out.println("   subtotal " + sum + " files processed.");
	total += sum;

	// tasks
	sum = 0;
	System.out.println("\n----- patch attachment for task files");
	ids = tkMgr.findId(pstuser, "om_acctname='%'");
	for (int i=0; i<ids.length; i++)
	{
		ct = 0;
		o = tkMgr.get(pstuser, ids[i]);
		Object [] oArr = o.getAttribute("Attachment");
		for (int j=0; j<oArr.length; j++)
		{
	if (oArr[j] == null) break;
	s = (String)oArr[j];		// this is the filename

	relPath = "/" + ids[i] + "/" + s;
	tempRelPath = relPath.replaceAll("'", "\\\\'");
	int [] ids2 = attMgr.findId(pstuser, "Location='" + tempRelPath + "'");
	if (ids2.length > 0) continue;		// already done with this

	String ext = null;
	int iExt = s.lastIndexOf(".");
	if (iExt != -1) ext = s.substring(iExt+1);

	absPath = path + "/" + ids[i] + "/Attachment-" + s;
	f = new File(absPath);
	f1 = new File(path + relPath);
	if (f.exists())
	{
		// found physical file in the drive
		dt = new Date(f.lastModified());
		f.renameTo(f1);				// rename file (remove Attachment-)
	}
	else
	{
		// might be our development machine: no physical files
		if (f1.exists())
		{
	dt = new Date(f1.lastModified());
	System.out.println("   file already renamed");
		}
		else
		{
	System.out.println("   cannot find file [" + absPath + "]");
	dt = new Date(0);
		}
	}

	// create new attachment object
	attachment att = (attachment)attMgr.create(pstuser);
	att.setAttribute("Owner", (String)o.getAttribute("Owner")[0]);
	att.setAttribute("CreatedDate", dt);
	att.setAttribute("LastUpdatedDate", dt);
	att.setAttribute("Location", relPath);			// relative path
	att.setAttribute("Frequency", new Integer(0));
	att.setAttribute("ProjectID", (String)o.getAttribute("ProjectID")[0]);
	att.setAttribute("Type", attachment.TYPE_TASK);
	att.setAttribute("FileExt", ext);
	att.setAttribute("SecurityLevel", new Integer(0));
	attMgr.commit(att);
	ct++;

	// update object
	o.setAttribute("Attachment", null);		// remove old values
	o.appendAttribute("AttachmentID", String.valueOf(att.getObjectId()));
		}
		if (ct>0)
		{
	tkMgr.commit(o);
	//System.out.println("task " + ids[i] + " done with " + ct + " files");
	sum += ct;
		}
	}
	System.out.println("   subtotal " + sum + " files processed.");
	total += sum;

	// bugs
	sum = 0;
	System.out.println("\n----- patch attachment for bug files");
	ids = bMgr.findId(pstuser, "om_acctname='%'");
	for (int i=0; i<ids.length; i++)
	{
		ct = 0;
		o = bMgr.get(pstuser, ids[i]);
		Object [] oArr = o.getAttribute("Attachment");
		for (int j=0; j<oArr.length; j++)
		{
	if (oArr[j] == null) break;
	s = (String)oArr[j];		// this is the filename

	relPath = "/" + ids[i] + "/" + s;
	tempRelPath = relPath.replaceAll("'", "\\\\'");
	int [] ids2 = attMgr.findId(pstuser, "Location='" + tempRelPath + "'");
	if (ids2.length > 0) continue;		// already done with this

	String ext = null;
	int iExt = s.lastIndexOf(".");
	if (iExt != -1) ext = s.substring(iExt+1);

	absPath = path + "/" + ids[i] + "/Attachment-" + s;
	f = new File(absPath);
	f1 = new File(path + relPath);
	if (f.exists())
	{
		// found physical file in the drive
		dt = new Date(f.lastModified());
		f.renameTo(f1);				// rename file (remove Attachment-)
	}
	else
	{
		// might be our development machine: no physical files
		if (f1.exists())
		{
	dt = new Date(f1.lastModified());
	System.out.println("   file already renamed");
		}
		else
		{
	System.out.println("   cannot find file [" + absPath + "]");
	dt = new Date(0);
		}
	}

	// create new attachment object
	attachment att = (attachment)attMgr.create(pstuser);
	String own = (String)o.getAttribute("Owner")[0];
	if (own == null) own = (String)o.getAttribute("Creator")[0];
	att.setAttribute("Owner", own);		// either own by bug owner or submitter
	att.setAttribute("CreatedDate", dt);
	att.setAttribute("LastUpdatedDate", dt);
	att.setAttribute("Location", relPath);			// relative path
	att.setAttribute("Frequency", new Integer(0));
	att.setAttribute("ProjectID", (String)o.getAttribute("ProjectID")[0]);
	att.setAttribute("Type", attachment.TYPE_BUG);
	att.setAttribute("FileExt", ext);
	att.setAttribute("SecurityLevel", new Integer(0));
	attMgr.commit(att);
	ct++;

	// update object
	o.setAttribute("Attachment", null);		// remove old values
	o.appendAttribute("AttachmentID", String.valueOf(att.getObjectId()));
		}
		if (ct>0)
		{
	bMgr.commit(o);
	System.out.println("bug " + ids[i] + " done with " + ct + " files");
	sum += ct;
		}
	}
	System.out.println("   subtotal " + sum + " files processed.");
	total += sum;
*/

/*
	// meeting
	sum = 0;
	System.out.println("\n----- patch attachment for meeting files");
	ids = mtgMgr.findId(pstuser, "om_acctname='59079'");
	for (int i=0; i<ids.length; i++)
	{
		ct = 0;
		o = mtgMgr.get(pstuser, ids[i]);
		Object [] oArr = o.getAttribute("Attachment");
		for (int j=0; j<oArr.length; j++)
		{
	if (oArr[j] == null) break;
	s = (String)oArr[j];		// this is the filename

	relPath = "/" + ids[i] + "/" + s;
	tempRelPath = relPath.replaceAll("'", "\\\\'");
	int [] ids2 = attMgr.findId(pstuser, "Location='" + tempRelPath + "'");
	if (ids2.length > 0) continue;		// already done with this

	String ext = null;
	int iExt = s.lastIndexOf(".");
	if (iExt != -1) ext = s.substring(iExt+1);

	absPath = path + "/" + ids[i] + "/Attachment-" + s;
	f = new File(absPath);
	f1 = new File(path + relPath);
	if (f.exists())
	{
		// found physical file in the drive
		dt = new Date(f.lastModified());
		f.renameTo(f1);				// rename file (remove Attachment-)
	}
	else
	{
		// might be our development machine: no physical files
		if (f1.exists())
		{
	System.out.println("   file already renamed");
	dt = new Date(f1.lastModified());
		}
		else
		{
	System.out.println("   cannot find file [" + absPath + "]");
	dt = new Date(0);
		}
	}

	// create new attachment object
	attachment att = (attachment)attMgr.create(pstuser);
	att.setAttribute("Owner", (String)o.getAttribute("Owner")[0]);
	att.setAttribute("CreatedDate", dt);
	att.setAttribute("LastUpdatedDate", dt);
	att.setAttribute("Location", relPath);			// relative path
	att.setAttribute("Frequency", new Integer(0));
	att.setAttribute("ProjectID", (String)o.getAttribute("ProjectID")[0]);
	att.setAttribute("Type", attachment.TYPE_MEETING);
	att.setAttribute("FileExt", ext);
	att.setAttribute("SecurityLevel", new Integer(0));
	attMgr.commit(att);
	ct++;

	// update object
	o.setAttribute("Attachment", null);		// remove old values
	o.appendAttribute("AttachmentID", String.valueOf(att.getObjectId()));
		}
		if (ct>0)
		{
	mtgMgr.commit(o);
	System.out.println("meeting " + ids[i] + " done with " + ct + " files");
	sum += ct;
		}
	}
	System.out.println("   subtotal " + sum + " files processed.");
	total += sum;
*/

/*
	// blog
	sum = 0;
	System.out.println("\n----- patch attachment for blog files");
	ids = rMgr.findId(pstuser, "om_acctname='%'");
	for (int i=0; i<ids.length; i++)
	{
		ct = 0;
		o = rMgr.get(pstuser, ids[i]);
		Object [] oArr = o.getAttribute("Attachment");
		for (int j=0; j<oArr.length; j++)
		{
	if (oArr[j] == null) break;
	s = (String)oArr[j];		// this is the filename

	relPath = "/" + ids[i] + "/" + s;
	tempRelPath = relPath.replaceAll("'", "\\\\'");
	int [] ids2 = attMgr.findId(pstuser, "Location='" + tempRelPath + "'");
	if (ids2.length > 0) continue;		// already done with this

	// check blog type
	String bType = (String)o.getAttribute("Type")[0];
	if (bType.indexOf(result.TYPE_TASK_BLOG) != -1) bType = attachment.TYPE_B_TASK;
	else if (bType.indexOf(result.TYPE_BUG_BLOG) != -1) bType = attachment.TYPE_B_BUG;
	else if (bType.indexOf(result.TYPE_ACTN_BLOG) != -1) bType = attachment.TYPE_B_ACTION;
	else if (bType.indexOf(result.TYPE_ENGR_BLOG) != -1) bType = attachment.TYPE_B_PERSONAL;

	String ext = null;
	int iExt = s.lastIndexOf(".");
	if (iExt != -1) ext = s.substring(iExt+1);

	absPath = path + "/" + ids[i] + "/Attachment-" + s;
	f = new File(absPath);
	f1 = new File(path + relPath);
	if (f.exists())
	{
		// found physical file in the drive
		dt = new Date(f.lastModified());
		f.renameTo(f1);				// rename file (remove Attachment-)
	}
	else
	{
		// might be our development machine: no physical files
		if (f1.exists())
		{
	System.out.println("   file already renamed");
	dt = new Date(f1.lastModified());
		}
		else
		{
	System.out.println("   cannot find file [" + absPath + "]");
	dt = new Date(0);
		}
	}

	// create new attachment object
	attachment att = (attachment)attMgr.create(pstuser);
	att.setAttribute("Owner", (String)o.getAttribute("Creator")[0]);
	att.setAttribute("CreatedDate", dt);
	att.setAttribute("LastUpdatedDate", dt);
	att.setAttribute("Location", relPath);			// relative path
	att.setAttribute("Frequency", new Integer(0));
	att.setAttribute("ProjectID", (String)o.getAttribute("ProjectID")[0]);
	att.setAttribute("Type", bType);
	att.setAttribute("FileExt", ext);
	att.setAttribute("SecurityLevel", new Integer(0));
	attMgr.commit(att);
	ct++;

	// update object
	o.setAttribute("Attachment", null);		// remove old values
	o.appendAttribute("AttachmentID", String.valueOf(att.getObjectId()));
		}
		if (ct>0)
		{
	rMgr.commit(o);
	System.out.println("blog " + ids[i] + " done with " + ct + " files");
	sum += ct;
		}
	}
	System.out.println("   subtotal " + sum + " files processed.");
	total += sum;
	System.out.println("***** SE Patch completed sucessfully.");
	System.out.println("      Total (" + total + ") files processed.");

//@AGQ062206 Remove extra result w/ type = ProjPhase
	int [] test = rMgr.findId(pstuser, "Type='ProjPhase'");
	System.out.println("There contains " + test.length + " result object with Type='ProjPhase'");
	PstAbstractObject [] objArr = rMgr.get(pstuser, test);
	for (int i=0; i<test.length; i++) {
		result res = (result)objArr[i];
		System.out.println("Removing result objectID: " + res.getObjectId());
		rMgr.delete(res);
	}


		// build index: just for once
		mod.se.IndexBuilder.build(pstuser, true);
*/

/*
	// @AGQ081606 Fix database meeting objects for attribte type from null -> public
	ids = mtgMgr.findId(pstuser, "om_acctname='%'");
	PstAbstractObject [] mtgArr = mtgMgr.get(pstuser, ids);
	meeting m = null;
	String meetingType = null;
	for (int i=0; i<mtgArr.length; i++)
	{
		m = (meeting) mtgArr[i];
		meetingType = (String) m.getAttribute(meeting.TYPE)[0];
		if (meetingType == null)
		{
	m.setAttribute(meeting.TYPE, meeting.PRIVATE);
	mtgMgr.commit(m);
	System.out.println("updated meeting [" + m.getObjectId() + "] from null type to Private");
	continue;
		}
	}

	// patch attachment: if they belongs to Private meeting, add the authorized access list
	ids = attMgr.findId(pstuser, "om_acctname='%'");
	attachment att;
	for (int i=0; i<ids.length; i++)
	{
		att = (attachment)attMgr.get(pstuser, ids[i]);
		s = (String) att.getAttribute("Type")[0];
		if (s != null && s.equals("meeting"))
		{
	ids1 = mtgMgr.findId(pstuser, "AttachmentID='" + ids[i] + "'");
	if (ids1.length <= 0)
	{
		System.out.println("cannot find meeting object for attachment " + ids[i]);
		continue;
	}
	meeting mtg = (meeting)mtgMgr.get(pstuser, ids1[0]);
	att.setAuthorizedList(mtg);
	System.out.println("set authority list for attachment [" + ids[i] + "]");
		}
	}
*/
/*
	// init ViewBlogNum of meetings to 25
	ids = mtgMgr.findId(pstuser, "om_acctname='%'");
	for (int i=0; i<ids.length; i++)
	{
		io = new Integer(0);
		o = mtgMgr.get(pstuser, ids[i]);
		o.setAttribute("ViewBlogNum", io);
		mtgMgr.commit(o);
	}
*/
/*
	// use Towns instead of TownID for user: support multiple companies
	ids = uMgr.findId(pstuser, "om_acctname='%'");
	for (int i=0; i<ids.length; i++)
	{
		o = uMgr.get(pstuser, ids[i]);
		s = (String)o.getAttribute("TownID")[0];
		if (s != null)
		{
	io = new Integer(s);
	o.appendAttribute("Towns", io);
	o.setAttribute("TownID", null);
	uMgr.commit(o);
	System.out.println("fixed user [" + o.getObjectName() + "] for town [" + s + "]");
		}
	}
*/
/*
	// OMF: compare town domain email with user and set user's towns
	ids1 = tnMgr.findId(pstuser, "om_acctname='%'");
	String [] domain = new String[ids1.length];
	for (int i=0; i<ids1.length; i++)
	{
		domain[i] = (String)tnMgr.get(pstuser, ids1[i]).getAttribute("Email")[0];
		if (domain[i] != null)
	domain[i] = domain[i].toLowerCase();
	}
	ids  = uMgr.findId(pstuser, "om_acctname='%'");
	Object [] towns;
	String email;
	for (int i=0; i<ids.length; i++)
	{
		o = uMgr.get(pstuser, ids[i]);
		towns = o.getAttribute("Towns");
		s = "";
		if (towns[0] != null)
		{
	for (int j=0; j<towns.length; j++)
		s += towns[j].toString() + ";";
		}

		email = (String)o.getAttribute("Email")[0];
		if (email == null) continue;				// special acct, no email
		email = email.toLowerCase();

		// start comparing email with domain to set town
		for (int j=0; j<ids1.length; j++)
		{
	if (domain[j] == null) continue;		// no domain email, can't check
	oo = tnMgr.get(pstuser, ids1[j]);
	if (s.indexOf(String.valueOf(ids1[j])) != -1)
		continue;		// already has this town
	if (email.endsWith(domain[j]))
	{
		o.appendAttribute("Towns", new Integer(ids1[j]));
		uMgr.commit(o);
		System.out.println("added town [" + ids1[j] + "] to user [" + o.getObjectName() + "]");
	}
		}
	}
*/

/*
	// CR: migrate Pericom db from older version of PRM to new
	// Security feature requires DepartmentName on project, task and attachment
	// Also update user Department to ENGR to start

	// 2nd Time: Pericom change ENGR to PE/AE, this impact all four organizations: user, project, task, attachment
	ids = pjMgr.findId(pstuser, "om_acctname='%'");
	for (int i=0; i<ids.length; i++)
	{
		o = pjMgr.get(pstuser, ids[i]);
		o.setAttribute("DepartmentName", "PE/AE");
		pjMgr.commit(o);
		System.out.println("updated DepartmentName of project [" + ids[i] + "]");
	}
	ids = tkMgr.findId(pstuser, "om_acctname='%'");
	for (int i=0; i<ids.length; i++)
	{
		o = tkMgr.get(pstuser, ids[i]);
		o.setAttribute("DepartmentName", "PE/AE");
		tkMgr.commit(o);
		System.out.println("updated DepartmentName of task [" + ids[i] + "]");
	}
	ids = attMgr.findId(pstuser, "om_acctname='%'");
	for (int i=0; i<ids.length; i++)
	{
		o = attMgr.get(pstuser, ids[i]);
		o.setAttribute("DepartmentName", "PE/AE");
		attMgr.commit(o);
		System.out.println("updated DepartmentName of attachment [" + ids[i] + "]");
	}
	ids = uMgr.findId(pstuser, "om_acctname='%'");
	for (int i=0; i<ids.length; i++)
	{
		o = uMgr.get(pstuser, ids[i]);
		s = o.getObjectName();
		if (s.equals("admin") || s.startsWith("prm"))
	continue;
		o.setAttribute("DepartmentName", "PE/AE");
		uMgr.commit(o);
		System.out.println("updated DepartmentName of user [" + s + "]");
	}

	ids = cMgr.findId(pstuser, "om_acctname='%'");
	String nm;
	for (int i=0; i<ids.length; i++)
	{
		o = cMgr.get(pstuser, ids[i]);
		o.setAttribute("Name", "@" + o.getAttribute("Name")[0]);
		cMgr.commit(o);
		System.out.println("set name for [" + o.getObjectId() + "]");
	}
*/

	// really useful: trigger an event for a user to his friend or a paricular circle
	// pass the person's uid
	// ECC: simply stack an event 70638 onto a circle
/*
	int uid = 39412;		// the user id: e.g. Andre
	PstAbstractObject u = uMgr.get(pstuser, uid);
	event evt = (event)eMgr.get(pstuser, 70638);

	int blogId = 65820;
	PrmEvent.checkCleanMaxEvent(pstuser,
	"Type='" + PrmEvent.EVT_BLG_PAGE3 + "' && Creator='" + uid
		+ "' && AlertMessage='% on his/her own page%'", 0);	// remove all old
	event evt = PrmEvent.create((PstUserAbstractObject)u, PrmEvent.EVT_BLG_PAGE3, null, null, null);	// can't be admin
	o = rMgr.get(pstuser, blogId);	// this is a blog from user
	bTextObj = o.getAttribute("Comment")[0];
	String text = (bTextObj==null)?"":new String((byte[])bTextObj);
	if (text.length() > 100)
	{
		int idx = text.indexOf(" ", 100);
		if (idx!=-1 && idx<200)
	text = text.substring(0, idx);
		else
	text = "";
	}
	String lnkStr = "<blockquote class='bq_com'>" + text + " ... <a class='listlink' href='../ep/my_page.jsp?uid=" + uid
		+ "'>read more & reply</a></blockquote>";
	PrmEvent.setValueToVar(evt, "var1", lnkStr);
*/


/*
	// look for users of town tid, unstack the specified event
	ids = uMgr.findId(pstuser, "Events='%68654%'");
	int tid = 64127;
	for (int i=0; i<ids.length; i++)
	{
		o = uMgr.get(pstuser, ids[i]);
		Object [] oA = o.getAttribute("Towns");
		boolean found = false;
		for (int j=0; j<oA.length; j++)
		{
	Integer iobj = (Integer)oA[j];
	if (iobj!=null && iobj.intValue()==tid)
	{
		found = true;
		break;
	}
		}
		if (!found)
		{
	PrmEvent.unstackEvent(pstuser, ids[i], "68654");
		}
	}

	// create step for task
	project pj = (project)pjMgr.get(pstuser, 59403);
	pj.createProjectFlow(pstuser);
	ids = pj.getCurrentTasks(pstuser);
	for (int i=0; i<ids.length; i++)
	{
		task t = (task)tkMgr.get(pstuser, ids[i]);
		PstFlowStep step = t.getStep(pstuser);
		if (step != null)
	fsMgr.delete(step);
		t.createStep(pstuser);
	}
*/
/*
	// change CurrentExecutor to ID string
	PstAbstractObject u;
	ids = fsMgr.findId(pstuser, "om_acctname='%'");
	for (int i=0; i<ids.length; i++)
	{
		o = fsMgr.get(pstuser, ids[i]);

		// change current executor
		s = (String)o.getAttribute("CurrentExecutor")[0];
		if (s!=null && !s.equals("dummy")) {
	u = uMgr.get(pstuser, s);
	s = String.valueOf(u.getObjectId());
	o.setAttribute("CurrentExecutor", s);
		}


	// create step for task
	project pj = (project)pjMgr.get(pstuser, 59403);
	pj.createProjectFlow(pstuser);
	ids = pj.getCurrentTasks(pstuser);
	System.out.println("total cur task = "+ids.length);
	for (int i=0; i<ids.length; i++)
	{
		task t = (task)tkMgr.get(pstuser, ids[i]);
		PstFlowStep step = t.getStep(pstuser);
		if (step != null)
	fsMgr.delete(step);
		t.createStep(pstuser);
	}

	// assign type to existing flow step
	ids = fsMgr.findId(pstuser, "om_acctname='%'");
	for (int i=0; i<ids.length; i++) {
		o = fsMgr.get(pstuser, ids[i]);
		if (o.getAttribute("Type")[0] == null) {
	if (o.getAttribute("TaskID")[0] == null)
		o.setAttribute("Type", PstFlowStep.TYPE_WORKFLOW);
	else
		o.setAttribute("Type", PstFlowStep.TYPE_PROJTASK);
	fsMgr.commit(o);
	System.out.println("fixed step ["+ ids[i] + "]");
		}
	}

	// set Original Start/Expire Date
	ids = tkMgr.findId(pstuser, "om_acctname='%'");
	for (int i=0; i<ids.length; i++) {
		o = tkMgr.get(pstuser, ids[i]);
		if (o.getAttribute("OriginalStartDate")[0] == null) {
	o.setAttribute("OriginalStartDate", o.getAttribute("StartDate")[0]);
	o.setAttribute("OriginalExpireDate", o.getAttribute("ExpireDate")[0]);
	tkMgr.commit(o);
	System.out.println("filled Original Dates for task [" + ids[i] + "]");
		}
	}

	// 6/3/10 add bug Note (initial description)
	ids = bMgr.findId(pstuser, "om_acctname='%'");
	for (int i=0; i<ids.length; i++) {
		o = bMgr.get(pstuser, ids[i]);
		// for each bug, use the first blog as description if exist
		if (o.getRawAttributeAsString("Note") == null) {
	ids1 = rMgr.findId(pstuser, "TaskID='" + ids[i] + "'");
	if (ids1.length > 0) {
		Arrays.sort(ids1);
		s = rMgr.get(pstuser, ids1[0]).getRawAttributeAsString("Comment");
		s = s.replaceAll("(<br>|<p>)", "\n");
		s = s.replaceAll("<\\S[^>]*>", "");
		o.setAttribute("Note", s.getBytes());
		bMgr.commit(o);
		System.out.println("copied note for bug [" + ids[i] + "]");
	}
		}
	}

	// 6/4/10 add bug CompleteDate
	ids = bMgr.findId(pstuser, "om_acctname='%'");
	for (int i=0; i<ids.length; i++) {
		o = bMgr.get(pstuser, ids[i]);
		s = (String)o.getAttribute("State")[0];
		if (!s.equals(bug.OPEN) && !s.equals(bug.ACTIVE)) {
	o.setAttribute("CompleteDate", (Date)o.getAttribute("LastUpdatedDate")[0]);
	bMgr.commit(o);
	System.out.println("updated CompleteDate for bug [" + ids[i] + "]");
		}
	}

	// roll forward meetings of a project for demo
	String [] attArr = {"StartDate", "ExpireDate", "EffectiveDate", "CompleteDate"};
	Calendar cal = Calendar.getInstance();
	Date dt;
	ids = mtgMgr.findId(pstuser, "ProjectID='59403'");
	boolean bNeedSave;
	for (int i=0; i<ids.length; i++) {
		o = mtgMgr.get(pstuser, ids[i]);
		bNeedSave = false;
		for (int j=0; j<attArr.length; j++) {
	dt = (Date)o.getAttribute(attArr[j])[0];
	if (dt != null) {
		cal.setTime(dt);
		cal.add(Calendar.DAY_OF_MONTH, 3);		// add 3 days
		o.setAttribute(attArr[j], cal.getTime());
		bNeedSave = true;
	}
		}
		if (bNeedSave) {
	mtgMgr.commit(o);
	System.out.println("roll forward meeting [" + ids[i] + "]");
		}
	}
	
	// this code is used to change the network drive location
	ids = attMgr.findId(pstuser, "Location='//phoenix/Department%'");
	for (int i=0; i<ids.length; i++) {
		o = attMgr.get(pstuser, ids[i]);
		s = (String)o.getAttribute("Location")[0];
		s = s.replaceFirst("//phoenix/Department", "//172.16.4.36/Department1");
		o.setAttribute("Location", s);
		attMgr.commit(o);
		System.out.println("fixed attachment " + ids[i]);
	}

	long Hr8 = 8 * 3600000;
	SimpleDateFormat df = new SimpleDateFormat("MM/dd/yyyy");
	Date feb15 = df.parse("02/15/2011");
	ids = mtgMgr.findId(pstuser, "om_acctname='%'");
	String [] attArr = {"StartDate", "ExpireDate", "EffectiveDate", "CompleteDate"};
	for (int i=0; i<ids.length; i++) {
		o = mtgMgr.get(pstuser, ids[i]);
		boolean bUpdated = false;
		for (int j=0; j<attArr.length; j++) {
	Date dt = (Date)o.getAttribute(attArr[j])[0];
	if (dt != null && dt.before(feb15)) {
		dt = new Date(dt.getTime() - Hr8);
		o.setAttribute(attArr[j], dt);
		bUpdated = true;
	}
		}
		if (bUpdated) {
	mtgMgr.commit(o);
	System.out.println("fixed meeting " + ids[i]);
		}
	}

	ids = qMgr.findId(pstuser, "om_acctname='%'");
	String [] attArr1 = {"StartDate", "ExpireDate", "EffectiveDate"};
	for (int i=0; i<ids.length; i++) {
		o = qMgr.get(pstuser, ids[i]);
		boolean bUpdated = false;
		for (int j=0; j<attArr1.length; j++) {
	Date dt = (Date)o.getAttribute(attArr1[j])[0];
	if (dt != null && dt.before(feb15)) {
		dt = new Date(dt.getTime() - Hr8);
		o.setAttribute(attArr1[j], dt);
		bUpdated = true;
	}
		}
		if (bUpdated) {
	qMgr.commit(o);
	System.out.println("fixed quest " + ids[i]);
		}
	}

	// revert all *-Archive (result.TYPE_ARCHIVE)
	ids = rMgr.findId(pstuser, "Type='%-Archive'");
	for (int i=0; i<ids.length; i++)
	{
		o = rMgr.get(pstuser, ids[i]);
		if (o.getAttribute("Comment")[0] != null) {
	s = o.getStringAttribute("Type");
	s = s.replace("-Archive", "");
	o.setAttribute("Type", s);
	rMgr.commit(o);
	System.out.println("fixed [" + ids[i] + "] with " + s);
		}
	}
	System.out.println("Done revert");


	// construct Contacts for users through projects
	// cleanup
	user u;
	ids = pjMgr.findId(pstuser, "om_acctname='%'");
	for (int i=0; i<ids.length; i++) {
		o = pjMgr.get(pstuser, ids[i]);
		Object [] teamMembers = o.getAttribute("TeamMembers");
		for (int j=0; j<teamMembers.length; j++) {
	try {u = (user)uMgr.get(pstuser, ((Integer)teamMembers[j]).intValue());}
	catch (Exception e) {continue;}
	int num = u.addContacts(teamMembers);
	System.out.println("   added (" + num + ") contacts to [" + u.getObjectName() + "]");
		}
		System.out.println("-- Done adding contacts for project [" + ids[i] + "]");
	}
	

	ids = pjMgr.findId(pstuser, "om_acctname='%'");
	project pj;
	for (int i = 0; i < ids.length; i++) {
		pj = (project) pjMgr.get(pstuser, ids[i]);
		String creator = pj.getStringAttribute("Creator");
		if (creator != null) {
			// try to see if a chat already exist
			ids1 = cMgr.findId(pstuser, "ProjectID='" + ids[i] + "'");
			if (ids1.length <= 0) {
				o = cMgr.create(pstuser);
				o.setAttribute("Creator", creator);
				o.setAttribute("Name", pj.getDisplayName());
				o.setAttribute("ProjectID", String.valueOf(ids[i]));
				o.setAttribute("CreatedDate", today);
				cMgr.commit(o);
				System.out.println("Created chat for [" + ids[i] + "]");
			}
			else {
				System.out.println("chat room already exist [" + ids[i] + "]");
			}
		} else {
			System.out.println("creator is null [" + ids[i] + "]");
		}
	}


	// delete projTemplate
	ids = pjtMgr.findId(pstuser, "om_acctname='%@@%'");
	PstAbstractObject [] oArr1 = pjtMgr.get(pstuser, ids);
	for (int i=0; i<oArr1.length; i++) {
		o = oArr1[i];
		s = o.getObjectName();
		s = s.substring(0, s.indexOf("@@"));
		o.setObjectName(s);
		pjtMgr.commit(o);
	}
	

	// force one-time archiving
	// archive
	//if (PrmArchive.archive(true) < 0)					// force archive immediately
	//	System.out.println("error in archiving!!!");
		
	// delete garbage user account
	ids = uMgr.findId(pstuser, "om_acctname='%http:%'");
	for (int i=0; i<ids.length; i++) {
		o = uMgr.get(pstuser, ids[i]);
		System.out.println("remove user [" + o.getObjectId() + "]");
		//uMgr.delete(o);
	}


	// clean up town
	ids = tnMgr.findId(pstuser, "om_acctname!='HKU-SZH' && om_acctname!='EGI' && om_acctname!='GHBD'");
	for (int i=0; i<ids.length; i++) {
		o = tnMgr.get(pstuser, ids[i]);
		System.out.println("del town [" + o.getObjectName() + "]");
		tnMgr.delete(o);
	}
*/

	response.sendRedirect("admin.jsp"); // default
%>
