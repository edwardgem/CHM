<%@ page import = "oct.codegen.user" %>
<%	int iRole = Integer.parseInt(request.getParameter("role"));

	out.print("<table border='0' cellspacing='0' cellpadding='0' width='100%'>");
  	out.print("<tr><td width='20'><img src='../i/mid/1x1.gif' width='20' border='0'></td>");

    out.print("<td width='85'><a href='../ep/ep_home.jsp' onMouseOut=\"MM_swapImgRestore()\" onMouseOver=\"MM_swapImage('home','','../i/but/hn.gif',1)\"><img src='../i/but/hf.gif' border='0' name='home'></a></td>");
    out.print("<td width='85'><a href='../project/proj_top.jsp?projName=session' onMouseOut=\"MM_swapImgRestore()\" onMouseOver=\"MM_swapImage('projects','','../i/but/pjn.gif',1)\"><img src='../i/but/pjf.gif' border='0' name='projects'></a></td>");

	if ((iRole & user.iROLE_VENDOR) == 0 && false) {
		out.print("<td width='85'><a href='../project/review.jsp?projName=session' onMouseOut=\"MM_swapImgRestore()\" onMouseOver=\"MM_swapImage('review','','../i/but/reviewn.gif',1)\"><img src='../i/but/reviewf.gif' border='0' name='review'></a></td>");
	}
    out.print("<td width='85'><a href='../meeting/cal.jsp' onMouseOut=\"MM_swapImgRestore()\" onMouseOver=\"MM_swapImage('meet','','../i/but/mtgn.gif',1)\"><img src='../i/but/mtgf.gif' border='0' name='meet'></a></td>");
    out.print("<td width='85'><a href='../bug/bug_search.jsp' onMouseOut=\"MM_swapImgRestore()\" onMouseOver=\"MM_swapImage('bugs','','../i/but/trn.gif',1)\"><img src='../i/but/tr.gif' border='0' name='bugs'></a></td>");
    out.print("<td width='85'><a href='../ep/ep1.jsp' onMouseOut=\"MM_swapImgRestore()\" onMouseOver=\"MM_swapImage('Image2','','../i/but/prfn.gif',1)\"><img src='../i/but/prff.gif' border='0' name='Image2'></a></td>");

	if ((iRole & user.iROLE_ADMIN) != 0)
	{
		out.print("<td><a href='../ep/ep_admin.jsp' onMouseOut=\"MM_swapImgRestore()\" onMouseOver=\"MM_swapImage('admin','','../i/but/adminn.gif',1)\"><img src='../i/but/adminf.gif' border='0' name='admin'></a></td>");
		out.print("<td><img src='../i/but/mbar.gif' width='165' height='29'></td>");
	}
	else if ((iRole & user.iROLE_VENDOR) != 0)
		out.print("<td width='265'><img src='../i/but/mbar.gif' width='265' height='29'></td>");
	else
	{
		// common user
		out.print("<td width='100%'><img src='../i/but/mbar.gif' width='100%' height='29'></td>");
	}

    out.print("<td width='70'><a href='../logout.jsp'><img src='../i/but/lout.gif' border='0' ></a></td>");
	out.print("</tr></table>");
%>