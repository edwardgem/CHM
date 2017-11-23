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
%>

<table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td align="left" width="780">
		<table width="95%" border="0" cellspacing="0" cellpadding="0">
		<tr><td><img src='../i/spacer.gif' height='10'></td></tr>
		<tr>
  			<td><img src='../i/spacer.gif' width='5'></td>
			<td><a href='../index.jsp'><img src='../i/logo.gif' border='0'></a></td>
			<td align='right'>
			<table border="0" cellspacing="0" cellpadding="0">
			<tr><td><font size="2px" face="Verdana, Arial, Helvetica, sans-serif" color="#003382"><b>
					<%=prodName%></td></tr>
			</table>
			</td>
		</tr>
		</table>
    </td>
   </tr>
   <tr><td><img src='../i/spacer.gif' height='10'></td></tr>
</table>
