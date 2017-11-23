<%@ page contentType="text/html; charset=utf-8"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2016, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: 	memo1.jsp
//	Author: ECC
//	Date:	02/10/16
//	Description: Entry point to write a letter to a circle.
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

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	String tidS = request.getParameter("tid");
	String noSession = "../out.jsp?go=memo/memo_1.jsp?tid=" + tidS;
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

	String HOST = Util.getPropKey("pst", "PRM_HOST");
	int iRole = ((Integer)session.getAttribute("role")).intValue();

	boolean isAdmin = ((iRole & user.iROLE_ADMIN) > 0);

	// to check if session is CR, OMF, or PRM
	String subCat = "MyLetter";

	userManager uMgr = userManager.getInstance();
	userinfoManager uiMgr = userinfoManager.getInstance();
	townManager tnMgr = townManager.getInstance();
	
	town tnObj = (town) tnMgr.get(me, tidS);
	String tnName = tnObj.getStringAttribute("Name");
	
	// this call might be back-page call, so pick up the previous info if they exist
	String mmidS = request.getParameter("mmid");
	if (StringUtil.isNullOrEmptyString(mmidS)) mmidS = "";
	
	String memNamesS = request.getParameter("memNamesStr");
	if (StringUtil.isNullOrEmptyString(memNamesS)) memNamesS = "";
	
	String mmidAgainS = request.getParameter("mmidAgain");
	if (StringUtil.isNullOrEmptyString(mmidAgainS)) mmidAgainS = "";

	
	SimpleDateFormat df = new SimpleDateFormat("MMM dd, yyyy");
	userinfo.setTimeZone(me, df);
	String todayS = df.format(new Date());

	String s;

	int myUid = me.getObjectId();
	String myUidS = String.valueOf(myUid);

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

<%	if (memNamesS == "") { %>

window.onload = function()
{
	document.getElementById("checkAll").checked = true;
	toggleSelectAll(document.getElementById("checkAll"));
}

<%	}%>


function toggleSelectAll(source) {
	var checkboxes = document.getElementsByName('memNames');

	for (i=0, n=checkboxes.length; i<n; i++) {
		checkboxes[i].checked = source.checked;
	}
}

function goNext() {
	// must check some members to send
	var checkboxes = document.getElementsByName('memNames');

	var bFound = false;
	for (i=0, n=checkboxes.length; i<n; i++) {
		if (checkboxes[i].checked) {
			bFound = true;
			break;
		}
	}
	
	if (!bFound) {
		alert("Please select some recipients");
		return false;
	}

	document.getElementById("subButton").disabled = true;
	memo_s1.submit();
}

//-->
</script>

</head>

<body bgcolor="#FFFFFF">

<form name='memo_s1' action='memo_2.jsp' method='post'>
<input type='hidden' name='caller' value='memo_1' />
<input type='hidden' name='tid' value='<%=tidS%>' />
<input type='hidden' name='customize' value='true' />
<input type='hidden' name='mmid' value='<%=mmidS%>' />
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
	<td class='instruction_head'>Step 1: Select members to send</td>
	</tr>

<!-- select circle members -->
	<tr><td colspan='2'><img src='../i/spacer.gif' height='10'/></td></tr>

	<tr><td></td>
	<td><table border='0'>
	<tr>
		<td><input type="checkbox" id="checkAll" onclick="toggleSelectAll(this)" /></td>
		<td class='plaintext_big'><b>Select all</b></td>
	</tr>
	
	<tr><td colspan='2'><img src='../i/spacer.gif' height='5'/></td></tr>


<%
	// list all circle members
	user u;
	String fullname, uidS, email;
	int [] ids = uMgr.findId(me, "Towns=" + tidS);;
	
	PstAbstractObject [] uArr = uMgr.get(me, ids);
	Util.sortUserArray(uArr, true);

	for (int i=0; i<uArr.length; i++) {
		u = (user) uArr[i];
		fullname = u.getFullName();
		uidS = String.valueOf(u.getObjectId());
		email = u.getStringAttribute("Email");

		out.print("<tr><td class='plaintext'>");
		out.print("<input type='checkbox' name='memNames' value='" + uidS + "'");
		if (memNamesS.contains(uidS)) out.print(" checked");
		out.print("/></td>");
		out.print("<td class='plaintext_big'>" + fullname + " <span style='color:#9999AA;'>(" + email + ")</span></td></tr>");
	}

%>

	</table>
	</td>
	</tr>

	
	<tr><td colspan='2'><img src='../i/spacer.gif' height='20'/></td></tr>

	<tr><td></td>
		<td align='center'><button type='button' id='subButton' class='button_medium' onclick='goNext();'> Next </button></td>
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
