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
//
/////////////////////////////////////////////////////////////////////
/**
* upload (backup) directories from client to server
*/

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.io.PrintStream;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import main.PrmThread;
import oct.codegen.attachment;
import oct.codegen.attachmentManager;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstGuest;
import oct.pst.PstManager;
import oct.pst.PstUserAbstractObject;
import oct.util.file.PrmClientConstant;

import org.apache.log4j.Logger;

import util.PrmLog;
import util.Util;
import util.Util2;

import com.oreilly.servlet.MultipartRequest;

public class DownloadFile extends HttpServlet
{
	private static final long serialVersionUID = 10132008;
	
	private static final String UPLOAD_PATH = Util.getPropKey("pst", "FILE_UPLOAD_PATH");
	private static Logger l = PrmLog.getLog();
	private static user jwu = PrmThread.getuser();
	private static String userName;
		
	private static attachmentManager attMgr = null;
	private static userManager uMgr = null;
	static {
		try {
			attMgr = attachmentManager.getInstance();
			uMgr = userManager.getInstance();
		}
		catch (PmpException e){}
	}

	public void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException
	{
	}
	
	/**
	* Handle POST requests
	*/
	public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException
	{
		MultipartRequest mrequest = new MultipartRequest(request, UPLOAD_PATH, 1024);
		
		// check if this is init: attempt login authority
		// this is a duplicate of Upload login.  It is unnecessary.  Only one of them is needed.
		String s;
		if ((s = mrequest.getParameter("USER")) != null)
		{
			userName = s;
			String passwd = mrequest.getParameter("PASSWORD");
			try
			{
				PstUserAbstractObject gUser = (PstUserAbstractObject) PstGuest.getInstance();
				uMgr.login(gUser, userName, passwd);
			}
			catch (Exception e) {throw new IOException("Fail to login");}
			return;
		}

		String op = mrequest.getParameter(PrmClientConstant.OP_LABEL);
		try
		{
			if (op.equals(PrmClientConstant.OP_GET_SHARE))
			{
				// get the list of shared files
				getShareFileList(mrequest, response);
			}
			else if (op.equals(PrmClientConstant.OP_GET_SEGMENT))
			{
				// get number of segments to be breaking into on download
				getNumOfSegment(mrequest, response);
			}
			else if (op.equals(PrmClientConstant.OP_DOWNLOAD_SEGMENT))
			{
				downloadSegment(mrequest, response);
			}
			else
			{
				// OLD: to download one file
				download(mrequest, response);
			}
		}
		catch (Exception e)
		{
			l.error("Exception in Download() with opcode [" + op + "]");
			e.printStackTrace();
		}
	}
	
	private void getNumOfSegment(MultipartRequest mrequest, HttpServletResponse response)
		throws PmpException, IOException
	{
		response.setContentType("text");
		OutputStream os = response.getOutputStream();
		PrintStream ostream = new PrintStream(os);

		String attIdS = mrequest.getParameter(PrmClientConstant.ATTID);
		PstAbstractObject aObj = attMgr.get(jwu, attIdS);
		String loc = UPLOAD_PATH + (String)aObj.getAttribute("Location")[0];
		File fObj = new File(loc);
		if (fObj.isDirectory())
		{
			ostream.println(PrmClientConstant.ERROR + ": cannot call get segment with a folder object.");
		}
		else
		{
			// get the file size
			long fSize = fObj.length();
			int numOfSegment = (int)Math.ceil(((double)fSize) / PrmClientConstant.DOWNLOAD_CHUNK_SIZE);
System.out.println("numOfSegment = " + numOfSegment);			
			ostream.println(numOfSegment);
		}
		
		os.flush();
		os.close();
		
		return;
	}	// END: getNumOfSegment()

	private void downloadSegment(MultipartRequest mrequest, HttpServletResponse response)
		throws PmpException, IOException
	{
		// read and return a segment of a file
		response.setContentType("text");
		OutputStream os = response.getOutputStream();
		PrintStream ostream = new PrintStream(os);

		String attIdS = mrequest.getParameter(PrmClientConstant.ATTID);
		PstAbstractObject aObj = attMgr.get(jwu, attIdS);
		String loc = UPLOAD_PATH + (String)aObj.getAttribute("Location")[0];
		File fObj = new File(loc);
		if (fObj.isDirectory())
		{
			ostream.println(PrmClientConstant.ERROR + ": cannot call download segment with a folder object.");
		}
		else
		{
			// get the segment
			long fSize = fObj.length();
			int numOfSegment = (int)Math.ceil(((double)fSize) / PrmClientConstant.DOWNLOAD_CHUNK_SIZE);
			int segmentNo = Integer.parseInt(mrequest.getParameter(PrmClientConstant.CHUNK_LABEL));
			if (segmentNo >= numOfSegment)
			{
				ostream.println(PrmClientConstant.ERROR + ": segment number exceed size of file.");
			}
			else
			{
				int offset = segmentNo * PrmClientConstant.DOWNLOAD_CHUNK_SIZE;
				FileInputStream fis = new FileInputStream(fObj);
				byte [] bArr = new byte[PrmClientConstant.DOWNLOAD_CHUNK_SIZE];
				int len = fis.read(bArr, offset, PrmClientConstant.DOWNLOAD_CHUNK_SIZE);
				os.write(bArr, 0, len);
				fis.close();
			}
		}
		
		os.flush();
		os.close();
		
		return;
	}	// END: downloadSegment();
	
	private void getShareFileList(MultipartRequest mrequest, HttpServletResponse response)
		throws IOException, ServletException, PmpException
	{
		// get the list of files shared by this user
		// if there is an attId (of a folder), then get the list of files in the folder
		PstAbstractObject o;
		String uname = mrequest.getParameter(PrmClientConstant.USER_LABEL);
		if (uname==null) uname = userName;			// fetch it from the login name
		int uid = PstManager.getIdByName(jwu, uMgr.getOrgId(), uname);

		response.setContentType("text");
		OutputStream os = response.getOutputStream();
		PrintStream ostream = new PrintStream(os);
		
		// return the file info one per line (filename::ID::owner::size)
		user uObj;
		File fObj = null;
		String s, fInfo, loc;
		boolean isShareFolder;
		
		String attIdS = mrequest.getParameter(PrmClientConstant.ATTID);

		if (attIdS == null)
		{
			// list the share files and folders on ep_home.jsp
			int []  ids = attMgr.findId(jwu, "ShareID='" + uid + "'");
	
			for (int i=0; i<ids.length; i++)
			{
				o = attMgr.get(jwu, ids[i]);
				
				s = (String)o.getAttribute("Type")[0];
				if (s!=null && s.equals(attachment.TYPE_FOLDER))
				{
					// this is a shared folder.  e.g. peace$C:/Doc/Company
					fInfo = (String)o.getAttribute("Name")[0];					// folder doesn't have size so caller can tell
					fInfo = "(" + fInfo.replace("$", ") ");						// peace$C:/Doc to (peace) C:/Doc
					isShareFolder = true;
				}
				else
				{
					// regular shared files
					loc = (String)o.getAttribute("Location")[0];
					fInfo = loc.substring(loc.lastIndexOf("/")+1);				// e.g. /31365/6 IT Decisions(1).pdf
					
					if (Util.isAbsolutePath(loc))
						fObj = new File(loc);
					else
						fObj = new File(UPLOAD_PATH + loc);						// file size string
					if (!fObj.exists())
						continue;
					isShareFolder = false;
				}
				
				fInfo += PrmClientConstant.TERMINATOR1 + o.getObjectId();		// attId
				
				uObj = (user)uMgr.get(jwu, Integer.parseInt((String)o.getAttribute("Owner")[0]));
				fInfo += PrmClientConstant.TERMINATOR1 + uObj.getFullName();	// owner fullname
	
				if (!isShareFolder)
					fInfo += PrmClientConstant.TERMINATOR1 + Util2.fileSizeDisplay(fObj.length());
				
				ostream.println(fInfo);
			}
		}	// END if list share files
		else
		{
			// list the files within a folder
			PstAbstractObject aObj = attMgr.get(jwu, attIdS);
			if (!aObj.getAttribute("Type")[0].equals(attachment.TYPE_FOLDER))
				ostream.println(PrmClientConstant.ERROR + ": the attachment [" + attIdS + "] is not of folder type.");
			else
			{
				// go to the corresponding directory and list files
				loc = UPLOAD_PATH + "/" + (String)aObj.getAttribute("Owner")[0]
				           + (String)aObj.getAttribute("Location")[0];
				File dirObj = new File(loc);
				File [] fList = dirObj.listFiles();			// file lists in the folder
				
				// return filename::attId::owner::size per line
				boolean isDirectory;
				String fPathName;
				int [] ids;
				for (int i=0; i<fList.length; i++)
				{
					fObj = fList[i];
					fPathName = fObj.getPath().replaceAll("\\\\", "/");		// for passing to actions
					
					if (fObj.isDirectory())
						isDirectory = true;
					else
						isDirectory = false;
					fInfo = fObj.getName();		// for display
					ids = attMgr.findId(jwu, "Location='" + fPathName + "'");
					if (ids.length > 0)
					{
						o = attMgr.get(jwu, ids[0]);
						fInfo += PrmClientConstant.TERMINATOR1 + o.getObjectId();
						uObj = (user)uMgr.get(jwu, Integer.parseInt((String)o.getAttribute("Owner")[0]));
						fInfo += PrmClientConstant.TERMINATOR1 + uObj.getFullName();	// owner full-name
						
						if (!isDirectory)
							fInfo += PrmClientConstant.TERMINATOR1 + Util2.fileSizeDisplay(fObj.length());
						
						ostream.println(fInfo);
					}
					else
						continue;				// can't find the corresponding attObj to this file
				}	// END for loop of all files in this folder
			}	// END else is listing files within a folder
		}
		os.flush();
		os.close();
	}	// END: getShareFileList()
	
	private void download(MultipartRequest mrequest, HttpServletResponse response)
		throws IOException, ServletException, PmpException
	{
		// ECC: should check for authority based on ShareID
		PstAbstractObject attObj;
		File fObj;
		String attId = mrequest.getParameter(PrmClientConstant.FILEID_LABEL);
		attObj = attMgr.get(jwu, attId);
		String loc = (String)attObj.getAttribute("Location")[0];
		
		response.setContentType("image");
		if (Util.isAbsolutePath(loc))
			fObj = new File(loc);
		else
			fObj = new File(UPLOAD_PATH + loc);								// file size string
		FileInputStream fis = new FileInputStream(fObj);
		
		byte [] contentBuf = new byte[8192];
		OutputStream os = response.getOutputStream();
		
		int count = 0;
		int len = 0; // Check total length read
		while((count = fis.read(contentBuf)) != -1)
		{
			os.write(contentBuf, 0, count);
			os.flush();
			len += count;
		}

		os.close();
		l.info("--- download file: "+fObj.getPath());
	}	// END: download()
	
}


