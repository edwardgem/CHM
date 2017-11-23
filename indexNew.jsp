
<%
//
//  Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   index.jsp
//  Author: marcush
//  Date:   07/02/2001
//  Description:
//    This is the index page for Project Management Tool.
//
//  Modification:
//
/////////////////////////////////////////////////////////////////////
//
//
//

/**
* @author $Author$
* @version $Revision$
*
* $Log$
* Revision 1.2  2005/11/07 07:03:28  edwardc
* Synchronize prayer (laptop) to merciful CVS
*
* Revision 1.1  2003/06/16 18:39:47  eddiel
* initial release
*
* Revision 1.11  2001/08/20 16:17:08  lianl
* no message
*
* Revision 1.10  2001/07/18 19:56:50  lianl
* adjusted top's width
*
* Revision 1.9  2001/07/12 23:54:17  timc
* Fixed header.  Now use an include page ( loginhead.jsp ) for header.
*
* Revision 1.8  2001/07/12 18:02:13  lianl
* input field validation
*
* Revision 1.7  2001/07/11 05:32:38  lianl
* set keypress
*
* Revision 1.6  2001/07/09 22:48:28  marcush
* added code for login
*
*
*/
%>

<%@ page import = "oct.omm.common.*" %>
<%@ page import = "oct.omm.client.*" %>
<%@ page import = "oct.omm.db.*" %>
<%@ page import = "oct.pep.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>


<%
	String error = request.getParameter("error");
%>

<html>
<head>
<title>Project Management</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<link rel="stylesheet" href="ss/css.css">
<script language="JavaScript">
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
//-->
</script>

<script language="JavaScript">
<!--//
function checkempty()
{
	if (document.Login.Uid.value == "")
	{
		alert("Please enter your Username.");
		return false;
	}

	if (document.Login.Password.value == "")
	{
		alert("Please enter your Password.");
		return false;
	}

	return true;
}

function fo()
{
	Form = document.Login;
	for (i=0;i < Form.length;i++)
	{
		if (Form.elements[i].type != "hidden")
		{
			Form.elements[i].focus();
			break;
		}
	}
}
-->
</script>
</head>

<body bgcolor="#FFFFFF" onLoad="MM_preloadImages('i/but/lgin.gif');fo();" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" height="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">
<table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr align="left" valign="top">
    <td><jsp:include page="loginhead.jsp" flush="true"/></td>
  </tr>
  <tr align="left" valign="top">
    <td>
      <table width="780" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td width="200">&nbsp;</td>
          <td width="380">&nbsp;</td>
          <td width="200">&nbsp;</td>
        </tr>
		 <tr>
          <td colspan="3">&nbsp;</td>
        </tr>
		<tr>
          <td colspan="3">&nbsp;</td>
        </tr>
        <tr>
          <td width="200">&nbsp;</td>
          <td align="center" valign="middle" class="10ptype" width="380"><b><font color="#336699">
           Please enter your Product Release Manager Login Username and Password. Then click Login.</font></b></td>
          <td width="200">&nbsp;</td>
        </tr>
        <tr>
          <td width="200">&nbsp;</td>
          <td width="380">&nbsp;</td>
          <td width="200">&nbsp;</td>
        </tr>
        <tr>
		  <form method="post" action="checklogin.jsp" name="Login">
          <td width="200">&nbsp;</td>
          <td width="380">
            <table width="380" border="0" cellspacing="0" cellpadding="0">
              <tr>
                <td class="10ptype" align="right" valign="top" width="120">User Name: </td>
                <td width="14" height="29">&nbsp;</td>
                <td width="246" align="left" valign="top" height="29">
					<input type="text" name="Uid">
                </td>
              </tr>
              <tr>
                <td width="120" align="right" valign="top" class="10ptype">Password: </td>
                <td width="14">&nbsp;</td>
                <td width="246" align="left" valign="top">
                    <input type="password" name="Password">
                </td>
              </tr>
              <tr>
                <td width="120">&nbsp;</td>
                <td width="14">&nbsp;</td>
                <td width="246">&nbsp;</td>
              </tr>
            </table>
          </td>
          <td width="200">&nbsp;</td>
        </tr>
        <tr>
          <td width="200">&nbsp;</td>
          <td width="380" align="center" valign="top">
            <a href="javascript:document.Login.submit()" onClick="return checkempty()" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('login','','i/but/lgin.gif',1)">
            <input type="image" src="i/but/lgif.gif" name="login"></a>
		  </td>
          <td width="200">&nbsp;</td>
		  </form>
        </tr>
        <tr>
          <td width="200">&nbsp;</td>
          <td width="380">&nbsp;</td>
          <td width="200">&nbsp;</td>
        </tr>
      </table>

	  <table height="200">
	  	<tr>
			<td>&nbsp;</td>
		</tr>
	  </table>
	</td>
</tr>
<tr>
	<td valign="bottom">
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
	</td>
</tr>
</table>
</body>
</html>
