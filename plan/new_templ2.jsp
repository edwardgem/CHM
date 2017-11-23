<%@ page contentType="text/html; charset=utf-8"%>

<%
//
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: new_templ2.jsp
//	Author: ECC
//	Date:	10/10/04
//	Description: Save a project template
//	Modification:
//				@ECC011608	Support quest.
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "util.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.util.regex.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp?" />

<%!
	// should put this in project.java
%>

<%
	// Step 2 of 2: review and save project plan into template database
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	boolean isAdmin = ((iRole & user.iROLE_ADMIN) > 0);

	String label1 = null;
	boolean isCRAPP = false;
	boolean isOMFAPP = false;
	String app = (String)session.getAttribute("app");
	if (app.indexOf("CR")!=-1 || app.equals("PRM"))
		isCRAPP = true;
	else if (app.equals("OMF"))
		isOMFAPP = true;

	String templateType = request.getParameter("TemplateType");
	String templateName = request.getParameter("TemplateName");
	String newTemplName = request.getParameter("NewTemplName");
	String planString = Util.stringToHTMLString(request.getParameter("Plan"));
	String qidS = request.getParameter("qid");
	String s;
	String prefix = "";
	boolean isUpdate=false, isQuest=false, isEvent=false;

	s = templateName;
	Vector rAgenda = null;
	if (isOMFAPP)
	{
		templateName = s.substring(4);
		prefix = s.substring(0,4);
		if (s.startsWith("Mtg_"))
			label1 = "Meeting";
		else
		{
			isQuest = true;
			if (s.startsWith("Evt_"))
			{
				isEvent = true;
				label1 = "Event/Party Invitation";
			}
			else
				label1 = "Questionnaire/Survey/Vote";

			// begin setting up questions
			try {rAgenda = JwTask.getAgendaVector(planString);}
			catch (PmpException e)
			{
				String msg = e.toString();
				response.sendRedirect("../out.jsp?msg="+ msg);
			}
			// end of setting up questions
		}
	}
	else
		label1 = "Project";


	String displayName = "";
	String uidStr = "";
	String name = null;
	String update = request.getParameter("Update");
	if (update.equals("true"))
	{
		int idx;
		name = templateName;
		if ((idx = name.indexOf("@@")) != -1) {
			displayName = name.substring(0, idx);		// take only the name
			uidStr = " (" + name.substring(idx+2) + ")";	// userId
			if (!isAdmin)
				name = displayName;						// take only the name
			else {
				// I am admin, need to pass the @@uid so that I can find this template
				// and then change the name.  So, don't take out the @@uid
			}
		}
		isUpdate = true;
	}
	else
	{
		name = displayName = newTemplName;

		// create new template, check duplicate name
		try
		{
			String fullName = prefix + name;
			//if (isCRAPP)
			fullName += "@@" + pstuser.getObjectId();
			projTemplateManager.getInstance().get(pstuser, fullName);
			response.sendRedirect("../out.jsp?msg=The template name \"<b>" +name+ "</b>\" has already been used.  Please choose another template name");
			return;
		}
		catch (PmpException e)
		{
			// good, since I can't find this name yet, let's keep going
		}
	}

	// begin setting up plan stack

	// Plan is represented by a Vector of Task
	// Task is represented by a hashtable.
	Stack planStack = null;
	Vector rPlan = new Vector();

	// process the plan script to create a list of JwTask
	JwTask [] taskArray = null;
	try
	{
		JwTask jw = new JwTask();
		taskArray = jw.processScript(planString);
	}
	catch (PmpException e)
	{
		StringTokenizer st = new StringTokenizer(e.toString(), ":");
		st.nextToken();
		String msg = st.nextToken();
		msg += ": \"<b>" + st.nextToken() + "</b>\"";
		response.sendRedirect("../out.jsp?msg="+ msg);
		return;
	}
	int i = 0;
	while (true)
	{
		// pTask is the persistent Task
		// rTask is the ram task which is in cache
		if (taskArray[i] == null) break;

		JwTask pTask = taskArray[i++];
		Hashtable rTask = new Hashtable();
		rTask.put("Order", pTask.getOrder());
		rTask.put("Level", pTask.getLevel());
		rTask.put("Name", pTask.getName());
		rTask.put("ParentID", pTask.getParentId());
		rPlan.addElement(rTask);
	}

	planStack = new Stack();
	planStack.push(rPlan);

// end of setting up plan stack

%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>

<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">

<jsp:include page="../init.jsp" flush="true"/>

<script language="JavaScript">
<!--
function affirm()
{
	return true;
}

function goback()
{
	SaveTemplate.action = "new_templ1.jsp";
	SaveTemplate.submit();
}
//-->
</script>


<title>
	<%=app%> Save a <%=label1%> Template
</title>

</head>

<body text="#000000" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="715" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<b class="head">

	&nbsp;&nbsp;Save a <%=label1%> Template

	</b><br><br>
	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="..../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>


<!-- Content Table -->
 <table width="800" border="0" cellspacing="0" cellpadding="0">
	<tr>
		<td width="15">&nbsp;</td>
		<td class="instruction_head"><br><b>Step 2 of 2: Review and Save the <%=label1%> Template</b></td>
	</tr>

	<tr>
		<td width="15"><img src="../i/spacer.gif" width="15" border="0"></td>
		<td class="plaintext_big">
			<br><br>
			<table width="100%" border="0" cellspacing="0" cellpadding="0">
			<tr><td>
				<table>
					<tr>
					<td class="plaintext_blue" width="250"><%=label1%> Type:</td>
					<td class="plaintext_big"><b><%=templateType%></b></td>
					</tr>

					<tr>
					<td class="plaintext_blue">Template Name:</td>
					<td class="plaintext_big"><b><%=displayName%><%=uidStr%></b></td>
					</tr>
				</table>
			</td></tr>

			<tr><td>&nbsp;</td></tr>
			<tr>
				<td>
<%

	if (!isQuest)
	{
		String[] levelInfo = new String[10];
		String prelevelInfo = "";

		out.println("<table width='100%' border='0' cellspacing='0' cellpadding='0' >");
		out.print("<tr><td colspan='2'></td>");
		out.print("<td colspan='4'class='formtext_small'>(To change the dependencies, update the previous page)</td>");
		out.print("</tr>");
		out.print("<tr>");
		out.print("<td class='plaintext_big' width='400'><img src='../i/spacer.gif' width='10'/>");
		out.print("<b>Task Name</b></td>");
		out.print("<td><img src='../i/spacer.gif' width='15' height='1'/></td>");	// vertical gap
		out.print("<td class='plaintext_big'><b>Dependencies</b></td>");
		out.print("<td class='plaintext_big'><b>Phase/Subphase</b></td>");
		out.print("</tr>");

		out.print("<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>");
		
		for(i = 0; i < rPlan.size(); i++)
		{
			Hashtable rTask = (Hashtable)rPlan.elementAt(i);
			String pName = (String)rTask.get("Name");
			Integer pLevel = (Integer)rTask.get("Level");
			Integer pOrder = (Integer)rTask.get("Order");
			Integer pPreOrder = (Integer)rTask.get("PreOrder");

			int level = pLevel.intValue();
			int order = pOrder.intValue();

			int width = 10 + 22 * level;
			order++;
			if (level == 0) {
				levelInfo[level] = Integer.toString(order);
			}
			else {
				levelInfo[level] = levelInfo[level - 1] + "." + order;
			}

			if (level == 0) {
				out.print("<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>");
			}
			out.print("<tr><td width='400'><table border='0' cellspacing='0' cellpadding='0'>");
			out.println("<tr><td width='" + width + "'><img src='../i/spacer.gif' width='" + width + "' height='2' border='0'></td><td class='plaintext'>");
			out.println(levelInfo[level] + "&nbsp;&nbsp;" + pName);
			out.println("</td></tr>");
			out.print("</table></td>");

			// vertical gap
			out.print("<td></td>");

			// get the dependency values from template if any
			String depStr = project.lookUpDependency(planString, levelInfo[level]);
			out.print("<td valign='top'><input type='text' disabled name='Depend_"
					+ levelInfo[level] + "' class='plaintext' size='25' value='" + depStr + "'></td>");
			
			// get the phase subphase values from template if any		
			depStr = project.lookUpPhase(planString, levelInfo[level], null);
			out.print("<td valign='top'><input type='text' disabled name='Phase_"
					+ levelInfo[level] + "' class='plaintext' size='25' value='" + depStr + "'></td>");

			out.print("</tr>");
		}
		out.println("</table>");
	}
	else
	{
		out.println("<table width='100%' border='0' cellspacing='0' cellpadding='0'><tr>");
		out.print("<td valign='top'><img src='../i/spacer.gif' width='10' /></td>");
		out.println("<td valign='top'><table width='100%' border='0' cellspacing='0' cellpadding='0'>");
		out.println(JwTask.printQuest(rAgenda, null, 0, null, null));	// no need to initialize summary
	}


%>

							</td>
						</tr>
				</table>
				</td>
			</tr>

		</table>
<form method="post" name="SaveTemplate" action="post_newtempl.jsp">
<input type="hidden" name="qid" value="<%=qidS%>" >
<input type="hidden" name="TemplateType" value="<%=templateType%>" >
<input type="hidden" name="TemplateName" value="<%=name%>" >
<input type="hidden" name="NewTemplName" value="<%=newTemplName%>" >
<input type="hidden" name="Content" value="<%=planString%>" >
<input type="hidden" name="isUpdate" value="<%=update%>" >
<input type="hidden" name="Update" value="<%=update%>" >

<table width="715" border="0" cellspacing="0" cellpadding="2">
  <tr>
    <td width="15" align="right"><img src="../i/spacer.gif" border="0" width="15" height="1"></td>
    <td width="700">&nbsp;</td>
  </tr>
  <tr>
  	<td>&nbsp;</td>
    <td class="plaintext_big">
		Click the <b>Save Button</b> to save the template into the template library.
		To make any changes, click "<< Prev" to go back to the previous page.
	</td>
  </tr>
  <tr>
    <td>&nbsp;</td>
    <td width="100%" valign="top">
		<table width="715" border="0" cellspacing="0" cellpadding="2">
		  <tr>
		    <td colspan="2">&nbsp;</td>
		  </tr>
		  <tr>
		    <td colspan="2" align="center">
				<input type="Button" value="<< Prev" onclick="goback()">&nbsp;
				<input type="Submit" name="Submit" value=" Save " onClick="return affirm()";>

		    </td>
		  </tr>
		</table>
	</td>
  </tr>
</table>

 </form>
  <!-- End of Content Table -->
		<!-- End of Main Tables -->
	</td>
</tr>

<!-- Footer -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- End of Footer -->

</table>
</body>
</html>
