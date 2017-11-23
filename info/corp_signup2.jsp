<%
//
//	Copyright (c) 2007, EGI Technologies, Co.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: corp_signup2.jsp
//	Author: ECC
//	Date:	01/08/07
//	Description: Signup a new company on MeetWE.
//
//
//	Modification:
// 
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "util.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pmp.exception.*" %>

<%
	String COMPANY		= Util.getPropKey("pst", "COMPANY_NAME");
	String NODE			= Util.getPropKey("pst", "PRM_HOST");
	String ADMIN_MAIL	= Util.getPropKey("pst", "FROM");
	
	boolean isLogin = false;
	if (session != null)
	{
		PstUserAbstractObject pstuser = (PstUserAbstractObject)session.getAttribute("pstuser");
		if (pstuser != null && !(pstuser instanceof PstGuest))
			isLogin = true;
	}
	
	// get parameters from caller (corp_signup1.jsp)
	String compName = request.getParameter("CompanyName");
	String domain = request.getParameter("Domain");
	
	// check for company domain to see if it already exist
	townManager tnMgr = townManager.getInstance();
	PstUserAbstractObject gUser = (PstUserAbstractObject) PstGuest.getInstance();
	int [] id = tnMgr.findId(gUser, "Email='" + domain + "'");
	if (id.length > 0)
	{
		// domain already exists
		response.sendRedirect("../out.jsp?msg=The DOMAIN you specified is already registered.  "
					+ "If you have made a mistake, please correct it and submit the request again, otherwise, "
					+ "contact HELP by emailing to <a href='mailto:support@MeetWE.com'>support@MeetWE.com</a>.");
		return;
	}

	// check for company name to see if it already exist
	id = tnMgr.findId(gUser, "om_acctname='" + compName + "'");
	if (id.length > 0)
	{
		// company name already exists
		response.sendRedirect("../out.jsp?msg=The COMPANY NAME you specified is already registered.  "
					+ "Please choose a different name and submit the request again, for further help, "
					+ "please email to <a href='mailto:support@MeetWE.com'>support@MeetWE.com</a>.");
		return;
	}

%>


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html lang="en">

<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../formsM.jsp" flush="true"/>
<script language="JavaScript" src="../get-date.js"></script>
<script language="JavaScript" src="../date.js"></script>

<script language="JavaScript">
<!--
function fo()
{
	var Form = document.newCompany;
	for (i=0;i < Form.length;i++)
	{
		if (Form.elements[i].type != "hidden")
		{
			Form.elements[i].focus();
			break;
		}
	}
}

function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

function validation()
{
	var f = document.newCompany;
	
	var fName = trim(f.FirstName.value);
	if (fName.length <= 0)
	{
		fixElement(f.FirstName,
			"Please make sure that the FIRST NAME field is properly completed.");
		return false;
	}
	f.FirstName.value = fName;
	
	var lName = trim(f.LastName.value);
	if (lName.length <= 0)
	{
		fixElement(f.LastName,
			"Please make sure that the LAST NAME field is properly completed.");
		return false;
	}
	f.LastName.value = lName;
	
	var phone = trim(f.Phone.value);
	if (phone.length > 0)
	{
		if (!checkPhone(phone))
		{
			fixElement(f.Phone,
				"'" + phone + "' is not a valid phone number, \nplease correct the error and submit again.");
			return false;
		}
	}
	else
	{
		fixElement(f.Phone,
			"Please make sure that the PHONE field is properly completed.");
		return false;
	}
	f.Phone.value = phone;
	
	var email = trim(f.ContactEmail.value);
	if (email.length > 0)
	{
		if (!checkMail(email))
		{
			fixElement(f.ContactEmail,
				"'" + email + "' is not a valid Email, \nplease correct the error and submit again.");
			return false;
		}
	}
	else
	{
		fixElement(f.ContactEmail,
			"Please make sure that the EMAIL field is properly completed.");
		return false;
	}
	f.ContactEmail.value = email;
	
	var addr1 = trim(f.Address1.value);
	if (addr1.length <= 0)
	{
		fixElement(f.Address1,
			"Please make sure that the ADDRESS 1 field is properly completed.");
		return false;
	}
	f.Address1.value = addr1;
	f.Address2.value = trim(f.Address2.value);
	
	var city = trim(f.City.value);
	if (city.length <= 0)
	{
		fixElement(f.City,
			"Please make sure that the CITY field is properly completed.");
		return false;
	}
	f.City.value = city;
	
	var state = f.State.value;
	if (state.length <= 0)
	{
		fixElement(f.State,
			"Please make sure to select a STATE or select none.");
		return false;
	}
	
	var country = f.Country.value;
	if (country.length <= 0)
	{
		fixElement(f.Country,
			"Please make sure to select a COUNTRY.");
		return false;
	}

	return true;
}



//-->
</script>

</head>

<title>New Corporate Account</title>
<body onLoad="fo();" bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" height="100%" border="0" cellspacing="0" cellpadding="0">

<!-- TOP BANNER -->
<jsp:include page="infohead.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<b class="head">
           &nbsp;&nbsp;<b>New Corporate Account</b>
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

	<table border="0" width="620" height="14" cellspacing="0" cellpadding="0">
		<tr>
			<td valign="top" align="right" class="bgsubnav">
				<table border="0" cellspacing="0" cellpadding="0">
				<tr class="bgsubnav">
	<!-- Home -->
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="../index.jsp" class="subnav">Home</a></td>
					<td colspan="3" width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- FAQ -->
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="faq_omf.jsp" class="subnav">FAQ</a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- Terms of Use -->
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="terms_omf.jsp" class="subnav">Terms of Use</a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- Help Forum -->
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="help.jsp" class="subnav">Help Forum</a></td>
					<td colspan="3" width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

				</tr>
				</table>
			</td>
		</tr>
	</table>
	<table border="0" width="620" height="1" cellspacing="0" cellpadding="0">
		<tr>
			<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
		</tr>
	</table>

</td>
</tr>
</table>
<!-- End of Navigation SUB-Menu -->

<style type="text/css">
.headlnk_green {  font-family: Verdana, Arial, Helvetica, sans-serif; color: #30cc30; font-size: 16px; font-weight: bold}
.headlnk_blue {  font-family: Verdana, Arial, Helvetica, sans-serif; color: #3030cc; font-size: 14px; font-weight: bold}
a.headlnk_blue:link, a.headlnk_blue:active, a.headlnk_blue:visited {  font-family: Verdana, Arial, Helvetica, sans-serif; color: #3030cc; font-size: 14px; font-weight: bold}
.headlnk_pink {  font-family: Verdana, Arial, Helvetica, sans-serif; color: ee2288; font-size: 16px; font-weight: bold; text-decoration: none}
</style>

<!-- Content Table -->
<table width="770" border="0" cellspacing="0" cellpadding="0">
<tr><td colspan="2">&nbsp;</td></tr>


<form method="post" name="newCompany" id="newCompany" action="post_corp_signup.jsp">
<input type="hidden" name="CompanyName" value="<%=compName%>">
<input type="hidden" name="Domain" value="<%=domain%>">


	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="instruction_head"><br><b>Step 2 of 2: Enter Billing Information</b></td>
	</tr>

	<tr>
		<td width="20">&nbsp;</td>
		<td colspan=2 class="instruction">
		<br>Please note that fields marked with an * are required.<br><br></td>
	</tr>

<!-- *************** Contact Person -->
	<tr>
		<td width="20">&nbsp;</td>
		<td colspan='2' class="headlnk_dark">Contact Person</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' height='5'></td></tr>
	
<!-- First Name -->
	<tr>
		<td width="20">&nbsp;</td>
		<td width='150' class="plaintext_blue"><font color="#000000">*</font> First Name:</td>
		<td>
			<input class="formtext" type="text" name="FirstName" size="25" value=''>
		</td>
	</tr>

<!-- Last Name -->
	<tr>
		<td width="20">&nbsp;</td>
		<td width='150' class="plaintext_blue"><font color="#000000">*</font> Last Name:</td>
		<td>
			<input class="formtext" type="text" name="LastName" size="25" value=''>
		</td>
	</tr>

<!-- Phone -->
	<tr>
		<td width="20">&nbsp;</td>
		<td width='150' class="plaintext_blue"><font color="#000000">*</font> Phone:</td>
		<td>
			<table border="0" cellspacing="0" cellpadding="0">
			<tr>
				<td><input class="formtext" type="text" name="Phone" size="25" value=''>&nbsp;&nbsp;&nbsp;</td>
				<td valign='bottom' class="footnotes">(E.g. 123-123-1234 or 123 123 1234 or 123-333-1234 x555 or 852-1234-5678)</td>
			</tr>
			</table>
		</td>
	</tr>

<!-- Email -->
	<tr>
		<td width="20">&nbsp;</td>
		<td width='150' class="plaintext_blue"><font color="#000000">*</font> Email:</td>
		<td>
			<input class="formtext" type="text" name="ContactEmail" size="25" value=''>
		</td>
	</tr>


	<tr><td colspan='3'><img src='../i/spacer.gif' height='15'></td></tr>

<!-- *************** Billing Address -->
	<tr>
		<td width="20">&nbsp;</td>
		<td colspan='2' class="headlnk_dark">Billing Address</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' height='5'></td></tr>

<!-- Address1 -->
	<tr>
		<td width="20">&nbsp;</td>
		<td width='150' class="plaintext_blue"><font color="#000000">*</font> Address 1:</td>
		<td>
			<input class="formtext" type="text" name="Address1" size="50" value=''>
		</td>
	</tr>

<!-- Address2 -->
	<tr>
		<td width="20">&nbsp;</td>
		<td width='150' class="plaintext_blue">&nbsp;&nbsp;&nbsp;Address 2:</td>
		<td>
			<input class="formtext" type="text" name="Address2" size="50" value=''>
		</td>
	</tr>

<!-- City -->
	<tr>
		<td width="20">&nbsp;</td>
		<td width='150' class="plaintext_blue"><font color="#000000">*</font> City:</td>
		<td>
			<input class="formtext" type="text" name="City" size="30" value=''>
		</td>
	</tr>
	
<!-- State -->
	<tr>
		<td width="20">&nbsp;</td>
		<td width='150' class="plaintext_blue"><font color="#000000">*</font> State:</td>
		<td>
			<select name="State" class='formtext'> 
			<option value="" selected="selected">- Select a State -</option>
			<option value="none">none</option>
<%
	String [] state = {	"AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
						"GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
						"MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
						"NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
						"SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"};

	for (int i=0; i<state.length; i++)
		out.print("<option value='" + state[i] + "'>" + state[i] + "</option>");
%>
			</select>
		</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' height='2'></td></tr>

<!-- Country -->
	<tr>
		<td width="20">&nbsp;</td>
		<td width='150' class="plaintext_blue"><font color="#000000">*</font> Country:</td>
		<td>
			<select name="Country" class='formtext'> 
			<option value="" selected="selected">- Select a Country -</option>
<%
	String [] country = {	"Afghanistan","Albania","Algeria","American Samoa","Andorra","Angola",
							"Anguilla","Antarctica","Antigua and Barbuda","Argentina","Armenia","Aruba",
							"Australia","Austria","Azerbaijan","Bahamas","Bahrain","Bangladesh","Barbados",
							"Belarus","Belgium","Belize","Benin","Bermuda","Bhutan","Bolivia",
							"Bosnia and Herzegowina","Botswana","Bouvet Island","Brazil",
							"British Indian Ocean Territory","Brunei Darussalam","Bulgaria","Burkina Faso",
							"Burundi","Cambodia","Cameroon","Canada","Cape Verde","Cayman Islands",
							"Central African Republic","Chad","Chile","China","Christmas Island",
							"Cocos (Keeling) Islands","Colombia","Comoros","Congo",
							"Congo, the Democratic Republic of the","Cook Islands","Costa Rica",
							"Cote d'Ivoire","Croatia (Hrvatska)","Cuba","Cyprus","Czech Republic",
							"Denmark","Djibouti","Dominica","Dominican Republic","East Timor","Ecuador",
							"Egypt","El Salvador","Equatorial Guinea","Eritrea","Estonia","Ethiopia",
							"Falkland Islands (Malvinas)","Faroe Islands","Fiji","Finland","France",
							"France, Metropolitan","French Guiana","French Polynesia",
							"French Southern Territories","Gabon","Gambia","Georgia","Germany",
							"Ghana","Gibraltar","Greece","Greenland","Grenada","Guadeloupe","Guam",
							"Guatemala","Guinea","Guinea-Bissau","Guyana","Haiti","Heard and Mc Donald Islands",
							"Holy See (Vatican City State)","Honduras","Hong Kong","Hungary","Iceland",
							"India","Indonesia","Iran (Islamic Republic of)","Iraq","Ireland","Israel",
							"Italy","Jamaica","Japan","Jordan","Kazakhstan","Kenya","Kiribati",
							"Korea, Democratic People's Republic of","Korea, Republic of","Kuwait",
							"Kyrgyzstan","Lao People's Democratic Republic","Latvia","Lebanon","Lesotho",
							"Liberia","Libyan Arab Jamahiriya","Liechtenstein","Lithuania","Luxembourg",
							"Macau","Macedonia, The Former Yugoslav Republic of","Madagascar","Malawi",
							"Malaysia","Maldives","Mali","Malta","Marshall Islands","Martinique","Mauritania",
							"Mauritius","Mayotte","Mexico","Micronesia, Federated States of",
							"Moldova, Republic of","Monaco","Mongolia","Montserrat","Morocco","Mozambique",
							"Myanmar","Namibia","Nauru","Nepal","Netherlands","Netherlands Antilles",
							"New Caledonia","New Zealand","Nicaragua","Niger","Nigeria","Niue","Norfolk Island",
							"Northern Mariana Islands","Norway","Oman","Pakistan","Palau","Panama",
							"Papua New Guinea","Paraguay","Peru","Philippines","Pitcairn","Poland",
							"Portugal","Puerto Rico","Qatar","Reunion","Romania","Russian Federation",
							"Rwanda","Saint Kitts and Nevis","Saint LUCIA","Saint Vincent and the Grenadines",
							"Samoa","San Marino","Sao Tome and Principe","Saudi Arabia","Senegal",
							"Seychelles","Sierra Leone","Singapore","Slovakia (Slovak Republic)",
							"Slovenia","Solomon Islands","Somalia","South Africa",
							"South Georgia and the South Sandwich Islands","Spain","Sri Lanka",
							"St. Helena","St. Pierre and Miquelon","Sudan","Suriname",
							"Svalbard and Jan Mayen Islands","Swaziland","Sweden","Switzerland",
							"Syrian Arab Republic","Taiwan, Province of China","Tajikistan",
							"Tanzania, United Republic of","Thailand","Togo","Tokelau","Tonga",
							"Trinidad and Tobago","Tunisia","Turkey","Turkmenistan",
							"Turks and Caicos Islands","Tuvalu","Uganda","Ukraine","United Arab Emirates",
							"United Kingdom","United States","United States Minor Outlying Islands",
							"Uruguay","Uzbekistan","Vanuatu","Venezuela","Viet Nam",
							"Virgin Islands (British)","Virgin Islands","Wallis and Futuna Islands",
							"Western Sahara","Yemen","Yugoslavia","Zambia","Zimbabwe"};

	for (int i=0; i<country.length; i++)
		out.print("<option value=\"" + country[i] + "\">" + country[i] + "</option>");
%>
			</select>
		</td>
	</tr>

<!-- Submit Button -->
	<tr>
		<td width="20">&nbsp;</td>
		<td colspan=2 class="10ptype" align="left"><br>
			<img src='../i/spacer.gif' width='100' height='30' />
			<input type="Button" value="   << Back  " class="button_medium" onclick="history.back(-1)">&nbsp;
			<input type="Submit" name="Submit" class="button_medium" value='  Submit  ' onclick="return validation();">
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
