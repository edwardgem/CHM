<%
////////////////////////////////////////////////////
//	Copyright (c) 2006, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	faq_omf.jsp
//	Author:	ECC
//	Date:	09/07/06
//	Description:		Feedback page for OMF.
//	Modification:
//			@ECC110806a	Support meeting blog
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>

<%
	String COMPANY		= Util.getPropKey("pst", "COMPANY_NAME");
	String NODE			= Util.getPropKey("pst", "PRM_HOST");
	String ADMIN_MAIL	= Util.getPropKey("pst", "FROM");
	
	String prodName;
	if (Prm.isMeetWE())
		prodName = "MeetWE";
	else
		prodName = "Collabris";

	boolean isLogin = false;

	// create a user object as guest if I am not login yet
	PstUserAbstractObject pstuser = null;
	HttpSession sess = request.getSession(false);
	if (sess != null)
		pstuser = (PstUserAbstractObject)sess.getAttribute("pstuser");
	else
		sess = request.getSession(true);
	if (pstuser == null) {
		try {
			sess = request.getSession(true);
			pstuser = (PstUserAbstractObject) PstGuest.getInstance();
			sess.setAttribute("pstuser", pstuser);
		} catch (PmpException e) {
			response.sendRedirect("../out.jsp?e=The feedback forum is temporarily unavailable, please try again later.");
			return;
		}
	}
	
	String title;
	String param;		// blog type
	
	// @ECC110806a Meeting blog
	String midS = request.getParameter("mid");
	if (midS == null)
	{
		title = "Feedback Forum";
		param = "type=" + result.TYPE_FRUM_BLOG;
	}
	else
	{
		title = "Meeting Blog";
		param = "type=" + result.TYPE_MTG_BLOG + "&id=" + midS;
	}

	resultManager rMgr = resultManager.getInstance();
	userManager uMgr = userManager.getInstance();
	
	String home = request.getParameter("home");
	if (home == null)
		home = "../index.jsp";
	if (home.equals("../ep/ep_home.jsp"))
		isLogin = true;
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">

<title>
	<%=title%>
</title>

</head>

<body text="#000000" leftmargin="10" topmargin="10" marginwidth="0" marginheight="0">

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="715" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="infohead.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<b class="head">

	&nbsp;&nbsp;<%=title%>

	</b><br><br>
	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- Navigation SUB-Menu -->
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
<td width="100%" valign="top">

	<table border="0" width="100%" height="14" cellspacing="0" cellpadding="0">
		<tr>
			<td valign="top" class="bgsubnav">
				<table border="0" cellspacing="0" cellpadding="0">
				<tr class="bgsubnav">
	<!-- Home -->
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="<%=home%>" class="subnav">Home</a></td>
					<td colspan="3" width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

<%	if (midS == null)
	{%>
	<!-- FAQ -->
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="faq_omf.jsp?home=<%=home%>" class="subnav">FAQ</a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- Terms of Use -->
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="terms_omf.jsp?home=<%=home%>" class="subnav">Terms of Use</a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- Help Forum -->
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="20" height="14"><img src="../i/nav_arrow.gif" width="20" height="14" border="0"></td>
					<td><a href="#" onClick="return false;" class="subnav"><u>Feedback Forum</u></a></td>
					<td colspan="3" width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
<%	} else
	{%>
	<!-- Meeting Blog -->
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="20" height="14"><img src="../i/nav_arrow.gif" width="20" height="14" border="0"></td>
					<td><a href="#" onClick="return false;" class="subnav"><u>Meeting Blog</u></a></td>
					<td colspan="3" width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- Back to Meeting -->
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="../meeting/mtg_view.jsp?mid=<%=midS%>" class="subnav">Back to Meeting</a></td>
					<td colspan="3" width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
<%	} %>
				</tr>
				</table>
			</td>
		</tr>
	</table>
	<table border="0" width="100%" height="1" cellspacing="0" cellpadding="0">
		<tr>
			<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
		</tr>
	</table>

</td>
</tr>
</table>
<!-- End of Navigation SUB-Menu -->

<!-- CONTENT -->
<table border='0' width='95%'>
	<tr><td><img src="../i/spacer.gif" width="10" height="5" border="0"></td><td></td></tr>
	
	<tr>
		<td width='2'></td>
		<td width='100%' align='right'>
		<img src="../i/bullet_tri.gif" width="20" height="10">
		<a class="listlinkbold" href="../blog/addblog.jsp?<%=param%>">New Post</a>
		</td>
	</tr>
	
	<tr>
		<td width='2'></td>
		<td class="plaintext">
<%
			String [] label = {"&nbsp;Topic", "Author", "Replies", "View #", "Posted On"};
			int [] labelLen = {700, 100, 60, 60, 100};
			boolean [] bAlignCenter = {false, true, true, true, true};
			out.print(Util.showLabel(label, labelLen, bAlignCenter, true));		// showAll and align center
			
			// get all FORUM parent blogs (Name != null)
			int [] ids;
			if (midS == null)
				ids = rMgr.findId(pstuser, "Type='" + result.TYPE_FRUM_BLOG + "' && Name='%'");
			else
				ids = rMgr.findId(pstuser, "Type='" + result.TYPE_MTG_BLOG + "' && TaskID='" + midS + "'");
			Arrays.sort(ids); 		// ascending order
			PstAbstractObject [] objList = rMgr.get(pstuser, ids);
			PstAbstractObject blog;
			String topic, author, authorIdS;
			Date dt;
			int replies, views, blogId;
			Integer iObj;
			SimpleDateFormat df = new SimpleDateFormat ("MM/dd/yyyy");

			String bgcolor="";
			boolean even = false;

			for (int i=objList.length-1; i >= 0 ; i--)
			{
				// list all blogs from latest to oldest
				blog = objList[i];
				blogId = blog.getObjectId();
				topic = (String)blog.getAttribute("Name")[0];
				authorIdS = (String)blog.getAttribute("Creator")[0];
				dt = (Date)blog.getAttribute("CreatedDate")[0];
				
				ids = rMgr.findId(pstuser, "ParentID='" + blogId + "'");
				replies = ids.length;
				iObj = (Integer)blog.getAttribute("ViewBlogNum")[0];
				if (iObj != null)
					views = iObj.intValue();
				else
					views = 0;
	
				if (even) bgcolor = "bgcolor='#EEEEEE'";
				else bgcolor = "bgcolor='#ffffff'";
				even = !even;

				out.print("<tr " + bgcolor + ">");

				// topic
				out.print("<td height='20px'></td>");
				out.print("<td class='ptextS1' width='" + labelLen[0] + "'>");
				out.print("<a class='ptextS1' href='../blog/blog_comment.jsp?blogId=" + blogId
						+ "&" + param + "&view=1'>");
				out.print(topic);
				out.print("</a></td>");

				// author
				author = uMgr.get(pstuser, Integer.parseInt(authorIdS)).getObjectName();
				out.print("<td colspan='2'></td>");
				out.print("<td class='listlink' align='center' width='" + labelLen[1] + "'>");
				out.print("<a class='listlink' href='../ep/ep1.jsp?uid=" + authorIdS + "'>");
				out.print(author);
				out.println("</a></td>");

				// replies
				out.print("<td colspan='2'></td>");
				out.print("<td class='plaintext' align='center' width='" + labelLen[2] + "'>");
				out.print(replies); 
				out.println("</td>");

				// views
				out.print("<td colspan='2'></td>");
				out.print("<td class='plaintext' align='center' width='" + labelLen[3] + "'>");
				out.print(views); 
				out.println("</td>");

				// posted date
				out.print("<td colspan='2'></td>");
				out.print("<td class='plaintext' align='center' width='" + labelLen[4] + "'>");
				out.print(df.format(dt)); 
				out.println("</td>");

				out.println("</tr>");
				out.println("<tr " + bgcolor + ">" + "<td colspan='14'><img src='../i/spacer.gif' width='2' height='2'></td></tr>");
			}
%>
		</table>
		</td>
	</tr>
	
<tr><td colspan='2'>&nbsp;</td><tr>
</table>



<!-- BEGIN FOOTER TABLE -->
<table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td width="90%" height="2" bgcolor="336699"><img src="../i/mid/u2x2.gif" width="2" height="2"></td>
    <td height="2" bgcolor="336699"><img src="../i/mid/u2x2.gif" width="2" height="2"></td>
  </tr>
  <tr>
    <td width="90%" valign="middle" align="center">
		<a href="<%=home%>" class="listlink">Home</a>
		&nbsp;|&nbsp;
		<a href="whatis.jsp" class="listlink">What is <%=prodName%>?</a>
		&nbsp;|&nbsp;
		<a href="faq_omf.jsp?home=<%=home%>" class="listlink">FAQ</a>
		&nbsp;|&nbsp;
		<a href="help.jsp?home=<%=home%>" class="listlink">Feedback</a>
<%if (isLogin){%>
		&nbsp;|&nbsp;
		<a href="../logout.jsp" class="listlink">Logout</a>
<%}%>
		&nbsp;|&nbsp;
		<a href="#top" class="listlink">Back to top</a></td>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td width="90%" height="32" align="center" valign="middle"><font size="1" face="Arial, Helvetica, sans-serif" color="#999999" class="8ptype">Copyright
      &copy; 2008-2014, EGI Technologies, Inc.</font></td>
    <td height="32">&nbsp;</td>
  </tr>
</table>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

