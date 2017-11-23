<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>

<%
	//
	//	Copyright (c) 2014, EGI Technologies, Inc.  All rights reserved.
	//
	/////////////////////////////////////////////////////////////////////
	//
	//	File: bug_updall.jsp
	//	Author: ECC
	//	Date:	04/09/14 (not done)
	//	Description: Allow project coordinator to update selected fields of bugs (service request).
	//
	//	Modification:
	//
	/////////////////////////////////////////////////////////////////////
	//
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.omm.common.*" %>
<%@ page import = "oct.omm.client.*" %>
<%@ page import = "oct.omm.db.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "util.JwTask" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>

<%
	String projIdS = request.getParameter("projId");
	String noSession = "../out.jsp?go=project/action_updall.jsp?projId="
			+ projIdS;
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%
	////////////////////////////////////////////////////////

	// copy from bug_update.jsp
	final String[] CAT2 = { "ABS", "CIS", "HIS", "CSS", "LIS", "PACS",
			"NIS", "HRP", "ORION", "Dictionary", "Workflow", "Others" };
	final String[] USER_DEPT = { "药剂科", "收费处", "门诊医生", "门诊护士", "住院医生",
			"住院护士", "影像科", "病理科", "院感科", "体检科" };
	final String[] PROCESS_TYPE = { "门诊挂号", "门诊收费", "收费报表", "分诊",
			"叫号屏显示", "处方打印", "手术申请", "入院登记", "住院结算", "医嘱处理", "电子病历",
			"执行单", "药品提交", "门诊发药", "住院发药", "药品字典界面", "医保相关", "出入库",
			"库存管理" };

	final String P0 = "P0 - 系统瘫痪";
	final String P1 = "P1 - 病人安全";
	final String P2 = "P2 - 收费问题";
	final String P3 = "P3 - 政策要求";
	final String P4 = "P4 - 工作效率";
	final String[] P = { P0, P1, P2, P3, P4 };

	String[] CATEGORY;
	CATEGORY = CAT2;
	/////////////////////////////

	if (pstuser instanceof PstGuest || projIdS == null) {
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}

	int myUid = pstuser.getObjectId();
	boolean isAdmin = false;
	int iRole = ((Integer) session.getAttribute("role")).intValue();
	if (iRole > 0) {
		if ((iRole & user.iROLE_ADMIN) > 0)
			isAdmin = true;
	}

	projectManager pjMgr = projectManager.getInstance();
	userManager uMgr = userManager.getInstance();
	bugManager bMgr = bugManager.getInstance();

	String s;
	String projName = null;
	project projObj = null;
	if (projIdS.length() == 0) {
		projName = (String) session.getAttribute("projName"); // the case when projId is removed from an issue
		projObj = (project) pjMgr.get(pstuser, projName);
		projIdS = String.valueOf(projObj.getObjectId());
	} else {
		projName = PstManager.getNameById(pstuser,
				Integer.parseInt(projIdS));
		projObj = (project) pjMgr.get(pstuser, projName);
	}
	projName = projObj.getDisplayName();

	String coordinatorIdS = (String) projObj.getAttribute("Owner")[0];
	int coordinatorId = Integer.parseInt(coordinatorIdS);

	SimpleDateFormat df1 = new SimpleDateFormat("MM/dd/yy");
	SimpleDateFormat df3 = new SimpleDateFormat("MM/dd/yyyy");
	String todayS = df1.format(new Date());

	////////////////////////////////////////////////////////
%>


<head>
<title>Project Items</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../forms.jsp" flush="true"/>
<script language="JavaScript" src="../get-date.js"></script>

<script type="text/javascript">

<!--

function checkUpdate(e)
{
	e.checked = true;
}

function goBack()
{
	location = "bug_search.jsp?projId=<%=projIdS%>";
}
//-->
</script>

</head>

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

					<tr><td colspan="2">&nbsp;</td></tr>
					<tr>
					<td></td>
					<td>
						<b class="head">Update Change Requests</b>
					</td></tr>

					<tr>
					<td></td>
					<td valign="top" class="title">
						&nbsp;&nbsp;&nbsp;<%=projName%>
					</td>
					</tr>

	              <tr>
	                <td width="20">&nbsp;</td>
	                <td width="754">&nbsp;</td>
	              </tr>
	            </table>

	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>
	          </td>
	        </tr>

<!-- Navigation SUB-Menu -->
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
<td width="100%" valign="top">

	<table border="0" width="100%" height="14" cellspacing="0" cellpadding="0">
		<tr>
			<td bgcolor='#EBECED'><img src='../i/spacer.gif' width='10' height='1'/></td>
			<td valign="top" class="bgsubnav">
				<table border="0" cellspacing="0" cellpadding="0">
				<tr class="bgsubnav">
	<!-- Change Request Summary -->
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="../project/proj_action.jsp?projId=<%=projIdS%>" class="subnav">Change Request Summary</a></td>
					<td colspan="3" width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- Update All -->
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="20" height="14"><img src="../i/nav_arrow.gif" width="20" height="14" border="0"></td>
					<td><a href="#" onClick="return false;" class="subnav"><u>Update All</u></a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
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

<!-- Content Table -->

<table width="90%" border="0" cellspacing="0" cellpadding="0">


<tr>
	<td width="20">&nbsp;</td>
	<td colspan="2"></td>
</tr>

<!-- *************************   Page Headers   ************************* -->


<!-- //////////////////////////////////////////////////// -->

<!-- LIST OF Change Requests -->
<form method="post" name="updAllBug" action="post_updAllBug.jsp">
<input type="hidden" name="projId" value="<%=projIdS%>">

<%
	// for Action Item, Decision Records and Issues
	int[] ids;

	// get the list of bugs
	s = (String) session.getAttribute("expr");	// can be null
	ids = bMgr.findId(pstuser, s);
	Arrays.sort(ids);
	PstAbstractObject[] bugObjList = bMgr.get(pstuser, ids);

	// variables
	String bgcolor = "";
	boolean even;

	String ownerIdS, midS, bugIdS, synopsis, category, type, processType, userDepartment, due;
	boolean bHasProcessType = true; // OMM DB contains this def
	boolean bHasUserDepartment = true; // OMM DB contains this def
	user uObj;
	int bid, len;
	bug bugObj;
%>


<tr><td colspan="3"><a name="action">
	<img src="../i/spacer.gif" width="5" height="5"></a></td></tr>

<tr>
	<td>&nbsp;</td>
	<td colspan='2'>
	<table border="0" cellspacing="0" cellpadding="0">
		<tr>
			<td>
			<input type='button' class='button_medium' value='Submit' onclick='updAllBug.submit();'/>
			<img src='../i/spacer.gif' width='20' />
			<input type='button' class='button_medium' value='Cancel' onclick='goBack();'/>
			</td>
		</tr>

		<tr><td colspan='2' height="10"><img src="../i/spacer.gif" height="10" width="1" alt=" " /></td></tr>
	</table>
	</td>
</tr>


<!-- List of bugs -->
<%
	String status;
	int ownerId;
	boolean found;

	if (bugObjList.length > 0) {
%>
<tr>
	<td>&nbsp;</td>
	<td colspan="2">
		<table width="100%" border='0' cellpadding="0" cellspacing="0">
		<tr>
		<td bgcolor="#EBECED" height="3"><img src="../i/spacer.gif" width="1" height="3" border="0"></td>
		</tr>
		</table>

		<table width="100%" border="0" cellspacing="0" cellpadding="0">
		<tr>
		<td colspan="14" height="2" bgcolor="#336699"><img src="../i/spacer.gif" width="2" height="2"></td>
		</tr>

		<tr>
		<td width="3" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td width="30" bgcolor="#6699cc" class="td_header" align="center"><strong>Update</strong></td>

		<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
		<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td width="20" bgcolor="#6699cc" class="td_header" align="center"><strong>CR#</strong></td>

		<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
		<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td bgcolor="#6699cc" class="td_header"><strong>&nbsp;Synopsis</strong></td>

		<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
		<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td width="65" bgcolor="#6699cc" class="td_header" align="center"><strong>Category</strong></td>

		<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
		<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td width="65" bgcolor="#6699cc" class="td_header" align="center"><strong>Type</strong></td>

		<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
		<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td width="65" bgcolor="#6699cc" class="td_header" align="center"><strong>Process Type</strong></td>

		<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
		<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td width="65" bgcolor="#6699cc" class="td_header" align="center"><strong>Dept Name</strong></td>

		<td width="2" bgcolor="#FFFFFF" class="10ptype"><img src="../i/spacer.gif" width="2" height="2"></td>
		<td width="4" bgcolor="#6699cc" class="10ptype">&nbsp;</td>
		<td width="65" bgcolor="#6699cc" class="td_header" align="center"><strong>Due</strong></td>

		</tr>

<%
	even = false;

		for (int i = 0; i < bugObjList.length; i++) { // the list of action item for this meeting object
			bugObj = (bug) bugObjList[i];
			bid = bugObj.getObjectId();

			ownerIdS = (String) bugObj.getAttribute("Owner")[0];
			ownerId = Integer.parseInt(ownerIdS);
			synopsis = (String) bugObj.getAttribute("Synopsis")[0];
			category = (String) bugObj.getAttribute("Category")[0];
			type = (String) bugObj.getAttribute("Type")[0];

			try {
				processType = (String) bugObj
						.getAttribute("ProcessType")[0];
			} catch (PmpException e) {
				bHasProcessType = false;
			}

			try {
				userDepartment = (String) bugObj
						.getAttribute("DepartmentName")[0];
			} catch (PmpException e) {
				bHasUserDepartment = false;
			}

			due = (String) bugObj.getAttribute("Release")[0];

			if (even)
				bgcolor = "bgcolor='#EEEEEE'";
			else
				bgcolor = "bgcolor='#ffffff'";
			even = !even;
			out.print("<tr " + bgcolor + ">");

			// update checkbox
			out.print("<td></td>");
			out.print("<td height='23' width='30' align='center'>");
			out.print("<input type='checkbox' name='update_" + bid
					+ "'>");
			out.println("</td>");

			// CR#
			out.print("<td colspan='2'></td><td width='65' align='center'>");
			out.print(bid);
			out.println("</td>");

			// Synopsis
			out.print("<td colspan='2'>&nbsp;</td>");
			out.print("<td valign='top'><table border='0'><tr>");
			out.print("<td class='ptextS2' valign='top' width='20'>"
					+ (i + 1) + ".</td>");
			out.print("<td class='ptextS2' valign='top'>");
			out.print(synopsis);
			out.println("</td></tr></table></td>");

			// category
			out.print("<td colspan='2'></td><td width='72' align='center'>");
			out.println("<select class='formtext' name='category'>");
			out.print("<option value=''>- select category -</option>");

			for (int j = 0; j < CATEGORY.length; j++) {
				out.print("<option value='" + CATEGORY[j] + "'");

				if (CATEGORY[j].equals(category))
					out.print(" selected");
				out.println(">" + CATEGORY[j] + "</option>");
			}
			out.println("</select>");
			out.println("</td>");

			// processType
			if (bHasProcessType) {
				out.print("<td colspan='2'></td><td width='72' align='center'>");
				out.println("<select class='formtext' name='processType'>");
				out.print("<option value=''>- select process type -</option>");
				for (int j = 0; j < PROCESS_TYPE.length; j++) {
					out.print("<option value='" + PROCESS_TYPE[j] + "'");

					if (PROCESS_TYPE[j].equals(processType))
						out.print(" selected");
					out.println(">" + PROCESS_TYPE[j] + "</option>");
				}
				out.println("</select>");
				out.println("</td>");
			}

			// userDepartment
			if (bHasUserDepartment) {
				out.print("<td colspan='2'></td><td width='72' align='center'>");
				out.println("<select class='formtext' name='userDept'>");
				out.print("<option value=''>- select user department -</option>");
				for (int j = 0; j < USER_DEPT.length; j++) {
					out.print("<option value='" + USER_DEPT[j] + "'");

					if (USER_DEPT[j].equals(userDepartment))
						out.print(" selected");
					out.println(">" + USER_DEPT[j] + "</option>");
				}
				out.println("</select>");
				out.println("</td>");

				out.println("</tr>");
				out.println("<tr "
						+ bgcolor
						+ ">"
						+ "<td colspan='14'><img src='../i/spacer.gif' width='2' height='2'></td></tr>");
			}
		}
%>
		</table>
	</td>
</tr>
<!-- End list of action items -->

<tr><td colspan="3"><img src="../i/spacer.gif" width="5" height="5"></td></tr>
<%
	} // END: if bugObjList > 0
%>


<tr>
	<td>&nbsp;</td>
	<td colspan='2'>
	<table border="0" cellspacing="0" cellpadding="0">
		<tr><td colspan='2' height="10"><img src="../i/spacer.gif" height="10" width="1" alt=" " /></td></tr>

		<tr>
		<td height="23">
			<input type='button' class='button_medium' value='Submit' onclick='updAllBug.submit();'/>
			<img src='../i/spacer.gif' width='20' />
			<input type='button' class='button_medium' value='Cancel' onclick='goBack();'/>
		</td>
		</tr>

	</table>
	</td>
</tr>

</form>

<tr><td colspan="3"><img src="../i/spacer.gif" width="5" height="10"></td></tr>


<!-- END LIST OF ACTION / DECISION / ISSUE -->


</table>


		<!-- End of Content Table -->
		<!-- End of Main Tables -->
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
