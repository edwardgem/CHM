<%
////////////////////////////////////////////////////
//	Copyright (c) 2009, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	order.jsp
//	Author:	ECC
//	Date:	3/09/09
//	Description:
//		An order form for leadership foundation.
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


<%
	String email = "";
	String [] bookArr = {
		"Thoughts From the Diary of a Desperate Man",
		"Thoughts From the Diary of a Desperate Man - Leather Bound",
		"Seeking to Understand the Christian Life",
		"Seeking to Understand the Christian Life - Leather Bound",
		"Disciples Are Made, Not Born",
		"Laymen, Look Up",
		"How to Disciple Your Children",
		"A Laymen's Guide to Studying the Bible",
		"After the Sacrifice",
		"Time for Prayer",
		"Riches - A Biblical Perspective",
		"Whose Job is the Ministry?",
		"Success - A Biblical Perspective",
		"Establishing Your Purpose",
		"Profit Motive",
		"Why Go to Work?",
		"Reward God's Criteria",
		"Who Defines the Ministry?"
	};
	
	double [] bookPrice = {
		10.50,
		23.00,
		10.50,
		23.00,
		13.50,
		8.50,
		8.50,
		16.00,
		10.50,
		5.00,
		5.00,
		5.00,
		5.00,
		5.00,
		5.00,
		5.00,
		5.00,
		5.00
	};
	
	double [] bookWeight = {
		5.1,
		6.6,
		4.0,
		5.3,
		7.3,
		6.8,
		5.0,
		9.9,
		7.5,
		2.4,
		2.1,
		2.1,
		2.3,
		2.5,
		2.1,
		2.6,
		2.1,
		2.9
	};
	
	if (bookArr.length != bookPrice.length)
		System.out.println("*** Error: the book number doesn't match the price list.");
	else if (bookArr.length != bookWeight.length)
		System.out.println("*** Error: the book number doesn't match the weight list.");
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">


<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="../init.jsp" flush="true"/>

<script language="JavaScript">
<!--
function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

function validation()
{
	if (OrderForm.XXX.value =='')
	{
		fixElement(document.OrderForm.ProjName,
			"Please make sure that the XXX field is properly completed.");
		return false;
	}
	return;
}

function update()
{
	var f = document.OrderForm;
	var subTotal = 0;
	var total = 0;
	var tax = 0;
	var shipping = 0;
	var weight = 0;
	
	var len = <%=bookArr.length%>;
	for (i=0; i<len; i++)
	{
		quanField = document.getElementById("Quantity_" + i);
		quantity = quanField.value;
		if (quantity == "")
		{
			quantity = "0";
			quanField.value = quantity;
		}
		priceField = document.getElementById("Price_" + i).innerHTML;
		subTo = quantity * priceField;
		subToField = document.getElementById("SubTotal_" + i);
		subToField.innerHTML = showDeci(subTo);
		subTotal += subTo;

		weightField = document.getElementById("Weight_" + i);
		weight += weightField.value * 1;
	}

	// calculate sub-total
	total += subTotal;
	subToField = document.getElementById("SubTotal");
	subToField.innerHTML = "$" + showDeci(subTotal);

	// calculate tax
	total += tax;
	
	// calculate shipping & handling
	// Math.ceil(weight)
	total += shipping;

	// Total
	totalField = document.getElementById("TotalAmt");
	totalField.innerHTML = "$" + showDeci(total);

	f.TotalAmount.value = total;
}

function showDeci(val)
{
	val = "" + val;
	if (val == "null")
		return "0.00";

	var ret = val;
	var idx = val.indexOf(".");
	if (idx == -1)
		ret += ".00";
	else if (idx > val.length-3)
		ret += "0";					// there is the decimal point
	return ret;
}
//-->
</script>

<title>
	Order Form
</title>

</head>

<style type="text/css">
td,th,p,a {font-family:arial,verdana,sans-serif;font-size:12px;}
.headlnk_blue_13 {  font-family: Verdana, Arial, Helvetica, sans-serif; color: #202099; font-size: 13px; font-weight: bold}
</style>


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
	            <table width="780" border="0" cellspacing="0" cellpadding="0">
				  <tr>
					<td width="20" height="30"><a name="top">&nbsp;</a></td>
					<td width="570" height="30" align="left" valign="bottom" class="head">
					  <b>Book Order Form</b>
					</td>
					<td>
<!-- Add links here -->
					</td>
				  </tr>
	            </table>
	          </td>
	        </tr>

			<tr>
          		<td width="100%" valign="top">
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
					<td><a href="http://www.leadershipfoundation.org/" class="subnav">Home</a></td>
					<td colspan="3" width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- FAQ -->
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="faq.jsp" class="subnav">FAQ</a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- Place Order -->
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="20" height="14"><img src="../i/nav_arrow.gif" width="20" height="14" border="0"></td>
					<td><a href="#" onClick="return false;" class="subnav"><u>Place Order</u></a></td>
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
				</td>
	        </tr>
		</table>
		<!-- Content Table -->

		 <table width="780" border="0" cellspacing="0" cellpadding="0">


			<tr><td colspan="2">&nbsp;</td></tr>
			<tr>
				<td><img src="../i/spacer.gif" width="5" border="0"></td>
				<td width="758">

<!-- *************************   Page Headers   ************************* -->

<!-- LABEL -->
<table border="0" cellspacing="0" cellpadding="0">
<tr>
<td>

<form name='OrderForm' action='javascript:update();' method='post'>
<input type='hidden' name='TotalAmount' value=''>

	<table border="0" cellspacing="0" cellpadding="0">
		<tr>
			<td><img src='../i/spacer.gif' width='20' height='1' /></td>
			<td class='headlnk_blue_13' width='200'><font color='#000000'>*</font> Your Email:</td>
			<td><input type='text' name='Email' class='formtext' size='30' value='<%=email%>'>
<!--			<span class='plaintext_small'>&nbsp;&nbsp;(This is your login name)</span>  -->
			</td>
		</tr>
		
		<tr><td><img src='../i/spacer.gif' width='1' height='5' /></td></tr>
		
		<tr>
			<td></td>
			<td class='headlnk_blue_13' width='200'>&nbsp;&nbsp;&nbsp;Your Phone No.:</td>
			<td><input type='text' name='Phone' class='formtext' size='30' value=''></td>
		</tr>
		
		<tr><td><img src='../i/spacer.gif' width='1' height='10' /></td></tr>
		
		<tr>
			<td colspan='3'>
			<table border="0" cellspacing="0" cellpadding="0">
				<tr>
					<td><img src='../i/spacer.gif' width='20' height='1' /></td>
					<td>&nbsp;</td>
					<td class='plaintext_big' width='100' align='right'><u>Unit Price</u></td>
					<td class='plaintext_big' width='100' align='right'><u>Quantity</u></td>
					<td class='plaintext_big' width='100' align='right'><u>Sub-Total</u></td>
				</tr>
		
				<tr><td><img src='../i/spacer.gif' width='1' height='10' /></td></tr>

<%
		for (int i=0; i<bookArr.length; i++)
		{
			out.print("<tr><td></td>");
			out.print("<td class='plaintext' width='400'>" + bookArr[i] + "</td>");
			out.print("<td class='plaintext' align='right'>$<span id='Price_" + i + "'>" + bookPrice[i] + "</span></td>");
			out.print("<td class='plaintext' align='right'><input class='plaintext' type='text' id='Quantity_" + i + "' size='2'></td>");
			out.print("<td class='plaintext' align='right'><span id='SubTotal_" + i + "'></span></td>");
			
			out.print("<input type='hidden' id='Weight_" + i + "' value='" + bookWeight[i] + "'>");
			out.print("</tr>");
		}
%>
		
				<tr><td><img src='../i/spacer.gif' width='1' height='10' /></td></tr>

				<tr>
					<td colspan='4' align='right'>
						<input type='submit' class='button_medium' value='Update'>
					</td>
				</tr>
		
				<tr><td><img src='../i/spacer.gif' width='1' height='10' /></td></tr>
				
				<tr>
					<td colspan='4' align='right' class='plaintext'><i>Sub-Total:</i></td>
					<td class='plaintext' align='right'><span id='SubTotal'>$0.00</span></td>
				</tr>

				<tr>
					<td colspan='4' align='right' class='plaintext'><i>Sales Tax:</i></td>
					<td class='plaintext' align='right'><span id='Tax'>$0.00</span></td>
				</tr>

				<tr>
					<td colspan='4' align='right' class='plaintext'><i>Shpping & Handling:</i></td>
					<td class='plaintext' align='right'><span id='Shipping'>$0.00</span></td>
				</tr>

				<tr>
					<td colspan='4' align='right' class='plaintext_bold'>Total Amount Due:</td>
					<td class='plaintext_bold' align='right'><span id='TotalAmt'>$0.00</span></td>
				</tr>
				
			</table>
			</td>
		</tr>

	</table>
</form>

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

