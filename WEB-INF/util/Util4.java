//
//  Copyright (c) 2010, EGI Technologies.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   Util4.java
//  Author:
//  Date:   06/15/2010
//  Description:
//
/////////////////////////////////////////////////////////////////////
//
// Util4.java : implementation of the Util4 class for PRM
//
package util;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;

import javax.activation.DataSource;

import oct.codegen.action;
import oct.codegen.actionManager;
import oct.codegen.bug;
import oct.codegen.bugManager;
import oct.codegen.phase;
import oct.codegen.phaseManager;
import oct.codegen.project;
import oct.codegen.projectManager;
import oct.codegen.task;
import oct.codegen.taskManager;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.codegen.phase.PhaseInfo;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstGuest;
import oct.pst.PstUserAbstractObject;

import org.apache.log4j.Logger;
import org.apache.soap.util.mime.ByteArrayDataSource;
import org.jfree.chart.ChartFactory;
import org.jfree.chart.ChartUtilities;
import org.jfree.chart.JFreeChart;
import org.jfree.data.general.DefaultPieDataset;


public class Util4 {
	final static String HOST = Util.getPropKey("pst", "PRM_HOST");
	final static String FROM = Util.getPropKey("pst", "FROM");

	final static String format = "MM/dd/yy";
	final static SimpleDateFormat df1 = new SimpleDateFormat (format);
	final static SimpleDateFormat df2 = new SimpleDateFormat ("MM/dd/yyyy");
	final static SimpleDateFormat df3 = new SimpleDateFormat ("MM/dd/yyyy");

	final static int IMG_WIDTH		= 400;
	final static int IMG_HEIGHT		= 300;
	final static int TOTAL_CHARTS	= 5;

	static int IMAGE_IDX			= 0;	// index for image reference
	static int IMAGE_CNT			= 0;	// index for image array
	
	final static String BAR_HEIGHT = "15";
	final static String BAR_COLOR_DONE = "#47C3F2";	// #0033bb
	final static String BAR_COLOR_LATE = "#FD447E";	// #dd0000
	final static String BAR_COLOR_OPEN = "#CCCCCC";

	static Logger l = PrmLog.getLog();

	private static userManager 			uMgr;
	private static projectManager		pjMgr;
	private static taskManager			tkMgr;
	private static actionManager		acMgr;
	private static bugManager			bugMgr;
	private static phaseManager			phMgr;

	static {
		l = PrmLog.getLog();

		try {
			uMgr	= userManager.getInstance();
			pjMgr	= projectManager.getInstance();
			tkMgr	= taskManager.getInstance();
			acMgr	= actionManager.getInstance();
			bugMgr	= bugManager.getInstance();
			phMgr	= phaseManager.getInstance();
		} catch (PmpException e) {
			l.error("Util4 failed to init managers. " + e.getMessage());
		}
	}

	public static boolean sendReport(
		PstUserAbstractObject pstuser, int projId, String userList)
	throws Exception
	{
		// send report to a group of people
		project pjObj = (project)pjMgr.get(pstuser, projId);
		String projName = pjObj.getDisplayName();
		String subject = "[" + Prm.getAppTitle() + "] " + projName
							+ " - Status Update (" + df2.format(new Date()) + ")";
		String s;

		if (userList == null) {
			// the recipient list is in the project object
			userList = Util2.getAttributeString(pjObj, "Attendee", ",");
			if (userList.length() <= 0) {
				return false;		// no recipient, don't send
			}
		}
		l.info("PrmReport.sendReport() constructing report for [" + projName + "]");

		IMAGE_IDX = 0;
		IMAGE_CNT = 0;


		///////////////////////////////////////////////////////////////////////////////////////
		// construct the page for report
		StringBuffer sBuf = new StringBuffer(8192);
		DataSource [] dsArr = new DataSource[TOTAL_CHARTS];
		project projObj = (project) pjMgr.get(pstuser, projId);

		sBuf.append("<H3>Project Status Report on " + projName + "</H3>");

		///////////////////////////////////////////////////////////////////////////////////////
		// Executive Summary
		///////////////////////////////////////////////////////////////////////////////////////

		sBuf.append("<table width='100%' border='0' cellspacing='0' cellpadding='0'>");
		sBuf.append("<tr><td class='heading'><H4>Executive Summary</H4></td></tr>");

		boolean found = false;

		//s = (String)projObj.getAttribute("Option")[0];
		String summaryTaskId = projObj.getOption(project.EXEC_SUMMARY);
		if (summaryTaskId != null)
		{
			// SUMMARY_ID:12345
			// the summary id is actually the TaskId
			sBuf.append("<tr><td>");
			String outStr = Util.showLastBlog(pstuser, String.valueOf(projId),
					summaryTaskId, "Task", null, "100%", -1);
			if (outStr.length() > 0)
			{
				sBuf.append(outStr);
				found = true;
			}
			sBuf.append("</td></tr>");
		}

		if (!found) {
			sBuf.append("<tr><td class='plaintext_grey'>&nbsp;&nbsp;" +
					"No executive summary</td></tr>");
		}
		sBuf.append("</table>");
		// END Executive Summary

		sBuf.append("<br><br>");

		///////////////////////////////////////////////////////////////////////////////////////
		// project time bar
		///////////////////////////////////////////////////////////////////////////////////////
		int INIT_SPACING = 80;				// leading spacing for dots
		int Y_POSITION	 = 250;				// y-coordinate for the dots (242)
		int maxPhases = getMaxPhases();
		PhaseInfo [] phaseArr = new PhaseInfo[maxPhases];
		int [] intArr = new int [5];		// see order below
		String [] sArr = new String [3];	// see order below
		boolean bReverseSizeFactor = Util4.prepareTimebarValues(projObj, intArr, sArr);
		int projLength = intArr[0];
		int daysElapsed = intArr[1];
		int daysLeft = intArr[2];
		int daysLate = intArr[3];
		int sizeFactor = intArr[4];
		sBuf.append(Util4.showProjectTimeBar(pstuser, String.valueOf(projId),
				phaseArr,									// will get filled in the call
				sizeFactor, bReverseSizeFactor, false,
				projLength, daysLate, daysElapsed, daysLeft,
				INIT_SPACING, Y_POSITION, true));

		///////////////////////////////////////////////////////////////////////////////////////
		// phases in table
		///////////////////////////////////////////////////////////////////////////////////////
		showPhaseTable(sBuf, phaseArr);
		sBuf.append("<br><br>");

		///////////////////////////////////////////////////////////////////////////////////////
		// bug
		///////////////////////////////////////////////////////////////////////////////////////
		addBugGraphs(pstuser, pjObj, sBuf, dsArr);


		///////////////////////////////////////////////////////////////////////////////////////
		// action item
		///////////////////////////////////////////////////////////////////////////////////////
		addActionGraphs(pstuser, pjObj, sBuf, dsArr);


	    ///////////////////////////////////////////////////////////////////////////////
	    // Send Email
		String alertMsg = sBuf.toString();
		String [] toArr = null;
		user uObj;
		int ct;

		if (userList != null)
		{
			String [] sa = userList.split("(,|;)");		// List of user Ids  (12345,22222 ...)
			toArr = new String[sa.length];
			for (ct=0; ct<sa.length; ct++)
			{
				s = sa[ct].trim();
				if (s.length()==0) continue;

				uObj = (user)uMgr.get(pstuser, Integer.parseInt(s));
				toArr[ct] = (String)uObj.getAttribute("Email")[0];
			}
		}

		Util.sendMailAsyn(pstuser, FROM, toArr, null, FROM, subject,
			alertMsg, "alert.htm", dsArr);

		return true;		// done sending report
	}	// END: sendReport()


	private static void addBugGraphs(
		PstUserAbstractObject pstuser, project pjObj,
		StringBuffer sBuf, DataSource [] dsArr)
	throws Exception
	{
		int [] ids;
		int iOpen;
		int ii;

	    user uObj;
		String bgcolor="";
		boolean even = true;
		String s;

		///////////////////////////////////////////////////////////////////////////////////////
		// bug report
		///////////////////////////////////////////////////////////////////////////////////////

		int projId = pjObj.getObjectId();
		String projName = pjObj.getDisplayName();

		String exprPj = "ProjectID='" + projId + "' ";

		// 1. bug status (new, active, fixed, closed)
		int iTotal0 = 0;
		DefaultPieDataset pieDataset = new DefaultPieDataset();
		ids = bugMgr.findId(pstuser, exprPj + "&& State='" + bug.ACTIVE + "'");
		if (ids.length <= 0) {
			return;		// no active bug to report
		}

		ii = ids.length; iTotal0 += ii; iOpen = ii;
		pieDataset.setValue("Open", new Integer(ii));
		ids = bugMgr.findId(pstuser, exprPj
				+ "&& (State='" + bug.ANALYZED + "' || State='" + bug.FEEDBACK + "')");
		ii = ids.length; iTotal0 += ii;
		pieDataset.setValue("Fixed", new Integer(ii));
		ids = bugMgr.findId(pstuser, exprPj + "&& State='" + bug.CLOSE + "'");
		ii = ids.length; iTotal0 += ii;
		pieDataset.setValue("Closed", new Integer(ii));
		ids = bugMgr.findId(pstuser, exprPj + "&& State='" + bug.OPEN + "'");	// = New
		ii = ids.length; iTotal0 += ii;
		pieDataset.setValue("New / Unassigned", new Integer(ii));

		JFreeChart chart = ChartFactory.createPieChart
		                     ("Bug Status on " + projName,	// Title
		                      pieDataset,           		// Dataset
		                      false,                 		// Show legend
		                      true,
		                      false
		                     );
		byte[] byteImage = ChartUtilities.encodeAsPNG(chart.createBufferedImage(IMG_WIDTH, IMG_HEIGHT));
		dsArr[IMAGE_CNT++] = new ByteArrayDataSource(byteImage, "image/png");

		int iTotal1 = 0;
		int iTotal2 = 0, iDesign=0, iSW=0, iHW=0;
		if (iOpen > 0)
		{
			// 2. open bug priority
			exprPj += "&& State='" + bug.ACTIVE + "' ";
			//String [] val1 = {bug.PRI_HIGH, bug.PRI_MED, bug.PRI_LOW};
			String [] val1 = {bug.PRI_HIGH+"%", bug.PRI_MED, bug.PRI_LOW};
			String [] label1 = {"High", "Medium", "Low"};
			pieDataset = new DefaultPieDataset();
			for (int m=0; m<val1.length; m++)
			{
				ids = bugMgr.findId(pstuser, exprPj + "&& Priority='" + val1[m] + "'");
				ii = ids.length; iTotal1 += ii;
				pieDataset.setValue(label1[m], new Integer(ii));
			}

			chart = ChartFactory.createPieChart
			                     ("Open Bug Priority (" + projName + ")",	// Title
			                      pieDataset,           		// Dataset
			                      false,                 		// Show legend
			                      true,
			                      false
			                     );
			byteImage = ChartUtilities.encodeAsPNG(chart.createBufferedImage(IMG_WIDTH, IMG_HEIGHT));
			dsArr[IMAGE_CNT++] = new ByteArrayDataSource(byteImage, "image/png");

			// 3. open bug type
			// CLASS_DS, CLASS_PS, CLASS_HW, CLASS_SW, CLASS_DOC, CLASS_SP
			String [] val2 = {bug.CLASS_DS, bug.CLASS_SW, bug.CLASS_HW, bug.CLASS_DOC, bug.CLASS_SP};
			String [] label2 = {"design", "sw-bug", "hw-bug", "doc-bug", "support"};
			pieDataset = new DefaultPieDataset();
			for (int m=0; m<val2.length; m++)
			{
				ids = bugMgr.findId(pstuser, exprPj + "&& Type='" + val2[m] + "'");
				ii = ids.length; iTotal2 += ii;
				if (ii>0 && m==0) iDesign=ii;
				else if (ii>0 && m==1) iSW = ii;
				else if (ii>0 && m==2) iHW = ii;
				pieDataset.setValue(label2[m], new Integer(ii));
			}
			ii = iTotal1 - iTotal2;
			if (ii > 0) pieDataset.setValue("others", new Integer(ii));

			chart = ChartFactory.createPieChart
			                     ("Open Bug Type (" + projName + ")",	// Title
			                      pieDataset,           		// Dataset
			                      false,                 		// Show legend
			                      true,
			                      false
			                     );
			byteImage = ChartUtilities.encodeAsPNG(chart.createBufferedImage(IMG_WIDTH, IMG_HEIGHT));
			dsArr[IMAGE_CNT++] = new ByteArrayDataSource(byteImage, "image/png");
		}

		// *** evaluate the aging of the new/open bugs
	    Date dt;
	    bug bObj;

		long now = new Date().getTime();
		long	oldest=now + 3600000,	// 1 hour in the future
				youngest=0,
				avg=0;
		long age;						// age of the bug
		ids = bugMgr.findId(pstuser, "ProjectID='" + projId + "' && (State='" + bug.ACTIVE
				+ "' || State='" + bug.OPEN + "')");

		if (ids.length > 0) {
			for (int m=0; m<ids.length; m++)
			{
				// go through these bugs to find the oldest, youngest and average age
				bObj = (bug)bugMgr.get(pstuser, ids[m]);
				dt = (Date)bObj.getAttribute("CreatedDate")[0];
				age = dt.getTime();
				if (age < oldest) oldest = age;
				if (age > youngest) youngest = age;
				age = now - age;			//
				avg += age;
			}
			oldest = (now - oldest)/86400000;		// in days
			youngest = (now - youngest)/86400000;	// in days
			avg = avg/86400000/ids.length;			// in days
		}


		sBuf.append("<table border='0' cellspacing='0' cellpadding='0'>");

		// first graph on bug
		sBuf.append("<tr><td width='" + IMG_WIDTH + "'><img src='cid:prm_img" + IMAGE_IDX++ + "'></td>");

	    sBuf.append("<td><img src='" + HOST + "/i/spacer.gif' width='20'></td>");	// vertical gap

	    sBuf.append("<td width='450' valign='top'>");
	    sBuf.append("<table border='0' cellspacing='0' cellpadding='0'>");
	    sBuf.append("<tr><td colspan='2'><img src='" + HOST + "/i/spacer.gif' height='30'></td></tr>");
	    sBuf.append("<tr><td colspan='2'><hr style='margin:0; padding:0; border:0; border-top:1px solid #cc6666; height:0'></td></tr>");
	    sBuf.append("<tr><td class='plaintext' width='300'><b>Total no. of defects:</b></td><td class='plaintext' width='150'><b>" + iTotal0 + "</b></td></tr>");
	    sBuf.append("<tr><td colspan='2'><img src='" + HOST + "/i/spacer.gif' height='10'></td></tr>");
	    sBuf.append("<tr><td class='plaintext'>Average age of open defects:</td><td class='plaintext'>" + avg + " days</td></tr>");
	    sBuf.append("<tr><td class='plaintext'>The oldest open defect:</td><td class='plaintext'>" + oldest + " days</td></tr>");
	    sBuf.append("<tr><td class='plaintext'>The youngest open defect:</td><td class='plaintext'>" + youngest + " days</td></tr></table></td>");
	    sBuf.append("</tr></table>");
	    sBuf.append("</p>");


	    sBuf.append("<table border='0' cellspacing='0' cellpadding='0'>");	// table 1
	    sBuf.append("<tr><td width='" + IMG_WIDTH + "'>");
		if (iOpen > 0)
	    {
		    // two graphs on open bugs
		    sBuf.append("<img src='cid:prm_img" + IMAGE_IDX++ + "'><p>");
		    sBuf.append("<img src='cid:prm_img" + IMAGE_IDX++ + "'>");
		    sBuf.append("</td>");

		    sBuf.append("<td><img src='" + HOST + "/i/spacer.gif' width='20'></td>");

		    sBuf.append("<td width='450' valign='top'>");
		    sBuf.append("<table width='100%' border='0' cellspacing='0' cellpadding='0'>");	// table 2
		    sBuf.append("<tr><td><img src='" + HOST + "/i/spacer.gif' height='30'></td></tr>");
		    sBuf.append("<tr><td><hr style='margin:0; padding:0; border:0; border-top:1px solid #cc6666; height:0'></td></tr>");
		    sBuf.append("<tr><td class='plaintext'><b>Total no. of open defects = " + iTotal1 + "</b></td></tr>");
		    sBuf.append("<tr><td><img src='" + HOST + "/i/spacer.gif' height='10'></td></tr>");
		    sBuf.append("<tr><td class='plaintext'><b>The <font color='#ee3333'>Open </font>and <font color='#ee3333'>High Priority </font>defects are</b></td></tr>");
		    sBuf.append("<tr><td><table border='0' cellspacing='0' cellpadding='0'><tr>");	// table 3
		    sBuf.append("<td width='20'></td>");	// vertical space
		    sBuf.append("<td width='100%' class='plaintext'>");
		    sBuf.append("<table border='0' cellspacing='0' cellpadding='0'>");	// table 4

		    ids = bugMgr.findId(pstuser,"ProjectID='" + projId + "' && State='" + bug.ACTIVE
		    		+ "' && Priority='" + bug.PRI_HIGH + "'");

		    for (int m=0; m<ids.length; m++)
		    {
		    	// list the open and high priority bugs
		    	bObj = (bug)bugMgr.get(pstuser, ids[m]);

				if (even)
					bgcolor = "bgcolor='#EEEEEE'";
				else
					bgcolor = "bgcolor='#ffffff'";
				even = !even;

		    	// bugId and synopsis
			    sBuf.append("<tr " + bgcolor + "><td colspan='5'><img src='" + HOST + "/i/spacer.gif' height='10'></td></tr>");
			    sBuf.append("<tr " + bgcolor + "><td class='plaintext' colspan='5'>");
			    sBuf.append("<table width='100%' border='0' cellspacing='0' cellpadding='0'>");
			    sBuf.append("<tr><td width='45' class='listtext' valign='top'>");
			    s = "<a class='listtext' href='" + HOST + "/bug/bug_update.jsp?bugId=" + ids[m] + "'>";
			    sBuf.append(s + ids[m] + "</a></td>");
			    sBuf.append("<td class='listtext'><b>" + s
			    		+ (String)bObj.getAttribute("Synopsis")[0] + "</a>");
			    sBuf.append("</b></td></tr></table></td></tr>");

			    // submitter and owner
			    uObj = (user)uMgr.get(pstuser, Integer.parseInt((String)bObj.getAttribute("Creator")[0]));
			    sBuf.append("<tr " + bgcolor + "><td width='15'>&nbsp;</td>");
			    sBuf.append("<td class='plaintext' width='60'><b>Submitter</b></td><td class='plaintext' width='130'>:&nbsp;"
			    		+ "<a class='listtext' href='mailto:" + (String)uObj.getAttribute("Email")[0] + "'>"
			    		+ uObj.getShortName()
			    		+ "</a></td><td class='plaintext' width='60'>");
			    s = (String)bObj.getAttribute("Owner")[0];
			    if (s == null)
			    	s = "not assigned";
			    else
		    	{
			    	uObj = (user)uMgr.get(pstuser, Integer.parseInt(s));
			    	s = uObj.getShortName();
		    	}
			    sBuf.append("<b>Owner</b></td><td class='plaintext' width='110'>:&nbsp;"
			    		+ "<a class='listtext' href='mailto:" + (String)uObj.getAttribute("Email")[0] + "'>"
			    		+ s + "</a></td></tr>");

			    // type and category
			    sBuf.append("<tr " + bgcolor + "><td width='15'>&nbsp;</td>");
			    sBuf.append("<td class='plaintext'><b>Type</b></td><td class='plaintext'>:&nbsp;"
			    		+ (String)bObj.getAttribute("Type")[0] + "</td><td class='plaintext'>");
			    s = (String)bObj.getAttribute("Category")[0];
			    if (s == null) s = "none";
			    sBuf.append("<b>Category</b></td><td class='plaintext'>:&nbsp;" + s + "</td></tr>");

			    // filed on and lastUpdated
			    dt = (Date)bObj.getAttribute("CreatedDate")[0];
			    sBuf.append("<tr " + bgcolor + "><td width='15'>&nbsp;</td>");
			    sBuf.append("<td class='plaintext'><b>Filed on</b></td><td class='plaintext'>:&nbsp;"
			    		+ df1.format(dt) + "</td><td class='plaintext'>");
			    dt = (Date)bObj.getAttribute("LastUpdatedDate")[0];
			    if (dt != null) s = df1.format(dt);
			    else s = "-";
			    sBuf.append("<b>Last Updated</b></td><td class='plaintext'>:&nbsp;" + s + "</td></tr>");

			    sBuf.append("<tr " + bgcolor + "><td colspan='5'><img src='" + HOST + "/i/spacer.gif' height='5'></td></tr>");
		    }
		    sBuf.append("</table></td>");			// table 4
		    sBuf.append("</tr></table></td></tr>");	// table 3
		    sBuf.append("<tr><td><img src='" + HOST + "/i/spacer.gif' height='20'></td></tr>");
	    }	// end if (iOpen>0)
		else
		{
		    sBuf.append("</td>");
		    sBuf.append("<td><img src='" + HOST + "/i/spacer.gif' width='20'></td>");
		    sBuf.append("<td width='450' valign='top'>");
		    sBuf.append("<table width='100%' border='0' cellspacing='0' cellpadding='0'>");	// else table 2
		}

	    // go to PRM for more review
	    sBuf.append("<tr><td><hr style='margin:0; padding:0; border:0; border-top:1px solid #cc6666; height:0'></td></tr>");
	    sBuf.append("<tr><td class='plaintext'><b>Go to " + Prm.getAppTitle() + " to review ...</b></td></tr>");

	    //  goto high priority open/active bugs
	    sBuf.append("<tr><td><img src='" + HOST + "/i/spacer.gif' height='10'></td></tr>");
	    sBuf.append("<tr><td><img src='" + HOST + "/i/bullet_tri.gif'>&nbsp;");
	    sBuf.append("<a class='listtext' href='" + HOST + "/bug/bug_search.jsp?projId=" + projId + "&open=on&active=on&high=on'>");
	    sBuf.append("High priority new/open defects</a>");
	    sBuf.append("</td></tr>");

	    // goto design-bug
	    if (iDesign > 0)
	    {
		    sBuf.append("<tr><td><img src='" + HOST + "/i/spacer.gif' height='5'></td></tr>");
		    sBuf.append("<tr><td><img src='" + HOST + "/i/bullet_tri.gif'>&nbsp;");
		    sBuf.append("<a class='listtext' href='" + HOST + "/bug/bug_search.jsp?projId=" + projId + "&open=on&active=on&design-bug=on&sortby=pr'>");
		    sBuf.append("Design new/open defects</a>");
		    sBuf.append("</td></tr>");
	    }

	    // goto sw-bug
	    if (iSW > 0)
	    {
		    sBuf.append("<tr><td><img src='" + HOST + "/i/spacer.gif' height='5'></td></tr>");
		    sBuf.append("<tr><td><img src='" + HOST + "/i/bullet_tri.gif'>&nbsp;");
		    sBuf.append("<a class='listtext' href='" + HOST + "/bug/bug_search.jsp?projId=" + projId + "&open=on&active=on&sw-bug=on&sortby=pr'>");
		    sBuf.append("Software new/open defects</a>");
		    sBuf.append("</td></tr>");
	    }

	    // goto sw-bug
	    if (iHW > 0)
	    {
		    sBuf.append("<tr><td><img src='" + HOST + "/i/spacer.gif' height='5'></td></tr>");
		    sBuf.append("<tr><td><img src='" + HOST + "/i/bullet_tri.gif'>&nbsp;");
		    sBuf.append("<a class='listtext' href='" + HOST + "/bug/bug_search.jsp?projId=" + projId + "&open=on&active=on&hw-bug=on&sortby=pr'>");
		    sBuf.append("Hardware new/open defects</a>");
		    sBuf.append("</td></tr>");
	    }

	    sBuf.append("</table>");			// table 2
	    sBuf.append("</td></tr></table>");	// table 1

	}	// END: addBugGraphs()


	static void addActionGraphs(
		PstUserAbstractObject pstuser, project pjObj,
		StringBuffer sBuf, DataSource [] dsArr)
	throws Exception
	{
		int ii;
		int [] ids;
		int iOpen;
		long oldest, youngest, avg, age;
		int iTotal0 = 0;
		int iTotal1 = 0;
	    Date dt;
		String bgcolor="";
		boolean even = true;
		String s;

		user uObj;

		int projId = pjObj.getObjectId();
		String projName = pjObj.getDisplayName();

		// 1. action item status
		String exprAc = "ProjectID='" + projId + "' ";
		String [] vala1 = {action.LATE, action.OPEN, action.DONE, action.CANCEL};
		DefaultPieDataset pieDataset = new DefaultPieDataset();

		for (int m=0; m<vala1.length; m++)
		{
			ids = acMgr.findId(pstuser, exprAc + "&& Status='" + vala1[m] + "'");
			ii = ids.length; iTotal0 += ii;
			pieDataset.setValue(vala1[m], new Integer(ii));
		}

		if (iTotal0 <= 0) {
			return;		// nothing to report
		}

		JFreeChart chart = ChartFactory.createPieChart
		                     ("Action Item Status on " + projName,	// Title
		                      pieDataset,           		// Dataset
		                      false,                 		// Show legend
		                      true,
		                      false
		                     );
		byte[] byteImage = ChartUtilities.encodeAsPNG(chart.createBufferedImage(IMG_WIDTH, IMG_HEIGHT));
		dsArr[IMAGE_CNT++] = new ByteArrayDataSource(byteImage, "image/png");

		// 2. open and late AC priority
		exprAc += "&& Status!='" + action.CANCEL + "' && Status!='" + action.DONE + "' ";

		// first ensure there are some open/late actions
		ids = acMgr.findId(pstuser, exprAc);
		iOpen = ids.length;
		int iHigh = 0;			// high priority, open/late
		int iHighLate = 0;		// high priority, late

		if (iOpen > 0)
		{
			String [] vala2 = {action.PRI_HIGH, action.PRI_MED, action.PRI_LOW};
			String [] labela2 = {"High", "Medium", "Low"};
			iTotal1 = 0;
			pieDataset = new DefaultPieDataset();
			for (int m=0; m<vala2.length; m++)
			{
				ids = acMgr.findId(pstuser, exprAc + "&& Priority='" + vala2[m] + "'");
				ii = ids.length; iTotal1 += ii;
				if (m==0) iHigh = ii;
				pieDataset.setValue(labela2[m], new Integer(ii));
			}

			chart = ChartFactory.createPieChart
			                     ("Open/Late Action Item Priority (" + projName + ")",	// Title
			                      pieDataset,           		// Dataset
			                      false,                 		// Show legend
			                      true,
			                      false
			                     );
			byteImage = ChartUtilities.encodeAsPNG(chart.createBufferedImage(IMG_WIDTH, IMG_HEIGHT));
			dsArr[IMAGE_CNT++] = new ByteArrayDataSource(byteImage, "image/png");
		}

		// *** evaluate the aging of the open/late action items
		long now = new Date().getTime();
		oldest=now + 3600000;	// 1 hour in the future
		youngest=0;
		avg=0;
		action aObj;

		ids = acMgr.findId(pstuser, "ProjectID='" + projId + "' && (Status='" + action.LATE
				+ "' || Status='" + action.OPEN + "')");
		for (int m=0; m<ids.length; m++)
		{
			// go through these bugs to find the oldest, youngest and avg age
			aObj = (action)acMgr.get(pstuser, ids[m]);
			dt = (Date)aObj.getAttribute("CreatedDate")[0];
			age = dt.getTime();
			if (age < oldest) oldest = age;
			if (age > youngest) youngest = age;
			age = now - age;			//
			avg += age;
		}
		oldest = (ids.length>0)?(now - oldest)/86400000:0;		// in days
		youngest = (ids.length>0)?(now - youngest)/86400000:0;	// in days
		avg = (ids.length>0)?avg/86400000/ids.length:0;			// in days


		////////////////////////////////////
	    // construct page for action item
	    sBuf.append("<p>");
		sBuf.append("<table border='0' cellspacing='0' cellpadding='0'>");
	    sBuf.append("<tr><td colspan='3'><hr style='margin:0; padding:0; border:0; border-top:1px solid #000000; height:10' color='#999999'/></td></tr>");

		// first graph on action item
		sBuf.append("<tr><td width='" + IMG_WIDTH + "'><img src='cid:prm_img" + IMAGE_IDX++ + "'></td>");

	    sBuf.append("<td><img src='" + HOST + "/i/spacer.gif' width='20'></td>");	// vertical gap

	    sBuf.append("<td width='450' valign='top'>");
	    sBuf.append("<table border='0' cellspacing='0' cellpadding='0'>");
	    sBuf.append("<tr><td colspan='2'><img src='" + HOST + "/i/spacer.gif' height='30'></td></tr>");
	    sBuf.append("<tr><td colspan='2'><hr style='margin:0; padding:0; border:0; border-top:1px solid #cc6666; height:0'></td></tr>");
	    sBuf.append("<tr><td class='plaintext' width='300'><b>Total no. of action items:</b></td><td class='plaintext' width='150'><b>" + iTotal0 + "</b></td></tr>");
	    sBuf.append("<tr><td colspan='2'><img src='" + HOST + "/i/spacer.gif' height='10'></td></tr>");
	    sBuf.append("<tr><td class='plaintext'>Average age of open/late actions:</td><td class='plaintext'>" + avg + " days</td></tr>");
	    sBuf.append("<tr><td class='plaintext'>The oldest open/late actions:</td><td class='plaintext'>" + oldest + " days</td></tr>");
	    sBuf.append("<tr><td class='plaintext'>The youngest open/late actions:</td><td class='plaintext'>" + youngest + " days</td></tr></table></td>");
	    sBuf.append("</tr></table>");
	    sBuf.append("</p>");


	    sBuf.append("<table border='0' cellspacing='0' cellpadding='0'>");	// table 1
	    sBuf.append("<tr><td width='" + IMG_WIDTH + "' valign='top'>");
	    if (iOpen > 0)
	    {
		    // second graphs on open/late action item priority
		    sBuf.append("<img src='cid:prm_img" + IMAGE_IDX++ + "'>");
		    sBuf.append("</td>");

		    sBuf.append("<td><img src='" + HOST + "/i/spacer.gif' width='20'></td>");

		    sBuf.append("<td width='450' valign='top'>");
		    sBuf.append("<table width='100%' border='0' cellspacing='0' cellpadding='0'>");	// table 2
		    sBuf.append("<tr><td><img src='" + HOST + "/i/spacer.gif' height='30'></td></tr>");
		    sBuf.append("<tr><td><hr style='margin:0; padding:0; border:0; border-top:1px solid #cc6666; height:0'></td></tr>");
		    sBuf.append("<tr><td class='plaintext'><b>Total no. of open/late action items = " + iTotal1 + "</b></td></tr>");
		    sBuf.append("<tr><td><img src='" + HOST + "/i/spacer.gif' height='10'></td></tr>");
		    sBuf.append("<tr><td class='plaintext'><b>The <font color='#ee3333'>High Priority Overdue </font>action items are:</b></td></tr>");
		    sBuf.append("<tr><td><table border='0' cellspacing='0' cellpadding='0'><tr>");	// table 3
		    sBuf.append("<td width='20'></td>");	// vertical space
		    sBuf.append("<td width='100%' class='plaintext'>");
		    sBuf.append("<table border='0' cellspacing='0' cellpadding='0'>");	// table 4

		    ids = acMgr.findId(pstuser, "ProjectID='" + projId + "' && Status='" + action.LATE
		    		+ "' && Priority='" + action.PRI_HIGH + "'");
		    iHighLate = ids.length;

			even = true;
		    for (int m=0; m<iHighLate; m++)
		    {
		    	// list the late and high priority action items
		    	aObj = (action)acMgr.get(pstuser, ids[m]);

				if (even)
					bgcolor = "bgcolor='#EEEEEE'";
				else
					bgcolor = "bgcolor='#ffffff'";
				even = !even;

		    	// action item ID and subject
			    sBuf.append("<tr " + bgcolor + "><td colspan='5'><img src='" + HOST + "/i/spacer.gif' height='10'></td></tr>");
			    sBuf.append("<tr " + bgcolor + "><td class='plaintext' colspan='5'>");
			    sBuf.append("<table width='100%' border='0' cellspacing='0' cellpadding='0'>");
			    sBuf.append("<tr><td width='45' class='listtext' valign='top'>");
			    s = "<a class='listtext' href='" + HOST + "/project/proj_action.jsp?projId=" + projId + "&aid=" + ids[m] + "&FilterStatus=OpenLate'>";
			    sBuf.append(s + ids[m] + "</a></td>");
			    sBuf.append("<td class='listtext'><b>" + s
			    		+ (String)aObj.getAttribute("Subject")[0] + "</a>");
			    sBuf.append("</b></td></tr></table></td></tr>");

			    // coordinator
			    s = (String)aObj.getAttribute("Owner")[0];
			    uObj = (user)uMgr.get(pstuser, Integer.parseInt(s));
			    sBuf.append("<tr " + bgcolor + "><td width='15'>&nbsp;</td>");
			    sBuf.append("<td class='plaintext' width='60'><b>Coordinator</b></td><td class='plaintext' width='130'>:&nbsp;"
			    		+ "<a class='listtext' href='mailto:" + (String)uObj.getAttribute("Email")[0] + "'>"
			    		+ uObj.getShortName() + "</a></td>");
			    sBuf.append("<td class='plaintext' width='60'>&nbsp;</td>");
			    sBuf.append("<td class='plaintext' width='110'>&nbsp;</td></tr>");

			    // responsible
			    Object [] oArr = aObj.getAttribute("Responsible");
			    if (oArr.length>0 && oArr[0]!=null && !(oArr.length==1 && s.equals(oArr[0])) )
			    {
				    sBuf.append("<tr " + bgcolor + "><td width='15'>&nbsp;</td>");
				    sBuf.append("<td class='plaintext'><b>Responsible</b></td>");
				    sBuf.append("<td colspan='3' class='plaintext'>:&nbsp;");
				    for (int n=0; n < oArr.length; n++)
				    {
				    	s = (String)oArr[n];
				    	if (s == null) break;
				    	if (n>0) sBuf.append(", ");
				    	uObj = (user)uMgr.get(pstuser, Integer.parseInt(s));
			    		sBuf.append("<a class='listtext' href='mailto:" + (String)uObj.getAttribute("Email")[0] + "'>");
				    	sBuf.append(uObj.getShortName() + "</a>");
				    }
				    sBuf.append("</td></tr>");
			    }

			    // filed on and deadline
			    dt = (Date)aObj.getAttribute("CreatedDate")[0];
			    sBuf.append("<tr " + bgcolor + "><td width='15'>&nbsp;</td>");
			    sBuf.append("<td class='plaintext'><b>Filed on</b></td><td class='plaintext'>:&nbsp;"
			    		+ df1.format(dt) + "</td><td class='plaintext'>");
			    dt = (Date)aObj.getAttribute("ExpireDate")[0];
			    if (dt != null) s = df1.format(dt);
			    else s = "-";
			    sBuf.append("<b>Deadline</b></td><td class='plaintext'>:&nbsp;" + s + "</td></tr>");

			    sBuf.append("<tr " + bgcolor + "><td colspan='5'><img src='" + HOST + "/i/spacer.gif' height='5'></td></tr>");
		    }
		    sBuf.append("</table></td>");			// table 4
		    sBuf.append("</tr></table></td></tr>");	// table 3
		    sBuf.append("<tr><td><img src='" + HOST + "/i/spacer.gif' height='20'></td></tr>");
	    }	// end if (iOpen > 0)
	    else
	    {
		    sBuf.append("</td>");
		    sBuf.append("<td><img src='" + HOST + "/i/spacer.gif' width='20'></td>");
		    sBuf.append("<td width='450' valign='top'>");
		    sBuf.append("<table width='100%' border='0' cellspacing='0' cellpadding='0'>");	// else table 2
	    }

	    // go to PRM for more review
	    sBuf.append("<tr><td><hr style='margin:0; padding:0; border:0; border-top:1px solid #cc6666; height:0'></td></tr>");
	    sBuf.append("<tr><td class='plaintext'><b>Go to " + Prm.getAppTitle() + " to review ...</b></td></tr>");

	    //  goto high priority open/late action
	    if (iHighLate > 0)
	    {
		    sBuf.append("<tr><td><img src='" + HOST + "/i/spacer.gif' height='10'></td></tr>");
		    sBuf.append("<tr><td><img src='" + HOST + "/i/bullet_tri.gif'>&nbsp;");
		    sBuf.append("<a class='listtext' href='" + HOST + "/project/proj_action.jsp?projId=" + projId + "&FilterStatus=Late&FilterPriority=high'>");
		    sBuf.append("High priority late action items</a>");
		    sBuf.append("</td></tr>");
	    }

	    // goto high priority open/late action
	    if (iHigh > 0)
	    {
		    sBuf.append("<tr><td><img src='" + HOST + "/i/spacer.gif' height='5'></td></tr>");
		    sBuf.append("<tr><td><img src='" + HOST + "/i/bullet_tri.gif'>&nbsp;");
		    sBuf.append("<a class='listtext' href='" + HOST + "/project/proj_action.jsp?projId=" + projId + "&FilterStatus=LateOpen&FilterPriority=high'>");
		    sBuf.append("High priority open/late action items</a>");
		    sBuf.append("</td></tr>");
	    }

	    // goto all open/late action
	    if (iOpen > 0)
	    {
		    sBuf.append("<tr><td><img src='" + HOST + "/i/spacer.gif' height='5'></td></tr>");
		    sBuf.append("<tr><td><img src='" + HOST + "/i/bullet_tri.gif'>&nbsp;");
		    sBuf.append("<a class='listtext' href='" + HOST + "/project/proj_action.jsp?projId=" + projId + "&FilterStatus=LateOpen'>");
		    sBuf.append("All open/late action items</a>");
		    sBuf.append("</td></tr>");
	    }

	    // goto all action items
	    if (iTotal0 > 0)
	    {
		    sBuf.append("<tr><td><img src='" + HOST + "/i/spacer.gif' height='5'></td></tr>");
		    sBuf.append("<tr><td><img src='" + HOST + "/i/bullet_tri.gif'>&nbsp;");
		    sBuf.append("<a class='listtext' href='" + HOST + "/project/proj_action.jsp?projId=" + projId + "'>");
		    sBuf.append("All action items</a>");
		    sBuf.append("</td></tr>");
	    }

	    sBuf.append("</table>");			// table 2
	    sBuf.append("</td></tr></table>");	// table 1

	}	// END: addActionGraphs()

	public static String showProjectPercentageBar(project pjObj)
		throws PmpException
	{
		int [] intArr = new int [5];		// projLen, elapse, left, late, sizeFactor
		String [] sArr = new String [3];	// not use
		StringBuffer sBuf = new StringBuffer(4096);
		
		Util4.prepareTimebarValues(pjObj, intArr, sArr);
		int projLength = intArr[0];
		int daysElapsed = intArr[1];
		int daysLeft = intArr[2];
		int daysLate = intArr[3];
		if (daysElapsed > projLength) daysElapsed = projLength;
		//System.out.println("len=" + projLength + ", elapse=" + daysElapsed + ", left=" + daysLeft + ", late=" + daysLate);

		int perElapsed = daysElapsed * 100 / projLength;
		int perLeft    = 100-perElapsed; //daysLeft * 100 / projLength;
		int perLate    = daysLate * 100 / projLength;
		int elapsedLength=0, leftLength=0, lateLength=0;
		
		sBuf.append("<table border='0' cellpadding='0' cellspacing='0'>");
		sBuf.append("<tr><td><img src='" + HOST + "/i/spacer.gif' border='0' width='70' height='1'/></td>");
		sBuf.append("<td class='bar' width='48' align='right'>Days:&nbsp;&nbsp;</td>");
		sBuf.append("<td align='left' width='900'>");
		sBuf.append("<table border='0' cellpadding='0' cellspacing='1'><tr>");

		// display the percentage BAR
		int sizeFactor = 4;
		if (daysElapsed > 0) {
			// time elapsed
			int d = 0;
			if (daysElapsed <= projLength)
				d = daysElapsed;
			else {
				d = projLength;		// max
			}
			elapsedLength = perElapsed * sizeFactor;
			sBuf.append("<td><img src='" + HOST + "/i/spacer.gif' width='5' height='1' border='0'></td>");

			sBuf.append("<td class='bar' bgcolor='" + BAR_COLOR_DONE + "' height='" + BAR_HEIGHT + "' width='"
				+ elapsedLength + "' align='center'><img src='" + HOST + "/i/spacer.gif' border='0'><font color='white'>"
				+ String.format("%,d", d) + "</font></td>");
		}
		if (daysLeft > 0)
		{
			// days left
			leftLength = perLeft * sizeFactor;
			sBuf.append("<td class='bar' bgcolor='" + BAR_COLOR_OPEN + "' height='" + BAR_HEIGHT + "' width='"
				+ leftLength +"' align='center'><img src='" + HOST + "/i/spacer.gif' border='0'>"
				+ String.format("%,d", daysLeft) + "</td>");
		}
		else if (daysLate > 0)
		{
			lateLength = perLate * sizeFactor;
			if (lateLength > 200) lateLength = 200;		// should show a broken bar to indicate too long
			sBuf.append("<td><img src='../i/spacer.gif' width='5'/></td>");
			sBuf.append("<td class='bar' bgcolor='" + BAR_COLOR_LATE + "' height='" + BAR_HEIGHT + "' width='"
				+ lateLength + "' align='center'><img src='" + HOST + "/i/spacer.gif' border='0'><font color='white'>"
				+ String.format("%,d", daysLate) + "</font></td>");
		}

		sBuf.append("</tr></table></td></tr>");
		
		// display the percentage numbers
		sBuf.append("<tr><td colspan='2'></td>");
		sBuf.append("<td><table><tr>");
		if (elapsedLength > 0) {
			if (perElapsed > 60) elapsedLength -= 30;
			else elapsedLength -= 10;
			if (elapsedLength > 0)
				sBuf.append("<td><img src='" + HOST + "/i/spacer.gif' width='" + elapsedLength + "' height='1'/></td>");
			sBuf.append("<td class='bar'>" + String.format("%,d", perElapsed) + "%</td>");
		}
		if (leftLength > 0) {
			if (perElapsed > 60) leftLength -= 20;
			else leftLength -= 50;
			if (leftLength > 0)
				sBuf.append("<td><img src='" + HOST + "/i/spacer.gif' width='" + leftLength + "' height='1'/></td>");
			sBuf.append("<td class='bar'>" + String.format("%,d", perLeft) + "%</td>");
		}
		if (lateLength > 0) {
			lateLength -= 30;
			if (lateLength > 0)
				sBuf.append("<td><img src='" + HOST + "/i/spacer.gif' width='" + lateLength + "' height='1'/></td>");
			sBuf.append("<td class='bar'>" + String.format("%,d", perLate) + "%</td>");
		}
		sBuf.append("</tr></table></td></tr>");
		
		sBuf.append("</table>");	// END the whole table
		return sBuf.toString();
	}

	/**
	 * return the HTML string to display the project timeline bar.
	 * @param u
	 * @param projIdS
	 * @param phaseArr
	 * @param sizeFactor
	 * @param bReverseSizeFactor
	 * @param updateOK
	 * @param projLength
	 * @param daysLate
	 * @param daysElapsed
	 * @param daysLeft
	 * @param INIT_SPACING
	 * @param Y_POSITION
	 * @param isEmail
	 * @return
	 * @throws PmpException
	 * @throws ParseException
	 */
	public static String showProjectTimeBar(
			PstUserAbstractObject u, String projIdS,
			PhaseInfo [] phaseArr,
			int sizeFactor, boolean bReverseSizeFactor, boolean updateOK,
			int projLength, int daysLate, int daysElapsed, int daysLeft,
			int INIT_SPACING, int Y_POSITION,
			boolean isEmail)
		throws PmpException, ParseException
	{
		StringBuffer sBuf = new StringBuffer(8192);
		String hostDes;
		if (isEmail) {
			hostDes = HOST;
		}
		else {
			hostDes = "..";
		}

		project projObj = (project)pjMgr.get(u, Integer.parseInt(projIdS));
		boolean isContainer = projObj.isContainer();
		Date pjStartDt = projObj.getStartDate();
		Date pjCompDt = projObj.getCompleteDate();
		Date pjExpireDt = projObj.getExpireDate();

		sBuf.append("<table border='0' cellpadding='0' cellspacing='0'>");
		sBuf.append("<tr><td width='20'><img src='" + hostDes + "/i/spacer.gif' border='0'></td>");
		sBuf.append("<td class='bar' width='48' align='right'>Weeks:&nbsp;&nbsp;</td>");
		sBuf.append("<td align='left' width='900'>");
		sBuf.append("<table border='0' cellpadding='0' cellspacing='1'><tr>");

		// displaying the # of weeks
		int wwGap	= 5;			// default to display every 5 weeks
		int ii = (projLength + daysLate) / 7;		// total # of weeks
		int projBegEndGap = 0;

		// I don't want to display too many weeks number otherwise would be too crowded
		while (ii/wwGap > 20) wwGap += 5;
		int gap = wwGap * 14;

		if (!bReverseSizeFactor) {
			//gap = (gap-1)*sizeFactor;
			gap = wwGap * 7 * sizeFactor;
		}
		else {
			wwGap *= sizeFactor;
			gap = wwGap*7/sizeFactor;
			//gap = gap/(sizeFactor-1)-1;
		}
		if (!updateOK) {
			// need to do this adjustment because in HTML dots/image dimension starts from LEFT
			sBuf.append("<td><img src='" + hostDes + "/i/spacer.gif' width='10' height='1' border='0'></td>");
		}

		/*
		System.out.println("-----");
		System.out.println("projLen="+projLength);
		System.out.println("ii="+ii);
		System.out.println("wwGap="+wwGap);
		System.out.println("gap="+gap);
		System.out.println("sizeFac="+sizeFactor);
		System.out.println("reverse="+bReverseSizeFactor);
		System.out.println("elapsed="+daysElapsed+", left="+daysLeft+", late="+daysLate);
		*/
		// now display the # of weeks
		int cnt = wwGap-1;
		for (int i=0; i<ii; i++) {
			if (cnt++ != wwGap-1) continue;
			cnt = 0;
			sBuf.append("<td class='barDigit' height='" + BAR_HEIGHT + "' width='"
				+ gap + "'>" + i + "</td>");
		}

		sBuf.append("</tr></table></td></tr>");
		sBuf.append("<tr><td class='bar' width='20'><img src='" + hostDes + "/i/spacer.gif' border='0'></td>");
		sBuf.append("<td class='bar' width='48' align='right'>Days:&nbsp;&nbsp;</td>");
		sBuf.append("<td align='left' width='900'>");
		sBuf.append("<table border='0' cellpadding='0' cellspacing='1'><tr>");

		// display the time BAR
		if (daysElapsed > 0)
		{
			int d = 0;
			if (daysElapsed <= projLength)
				d = daysElapsed;
			else {
				d = projLength;
			}
			if (!bReverseSizeFactor) ii = d * sizeFactor;
			else ii = d / sizeFactor;
			if (ii<15) ii=15;
			if (!updateOK) {
				// need to do this adjustment because in HTML dots/image dimension starts from LEFT
				sBuf.append("<td><img src='" + hostDes + "/i/spacer.gif' width='5' height='1' border='0'></td>");
			}
			sBuf.append("<td class='bar' bgcolor='" + BAR_COLOR_DONE + "' height='" + BAR_HEIGHT + "' width='"
				+ ii + "' align='center'><img src='" + hostDes + "/i/spacer.gif' border='0'><font color='white'>"
				+ showDayString(d) + "</font></td>");
			projBegEndGap = ii;
		}
		if (!isContainer) {
			if (daysLeft > 0) {
				if (!bReverseSizeFactor) ii = daysLeft * sizeFactor;
				else ii = daysLeft / sizeFactor;
				if (ii<15) ii=15;
				sBuf.append("<td class='bar' bgcolor='" + BAR_COLOR_OPEN + "' height='" + BAR_HEIGHT + "' width='"
					+ ii +"' align='center'><img src='" + hostDes + "/i/spacer.gif' border='0'>"
					+ showDayString(daysLeft) + "</td>");
			}
			else if (daysLate > 0) {
				if (!bReverseSizeFactor) ii = daysLate * sizeFactor;
				else ii = daysLate / sizeFactor;
				if (ii<15) ii=15;
				sBuf.append("<td class='bar' bgcolor='" + BAR_COLOR_LATE + "' height='" + BAR_HEIGHT + "' width='"
					+ ii + "' align='center'><img src='" + hostDes + "/i/spacer.gif' border='0'><font color='white'>"
					+ showDayString(daysLate) + "</font></td>");
			}
			projBegEndGap = projLength;
			if (!bReverseSizeFactor) projBegEndGap *= sizeFactor;
			else projBegEndGap /= sizeFactor;
		}
		else {
			sBuf.append("<td class='bar'><b>&nbsp;&nbsp;. . .</b></td>");	// container continuous
		}

		sBuf.append("</tr></table></td></tr>");
		sBuf.append("<tr><td colspan='3' width='1' height='2'>");
		sBuf.append("<img src='" + hostDes + "/i/spacer.gif' border='0'></td></tr>");
		
		
		boolean bNeedSubmitButton = false;
		boolean dragOK = false;
		int maxPhases = 0;

		if (!isContainer) {					// ECC
		////////////////////////
		// Phase dots
		String dot;
		Date dt;
		maxPhases = Util4.getMaxPhases();
		int count = 0;		// actual phases present
		String s;

		task tk;
		PstAbstractObject ptk;

		// get top main phases
		PstAbstractObject [] objArr = phMgr.getPhases(u, String.valueOf(projObj.getObjectId()));
		phase ph;

		for (int i=0; i<maxPhases; i++)
		{
			phaseArr[i] = new PhaseInfo();

			if (i < objArr.length)
			{
				ph = (phase) objArr[i];
				// @110705ECC
				Object obj = ph.getAttribute(phase.TASKID)[0];
				if (obj != null)
				{
					// use task to fill the phase info
					phaseArr[i].taskId = obj.toString();
					try
					{
						tk = (task)tkMgr.get(u, phaseArr[i].taskId);
						ptk = tk.getPlanTask(u);
						obj = ph.getAttribute(phase.NAME)[0];
						if (obj == null)
							phaseArr[count].name = (String)ptk.getAttribute("Name")[0];
						else
							phaseArr[count].name = obj.toString();
						phaseArr[count].htmlName = "<a class='listlink' href='"
							+ hostDes + "/blog/blog_task.jsp?projId=" + projIdS
							+ "&planTaskId=" + ptk.getObjectId() + "'>" + phaseArr[count].name + "</a>";

						dt = (Date)tk.getAttribute("OriginalStartDate")[0];
						if (dt != null) phaseArr[count].origStartDtS = df1.format(dt);
						else phaseArr[count].origStartDtS = "-";

						dt = (Date)tk.getAttribute("OriginalExpireDate")[0];
						if (dt != null) phaseArr[count].origExpireDtS = df1.format(dt);
						else phaseArr[count].origExpireDtS = "-";

						dt = (Date)tk.getAttribute("StartDate")[0];
						if (dt != null) phaseArr[count].startDateS = df1.format(dt);
						else phaseArr[count].startDateS = "-";

						dt = (Date)tk.getAttribute("ExpireDate")[0];
						phaseArr[count].expireDateS = phase.parseDateToString(dt, format);

						//dt = (Date)tk.getAttribute(phase.PLANEXPIREDATE)[0];
						//phaseArr[count].pExpDateS = phase.parseDateToString(dt, format);

						dt = (Date)tk.getAttribute("EffectiveDate")[0];
						if (dt != null) phaseArr[count].effectiveDateS = df1.format(dt);
						else phaseArr[count].effectiveDateS = "-";

						dt = (Date)tk.getAttribute("CompleteDate")[0];
						phaseArr[count].doneDateS = phase.parseDateToString(dt, format);

						s = (String)tk.getAttribute("Status")[0];
						if (s.equals(task.ST_NEW)) s = project.PH_NEW;
						else if (s.equals(task.ST_OPEN) || s.equals(task.ST_ONHOLD)) s = project.PH_START;
						phaseArr[count].status = s;
					}
					catch (PmpException e) {
						phaseArr[count].htmlName = "<span class='tinytype'>*** Invalid task ID</span>";
						phaseArr[count].startDateS =
							phaseArr[count].effectiveDateS =
							phaseArr[count].expireDateS =
							phaseArr[count].pExpDateS =
							phaseArr[count].doneDateS =
							phaseArr[count].status = "";
					}
				}
				else
				{
					phaseArr[count].name = (String)ph.getAttribute(phase.NAME)[0];
					phaseArr[count].htmlName = "<span class='tinytype'>" + phaseArr[count].name + "</span>";

					dt = (Date)ph.getAttribute(phase.STARTDATE)[0];
					if (dt != null) phaseArr[count].startDateS = df1.format(dt);
					else phaseArr[count].startDateS = "-";

					phaseArr[count].effectiveDateS = "-";
					phaseArr[count].origExpireDtS = "-";
					phaseArr[count].origStartDtS = "-";

					dt = (Date)ph.getAttribute(phase.PLANEXPIREDATE)[0];
					phaseArr[count].pExpDateS = phase.parseDateToString(dt, format);

					dt = (Date)ph.getAttribute(phase.EXPIREDATE)[0];
					phaseArr[count].expireDateS = phase.parseDateToString(dt, format);

					dt = (Date)ph.getAttribute(phase.COMPLETEDATE)[0];
					phaseArr[count].doneDateS = phase.parseDateToString(dt, format);

					phaseArr[count].status = ph.getAttribute(phase.STATUS)[0].toString();
					phaseArr[i].taskId = null;
				}
				s = String.valueOf(ph.getObjectId());
				if (phMgr.hasSubPhases(u, s))
					phaseArr[i].phaseId = s;
				else
					phaseArr[i].phaseId = null;
				count++;
			}
			else {
				// the caller may need this to identify how many actual phases are there
				phaseArr[i] = null;
				break;		// reach last phase
			}
		}

		// draw the expireDate triangular dots, starts from project StartDate (dt)
		// reasonably assume serial phases (in terms of milestones -- expireDate)
		sBuf.append("<tr><td class='bar' width='20'><img src='" + hostDes + "/i/spacer.gif' border='0'></td>");
		sBuf.append("<td class='bar' width='48' valign='top' align='right'>");
		if (count > 0) sBuf.append("Phase:&nbsp;&nbsp;");
		sBuf.append("</td><td><table border='0' cellpadding='0' cellspacing='1'><tr>");

		int days, lastii=0;
		long begin = pjStartDt.getTime(), lo;
		int dist = INIT_SPACING, adjust = 0;
		String tipsStr;
		int lastDist=0, distGap;

		for (int i=0; i<count; i++)
		{
			s = phaseArr[i].status;
			if (s.length() == 0) continue;		// invalid task id case
			if (s.equals(project.PH_START))
				dot = "tri_blue.gif";
			else if (s.equals(project.PH_COMPLETE))
				dot = "tri_green.gif";
			else if (s.equals(project.PH_LATE))
				dot = "tri_red.gif";
			else
				dot = "tri_grey.gif";

			dt = phase.parseStringToDate(phaseArr[i].expireDateS, format);
			if (dt == null || phase.isSpecialDate(dt)) continue;
			lo = dt.getTime();
			days = (int)Math.ceil((lo - begin)/86400000);
			tipsStr = "Phase " + (i+1) + ": " + phaseArr[i].name
							+ " (expire: " + phaseArr[i].expireDateS + ")";

			if (!bReverseSizeFactor) ii = days * sizeFactor;
			else ii = days / sizeFactor;
//System.out.println("ii="+ ii);
			if (updateOK)
			{
				dragOK = (phaseArr[i].taskId == null);
				if (dragOK) bNeedSubmitButton = true;
				//if (ii>10 || i==0) {dist += ii + adjust; adjust=0;}
				//else {dist += 10; adjust=-10;}
				dist = INIT_SPACING + ii;
				distGap = dist-lastDist;
				if (distGap<10 && distGap>=0) {
					// don't overlap if the next dot is to the right
					dist += (10 - distGap);
				}
				lastDist = dist;

				sBuf.append("<td><div id='d" + i + "' class='curBox'>");
				sBuf.append("<table border='0' cellpadding='0' cellspacing='0'>");
				sBuf.append("<tr><td title='" + tipsStr + "'>");
				sBuf.append("<img src='" + hostDes + "/i/" + dot + "' border='0'></td></tr>");
				sBuf.append("<tr><td align='center'>" + (i+1) + "</td></tr>");
				sBuf.append("</table></div></td>");
				sBuf.append("<script type='text/javascript'>\n");
				sBuf.append("<!--\n");
				sBuf.append("dotSetup('d" + i + "', " + dist + ", " + Y_POSITION + ", '"
						+ phaseArr[i].expireDateS + "', " + dragOK + ");");
				sBuf.append("\n//-->\n</script>");
			}
			else
			{
				ii += adjust - lastii - 15;
//System.out.println("   ii2 = " + ii);
				sBuf.append("<td class='bar' width='" + ii + "' align='center'>");
				sBuf.append("<img src='" + hostDes + "/i/spacer.gif' width='" + ii + "' height='1' border='0'></td>");
				sBuf.append("<td><table border='0' cellpadding='0' cellspacing='0'>");
				sBuf.append("<tr><td title='" + tipsStr + "'><img src='" + hostDes + "/i/" + dot
						+ "' border='0' alt='" + phaseArr[i].expireDateS + "'></td></tr>");
				sBuf.append("<tr><td align='center'>" + (i+1) + "</td></tr>");
				sBuf.append("</table></td>");
				if (i>0 && (ii < 7)) adjust= -7;
				else adjust = 0;
				lastii = ii + lastii;
			}
		}	// END: for each phase
		
		sBuf.append("</tr>");
		sBuf.append("</table></td></tr>");

		sBuf.append("<tr><td colspan='3'><table>");		// start Table M
		// show the project Start/Expire Dates if there is no phases
		if (count <= 0) {
			projBegEndGap -= 70;
			sBuf.append("<tr><td><img src='"
					+ hostDes + "/i/spacer.gif' height='15' width='35'/></td>");
			sBuf.append("<td class='bar' align='center' style='line-height:15px;'>Start<br><b>"
					+ df1.format(pjStartDt) + "</b></td>");
			sBuf.append("<td><img src='" + hostDes + "/i/spacer.gif' height='1' width='" + projBegEndGap + "'/></td>");
			if (!isContainer) {
				// only time-tracking project has ExpireDate
				sBuf.append("<td class='bar' align='center' style='line-height:15px;'>End<br><b>"
						+ df1.format(pjExpireDt) + "</b></td>");
			}
			else if (pjCompDt == null) {
				sBuf.append("<td class='bar' align='center' style='line-height:15px;'>Today<br><b>"
						+ df1.format(new Date()) + "</b></td>");
			}
			sBuf.append("</tr>");
		}
		sBuf.append("</table></td></tr>");				// close Table M

		// put done completed date if the project is finished
		if (pjCompDt != null) {
			//sBuf.append("<tr><td><img src='" + hostDes + "/i/spacer.gif' height='15'/></td></tr>");
			sBuf.append("<tr><td colspan='3' class='plaintext'>");
			sBuf.append("<img src='" + hostDes + "/i/spacer.gif' width='200' height='1'/>");
			sBuf.append("(Completed on <b>" + df1.format(pjCompDt) + "</b>)</td></tr>");
		}
		}	// ECC: if isContainer

		if (bNeedSubmitButton) {
			sBuf.append("<tr><td colspan='3'><img src='" + hostDes + "/i/spacer.gif' width='1' height='20'>");
			sBuf.append("</td></tr>");

			sBuf.append("<form method='post' name='SavePhase' action='post_savephase.jsp'>");
			sBuf.append("<input type='hidden' name='projId' value='" + projIdS + "'>");

			for (int i=0; i<maxPhases; i++) {
				sBuf.append("<input type='hidden' name='dt"+i+"' id='dt"+i+"' value=''>");
			}

			sBuf.append("<tr><td></td><td colspan='2' class='plaintext'>");
			sBuf.append("Note: hold and drag the pointer dots to change the milestone dates.  Click the Submit button to save.");
			sBuf.append("&nbsp;&nbsp;<input class='plaintext' type='Submit' name='Submit' value='Submit' onClick='return saveDots();'>");
			sBuf.append("</td></tr></form>");
		}	// END if bNeedSubmitButton
		else {
			//sBuf.append("<tr><td><img src='" + hostDes + "/i/spacer.gif' height='10'/></td></tr>");
		}
		sBuf.append("</table>");
		return sBuf.toString();
	}	// END: showProjectTimeBar()

	/**
	 * Return a string representing the no. of days, e.g. 1yr 4mo 21dy
	 * @param days
	 * @return
	 */
	public static String showDayString(int days)
	{
		String res = "";
		int years = days/365;
		if (years > 0) {
			res = years + "yr";
			days %= 365;
		}
		int months = days/31;	// use 31 instead of 30 or you may get 12 months here
		if (months > 0) {
			if (res.length() > 0) res += " ";
			res += months + "mo";
			days %= 30;
		}
		if (days > 0) {
			if (res.length() > 0) res += " ";
			res += days + "dy";
		}

		return res;
	}


	public static int getMaxPhases()
	{
		int maxPhases = 7;
		String s = Util.getPropKey("bringup", "PHS.TOTAL");
		if (s != null) maxPhases = Integer.parseInt(s);
		return maxPhases;
	}

	public static boolean prepareTimebarValues(project projObj, int[] intArr, String[] sArr)
		throws PmpException
	{
		String startDate=null, deadline=null, completeDate=null;
		int projLength = 0;
		int daysElapsed = 0;
		int daysLeft = 0;
		int daysLate = 0;
		int sizeFactor = 1;

		Date pjStartDt = projObj.getStartDate();
		Date today = Util.getToday();

		// elapsed
		Date compDt = (Date)projObj.getAttribute("CompleteDate")[0];
		if (pjStartDt != null)		// proj start date
		{
			startDate = df1.format(pjStartDt);
			if (compDt != null) {
				daysElapsed = (int)Math.ceil((compDt.getTime() - pjStartDt.getTime())/86400000);
				completeDate = df1.format(compDt);
			}
			else {
				daysElapsed = (int)Math.ceil((today.getTime() - pjStartDt.getTime())/86400000);
				completeDate = "Not yet completed";
			}
			if (daysElapsed < 0) daysElapsed = 0;
		}

		// days left or late
		Date dt1 = (Date)projObj.getAttribute("ExpireDate")[0];
		if (dt1 == null) dt1 = new Date();		// container project, no expiration, use today

		deadline = df1.format(dt1);
		if (compDt == null) {
			daysLeft = (int)Math.ceil((dt1.getTime() - today.getTime())/86400000+1);
			if (daysLeft < 0) {
				daysLate = -(int)Math.ceil((dt1.getTime() - today.getTime())/86400000); //- daysLeft;
				daysLeft = 0;
			}
		}
		else {
			// project already completed
			daysLate = (int)Math.ceil((compDt.getTime() - dt1.getTime())/86400000);
			if (daysLate < 0) daysLate = 0;
			daysLeft = (int)Math.ceil((dt1.getTime() - compDt.getTime())/86400000);		// not used
			if (daysLeft < 0) daysLeft = 0;
			//dt1 = compDt;		// completed date is the end of the project - ECC: no, normalize based on plan dates
		}

		projLength = (int)Math.ceil((dt1.getTime() - pjStartDt.getTime())/86400000);
		if (projLength < 2) projLength = 2;			// even if projLength==1 will have infinite loop

		boolean bReverseSizeFactor = false;
		int totalDays = daysElapsed + daysLeft + daysLate;	//projLength;
		int temp = totalDays;

		if (totalDays < 350) {
			while (temp < 350)
				temp = totalDays * ++sizeFactor;		// setting sizeFactor
		}
		else if (totalDays > 900) {
			while (temp > 900)
				{temp = totalDays / ++sizeFactor; bReverseSizeFactor = true;}
		}

		// package return values: must be in this order
		intArr[0] = projLength;
		intArr[1] = daysElapsed;
		intArr[2] = daysLeft;
		intArr[3] = daysLate;
		intArr[4] = sizeFactor;
		sArr[0] = startDate;
		sArr[1] = deadline;
		sArr[2] = completeDate;

		return bReverseSizeFactor;
	}	// END: prepareTimebarValues

	private static int showPhaseTable(StringBuffer sBuf, PhaseInfo [] phaseArr)
		throws PmpException, ParseException
	{
		if (phaseArr.length<=0 || phaseArr[0]==null) {
			// no phase to display
			return 0;
		}
		
		Date today = df3.parse(df3.format(new Date()));

		sBuf.append("<table width='100%' border='0' cellspacing='0' cellpadding='0'>");
		sBuf.append("<tr><td>");

		String [] label0 = {"&nbsp;Phase / Milestone", "Status", "Ori Start", "Ori Due",
							"Pl Start", "Pl Due", "Ac Start", "Ac Finish"};
		int [] labelLen0 = {465, 42, 55, 55, 55, 55, 55, 55};
		boolean [] bAlignCenter0 = {false, true, true, true, true, true, true, true};
		sBuf.append(Util.showLabel(label0, labelLen0, bAlignCenter0, true));

		// Phases
		String outStr, numS;
		String bgcolor="";
		boolean even = false;
		int ct = 0;
		Date dt, dt1;
		
		String s;
		String projIdS = null;
		String subphTid=null, subphName=null, subphStart=null, subphOriStart=null, subphOriExpire=null,
			subphPStart=null, subphPDeadln = null, subphDone=null, subphStatus=null;
		String oriExpDtS;

		for (int i=0; i<phaseArr.length; i++) {
			if (phaseArr[i] == null) break;

			if (even)
				bgcolor = Prm.DARK;
			else
				bgcolor = Prm.LIGHT;
			even = !even;

			numS = String.valueOf(i+1);
			
			// check to see if we are late from the perspective of Original Expire Date
			oriExpDtS = phaseArr[i].origExpireDtS;
			if (!StringUtil.isNullOrEmptyString(oriExpDtS) && !oriExpDtS.equals("-")) {
				dt = df1.parse(oriExpDtS);
				s = phaseArr[i].doneDateS;
				if (!StringUtil.isNullOrEmptyString(s) && !s.equals("-")) {
					dt1 = df1.parse(s);		// compare oriExpireDate with actual complete date

					// also see if user beats the schedule
					if (dt1.before(dt)) {
						phaseArr[i].origExpireDtS = "<font color='#00aa00'>" + oriExpDtS + "</font>";
					}
				}
				else
					dt1 = today;			// not done yet: compare with today
				if (dt.before(dt1)) {
					phaseArr[i].origExpireDtS = "<font color='#ee0000'>" + oriExpDtS + "</font>";
				}
			}
			
			outStr = project.displayPhase(bgcolor, numS, phaseArr[i].htmlName,
								phaseArr[i].origStartDtS, phaseArr[i].origExpireDtS,
								phaseArr[i].startDateS, phaseArr[i].expireDateS,
								phaseArr[i].effectiveDateS, phaseArr[i].doneDateS,
								phaseArr[i].status, HOST);

			sBuf.append(outStr);
			ct++;
			
			// show sub-phases
			PstAbstractObject [] objArr;
			phase ph;
			PstAbstractObject tk, ptk;

			if (phaseArr[i].phaseId != null)
			{
				PstGuest guest = PstGuest.getInstance();
				objArr = phMgr.getSubPhases(guest, phaseArr[i].phaseId);
				for (int m=0; m<objArr.length; m++)
				{
					subphName = subphStart = subphPDeadln = subphDone = subphStatus = "";
					ph = (phase) objArr[m];
					Object obj = ph.getAttribute(phase.TASKID)[0];
					if (obj != null)
					{
						// use task to fill the phase info
						subphTid = obj.toString();
						try
						{
							tk = tkMgr.get(guest, subphTid);
							if (projIdS == null) {
								projIdS = tk.getStringAttribute("ProjectID");
							}
							
							ptk = ((task)tk).getPlanTask(guest);

							obj = ph.getAttribute(phase.NAME)[0];
							if (obj == null)
								s = (String)ptk.getAttribute("Name")[0];
							else
								s = obj.toString();
							subphName = "<a class='listlink' href='" + HOST + "/blog/blog_task.jsp?projId=" + projIdS
								+ "&planTaskId=" + ptk.getObjectId() + "'>" + s + "</a>";

							dt = (Date)tk.getAttribute("OriginalStartDate")[0];
							subphOriStart = phase.parseDateToString(dt, format);

							dt = (Date)tk.getAttribute("OriginalExpireDate")[0];
							subphOriExpire = phase.parseDateToString(dt, format);
							if (dt != null) {
								dt1 = (Date) tk.getAttribute("CompleteDate")[0];
								if (dt1 != null) {
									// also see if user beats the schedule
									if (dt1.before(dt)) {
										subphOriExpire= "<font color='#00aa00'>" + subphOriExpire + "</font>";
									}
								}
								else
									dt1 = today;
								if (dt.before(dt1)) {
									subphOriExpire = "<font color='#ee0000'>" + subphOriExpire + "</font>";
								}
							}

							dt = (Date)tk.getAttribute("StartDate")[0];
							subphPStart = phase.parseDateToString(dt, format);

							dt = (Date)tk.getAttribute("ExpireDate")[0];
							subphPDeadln = phase.parseDateToString(dt, format);
							
							//dt = (Date)tk.getAttribute(phase.PLANEXPIREDATE)[0];
							//subphPDeadln = phase.parseDateToString(dt, format);
							
							dt = (Date)tk.getAttribute("EffectiveDate")[0];
							subphStart = phase.parseDateToString(dt, format);

							dt = (Date)tk.getAttribute("CompleteDate")[0];
							subphDone = phase.parseDateToString(dt, format);

							s = (String)tk.getAttribute("Status")[0];
							if (s.equals(task.ST_NEW)) s = project.PH_NEW;
							else if (s.equals(task.ST_OPEN) || s.equals(task.ST_ONHOLD)) s = project.PH_START;
							subphStatus = s;
						}
						catch (PmpException e){subphName = "*** Invalid task ID";}
					}
			
					if (even)
						bgcolor = Prm.DARK;
					else
						bgcolor = Prm.LIGHT;
					even = !even;

					numS = (i+1) + "." + (m+1);

					outStr = project.displayPhase(bgcolor, numS, subphName,
								subphOriStart, subphOriExpire, subphPStart, subphPDeadln,
								subphStart, subphDone, subphStatus, HOST);
					sBuf.append(outStr);
				}
			}
		}
		sBuf.append("</table>");
		sBuf.append("</td></tr></table>");
		return ct;
	}	// END: showPhaseTable

	public static String showHelp(String anchor, String titleMsg)
	{
		if (anchor == null) anchor = "";
		StringBuffer sBuf = new StringBuffer("&nbsp;<a href='javascript:popHelp(\"" + anchor
						+ "\")'><img src='../i/qmark.gif' border='0'");
		if (titleMsg != null) {
			sBuf.append(" title='" + titleMsg + "'");
		}
		sBuf.append("/></a>");
		return sBuf.toString();
	}

}	// END: class Util4