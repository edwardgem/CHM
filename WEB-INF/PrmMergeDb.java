//
///////////////////////////////////////////////////////////////////////////////////////////
//
//	File:		PrmMergeDb.java
//	Author:		ECC
//	Date:		05/19/2009
//	Description:
//			Taking a source OMM DB and copy of the missing organization and attributes to the target.
//			Note that it only copy the definition, not the content.
//
//	Modification:
//
///////////////////////////////////////////////////////////////////////////////////////////
//

import oct.codegen.user;
import oct.codegen.userManager;
import oct.omm.client.OmsAttribDef;
import oct.omm.client.OmsDomain;
import oct.omm.client.OmsMember;
import oct.omm.client.OmsOrganization;
import oct.omm.client.OmsSession;
import oct.omm.common.OmsException;
import oct.omm.common.OmsObList;

public class PrmMergeDb
{
	private static userManager uMgr;

	private static user user1;		// source db user
	private static user user2;		// target db user

	public static void main(String[] args)
		throws Exception
	{
		// connect to two separate databases as special user
		OmsSession sessSource, sessTarget;
		String sourcePool, targetPool;
		
		if (args.length < 1)
		{
			System.out.println("Usage 1: runtool PrmMergeDb SourcePool TargetPool");
			System.out.println("Usage 2: runtool PrmMergeDb showPool");
			return;
		}
		if (args.length == 1)
		{
			// only show the content of the DB pool
			showDb(args[0]);
			return;
		}
		
		sourcePool = args[0];
		targetPool = args[1];

		// CR (source)
		sessSource = connect(sourcePool);
		OmsOrganization org = new OmsOrganization(sessSource, "user");
		OmsMember member = new OmsMember( sessSource, org, "prmus3r" );
		user1 = new user(member);

		// BringUp (target)
		sessTarget = connect(targetPool);
		org = new OmsOrganization(sessTarget, "user");
		member = new OmsMember( sessTarget, org, "prmus3r" );
		user2 = new user(member);

		uMgr = userManager.getInstance();

		int [] ids;

		//test
		ids = uMgr.findId(user1, "om_acctname='%'");
		System.out.println("total users in Source = "+ ids.length);
		ids = uMgr.findId(user2, "om_acctname='%'");
		System.out.println("total users in Target = "+ ids.length);

		// copy attributes
		copyAttributes(sessSource, sessTarget);

		// copy organizations and attr associations
		copyOrgs(sessSource, sessTarget);

		// check if target has extra organizations
		checkOrgs(sessSource, sessTarget);
		
		System.out.println("DONE");
	}

	// copy attribute definitions from one domain to another
	private static void copyAttributes(OmsSession s1, OmsSession s2)
	{
		OmsObList ol1, ol2;
		OmsAttribDef att1, att2;
		OmsDomain d1 = new OmsDomain(s1);
		OmsDomain d2 = new OmsDomain(s2);

		try
		{
			ol1 = d1.getAttrList();
			ol2 = d2.getAttrList();
			
			System.out.println(">>>>> copying attribute definition");
			boolean bFound;
			for (int i=0; i<ol1.size(); i++)
			{
				att1 = (OmsAttribDef)ol1.get(i);
				bFound = false;
				for (int j=0; j<ol2.size(); j++)
				{
					att2 = (OmsAttribDef)ol2.get(j);
					if (att1.getName().equals(att2.getName()))
					{
						if ( att1.getConstraint()!=att2.getConstraint()
							|| att1.getType()!=att2.getType() ) {
							// same name but constraint is not the same
							// need to delete and create
							System.out.println("Found same name but different attribute [" + att1.getName() + "]");
							try {att2.delete();}		// this will remove all the associations too
							catch (OmsException e) {System.out.println("*** Fail in delete attr."); e.printStackTrace(); continue;}
						}
						bFound = true;
						break;
					}
				}
				if (!bFound)
				{
					// create the source attribute for target
					System.out.print("Creating new attribute [" + att1.getName() + "] ... ");
					try {
						att2 = new OmsAttribDef(s2);
						att2.create(att1.getName(), att1.getType(), att1.getConstraint());
					}
					catch (OmsException e) {System.out.println("*** Fail in create attr."); e.printStackTrace(); continue;}
					System.out.println("done");
				}
			}
			System.out.println("<<<<< done copying attribute definition.");
			System.out.println("-------------------------\n");
		}
		catch (OmsException e)
		{
			e.printStackTrace();
		}
	}	// END: copyAttributes()

	// copy organization definitions from one domain to another
	private static void copyOrgs(OmsSession s1, OmsSession s2)
	{
		OmsObList ol1, ol2;
		OmsOrganization org1, org2;
		OmsDomain d1 = new OmsDomain(s1);
		OmsDomain d2 = new OmsDomain(s2);

		try
		{
			ol1 = d1.getOrgList();
			ol2 = d2.getOrgList();
			
			boolean bFound;
			for (int i=0; i<ol1.size(); i++)
			{
				org1 = (OmsOrganization)ol1.get(i);
				org1 = new OmsOrganization(s1, org1.getId());		// need to get the content
				bFound = false;
				for (int j=0; j<ol2.size(); j++)
				{
					org2 = (OmsOrganization)ol2.get(j);
					org2 = new OmsOrganization(s2, org2.getId());	// need to get the content
					if (org1.getName().equals(org2.getName()))
					{
						bFound = true;
						copyOrg2Org(org1, org2);
						break;
					}
				}
				if (!bFound)
				{
					// create the org and then copy over
					System.out.print(">>> Creating new org [" + org1.getName() + "] ... ");
					org2 = new OmsOrganization(s2);
					org2.create(org1.getName(), org1.getType());
					copyOrg2Org(org1, org2);
					System.out.println("<<< Done create org [" + org2.getName() + "].\n");
				}
			}
		}
		catch (OmsException e)
		{
			e.printStackTrace();
		}
	}	// END: copyOrg()

	// compare source org with target org and copy over attribute associations
	private static void copyOrg2Org(OmsOrganization o1, OmsOrganization o2)
	{
		OmsObList ol1, ol2;
		OmsAttribDef att1, att2;
		
		ol1 = o1.getAttribDefList();
		ol2 = o2.getAttribDefList();
		
		boolean bFound;
		System.out.println("Compare and copy [" + o1.getName() + "]");
		System.out.print("   assocating ");
		for (int i=0; i<ol1.size(); i++)
		{
			att1 = (OmsAttribDef)ol1.get(i);
			bFound = false;
			for (int j=0; j<ol2.size(); j++)
			{
				att2 = (OmsAttribDef)ol2.get(j);
				if (att1.getName().equals(att2.getName()) && att1.getConstraint()==att2.getConstraint()
						&& att1.getType()==att2.getType())
				{
					bFound = true;
					break;
				}
			}
			if (!bFound)
			{
				// associate the source attribute for target
				System.out.print("[" + att1.getName() + "] ");
				try {o2.addAttribute(att1, 0, null, att1.isRequired());}
				catch (OmsException e) {System.out.println("Failed in addAttribute() [" + att1.getName()
						+ "] for org [" + o2.getName() + "]"); e.printStackTrace();continue;}
			}
		}
		System.out.println(" done.\n-----\n");
	}	// END: copyOrg2Org()

	// compare source org with target org and copy over attribute associations
	private static void checkOrgs(OmsSession s1, OmsSession s2)
	{
		OmsObList ol1, ol2;
		OmsOrganization org1, org2;
		OmsDomain d1 = new OmsDomain(s1);
		OmsDomain d2 = new OmsDomain(s2);

		try
		{
			ol1 = d1.getOrgList();
			ol2 = d2.getOrgList();
			
			boolean bFound;
			for (int i=0; i<ol2.size(); i++)
			{
				org2 = (OmsOrganization)ol2.get(i);		// target
				bFound = false;
				for (int j=0; j<ol1.size(); j++)
				{
					// go thru the source
					org1 = (OmsOrganization)ol1.get(j);	// source
					if (org1.getName().equals(org2.getName()))
					{
						bFound = true;
						break;
					}
				}
				if (!bFound)
					System.out.println("***** Org [" + org2.getName() + "] not found in source.  You may consider deleting.");
			}
		}
		catch (OmsException e)
		{
			e.printStackTrace();
		}
	}	// END: checkOrgs
	
	private static OmsSession connect(String poolName) throws OmsException
	{
		OmsSession sess = new OmsSession();
		System.out.println("Connecting to DB pool: " + poolName);
		sess.connect(poolName, "user", "prmus3r", "john155");
		return sess;
	}

	// compare source org with target org and copy over attribute associations
	private static void showDb(String poolName) throws OmsException
	{
		OmsSession sess = connect(poolName);
		OmsDomain dom = new OmsDomain(sess);
		OmsObList orgList = dom.getOrgList();
		
		OmsOrganization org;
		OmsObList attrList;
		String s;
		int spaceNum;
		
		// list organizations and # of objects
		System.out.println("id     org name            # of attr     # of member");
		System.out.println("---    ---------------     ----------    -----------");
		for (int i=0; i<orgList.size(); i++)
		{
			// print org id
			org = (OmsOrganization)orgList.get(i);
			org = new OmsOrganization(sess, org.getId());		// I need to get the content of the org
			s = String.valueOf(org.getId());
			System.out.print(s);
			spaceNum = 2 - s.length();
			while (spaceNum-- > 0) System.out.print(" ");		// append space to align row
			System.out.print("     ");
			
			// org name
			s = org.getName();
			System.out.print(s);
			spaceNum = 25 - s.length();
			while (spaceNum-- > 0) System.out.print(" ");		// append space to align row
			
			// attribute list
			attrList = org.getAttribDefList();
			s = String.valueOf(attrList.size());
			spaceNum = 4 - s.length();
			while (spaceNum-- > 0) System.out.print(" ");		// insert leading space for number
			System.out.print(s + "           ");				// attr num and gap spaces
			
			// total members
			s = String.valueOf(org.size());
			spaceNum = 5 - s.length();
			while (spaceNum-- > 0) System.out.print(" ");		// insert leading space for number
			System.out.print(s);
			
			System.out.println("");								// new line
		}
		
		// list attribute lists
	}

}
