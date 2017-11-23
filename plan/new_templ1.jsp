<%@ page contentType="text/html; charset=utf-8"%>

<%
//
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	new_templ1.jsp
//	Author: ECC
//	Date:		10/17/2004
//	Description:	Save a project plan to the template database.
//	Modification:
//				@ECC011608	Support quest.
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
	// Step 1 of 2: update project plan
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	PstUserAbstractObject me = pstuser;
	if (me instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	int myUid = me.getObjectId();

	int iRole = ((Integer) session.getAttribute("role")).intValue();
	boolean isAdmin = ((iRole & user.iROLE_ADMIN) > 0);

	// @ECC011608
	String qidS = request.getParameter("qid");
	PstAbstractObject qObj;
	boolean isQuest = false;			// can be event or questionnaire
	boolean isEvent = false;			// it is event

	String s;
	taskManager tkMgr = taskManager.getInstance();
	projectManager pjMgr = projectManager.getInstance();
	projTemplateManager pjTMgr = projTemplateManager.getInstance();
	questManager qMgr = questManager.getInstance();
	phaseManager phMgr = phaseManager.getInstance();

	String label1 = null;	// this is just a label
	String type=null, templateName=null, content=null;
	String backPage=null;

	boolean bUpdateTemplate = false;
	s = request.getParameter("isUpdate");
	if (s!=null && s.equals("true"))
		bUpdateTemplate = true;

	String projIdS = null;
	boolean isCRAPP = Prm.isCR();
	boolean isPRMAPP = Prm.isPRM();
	boolean isOMFAPP = Prm.isOMF();
	if (isCRAPP || isPRMAPP)
	{
		label1 = "Project";
		backPage = "location='../project/proj_profile.jsp';";
		projIdS = request.getParameter("projId");
		if (projIdS == null)
			projIdS = (String)session.getAttribute("projId");
	}
	else if (isOMFAPP)
	{
		isOMFAPP = true;
		if (qidS == null)
		{
			label1 = "Meeting";
			backPage = "history.back(-1)";
		}
		else
		{
			isQuest = true;
			qObj = qMgr.get(me, qidS);
			s = (String)qObj.getAttribute("Type")[0];
			if (s.indexOf(quest.TYPE_EVENT) != -1)
			{
				isEvent = true;
				label1 = "Event/Party Invitation";
			}
			else
				label1 = "Questionnaire/Survey/Vote";

			// extract the category
			s = (String)qObj.getAttribute("Category")[0];
			String [] sa = s.split(quest.DELIMITER);
			templateName = sa[1];
			if (isEvent)
				type = "Evt_" + sa[0];
			else
				type = "Qst_" + sa[0];

			// get questions
			if (!bUpdateTemplate)
			{
				Object bTextObj = qObj.getAttribute("Content")[0];
				content = (bTextObj==null)? "" : new String((byte[])bTextObj, "utf-8");
			}

			backPage = "location='../question/q_answer.jsp?qid=" + qidS + "'";
		}
	}

	if (!bUpdateTemplate)
	{
		s = request.getParameter("Update");		// from saveTemplateForm
		if (s!=null && s.equals("true")) bUpdateTemplate = true;
	}

	if (!isQuest)
	{
		type = request.getParameter("TemplateType");
		templateName = request.getParameter("TemplateName");
		content = request.getParameter("Content");
	}

	// template type
	if (type == null)
	{
		if (projIdS == null)
			type = "Simple";
		else
			type = "Administration";
	}

	// template name
	if (templateName == null)
	{
		if (type.equals("Simple") && projIdS==null) templateName = "Default";
		else templateName = "";
	}
	if (isOMFAPP && !isQuest && templateName.length()>0 && !templateName.startsWith("Mtg_"))
		templateName = "Mtg_" + templateName;

	String newTemplName = request.getParameter("NewTemplName");
	if (newTemplName == null)
		newTemplName = "";

	// get the list of template of this type
	PstAbstractObject [] templates = null;
	int [] templateIds = null;

	if (isOMFAPP && !isQuest)
		templateIds = pjTMgr.findId(me, "Type='Mtg_" + type + "'");
	else if (isQuest)
	{
		if (isEvent)
			templateIds = pjTMgr.findId(me, "Type='Evt_" + type + "'");
		else
			templateIds = pjTMgr.findId(me, "Type='Qst_" + type + "'");
	}
	else
	{
		// CR
		String ownerIdS;
		if (isAdmin)
			ownerIdS = "%";
		else
			ownerIdS = String.valueOf(pstuser.getObjectId());
System.out.println("own=" + ownerIdS);		
		templateIds = pjTMgr.findId(me, "Type='" + type + "' && Owner='" + ownerIdS + "'");
	}
System.out.println("len=" + templateIds.length);

	templates = pjTMgr.get(me, templateIds);

	// there might be a content if the user press Prev from the next screen
	if (content == null) content = "";

	// (code from updplan.jsp)
	// Get plan task (stack is constructed first time when going into a plan)
	boolean bSavingCurrentProj = false;
	project pj = null;
	task tk;
	HashMap<String,String> taskMap = new HashMap<String,String>();

	if (templateName.length()>0 && content.length()<=0 )
	{
		projTemplate pjTempate = (projTemplate)pjTMgr.get(me, templateName);
		Object cObj = pjTempate.getAttribute("Content")[0];
		content = (cObj==null)?"":new String((byte[])cObj, "utf-8");
	}
	else if (!isOMFAPP)
	{
		// for PRM/CR
		bSavingCurrentProj = true;
		Stack planStack = (Stack)session.getAttribute("planStack");
		if((planStack == null) || planStack.empty())
		{
			response.sendRedirect("../out.jsp?msg=Internal error in opening plan stack.  Please contact administrator.");
			return;
		}
		Vector rPlan = (Vector)planStack.peek();

		String [] levelStar = new String[JwTask.MAX_LEVEL];
		String [] levelInfo = new String[JwTask.MAX_LEVEL];
		long start, expire;
		int length, startDist;
		String tidS;

		if (projIdS != null)
			pj = (project)pjMgr.get(me, Integer.parseInt(projIdS));
		else
			pj = (project)pjMgr.get(me, (String)session.getAttribute("projName"));
		Date pjStartDt = pj.getStartDate();
		long pjStart = pjStartDt.getTime();

		for(int i = 0; i < rPlan.size(); i++)
		{
			Hashtable rTask = (Hashtable)rPlan.elementAt(i);
			String status = (String)rTask.get("Status");
			if (status.charAt(0) == 'D')
				continue;

			tidS = (String)rTask.get("TaskID");
			String pName = (String)rTask.get("Name");
			Object [] pLevel = (Object [])rTask.get("Level");
			Object [] pOrder = (Object [])rTask.get("Order");
			//Object [] pPreOrder = (Object [])rTask.get("PreOrder");
			//Object [] pPlanID = ptargetObj.getAttribute("PlanID");

			int level = ((Integer)pLevel[0]).intValue();
			int order = ((Integer)pOrder[0]).intValue() + 1;

			if (level == 0) {
				levelStar[level] = "";
				levelInfo[level] = String.valueOf(order);
			}
			else {
				levelStar[level] = levelStar[level - 1] + "*";
				levelInfo[level] = levelInfo[level - 1] + "." + order;
			}

			// remember taskId and header# map for building dependencies later
			taskMap.put(tidS, levelInfo[level]);

			// calculate the length and start date (from pj start date) of the task
			tk = (task)tkMgr.get(me, tidS);
			if (isCRAPP || isPRMAPP)
			{
				//start = ((Date)tk.getAttribute("StartDate")[0]).getTime();
				//expire = ((Date)tk.getAttribute("ExpireDate")[0]).getTime();
				startDist = ((Integer)tk.getAttribute("Gap")[0]).intValue();
				Date tkStartDt = tk.getStartDate();
				if (startDist<=0 && tk.isTopLevel(me) && tkStartDt!=null) {
					// figure out gap for top level tasks; for non-top task, assume no gap
					startDist = task.getDaysDiff(tkStartDt, pjStartDt);
				}
				length = ((Integer)tk.getAttribute("Duration")[0]).intValue();
				if (length==0 && tk.getStartDate()!=null) {
					// if StartDate is not null, calculate the Length
					length = task.getDaysDiff(tk.getExpireDate(), tk.getStartDate());
				}
				if (length <= 0) length = 1;
			}
			else
			{
				start = expire = 0;
				startDist = length = 0;
			}
			content += (levelStar[level]==""?"\n":(levelStar[level] + " ")) + pName;
			if (startDist!=0 || length!=0)
			{
				content += "::" + startDist + "," + length;
			}
			content += "\n";
		}
	}

	StringBuffer sBuf = new StringBuffer(8192);
	if (bSavingCurrentProj || content.length() <= 0)
	{
		// construct the project plan text
		if (pj != null)
			sBuf.append("# Project plan of " + pj.getDisplayName() + "\n");
		else
			sBuf.append("# Sample plan name\n");
		sBuf.append("# Author: " + ((user)me).getFullName() + "\n");
		sBuf.append("# Date: " + new Date() + "\n");
		sBuf.append("# ----------------------------------\n\n");
		sBuf.append(content);
	}

	// construct the dependencies and phase comment if any
	if (taskMap.size() > 0) {
		String key, depLine;
		int [] ids = tkMgr.findId(pstuser, "Dependency='%'");
		sBuf.append("\n\n");
		
		// dependency
		sBuf.append("# Begin: CPM system generated dependencies\n");
		for (int i=0; i<ids.length; i++) {
			if ((key = taskMap.get(String.valueOf(ids[i]))) == null)
				continue;		// not in the hash map

			// check dependencies
			depLine = "";
			tk = (task)tkMgr.get(pstuser, ids[i]);
			Object [] depArr = tk.getAttribute("Dependency");
			for (int j=0; j<depArr.length; j++) {
				if (depLine.length() > 0) depLine += ",";
				depLine += taskMap.get((String)depArr[j]);
			}
			depLine = "# @Dep " + key + ":" + depLine + "\n";		// "# @Dep 1.3:"
			sBuf.append(depLine);
		}
		sBuf.append("# End: CPM system generated dependencies\n");
		
		// phase
		PstAbstractObject ph;
		String tkIdS, tkHeader, color;
		int mainPhaseNum;
		ids = phMgr.findId(pstuser, "ProjectID='" + projIdS + "' && ParentID=null");
		sBuf.append("\n\n");
		sBuf.append("# Begin: CPM system generated phase definition\n");
		for (int i=0; i<ids.length; i++) {
			depLine = "";
			ph = phMgr.get(pstuser, ids[i]);
			tkIdS = ph.getStringAttribute("TaskID");
			tkHeader = taskMap.get(tkIdS);
			mainPhaseNum = ph.getIntAttribute("PhaseNumber");
			color = ph.getStringAttribute("Color");
			if (StringUtil.isNullOrEmptyString(color) || color.charAt(0)!='#') color = "";
			depLine = "# @Phase " + mainPhaseNum + ":" + tkHeader
							+ ":" + color + "\n";
			sBuf.append(depLine);
			
			// subphases
			int [] ids1 = phMgr.findId(pstuser, "ParentID='" + ids[i] + "'");
			for (int j=0; j<ids1.length; j++) {
				ph = phMgr.get(pstuser, ids1[j]);
				tkIdS = ph.getStringAttribute("TaskID");
				tkHeader = taskMap.get(tkIdS);
				color = ph.getStringAttribute("Color");
				if (color == null) color = "";
				depLine = "# @Subphase " + mainPhaseNum + "." + ph.getIntAttribute("PhaseNumber") + ":" + tkHeader
							+ ":" + color + "\n";
				sBuf.append(depLine);
			}
		}
		
		sBuf.append("# End: CPM system generated phase definition\n");
	}

	if (sBuf.length() > 0) {
		content = sBuf.toString();
	}

	// do not perform the create until the last step, make sure the user has credit to create
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<script language="JavaScript">
<!--

function foundBadChar(str)
{
	for (i=0;i<str.length;i++)
	{
		char = str.charAt(i);
		if (char == '\"' || char == '\\' || char == '~'
				|| char == '`' || char == '!' || char == '#' || char == '$'
				|| char == '%' || char == '^' || char == '*' || char == '('
				|| char == ')' || char == '+' || char == '=' || char == '['
				|| char == ']' || char == '{' || char == '}' || char == '|'
				|| char == '>' || char == '<' || char == '?')
		{
			return true;	// bad
		}
	}
	return false;			// good
}

function checkUpdate()
{
	var bUpdate = TemplateTypeForm.Update[0].checked;
	document.TemplateTypeForm.TemplateName.disabled = !bUpdate;
	document.TemplateTypeForm.NewTemplName.disabled = bUpdate;
}

function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

function validation()
{
	var newTmplName = TemplateTypeForm.NewTemplName.value
	if (foundBadChar(newTmplName))
	{
		fixElement(TemplateTypeForm.NewTemplName,
			"TEMPLATE NAME cannot contain these characters: \n  \" \\ ~ ` ! # $ % ^ * ( ) + = [ ] { } |  ? > <");
		return false;
	}
	if (TemplateTypeForm.Update[0].checked == true)
	{
		saveTemplateForm.Update.value = 'true';
		saveTemplateForm.TemplateName.value = TemplateTypeForm.TemplateName.value;
	}
	else
	{
		if (document.TemplateTypeForm.NewTemplName.value == "")
		{
			alert("Please enter the NEW TEMPLATE NAME");
			document.TemplateTypeForm.NewTemplName.focus();
			return false;
		}
		saveTemplateForm.NewTemplName.value = newTmplName;
	}
	return true;
}

function changeTmplType()
{
	// user just click to change the template type
	var bUpdate = TemplateTypeForm.Update[0].checked;
	if (bUpdate)
	{
		TemplateTypeForm.isUpdate.value = 'true';
		TemplateTypeForm.submit();
	}
	else
	{
		saveTemplateForm.TemplateType.value = TemplateTypeForm.TemplateType.value;
		return;				// this is to create a new template, don't change anything
	}
}
//-->
</script>

<title>
	<%=Prm.getAppTitle()%> Save <%=label1%> Template
</title>

</head>

<body text="#000000" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="90%" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<b class="head">
	&nbsp;&nbsp;Save <%=label1%> Template

	</b><br><br>
	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- CONTENT -->
<table width='90%' border='0'>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="instruction_head" colspan='2'><br><b>Step 1 of 2: Specify a <%=label1%> Template</b></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_big" colspan='2'>
		<br>
		<u>To save a <%=label1%> Template</u> to the template library, first choose from below the
		<u>Type of <%=label1%></u> this plan is about, then either select from the <u><%=label1%> Plan Templates</u>
		the name of the template you want to update, or create a new template by giving it a new template
		name.

		<p>When you are satisfied with the <%=label1%> Plan, click the <b>Next Button</b> to
		preview the result.

		<br><br></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>

		<td width='20%'>

<!-- Content -->
<table border="0" width='100%'>

<!-- Project Plan widgets -->
	<tr>

	<td valign="top">
		<table border="0" cellspacing="0" cellpadding="0">

<!-- Choose Project Type -->
<form name="TemplateTypeForm">
<input type="hidden" name="isUpdate" value="false">
<input type="hidden" name="qid" value="<%=qidS%>" >

		<tr><td class="plaintext_blue">Type of <%=label1%>:</td></tr>
		<tr><td class="plaintext_big">
		<select class="plaintext_big" name="TemplateType" onChange="javascript:changeTmplType();">

<%
		// changes to the followings need to also copy to new_templ1.jsp
		String [] eventTypeArr = {"Birthday", "Baby Shower", "Bridal Shower", "Bachelor Party", "Reunion"};
		String [] questTypeArr = {"Simple", "Politics", "Faith, Life & Religion", "Personal Improvement"};
		
		String [] projTypeArray1 = {"Simple", "Marketing", "Design Engineering", "Product Engineering", "Product Testing", "Manufacturing"};
		String [] projTypeArray2 = {"Simple", "Family & Friends", "School & Education", "Business"};
		String [] projTypeArray3 = {"Administration", "Customer", "Financial", "Product & Service",
				"Sales & Marketing", "IT/IS", "Electronics Engineering", "Software Engineering", "Other Engineering"};	// same as in proj_new2.jsp
		String [] projTypeArray;
		if (isOMFAPP)
		{
			if (isQuest)
			{
				if (isEvent)
					projTypeArray = eventTypeArr;
				else
					projTypeArray = questTypeArr;
			}
			else
				projTypeArray = projTypeArray2;
		}
		else if (isCRAPP || isPRMAPP)
			projTypeArray = projTypeArray3;
		else
			projTypeArray = projTypeArray1;

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

		<tr><td><img src="../i/spacer.gif" height="20" width="1" alt=" " /></td></tr>


<!-- Update existing template -->
		<tr><td class="plaintext_blue">Update / Create:</td></tr>
		<tr><td class="plaintext_big">
			<input type="radio" name="Update" value="true" onclick="checkUpdate();"
				<%if (bUpdateTemplate) out.print(" checked");%> >Update an existing template
		</td></tr>

<!-- Template names for update -->
		<tr><td class="plaintext_big">&nbsp;&nbsp;&nbsp;Template name:</td></tr>
		<tr><td class="plaintext_big">&nbsp;&nbsp;
		<select class="plaintext_big" name="TemplateName"  onChange="document.TemplateTypeForm.submit();"
			<%if (!bUpdateTemplate) out.print(" disabled");%>>
		<option selected name="" value="">
		-- select a template --

<%
		int id;
		if (templates != null)
		{
			for(int i=0; i < templates.length; i++)
			{
				String aName = templates[i].getObjectName();
				String displayName = aName.substring(0, aName.lastIndexOf("@@"));
				s = (String)templates[i].getAttribute("Owner")[0];
				if (!isAdmin && (s==null || Integer.parseInt(s)!=myUid) )
					continue;			// either no owner or I am not the owner: can't update
				out.print("<option name='" + aName + "' value='" + aName + "'");
				if (aName.equals(templateName))
					out.print(" selected");
				out.print(">");
				if (isOMFAPP)
					out.println(aName.substring(4));	// skip Mtg_, Qst_, Evt_
				else
					out.println(displayName);
			}
		}
%>
		</select>
		</td></tr>
		<tr><td>&nbsp;</td></tr>

<!-- Create a new template -->
		<tr><td class="plaintext_big">
			<input type="radio" name="Update" value="false" onclick="checkUpdate();"
				<%if (!bUpdateTemplate) out.print(" checked");%>>Create a new template
		</td></tr>
		<tr><td class="plaintext_big">&nbsp;&nbsp;&nbsp;Template name:<br>&nbsp;&nbsp;
			<input type="text" size="30" name="NewTemplName" value="<%=newTemplName%>"
				<%if (bUpdateTemplate) out.print(" disabled");%>>
		</td></tr>

</form>

		</table>
	</td></tr>
	</table>
	</td>

<!-- Textbox Project Plan -->
<form method="post" name="saveTemplateForm" action="new_templ2.jsp" onSubmit="return validation();">
	<td width='70%'>
		<table width='100%'>
		<tr><td class="plaintext_blue">Edit <%=label1%> Template:
			<%if (!isQuest){%><span class="tinytype">(note: "*" is used to denote subtask levels)</span><%}%>
		</td></tr>
		<tr><td>
			<textarea name="Plan" rows="15" style='width:90%;' wrap="off"><%=content%></textarea>
		</td></tr>
		</table>
	</td>

	</tr>
<!-- End Project Plan widgets -->

<!-- Submit Button -->
<input type="hidden" name="qid" value="<%=qidS%>" >
<input type="hidden" name="TemplateType" value="<%=type%>" >
<input type="hidden" name="TemplateName" value="<%=templateName%>" >
<input type="hidden" name="NewTemplName" value="<%=newTemplName%>" >
<input type="hidden" name="Update" value="false" >
	<tr>
	<td colspan="3"><br>
		<img src='../i/spacer.gif' height='0' width='380' />
		<input type="Button" value="Cancel" onclick="<%=backPage%>">&nbsp;
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
