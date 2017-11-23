<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2008, EGI Technologies, Co.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: q_new2.jsp
//	Author: ECC
//	Date:	01/02/08
//	Description: Create a new questionnaire.
//
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
	// Step 2 of 3 in setting up questionnaire

	String subject = request.getParameter("Subject");
	subject = Util.stringToHTMLString(subject); // escape special characters
	if ((pstuser instanceof PstGuest) || (subject == null))
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	
	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ( (iRole & user.iROLE_ADMIN) > 0 )
		isAdmin = true;
	
	// to check if session is OMF or PRM
	boolean isOMFAPP = false;
	String appS = (String)session.getAttribute("app");
	if (appS.equals("OMF"))
	{
		appS = "MeetWE";
		isOMFAPP = true;
	}

	boolean isEvent = false;
	String label1 = "";
	String tmpType = "";
	String qType = request.getParameter("Qtype");
	String subCatLabel;
	if (qType.equals("event"))
	{
		isEvent = true;
		label1 = "Event";
		tmpType = "Evt_";
		subCatLabel = "NewEvent";
	}
	else
	{
		label1 = "Questionnaire";
		tmpType = "Qst_";
		subCatLabel = "NewQuestion";
	}
	
	String qShare = request.getParameter("Qshare");

	String qidS = request.getParameter("Qid");
	String parentIdS = request.getParameter("ParentId");

	String location = request.getParameter("Location");
	location = Util.stringToHTMLString(location);
	String localDT = request.getParameter("LocalStartDT");
	String startDT = request.getParameter("StartDT");
	String expireDT = request.getParameter("ExpireDT");
	String durationS = request.getParameter("Duration");
	if (durationS==null) durationS="";

	String sendDT = request.getParameter("SendDT");
	String mandatoryS = request.getParameter("Mandatory");
	// @AGQ080206	
	String [] manArr = request.getParameterValues("MandatoryAttendee");
	String descStr = request.getParameter("Description");		// @ECC110206
	descStr = Util.stringToHTMLString(descStr);
	String selectGp = request.getParameter("SelectGroup");		// @ECC110206
	
	// @AGQ081606 Type public or private
	String meetingType = request.getParameter("meetingType");
	String company = request.getParameter("company");
	String midS = request.getParameter("mid");

	// @AGQ030606
	String emailStr = request.getParameter("guestEmails");
	session.setAttribute("guestEmails", Util.expandGuestEmails(emailStr));
	if (emailStr == null) emailStr = "";
	
	String optMsg = request.getParameter("message");
	String agendaS = request.getParameter("Agenda");
	String projectS = request.getParameter("ProjectId");

	// @ECC100605: create a followup meeting
	String s;
	String [] sa;
	String lastAgendaS = "";

	// template type
	String type = request.getParameter("Type");
	if (type == null)
	{
		if (isEvent) type = "Birthday";		// event/party
		else type = "Simple";				// questionnaire
	}

	// get the list of template of this type (prefix is "Qst_", e.g. Qst_Simple)
	PstAbstractObject [] templates = null;
	projTemplateManager pjTMgr = projTemplateManager.getInstance();
	int [] templateIds = pjTMgr.findId(pstuser, "Type='" + tmpType + type + "'");	// Qst_Simple
	templates = pjTMgr.get(pstuser, templateIds);

	// current selected template
	String templateName = request.getParameter("TemplateName");
	if (templateName == null)
	{
		if (templates.length>0 && templates[0] != null)
			templateName = templates[0].getObjectName();
		else
			templateName = "";
	}

	// get the selected template
	String content = "";
	if (lastAgendaS.length() > 0)
		content = lastAgendaS;
	else if (templateName.length() > 0)
	{
		projTemplate pjTempate = (projTemplate)pjTMgr.get(pstuser, templateName);
		Object cObj = pjTempate.getAttribute("Content")[0];
		content = (cObj==null)?"":new String((byte[])cObj, "utf-8");
	}
	
	if (agendaS != null && agendaS.length() > 0) // @SWS101606
		content = agendaS;

	// do not perform the create until the last step
	////////////////////////////////////////////////////////
%>


<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../edit.jsp" flush="true"/>
<script language="JavaScript">
<!--

function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

function validation()
{
	var e = newQuestion.Agenda;
	if (e.value.indexOf("::") != -1)
	{
		fixElement(e, "You cannot use double-colon \(::\) in the questions.");
		return false;
	}
	return true;
}
// @AGQ080206
function goBack() {
	var backPage = "q_new1.jsp";
	newQuestion.action = backPage;
	newQuestion.ComeBack.value = "true";		// don't make q_new1.jsp reload from old
	newQuestion.submit();
}

function finish()
{ // @SWS082206
	var origin = document.getElementsByName("Origin")[0];
	origin.value = "q_new2";
	var nextPage = "post_q_new.jsp";
	newQuestion.action = nextPage;
	if (!validation())
		return false;
	newQuestion.submit();
}

//-->
</script>

</head>

<title><%=appS%></title>
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
                	<b>Set Up 
<%
	if (isEvent) {out.print("an Invite for Party / Event");}
	else {out.print("a Questionnaire / Survey / Vote");}
%>
                	</b>
					</td></tr>
	            </table>
	          </td>
	        </tr>
</table>

<table width='90%' border='0' cellspacing='0' cellpadding='0'>	        
			<tr>
          		<td width="100%">
<!-- Navigation Menu -->
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Event" />
				<jsp:param name="subCat" value="<%=subCatLabel%>" />
				<jsp:param name="role" value="<%=iRole%>" />
				<jsp:param name="roleType" value="1" />
			</jsp:include>
<!-- End of Navigation Menu -->
				</td>
	        </tr>
		</table>
<!-- Content Table -->

<table width="770" border="0" cellspacing="0" cellpadding="0">
<tr><td colspan="2">&nbsp;</td></tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="instruction_head"><br><b>Step 2 of 3: Set Up Optional Questions for 
<%	if (isEvent) out.print("Party / Event");
	else out.print("Questionnaire / Survey / Vote");
%>
		</b></td>
	</tr>

	<tr>
		<td width="20">&nbsp;</td>
		<td colspan=2 class="instruction"><br/>
		To some questions for your guests, simply choose from the <b>Type of <%=label1%></b> you are
		creating, and select from the <b>Templates</b>.  After making these choices,
		you may further modify the questions below.

		<p>When you are satisfied with the change, click the <b>Continue Button</b> to
		preview the questions.
		<br/><br/></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>

		<td>

<!-- Content -->
<table>

<!-- Project Plan widgets -->
	<tr>

	<td valign="top">
		<table>
<%
	String startTime = request.getParameter("StartTime");
	if (startTime==null) startTime="";
	String expireTime = request.getParameter("ExpireTime");
	if (expireTime==null) expireTime="";
	String startDate = request.getParameter("StartDate");
	if (startDate==null) startDate="";	
	String expireDate = request.getParameter("ExpireDate");
	if (expireDate==null) expireDate="";		
%>
<!-- Choose Project Type -->
<form name="TemplateType">
<input type="hidden" name="Qid" value="<%=qidS%>"/>
<input type="hidden" name="updateQid" value="<%=qidS%>"/>
<input type="hidden" name="ParentId" value="<%=parentIdS%>"/>
<input type="hidden" name="Qtype" value="<%=qType%>" />
<input type="hidden" name="Qshare" value="<%=qShare%>"/>
<input type="hidden" name="Subject" value="<%=subject%>" />
<input type="hidden" name="Location" value="<%=location%>" />
<input type="hidden" name="LocalStartDT" value="<%=localDT%>" />
<input type="hidden" name="StartDT" value="<%=startDT%>" />
<input type="hidden" name="ExpireDT" value="<%=expireDT%>" />
<input type="hidden" name="SendDT" value="<%=sendDT%>"/>
<input type="hidden" name="Mandatory" value="<%=mandatoryS%>" />
<input type="hidden" name="guestEmails" value="<%=emailStr%>" />
<input type="hidden" name="StartTime" value="<%=startTime%>"/>
<input type="hidden" name="ExpireTime" value="<%=expireTime%>"/>
<input type="hidden" name="StartDate" value="<%=startDate%>"/>
<input type="hidden" name="ExpireDate" value="<%=expireDate%>"/>
<input type="hidden" name="Duration" value="<%=durationS%>"/>
<%-- @AGQ081606 --%>
<input type="hidden" name="meetingType" value="<%=meetingType%>" />
<input type="hidden" name="company" value="<%=company%>" />
<input type="hidden" name="StartNow" value="" />
<input type="hidden" name="message" value="<%=optMsg%>" />
<input type="hidden" name="Description" value="<%=descStr%>" />
<input type="hidden" name="SelectGroup" value="<%=selectGp%>" />
<input type="hidden" name="mid" value="<%=midS%>" />
<input type="hidden" name="ProjectId" value="<%=projectS%>" />

<%
// @AGQ080206
if (manArr != null) {	
	for (int i=0;i<manArr.length;i++) {
		out.println("<input type='hidden' name='MandatoryAttendee' value='"+manArr[i]+"'>");
	}
}
%>

		<tr><td class="plaintext_blue">Type of <%=label1%>:</td></tr>
		<tr><td class="plaintext_big">
		<select class="plaintext_big" name="Type" onChange="document.TemplateType.submit();">

<%
		// changes to the followings need to also copy to new_templ1.jsp
		String [] eventTypeArr = {"Birthday", "Baby Shower", "Bridal Shower", "Bachelor Party", "Reunion"};
		String [] questTypeArr = {"Simple", "Politics", "Faith, Life & Religion", "Personal Improvement"};
		String [] thisTypeArray;
		if (isEvent)
			thisTypeArray = eventTypeArr;
		else
			thisTypeArray = questTypeArr;
		
		for(int i = 0; i < thisTypeArray.length; i++)
		{
			out.print("<option name='" + thisTypeArray[i] + "' value='" + thisTypeArray[i] + "'");
			if (type.equals(thisTypeArray[i]))
				out.print(" selected");
			out.println(">" + thisTypeArray[i]);
		}
%>
		</select>
		</td></tr>
</form>

		<tr><td><img src="../i/spacer.gif" height="20" width="1" alt=" " /></td></tr>

<!-- Templates -->
<form name="TemplName">
<input type="hidden" name="Qid" value="<%=qidS%>">
<input type="hidden" name="updateQid" value="<%=qidS%>">
<input type="hidden" name="ParentId" value="<%=parentIdS%>">
<input type="hidden" name="Qtype" value="<%=qType%>" >
<input type="hidden" name="Qshare" value="<%=qShare%>">
<input type="hidden" name="Subject" value="<%=subject%>" >
<input type="hidden" name="Location" value="<%=location%>" >
<input type="hidden" name="LocalStartDT" value="<%=localDT%>" >
<input type="hidden" name="StartDT" value="<%=startDT%>" >
<input type="hidden" name="ExpireDT" value="<%=expireDT%>" >
<input type="hidden" name="SendDT" value="<%=sendDT%>">
<input type="hidden" name="Mandatory" value="<%=mandatoryS%>" >
<input type="hidden" name="Type" value="<%=type%>">
<input type="hidden" name="guestEmails" value="<%=emailStr%>" >
<input type="hidden" name="StartTime" value="<%=startTime%>">
<input type="hidden" name="ExpireTime" value="<%=expireTime%>">
<input type="hidden" name="StartDate" value="<%=startDate%>">
<input type="hidden" name="ExpireDate" value="<%=expireDate%>">
<input type="hidden" name="Duration" value="<%=durationS%>">
<%-- @AGQ081606 --%>
<input type="hidden" name="meetingType" value="<%=meetingType%>" >
<input type="hidden" name="company" value="<%=company%>" >
<input type="hidden" name="StartNow" value="">
<input type="hidden" name="Type" value="<%=type%>">
<input type="hidden" name="message" value="<%=optMsg%>" >
<input type="hidden" name="Description" value="<%=descStr%>" >
<input type="hidden" name="SelectGroup" value="<%=selectGp%>" >
<input type="hidden" name="mid" value="<%=midS%>" >
<input type="hidden" name="ProjectId" value="<%=projectS%>" >
<%
// @AGQ080206
if (manArr != null) {	
	for (int i=0;i<manArr.length;i++) {
		out.println("<input type='hidden' name='MandatoryAttendee' value='"+manArr[i]+"'>");
	}
}
%>

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
				out.println(">" + aName.substring(4));	// skip Qst_
			}
		}
%>
		</select>
		</td></tr>
</form>

		</table>
	</td>

<!-- Textbox Agenda -->
<form method="post" name="newQuestion" action="q_new3.jsp">
	<td>
		<table>
		<tr><td class="plaintext_blue">Edit Questions:
				<span class="tinytype">(note: "*" is used to denote multiple choices)</span>
			</td>
			<td align="right">
			</td>
		</tr>
		<tr><td colspan='2'>
			<textarea name="Agenda" rows="15" cols="60" wrap="off"
				OnSelect="storeCaret(this);"><%=content%></textarea>
		</td></tr>
		</table>
	</td>

	</tr>
<!-- End Agenda widgets -->

<!-- Submit Button -->
<input type="hidden" name="ComeBack" value="">
<input type="hidden" name="Qid" value="<%=qidS%>">
<input type="hidden" name="updateQid" value="<%=qidS%>">
<input type="hidden" name="ParentId" value="<%=parentIdS%>">
<input type="hidden" name="Qtype" value="<%=qType%>" >
<input type="hidden" name="Qshare" value="<%=qShare%>">
<input type="hidden" name="Subject" value="<%=subject%>" >
<input type="hidden" name="Location" value="<%=location%>" >
<input type="hidden" name="LocalStartDT" value="<%=localDT%>" >
<input type="hidden" name="StartDT" value="<%=startDT%>" >
<input type="hidden" name="ExpireDT" value="<%=expireDT%>" >
<input type="hidden" name="SendDT" value="<%=sendDT%>">
<input type="hidden" name="Mandatory" value="<%=mandatoryS%>" >
<input type="hidden" name="guestEmails" value="<%=emailStr%>" >
<%-- @AGQ081606 --%>
<input type="hidden" name="meetingType" value="<%=meetingType%>" >
<input type="hidden" name="company" value="<%=company%>" >
<input type="hidden" name="StartNow" value="">
<input type="hidden" name="message" value="<%=optMsg%>" >

<input type="hidden" name="StartTime" value="<%=startTime%>">
<input type="hidden" name="ExpireTime" value="<%=expireTime%>">
<input type="hidden" name="StartDate" value="<%=startDate%>">
<input type="hidden" name="ExpireDate" value="<%=expireDate%>">
<input type="hidden" name="Duration" value="<%=durationS%>">
<%-- @AGQ081506 --%>
<input type="hidden" name="Type" value="<%=type%>">
<input type="hidden" name="TemplateName" value="<%=templateName%>">
<input type="hidden" name="Origin" value="">
<input type="hidden" name="Description" value="<%=descStr%>" >
<input type="hidden" name="SelectGroup" value="<%=selectGp%>" >
<input type="hidden" name="mid" value="<%=midS%>" >
<input type="hidden" name="ProjectId" value="<%=projectS%>" >
<%
// @AGQ080206
if (manArr != null) {	
	for (int i=0;i<manArr.length;i++) {
		out.println("<input type='hidden' name='MandatoryAttendee' value='"+manArr[i]+"'>");
	}
}
%>


	<tr>
	<td colspan='2'><br/>
		<img src='../i/spacer.gif' height='1' width='330' />
		<input type="button" class="button_medium" value="  << Prev  " onclick="goBack()"/>&nbsp;
		<input type="submit" class="button_medium" name="Submit" value="  Continue  " onClick="return validation();"/>
	</td>
	</tr>
</form>

</table>

		</td>
	</tr>

</table>


	</td>
</tr>


</form>


		<!-- End of Content Table -->
		<!-- End of Main Tables -->

</table>
</td>
</tr>

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
