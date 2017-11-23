//
///////////////////////////////////////////////////////////////////////////////////////////
//
//	File:		PrmMigration.java
//	Author:		ECC
//	Date:		10/25/2006
//	Description:
//			Migrate objects from one PRM database to another.  Particularly user, project and
//			meeting objects and the related objects such as actions.  For migration of project,
//			it supports migrating one specified project only.
//
//	Modification:
//			@011201ECC	Roll forward all dates to support a more recently dated demo.
//						Allow the option of only copying users appeared in meetings.
//
//	Note:
//			*** It is important that in pst.properties, you need to set the PoolName to the target pool name.
//			The attribute Ids, which is taken from the manager objects, are taken from this pool.  When
//			committing the creation and changes to the target object, if these attribute ids are not from
//			the target pool, it might be wrong.
//
///////////////////////////////////////////////////////////////////////////////////////////
//

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.Random;

import oct.codegen.actionManager;
import oct.codegen.attachmentManager;
import oct.codegen.meetingManager;
import oct.codegen.plan;
import oct.codegen.planManager;
import oct.codegen.planTaskManager;
import oct.codegen.project;
import oct.codegen.projectManager;
import oct.codegen.resultManager;
import oct.codegen.task;
import oct.codegen.taskManager;
import oct.codegen.townManager;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.omm.client.OmsMember;
import oct.omm.client.OmsOrganization;
import oct.omm.client.OmsSession;
import oct.pmp.exception.PmpException;
import oct.pmp.exception.PmpObjectCreationException;
import oct.pmp.exception.PmpUnsupportedTypeException;
import oct.pst.PstAbstractObject;
import oct.pst.PstFlowStep;
import oct.pst.PstFlowStepManager;
import oct.pst.PstManager;

public class PrmMigration
{
	// *** option constants: set this up before compiling and running
	private static final boolean bNeedUserNameHash = false;	// set to true if you have user.txt for name/password insert
	private static final boolean bMigrateAllUsers = true;
	private static final boolean bMigrateProj = true;
	private static final boolean bEmailUserName = false;	// target DB using email username?
	
	private static final int MIGRATE_PROJ_ID	= 123477;	// The project to be migrated: Crystal Oscillator
	private static final String defaultOwnerId = "33075";	// 39412 for MeetWE
	
	private static final String [] newMtgAttendee = {"39412", "58966"};
	private static final String mtgProjID = "59403";
	private static final String emailDomain = "@smartchip.com";
	private static final String exprMtg = 		//"om_acctname='%'";
		"(StartDate>'2005.01.01' && StartDate<'2006.3.31' && Type='Private' && TownID='58922')";
	
	// *** the above constants must be set before running
	////////////////////////////
	
	
	////////////////////////////
	private static final String [] mtgDateField = {"StartDate", "ExpireDate", "EffectiveDate", "CompleteDate", "LastUpdatedDate"};
	private static final String USER_FILE_NAME = "user.txt";
	private static final String [] BAD_USER = {}; //{"kkcchong", "ksato", "elin", "takaogi"};
	private static final int MAX_MTG_ATTENDEE = 20;	// preferred upper limit of attendees in meetings
	private static Random rand = new Random(12345);
	private static int docMigrated = 0;
	private static int userMigrated = 0;
	private static int mtgMigrated = 0;
	private static int actionMigrated = 0;
	private static String targetTownIdS = "10007";		// the company ID from target db

	private static HashMap <String,String> userNameHash = new HashMap<String,String>(500);	// user/passwd
	private static HashMap <String,String> userIdHash = new HashMap<String,String>(500);
	private static HashMap <String,String> mtgHash = new HashMap <String,String>(700);

	private static userManager uMgr;
	private static meetingManager mMgr;
	private static attachmentManager attMgr;
	private static actionManager actMgr;
	private static projectManager pjMgr;
	private static planManager plMgr;
	private static taskManager tkMgr;
	private static planTaskManager ptMgr;
	private static resultManager rMgr;
	private static PstFlowStepManager fsMgr;

	private static user user1;		// source db user
	private static user user2;		// target db user

	public static void main(String[] args)
		throws Exception
	{
		// connect to two separate databases as special user
		if (args.length < 2)
		{
			System.out.println("Usage 1: runtool PrmMigrateion SourcePool TargetPool\n");
			return;
		}
		
		System.out.println("Migrating OMM objects from " + args[0] + " to " + args[1] + "\n-----------\n");

		// (source)
		OmsSession session = new OmsSession();
		System.out.println("Connecting to source: " + args[0]);
		session.connect(args[0], "user", "prmus3r", "john155");
		OmsOrganization org = new OmsOrganization(session, "user");
		OmsMember member = new OmsMember(session, org, "prmus3r");
		user1 = new user(member);

		// (target)
		session = new OmsSession();
		System.out.println("Connecting to target: " + args[1]);
		session.connect(args[1], "user", "prmus3r", "john155");
		org = new OmsOrganization(session, "user");
		member = new OmsMember(session, org, "prmus3r");
		user2 = new user(member);

		uMgr = userManager.getInstance();
		mMgr = meetingManager.getInstance();
		attMgr = attachmentManager.getInstance();
		actMgr = actionManager.getInstance();
		pjMgr = projectManager.getInstance();
		tkMgr = taskManager.getInstance();
		plMgr = planManager.getInstance();
		ptMgr = planTaskManager.getInstance();
		rMgr = resultManager.getInstance();
		fsMgr = PstFlowStepManager.getInstance();

		int [] ids;
		int count;

		//test
		ids = uMgr.findId(user1, "om_acctname='%'");
		System.out.println("total users in Source = "+ ids.length);
		ids = uMgr.findId(user2, "om_acctname='%'");
		System.out.println("total users in Target = "+ ids.length);
		
		// set up TownID for the company
		if (targetTownIdS == null) {
			targetTownIdS = String.valueOf(townManager.getInstance().get(user2, "EGI").getObjectId());
		}
		
		// read and build user/passwd hash from source
		if (bNeedUserNameHash && !builduserNameHash())
			return;
		
		// set up mapping of users between two DB (source -> target)
		//userIdHash.put("39412",	"39412");	// echeng
		//userIdHash.put("39009", "58966");	// ccyee

		/////////////////////////////////////////////
		// migrate user
		// check for collision in user name and/or email addr
		// a hash will be built to map userId from source to target
		if (bMigrateAllUsers)
			migrateUser();

		////////////////////////////////////////////////////////
		// code to migrate a project and its assoc objects
		if (bMigrateProj) {
			int pid = MIGRATE_PROJ_ID;
			migrateProject(pid);
			return;
		}
		
		//
		// ****  go beyond here only if we want to migrate meeting
		//

		//////////////////////////////////////////////////////
		// migrate meetings
		PstAbstractObject o;
		count = 0;
		ids = mMgr.findId(user1, exprMtg);
		for (int i=0; i<ids.length; i++)
		{
			o = mMgr.get(user1, ids[i]);

			// copy over meeting object
			createCopy(mMgr, o, true);	// also migrate (Attendee, Owner, Recorder) and AgendaItem
		}

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

		// go through all meetings and migrate their action items into the target db
		ids = mMgr.findId(user1, exprMtg);
		int [] ids1;
		for (int i=0; i<ids.length; i++)
		{
			ids1 = actMgr.findId(user1, "MeetingID='" + ids[i]
			                          + "' && ExpireDate>='2005.10.15'");
			if (ids1.length <= 0) continue;

			// there is action item with this old meeting: migrate
			for (int j=0; j<ids1.length; j++)
			{
				createCopy(actMgr, actMgr.get(user1, ids1[j]), true);
				count++;
			}
		}

		//////////////////////////////////////////////////////
		System.out.println("User   migrated     = " + userMigrated);
		System.out.println("Mtg    migrated     = " + mtgMigrated);
		System.out.println("Action migrated     = " + actionMigrated);
		System.out.println("Doc link migrated = "+ docMigrated);

		System.out.println("DONE");
	}

	private static void migrateProject(int pid)
		throws PmpException
	{
		// migrate the project to target DB
		System.out.println(">>> Start migrateProject()");
		PstAbstractObject o = pjMgr.get(user1, pid);
		createCopy(pjMgr, o, false);
		System.out.println(">>> End migrateProject()");
	}

	// migrateUser()
	private static void migrateUser() throws PmpException
	{
		PstAbstractObject o, oo;
		String oName;
		int [] ids1;
		System.out.println(">>> Start migrateUser()");
		
		int [] ids = uMgr.findId(user1, "om_acctname='%'");		// source
		for (int i=0; i<ids.length; i++)
		{
			o = uMgr.get(user1, ids[i]);
			oName = o.getObjectName();
			if (checkIgnore(BAD_USER, oName)) continue;

			ids1 = uMgr.findId(user2, "om_acctname='" + oName + "'");	// target
			if (ids1.length > 0)
			{
				// this would only be possible if the two DB have same user format
				System.out.println("********** Found same user [" +oName+ "] - no need to copy - simply hashed");
				userIdHash.put(String.valueOf(ids[i]), String.valueOf(ids1[0]));	// hashmap userId: source to target
				continue;
			}
			ids1 = uMgr.findId(user2, "Email='" + o.getAttribute("Email")[0] + "'");
			if (ids1.length > 0)
			{
				oo = uMgr.get(user2, ids1[0]);
				System.out.println("********** !! Found " + ids1.length + " duplicate Email for user [" +oName+ ", " + oo.getObjectName() + "]["
					+ o.getAttribute("Email")[0] + "]");
				continue;
			}
			// copy over user object
			if (bMigrateAllUsers)
			{
				System.out.println("Start migrate new user [" + oName + "] in migrateUser()");
				createCopy(uMgr, o, false);		// will save to hashmap
			}
		}
		System.out.println("<<< End migrateUser()");
	}
	// build source user/passwd hash
	private static boolean builduserNameHash()
		throws Exception
	{
		FileInputStream fis = new FileInputStream(USER_FILE_NAME);

		BufferedReader in = new BufferedReader(new InputStreamReader(fis));

		String inputLine;
		int idx;
		String uname, passwd;
		while ((inputLine = in.readLine()) != null)
		{
			if ((idx = inputLine.indexOf("\t")) != -1)
			{
				// found tab (separating username and passwd)
				uname = inputLine.substring(0, idx++);	// skip tab
				passwd = inputLine.substring(idx);

				// insert into HashMap
				userNameHash.put(uname, passwd);
			}
			else
			{
				System.out.println("***** no password");
				return false;
			}
		}
		in.close();
		return true;
	}

	// return the new object Id as String
	private static PstAbstractObject createCopy(PstManager mgr, PstAbstractObject obj, boolean bPrint)
		throws PmpException
	{
		// create the same organization object and copy the attribute value
		PstAbstractObject newObj = null;
		String name, passwd;
		String [] attNames = null;

		name = obj.getObjectName();
		System.out.println("Start createCopy() of [" + name + "]");

		if (mgr instanceof userManager)
		{
			// create user object
			boolean bAlreadyExist = false;
			int idx;
			attNames = ((userManager)mgr).getAllAttributeNames();
			passwd = (String)userNameHash.get(name);
			if (passwd == null) passwd = "egixxx";			// when I copyover new users, the password would be lost
			if (!bEmailUserName)
			{
				idx = name.indexOf('@');
				if (idx != -1)
					name = name.substring(0, idx);
			}
			else if ((idx = name.indexOf('@')) == -1)
			{
				// add email format
				name += emailDomain;
			}
			try {
				newObj = ((userManager)mgr).createFull(user2, name, passwd);
				userMigrated++;
			}
			catch (PmpObjectCreationException e) {
				// the user already exist, just put in the userIdHash
				System.out.println("createCopy() user [" + name + "] found duplicate, ignore create.");
				newObj = mgr.get(user2, name);
				bAlreadyExist = true;
			}
			userIdHash.put(String.valueOf(obj.getObjectId()), String.valueOf(newObj.getObjectId()));
			if (bAlreadyExist) return obj;
		}
		else if (mgr instanceof meetingManager)
		{
			// create meeting
			attNames = ((meetingManager)mgr).getAllAttributeNames();
			newObj = ((meetingManager)mgr).create(user2);
			mtgHash.put(String.valueOf(obj.getObjectId()), String.valueOf(newObj.getObjectId()));
			mtgMigrated++;
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
			String mId = (String)obj.getAttribute("MeetingID")[0];
			mId = mtgHash.get(mId);
			if (mId == null)
				return null;		// the action doesn't belong to any meeting
			attNames = ((actionManager)mgr).getAllAttributeNames();
			newObj = ((actionManager)mgr).create(user2);
			actionMigrated++;
		}
		else if (mgr instanceof projectManager) {
			// create project
			attNames = ((projectManager)mgr).getAllAttributeNames();
			newObj = ((projectManager)mgr).create(user2);
		}
		else if (mgr instanceof planManager) {
			attNames = ((planManager)mgr).getAllAttributeNames();
			newObj = ((planManager)mgr).create(user2);
		}
		else if (mgr instanceof taskManager) {
			attNames = ((taskManager)mgr).getAllAttributeNames();
			newObj = ((taskManager)mgr).create(user2);
		}
		else if (mgr instanceof planTaskManager) {
			attNames = ((planTaskManager)mgr).getAllAttributeNames();
			newObj = ((planTaskManager)mgr).create(user2);
		}
		else if (mgr instanceof PstFlowStepManager) {
			attNames = new String[0];
		}
		else if (mgr instanceof resultManager) {
			attNames = ((resultManager)mgr).getAllAttributeNames();
			newObj = ((resultManager)mgr).create(user2);
		}

		////////////////////////////////////////////////////////
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
			catch (PmpUnsupportedTypeException e) {
				System.out.println("... try copying [" + attName + "] as raw type");
				newObj.setRawAttribute(attName, obj.getRawAttributeAsString(attName));
				System.out.println("    copy OK");
			}
			catch (PmpException e) {
				System.out.println("Failed copyover attribute [" + attName + "]");
				e.printStackTrace();
			}
		}

		//////////////////////////////////////////////////////////
		// handle special case
		String idS, s, temp;
		Object [] oArr;
		int idx;
		Integer one = new Integer(1);
		PstAbstractObject o;

		if (mgr instanceof userManager)
		{
			// 1. for user, update Company
			newObj.setAttribute("Company", targetTownIdS);
			newObj.setAttribute("TownID", targetTownIdS);
			//newObj.setAttribute("Picture", (byte[])obj.getAttribute("Picture")[0]);
			//newObj.setAttribute("HireDate", now);
			
			// un-comment below if want to change Email address
			/*s = name;
			if (!bEmailUserName)
				s += emailDomain;
			newObj.setAttribute("Email", s);*/
		}
		else if (mgr instanceof meetingManager)
		{
			// 2. for meeting: change Owner, Recorder and Attendee
			newObj.setAttribute("Note", (byte[])obj.getAttribute("Note")[0]);
			newObj.setAttribute("Type", "Private");
			temp = (String)newObj.getAttribute("Owner")[0];
			idS = userIdHash.get(temp);
			if (idS == null)
			{
				if (!bMigrateAllUsers)
				{
					// create this user on the target DB now
					try {
						o = uMgr.get(user1, Integer.parseInt(temp));
						createCopy(uMgr, o, false);
						idS = userIdHash.get(temp);
					}
					catch (PmpException e) {}
				}
				else
					System.out.println("!!!!! ***** ***** Translating owner [" + temp + "] is null");
			}
			if (idS == null)
				idS = defaultOwnerId;
			newObj.setAttribute("Owner", idS);

			// recorder
			idS = (String)userIdHash.get((String)newObj.getAttribute("Recorder")[0]);
			if (idS == null)
				idS = (String)newObj.getAttribute("Owner")[0];
			newObj.setAttribute("Recorder", idS);

			// Attendees
			int ct = 0;
			oArr = newObj.getAttribute("Attendee");
			for (int i=0; i<oArr.length; i++)
			{
				if ((s = (String)oArr[i]) == null) continue;
				newObj.removeAttribute("Attendee", s);
				idx = s.indexOf("::");
				temp = s.substring(0, idx);
				idS = (String)userIdHash.get(temp);	// translate the userId
				if (idS==null && ct<MAX_MTG_ATTENDEE)
				{
					if (!bMigrateAllUsers)
					{
						// create this user on the target DB now
						try {o = uMgr.get(user1, Integer.parseInt(temp));}
						catch (PmpException e) {continue;}	// might be deleted user from source
						createCopy(uMgr, o, false);
						idS = userIdHash.get(temp);
					}
					else
					{
						//System.out.println("***** ***** Translating attendee [" + temp + "] is null");
						continue;
					}
				}
				if (idS == null) continue;
				s = idS + s.substring(idx);
				newObj.appendAttribute("Attendee", s);
				ct++;		// keep track of how many people added to the meeting
			}
			for (int i=0; i<newMtgAttendee.length; i++)
				newObj.appendAttribute("Attendee", newMtgAttendee[i] + "::MandatoryPresent");

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
				idS = String.valueOf(createCopy(attMgr, oldAtt, true).getObjectId());
				newObj.removeAttribute("AttachmentID", s);
				newObj.appendAttribute("AttachmentID", idS);
				docMigrated++;
			}

			// TownID (company) attribute on meeting
			newObj.setAttribute("TownID", targetTownIdS);
			
			newObj.setAttribute("ProjectID", mtgProjID);		// projectID
			
			// roll time forward by 3 yrs
			for (int i=0; i<mtgDateField.length; i++)
			{
				rollForwardDate(newObj, mtgDateField[i], 4);
			}

			// ViewBlogNum
			if (newObj.getAttribute("Status")[0].equals("New"))
				newObj.setAttribute("ViewBlogNum", one);
			else
				newObj.setAttribute("ViewBlogNum", getRandom(5, 100));
		}
		else if (mgr instanceof attachmentManager)
		{
			// Owner
			s = (String)newObj.getAttribute("Owner")[0];
			idS = (String)userIdHash.get(s);
			if (idS != null)
				idS = defaultOwnerId;
			newObj.setAttribute("Owner", idS);

			// Location
			s = (String)obj.getAttribute("Location")[0];
			newObj.setAttribute("Location", "http://cr.egiomm.com/servlet/ShowFile?filePath=" + s);

			newObj.setAttribute("ProjectID", null);
		}
		else if (mgr instanceof actionManager)
		{
			// meeting ID
			s = (String)newObj.getAttribute("MeetingID")[0];
			idS = mtgHash.get(s);
			if (idS != null)
				newObj.setAttribute("MeetingID", idS);
			else
				System.out.println("***** ***** Translating action meetingID [" + s + "] is null");

			// Owner
			s = (String)newObj.getAttribute("Owner")[0];
			idS = (String)userIdHash.get(s);
			if (idS == null)
				idS = defaultOwnerId;
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
			
			// roll forward date
			rollForwardDate(newObj, "CreatedDate", 3);
			rollForwardDate(newObj, "ExpireDate", 3);
			rollForwardDate(newObj, "CompleteDate", 3);

			newObj.setAttribute("ProjectID", mtgProjID);
			newObj.setAttribute("BugID", null);
		}
		else if (mgr instanceof projectManager)
		{
			// project Company

			s = obj.getObjectName();
			s = s.substring(0, s.indexOf('@'));
			newObj.setObjectName(s + "@@" + defaultOwnerId);
			newObj.setAttribute("Company", targetTownIdS);
			newObj.setAttribute("TownID", targetTownIdS);
			
			// Owner and Creator
			newObj.setAttribute("Owner", userIdHash.get((String)obj.getStringAttribute("Owner")));
			newObj.setAttribute("Creator", userIdHash.get((String)obj.getStringAttribute("Creator")));
			
			// TeamMembers
			newObj.setAttribute("TeamMembers", null);	// reset
			for (int i=0; i<obj.getAttribute("TeamMembers").length; i++) {
				// find each of these users from source and create them in target
				// put them in HaspMap so that we can use them for task owner
				Integer oldId = (Integer)obj.getAttribute("TeamMembers")[i];
				if (oldId.intValue() <= 0) continue;
				/* migrateAllUser should take care of creating all users already
				o = uMgr.get(user1, oldId.intValue());
				o = createCopy(uMgr, o, false);
				newObj.removeAttribute("TeamMembers", oldId);
				System.out.println(">>> created new user: "+ o.getObjectName());
				System.out.println("old="+oldId+", new="+userIdHash.get(oldId.toString()));
				*/
				newObj.appendAttribute("TeamMembers", new Integer(userIdHash.get(oldId.toString())));
			}
			//newObj.appendAttribute("TeamMembers", 39412);
			
			///////
			// create plan, tasks and planTasks
			///////
			
			String newPjIdS = String.valueOf(newObj.getObjectId());
			
			// copy plan
			plan oldPlan = ((project)obj).getLatestPlan(user1);
			PstAbstractObject newPlan = createCopy(plMgr, oldPlan, false);
			newPlan.setAttribute("ProjectID", newPjIdS);
			newPlan.setAttribute("Creator", defaultOwnerId);
			plMgr.commit(newPlan);
			
			// copy task, planTask and task step
			HashMap<String,String> ptIdMap = new HashMap<String,String>();
			HashMap<String,String> tkIdMap = new HashMap<String,String>();	// for dependency
			int [] tidArr = ((project)obj).getCurrentTasks(user1);
			PstAbstractObject [] taskArr = tkMgr.get(user1, tidArr);
			PstAbstractObject tk, oldStep, newStep;
			String newTkIdS;
			String [] stepAttributes = {"CreatedDate", "ExpireDate"};
			
			// loop through old tasks
			for (int i=0; i<taskArr.length; i++) {
				// copy task
				tk = createCopy(tkMgr, taskArr[i], false);
				newTkIdS = String.valueOf(tk.getObjectId());
				tk.setAttribute("ProjectID", newPjIdS);
				tk.setAttribute("Creator", userIdHash.get(obj.getAttribute("Creator")[0]));
				idS = (String)taskArr[i].getAttribute("Owner")[0];
System.out.println("--- create task ["+tk.getObjectId() + "] oldOwner = "+idS + ", newOwner="+userIdHash.get(idS));			
tk.setAttribute("Owner", userIdHash.get(idS));
				tkMgr.commit(tk);
				tkIdMap.put(taskArr[i].getObjectName(), tk.getObjectName());
				
				// create planTask for this task
				PstAbstractObject oldPlTk = ((task)taskArr[i]).getPlanTask(user1);
				PstAbstractObject newPlTk = createCopy(ptMgr, oldPlTk, false);
				newPlTk.setAttribute("PlanID", newPlan.getObjectName());
				newPlTk.setAttribute("TaskID", newTkIdS);
				ptMgr.commit(newPlTk);
				ptIdMap.put(String.valueOf(oldPlTk.getObjectId()), String.valueOf(newPlTk.getObjectId()));
				
				// create task step if there was one
				oldStep = ((task)taskArr[i]).getStep(user1);
				if (oldStep != null) {
					newStep =
						(PstFlowStep)fsMgr.create(user2, null, null, null, null, PstFlowStep.TYPE_PROJTASK);
System.out.println("created step "+ newStep.getObjectId());	
					// set info for the task step object
					newStep.setAttribute("ProjectID", newPjIdS);
					newStep.setAttribute("TaskID", newTkIdS);
					newStep.setAttribute("Owner", tk.getAttribute("Owner")[0]);
					newStep.setAttribute("CurrentExecutor", tk.getAttribute("Owner")[0]);
					((PstFlowStep)newStep).setCurrentState((String)oldStep.getAttribute("State")[0]);
					for (int j=0; j<stepAttributes.length; j++) {
						newStep.setAttribute(stepAttributes[j], oldStep.getAttribute(stepAttributes[j])[0]);
					}
					fsMgr.commit(newStep);
				}
			}
			
			// fix up the ParentID in the planTask
			tidArr = ((project)newObj).getCurrentTasks(user2);
			taskArr = tkMgr.get(user2, tidArr);
			for (int i=0; i<taskArr.length; i++) {
				PstAbstractObject pt = ((task)taskArr[i]).getPlanTask(user2);
				if ( ((s = (String)pt.getAttribute("ParentID")[0]) != null) && !s.equals("0") ) {
					pt.setAttribute("ParentID", ptIdMap.get(s));
					ptMgr.commit(pt);
				}
			}
			
			// fix up dependencies in task
			Object [] depArr;
			// loop through new tasks
			for (int i=0; i<taskArr.length; i++) {
				tk = taskArr[i];
				depArr = tk.getAttribute("Dependency");
				tk.setAttribute("Dependency", null);
				for (int j=0; j<depArr.length; j++) {
					if (depArr[j] == null) break;
					tk.appendAttribute("Dependency", tkIdMap.get(depArr[j]));
				}
				tkMgr.commit(tk);
			}
		}	// END: else if project manager
		
		else if (mgr instanceof taskManager)
		{
			// for task we need to copy the blog
			int [] blogIdArr = rMgr.findId(user1, "TaskID='" + obj.getObjectId() + "'");
			for (int i=0; i<blogIdArr.length; i++) {
				o =rMgr.get(user1, blogIdArr[i]);
				System.out.println("--- copy task blog [" + blogIdArr[i] + "]");
				PstAbstractObject newBlog = createCopy(rMgr, o, false);
				newBlog.setAttribute("CreatedDate", o.getAttribute("CreatedDate")[0]);
				newBlog.setAttribute("Creator", userIdHash.get(o.getAttribute("Creator")[0]));
				newBlog.setAttribute("TaskID", String.valueOf(newObj.getObjectId()));
				rMgr.commit(newBlog);
			}
		}

		mgr.commit(newObj);

		if (bPrint)
		{
			System.out.println("Created and updated [" + newObj.getObjectName()
					+ "] (" + mgr.getClass().getName() + ")");
		}
		return newObj;
	}
	
	private static PstAbstractObject createStep(PstAbstractObject oldStep)
	{
		return null;
	}

	private static void rollForwardDate(PstAbstractObject obj, String attName, int yr)
		throws PmpException
	{
		Date dt = (Date)obj.getAttribute(attName)[0];
		if (dt != null)
		{
			Calendar cal = Calendar.getInstance();
			cal.setTime(dt);
			cal.roll(Calendar.YEAR, yr);
			cal.roll(Calendar.DATE, 2);					// this you have to adjust case-by-case
			obj.setAttribute(attName, cal.getTime());
		}
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
