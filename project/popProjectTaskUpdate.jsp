<html>
<%
//
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: popProjectTaskUpdate.jsp
//	Author: Lian Lee
//	Date: 03/20/03
//	Description: Update project.
//
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
// popProjectTaskUpdate.jsp :
//
/**
* @author $Author$
* @version $Revision$
*/
/**
* $Log$
* Revision 1.3  2007/10/25 19:12:42  edwardc
* Change lettercase of properties file BringUp to bringup.
*
* Revision 1.2  2005/11/07 07:03:29  edwardc
* Synchronize prayer (laptop) to merciful CVS
*
* Revision 1.1  2003/06/16 18:09:17  eddiel
* initial release
*
* Revision 1.25  2001/08/17 17:47:36  lianl
* no message
*
* Revision 1.24  2001/08/14 23:34:59  lianl
* no message
*
* Revision 1.23  2001/08/06 21:41:52  lianl
* no message
*
* Revision 1.22  2001/08/01 23:38:10  lianl
*/
%>

<%@ page import = "oct.omm.common.*" %>
<%@ page import = "oct.omm.client.*" %>
<%@ page import = "oct.omm.db.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />
<%
	if (user instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	String levelInfo = request.getParameter("levelInfo");
	String realorder = request.getParameter("realorder");
	// Get project task
	Stack projectStack = (Stack)session.getAttribute("projectStack");
	if((projectStack == null) || projectStack.empty())
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	Vector rProject = (Vector)projectStack.peek();
	Hashtable rProjectTask = (Hashtable)rProject.elementAt(Integer.parseInt(realorder));
	Object [] pName = (Object [])rProjectTask.get("Name");
	String name = (String)pName[0];


%>

<head>
<title>PRM</title>

<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<link rel="stylesheet" href="../ss/popup.css">
<script Language="JavaScript">
<!--
function MM_preloadImages() { //v3.0
  var d=document; if(d.images){ if(!d.MM_p) d.MM_p=new Array();
    var i,j=d.MM_p.length,a=MM_preloadImages.arguments; for(i=0; i<a.length; i++)
    if (a[i].indexOf("#")!=0){ d.MM_p[j]=new Image; d.MM_p[j++].src=a[i];}}
}

function MM_swapImgRestore() { //v3.0
  var i,x,a=document.MM_sr; for(i=0;a&&i<a.length&&(x=a[i])&&x.oSrc;i++) x.src=x.oSrc;
}

function MM_findObj(n, d) { //v3.0
  var p,i,x;  if(!d) d=document; if((p=n.indexOf("?"))>0&&parent.frames.length) {
    d=parent.frames[n.substring(p+1)].document; n=n.substring(0,p);}
  if(!(x=d[n])&&d.all) x=d.all[n]; for (i=0;!x&&i<d.forms.length;i++) x=d.forms[i][n];
  for(i=0;!x&&d.layers&&i<d.layers.length;i++) x=MM_findObj(n,d.layers[i].document); return x;
}

function MM_swapImage() { //v3.0
  var i,j=0,x,a=MM_swapImage.arguments; document.MM_sr=new Array; for(i=0;i<(a.length-2);i+=3)
   if ((x=MM_findObj(a[i]))!=null){document.MM_sr[j++]=x; if(!x.oSrc) x.oSrc=x.src; x.src=a[i+2];}
}

function checkEmpty()
{
	path = document.updateProjectTask;

	if (path.Name.value == "")
	{
		alert("The Task cannot be empty.");
		path.Name.value = "<%=name%>";
		path.Name.onFocus;
		return false;
	}

	return true;
}

function reset()
{
	document.updateProjectTask.Name.value="<%=name%>";
}

//-->

</SCRIPT>

</head>

<body bgcolor="#FFFFFF"  leftmargin="0" topmargin="0" marginwidth="0" marginheight="0" onLoad="MM_preloadImages('../i/but/sven.gif','../i/but/resn.gif','../i/but/cnln.gif');">
<table width="100%" height="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">

<table width="675" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td>
      <table width="675" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td width="675" height="60"><img src="../i/top/top_UpdatePlan.gif" width="675" height="60" border="0"></td>
        </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
	<!-- Content Table -->
		<form method="post" name="updateProjectTask" action="postProjectTaskUpdate.jsp">
	    <input type="hidden" name="realorder" value='<%=realorder%>'>
	   	<table width="100%" border="0" cellspacing="0" cellpadding="0">
		<tr><td colspan="5">&nbsp;</td></tr>
		<tr><td colspan="5">&nbsp;</td></tr>
		<tr>
			<td width="20"><img src="../i/spacer.gif" width="20" height="2" border="0"></td>
			<td colspan="3">* Please type in the change of task <%=levelInfo%> and click save to proceed.</td>
			<td>&nbsp;</td>
		</tr>
		<tr>
            <td>&nbsp;</td>
			<td width="80" class="td_all"><%=levelInfo%></td>
            <td width="6">&nbsp;</td>
            <td width="350"><%=name%></td>
			<td>&nbsp;</td>
		</tr>
		<tr>
            <td>&nbsp;</td>
			<td width="80" class="td_all"><%=levelInfo%></td>
            <td width="6">&nbsp;</td>
            <td width="350"><input type="text" name="Name" value="<%=name%>" size="80"></td>
			<td>&nbsp;</td>
        </tr>
		<tr><td colspan="5">&nbsp;</td></tr>
		<tr><td colspan="5">&nbsp;</td></tr>
		 <tr>
            <td>&nbsp;</td>
			<td>&nbsp;</td>
	        <td colspan="2" align="center">
              <table border="0" cellspacing="1" cellpadding="0">
                <tr>
                  <td width="69"><a href="javascript:document.updateProjectTask.submit();" OnClick="return checkEmpty()" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('Image1','','../i/but/sven.gif',1)"><img src="../i/but/svef.gif" border="0" name="Image1"></a></td>
                  <td width="10"><img src="../i/spacer.gif" width="10" height="2" border="0"></td>
                  <td width="69"><a href="javascript:reset()" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('Image4','','../i/but/resn.gif',1)"><img src="../i/but/resf.gif" border="0" name="Image4"></a></td>
                  <td width="10"><img src="../i/spacer.gif" width="10" height="2" border="0"></td>
                  <td width="69"><a href="javascript:window.close()" onClick="window.close()" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('Image5','','../i/but/cnln.gif',1)"><img src="../i/but/cnlf.gif" border="0" name="Image5"></a></td>
                </tr>
              </table>
            </td>
			<td>&nbsp;</td>
        </tr>
      </table>
      </form>
<!-- End of Content Table -->
    </td>
  </tr>
  </table>
	</td>
</tr>
<tr>
	<td>
		<!-- Footer -->
		<table width="660" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td width="520">&nbsp;</td>
        </tr>
        <tr>
          <td height="2" width="520" bgcolor="336699"><img src="ep/images/mid/336699-2by2-holder.gif" width="2" height="2"></td>
        </tr>
        <tr>
          <td height="32" width="520" align="center" valign="middle"><font size="1" face="Arial, Helvetica, sans-serif" color="#999999">Copyright
            &copy; 2004, EGI Technologies</font></td>
        </tr>
      </table>
		<!-- End of Footer -->
	</td>
</tr>
</table>
</body>
</html>
