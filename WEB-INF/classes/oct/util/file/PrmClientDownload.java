//
///////////////////////////////////////////////////////////////////////////////////////////
//
//	File:		PrmClientDownload.java
//	Author:		ECC
//	Date:		08/18/2008
//	Description:
//				To enable download of shared files from the server to client machine.
//				It first calls the server to get a number of files the user has on
//				the share file list.  Allowing the user to choose from there and then
//				download those selected files.
//
//				Since I don't have the user interface now, I will simply do both in one
//				call and don't allow user to choose.  Just download all shared files.
//
//	Modification:
//				@ECC113009	Introduce new calling convention in order to support a better
//				progress bar.  First call prepareUploadFile() then call uploadSegment().
//
///////////////////////////////////////////////////////////////////////////////////////////
//

package oct.util.file;

import java.io.BufferedInputStream;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.PrintWriter;


public class PrmClientDownload extends PrmClient
{

	private static String saveDir = null;

	public static String listFiles() throws IOException {return listFiles(null);}
	public static String listFiles(String attIdS)
		throws IOException
	{
		if (!isLogin)
			throw new IOException("User is not connected.  Please login.");
		PrintWriter os = getAppendPrintWriter();
		if (os == null)
			throw new IOException("Fail to get log file output stream.");

		// get the properties
		// if attIdS is not null, it is the folder attId, return the list the files in that folder.
		out(">>> Calling PrmClientDownload.listFiles()");
		out(PrmClientConstant.getXMLValue(PrmClientConstant.SPEC_PATH, "location"));	// ECC debug
		
		String userName = PrmClientConstant.getXMLValue(PrmClientConstant.SPEC_PATH, "USER");
		saveDir = PrmClientConstant.getXMLValue(PrmClientConstant.SPEC_PATH, "DOWNLOAD_PATH");

		// for each of the directory paths in the dirpath.txt file, use HTTP to upload

		// get the list of Shared Files from server
		ClientHttpRequest clientReq = new ClientHttpRequest(getHost() + "/servlet/DownloadFile");
		clientReq.setParameter(PrmClientConstant.OP_LABEL, PrmClientConstant.OP_GET_SHARE);	// get the list of shared files
		clientReq.setParameter(PrmClientConstant.USER_LABEL, userName);
		
		if (attIdS != null)
			clientReq.setParameter(PrmClientConstant.ATTID, attIdS);		// retrieving file list in a folder
		
		InputStream in = clientReq.post();
		BufferedReader din = new BufferedReader(new InputStreamReader(in));
		
		StringBuffer sBuf = new StringBuffer(4096);
		
		String line;
		while ((line = din.readLine()) != null)
		{
			// download files one at a time
			out("--" + line);
			if (sBuf.length() > 0) sBuf.append("\n");		// add a new line
			sBuf.append(line);
		}
		
		os.flush();
		os.close();

		return sBuf.toString();
	}	// END listFiles()
			

	public static String download(String line)
	{
		if (saveDir == null) return null;
		PrintWriter os = getAppendPrintWriter();
		if (os == null)
			return null;
		
		InputStream in = null;
		FileOutputStream fos = null;
		try
		{
			byte [] contentBuf = new byte[8192];
			int count, len;
			BufferedInputStream fis;
			File newFile;
	
			String [] sa = line.split(PrmClientConstant.TERMINATOR1);
			os.print("Downloading " + line);
			ClientHttpRequest clientReq = new ClientHttpRequest(getHost() + "/servlet/DownloadFile");
			clientReq.setParameter(PrmClientConstant.OP_LABEL, PrmClientConstant.OP_DOWNLOAD);
			clientReq.setParameter(PrmClientConstant.FILEID_LABEL, sa[1]);
			in = clientReq.post();
			fis = new BufferedInputStream(in);
	
			len = 0;
			newFile = new File(saveDir + "/" + sa[0]);
			newFile.createNewFile();
			fos = new FileOutputStream(newFile);
			while((count = fis.read(contentBuf)) != -1)
			{
				fos.write(contentBuf, 0, count);
				fos.flush();
				len += count;
			}
			os.println(" ... done");
			return "Complete";
		}
		catch (Exception e)
		{
			os.println(" ... failed");
			os.println(e.toString());
			e.printStackTrace();
			return "Fail";
		}
		finally
		{
			try
			{
				if (in != null)
					in.close();
				if (fos != null)
					fos.close();
				os.flush();
				os.close();
			}
			catch (IOException e) {}
		}
		//Thread.sleep(5000);
	}
	
	// ECC: new calling convention introduced 11/30/09

	/************************************************************************************
	 * Call to prepare for downloading a file.  It returns the number of segments that the
	 * actual download will take.
	 * Caller should follow this method by calling downloadSegment() in a loop to download
	 * all the segments of the file.
	 * 
	 * @param fInfo the encoded line containing the info of the file to be uploaded.
	 * fileName::fileID::owner::size
	 * @return the number of segments to be downloaded.
	 * @throws IOException 
	 */
	public static int prepareDownloadFile(String fInfo)
		throws IOException
	{
		if (saveDir == null) return 0;
		if (fInfo==null || fInfo.trim().length()<=0)
			return 0;
		PrintWriter os = getAppendPrintWriter();
		if (os == null)
			return 0;

		String [] sa = fInfo.split(PrmClientConstant.TERMINATOR1);
		String attidS = sa[1];
		int numOfSegment = 0;
		
		InputStream in = null;
		BufferedInputStream fis;

		os.print("Get segment no. for [" + attidS + "] " + sa[0] + " = ");
		ClientHttpRequest clientReq = new ClientHttpRequest(getHost() + "/servlet/DownloadFile");
		clientReq.setParameter(PrmClientConstant.OP_LABEL, PrmClientConstant.OP_GET_SEGMENT);
		clientReq.setParameter(PrmClientConstant.ATTID, attidS);
		in = clientReq.post();
		fis = new BufferedInputStream(in);
		
		byte [] contentBuf = new byte[1024];
		if(fis.read(contentBuf) != -1)
		{
			String res = new String(contentBuf).trim();			
			try {numOfSegment = Integer.parseInt(res);}
			catch (Exception e) {numOfSegment = 0;}
			os.print(numOfSegment);
		}
		os.println(".");
		
		// clean up
		os.close();
		in.close();
		
		return numOfSegment;
	}
	
	/*******************************************************************************
	 * 
	 * Downloads the specified segment of the file.  The number of segments to be downloaded
	 * is determined by the download chunk size.  Caller of this method should first
	 * call prepareDownloadFile() to get the number of segments.
	 * 
	 * @param fInfo the encoded line containing the info of the file to be uploaded.
	 * fileName::fileID::owner::size
	 * @param segmentNo is the index of the file segment to be uploaded in this call.
	 * @return true if the download is successful, otherwise false.
	 * @throws IOException 
	 * @throws IOException
	 */
	public static boolean downloadSegment(String fInfo,  int segmentNo)
		throws IOException
	{
		if (saveDir == null) return false;
		// check for saveDir: must exist
		File dirObj = new File(saveDir);
		if (!dirObj.isDirectory() || !dirObj.exists())
		{
			throw new IOException("Save folder: " + saveDir + " does not exist.");
		}
		PrintWriter os = getAppendPrintWriter();
		if (os == null)
			return false;

		String [] sa = fInfo.split(PrmClientConstant.TERMINATOR1);
		String attidS = sa[1];
		
		InputStream in = null;
		FileOutputStream fos = null;
		BufferedInputStream fis;

		os.print("downloading [" + attidS + "] - (" + segmentNo + ") ... ");
		ClientHttpRequest clientReq = new ClientHttpRequest(getHost() + "/servlet/DownloadFile");
		clientReq.setParameter(PrmClientConstant.OP_LABEL, PrmClientConstant.OP_DOWNLOAD_SEGMENT);
		clientReq.setParameter(PrmClientConstant.ATTID, attidS);
		clientReq.setParameter(PrmClientConstant.CHUNK_LABEL, String.valueOf(segmentNo));
		in = clientReq.post();
		fis = new BufferedInputStream(in);
		
		int count, len=0;
		byte [] contentBuf = new byte[PrmClientConstant.DOWNLOAD_CHUNK_SIZE];
		
		File newFile = new File(saveDir + "/" + sa[0]);	// write directly to SAVE location
		newFile.createNewFile();
		fos = new FileOutputStream(newFile);
		while ((count = fis.read(contentBuf)) != -1)
		{
			fos.write(contentBuf, 0, count);
			fos.flush();
			len += count;
		}
		os.println("done.");
		
		// clean up
		os.close();
		in.close();
		if (fos != null) fos.close();
		return true;
	}
}
