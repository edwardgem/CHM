import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;

import oct.util.file.ClientHttpRequest;
import util.Util;
import util.Util3;


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
* deploy source files from client to server.  Client side.
*/

public class DeployClient implements DeployBase
{

	private static String host = Util.getPropKey("pst", "DEPLOY_HOST");
	private static String sourcePath = Util3.copyPathExceptLastPart(Util.getPropKey("pst", "SHOW_FILE_PATH"));
	private static String targetPath;
	private static boolean bNoJava = false;
	private static boolean bForce;

	/**
	 * @param args
	 * @throws IOException 
	 */
	public static void main(String[] args) throws IOException
	{
		String fName = sourcePath;
		targetPath = null;
		bForce = false;
		
		if (args.length <= 0)
		{
			// deploy the whole workspace with default host
			// java DeployClient
		}
		else
		{
			// go through the args to extract the options
			// java DeployClient -nojava -h host source_files
			int ct = args.length;
			for (int i=0; i<ct; i++) {
				String s = args[i].toLowerCase();
				if (s.equals("-nojava")) {
					bNoJava = true;
					System.out.println("-- ignore Java");
				}
				else if (s.equals("-f")) {
					bForce = true;
					System.out.println("-- force deploy");
				}
				else if (s.startsWith("-srcpath")) {
					// -srcpathc:/Tomcat/webapps/NotificationManager
					sourcePath = fName = args[i].substring("-srcpath".length()).trim();
				}
				else if (s.startsWith("-trgpath")) {
					// -trgpathd:/Tomcat/webapps/NotificationManager
					targetPath = args[i].substring("-trgpath".length()).trim();
				}
				else if (s.startsWith("-h")) {
					if (s.equals("-h") && ct>(i+1)) {
						// the next argument is the hostname
						host = args[i+1];
						i++;				// skip the next argument which is the hostname
					}
					else {
						// there is no space after "-h"
						host = args[i].substring(2);	// skip "-h"
					}
				}
				else if (i == (ct-1)) {
					// the last arg and is not an option, then it must be source_files
					fName = args[i];
				}
			}
		}
		System.out.println("Deploying to " + host + " ...");

		// if calling this with filename, then simply deploy a file
		// if calling this with directory name, then attempt deploying the whole directory
		File fObj;
		fObj = new File(fName);
		checkAndCopy(fObj);				// recursive deploy file/directory
	}
	
	private static void checkAndCopy(File fObj)
	{
		String fName = fObj.getName();
		if (IGNORE_DIR.contains(";" + fName + ";"))	// use ";" as a prefix and suffix for name token
			return;
		if (bNoJava && fName.endsWith(".java"))
			return;
		
		if (fObj.isDirectory())
		{
			System.out.println(">>> deploy directory: " + fName);
			File [] fList = fObj.listFiles();			// file lists in the folder
			for (File aFile : fList)
			{
				checkAndCopy(aFile);					// recursive to subdirectory
			}
		}
		else
		{
			// file: actually check-in
			try
			{
				if (needToDeployFile(fObj))
				{
					copyFile(fObj);
				}
			}
			catch (IOException e)
			{
				System.out.println("Got IOException when deploying " + fName);
			}
		}
	}
	
	/*
	 * needToDeployFile() takes a filename as an input parameter and compares the timestamp
	 * of that file to the one on server.  If the server copy is older than the client copy,
	 * it will return true (need to copy).  If the file doesn't exist on server, it return true
	 * also.
	 * @param fObj the File Object of the file without the path.
	 * @return true if the file on server is not found or is older than the client copy.
	 */
	private static boolean needToDeployFile(File fObj) throws IOException
	{
		if (bForce)
			return true;
		
		String fName = fObj.getName();
		if (!fObj.exists())
		{
			System.out.println("Error: file " + fName + " does not exist.");
			return false;
		}
		
		String pathName = Util3.getRelativePath(fObj, sourcePath);
		
		ClientHttpRequest clientReq = new ClientHttpRequest(host + "/servlet/Deploy");
		clientReq.setParameter(OPERATION, CHECK_FILE);
		clientReq.setParameter(FILENAME, pathName);
		if (targetPath != null)
			clientReq.setParameter(TARGETPATH, targetPath);
		
		clientReq.post();	// will throw exception if failed
		
		InputStream in = clientReq.post();
		BufferedReader din = new BufferedReader(new InputStreamReader(in));
		
		String line;
		long clientCopyTime = fObj.lastModified();
		long serverCopyTime;
		
		if ((line = din.readLine()) != null)
		{
			// read back the last modified time for comparison
			serverCopyTime = Long.valueOf(line);
			//System.out.println("client time: " + new Date(clientCopyTime));
			//System.out.println("server time: " + new Date(serverCopyTime));
			//System.out.println("** time = "+serverCopyTime);
			if (clientCopyTime > serverCopyTime)
			{
				return true;		// need to check-in
			}
			else
			{
				//System.out.println("- " + fObj.getName() + " is up-to-date");
			}
		}
		return false;
	}

	/*
	 * copyFile() takes a parameter, fObj, and transfer this file to the server for copy.
	 * copyFile() only takes a file, not a directory.
	 * @param fObj the file Object to be transfer to the server.
	 * @return void
	 */
	private static void copyFile(File fObj) throws IOException
	{	
		String pathName = Util3.getRelativePath(fObj, sourcePath);
		String timestamp = String.valueOf(fObj.lastModified());

		ClientHttpRequest clientReq = new ClientHttpRequest(host + "/servlet/Deploy");
		clientReq.setParameter(OPERATION, DEPLOY_FILE);
		clientReq.setParameter(FILENAME, pathName);
		clientReq.setParameter(TIMESTAMP, timestamp);
		clientReq.setParameter(TRANSFER, fObj);				// upload the file
		if (targetPath != null) {
			clientReq.setParameter(TARGETPATH, targetPath);
		}
		clientReq.post();	// will throw exception if failed
		
		InputStream in = clientReq.post();
		BufferedReader din = new BufferedReader(new InputStreamReader(in));
		
		String line;
		if ((line = din.readLine()) != null)
		{
			// read back the upload status and just print
			System.out.println(line);
		}
	}
}
