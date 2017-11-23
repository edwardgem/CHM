////////////////////////////////////////////////////
//	Copyright (c) 2013, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	PrmRdb.java
//	Author:	ECC
//	Date:	2/25/10
//	Description:
//		MySQL direct access without using OMM.
//
////////////////////////////////////////////////////////////////////

package util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;

import org.apache.log4j.Logger;

import oct.codegen.bugManager;
import oct.codegen.user;
import oct.codegen.userinfo;
import oct.codegen.userinfoManager;
import oct.pmp.exception.PmpException;

public class PrmRdb {
	
	static user jwu = Prm.getSpecialUser();

	private static Connection conn = null;
	//private static Statement stmt = null;
	private static PreparedStatement pst = null;
	//private static ResultSet rs = null;

	private static Logger l;
	
	static {
		l = PrmLog.getLog();
	}

	/**
	 * Insert a bunch of Int into the DB
	 * @param url the JDBC connection string. E.g. jdbc:mysql://localhost:3306/stat
	 * @param num variable number of int parameters
	 */
	public static void insertIntDB (String url, String tabName, int ... num)
	{
		try {
			// This will load the MySQL driver, each DB has its own driver
			Class.forName("com.mysql.jdbc.Driver");
			
			// Setup the connection with the DB
			String spec_uname = Util.getPropKey("pst", "PRIVILEGE_USER");
			String spec_passwd = Util.getPropKey("pst", "PRIVILEGE_PASSWD");
			conn = DriverManager.getConnection(url
								+ "?user=" + spec_uname + "&password=" + spec_passwd);

			// Statements allow to issue SQL queries to the database
			//stmt = conn.createStatement();
			
			// perform insert
			String sql = "INSERT INTO "
					+ tabName
					+ " (rec_date, new, assigned, resolved, verified, closed, priority)"
					+ " values (NOW(), ?, ?, ?, ?, ?, 'all')";
			pst = conn.prepareStatement(sql);
			
			/*
			pst.setInt(1, iNew);
			pst.setInt(2, iAssigned);
			pst.setInt(3, iResolved);
			pst.setInt(4, iVerified);
			pst.setInt(5, iClosed);
			*/
			for (int i=0; i<num.length; i++) {
				pst.setInt(i+1, num[i]);
			}

			pst.executeUpdate();
			pst.close();

		}
		catch (Exception e) {
			e.printStackTrace();
		}
	}	// END: insertIntDB()
	
	/**
	 * Count the number of bugs in different states
	 * insert the info into an external database.
	 */
	public static void bugCount()
		throws PmpException
	{
		// gather bug info from the project
		userinfoManager uiMgr = userinfoManager.getInstance();
		userinfo ui = (userinfo)uiMgr.get(jwu, String.valueOf(jwu.getObjectId()));
		String projIdS = ui.getPreference("BugPID");		// projectID of the proj that tracks bugs
		if (StringUtil.isNullOrEmptyString(projIdS))
			return;

		String url = Util.getPropKey("pst", "JDBC_CONN");
		if (StringUtil.isNullOrEmptyString(url))
			return;
		
		bugManager bugMgr = bugManager.getInstance();
		String [] sa = projIdS.split(":");
		projIdS = sa[1];
		String expr = "ProjectID='" + projIdS + "' && State='";
		int [] ids1 = bugMgr.findId(jwu, expr + "new'");
		int iNew = ids1.length;
		ids1 = bugMgr.findId(jwu, expr + "assigned'");
		int iAssign = ids1.length;
		ids1 = bugMgr.findId(jwu, expr + "resolved'");
		int iResolved = ids1.length;
		ids1 = bugMgr.findId(jwu, expr + "verified'");
		int iVerified = ids1.length;
		ids1 = bugMgr.findId(jwu, expr + "closed'");
		int iClosed = ids1.length;

		PrmRdb.insertIntDB(url, "bug", iNew, iAssign, iResolved, iVerified, iClosed);
		l.info("Done bugCount() on project [" + projIdS + "]");
	}
}
