<%
//
//	Copyright (c) 2008, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_clipAction.java
//	Author: ECC
//	Date:		10/07/2008
//	Description:	Link, copy or move files from clipboard.
//	Modification:
//			@ECC020410	Allow project owner to move files and retain owner name.
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
<%@ page import = "org.apache.log4j.Logger" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />


<%
	// 1.  called by task_update.jsp for copy and move files from clipboard (mid == null)
	// 2.  called by mtg_update1.jsp for copy and move files from clipboard (mid != null)

	final int OP_MOVE = 2;
	final int OP_COPY = 1;
	final int OP_LINK = 0;

	String repository = Util.getPropKey("pst", "FILE_UPLOAD_PATH");
	String host = Util.getPropKey("pst", "PRM_HOST");

	PstUserAbstractObject me = pstuser;
	if (me instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	Logger l = PrmLog.getLog();
	String myUidS = String.valueOf(me.getObjectId());
	
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	boolean isAdmin = (iRole & user.iROLE_ADMIN) > 0;

	String s;
	String backFile = request.getParameter("backPage");
	int op = Integer.parseInt(request.getParameter("op"));				// 0=link; 1=copy; 2=move
	String taskIdS = request.getParameter("taskID");					// destination task ID
	String projIdS = request.getParameter("projId");
	if (projIdS!=null && projIdS.length()<=0)
		projIdS = null;

	String dirIdS;			// either taskId or meeting Id
	String midS = request.getParameter("mid");
	if (midS != null)
		dirIdS = midS;
	else
		dirIdS = taskIdS;

	attachmentManager attMgr = attachmentManager.getInstance();
	taskManager tMgr = taskManager.getInstance();
	meetingManager mMgr = meetingManager.getInstance();

	String projOwnerIdS = "";
	if (projIdS != null)
	{
		projectManager pjMgr = projectManager.getInstance();
		projOwnerIdS = (String)pjMgr.get(me, Integer.parseInt(projIdS)).getAttribute("Owner")[0];
	}

	PstAbstractObject oldAtt, newAtt, tObj, mObj;
	String oldPathName, newPathName, fileName, dirName, relPath,
		attType, deptName, oldAttIdS, oldTaskIdS, attIdS, oldAttmtProjIdS;
	File targetDir, oldF, newF;
	String [] attNames = null;
	int bufSize = 8192;
	Date dt;
	Object freqObj;

	// session cache cleanup
	if (taskIdS != null)
		session.removeAttribute("planStack");	// cleanup cache
	if (op == OP_MOVE)
		session.removeAttribute("clipboard");	// the file is moved away

	// loop through the checked files to copy or move
	ArrayList<PstAbstractObject> attList = new ArrayList<PstAbstractObject>();
	for (Enumeration e = request.getParameterNames() ; e.hasMoreElements() ;)
	{
		String temp = (String)e.nextElement();
		if (temp.startsWith("clip_"))
		{
			attIdS = temp.substring(5);
			oldAtt = attMgr.get(me, attIdS);	// the attachment object
			attList.add(oldAtt);
		}
	}
	
	// sort the file list by name
	// I need to do this because users might be moving versions and they need to be in order
	PstAbstractObject [] attArr = attList.toArray(new PstAbstractObject[0]);
	Util.sortString(attArr, "Location");
	
	for (PstAbstractObject attObj : attArr) {
		oldAtt = attObj;
		attIdS = String.valueOf(oldAtt.getObjectId());
		
		s = (String)oldAtt.getAttribute("Location")[0];
		if (Util.isAbsolutePath(s))
			s = s.substring(repository.length());

		oldPathName = repository + s;
		oldTaskIdS = s.substring(1, s.indexOf("/", 1));

		// error checking: if the attObj belongs to this task, cannot link, copy or move
		if (midS == null)
		{
			tObj = tMgr.get(me, taskIdS);
			if (Util2.foundAttribute(tObj, "AttachmentID", attIdS))
			{
				response.sendRedirect("../out.jsp?e=You cannot link, copy or move files to the same task (" + taskIdS + ").");
				return;
			}
		}

		// error checking: if the attObj is already linked to this task/mtg, cannot link, copy or move
		if (Util2.foundAttribute(oldAtt, "Link", dirIdS))
		{
			if (midS == null) s = "task";
			else s = "meeting";
			response.sendRedirect("../out.jsp?e=The file is already linked to this " + s + ".  You cannot link, copy or move this file to this " + s + ".");
			return;
		}

		deptName = (String)oldAtt.getAttribute("DepartmentName")[0];
		oldAttIdS = String.valueOf(oldAtt.getObjectId());
		oldF = new File(oldPathName);
		String oldAttOwnerIdS = (String)oldAtt.getAttribute("Owner")[0];
		fileName = oldF.getName();
		dt = (Date)oldAtt.getAttribute("CreatedDate")[0];
		freqObj = oldAtt.getAttribute("Frequency")[0];

		// copying or moving to this task/mtg
		dirName = repository + "/" + dirIdS;
		targetDir = new File(dirName);
		if (!targetDir.exists())
			targetDir.mkdir();
		fileName = FileTransfer.getVersionFileName(fileName, targetDir);
		newPathName = dirName + "/" + fileName;
		newF = new File(newPathName);

		// copy or move the physical file to the new location
		if (op == OP_LINK)
		{
			// link file
			// only need to set the Link attribute on the attachment
			oldAtt.appendAttribute("Link", dirIdS);		// may be midS or taskIdS
			attMgr.commit(oldAtt);
			continue;									// I am all DONE: it is just a link
		}
		else if (op == OP_MOVE)
		{
			// move
			oldAttmtProjIdS = (String)oldAtt.getAttribute("ProjectID")[0];
			if (!myUidS.equals(oldAttOwnerIdS) && !isAdmin)
			{
				if (!myUidS.equals(projOwnerIdS)
					|| projIdS==null || oldAttmtProjIdS==null || !projIdS.equals(oldAttmtProjIdS) )
				{
					response.sendRedirect("../out.jsp?e=You are not authorized to move this file; only the file owner can move the file.");
					return;
				}
			}
			if (!oldF.renameTo(newF))
			{
				// error moving file
				l.error("Error moving file: " + oldPathName + " to " + newPathName + ". (System renameTo() failed.)");
				continue;
			}
			attMgr.delete(oldAtt);			// remove old attObj, will reindex
			try
			{
				tObj = tMgr.get(me, oldTaskIdS);
				tObj.removeAttribute("AttachmentID", oldAttIdS);
				tMgr.commit(tObj);			// remove attId from source task
			}
			catch (PmpException ee) {}		// oldTaskIdS might be a userId (files from rdata.jsp) - no need to cleanup
		}
		else
		{
			// copy file (OP_COPY)
			FileInputStream inF = new FileInputStream(oldF);
			FileOutputStream outF = new FileOutputStream(newF);

			byte[] buf = new byte[bufSize];
			int len;
			while ((len = inF.read(buf, 0, bufSize)) > 0)
				outF.write(buf, 0, len);
			inF.close();
			outF.close();
		}

		// get some file info for creating attachment object
		relPath = "/" + dirIdS + "/" + fileName;
		int idx = fileName.lastIndexOf('.');
		String ext = null;
		if (idx != -1) ext = fileName.substring(idx+1).toLowerCase();	// need this for attachment
		if (midS == null)
			attType = attachment.TYPE_TASK;			// task file
		else
			attType = attachment.TYPE_MEETING;		// meeting file

		// clone attachment object
		attNames = attMgr.getAllAttributeNames();
		newAtt = attMgr.create(me,
				myUidS,
				relPath,
				ext,
				projIdS,		// might be null
				attType,
				deptName);
		if (op == OP_MOVE)
		{
			newAtt.setAttribute("CreatedDate", dt);
			newAtt.setAttribute("Frequency", freqObj);
			if (!isAdmin) {
				newAtt.setAttribute("Owner", oldAttOwnerIdS);	// @ECC020410
			}
			attMgr.commit(newAtt);
		}

		// record the new attId in the task object
		if (midS == null)
		{
			tObj = tMgr.get(me, taskIdS);
			tObj.appendAttribute("AttachmentID", String.valueOf(newAtt.getObjectId()));
			tMgr.commit(tObj);				// append attId to target task
		}
		else
		{
			mObj = mMgr.get(me, midS);
			mObj.appendAttribute("AttachmentID", String.valueOf(newAtt.getObjectId()));
			mMgr.commit(mObj);				// append attId to target meeting
		}
	}	// for each file

	// recal space
	if (op==OP_MOVE || op==OP_COPY)
	{
    	UtilThread th = new UtilThread(UtilThread.CAL_PROJ_SPACE, me);
    	th.setParam(0, projIdS);		// projIdS can be null in which case update all project space for this user
    	th.start();
	}

	response.sendRedirect(backFile);
%>
