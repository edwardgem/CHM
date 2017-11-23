////////////////////////////////////////////////////
//	Copyright (c) 20067, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	OmfChatAjax.java
//	Author:	ECC
//	Date:	11/14/07
//	Description:
//		Implementation of OmfChatAjax class.  Entry point for Web chat.  The front-end is in ep_chat.jsp and chat.js
//		There are two types of chats, namely Project Chats and Any Chats.  Project chat is a chat room associated to each
//		project.  Any chats are chats created by users between 2 or more users.
//
//	Modification:
//		@ECC141007	Change the chat message format and store them separately in Messages attribute.
//
////////////////////////////////////////////////////////////////////

package mod.mfchat;

import java.io.IOException;
import java.util.Date;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import oct.codegen.event;
import oct.codegen.projectManager;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstUserAbstractObject;

import org.apache.log4j.Logger;

import util.PrmEvent;
import util.PrmLog;
import util.PrmMtgConstants;
import util.StringUtil;
import util.Util2;

/**
 * @author edwardc
 *
 */
public class OmfChatAjax extends HttpServlet
{
	private static final long serialVersionUID = 1003;
	private static Logger l;
	
	private static final int OP_START_CHAT		= 1;
	private static final int OP_CHECK_CHAT		= 2;
	private static final int OP_JOIN_CHAT		= 3;
	private static final int OP_SUBMIT_CHAT		= 4;
	private static final int OP_CLOSE_CHAT		= 5;
	private static final int OP_SAVE_CHAT_MTG	= 6;
	private static final int OP_REMOVE_CHAT		= 7;
	private static final int OP_RENAME_CHAT		= 8;
	
	private static final String OPS_START		= "start";
	private static final String OPS_CHECK		= "check";
	private static final String OPS_JOIN		= "join";
	private static final String OPS_SUBMIT		= "submit";
	private static final String OPS_CLOSE		= "close";
	private static final String OPS_SAVE_MTG	= "save_mtg";
	private static final String OPS_REMOVE		= "remove";
	private static final String OPS_RENAME		= "rename";
	
	public static final String CHATOBJ_ID_TAG		= "ChatObjId";
	public static final String CHAT_IDX_TAG			= "LastChatId";
	public static final String CHAT_BLOCK_TAG		= "ChatBlocks";
	public static final String CHAT_USER_TAG		= "ChatUsers";
	public static final String CHAT_COLOR_TAG		= "MyChatLabel";
	public static final String CHAT_MID_TAG			= "SavedMtgId";
	public static final String CHAT_CIRCLE_NAME		= "CircleName";
	public static final String CHAT_NAME			= "ChatName";
	
	private static userManager uMgr;
	private static projectManager pjMgr;
	private static boolean bDebug = false;			// turn on debuf in chat.js
	
	static {
		l = PrmLog.getLog();
		try {
			uMgr = userManager.getInstance();
			pjMgr = projectManager.getInstance();
		} catch (PmpException e) {
			uMgr = null; pjMgr = null;
		}
	}

	public void doPost(HttpServletRequest request, HttpServletResponse response) 
	throws ServletException, IOException
	{
		request.setCharacterEncoding("utf-8");
		response.setCharacterEncoding("utf-8");

		// post note and send turkey
		// Get the current session and pstuser
		PstUserAbstractObject pstuser = null;
		HttpSession httpSession = request.getSession(false);
		// Verify that this is indeed the user
		// Check valid user
		if (httpSession != null)
			pstuser = (PstUserAbstractObject)httpSession.getAttribute(PrmMtgConstants.PSTUSER);
		if (pstuser == null)
		{
			// Session Timeout (and users clicks Live) or Invalid Meeting ID
			return;
		}
		
		// ECC debug option: set in chat.js
		bDebug = request.getParameter("debug")!=null;
		OmfEventAjax.setDebug(bDebug);
		OmfChatObject.setDebug(bDebug);
		
		String s, temp="";
		int idx;
		int recvChatId = 0;
		int myUid = pstuser.getObjectId();
		String myUidS = String.valueOf(myUid);
		
		String opS			= request.getParameter("op");
		String chatObjIdS	= request.getParameter("chatObjId");	// chat session id	
		String otherUidS	= request.getParameter("chatWith");		// uid, townId (circle) or 0 (friend)
		if (otherUidS!=null && (idx = otherUidS.indexOf('-'))!=-1) {
			temp = otherUidS;
			otherUidS = otherUidS.substring(0, idx);				// uid-evId e.g. 12345-33333
		}
		
		
		// utf-8
		String text			= request.getParameter("text");

		String circleIdS	= request.getParameter("circleId");		// if this is chatting with circle
		String projIdS		= request.getParameter("projId");		// project id for chat with project
		String colorS		= request.getParameter("color");
		if (circleIdS!=null && circleIdS.length()<=0)
			circleIdS = null;
		s = request.getParameter("lastChatId");
		if (s != null)
			recvChatId = Integer.parseInt(s);
		
		
		if (bDebug) {
			if (bDebug) System.out.println("\n>>>> ----------------------------------- "+ myUidS);
			System.out.println(">>>>> OmfChatAjax doPost() from Web");
			System.out.println("   opS        = " + opS);
			System.out.println("   chatObjIdS = " + chatObjIdS);
			System.out.println("   otherUidS  = " + otherUidS + ", " + temp);
			System.out.println("   text       = " + text);
			System.out.println("   circleIdS  = " + circleIdS);
			System.out.println("   projIdS    = " + projIdS);
			System.out.println("   colorS     = " + colorS);
			System.out.println("   lastChatId = " + recvChatId);
			System.out.println("-----");
		}
		
		int iOpType;		// handle different chat requests
		if (opS.equals(OPS_START))
			iOpType = OP_START_CHAT;
		else if (opS.equals(OPS_CHECK))
			iOpType = OP_CHECK_CHAT;
		else if (opS.equals(OPS_JOIN))
			iOpType = OP_JOIN_CHAT;
		else if (opS.equals(OPS_SUBMIT))
			iOpType = OP_SUBMIT_CHAT;
		else if (opS.equals(OPS_CLOSE))
			iOpType = OP_CLOSE_CHAT;
		else if (opS.equals(OPS_SAVE_MTG))
			iOpType = OP_SAVE_CHAT_MTG;
		else if (opS.equals(OPS_REMOVE))
			iOpType = OP_REMOVE_CHAT;
		else if (opS.equals(OPS_RENAME))
			iOpType = OP_RENAME_CHAT;
		else
			iOpType = 0;
			
		int lastChatId = 0;
		StringBuffer chatBlks = new StringBuffer(1024);		// only used by Web
		OmfChatObject chatObj;
		String chatUsers;
		event evt;
		int [] ids = null;
		int [] uids;
		int [] uids1;
		
		try
		{
		
			switch (iOpType)
			{
				///////////////////////////////////////////////////////
				// 1.  start chat
				case OP_START_CHAT:
					// System.out.println("*** Start Chat ("+ recvChatId + ")");					
					// attempt to retrieve chat object from db by looking up Creator and Attendee
					// in the case of responding to a chat request, the call already has a chatObjIdS>0
					// will give the option to create a chat except for 1-on-1 chat.
					
					// check to see if the chat is already in memory
					// upload or create chat buffer in memory <-- ECC: changed, obsolete, now use DB to keep/synchronize
					l.info("---- Start a chat (" + chatObjIdS + ") [" + myUidS + ", " + otherUidS + "]; pid=" + projIdS);
					if (chatObjIdS!=null)
					{
						if (Integer.parseInt(chatObjIdS) <= 0)
							chatObjIdS = null;			// need to search for chat obj in DB
					}

					// if necessary, would create an OMM chat object and use its object ID
					// getMake() also makes sure a chatObj is allocated
					// ** Important call
					System.out.println("call getMakeWeb()");
					try {ids = OmfChatObject.getMakeWeb(pstuser, myUidS, otherUidS, circleIdS, projIdS, chatObjIdS, false);}
					catch (PmpException e) {e.printStackTrace();}
					System.out.println("done getMakeWeb()");
					if (bDebug) System.out.println("-- no. of chats found = " + ids.length);
					if (ids == null)
					{
						// error condition
						l.error("Internal Error: START CHAT couldn't get or make a chat object.");
						createXml("-1", 0, null, null, null, null, null, null, null, response);
						break;
					}
					if (ids.length == 1)
					{
						// only one chat OMM DB obj is found or just made
						// I can truly start chatting on this chat object.
						chatObjIdS = String.valueOf(ids[0]);	// the above passed in Id might be bad (not found in DB)
						l.info("   located/created single chatId = " + chatObjIdS);
						
						// will go on below >>>
					}
					else
					{
						// there are more than one chat sessions between these two users in DB
						// go back to client and ask which one he wants to start
						// ECC: we should give user the option to create a new one; he may not want to open any old ones
						l.info("OmfChatAjax:doPost() Start Chat.  More than one chats found.");
						StringBuffer chatBuf = new StringBuffer();
						OmfEventAjax.constructChatList(pstuser, null, null, null,
								OmfEventAjax.OP_FORCE_ALL, chatBuf, ids);	// construct XML for chat list
						createXmlChatList(chatBuf.toString(), response);
						// need to return Xml
						return;
					}
					
					//
					// IF we got here that means only one chat object is located (or made)
					// I can start chatting
					// return the chatBuf to the user
					//

					// retrieve the chat object from the hash (ECC? do I still need hash object?)
					chatObj = OmfChat.getChatObject(chatObjIdS);		// this will get the hash obj back
					boolean bIsJustCreated = chatObj.isJustCreated();
					boolean bIsFresh = chatObj.isFresh();				// just created or just filled from DB (not in memory)
					if (bDebug) {
						System.out.println("-- isJustCreated=" + bIsJustCreated
								+ ", isFresh=" + bIsFresh + ", isMoved=" + chatObj.isMoved());
						chatObj.printChatBuf();
					}
					
					Date startDt = null;
					if (bIsFresh) {
						chatObj.setState(OmfChatObject.ST_ACTIVE);	// I am the first guy: now it is active
					}
					else if (chatObj.isMoved())
					{
						// chat --> meeting
						// another user just moved this chat to meeting, return a message to user
						createXml(chatObjIdS, lastChatId, null, null, null, null,
								chatObj.getMeetingId(), null, null, response);
						break;
					}

					// set color for this and other users; this might already be set from getMake()
					// the order of the following two setColor() calls are important
					// for a just created chat, the first guy will get color0 and 2nd guy color1
					String myLabel = chatObj.setColor(pstuser, myUidS, colorS);
					myLabel = "<font color='" + myLabel + "'>" + pstuser.getObjectName() + "</font>";
					if (otherUidS!=null && otherUidS.length()>0)
						chatObj.setColor(pstuser, otherUidS, null);	// otherUidS is null for circle chat

					// get the list of users on chat
					chatUsers = chatObj.getUsers();
					
					// insert a <DIV id='date'> tag for today for this chat session if it is not there
					if (bIsFresh) {
						// put today's date in the chatBuf as a starting point for today
						chatObj.setDate(pstuser, startDt);
					}
					
					// in case of circle chat, extract circle name
					String cirName = chatObj.getCircleName();
					
					// extract the latest chat blocks from history
					if (chatObj.length() > 0) {
						// caller passes the lastChatId (recvChatId) or 0
						// should control to extract at most n number of chat messages at once
						lastChatId = chatObj.extractChatBlock(recvChatId, chatBlks);	// return chat block excluding recvChatId
					}
					
					chatObj.save(pstuser, true);		// save color map

					// return ALL chat blocks at once to caller
					createXml(chatObjIdS, lastChatId, chatBlks.toString(), null, chatUsers,
							myLabel, null, cirName, chatObj.getName(), response);

					// if I am the initiator this time (just brought in or created from DB), trigger an event
					// No! Don't trigger now unless i just created this chat; trigger it when I actually insert text next.
					if (bIsJustCreated) {
						OmfChatObject.triggerChatEvent(pstuser, chatObj, chatObjIdS,
								circleIdS, projIdS, otherUidS, true, PrmEvent.iEVT_CHAT_START, null);
					}
					else if (bIsFresh) {
						chatObj.setTriggerEvt(myUid);		// I will trigger event on my next insert text
					}
//System.out.println("*** done START chat");

					break;
				
				///////////////////////////////////////////////////////
				// 2.  caller is checking to see if there is newer chat text messages
				case OP_CHECK_CHAT:
					//System.out.println("*** Web calling check Chat ("
					//	+ myUidS + ", " + chatObjIdS + ", " + recvChatId + ")");
					
					// compare my last ID (recvChatId) with the lastMessageID to determine if I need
					// to return anything

					// retrieve the chat object from the hash.  It should be in the hash because web client
					// would only call OP_CHECK_CHAT after START_CHAT
					chatObj = OmfChat.getChatObjectInHash(chatObjIdS);
					if (chatObj == null) {
						try {
							ids = OmfChatObject.getMakeWeb(pstuser, myUidS, otherUidS,
									circleIdS, projIdS, chatObjIdS, false);
							chatObj = OmfChat.getChatObjectInHash(chatObjIdS);
						}
						catch (PmpException e) {e.printStackTrace();}
					}

					//System.out.println("    chatObj = " + chatObj);
					
					int lastID = chatObj.getLastMessageID();
//System.out.println("------------------- lastID of Chat = " + lastID);					
					if (lastID <= recvChatId) {
						// nothing new to return
						System.out.println("--- nothing to return to Web caller");
						createXml(chatObjIdS, lastID, null, null, null, null, null, null, null, response);
						break;
					}

					if (chatObj.isMoved())
					{
						// another user just moved this chat to meeting, return a message to user
						createXml(chatObjIdS, lastChatId, null, null, null, 
								null, chatObj.getMeetingId(), null, null, response);
						break;
					}

					
					// return any new chat blocks to caller
					lastChatId = chatObj.extractChatBlock(recvChatId, chatBlks);	// return chat block excluding recvChatId
					createXml(chatObjIdS, lastChatId, null, chatBlks.toString(),
							null, null, null, null, null, response);
//System.out.println("--- return buffer to Web caller: lastChatId = " + lastChatId);
					break;
					
				///////////////////////////////////////////////////////
				// 3.  add another person to the chat
				case OP_JOIN_CHAT:
					//System.out.println("*** Join Chat ("+ otherUidS + ")");
					chatObj = OmfChat.getChatObject(chatObjIdS);
					
					// put the new user onto the user list so that when he click we will find the chat session
					chatObj.setColor(pstuser, otherUidS);
					chatObj.save(pstuser);	// save to DB
					
					// generate an event to the user
					evt = PrmEvent.create(pstuser, PrmEvent.EVT_CHAT_JOIN, chatObjIdS, null, null);
					if (evt == null)
						break;
					chatUsers = chatObj.getUsers();
					idx = chatUsers.lastIndexOf(";");
					s = chatUsers.substring(idx+1);
					s = chatUsers.replaceFirst(";"+s, " and" + s);
					PrmEvent.setValueToVar(evt, "var1", s);
					
					// ready to trigger event to the specific user
					user u = (user)uMgr.get(pstuser, Integer.parseInt(otherUidS));
					PrmEvent.stackEvent(u, evt);

					break;
				
				///////////////////////////////////////////////////////
				// 4.  submit new chat text
				case OP_SUBMIT_CHAT:
					if (bDebug) System.out.println("*** Submit Chat message ("+ recvChatId + ") on [" + chatObjIdS + "]: " + text);
					// get chat object
					chatObj = OmfChat.getChatObject(chatObjIdS);
					
					if (chatObj.isMoved())
					{
						// another user just moved this chat to meeting, return a message to user
						createXml(chatObjIdS, lastChatId, null, null, null, null, chatObj.getMeetingId(), null, null, response);
						break;
					}
					
					// compose and save: <chat-123><chat-date 2014-10-5 15:32:18 /><chat-user 12345 />text</chat-123>
					// insert the chat text into OMM DB
					chatObj.insertChatMessageToDB(pstuser, text);	// will prepare and commit the chat message to DB

					// return chat block excluding recvChatId
					lastChatId = chatObj.extractChatBlock(recvChatId, chatBlks);
					
					// return any new chat blocks to caller
					createXml(chatObjIdS, lastChatId, null, chatBlks.toString(),
							null, null, null, null, null, response);

					// check if I need to trigger Start Chat event, but need to trigger submit text for mobile always
					if (circleIdS == null) circleIdS = chatObj.getCircleId();
					if (otherUidS == null) otherUidS = chatObj.getOtherUid();
					if (projIdS == null) projIdS = chatObj.getProjectId();
					if (chatObj.bNeedTriggerEvt(myUid))
					{
						OmfChatObject.triggerChatEvent(pstuser, chatObj, chatObjIdS,
								circleIdS, projIdS, otherUidS, false, PrmEvent.iEVT_CHAT_START, null);
						chatObj.setTriggerEvt(0);		// reset so that I won't trigger Start Chat again
					}
					
					break;
				
				///////////////////////////////////////////////////////
				// 5.  stop now, might chat later
				case OP_CLOSE_CHAT:
					// flush the chatObj to DB
					// deallocate of the memory chat object will based on time of inactiveness
					//l.info("---- Close Chat ("+ recvChatId + ")");
					chatObj = OmfChat.getChatObjectInHash(chatObjIdS);
					
					if (chatObj != null)
					{
						if (chatObj.bNeedTriggerEvt(myUid))
						{
							OmfChat.removeChatObj(pstuser, chatObjIdS, false);	// nothing has been done, just remove
							break;		// and return
						}
						else if (chatObj.isDirty())
						{
							chatObj.save(pstuser);	// save the hash chatObj to DB
							//l.info(   "saved chat by user.");
						}
						//chatObj.setState(OmfChatObject.ST_FILLED);	// no longer active (ECC: the other person might still be on it)
					}
					
					// chat_change event will refresh the chat list
   					circleIdS = chatObj.getCircleId();
					uids = chatObj.getUserIds();
					evt = PrmEvent.create(pstuser, PrmEvent.EVT_CHAT_CHANGE, chatObjIdS, circleIdS, null);
	    			if (circleIdS != null)
	    			{
	    				uids1 = uMgr.findId(pstuser, "Towns=" + circleIdS);
	    				uids = Util2.mergeIntArray(uids, uids1);
	    			}
					PrmEvent.stackEvent(pstuser, uids, evt);
 					break;
					
				///////////////////////////////////////////////////////
				// 6.  end this chat but save to a meeting object
				case OP_SAVE_CHAT_MTG:
					//System.out.println("*** Save meeting Chat ("+ recvChatId + "): ");
					// flush the chatObj to DB
					// save the chat object (and chat DB) to a meeting object in DB
					// deallocate of the memory chat object will based on time of inactiveness
					// This will remove the DB chat object.
					chatObj = OmfChat.getChatObject(chatObjIdS);
					String midS = chatObj.saveToMeeting(pstuser);	// save to meeting and remove the DB chat obj
					
					// trigger a EVT_MTG_NEW event
					if (midS != null) {
						PrmEvent.createTriggerEvent(pstuser, PrmEvent.EVT_CHATMTG_NEW, midS, null, null);
					}
					else {
						midS = "-1";		// error in saving chat to meeting: not authorized
					}
					
					// return the meeting ID to user
					createXml(chatObjIdS, 0, null, null, null, null, midS, null, null, response);
					break;

					///////////////////////////////////////////////////////
					// 7.  remove this chat from memory and DB
					// 8.  rename this chat
					case OP_REMOVE_CHAT:
					case OP_RENAME_CHAT:
						ids = OmfChatObject.getMakeWeb(pstuser, null, null, null, null, chatObjIdS, true);
						if (ids == null)
							break;			// this chat doesn't exist in DB
						
						chatObj = OmfChat.getChatObject(chatObjIdS);
    					uids = chatObj.getUserIds();
    					circleIdS = chatObj.getCircleId();
						
						// remove all events related to this chat
						evt = PrmEvent.create(pstuser, PrmEvent.EVT_CHAT_CHANGE, chatObjIdS, circleIdS, null);
		    			s = "MeetingID='" + (String)evt.getAttribute("MeetingID")[0] + "'"
		    				+ " && (Type='" + PrmEvent.EVT_CHAT_START + "' || Type='" + PrmEvent.EVT_CHAT_JOIN + "')";
		    			PrmEvent.checkCleanMaxEvent(pstuser, s, 0);
		    			if (circleIdS != null) {
		    				// event to the whole town
		    				uids1 = uMgr.findId(pstuser, "Towns=" + circleIdS);
		    				uids = Util2.mergeIntArray(uids, uids1);
		    			}
		    			else if (projIdS != null) {
		    				// event to project team
		    				PstAbstractObject o = pjMgr.get(pstuser, Integer.parseInt(projIdS));
		    				uids1 = Util2.toIntArray(o.getAttribute("TeamMembers"));
		    				uids1 = Util2.mergeIntArray(uids, uids1);
		    			}
		    			
	    				for (int i=0; i<uids.length; i++)
	    				{
	    					if (iOpType==OP_RENAME_CHAT && uids[i]==myUid)
	    						continue;
							// ready to trigger event to the specific user
							PrmEvent.stackEvent(pstuser, uids[i], evt);
	    				}
		    			
	    				if (iOpType == OP_REMOVE_CHAT)
	    				{
							// remove from both hash and DB if it is there
							OmfChat.removeChatObj(pstuser, chatObjIdS, true);
	    				}
	    				else if (iOpType == OP_RENAME_CHAT)
	    				{
							chatObj.setName(text);
							chatObj.saveName(pstuser);
	    				}
						break;

					///////////////////////////////////////////////////////
					
				default:
					l.error("OmfChatAjax.doPost(): unknown op type [" + iOpType + "]");
					break;
			}
		}
		catch (PmpException e)
		{
			l.error("Exception in OmfChatAjax.doPost()");
			e.printStackTrace();
			return;
		}
		
	}	// END: doPost()
	

	private static void createXml(
			String				chatObjIdS,
			int					lastChatId,
			String				allChatBlocks,			// all chat blks (only at Start Chat)
			String				newChatBlocks,			// the returned check blocks in DIV's
			String				chatUsers,				// current user on the chat session
			String				myColor,				// the caller's color (only at Start Chat)
			String				midS,					// return saved meeting ID
			String				cirName,				// circle name if it is a circle chat (only at Start Chat)
			String				chatName,				// chat name
			HttpServletResponse response)
	throws IOException
	{
		createXmlHead(response);
		
		PrmMtgParticipants.createXmlChild(CHATOBJ_ID_TAG, chatObjIdS, response);
		PrmMtgParticipants.createXmlChild(CHAT_IDX_TAG, String.valueOf(lastChatId), response);
		if (allChatBlocks!=null && allChatBlocks.length()>0)
		{
			// at start chat, return all chat blocks at once (for performance)
			PrmMtgParticipants.createXmlChild(CHAT_BLOCK_TAG, allChatBlocks, response);
		}
		else if (newChatBlocks!=null && newChatBlocks.length()>0)
		{
			// while chat is going on, return chat text one by one
			createXmlChatBlock(newChatBlocks, response);
		}
		if (chatUsers != null)
			PrmMtgParticipants.createXmlChild(CHAT_USER_TAG, chatUsers, response);
		if (myColor != null)
			PrmMtgParticipants.createXmlChild(CHAT_COLOR_TAG, myColor, response);
		if (midS != null)
			PrmMtgParticipants.createXmlChild(CHAT_MID_TAG, midS, response);
		if (cirName != null)
			PrmMtgParticipants.createXmlChild(CHAT_CIRCLE_NAME, cirName, response);
		if (chatName != null)
			PrmMtgParticipants.createXmlChild(CHAT_NAME, chatName, response);

		response.getWriter().write(PrmMtgConstants.XML_RESPONSE_CL);
	}	// END: createXml()
	
	private static void createXmlChatList(
			String				chatS,				// the XML to list the chat
			HttpServletResponse response)
	throws IOException
	{
		createXmlHead(response);
		PrmMtgParticipants.createXmlChild(OmfEventAjax.EVENT_CHAT_TAG, chatS, response);
		response.getWriter().write(PrmMtgConstants.XML_RESPONSE_CL);
	}
	
	private static void createXmlHead(
			HttpServletResponse response)
	throws IOException
	{
		response.setContentType(PrmMtgConstants.XML_CONTENT);
		response.setHeader(PrmMtgConstants.XML_CACHECONTROL, PrmMtgConstants.XML_NOCACHE);
		response.getWriter().write(PrmMtgConstants.XML_RESPONSE_OP);
	}
	
	private static void createXmlChatBlock(String chatBlk, HttpServletResponse response)
	throws IOException
	{
		String tag, chatText;
		int idx1 = 0, idx2;
		
		String [] sa = chatBlk.split("<DIV>");
		for (int i=0; i<sa.length; i++) {
			chatText = sa[i];
			chatText.replace("</DIV>", "");		// removed both <DIV> and </DIV>
			if (StringUtil.isNullOrEmptyString(chatText)) continue;
			
			idx1 = chatText.indexOf(OmfChatObject.OPENTAG1);		// <chat-
			idx2 = chatText.indexOf(OmfChatObject.OPENTAG2, idx1);	// >
			tag  = chatText.substring(idx1+1, idx2);
//System.out.println("+++++ !!! add tag to XML: " + tag);			// chat-123
			PrmMtgParticipants.createXmlChild(tag, chatText, response);
		}

/*
		while ((idx1 = chatBlk.indexOf(OmfChatObject.OPENTAG1, idx1)) != -1)
		{
			idx2 = chatBlk.indexOf(OmfChatObject.OPENTAG2, idx1);	// <chat-
			tag = chatBlk.substring(idx1+1, idx2);
			idx1 = chatBlk.indexOf(OmfChatObject.CLOSETAG1, idx2);	// </chat-
			chatText = chatBlk.substring(idx2+1, idx1);
			PrmMtgParticipants.createXmlChild(tag, chatText, response);
		}
*/
	}

    public static String unescape(String src) {
        StringBuffer tmp = new StringBuffer();
        tmp.ensureCapacity(src.length());
        int lastPos = 0, pos = 0;
        char ch;
        while (lastPos < src.length()) {
            pos = src.indexOf("%", lastPos);
            if (pos == lastPos) {
                if (src.charAt(pos + 1) == 'u') {
                    ch = (char) Integer.parseInt(
                            src.substring(pos + 2, pos + 6), 16);
                    tmp.append(ch);
                    lastPos = pos + 6;
                } else {
                    ch = (char) Integer.parseInt(
                            src.substring(pos + 1, pos + 3), 16);
                    tmp.append(ch);
                    lastPos = pos + 3;
                }
            } else {
                if (pos == -1) {
                    tmp.append(src.substring(lastPos));
                    lastPos = src.length();
                } else {
                    tmp.append(src.substring(lastPos, pos));
                    lastPos = pos;
                }
            }
        }
        return tmp.toString();
    }

}
