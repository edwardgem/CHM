
//
//  Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   PrmAlert.java
//  Author:	ECC
//  Date:   05/15/04
//  Description:
//			Background work to check and send alert messages.
//  Modification:
//
//
/////////////////////////////////////////////////////////////////////
//
// PrmAlert.java : implementation of the PrmAlert class for PRM
//

package main;

import java.text.SimpleDateFormat;
import java.util.Date;

import oct.codegen.history;
import oct.codegen.historyManager;
import oct.codegen.planTaskManager;
import oct.codegen.project;
import oct.codegen.projectManager;
import oct.codegen.resultManager;
import oct.codegen.task;
import oct.codegen.taskManager;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.codegen.userinfoManager;
import oct.pmp.exception.PmpException;
import oct.pmp.exception.PmpObjectNotFoundException;

import org.apache.log4j.Logger;

import util.Prm;
import util.PrmLog;
import util.Util;


public class PrmHistory
{
	static final String PROJ_CLOSE_SUBJ = "<font color='#aa0000'>[" + Prm.getAppTitle() + "] History Management</font><br>";
	static final String FROM = Util.getPropKey("pst", "FROM");;
	static final String MAILFILE = "alert.htm";
	static final long DAY_MILLISEC = 86400000;

	static projectManager pjMgr = PrmThread.getpjMgr();
	static taskManager tkMgr = PrmThread.gettkMgr();
	static planTaskManager ptMgr = PrmThread.getptMgr();
	static resultManager rsMgr = PrmThread.getrsMgr();
	static userinfoManager uiMgr = PrmThread.getuiMgr();
	static userManager uMgr = PrmThread.getuMgr();
	static historyManager hMgr = PrmThread.gethMgr();

	static long thisMoment;
	static user jwu;
	static Logger l = PrmLog.getLog();

	public static int checkClosedProject()
		throws PmpException
	{
		// for each project, check the Status and see if it "closed".
		// There are 2 Close Paths: Closed after Completed or Closed after Canceled.

		jwu = PrmThread.getuser();
		Date now = new Date();

		////////////////////////////////////////////////////////////////
		// This thread works once a day, immediately after Project/Task Alert check
		l.info("*** PrmHistory checkClosedProject starts (" + now.toString() + ")");

		// now check each project that are Completed or Late
		SimpleDateFormat Formatter1 = new SimpleDateFormat ("MMMMMMMM dd, yyyy (EEEEEEEE) hh:mm a");

		// policy follows:
		// For each closed project, generate a history record in XML format.
		// Once a project is closed, it becomes history and cannot be changed.  Neither can
		// anyone post or update the blog.
		//
		// Note: archiving is not done here.  It would be done by a separate thread in
		// ARCHIVE_DAYS after the project is closed.

		int count = 0;					// no. of closed project processed

		// for every project that is Completed or Late
		int [] pjids = pjMgr.findId(jwu, "Status='Closed'");
		project pj = null;
		for (int i=0; i<pjids.length; i++)
		{
			// for every project check the expiration date against the alert conditions
			pj = (project)pjMgr.get(jwu, pjids[i]);				// proj Id
			if (closing(pj))
				count++;
		}

		// send alert notification email to info@egiomm if anything has closed
		now = new Date();
		if (count > 0)
		{
			String msg = "Completed project closing check on " + Formatter1.format(now) +"<br><br>";
			msg += "Total history records (for closed projects) = " + count + "<br>";

			if (!Util.sendMailAsyn(FROM, FROM, null, null,
				PROJ_CLOSE_SUBJ, msg, MAILFILE))
			{
				l.error("!!! Error sending project closed report");
			}
		}

		l.info("*** PrmThread checkClosedProject ends (" + now.toString() + ")");
		return 0;
	}

	///////////////////////////////////////////////////////
	//
	//	closing()
	//	Closing a project and construct history record.
	//
	///////////////////////////////////////////////////////
	//
	protected static boolean closing(project pj)
		throws PmpException
	{
		// check closed project to see if history record is generated
		// if not, complete the closing by creating history record in XML.
		String pjIdS = Integer.toString(pj.getObjectId());
		try
		{
			if (hMgr.get(jwu, pjIdS) != null)
				return false;
		}
		catch (PmpObjectNotFoundException e)
		{
			// good: history record not found, move ahead to create now
			l.info("Creating history record for project [" + pjIdS + "]");
		}

		//////////////////////////////////
		// construct history record
		// XML format
		StringBuffer sbuf = new StringBuffer();
		sbuf.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?><prm-history>");
		SimpleDateFormat Formatter = new SimpleDateFormat ("MM/dd/yy");
		Date complete	= (Date)pj.getAttribute("CompleteDate")[0];
		Date start		= (Date)pj.getAttribute("StartDate")[0];
		Date expire		= (Date)pj.getAttribute("ExpireDate")[0];

		// project name, coordinator, type
		append(sbuf, "project-name", pj.getObjectName());
		append(sbuf, "coordinator", (String)pj.getAttribute("Owner")[0]);
		append(sbuf, "type", (String)pj.getAttribute("Type")[0]);

		// deduce project's final status: Completed-Early, Completed-Late, Completed, Canceled
		boolean bProjCanceled = false;
		String status = null;
		if (complete != null)
		{
			status = "Completed";
			if (complete.after(expire))
				status += "-Late";
			else if (complete.before(expire))
				status += "-Early";
		}
		else
		{
			status = "Canceled";
			bProjCanceled = true;
		}
		append(sbuf, "status", status);

		// start date, target date, completion date, and project duration and days gain(lost)
		append(sbuf, "start-date", Formatter.format(start));
		append(sbuf, "expire-date", Formatter.format(expire));
		if (complete != null)
		{
			// duration
			append(sbuf, "complete-date", Formatter.format(complete));
			long diff = complete.getTime() - start.getTime();
			int days = (int)Math.ceil(diff/DAY_MILLISEC);
			append(sbuf, "duration", Integer.toString(days));

			// days gain (lost)
			days = (int)Math.ceil((expire.getTime() - complete.getTime())/DAY_MILLISEC);
			append(sbuf, "days-gain", Integer.toString(days));
		}

		// # of team members
		int num = pj.getAttribute("TeamMembers").length;
		append(sbuf, "total-member", Integer.toString(num));

		// # of blogs posted
		int [] ids = rsMgr.findId(jwu, "ProjectID='" + pj.getObjectId() + "' && Type!='Alert'");
		append(sbuf, "total-blog", Integer.toString(ids.length));

		// # of tasks
		ids = tkMgr.findId(jwu, "ProjectID='" + pj.getObjectId() + "'");
		append(sbuf, "total-task", Integer.toString(ids.length));

		// compute task handling efficiency
		// # of Early, Late and Canceled tasks.  Total no. of days gained by tasks
		if (!bProjCanceled)
		{
			// compute task efficiency only if project is not canceled
			int late  = 0;
			int early = 0;
			int cancel = 0;
			int daysGain = 0;
			String s;
			task tk;
			for (int i=0; i<ids.length; i++)
			{
				tk = (task)tkMgr.get(jwu, ids[i]);
				complete = (Date)tk.getAttribute("CompleteDate")[0];
				expire = (Date)tk.getAttribute("ExpireDate")[0];
				if (expire == null) continue;	// ignore this task
				if (complete == null)
				{
					// task was never marked completed, use proj completion date as task completion date
					complete = (Date)pj.getAttribute("CompleteDate")[0];
				}
				s = (String)tk.getAttribute("Status")[0];
				if (s.equals("Late")) late++;
				else if (s.equals("Canceled")) cancel++;
				else
				{
					// compare complete date and expire date to determine if it is early
					if (complete.before(expire))
						early++;
				}
				daysGain += (int)Math.ceil((expire.getTime() - complete.getTime())/DAY_MILLISEC);
			}

			append(sbuf, "early-task", Integer.toString(early));
			append(sbuf, "late-task", Integer.toString(late));
			append(sbuf, "cancel-task", Integer.toString(cancel));
			append(sbuf, "days-gain-by-task", Integer.toString(daysGain));
		}

		// create and insert the history record
		sbuf.append("</prm-history>");
		history h = (history)hMgr.create(jwu, pjIdS);
		h.setAttribute("Content", sbuf.toString().getBytes());
		h.setAttribute("CreatedDate", new Date());
		hMgr.commit(h);

		//////////////////////////////////
		// clean-up
		// - remove all but the latest plan and planTask
		// - remove all workflow objects

		return true;
	}	// end closing()

	protected static void append(StringBuffer buf, String tag, String value)
	{
		buf.append("<" + tag + ">" + value + "</" + tag + ">");
	}

}
