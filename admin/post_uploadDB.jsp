<%@ page contentType="text/html; charset=utf-8"%>

<%
//
//	Copyright (c) 2014, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_uploadDB.java
//	Author: EL
//	Date:		11/10/2011
//	Description:	
//		Create a list of object (support bug and user)
//		The source file must be an .xls file.
//		The first row must be attribute names;
//		For user object, the first attribute must be Email (for username)
//		For user object, we can update userinfo object also. Attribute name should be ui.TimeZone
//
//		@ECC20151010: add an option to add the new user to a project.  This need to be done
//		by changing the code below
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
<%@ page import = "java.net.URLEncoder" %>

<%@ page import = "com.oreilly.servlet.*" %>
<%@ page import="org.apache.poi.hssf.usermodel.HSSFSheet"%>
<%@ page import="org.apache.poi.hssf.usermodel.HSSFWorkbook"%>
<%@ page import="org.apache.poi.hssf.usermodel.HSSFCell"%>
<%@ page import="org.apache.poi.hssf.usermodel.HSSFRow"%>
<%@ page import="org.apache.poi.hssf.usermodel.HSSFRichTextString"%>
<%@ page import="org.apache.poi.hssf.usermodel.HSSFCellStyle"%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%

%>
<%!
	final static int MAX_ATTR			= 50;
	
	final static String NODE = Util.getPropKey("pst", "PRM_HOST");
	final static String appTitle = Prm.getAppTitle();
	
	final static Date today = new Date();
	
	/////////////////////
	// customized attributes
	// @ECC20151010 change this constants to add a project
	final static boolean bOVER_WRITE	= false;	// if user already exist, do you want to overwrite its values
	final static int ADD_PROJID			= 355627;	// 74807.  0 if don't want to add project to user

	final static String PASSWD_SUFFIX		= "2017";		// for GHBD-2017
	final static String COMPANY_NAME		= "GHBD";		// GHBD
	final static String ALERT_HTML_FILE		= "alert_GHBD.htm";

	
	final static String FROM = "ghbd@hku-szh.org";		//Util.getPropKey("pst", "FROM");
	final static String SUBJ = "[Collabris-CHM] Welcome to GHBD";
	
	String statusMsg = "";
	

/* 	final static String MSG =
		"<br/><br/>尊敬的参会者：<br/>"
		+ "&nbsp;&nbsp;&nbsp;&nbsp;您好！<br/>"
		+ "&nbsp;&nbsp;&nbsp;&nbsp;欢迎您参加在香港大学深圳医院举办的第二届国际云计算、移动医疗和医疗大数据研讨会。<br/>"
		+ "&nbsp;&nbsp;&nbsp;&nbsp;本次会议的时间为10月15日8：45开始开幕式典礼，10月17日上午12：00闭幕典礼，总共2天半的时间。"
		+ "<br/><br/><b>温馨提示</b>："
		+ "<ol><li>参会者来院后在科教管理楼大厅办理注册报到，已报名的参会者请在进门右边签到，同时领取参会证、会刊及资料。</li>"
		+ "<li>会议提供10月15日、10月16日中午的午餐券，凭午餐券在后勤服务楼一楼员工餐厅用餐。</li>"
		+ "<li>已交费的参会者请在报到处索取发票。</li>"
		+ "<li>本次会议不提供住宿。</li>"
		+ "</ol><br/><br/>"
		+ "<b>联系地址</b>：<br/>"
		+ "&nbsp;&nbsp;广东深圳市福田区海园一路（白石路与侨城东路交汇）香港大学深圳医院<br/>"
		+ "&nbsp;&nbsp;交通指南：http://hku-szh.org/Nabout/index88.html<br/>"
		+ "<b>联系电话</b>：0755-86913333-8863或8721<br/><br/>"
		+ "请按下面的指示登进系统，可以看到所有大会的信息。<br/><br/>"
		+ "A new CHM user account has been created for you. "
		+ "You can obtain all information about the CMBH '15 Conference from here."
		+ "<blockquote>";
 */
 	final static String MSG = "";
	
	// END: customized attributes
	/////////////////////

	// convert from UTF-8 encoded HTML-Pages -> internal Java String Format
/* 	private static String convertFromUTF8(String s) {
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
 */
 
	private static void sendNotificationEmail(
			PstUserAbstractObject u, PstAbstractObject obj, String email)
		throws PmpException
	{
		String uname = obj.getObjectName();
		int idx = uname.indexOf('@');
		String passwd;		// passwd is name only, no Email part
		if (idx != -1)
			passwd = uname.substring(0, uname.indexOf('@'));
		else
			passwd = uname;
		passwd += PASSWD_SUFFIX;
		
		String msg = "<table border='0' cellspacing='0' cellpadding='0'>";
		msg += "<tr><td class='plaintext' width='150'>Username:</td><td class='plaintext'>" + uname + "</td></tr>";
		msg += "<tr><td class='plaintext'>Password:</td><td class='plaintext'>" + passwd + "</td></tr>";
		msg += "<tr><td class='plaintext'>Email:</td><td class='plaintext'>" + email + "</td></tr>";
		msg += "<tr><td colspan='2'>&nbsp;</td></tr>";
		msg += "<tr><td colspan='2' class='plaintext'>Please click this link to login:&nbsp;&nbsp;";
		msg += "<b><a href='" + NODE + "'>" + NODE + "</a></b></td></tr>";
		msg += "</table>";
		msg += MSG + msg;
		msg += "</blockquote><br><br>";
		msg += "If you have any questions, please contact " + appTitle + " Admin at " + FROM;
		
		Util.sendMailAsyn(u, FROM, email, null, null, SUBJ, msg, ALERT_HTML_FILE);

	}
%>

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	String repository = Util.getPropKey("pst", "FILE_UPLOAD_PATH");
	MultipartRequest mrequest = new MultipartRequest(request, repository, 100*1024*1024, "UTF-8");

	if ((pstuser instanceof PstGuest))
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}


	SimpleDateFormat df = new SimpleDateFormat("MM/dd/yyyy");

	PstManager mgr;
	bugManager bMgr = bugManager.getInstance();
	userManager uMgr = userManager.getInstance();
	userinfoManager uiMgr = userinfoManager.getInstance();
	projectManager pjMgr = projectManager.getInstance();
	townManager tnMgr = townManager.getInstance();

    HSSFCell aCell;
    HSSFRichTextString sValue;
    
    // get organization name
    String orgName = mrequest.getParameter("orgName");
    System.out.println(">>>     orgname=" + orgName);
    
    boolean isBug, isUser;
    isBug = isUser = false;
    
    String s = Util.getPropKey("pst", "USERNAME_EMAIL");
    boolean isUsernameEmail = (s==null || !s.equals("false"));
    
    project pjObj = null;
    
    // get town
    PstAbstractObject tnObj = tnMgr.get(pstuser, COMPANY_NAME);
    int companyId = tnObj.getObjectId();

    
    // only support bug and user
    if (orgName.equalsIgnoreCase("bug")) {
    	// only support bug type now
    	isBug = true;
    	mgr = bMgr;
    }
    else if (orgName.equalsIgnoreCase("user")) {
    	isUser = true;
    	mgr = uMgr;
    	
        // check to see if we need to add project membership to newly created users
		if (ADD_PROJID > 0)
			pjObj = (project) pjMgr.get(pstuser, ADD_PROJID);
    }
    else {
    	// not supported
    	response.sendRedirect("../out.jsp?msg=unsupported type");
    	return;
    }
         
	try {
		File fObj = mrequest.getFile("uploadFile");
		FileInputStream fileInputStream = new FileInputStream(fObj);
		HSSFWorkbook workbook = new HSSFWorkbook(fileInputStream);
		HSSFSheet worksheet = workbook.getSheetAt(0);
		
		// get Attribute Names
		int rowNum = 0;
		int successCt = 0;
		int totalAttr = 0;
		
		// row 0 is attribute name
		HSSFRow rowAttrName = worksheet.getRow(rowNum++);
		String [] attNameArr = new String [MAX_ATTR];
		
		
		// get attribute names
		for (int i=0; i<MAX_ATTR; i++) {
			aCell = rowAttrName.getCell((short) i);
			if (aCell == null) {
				break;
			}
			
			s = aCell.getRichStringCellValue().toString().trim();
			if (StringUtil.isNullOrEmptyString(s)) {
				// no more
				attNameArr[i] = null;
				break;
			}
			
			attNameArr[i] = s;			// store the attribute name
			totalAttr++;
		}
		
		// set up the arrays for attribute type and multi-value
		String name;
		int [] attrTypeArr = new int[totalAttr];
		boolean [] attrMultArr = new boolean[totalAttr];
		for (int i=0; i<totalAttr; i++) {
			name = attNameArr[i];
			if (isBug) {
				attrTypeArr[i] = bMgr.getAttributeType(name);
				attrMultArr[i] = bMgr.hasMultipleValues(name);
			}
			else {
				if (name.startsWith("ui.")) {
					name = name.substring(3);		// skip "ui."
					attrTypeArr[i] = uiMgr.getAttributeType(name);
					attrMultArr[i] = uiMgr.hasMultipleValues(name);
				}
				else {
					attrTypeArr[i] = uMgr.getAttributeType(name);
					attrMultArr[i] = uMgr.hasMultipleValues(name);
				}
			}
		}
		
		
		// extract data (now rowNum == 1)
		HSSFRow aRow;
		PstAbstractObject obj, saveObj;
		String uname, nameOnly, passwd=null;
		int ct;
		boolean bUserExist;
		int [] id;
		int attrType;
		boolean bMultiValue;
		String [] sa;
		userinfo uiObj;
		String attName;
		
		// for user object, need to rely on the Email attribute to create username
		
		// process one row at a time
		while (true) {
			
			// get a row
			aRow = worksheet.getRow(rowNum++);
			if (aRow == null || rowNum>100) break;		// put a row limit for safety
			
			obj = null;
			uiObj = null;
			saveObj = null;								// when attribute is ui., saveObj=user obj; obj=uiObj
			uname = null;
			bUserExist = false;
			
			if (isBug) {
				obj = bMgr.create(pstuser);
			}

			// start processing cell for attribute one at a time
			for (int i=0; i<totalAttr; i++) {
				
				attName = attNameArr[i];
				System.out.println("--- processing " + attName);
				
				// restore user obj
				if (saveObj != null) {
					obj = saveObj;
					saveObj = null;
				}

				aCell = aRow.getCell((short) i);
				if (aCell == null) {
					//System.out.println("-- empty cell");
					continue;		// a cell might be empty
				}
				
				// attribute type and multi-value
				attrType = attrTypeArr[i];
				bMultiValue = attrMultArr[i];
				
				// is this an userinfo attribute?
				if (attNameArr[i].startsWith("ui.")) {
					saveObj = obj;
					obj = uiObj;
					attName = attNameArr[i].substring(3);
				}
				
				
				switch (attrType) {
				
				case PstAbstractObject.STRING:					
				case PstAbstractObject.RAW:
					
					try {
						// although String attr, it is possible the value is an int
						s = aCell.getRichStringCellValue().toString();
					}
					catch (Exception e) {
						// the cell is an integer
						s = String.valueOf((int) aCell.getNumericCellValue());
					}

					if (s==null || s.trim()=="") continue;
					s = s.trim();

					if (attrType == PstAbstractObject.STRING) {
						
						// create user object
						if (isUser && attName.equals("Email")) {
							
							// use Email to see if this user exist
							id = uMgr.findId(pstuser, "Email='" + s + "'");
							if (id.length > 0) {
								bUserExist = true;
								obj = uMgr.get(pstuser, id[0]);
								uname = obj.getObjectName();
							}
							else {
								// need to create the user object now
								nameOnly = s.substring(0, s.indexOf('@'));
								passwd = nameOnly + PASSWD_SUFFIX;
								if (isUsernameEmail) {
									uname = s;			// use Email as username
								}
								else {
									uname = nameOnly;
								}
							}
							
							ct = 0;
							while (!bUserExist && ct++ < 10) {
								try {
									obj = uMgr.create(pstuser, uname, passwd);
									System.out.println("created user: " + uname + " (" + passwd + ")");
									
									//////////////////////////
									// update any attributes here
									if (!StringUtil.isNullOrEmptyString(COMPANY_NAME)) {
										obj.setAttribute("Company", String.valueOf(companyId));
										obj.setAttribute("Towns", companyId);
									}
									obj.setAttribute("Role", "User");
									obj.setAttribute("HireDate", today);
									
									//////////////////////////
									// create userinfo
									uiObj = (userinfo)uiMgr.create(pstuser, String.valueOf(obj.getObjectId()));
									uiObj.setAttribute("Preference", "BlogCheck:Mon");
									uiObj.setAttribute("Location", "zh_CN");
									uiObj.setAttribute("TimeZone", new Integer(8));
									//uiMgr.commit(uiObj);		ECC: commit at end of a row
									
									// send notification email to user
									sendNotificationEmail(pstuser, obj, s);
									
									break;		// success, break out of while loop
								}
								catch (PmpException e) {
									if (e.getMessage().contains("Duplicate")) {
										// check to see if this person already exist by looking at the Email
										// if so, just skip
										if (isUsernameEmail) {
											bUserExist = true;
											break;
										}

										// non-email user, might just have a collision on name
										obj = uMgr.get(pstuser, uname);
										if (s.equalsIgnoreCase(obj.getStringAttribute("Email"))) {
											// found person with same name and Email
											// user already exists
											bUserExist = true;
											break;
										}
										
										uname += ct;
										continue;
									}
									System.out.println("Error in post_uploadDB.jsp: " + e.getMessage());
							    	response.sendRedirect("../out.jsp?msg=Error-1 creating user object at line "
										+ rowNum + " [" + uname + "]");
							    	return;
								}
							}	// while: try create 10 times
							
							if (bUserExist) {
								System.out.println("!!! user [" + uname + "] already exists, do not create");
								break;		// ignore this row, break out of switch first
							}
							
							if (obj == null) {
						    	response.sendRedirect("../out.jsp?msg=Error-2 creating user object at line "
						    			+ rowNum + " [" + uname + "]");
						    	return;
							}
						}	// END if: Email attribute
						
						
						// save String attribute value
						// can be email or other attributes
						if (!bUserExist || bOVER_WRITE) {
							if (!bMultiValue) {
								obj.setAttribute(attName, s);
							}
							else {
								// for multi-valued attribute, values separated by semicolon
								sa = s.split(";");
								for (int j=0; j<sa.length; j++) {
									s = sa[i].trim();
									if (s.length() > 0) {
										obj.appendAttribute(attName, s);
									}
								}
							}
						}
					}
					
					// RAW type
					else {
						// RAW type
						//obj.setAttribute(attName, s.getBytes("UTF-8"));
						obj.setAttribute(attName, URLEncoder.encode(s, "UTF-8").getBytes());
					}
					
					break;
					
					
				case PstAbstractObject.INT:
					// ECC: should handle multi-valued attribute also
					int iVal = (int) aCell.getNumericCellValue();
					obj.setAttribute(attName, iVal);
					break;
					
					
				case PstAbstractObject.DATE:
					// ECC: should handle multi-valued attribute also
					Date dt = aCell.getDateCellValue();
					obj.setAttribute(attName, dt);
					break;
					
					
				default:
					System.out.println("Unsupported attr type: " + attrType);
					break;
				}	// END switch of attrType
				
				if (bUserExist) break;			// no need to process this line
				
			}	// END: for each cell
			
			
			//////////////////////////////////
			// finish processing a line
			//////////////////////////////////
			
							
			// restore user obj after processing a line
			if (saveObj != null) {
				obj = saveObj;
				saveObj = null;
			}


			if (isUser && obj!=null && pjObj!=null) {
				// might need to add the user to a project
				pjObj.appendAttribute("TeamMembers", obj.getObjectId());
				pjMgr.commit(pjObj);
				System.out.println("   added user [" + obj.getObjectName() + "] to project [" + ADD_PROJID + "]");
			}
			
			if (bUserExist) {
				continue;		// continue to process another line
			}
			
			if (obj == null) break;		// failed or end, so break
					
			if (isUser && uname!=null) {
				// make sure there is a FirstName/LastName
				if (obj.getStringAttribute("FirstName") == null)
					obj.setAttribute("FirstName", uname);

				if (obj.getStringAttribute("LastName") == null)
					obj.setAttribute("LastName", ".");
			}

			//save
			mgr.commit(obj);
			System.out.println("+++++  created and saved an object [" + obj.getObjectName() + "]");
			
			if (isUser && uiObj!=null) {
				uiMgr.commit(uiObj);
			}
			successCt++;

		}	// END: while there is another line
		
		
		System.out.println("total row processed   = " + rowNum);
		System.out.println("total objects created = " + successCt);
		
		statusMsg = "total row processed   = " + rowNum
				+ "<br>" + "total objects created = " + successCt;
		
		//Date d1Val = cellD1.getDateCellValue();

	} catch (FileNotFoundException e) {
		e.printStackTrace();
		statusMsg = "Error: " + e.getMessage();
	} catch (Exception e) {
		e.printStackTrace();
		statusMsg = "Error: " + e.getMessage();
	}

	response.sendRedirect("admin.jsp?msg=" + statusMsg);

%>
