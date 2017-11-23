//
//	Copyright (c) 2006 EGI Technologies.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
// $Header$
//
//	File:	$RCSfile$
//	Author:	Allen G Quan (AGQ)
//	Date:	$Date$
//  Description:
//      Stores current meeting's participants that are required for
//		input into the meeting minutes. 
//
//	Modification:
//		@ECC100606	Send only the newly inserted chat content rather than the whole minute.
//
/////////////////////////////////////////////////////////////////////

package mod.mfchat;

import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;

import org.apache.log4j.Logger;

import util.PrmColor;
import util.PrmLog;
import util.PrmMtgConstants;
import util.PrmUpdateCounter;

public class MeetingParticipants {
	static Logger l;
	static final int SECONDS;					// Number of seconds before user is considered offline
	
	private static HashMap meetingCount;		// Stores the current session number
	private static HashMap meetingOnline;		// Stores the current online members
	private static HashMap meetingParticipants;	// Stores the meeting and the current invited participants
	private static HashMap meetingRevokeTime;	// Stores the current revoking time
	private static HashMap meetingColor; 		// Stores the colors for the current users
	private static HashMap meetingPosition;		// Stores the position for the current index
	private static HashMap meetingCharBefore;	// Stores the character for the before the index
	private static HashMap meetingCharAfter;	// Stores the character for the after the index
	private static HashMap meetingObject;		// Stores an empty object for synchronization within meetings
	private static HashMap meetingExprQueue;	// @ECC092806 Stores the expression queue for each meeting
	private static HashMap meetingChatQueue;	// @ECC092806 Stores the chat queue and string buffer for each meeting
	private static HashMap meetingInputQueue;	// @ECC101106 Input queues for each meeting
	
	// Initialize static variables
	static {
		l = PrmLog.getLog();
		SECONDS					= 5;
		meetingCount			= new HashMap();
		meetingOnline			= new HashMap();
		meetingParticipants 	= new HashMap();
		meetingRevokeTime 		= new HashMap();
		meetingColor			= new HashMap();
		meetingPosition			= new HashMap();
		meetingCharBefore		= new HashMap();
		meetingCharAfter		= new HashMap();
		meetingObject			= new HashMap();
		meetingExprQueue		= new HashMap();
		meetingChatQueue		= new HashMap();
		meetingInputQueue		= new HashMap();
	}
	
	/**
	 * Sets the current meeting's participants. If uidArr is null, then meetingParticipants
	 * will not be set. 
	 * @param midS		Meeting ID
	 * @param uidArr	User ID in String Array format or null if it is facilitator
	 */
	synchronized public static void setMeetingParticipants(String midS, String [] uidArr) {
		if (midS!=null) {
			if (uidArr!=null)
				meetingParticipants.put(midS, uidArr);
			else
				meetingParticipants.remove(midS);
		}
	}
	
	synchronized public static void setMeetingRevokeTime(String midS, String seconds) {
		if (seconds!=null) {
			try {
				setMeetingRevokeTime(midS, Integer.valueOf(seconds));
			} catch (NumberFormatException e) {
				l.error(e.getMessage());
			}
		}
	}
	
	synchronized public static void setMeetingRevokeTime(String midS, int seconds) {
		setMeetingRevokeTime(midS, Integer.valueOf(seconds));
	}
	
	/**
	 * Sets midS revoke time to seconds. Currently revoked users will use this
	 * time to see how much longer they car input minutes.
	 * @param midS
	 * @param seconds
	 */
	synchronized public static void setMeetingRevokeTime(String midS, Integer seconds) {
		if (midS!=null) {
			if (seconds!=null)
				meetingRevokeTime.put(midS, seconds);
		}
	}
	
	synchronized public static void setPosition(String midS, String posS) {
		if (midS!=null) {
			if (posS!=null) {
				try {
					Integer pos = Integer.valueOf(posS);	
					meetingPosition.put(midS, pos);
				} catch (NumberFormatException e) {
					l.error(e.getMessage());
				}
			}
		}
	}
	
	//////////////////////////////////////////////////
	// @ECC092806 Begin
	synchronized public static OmfQueue initExprQueue(String midS) {
		// initialize the queue and put it in the hash for a new meeting
		if (midS!=null) {
			OmfQueue q = (OmfQueue) meetingExprQueue.get(midS);
			if (q != null) return q;		// already initialized
			q = new OmfQueue();				// use default size
			meetingExprQueue.put(midS, q);
			return q;
		}
		return null;
	}
	
	/**
	 * @see removeHashMap(String midS)
	 * @param midS
	 */
	synchronized public static void removeExprQueue(String midS) {
		// remove the queue of a meeting (when adjourn)
		if (midS!=null && meetingExprQueue.containsKey(midS)) {
			meetingExprQueue.remove(midS);
		}
	}

	public static void addExpr(String midS, OmfExpr expr) {
		// add an expression to a meeting queue: it will be synchronize by the enqueue() method
		if (midS!=null) {
			OmfQueue q = (OmfQueue) meetingExprQueue.get(midS);
			if (q == null)
				q = (OmfQueue) initExprQueue(midS);	// need to initialize the queue
			
			// if queue is full (overflow) simply ignore the enqueu and log a message
			if (!q.enqueue(expr))
				l.info("Expression queue [" +midS + "] overflow: advise to increase OmfQueue:MAX_QUEUE_SIZE value.");
		}
	}

	/**
	 * Retrieves the meeting's expression from the queue
	 * @param midS	Meeting ID
	 * @param idx	last retrieved element number
	 * @return		The string containing all unread expr pair encoded in the format nextIdx::id1:str1::id2:str2 ...
	 */
	public static String getUnreadExpr(String midS, int idx, boolean bCleanUp) {
		if (midS!=null) {
			OmfQueue q = (OmfQueue) meetingExprQueue.get(midS);
			if (q == null)
				q = (OmfQueue) initExprQueue(midS);	// need to initialize the queue
			String ret = "";
			OmfExpr e;
			if (idx < 0)
			{
				if (idx == -1)
				{
					idx = q.getIndex();		// this is a new guy, ignore any old expressions on queue
					return (String.valueOf(idx));
				}
				else if (idx < -1)
					idx = q.getLastIndex();	// this is a new guy but he has just sent an expression
			}
			
			while ((e = (OmfExpr)q.peek(idx)) != null)
			{
				if (ret.length()>0) ret += "@@";		// id1@@str1@@id2:str2 ...
				ret += e.getId() + ":" + e.getStr();
				idx++;
			}
			if (ret.length() > 0)
				ret = idx + "@@" + ret;					// nextIdx@@id1:str1@@id2:str2 ...
			if (bCleanUp)
				q.setQueueHead(PrmMtgConstants.MAX_WAIT_ON_QUEUE);	// clean up anything more than MAX_WAIT_ON_QUEUE
			return (ret);
		}
		else {
			return null;
		}
	}
	// @ECC092806 End
	
	//////////////////////////////////////////////////
	// @ECC100606 Begin
	synchronized public static OmfQueue initChatQueue(String midS) {
		// initialize the queue and put it in the hash for a new meeting
		if (midS!=null) {
			OmfQueue q = (OmfQueue) meetingChatQueue.get(midS);
			if (q != null) return q;		// already initialized
			q = new OmfQueue(OmfQueue.iCHAT_QUEUE, OmfQueue.MAX_QUEUE_SIZE);	// init queue with string buffer
			meetingChatQueue.put(midS, q);
			return q;
		}
		return null;
	}
	
	/**
	 * @see removeHashMap(String midS)
	 * @param midS
	 */
	synchronized public static void removeChatQueue(String midS) {
		// remove the queue of a meeting (when adjourn)
		if (midS!=null && meetingChatQueue.containsKey(midS)) {
			meetingChatQueue.remove(midS);
		}
	}

	public static void addChat(String midS, StringBuffer chatStr) {
		// add a chat element to a meeting queue: it will be synchronize by the enqueue() method
		if (midS!=null) {
			OmfQueue q = (OmfQueue) meetingChatQueue.get(midS);
			if (q == null)
			{
				// need to initialize the queue
				q = (OmfQueue) initChatQueue(midS);
			}
			// insert the chat string into the string buffer and then insert element into queue
			int offset = q.insertChat(chatStr);
			int length = chatStr.length();
			OmfChatElement chat = new OmfChatElement(offset, length);
			
			// if queue is full (overflow) simply ignore the enqueue and log a message
			if (!q.enqueue(chat))
				l.info("Chat queue [" +midS + "] overflow: advise to increase OmfQueue:MAX_QUEUE_SIZE value.");
		}
	}

	/**
	 * Retrieves the meeting's chat elements from the queue as a compacted string
	 * @param midS	Meeting ID
	 * @param idx	last retrieved element number
	 * @return		The string containing all unread chat strings compacted in a string
	 */
	public static String getUnreadChat(String midS, int idx, boolean bCleanUp) {
		if (midS!=null && meetingChatQueue.containsKey(midS)) {
			OmfQueue q = (OmfQueue) meetingChatQueue.get(midS);
			StringBuffer ret = new StringBuffer();
			OmfChatElement e;
			int off, len;
			StringBuffer buf = q.getBuffer();
			idx -= q.getIdxDiff();

			while ((e = (OmfChatElement)q.peek(idx)) != null)
			{
				off = e.getOffset();
				len = e.getLength();
				ret.append(buf.substring(off, off+len));
				idx++;
			}
			if (bCleanUp)
				q.setQueueHead(PrmMtgConstants.MAX_WAIT_ON_QUEUE);	// clean up anything more than MAX_WAIT_ON_QUEUE
			return (ret.toString());
		}
		else {
			return null;
		}
	}
	
	public static void setMeetingChatIdx(String midS)
	{
		if (midS!=null && meetingChatQueue.containsKey(midS)) {
			removeChatQueue(midS);
		}
		OmfQueue q = (OmfQueue) initChatQueue(midS);
		int mnCount = PrmUpdateCounter.getMtgCounters(midS)[PrmMtgConstants.MNINDEX];
		q.setIdxDiff(mnCount);
	}
	// @ECC100606 End
	
	//////////////////////////////////////////////////
	// @ECC101106 Begin
	synchronized public static OmfQueue initInputQueue(String midS) {
		// initialize the queue and put it in the hash for a new meeting
		if (midS!=null) {
			OmfQueue q = (OmfQueue) meetingInputQueue.get(midS);
			if (q != null) return q;		// already initialized
			q = new OmfQueue(OmfQueue.iINPUT_QUEUE, OmfQueue.MAX_INPUT_QUEUE_NUM);
			meetingInputQueue.put(midS, q);
			return q;
		}
		return null;
	}
	
	/**
	 * @see removeHashMap(String midS)
	 * @param midS
	 */
	synchronized public static void removeInputQueue(String midS) {
		// remove the queue of a meeting (when adjourn)
		if (midS!=null && meetingInputQueue.containsKey(midS)) {
			meetingInputQueue.remove(midS);
		}
	}

	public static void addToInputQueue(String midS, String uid) {
		// add a user to the meeting input queue: it will be synchronize by the enqueue() method
		if (midS!=null) {
			OmfQueue q = (OmfQueue) meetingInputQueue.get(midS);
			if (q == null)
			{
				// need to initialize the queue
				q = (OmfQueue) initInputQueue(midS);
			}
			// insert the uid into the queue
			// if the user is already on queue, ignore
			if (q.found(uid)) return;
			
			// if queue is full (overflow) simply ignore the enqueue and log a message
			if (!q.enqueue(uid))
				l.info("Input queue [" +midS + "] overflow: advise to increase OmfQueue:MAX_QUEUE_SIZE value.");
			PrmUpdateCounter.updateOrCreateCounterArray(midS, PrmMtgConstants.ININDEX);
		}
	}

	public static void removeFromInputQueue(String midS, String uid) {
		// remove a user from the meeting input queue: it will be synchronize by the dequeue() method
		if (midS!=null) {
			OmfQueue q = (OmfQueue) meetingInputQueue.get(midS);
			if (q == null) return;
			q.dequeue(uid);	// remove the uid from the queue
			PrmUpdateCounter.updateOrCreateCounterArray(midS, PrmMtgConstants.ININDEX);
		}
	}
	
	/**
	 * Retrieves the input queue contents back as a compacted string
	 * @param midS	Meeting ID
	 * @return		The string containing all users on queue compacted in a string
	 */
	public static String getAllOnQueue(String midS) {
		if (midS!=null && meetingInputQueue.containsKey(midS)) {
			OmfQueue q = (OmfQueue) meetingInputQueue.get(midS);
			if (q == null) return null;		// not init yet
			
			StringBuffer ret = new StringBuffer();
			int idx = q.getHead();
			String s;
			
			// first see if there is an input user, if so include that with *user1
			if ((s = q.getInputUser()) != null)
				ret.append("*" + s);	// e.g. *edwardc

			while ((s = (String)q.peek(idx)) != null)
			{
				if (ret.length() > 0) ret.append(":");	// return string edwardc:allenq: ...
				ret.append(s);
				idx = q.incIdx(idx);
			}
			return (ret.toString());
		}
		else {
			return null;
		}
	}
	
	public static String getRemoveAllOnQueue(String midS)
	{
		if (midS!=null && meetingInputQueue.containsKey(midS)) {
			OmfQueue q = (OmfQueue) meetingInputQueue.get(midS);
			if (q == null) return null;		// not init yet
			
			StringBuffer ret = new StringBuffer();
			int idx = q.getHead();
			String s;
			
			// first see if there is an input user, if so include that
			if ((s = q.getInputUser()) != null)
				ret.append(s);	// no star * needed

			while ((s = (String)q.peek(idx)) != null)
			{
				if (ret.length() > 0) ret.append(":");	// return string edwardc:allenq: ...
				ret.append(s);
				q.dequeue(s);	// remove the uid from the queue
				idx = q.incIdx(idx);
			}
			PrmUpdateCounter.updateOrCreateCounterArray(midS, PrmMtgConstants.ININDEX);
			return (ret.toString());
		}
		else {
			return null;
		}
	}
	
	public static String getInputUser(String midS) {
		if (midS!=null && meetingInputQueue.containsKey(midS)) {
			OmfQueue q = (OmfQueue) meetingInputQueue.get(midS);
			if (q == null) return null;		// not init yet
			
			return q.getInputUser();
		}
		else return null;
	}
	
	public static void setInputUser(String midS, String uname) {
		if (midS != null) {
			OmfQueue q = (OmfQueue) meetingInputQueue.get(midS);
			if (q == null) return;		// not init yet
			q.setInputUser(uname);
			PrmUpdateCounter.updateOrCreateCounterArray(midS, PrmMtgConstants.ININDEX);
		}
	}
	
	public static String getInputQHead(String midS){
		if (midS != null) {
			OmfQueue q = (OmfQueue) meetingInputQueue.get(midS);
			if (q == null) return null;		// not init yet
			int idx = q.getHead();
			return (String)q.peek(idx);
		}
		else
			return null;
	}
	// @ECC101106 End
	
	synchronized public static void setCharBefore(String midS, String charBefore) {
		if (midS!=null) {
			if (charBefore!=null) {
				meetingCharBefore.put(midS, charBefore);
			}
		}
	}
	
	synchronized public static void setCharAfter(String midS, String charAfter) {
		if (midS!=null) {
			if (charAfter!=null) {
				meetingCharAfter.put(midS, charAfter);
			}
		}
	}
	
	synchronized public static Object getObject(String midS) {
		if (midS!=null) {
			if (meetingObject.containsKey(midS)) {	
				return meetingObject.get(midS);
			}
			else {		
				Object obj = new Object();				
				meetingObject.put(midS, obj);
				return obj;
			}
		}
		// No mid specified return a new dummy Object
		return new Object();
	}
	
	synchronized public static int getSessionCount(String midS) {
		if (midS!=null) {
			if (meetingCount.containsKey(midS)) {
				Integer posI = (Integer) meetingCount.get(midS);
				if (posI != null) {
					int pos = posI.intValue();
					pos++;
					meetingCount.put(midS, Integer.valueOf(pos));							
					return pos;
				}
			}
			else {
				meetingCount.put(midS, Integer.valueOf(1));
				return 1;
			}
		}
		return -1;
	}
	
	synchronized public static int getCurPosition(String midS, int length) {
		if (midS!=null) {
			if (meetingPosition.containsKey(midS)) {
				Integer posI = (Integer) meetingPosition.get(midS);
				if (posI != null) {
					int pos = posI.intValue();
					int newPos = pos + length;
					meetingPosition.put(midS, Integer.valueOf(newPos));
					return pos;
				}
			}
		}
		return -1;
	}
	
	synchronized public static String getCurCharBefore(String midS) {
		if (midS!=null) {
			if (meetingCharBefore.containsKey(midS)) {
				return (String) meetingCharBefore.get(midS);
			}
		}
		return null;
	}
	
	synchronized public static String getCurCharAfter(String midS) {
		if (midS!=null) {
			if (meetingCharAfter.containsKey(midS)) {
				return (String) meetingCharAfter.get(midS);
			}
		}
		return null;
	}
	
	synchronized public static String getMeetingColor(String midS, String idS) {
		if (midS!=null) {
			if (meetingColor.containsKey(midS)) {
				PrmColor prmColor = (PrmColor) meetingColor.get(midS);
				return prmColor.getColor(idS);
			}
			else {
				PrmColor prmColor = new PrmColor();
				meetingColor.put(midS, prmColor);
				return prmColor.getColor(idS);
			}
		}
		return "";
	}
	
	/**
	 * Retreives the meeting participants from memory
	 * @param midS		Meeting ID
	 * @return 			A String [] of IDs that can participate in the chat session now 
	 * 					or null if not found. 
	 */
	public static String [] getMeetingParticipants(String midS) {
		if (midS!=null && isOn(midS))
			return (String []) meetingParticipants.get(midS);
		else
			return null;
	}
	
	/**
	 * Determines if currently Facilitator has turned on
	 * invite for Participants to submit opinion.
	 * @param midS	Meeting ID
	 * @return 		true or false
	 */
	public static boolean isOn(String midS) {
		if (midS!=null)
			return meetingParticipants.containsKey(midS);
		else
			return false;
	}
	
	/**
	 * Determines if uid is part of the participants
	 * @param midS	Meeting ID
	 * @param uid	Current user ID
	 * @return		true if is part of the current input (chat) session otherwise false
	 */
	public static boolean isParticipant(String midS, String uid) {
		boolean isParticipant = false;
		if (midS!=null && uid!=null) {
			String [] pidArr = getMeetingParticipants(midS);
			if (pidArr!=null) {
				for (int i=0; i<pidArr.length; i++) {
					if (pidArr[i].equals(uid)) {
						isParticipant = true;
						break;
					}
				}
			}
		}
		return isParticipant;
	}
	
	/**
	 * Retrieves the meeting's revoke time
	 * @param midS	Meeting ID
	 * @return		The time left in Integer form
	 */
	public static Integer getRevokeTime(String midS) {
		if (midS!=null && meetingRevokeTime.containsKey(midS)) {
			return (Integer) meetingRevokeTime.get(midS);
		}
		else {
			return null;
		}
	}
	
	public static void setOnline(String midS, String idS) {
		if (midS!=null && idS!=null) {
			synchronized (getObject(midS)) {
				if (meetingOnline.containsKey(midS)) {
					HashMap map = (HashMap) meetingOnline.get(midS);
					Long time = Long.valueOf((new Date()).getTime());
					map.put(idS, time);
				}
				else {
					HashMap map = new HashMap();
					meetingOnline.put(midS, map);				
				}
			}
		}
	}
	
	public static void setOffline(String midS, String idS) {
		if (midS!=null && idS!=null) {
			synchronized (getObject(midS)) {
				if (meetingOnline.containsKey(midS)) {
					HashMap map = (HashMap) meetingOnline.get(midS);
					if (map.containsKey(idS))
						map.remove(idS);
				}
			}
		}
	}
	
	public static boolean isOnline(String midS, String idS) {
		if (midS!=null && idS!=null) {
			if (meetingOnline.containsKey(midS)) {
				HashMap map = (HashMap) meetingOnline.get(midS);
				return map.containsKey(idS);
			}
		}
		return false;
	}
	
	public static String getAllOnline(String midS)
	{
		if (midS!=null && meetingOnline.containsKey(midS)) {
			HashMap map = (HashMap) meetingOnline.get(midS);
			Object [] arr = map.keySet().toArray();
			String ret = "";
			for (int i=0; i<arr.length; i++)
			{
				if (ret.length() > 0) ret += ":";
				ret += arr[i].toString();
			}
			return (ret);
		}
		else {
			return null;
		}
	}
	
	/**
	 * Checks to see if the online time has expired.  
	 * @param midS
	 */
	public static void clearOnline(String midS) {
		if (midS!=null) {
			synchronized (getObject(midS)) {
				if (meetingOnline.containsKey(midS)) {
					Date d = new Date();
					long curTime = d.getTime();
					long time;
					HashMap map = (HashMap) meetingOnline.get(midS);			
					Iterator iter = map.keySet().iterator();
					boolean removed = false;
					while(iter.hasNext()) 
					{
						Object key = iter.next();
						Long timeL = (Long) map.get(key);
						time = timeL.longValue();
						if ((curTime - time) > (SECONDS * 4 * 1000)) {	// ECC: added *4 to prolong detecting offline
							iter.remove();
							if (!removed)
								removed = true;
						}
					}
					if (removed) {
						PrmUpdateCounter.updateOrCreateCounterArray(midS, PrmMtgConstants.ADINDEX);
					}
				}
			}
		}
	}
	
	public static int usersOnline(String midS) {
		if (midS!=null) {
			if (meetingOnline.containsKey(midS)) {
				HashMap map = (HashMap) meetingOnline.get(midS);
				return map.size();
			}
		}
		return 0;
	}
	
	/**
	 * Removes all the hashmap fields related to the meeting
	 * with meeting ID midS
	 * @param midS
	 */
	public static void removeHashMap(String midS) {
		if (midS!=null) {
			Object obj = getObject(midS);
			synchronized (obj) {
				meetingCount.remove(midS);
				meetingOnline.remove(midS);
				meetingParticipants.remove(midS);
				meetingRevokeTime.remove(midS);
				meetingColor.remove(midS);
				meetingPosition.remove(midS);
				meetingCharBefore.remove(midS);
				meetingCharAfter.remove(midS);
				meetingExprQueue.remove(midS);
				meetingChatQueue.remove(midS);
				meetingInputQueue.remove(midS);
			}
			removeMtgObj(midS);
		}
	}
	
	synchronized private static void removeMtgObj(String midS) {
		if (midS!=null) {
			meetingObject.remove(midS);
		}
	}
}