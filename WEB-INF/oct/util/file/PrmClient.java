/**
 **********************************************************
 *
 *	File:		PrmClient.java
 *	Author:		ECC
 *	Date:		Nov 28, 2009
 *	Description:
 *				Description of the file.
 *
 *	Modification:
 * 
 **********************************************************
 */
package oct.util.file;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.PrintStream;
import java.io.PrintWriter;
import java.net.InetAddress;
import java.util.ArrayList;
import java.util.Date;

import javax.swing.JLabel;

/**
 * @author edwardc
 *
 */
public abstract class PrmClient {
	
	public static boolean isLogin = false;
	
	private static JLabel windowStatusBar = null;
	private static PrintStream ostream;
	private static boolean bNeedRecalSpace	= false;		// need to trigger server to recalculate space used
	private static String paths = PrmClientConstant.getXMLValue(PrmClientConstant.SPEC_PATH, "UPLOAD");
	private static String host = PrmClientConstant.getXMLValue(PrmClientConstant.SPEC_PATH, "PRM_HOST");
	private static String hostname = null;
	private static String username = null;

	
	// init() is just to login to make sure authorization is OK and to get the specified upload folders
	/**
	 * Connect to server and initialize for upload and download.
	 * @return true if succeed, otherwise false.
	 * @throws IOException
	 */
	public static boolean init() throws IOException {return init(null);}
	
	/**
	 * All users of PrmClient upload or download must call this to begin.
	 * Connect to server and initialize for upload and download.
	 * @param callerStatusBar JLabel object to post status messages.
	 * @return true if succeed, otherwise false.
	 * @throws IOException
	 */
	public static boolean init(JLabel callerStatusBar)
		throws IOException
	{
		// get the properties
		if (callerStatusBar != null)
			windowStatusBar = callerStatusBar;
		
		File tFile = new File("cr_upload.log");
		ostream = new PrintStream(new FileOutputStream(tFile));
		out(PrmClientConstant.VERSION);
		out(new Date().toString());
		
		bNeedRecalSpace = false;
		hostname = InetAddress.getLocalHost().getHostName();
		
		// check login authority
		isLogin = false;
		ClientHttpRequest clientReq = new ClientHttpRequest(host + "/servlet/UploadFile");
		username = PrmClientConstant.getXMLValue(PrmClientConstant.SPEC_PATH, "USER");
		clientReq.setParameter("USER", username);
		clientReq.setParameter("PASSWORD", PrmClientConstant.getXMLValue(PrmClientConstant.SPEC_PATH, "PASSWORD"));
		clientReq.post();	// login: will throw exception if failed

		isLogin = true;
		return isLogin;
	}
	
	/**
	 * Close the connection to server.
	 */
	public static void logout()
	{
		isLogin = false;
		bNeedRecalSpace = false;
		windowStatusBar = null;
		username = null;
	}
	
	/**
	 * Retrieve the authorized project list of the login user
	 * @return ArrayList of projId::projName pairs in string
	 * @throws IOException
	 */ 
	@SuppressWarnings("unchecked")
	public static ArrayList <String> getProjectList()
		throws IOException
	{
		if (!isLogin)
			return null;
		
		ClientHttpRequest clientReq = new ClientHttpRequest(host + "/servlet/UploadFile");
		clientReq.setParameter("uname", username);
		clientReq.setParameter(PrmClientConstant.GET_PROJLIST_LABEL, "true");
		
		InputStream in = clientReq.post();
		BufferedReader din = new BufferedReader(new InputStreamReader(in));
		
		// process result projID::projName:@: ...		
		String line;	
		StringBuffer sBuf = new StringBuffer(4096);
		ArrayList <String> resList = new ArrayList();
		String [] sa1;
		if ((line = din.readLine()) != null)
		{
			// the line contains a number of projID::projName pairs
			if (sBuf.length() > 0) sBuf.append("\n");		// add a new line
			if (line.startsWith(PrmClientConstant.ERROR))
			{
				out(line);		// just dump the error to log file
				return resList;	// empty list
			}
			sa1 = line.split(PrmClientConstant.TERMINATOR2);	// :@:
			String projPair;
			for (int i=0; i<sa1.length; i++)
			{
				projPair = sa1[i];
				resList.add(projPair);
			}
		}		
		
		return resList;
	}

	/**
	 * Return a list of task name of the specified project.
	 * @param projIdS the ID of the project to retrieve the task names
	 * @return ArrayList of taskId::taskName pairs in string
	 * @throws IOException
	 */
	@SuppressWarnings("unchecked")
	public static ArrayList <String> getTaskList(String projIdS)
		throws IOException
	{
		if (!isLogin)
			return null;
		
		ClientHttpRequest clientReq = new ClientHttpRequest(host + "/servlet/UploadFile");
		clientReq.setParameter("uname", username);
		clientReq.setParameter(PrmClientConstant.GET_TASKLIST_LABEL, "true");
		clientReq.setParameter("projId", projIdS);
		
		InputStream in = clientReq.post();
		BufferedReader din = new BufferedReader(new InputStreamReader(in));
		
		// process result taskID::taskName:@: ...		
		String line;	
		StringBuffer sBuf = new StringBuffer(4096);
		ArrayList <String> resList = new ArrayList();
		String [] sa1;
		if ((line = din.readLine()) != null)
		{
			// the line contains a number of projID::projName pairs
			if (sBuf.length() > 0) sBuf.append("\n");		// add a new line
			if (line.startsWith(PrmClientConstant.ERROR))
			{
				out(line);		// just dump the error to log file
				return resList;	// empty list
			}
			sa1 = line.split(PrmClientConstant.TERMINATOR2);	// :@:
			String taskPair;
			for (int i=0; i<sa1.length; i++)
			{
				taskPair = sa1[i];
				resList.add(taskPair);
			}
		}		
		
		return resList;
	}

	protected static boolean getNeedRecalSpace() {return bNeedRecalSpace;}
	protected static void setNeedRecalSpace(boolean b) {bNeedRecalSpace = b;}
	
	protected static String getHost() {return host;}
	protected static void setHost(String s) {host = s;}
	
	protected static String getHostname() {return hostname;}
	protected static void setHostname(String s) {hostname = s;}
	
	protected static String getPaths() {return paths;}
	protected static void setPaths(String s) {paths = s;}
	
	protected static JLabel getWindowStatusBar() {return windowStatusBar;}
	
	public static void out(String msg)
	{
		//System.out.println(msg);
		if (ostream == null)
			System.out.println(msg);
		else
			ostream.println(msg);
	}
	
	protected static PrintWriter getAppendPrintWriter()
	{
		FileWriter fw;
		try {fw = new FileWriter("cr_upload.log", true);}	// append
		catch (IOException e) {return null;}		
		PrintWriter os = new PrintWriter(fw);
		return os;
	}
	
	protected static boolean isEmptyString(String str)
	{
		if (str==null || str.trim().length()<=0)
			return true;
		else
			return false;
	}

    public static void sortVersionFiles(File [] fList)
    {
    	if (fList == null) return;
		File o1, o2;
		boolean swap;
		do
		{
			swap = false;
			for (int i=0; i<fList.length-1; i++)
			{
				o1 = fList[i];
				if (o1.isDirectory()) continue;
				
				o2 = fList[i+1];
				if (getVersionNumber(o1) > getVersionNumber(o2))
				{
					swap = true;
				}
				if (swap)
				{
					fList[i]   = o2;
					fList[i+1] = o1;
				}
			}
		} while (swap);
    }
    
    private static int getVersionNumber(File fObj)
    {
    	int res = 99999;
    	if (fObj == null) return res;
    	String fname = fObj.getName();
    	int idx1, idx2;
    	
    	if ((idx1 = fname.lastIndexOf('_')) == -1)
    		return res;
    	if ((idx2 = fname.lastIndexOf('.')) == -1)
    		idx2 = fname.length();				// no file extension
    	
    	String numS = fname.substring(idx1+1, idx2);
    	try {res = Integer.parseInt(numS);}
    	catch (Exception e) {}
    	
    	return res;
    }

}
