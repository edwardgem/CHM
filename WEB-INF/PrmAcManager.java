//
//	Copyright (c) 2006 EGI Technologies.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
// $Header$
//
//	File:	$RCSfile$
//	Author:	Allen G Quan
//	Date:	$Date$
//  Description:
//      Servlet to create or delete Action/Decision/Issue (AC). The doGet
//		is called when the recorder changes projId. This method returns 
//		a new set of names corresponding to the projId. The doPost performs
//		adding and removing of AC. The new list of AC is returned to update
//		the recorder's page. 
//
//  Required:
//		mid			- meeting id
//		Type		- type: action/decision/issue
//		Priority	- priority: high/medium/low
//		Description	- the current item's description
//		Owner		- the "coordinator"/"file by" name
//
//	Optional:
//		projId	- the project id this AC is associated with
//		BugId	- the issue number this AC is associated with
//		
//
//	Modification:
/////////////////////////////////////////////////////////////////////

import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.Enumeration;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import oct.codegen.action;
import oct.codegen.actionManager;
import oct.codegen.bug;
import oct.codegen.bugManager;
import oct.codegen.meeting;
import oct.codegen.meetingManager;
import oct.codegen.user;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstUserAbstractObject;
import util.PrmMtgConstants;
import util.PrmUpdateCounter;
import util.Util;

public class PrmAcManager extends HttpServlet implements PrmMtgConstants{
	/**
	 * Fetches names when the recorder changes Project. This method also updates
	 * the "New Attendee's", Coordinator, Issue / PR ID, Responsible, and 
	 * Coordinator list 
	 */
	private static boolean bDebug = false;

	public void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
		try {
			PstUserAbstractObject pstuser = null;
			HttpSession httpSession = request.getSession(false);
			String midS = request.getParameter(MID);
						
			if (httpSession != null)
				pstuser = (PstUserAbstractObject)httpSession.getAttribute(PSTUSER);
			if (pstuser == null || midS == null) {
				//Session Timeout (and users clicks Live) or Invalid Meeting ID
				PrmLiveMtg.createXmlRedirect(null, SESSIONTIMEOUT, response);
				return;   
			}

			meetingManager mMgr = meetingManager.getInstance();
			meeting mtg = (meeting)mMgr.get(pstuser, midS);
			
			int[] bIds = new int[0];
			int myUid = pstuser.getObjectId();
			int selectedPjId = 0;
			String projId = request.getParameter(PROJID);
			PstAbstractObject[] projMember = null;
			bugManager bMgr = bugManager.getInstance();
			
			// Fetch user's and issue information from DB			
			if (projId!=null && projId.length()>0)
				selectedPjId = Integer.parseInt(projId);
			if (selectedPjId <= 0) {
				projMember = ((user)pstuser).getAllUsers();
				bIds = bMgr.findId(pstuser, "om_acctname='%'");
			}
			else {
				projMember = ((user)pstuser).getTeamMembers(selectedPjId);
				bIds = bMgr.findId(pstuser, "ProjectID='" + selectedPjId + "'");
			}
			// Finds all the none added attendees
			ArrayList newAttendeeList = getAttendeeList(projMember, myUid, mMgr, mtg);
			// Remove users that are already in the responsible list
			projMember = removeResponsible(projMember);
			// Create returning Xml
			createXml(projMember, bIds, myUid, newAttendeeList, response);
		} catch (PmpException e) {
			e.printStackTrace();
		}
	}
	
	/**
	 * Adds or Deletes the AC 
	 */
	public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
		PstUserAbstractObject pstuser = null;
		HttpSession httpSession = request.getSession(false);
		String midS = request.getParameter(MID);
		if (httpSession != null)
			pstuser = (PstUserAbstractObject)httpSession.getAttribute(PSTUSER);
		if (pstuser == null || midS == null) {
			//Session Timeout (and users clicks Live) or Invalid Meeting ID
			PrmLiveMtg.createXmlRedirect(null, SESSIONTIMEOUT, response);
			return;   
		}	
		
		// ECC debug option
		bDebug = request.getParameter("debug")!=null;
		
		// to check if session is OMF or PRM
		boolean isOMFAPP = false;
		String app = (String)httpSession.getAttribute("app");
		if (app.equals("OMF"))
			isOMFAPP = true;		
		
		try {			
			String type = request.getParameter("Type");
			String priority = request.getParameter("Priority");
			String subject = request.getParameter("Description");
			String ownerCompany = ((user)pstuser).getUserCompanyID();
			Date now = new Date();
			
			////////////////////////////////////////////////////
			// action/decision/issue item info: create new only
			String projIdS = request.getParameter(PROJID);
			String bugIdS = request.getParameter("BugId");
			String s;
			subject = removeEndBkSlash(subject);
			
			if (subject!=null && subject.length()>0)
			{	
				String owner = request.getParameter("Owner");
				if (type.equalsIgnoreCase("Issue"))
				{
					// issue
					bugManager bugMgr = bugManager.getInstance();
					bug bObj = (bug)bugMgr.create(pstuser);
	
					bObj.setAttribute("Synopsis", subject);
					bObj.setAttribute("Creator", owner);		// submitter
					bObj.setAttribute("Company", ownerCompany);
					bObj.setAttribute("State", bug.OPEN);
					bObj.setAttribute("Type", bug.CLASS_ISSUE);
					bObj.setAttribute("CreatedDate", now);
					bObj.setAttribute("Priority", priority);
					bObj.setAttribute("MeetingID", midS);
					bObj.setAttribute("ProjectID", projIdS);
	
					SimpleDateFormat df = new SimpleDateFormat ("MMMMMMMM dd, yyyy (EEE) hh:mm a");
					String myName = (String)pstuser.getAttribute("FirstName")[0];
					s = "<font color='#aa0000'><b>Issue Filed</b> by " + myName + " on " + df.format(now) + "</font>";
					bObj.setAttribute("Description", s.getBytes());
	
					bugMgr.commit(bObj);
					PrmUpdateCounter.updateOrCreateCounterArray(midS, ISINDEX);
				}
				else
				{
					// action or decision
					actionManager aMgr = actionManager.getInstance();
					action aiObj = (action)aMgr.create(pstuser);
	
					String [] respA = null;
					if (type.equals(action.TYPE_ACTION))
					{
						respA = request.getParameterValues("Responsible");
						for (int i=0; respA!=null && i<respA.length; i++)
						{
							aiObj.appendAttribute("Responsible", respA[i]);
						}
						String expire = request.getParameter("Expire");
						aiObj.setAttribute("ExpireDate", new Date(expire));
						aiObj.setAttribute("Owner", owner);
						aiObj.setAttribute("Status", action.OPEN);
						PrmUpdateCounter.updateOrCreateCounterArray(midS, AIINDEX);
					}
					else
						PrmUpdateCounter.updateOrCreateCounterArray(midS, DCINDEX);
	
					aiObj.setAttribute("Company", ownerCompany);
					aiObj.setAttribute("Type", type);
					aiObj.setAttribute("MeetingID", midS);
					aiObj.setAttribute("ProjectID", projIdS);
					aiObj.setAttribute("BugID", bugIdS);
					aiObj.setAttribute("Subject", subject);
					aiObj.setAttribute("CreatedDate", now);
					aiObj.setAttribute("Priority", priority);
					aMgr.commit(aiObj);
				}
			}
			// Check for Delete
			else {
				actionManager aMgr = actionManager.getInstance();
				bugManager bMgr = bugManager.getInstance();
				PstAbstractObject obj;
				String oidS;
				// Either delete or update status only: get the list of obj ids
				for (Enumeration e = request.getParameterNames() ; e.hasMoreElements() ;)
				{
					String temp = (String)e.nextElement();
					if (temp.startsWith("delete_"))
					{
						// delete action items or decisions
						oidS = temp.substring(7);
						try
						{
							obj = aMgr.get(pstuser, oidS);
							Object[] test = obj.getAttribute("Type");
							if(test[0].equals(action.TYPE_ACTION))
								PrmUpdateCounter.updateOrCreateCounterArray(midS, AIINDEX);
							else
								PrmUpdateCounter.updateOrCreateCounterArray(midS, DCINDEX);
							
							aMgr.delete(obj);
						}
						catch (PmpException ee)
						{
							// assume that the object is a bug
							obj = bMgr.get(pstuser, oidS);
							bMgr.delete(obj);
							PrmUpdateCounter.updateOrCreateCounterArray(midS, ISINDEX);

							// all actions that reference this bug needs to be cleared
							int [] ids = aMgr.findId(pstuser, "BugID='" + oidS + "'");
							for (int i=0; i<ids.length; i++)
							{
								obj = aMgr.get(pstuser, ids[i]);
								obj.setAttribute("BugID", null);
								aMgr.commit(obj);
							}
						}
					}
				}
			}
		} catch (PmpException e) {
			e.printStackTrace();
		}
		createXmlResponse(midS, pstuser, response, request, isOMFAPP);
	}
	
	/**
	 * This method creates the results after the recorder has add an AC. This method
	 * saves the current attendee's list, replies with an updated list of AC, and 
	 * fetches the updated attendee's list. Also checks to see if the current
	 * recorder still has the recorder status.
	 * @param midS
	 * @param pstuser
	 * @param response
	 * @param request
	 * @throws IOException
	 */
	private void createXmlResponse(String midS, 
			PstUserAbstractObject pstuser, 
			HttpServletResponse response, 
			HttpServletRequest request, 
			boolean isOMFAPP) 
	throws IOException {	
		try {
			int myUid = 0;
			int recorderId = 0; 
			boolean isRun = true; // Only Recorders can access this servlet
			int[] counter = new int[1]; // Used to give checkboxes a unique id; I need to pass by reference
			counter[0] = 0; // Counter starts 
			// get meeting object
			meetingManager mMgr = meetingManager.getInstance();
			meeting mtg = (meeting)mMgr.get(pstuser, midS);
			// Save current attendees checkbox
			PrmLiveMtg.saveAttendeeList(request, mtg);
			myUid = pstuser.getObjectId();
			// Find recorder ID
			String activeRecorder = (String)mtg.getAttribute(RECORDER)[0]; // active recorder
			if (activeRecorder != null)
				recorderId = Integer.parseInt(activeRecorder);
			
			// Create different html strings to report
			actionManager aMgr = actionManager.getInstance();
			// Get Action Items
			PstAbstractObject[] aiObjList = PrmLiveMtg.fetchActnDecnArray(pstuser, midS, action.TYPE_ACTION, aMgr);
			String aiObjString = PrmLiveMtg.createAITable(aiObjList, pstuser, isRun, midS, counter);
			// Get Decisions
			PstAbstractObject[] dsObjList = PrmLiveMtg.fetchActnDecnArray(pstuser, midS, action.TYPE_DECISION, aMgr);
			String dsObjString = PrmLiveMtg.createDSTable(dsObjList, pstuser, isRun, counter, isOMFAPP);
			// Get Issues
			PstAbstractObject[] bgObjList = PrmLiveMtg.fetchIssuesArray(pstuser, midS);
			String bgObjString = PrmLiveMtg.createISTable(bgObjList, pstuser, isRun, counter);
			// Get Present/Absent/Signed In Attendees
			ArrayList[] psNadLists = PrmLiveMtg.fetchPresentAttendeeList(mtg, myUid, mMgr);
			StringBuffer onlineStrBuf = new StringBuffer();
			String adObjString = PrmLiveMtg.createADTable(pstuser, psNadLists, isRun, midS, onlineStrBuf);
			Util.sortExUserList(pstuser, psNadLists[2]); // exchange the list of ids with list of users and sort
			
			mMgr.commit(mtg);
			
			if (recorderId!=myUid) // Not the recorder, status has been revoked by coordinator
				PrmLiveMtg.createXmlRedirect(REVOKEDRECORDER + new Date(), "mtg_live.jsp?mid="+midS, response);
			else
				PrmLiveMtg.createXml(null, aiObjString, dsObjString, bgObjString, null, null, null, null, adObjString, onlineStrBuf.toString(), psNadLists[2], recorderId, null, null, -1, response);
		
		} catch (PmpException e) {
			e.printStackTrace();
		}
	}
	
	/**
	 * Finds the current list of attendees that belong to this Project. 
	 * If the attendee is already in the meeting, then their name
	 * will not be included. 
	 * @param projMember
	 * @param myUid
	 * @param mMgr
	 * @param mtg
	 * @return
	 * @throws PmpException
	 */
	private ArrayList getAttendeeList(PstAbstractObject[] projMember, int myUid, meetingManager mMgr, meeting mtg) throws PmpException {
		// get attendee list
		Object [] attendeeArr = mtg.getAttribute(ATTENDEE);
		String [] sa;
		ArrayList attendeeList = new ArrayList();	// those who hasn't signed in yet
		ArrayList presentList = new ArrayList();	// those who has signed in
		boolean found = false;
		String s;
		user u;
		for (int i=0; i<attendeeArr.length; i++)
		{
			s = (String)attendeeArr[i];
			if (s == null) break;
			sa = s.split(meeting.DELIMITER);
			int aId = Integer.parseInt(sa[0]);

			// Technically this should never happen in the Ajax environment; The person
			// who calls this must be the recorder, and if the recorder is selectable
			// then he/she must have gone through this on the original call when they 
			// first logged on. Going to leave this here in case we will think about
			// calling this method when we make call in the jsp page. 
			if (aId == myUid)
			{
				if (!sa[1].endsWith(meeting.ATT_LOGON + meeting.ATT_PRESENT))
				{
					// I just logon
					mtg.removeAttribute("Attendee", s);
					s += meeting.ATT_LOGON + meeting.ATT_PRESENT;
					mtg.appendAttribute("Attendee", s);
					mMgr.commit(mtg);
				}
				presentList.add(sa[0]);		// I just signed in
				found = true;
				continue;
			}

			if (sa[1].endsWith(meeting.ATT_PRESENT))
				presentList.add(sa[0]);
			else
				attendeeList.add(sa[0]);
		}
		if (!found)
			presentList.add(String.valueOf(myUid));

		// get potential new attendee list
		ArrayList newAttendeeList = new ArrayList();
		int id;
		for (int i=0; i<projMember.length; i++)
		{
			u = (user)projMember[i];
			if (u == null) continue;

			id = u.getObjectId();
			found = false;
			for (int j=0; j<presentList.size(); j++)
			{
				if (id == Integer.parseInt((String)presentList.get(j)))
				{
					found = true;
					break;
				}
			}
			for (int j=0; !found && j<attendeeList.size(); j++)
			{
				if (id == Integer.parseInt((String)attendeeList.get(j)))
				{
					found = true;
					break;
				}
			}
			if (!found)
				newAttendeeList.add(u);
		}
		return newAttendeeList;
	}
	
	/**
	 * Removes user from the list who are already in the responsible list. However this
	 * method receives the people from a new object which is empty. 
	 * @param projMember
	 * @throws PmpException
	 * @return projMember Modified list with people who are already responsible null. 
	 */
	private PstAbstractObject[] removeResponsible(PstAbstractObject[] projMember) throws PmpException {
		int id = 0;
		Object [] responsibleIds = new Object[0]; 
		// null out ppl who are responsible
		//String [] fName = new String [responsibleIds.length];
		//String [] lName = new String [responsibleIds.length];
		if (responsibleIds.length>0 && responsibleIds[0]!=null)
		for (int i = 0; i < responsibleIds.length; i++)
		{
			id = Integer.parseInt((String)responsibleIds[i]);
			for (int j = 0; j < projMember.length; j++)
			{
				if (projMember[j] == null) continue;
				if (projMember[j].getObjectId() == id)
				{
					//fName[i] = (String)projMember[j].getAttribute(FIRSTNAME)[0];
					//lName[i] = (String)projMember[j].getAttribute(LASTNAME)[0];
					projMember[j] = null;
					break;
				}
			}
		}
		return projMember;
	}
	
	/**
	 * Create the return Xml document
	 * @param projMember
	 * @param bIds
	 * @param myUid
	 * @param newAttendeeList
	 * @param response
	 * @throws IOException
	 */
	private void createXml(PstAbstractObject[] projMember, int[] bIds, int myUid, ArrayList newAttendeeList, HttpServletResponse response) throws IOException {
		response.setContentType(XML_CONTENT);
		response.setHeader(XML_CACHECONTROL, XML_NOCACHE);
		response.getWriter().write(XML_RESPONSE_OP);
		createRSNames(projMember, myUid, response);
		createIBNames(bIds, response);
		createADNames(newAttendeeList, response);
		response.getWriter().write(XML_RESPONSE_CL);
	}

//*****************************
//* XML Creators
//*****************************
	
	/**
	 * Create list of names for responsible, and coordinator field
	 * @param projMember
	 * @param myUid
	 * @param response
	 * @throws IOException
	 */
	private void createRSNames(PstAbstractObject[] projMember, int myUid, HttpServletResponse response) throws IOException {
		String uName;
		int id;
		int counter = 0;
		
		try {
			if (projMember != null && projMember.length > 0)
			{
				for (int i=0; i < projMember.length; i++)
				{
					if (projMember[i] == null) continue;
					id = projMember[i].getObjectId();
					uName = ((user)projMember[i]).getFullName();
					if (id == myUid)
						response.getWriter().write(XML_RSSELECTED_OP+counter+XML_RESELECTED_CL);
					response.getWriter().write(XML_RSNAMEVALUE_OP+projMember[i].getObjectId()+XML_RSNAMEVALUE_CL);
					response.getWriter().write(XML_RSNAMETEXT_OP+Util.stringToHTMLString(uName, false)+XML_RSNAMETEXT_CL);
					counter++;
				} 
			} 
			else {
				response.getWriter().write(XML_RSEMPTY);
			}
		} catch (IOException e) {
			throw e;
		} catch (Exception e) {
			e.printStackTrace();
		} 
	}
	
	/**
	 * Create issue/bug Xml list
	 * @param bIds
	 * @param response
	 * @throws IOException
	 */
	private void createIBNames(int[] bIds, HttpServletResponse response) throws IOException {
		if (bIds != null && bIds.length > 0) {
			for (int i=0; i<bIds.length; i++)
				response.getWriter().write(XML_IBNAMETEXT_OP+bIds[i]+XML_IBNAMETEXT_CL);
		}
		else
			response.getWriter().write(XML_IBEMPTY);
	}
	
	/**
	 * Create attendees' names to be returned to XML
	 * @param newAttendeeList
	 * @param response
	 * @throws IOException
	 */
	private void createADNames(ArrayList newAttendeeList, HttpServletResponse response) throws IOException {
		user u;
		int id;
		String uName;
		if (newAttendeeList != null && newAttendeeList.size() > 0) {
			for (int i=0; i<newAttendeeList.size(); i++)
			{
				u = (user)newAttendeeList.get(i);
				id = u.getObjectId();
				uName = u.getFullName();
				response.getWriter().write(XML_ADNAMETEXT_OP+Util.stringToHTMLString(uName, false)+XML_ADNAMETEXT_CL);
				response.getWriter().write(XML_ADNAMEVALUE_OP+id+XML_ADNAMEVALUE_CL);
			}
		}
		else {
			response.getWriter().write(XML_ADEMPTY);
		}
	}
	
//************************
//* Helpers
//************************
	private String removeEndBkSlash(String subject) {
		if(subject != null) {
			int i;
			int length = subject.length()-1;
			for(i = length; i >= 0; i--) {
				if(subject.charAt(i) != '\\')
					break;
			}
			if(i < length)
				subject = subject.substring(0, i+1);
		}
		return subject;
	}
}	
