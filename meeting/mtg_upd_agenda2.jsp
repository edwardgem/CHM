<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>

<%
//
//	Copyright (c) 2005, EGI Technologies, Co.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: mtg_upd_agenda2.jsp
//	Author: ECC
//	Date:	03/04/05
//	Description: Update the meeting agenda (step 2 of 2).
//
//	Modification:
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
	
	SimpleDateFormat df1 = new SimpleDateFormat ("MM/dd/yyyy (EEE) hh:mm a");
	SimpleDateFormat df2 = new SimpleDateFormat ("hh:mm a");
	if (!userinfo.isServerTimeZone(myTimeZone)) {
		df1.setTimeZone(myTimeZone);
		df2.setTimeZone(myTimeZone);
	}

	String status = (String)mtg.getAttribute("Status")[0];
	String subject = (String)mtg.getAttribute("Subject")[0];
	String location = (String)mtg.getAttribute("Location")[0];
	if (location == null) location = "";
	String recurring = (String)mtg.getAttribute("Recurring")[0];

	// date
	Date start = (Date)mtg.getAttribute("StartDate")[0];
	Date expire = (Date)mtg.getAttribute("ExpireDate")[0];
	String startS = df1.format(start);
	String expireS = df2.format(expire);
	
	// template type
	String type = request.getParameter("Type");
	// template name
	String templateName = request.getParameter("TemplateName");

	// check agenda items against old, match for exact item name
	String [] sa;
	Object [] oldAgendaArr = mtg.getAttribute("AgendaItem");
	Arrays.sort(oldAgendaArr, new Comparator <Object> ()
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
	
// begin setting up plan stack

	// Agenda is represented by a Vector of Task
	// Task is represented by a hashtable.
	String agendaS = request.getParameter("Agenda");
	Vector rAgenda = new Vector();
	String msg;

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
		msg = st[1];
		msg += ": \"<b>" + st[2] + "</b>\"";
		response.sendRedirect("../out.jsp?msg="+ msg);
		return;
	}
	int i = 0;
	String durationS, owner, s;
	while (true)
	{
		// rTask is the ram task which is in cache
		if (taskArray==null || taskArray[i] == null) break;	// only exit condition

		JwTask pTask = taskArray[i++];
		Hashtable rTask = new Hashtable();

		// for each new agenda item, check to see if it exist in the old and copy over duration and owner
		String pName = pTask.getName();
		if (pName.length() >= 240)
		{
			msg = "The following agenda item is longer than the maximum length (240) allowed:<blockquote>" + pName + "</blockquote>";
			response.sendRedirect("../out.jsp?msg="+ msg);
			return;
		}

		durationS = "";
		owner = "";
		for (int j=0; j<oldAgendaArr.length; j++)
		{
			s = (String)oldAgendaArr[j];
			if (s == null) continue;			// already found match on this old agenda item
			//if (s == null) break;
			sa = s.split(meeting.DELIMITER);
			String s1 = pName.replaceAll("<\\S[^>]*>", "");
			String s2 = sa[3].replaceAll("<\\S[^>]*>", "");
			s2 = s2.replaceAll("@@", ":");
			//if (pName.equals(sa[3]))
			if (s1.equals(s2))
			{
				durationS = sa[4];
				owner = sa[5];
				oldAgendaArr[j] = null;			// match found, nullify this old item
				break;
			}
		}

		// set up agenda item in cache
		rTask.put("Order", pTask.getOrder());
		rTask.put("Level", pTask.getLevel());
		rTask.put("Name", pName);
		rTask.put("Duration", durationS);
		rTask.put("Owner", owner);
		rAgenda.addElement(rTask);
	}
	session.setAttribute("agenda", rAgenda);

// end of setting up plan stack

	// attendee list sorted
	ArrayList attendeeList = new ArrayList();
	Object [] oa = mtg.getAttribute("Attendee");
	user u;
	userManager uMgr = userManager.getInstance();
	for (i=0; i<oa.length; i++)
	{
		if (oa[i] == null) break;
		s = (String)oa[i];
		sa = s.split(meeting.DELIMITER);
		u = (user)uMgr.get(pstuser, Integer.parseInt(sa[0]));
		attendeeList.add(u);
	}
	Object [] attendeeArr = attendeeList.toArray();
	
	// optional message
	String optMsg = request.getParameter("message");
	if (StringUtil.isNullOrEmptyString(optMsg)) optMsg = "";

	////////////////////////////////////////////////////////
%>


<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<jsp:include page="../init.jsp" flush="true"/>
<script language="JavaScript" src="../date.js"></script>
<script language="JavaScript">
<!--

function validation()
{
	/*if (confirm("Do you want to resend the meeting requests? (OK=YES; Cancel=NO)"))
	{
		UpdateAgenda.SendAlert.value = "true";
	}*/

	var diff = getDiffUTC();
	var stD = new Date('<%=startS%>');

	var tm = stD.getTime() + diff;
	stD = new Date(tm);
	document.UpdateAgenda.LocalStartDT.value = formatDate(stD, "MMM dd, yyyy (E) hh:mm a");
	return;
}

function showMessage(id)
{
	var e = document.getElementById(id);
	if (UpdateAgenda.SendAlert.checked == true)
		e.style.display = 'block';
	else
		e.style.display = 'none';
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

<table width="90%" border='0' cellspacing="0" cellpadding="0">
<tr>
	<td width="25"><img src="../i/spacer.gif" border="0" width="25" height="1"/></td>
	<td width="120">&nbsp;</td>
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

<!-- Schedule -->
<tr>
	<td></td>
	<td class="plaintext"><b>Schedule:</b></td>
	<td class="plaintext"><%=startS%> - <%=expireS%>

<%
	int recurMult = 0;
	if (recurring != null)
	{
		sa = recurring.split(meeting.DELIMITER);
		out.print("&nbsp;&nbsp;&nbsp;(" + sa[0] + " event for <b>" + sa[1] + "</b> more occurrences)");
		recurMult = Integer.parseInt(sa[1]);
	}
%>
	</td>
</tr>


<!-- Agenda -->
<tr>
	<td>&nbsp;</td>
	<td class="plaintext" valign="top"><b>Agenda:</b></td>
	<td></td>
</tr>

<tr>
	<td>&nbsp;</td>
	<td colspan='2'>
		<table width='100%' border='0' cellspacing='0' cellpadding='0'>
		<tr>
		<td width='40'>&nbsp;</td>
		<td class="plaintext">

<form method="post" name="UpdateAgenda" action="post_mtg_new.jsp">
<input type="hidden" name="mid" value="<%=midS%>"/>
<input type="hidden" name="LocalStartDT" value=""/>
<input type="hidden" name="Type" value="<%=type %>"/>
<input type="hidden" name="TemplateName" value="<%=templateName %>"/>

<%
	int duration, ownerId;
	String[] levelInfo = new String[10];
	for(i = 0; i < rAgenda.size(); i++)
	{
		Hashtable rTask = (Hashtable)rAgenda.elementAt(i);
		String pName = (String)rTask.get("Name");
		Integer pLevel = (Integer)rTask.get("Level");
		Integer pOrder = (Integer)rTask.get("Order");
		String pDur = (String)rTask.get("Duration");
		if (pDur == "")
			duration = 0;			// default allocated time is 0 min (- -)
		else
			duration = Integer.parseInt(pDur);

		String ownerIdS = (String)rTask.get("Owner");
		if (ownerIdS == "")
			ownerId = myUid;
		else
			ownerId = Integer.parseInt(ownerIdS);

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
		out.print("<option value='" + meeting.iAGENDA_NONE + "'");
		if (ownerId==meeting.iAGENDA_NONE) {out.print(" selected");}
		out.print(">- -</option>");
		out.print("<option value='" + meeting.iAGENDA_ALL + "'");
		if (ownerId==meeting.iAGENDA_ALL) {out.print(" selected");}
		out.print(">All</option>");

		if (attendeeArr != null && attendeeArr.length > 0)
		{
			for (int j=0; j < attendeeArr.length; j++)
			{
				u = (user)attendeeArr[j];
				if (u== null) continue;
				String firstName = (String)u.getAttribute("FirstName")[0];
				String lastName = (String)u.getAttribute("LastName")[0];
				String uName = firstName + (lastName==null?"":(" "+lastName));
				out.print("<option value='" + u.getObjectId() + "'");
				if (u.getObjectId() == ownerId) out.print(" selected");
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
	</tr></table>

	</td>
</tr>

<tr><td colspan="3"><img src='../i/spacer.gif' height='10'></td></tr>


<!-- Update all recurring event? -->
<%	if (recurMult>0)
	{%>
	<tr>
  		<td>&nbsp;</td>
		<td colspan='2' class="plaintext_big">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
		<input class="plaintext_big" type="checkbox" name="UpdateRecur">Update all recurring events after this
		</td>
	</tr>
<%	}%>

  <tr>
  	<td>&nbsp;</td>
    <td colspan="2" class="plaintext_big">
		<input class="plaintext_big" type="checkbox" name="SendAlert" onClick="showMessage('optMessage');" >Send reminder Email to all attendees
	</td>
  </tr>

  <tr><td colspan='2'><img src="../i/spacer.gif" border="0" width="15" height="10"></td></tr>

	<tr>
	<td colspan='3'>
	<div id='optMessage' name='optMessage' style='display:none'>
	<table>
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
    <td colspan='2' class="plaintext_big">
		Click the <b>Finished Button</b> to publish the new meeting.
		To make any changes, click "<b><< Prev</b>" to go back to the previous page.
	</td>
  </tr>

<tr><td colspan="3">&nbsp;</td></tr>

<!-- Submit Button -->
	<tr>
	<td colspan="3" align="center"><br>
		<input type="button" class="button_medium" value="  << Prev  " onclick="history.back(-1)"/>&nbsp;
		<input type="submit" class="button_medium" name="Submit" onclick="validation();" value=" Publish "/>
	</td>
	</tr>
</form>

</table>
		<!-- End of Content Table -->
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
