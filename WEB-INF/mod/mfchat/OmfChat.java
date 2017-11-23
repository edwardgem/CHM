////////////////////////////////////////////////////
//	Copyright (c) 2014, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	OmfChat.java
//	Author:	ECC
//	Date:	11/14/14
//	Description:
//		Implementation of OmfChat class, for mobile app.
//		Chat text are of the following format: <DIV><chat-12345>esmith:bla, bla, bla</chat-12345></DIV>
//
//	Modification:
//
//	TODO:	Need to use Database to store each chat message.  Do not use memory buffer as you might have multiple virtual machines for millions of users.
//
////////////////////////////////////////////////////////////////////


package mod.mfchat;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;

import oct.codegen.chat;
import oct.codegen.chatManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstUserAbstractObject;

import org.apache.log4j.Logger;

import util.PrmLog;
import util.StringUtil;
import util.Util2;

/**
 * @author edwardc
 *
 */
public class OmfChat
{
	private static final String OPT_SILENCE = chat.OPT_SILENCE;		// option Silence:12345;39414
	static Logger l;
	private static chatManager cMgr;
	
	private static HashMap <String, OmfChatObject> chatHash;		// one chat obj per each chat session
	
	static {
		try {cMgr = chatManager.getInstance();}
		catch (PmpException e) {}
		l = PrmLog.getLog();
		chatHash	= new HashMap<String, OmfChatObject>();
	}
	
	public static HashMap<String, OmfChatObject> getHash() {return chatHash;}
	
	synchronized public static OmfChatObject getChatObjectInHash(String chatIdS)
	{
		if (chatIdS!=null)
		{
			if (chatHash.containsKey(chatIdS))
				return (OmfChatObject)chatHash.get(chatIdS);
		}
		return null;	// not in hash
	}
	
	synchronized public static OmfChatObject getChatObject(String chatIdS)
	{
		if (chatIdS!=null)
		{
			if (chatHash.containsKey(chatIdS))
			{
				return (OmfChatObject)chatHash.get(chatIdS);
			}
			else
			{
				// the chat is not in hash
				OmfChatObject chatObj = new OmfChatObject(chatIdS);				
				chatHash.put(chatIdS, chatObj);
				return chatObj;
			}
		}
		// caller must have an id
		return null;
	}
	
	synchronized public static void removeChatObj(PstUserAbstractObject pstuser, String chatIdS, boolean bFromDB) {
		if (chatIdS!=null) {
			chatHash.remove(chatIdS);
		}
		
		if (bFromDB)
		{
			try {OmfChatObject.removeChat(pstuser, chatIdS);}
			catch (PmpException e){l.error("OmfChat.removeChatObj(): exception in removing chat [" + chatIdS + "]");}
		}
	}
	
	private static int [] getMake(PstUserAbstractObject pstuser, String uidS1, String uidS2,
			String circleIdS, String projIdS, String chatIdS, boolean bNoMake)
		throws PmpException
	{
		return OmfChatObject.getMakeMobile(pstuser, uidS1, uidS2, circleIdS, projIdS, chatIdS, bNoMake);
	}
	
	/**
	 * 
	 * create a chat in the OMM database
	 * @param pstuser	Creator of this chat.
	 * @param chatName	The name of this chat.
	 * @param uidSArr	Initial attendees participating in this chat.
	 * @param iconFS	Icon stream of this chat.
	 * @return			The ID of the new chat
	 * @throws PmpException
	 */
	public static String createAnyChat(PstUserAbstractObject pstuser, String chatName,
			String [] uidSArr, InputStream iconFS, String ext)
		throws PmpException
	{
		return OmfChatObject.createChat(pstuser, chatName, null, uidSArr, iconFS, ext);
	}
	
	/**
	 * mobile app only: insert a chat message text.  The call will save the chat to the OMM repository.
	 * @param pstuser	Author.
	 * @param chatIdS	The chat object.
	 * @param text		Text to be inserted.
	 * @param dateS		Caller supply the timestamp of this inserted text
	 * @return			The ID of the new chat message.
	 * @throws PmpException
	 */
	public static String insertChatMessage(PstUserAbstractObject pstuser, String chatIdS,
			String text, String dateS)
		throws PmpException
	{
		String uidS = String.valueOf(pstuser.getObjectId());
		int [] ids = OmfChat.getMake(pstuser, uidS, null, null, null, chatIdS, true);
		if (ids.length <= 0) {
			throw new PmpException("The chat [" + chatIdS + "] is not found in the repository.");
		}
		OmfChatObject chatObj = getChatObjectInHash(chatIdS);		// getMake() will put it in hash
		
		// The call will compose a message and put it in OMM DB
		// compose a message: <chat-123><chat-date=2014-10-5 15:32:18 /><chat-user=12345 />text</chat-123>
		// save this one chat message to Database and cache
		int messageId = chatObj.insertChatMessageToDB(pstuser, text, dateS);
		
		return String.valueOf(messageId);
	}
	
	public static String insertChatMessage(PstUserAbstractObject pstuser, String chatIdS, String text)
			throws PmpException
	{
		return insertChatMessage(pstuser, chatIdS, text, null);
	}
	
	/**
	 * mobile app only: return the last numOfMessages chat messages.
	 * @param pstuser
	 * @param chatIdS		ID of the chat.
	 * @param segmentNum	segment of chat messages to be retrieved, starting from the most recent chat.
	 * 						Segment size is determined in OmfChatObject.java.
	 * @param lastMsgId		request to return only messages after this messageID, excluding this. When this is supplied,
	 * 						segmentNum is ignored. If lastMsgId is not found in DB, nothing is returned.
	 * @return				An array of chat messages.  Web format: <DIV><chat-123> ... text ... </chat-123></DIV>
	 * mobile app return format: <chat-123><chat-date=2014-10-5 15:32:18 /><chat-user=12345 />text</chat-123>
	 */
	public static String [] getChatMessages(
			PstUserAbstractObject pstuser, String chatIdS, int segmentNum, String lastMsgIdS)
		throws PmpException
	{
		// get the last numOfMessages messages from OMM DB
		
		// get the chat from memory, if not found, get it from OMM DB, but don't make a new one if not found
		if (pstuser == null) throw new PmpException("getChatMessages(): pstuser cannot be null.");
		
		int [] ids = OmfChat.getMake(pstuser, String.valueOf(pstuser.getObjectId()), null, null, null, chatIdS, true);
		if (ids==null || ids.length<=0) {
			throw new PmpException("The chat [" + chatIdS + "] is not found in the repository.");
		}
		OmfChatObject chatObj = getChatObjectInHash(chatIdS);	// getMake() will put it in hash

		// getChatSegment() is the call to get the list of messages
		int iLastMsgIdS = -1;
		if (!StringUtil.isNullOrEmptyString(lastMsgIdS)) {
			try {iLastMsgIdS = Integer.parseInt(lastMsgIdS);}
			catch (NumberFormatException e) {}
		}
		
		// calling from mobile app only
		ArrayList <String> msgList = chatObj.getChatSegment(segmentNum, iLastMsgIdS, true);		
		return msgList.toArray(new String[0]);
	}
	
	/**
	 * get the chat message's author user ID
	 * @param msg
	 * @return	user ID, or null if failed.
	 */
	public static String getMessageUserId(String msg)
	{
		return OmfChatObject.getMessageUserId(msg);
	}
	
	/**
	 * get the chat message's creation date String in "yyyy-MM-dd HH:mm:ss" format
	 * @param msg
	 * @return	Date object that this chat message is posted
	 */
	public static String getMessageDate(String msg)
	{
		return OmfChatObject.getMessageDate(msg);
	}
	
	
	/**
	 * extract the pure text of the chat message.
	 * @param msg
	 * @return	the text or empty String if not found
	 */
	public static String getMessageText(String msg)
	{
		return OmfChatObject.getMessageText(msg);
	}
	
	public static String getMessageId(String msg)
	{
		return String.valueOf(OmfChatObject.getMessageId(msg));
	}
	
	/**
	 * setChatName both in OMM DB and in cache
	 * @param pstuser
	 * @param chatIdS
	 * @param newChatName
	 * @throws PmpException
	 */
	public static void setChatName(PstUserAbstractObject uObj, String chatIdS, String newChatName)
		throws PmpException
	{
		chat chatObj = (chat) cMgr.get(uObj, chatIdS);
		chatObj.setAttribute("Name", newChatName);
		cMgr.commit(chatObj);
		
		// update memory copy if it is in cache
		OmfChatObject oChatObj = getChatObjectInHash(chatIdS);
		if (oChatObj != null) {
			oChatObj.setName(newChatName);
		}
	}
	
	/**
	 * set icon for a chat.
	 * @param cObj
	 * @param iconFS
	 * @param ext
	 * @throws PmpException
	 */
	public static void setChatIcon(chat cObj, InputStream iconFS, String ext)
			throws PmpException
	{
		OmfChatObject.setChatIcon(cObj, iconFS, ext);
	}

	/**
	 * set/unset a chat to silence for a user.
	 * @param uObj
	 * @param chatIdS
	 * @param userIdS
	 * @param bSilence
	 * @throws PmpException
	 */
	public static void setChatSilence(PstUserAbstractObject uObj, String chatIdS, String userIdS, boolean bSilence)
		throws PmpException
	{
		chat chatObj = (chat) cMgr.get(uObj, chatIdS);

		String userIdList = chatObj.getSilence();
		if (bSilence) {
			// set silence
			userIdList = Util2.addSubString(userIdList, userIdS, ";");	// a list of userId separated by ";"
		}
		else {
			// unset silence
			userIdList = Util2.removeSubString(userIdList, userIdS, ";");
		}

		chatObj.setOption(cMgr, OPT_SILENCE, userIdList);			// this call will commit
	}
}
