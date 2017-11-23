<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2005, EGI Technologies, Co.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: mtg_new3.jsp
//	Author: ECC
//	Date:	02/24/05
//	Description: Create a new meeting.
//
//
//	Modification:
//			@ECC100605	Support create follow meeting either from a standalone meeting or
//						at the end of a recurring event.
//			@AGQ022806	Expand dl and removed duplicate from mandatory and optional attendees
//			@AGQ033006	Escaped agenda's special characters
//			@ECC061206a	Add project association to meeting.
//			@ECC110206	Add Description attribute.
//			@ECC042507	Allow NONE or ALL to be responsible for an agenda item.
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
	// Step 3 of 3 in setting up meeting

	String subject = request.getParameter("Subject");
	subject = Util.stringToHTMLString(subject);
	if ((pstuser instanceof PstGuest) || (subject == null))
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}

	int myUid = pstuser.getObjectId();
	userManager uMgr = userManager.getInstance();
	meetingManager mMgr = meetingManager.getInstance();
	dlManager dlMgr = dlManager.getInstance();
	
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	
	// to check if session is OMF or PRM
	boolean isOMFAPP = false;
	String appS = (String)session.getAttribute("app");
	if (appS.equals("OMF"))
	{
		appS = "MeetWE";
		isOMFAPP = true;
	}

	String location = request.getParameter("Location");
	location = Util.stringToHTMLString(location);
	String confRoomSelect = request.getParameter("confRoomSelect");
	String localDT = request.getParameter("LocalStartDT");			// ECC: not used
	String startDT = request.getParameter("StartDT");
	String expireDT = request.getParameter("ExpireDT");
	String endT = request.getParameter("ExpireTime");
	String recurring = request.getParameter("Recurring");
	String recurMult = request.getParameter("RecurMultiple");
	String projIdS = request.getParameter("ProjectId");			// @ECC061206a
// @AGQ081506
	String type = request.getParameter("Type");
	String templateName = request.getParameter("TemplateName");
// @AGQ081606 Type public or private
	String meetingType = request.getParameter("meetingType");	
	String company = request.getParameter("company");
	String emailStr = request.getParameter("guestEmails");
	String selectGp = request.getParameter("SelectGroup");		// @ECC110206
// @AGQ022806
	String mandatoryS = dlMgr.removeDuplicate(pstuser, request.getParameter("Mandatory"), ";");
	String optionalS = dlMgr.removeDuplicateFromOptIds(pstuser, mandatoryS, request.getParameter("Optional"), ";");
	String [] manArr = request.getParameterValues("MandatoryAttendee");
	String [] optArr = request.getParameterValues("OptionalAttendee");
	String agendaS = request.getParameter("Agenda");
// @AGQ033006
	String agendaS2 = Util.stringToHTMLString(agendaS);		// can't handle the HTML for the Prev button at the bottom of this file
	String lastmidS = request.getParameter("Lastmid");		// @ECC100605
	if (lastmidS == null) lastmidS = "";
	
	String optMsg = request.getParameter("message");
	if (StringUtil.isNullOrEmptyString(optMsg)) optMsg = "";

	String descStr = request.getParameter("Description");		// @ECC110206

	Object [] agendaArr = new Object[0];
	if (lastmidS.length()>0)
	{
		PstAbstractObject obj = mMgr.get(pstuser, lastmidS);
		agendaArr = obj.getAttribute("AgendaItem");
	}
	
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

// begin setting up plan stack

	// Agenda is represented by a Vector of Task
	// Task is represented by a hashtable.
	Vector rAgenda = new Vector();
	String s, itemName;
	String [] sa;
	int i = 0;

	// process the plan script to create a list of JwTask
	JwTask [] taskArray = null;
	try
	{
		JwTask jw = new JwTask();
		taskArray = jw.processScript(agendaS);
	}
	catch (PmpException e)
	{
		String [] st = e.toString().split(":");
		String msg = st[1];
		msg += ": \"<b>" + st[2] + "</b>\"";
		response.sendRedirect("../out.jsp?msg="+ msg);
		return;
	}

	while (true)
	{
		// pTask is the persistent Task
		// rTask is the ram task which is in cache
		if (taskArray==null || taskArray[i] == null) break;

		JwTask pTask = taskArray[i++];
		s = pTask.getName();
		if (s.length() >= 240)
		{
			s = "The following agenda item is longer than the maximum length (240) allowed:<blockquote>" + s + "</blockquote>";
			response.sendRedirect("../out.jsp?msg="+ s);
			return;
		}
		Hashtable rTask = new Hashtable();
		rTask.put("Order", pTask.getOrder());
		rTask.put("Level", pTask.getLevel());
		rTask.put("Name", s);

		// @ECC100605
		for (int j=0; j<agendaArr.length; j++)
		{
			String ss = (String)agendaArr[j];		// (pre-order::order::level::item::duration::owner)
			if (ss == null) continue;
			sa = ss.split(meeting.DELIMITER);
			try{
				itemName = sa[3].replaceAll("@@", ":");
				if (itemName.equals(s))
				{
					rTask.put("Duration", sa[4]);
					rTask.put("Responsible", sa[5]);
				}
			}
			catch (Exception e) {break;}
		}

		rAgenda.addElement(rTask);
	}
	session.setAttribute("agenda", rAgenda);

// end of setting up plan stack

	// get all attendees, plus owner if not on attendee list
	ArrayList attendeeList = new ArrayList();
	user u;
	boolean found = false;
	int id;
	if (mandatoryS!=null && mandatoryS.length()>0)
	{
		sa = mandatoryS.split(";");	// id1;id2;id3,...
		for (i=0; i<sa.length; i++)
		{
			id = Integer.parseInt(sa[i]);
			if (id == myUid) found = true;
			u = (user)uMgr.get(pstuser, id);
			attendeeList.add(u);
		}
	}
	if (optionalS!=null && optionalS.length()>0)
	{	
		sa = optionalS.split(";");	// id1;id2;id3,...
		for (i=0; i<sa.length; i++)
		{
			id = Integer.parseInt(sa[i]);
			if (id == myUid) found = true;
			u = (user)uMgr.get(pstuser, id);
			attendeeList.add(u);
		}
	}
	if (!found)
		attendeeList.add(pstuser);

	Object [] attendeeArr = attendeeList.toArray();
	Arrays.sort(attendeeArr, new Comparator() {
			public int compare(Object o1, Object o2)
			  {
			   user emp1 = (user) o1;
			   user emp2 = (user) o2;

			   try
			   {
					String eName1 = emp1.getAttribute("FirstName")[0] + " " +
							emp1.getAttribute("LastName")[0];
					String eName2 = emp2.getAttribute("FirstName")[0] + " " +
							emp1.getAttribute("LastName")[0];

					   return eName1.compareToIgnoreCase(eName2);
			   }
			   catch(Exception e)
			   {
				   throw new ClassCastException("Could not compare.");
			   }
			  }
	});
	for (i=0; i<attendeeArr.length; i++)
	{
		if (((user)attendeeArr[i]).getAttribute("FirstName")[0] == null)
			attendeeArr[i] = null;
	}

%>


<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<jsp:include page="../init.jsp" flush="true"/>
<script language="JavaScript">
<!--

function showMessage(id)
{
	var e = document.getElementById(id);
	if (CreateAgenda.SendAlert.checked == true)
		e.style.display = 'block';
	else
		e.style.display = 'none';
}

function goBack() {
	var backPage = "mtg_new2.jsp";
	CreateAgenda.action = backPage;
	CreateAgenda.submit();
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
	<tr>
		<td width="15">&nbsp;</td>
		<td class="instruction_head"><br><b>Step 3 of 3: Review and Publish the Meeting Agenda</b></td>
	</tr>

	<tr>
		<td width="20"><img src="../i/spacer.gif" width="15" border="0"></td>
		<td class="plaintext_big">
			<br>
			<table width="100%" border="0" cellspacing="0" cellpadding="0">
			<tr>
				<td><img src='../i/spacer.gif' width='20' height='1' /></td>
				<td>
<form method="post" name="CreateAgenda" action="post_mtg_new.jsp">

<%
	String[] levelInfo = new String[10];
	int duration, respId;
	boolean bFound;
	for(i = 0; i < rAgenda.size(); i++)
	{
		Hashtable rTask = (Hashtable)rAgenda.elementAt(i);
		String pName = (String)rTask.get("Name");
		Integer pLevel = (Integer)rTask.get("Level");
		Integer pOrder = (Integer)rTask.get("Order");

		s = (String)rTask.get("Duration");
		if (s != null) duration = Integer.parseInt(s);
		else duration = 0;

		s = (String)rTask.get("Responsible");
		if (s != null) respId = Integer.parseInt(s);
		else respId = 0;

		int level = pLevel.intValue();
		int order = pOrder.intValue();

		int width = 10 + 22 * level;
		order++;
		if (level == 0)
		{
			out.println("<br>");
			levelInfo[level] = String.valueOf(order);
		}
		else
		{
			levelInfo[level] = levelInfo[level - 1] + "." + order;
		}

		out.println("<table width='100%' border='0' cellspacing='0' cellpadding='2'><tr>");

		// -- list the table of agenda items
		out.println("<td><table width='100%' border='0' cellspacing='0' cellpadding='0'><tr>");		// table A
		out.println("<td class='plaintext_big' valign='top' width='30'>" + levelInfo[level] + "&nbsp;&nbsp;</td>");
		out.print("<td><table border='0' width='100%' cellspacing='0' cellpadding='0'><tr>");	// table B
		out.println("<td class='plaintext_big' valign='top' style='white-space:nowrap;max-width:500px;'>" + pName + "</td>");
		out.print("<td><img src='../i/spacer.gif' width='10' height='1'/></td>");
		out.print("<td style='border-bottom:#777777 dotted 1px;' width='100%'><img src='../i/spacer.gif' width='100%' height='1'/></td>");
		out.print("</tr></table></td>");			// ENd table B
		out.println("</tr></table></td>");			// END table A

		// -- allocate time for each item
		out.println("<td valign='top' width='100'>");
		out.println("<select class='formtext' name='ItemTime_" + i + "'>");
		out.print("<option value='0' >- -</option>");
		for (int j=5; j<=120; j+=5)
		{
			out.print("<option value='" + j + "'");
			if (j==duration) out.print(" selected");
			out.print(">" + j + " min");
			out.println("</option>");
		}
		out.println("</select></td>");

		// -- choose owner for each item
		out.println("<td valign='top' width='120'>");
		out.println("<select class='formtext' name='Owner_" + i + "'>");
		
		// @ECC042507 add ALL and -- to agenda item responsible person list
		boolean bAlreadyFound = false;
		out.print("<option value='" + meeting.iAGENDA_NONE + "'");
		if (respId==meeting.iAGENDA_NONE) {out.print(" selected"); bAlreadyFound=true;}
		out.print(">- -</option>");
		out.print("<option value='" + meeting.iAGENDA_ALL + "'");
		if (respId==meeting.iAGENDA_ALL) {out.print(" selected"); bAlreadyFound=true;}
		out.print(">All</option>");

		if (attendeeArr != null && attendeeArr.length > 0)
		{
			bFound = bAlreadyFound;
			for (int j=0; j < attendeeArr.length; j++)
			{
				u = (user)attendeeArr[j];
				if (u== null) continue;
				String uName = u.getFullName();
				out.print("<option value='" + u.getObjectId() + "'");
				if (u.getObjectId() == respId) {out.print(" selected"); bFound = true;}
				else if (!bFound && u.getObjectId()==myUid) out.print(" selected");
				out.print(">" + uName);
				out.println("</option>");
			}
		}
		out.println("</select></td>");

		out.println("</tr>");
		out.println("</table>");
	}

%>

							</td>
						</tr>
				</table>
				</td>
			</tr>

		</table>

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
<input type="hidden" name="Description" value="<%=descStr%>" />
<input type="hidden" name="guestEmails" value="<%=emailStr%>" />
<input type="hidden" name="SelectGroup" value="<%=selectGp%>" />
<% // @SWS101706
if (manArr != null) {	
	for (int j=0;j<manArr.length;j++) {
		out.println("<input type='hidden' name='MandatoryAttendee' value='"+manArr[j]+"'>");
	}
}
if (optArr != null) {
	for (int j=0;j<optArr.length;j++) {
		out.println("<input type='hidden' name='OptionalAttendee' value='"+optArr[j]+"'>");
	}
}
%>
<input type="hidden" name="Agenda" value="<%=agendaS2%>" />
<input type="hidden" name="Lastmid" value="<%=lastmidS%>"/>
<input type="hidden" name="ProjectId" value="<%=projIdS%>" />
<%-- @AGQ081506 --%>
<input type="hidden" name="Type" value="<%=type%>"/>
<input type="hidden" name="TemplateName" value="<%=templateName%>"/>
<%-- @AGQ081606 --%>
<input type="hidden" name="meetingType" value="<%=meetingType%>" />
<input type="hidden" name="company" value="<%=company%>" />
<input type="hidden" name="StartNow" value=""/>
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
System.out.println("3-StartDate=" + startDate);
System.out.println("   startDT=" + startDT);
System.out.println("   localStartDT=" + localDT);	// ECC: not used

%>
<input type="hidden" name="StartTime" value="<%=startTime%>"/>
<input type="hidden" name="ExpireTime" value="<%=expireTime%>"/>
<input type="hidden" name="StartDate" value="<%=startDate%>"/>
<input type="hidden" name="ExpireDate" value="<%=expireDate%>"/>
<input type="hidden" name="Duration" value="<%=durationS%>"/>

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

<table width="90%" border="0" cellspacing="0" cellpadding="2">
  <tr>
    <td width="20"><img src='../i/spacer.gif' width='20'/></td>
    <td></td>
  </tr>

  <tr>
  	<td></td>
    <td class="plaintext_big">
		<input class="plaintext_big" type="checkbox" name="SendAlert" onclick="showMessage('optMessage')" checked />Send reminder Email to all attendees
	</td>
  </tr>

  <tr><td colspan='2'><img src="../i/spacer.gif" border="0" width="15" height="10"/></td></tr>

	<tr>
	<td colspan='2'>
	<div id='optMessage' name='optMessage' style='display:block'>
	<table width='100%'>
		<tr>
			<td width='20'><img src='../i/spacer.gif' width='20' height='1'/></td>
	        <td class="formtext">
           You may add an optional personal message to the invitation:
        	</td>
		</tr>
		<tr>
			<td></td>
		   	<td>
		   	  <img src='../i/spacer.gif' width='30' height='1'/>
		      <textarea name="message" rows="5" style='width:700px;'><%=optMsg%></textarea>
		   	</td>
		</tr>
	</table>
	</div>
	</td>
	</tr>

  <tr>
  	<td>&nbsp;</td>
    <td class="plaintext_big">
		Click the <b>Finished Button</b> to publish the new meeting.
		To make any changes, click "<b><< Prev</b>" to go back to the previous page.
	</td>
  </tr>
  
  <tr>
    <td>&nbsp;</td>
    <td width="100%" valign="top">
		<table border="0" cellspacing="0" cellpadding="2">
		  <tr>
		    <td colspan="2">&nbsp;</td>
		  </tr>
		  <tr>
		    <td colspan="2" align="center">
				<input type="button" class="button_medium" value="  << Prev  " onclick="goBack()"/>&nbsp;
				<input type="submit" class="button_medium" name="Submit" value=" Finished "/>
		    </td>
		  </tr>
		</table>
	</td>
  </tr>
</table>

</form>

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
