//
//	Copyright (c) 2008 EGI Technologies Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
// $Header$
//
//	File:	$RCSfile$
//	Author:	ECC
//	Date:	08/18/2008
//
//	Modification:
//			@ECC120309	Support uploading to a specified project and task node.
//
/////////////////////////////////////////////////////////////////////
/**
* upload (backup) directories from client to server
*/

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.io.PrintStream;
import java.util.Date;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Stack;
import java.util.Vector;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import main.PrmThread;
import oct.codegen.attachment;
import oct.codegen.attachmentManager;
import oct.codegen.plan;
import oct.codegen.planManager;
import oct.codegen.project;
import oct.codegen.projectManager;
import oct.codegen.taskManager;
import oct.codegen.townManager;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstGuest;
import oct.pst.PstManager;
import oct.pst.PstUserAbstractObject;
import oct.util.file.FileTransfer;
import oct.util.file.MyFileFilter;
import oct.util.file.PrmClient;
import oct.util.file.PrmClientConstant;

import org.apache.log4j.Logger;

import util.JwTask;
import util.PrmLog;
import util.PrmProjThread;
import util.Util;
import util.Util2;

import com.oreilly.servlet.MultipartRequest;

public class UploadFile extends HttpServlet
{
	private static final long serialVersionUID = 8182008;
	
	private static String uploadPath = Util.getPropKey("pst", "FILE_UPLOAD_PATH");
	private static Logger l = PrmLog.getLog();
	private static user jwu = PrmThread.getuser();
	
	private static final int L200M			= 200*1024*1024;
	private static final int BUFFER_SIZE	= 2*1024*1024;			// 2MB
	
	private static final String TEMP_DIR	= Util.getPropKey("pst", "REMOTE_ACCESS_TEMPDIR");
	
	private static attachmentManager attMgr = null;
	private static townManager tnMgr = null;
	private static userManager uMgr = null;
	private static projectManager pjMgr = null;
	private static taskManager tkMgr = null;
	
	static {
		try {
			attMgr = attachmentManager.getInstance();
			tnMgr = townManager.getInstance();
			uMgr = userManager.getInstance();
			pjMgr = projectManager.getInstance();
			tkMgr = taskManager.getInstance();
		}
		catch (PmpException e){}
	}

	public void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException
	{
		upload(request, response);
	}
	
	/**
	* Handle POST requests
	*/
	public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException
	{
		upload(request, response);
	}
	
	@SuppressWarnings("unchecked")
	private void upload(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException
	{
		// every post is to upload ONE directory at a time
		// for recursive operation, one upload area may contain multiple directories
		try
		{
			MultipartRequest mrequest = new MultipartRequest(request, uploadPath, L200M);
			String s;
			
			// check if this is init: attempt login authority
			if ((s = mrequest.getParameter("USER")) != null)
			{
				String passwd = mrequest.getParameter("PASSWORD");
				PstUserAbstractObject gUser = (PstUserAbstractObject) PstGuest.getInstance();
				try {uMgr.login(gUser, s, passwd);}
				catch (Exception e) {throw new IOException("Fail to login");}
				return;
			}
			
			// check if this is a recal space call
			s = mrequest.getParameter(PrmClientConstant.RECALSP_LABEL);
			if (s != null)
			{
				recalSpace(s);
				return;
			}
			
			// getProjectList()
			s = mrequest.getParameter(PrmClientConstant.GET_PROJLIST_LABEL);
			if (s != null)
			{
				getProjectList(mrequest, response);
				return;
			}
			
			// getTaskList()
			s = mrequest.getParameter(PrmClientConstant.GET_TASKLIST_LABEL);
			if (s != null)
			{
				getTaskList(mrequest, response);
				return;
			}
			
			// *** UPLOADING FILE ***
			boolean bNoSpace = false;

			// company and user owner
			String uname = null;
			String subDir = null;
			String compIdS = mrequest.getParameter("cid");
			String hostname = mrequest.getParameter("hostname");
			String ownerIdS = null;
			PstAbstractObject o, coreObj;
			PstManager coreMgr;
			
			// company takes precedence
			if (compIdS != null)
			{				
				// ECC: not implemented yet
				// user company program mgr (Chief) as owner
				coreMgr = tnMgr;
				uname = compIdS;								// use company ID as uname
				coreObj = tnMgr.get(jwu, Integer.parseInt(compIdS));
				ownerIdS = (String)coreObj.getAttribute("Chief")[0];
				
				subDir =  uploadPath + "/" + compIdS;			// C:/Repository/CR/12345 (use company ID)
			}
			else
			{
				// must be uploading for individual
				coreMgr = uMgr;
				uname = mrequest.getParameter("uname");
				if (uname == null)
				{
					l.error("Failed to backup file: no company or user info.");
					return;
				}
				
				// use the uname to get the ownerId
				coreObj = uMgr.get(jwu, uname);		// this is the request user
				ownerIdS = String.valueOf(coreObj.getObjectId());				
				
				// check space limit of the user
				s = "Note: your upload attempt on " + new Date().toString() + " has failed.";
				if (!Util2.checkSpace(jwu, coreObj.getObjectId(), s))
				{
					// not enough space
					l.info("Upload failed.  User [" + uname + "] has no space for upload.");
					PrintStream ostream = getOutputStream(response);
					ostream.println(PrmClientConstant.ERROR + " no space to upload.");
					bNoSpace = true;
					return;										// ECC: in future, allow user to call for delete files
				}
				
				subDir = uploadPath + "/" + ownerIdS;			// C:/Repository/CR/34555 (use user ID)
			}
			
			
			///////////////////////////////////////////////////////////////
			// check to see if it is backup definition
			// backup area in user object
			// update the user object's backup attribute
			String uploadOption = mrequest.getParameter(PrmClientConstant.UPLOAD_OPT_LABEL);
			String backup = mrequest.getParameter("backup");	// peace$c:/temp/folder1*?@ADMIN;ENGR
			int idx1;
			if (uploadOption==null && backup!=null && backup.length()>0)
			{
				// peace$c:/temp/folder1*?@ADMIN;ENGR
				backup = backup.replaceAll("\\\\", "/");
				if ((idx1 = backup.indexOf(PrmClientConstant.DEPT_TERM)) != -1)
					s = backup.substring(0, idx1).trim();				// peace$c:/temp/folder1*
				else
					s = backup.trim();
				if (s.endsWith("*"))
				{
					String s1 = s.substring(0, s.length()-1).trim();	// remove the "*" sign
					backup = backup.replace(s, s1);
					s = s1;
				}
				// should check if update is necessary
				if (!Util2.foundAttribute(coreObj, PrmClientConstant.ATTR_BACKUP, backup)) {
					Util2.replaceAttribute(coreObj, PrmClientConstant.ATTR_BACKUP, s, backup);
					coreMgr.commit(coreObj);
					l.info("Updated Backup attribute for [" + coreObj.getObjectId() + "] with [" + backup + "]");
				}
				
				// create the actual directory if it does not exist
				// uid/hostname/C-drive/path...
				String relPath = mrequest.getParameter("dirName");	// D-drive/Temp/folder1
				relPath = relPath.replaceAll("\\\\", "/");
				
				// subDir is C:/Repository/CR/uid/peace
				subDir += "/" + hostname;
				
				// C:/Repository/CR/uid/peace/D-drive/Temp/folder1
				String dirName = subDir + "/" + relPath;

				File serverDir = new File(dirName);
				if (!serverDir.exists()) {
					serverDir.mkdirs();			// make the whole path - top directory area
					l.info("mkdir for top Backup area [" + dirName + "]");
				}
				
				return;		// done
			}
			
			/////////////////////////////////////////////////////////
			// @ECC120309 check to see if uploading segment
			String deptName, clientPath, pathName, relPath, dirName,
						fNameOnly="", fPathName, ext="", paramS, chunkS="";
			File fileObj=null, subPathObj;
			long lt = 0;
			int ct = 0;
			int [] ids;
			File newFile;
			String timeS;
			
			// after version 1.7, use uploadOption
			if (uploadOption!=null && uploadOption.length()>0)
			{
				// uploading one chunk at a time
				// put it in a temporary directory until it is all done,
				// then merge together the file and store it.
				// the chunks file names are uname@@actualFileName_chunk#.ext
				PrintStream ostream = getOutputStream(response);

				timeS = mrequest.getParameter(PrmClientConstant.TIME_LABEL + uname);
				if (timeS!=null && timeS.length()>0)
				{
					// last segment uploaded: merge back the file and put it in repository
					// merge the file in temp dir and then decide where to put it depending on destination
					fNameOnly = getUploadFileName(mrequest);		// filename.ext w/o uname@@
					System.out.println("   upload fname (last segment) = " + fNameOnly);
					//System.out.println("   timestamp = " + timeS);
					newFile = new File(TEMP_DIR + "/" + fNameOnly);
					unsplitBigFile(newFile, uname);
					
					// the merged file is newFile, now place the file according to destination
					if (uploadOption.equalsIgnoreCase(PrmClientConstant.UP_OPT_TOPROJ))
					{
						// ECC: should check user's authority to upload to project/task
						String projIdS = mrequest.getParameter(PrmClientConstant.PROJ_LABEL);
						String taskIdS = mrequest.getParameter(PrmClientConstant.TASK_LABEL);
						System.out.println("   uploading to proj/task = "+ projIdS + ":" + taskIdS);						
						PstAbstractObject tkObj = tkMgr.get(jwu, taskIdS);
						
						// ECC: should we check and reject if fname collide w/ a link file?
						// the following code is from post_updtask.jsp
						FileTransfer ft = new FileTransfer((PstUserAbstractObject)coreObj);
						try
						{
							attachment att = ft.saveFile(tkObj.getObjectId(), projIdS, newFile,
									null, attachment.TYPE_TASK, null, null, true);
							tkObj.appendAttribute("AttachmentID", String.valueOf(att.getObjectId()));
							tkMgr.commit(tkObj);
						}
						catch(Exception e)
						{
							// return an error message
							e.printStackTrace();
							if (ostream != null)
								ostream.println(PrmClientConstant.ERROR + " in UploadFile when attempting to put file in repository: " + e.toString());
							return;
						}
					}
					else
					{
						/***************************************************************/
						// upload to backup area
						//System.out.println("   uploading for Remote Backup = "+ backup);						
						deptName = mrequest.getParameter(PrmClientConstant.DEPT_LABEL);
						clientPath = mrequest.getParameter(PrmClientConstant.PATH_LABEL);		// C-drive/Temp/folder1/sub-folder1
						relPath = mrequest.getParameter("dirName");	// D-drive/Temp/folder1

						relPath = relPath.replaceAll("\\\\", "/");
						subDir += "/" + hostname;			// C:/Repository/CR/12345/peace
						dirName = subDir + "/" + relPath;	// C:/Repository/CR/12345/peace/D-drive/Temp/folder1

						File serverDir = new File(dirName);
						if (!serverDir.exists()) {
							serverDir.mkdirs();		// make the whole path - top directory area
							l.info("mkdir for Backup area - subpath [" + dirName + "]");
						}

						pathName = dirName;			// C:/Repository/CR/12345/peace/D-drive/Temp/folder1
						if (!pathName.endsWith("/"))
							pathName += "/";
						fPathName = pathName + fNameOnly;	// the full pathname of the file on server
						File oldFile = new File(fPathName);
						if (oldFile.exists())
						{
							oldFile.delete();		// remove the old version of the file first
							
							// remove the old attachment object
							ids = attMgr.findId(jwu, "Location='" + fPathName + "'");
							for (int i=0; i<ids.length; i++)
							{
								try
								{
									o = attMgr.get(jwu, ids[i]);
									attMgr.delete(o);
								}
								catch (PmpException e1) {}
							}
						}

						// rename the merged file to the file location and set timestamp
						lt = Long.parseLong(timeS);			// extract file last modified time
						if (lt > 0)
							newFile.setLastModified(lt);	// use the same timestamp as the original file on client
						newFile.renameTo(oldFile);
						l.info("    backup file (" + newFile.getPath() + ")");
						
						// ECC: now only one file at a time for uploading
						// create the attachment object
						attMgr.create(jwu,
								ownerIdS,
								fPathName,
								ext,
								compIdS,			// proj Id, put the company id here
								null,				// type: drive file, no type
								deptName);
						
					}
				}	// END if: upload last segment
				if (ostream != null)
					ostream.println("Upload completed successfully.");
				// System.out.println("--- upload segment done.");
				return;
			}	// END if: there is an upload option specify (NEW)
			
			// ************************* Depreciated code ********************
			// now either it is OLD uploading calls before DEC 2009
System.out.println("!!!!!!!! OLD obsoleted code.  Should not get hit");			
			subDir += "/" + hostname;							// C:/Repository/CR/12345/peace

			// upload posting is one directory at a time: get directory name
			relPath = mrequest.getParameter("dirName");	// D-drive/Temp/folder1
			relPath = relPath.replaceAll("\\\\", "/");
			dirName = subDir + "/" + relPath;			// C:/Repository/CR/12345/peace/D-drive/Temp/folder1
			File serverDir = new File(dirName);
			if (!serverDir.exists())
				serverDir.mkdirs();								// make the whole path - top directory area

			/////////////////////////////////////////////
			// remember the top backup area info
			// caller should not pass "backup" parameter if it is not a top directory
			int idx2;
			if (backup!=null && backup.length()>0)
			{
				backup = backup.replaceAll("\\\\", "/");
				if ((idx1 = backup.indexOf(PrmClientConstant.DEPT_TERM)) != -1)			// peace$c:/temp/folder1*?@ADMIN;ENGR
					s = backup.substring(0, idx1).trim();				// peace$c:/temp/folder1*
				else
					s = backup.trim();
				if (s.endsWith("*"))
				{
					String s1 = s.substring(0, s.length()-1).trim();	// remove the "*" sign
					backup = backup.replace(s, s1);
					s = s1;
				}
				Util2.replaceAttribute(coreObj, PrmClientConstant.ATTR_BACKUP, s, backup);
				coreMgr.commit(coreObj);
				l.info("Updated Backup attribute for [" + coreObj.getObjectId() + "] with [" + backup + "]");
			}

			clientPath = mrequest.getParameter(PrmClientConstant.PATH_LABEL);		// C-drive/Temp/folder1/sub-folder1
			if (clientPath==null)
				return;		// probably just updating Backup attribute, called from PrmClientUpload.backupArea()
			
			l.info(">>> Start uploading for [" + coreObj.getObjectId() + "] " + dirName);
			
			// department authorization specification on directory
			deptName = mrequest.getParameter("dept");
			
			// do the backup for each file received from client
			
			// might be uploading subdirectory files underneath the root path
			// the sub-folder path is put in clientPath
			pathName = dirName;									// C:/Repository/CR/12345/peace/D-drive/Temp/folder1
			clientPath = clientPath.substring(relPath.length());	// only: "/sub-folder1" if exists
			if (clientPath.length() > 0)
			{
				pathName += clientPath;			// C:/Repository/CR/12345/peace/D-drive/Temp/folder1/sub-folder1
				subPathObj = new File(pathName);
				if (!subPathObj.exists())
					subPathObj.mkdir();
			}
			//System.out.println("actual dir="+pathName);				
			
			// ECC: since Apr 2009 I am expecting uploading one whole file at a time
			// and if the file is > 10MB, I expect it to come in small chunks <= 10MB.
			boolean bCompletedFile = false;
			Enumeration enum0 = mrequest.getFileNames();
			while (!bNoSpace && enum0.hasMoreElements())
			{
				// split files to smaller parts, label: filename5_0, filename5_1, etc.
				// but they come one file (chunk) per post until we see TIME_LABEL
				paramS = enum0.nextElement().toString();
				fileObj = mrequest.getFile(paramS);			// get the object, the upload is done when client post
//System.out.println("... got chunk: "+ fileObj.getName());				
				//fArrList.add(fileObj);					// add to the file chunk list

				// get chunk #
				chunkS = mrequest.getParameter(PrmClientConstant.CHUNK_LABEL);
				
				timeS = mrequest.getParameter(PrmClientConstant.TIME_LABEL + uname);
				if (timeS != null)
				{
					// only do this when caller has passed the TIME_LABEL (last chunk)
					bCompletedFile = true;
					lt = Long.parseLong(timeS);			// extract file last modified time
					
					// extension
					fNameOnly = mrequest.getFilesystemName(paramS);			// myFileName_0.pdf
					idx1 = fNameOnly.lastIndexOf('_');
					idx2 = fNameOnly.lastIndexOf('.');
					if (idx2 < idx1)
						idx2 = -1;
					if (idx2 != -1)
					{
						ext = fNameOnly.substring(idx2+1).toLowerCase();
						fNameOnly = fNameOnly.substring(0, idx1) + fNameOnly.substring(idx2);
					}
					else
					{
						fNameOnly = fNameOnly.substring(0, idx1);
						ext = null;
					}
				}
			}	// END for
			
			if (fileObj != null)
			{
				newFile = new File(TEMP_DIR + "/" + ownerIdS+"_"+chunkS);
				fileObj.renameTo(newFile);
				l.info("Saved chunk [" + chunkS + "] to " + newFile.getName());
			}
			if (!bCompletedFile)
				return;									// just receive a chunk
			
			// If I get here: I have received a completed file (might contain one or more chunk on drive)
			// time-stamp check is done on client: here always receive the file
			fPathName = pathName + "/" + fNameOnly;		// the full pathname of the file on server
			newFile = new File(fPathName);
			if (newFile.exists())
			{
				newFile.delete();						// remove the old version of the file first
				
				// remove the old attachment object
				ids = attMgr.findId(jwu, "Location='" + fPathName + "'");
				for (int i=0; i<ids.length; i++)
				{
					try
					{
						o = attMgr.get(jwu, ids[i]);
						attMgr.delete(o);
					}
					catch (PmpException e1) {}
				}
			}

			// merge the file: result is only one file on the array list
			unsplitBigFile(newFile, ownerIdS);
			if (lt > 0)
				newFile.setLastModified(lt);			// use the same timestamp as the original file on client
			l.info("    saved file (" + newFile.getPath() + ")");
			
			// ECC: now only one file at a time for uploading
			// create the attachment object
			attMgr.create(jwu,
					ownerIdS,
					fPathName,
					ext,
					compIdS,			// proj Id, put the company id here
					null,				// type: drive file, no type
					deptName);
			
			l.info("+++    Total 1 file saved.");			// always one file now
			
			////////////////////////////////////////////////////////////
			// remove deleted files to sync with client directory
			enum0 = mrequest.getParameterNames();
			ct = 0;
			while (enum0.hasMoreElements())
			{
				s = enum0.nextElement().toString();
				if (!s.startsWith(PrmClientConstant.REMOVE_LABEL))
					continue;
				
				// remove file
				fPathName = mrequest.getParameter(s);		// filename to be removed
				fPathName = pathName + "/" + fPathName; 	// complete pathname for the file
				fileObj = new File(fPathName);
				int cycle = 1;
				do
				{
					if (fileObj.delete())
					{
						l.info("    deleted file (" + fPathName + "): " + cycle);
						ct++;
						
						// remove attachment object
						ids = attMgr.findId(jwu, "Location='" + fPathName + "'");
						for (int i=0; i<ids.length; i++)
						{
							try
							{
								o = attMgr.get(jwu, ids[i]);
								attMgr.delete(o);
								l.info("   - del attmt object ["+ ids[i] + "]");
							}
							catch (PmpException e1) {}
						}
						break;	// done with delete: no cycling needed
					}
					else
					{
						// it seems like long filename .doc will fail: no idea why
						l.info("    !!! failed deleting file (" + fPathName + "): " + cycle);
						Thread.sleep(5000);		// wait for conditions
					}
				} while (cycle++ < 3);
			}
			
			if (ct > 0)
				l.info("---    Total " + ct + " files deleted.");
			
			// remember the upload time in the folder
			l.info("***** UploadFile.upload() completed at " + new Date());
			if (!bNoSpace)
				serverDir.setLastModified(new Date().getTime());

			return;
		}
		catch (Exception e)
		{
			String msg = e.toString();
			l.error("Exception catch: " + msg);
			e.printStackTrace();
			if (msg.contains("login"))
				throw new IOException(msg);			// passon the login exception
		}
	}	// END: upload()
	
	////////////////////////////////////////////
	private void unsplitBigFile(File newFile, String prefixS)
	{
		// if there is only one file in the chunk, then just fixed up the filename by removing the suffix digit
		// 35412_0 -> myFileName.pdf
		File dirObj = new File(uploadPath);
		MyFileFilter fil = new MyFileFilter(prefixS, "");
		File [] fList = dirObj.listFiles(fil);
System.out.println("**** chunks found in uploadPath = "+fList.length);		
		PrmClient.sortVersionFiles(fList);				// sort by name
		if (fList.length == 1)
		{
			// there is only one file, just fix the filename
			fList[0].renameTo(newFile);		// quickest: simply rename the file
			l.info(">>> Rename for single chunk file: " + newFile.getPath());
			return;
		}

		try
		{
			FileOutputStream fos = new FileOutputStream(newFile);
			FileInputStream fis;
			File fObj;
			byte [] bArr = new byte[BUFFER_SIZE];
			int len;
			l.info(">>> Merging " + newFile.getPath() + ": total " + fList.length + " chunks.");
			for (int i=0; i<fList.length; i++)
			{
				fObj = fList[i];
				fis = new FileInputStream(fObj);
				while ((len = fis.read(bArr)) > 0)
				{
					fos.write(bArr, 0, len);			// 2MB at a time
				}
				l.info("    + Merged " + fObj.getName());
				fis.close();
				fObj.delete();					// clean up
				fos.flush();
			}
			l.info("<<< Merge done.");
			fos.close();						// the file merge is done
		}
		catch (IOException e)
		{
			l.error("Got IOException in UploadFile.unsplitBigFile()");
			e.printStackTrace();
		}
		return;
	}
	
	////////////////////////////////////////////
	// recalculate the space used by the user, if it is closed to the limit, trigger a marketing email
	private void recalSpace(String uname)
		throws PmpException
	{
		// create a thread to recal space used by user
		// do it for every space area
		PstAbstractObject uObj = uMgr.get(jwu, uname);
		String path = uploadPath + "/" + String.valueOf(uObj.getObjectId());
		
		String pathName;
		int idx;
		File fObj;
		int size, totalSize=0;		// in MB
		
		Object [] areaArr = uObj.getAttribute(PrmClientConstant.ATTR_BACKUP);
		for (int i=0; i<areaArr.length; i++)
		{
			pathName = (String)areaArr[i];					// peace$D:/temp/folder1?@ADMIN;ENGR?#278
			if (pathName == null) break;
			
			pathName = getTruePath(pathName);				// peace/D-drive/temp/folder1
			
			// C:/Repository/CR/12345/peace/D-drive/Temp/folder1
			pathName = path + "/" + pathName;
			
			// recursively look into the filesystem to calculate space
			fObj = new File(pathName);
			size = Util2.getSize(fObj);
			
			// save the info in the Backup attribute
			uObj.removeAttribute(PrmClientConstant.ATTR_BACKUP, areaArr[i]);
			pathName = (String)areaArr[i];
			if ((idx = pathName.indexOf(PrmClientConstant.SIZE_TERM)) != -1)
				pathName = pathName.substring(0, idx);		// peace$D:/temp/folder1?@ADMIN;ENGR
			pathName += PrmClientConstant.SIZE_TERM + String.valueOf(size);
			uObj.appendAttribute(PrmClientConstant.ATTR_BACKUP, pathName);
			uMgr.commit(uObj);
			
			totalSize += size;
		}
		
		// save the total size in the user object
		uMgr.commit(uObj);
		
		Util2.updateSpaceUsed((PstUserAbstractObject)uObj);			// need to combine this with project space
		//uObj.setAttribute("SpaceUsed", new Integer(totalSize));
		//uMgr.commit(uObj);
		//l.info("Recal space for [" + uname + "] - space used: " + totalSize);
		
	}	// END: recalSpace()

	// return a list of projectID::projName that is authorized to access by the uname
	// the pairs are separated by :@:
	private void getProjectList(MultipartRequest mrequest, HttpServletResponse response)
	{
		PrintStream ostream = null;
		try
		{
			String uname = mrequest.getParameter("uname");
			PstAbstractObject uObj = uMgr.get(jwu, uname);
			int [] ids = pjMgr.findId(jwu, "TeamMembers=" + uObj.getObjectId());
			
			// send result back to caller
			ostream = getOutputStream(response);
			StringBuffer sBuf = new StringBuffer(4096);
			
			project pjObj;
			for (int i=0; i<ids.length; i++)
			{
				pjObj = (project)pjMgr.get(jwu, ids[i]);
				if (sBuf.length() > 0) sBuf.append(PrmClientConstant.TERMINATOR2);
				sBuf.append(ids[i]);
				sBuf.append(PrmClientConstant.TERMINATOR1);
				sBuf.append(pjObj.getDisplayName());
			}
			ostream.println(sBuf);
		}
		catch (Exception e)
		{
			if (ostream != null)
				ostream.println(PrmClientConstant.ERROR + " in UploadFile.getProjectList(): " + e.toString());
		}
		ostream.close();
	}	// END: getProjectList()

	// return a list of taskID::taskName that is authorized to access by the uname
	// the pairs are separated by :@:
	@SuppressWarnings("unchecked")
	private void getTaskList(MultipartRequest mrequest, HttpServletResponse response)
	{
		PrintStream ostream = null;
		try
		{
			//String uname = mrequest.getParameter("uname");
			String projIdS = mrequest.getParameter("projId");

			// need to get the latest plan for this project
			planManager planObjMgr = planManager.getInstance();
			int [] ids = planObjMgr.findId(jwu, "Status='Latest' && ProjectID='"+projIdS+"'");
			PstAbstractObject [] targetObjList = planObjMgr.get(jwu, ids);

			// there is only one plan which is latest for this project
			plan latestPlan = (plan)targetObjList[0];
			String latestPlanIdS = latestPlan.getObjectName();

			StringBuffer sBuf = new StringBuffer(4096);
			String tkName, taskIdS;
			int level, order;
			String[] levelInfo = new String[JwTask.MAX_LEVEL];
			Stack planStack = PrmProjThread.setupPlan(-1, null, null, jwu, projIdS, latestPlanIdS, false);
			if((planStack != null) && !planStack.empty())
			{		
				Vector rPlan = (Vector)planStack.peek();
				for(int i=0; i < rPlan.size(); i++)
				{
					Hashtable rTask = (Hashtable)rPlan.elementAt(i);
					//status = (String)rTask.get("Status");
					taskIdS = (String)rTask.get("TaskID");
					tkName = (String)rTask.get("Name");

					level = ((Integer)((Object [])rTask.get("Level"))[0]).intValue();
					order = ((Integer)((Object [])rTask.get("Order"))[0]).intValue() + 1;

					if (level == 0)
						levelInfo[level] = String.valueOf(order);
					else
						levelInfo[level] = levelInfo[level - 1] + "." + order;

					if (sBuf.length() > 0) sBuf.append(PrmClientConstant.TERMINATOR2);
					sBuf.append(taskIdS);
					sBuf.append(PrmClientConstant.TERMINATOR1);
					sBuf.append(levelInfo[level] + " " + tkName);
				}
			}
			
			// send result back to caller
			ostream = getOutputStream(response);
			ostream.println(sBuf);
		}
		catch (Exception e)
		{
			if (ostream != null)
				ostream.println(PrmClientConstant.ERROR + " in UploadFile.getTaskList(): " + e.toString());
		}
		ostream.close();
	}	// END: getTaskList()
	
	private PrintStream getOutputStream(HttpServletResponse response)
	{
		response.setContentType("text");
		OutputStream os;
		try {
			os = response.getOutputStream();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			return null;
		}
		PrintStream ostream = new PrintStream(os);
		return ostream;
	}
	
	@SuppressWarnings("unchecked")
	private String getUploadFileName(MultipartRequest mrequest)
	{
		// it should only be upload one segment file: simply put it in TEMP dir
		String paramS, chunkS, fName;
		File fileObj;
		
		Enumeration enum0 = mrequest.getFileNames();
		if (enum0.hasMoreElements())
		{
			// split files to smaller parts, label: filename5_0, filename5_1, etc.
			// but they come one file (chunk) per post until we see TIME_LABEL
			paramS = enum0.nextElement().toString();
			fileObj = mrequest.getFile(paramS);			// get the object, the upload is done when client post
			fName = fileObj.getName();

			// get chunk #
			chunkS = mrequest.getParameter(PrmClientConstant.CHUNK_LABEL);
			fName = fName.replace("_" + chunkS, "");
			
			// remove uname@@
			String uname = mrequest.getParameter("uname");
			fName = fName.replace(uname+"@@", "");
			return fName;
		}
		return "";
	}
	
	private String getTruePath(String pathName)
	{
		// pathName is in the form of
		// peace$D:/temp/folder1?@ADMIN;ENGR?#278
		// peace$D:/temp/folder1?@ADMIN;ENGR
		// peace$D:/temp/folder1?#278
		// peace$D:/temp/folder1
		
		int idx;
		String res;
		if ((idx = pathName.indexOf(PrmClientConstant.DEPT_TERM)) != -1)
			res = pathName.substring(0, idx).trim();	// peace$D:/temp/folder1
		else if ((idx = pathName.indexOf(PrmClientConstant.SIZE_TERM)) != -1)
			res = pathName.substring(0, idx).trim();	// peace$D:/temp/folder1
		else
			res = pathName.trim();
		
		res = res.replace("$", "/");					// peace/D:/temp/folder1
		res = res.replace(":", PrmClientConstant.DRIVE_STR);				// peace/D-drive/temp/folder1
		return res;
	}
}


