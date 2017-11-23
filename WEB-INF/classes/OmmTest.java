//
///////////////////////////////////////////////////////////////////////////////////////////
//
//	File:		OmmTest.java
//	Author:		ECC
//	Date:		12/12/2016
//	Description:
//
//	Modification:
//
///////////////////////////////////////////////////////////////////////////////////////////
//

import util.*;
import oct.codegen.*;
import oct.pst.*;
import oct.pmp.exception.*;
import oct.omm.common.*;
import oct.omm.client.*;
import java.net.*;
import java.io.*;
import java.util.*;
import java.text.*;

public class OmmTest
{
	private static final String USER_FILE_NAME = "user.txt";
	private static final String [] BAD_USER = {"kkcchong", "ksato", "elin", "takaogi"};
	private static final Date now = new Date();
	private static Random rand = new Random(12345);
	private static int docMigrated = 0;
	private static String townID;

	private static userManager uMgr;
	private static meetingManager mtgMgr;

	private static user jwu;		// source db user

	public static void main(String[] args)
		throws Exception
	{
		// test performance of OMM calls

		// BringUp (target)
		OmsSession session = new OmsSession();
		System.out.println("Connecting to BringUpPool");
		session.connect("BringUpPool", "user", "prmus3r", "john316");
		OmsOrganization org = new OmsOrganization(session, "user");
		OmsMember member = new OmsMember( session, org, "prmus3r" );
		jwu = new user(member);

		uMgr = userManager.getInstance();


		//test
		String uname="xxx-test";
		String passwd = "xxx";
		
		System.out.println("Start testing ...");
		PstAbstractObject o = uMgr.create(jwu, uname, passwd);
		
		System.out.println("cleanup ...");
		uMgr.delete(o);


		System.out.println("... DONE testing");
	}


}
