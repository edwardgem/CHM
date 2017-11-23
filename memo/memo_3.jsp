<%@ page contentType="text/html; charset=utf-8"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2016, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: 	memo3.jsp
//	Author: ECC
//	Date:	02/10/16
//	Description: Continue from memo2.jsp, save the Main Letter into the created memo object.
//				 The memo is created in memo2.jsp. 
//				 For customized option, open editor to update letters for individual members.
//				 If there is no customization, go ahead and send emails by calling post_memo.jsp
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//

%>

<%@ page import = "util.*" %>
<%@ page import = "mod.mfchat.OmfPresence" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.util.regex.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>
<%@ page import = "org.apache.log4j.Logger" %>

<%
%>

<%!

	// uArr is a sorted user object array
	String layoutUsers(PstUserAbstractObject uObj,
			int rowSize, PstAbstractObject [] uArr, int itemWidth, String linkS)
		throws PmpException
	{
		StringBuffer retBuf = new StringBuffer();
		int num = 0;

		userManager uMgr = userManager.getInstance();
		user u;
		
		retBuf.append("<table border='0'>");

		
		if (uArr.length <= 0) {
			retBuf.append("<tr><td class='formtext'>None</td>");
		}
		
		else for (int i = 0; i<uArr.length; i++) {
			u = (user) uArr[i];
			
			if (num % rowSize == 0) {
				if (num > 0) retBuf.append("</tr>");
				retBuf.append("<tr>");
			}
			
			retBuf.append("<td width='"
					+ itemWidth
					+ "' class='formtext'><a href='"
					+ linkS.replace("$UID$", String.valueOf(u.getObjectId()))
					+ "' class='formtext' >"
					+ u.getFullName() + "</a></td>" );
				
			num++;
		}
		
		retBuf.append("</tr></table>");
		
		return retBuf.toString();
	}

	void printArr(Object [] arr) {
		for (int i=0; i<arr.length; i++)
			System.out.print(arr[i] + "; ");
		System.out.println("");
		
	}

%>

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	String mmidS = request.getParameter("mmid");
	String noSession = "../out.jsp?go=ep/ep_omf.jsp";
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%
	PstUserAbstractObject me = pstuser;

	if (me instanceof PstGuest || StringUtil.isNullOrEmptyString(mmidS))
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}

	Logger l = PrmLog.getLog();
	String HOST = Util.getPropKey("pst", "PRM_HOST");
	int iRole = ((Integer)session.getAttribute("role")).intValue();

	boolean isAdmin = ((iRole & user.iROLE_ADMIN) > 0);
	
	boolean isPDA = Prm.isPDA(request);

	// to check if session is CR, OMF, or PRM
	String subCat = "MyLetter";

	userManager uMgr = userManager.getInstance();
	userinfoManager uiMgr = userinfoManager.getInstance();
	townManager tnMgr = townManager.getInstance();
	memoManager mmMgr = memoManager.getInstance();
	
	SimpleDateFormat df = new SimpleDateFormat("MMM dd, yyyy hh:mm a");
	userinfo.setTimeZone(me, df);
	
	Date now = new Date();

	String s;
	String tidS = null;
	String text = "";
	Object bTextObj;
	int [] ids = null;
	memo childMemo = null;
	String childmmidS = null;
	String addCustUidS = "";
	String caller;
	user u;
	int creatorId = 0;

	String customizedS = "true";				// ECC: always true
	String memNamesS = null;
	String [] memNames = null;

	int myUid = me.getObjectId();
	String myUidS = String.valueOf(myUid);
	
	memo mm = (memo) mmMgr.get(me, mmidS);		// main memo always created by memo_2.jsp
	String title = request.getParameter("title");
	
	// if letter is already sent, then it is read only
	boolean bReadRecv = false;											// read a received letter
	boolean bReadOnly = (mm.getAttribute("CompleteDate")[0] != null);	// read a sent letter
	
	String editorInstruction, clickNameUpdStr;
	String clickNameViewStr = "click name to view";
	if (bReadOnly) {
		editorInstruction = "Letter mailed to";
		clickNameUpdStr = clickNameViewStr;
	}
	else {
		editorInstruction = "Use the below editor to customize a letter to";
		clickNameUpdStr = "click name to customize";
	}
	
	String recvStr = "";
	
	///////////////////////////
	// 1.  call by memo_2.jsp: need to save title and text into main memo
	caller = request.getParameter("caller");
	if ("memo_2".equals(caller)) {
		mm.setAttribute("Name", title);
		
		text = request.getParameter("logText");					// get text from the editor
		text = text.replaceAll(PrmMtgConstants.REGEX, " ").trim();	//"(<p>[(&nbsp;) ]*</p>)|[<br /></p>]*$" // ("<p>[(&nbsp;) ]*</p>$", "");
		mm.setAttribute("Comment", text.getBytes("UTF-8"));			// save content
		mmMgr.commit(mm);
		l.info("memo_3.jsp: saved content for main memo [" + mmidS + "]");
				
		// in case of Write Again, needs to create children memos here
		PstAbstractObject o;
		String attendeeIdS;
		s = request.getParameter("mmidAgain");

		if (!StringUtil.isNullOrEmptyString(s)) {
			ids = mmMgr.findId(me, "ParentID='" + s + "'");
			for (int i=0; i<ids.length; i++) {
				o = mmMgr.get(me, ids[i]);		// get that child memo
				attendeeIdS = o.getStringAttribute("Attendee");		// there should only be one
				
				childMemo = (memo) mmMgr.create(me);
				l.info("created child memo letter [" + childMemo.getObjectId() + "] for " + attendeeIdS);
				
				// content is null and it will use the main letter below
				childMemo.setAttribute("ParentID", mmidS);
				childMemo.setAttribute("CreatedDate", now);
				childMemo.setAttribute("Creator", myUidS);
				childMemo.setAttribute("TownID", tidS);
				childMemo.setAttribute("Attendee", attendeeIdS);
				childMemo.setAttribute("Type", memo.M_LETTER);
				mmMgr.commit(childMemo);
			}
		}
	}
	
	///////////////////////////
	// 2.  call by my_memo.jsp: display/update memo I created
	else if ("my_memo".equals(caller)) {
		// I only received mmid, need to set up title, tidS, customizedS, memNamesS and memNames
		title = mm.getStringAttribute("Name");
		tidS = mm.getStringAttribute("TownID");
		customizedS = "true";		// default to true - no harm, ignore user's previous setting
		Object [] oArr = mm.getAttribute("Attendee");
		memNames = Arrays.copyOf(oArr, oArr.length, String[].class);
		memNamesS = StringUtil.toString(memNames, ";");

		bReadRecv = ((s=request.getParameter("readRecv")) != null && s.equals("true"));
		if (bReadRecv || bReadOnly) {
			bReadOnly = true;
			
			// get the memo to display
			bTextObj = mm.getAttribute("Comment")[0];
			text = (bTextObj==null)?"":new String((byte[])bTextObj, "utf-8");
			
			// received string
			creatorId = Integer.parseInt(mm.getStringAttribute("Creator"));
			u = (user) uMgr.get(me, creatorId);
			Date dt = (Date) mm.getAttribute("CompleteDate")[0];
			recvStr = " by <b>" + u.getFullName() + "</b> on " + df.format(dt);
		}
	}

	///////////////////////////
	// 3.  call by self: remove customized copy (button pressed)
	else if (!StringUtil.isNullOrEmptyString((s = request.getParameter("delChild")))) {
		// !!! remove customized copy operation, remove memo copy
		try {
			ids = mmMgr.findId(me, "ParentID='" + mmidS + "' && Attendee='" + s + "'");
			if (ids.length > 0) {
				memo copymm = (memo) mmMgr.get(me, ids[0]);		// should only have one
				mmMgr.delete(copymm);
				l.info("removed child memo [" + ids[0] + "]");
			}
		}
		catch (PmpException e) {
			l.error("error removing child memo [" + ids[0] + "]");
		}
	}
	
	///////////////////////////
	// 4.  call by self: save an updated child memo (Save button pressed)
	else if (!StringUtil.isNullOrEmptyString((s = request.getParameter("saveChild")))) {
		// save child memo update
		addCustUidS = s;
		
		try {
			ids = mmMgr.findId(me, "ParentID='" + mmidS + "' && Attendee='" + addCustUidS + "'");
			if (ids.length > 0) {
				childmmidS = String.valueOf(ids[0]);
				childMemo = (memo) mmMgr.get(me, ids[0]);					// should only have one
				text = request.getParameter("logText");						// get text from the editor
				text = text.replaceAll(PrmMtgConstants.REGEX, " ").trim();	//"(<p>[(&nbsp;) ]*</p>)|[<br /></p>]*$" // ("<p>[(&nbsp;) ]*</p>$", "");
				
				if (!StringUtil.isNullOrEmptyString(text)) {
					childMemo.setAttribute("Comment", text.getBytes("UTF-8"));		// save content
					mmMgr.commit(childMemo);
					l.info("saved updated child memo [" + childmmidS + "]");
				}
				else {
					// empty content, remove this child
					mmMgr.delete(childMemo);
					l.info("remove child memo [" + childmmidS + "] - user wipe out content");
				}
			}
		}
		catch (PmpException e) {
			l.error("error saving child memo [" + childmmidS + "]");
		}
	}
	
	// get calling parameters
	if (tidS == null)
		tidS = request.getParameter("tid");
	town tnObj = (town) tnMgr.get(me, tidS);
	String tnName = tnObj.getStringAttribute("Name");
	
	if (memNamesS == null) {
		memNamesS = request.getParameter("memNamesStr");			// this is a string separated by ";"
		memNames = StringUtil.toStringArray(memNamesS, ";");
	}

	boolean bCustomized = true;		// ECC: always allow customized

	/* ECC: always customize
	if (customizedS == null)
		customizedS = request.getParameter("customizeStr");

	boolean bCustomized = !StringUtil.isNullOrEmptyString(customizedS);	// null or true
	if (!bCustomized) {
		// no customization needed, send email right away
		response.sendRedirect("post_memo.jsp?mmid=" + mmidS);
		return;
	}*/
	
	if (StringUtil.isNullOrEmptyString(title))
		title = mm.getStringAttribute("Name");
	
	///////////////////////////
	// 5.  call by self: add or view customized user
	if (!StringUtil.isNullOrEmptyString((s = request.getParameter("addChild")))) {
		addCustUidS = s;
		
		// check to see if a child memo for this user already exist
		ids = mmMgr.findId(me, "ParentID='" + mmidS + "' && Attendee='" + s + "'");
		
		if (ids.length > 0) {
			// already exist, just open the child memo for view and update (if not readOnly)
			childMemo = (memo) mmMgr.get(me, ids[0]);
			l.info("open child memo letter [" + ids[0] + "]");
			
			// put the content of child letter into the text editor
			bTextObj = childMemo.getAttribute("Comment")[0];
			text = (bTextObj==null)?"":new String((byte[])bTextObj, "utf-8");
		}
		else {
		// create the child memo for this user
			if (!bReadOnly) {
				childMemo = (memo) mmMgr.create(me);
				l.info("created child memo letter [" + childMemo.getObjectId() + "]");
				
				childMemo.setAttribute("ParentID", mmidS);
				childMemo.setAttribute("CreatedDate", now);
				childMemo.setAttribute("Creator", myUidS);
				childMemo.setAttribute("TownID", tidS);
				childMemo.setAttribute("Attendee", addCustUidS);
				childMemo.setAttribute("Type", memo.M_LETTER);
				mmMgr.commit(childMemo);
			}
			
			text = "";		// use main memo content
		}
		
		if (StringUtil.isNullOrEmptyString(text)) {
			// put the content of main letter into the text editor
			bTextObj = mm.getAttribute("Comment")[0];
			text = (bTextObj==null)?"":new String((byte[])bTextObj, "utf-8");
		}
	}

	
	// separate into customized and non-customized user list for later display
	// allAttendees, cusAttendees, noCusAttendees
			
	int [] allAttendees = Util2.toIntArray(memNames);
	
	ids = mmMgr.findId(me, "ParentID='" + mmidS + "'");
	int [] cusAttendees = new int[ids.length];
	PstAbstractObject o;
	for (int i=0; i<ids.length; i++) {
		o = mmMgr.get(me, ids[i]);
		cusAttendees[i] = Integer.parseInt((String)o.getAttribute("Attendee")[0]);
	}
	
	int [] noCusAttendees = Util2.outerJoin(allAttendees, cusAttendees);


	// display any letter during update session
	boolean bOpenEditor = bCustomized && !StringUtil.isNullOrEmptyString(addCustUidS);
	
%>


<head>
<title><%=session.getAttribute("app")%> Page</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../forms.jsp" flush="true"/>
<script type="text/javascript" src="../resize.js"></script>
<script type="text/javascript" src="<%=HOST%>/FCKeditor/fckeditor.js"></script>

<script language="JavaScript">
<!--


//enter refresh time in "minutes:seconds" Minutes should range from 0 to inifinity. Seconds should range from 0 to 59
var limit="30:0";
var oFCKeditor;
var parselimit=limit.split(":");
parselimit=parselimit[0]*60+parselimit[1]*1
var msgE;

var currentCustomizeUid = "<%=addCustUidS%>";

window.onload = function()
{
	if (<%=isPDA%>==false && <%=bOpenEditor%>==true && <%=bReadOnly%>==false) {
		oFCKeditor = new FCKeditor( 'logText' ) ;
		oFCKeditor.ReplaceTextarea() ;
	
		// to enable dragging editor box
		setTextBoxId('logText');
		initDrag(300);
		new dragObject(handleBottom[0], null, new Position(0, beginHeight), new Position(0, 800),
						null, BottomMove, null, false, 0);

		msgE = document.getElementById("timeoutMsg");
		beginRefresh(document.memo_s2);			// defined in init.jsp
		fo();									// init.jsp
	}
}


function updateMain()
{
	memo_s3.action = "memo_2.jsp";		// back to memo_2.jsp to update main memo
	memo_s3.submit();
}

function addCustomize(uid)
{
	// create a child memo for this user (by calling memo_3.jsp)
	memo_s3.addChild.value = "" + uid;
	memo_s3.action = "memo_3.jsp";
	memo_s3.submit();
}

function viewCustomize(uid)
{
	// open the child memo of this user for view and update
	memo_s3.addChild.value = "" + uid;
	memo_s3.action = "memo_3.jsp";
	memo_s3.submit();
}

function send()
{
	if (!confirm("Are you ready to send out the emails?  This is irreversible."))
		return false;
	memo_s3.submit();			// call post_memo.jsp to send emails
}

function done()
{
	location = "my_memo.jsp";
}

function removeCust()
{
	// remove customized copy for currently displayed user
	if (confirm("Do you want to remove this customized copy?")) {
		// remove the letter
		disableButtons(true);
		memo_s3.delChild.value = currentCustomizeUid;
		memo_s3.action = "memo_3.jsp";
		memo_s3.submit();
	}
}

function saveCust() {
	disableButtons(true);
	memo_s3.saveChild.value = currentCustomizeUid;
	memo_s3.action = "memo_3.jsp";
	memo_s3.submit();
}


function disableButtons(b)
{
	document.getElementById("cancelBut").disabled  = b;
	document.getElementById("submitBut1").disabled = b;
	document.getElementById("submitBut2").disabled = b;
}

function writeAgain()
{
	memo_s3.mmid.value = "";
	memo_s3.mmidAgain.value = "<%=mmidS%>";
	memo_s3.action = "memo_1.jsp";
	memo_s3.submit();
}

//-->
</script>

</head>

<body bgcolor="#FFFFFF">

<form name='memo_s3' action='post_memo.jsp' method='post'>
<input type='hidden' name='caller' value='memo_3' />
<input type='hidden' name='tid' value='<%=tidS%>' />
<input type='hidden' name='customizeStr' value='<%=customizedS%>' />
<input type='hidden' name='memNamesStr' value='<%=memNamesS%>' />
<input type='hidden' name='mmid' value='<%=mmidS%>' />
<input type='hidden' name='delChild' value='' />
<input type='hidden' name='addChild' value='' />
<input type='hidden' name='saveChild' value='' />
<input type='hidden' name='mmidAgain' value='' />


<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">

<table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr align="left" valign="top">
    <td width="100%">
	<jsp:include page="../head.jsp" flush="true"/>
	</td>
	</tr>
</table>
<table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr align="left" valign="top">
    <td width='100%'>
      <table width='90%' border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td>
            <table width="100%" border="0" cellspacing="0" cellpadding="0">
              <tr>
                <td width="26" height="30"><a name="top">&nbsp;</a></td>
                <td width="754" height="30" align="left" valign="bottom" class="head">
				Send Letter to <%=tnName%>
				 </td>
<%	if (creatorId==myUid && bReadOnly && !bReadRecv) {%>
				 <td width='290'>
				 	<img src='../i/bullet_tri.gif' width='20' height='10'/>
				 	<a class='listlinkbold' href='javascript:writeAgain();'>Write again</a>
				 </td>
<%	} %>
              </tr>
            </table>
          </td>
        </tr>
        
        <tr>
				<td width="100%">
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Home" />
				<jsp:param name="subCat" value="<%=subCat%>" />
				<jsp:param name="role" value="<%=iRole%>" />
			</jsp:include>
<!-- End of Navigation Menu -->
				</td>
	    </tr>

<tr>
	<td width='100%'>
	<table border='0' cellspacing="0" cellpadding="0" width='100%'>
	<tr>
	<td><img src='../i/spacer.gif' width='20' height='1'/></td>
	<td></td>
	</tr>
	
	<tr><td></td>
	<td class='instruction_head'>Step 3: Customize letter to individual members</td>
	</tr>


<!-- Title of letter -->
<%
	out.print("<tr><td colspan='2'><img src='../i/spacer.gif' height='20'/></td></tr>");

	out.print("<tr><td></td>");
	out.print("<td><table border='0'>");

	// display title
	out.print("<tr><td class='plaintext_big'><b>Title</b>: </td>");
	out.print("<td class='plaintext_big'>" + title + "</td>");
	out.print("</tr>");
	
	out.print("</table></td></tr>");
%>

<!-- show user list: customized NOT done -->
<%
if (!bReadRecv) {
	out.print("<tr><td colspan='2'><img src='../i/spacer.gif' height='20'/></td></tr>");
	
	out.print("<tr><td></td>");
	out.print("<td><table border='0'>");
	
	out.print("<tr><td><img src='../i/bullet_tri.gif' border='0'/></td>");
	out.print("<td class='plaintext_head'>Use main letter <span class='plaintext'>("
				+ clickNameUpdStr + "):</span></td></tr>");
	
	
	// list names in rows of four
	out.print("<tr><td></td><td>");
	
	final int ROW_SIZE = 4;
	PstAbstractObject [] uArr = uMgr.get(me, noCusAttendees);
	Util.sortUserArray(uArr, true);
	String linkS = "javascript:addCustomize($UID$);";
	out.print(layoutUsers(me, ROW_SIZE, uArr, 200, linkS));
	
	out.print("</td></tr>");
	
	
	out.print("</table></td></tr>");
%>

<!-- show user list: customized done -->
<%
	out.print("<tr><td colspan='2'><img src='../i/spacer.gif' height='20'/></td></tr>");
	
	out.print("<tr><td></td>");
	out.print("<td><table border='0'>");
	
	out.print("<tr><td><img src='../i/bullet_tri.gif' border='0'/></td>");
	out.print("<td class='plaintext_head'>Use customized letter <span class='plaintext'>("
					+ clickNameViewStr + "):</span></td></tr>");
	
	
	// list names in rows of four
	out.print("<tr><td></td><td>");
	
	uArr = uMgr.get(me, cusAttendees);
	Util.sortUserArray(uArr, true);
	linkS = "javascript:viewCustomize($UID$);";
	out.print(layoutUsers(me, ROW_SIZE, uArr, 200, linkS));
	
	out.print("</td></tr>");
	
	
	out.print("</table></td></tr>");
}	// END: if bReadRecv
%>

<!-- show Editor to customize for a person -->
<%
if (bOpenEditor || bReadRecv) {

	out.print("<tr><td colspan='2'><img src='../i/spacer.gif' height='20'/></td></tr>");

	out.print("<tr><td></td>");
	out.print("<td><table border='0' width='100%'>");
	
	// instruction
	out.print("<tr><td></td><td class='plaintext_big'>&nbsp;");
	if (!bReadRecv) {
		u = (user) uMgr.get(me, Integer.parseInt(addCustUidS));
		out.print(editorInstruction + " <b>" + u.getFullName() + "</b>" + recvStr + "</td></tr>");
	}
	else {
		u = (user) me;
		out.print(editorInstruction + " <b>" + u.getFullName() + "</b>" + recvStr + "</td></tr>");
	}

	// editor: same as addblog.jsp
%>
	<tr>
		<td width="15">&nbsp;</td>
		<td>
		<table width="100%" border="0" cellspacing="0" cellpadding="0">
		<tr><td colspan="2" valign="top">
			<div id='textDiv'>
<%	if (!bReadOnly) { %>
				<textarea name="logText" id='logText' rows='10'; style='width:100%' ><%=text%></textarea>
			</div>
			<div align='right'>
			<span id="handleBottom" ><img src='../i/drag.gif' style="cursor:s-resize;"/></span>
			<span><img src='../i/spacer.gif' width='20' height='1'/></span>
<%	}
	else {
		// put letter in the mail format and display it
		String HTMLfile = Util.getPropKey("pst", "MAIL_FILEPATH") + "/alert.htm";
		text = Email.insertFileContent(HTMLfile, text);
		out.print("<div><hr/><p/><img src='../i/spacer.gif' height='20' border='0'/></div>");
		out.print("<span class='plaintext_big'>" + text + "</span>");
	}
%>
			</div>
		</td>
		</tr>


<!-- timeout -->
		<tr><td id='timeoutMsg' class='plaintext' style='color:#00cc00'></td></tr>
		</table>
		</td>
	</tr>
<%
	out.print("</table></td></tr>");

}	// END: if bOpenEditor
%>

<!-- Button to submit -->

	<tr><td colspan='2'><img src='../i/spacer.gif' height='20'/></td></tr>

	<tr><td></td>
		<td align='center'>
		
<%

	if (!bReadOnly) {
		if (!bReadRecv) {
			out.print("<input type='button' id='updMainBut' class='button_medium' onclick='javascript:updateMain();' value='Update Main Letter'/>&nbsp;");
		}

		if (bOpenEditor) {
			out.print("<input type='button' id='cancelBut' class='button_medium' onclick='javascript:removeCust();' value='Remove Customized Copy'/>&nbsp;");
			out.print("<img src='../i/spacer.gif' width='20' border='0'/>");
			out.print("<input type='button' id='submitBut1' class='button_medium' onclick='return saveCust();' value=' Save '/>&nbsp;");
			out.print("<img src='../i/spacer.gif' width='20' border='0'/>");
		}

		out.print("<input type='button' id='submitBut2' class='button_medium' onclick='return send();' value=' Send Letters '/>");
	}
	else {
		out.print("<input type='button' id='submitBut2' class='button_medium' onclick='return done();' value=' Done '/>");
		if (!bReadRecv) {
			out.print("<img src='../i/spacer.gif' width='20' border='0'/>");
			out.print("<input type='button' id='submitBut3' class='button_medium' onclick='return delete();' value=' Delete '/>");
		}
	}
%>


		</td>
	</tr>
	
	</table>
	</td>
</tr>
<!-- End List of Blog -->

<!-- ************************** -->

      </table>
    </td>
  </tr>

</table>

</td>
</tr>
</table>


<p>&nbsp;</p>
<jsp:include page="../foot.jsp" flush="true"/>

</form>
</body>
</html>
