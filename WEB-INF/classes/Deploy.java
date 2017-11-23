//
//	Copyright (c) 2009 EGI Technologies Inc.  All rights reserved.
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
* deploy source files from client to server
*/

import java.io.File;
import java.io.IOException;
import java.io.OutputStream;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.log4j.Logger;

import util.PrmLog;
import util.Util;
import util.Util3;

import com.oreilly.servlet.MultipartRequest;

public class Deploy extends HttpServlet implements DeployBase
{
	/**
	 * 
	 */
	private static final long serialVersionUID = 10182009;
	private static Logger l = PrmLog.getLog();
	
	private static String uploadPath = Util.getPropKey("pst", "FILE_UPLOAD_PATH");
	private static String sourcePath = Util3.copyPathExceptLastPart(Util.getPropKey("pst", "SHOW_FILE_PATH"));
	
	private static final int L10M			= 10*1024*1024;

	// go to the local Tomcat directory, compare timestamp and decide to upload
	public Deploy()
	{
	}
	
	/**
	* Handle POST requests
	*/
	public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException
	{
		try
		{
			MultipartRequest mrequest = new MultipartRequest(request, uploadPath, L10M);
			String s = mrequest.getParameter(OPERATION);
			int iOp = Integer.parseInt(s);
			
			switch (iOp)
			{
				case CHECK_FILE:
					checkFileStatus(mrequest, response);
					break;
					
				case DEPLOY_FILE:
					deployFile(mrequest, response);
					break;
			}
		}
		catch (Exception e)
		{
			String msg = e.toString();
			l.error("Exception in Deploy.doPost(): " + msg);
			e.printStackTrace();
		}
	}
	
	private void checkFileStatus(MultipartRequest mrequest, HttpServletResponse response) throws IOException, ServletException
	{
		// the caller is sending over a filename (in relative path), return the last modified timestamp
		String pathName = mrequest.getParameter(TARGETPATH);
		if (pathName == null) pathName = sourcePath;
		pathName += mrequest.getParameter(FILENAME);
		
		//System.out.println("** pathName="+pathName);		
		File fObj = new File(pathName);
		String lastModified = "0";			// default to copy
		if (fObj.exists())
		{
			lastModified = String.valueOf(fObj.lastModified());
		}
		//System.out.println("** time="+lastModified);

		OutputStream os = response.getOutputStream();
		byte [] bArr = lastModified.getBytes();
		os.write(bArr, 0, bArr.length);
		os.flush();
		os.close();
	}
	
	private void deployFile(MultipartRequest mrequest, HttpServletResponse response) throws IOException, ServletException
	{
		String statusMsg = "";
		String pathName = "";
		
		try
		{
			File fileObj = mrequest.getFile(TRANSFER);			// get the object, the upload is done when client post
			
			pathName = mrequest.getParameter(TARGETPATH);
			if (pathName == null) {
				pathName = sourcePath;
			}
			pathName += mrequest.getParameter(FILENAME);
			long timestamp = Long.parseLong(mrequest.getParameter(TIMESTAMP));
			File newFile = new File(pathName);
			if (newFile.exists()) {
				newFile.delete();						// remove the old version of the file first
			}
			fileObj.renameTo(newFile);
			fileObj.setLastModified(timestamp);			// use client side timestamp
			statusMsg = "Deploy " + pathName;
		}
		catch (Exception e)
		{
			e.printStackTrace();
			statusMsg = "Failed to deploy " + pathName;
		}
		l.info(statusMsg);

		// report status
		OutputStream os = response.getOutputStream();
		os.write(statusMsg.getBytes(), 0, statusMsg.length());
		os.flush();
		os.close();
	}
}
