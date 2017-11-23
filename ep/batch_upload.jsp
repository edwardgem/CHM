<html>
<%
//
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: batch_upload.jsp
//	Author: Lian Lee
//	Date:	05/28/03
//	Description: Batch Operation Upload personal profile.
//
//
//	Modification:
//		@AGQ081506	Changed role value from "Site Administrator" to session's 
//					iRole value.
//
/////////////////////////////////////////////////////////////////////
//
// ep1.jsp :
//
/**
* @author $Author$
* @version $Revision$
*/
/**
* $Log$
* Revision 1.8  2006/09/11 21:52:53  sandras
* Fix page title tag with correct application name.
*
* Revision 1.7  2006/09/08 00:51:22  edwardc
* OMF bug-fix.
*
* Revision 1.6  2006/08/16 19:25:07  sandras
* Fix sub-menu position.
*
* Revision 1.5  2006/08/16 02:03:16  allenq
* Bug Fix: iRole value for Admin -> 2046
*
* Revision 1.4  2006/06/23 03:31:01  edwardc
* SE project check-in
*
* Revision 1.3  2006/06/16 02:13:15  edwardc
* Created search box and changed header banner.
*
* Revision 1.2  2005/11/07 07:03:36  edwardc
* Synchronize prayer (laptop) to merciful CVS
*
* Revision 1.1  2003/06/16 17:59:31  eddiel
* initial release
*
* Revision 1.60  2001/08/17 17:47:36  lianl
* no message
*
* Revision 1.59  2001/08/09 21:32:06  marcush
* fixed time out page
*
* Revision 1.58  2001/08/06 21:41:52  lianl
* no message
*
* Revision 1.22  2001/08/01 23:38:10  lianl
*/
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.omm.common.*" %>
<%@ page import = "oct.omm.client.*" %>
<%@ page import = "oct.omm.db.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />
<%
	String memname = request.getParameter("memname");
	String msg = request.getParameter("msg");
	if (msg == null) msg = "";
	String app = (String)session.getAttribute("app");
%>


<head>
<title><%=app%> Upload</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="../init.jsp" flush="true"/>
<script language="javaScript">
<!--

function check(){
	if (document.upload.UpLoadFile.value=="")
	{
		alert("Please enter the file path before submit!");
		document.upload.UpLoadFile.focus();
		return false;
	}
}


//-->
</SCRIPT>

</head>

<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" height="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">

<table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr align="left" valign="top">
    <td width="100%">
	<jsp:include page="../head.jsp" flush="true"/>
</table>
<table border="0" cellspacing="0" cellpadding="0">
<tr>
</td>
  </tr>
  <tr align="left" valign="top">
    <td>
      <table width="780" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td>
            <table width="780" border="0" cellspacing="0" cellpadding="0">
              <tr>
                <td width="26" height="28"><a name="top">&nbsp;</a></td>
                <td width="754" height="28" align="left" valign="bottom"><b><font size="2" face="Arial, Helvetica, sans-serif" color="#336699" class="10ptype">
				&nbsp;&nbsp;&nbsp;&nbsp;Welcome, <%=pstuser.getAttribute("FirstName")[0] %>.</font>
				  </b>
				 </td>
              </tr>
			  <tr>
			  	<td colspan="2">

<%	// @081403ECC
	if (app.equals("PRM") &&
		session.getAttribute("projectId") == null)
	{ // run PRM and no project selected yet
%>
<%-- @AGQ081506 --%>
			<jsp:include page="../in/home_short.jsp" flush="true">
			<jsp:param name="role" value="<%=((Integer)session.getAttribute("role")).intValue()%>"/> 
			</jsp:include>
<%
	} else
	{ // run SBM version or PRM with a project selected
%>
<%-- @AGQ081506 --%>
			<jsp:include page="../in/home.jsp" flush="true">
			<jsp:param name="role" value="<%=((Integer)session.getAttribute("role")).intValue()%>"/> 
			</jsp:include>
<%	}%>

			  	</td>
			  </tr>
			  <tr>
          		<td width="100%" colspan="2" valign="top">
					<!-- Navigation SUB-Menu -->
					<table border="0" width="780" height="1" cellspacing="0" cellpadding="0">
						<tr>
							<td width="20" height="1" bgcolor="#FFFFFF"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
							<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../images/spacer.gif" width="1" height="1" border="0"></td>
						</tr>
					</table>
					<table border="0" width="780" height="14" cellspacing="0" cellpadding="0">
						<tr>
							<td width="20" height="14" bgcolor="#FFFFFF"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
							<td valign="top" class="BgSubnav">
								<table border="0" cellspacing="0" cellpadding="0">
								<tr class="BgSubnav">
								<td width="40"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
					<!-- Home -->
									<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td><a href="ep_home.jsp" class="subnav">Home</a></td>
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
					<!-- Batch Upload -->
									<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
									<td width="7"><img src="../i/spacer.gif" width="7" height="1" border="0"></td>
									<td width="15" height="14"><img src="../i/nav_arrow.gif" width="15" height="14" border="0"></td>
									<td><a href="batch_upload.jsp" onClick="return false;" class="subnav"><u>Batch Upload</u></a></td>
									<td width="15"><img src="../i/spacer.gif" width="15" height="1" border="0"></td>
									<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
								</tr>
								</table>
							</td>
						</tr>
					</table>
					<table border="0" width="780" height="1" cellspacing="0" cellpadding="0">
						<tr>
							<td width="20" height="1" bgcolor="#FFFFFF"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
							<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../images/spacer.gif" width="1" height="1" border="0"></td>
						</tr>
					</table>
					<!-- End of Navigation SUB-Menu -->
				</td>
	        </tr>
              <tr>
                <td width="26">&nbsp;</td>
                <td width="754">
					<table width="100%" border="0" cellspacing="0" cellpadding="0">
						<tr>
							<td >
								&nbsp;
							</td>
						 </tr>
						<tr>
							<td class="heading">Batch Upload</td>
						</tr>
						<tr>
							<td class="plaintext"><font color="#aa0000">
								&nbsp;&nbsp;<%=msg%></font>
							</td>
						 </tr>
					</table>
					<form method="post" name="upload" action="postUpload.jsp" enctype="multipart/form-data">
					<table width="90%" height="50" border="0" cellspacing="2" cellpadding="4" bgcolor="#FFFFFF">
						<tr>
							<td class="td_field_bg" width="100"><strong>Upload File</strong></td>
							<td class="td_value_bg">
									<input type="file" name="UpLoadFile" size="70">
							</td>
						</tr>
					</table>
					<p align="center" >
						<a href="javascript:document.upload.submit()" OnClick="return check()" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('submit_button','','../i/but/sbtn.gif',1)"><img src="../i/but/sbtf.gif" name="submit_button" border="0"></a>
					</p>
				</td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </td>
  </tr>

</table>
<p>&nbsp;</p>
<p>&nbsp;</p>
<jsp:include page="../foot.jsp" flush="true"/>
</body>
</html>
