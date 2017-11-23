<%@ page contentType="text/html; charset=utf-8"%>

<%
//
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_addfile.java
//	Author: ECC
//	Date:		04/05/2004
//	Description:	Add project files, upload project report, or blog file.
//				Task files are added through post_updtask.jsp
//				Bug files are added through post_updbug.jsp
//				Meeting files are added through post_mtg_upd1 & 2.jsp
//	Modification:
//		@050605ECC	Support adding file attachments to blogs.
//		@061306ECC	Support attachment object type.
//		@ECC121807	Support uploading and showing image file on blog.
//		
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
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");
	
	String repository = Util.getPropKey("pst", "FILE_UPLOAD_PATH");
	String host = Util.getPropKey("pst", "PRM_HOST");
	MultipartRequest mrequest = new MultipartRequest(request, repository, 100*1024*1024, "UTF-8");

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	
	boolean bVersioning;

	String s;
	String projIdS = mrequest.getParameter("projId");
	String specFileName = null;
	String blogIdS = null;
	String backFile = null;
	String type = mrequest.getParameter("type");
	String attType = null;			// @061306ECC the attachment type
	String idS = null;
	PstManager mgr = null;
	PstAbstractObject obj = null;
	String deptName = null;

	if (projIdS != null)
	{
		// adding project file or upload project reports
		bVersioning = true;
		mgr = projectManager.getInstance();
		obj = mgr.get(pstuser, Integer.parseInt(projIdS));
		backFile = mrequest.getParameter("backPage");
		if (backFile == null)
			backFile = "proj_profile.jsp?projId=" + projIdS;
		attType = attachment.TYPE_PROJECT;
		specFileName = mrequest.getParameter("fileName");	// only use for proj report
		deptName = (String)obj.getAttribute("DepartmentName")[0];	// use project's dept name
	}
	else
	{
		// adding file to blog (project, task, bug, action, personal)
		bVersioning = false;			// don't use versioning
		blogIdS = mrequest.getParameter("blogId");		// can be a blogId or "none"
		mgr = resultManager.getInstance();
		backFile = mrequest.getParameter("backPage");
		backFile = backFile.replaceAll("::", "&");
		idS = mrequest.getParameter("idS");
		
		// @061306ECC: find projId based on type
		PstManager tmgr;
		if (type.equals(result.TYPE_TASK_BLOG))
			{tmgr = taskManager.getInstance(); attType = attachment.TYPE_B_TASK;}
		else if (type.equals(result.TYPE_BUG_BLOG))
			{tmgr = bugManager.getInstance(); attType = attachment.TYPE_B_BUG;}
		else if (type.equals(result.TYPE_ACTN_BLOG))
			{tmgr = actionManager.getInstance(); attType = attachment.TYPE_B_ACTION;}
		else if (type.equals(result.TYPE_ENGR_BLOG))
			{tmgr = null; attType = attachment.TYPE_B_PERSONAL;}
		else
		{tmgr = null; attType = attachment.TYPE_B_FORUM;}
		
		if (tmgr != null)
		{
			PstAbstractObject o = tmgr.get(pstuser, idS);
			projIdS = (String)o.getAttribute("ProjectID")[0];
		}
	}

// @AGQ032806
	String bText = mrequest.getParameter("blogText");	// current text
	Enumeration enumeration = mrequest.getFileNames();
	String fileName;

	while (enumeration.hasMoreElements()) {
		Object name = enumeration.nextElement();
		// file attachment upload		
		File AttachmentFileObj = mrequest.getFile(name.toString());		
	
		if (AttachmentFileObj == null)
			continue;
		
		fileName = AttachmentFileObj.getName();
	
		// call by addblog.jsp?
		boolean isBlog = false;
		if (blogIdS != null)
		{
			isBlog = true;
			// check to see if the blog get created yet
			if (blogIdS.equals("none"))
			{
				// caller is addblog.jsp: the blog is not posted (created) yet.  Create now.
				obj = ((resultManager)mgr).create(pstuser);
				obj.setAttribute("Creator", String.valueOf(pstuser.getObjectId()));
				obj.setAttribute("Type", type);
				obj.setAttribute("TaskID", idS);	// taskId or bugId
				obj.setAttribute("Status", "New");	// just for post_addblog.jsp to know that event is not triggered yet
				if (type.equals(result.TYPE_PROJ_BLOG))
					obj.setAttribute("ProjectID", idS);
				blogIdS = obj.getObjectName();
				backFile = backFile.replaceAll("none", blogIdS);	// turn the return to an update of blog
			}
			else
			{
				obj = mgr.get(pstuser, Integer.parseInt(blogIdS));
			}
			obj.setAttribute("CreatedDate", new Date());	// updated or created
		}
	
		// file attachment upload
		// Check account balance and charge user
		int uid = pstuser.getObjectId();
		String uidS = String.valueOf(uid);
	
		FileTransfer ft = new FileTransfer(pstuser);
		try
		{
			// save file only save the file to the repository directory
			// use versioning
			StringBuffer newFileNameBuf = null;
			if (isBlog)
				newFileNameBuf = new StringBuffer();
			attachment att = ft.saveFile(obj.getObjectId(), projIdS, AttachmentFileObj,
					specFileName, attType, deptName, newFileNameBuf, bVersioning);
			if (newFileNameBuf==null || newFileNameBuf.length()<=0)
				obj.appendAttribute("AttachmentID", String.valueOf(att.getObjectId()));

			if (isBlog)
			{
				// add a text line in the blog
				if (bText == null) bText = "";
				
				if (newFileNameBuf.length() <= 0)
				{
					s = "<br><img alt='' src='" + host + "/i/file.gif'/>&nbsp;"
						+ "Uploaded file: <a class='listlink' "
						+ "href='" + host + "/servlet/ShowFile?attId=" + att.getObjectId() + "'>"	// @061306ECC
						+ fileName + "</a><br>";
				}
				else
				{
					// just uploaded an image file
					s = "<br><table width='100%'><tr><td style='padding:10px;'><img src='" + newFileNameBuf.toString() + "' border='0' width='400' /></td>";
					s += "<td valign='top' style='font-size:14px;line-height:20px;font-family:Verdana;width:100%'>Overwrite picture description here&nbsp;</td></tr></table><br>";
					//s += "<td valign='top' style='font-size:12px;line-height:16px'>Overwrite picture description here&nbsp;</td></tr></table><br>";
					//s += "<div id='del' style='color:grey'>You may change the size of the picture by clicking on the image and then re-size</div><br><br>";
				}
				
				// add it to where the cursor is
				// cursor is at the mark !@@!
				int idx = bText.indexOf("!@@!");
				if (idx != -1) {
					StringBuffer sBuf = new StringBuffer(4096);
					sBuf.append(bText.substring(0, idx));
					sBuf.append(s);
					sBuf.append(bText.substring(idx+4));	// skip !@@!
					bText = sBuf.toString();
				}
				else {
					bText += s;				// append to the end
				}
				obj.setRawAttributeUtf("Comment", bText);
				//obj.setAttribute("Comment", bText.getBytes("utf-8"));
				
				// trigger event if it is OMF
				// I won't trigger event or email here but only in post_addblog.jsp
				// the Status attribute will tell post_addblog.jsp that this is a new blog

			}
			mgr.commit(obj);
		}
		catch(Exception e)
		{
			e.printStackTrace();
			String msg = e.getMessage();
			if (msg == null) msg = "";
			response.sendRedirect("../out.jsp?e=Failed to upload file. " + msg);
		}
	}	// END: while loop on uploading a number of files
	
	response.sendRedirect(backFile);	// default
%>
