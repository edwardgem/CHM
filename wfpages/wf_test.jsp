<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>

<%
////////////////////////////////////////////////////
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	wf_test.jsp
//	Author:	ECC
//	Date:	06/26/16
//	Description:
//		Test the lifecycle of workflow.
//
//	Modification:
//
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>


<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp?go=wfpages/wf_test.jsp" />


<%!
	SimpleDateFormat df = new SimpleDateFormat("MM-dd-yyyy [HH:mm:ss]");


	// return an HTML string for String attribute value
	String printStringAttr(PstAbstractObject obj, String attrName, String colorStr)
		throws PmpException
	{
		String s = obj.getStringAttribute(attrName);
		if (s == null) s = "-";
		
		StringBuffer sBuf = new StringBuffer();
		sBuf.append("<tr><td></td>");
		sBuf.append("<td class='ptextS2G' width='200'>"+ attrName + "</td>");
		
		sBuf.append("<td class='ptextS2'>");
		if (colorStr != null)
			sBuf.append("<font color='" + colorStr + "'>" + s + "</font>");
		else
			sBuf.append(s);
		sBuf.append("</td></tr>");
		
		return sBuf.toString();
	}

	String printStringAttr(PstAbstractObject obj, String attrName)
		throws PmpException
	{
		return printStringAttr(obj, attrName, null);
	}

	String printIntAttr(PstAbstractObject obj, String attrName)
		throws PmpException
	{
		int i = obj.getIntAttribute(attrName);
		
		StringBuffer sBuf = new StringBuffer();
		sBuf.append("<tr><td></td>");
		sBuf.append("<td class='ptextS2G' width='200'>" + attrName + "</td>");
		sBuf.append("<td class='ptextS2'>" + i + "</td></tr>");
		
		return sBuf.toString();
	}
	
	String printAttrLink(PstUserAbstractObject uObj, PstAbstractObject obj, String attrName, int orgId)
			throws PmpException
	{
		
		String s = obj.getStringAttribute("FlowDataInstance");
		
		StringBuffer sBuf = new StringBuffer();
		sBuf.append("<tr><td></td>");
		sBuf.append("<td class='ptextS2G' width='200'>FlowDataInstance</td>");
		sBuf.append("<td class='ptextS2'>");
		
		if (s != null) {
			int objId = PstManager.getIdByName(uObj, orgId, s);
			sBuf.append("<a target='_blank' href='../../ommtool/dispmem.jsp?memid="
				+ objId + "'>" + s + "</a>");
		}
		else
			sBuf.append("-");
		
		sBuf.append("</td></tr>");

		return sBuf.toString();
	}


	// return an HTML string for Date attribute value
	String printDateAttr(PstAbstractObject obj, String attrName)
		throws PmpException
	{
		String s;
		Date dt = (Date) obj.getAttribute(attrName)[0];
		if (dt == null) s = "-";
		else {
			s = df.format(dt);
		}
		
		StringBuffer sBuf = new StringBuffer();
		sBuf.append("<tr><td></td>");
		sBuf.append("<td class='ptextS2G' width='200'>" + attrName + "</td>");
		sBuf.append("<td class='ptextS2'>" + s + "</td></tr>");
		
		return sBuf.toString();
	}

%>


<%
	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}

	PstFlowDefManager fDefMgr = PstFlowDefManager.getInstance();
	PstFlowManager fInstMgr = PstFlowManager.getInstance();
	PstFlowStepManager fStepInstMgr = PstFlowStepManager.getInstance();
	PstFlowDataObjectManager fDataMgr = PstFlowDataObjectManager.getInstance();
	
	PstAbstractObject o=null;
	String s;

	
	// get parameters for operations
	boolean bFlowDefClick   = false;
	boolean bFlowInstClick  = false;
	
	// flow definition chosen
	// display all instances of this flow definition
	String flowDefIdS = request.getParameter("fDefId");
	int flowDefId = 0;
	PstAbstractObject fDefObj = null;
	String flowDefName = null;
			
	if (!StringUtil.isNullOrEmptyString(flowDefIdS)) {
		flowDefId = Integer.parseInt(flowDefIdS);
		fDefObj = fDefMgr.get(pstuser, flowDefId);
		flowDefName = fDefObj.getObjectName();
		bFlowDefClick = true;
	}
	
	// flow instance chosen
	// display all created steps of this flow instance
	String flowInstIdS = request.getParameter("fInstId");
	int flowInstId = 0;
	PstAbstractObject fInstObj = null;
	
	if (!StringUtil.isNullOrEmptyString(flowInstIdS)) {
		flowInstId = Integer.parseInt(flowInstIdS);
		fInstObj = fInstMgr.get(pstuser, flowInstId);
		bFlowDefClick  = false;				// if Instance is clicked reset this to false
		bFlowInstClick = true;
		
		if (StringUtil.isNullOrEmptyString(flowDefIdS)) {
			flowDefName = fInstObj.getStringAttribute("FlowName");
			flowDefIdS = String.valueOf(PstManager.getIdByName(pstuser, 3, flowDefName));
		}
	}
	
	
	// actions
	
	/////////////////////////////////
	// start a flow instance
	String startFlowName = request.getParameter("st");
	String doName = startFlowName + "-" + new Date().getTime();
	PstFlow newFlow = null;
	
	if (!StringUtil.isNullOrEmptyString(startFlowName)) {
		newFlow = WfThread.startFlow(pstuser, startFlowName, doName);		// sync call
		
		// refresh with this flow instance chosen
		response.sendRedirect("wf_test.jsp?fDefId=" + flowDefIdS + "&fInstId=" + newFlow.getObjectId());
		return;
	}
	
	/////////////////////////////////
	// delete flow instance
	String delFlowInstIdS = request.getParameter("delFlowInst");
	
	if (!StringUtil.isNullOrEmptyString(delFlowInstIdS)) {
		o = fInstMgr.get(pstuser, delFlowInstIdS);
		fInstMgr.deleteAll((PstFlow) o);
		
		response.sendRedirect("wf_test.jsp?fDefId=" + flowDefIdS);
		return;
	}
	
	/////////////////////////////////
	// commit step
	String commitStepIdS = request.getParameter("cmtStep");
	
	if (!StringUtil.isNullOrEmptyString(commitStepIdS)) {
		PstFlowStep stObj = (PstFlowStep) fStepInstMgr.get(pstuser, commitStepIdS);
		o = fDataMgr.get(pstuser, stObj.getStringAttribute("FlowDataInstance"));
		stObj.commitStep(pstuser, (PstFlowDataObject) o);
		
		// select the flow instance to show
		flowInstIdS = stObj.getStringAttribute("FlowInstanceName");
		response.sendRedirect("wf_test.jsp?fDefId=" + flowDefIdS + "&fInstId=" + flowInstIdS);
		return;
	}
	
	

%>


<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>

<script language="JavaScript">
<!--
function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

function validation()
{
	if (document.NewForm.ProjName.value =='')
	{
		fixElement(document.NewForm.ProjName,
			"Please make sure that the PROJECT NAME field is properly completed.");
		return false;
	}
	return;
}

function commitStep(stepId)
{
	location = "wf_test.jsp?cmtStep=" + stepId;
}

//-->
</script>

<title>
	CPM Workflow
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
	<td width='10'>&nbsp;</td>
	<td class="head">
		<a href='wf_test.jsp' class='head'>Workflow Tester</a>
	</td></tr>

	</table>

	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- CONTENT -->
<form method="post" name="testForm" action="">
<table width='95%'>

	<tr><td colspan='3'><img src='../i/spacer.gif' height='20' /></td></tr>

<!-- flow definition -->
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="instruction_head">Flow Name</td>
	</tr>

<%
	int [] ids = fDefMgr.findId(pstuser, "om_acctname='%'");

	out.print("<tr><td></td><td colspan='2'><table>");

	// list all flow definition names
	String thisName;
	for (int i=0; i<ids.length; i++) {
		o = fDefMgr.get(pstuser, ids[i]);
		thisName = o.getObjectName();
		
		out.print("<tr>");
		if (ids[i] == flowDefId)
			out.print("<td><img src='../i/tri.gif' border='0' width='10'/></td>");
		else
			out.print("<td></td>");
		out.print("<td class='ptextS2' width='290'><a href='?fDefId=" + ids[i] + "'>"
					+ thisName
					+ "</a></td>");
		out.print("<td class='ptextS2'><a href='?st=" + thisName
					+ "&fDefId=" + ids[i] + "'>Start</a></td>");
		out.print("</tr>");
	}
	out.print("</table></td></tr>");
	
	out.print("<tr><td colspan='3'><img src='../i/spacer.gif' height='20' /></td></tr>");
%>

<%
	/////////////////////////////////////////////////////////////////////////
	// Either a flow definition is clicked or a flow instance is clicked
	
	if (flowDefName != null) {
%>
<!-- flow Instance -->
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="instruction_head">
			Flow Instance <span class='ptextS2'>of <%=flowDefName%></span>
		</td>
	</tr>

<%
	
	// list all flow instances of the clicked flow defintion
	out.print("<tr><td></td><td colspan='2'><table>");
	
	ids = fInstMgr.findId(pstuser, "FlowName='" + flowDefName + "'");
	String uname, dtS, st;
	Date dt;

	for (int i=0; i<ids.length; i++) {
		
		// if a flow instance is clicked, just show that one instance
		if (bFlowInstClick && flowInstId!=ids[i])
			continue;
		
		o = fInstMgr.get(pstuser, ids[i]);
		out.print("<tr>");
		
		if (bFlowInstClick)
			out.print("<td><img src='../i/tri.gif' border='0' width='10'/></td>");

		out.print("<td class='ptextS2' width='100'>"
					+ "<a href='?fInstId=" + ids[i] + "&fDefId=" + flowDefIdS + "'>"
					+ o.getObjectName() + "</a></td>");
		
		// creator
		uname = o.getStringAttribute("Owner");
		if (StringUtil.isNullOrEmptyString(uname))
			uname = "-";
		out.print("<td class='ptextS2' width='200'>created by " + uname + "</td>");
		
		// date
		dt = (Date) o.getAttribute("CreatedDate")[0];
		if (dt != null)
			dtS = df.format(dt);
		else
			dtS = "-";
		out.print("<td class='ptextS2' width='250'>" + dtS + "</td>");
		
		// state
		st = o.getStringAttribute("State");
		out.print("<td class='ptextS2' width='150'><font color='blue'>" + st + "</font></td>");
		
		// delete flow instance
		out.print("<td class='ptextS2' width='150'><a href='?delFlowInst="
			+ ids[i] + "&fDefId=" + flowDefIdS + "'>Delete" + "</a></td>");
		
		out.print("</tr>");
	}	// END for each flow instance
	
	// if flow instance is clicked, also show flow data
	if (bFlowInstClick) {
		out.print("<tr>");
		out.print(printAttrLink(pstuser, o, "FlowDataInstance", 2));	// step data object
		out.print("</tr>");
	}
	
	out.print("</table></td></tr>");
	

	
	////////////////////////////////////////////////////////////////////////////////////
	// flow instance is clicked
	PstAbstractObject dtObj;
			
	if (bFlowInstClick) {

		// display the steps belonging to this flow instance
		out.print("<tr><td></td><td colspan='2'><table>");
		out.print("<tr><td width='20'>&nbsp;</td><td></td><td></td></tr>");	// format

		ids = fStepInstMgr.findId(pstuser, "FlowInstanceName='" + flowInstIdS + "'");
		Arrays.sort(ids);
		
		// list the steps of the flow instance
		for (int i=0; i<ids.length; i++) {
			o = fStepInstMgr.get(pstuser, ids[i]);

			// step ID
			out.print("<tr><td class='ptextS2' colspan='3'>" + (i+1) + ".&nbsp;&nbsp;Step ID: "
					+ "<a target='_blank' href='../../ommtool/dispmem.jsp?memid=" + ids[i] + "'>"
					+ ids[i] + "</a></td></tr>");
			
			// attributes
			out.print(printStringAttr(o, "FlowStepDefName"));
			out.print(printStringAttr(o, "DisplayName"));
			out.print(printIntAttr(o, "TokenCount"));
			out.print(printStringAttr(o, "IncomingStepInstance"));
			out.print(printStringAttr(o, "OutgoingStepInstance"));
			
			out.print(printAttrLink(pstuser, o, "FlowDataInstance", 2));	// step data object
			
			out.print(printStringAttr(o, "Application"));
			out.print(printStringAttr(o, "Owner"));
			out.print(printDateAttr(o, "CreatedDate"));
			out.print(printStringAttr(o, "CurrentExecutor"));
			out.print(printStringAttr(o, "State", "blue"));
			
			st = o.getStringAttribute("State");
			if (st!=null && st.equals(PstFlowConstant.ST_STEP_ACTIVE)) {
				out.print("<tr><td></td><td></td><td>");
				out.print("<input type='button' value='Commit Step' onclick='commitStep("
					+ ids[i] + ");' /></td></tr>");
			}
			
			// partition
			out.print("<tr><td colspan='3'><img src='../i/spacer.gif' height='20'/></td></tr>");

		}	// END for each step instance
		
		out.print("</table></td></tr>");

	}

	
}	// END IF flowDefName!=null
%>



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

