<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>

<%
////////////////////////////////////////////////////
//	Copyright (c) 2017, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	challenge.jsp
//	Author:	ECC
//	Date:	11/01/17
//	Description:
//		Challenge page. Create, display and update a challenge in OpenAI.
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
<%@ page import = "org.apache.commons.lang.StringEscapeUtils" %>
<%@ page import = "java.text.SimpleDateFormat" %>

<%@ page import = "javax.xml.parsers.*" %>
<%@ page import = "org.w3c.dom.*" %>
<%@ page import = "org.xml.sax.SAXException" %>
<%@ page import = "org.xml.sax.InputSource" %>

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	// this JSP requires the id to be the Model Robot ID, if it is not we need to find it
	String chIdS = request.getParameter("id");
	String noSession = "../out.jsp?go=bots/challenge.jsp?id="+chIdS;
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />


<%
	
	String s;
	SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd HH:mm");
	
	boolean bReadOnly = true;
	
	// create a new challenge?
	s = request.getParameter("cr");
	boolean bCreateChallenge = (s!=null && s.equals("1"));

	if (StringUtil.isNullOrEmptyString(chIdS) && !bCreateChallenge) {
		response.sendRedirect("../out.jsp?go=../bots/challenge.jsp");
		return;		
	}
	int [] ids;
	PstAbstractObject [] rbArr = null;
	
	int chId = 0;
	int myUid = pstuser.getObjectId();

	challengeManager chMgr = challengeManager.getInstance();
	
	String pageLabel = "";
	if (bCreateChallenge) {
		pageLabel = "New Challenge";
	}
	else {
		pageLabel = "Challenge";
	}
	
	robot chObj = null;

	String synopsis = null;
	String category;
	String creatorIdS;
	String createdDtS;
	String companyIdS;
	String desc;
	String keywords;
	
	String disabledStr = "";
	
	
	// display the challenge
	if (!bCreateChallenge) {
		
		// get challenge info
		chId = Integer.parseInt(chIdS);
		chObj = (robot) chMgr.get(pstuser, chId);
		
	
		// challenge attributes
		synopsis = chObj.getStringAttribute("Synopsis");
		category = chObj.getStringAttribute("Category");
		desc = chObj.getRawAttributeAsUtf8("Description");
		creatorIdS = chObj.getStringAttribute("Creator");
		companyIdS = chObj.getStringAttribute("Company");
		
		Date dt = (Date) chObj.getAttribute("CreatedDate")[0];
		createdDtS = df.format(dt);
		
		if (bReadOnly) disabledStr = "disabled";
	
	}	// END if: bCreateChallenge
	
%>


<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<link href="oct-bots.css" rel="stylesheet" type="text/css" />
<script language="JavaScript" src="../meeting/ajax_utils.js"></script>
<script language="JavaScript" src="botsAction.js"></script>

<script language="JavaScript">
<!--
var bReadOnly = <%=bReadOnly%>;

window.onload = function()
{
}

function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

// for Save or Submit
function validation(bSaveOnly)
{
	if (bReadOnly) {
		alert("Read Only");
		return;
	}
	
	var val = goChallengeForm.synopsis.value.trim();
	if (val == '')
	{
		fixElement(goChallengeForm.synopsis,
			"Please make sure to enter a 1-line topic for the challenge.");
		return false;
	}

	// save
	goChallengeForm.submit();
}

function delBot()
{
	if (confirm("Are you sure you want to permanently delete this challenge?")) {
		location = "post_challenge.jsp?del=<%=chId%>";
	}
}

//-->
</script>

<title>
	Omm Challenge
</title>

</head>


<body bgcolor="#FFFFFF" >


<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="100%" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<table>

	<tr><td colspan="2">&nbsp;</td></tr>
	<tr>
	<td></td>
	<td class="head">
		Distributive Big Data & AI
	</td></tr>

	</table>

	<table width="90%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- CONTENT -->
<form method="post" name="goChallengeForm" action="post_challenge.jsp">
<input type='hidden' name='SaveOnly' value='' />
<input type='hidden' name='bReadOnly' value='<%=bReadOnly%>' />

<table border='0' cellspacing='0' cellpadding='0' width='90%'>

	<tr>
		<td width='30'>&nbsp;</td>
		<td colspan='2' class='instruction_head'><br/><b><%=pageLabel%></b></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td colspan='2' class="instruction">
		<br/>
		</td>
	</tr>

<%	if (!bCreateChallenge) { %>
<!-- Synopsis -->
	<tr>
		<td><img src='../i/spacer.gif' width='15' height='1'/></td>
		<td width='210' class="plaintext_head_blue">Challenge</td>
		<td class='plaintext_big2'><b>CH-<%=chIdS %></b>
			&nbsp;&nbsp;&nbsp; <%=synopsis %>
		</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='5'/></td></tr>
	
<!-- Description -->
	<tr>
		<td colspan='2'><a name='clone'></a></td>
		<td><table><tr>
			<td><img src='../i/spacer.gif' width='10'/></td>
			<td class='plaintext_big' width='700'><%=desc %></td>
		</tr></table></td>
	</tr>
	
<!-- Organization -->
	<tr>
		<td colspan='2'></td>
		<td><table><tr>
			<td><img src='../i/spacer.gif' width='10'/></td>
			<td class='plaintext_big' width='700' align='right'><i><%=modelComp %></i></td>
		</tr></table></td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='20'/></td></tr>
	<tr><td colspan='5'><hr class='style1'></hr></td></tr>
	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='20'/></td></tr>
<%	} %>

	
<!-- ********************* -->
<!-- Display cloned robots -->
	<tr>
		<td colspan="5">
			<div id='piccontainer' style='display:none;'></div>
		</td>
	</tr>


<% if (!bReadOnly || bCreateChallenge) {
	// show the challenge synopsis and description
%>
<!-- Challenge Info -->
	<tr>
		<td></td>
		<td class="plaintext_head_blue">Challenge CH-<%=chIdS%> Information</td>
		<td>
		</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='10'/></td></tr>

<%	if (!bCreateChallenge) { %>	
	<tr>
		<td></td>
		<td class="plaintext_bold"><img src='../i/spacer.gif' width='10' height='1'/>
			Challenge ID</td>
		<td class='plaintext_blue'>CH-<%=chIdS%></td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='5'/></td></tr>
<%	} %>

	<tr>
		<td></td>
		<td class="plaintext_bold"><img src='../i/spacer.gif' width='10' height='1'/>
			Challenge CH-<%=chIdS%>
		</td>
		<td>
			<input type="text" name="synopsis" class='formtext' style='width:500px;'
					value='<%=synopsis%>'  <%=disabledStr%>/>
		</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='5'/></td></tr>
		
	<tr>
		<td></td>
		<td class="plaintext_bold" valign='top'><img src='../i/spacer.gif' width='10' height='1'/>
			Description
		</td>
		<td>
			<textarea name="cloneDesc" class='formtext'
				style='width:500px; height:50px' <%=disabledStr%>><%=cloneDesc%></textarea>
		</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='5'/></td></tr>
		
<%	if (!bCreateChallenge) { %>	
	<tr>
		<td></td>
		<td class="plaintext_bold" valign='top'><img src='../i/spacer.gif' width='10' height='1'/>
			In Service Since</td>
		<td class='plaintext'><%=createdDt %></td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='20'/></td></tr>
<%	}

	} %>

<!-- Algorithm -->
	<tr>
		<td></td>
		<td class="plaintext_head_blue">Algorithm</td>
		<td>
		</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='10'/></td></tr>
	
	<tr>
		<td></td>
		<td class="plaintext_bold"><img src='../i/spacer.gif' width='10' height='1'/>
			Program
		</td>
		<td>
			<input type="text" name="Class" class='formtext' style='width:330px;'  value='<%=evalClassName%>'  <%=disabledStr%>/>&nbsp;
			<input type="text" name="Method" class='formtext' style='width:160px;' value='<%=evalMethodName%>' <%=disabledStr%>/>
		</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='5'/></td></tr>
	
	<tr>
		<td></td>
		<td class="plaintext_bold" valign='top'><img src='../i/spacer.gif' width='10' height='1' />
			Condition
		</td>
		<td>
			<textarea name="Expr" class='formtext' style='width:500px; height:40px;' <%=disabledStr%> ><%=expr%></textarea>
		</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='5'/></td></tr>
	
	<tr>
		<td></td>
		<td class="plaintext_bold"><img src='../i/spacer.gif' width='10' height='1'/>
			Learning rate (α)
		</td>
		<td>
			<select class='formtext' name="Alpha" style='width:170px;' <%=disabledStr%>>
			<option value='0'>- select Alpha -</option>
<%
			String [] alphaArr = {"0.001", "0.003", "0.01", "0.03", "0.1", "0.3", "1"};
			for (int i=0; i<alphaArr.length; i++) {
				out.print("<option value='" + alphaArr[i] + "' ");
				if (alphaArr[i].equals(alpha))
					out.print("selected");
				out.print(">" + alphaArr[i] + "</option>");
			}
%>
			</select>
		</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='5'/></td></tr>
	
	<tr>
		<td></td>
		<td class="plaintext_bold"><img src='../i/spacer.gif' width='10' height='1'/>
			Regularization parameter (λ)
		</td>
		<td>
			<select class='formtext' name="Lambda" style='width:170px;' <%=disabledStr%>>
			<option value='0'>- select Lambda -</option>
<%
			String [] lamArr = {"0", "10", "100", "1000", "10000", "100000", "1000000"};
			for (int i=0; i<lamArr.length; i++) {
				out.print("<option value='" + lamArr[i] + "' ");
				if (lamArr[i].equals(lambda))
					out.print("selected");
				out.print(">" + lamArr[i] + "</option>");
			}
			// random
			out.print("<option value='random' ");
			if ("random".equals(lambda))
				out.print("selected");
			out.print(">random</option>");
%>
			</select>
		</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='5'/></td></tr>
	
	<tr>
		<td></td>
		<td class="plaintext_bold"><img src='../i/spacer.gif' width='10' height='1'/>
			Initial weight (θ)
		</td>
		<td>
			<select class='formtext' name="Theta" style='width:170px;' <%=disabledStr%>>
			<option value='0'>- select Theta -</option>
<%
			String [] thetaArr = {"0.001", "0.01", "0.1", "1"};
			for (int i=0; i<thetaArr.length; i++) {
				out.print("<option value='" + thetaArr[i] + "' ");
				if (thetaArr[i].equals(theta))
					out.print("selected");
				out.print(">" + thetaArr[i] + "</option>");
			}
			// random
			out.print("<option value='random' ");
			if ("random".equals(theta))
				out.print("selected");
			out.print(">random</option>");
%>
			</select>
		</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='20'/></td></tr>


<!-- Solutions -->
	<tr>
		<td></td>
		<td class="plaintext_head_blue">Solution</td>
		<td>
		</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='10'/></td></tr>
	
	<tr>
		<td></td>
		<td class="plaintext_bold"><img src='../i/spacer.gif' width='10' height='1'/>
			Size Limit
		</td>
		<td>
			<select class='formtext' name="SizeLimit" style='width:170px;' <%=disabledStr%>>
			<option value='0'>- select size limit -</option>
<%
			String [] sizeArr = {"500", "1000", "10000", "100000", "1000000"};
			String [] sizeCommaArr = {"500", "1,000", "10,000", "100,000", "1,000,000"};
			for (int i=0; i<sizeArr.length; i++) {
				out.print("<option value='" + sizeArr[i] + "' ");
				if (sizeArr[i].equals(selSizeLimit))
					out.print("selected");
				out.print(">" + sizeCommaArr[i] + "</option>");
			}
			// unlimited
			out.print("<option value='unlimited' ");
			if ("unlimited".equals(selSizeLimit))
				out.print("selected");
			out.print(">1,000,000+</option>");
%>
			</select>
		</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='5'/></td></tr>
	
	<tr>
		<td></td>
		<td class="plaintext_bold"><img src='../i/spacer.gif' width='10' height='1'/>
			Time Limit
		</td>
		<td>
			<select class='formtext' name="TimeLimit" style='width:170px;' <%=disabledStr%>>
			<option value="">- select time limit -</option>
<%
			String [] timeArr = {"1", "5", "10", "15", "30", "60", "300", "720", "1440", "2880"};
			String [] timeStrArr = {"1 min", "5 min", "10 min", "15 min", "30 min", "1 hr", "5 hr", "12 hr", "24 hr", "48 hr"};
			for (int i=0; i<timeArr.length; i++) {
				out.print("<option value='" + timeArr[i] + "' ");
				if (timeArr[i].equals(selTimeLimit))
					out.print("selected");
				out.print(">" + timeStrArr[i] + "</option>");
			}
%>
			</select>
		</td>
	</tr>

	
	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='20'/></td></tr>


<!-- Submit Button -->
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan='4' align="right"><br/>
<% if (!bReadOnly || bCreateChallenge) { %>
			<input type="button" value="   Save   " class='button_medium' onclick='return validation(true);'/>&nbsp;
<% if (!bCreateChallenge) { %>
			<input type="submit" name="Submit" value="  Deploy  " onclick='return validation();' class='button_medium'/>
<% }}  else { %>
			<img src='../i/spacer.gif' width='20' height='1'/>
			<button type="button" onclick="cloneBots();" class='button_medium'>Clone</button>
<% } %>
		</td>
		<td align='right' valign='bottom'>
			<input type="button" value="Back" onclick="location='listBots.jsp';" class='button_medium'/>
		</td>
	</tr>

	
</table>

</form>



<!-- BEGIN FOOTER TABLE -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</td></tr>
</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

