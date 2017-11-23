<%
//
//	Copyright (c) 2005, EGI Technologies, Co.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: memo_search.jsp
//	Author: ECC
//	Date:	04/05/05
//	Description: Search for memos.  Make sure to limit search to only
//				my memo (creator or receipient)
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "util.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.omm.common.*" %>
<%@ page import = "oct.omm.client.*" %>
<%@ page import = "oct.omm.db.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />
<%
	////////////////////////////////////////////////////////
	final int RADIO_NUM		= 4;

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}

	int uid = pstuser.getObjectId();
	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ( (iRole & user.iROLE_ADMIN) > 0 )
		isAdmin = true;

	memoManager mMgr = memoManager.getInstance();
	userManager uMgr = userManager.getInstance();

	SimpleDateFormat df = new SimpleDateFormat ("MM/dd/yy (EEE) hh:mm a");

	// construct the expression
	//String expr = "";
	String expr = "";
	if (!isAdmin)
		expr = "((Creator='" + uid + "') || (Attendee='" + uid + "') || (Alert='" + uid + "'))";
	int exprLen = expr.length();
	PstAbstractObject [] targetObjList = new PstAbstractObject[0];

	int viewCreatorId = -1, viewRecipientId = 0;
	String viewSubject, viewLoc;
	String s;
	String tempExpr;

	// subject
	viewSubject = request.getParameter("subject");
	if (viewSubject == null) viewSubject = "";
	if (viewSubject.length()>0)
	{
		if (expr.length() > 0) expr += " && ";
		expr += "(Name='%" + viewSubject + "%')";
	}

	// creator
	String creator = request.getParameter("creator");
	if (creator!=null && creator.length()>0)
	{
		viewCreatorId = Integer.parseInt(creator);
		if (expr.length() > 0) expr += " && ";
		expr += "(Creator='" + creator + "')";
	}

	// recipient
	String recipient = request.getParameter("recipient");
	if (recipient!=null && recipient.length()>0)
	{
		viewRecipientId = Integer.parseInt(recipient);
		if (expr.length() > 0) expr += " && ";
		expr += "((Attendee='" + recipient + "') || (Alert='" + recipient + "'))";
	}
	if (expr.length() == exprLen) expr = "";		// no condition specified: it is an empty expression

	expr = expr.replaceAll("\\*", "%");
	System.out.println("expr = "+ expr);

	// get the list of memos
	if (expr != null)
	{
		int [] ids = mMgr.findId(pstuser, expr);
		targetObjList = mMgr.get(pstuser, ids);

		Arrays.sort(targetObjList, new Comparator()
		{
			public int compare(Object o1, Object o2)
			{
				try{
				Date d1 = (Date)((memo)o1).getAttribute("CreatedDate")[0];
				Date d2 = (Date)((memo)o2).getAttribute("CreatedDate")[0];
				return (d1.after(d2)?0:1);
				}catch(Exception e){System.out.println("Internal error sorting momo list [memo_search.jsp].");
					return 0;}
			}
		});
	}

	// all users
	PstAbstractObject [] allMember = ((user)pstuser).getAllUsers();

	////////////////////////////////////////////////////////
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html lang="en">

<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="../init.jsp" flush="true"/>

<script language="JavaScript">
<!--

function fo()
{
	Form = document.memoSearch;
	for (i=0;i < Form.length;i++)
	{
		if (Form.elements[i].type != "hidden")
		{
			Form.elements[i].focus();
			break;
		}
	}
}

//-->
</script>


</head>

<title><%=session.getAttribute("app")%></title>
<body onLoad="fo();"  bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" height="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">
		<!-- Main Tables -->
		<table width="100%" border="0" cellspacing="0" cellpadding="0">
		  	<tr>
		    	<td width="100%" valign="top">
					<!-- Top -->
					<jsp:include page="../head.jsp" flush="true"/>
					<!-- End of Top -->
				</td>
			</tr>
			<tr>
	          <td>
	            <table width="780" border="0" cellspacing="0" cellpadding="0">
				  <tr>
	                <td width="26" height="30"><a name="top">&nbsp;</a></td>
	                <td width="754" height="30" align="left" valign="bottom" class="head"><b class="head">
					<b>Find Memo</b>
					</td></tr>
	            </table>
	          </td>
	        </tr>
			<tr>
          		<td width="100%">
					<!-- Navigation Menu -->
					<jsp:include page="../in/prf.jsp" flush="true">
					<jsp:param name="role" value="<%=iRole%>" />
					</jsp:include>
					<!-- End of Navigation Menu -->
				</td>
	        </tr>
			<tr>
          		<td width="100%" valign="top">
					<!-- Navigation SUB-Menu -->
					<table border="0" width="780" height="1" cellspacing="0" cellpadding="0">
						<tr>
							<td width="20" height="1" bgcolor="#FFFFFF"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
							<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
						</tr>
					</table>
					<table border="0" width="780" height="14" cellspacing="0" cellpadding="0">
						<tr>
							<td width="20" height="14" bgcolor="#FFFFFF"><img src="../i/spacer.gif" height="1" border="0"></td>
							<td valign="top" class="BgSubnav">
								<table border="0" cellspacing="0" cellpadding="0">
								<tr class="BgSubnav">
								<td width="40"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
				<!-- My Personal Profile -->
								<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
								<td width="10"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
								<td><a href="../ep/ep1.jsp" class="subnav">My Personal Profile</a></td>
								<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
				<!-- Find Memo -->
								<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
								<td width="7"><img src="../i/spacer.gif" width="7" height="1" border="0"></td>
								<td width="15" height="14"><img src="../i/nav_arrow.gif" width="20" height="14" border="0"></td>
								<td><a href="#" class="subnav"><u>Find Memo</u></a></td>
								<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
				<!-- Distribution List -->
								<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
								<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
								<td><a href="../ep/dl.jsp?backPage=../ep/ep1.jsp" class="subnav">Distribution List</a></td>
								<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>								

<%	if (isAdmin)
	{%>
				<!-- New Employee -->
								<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
								<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
								<td><a href="#" onclick="return demo_alert();" class="subnav">New Employee</a></td>
								<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
<%	}%>
								</tr>
								</table>
							</td>
						</tr>
					</table>
					<table border="0" width="780" height="1" cellspacing="0" cellpadding="0">
						<tr>
							<td width="20" height="1" bgcolor="#FFFFFF"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
							<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
						</tr>
					</table>
					<!-- End of Navigation SUB-Menu -->
				</td>
	        </tr>
		</table>
		<!-- Content Table -->
		 <table width="770" border="0" cellspacing="0" cellpadding="0">
			<tr><td colspan="2">&nbsp;</td></tr>
			<tr>
				<td width="26"><img src="../i/spacer.gif" width="5" border="0"></td>
				<td width="750">

<form name="memoSearch" action="memo_search.jsp" method="post" >
	<table width="700" cellpadding="0" cellspacing="0" border="0">

<!-- Subject -->
	<tr>
	<td width="5">&nbsp;</td>
		<td width="120" class="plaintext_blue">Subject:</td>
		<td>
			<input type='text' name='subject' size='60' value='<%=viewSubject%>'>
		</td>
	</tr>

<!-- Creator -->
	<tr>
	<td width="5">&nbsp;</td>
	<td align="left" valign="middle" class="plaintext_blue">From:</td>
	<td>
			<select name="creator" class="formtext">
			<option value=""> - - Select - - </option>
<%
		out.print("<option value='0'");
		if (viewCreatorId == 0) out.print(" selected");
		out.print(">SYSTEM</option>");

		int oid;
		for(int i=0; i < allMember.length; i++)
		{
			if (allMember[i] == null) continue;
			oid = allMember[i].getObjectId();
			String firstEmpName = (String)allMember[i].getAttribute("FirstName")[0];
			String lastEmpName = (String)allMember[i].getAttribute("LastName")[0];
			out.print("<option value='" + oid + "' ");
			if (oid == viewCreatorId) out.print("selected");
			out.print(">" + firstEmpName + " " + lastEmpName + "</option>");
		}
%>

			</select>

	</td>
	</tr>

<!-- recipient -->
	<tr>
	<td width="5">&nbsp;</td>
	<td align="left" valign="middle" class="plaintext_blue">To:</td>
	<td>
			<select name="recipient" class="formtext">
			<option value=""> - - Select - - </option>
<%
		for(int i=0; i < allMember.length; i++)
		{
			if (allMember[i] == null) continue;
			oid = allMember[i].getObjectId();
			String firstEmpName = (String)allMember[i].getAttribute("FirstName")[0];
			String lastEmpName = (String)allMember[i].getAttribute("LastName")[0];
			out.print("<option value='" + oid + "' ");
			if (oid == viewRecipientId) out.print("selected");
			out.print(">" + firstEmpName + " " + lastEmpName + "</option>");
		}
%>

			</select>

	</td>
	</tr>


	<tr><td colspan="3">&nbsp;</td></tr>

	<tr>
	<td colspan="3" align="center">
		<a href="javascript:document.memoSearch.submit()" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('SubmitButton','','../i/sbtn.gif',1)">
			<input type="image" src="../i/sbtf.gif" name="SubmitButton"></a>
		<a href="mtg_search.jsp" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('Reset','','../i/resn.gif',1)"><img src="../i/resf.gif" border="0" name="Reset"></a></td>
	</td>
	</tr>

	</table>
</form>

<!-- *************************   Display result Headers   ************************* -->

<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
<td>
	<table width="100%" border='0' cellpadding="0" cellspacing="0">
	<tr>
	<td bgcolor="#EBECED" height="3"><img src="../i/spacer.gif" width="1" height="3" border="0"></td>
	</tr>
	</table>
	<table width="100%" border="0" cellspacing="0" cellpadding="0">
	<tr>
	<td colspan="11" height="2" bgcolor="#336699"><img src="../i/spacer.gif" width="2" height="2"></td>
	</tr>
	<tr>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="90" bgcolor="#6699cc" class="td_header" align="center"><strong>Sent</strong></td>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="50" bgcolor="#6699cc" class="td_header" align="center"><strong>From</strong></td>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="230" bgcolor="#6699cc" class="td_header"><strong>&nbsp;Subject</strong></td>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="200" bgcolor="#6699cc" class="td_header"><strong>To</strong></td>
	</tr>


<!-- list of memos -->
<%

try {
	String bgcolor="";
	boolean even = false;

	String creatorIdS, dot, fName;
	user empObj = null, uObj;
	String lastCreator = "";

	String status, subject, location;
	Object [] recipientA;		// those who had received the memo
	Object [] attendeeA;		// those who had acknowledged the memo

	Date sendDate, endDate, dt;

	for(int i = 0; i < targetObjList.length; i++)
	{	// a list of memo satisfied the search expr
		memo mObj = (memo)targetObjList[i];

		subject		= (String)mObj.getAttribute("Name")[0];
		if (subject.length() <= 0)
			subject = "None";
		sendDate	= (Date)mObj.getAttribute("CreatedDate")[0];
		creatorIdS	= (String)mObj.getAttribute("Creator")[0];
		recipientA	= mObj.getAttribute("Alert");
		attendeeA	= mObj.getAttribute("Attendee");

		for (int m=0; m<attendeeA.length; m++)
		{
			if (attendeeA[m] == null) break;
			for (int n=0; n<recipientA.length; n++)
			{
				s = (String)recipientA[n];
				if (s == null) break;
				if (s.equals((String)attendeeA[m]))
					recipientA[n] = "0";	// remove repeated id
			}
		}

		if (even)
			bgcolor = "bgcolor='#EEEEEE'";
		else
			bgcolor = "bgcolor='#ffffff'";
		even = !even;
		out.print("<tr " + bgcolor + ">");

		// sendDate
		out.print("<td>&nbsp;</td>");
		out.print("<td class='listtext_small' width='90' align='center' valign='top'>");
		out.print(df.format(sendDate));
		out.println("</td>");

		// From
		boolean isSystem = false;
		out.print("<td colspan='3' class='plaintext' width='50' align='center' valign='top'>");
		if (creatorIdS != null)
		{
			// ECC: need to optimize this in the near future
			if (creatorIdS.equals("0"))
			{
				// send by System
				out.print("SYSTEM");
				isSystem = true;
			}
			else
			{
				if (!creatorIdS.equals(lastCreator))
					empObj = (user)uMgr.get(pstuser,Integer.parseInt(creatorIdS));
				uid = empObj.getObjectId();
				lastCreator = creatorIdS;
				out.print("<a class='listlink' href='../ep/ep1.jsp?uid=" + uid + "'>");
				out.print((String)empObj.getAttribute("FirstName")[0]);
				out.print("</a>");
			}
		}
		out.println("</td>");

		// Subject
		out.print("<td colspan='2'>&nbsp;</td>");
		out.print("<td class='listtext' width='230' valign='top'>");
		out.print("<a href='../blog/seealert.jsp?memoId=" + mObj.getObjectId() + "&backPage=memo_search.jsp'>");
		if (isSystem) out.print("<font color='#aa0000'>" +subject+ "</font>");
		else out.print(subject);
		out.println("</a></td>");

		// recipients
		out.print("<td colspan='2'>&nbsp;</td>");
		out.print("<td class='listtext' valign='top'>");

		boolean bComma = false;
		for (int j=0; j<attendeeA.length; j++)
		{
			s = (String)attendeeA[j];
			if (s == null) break;
			if (!bComma) bComma = true;

			try{uObj = (user)uMgr.get(pstuser,Integer.parseInt(s));}
			catch (PmpException e) {continue;}
			fName = (String)uObj.getAttribute("FirstName")[0];
			if (fName == null) continue;
			out.print("<a class='listlink' href='../ep/ep1.jsp?uid=" + s + "'>");
			out.print(fName);
			out.print("</a>");
			if (j < attendeeA.length-1) out.print(", ");
		}

		for (int j=0; j<recipientA.length; j++)
		{
			s = (String)recipientA[j];
			if (s == null) break;
			else if (s.equals("0")) continue;
			if (bComma) out.print(", ");
			bComma = false;

			try{uObj = (user)uMgr.get(pstuser,Integer.parseInt(s));}
			catch (PmpException e) {continue;}
			fName = (String)uObj.getAttribute("FirstName")[0];
			if (fName == null) continue;
			out.print("<a class='listlink' href='../ep/ep1.jsp?uid=" + s + "'>");
			out.print(fName);
			out.print("</a>");
			if (j < recipientA.length-1) out.print(", ");
		}
		out.println("</td>");

		out.println("</tr>");
		out.println("<tr " + bgcolor + ">" + "<td colspan='11'><img src='../i/spacer.gif' width='2' height='2'></td></tr>");
	}

} catch (Exception e)
{
	response.sendRedirect("../out.jsp?msg=Internal error in displaying memo list (memo_search.jsp).  Please contact administrator.");
	return;
}
%>
	</table>

		</td>
		</tr>
		<tr><td colspan="2">&nbsp;</td></tr>
	</table>
<!-- END result LIST -->


		<!-- End of Content Table -->
		<!-- End of Main Tables -->
	</td>
</tr>
</table>
</td>
</tr>

<tr>
	<td>
		<!-- Footer -->
		<jsp:include page="../foot.jsp" flush="true"/>
		<!-- End of Footer -->
	</td>
</tr>
</table>
</body>
</html>
