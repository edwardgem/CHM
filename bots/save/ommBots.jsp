<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>

<%
////////////////////////////////////////////////////
//	Copyright (c) 2017, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	ommBots.jsp
//	Author:	ECC
//	Date:	04/11/17
//	Description:
//		Omm Robot page.
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

<%@ page import = "javax.xml.parsers.*" %>
<%@ page import = "org.w3c.dom.*" %>
<%@ page import = "org.xml.sax.SAXException" %>
<%@ page import = "org.xml.sax.InputSource" %>

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	String rbIdS = request.getParameter("id");
	String noSession = "../out.jsp?go=bots/ommBots.jsp?id="+rbIdS;
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />


<%
	final String EXT_XML				= ".xml";
	final String TAG_ORGNAME			= "Name";
	final String TAG_EVAL_METHOD		= "Eval_Method";
	final String TAG_EXPR				= "Expr";
	final String TAG_ALPHA				= "Alpha";
	final String TAG_LAMBDA				= "Lambda";
	final String TAG_THETA				= "Theta";
	final String TAG_SIZE_LMT			= "Size_Limit";
	final String TAG_TIME_LMT			= "Time_Limit";
	
	final String TAG_DOMAIN				= "Domain";				// distributive domain specification
	final String TAG_URL				= "URL";				// webservice URL

	if (StringUtil.isNullOrEmptyString(rbIdS)) {
		response.sendRedirect("../out.jsp?go=../bots/listBots.jsp");
		return;		
	}
	String s;
	int rbId = Integer.parseInt(rbIdS);
	
	robotManager rbMgr = robotManager.getInstance();
	
	robot rbObj = (robot) rbMgr.get(pstuser, rbId);
	String botName = rbObj.getObjectName();
	String dispName = rbObj.getStringAttribute("DisplayName");

	// robot name
	String evalClassName = "";
	String evalMethodName = "";
	String expr = "None";
	String alpha = "";
	String lambda = "";
	String theta = "";
	String selSizeLimit = "";
	String selTimeLimit = "";
	
	ArrayList <String> nodeList = new ArrayList<String>();
	ArrayList <String> authList = new ArrayList<String>();
	int totalNodesInXML = 0;
	int idx;
	
	// check to see if user has selected a Robot name already
	// If so, get the info from XML file
	String xml = rbObj.getRawAttributeAsUtf8("Content");

	if (xml != null) {
		xml = xml.replaceAll("&\\s+", "&amp;");		// escape & sign in the condition expression
		DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
		DocumentBuilder builder = factory.newDocumentBuilder();
		InputSource is = new InputSource(new StringReader(xml));
		Document document = builder.parse(is);
		
		
		Element root = document.getDocumentElement();
		s = XML.getXMLString(TAG_ORGNAME, root);
		
		if (!s.equalsIgnoreCase(botName)) {
			response.sendRedirect("../out.jsp?msg=Mismatch OmmOrg name found in XML.");
			return;
		}
		
		// get eval() class method
		if ((s = XML.getXMLString(TAG_EVAL_METHOD, root)) != null) {
			idx = s.lastIndexOf(".");
			if (idx == -1) {
				response.sendRedirect("../out.jsp?msg=<"+TAG_EVAL_METHOD+"> tag illegal class.method expression: " + s);
				return;
			}
			evalClassName  = s.substring(0,idx).trim();
			evalMethodName = s.substring(idx+1).trim() + "()";
		}
			
		// get expression
		if ((s = XML.getXMLString(TAG_EXPR, root)) != null) {
			expr = Util.stringToHTMLString(s.trim());
		}
		
		// Alpha
		if ((s = XML.getXMLString(TAG_ALPHA, root)) != null) {
			alpha = Util.stringToHTMLString(s.trim());
		}
		
		// Lambda
		if ((s = XML.getXMLString(TAG_LAMBDA, root)) != null) {
			lambda = Util.stringToHTMLString(s.trim());
		}
		
		// Theta
		if ((s = XML.getXMLString(TAG_THETA, root)) != null) {
			theta = Util.stringToHTMLString(s.trim());
		}
		
		// Size Limit
		if ((s = XML.getXMLString(TAG_SIZE_LMT, root)) != null) {
			selSizeLimit = Util.stringToHTMLString(s.trim());
		}
		
		// Time Limit
		if ((s = XML.getXMLString(TAG_TIME_LMT, root)) != null) {
			selTimeLimit = Util.stringToHTMLString(s.trim());
		}
		
		// domains
		XML.getNodeArray(nodeList, root, TAG_DOMAIN);
		totalNodesInXML = nodeList.size();
	
		XML.getNodeAuthcode(authList, root, TAG_DOMAIN, false);
	}
%>


<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>

<script language="JavaScript">
<!--
var totalXmlNodes = 0 + <%=totalNodesInXML%>;

function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

// for Save or Submit
function validation(bSaveOnly)
{
	if (goRobotForm.BotName.value =='')
	{
		fixElement(goRobotForm.BotName,
			"Please make sure to choose a Robot.");
		return false;
	}

	if (goRobotForm.Expr.value.trim() == 'None')
		goRobotForm.Expr.value = '';

	if (bSaveOnly)
		goRobotForm.SaveOnly.value = 'true';
	
	// check to see if there are new nodes defined
	var tabl = document.getElementById("nodeTable");
	var totalNodesOnPage = tabl.rows.length - 1;
	goRobotForm.TotalXmlNodes.value = totalXmlNodes;
	goRobotForm.XmlNodesOnPage.value = totalNodesOnPage;

	// save to XML
	goRobotForm.submit();
}

// get the Robot content from XML
function getRobot(robotItem)
{
	var robotName = robotItem.value;
	goRobotForm.action = 'ommBots.jsp';
	goRobotForm.submit();
}

function addNewNode()
{
	var tabl = document.getElementById("nodeTable");
	var lnkRow = document.getElementById("newLink");
	var len = tabl.rows.length;
	var aRow = tabl.rows[0].cloneNode(true);
	var nodeId = 'Node' + len;
	var authId = 'Auth' + len;
	aRow.cells[0].innerHTML = "<img src='../i/spacer.gif' width='15' height='20'/>"
			+ "Node " + len;
	aRow.cells[1].innerHTML = "<input type='text' id='"
		+ nodeId + "' name='" + nodeId + "' value='' "
		+ "class='formtext' style='width:300px;'/>&nbsp;"
		+ "<input type='password' id='"
		+ authId + "' name='" + authId + "' value='' "
		+ " onfocus='showPswd(" + len + ",true);' name='Auth" + len
		+ "' onfocusout='showPswd(" + len + ",false);'"
		+ "class='formtext' style='width:150px;'/>";
	lnkRow.parentNode.insertBefore(aRow, lnkRow);
	document.getElementById(nodeId).focus();
}

function showPswd(id, bShow)
{
	var e = document.getElementById("Auth" + id);
	if (bShow)
		e.setAttribute('type', 'text');
	else
		e.setAttribute('type', 'password');
}

//-->
</script>

<title>
	Omm Robots
</title>

</head>


<body bgcolor="#FFFFFF" >

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="715" border="0" cellspacing="0" cellpadding="0" align="left">

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
		Distributive Big Data
	</td></tr>

	</table>

	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- CONTENT -->
<form method="post" name="goRobotForm" action="post_ommBots.jsp">
<input type='hidden' name='SaveOnly' value='' />
<input type='hidden' name='TotalXmlNodes' value='' />
<input type='hidden' name='XmlNodesOnPage' value='' />

<table border='0' cellspacing='0' cellpadding='0'>

	<tr>
		<td width='30'>&nbsp;</td>
		<td colspan='2' class='instruction_head'><br/><b>OMM Robots for Machine Learning</b></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td colspan='2' class="instruction">
		<br/>
		</td>
	</tr>


<!-- Robot Name -->
	<tr>
		<td><img src='../i/spacer.gif' width='15' height='1'/></td>
		<td width='250' class="plaintext_blue">Robot Name</td>
		<td class='plaintext_big2'><b><%=botName %></b>
			&nbsp;&nbsp;&nbsp; <%=dispName %>
		</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='20'/></td></tr>


<!-- Algorithm -->
	<tr>
		<td></td>
		<td class="plaintext_blue">Algorithm</td>
		<td>
		</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='5'/></td></tr>
	
	<tr>
		<td></td>
		<td class="plaintext_bold"><img src='../i/spacer.gif' width='10' height='1'/>
			Program
		</td>
		<td>
			<input type="text" name="Class" class='formtext' style='width:300px;'  value='<%=evalClassName%>'/>&nbsp;
			<input type="text" name="Method" class='formtext' style='width:150px;' value='<%=evalMethodName%>'/>
		</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='5'/></td></tr>
	
	<tr>
		<td></td>
		<td class="plaintext_bold"><img src='../i/spacer.gif' width='10' height='1'/>
			Condition
		</td>
		<td>
			<input type="text" name="Expr" class='formtext' style='width:460px;' value='<%=expr%>' />
		</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='5'/></td></tr>
	
	<tr>
		<td></td>
		<td class="plaintext_bold"><img src='../i/spacer.gif' width='10' height='1'/>
			Learning rate (α)
		</td>
		<td>
			<select class='formtext' name="Alpha" style='width:150px;'>
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
			<select class='formtext' name="Lambda" style='width:150px;'>
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
			<select class='formtext' name="Theta" style='width:150px;'>
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


<!-- Learning Sample -->
	<tr>
		<td></td>
		<td class="plaintext_blue">Learning Sample</td>
		<td>
		</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='5'/></td></tr>
	
	<tr>
		<td></td>
		<td class="plaintext_bold"><img src='../i/spacer.gif' width='10' height='1'/>
			Size Limit
		</td>
		<td>
			<select class='formtext' name="SizeLimit" style='width:150px;'>
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
			<select class='formtext' name="TimeLimit" style='width:150px;'>
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
			<option value='1'>1 min</option>
			<option value='5'>5 min</option>
			<option value='10'>10 min</option>
			<option value='15'>15 min</option>
			<option value='30'>30 min</option>
			<option value='60'>1 hr</option>
			<option value='300'>5 hr</option>
			<option value='720'>12 hr</option>
			<option value='1440'>24 hr</option>
			<option value='2880'>48 hr</option>
			</select>
		</td>
	</tr>
	
	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='20'/></td></tr>


<!-- Domains -->
	<tr>
		<td></td>
		<td class="plaintext_blue">Domains</td>
		<td>
		</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='5'/></td></tr>
	
<%
		// one node per line
		out.print("<tr><td></td>");		// <---

		out.print("<td colspan='2'><table id='nodeTable' border='0' cellspacing='0' cellpadding='0'>");	// a new table
		
		// node index starts from 1
		String authStr;
		for (int i=0; i<nodeList.size(); i++) {
			if ((authStr = authList.get(i)) == null)
				authStr = "";
			
			out.print("<tr>");
			out.print("<td width='250' class='plaintext_bold'><img src='../i/spacer.gif' width='15' height='20'/>");
			out.print("Node " + (i+1));
			out.print("</td>");
			
			out.print("<td><input type='text' name='Node" + (i+1)
					+ "' id='" + "Node" + (i+1)
					+ "' value='" + nodeList.get(i)
					+ "' class='formtext' style='width:300px;' />&nbsp;");
			out.print("<input type='password'"
					+ " onfocus='showPswd(" + (i+1) + ",true);' name='Auth" + (i+1)
					+ "' onfocusout='showPswd(" + (i+1) + ",false);'"
					+ "' id='" + "Auth" + (i+1)
					+ "' value='" + authStr
					+ "' class='formtext' style='width:150px;' />");
			out.print("</td>");
			out.print("</tr>");
		}
		
		// space for adding new node
		//out.print("<div id='newNode'></div>");
		
		// add new node
		out.print("<tr id='newLink'><td>&nbsp;</td>");
		out.print("<td><a href='javascript:addNewNode();'>Add new node</a></td>");
		out.print("</tr>");
		
		out.print("</table></td>");
		out.print("</tr>");				// -->
%>


	
	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='20'/></td></tr>


<!-- Submit Button -->
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan='2' class="10ptype" align="right"><br/>
			<input type="button" value="   Save   " class='button_medium' onclick='return validation(true);'/>&nbsp;
			<input type="submit" name="Submit" value="  Submit  " onclick='return validation();' class='button_medium'/>
			<img src='../i/spacer.gif' width='20' height='1'/>
			<input type="button" value="Cancel" onclick="window.close();" class='button_medium'/>
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

