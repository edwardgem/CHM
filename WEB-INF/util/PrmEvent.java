////////////////////////////////////////////////////
//	Copyright (c) 2007, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	PrmEvent.java
//	Author:	ECC
//	Date:	10/18/07
//	Description:
//		Implementation of PrmEvent class.
//		To trigger an event, basically 2 steps.  First create the event, then stack the event to
//		relevant users.
//
//		The top public method is createTriggerEvent(pstuser, evtTypeIdS, midS, townIdS, expireDate)
//		The var1,2,3 are specified in the message itself which is in bringup.properties.
//		Their values will be filled in trigger() based on the event type.
//		Alternatively user can create() the event himself, setValueToVar(), then stackEvent().
//
//		OmfEventAjax.java is responsible for constructing the actual event display/email.
//
//	Modification:
//
//
////////////////////////////////////////////////////////////////////

package util;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;

import javax.ws.rs.core.MultivaluedMap;

import oct.codegen.answerManager;
import oct.codegen.attachment;
import oct.codegen.attachmentManager;
import oct.codegen.bug;
import oct.codegen.bugManager;
import oct.codegen.chat;
import oct.codegen.chatManager;
import oct.codegen.event;
import oct.codegen.eventManager;
import oct.codegen.meeting;
import oct.codegen.meetingManager;
import oct.codegen.project;
import oct.codegen.projectManager;
import oct.codegen.quest;
import oct.codegen.questManager;
import oct.codegen.resultManager;
import oct.codegen.task;
import oct.codegen.taskManager;
import oct.codegen.townManager;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.codegen.userinfoManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstGuest;
import oct.pst.PstUserAbstractObject;

import org.apache.log4j.Logger;

import com.sun.jersey.api.client.Client;
import com.sun.jersey.api.client.ClientResponse;
import com.sun.jersey.api.client.WebResource;
import com.sun.jersey.core.util.MultivaluedMapImpl;

/**
 * @author ECC
 *
 */
public class PrmEvent {
	
	// public
	public static final String LNK1				= "@L1:";	// opening mark to insert link at ep_home.jsp
	public static final String LNK2				= ":@L2";	// closing mark to insert link at ep_home.jsp
	
	public static final String QUESTION_SUB		= "@Q_";	// my thought question no. "@Q_3"
	
	public static final int EVENT_STACK_SIZE	= 30;	// event no. to be kept for each user

	// this list is incomplete; the complete list is in event.csv
	public static final String EVT_MTG_NEW		= "101";
	public static final int	  iEVT_MTG_NEW		= 101;
	public static final String EVT_MTG_START	= "102";
	public static final int	  iEVT_MTG_START	= 102;
	public static final String EVT_MTG_JOIN		= "103";
	public static final int	  iEVT_MTG_JOIN		= 103;
	public static final String EVT_MTG_DONE		= "104";
	public static final int	  iEVT_MTG_DONE		= 104;
	public static final String EVT_MTG_UPDATE	= "105";
	public static final int	  iEVT_MTG_UPDATE	= 105;
	public static final String EVT_MTG_VIEW		= "106";
	public static final int	  iEVT_MTG_VIEW		= 106;
	public static final String EVT_MTG_DELETE	= "107";
	public static final int	  iEVT_MTG_DELETE	= 107;
	public static final String EVT_CHATMTG_NEW	= "108";
	public static final int	  iEVT_CHATMTG_NEW	= 108;

	public static final String EVT_BLG_POST		= "111";		// post blog on meeting
	public static final int	  iEVT_BLG_POST		= 111;
	public static final String EVT_BLG_REPLY	= "112";
	public static final int	  iEVT_BLG_REPLY	= 112;
	public static final String EVT_BLG_PAGE1	= "113";		// post on your page
	public static final int	  iEVT_BLG_PAGE1	= 113;
	public static final String EVT_BLG_PAGE2	= "114";		// post on someone's page
	public static final int	  iEVT_BLG_PAGE2	= 114;
	public static final String EVT_BLG_COMMENT	= "115";
	public static final int	  iEVT_BLG_COMMENT	= 115;
	public static final String EVT_BLG_CIR		= "116";
	public static final int	  iEVT_BLG_CIR		= 116;
	public static final String EVT_BLG_PAGE3	= "117";		// post on his/her own page
	public static final int	  iEVT_BLG_PAGE3	= 117;
	public static final String EVT_BLG_PROJ		= "118";		// post on circle project/task
	public static final int	  iEVT_BLG_PROJ		= 118;
	public static final String EVT_BLG_PJ_C		= "119";		// responded to circle proj/task blog
	public static final int	  iEVT_BLG_PJ_C		= 119;
	public static final String EVT_BLG_BUG		= "120";		// post on bug
	public static final int	  iEVT_BLG_BUG		= 120;
	public static final String EVT_BLG_BUG_C	= "121";		// responded to bug blog
	public static final int	  iEVT_BLG_BUG_C	= 121;
	
	public static final String EVT_BLG_QUEST	= "1111";		// post blog on quest
	public static final int	  iEVT_BLG_QUEST	= 1111;
	public static final String EVT_BLG_QUEST_C	= "1112";
	public static final int	  iEVT_BLG_QUEST_C	= 1112;
	// action item blog
	public static final String EVT_BLG_ACTN		= "1113";		// post blog on action item
	public static final int	  iEVT_BLG_ACTN		= 1113;
	public static final String EVT_BLG_AC_C		= "1114";		// post response to blog
	public static final int	  iEVT_BLG_AC_C		= 1114;

	public static final String EVT_USR_LOGIN	= "141";
	public static final int	  iEVT_USR_LOGIN	= 141;
	public static final String EVT_USR_LOGOUT	= "142";
	public static final int	  iEVT_USR_LOGOUT	= 142;
	
	public static final String EVT_USR_POSTNOTE	= "151";
	public static final int	  iEVT_USR_POSTNOTE	= 151;
	public static final String EVT_USR_SENDMSG	= "152";
	public static final int	  iEVT_USR_SENDMSG	= 152;
	
	public static final String EVT_USR_THOUGHT	= "161";
	public static final int	  iEVT_USR_THOUGHT	= 161;
	public static final String EVT_USR_TH_COMMENT	= "162";
	public static final int	  iEVT_USR_TH_COMMENT	= 162;

	public static final String EVT_USR_SEASON	= "171";
	public static final int	  iEVT_USR_SEASON	= 171;

	public static final String EVT_CHAT_JOIN	= "181";
	public static final int	  iEVT_CHAT_JOIN	= 181;
	public static final String EVT_CHAT_START	= "182";
	public static final int	  iEVT_CHAT_START	= 182;
	public static final String EVT_CHAT_CHANGE	= "183";	// internal event
	public static final int	  iEVT_CHAT_CHANGE	= 183;
	public static final String EVT_CHAT_MSG		= "184";	// submitted a chat text message
	public static final int	  iEVT_CHAT_MSG		= 184;
	
	public static final String EVT_INV_NEW		= "191";
	public static final int	  iEVT_INV_NEW		= 191;
	public static final String EVT_QST_NEW		= "192";
	public static final int	  iEVT_QST_NEW		= 192;
	public static final String EVT_INV_REPLY	= "193";
	public static final int	  iEVT_INV_REPLY	= 193;
	public static final String EVT_QST_REPLY	= "194";
	public static final int	  iEVT_QST_REPLY	= 194;

	public static final String EVT_REQ_FRIEND	= "201";	// request to be friend
	public static final int	  iEVT_REQ_FRIEND	= 201;
	public static final String EVT_RQF_ACCEPT	= "202";	// accept friend req
	public static final int	  iEVT_RQF_ACCEPT	= 202;
	public static final String EVT_RQF_REJECT	= "203";	// reject friend req
	public static final int	  iEVT_RQF_REJECT	= 203;
	
	public static final String EVT_REQ_CIRCLE	= "205";	// request to join a circle
	public static final int	  iEVT_REQ_CIRCLE	= 205;
	public static final String EVT_RQC_ACCEPT	= "206";	// accept friend req
	public static final int	  iEVT_RQC_ACCEPT	= 206;
	public static final String EVT_RQC_REJECT	= "207";	// reject friend req
	public static final int	  iEVT_RQC_REJECT	= 207;
	
	public static final String EVT_REQ_INTROF	= "211";	// introduce a friend
	public static final int	  iEVT_REQ_INTROF	= 211;
	public static final String EVT_RQI_ACCEPT	= "212";	// accept friend introduction
	public static final int	  iEVT_RQI_ACCEPT	= 212;
	public static final String EVT_RQI_REJECT	= "213";	// reject friend introduction
	public static final int	  iEVT_RQI_REJECT	= 213;
	
	public static final String EVT_REQ_INTROC	= "215";	// recommend a circle
	public static final int	  iEVT_REQ_INTROC	= 215;
	public static final String EVT_RQIC_ACCEPT	= "216";	// accept circle introduction
	public static final int	  iEVT_RQIC_ACCEPT	= 216;
	public static final String EVT_RQIC_REJECT	= "217";	// reject circle introduction
	public static final int	  iEVT_RQIC_REJECT	= 217;
	

	// friend events
	public static final String EVT_FRN_MINE		= "2121";
	public static final int	  iEVT_FRN_MINE		= 2121;
	public static final String EVT_FRN_OTHERS	= "2122";
	public static final int	  iEVT_FRN_OTHERS	= 2122;
	public static final String EVT_FRN_ACCEPT	= "2123";
	public static final int	  iEVT_FRN_ACCEPT	= 2123;

	// circle events
	public static final String EVT_CIR_NEW		= "2131";
	public static final int	  iEVT_CIR_NEW		= 2131;
	public static final String EVT_CIR_JOIN		= "2132";
	public static final int	  iEVT_CIR_JOIN		= 2132;
	public static final String EVT_CIR_ADDYOU	= "2133";
	public static final int	  iEVT_CIR_ADDYOU	= 2133;

	public static final String	MOBILE_IGNORE_EVT	= "182;183";


	// user actions to friends and circle
	public static final String	ACT_HELLO		= "hello";
	public static final String	ACT_POSTNOTE	= "note";
	public static final String	ACT_DELTNOTE	= "del_note";
	public static final String	ACT_SEASONAL	= "seasonal";

	public static final String	ACT_CHANGE_MOTTO= "motto";
	
	// my thought questions
	public static String []		THOUGHT_QUESTION = null;
	public static final String	DEFAULT_COMMENT_STR = "Write a comment ...";
	
	// private
	private static boolean bEventOn;
	private static final int MAX_JOIN_EVENT		= 5;				// max join evt for a meeting
	private static final String URL_FILE_PATH	= Util.getPropKey("pst", "URL_FILE_PATH");
	private static final String RESOURCE_FILE_PATH = Util.getPropKey("pst", "RESOURCE_FILE_PATH");
	private static final String HOST		= Util.getPropKey("pst", "PRM_HOST");
	private static final String MOBILE_NOTIFICATION_URI	= Util.getPropKey("pst", "MOBILE_NOTIFICATION_URI");
	//private static final String MOBILE_NOTIFICATION_URI
	//	= "http://192.168.1.15:8080/NotificationManagement/services/notifications/pushNotification";
	private static String adminIdS				= "";
	private static String adminEvtS				= EVT_USR_POSTNOTE;
	private static Logger l 					= PrmLog.getLog();
	
	private static userManager 		uMgr;
	private static userinfoManager	uiMgr;
	private static eventManager 	eMgr;
	private static meetingManager	mtgMgr;
	private static questManager 	qMgr;
	private static answerManager 	aMgr;
	private static resultManager 	rMgr;
	private static projectManager 	pjMgr;
	private static taskManager 		tkMgr;
	private static attachmentManager attMgr;
	private static bugManager		bMgr;
	private static chatManager		cMgr;
	
	private static user jwu;
	
	private static final boolean bHasMobileNotification = (MOBILE_NOTIFICATION_URI != null);
	
	// hashmap for event messages
	private static HashMap<String,String> _evtHash;		// for default (en_US) locale
	
	// mobile event
	private static Client _client;
	private static WebResource _webResource;

	
	static {
		try {
			uMgr	= userManager.getInstance();
			uiMgr	= userinfoManager.getInstance();
			eMgr	= eventManager.getInstance();
			mtgMgr	= meetingManager.getInstance();
			qMgr	= questManager.getInstance();
			aMgr	= answerManager.getInstance();
			rMgr	= resultManager.getInstance();
			pjMgr	= projectManager.getInstance();
			tkMgr	= taskManager.getInstance();
			attMgr	= attachmentManager.getInstance();
			bMgr	= bugManager.getInstance();
			cMgr	= chatManager.getInstance();

			String s;
			if ((s=Util.getPropKey("pst", "EVENT"))!=null && s.equalsIgnoreCase("true"))
				bEventOn = true;
			else
				bEventOn = false;
			
			jwu = Prm.getSpecialUser();
			
			int [] ids = uMgr.findId(jwu, "Role='Site Administrator'");
			for (int i=0; i<ids.length; i++)
				adminIdS += String.valueOf(ids[i]) + ";";
			
			// TODO: hash for event string in en_US
			try {
				_evtHash = fillEventHash(null);
			}
			catch (Exception e) {
				l.error(e.getMessage());
			}

			// thought questions
			if (Prm.isMeetWE()) {
				setUpThoughtQuestions(jwu);
			}
			
			// mobile
			if (bHasMobileNotification) {
				_client = Client.create();
				_webResource = _client.resource(MOBILE_NOTIFICATION_URI);
			}
			
		} catch (PmpException e) {
			l.error(e.getMessage());
		}
	}
	
    // top public method call by OMF/CR to create and trigger event asynchronously
    public static UtilThread createTriggerEvent(PstUserAbstractObject pstuser, String typeIdS,
    		String idS1, String idS2, Date expireDate)
    	throws PmpException
	{
    	// create a UtilThread to do everything
    	if (!bEventOn || (pstuser instanceof PstGuest))
    		return null;			// pst says event option off
    	if (adminEvtS.indexOf(typeIdS)==-1 && adminIdS.indexOf(String.valueOf(pstuser.getObjectId()))!=-1)
    		return null;			// admin is stealth
    	
    	UtilThread th = new UtilThread(UtilThread.CREATE_EVENT, pstuser);
    	th.setParam(0, typeIdS);	// e.g. "105", see event.csv
    	th.setParam(1, idS1);		// meeting id or quest id or projId
    	th.setParam(2, idS2);		// townId or taskId or attId or bugId
    	th.setParam(3, expireDate);
    	th.start();					// UtilThread will call create() and trigger() below to do the job
    	return th;
	}	// END: createTriggerEvent()

    /**
     * Synchronously create and trigger an event
     * @param pstuser
     * @param typeIdS
     * @param targetUid
     * @return
     * @throws PmpException
     */
	public static event createTriggerEventDirect(PstUserAbstractObject pstuser, String typeIdS, int targetUid)
    	throws PmpException
	{
    	return createTriggerEventDirect(pstuser, typeIdS, targetUid, null);
	}
	
	/**
	 * Synchronously create and trigger an event
	 * @param pstuser
	 * @param typeIdS
	 * @param targetUid
	 * @param townIdS
	 * @return
	 * @throws PmpException
	 */
    public static event createTriggerEventDirect(PstUserAbstractObject pstuser, String typeIdS,
    		int targetUid, String townIdS)
		throws PmpException
	{
    	// create and trigger without using thread
    	if (!bEventOn || (pstuser instanceof PstGuest))
    		return null;					// pst says event option off
    	if (adminEvtS.indexOf(typeIdS)==-1 && adminIdS.indexOf(String.valueOf(pstuser.getObjectId()))!=-1)
    		return null;					// admin is stealth on most events
    	
    	l.info("PrmEvent.createTriggerEventDirect(): event [" + typeIdS + "] from user [" + pstuser.getObjectId()
    			+ "] to user [" + targetUid + "]");
		event evt = PrmEvent.create(pstuser, typeIdS, null, townIdS, null);
		
		if (townIdS!=null
				&& !typeIdS.equals(EVT_REQ_FRIEND) && !typeIdS.equals(EVT_REQ_CIRCLE)
				&& !typeIdS.equals(EVT_REQ_INTROF) && !typeIdS.equals(EVT_REQ_INTROC))
			setMtgCircleToVar(pstuser, evt, "var1");		// for networking events, caller would set var1 after this call
		
		// now triggers the event to establish links to users
		user u = (user)uMgr.get(pstuser, targetUid);
		stackEvent(u, evt);
		return evt;
	}
    
	public static void trigger(PstUserAbstractObject pstuser, event evt)
    	throws PmpException
    {
    	// trigger the insertion of links to events to users
    	// Given this event object, evaluate the potential links between user and this object.
    	// The link is inserted into the user in the Events attribute as a stack (LIFO).
		// The correct AlertMessage is mainly set up here (except Creator is filled in at create().)
		int [] ids;
		String s, expr, projIdS;
		int ct = 0;
		PstAbstractObject o, oo;
		project pj = null;
		
    	int iType = Integer.parseInt((String)evt.getAttribute("Type")[0]);
    	switch (iType)
    	{
    		////////////////////////   Meeting Events /////////////////////////
    		case iEVT_MTG_NEW:
    		case iEVT_MTG_UPDATE:
    		case iEVT_CHATMTG_NEW:
    			// inform friends and circle
    			// var1:	circle name and meeting type (e.g. EGI Public)
    			
    			if (iType == iEVT_MTG_UPDATE)
    			{
        			// allow only one iEVT_MTG_UPDATE events from the same user on this meeting
        			expr = "MeetingID='" + (String)evt.getAttribute("MeetingID")[0] + "'"
         					+ " && Type='" + iEVT_MTG_UPDATE + "'"
        					+ " && Creator='" + (String)evt.getAttribute("Creator")[0] + "'";
        			checkCleanMaxEvent(pstuser, expr, 1);
        			
        			// remove all the iEVT_MTG_VIEW from the same user on this meeting
        			expr = "MeetingID='" + (String)evt.getAttribute("MeetingID")[0] + "'"
		 					+ " && Type='" + iEVT_MTG_VIEW + "'"
							+ " && Creator='" + (String)evt.getAttribute("Creator")[0] + "'";
        			checkCleanMaxEvent(pstuser, expr, 0);
    			}
    			
    			// setup var1 in AlertMessage of evt
    			setMtgCircleToVar(pstuser, evt, "var1");
    			
    			// add event to stacks of friends & circle
				ct = addEventForMeeting(pstuser, evt);
   			break;
    			
    		case iEVT_MTG_START:
    			// EVT_MTG_START: inform friends and circle
    			// var1:	circle name and meeting type (e.g. EGI Public)
    			
    			// need to remove all of the EVT_MTG_NEW, EVT_MTG_VIEW and EVT_MTG_UPDATE events
    			ids = eMgr.findId(pstuser, "MeetingID='" + (String)evt.getAttribute("MeetingID")[0] + "'"
    					+ " && Type!='" + EVT_MTG_START + "'"
    					+ " && Type!='" + EVT_MTG_JOIN + "'");
    			for (int i=0; i<ids.length; i++)
    				removeEvent(pstuser, ids[i]);
    			
    			// setup var1 in AlertMessage of evt
    			setMtgCircleToVar(pstuser, evt, "var1");
    			
    			// add event to stacks of friends & circle
				ct = addEventForMeeting(pstuser, evt);
    			break;
    			
    		case iEVT_MTG_JOIN:
    			// EVT_MTG_JOIN
    			// at max leave MAX_JOIN_EVENT Join events on the stack, ignore the rest.  The last msg should be different.
    			// var1:	circle name and meeting type (e.g. EGI Public)
    			
    			// check if the Creator already has a join event, if so, ignore this new one (evt)
    			ids = eMgr.findId(pstuser, "MeetingID='" + (String)evt.getAttribute("MeetingID")[0] + "'"
    					+ " && Type='" + EVT_MTG_JOIN + "'"
    					+ " && Creator='" + (String)evt.getAttribute("Creator")[0] + "'");
    			if (ids.length>0 && ids[0]!=evt.getObjectId())
    			{
    				eMgr.delete(evt);	// remove myself - new event; not triggered yet
    				break;
    			}
    			
    			// check how many EVT_MTG_JOIN event are there for this meeting
    			ids = eMgr.findId(pstuser, "MeetingID='" + (String)evt.getAttribute("MeetingID")[0] + "'"
    					+ " && Type='" + EVT_MTG_JOIN + "'");
    			if (ids.length >= MAX_JOIN_EVENT)
    			{
    				// exceed MAX: ignore and remove this event
    				eMgr.delete(evt);	// remove myself - new event; not triggered yet
    				break;
    			}
    			if (ids.length == MAX_JOIN_EVENT-1)
    			{
    				// change the message to indicate there can be more ppl
    				s = (String)evt.getAttribute("AlertMessage")[0];
    				// TODO: this replacement won't work for other locale
    				// we should use a tag here $AND_OTHERS_HAVE$ so that it will be
    				// replaced by before the message is sent out with the right
    				// locale.
    				s = s.replaceFirst(" has ", " and others have ");
    				evt.setAttribute("AlertMessage", s);
    				eMgr.commit(evt);
    			}
    			
    			// setup var1 in AlertMessage of evt
    			setMtgCircleToVar(pstuser, evt, "var1");
    			
    			// add event to stacks of friends & circle
				ct = addEventForMeeting(pstuser, evt);
    			break;
    			
    		case iEVT_MTG_DONE:
    			// EVT_MTG_DONE
    			// var1:	all the ppl in the mtg (e.g. jsmith, jhui, aquan and sandras)
    			// var2:	circle name and meeting type (e.g. EGI Public)
    			String ppl = "";
    			event aEvt;

    			// remove all the Join message and derive from them the ppl (var1) in the EVT_MTG_DONE msg.
    			ids = eMgr.findId(pstuser, "MeetingID='" + (String)evt.getAttribute("MeetingID")[0] + "'"
    					+ " && (Type='" + EVT_MTG_JOIN + "' || Type='" + EVT_MTG_START + "')");
    			for (int i=0; i<ids.length; i++)
    			{
    				aEvt = (event)eMgr.get(pstuser, ids[i]);
    				if (i>0 && i==ids.length-1 && ids.length!=MAX_JOIN_EVENT) ppl += " and ";
    				else if (i > 0) ppl += ", ";
    				ppl += ((user)uMgr.get(pstuser, (Integer.parseInt((String)aEvt.getAttribute("Creator")[0])))).getFullName();
    				removeEvent(pstuser, ids[i]);			// remove the old EVT_MTG_JOIN event
    			}
    			if (ids.length >= MAX_JOIN_EVENT)
    				ppl += " and others";
    			s = (String)evt.getAttribute("AlertMessage")[0];
    			// TODO: this replacement won't work for other locale.
    			// We should use a tag like $AND_OTHERS$ here so that
    			// the right locale string will be used at the time when
    			// the message is sent out.
    			evt.setAttribute("AlertMessage", s.replaceFirst("\\$var1", ppl));
    			eMgr.commit(evt);
    			
    			// setup var2 in AlertMessage of evt
    			setMtgCircleToVar(pstuser, evt, "var2");
    			
    			// add event to stacks of friends & circle
				ct = addEventForMeeting(pstuser, evt);
    			break;
    			
    		case iEVT_MTG_VIEW:
    			// inform friends and circle
    			// var1:	circle name and meeting type (e.g. EGI Public)
    			
    			// allow only one iEVT_MTG_VIEW events from the same user on this meeting
    			expr = "MeetingID='" + (String)evt.getAttribute("MeetingID")[0] + "'"
     					+ " && Type='" + iEVT_MTG_VIEW + "'"
    					+ " && Creator='" + (String)evt.getAttribute("Creator")[0] + "'";
    			checkCleanMaxEvent(pstuser, expr, 1);
    			
    			// setup var1 in AlertMessage of evt
    			setMtgCircleToVar(pstuser, evt, "var1");
    			
    			// add event to stacks of friends & circle
				ct = addEventForMeeting(pstuser, evt);
    			break;
    			
    		case iEVT_MTG_DELETE:
    			// EVT_MTG_DELETE
    			// remove all previous EVT_MTG_UPDATE event on this meeting
    			// var1:	circle name and meeting type (e.g. EGI Public)
    			
    			// need to remove all meeting events except this one
    			expr = "MeetingID='" + (String)evt.getAttribute("MeetingID")[0] + "'"
					+ " && Type!='" + EVT_MTG_DELETE + "'";
    			checkCleanMaxEvent(pstuser, expr, 0);
    			
    			// setup var1 in AlertMessage of evt
    			setMtgCircleToVar(pstuser, evt, "var1");
    			
    			// the meeting is going to be deleted after this call, fill in more info for user
    			s = (String)mtgMgr.get(pstuser, (String)evt.getAttribute("MeetingID")[0]).getAttribute("Subject")[0];
    			evt.setAttribute("AlertMessage", evt.getAttribute("AlertMessage")[0] + " (" + s + ")");
    			eMgr.commit(evt);
    			
    			// add event to stacks of friends & circle
				ct = addEventForMeeting(pstuser, evt);
    			break;
    			
        	////////////////////////   Blog Events /////////////////////////
    		case iEVT_BLG_POST:
    		case iEVT_BLG_REPLY:
    			// this is meeting blog
    			// inform friends and circle
    			// var1:	circle name and meeting type (e.g. EGI Public)
    			
    			// allow one same events from the same user on this meeting
    			expr = "MeetingID='" + (String)evt.getAttribute("MeetingID")[0] + "'"
     					+ " && Type='" + iType + "'"
    					+ " && Creator='" + (String)evt.getAttribute("Creator")[0] + "'";
    			checkCleanMaxEvent(pstuser, expr, 1);
    			
    			// remove all EVT_MTG_VIEW events
    			expr = "MeetingID='" + (String)evt.getAttribute("MeetingID")[0] + "'"
					+ " && Type='" + EVT_MTG_VIEW + "'"
					+ " && Creator='" + (String)evt.getAttribute("Creator")[0] + "'";
    			checkCleanMaxEvent(pstuser, expr, 0);
    			
    			// setup var1 in AlertMessage of evt
    			setMtgCircleToVar(pstuser, evt, "var1");
    			
    			// add event to stacks of friends & circle
				ct = addEventForMeeting(pstuser, evt);	// this is meeting blog, triggered from post_addblog.jsp
    			break;
    			
    		// QUEST (event/survey) blog
    		case iEVT_BLG_QUEST:
    		case iEVT_BLG_QUEST_C:
    			PstAbstractObject qObj = qMgr.get(pstuser, (String)evt.getAttribute("MeetingID")[0]);	// the quest obj
    			ids = Util2.toIntArray(qObj.getAttribute("Attendee"));
    			ct = stackEvent(pstuser, ids, evt);
    			break;
    			
        	////////////////////////   Friend Events /////////////////////////
    		case iEVT_FRN_MINE:
    			break;
    			
    		case iEVT_FRN_OTHERS:
    			break;
    			
    		case iEVT_FRN_ACCEPT:
    			break;
    			
        	////////////////////////   Circle Events /////////////////////////
    		case iEVT_CIR_NEW:
    			setMtgCircleToVar(pstuser, evt, "var1");
    			ct = addEventToFriend(pstuser, evt);
    			ct += addEventToCircle(pstuser, evt);
    			break;
    			
    		case iEVT_CIR_JOIN:
    			// the user has joined the circle
    			// var1 is circle name
    			setMtgCircleToVar(pstuser, evt, "var1");
    			ct = addEventToCircle(pstuser, evt);
    			break;
    			
    		case iEVT_CIR_ADDYOU:
    			// not used here: only triggered directly
    			break;
    			
        	/////////////////////////   User Events //////////////////////////
    		case iEVT_USR_LOGIN:
    		//case iEVT_USR_LOGOUT:
    		// ECC: changed by using check login status: can remove the whole thing
    			break;
    			
            /////////////////////////   Chat Events //////////////////////////
    		// most chat event (start, join and remove) are created/triggered directly from OmfChatAjax.java
    		// save chat to meeting is handled at the meeting section above.
 
    			
        	/////////////////////////   Quest/Invite Events //////////////////////////
    		case iEVT_INV_NEW:
    		case iEVT_QST_NEW:
    			// invite or quest was created and sent out
    			if ((s=(String)evt.getAttribute("TownID")[0]) != null)
    				s = townManager.getTownName(pstuser, s);
    			else
    				s = "";
				setValueToVar(evt, "var1", s);
				
				o = qMgr.get(pstuser, (String)evt.getAttribute("MeetingID")[0]);	// the quest obj
				s = Util2.displayQuestLink(pstuser, o, null);
				setValueToVar(evt, "var2", s);
				
				ct = 0;
				s = (String)o.getAttribute("Type")[0];
				if (s.indexOf(quest.PUBLIC) != -1)
					ct += addEventToFriend(pstuser, evt);
				if (evt.getAttribute("TownID")[0] != null)
	    			ct += addEventToCircle(pstuser, evt);
				else
				{
					// add event only to participants and owner
					Object [] oA = o.getAttribute("Attendee");
					ids = Util2.toIntArray(oA);
					ct = stackEvent(pstuser, ids, evt);
					ct += stackEvent(pstuser, Integer.parseInt((String)o.getAttribute("Creator")[0]), evt);
				}
    			break;
    			
    		case iEVT_INV_REPLY:
    		case iEVT_QST_REPLY:
    			// a user responded to a quest
    			if ((s=(String)evt.getAttribute("TownID")[0]) != null)
    				s = townManager.getTownName(pstuser, s);
    			else
    				s = "";
				setValueToVar(evt, "var1", s);
				
				o = aMgr.get(pstuser, (String)evt.getAttribute("MeetingID")[0]);	// the answer obj
				oo = qMgr.get(pstuser, (String)o.getAttribute("TaskID")[0]);		// the quest obj

				s += Util2.displayAnswerLink(pstuser, o, oo);
				setValueToVar(evt, "var2", s);
				
				if (evt.getAttribute("TownID")[0] != null)
	    			ct = addEventToCircle(pstuser, evt);
				else
				{
					// add event only to participants of the quest
					Object [] oA = oo.getAttribute("Attendee");
					ids = Util2.toIntArray(oA);
					ct = stackEvent(pstuser, ids, evt);
				}
    			break;
    			
            	/////////////////////////   Personal thoughts   //////////////////////////
        		case iEVT_USR_THOUGHT:
					ids = Util2.toIntArray(pstuser.getAttribute("TeamMembers"));
					ct = 0;
					for (int i=0; i<ids.length; i++)
					{
						user u = (user)uMgr.get(pstuser, ids[i]);
						stackEvent(u, evt);	// stack the event to my friends
						ct++;
					}
        		break;
        			
    		default:
    			// check for rest of the events in event.csv
    			
    			///////////////////////
    			// project/task events here
    			if (iType>=500 && iType<600) {
    				// fill var1 with projName and var2 with taskName
    				projIdS = (String)evt.getAttribute("MeetingID")[0];
    				String taskIdS = (String)evt.getAttribute("TownID")[0];
    				ids = null;
    				if (projIdS != null) {
    					pj = (project)pjMgr.get(pstuser, Integer.parseInt(projIdS));
    					s = "<a href='" + HOST + "/project/proj_plan.jsp?projId="
    						+ projIdS + "'>" + pj.getDisplayName() + "</a>";
    					setValueToVar(evt, "var1", s);
    				}
    				if (taskIdS != null) {
    					task tk = (task)tkMgr.get(pstuser, Integer.parseInt(taskIdS));    					
    					if (pj == null) {
    						pj = tk.getProject(pstuser);
    						projIdS = String.valueOf(pj.getObjectId());
    					}
    					s = "<a href='" + HOST + "/project/task_update.jsp?projId="
    						+ projIdS + "&taskId=" + taskIdS + "'>"
    						+ tk.getTaskName(pstuser) + "</a>";
    					setValueToVar(evt, "var2", s);
    				}
    				
    				// stack the event to project team and followers
        			ct = addEventToProjectTeam(pstuser, pj, evt);
    			}	// END if: 500-599
    			
    			///////////////////////
    			// attachment events
    			else if (iType>=600 && iType<700) {
    				// var1=filename, var2=attId
    				projIdS = (String)evt.getAttribute("MeetingID")[0];
    				String attIdS = (String)evt.getAttribute("TownID")[0];
    				// user open a file in a project
    				attachment attObj = (attachment)attMgr.get(pstuser, attIdS);
    				String fName = attObj.getFileName();
    				fName = "<a href='" + HOST + "/servlet/ShowFile?attId=" + attIdS
    							+ "'>" + fName + "</a>";
    				setValueToVar(evt, "var1", fName);
    				
    				// stack the event to project team and followers
    				if (projIdS != null) {
    					// try to get project >> task path
    					String path = attObj.getProjectPath(pstuser);		// include URL
        				setValueToVar(evt, "var2", path);
        				
            			// allow one same events from the same user on the same file
            			expr = "TownID='" + attIdS + "'"	// this is the attachment ID
             					+ " && Type='" + iType + "'"
            					+ " && Creator='" + (String)evt.getAttribute("Creator")[0] + "'";
            			checkCleanMaxEvent(pstuser, expr, 1);
        				
            			pj = (project) pjMgr.get(pstuser, Integer.parseInt(projIdS));
            			ct = addEventToProjectTeam(pstuser, pj, evt);
    				}
    				else {
    					// remove the project clause in the event
    					s = (String)evt.getAttribute("AlertMessage")[0];
    					s = s.replace(" in project $var2", "");
    					evt.setAttribute("AlertMessage", s);
    					eMgr.commit(evt);
    					
    					// stack event to friends
    					ct = addEventToFriend(pstuser, evt);
    				}
    			}	// END if: 600-699
    			
    			///////////////////////
    			// bug events
    			else if (iType>=700 && iType<800) {
    				// var1=bug synopsis, var2=projName
    				projIdS = (String)evt.getAttribute("MeetingID")[0];
    				String bugIdS = (String)evt.getAttribute("TownID")[0];
    			
    				// var1: bug synopsis
    				bug bObj = (bug) bMgr.get(pstuser, bugIdS);
    				String synopsis = bObj.getStringAttribute("Synopsis");
    				synopsis = "<a href='" + HOST + "/bug/bug_update.jsp?bugId=" + bugIdS
						+ "'>" + synopsis + "</a>";
    				setValueToVar(evt, "var1", synopsis);

    				// var2: project name
    				if (projIdS != null) {	// shouldn't be null
    					pj = (project)pjMgr.get(pstuser, Integer.parseInt(projIdS));
    					String projName = pj.getDisplayName();
    					projName = "<a href='" + HOST + "/project/proj_top.jsp?projId=" + projIdS
    						+ "'>" + projName + "</a>";
    					setValueToVar(evt, "var2", projName);
    				}
    				
        			ct = addEventToProjectTeam(pstuser, pj, evt);
    			}	// END if: 700-799

    			///////////////////////
    			// none matching
    			else {
    				l.error("Unsupported event type [" + iType + "] found in PrmEvent.trigger().");
    				throw new PmpException("fail to process event");
    			}
    	}	// END: switch
    	
    	l.info("Event [" + iType + " - " + evt.getObjectId() + "] triggered to " + ct + " users.");
    	
    }	// END: trigger()
    
	/**
	 * This must be a meeting event
	 * @param pstuser
	 * @param evt
	 * @return
	 * @throws PmpException
	 */
	private static int addEventForMeeting(PstUserAbstractObject pstuser, event evt)
		throws PmpException
	{
		int ct = 0;
		PstAbstractObject mtgObj = mtgMgr.get(pstuser, (String)evt.getAttribute("MeetingID")[0]);	// the meeting obj
		String projIdS = (String)mtgObj.getAttribute("ProjectID")[0];
		// if it is project meeting, add event to all project members
		if (projIdS != null) {
			project pj = (project) pjMgr.get(pstuser, Integer.parseInt(projIdS));
			if (pj != null) {
				ct = addEventToProjectTeam(pstuser, pj, evt);
			}
		}
		else if (evt.getAttribute("TownID")[0]==null) {
			if (mtgObj.getAttribute("Type")[0].equals(meeting.PRIVATE)) {
				// only send event to attendees
				String [] arrIdS = ((meeting)mtgObj).getAllAttendees().toArray(new String[0]);
				ct = stackEvent(pstuser, arrIdS, evt);
			}
			else {
				ct = addEventToFriend(pstuser, evt);
			}
		}
		else {
			ct = addEventToCircle(pstuser, evt);
		}
		return ct;
	}

	public static int addEventToProjectTeam(PstUserAbstractObject pstuser,
			project pj, event evt)
		throws PmpException
	{
		if (pj == null) return 0;
		int [] ids = Util2.toIntArray(pj.getAttribute("TeamMembers"));
		return stackEvent(pstuser, ids, evt);
	}

	public static void checkCleanMaxEvent(PstUserAbstractObject pstuser, String expr, int maxEventAllow)
		throws PmpException
	{
		// check no. of event found based on expr and remove the older ones
		int [] ids = eMgr.findId(pstuser, expr);
		if (ids.length > maxEventAllow)
		{
			Arrays.sort(ids);
			for (int i=0; i<ids.length-maxEventAllow; i++)
				removeEvent(pstuser, ids[i]);	// remove the oldest one
		}
	}
	
	public static void checkCleanMaxEventOnStack(PstUserAbstractObject pstuser, String expr,
			int maxEventAllow, String targetUidS)
		throws PmpException
	{
		// check no. of event found based on expr, limit the max based on targetUidS stack
		int [] ids = eMgr.findId(pstuser, expr);
		if (ids.length <= 0) return;
		Arrays.sort(ids);
		
		String evtIdS;
		if (targetUidS != null)
		{
			String evtStackS = null;
			evtStackS = (String)uMgr.get(pstuser, Integer.parseInt(targetUidS)).getAttribute("Events")[0];
			if (evtStackS == null) return;
			
			int ct = 0;
			for (int i=0; i<ids.length; i++)
			{
				// for each event found
				evtIdS = String.valueOf(ids[i]);
				if (evtStackS.indexOf(evtIdS) != -1) ct++;
			}
			// ct is now the number of event on this user's stack that satisfy the expr
			
			for (int i=0; i<ids.length; i++)
			{
				evtIdS = String.valueOf(ids[i]);
				if (ct-- > maxEventAllow)
				{
					// remove this from the user stack
					unstackEvent(pstuser, Integer.parseInt(targetUidS), evtIdS);
				}
			}
		}
		else
		{
			// unstack not for one person but the whole system
			// always remove all events that satisfy the expr; ignore maxEventAllow
			int [] ids1;	// userIds
			for (int i=0; i<ids.length; i++)
			{
				evtIdS = String.valueOf(ids[i]);
				ids1 = uMgr.findId(pstuser, "Events='%" + evtIdS + "%'");
				for (int j=0; j<ids1.length; j++)
					unstackEvent(pstuser, ids1[j], evtIdS);
			}
		}
	}

    public static event create(PstUserAbstractObject u, String typeIdS,
    		String midS, String townIdS, Date expireDate)
    	throws PmpException
    {
    	if (!bEventOn || (u instanceof PstGuest))
    		return null;					// pst says event option off
    	if (adminEvtS.indexOf(typeIdS)==-1 && adminIdS.indexOf(String.valueOf(u.getObjectId()))!=-1)
    		return null;					// admin is stealth

    	event evt;
    	synchronized (PrmEvent.class) {evt = (event)eMgr.create(u);}
    	String creatorIdS = String.valueOf(u.getObjectId());

    	evt.setAttribute("Type", typeIdS);			// e.g. 101
    	evt.setAttribute("Creator", creatorIdS);
    	evt.setAttribute("CreatedDate", new Date());
    	
    	// The var replaceAll() is done in trigger().  I only need to store the parameters
    	// which can be used by displayEvent() to construct URL links
    	if (midS != null)
      		evt.setAttribute("MeetingID", midS);	// meetingId or projId or questId or chatId
    	if (townIdS != null)
     		evt.setAttribute("TownID", townIdS);	// townId or taskId or attId or bugId
    	if (expireDate != null)
    		evt.setAttribute("ExpireDate", expireDate);
    	
    	// fill in the msg with Creator here, more filling will be done in trigger()
    	user aUser;
    	if (u instanceof oct.pst.PstGuest)
    		aUser = (user)uMgr.get(u, u.getObjectId());
    	else
    		aUser = (user)u;
    	
    	// this should be a company set default locale.  It is done for
    	// performance optimization.  The AlertMessage contains the default
    	// language message.  But if the user chooses a locale different from
    	// this company default, we will have to retain all the substituted
    	// info in order to translate his message in place.
    	
    	String locale = null;	// company default locale: support i18n default to en_US
    	String evtIdS = "EVENT."+typeIdS;			// e.g. EVENT.101
    	String msg = getLocalEventString(locale, evtIdS);	//Util.getPropKey(PROP_FILE, evtIdS);
    	if (msg == null)
    		l.error("PrmEvent.create() failed to find message in the property file (" + evtIdS + ")");
    	else
	    {
	    	String creator = aUser.getFullName();
	    	if (Util.isNullOrEmptyString(creator))
	    		creator = Prm.getAppTitle();	// assume the null name to be System
	    	creator = LNK1 + creator + LNK2;	// the link will be replaced at time of display
	    	msg = msg.replaceAll("\\$Creator", creator);	// full name of creator
	    	evt.setAttribute("AlertMessage", msg);
	    }

    	eMgr.commit(evt);
    	return evt;
    }
    
    /**
     * 
     * @param locale default null to en_US
     * @param evtIdS
     * @return
     */
    public static String getLocalEventString(String locale, String evtIdS)
    {
    	// for en_US we will optimize by looking up the hash
    	// for other locale, we will have to read the locale string file
    	
    	if (locale==null || locale.equalsIgnoreCase("en_US")) {
    		// _evtHash is initialize at init above, should not be null
    		return _evtHash.get(evtIdS);
    	}
    	
    	// TODO: other locale support
		return null;
	}

	// an event that user may respond with actions
    public static event createActionEvent(PstUserAbstractObject u, String typeIdS,
    		String param1, String param2, String param3)
		throws PmpException
	{
    	if (!bEventOn || (u instanceof PstGuest))
    		return null;					// pst says event option off
    	if (adminEvtS.indexOf(typeIdS)==-1 && adminIdS.indexOf(String.valueOf(u.getObjectId()))!=-1)
    		return null;					// admin is stealth
    	
    	// create evt and fill in type, creator, createdDate and get basic msg from properties file
    	event evt = create(u, typeIdS, null, null, null);
    	
    	// do replace var's here
		// TODO: all vars should be stored to support different locale
    	String msg = null;
    	if (typeIdS.equals(EVT_USR_SENDMSG))
    	{
    		// user actions: say hello
    		// param1 is actiontype (e.g. hello)
    		// var1 in AlertMessage is the action message
    		msg = "<a href='javascript:showExpr(\"" + param1 + ":" + ((user)u).getFullName() + "\")' class='listlink'>" + param1 + "</a>";
    		msg = ((String)evt.getAttribute("AlertMessage")[0]).replaceFirst("\\$var1", msg);
    	}
    	else if (typeIdS.equals(EVT_USR_POSTNOTE))
    	{
    		// post note
    		// param1 is note
    		// param2 is note backgd image
    		// param3 is parentId
    		param1 = param1.replaceAll("\\$", "&#36;");	// special char like $ would fail in replaceFirst()
    		msg = "<blockquote class='bq_note'";
    		if (param2 != null)
    		{
    			// background and text color
    			String [] sa = param2.split("\\?");
    			msg += " style='";
    			if (sa[0].length() > 0)
    				msg += "background:url(" + sa[0] + ") repeat;";
    			if (sa.length > 1)
    				msg += " color:" + sa[1];
    			msg += "'";				// close the style
    		}
    		msg += ">" + param1 + "</blockquote>";
    		msg = ((String)evt.getAttribute("AlertMessage")[0]).replaceFirst("\\$var1", msg);
    		if (param3 != null)
    			evt.setAttribute("ParentID", param3);
    	}
    	else if (typeIdS.equals(EVT_USR_SEASON))
    	{
    		// send thing (turkey)
    		// param1 is note; param2=thing; param3=thingFileName
    		// var1 is the thing (turkey) and the link to picture
    		if (param2.equalsIgnoreCase("turkey"))
    			param3 = URL_FILE_PATH + "/action/nov/" + param3;
     		msg = param2 + "<br><img src='" + param3 + "' height='75'/>";
     		if (param1!=null && param1.length()>0)
    			msg += "<blockquote class='bq_note'>" + param1 + "</blockquote>";
    		
       		msg = ((String)evt.getAttribute("AlertMessage")[0]).replaceFirst("\\$var1", msg);
    	}
    	else if (typeIdS.equals(EVT_USR_THOUGHT))
    	{
    		// user posts a personal thought
    		// param1 is the text
    		// param2 is the blog Id
    		// param3 is the question Id
    		msg = QUESTION_SUB + param3 + " ";// "@Q_2 " replace in OmfEventAjax to "on 'how are you ...' xxx said"
    		msg += "<blockquote class='bq_note'>" + param1 + "</blockquote>";
    		msg = ((String)evt.getAttribute("AlertMessage")[0]).replaceFirst("\\$var1", msg);
			evt.setAttribute("TownID", param2);		// event use TownID to store the blog Id
    	}
    	
    	if (msg != null)
    	{
			evt.setAttribute("AlertMessage", msg);
			eMgr.commit(evt);
    	}
    	return evt;
	}
    
    private static int addEventToFriend(PstUserAbstractObject pstuser, event evt)
    	throws PmpException
	{
    	return addEventToFriend(pstuser,  evt, 0);
	}
    private static int addEventToFriend(PstUserAbstractObject pstuser, event evt, int ignoreUid)
    	throws PmpException
    {
		int [] friendIds;
		Object [] objArr;
		int ct = 0;
		
		try {
			PstAbstractObject creator = uMgr.get(pstuser, Integer.parseInt((String)evt.getAttribute("Creator")[0]));
			objArr = creator.getAttribute("TeamMembers");	// friends
			friendIds = Util2.toIntArray(objArr);
			for (int i=0; i<friendIds.length; i++)
			{
				// for each friend, stack this event
				if (friendIds[i] == ignoreUid) continue;
				try {ct += stackEvent((user)uMgr.get(pstuser, friendIds[i]), evt);}
				catch (PmpException e){l.error("addEventToFriend() failed to stackEvent for user ["+ friendIds[i] + "]"); continue;}
			}
		} catch (PmpException e) {l.error("PmpException caught in addEventToFriend(): "+e.getMessage()); throw e;}
		return ct;
    }
    
    
    public static int addEventToCircle(PstUserAbstractObject pstuser, event evt)
    	throws PmpException
	{
    	return addEventToCircle(pstuser,  evt, 0);
	}
    public static int addEventToCircle(PstUserAbstractObject pstuser, event evt, int ignoreUid)
    	throws PmpException
    {
    	// NOTE: need circleId (=townId) in event object
		String circleIdS;
		int [] ids;
		int ct = 0;
		
		try {
			if ((circleIdS = (String)evt.getAttribute("TownID")[0]) != null)
			{
				ids = uMgr.findId(pstuser, "Towns=" + circleIdS);
	   			for (int i=0; i<ids.length; i++)
				{
					// for each member, stack this event
					if (ids[i] == ignoreUid) continue;
					try {ct += stackEvent((user)uMgr.get(pstuser, ids[i]), evt);}
					catch (PmpException e){l.error("addEventToCircle() failed to stackEvent for user ["+ ids[i] + "]"); e.printStackTrace(); continue;}
				}
			}
		} catch (PmpException e) {l.error("PmpException caught in addEventToCircle(): "+e.getMessage()); throw e;}
		return ct;
    }
    
    public static void setMtgCircleToVar(PstUserAbstractObject pstuser, event evt, String varNum)
    	throws PmpException
    {
		String s, value, mtgType;
		PstAbstractObject mtg = null;

		try {
			try
			{
				if ((s = (String)evt.getAttribute("MeetingID")[0]) != null)
				{
					mtg = mtgMgr.get(pstuser, s);
					mtgType = " " + (String)mtg.getAttribute("Type")[0];
				}
				else
					mtgType = "";
			} catch (PmpException e) {mtgType = "";}	// might be chat id
			if ((s = (String)evt.getAttribute("TownID")[0]) != null)
				s = townManager.getTownName(pstuser, s);
			else
				s = "";
			value = s + mtgType;	// e.g. EGI or EGI Public or Public
			setValueToVar(evt, varNum, value);
		} catch (PmpException e) {l.error("PmpException caught in setMtgCircleToVar(): "+e.getMessage()); throw e;}
    }
    
    /**
     * Convenient tool method to replace var's in an event message with
     * an actual value.  All var's should be stored in the event object
     * in case if a different locale message is requested.
     * @param evt
     * @param varNum
     * @param value
     * @throws PmpException
     */
    public static void setValueToVar(event evt, String varNum, String value)
    	throws PmpException
    {
		String s = (String)evt.getAttribute("AlertMessage")[0];
		if (s.indexOf("$"+varNum) == -1) return;		// no such var in the event string
		s = s.replace("$"+varNum, value);		// ECC: can't use replaceFirst because regex may not work
		evt.setAttribute("AlertMessage", s);
		eMgr.commit(evt);
    }
    
    public static void removeEvent(PstUserAbstractObject pstuser, int id)
    	throws PmpException
    {
    	// delete the event object and remove its presence from user stacks
    	PstAbstractObject evt;
    	try
    	{
    		evt = eMgr.get(pstuser, id);
    		eMgr.delete(evt);
    	}
    	catch (PmpException e) {}			// the event might not exist
    	
    	// continue to find and unstack the event
    	int [] ids = uMgr.findId(pstuser, "Events='%" + id + "%'");
    	for (int i=0; i<ids.length; i++)
    	{
    		// unstack this event for each user that has it on his stack
    		unstackEvent(pstuser, ids[i], String.valueOf(id));
    	}
    }	// END: removeEvent()
    
    public static int stackEvent(PstUserAbstractObject pstuser, String [] idS, event evt)
	throws PmpException
    {
    	//simply convert String[] to int[]
    	int [] ids = new int[idS.length];
     	for (int i=0; i<ids.length; i++) {
    		try {ids[i] = Integer.parseInt(idS[i]);}
    		catch (Exception e) {ids[i] = 0; continue;}
    	}
     	return stackEvent(pstuser, ids, evt);
    }
    
    /**
     * Use a thread to perform this stackEvent() to a list of users
     * @param pstuser
     * @param ids
     * @param evt
     * @return
     * @throws PmpException
     */
    public static int stackEvent(PstUserAbstractObject pstuser, int [] ids, event evt)
    	throws PmpException
    {
    	
		UtilThread th = new UtilThread(UtilThread.TRIGGER_MOBILE_EVENT, pstuser);
		th.setParam(0, ids);		// param[0] is ids[]
		th.setParam(1, evt);
		th.start();					// the thread will call pushToMobile
		return ids.length;

    	/*
    	user u;
    	int ct = 0;
    	for (int i=0; i<ids.length; i++)
    	{
    		try {u = (user)uMgr.get(pstuser, ids[i]);}
    		catch (PmpException e) {continue;}
    		ct += stackEvent(u, evt);
    	}
    	return ct;
    	*/
    }
    public static int stackEvent(PstUserAbstractObject pstuser, int uid, event evt)
    	throws PmpException
    {
    	user u = (user)uMgr.get(pstuser, uid);
    	return stackEvent(u, evt);
    }
    
    /**
     * stackEvent() stacks one event to one user
     * @param u
     * @param evt
     * @return
     * @throws PmpException
     */
    public static int stackEvent(user u, event evt)
    	throws PmpException
	{
    	return stackEvent(u, evt, true);		// default is to push mobile event
	}
    public static int stackEvent(user u, event evt, boolean bPushMobile)
    	throws PmpException
    {
    	// stack a new event to the user's Events attribute
    	// put this event Id to the top of the stack.  If the stack size is larger than EVENT_STACK_SIZE,
    	// the older events will be removed.
    	// The stack is a string like this 12347;12346;12345  (from new ... to ... old)
    	String stack = (String)u.getAttribute("Events")[0];
    	if (stack == null) stack = "";

    	String eidS = evt.getObjectName();
    	if (stack.indexOf(eidS) != -1)
    		return 0;				// the event is already on stack

    	String [] sa = stack.split(";");
    	int len = sa.length;
    	if (len >= EVENT_STACK_SIZE)
    	{
    		int idx = stack.length();
    		while (len-- >= EVENT_STACK_SIZE)
    		{
    			// need to cut the tail
    			idx = stack.lastIndexOf(';', idx-1);
    		}
    		stack = stack.substring(0,idx);
    	}

    	// add new event id to the head
    	if (stack.length() > 0)
    		stack = ";" + stack;
    	stack = eidS + stack;

    	u.setAttribute("Events", stack);
    	uMgr.commit(u);
    	
    	// push the event to Apple mobile service
    	if (bPushMobile)
    		pushMobileEvent(String.valueOf(u.getObjectId()), eidS);
    	
    	return 1;					// 1 event stacked
    }	// END: stackEvent()
    
    /**
     * Called by OmfChatObject.java to just push mobile event for chat without stackEvent() to web.
     * Need to check if user has silent option on.
     * @param ids
     * @param eidS
     */
    public static void pushChatMobileEvent(int [] ids, String eidS, String chatIdS)
    	throws PmpException
    {
    	chat cObj = (chat) cMgr.get(jwu, chatIdS);
    	String silentIds = cObj.getOption(chat.OPT_SILENCE);
    	// should remove the silent users
    	
    	pushMobileEvent(ids, eidS);

    	/*String uidS;
    	for (int uid : ids) {
    		if (uid <= 0) continue;
    		uidS = String.valueOf(uid);
    		if (silentIds!=null && silentIds.contains(uidS)) continue;			// silent: don't push event
    		pushMobileEvent(uidS, eidS);
    	}*/
    }
    
    public static void pushMobileEvent(int [] ids, String eidS)
    	throws PmpException
    {
    	String idsStr = StringUtil.toString(ids, ",");
    	pushMobileEvent(idsStr, eidS);
    }
    
    /**
     * 
     * @param uidS	(this now can support a list of uids delimited by ","
     * @param eidS
     */
    private static void pushMobileEvent(String uidS, String eidS)
    	throws PmpException
    {
    	if (!bHasMobileNotification) return;
    	
    	// check ignore event
    	event evtObj = (event) eMgr.get(jwu, eidS);
    	if (MOBILE_IGNORE_EVT.contains(evtObj.getStringAttribute("Type"))) return;
    	 
    	MultivaluedMap<String, String> formData = new MultivaluedMapImpl();
    	formData.add("userId", uidS);		// can be one or more uid separated by ","
    	formData.add("eventId", eidS);
    	
		// ECC: do not use thread and only do it for Apple

		// use Webservice to push mobile event (only to Apple for now)
		try {
			PstAbstractObject o = uMgr.get(jwu, Integer.parseInt(uidS));
			Object[] tokenArr = o.getAttribute("Token1");
			if (tokenArr!=null && tokenArr.length>0) {
				System.out.println("push mobile (Apple) noti: [" + eidS + "] to " + uidS);
				pushToMobile(formData);
			}
		}
		catch (Exception e) {}
    }
    
    public static void pushToMobile(MultivaluedMap<String, String> formData)
    	throws Exception
    {
    	ClientResponse response =
    		_webResource.type("application/x-www-form-urlencoded").post(ClientResponse.class, formData);
    	System.out.println(response.toString());
    	System.out.println("done pushing!!");
    }

	public static void unstackEvent(PstUserAbstractObject pstuser, int uid, String evtIdS)
    	throws PmpException
    {
    	// remove this event from this user stack if found
    	PstAbstractObject u = uMgr.get(pstuser, uid);

    	String retS = "";
    	String evtS = (String)u.getAttribute("Events")[0];
    	int idx1, idx2;
    	if ((idx1 = evtS.indexOf(evtIdS)) != -1)
    	{
    		if ((idx2 = evtS.indexOf(";", idx1)) == -1)
    			retS = evtS.substring(0, idx1);		// evtS is the last event
    		else
    			retS = evtS.substring(0, idx1) + evtS.substring(idx2+1);	// skip evtS and the ";"
    		if (retS.length() <= 0) retS = null;
    		u.setAttribute("Events", retS);
    		uMgr.commit(u);
    	}
    }
    
    public static void setUpThoughtQuestions(PstUserAbstractObject u)
    	throws PmpException
    {
    	PstAbstractObject o = rMgr.get(u, "Thoughts");
    	Object [] questionArr = o.getAttribute("Alert");
    	THOUGHT_QUESTION = new String[questionArr.length];
    	for (int i=0; i<questionArr.length; i++) {
        	THOUGHT_QUESTION[i] = (String)questionArr[i]; 
    	}
    }
    
    public static HashMap<String, String> fillEventHash(String locale)
    	throws FileNotFoundException, IOException
    {
    	if (locale == null) locale = "en_US";
		File evtFile = new File(RESOURCE_FILE_PATH + "/" + locale + "/event.csv");
    	return StringUtil.putResourceInHash(evtFile);
	}

}	// END class PrmEvent
