<%@ page import = "oct.pst.PstGuest" %>
<%@ page import = "util.*" %>
<%
	String NODE = Prm.getPrmHost();
	String prodName = Prm.getApp();
	String logoFile = null;
	if (!Prm.isMeetWE())
		logoFile = (String)session.getAttribute("comPicFile");
	if (logoFile == null) logoFile = "../i/logo.gif";
	else logoFile = "../file/memberPic/" + logoFile;
	
	if (Prm.isCR())
		prodName = "Central Repository";
	else if (Prm.isMeetWE())
		prodName = "Open Meeting Facilitator";
	else if (Prm.isPRM())
		prodName = "Collaborative Project Management";
	else
		prodName = "Central Repository - OMF";

	boolean isGuest = false;
	if (session.getAttribute("pstuser") instanceof PstGuest) isGuest = true;
%>

<table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td align="left">
		<table width="90%" border="0" cellspacing="0" cellpadding="0">
		<tr><td><img src='../i/spacer.gif' height='10'></td></tr>
		<tr>
  			<td><img src='../i/spacer.gif' width='5'></td>
  			<td><table cellspacing='0' cellpadding='0'><tr>
				<td><a href='<%=NODE%>/index.jsp'><img src='<%=logoFile%>' height='70' border='0'></a></td>
				<td valign='top'><img src='../i/spacer.gif' height='35' width='1'/><font size="2px" face="Verdana, Arial, Helvetica, sans-serif" color="#003382">
						<b><%=prodName%></b></font></td>
			</tr></table></td>

			<td valign='top' align='right'>
			<table border="0" cellspacing="0" cellpadding="0">
				<tr><td><img src='../i/spacer.gif' height='20'></td></tr>
<%	if (isGuest){ %>
				<tr><td><a href='../login.jsp'>Sign in</a></td></tr>
<%	}%>
				<tr><td><img src='../i/spacer.gif' height='10'></td></tr>
			</table>
			</td>
		</tr>
		</table>
    </td>

   </tr>
</table>
<!-- table width="100%" border="0" cellspacing="0" cellpadding="0">
	<tr>
	<td style="font-family: Verdana, Arial, Helvetica, Verdana,sans-serif; font-weight: bold; font-size: 18px; color: #bb0000" align='center'>
		The System will be shutting down in 5 minutes.<br>Sorry for the inconvenience.
	<td>
	</tr>
</table -->

