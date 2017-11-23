<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2005, EGI Technologies, Co.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: mtg_search.jsp
//	Author: ECC
//	Date:	03/02/05
//	Description: Search for meetings.
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
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	////////////////////////////////////////////////////////
	final int RADIO_NUM		= 4;

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}

	int uid = pstuser.getObjectId();
	String myIdS = String.valueOf(uid);

	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ( (iRole & user.iROLE_ADMIN) > 0 )
		isAdmin = true;
	
	String app = (String)session.getAttribute("app");
	if (app != null && app.equals("OMF")) app = "MeetWE";

	meetingManager mMgr = meetingManager.getInstance();
	userManager uMgr = userManager.getInstance();

	SimpleDateFormat df = new SimpleDateFormat ("MM/dd/yy (EEE) hh:mm a");

	// construct the expression
	String expr = "";
	PstAbstractObject [] mtgArr = new PstAbstractObject[0];

	int viewOwnerId = 0, viewAttendeeId = 0;
	String viewSubject, viewLoc;
	String s;
	String tempExpr;

	// subject
	viewSubject = request.getParameter("subject");
	if (viewSubject == null) viewSubject = "";
	if (viewSubject.length()>0)
	{
		if (expr.length() > 0) expr += " && ";
		expr += "(Subject='%" + viewSubject + "%')";
	}

	// location
	viewLoc = request.getParameter("location");
	if (viewLoc == null) viewLoc = "";
	if (viewLoc.length()>0)
	{
		if (expr.length() > 0) expr += " && ";
		expr += "(Location='%" + viewLoc + "%')";
	}

	// owner
	String owner = request.getParameter("owner");
	if (owner!=null && owner.length()>0)
	{
		viewOwnerId = Integer.parseInt(owner);
		if (expr.length() > 0) expr += " && ";
		expr += "(Owner='" + owner + "')";
	}

	// attendee
	String attendee = request.getParameter("attendee");
	if (attendee!=null && attendee.length()>0)
	{
		viewAttendeeId = Integer.parseInt(attendee);
		if (expr.length() > 0) expr += " && ";
		expr += "(Attendee='" + attendee + "%')";
	}

	// status
	tempExpr = "";
	for (int i=0; i < meeting.STATE_ARRAY.length; i++)
	{
		s = request.getParameter(meeting.STATE_ARRAY[i]);
		if (s!=null && s.length()>0)
		{
			if (tempExpr.length() > 0) tempExpr += " || ";
			tempExpr += "Status='" + meeting.STATE_ARRAY[i] + "'";
		}
	}
	if (tempExpr.length() > 0)
	{
		tempExpr = "(" + tempExpr + ")";
		if (expr.length() > 0) expr += " && ";
		expr += tempExpr;
	}
	expr = expr.replaceAll("\\*", "%");
	//System.out.println("expr = "+ expr);

	// get the list of meetings
	if (expr != null)
	{
		int [] ids = mMgr.findId(pstuser, expr);
		mtgArr = mMgr.get(pstuser, ids);

		Arrays.sort(mtgArr, new Comparator <Object> ()
		{
			public int compare(Object o1, Object o2)
			{
				try{
				Date d1 = (Date)((meeting)o1).getAttribute("StartDate")[0];
				Date d2 = (Date)((meeting)o2).getAttribute("StartDate")[0];
				return (d2.before(d1)?-1:1);
				}catch(Exception e){System.out.println("Internal error sorting meeting list [mtg_search.jsp].");
					return 0;}
			}
		});
	}

	// filter the meetings (only show if I am owner or attendee)
	s = Util.getPropKey("pst", "MTG_FILTER_SEARCH");
	if (!isAdmin && s!=null && s.equalsIgnoreCase("true") )
	{
		boolean found;
		for (int i=0; i<mtgArr.length; i++)
		{
			found = false;
			meeting m = (meeting)mtgArr[i];
			if (myIdS.equals(m.getAttribute("Owner")))
				continue;					// found

			Object [] oArr = m.getAttribute("Attendee");
			for (int j=0; j<oArr.length; j++)
			{
				s = (String)oArr[j];
				if (s == null) break;		// no attendee
				if (s.startsWith(myIdS))
				{
					found = true;
					break;					// found
				}
			}
			if (!found)
				mtgArr[i] = null;			// don't show this meeting
		}
	}

	// all users
	PstAbstractObject [] allMember = ((user)pstuser).getAllUsers();

	////////////////////////////////////////////////////////
%>


<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="../init.jsp" flush="true"/>

<script language="JavaScript">
<!--

function fo()
{
	Form = document.mtgSearch;
	for (i=0;i < Form.length;i++)
	{
		if (Form.elements[i].type != "hidden")
		{
			Form.elements[i].focus();
			break;
		}
	}
}

function resetForm()
{
	location = "mtg_search.jsp";
}
//-->
</script>

<style type="text/css">
.plaintext_blue {line-height:30px;}
</style>

</head>

<title><%=app%></title>
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
	            <table width="100%" border="0" cellspacing="0" cellpadding="0">
				  <tr>
					<td width="26" height="30"><a name="top">&nbsp;</a></td>
                	<td height="30" align="left" valign="bottom" class="head">
                	<b>Search Meeting</b>
					</td></tr>
	            </table>
	          </td>
	        </tr>
</table>

<table width='90%' border='0' cellspacing='0' cellpadding='0'>
			<tr>
          		<td width="100%">
<!-- Navigation Menu -->
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Event" />
				<jsp:param name="subCat" value="SearchMeeting" />
				<jsp:param name="role" value="<%=iRole%>" />
			</jsp:include>
<!-- End of Navigation Menu -->
				</td>
	        </tr>
		</table>
		<!-- Content Table -->

		 <table width="90%" border="0" cellspacing="0" cellpadding="0">


			<tr><td colspan="2">&nbsp;</td></tr>
			<tr>
				<td width="20"><img src="../i/spacer.gif" width="5" border="0"></td>
				<td>


<form name="mtgSearch" action="mtg_search.jsp" method="post" >
	<table width="100%" cellpadding="0" cellspacing="0" border="0">

<!-- Subject -->
	<tr>
	<td width="15">&nbsp;</td>
		<td width="120" class="plaintext_blue">Subject:</td>
		<td>
			<input type='text' name='subject' size='60' value='<%=viewSubject%>'>
		</td>
	</tr>

<!-- Location -->
	<tr>
	<td width="15">&nbsp;</td>
		<td width="120" class="plaintext_blue">Location:</td>
		<td>
			<input type='text' name='location' size='30' value='<%=viewLoc%>'>
		</td>
	</tr>

<!-- owner -->
	<tr>
	<td width="15">&nbsp;</td>
	<td align="left" valign="middle" class="plaintext_blue">Coordinator:</td>
	<td>
			<select name="owner" class="formtext">
			<option value=""> - - Select - - </option>
<%
		int oid;
		for(int i=0; i < allMember.length; i++)
		{
			if (allMember[i] == null) continue;
			oid = allMember[i].getObjectId();
			String firstEmpName = (String)allMember[i].getAttribute("FirstName")[0];
			String lastEmpName = (String)allMember[i].getAttribute("LastName")[0];
			out.print("<option value='" + oid + "' ");
			if (oid == viewOwnerId) out.print("selected");
			out.print(">" + firstEmpName + " " + lastEmpName + "</option>");
		}
%>

			</select>

	</td>
	</tr>

<!-- attendee -->
	<tr>
	<td width="15">&nbsp;</td>
	<td align="left" valign="middle" class="plaintext_blue">Attendee:</td>
	<td>
			<select name="attendee" class="formtext">
			<option value=""> - - Select - - </option>
<%
		for(int i=0; i < allMember.length; i++)
		{
			if (allMember[i] == null) continue;
			oid = allMember[i].getObjectId();
			String firstEmpName = (String)allMember[i].getAttribute("FirstName")[0];
			String lastEmpName = (String)allMember[i].getAttribute("LastName")[0];
			out.print("<option value='" + oid + "' ");
			if (oid == viewAttendeeId) out.print("selected");
			out.print(">" + firstEmpName + " " + lastEmpName + "</option>");
		}
%>

			</select>

	</td>
	</tr>


<!-- status -->
	<tr>
	<td width="15">&nbsp;</td>
	<td align="left" valign="top" class="plaintext_blue">Status:</td>
	<td>
		<table border='0' cellspacing='0' cellpadding='0'>
<%
	int num = 0;
	for(int i = 0; i < meeting.STATE_ARRAY.length; i++)
	{
		if (num%RADIO_NUM == 0) out.print("<tr>");
		out.print("<td class='formtext' width='130'><input type='checkbox' name='"
			+ meeting.STATE_ARRAY[i] + "'");
		if (request.getParameter(meeting.STATE_ARRAY[i]) != null)
			out.print(" checked");
		out.print(">" + meeting.STATE_ARRAY[i] + "</td>");
		if (num%RADIO_NUM == RADIO_NUM-1) out.print("</tr>");
		num++;
	}
	if (num%RADIO_NUM != 0) out.print("</tr>");
%>
		</table>
	</td>
	</tr>

	<tr><td colspan="3">&nbsp;</td></tr>

	<tr>
	<td colspan="3" align="center">
		<input type='button' class='button_medium' value='Submit' onclick='mtgSearch.submit();' />
		<input type='button' class='button_medium' value='Reset' onclick='resetForm();' />
	</td>
	</tr>

	<tr><td><img src='../i/spacer.gif' height='20'/></td></tr>
	</table>
</form>

<!-- *************************   Display Meeting Headers   ************************* -->

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
	<td colspan="20" height="2" bgcolor="#336699"><img src="../i/spacer.gif" width="2" height="2"></td>
	</tr>
	<tr>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="230" bgcolor="#6699cc" class="td_header"><strong>&nbsp;Subject</strong></td>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="15" bgcolor="#6699cc" class="td_header"><strong>St.</strong></td>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="84" bgcolor="#6699cc" class="td_header" align="center"><strong>Start Time</strong></td>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="84" bgcolor="#6699cc" class="td_header" align="center"><strong>End Time</strong></td>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="80" bgcolor="#6699cc" class="td_header" align="center"><strong>Location</strong></td>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="50" bgcolor="#6699cc" class="td_header" align="center"><strong>Coordinator</strong></td>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="100" bgcolor="#6699cc" class="td_header" align="center"><strong>Attendee</strong></td>
	</tr>


<!-- list of meetings -->
<%

try {
	String bgcolor="";
	boolean even = false;

	String ownerIdS, dot;
	user empObj = null, uObj;
	String lastOwner = "";

	String status, subject, location;
	Object [] attendeeA;

	Date startDate, endDate, dt;

	for(int i = 0; i < mtgArr.length; i++)
	{	// a list of meetings satisfied the search expr
		meeting mtgObj = (meeting)mtgArr[i];
		if (mtgObj == null) continue;

		subject		= (String)mtgObj.getAttribute("Subject")[0];
		status		= (String)mtgObj.getAttribute("Status")[0];
		startDate	= (Date)mtgObj.getAttribute("StartDate")[0];
		endDate		= (Date)mtgObj.getAttribute("ExpireDate")[0];
		location	= (String)mtgObj.getAttribute("Location")[0];
		ownerIdS	= (String)mtgObj.getAttribute("Owner")[0];
		attendeeA	= mtgObj.getAttribute("Attendee");

		if (even)
			bgcolor = Prm.DARK;
		else
			bgcolor = Prm.LIGHT;
		even = !even;
		
		out.print("<tr " + bgcolor + "><td colspan='20'><img src='../i/spacer.gif' height='5'/></td></tr>");
		out.print("<tr " + bgcolor + ">");

		// Subject
		out.print("<td>&nbsp;</td>");
		out.print("<td class='listtext' valign='top'>");
		out.print("<a href='mtg_view.jsp?mid=" + mtgObj.getObjectId() + "'>");
		out.print(subject + "</a>");
		out.println("</td>");

		// Status {NEW, LIVE, FINISH, EXPIRE, COMMIT, ABORT}
		dot = "../i/";
		if (status.equals(meeting.NEW)) {dot += "dot_orange.gif";}
		else if (status.equals(meeting.LIVE)) {dot += "dot_green.gif";}
		else if (status.equals(meeting.FINISH)) {dot += "dot_blue.gif";}
		else if (status.equals(meeting.EXPIRE)) {dot += "dot_red.gif";}
		else if (status.equals(meeting.COMMIT)) {dot += "dot_black.gif";}
		else if (status.equals(meeting.ABORT)) {dot += "dot_cancel.gif";}
		else {dot += "dot_grey.gif";}
		out.print("<td colspan='3' class='listlink' align='center' valign='top'>");
		out.print("<img src='" + dot + "' alt='" + status + "'>");
		out.println("</td>");

		// StartDate
		out.print("<td colspan='2'>&nbsp;</td>");
		out.print("<td class='listtext_small' width='84' align='center' valign='top'>");
		out.print(df.format(startDate));
		out.println("</td>");

		// ExpireDate
		out.print("<td colspan='2'>&nbsp;</td>");
		out.print("<td class='listtext_small' width='84' align='center' valign='top'>");
		out.print(df.format(endDate));
		out.println("</td>");

		// location
		out.print("<td colspan='2'>&nbsp;</td>");
		out.print("<td class='listtext' width='80' valign='top' align='center'>");
		if (location == null) location = "-";
		out.print(location);
		out.println("</td>");

		// owner
		out.print("<td colspan='3' class='listtext' align='center' valign='top'>");
		if (ownerIdS != null)
		{
			// ECC: need to optimize this in the near future
			if (!ownerIdS.equals(lastOwner))
				empObj = (user)uMgr.get(pstuser,Integer.parseInt(ownerIdS));
			uid = empObj.getObjectId();
			lastOwner = ownerIdS;
			out.print("<a class='listlink' href='../ep/ep1.jsp?uid=" + uid + "'>");
			out.print((String)empObj.getAttribute("FirstName")[0]);
			out.print("</a>");
		}
		out.println("</td>");

		// attendees
		out.print("<td colspan='2'>&nbsp;</td>");
		out.print("<td class='listtext' width='100' valign='top'>");

		for (int j=0; j<attendeeA.length; j++)
		{
			if (j > 5)
			{
				// show up to 5 people
				out.print(", ...");
				break;
			}
			s = (String)attendeeA[j];
			if (s == null) break;
			String [] sa = s.split(meeting.DELIMITER);
			try{
			uObj = (user)uMgr.get(pstuser,Integer.parseInt(sa[0]));
			if (j > 0) out.print(", ");
			out.print("<a class='listlink' href='../ep/ep1.jsp?uid=" + sa[0] + "'>");
			out.print((String)uObj.getAttribute("FirstName")[0]);
			out.print("</a>");
			} catch (PmpException e) {continue;}
		}
		out.println("</td>");

		out.println("</tr>");
		out.println("<tr " + bgcolor + ">" + "<td colspan='20'><img src='../i/spacer.gif' width='2' height='2'></td></tr>");
	}

} catch (Exception e)
{
	response.sendRedirect("../out.jsp?msg=Internal error in displaying meeting list.  Please contact administrator.");
	return;
}
%>
	</table>

		</td>
		</tr>
		<tr><td colspan="2">&nbsp;</td></tr>
	</table>
<!-- END MEETING LIST -->


<table>
	<tr>
		<td width="10">&nbsp;</td>
		<td class="tinytype" align="center">Meeting Status:
			&nbsp;&nbsp;<img src="../i/dot_orange.gif" border="0"><%=meeting.NEW%>
			&nbsp;&nbsp;<img src="../i/dot_green.gif" border="0"><%=meeting.LIVE%>
			&nbsp;&nbsp;<img src="../i/dot_blue.gif" border="0"><%=meeting.FINISH%>
			&nbsp;&nbsp;<img src="../i/dot_red.gif" border="0"><%=meeting.EXPIRE%>
			&nbsp;&nbsp;<img src="../i/dot_black.gif" border="0"><%=meeting.COMMIT%>
			&nbsp;&nbsp;<img src="../i/dot_cancel.gif" border="0"><%=meeting.ABORT%>
		</td>
	</tr>
</table>

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
