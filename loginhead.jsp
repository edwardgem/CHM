<%@ page import = "util.*" %>
<%
	String prodName;

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
    <td align="left">
		<table width="90%" border="0" cellspacing="0" cellpadding="0">
		<tr><td><img src='i/spacer.gif' height='10'></td></tr>
		<tr>
  			<td><img src='i/spacer.gif' width='5'></td>
			<td><a href='index.jsp'><img src='i/logo.gif' border='0'></a></td>
			<td align='right'>
			<table border="0" cellspacing="0" cellpadding="0">
			<tr><td><font size="2px" face="Verdana, Arial, Helvetica, sans-serif" color="#003382"><b>
					<%=prodName%></font></td></tr>
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
