<%@ page import = "oct.codegen.user" %>
<%@ page import = "util.Prm" %>
<%	int iRole = Integer.parseInt(request.getParameter("role"));
	boolean isCRAPP = Prm.isCR();
	boolean isOMFAPP = Prm.isOMF();
	boolean isPRMAPP = Prm.isPRM();
	boolean isCtModule = Prm.isCtModule(session);


	out.print("<table border='0' cellspacing='0' cellpadding='0' width='100%'>");
	out.print("<tr><td width='20'><img src='../i/mid/1x1.gif' width='20' border='0'></td>");
    out.print("<td><a href='../ep/ep_home.jsp' onMouseOut=\"MM_swapImgRestore()\" onMouseOver=\"MM_swapImage('home','','../i/but/hn.gif',1)\"><img src='../i/but/h.gif' border='0' name='home'></a></td>");


	if (isPRMAPP) {
    	out.print("<td><a href='../project/proj_top.jsp' onMouseOut=\"MM_swapImgRestore()\" onMouseOver=\"MM_swapImage('projects','','../i/but/pjn.gif',1)\"><img src='../i/but/pjf.gif' border='0' name='projects'></a></td>");
		if ((iRole & user.iROLE_VENDOR) == 0 && false) {
    		out.print("<td><a href='../project/review.jsp?projName=session' onMouseOut=\"MM_swapImgRestore()\" onMouseOver=\"MM_swapImage('review','','../i/but/reviewn.gif',1)\"><img src='../i/but/reviewf.gif' border='0' name='review'></a></td>");
		}
	}
	else if (isCRAPP) {
    	out.print("<td width='85'><a href='../project/cr.jsp' onMouseOut=\"MM_swapImgRestore()\" onMouseOver=\"MM_swapImage('projects','','../i/but/pjn.gif',1)\"><img src='../i/but/pjf.gif' border='0' name='projects'></a></td>");
	}


	if (isOMFAPP || isPRMAPP)
	{
		// event
    	out.print("<td><a href='../meeting/cal.jsp#today' onMouseOut=\"MM_swapImgRestore()\" onMouseOver=\"MM_swapImage('meet','','../i/but/mtgn.gif',1)\"><img src='../i/but/mtgf.gif' border='0' name='meet'></a></td>");

		if (isOMFAPP && !isCRAPP) {
			out.print("<td><a href='../network/contacts.jsp' onMouseOut=\"MM_swapImgRestore()\" onMouseOver=\"MM_swapImage('net','','../i/but/netn.gif',1)\"><img src='../i/but/netf.gif' border='0' name='net'></a></td>");
		}
	}

	// tracker
	if (isCtModule){
    	out.print("<td><a href='../bug/bug_search.jsp' onMouseOut=\"MM_swapImgRestore()\" onMouseOver=\"MM_swapImage('bugs','','../i/but/trn.gif',1)\"><img src='../i/but/trf.gif' border='0' name='bugs'></a></td>");
	}

    out.print("<td><a href='../ep/ep1.jsp' onMouseOut=\"MM_swapImgRestore()\" onMouseOver=\"MM_swapImage('Image2','','../i/but/prfn.gif',1)\"><img src='../i/but/prff.gif'border='0' name='Image2'></a></td>");

	if ((iRole & user.iROLE_ADMIN) != 0)
	{
		out.print("<td><a href='../ep/ep_admin.jsp' onMouseOut=\"MM_swapImgRestore()\" onMouseOver=\"MM_swapImage('admin','','../i/but/adminn.gif',1)\"><img src='../i/but/adminf.gif' border='0' name='admin'></a></td>");
		out.print("<td width='100%'><img src='../i/but/mbar.gif' width='100%' height='29'></td>");
	}
	else if ((iRole & user.iROLE_VENDOR) != 0)
	{
		if (isCRAPP || isOMFAPP)
			out.print("<td><img src='../i/but/mbar.gif' width='350' height='29'></td>");
		else if (isPRMAPP)
			out.print("<td><img src='../i/but/mbar.gif' width='265' height='29'></td>");
		else // CR-OMF
			out.print("<td><img src='../i/but/mbar.gif' width='350' height='29'></td>");
	}
	else
	{
		// common user
		out.print("<td width='100%'><img src='../i/but/mbar.gif' width='100%' height='29'></td>");
	}

    out.print("<td><a href='../logout.jsp' onMouseOut=\"MM_swapImgRestore()\" onMouseOver=\"MM_swapImage('logout','','../i/but/loutn.gif',1)\"><img src='../i/but/loutf.gif' border='0' name='logout'></a></td>");
	out.print("</tr></table>");
%>