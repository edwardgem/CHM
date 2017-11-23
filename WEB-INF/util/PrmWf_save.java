////////////////////////////////////////////////////
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	Wf.java
//	Author:	ECC
//	Date:	07/05/05
//	Description:
//		Workflow methods for notification.
//		TODO: we should move this into Pst package.
//
//	Modification:
//
//
////////////////////////////////////////////////////////////////////

package util;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;

import org.apache.log4j.Logger;

import oct.codegen.planManager;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstFlow;
import oct.pst.PstFlowConstant;
import oct.pst.PstFlowDataObject;
import oct.pst.PstFlowDef;
import oct.pst.PstFlowDefManager;
import oct.pst.PstFlowManager;
import oct.pst.PstFlowStep;
import oct.pst.PstFlowStepManager;
import oct.pst.PstUserAbstractObject;
import oct.pst.PstUtil;
import oct.pst.PstSystem;
import util.Notify;
//import util.Notify_gongwen;

public class PrmWf
{
	private static Logger l = PrmLog.getLog();

	private static PstFlowDefManager fdMgr;
	private static PstFlowStepManager fsMgr;
	private static PstFlowManager fiMgr;
	private static userManager uMgr;
	private static planManager planMgr;

	private static final String MAILFILE = "alert.htm";
	private static final SimpleDateFormat df = new SimpleDateFormat("MMMMMMMM dd, yyyy (EEE) hh:mm a");
	private static final SimpleDateFormat df2 = new SimpleDateFormat("yyyy-MM-dd");
	private static final String FROM = Util.getPropKey("pst", "FROM");
	private static final String NODE = Util.getPropKey("pst", "PRM_HOST");

	static {
		try {
			fdMgr = PstFlowDefManager.getInstance();
			fiMgr = PstFlowManager.getInstance();
			fsMgr = PstFlowStepManager.getInstance();
			uMgr = userManager.getInstance();
			planMgr = planManager.getInstance();
		}
		catch (PmpException e) {}
	}

	public static void notifyExecutor(PstUserAbstractObject pstuser,PstFlowDataObject flowDataObj, PstFlow flowObj, String app)
		throws PmpException
	{
		PstFlowStep stepObj;
		String status, creator, executor,toEmail,Email_users,stepDisplayName_cn;
		String From_name="";
		for (int i=0; i < flowObj.getAttribute(PstFlow.CURRENT_ACTIVE_STEP).length; i++)
		{
			stepObj = (PstFlowStep)fsMgr.get(pstuser, (String)flowObj.getAttribute(PstFlow.CURRENT_ACTIVE_STEP)[i]);
			if (stepObj == null) continue;
			// check to see if stepObj is ready to be executed, if so, send notification
			status = (String)stepObj.getAttribute(PstFlow.STATUS)[0];
			if (!status.equals(PstFlowConstant.ST_STEP_ACTIVE))
				continue;				// not ready (waiting for token)

			// if the user is 'dummy' (auto step), ignore it.
			creator  = (String)stepObj.getAttribute(PstFlowStep.OWNER)[0];
			executor = (String)stepObj.getAttribute(PstFlowStep.CURRENT_EXECUTOR)[0];
			if (executor==null || executor.equals("dummy") || executor.equals(creator))
				continue;
			try {
			//executor=Integer.parseInt(executor);
		    user u = (user)uMgr.get(pstuser,Integer.parseInt(executor));
			//executor = String.valueOf(u.getObjectId());		// *** change to user id
			//By Perry
			toEmail = u.getStringAttribute("Email");	
			String str1[] = toEmail.split("@");			
			Email_users=str1[0].trim();
			/*Email_users = toEmail.replace("@hku-szh.org","");
			Email_users = Email_users.replace("@hku.hk","");*/
			System.out.println("Got the executor's email:" +toEmail);
			}catch (Exception e)
			{
	throw new PmpException("Error in get executor's email.");
			}

			// timestamp
			String ts = df.format(new Date());

			String stepId = stepObj.getObjectName();

			// get the step display name
			String s = (String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0];
			PstFlow flowInstance = (PstFlow)fiMgr.get(pstuser, s);
			String flowXML = stepObj.getFlowXML(pstuser);
			HashMap<String,String> stepHash =
				PstUtil.getStepAttributeHashFromXML(flowXML, stepObj);

			String stepDisplayName = PstUtil.getStepAttribute(stepHash, PstFlowConstant.STEP_DISPNAME);
			//(String)sd.getAttribute("DisplayName")[0];
			if (stepDisplayName == null)
				stepDisplayName = PstUtil.getStepAttribute(stepHash, PstFlowConstant.STEP_NAME);

			// get the flow display name
			s  = (String)flowInstance.getAttribute("FlowName")[0];
			PstFlowDef fd = (PstFlowDef)fdMgr.get(pstuser, s);
			String flowDisplayName =(String)fd.getAttribute("DisplayName")[0];
			if (flowDisplayName == null) flowDisplayName = fd.getObjectName();		
/*
			String msg = "A workflow step has arrived your in-tray on " + ts;
			msg += "<blockquote>Process Name: " + flowDisplayName + "</br>";
			msg += "Step Name: " + stepDisplayName + "</blockquote>";
			msg += "Click the following link to access your in-tray and process the work step:";
			msg += "<blockquote><a href='" + NODE + "/project/revw_planchg.jsp?stepId="
					+ stepId + "'><b>Process Work</b></a></blockquote>";*/
			//By Perry:Send the email to executor.			
	Date dt = (Date) flowDataObj.getAttribute("date1")[0];
			String equ_date = "-";
			if (dt != null) {
			equ_date = df.format(dt);
				}
			String equ_name = (String) flowDataObj.getAttribute("string1")[0];
			if (equ_name == null) equ_name = "没有设备列表(None)";
String Jobno ="";
String my_dept ="";						
String owner =flowObj.getStringAttribute(PstFlow.OWNER);
			if (owner != null) {
			user u = (user) uMgr.get(pstuser,Integer.parseInt(owner));
		     //owner = u.getFullName();
			owner = u.getStringAttribute("LastName")+u.getStringAttribute("FirstName");
			Jobno = u.getStringAttribute("Jobno");
			my_dept = u.getStringAttribute("DepartmentName");
			}
switch (stepDisplayName)
{
case "Approval By Department's GM":		
stepDisplayName_cn="部门经理审批" ;
break;
case "Approval By Admin GM":		
stepDisplayName_cn="行政及保障事务部经理审批" ;
break;
case "Approval By IT GM":
stepDisplayName_cn="IT部门经理审批" ;
break;
case "handle the hardware request":
stepDisplayName_cn="IT部门出入库管理员审批" ;
break;
//vacation
case "Approval By Supervisor":
stepDisplayName_cn="上司审批" ;
break;
case "Approval By HR":
stepDisplayName_cn="人力资源部审批" ;
break;
case "Back to Work":
stepDisplayName_cn="员工返岗销假" ;
break;
case "Check on work attendance":
stepDisplayName_cn="考勤人员确认(员工返岗销假)" ;
break;
case "Check on work attendance By Department's GM":
stepDisplayName_cn="部门经理确认(员工返岗销假)" ;
break;
case "Notify HR":
stepDisplayName_cn="人力资源处备案(请假申请已完成)" ;
break;
//Document Management
case "Approval By Administration":
stepDisplayName_cn="院务部拟办意见" ;
break;
case "Approval By Leader":
stepDisplayName_cn="院领导审批" ;
break;
case "Choose Department":
stepDisplayName_cn="承办部门选择" ;
break;
case "Department Comment":
stepDisplayName_cn="承办部门办理意见" ;
break;
case "Additional Comment":
stepDisplayName_cn="是否需要院领导补充意见" ;
break;
case "Additional comments by leader":
stepDisplayName_cn="院领导补充意见" ;
break;
case "Filed":
stepDisplayName_cn="归档" ;
break;
case "Notify Receive":
stepDisplayName_cn="已归档" ;
break;

case "<font color='red'>Rejected</font>":
stepDisplayName_cn="申请被退回" ;
break;
default:	
stepDisplayName_cn="";
}
String msg ="";
String subj ="";
String worktray_lisname ="";
if (app==null) app="";
if (app.equals("VacationApplication"))
{
From_name="OA系统(请假申请)";
String gonghao=(String) flowDataObj.getAttribute("string1")[0];	
String va_type=(String) flowDataObj.getAttribute("string4")[0];
String time_start=(String) flowDataObj.getAttribute("string19")[0];
String location=(String) flowDataObj.getAttribute("string11")[0];
String time_start_old=(String) flowDataObj.getAttribute("string20")[0];
String upfiles=(String) flowDataObj.getAttribute("string21")[0];
String Flotdataid=(String) flowDataObj.getAttribute("string22")[0];

if (time_start_old==null) time_start_old="";
if (upfiles==null) upfiles="";
if (Flotdataid==null) Flotdataid="";

String day_va_finish= (String) flowDataObj.getAttribute("string9")[0];
String day_va_left= (String) flowDataObj.getAttribute("string10")[0];
String memo= (String) flowDataObj.getAttribute("string12")[0];	
if (gonghao == null) 
{
worktray_lisname = "无(None)";
}
else
{
worktray_lisname ="<strong>请假类型：</strong>"+va_type+"<br><strong>请假时间：</strong><br><strong><font color='blue'>"+time_start+"</font></strong><strong>休假地点：</strong>"+location;
}

if (stepDisplayName.equals("Approval By Supervisor"))
{
String attend_email ="";
msg = "<div align='left'>您好！以下请假申请信息正在开始申请，请假信息如下所示。</div><br><br><table width='99%' border='0' align='center' cellpadding='0' cellspacing='1' bgcolor='#2698D6'><tr><td><table width='100%' border='0' cellpadding='0' cellspacing='0' bgcolor='#FFFFFF'><tr><td><table width='98%' border='0' align='center' cellpadding='0' cellspacing='0'><tr><td>&nbsp;</td></tr><tr><td><div align='center'><h3>香港大学深圳医院请假申请</h3></div></td></tr><tr><td>&nbsp;</td></tr><tr><td><table width='100%' border='0' cellpadding='0' cellspacing='0'><tr><td width='38%'><div align='center'><strong>请假申请内容</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='20%'><div align='center'><strong>申请人</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='21%'><div align='center'><strong>申请进度</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='21%'><div align='center'><strong>提交时间</strong></div></td></tr><tr><td height='8' colspan='11'></td></tr><tr><td height='1' colspan='11' bgcolor='#CECEFF'></td></tr></table></td></tr><tr><td>&nbsp;</td></tr><tr><td><table width='100%' border='0' cellspacing='0' cellpadding='0'><tr><td width='38%'>"+worktray_lisname+"</td><td width='20%'><div align='center'>"+owner+"</div></td><td width='21%'><div align='center'><font color='#30B133'><strong>"+stepDisplayName_cn+"("+stepDisplayName+")</strong></font></div></td><td width='21%'><div align='center'>"+equ_date+"</div></td></tr></table></td></tr><tr><td>&nbsp;</td></tr></table></td></tr></table></td></tr></table><br><br><br><div align='center'></div><br><br><br><br><div align='right'><strong>资讯科技部</strong><br>OA系统</div>" ;
subj ="提示："+owner+"正开始请假申请--"+stepDisplayName_cn+"[OA-请假申请]";
if ("admin".equals(my_dept))
	{
	attend_email="weilj@hku-szh.org";
	}
	else if ("IT".equals(my_dept))
	{
	attend_email="guanmy@hku-szh.org";//zhouj@hku-szh.org
	}	
	else if ("HR".equals(my_dept))
	{
	attend_email="lux@hku-szh.org";//liangyy@hku-szh.org
	}
	else if ("financial".equals(my_dept))
	{
	attend_email="zhongw@hku-szh.org";
	}
	else if ("logistics".equals(my_dept))
	{
	attend_email="renhj@hku-szh.org";
	}
	else if ("relationship".equals(my_dept))
	{
	attend_email="zhengfn@hku-szh.org";
	}
	else if ("public".equals(my_dept))
	{
	attend_email="wangyl5@hku-szh.org";
	}		
	else if ("financial2".equals(my_dept))
	{
	attend_email="shoufkq@hku-szh.org";
	}
	else if ("medical".equals(my_dept))
	{
	attend_email="kedg@hku-szh.org";
	}
	else if ("certification".equals(my_dept))
	{
	attend_email="linmn@hku-szh.org";
	}
try{
//Notify send_email = new Notify();
Notify.SendEmail("notify_wf@hku-szh.org",attend_email,subj,msg,From_name);		   
 }catch(Exception e){  	
throw new PmpException("Error in sending attendence's notification email.");
}
}

 if (stepDisplayName.equals("Back to Work"))
	{
msg = "<div align='left'>您好！您的请假申请已通过，请确认您的请假信息并<b>请在返岗之日进行以下操作</b>。</div><br><br><table width='99%' border='0' align='center' cellpadding='0' cellspacing='1' bgcolor='#2698D6'><tr><td><table width='100%' border='0' cellpadding='0' cellspacing='0' bgcolor='#FFFFFF'><tr><td><table width='98%' border='0' align='center' cellpadding='0' cellspacing='0'><tr><td>&nbsp;</td></tr><tr><td><div align='center'><h3>香港大学深圳医院请假申请</h3></div></td></tr><tr><td>&nbsp;</td></tr><tr><td><table width='100%' border='0' cellpadding='0' cellspacing='0'><tr><td width='38%'><div align='center'><strong>请假申请内容</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='20%'><div align='center'><strong>申请人</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='21%'><div align='center'><strong>申请进度</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='21%'><div align='center'><strong>提交时间</strong></div></td></tr><tr><td height='8' colspan='11'></td></tr><tr><td height='1' colspan='11' bgcolor='#CECEFF'></td></tr></table></td></tr><tr><td>&nbsp;</td></tr><tr><td><table width='100%' border='0' cellspacing='0' cellpadding='0'><tr><td width='38%'>"+worktray_lisname+"</td><td width='20%'><div align='center'>"+owner+"</div></td><td width='21%'><div align='center'><font color='#30B133'><strong>"+stepDisplayName_cn+"("+stepDisplayName+")</strong></font></div></td><td width='21%'><div align='center'>"+equ_date+"</div></td></tr></table></td></tr><tr><td>&nbsp;</td></tr></table></td></tr></table></td></tr></table><br><br><br><div align='center'><a href='http://58.60.186.57:8088/hkusz/index.jsp?randpass=pxet6bfj8z4o&UserName="+Email_users+"&red_url=worktray.jsp?worktray_type=vacation' target='_blank'><b>点击这里开始操作(Process Work)</b></a></div><br><br><br><br><div align='right'><strong>资讯科技部</strong><br>OA系统</div>" ;
subj =owner+"的请假申请--"+stepDisplayName_cn+"[OA-请假申请]";
//DBAccess.Insert(Flotdataid,Jobno,owner,my_dept,upfiles,va_type,time_start,time_start_old,day_va_finish,day_va_left,location,memo);//需求返岗销假计入统计。//used
	}
 else
 	{
msg = "<div align='left'>您好！以下请假申请信息需要您的确认及操作，请假信息如下所示。</div><br><br><table width='99%' border='0' align='center' cellpadding='0' cellspacing='1' bgcolor='#2698D6'><tr><td><table width='100%' border='0' cellpadding='0' cellspacing='0' bgcolor='#FFFFFF'><tr><td><table width='98%' border='0' align='center' cellpadding='0' cellspacing='0'><tr><td>&nbsp;</td></tr><tr><td><div align='center'><h3>香港大学深圳医院请假申请</h3></div></td></tr><tr><td>&nbsp;</td></tr><tr><td><table width='100%' border='0' cellpadding='0' cellspacing='0'><tr><td width='38%'><div align='center'><strong>请假申请内容</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='20%'><div align='center'><strong>申请人</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='21%'><div align='center'><strong>申请进度</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='21%'><div align='center'><strong>提交时间</strong></div></td></tr><tr><td height='8' colspan='11'></td></tr><tr><td height='1' colspan='11' bgcolor='#CECEFF'></td></tr></table></td></tr><tr><td>&nbsp;</td></tr><tr><td><table width='100%' border='0' cellspacing='0' cellpadding='0'><tr><td width='38%'>"+worktray_lisname+"</td><td width='20%'><div align='center'>"+owner+"</div></td><td width='21%'><div align='center'><font color='#30B133'><strong>"+stepDisplayName_cn+"("+stepDisplayName+")</strong></font></div></td><td width='21%'><div align='center'>"+equ_date+"</div></td></tr></table></td></tr><tr><td>&nbsp;</td></tr></table></td></tr></table></td></tr></table><br><br><br><div align='center'><a href='http://58.60.186.57:8088/hkusz/index.jsp?randpass=pxet6bfj8z4o&UserName="+Email_users+"&red_url=worktray.jsp?worktray_type=vacation' target='_blank'><b>点击这里开始操作(Process Work)</b></a></div><br><br><br><br><div align='right'><strong>资讯科技部</strong><br>OA系统</div>" ;
subj =owner+"的请假申请--"+stepDisplayName_cn+"[OA-请假申请]";		
	}
}

else if (app.equals("ReceiveApplication"))
{
From_name="公文管理(OA)";	
//String upload_file= (String) flowDataObj.getAttribute("string1")[0];
String doc_title= (String) flowDataObj.getAttribute("string2")[0];
/*String doc_shunxu= (String) flowDataObj.getAttribute("string3")[0];
String doc_zihao= (String) flowDataObj.getAttribute("string4")[0];*/
String doc_other= (String) flowDataObj.getAttribute("string5")[0];
//String doc_company= (String) flowDataObj.getAttribute("string6")[0];
String doc_jinji= (String) flowDataObj.getAttribute("string7")[0];		
//String doc_person= (String) flowDataObj.getAttribute("string8")[0];				
String doc_type= (String) flowDataObj.getAttribute("string9")[0];
String time_start= (String) flowDataObj.getAttribute("string22")[0];
Date doc_time = null;
doc_time = (Date) flowDataObj.getAttribute("date8")[0];
//String buchong = (String) flowDataObj.getAttribute("string10")[0];

if (doc_other==null) doc_other=""; 	
if (doc_type.equals("其他事务")) doc_type="其他事务:"+doc_other;


String doc_date = "-";
if (doc_time != null) doc_date = df2.format(doc_time);

if (time_start== null) time_start="";
 if (!time_start.equals(""))
 {
subj ="["+doc_jinji+"-("+time_start+"前完成)]"+doc_title;
 }
 else
 {
subj ="["+doc_jinji+"]"+doc_title;	 
  }
msg = "<div align='left'>您好！有以下公文需要您审批，公文信息如下所示。</div><br><br><table width='99%' border='0' align='center' cellpadding='0' cellspacing='1' bgcolor='#2698D6'><tr><td><table width='100%' border='0' cellpadding='0' cellspacing='0' bgcolor='#FFFFFF'><tr><td><table width='98%' border='0' align='center' cellpadding='0' cellspacing='0'><tr><td>&nbsp;</td></tr><tr><td><div align='center'><h3>香港大学深圳医院公文信息</h3></div></td></tr><tr><td>&nbsp;</td></tr><tr><td><table width='100%' border='0' cellpadding='0' cellspacing='0'><tr><td width='34%'><div align='center'><strong>公文标题</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='14%'><div align='center'><strong>事务类型</strong></div></td><td width='0%' bgcolor='#CECEFF'></td><td width='15%'><div align='center'><strong>紧急程度</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='21%'><div align='center'><strong>流转进度</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='16%'><div align='center'><strong>收文日期</strong></div></td></tr><tr><td height='8' colspan='13'></td></tr><tr><td height='1' colspan='13' bgcolor='#CECEFF'></td></tr></table></td></tr><tr><td>&nbsp;</td></tr><tr><td><table width='100%' border='0' cellspacing='0' cellpadding='0'><tr><td width='34%'>"+doc_title+"</td><td width='14%'><div align='center'>"+doc_type+"</div></td><td width='15%'><div align='center'>"+doc_jinji+"</div></td><td width='21%'><div align='center'><font color='#30B133'><strong>"+stepDisplayName_cn+"("+stepDisplayName+")</strong></font></div></td><td width='16%'><div align='center'>"+doc_date+"</div></td></tr></table></td></tr><tr><td>&nbsp;</td></tr></table></td></tr></table></td></tr></table><br><br><br><div align='center'><a href='http://58.60.186.57:8088/hkusz/index.jsp?randpass=pxet6bfj8z4o&UserName="+Email_users+"&red_url=worktray_Doc.jsp' target='_blank'><b>点击这里开始审批(Process Work)</b></a></div><br><br><br><br><div align='right'><strong>资讯科技部</strong><br>OA系统</div>";
//subj ="有新的审批[OA-电脑及相关设备申请]";
System.out.println("Ready to send the document management app's executor email="+toEmail);	
}

else
{
From_name="OA系统(PC申请)";	
msg = "<div align='left'>您好！有新的申请需要您审批，审批信息如下所示。</div><br><br><table width='99%' border='0' align='center' cellpadding='0' cellspacing='1' bgcolor='#2698D6'><tr><td><table width='100%' border='0' cellpadding='0' cellspacing='0' bgcolor='#FFFFFF'><tr><td><table width='98%' border='0' align='center' cellpadding='0' cellspacing='0'><tr><td>&nbsp;</td></tr><tr><td><div align='center'><h3>香港大学深圳医院电脑及相关设备申请审批</h3></div></td></tr><tr><td>&nbsp;</td></tr><tr><td><table width='100%' border='0' cellpadding='0' cellspacing='0'><tr><td width='38%'><div align='center'><strong>申请设备内容</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='20%'><div align='center'><strong>申请人</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='21%'><div align='center'><strong>申请进度</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='21%'><div align='center'><strong>提交时间</strong></div></td></tr><tr><td height='8' colspan='11'></td></tr><tr><td height='1' colspan='11' bgcolor='#CECEFF'></td></tr></table></td></tr><tr><td>&nbsp;</td></tr><tr><td><table width='100%' border='0' cellspacing='0' cellpadding='0'><tr><td width='38%'>"+equ_name+"</td><td width='20%'><div align='center'>"+owner+"</div></td><td width='21%'><div align='center'><font color='#30B133'><strong>"+stepDisplayName_cn+"("+stepDisplayName+")</strong></font></div></td><td width='21%'><div align='center'>"+equ_date+"</div></td></tr></table></td></tr><tr><td>&nbsp;</td></tr></table></td></tr></table></td></tr></table><br><br><br><div align='center'><a href='http://58.60.186.57:8088/hkusz/index.jsp?randpass=pxet6bfj8z4o&UserName="+Email_users+"&red_url=worktray.jsp' target='_blank'><b>点击这里开始审批(Process Work)</b></a></div><br><br><br><br><div align='right'><strong>资讯科技部</strong><br>OA系统</div>" ;
subj ="有新的审批[OA-电脑及相关设备申请]";
}
			//String subj = "[" + Prm.getAppTitle() + " Workflow] New work request (" + stepId + ")";
//By Perry
try{
  if (app.equals("ReceiveApplication")) 
  {
//toEmail="perryc@hku-szh.org";//测试
//Notify send_email = new Notify_gongwen();
Notify.SendEmail("notify_wf@hku-szh.org",toEmail,subj,msg,From_name);
  }
  else
  {
//Notify send_email = new Notify();	  
Notify.SendEmail("notify_wf@hku-szh.org",toEmail,subj,msg,From_name);
   }
 }catch(Exception e){  	
throw new PmpException("Error in sending executor's notification email.");
}
			//Util.sendMailAsyn(pstuser, FROM, executor, null, null, subj, msg, MAILFILE);
		}
	}
	
	

	public static void notifyExecutor_chs(PstUserAbstractObject pstuser,PstFlowDataObject flowDataObj, PstFlow flowObj,String app,String selList_chs)
		throws PmpException
	{
		PstFlowStep stepObj;
		String status, creator, executor,stepDisplayName_cn;
		String From_name="";
		String toEmail="";
		String Email_users="";
		String m_selList_chs=selList_chs.trim();
		int Count=1;//仅发送一次当有多个ACTIVE_STEP
		for (int i=0; i < flowObj.getAttribute(PstFlow.CURRENT_ACTIVE_STEP).length; i++)
		{
			stepObj = (PstFlowStep)fsMgr.get(pstuser, (String)flowObj.getAttribute(PstFlow.CURRENT_ACTIVE_STEP)[i]);
			if (stepObj == null) continue;
			// check to see if stepObj is ready to be executed, if so, send notification
			status = (String)stepObj.getAttribute(PstFlow.STATUS)[0];
			if (!status.equals(PstFlowConstant.ST_STEP_ACTIVE))
				continue;				// not ready (waiting for token)

			// if the user is 'dummy' (auto step), ignore it.
			creator  = (String)stepObj.getAttribute(PstFlowStep.OWNER)[0];
			executor = (String)stepObj.getAttribute(PstFlowStep.CURRENT_EXECUTOR)[0];
			if (executor==null || executor.equals("dummy") || executor.equals(creator))
				continue;
				
				if(Count==1){//仅发送一次
			if(m_selList_chs.indexOf(",")>0){
			String [] executor_chs = m_selList_chs.split(",");
			 for (int s_i=0; s_i<executor_chs.length; s_i++) {
		        if (!executor_chs[s_i].trim().equals("")){
            //toEmail+=executor_chs[s_i].trim()+"@hku-szh.org,";
			String str1[] = executor_chs[s_i].trim().split("@");
			Email_users+=str1[0].trim()+",";
				}
			 }
			//toEmail=toEmail.substring(0,toEmail.length()-1);
			Email_users=Email_users.substring(0,Email_users.length()-1);
			}
			else
			{
			//toEmail=selList_chs+"@hku-szh.org";
			toEmail=selList_chs;
            String str1[] = selList_chs.split("@");			
			Email_users=str1[0].trim();
			}		
			
System.out.println("Ready to send the CC email:" +selList_chs);
//System.out.println("Ready to send the CC email,Email_users:" +Email_users);
		/*	
			try {
			//executor=Integer.parseInt(executor);
		    user u = (user)uMgr.get(pstuser,Integer.parseInt(executor));
			//executor = String.valueOf(u.getObjectId());		// *** change to user id
			//By Perry
			toEmail = u.getStringAttribute("Email");	
			Email_users = toEmail.replace("@hku-szh.org","");
			Email_users = Email_users.replace("@hku.hk","");
			System.out.println("Got the executor's email:" +toEmail);
			}catch (Exception e)
			{
	throw new PmpException("Error in get executor's email.");
			}*/
			// timestamp
			String ts = df.format(new Date());

			String stepId = stepObj.getObjectName();

			// get the step display name
			String s = (String)stepObj.getAttribute(PstFlowStep.FLOW_INSTANCE_NAME)[0];
			PstFlow flowInstance = (PstFlow)fiMgr.get(pstuser, s);
			String flowXML = stepObj.getFlowXML(pstuser);
			HashMap<String,String> stepHash =
				PstUtil.getStepAttributeHashFromXML(flowXML, stepObj);

			String stepDisplayName = PstUtil.getStepAttribute(stepHash, PstFlowConstant.STEP_DISPNAME);
			//(String)sd.getAttribute("DisplayName")[0];
			if (stepDisplayName == null)
				stepDisplayName = PstUtil.getStepAttribute(stepHash, PstFlowConstant.STEP_NAME);

			// get the flow display name
			s  = (String)flowInstance.getAttribute("FlowName")[0];
			PstFlowDef fd = (PstFlowDef)fdMgr.get(pstuser, s);
			String flowDisplayName =(String)fd.getAttribute("DisplayName")[0];
			if (flowDisplayName == null) flowDisplayName = fd.getObjectName();		
/*
			String msg = "A workflow step has arrived your in-tray on " + ts;
			msg += "<blockquote>Process Name: " + flowDisplayName + "</br>";
			msg += "Step Name: " + stepDisplayName + "</blockquote>";
			msg += "Click the following link to access your in-tray and process the work step:";
			msg += "<blockquote><a href='" + NODE + "/project/revw_planchg.jsp?stepId="
					+ stepId + "'><b>Process Work</b></a></blockquote>";*/
			//By Perry:Send the email to executor.			
	Date dt = (Date) flowDataObj.getAttribute("date1")[0];
			String equ_date = "-";
			if (dt != null) {
			equ_date = df.format(dt);
				}
			String equ_name = (String) flowDataObj.getAttribute("string1")[0];
			if (equ_name == null) equ_name = "没有设备列表(None)";
String Jobno ="";
String my_dept ="";						
String owner =flowObj.getStringAttribute(PstFlow.OWNER);
			if (owner != null) {
			user u = (user) uMgr.get(pstuser,Integer.parseInt(owner));
		     //owner = u.getFullName();
			owner = u.getStringAttribute("LastName")+u.getStringAttribute("FirstName");
			Jobno = u.getStringAttribute("Jobno");
			my_dept = u.getStringAttribute("DepartmentName");
			}
switch (stepDisplayName)
{
case "Approval By Department's GM":		
stepDisplayName_cn="部门经理审批" ;
break;
case "Approval By Admin GM":		
stepDisplayName_cn="行政及保障事务部经理审批" ;
break;
case "Approval By IT GM":
stepDisplayName_cn="IT部门经理审批" ;
break;
case "handle the hardware request":
stepDisplayName_cn="IT部门出入库管理员审批" ;
break;
//vacation
case "Approval By Supervisor":
stepDisplayName_cn="上司审批" ;
break;
case "Approval By HR":
stepDisplayName_cn="人力资源部审批" ;
break;
case "Back to Work":
stepDisplayName_cn="员工返岗销假" ;
break;
case "Check on work attendance":
stepDisplayName_cn="考勤人员确认(员工返岗销假)" ;
break;
case "Check on work attendance By Department's GM":
stepDisplayName_cn="部门经理确认(员工返岗销假)" ;
break;
case "Notify HR":
stepDisplayName_cn="人力资源处备案(请假申请已完成)" ;
break;
//Document Management
case "Approval By Administration":
stepDisplayName_cn="院务部拟办意见" ;
break;
case "Approval By Leader":
stepDisplayName_cn="院领导审批" ;
break;
case "Choose Department":
stepDisplayName_cn="承办部门选择" ;
break;
case "Department Comment":
stepDisplayName_cn="承办部门办理意见" ;
break;
case "Additional Comment":
stepDisplayName_cn="是否需要院领导补充意见" ;
break;
case "Additional comments by leader":
stepDisplayName_cn="院领导补充意见" ;
break;
case "Filed":
stepDisplayName_cn="归档" ;
break;
case "Notify Receive":
stepDisplayName_cn="已归档" ;
break;

case "<font color='red'>Rejected</font>":
stepDisplayName_cn="申请被退回" ;
break;
default:	
stepDisplayName_cn="";
}
String msg ="";
String subj ="";
String worktray_lisname ="";
if (app==null) app="";
if (app.equals("VacationApplication"))
{
From_name="OA系统(请假申请)";	
String gonghao=(String) flowDataObj.getAttribute("string1")[0];	
String va_type=(String) flowDataObj.getAttribute("string4")[0];
String time_start=(String) flowDataObj.getAttribute("string19")[0];
String location=(String) flowDataObj.getAttribute("string11")[0];

String day_va_finish= (String) flowDataObj.getAttribute("string9")[0];
String day_va_left= (String) flowDataObj.getAttribute("string10")[0];
String memo= (String) flowDataObj.getAttribute("string12")[0];	
if (gonghao == null) 
{
worktray_lisname = "无(None)";
}
else
{
worktray_lisname ="<strong>请假类型：</strong>"+va_type+"<br><strong>请假时间：</strong><br><strong><font color='blue'>"+time_start+"</font></strong><strong>休假地点：</strong>"+location;
}

if (stepDisplayName.equals("Approval By Supervisor"))
{
String attend_email ="";
msg = "<div align='left'>您好！以下请假申请信息正在开始申请，请假信息如下所示。</div><br><br><table width='99%' border='0' align='center' cellpadding='0' cellspacing='1' bgcolor='#2698D6'><tr><td><table width='100%' border='0' cellpadding='0' cellspacing='0' bgcolor='#FFFFFF'><tr><td><table width='98%' border='0' align='center' cellpadding='0' cellspacing='0'><tr><td>&nbsp;</td></tr><tr><td><div align='center'><h3>香港大学深圳医院请假申请</h3></div></td></tr><tr><td>&nbsp;</td></tr><tr><td><table width='100%' border='0' cellpadding='0' cellspacing='0'><tr><td width='38%'><div align='center'><strong>请假申请内容</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='20%'><div align='center'><strong>申请人</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='21%'><div align='center'><strong>申请进度</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='21%'><div align='center'><strong>提交时间</strong></div></td></tr><tr><td height='8' colspan='11'></td></tr><tr><td height='1' colspan='11' bgcolor='#CECEFF'></td></tr></table></td></tr><tr><td>&nbsp;</td></tr><tr><td><table width='100%' border='0' cellspacing='0' cellpadding='0'><tr><td width='38%'>"+worktray_lisname+"</td><td width='20%'><div align='center'>"+owner+"</div></td><td width='21%'><div align='center'><font color='#30B133'><strong>"+stepDisplayName_cn+"("+stepDisplayName+")</strong></font></div></td><td width='21%'><div align='center'>"+equ_date+"</div></td></tr></table></td></tr><tr><td>&nbsp;</td></tr></table></td></tr></table></td></tr></table><br><br><br><div align='center'></div><br><br><br><br><div align='right'><strong>资讯科技部</strong><br>OA系统</div>" ;
subj ="提示："+owner+"正开始请假申请--"+stepDisplayName_cn+"[OA-请假申请]";
if ("admin".equals(my_dept))
	{
	attend_email="weilj@hku-szh.org";
	}
	else if ("IT".equals(my_dept))
	{
	attend_email="guanmy@hku-szh.org";//zhouj@hku-szh.org
	}	
	else if ("HR".equals(my_dept))
	{
	attend_email="lux@hku-szh.org";//liangyy@hku-szh.org
	}
	else if ("financial".equals(my_dept))
	{
	attend_email="zhongw@hku-szh.org";
	}
	else if ("logistics".equals(my_dept))
	{
	attend_email="renhj@hku-szh.org";
	}
	else if ("relationship".equals(my_dept))
	{
	attend_email="zhengfn@hku-szh.org";
	}
	else if ("public".equals(my_dept))
	{
	attend_email="wangyl5@hku-szh.org";
	}		
	else if ("financial2".equals(my_dept))
	{
	attend_email="shoufkq@hku-szh.org";
	}
	else if ("medical".equals(my_dept))
	{
	attend_email="kedg@hku-szh.org";
	}
	else if ("certification".equals(my_dept))
	{
	attend_email="linmn@hku-szh.org";
	}	
try{
//Notify send_email = new Notify();
Notify.SendEmail("notify_wf@hku-szh.org",attend_email,subj,msg,From_name);		   
 }catch(Exception e){  	
throw new PmpException("Error in sending attendence's notification email.");
}
}

 if (stepDisplayName.equals("Back to Work"))
	{
msg = "<div align='left'>您好！您的请假申请已通过，请确认您的请假信息并<b>请在返岗之日进行以下操作</b>。</div><br><br><table width='99%' border='0' align='center' cellpadding='0' cellspacing='1' bgcolor='#2698D6'><tr><td><table width='100%' border='0' cellpadding='0' cellspacing='0' bgcolor='#FFFFFF'><tr><td><table width='98%' border='0' align='center' cellpadding='0' cellspacing='0'><tr><td>&nbsp;</td></tr><tr><td><div align='center'><h3>香港大学深圳医院请假申请</h3></div></td></tr><tr><td>&nbsp;</td></tr><tr><td><table width='100%' border='0' cellpadding='0' cellspacing='0'><tr><td width='38%'><div align='center'><strong>请假申请内容</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='20%'><div align='center'><strong>申请人</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='21%'><div align='center'><strong>申请进度</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='21%'><div align='center'><strong>提交时间</strong></div></td></tr><tr><td height='8' colspan='11'></td></tr><tr><td height='1' colspan='11' bgcolor='#CECEFF'></td></tr></table></td></tr><tr><td>&nbsp;</td></tr><tr><td><table width='100%' border='0' cellspacing='0' cellpadding='0'><tr><td width='38%'>"+worktray_lisname+"</td><td width='20%'><div align='center'>"+owner+"</div></td><td width='21%'><div align='center'><font color='#30B133'><strong>"+stepDisplayName_cn+"("+stepDisplayName+")</strong></font></div></td><td width='21%'><div align='center'>"+equ_date+"</div></td></tr></table></td></tr><tr><td>&nbsp;</td></tr></table></td></tr></table></td></tr></table><br><br><br><div align='center'><a href='http://58.60.186.57:8088/hkusz/index.jsp?randpass=pxet6bfj8z4o&UserName="+Email_users+"&red_url=worktray.jsp?worktray_type=vacation' target='_blank'><b>点击这里开始操作(Process Work)</b></a></div><br><br><br><br><div align='right'><strong>资讯科技部</strong><br>OA系统</div>" ;
subj =owner+"的请假申请--"+stepDisplayName_cn+"[OA-请假申请]";
//DBAccess.Insert(Jobno,owner,my_dept,va_type,time_start,day_va_finish,day_va_left,location,memo);//原需求返岗销假计入统计，暂取消。
	}
 else
 	{
msg = "<div align='left'>您好！以下请假申请信息需要您的确认及操作，请假信息如下所示。</div><br><br><table width='99%' border='0' align='center' cellpadding='0' cellspacing='1' bgcolor='#2698D6'><tr><td><table width='100%' border='0' cellpadding='0' cellspacing='0' bgcolor='#FFFFFF'><tr><td><table width='98%' border='0' align='center' cellpadding='0' cellspacing='0'><tr><td>&nbsp;</td></tr><tr><td><div align='center'><h3>香港大学深圳医院请假申请</h3></div></td></tr><tr><td>&nbsp;</td></tr><tr><td><table width='100%' border='0' cellpadding='0' cellspacing='0'><tr><td width='38%'><div align='center'><strong>请假申请内容</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='20%'><div align='center'><strong>申请人</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='21%'><div align='center'><strong>申请进度</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='21%'><div align='center'><strong>提交时间</strong></div></td></tr><tr><td height='8' colspan='11'></td></tr><tr><td height='1' colspan='11' bgcolor='#CECEFF'></td></tr></table></td></tr><tr><td>&nbsp;</td></tr><tr><td><table width='100%' border='0' cellspacing='0' cellpadding='0'><tr><td width='38%'>"+worktray_lisname+"</td><td width='20%'><div align='center'>"+owner+"</div></td><td width='21%'><div align='center'><font color='#30B133'><strong>"+stepDisplayName_cn+"("+stepDisplayName+")</strong></font></div></td><td width='21%'><div align='center'>"+equ_date+"</div></td></tr></table></td></tr><tr><td>&nbsp;</td></tr></table></td></tr></table></td></tr></table><br><br><br><div align='center'><a href='http://58.60.186.57:8088/hkusz/index.jsp?randpass=pxet6bfj8z4o&UserName="+Email_users+"&red_url=worktray.jsp?worktray_type=vacation' target='_blank'><b>点击这里开始操作(Process Work)</b></a></div><br><br><br><br><div align='right'><strong>资讯科技部</strong><br>OA系统</div>" ;
subj =owner+"的请假申请--"+stepDisplayName_cn+"[OA-请假申请]";		
	}
}

else if (app.equals("ReceiveApplication"))
{
From_name="公文管理(OA)";	
//String upload_file= (String) flowDataObj.getAttribute("string1")[0];
String doc_title= (String) flowDataObj.getAttribute("string2")[0];
/*String doc_shunxu= (String) flowDataObj.getAttribute("string3")[0];
String doc_zihao= (String) flowDataObj.getAttribute("string4")[0];*/
String doc_other= (String) flowDataObj.getAttribute("string5")[0];
//String doc_company= (String) flowDataObj.getAttribute("string6")[0];
String doc_jinji= (String) flowDataObj.getAttribute("string7")[0];		
//String doc_person= (String) flowDataObj.getAttribute("string8")[0];				
String doc_type= (String) flowDataObj.getAttribute("string9")[0];
String time_start= (String) flowDataObj.getAttribute("string22")[0];
Date doc_time = null;
doc_time = (Date) flowDataObj.getAttribute("date8")[0];
//String buchong = (String) flowDataObj.getAttribute("string10")[0];
if (doc_other==null) doc_other=""; 	
if (doc_type.equals("其他事务")) doc_type="其他事务:"+doc_other;

String doc_date = "-";
if (doc_time != null) doc_date = df2.format(doc_time);

if (time_start== null) time_start="";
 if (!time_start.equals(""))
 {
subj ="抄送:["+doc_jinji+"-("+time_start+"前完成)]"+doc_title;
 }
 else
 {
subj ="抄送:["+doc_jinji+"]"+doc_title;	 
  }

//Notify send_email = new Notify_gongwen();
	if(m_selList_chs.indexOf(",")>0){
	String [] cc_Email_users = Email_users.split(",");	
	String [] executor_chs = m_selList_chs.split(",");
		for (int s_i=0; s_i<executor_chs.length; s_i++) {
			if (!executor_chs[s_i].trim().equals("")) {
msg = "<div align='left'>您好！以下公文正在办理，公文信息如下所示。您可以点击下面的链接持续关注与了解该公文的办理情况。</div><br><br><table width='99%' border='0' align='center' cellpadding='0' cellspacing='1' bgcolor='#2698D6'><tr><td><table width='100%' border='0' cellpadding='0' cellspacing='0' bgcolor='#FFFFFF'><tr><td><table width='98%' border='0' align='center' cellpadding='0' cellspacing='0'><tr><td>&nbsp;</td></tr><tr><td><div align='center'><h3>香港大学深圳医院公文信息</h3></div></td></tr><tr><td>&nbsp;</td></tr><tr><td><table width='100%' border='0' cellpadding='0' cellspacing='0'><tr><td width='34%'><div align='center'><strong>公文标题</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='14%'><div align='center'><strong>事务类型</strong></div></td><td width='0%' bgcolor='#CECEFF'></td><td width='15%'><div align='center'><strong>紧急程度</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='21%'><div align='center'><strong>流转进度</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='16%'><div align='center'><strong>收文日期</strong></div></td></tr><tr><td height='8' colspan='13'></td></tr><tr><td height='1' colspan='13' bgcolor='#CECEFF'></td></tr></table></td></tr><tr><td>&nbsp;</td></tr><tr><td><table width='100%' border='0' cellspacing='0' cellpadding='0'><tr><td width='34%'>"+doc_title+"</td><td width='14%'><div align='center'>"+doc_type+"</div></td><td width='15%'><div align='center'>"+doc_jinji+"</div></td><td width='21%'><div align='center'><font color='#30B133'><strong>"+stepDisplayName_cn+"("+stepDisplayName+")</strong></font></div></td><td width='16%'><div align='center'>"+doc_date+"</div></td></tr></table></td></tr><tr><td>&nbsp;</td></tr></table></td></tr></table></td></tr></table><br><br><br><div align='center'><a href='http://58.60.186.57:8088/hkusz/index.jsp?randpass=pxet6bfj8z4o&UserName="+cc_Email_users[s_i].trim()+"&red_url=view_Doc.jsp?stepId="+stepId+"' target='_blank'><b>点击这里了解该公文办理情况(View the document)</b></a></div><br><br><br><br><div align='right'><strong>资讯科技部</strong><br>OA系统</div>";
//subj ="有新的审批[OA-电脑及相关设备申请]";
System.out.println("Ready to send the document management app's CC email="+executor_chs[s_i].trim());
//System.out.println("Title:"+subj);
//System.out.println("Email content:"+msg);
try{
//Notify send_email = new Notify();
Notify.SendEmail("notify_wf@hku-szh.org",executor_chs[s_i].trim(),subj,msg,From_name);////测试perryc@hku-szh.org
//send_email.SendEmail("notify_wf@hku-szh.org","perryc@hku-szh.org",subj,msg,From_name);		   
 }catch(Exception e){  	
throw new PmpException("Error in sending executor's notification email.");
}	
				
			}	
	    }
	}
	else
	{
msg = "<div align='left'>您好！以下公文正在办理，公文信息如下所示。您可以点击下面的链接持续关注与了解该公文的办理情况。</div><br><br><table width='99%' border='0' align='center' cellpadding='0' cellspacing='1' bgcolor='#2698D6'><tr><td><table width='100%' border='0' cellpadding='0' cellspacing='0' bgcolor='#FFFFFF'><tr><td><table width='98%' border='0' align='center' cellpadding='0' cellspacing='0'><tr><td>&nbsp;</td></tr><tr><td><div align='center'><h3>香港大学深圳医院公文信息</h3></div></td></tr><tr><td>&nbsp;</td></tr><tr><td><table width='100%' border='0' cellpadding='0' cellspacing='0'><tr><td width='34%'><div align='center'><strong>公文标题</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='14%'><div align='center'><strong>事务类型</strong></div></td><td width='0%' bgcolor='#CECEFF'></td><td width='15%'><div align='center'><strong>紧急程度</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='21%'><div align='center'><strong>流转进度</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='16%'><div align='center'><strong>收文日期</strong></div></td></tr><tr><td height='8' colspan='13'></td></tr><tr><td height='1' colspan='13' bgcolor='#CECEFF'></td></tr></table></td></tr><tr><td>&nbsp;</td></tr><tr><td><table width='100%' border='0' cellspacing='0' cellpadding='0'><tr><td width='34%'>"+doc_title+"</td><td width='14%'><div align='center'>"+doc_type+"</div></td><td width='15%'><div align='center'>"+doc_jinji+"</div></td><td width='21%'><div align='center'><font color='#30B133'><strong>"+stepDisplayName_cn+"("+stepDisplayName+")</strong></font></div></td><td width='16%'><div align='center'>"+doc_date+"</div></td></tr></table></td></tr><tr><td>&nbsp;</td></tr></table></td></tr></table></td></tr></table><br><br><br><div align='center'><a href='http://58.60.186.57:8088/hkusz/index.jsp?randpass=pxet6bfj8z4o&UserName="+Email_users+"&red_url=view_Doc.jsp?stepId="+stepId+"' target='_blank'><b>点击这里了解该公文办理情况(View the document)</b></a></div><br><br><br><br><div align='right'><strong>资讯科技部</strong><br>OA系统</div>";
//subj ="有新的审批[OA-电脑及相关设备申请]";
System.out.println("Ready to send the document management app's CC email="+toEmail);
//System.out.println("Email content:"+msg);
try{
//Notify send_email = new Notify();
//Notify send_email = new Notify_gongwen();
  if (app.equals("ReceiveApplication")) 
  {
//toEmail="perryc@hku-szh.org";//测试
Notify.SendEmail("notify_wf@hku-szh.org",toEmail,subj,msg,From_name);
  }
  else
  {  
Notify.SendEmail("notify_wf@hku-szh.org",toEmail,subj,msg,From_name);
   }	   
 }catch(Exception e){  	
throw new PmpException("Error in sending executor's notification email.");
}
	}	

	
}

else
{
From_name="OA系统(PC申请)";	
msg = "<div align='left'>您好！有新的申请需要您审批，审批信息如下所示。</div><br><br><table width='99%' border='0' align='center' cellpadding='0' cellspacing='1' bgcolor='#2698D6'><tr><td><table width='100%' border='0' cellpadding='0' cellspacing='0' bgcolor='#FFFFFF'><tr><td><table width='98%' border='0' align='center' cellpadding='0' cellspacing='0'><tr><td>&nbsp;</td></tr><tr><td><div align='center'><h3>香港大学深圳医院电脑及相关设备申请审批</h3></div></td></tr><tr><td>&nbsp;</td></tr><tr><td><table width='100%' border='0' cellpadding='0' cellspacing='0'><tr><td width='38%'><div align='center'><strong>申请设备内容</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='20%'><div align='center'><strong>申请人</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='21%'><div align='center'><strong>申请进度</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='21%'><div align='center'><strong>提交时间</strong></div></td></tr><tr><td height='8' colspan='11'></td></tr><tr><td height='1' colspan='11' bgcolor='#CECEFF'></td></tr></table></td></tr><tr><td>&nbsp;</td></tr><tr><td><table width='100%' border='0' cellspacing='0' cellpadding='0'><tr><td width='38%'>"+equ_name+"</td><td width='20%'><div align='center'>"+owner+"</div></td><td width='21%'><div align='center'><font color='#30B133'><strong>"+stepDisplayName_cn+"("+stepDisplayName+")</strong></font></div></td><td width='21%'><div align='center'>"+equ_date+"</div></td></tr></table></td></tr><tr><td>&nbsp;</td></tr></table></td></tr></table></td></tr></table><br><br><br><div align='center'><a href='http://58.60.186.57:8088/hkusz/index.jsp?randpass=pxet6bfj8z4o&UserName="+Email_users+"&red_url=worktray.jsp' target='_blank'><b>点击这里开始审批(Process Work)</b></a></div><br><br><br><br><div align='right'><strong>资讯科技部</strong><br>OA系统</div>" ;
subj ="有新的审批[OA-电脑及相关设备申请]";
//By Perry
try{
//Notify send_email = new Notify();
Notify.SendEmail("notify_wf@hku-szh.org",toEmail,subj,msg,From_name);		   
 }catch(Exception e){  	
throw new PmpException("Error in sending executor's notification email.");
}
}
			//String subj = "[" + Prm.getAppTitle() + " Workflow] New work request (" + stepId + ")";
//By Perry
/*try{
Notify send_email = new Notify();
send_email.SendEmail("notify_wf@hku-szh.org",toEmail,subj,msg,From_name);		   
 }catch(Exception e){  	
throw new PmpException("Error in sending executor's notification email.");
}*/
			//Util.sendMailAsyn(pstuser, FROM, executor, null, null, subj, msg, MAILFILE);
			}//发送一次判断结束
	Count++;		
		}
	}

	

	/**
	 * Notify the initiator of the workflow
	 * @param pstuser
	 * @param flowObj
	 * @param app
	 * @throws PmpException
	 */
	public static void notifyPlanSubmitter(PstUserAbstractObject pstuser, PstFlow flowObj, String app)
		throws PmpException
	{
		String creator = (String)flowObj.getAttribute(PstFlow.OWNER)[0];
		String status = (String)flowObj.getAttribute(PstFlow.STATUS)[0];

		try {Integer.parseInt(creator);}
		catch (Exception e)
		{
			user u = (user)uMgr.get(pstuser, creator);
			creator = String.valueOf(u.getObjectId());		// *** change to user id
		}

		// get project id
		String planName = (String)flowObj.getAttribute(PstFlow.CONTEXT_OBJECT)[0];
		String projIdS = (String)planMgr.get(pstuser, planName).getAttribute("ProjectID")[0];

		// timestamp
		String ts = df.format((Date)flowObj.getAttribute(PstFlow.CREATE_DATE)[0]);

		// get the flow display name
		String s  = (String)flowObj.getAttribute("FlowName")[0];
		PstFlowDef fd = (PstFlowDef)fdMgr.get(pstuser, s);
		String flowDisplayName =(String)fd.getAttribute("DisplayName")[0];
		if (flowDisplayName == null) flowDisplayName = fd.getObjectName();

		String msg = "The change request you submitted on " + ts;

		// approved
		String subj = null;
		if (status.equals(PstFlowConstant.ST_FLOW_COMMIT))
		{
			msg += " has been completed and published";
			msg += "<blockquote>Process Name: " + flowDisplayName + "</blockquote>";
			msg += "Click the following link to review the new project plan:";
			msg += "<blockquote><a href='" + NODE + "/project/proj_plan.jsp?projId="
					+ projIdS + "'><b>Review project plan</b></a></blockquote>";
			subj = ") has been approved";
		}
		else if (status.equals(PstFlowConstant.ST_FLOW_ABORT))
		{
			msg += " has been <font color='#cc0000'>rejected</font>";
			msg += "<blockquote>Process Name: " + flowDisplayName + "</blockquote>";
			msg += "Click the following link to review more information:";
			msg += "<blockquote><a href='" + NODE + "/project/revw_planchg.jsp'>"
					+ "<b>Review change requests</b></a></blockquote>";
			subj = ") has been rejected";
		}

		subj = "[" + Prm.getAppTitle() + " Workflow] Project plan change request (" + projIdS + subj;

		Util.sendMailAsyn(pstuser, FROM, creator, null, null, subj, msg, MAILFILE);
	}	// notifyInitiator
	
	
	/**
	 * Get the initiator of this flow instance.
	 * @param userObj - The login user who requests to perform this operation.
	 * @param flowInstanceObj - the flow instance object.
	 * @return user object that is the initiator of this flow instance.
	 * @exception PmpException - error from OMM or Pst.
	 */
	public static user getFlowInitiator(PstUserAbstractObject userObj, PstFlow flowInstanceObj)
		throws PmpException
	{
		// the Owner of the flow instance is the Creator
		if (flowInstanceObj == null || userObj == null) {
			return null;
		}
		
		user initiator = null;
		String initiatorIdS = (String) flowInstanceObj.getStringAttribute("Owner");
		if (initiatorIdS == null) {
			return null;
		}
		initiator = (user) userManager.getInstance().get(userObj, Integer.parseInt(initiatorIdS));
		return initiator;
	}	// END: getFlowInitiator()

	/**
	 * Get the flow instance object from the flow data object.
	 * @param userObj - the login user requesting this service.
	 * @param flowDataObj - the flow data object that the flow instance is associated with.
	 * @return the PstFlow instance object
	 * @throws PmpException
	 */
	public static PstFlow getFlowInstanceFromDataObject(PstUserAbstractObject userObj, PstFlowDataObject flowDataObj)
		throws PmpException
	{
		// use the flowData object to get the flow instance object
		if (flowDataObj == null) {
			l.error("getFlowInstanceFromDataObject() FlowData is NULL.");
			return null;
		}
		PstFlowManager flowMgr = PstFlowManager.getInstance();
		int [] ids = flowMgr.findId(userObj, "ContextObject='" + flowDataObj.getObjectName() + "'");
		if (ids.length <= 0) {
			l.error("getFlowInstanceFromDataObject() cannot find FlowInstance for FlowData ["
					+ flowDataObj.getObjectName() + "]");
			return null;			// can't find any flow object referencing this data object
		}
		PstFlow flowObj = (PstFlow) flowMgr.get(userObj, ids[0]);
		return flowObj;
	}	// END: getFlowInstanceFromDataObject()
	
	/**
	 * Send notification Email to the flow initiator.
	 * @param userObj - the login user requesting this service.
	 * @param flowObj - the flow instance object.
	 * @param subject - the subject of the Email.
	 * @param message - the message content of the Email.
	 * @throws PmpException
	 */
	public static void notifyFlowInitiator(PstUserAbstractObject userObj, PstFlow flowObj,
			String subject, String message)
		throws PmpException
	{
		String From_name="OA系统";
		// notify the flow initiator by Email
		user initiator = getFlowInitiator(userObj, flowObj);
		if (initiator == null) {
			throw new PmpException("notifyFlowInitiator() found NULL flow initiator for flowObj ["
					+ flowObj.getObjectId() + ".");
		}
		String toEmail = initiator.getStringAttribute("Email");
		if (toEmail == null) {
			throw new PmpException("The initiator [" + userObj.getObjectId() + "] has a null Email.");
		}
		
		String fromEmail = userObj.getStringAttribute("Email");		
		//By Perry
try{
Notify send_email = new Notify();
send_email.SendEmail("notify_wf@hku-szh.org",toEmail,subject,message,From_name);
 }catch(Exception e){  	
throw new PmpException("Error in sending notification email.");
}	
		/*if (!Util.sendMailAsyn(fromEmail, toEmail, null, null,
				subject, message, MAILFILE)) {
			throw new PmpException("Error in sending notification email.");
		}*/
	}

public static void notifyReject(PstFlowDataObject flowDataObj,String reject_comment)
	{
		try {
			// send notification email to user
			if (flowDataObj != null) {
				System.out.println("notifyReject: flow data id=" + flowDataObj.getObjectId());
			}
			else {
				System.out.println("notifyReject: flow data is NULL");
			}
			PstSystem pst = PstSystem.getInstance();
			PstFlow flowObj = PrmWf.getFlowInstanceFromDataObject(pst, flowDataObj);
			Date dt = (Date) flowDataObj.getAttribute("date1")[0];
			String equ_date = "-";
			if (dt != null) {
			equ_date = df.format(dt);
				}
			PstUserAbstractObject userObj=pst;
			uMgr = userManager.getInstance();
String Jobno ="";
String my_dept ="";						
String owner =flowObj.getStringAttribute(PstFlow.OWNER);
String From_name="OA系统(请假申请)";
			if (owner != null) {
			user u = (user) uMgr.get(userObj,Integer.parseInt(owner));
		     //owner = u.getFullName();
			owner = u.getStringAttribute("LastName")+u.getStringAttribute("FirstName");
			Jobno = u.getStringAttribute("Jobno");
			my_dept = u.getStringAttribute("DepartmentName");
			}
String msg ="";
String subj ="";
String worktray_lisname ="";				
String gonghao=(String) flowDataObj.getAttribute("string1")[0];	
String va_type=(String) flowDataObj.getAttribute("string4")[0];
String time_start=(String) flowDataObj.getAttribute("string19")[0];
String location=(String) flowDataObj.getAttribute("string11")[0];
String day_va_finish= (String) flowDataObj.getAttribute("string9")[0];
String day_va_left= (String) flowDataObj.getAttribute("string10")[0];
String memo= (String) flowDataObj.getAttribute("string12")[0];	
if (gonghao == null) 
{
worktray_lisname = "无(None)";
}
else
{
worktray_lisname ="<strong>请假类型：</strong>"+va_type+"<br><strong>请假时间：</strong><br>"+time_start+"<strong>休假地点：</strong>"+location;
}
String attend_email ="";
String subject1 =owner+"的请假申请被拒绝--申请被拒绝[OA-请假申请]";
String message1 = "<div align='left'>您好！以下请假申请被拒绝，请重新提交申请。请假信息如下所示。</div><br><br><table width='99%' border='0' align='center' cellpadding='0' cellspacing='1' bgcolor='#2698D6'><tr><td><table width='100%' border='0' cellpadding='0' cellspacing='0' bgcolor='#FFFFFF'><tr><td><table width='98%' border='0' align='center' cellpadding='0' cellspacing='0'><tr><td>&nbsp;</td></tr><tr><td><div align='center'><h3>香港大学深圳医院请假申请</h3></div></td></tr><tr><td>&nbsp;</td></tr><tr><td><table width='100%' border='0' cellpadding='0' cellspacing='0'><tr><td width='38%'><div align='center'><strong>请假申请内容</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='20%'><div align='center'><strong>申请人</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='21%'><div align='center'><strong>申请进度</strong></div></td><td width='0%' bgcolor='#CECEFF'><div align='center'></div></td><td width='21%'><div align='center'><strong>提交时间</strong></div></td></tr><tr><td height='8' colspan='11'></td></tr><tr><td height='1' colspan='11' bgcolor='#CECEFF'></td></tr></table></td></tr><tr><td>&nbsp;</td></tr><tr><td><table width='100%' border='0' cellspacing='0' cellpadding='0'><tr><td width='38%'>"+worktray_lisname+"</td><td width='20%'><div align='center'>"+owner+"</div></td><td width='21%'><div align='center'><font color='#30B133'><strong>申请被拒绝("+reject_comment+")</strong></font></div></td><td width='21%'><div align='center'>"+equ_date+"</div></td></tr></table></td></tr><tr><td>&nbsp;</td></tr></table></td></tr></table></td></tr></table> <br><br><br><br><div align='right'><strong>资讯科技部</strong><br>OA系统</div>" ;
//<br><br><br><div align='center'><a href='http://58.60.186.57:8080/hkusz/index.jsp?randpass=pxet6bfj8z4o&UserName=yangj1&red_url=worktray.jsp?do=admin&worktray_type=vacation' target='_blank'><b>点击这里浏览(Process Work)</b></a></div>
if ("admin".equals(my_dept))
	{
	attend_email="weilj@hku-szh.org";
	}
	else if ("IT".equals(my_dept))
	{
	attend_email="guanmy@hku-szh.org";//zhouj@hku-szh.org
	}	
	else if ("HR".equals(my_dept))
	{
	attend_email="lux@hku-szh.org";//liangyy@hku-szh.org
	}
	else if ("financial".equals(my_dept))
	{
	attend_email="zhongw@hku-szh.org";
	}
	else if ("logistics".equals(my_dept))
	{
	attend_email="renhj@hku-szh.org";
	}
	else if ("relationship".equals(my_dept))
	{
	attend_email="zhengfn@hku-szh.org";
	}
	else if ("public".equals(my_dept))
	{
	attend_email="wangyl5@hku-szh.org";
	}		
	else if ("financial2".equals(my_dept))
	{
	attend_email="shoufkq@hku-szh.org";
	}
	else if ("medical".equals(my_dept))
	{
	attend_email="kedg@hku-szh.org";
	}
	else if ("certification".equals(my_dept))
	{
	attend_email="linmn@hku-szh.org";
	}		
try{
Notify send_email = new Notify();
send_email.SendEmail("notify_wf@hku-szh.org",attend_email,subject1,message1,From_name);
 }catch(Exception e){  	
throw new PmpException("Error in sending notifyReject(attend)'s notification email.");	
 }
PrmWf.notifyFlowInitiator(pst,flowObj,subject1,message1);	
			// all done
			System.out.println(">>> NotifyReject is done!");
			//return new Boolean(true);
		}
		catch(Exception e) {
			e.printStackTrace();
			System.out.println("NotifyReject\n" + e.toString());
			//return new Boolean(false);
		}
	}		
	
}
