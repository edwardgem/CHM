<%@ page import = "oct.codegen.user" %>
<%	int iRole = Integer.parseInt(request.getParameter("role"));%>

<table border="0" cellspacing="0" cellpadding="0" width="780">
  <tr>
  	<td width="20"><img src="../i/mid/1x1.gif" width="20" border="0"></td>

    <td width="85"><a href="../ep/ep_home.jsp" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('home','','../i/but/hn.gif',1)"><img src="../i/but/hf.gif" border="0" name="home"></a></td>
    <td width="85"><a href="../project/proj_plan.jsp?projName=session" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('projects','','../i/but/pjn.gif',1)"><img src="../i/but/pjf.gif" border="0" name="projects"></a></td>
    <td width="85"><a href="#" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('review','','../i/but/reviewn.gif',1)"><img src="../i/but/review.gif" border="0" name="review"></a></td>
    <td width="85"><a href="../bug/bug_search.jsp" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('bugs','','../i/but/trn.gif',1)"><img src="../i/but/trf.gif" border="0" name="bugs"></a></td>
    <td width="85"><a href="../meeting/cal.jsp" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('meet','','../i/but/mtgn.gif',1)"><img src="../i/but/mtgf.gif" border="0" name="meet"></a></td>
    <td width="85"><a href="../ep/ep1.jsp" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('Image2','','../i/but/prfn.gif',1)"><img src="../i/but/prff.gif" border="0" name="Image2"></a></td>

<%	if ((iRole & user.iROLE_ADMIN) != 0)
	{%>
		<td width="85"><a href="../ep/ep_admin.jsp" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('admin','','../i/but/adminn.gif',1)"><img src="../i/but/adminf.gif" border="0" name="admin"></a></td>
		<td width="95"><img src="../i/but/mbar.gif" width="80" height="29"></td>
<%	}
	else
	{%>
		<td width="180"><img src="../i/but/mbar.gif" width="165" height="29"></td>
<%	}%>

    <td width="70"><a href="../logout.jsp"><img src="../i/but/lout.gif" border="0"></a></td>
  </tr>
</table>
