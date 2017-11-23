////////////////////////////////////////////////////
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	PrmMonitor.java
//	Author:	ECC
//	Date:	04/28/04
//	Description:
//		Run background processes for PRM.
//
//	Modification:
//		@AGQ071406A	Modified to have only one instance of Worker Thread
//					(should not occur anymore since there will only be
//					 one instance of Monitor)
//		@AGQ071406B	Modified to have only one instance of Monitor
//		@AGQ071406C	Removed checking bExited to prevent exit of monitor.
//					This occurs when scheduler has been restarted within 
//					a minute when Worker Thread last run.
//		@ECC071907	Add configuration NO_PRM_THREAD to prevent PrmThread background process all together.
//		@ECC111607	Add ChatThread for OMF to manage chat objects.
//
////////////////////////////////////////////////////////////////////

package main;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;

import mod.se.IndexScheduler;
import oct.codegen.actionManager;
import oct.codegen.bugManager;
import oct.codegen.eventManager;
import oct.codegen.historyManager;
import oct.codegen.meetingManager;
import oct.codegen.memoManager;
import oct.codegen.phaseManager;
import oct.codegen.planTaskManager;
import oct.codegen.projectManager;
import oct.codegen.questManager;
import oct.codegen.result;
import oct.codegen.resultManager;
import oct.codegen.taskManager;
import oct.codegen.townManager;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.codegen.userinfo;
import oct.codegen.userinfoManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstFlowStepManager;

import org.apache.log4j.Logger;

import util.Prm;
import util.PrmLog;
import util.PrmRdb;
import util.Util;

public class PrmThread extends Thread
{
	// attributes
	boolean bExited;			// true if the worker thread voluntarily exited
	
	// static attributes
	static final String THREAD_MONITOR		= "PrmMonitor";
	static final String THREAD_PRM_WORKER	= "PrmWorker";
	static final String THREAD_OMF_CHAT		= "OmfChat";
	
	static final String [] WEEK_DAY = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};
	final static int	PRM_NEW_BLOG		= 1;
	final static long	PRM_SLEEP_TIME	= 3600000;
	private final static String ARCV_FILE_PATH	= "ARCHIVE_PATH";
	private final static String ARCV_BLOG		= "ARCHIVE_BLOG";
	private final static String SEND_REPORT		= "SEND_REPORT";
	private final static String ROBO_MAIL		= "ROBO_MAIL";
	private static boolean isCRAPP  = false;
	private static boolean isOMFAPP = false;
	private static boolean isPRMAPP = false;
	private static String app = Util.getPropKey("pst", "APPLICATION");

	static final String PROJ_ALERT_SUBJ = "[" + Prm.getAppTitle() + " Thread] background processing";
	static final String FROM = Util.getPropKey("pst", "FROM");
	static final String MAILFILE = "alert.htm";
	static final String COMPANY = Util.getPropKey("pst", "COMPANY_NAME");
	static final String EGI_EMAIL = Util.getPropKey("pst", "EGI_EMAIL");

	private static userManager		m_uMgr;
	private static userinfoManager	m_uiMgr;
	private static townManager		m_tnMgr;
	private static resultManager	m_rsMgr;
	private static projectManager	m_pjMgr;
	private static taskManager		m_tkMgr;
	private static planTaskManager	m_ptMgr;
	//private static forumManager		m_fmMgr;
	private static historyManager	m_hMgr;
	private static actionManager	m_aMgr;
	private static memoManager		m_mmMgr;
	private static meetingManager	m_mtgMgr;
	private static bugManager		m_bugMgr;
	private static phaseManager		m_phMgr;
	private static eventManager		m_eMgr;
	private static questManager		m_qMgr;
	private static PstFlowStepManager m_fsMgr;

	private static user m_prmuser = null;

	private static String	m_arcvPath;
	private static boolean	m_bSendActionAlert;
	private static boolean	m_bDoArchive;
	private static boolean	m_bDoReport;
	private static boolean	m_bRoboMail;
	private static boolean 	running = false;
	private static boolean	m_bNoPrmWorkerThread;
	//private static boolean	m_bNoChatThread;
	private static boolean	m_bSendDailyEvents;
	private static boolean	m_bForceTest;
	
	private static RoboMailThread m_thRoboMail = null;


	private static Logger l;

	// statistics variables
	public static int lateProjNum, lateTaskNum, lateActionNum,
			openProjNum, openTaskNum, taskAlertNum, projAlertNum, delMemoNum,
			finishMtgNum, closeMtgNum, delMtgNum,
			totalTaskArc, totalBugArc, totalCirArc, totalUsrArc, totalReport,
			totalEvent, totalEventMail, totalEventDel, totalNBlogDel;
	
	static
	{
		l = PrmLog.getLog();
		if (app == null || app.indexOf("CR")!=-1)
			isCRAPP = true;
		if (app!=null && app.indexOf("OMF")!=-1)
			isOMFAPP = true;
		if (app!=null && app.indexOf("PRM")!=-1)
			isPRMAPP = true;
	}

	public PrmThread(String name)
	{
		super(name);
		/*if (name.equals(THREAD_MONITOR))
			return;*/
		checkOption();
	}
	
	private void checkOption()
	{
		try
		{
			// @ECC071907
			String s = Util.getPropKey("pst", "NO_PRM_THREAD");
			m_bNoPrmWorkerThread = s!=null && s.equalsIgnoreCase("true");

			//s = Util.getPropKey("pst", "NO_CHAT_THREAD");
			//m_bNoChatThread = s!=null && s.equalsIgnoreCase("true");

			if (m_bNoPrmWorkerThread)		// && m_bNoChatThread)
				return;							// no more processing on this thread
			
			s = Util.getPropKey("pst", "FORCE_BACKGROUND_THREAD");
			m_bForceTest = s!=null && s.equalsIgnoreCase("true");
			
			s = Util.getPropKey("pst", "SEND_DAILY_EVENT_EMAIL");
			m_bSendDailyEvents = s!=null && s.equalsIgnoreCase("true");
			
			// login as privilege user
			initLogin();

			if (!m_bNoPrmWorkerThread)
			{
				// gather PRM background options
				// configurable option: send action item late alert
				s = Util.getPropKey("pst", "SEND_ACTION_ALERT_LATE");
				m_bSendActionAlert = s!=null && s.equalsIgnoreCase("true");
	
				// archive repository
				m_arcvPath = Util.getPropKey("pst", ARCV_FILE_PATH);	// default: "C:/repository/Archive"
				s = Util.getPropKey("pst", ARCV_BLOG);
				m_bDoArchive = s!=null && s.equalsIgnoreCase("true");
	
				// reports
				s = Util.getPropKey("pst", SEND_REPORT);
				m_bDoReport = s!=null && s.equalsIgnoreCase("true");
				
				// roboMail
				s = Util.getPropKey("pst", ROBO_MAIL);
				m_bRoboMail = s!=null && s.equalsIgnoreCase("true");
			}
		}
		catch (PmpException e)
		{
			System.out.println(e.toString());
			e.printStackTrace();
		}
	}

	public static userManager getuMgr() {return m_uMgr;}
	public static userinfoManager getuiMgr() {return m_uiMgr;}
	public static resultManager getrsMgr() {return m_rsMgr;}
	public static projectManager getpjMgr() {return m_pjMgr;}
	public static taskManager gettkMgr() {return m_tkMgr;}
	public static planTaskManager getptMgr() {return m_ptMgr;}
	public static historyManager gethMgr() {return m_hMgr;}
	public static actionManager getaMgr() {return m_aMgr;}
	public static memoManager getmmMgr() {return m_mmMgr;}
	public static meetingManager getmtgMgr() {return m_mtgMgr;}
	public static bugManager getbugMgr() {return m_bugMgr;}
	public static phaseManager getphMgr() {return m_phMgr;}
	public static eventManager geteMgr() {return m_eMgr;}
	public static townManager gettnMgr() {return m_tnMgr;}
	public static questManager getqMgr() {return m_qMgr;}
	public static PstFlowStepManager getfsMgr() {return m_fsMgr;}

	public static user getuser() {return m_prmuser;}
	public static String getarcvpath() {return m_arcvPath;}

	public static boolean isSendActionAlert() {return m_bSendActionAlert;}
	
	public static boolean isOMFAPP() {return isOMFAPP;}
	public static boolean isCRAPP() {return isCRAPP;}
	public static boolean isPRMAPP() {return isPRMAPP;}

	public void run()
	{
		// Monitor thread
		if (m_bNoPrmWorkerThread)		// && m_bNoChatThread)		// @ECC071907
		{
			l.info("*** " + this.getName() + " thread exit normally: NO_PRM_THREAD=true");
			return;
		}
		
		
		String threadName = this.getName();

		if (threadName.equals(THREAD_MONITOR))
		{			
			
			// ECC testing
			//eccTesting();

			
			///////////////////////////////////////////////////////////
			// PrmMonitor thread started by PrmMonitor.java in the startup time
			//
			if(!checkCanRun()) { 		// @AGQ071406B
				l.info("*** PrmMonitor [" + app + "] thread exited because another instance is running.");
				return;
			}
			
			String msg = "*** PrmMonitor thread started for [" + app + "]: PrmWorkerThread="
				+ !m_bNoPrmWorkerThread;	// + ", OmfChatThread=" + !m_bNoChatThread;
			l.info(msg);
			sendEgiEmail(msg);
			
			IndexScheduler thSE = new IndexScheduler();
			thSE.start();
			
			PrmThread thPRM = null;	
			if (!m_bNoPrmWorkerThread) {				
				thPRM = new PrmThread(THREAD_PRM_WORKER);
				thPRM.start();
			}
			
			/* ECC: obsolete OmfChatThread
			OmfChatThread thChat = null;
			if (isOMFAPP && !m_bNoChatThread)
			{
				thChat = new OmfChatThread(THREAD_OMF_CHAT, m_prmuser);
				thChat.start();
			}
			*/
			
			if (m_bRoboMail && m_thRoboMail==null)
			{
				m_thRoboMail = new RoboMailThread(m_prmuser);
				m_thRoboMail.start();
			}

			while (getRunning())
			{
				try {Thread.sleep(5000);}		// yield for the worker thread to get started if any
				catch (InterruptedException e) {}
				
				if (m_bNoPrmWorkerThread)	// && m_bNoChatThread)		// @ECC071907
				{
					// just in case I miss the boolean flag above because of timing
					l.info("*** " + this.getName() + " thread exit normally: NO_PRM_THREAD=true");
					return;
				}
				
				l.info("*** PrmMonitor [" + app + "] thread start checking at (" +new Date().toString()+ ")");
				
				if (!m_bNoPrmWorkerThread)		// || !m_bNoChatThread)
				{
					// @AGQ071406C
					// check to see if PRM Worker Thread is alive
					if (thPRM != null)
					{
						if (thPRM.isAlive()) l.info("PrmThread [" + app + "] worker is alive.");
						else
						{
							l.error("!!!  PrmThread [" + app + "] worker is dead.  Restarting PrmThread ...");
							thPRM = new PrmThread(THREAD_PRM_WORKER);
							thPRM.start();
							msg = "New PrmThread [" + app + "] worker re-started by PrmMonitor.";
							l.info(msg);
							sendEgiEmail("Thread is dead.  " + msg);
						}
					}
					
					// check to see if OMF Chat thread is alive
					/* ECC obsolete OmfChatThread
					if (thChat != null)
					{
						if (thChat.isAlive()) l.info("ChatThread [" + app + "] is alive.");
						else
						{
							l.error("!!!  ChatThread [" + app + "] is dead.  Restarting OmfChatThread ...");
							thChat = new OmfChatThread(THREAD_OMF_CHAT, m_prmuser);
							thChat.start();
							msg = "New ChatThread [" + app + "] re-started by PrmMonitor.";
							l.info(msg);
							sendEgiEmail("Thread is dead.  " + msg);
						}
					}
					*/
					
					// check to see if RoboMail Worker Thread is alive
					if (m_thRoboMail != null)
					{
						if (m_thRoboMail.isAlive()) l.info("RoboMailThread [" + app + "] worker is alive.");
						else
						{
							l.error("!!!  RoboMailThread [" + app + "] worker is dead.  Restarting RoboMailThread ...");
							m_thRoboMail = new RoboMailThread(m_prmuser);
							m_thRoboMail.start();
							msg = "New RoboMailThread [" + app + "] worker re-started by PrmMonitor.";
							l.info(msg);
							sendEgiEmail("Thread is dead.  " + msg);
						}
					}
				}
				else
				{
					// isCRAPP
					// for CR, we want to do history management
					try {
						if (m_prmuser == null)
							initLogin();	// need special user login
						if (PrmAlert.isTime(PrmAlert.PJ_ALERT, 1, null))		// check at 1 AM
						{
							if (PrmHistory.checkClosedProject() < 0)
								l.error("********* checkClosedProject() returns error");
						}
					} catch (Exception e) {l.error("***** Exception in history management for CR.");e.printStackTrace();}
				}
				
				// perform statistic
				try {
					if (PrmAlert.isTime(PrmAlert.STAT_ACTIVITY, 5, null)) {			// check at 5 AM
						PrmRdb.bugCount();
						l.info("Completed Statistics Activity for [" + app + "]");
					}
				} catch (Exception e) {l.error("***** Exception in collecting statistics.");e.printStackTrace();}
				
				// check to see if thread is alive
				if (thSE.isAlive()) l.info("IndexScheduler [" + app + "] worker is alive.");
				else
				{
					l.error("!!!  IndexScheduler [" + app + "] worker is dead.  Restarting IndexScheduler ...");
					thSE = new IndexScheduler();
					thSE.start();
					msg = "New IndexScheduler [" + app + "] worker started.";
					l.info(msg);
					sendEgiEmail("Thread is dead.  " + msg);
				}
				
				// go to sleep
				l.info("*** PrmMonitor [" + app + "] thread go to sleep for 6 hours.");
				try {Thread.sleep(21600000);}		// check once every 6 hours
				catch (InterruptedException e) {}
			}
			setRunning(false);
			l.info("*** PrmMonitor [" + app + "] thread exited because its worker has exited normally.");
		}	// END: monitor thread
		else 
		{
			// Worker thread
			bExited = false;
			l.info("*** PrmThread [" + app + "] worker started");
			SimpleDateFormat Formatter1 = new SimpleDateFormat ("MMMMMMMM dd, yyyy (EEEEEEEE) hh:mm a");
			boolean bTest = m_bForceTest;		// set this to true to force background activities
	
			try
			{
				int rc1=0, rc2=0, rc3=0, rc4=0, rc5=0;
				while (true)
				{	
					if (m_bNoPrmWorkerThread)		// @ECC071907
					{
						// just in case I miss the boolean flag above because of timing
						l.info("*** PrmThread [" + app + "] worker thread exit normally: NO_PRM_THREAD=true");
						return;
					}
					
					lateProjNum = lateTaskNum = lateActionNum = openProjNum = openTaskNum =
						taskAlertNum = projAlertNum = delMemoNum = finishMtgNum = closeMtgNum = delMtgNum =
						totalTaskArc = totalBugArc = totalReport = totalEvent = totalEventMail = totalEventDel =
						totalCirArc = totalUsrArc = totalNBlogDel = 0;
					
					// check timestamp, make sure no other threads are working
					// and I am not just restarted short while ago
					Date now = null;
					
					Calendar rightNow = Calendar.getInstance();
					int day = rightNow.get(Calendar.DAY_OF_WEEK);
					
					// @AGQ071406A
					synchronized(m_uiMgr) {
						now = new Date();
						long nowtime = now.getTime();
						
						userinfo ui = (userinfo) m_uiMgr.get(m_prmuser, String.valueOf(m_prmuser.getObjectId()));
						Date dt = (Date)ui.getAttribute("LastLogin")[0];
						long lastWork = 0;
						if (dt != null)
							lastWork = dt.getTime();
						long diff = nowtime - lastWork;

						if (diff < 60000)		// if within 1 min
							break;				// assume someone else is working - terminate myself
		
						// I am the working thread for this epoch, timestamp my wakeup
						ui.setAttribute("LastLogin", now);
						m_uiMgr.commit(ui);
					}
					
					this.setPriority(Thread.MIN_PRIORITY);
					System.out.println(">>> PrmThread [" + app + "] wake up (" + now.toString() +")");
	
					////////////////  START WORKING  ////////////////////
	
					// send system alerts ///////////////////////////////
					if ((isPRMAPP || isCRAPP) && ((rc1 = PrmAlert.projTaskAlert(bTest)) < 0) )
						l.error("********* projTaskAlert() returns error");
	
					// history management ///////////////////////////////
					if (rc1 > 0)
					{
						// do this only if PrmAlert kicks in
						if (PrmHistory.checkClosedProject() < 0)
							l.error("********* checkClosedProject() returns error");
					}
	
					// handle meetings ///////////////////////////////
					if ((rc2 = PrmAlert.mtgCleanup(bTest)) < 0)
						l.error("********* mtgCleanup() returns error");
	
					// archiving //////////////////////////////////////
					if ( m_bDoArchive && ((rc3 = PrmArchive.archive(bTest)) < 0) )
						l.error("********* archive() returns error");
	
					// reports //////////////////////////////////////
					if ( isPRMAPP && m_bDoReport && ((rc4 = PrmReport.report(bTest)) < 0) )
						l.error("********* report() returns error");
					
					if ( m_bSendDailyEvents && (rc5 = PrmThBgEvent.checkEvent(bTest)) < 0)
						l.error("********* PrmThBgEvent() returns error");
	
					// notification to admin
					if ( /*(day!=0 && rc2>0) ||*/ (day==0 && rc4>0) || rc5>0)
					{
						rc2 = rc4 = 0;
	
						// send alert notification email to admin
						now = new Date();	// completed timestamp
						StringBuffer sBuf = new StringBuffer(1024);
						
						sBuf.append("Completed PRM background check on " + Formatter1.format(now) +"<br><br>");
						
						int [] ids = m_uMgr.findId(m_prmuser, "om_acctname='%'");
	
						sBuf.append("<b>Total # of users = " + ids.length + "<br><br>");
						
						sBuf.append("<b>Project / Task</b>:<blockquote>");
						sBuf.append("Projs alert sent = " + projAlertNum + "<br>");
						sBuf.append("Tasks alert sent = " + taskAlertNum + "<br><br>");
	
						sBuf.append("Projs moved to LATE = " + lateProjNum + "<br>");
						sBuf.append("Tasks moved to LATE = " + lateProjNum + "<br><br>");
	
						sBuf.append("Projs moved to OPEN = " + openProjNum + "<br>");
						sBuf.append("Tasks moved to OPEN = " + openProjNum);
						sBuf.append("</blockquote>");
	
						sBuf.append("<b>Action Item</b>:<blockquote>");
						sBuf.append("Action Items moved to LATE = " + lateActionNum);
						sBuf.append("</blockquote>");
	
						sBuf.append("<b>Memo</b>:<blockquote>");
						sBuf.append("Memo deleted = " + delMemoNum);
						sBuf.append("</blockquote>");
	
	
						sBuf.append("<b>Meeting</b>:<blockquote>");
						sBuf.append("FINISH opened meeting = " + finishMtgNum + "<br>");
						sBuf.append("CLOSED finished meeting = " + closeMtgNum + "<br>");
						sBuf.append("DELETE cancelled meeting = " + delMtgNum);
						sBuf.append("</blockquote>");
	
						if (rc3 > 0)
						{
							sBuf.append("<b>Archiving</b>:<blockquote>");
							sBuf.append("Total Tasks archived  = " + totalTaskArc + "<br>");
							sBuf.append("Total Bugs  archived  = " + totalBugArc + "<br>");
							sBuf.append("Total Circle blog   archived  = " + totalCirArc + "<br>");
							sBuf.append("Total Personal blog archived  = " + totalUsrArc);
							sBuf.append("</blockquote>");
						}
	
						if (rc4 > 0)
						{
							sBuf.append("<b>Weekly reports</b>:<blockquote>");
							sBuf.append("Total Reports sent  = " + totalReport);
							sBuf.append("</blockquote>");
						}
						
						if (rc5 > 0)
						{
							sBuf.append("<b>Event reports</b>:<blockquote>");
							sBuf.append("Total new events    = " + totalEvent + "<br>");
							sBuf.append("Total event emails  = " + totalEventMail + "<br>");
							sBuf.append("Total event cleanup = " + totalEventDel + "<br>");
							sBuf.append("Total note blog removed = " + totalNBlogDel);
							sBuf.append("</blockquote>");
						}
						
						// other reports
						sBuf.append("<b>Other reports</b>:<blockquote>");
						sBuf.append("Total Login (24-hr) = " + Util.m_loginNum + "<br>");
						sBuf.append("</blockquote>");
						Util.m_loginNum = 0;
	
						if (!Util.sendMailAsyn(FROM, FROM, null, null,
							PROJ_ALERT_SUBJ, sBuf.toString(), MAILFILE))
						{
							l.error("!!! Error sending [" + app + "] Background Processing report");
						}
						sendEgiEmail(sBuf.toString());
						
						// after sending notification, turn on Expiration check (once a day)
						oct.omm.client.OmsSession.setExpireCheck();
					}
	
					// fine tune clock to wake up right on the hour
					// it's ok even if the above jobs take more than an hour
					rightNow = Calendar.getInstance();
					int minute = 60 - rightNow.get(Calendar.MINUTE);
					if (minute < 10)
						minute = 60 + minute;
					System.out.println("<<< PrmThread [" + app + "] goto sleep (" + new Date().toString() +")");
	
					try {Thread.sleep(minute*60000);}		// check once an hour but adjust to 0 min.
					catch (InterruptedException e) {}
				}	// END: while true
	
				// logout and leave
				// @AGQ071406 Other applications may use m_prmuser; do not log out
				//m_uMgr.logout(m_prmuser);
				bExited = true;						// voluntarily, normally exited
				l.error("*** PrmThread [" + app + "] exited normally.");
			}
			catch (Exception e)
			{
				System.out.println(e.toString());
				e.printStackTrace();
			}
		}
	}	// END: else worker thread
	
	private void eccTesting() {
		try {
			System.out.println("***** archiving ...");
			int [] blogs = m_rsMgr.findId(m_prmuser, "TaskID='" + 104208 + "'");
			PstAbstractObject o;
			for (int i=0; i<blogs.length; i++)
			{
				o = m_rsMgr.get(m_prmuser, blogs[i]);
				o.setAttribute("Type", result.TYPE_TASK_BLOG);
				m_rsMgr.commit(o);
			}
			PrmArchive.do_archive(m_tkMgr, 104208, blogs);
			System.out.println("done archiving");
		}
		catch (PmpException e) {e.printStackTrace();}
	}

// @AGQ071406B
	/**
	 * Checks to see if the thread is currently running
	 * and sets the value to true if it is not. 
	 * @return true: Thread can be run and should be run now
	 * 			false: Thread is already running, should exit 
	 */
	private synchronized static boolean checkCanRun() {
		if (!getRunning()) {
			setRunning(true);
			return true;
		}
		else {
			return false;
		}
	}
	
	public synchronized static boolean getRunning() {
		return PrmThread.running;
	}
	
	private synchronized static boolean setRunning(boolean running) {
		PrmThread.running = running;
		return PrmThread.running;
	}
	
	private void init()
		throws PmpException
	{
		if (m_uMgr == null)
		{
			m_uMgr		= userManager.getInstance();
			m_uiMgr 	= userinfoManager.getInstance();
			m_rsMgr 	= resultManager.getInstance();
			m_pjMgr 	= projectManager.getInstance();
			m_tkMgr 	= taskManager.getInstance();
			m_ptMgr 	= planTaskManager.getInstance();
			m_hMgr		= historyManager.getInstance();
			m_aMgr		= actionManager.getInstance();
			m_mmMgr 	= memoManager.getInstance();
			m_mtgMgr 	= meetingManager.getInstance();
			m_bugMgr 	= bugManager.getInstance();
			m_phMgr 	= phaseManager.getInstance();
			m_eMgr		= eventManager.getInstance();
			m_tnMgr		= townManager.getInstance();
			m_qMgr		= questManager.getInstance();
			m_fsMgr		= PstFlowStepManager.getInstance();
		}
	}
	
	synchronized private void initLogin()
		throws PmpException
	{
		init();
		m_prmuser = Prm.getSpecialUser();
		if (m_prmuser == null) {
			throw new PmpException("Special user from Prm.getSpecialUser() is null.");
		}
	}
	
	public void sendEgiEmail(String msg)
	{
		// send email to lab
		if (EGI_EMAIL == null || EGI_EMAIL.length()<=0)
			return;
		
		String subj = "[" + COMPANY + "] Mail from (" + app + ")";
		if (!Util.sendMailAsyn(FROM, EGI_EMAIL, null, null,
				subj, msg, MAILFILE))
			{
				l.error("!!! Error sending " + app + " Email at sendEgiEmail()");
			}
	}
}
