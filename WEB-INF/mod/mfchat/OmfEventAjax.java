////////////////////////////////////////////////////
//	Copyright (c) 20067, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	OmfEventAjax.java
//	Author:	ECC
//	Date:	10/15/07
//	Description:
//		Implementation of OmfEventAjax class.
//
//	Modification:
//		@ECC013008	Support diff background images for post notes.
//		@ECC041808 support traversing back and forth between threaded notes.
//
////////////////////////////////////////////////////////////////////

package mod.mfchat;

import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.Locale;
import java.util.TimeZone;
import java.util.Vector;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import oct.codegen.chatManager;
import oct.codegen.event;
import oct.codegen.eventManager;
import oct.codegen.meetingManager;
import oct.codegen.project;
import oct.codegen.projectManager;
import oct.codegen.questManager;
import oct.codegen.req;
import oct.codegen.reqManager;
import oct.codegen.result;
import oct.codegen.resultManager;
import oct.codegen.townManager;
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
import util.PrmMtgConstants;
import util.StringUtil;
import util.Util;
import util.Util2;
import util.Util3;

/**
 * @author edwardc
 *
 */
public class OmfEventAjax extends HttpServlet
{
	static final long serialVersionUID = 1002;
	static Logger l;

	public static final String EVENT_DISPLAY_TAG	= "Events";
	public static final String EVENT_ID_TAG			= "EventId";
	public static final String EVENT_EXPR_TAG		= "Expr";
	public static final String EVENT_CHAT_TAG		= "ChatList";
	
	public static final String EVENT_ONLINE_TAG		= "OnlineXml";
	public static final String EVENT_ONLINE_STR_TAG	= "OnlineStr";

	public static final String NOTE_LABEL_TAG		= "NoteLabel";
	public static final String NOTE_STR_TAG			= "Note";

	public static final String ERROR_STR			= "Error";
	
	private static final String OP_DEFAULT			= "default";		// regular default to 4 chats on list
	private static final String OP_ALL				= "all";			// default to all
	public static final String OP_FORCE_ALL			= "0";				// force to retrieve all
	private static final String OP_FORCE_DEFAULT	= "4";				// force to retrieve regular default
	private static final int REG_DEFAULT_CHATLIST	= 4;				// regular default # on chat list
	
	private static final String NOTHING				= "<div class='plaintext_grey'>&nbsp;Nothing ...</div>";
	private static final String NO_NEW				= "no new";
	private static final String POST_NOTE_SUBJ		= "[MeetWE] Notes from ";
	private static final String HOST				= Util.getPropKey("pst", "PRM_HOST");
	private static final String MAILFILE			= "alert.htm";
	
	private static final String IMG_BULLET_TRIANGLE	= "<img src='../i/bullet_tri.gif' width='15' />";
	private static final String CLOSE_DIV_TAG		= "</div>";

	private static final String lnkS0 = "<a class='listlink' href='javascript:show_action(";
	private static final String lnkS1 = ");'>";

	private static final SimpleDateFormat df1 = new SimpleDateFormat ("h:mm a");
	private static final SimpleDateFormat df2 = new SimpleDateFormat ("MM/dd/yy (EEE) h:mm a");
	private static final SimpleDateFormat df3 = new SimpleDateFormat ("M/d");
	private static final SimpleDateFormat df4 = new SimpleDateFormat ("MM/dd/yy (EEE)");

	private static eventManager 	eMgr;
	private static meetingManager 	mMgr;
	private static userManager 		uMgr;
	private static userinfoManager	uiMgr;
	private static townManager 		tMgr;
	private static chatManager 		cMgr;
	private static resultManager 	rMgr;
	private static reqManager 		rqMgr;
	private static questManager		qMgr;
	private static projectManager	pjMgr;
	
	private static boolean bDebug = false;	// to be set by any callers to dump data (e.g. OmfChatAjax.java)
	public static void setDebug(boolean debug) {bDebug = debug;}
	
	static {
		l = PrmLog.getLog();
		
		initMgr();
	}
	
	private static void initMgr() {
		try {
			eMgr = eventManager.getInstance();
			mMgr = meetingManager.getInstance();
			uMgr = userManager.getInstance();
			uiMgr= userinfoManager.getInstance();
			tMgr = townManager.getInstance();
			cMgr = chatManager.getInstance();
			rMgr = resultManager.getInstance();
			rqMgr = reqManager.getInstance();
			qMgr = questManager.getInstance();
			pjMgr = projectManager.getInstance();

		} catch (PmpException e) {
			l.warn("Failed in OmfEventAjax.initMgr()");
		}
	}
	
	// doGet() call by Ajax from event.js and ep_circles.jsp (check who's online)
	public void doGet(HttpServletRequest request, HttpServletResponse response)
	throws ServletException, IOException
	{
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
			try {createXml(PrmMtgConstants.USERTIMEOUT, "-1", response);}
			catch (IOException e) {}
			return;
		}
		String s, msg;
		
		// get timezone from session
		//Long tz = (Long)httpSession.getAttribute("tzAdjust");
		Integer tz = (Integer)httpSession.getAttribute("timeZone");
		
		try {
			userinfo myUI = (userinfo) uiMgr.get(pstuser, String.valueOf(pstuser.getObjectId()));
			TimeZone myTimeZone = myUI.getTimeZone();
			if (!userinfo.isServerTimeZone(myTimeZone)) {
				df1.setTimeZone(myTimeZone);
				df2.setTimeZone(myTimeZone);
				df3.setTimeZone(myTimeZone);
				df4.setTimeZone(myTimeZone);
			}
		}
		catch (PmpException e) {}
		
		boolean isPDA = Prm.isPDA(request);

		// get params
		String uidS = request.getParameter("uid");
		String eidS = request.getParameter("eid");		// retrieve a post note
		long tDiff = 0;
		String label = null;
		if (bDebug) {
			System.out.println("eidS=" + eidS + ", uid=" + uidS);
		}

		if (eidS != null)
		{
			// retrieve post note by clicking PREV or NEXT
			tDiff = Long.parseLong(request.getParameter("UTCdiff"));
			try
			{
				event evt = (event)eMgr.get(pstuser, eidS);
				label = request.getParameter("label");
				String op = request.getParameter("op");			// -2=first; -1=prev; 1=next; 2=last
				int iOp = Integer.parseInt(op);
				boolean bFound = false;
				//System.out.println("iOp=" + iOp);
				
				switch (iOp)
				{
					case -1:
					case -2:
						while ((s=(String)evt.getAttribute("ParentID")[0]) != null)
						{
							bFound = true;
							eidS = s;
							if (iOp==-1) break;		// get prev: only while loop once
							evt = (event)eMgr.get(pstuser, eidS);
						}
						break;
						
					case 1:
					case 2:
						int [] ids;
						do
						{
							ids = eMgr.findId(pstuser, "ParentID='" + eidS + "'");
							if (ids.length > 0)
							{
								bFound = true;
								eidS = String.valueOf(ids[0]);
							}
							else
								break;
							if (iOp == 1) break;
						} while (true);
						break;
					
					default:
						break;
				}
				if (!bFound)
				{
					msg = "Error in OmfEventAjax.doGet() 1: get note failed (" + eidS + ")";
					l.error(msg);
					createNoteXml(null, null, response);		// no parent or no child
					return;
				}

				evt = (event)eMgr.get(pstuser, eidS);			// reload
				
				StringBuffer sBuf= new StringBuffer(2048);
				displayOneEvent(pstuser, sBuf, evt, null, null, null, 0, tDiff, false, isPDA, label, null, tz);

				createNoteXml(label, sBuf.toString(), response);
				return;
			}
			catch (PmpException e)
			{
				msg = "Error in OmfEventAjax.doGet() 2: get note failed (" + eidS + ")";
				l.error(msg);
				msg = "The note (" + eidS + ") has been removed from the database.";
				createNoteXml(ERROR_STR, msg, response);
				return;
			}
		}	// END if eidS!=null
		
		// check to see if it is ep_circles.jsp checking online users
		String onlineStr = request.getParameter("online");
		if (bDebug) System.out.println("online=" + onlineStr);
		
		if (onlineStr != null)
		{
			int beginIdx = Integer.parseInt(request.getParameter("begIdx"));
			int circleId = Integer.parseInt(request.getParameter("circle"));
			boolean isMyFriends = (circleId == 0);

			// ep_circles.jsp Ajax checking online user
			try
			{
				Vector vec;
				String newOnlineStr = null;
				String memOnlineXml = null;
				if ((vec = OmfPresence.checkOnline(pstuser, onlineStr, circleId)) != null)
				{
					// need to return new XML
					StringBuffer xmlBuf = new StringBuffer(4096);
					newOnlineStr = OmfPresence.displayMemberList(pstuser, xmlBuf,
							vec, null, beginIdx, isMyFriends, false, false);
					memOnlineXml = xmlBuf.toString();
				}
				else
					memOnlineXml = "no change";
				createOnlineXml(memOnlineXml, newOnlineStr, response);
				return;
			}
			catch (Exception e)
			{
				msg = "Error in OmfEventAjax.doGet(): ep_circles.jsp checking online user.";
				l.error(msg);
				createOnlineXml("no change", null, response);
				return;
			}
		}	// END if onlineStr!=null
		
		
		// @ECC020808 check on events: signal that i am online
		OmfPresence.setOnline(uidS);
		
		int lastId = 0;
		try
		{
			try {lastId = Integer.parseInt(request.getParameter("lastEvtId"));}
			catch (Exception e) {lastId = -1;}
			tDiff = Long.parseLong(request.getParameter("UTCdiff"));
			if (tz==null || (tz.intValue()==0 && tDiff!=0) )
			{
				// if tz is GMT (0), assume it is not set: set it based on the local machine timezone
				tz = new Integer((int)(tDiff/3600000));
				httpSession.setAttribute("timeZone", tz);
			}
		}
		catch (Exception e)
		{
			msg = "Error in OmfEventAjax.doGet(): request parameters are not initialized";
			l.error(msg);
			e.printStackTrace();
			createXml(msg, "-1", response);
			return;
		}
		
		
		String op = request.getParameter("op");
		if (bDebug) System.out.println("op=" + op);
		
		try
		{
			// check to see if there are newer events for this user
			boolean bNoEventConstruct = false;
			String evtStr = null;
			PstAbstractObject u = uMgr.get(pstuser, Integer.parseInt(uidS));
			String evtS = (String)u.getAttribute("Events")[0];
			int evtId = 0, idx;
			if (evtS != null)
			{
				if ((idx = evtS.indexOf(";")) != -1)
					evtS = evtS.substring(0, idx);
				evtId = Integer.parseInt(evtS);
			}
			else
			{
				// absolutely nothing on stack
				evtStr = NOTHING;
				evtId = 0;
				bNoEventConstruct = true;
			}
			
			if (!bNoEventConstruct && evtId<=lastId)
			{
				// no new events
				evtStr = NO_NEW;
				evtId = lastId;
				bNoEventConstruct = true;
			}
			if (bDebug) System.out.println("bNoEventConstruct=" + bNoEventConstruct);
			
			StringBuffer chatBuf = new StringBuffer();
			if (op!=null && bNoEventConstruct)
			{
				// special request of info.  Fulfill it and return
				// for retrieving chat list, op can be "default", "all", 0 or 4.  0 and 4 means need to force a retrieval
				if (!op.equals(OP_DEFAULT) && !op.equals(OP_ALL))
				{
					// force retrieval to get chat list, regardless of events
					constructChatList(pstuser, null, null, null, op, chatBuf, null);	// op is either 0 (all) or 4
					createXml(evtStr, String.valueOf(evtId), null, chatBuf.toString(), response);
					return;
				}
				else
				{
					createXml(evtStr, String.valueOf(evtId), response);
					return;
				}
			}
			if (op!=null && op.equals(OP_DEFAULT))
				op = OP_FORCE_DEFAULT;
			else
				op = OP_FORCE_ALL;	// means all

			// construct in a loop all the <DIV> to display events
			StringBuffer exprBuf = new StringBuffer();
			evtStr = constructDisplay(pstuser, u, tDiff, exprBuf, lastId, chatBuf, op, tz, isPDA);	// new event string
			// create a response XML to caller
			createXml(evtStr, String.valueOf(evtId), exprBuf.toString(), chatBuf.toString(), response);
		}
		catch (PmpException e)
		{
			l.error("Error in OmfEventAjax.doGet()");
			e.printStackTrace();
			createXml(e.toString(), "-1", response);
			return;
		}
	}	// END: doGet()
	
	//
	// createXml() calls createXmlChild() to insert XML (e.g. <Events>.....</Events>)
	//
	public static void createXml(String evtDisplayStr, String lastEvtIdS, HttpServletResponse response)
		throws IOException
	{
		createXml(evtDisplayStr, lastEvtIdS, null, null, response);
	}
	public static void createXml(
			String 				evtDisplayStr, 
			String				lastEvtIdS,
			String				exprS,
			String				chatS,
			HttpServletResponse response)
	throws IOException
	{
		initXml(response);
		PrmMtgParticipants.createXmlChild(EVENT_DISPLAY_TAG, evtDisplayStr, response);
		PrmMtgParticipants.createXmlChild(EVENT_ID_TAG, lastEvtIdS, response);
		if (exprS!=null && exprS.length()>0)
			PrmMtgParticipants.createXmlChild(EVENT_EXPR_TAG, exprS, response);
		if (chatS!=null && chatS.length()>0)
			PrmMtgParticipants.createXmlChild(EVENT_CHAT_TAG, chatS, response);
		response.getWriter().write(PrmMtgConstants.XML_RESPONSE_CL);
	}	// END: createXml()
	
	private static void initXml(HttpServletResponse response)
		throws IOException
	{
		response.setContentType(PrmMtgConstants.XML_CONTENT);
		response.setHeader(PrmMtgConstants.XML_CACHECONTROL, PrmMtgConstants.XML_NOCACHE);
		response.getWriter().write(PrmMtgConstants.XML_RESPONSE_OP);
		return;
	}
	
	private static void createOnlineXml(String memListStr, String onlineStr, HttpServletResponse response)
	throws IOException
	{
		// return online/offline users XML
		initXml(response);		
		PrmMtgParticipants.createXmlChild(EVENT_ONLINE_TAG, memListStr, response);
		if (onlineStr != null)
			PrmMtgParticipants.createXmlChild(EVENT_ONLINE_STR_TAG, onlineStr, response);
		response.getWriter().write(PrmMtgConstants.XML_RESPONSE_CL);
	}
	
	private static void createNoteXml(String labelStr, String noteStr, HttpServletResponse response)
	throws IOException
	{
		// return online/offline users XML
		initXml(response);
		if (labelStr != null)
			PrmMtgParticipants.createXmlChild(NOTE_LABEL_TAG, labelStr, response);
		if (noteStr != null)
			PrmMtgParticipants.createXmlChild(NOTE_STR_TAG, noteStr, response);
		response.getWriter().write(PrmMtgConstants.XML_RESPONSE_CL);
	}
	
	private static String constructDisplay(PstUserAbstractObject pstuser, PstAbstractObject u,
			long diff, StringBuffer exprBuf, int lastId, StringBuffer chatBuf, String reqS, Integer tz, boolean isPDA)
		throws PmpException
	{
		String evtS = (String)u.getAttribute("Events")[0];
		if (bDebug) System.out.println("constructDisplay(): evtS=" + evtS);
		
		if (evtS==null || evtS.length()<=0)
			return "";

		PstAbstractObject evt = null;
		String [] sa;
		String evIdS = "";
		sa = evtS.split(";");
		ArrayList evList = new ArrayList();
		for (int i=0; i<sa.length; i++)
		{
			try{evt = eMgr.get(pstuser, sa[i]);}
			catch (PmpException e) {continue;}
			evList.add(evt);
			evIdS += sa[i] + ";";
		}
		if (evList.isEmpty() && reqS==null) return "";

		return constructEventDisplay(pstuser, evList, diff, exprBuf, lastId, null, null, chatBuf, reqS, evIdS, tz, isPDA);

	}	// END: constructDisplay()
	
	// call here in OmsEventAjax and also by PrmThBgEvent for nightly event alert Email
	public static String constructEventDisplay(PstUserAbstractObject pstuser, ArrayList evList,
			long diff, StringBuffer exprBuf, int lastId, StringBuffer friendNameBuf, String ignoreEvtList,
			StringBuffer chatBuf, String reqS, String evIdS, Integer tz, boolean isPDA)
		throws PmpException
	{
		StringBuffer sBuf= new StringBuffer(8192);
		boolean bEmailDisplayOnly = (friendNameBuf!=null || chatBuf==null);
		if (bDebug) System.out.println("constructEventDisplay(): bEmailDisplayOnly=" + bEmailDisplayOnly);

		String s, creatorIdS, dispDate="", townIdS;
		Date evtDate;
		int iType, evId, creatorId;
		PstAbstractObject evt = null;
		int myUid = pstuser.getObjectId();
		user detailUser = (user)uMgr.get(pstuser, myUid);
		
		// set timezone
		TimeZone tzObj;
		if (tz != null)
			tzObj = TimeZone.getTimeZone("GMT" + tz.toString());
		else
			tzObj = TimeZone.getTimeZone("GMT" + userinfo.getServerTimeZone());
		Calendar cal = Calendar.getInstance(tzObj, Locale.US);
		cal.set(Calendar.HOUR_OF_DAY, 0);
		cal.set(Calendar.MINUTE, 0);
		cal.set(Calendar.SECOND, 0);
		Date today = cal.getTime();
		cal.add(Calendar.DAY_OF_MONTH, -1);
		Date yesterday = cal.getTime();
		int iDisplaying = 0;		// displaying event from today, yesterday, or even older?
		int count = 0;				// total event composed in the message
		boolean bNewChatList = false;
		boolean bFirstThought = true;	// do not display first thought for self
		
		for (int i=0; i<evList.size(); i++)
		{
			evt = (PstAbstractObject) evList.get(i);
			evId = evt.getObjectId();
			iType = Integer.parseInt((String)evt.getAttribute("Type")[0]);
			creatorIdS = (String)evt.getAttribute("Creator")[0];
			creatorId = Integer.parseInt(creatorIdS);
			townIdS = (String)evt.getAttribute("TownID")[0];

			if (ignoreEvtList != null)
			{
				// check if this event type should be ignored
				if (ignoreEvtList.indexOf((String)evt.getAttribute("Type")[0]) != -1)
					continue;				// ignore this event
			}

			if (creatorId==myUid && iType==PrmEvent.iEVT_CHAT_START		// start chat from myself
					&& townIdS==null)									// not a circle chat
			{
				if (!bNewChatList && chatBuf!=null && lastId<evId)
					bNewChatList = true;	// new chat request, refresh callers chat list
				PrmEvent.unstackEvent(pstuser, myUid, String.valueOf(evId));
				continue;					// ignore Start Chat event from me if it is not a Circle chat
			}

			if (iType==PrmEvent.iEVT_CHAT_CHANGE)
			{
				if (!bNewChatList && chatBuf!=null && lastId<evId)
					bNewChatList = true;
				PrmEvent.unstackEvent(pstuser, myUid, String.valueOf(evId));
				continue;					// ignore chat remove
			}
			
			if ( (iType==PrmEvent.iEVT_CHAT_START || iType==PrmEvent.iEVT_CHAT_JOIN || iType==PrmEvent.iEVT_CHATMTG_NEW)
				&& chatBuf!=null && lastId<evId )
			{
				bNewChatList = true;	// this is a new chat request, clients need to renew their chat list display
			}
			
			if (iType==PrmEvent.iEVT_USR_THOUGHT && !bEmailDisplayOnly
					&& creatorId==myUid && bFirstThought)
			{
				// skip displaying first thought of self
				bFirstThought = false;
				continue;
			}
			
			////////////////////////////////////////////////////////
			// add this event to the return XML

			// check for date event is created
			evtDate = (Date)evt.getAttribute("CreatedDate")[0];

			if (iDisplaying<=0 && evtDate.after(today))
			{
				iDisplaying = 1;
				sBuf.append("<div class='plaintext_blue'>Today</div>");
				sBuf.append("<img src='../i/spacer.gif' height='5' />");
			}
			else if (iDisplaying!=2 && evtDate.before(today) && evtDate.after(yesterday))
			{
				if (iDisplaying > 0) sBuf.append("<img src='../i/spacer.gif' height='20' />");
				iDisplaying = 2;
				sBuf.append("<div class='plaintext_blue'>Yesterday</div>");
				sBuf.append("<img src='../i/spacer.gif' height='5' />");
			}
			else if (evtDate.before(yesterday))
			{
				// display older events
				if (iDisplaying > 0) sBuf.append("<img src='../i/spacer.gif' height='20' />");
				iDisplaying = 3;
				s = df4.format(evtDate);
				if (!dispDate.equals(s))
				{
					dispDate = s;
					sBuf.append("<div class='plaintext_blue'>" + s + "</div>");
					sBuf.append("<img src='../i/spacer.gif' height='5' />");
				}
			}
			
			///////////////////////////////////////////////////////////////////
			// Start Event Display
			try {
			count += displayOneEvent(pstuser, sBuf, evt, chatBuf, friendNameBuf, exprBuf, lastId, diff,
					bEmailDisplayOnly, isPDA, null, evIdS, tz);
			} catch (PmpException e) {e.printStackTrace();}

		}	// END: for each event on the list
		
		if (count > 0)
			sBuf.append("<hr class='evt_hr' />");

		///////////////////////////////////////////
		// construct new chat list if necessary
		if (!bEmailDisplayOnly && chatBuf!=null && (bNewChatList || lastId<=0) )
		{
			constructChatList(pstuser, detailUser, today, yesterday, reqS, chatBuf, null);
		}	// End if construct chat list
		
		//System.out.println(sBuf.toString());
		return sBuf.toString();
		
	}	// END: constructEventDisplay()
	
	// construct displaying one event
	private static int displayOneEvent(PstUserAbstractObject pstuser, StringBuffer sBuf, PstAbstractObject evt,
			StringBuffer chatBuf, StringBuffer friendNameBuf, StringBuffer exprBuf, int lastId, 
			long diff, boolean bEmailDisplayOnly, boolean isPDA, String evtLabel, String evIdListS, Integer tz)
		throws PmpException
	{
		String s, imgSrc, cirName, creatorFname;
		int evId = evt.getObjectId();
		int iType = Integer.parseInt((String)evt.getAttribute("Type")[0]);
		String townIdS = (String)evt.getAttribute("TownID")[0];
		String parentIdS = (String)evt.getAttribute("ParentID")[0];
		Date evtDate = getDateByTimezone((Date)evt.getAttribute("CreatedDate")[0], tz);
		project pjObj;
		PstAbstractObject o;
		
		// message body: AlertMessage
		String msg = (String)evt.getAttribute("AlertMessage")[0];
		
		// ECC041808 when loading events, only display latest post notes
		int [] childIds = null;		// postnotes children
		int [] myChildIds = null;	// immediate child
		int lastChildId = 0;
		if (iType==PrmEvent.iEVT_USR_POSTNOTE)
		{
			childIds = myChildIds = eMgr.findId(pstuser, "ParentID='" + evId + "'");
			if (!bEmailDisplayOnly && chatBuf!=null && evIdListS!=null && childIds.length>0)
			{
				// check to see if I have child, if so, and if my child will be shown, ignore this
				try {
					do
					{
						lastChildId = childIds[0];
						if (evIdListS.indexOf(String.valueOf(childIds[0])) != -1)
							return 0;
						childIds = eMgr.findId(pstuser, "ParentID='" + childIds[0] + "'");
					} while (childIds.length > 0);
					
					// always display the last child: replace this event with the child event
					evId = lastChildId;
					evt = eMgr.get(pstuser, evId);
					parentIdS = (String)evt.getAttribute("ParentID")[0];
					evtDate = getDateByTimezone((Date)evt.getAttribute("CreatedDate")[0], tz);
					msg = (String)evt.getAttribute("AlertMessage")[0];
					myChildIds = new int[0];	// this variable is useless now, always empty
				} catch (PmpException e) {
					l.error("Error getting child postnote evt.");
				}
			}
		}
		else if (iType == PrmEvent.iEVT_USR_THOUGHT)
		{
			// insert the question now
			int idx = msg.indexOf(PrmEvent.QUESTION_SUB);	// "@Q_"
			idx += PrmEvent.QUESTION_SUB.length();
			String num = msg.substring(idx, msg.indexOf(" ", idx));

			parentIdS = (String)evt.getAttribute("TownID")[0];
			o = rMgr.get(pstuser, parentIdS);
			String questionTxt = o.getStringAttribute("Alert");
			if (StringUtil.isNullOrEmptyString(questionTxt)) {
				// didn't set up the question text, get it by index
				questionTxt = PrmEvent.THOUGHT_QUESTION[Integer.parseInt(num)];
			}
			if (!StringUtil.isNullOrEmptyString(questionTxt))
				questionTxt = "on <i>'" + questionTxt + "'</i>";
			msg = msg.replaceFirst(PrmEvent.QUESTION_SUB + num, questionTxt);
			
			// append all friend's responses to the original thought
			String author, commentS, timeS, picURL, lnkS, style;
			Object bTextObj;
			StringBuffer tempBuf = null;
			int [] ids = rMgr.findId(pstuser, "ParentID='" + parentIdS + "'");
			if (ids.length > 0)
			{
				tempBuf = new StringBuffer(1024);
				tempBuf.append("<table width='100%' cellpadding='0' cellspacing='0'>");
			}
			for (int i=0; i<ids.length; i++)
			{
				try {
					o = rMgr.get(pstuser, ids[i]);
					bTextObj = o.getAttribute("Comment")[0];
					commentS = (bTextObj==null) ? "" : new String((byte[])bTextObj);
					tempBuf.append("<tr ><td width='100%'><table width='100%' cellspacing='0' cellpadding='3'>");	// bgcolor='#ffffbb'
					s = (String)o.getAttribute("Creator")[0];
					user uObj = (user)uMgr.get(pstuser, Integer.parseInt(s));
					lnkS = "<a href='ep1.jsp?uid=" + s + "'>";
					author = lnkS + (String)uObj.getFullName() + "</a>";
					timeS = " at " + df1.format((Date)o.getAttribute("CreatedDate")[0]);
					picURL = Util2.getPicURL(uObj);
					
					style = Util2.getUserNoteBkgd(uObj);
					if (style.length() > 0)
						style = style.substring(0, style.length()-1) + "; padding:10px 5px 10px 5px;'";
				}
				catch (PmpException e) {continue;}
				tempBuf.append("<tr><td>" + lnkS
						+ "<img class='floatL' src='" + picURL + "' width='40' border='0'/></a></td>");
				tempBuf.append("<td width='100%'><img src='../i/spacer.gif' height='3'/><br>");
				tempBuf.append("<span class='plaintext_small'>" + author + timeS + "</span>");
				tempBuf.append("<br><img src='../i/spacer.gif' height='8'/>");
				tempBuf.append("<div class='plaintext'" + style);
				tempBuf.append(">" + commentS + "</div>");
				tempBuf.append("</td></tr></table></td></tr>");
				tempBuf.append("<tr><td><img src='../i/spacer.gif' height='3' /></td></tr>");
			}
			if (ids.length > 0)
			{
				tempBuf.append("</table>");
				msg += tempBuf.toString();
			}
		}
		else if (iType == PrmEvent.iEVT_BLG_POST && !bEmailDisplayOnly) {
			// cut long lines
			int len = msg.length();
			int sectionLen = 0;
			int i = 0;
			StringBuffer newMsg = new StringBuffer();
			while (i<len) {
				char c = msg.charAt(i++);
				if (c == ' ') {
					sectionLen = 0;
				}
				else if (sectionLen++ > 40) {
					// perform cut at certain characters
					if (c=='/' || c==':' || c==';') {
						newMsg.append(' ');
						sectionLen = 0;
					}
				}
				newMsg.append(c);
			}
			msg = newMsg.toString();
		}

		// meeting events
		String midS = (String)evt.getAttribute("MeetingID")[0];
		PstAbstractObject mObj=null, qObj=null;
		if (midS != null)
		{
			try {mObj = mMgr.get(pstuser, midS);}
			catch (PmpException e) {
				// try to see if it is a quest
				try {qObj = qMgr.get(pstuser, midS);}
				catch (PmpException ee) {}
			}	// midS can be chatId or questId
		}

		// common to all
		// check for myself as creator of message
		int myUid = pstuser.getObjectId();
		String creatorIdS = (String)evt.getAttribute("Creator")[0];
		int creatorId = Integer.parseInt(creatorIdS);
		user creator = (user)uMgr.get(pstuser, creatorId);
		if (!bEmailDisplayOnly && creatorId == myUid)
		{
			// the event creator is this user (the guy who own this Events)
			// for email: needs to retain my (the sender's) name
			//s = PrmEvent.LNK1 + ((user)pstuser).getFullName() + PrmEvent.LNK2;
			if ( (iType == PrmEvent.iEVT_CHAT_START)
				|| (townIdS!=null && (iType==PrmEvent.iEVT_INV_NEW ||iType==PrmEvent.iEVT_QST_NEW) ) )
				msg = msg.replaceFirst(" you ", " all ");	// -> invited all to ...
			s = PrmEvent.LNK1 + "(.*)" + PrmEvent.LNK2;
			msg = msg.replaceFirst(s, "you");
			msg = msg.replaceFirst("null", Prm.getAppTitle());
			if (iType == PrmEvent.iEVT_USR_POSTNOTE) {
				msg = msg.replaceFirst("note to you.", "note.");
			}
			if (!(iType>=500 && iType<=600)) {
				// non-project/task events
				msg = msg.replaceFirst("your friend ", "");
				msg = msg.replaceFirst("says", "say");
				msg = msg.replaceFirst("you has", "you have");
				msg = msg.replaceFirst("sent you", "sent out");
				msg = msg.replaceFirst("his/her", "your");
			}
		}
		else
		{
			try
			{	// return max 1 name
				if (friendNameBuf != null && friendNameBuf.length()==0)
					friendNameBuf.append(creator.getFullName());
				creatorFname = (String)creator.getAttribute("FirstName")[0];
			}
			catch (Exception e) {throw new PmpException();}	// the user is gone, ignore events from him
			
			// put javascript link to the creator
			if (!bEmailDisplayOnly)
			{
				s = lnkS0 + creatorIdS + "," + evId + ",null,\"" + creatorFname + "\"" + lnkS1;
				msg = msg.replaceFirst(PrmEvent.LNK1, s);
				msg = msg.replaceFirst(PrmEvent.LNK2, "</a>");
			}
			else
			{
				msg = msg.replaceFirst(PrmEvent.LNK1, "");
				msg = msg.replaceFirst(PrmEvent.LNK2, "");
			}
		}
		
		// partition HR line and Remove icon
		if (evtLabel == null)
			evtLabel = String.valueOf(evId);			// evtLabel is passed in for get postnote
		sBuf.append("<div id='" + evtLabel + "' style='display:block'>");		// open event display DIV
		sBuf.append("<table width='100%' cellspacing='0' cellpadding='0'><tr><td width='210' valign='top'><hr class='evt_hr' /></td>");
		if (!bEmailDisplayOnly)
		{
			sBuf.append("<td align='right' valign='bottom'><a href='javascript:remove_evt(" + evId + ");'>");
			sBuf.append("<img src='../i/icon_deleteG.gif' border='0' title='Remove'/></a></td>");
		}
		sBuf.append("</tr></table>");
		
		// display user picture for CPM only
		boolean bDisplayUserPicture = !bEmailDisplayOnly && (Prm.isPRM() || isPDA);
		boolean isNullName = Util.isNullString(creator.getFullName());
		if (bDisplayUserPicture) {
			s = " href='javascript:show_action(" + creatorIdS + "," + evId + ",null,\""
				+ (String)creator.getAttribute("FirstName")[0] + "\");'";		// href
			String picURL = Util2.getPicURL(creator);			
			sBuf.append("<table width='100%' cellspacing='0' cellpadding='0'>");
			sBuf.append("<tr><td valign='top' width='50'>");		// picture frame
			sBuf.append("<a class='listlink'" + s + "><img id='evtPic' src='" + picURL + "' width='50' border='0'/></a></td>");
			
			sBuf.append("<td class='plaintext' valign='top' width='100%'><table cellspacing='0' cellpadding='0' width='100%'>");

			boolean isOnline = OmfPresence.isOnline(creatorIdS);
			if (!isNullName) {
				if (isOnline) {
					sBuf.append("<tr><td class='online'>online&nbsp;&nbsp;</td></tr>");
				}
				else {
					// not online, show last login
					Date dt = (Date)uiMgr.get(pstuser, creatorIdS).getAttribute("LastLogin")[0];
					s = OmfPresence.getGapBetweenDates(new Date(), dt);
					sBuf.append("<tr><td class='offline'>" + s + "</td></tr>");
				}
			}
			
			// get ready to display icon, time and event type
			sBuf.append("<tr><td>");	// row for icon and event type
		}	// END: if bDisplayUserPicture
		
		// display msg, icon based on event type
		switch (iType)
		{
			case PrmEvent.iEVT_MTG_NEW:
			case PrmEvent.iEVT_INV_NEW:
			case PrmEvent.iEVT_CHATMTG_NEW:
				imgSrc = "icon_clock.jpg"; break;
			case PrmEvent.iEVT_MTG_UPDATE:
			case PrmEvent.iEVT_BLG_POST:
			case PrmEvent.iEVT_BLG_REPLY:
			case PrmEvent.iEVT_BLG_QUEST:
			case PrmEvent.iEVT_BLG_QUEST_C:
			case PrmEvent.iEVT_USR_POSTNOTE:
			case PrmEvent.iEVT_BLG_PAGE1:
			case PrmEvent.iEVT_BLG_PAGE2:
			case PrmEvent.iEVT_BLG_PAGE3:
			case PrmEvent.iEVT_BLG_COMMENT:
			case PrmEvent.iEVT_BLG_CIR:
			case PrmEvent.iEVT_BLG_PROJ:
			case PrmEvent.iEVT_BLG_PJ_C:
			case PrmEvent.iEVT_BLG_ACTN:
			case PrmEvent.iEVT_BLG_AC_C:
			case PrmEvent.iEVT_QST_NEW:
			case 601:	// post a file
				imgSrc = "icon_note.gif"; break;
			case PrmEvent.iEVT_MTG_VIEW:
			case PrmEvent.iEVT_INV_REPLY:
			case PrmEvent.iEVT_QST_REPLY:
			case 603:	// open a file
				imgSrc = "icon_eye.gif"; break;
			case PrmEvent.iEVT_MTG_DELETE:
			case PrmEvent.iEVT_RQF_REJECT:
			case 502:	// delete project
				imgSrc = "icon_garbage.gif"; break;
			case PrmEvent.iEVT_USR_SEASON:
			case PrmEvent.iEVT_REQ_FRIEND:
			case PrmEvent.iEVT_RQF_ACCEPT:
			case PrmEvent.iEVT_REQ_CIRCLE:
			case PrmEvent.iEVT_RQC_ACCEPT:
			case PrmEvent.iEVT_REQ_INTROF:
			case PrmEvent.iEVT_REQ_INTROC:
				imgSrc = "icon_face.gif"; break;
			case PrmEvent.iEVT_CHAT_START:
			case PrmEvent.iEVT_CHAT_JOIN:
			case PrmEvent.iEVT_USR_THOUGHT:
				imgSrc = "icon_chat.gif"; break;
			case PrmEvent.iEVT_CHAT_MSG:
				imgSrc = "icon_chat.gif";
				String temp = creator.getFullName() + " posted chat";
				o = cMgr.get(pstuser, midS);		// get the chat object
				s = o.getStringAttribute("ProjectID");
				if (s != null) {
					pjObj = (project) pjMgr.get(pstuser, Integer.parseInt(s));
					temp += " on " + pjObj.getDisplayName();
				}
				msg = temp + ": " + msg;
				break;
			case 501:	// project create
				imgSrc = "light_bulb.jpg"; break;
			case 504:	// project on-hold
			case 505:	// project cancel
			case 555:	// task on-hold
			case 556:	// task cancel
				imgSrc = "icon_off.gif"; break;
			case PrmEvent.iEVT_CIR_NEW:
			case PrmEvent.iEVT_CIR_JOIN:
			case PrmEvent.iEVT_CIR_ADDYOU:
			{
				imgSrc = "icon_circle.jpg";
				s = (String)evt.getAttribute("TownID")[0];
				try {
					o = tMgr.get(pstuser, Integer.parseInt(s));
					cirName = (String)o.getAttribute("Name")[0];
					msg = msg.replace(cirName, "<a href='../ep/my_page.jsp?uid=" + s + "' class='listlink'>"+cirName+"</a>");
				}
				catch (PmpException e) {l.info("Removed event " + evt.getObjectId());eMgr.delete(evt);}	// the circle might be deleted
				break;
			}
			default:
				if (iType>=500 && iType<600) {
					// all other project/task events
					imgSrc = "clipboard.jpg";
				}
				else {
					imgSrc = "icon_meeting.gif";
				}
				break;
		}
		
		String divId = creatorIdS + "-" + evtLabel;
		String evtDate2 = "";
		if (myChildIds!=null && myChildIds.length>0)
			evtDate2 = " (" + df3.format(evtDate) + ")";
		sBuf.append("<div class='plaintext' style='margin:0 0 0 3px;'>");
		sBuf.append("<img id='evtImg' src='../i/" + imgSrc + "' border='0' />&nbsp;");
		sBuf.append("<span>At " + df1.format(evtDate) + evtDate2 + "</span>&nbsp;");
		sBuf.append(msg);
		sBuf.append("</div>");
		
		if (bDisplayUserPicture) {
			sBuf.append("</td></tr>");			// close row for icon and event type
			sBuf.append("</table>");
			sBuf.append("</td></tr></table>");	// close user picture table
			sBuf.append("<div style='margin:3px 0 0 0;'></div>");
		}
		
		// allow reply to post note and add other additional links
		switch (iType)
		{
			case PrmEvent.iEVT_USR_POSTNOTE:
			{
				// the actual note content is embedded in the event msg at create (see PrmEvent.createActionEvent())
				sBuf.append("<div id='reply-" + divId + "' style='display:block'>");
				if (!bEmailDisplayOnly)
				{
					// @ECC041808 support traversing back and forth between threaded notes
					sBuf.append("<table width='100%' border='0' cellspacing='0' cellpadding='0'><tr>");
					sBuf.append("<td width='15'>" + IMG_BULLET_TRIANGLE + "</td>");
					sBuf.append("<td><a href='javascript:action(1,\"" + divId + "\");' class='listlink'>");
					sBuf.append("Reply</a></td>");

					sBuf.append("<td align='right'>");
					if (parentIdS != null)
						sBuf.append("<a href='javascript:get_note(" + evId + ", " + evtLabel + ", -2);' title='First'>");
					else
						sBuf.append("<a href='javascript:alert(\"no more notes\");'>");
					sBuf.append("<img src='../i/fastBx.gif' border='0' /></a>");

					if (parentIdS != null)
						sBuf.append("<a href='javascript:get_note(" + evId + ", " + evtLabel + ", -1);' title='Prev'>");
					else
						sBuf.append("<a href='javascript:alert(\"no more notes\");'>");
					sBuf.append("<img src='../i/prevx.gif' border='0' /></a>");
					
					sBuf.append("<img src='../i/gapx.gif' border='0' />");

					if (myChildIds.length > 0)
						sBuf.append("<a href='javascript:get_note(" + evId + ", " + evtLabel + ", 1);' title='Next'>");
					else
						sBuf.append("<a href='javascript:alert(\"no more notes\");'>");
					sBuf.append("<img src='../i/nextx.gif' border='0' /></a>");

					if (myChildIds.length > 0)
						sBuf.append("<a href='javascript:get_note(" + evId + ", " + evtLabel + ", 2);' title='Last'>");
					else
						sBuf.append("<a href='javascript:alert(\"no more notes\");'>");
					sBuf.append("<img src='../i/fastFx.gif' border='0' /></a>");

					sBuf.append("&nbsp;</td>");
					sBuf.append("</tr></table>" + CLOSE_DIV_TAG);
				}
				else
				{
					sBuf.append(IMG_BULLET_TRIANGLE);
					sBuf.append("<a href='" + HOST + "/ep/ep_home.jsp' class='listlink'>Reply</a>" + CLOSE_DIV_TAG);
				}
				break;
			}
			case PrmEvent.iEVT_CHAT_JOIN:
			case PrmEvent.iEVT_CHAT_START:
			{
				int op;
				if ((String)evt.getAttribute("TownID")[0] != null) op = 6;
				else op = 4;
				sBuf.append("<div id='chatReply-" + divId + "' style='display:block'>");
				sBuf.append(IMG_BULLET_TRIANGLE);
				if (!bEmailDisplayOnly)
				{
					sBuf.append("<a href='javascript:action(" + op + ",\"" + divId + "\"");
					if (midS != null) sBuf.append(",\"" + midS + "\"");
					sBuf.append(");' class='listlink'>");
				}
				else
				{
					sBuf.append("<a href='" + HOST + "/ep/ep_home.jsp' class='listlink'>");
				}
				sBuf.append("Go chat</a>" + CLOSE_DIV_TAG);
				break;
			}
			case PrmEvent.iEVT_INV_NEW:
			{
				sBuf.append("<div>");
				sBuf.append(IMG_BULLET_TRIANGLE);
				sBuf.append("<a href='" + HOST + "/question/q_respond.jsp?qid=" + midS + "' class='listlink'>");
				sBuf.append("RSVP</a>" + CLOSE_DIV_TAG);
				break;
			}
			case PrmEvent.iEVT_QST_NEW:
			{
				sBuf.append("<div>");
				sBuf.append(IMG_BULLET_TRIANGLE);
				sBuf.append("<a href='" + HOST + "/question/q_respond.jsp?qid=" + midS + "' class='listlink'>");
				sBuf.append("Respond</a>" + CLOSE_DIV_TAG);
				break;
			}
			case PrmEvent.iEVT_USR_SENDMSG:
			{
				imgSrc = "icon_face.gif";
				if (exprBuf!=null && lastId<evId)
				{
					// this is a new expr event, construct expr for immediate animation
					if (exprBuf.length() > 0) exprBuf.append("@");	// add delimiter
					exprBuf.append(getExpr(msg));
				}
				break;
			}
			case PrmEvent.iEVT_REQ_FRIEND:
			case PrmEvent.iEVT_REQ_CIRCLE:
			case PrmEvent.iEVT_REQ_INTROF:
			case PrmEvent.iEVT_REQ_INTROC:
			{
				sBuf.append("<div>");
				if (!bEmailDisplayOnly)
				{
					// display the option message from the req object
					PstAbstractObject rq = rqMgr.get(pstuser, townIdS);
					Object bTextObj = rq.getAttribute("Content")[0];
					if (bTextObj != null)
						sBuf.append(new String((byte[])bTextObj));
					
					String funcName;
					if (iType == PrmEvent.iEVT_REQ_FRIEND)
						funcName = "friend";
					else if (iType == PrmEvent.iEVT_REQ_CIRCLE)
						funcName = "circle";
					else if (iType == PrmEvent.iEVT_REQ_INTROF)
						funcName = "intro";
					else
						funcName = "introCir";
					
					// allow user to Accept or Reject
					sBuf.append("<span><img src='../i/spacer.gif' width='35' height='20'/></span>");
					sBuf.append("<span align='center'>");
					sBuf.append("<input type='button' class='button_small' value='ACCEPT' onclick='accept_" + funcName + "(" + evId + ");'>");
					sBuf.append("<img src='../i/spacer.gif' width='15' />");
					sBuf.append("<input type='button' class='button_small' value='REJECT' onclick='reject_" + funcName + "(" + evId + ");'>");
					sBuf.append("</span>" + CLOSE_DIV_TAG);
				}
				else
				{
					sBuf.append(IMG_BULLET_TRIANGLE);
					sBuf.append("<a href='" + HOST + "/ep/ep_home.jsp' class='listlink'>Accept</a>" + CLOSE_DIV_TAG);
				}
				break;
			}
			case PrmEvent.iEVT_USR_THOUGHT:
			{
				// display all respond comments (children blog)
				sBuf.append("<div id='comment-" + divId + "' style='display:block'>");
				sBuf.append("<table width='100%' border='0' cellspacing='0' cellpadding='5'><tr>");
				sBuf.append("<td bgcolor='#ffffbb'>"
						+ "<textarea id='commTh_" + divId + "' name='commTh_" + divId + "' "
						+ "onFocus='enterDesc(1, \"commTh_" + divId + "\");' "
						+ "onBlur='leftDesc(1, \"commTh_" + divId + "\");' "
						+ "onKeyUp='checkKey(this, event, " + evt.getAttribute("TownID")[0] + ");' "
						+ "class='comment' cols='40' rows='1' maxlength='250'>");
				sBuf.append(PrmEvent.DEFAULT_COMMENT_STR + "</textarea></td>");
				sBuf.append("</tr></table>" + CLOSE_DIV_TAG);
				break;
			}
			
			default:
				break;
		}
		
		// display more meeting details
		if (mObj!=null || qObj!=null) {
			// display the meeting/quest info (subject and date/time) and link
			if (mObj != null)
				Util2.displayMeetingLink(pstuser, mObj, sBuf);
			else
				Util2.displayQuestLink(pstuser, qObj, sBuf);
		}
		
		sBuf.append("<img src='../i/spacer.gif' height='3' />");
		
		// div for show actions
		sBuf.append("<div id='" + divId + "' class='plaintext' style='display:none;'></div>");
		
		sBuf.append("</div>");				// close the event display DIV
		return 1;							// return one more event
	}	// END: displayOneEvent()
	
	// adjust timezone
	private static Date getDateByTimezone(Date dt, Integer tz) {		
		if (tz != null)
		{
			long t = tz.intValue();	//(tz.intValue() - userinfo.getServerUTCdiff());
			dt = new Date(dt.getTime() + t);
		}
		return dt;
	}

	public static void constructChatList(PstUserAbstractObject pstuser, user detailUser,
			Date today, Date yesterday, String reqS, StringBuffer chatBuf, int [] chatIds)
		throws PmpException
	{
		PstAbstractObject cObj;
		Date dt;
		int cid=0;
		String s;
		int myUid = pstuser.getObjectId();
		
		System.out.println("constructChatList(): reqS=" + reqS);
		if (today == null)
		{
			Calendar cal = Calendar.getInstance();
			cal.set(Calendar.HOUR_OF_DAY, 0);
			cal.set(Calendar.MINUTE, 0);
			cal.set(Calendar.SECOND, 0);
			today = cal.getTime();
			cal.add(Calendar.DAY_OF_MONTH, -1);
			yesterday = cal.getTime();
		}
		if (detailUser == null)
			detailUser = (user)uMgr.get(pstuser, myUid);
		
		String myFullName = detailUser.getFullName();
		int [] ids;
		if (chatIds == null) {
			ids = cMgr.findId(pstuser, "Attendee='" + myUid + "'");
			
			// also include the project chat (ECC: should do this for circle chat too?)
			int [] ids1 = pjMgr.getProjects(detailUser, false);
			for (int i=0; i<ids1.length; i++) {
				int [] ids2 = cMgr.findId(pstuser, "ProjectID='" + ids1[i] + "'");
				ids = Util2.mergeIntArray(ids, ids2);
			}
		}
		else
		{
			ids = chatIds;					// caller passes in the chats to be included on the list
			chatBuf.append("<div class='inst'>Click to choose from the following chats:</div>");
		}
		
		PstAbstractObject [] oArr = cMgr.get(pstuser, ids);
		Util.sortDate(oArr, "LastUpdatedDate", true);
		
		chatBuf.append("<table width='100%' border='0' cellspacing='0' cellpadding='0'><tr><td>");
		int len = oArr.length;
		if (len>REG_DEFAULT_CHATLIST && reqS!=null && reqS.equals(OP_FORCE_DEFAULT))
				len = REG_DEFAULT_CHATLIST;

		for (int i=0; i<len; i++)
		{
			cObj = oArr[i];
			try
			{
				cid = cObj.getObjectId();
				s = (String)cObj.getAttribute("Name")[0];
				if (s.startsWith("@"))
				{
					// i am using default chat name
					s = s.substring(1);		// don't display the @
					s = s.replaceFirst(", " + myFullName, "");
					s = s.replaceFirst(myFullName + ", ", "");
				}
				chatBuf.append("<div id='chat-" + cid + "'>");
				chatBuf.append("<table width='100%' border='0' cellspacing='0' cellpadding='0'>");
				chatBuf.append("<tr><td valign='top' width='30' class='plaintext'><img src='../i/icon_chat.gif' /></td>");
				chatBuf.append("<td align='left' width='180'><a id='chatName-" + cid + "' href='javascript:action(8,null," + cid + ");' class='listlink'>"
						+ s + "</a></td>");
				chatBuf.append("<td width='50' valign='top' align='right'>");
				chatBuf.append("<a href='javascript:rename_chat(" + cid + ")' class='listlink'><img src='../i/icon_pen.gif' border='0' title='Rename' /></a>&nbsp;&nbsp;");
				chatBuf.append("<a href='javascript:remove_chat(" + cid + ")' class='listlink'><img src='../i/icon_delete.gif' border='0' title='Remove' /></a>");
				chatBuf.append("</td></tr>");
				chatBuf.append("<tr><td colspan='3' class='plaintext_small'><img src='../i/spacer.gif' width='35' height='1'/>");
				chatBuf.append("Last chat: ");
				dt = (Date)cObj.getAttribute("LastUpdatedDate")[0];
				if (dt.after(today))
					chatBuf.append("today at " + df1.format(dt));
				else if (dt.before(today) && dt.after(yesterday))
					chatBuf.append("yesterday at " + df1.format(dt));
				else
					chatBuf.append(df2.format(dt));
				chatBuf.append("</td></tr></table></div>");
			}
			catch (Exception e) {
				// ECC: do some clean up code
				l.error("remove corrupted chat record ["+ cid + "] - " + e.getMessage());
				cMgr.delete(cObj);
			}
		}
		chatBuf.append("</td></tr>");
		if (reqS==null || reqS.equals(OP_FORCE_DEFAULT))
		{
			if (oArr.length > REG_DEFAULT_CHATLIST)
			{
				chatBuf.append("<tr><td><img src='../i/spacer.gif' height='5' /></td></tr>");
				chatBuf.append("<tr><td align='right'><a class='listlink' href='javascript:action(9);'>... show all (" + oArr.length + ") chats</td></tr>");
			}
		}
		else if (oArr.length > REG_DEFAULT_CHATLIST)
		{
			chatBuf.append("<tr><td><img src='../i/spacer.gif' height='5' /></td></tr>");
			chatBuf.append("<tr><td align='right'><a class='listlink' href='javascript:action(10);'>&gt; show most recent chats only</td></tr>");
		}
		else if (chatIds != null)
		{
			chatBuf.append("<tr><td><img src='../i/spacer.gif' height='5' /></td></tr>");
			chatBuf.append("<tr><td align='right'><a class='listlink' href='javascript:action(9);'>... show all of my chats</td></tr>");
		}
		chatBuf.append("</table>");
		return;
	}	// END: constructChatList()
	
	private static String getExpr(String msg)
	{
		int idx1 = msg.indexOf("showExpr");		// the str is sendExpr("hello:Edward Cheng")
		if (idx1 == -1) return "";
		idx1 = msg.indexOf('"', idx1) + 1;		// add 1 to skip "
		int idx2 = msg.indexOf('"', idx1);
		return msg.substring(idx1, idx2);
	}
	
	/*
	 * ************************************************************************************************
	 */

	public void doPost(HttpServletRequest request, HttpServletResponse response) 
	//throws ServletException, IOException
	{
		// post note, send turkey or change motto
		// the target can be individual, circle/friend, or search result
		// Get the current session and pstuser
		try
		{
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
		// get timezone from session
		//Long tz = (Long)httpSession.getAttribute("tzAdjust");
		Integer tz = (Integer)httpSession.getAttribute("timeZone");
		
		boolean isPDA = Prm.isPDA(request);

		String s;
		PstAbstractObject o, reqObj;
		event evt = null;
		String myUidS = String.valueOf(pstuser.getObjectId());

		// targetUidS can be just evId, or userId-EvId (reply note)
		String targetUidS = request.getParameter("uid");	// this would be the evId in case of remove event
		String actionType = request.getParameter("type");
		String notes = request.getParameter("note");
		String motto = request.getParameter("motto");		// no event trigger, simply save the new motto
		String backPage = request.getParameter("backPage");
		String thing = request.getParameter("thing");
		String thingFileName = null;
		String noteBkgd = null;

		l.info("OmfEventAjax.doPost() actionType = " + actionType);
		if (actionType == null)
		{
			if (thing != null)
			{
				thingFileName = request.getParameter("thingFile");
				actionType = PrmEvent.ACT_SEASONAL;
			}
			else if (notes != null)
			{
				actionType = PrmEvent.ACT_POSTNOTE;
				noteBkgd = Util2.getUserPreference(pstuser, "NoteBackground");
			}
			else if (motto != null)
				actionType = PrmEvent.ACT_CHANGE_MOTTO;
		}
		else if (actionType.equals("removeEvent"))
		{
			// this removing event from ep_home.jsp (don't touch assoc blog)
			// just unstack the target event and return
			try {PrmEvent.unstackEvent(pstuser, pstuser.getObjectId(), targetUidS);}
			catch (PmpException e) {e.printStackTrace();}		// just ignore
			return;
		}
		else if (actionType.equals("acceptFriend") || actionType.equals("acceptIntro"))
		{
			// construct bi-directional friendship and remove event and request
			try
			{
				String s1, s2;
				evt = (event)eMgr.get(pstuser, targetUidS);	// targetUidS is the evId
				reqObj = rqMgr.get(pstuser, (String)evt.getAttribute("TownID")[0]);	// TownID stores reqID

				s1 = (String)reqObj.getAttribute("Creator")[0];
				o = uMgr.get(pstuser, Integer.parseInt(s1));

				String evtS, initiatorName=null;
				if (actionType.equals("acceptFriend"))
				{
					evtS = PrmEvent.EVT_RQF_ACCEPT;
				}
				else
				{
					evtS = PrmEvent.EVT_RQI_ACCEPT;
					initiatorName = ((user)o).getFullName();			// remember the creator of the req
					s1 = (String)evt.getAttribute("AlertMessage")[0];
					int idx1 = s1.indexOf("uid=");
					if (idx1 == -1)
						throw new PmpException("corrupted event [" + targetUidS + "] AlertMessage.");
					int idx2 = s1.indexOf("'", idx1);
					s1 = s1.substring(idx1+4, idx2);
					o = uMgr.get(pstuser, Integer.parseInt(s1));
				}

				s2 = (String)reqObj.getAttribute("Owner")[0];
				o.appendAttribute("TeamMembers", new Integer(s2));
				uMgr.commit(o);
				o = uMgr.get(pstuser, Integer.parseInt(s2));
				o.appendAttribute("TeamMembers", new Integer(s1));
				uMgr.commit(o);
				
				// send a notification event to the requester
				event newEvt = PrmEvent.createTriggerEventDirect(pstuser, evtS, Integer.parseInt(s1));
				if (actionType.equals("acceptIntro"))
					PrmEvent.setValueToVar(newEvt, "var1", initiatorName);
				
				// remove the event and the request
				rqMgr.delete(reqObj);
				eMgr.delete(evt);
				
				l.info("OmfEventAjax constructed friendship between [" + s1 + ", " + s2 + "]");
			}
			catch (PmpException e) {e.printStackTrace();}
			return;
		}
		else if (actionType.equals("rejectFriend"))
		{
			// rejected friend request
			try
			{
				// send a notification event to the requester
				evt = (event)eMgr.get(pstuser, targetUidS);
				reqObj = rqMgr.get(pstuser, (String)evt.getAttribute("TownID")[0]);
				s = (String)reqObj.getAttribute("Creator")[0];
				
				PrmEvent.createTriggerEventDirect(pstuser, PrmEvent.EVT_RQF_REJECT, Integer.parseInt(s));

				// remove the event and the request
				rqMgr.delete(reqObj);
				eMgr.delete(evt);
				
				l.info("OmfEventAjax rejected friend request from [" + s + "]");
			}
			catch (PmpException e) {e.printStackTrace();}
			return;
		}
		else if (actionType.equals("acceptCircle"))
		{
			// add circle membership and remove event and request
			try
			{
				evt = (event)eMgr.get(pstuser, targetUidS);
				reqObj = rqMgr.get(pstuser, (String)evt.getAttribute("TownID")[0]);	// TownID stores reqID
				String userIdS = (String)reqObj.getAttribute("Creator")[0];	// this is the guy requesting membership
				String townIdS = (String)reqObj.getAttribute("TownID")[0];
				acceptToCircle(pstuser, userIdS, townIdS);
				
				// remove the event and the request
				rqMgr.delete(reqObj);
				eMgr.delete(evt);
			}
			catch (PmpException e) {e.printStackTrace();}
			return;
		}
		else if (actionType.equals("rejectCircle"))
		{
			// rejected circle request
			try
			{
				// send a notification event to the requester
				evt = (event)eMgr.get(pstuser, targetUidS);
				reqObj = rqMgr.get(pstuser, (String)evt.getAttribute("TownID")[0]);
				s = (String)reqObj.getAttribute("Creator")[0];
				
				PrmEvent.createTriggerEventDirect(pstuser, PrmEvent.EVT_RQF_REJECT, Integer.parseInt(s),
						(String)reqObj.getAttribute("TownID")[0]);

				// remove the event and the request
				rqMgr.delete(reqObj);
				eMgr.delete(evt);
				
				l.info("OmfEventAjax rejected join circle request from [" + s + "]");
			}
			catch (PmpException e) {e.printStackTrace();}
			return;
		}
		else if (actionType.equals("acceptIntroCir"))
		{
			// someone recommend a circle to me: I accept means to trigger request to join circle, reject is just ignore
			// trigger a request to join circle event
			try
			{
				evt = (event)eMgr.get(pstuser, targetUidS);
				reqObj = rqMgr.get(pstuser, (String)evt.getAttribute("TownID")[0]);
				s = (String)reqObj.getAttribute("Creator")[0];		// initial request owner ID
				o = uMgr.get(pstuser, Integer.parseInt(s));
				String initiator = "<a href='ep1.jsp?uid=" + s + "'>" + ((user)o).getFullName() + "</a>";
				String circleIdS = (String)reqObj.getAttribute("TownID")[0];
				o = tMgr.get(pstuser, Integer.parseInt(circleIdS));
				
				// if the initiator is the Chief of the circle, then simply accepts the guy to be a member
				if (s.equals(o.getAttribute("Chief")[0]))
				{
					acceptToCircle(pstuser, String.valueOf(pstuser.getObjectId()),
							circleIdS);
				}
				else
				{
					// otherwise trigger a request to join the circle
					String circleName = (String)o.getAttribute("Name")[0];
					String optMsg =  initiator + " recommends me to join " + circleName + ".  Please approve.";
					Util3.sendRequest(pstuser, null, req.REQ_CIRCLE, optMsg, null, circleIdS);
				}

				// remove the event and the request
				rqMgr.delete(reqObj);
				eMgr.delete(evt);
			}
			catch (PmpException e) {e.printStackTrace();}
			return;
		}
		/*else
		{
			l.error("Unsupported action event posted to OmfEventAjax (" + actionType + ").");
			return;							// not supported operation request
		}*/
		
		boolean bEmail = false;				// send a notification email now?
		s = request.getParameter("email");
		if (s!=null && s.equals("true"))
			bEmail = true;
		
		// note that the uid can be simple uid (12345), or uid-eid (12345-33345) or circleId (55566)
		String parentIdS = null;			// for reply note, in uid-eid, eid is the parentId
		int [] ids;
		int idx;
		if ((idx = targetUidS.indexOf('-')) != -1)
		{
			parentIdS  = targetUidS.substring(idx+1);
			try {
				o = eMgr.get(pstuser, parentIdS);
				// make sure the call is really coming from Reply of a postnote
				if (o.getAttribute("Type")[0].equals(PrmEvent.EVT_USR_POSTNOTE))
				{
					do
					{	// get the last postnote as my parent (attached to the end)
						ids = eMgr.findId(pstuser, "ParentID='" + parentIdS + "'");
						if (ids.length > 0)
							parentIdS = String.valueOf(ids[0]);
						else
							break;
					} while (true);
				}
				else
					parentIdS = null;
			}
			catch (PmpException e) {}
			targetUidS = targetUidS.substring(0, idx);
		}
		int targetUid = Integer.parseInt(targetUidS);		// can be uid or circleId
		
		user u;
		Object [] emailArr = null;
		PstAbstractObject bObj = null;	
		try
		{
			if (actionType.equals(PrmEvent.ACT_HELLO))
			{
				// stack the new event to the target user
				if (targetUid == 999)
					ids = (int [])httpSession.getAttribute("searchArr");
				else
				{
					ids = new int[1];
					ids[0] = targetUid;
				}
				for (int i=0; i<ids.length; i++)
				{
					//System.out.println("hello to [" + ids[i] + "]");					
	        		s = "TownID='" + ids[i] + "'"
	 					+ " && Type='" + PrmEvent.EVT_USR_SENDMSG + "'"
						+ " && AlertMessage='%" + PrmEvent.ACT_HELLO + "%'"
						+ " && Creator='" + pstuser.getObjectId() + "'";
	        		PrmEvent.checkCleanMaxEvent(pstuser, s, 0);			// remove all old same event
					evt = PrmEvent.createActionEvent(pstuser, PrmEvent.EVT_USR_SENDMSG, PrmEvent.ACT_HELLO, null, null);
					evt.setAttribute("TownID", String.valueOf(ids[i]));	// store the target user or town id
					eMgr.commit(evt);
				}
			}
			else if (actionType.equals(PrmEvent.ACT_POSTNOTE))
			{
				// user post a note to either another user or friend/circle
				notes = notes.replaceAll("\n", "<br>");
				evt = PrmEvent.createActionEvent(pstuser, PrmEvent.EVT_USR_POSTNOTE, notes, noteBkgd, parentIdS);
				bObj = resultManager.createBlog(pstuser, result.TYPE_NOTE_BLOG, targetUidS,
						String.valueOf(evt.getObjectId()), (String)evt.getAttribute("AlertMessage")[0]);
			}
			else if (actionType.equals(PrmEvent.ACT_SEASONAL))
			{
				// user send a thing (e.g. turkey) to either another user or friend/circle
				evt = PrmEvent.createActionEvent(pstuser, PrmEvent.EVT_USR_SEASON, notes, thing, thingFileName);
			}
			else if (actionType.equals(PrmEvent.ACT_CHANGE_MOTTO))
			{
				// simply save the motto to the user object
				pstuser.setAttribute("Motto", motto);
				uMgr.commit(pstuser);
				return;
			}
			else if (actionType.equals(PrmEvent.ACT_DELTNOTE))
			{
				// remove the blog and the note
				// since others might still reference to it, i can only set up a block list
				// the blog will actually be recycle in a few days by backgd process
				o = rMgr.get(pstuser, targetUidS);				// targetUidS is the blog id

				// block this blog from me
				o.appendAttribute("Block", myUidS);
				rMgr.commit(o);

				s = (String)o.getAttribute("TaskID")[0];		// id of the event associated to this blog
				if (s != null)	// s is the TaskID = event id
					PrmEvent.unstackEvent(pstuser, pstuser.getObjectId(), s);		// unstack this event if I have it
				if (backPage != null)
					response.sendRedirect(backPage);
				return;
			}
			
			if (evt == null)
				return;			// either event is turned off or i am admin
			
			// create email message if needed
			String msg="", subj="";
			if (bEmail)
			{
				ArrayList evList = new ArrayList();
				evList.add(evt);
				msg = constructEventDisplay(pstuser, evList, 0, null, 0, null, null, null, null, null, tz, isPDA);

				msg = msg.trim();
				if (msg.length() > 0)
				{
					msg = msg.replaceAll("\\.\\./", HOST+"/");	// switch host name			
					//msg = msg.replaceAll("(<[A|a][^>]*>)|(</[A|a]>)", "");	// remove all <A> tags
					if ((idx = msg.indexOf(IMG_BULLET_TRIANGLE)) != -1)
					{
						idx += IMG_BULLET_TRIANGLE.length();
						msg = msg.substring(0, idx) + "<a href='" + HOST + "/ep/ep_home.jsp' class='listlink'>"
							+ msg.substring(idx, idx+5) + "</a>" + msg.substring(idx+5);
					}
					msg = "<table><tr><td width='20'>&nbsp;</td><td><table><tr><td id='Events' class='plaintext'>"
						+ msg + "</td></tr></table></td></tr></table>";
					//msg = msg.replaceAll("../i/", HOST+"/i/");				// finally, switch host name
					subj = POST_NOTE_SUBJ + ((user)pstuser).getFullName();
				}
			}
				
			// the event is created.  Now stack the event to user, friends or circle.
			try
			{
				if (targetUid==0 || targetUid==999) throw new PmpException();
				
				u = (user)uMgr.get(pstuser, targetUid);
				PrmEvent.stackEvent(u, evt);	// stack the event to target user
				l.info("Action event [" + actionType + "] triggered to user [" + targetUid + "]");
				
				// create blog for user
				
				// send Email to the target user
				if (bEmail)
				{
					emailArr = new Object[1];
					emailArr[0] = u.getAttribute("Email")[0];
				}
			}
			catch (PmpException e)
			{
				// failed to get user
				// now this is either circle/friends or search result
				s = (String)evt.getAttribute("AlertMessage")[0];
				
				// first check to see if we are in a search display, then
				// try to see if the targetUid is a circleId (townId) or myfriends
				if (targetUid == 999)
				{
					// we are in a search display
					// fix attendees in blog object
					ids = (int [])httpSession.getAttribute("searchArr");
					if (bObj != null)
					{
						bObj.setAttribute("Attendee", null);	// remove the townId or "0"
						for (int i=0; i<ids.length; i++)
							bObj.appendAttribute("Attendee", String.valueOf(ids[i]));
						rMgr.commit(bObj);
					}
				}
				else if (targetUid == 0)
				{
					// my friends
					int iRole = ((Integer)httpSession.getAttribute("role")).intValue();
					if ((iRole & user.iROLE_ADMIN) > 0)
					{
						// i am admin, send to all user
						ids = uMgr.findId(pstuser, "om_acctname='%'");
						s = s.replaceFirst("(.)*"+PrmEvent.LNK2, "<font color='#ee0000'><b>MeetWE Admin</b></font>");
						s = s.replaceFirst("to you", "to all");
					}
					else
					{
						ids = Util2.toIntArray(pstuser.getAttribute("TeamMembers"));
						s = s.replaceFirst("to you", "to friends");
					}
					
					// fix attendees in blog object if it is friends (circle is ok to just store townId)
					if (bObj != null)
					{
						bObj.setAttribute("Attendee", null);	// remove the "0"
						for (int i=0; i<ids.length; i++)
							bObj.appendAttribute("Attendee", String.valueOf(ids[i]));
						rMgr.commit(bObj);
					}
				}
				else
				{
					// try to see if it is a town (circle)
					PstAbstractObject tn = tMgr.get(pstuser, targetUid);	// will cause exception if it is not a town
					ids = uMgr.findId(pstuser, "Towns=" + targetUid);
					String tnName = (String)tn.getAttribute("Name")[0];
					s = s.replaceFirst("to you", "to " + tnName);
					s = s.replaceFirst("sent you ", "sent " + tnName + " ");
				}
				evt.setAttribute("AlertMessage", s);
				eMgr.commit(evt);
				if (bEmail) emailArr = new Object[ids.length];
				for (int i=0; i<ids.length; i++)
				{
					u = (user)uMgr.get(pstuser, ids[i]);
					PrmEvent.stackEvent(u, evt);	// stack the event to target user
					if (bEmail) emailArr[i] = u.getAttribute("Email")[0];
				}
				l.info("Action event [" + actionType + "] triggered to circle/friend/search [" + targetUid + "]");
			}	// END: catch (PmpException) - not a single user, probably for circle/friend
			
			if (bEmail)
			{
				s = (String)pstuser.getAttribute("Email")[0];
				if (!Util.sendMailAsyn(s, emailArr, null, null, subj, msg, MAILFILE))
					l.error("!!! Error sending OMF Post Note notification from user [" + pstuser.getObjectId() + "]");
			}
		}	// END: try
		catch (PmpException e)
		{
			l.error("Error in OmfEventAjax.doPost()");
			e.printStackTrace();
			return;
		}
		if (backPage != null)
			response.sendRedirect(backPage);
		}
		catch (Exception e)
		{
			l.error("Got exception in OmfEventAjax.doPost()");
			e.printStackTrace();
			return;
		}
	}	//END: doPost()

	// process the event to accept the request to join circle
	private void acceptToCircle(PstUserAbstractObject u, String userIdS, String cirIdS) throws NumberFormatException, PmpException
	{
		PstAbstractObject requester = uMgr.get(u, Integer.parseInt(userIdS));
		requester.appendAttribute("Towns", new Integer(cirIdS));
		uMgr.commit(requester);
		
		// send a notification event to the requester
		PrmEvent.createTriggerEventDirect(u, PrmEvent.EVT_RQC_ACCEPT, requester.getObjectId(), cirIdS);
		
		// send event to all circle members about the new member
		PrmEvent.createTriggerEvent((PstUserAbstractObject)requester, PrmEvent.EVT_CIR_JOIN, null, cirIdS, null);
		
		l.info("OmfEventAjax approved membership for [" + userIdS + "] to join [" + cirIdS + "]");	}

}	// END: OmfEventAjax class
