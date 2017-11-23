//
//	Copyright (c) 2002 EGI Technologies Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
// $Header$
//
//	File:	$RCSfile$
//	Author:	Eddie Lo
//	Date:	$Date$
//
//	Modification:
//
//		@AGQ062806	Removed attachment object from db if external file does not exists
//					Other users may have manually deleted this file.
//		@AGQ080306	Added tag in pst.properties to determine if unfound files from the 
//					network needs to be removed from the database
//		@AGQ080706	Changed all backslashes to forward slashes for internet addresses
//					This fixes the problem where firefox cannot display pictures for archived blogs
//		@ECC012909	Support Google Docs.
//
/////////////////////////////////////////////////////////////////////
/**
* show TIF file to the web
* @author johnnyl
* @version $Revision$
*/

import java.io.IOException;
import java.io.OutputStream;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import oct.codegen.attachment;
import oct.codegen.attachmentManager;
import oct.codegen.history;
import oct.codegen.userManager;
import oct.omm.client.OmsOrganization;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstGuest;
import oct.pst.PstUserAbstractObject;
import oct.util.file.FileTransfer;
import oct.util.file.exception.FileTransferException;

import org.apache.log4j.Logger;

import util.PrmLog;
import util.StringUtil;
import util.Util;
import util.Util2;

public class ShowFile extends HttpServlet
{ 
   /**
	 * 
	 */
	private static final long serialVersionUID = 7299935614943192906L;
	static Logger l = PrmLog.getLog();
	static String host = Util.getPropKey("pst", "PRM_HOST");

	public void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException
	{
		getFile(request, response);
	}

	/**
	 * Handle POST requests
	 */
	public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException
	{
		getFile(request, response);
	}

	public void getFile(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException
	{
		String attIdS = request.getParameter("attId");
		
		// HKU redirect to collabris.cn
/*		if (host.contains("183.238.5.149/PRM")) {
			String url = request.getRequestURL().toString();
			url = url.replace("183.238.5.149/PRM", "collabris.cn") + "?attId=" + attIdS;
			System.out.println("ShowFile redirect to: " + url);
			response.sendRedirect(url);
		}
*/		
		try
		{
			boolean isGoogle = false;
			attachmentManager attachmentMgr = attachmentManager.getInstance();
			PstUserAbstractObject pstuser = null;
			PstAbstractObject attObj = null;
			int attId = -1;
			String filePath = request.getParameter("filePath");
			HttpSession s = request.getSession(false);

			// ECC: temporary workaround for webservice that we couldn't get the HttpSession
			String uname = request.getParameter("username");

			if (!StringUtil.isNullOrEmptyString(uname)) {
				// caller might pass to me username and password for authentication
				String passwd = request.getParameter("password");
				PstUserAbstractObject tempUser = PstGuest.getInstance();
				try {pstuser = userManager.getInstance().login(tempUser, uname, passwd);}
				catch (PmpException e) {pstuser = null;}
			}
			else if (s != null)
				pstuser = (PstUserAbstractObject)s.getAttribute("pstuser");

			if (pstuser == null)
			{
				// the session might be timed out
				if (attIdS != null && attIdS.length() > 0)
					response.sendRedirect(host + "/out.jsp?go=/servlet/ShowFile?attId="+attIdS+"&e=time out");
				else 
					response.sendRedirect(host + "/out.jsp?go=/servlet/ShowFile?filePath="+filePath+"&e=time out");
				return;
			}			

			// remove all filePath with attachment text 
			if (filePath != null) {
				// if filePath is given, it cannot be an absolutePath
				if (filePath.length() > 0) {
					char c = filePath.charAt(0);
					if (c != '/' && c != '\\'
							&& (filePath.length()>1 && filePath.charAt(1)!=':') )
						filePath = "/" + filePath;
				}
				int pos = filePath.indexOf("Attachment-");
				if (pos >= 0) {
					filePath = filePath.replaceAll("Attachment-", "");
				}
			}
			// convert attId to location
			else if (attIdS != null) {
				try {
					attId = Integer.parseInt(attIdS);
					attObj = attachmentMgr.get(pstuser, attId);
					filePath = (String)attObj.getAttribute("Location")[0];
					isGoogle = ((attachment)attObj).isGoogle();

					// @ECC011707 Check authorized access
					String deptName = (String)attObj.getAttribute("DepartmentName")[0];	// attachment's depts
					String myDept = null;
					if (pstuser != null && !(pstuser instanceof PstGuest) )
						myDept = (String)pstuser.getAttribute("DepartmentName")[0];	// user's auth depts
					else if (deptName != null)
					{
						// I am a guest and there is a dept auth control on the file
						deptName = deptName.replaceAll("@", "; ");
						l.info("!!! Unauthorized access to document (Guest -> [" + attIdS +  "] "+ deptName + " file: " + filePath + ")");
						response.sendRedirect(host + "/out.jsp?e=Guest is not authorized to access this " + deptName + " document.  Please login in order to access the protected document.");
						return;
					}
					if (deptName!=null)
					{
						if (!Util2.isAuthAttachmt(myDept, deptName))	//(myDept==null || (myDept.indexOf(deptName)<0 && deptName.indexOf(myDept)<0) )
						{
							// unauthorized access based on DepartmentName match
							deptName = deptName.replaceAll("@", "; ");
							l.info("!!! Unauthorized access to document (" + pstuser.getObjectName() + " -> [" + attIdS +  "] "+ deptName + " file: " + filePath + ")");
							response.sendRedirect(host + "/out.jsp?e=You are not authorized to access this " + deptName + " document.  Your attempt to access is being logged.");
							return;
						}
					}
				} catch (NumberFormatException e) {
					l.error(e);
				}
			}



			String memid = request.getParameter("memid");
			String attname = request.getParameter("attname");
			String arcvFile = request.getParameter("archiveFile");

			FileTransfer f = new FileTransfer(pstuser.getSession(), null);
			byte[] b = null;

			if (arcvFile != null)
			{
				// viewing blog archive
				String anchor = null;
				int idx;
				if ((idx = arcvFile.indexOf("#")) != -1)
				{
					anchor = arcvFile.substring(idx);
					arcvFile = arcvFile.substring(0, idx);
				}
				String htmlFileName = f.placeArcvFileOnServer(arcvFile);
				if (anchor != null) htmlFileName += anchor;
				// @AGQ080706
				htmlFileName = htmlFileName.replaceAll("\\\\", "/");
				response.sendRedirect(htmlFileName);
			}
			else if (filePath != null)
			{
				// calling ShowFile to view attachments
				try {
					// Update Frequency; we have the attachment object id
					if (attId >= 0)
						attObj = attachmentMgr.updateFrequency(pstuser, attId);
					// use location to find object id
					else
						attObj = attachmentMgr.updateFrequency(pstuser, filePath);
					attIdS = attObj.getObjectName();

					String projIdS = (String)attObj.getAttribute("ProjectID")[0];

					String fullname = null;
					if (!isGoogle)
					{
						String type = (attObj!=null)?(String)attObj.getAttribute("Type")[0]:null;
						if (type!=null && type.equals(attachment.TYPE_FOLDER))
						{
							// viewing share folder
							String loc = host + "/ep/rdata.jsp?attId=" + attId;
							showFileRedirect(pstuser, response, loc, projIdS, attIdS);
							return;
						}
						fullname = f.placeFileOnServer(filePath);
						fullname = fullname.replaceAll("\\\\", "/");
					}
					else {
						fullname = (String)attObj.getAttribute("Location")[0];
					}

					showFileRedirect(pstuser, response, fullname, projIdS, attIdS);

				} catch (FileTransferException e) {
					l.error("Got FileTransferException in ShowFile.getFile()");
					e.printStackTrace();
					String removeAttObjS = Util.getPropKey("pst", "REMOVE_ATT_OBJ");
					boolean bRemoveAttObj = (removeAttObjS!=null && removeAttObjS.equalsIgnoreCase("true"));

					if (attId >= 0) {
						PstAbstractObject obj = attachmentMgr.get(pstuser, attId);
						String location = (String)obj.getAttribute("Location")[0];
						if (Util.isAbsolutePath(location)) {
							// this should not happen for non-network files
							//throw new FileTransferException();
							if (bRemoveAttObj) {
								attachmentMgr.delete(obj);
								l.info("ShowFile.getFile() [1] cleanup attachment object [" + attId + "]");
							}
						}
						l.error("Attachment ID1: " + attId + "\nAttachment File: " + location + " not found");
						response.sendRedirect("../out.jsp?e=File cannot be found in the repository");
					}
					else {
						if (!Util.isAbsolutePath(filePath)) {
							// this should not happen for non-network files
							throw new FileTransferException();
						}
						filePath = filePath.replaceAll("\\'", "\\\\'");
						int[] ids = attachmentMgr.findId(pstuser, "Location='"+filePath+"'");
						PstAbstractObject[] objArr = attachmentMgr.get(pstuser, ids);
						if (objArr.length > 0) {
							if (bRemoveAttObj) {
								attachmentMgr.delete(objArr[0]);
								l.info("ShowFile.getFile() [2] cleanup attachment object [" + ids + "]");
							}
							l.error("Attachment ID2: " + objArr[0].getObjectId() + "\nAttachment File: " + filePath + " not found");
							response.sendRedirect("../out.jsp?e=File cannot be found in the repository");
						}
					}
				}
			}
			else if (memid.equals("-1")) // External member
			{
				String memname = request.getParameter("memname");
				String orgname = request.getParameter("orgname");

				b = f.retrieveFileFromObject(memname, new OmsOrganization(pstuser.getSession(), orgname), attname);
				response.setContentType("image");
				OutputStream os = response.getOutputStream();
				os.write(b);
				os.flush();
			}
			else   // Internal member
			{				
				//b = f.retrieveFileFromObject(Integer.parseInt(memid) , attname);
				String fullname = f.placeFileOnServer(Integer.parseInt(memid) , attname);
				response.sendRedirect(fullname);	// don't know how to do history for this one
			}

			return;

		}
		catch (Exception e)
		{
			e.printStackTrace();
			String msg = e.toString();
			System.out.println("Exeception catch: " + msg);
			if (msg.indexOf("PmpObjectNotFoundException") != -1)
			{
				response.sendRedirect("../out.jsp?e=The file you requested cannot be found in the repository.  It might have been deleted by the owner.");
			}
		}
	}

   /**
    * redirect client to the file
    * @param response
    * @param loc
    * @throws IOException
    */
	public static void showFileRedirect(PstUserAbstractObject u, HttpServletResponse response, String loc,
			String projIdS, String attIdS)
		throws IOException
	{
		// record history and send event
	   	// TOWNID, USERID, PROJECTID, TASKID, MEETINGID, BUGID, ATTID
		history.addRecord(u, "HIST.7103",
				null, null,
				projIdS, null, null, null,
				attIdS);
		
        byte[] utfBytes = loc.getBytes("UTF-8");
        String result = new String(utfBytes, "ISO-8859-1");
		response.sendRedirect(result);
	}
}





/**
* $Log$
* Revision 1.16  2007/07/04 00:15:06  edwardc
* Better exception message when file is deleted.
*
* Revision 1.15  2007/06/19 22:34:26  edwardc
* Bug fix for accessing files that had been removed from the repository.
*
* Revision 1.14  2007/06/08 19:30:26  edwardc
* Guest unauthorized access to files will show a correct error message.
*
* Revision 1.13  2007/06/04 22:09:29  edwardc
* Support more flexible multiple department names in authorization of attachment accesses.
*
* Revision 1.12  2007/01/17 22:56:15  edwardc
* @ECC011707 Support project, task and attachment to have DepartmentName.  Access authority to attachments will be checked by matching user DepartmentName and attachment DepartmentName.
*
* Revision 1.11  2006/11/03 18:40:49  edwardc
* Remove unnecessary case to handle HTTP direct link for Spansion.
*
* Revision 1.9  2006/08/07 19:21:38  allenq
* Fixed bug for firefox where archive blogs does not display pictures
*
* Revision 1.8  2006/08/03 18:11:54  allenq
* Support debug mode to prevent removing ext files when not found
*
* Revision 1.7  2006/07/06 18:24:39  allenq
* Fixed bug where external file breaks download blog file
*
* Revision 1.6  2006/06/30 20:14:43  allenq
* Thread, handled more exceptions, fixed reload searcher
*
* Revision 1.5  2006/06/29 18:47:05  allenq
* Codes to distinguish between ext and int files, standalone tool, fixed deleted attachments
*
* Revision 1.4  2006/06/17 01:15:54  allenq
* Implementation of IndexBuilder and QueryManagement 1st phase
*
* Revision 1.3  2006/01/04 23:03:11  edwardc
* Check-in Archiving feature.
*
* Revision 1.2  2005/11/07 07:03:36  edwardc
* Synchronize prayer (laptop) to merciful CVS
*
* Revision 1.1  2003/06/16 19:03:02  eddiel
* initial release
*
* Revision 1.2  2003/02/25 04:03:58  eddiel
* Support orgname for external org showfile
*
* Revision 1.1.1.1  2003/01/14 01:08:54  johnnyl
* no message
*
* Revision 1.1.1.1  2003/01/13 21:32:56  johnnyl
* no message
*
* Revision 1.1  2002/08/28 19:15:25  eddiel
* fix bug 58110 for upload files
*
*
*
*/

