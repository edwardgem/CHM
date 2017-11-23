////////////////////////////////////////////////////
//	Copyright (c) 20067, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	OmfChatObject.java
//	Author:	ECC
//	Date:	11/14/07
//	Description:
//		Implementation of OmfChatObject class.  There are two paths in participating in a chat.
//		First the web browser is using XML and manipulating by blocks kept in the chatBuf in memory.
//		Second is mobile App is handling one message at a time.  Originally we flush the chatBuf to
//		Content, but not anymore.  Content will be used to keep images and voice.  But all messages
//		are kept one by one in Messages (an OMM multi-String attribute).
//		
//		OmfChatAjax class handles the Http interactions.
//		OmfChat class handles mobile methods.
//
//		Key Design Note:
//      ------------------
//		START: At START CHAT time, messages are read (a) into chatBuf by getMake() for web; (b) constructed
//		by getChatMessages() in real-time for mobile.
//
//		POST: When someone post a chat message, it will be written to the DB and if chatBuf is not null, then
//		also insert into the buffer.  This is done for both web or mobile post.
//
//		READ: To support multiple virtual machines, chatBuf might be out of sync, we should keep the refresh
//		timestamp in memory so that on read chatBuf, we compare the timestamp with the LastUpdatedDate
//		of the chat in OMM, and decide if we need to refresh the chatBuf.
//
//		SAVE: no need to take care of chat messages because every post will write to OMM DB.
//
//	Modification:
//		@ECC101508	Allow user to change color.
//		@ECC141007	Support Mobile App, change chat message format:
//					<chat-123><chat-date=2014-10-5 15:32:18 /><chat-user=12345 />text</chat-123>
//
////////////////////////////////////////////////////////////////////

package mod.mfchat;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.Enumeration;
import java.util.Hashtable;

import oct.codegen.chat;
import oct.codegen.chatManager;
import oct.codegen.event;
import oct.codegen.meeting;
import oct.codegen.meetingManager;
import oct.codegen.project;
import oct.codegen.projectManager;
import oct.codegen.townManager;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.codegen.userinfo;
import oct.pmp.exception.PmpException;
import oct.pmp.exception.PmpInternalException;
import oct.pmp.exception.PmpObjectNotFoundException;
import oct.pst.PstAbstractObject;
import oct.pst.PstUserAbstractObject;

import org.apache.commons.io.FileUtils;
import org.apache.log4j.Logger;

import util.Prm;
import util.PrmColor;
import util.PrmEvent;
import util.PrmLog;
import util.StringUtil;
import util.Util;
import util.Util2;

/**
 * @author edwardc
 *
 */
public class OmfChatObject
{
	public static final String OPENTAG1		= "<chat-";
	public static final String OPENTAG2		= ">";
	public static final String CLOSETAG1	= "</chat-";
	public static final String CLOSETAG2	= ">";
	public static final String DIVOPEN		= "<DIV>";
	public static final String DIVCLOSE		= "</DIV>";
	public static final String DATETAG		= "<DIV class='date'>";
	public static final String TIMETAG		= "<SPAN class='com_date'>";
	public static final String SPANCLOSE	= "</SPAN>";
	public static final String MSG_DATETAG1	= "<chat-date ";
	public static final String MSG_DATETAG2	= " />";
	public static final String MSG_USERTAG1	= "<chat-user ";
	public static final String MSG_USERTAG2	= " />";

	public static final int ST_NEW			= 0;			// newly instantiated memory object, not filled
	public static final int ST_CREATED		= 1;			// brand new chat, just created now in DB
	public static final int ST_FILLED		= 2;			// just filled with DB content, ready to be active
	public static final int ST_ACTIVE		= 3;			// active now
	public static final int ST_DIRTY		= 4;			// just inserted text, active
	public static final int ST_FLUSHED		= 5;			// just flushed to DB, active
	public static final int ST_MOVED		= 6;			// just moved the chat to meeting, INACTIVE
	
	public static final String REGEX_DEV_ID	= "<DEV_ID=(\\d)*\\/>";
	
	private static final long MIN_15			= 15 * 60000;
	private static final long HOUR_1			= 60 * 60000;
	
	private static final int CHAT_SEGMENT_SIZE	= 30;		// 30 chat messages in each segment
	
	private static final SimpleDateFormat df0 = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
	private static final SimpleDateFormat df1 = new SimpleDateFormat ("MM/dd/yy (EEE)");
	private static final SimpleDateFormat df2 = new SimpleDateFormat ("(h:mm a)");
	private static final SimpleDateFormat df3 = new SimpleDateFormat("yyyy-MM-dd");
	private static final String LOCATION	= "MeetWE chat room";
	
	static Logger l;
	private String chatObjIdS;
	private String name;				// the readable name of the chat object
	private int lastIdInBuffer;
	private StringBuffer chatBuf;
	private PrmColor color;
	private String chatUsers;			// edwardc; tlo; ... (with all font color specified)
	private Date lastFlush;				// last timestamp when chat is flushed to DB
	private int state;					// the state can be ST_NEW, ST_FILLED, ST_DIRTY, ST_FLUSHED, ST_MOVED
	private String midS;				// the meeting id if the chat is moved to a meeting
	private String circleName;			// store the circle name if it is a circle chat
	private String circleIdS;			// store the circle Id if it is a circle chat
	private String projIdS;				// store the proj Id if it is a proj chat
	private int	triggerEvtUid;			// the user who should trigger Start Chat event on his next insert text
	private String otherUidS;			// remember the other uid for 1-on-1 chat
	private Hashtable<String, String> colorMap;			// @ECC101508 map user id to a color string
	
	private chat ommChatObj;			// the OMM chat

	private static userManager 		uMgr;
	private static chatManager 		cMgr;
	private static townManager 		tnMgr;
	private static projectManager 	pjMgr;
	private static PstUserAbstractObject	jwu;
	
	protected static boolean bDebug = false;			// set by OmfChatAjax.java, turn on debuf in chat.js

	public StringBuffer getChatBuf() {return chatBuf;}
	public String getObjectId() {return chatObjIdS;}
	public int length() {return chatBuf==null?0:chatBuf.length();}
	public String getUsers() {return chatUsers;}
	public String getColor(String idS) {return (String)colorMap.get(idS);}
	public Date getLastFlush() {return lastFlush;}
	public String getCircleName() {return circleName;}
	public String getCircleId() {return circleIdS;}
	public String getProjectId() {return projIdS;}
	public String getOtherUid() {return otherUidS;}
	public String getName() {return name;}				// chat name
	public void setName(String nm) {name = nm;}			// only in memory

	public boolean isFresh() {return (state<=ST_FILLED);}
	public boolean isDirty() {return (state==ST_DIRTY);}
	public boolean isMoved() {return (state==ST_MOVED);}
	public boolean isJustCreated() {return (state==ST_CREATED);}
	
	public boolean isCircleChat() {return (circleName!=null);}
	public void setState(int st) {state = st;}
	public String getMeetingId() {return midS;}
	
	public boolean bNeedTriggerEvt(int uid) {return (uid==triggerEvtUid);}
	public void setTriggerEvt(int uid) {triggerEvtUid = uid;}
	
	protected static void setDebug(boolean debug) {bDebug = debug;}		// called by OmfChatAjax
	
	
	static
	{
		l = PrmLog.getLog();
		initMgr();
	}
	
	private static void initMgr()
	{
		try
		{
			uMgr = userManager.getInstance();
			cMgr = chatManager.getInstance();
			tnMgr = townManager.getInstance();
			pjMgr = projectManager.getInstance();
			
			jwu = Prm.getSpecialUser();
		}
		catch (PmpException e) {uMgr=null; cMgr=null; tnMgr=null; pjMgr=null;}
	}
	
	public OmfChatObject(String idS)
	{
		chatObjIdS = idS;
		name = "";
		chatBuf = null;					// if mobile only in chat, this is null
		lastIdInBuffer = -1;			// ECC: obsolete
		color = new PrmColor();
		chatUsers = "";
		state = ST_NEW;
		midS = null;
		circleName = null;
		circleIdS = null;
		projIdS   = null;
		lastFlush = new Date();			// ECC: obsolete
		triggerEvtUid = 0;
		otherUidS = null;
		colorMap = new Hashtable<String, String>(10);
		// need to upload the chat object from db
		ommChatObj = null;
	}
	
	protected chat getOMMChatObject()
		throws PmpObjectNotFoundException, PmpInternalException
	{
		// always get it from OMM DB afresh
		ommChatObj = (chat) cMgr.get(jwu, chatObjIdS);
		return ommChatObj;
	}
	// each chat message if: <chat-123><chat-date 2014-10-5 15:32:18 /><chat-user 12345 />text</chat-123>
	
	/**
	 * When the mobile device first initialize the display, it will just call to get the latest
	 * segment, without any lastMsgId.  But once it started chatting, it will only want to retrieve
	 * newer chat text after the lastMsgId.
	 * 
	 * @param segmentNum
	 * @return
	 * @throws PmpException
	 */
	protected ArrayList <String> getChatSegment(int segmentNum)
		throws PmpException
	{
		return getChatSegment(segmentNum, -1, false);
	}
	
	/**
	 * get a segment of chat messages from OMM DB.  Called by both mobile and web.
	 * @param segmentNum
	 * @param lastMsgId if provided, exclude this msgId and anything before
	 * @param isMobile	call from Mobile App - take out the device ID (DEV_ID) tag
	 * @return
	 * @throws PmpException
	 */
	protected ArrayList <String> getChatSegment(int segmentNum, int lastMsgId, boolean isMobile)
		throws PmpException
	{
		// if segmentNum = 0, get the latest CHAT_SEGMENT_SIZE number of chat messages;
		// 1 is the previous segment, etc.
		System.out.println("-- calling getChatSegment("
						+ segmentNum + ", " + lastMsgId + ")");
		ArrayList <String> cMsgArrList = new ArrayList <String> ();
		int lastId = getLastMessageID();
		chat cObj = ommChatObj;
		
		// ECC: watch out for performance hit when there are a lot of chat messages
		Object [] chatMessages = cObj.getAttribute("Messages");				// need to sort them or put in hash
		sortMessages(chatMessages);											// sort message by chat-id tag
		int totalMessages = chatMessages.length;
		int idx = totalMessages - ((segmentNum+1) * CHAT_SEGMENT_SIZE);
		if (idx < 0) {
			// total chat msg in the DB is less than segment size: return all
			idx = 0;
		}

		// extract the corresponding segment
		String msg;
		int msgId;
		for (int i=0; i<CHAT_SEGMENT_SIZE && idx<totalMessages; i++) {
			if ((msg = (String) chatMessages[idx++]) == null) break;
			if (lastMsgId >= 0) {
				// exclude lastMsgId and anything smaller
				msgId = getMessageId(msg);
				if (msgId <= lastMsgId)
					continue;				// exclude this older message
			}
			
			// for mobile, remove the DEV_ID tag: <DEV_ID=..../>
			if (isMobile)
				msg = msg.replaceFirst(REGEX_DEV_ID, "");
			
			cMsgArrList.add(msg);
		}

		// if extracting the last segment, might need to initialize the lastIdInBuffer
		if (segmentNum==0 && cMsgArrList.size()>0) {
			msg = cMsgArrList.get(cMsgArrList.size()-1);		// get the last element			
			lastIdInBuffer = getMessageId(msg);
			if (lastId < lastIdInBuffer) {
				// need to re-initialize lastID
				cObj.setAttribute("LastID", lastIdInBuffer);
				cMgr.commit(cObj);
			}
		}

		return cMsgArrList;
	}
	
	

	private void sortMessages(Object[] msgArr)
	{
		// sort by the <chat-123 tag
		boolean swap;
		int i1, i2;
		String temp;
		do
		{
			swap = false;
			for (int i=0; i<msgArr.length-1; i++)
			{
					i1 = getMessageId((String) msgArr[i]);
					i2 = getMessageId((String) msgArr[i+1]);

					if (i1 > i2)
					{
						// swap the element
						temp		= (String) msgArr[i];
						msgArr[i]	= msgArr[i+1];
						msgArr[i+1]	= temp;
						swap = true;
					}
			}
		} while (swap);
	}
	
	/**
	 * For web client: return the lastID and the chat buffer content excluding reqIdx.
	 * e.g. 12345: return from 12346 and all the new messages after that.
	 * If reqIdx is the lastID, nothing ("") needs to be returned.
	 * @param reqIdx
	 * @param retBuf
	 * @return
	 */
	public int extractChatBlock(int reqIdx, StringBuffer retBuf)
		throws PmpException
	{
		int lastId = getLastMessageID();
		if (lastId > lastIdInBuffer) {
			// need to refresh the buffer
			fillChatBuf(true);
		}
		
		synchronized (this)
		{
			if (this.length() <= 0) return 0;			// check chatBuf empty
			
			int idx = -1;
			String s;

			if (reqIdx > -1) {
				// search for <chat-123>
				s = OPENTAG1 + reqIdx + OPENTAG2;
				idx = chatBuf.indexOf(s);
			}
			
			if (idx == -1)
			{
				// can't find the requested message ID
				retBuf.append(chatBuf.toString());
				return lastIdInBuffer;					// can't find the chatIdx, return the whole buffer
			}
			
			// found the requested message ID, go on to find the paired end tag
			s = CLOSETAG1 + reqIdx + CLOSETAG2;
			idx = chatBuf.indexOf(s, idx);
			if (idx == -1)
			{
				// shouldn't be missing end tag
				l.error("OmfChatObject: missing </chat-" + reqIdx + "> tag in chat object [" + chatObjIdS + "]");
				return 0; 
			}

			idx += s.length() + DIVCLOSE.length();				// skip this reqIdx block and the closing </DIV>
			retBuf.append(chatBuf.substring(idx).toString());	// get all the text behind the reqIdx
			return lastIdInBuffer;								// last posted chat message ID
		}
	}	// END: extractChatBlock

	
	// web client only: fill chatBuf with the latest segment
	private void fillChatBuf(boolean forced)
		throws PmpException
	{
		if (forced || this.state<ST_FILLED)
		{
			// chatBuf is only for Web chat to view, but mobile needs to fill it also
			chatBuf = new StringBuffer(4096);						// initialize buffer
			ArrayList <String> msgArrList = getChatSegment(0);		// get last/latest segment
			
			PstUserAbstractObject uObj;
			String lastDtS = null;
			String timeS = null;
			String [] dtArr = new String[2];
			Date dt;
			
			for (String msg : msgArrList) {
				if (msg == null) break;
				getMessageDateTime(msg, dtArr);	// firstDtS is complete date time string
				timeS = dtArr[1];				// just time 15:23
				if (lastDtS==null || !lastDtS.equals(dtArr[0])) {
					lastDtS = dtArr[0];
					try {
						dt = df3.parse(lastDtS);
						chatBuf.append(DATETAG + df1.format(dt) + DIVCLOSE);
					}
					catch (ParseException e) {}
				}

				uObj = getUserFromMessage(msg);
				msg = stripMessage(msg);							// remove the irrelevant info for web client, userid, date
				msg = "<span class='hist_date'>(" + timeS + ")</span>:&nbsp;" + msg;
				msg = addUserInfoToChatMessage(uObj, msg);			// add color and label, "jsmith: "
				
				// <DIV><chat-123><font ...>echeng (time)</font>:text</chat-123></DIV>
				chatBuf.append(DIVOPEN);
				chatBuf.append(msg);
				chatBuf.append(DIVCLOSE);
			}
			setState(ST_FILLED);			// I have just filled the memory chat obj now
		}
		
		// chatBuf filled either by someone or just now from OMM DB Content
		
		if (bDebug) {
			System.out.println("-- End calling fillChatBuf(" + forced + "). lastIdInBuffer=" + lastIdInBuffer);
			printChatBuf();
		}
	}
	
	// for web client only: to strip irrelevant content from chat message
	private String stripMessage(String msg) {
		// strip the irrelevant info for web client: userId, date
		// <chat-123><chat-date=2014-10-5 15:32:18 /><chat-user=12345 />text</chat-123>
		StringBuffer retB = new StringBuffer(1024);
		int idx1, idx2;
		
		// <chat-date ...
		if ((idx1 = msg.indexOf(MSG_DATETAG1)) != -1) {
			if ((idx2 = msg.indexOf(MSG_DATETAG2, idx1)) != -1) {
				retB.append(msg.substring(0, idx1));
				retB.append(msg.substring(idx2 + MSG_DATETAG2.length()));
				msg = retB.toString();			// removed <chat-date tag
			}
		}
		
		// <chat-user ...
		if ((idx1 = msg.indexOf(MSG_USERTAG1)) != -1) {
			if ((idx2 = msg.indexOf(MSG_USERTAG2, idx1)) != -1) {
				retB.setLength(0);				// make sure retB is re-initialized
				retB.append(msg.substring(0, idx1));
				retB.append(msg.substring(idx2 + MSG_USERTAG2.length()));
				msg = retB.toString();
			}
		}

		return msg;			// return <chat-123>text</chat-123>
	}
	
	
	private PstUserAbstractObject getUserFromMessage(String msg)
	{
		// extract the user object from the chat message
		PstUserAbstractObject uObj = null;
		String uidS = getMessageUserId(msg);
		try {
			uObj = (PstUserAbstractObject) uMgr.get(jwu, Integer.parseInt(uidS));
		}
		catch (PmpException e) {
			e.printStackTrace();
		}
		return uObj;
	}
	
	/**
	 * extract "<chat-user" author's userId from a chat message
	 * @param msg
	 * @return
	 */
	protected static String getMessageUserId(String msg)
	{
		String uidS = null;
		int idx1, idx2;
		if ((idx1 = msg.indexOf(MSG_USERTAG1)) != -1) {				// <chat-user tag
			if ((idx2 = msg.indexOf(MSG_USERTAG2, idx1)) != -1) {	// close tag: />
				uidS = msg.substring(idx1+MSG_USERTAG1.length(), idx2).trim();
			}
		}
		return uidS;
	}

	
	protected static int getMessageId(String msg)
	{
		// extract the message ID from the chat message
		int id = -1;
		if (StringUtil.isNullOrEmptyString(msg)) return -1;
		
		int idx1, idx2;
		if ((idx1=msg.indexOf(OPENTAG1)) != -1) {
			idx1 = idx1 + OPENTAG1.length();			// skip the tag "<chat-"
			if ((idx2=msg.indexOf(OPENTAG2, idx1)) != -1) {
				String s = msg.substring(idx1, idx2).trim();
				id = Integer.parseInt(s);
			}
		}
		return id;
	}
	
	/**
	 * extract the date/time string from "<chat-date".  It also fills the array param with date and time.
	 * @param msg
	 * @return
	 */
	private static String getMessageDateTime(String msg, String [] dtArr)
	{
		String dtS = "", timeS;
		int idx1 = msg.indexOf(MSG_DATETAG1);
		
		if (idx1 != -1) {
			int idx2 = msg.indexOf(MSG_DATETAG2, idx1);
			if (idx2 != -1) {
				// extract date
				dtS = msg.substring(idx1+MSG_DATETAG1.length(), idx2).trim();

				// strip quote or double-quote if any
				dtS = dtS.replaceAll("'", "").replaceAll("\"", "");
				
				String [] sa = dtS.split(" ");
				if (sa.length >= 2) {
					dtArr[0] = sa[0];		// only date
					timeS = sa[1];		// only time, 15:23:21
					if ((idx1 = timeS.lastIndexOf(':')) != -1) {
						timeS = timeS.substring(0, idx1);		// 15:23
						dtArr[1] = timeS;
					}
				}
				else {
					dtArr[0] = dtArr[1] = "";
				}
			}
		}
		return dtS;
	}
	
	
	/**
	 * extract the "<chat-date" date from the chat message and return the Date object.
	 * @param msg
	 * @return
	 */
	protected static String getMessageDate(String msg)
	{
		String dtS = "";
		int idx1 = msg.indexOf(MSG_DATETAG1);
		
		if (idx1 != -1) {
			int idx2 = msg.indexOf(MSG_DATETAG2, idx1);
			if (idx2 != -1) {
				// extract date
				dtS = msg.substring(idx1+MSG_DATETAG1.length(), idx2).trim();

				// strip quote or double-quote if any
				dtS = dtS.replaceAll("'", "").replaceAll("\"", "");
			}
		}
		return dtS;
	}
	
	
	/**
	 * extract the pure text of the chat message.
	 * @param msg
	 * @return	the text or empty String if not found
	 */
	protected static String getMessageText(String msg)
	{
		// <chat-123><chat-date "..."/><chat-user 12345 />... text ...</chat-123>
		String retS = "";
		int idx1, idx2;
		if ((idx1 = msg.lastIndexOf(MSG_USERTAG2)) != -1) {
			if ((idx2 = msg.indexOf(CLOSETAG1, idx1)) != -1) {
				retS = msg.substring(idx1+MSG_USERTAG2.length(), idx2);
			}
		}
		return retS;
	}

	/**
	 * get LastID from the OMM DB.
	 * @return
	 */
	public int getLastMessageID()
		throws PmpException
	{
		chat cObj = (chat) getOMMChatObject();			// get the object afresh from OMM DB
		int lastId = cObj.getIntAttribute("LastID");
		return lastId;
	}

	/**
	 * call by both web client and mobile app to insert a basic chat message into OMM DB and the cache.
	 * @param text
	 * @param dateS	user supply the timestamp of the chat message.
	 * @return	just inserted lastID for the message, or -1 if insert failed or submitted insert text is empty.
	 * @throws PmpException
	 */
	protected int insertChatMessageToDB(PstUserAbstractObject creatorObj, String text, String dateS)
		throws PmpException
	{
		if (StringUtil.isNullOrEmptyString(text)) return -1;
		
		// dateS if supplied by caller, is in df0 format
		Date dt = null;
		try {userinfo.setTimeZone(creatorObj, df0);}
		catch (Exception e ) {}
		if (StringUtil.isNullOrEmptyString(dateS)) {
			// user didn't supply date of posted text, create it NOW
			dt = new Date();
			dateS = df0.format(dt);
		}
		else {
			try {dt = df0.parse(dateS);}
			catch (ParseException e) {}
		}
		
		// compose a message: <chat-123><chat-date 2014-10-5 15:32:18 /><chat-user 12345 />text</chat-123>
		StringBuffer sBuf = new StringBuffer(1024);
		
		// prepare text for cache
		//user uObj = (user) uMgr.get(jwu, Integer.parseInt(authorIdS));
		//String modText = addUserInfoToChatMessage(uObj, text);
		
		// message id
		int messageId;
		String tag1A, tag1B;
		
		// synchronized by memory is not reliable as mobile and web are on different memory space,
		// unless I have a getSet() on DB level, I always have a window where the mobile get the
		// messageId (=123) and got swap out, web comes in get the same messageId (=123)
		synchronized (this) {
			messageId = getLastMessageID() + 1;			// inc the message ID
			tag1A = OPENTAG1 + messageId + OPENTAG2;	// <chat-123>
			tag1B = CLOSETAG1 + messageId + CLOSETAG2;	// </chat-123>

			sBuf.append(tag1A);
			sBuf.append(MSG_DATETAG1 + dateS + MSG_DATETAG2);	// <chat-date 2014-10-5 15:32:18 />		
			sBuf.append(MSG_USERTAG1 + creatorObj.getObjectId() + MSG_USERTAG2);	// <chat-user 12345 />		
			sBuf.append(text);		
			sBuf.append(tag1B);

			// the message is complete now for OMM DB
			chat cObj = ommChatObj;						// this is refreshed by getLastMessageID()
			cObj.appendAttribute("Messages", sBuf.toString());
			cObj.setAttribute("LastUpdatedDate", dt);
			// ECC: add username for mobile to use
			cObj.setAttribute("LastComment", creatorObj.getObjectName() + ": " + text);
			cObj.setAttribute("LastID", new Integer(messageId));
			cMgr.commit(cObj);
			
		}	// END synchronized
		
		// trigger event
		// always trigger submit text event for mobile
		triggerChatEvent(creatorObj, this, chatObjIdS,
				circleIdS, projIdS, otherUidS, false, PrmEvent.iEVT_CHAT_MSG, text);
		
		return messageId;
	}	// END: insertChatMessageToDB()
	
	
	protected int insertChatMessageToDB(PstUserAbstractObject creatorObj, String text)
			throws PmpException
		{
			return insertChatMessageToDB(creatorObj, text, null);
		}
	
	
	// ECC: this call is to add info to the chat text so that Web client can display it nicely
	// Mobile doesn't need this user info
	private String addUserInfoToChatMessage(PstUserAbstractObject uObj, String text)
	{
		String myUidS = String.valueOf(uObj.getObjectId());
		if (text.startsWith("@@"))
			text = "<font color='" + this.getColor(myUidS) + "'>" + text.substring(2) + "</font>";
		else
			text = "<font color='" + this.getColor(myUidS) + "'>" + uObj.getObjectName() + "</font> " + text;
		return text;
	}

	public String setColor(PstUserAbstractObject pstuser, String uidS)
	{
		return setColor(pstuser, uidS, null);
	}
	
	public String setColor(PstUserAbstractObject pstuser, String uidS, String selColorS)
	{
		// the color list is set up at Start Chat time, that the old color assignment is loaded from DB
		user u;
		String screenName;
		String colorS;
		if (selColorS == null)
		{
			colorS = (String)colorMap.get(uidS);	// the colorMap Hash might already has an old color
			if (colorS == null)
				colorS = color.getColor(uidS);		// if not, then get it from the array
		}
		else {
			colorS = selColorS;
			color.matchColor(uidS, selColorS);
		}
		colorMap.put(uidS, colorS);			// @ECC101508
		int idx;
		try
		{
			// setColor() will also remember the chatUsers
			u = (user)uMgr.get(pstuser, Integer.parseInt(uidS));
			screenName = u.getObjectName();
			if ((idx = chatUsers.indexOf(screenName)) == -1)
			{
				// not yet on the list
				if (chatUsers.length() > 0)
					chatUsers += "; ";
				chatUsers += "<font color='" + colorS + "'>" + screenName + "</font>";
			}
			else if (selColorS != null)
			{
				// need to replace the color='#223344'>echeng
				chatUsers = chatUsers.substring(0, idx-9) + colorS + chatUsers.substring(idx-2);
			}
		}
		catch (PmpException e) {l.info("OmfChatObject.setColor() failed to get user [" + uidS + "]");}

		return colorS;
	}	// END: setColor()
	
	// web app only:
	// append a <Date> tag of the current date into the chat buffer
	public void setDate(PstUserAbstractObject pstuser, Date startDt)
	{
		try {
			userinfo.setTimeZone(pstuser, df1);
			userinfo.setTimeZone(pstuser, df2);
		}
		catch (PmpException e) {}

		String stDateS = "";
		if (startDt != null) stDateS = df1.format(startDt);
		
		Date today = new Date();
		String todayS = df1.format(today);
		String dtS = DATETAG + todayS + DIVCLOSE;
		if (chatBuf.indexOf(dtS)!=-1 || stDateS.equals(todayS))
		{
			// already a date tag, only insert a time and a partition
			dtS = "<br><hr>";
		}

		dtS += TIMETAG + df2.format(today) + SPANCLOSE + "<br>";
		chatBuf.append(dtS);
	}


	protected static int [] getMakeMobile(PstUserAbstractObject pstuser, String uidS1, String uidS2,
			String cirIdS, String pjIdS, String chatIdS, boolean bNoMake)
		throws PmpException
	{
		return getMake(pstuser, uidS1, uidS2, cirIdS, pjIdS, chatIdS, bNoMake, true);
	}
	
	protected static int [] getMakeWeb(PstUserAbstractObject pstuser, String uidS1, String uidS2,
			String cirIdS, String pjIdS, String chatIdS, boolean bNoMake)
		throws PmpException
	{
		return getMake(pstuser, uidS1, uidS2, cirIdS, pjIdS, chatIdS, bNoMake, false);
	}
	
	/**
	 * Important call to locate and/or make the OMM chat object.
	 * try to locate the chat from OMM DB.  If not found, create it if the boolean of bNoMake is false.
	 * To make the OMM DB object, it in turns calls createOMMChatInternal().
	 * @param pstuser
	 * @param uidS1			for Any chat between 2 people
	 * @param uidS2			for Any chat between 2 people
	 * @param cirIdS		circle ID if opening a circle chat.
	 * @param pjIdS			project ID if this is a project chat.
	 * @param chatIdS		the chat ID to be retrieved.  It can be null.
	 * @param bNoMake		If true, then if I can't find this chat in memory or OMM DB, then I will simple return.
	 * @return
	 * @throws PmpException
	 */
	synchronized private static int [] getMake(PstUserAbstractObject pstuser, String uidS1, String uidS2,
			String cirIdS, String pjIdS, String chatIdS, boolean bNoMake, boolean isMobileApp)
		throws PmpException
	{
		// if the chat exist, I definitely will get it from the DB since this call is sync.
		// If I don't find it in DB, guarantee I am the first guy who got here.
		// But even if I found it in DB, it might already be going in memory now.
		// I will therefore call getChatObject() with the chat ID from DB, and see if the object
		// is already filled.  If so, just return the chat ID.
		int [] ids;
		if (chatIdS == null) {
			String expr = "";
			if (cirIdS==null && pjIdS==null) {
				// individual chat
				if (uidS1==null || uidS2==null || uidS1.length()<=0 || uidS2.length()<=0)
				{
					l.error("OmfChatObject.getMake() detected bad user id [" + uidS1 + ", " + uidS2 + "]");
					return null;
				}
				expr = "Attendee='" + uidS1 + "' && Attendee='" + uidS2 + "'";
			}
			else if (cirIdS == null) {
				// PRM: project chat
				expr = "ProjectID='" + pjIdS + "'";	// chat with project
				uidS1 = pjIdS;						// put projId here to be used below
			}
			else {
				// MeetWE: chat with Circle (town); PRM: chat with Company (?? too much ??)
				expr = "TownID='" + cirIdS + "'";	// chat with circle
				uidS1 = cirIdS;						// put circleId here to be used below
			}
			ids = cMgr.findId(pstuser, expr);
			if (bDebug) System.out.println("-- " + ids.length + " matching found in OMM. (" + expr + ")");
		}
		else
		{
			// caller has the specific chat ID to get
			// ECC: potential problem - this id might be removed but another chat might have been created
			// for these attendees already.  The code below would not detect it and would create another chat.
			ids = new int[1];
			ids[0] = Integer.parseInt(chatIdS);
		}
		
		PstAbstractObject cObj = null;		// the DB chat object
		OmfChatObject chatObj  = null;
		if (ids.length > 1)
			return ids;						// *** more than one DB obj found, need to return to ask for user's choice
		
		if (ids.length <= 0)
		{
			// no chat db found
			if (bNoMake)
				return null;

			cObj = createOMMChatInternal(pstuser, uidS1, uidS2, pjIdS);
			ids = new int[1];
			ids[0] = cObj.getObjectId();
			
			// create and put the chat buffer in a OmfChatObject in hash
			chatObj = OmfChat.getChatObject(String.valueOf(ids[0]));
			chatObj.setState(ST_CREATED);		// just called createChatDBobj to create the chat obj
			chatObj.ommChatObj = (chat) cObj;	// just created in OMM

			l.info("OmfChatObject.getMake()-1 created a new OMM chat object in DB [" + ids[0]
			       + "] for (" + uidS1 + ", " + uidS2 + ") - projId=" + pjIdS);
		}
		else if (ids.length == 1)
		{
			// either found chatId in DB or Id is given by caller
			// check to see if chat is going on in memory.  If not, fill it up with the DB contents
			chatObj = OmfChat.getChatObject(String.valueOf(ids[0]));	// find or put in Hash
			if (!chatObj.isFresh()) {
				if (bDebug) System.out.println("-- getMake() found chatObj [" + ids[0] + "] in cache.");
				return ids;					// *** chat is going on already, do nothing more and return
			}
			
			try {cObj = chatObj.getOMMChatObject();}		// cMgr.get(pstuser, ids[0]);}
			catch (PmpException e)
			{
				// the chat is removed from the DB, simply start a new chat
				// ECC2: I should try to locate the DB chat obj by uidS1/uidS2 or cirIdS
				if (bNoMake)
					return null;
				l.info("The chat [" + ids[0] + "] is not found in DB.  Create new chat.");
				cObj = createOMMChatInternal(pstuser, uidS1, uidS2, pjIdS);
				ids = new int[1];
				ids[0] = cObj.getObjectId();
				
				// create and put the chat in a OmfChatObject in hash
				chatObj = OmfChat.getChatObject(String.valueOf(ids[0]));
				chatObj.setState(ST_CREATED);		// just called createChatDBobj to create the chat obj
				chatObj.ommChatObj = (chat) cObj;	// just created in OMM

				l.info("OmfChatObject.getMake()-2 created a new OMM chat object in DB [" + ids[0]
				       + "] for (" + uidS1 + ", " + uidS2 + ")");
			}
		}
	
		
		// store circle name if it is a circle chat
		if (cirIdS == null) {
			cirIdS = (String)cObj.getAttribute("TownID")[0];
		}
		
		if (pjIdS == null) {
			pjIdS = chatObj.projIdS = cObj.getStringAttribute("ProjectID");
		}

		if (cirIdS != null)
		{
			chatObj.circleName = (String) tnMgr.get(pstuser, Integer.parseInt(cirIdS)).getAttribute("Name")[0];
			chatObj.circleIdS = cirIdS;
		}
		else if (pjIdS != null) {
System.out.println("*** Call getMake() for a Project chat, pid [" + pjIdS + "]");			
			chatObj.projIdS = pjIdS;
		}
		else {
			chatObj.otherUidS = uidS2;				// remember the 1-on-1 chat user
		}
		
		// color: not used by Mobile App
		String s = (String)cObj.getAttribute("Color")[0];			// id;id; ... e.g. 12345;23456 (in order of 0, 1, ...)
		if (s != null)
		{
			// there is old color assignment, use them.  Otherwise caller will setColor.
			String [] sa1;
			String [] sa2;
			String colorS;
			sa1 = s.split(";");
			for (int i=0; i<sa1.length; i++)
			{
//System.out.println("!!! Got color string: " + sa1[i]);				
				sa2 = sa1[i].split(":");					// might be userId (old) only or userId:#color
				if (sa2.length > 1) colorS = sa2[1];
				else colorS = null;
				chatObj.setColor(pstuser, sa2[0], colorS);
//System.out.println("    setColor: " + sa2[0] + ":" + colorS);				
			}
		}
		// name
		chatObj.setName((String)cObj.getAttribute("Name")[0]);
		
		// chatBuf is only used by mobile
		// there is one DB chat object identified, and this is a Start Chat,
		// so fill the memory obj with OMM DB buffer.  Do this after setColor().
		// this will call getChatSegment(0) and grab the latest chatMessageID.
		if (!isMobileApp) {
			if (bDebug) System.out.println("-- getMake() filling internal chatBuf.  pid=" + pjIdS);
			chatObj.fillChatBuf(false);
		}
			
		return ids;
	}	// END: getMake()
	
	/**
	 * create a chat in the OMM database (called by mobile App)
	 * @param pstuser	Creator of this chat.
	 * @param chatName	The name of this chat.
	 * @param projIdS	For Any chats, this will be null.
	 * @param uidSArr	Initial attendees participating in this chat.
	 * @param iconFS	Icon stream of this chat.
	 * @return			The ID of the new chat
	 * @throws PmpException
	 */
	protected static String createChat(PstUserAbstractObject pstuser, String chatName,
			String projIdS, String [] uidSArr, InputStream iconFS, String ext)
		throws PmpException
	{
		return createOMMChat(pstuser, chatName, projIdS, null, uidSArr, iconFS, ext).getObjectName();
	}

	
	/**
	 * this is called by Web app in this class, mainly to construct the default chat name.
	 * Mobile will call createChat() directly by passing chat name
	 * @param pstuser
	 * @param uidS1
	 * @param uidS2
	 * @param pjIdS
	 * @return
	 * @throws PmpException
	 */
	private static PstAbstractObject createOMMChatInternal(PstUserAbstractObject pstuser,
			String uidS1, String uidS2, String pjIdS)
		throws PmpException
	{
		PstAbstractObject o;
		String nm = "";
		String [] uidSArr = null;
		String townIdS = null;			// for circle chat
		
		if (pjIdS != null) {
			o = pjMgr.get(pstuser, Integer.parseInt(pjIdS));
			nm = ((project)o).getDisplayName();					// project name is project chat name
		}
		else if (uidS2 != null)
		{
			uidSArr = new String[2];
			uidSArr[0] = uidS1;
			uidSArr[1] = uidS2;
			
			// ECC: shouldn't we use: "John Smith / Lucy Bear" ?
			nm = ((user)uMgr.get(pstuser, Integer.parseInt(uidS2))).getFullName();
		}
		else
		{
			// circle chat: we had put townIdS into uidS1
			try {
				o = tnMgr.get(pstuser, Integer.parseInt(uidS1));
				nm = (String)o.getAttribute("Name")[0];		// town name
				nm = "@Chat room of " + nm;					// the @ sign indicate it's a default name
				townIdS = uidS1;
			}
			catch (PmpException e) {
				// failed to find the town object, cannot create chat room for it
				l.error("Error creating circle chat because town [" + uidS1 + "] is not found.");
				return null;
			}
		}

		return createOMMChat(pstuser, nm, pjIdS, townIdS, uidSArr, null, null);
	}
	
	//
	// called by createChat() from Mobile and by createOMMChatInternal() in this class
	//
	private static PstAbstractObject createOMMChat(PstUserAbstractObject pstuser, String chatName,
			String projIdS, String townIdS, String [] uidSArr, InputStream iconFS, String ext)
		throws PmpException
	{
		chat cObj = (chat) cMgr.create(pstuser);
		Date now = new Date();
		
		cObj.setAttribute("Name", chatName);
		cObj.setAttribute("Attendee", uidSArr);
		cObj.setAttribute("Creator", String.valueOf(pstuser.getObjectId()));
		cObj.setAttribute("ProjectID", projIdS);			// for Any chat this would be null
		cObj.setAttribute("TownID", townIdS);

		if (uidSArr!=null && uidSArr.length==2) {
			cObj.setAttribute("Color", uidSArr[0] + ";" + uidSArr[1]);	// Color is used by Web chat only
		}
		
		setChatIcon(cObj, iconFS, ext);
		
		cObj.setAttribute("CreatedDate", now);
		cObj.setAttribute("LastUpdatedDate", now);
		cMgr.commit(cObj);
		
		return cObj;
	}
	
 	
	protected static void setChatIcon(chat cObj, InputStream iconFS, String ext)
		throws PmpException
	{
		if (iconFS != null) {
			// put the file in the ICON_FILE folder and save the path
			//String s = new String(IOUtils.toByteArray(iconFS), "utf-8");
			//cObj.setAttribute("Picture", s.getBytes("utf-8"));

			// identify icon image type (for finding file extension)
			// icon file name with extension
			String fnameOnly = cObj.getObjectName() + "." + ext.toLowerCase();		// 12345.gif
			String fname = Util.getPropKey("pst", "ICON_FILE_PATH");
			if (fname == null) {throw new PmpException("ICON_FILE_PATH not defined in pst.properties file.");}
			fname += File.separator + fnameOnly;		// C:/Tomcat/.../PRM/file/icon/12345.gif

			// now I have the complete filename with extension
			// create and save image to the icon file
			File targetFile = new File(fname);			// might be any type: jpg, gif, png, etc.
			try {
				FileUtils.copyInputStreamToFile(iconFS, targetFile);
			} catch (IOException e1) {
				e1.printStackTrace();
				throw new PmpException("Error copying chat icon image file.");
			}

			/*
					OutputStream outputStream = new FileOutputStream(new File(fname));
					int read = 0;
					byte[] bytes = new byte[1024];
					while ((read = iconFS.read(bytes)) != -1) {
						outputStream.write(bytes, 0, read);
					}
					outputStream.close();
			 */
			cObj.setAttribute("PictureFile", fnameOnly);
			cMgr.commit(cObj);
			l.info("Saved chat icon file [" + fname + "] for chat [" + cObj.getObjectName() + "]");
		}
	}
	
	private String getUserShortList(PstUserAbstractObject pstuser)
	{
		// return "edwardc" or "edwardc and joinh" or "edwardc, joinh and others"
		String idS, name, retS="";
		int ct = 0;

		for (Enumeration<String> en = colorMap.keys(); en.hasMoreElements() ;)
		{
			idS = (String)en.nextElement();
			if (++ct >= 3) break;
			try {name = uMgr.get(pstuser, Integer.parseInt(idS)).getObjectName();}
			catch (PmpException e) {continue;}
			if (retS.length() > 0) retS += ", ";	// I am going to replace "," with " and"
			retS += name;
		}

		if (ct == 2)
			retS = retS.replace(",", " and");
		else if (ct > 2)
			retS += " and others";
		return retS;
	}
	
	public int [] getUserIds()
	{
		// return Attendees in int array
		int ct = 0;
		int [] ids = new int[colorMap.size()];
		for (Enumeration<String> en = colorMap.keys(); en.hasMoreElements() ;)
		{
			ids[ct++] = Integer.parseInt((String)en.nextElement());
		}
		return ids;
	}
	
	// save the chat object to DB
	public void save(PstUserAbstractObject pstuser)
		throws PmpException
	{
		save(pstuser, true);
	}
	
	/**
	 * save the chat object to OMM database.  Note that this all doesn't take care of the
	 * chat messages; they are saved one by one by calling insertChatMessageToDB()
	 * 
	 * @param pstuser
	 * @param bUseColorMap
	 * @throws PmpException
	 */
	public void save(PstUserAbstractObject pstuser, boolean bUseColorMap)
		throws PmpException
	{
		synchronized (this)
		{
			// save Attendee and Color
			String idS, colorS = "";
			PstAbstractObject cObj = getOMMChatObject();	//cMgr.get(pstuser, chatObjIdS);
			
			// the concept of color map is not used in Mobile app
			if (bUseColorMap) {
				cObj.setAttribute("Attendee", null);		// remove all
				//for (int i=0; i<color.length(); i++)
				for (Enumeration<String> en = colorMap.keys(); en.hasMoreElements() ;)
				{
					idS = (String)en.nextElement();
					cObj.appendAttribute("Attendee", idS);
					if (colorS.length() > 0) colorS += ";";
					colorS += idS + ":" + colorMap.get(idS);		// @ECC101508
				}
				if (colorS.length() <= 0) colorS = null;
				cObj.setAttribute("Color", colorS);
			}
			
			//cObj.setAttribute("Name", name);		// Name is saved by calling saveName()
			cObj.setAttribute("LastUpdatedDate", new Date());
			
			cMgr.commit(cObj);
			
			this.lastFlush = new Date();
			this.state = ST_ACTIVE;				// not dirty
			l.info("Saved chat object [" + chatObjIdS + "] name: " + name);
		}
	}	// END: save()
	
	public void saveName(PstUserAbstractObject pstuser)
		throws PmpException
	{
		synchronized (this)
		{
			PstAbstractObject cObj = getOMMChatObject();	//cMgr.get(pstuser, chatObjIdS);
			cObj.setAttribute("Name", name);
			cMgr.commit(cObj);
			l.info("Saved chat name [" + name + "] for [" + chatObjIdS + "]");
		}
	}
	
	// create a meeting object for this chat
	// and remove the DB chat object
	public String saveToMeeting(PstUserAbstractObject pstuser)
		throws PmpException
	{
		synchronized (this)
		{
			// authorization check: only allow Chat creator to save chat to meeting
			String myUidS = String.valueOf(pstuser.getObjectId());
			PstAbstractObject cObj = cMgr.get(pstuser, chatObjIdS);
			String chatOwnerIdS = cObj.getStringAttribute("Creator");
			
			if (chatOwnerIdS!=null && !chatOwnerIdS.equals(myUidS)) {
				// not authorized to save chat to meeting
				return null;
			}
			
			// create the meeting object
			meetingManager mMgr = meetingManager.getInstance();
			PstAbstractObject mObj = mMgr.create(pstuser);
			
			Date start = new Date(new Date().getTime() - MIN_15 - userinfo.getServerUTCdiff());
			Date end = new Date(start.getTime() + HOUR_1);
			
			String s;
			// set attributes
			// Owner, Recorder, StartDate, ExpireDate, EffectiveDate, CompleteDate, Location, Status,
			// Subject, TownID, Type, Attendee, Content
			mObj.setAttribute("Owner", myUidS);
			
			// Assume all attendees are MandatoryLogonPresent
			String attendee, resp;
			s = meeting.ATT_MANDATORY + meeting.ATT_ACCEPT;

			for (Enumeration<String> en = colorMap.keys(); en.hasMoreElements() ;)
			{
				//if (color.getId(i).equals(s)) continue;
				resp = (String)en.nextElement();
				attendee = resp + "::" + s;
				mObj.appendAttribute("Attendee", attendee);
				mObj.appendAttribute("Responsible", resp);
			}
			//mObj.setAttribute("Recorder", s);
			mObj.setAttribute("StartDate", start);
			mObj.setAttribute("ExpireDate", end);
			//mObj.setAttribute("EffectiveDate", back1min);
			//mObj.setAttribute("CompleteDate", now);
			mObj.setAttribute("Location", LOCATION);
			mObj.setAttribute("Status", meeting.NEW);
			mObj.setAttribute("Type", meeting.PRIVATE);			// default to private
			
			// Subject from chat name
			s = getName();
			if (s.charAt(0) == '@')
			{
				s = s.substring(1);	// default name is used
				s = s.replaceFirst("with", "of");
			}
			else
				s = getName() + " - chat meeting of " + getUserShortList(pstuser);
			mObj.setAttribute("Subject", s);				
			
			// Content
			try {mObj.setAttribute("Note", chatBuf.toString().getBytes("utf-8"));}
			catch (UnsupportedEncodingException e) {throw new PmpException(e.getMessage());}
			
			// save the meeting object
			mMgr.commit(mObj);
			
			// now delete the DB chat obj and set the mem chatObj state to reflect the change
			l.info("saveToMeeting() deleting chat from DB [" + chatObjIdS + "]");
			cMgr.delete(cObj);
			this.setState(ST_MOVED);
			this.midS = String.valueOf(mObj.getObjectId());
			
			return midS;
		}
	}	// END: saveToMeeting()
	
	public static void removeChat(PstUserAbstractObject pstuser, String chatIdS)
		throws PmpException
	{
		PstAbstractObject cObj = cMgr.get(pstuser, chatIdS);
		cMgr.delete(cObj);
		l.info("OmfChatObject.removeChat() removed chat [" + chatIdS + "] from DB");
	}
	
	// to support debugging of web client
	public void printChatBuf() {
		// print content of chatBuf
		System.out.println(">> dumping chatBuf for chat [" + chatObjIdS + "]");
		if (chatBuf == null) {
			System.out.println("-- null chatBuf.");
			return;
		}
		System.out.println("   -- lastIdInBuffer = " + lastIdInBuffer);
		if (chatBuf.length() <= 0) System.out.println("  empty buffer.");
		String s = chatBuf.toString();
		s = s.replaceAll("<DIV>", "\n<DIV>");
		System.out.println(s);
		System.out.println("\n<< end dumping chatBuf.");
	}
	
	protected static void triggerChatEvent(PstUserAbstractObject pstuser, OmfChatObject chatObj,
			String chatObjIdS, String circleIdS, String projIdS, String otherUidS, boolean bIncSelf,
			int iEventID, String chatText)
		throws PmpException
	{
		// generate an event to the user (put chatId into MeetingId)
		if (bDebug) System.out.println("triggerChatEvent(): eventID=" + iEventID
				+ ", chatId=" + chatObjIdS + ", projId=" +projIdS + ", text=" + chatText);
		user u;
		String s;
		int [] uids;
		int myUid = pstuser.getObjectId();
		String myUidS = String.valueOf(myUid);

		if (circleIdS == null) circleIdS = chatObj.getCircleId();
		event evt = PrmEvent.create(pstuser, String.valueOf(iEventID), chatObjIdS, circleIdS, null);
		if (evt == null)
			return;
		
		if (circleIdS!=null && iEventID==PrmEvent.iEVT_CHAT_START) {
			PrmEvent.setMtgCircleToVar(pstuser, evt, "var1");	// put circle name in $var1
		}

		if (!chatObj.isCircleChat())
		{
			String chatName = "";
			if (projIdS != null) {
				// project chat: event to team members
				// put project name in evt $var1 for StartChat
				// put text in evt $var1 for Submit Chat text
				project pj = (project)pjMgr.get(pstuser, Integer.parseInt(projIdS));
				s = "Creator='" + myUidS + "'"
						+ " && MeetingID='" + chatObjIdS + "'"
						+ " && Type='" + iEventID + "'";
				PrmEvent.checkCleanMaxEventOnStack(pstuser, s, 0, null);	// remove all: only one start/msg chat event

				if (iEventID == PrmEvent.iEVT_CHAT_START) {
					chatName = pj.getDisplayName();
					PrmEvent.setValueToVar(evt, "var1", chatName);
					
					// trigger event to project team
					//u = (user)uMgr.get(pstuser, myUid);		// need to refresh evt stack
					//PrmEvent.stackEvent(u, evt);			// include myself
				}
				else if (iEventID == PrmEvent.iEVT_CHAT_MSG) {
					// need this event for mobile
					PrmEvent.setValueToVar(evt, "var1", chatText);
					String chatIdS = evt.getStringAttribute("MeetingID");	// chat Id
					int [] ids = Util2.toIntArray(pj.getAttribute("TeamMembers"));
					/*if (!bIncSelf) {
						for (int i=0; i<ids.length; i++) {
							if (ids[i] == myUid) {
								ids[i] = 0;			// found: remove myself because I don't want to send to myself
								break;
							}
						}
					}*/
					//PrmEvent.pushChatMobileEvent(ids, evt.getObjectName(), chatIdS);
				}
				
				// trigger event (incl Apple mobile) to project team
				PrmEvent.addEventToProjectTeam(pstuser, pj, evt);

			}	// END if: Project chat
			
			
			// Any chat
			else {
				// Any chat: multiple attendee
				chat ommChat = chatObj.getOMMChatObject();
				//chatName = ommChat.getStringAttribute("Name");
				chatName = ommChat.getName(myUid);
				Object [] attendeeArr = ommChat.getAttribute("Attendee");
				uids = Util2.toIntArray(attendeeArr);
				/* ECC: include self for now - testing
				if (!bIncSelf) {
					for (int i=0; i<uids.length; i++) {
						if (uids[i] == myUid) {
							uids[i] = 0;			// found: remove myself because I don't want to send to myself
							break;
						}
					}
				}
				*/

				if (iEventID == PrmEvent.iEVT_CHAT_START) {
					s = "Creator='" + myUidS + "'"
						+ " && MeetingID='" + chatObjIdS + "'"
						+ " && Type='" + iEventID + "'";
	    			PrmEvent.checkCleanMaxEventOnStack(pstuser, s, 0, null);	// remove the old events
					PrmEvent.setValueToVar(evt, "var1", chatName);
					PrmEvent.stackEvent(pstuser, uids, evt);
				}
				else if (iEventID == PrmEvent.iEVT_CHAT_MSG) {
					PrmEvent.setValueToVar(evt, "var1", chatText);
					String chatIdS = evt.getStringAttribute("MeetingID");	// chat Id
					PrmEvent.stackEvent(pstuser, uids, evt);
					//PrmEvent.pushChatMobileEvent(uids, evt.getObjectName(), chatIdS);
				}
			}	// END else: Any chat

		}
		
		// Circle chat
		else
		{
			// trigger event to the whole circle
			s = "Creator='" + myUidS + "'"
				+ " && TownID='" + circleIdS + "'"						// only one circle chat evt allowed
				+ " && Type='" + PrmEvent.EVT_CHAT_START + "'";
			PrmEvent.checkCleanMaxEventOnStack(pstuser, s, 0, null);	// remove the old events
			PrmEvent.addEventToCircle(pstuser, evt);
			u = (user)uMgr.get(pstuser, myUid);		// need to refresh evt stack
			PrmEvent.stackEvent(u, evt);			// include myself
		}
	}

}
