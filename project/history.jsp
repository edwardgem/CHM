<html>
<%
//
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: history.jsp
//	Author: ECC
//	Date:	10/18/04
//	Description: Review project history.  Only closed project has history.
//		Get all the history records of the projects that I am authorized to see.
//		Display them in the table.
//		For now, show all history record without authorization check.
//
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
<%@ page import = "java.text.SimpleDateFormat" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />
<%
	////////////////////////////////////////////////////////
	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}

	String backPage = "../project/history.jsp";

	int uid = pstuser.getObjectId();
	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ( (iRole & user.iROLE_ADMIN) > 0 )
		isAdmin = true;

	projectManager pjMgr = projectManager.getInstance();

	SimpleDateFormat Formatter;
	Formatter = new SimpleDateFormat ("MM/dd/yy");

	userManager uMgr = userManager.getInstance();


	////////////////////////////////////////////////////////
%>


<head>
<title>PRM</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="../init.jsp" flush="true"/>

</head>

<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
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
						<td width="754" height="30" align="left" valign="bottom" class="head">
						<b>Project History</b>
					</td></tr>
	            </table>
	          </td>
	        </tr>
			<tr>
          		<td width="100%">
					<!-- Navigation Menu -->
					<jsp:include page="../in/ireview.jsp" flush="true">
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
							<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../images/spacer.gif" width="1" height="1" border="0"></td>
						</tr>
					</table>
					<table border="0" width="780" height="14" cellspacing="0" cellpadding="0">
						<tr>
							<td width="20" height="14" bgcolor="#FFFFFF"><img src="../i/spacer.gif" height="1" border="0"></td>
							<td valign="top" class="BgSubnav">
								<table border="0" cellspacing="0" cellpadding="0">
								<tr class="BgSubnav">
								<td width="40"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
					<!-- Current Project -->
									<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
									<td width="7"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td><a href="review.jsp" class="subnav">Current Project</a></td>
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<!-- Task Analysis -->
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td><a href="revw_task.jsp" class="subnav">Task Analysis</a></td>
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<!-- Project History -->
									<td width="7"><img src="../i/spacer.gif" width="7" height="1" border="0"></td>
									<td width="15" height="14"><img src="../i/nav_arrow.gif" width="20" height="14" border="0"></td>
									<td><a href="#" class="subnav"><u>Project History</u></a></td>
									<td width="15" onClick="return false;"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<!-- Project Plan Change -->
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td><a href="revw_planchg.jsp" class="subnav">Project Plan Change</a></td>
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
								</tr>
								</table>
							</td>
						</tr>
					</table>
					<table border="0" width="780" height="1" cellspacing="0" cellpadding="0">
						<tr>
							<td width="20" height="1" bgcolor="#FFFFFF"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
							<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../images/spacer.gif" width="1" height="1" border="0"></td>
						</tr>
					</table>
					<!-- End of Navigation SUB-Menu -->
				</td>
	        </tr>
		</table>
		<!-- Content Table -->

		 <table width="855" border="0" cellspacing="0" cellpadding="0">


			<tr><td colspan="2">&nbsp;</td></tr>
			<tr>
				<td width="20"><img src="../i/spacer.gif" width="5" border="0"></td>
				<td width="835">

<!-- Project Name -->

	<table width="100%" cellpadding="0" cellspacing="0">
	<tr>
		<td class="heading">
		</td>
	</tr>

	</table>

<!-- *************************   Page Headers   ************************* -->

<!-- LABEL -->
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
	<td colspan="38" height="2" bgcolor="#336699"><img src="../i/spacer.gif" width="2" height="2"></td>
	</tr>
	<tr>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="190" bgcolor="#6699cc" class="td_header">&nbsp;Project Name</td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="50" bgcolor="#6699cc" class="td_header" align="center">Manager</td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="24" bgcolor="#6699cc" class="td_header">St.</td>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="40" bgcolor="#6699cc" class="td_header">Type</td>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="55" bgcolor="#6699cc" class="td_header" align="center">Start<br>Date</td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="55" bgcolor="#6699cc" class="td_header" align="center">Expire Date</td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="55" bgcolor="#6699cc" class="td_header" align="center">Done<br>Date</td>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="33" bgcolor="#6699cc" class="td_header" align="center">Len (Day)</td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="42" bgcolor="#6699cc" class="td_header" align="center">Days Gain / Loss</td>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="33"bgcolor="#6699cc" class="td_header" align="center">Team Size</td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="33"bgcolor="#6699cc" class="td_header" align="center"># of Blog</td>
	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
	<td width="33"bgcolor="#6699cc" class="td_header" align="center"># of Task</td>

	<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
	<td width="112" bgcolor="#6699cc" class="td_header">
		<table width="100%" border="0" cellspacing="0" cellpadding="0">
			<tr><td height="20" colspan="5" class="td_header" align="center">Task</td></tr>
			<tr><td colspan="5" width="114" height="1" bgcolor="#FFFFFF"><img src="../i/spacer.gif" width="114" height="1"></td></tr>
			<tr>
				<td class="td_header" align="center">Early</td>
				<td width="1" height="25" bgcolor="#FFFFFF"><img src="../i/spacer.gif" width="1" height="25"></td>
				<td class="td_header" align="center">Late</td>
				<td width="1" height="25" bgcolor="#FFFFFF"><img src="../i/spacer.gif" width="1" height="25"></td>
				<td class="td_header" align="center">Cancel</td>
			</tr>
		</table>
	</td>

	</tr>
	</table>


<!-- HISTORY -->
<%

try
{
	historyManager hMgr = historyManager.getInstance();
	int [] ids = hMgr.findId(pstuser, "om_acctname='%'");

	String bgcolor="";
	boolean even = false;

	org.xml.sax.XMLReader reader = XML.makeXMLReader();
	XHandle hd = new XHandle();		// create a parser
	HashMap hash;
	reader.setContentHandler(hd);
	byte [] ba;

	history h;
	String pjName, ownerIdS, tStatus, s;
	user empObj = null;
	String lastOwner = "";
	String dot=null;

	for (int i=0; i<ids.length; i++)
	{
		h = (history)hMgr.get(pstuser, ids[i]);
		hash = hd.newHash();		// get a new hash for the record

		ba = (byte [])h.getAttribute("Content")[0];
		reader.parse(new org.xml.sax.InputSource(new ByteArrayInputStream(ba)));	// i use ByteArrayInputStream(byte[] buf)

		if (even)
			bgcolor = "bgcolor='#EEEEEE'";
		else
			bgcolor = "bgcolor='#ffffff'";
		even = !even;

		// get and display the items in the history record

		// project name
		pjName = (String)hash.get("project-name");
		out.println("<table width='100%' " + bgcolor +"border='0' cellspacing='2' cellpadding='2'>");
		out.print("<tr><td width='176'><table width='176' cellspacing='0' cellpadding='0'><tr>");
		out.print("<td width='3' height='20'>&nbsp;</td>");
		out.print("<td class='listlink' width='172'>");
		out.print("<a class='listlink' href='../out.jsp?msg=Archive database not found."
			+ "&projName=" + pjName + "'>");
		out.print(pjName + "</a></td>");
		out.print("</tr></table></td>");

		// coordinator
		ownerIdS = (String)hash.get("coordinator");
		out.print("<td class='listlink' align='center' width='44'>");
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

		// status
		tStatus = (String)hash.get("status");
		dot = "../i/";
		boolean bComplete = false;
		out.print("<td class='listtext_small' width='20' align='center'>");
		if (tStatus.equals("Canceled"))
		{
			dot += "dot_cancel.gif";
			out.print("<img src='" + dot + "' alt='" + tStatus + "'>");
		}
		else if (tStatus.equals("Completed"))
		{
			dot += "dot_green.gif";
			out.print("<img src='" + dot + "' alt='" + tStatus + "'>");
		}
		else if (tStatus.equals("Completed-Early"))
		{
			dot += "dot_green.gif";
			out.print("<img src='" + dot + "' alt='" + tStatus + "'>");
			out.print("<img src='../i/dot_lightblue.gif' alt='Early'>");
		}
		else if (tStatus.equals("Completed-Late"))
		{
			dot += "dot_green.gif";
			out.print("<img src='" + dot + "' alt='" + tStatus + "'>");
			out.print("<img src='../i/dot_red.gif' alt='Late'>");
		}
		out.println("</td>");

		// project type
		out.print("<td class='listtext_small' width='40' align='center'>");
		out.print(hash.get("type"));
		out.print("</td>");

		// start, expire, and complete Date
		out.print("<td class='listtext_small' width='47' align='center'>");
		out.print(hash.get("start-date"));
		out.println("</td>");

		out.print("<td class='listtext_small' width='47' align='center'>");
		out.print(hash.get("expire-date"));
		out.println("</td>");

		s = (String)hash.get("complete-date");
		if (s == null) s = "-";
		out.print("<td class='listtext_small' width='48' align='center'>");
		out.print(s);
		out.println("</td>");

		// duration (length)
		s = (String)hash.get("duration");
		if (s == null) s = "-";
		out.print("<td class='listtext_small' width='30' align='center'>");
		out.print(s);
		out.print("</td>");

		// days gain/loss
		s = (String)hash.get("days-gain");
		out.print("<td class='listtext_small' width='33' align='center'>");
		if (s == null) s = "-";
		else if (Integer.parseInt(s) < 0) out.print("<font color='#dd0000'>" + s + "</font>");
		else out.print(s);
		out.print("</td>");

		// team size
		out.print("<td class='listtext_small' width='30' align='center'>");
		out.print(hash.get("total-member"));
		out.print("</td>");

		// # of blog
		out.print("<td class='listtext_small' width='30' align='center'>");
		out.print(hash.get("total-blog"));
		out.print("</td>");

		// # of task
		out.print("<td class='listtext_small' width='30' align='center'>");
		out.print(hash.get("total-task"));
		out.print("</td>");

		// early task
		s = (String)hash.get("early-task");
		if (s == null) s = "-";
		out.print("<td class='listtext_small' width='30' align='center'>");
		out.print(s);
		out.print("</td>");

		// late task
		s = (String)hash.get("late-task");
		if (s == null) s = "-";
		out.print("<td class='listtext_small' width='30' align='center'>");
		out.print(s);
		out.print("</td>");

		// cancel task
		s = (String)hash.get("cancel-task");
		if (s == null) s = "-";
		out.print("<td class='listtext_small' width='30' align='center'>");
		out.print(s);
		out.print("</td>");

		out.println("</tr></table>");
	}

} catch (Exception e)
{
	response.sendRedirect("../out.jsp?msg=Internal error in displaying history.  Please contact administrator.");
	return;
}

%>

		</td>
		</tr>
		<tr><td colspan="2">&nbsp;</td></tr>
	</table>
<!-- END HISTORY -->


<table>
	<tr>
		<td width="10">&nbsp;</td>
		<td class="tinytype" align="center">Project Status:
			&nbsp;&nbsp;<img src="../i/dot_green.gif" border="0">Completed
			&nbsp;&nbsp;<img src="../i/dot_lightblue.gif" border="0">Early
			&nbsp;&nbsp;<img src="../i/dot_red.gif" border="0">Late
			&nbsp;&nbsp;<img src="../i/dot_cancel.gif" border="0">Canceled
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
