<%@ page contentType="text/html; charset=utf-8"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2016, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: 	my_memo.jsp
//	Author: ECC
//	Date:	02/10/16
//	Description: Display memo I sent and received.
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

	String noSession = "../out.jsp?go=ep/ep_omf.jsp";
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
	memoManager mmMgr = memoManager.getInstance();
	
	
	SimpleDateFormat df = new SimpleDateFormat("MMM dd, yyyy hh:mm a");
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

function openMain(mmid, bJustRead)
{
	my_memo.mmid.value = "" + mmid;
	my_memo.readRecv.value = bJustRead;
	my_memo.submit();				// open memo_3.jsp
}


function goHome()
{
	location = '../ep/ep_omf.jsp';
}

//-->
</script>

</head>

<body bgcolor="#FFFFFF">
<form name='my_memo' action='memo_3.jsp' method='post'>
<input type='hidden' name='caller' value='my_memo' />
<input type='hidden' name='mmid' value='' />
<input type='hidden' name='readRecv' value='' />


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
				My Letter
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
	<td></td>
	</tr>
	

<!-- list letters I wrote -->
<%

	out.print("<tr><td colspan='3'><img src='../i/spacer.gif' height='20'/></td></tr>");

	out.print("<tr><td></td>");
	out.print("<td width='20'><img src='../i/bullet_tri.gif' border='0'/></td>");
	out.print("<td class='plaintext_head'>Letters I wrote</td>");
	out.print("</tr>");

	out.print("<tr><td colspan='3'><img src='../i/spacer.gif' height='10'/></td></tr>");
	
	out.print("<tr><td colspan='2'></td>");
	out.print("<td><table border='0' width='100%'><tr>");
	
	// memo created by me
	int [] ids = mmMgr.findId(me, "Type='" + memo.M_LETTER
					+ "' && Creator='" + myUidS + "' && ParentID=null");
	PstAbstractObject [] oArr = mmMgr.get(me, ids);
	
	Util.sortDate(oArr, "CompleteDate", true);
	
	PstAbstractObject mm;
	Date dt;
	String dtSentS, title;
	Object [] attArr;
	String greyBeg, greyEnd, notSentStr="";

	for (int i=0; i<oArr.length; i++) {
		mm = oArr[i];

		dt = (Date) mm.getAttribute("CompleteDate")[0];
		if (dt == null) {
			dt = (Date) mm.getAttribute("CreatedDate")[0];
			greyBeg = "<font color='#aa0000'>";
			greyEnd = "</font>";
			notSentStr = "&nbsp;<span style='color:#777777'>(not sent)</span>";
		}
		else {
			greyBeg = greyEnd = "";
		}
		dtSentS = df.format(dt);
		
		title = mm.getStringAttribute("Name");
		attArr = mm.getAttribute("Attendee");
		
		out.print("<td class='plaintext_big' width='250'>" + greyBeg + dtSentS + greyEnd + "</td>");
		out.print("<td class='plaintext_big'>");
		out.print("<a href='javascript:openMain(" + mm.getObjectId() + ");'>");
		out.print(title + "</a>" + notSentStr + "</td>");
		out.print("<td class='plaintext_big' width='150'>to " + attArr.length + " people</td>");
		out.print("</tr>");
	}
	
	out.print("</table></td></tr>");
%>


<!-- list letters I received -->
<%

	out.print("<tr><td colspan='3'><img src='../i/spacer.gif' height='20'/></td></tr>");
	
	out.print("<tr><td></td>");
	out.print("<td width='20'><img src='../i/bullet_tri.gif' border='0'/></td>");
	out.print("<td class='plaintext_head'>Letters I received</td>");
	out.print("</tr>");
	
	out.print("<tr><td colspan='3'><img src='../i/spacer.gif' height='10'/></td></tr>");
	
	out.print("<tr><td colspan='2'></td>");
	out.print("<td><table border='0' width='100%'><tr>");

	// checkbox to select customize message
	ids = mmMgr.findId(me, "Type='" + memo.M_LETTER
					+ "' && Attendee='" + myUidS + "'");	// all memo's that I am attendee
	oArr = mmMgr.get(me, ids);
	
	Util.sortDate(oArr, "CompleteDate", true);
	
	user u;
	for (int i=0; i<oArr.length; i++) {
		mm = oArr[i];
	
		dt = (Date) mm.getAttribute("CompleteDate")[0];
		if (dt == null)
			continue;				// show only those that are sent
		dtSentS = df.format(dt);
		
		title = mm.getStringAttribute("Name");
		attArr = mm.getAttribute("Attendee");
		
		out.print("<td class='plaintext_big' width='250'>" + dtSentS + "</td>");
		out.print("<td class='plaintext_big'>");
		out.print("<a href='javascript:openMain(" + mm.getObjectId() + ", true);'>");
		out.print(title + "</a></td>");
		
		// sender
		u = (user) uMgr.get(me, Integer.parseInt(mm.getStringAttribute("Creator")));
		out.print("<td class='plaintext_big' width='150'><a href='../ep/ep1.jsp?uid=" + u.getObjectId() + "'>"
			+ u.getFullName() + "</a></td>");
		out.print("</tr>");
	}

	out.print("</table></td></tr>");
%>
	
	<tr><td colspan='3'><img src='../i/spacer.gif' height='20'/></td></tr>

	<tr><td colspan='2'></td>
		<td align='center'><button type='button' id='subButton' class='button_medium' onclick='goHome();'> Done </button></td>
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
