<%@ page contentType="text/html; charset=utf-8"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2016, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: 	memo2.jsp
//	Author: ECC
//	Date:	02/10/16
//	Description: Step 2 to write a letter to a circle - compose main letter content.
//				 Create the memo object in this JSP.  User may then Save & Continue on content.
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
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	String noSession = "../out.jsp?go=memo/memo_2.jsp";
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%
	PstUserAbstractObject me = pstuser;

	if (me instanceof PstGuest)
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

	String s;

	int myUid = me.getObjectId();
	String myUidS = String.valueOf(myUid);

	SimpleDateFormat df = new SimpleDateFormat("MMM dd, yyyy");
	userinfo.setTimeZone(me, df);
	Date now = new Date();
	String todayS = df.format(now);

	
	// get calling parameters
	String tidS = request.getParameter("tid");
	town tnObj = (town) tnMgr.get(me, tidS);
	String tnName = tnObj.getStringAttribute("Name");
	
	memo mm = null;
	String memNamesS = "";
	String customizedS = "true";		// ECC: always customize
	String mmidS = null;
	Object bTextObj;
	String text = "";
	String title = "";
	int [] ids;
	
	String caller = request.getParameter("caller");

	String [] memNames = request.getParameterValues("memNames");
	
	
	if (memNames == null) {
		// coming from myself (Save & Continue) or (cancel)
		// can also come from memo_3.jsp for updating main memo
		
		mmidS = request.getParameter("mmid");
		mm = (memo) mmMgr.get(me, mmidS);
		
		if ("memo_2".equals(caller)) {
			// from self
			s = request.getParameter("cancel");
			if (s!=null && s.equals("true")) {
				// !!! cancel operation, remove memo and back to home
				mmMgr.delete(mm);
				l.info("removed main memo letter [" + mmidS + "]");
				response.sendRedirect("../ep/ep_omf.jsp");
				return;
			}
			
			text = request.getParameter("logText");					// always get text from the editor
			title = request.getParameter("title");
		}
		else if ("memo_3".equals(caller)) {
			// called by memo_3.jsp to update main memo
			title = mm.getStringAttribute("Name");
		}
		
		memNamesS = request.getParameter("memNamesStr");
		customizedS = request.getParameter("customizeStr");
	}
	else if ("memo_1".equals(caller)) {
		// from memo_1.jsp
		memNamesS = StringUtil.toString(memNames, ";");
		customizedS = request.getParameter("customize");		// can be null or true (always null)
		
		// note it can be back-and-forth between pages: called by memo_1.jsp again
		mmidS = request.getParameter("mmid");
		if (!StringUtil.isNullOrEmptyString(mmidS)) {
			// call again: get object and info, but also save updated attendee list
			mm = (memo) mmMgr.get(me, mmidS);
			title = mm.getStringAttribute("Name");
			
			// save updated attendee list
			mm.setAttribute("Attendee", memNames);
			
			// get all children memo's
			ids = mmMgr.findId(me, "ParentID='" + mmidS + "'");
			PstAbstractObject [] childMemo = mmMgr.get(me, ids);

			// clean up all customized memo that the attendee has been removed
			PstAbstractObject o;
			String uidS;
			//int num = mmMgr.getCount(me, "ParentID='" + mmidS + "'");	// total child memo number
			int num = ids.length;
			
			for (int i=0; num>0 && i<childMemo.length; i++) {
				o = childMemo[i];
				uidS = o.getStringAttribute("Attendee");
				if (memNamesS.contains(uidS)) continue;		// an attendee, don't delete
				
				mmMgr.delete(o);
				num--;
				l.info("memo_2: removed child memo [" + o.getObjectId() + "]");
				
				/*
				uidS = memNames[i];
				if (memNamesS.contains(uidS)) continue;		// an attendee, don't delete
				
				ids = mmMgr.findId(me, "ParentID='" + mmidS + "' && Attendee='" + uidS + "'");
				if (ids.length > 0) {
					o = mmMgr.get(me, ids[0]);
					mmMgr.delete(o);
					num--;
					l.info("memo_2: removed child memo [" + ids[0] + "]");
				}
				*/
			}
		}
		else {
		
			// give the letter a default title (there might be single quote, etc.)
			title = Util.stringToHTMLString("Letter to " + tnName + " - " + todayS);
		}
	}
	
	
	// for writing another letter (Write Again), pass along the parameter
	String mmidAgainS = request.getParameter("mmidAgain");
	if (StringUtil.isNullOrEmptyString(mmidAgainS))
		mmidAgainS = "";

	// create and save memo object
	if (mm == null) {
		// first time create
		mm = (memo) mmMgr.create(me);
		mmidS = String.valueOf(mm.getObjectId());
		l.info("created main memo letter [" + mmidS + "]");
		
		mm.setAttribute("CreatedDate", now);
		mm.setAttribute("Creator", myUidS);
		mm.setAttribute("TownID", tidS);
		mm.setAttribute("Attendee", memNames);
		mm.setAttribute("Type", memo.M_LETTER);
	}
	else {
		// call by self or others: already created, just save content and title here
		
		if (!StringUtil.isNullOrEmptyString(text)) {
			text = text.replaceAll(PrmMtgConstants.REGEX, " ").trim();	//"(<p>[(&nbsp;) ]*</p>)|[<br /></p>]*$" // ("<p>[(&nbsp;) ]*</p>$", "");
			mm.setAttribute("Comment", text.getBytes("UTF-8"));			// save content
		}
		else {
			// get text from object to be displayed in the editor below
			bTextObj = mm.getAttribute("Comment")[0];
			text = (bTextObj==null)?"":new String((byte[])bTextObj, "utf-8");
		}
	}
	
	mm.setAttribute("Name", title);
	mmMgr.commit(mm);

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

window.onload = function()
{
	if (<%=isPDA%> == false) {
		oFCKeditor = new FCKeditor( 'logText' ) ;
		oFCKeditor.ReplaceTextarea() ;
	
		// to enable dragging editor box
		setTextBoxId('logText');
		initDrag(300);
		new dragObject(handleBottom[0], null, new Position(0, beginHeight), new Position(0, 800),
						null, BottomMove, null, false, 0);
	}

	msgE = document.getElementById("timeoutMsg");
	beginRefresh(document.memo_s2);			// defined in init.jsp
	fo();									// init.jsp
}


function validation()
{
	var title = trim(memo_s2.title.value);
	if (title == "") {
		fixElement(document.getElementById("title"), "Please provide a subject for the letter.");
		return false;
	}
	
	disableButtons(true);
	return true;

}

function changeRecv()
{
	memo_s2.action = "memo_1.jsp";
	memo_s2.submit();
}

function cancel_op()
{
	if (confirm("Do you want to quit and remove this letter?")) {
		// remove the letter and leave
		disableButtons(true);
		memo_s2.cancel.value = "true";
		memo_s2.action = "memo_2.jsp";
		memo_s2.submit();
	}
}

function saveAndCont()
{
	if (!validation())
		return false;
	
	memo_s2.action = "memo_2.jsp";		// resubmit to save and continue
	memo_s2.submit();
}

function validateAndSubmit() {
	if (!validation())
		return false;
	
	// if !customize, confirm if user is ready to send email
	if ("<%=customizedS%>" != "true") {
		if (!confirm("Are you ready to send the emails?"))
			disableButtons(false);
			return false;
	}
	
	memo_s2.submit();					// go next to memo_3.jsp
}

function disableButtons(b)
{
	document.getElementById("cancelBut").disabled  = b;
	document.getElementById("submitBut1").disabled = b;
	document.getElementById("submitBut2").disabled = b;
}

//-->
</script>

</head>

<body bgcolor="#FFFFFF">

<form name='memo_s2' action='memo_3.jsp' method='post'>
<input type='hidden' name='caller' value='memo_2' />
<input type='hidden' name='tid' value='<%=tidS%>' />
<input type='hidden' name='customizeStr' value='<%=customizedS%>' />
<input type='hidden' name='memNamesStr' value='<%=memNamesS%>' />
<input type='hidden' name='mmid' value='<%=mmidS%>' />
<input type='hidden' name='cancel' value='' />
<input type='hidden' name='mmidAgain' value='<%=mmidAgainS%>' />


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
	<td class='instruction_head'>Step 2: Compose main letter</td>
	</tr>


<!-- Title of letter -->
<%
	out.print("<tr><td colspan='2'><img src='../i/spacer.gif' height='20'/></td></tr>");

	out.print("<tr><td></td>");
	out.print("<td><table border='0'>");
	
	out.print("<tr><td class='plaintext_big'><b>Subject</b>: </td>");
	out.print("<td><input type='text' size='60' id='title' name='title' class='plaintext' value='" + title + "'></td>");
	out.print("</tr>");
	
	out.print("</table></td></tr>");
%>


<!-- show Editor -->
<%
	out.print("<tr><td colspan='2'><img src='../i/spacer.gif' height='20'/></td></tr>");

	out.print("<tr><td></td>");
	out.print("<td><table border='0' width='100%'>");

	// editor: same as addblog.jsp
%>
	<tr>
		<td width="15">&nbsp;</td>
		<td>
		<table width="100%" border="0" cellspacing="0" cellpadding="0">
		<tr><td colspan="2" valign="top">
			<div id='textDiv'>
				<textarea name="logText" id='logText' rows=10; style='width:100%'><%=text%></textarea>
			</div>
			<div align='right'>
			<span id="handleBottom" ><img src='../i/drag.gif' style="cursor:s-resize;"/></span>
			<span><img src='../i/spacer.gif' width='20' height='1'/></span>
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
%>

<!-- Button to submit -->

	<tr><td colspan='2'><img src='../i/spacer.gif' height='20'/></td></tr>

	<tr><td></td>
		<td align='center'>
			<input type='button' id='prevBut' class='button_medium' onclick='javascript:changeRecv();' value='Change Recipients'/>&nbsp;
			<img src='../i/spacer.gif' width='20' border='0'/>
			<input type='button' id='cancelBut' class='button_medium' onclick='javascript:cancel_op();' value='Cancel'/>&nbsp;
			<input type='button' id='submitBut1' class='button_medium' onclick='return saveAndCont();' value='Save & Continue'/>&nbsp;
			<input type='button' id='submitBut2' class='button_medium' onclick='return validateAndSubmit();' value=' Next '/>
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

</td>
</tr>
</table>


</form>
</body>
</html>
