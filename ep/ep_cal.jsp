<table border='0' height='100%'>
<tr>
<td valign='top'>
<style type="text/css">

ul#cal_omf {padding:0; margin:0; list-style-type:none; bottom:0; right:0; width:186px; height:150px; position:absolute; font-family:arial, sans-serif; font-size:10px; background:#4060a0;border-bottom:1px solid #444; border-right:1px solid #444; border-top:1px solid #d4d8bd; border-left:10px solid #4060a0;}
ul#cal_omf li.top {display:block; float:left; width:30px; height:30px; text-align:center; margin:5px 0 55px 0;}
ul#cal_omf li.bottom {display:block; float:left; width:30px; height:30px; text-align:center; margin:55px 0 0 0;}
ul#cal_omf li a, ul#cal_omf li a:visited {text-decoration:none; display:block; color:#000; font-weight:normal;}
ul#cal_omf li a.month_bot, ul#cal_omf li a.month_bot:visited {text-decoration:none; display:block; color:#000; font-weight:bold; margin-top:14px; width:30px;}


ul#cal_omf table {font-size:10px; background:#a0c0c0; border-collapse:collapse; width:177px;}
ul#cal_omf tbody td {text-align:center; background:#fff; border:1px solid #aaa; padding:0; width:25px; height:17px; margin:0;}
ul#cal_omf tbody td.blank {background:#d4d8bd;}
ul#cal_omf caption  {font-weight:bold; font-size:11px;}
ul#cal_omf caption td.blank {font-weight:bold; font-size:11px; border:0;}
ul#cal_omf thead th {color:#840; font-size:9px;}
ul#cal_omf tfoot td {text-align:center; color:#840; font-size:9px;}


ul#cal_omf td a, ul#cal_omf td a:visited {color:#345; text-decoration:none; display:block; width:100%; height:100%; line-height:15px;}

ul#cal_omf li a.month_top:hover {border:0; height:30px;}
ul#cal_omf li a.month_bot:hover {border:0; margin:0; padding-top:14px;}


ul#cal_omf :hover table {top:25px; left:6px;}
ul#cal_omf :hover table :hover {background:#d4d8bd;cursor:pointer;}

div#caltext {display:none;}

#box2, #box3 {display:block; position:absolute; top:2px; left:2px;}
#box1 {display:block; width:195px; height:150px; position:relative; top:20px; left:0; background:#ccc; border:2px solid #eee; margin:0 auto;}
#box2 {width:187px; height:142px; background:#999; border:2px solid #aaa;}
#box3 {width:179px; height:134px; background:#777; border:2px solid #888;}

</style>

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

<%	String noSession = "../out.jsp?go=ep/ep_home.jsp";%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<script language="JavaScript" src="../date.js"></script>

<%
	final String [] MONTH_ARRAY_LONG	= {"January", "February", "March", "April", "May", "June",
		"July", "August", "September", "October", "November", "December"};
	final String [] MONTH_ARRAY	= {"Jan", "Feb", "Mar", "Apr", "May", "Jun",
		"Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};
	
	String myIdS = String.valueOf(pstuser.getObjectId());

	// get month and year
	String monthS = request.getParameter("month");	// it is a digit here, will convert to January
	String yearS = request.getParameter("year");
	Calendar today = Calendar.getInstance();
	int todayDy = today.get(Calendar.DAY_OF_MONTH);
	int todayMo = today.get(Calendar.MONTH);
	int todayYr = today.get(Calendar.YEAR);
	int month, year;
	boolean bFutureMo = false;

	if (monthS == null)
	{
		month = todayMo;
		year  = todayYr;
		monthS = MONTH_ARRAY[month];
		yearS  = String.valueOf(year);
	}
	else
	{
		month = Integer.parseInt(monthS);
		monthS = MONTH_ARRAY[month];
		year = Integer.parseInt(yearS);
		if ( (month>todayMo && year==today.get(Calendar.YEAR)) || year>today.get(Calendar.YEAR) )
			bFutureMo = true;
	}

	// get the list of meeting events for this month
	Calendar ca = Calendar.getInstance();
	ca.set(Calendar.MONTH, month);
	int lastDay = ca.getActualMaximum(Calendar.DAY_OF_MONTH);
	ca.set(year, month, 1, 7, 0);
	Date firstD = ca.getTime();
	ca.set(year, month, lastDay, 23, 59);
	Date lastD = ca.getTime();
	lastD = new Date(lastD.getTime() + 8*3600000);	// workaround: include 8 more hours to get Asia
	SimpleDateFormat df = new SimpleDateFormat ("yyyy.MM.dd.HH.mm.ss");
	SimpleDateFormat df1 = new SimpleDateFormat ("MM/dd/yyyy hh:mm a");
	SimpleDateFormat df2 = new SimpleDateFormat ("d");
	SimpleDateFormat df3 = new SimpleDateFormat ("M/dd/yy");
	SimpleDateFormat df4 = new SimpleDateFormat ("M/dd");

	meetingManager mMgr = meetingManager.getInstance();
	String expr = "(StartDate>='" + df.format(firstD)+ "') && (StartDate<='" + df.format(lastD) + "')";

	int [] mIds = mMgr.findId(pstuser, expr);
	PstAbstractObject [] mtgArr = mMgr.get(pstuser, mIds);

	int len = mtgArr.length;
	if (len > 1)
		Util.sortDate(mtgArr, "StartDate");

	// for faster comparision with multiple towns
	String townString = "";
	Object [] townIds = pstuser.getAttribute("Towns");
	if (townIds[0]!=null)
		for (int i=0; i<townIds.length; i++)
			townString += townIds[i].toString() + ";";

	String s;
	Date dt;
	int currentDate = 0;
	int nextDate;

	String jMtgStr = "", tempJ = "";			// use for javascript to identify dates that have meetings
	boolean found;
	for (int i=0; i<len; i++)
	{
		found = false;
		meeting m = (meeting)mtgArr[i];
		if (m == null)
			continue;
		
		dt = (Date)m.getAttribute("StartDate")[0];
		dt = new Date(dt.getTime() - 25200000);		// minus 7 hrs.
		nextDate = Integer.parseInt(df2.format(dt));

		Object obj = m.getAttribute("Type")[0];
		String meetingType = meeting.PRIVATE;
		if (obj!=null) meetingType = (String) obj;			
		
		if (nextDate > currentDate)
		{
			if (jMtgStr.length() > 0)
				tempJ = ":";
			else
				tempJ = "";
			tempJ += nextDate;
			currentDate = nextDate;
		}

		if (meetingType.equalsIgnoreCase(meeting.PRIVATE))
		{ 
			if (myIdS.equals(m.getAttribute("Owner")))
			{
				jMtgStr += tempJ;
				tempJ = "";
				continue;					// found
			}

			Object [] oArr = m.getAttribute("Attendee");
			for (int j=0; j<oArr.length; j++)
			{
				s = (String)oArr[j];
				if (s == null) break;		// no attendee
				if (s.startsWith(myIdS))
				{
					found = true;
					jMtgStr += tempJ;
					tempJ = "";
					break;					// found
				}
			}
			
			// check to see if the same town
			String mtgTownId = (String)m.getAttribute("TownID")[0];
			if ( townIds[0]!=null && mtgTownId!=null && townString.indexOf(mtgTownId)!=-1)
			{
				jMtgStr += tempJ;
				tempJ = "";
				continue;
			}
			
			if (!found)
				mtgArr[i] = null;			// don't show this meeting
		}
		else
		{
			// public meeting
			jMtgStr += tempJ;
			tempJ = "";
		}
	}

%>
<script language="JavaScript">
<!--
var tog = false;
var remember;
var gNow = new Date();

function op() {}
function toggle(id)
{	
	tog = !tog;
	if (tog == true)
		remember = id;
	else
	{
		hideEvent(remember);
		showEvent(id);
	}
}

function showEvent(id)
{
	if (tog != null && tog == true)
		return;
	var e = document.getElementById(id);
	e.style.display = 'block';
}

function hideEvent(id)
{
	if (tog != null && tog == true)
		return;
	var e = document.getElementById(id);
	e.style.display = 'none';
}

var gMtgArr = new Array(31);
Calendar.DOMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]; // Non-Leap year Month days..
Calendar.lDOMonth = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]; // Leap year Month days..

//This function write the layout of the actually output.
function showCal()
{
	var vCode = "";

	// Get the complete calendar code for the month..
	vCode = this.getMonthlyCalendarCode();
	document.write(vCode);

}

function getMonthlyCalendarCode()
{
	var vCode = "";
	var vHeader_Code = "";
	var vData_Code = "";

	vHeader_Code = this.cal_header();
	vData_Code = this.cal_data('<%=month%>', '<%=year%>');
	vCode = vCode + vHeader_Code + vData_Code;

	return vCode;
}

function cal_header()
{
	var vCode = "";

	vCode = vCode + "<thead>";
	vCode = vCode + "<th>Sun</th>";
	vCode = vCode + "<th>Mon</th>";
	vCode = vCode + "<th>Tue</th>";
	vCode = vCode + "<th>Wed</th>";
	vCode = vCode + "<th>Thu</th>";
	vCode = vCode + "<th>Fri</th>";
	vCode = vCode + "<th>Sat</th>";
	vCode = vCode + "</thead>";

	return vCode;
}

function cal_data(p_month, p_year)
{
	var vDate = new Date();
	this.gMonth = new Number(p_month);
	this.gYear = p_year;

	vDate.setDate(1);
	vDate.setMonth(this.gMonth);
	vDate.setFullYear(this.gYear);

	var vFirstDay=vDate.getDay();
	var vDay=1;
	var vLastDay=Calendar_get_daysofmonth(this.gMonth, this.gYear);
	var vOnLastDay=0;
	var vCode = "";

	// process meeting string to bold dates that have meetings
	var str = "<%=jMtgStr%>";
	var sa = new Array();
	sa = str.split(":");

	for (i=0; i<sa.length; i++)
	{
		if (sa[i] != "")
		{
			j = parseInt(sa[i]);
			gMtgArr[j] = "y";
		}
	}

	// use gSameMoYr to eval and highlight today in RED
	this.gSameMoYr = true;
	if (gNow.getMonth() != this.gMonth || gNow.getFullYear() != parseInt(this.gYear))
		this.gSameMoYr = false;

/*
Get day for the 1st of the requested month/year..
Place as many blank cells before the 1st day of the month as necessary.
*/
	// leading blanks
	vCode = vCode + "<tbody><tr>";
	for (i=0; i<vFirstDay; i++)
	{
		vCode = vCode + "<td class='blank'></td>";
	}

	// Write rest of the 1st week (1, 2, ...)
	for (j=vFirstDay; j<7; j++)
	{
		vCode = vCode + "<td><a href='javascript:op();' onClick=toggle('mtgDisp" + vDay + "') onMouseOver=showEvent('mtgDisp" + vDay + "') onMouseOut=hideEvent('mtgDisp" + vDay + "')>"
				+ this.format_day(vDay);

		/*if (gMtgArr[vDay] != null)
		{
			// write events
			vCode += gMtgArr[vDay];
		}*/
		vCode += "</a></td>";
		vDay=vDay + 1;
	}
	vCode = vCode + "</tr>";

	// Write the rest of the weeks
	for (k=2; k<7; k++)
	{
		vCode = vCode + "<tr>";

		var s = '';
		for (j=0; j<7; j++)
		{
			vCode = vCode + "<td><a href='javascript:op();' onClick=toggle('mtgDisp" + vDay + "') onMouseOver=showEvent('mtgDisp" + vDay + "') onMouseOut=hideEvent('mtgDisp" + vDay + "')>"
					+ this.format_day(vDay);

			/*if (gMtgArr[vDay] != null)
			{
				// write events
				vCode += gMtgArr[vDay];
			}*/
			vCode += "</a></td>";
			vDay=vDay + 1;

			if (vDay > vLastDay)
			{
				vOnLastDay = 1;
				break;
			}
		}

		if (j == 6)
			vCode = vCode + "</tr>";
		if (vOnLastDay == 1)
			break;
	}

	// Fill up the rest of last week with proper blanks, so that we get proper square blocks
	for (m=1; m<(7-j); m++)
	{
		vCode = vCode + "<td class='blank'></td>";
	}

	vCode = vCode + "</tbody>";
	return vCode;

}

function format_day(vday)
{
	if (vday == gNow.getDate() && this.gSameMoYr)
	{
		var s = "<FONT COLOR='#ff6666'><B";
		if (gMtgArr[vday] != null)
			s += " title='click to select a meeting'";
		s += ">" + vday + "</B></FONT>";
		return (s);
	}
	else
	{
		if (gMtgArr[vday] != null)
			return ("<b title='click to select a meeting'>" + vday + "</b>");
		else
			return (vday);
	}
}

function Calendar_get_daysofmonth(monthNo, p_year)
{
/*
Check for leap year ..
1.Years evenly divisible by four are normally leap years, except for...
2.Years also evenly divisible by 100 are not leap years, except for...
3.Years also evenly divisible by 400 are leap years.
*/
	if ((p_year % 4) == 0)
	{
		if ((p_year % 100) == 0 && (p_year % 400) != 0)
			return Calendar.DOMonth[monthNo];

		return Calendar.lDOMonth[monthNo];
	}
	else
		return Calendar.DOMonth[monthNo];
}

function backward()
{
	var mon = parseInt('<%=month%>');
	var yr = parseInt('<%=year%>');

	if (mon == 0)
	{
		mon = 11;
		yr -= 1;
	}
	else
		mon -= 1;

	var f = document.cal;
	f.month.value = mon;
	f.year.value  = yr;
	f.submit();
}

function forward()
{
	var mon = parseInt('<%=month%>');
	var yr = parseInt('<%=year%>');

	if (mon == 11)
	{
		mon = 0;
		yr += 1;
	}
	else
		mon += 1;

	var f = document.cal;
	f.month.value = mon;
	f.year.value  = yr;
	f.submit();
}

//-->
</script>

<div id="box1">
<div id="box2">
<div id="box3">

<ul id="cal_omf">

<li class="top"><a class="month_top" href="#"><!--[if IE 7]><!--></a><!--<![endif]-->
<table border='0'>

<form name="cal" action="ep_home.jsp" method="post">
	<input type="hidden" name="month" value="<%=monthS%>">
	<input type="hidden" name="year" value="<%=yearS%>">


<caption>
	<table border='0' width='100' cellspacing='0' cellpadding='0'>
		<tr>
		<td class='blank'><img src='../i/spacer.gif' width='30' height='1' border='0'></td>
		<td class='blank' align='center'><a href='javascript:backward();'><<</a></td>
		<td class='blank' align='center'><%=MONTH_ARRAY[month]%>&nbsp;<%=yearS%></td>
		<td class='blank' align='center'><a href='javascript:forward();'>>></a></td>
		<td class='blank'><img src='../i/spacer.gif' width='20' height='1' border='0'></td>
		</tr>
	</table>
</caption>

<tr>
<script language="JavaScript">
	showCal();
</script>
</tr>
</form>
<tfoot>
<!--tr><td colspan="7">&copy;2006 MeetME, Inc.</td></tr-->
</tfoot>
</table>
<!--[if lte IE 6]></a><![endif]--></li>

</ul>

</div>
</div>
</div>

<br /><br />
<%
	currentDate = 0;
	//int nextDate; //= ca.getActualMinimum(Calendar.DAY_OF_MONTH);
	int lastDate = ca.getActualMaximum(Calendar.DAY_OF_MONTH);
	String mtgStr = "";
	String start=null, dtLabel;
	int thisMonth = month + 1;
	int thisYear = year;
	String fName = (String)pstuser.getAttribute("FirstName")[0];

	PstAbstractObject mo;
	for (int i=0; i<len; i++)
	{
		mo = mtgArr[i];
		if (mo == null) continue;
		dt = (Date)mo.getAttribute("StartDate")[0];
		start = df1.format(dt);
		dt = new Date(dt.getTime() - 7*3600000);
		dtLabel = df3.format(dt);
		mtgStr = (String)mo.getAttribute("Subject")[0];
		int id = mtgArr[i].getObjectId();
		nextDate = Integer.parseInt(df2.format(dt));
		
		// nextDate contains this meeting day of the month
		if (nextDate > currentDate)
		{
			if (currentDate >0)
			{
				if (bFutureMo || (year==todayYr && month==todayMo && currentDate >= todayDy) )
				{
					out.print("<tr><td colspan='2'><table cellspacing='0' cellpadding='0'><tr><td valign='baseline'><img src='../i/bullet_tri.gif' width='20' height='10'></td><td valign='top' class='listlink'>");
					out.print("<a href='../meeting/mtg_new1.jsp?Subject=" + fName
							+ "&#39s Meeting&StartDate=" +thisMonth+"/"+currentDate+"/"+thisYear+ "'>Schedule a meeting on "+thisMonth+"/" + currentDate +"</a></td></tr></table></td></tr>");
				}
				out.print("</table></div>");
			}
			
			//currentDate = nextDate;
			//out.print("<div class='caltext' id='mtgDisp" + currentDate + "' style='display:none'><table>");
			
			for (int j=currentDate; j<=nextDate; j++)
			{
				out.print("<div class='caltext' id='mtgDisp" + currentDate + "' name='mtgDisp" + currentDate + "'style='display:none'>");
				if (currentDate == nextDate)
				{
					out.print("<table height='20' cellspacing='0' cellpadding='0'><tr><td valign='top' class='plaintext'><b>"+ dtLabel + " Events:</b></td></tr></table>");
					out.print("<table cellspacing='0' cellpadding='0'>");
				}
				else 
				{
					if (bFutureMo || (year==todayYr && month==todayMo && currentDate >= todayDy) )
					{
						out.print("<table cellspacing='0' cellpadding='0'><tr><td valign='baseline'><img src='../i/bullet_tri.gif' width='20' height='10'></td><td valign='top' class='listlink'>");
						out.print("<a href='../meeting/mtg_new1.jsp?Subject=" + fName
								+ "&#39s Meeting&StartDate=" +thisMonth+"/"+currentDate+"/"+thisYear+ "'>Schedule a meeting on "+thisMonth+"/" + currentDate +"</a></td></tr></table>");
					}
					out.print("</div>");
					currentDate++;
				}
			}
		}
		
		out.print("<tr><td valign='top' class='plaintext'>");
%>
<script language="JavaScript">
// <!-- Begin
		var diff = getDiffUTC();
		var stD = new Date('<%=start%>');
		var tm = stD.getTime() + diff;
		stD = new Date(tm);
		document.write(formatDate(stD, "hh:mm a"));
// End -->
</script>
<%
		out.print("&nbsp;&nbsp;</td>");
		out.print("<td width='130' valign='top'><a class='listlink' href='../meeting/mtg_view.jsp?mid=" + id + "'>" + mtgStr + "</a></td></tr>");
	}	// end for loop of len
	
	if (start!=null)
	{
		if (bFutureMo || (year==todayYr && month==todayMo && currentDate >= todayDy) )
		{
			out.print("<tr><td colspan='2'><table cellspacing='0' cellpadding='0'><tr><td valign='baseline'><img src='../i/bullet_tri.gif' width='20' height='10'></td><td valign='top' class='listlink'>");
			out.print("<a href='../meeting/mtg_new1.jsp?Subject=" + fName
					+ "&#39s Meeting&StartDate=" +thisMonth+"/"+currentDate+"/"+thisYear+ "'>Schedule a meeting on "+thisMonth+"/" + currentDate +"</a></td></tr></table></td></tr>");
		}
		out.print("</table></div>");
	}
	if (currentDate < lastDate)
	{
		for (int i=currentDate; i<=lastDate; i++)
		{
			out.print("<div class='caltext' id='mtgDisp" + currentDate + "' style='display:none'>");
			if (bFutureMo || (year==todayYr && month==todayMo && currentDate >= todayDy) )
			{
				out.print("<table cellspacing='0' cellpadding='0'><tr><td valign='baseline'><img src='../i/bullet_tri.gif' width='20' height='10'></td><td class='listlink'>");
				out.print("<a href='../meeting/mtg_new1.jsp?Subject=" + fName
						+ "&#39s Meeting&StartDate=" +thisMonth+"/"+currentDate+"/"+thisYear+ "'>Schedule a meeting on "+thisMonth+"/" + currentDate +"</a></td></tr></table>");
			}
			out.print("</div>");
			currentDate++;
		}
	}
%>

<br /><br />

</td>
</tr>

</table>
