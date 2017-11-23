//
///////////////////////////////////////////////////////////////////////////////////////////
//
//	File:		PrmCopy.java
//	Author:		ECC
//	Date:		10/01/2008
//	Description:
//			Copy objects from one PRM database to another.
//
//	Modification:
//
///////////////////////////////////////////////////////////////////////////////////////////
//

import java.util.Date;
import java.util.HashMap;
import java.util.Random;

import oct.codegen.actionManager;
import oct.codegen.attachmentManager;
import oct.codegen.meetingManager;
import oct.codegen.resultManager;
import oct.codegen.townManager;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.omm.client.OmsMember;
import oct.omm.client.OmsOrganization;
import oct.omm.client.OmsSession;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstManager;

public class PrmCopy
{
	private static final Date now = new Date();
	private static Random rand = new Random(12345);
	private static int docMigrated = 0;
	private static String townID;
	private static String myUidS;
	private static String [] userIdArr;

	private static HashMap mtgHash = new HashMap(700);
	private static HashMap blogHash = new HashMap(100);
	private static HashMap actionHash = new HashMap(100);

	private static userManager uMgr;
	private static meetingManager mMgr;
	private static attachmentManager attMgr;
	private static actionManager aMgr;
	private static resultManager rMgr;

	private static user user1;		// source db user
	private static user user2;		// target db user

	public static void main(String[] args)
		throws Exception
	{
		// take an object ID of the source db and create the object and copy that to the target db
		// this is for meeting organization: you should enter the object ID of the first meeting in a list of mtg
		if (args.length < 1)
		{
			System.out.println("Usage: java PrmCopy 12345 - where 12345 is the ID of the object to be copied.");
			return;
		}
		String mtgIdS = args[0];
		
		// connect to two separate databases as special user

		// OMF (source)
		OmsSession session = new OmsSession();
		System.out.println("Connecting to OmfPool");
		session.connect("OmfPool", "user", "prmus3r", "john155");
		OmsOrganization org = new OmsOrganization(session, "user");
		OmsMember member = new OmsMember( session, org, "prmus3r" );
		user1 = new user(member);

		// BringUp (target)
		session = new OmsSession();
		System.out.println("Connecting to BringUpPool");
		session.connect("BringUpPool", "user", "prmus3r", "john155");
		org = new OmsOrganization(session, "user");
		member = new OmsMember( session, org, "prmus3r" );
		user2 = new user(member);

		uMgr = userManager.getInstance();
		mMgr = meetingManager.getInstance();
		attMgr = attachmentManager.getInstance();
		aMgr = actionManager.getInstance();
		rMgr = resultManager.getInstance();

		int [] ids;
		int count;

		//test
		ids = uMgr.findId(user1, "om_acctname='%'");
		System.out.println("total users in OMF = "+ ids.length);
		ids = uMgr.findId(user2, "om_acctname='%'");
		System.out.println("total users in BringUp = "+ ids.length);

		// set up TownID for the company
		townID = String.valueOf(townManager.getInstance().get(user2, "EGI").getObjectId());
		
		// get myself (edwardc@egiomm.com)
		user me = (user)uMgr.get(user2, "edwardc@egiomm.com");
		int myUid = me.getObjectId();
		myUidS = String.valueOf(myUid);
		
		// use a group of users as attendee
		PstAbstractObject o;
		String [] users = {"edwardc@egiomm.com", "khemperly@comcast.net", "dlee@orrick.com", "dmazepink@mac.com",
				"eddie.lo@gmail.com", "alin@orrick.com"};
		userIdArr = new String[users.length];
		for (int i=0; i<users.length; i++)
		{
			o = uMgr.get(user2, users[i]);
			userIdArr[i] = String.valueOf(o.getObjectId());
		}


		//////////////////////////////////////////////////////
		// migrate meetings based on input object ID
		count = 0;
		String recur;
		String [] sa;
		while (mtgIdS != null)
		{
			o = mMgr.get(user1, mtgIdS);

			// copy over meeting object
			createCopy(mMgr, o, true);	// also migrate (Attendee, Owner, Recorder) and AgendaItem
			count++;

			// migrate Recurring
			recur = (String)o.getAttribute("Recurring")[0];
			if (recur == null) break;
			sa = recur.split("::");
			if (sa.length < 3) break;
			mtgIdS = sa[2];
		}
		System.out.println("Total meetings migrated = " + count);

		// fix recurring: can only be done after all meetings are processed
		int idx;
		String idS, s;
		count = 0;
		ids = mMgr.findId(user2, "om_acctname='%'");
		for (int i=0; i<ids.length; i++)
		{
			o = mMgr.get(user2, ids[i]);

			if ((s = (String)o.getAttribute("Recurring")[0]) != null)
			{
				// Recurring
				idx = s.lastIndexOf("::")+2;
				idS = s.substring(idx);
				if (idS.length() != 5) continue;	// not our IDs
				idS = (String)mtgHash.get(idS);		// translate the meeting id
				if (idS == null)
				{
					System.out.println("***** ***** Failed to translate recurring ID [" + s.substring(idx) + "] for meeting [" + o.getObjectId() + "]");
					o.setAttribute("Recurring", null);
				}
				else
				{
					s = s.substring(0, idx) + idS;
					o.setAttribute("Recurring", s);
				}
				mMgr.commit(o);
				count++;
			}
		}
		System.out.println("Fixed recurring reference = " + count);

		// copy/create/change actions

		//////////////////////////////////////////////////////
		// migrate document attachments
		System.out.println("Doc link migrated = "+ docMigrated);

		System.out.println("DONE");
	}



	// return the new object Id as String
	public static String createCopy(PstManager mgr, PstAbstractObject obj, boolean bPrint)
		throws PmpException
	{
		// create the same organization object and copy the attriute value
		PstAbstractObject newObj = null;
		String [] attNames = null;

		System.out.print("copying " + mgr.getOrgname() + ": ");
		if (mgr instanceof meetingManager)
		{
			// create meeting
			attNames = ((meetingManager)mgr).getAllAttributeNames();
			newObj = ((meetingManager)mgr).create(user2);
			mtgHash.put(String.valueOf(obj.getObjectId()), String.valueOf(newObj.getObjectId()));
		}
		else if (mgr instanceof attachmentManager)
		{
			// create attachment
			attNames = ((attachmentManager)mgr).getAllAttributeNames();
			newObj = ((attachmentManager)mgr).create(user2);
		}
		else if (mgr instanceof actionManager)
		{
			// create action
			attNames = ((actionManager)mgr).getAllAttributeNames();
			newObj = ((actionManager)mgr).create(user2);
			actionHash.put(String.valueOf(obj.getObjectId()), String.valueOf(newObj.getObjectId()));
		}
		else if (mgr instanceof resultManager)
		{
			// create blog
			attNames = ((resultManager)mgr).getAllAttributeNames();
			newObj = ((resultManager)mgr).create(user2);
			blogHash.put(String.valueOf(obj.getObjectId()), String.valueOf(newObj.getObjectId()));
		}
		System.out.println(obj.getObjectId() + " to " + newObj.getObjectId());

		// copy values
		String attName;
		for (int i=0; i<attNames.length; i++)
		{
			// copy each value over from old to new object
			attName = attNames[i];
			//System.out.print(attName + ": ");
			try
			{
				//System.out.println(obj.getAttribute(attName)[0]);
				newObj.setAttribute(attName, obj.getAttribute(attName));
			}
			catch (PmpException e) {/*System.out.println("no such attribute [" + attName + "]");*/}
		}

		// handle special case
		String idS, s;
		Object [] oArr;
		int idx;
		Integer one = new Integer(1);

		if (mgr instanceof userManager)
		{
			// 1. for user, update Company
			newObj.setAttribute("TownID", townID);
			//newObj.setAttribute("Picture", (byte[])obj.getAttribute("Picture")[0]);	// obsolete attribute, now use PictureFile
			newObj.setAttribute("HireDate", now);
		}
		else if (mgr instanceof meetingManager)
		{
			// 2. for meeting: change Owner, Recorder and Attendee
			newObj.setAttribute("Note", (byte[])obj.getAttribute("Note")[0]);
			newObj.setAttribute("Type", "Private");
			newObj.setAttribute("Owner", myUidS);
			newObj.setAttribute("Recorder", myUidS);

			// Attendees
			oArr = newObj.getAttribute("Attendee");
			newObj.setAttribute("Attendee", null);
			for (int i=0; i<oArr.length; i++)
			{
				if ((s = (String)oArr[i]) == null) continue;
				if (i >= userIdArr.length) break;
				idx = s.indexOf("::");
				idS = userIdArr[i];				// translate the userId
				s = idS + s.substring(idx);
				newObj.appendAttribute("Attendee", s);
			}

			// Agenda
			oArr = newObj.getAttribute("AgendaItem");
			for (int i=0; i<oArr.length; i++)
			{
				if ((s = (String)oArr[i]) == null) continue;
				idx = s.lastIndexOf("::")+2;
				idS = s.substring(idx);			// translate the userId
				int iVal = Integer.parseInt(idS);
				if (iVal < 100)
				{
					//System.out.println("***** ***** An agenda owner is null: substitute w/ meeting owner");
					idS = (String)newObj.getAttribute("Owner")[0];
				}
				else
				{
					idS = userIdArr[getRandom(0, userIdArr.length-1).intValue()];
				}
				s = s.substring(0, idx) + idS;
				newObj.removeAttribute("AgendaItem", oArr[i]);
				newObj.appendAttribute("AgendaItem", s);
			}

			// AttachmentID
			oArr = newObj.getAttribute("AttachmentID");
			PstAbstractObject oldAtt;
			for (int i=0; i<oArr.length; i++)
			{
				if ((s = (String)oArr[i]) == null) continue;
				oldAtt = attMgr.get(user1, s);
				idS = createCopy(attMgr, oldAtt, true);
				newObj.removeAttribute("AttachmentID", s);
				newObj.appendAttribute("AttachmentID", idS);
				docMigrated++;
			}

			// TownID (company) attribute on meeting
			newObj.setAttribute("TownID", townID);

			// ViewBlogNum
			if (newObj.getAttribute("Status")[0].equals("New"))
				newObj.setAttribute("ViewBlogNum", one);
			else
				newObj.setAttribute("ViewBlogNum", getRandom(5, 100));
			
			// action/decision
			PstAbstractObject aObj;
			int [] ids = aMgr.findId(user1, "MeetingID='" + obj.getObjectId() + "'");
			for (int i=0; i<ids.length; i++)
			{
				aObj = aMgr.get(user1, ids[i]);
				createCopy(aMgr, aObj, true);
			}
			
			// meeting blog
			PstAbstractObject bObj;
			ids = rMgr.findId(user1, "TaskID='" + obj.getObjectId() + "'");
			for (int i=0; i<ids.length; i++)
			{
				bObj = rMgr.get(user1, ids[i]);
				createCopy(rMgr, bObj, true);
			}
		}
		else if (mgr instanceof attachmentManager)
		{
			// translate ViewBy (ECC: used to be AccessedBy)
			newObj.setAttribute("ViewBy", null);

			// Owner
			newObj.setAttribute("Owner", myUidS);

			// Location
			s = (String)obj.getAttribute("Location")[0];
			newObj.setAttribute("Location", "http://cr.egiomm.com/servlet/ShowFile?filePath=" + s);

			newObj.setAttribute("ProjectID", null);
		}
		else if (mgr instanceof actionManager)
		{
			idS = (String)newObj.getAttribute("MeetingID")[0];
			idS = (String)mtgHash.get(idS);		// translate the meeting id
			newObj.setAttribute("MeetingID", idS);
			newObj.setAttribute("Owner", myUidS);

			// Responsible
			oArr = newObj.getAttribute("Responsible");
			for (int i=0; i<oArr.length; i++)
			{
				if ((s = (String)oArr[i]) == null) continue;
				idS = userIdArr[getRandom(0, userIdArr.length-1).intValue()];
				newObj.removeAttribute("Responsible", oArr[i]);
				newObj.appendAttribute("Responsible", idS);
			}
			
			// action blog
			PstAbstractObject bObj;
			int [] ids = rMgr.findId(user1, "TaskID='" + obj.getObjectId() + "'");
			for (int i=0; i<ids.length; i++)
			{
				bObj = rMgr.get(user1, ids[i]);
				createCopy(rMgr, bObj, true);
			}
		}
		else if (mgr instanceof resultManager)
		{
			newObj.setAttribute("Comment", (byte[])obj.getAttribute("Comment")[0]);
			idS = (String)newObj.getAttribute("TaskID")[0];
			s = (String)mtgHash.get(idS);				// translate the meeting id
			if (s == null)
				s = (String)actionHash.get(idS);		// translate the action id
			newObj.setAttribute("TaskID", s);
			idS = userIdArr[getRandom(0, userIdArr.length-1).intValue()];
			newObj.setAttribute("Creator", idS);
		}

		mgr.commit(newObj);

		if (bPrint)
			System.out.println("Created and updated [" + newObj.getObjectName() + "]");
		return (String.valueOf(newObj.getObjectId()));
	}

	private static Integer getRandom(int min, int bound)
	{
		return (new Integer(min + rand.nextInt(bound)));
	}

}
