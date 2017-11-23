<%@ page contentType="text/html; charset=utf-8"%>

<%
//
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_updtask.jsp
//	Author: ECC
//	Date:		04/05/2004
//	Description:	Update task.
//	Modification:
//		@AGQ101904	Impletemented when Task is Canceled all subtasks are also canceled
//		@AGQ102104	If status changes from New to Open, created date of task is set to today
//		@102504ECC	Add update StartDate.  Note that currently the task implementation doesn't
//					have a StartDate attribute, we use the CreatedDate as a workaround.
//
//		@102604AGQ	Search for ECC:temp these are quick fixes to the time. The current problem
//					we have is with the date is being compared to the nano-second of this moment
//					when instead we want to compare the date.
//					Also made oldStartDate 0:0:0 so it will be compared correctly.
//					Expire Date should have the same problem. Corrected this as well.
//
//		@041805ECC	Send notification to dependent task owners when this task has completed.
//		@ECC092305	Support non-owner to upload files.
//		@ECC112405	Added Duration and Gap to task.
//		@AGQ032806	Support of multiple files
//		@AGQ050306	Support special characters in dates
//		@AGQ050806	Added parse to Expiration dates
//		@ECC011707	Support Department Name in project, task and attachment for authorization.
//		@ECC050207	Check upload file limit from pst properties.  This file has the best error reporting
//					to show that some of the files are uploaded while others are blocked.
//		@ECC060407	Support flexible combination of dept name for attachment authorization.
//		@ECC062007	Send team notification for file upload.  The same option is used for notification of blogs also.
//		@ECC062107	Allow file upload notification email to be sent to alert personnel.
//		@ECC071807	Add optional Subject and Guest list in notification email.
//		@ECC081407	Support Blog Module.  Whether sending notification or not, always store a blog.
//		@ECC112707	Support sending notification to distribution list (DL).
//		@ECC091108	Recalculate and store project space used by attachment in MB at end of upload.
//		@ECC012909	Google docs.
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "oct.util.file.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.PepCommentVector" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>
<%@ page import = "java.net.URLEncoder" %>
<%@ page import = "com.oreilly.servlet.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%!
	boolean isDifferentDates(Date dt1, Date dt2)
	{
		if ( (dt1==null && dt2!=null) ||
			 (dt1!=null && dt2==null) ||
			 (dt1!=null && dt2!=null && dt1.compareTo(dt2)!=0) ) {
			return true;
		}
		return false;
	}
%>

<%
	//double UPLOAD_COST = 0.25;
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	PstUserAbstractObject me = pstuser;
	String repository = Util.getPropKey("pst", "FILE_UPLOAD_PATH");
	
	// 200MB buffer
	MultipartRequest mrequest = new MultipartRequest(request, repository, 200*1024*1024, "UTF-8");

	String taskID = mrequest.getParameter("taskID");
	if ((me instanceof PstGuest) || (taskID == null))
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	String s;

	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ( (iRole & user.iROLE_ADMIN) > 0 )
		isAdmin = true;
	boolean isAcctMgr = ((iRole & user.iROLE_ACCTMGR) > 0 );

	boolean isCRAPP = false;
	String app = (String)session.getAttribute("app");
	if (app.indexOf("CR")!=-1)
		isCRAPP = true;

	// @ECC080108 Multiple company
	boolean isMultiCorp = false;
	s = Util.getPropKey("pst", "MULTICORPORATE");
	if (s!=null && s.equalsIgnoreCase("true"))
		isMultiCorp = true;

	int myUid = me.getObjectId();

	projectManager pjMgr = projectManager.getInstance();
	taskManager tkMgr = taskManager.getInstance();
	userManager uMgr = userManager.getInstance();
	planTaskManager ptMgr = planTaskManager.getInstance();
	dlManager dlMgr = dlManager.getInstance();
	attachmentManager attMgr = attachmentManager.getInstance();

	String projIdS = mrequest.getParameter("projId");
	project pj = (project)pjMgr.get(me, Integer.parseInt(projIdS));
	String projName = pj.getDisplayName();
	boolean bProjectNotStarted = project.ST_NEW.equals(pj.getStringAttribute("Status"));
	
	int pTaskId = Integer.parseInt(mrequest.getParameter("planTaskID"));
	task tkObj = (task)tkMgr.get(me, Integer.parseInt(taskID));

	String oldTaskOwner = (String)tkObj.getAttribute("Owner")[0];
	
	// update task name?
	planTask thisPlanTask = (planTask) ptMgr.get(pstuser, pTaskId);
	String newTaskName = mrequest.getParameter("TaskName");
	if (!StringUtil.isNullOrEmptyString(newTaskName))
		newTaskName = newTaskName.trim();
	else
		newTaskName = null;
	String oldTaskName = thisPlanTask.getStringAttribute("Name");
	if (newTaskName!=null && !newTaskName.equals(oldTaskName)) {
		thisPlanTask.setAttribute("Name", newTaskName);
		ptMgr.commit(thisPlanTask);
	}

	// allow CR to alert on task expiration
	boolean isTaskDeadline = false;
	s = (String)pj.getAttribute("Option")[0];
	if (!isCRAPP || s.contains(project.OP_NOTIFY_TASK))		// either PRM or task notification option ON
		isTaskDeadline = true;

	String deptName = "";	// @060407 DepartmentName string
	String [] deptNames = mrequest.getParameterValues("Departments");
	if (deptNames==null || deptNames.length<=0) deptName = null;
	else for (int i = 0; i<deptNames.length; i++)
	{
		if (deptName.length() > 0) deptName += "@";
		deptName += deptNames[i];
	}

	// @ECC062107 here I need to look at the old task object to determine if
	// alert needs to be sent for upload files: Changed and moved to below.  Use the latest updated alert personnel
/*	Object [] alertPersonArr = tkObj.getAttribute("Alert");		// contains id in string
	if (alertPersonArr[0] == null)
		alertPersonArr = null;		// no alert personnel
*/
	// @ECC062007 send team notification for file upload (also for blogs)
	boolean bSendTeamNotification = false;				// @ECC062007
	String fileLinkS = "";
	String MAILFILE = "alert.htm";
	String host = null;
	String myName = null;
	String nowS = null;
	Object [] userIdArr = null;
	String optStr = (String)pj.getAttribute("Option")[0];
	if (optStr!=null && optStr.indexOf(project.OP_NOTIFY_BLOG)!=-1)
	{
		bSendTeamNotification = true;
		userIdArr = pj.getAttribute("TeamMembers");		// userIdArr was null
	}

	//if (bSendTeamNotification || alertPersonArr!=null)
	//{
	// I need myName and nowS for blog also, so set their values regardless
		host = Util.getPropKey("pst", "PRM_HOST");
		myName = ((user)me).getFullName();
		myName += " (" + me.getObjectName() + ")";

		SimpleDateFormat df0 = new SimpleDateFormat ("MMMMMMMM dd, yyyy (EEE) hh:mm a");
		nowS = df0.format(new Date());
	//}
	// end @ECC062007

	String Owner = mrequest.getParameter("Owner");
	String oriStartDateS = mrequest.getParameter("OriStartDate");
	String oriExpireDateS = mrequest.getParameter("OriExpireDate");
	String ExpireDate = mrequest.getParameter("ExpireDate");
	String StartDate = mrequest.getParameter("StartDate");
	String AlertCondition = mrequest.getParameter("AlertCondition");
	String AlertMessage = mrequest.getParameter("AlertMessage");
	String ChildExpire = mrequest.getParameter("ChildExpire");
	String ChildStart = mrequest.getParameter("ChildStart");
	String ChildOwner = mrequest.getParameter("ChildOwner");
	String Gap = mrequest.getParameter("Gap");
	String Duration = mrequest.getParameter("Dur");
	String weightS = mrequest.getParameter("Weight");
	String [] AlertPersonnel = mrequest.getParameterValues("AlertPersonnel");


	// @ECC062107 handle alert personnel, merge the code for admin and others
	// note that this code has to be after the upload file attachment alert msg handling
	// ECC: No!  We have to move this code before file upload otherwise the alert Email would not pick up the new alert personnel
	Object [] alertPersonArr = null;		// need to reset to null because this was used above
	if (AlertPersonnel != null) {
		alertPersonArr = dlMgr.getUsers(me, AlertPersonnel, true);
	}
	// do file upload first (since non-owner can only do this and nothing else)
	// file attachment upload
// @AGQ032806
	String errMsg = "";
	String sessErrMsg = "";
	int ct = 0;
	int idx;
	int [] ids;
	boolean bReject;
	PstAbstractObject [] linkDocArr = new PstAbstractObject[0];
	Enumeration enumeration = mrequest.getFileNames();
	boolean bUploadFiles = false;
	if (enumeration.hasMoreElements())
	{
		// get all the documents linked to this task
		ids = attMgr.findId(me, "Link='" + taskID + "'");
		linkDocArr = attMgr.get(me, ids);
		bUploadFiles = true;
	}

	// @ECC012909 Google docs
	boolean isGoogle = false;
	PrmGoogle googleHandler = null;
	if (mrequest.getParameter("google") != null)
		isGoogle = true;

	String linkS;
	attachment att, firstAtt=null;
	ArrayList<String> attIdList = new ArrayList<String>();
	
	while (enumeration.hasMoreElements())
	{
		Object name = enumeration.nextElement();
		// file attachment upload
		byte[] utf8Bytes = name.toString().getBytes("UTF8");
		File AttachmentFileObj = mrequest.getFile(new String(utf8Bytes, "UTF8"));

		if (AttachmentFileObj != null)
		{
			// @ECC012909 Google
			if (isGoogle)
			{
				// init the connection to Google server for once only
				if (googleHandler == null)
				{
					try {googleHandler = new PrmGoogle(me);}
					catch (Exception e)
					{
						response.sendRedirect("../out.jsp?e=" + e.getMessage());
						return;
					}
				}

				// upload Google Docs
				linkS = googleHandler.uploadFile(AttachmentFileObj.getPath());

				// create attachment object
				String contentOriginalName = AttachmentFileObj.getName();
				idx = contentOriginalName.lastIndexOf('.');
				String ext = null;
				if (idx != -1) ext = contentOriginalName.substring(idx+1).toLowerCase();	// need this for attachment
				att = (attachment)attMgr.create(me,
						String.valueOf(myUid),
						linkS,
						ext,
						projIdS,
						attachment.TYPE_TASK,
						deptName,
						contentOriginalName);
				attIdList.add(att.getObjectName());

				// store the attachment ID in the task object
				tkObj.appendAttribute("AttachmentID", String.valueOf(att.getObjectId()));
				tkMgr.commit(tkObj);	// need to commit everytime in case I have file upload error for others

				// construct fileLinkS for email notification
				if (fileLinkS.length() > 0) fileLinkS += "<br>";
				fileLinkS += "<li><a class='plaintext' href='" + linkS + "'><u>"
							+ contentOriginalName + "</u></a>";

				ct++;
				continue;
			}

			// upload CR documents
			// error checking: if the filename match any linked file, reject the upload
			bReject = false;
			for (int i=0; i<linkDocArr.length; i++)
			{
				if (Util3.getOnlyFileName(linkDocArr[i]).equalsIgnoreCase(AttachmentFileObj.getName()))
				{
					bReject = true;
					if (sessErrMsg.length() <= 0)
						sessErrMsg = "The following file(s) are not uploaded:<br>";
					sessErrMsg += "- " + AttachmentFileObj.getName() + ": filename collides with a linked file.<br>";
					break;
				}
			}
			if (bReject) continue;

			FileTransfer ft = new FileTransfer(me);
			try
			{
				att = ft.saveFile(tkObj.getObjectId(), projIdS, AttachmentFileObj,
						null, attachment.TYPE_TASK, deptName, null, true);
				tkObj.appendAttribute("AttachmentID", String.valueOf(att.getObjectId()));
				tkMgr.commit(tkObj);	// need to commit everytime in case I have file upload error for others
				attIdList.add(att.getObjectName());
						
				// remember the first file to apply the blog posting as description
				if (firstAtt == null)
					firstAtt = att;

				// @ECC062007 team notification
				//if (bSendTeamNotification || alertPersonArr!=null)
				//{
					if (fileLinkS.length() > 0) fileLinkS += "<br>";
					s = (String)att.getAttribute("Location")[0];
					if ((idx = s.lastIndexOf('/')) != -1)
						s = s.substring(idx+1);
					fileLinkS += "<li><a class='plaintext' href='" + host + "/servlet/ShowFile?attId=" + att.getObjectId() + "'><u>"
								+ s + "</u></a>";
				//}
				ct++;
			}
			catch(Exception e)
			{
				e.printStackTrace();
				String msg = e.getMessage();
				if (msg == null) msg = "";
				errMsg += "<BR>" + msg;
				continue;
			}
		}
	}	// END while upload file loop
	
	
	if (sessErrMsg.length() > 0)
		session.setAttribute("errorMsg", sessErrMsg);		// error message from uploading files

	// @ECC031709 restrictive access: needs to be done before sending Email
	Integer [] restrictArr = null;
	Object [] oArr;
	s = mrequest.getParameter("RestrictIgnore");
	if (s!=null && s.equals("false"))
	{
		// need to consider specification of restrictive access
		s = mrequest.getParameter("RestrictCheck");
		if (s==null || !s.equals("on"))
			tkObj.setAttribute("TeamMembers", null);		// no restrictive access specified
		else
		{
			// get the list of restrictive access people
			String [] restrictMems = mrequest.getParameterValues("RestrictAccess");
			int [] restrictIds = Util2.toIntArray(restrictMems);
			int projOwnerId = Integer.parseInt((String)pj.getAttribute("Owner")[0]);
			int ownerId   = Integer.parseInt(oldTaskOwner);
			int [] owners = {ownerId, projOwnerId};
			restrictIds = Util2.mergeIntArray(restrictIds, owners);
			restrictArr = new Integer[restrictIds.length];
			for (int i=0; i<restrictArr.length; i++)
				restrictArr[i] = new Integer(restrictIds[i]);
			tkObj.setAttribute("TeamMembers", restrictArr);
		}
	}
	oArr = tkObj.getAttribute("TeamMembers");
	boolean isRestrictive = (oArr[0]!=null && ((Integer)oArr[0]).intValue()>0);
	if (isRestrictive && restrictArr==null)
	{
		restrictArr = new Integer[oArr.length];
		for (int i=0; i<oArr.length; i++)
			restrictArr[i] = (Integer)oArr[i];
	}

	// @ECC062007 send team notification before leaving for error message
	// @ECC081507 post a blog whether sending email or not
	if (ct > 0)
	{
		String taskName = (String)ptMgr.get(me, pTaskId).getAttribute("Name")[0];
		String from = (String)me.getAttribute("Email")[0];
		String subj = mrequest.getParameter("OptSubject");
		if (subj != null)
		{
			subj = subj.trim();
		}
		else
		{
			subj = ct + " file";
			if (ct > 1) subj += "s are ";
			else subj += " is ";
			subj += "posted on (" + projName + ")";
		}
		subj = "[" + Prm.getAppTitle() + "] " + subj;

		// @ECC070307a support option alert message for upload file
		String optMsg = "";
		String justMsg = null;
		if (mrequest.getParameter("OptMsg") != null)
		{
			optMsg = justMsg = mrequest.getParameter("message");
			// get optional message
			if (optMsg != null && optMsg.length()>0 && !optMsg.equals("null"))
			{
				optMsg = optMsg.replaceAll("\n", "<br>");
				optMsg = "Message from " + myName + ":<br><div STYLE='font-size: 14px; font-family: Courier New'><br>"
						+ optMsg + "</div><br /><hr>";
			}
			else
				optMsg = "";
		}
		// END @ECC070307a

		StringBuffer msgBuf = new StringBuffer(optMsg);
		msgBuf.append(myName + " has posted " + ct + " new file");
		if (ct > 1) msgBuf.append("s");
		msgBuf.append(" on " + nowS + "<blockquote><table>");
		msgBuf.append("<tr><td class='plaintext' width='80'>PROJECT:</td><td class='plaintext'><a href='" + host + "/project/cr.jsp?projId=");
		msgBuf.append(projIdS + "'><u>" + projName + "</u></a></td></tr>");
		msgBuf.append("<tr><td class='plaintext' width='80'>TASK:</td><td class='plaintext'><a href='" + host + "/project/task_update.jsp?projId=");
		msgBuf.append( projIdS + "&taskId=" + taskID + "'><u>" + taskName + "</u></a></td></tr>");
		msgBuf.append("</table></blockquote>You may click on the following filename to open the ");
		if (isGoogle)
			msgBuf.append("Google Docs");
		else
			msgBuf.append("file");
		msgBuf.append(":<blockquote><ul>");
		msgBuf.append(fileLinkS);
		msgBuf.append("</ul></blockquote>");

		// @ECC071807 Guest email
		String [] guestEmails = null;
		s = mrequest.getParameter("OptGuest");
		if (s!=null && s.trim().length()>0)
		{
			s = s.replaceAll("[,;]", " ");
			guestEmails = s.split(" ");
		}

		if (bSendTeamNotification || alertPersonArr!=null || guestEmails!=null)
		{
			if (isRestrictive)
				userIdArr = restrictArr;
			else
			{
				// support DL (user list)
				String [] uList;
				ArrayList allDLuser = new ArrayList();
				PstAbstractObject o;
				s = mrequest.getParameter("UserList");
				if (s!=null && s.trim().length()>0)
				{
					s = s.replaceAll("[,]", ";");
					uList = s.split(";");
					for (int i=0; i<uList.length; i++)
					{
						// extract the uids from the uList
						try {o = dlMgr.get(me, uList[i].trim());}
						catch (PmpException e) {continue;}
						oArr = o.getAttribute("TeamMembers");
						if (oArr[0] != null)
						for (int j=0; j<oArr.length; j++)
							allDLuser.add(oArr[j]);
					}
				}

				if (alertPersonArr!=null || !allDLuser.isEmpty())
				{
					Object [] mergedIdArr;
					idx = 0;
					if (userIdArr == null) userIdArr = new Object[0];		// userIdArr contains pj team members
					if (alertPersonArr == null) alertPersonArr = new Object[0];	// alertPersonArr contains alert personnel
					if (bSendTeamNotification)
					{
						// merge the recipient id array.  sendMailAsyn() can handle ids either in string or Integer,
						// but userIdArr is in Integer type, so need to convert alertPersonArr also from string to Integer
						// Don't worry about duplicate because EmailThread will eliminate dup.
						mergedIdArr = new Object[userIdArr.length + alertPersonArr.length + allDLuser.size()];
						for (int i=0; i<userIdArr.length; i++)
							mergedIdArr[idx++] = userIdArr[i];		// simply copy over Integer
					}
					else
					{
						mergedIdArr = new Object[alertPersonArr.length + allDLuser.size()];
					}
					for (int i=0; i<alertPersonArr.length; i++)
						mergedIdArr[idx++] = new Integer((String)alertPersonArr[i]);
					for (int i=0; i<allDLuser.size(); i++)
						mergedIdArr[idx++] = allDLuser.get(i);
					userIdArr = mergedIdArr;	// userIdArr pts to the merged array before sending out email
				}
			}
			if (userIdArr == null) {			// might just have guestEmails
				userIdArr = new Object[1];
				userIdArr[0] = from;
			}

			// Email notification on post file
			Util.sendMailAsyn(me, from, userIdArr, null, null,
					subj, msgBuf.toString(), MAILFILE, null, guestEmails, false);
		}

		// @ECC071408 post blog whether sending email or not
		Util2.postBlog(me, result.TYPE_TASK_BLOG, taskID, projIdS, subj, msgBuf.toString(), "utf-8");

		// save the description of posting into the first uploaded file
		if (firstAtt!=null && !StringUtil.isNullOrEmptyString(justMsg)) {
			firstAtt.setAttribute("Description", justMsg.getBytes("utf-8"));
			attMgr.commit(firstAtt);
		}

		
		// save history record for every files user post
		for (String attIdS: attIdList) {
			history.addRecord(me, "HIST.7101",
					null, null,
					projIdS, null, null, null,
					attIdS);
		}

		// @ECC091108 recalculate project space
		if (!isGoogle && isMultiCorp)
		{
	    	UtilThread th = new UtilThread(UtilThread.CAL_PROJ_SPACE, me);
	    	th.setParam(0, projIdS);
	    	th.start();
		}
	}
	// end @ECC062007
	if (errMsg.length() > 0)
	{
		response.sendRedirect("../out.jsp?msg=Failed to upload file." + errMsg
				+ "&go=project/task_update.jsp?projId=" + projIdS + ":pTaskId=" + pTaskId);
		return;
	}

	String newState = mrequest.getParameter("Status");
	if (newState == null)
	{
		// this must be adding file as a non-owner: commit and get out
		tkObj.setAttribute("LastUpdatedDate", new Date());
		session.removeAttribute("planStack");
		tkMgr.commit(tkObj);

		response.sendRedirect("task_update.jsp?projId=" + projIdS
			+ "&taskId=" + taskID + "&pTaskId=" + pTaskId);
		return;
	}


	String format = "MM/dd/yyyy";
	SimpleDateFormat df = new SimpleDateFormat(format);
	Date now = new Date();
	Date today = df.parse(df.format(now));
	Date dt;

	// original plan dates
	// authority has been check on the UI side
	boolean bChangedOriginalPlanDates = false;
	Date oldOriStartDt, oldOriExpireDt;
	Date newOriStartDt=null, newOriExpireDt=null;
	oldOriStartDt = (Date)tkObj.getAttribute("OriginalStartDate")[0];
	oldOriExpireDt = (Date)tkObj.getAttribute("OriginalExpireDate")[0];
	if (oriStartDateS!=null && oriStartDateS.trim().length()>0) {
		newOriStartDt = df.parse(oriStartDateS);
	}
	if (oriExpireDateS!=null && oriExpireDateS.trim().length()>0) {
		newOriExpireDt = df.parse(oriExpireDateS);
	}
	if (isDifferentDates(newOriStartDt, oldOriStartDt) ||
		isDifferentDates(newOriExpireDt, oldOriExpireDt) ) {
		// user has changed the original dates
		bChangedOriginalPlanDates = true;
		tkObj.setAttribute("OriginalStartDate", newOriStartDt);
		tkObj.setAttribute("OriginalExpireDate", newOriExpireDt);

		// should log a history record that original plan dates has changed
	}

	String currentState = (String)tkObj.getAttribute("Status")[0];
	dt = (Date)tkObj.getAttribute("StartDate")[0];
	Date oldStartDate = null;
	if (dt != null) oldStartDate = df.parse(df.format(dt));

	Date StartDateVal = null;
	if (!StringUtil.isNullOrEmptyString(StartDate)) {
		try {
		StartDateVal = df.parse(StartDate);
		} catch (ParseException e) {
			response.sendRedirect("../out.jsp?msg=You cannot set the START DATE to '" + StartDate + "'.");
			return;
		}
	}
	else if (!StringUtil.isNullOrEmptyString(Gap) || !StringUtil.isNullOrEmptyString(Duration))
	{
		StartDateVal = (Date)tkObj.getAttribute("StartDate")[0];
		StartDate = df.format(StartDateVal);
	}
	else if (!currentState.equals(task.ST_NEW) && !isCRAPP)
	{
		response.sendRedirect("../out.jsp?msg=You cannot remove the START DATE except when the task is in the NEW state.");
		return;
	}

	Date ExpireDateVal = null;
	if (ExpireDate != null) {
// @AGQ050806
		try {
			ExpireDateVal = phase.parseStringToDate(ExpireDate, format);
		} catch (ParseException e) {
			response.sendRedirect("../out.jsp?msg=You cannot set the EXPIRATION DATE to: '" + ExpireDate + "'.");
			return;
		}
	}
	else if (Gap!=null || Duration!=null)
	{
		ExpireDateVal = (Date)tkObj.getAttribute("ExpireDate")[0];
		ExpireDate = phase.parseDateToString(ExpireDateVal, format);//df.format(ExpireDateVal);
	}

	int pjOwnerId = Integer.parseInt((String)pj.getAttribute("Owner")[0]);
	
	Double weightDbl = null;
	if (weightS != null) {
		weightDbl = Double.parseDouble(weightS);
	}

	// handle task

	boolean bIgnoreOtherUpdate = false;		// if changing between On-hold & Open, ignore any other updates

	// admin is authorized to update all attributes but without cascade
	if (isAdmin)
	{
		// update all except attachment file
		today = new Date();
		if (newState.equals(task.ST_COMPLETE))
			tkObj.setAttribute("CompleteDate", today);
		else
			tkObj.setAttribute("CompleteDate", null);
		if (ExpireDateVal!=null && newState.equals(task.ST_OPEN) && ExpireDateVal.before(today))
			newState = task.ST_LATE;	// change the requested status

		tkObj.setOwner(me, Owner);
		if (ChildOwner != null)
			Util.setChildrenOwner(me, Owner, pTaskId, tkObj);
		tkObj.setAttribute("Status", newState);
		tkObj.setAttribute("DepartmentName", deptName);
		tkObj.setAttribute("StartDate", StartDateVal);
		tkObj.setAttribute("ExpireDate", ExpireDateVal);
// @AGQ071006 CR returns a null for AlertCondition
		Integer tempI = (AlertCondition!=null)?Integer.valueOf(AlertCondition):null;
		tkObj.setAttribute("AlertCondition", tempI);
// @AGQ022806
		tkObj.setAttribute("Alert", alertPersonArr);
		tkObj.setAttribute("AlertMessage", AlertMessage);
		tkObj.setAttribute("LastUpdatedDate", today);

		if (!StringUtil.isNullOrEmptyString(Gap)) tkObj.setAttribute("Gap", new Integer(Gap));
		if (!StringUtil.isNullOrEmptyString(Duration)) tkObj.setAttribute("Duration", new Integer(Duration));
		if (!StringUtil.isNullOrEmptyString(Gap) || !StringUtil.isNullOrEmptyString(Duration))
			tkObj.setPlanDates(me);
		
		tkObj.setWeight(pj, weightDbl);

		tkMgr.commit(tkObj);
		pj.setAttribute("LastUpdatedDate", today);
		pjMgr.commit(pj);
		session.removeAttribute("planStack");		// cleanup cache
		
		response.sendRedirect("task_update.jsp?projId=" + projIdS
			+ "&taskId=" + taskID + "&pTaskId=" + pTaskId);	// default
		return;
	}

	// cannot change to New
	// *** Not sure about this: "cannot change if it is already Completed"
	if ((newState != null) && !newState.equals(currentState))
	{
		// KEY call: will handle workflow based on old/new state
		try {tkObj.setState(me, newState);}	// will commit task
		catch (PmpException e) {
			response.sendRedirect("../out.jsp?msg=" + e.getMessage());
			return;
		}

		// if the current status is on-hold, we can only update the status to open, ignore all other updates
		/*if (currentState.equals(task.ST_ONHOLD)
			|| newState.equals(task.ST_COMPLETE)
			|| newState.equals(task.ST_ONHOLD))*/
		// Well, whenever I change status except from NEW to OPEN, ignore other update
		if (!currentState.equals(task.ST_NEW) || !newState.equals(task.ST_OPEN))
			bIgnoreOtherUpdate = true;
	}

	// whenever I change status except from NEW to OPEN, ignore other update
	if (!bIgnoreOtherUpdate)
	{
		if(Owner != null)
			tkObj.setOwner(me, Owner);
		if (ChildOwner != null)
			Util.setChildrenOwner(me, Owner, pTaskId, tkObj);

		if ((ExpireDate != null) && (ExpireDate.length() > 0))
		{
			// @102604AGQ
			Date oldExpireDate = (Date)tkObj.getAttribute("ExpireDate")[0];	// ECC: don't need to format

			if (oldExpireDate==null || ExpireDateVal.compareTo(oldExpireDate) != 0)
			{
				// cannot be before today
				if (!isAdmin && !isAcctMgr && !bProjectNotStarted && ExpireDateVal.before(today) && !newState.equals(task.ST_COMPLETE))
				{
					response.sendRedirect("../out.jsp?msg=You cannot set the TASK EXPIRATION DATE to the past.");
					return;
				}

				// cannot be before StartDate BUT can be on the same day
				if (!bProjectNotStarted && StartDateVal!=null && ExpireDateVal.before(StartDateVal))
				{
					response.sendRedirect("../out.jsp?msg=You cannot set the TASK EXPIRATION DATE to before the task Start Date.");
					return;
				}

				// check expire date which cannot be after parent task nor project deadline
				// get parent from my planTask (only need to check immediate parent because the rule is transitive in nature)
				int [] ptId = ptMgr.findId(me, "TaskID='" +taskID+ "' && Status!='Deprecated'");
				Arrays.sort(ptId);		// ascending order
				planTask pt = (planTask)ptMgr.get(me, ptId[ptId.length-1]);
				String parentIdS = (String)pt.getAttribute("ParentID")[0];
				if (parentIdS != null && !parentIdS.equals("0"))
				{
					planTask ptParent = (planTask)ptMgr.get(me, parentIdS);
					task parentTask = (task)tkMgr.get(me, (String)ptParent.getAttribute("TaskID")[0]);
	// @AGQ050306
					if (!phase.isSpecialDate(ExpireDateVal)
							&& parentTask.getAttribute("ExpireDate")[0]!=null
							&& ExpireDateVal.after((Date)parentTask.getAttribute("ExpireDate")[0]))
					{
						//response.sendRedirect("../out.jsp?msg=You cannot set the TASK EXPIRATION DATE to be after the Expiration Date of its parent task.");
						//return;
						// ECC: change the rule, extend the parent if necessary
						// see below for call to checkExtendParent()
					}
				}
				else
				{
					// this is a top task, check and extend project deadline if this is not a container project
					if (!pj.isContainer() &&
							!phase.isSpecialDate(ExpireDateVal) &&
							ExpireDateVal.after((Date)pj.getAttribute("ExpireDate")[0]))
					{
						if (bProjectNotStarted || isAdmin || myUid==pjOwnerId)
						{
							// allow for admin or proj coordinator
							// ECC: move project expiration out accordingly
							pj.setAttribute("ExpireDate", ExpireDateVal);		// commit is at the end
						}
						else
						{
							response.sendRedirect("../out.jsp?msg=You cannot set the TASK EXPIRATION DATE to be after the Expiration Date of the project.");
							return;
						}
					}
				}

				// expire date cannot be before children expiration date.  Only need to check immediate children because
				// the rule is transitive
				if (!bProjectNotStarted && ChildExpire == null)
				{
					ptId = ptMgr.findId(me, "TaskID='" +taskID+ "' && Status!='Deprecated'");
					Arrays.sort(ptId);		// ascending order
					pt = (planTask)ptMgr.get(me, ptId[ptId.length-1]);
					ptId = ptMgr.findId(me, "ParentID='" + pt.getObjectId() + "'");
					for (int i=0; i<ptId.length; i++)
					{
						// for each child task, compare the start date
						pt = (planTask)ptMgr.get(me, ptId[i]);
						task childTask = (task)tkMgr.get(me, (String)pt.getAttribute("TaskID")[0]);
						if (((String)childTask.getAttribute("Status")[0]).equals(task.ST_CANCEL))
							continue;
						dt = (Date)childTask.getAttribute("ExpireDate")[0];	// ECC: don't need to format
						if (ExpireDateVal.before(dt))
						{
							response.sendRedirect("../out.jsp?msg=You cannot set the TASK EXPIRATION DATE to before the subtask ("
								+ (String)pt.getAttribute("Name")[0] + ") expiration date.");
							return;
						}
					}
				}

				tkObj.setAttribute("ExpireDate", ExpireDateVal);
				tkObj.setSaveMyDependentsDates(me);
				tkObj.checkExtendParent(me);

				// if updated from expired to not expired, change status if necessary
				if (tkObj.getAttribute("Status")[0].equals(task.ST_LATE)) {
					// reopen: no need to create workflow
					tkObj.setAttribute("Status", task.ST_OPEN);
				}
			}
		}
		else
		{
			// Expire date should not be null, if so, set it to project's expiration
			// ECC: changed allow null ExpireDate
			//tkObj.setAttribute("ExpireDate", (Date)pj.getAttribute("ExpireDate")[0]);
			tkObj.setAttribute("ExpireDate", null);
		}

		// set children expiration
		if (ChildExpire != null)
		{
			tkObj.setChildrenExpireDate(me, pTaskId);
		}

		///////////////////////////////
		// handle StartDate
		if ((StartDate != null) && (StartDate.length() > 0))
		{

			if (oldStartDate==null || StartDateVal.compareTo(oldStartDate) != 0)
			{
				// must after today
				if (!isAdmin && !isAcctMgr && !bProjectNotStarted && StartDateVal.before(today))
				{
					response.sendRedirect("../out.jsp?msg=You cannot set the TASK START DATE to the past.");
					return;
				}

				// ECC:temp fix for date/time not start from 0:0:0
				dt = (Date)tkObj.getAttribute("ExpireDate")[0];	// ECC: don't need to format
				// must be before my (new) expire date
				if (dt!=null && StartDateVal.after(dt))
				{
					response.sendRedirect("../out.jsp?msg=You cannot set the TASK START DATE to after the task Expiration Date.");
					return;
				}

				// must !before parent start nor after parent expire
				int [] ptId = ptMgr.findId(me, "TaskID='" +taskID+ "' && Status!='Deprecated'");
				Arrays.sort(ptId);		// ascending order
				planTask pt = (planTask)ptMgr.get(me, ptId[ptId.length-1]);
				String parentIdS = (String)pt.getAttribute("ParentID")[0];
				if (parentIdS != null && !parentIdS.equals("0"))
				{
					planTask ptParent = (planTask)ptMgr.get(me, parentIdS);
					task parentTask = (task)tkMgr.get(me, (String)ptParent.getAttribute("TaskID")[0]);

					// ECC:temp fix for date/time not start from 0:0:0
					dt = (Date)parentTask.getAttribute("StartDate")[0];
					if (dt != null)
						dt = df.parse(df.format(dt));
					if (!bProjectNotStarted && dt!=null && StartDateVal.before(dt))
					{
						response.sendRedirect("../out.jsp?msg=You cannot set the TASK START DATE to before the start date of its parent task.");
						return;
					}
					// ECC:temp fix for date/time not start from 0:0:0
					dt = (Date)parentTask.getAttribute("ExpireDate")[0];	// ECC: don't need to format
					if (!bProjectNotStarted && dt!=null && StartDateVal.after(dt))
					{
						response.sendRedirect("../out.jsp?msg=You cannot set the TASK START DATE to be after the expiration date of its parent task.");
						return;
					}
				}
				else
				{
					// ECC:temp fix for date/time not start from 0:0:0
					dt = (Date)pj.getAttribute("StartDate")[0];
					// this is a top task, must !before the project start date
					if (!bProjectNotStarted && StartDateVal.before(dt))
					{
						response.sendRedirect("../out.jsp?msg=You cannot set the TASK START DATE to before the project start date.");
						return;
					}
				}

				// must before my children start date if not moving children task
				// if children tasks are moving along with me, then only check against parent/proj will be fine
				if (!bProjectNotStarted && ChildStart == null && StartDateVal!=null)
				{
					ptId = ptMgr.findId(me, "TaskID='" +taskID+ "' && Status!='Deprecated'");
					Arrays.sort(ptId);		// ascending order
					pt = (planTask)ptMgr.get(me, ptId[ptId.length-1]);
					ptId = ptMgr.findId(me, "ParentID='" + pt.getObjectId() + "'");
					for (int i=0; i<ptId.length; i++)
					{
						// for each child task, compare the start date
						pt = (planTask)ptMgr.get(me, ptId[i]);
						task childTask = (task)tkMgr.get(me, (String)pt.getAttribute("TaskID")[0]);
						dt = (Date)childTask.getAttribute("StartDate")[0];
						if (dt != null) {
							dt = df.parse(df.format(dt));	// ECC: need to format because old data has non 0:0 time
							if (StartDateVal.after(dt))
							{
								response.sendRedirect("../out.jsp?msg=You cannot set the TASK START DATE to after the subtask ("
									+ (String)pt.getAttribute("Name")[0] + ") start date.");
								return;
							}
						}
					}
				}

				tkObj.setAttribute("StartDate", StartDateVal);

				// if updated StartDate to today and Status is New, change status to Open
				if (tkObj.getAttribute("Status")[0].equals(task.ST_NEW)
					&& StartDateVal!=null && !StartDateVal.after(today))
				{
					s = tkObj.getParentTaskStatus(me);
					if (!bProjectNotStarted && s!=null && !s.equals(task.ST_OPEN))
					{
						response.sendRedirect("../out.jsp?msg=You cannot set the Start Date of this task to today unless its parent task is in the Open state.");
						return;
					}

					// changing StartDate may auto move a task to OPEN
					// move to OPEN: create workflow step
					try {tkObj.setState(me, task.ST_OPEN);}	// will commit task
					catch (PmpException e) {
						response.sendRedirect("../out.jsp?msg=" + e.getMessage());
						return;
					}
				}

				// if updated StartDate to future and Status is Open, change status to New
				if (tkObj.getAttribute("Status")[0].equals(task.ST_OPEN)
					&& StartDateVal!=null && StartDateVal.after(today))
					{
						// don't worry about children start date must be on or after mine; it is checked above
						tkObj.setAttribute("Status", task.ST_NEW);

						// leave the created step alone
					}
			}
		}
		else
		{
			// Start date should not be null, if so, set it to project's startDate
			// ECC changed: allow null start date for container
			//tkObj.setAttribute("StartDate", (Date)pj.getAttribute("StartDate")[0]);
			tkObj.setAttribute("StartDate", null);
		}

		// @ECC11240
		if (!StringUtil.isNullOrEmptyString(Gap) || !StringUtil.isNullOrEmptyString(Duration))
		{
			Integer iGap=null, iDur=null;
//System.out.println("gap=" + Gap);			
			if (!StringUtil.isNullOrEmptyString(Gap))
			{
				iGap = new Integer(Gap);
				tkObj.setAttribute("Gap", iGap);
			}
			if (!StringUtil.isNullOrEmptyString(Duration))
			{
				iDur = new Integer(Duration);
				tkObj.setAttribute("Duration", iDur);
			}
			if (iGap!=null && iDur!=null)
				tkObj.setPlanDates(me);
		}
		else
		{
			tkObj.setAttribute("Gap", null);
			tkObj.setAttribute("Duration", null);
		}

		// set children Start Date
		if (ChildStart != null) {
			tkObj.setChildrenStartDate(me, pTaskId);
		}

		// alert
		if (!isCRAPP || isTaskDeadline) {
			tkObj.setAttribute("AlertCondition", Integer.valueOf(AlertCondition));
			tkObj.setAttribute("AlertMessage", AlertMessage);
		}
	//		 @AGQ022806
		// ECC: move the following outside of the !isCRAPP condition
		// to allow alert personnel for CR also
		tkObj.setAttribute("Alert", alertPersonArr);	// alertPersonArr can be null

	}	// endif !ignoreOtherUpdate

	//  @ECC011707
	tkObj.setAttribute("DepartmentName", deptName);
	
	tkObj.setWeight(pj, weightDbl);

	// option: task blog id
	s = mrequest.getParameter("TaskBlogId");
	if (!StringUtil.isNullOrEmptyString(s)) {
		try {
			s = s.trim();
			Integer.parseInt(s);
			tkObj.setOption(task.TASK_BLOG_ID, s);		// valid int
		}
		catch (Exception e) {/*ignore*/}
	}
	else {
		tkObj.setOption(task.TASK_BLOG_ID, null);	// unset
	}


	// commit the task object
	today = new Date();
	tkObj.setAttribute("LastUpdatedDate", now);
	tkMgr.commit(tkObj);

	// the project has been updated
	pj.setAttribute("LastUpdatedDate", now);
	pjMgr.commit(pj);

	session.removeAttribute("planStack");		// cleanup cache

	if (bUploadFiles) {
		// for uploading files, stay on the task update page
		response.sendRedirect("task_update.jsp?projId=" + projIdS
			+ "&taskId=" + taskID + "&pTaskId=" + pTaskId);	// default
	}
	else {
		// for other task updates, go back to proj_plan.jsp
		response.sendRedirect("proj_plan.jsp?projId=" + projIdS
				+ "&boTaskId=" + taskID);
	}
%>
