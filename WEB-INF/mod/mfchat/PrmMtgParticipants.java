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
//      Interacts w/ Live Meeting to handle invite input from participants
//
//	Modification:
//		@AGQ092806	Added an algorithm to detect if the current position is the
//					desired text input location. Trys to avoid inserting text 
//					inbetween tags.
//		ECC101106	Input queue.
//
//		@AGQ101106	Return counters for forcing reload of mtg notes
/////////////////////////////////////////////////////////////////////

package mod.mfchat;

import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.apache.log4j.Logger;

import oct.codegen.meeting;
import oct.codegen.meetingManager;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstGuest;
import oct.pst.PstManager;
import oct.pst.PstUserAbstractObject;
import util.PrmLog;
import util.PrmMtgConstants;
import util.PrmUpdateCounter;
import util.Util;
import util.Util2;

public class PrmMtgParticipants extends HttpServlet implements PrmMtgConstants{
	/**
	 * 
	 */
	private static final long serialVersionUID = 10060101L;

	static Logger l;
	
	private static final String MID 		= "mid";
	private static final String ISRUN 		= "isRun";
	private static final String RUN 		= "run";
	private static final String BTEXT		= "bText";
	private static final String CLEARONLINE	= "clearOnline";
	private static final String EXPRID		= "id";
	private static final String EXPRSTR		= "str";
	private static final String QUID		= "qUid";		// the user obj id to be queued for input
	private static final String QREMOVE		= "removeQ";	// the user obj id to be removed from the input queue
	private static final String TYPING		= "typing";		// expression of someone typing a chat text
	
	private static final SimpleDateFormat df = new SimpleDateFormat("hh:mm");
	
	private static meetingManager 	mMgr;
	private static userManager 		uMgr;
	
	static {
		l = PrmLog.getLog();
		
		initMgr();
	}
	
	private static void initMgr() {
		try {
			mMgr = meetingManager.getInstance();
			uMgr = userManager.getInstance();
		} catch (PmpException e) {
			mMgr = null;
			uMgr = null;
		}
	}
	
	public void doGet(HttpServletRequest request, HttpServletResponse response)
	throws ServletException, IOException {
		boolean isOn = false;	// Determines if live feedback is on. Requires change of reload time
		boolean isParticipant = false;
		Integer revokeTime = null;
		String midS = request.getParameter(MID);
		String isRun = request.getParameter(ISRUN); // Runner/Facilitator View
		String run = request.getParameter(RUN);
		String hasColor = request.getParameter("hasColor");	
		String clearOnline = request.getParameter(CLEARONLINE);
		String idS; // Current user id
		String chatColor = null; // Current user's chat color
		long svrTime = -1; // Current time in milliseconds
		
		if (clearOnline != null) {
			MeetingParticipants.clearOnline(midS);
			return;
		}
		
		// Get the current session and pstuser 
		PstUserAbstractObject pstuser = null;
		HttpSession httpSession = request.getSession(false);
		// Verify that this is indeed the user
		// Check valid user
		if (httpSession != null)
			pstuser = (PstUserAbstractObject)httpSession.getAttribute(PSTUSER);
		if (pstuser == null) {
			// Session Timeout (and users clicks Live) or Invalid Meeting ID
			try {
				createXmlMessage(USERTIMEOUT, response);
			} catch (IOException e) {};
			return;
		}
		
		boolean isGuest = false;
		if (pstuser instanceof PstGuest) isGuest = true;

		// @ECC092806 received expression next index: called by both facilitator and participants
		String idxS = request.getParameter(EXPRIDX);
		String exprStr = "";
		if (idxS != null)
		{
			//System.out.println("Recv Idx = "+idxS);				
			// exprStr is nextIdx@@id1:str1@@id2:str2 ... or ""
			int idx = Integer.parseInt(idxS);
			exprStr = MeetingParticipants.getUnreadExpr(midS, idx, true);	// will cleanup
			//System.out.println("   exprStr ret = "+exprStr);
		}

		isOn = MeetingParticipants.isOn(midS);
		idS = String.valueOf(pstuser.getObjectId());
		
		if (isOn) {
			if (isRun!=null) {
				
				// Redirects facilitator to start invite participant view
				createXmlRedirect(null, "mtg_live.jsp?mid="+midS, response);
				return;
			}
			// Redirects user when he is revoked while Chat is on
			if (run != null) {
				boolean isFacilitator = isFacilitator(pstuser, midS);
				if (!isFacilitator) {
					createXmlRedirect(REVOKEDRECORDER, "mtg_live.jsp?mid="+midS, response);
					return;
				}
			}
			// Check to see if I am a participant
			if (!isGuest) {
				isParticipant = MeetingParticipants.isParticipant(midS, idS);
				if(hasColor == null) {
					chatColor = MeetingParticipants.getMeetingColor(midS, idS);					
					svrTime = new Date().getTime();
				}
			}
		}	
		
		// @AGQ091806 Set that I am online
		if (!isGuest)
			MeetingParticipants.setOnline(midS, idS);
		
		revokeTime = MeetingParticipants.getRevokeTime(midS);
		// @AGQ101106
		int[] localCounters = PrmUpdateCounter.getMtgCounters(midS);
		createXml(String.valueOf(isOn), String.valueOf(isParticipant), 
				String.valueOf(revokeTime), exprStr, chatColor, svrTime, localCounters, -1, response);
	}
	
	public void doPost(HttpServletRequest request, HttpServletResponse response) 
	throws ServletException, IOException {
		int mid = 0;
		int uid = 0;
		String midS = request.getParameter(MID);
		String bText = request.getParameter(BTEXT);

		// @ECC092806 Send Expression
		String id = request.getParameter(EXPRID);
		
		// Get the current session and pstuser 
		PstUserAbstractObject pstuser = null;
		HttpSession httpSession = request.getSession(false);
		// Verify that this is indeed the user
		if (httpSession != null) {
			pstuser = (PstUserAbstractObject)httpSession.getAttribute(PSTUSER);				
			uid = pstuser.getObjectId();
		}

		// Verifications
		if (midS != null) {
			try {
				mid = Integer.parseInt(midS);
			} catch (NumberFormatException e) {
				l.error("Meeting ID parse exception for mid " + midS + 
						" user " + uid);
			}
		}

		if (pstuser == null || mid == 0) {
			// Session Timeout (and users clicks Live) or Invalid Meeting ID
			try {
				createXmlMessage(USERTIMEOUT, response);
			} catch (IOException e) {};
			return;
		}
		
		int [] localCounters;

		// @ECC101106 Input queue for chat
		String qUid = request.getParameter(QUID);
		if (qUid != null)
		{
			if (request.getParameter(QREMOVE) == null)
			{
				// put the uid into the input queue
				//if (!qUid.equals(MeetingParticipants.getInputUser(midS)))	// the user is not inputing
				String s = null;
				try {s = String.valueOf(PstManager.getIdByName(pstuser, 7, qUid));}
				catch (PmpException e){l.error("Cannot find object id to enqueue user [" + qUid + "]");}
				if (s!=null && !MeetingParticipants.isParticipant(midS, s))		// user not in chat session
				{
					MeetingParticipants.addToInputQueue(midS, qUid);
				}
			}
			else
			{
				// remove the uid from the input queue
				MeetingParticipants.removeFromInputQueue(midS, qUid);
			}
			//PrmUpdateCounter.updateOrCreateCounterArray(String.valueOf(mid), ININDEX);
			String inputQueS = MeetingParticipants.getAllOnQueue(midS);
			localCounters = PrmUpdateCounter.getMtgCounters(midS);
			createXmlInQ(inputQueS, localCounters, -1, response);
			return;
		}

		if (id == null)
		{
			// handle chat
			String chatIdxS = request.getParameter(CHATIDX);
			// @AGQ101006 Determine if I should return the whole note after submit
			if (chatIdxS != null) {
				// @ECC100606 Need to put new chat string into the meeting's string buffer and enqueue an element
				StringBuffer newChatStrBuf = appendMessage(pstuser, mid, uid, bText);
				MeetingParticipants.addChat(midS, newChatStrBuf);	// insert into buffer and the enqueue an element		
				int idx = Integer.parseInt(chatIdxS) - 1;
				bText = MeetingParticipants.getUnreadChat(midS, idx, true);	// will cleanup
				localCounters = PrmUpdateCounter.getMtgCounters(midS);
				createXmlMtgNotes(bText, localCounters, -1, response);
			}
			else {				
				// need to clean up and merge code
				StringBuffer [] sbArr = appendMessage(pstuser, mid, uid, bText, true);
				StringBuffer newChatStrBuf = sbArr[0];
				MeetingParticipants.addChat(midS, newChatStrBuf);	// insert into buffer and the enqueue an element		
				String newMtgNotes = sbArr[1].toString();
				localCounters = PrmUpdateCounter.getMtgCounters(midS);
				createXmlMtgNotes(newMtgNotes, localCounters, -1, response);
			}
			return;
		}
		else
		{
			// handle expression
			// @ECC092806 received Send Expression from client
			String str = request.getParameter(EXPRSTR);
			if (id.equals(TYPING))
				str = Util2.findPictureName(pstuser, str);	// str is unchanged if there is no PictureFile for this user
			else
			{
				// insert expression note onto meeting note
				String color = MeetingParticipants.getMeetingColor(String.valueOf(mid), String.valueOf(uid));
				StringBuffer sb = new StringBuffer();
				String s = (id.equals("ques")?"question":(id.equals("thank")?"thanks":(id.equals("hand")?"raise hand":id)));
				sb.append("<div><a href='javascript:showExpr(\"" + id + ":" + str + "\"" + ");' style='font-size:14px; font-weight:normal; text-indent:20px; line-height:25px; color:"
						+ color + "'>"+ str + ": " + s + "</a></div>");
				appendMessage(pstuser, mid, sb, sb.length(), false, false, false);
				str += ":" + color;
			}
			MeetingParticipants.addExpr(midS, new OmfExpr(id, str));	// insert into meeting queue
		}
		
	}
	
	private static boolean isFacilitator(PstUserAbstractObject pstuser, String midS) {
		try {
			int mid = Integer.parseInt(midS);
			meeting m = (meeting) mMgr.get(pstuser, mid);
			String recorder = (String) m.getAttribute(meeting.RECORDER)[0];
			return ((String.valueOf(pstuser.getObjectId())).equals(recorder));
		} catch (NumberFormatException e) {
		} catch (PmpException e) {
		}
		return false;
	}
	
	public static boolean appendStatus(PstUserAbstractObject pstuser, int mid,
			int uid) {
		try {
			StringBuffer sb = new StringBuffer();
			String [] strArr = MeetingParticipants.getMeetingParticipants(String.valueOf(mid));
			if (strArr == null) return false;
			Integer [] intArr = new Integer[strArr.length];
			user u;
			for (int i=0; i<strArr.length; i++) {
				intArr[i] = Integer.valueOf(strArr[i]);
			}
			PstAbstractObject [] pstArr = uMgr.get(pstuser, intArr);
			Util.sortUserArray(pstArr);
			//Date d = new Date();
			int sessionCt = MeetingParticipants.getSessionCount(String.valueOf(mid));
			sb.append("</br><DIV style=\"FONT-WEIGHT: bold; COLOR: #4060a0\">[Input session "+
					sessionCt +": input from ");
			int andCt = pstArr.length-2;
			String s;
			int idx;
			for (int i=0; i<pstArr.length; i++) {
				u = (user) pstArr[i];
				s = u.getObjectName();
				if ((idx = s.indexOf('@')) != -1) s = s.substring(0, idx);	// take first part of email username
				sb.append(s);
				if (i == andCt) {
					sb.append(" and ");
				}
				else if (i < andCt) {
					sb.append(", ");
				}
			}
			sb.append("]</div><br /><div id='insertNotes'>");
			int length = sb.toString().length();
			/*sb.append("</div><var id='scrollMark'></var><br /><DIV style=\"FONT-WEIGHT: bold; COLOR: #4060a0\">[Above are entries from input session " + 
					sessionCt + "]</div><br /><br />");*/
			sb.append("</div><var id='scrollMark'></var>");
			StringBuffer[] sbArr = appendMessage(pstuser, mid, sb, length, true, true, true);
			StringBuffer newMtgNotes = null;
			if (sbArr != null)
				newMtgNotes = sbArr[0];
			return (newMtgNotes != null && newMtgNotes.length() > 0);
		} catch (NumberFormatException e) {
			l.error(e.getMessage());
		} catch (PmpException e) {
			l.error(e.getMessage());
		}
		return false;
	}

	private static StringBuffer appendMessage(PstUserAbstractObject pstuser, int mid,
			int uid, String message) {
		StringBuffer[] sbArr = appendMessage(pstuser, mid, uid, message, false);
		if (sbArr != null)
			return sbArr[0];
		else
			return null;
	}
	private static StringBuffer[] appendMessage(PstUserAbstractObject pstuser, int mid,
			int uid, String message, boolean fullMessage) {
		// Get user's ID and Color
		StringBuffer sb = new StringBuffer();
		String color = MeetingParticipants.getMeetingColor(String.valueOf(mid), String.valueOf(uid));
		user u = (user) pstuser;
		Date d = new Date();
		// Please see NAME_IDX in mtg.js if any changes are made here
		sb.append("<div>");
		sb.append("<font color='#555555'>["+df.format(d)+"]</font> <span style='color:"+color+"; font-weight: normal;'>");
		int idx;
		String s = u.getObjectName();
		if ((idx = s.indexOf('@')) != -1) s = s.substring(0, idx);	// take first part of email username
		sb.append(s);
		sb.append(": </span><span style='color: black; font-weight: normal;'>");
		sb.append(Util.stringToHTMLString(message));	// Escapes html tags
		sb.append("</span>");
		sb.append("</div>");
		return appendMessage(pstuser, mid, sb, sb.length(), false, fullMessage, true);
	}
	
	private static StringBuffer[] appendMessage(PstUserAbstractObject pstuser, int mid, 
			StringBuffer message, int length, boolean isStatus, boolean fullMessage, boolean bUpdateCounter) {
		StringBuffer newMtgNotes = new StringBuffer();
		if (mMgr == null || uMgr == null) initMgr();	// Shouldn't happen
		try {
			// Get meeting notes
			Object obj = MeetingParticipants.getObject(String.valueOf(mid));
			synchronized (obj) {
				meeting mtg = (meeting) mMgr.get(pstuser, mid);
				String midS = String.valueOf(mid);
				byte [] bArr = (byte []) mtg.getAttribute(meeting.NOTE)[0];
				if (bArr == null) bArr = new byte[0];
				StringBuffer bText = new StringBuffer();
				int curDiff = 0;
				int pos;
				if (bArr!=null) {				
					// replace the BOLD blue label with Normal grey label
					String oldTxt = new String(bArr);
					if (fullMessage)
					{
						String old = "FONT-WEIGHT: bold; COLOR: #4060a0";
						pos = MeetingParticipants.getCurPosition(midS, 0);
						int idx = 0;
						while ((idx = oldTxt.indexOf(old, idx)) > -1)
							if (pos > idx++) curDiff += 2;
						oldTxt = oldTxt.replaceAll(old, "FONT-WEIGHT: NORMAL; COLOR: #888888");
						MeetingParticipants.getCurPosition(midS, curDiff);
					}
					bText.append(oldTxt);
				}
	
				// Get the position this user is suppose to write
				// Paste user feedback onto meeting notes
				pos = MeetingParticipants.getCurPosition(midS, length);	
				if (pos >= 0 && pos < bArr.length) {
					// Find out where to insert the next status text
					if (isStatus) {	
						/* @AGQ092806
						 * Client gives us two characters and a position. We match the position
						 * to see if can match the same characters.
						 * Literal = ABCD; starting w/ position 0 for A
						 * Given charBefore = B, charAfter = C from client
						 * 1. Pos 1, BC == BC Characters matches, we insert the text
						 * 2. Pos 0, BC != AB Move the position up by one 
						 *    Pos 1, BC == BC Characters matches, we insert the text
						 * 3. Pos 2, BC != CD Move the position down by one
						 *    Pos 1, BC == BC Characters matches, we insert the text
						 * 4. Characters still doesn't match check to see if we are
						 *    next to < or >. If we are insert before < or after >.
						 * 5. Current this does not handle characters that are more than
						 *    one index away.
						 */
						String before = MeetingParticipants.getCurCharBefore(midS);
						String after = MeetingParticipants.getCurCharAfter(midS);
						Character charBefore = null;
						Character charAfter = null;
						
						if (before != null && before.length() > 0)
							charBefore = Character.valueOf(before.charAt(0));
						if (after != null  && after.length() > 0)
							charAfter = Character.valueOf(after.charAt(0));	
						
						// Check to see if characters matches
						if (checkChar(charBefore, charAfter, bText, pos)) {
							bText.insert(pos, message);
						}
						// Check the 
						else if (checkChar(charBefore, charAfter, bText, pos+1)){						
							MeetingParticipants.getCurPosition(midS, 1); // Reposition
							bText.insert(pos+1, message);
						}
						else if (checkChar(charBefore, charAfter, bText, pos-1)) {
							MeetingParticipants.getCurPosition(midS, -1);
							bText.insert(pos-1, message);
						}
						// Cannot match characters, do a brief check to make sure characters are not inbetween angle brackets
						else {
							char curBefore = ' ';
							if ((pos-1) >= 0) // Pos is at 0 when FCKeditor has never been clicked
								curBefore = bText.charAt(pos-1);
							char curAfter = bText.charAt(pos);
							if (curBefore == '<') {								
								MeetingParticipants.getCurPosition(midS, -1);
								bText.insert(pos-1, message);
							}
							else if (curAfter == '>') {
								MeetingParticipants.getCurPosition(midS, 1);
								bText.insert(pos+1, message);
							}
							else {
								MeetingParticipants.setPosition(midS, String.valueOf(pos + length)); // This should not be needed
								bText.insert(pos, message);
							}
						}
					}
					// Should be safe to insert text after status is correctly set
				else
						bText.insert(pos, message);
				}
				else {
					// Reset to position since message is appended to the bottom.
					MeetingParticipants.setPosition(midS, String.valueOf(bText.length() + length));
					bText.append(message);			
				}
				newMtgNotes = bText;
				mtg.setAttribute(meeting.NOTE, newMtgNotes.toString().getBytes());
				mMgr.commit(mtg);
			}
			
			if (bUpdateCounter)
				PrmUpdateCounter.updateOrCreateCounterArray(String.valueOf(mid), MNINDEX);

			StringBuffer [] sbArr = null;
			if (fullMessage) {
				sbArr = new StringBuffer[2];
				sbArr[0] = message;
				sbArr[1] = newMtgNotes;
			}
			else {
				sbArr = new StringBuffer[1];
				sbArr[0] = message;
			}
			return sbArr;
		} catch (PmpException e) {
			l.error(e.getMessage());
			return null;
		} 
	}
	
	// @AGQ092806
	private static boolean checkChar(Character charBefore, Character charAfter, 
			StringBuffer bText, int pos) {
			Character curBefore = null;
			Character curAfter = null;
			if ((pos-1) > 0)
				curBefore = Character.valueOf(bText.charAt(pos-1));
			else
			return false;
			
			if (pos < bText.length())
				curAfter = Character.valueOf(bText.charAt(pos));
			else
				return false;
			
			boolean result = (charBefore != null && charBefore.equals(curBefore) &&
				charAfter != null && charAfter.equals(curAfter));			
			return result;
		} 
	
	public static void createXmlInQ(
			String 				inQStr, 
			int [] 				counters,
			int 				flag,
			HttpServletResponse response) 
	throws IOException {
		createXml(null, null, null, null, null, null, null, null, inQStr, counters, flag, response);
	}	
	
	public static void createXmlMtgNotes(
			String 				bText, 
			int [] 				counters,
			int 				flag,
			HttpServletResponse response) 
	throws IOException {
		createXml(null, null, null, null, null, null, null, bText, null, counters, flag, response);
	}
	
	public static void createXml(
			String 				isOn, 
			String 				isParticipant, 
			String				revokeTime,
			String				exprStr,
			String 				chatColor,
			long				svrTime,
			int []				counters, // @AGQ101106
			int					flag,
			HttpServletResponse response) 
	throws IOException {	
		createXml(null, null, isOn, isParticipant, revokeTime, exprStr, null, null, null, chatColor, svrTime, counters, flag, response);
	}
	
	public static void createXml(
			String 				alertMessage, 
			String 				url, 
			String 				isOn,
			String 				isParticipant, 
			String 				revokeTime, 
			String				exprStr,			
			String 				message,
			String				bText,
			String				inQStr,				
			int [] 				counters,
			int					flag,
			HttpServletResponse response)
	throws IOException {
		createXml(alertMessage, url, isOn, isParticipant, revokeTime, exprStr, message, bText, inQStr, null, -1, counters, flag, response);
	}
	
	/**
	 * Constructs an Xml response.
	 * <pre>
	 * &lt;response&gt;
	 * 	&lt;meetingNotes&gt;
	 * 		Meeting Notes
	 *	&lt;/meetingNotes&gt;
	 * &lt;/response&gt;
	 * </pre>
	 * @param isOn			Is live feedback on
	 * @param isParticipant Is current user a participant
	 * @param revokeTime	Current user's time left before
	 * 						live feedback is revoked
	 * @param response		Response page to write XML
	 * @throws IOException
	 */
	public static void createXml(
			String 				alertMessage, 
			String 				url, 
			String 				isOn,
			String 				isParticipant, 
			String 				revokeTime, 
			String				exprStr,			// @ECC092806
			String 				message,
			String				bText,
			String				inQStr,				// @ECC101106
			String				chatColor,
			long				svrTime,
			int [] 				counters,
			int					flag,
			HttpServletResponse response)
	throws IOException {
		response.setContentType(XML_CONTENT);
		response.setHeader(XML_CACHECONTROL, XML_NOCACHE);
		response.getWriter().write(XML_RESPONSE_OP);
		createXmlChild(ALERTMESSAGE, alertMessage, response);
		createXmlChild(URL, url, response);
		createXmlChild("isOn", isOn, response);
		createXmlChild("isParticipant", isParticipant, response);
		createXmlChild("revokeTime", revokeTime, response);
		createXmlChild(EXPRSTRING, exprStr, response);			// @ECC092806
		createXmlChild(MEETINGNOTES, bText, response);
		if (inQStr != null) createXmlChild(IQSTRING, inQStr, response);
		createXmlChild("chatColor", chatColor, response);
		createXmlChild("svrTime", (svrTime>-1)?String.valueOf(svrTime):null, response);
		createXmlChild(COUNTS, counters, flag, response);
		response.getWriter().write(XML_RESPONSE_CL);
	}
	
	/**
	 * Create an Xml with a message. This lets the recorder see the status of their
	 * or the system's actions.
	 * @param lastUpdate The time the meeting was last updated in Date.toString() format
	 * @param response
	 * @throws IOException
	 */
	private void createXmlMessage(String message, HttpServletResponse response) 
	throws IOException {
		createXml(null, null, null, null, null, null, message, null, null, null, -1, response);
	}
	
	/**
	 * Create an Xml with a &lt;url&gt; tag and a redirect url.
	 * @param url a complete url with http://
	 * @param response
	 * @throws IOException
	 */
	public static void createXmlRedirect(String alertMessage, String url, 
			HttpServletResponse response) throws IOException {
		createXml(alertMessage, url, null, null, null, null, null, null, null, null, -1, response);
	}
	
	/**
	 * Writes multiple child nodes with text limiting to VAR_LENGTH (4095) chars per node. When returned to
	 * browser javascript, each node can be contained in a var or an array of var. There is a
	 * limit in 4096 chars stored in a var in js for firefox.
	 * @param child the name of the child nodes
	 * @param text the text to store inside the child nodes
	 * @throws IOException
	 */
	public static void createXmlChild(String child, String text, 
			HttpServletResponse response) throws IOException {
		if (text != null) {
			int textLength = text.length() - 1; // Convert to index position
			int curIndex = 0;
			int endIndex = 0;
			// includes chars from index 0+
			while(curIndex <= textLength) {
				// when the text is over 4096, somehow i got a problem which might have to do
				// with stringToHTMLString() extends the string to too long.  So I subtract 100 to make it work.
				endIndex = curIndex + VAR_LENGTH-100;
				response.getWriter().write(BRACKETOPL + child + BRACKETOPR);
				if (endIndex <= textLength)
					response.getWriter().write(Util.stringToHTMLString(text.substring(curIndex, endIndex), false));
				else
					response.getWriter().write(Util.stringToHTMLString(text.substring(curIndex), false));
				response.getWriter().write(BRACKETCLL + child + BRACKETCLR);
				curIndex = endIndex;
			}
		}
	}
	
	/**
	 * Creates the variables for counters. The variables will show up as 6 individual xml tags
	 * and when the user receives it, it should be in order.
	 * @param child
	 * @param counters
	 * @param response
	 * @throws IOException
	 */
	public static void createXmlChild(String child, int[] counters, int flag, HttpServletResponse response) throws IOException {
		if(counters != null) {
			for(int i = 0; i < ARRAYSIZE; i++) {
				response.getWriter().write("\t<" + child + ">");
				response.getWriter().write(counters[i]+"");
				response.getWriter().write("</" + child + ">\n");
			}
		}
		response.getWriter().write("\t<" + child + ">");
		response.getWriter().write(flag+"");
		response.getWriter().write("</" + child + ">\n");
	}
	
	
	public static void initXml(HttpServletResponse response)
		throws IOException
	{
		response.setContentType(PrmMtgConstants.XML_CONTENT);
		response.setHeader(PrmMtgConstants.XML_CACHECONTROL, PrmMtgConstants.XML_NOCACHE);
		response.getWriter().write(PrmMtgConstants.XML_RESPONSE_OP);
		return;
	}

}
