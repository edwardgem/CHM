var weekend = [0,6];
var weekendColor = "#e0e0e0";
var fontface = "Verdana";
var fontsize = 2;

var gNow = new Date();
var ggWinCal;
var gMtgArr = new Array(31);
var gDayArr = new Array(31);
var showingYrMo = "";

isNav = (navigator.appName.indexOf("Netscape") != -1) ? true : false;
isIE = (navigator.appName.indexOf("Microsoft") != -1) ? true : false;

Calendar.Months = ["January", "February", "March", "April", "May", "June",
"July", "August", "September", "October", "November", "December"];

// Non-Leap year Month days..
Calendar.DOMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
// Leap year Month days..
Calendar.lDOMonth = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

function Calendar(p_item, p_WinCal, p_month, p_year, p_format, p_mtgStr, p_dayStr)
{
	if ((p_month == null) && (p_year == null))	return;

	for (i=0; i<gMtgArr.length; i++)
	{
		gMtgArr[i] = null;
		gDayArr[i] = null;
	}
	var sa = new Array();
	
	// meeting and event array
	sa = p_mtgStr.split("::");
	var dy;
	for (i=0; i<sa.length; i++)
	{
		dy = parseInt(sa[i++]);
		gMtgArr[dy] = sa[i];
	}

	// day array
	sa = p_dayStr.split("::");
	for (i=0; i<sa.length; i++)
	{
		dy = parseInt(sa[i++]);
		if (gDayArr[dy] == null) gDayArr[dy] = "";
		else gDayArr[dy] += "<BR><BR>";
		gDayArr[dy] += sa[i];
	}

	if (p_WinCal == null)
		this.gWinCal = ggWinCal;
	else
		this.gWinCal = p_WinCal;

	if (p_month == null) {
		this.gMonthName = null;
		this.gMonth = null;
		this.gYearly = true;
	} else {
		this.gMonthName = Calendar.get_month(p_month);
		this.gMonth = new Number(p_month);
		this.gYearly = false;
	}
	this.gYear = p_year;
	this.gFormat = p_format;
	this.gBGColor = "white";
	this.gFGColor = "black";
	this.gTextColor = "black";
	this.gHeaderColor = "white";
	this.gHeaderBkgd = "#000077";
	this.gCellHeight = "80";
	this.gReturnItem = p_item;

	this.gSameMoYr = true;
	if (gNow.getMonth() != this.gMonth || gNow.getFullYear() != this.gYear)
		this.gSameMoYr = false;
	showingYrMo = this.gYear + "/" + (this.gMonth+1);
}

Calendar.get_month = Calendar_get_month;
Calendar.get_daysofmonth = Calendar_get_daysofmonth;
Calendar.calc_month_year = Calendar_calc_month_year;
Calendar.print = Calendar_print;

function Calendar_get_month(monthNo)
{
	return Calendar.Months[monthNo];
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

function Calendar_calc_month_year(p_Month, p_Year, incr)
{

/*
Will return an 1-D array with 1st element being the calculated month
and second being the calculated year
after applying the month increment/decrement as specified by 'incr' parameter.
'incr' will normally have 1/-1 to navigate thru the months.
*/
	var ret_arr = new Array();

	if (incr == -1)
	{
		// B A C K W A R D
		if (p_Month == 0)
		{
			ret_arr[0] = 11;
			ret_arr[1] = parseInt(p_Year) - 1;
		}
		else
		{
			ret_arr[0] = parseInt(p_Month) - 1;
			ret_arr[1] = parseInt(p_Year);
		}
	}
	else if (incr == 1)
	{
		// F O R W A R D
		if (p_Month == 11)
		{
			ret_arr[0] = 0;
			ret_arr[1] = parseInt(p_Year) + 1;
		}
		else
		{
			ret_arr[0] = parseInt(p_Month) + 1;
			ret_arr[1] = parseInt(p_Year);
		}
	}

	return ret_arr;
}

function Calendar_print()
{
	ggWinCal.print();
}

// This is for compatibility with Navigator 3, we have to create and discard one object before the prototype object exists.
new Calendar();

Calendar.prototype.getMonthlyCalendarCode = function()
{
	var vCode = "";
	var vHeader_Code = "";
	var vData_Code = "";

	// Begin Table Drawing code here..
	vCode = vCode + "<TABLE width='100%' BORDER=0 BGCOLOR=\"" + this.gBGColor + "\">";

	vHeader_Code = this.cal_header();
	vData_Code = this.cal_data();
	vCode = vCode + vHeader_Code + vData_Code;

	vCode = vCode + "</TABLE>";

	return vCode;
}

//This function write the layout of the actually output.
Calendar.prototype.show = function()
{
	var vCode = "";

	// Get the complete calendar code for the month..
	vCode = this.getMonthlyCalendarCode();
	document.write(vCode);
}

Calendar.prototype.showY = function()
{
	var vCode = "";
	var i;
	var vr, vc, vx, vy;		// Row, Column, X-coord, Y-coord
	var vxf = 285;			// X-Factor
	var vyf = 200;			// Y-Factor
	var vxm = 10;			// X-margin
	var vym;			// Y-margin
	if (isIE)	vym = 75;
	else if (isNav)	vym = 25;

	this.gWinCal.document.open();

	this.wwrite("<html>");
	this.wwrite("<head><title>Calendar</title>");
	this.wwrite("<style type='text/css'>\n<!--");
	for (i=0; i<12; i++)
	{
		vc = i % 3;
		if (i>=0 && i<= 2)	vr = 0;
		if (i>=3 && i<= 5)	vr = 1;
		if (i>=6 && i<= 8)	vr = 2;
		if (i>=9 && i<= 11)	vr = 3;

		vx = parseInt(vxf * vc) + vxm;
		vy = parseInt(vyf * vr) + vym;

		this.wwrite(".lclass" + i + " {position:absolute;top:" + vy + ";left:" + vx + ";}");
	}
	this.wwrite("-->\n</style>");
	this.wwrite("</head>");

	this.wwrite("<body " +
		"link=\"" + this.gLinkColor + "\" " +
		"vlink=\"" + this.gLinkColor + "\" " +
		"alink=\"" + this.gLinkColor + "\" " +
		"text=\"" + this.gTextColor + "\">");
	this.wwrite("<FONT FACE='" + fontface + "' SIZE=2><B>");
	this.wwrite("Year : " + this.gYear);
	this.wwrite("</B><BR>");

	// Show navigation buttons
	var prevYYYY = parseInt(this.gYear) - 1;
	var nextYYYY = parseInt(this.gYear) + 1;

	this.wwrite("<TABLE WIDTH='100%' BORDER=0 CELLSPACING=0 CELLPADDING=0 BGCOLOR='#e0e0e0'><TR><TD ALIGN=center>");
	this.wwrite("<A HREF=\"" +
		"javascript:window.opener.Build(" +
		"'" + this.gReturnItem + "', null, '" + prevYYYY + "', '" + this.gFormat + "'" +
		");" +
		"\" alt='Prev Year'><<<\/A></TD><TD ALIGN=center>");
//	this.wwrite("<A HREF=\"javascript:window.print();\">Print</A></TD><TD ALIGN=center>");
	this.wwrite("<A HREF=\"" +
		"javascript:window.opener.Build(" +
		"'" + this.gReturnItem + "', null, '" + nextYYYY + "', '" + this.gFormat + "'" +
		");" +
		"\">>><\/A></TD></TR></TABLE><BR>");

	// Get the complete calendar code for each month..
	var j;
	for (i=11; i>=0; i--) {
		if (isIE)
			this.wwrite("<DIV ID=\"layer" + i + "\" CLASS=\"lclass" + i + "\">");
		else if (isNav)
			this.wwrite("<LAYER ID=\"layer" + i + "\" CLASS=\"lclass" + i + "\">");

		this.gMonth = i;
		this.gMonthName = Calendar.get_month(this.gMonth);
		vCode = this.getMonthlyCalendarCode();
		this.wwrite(this.gMonthName + "/" + this.gYear + "<BR>");
		this.wwrite(vCode);

		if (isIE)
			this.wwrite("</DIV>");
		else if (isNav)
			this.wwrite("</LAYER>");
	}

	this.wwrite("</font><BR></body></html>");
	this.gWinCal.document.close();
}

Calendar.prototype.wwrite = function(wtext)
{
	this.gWinCal.document.writeln(wtext);
}

Calendar.prototype.wwriteA = function(wtext)
{
	this.gWinCal.document.write(wtext);
}

Calendar.prototype.cal_header = function()
{
	var vCode = "";

	vCode = vCode + "<TR align='center' BGCOLOR='" + this.gHeaderBkgd + "'>";
	vCode = vCode + "<TD WIDTH='15%'><FONT SIZE='2' FACE='" + fontface + "' COLOR='" + this.gHeaderColor + "'><B>Sun</B></FONT></TD>";
	vCode = vCode + "<TD WIDTH='14%'><FONT SIZE='2' FACE='" + fontface + "' COLOR='" + this.gHeaderColor + "'><B>Mon</B></FONT></TD>";
	vCode = vCode + "<TD WIDTH='14%'><FONT SIZE='2' FACE='" + fontface + "' COLOR='" + this.gHeaderColor + "'><B>Tue</B></FONT></TD>";
	vCode = vCode + "<TD WIDTH='14%'><FONT SIZE='2' FACE='" + fontface + "' COLOR='" + this.gHeaderColor + "'><B>Wed</B></FONT></TD>";
	vCode = vCode + "<TD WIDTH='14%'><FONT SIZE='2' FACE='" + fontface + "' COLOR='" + this.gHeaderColor + "'><B>Thu</B></FONT></TD>";
	vCode = vCode + "<TD WIDTH='14%'><FONT SIZE='2' FACE='" + fontface + "' COLOR='" + this.gHeaderColor + "'><B>Fri</B></FONT></TD>";
	vCode = vCode + "<TD WIDTH='15%'><FONT SIZE='2' FACE='" + fontface + "' COLOR='" + this.gHeaderColor + "'><B>Sat</B></FONT></TD>";
	vCode = vCode + "</TR>";

	return vCode;
}

Calendar.prototype.cal_data = function()
{
	var vDate = new Date();
	vDate.setDate(1);
	vDate.setMonth(this.gMonth);
	vDate.setFullYear(this.gYear);

	var vFirstDay=vDate.getDay();
	var vDay=1;
	var vLastDay=Calendar.get_daysofmonth(this.gMonth, this.gYear);
	var vOnLastDay=0;
	var vCode = "";
	var s = "";

	var even = true;
	var bgcolor = '';
	var cellColor = '#ffffcc';

/*
Get day for the 1st of the requested month/year..
Place as many blank cells before the 1st day of the month as necessary.
*/

	// leading blanks
	vCode = vCode + "<TR>";
	for (i=0; i<vFirstDay; i++)
	{
		if (even) bgcolor = " bgcolor='" + cellColor + "' ";
		else bgcolor = " bgcolor='#ffffff' ";
		even = !even;
		vCode = vCode + "<TD VALIGN='TOP' HEIGHT='" + this.gCellHeight + "'" + bgcolor + "WIDTH='14%'></TD>";
	}

	// Write rest of the 1st week (1, 2, ...)
	for (j=vFirstDay; j<7; j++)
	{
		if (even) bgcolor = " bgcolor='" + cellColor + "' ";
		else bgcolor = " bgcolor='#ffffff' ";
		even = !even;
		s = this.format_day(vDay);
		vCode = vCode + "<TD VALIGN='TOP' HEIGHT='" + this.gCellHeight + "'" + bgcolor + "WIDTH='14%'"
			+ this.write_weekend_string(j) + "><FONT SIZE='1' FACE='" + fontface
			+ "'><A HREF='javascript:menu(\"ID_" + vDay + "\");'>"+ s + "</A></FONT>"
			+ this.menuDiv(vDay);
		if (s != vDay)
			vCode = vCode + "<a name=\"today\"></a>";

		if (gDayArr[vDay] != null)
			vCode += gDayArr[vDay];		// first handle holiday and special day
		if (gMtgArr[vDay] != null)
			vCode += gMtgArr[vDay];		// then meetings and events

		vCode += "</TD>";
		vDay=vDay + 1;
	}
	vCode = vCode + "</TR>";

	// Write the rest of the weeks
	for (k=2; k<7; k++)
	{
		vCode = vCode + "<TR>";

		for (j=0; j<7; j++)
		{
			if (even) bgcolor = " bgcolor='" + cellColor + "' ";
			else bgcolor = " bgcolor='#ffffff' ";
			even = !even;
			s = this.format_day(vDay);
			vCode = vCode + "<TD VALIGN='TOP' HEIGHT='" + this.gCellHeight + "'" + bgcolor + "WIDTH='14%'"
				+ this.write_weekend_string(j) + "><FONT SIZE='1' FACE='" + fontface
				+ "'><A HREF='javascript:menu(\"ID_" + vDay + "\");'>"+ s + "</A></FONT>"
				+ this.menuDiv(vDay);
			if (s != vDay)
				vCode = vCode + "<a name=\"today\"></a>";

			if (gDayArr[vDay] != null)
				vCode += gDayArr[vDay];		// first handle holiday and special day
			if (gMtgArr[vDay] != null)
				vCode += gMtgArr[vDay];		// then meetings and events

			vCode += "</TD>";
			vDay=vDay + 1;

			if (vDay > vLastDay)
			{
				vOnLastDay = 1;
				break;
			}
		}

		if (j == 6)
			vCode = vCode + "</TR>";
		if (vOnLastDay == 1)
			break;
	}

	// Fill up the rest of last week with proper blanks, so that we get proper square blocks
	for (m=1; m<(7-j); m++)
	{
		if (even) bgcolor = " bgcolor='" + cellColor + "' ";
		else bgcolor = " bgcolor='#ffffff' ";
		even = !even;
		//if (this.gYearly)
			vCode = vCode + "<TD VALIGN='TOP' HEIGHT='" + this.gCellHeight + "'" + bgcolor + "WIDTH='14%'"
				+ this.write_weekend_string(j+m) + "</TD>";
/*		else
			vCode = vCode + "<TD VALIGN='TOP' HEIGHT='" + this.gCellHeight + "'" + bgcolor + "WIDTH='14%'"
				+ this.write_weekend_string(j+m)
				+ "><FONT SIZE='1' FACE='" + fontface + "' COLOR='gray'></FONT></TD>";*/
	}

	return vCode;
}

var curShowMenuId = "";
function menu(eId)
{
	// small menu under each day
	popMenu(false);
	selectedYrMoDy = showingYrMo + "/" + eId.substring(3);
	var e = document.getElementById(eId);
	if (e.style.display=="block")
	{
		e.style.display = "none";
		curShowMenuId = "";
	}
	else
	{
		if (curShowMenuId != "")
			document.getElementById(curShowMenuId).style.display = "none";
		e.style.display = "block";
		curShowMenuId = eId;
	}
}

function popMenu(op, type)
{
	// big menu to give details of holiday/special day
	var e = document.getElementById("popMenu");
	if (op==true)
	{
		e.style.display = "block";
		if (type != null)
		{
			var ee = document.getElementById("dayType");
			if (type == 0)
			{
				ee.options[0].selected = true;
				ee.options[1].selected = false;
			}
			else
			{
				ee.options[0].selected = false;
				ee.options[1].selected = true;
			}
			var f = document.dayForm;
			f.dayTitle.value = '';
			f.dayDesc.value = '';
			f.scope.options[1].selected = true;
			f.notify[0].checked = true;
			f.dayTitle.focus();
		}
	}
	else
		e.style.display = "none";
}

Calendar.prototype.menuDiv = function(vday)
{
	var s = "<BR><DIV id='ID_" + vday + "' class='menu'>"
		+ "<div class='trans'></div>"
		+ "<div class='tx'>"
		+ "&nbsp;&nbsp;. <a href='javascript:popMenu(true, 0);'>Holiday</a><br>"
		+ "&nbsp;&nbsp;. <a href='javascript:popMenu(true, 1);'>Special Day</a><br>"
		+ "&nbsp;&nbsp;. <a href='../question/q_new1.jsp?Qtype=event&D="
			+ showingYrMo + "/" + vday + "'>New Event</a><br>"
		+ "&nbsp;&nbsp;. <a href='../meeting/mtg_new1.jsp?D="
			+ showingYrMo + "/" + vday + "'>New Meeting</a>"
		+ "</div></DIV>";
	return (s);
}

Calendar.prototype.format_day = function(vday)
{
	var vNowDay = gNow.getDate();
	var vNowMonth = gNow.getMonth();
	var vNowYear = gNow.getFullYear();

	if (vday == gNow.getDate() && this.gSameMoYr)
		return ("<FONT COLOR=\"#ff6666\"><B>" + vday + "</B></FONT>");
	else
		return (vday);
}

Calendar.prototype.write_weekend_string = function(vday)
{
	var i;
	return "";

	// Return special formatting for the weekend day.
	for (i=0; i<weekend.length; i++)
	{
		if (vday == weekend[i])
			return (" BGCOLOR=\"" + weekendColor + "\"");
	}

	return "";
}

Calendar.prototype.format_data = function(p_day)
{
	var vData;
	var vMonth = 1 + this.gMonth;
	vMonth = (vMonth.toString().length < 2) ? "0" + vMonth : vMonth;
	var vMon = Calendar.get_month(this.gMonth).substr(0,3).toUpperCase();
	var vFMon = Calendar.get_month(this.gMonth).toUpperCase();
	var vY4 = new String(this.gYear);
	var vY2 = new String(this.gYear.substr(2,2));
	var vDD = (p_day.toString().length < 2) ? "0" + p_day : p_day;

	switch (this.gFormat)
	{
		case "MM\/DD\/YYYY" :
			vData = vMonth + "\/" + vDD + "\/" + vY4;
			break;
		case "MM\/DD\/YY" :
			vData = vMonth + "\/" + vDD + "\/" + vY2;
			break;
		case "MM-DD-YYYY" :
			vData = vMonth + "-" + vDD + "-" + vY4;
			break;
		case "MM-DD-YY" :
			vData = vMonth + "-" + vDD + "-" + vY2;
			break;

		case "DD\/MON\/YYYY" :
			vData = vDD + "\/" + vMon + "\/" + vY4;
			break;
		case "DD\/MON\/YY" :
			vData = vDD + "\/" + vMon + "\/" + vY2;
			break;
		case "DD-MON-YYYY" :
			vData = vDD + "-" + vMon + "-" + vY4;
			break;
		case "DD-MON-YY" :
			vData = vDD + "-" + vMon + "-" + vY2;
			break;

		case "DD\/MONTH\/YYYY" :
			vData = vDD + "\/" + vFMon + "\/" + vY4;
			break;
		case "DD\/MONTH\/YY" :
			vData = vDD + "\/" + vFMon + "\/" + vY2;
			break;
		case "DD-MONTH-YYYY" :
			vData = vDD + "-" + vFMon + "-" + vY4;
			break;
		case "DD-MONTH-YY" :
			vData = vDD + "-" + vFMon + "-" + vY2;
			break;

		case "DD\/MM\/YYYY" :
			vData = vDD + "\/" + vMonth + "\/" + vY4;
			break;
		case "DD\/MM\/YY" :
			vData = vDD + "\/" + vMonth + "\/" + vY2;
			break;
		case "DD-MM-YYYY" :
			vData = vDD + "-" + vMonth + "-" + vY4;
			break;
		case "DD-MM-YY" :
			vData = vDD + "-" + vMonth + "-" + vY2;
			break;

		default :
			vData = vMonth + "\/" + vDD + "\/" + vY4;
	}

	return vData;
}

function Build(p_item, p_month, p_year, p_format)
{
	var p_WinCal = ggWinCal;
	gCal = new Calendar(p_item, p_WinCal, p_month, p_year, p_format);

	// Customize your Calendar here..
	gCal.gBGColor="white";
	gCal.gLinkColor="black";
	gCal.gTextColor="black";
	gCal.gHeaderColor="darkgreen";

	// Choose appropriate show function
	if (gCal.gYearly)	gCal.showY();
	else	gCal.show();
}

function show_calendar()
{
/*
	p_month : 0-11 for Jan-Dec; 12 for All Months.
	p_year	: 4-digit year
	p_format: Date format (mm/dd/yyyy, dd/mm/yy, ...)
	p_item	: Return Item.
*/
	p_item = arguments[0];

	if (arguments[1] == null)
		p_month = new String(gNow.getMonth());
	else
		p_month = arguments[1];
	if (arguments[2] == "" || arguments[2] == null)
		p_year = new String(gNow.getFullYear().toString());
	else
		p_year = arguments[2];

	if (arguments[3] == null)
		p_format = "MM/DD/YYYY";
	else
		p_format = arguments[3];

	vWinCal = window.open("", "Calendar",
		"width=250,height=250,status=no,resizable=no,top=200,left=200");
	vWinCal.opener = self;
	ggWinCal = vWinCal;

	Build(p_item, p_month, p_year, p_format);
}
/*
Yearly Calendar Code Starts here
*/
function show_yearly_calendar(p_item, p_year, p_format)
{
	// Load the defaults..
	if (p_year == null || p_year == "")
		p_year = new String(gNow.getFullYear().toString());
	if (p_format == null || p_format == "")
		p_format = "MM/DD/YYYY";

	var vWinCal = window.open("", "Calendar", "scrollbars=yes");
	vWinCal.opener = self;
	ggWinCal = vWinCal;

	Build(p_item, null, p_year, p_format);
}

