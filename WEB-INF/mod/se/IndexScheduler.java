//
//	Copyright (c) 2006, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: IndexScheduler.java
//	Author: AGQ
//	Date:	06/16/06
//	Description: Runs thread processes for Search Engine.
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//

package mod.se;

import java.io.IOException;
import java.util.Calendar;
import java.util.Date;

import oct.codegen.user;
import oct.codegen.userManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstGuest;
import oct.pst.PstUserAbstractObject;

import org.apache.log4j.Logger;
import org.apache.lucene.index.IndexWriter;

import util.Prm;
import util.PrmLog;
import util.Util;

public class IndexScheduler extends Thread{
	static Logger l = PrmLog.getLog();
	public static final String UPDATE ="update";
	public static final String RELOAD = "reload";
	static boolean reloading = false;
	private static boolean running = false;
	
	static final String PROJ_ALERT_SUBJ = "[" + Prm.getAppTitle() + "] IndexScheduler Thread - background processing";
	static final String FROM = Util.getPropKey("pst", "FROM");
	static final String TO = Util.getPropKey("pst", "MAIL_ADMIN");
	static final String MAILFILE = "alert.htm";
	static final String MSG = "CR/SE is up and running";
	
	private String fileLocation;
	private String id;
	private boolean success;
	
	public IndexScheduler(String name) {
		super(name);
		if (getPriority() >= Thread.NORM_PRIORITY) {
			setPriority(Thread.NORM_PRIORITY-1);
		}
	}
	
	public IndexScheduler(String name, String fileLocation, String id) {
		super(name);
		this.fileLocation = fileLocation;
		this.id = id;
		this.success = false;
		if (getPriority() >= Thread.NORM_PRIORITY) {
			setPriority(Thread.NORM_PRIORITY-1);
		}
	}
	
	public IndexScheduler() {
		setRunning(false);
		if (getPriority() >= Thread.NORM_PRIORITY) {
			setPriority(Thread.NORM_PRIORITY-1);
		}
	}
	
	/**
	 * Checks to see what the current status requires to run. 
	 * Calls runOptimize and runReIndex when required and resets 
	 * the status. For every hour, runActiveQuery and reloadSearcher 
	 * will be called if necessary.
	 */
	public void run() {
		// Reloads the searcher when possible
		if (super.getName().equals(RELOAD)) {
			if (reloading == true) {
				System.out.println("SE currently reloading searcher");
				return;
			}
			System.out.println("Reloading searcher");
			reloading = true;
			reloadSearcher();
			IndexStatus.setUpdated(false);
			reloading = false;
			System.out.println("Reloading searcher finished");
		}
		else if (super.getName().equals(UPDATE)) {
			this.setPriority(Thread.MIN_PRIORITY);
			System.out.println("-adding " + fileLocation);
			success = IndexBuilder.update(fileLocation, id);
			if (success)
				System.out.println("   " + fileLocation + ": Index has been updated");
			else
				System.out.println("   " + fileLocation + ": Index failed to update:" + id);

		}
		// Perform hourly tasks
		else {
			if (!checkCanRun()) {
				System.out.println("SE currently running");
				return;
			}

			String app = Util.getPropKey("pst", "APPLICATION");
			String sentMailS = Util.getPropKey("pst", "CR_SENT_ALIVE_MAIL");
			boolean isCRAPP = true;
			boolean sentMail = true;
			if (app != null && app.equalsIgnoreCase("PRM"))
				isCRAPP = false;
			if (sentMailS!=null && sentMailS.equalsIgnoreCase("false"))
				sentMail = false;
			
			while(getRunning()) {
				try {
					System.out.println(">>> SE IndexScheduler wake up (" + new Date().toString() +")");
					this.setPriority(Thread.MIN_PRIORITY);
					userManager uMgr = userManager.getInstance();
					PstUserAbstractObject pstuser = (PstUserAbstractObject) PstGuest.getInstance();
					String spec_uname = Util.getPropKey("pst", "PRIVILEGE_USER");
					String spec_passwd = Util.getPropKey("pst", "PRIVILEGE_PASSWD");
					pstuser = (user)uMgr.login(pstuser, spec_uname, spec_passwd);
					
					System.out.println("Checking for new files...");
					checkNewExtFiles();
					System.out.println("Checking for new files finished");
					
					System.out.println("Sending active queries");
					runActiveQuery(pstuser);
					System.out.println("Sending active queries finished");
					
					System.out.println("Run Optimize");
					runOptimize();
					System.out.println("Run Optimize Finished");
										
					Calendar rightNow = Calendar.getInstance();
					int hour = rightNow.get(Calendar.HOUR_OF_DAY);
					if (hour == 3 && isCRAPP && sentMail) {
						// sent out alert email to monitor if app is running
						if (!Util.sendMailAsyn(pstuser, FROM, TO, null, null,
								PROJ_ALERT_SUBJ, MSG, MAILFILE))
							{
								System.out.println("!!! Error sending PRM Background Processing report");
							}
					}
					int minute = 60 - rightNow.get(Calendar.MINUTE);
					if (minute < 10)
						minute = 60 + minute;
					System.out.println("<<< SE IndexScheduler go to sleep (" + new Date().toString() +")");
					
					uMgr.logout(pstuser);
					
					Thread.sleep(minute*60000); // check once an hour but adjust to 0 min.
				} catch (PmpException e) {
					l.error("SE thread login error");
					setRunning(false);
				} catch (InterruptedException e) {
					l.error("SE thread interrupted");
					setRunning(false);
				}
			}
		}
	}
	
	/**
	 * Checks to see if the thread is currently running
	 * and sets the value to true if it is not
	 * @return
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
		return IndexScheduler.running;
	}
	
	private synchronized static boolean setRunning(boolean running) {
		IndexScheduler.running = running;
		return IndexScheduler.running;
	}

	private boolean checkNewExtFiles() {
		try {
			String [] strArr = new String[1];
			strArr[0] = UPDATE;
			CreateAttDB.main(strArr);
			return true;
		} catch (Exception e) {
			l.error(e);
			return false;
		}
	}	
	
	/**
	 * Reloads the searcher so the most up to date results will show
	 * @return
	 */
	private boolean reloadSearcher() {
		int count = 0;
		while (count < 5) { 						// || count < 60
			count++;
			try {
				if (IndexStatus.isCurrentlyUsed())
					Thread.sleep(60000);			// 1 min.
				else {
					if (SearchIndex.reloadSearcher())
						return true;
					else {
						Thread.sleep(60000);
					}
				}
			} catch (InterruptedException e) {}
		}
		l.error("Search failed to reload after 5 mins, trying again.");
		return reloadSearcher();
	}
	
	/**
	 * Call QueryManagement.ActiveQuery() to handle all the 
	 * live query requests.
	 * @return
	 */
	private boolean runActiveQuery(PstUserAbstractObject pstuser) {
		return QueryManagement.activeQuery(pstuser);
	}
	
	/**
	 * Optimizes the current index in use
	 * @return
	 */
	private boolean runOptimize() {
		if (!IndexStatus.isOptimized()) {
			IndexWriter writer = null;
			try {
				IndexStatus.setCurrentlyUsed(true);
				
				writer = IndexBuilder.getIndexWriter();

				//writer = new IndexWriter(indexDir, new StandardAnalyzer(), false);
				//writer.optimize();
				writer.commit();
				IndexBuilder.closeWriter();
				IndexStatus.setOptimized(true);
				return true;			
			} catch (IOException e) {
				l.error(e);
				return false;
			} finally {
				try {
					if (writer != null)
						writer.commit();
						writer.close();
				} catch (Exception e) {}
				IndexStatus.setCurrentlyUsed(false);
			}
		}
		return false;
	}
}
