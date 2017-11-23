<%
////////////////////////////////////////////////////
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	delblog.jsp
//	Author:	ECC
//	Date:	04/22/04
//	Description:
//		Delete a weblog object.
//	Modification:
//
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.*" %>
<%@ page import = "util.*" %>
<%@ page import = "oct.util.file.MyFileFilter" %>
<%@ page import = "org.apache.commons.io.filefilter.WildcardFileFilter" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">
    <head>
        <meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="/oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="/oct-print.css" rel="stylesheet" type="text/css" media="print">

<title>
	<%=session.getAttribute("app")%> Weblog
</title>

</head>

<%
	String blogIdS = request.getParameter("blogId");
	if ((pstuser instanceof PstGuest) || (blogIdS == null))
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	String backPage = request.getParameter("backPage").replace(':','&');

	// delete the blog object
	resultManager rMgr = resultManager.getInstance();
	attachmentManager aMgr = attachmentManager.getInstance();
	// delete all comments associated to this blog
	int [] ids = rMgr.findId(pstuser, "ParentID='" + blogIdS + "'");
	for (int i=0; i<ids.length; i++)
	{
		rMgr.delete((result)rMgr.get(pstuser, ids[i]));
	}

	// delete files attached to this blog
	String s = Util.getPropKey("pst", "FILE_UPLOAD_PATH");	// Repository/PRM
	s += File.separator + blogIdS;
	File f = new File(s);
	File [] fList = f.listFiles();
	if (fList != null)
	{
		for (int i=0; i<fList.length; i++)
			fList[i].delete();
	}
	f.delete();				// delete the blogId directory

	// remove all attachmentObject related to Blog
	result rObj = (result) rMgr.get(pstuser, blogIdS);
	Object [] objArr = rObj.getAttribute("AttachmentID");
	for (int j=0; j<objArr.length; j++) {
		if (objArr[j] != null) {
			int aId = Integer.parseInt(objArr[j].toString());
			attachment aObj = (attachment)aMgr.get(pstuser, aId);
			aMgr.delete(aObj);	
			
		}
	}
	rMgr.delete(rObj);
	
	// remove all image files assciated with this blog
	String picFileStoragePath = Util.getPropKey("pst", "USER_PICFILE_PATH");
	File subDirectory = new File(picFileStoragePath);
	String [] ls;
	FilenameFilter filter = new MyFileFilter(
			blogIdS,	// prefix
			"");		// subfix
	ls = subDirectory.list(filter);
	File aFile;
	if (ls != null)
		for (int i=0; i<ls.length; i++)
		{
			aFile = new File(picFileStoragePath + "/" + ls[i]);
			if (aFile!=null && aFile.exists())
				aFile.delete();
			//System.out.println("deleted file " + ls[i]);
		}
	
	// delete mobile photos attached to this blog
	picFileStoragePath = Util.getPropKey("pst", "BLOG_FILEPATH");	// .../PRM/file/Blog
	subDirectory = new File(picFileStoragePath);		// the directory
	filter = new MyFileFilter(
			blogIdS + "-",	// prefix
			"");			// subfix
	ls = subDirectory.list(filter);
	if (ls != null)
		for (int i=0; i<ls.length; i++)
		{
			aFile = new File(picFileStoragePath + File.separator + ls[i]);
			if (aFile!=null && aFile.exists())
				aFile.delete();
		}
			
	
	session.removeAttribute("planStack");		// cleanup cache

	response.sendRedirect(backPage);
%>
