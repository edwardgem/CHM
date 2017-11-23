<%@ page contentType="text/html; charset=utf-8"%>

<%
//
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	proj_new2.java
//	Author: ECC
//	Date:		04/17/2004
//	Description:	Create a new project.
//	Modification:
//		@ECC011707	Support Department Name in project, task and attachment for authorization.
//		@ECC060407	Support more flexible attachment authorization using department name combination.
//		@ECC090508	Add owner id to project name to avoid collision.
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "oct.util.file.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	// Step 2 of 3: construct project plan
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	String townName = request.getParameter("TownName");
	if ((pstuser instanceof PstGuest) || (townName == null))
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	String townIdS = request.getParameter("TownID");
	
	// to check if session is CR
	boolean isCRAPP = false;
	String app = (String)session.getAttribute("app");
	if (app.indexOf("CR")!=-1)
		isCRAPP = true;

	String label1 = "Plan";
	if (isCRAPP)
		label1 = "Space";
	
	String s;
	String projDispName = request.getParameter("ProjName");
	if (projDispName != null && projDispName.length() > 0) projDispName = projDispName.replaceAll("\\\\", "");
	String projName = projDispName + "@@" + pstuser.getObjectId();	// @ECC090508
	String desc = request.getParameter("Description");
	String start = request.getParameter("StartDate");
	String expire = request.getParameter("ExpireDate");
	String option = request.getParameter("ProjectOption");
	
	int myUid = pstuser.getObjectId();
	String myUidS = String.valueOf(myUid);
	
	String deptName = "";
	String [] deptNames = request.getParameterValues("Departments");		// @ECC060407
	if (deptNames==null || deptNames.length<=0)
	{
		// might be a reload
		deptName = request.getParameter("Department");
		if (deptName == null) deptName = "";
	}
	else for (int i = 0; i<deptNames.length; i++)
	{
		if (deptName.length() > 0) deptName += "@";
		deptName += deptNames[i];
	}

	// check duplicate name
	try
	{
		projectManager.getInstance().get(pstuser, projName);
		response.sendRedirect("../out.jsp?msg=The project name <u>" +projDispName+ "</u> has already been used.  Please choose another project name");
		return;
	}
	catch (PmpException e)
	{
		// good, since I can't find this name yet, let's keep going
	}

	// template type
	String type = request.getParameter("Type");
	if (type == null) type = "Administration";	// default type

	// template name
	String templateName = request.getParameter("TemplateName");
	if (templateName == null)
	{
		/*if (type.equals("Administration")) templateName = "Default";
		else templateName = "";*/
		templateName = "";
	}

	// get the list of template of this type
	PstAbstractObject [] templates = null;
	projTemplateManager pjTMgr = projTemplateManager.getInstance();
	int [] templateIds = pjTMgr.findId(pstuser, "Type='" + type + "'");
	templates = pjTMgr.get(pstuser, templateIds);
	Util.sortName(templates);
	for (int i=0; i<templates.length; i++)
	{
		s = (String)templates[i].getAttribute("Owner")[0];
		if (s!=null && !s.equals(myUidS))
			templates[i] = null;			// not my template
	}
	if (templateName.length()<=0)
		for (int i=0; i<templates.length; i++)
		{
			if (templates[i] == null) continue;
			templateName = templates[i].getObjectName();
			break;			// just get the first one's name
		}

	// get the selected template
	projTemplate pjTempate = null;
	String content = "";
	if (templateName.length() > 0)
	{
		pjTempate = (projTemplate)pjTMgr.get(pstuser, templateName);
		Object cObj = pjTempate.getAttribute("Content")[0];
		content = (cObj==null)?"":new String((byte[])cObj, "utf-8");
	}
	
	boolean isTemplateOwner = templateName.endsWith(myUidS);
	if (isTemplateOwner && request.getParameter("del")!=null) {
		// remove this template
		pjTMgr.delete(pjTempate);
		response.sendRedirect("../out.jsp?msg=Template has been removed successfully.&go=ep/ep_home.jsp");
		return;
	}

	// do not perform the create until the last step, make sure the user has credit to create
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="../init.jsp" flush="true"/>

<script language="JavaScript">
<!--

function delTemplate()
{
	if (confirm("This action is non-recoverable. Do you really want to delete this template?")) {
		var loc = parent.document.URL;
		location = addURLOption(loc, "del=1");
	}
	return;
}

//-->
</script>

<title>
	Create a New Project <%=label1%>
</title>

</head>

<body text="#000000" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="100%" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<b class="head">

	&nbsp;&nbsp;Create a New Project <%=label1%>

	</b><br><br>
	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- CONTENT -->
<table width='100%'>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="instruction_head"><br><b>Step 2 of 3: Specify a Project <%=label1%></b></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_big">
		<br>
		<u>To specify a <%=label1%></u> for the project, simply choose from below the <u>Type of Project</u> you are
		creating, and select from the <u>Project <%=label1%> Templates</u>.  After making these choices,
		you may further modify the <u>Project <%=label1%></u>.  The project <%=label1%> can be
		changed even after you have published and worked on the project.

		<p>When you are satisfied with the project <%=label1%>, click the <b>Next Button</b> to
		preview the <%=label1%> layout.

		<br><br></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>

		<td>

<!-- Content -->
<table width='100%'>

<!-- Project Plan widgets -->
	<tr>

	<td valign="top">
		<table>

<!-- Choose Project Type -->
<form name="TemplateType" method='post'>
<input type="hidden" name="TownName" value="<%=townName%>" >
<input type="hidden" name="TownID" value="<%=townIdS%>" >
<input type="hidden" name="ProjName" value="<%=Util.stringToHTMLString(projDispName)%>" >
<input type="hidden" name="Department" value="<%=deptName%>" >
<input type="hidden" name="Description" value="<%=Util.stringToHTMLString(desc)%>" >
<input type="hidden" name="StartDate" value="<%=start%>" >
<input type="hidden" name="ExpireDate" value="<%=expire%>" >
<input type="hidden" name="ProjectOption" value="<%=option%>" >
		<tr><td class="plaintext_blue">Type of Project:</td></tr>
		<tr><td class="plaintext_big">
		<select class="plaintext_big" name="Type" onChange="document.TemplateType.submit();">

<%
		// Simple; Marketing; Design Engineering; Product Engineering; Product Testing; Manufacturing
		String [] projTypeArray;
		String [] simpleTypeArr = {"Administration", "Customer", "Financial", "Product & Service", "Sales & Marketing",
				"Electronics Engineering", "Software Engineering", "Other Engineering"};	// same as in nre_templ1.jsp
		s = Util.getPropKey("pst", "COMPANY_TYPE");
		if (s==null || s.equalsIgnoreCase("simple"))
			projTypeArray = simpleTypeArr;
		else
		{
			String [] sa = s.split(";");
			projTypeArray = new String[sa.length];
			for (int i=0; i<sa.length; i++)
				projTypeArray[i] = sa[i].trim();
		}
		// String [] projTypeArray = {"Simple", "Marketing", "Design Engineering", "Product Engineering", "Product Testing", "Manufacturing"};

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
<form name="TemplName" method='post'>
<input type="hidden" name="TownName" value="<%=townName%>" >
<input type="hidden" name="TownID" value="<%=townIdS%>" >
<input type="hidden" name="ProjName" value="<%=Util.stringToHTMLString(projDispName)%>" >
<input type="hidden" name="Department" value="<%=deptName%>" >
<input type="hidden" name="Description" value="<%=Util.stringToHTMLString(desc)%>" >
<input type="hidden" name="StartDate" value="<%=start%>" >
<input type="hidden" name="ExpireDate" value="<%=expire%>" >
<input type="hidden" name="ProjectOption" value="<%=option%>" >
<input type="hidden" name="Type" value="<%=type%>" >
		<tr><td class="plaintext_blue">Project <%=label1%> Template:</td></tr>
		<tr><td class="plaintext_big">
		<select class="plaintext_big" name="TemplateName" onChange="document.TemplName.submit();">
		<option selected value="">-- select a template --

<%
		int idx;
		if (templates != null)
		{
			for(int i = 0; i < templates.length; i++)
			{
				if (templates[i] == null) continue;
				String aName = templates[i].getObjectName();
				s = (String)templates[i].getAttribute("Owner")[0];
				if (s!=null && Integer.parseInt(s)!=myUid)
					continue;
				String displayName = aName;
				if ((idx = aName.indexOf("@@")) != -1)
					displayName = aName.substring(0, idx);
				out.print("<option value='" + aName + "'");
				if (aName.equals(templateName) || i==0)
					out.print(" selected");
				out.println(">" + displayName);
			}
		}
%>
		</select>
		</td></tr>
</form>

		</table>
	</td>

<!-- Textbox Project Plan -->
<form method="post" name="newProject" action="proj_new3.jsp">
	<td width='75%'>
		<table width='90%' border='0' >
		<tr><td colspan='2' class="plaintext_blue">Edit Project <%=label1%> Layout:
			<span class="tinytype">(note: "*" is used to denote subtask levels)</span></td></tr>
		<tr><td>
			<textarea name="Plan" rows="15" style='width:100%' wrap="off"><%=content%></textarea>
			</td>
			<td width='200'  valign='top' align='left' class='plaintext_big'>
<% if (isTemplateOwner) { %>
				You are the owner of this template<br>
				<input type='button' class='button_medium' onclick='delTemplate();' value='Delete Template';>
<%	} %>
			</td>
		</tr>
		</table>
	</td>

	</tr>
<!-- End Project Plan widgets -->

<!-- Submit Button -->
<input type="hidden" name="TownName" value="<%=townName%>" >
<input type="hidden" name="TownID" value="<%=townIdS%>" >
<input type="hidden" name="ProjName" value="<%=Util.stringToHTMLString(projDispName)%>" >
<input type="hidden" name="Department" value="<%=deptName%>" >
<input type="hidden" name="Description" value="<%=Util.stringToHTMLString(desc)%>" >
<input type="hidden" name="StartDate" value="<%=start%>" >
<input type="hidden" name="ExpireDate" value="<%=expire%>" >
<input type="hidden" name="ProjectOption" value="<%=option%>" >
	<tr>
	<td colspan="2" align="center"><br>
		<input type="Button" value="  << Prev  " onclick="history.back(-1)">&nbsp;
		<input type="Submit" name="Submit" value="  Next >>  ">
	</td>
	</tr>
</form>

</table>
<!-- End Content -->

		</td>
	</tr>

</table>


	</td>
</tr>

<tr><td>&nbsp;</td><tr>


<!-- BEGIN FOOTER TABLE -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>
