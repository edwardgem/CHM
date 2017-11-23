
////////////////////////////////////////////////////
//	Copyright (c) 2007, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	PrmThBgEvent.java
//	Author:	ECC
//	Date:	11/09/07
//	Description:
//		Implementation of PrmThBgEvent class.  Execute nightly to send email notifications
//		to users on events.  Cleanup old events.
//
////////////////////////////////////////////////////////////////////

package main;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;

import mod.mfchat.OmfEventAjax;
import oct.codegen.eventManager;
import oct.codegen.meeting;
import oct.codegen.result;
import oct.codegen.resultManager;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.codegen.userinfo;
import oct.codegen.userinfoManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstUserAbstractObject;

import org.apache.log4j.Logger;

import util.Prm;
import util.PrmEvent;
import util.PrmLog;
import util.Util;
import util.Util2;

/**
 * @author ECC
 *
 */
public class PrmThBgEvent {

	static final String CHK_REPORT	= "Events";
	static final int WORK_HOUR	= 4;				// 4 AM

	static final String EVENT_NOTIFICATION_SUBJ = "[" + Prm.getAppTitle()
													+ "] Notes and events from ";
	static final String HOST = Util.getPropKey("pst", "PRM_HOST");
	static final String FROM = Util.getPropKey("pst", "FROM");
	static final String MAILFILE = "alert.htm";
    static final String ignoreEvents = PrmEvent.EVT_MTG_VIEW + ";"
    									+ PrmEvent.EVT_USR_LOGIN + ";"
    									+ PrmEvent.EVT_MTG_DELETE;

    public static final long NOTE_DEL_DAYS	= 5 * 24 * 3600000;		// remove post note blogs older than 5 days
    public static final long MAX_EVT_LIFE	= 10 * 24 * 3600000;	// remove events older than 5 days

	static user jwu = PrmThread.getuser();
	static Logger l = PrmLog.getLog();
	
	static userManager uMgr			= PrmThread.getuMgr();
	static userinfoManager uiMgr	= PrmThread.getuiMgr();
	static eventManager eMgr		= PrmThread.geteMgr();
	static resultManager rMgr		= PrmThread.getrsMgr();
	
	
	public static int checkEvent(boolean bTest)
	throws Exception
	{
		// check to see when was the last time I do reporting on the System.
		// do event check on the system everyday at 4AM
		if (!bTest && !PrmAlert.isTime(CHK_REPORT, WORK_HOUR, null))
			return 0;
		l.info("*** PrmThread Event Check starts");
				
	    Date today = new Date();
	    long now = today.getTime();
	    String s, eventS, subj, msg;
	    String [] sa;
	    Date dt;
	    long diff;
	    ArrayList evList;
	    PstAbstractObject evt;
	    PstUserAbstractObject detailUser;
	    StringBuffer friendName = null;
	    PstAbstractObject o, ui;
	    
		Calendar rightNow = Calendar.getInstance();
		int day = rightNow.get(Calendar.DAY_OF_WEEK);
		String todayWeekDay = PrmThread.WEEK_DAY[day-1];

		
		// for each user, for each event that is created within the last 24 hours
		int [] uids = uMgr.findId(jwu, "om_acctname='%'");
		for (int i=0; i<uids.length; i++)
		{
			// grab the events and for each event, check the CreatedDate
			try {detailUser = (PstUserAbstractObject) uMgr.get(jwu, uids[i]);}
			catch (PmpException e) {l.error("checkEvent() failed to get user: ["+uids[i]+"]"); continue;}
			
			eventS = (String)detailUser.getAttribute("Events")[0];
			if (eventS == null) continue;		// no event for this user
			
			// @ECC080608 check user preference if s/he wants to ignore event notification
			s = Util2.getUserPreference(detailUser, "BlogCheck");		// CheckEvent
			if (s!=null) {
				if (s.equalsIgnoreCase("no")
					|| (!s.equalsIgnoreCase("daily") && !todayWeekDay.equalsIgnoreCase(s)) )
					continue;		// no daily event notification for this user
			}
			
			// get user time zone info
			ui = uiMgr.get(jwu, String.valueOf(uids[i]));
			Integer tz = (Integer)ui.getAttribute("TimeZone")[0];
			if (tz.intValue() == 0) tz = new Integer(userinfo.SERVER_TIME_ZONE);	// default to server timezone

			evList = new ArrayList();
			sa = eventS.split(";");
			for (int j=0; j<sa.length; j++)
			{
				try {evt = eMgr.get(jwu, sa[j]);}
				catch (PmpException e)
				{
					// event not found, do clean up here
					PrmEvent.removeEvent(jwu, Integer.parseInt(sa[j]));
					continue;
				}
				dt = (Date)evt.getAttribute("CreatedDate")[0];
				diff = now - (dt.getTime() + userinfo.getServerUTCdiff());
				if (diff <= PrmAlert.ONE_DAY) {
					// include this event in the email notification
					evList.add(evt);
				}
			}
			
			if (evList.isEmpty()) continue;
			PrmThread.totalEvent += evList.size();
			
			friendName = new StringBuffer(128);
			msg = OmfEventAjax.constructEventDisplay(detailUser, evList, userinfo.getServerUTCdiff(), null, 0,
					friendName, ignoreEvents, null, null, null, tz, false);

			msg = msg.trim();
			if (msg.length() > 0)
			{
				msg = msg.replaceAll("\\.\\./", HOST+"/");	// switch host name			
				//msg = msg.replaceAll("(<[A|a][^>]*>)|(</[A|a]>)", "");	// remove all <A> tags
				msg = "<table><tr><td width='20'>&nbsp;</td><td><table><tr><td id='Events' class='plaintext'>"
					+ msg + "</td></tr></table></td></tr></table>"
					+ "<div><blockquote>"
					+ "<a href='" + HOST + "/ep/ep_home.jsp' class='listlink_big'>Click here to reply and respond to these events"
					+ "</a></blockquote></div>";
				subj = EVENT_NOTIFICATION_SUBJ;
				if (!Util.isNullString(friendName.toString()))
					subj += friendName.toString() + " and others";
				else if (Prm.isMeetWE())
					subj += "friends and circles";
				else
					subj += "team members";
				if (!Util.sendMailAsyn(FROM, (String)detailUser.getAttribute("Email")[0], null, null,
					subj, msg, MAILFILE))
					l.error("!!! Error sending " + Prm.getAppTitle() + " Background event notification to user [" + uids[i] + "]");
				PrmThread.totalEventMail++;
			}
		}	// end for each user
		
		// 1. for each of the event, if it was created more than MAX_EVT_LIFE (5 days), remove it
		// 2. for each event that does not connect to user, remove it
		int [] ids = eMgr.findId(jwu, "om_acctname='%'");
		for (int i=0; i<ids.length; i++)
		{
			evt = eMgr.get(jwu, ids[i]);
			
			// check how old is the event: over 10 days, remove and unstack
			dt = (Date)evt.getAttribute("CreatedDate")[0];
			if (dt == null)
			{
				l.info("Event [" + ids[i] + "] has a null CreatedDate.");
				PrmEvent.removeEvent(jwu, ids[i]);	// delete and unstack
				PrmThread.totalEventDel++;
				continue;
			}
			if (now - dt.getTime() > MAX_EVT_LIFE)
			{
				PrmEvent.removeEvent(jwu, ids[i]);	// delete and unstack
				PrmThread.totalEventDel++;
				continue;
			}
			
			// check if anyone is link to this event, if not, delete event
			uids = uMgr.findId(jwu, "Events='%" + ids[i] + "%'");
			if (uids.length <= 0)
			{
				eMgr.delete(evt);
				PrmThread.totalEventDel++;
			}
		}
		
		
		// check post note blog
		ids = rMgr.findId(jwu, "Type='" + result.TYPE_NOTE_BLOG + "'");
		for (int i=0; i<ids.length; i++)
		{
			o = rMgr.get(jwu, ids[i]);
			dt = (Date)o.getAttribute("CreatedDate")[0];
			if (now - dt.getTime() > NOTE_DEL_DAYS)
			{
				rMgr.delete(o);
				PrmThread.totalNBlogDel++;
			}
		}

		l.info("*** PrmThread Event Check ends");
		return 1;
	}	// END: checkEvent()
}
