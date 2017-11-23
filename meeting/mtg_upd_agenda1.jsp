<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>

<%
//
//	Copyright (c) 2005, EGI Technologies, Co.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: mtg_upd_agenda1.jsp
//	Author: ECC
//	Date:	03/04/05
//	Description: Update the meeting agenda (step 1 of 2).
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "util.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.omm.common.*" %>
<%@ page import = "oct.omm.client.*" %>
<%@ page import = "oct.omm.db.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />
<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	////////////////////////////////////////////////////////

	String midS = request.getParameter("mid");
	if ((pstuser instanceof PstGuest) || (midS == null))
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	int myUid = pstuser.getObjectId();
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	
	String app = Prm.getAppTitle();

	meeting mtg = (meeting)meetingManager.getInstance().get(pstuser, midS);
	userinfoManager uiMgr = userinfoManager.getInstance();
	
	userinfo myUI = (userinfo) uiMgr.get(pstuser, String.valueOf(myUid));
	TimeZone myTimeZone = myUI.getTimeZone();
	int myTimeZoneOffset = myUI.getTimeZoneIdx();
	
	SimpleDateFormat df = new SimpleDateFormat ("MM/dd/yyyy hh:mm a");
	if (!userinfo.isServerTimeZone(myTimeZone)) {
		df.setTimeZone(myTimeZone);
	}

	String status = (String)mtg.getAttribute("Status")[0];
	String subject = (String)mtg.getAttribute("Subject")[0];
	String location = (String)mtg.getAttribute("Location")[0];
	if (location == null) location = "";
	String recurring = (String)mtg.getAttribute("Recurring")[0];

	// date
	Date start = (Date)mtg.getAttribute("StartDate")[0];
	Date expire = (Date)mtg.getAttribute("ExpireDate")[0];
	String startS = df.format(start);
	String expireS = df.format(expire);

	
	String meetingCategory = (String)mtg.getAttribute(meeting.CATEGORY)[0];
	String [] categories = (meetingCategory!=null)?meetingCategory.split(meeting.DELIMITER):null;
	
	// template type
	String type = request.getParameter("Type");
	// template name
	String templateName = request.getParameter("TemplateName");

	String tempType = "";
	String tempTName = "";
	if (categories!=null) {
		tempType=(categories.length>0)?categories[0].trim():"";
		//tempTName=(categories.length>1)?categories[1].trim():"";
	}

	if (type==null) type=tempType;
	if (templateName==null) templateName=tempTName;

	// get the list of template of this type (prefix is "Mtg_", e.g. Mtg_Simple)
	PstAbstractObject [] templates = null;
	projTemplateManager pjTMgr = projTemplateManager.getInstance();
	if (type.length() > 0)
	{
		int [] templateIds = pjTMgr.findId(pstuser, "Type='Mtg_" + type + "'");
		templates = pjTMgr.get(pstuser, templateIds);
	}

	// get the selected template
	String content = "";
	if (templateName.length() > 0)
	{
		projTemplate pjTempate = (projTemplate)pjTMgr.get(pstuser, templateName);
		Object cObj = pjTempate.getAttribute("Content")[0];
		content = (cObj==null)?"":new String((byte[])cObj);
	}

	// get agenda items
	if (content.length() <= 0)
	{
		Object [] agendaArr = mtg.getAttribute("AgendaItem");
		Arrays.sort(agendaArr, new Comparator <Object> ()
		{
			public int compare(Object o1, Object o2)
			{
				try{
				String [] sa1 = ((String)o1).split(meeting.DELIMITER);
				String [] sa2 = ((String)o2).split(meeting.DELIMITER);
				int i1 = Integer.parseInt(sa1[0]);	// pre-order
				int i2 = Integer.parseInt(sa2[0]);	// pre-order
				return (i1-i2);
				}catch(Exception e){
					return 0;}
			}
		});

		// use current agenda to create content in the text box
		String s, itemName, levelStr;
		String [] sa;
		int level;
		for (int i=0; i<agendaArr.length; i++)
		{
			s = (String)agendaArr[i];			// (order::level::item::duration::owner)
			if (s == null) break;
			sa = s.split(meeting.DELIMITER);
			level = Integer.parseInt(sa[2]);
			itemName = sa[3].replaceAll("@@", ":");

			levelStr = "";
			while (level-- > 0) levelStr += "*";
			if (levelStr != "")
				content += levelStr + " " + itemName + "\n";
			else
				content += "\n" + itemName + "\n";
		}
	}
	content = content.trim();

	////////////////////////////////////////////////////////
%>


<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../edit.jsp" flush="true"/>
<script language="JavaScript" src="../date.js"></script>
<script language="JavaScript">
<!--

function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

function validation()
{
	var e = updMtgAgenda.Agenda;

	if (e.value.indexOf("::") != -1)
	{
		fixElement(e, "You cannot use double-colon \(::\) in the Agenda.");
		return false;
	}
	return true;
}

//-->
</script>

<style type="text/css">
.plaintext {line-height:20px;}
</style>

</head>

<title><%=app%></title>
<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" height="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">
		<!-- Main Tables -->
		<table width="100%" border="0" cellspacing="0" cellpadding="0">
		  	<tr>
		    	<td width="100%" valign="top">
					<!-- Top -->
					<jsp:include page="../head.jsp" flush="true"/>
					<!-- End of Top -->
				</td>
			</tr>
			<tr>
	          <td>
	            <table width="100%" border="0" cellspacing="0" cellpadding="0">
				  <tr>
					<td width="26" height="30"><a name="top">&nbsp;</a></td>
                	<td height="30" align="left" valign="bottom" class="head">
                	<b>Update Meeting Agenda</b>
					</td></tr>
	            </table>
	          </td>
	        </tr>
	    </table>
	    <table width="90%" border="0" cellspacing="0" cellpadding="0">
			<tr>
          		<td width="100%">
<!-- Navigation Menu -->
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Event" />
				<jsp:param name="subCat" value="" />
				<jsp:param name="role" value="<%=iRole%>" />
			</jsp:include>
<!-- End of Navigation Menu -->
				</td>
	        </tr>
		</table>
<!-- Content Table -->

<table border="0" cellspacing="0" cellpadding="0">
<tr>
	<td width='30'><img src='../i/spacer.gif' border='0' width='30' height='1' /></td>
	<td width='200'></td>
	<td width='600'>&nbsp;</td>
</tr>

<!-- Subject -->
<tr>
	<td></td>
	<td class="plaintext"><b>Subject:</b></td>
	<td class="plaintext"><b><%=subject%></b></td>
</tr>

<!-- Location -->
<tr>
	<td>&nbsp;</td>
	<td class="plaintext"><b>Location:</b></td>
	<td class="plaintext"><%=location%></td>
</tr>

<!-- Start time -->
<tr>
	<td>&nbsp;</td>
	<td class="plaintext"><b>Start Time:</b></td>
	<td class="plaintext"><%=startS%>

<%
	if (recurring != null)
	{
		String [] sa = recurring.split(meeting.DELIMITER);
		out.print("&nbsp;&nbsp;&nbsp;(" + sa[0] + " event for <b>" + sa[1] + "</b> more occurrences)");
	}
%>
	</td>
</tr>

<!-- End time -->
<tr>
	<td></td>
	<td class="plaintext"><b>End Time:</b></td>
	<td class="plaintext"><%=expireS%></td>
</tr>

<tr><td><img src='../i/spacer.gif' height='20'/></td></tr>


<!-- Agenda and templates -->
<tr>
	<td></td>
	<td colspan="2">
<table border="0" cellspacing="0" cellpadding="0">

<tr>
<!-- left side table -->

<td valign="top">
<table border="0" cellspacing="0" cellpadding="0">
<!-- Choose Project Type -->
<form name="TemplateType">
<input type="hidden" name="mid" value="<%=midS%>" >
		<tr><td width='200' class="plaintext_blue">Type of Meeting:</td></tr>
		<tr><td class="plaintext_big">
		<select class="plaintext_big" name="Type" onChange="document.TemplateType.submit();">

<%
		String [] projTypeArray = {"Simple", "Business", "Financial", "Personal", "Product Management"};

		out.print("<option name='' value=''>-- select a type --");
		for(int i = 0; i < projTypeArray.length; i++)
		{
			out.print("<option name='" + projTypeArray[i] + "' value='" + projTypeArray[i] + "'");
			if (type.equals(projTypeArray[i]))
				out.print(" selected");
			out.println(">" + projTypeArray[i]);
		}
%>
		</select>
		</td></tr>
</form>

		<tr><td><img src="../i/spacer.gif" height="20" width="1" alt=" " /></td></tr>

<!-- Templates -->
<form name="TemplName">
<input type="hidden" name="mid" value="<%=midS%>" >
<input type="hidden" name="Type" value="<%=type%>" >
		<tr><td class="plaintext_blue">Agenda Template:</td></tr>
		<tr><td class="plaintext_big">
		<select class="plaintext_big" name="TemplateName" onChange="document.TemplName.submit();">
		<option selected name="" value="">-- select a template --

<%
		if (templates != null)
		{
			for(int i = 0; i < templates.length; i++)
			{
				String aName = templates[i].getObjectName();
				out.print("<option name='" + aName + "' value='" + aName + "'");
				if (aName.equals(templateName))
					out.print(" selected");
				out.println(">" + aName.substring(4));	// skip Mtg_
			}
		}
%>
		</select>
		</td></tr>
</form>
</table>
</td>
<!-- end left side table -->


<!-- Textbox Agenda -->
<form method="post" name="updMtgAgenda" action="mtg_upd_agenda2.jsp">
<input type="hidden" name="mid" value="<%=midS%>" >
<input type="hidden" name="Type" value="<%=type %>">
<input type="hidden" name="TemplateName" value="<%=templateName %>">

<!-- right side table -->
<td>
<table border="0" cellspacing="0" cellpadding="0">
		<tr><td class="plaintext_blue">Edit Agenda:
				<span class="tinytype">(note: "*" is used to denote sub-item levels)</span>
			</td>
			<td align="right">
				<input type="button" class="button" value=" Add Link " onClick="wrapIt('l')">
			</td>
		</tr>
		<tr>
			<td colspan='2'>
				<textarea name="Agenda" rows="15" style='width:600px;'
					wrap="auto"
					OnSelect="storeCaret(this);"><%=content%></textarea>			
		</td></tr>
</table>
</td>
<!-- end right side table -->
</tr>

<!-- Submit Button -->
	<tr>
	<td colspan="3" align="center"><br>
		<input type="Button" class="button_medium" value="  Reset  " onclick="location='mtg_upd_agenda1.jsp?mid=<%=midS%>'">&nbsp;
		<input type="Submit" class="button_medium" name="Submit" value="  Next >>  " onClick="return validation();">
	</td>
	</tr>
</form>

</table>
		<!-- End of Content Table -->


	</td>
</tr>

</table>
</td></tr>

		<!-- End of Main Tables -->


<tr>
	<td>
		<!-- Footer -->
		<jsp:include page="../foot.jsp" flush="true"/>
		<!-- End of Footer -->
	</td>
</tr>
</table>
</body>
</html>
