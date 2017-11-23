//
//	Copyright (c) 2006, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: CreateAttDB.java
//	Author: AGQ
//	Date:	06/16/06
//	Description: Search engine mapping and indexing files.
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//

package mod.se;
import java.io.File;
import java.io.IOException;
import java.util.Date;

import oct.codegen.attachment;
import oct.codegen.attachmentManager;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstGuest;
import oct.pst.PstUserAbstractObject;
import util.Util;

public class CreateAttDB {
	//public static final String SELASTMAPPED = "SE-LastMapped";
	
	public static void main(String[] args) throws Exception
	{
		if (args.length < 1)
		{ 
			System.out.println("Usage: Maps directories located in pst.properties file to database.");
			System.out.println("       Checks SE_INDEX_DIRS for the list of directoies to index.");
			System.out.println("> java mod.se.IndexBuilder map");
			System.out.println("       Looks through the attachment objects in the database to build");
			System.out.println("       an index");
			System.out.println("> java mod.se.IndexBuilder index");
			System.out.println("       Checks for files not inside database and also indexes the file");
			System.out.println("> java mod.se.IndexBuilder update");
			return;
		}

		userManager uMgr = userManager.getInstance();
		attachmentManager attMgr = attachmentManager.getInstance();

		// connect to PRM
		PstUserAbstractObject gUser = (PstUserAbstractObject) PstGuest.getInstance();
		String spec_uname = Util.getPropKey("pst", "PRIVILEGE_USER");
		String spec_passwd = Util.getPropKey("pst", "PRIVILEGE_PASSWD");
		user prmuser = (user)uMgr.login(gUser, spec_uname, spec_passwd);
		System.out.println("... connected");
		
		boolean isUpdate = false;
		if (args[0].equalsIgnoreCase("update"))
			isUpdate = true;
			
		if (args[0].equalsIgnoreCase("map") || isUpdate) {
			String repoDir = Util.getPropKey("pst", "FILE_UPLOAD_PATH"); // Ignore duplicate directory
			if (repoDir != null)
				repoDir = repoDir.replaceAll("\\\\", "/");
			else
				repoDir = "";
			String directories = Util.getPropKey("pst", "SE_INDEX_DIRS");
			String [] seItems = null;
			if (directories != null)
				seItems = directories.split(";");		// e.g. C:/temp@@ENGR; //server/test
			String [] directoryArr = new String[0];
			String [] deptArr = null;
			if (directories != null)
			{
				directoryArr = new String[seItems.length];
				deptArr = new String[seItems.length];
				String [] sa;
				for (int i=0; i<seItems.length; i++)
				{
					sa = seItems[i].split("@@");		// @@ separates the dir from DeptName
					directoryArr[i] = sa[0].trim();
					if (sa.length > 1)
						deptArr[i] = sa[1].trim();
					else
						deptArr[i] = null;
				}
			}
			
			PstAbstractObject[] objArr = attMgr.getAllattachment(prmuser);
			int before = objArr.length;
			System.out.println("Attachment contains: " +before + " objects");
			
			// Set index currently used
			if (isUpdate) {
				IndexStatus.setCurrentlyUsed(true);
			}
			
			for (int i=0; i<directoryArr.length; i++) {
				String dirPath = directoryArr[i];
				System.out.println(dirPath);
				File file = new File(dirPath);
				createAttObjs(prmuser, attMgr, file, isUpdate, repoDir, deptArr[i]);
			}
			
			// Unset index currently used
			if (isUpdate) {
				IndexStatus.setCurrentlyUsed(false);
			}
			
			objArr = attMgr.getAllattachment(prmuser);
			int after = objArr.length;
			System.out.println("Attachment now contains: " +after + " objects");
			System.out.println("Added " + (after-before) + " attachment objects");
		}
		else if (args[0].equalsIgnoreCase("index")) {
			IndexBuilder.build(prmuser, true);
		}

		// logout
		uMgr.logout(prmuser);
		System.out.println("... close session");
	}
	
	private static void createAttObjs(PstUserAbstractObject pstuser, attachmentManager attMgr, File file, boolean isUpdate, String repoDir, String deptName)
		throws IOException 
	{
		// do not try to index files that cannot be read
		if (file.canRead()) {
			if (file.isDirectory()) {
				String dir = file.getAbsolutePath();
				dir = dir.replaceAll("\\\\", "/");
				if (dir.equalsIgnoreCase(repoDir) || dir.equalsIgnoreCase(IndexBuilder.getIndexDirS()))
					return;
				String[] files = file.list();
				// an IO error could occur
				if (files != null) {
					for (int i = 0; i < files.length; i++) {
						createAttObjs(pstuser, attMgr, new File(file, files[i]), isUpdate, repoDir, deptName);
					}
				}
			} else {
				if (!isUpdate)
					System.out.println("-adding " + file);
				if (!createAttObj(pstuser, attMgr, file, isUpdate, deptName)) {
					if (!isUpdate)
						System.out.println("  Failed to add " + file.getAbsolutePath() + " to db");
				}
			}
		}
		else
			System.out.println("--- cannot read " + file);
	}
	
	private static boolean createAttObj(PstUserAbstractObject pstuser, attachmentManager attMgr, File file, boolean isUpdate, String deptName) {
		Date createdDate = new Date();
		Date lastUpdatedDate = new Date(file.lastModified()); // lastUpdatedDate of file == lastModified
		String absolutePath = file.getAbsolutePath();
		absolutePath = absolutePath.replaceAll("\\\\", "/"); // changes all c:\ to c:/, prevents escaping text
		String savePath = absolutePath; // Path cannot be saved w/ '\'
		absolutePath = absolutePath.replaceAll("\\'", "\\\\'"); // replace all ' to \\' so findId will not escape it
		Integer frequency = new Integer(0);
		
		String ext = null;
		int iExt = absolutePath.lastIndexOf(".");
		ext = (iExt != -1)?absolutePath.substring(iExt+1).toLowerCase():"";
		
		Integer securityLevel = new Integer(Util.getPropKey("pst", "DEFAULT_SEC_LEVEL"));
		
		try {
			if (attMgr == null)
				attMgr = attachmentManager.getInstance();
			
			int [] ids = attMgr.findId(pstuser, "Location='"+absolutePath+"'");
			if (ids.length > 0) {
				if (!isUpdate)
					System.out.println("  File: " + absolutePath + " already exists in db.");
				return false;
			}
			
			attachment att = (attachment)attMgr.create(pstuser);
			att.setAttribute("CreatedDate", createdDate);
			att.setAttribute("LastUpdatedDate", lastUpdatedDate);
			att.setAttribute("Location", savePath);			// relative path
			att.setAttribute("Frequency", frequency);
			att.setAttribute("FileExt", ext);
			att.setAttribute("SecurityLevel", securityLevel);
			att.setAttribute("DepartmentName", deptName);
			attMgr.commit(att);
			
			if (isUpdate) {
				boolean success = IndexBuilder.update(absolutePath, String.valueOf(att.getObjectId()));
				if (success)
					System.out.println("-adding " + absolutePath + "\n  Index has been updated");
				else
					System.out.println("-adding " + absolutePath + "\n  Index failed to update:" + att.getObjectId());
			}
			
			return true;
		} catch (PmpException e) {
			e.printStackTrace();
			return false;
		}
	}
}
