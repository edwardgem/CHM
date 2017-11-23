/**
 *  Copyright (c) 2010, EGI Technologies, Inc.  All rights reserved.
 *	File:		RemoteSync.java
 *	Author:		edwardc
 *	Date:		Mar 26, 2010
 *	Description:
 *
 */

package oct.util.file;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Date;

/**
 * @author edwardc
 *
 */
public class RemoteSync {

	static final long SleepTime		= 60000;		// 1 min.
	static private String _installPath		= null;


   /**
    * Single static instance of the service class
    */
	private static RemoteSync
		serviceInstance = new RemoteSync();

   /**
    * Static method called by prunsrv to start/stop
    * the service.  Pass the argument "start"
    * to start the service, and pass "stop" to
    * stop the service.
 * @throws IOException 
    */
	public static void windowsService(String args[])
		throws IOException
	{
		String cmd = "start";
		if(args.length > 0) {
			cmd = args[0];
		}

		if("start".equals(cmd)) {
			// get install path to locate cr.properties
			if (args.length > 1) {
				_installPath = args[1];
			}

			serviceInstance.start();
		}
		else {
			serviceInstance.stop();
		}
	}

   /**
    * Flag to know if this service
    * instance has been stopped.
    */
	private boolean stopped = false;


   /**
    * Start this service instance
    */
	public void start()
		throws IOException
	{

		stopped = false;

		System.out.println("RemoteSync Service Started "
                         + new Date());

        // set the cr.properties file location
        System.out.println("Install Path = " + _installPath);
        /*String propFilePath = _installPath + "/bin/cr.properties";
        File f = new File(propFilePath);
        if (f.exists()) {
        	PrmClientConstant.setPropFile(propFilePath);
		}
		*/
        
        PrmClient.init();

		String [] uploadFolderArr;
		String [] fileArr;

		while(!stopped) {
			System.out.println("RemoteSync Service Executing "
							 + new Date());
			synchronized(this) {
				try {
					// get the upload folders/files
					// ECC: I think this needs to be changed because now I support
					// specifying uploading files
					
					String uploadOption = PrmClientConstant.getXMLValue(
							PrmClientConstant.getPropFile(), PrmClientConstant.UPLOAD_OPT_LABEL);
					
					if (PrmClientConstant.UP_OPT_BACKUP.equalsIgnoreCase(uploadOption)) {
						String uploadTag = PrmClientConstant.getXMLValue(
								PrmClientConstant.getPropFile(), "UPLOAD");
						//System.out.println("upload: " + uploadTag);
						
						uploadFolderArr = uploadTag.split(PrmClientConstant.TERMINATOR1);
	
						// upload the files
						ArrayList<String> fileList = new ArrayList<String>();
	
						for (int i=0; i<uploadFolderArr.length; i++) {							
							// must call backupArea for each folder specified before uploading
							PrmClientUpload.backupArea(uploadFolderArr[i]);

							fileArr = PrmClientUpload.getFilesInFolder(uploadFolderArr[i]);
							for (String fname: fileArr) {
								fileList.add(fname);
							}
						}
	
						// sync to server on the targeted destiny
						// (project/task or backup folders)
						int ct = 0;
						int totalSegment;
						for (String fname: fileList) {
							// call prepareUploadFile() followed by uploadSegment()
							if ((totalSegment = PrmClientUpload.prepareUploadFile(fname)) > 0) {
								System.out.println("uploading " + fname);
								for (int i=0; i<totalSegment; i++) {
									PrmClientUpload.uploadSegment(fname, i, totalSegment);
								}
								ct++;
							}
						}
						//System.out.println("uploaded " + ct + " files.");
					}
					else {
						System.out.println("!! No remote sync for upload option ["
								+ uploadOption + "]");
					}

					sleep(SleepTime);  // wait 1 minute
				}
				catch(Exception e) {
					e.printStackTrace();
					sleep(SleepTime);
				}
		 	}
		}

		System.out.println("RemoteSync Service Finished "
						  + new java.util.Date());
	}

	private void sleep(long t)
	{
		try {this.wait(t);}
		catch (InterruptedException e) {}
	}

   /**
    * Stop this service instance
    */
	public void stop()
	{
		stopped = true;
		synchronized(this) {
			this.notify();
		}
	}
}
