////////////////////////////////////////////////////
//	Copyright (c) 2006, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	OmfChatThread.java
//	Author:	ECC
//	Date:	11/16/07
//	Description:
//		Implementation of OmfChatThread class.
//
//	Modification:
//			@ECC020808	Use this thread to check and cleanup for online/offline hash.
//
////////////////////////////////////////////////////////////////////

package mod.mfchat;

import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;

import oct.codegen.chatManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstUserAbstractObject;

import org.apache.log4j.Logger;

import util.PrmLog;

/**
 * @deprecated
 * @author edwardc
 *
 */
public class OmfChatThread extends Thread
{
	private static boolean running = false;
	private static final int WORK_PERIOD	= 5;				// wake up every 5 min to do work
	private static final long MEM_CLEANUP_PERIOD = 10 * 60000;	// 10 min: time before memory copy is deallocated
	private static final long MEM_COMMIT_PERIOD	 = 5 * 60000;	// 5 min: time before memory copy is flush to disk

	public static final int FORGOTTEN_PERIOD	= 10 * 24 * 3600000;	// 10 days: chats in DB that are inactive will be forgotten

	private static final long INACTIVE_PERIOD	= 15 * 60000;	// 15 min inactive: consider the user has logout

	private static PstUserAbstractObject jwu;
	private static chatManager cMgr;

	private static Logger l;
	static
	{
		l = PrmLog.getLog();
		try {cMgr = chatManager.getInstance();}
		catch (PmpException e) {cMgr = null;}
	}

	public OmfChatThread(String name, PstUserAbstractObject u) {
		super(name);
		jwu = u;
	}

	public void run()
	{
		if (!checkCanRun())
		{
			System.out.println("ChatThread is currently running - exit self normally.");
			return;
		}
		
		// get the Chat Hash object
		HashMap chatHash = OmfChat.getHash();
		Object [] keyArr;
		OmfChatObject chatObj;
		Date now, lastTouch, lastFlush;
		long diff, tm;
		
		// get the online presence Hash object
		HashMap onlineHash = OmfPresence.getHash();

		while (getRunning())
		{
			boolean bOutput = false;
			Calendar cal = Calendar.getInstance();
			if (cal.get(Calendar.HOUR)==0 && cal.get(Calendar.MINUTE)<=4)
				bOutput = true;		// write info twice a day only
			
			if (bOutput)
				l.info(">>> OmfChatThread start working ...");
			
			now = cal.getTime();
			tm = now.getTime();
			
			//////////////////////////////////////////////////////////////////////////////////
			// Run the following every WORKER_PERIOD when I wake up
			//
			
			////////////////////////
			// Flush chat or deallocate chat object
			keyArr = chatHash.keySet().toArray();
			for (int i=0; i<keyArr.length; i++)
			{
				chatObj = OmfChat.getChatObjectInHash((String)keyArr[i]);
				if (chatObj == null) continue;
				
				// check to see if there is anything in OmfChat Hash that needs to be flushed to DB
				if (chatObj.isDirty())
				{
					lastFlush = chatObj.getLastFlush();
					diff = tm - lastFlush.getTime();
					if (diff > MEM_COMMIT_PERIOD)
					{
						// save the chat object to DB
						try
						{
							chatObj.save(jwu);
							l.info("OmfChatThread saved chat ["+ keyArr[i] + "]");
						}
						catch (PmpException e) {l.error("OmfChatThread.run(): failed to save chatObj [" + keyArr[i] + "]");}
					}
				}
				
				// check to see if there are inactive chat session that I need to deallocate memory
				//lastTouch = chatObj.getLastTouch();
				// ECC: should do getLastTouch()
				lastTouch = new Date();
				diff = tm - lastTouch.getTime();
				if (diff > MEM_CLEANUP_PERIOD)
				{
					// do clean up of memory
					OmfChat.removeChatObj(null, chatObj.getObjectId(), false);
					l.info("OmfChatThread removed chat object from memory ["+ keyArr[i] + "]");
				}
			}

			////////////////////////
			// @ECC020808 Check online user status
			keyArr = onlineHash.keySet().toArray();
			for (int i=0; i<keyArr.length; i++)
			{
				lastTouch = (Date)onlineHash.get(keyArr[i]);
				if (lastTouch == null) continue;
				diff = tm - lastTouch.getTime();
				if (diff > INACTIVE_PERIOD)
				{
					// 15 min inactive: consider he has logout
					OmfPresence.setOffline((String)keyArr[i]);
				}
			}
			
			//////////////////////////////////////////////////////////////////////////////////
			// Run the following nightly
			
			////////////////////////
			// check to see if there are DB chats that had not been updated for FORGOTTEN_PERIOD
			// remove them from DB
			if (cal.get(Calendar.HOUR_OF_DAY)==2 && cal.get(Calendar.MINUTE)<=4)
			{
				try
				{
					int [] ids = cMgr.findId(jwu, "om_acctname='%'");
					PstAbstractObject o;
					for (int i=0; i<ids.length; i++)
					{
						o = cMgr.get(jwu, ids[i]);
						lastFlush = (Date)o.getAttribute("LastUpdatedDate")[0];
						if (lastFlush != null) {
							diff = now.getTime() - lastFlush.getTime();
							if (diff > FORGOTTEN_PERIOD)
							{
								// remove this chat DB object
								cMgr.delete(o);
								l.info("*** Removed chat DB object [" + ids[i] + "]: last updated on " + lastFlush.toString());
							}
						}
						else {
							o.setAttribute("LastUpdatedDate", now);
							cMgr.commit(o);
						}
					}
				}
				catch (PmpException e) {l.error("OmfChatThread.run(): failed in cleaning up chat DB objects.");}
			}
			
			if (bOutput)
				l.info("<<< OmfChatThread goto sleep (" + new Date().toString() +")");
			try {Thread.sleep(WORK_PERIOD*60000);}		// check once every 5 min
			catch (InterruptedException e) {}
		}
	}
	
	public synchronized static boolean getRunning() {return OmfChatThread.running;}
	
	private synchronized static boolean setRunning(boolean running) {
		OmfChatThread.running = running;
		return OmfChatThread.running;
	}
	
	private synchronized static boolean checkCanRun() {
		if (!getRunning()) {
			setRunning(true);
			return true;
		}
		else
			return false;
	}
}
