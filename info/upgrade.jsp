<%@ page contentType="text/html; charset=utf-8"%>

<%
////////////////////////////////////////////////////
//	Copyright (c) 2008, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	upgrade.jsp
//	Author:	ECC
//	Date:	09/07/06
//	Description:
//		Upgrade page with pricing info, connects to payment page. Default is CPM.
//		For CR, redirect to upgrade_cr.jsp
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.io.BufferedReader" %>
<%@ page import = "java.io.IOException" %>
<%@ page import = "java.text.DecimalFormat" %>
<%@ page import = "java.util.ArrayList" %>
<%@ page import = "java.util.HashMap" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>

<%!
	String PRICE_1		= "Price_1",
		   PRICE_2		= "Price_2",
		   PRICE_3		= "Price_3",
		   PRICE_4		= "Price_4";

	//////////////////////////////
	// the following constants define our pricing and limit for each category
	final int SIZE_1		= Util2.DEFAULT_TOTAL_SPACE;
	final int SIZE_2		= 5000;		// 5 GB
	final int SIZE_3		= 20000;	// 20 GB
	final int SIZE_4		= 200000;	// 200 GB
	
	final int PROJ_1		= 5;
	final int PROJ_2		= 15;
	final int PROJ_3		= 50;
	final int PROJ_4		= -1;		// unlimited
	
	final int USER_1		= 10;
	final int USER_2		= 20;
	final int USER_3		= 50;		// 50+
	final int USER_4		= 100;		// 100+
	
	///////////////////////////////

	String PRICE_10G			= "Price_10G",
		   PRICE_1_USER			= "Price_1_User";
	
	static final String regex = "(?:^|,)(\\\"(?:[^\\\"]+|\\\"\\\")*\\\"|[^,]*)";	// regex for CSV

	HashMap<String,Double> priceHash;
	ArrayList<String> headerList;
	ArrayList<String> headerDescList;
	ArrayList<String> categoryNameList;
	ArrayList<ArrayList<ArrayList<String>>> catRowList;

	void uploadPricing(String fName)
		throws IOException
	{
		// scan the file line by line and process the pricing info
		// put the price in a HashMap which uses name as key
		BufferedReader din = UtilIO.getFileReader(fName);
		
		// init
		priceHash = new HashMap<String,Double>();
		headerList = new ArrayList<String>();
		headerDescList = new ArrayList<String>();
		categoryNameList = new ArrayList<String>();
		catRowList = new ArrayList<ArrayList<ArrayList<String>>>();
		
		String line, lowercaseKey;
		String s;
		String [] sa;
		int categoryIdx = -1;
		boolean isCategory = false;
		
		while ((line = din.readLine()) != null) {
			line = line.trim();
			if (line.length() <= 0 ||		// blank line
				line.charAt(0) == '#')		// comment line
				continue;
			
			sa = line.split(",");
			if (sa.length < 2) continue;	// there should at least be 2 tokens
			
			// trim and strip the beginning and ending double-quote (")
			sa[0] = stripDoubleQuote(sa[0]);
			
			lowercaseKey = sa[0].toLowerCase();

			if (lowercaseKey.startsWith("price_")) {
				// save price to hash: expect two token
				priceHash.put(lowercaseKey, Double.parseDouble(sa[1]));
			}
			else if (lowercaseKey.equals("header")) {
				// header line: just 1 line
				for (int i=1; i<sa.length; i++) {
					headerList.add(sa[i].trim());
				}
			}
			else if (lowercaseKey.equals("headerdesc")) {
				// header description line: just 1 line
				for (int i=1; i<sa.length; i++) {
					s = strip(sa[i]);
					headerDescList.add(s);
				}
			}
			
			// process category each has a number of rows
			else if (lowercaseKey.equals("category")) {
				// category name followed by a number of rows
				isCategory = true;
				categoryIdx++;
				categoryNameList.add(stripDoubleQuote(sa[1]));
				ArrayList<ArrayList<String>> thisCategoryList = new ArrayList<ArrayList<String>>();
				catRowList.add(thisCategoryList);
			}
			
			// processing a row for category
			else if (isCategory) {
				ArrayList<String> rowList = new ArrayList<String>();
				ArrayList<ArrayList<String>> thisCategoryList = catRowList.get(categoryIdx);
				thisCategoryList.add(rowList);
				for (String val : sa) {
					val = stripDoubleQuote(val);
					rowList.add(val);				// can be empty string ""
				}
			}
		}
		din.close();
	}
	
	String strip(String s)
	{
		s = s.trim();
		if (s.charAt(0) == '"')
			s = s.substring(1, s.length()-1);
		return s;
	}
	
	double getPrice(String key)
	{
		return priceHash.get(key.toLowerCase());
	}
	
	String stripDoubleQuote(String s)
	{
		s = s.trim();
		int len = s.length();
		if (len>0 && s.charAt(0)=='"' && s.charAt(len-1)=='"') {
			s = s.substring(1, len-1);
		}
		return s;
	}
	
	String getNicePriceString(String p)
	{
		// strip the ".00" at the end
		if (p.endsWith(".00")) {
			p = p.substring(0, p.length()-3);
		}
		return p;
	}
%>

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");
	
	//////////////////////////////////////////

	String HOST			= Prm.getPrmHost();

	if (!Prm.isMultiCorp() || Prm.isMeetWE()) {
		// single company site, no upgrade page
		response.sendRedirect(HOST + "/admin/adduser.jsp");
		return;
	}
	//////////////////////////////////////////


	// we should put the filename in the properties file
	String pricingFileName = Prm.getResourcePath() + "/../info/";	// "C:/Tomcat/webapps/PRM/info/";
	
	if (Prm.isCR()) {
		pricingFileName += "price_cr.csv";
	}
	else {
		pricingFileName += "price_cpm.csv";
	}
	
	String s;
	String secureHost;
	if (Prm.isSecureHost())
		secureHost = HOST.replace("http", "https");
	else
		secureHost = HOST;
	
	uploadPricing(pricingFileName);
	
	// primary pricing, monthly
	
	
	String home;
	String levelS, paymentS, currentSizeS, currentStatus="";
	int currentSize = 0;					// the current total space of the user
	int baseSize = SIZE_2;
	int excess = 0;							// if user purchase over baseSize
	double priceMo=0, priceYr;
	String currentStmt = "";				// current service level and extra space purchase

	boolean isLogin = false;

	// create a user object as guest if I am not login yet
	PstUserAbstractObject pstuser = null;
	HttpSession sess = request.getSession(false);
	if (sess != null)
		pstuser = (PstUserAbstractObject)sess.getAttribute("pstuser");
	else
		sess = request.getSession(true);
	if (pstuser == null) {
		try {
			sess = request.getSession(true);
			pstuser = (PstUserAbstractObject) PstGuest.getInstance();
		} catch (PmpException e) {
			response.sendRedirect(HOST + "/out.jsp?e=The requested page is temporarily unavailable, please try again later.");
			return;
		}
	}
	
	if (!(pstuser instanceof PstGuest))
	{
		isLogin = true;
		home = HOST + "/ep/ep_home.jsp";
		currentStmt = " * Your current subscription is on the ";
		
		// get current level
		userinfoManager uiMgr = userinfoManager.getInstance();
		PstAbstractObject ui = uiMgr.get(pstuser, String.valueOf(pstuser.getObjectId()));
		s = (String)ui.getAttribute("Status")[0];	// service status
		if (s == null)
			s = userinfo.LEVEL_1 + userinfo.PAYMT_MONTHLY;	// default
		currentStatus = s;
		//s = "ProfessionalYearly";		// testing
		
		if (s.indexOf(userinfo.LEVEL_1)!=-1)
		{
			levelS = userinfo.LEVEL_1;
			priceMo = getPrice(PRICE_1);
			baseSize = SIZE_1;
			currentStmt += userinfo.LEVEL_1.toUpperCase() + " level";
		}
		else if (s.indexOf(userinfo.LEVEL_2)!=-1)
		{
			levelS = userinfo.LEVEL_2;
			priceMo = getPrice(PRICE_2);
			baseSize = SIZE_2;
			currentStmt += userinfo.LEVEL_2.toUpperCase() + " level";
		}
		else if (s.indexOf(userinfo.LEVEL_3)!=-1)
		{
			levelS = userinfo.LEVEL_3;
			priceMo = getPrice(PRICE_3);
			baseSize = SIZE_3;
			currentStmt += userinfo.LEVEL_3.toUpperCase() + " level";
		}
		else
		{
			levelS = userinfo.LEVEL_4;
			priceMo = getPrice(PRICE_4);
			baseSize = SIZE_4;
			currentStmt += userinfo.LEVEL_4.toUpperCase() + " level";
		}
		
		// current payment type (monthly or yearly)
		if (s.indexOf(userinfo.PAYMT_YEARLY) != -1)
			paymentS = userinfo.PAYMT_YEARLY;
		else
			paymentS = userinfo.PAYMT_MONTHLY;
		
		// current space purchased
		currentSize = ((Integer)pstuser.getAttribute("SpaceTotal")[0]).intValue();
	}
	else
	{	// !isLogin
		// default
		home = HOST + "/index.jsp";
		levelS = userinfo.LEVEL_1;
		priceMo = getPrice(PRICE_1);
		paymentS = userinfo.PAYMT_MONTHLY;
		currentStmt = "FREE TRIAL for 10 SHARED SPACES!";
	}
	//currentSize = 300000;		// testing
	
	if (currentSize == 0)
		currentSize = Util2.DEFAULT_TOTAL_SPACE;		// 200 MB
	else
	{
		// the user might have purchased additional space
		if ((excess = currentSize - baseSize) > 0)
		{
			priceMo += excess/1000;
		
			currentStmt += " with additional " + excess/1000 + " GB space (over base of ";
		}
		else
			currentStmt += " (base storage is ";
			
		if (baseSize > 1000)
			currentStmt += baseSize/1000 + " GB)";
		else
			currentStmt += baseSize + " MB)";
	}
	
	if (currentSize >= 1000)
		currentSizeS = currentSize/1000 + " GB";
	else
		currentSizeS = currentSize + " MB";
	
	// after currentStmt is constructed, we want to make a recommendation to the login user
	if (isLogin && currentStatus.indexOf(userinfo.LEVEL_1)!=-1)
	{
		// recommend Standard user to Elite
		levelS = userinfo.LEVEL_2;
		priceMo = getPrice(PRICE_2);
		baseSize = SIZE_2;
	}
	
	priceYr = priceMo * 10;
	
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">

<title>
	<%=Prm.getAppTitle()%> Upgrade
</title>

<script type="text/javascript">
<!--

var curLevel = 0;
var basePrice = 0.00;
var baseSize = 200;
var excess = <%=excess%>;

window.onload = function()
{
	checkService();
	updateSize();
	updateSizeStmt(baseSize+excess);
}

function validate()
{
	var f = document.upgrade;
	checkService();

	if (curLevel==0 && '<%=currentStatus%>'.indexOf('<%=userinfo.LEVEL_1%>')!=-1)
	{
		alert("You are already subsrcibed to the <%=userinfo.LEVEL_1.toUpperCase()%> level.  Please pick a higher level to upgrade.");
		return false;
	}
	if (curLevel==1 && '<%=currentStatus%>'.indexOf('<%=userinfo.LEVEL_2%>')!=-1)
	{
		alert("You are already subscribed to the <%=userinfo.LEVEL_2.toUpperCase()%> level.  Please pick a higher level to upgrade.");
		return false;
	}
	
	f.spaceStmt.value = document.getElementById('sizeStmt').innerHTML;
	
	// # of user
	if (curLevel == 0) f.userLimit.value = "<%=USER_1%>";
	else if (curLevel == 1) f.userLimit.value = "<%=USER_2%>";
	else if (curLevel == 2) f.userLimit.value = "<%=USER_3%>";
	else if (curLevel == 3) f.userLimit.value = "<%=USER_4%>";

	// # of project
	if (curLevel == 0) f.projLimit.value = "<%=PROJ_1%>";
	else if (curLevel == 1) f.projLimit.value = "<%=PROJ_2%>";
	else if (curLevel == 2) f.projLimit.value = "<%=PROJ_3%>";
	else if (curLevel == 3) f.projLimit.value = "<%=PROJ_4%>";

	f.submit();
}

function checkService()
{
	var e0 = document.getElementById('level0');
	var e1 = document.getElementById('level1');
	var e2 = document.getElementById('level2');
	var e3 = document.getElementById('level3');
	if (e0.checked)
	{
		curLevel = 0;
		basePrice = <%=getPrice(PRICE_1)%>;
		baseSize = <%=SIZE_1%>;
	}
	else if (e1.checked)
	{
		curLevel = 1; 
		basePrice = <%=getPrice(PRICE_2)%>;
		baseSize = <%=SIZE_2%>;		
	}
	else if (e2.checked) 
	{
		curLevel = 2; 
		basePrice = <%=getPrice(PRICE_3)%>;
		baseSize = <%=SIZE_3%>;
	}
	else if (e3.checked)
	{
		curLevel = 3;
		basePrice = <%=getPrice(PRICE_4)%>;
		baseSize = <%=SIZE_4%>;
	}
	
	if (curLevel <= 1)
	{
		return false;
	}
	return true;
}

function add()
{
	if (!checkService())
	{
		alert("Choose <%=userinfo.LEVEL_3.toUpperCase()%> or <%=userinfo.LEVEL_4.toUpperCase()%> level service to change storage space.");
		return false;
	}

	var e = document.upgrade.space;
	var size = e.value;
	var iSize = getSize(size);
	if (iSize > 10000000)
		return false;
	iSize += 10000;
	e.value = iSize/1000 + " GB";
	updateSizeStmt(iSize);
	updatePrice();
}

function del()
{
	if (!checkService())
	{
		alert("Choose <%=userinfo.LEVEL_3.toUpperCase()%> or <%=userinfo.LEVEL_4.toUpperCase()%> level service to change storage space.");
		return false;
	}
	
	var e = document.upgrade.space;
	var size = e.value;
	var iSize = getSize(size);
	if (curLevel==2 && iSize<=<%=SIZE_3%>)
		return false;
	else if (curLevel == 3 && iSize<=<%=SIZE_4%>)
		return false;
	iSize -= 10000;
	e.value = iSize/1000 + " GB";
	updateSizeStmt(iSize);
	updatePrice();
}

function getSize(sizeStr)
{
	var iSize = 0;
	var idx = sizeStr.indexOf(" MB");
	if (idx != -1)
		iSize = parseInt(sizeStr.substring(0, idx));
	else
	{
		// in GB range
		idx = sizeStr.indexOf(" GB");
		iSize = parseInt(sizeStr.substring(0, idx)) * 1000;
	}
	return iSize;
}

function checkSpace(level)
{
	checkService();
	
	var e = document.upgrade.space;
	var size = "<%=currentSize%>" + " MB";		// current size is in MB
	e.value = size;								// reset it to current subscribed size
	
	if (level == 0)
		e.value = "1 GB";
	else if (level == 1)
		e.value = "5 GB";
	else
	{
		var iSize = getSize(size);
		if (level == 2)
		{
			if (iSize < <%=SIZE_3%>)
			{
				iSize = <%=SIZE_3%>;
				e.value = "20 GB";
			}
		}
		else
		{
			// level 3
			if (iSize < <%=SIZE_4%>)
			{
				iSize = <%=SIZE_4%>;
				e.value = "200 GB";
			}
		}
		if (iSize > 1000)
			e.value = iSize/1000 + " GB";
	}
	updateSizeStmt(iSize);
	updatePrice();
}

function updatePrice()
{
	var chooseSize = document.upgrade.space.value;
	var iSize = getSize(chooseSize);
	excess = iSize - baseSize;
	if (excess > 0)
		basePrice += excess/1000;

	document.upgrade.month.value = basePrice;
	document.upgrade.year.value = basePrice * 10;
}

function updateSize()
{
	var e = document.upgrade.space;
	var sizeStr = "";
	var size = baseSize + excess;
	if (size < 1000)
		sizeStr = size + " MB";
	else
		sizeStr = size/1000 + " GB";
	e.value = sizeStr;
}

function updateSizeStmt(iSize)
{
	var e = document.getElementById('sizeStmt');
	var excess = iSize - baseSize;
	var str = "(";
	if (excess > 0)
	{
		str += "additional ";
		if (excess > 1000)
			str += excess/1000 + " GB space over ";
		else
			str += excess + " MB space over ";
			
		if (baseSize > 1000)
			str += "base storage of " + baseSize/1000 + " GB)";
		else
			str += "base storage of " + baseSize + " MB)";
	}
	else
		str += "base storage)";
		
	e.innerHTML = str;
}

//-->
</script>

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

	&nbsp;&nbsp;Upgrade <%=Prm.getAppTitle()%>

	</b><br><br>
	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- Navigation SUB-Menu -->
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
<td width="100%" valign="top">

	<table border="0" width="100%" height="14" cellspacing="0" cellpadding="0">
		<tr>
			<td valign="top" class="bgsubnav">
				<table border="0" cellspacing="0" cellpadding="0">
				<tr class="bgsubnav">
	<!-- Home -->
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="<%=home%>" class="subnav">Home</a></td>
					<td colspan="3" width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- FAQ -->
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="<%=HOST%>/info/faq.jsp" class="subnav">FAQ</a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- Download -->
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="<%=HOST%>/info/download.jsp" class="subnav">Download</a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- Upgrade -->
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="20" height="14"><img src="../i/nav_arrow.gif" width="20" height="14" border="0"></td>
					<td><a href="#" onClick="return false;" class="subnav"><u>Upgrade</u></a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

				</tr>
				</table>
			</td>
		</tr>
	</table>
	<table border="0" width="100%" height="1" cellspacing="0" cellpadding="0">
		<tr>
			<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
		</tr>
	</table>

</td>
</tr>
</table>
<!-- End of Navigation SUB-Menu -->

<style type="text/css">
.headlnk_blue_13 {  font-family: Verdana, Arial, Helvetica, sans-serif; color: #202099; font-size: 13px; font-weight: bold}
a.headlnk_blue:link, a.headlnk_blue:active, a.headlnk_blue:visited {  font-family: Verdana, Arial, Helvetica, sans-serif; color: #3030cc; font-size: 14px; font-weight: bold}
.headlnk_pink {  font-family: Verdana, Arial, Helvetica, sans-serif; color: ee2288; font-size: 16px; font-weight: bold; text-decoration: none}
.headlnk_green {  font-family: Verdana, Arial, Helvetica, sans-serif; color: #40a040; font-size: 16px; font-weight: bold}

body,td,th,p,a{font-family:arial,verdana,sans-serif;font-size:12px;}
table {border-collapse:collapse;}
.table td{padding:5px;border:solid 1px #c1c1c1; word-break:normal;}
.table td.cell{padding:5px;border:solid 1px #c1c1c1;text-align:center;}
.table td.cellB{padding:5px;border:solid 1px #c1c1c1;text-align:center;}
.table td.vertical{background:#390;color:#fff;writing-mode:tb-rl;width=10px;padding:5px;border:solid 1px #c1c1c1;text-align:center;}
.table th{padding:5px;border:solid 1px #c1c1c1;}
.table td.gray{background:#efefef;font-weight:bold;}
.table th.top{background:#390;color:#fff;text-align:center;font-size:18px}
.table th.empty{border:none;}
.table td.x{font-weight:bold;text-align:center}
.table th.top_desc{background:#efefef;text-align:left;vertical-align:top;font-size:10px;font-weight:normal;padding:10;line-height:20px;}
.top0 {font-size:20px;color:#777777;padding:10;}
.top1 {font-size:30px;color:#333333;}
.top2 {font-size:11px;color:#777777;}
</style>

<!-- CONTENT -->
<table width='90%'>
	<tr><td><img src='../i/spacer.gif' height='20' /></td></tr>

<%	if (currentStmt.length() > 0) {
	out.println("<tr><td></td><td class='headlnk_green'>" + currentStmt + "</td></tr>");
	out.print("<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>");
	}
%>
	
	<tr>
		<td><img src='../i/spacer.gif' width='30' height='1' /></td>
		<td>
<form name='upgrade' method='post' action='<%=secureHost%>/info/account.jsp'>
<input type='hidden' name='spaceStmt' value=''>
<input type='hidden' name='userLimit' value=''>
<input type='hidden' name='projLimit' value=''>

		<table width='100%' cellpadding='3' border='1' bgcolor='#efefef'>
			<tr>
				<td class='headlnk_blue_13'>Select your level of service:</td>
<%
				out.print("<td width='18%'><input type='radio' name='level' id='level3' value='" + userinfo.LEVEL_4 + "'");
				if (levelS.equals(userinfo.LEVEL_4)) out.print(" checked");
				out.print(" onclick='checkSpace(3)'><b>" + userinfo.LEVEL_4 + "</b></td>");

				out.print("<td width='18%'><input type='radio' name='level' id='level2' value='" + userinfo.LEVEL_3 + "'");
				if (levelS.equals(userinfo.LEVEL_3)) out.print(" checked");
				out.print(" onclick='checkSpace(2)'><b>" + userinfo.LEVEL_3 + "</b></td>");

				out.print("<td width='18%'><input type='radio' name='level' id='level1' value='" + userinfo.LEVEL_2 + "'");
				if (levelS.equals(userinfo.LEVEL_2)) out.print(" checked");
				out.print(" onclick='checkSpace(1)'><b>" + userinfo.LEVEL_2 + "</b></td>");
				
				out.print("<td width='18%'><input type='radio' name='level' id='level0' value='" + userinfo.LEVEL_1 + "'");
				if (levelS.equals(userinfo.LEVEL_1)) out.print(" checked");
				out.print(" onclick='checkSpace(0)'><b>" + userinfo.LEVEL_1 + "</b></td>");		
%>
			</tr>

			<tr>
				<td class='headlnk_blue_13'>Total storage space:</td>
				<td colspan='4'>
					<table border='0' cellspacing='0' cellpadding='0'>
						<tr>
						<td>&nbsp;<input name='space' id='space' type='text' size='10' value='<%=currentSizeS%>' onkeydown='return false' class='formtext'></td>
						<td><table border='0' cellspacing='0' cellpadding='2'>
							<tr><td><img src='../i/plus.gif' onclick='add()' border='0' title='Add space' /></td></tr>
							<tr><td><img src='../i/minus.gif' onclick='del()' border='0' title='Reduce space'/></td></tr>
							</table>
						</td>
						<td><img src='../i/spacer.gif' width='30' height='1' /></td>
						<td class='plaintext' id='sizeStmt'></td>
						</tr>
					</table>
				</td>
			</tr>
			
			<tr>
				<td class='headlnk_blue_13'>Payment plan:</td>
				<td colspan='4'>
					<table border='0' cellspacing='0' cellpadding='0'>
						<tr>
<%						
						out.print("<td><input type='radio' name='paymentType' value='" + userinfo.PAYMT_MONTHLY + "'");
						if (paymentS.equals(userinfo.PAYMT_MONTHLY)) out.print(" checked");
						out.print(">&nbsp;$ <input name='monthCost' id='month' type='text' size='6' value='" + priceMo + "' class='formtext' onkeydown='return false'>&nbsp;&nbsp;per month</td>");
						out.print("<td><img src='../i/spacer.gif' width='110' height='1' /></td>");
						
						out.print("<td><input type='radio' name='paymentType' value='" + userinfo.PAYMT_YEARLY + "'");
						if (paymentS.equals(userinfo.PAYMT_YEARLY)) out.print(" checked");
						out.print(">&nbsp;$ <input name='yearCost' id='year' type='text' size='6' value='" + priceYr + "' class='formtext' onkeydown='return false'>&nbsp;&nbsp;per year</td>");
%>						
							</tr>
					</table>
				</td>
			</tr>
			
		</table>
</form>

		</td>
	</tr>
			
	<tr>
		<td></td>
		<td align='center'>
			<table width='100%'><tr>
<%
	if (!isLogin) {
		out.println("<td class='headlnk_green'>" + currentStmt + "</td>");
	}
%>		

			<td><img src='../i/spacer.gif' height='1' /></td>
			<td width='300'><input type='submit' class='button_orange' value='CONTINUE' onclick='validate();'></td>
			</tr></table>
		</td>
	</tr>
		
	<tr><td><img src='../i/spacer.gif' height='30' /></td></tr>
	
	<tr>
		<td width="15">&nbsp;</td>
		
		<td>
		<table class='table' width='100%'>
			<tr>
			<th class='empty' width='10'></th>
			<th class='empty' width='215'></th>
<%			
			int idx1, idx2;
			int totalColumns = headerList.size();
			DecimalFormat formatter = new DecimalFormat("#0.00");

			// Headers
			for (int i=0; i<headerList.size(); i++) {
				out.print("<th class='top' width='18%'>" + headerList.get(i) + "</th>");
			}
			out.print("</tr>");
			
			// description of each service class
			out.print("<tr><th class='empty'></th><th class='empty'></th>");
			for (int i=0; i<headerList.size(); i++) {
				out.print("<th class='top_desc'>" + headerDescList.get(i) + "</th>");
			}
			out.print("</tr>");
			
			// categories and details within each category
			for (int i=0; i<categoryNameList.size(); i++) {
				ArrayList<ArrayList<String>> thisCategoryList = catRowList.get(i);
				out.print("<tr>");
				out.print("<td rowspan='" + thisCategoryList.size() + "' class='vertical'>"
						+ categoryNameList.get(i) + "</td>");
				
				// process one row at a time for this category
				for (int j=0; j<thisCategoryList.size(); j++) {
					ArrayList<String> rowList = thisCategoryList.get(j);
					
					if (j > 0) {
						out.print("</tr><tr>");		// close for last row
					}
					
					// error checking
					if (rowList.size() > totalColumns+1) {
						System.out.println("!!!!!!!!!!!!! Error: not matching column");
						System.out.println("Category: " + categoryNameList.get(i));
						System.out.println("row: " + rowList.toString());
						return;
					}
					
					// each row starts with a label followed by a number of values (column)
					for (int k=0; k<totalColumns+1; k++) {
						String val;
						if (k > rowList.size()-1) {
							val = "";
						}
						else {
							val = rowList.get(k);
						}
						
						String lowercaseVal = val.toLowerCase();
						if (k == 0) {
							// print the label of this row
							out.print("<td class='gray'>" + val + "</td>");
						}
						else if (val.equalsIgnoreCase("yes")) {
							out.print("<td class='cellB'><img src='../i/check.jpg' /></td>");
						}
						else if (Util.isNullOrEmptyString(val)) {
							// no value for this cell
							out.print("<td class='cellB' bgcolor='#efefef'></td>");
						}
						else if ((idx1=lowercaseVal.indexOf("price_")) != -1) {
							String val1 = val.substring(0,idx1);		// prefix
							idx2 = val.indexOf('/');					// per month, etc.
							String val2, val3;
							if ((idx2=lowercaseVal.indexOf('/')) != -1) {
								val2 = val.substring(idx1, idx2);
								val3 = val.substring(idx2);				// suffix
							}
							else {
								val2 = val.substring(idx1);
								val3 = "";
							}
							out.print("<td class='cellB'>" + val1
									+ getNicePriceString(formatter.format(getPrice(val2))) + val3 + "</td>");
						}
						else {
							out.print("<td class='cellB'>" + val + "</td>");
						}
					}	// END k: for one row
				}	// END j: for one category
				out.println("</tr>");		// close last row of this category
			}	// END i: for each category
			
%>

		</table>
		</td>
	</tr>
		
	<tr><td><img src='../i/spacer.gif' height='20' /></td><tr>
			
	<tr>
		<td></td>
		<td align='center'>
			<table width='100%'><tr>
			<td><img src='../i/spacer.gif' height='1' /></td>
			<td width='300'><input type='submit' class='button_orange' value='CONTINUE' onclick='document.upgrade.submit();'></td>
			</tr></table>
		</td>
	</tr>
		
	<tr><td><img src='../i/spacer.gif' height='20' /></td><tr>

</table>



<!-- BEGIN FOOTER TABLE -->
<table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td width="780" height="2" bgcolor="336699"><img src="../i/mid/u2x2.gif" width="2" height="2"></td>
    <td height="2" bgcolor="336699"><img src="../i/mid/u2x2.gif" width="2" height="2"></td>
  </tr>
  <tr>
    <td width="100%" valign="middle" align="center">
		<a href="<%=home%>" class="listlink">Home</a>
		&nbsp;|&nbsp;
		<a href="<%=HOST%>/info/help.jsp" class="listlink">Help</a>
<%if (isLogin){%>
		&nbsp;|&nbsp;
		<a href="<%=HOST%>/logout.jsp" class="listlink">Logout</a>
<%}%>
		&nbsp;|&nbsp;
		<a href="#top" class="listlink">Back to top</a></td>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td width="100%" height="32" align="center" valign="middle"><font size="1" face="Arial, Helvetica, sans-serif" color="#999999" class="8ptype">Copyright
      &copy; 2008-2010, EGI Technologies, Inc.</font></td>
    <td height="32">&nbsp;</td>
  </tr>
</table>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

