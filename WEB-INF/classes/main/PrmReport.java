//
//  Copyright (c) 2006, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   PrmReport.java
//  Author:	ECC
//  Date:   3/9/06
//  Description:
//			Background work to send out weekly project reports.
//  Modification:
//
//
/////////////////////////////////////////////////////////////////////
//
// PrmArchive.java : implementation of the PrmReport class for PRM
//

package main;

import java.util.Calendar;

import oct.codegen.project;
import oct.codegen.projectManager;
import oct.codegen.user;
import oct.codegen.userManager;

import org.apache.log4j.Logger;

import util.PrmLog;
import util.Util;
import util.Util4;


public class PrmReport {

	static final String REPORT	= "Report";
	static final int REPORT_HOUR	= 5;				// 5 AM
	static final String WORK_DAY	= "Mon";			// send report on Monday morning

	static user jwu = PrmThread.getuser();
	static Logger l = PrmLog.getLog();

	static userManager uMgr = PrmThread.getuMgr();
	static projectManager pjMgr = PrmThread.getpjMgr();

	public static int report(boolean bTest)
	throws Exception
	{
		// check to see when was the last time I do reporting on the System.
		// do Report on the system once a day at 6AM
		if (!bTest && !PrmAlert.isTime(REPORT, REPORT_HOUR, null))
			return 0;


		////////////////////////////////////////////////////////////////
		// Need to work (on Sun after 6 AM)
		l.info("*** PrmThread Reporting starts");

		// the report recipients is in the project object (Attendee attr)
		// go thru each project to decide which one needs to send
		// report.

		// check every project to decide if we need to send reports
		// to a group of people in the project
		int idx;
		int [] ids = pjMgr.findId(jwu, "om_acctname='%'");
		for (int i=0; i<ids.length; i++)
		{
			int projId = ids[i];
			try
			{
				project pj = (project)pjMgr.get(jwu, projId);
				String currentDistFreq = pj.getOption(project.DISTRIBUTE_FREQ);
				if (Util.isNullString(currentDistFreq) ||
					currentDistFreq.equals(project.DIST_MANUALLY) ||
					currentDistFreq.equals(project.DIST_POSTED)) {
					continue;		// no auto periodic distribution of report
				}
				
				// daily, weekly or monthly
				Calendar cal = Calendar.getInstance();
				String currentDistFreqSpec = "";
				if ((idx=currentDistFreq.indexOf(':')) != -1) {
					currentDistFreqSpec = currentDistFreq.substring(idx+1);
					currentDistFreq = currentDistFreq.substring(0, idx);
				}

				if (!currentDistFreq.equals(project.DIST_DAILY)) {
					int dayNum = Integer.parseInt(currentDistFreqSpec);	// DAY_OF_WEEK or DAY_OF_MONTH
					if (currentDistFreq.equals(project.DIST_WEEKLY)) {
						// java Calendar Mon=1
						if (cal.get(Calendar.DAY_OF_WEEK) != dayNum)
							continue;	// not today
					}
					else if (currentDistFreq.equals(project.DIST_MONTHLY)) {
						if (cal.get(Calendar.DAY_OF_MONTH) != dayNum) {
							continue;
						}
					}
				}

				// if I get to here then distribute;
				if (Util4.sendReport(jwu, projId, null)) {
					PrmThread.totalReport++;
				}
			}
			catch (Exception e)
			{
				e.printStackTrace();
				l.error("Failed to construct and send report for " + projId);
			}
		}

		l.info("*** PrmThread Reporting ends");
		return 1;
	}

}
