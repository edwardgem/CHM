<%
//
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_delfile.java
//	Author: ECC
//	Date:		06/05/2004
//	Description:	Delete project files and rdata (shared and remote upload) files.
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "oct.util.file.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.PepCommentVector" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>
<%@ page import = "com.oreilly.servlet.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />


<%
	// project, task, bug all share this file to delete attachments
	// called by task_update.jsp and mtg_update1.jsp (probably by mtg_update2.jsp also?)

	PstUserAbstractObject me = pstuser;
	if (me instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}

	String uploadPath = Util.getPropKey("pst", "FILE_UPLOAD_PATH");
	
	PstManager mgr = null;
	attachmentManager aMgr = attachmentManager.getInstance();
	bugManager bMgr = bugManager.getInstance();
	
	PstAbstractObject obj = null;
	PstAbstractObject aObj = null;
	int [] idArr = null;
	PstAbstractObject [] objArr = null;
	
	boolean isProject = false;
	boolean isRemoteUploadFile = false;
	
	String expr = null;
	String filePath = null;
	String attObjId = null;
	String fname = null;
	String projIdS = request.getParameter("projId");
	String pTaskId = request.getParameter("pTaskId");
	String idS = request.getParameter("bugId");			// support bug track
	String midS = request.getParameter("mid");			// support meeting
	String isRun = request.getParameter("run");			// support deleting file when mtg is live
	
	String hostname, area, uidS, subpath, idxS, dbAreaName;
	hostname = area = uidS = subpath = idxS = dbAreaName = null;
	
	if (midS != null)
	{
		// deleting meeting attachment
		idS = midS;
		mgr = meetingManager.getInstance();
	}
	else if (pTaskId != null)
	{
		// deleting task attachment
		idS = request.getParameter("taskId");
		mgr = taskManager.getInstance();
	}
	else if (idS != null)
	{
		// deleting bug attachment
		mgr = bugManager.getInstance();
	}
	else if (projIdS != null)
	{
		// deleting project attachment
		isProject = true;
		idS = projIdS;
		mgr = projectManager.getInstance();
	}
	else
	{
		// delete remote upload file
		isRemoteUploadFile = true;
		hostname = request.getParameter("host");		// for return to remote upload rdata.jsp
		area = request.getParameter("area");
		uidS = request.getParameter("uid");
		subpath = request.getParameter("subpath");
		idxS = request.getParameter("idx");
		dbAreaName = hostname + "$" + area;				// the first part of the Backup attr (peace$C:/Temp/Folder1)
		if (subpath==null || subpath.equals("null"))
			subpath = "";
	}

	if (mgr != null)
		obj = mgr.get(me, Integer.parseInt(idS));

	// Check to see if user provided an attachment Id
	boolean bAttachmtObjRemoved = false;				// if it is a folder, then there is no attmt obj
	boolean isDirectory = false;
	boolean isLink = false;
	boolean isGoogle = false;							// external server file: now only Google docs
	boolean bDelAuthorized = true;						// not authorized if I am only sharing the file
	attObjId = request.getParameter("attId");			// could be a list of attId's if calling by rdata.jsp
	
	// path1: delete by passing attId (can be more than one id separated by ; in case of rdata.jsp)
	if (attObjId != null && attObjId.length() > 0)
	{
		String [] sa = attObjId.split(";");
		for (int i=0; i<sa.length; i++)
		{
			attObjId = sa[i];
			int attId = Integer.parseInt(attObjId);
			aObj = aMgr.get(me, attId);
			if (pTaskId!=null || midS!=null)
			{
				// @ECC103008 check to see if this is just deleting a link
				if (Util2.foundAttribute(aObj, "Link", idS))
				{
					isLink = true;
					aObj.removeAttribute("Link", idS);
					aMgr.commit(aObj);
					System.out.println("remove link " + attId);
				}
			}
			if (!isLink)
			{
				fname = (String)aObj.getAttribute("Location")[0];
				if (fname.startsWith("http:"))
					isGoogle = true;
				else if (util.Util.isAbsolutePath(fname))
					filePath = fname;
				else
				{
					filePath = uploadPath;
					filePath += fname;
				}
		
				if (obj != null)		// if call from rdata.jsp, file would have no obj to associate with
				{
					obj.removeAttribute("AttachmentID", attObjId);
					aMgr.delete(aObj);
				}
				else
				{
					// for rdata.jsp, only allow owner to delete the file
					if (aObj.getAttribute("Owner")[0].equals(String.valueOf(me.getObjectId())))
						aMgr.delete(aObj);
					else
						bDelAuthorized = false;
				}
				bAttachmtObjRemoved = true;
				
				// delete file
				if (!isGoogle && bDelAuthorized)
				{
					File f = new File(filePath);
					f.delete();
				}
			}
		}	// END: for each attId
	}	// END if path 1
	
	// path 2: delete by passing filename (mtg_update2.jsp, bug_update.jsp, etc.)
	else
	{
		// User provides actual fileName
		// ECC: not preferred - task_update.jsp and mtg_update1.jsp use attId now
		fname = request.getParameter("fname");	// attributeName-filename.ext e.g. Attachment-abc.txt
		String [] fList;
		if (fname.indexOf("??") != -1)
		{
			fList = fname.split("\\?\\?");
		}
		else
		{
			fname = fname.replace("Attachment-", ""); // @AGQ062706 removed Attachment-
			fList = new String[1];
			fList[0] = fname;
		}
		
		// check for absolute path set a variable for findId and for delete file
		for (int i=0; i<fList.length; i++)
		{
			fname = fList[i];
			if (util.Util.isAbsolutePath(fname))
				filePath = fname;		
			else
			{
				fname = "/" + idS + "/" + fname;
				filePath = uploadPath + fname;
			}
	
			expr = "Location='"+fname+"'";
			idArr = aMgr.findId(me, expr);
	
			isLink = false;
			if (idArr != null && idArr.length > 0)
			{
				attObjId = String.valueOf(idArr[0]);	// only look at the first one because there should only one match
				if (attObjId != null)
				{
					aObj = (attachment)aMgr.get(me, attObjId);
					if (pTaskId!=null || midS!=null)
					{
						// @ECC103008 check to see if this is just deleting a link
						if (Util2.foundAttribute(aObj, "Link", idS))
						{
							isLink = true;
							aObj.removeAttribute("Link", idS);
							aMgr.commit(aObj);
							System.out.println("remove link " + attObjId);
						}
					}
					if (!isLink)
					{
						aMgr.delete(aObj);
						bAttachmtObjRemoved = true;
		
						// cleanup the attribute if necessary
						if (obj != null)
							obj.removeAttribute("AttachmentID", attObjId);
					}
				}
				else
					System.out.println("Cannot find attachment id: " + attObjId);
			}
			else 
				System.out.println("Cannot find attachment filename: " + fname + ", might just be a directory.");

			// delete file
			if (!isLink)
			{
				File f = new File(filePath);
				isDirectory = f.isDirectory();
				f.delete();
				System.out.println("Deleted physical file/dir: " + filePath);
			}

		}	// END for file list
	}
	
	// @ECC091108 recalculate project space
	if (!isGoogle)
	{
		if (bAttachmtObjRemoved && bDelAuthorized)
		{
			if (projIdS != null)
			{
				UtilThread th = new UtilThread(UtilThread.CAL_PROJ_SPACE, me);
				th.setParam(0, projIdS);
				th.start();
			}
			else if (isRemoteUploadFile)
			{
				// recal remote upload space
				// area is:   C:/Temp/Folder1
				// real path: C:/Repository/CR/12345/peace/C-drive/Temp/Folder1
				// db name:   peace$C:/Temp/Folder1? ...  OR   peace$C:/Temp/Folder1*? ...
				area = uploadPath + "/" + uidS + "/" + hostname + "/" + area.replace(":", "-drive");			// peace$
				UtilThread th = new UtilThread(UtilThread.CAL_REMOTE_SPACE, me);
				th.setParam(0, uidS);
				th.setParam(1, area);
				th.setParam(2, dbAreaName);
				th.start();
			}
		}
		else
		{
			// check to see if this removal is the top upload area
			if (subpath!= null && subpath.length() <= 0 && isDirectory)
			{
				// removing top area: need to remove the corresponding Backup attrib item
				String s = Util2.removeAttribute(me, "Backup", dbAreaName);
				System.out.println("**** backup attr removed: " + s);
				userManager.getInstance().commit(me);
				session.setAttribute("pstuser", me);
			}
		}
	}	// END if !isGoogle
	else
	{
		// optionally I can consider calling Google APIs to remove the file on Google server
	}
	
	if (obj != null)
		mgr.commit(obj);

	if (isRemoteUploadFile)
	{
		String loc = "../ep/rdata.jsp?id=" + uidS + "&host="+hostname;
		if (subpath.length()>0 || bAttachmtObjRemoved)
			loc += "&idx=" + idxS;
		else
			loc += "&idx=0";
		if (subpath.length()>0 && bAttachmtObjRemoved)
			loc += "&subpath=" + subpath;
		response.sendRedirect(loc);
	}
	else if (isProject) {
		if (request.getParameter("report") != null)
			response.sendRedirect("proj_report.jsp?projId="+projIdS);
		else
			response.sendRedirect("proj_profile.jsp?projId="+projIdS);
	}
	else if (pTaskId != null)
	{
		session.removeAttribute("planStack");
		response.sendRedirect("task_update.jsp?projId="+projIdS+"&pTaskId="+pTaskId);
	}
	else if (midS != null)
	{
		if (isRun != null)
			response.sendRedirect("../meeting/mtg_live.jsp?mid="+midS+"&run=true");
		else
			response.sendRedirect("../meeting/mtg_update1.jsp?mid="+midS);
	}
	else {
		// append bug history about the delete action
		bug bugObj = (bug)bMgr.get(pstuser, idS);
		String history = "<b>" + ((user)pstuser).getFullName()
				+ "</b> deleted file <b>" + Util3.getOnlyFileName(fname) + "</b>";
		bugObj.appendHistory(history);		// this call will not commit
		bMgr.commit(bugObj);
		response.sendRedirect("../bug/bug_update.jsp?bugId="+idS);
	}
%>
