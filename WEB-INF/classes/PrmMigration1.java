//
///////////////////////////////////////////////////////////////////////////////////////////
//
//	File:		PrmMigration.java
//	Author:		ECC
//	Date:		10/25/2006
//	Description:
//			Migrate objects from one PRM database to another.  Particularly user and
//			meeting objects and the related objects such as actions.
//
//	Modification:
//
///////////////////////////////////////////////////////////////////////////////////////////
//

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Random;

import oct.codegen.actionManager;
import oct.codegen.attachmentManager;
import oct.codegen.meetingManager;
import oct.codegen.townManager;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.codegen.userinfoManager;
import oct.omm.client.OmsMember;
import oct.omm.client.OmsOrganization;
import oct.omm.client.OmsSession;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstManager;

/* This class follows PrmMigration.java.  This is used when the first migration has been deployed but there are
 * left-over work that needs to be done.  The meetings are all there but there are newer info added since the migration
 * last time.  As a result, we cannot re-create the meetings.
 * In this instance, we need to add the old action items to the old meetings.
 */

public class PrmMigration1
{
	private static final String [] BAD_USER = {"kkcchong", "ksato", "elin", "takaogi", "prmext"};
	private static final Date now = new Date();
	private static Random rand = new Random(12345);
	private static int docMigrated = 0;
	private static String townID;

	private static HashMap userNameHash = new HashMap(500);
	private static HashMap userIdHash = new HashMap(500);
	private static HashMap mtgHash = new HashMap(700);

	private static userManager uMgr;
	private static meetingManager mMgr;
	private static attachmentManager attMgr;
	private static actionManager actMgr;
	private static userinfoManager uiMgr;

	private static user user1;		// source db user
	private static user user2;		// target db user

	public static void main(String[] args)
		throws Exception
	{
		// connect to two separate databases as special user

		// OMF (source)
		OmsSession session = new OmsSession();
		System.out.println("Connecting to OmfPool");
		session.connect("SpansionPool", "user", "prmus3r", "john155");
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
		actMgr = actionManager.getInstance();
		uiMgr = userinfoManager.getInstance();

		int [] ids;
		int count;

		//test
		ids = uMgr.findId(user1, "om_acctname='%'");
		System.out.println("total users in Spansion = "+ ids.length);
		ids = uMgr.findId(user2, "om_acctname='%'");
		System.out.println("total users in BringUp = "+ ids.length);

		// set up TownID for the company
		townID = String.valueOf(townManager.getInstance().get(user2, "Spansion").getObjectId());

		// build userID and meeting ID hash
		buildUserHash();
		//buildMtgHash();

		count = 0;
		int [] ids1;
		int [] ids2;
		String uname;
		PstAbstractObject o;
		
		// go through all members and see if userinfo exists, if not, create it now
		ids = uMgr.findId(user2, "om_acctname='%'");
		for (int i=0; i<ids.length; i++)
		{
			ids1 = uiMgr.findId(user2, "om_acctname='" + ids[i] + "'");
			if (ids1.length == 0)
			{
				// need to create and copy userinfo
				uname = uMgr.get(user2, ids[i]).getObjectName();
				try {
					int id = uMgr.get(user1, uname).getObjectId();
					createCopy(uiMgr, uiMgr.get(user1, String.valueOf(id)), String.valueOf(ids[i]), true);
				} catch (PmpException e) {System.out.println("*** fail to get " + uname); continue;}
			}
		}

		// go through all meetings and migrate their action items into the target db
		ids = mMgr.findId(user1, "om_acctname='%'");
		for (int i=0; i<ids.length; i++)
		{
			ids1 = actMgr.findId(user1, "MeetingID='" + ids[i] + "'");
			if (ids1.length <= 0) continue;

			// there is action item with this old meeting: migrate
			for (int j=0; j<ids1.length; j++)
			{
				createCopy(actMgr, actMgr.get(user1, ids1[j]), true);
				count++;
			}
		}


		System.out.println("DONE");
	}

	private static void buildUserHash()
		throws PmpException
	{
		String name;
		PstAbstractObject o, newO;
		int count = 0;

		int [] ids = uMgr.findId(user1, "om_acctname='%'");
		for (int i=0; i<ids.length; i++)
		{
			o = uMgr.get(user1, ids[i]);
			name = o.getObjectName();
			if (checkIgnore(BAD_USER, name))
				continue;

			newO = uMgr.get(user2, name);
			if (newO != null)
			{
				userIdHash.put(String.valueOf(ids[i]), String.valueOf(newO.getObjectId()));
				count++;
			}
			else
				System.out.println("***** ***** User [" + ids[i] + "] not found.");
		}
		System.out.println("Total " + count + " user hashed.");
	}

	private static void buildMtgHash()
		throws PmpException
	{
		String name, owner;
		Date dt;
		SimpleDateFormat df = new SimpleDateFormat ("yyyy.MM.dd.HH.mm.ss");
		PstAbstractObject o, newO;
		int count = 0;
		int [] ids1;

		int [] ids = mMgr.findId(user1, "om_acctname='%'");
		for (int i=0; i<ids.length; i++)
		{
			o = mMgr.get(user1, ids[i]);
			name = (String)o.getAttribute("Subject")[0];
			owner = (String)o.getAttribute("Owner")[0];
			owner = (String)userIdHash.get(owner);
			dt = (Date)o.getAttribute("StartDate")[0];
			ids1 = mMgr.findId(user2, "StartDate='" + df.format(dt) + "' && Subject='" + name + "' && Owner='" + owner + "'");
			if (ids1.length > 0)
			{
				if (ids1.length > 1)
					System.out.println("***** ***** There are more than 1 meeting of the same name on the same day ["+ ids1[0] + "]");
				newO = mMgr.get(user2, ids1[0]);
				mtgHash.put(String.valueOf(ids[i]), newO.getObjectName());
				count++;
			}
			else
				System.out.println("***** ***** Meeting [" + ids[i] + "] not found.");
		}
		System.out.println("Total " + count + " meeting hashed.");
	}

	private static String createCopy(PstManager mgr, PstAbstractObject obj, boolean bPrint)
	throws PmpException
	{
		return createCopy(mgr, obj, null, bPrint);
	}
	
	// return the new object Id as String
	private static String createCopy(PstManager mgr, PstAbstractObject obj, String newName, boolean bPrint)
		throws PmpException
	{
		// create the same organization object and copy the attriute value
		PstAbstractObject newObj = null;
		String name, passwd;
		String [] attNames = null;

		name = obj.getObjectName();

		if (mgr instanceof userManager)
		{
			// create user object
			attNames = ((userManager)mgr).getAllAttributeNames();
			passwd = (String)userNameHash.get(name);
			newObj = ((userManager)mgr).create(user2, name, passwd);
			userIdHash.put(String.valueOf(obj.getObjectId()), String.valueOf(newObj.getObjectId()));
		}
		else if (mgr instanceof meetingManager)
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
			// create action item
			attNames = ((actionManager)mgr).getAllAttributeNames();
			newObj = ((actionManager)mgr).create(user2);
		}
		else if (mgr instanceof userinfoManager)
		{
			// create userinfo
			attNames = ((userinfoManager)mgr).getAllAttributeNames();
			newObj = ((userinfoManager)mgr).create(user2, newName);
		}

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
		String idS, s, temp;
		Object [] oArr;
		int idx;
		Integer one = new Integer(1);

		if (mgr instanceof userManager)
		{
			// 1. for user, update Company
			newObj.setAttribute("TownID", townID);
			// newObj.setAttribute("Picture", (byte[])obj.getAttribute("Picture")[0]);	// obsolete attribute, now use PictureFile
			newObj.setAttribute("HireDate", now);
		}
		else if (mgr instanceof meetingManager)
		{
			// 2. for meeting: change Owner, Recorder and Attendee
			newObj.setAttribute("Note", (byte[])obj.getAttribute("Note")[0]);
			newObj.setAttribute("Type", "Private");
			temp = (String)newObj.getAttribute("Owner")[0];
			idS = (String)userIdHash.get(temp);
			if (idS != null)
				newObj.setAttribute("Owner", idS);
			else
				System.out.println("!!!!! ***** ***** Translating owner [" + temp + "] is null");
			idS = (String)userIdHash.get((String)newObj.getAttribute("Recorder")[0]);
			if (idS == null)
				idS = (String)newObj.getAttribute("Owner")[0];
			newObj.setAttribute("Recorder", idS);

			// Attendees
			oArr = newObj.getAttribute("Attendee");
			for (int i=0; i<oArr.length; i++)
			{
				if ((s = (String)oArr[i]) == null) continue;
				newObj.removeAttribute("Attendee", s);
				idx = s.indexOf("::");
				temp = s.substring(0, idx);
				idS = (String)userIdHash.get(temp);	// translate the userId
				if (idS == null)
				{
					//System.out.println("***** ***** Translating attendee [" + temp + "] is null");
					continue;
				}
				s = idS + s.substring(idx);
				newObj.appendAttribute("Attendee", s);
			}

			// Agenda
			oArr = newObj.getAttribute("AgendaItem");
			for (int i=0; i<oArr.length; i++)
			{
				if ((s = (String)oArr[i]) == null) continue;
				idx = s.lastIndexOf("::")+2;
				idS = (String)userIdHash.get(s.substring(idx));	// translate the userId
				if (idS == null)
				{
					//System.out.println("***** ***** An agenda owner is null: substitute w/ meeting owner");
					idS = (String)newObj.getAttribute("Owner")[0];
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
		}
		else if (mgr instanceof attachmentManager)
		{
			// translate AccessedBy  ECC: commented out because AccessedBy changed to ViewBy
			/*s = (String)newObj.getAttribute("AccessedBy")[0];
			if (s != null)
			{
				idS = (String)userIdHash.get(s);
				if (idS != null)
					newObj.setAttribute("AccessedBy", idS);
				else
					System.out.println("***** ***** Failed to translate accessed by [" + s + "] for attachment [" + newObj.getObjectId() + "]");
			}*/

			// Owner
			s = (String)newObj.getAttribute("Owner")[0];
			idS = (String)userIdHash.get(s);
			if (idS != null)
				newObj.setAttribute("Owner", idS);
			else
				System.out.println("***** ***** Translating attachment owner [" + s + "] is null");

			// Location
			s = (String)obj.getAttribute("Location")[0];
			newObj.setAttribute("Location", "http://prm/servlet/ShowFile?filePath=" + s);

			newObj.setAttribute("ProjectID", null);
		}
		else if (mgr instanceof actionManager)
		{
			// meeting ID
			s = (String)newObj.getAttribute("MeetingID")[0];
			idS = (String)mtgHash.get(s);
			if (idS != null)
				newObj.setAttribute("MeetingID", idS);
			else
				System.out.println("***** ***** Translating action meetingID [" + s + "] is null");

			// Owner
			s = (String)newObj.getAttribute("Owner")[0];
			idS = (String)userIdHash.get(s);
			if (idS != null)
				newObj.setAttribute("Owner", idS);			// decisions has no id

			// Responsible
			oArr = newObj.getAttribute("Responsible");
			for (int i=0; i<oArr.length; i++)
			{
				if ((s = (String)oArr[i]) == null) continue;
				newObj.removeAttribute("Responsible", s);
				idS = (String)userIdHash.get(s);
				if (idS != null)
					newObj.appendAttribute("Responsible", idS);
			}

			newObj.setAttribute("ProjectID", null);
			newObj.setAttribute("BugID", null);
		}

		mgr.commit(newObj);

		if (bPrint)
			System.out.println("Created and updated [" + newObj.getObjectName() + "]");
		return (String.valueOf(newObj.getObjectId()));
	}

	private static boolean checkIgnore(String[] ignores, String name)
	{
		for (int i=0; i<ignores.length; i++)
			if (name.equals(ignores[i])) return true;
		return false;
	}

	private static Integer getRandom(int min, int bound)
	{
		return (new Integer(min + rand.nextInt(bound)));
	}

}
