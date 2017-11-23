<%@ page contentType="text/html; charset=utf-8"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2016, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: 	post_memo.jsp
//	Author: ECC
//	Date:	02/10/16
//	Description: Final step to send a letter to a circle and display complete message.
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

	// to check if session is CR, OMF, or PRM
	String subCat = "MyLetter";

	userManager uMgr = userManager.getInstance();
	userinfoManager uiMgr = userinfoManager.getInstance();
	townManager tnMgr = townManager.getInstance();
	memoManager mmMgr = memoManager.getInstance();

	String s;

	int myUid = me.getObjectId();
	String myUidS = String.valueOf(myUid);
	
	memo mm = (memo) mmMgr.get(me, mmidS);
	Object bTextObj = mm.getAttribute("Comment")[0];
	String mainText = (bTextObj==null)?"":new String((byte[])bTextObj, "utf-8");
	
	// get calling parameters
	String tidS = request.getParameter("tid");
	town tnObj = (town) tnMgr.get(me, tidS);
	String tnName = tnObj.getStringAttribute("Name");

	// send email one by one
	Date now = new Date();
	
	// for each member, if there is a customized letter, use that, otherwise send main letter
	Object [] oArr = mm.getAttribute("Attendee");
	String [] attendeeArr = Arrays.copyOf(oArr, oArr.length, String[].class);

	
	String mainMailList="", custMailList="", uname;
	user u;
	String MAILFILE = "alert.htm";
	String subj = mm.getStringAttribute("Name");
	String from = me.getStringAttribute("Email");
	String msg;		// content of email
	int [] ids;
	PstAbstractObject o;
	
	
	for (String uidS : attendeeArr) {
		try {
			u = (user) uMgr.get(me, Integer.parseInt(uidS));
			uname = u.getFullName();
		}
		catch (Exception e) {continue;}
		
		// send one-by-one
		
		// get customized email
		l.info("post_memo: sent email to [" + uidS + "]");
		ids = mmMgr.findId(me, "ParentID='" + mmidS + "' && Attendee='" + uidS + "'");
		if (ids.length <= 0) {
			// use main letter
			msg = mainText;
			Util.sendMailAsyn(me, from, uidS, null, null, subj, msg, MAILFILE);
			mainMailList += "</p>" + uname;
			l.info("   use main letter");
		}
		else {
			// use customized letter
			o = mmMgr.get(me, ids[0]);
			bTextObj = o.getAttribute("Comment")[0];
			msg = (bTextObj==null)?"":new String((byte[])bTextObj, "utf-8");
			if (StringUtil.isNullOrEmptyString(msg)) {
				// for Write Again, the child memo might not have been updated, content==NULL
				// use main letter and remove the child memo
				msg = mainText;
				mmMgr.delete(o);
				o = null;
				l.info("   removed empty child memo [" + ids[0] + "]");
			}
			Util.sendMailAsyn(me, from, uidS, null, null, subj, msg, MAILFILE);
			custMailList += "</p>" + uname;
			l.info("   use customized letter [" + ids[0] + "]");
			
			if (o != null) {
				o.setAttribute("CompleteDate", now);
				mmMgr.commit(o);
			}
		}
	}	// END: for each attendee
	
	// done sending, mark mailing timestamp
	mm.setAttribute("CompleteDate", now);
	mmMgr.commit(mm);

	//OmfPresence.setOnline(myUid);


%>


<head>
<title><%=session.getAttribute("app")%> Page</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../forms.jsp" flush="true"/>

<script language="JavaScript">
<!--

function done() {
	location = 'my_memo.jsp';
}

//-->
</script>

</head>

<body bgcolor="#FFFFFF">

<table width="100%" height="100%" border="0" cellspacing="0" cellpadding="0">
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
	<td class='instruction_head'>Letters sent to <%=tnName%> complete</td>
	</tr>

<%
	////////////////
	// list those received the main letter
	out.print("<tr><td colspan='2'><img src='../i/spacer.gif' height='20'/></td></tr>");
	
	out.print("<tr><td></td>");
	out.print("<td><table border='0'>");
	
	out.print("<tr><td><img src='../i/bullet_tri.gif' border='0'/></td>");
	out.print("<td class='plaintext_head'>Main letter sent to:</td></tr>");
	
	// list names one on a row
	out.print("<tr><td></td><td class='plaintext_big'>");
	out.print(mainMailList);
	out.print("</td></tr>");
	
	out.print("</table></td></tr>");
	
	/////////////////
	// list those received the customized letter
	out.print("<tr><td colspan='2'><img src='../i/spacer.gif' height='20'/></td></tr>");
	
	out.print("<tr><td></td>");
	out.print("<td><table border='0'>");
	
	out.print("<tr><td><img src='../i/bullet_tri.gif' border='0'/></td>");
	out.print("<td class='plaintext_head'>Customized letter sent to:</td></tr>");
	
	// list names one on a row
	out.print("<tr><td></td><td class='plaintext_big'>");
	out.print(custMailList);
	out.print("</td></tr>");
	
	out.print("</table></td></tr>");

%>

	
	<tr><td colspan='2'><img src='../i/spacer.gif' height='20'/></td></tr>

	<tr><td></td>
		<td align='center'><button type='button' id='subButton' class='button_medium' onclick='done();'> Done </button></td>
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
