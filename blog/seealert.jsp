<%
////////////////////////////////////////////////////
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	seealert.jsp
//	Author:	ECC
//	Date:	03/22/04
//	Description:
//		View the Memo message.
//	Modification:
//		@040405ECC	Alert becomes MEMO.  We need to keep track
//					of who has attended to the memo.
//
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">
    <head>
        <meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">

<title>
	<%=session.getAttribute("app")%> Memo Message
</title>

</head>

<%
	//String alertText = request.getParameter("text");
	//alertText = alertText.replace('{', '<');		// strip HTML tag
	//alertText = alertText.replace('}', '>');		// strip HTML tag

	final int RADIO_NUM = 5;
	final int MAX_LINES = 4;

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	String backPage = request.getParameter("backPage");
	String memoIdS = request.getParameter("memoId");
	boolean bShowAllRecipient = (request.getParameter("showAll") != null);

	boolean bShowComment = false;
	String s = request.getParameter("show");
	if (s!=null && s.equals("true"))
		bShowComment = true;

	String backPage2 = "seealert.jsp?memoId=" +memoIdS+ "&show=" +s+ "&backPage=" + backPage;
	backPage2 = backPage2.replaceAll("&", ":");

	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ( (iRole & user.iROLE_ADMIN) > 0 )
			isAdmin = true;

	String uidS = String.valueOf(pstuser.getObjectId());

	userManager uMgr = userManager.getInstance();
	memoManager mMgr = memoManager.getInstance();

	memo memoObj = (memo)mMgr.get(pstuser, Integer.parseInt(memoIdS));
	String tidS = (String)memoObj.getAttribute("TaskID")[0];	// TaskID stores the townId

	String subject = (String)memoObj.getAttribute("Name")[0];
	if (subject == null) subject = "";
	user u;
	String sender = null;
	s = (String)memoObj.getAttribute("Creator")[0];
	int senderId = Integer.parseInt(s);
	if (senderId == 0)
		sender = "System";
	else
	{
		u = (user)uMgr.get(pstuser, senderId);
		//sender = (String)u.getAttribute("FirstName")[0] + " " + (String)u.getAttribute("LastName")[0];
		sender = (String)u.getAttribute("FirstName")[0];
	}

	Object [] receive = memoObj.getAttribute("Alert");
	Object [] attended = memoObj.getAttribute("Attendee");

	boolean found = false;
	for (int i=0; i<receive.length; i++)
	{
		s = (String)receive[i];
		if (s == null) break;
		if (s.equals(uidS))
			receive[i] = "0";
		for (int j=0; j<attended.length; j++)
		{
			if (attended[j] == null) break;
			if (s.equals((String)attended[j]))
				receive[i] = "0";	// remove repeated id
			if (uidS.equals((String)attended[j]))
				found = true;		// I am already on the attendee list
		}
	}

	if (!found)
	{
		memoObj.appendAttribute("Attendee", uidS);		// I just open it the 1st time (attend to it)
		mMgr.commit(memoObj);
		attended = memoObj.getAttribute("Attendee");		// refresh the list
	}

	SimpleDateFormat df = new SimpleDateFormat ("MM/dd/yy (EEE) hh:mm a");
	String sendDate = df.format((Date)memoObj.getAttribute("CreatedDate")[0]);

	Object bTextObj = memoObj.getAttribute("Comment")[0];
	String alertText = (bTextObj==null)?"no message text":new String((byte[])bTextObj);

%>

<jsp:include page="../init.jsp" flush="true"/>

<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="715" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true"/>

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

<!--
	<table><tr><td width="450">

	<table><tr><td><b class="head">
	View Memo
	</b></td></tr></table>

	</td></tr></table>
-->

<!-- table for header -->
<table width="100%" border="0" cellspacing="0" cellpadding="0">

<!-- Left table -->
<tr><td width="600">
<table width="100%" border="0" cellspacing="0" cellpadding="0">

<!-- From -->
<tr>
	<td width="20" ><img src="../i/spacer.gif" border="0" width="20" height="1"></td>
	<td width="100" class="plaintext">From:</td>
	<td class="plaintext">
<%	if (senderId > 0)
		out.print("<a href='../ep/ep1.jsp?uid=" +senderId+ "' class='listlink'>" +sender+ "</a>");
	else
		out.print(sender);
%>
	</td>
</tr>
<tr><td copsan="3"><img src="../i/spacer.gif" border="0" width="15" height="5"></td></tr>

<!-- To -->
<tr>
	<td width="20" ><img src="../i/spacer.gif" border="0" width="20" height="1"></td>
	<td width="100" class="plaintext" valign="top">To:</td>
	<td>
		<table border="0" cellspacing="0" cellpadding="0">
<%

	int num = 0, id;
	String uname;

	// fist list all who has read it
	int lineCt = 0;
	for(int i = 0; i < attended.length; i++)
	{
		if (!bShowAllRecipient && lineCt>=MAX_LINES) break;
		s = (String)attended[i];
		if (s == null) break;

		id = Integer.parseInt(s);
		u = (user)uMgr.get(pstuser, id);
		uname = (String)u.getAttribute("FirstName")[0];
		if (uname == null) continue;
		//uname = uname + " " + (String)u.getAttribute("LastName")[0];

		if (num%RADIO_NUM == 0) out.print("<tr>");
		out.print("<td width='120' class='plaintext'><img src='../i/check.gif' border='0' width=16' height='16'>");
		out.print("<a href='../ep/ep1.jsp?uid=" + id + "' class='listlink'>");
		out.println(uname + "</td>");
		if (num%RADIO_NUM == RADIO_NUM-1) {out.print("</tr>"); lineCt++;}
		num++;
	}

	// now list the receive list (not attended yet)
	for(int i = 0; i < receive.length; i++)
	{
		if (!bShowAllRecipient && lineCt>=MAX_LINES) break;
		s = (String)receive[i];
		if (s == null) break;
		else if (s.equals("0")) continue;

		id = Integer.parseInt(s);
		u = (user)uMgr.get(pstuser, id);
		uname = (String)u.getAttribute("FirstName")[0];
		if (uname == null) continue;
		//uname = uname + " " + (String)u.getAttribute("LastName")[0];

		if (num%RADIO_NUM == 0) out.print("<tr>");
		out.print("<td width='120' class='plaintext'><img src='../i/spacer.gif' border='0' width=16' height='16'>");
		out.print("<a href='../ep/ep1.jsp?uid=" + id + "' class='listlink'>");
		out.println(uname + "</td>");
		if (num%RADIO_NUM == RADIO_NUM-1) {out.print("</tr>"); lineCt++;}
		num++;
	}
	if (num%RADIO_NUM != 0) out.print("</tr>");
	out.print("</table></td></tr>");

	if (lineCt>=MAX_LINES && !bShowAllRecipient)
	{
		out.print("<tr><td colspan='2'></td>");
		out.print("<td width='450' align='right'><a class='listlink' href='seealert.jsp?memoId=" + memoIdS
			+ "&backPage=" + backPage + "&showAll=true'>... <b>see all recipients</b></a></td>");
		out.print("</tr>");
	}
	if (bShowAllRecipient)
	{
		out.print("<tr><td colspan='2'></td>");
		out.print("<td width='450' align='right'><a class='listlink' href='seealert.jsp?memoId=" + memoIdS
			+ "&backPage=" + backPage + "'>... <b>close recipients list</b></a></td>");
		out.print("</tr>");
	}
%>

<tr><td colspan="3"><img src="../i/spacer.gif" border="0" width="15" height="5"></td></tr>

<!-- Subject -->
<tr>
	<td></td>
	<td width="100" class="plaintext">Subject:</td>
	<td class="plaintext">
<%	if (senderId == 0)
		out.print("<font color='#aa0000'>" + subject + "</font>");
	else
		out.print(subject);
%>
	</td>
</tr>
</table>
</td>

<!-- Right table -->
<td align="right">
<table width="100%" border="0" cellspacing="0" cellpadding="0" align="right">
<tr>
	<td style="font-family: Verdana, Arial, Helvetica, Verdana, sans-serif; font-weight: bold; font-size: 60px; line-height: 63px; color: #cccccc" valign="top">
		MEMO&nbsp;
	</td>
</tr>
<tr>
	<td class="plaintext">&nbsp;&nbsp;Sent: <%=sendDate%></td>
</tr>
</table>
</td>
</tr>

</table>
<!-- end table for header -->

	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- CONTENT -->
<table width="100%" border="0" cellspacing="0" cellpadding="0">

<tr>
	<td width="20"><img src="../i/spacer.gif" border="0" width="15" height="1"></td>
	<td width="150">&nbsp;</td>
	<td width="600">&nbsp;</td>
</tr>

<tr><td copsan="3"><img src="../i/spacer.gif" border="0" width="15" height="10"></td></tr>

<tr>
	<td></td>
	<td colspan='2' class="plaintext_big"><%=alertText%><td>
	</td>
</tr>

<tr><td copsan="3"><img src="../i/spacer.gif" border="0" width="15" height="10"></td></tr>

<!-- buttons -->
<tr><td colspan="3">
<table width="90%" border="0" cellspacing="0" cellpadding="0">
<tr>
<td>&nbsp;</td>
<%
	int [] ids = mMgr.findId(pstuser, "ParentID='" + memoIdS + "'");
	int comNum = ids.length;

	if (isAdmin)
	{%>
	<td align="right">
		<a class="blog_small" href="../blog/post_delalert.jsp?memoId=<%=memoIdS%>"
		onClick="return confirm('Are you sure you want to delete this Memo?')">
		DEL</a>
	</td>
<%	}%>

	<td width="100" align="right">
		<a class="blog_small" href="seealert.jsp?memoId=<%=memoIdS%>&show=<%=!bShowComment%>&backPage=<%=backPage%>">
		COMMENT (<%=comNum%>)</a>
	</td>

	<td width="60" align="right">
		<a class="blog_small" href="addalert.jsp?type=memo&id=<%=memoIdS%>&backPage=<%=backPage2%>">
		EMAIL</a>
	</td>

	<td width="60" align="right">
		<a class="blog_small" href="<%=backPage%>">
		BACK</a>
	</td>
</tr>
</table>
</td>
</tr>

<tr>
	<td colspan="3" bgcolor="#bbbbbb" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
</tr>
<tr><td colspan="3"><img src="../i/spacer.gif" width="1" height="10"></td></tr>

<%	if (bShowComment)
{
	Date createDate;
	PstAbstractObject [] mList = mMgr.get(pstuser, ids);

	// sort the comments by create date.  Display latest postings first.
	Arrays.sort(mList, new Comparator()
	{
		public int compare(Object o1, Object o2)
		{
			try{
			Date d2 = (Date)((result)o2).getAttribute("CreatedDate")[0];
			Date d1 = (Date)((result)o1).getAttribute("CreatedDate")[0];
			return d2.compareTo(d1);
			}catch(Exception e){
				return 0;}
		}
	});

	for (int i=0; i<comNum; i++)
	{
		memoObj = (memo)mList[i];
		createDate = (Date)memoObj.getAttribute("CreatedDate")[0];
		s = (String)memoObj.getAttribute("Creator")[0];
		u = (user)uMgr.get(pstuser, Integer.parseInt(s));
		uname = (String)u.getAttribute("LastName")[0];
		uname =  u.getAttribute("FirstName")[0] + " " + (uname==null?"":uname);

		bTextObj = memoObj.getAttribute("Comment")[0];
		alertText = (bTextObj==null)?"":new String((byte[])bTextObj);
%>

<!-- DATE -->
	<tr>
		<td></td>
		<td colspan="2" height="40" class="plaintext">
		<b><%=uname.toUpperCase()%></b> wrote on <b><%=df.format(createDate)%></b>:
		</td>
	</tr>

<!-- TEXT -->
	<tr>
		<td></td>
		<td colspan="2" class="blog_text">
		<%=alertText%><p></p>
		</td>
	</tr>

	<tr><td colspan="3">
	<table border="0" width="100%" height="1" cellspacing="0" cellpadding="0">
		<tr>
			<td bgcolor="#bbbbbb" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
		</tr>
	</table>
	</td></tr>

	<tr><td colspan="3"><img src="../i/spacer.gif" width="1" height="10"></td></tr>
<%	}	// end for loop for all comments
}		// end if bShowComment
%>

<tr><td colspan="3"><img src="../i/spacer.gif" width="1" height="10"></td></tr>

<!-- add comments -->
<form name="AddCommentForm" action="post_addalert.jsp" method="post">
<input type="hidden" name="parentId" value="<%=memoIdS%>">
<input type="hidden" name="backPage" value="<%=backPage%>">
<tr>
	<td></td>
	<td colspan="2">
	<table width="100%" border="0" cellspacing="0" cellpadding="0">
	<tr>
		<td class="plaintext_blue">Add Comment:</td>
	</tr>
	<tr>
		<td>
			<textarea name="MsgText" cols="80" rows="8"></textarea>
		</td>
	<tr>
		<td align="center"><br>
			<a href="<%=backPage%>"  onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('Cancel','','../i/cnln.gif',1)"><img src="../i/cnlf.gif" width="100" height="23" border="0" name="Cancel"></a>
			<a href="javascript:document.AddCommentForm.submit()"  onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('SubmitButton','','../i/sbtn.gif',1)"><img src="../i/sbtf.gif" border="0" name="SubmitButton"></a>
		</td>
	</tr>
	</table>
	</td>
</tr>
</form>
<!-- End of add comments -->

</table>


	</td>
</tr>

<tr><td>&nbsp;</td><tr>

<!-- BEGIN FOOTER TABLE -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->

<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

