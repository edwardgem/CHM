<%@ page language="java" pageEncoding="utf-8"%>
<%
	////////////////////////////////////////////////////
	//
	//	File:	requestPC.jsp
	//	Author:	
	//	Date:
	//	Description:
	//		main form for request PC.
	//
	////////////////////////////////////////////////////////////////////
request.setCharacterEncoding("utf-8");//perry
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<%@ page import="util.*"%>
<%@ page import="oct.codegen.*"%>
<%@ page import="oct.pst.*"%>
<%@ page import="oct.pmp.exception.*"%>
<%@ page import="java.util.*"%>
<%@ page import="java.io.*"%>
<%@ page import="java.text.*"%>

<%@ taglib uri="/pmp-taglib" prefix="pmp"%>
<pmp:useUser id="pstuser" noSessionUrl="./login.jsp" />
<%!

	// op code
	final int WF_OP_HARDWARE_REQ = 101;
	final int WF_OP_DEPT_GM_APPROVE = 102;
	final int WF_OP_ADMIN_GM_APPROVE = 103;
	final int WF_OP_IT_GM_APPROVE = 104;
	final int WF_OP_IT_HANDLE_INFORM = 105;

	// comment type
	final int COMMENT_DEPT		= 0;
	final int COMMENT_ADMIN		= 1;
	final int COMMENT_IT		= 2;
	final int COMMENT_HANDLE	= 3;
	
	String getComment(PstFlowDataObject flowDataObj, int iType)
		throws Exception
	{
		String com = null;
		Object rawData = flowDataObj.getAttribute("raw1")[0];
		if (rawData != null) {
			com = new String ((byte []) rawData, "utf-8");
		}
		if (StringUtil.isNullOrEmptyString(com)) return "";
		String retComment = "";
		
		// based on type to extract data
		// 1-dept; 2-admin; 3-it (use @@ as terminator)
		String [] sa = com.split("@@");
		String [] comArr = {"", "", "", ""};
		for (int i=0; i<sa.length; i++) {
			comArr[i] = sa[i];
		}
		retComment = comArr[iType];
		return retComment;
	}
%>

<script type="text/javascript">
<!--
function approve(shenpi)
{
	// approve this step
	reqForm.status.value = "commit";
	reqForm.submit();
	//if(shenpi==1){window.opener.location.reload();}	//By Perry 	
}

function reject()
{
	// abort the flow
	reqForm.status.value = "abort";
	reqForm.submit();
}

function save()
{
	// save the current comments if any
	reqForm.status.value = "save";
	reqForm.submit();
}

function resubmitReq(equipmentList)
{
	// approve this step
	// !!!Perry: here can you help to extract the equipment list and
	// pass it to post_requestPC.jsp?
	reqForm.status.value = "resubmit";
	reqForm.op.value = "<%=WF_OP_HARDWARE_REQ%>";
	reqForm.equipList.value = equipmentList;
	reqForm.stepName.value = "";
	reqForm.resubmit.value = "true";
	reqForm.submit();
}

function closeWin()
{
	// close this window
	self.close();
}

//-->
</script>


<%
	
	int myUid = pstuser.getObjectId();

	String op = request.getParameter("op");
	int opCode = 0;
//By Perry:Check the user profile if it's empty.
	String lastName = pstuser.getStringAttribute("LastName");
	String firstName = pstuser.getStringAttribute("FirstName");
	String email = pstuser.getStringAttribute("Email");
	String my_dept = pstuser.getStringAttribute("DepartmentName");
	if (lastName == null) lastName = "";
	if (firstName == null) firstName = "";	
	if (email == null) email = "";
	if (my_dept == null) my_dept = "";	
if (lastName.equals("") || firstName.equals("") || email.equals("") || my_dept.equals(""))
{
response.sendRedirect("user_profile.jsp?f_login=fill");
return;
}
	//get current step's flow step instance
	String stepId = request.getParameter("stepId");
	if (stepId == null) stepId="";
	String equipList = "";
	String location = "";
	String deptApproval = "";
	Date deptApprovalDate = null;
	String deptApprovalDateStr = null;
	String adminApproval = "";
	Date adminApprovalDate = null;
	String adminApprovalDateStr = null;
	//perry
	Date itApprovalDate = null;
	String itApprovalDateStr = null;	
	String itApproval = null;	
	Date handleApprovalDate = null;
	String handleApprovalDateStr = null;		
	String handleApproval = null;	
	String Owner_fullName ="";
	String Owner_Departments = "";	
	String Owner_Department_name = "";
	//if stepId exists get all variables of application including:
	// form_name		 	var_name			flow_data_object_location
	//1. 设备清单		 	equipList			String1
	//2. 安装位置 		 	location 			String2
	//3. 部门负责人审?	 	deptApproval		string3
	//4. 部门负责人审批日?deptApprovalDate     	date1
	//5. 行政事务部审?	adminApproval		string4
	//6. 行政事务部审批日?adminApprovalDate 	date2
	//perry
    //7. 资讯科技部审批?	itApproval		string5
	//8. 资讯科技部部审批日?itApprovalDate 	date3
    //9. IT经手人?	 handleApproval		string6
	//10.IT经手人审批日?handleApprovalDate	date4
	
	String disabledStr = "";
	boolean isAborted = false;
	
	if (!(stepId == null || "".equals(stepId))) {  
		PstFlowStepManager fsMgr = PstFlowStepManager.getInstance();
		PstFlowStep flowStep = (PstFlowStep) fsMgr.get(pstuser, stepId);
		
		String executorIdS = flowStep.getCurrentExecutor();
		boolean isExecutor = !StringUtil.isNullOrEmptyString(executorIdS)
								&& myUid==Integer.parseInt(executorIdS);
		if (!isExecutor) disabledStr = "disabled";

		//get current flow instance 
		String flowInstanceId = (String) flowStep
				.getAttribute("FlowInstanceName")[0];
		PstFlowManager fMgr = PstFlowManager.getInstance();
		PstFlow flow = (PstFlow) fMgr.get(pstuser, flowInstanceId);
		isAborted = flow.getStringAttribute("State").equals("abort");
//By Perry:get the Owner Fullname
String Owner = flow.getStringAttribute("Owner");
if (Owner != null)
{
user Owner_name = (user)userManager.getInstance().get(pstuser, Integer.parseInt(Owner));
	Owner_fullName = Owner_name.getStringAttribute("LastName")+' '+Owner_name.getStringAttribute("FirstName");
	Owner_Departments = Owner_name.getStringAttribute("DepartmentName");
if ("logistics".equals(Owner_Departments))
	{
	Owner_Department_name="院务部";
	}
	else if ("admin".equals(Owner_Departments))
	{
	Owner_Department_name="行政事务部";
	}
	else if ("public".equals(Owner_Departments))
	{
	Owner_Department_name="公共事务部";
	}		
	else if ("IT".equals(Owner_Departments))
	{
	Owner_Department_name="资讯科技部";
	}	
	else if ("HR".equals(Owner_Departments))
	{
	Owner_Department_name="人力资源部";
	}
	else if ("financial".equals(Owner_Departments))
	{
	Owner_Department_name="财务部";
	}
	else if ("engineering".equals(Owner_Departments))
	{
	Owner_Department_name="工程技术部";
	}
	else if ("medical".equals(Owner_Departments))
	{
	Owner_Department_name="医疗事务部";
	}
	else if ("nursing".equals(Owner_Departments))
	{
	Owner_Department_name="护理部";
	}	
	else if ("pharmacy".equals(Owner_Departments))
	{
	Owner_Department_name="药剂科";
	}
	else if ("pathology".equals(Owner_Departments))
	{
	Owner_Department_name="病理科";
	}
	else if ("pediatrics".equals(Owner_Departments))
	{
	Owner_Department_name="儿科";
	}
	else if ("radiology".equals(Owner_Departments))
	{
	Owner_Department_name="放射科";
	}
	else if ("oncology".equals(Owner_Departments))
	{
	Owner_Department_name="肿瘤科";
	}
	else if ("obstetrics".equals(Owner_Departments))
	{
	Owner_Department_name="妇产科";
	}
	else if ("gynecology".equals(Owner_Departments))
	{
	Owner_Department_name="妇科";
	}
	else if ("orthopaedics".equals(Owner_Departments))
	{
	Owner_Department_name="骨科";
	}
	else if ("stomatology".equals(Owner_Departments))
	{
	Owner_Department_name="口腔科";
	}
	else if ("microbiology".equals(Owner_Departments))
	{
	Owner_Department_name="临床微生物及感染学";
	}
	else if ("anesthesiology".equals(Owner_Departments))
	{
	Owner_Department_name="麻醉";
	}	
	else if ("medicine".equals(Owner_Departments))
	{
	Owner_Department_name="内科";
	}	
	else if ("general".equals(Owner_Departments))
	{
	Owner_Department_name="全科";
	}
	else if ("surgery".equals(Owner_Departments))
	{
	Owner_Department_name="外科";
	}
	else if ("image".equals(Owner_Departments))
	{
	Owner_Department_name="影像";
	}
	else if ("resources".equals(Owner_Departments))
	{
	Owner_Department_name="资源整合";
	}
	else if ("emergency".equals(Owner_Departments))
	{
	Owner_Department_name="急诊科";
	}
	else if ("support".equals(Owner_Departments))
	{
	Owner_Department_name="中央支援";
	}	
	else if ("other".equals(Owner_Departments))
	{
	Owner_Department_name="其它部门";
	}			
	else
	{
	Owner_Department_name="未知部门";
	}
}

		//get the flow data object of current flow instance
		String flowDataObjId = (String) flow.getAttribute("ContextObject")[0];
		PstFlowDataObjectManager fdoMgr = PstFlowDataObjectManager.getInstance();
System.out.println("*** data = "+flowDataObjId);				
		PstFlowDataObject flowDataObj = (PstFlowDataObject) fdoMgr.get(
				pstuser, flowDataObjId);

		//get equipList from raw1 of flow data object
		equipList = (String) flowDataObj.getAttribute("string1")[0]; 
		//equipList = "临时的设备清?;
		//System.out.println("equipList" + equipList);
		
		//get location from raw2 of flow data object
		//location = flowDataObj.getRawAttributeAsString("raw2");
		location = (String) flowDataObj.getAttribute("string2")[0];
		//location = "临时的安装位?;
		//System.out.println("location" + location);
		
		//get department's approval from flow data object
		deptApproval = (String) getComment(flowDataObj, COMMENT_DEPT);
		System.out.println("deptApproval: " + deptApproval);
		
		//get department's approval date from date from flow data object
		deptApprovalDate = (Date) flowDataObj.getAttribute("date1")[0];
		System.out.println("deptApprovalDate: " + deptApprovalDate);
		
		//get admin department's approval from string2 from flow data object
		adminApproval = (String) getComment(flowDataObj, COMMENT_ADMIN);
		System.out.println("adminApproval: " + adminApproval);
		
		//get admin department's approval date from date2 from flow data object
		adminApprovalDate = (Date) flowDataObj.getAttribute("date2")[0];
		System.out.println("adminApprovalDate: " + adminApprovalDate);
		
		//perry
		//get IT GM's approval from string5 from flow data object
		itApproval = (String) getComment(flowDataObj, COMMENT_IT);
		System.out.println("itApproval: " + itApproval);
		
		//get ITGM's approval date from date2 from flow data object
		itApprovalDate = (Date) flowDataObj.getAttribute("date3")[0];
		System.out.println("itApprovalDate: " + itApprovalDate);
		
		//get handel person's approval from string2 from flow data object
		handleApproval = (String) getComment(flowDataObj, COMMENT_HANDLE);
		System.out.println("handleApproval: " + handleApproval);
		//get handel person's approval date from date2 from flow data object
		handleApprovalDate = (Date) flowDataObj.getAttribute("date4")[0];
		System.out.println("handleApprovalDate: " + handleApprovalDate);
	}
	
	//clean null of string variables
	if ("null".equals(equipList) || equipList == null) equipList = "";
	if ("null".equals(location) || location == null) location = "";
	if ("null".equals(deptApproval) || deptApproval == null) deptApproval = "";
	if ("null".equals(adminApproval) || adminApproval == null) adminApproval = "";//perry
	if ("null".equals(itApproval) || itApproval == null) itApproval = "";
	if ("null".equals(handleApproval) || handleApproval == null) handleApproval = "";
	
	//format date yyyy-MM-dd
	SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
	
	if (deptApprovalDate == null) deptApprovalDate = new Date();
	deptApprovalDateStr = sdf.format(deptApprovalDate);
	
	if (adminApprovalDate == null) adminApprovalDate = new Date();
	adminApprovalDateStr = sdf.format(adminApprovalDate);
	System.out.println("requestPC jsp - adminApprovalDate - " + adminApprovalDate);
	
	//PERRY
	if (itApprovalDate == null) itApprovalDate = new Date();
	itApprovalDateStr = sdf.format(itApprovalDate);
	
	if (handleApprovalDate == null) handleApprovalDate = new Date();
	handleApprovalDateStr = sdf.format(handleApprovalDate);		
	
	if (op == null) { //first time to run the page, means WF_OP_HARDWARE_REQ;
		op = String.valueOf(SampleWfThread.WF_OP_HARDWARE_REQ);
		opCode = SampleWfThread.WF_OP_HARDWARE_REQ;
	} else {
		opCode = Integer.parseInt(op);
	}

	System.out.println("op = " + op);
	System.out.println("op code = " + opCode);

	//String username = "perryc";
	//String password = "snowman24";

	//boolean isGuest = false;
	//PstUserAbstractObject gUser = (PstUserAbstractObject) session
	//		.getAttribute("pstuser");

	// 	if (gUser == null || (gUser instanceof PstGuest)) {
	// 		gUser = (PstUserAbstractObject) PstGuest.getInstance();
	// 		isGuest = true;
	// 	}

	userManager uMgr = userManager.getInstance();

	user me = (user) uMgr.get(pstuser, pstuser.getObjectId());
	String fullName = pstuser.getStringAttribute("LastName")+' '+pstuser.getStringAttribute("FirstName");//me.getFullName();
	//String fullName = me.getFullName();
	String Departments = pstuser.getStringAttribute("DepartmentName");
	String Department_name = "";
	if ("logistics".equals(Departments))
	{
	Department_name="院务部";
	}
	else if ("admin".equals(Departments))
	{
	Department_name="行政事务部";
	}
	else if ("public".equals(Departments))
	{
	Department_name="公共事务部";
	}		
	else if ("IT".equals(Departments))
	{
	Department_name="资讯科技部";
	}	
	else if ("HR".equals(Departments))
	{
	Department_name="人力资源部";
	}
	else if ("financial".equals(Departments))
	{
	Department_name="财务部";
	}
	else if ("engineering".equals(Departments))
	{
	Department_name="工程技术部";
	}
	else if ("medical".equals(Departments))
	{
	Department_name="医疗事务部";
	}
	else if ("nursing".equals(Departments))
	{
	Department_name="护理部";
	}	
	else if ("pharmacy".equals(Departments))
	{
	Department_name="药剂科";
	}
	else if ("pathology".equals(Departments))
	{
	Department_name="病理科";
	}
	else if ("pediatrics".equals(Departments))
	{
	Department_name="儿科";
	}
	else if ("radiology".equals(Departments))
	{
	Department_name="放射科";
	}
	else if ("oncology".equals(Departments))
	{
	Department_name="肿瘤科";
	}
	else if ("obstetrics".equals(Departments))
	{
	Department_name="妇产科";
	}
	else if ("gynecology".equals(Departments))
	{
	Department_name="妇科";
	}
	else if ("orthopaedics".equals(Departments))
	{
	Department_name="骨科";
	}
	else if ("stomatology".equals(Departments))
	{
	Department_name="口腔科";
	}
	else if ("microbiology".equals(Departments))
	{
	Department_name="临床微生物及感染学";
	}
	else if ("anesthesiology".equals(Departments))
	{
	Department_name="麻醉";
	}	
	else if ("medicine".equals(Departments))
	{
	Department_name="内科";
	}	
	else if ("general".equals(Departments))
	{
	Department_name="全科";
	}
	else if ("surgery".equals(Departments))
	{
	Department_name="外科";
	}
	else if ("image".equals(Departments))
	{
	Department_name="影像";
	}
	else if ("resources".equals(Departments))
	{
	Department_name="资源整合";
	}
	else if ("emergency".equals(Departments))
	{
	Department_name="急诊科";
	}
	else if ("support".equals(Departments))
	{
	Department_name="中央支援";
	}	
	else if ("other".equals(Departments))
	{
	Department_name="其它部门";
	}			
	else
	{
	Department_name="未知部门";
	}
%>

<html>
<head>

<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>香港大学深圳医院设备领用申请</title>
<script src="js/sel_squlist.js" type="text/javascript"></script>
<!--
<script language="JavaScript">
var nextField = "Uid";

function submitForm()
{
	reqForm.op.value = "<%=op%>";
	alert("<%=op%>");
	submit();
}

</script>  
//-->



<style type="text/css">
<!--
body {
	margin-left: 0px;
	margin-top: 0px;
	margin-right: 0px;
	margin-bottom: 0px;
	background-color: #FFFFFF;
}

body,td,th {
	font-family: 宋体, Arial, Helvetica, sans-serif;
	font-size: 14px;
}

input {
	height: 20px;
}

.title_link:link {color:#006AD5;font-weight:bold;text-decoration:none; font-size:14px;}
.title_link:visited {color:#006AD5; font-weight:bold;text-decoration:none; font-size:14px;}
.title_link:active {color:#006AD5;font-weight:bold; text-decoration:none; font-size:14px;}
.title_link:hover {color:#0080FF;font-weight:bold;text-decoration:underline; font-size:14px;}
.title_link_admin:link {color: #FF3535;font-weight:bold;text-decoration:none; font-size:14px;}
.title_link_admin:visited {color:#FF3535; font-weight:bold;text-decoration:none; font-size:14px;}
.title_link_admin:active {color:#FF3535;font-weight:bold; text-decoration:none; font-size:14px;}
.title_link_admin:hover {color:#FF3535;font-weight:bold;text-decoration:underline; font-size:14px;}
.title_text {
	padding-top: 3px;
	padding-left: 5px;
}
-->
</style>
</head>

<body>
	<table width="100%" border="0" cellpadding="0" cellspacing="0">
  <tr>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td width="3%">&nbsp;</td>
    <td width="8%"><img src="images/logo2.jpg" width="76" height="76"></td>
    <td width="89%"><img src="images/logo_title.gif" width="417" height="43"></td>
  </tr>
  <tr>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td height="35" colspan="3" bgcolor="#CCE8F7"><table width="1000" border="0" align="center" cellpadding="0" cellspacing="0">
      <tr>
        <td><div align="center"><a href="requestPC.jsp" target="_self" class="title_link">计算机领用申请(Request PC)</a></div></td>
        <td><div align="center"></div></td>
        <td><div align="center"><a href="worktray.jsp" target="_self" class="title_link">计算机申请列表(Worktray)</a></div></td>
<%
if (session.getAttribute("username").equals("perryc") || session.getAttribute("username").equals("echeng") || session.getAttribute("username").equals("huangrt")){
%>		
		
		<td><div align="center"></div></td>		
		<td><div align="center"><a href="worktray.jsp?do=admin" target="_self" class="title_link_admin">管理列表(Admin)</a></div></td>
<%
}
%>			
        <td><div align="center"></div></td>
        <td><div align="center"><a href="user_profile.jsp" target="_self" class="title_link">修改我的个人信息(Edit User Profile)</a></div></td>
        <td><div align="center"></div></td>
        <td><div align="center"><a href="logout.jsp" target="_self" class="title_link">退出(Logout)</a></div></td>
      </tr>
    </table></td>
  </tr>
  <tr>
    <td height="30" colspan="3">&nbsp;</td>
  </tr>
</table>
	<table width="1000" border="0" align="center" cellpadding="1"
		cellspacing="0" bgcolor="#A8A8A8">
		<tr>
			<td><table width="100%" border="0" cellpadding="0"
					cellspacing="1">
					<form name="reqForm" method="post" action="post_requestPC.jsp">
						<input type='hidden' name='op' value='<%=op%>'>
						<input type='hidden' name='resubmit' value=''>

						<tr>
							<td height="48" colspan="4" bgcolor="#FFFFFF"><div
									align="center">
							  <table width="99%" border="0" cellpadding="0" cellspacing="0">
										<tr>
											<td>&nbsp;</td>
										</tr>
										<tr>
											<td><div align="center">
													<img src="images/title.jpg" width="200" height="23">
												</div></td>
										</tr>
										<tr>
											<td>&nbsp;</td>
										</tr>
										<tr>
											<td height="1" bgcolor="#A8A8A8"></td>
										</tr>
										<tr>
											<td height="30">&nbsp;</td>
										</tr>
									</table>
								</div></td>
						</tr>

						<tr>
						<!--
							<td width="12%" height="25" bgcolor="#FFFFFF"><div
									align="right">&nbsp;申请部门</div></td>
							<td width="31%" bgcolor="#FFFFFF">&nbsp;</td>-->
							<td width="22%" bgcolor="#FFFFFF"><div align="right">申请人：</div>							</td>
							<td width="35%" bgcolor="#FFFFFF"><strong><%
if (!(stepId == null || "".equals(stepId))) { 
out.print(Owner_fullName+"&nbsp;&nbsp;"+Owner_Department_name);
}
else
{
out.print(fullName+"&nbsp;&nbsp;"+Department_name);
}
%></strong></td>
						</tr>

						<tr>
							<td height="131" colspan="4" valign="top" bgcolor="#FFFFFF"><table
									width="100%" border="0" cellpadding="0" cellspacing="0">
									<tr>
										<td height="30"><span class="title_text">申请的设备列表</span></td>
									</tr>
									<tr>
										<td>


<%
//if (opCode != SUBMIT_REQ) {
 if (opCode == WF_OP_HARDWARE_REQ) {
 %>										
										<span class="title_text"> 
										<strong></strong>
										<select name="equipsel" size="1" id="equipsel">
										  <option value="电脑" selected>电脑</option>
										  <option value="显示器">显示器</option>										  
										  <option value="打印机">打印机</option>
										  <option value="外设">外设</option>
										  <option value="网络产品">网络产品</option>
										  <option value="其它产品">其它产品</option>
									    </select>&nbsp;<select name="equipsel2" size="1" id="equipsel2" class="equipsel2">
                                          <option value="台式电脑" selected>台式电脑</option>										
                                          <option value="瘦客户机">瘦客户机</option>
                                          <option value="触摸屏一体机">触摸屏一体机</option>
                                          <option value="手持移动平板电脑">手持移动平板电脑</option>
                                          <option value="大运会处置电脑">大运会处置电脑</option>
                                          <option value="PDA">PDA</option>
                                        </select>
									    <label>申请数量：</label>
                                        <select name="equipnum" size="1" id="equipnum">
<script language="javascript">	
<!--				 
for(var i = 1; i <= 30; i++) { 		
document.write("<option value='"+i+"'>"+i+"</option>"); 
}
-->	 
</script>
</select>
                                        <label>
                                        <input type="button" name="Submit2" value="加入到申请设备列表" onClick="add_search();">
                                        </label>
                                        <input name="temp_equ_list" type="hidden" id="temp_equ_list">
                                        <br>
                                        <br>
                                        <span class="title_text">已选申请设备列表:</span><br>
<span class="title_text"><select name="equipList" multiple="multiple" id="equipList" style="width: 968px;height:158px;z-index:-100;"></select></span>												
													
												<br>
												<br>
												<input type="button" name="Submit11" value="移除已选设备列表" onClick="del_search_sel();"/> &nbsp;&nbsp;<strong>注：</strong>按CTRL键可进行多选<br> </span><br>
<br>

<%
}
else
{
%>
<span class="title_text"><%=equipList %></span>
<input type='hidden' name='equipList' value=''>
<%
}
%>												</td>
									</tr>
								</table></td>
						</tr>

						<tr>
							<td height="131" colspan="4" valign="top" bgcolor="#FFFFFF">
<table width="100%" border="0" cellpadding="0" cellspacing="0">
									<tr>
										<td height="30"><span class="title_text">安装地点:</span></td>
									</tr>
									<tr>
										<td>
<%
//if (opCode != SUBMIT_REQ) {
 if (opCode == WF_OP_HARDWARE_REQ) {
 %>													
										<span class="title_text"> <textarea <%=disabledStr%>
													name="location" cols="135" rows="10" id="location"><%=location %></textarea>
												<br> <br> </span>
<%
}
else
{
%>
&nbsp;&nbsp;<%=location %>
<%
}
%>									  </td>
									</tr>
</table>							

<%
 	//if (opCode != SUBMIT_REQ) {
 	if (opCode == WF_OP_DEPT_GM_APPROVE
 			|| opCode == WF_OP_ADMIN_GM_APPROVE
 			|| opCode == WF_OP_IT_GM_APPROVE
 			|| opCode == WF_OP_IT_HANDLE_INFORM) {
 %>
				      <tr>
					      <td height="131" colspan="4" valign="top" bgcolor="#FFFFFF">
								<table width="100%" border="0" cellpadding="0" cellspacing="0">
									<tr>
										<td height="30"><span class="title_text">申请部门负责人审批：</span>										</td>
									</tr>
									<tr>
										<td><table width="100%" border="0" cellpadding="0"
												cellspacing="0">
												<tr>
													<td height="50" colspan="2">
<%
//if (opCode != SUBMIT_REQ) {
 if (opCode == WF_OP_DEPT_GM_APPROVE) {
 %>										
										<span class="title_text"> <textarea <%=disabledStr%>
															name="deptApproval" id="deptApproval"
															cols="135" rows="10"><%=deptApproval %></textarea>
												<br> <br> </span>
<%
}
else
{
%>
&nbsp;&nbsp;<%=deptApproval %>
<%
}
%>													
</td>
												</tr>
												<tr>
													<td width="81%" height="20">&nbsp;</td>
													<td width="19%">日期：<%
//if (opCode != SUBMIT_REQ) {
 if (opCode == WF_OP_DEPT_GM_APPROVE) {
 %>										
										<span class="title_text"><input type="text" name="deptApprovalDate" id="deptApprovalDate" value="<%=deptApprovalDateStr %>"/></span>
<%
}
else
{
%>
<%=deptApprovalDateStr %>
<%
}
%>				</td>
												</tr>
												<tr>
													<td colspan="2"><br></td>
												</tr>
											</table> <span class="title_text"><br> <br> </span></td>
									</tr>
								</table> <%
 	}
 %> 
 <%
 	if (opCode == WF_OP_ADMIN_GM_APPROVE
 			|| opCode == WF_OP_IT_GM_APPROVE
 			|| opCode == WF_OP_IT_HANDLE_INFORM) {
 %>
				      <tr>
					        <td height="131" colspan="4" valign="top" bgcolor="#FFFFFF">


								<table width="100%" border="0" cellpadding="0" cellspacing="0">
									<tr>
										<td height="30"><span class="title_text">行政事务部审批：</span>										</td>
									</tr>
									<tr>
										<td><table width="100%" border="0" cellpadding="0"
												cellspacing="0">
												<tr>
													<td height="50" colspan="2">
<%
//if (opCode != SUBMIT_REQ) {
 if (opCode == WF_OP_ADMIN_GM_APPROVE) {
 %>														
<span class="title_text">	
													<textarea <%=disabledStr%>
															name="adminApproval" id="adminApproval"
															cols="135" rows="10"><%=adminApproval %></textarea><br> <br> </span>
															
<%
}
else
{
%>
&nbsp;&nbsp;<%=adminApproval %>
<%
}
%>															
</td>
												</tr>
												<tr>
													<td width="81%" height="20">&nbsp;</td>
													<td width="19%">日期：
<%
if (opCode == WF_OP_ADMIN_GM_APPROVE) {
%>	
<span class="title_text"><input type="text" name="adminApprovalDate" id="adminApprovalDate" value="<%=adminApprovalDateStr %>"/></span>
<%
}
else
{
%>
<%=adminApprovalDateStr %>
<%
}
%>
</td>
												</tr>
												<tr>
													<td colspan="2"><br></td>
												</tr>
											</table> <span class="title_text"><br> <br> </span></td>
									</tr>
								</table> <%
 	}
 %> 
 <%
 	if (opCode == WF_OP_IT_GM_APPROVE
 			|| opCode == WF_OP_IT_HANDLE_INFORM) {
 %>							                        
			          <tr>
					          <td height="131" colspan="4" valign="top" bgcolor="#FFFFFF">



								<table width="100%" border="0" cellpadding="0" cellspacing="0">
									<tr>
										<td height="30"><span class="title_text">资讯科技部审批</span>										</td>
									</tr>
									<tr>
										<td><table width="100%" border="0" cellpadding="0"
												cellspacing="0">
												<tr>
													<td height="50" colspan="2">
<%
//if (opCode != SUBMIT_REQ) {
 if (opCode == WF_OP_IT_GM_APPROVE) {
 %>										
										<span class="title_text">													
													<textarea <%=disabledStr%>
															name="itApproval" id="itApproval"
															cols="135" rows="10"><%=itApproval %></textarea>
	<br> <br> </span>
<%
}
else
{
%>
&nbsp;&nbsp;<%=itApproval %>
<%
}
%>			
															
															
															</td>
												</tr>
												<tr>
													<td width="81%" height="20">&nbsp;</td>
													<td width="19%">日期：<%
if (opCode == WF_OP_IT_GM_APPROVE) {
 %>										
										<span class="title_text">
												    <input type="text" name="itApprovalDate" id="itApprovalDate" value="<%=itApprovalDateStr %>"/></span>
<%
}
else
{
%>
<%=itApprovalDateStr %>
<%
}
%>	</td>
												</tr>
												<tr>
													<td colspan="2"><br></td>
												</tr>
											</table> <span class="title_text"><br> <br> </span></td>
									</tr>
								</table> <%
 	}
 %>	
 <%
 	if (opCode == WF_OP_IT_HANDLE_INFORM) {
 %>						                          
			          <tr>
					            <td height="131" colspan="4" valign="top" bgcolor="#FFFFFF">

								<table width="100%" border="0" cellpadding="0" cellspacing="0">
									<tr>
										<td height="30"><span class="title_text">IT经手人审批：</span></td>
									</tr>
									<tr>
										<td><table width="100%" border="0" cellpadding="0"
												cellspacing="0">
												<tr>
												  <td height="50" colspan="2"><%
//if (opCode != SUBMIT_REQ) {
 if (opCode == WF_OP_IT_HANDLE_INFORM) {
 %>										
										<span class="title_text"> 
												    <textarea <%=disabledStr%>
															name="handleApproval" id="handleApproval"
															cols="135" rows="10"><%=handleApproval %></textarea>
	<br> <br> </span>
<%
}
else
{
%>
&nbsp;&nbsp;<%=handleApproval %>
<%
}
%>																
															</td>
												</tr>
												<tr>
													<td width="81%" height="20">&nbsp;</td>
													<td width="19%">日期：<%if (opCode == WF_OP_IT_HANDLE_INFORM) {
 %>										
										<span class="title_text">
												    <input type="text" name="handleApprovalDate" id="handleApprovalDate" value="<%=handleApprovalDateStr %>"/>
</span>
<%
}
else
{
%>
<%=handleApprovalDateStr %>
<%
}
%>														
</td>
												</tr>
												<tr>
													<td colspan="2"><br></td>
												</tr>
											</table> <span class="title_text"><br> <br> </span></td>
									</tr>
								</table> <%
 	}
 %>								                        
		              <tr>
		                <td height="65" colspan="4" valign="top" bgcolor="#FFFFFF">
                          <input type="hidden" name="memname" value="this is mem name" />
                          <input type="hidden" name="stepName" value="<%=stepId%>" />
                          <input type="hidden" name="status" value="" />
                          <table width="100%" border="0" cellpadding="0" cellspacing="0">
                            <tr>
                              <td height="30">&nbsp;</td>
                            </tr>
                            <tr>
                              <td><table width="100%" border="0" cellpadding="0"
												cellspacing="0">
                                  <tr>
                                    <td align='center'>
<%	if (!isAborted) {
if (opCode != WF_OP_HARDWARE_REQ) {
%>									
<input type="button" name="Submit" value="开始审批(Approve)" onclick="approve(1);" <%=disabledStr%> />
<%
}
else
{%>
<input type="button" name="Submit" value="提交申请(Submit)" onclick="approve(0);" <%=disabledStr%> />
<%}
if (opCode != WF_OP_HARDWARE_REQ) {%>
                                            <input type="button" name="Reject" value="不同意并退回(Reject)" onclick="reject();" <%=disabledStr%> />
											<img src='i/spacer.gif' width='20'/>
                                            <input type="button" name="Save" value="保存(Save)" onclick='save();' <%=disabledStr%> />
<%	} 
	}  else {	// isAborted
										out.print("<input type='button' name='ReSubmit' value='重新提交(Re-submit)' "
											+ "onclick='resubmitReq(\"" + equipList + "\");' />");
	}
%>
                                            <input type="button" name="Close" value="关闭(Close)" onclick='closeWin();' />
                                    </td>
                                  </tr>
                                </table>
                                  <span class="title_text"><br>
                                  <br>
                                </span></td>
                            </tr>
                          </table>						                      
              </form>
				</table></td>
		</tr>
	</table>
</body>
</html>
