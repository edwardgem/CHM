<%@ page import = "oct.codegen.user" %>
<%	int iRole = Integer.parseInt(request.getParameter("role"));
	boolean isCRAPP = false;
	boolean isOMFAPP = false;
	boolean isPRMAPP = false;
	String app = (String)session.getAttribute("app");
	if (app.indexOf("CR")!=-1)
		isCRAPP = true;
	if (app.indexOf("OMF")!=-1 || app.toLowerCase().indexOf("meetwe")!=-1)
		isOMFAPP = true;
	else if (app.equals("PRM"))
		isPRMAPP = true;
%>

<table border="0" cellspacing="0" cellpadding="0" width="780">
  <tr>
  	<td width="20"><img src="../i/mid/1x1.gif" width="20" border="0"></td>

    <td width="85"><a href="../ep/ep_home.jsp" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('home','','../i/but/hn.gif',1)"><img src="../i/but/hf.gif" border="0" name="home"></a></td>

<%
	if (isPRMAPP){
%>
    <td><a href="../project/proj_plan.jsp" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('projects','','../i/but/pjn.gif',1)"><img src="../i/but/pjf.gif" border="0" name="projects"></a></td>
<%		if ((iRole & user.iROLE_VENDOR) == 0)
		{%>
    		<td><a href="../project/review.jsp?projName=session" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('review','','../i/but/reviewn.gif',1)"><img src="../i/but/reviewf.gif" border="0" name="review"></a></td>
<%		}
	}
	else if (isCRAPP) {%>
    <td width="85"><a href="../project/cr.jsp" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('projects','','../i/but/pjn.gif',1)"><img src="../i/but/pjf.gif" border="0" name="projects"></a></td>
<%	}


	if (isPRMAPP){%>
    <td><a href="../bug/bug_search.jsp" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('bugs','','../i/but/trn.gif',1)"><img src="../i/but/trf.gif" border="0" name="bugs"></a></td>
<%	}
	if (isOMFAPP || isPRMAPP)
	{%>
    <td><a href="../meeting/cal.jsp#today" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('meet','','../i/but/mtgn.gif',1)"><img src="../i/but/mtgf.gif" border="0" name="meet"></a></td>
	<td><a href="../network/contacts.jsp" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('net','','../i/but/netn.gif',1)"><img src="../i/but/net.gif" border="0" name="net"></a></td>
<%	}%>

    <td><a href="../ep/ep1.jsp" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('Image2','','../i/but/prfn.gif',1)"><img src="../i/but/prff.gif"border="0" name="Image2"></a></td>

<%	if ((iRole & user.iROLE_ADMIN) != 0)
	{%>
		<td><a href="../ep/ep_admin.jsp" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('admin','','../i/but/adminn.gif',1)"><img src="../i/but/adminf.gif" border="0" name="admin"></a></td>
<%		if (!(isCRAPP && isOMFAPP) && (isCRAPP || isOMFAPP) )
			out.print("<td><img src='../i/but/mbar.gif' width='250' height='29'></td>");
		else if (isPRMAPP)
			out.print("<td><img src='../i/but/mbar.gif' width='80' height='29'></td>");
		else // CR-OMF
			out.print("<td><img src='../i/but/mbar.gif' width='250' height='29'></td>");
	}
	else if ((iRole & user.iROLE_VENDOR) != 0)
	{
		if (isCRAPP || isOMFAPP)
			out.print("<td><img src='../i/but/mbar.gif' width='350' height='29'></td>");
		else if (app.equals("PRM"))
			out.print("<td><img src='../i/but/mbar.gif' width='265' height='29'></td>");
		else // CR-OMF
			out.print("<td><img src='../i/but/mbar.gif' width='350' height='29'></td>");
	}
	else
	{
		if (!(isCRAPP && isOMFAPP) && (isCRAPP || isOMFAPP) )
			out.print("<td><img src='../i/but/mbar.gif' width='335' height='29'></td>");
		else if (isPRMAPP)
			out.print("<td><img src='../i/but/mbar.gif' width='165' height='29'></td>");
		else // CR-OMF
			out.print("<td><img src='../i/but/mbar.gif' width='335' height='29'></td>");
	}%>

    <td><a href="../logout.jsp" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('logout','','../i/but/loutn.gif',1)"><img src="../i/but/loutf.gif" border="0" name="logout"></a></td>
  </tr>
</table>
