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
//		Omm Robot page. Bots name: model-ownerId-timestamp (H-1701-39412-389359458948)
//		Responsible for displaying a robot model, display/clone robots, or create a new model
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
	
	final String DEF_ROBOT_FILE			= "robot1.jpg";
	
	String READ_ONLY_ALERT_STR			= "Feature disabled for Read-only account";
	
	
	String s;
	SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd HH:mm");
	
	boolean isReadOnly = pstuser.getStringAttribute("Title").toLowerCase().contains("demo");
	
	// create a new robot model?
	s = request.getParameter("cr");
	boolean bCreateModel = (s!=null && s.equals("1"));

	if (StringUtil.isNullOrEmptyString(rbIdS) && !bCreateModel) {
		response.sendRedirect("../out.jsp?go=../bots/listBots.jsp");
		return;		
	}
	int [] ids;
	PstAbstractObject [] rbArr = null;
	
	int rbId = 0;
	int myUid = pstuser.getObjectId();

	robotManager rbMgr = robotManager.getInstance();
	
	// set up constant string
	StringBuffer sBuf = new StringBuffer(4096);
	sBuf.append("<table><tr>");
	for (int i=1; i<=5; i++) {
		sBuf.append( 
				"<td><a href='javascript:changeBot(" + i
				+ ");'><img src='../i/robot" + i + ".jpg' height='120'/></a></td>");
	}
	sBuf.append("<td valign='top' width='30' class='bot-td'>&nbsp;&nbsp;&nbsp;<a href='javascript:showChangeBotPanel(false);'><img src='../i/delete.gif' /></a></td>");
	sBuf.append("</tr></table>");
	String STR_BOTICONS = sBuf.toString();
	
	String pageLabel = "";
	String modelStr = "";
	if (bCreateModel) {
		pageLabel = "New OMM Robot Model";
		modelStr = "Model";
	}
	else {
		pageLabel = "OMM Robot for Machine Learning";
	}
	
	robot rbObj = null;
	robot parent = null;

	String modelName = null;
	String modelDispName = null;
	String modelDesc = null;
	String modelComp = null;
	boolean bShowModelOnly = true;			// set to true for show model and create model
	
	int selectedBotId = 0;
	int totalRobotCloned = 0;
	String botName = null;
	int totalNodesInXML = 0;
	int selectIdx = 0;			// by default the first one of the clone is selected
	String dispHTML = "";
	String disabledStr = "";
	String cloneDispName = "";
	String cloneDesc = "";
	String createdDt = null;
	
	ArrayList <String> nodeList = new ArrayList<String>();
	ArrayList <String> authList = new ArrayList<String>();

	
	// XML variables
	String evalClassName = " -";
	String evalMethodName = " -";
	String expr = "None";
	String alpha = "";
	String lambda = "";
	String theta = "";
	String selSizeLimit = "";
	String selTimeLimit = "";


	if (!bCreateModel) {
		
		// get robot model info
		rbId = Integer.parseInt(rbIdS);
		rbObj = (robot) rbMgr.get(pstuser, rbId);
		parent = rbObj;
		
		// assume rbId is the model (parent) ID, make sure that is the case
		// parentID==-1 for remote clones; parentID==null for models.
		s = rbObj.getStringAttribute("ParentID");
		if (s!=null && !s.equals("-1")) {
			// this is a robot, need to get parent and find this robot's index, then resubmit the call
			String parentId = s;
			ids = rbMgr.findId(pstuser, "ParentID='" + s + "'"); 
			rbArr = rbMgr.get(pstuser, ids);
			Util.sortName(rbArr);
			int idx = 0;
			for (int i=0; i<rbArr.length; i++) {
				if (rbArr[i].getObjectId() == rbId) {
					idx = i;
					break;
				}
			}
			response.sendRedirect("ommBots.jsp?id=" + parentId + "&idx=" + idx);
			return;		
		}
		
		modelName = parent.getObjectName();
		modelDispName = parent.getStringAttribute("DisplayName");
	
		
		s = request.getParameter("idx");
		if (!StringUtil.isNullOrEmptyString(s))
			selectIdx = Integer.parseInt(s);
		
	
		// get robots that I have cloned
		String botExpr;
		if (isReadOnly)
			botExpr = "om_acctname='" + modelName + "-%' && parentID!='-1' && State='%demo%'";
		else
			botExpr = "om_acctname='" + modelName + "-" + myUid + "%' && parentID!='-1'";
		
		ids = rbMgr.findId(pstuser, botExpr);
		totalRobotCloned = ids.length;
		String aName;
		PstAbstractObject aBot;
	
		if (totalRobotCloned > 0) {
			rbArr = rbMgr.get(pstuser, ids);
			Util.sortName(rbArr);
			rbObj = (robot) rbArr[selectIdx];			// show the selected robot
			selectedBotId = rbObj.getObjectId();
			
			String defRobotImg = parent.getStringAttribute("PictureFile");
			if (defRobotImg == null) defRobotImg = DEF_ROBOT_FILE;
			
			cloneDesc = rbObj.getRawAttributeAsUtf8("Description");
			if (cloneDesc == null) cloneDesc = "";
			
			// string to display the cloned robot images
			// <newBot1/> and <newBot2/> are placeholder to insert new robots
			String imgS;
			sBuf = new StringBuffer(4096);
			int aBotId;
			
			sBuf.append("<table border='0' style='border-spacing: 10px 2px;'><tr><td><img src='../i/spacer.gif' width='10'/></td>");
			for (int i=0; i<totalRobotCloned; i++) {
				aBotId = rbArr[i].getObjectId();
				imgS = rbArr[i].getStringAttribute("PictureFile");
				if (imgS == null) imgS = defRobotImg;
				sBuf.append("<td width='110' ");
				if (i == selectIdx) {
					sBuf.append("class='selected'><img src='../i/" + imgS + "' height='140'/></td>");
					sBuf.append("<td valign='top'>");
					sBuf.append("<div class='dropdown'>");
					sBuf.append("<img src='../i/dot_menu.jpg' width='8'/>");
					sBuf.append("<div class='dropdown-content'>");
					sBuf.append("<a href='javascript:chgName(" + aBotId + ");'>Change name</a>");
					sBuf.append("<a href='javascript:showChangeBotPanel(true);'>Change icon</a>");
					sBuf.append("<a href='javascript:delBot();'>Recycle</a>");
					sBuf.append("<a href='javascript:scan();'>Security scan</a>");
					sBuf.append("</div></div>");
					sBuf.append("</td>");
				}
				else {
					sBuf.append("class='regular'>");
					sBuf.append("<a href='javascript:changeSelected(" + i + ");'><img src='../i/"
								+ imgS + "' height='140'/></a></td><td></td>");
				}
			}
			sBuf.append("</tr><tr><td></td>");
			
			// the robot name
			for (int i=0; i<ids.length; i++) {
				aBot = rbArr[i];
				if ((aName = aBot.getStringAttribute("DisplayName")) == null)
					aName = rbArr[i].getObjectName();
				sBuf.append("<td align='center' class='plaintext_big'>" + aName + "</td><td></td>");
				if (i == selectIdx) cloneDispName = aName;
			}
			sBuf.append("</tr></table>");
			sBuf.append("<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='20'/></td></tr>");
			sBuf.append("<tr><td colspan='5'><hr class='style1'></hr></td></tr>");
			sBuf.append("<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='20'/></td></tr>");
	
			dispHTML = sBuf.toString();
		}
	
		// robot attributes
		botName = rbObj.getObjectName();
		modelDesc = parent.getRawAttributeAsUtf8("Description");
		modelComp = parent.getStringAttribute("Company");
		Date dt = (Date) rbObj.getAttribute("CreatedDate")[0];
		createdDt = df.format(dt);
		
		bShowModelOnly = (rbObj == parent);				// showing the robot model
		if (bShowModelOnly) disabledStr = "disabled";
		else if (isReadOnly) disabledStr = "disabled";	// readOnly can't change cloned robot
	
		// robot XML
		int idx;
		
		// check to see if user has selected a Robot name already
		// If so, get the info from XML file
		String xml = rbObj.getRawAttributeAsUtf8("Content");
		//System.out.println("xml=" + xml);
		
		if (xml != null) {
			if (xml.indexOf('&')!=-1 && xml.indexOf("&amp;")==-1) {
				// Document parser can't take && or < signs
				xml = xml.replaceAll("&", "&amp;");		// escape & sign in the condition expression &\\s+
				xml = xml.replaceAll("<=", "&lt;&#61;");
			}
			DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
			DocumentBuilder builder = factory.newDocumentBuilder();
			InputSource is = new InputSource(new StringReader(xml));
			Document document = builder.parse(is);
			
			
			Element root = document.getDocumentElement();
			s = XML.getXMLString(TAG_ORGNAME, root);
	
			if (!s.startsWith(modelName)) {
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
				s = s.replaceAll("&amp;", "&");
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
	}	// END if: bCreateModel
	
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
var totalXmlNodes = 0 + <%=totalNodesInXML%>;
var totalCloned = 0 + <%=totalRobotCloned%>;
var selectIndex = 0 + <%=selectIdx%>;
var isReadOnly = <%=isReadOnly%>;

window.onload = function()
{
	if ("<%=dispHTML%>" != "") {
		var e = document.getElementById("piccontainer");
		e.innerHTML = "<%=dispHTML%>";
		if (e.style.display == 'none') {
			e.style.display = 'block';
		}
	}
}

function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

// for Save or Submit
function validation(bSaveOnly)
{
	if (bSaveOnly && isReadOnly) {
		alert("<%=READ_ONLY_ALERT_STR%>");
		return;
	}
	
	var val = goRobotForm.cloneBotName.value.trim();
	if (val == '')
	{
		fixElement(goRobotForm.cloneBotName,
			"Please make sure to assign a name to the Robot.");
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
	
	goRobotForm.selectIdx.value = selectIndex;

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
	if (isReadOnly) {
		alert("<%=READ_ONLY_ALERT_STR%>");
		return;
	}
	var tabl = document.getElementById("nodeTable");
	var lnkRow = document.getElementById("newLink");
	var len = tabl.rows.length;
	var aRow = tabl.rows[0].cloneNode(true);
	var nodeId = 'Node' + len;
	var authId = 'Auth' + len;
	aRow.cells[0].innerHTML = "<span class='plaintext_bold'><img src='../i/spacer.gif' width='15' height='20'/>"
			+ "Node " + len + "</span>";
	aRow.cells[1].innerHTML = "<input type='text' id='"
		+ nodeId + "' name='" + nodeId + "' value='Enter node-OMM-URL' "
		+ "class='formtext' style='width:300px;'/>&nbsp;"
		+ "<input type='password' id='"
		+ authId + "' name='" + authId + "' value='password' "
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

// use Ajax to clone from a robot model
function cloneBots()
{
	if (isReadOnly) {
		alert("<%=READ_ONLY_ALERT_STR%>");
		return;
	}
	
	// call Ajax and will callback to doneCloneBots() below
	ajaxClone("<%=modelName%>");
}

// called by callback function
function doneCloneBots(newBotName, botImgSrc)
{
	changeSelected(totalCloned);
}

function changeSelected(selIdx)
{
	var url = window.location.href;
	idx = url.indexOf("&idx=");
	if (idx != -1)
		url = url.substring(0, idx);
	location = url + '&idx=' + selIdx + "#clone";
}

function delBot()
{
	if (confirm("Are you sure you want to RECYCLE the robot?")) {
		location = "post_ommBots.jsp?del=<%=selectedBotId%>";
	}
}

function showChangeBotPanel(b)
{
	var e = document.getElementById("chgBot");
	if (b)
		e.style.display = 'block';
	else
		e.style.display = 'none';
}

function changeBot(i)
{
	showChangeBotPanel(false);
	location = "post_ommBots.jsp?chi=" + i + "&id=<%=selectedBotId%>"
				+ "&idx=<%=selectIdx%>";
}
//-->
</script>

<title>
	Omm Robots
</title>

</head>


<body bgcolor="#FFFFFF" >

<div class='wrapper'><div id='chgBot' class='bot-icons'><%=STR_BOTICONS%></div></div>

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
<form method="post" name="goRobotForm" action="post_ommBots.jsp">
<input type='hidden' name='SaveOnly' value='' />
<input type='hidden' name='TotalXmlNodes' value='' />
<input type='hidden' name='XmlNodesOnPage' value='' />
<input type='hidden' name='cloneId' value='<%=selectedBotId%>' />
<input type='hidden' name='selectIdx' value='' />
<input type='hidden' name='isReadOnly' value='<%=isReadOnly%>' />

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

<%	if (!bCreateModel) { %>
<!-- Model Name -->
	<tr>
		<td><img src='../i/spacer.gif' width='15' height='1'/></td>
		<td width='210' class="plaintext_head_blue" valign='top'>Robot Model</td>
		<td class='plaintext_big2'><b><%=modelName %></b>
			&nbsp;&nbsp;&nbsp; <%=modelDispName %>
		</td>
		
		<!-- buttons -->
		<td><img src='../i/spacer.gif' width='20'/></td>
		<td><button type='button' class='button_medium' onclick='cloneBots();'>Clone</button></td>
		<td align='right' valign='bottom' width='90'>
			<input type="button" value="Back" onclick="location='listBots.jsp';" class='button_medium'/>
		</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='5'/></td></tr>
	
<!-- Model Description -->
	<tr>
		<td colspan='2'><a name='clone'></a></td>
		<td><table><tr>
			<td><img src='../i/spacer.gif' width='10'/></td>
			<td class='plaintext_big' width='700'><%=modelDesc %></td>
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


<% if (!bShowModelOnly || bCreateModel) {
	// show the cloned robot name
%>
<!-- Robot Info -->
	<tr>
		<td></td>
		<td class="plaintext_head_blue">Robot <%=modelStr%> Information</td>
		<td>
		</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='10'/></td></tr>

<%	if (!bCreateModel) { %>	
	<tr>
		<td></td>
		<td class="plaintext_bold"><img src='../i/spacer.gif' width='10' height='1'/>
			Robot ID</td>
		<td class='plaintext_blue'><%=botName%>-<%=selectedBotId%></td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='5'/></td></tr>
<%	} %>

	<tr>
		<td></td>
		<td class="plaintext_bold"><img src='../i/spacer.gif' width='10' height='1'/>
			Robot <%=modelStr%> Name
		</td>
		<td>
			<input type="text" name="cloneBotName" class='formtext' style='width:500px;'
					value='<%=cloneDispName%>'  <%=disabledStr%>/>
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
		
<%	if (!bCreateModel) { %>	
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


<!-- Learning Sample -->
	<tr>
		<td></td>
		<td class="plaintext_head_blue">Learning Sample</td>
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


<!-- Pricing -->
<%	if (bCreateModel) { %>
	<tr>
		<td></td>
		<td class="plaintext_head_blue">Pricing</td>
		<td>
		</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='10'/></td></tr>
	
	<tr>
		<td></td>
		<td class="plaintext_bold"><img src='../i/spacer.gif' width='10' height='1'/>
			Currency / Price / Period
		</td>
		<td>
			<select class='formtext' name="Currency" style='width:170px;' <%=disabledStr%>>
			<option value="">- select currency -</option>
			<option value='1'>AUD</option>
			<option value='2'>EUR</option>
			<option value='3'>GBP</option>
			<option value='4'>HKD</option>
			<option value='5'>RMB</option>
			<option value='6'>SGD</option>
			<option value='7'>USD</option>
			</select>
			<input type="text" name="Price" class='formtext' style='width:150px;'  value='' <%=disabledStr%>/>&nbsp;
			<select class='formtext' name="LicenseDue" style='width:170px;' <%=disabledStr%>>
			<option value="">- select license period -</option>
			<option value=''>Perpetual</option>
			<option value=''>Annual</option>
			<option value=''>Monthly</option>
			<option value=''>Per Execution</option>
			</select>
		</td>
	</tr>

	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='10'/></td></tr>
	
<%	} %>

<%if (!bShowModelOnly && !bCreateModel) { %>
<!-- Domains -->
	<tr>
		<td></td>
		<td class="plaintext_head_blue">Domains</td>
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
			out.print("<td width='210' class='plaintext_bold'><img src='../i/spacer.gif' width='15' height='20'/>");
			out.print("Node " + (i+1));
			out.print("</td>");
			
			out.print("<td><input type='text' name='Node" + (i+1)
					+ "' id='" + "Node" + (i+1)
					+ "' value='" + nodeList.get(i) + "' "
					+ disabledStr
					+ " class='formtext' style='width:325px;' />&nbsp;");
			out.print("<input type='password'"
					+ " onfocus='showPswd(" + (i+1) + ",true);' name='Auth" + (i+1)
					+ "' onfocusout='showPswd(" + (i+1) + ",false);'"
					+ "' id='" + "Auth" + (i+1)
					+ "' value='" + authStr + "' "
					+ disabledStr
					+ " class='formtext' style='width:170px;' />");
			out.print("</td>");
			out.print("</tr>");
		}
		
		
		// add new node
		out.print("<tr id='newLink'><td width='210'>&nbsp;</td>");
		out.print("<td><a href='javascript:addNewNode();' class='plaintext_big'>Add new node</a></td>");
		out.print("</tr>");
		
		out.print("</table></td>");
		out.print("</tr>");				// -->

}%>


	
	<tr><td colspan='3'><img src='../i/spacer.gif' width='1' height='20'/></td></tr>


<!-- Submit Button -->
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan='4' align="right"><br/>
<% if (!bShowModelOnly || bCreateModel) { %>
			<input type="button" value="   Save   " class='button_medium' onclick='return validation(true);'/>&nbsp;
<% if (!bCreateModel) { %>
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

