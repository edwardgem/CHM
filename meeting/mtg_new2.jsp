<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2005, EGI Technologies, Co.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: mtg_new2.jsp
//	Author: ECC
//	Date:	02/24/05
//	Description: Create a new meeting.
//
//
//	Modification:
//			@ECC100605	Support create follow meeting either from a standalone meeting or
//						at the end of a recurring event.
//			@AGQ030606	Added guest emails. Retreived and stored emails into session
//			@ECC061206a	Add project association to meeting.
//			@AGQ080206	Support memorizing Team Members
//			@SWS082206  Added option to finish setup new meeting from this page.
//			@SWS101606  Pass agenda value between mtg_new1 and 3.
//			@ECC110206	Add Description attribute.
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
	// Step 2 of 3 in setting up meeting
	
	final String REVIEW_LAST_ITEM = "Review last meeting action items";

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
	
	actionManager aMgr = actionManager.getInstance();
	SimpleDateFormat df1 = new SimpleDateFormat ("MM/dd/yyyy");
	
	// to check if session is OMF or PRM
	boolean isOMFAPP = Prm.isMeetWE();
	String appS = Prm.getAppTitle();

	String location = request.getParameter("Location");
	location = Util.stringToHTMLString(location);
	String confRoomSelect = request.getParameter("confRoomSelect");
	String localDT = request.getParameter("LocalStartDT");				// ECC: not used
	String startDT = request.getParameter("StartDT");
	String expireDT = request.getParameter("ExpireDT");
	String recurring = request.getParameter("Recurring");
	String recurMult = request.getParameter("RecurMultiple");
	String mandatoryS = request.getParameter("Mandatory");
	// @AGQ080206	
	String [] manArr = request.getParameterValues("MandatoryAttendee");
	String optionalS = request.getParameter("Optional");
	String [] optArr = request.getParameterValues("OptionalAttendee");
	String projIdS = request.getParameter("ProjectId");			// @ECC061206a
	String lastmidS = request.getParameter("Lastmid");
	if (lastmidS == null) lastmidS = "";
	String descStr = request.getParameter("Description");		// @ECC110206
	String selectGp = request.getParameter("SelectGroup");		// @ECC110206
	
	// @AGQ081606 Type public or private
	String meetingType = request.getParameter("meetingType");
	//if (meetingType == null) meetingType = meeting.PRIVATE;
	String company = request.getParameter("company");

	// @AGQ030606
	String emailStr = request.getParameter("guestEmails");
	session.setAttribute("guestEmails", Util.expandGuestEmails(emailStr));
	if (emailStr == null) emailStr = "";
	
	String optMsg = request.getParameter("message");
	String agendaS = request.getParameter("Agenda");
	
	// @ECC030309
	String recur1 = request.getParameter("Recur1");
	String recur2 = request.getParameter("Recur2");
	String recur3 = request.getParameter("Recur3");
	String recur4 = request.getParameter("Recur4");
	String recur5 = request.getParameter("Recur5");
	String recurSun = request.getParameter("RecurSun");
	String recurMon = request.getParameter("RecurMon");
	String recurTue = request.getParameter("RecurTue");
	String recurWed = request.getParameter("RecurWed");
	String recurThu = request.getParameter("RecurThu");
	String recurFri = request.getParameter("RecurFri");
	String recurSat = request.getParameter("RecurSat");

	// @ECC100605: create a followup meeting
	String s;
	String [] sa;
	String lastAgendaS = "";
	String firstItem = "";
	if (lastmidS.length()>0 && StringUtil.isNullOrEmptyString(agendaS))
	{
		PstAbstractObject obj = meetingManager.getInstance().get(pstuser, lastmidS);

		// get agenda items
		Object [] agendaArr = obj.getAttribute("AgendaItem");
		if (agendaArr[0] != null)
		{
			Arrays.sort(agendaArr, new Comparator()
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

			int level = 0;
			String itemName = null;
			boolean bIgnoreThisGpOfItems = false;
			for (int i=0; i<agendaArr.length; i++)
			{
				s = (String)agendaArr[i];			// (pre-order::order::level::item::duration::owner)
				sa = s.split(meeting.DELIMITER);
				try
				{
					level = Integer.parseInt(sa[2]);
					if (bIgnoreThisGpOfItems && level>0) {
						continue;	// ignore this group
					}
					else {
						bIgnoreThisGpOfItems = false;
					}
					s = "";
					while (level-- > 0) s += "*";
					itemName = s + sa[3].replaceAll("@@", ":");
				}
				catch (Exception e) {continue;}
				if (firstItem == "") {
					firstItem = itemName.toLowerCase();
					if (firstItem.contains(REVIEW_LAST_ITEM.toLowerCase())) {
						// there is review action items in the agenda, strip it
						bIgnoreThisGpOfItems = true;
						continue;
					}
				}
				lastAgendaS += itemName + "\n";
			}
		}
		
		// insert last meeting action items into agenda
		int [] ids = aMgr.findId(pstuser, "MeetingID='" + lastmidS + "' && Type='" + action.TYPE_ACTION + "'");
		if (ids.length > 0) {
			String temp = REVIEW_LAST_ITEM + "\n";
			PstAbstractObject actObj;
			Date dt;
			for (int i=0; i<ids.length; i++) {
				actObj = aMgr.get(pstuser, ids[i]);
				dt = (Date) actObj.getAttribute("ExpireDate")[0];
				temp += "* " + actObj.getStringAttribute("Subject");
				if (dt != null) {
					temp += " (Due: " + df1.format(dt) + ")";
				}
				temp += "\n";
			}
			lastAgendaS = temp + "\n\n" + lastAgendaS;
		}
	}
	

	// template type
	String type = request.getParameter("Type");
	if (type == null) type = "Simple";

	// template name
	String templateName = request.getParameter("TemplateName");
	if (templateName == null)
	{
		if (type.equals("Simple")) templateName = "Mtg_Default";
		else templateName = "";
	}

	// get the list of template of this type (prefix is "Mtg_", e.g. Mtg_Simple)
	PstAbstractObject [] templates = null;
	projTemplateManager pjTMgr = projTemplateManager.getInstance();
	int [] templateIds = pjTMgr.findId(pstuser, "Type='Mtg_" + type + "'");
	templates = pjTMgr.get(pstuser, templateIds);

	// get the selected content
	String content = "";
	if (!StringUtil.isNullOrEmptyString(agendaS)) {
		content = agendaS;
	}	
	else if (lastAgendaS.length() > 0)
		content = lastAgendaS;
	else if (templateName.length() > 0)
	{
		projTemplate pjTempate = (projTemplate)pjTMgr.get(pstuser, templateName);
		Object cObj = pjTempate.getAttribute("Content")[0];
		content = (cObj==null)?"":new String((byte[])cObj, "utf-8");
	}

	// do not perform the create until the last step
	////////////////////////////////////////////////////////
%>


<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
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
	var e = newMeeting.Agenda;
	if (e.value.indexOf("::") != -1)
	{
		fixElement(e, "You cannot use double-colon \(::\) in the Agenda.");
		return false;
	}
	return true;
}
// @AGQ080206
function goBack() {
	var backPage = "mtg_new1.jsp";
	newMeeting.action = backPage;
	newMeeting.submit();
}

function finish()
{ // @SWS082206
	var origin = document.getElementsByName("Origin")[0];
	origin.value = "mtg_new2";
	var nextPage = "post_mtg_new.jsp";
	newMeeting.action = nextPage;
	if (!validation())
		return false;
	newMeeting.submit();
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
		</table>
	</td>
</tr>
</table>
		
<table width='90%' border='0' cellspacing='0' cellpadding='0'>
			<tr>
	          <td>
	            <table width="100%" border="0" cellspacing="0" cellpadding="0">
				  <tr>
					<td width="26" height="30"><a name="top">&nbsp;</a></td>
                	<td height="30" align="left" valign="bottom" class="head">
                	<b>Set Up a Meeting</b>
					</td></tr>
	            </table>
	          </td>
	        </tr>
			<tr>
          		<td width="100%">
<!-- Navigation Menu -->
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Event" />
				<jsp:param name="subCat" value="NewMeeting" />
				<jsp:param name="role" value="<%=iRole%>" />
			</jsp:include>
<!-- End of Navigation Menu -->
				</td>
	        </tr>
		</table>
<!-- Content Table -->

<table width="90%" border="0" cellspacing="0" cellpadding="0">
<tr><td colspan="2">&nbsp;</td></tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="instruction_head"><br><b>Step 2 of 3: Set Up Meeting Agenda</b></td>
	</tr>

	<tr>
		<td width="20">&nbsp;</td>
		<td colspan=2 class="instruction"><br>
		<u>To specify an agenda</u> for the meeting, simply choose from below the <b>Type of Meeting</b> you are
		creating, and select from the <b>Agenda Templates</b>.  After making these choices,
		you may further modify the Meeting Agenda.

		<p>When you are satisfied with the change, click the <b>Continue Button</b> to
		preview the agenda.
		<br><br></td>
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
	String durationS = request.getParameter("Duration");
	if (durationS==null) durationS="";
System.out.println("2-StartDate=" + startDate);
System.out.println("   startDT=" + startDT);
System.out.println("   localStartDT=" + localDT);

%>
<!-- Choose Project Type -->
<form name="TemplateType">
<input type="hidden" name="Subject" value="<%=subject%>" />
<input type="hidden" name="Location" value="<%=location%>" />
<input type="hidden" name="confRoomSelect" value="<%=confRoomSelect%>" />
<input type="hidden" name="LocalStartDT" value="<%=localDT%>" />
<input type="hidden" name="StartDT" value="<%=startDT%>" />
<input type="hidden" name="ExpireDT" value="<%=expireDT%>" />
<input type="hidden" name="Recurring" value="<%=recurring%>" />
<input type="hidden" name="RecurMultiple" value="<%=recurMult%>" />
<input type="hidden" name="Mandatory" value="<%=mandatoryS%>" />
<input type="hidden" name="Optional" value="<%=optionalS%>" />
<input type="hidden" name="ProjectId" value="<%=projIdS%>" />
<input type="hidden" name="guestEmails" value="<%=emailStr%>" />
<input type="hidden" name="StartTime" value="<%=startTime%>"/>
<input type="hidden" name="ExpireTime" value="<%=expireTime%>"/>
<input type="hidden" name="StartDate" value="<%=startDate%>"/>
<input type="hidden" name="ExpireDate" value="<%=expireDate%>"/>
<input type="hidden" name="Duration" value="<%=durationS%>"/>

<%-- @AGQ081606 --%>
<input type="hidden" name="meetingType" value="<%=meetingType%>" />
<input type="hidden" name="company" value="<%=company%>" />
<input type="hidden" name="StartNow" value=""/>
<input type="hidden" name="message" value="<%=optMsg%>" />
<input type="hidden" name="Description" value="<%=descStr%>" />
<input type="hidden" name="SelectGroup" value="<%=selectGp%>" />
<input type="hidden" name="Recur1" value="<%=recur1%>" />
<input type="hidden" name="Recur2" value="<%=recur2%>" />
<input type="hidden" name="Recur3" value="<%=recur3%>" />
<input type="hidden" name="Recur4" value="<%=recur4%>" />
<input type="hidden" name="Recur5" value="<%=recur5%>" />
<input type="hidden" name="RecurSun" value="<%=recurSun%>" />
<input type="hidden" name="RecurMon" value="<%=recurMon%>" />
<input type="hidden" name="RecurTue" value="<%=recurTue%>" />
<input type="hidden" name="RecurWed" value="<%=recurWed%>" />
<input type="hidden" name="RecurThu" value="<%=recurThu%>" />
<input type="hidden" name="RecurFri" value="<%=recurFri%>" />
<input type="hidden" name="RecurSat" value="<%=recurSat%>" />

<%
// @AGQ080206
if (manArr != null) {	
	for (int i=0;i<manArr.length;i++) {
		out.println("<input type='hidden' name='MandatoryAttendee' value='"+manArr[i]+"'>");
	}
}
if (optArr != null) {
	for (int i=0;i<optArr.length;i++) {
		out.println("<input type='hidden' name='OptionalAttendee' value='"+optArr[i]+"'>");
	}
}
%>

		<tr><td width='200' class="plaintext_blue">Type of Meeting:</td></tr>
		<tr><td class="plaintext_big">
		<select class="plaintext_big" name="Type" onChange="document.TemplateType.submit();">

<%
		String [] mtgTypeArrayCR 	= {"Simple", "Business", "Engineering", "Finance", "Personal"};
		String [] mtgTypeArrayOMF = {"Simple", "Family & Friends", "School & Education", "Business"};
		String [] projTypeArray;
		if (isOMFAPP)
			projTypeArray = mtgTypeArrayOMF;
		else
			projTypeArray = mtgTypeArrayCR;

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
<input type="hidden" name="Subject" value="<%=subject%>" />
<input type="hidden" name="Location" value="<%=location%>" >
<input type="hidden" name="confRoomSelect" value="<%=confRoomSelect%>" />
<input type="hidden" name="LocalStartDT" value="<%=localDT%>" />
<input type="hidden" name="StartDT" value="<%=startDT%>" />
<input type="hidden" name="ExpireDT" value="<%=expireDT%>" />
<input type="hidden" name="Recurring" value="<%=recurring%>" />
<input type="hidden" name="RecurMultiple" value="<%=recurMult%>" />
<input type="hidden" name="Mandatory" value="<%=mandatoryS%>" />
<input type="hidden" name="Optional" value="<%=optionalS%>" />
<input type="hidden" name="Type" value="<%=type%>"/>
<input type="hidden" name="ProjectId" value="<%=projIdS%>" />
<input type="hidden" name="guestEmails" value="<%=emailStr%>" />
<input type="hidden" name="StartTime" value="<%=startTime%>"/>
<input type="hidden" name="ExpireTime" value="<%=expireTime%>"/>
<input type="hidden" name="StartDate" value="<%=startDate%>"/>
<input type="hidden" name="ExpireDate" value="<%=expireDate%>"/>
<input type="hidden" name="Duration" value="<%=durationS%>"/>

<%-- @AGQ081606 --%>
<input type="hidden" name="meetingType" value="<%=meetingType%>" />
<input type="hidden" name="company" value="<%=company%>" />
<input type="hidden" name="StartNow" value=""/>
<input type="hidden" name="Type" value="<%=type%>"/>
<input type="hidden" name="message" value="<%=optMsg%>" />
<input type="hidden" name="Description" value="<%=descStr%>" />
<input type="hidden" name="SelectGroup" value="<%=selectGp%>" />
<input type="hidden" name="Recur1" value="<%=recur1%>" />
<input type="hidden" name="Recur2" value="<%=recur2%>" />
<input type="hidden" name="Recur3" value="<%=recur3%>" />
<input type="hidden" name="Recur4" value="<%=recur4%>" />
<input type="hidden" name="Recur5" value="<%=recur5%>" />
<input type="hidden" name="RecurSun" value="<%=recurSun%>" />
<input type="hidden" name="RecurMon" value="<%=recurMon%>" />
<input type="hidden" name="RecurTue" value="<%=recurTue%>" />
<input type="hidden" name="RecurWed" value="<%=recurWed%>" />
<input type="hidden" name="RecurThu" value="<%=recurThu%>" />
<input type="hidden" name="RecurFri" value="<%=recurFri%>" />
<input type="hidden" name="RecurSat" value="<%=recurSat%>" />

<%
// @AGQ080206
if (manArr != null) {	
	for (int i=0;i<manArr.length;i++) {
		out.println("<input type='hidden' name='MandatoryAttendee' value='"+manArr[i]+"'/>");
	}
}
if (optArr != null) {
	for (int i=0;i<optArr.length;i++) {
		out.println("<input type='hidden' name='OptionalAttendee' value='"+optArr[i]+"'/>");
	}
}
%>

		<tr><td class="plaintext_blue">Agenda Template:</td></tr>
		<tr><td class="plaintext_big">
		<select class="plaintext_big" name="TemplateName" onChange="document.TemplName.submit();">
		<option selected name="" value="">-- select a template --</option>

<%
		if (templates != null)
		{
			for(int i = 0; i < templates.length; i++)
			{
				String aName = templates[i].getObjectName();
				out.print("<option name='" + aName + "' value='" + aName + "'");
				if (aName.equals(templateName))
					out.print(" selected");
				out.println(">" + aName.substring(4) + "</option>");	// skip Mtg_
			}
		}
%>
		</select>
		</td></tr>
</form>

		</table>
	</td>

<!-- Textarea Agenda -->
<form method="post" name="newMeeting" action="mtg_new3.jsp">
	<td>
		<table>
		<tr><td class="plaintext_blue">Edit Agenda:
				<span class="tinytype">(note: "*" is used to denote sub-item levels)</span>
			</td>
			<td align="right">
				<input type="button" class="button" value=" Add Link " onClick="wrapIt('l')">
			</td>
		</tr>
		<tr><td colspan='2'>
			<textarea name="Agenda" rows="15" style='width:600px;'
				wrap="auto"
				OnSelect="storeCaret(this);"><%=content%></textarea>
		</td></tr>
		</table>
	</td>

	</tr>
<!-- End Agenda widgets -->

<!-- Submit Button -->
<input type="hidden" name="Subject" value="<%=subject%>" />
<input type="hidden" name="Location" value="<%=location%>" >
<input type="hidden" name="confRoomSelect" value="<%=confRoomSelect%>" />
<input type="hidden" name="LocalStartDT" value="<%=localDT%>" />
<input type="hidden" name="StartDT" value="<%=startDT%>" />
<input type="hidden" name="ExpireDT" value="<%=expireDT%>" />
<input type="hidden" name="Recurring" value="<%=recurring%>" />
<input type="hidden" name="RecurMultiple" value="<%=recurMult%>" />
<input type="hidden" name="Mandatory" value="<%=mandatoryS%>" />
<input type="hidden" name="Optional" value="<%=optionalS%>" />
<input type="hidden" name="Lastmid" value="<%=lastmidS%>"/>
<input type="hidden" name="ProjectId" value="<%=projIdS%>" />
<input type="hidden" name="guestEmails" value="<%=emailStr%>" />
<%-- @AGQ081606 --%>
<input type="hidden" name="meetingType" value="<%=meetingType%>" />
<input type="hidden" name="company" value="<%=company%>" />
<input type="hidden" name="StartNow" value=""/>
<input type="hidden" name="message" value="<%=optMsg%>" />

<input type="hidden" name="StartTime" value="<%=startTime%>"/>
<input type="hidden" name="ExpireTime" value="<%=expireTime%>"/>
<input type="hidden" name="StartDate" value="<%=startDate%>"/>
<input type="hidden" name="ExpireDate" value="<%=expireDate%>"/>
<input type="hidden" name="Duration" value="<%=durationS%>"/>

<%-- @AGQ081506 --%>
<input type="hidden" name="Type" value="<%=type%>"/>
<input type="hidden" name="TemplateName" value="<%=templateName%>"/>
<input type="hidden" name="Origin" value=""/>
<input type="hidden" name="Description" value="<%=descStr%>" />
<input type="hidden" name="SelectGroup" value="<%=selectGp%>" />
<input type="hidden" name="Recur1" value="<%=recur1%>" />
<input type="hidden" name="Recur2" value="<%=recur2%>" />
<input type="hidden" name="Recur3" value="<%=recur3%>" />
<input type="hidden" name="Recur4" value="<%=recur4%>" />
<input type="hidden" name="Recur5" value="<%=recur5%>" />
<input type="hidden" name="RecurSun" value="<%=recurSun%>" />
<input type="hidden" name="RecurMon" value="<%=recurMon%>" />
<input type="hidden" name="RecurTue" value="<%=recurTue%>" />
<input type="hidden" name="RecurWed" value="<%=recurWed%>" />
<input type="hidden" name="RecurThu" value="<%=recurThu%>" />
<input type="hidden" name="RecurFri" value="<%=recurFri%>" />
<input type="hidden" name="RecurSat" value="<%=recurSat%>" />

<%
// @AGQ080206
if (manArr != null) {	
	for (int i=0;i<manArr.length;i++) {
		out.println("<input type='hidden' name='MandatoryAttendee' value='"+manArr[i]+"'/>");
	}
}
if (optArr != null) {
	for (int i=0;i<optArr.length;i++) {
		out.println("<input type='hidden' name='OptionalAttendee' value='"+optArr[i]+"'/>");
	}
}
%>


	<tr>
	<td colspan="2"><br>
			<img src='../i/spacer.gif' height='1' width='375'/>
		<input type="button" class="button_medium" value="  << Prev  " onclick="goBack()"/>&nbsp;
		<input type="button" class="button_medium" value="   Finished  " onclick="finish();"/>
			<img src='../i/spacer.gif' width='20'/>
		<input type="submit" class="button_medium" name="Submit" value="  Continue  " onclick="return validation();"/>
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
