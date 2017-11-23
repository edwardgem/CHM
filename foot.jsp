<%@ page import = "util.*" %>
<% String NODE = Util.getPropKey("pst", "PRM_HOST");%>

<table width="90%" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td width="100%" height="2" bgcolor="#336699"><img src="../i/mid/u2x2.gif" width="2" height="2"></td>
    <td height="2" bgcolor="#336699"><img src="../i/mid/u2x2.gif" width="2" height="2"></td>
  </tr>
<%
	String app = (String)session.getAttribute("app");
	if (app!=null && !app.equals("OMF"))
	{%>
  <tr>
    <td valign="middle" align="center">
		<a href="<%=NODE%>/ep/ep_home.jsp" class="listlink">Home</a>
		&nbsp;|&nbsp;
		<a href="<%=NODE%>/info/faq.jsp" class="listlink">FAQ</a>
		&nbsp;|&nbsp;
		<a href="<%=NODE%>/info/help.jsp" class="listlink">Help forum</a>
		&nbsp;|&nbsp;
		<a href="<%=NODE%>/logout.jsp" class="listlink">Logout</a>
		&nbsp;&nbsp;|&nbsp;
		<a href="#top" class="listlink">Back to top</a></td>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td height="32" align="center" valign="middle"><font size="1" face="Arial, Helvetica, sans-serif" color="#999999" class="8ptype">Copyright
      &copy; 2013-2017, EGI Technologies, Inc.</font></td>
    <td height="32">&nbsp;</td>
  </tr>
<%	}
	else
	{%>
  <tr>
    <td valign="middle" align="center">
		<a href="../ep/ep_home.jsp" class="listlink">Home</a>
		&nbsp;|&nbsp;
		<a href="../info/faq_omf.jsp?home=../ep/ep_home.jsp" class="listlink">FAQ</a>
		&nbsp;|&nbsp;
		<a href="../info/help.jsp?home=../ep/ep_home.jsp" class="listlink">Feedback forum</a>
<%		if (app!=null)
		{%>
		&nbsp;|&nbsp;
		<a href="../logout.jsp" class="listlink">Logout</a>
<%		} %>
		&nbsp;|&nbsp;
		<a href="#top" class="listlink">Back to top</a></td>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td width="100%" height="32" align="center" valign="middle"><font size="1" face="Arial, Helvetica, sans-serif" color="#999999" class="8ptype">Copyright
      &copy; 2013-2017, EGI Technologies, Inc.</font></td>
    <td height="32">&nbsp;</td>
  </tr>
<%	} %>
</table>
