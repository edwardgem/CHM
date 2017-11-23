//
///////////////////////////////////////////////////////////////////////////////////////////
//
//	File:		PrmClientUpload.java
//	Author:		ECC
//	Date:		08/18/2008
//	Description:
//				To enable upload of a client machine to the server.  It surveys a list of
//				specified directories, and compares to the timestamp of last upload,
//				check if there any new files and upload them through HTTP posting to
//				the server by calling ClientHttpRequest.
//
//	Modification:
//				@ECC113009	Introduce new calling convention in order to support a better
//				progress bar.  First call prepareUploadFile() then call uploadSegment().
//
///////////////////////////////////////////////////////////////////////////////////////////
//

package oct.util.file;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.PrintStream;
import java.net.InetAddress;
import java.net.URL;
import java.util.ArrayList;
import java.util.Date;


public class PrmClientUpload extends PrmClient
{
	private static int uploadNum		= 0;			// monotonically inc to remember the # of file at work
	private static int removeNum		= 0;			// monotonically inc to remember the # of file to remove
	
	private static String companyIdS = PrmClientConstant.getXMLValue(PrmClientConstant.getPropFile(), "COMPANY");
	private static String userName = PrmClientConstant.getXMLValue(PrmClientConstant.getPropFile(), "USER");
	
	private static final String TMP_DIR = "C:/Windows/Temp";
	
	private static String backupStr = null;

	//
	// OLD convention (should be removed once current release is stable because there is no dependency)
	// client calling convention:
	// 1. call getUploadFolders() which returns a list of folders specified by users to be uploaded
	// 2. For each folder, call getFilesInFolder() which returns a list of files/folders in a folder.
	//    Note that it also returns Folders in the folder, so 1 and 2 needs to be recursive.
	// 3. For each top area, save the Backup attribute (in user obj) by calling backupArea().
	// 4. For each file, call uploadFile() to actually upload and get a status return.
	// 5. For each folder, when uploadFile() is all done, call cleanupFolder() to cleanup.
	// 6. When all top folders are done, call recalSpace()
	//
	
	// return an array of folders specified by the user
	// this is the first call before actual uploading can be done
	@Deprecated
	public static String [] getUploadFolders()
		throws IOException
	{
		if (!isLogin)
			throw new IOException("User is not connected.  Please login.");
		
		// return a list of folders specified by user in the properties file
		if (getHostname() == null)
			setHostname(InetAddress.getLocalHost().getHostName());
		setPaths(PrmClientConstant.getXMLValue(PrmClientConstant.getPropFile(), "UPLOAD"));
		String [] uploadPathArr = getPaths().split(PrmClientConstant.TERMINATOR1);
		String [] folderList = new String[uploadPathArr.length];
		for (int i=0; i<uploadPathArr.length; i++)
			folderList[i] = "*" + uploadPathArr[i];		// to be consistent, folder name starts with "*"
		return folderList;
	}
	
	// this is to record the backup area in the user object
	// only call this for the top area that needs to be recorded
	// ECC: needed for NEW convention also
	// this is called only when upload option is for RemoteBackup
	public static void backupArea(String folderPath)
		throws IOException
	{
		if (folderPath.charAt(0) == '*')
			folderPath = folderPath.substring(1);		// strip the leading "*"
		folderPath = folderPath.trim();					// c:/temp/folder1*

		// strip the trailing "*"
		if (folderPath.endsWith("*"))
			folderPath = folderPath.substring(0, folderPath.length()-1);
		
		// check to see if it is a file, if so, just get the file path
		folderPath = getFilePath(folderPath);
		
		// set up constant string for this folder: get ready to post
		String dirStr = setupDirStr(folderPath);

		// backup is peace$c:/temp/folder1@ADMIN;ENGR
		String uploadStr = getHostname() + "$" + folderPath;// peace$c:/temp/folder1*, only pass this for top area
		setupHttpRequestParam(uploadStr, getHostname(), dirStr, companyIdS, userName, "");

		ClientHttpRequest clientReq = new ClientHttpRequest(getHost() + "/servlet/UploadFile");
		setupHttpRequest(clientReq);
		//clientReq.setParameter("backup", uploadStr);		
		clientReq.post();
		
		backupStr = uploadStr;							// remember this string for later upload
	}

	/**
	 * return file names in the folderPath
	 * if folderPath endsWith a "*", then also return the folders within folderPath
	 * This call might return folders within the folderPath in which case the return name will be
	 * preceded by "*".
	 * This method also sets up the parameters to HTTP in the uploadFile() call
	 * 
	 * @param folderPath
	 * @return
	 */
	@SuppressWarnings("unchecked")
	public static String [] getFilesInFolder(String folderPath)
	{
		// no HTTP posting needed in this call, just look at the file system
		File dirObj;
		boolean bIncludeSubFolders = false;
		if (folderPath.charAt(0)=='*')
			folderPath = folderPath.substring(1);		// skip the leading "*"
		folderPath = folderPath.trim();					// c:/temp/folder1*

		if (folderPath.endsWith("*"))
		{
			bIncludeSubFolders = true;
			folderPath = folderPath.substring(0, folderPath.length()-1);	// remove the ending "*"
		}

		setupHttpRequestDir(setupDirStr(folderPath));
		
		dirObj = new File(folderPath);
		if (!dirObj.exists())
			return new String[0];						// local directory has been removed

		// if the pass-in name is not a directory, then
		// simply return it to the caller, assuming it is a file
		if (!dirObj.isDirectory()) {
			// it is a file, just return its name
			String [] res = new String[1];
			res[0] = dirObj.getPath();
			return res;
		}

		File [] fList = dirObj.listFiles();				// I might want to sort the list from files to directories

		//Util2.sortDirectory(fList);	// ECC: somehow doesn't work, need debug

		ArrayList aL = new ArrayList();
		String fName;
		for (int i=0; i<fList.length; i++)
		{
			if (fList[i].isDirectory())
			{
				if (!bIncludeSubFolders)
					continue;
				else
					fName = "*" + fList[i].getPath() + "*";		// this is a folder and need to get subFolders
			}
			else
				fName = fList[i].getPath();
			aL.add(fName);
		}
		return (String [])aL.toArray(new String [0]);
	}

	/*************************************************************************************
	 * Call to prepare for upload a file.  It returns the number of segments that the
	 * PrmClientUpload class is going to split the file into for the actual upload.
	 * Caller should follow this method by calling uploadSegment() in a loop to upload
	 * all the segments of the file.
	 * If the file is up-to-date, then it will return 0.
	 * 
	 * @param fileName the absolute pathname of the file to be uploaded
	 * @return numberOfSegment the number of segments PrmClientUpload is going to split the
	 * file into on uploading.  Return 0 if the file is up-to-date.
	 * @throws IOException 
	 */
	public static int prepareUploadFile(String fileName)
		throws IOException
	{
		PrmClient.out("prepareUploadFile() for " + fileName);
		if (fileName.endsWith(PrmClientConstant.LOGFILE_NAME)) {
			PrmClient.out("   ignore logfile");
			return 0;
		}
		
		File fObj = new File(fileName);
		if (!fObj.exists())
			throw new IOException("Cannot find file [" + fileName + "]");
		
		if (isUptoDate(fileName)) {
			PrmClient.out("   up-to-date");
			return 0;
		}
		
		int numOfSegment = 0;
		long fSize = fObj.length();
		numOfSegment = (int)Math.ceil(((double)fSize) / PrmClientConstant.UPLOAD_CHUNK_SIZE);
		PrmClient.out("   total segments = " + numOfSegment);
		return numOfSegment;
	}	// END: prepareUploadFile()
	
	/************************************************************************************
	 * Uploads the specified segment of the file.  The number of segments to be uploaded for
	 * a file is determined by the upload chunk size.  Caller of this method should first
	 * call prepareUploadFile() to get the number of segments.
	 * 
	 * @param fileName this is the absolute file name of the file to be uploaded.
	 * @param segmentNo is the index of the file segment to be uploaded in this call.
	 * @return void.
	 * @throws Exception
	 */
	public static void uploadSegment(String fileName, int segmentNo, int numOfSegment)
		throws Exception
	{
		// TODO this should be optimized by handshaking better with caller
		// so that I reduce the read/skip
		PrmClient.out("uploadSegment() for " + fileName + ": " + segmentNo);
		//int numOfSegment = prepareUploadFile(fileName);
		if (segmentNo >= numOfSegment)
			return;
		
		// create the chunk file for upload
		File fObj = new File(fileName);
		int offset = segmentNo * PrmClientConstant.UPLOAD_CHUNK_SIZE;
		FileInputStream fis = new FileInputStream(fObj);
		String tempFname = TMP_DIR + "/" + userName + "@@" + getChunkFilename(fObj, segmentNo);
		File chunkFile = new File(tempFname);
		FileOutputStream fos = new FileOutputStream(chunkFile);
		byte [] bArr = new byte[PrmClientConstant.UPLOAD_CHUNK_SIZE];
		fis.skip(offset);
		int len = fis.read(bArr);
		fos.write(bArr, 0, len);
		
		// closing
		fos.flush();
		fos.close();
		fis.close();
		
		// post file upload
		String dirPath = getDirPath(fObj);
		ClientHttpRequest req = new ClientHttpRequest(getHost() + "/servlet/UploadFile");
		req.setParameter(PrmClientConstant.FILENAME_LABEL, chunkFile);
		req.setParameter(PrmClientConstant.CHUNK_LABEL, String.valueOf(segmentNo));
		req.setParameter("uname", userName);

		String uploadOp = PrmClientConstant.getXMLValue(PrmClientConstant.getPropFile(), PrmClientConstant.UPLOAD_OPT_LABEL);
		req.setParameter(PrmClientConstant.UPLOAD_OPT_LABEL, uploadOp);
		
		// check to see if we need to pass destination info
		if (segmentNo == numOfSegment-1)		// last one
		{
			PrmClient.out("   uploading last segment");
			long lastModTime = fObj.lastModified();
			req.setParameter(PrmClientConstant.TIME_LABEL+userName, String.valueOf(lastModTime));

			if (uploadOp!=null && uploadOp.equalsIgnoreCase(PrmClientConstant.UP_OPT_TOPROJ))
			{
				String projIdS = PrmClientConstant.getXMLValue(PrmClientConstant.getPropFile(), PrmClientConstant.PROJ_LABEL);
				String taskIdS = PrmClientConstant.getXMLValue(PrmClientConstant.getPropFile(), PrmClientConstant.TASK_LABEL);
				if (PrmClient.isEmptyString(projIdS) || PrmClient.isEmptyString(taskIdS))
				{
					throw new Exception("For upload to project, both PROJECT and TASK must contain valid ID.");
				}
				req.setParameter(PrmClientConstant.PROJ_LABEL, projIdS);
				req.setParameter(PrmClientConstant.TASK_LABEL, taskIdS);
			}
			else
			{				
				if (backupStr == null)
					throw new Exception("You must call BackupArea() before uploading.");
				setupHttpRequest(req);	// backup, hostname, dirName, cid, uname, dept
				req.setParameter(PrmClientConstant.PATH_LABEL, dirPath);	// C-drive/Temp/folder1/sub-folder1
			}
		}
		//setupHttpRequest(req);
		InputStream in = req.post();			// upload
		BufferedReader din = new BufferedReader(new InputStreamReader(in));
		String line;
		if ((line = din.readLine()) != null)
		{
			if (line.contains(PrmClientConstant.ERROR))
				throw new Exception("Error uploading segment.");
		}
		
		if (segmentNo == numOfSegment-1)		// last one
			setLastUploadTime(dirPath, fObj.getName());
		chunkFile.delete();						// remove the temporary chunk
		return;
	}
	
	// actually upload a file by its pathname
	// throw Exception if the file doesn't exist or if it is a directory
	// return 1 if succeeded
	@Deprecated
	public static int uploadFile(String fPathName)
		throws Exception
	{
		File fObj = new File(fPathName);
		if (!fObj.exists())
			throw new Exception("Failed in PrmClientUpload.uploadFile(): File [" + fObj.getPath() + "] does not exist.");
		if (fObj.isDirectory())
			throw new Exception ("Failed in PrmClientUpload.uploadFile(): [" + fObj.getPath() + "] is a directory.");

		String dirPath = getDirPath(fObj);
		return upload(fObj, dirPath, false);			// only calls upload() for file
	}
	
	// TODO might be meaningful call to use
	public static void cleanupFolder(String dirPath)
		throws IOException
	{
		///////////////////////
		// check if we need to remove old files
		dirPath = dirPath.trim();
		File dirObj = new File(dirPath);
		if (!dirObj.isDirectory())
			return;
		
		File [] fList = dirObj.listFiles();
		ClientHttpRequest clientReq = new ClientHttpRequest(getHost() + "/servlet/UploadFile");
		boolean bNeedRemove = checkRemoveFile(clientReq, fList, dirPath);	// will set up POST params for HTTP
		if (bNeedRemove)
		{
			clientReq.setParameter(PrmClientConstant.PATH_LABEL, dirPath.replace(":", PrmClientConstant.DRIVE_STR));	// C-drive/Temp/folder1/sub-folder1
			setupHttpRequest(clientReq);
			clientReq.post();
		}
	}
	
	@Deprecated
	public static void recalSpace()
		throws IOException
	{
		if (getNeedRecalSpace())		// reevaluate user free space
		{
			ClientHttpRequest.post(new URL(getHost() + "/servlet/UploadFile"), PrmClientConstant.RECALSP_LABEL, userName);
			setNeedRecalSpace(false);
		}
	}

	// OLD (obsolete)
	// call to upload a file or a directory recursively
	// there is a log file in each directory to be backup.  For files that are not on the log
	// definitely need backup.  If file is on the log, then compare the timestamp to decide.
	// lookup the logfile for the time of last upload of this file and
	// compare to the file's lastModified()
	@Deprecated
	@SuppressWarnings("unchecked")
	private static int upload(File fObj, String dirPath, boolean bRecursive)
		throws IOException
	{
		String fName = fObj.getName();
		if (fObj.isDirectory())
		{
			if (bRecursive)
			{
				int ct = 0;
				dirPath += "/" + fName;					// go down to this directory
				File [] fList = fObj.listFiles();
				out("... uploading " + dirPath);
				
				if (fList.length > 0)
				{
					// create a new HttpRequest for posting for each directory
					for (int i=0; i<fList.length; i++)
						ct += upload(fList[i], dirPath, bRecursive);
				}
				
				// check for removing files
				ClientHttpRequest req = new ClientHttpRequest(getHost() + "/servlet/UploadFile");
				boolean bNeedRemove = checkRemoveFile(req, fList, dirPath);
				
				if (bNeedRemove)
				{
					// upload for all files in this directory
					req.setParameter(PrmClientConstant.PATH_LABEL, dirPath.replace(":", PrmClientConstant.DRIVE_STR));	// C-drive/Temp/folder1/sub-folder1
					setupHttpRequest(req);
					req.post();
				}
				return ct;
			}
			else
				return 0;			// ignore directory
		}
		
		// it is a file, just upload
		if (fName.equals(PrmClientConstant.LOGFILE_NAME))
			return 0;				// ignore logfile

		long lastUploadTime = getLastUploadTime(dirPath, fName);
		long lastModTime = fObj.lastModified();
		String dirPathX = dirPath.replace(":", PrmClientConstant.DRIVE_STR);
		String perctgS;				// percentage
		if (lastModTime > lastUploadTime)
		{
			out("    > + " + fName);
			getWindowStatusBar().setText("Uploading " + fName + " ... 0%");
			ArrayList fArrList = splitBigFile(fObj);		// if fObj is > UPLOAD_CHUNK_SIZE, it will split
			for (int i=0; i<fArrList.size(); i++)
			{
				ClientHttpRequest req = new ClientHttpRequest(getHost() + "/servlet/UploadFile");
				req.setParameter(PrmClientConstant.PATH_LABEL, dirPathX);	// C-drive/Temp/folder1/sub-folder1
				req.setParameter(PrmClientConstant.FILENAME_LABEL+uploadNum, fArrList.get(i));
				req.setParameter(PrmClientConstant.CHUNK_LABEL, String.valueOf(i));
				if (i == fArrList.size()-1)		// last one
					req.setParameter(PrmClientConstant.TIME_LABEL+userName, String.valueOf(lastModTime));
				setupHttpRequest(req);
				req.post();			// upload one file at a time
				perctgS = "" + (i+1)*100/fArrList.size() + "%";
				getWindowStatusBar().setText("Uploading " + fName + " ... " + perctgS);
			}
			
			setLastUploadTime(dirPath, fName);
			uploadNum++;
			return 1;
		}
		return 0;
	}
	
	/////////////////////////////////////////////////////////////////////////////
	// private methods
	
	/**
	 * Check timestamp in .crlog to decide if file is up-to-date
	 * @param fileName
	 * @return
	 */
	private static boolean isUptoDate(String fileName) {
		if (fileName==null)
			return false;
		File f = new File(fileName);
		if (!f.exists())
			return false;		// no such file to upload
		
		fileName = fileName.replaceAll("\\\\", "/");
		int idx = fileName.lastIndexOf('/');
		String dirName, fileNameOnly;
		if (idx < 0) {
			dirName = ".";
			fileNameOnly = fileName;
		}
		else {
			dirName = fileName.substring(0, idx);
			fileNameOnly = fileName.substring(idx+1);
		}
		
		long lastUploadTime = getLastUploadTime(dirName, fileNameOnly);
		long lastModTime = f.lastModified();
		
		return lastModTime <= lastUploadTime;
	}

	@Deprecated
	private static ArrayList <File> splitBigFile(File fObj)
		throws IOException
	{
		ArrayList <File> fArrList = new ArrayList<File>();
		FileInputStream fis = new FileInputStream(fObj);
		FileOutputStream fos;
		File aChunk;
		int ct = 0;
		byte [] bArr = new byte[PrmClientConstant.UPLOAD_CHUNK_SIZE];
		
		String fName;
		long fSize = fObj.length();
		long total = 0, chunkTotal;
		int len;
		
		out(">>> Splitting file: " + fObj.getName() + " (" + fSize + ")");
		while (total < fSize)
		{
			fName = TMP_DIR + "/" + getChunkFilename(fObj, ct++);
			aChunk = new File(fName);
			fos = new FileOutputStream(aChunk);
			chunkTotal = 0;
			while (chunkTotal<PrmClientConstant.UPLOAD_CHUNK_SIZE)
			{
				len = fis.read(bArr);
				if (len < 0)
					break;
				fos.write(bArr, 0, len);
				chunkTotal += len;
			}
			total += chunkTotal;
			fos.flush();
			fos.close();
			fArrList.add(aChunk);
			aChunk.deleteOnExit();						// cleanup
		}
		fis.close();
		out("    total " + fArrList.size() + " chunks.");
		return fArrList;
	}
	
	private static String getChunkFilename(File fObj, int chunkNum)
	{
		String fName, fName1, fName2="";
		fName = fObj.getName();
		int idx = fName.lastIndexOf('.');
		if (idx == -1)
			fName1 = fName + "_";
		else
		{
			fName1 = fName.substring(0, idx) + "_";		// myFileName_
			fName2 = fName.substring(idx);				// .pdf
		}
		String chunkFilename = fName1 + chunkNum + fName2;	// myFileName_1.pdf
		return chunkFilename;
	}
	
	private static String getDirPath(File fObj)
	{
		String dirPath = fObj.getPath().replaceAll("\\\\", "/");
		int idx = dirPath.lastIndexOf('/');
		if (idx != -1)
			dirPath = dirPath.substring(0, idx);
		return dirPath;
	}
	
	/**
	 * strip the filename and return only the path part of the file to caller.
	 * if fName is a folder, return fName untouched.
	 * @param fName
	 * @return
	 */
	private static String getFilePath(String fName) {
		if (fName==null || fName.length()<=0)
			return fName;
		
		fName = fName.replaceAll("\\\\", "/");
		int idx = fName.lastIndexOf('/');
		String dirName;
		if (idx < 0) {
			dirName = "";
		}
		else {
			dirName = fName.substring(0, idx);
		}
		return dirName;
	}
	
	// check to see if we need to remove any files from the repository to sync with this directory
	@Deprecated
	private static boolean checkRemoveFile(ClientHttpRequest req, File [] fList, String dir)
	{
		// compare the logfile with the fList of this directory to determine whether to remove any files
		// both the logfile and the fList are already sorted by name.  Compare and if a file is found
		// in the logfile and not in fList, that file can be removed.
		BufferedReader din = openLogFile(dir);
		if (din == null)
			return false;			// not found: need upload
		
		String s, line, delStr="";
		String [] sa;
		int rc, idx=0;
		boolean bFound = false;
		boolean bNoMore;

		try
		{
			while ((line = din.readLine()) != null)
			{
				line = line.trim();
				if ((line.length() <= 0) || (line.charAt(0) == '#'))
					continue;						// comment line and blank line

				sa = line.split("\t");
				s = sa[0].trim();		// the filename
				
				bNoMore = true;
				for (int i=idx; i<fList.length; i++)
				{
					// step through the directory
					if (fList[i].isDirectory() || fList[i].getName().equals(PrmClientConstant.LOGFILE_NAME))
					{
						idx = i+1;
						continue;	// only compare files
					}

					if ((rc = s.compareToIgnoreCase(fList[i].getName())) == 0)
					{
						// found the file, move on to the next one on the log
						idx = i+1;
						bNoMore = false;
						break;
					}
					else if (rc < 0)
					{
						// the file in the logfile is not found in the directory: need remove
						bFound = true;
						bNoMore = false;
						delStr += s + "@@";		// put a terminator there for comparision later
						req.setParameter(PrmClientConstant.REMOVE_LABEL + removeNum++, s);
						out("    < - "+ s);
						break;
					}
					// check the next file on fList
				}

				// exhaust the fList already: all files in the rest of logfile should be deleted
				if (bNoMore && idx>=fList.length)
				{
					bFound = true;
					delStr += s + "@@";		// put a terminator there for comparision later
					req.setParameter(PrmClientConstant.REMOVE_LABEL + removeNum++, s);
					out("    < - "+ s);
					continue;					// next file on the logfile
				}
			}
			din.close();
			
			if (bFound)
			{
				deleteFileRecord(dir, delStr);
				return true;
			}
			else
				return false;
		}
		catch (IOException e) {return false;}
	}
	
	private static BufferedReader openLogFile(String dir)
	{
		File logF = new File(dir + "/" + PrmClientConstant.LOGFILE_NAME);						// C:/doc/abc/.crlog
		FileInputStream in = null;
		try {in = new FileInputStream(logF);}
		catch (FileNotFoundException e)
		{
			return null;
		}
		return new BufferedReader(new InputStreamReader(in));
	}
	
	// check the logfile of this directory to review last upload time of this file
	private static long getLastUploadTime(String dir, String fName)
	{
		// read from the local directory logfile
		BufferedReader din = openLogFile(dir);
		if (din == null)
			return 0;			// not found: need upload

		// parse the file line by line
		String s, line;
		String [] sa;
		try
		{
			while ((line = din.readLine()) != null)
			{
				line = line.trim();
				if ((line.length() <= 0) || (line.charAt(0) == '#'))
					continue;						// comment line and blank line

				sa = line.split("\t");
				s = sa[0].trim();
				if (s.equals(fName))
				{
					// found the right file, update timestamp and return last timestamp
					long lastTime = Long.parseLong(sa[1].trim());
					din.close();
					return lastTime;
				}
			}
			din.close();
		}
		catch (IOException e) {return 0;}

		return 0;
	}	// END: getLastUpload()
	
	// set the last upload timestamp of fName to the current time
	private static void setLastUploadTime(String dir, String fName)
	{
		// read from the local directory logfile
		File logF = new File(dir + "\\" + PrmClientConstant.LOGFILE_NAME);						// C:/doc/abc/.crlog
		
		FileInputStream in = null;
		try {
			if (!logF.exists())
				logF.createNewFile();

			in = new FileInputStream(logF);
		}
		catch (IOException e)
		{
			// error: the file should be there because i just read it
			out("Failed to open logfile [" + dir + "\\" + PrmClientConstant.LOGFILE_NAME + "] in setLastUploadTime().");
			return;
		}
		BufferedReader  din = new BufferedReader(new InputStreamReader(in));

		// parse and copy the file line by line
		String s, line;
		String [] sa;
		int rc;
		boolean bFound = false;

		try
		{
			File tFile = new File("tempCR");
			PrintStream ostream = new PrintStream(new FileOutputStream(tFile));
			while ((line = din.readLine()) != null)
			{
				line = line.trim();
				if ((line.length() <= 0) || (line.charAt(0) == '#'))
				{
					ostream.println(line);			// copy the line
					continue;						// comment line and blank line
				}
				sa = line.split("\t");
				s = sa[0].trim();
				//if (s.equals(fName))
				if ((rc = s.compareToIgnoreCase(fName)) >= 0)
				{
					// either found the filename or it's a new file, insert the new timestamp for this file
					bFound = true;
					if (rc == 0) line = null;		// need to copy the read line
					updateTimestamp(ostream, din, fName, line);	// this will finish copying the rest of the file

					break;
				}
				else
					ostream.println(line);			// copy the line
			}
			if (!bFound)
			{
				// just append the new timestamp record in the logfile
				din.close();
				ostream.println(fName + "\t" + new Date().getTime());
				ostream.flush();
				ostream.close();
			}
			logF.delete();					// remove the old logF
			tFile.renameTo(logF);			// save the new logF
		}
		catch (IOException e) {e.printStackTrace(); return;}

		return;
	}	// END: setLastUpload()

	
	private static void updateTimestamp(PrintStream ostream, BufferedReader din, String fName, String nxtLine)
		throws IOException
	{
		// update the current fName record and then copy the rest of the file.
		String line;
		ostream.println(fName + "\t" + new Date().getTime());
		if (nxtLine != null)
			ostream.println(nxtLine);		// need to copy the next line back
		while ((line = din.readLine()) != null)
		{
			ostream.println(line);			// copy the line
		}
		din.close();
		ostream.flush();
		ostream.close();
	}
	
	private static void deleteFileRecord(String dir, String delStr)
		throws IOException
	{
		// read from the local directory logfile
		BufferedReader din = openLogFile(dir);
		if (din == null)
			return;			// not found

		// parse and copy the file line by line
		String s, line;
		String [] sa;
		try
		{
			File tFile = new File("tempCR");
			PrintStream ostream = new PrintStream(new FileOutputStream(tFile));
			while ((line = din.readLine()) != null)
			{
				line = line.trim();
				if ((line.length() <= 0) || (line.charAt(0) == '#'))
				{
					ostream.println(line);			// copy the line
					continue;						// comment line and blank line
				}
				sa = line.split("\t");
				s = sa[0].trim() + "@@";			// put a terminator at the end of filename for comparison
				if (delStr.indexOf(s) != -1)
				{
					// delete this line, i.e., ignore copying
				}
				else
					ostream.println(line);			// copy the line
			}

			// cleanup files
			din.close();
			ostream.flush();
			ostream.close();
			
			File logF = new File(dir + "/" + PrmClientConstant.LOGFILE_NAME);		// C:/doc/abc/.crlog
			logF.delete();							// remove the old logF
			tFile.renameTo(logF);					// save the new logF
		}
		catch (IOException e) {return;}

		return;
	}	// deleteFileRecord
	
	private static String setupDirStr(String folderPath)
	{
		int idx;
		String drive;
		String dirStr = null;
		if ((idx = folderPath.indexOf(":")) != -1)
		{
			drive = folderPath.substring(0,idx) + PrmClientConstant.DRIVE_STR;		// D-drive
			dirStr = drive + folderPath.substring(idx+1);	// root (top) area.   D-drive/Temp/folder1
		}
		return dirStr;
	}
	
	static String S1, S2, S3, S4, S5, S6;
	private static void setupHttpRequestParam(
			String s1, String s2, String s3, String s4, String s5, String s6)
	{
		S1 = s1;
		S2 = s2;
		S3 = s3;
		S4 = s4;
		S5 = s5;
		S6 = s6;
	}
	
	private static void setupHttpRequestDir(String dirName) {S3 = dirName;}
	
	private static void setupHttpRequest(ClientHttpRequest req)
		throws IOException
	{
		req.setParameter("backup", S1);		// peace$c:/temp/folder1@ADMIN;ENGR
		req.setParameter("hostname", S2);
		req.setParameter("dirName", S3);	// D-drive/Temp/folder1
		req.setParameter("cid", S4);
		req.setParameter("uname", S5);
		req.setParameter("dept", S6);		// set department authority for this directory
		setNeedRecalSpace(true);
	}	

}
