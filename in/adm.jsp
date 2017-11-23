<%@ page import = "util.Prm" %>
<%	
	boolean isCRAPP = Prm.isCR();
	boolean isOMFAPP = Prm.isOMF();
	boolean isPRMAPP = Prm.isPRM();
	boolean isCtModule = Prm.isCtModule(session);
%>
	
<table border="0" cellspacing="0" cellpadding="0" width="100%">
  <tr>
  	<td width="20"><img src="../i/mid/1x1.gif" width="20" border="0"></td>

    <td><a href="../ep/ep_home.jsp" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('home','','../i/but/hn.gif',1)"><img src="../i/but/hf.gif" border="0" name="home"></a></td>
<%	if (isPRMAPP) {
	    out.print("<td><a href='../project/proj_plan.jsp' onMouseOut='MM_swapImgRestore()' onMouseOver=\"MM_swapImage('projects','','../i/but/pjn.gif',1)\"><img src='../i/but/pjf.gif' border='0' name='projects'></a></td>");
	}
	if (isOMFAPP || isPRMAPP) {
    out.print("<td><a href='../meeting/cal.jsp' onMouseOut='MM_swapImgRestore()' onMouseOver=\"MM_swapImage('meet','','../i/but/mtgn.gif',1)\"><img src='../i/but/mtgf.gif' border='0' name='meet'></a></td>");
	}
	if (isCtModule)
	    out.print("<td><a href='../bug/bug_search.jsp' onMouseOut='MM_swapImgRestore()' onMouseOver=\"MM_swapImage('bugs','','../i/but/trn.gif',1)\"><img src='../i/but/trf.gif' border='0' name='bugs'></a></td>");
%>
    <td><a href="../ep/ep1.jsp" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('Image2','','../i/but/prfn.gif',1)"><img src="../i/but/prff.gif" border="0" name="Image2"></a></td>
	<td><a href="#" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('admin','','../i/but/adminn.gif',1)"><img src="../i/but/admin.gif" border="0" name="admin"></a></td>

<%
	out.print("<td width='100%'><img src='../i/but/mbar.gif' width='100%' height='29'></td>");
%>
	
	<td><a href="../logout.jsp" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('logout','','../i/but/loutn.gif',1)"><img src="../i/but/loutf.gif" border="0" name="logout"></a></td>
  </tr>
</table>
