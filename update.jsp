<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
<title>OMM Modeling Tool</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />

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

function MM_showHideLayers() { //v3.0
  var i,p,v,obj,args=MM_showHideLayers.arguments;
  for (i=0; i<(args.length-2); i+=3) if ((obj=MM_findObj(args[i]))!=null) { v=args[i+2];
    if (obj.style) { obj=obj.style; v=(v=='show')?'visible':(v='hide')?'hidden':v; }
    obj.visibility=v; }
}
//-->
</script>
<SCRIPT LANAGUAGE = "JavaScript">
<!-- start
	function checkOrg()
	{
	   var choices = document.CheckOrg.orgname
	   var chosen = choices.options[choices.selectedIndex].value

	   if(chosen == "")
	   {
		  alert("Please select an Organization")
	   }
	   else
	   {
	      document.CheckOrg.submit()
	   }
    }
//end-->
</SCRIPT>
<link rel="stylesheet" href="ss/css.css">
</head>
<%@ page import = "oct.omm.common.*" %>
<%@ page import = "oct.omm.client.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<jsp:useBean id="admin" scope="session" class="oct.omm.jsp.OJspMember" />

<%
	OmsSession s = admin.getSession();
	OmsDomain domain = new OmsDomain(s);
	OmsObList orglist = domain.getOrgList();	//list type == organization att list
    orglist.sort();

	OmsObList list = new OmsObList();
	OmsObList memlist = new OmsObList();
	OmsObject obj =	 null;
	String orgname = new String();

	if(request.getParameter("orgname") != null && ((String)request.getParameter("orgname")).length() > 0)
	{
		orgname = request.getParameter("orgname");
		OmsOrganization org1 = new OmsOrganization(s, orgname);
		memlist = org1.resolveExpression("(om_acctname='%')");
		memlist.sort();
	}
%>

<body bgcolor="#FFFFFF" link="#0000FF" vlink="#0000FF" alink="#FF0000" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0" onLoad="MM_preloadImages('image/organiz-on.gif','image/member-on.gif','image/create-on.gif','image/delete-on.gif','image/update-on.gif','image/advsrch-on.gif','image/horupdate-on.gif','image/horsrch-on.gif','image/attribute-on.gif','image/relation-on.gif','image/role-on.gif','image/event-on.gif','image/logout-on.gif','image/getattlst-on.gif','image/getmem-on.gif','image/createorg-on.gif','image/deleteorg-on.gif','image/addatt-on.gif','image/dropatt-on.gif','image/modeling-on.gif','image/disattdef-on.gif','image/create2-on.gif','image/delete2-on.gif','image/disvlndef-on.gif','image/delete3-on.gif','image/update3-on.gif','image/resolve-on.gif','image/create3-on.gif','image/disroldef-on.gif','image/delevndef-on.gif','image/setevndef-on.gif','image/detofevn-on.gif','image/updatebut-on.gif')">
<a name="top"></a>
<table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td>
      <jsp:include page="omm-top.jsp" flush="true"/></td>
  </tr>
</table>
<table width="780" border="0">
  <tr>
    <td width="10">&nbsp;</td>
    <td width="760">&nbsp;</td>
  </tr>
  <tr align="left">
    <td width="10"><img src="image/1clear-px.gif" width="10" height="1"></td>
    <td width="760"><img src="image/search-member.gif" width="633" height="22"></td>
  </tr>
  <tr>
    <td width="10">&nbsp;</td>
    <td width="760">&nbsp;</td>
  </tr>
</table>
<table width="780" border="0" cellspacing="1" cellpadding="1">
  <tr class="11ptype">
    <td width="10">&nbsp;</td>
    <td width="213" class="10ptype" align="right">&nbsp;</td>
    <td width="544" class="10ptype">&nbsp;</td>
  </tr>
  <form name="CheckOrg">
    <tr class="11ptype">
      <td width="10">&nbsp;</td>
      <td width="213" class="10ptype" align="right">&nbsp;</td>
      <td width="544" class="10ptype">&nbsp;</td>
    </tr>
    <tr class="10ptype">
      <td width="10">&nbsp;</td>
      <td width="213" class="10ptype" align="right">&nbsp;</td>
      <td width="544" class="10ptype">&nbsp;</td>
    </tr>
    <tr>
      <td width="10"><img src="image/1clear-px.gif" width="10" height="1"></td>
      <td width="213" class="10ptype" align="right"><b>Organization Name: </b></td>
      <td width="544" class="10ptype">
        <select name="orgname" OnChange = "javascript:checkOrg()">
			<option value = "">-select organization-
			<%
				for (Enumeration e=orglist.elements(); e.hasMoreElements(); )
				{
				   obj = (OmsObject)e.nextElement();
				   if(obj.getName().equals(orgname))
				   {
			%>
					<option value = "<%=obj.getName()%>" selected><%=obj.getName()%>
			<%
				   }
				   else
				   {
			%>
					<option value = "<%=obj.getName()%>"><%=obj.getName()%>
			<%
				   }
				} // endfor
			%>
		</select>
      </td>
    </tr>
    </form>
    <form name="Submit" action="createupdate.jsp">
    <tr>
      <td width="10">&nbsp;</td>
      <td width="213" align="right" class="10ptype" valign="top">&nbsp;</td>
      <td width="544">&nbsp;</td>
    </tr>
    <tr>
      <td width="10">&nbsp;</td>
      <td width="213" align="right" class="10ptype" valign="top"><b>Member Name:
        </b></td>
      <td width="544">
        <select name="memid">
			<%
				if(memlist.size() > 0)
				{
					for (Enumeration e=memlist.elements(); e.hasMoreElements(); )
					{
					   	obj = (OmsObject)e.nextElement();
			%>
						<option value = "<%=obj.getId()%>"><%=obj.getName()%>
			<%
					}
				}
				else
				{
			%>
						<option value = "-select member-">-select member-
			<%

				} // endfor
			%>
		</select>
      </td>
    </tr>
    <tr>
      <td width="10">&nbsp;</td>
      <td width="213" class="10ptype" align="right">&nbsp;</td>
      <td width="544">&nbsp;</td>
    </tr>
    <tr>
      <td width="10">&nbsp;</td>
      <td width="213" class="10ptype" align="right">&nbsp;</td>
      <td width="544">&nbsp;</td>
    </tr>
    <tr>
      <td width="10">&nbsp;</td>
      <td width="213" class="10ptype" align="right">&nbsp;</td>
      <td width="544"><a href="javascript:document,Submit.submit()" onMouseOut="MM_swapImgRestore()" onMouseOver="MM_swapImage('Image38','','image/updatebut-on.gif',1)"><img src="image/updatebut-off.gif" width="72" height="14" border="0" name="Image38"></a></td>
    </tr>
    <tr>
      <td width="10">&nbsp;</td>
      <td width="213">&nbsp;</td>
      <td width="544">&nbsp;</td>
    </tr>
  </form>
</table>
<table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td>
      <jsp:include page="omm-bottom.jsp" flush="true"/></td>
  </tr>
</table>
</body>
</html>
