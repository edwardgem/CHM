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
//      Thread to perform various tasks for PRM/CR/OMF.  Their names will determine their jobs:
//		APPEND_CONTACTS - convert guest emails on meetings to userIds.
//		CONVERT_EMAILS	- convert guest (emails) on a user to friends/contacts (TeamMembers).
//		ADD_EXTERN_ACCT	- when registering for one product (e.g. PRM), allows auto register to another product
//							(e.g. OMF) that is on another URL.
//		CREATE_EVENT	- create an event and trigger the connections to relevant users.
//
//	Modification:
// 			@AGQ090606	Removed GuestEmails from meeting object if it is a user.
//						User will be added as optional attendee.
//			@ECC101807	Support event triggers.
//
/////////////////////////////////////////////////////////////////////
package util;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.Date;

import oct.codegen.event;
import oct.codegen.meeting;
import oct.codegen.meetingManager;
import oct.codegen.project;
import oct.codegen.projectManager;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstUserAbstractObject;

import org.apache.log4j.Logger;

public class UtilThread extends Thread {
	
	// different thread functions
	public static final String 		APPEND_CONTACTS = "APPEND_CONTACTS"; 	// Append Contacts to Users
	public static final String 		CONVERT_EMAILS	= "CONVERT_EMAILS";		// Convert guestEmails to user ids
	public static final String 		ADD_EXTERN_ACCT	= "ADD_EXTERN_ACCT";	// extern app calls to create an acct
	public static final String 		CREATE_EVENT 	= "CREATE_EVENT";		// create and trigger an event
	public static final String 		CAL_PROJ_SPACE	= "CAL_PROJ_SPACE";// calculate space used by a project's attachments
	public static final String 		CAL_REMOTE_SPACE= "CAL_REMOTE_SPACE";	// calculate space used on a dir path
	public static final String		TRIGGER_MOBILE_EVENT = "TRIG_MOBILE_EVENT";
	
	public static final String 		ATTENDEE 		= "Attendee";
	public static final String 		GUESTEMAILS 	= "GuestEmails";
	
	static Logger 					l 				= PrmLog.getLog();
	
	// private attribute
	private static final String SIZE_TERM			= "?#";
	
	private static userManager 		uMgr;
	private static meetingManager	mMgr;
	private static projectManager	pjMgr;
	
	private PstUserAbstractObject 	pstuser;
	private PstAbstractObject 		pstObj; 		// meeting or quest
	private Object []				param;			// allow 10 String parameters
	
	static {
		try {
			uMgr = userManager.getInstance();
			mMgr = meetingManager.getInstance();
			pjMgr = projectManager.getInstance();
		} catch (PmpException e) {
			uMgr = null;
			mMgr = null;
			pjMgr = null;
			l.error(e.getMessage());
		}
	}
	
	public UtilThread(String name, PstUserAbstractObject pstuser) {
		super(name);
		this.pstuser = pstuser;
		initParam();
	}
	
	/**
	 * Constructor
	 * @param name Name of the method
	 * @param pstuser
	 * @param pstObj 
	 */
	public UtilThread(String name, PstUserAbstractObject pstuser, PstAbstractObject pstObj) {
		super(name);
		this.pstuser 	= pstuser;
		this.pstObj 	= pstObj;
		initParam();
	}
	
	private void initParam()
	{
		param = new Object[10];
		for (int i=0; i<10; i++)
			param[i] = null;
	}
	public void setParam(int idx, Object valS)
	{
		param[idx] = valS;
	}
	
	@SuppressWarnings("unchecked")
	public void run() {
		String name = super.getName();
		this.setPriority(Thread.MIN_PRIORITY);
		l.info("UtilThread [" + name + "] started");
		String s;
		
		if (name.equals(APPEND_CONTACTS)) {
			try {
				if (pstObj instanceof meeting) {
					meeting mtg = (meeting) pstObj; // Converted to call special methods
					Integer []	userIdArr;	// Holds user Ids
					ArrayList	guestToUserId	= new ArrayList(); // Converted user Ids from emails
					ArrayList	emailArr 	= new ArrayList(); // GuestEmails
					int noOfConversion = 0; // Number of guestEmails converted to Users Ids
					if (uMgr == null) uMgr	= userManager.getInstance(); // Shouldn't happen
					if (mMgr == null) mMgr	= meetingManager.getInstance(); // Shouldn't happen
					
					Object [] objArrGE = pstObj.getAttribute(meeting.GUESTEMAILS);
					// @AGQ cannot reuse same object array because of meeting commit
					Object [] objArrAtt = pstObj.getAttribute(meeting.ATTENDEE); 	
					
					// Get all attendee IDs to compare w/ GuestEmails
					int [] attIArr = new int[objArrAtt.length];
					if (objArrAtt[0]!=null) {
						String tempS = null;
						String [] splitS = null;
						for (int i=0; i<objArrAtt.length; i++) {
							tempS = (String) objArrAtt[i];
							if (tempS != null) {
								splitS = tempS.split(meeting.DELIMITER);
								if (splitS.length > 0) {
									try {
										attIArr[i] = Integer.parseInt(splitS[0]);
									} catch (NumberFormatException e) {
										l.error(e.getMessage());
										continue;
									}
								}
							}
						}
					}

					// Convert GuestEmails to User Ids					
					if (objArrGE[0] != null) {
						String email;
						int [] curIArr;
						for (int i=0; i<objArrGE.length; i++) {
							email = ((String) objArrGE[i]).trim();
							curIArr = uMgr.findId(pstuser, "Email='"+email+"'");
							if (curIArr.length > 0) {
								for (int j=0; j<curIArr.length; j++) {
									guestToUserId.add(Integer.valueOf(curIArr[j]));
									// @AGQ090606
									mtg.removeAttributeIgnoreCase(meeting.GUESTEMAILS, email);
									// Compare attendee IDs with GuestEmail to remove duplicate
									// TODO: this algorithm is slow
									boolean found = false;
									for (int k=0; k<attIArr.length; k++) {
										if (attIArr[k] == curIArr[j]) {
											found = true;
											break;
										}
									}
									if (!found)
										mtg.appendAttribute(meeting.ATTENDEE, curIArr[j]+meeting.DELIMITER+meeting.ATT_OPTIONAL);				
								}
							}
							else {
								emailArr.add(email);
							}
						}
					}
					// @AGQ090606
					mMgr.commit(mtg);
					noOfConversion = guestToUserId.size();
					
					// Convert Attendee to User Ids					
					int noOfUserIds; // Number of User Ids
					if (objArrAtt[0] != null) {
						noOfUserIds = objArrAtt.length;
						userIdArr = new Integer[noOfUserIds + noOfConversion];
						for (int i=0; i<objArrAtt.length; i++) {
							userIdArr[i] = Integer.valueOf(attIArr[i]);
						}
					}
					// No user id found
					else {
						noOfUserIds = 0;
						userIdArr = new Integer[noOfUserIds + noOfConversion];
					}
					
					// Add remaining converted users
					if (noOfConversion > 0) {
						for (int i=0; i<noOfConversion; i++) {
							userIdArr[i+noOfUserIds] = (Integer) guestToUserId.get(i); 
						}
					}
					
					// Set contact lists to user object
					user u;
					int userId = pstuser.getObjectId();
					int curId = 0; 
					for (int i=0; i<userIdArr.length; i++) {
						curId = userIdArr[i].intValue();
						if (userId == curId)
							u = (user) pstuser;
						else 
							u = (user) uMgr.get(pstuser, curId);
						
						if(!u.setContactList(userIdArr, emailArr))
							l.warn("Failed to add contacts for userId " + u.getObjectId() + " for meeting " + pstObj.getObjectId());
						uMgr.commit(u);
					}
					l.info("UtilThread completed cross add meeting [" + mtg.getObjectId() + "] members as contacts for " + userIdArr.length + "people.");
				}	// END if meeting
				
				///////////////////////////////////////////////////////////////////////////
				
				else if (pstObj instanceof project) {
					project pjObj = (project) pstObj;
					Object [] oArr = pjObj.getAttribute("TeamMembers");
					int uid;
					user uObj;
					for (Object o : oArr) {
						// for each project team member, add the whole team to his contact list
						if (o != null) {
							uid = ((Integer)o).intValue();
							uObj = (user) uMgr.get(pstuser, uid);
							uObj.addContacts(oArr);
						}
					}
					l.info("UtilThread completed cross add project [" + pjObj.getObjectId() + "] members as contacts for " + oArr.length + "people.");
				}	// END else if project
				
			} catch (PmpException e) {
				l.error(e.getMessage());
			}
		}
		else if (name.equals(CONVERT_EMAILS)) {
			try {
				if (uMgr == null) uMgr	= userManager.getInstance(); // Shouldn't happen
				uMgr.convertGuestEmailsToUser(pstuser);
			} catch (PmpException e) {
				l.error(e.getMessage());
			}
		}
		
		else if (name.equals(ADD_EXTERN_ACCT))
		{
			try
			{
				URL url;
				HttpURLConnection urlConn;
				DataOutputStream printout;
				BufferedReader input;

				s = Util.getPropKey("pst", "ADD_EXTERN_ACCT");	// the URL like www.meetwe.com
				if (s == null) return;

				s += "/admin/post_adduser.jsp";
				url =new URL(s);

				urlConn =(HttpURLConnection)url.openConnection();

				urlConn.setDoInput(true);
				urlConn.setDoOutput(true);
				urlConn.setUseCaches(false);

//				set request method
				urlConn.setRequestMethod("POST");
//				set request type
				urlConn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");

//				 data-value pairs are separated by &
				String content =
					"Extern=" + URLEncoder.encode(Util.getPropKey("pst", "PRM_HOST"), "UTF-8") +
					"&" +
					"Company=" + URLEncoder.encode(Util.getPropKey("pst", "COMPANY_NAME"), "UTF-8") +
					"&" +
					"Email=" + URLEncoder.encode((String)param[0], "UTF-8") +
					"&" +
					"UserName=" + URLEncoder.encode((String)param[1], "UTF-8") +
					"&" +
					"newPass=" + URLEncoder.encode((String)param[2], "UTF-8") +
					"&" +
					"Departments=" + URLEncoder.encode((String)param[3], "UTF-8");

				urlConn.setRequestProperty("Content-Length", content.length()+ "" );

//				 Send POST output.
				printout = new DataOutputStream( urlConn.getOutputStream() );

				printout.writeBytes (content);
				printout.flush ();
				printout.close ();

//				 Get response data.
				input = new BufferedReader(new InputStreamReader(urlConn.getInputStream()));

				while( null != ((s = input.readLine())))
				//System.out.println(s);
				input.close ();
			}
			catch (MalformedURLException me)
			{
				l.error("MalformedURLException; " + me);
			}
			catch (IOException ioe)
			{
				l.error("IOException; " + ioe.getMessage());
			}
		}
		
		else if (name.equals(CREATE_EVENT))
		{
			// create and trigger events
			// caller must call setParam() to pass param into this thread
			// param0 is event typeId (e.g. 101 or 112)
			// param1 is meetingID (or projId)
			// param2 is circleID (=townId) (or taskId)
			// param3 is expireDate
			// all except param0 can be null
			try
			{
				// this call only create the event object and sets the parameters
				// for meeting events: param1=mid; param2=townId (circleId)
				event evt = PrmEvent.create(pstuser, (String)param[0],
						(String)param[1], (String)param[2], (Date)param[3]);
				
				// now triggers the event to establish links to users
				PrmEvent.trigger(pstuser, evt);
			}
			catch (PmpException e)
			{
				l.error("PmpException in CREATE_EVENT thread: " + e.getMessage());
			}
		}
		
		else if (name.equals(TRIGGER_MOBILE_EVENT))
		{
	    	user u;
	    	int ct = 0;
	    	
	    	int [] ids = (int[]) param[0];
	    	event evt  = (event) param[1];
	    	
	    	for (int i=0; i<ids.length; i++) {
	    		try {
	    			u = (user)uMgr.get(pstuser, ids[i]);
	    			ct += PrmEvent.stackEvent(u, evt, true);	// don't push one by one
	    		}
	    		catch (Exception e) {l.error("Error in TRIGGER_MOBILE_EVENT thread to stackEvent");}
	    	}
	    	
	    	
	    	try {
		    	// push mobile event to all users at once
		    	PrmEvent.pushMobileEvent(ids, evt.getObjectName());
	    		l.info("UtilThread stacked (" + ct + ") "
	    			+ evt.getStringAttribute("Type") + " events [" + evt.getObjectName() + "]");
	    	}
	    	catch (PmpException e) {l.error("Failed pushing mobile event in UtilThread.");}

			/**
			try {
				PrmEvent.pushToMobile((MultivaluedMap<String, String>) param[0]);
			}
			catch (Exception e) {e.printStackTrace();}
			*/
		}
		
		else if (name.equals(CAL_PROJ_SPACE))
		{
			// calculate space used by a project's attachments
			// caller must call setParam() to pass param into this thread
			// param0 is the project ID
			try
			{
				// call project.getProjectSpace() to do the actual calculation
				// store the result in MB in project's SPACE_USED attribute
				int [] pjIds;
				if (param[0] != null)
				{
					pjIds = new int[1];
					pjIds[0] = Integer.parseInt((String)param[0]);
				}
				else
				{
					pjIds = pjMgr.findId(pstuser, "Owner='" + pstuser.getObjectId() + "'");
				}
				
				for (int i=0; i<pjIds.length; i++)
				{
					project pj = (project)pjMgr.get(pstuser, Integer.parseInt((String)param[0]));
					pj.setAttribute("SpaceUsed", new Integer(pj.getProjectSpace(pstuser)));
					pjMgr.commit(pj);
					
					// update total SpaceUsed by the user (projects + upload areas)
					PstAbstractObject uObj = uMgr.get(pstuser, Integer.parseInt((String)pj.getAttribute("Owner")[0]));
					Util2.updateSpaceUsed((PstUserAbstractObject)uObj);
				}
			}
			catch (PmpException e)
			{
				l.error("PmpException in CAL_PROJ_SPACE thread: " + e.getMessage());
			}
		}
		
		else if (name.equals(CAL_REMOTE_SPACE))
		{
			// calculate space used under a remote space directory path
			// caller must call setParam() to pass param into this thread
			// param0 is the uid
			// param1 is the complete pathname
			// param2 is the db stored area name (peace$C:/Temp/Folder1 ...)
			try
			{
				String uidS = (String)param[0];
				String path = (String)param[1];
				String area = (String)param[2];
				PstAbstractObject uObj = uMgr.get(pstuser, Integer.parseInt(uidS));
				
				// recursively look into the filesystem to calculate space
				File fObj = new File(path);
				int size = Util2.getSize(fObj);		// in MB
				
				// find and remove the item in the Backup attribute
				String oldVal;
				if ((oldVal = Util2.removeAttribute(uObj, "Backup", area+"*?")) == null)
					oldVal = Util2.removeAttribute(uObj, "Backup", area + "?");	// try removing /temp/folder1*
				if (oldVal == null)
				{
					// weird?  It should be there, anyway, construct another one
					l.warn("CAL_REMOTE_SPACE thread cannot find a supposed old value in the Backup attribute of ["
							+ uidS + "]");
					oldVal = area;
				}
				
				// replace the info in the Backup attribute
				int idx;
				String pathName = oldVal;
				if ((idx = pathName.indexOf(SIZE_TERM)) != -1)
					pathName = pathName.substring(0, idx);		// peace$D:/temp/folder1?@ADMIN;ENGR
				pathName += SIZE_TERM + String.valueOf(size);
				uObj.appendAttribute("Backup", pathName);
				uMgr.commit(uObj);

				Util2.updateSpaceUsed((PstUserAbstractObject)uObj);
			}
			catch (PmpException e)
			{
				l.error("PmpException in CAL_PROJ_SPACE thread: " + e.getMessage());
			}
		}
		
		l.info("UtilThread [" + name + "] done and exit");
	}
}
