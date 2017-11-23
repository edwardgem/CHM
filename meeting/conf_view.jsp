<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>

<%
////////////////////////////////////////////////////
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	conf_view.jsp
//	Author:	SC
//	Date:	02/11/15
//	Description:
//		Display conference room and the associated meetings.
//
//	Modification:
//
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	final String [] MONTH_ARRAY	= {"Jan", "Feb", "Mar", "Apr", "May", "Jun",
									"Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};


	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	
	confManager cfMgr = confManager.getInstance();
	meetingManager mtgMgr = meetingManager.getInstance();
	userManager uMgr = userManager.getInstance();
	
	// roles
	Integer io = (Integer)session.getAttribute("role");
	int iRole = 0;
	if (io != null) iRole = io.intValue();
	boolean isAdmin = (iRole & user.iROLE_ADMIN)>0;
	boolean isProgMgr = (iRole & user.iROLE_PROGMGR)>0;
	boolean isAdminAsst = (iRole & user.iROLE_ADMIN_ASST)>0;

	
	// parameters
	String s = request.getParameter("upd");
	boolean bUpdate = (s!=null && s.equals("1"));
	
	Calendar todayCal = Calendar.getInstance();
	int month, year;
	String dtStr;		// yyyy.MM.dd.HH.mm.ss

	String monthS = request.getParameter("mn");	// it is a digit here, will convert to January
	String yearS = request.getParameter("yr");

	if (monthS == null)
	{
		month = todayCal.get(Calendar.MONTH);
		year  = todayCal.get(Calendar.YEAR);
		monthS = MONTH_ARRAY[month];
		yearS  = String.valueOf(year);
	}
	else
	{
		month = Integer.parseInt(monthS);
		monthS = MONTH_ARRAY[month];
		year = Integer.parseInt(yearS);
	}

	
	dtStr = yearS + "."
				+ String.format("%02d", month+1) + "."
				+ "01."
				+ "00.00.00";
	
	// see if I need to save a conf description
	String confIdS = request.getParameter("confID");
	String desc = request.getParameter("desc");
	
	if (!StringUtil.isNullOrEmptyString(confIdS) && desc!=null) {
		if (desc == "") desc = null;
		
		PstAbstractObject cfObj = cfMgr.get(pstuser, confIdS);
		cfObj.setAttribute("Description", desc.getBytes("UTF-8"));
		cfMgr.commit(cfObj);
		
		String msg = "Update Description successful: " + cfObj.getStringAttribute("Name");
		ArrayList<String> errList = new ArrayList<String>();
		errList.add(msg);
		session.setAttribute("errorList", errList);
	}
	

%>



<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<jsp:include page="../errormsg.jsp" flush="true"/>

<script language="JavaScript">
<!--

function saveConf(confID)
{
	var e = document.getElementById(confID);
	updConfRoom.confID.value = confID;
	updConfRoom.desc.value = e.value;
	if (<%=bUpdate%>)
		updConfRoom.upd.value = "1";
	
	updConfRoom.submit();
}

function backward()
{
	var mn = parseInt('<%=month%>');
	var yr = parseInt('<%=year%>');

	if (mn == 0)
	{
		mn = 11;
		yr -= 1;
	}
	else
		mn -= 1;

	var f = document.updConfRoom;
	f.mn.value = mn;
	f.yr.value = yr;
	f.submit();
}

function forward()
{
	var mn = parseInt('<%=month%>');
	var yr = parseInt('<%=year%>');

	if (mn == 11)
	{
		mn = 0;
		yr += 1;
	}
	else
		mn += 1;

	var f = document.updConfRoom;
	f.mn.value = mn;
	f.yr.value = yr;
	f.submit();
}

//-->
</script>

<title>
	CPM Conference Room
</title>

</head>


<body bgcolor="#FFFFFF" >

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="95%" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<table width='90%'>

	<tr><td colspan="2">&nbsp;</td></tr>
	<tr>
	<td></td>
	<td>
		<b class="head">
		Conference Rooms Booking
		</b>
	</td>
	<td align='right'>
		<table>
		<tr><td>
		<img src='../i/bullet_tri.gif' width='20' height='10' />
		<a class='listlinkbold' href='cal.jsp'>Back to Calendar</a>
		</td></tr>
		
<%	if (isAdmin || isProgMgr) {
		out.print("<tr><td>");
		out.print("<img src='../i/bullet_tri.gif' width='20' height='10' />");

		if (!bUpdate)
			out.print("<a class='listlinkbold' href='conf_view.jsp?upd=1'>Update Conference Rooms</a>");
		else
			out.print("<a class='listlinkbold' href='conf_view.jsp'>View Conference Rooms</a>");

		out.print("</td></tr>");
	}
%>		
		
		</table>
	</td>
	</tr>
	
	<tr><td><img src='../i/spacer.gif' width='1' height='10'/></td></tr>
	
	<tr>
		<td></td>
		<td width='400' class="plaintext_blue">
			<a class='listlinkbold' href='javascript:backward();'>&lt;&lt;</a>
			&nbsp;<%=monthS%>&nbsp;<%=yearS%>&nbsp;
			<a class='listlinkbold' href='javascript:forward();'>&gt;&gt;</a>
		</td>
	</tr>
	
	</table>

	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1"/></td>
	    </tr>
	</table>

<!-- CONTENT -->
<table border='0'>
<tr>
<td><img src='../i/spacer.gif' height='5' width='20'/></td>
<td>

<form name='updConfRoom' method='post' action='conf_view.jsp'>
<input type='hidden' name='confID' value='' />
<input type='hidden' name='desc' value='' />
<input type='hidden' name='upd' value='' />
<input type='hidden' name='mn' value='' />
<input type='hidden' name='yr' value='' />

<table>


<%
	//get all conf rooms
	//for each conf room get all meetings that are coming up
	//meeting details will be [meeting name; start time & end time; meeting owner]
	
	String name;
	SimpleDateFormat df1 = new SimpleDateFormat("MM/dd/yyyy (EEE)");
	SimpleDateFormat df2 = new SimpleDateFormat("hh:mm a");
	SimpleDateFormat df3 = new SimpleDateFormat("yyyy.MM.dd.HH.mm.ss");
		
	
	userinfo.setTimeZone(pstuser, df1);
	userinfo.setTimeZone(pstuser, df2);

	int [] confRoomIdArr = cfMgr.findId(pstuser, "om_acctname='%'");
	PstAbstractObject [] confRoomArr = cfMgr.get(pstuser, confRoomIdArr);
	
	Util.sortString(confRoomArr, "Name", true);

	PstAbstractObject mtgObj, confObj;
	int [] mtgIdArr;
	Date date, st, ex;
	String mtgName, ownerId, ownerName, confRoomIdS;
	String bText;
	Object bTextObj;
	
	for (int i = 0; i < confRoomArr.length; i++) {
		
		confObj = confRoomArr[i];
		confRoomIdS = confObj.getObjectName();
		name = confObj.getStringAttribute("Name");
		
		bTextObj = confObj.getAttribute("Description")[0];
		bText = (bTextObj==null) ? "" : new String((byte[])bTextObj, "utf-8");
		
		out.print("<tr><td><img src='../i/spacer.gif' height='10' width='1'/></td>");			
		out.print("<tr><td><hr class='evt_hr' style='width:15%'/></td></tr>");

		out.print("<tr><td>");
		out.print("<table border='0'><tr><td class='plaintext_big' width='150'><b>");
		out.print(name);
		out.print("</b></td>");
		out.print("<td class='ptextS1'>");
		if (bUpdate) {
			out.print("<input type='text' size='50' id='" + confRoomIdS
				+ "' value='" + bText + "' />&nbsp;&nbsp;&nbsp;");
			out.print("<input type='button' class='button_medium' value='Save' "
				+ " onclick='saveConf(" + confRoomIdS + ");'/>");
		}
		else {
			out.print(bText);
		}
		out.print("</td></tr></table>");
		out.print("</td></tr>");
	

		//print each meeting that booked the conference room
		out.print("<tr><td><table border = '0'>");

		mtgIdArr = mtgMgr.findId(pstuser,
				  "Location='" + confRoomIdS + "'"
				+ "&& StartDate>='" + dtStr + "'"
				);

		for (int j = 0; j < mtgIdArr.length; j++) {
			mtgObj = mtgMgr.get(pstuser, mtgIdArr[j]);
			
			mtgName = mtgObj.getStringAttribute("Subject");
			ownerId = mtgObj.getStringAttribute("Owner");
			user ou = (user)uMgr.get(pstuser, Integer.parseInt(ownerId));
			//ownerName = (String)ou.getAttribute("FirstName")[0] + " " + (String)ou.getAttribute("LastName")[0];
			ownerName = ou.getFullName();
			
			st = (Date) mtgObj.getAttribute("StartDate")[0];
			ex = (Date) mtgObj.getAttribute("ExpireDate")[0];
			
			out.print("<tr><td><img src='../i/spacer.gif' height='1' width='40'/></td>");			
			out.print("<td><img src='../i/bullet_tri.gif' width='20' height='10'/></td>");
			
			out.print("<td width='150' class='ptextS1'>" + df1.format(st) + "</td>");
			out.print("<td width='200' class='ptextS1'>" + df2.format(st) + "-" + df2.format(ex) + "</td>");
			
			out.print("<td width='250' class='ptextS1'>"
				+ "<a href='mtg_view.jsp?mid=" + mtgIdArr[j] + "'>"
				+ mtgName + "</a></td>");

			out.print("<td width='300' class='ptextS1'>(" + ownerName + ")</td></tr>");
			out.print("</td></tr>");
		}

		out.print("</table></td></tr>");
	}
%>

</table>
</form>

</td>
</tr>
</table>

<tr><td>&nbsp;</td></tr>




<!-- BEGIN FOOTER TABLE -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

