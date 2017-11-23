<%@ page contentType="text/html; charset=utf-8"%>


<%
//
//	Copyright (c) 2011, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_bug_export.java
//	Author: EL
//	Date:		11/10/2011
//	Description:	Export a list of bug to the Excel file.
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
<%@ page import="org.apache.poi.hssf.usermodel.HSSFSheet"%>
<%@ page import="org.apache.poi.hssf.usermodel.HSSFWorkbook"%>
<%@ page import="org.apache.poi.hssf.usermodel.HSSFCell"%>
<%@ page import="org.apache.poi.hssf.usermodel.HSSFRow"%>
<%@ page import="org.apache.poi.hssf.usermodel.HSSFRichTextString"%>
<%@ page import="org.apache.poi.hssf.usermodel.HSSFCellStyle"%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%!

	userManager uMgr = null;

	private String getUserName(PstUserAbstractObject u, String uIdS)
		throws PmpException	//, UnsupportedEncodingException
	{
		if (uIdS != null)
		try {
			user uObj = (user)uMgr.get(u, Integer.parseInt(uIdS));
			return uObj.getFullName();
		}
		catch (Exception e) {}
		return "-";
	}
	
	// convert from UTF-8 encoded HTML-Pages -> internal Java String Format
	private static String convertFromUTF8(String s) {
	  String out = null;
	  try {
		  //out = new String(s.getBytes("ISO-8859-1"), "GB2312");
		  out = new String(s.getBytes("ISO-8859-1"), "UTF-8");
	  } catch (java.io.UnsupportedEncodingException e) {
		  System.out.println("Unsupported ecoding.");
	    return null;
	  }
	  return out;
	}
%>

<%

	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	if ((pstuser instanceof PstGuest))
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}

	// get the bug list
	uMgr = userManager.getInstance();
	PstAbstractObject [] bugObjList = (PstAbstractObject [])session.getAttribute("bugList");
	String s;

	SimpleDateFormat df = new SimpleDateFormat("MM/dd/yyyy HH:mm");
	final String FILE_PATH = "SHOW_FILE_PATH";		// save the file here
	final String URL_FILE_PATH = "URL_FILE_PATH";	// return the URL file path: same location
	final String FILE_PREFIX = "CT_";
	String NL = "\n";
	String IND = "\t";
	String DEL = ",";

	String fname;
	File f, subDirectory;
	StringBuffer buf  = new StringBuffer(4096);
	String projIdS = request.getParameter("projId");
	if (projIdS == null) projIdS = "";

	// generate MS CSV file
	fname = FILE_PREFIX + projIdS + ".xls"; 	// CT_12345.xls
	String filePath = Util.getPropKey("pst", FILE_PATH);
	String urlPath = Util.getPropKey("pst", URL_FILE_PATH) + "/" + fname;

	//If objectId directory not exist, create it.
	subDirectory = new File(filePath);
	if(!subDirectory.exists())
		subDirectory.mkdirs();


	filePath += "/" + fname;		// filePath now has the absolute path name
	f = new File(filePath);
	f.createNewFile();
	FileOutputStream fos = new FileOutputStream(f);

	// build content
	HSSFWorkbook wb = new HSSFWorkbook();
	HSSFSheet sheet = wb.createSheet("CT " + projIdS);
	wb.setSheetName(0, "CT" + projIdS, HSSFWorkbook.ENCODING_UTF_16);
	HSSFCellStyle style = wb.createCellStyle();
	HSSFRow row;
	HSSFCell cell;
	short colCt;
	int bugId, rowCt = 0;
	
	// multiple owner
	int numOfOwner;
	String [] ownerAttr;						// array that holds the attribute names
	String [] ownerLabel = null;
	String [] sa;
	s = Util.getPropKey("pst", "BUG_OWNER_ATTRIBUTE");
	boolean bHasSpecialOwnerLabel = true;
	if (s != null)
	{
		// there is multiple owner
		sa = s.split(";");						// e.g. Owner; Owner1
		numOfOwner = sa.length;
		ownerAttr = new String[numOfOwner];
		for (int i=0; i<numOfOwner; i++)
			ownerAttr[i] = sa[i].trim();
		s = Util.getPropKey("pst", "BUG_OWNER_LABEL");
		if (s != null) ownerLabel = s.split(";");
		if (ownerLabel==null || ownerLabel.length<numOfOwner) {
			ownerLabel = ownerAttr;				// no special label, just use attr name
			bHasSpecialOwnerLabel = false;
		}
	}
	else
	{
		// only one owner
		numOfOwner = 1;
		ownerAttr = new String[1];
		ownerAttr[0] = "Owner";					// default owner attr name
		ownerLabel = ownerAttr;
		bHasSpecialOwnerLabel = false;
	}

	
	sheet.setDefaultColumnWidth((short)15);
	
	// header: row 0
	int idx = 0;
	row = sheet.createRow((short)rowCt++);
	row.createCell((short)idx++).setCellValue(new HSSFRichTextString("Item No."));
	row.createCell((short)idx++).setCellValue(new HSSFRichTextString("CR #"));
	row.createCell((short)idx++).setCellValue(new HSSFRichTextString("Status"));
	row.createCell((short)idx++).setCellValue(new HSSFRichTextString("Synopsis"));
	row.createCell((short)idx++).setCellValue(new HSSFRichTextString("Description"));
	row.createCell((short)idx++).setCellValue(new HSSFRichTextString("Submitter"));
	for (int i=0; i<numOfOwner; i++) {
		s = ownerLabel[i];
		//if (bHasSpecialOwnerLabel) s = "Owner " + s;	// comment out: don't add the word Owner
		row.createCell((short)idx++).setCellValue(new HSSFRichTextString(s));
	}
	row.createCell((short)idx++).setCellValue(new HSSFRichTextString("Verifier"));
	row.createCell((short)idx++).setCellValue(new HSSFRichTextString("Category"));
	row.createCell((short)idx++).setCellValue(new HSSFRichTextString("Process Type"));
	row.createCell((short)idx++).setCellValue(new HSSFRichTextString("Department"));
	row.createCell((short)idx++).setCellValue(new HSSFRichTextString("Type"));
	row.createCell((short)idx++).setCellValue(new HSSFRichTextString("Priority"));
	row.createCell((short)idx++).setCellValue(new HSSFRichTextString("Severity"));
	row.createCell((short)idx++).setCellValue(new HSSFRichTextString("Due Date"));	// release
	row.createCell((short)idx++).setCellValue(new HSSFRichTextString("Created Date"));
	row.createCell((short)idx++).setCellValue(new HSSFRichTextString("Resolved Date"));
	row.createCell((short)idx++).setCellValue(new HSSFRichTextString("Verified Date"));

	// content
	String status, synopsis, submitter, owner, verifier, projectID, taskID, type,
				note, priority, severity, release, category, processType, userDept, linkS,
				createDateS, completeDateS, verifyDateS;
	Date dt;
	user uObj;

	for (int i = bugObjList.length-1; i >= 0; i--) {
		bug bugObj = (bug)bugObjList[i];
		if (bugObj == null) continue;

		bugId = bugObj.getObjectId();

		// date
		dt			= (Date)bugObj.getAttribute("CreatedDate")[0];
		if (dt != null) createDateS = df.format(dt); else createDateS = "";
		dt			= (Date)bugObj.getAttribute("CompleteDate")[0];
		if (dt != null) completeDateS = df.format(dt); else completeDateS = "";
		dt			= (Date)bugObj.getAttribute("VerifiedDate")[0];
		if (dt != null) verifyDateS = df.format(dt); else verifyDateS = "";
		
		status		= (String)bugObj.getAttribute("State")[0];
		synopsis	= (String)bugObj.getAttribute("Synopsis")[0];
		submitter	= (String)bugObj.getAttribute("Creator")[0];
		verifier	= (String)bugObj.getAttribute("Verifier")[0];
		category	= (String)bugObj.getAttribute("Category")[0];
		processType	= bugObj.getStringAttribute("ProcessType");
		userDept	= bugObj.getStringAttribute("DepartmentName");
		type		= (String)bugObj.getAttribute("Type")[0];
		priority	= (String)bugObj.getAttribute("Priority")[0];
		severity	= (String)bugObj.getAttribute("Severity")[0];
		release		= (String)bugObj.getAttribute("Release")[0];
		note		= bugObj.getRawAttributeAsString("Note");
		if (note == null) note = "";
		else try {
			note = java.net.URLDecoder.decode(note, "utf-8").trim();
			while (note.endsWith("!@@!")) {
				// the better way might be to split note, resolution and solution
				note = note.substring(0,note.length()-4);
			}
			
			// now the first !@@! is resolution
			note = note.replaceFirst("!@@!", "\nResolution:\n");
			
			// the second !@@! is solution
			note = note.replaceFirst("!@@!", "\nSolution:\n");
		}
		catch (Exception e) {
			note = "";
		}
		
		row = sheet.createRow((short)rowCt);
		colCt = 0;
		sheet.setColumnWidth(colCt, (short)1000);
		row.createCell(colCt++).setCellValue(rowCt++);		// row no.
		sheet.setColumnWidth(colCt, (short)2500);
		row.createCell(colCt++).setCellValue(bugId);		// CR #
		row.createCell(colCt++).setCellValue(new HSSFRichTextString(status));	// status
		
		// synopsis
		sheet.setColumnWidth(colCt, (short)10000);
		style.setWrapText(true);
		cell = row.createCell(colCt++);
		cell.setCellStyle(style);
		cell.setCellValue(new HSSFRichTextString(synopsis));					// synopsis

		// description/note
		sheet.setColumnWidth(colCt, (short)10000);
		style.setWrapText(true);
		cell = row.createCell(colCt++);
		cell.setCellStyle(style);
		cell.setCellValue(new HSSFRichTextString(note));						// note
		

		row.createCell(colCt++).setCellValue(new HSSFRichTextString(getUserName(pstuser, submitter)));
		
		for (int j=0; j<numOfOwner; j++) {
			owner = (String)bugObj.getAttribute(ownerAttr[j])[0];				// can be multiple
			row.createCell(colCt++).setCellValue(new HSSFRichTextString(getUserName(pstuser, owner)));
		}
		
		row.createCell(colCt++).setCellValue(new HSSFRichTextString(getUserName(pstuser, verifier)));
		
		row.createCell(colCt++).setCellValue(new HSSFRichTextString(category==null?"-":category));
		row.createCell(colCt++).setCellValue(new HSSFRichTextString(processType==null?"-":processType));	// category
		row.createCell(colCt++).setCellValue(new HSSFRichTextString(userDept==null?"-":userDept));
		
		row.createCell(colCt++).setCellValue(new HSSFRichTextString(type));		// type
		row.createCell(colCt++).setCellValue(new HSSFRichTextString(priority));	// priority
		row.createCell(colCt++).setCellValue(new HSSFRichTextString(severity==null?"-":severity));	// severity
		row.createCell(colCt++).setCellValue(new HSSFRichTextString(release==null?"-":release));	// release
		
		row.createCell(colCt++).setCellValue(new HSSFRichTextString(createDateS));		// created date
		row.createCell(colCt++).setCellValue(new HSSFRichTextString(completeDateS));	// complete date
		row.createCell(colCt++).setCellValue(new HSSFRichTextString(verifyDateS));		// verified date
	}
	wb.write(fos);

	// save buffer to file
	//fos.write(buf.toString().getBytes());
	fos.flush();
	fos.close();
	

	//response.sendRedirect("bug_search.jsp");	// default
	System.out.println(urlPath);
	response.sendRedirect(urlPath);				// the file URL

%>
