
//
//  Copyright (c) 2004, EGI Technologies.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   Util.java
//  Author:
//  Date:   10/08/2004
//  Description:
//
//  Modification:
//			@AGQ101904
//				Enforce State transition diagram for tasks
//			@102504AGQ
//				Subtasks that are Canceled & On-hold will not have a completedDate
//				 when the Task status is set to Completed
//			@040405ECC
//				Move all alerts from result organization to memo organization.
//			@AGQ030606
//				Added sortUserArray method and changed concatination to use StringBuffer
//			@AGQ030806
//				Implemented function to include bcc true or false value
//			@AGQ030906
//				Extra a string of guestEmails into an array of Strings
//			@AGQ040706
//				Detect attributes for null before casting into String or other objects
//			@AGQ040706a
//				Supports reverse on sorting algorithm
//			@AGQ040706b
//				Detects Empty string from prioity array and
//				gives a priority value to null values
//			@AGQ041306
//				sortString method can ignoreCase
//			@AGQ041906
//				sortName method can ignoreCase
//			@AGQ051106
//				Created sortInteger method
//			@SWS090606
//				Created method to generate username append by number if duplicate.
//			@AGQ092806
//				FCKeditor escaping spaces
//
/////////////////////////////////////////////////////////////////////
//
// Util.java : implementation of the Util class for PRM
//

package util;

import java.io.File;
import java.io.InputStream;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.Properties;
import java.util.Random;
import java.util.TreeSet;

import javax.activation.DataSource;
import javax.servlet.http.HttpSession;

import org.apache.log4j.Logger;
import org.jasypt.encryption.pbe.StandardPBEStringEncryptor;
import org.jasypt.properties.EncryptableProperties;

import oct.codegen.FlowDataManager;
import oct.codegen.actionManager;
import oct.codegen.attachment;
import oct.codegen.attachmentManager;
import oct.codegen.chatManager;
import oct.codegen.dl;
import oct.codegen.dlManager;
import oct.codegen.latest_resultManager;
import oct.codegen.meeting;
import oct.codegen.memo;
import oct.codegen.memoManager;
import oct.codegen.phaseManager;
import oct.codegen.planManager;
import oct.codegen.planTask;
import oct.codegen.planTaskManager;
import oct.codegen.project;
import oct.codegen.projectManager;
import oct.codegen.result;
import oct.codegen.resultManager;
import oct.codegen.task;
import oct.codegen.taskManager;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.codegen.userinfo;
import oct.codegen.userinfoManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstFlowManager;
import oct.pst.PstFlowStepManager;
import oct.pst.PstGuest;
import oct.pst.PstManager;
import oct.pst.PstUserAbstractObject;

public class Util
{
	static Logger l = PrmLog.getLog();
	private static final String EMAILDELIMREG = "[,;]";
	private static final String SPACE = " ";
	private static final char BLANKCHAR = ' ';
	private static final String SPACESTRING = "&nbsp;";
	private static final String SPACESTRINGAMP = "&amp;nbsp;";
	private static final char QUOTECHAR = '"';
	private static final String QUOTESTRING = "&quot;";
	private static final char AMPCHAR = '&';
	private static final String AMPSTRING = "&amp;";
	private static final char LESSTHANCHAR = '<';
	private static final String LESSTHANSTRING = "&lt;";
	private static final char GREATERTHANCHAR = '>';
	private static final String GREATERTHANSTRING = "&gt;";
	private static final char DOLLARCHAR = '$';
	private static final String DOLLARSTRING = "&#36;";
	private static final char NEWLINECHAR = '\n';
	//private static final String NEWLINESTRING = "&lt;br/&gt;";
	private static final String ENTITY = "&#";
	private static final char SEMICOLONCHAR = ';';
	private static final char APOSCHAR = '\'';
	private static final String APOSSTRING = "&#39;";
	private static final String STRAIGHTLINES = "|||";

	private static final String DATEMONTH = "MM";
	private static final SimpleDateFormat CHECKER = new SimpleDateFormat(DATEMONTH);
	private static final String HOST		= Util.getPropKey("pst", "PRM_HOST");

	public static int m_loginNum = 0;

	private static userManager uMgr;
	private static resultManager rMgr;
	private static projectManager pjMgr;
	
	private static StandardPBEStringEncryptor encryptor;

	static {
		try {
			uMgr = userManager.getInstance();
			rMgr = resultManager.getInstance();
			pjMgr = projectManager.getInstance();
		}
		catch (PmpException e) {}
	}

	public static String skipAPosCharacter(String str)
	{
		String skipStr = new String();
		for(int i = 0; i < str.length(); i++)
		{
			char[] character = new char[1];
			character[0] = str.charAt(i);
			if(str.charAt(i) == '\'')
				skipStr = skipStr + "\\";
			skipStr = skipStr + new String(character);
		}
		return skipStr;
	}

	// createAlert
	public static memo createAlert(
		PstUserAbstractObject uObj,
		String		subject,
		String		alertMsg,
		int			creatorId,
		String		alertType,
		int			projId,
		int			taskId,				// taskId
		String		alertPersonnelId	// user idS array
		)
	{
		String [] alertPersonnel = new String[1];
		alertPersonnel[0] = alertPersonnelId;
		return createAlert(uObj,subject,alertMsg,creatorId,alertType,projId,taskId,alertPersonnel);
	}

	// createAlert
	public static memo createAlert(
		PstUserAbstractObject uObj,
		String		subject,
		String		alertMsg,
		int			creatorId,
		String		alertType,
		int			projId,
		int			taskId,				// taskId
		Object []	alertPersonnel		// user idS array
		)
	{
		if (Prm.isPRM()) return null;

		memo memoObj = null;

		try
		{
		memoManager mMgr = memoManager.getInstance();
		memoObj = (memo)mMgr.create(uObj);
		Date today = new Date();

		memoObj.setAttribute("Name", subject);
		memoObj.setAttribute("Comment", alertMsg.getBytes());
		memoObj.setAttribute("CreatedDate", today);
		memoObj.setAttribute("Creator", String.valueOf(creatorId));
		//memoObj.setAttribute("Type", alertType);		// Alert vs. Blog (=Town, Project, Task)
		if (projId > 0)
			memoObj.setAttribute("ProjectID", String.valueOf(projId));
		if (taskId > 0)
			memoObj.setAttribute("TaskID", String.valueOf(taskId));	// TaskID is used to store townId or taskId

		memoObj.setAttribute("Alert", alertPersonnel);

		mMgr.commit(memoObj);		// save to disk
		}
		catch (PmpException e)
		{
			e.printStackTrace();
			System.out.println("Exception in Util.createAlert: " + e.toString() );
		}
		return memoObj;
	}

	// sendMailAsyn with multipart graphics
	public static boolean sendMailAsyn(
		String		from,
		String		recipient,			// single email addresses
		String		cc,
		String		bcc,
		String		subject,
		String		msgBody,
		String		htmlFileName,
		DataSource	[] dsArr
		)
	{
		return sendMailAsyn(null, from, recipient, cc, bcc, subject, msgBody, htmlFileName, dsArr);
	}

	// sendMailAsyn
	public static boolean sendMailAsyn(
		String		from,
		String		recipient,			// single email addresses
		String		cc,
		String		bcc,
		String		subject,
		String		msgBody,
		String		htmlFileName
		)
	{
		return sendMailAsyn(null, from, recipient, cc, bcc, subject, msgBody, htmlFileName, null);
	}

	public static boolean sendMailAsyn(
			PstUserAbstractObject u,
			String		from,
			String		recipient,			// array of email addresses or user id
			String		cc,
			String		bcc,
			String		subject,
			String		msgBody,
			String		htmlFileName
			)
	{
		return sendMailAsyn(u, from, recipient, cc, bcc, subject, msgBody, htmlFileName, null);
	}

	public static boolean sendMailAsyn(
		PstUserAbstractObject u,
		String		from,
		String		recipient,			// single email addresses
		String		cc,
		String		bcc,
		String		subject,
		String		msgBody,
		String		htmlFileName,
		DataSource	[] dsArr
		)
	{
		Object [] recArray = new String[1];
		recArray[0] = recipient;
		return sendMailAsyn(u, from, recArray, cc, bcc, subject, msgBody, htmlFileName, dsArr);
	}

	// sendMailAsyn: passing in email addresses directly
	public static boolean sendMailAsyn(
		String		from,
		Object []	recipient,			// array of email addresses
		String		cc,
		String		bcc,
		String		subject,
		String		msgBody,
		String		htmlFileName
		)
	{
		return sendMailAsyn(null, from, recipient, cc, bcc, subject, msgBody, htmlFileName, null);
	}
// @AGQ030606
	public static boolean sendMailAsyn(
			PstUserAbstractObject u,
			String		from,
			Object []	recipient,			// array of email addresses or user id
			String		cc,
			String		bcc,
			String		subject,
			String		msgBody,
			String		htmlFileName
			)
	{
		return sendMailAsyn(u, from, recipient, cc, bcc, subject, msgBody, htmlFileName, null, null);
	}
// @AGQ030606
	public static boolean sendMailAsyn(
			PstUserAbstractObject u,
			String		from,
			Object []	recipient,			// array of email addresses or user id
			String		cc,
			String		bcc,
			String		subject,
			String		msgBody,
			String		htmlFileName,
			Object []	guestEmails
			)
	{
		return sendMailAsyn(u, from, recipient, cc, bcc, subject, msgBody, htmlFileName, null, guestEmails);
	}
// @AGQ030606
	public static boolean sendMailAsyn(
			PstUserAbstractObject u,
			String		from,
			Object []	recipient,			// array of email addresses or user id
			String		cc,
			String		bcc,
			String		subject,
			String		msgBody,
			String		htmlFileName,
			DataSource	[] dsArr
			)
	{
		return sendMailAsyn(u, from, recipient, cc, bcc, subject, msgBody, htmlFileName, dsArr, null);
	}
// @AGQ030806
	public static boolean sendMailAsyn(
			PstUserAbstractObject u,
			String		from,
			Object []	recipient,			// array of email addresses or user id
			String		cc,
			String		bcc,
			String		subject,
			String		msgBody,
			String		htmlFileName,
			DataSource [] dsArr,
			Object []	guestEmails
			)
	{
		return sendMailAsyn(u, from, recipient, cc, bcc, subject, msgBody, htmlFileName, dsArr, guestEmails, false);
	}

	public static boolean sendMailAsyn(
		PstUserAbstractObject u,
		String		from,
		Object []	recipient,			// array of email addresses or user id
		String		cc,
		String		bcc,
		String		subject,
		String		msgBody,
		String		htmlFileName,
		DataSource [] dsArr,
		Object []	guestEmails,
		boolean		bHidden
		)
	{
		return sendMailAsyn(u, from, recipient, cc, bcc, subject, msgBody, htmlFileName, dsArr, guestEmails, false, null);
	}

	public static boolean sendMailAsyn(
		PstUserAbstractObject u,
		String		from,
		Object []	recipient,			// array of email addresses or user id
		String		cc,
		String		bcc,
		String		subject,
		String		msgBody,
		String		htmlFileName,
		DataSource [] dsArr,
		Object []	guestEmails,
		boolean		bHidden,
		String		contentType
		)
	{
		try
		{
			if (u != null)
			{
				// convert user id to email
				if (recipient.length > 0)
				{
					ArrayList arrList = new ArrayList();
					user r;
					String emailAddr;
					if (recipient[0] instanceof Integer)
					{
						// the array is user ids in Integer class
						for (int i=0; i<recipient.length; i++)
						{
							if (recipient[i] == null) continue;
							try{
								r = (user)uMgr.get(u, ((Integer)recipient[i]).intValue());
								emailAddr = r.getStringAttribute("Email");
								if (emailAddr != null)
									arrList.add(emailAddr);	// assume Email attribute
							} catch (PmpException ee)
							{
								System.out.println("Util.sendMailAsyn error in getting user: " + recipient[i]);
								continue;
							}
						}
					}
					else if (recipient[0]!=null && ((String)recipient[0]).indexOf("@") != -1)
					{
						// Straight emails
						for (int i=0; i<recipient.length; i++)
						{
							if (recipient[i] == null) continue;
							arrList.add(recipient[i]);
						}
					}
					else
					{
						// assume the array is all user ids
						for (int i=0; i<recipient.length; i++)
						{
							if (StringUtil.isNullOrEmptyString((String)recipient[i])) continue;
							try{
								r = (user)uMgr.get(u, Integer.parseInt((String)recipient[i]));
								emailAddr = r.getStringAttribute("Email");
								if (emailAddr != null)
									arrList.add(emailAddr);	// assume Email attribute
							} catch (PmpException ee)
							{
								System.out.println("Util.sendMailAsyn error in getting user: " + recipient[i]);
								continue;
							}
						}
					}
// @AGQ030606
					arrList = appendGuestEmails(arrList, guestEmails);
					// Convert ArrayList back to Object[]
					recipient = arrList.toArray();
				}
				else
				{
					// empty TO list: set TO list to FROM
					ArrayList arrList = new ArrayList();
					arrList.add(from);
// @AGQ030606
					arrList = appendGuestEmails(arrList, guestEmails);
					recipient = arrList.toArray();
				}
			}

			EmailThread eth = new EmailThread(
				"Mail Thread", recipient, from, cc, bcc, subject, msgBody, htmlFileName, bHidden, dsArr);
			if (contentType != null) {
				eth.setContentType(contentType);
			}
			eth.start();
		}
		catch (Exception e)
		{
			System.out.println( "Exception in Util.sendMailAsyn: " + e.toString() );
			e.printStackTrace();
			return false;
		}
		//System.out.println("Send Mail by "+from);
		return true;
	}

	// sendJWMail: send mail to the entire JW community and hide the names
	public static boolean sendJWMail(
		PstUserAbstractObject uObj,
		String		from,
		String		subject,
		String		msgBody,
		String		htmlFileName
		)
	{
		try
		{
			// get all the people in JW
			String [] allPeople = userManager.getInstance().findName(uObj, "om_acctname='%'");
			EmailThread eth = new EmailThread(
				"Mail Thread", allPeople, from, null, null, subject, msgBody, htmlFileName, true);
			eth.start();
		}
		catch (Exception e)
		{
			System.out.println( "Exception in Util.sendJWMail: " + e.toString() );
			return false;
		}
		System.out.println("Send PRM Mail by "+from);
		return true;
	}

	public static void deleteProject(PstUserAbstractObject pstuser, int pjId)
		throws PmpException
	{
		// project		-	(TownID)
		// plan			-	(ProjectID)
		// planTask 	-	(PlanID)
		// task			-	(ProjectID)
		// result		-	(TaskID)
		// latest_result-	(TaskID)
		// distri. list
		// chat

		planManager plMgr		= planManager.getInstance();
		planTaskManager ptMgr	= planTaskManager.getInstance();
		taskManager tkMgr		= taskManager.getInstance();
		latest_resultManager lrMgr	= latest_resultManager.getInstance();
		FlowDataManager fdMgr	= FlowDataManager.getInstance();
		PstFlowManager fiMgr	= PstFlowManager.getInstance();
		PstFlowStepManager fsMgr = PstFlowStepManager.getInstance();
		actionManager aMgr		= actionManager.getInstance();
		attachmentManager attMgr = attachmentManager.getInstance();
		dlManager dlMgr			= dlManager.getInstance();
		phaseManager phMgr		= phaseManager.getInstance();
		chatManager cMgr				= chatManager.getInstance();

		project pj = (project)pjMgr.get(pstuser, pjId);
		String townIdS = (String)pj.getAttribute("TownID")[0];
		String pjName = PstManager.getNameById(pstuser, pjId);

		// get the properties for file deletion
		String FILE_CONFIG_NAME = "pst";
		String FILE_PATH = "FILE_UPLOAD_PATH";
		String ARCHIVE_PATH = "ARCHIVE_PATH";
//		ResourceBundle filebundleFile = ResourceBundle.getBundle(FILE_CONFIG_NAME);
//		String repository = filebundleFile.getString(FILE_PATH);	// Repository/JW
//		String archive = filebundleFile.getString(ARCHIVE_PATH);	// Repository/Archive
		
		String repository = getPropKey(FILE_CONFIG_NAME, FILE_PATH);
		String archive = getPropKey(FILE_CONFIG_NAME, ARCHIVE_PATH);
		
		String pathName;
		File f;
		File [] fList;
		String upPath = Util.getPropKey("pst", "FILE_UPLOAD_PATH");	// Repository/PRM

		// get and delete the plans
		int [] planIds =  plMgr.findId(pstuser, "ProjectID='"+pjId+"'");
		for (int i=0; i<planIds.length; i++)
		{
			// get and delete the planTasks
			int [] ptaskIds = ptMgr.findId(pstuser, "PlanID='"+planIds[i]+"'");
			for (int j=0; j<ptaskIds.length; j++)
				ptMgr.delete(ptMgr.get(pstuser, ptaskIds[j]));

			// delete workflow obj: FlowData, PstFlow, PstFlowStep objects
			int [] ids = fdMgr.findId(pstuser, "string2='"+planIds[i]+"'");
			for (int j=0; j<ids.length; j++)
			{
				fdMgr.delete(fdMgr.get(pstuser, ids[j]));
			}
			int [] ids1 = fiMgr.findId(pstuser, "ContextObject='"+planIds[i]+"'");
			for (int j=0; j<ids1.length; j++)
			{
				fiMgr.delete(fiMgr.get(pstuser, ids1[j]));
				int [] ids2 = fsMgr.findId(pstuser, "FlowInstanceName='"+ids1[j]+"'");
				for (int k=0; k<ids2.length; k++) {
					try {fsMgr.delete(fsMgr.get(pstuser, ids2[k]));}
					catch (PmpException e) {}
				}
			}

			// now delete the plan
			plMgr.delete(plMgr.get(pstuser, planIds[i]));
		}

		// delete the flow instance of this project
		int [] ids = fiMgr.findId(pstuser, "ContextObject='" + pjId + "'");
		if (ids.length > 0) {
			fiMgr.delete(fiMgr.get(pstuser, ids[0]));
		}

		// delete task steps of this project
		ids = fsMgr.findId(pstuser, "ProjectID='" + pjId + "'");
		for (int i=0; i<ids.length; i++) {
			try {fsMgr.delete(fsMgr.get(pstuser, ids[i]));}
			catch (PmpException e) {}
		}

		// delete all tasks, task results and latest_result
		int [] tkIds = tkMgr.findId(pstuser, "ProjectID='"+pjId+"'");
		for (int i=0; i<tkIds.length; i++)
		{
			// get and delete task weblog and its comments
			int [] rsIds = rMgr.findId(pstuser, "TaskID='"+tkIds[i]+"'");
			for (int j=0; j<rsIds.length; j++)
			{
				int [] child = rMgr.findId(pstuser, "ParentID='" + rsIds[j] + "'");
				for (int k=0; k<child.length; k++)
					rMgr.delete(rMgr.get(pstuser, child[k]));	// delete blog comments

				// remove all attachmentObject related to blog
				result rObj = (result) rMgr.get(pstuser, rsIds[j]);
				Object [] objArr = rObj.getAttribute("AttachmentID");
				for (int k=0; k<objArr.length; k++) {
					if (objArr[k] != null) {
						int aId = Integer.parseInt(objArr[k].toString());
						try {attachment aObj = (attachment)attMgr.get(pstuser, aId);
						attMgr.delete(aObj);}
						catch (PmpException e) {}
					}
				}

				upPath += File.separator + rsIds[j];
				f = new File(upPath);
				fList = f.listFiles();
				if (fList != null)
				{
					for (int k=0; k<fList.length; k++)
						fList[k].delete();
				}
				f.delete();

				rMgr.delete(rObj);
			}

			// get and delete latest_result
			int [] lrsIds = lrMgr.findId(pstuser, "TaskID='"+tkIds[i]+"'");
			for (int j=0; j<lrsIds.length; j++)
				lrMgr.delete(lrMgr.get(pstuser, lrsIds[j]));

			// remove all attachmentObject related to task
			task tObj = (task) tkMgr.get(pstuser, tkIds[i]);
			Object [] objArr = tObj.getAttribute("AttachmentID");
			for (int j=0; j<objArr.length; j++) {
				if (objArr[j] != null) {
					int aId = Integer.parseInt(objArr[j].toString());
					try {attachment aObj = (attachment)attMgr.get(pstuser, aId);
					attMgr.delete(aObj);}
					catch (PmpException e) {}
				}
			}

			tkMgr.delete(tObj);

			// delete files attached to this task (directory: Repository/JW/tkId)
			pathName = repository + File.separator + tkIds[i];
			f = new File(pathName);
			fList = f.listFiles();
			if (fList != null)
				for (int j=0; j<fList.length; j++)
					fList[j].delete();
			f.delete();

			// delete archived weblogs of this task (file: Repository/Archive/townId/tkId*.jsp)
			String tkidS = String.valueOf(tkIds[i]);
			pathName = archive + File.separator + townIdS;
			f = new File(pathName);
			fList = f.listFiles();
			if (fList != null)
			{
				for (int j=0; j<fList.length; j++)
				{
					if (fList[j].getName().indexOf(tkidS) != -1)
						fList[j].delete();
				}
			}
		}

		// delete project weblogs
		int [] rsIds = rMgr.findId(pstuser, "TaskID='"+pjId+"'");	// TaskID is used to store projId also
		for (int i=0; i<rsIds.length; i++) {
// @AGQ070706
			// delete files attached to this blog
			String s = Util.getPropKey("pst", "FILE_UPLOAD_PATH");	// Repository/PRM
			s += File.separator + rsIds[i];
			f = new File(s);
			fList = f.listFiles();
			if (fList != null)
			{
				for (int j=0; j<fList.length; j++)
					fList[j].delete();
			}
			f.delete();				// delete the blogId directory

			// remove all attachmentObject related to Blog
			result rObj = (result) rMgr.get(pstuser, rsIds[i]);
			Object [] objArr = rObj.getAttribute("AttachmentID");
			for (int j=0; j<objArr.length; j++) {
				if (objArr[j] != null) {
					int aId = Integer.parseInt(objArr[j].toString());
					try {attachment aObj = (attachment)attMgr.get(pstuser, aId);
					attMgr.delete(aObj);}
					catch (PmpException e) {}
				}
			}

			rMgr.delete(rObj);
		}

		// delete project weblogs' latest_result
		int [] lrsIds = lrMgr.findId(pstuser, "TaskID='"+pjId+"'");
		for (int i=0; i<lrsIds.length; i++)
			lrMgr.delete(lrMgr.get(pstuser, lrsIds[i]));

		// remove all attachmentObject related to pj
		Object [] objArr = pj.getAttribute("AttachmentID");
		for (int j=0; j<objArr.length; j++) {
			if (objArr[j] != null) {
				int aId = Integer.parseInt(objArr[j].toString());
				try {attachment aObj = (attachment)attMgr.get(pstuser, aId);
				attMgr.delete(aObj);}
				catch (PmpException e) {}
			}
		}

		// delete all the project phases
		ids = phMgr.findId(pstuser, "ProjectID='" + pjId + "'");
		for (int i=0; i<ids.length; i++) {
			phMgr.delete(phMgr.get(pstuser, ids[i]));
		}

		// delete files attached to this project (directory: Repository/JW/pjId)
		pathName = repository + File.separator + pjId;
		f = new File(pathName);
		fList = f.listFiles();
		if (fList != null)
			for (int j=0; j<fList.length; j++)
				fList[j].delete();
		f.delete();

		// delete archived weblogs of this project (file: Repository/Archive/townId/pjId*.jsp)
		String pjidS = String.valueOf(pjId);
		pathName = archive + File.separator + townIdS;
		f = new File(pathName);
		fList = f.listFiles();
		if (fList != null)
		{
			for (int j=0; j<fList.length; j++)
			{
				if (fList[j].getName().indexOf(pjidS) != -1)
					fList[j].delete();
			}
		}

		// delete action/decision only associated to this project
		ids = aMgr.findId(pstuser, "ProjectID='"+ pjId+"'");
		PstAbstractObject obj;
		for (int i=0; i<ids.length; i++)
		{
			obj = aMgr.get(pstuser, ids[i]);
			if (obj.getAttribute("MeetingID")[0] == null)
				aMgr.delete(obj);	// remove action/decision that only connect to this project
		}

		// delete dl
		int [] dlIds = dlMgr.findId(pstuser, dl.PROJECTID + "='" + pjId + "'");
		for (int i=0; i<dlIds.length; i++)
			dlMgr.delete(dlMgr.get(pstuser, dlIds[i]));
		
		// delete project chat
		ids = cMgr.findId(pstuser, "ProjectID='" + pjId + "'");
		for (int i=0; i<ids.length; i++) {
			cMgr.delete(cMgr.get(pstuser, ids[i]));
		}

		// finally, delete the project
		pjMgr.delete(pj);

		l.info("deleted project [" +pjName+ " (" +pjId+ ")]");
	}


	// recursively set owner of children task if current owner is me
	public static void setChildrenOwner(PstUserAbstractObject pstuser, String owner, int pTaskId, task t)
		throws PmpException
	{
		planTask pt;
		planTaskManager ptMgr = planTaskManager.getInstance();
		taskManager tkMgr = taskManager.getInstance();
		int [] ptId = ptMgr.findId(pstuser, "ParentID='" +pTaskId+ "' && Status!='Deprecated'");

		for (int i=0; i<ptId.length; i++)
		{
			pt = (planTask)ptMgr.get(pstuser, ptId[i]);
			task tk = (task)tkMgr.get(pstuser, (String)pt.getAttribute("TaskID")[0]);
			tk.setOwner(pstuser, owner);	// will change step CurrentExecutor
			tkMgr.commit(tk);

			// recursive call
			setChildrenOwner(pstuser, owner, ptId[i], tk);
		}
	}


	// update userinfo record
	public static void removeAttrUserinfo(PstUserAbstractObject pstuser, String attName, String attVal)
		throws PmpException
	{
		userinfoManager uiMgr = userinfoManager.getInstance();

		// no need to change identity to special user since userinfo is now updatable by normal user

		userinfo ui = (userinfo)uiMgr.get(pstuser, String.valueOf(pstuser.getObjectId()));
		Object [] postings = ui.getAttribute(attName);
		boolean bFound = false;
		for (int i=0; i<postings.length; i++)
		{
			if (postings[0] == null) break;	// no att val
			if (((String)postings[i]).startsWith(attVal))
			{
				attVal = (String)postings[i];
				bFound = true;
				break;
			}
		}

		if (bFound)
		{
			ui.removeAttribute(attName, attVal);
			uiMgr.commit(ui);
		}

		return;
	}

	public static String getPropKey(String conFName, String key)
	{
//		ResourceBundle bundleFile = ResourceBundle.getBundle(conFName);
//		try {return (bundleFile.getString(key));}
//		catch (Exception e) {return null;}
	    if (encryptor == null) {
			encryptor = new StandardPBEStringEncryptor();
			encryptor.setPassword("EgiOmm");
	    }

	    try {
	    	InputStream is = Util.class.getClassLoader().getResourceAsStream(conFName + ".properties");
	    	
			Properties props = new EncryptableProperties(encryptor);
			props.load(is);
			is.close();
			
			String val = props.getProperty(key);
			return val;
	    }
	    catch (Exception ex) {return null;}
	}

	// increment statistic value in userinfo
	public static int incUserinfo(PstUserAbstractObject pstuser, String attName)
		throws PmpException
	{
		userinfoManager uiMgr = userinfoManager.getInstance();
		userinfo ui = (userinfo)uiMgr.get(pstuser, String.valueOf(pstuser.getObjectId()));
		int ct = 1;
		Integer iObj = (Integer)ui.getAttribute(attName)[0];
		if (iObj != null) ct = iObj.intValue() + 1;
		ui.setAttribute(attName, new Integer(ct));
		uiMgr.commit(ui);
		return ct;
	}

	public static int incAttrNum(PstManager mgr, PstAbstractObject obj, String attName)
		throws PmpException
	{
		int ct = 1;
		Integer iObj = (Integer)obj.getAttribute(attName)[0];
		if (iObj != null) ct = iObj.intValue() + 1;
		obj.setAttribute(attName, new Integer(ct));
		mgr.commit(obj);
		return ct;
	}

	public static String getAttrNum(PstAbstractObject obj, String attName, String defRetS)
		throws PmpException
	{
		Integer iObj = (Integer)obj.getAttribute(attName)[0];
		if (iObj!=null && iObj.intValue()>0)
			return iObj.toString();
		return defRetS;
	}

	// update statistic based on adjourned meeting
	public static void meetingStat(PstUserAbstractObject pstuser, meeting mtgObj)
		throws PmpException
	{
		userinfoManager uiMgr = userinfoManager.getInstance();
		userinfo ui;
		Object [] attendeeArr = mtgObj.getAttribute("Attendee");
		String [] sa;
		String s;
		Integer iObj;
		for (int i=0; i<attendeeArr.length; i++)
		{
			s = (String)attendeeArr[i];
			if (s == null) break;
			if (s.indexOf(meeting.ATT_PRESENT) != -1)
			{
				// log for his present
				int ct = 1;
				sa = s.split(meeting.DELIMITER);
				s = sa[0];		// user id
				ui = (userinfo)uiMgr.get(pstuser, s);
				iObj = (Integer)ui.getAttribute("AttendMtgNum")[0];
				if (iObj != null) ct = iObj.intValue() + 1;
				ui.setAttribute("AttendMtgNum", new Integer(ct));
				uiMgr.commit(ui);
			}
		}
	}
// @AGQ041906

	public static void sort(int [] iArr, boolean reverse)
	{
		boolean swap;
		int i1, i2, result;
		do
		{
			swap = false;
			for (int i=0; i<iArr.length-1; i++)
			{
					i1 = iArr[i];
					i2 = iArr[i+1];

					result = 0;
					if (reverse)
					{
						if (i1 < i2) result = 1;
					}
					else
					{
						if (i1 > i2) result = 1;
					}

					if (result > 0)
					{
						// swap the element
						iArr[i]   = i2;
						iArr[i+1] = i1;
						swap = true;
					}
			}
		} while (swap);
	}

	public static void sortById(Object [] oArr) {sortById(oArr, false);}
	public static void sortById(Object [] oArr, boolean reverse)
	{
		// small to large: ObjectID
		PstAbstractObject o1, o2;
		int v1, v2;
		boolean swap;
		boolean bNeedSwap;
		do
		{
			swap = false;
			for (int i=0; i<oArr.length-1; i++)
			{
				o1 = (PstAbstractObject)oArr[i];
				o2 = (PstAbstractObject)oArr[i+1];
				try
				{
					v1 = o1.getObjectId();
					v2 = o2.getObjectId();

					if (reverse)
						bNeedSwap = (v2>v1);
					else
						bNeedSwap = (v1>v2);

					if (bNeedSwap)
					{
						// swap the element
						oArr[i]   = o2;
						oArr[i+1] = o1;
						swap = true;
					}
				}
				catch (Exception e) {}
			}
		} while (swap);
	}
	
	public static void sortName(Object [] oArr)
	{
		sortName(oArr, false);
	}

	// sort using object names
	public static void sortName(Object [] oArr, boolean ignoreCase)
	{
		PstAbstractObject o1, o2;
		String v1, v2;
		boolean swap;
		int result;
		do
		{
			swap = false;
			for (int i=0; i<oArr.length-1; i++)
			{
				o1 = (PstAbstractObject)oArr[i];
				o2 = (PstAbstractObject)oArr[i+1];
				try
				{
					v1 = o1.getObjectName();
					v2 = o2.getObjectName();
// @AGQ041906
					if (ignoreCase)
						result = v1.compareToIgnoreCase(v2);
					else
						result = v1.compareTo(v2);

					if (result > 0)
					{
						// swap the element
						oArr[i]   = o2;
						oArr[i+1] = o1;
						swap = true;
					}
				}
				catch (Exception e) {}
			}
		} while (swap);
	}
	
// @AGQ041306
	public static void sortString(Object [] oArr, String attName) {
		sortString(oArr, attName, false);
	}

	public static void sortString(Object [] oArr, String attName, boolean ignoreCase)
	{
		PstAbstractObject o1, o2;
		String v1, v2;
		Object obj1, obj2;
		boolean swap;
		int result;
		do
		{
			swap = false;
			for (int i=0; i<oArr.length-1; i++)
			{
				o1 = (PstAbstractObject)oArr[i];
				o2 = (PstAbstractObject)oArr[i+1];
				try
				{
// @AGQ040706
					obj1 = o1.getAttribute(attName)[0];
					obj2 = o2.getAttribute(attName)[0];

					v1 = (obj1 != null)?(String)obj1:"zzz";		// change from ""
					v2 = (obj2 != null)?(String)obj2:"zzz";

// @AGQ041306
					if (ignoreCase) {
						result = v1.compareToIgnoreCase(v2);
					}
					else
						result = v1.compareTo(v2);

					if (result > 0)
					{
						// swap the element
						oArr[i]   = o2;
						oArr[i+1] = o1;
						swap = true;
					}
				}
				catch (Exception e) {}
			}
		} while (swap);
	}

	public static void sortIndirectUserName(PstUserAbstractObject pstuser, PstManager mgr, Object [] oArr, String attName)
	{
		// e.g. pass in answer obj array and sort by Creator's fullname
		PstAbstractObject o1, o2;
		String v1, v2;
		String obj1, obj2;
		String [] nameArr;
		boolean swap;
		int result;

		// first set up the nameArr by filling it with user object based on attName
		nameArr = new String[oArr.length];
		int id;
		for (int i=0; i<oArr.length; i++)
		{
			o1 = (PstAbstractObject)oArr[i];
			try
			{
				id = Integer.parseInt((String)o1.getAttribute(attName)[0]);	// e.g. extract the Creator ID
				nameArr[i] = ((user)mgr.get(pstuser, id)).getFullName();
			}
			catch (PmpException e) {}
		}

		do
		{
			swap = false;
			for (int i=0; i<oArr.length-1; i++)
			{
				o1 = (PstAbstractObject)oArr[i];
				o2 = (PstAbstractObject)oArr[i+1];
				try
				{
					obj1 = nameArr[i];
					obj2 = nameArr[i+1];

					v1 = (obj1 != null)?obj1:"";
					v2 = (obj2 != null)?obj2:"";

					result = v1.compareToIgnoreCase(v2);

					if (result > 0)
					{
						// swap the element
						oArr[i]		= o2;
						oArr[i+1]	= o1;
						nameArr[i]	= obj2;
						nameArr[i+1]= obj1;
						swap = true;
					}
				}
				catch (Exception e) {}
			}
		} while (swap);
	}

	public static void sortDate(Object [] oArr, String attName)
	{
		sortDate(oArr, attName, false);		// list the oldest first
	}

	public static void sortDate(Object [] oArr, String attName, boolean reverse)
	{
		// by default it is from old to latest.  Reverse will reverse this.
		PstAbstractObject o1, o2;
		Date v1, v2;
		Date oldDate = new Date(0);
		boolean swap=false, again;
		do
		{
			again = false;
			for (int i=0; i<oArr.length-1; i++)
			{
				o1 = (PstAbstractObject)oArr[i];
				o2 = (PstAbstractObject)oArr[i+1];
				try
				{
					v1 = (Date)o1.getAttribute(attName)[0];
					v2 = (Date)o2.getAttribute(attName)[0];
					if (v1 == null) v1 = oldDate;
					if (v2 == null) v2 = oldDate;
					if (!reverse)
					{
						if (v1.compareTo(v2)>0) swap = true;
					}
					else
					{
						if (v2.compareTo(v1)>0) swap = true;
					}
					if (swap)
					{
						// swap the element
						oArr[i]   = o2;
						oArr[i+1] = o1;
						swap = false;
						again = true;
					}
				}
				catch (Exception e) {}
			}
		} while (again);
	}

	public static void sortInteger(Object [] oArr, String attName)
	{
		sortInteger(oArr, attName, false);		// list the oldest first
	}

// @AGQ051106
	public static void sortInteger(Object [] oArr, String attName, boolean reverse)
	{
		// by default it is from smallest to largest.  Reverse will reverse this.
		PstAbstractObject o1, o2;
		Integer v1, v2;
		Integer zero = new Integer(0);
		boolean swap=false, again;
		do
		{
			again = false;
			for (int i=0; i<oArr.length-1; i++)
			{
				o1 = (PstAbstractObject)oArr[i];
				o2 = (PstAbstractObject)oArr[i+1];
				try
				{
					v1 = (Integer)o1.getAttribute(attName)[0];
					v2 = (Integer)o2.getAttribute(attName)[0];
					if (v1 == null) v1 = zero;
					if (v2 == null) v2 = zero;
					if (!reverse)
					{
						if (v1.compareTo(v2)>0) swap = true;
					}
					else
					{
						if (v2.compareTo(v1)>0) swap = true;
					}
					if (swap)
					{
						// swap the element
						oArr[i]   = o2;
						oArr[i+1] = o1;
						swap = false;
						again = true;
					}
				}
				catch (Exception e) {}
			}
		} while (again);
	}

// @AGQ040706a
	/**
	 * sort by an attribute which is a user ID
	 * order: Null - Z - A
	 * @param pstuser
	 * @param oArr
	 * @param attName
	 * @throws PmpException
	 */
	public static void sortUserId(PstUserAbstractObject pstuser, Object [] oArr, String attName)
		throws PmpException
	{
		sortUserId(pstuser, oArr, attName, true);
	}

	/**
	 * sort by an attribute which is a user ID
	 * @param pstuser
	 * @param oArr
	 * @param attName
	 * @param reverse 	true: order null - z - a
	 * 					false: order a - z - null
	 * @throws PmpException
	 */
	public static void sortUserId(PstUserAbstractObject pstuser, Object [] oArr, String attName, boolean reverse)
		throws PmpException
	{
		PstAbstractObject o1, o2, u1, u2;
		Object key1, key2;
		String s1, s2;
		boolean swap=false, again;
		HashMap nameMap = new HashMap();

		do
		{
			again = false;
			for (int i=0; i<oArr.length-1; i++)
			{
				o1 = (PstAbstractObject)oArr[i];
				o2 = (PstAbstractObject)oArr[i+1];

				u1 = u2 = null;
				s1 = s2 = null;
				key1 = o1.getAttribute(attName)[0];
				key2 = o2.getAttribute(attName)[0];
				// find name from hashmap
				if (nameMap.containsKey(key1)) {
					s1 = (nameMap.get(key1)).toString(); // done
				}
				else if (key1 != null)
					u1 = uMgr.get(pstuser, Integer.parseInt(key1.toString()));

				if (nameMap.containsKey(key2)) {
					s2 = (nameMap.get(key2)).toString(); // done
				}
				else if (key2 != null)
					u2 = uMgr.get(pstuser, Integer.parseInt(key2.toString()));

				try
				{	// find user name 1 and store into hashmap
					if (u1 != null) {
						s1 = ((user)u1).getFullName();
						nameMap.put(key1, s1);
					}
					// no name
					else if (s1 == null)
						s1 = STRAIGHTLINES;

					if (u2 != null) {
						s2 = ((user)u2).getFullName();
						nameMap.put(key2, s2);
					}
					else if (s2 == null)
						s2 = STRAIGHTLINES;

					if (!reverse)
					{
						// order: A - Z - Null
						if (s1.compareTo(s2)>0) swap = true;
					}
					else
					{
						// order: Null - Z - A
						if (reverse && s2.compareTo(s1)>0) swap = true;
					}
					if (swap)
					{
						// swap the element
						oArr[i]   = o2;
						oArr[i+1] = o1;
						swap = false;
						again = true;
					}
				}
				catch (Exception e) {}
			}
		} while (again);
	}

	public static void sortUserArray(Object [] oArr) {
		sortUserArray(oArr, false);
	}

// @AGQ030606
	public static void sortUserArray(Object [] oArr, boolean ignoreCase) {
		PstAbstractObject o1, o2;
		String v1, v2;
		boolean swap;
		HashMap map = new HashMap();
		do
		{
			swap = false;
			for (int i=0; i<oArr.length-1; i++)
			{
				o1 = (PstAbstractObject)oArr[i];
				o2 = (PstAbstractObject)oArr[i+1];
				try
				{
// @AGQ030606
					if (o1 == null) v1 = STRAIGHTLINES;
					else if (map.containsKey(o1)) {
						v1 = (String)map.get(o1);
					}
					else {
						v1 = ((user)o1).getFullName();
						map.put(o1, v1);
					}

					if (o2 == null) v2 = STRAIGHTLINES;
					else if (map.containsKey(o2)) {
						v2 = (String)map.get(o2);
					}
					else {
						v2 = ((user)o2).getFullName();
						map.put(o2, v2);
					}

					int results;
					if (ignoreCase)
						results = v1.compareToIgnoreCase(v2);
					else
						results = v1.compareTo(v2);

					if (results > 0)
					{
						// swap the element
						oArr[i]   = o2;
						oArr[i+1] = o1;
						swap = true;
					}
				}
				catch (Exception e) {}
			}
		} while (swap);
	}

	public static void sortUserList(ArrayList aList)
	{
		PstAbstractObject o1, o2;
		String s1, s2;
		StringBuffer sb = new StringBuffer();
		boolean swap;
		HashMap map = new HashMap();
		int len = aList.size()-1;
		do
		{
			swap = false;
			for (int i=0; i<len; i++)
			{
				o1 = (PstAbstractObject)aList.get(i);
				o2 = (PstAbstractObject)aList.get(i+1);
				try
				{
// @AGQ030606
					if (map.containsKey(o1)) {
						s1 = (String)map.get(o1);
					}
					else {
						sb.append((String)o1.getAttribute("FirstName")[0]);
						sb.append((String)o1.getAttribute("LastName")[0]);
						s1 = sb.toString();
						sb.setLength(0);
						map.put(o1, s1);
					}

					if (map.containsKey(o2)) {
						s2 = (String)map.get(o2);
					}
					else {
						sb.append((String)o2.getAttribute("FirstName")[0]);
						sb.append((String)o2.getAttribute("LastName")[0]);
						s2 = sb.toString();
						sb.setLength(0);
						map.put(o2, s2);
					}
					if (s1.compareTo(s2) > 0)
					{
						// swap the element
						aList.set(i, o2);
						aList.set(i+1, o1);
						swap = true;
					}
				}
				catch (Exception e) {}
			}
		} while (swap);
	}

	//
	// exchange the id array with user members and sort the ArrayList
	// if there are obsolete members (deleted user), remove them from the ArrayList
	//
	public static void sortExUserList(PstUserAbstractObject pstuser, ArrayList aList)
		throws PmpException
	{
		PstAbstractObject o1, o2;
		String s1, s2;
		StringBuffer sb = new StringBuffer();
		boolean swap, firstRound = true;
		int len = aList.size()-1;

		while (len >= 0)
		{
			try {
				aList.set(0, uMgr.get(pstuser, Integer.parseInt((String)aList.get(0))));
				break;
			}	// set up element 0
			catch (PmpException e) {
				aList.remove(0);
				len--;
			}
		}

		do
		{
			swap = false;
			for (int i=0; i<len; i++)
			{
				if (firstRound)
				{
					o1 = (PstAbstractObject)aList.get(i);
					try {
						o2 = uMgr.get(pstuser, Integer.parseInt((String)aList.get(i+1)));
						aList.set(i+1, o2);
					}
					catch (PmpException e) {
						aList.remove(i+1);
						len--;
						i--;
						continue;
					}
				}
				else
				{
					o1 = (PstAbstractObject)aList.get(i);
					o2 = (PstAbstractObject)aList.get(i+1);
				}
				try
				{
// @AGQ030606
					sb.append((String)o1.getAttribute("FirstName")[0]);
					sb.append((String)o1.getAttribute("LastName")[0]);
					s1 = sb.toString();
					sb.delete(0, sb.length());
					sb.append((String)o2.getAttribute("FirstName")[0]);
					sb.append((String)o2.getAttribute("LastName")[0]);
					s2 = sb.toString();
					sb.delete(0, sb.length());
					if (s1.compareTo(s2) > 0)
					{
						// swap the element
						aList.set(i, o2);
						aList.set(i+1, o1);
						swap = true;
					}
				}
				catch (Exception e) {}
			}
			firstRound = false;
		} while (swap && len>0);
	}

	public static void sortWithValues(Object [] oArr, String attName, String [] valArr)
	{
		sortWithValues(oArr, attName, valArr, false);
	}
	public static void sortWithValues(Object [] oArr, String attName, String [] valArr, boolean reverse)
	{
		Object obj;
		String val;
		int num;
// @AGQ040706b
		int nullValue = -1;
		for (int j=0; j<valArr.length; j++) {
			if (valArr[j].length() == 0) {
				nullValue = j;
				break;
			}
		}

		// for performance: first replace with numeric value before sort
		int [] numValArr = new int[oArr.length];
		for (int i=0; i<oArr.length; i++)
		{
			obj = oArr[i];
			num = -1;
			try
			{
				val = (String)((PstAbstractObject)obj).getAttribute(attName)[0];
				if (val != null)
				{
					for (int j=0; j<valArr.length; j++)
						if (valArr[j].length() > 0 && val.startsWith(valArr[j]))
							{num = j; break;}
				}
				else
					num = nullValue;	// Set null case according to array's "" string
			}
			catch (Exception e) {}
			numValArr[i] = num;
		}

		// now simply compare int array
		boolean swap = false, again;
		do
		{
			again = false;
			for (int i=0; i<oArr.length-1; i++)
			{
				if (reverse)
				{
					if (numValArr[i]<numValArr[i+1]) swap = true;
				}
				else
				{
					if (numValArr[i]>numValArr[i+1]) swap = true;
				}
				if (swap)
				{
					// swap the element
					obj = oArr[i];
					oArr[i]   = oArr[i+1];
					oArr[i+1] = obj;

					// swap the numArr
					num = numValArr[i];
					numValArr[i] = numValArr[i+1];
					numValArr[i+1] = num;

					again = true;
					swap = false;
				}
			}
		} while (again);
	}

	/**
	 * Display the last blog of an object (task or bug), optionally specify
	 * width and drag-able index.  Caller must specify height.
	 */
	public static String showLastBlog(PstUserAbstractObject pstuser,
					String projIdS, String idS, String type, String heightS)
		throws PmpException
	{
		return showLastBlog(pstuser, projIdS, idS, type, heightS, null, -1);
	}

	public static String showLastBlog(PstUserAbstractObject pstuser,
					String projIdS, String idS, String type, String heightS, String widthS, int idx)
		throws PmpException
	{
		result blog;
		String uname;
		StringBuffer sBuf = new StringBuffer();
		Date bDate;
		user bUser;
		PstAbstractObject [] blogList;
		String bText = "";
		SimpleDateFormat df = new SimpleDateFormat ("MMM dd, yy (EEE) hh:mm a");

		// for draggable window index on the page (support up to 10)
		// idx=-1 means only one draggable window and not using index
		// idx=-2 means not draggable at all
		String idxS = "";
		if (idx >= 0)
			idxS = String.valueOf(idx);

		int [] blogIds = rMgr.findId(pstuser, "(TaskID='" + idS + "') && (Type='" + type + "')");
		if (blogIds.length > 0)
		{
			blogList = rMgr.get(pstuser, blogIds);
			Util.sortDate(blogList, "CreatedDate", true);
			blog = (result)blogList[0];
			bDate = (Date)blog.getAttribute("CreatedDate")[0];
			bUser = (user)uMgr.get(pstuser, Integer.parseInt((String)blog.getAttribute("Creator")[0]));
			uname = bUser.getFullName();
			Object bTextObj = blog.getAttribute("Comment")[0];
			if (bTextObj != null) {
				try	{
					bText = new String((byte[])bTextObj, "utf-8");				
				}catch (Exception e){
					e.printStackTrace();
				}
			}
			else
				bText = "";
			/*bText = blog.getRawAttributeAsString("Comment");
			if (bText == null)
				bText = "";*/

			sBuf.append("<table width='85%' border='0'>");
			sBuf.append("<tr><td class='plaintext' align='left'>");
			sBuf.append("Posted by <b>" + uname + "</b> on " + df.format(bDate) + "</td>");
			sBuf.append("<td align='right'><a class='listlink' href='"
					+ HOST + "/blog/blog_task.jsp?projId=" + projIdS);
			if (type.equals("Task")) sBuf.append("&taskId=");
			else sBuf.append("&bugId=");
			sBuf.append(idS + "'>>> go to blog</a></td></tr>");
			sBuf.append("<tr><td colspan='2'>");
			sBuf.append("<div align='left'");
			if (heightS!=null || widthS!=null) {
				sBuf.append(" class='scroll' id='mtgText" + idxS + "' style='");
				if (heightS != null)
					sBuf.append("height:" + heightS + ";");
				if (widthS != null)
					sBuf.append("width:" + widthS);
				sBuf.append("'");
			}
			sBuf.append(">" + bText + "</div>");

			if (idx >= 0) {
				sBuf.append("<div><img src='../i/spacer.gif' height='5'/></div>");
				sBuf.append("<div align='right'>");
				sBuf.append("<span id='handleBottom" + idxS
						+ "' ><img src='../i/drag.gif' style='cursor:s-resize;'/></span>");
				sBuf.append("<span><img src='../i/spacer.gif' width='40' height='1'/></span>");
				sBuf.append("</div>");
			}
			sBuf.append("</td>");
			sBuf.append("</tr></table>");
		}

		return sBuf.toString();
	}

	public static String showLabel(String [] label, int [] labelLength)
	{
		return showLabel(label, null, null, null, labelLength, null, true);	// showAll, not centered
	}
	public static String showLabel(String [] label, int [] labelLength, boolean bAll)
	{
		return showLabel(label, null, null, null, labelLength, null, bAll);	// not centered
	}
	public static String showLabel(String [] label, int [] labelLength, boolean [] bAlignCenter, boolean bAll)
	{
		return showLabel(label, null, null, null, labelLength, bAlignCenter, bAll);	// no title
	}
	public static String showLabel(String [] label, String [] title, int [] labelLength, boolean [] bAlignCenter, boolean bAll)
	{
		return showLabel(label, null, null, null, labelLength, bAlignCenter, bAll);	// no sortby
	}
	public static String showLabel(String [] label, String [] title, String [] sortArr,
			String sortby, int [] labelLength, boolean [] bAlignCenter,
			boolean bAll)
	{
		return showLabel(label, title, sortArr, sortby, labelLength, bAlignCenter, bAll, null);
	}

	/**
	 * display the label
	 * @param label
	 * @param title
	 * @param sortArr
	 * @param sortby
	 * @param labelLength
	 * @param bAlignCenter
	 * @param bAll in some cases don't use the last element in the labelLength and bAlignCenter array
	 * @return
	 */
	public static String showLabel(String [] label, String [] title, String [] sortArr,
			String sortby, int [] labelLength, boolean [] bAlignCenter,
			boolean bAll, String labelBgColor)
	{
		// the last element in the two arrays will only be used if bAll is true.  This is done
		// to support the different cases of listing by different users.
		StringBuffer sBuf = new StringBuffer(4096);
		int len = label.length;
		if (len != labelLength.length) {l.error("showLabel(1) mismatch in array lengths."); return null;}
		if (bAlignCenter!=null && len!=bAlignCenter.length) {l.error("showLabel(2) mismatch in array lengths."); return null;}

		// pixel or percentage
		String labelLenSpec = "";
		if (labelLength[0] < 0)
			labelLenSpec = "%";

		if (labelBgColor == null) labelBgColor = "#6699cc";

		String bgcl = "bgcolor='" + labelBgColor + "' ";
		String srcl = "bgcolor='#66cc99' ";
		String bg;
		int iLabelLen;

		if (!bAll) len--;		// don't do the last element

		sBuf.append("<table width='100%' border='0' cellpadding='0' cellspacing='0'>");
		sBuf.append("<tr><td bgcolor='#EBECED' height='3'><img src='"
				+ HOST + "/i/spacer.gif' width='1' height='3' border='0'></td></tr></table>");

		sBuf.append("<table width='100%' border='0' cellspacing='0' cellpadding='0'>");
		sBuf.append("<tr><td colspan='" + (len*3 - 1) + "' height='2' bgcolor='#336699'><img src='"
				+ HOST + "/i/spacer.gif' width='2' height='2'></td></tr>");

		sBuf.append("<tr>");
		for (int i=0; i<len; i++)
		{
			if (sortby!=null && sortby.equals(sortArr[i]))
				bg = srcl;
			else
				bg = bgcl;
			if (i > 0)
				sBuf.append("<td width='2' bgcolor='#FFFFFF' class='10ptype'><img src='"
						+ HOST + "/i/spacer.gif' width='2'></td>");
			sBuf.append("<td width='4' " + bg + "class='10ptype'><img src='"
					+ HOST + "/i/spacer.gif' width='4' /></td>");
			sBuf.append("<td ");
			if ((iLabelLen = Math.abs(labelLength[i])) > 0) {
				sBuf.append("width='" + iLabelLen + labelLenSpec + "' ");
			}
			if (bAlignCenter!=null && bAlignCenter[i]) sBuf.append("align='center' ");
			sBuf.append(bg + "class='td_header'");
			if (title!=null && title[i]!=null)
				sBuf.append(" title='" + title[i] + "'");
			if (sortby!=null && sortArr[i]!=null && bg==bgcl)
				sBuf.append("><a href='javascript:sort(\"" + sortArr[i] + "\")'><font color='ffffff'><b>"
						+ label[i] + "</b></font></a>");
			else
				sBuf.append("><b>" + label[i] + "</b>");
			sBuf.append("</td>");
		}
		sBuf.append("</tr>");
		return sBuf.toString();
	}

	public static Date getToday()
	{
		java.text.SimpleDateFormat df = new java.text.SimpleDateFormat("MM/dd/yyyy");
		Date dt = null;
		try {dt = df.parse(df.format(new Date()));}
		catch (ParseException e) {}
		return (dt);			//( new Date(df.format(new Date())) );
	}

	/**
	 * Receives an arrList of recipients emails and adds guest's emails to the current
	 * arrList. If email does not contain a "@" a system message will show.
	 * @param arrList
	 * @param guestEmails
	 */
	private static ArrayList appendGuestEmails(ArrayList arrList, Object [] guestEmails) {
// @AGQ030606
		if (guestEmails != null && guestEmails.length > 0) {
			for (int i=0; i<guestEmails.length; i++) {
				Object curObj = guestEmails[i];
				if (curObj != null) {
					String email = curObj.toString();
					if(email.indexOf("@") != -1)
						arrList.add(email);
					else if (email.length() > 0){
						// User typed in wrong email address
						System.out.println("Util.sendMailAsyn error in getting guest email: " + email);
					}
				}
			}
		}
		// Remove Duplicates
		return new ArrayList(new TreeSet(arrList));
	}
// @AGQ030906
	/**
	 * Receives a string of email address and splits the string
	 * by either a comma, semicolon, or a space. Mixed delimiters
	 * are not supported. The list of emails are looped to remove
	 * extra spaces.
	 * @param emailStr
	 * @return A String [] of emails addresses or null if emailStr does not contain any value
	 */
	public static String [] expandGuestEmails(String emailStr) {
		String [] guestEmails = null;
		if (emailStr != null) {
			emailStr = emailStr.replaceAll(EMAILDELIMREG, SPACE);
			guestEmails = emailStr.split(SPACE);

			TreeSet set = new TreeSet();
			for (int i=0;i<guestEmails.length;i++) {
				String curEmail = guestEmails[i].trim();
				if (curEmail.length() > 0)
					set.add(curEmail);
			}
			ArrayList arrList = new ArrayList(set);
			guestEmails = new String[arrList.size()];
			for (int i=0; i<guestEmails.length;i++) {
				guestEmails[i] = arrList.get(i).toString();
			}
		}
		return guestEmails;
	}

	public static String stringToHTMLStringSimple(String string) {
		if (string != null) {
		    StringBuffer sb = new StringBuffer(string.length());
		    // true if last char was blank
		    boolean lastWasBlankChar = false;
		    int len = string.length();
		    char c;

		    for (int i = 0; i < len; i++)
		        {
		        c = string.charAt(i);
		        if (c == BLANKCHAR) {
		            // blank gets extra work
		            if (lastWasBlankChar) {
		                lastWasBlankChar = false;
		                	sb.append(SPACESTRING);
		                }
		            else {
		                lastWasBlankChar = true;
		                sb.append(BLANKCHAR);
		                }
		            }
		        else {
		            lastWasBlankChar = false;
		            //
		            // HTML Special Chars
		            if (c == QUOTECHAR)
		                sb.append("\\\"");
		            else if (c == NEWLINECHAR) // Handle Newline
		                sb.append(NEWLINECHAR);
		            else {
		                int ci = 0xffff & c;
		                if (ci < 160 )
		                    // nothing special only 7 Bit
		                    sb.append(c);
		                else {
		                    // Not 7 Bit use the unicode system
		                    sb.append(ENTITY);
		                    sb.append(new Integer(ci).toString());
		                    sb.append(SEMICOLONCHAR);
		                    }
		                }
		            }
		        }
		    return sb.toString();
		}
		else
			return string;
	}

	public static String stringToHTMLString(String string) {
		return stringToHTMLString(string, true);
	}

// @AGQ033006
	/**
	 * Translate a String into a HTML compatible String. Looks through each char and
	 * determines if it needs to be translated. If char is not 7 bit it will be encoded
	 * through looking for it's entity number.
	 * Took from http://www.rgagnon.com/javadetails/java-0306.html
	 * @param string String to be encoded
	 * @return Encoded string
	 */
	public static String stringToHTMLString(String string, boolean useNBSP) {
		if (string != null) {
		    StringBuffer sb = new StringBuffer(string.length());
		    // true if last char was blank
		    boolean lastWasBlankChar = false;
		    int len = string.length();
		    char c;

		    for (int i = 0; i < len; i++)
		        {
		        c = string.charAt(i);
		        if (c == BLANKCHAR) {
		            // blank gets extra work
		            if (lastWasBlankChar) {
		                lastWasBlankChar = false;
		                if (useNBSP)
		                	sb.append(SPACESTRING);
		                else
		                	sb.append(SPACESTRINGAMP);
		                }
		            else {
		                lastWasBlankChar = true;
		                sb.append(BLANKCHAR);
		                }
		            }
		        else {
		            lastWasBlankChar = false;
		            //
		            // HTML Special Chars
		            if (c == QUOTECHAR)
		                sb.append(QUOTESTRING);
		            else if (c == APOSCHAR)
		            	sb.append(APOSSTRING);
		            else if (c == AMPCHAR)
		                sb.append(AMPSTRING);
		            else if (c == LESSTHANCHAR)
		                sb.append(LESSTHANSTRING);
		            else if (c == GREATERTHANCHAR)
		                sb.append(GREATERTHANSTRING);
		            else if (c == NEWLINECHAR) // Handle Newline
		                sb.append(NEWLINECHAR);
		            else if (c==DOLLARCHAR)
		                sb.append(DOLLARSTRING);
		            else {
		                int ci = 0xffff & c;
		                if (ci < 160 )
		                    // nothing special only 7 Bit
		                    sb.append(c);
		                else {
		                    // Not 7 Bit use the unicode system
		                    sb.append(ENTITY);
		                    sb.append(new Integer(ci).toString());
		                    sb.append(SEMICOLONCHAR);
		                    }
		                }
		            }
		        }
		    return sb.toString();
		}
		else
		{
			return string;
		}
	}

	public static String stringToHex(String string)
	{
		if (string == null) return null;
		int len = string.length();
		char c;
		StringBuffer sb = new StringBuffer(512);
		for (int i = 0; i < len; i++)
		{
			c = string.charAt(i);
			if (c==QUOTECHAR || c==APOSCHAR || c==AMPCHAR || c==LESSTHANCHAR || c==GREATERTHANCHAR || c==NEWLINECHAR
					|| c==DOLLARCHAR)
				sb.append("%" + Integer.toHexString(c));
			else
			{
                int ci = 0xffff & c;
                if (ci < 160 )
                    sb.append(c);	// nothing special only 7 Bit
                else
                {
                    // Not 7 Bit use the unicode system
                    sb.append(ENTITY);
                    sb.append(new Integer(ci).toString());
                    sb.append(SEMICOLONCHAR);
                }
            }
		}
		return sb.toString();
	}

	/**
	 * @AGQ092806
	 * This method tries to handle the funny spacing that FCKeditor
	 * changes.
	 * e.g.
	 * 1. 2 Spaces: " &nbsp;" -> "&amp;nbsp; "
	 * 2. 3 Spaces: " &nbsp; " -> "&amp;nbsp;&amp;nbsp; "
	 * 3. 4 Spaces: " &nbsp; &nbsp;" -> "&amp;nbsp;&amp;nbsp;&amp;nbsp; "
	 * I still need to figure out a good while loop to construct this
	 * pattern. Need to be careful whether this will affect finding
	 * the current position.
	 * @param string
	 * @return
	 */
	public static String stringToHTMLStringFCK(String string) {
		if (string != null) {
		    StringBuffer sb = new StringBuffer(string.length());
		    int len = string.length();
		    char c;

		    for (int i = 0; i < len; i++)
		        {
		        c = string.charAt(i);
		        if (c == BLANKCHAR) {
		            // blank gets extra work
		        	int nexti = i+7;
		            if (nexti < len) {
		            	String e = string.substring(i+1, nexti);
		            	if (e.equals(SPACESTRING)) {
		            		sb.append("&amp;nbsp; ");
		            		i = nexti-1;
		            	}
		            	else
		            		sb.append(BLANKCHAR);
		            }
		            else
		            	sb.append(BLANKCHAR);
		        }
		        else {
		            //
		            // HTML Special Chars
		            if (c == QUOTECHAR)
		                sb.append(QUOTESTRING);
		            else if (c == APOSCHAR)
		            	sb.append(APOSSTRING);
		            else if (c == AMPCHAR)
		                sb.append(AMPSTRING);
		            else if (c == LESSTHANCHAR)
		                sb.append(LESSTHANSTRING);
		            else if (c == GREATERTHANCHAR)
		                sb.append(GREATERTHANSTRING);
		            else if (c == NEWLINECHAR) // Handle Newline
		                sb.append(NEWLINECHAR);
		            else {
		                int ci = 0xffff & c;
		                if (ci < 160 )
		                    // nothing special only 7 Bit
		                    sb.append(c);
		                else {
		                    // Not 7 Bit use the unicode system
		                    sb.append(ENTITY);
		                    sb.append(new Integer(ci).toString());
		                    sb.append(SEMICOLONCHAR);
		                    }
		                }
		            }
		        }
		    return sb.toString();
		}
		else
			return string;
	}

	public static String formatToDate(String format, String date) {
		return formatToDate(format, date, null);
	}

	/**
	 * Formats the date into the original Date format. If the String cannot
	 * be format back into a date, the original String is returned.
	 * e.g. From 3/24/2006 to Fri Mar 24 00:00:00 PST 2006
	 * @param format 	A String which specifies the date's format.
	 * 					Uses SimpleDateFormat api e.g. MM/dd/yyyy
	 * @param date 		The date to format
	 * @return 			Date in original String format or
	 * 					the variable date if it could not be parsed.
	 */
	public static String formatToDate(String format, String date, String formatTo) {
		try {
			if (format != null && format.length() > 0
					&& date != null && date.length() > 0) {
				DateFormat dF = new SimpleDateFormat(format);
				if (formatTo != null && formatTo.length() > 0) {
					return formatToDate(dF.parse(date), formatTo);
				}
				return dF.parse(date).toString();
			}
			else
				return date;
		} catch (ParseException e) {
			// parse exception
			return date;
		}
	}

	/**
	 * Formats the Date object to the specified formatTo
	 * @param date
	 * @param formatTo
	 * @return
	 */
	public static String formatToDate(Date date, String formatTo) {
		if (date != null && formatTo != null && formatTo.length() > 0) {
			DateFormat dF2 = new SimpleDateFormat(formatTo);
			return dF2.format(date);
		}
		else if (date != null)
			return date.toString();
		else
			return null;
	}

	/**
	 * Compares to see if an invalid calander day is entered.
	 * i.e. 13/45/2006
	 * @param date Must be in MM/dd/yyyy format, cannot be null or empty
	 * @param d The same date object created from date, cannot be null
	 */
	public static void validCalanderDate(String date, Date d) throws ParseException {
		StringBuffer month = new StringBuffer(8);
		int idx = date.indexOf('/');
		if (idx == 1)
			month.append(0);
		month.append(date.substring(0, idx));

		if (!month.toString().equals(CHECKER.format(d))) {
			l.info("Invalid calander date: " + date);
			throw new ParseException(date, 0);
		}
	}

	// checklogin
	public static user login(HttpSession sess, String uid, String passwd)
		throws PmpException
	{
		PstUserAbstractObject guest = (PstUserAbstractObject) PstGuest.getInstance();
		user newUser = (user)userManager.getInstance().login(guest, uid, passwd);

		userinfoManager uiMgr = userinfoManager.getInstance();
		userinfo uif = (userinfo)uiMgr.get(newUser, String.valueOf(newUser.getObjectId()));
		Date dt = (Date)uif.getAttribute("LastLogin")[0];	// get the last time he login: null if new user
		uif.setAttribute("LastLogin", new Date());
		Integer iObj = (Integer)uif.getAttribute("LoginNum")[0];
		int ct = 1;
		if (iObj != null)
			ct = iObj.intValue() + 1;
		uif.setAttribute("LoginNum", new Integer(ct));
		uiMgr.commit(uif);

		sess.removeAttribute("planComplete");		// this might be set to false in cr.jsp at the time thread died
		sess.setAttribute("lastLogin", dt);			// really last login time: null if new user.
		sess.setAttribute("pstuser", newUser);
		sess.setAttribute("password", passwd);
		sess.setAttribute("firstName", (String)newUser.getAttribute("FirstName")[0]);
		sess.setAttribute("lastName", (String)newUser.getAttribute("LastName")[0]);

		// timezone
		iObj = (Integer)uif.getAttribute("TimeZone")[0];
		if (iObj != null) {
			sess.setAttribute("timeZone", iObj);
		}
		sess.setAttribute("javaTimeZone", uif.getTimeZone());
		
		// locale
		sess.setAttribute("locale", uif.getLocale());

		// type of application
		String app = Prm.getApp();
		sess.setAttribute("app", app);
		boolean isMultiCorp = Prm.isMultiCorp();

		// @ECC080108 multi-corp support
		String s;
		if (app.contains("CR") || app.contains("PRM"))
		{
			if (isMultiCorp) {
				// @ECC093008 for CR MultipCorp, get app from userinof attribute
				s = uif.getStringAttribute("Application");
				if (s != null) sess.setAttribute("app", s);				// modules: CT::CW::Blog
			}

			s = (String)newUser.getAttribute("Company")[0];
			if (s != null) {
				PstAbstractObject tn = Util2.tnMgr.get(newUser, Integer.parseInt(s));
				sess.setAttribute("comPicFile", tn.getAttribute("PictureFile")[0]);		// company logo
			}

		}

		// user roles
		Integer iRoleObj = new Integer(getRoles(newUser));
		sess.setAttribute("role", iRoleObj);
		m_loginNum++;							// this is used in daily reporting in PrmThread.java

		return newUser;
	}
	
	public static user lightLogin(String uid, String passwd)
		throws PmpException
	{
		PstUserAbstractObject guest = (PstUserAbstractObject) PstGuest.getInstance();
		user newUser = (user)userManager.getInstance().login(guest, uid, passwd);
		return newUser;
	}

	/**
	 * Determines if fileName is an absolutePath. Given the fileName
	 * and there does not contain any / or \, it is not a absolutePath.
	 * (e.g. 98887 MS 4.0.ppt)
	 * If there contains / or \ and the first character is / or \,
	 * then it is not an absolutePath.
	 * (e.g. /25355/98887 MS 4.0.ppt)
	 * If there contains / or \ and the first character is not / or \,
	 * then it is an absolutePath.
	 * (e.g. x:/file/98887 MS 4.0.ppt)
	 * If there contains / or \ and the first two characters are \\,
	 * then it is a network path
	 * (e.g. //phoenix\c$\file\98887 MS 4.0.ppt)
	 * @param fileName
	 * @return true if it is an absolutePath
	 */
	public static boolean isAbsolutePath(String fileName) {
		int length = fileName.length();
		if (fileName != null && length > 0) {
			if (fileName.contains("/") || fileName.contains("\\")) {
				char character = fileName.charAt(0);
				if (character == '/' || character == '\\') {
					if (length > 1) {
						// filename starts with \\phoenix
						char character2 = fileName.charAt(1);
						if (character2 == '/' || character2 == '\\')
							return true;
						return false;
					}
				}
				if (character != '/' && character != '\\')
					return true;
			}
			else if (fileName.length()>2 && fileName.charAt(1)==':')
				return true;		// C: or D:
		}
		return false;
	}

	public static int getRoles(PstUserAbstractObject u)
		throws PmpException
	{
		int iRole = 0;
		Object [] myRoles = u.getAttribute("Role");
		if (myRoles == null) return 0;
		
		for (int i=0; i<myRoles.length; i++)
		{
			if (myRoles[i] == null) break;
			for (int j=0; j<user.ROLE_ARRAY.length; j++)
			{
				if (user.ROLE_ARRAY[j].equals(myRoles[i]))
				{
					iRole |= user.iROLE_ARRAY[j];
					break;
				}
			}
		}
		return iRole;
	}

	// check to see if a project belongs to the same town as my town
	// @param project pj: proj object
	public static boolean isMyTownProject(PstUserAbstractObject u, project pj)
		throws PmpException
	{
		String myTownIdS = null;		// (String)u.getAttribute("TownID")[0];
		//Integer iObj = (Integer)u.getAttribute("Towns")[0];
		//if (iObj != null) myTownId = iObj.toString();
		myTownIdS = StringUtil.toString(u.getAttribute("Towns"), ";");
		String pjTownId = (String)pj.getAttribute("TownID")[0];
		if (myTownIdS==null || pjTownId==null || myTownIdS.contains(pjTownId))
			return true;	// town not specify or matching townId
		else
			return false;
	}

	// check to see if a project belongs to the same town as my town
	// @param String pjIdS: proj Id
	public static boolean isMyTownProject(PstUserAbstractObject u, String pjIdS)
		throws PmpException
	{
		project pj = (project)pjMgr.get(u, Integer.parseInt(pjIdS));
		return isMyTownProject(u, pj);
	}

	public static String createPassword()
	throws PmpException
	{
		String ps1 = getPropKey("bringup", "PASSWORD_PAIR1");
		String ps2 = getPropKey("bringup", "PASSWORD_PAIR2");
		if (ps1==null || ps2==null)
			return "snowman24";

		// create password using random number
		long seed = new Date().getTime();
		Random rand = new Random(seed);

		String password;
		String [] sa;
		sa = ps1.split(";");
		int i1 = rand.nextInt(sa.length-1);
		password = sa[i1];

		sa = ps2.split(";");
		int i2 = rand.nextInt(sa.length-1);
		password += sa[i2] + rand.nextInt(99);

		return password;
	}

// @SWS090606
	public static String createUsername(String uname, user au, PstUserAbstractObject pstuser)
	throws PmpException
	{
		boolean isDup = true;
		while (isDup)
		{
			String temp = "";
			int count = 0;
			for(int i=uname.length(); i>0; i--)
			{
				temp = uname.substring(i-1);
				uname = uname.substring(0, i-1);
				if (!temp.equals("9"))
				{
					try{

						int iTemp = Integer.parseInt(temp);
						iTemp++;
						temp = Integer.toString(iTemp);
						uname = uname.concat(temp);
					}
					catch (NumberFormatException e1)
					{
						temp = temp.concat("1");
						uname = uname.concat(temp);
						break;
					}
					break;
				}
				else
				{
					count++;
					continue;
				}
			}
			if (count>0)
			for(int i=0; i<count; i++)
				uname = uname.concat("0");
			try {
				au = (user)uMgr.get(pstuser, uname);
				continue;
			}
			catch (PmpException e2)
			{
				//isDup = false;
				break;
			}
		}
		return uname;
	}
	/**
	 * Check to see if a PST object raw attribute is null or empty string.
	 * @param val the value attribute object
	 * @return true if it is empty
	 */
	public static boolean isEmptyRaw(Object val)
	{
		String valStr = (val==null?null:new String((byte[])val).trim());
		if (valStr==null || valStr.length()<=0) return true;
		return false;
	}

	/**
	 */
	public static String selectProject(PstUserAbstractObject u, int selectedPjId)
		throws PmpException
	{
		return selectProject(u, selectedPjId, false);
	}
	
	/**
	 * 
	 * @param u
	 * @param selectedPjId
	 * @param bAllowNotSelected
	 * @return
	 * @throws PmpException
	 */
	public static String selectProject(PstUserAbstractObject u, int selectedPjId, boolean bAllowNotSelected)
		throws PmpException
	{
		StringBuffer sBuf = new StringBuffer(512);
		if (bAllowNotSelected) {
			sBuf.append("<option value='0'>- Select a project -</option>");
		}
		int [] projectObjId = pjMgr.getProjects(u, false);
		if (projectObjId.length > 0)
		{
			PstAbstractObject [] projectObjList = pjMgr.get(u, projectObjId);
			Util.sortName(projectObjList, true);

			int id;
			project pj;
			for (int i=0; i < projectObjList.length ; i++)
			{
				// project
				pj = (project) projectObjList[i];
				id = pj.getObjectId();
				
				// do not show other users' personal space
				if (pj.getObjectName().contains("Personal Space") &&
					!String.valueOf(u.getObjectId()).equals(pj.getStringAttribute("Owner"))) {
					continue;	// don't show others' personal space
				}

				sBuf.append("<option value='" + id +"' ");
				if (id == selectedPjId)
					sBuf.append("selected");
				sBuf.append(">" + pj.getDisplayName() + "</option>");
			}
		}
		return sBuf.toString();
	}

	public static String selectMember(PstAbstractObject[] teamMember, int taskOwnerId)
		throws ClassCastException, PmpException
	{
		StringBuffer sBuf = new StringBuffer(512);
		String uname;
		for(int a=0; a < teamMember.length; a++)
		{
			uname = ((user)teamMember[a]).getFullName();
			sBuf.append("<option value='" + teamMember[a].getObjectId() + "'");
			if (taskOwnerId == teamMember[a].getObjectId()) {
				sBuf.append(" selected");
			}
			sBuf.append(">" + uname + "</option>");
		}
		return sBuf.toString();
	}

	public static boolean isNullString(String s)
	{
		return StringUtil.isNullString(s);
	}

	public static boolean isNullOrEmptyString(String s)
	{
		return StringUtil.isNullOrEmptyString(s);
	}
	
	public static String getHeaderPartitionLine()
	{
		StringBuffer sBuf = new StringBuffer(512);
		sBuf.append("<img src='../i/spacer.gif' width='25' height='15'/>");
		sBuf.append("<span style='border-bottom:#336699 1px solid;'><img src='../i/spacer.gif' width='120' height='1'/></span><br>");
		sBuf.append("<img src='../i/spacer.gif' width='25' height='1'/>");
		sBuf.append("<span style='border-bottom:#336699 1px solid;'><img src='../i/spacer.gif' width='300' height='1'/></span>");
		sBuf.append("<br><img src='../i/spacer.gif' height='3' width='1'/>");	// need this space for IE to behave
		sBuf.append("<br/><img src='../i/spacer.gif' width='20' height='1'/>");
		return sBuf.toString();
	}
}