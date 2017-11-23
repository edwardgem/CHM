<%@ page contentType="text/html; charset=utf-8"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<%
////////////////////////////////////////////////////
//	Copyright (c) 2004-2008, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	post_comp_upd.jsp
//	Author:	ECC
//	Date:	08/14/08
//	Description:
//		post action for comp_update.jsp.
//
//	Modification:
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.file.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>
<%@ page import = "com.oreilly.servlet.*" %>
<%@ page import = "org.apache.log4j.Logger" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	// init
	Logger l = PrmLog.getLog();
	String filepath = Util.getPropKey("pst", "FILE_UPLOAD_PATH");
	MultipartRequest mrequest = new MultipartRequest(request, filepath, 10*1024*1024, "UTF-8");
	
	// check authorized role
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	boolean isAdmin = ((iRole & user.iROLE_ADMIN) > 0);
	boolean isAcctMgr = ((iRole & user.iROLE_ACCTMGR) > 0);

	if ( (pstuser instanceof PstGuest)
			|| (!isAdmin && !isAcctMgr) )
	{
		response.sendRedirect("../out.jsp?msg=Access denied");
		return;
	}
	PstUserAbstractObject me = pstuser;

	userManager uMgr = userManager.getInstance();
	townManager tnMgr = townManager.getInstance();
	PstAbstractObject tObj, uObj;
	
	String s;

	String errMsg = null;
	String tidS = mrequest.getParameter("id");
	int tid = Integer.parseInt(tidS);
	String compDispName = mrequest.getParameter("CompanyName");
	
	// program manager
	String progMgrIdS = null;
	s = mrequest.getParameter("ProgManager");
	user pm = null;
	try {
		if (!StringUtil.isNullOrEmptyString(s)) {
			pm = (user) uMgr.get(me, s);
			progMgrIdS = String.valueOf(pm.getObjectId());
		}
	}
	catch (Exception e) {System.out.println("error getting program manager [" + s + "]");}
	
	// department name
	String deptName = "";
	s = mrequest.getParameter("DeptName");
	if (s!=null && s.length()>0)
		s = s.trim().toUpperCase();
	else s = "";
	for (int i=0; i<s.length(); i++)
	{
		if (s.charAt(i) == ' ') continue;
		deptName += s.charAt(i);
	}
	if (deptName.length() <= 0)
		deptName = null;		// Util.getPropKey("pst", "DEPARTMENTS");
	
	// account manager
	String acctMgrIdS = mrequest.getParameter("AcctManager");
System.out.println("acctmgr="+acctMgrIdS);
System.out.println("isAdmin="+isAdmin);
	/*if (acctMgrIdS == null)
		acctMgrIdS = String.valueOf(me.getObjectId());*/

	// update company
	try
	{
		tObj = tnMgr.get(me, tid);
		tObj.setAttribute("Name", compDispName);
		tObj.setAttribute("DepartmentName", deptName);
		if (isAdmin && acctMgrIdS!=null)
			tObj.setAttribute("AccountManager", acctMgrIdS);
		tObj.setAttribute("Chief", progMgrIdS);			// chief = program manager
		
		// when assign as PM, the PM must be added as a company member
		if (pm != null) {
			pm.appendAttribute("Towns", new Integer(tid));
			uMgr.commit(pm);
		}
		
		// same for AcctMgr
		if (acctMgrIdS != null) {
			user am = (user) uMgr.get(me, Integer.parseInt(acctMgrIdS));
			am.appendAttribute("Towns", new Integer(tid));
			uMgr.commit(am);
		}
		
		// upload logo file
		String compName = tObj.getObjectName();
		Enumeration enum0 = mrequest.getFileNames();
		while (enum0.hasMoreElements())
		{
			Object name = enum0.nextElement();
			File fileObj = mrequest.getFile(name.toString());	// file attachment upload

			if(fileObj != null)
			{
				FileTransfer ft = new FileTransfer(me);
				String fullFileName = ft.savePictureFile(fileObj, tidS);
				tObj.setAttribute("PictureFile", fullFileName);			// commit below
			}
		}
	}
	catch (PmpException e)
	{
		response.sendRedirect("../out.jsp?msg=Failed to get company [" + tidS + "]&go=ep/ep_home.jsp");
		return;
	}
	
	
	// commit the objects
	tnMgr.commit(tObj);
	
	l.info("Updated company " + compDispName + "[" + tidS + "]");

	response.sendRedirect("comp_update.jsp?id=" + tidS + "&msg=<b>Done!</b>  Update of " + compDispName + " completed successfully.");
%>
