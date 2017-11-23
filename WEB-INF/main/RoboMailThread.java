
////////////////////////////////////////////////////
//	Copyright (c) 2008, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	RoboMailThread.java
//	Author:	ECC
//	Date:	11/16/08
//	Description:
//		Run background processes for PRM RoboMail.  It supports these operations:
//		- copy (the content XML will provide object and attribute info)
//		- upload taskId (upload the attachment files to the task)
//		- post taskId (post the email to the task blog and upload the attachment files to the task)
//
//	Modification:
//
////////////////////////////////////////////////////////////////////

package main;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.Date;

import javax.mail.Address;
import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.Flags.Flag;
import javax.mail.internet.MimeBodyPart;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.MimeMultipart;

import oct.codegen.attachment;
import oct.codegen.attachmentManager;
import oct.codegen.event;
import oct.codegen.meetingManager;
import oct.codegen.planTaskManager;
import oct.codegen.project;
import oct.codegen.projectManager;
import oct.codegen.questManager;
import oct.codegen.result;
import oct.codegen.task;
import oct.codegen.taskManager;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstManager;
import oct.pst.PstUserAbstractObject;
import oct.util.file.FileTransfer;

import org.apache.log4j.Logger;

import util.Prm;
import util.PrmEvent;
import util.PrmLog;
import util.RoboMail;
import util.StringUtil;
import util.Util;
import util.Util2;
import util.Util3;
import util.UtilThread;

public class RoboMailThread extends Thread
{

	private static final String PRM_ROBO_MAIL	= "PrmRoboMail";
	private static final String OP_COPY			= "copy";			// copy XML object
	private static final String OP_POST			= "post";			// post blog and upload files
	private static final String OP_UPLOAD		= "upload";			// only upload files

	private static final String FROM				= Util.getPropKey("pst", "FROM");
	private static final String ADMIN_MAIL			= Util.getPropKey("pst", "MAIL_ADMIN");
	private static final String MAILFILE			= "alert.htm";
	private static final String UPLOAD_PATH			= Util.getPropKey("pst", "FILE_UPLOAD_PATH");
	private static final String HOST				= Util.getPropKey("pst", "PRM_HOST");
	private static final String app					= Prm.getAppTitle();
	//private static final boolean isCRAPP			= (app.indexOf("CR")!=-1);

	private static final String ROBOMAIL_HOST		= Util.getPropKey("pst", "ROBOMAIL_HOST");
	private static final String ROBOMAIL_USERNAME	= Util.getPropKey("pst", "ROBOMAIL_USERNAME");
	private static final String ROBOMAIL_PASSWORD	= Util.getPropKey("pst", "ROBOMAIL_PASSWORD");
	private static final String ROBOMAIL_MESSAGE	= Util.getPropKey("pst", "ROBOMAIL_MESSAGE");

	private static boolean running = false;
	private static final int WORK_PERIOD	= 1;				// wake up every 1 min to do work
	private static final SimpleDateFormat df0 = new SimpleDateFormat("MMMMMMMM dd, yyyy (EEE) hh:mm a");

	private static PstUserAbstractObject jwu;
	private static userManager uMgr;
	private static projectManager pjMgr;
	private static taskManager tMgr;
	private static planTaskManager ptMgr;
	private static attachmentManager attMgr;
	private static meetingManager mtgMgr;
	private static questManager qMgr;
	
	private static final boolean bSendErrorMsg = "true".equalsIgnoreCase(ROBOMAIL_MESSAGE);

	private static Logger l;
	static
	{
		l = PrmLog.getLog();

		try {
			uMgr = userManager.getInstance();
			pjMgr = projectManager.getInstance();
			tMgr = taskManager.getInstance();
			ptMgr = planTaskManager.getInstance();
			attMgr = attachmentManager.getInstance();
			mtgMgr = meetingManager.getInstance();
			qMgr = questManager.getInstance();
		}
		catch (PmpException e) {uMgr=null;pjMgr=null;tMgr=null;ptMgr=null;attMgr=null;mtgMgr=null;qMgr=null;}
	}

	public RoboMailThread(PstUserAbstractObject u) {
		super(PRM_ROBO_MAIL);
		jwu = u;
	}

	public void run()
	{
		if (!checkCanRun())
		{
			System.out.println("[" + Prm.getAppTitle()
					+ "] PrmRoboThread is currently running - exit self normally.");
			return;
		}
		l.info("[" + Prm.getAppTitle() + "] PrmRoboThread started.");

		int exceptionCount = 0;
        RoboMail pop3 = null;
        try {
			pop3 = new RoboMail(ROBOMAIL_HOST, ROBOMAIL_USERNAME, ROBOMAIL_PASSWORD);
		} catch (Exception e1) {
			l.error("RoboMailThread failed to initialize.  Exit.");
			return;
		}
        
		while (getRunning())
		{
			// receive Robo mail in a loop and handle RoboMail commands accordingly
			try
			{
				synchronized(RoboMailThread.class){
					
	            pop3.connect();
	            //l.info("RoboMail Message Count:"+pop3.getMessageCount());
	            if (pop3.getUnreadMessageCount() > 0)
	            	l.info("Unread Message Count:"+pop3.getUnreadMessageCount());

	            Message msg[] = pop3.getMessages();
				String subj, changedSubj, fromEmail;

	            for (int i=0; i < msg.length; i++)
	            {
	                MimeMessage m = (MimeMessage) msg[i];
	                Address from[] = m.getFrom();
	                changedSubj = null;
	    	        subj = m.getSubject().toLowerCase().trim();
	    	        //subj = subj.replace("fw:", "").replace("re:", "").trim();
	                fromEmail = from[0].toString();
	                l.info("Message #" + i + " From: [" + fromEmail + "] Subject:"+subj);
	                
	                // allow starts with "[EGI-2.1]xxx" change to "post EGI-2.1 xxx"
	                if (subj.charAt(0) == '[') {
	                	// first I don't want the lowercase, get back the original
	                	subj = m.getSubject().trim();
	                	
	                	int endIdx;
	                	StringBuffer sBuf = new StringBuffer();
	                	if ((endIdx=subj.indexOf(']')) != -1) {
	                		sBuf.append("post ");
	                		sBuf.append(subj.substring(1, endIdx));		// copy EGIFN-1.1
	                		if (subj.charAt(endIdx+1) != ' ')
	                			sBuf.append(' ');			// add space before real mail subject starts
	                		sBuf.append(subj.substring(endIdx+1));
	                		subj = sBuf.toString();
	                		changedSubj = subj;
	                		// POP3 cannot do m.setSubject()
	                	}
	                }

	                // Process command specified in Subject
	                if (subj.startsWith(OP_COPY)) {
	                	// copy OMM object in XML
	                	copy(m);
	                }
	                else if (subj.startsWith(OP_UPLOAD)) {
	                	// upload files attached to the mail (must be multipart message)
		                upload(m, false, changedSubj);
	                }
	                else if (subj.startsWith(OP_POST)) {
	                	// post the content of the email to the task and upload the attachments
		                upload(m, true, changedSubj);
	                }
	                else {
	                	// even rejected messages will be deleted
	                	reject(m, "RoboMail command failed.  The command in the subject line is not understood by PRM RoboMail."
	                			+ "<br>Subject: " + subj);
	                }

	                //
	                //Delete the message
	                //
	                m.setFlag(Flag.DELETED, true);
	            }	// END for each message received

	            // finished all the read messages, disconnect.
	            pop3.disconnect();
	            exceptionCount = 0;
	            
				}	// static synchronized block

			}
			catch (Exception e)
			{
				l.error("RoboMailThread got exception: " + e.toString());
				if (++exceptionCount >= 3) {
					l.info("RoboMailThread exit after " + exceptionCount + " consecutive exceptions.");
					return;
				}
				continue;		// on error, continue on while loop to try again
			}

			// when done with email, sleep for a WORK_PERIOD (1 min)
			try {Thread.sleep(WORK_PERIOD*60000);}		// check once every 1 min
			catch (InterruptedException e) {}
		}	// END: while running
	}

	//
	// copy an OMM member provided in the body of the email in XML format
	//
	private boolean copy(MimeMessage m)
	{
		try
		{
	        String fromEmail = getPlainFrom(m);
	        PstUserAbstractObject u = null;
	        try {u = (PstUserAbstractObject)uMgr.get(jwu, fromEmail);}
	        catch (PmpException e)
	        {
	        	// try to use the Email to locate the user
	        	int [] ids = uMgr.findId(jwu, "Email='" + fromEmail + "'");
	        	if (ids.length <= 0) {
	        		// cannot find the user
		        	reject(m, "RoboMail copy command rejected.  You are not authorized to perform the action.");
		        	return false;
	        	}
	        	u = (PstUserAbstractObject) uMgr.get(jwu, ids[0]);
	        }
	        Object msgContent = m.getContent();
	        String xmlMsg = msgContent.toString();
	        xmlMsg = Util3.getXMLValue(xmlMsg, Util3.PRM_OBJECT);		// only look at PRM_OBJECT portion of XML
	        String className = Util3.getXMLValue(xmlMsg, Util3.PRM_CLASS);

	        boolean isMeeting = false;
	        boolean isQuest = false;
	        PstManager mgr;
	        PstAbstractObject newObj;
	        if (className.equals(mtgMgr.getClass().getName()))
	        {
	        	mgr = mtgMgr;
		        newObj = mtgMgr.create(jwu);
	        	isMeeting = true;
	        }
	        else if (className.equals(qMgr.getClass().getName()))
	        {
	        	mgr = qMgr;
		        newObj = qMgr.create(jwu);
	        	isQuest = true;
	        }
	        else
	        {
	        	// cannot handle this type
	        	l.error("RoboMail copy() cannot handle this type of object (" + className + ")");
	        	return false;
	        }

	        String s;
	        String [] tagNameArr = Util3.getXMLTagNames(xmlMsg);
	        String val, attName, idS;
	        int iType = 0, idx;
	        String [] sa;
	        Object valObj;
	        for (int i=0; i<tagNameArr.length; i++)
	        {
	        	attName = tagNameArr[i];			// usually OMM attributes, but also special tag e.g. RemoteUsername
	        	if (attName.equalsIgnoreCase(Util3.PRM_CLASS))
	        		continue;

				val = Util3.getXMLValue(xmlMsg, tagNameArr[i]);
	        	if (val==null || val.length()<=0)
	        		continue;
	        	
	        	iType = 0;

				try
				{
					if (isMeeting)
					{
						try {iType = mtgMgr.getAttributeType(attName);}
						catch (PmpException e) {l.warn("[" + attName + "] is not an OMM attribute");}
						
			        	if (Util3.EXCEPT_ATTR_MTG.indexOf(attName) != -1)
			        	{
			        		// handle exception cases
			        		if (attName.equals("Owner"))
			        		{
				        		// Owner
				        		idS = Util3.getUidFromEmail(u, val);
				        		if (idS == null)
				        			idS = String.valueOf(u.getObjectId());
				        		newObj.setAttribute("Owner", idS);
			        		}
			        		else if (attName.equals("Recorder"))
			        		{
			        			// Recorder
				        		idS = Util3.getUidFromEmail(u, val);
				        		if (idS == null)
				        			idS = String.valueOf(u.getObjectId());
				        		newObj.setAttribute("Recorder", idS);
			        		}
			        		else if (attName.equals("Attendee"))
			        		{
			        			// Attendee
								// each value looks like jdoe@gmail.com::MandatoryAcceptLogonPresent
			        			sa = val.split(Util3.TERMINATOR0);
			        			for (int j=0; j<sa.length; j++)
			        			{
			        				val = sa[j];
				        			idx = val.indexOf(Util3.TERMINATOR1);
					        		idS = Util3.getUidFromEmail(u, val.substring(0, idx));
					        		if (idS == null) continue;			// no such user, ignored
					        		val = idS + val.substring(idx);
					        		newObj.appendAttribute("Attendee", val);
			        			}
			        		}
			        		else if (attName.equals("AgendaItem"))
			        		{
			        			// AgendaItem
								// each value looks like 0::0::0::Review last week's actions::30::jdoe@gmail.com
			        			sa = val.split(Util3.TERMINATOR0);
			        			for (int j=0; j<sa.length; j++)
			        			{
			        				val = sa[j];
			        				idx = val.lastIndexOf(Util3.TERMINATOR1) + 2;
			        				s = val.substring(idx);			// email or -1 or -2
			        				if (s.charAt(0) == '-')
			        				{
			        					newObj.appendAttribute("AgendaItem", val);
			        					continue;
			        				}
			        				idS = Util3.getUidFromEmail(u, s);
			        				if (idS == null)
			        					idS = "-1";					// no one; String.valueOf(u.getObjectId());
			        				val = val.substring(0, idx) + idS;
			        				newObj.appendAttribute("AgendaItem", val);
			        			}
			        		}
			        		else if (attName.equals(Util3.TAG_REMOTE_UNAME)) {
			        			// use the username to find uid and put as attendee
			        			idS = Util3.getUidFromUsername(u, val);
			        			if (!StringUtil.isNullOrEmptyString(idS))
			        				newObj.appendAttribute("Attendee", idS + "::Mandatory");
			        		}

			        		continue;	// ignore others; next attr
			        	}
					}
					else if (isQuest)
					{
						try {iType = qMgr.getAttributeType(attName);}
						catch (PmpException e) {l.warn("[" + attName + "] is not an OMM attribute");}
						
			        	if (Util3.EXCEPT_ATTR_QST.indexOf(attName) != -1)
			        	{
			        		// handle exception cases
			        		if (attName.equals("Creator"))
			        		{
				        		// Creator
				        		// use the email to find the person.  If not found, use the XML email sender
				        		idS = Util3.getUidFromEmail(u, val);
				        		if (idS == null)
				        			idS = String.valueOf(u.getObjectId());
				        		newObj.setAttribute("Creator", idS);
			        		}
			        		else if (attName.equals("Attendee"))
			        		{
				        		// Attendee
				        		sa = val.split(Util3.TERMINATOR0);
				        		for (int j=0; j<sa.length; j++)
				        		{
				        			// 12345
				        			idS = Util3.getUidFromEmail(u, sa[j]);
				        			if (idS != null)
				        				newObj.appendAttribute("Attendee", idS);
				        		}
			        		}
			        		else if (attName.equals(Util3.TAG_REMOTE_UNAME)) {
			        			// use the username to find uid and put as attendee
			        			idS = Util3.getUidFromUsername(u, val);
			        			if (!StringUtil.isNullOrEmptyString(idS))
			        				newObj.appendAttribute("Attendee", idS);
			        		}

			        		continue;		// ignore the rest, next attr
			        	}
					}

					// for non-exceptional type
					if (iType > 0 ) {
						sa = val.split(Util3.TERMINATOR0);
						for (int j=0; j<sa.length; j++)
						{
							if (sa[j].length() <= 0) continue;
							switch (iType)
							{
								case PstAbstractObject.INT:
									valObj = new Integer(sa[j]);
									break;
								case PstAbstractObject.FLOAT:
									valObj = new Float(sa[j]);
									break;
								case PstAbstractObject.STRING:
									valObj = new String(sa[j]);
									break;
								case PstAbstractObject.DATE:
									valObj = Util3.df0.parse(sa[j]);
									break;
								case PstAbstractObject.RAW:
									valObj = sa[j].getBytes();
									break;
								default:
									l.error("Unsupported data type.");
									continue;
							}
							newObj.appendAttribute(attName, valObj);
						}	// END for each value in the value array
					}
				}
				catch (Exception e) {l.error("exception in getting attribute value for [" + attName + "]");}
	        }	// END for each attr in the XML message

	        mgr.commit(newObj);
	        l.info("Created new " + className + " object [" + newObj.getObjectId() + "]");
		}
		catch (Exception e)
		{
			e.printStackTrace();
			reject(m, "Copy command failed in copy() operation. " + e.toString());
			return false;
		}
		return true;
	}

	//
	// upload or post
	// upload multiple files with or without posting the email body to the blog
	//
	private boolean upload(MimeMessage m, boolean bPostMsg, String changedSubj)
	{
		try
		{
	        Object msgContent = m.getContent();
	        if (!(msgContent instanceof MimeMultipart))
	        {
	        	reject(m, "Post/Upload command failed.  Unsupported message type - you must use MimeMultipart.");
	        	return false;
	        }

	        // get the target object ID
	        //subj = subj.replace("fw:", "").replace("re:", "").trim();
	        String commandS = "";

			// upload/post 12345 user's optional subject
	        String subj = null;
	        if (changedSubj == null) {
	        	subj = m.getSubject();
	        }
	        else {
	        	subj = changedSubj;		// for [EGIFN-1.1], changedSubj is now "post EGIFN-1.1 xxx"
	        }
	        String [] sa = subj.split(" ");
	        if (sa.length < 2)
	        {
	        	reject(m, "Post/Upload command failed.  You must specify the target task ID or project tag for the files to be uploaded to.");
	        	return false;
	        }

	        String pjAbbrev = null;
	        String taskIdS = sa[1].trim();

	        commandS = sa[0] + " " + sa[1];			// e.g. upload 12345 or post ABC-2.1

	        int taskId = 0;							// taskId
	        String taskMatchName = null;
	        try {taskId = Integer.parseInt(taskIdS);}
	        catch (Exception e)
	        {
				// now support doing: post/upload UCAHP-2.1
	        	// UCAHP-2.1 or UCAHP
	        	// also support UCAHP-competition (match the first occurrence of the word "competition" for task name
	        	int idx = taskIdS.indexOf("-");
	        	if (idx == -1) {
	        		// case of UCAHP only
					pjAbbrev = taskIdS;		// UCAHP
					taskIdS = "";
				}
				else {
					// case of UCAHP-2.1 or UCAHP-competition
					pjAbbrev = taskIdS.substring(0, idx).trim();	// UCAHP
					taskIdS = taskIdS.substring(idx+1).trim();		// assume 2.1
					try {Float.parseFloat(taskIdS);}
					catch (Exception ee) {
						// it is not 2.1, assume it is UCAHP-competition
						taskMatchName = taskIdS;
						taskIdS = "";		// turn it into the case like UCAHP only and be handle below
					}
				}
	        }

	        String optSubj = null;
	        if (sa.length > 2) {
	        	optSubj = subj.substring(subj.indexOf(sa[2]));	// remove post... or [EGIFN-1.1] etc.
	        }

	        // get ready to check for link file collision later
	    	boolean bReject = false;
	    	PstAbstractObject [] linkDocArr = new PstAbstractObject[0];
			int [] ids = attMgr.findId(jwu, "Link='" + taskIdS + "'");
			linkDocArr = attMgr.get(jwu, ids);

	        // authorization check
	        // only project team member can upload to the project task
	        int idx1;
	        PstAbstractObject taskObj, pjObj=null;
	        user uObj;
	        String fromEmail = getPlainFrom(m);
	        System.out.println("Processing RoboMail request from [" + fromEmail + "]");
	        try {uObj = (user)uMgr.get(jwu, fromEmail);}
	        catch (Exception e)
	        {
				// try to see if fromEmail is found in Email attribute
				int [] tempIds = uMgr.findId(jwu, "Email='" + fromEmail + "'");
				if (tempIds.length <= 0) return false;
				uObj = (user)uMgr.get(jwu, tempIds[0]);
			}
	        int uid = uObj.getObjectId();
	        String myName = uObj.getFullName();

	        // check to see if I need to get taskId from project abbreviation
	        if (taskId == 0) {
	        	// try decode post UCAHP-2.1.  Using UCAHP-2.1 to find taskId
	        	pjObj = pjMgr.getProjectByAbbreviation(uObj, pjAbbrev);
	        	if (pjObj == null) {
	        		reject(m, "Post/Upload command failed.  (" + subj + ") is not a valid command.  E.g. upload 12345");
	        		return false;
				}

				// now get task from header number.  e.g. 2.1
				if (taskIdS != "") {
					try {Float.parseFloat(taskIdS);}
					catch (Exception e) {
						// now support doing: post/upload UCAHP-2.1
						reject(m, "Post/Upload command failed.  (" + subj + ") is not a valid command.  E.g. upload UCAHP-2.1");
						return false;
					}
					// the case of UCAHP-2.1
					// taskIdS is 2.1 or something like that
					taskIdS = ((project)pjObj).getTaskByHeader(uObj, taskIdS);
					taskId = Integer.parseInt(taskIdS);
				}
				else {
					// either the case of UCAHP without the task header number (same as UCAHP-other)
					// or the case of UCAHP-competition
					task tk;
					String tkName;
					int [] tids = ((project)pjObj).getCurrentTasks(uObj);
					for (int i=0; i<tids.length; i++) {
						tk = (task)tMgr.get(uObj, tids[i]);
						tkName = ((String)tk.getPlanTask(uObj).getAttribute("Name")[0]).trim().toLowerCase();
						if ( (taskMatchName!=null && tkName.contains(taskMatchName)) ||
							 tkName.equals("other") ||
							 tkName.equals("others")) {
							// found task
							taskId = tids[i];
							taskIdS = String.valueOf(taskId);
							break;
						}
					}
					if (taskId == 0) {
						reject(m, "Post/Upload command failed.  (" + subj + ") cannot find the task to complete the command.");
						return false;
					}
				}
				l.info("Robomail translated [" + commandS + "] to task [" + taskIdS + "]");
			}

	        taskObj = tMgr.get(jwu, taskId);
	        String projIdS = (String)taskObj.getAttribute("ProjectID")[0];
	        if (pjObj == null)
	        	pjObj = pjMgr.get(jwu, Integer.parseInt(projIdS));
	        if (pjObj.getAttribute("Type")[0].equals("Private") && !Util2.foundAttribute(pjObj, "TeamMembers", uid))
	        {
	        	reject(m, "Post/Upload command failed.  You don't have authority to post to this task (" + taskId + ")");
	        	return false;
	        }

	        //
	        // now ready to upload the file attachments
	        //
	        String s;
            InputStream io;
			byte [] contentBuf = new byte[8192];
			FileOutputStream fos;
			File newF=null, dirObj;
			FileTransfer ft = new FileTransfer(uObj);
			PstAbstractObject attObj;
			String sessErrMsg = "";
			String fileLinkS = "";
			String optMsg = null;
			boolean bUploadedFile = false;
			String mailContentType = null;	// to support multi-byte charset
			String charsetName = null;
			int ct = 0;
			int mpCount = 0;

			MimeMultipart mp = (MimeMultipart) msgContent;
			try {mpCount = mp.getCount();}
			catch (MessagingException e) {
				l.error("Error in upload(): failed to get multipart in mail. mp.getCount() Exception.");
				return false;
			}
			
            if (mp!=null && mpCount>0)
            {
            	// ensure the upload directory is there
            	String dirStr = UPLOAD_PATH + "/" + taskIdS;
            	dirObj = new File(dirStr);
            	if (!dirObj.exists())
            		dirObj.mkdirs();			// create the C:/Repository/CR/12345 directory

                for (int j=0; j<mpCount; j++)
                {
                    MimeBodyPart bp = (MimeBodyPart) mp.getBodyPart(j);

                    // get the attachment content
                    String fname = bp.getFileName();

                    if (!bPostMsg && fname==null)
                    	continue;

					if (fname==null)
					{
						// this is the content of the message
						if (bp.getContent() instanceof MimeMultipart)
						{
							MimeMultipart tempMp = (MimeMultipart) bp.getContent();
							bp = (MimeBodyPart)tempMp.getBodyPart(0);				// this is just the content
						}
						optMsg = bp.getContent().toString();
						s = bp.getContentType();
						if (s != null) s = s.toLowerCase();
						System.out.println("Robomail handling email content type: " + s);
						if (s==null || !s.contains("html")) {
							// mainly have to deal with RTF email
							optMsg = optMsg.replaceAll("<\\S[^>]*>", "");
							optMsg = optMsg.replaceAll("\n", "<br>");
						}
						if (s!=null && s.contains("charset")) {
							mailContentType = bp.getContentType();	// support multibype charset
							System.out.println("encoding=" + bp.getEncoding());
							int idx = s.indexOf("charset=");
							charsetName = mailContentType.substring(idx+8);
							System.out.println("charset="+charsetName);
						}
						continue;
					}

			        // reject if upload file collide with link files in this task
					// error checking: if the filename match any linked file, reject the upload
					bReject = false;
					for (int i=0; i<linkDocArr.length; i++)
					{
						if (Util3.getOnlyFileName(linkDocArr[i]).equalsIgnoreCase(fname))
						{
							bReject = true;
							if (sessErrMsg.length() <= 0)
								sessErrMsg = "The following file(s) are not uploaded:<br>";
							sessErrMsg += "- " + fname + ": filename collides with a linked file.<br>";
							break;
						}
					}
					if (bReject) continue;

                    io = bp.getInputStream();
                    newF = new File(fname);
                    newF.createNewFile();
                    fos = new FileOutputStream(newF);

					int count = 0;
					int len = 0; // Check total length read
					while((count = io.read(contentBuf)) != -1)
					{
						fos.write(contentBuf, 0, count);
						fos.flush();
						len += count;
					}

					fos.close();
					io.close();
					bUploadedFile = true;

					// save the file and update task object
					attObj = ft.saveFile(taskId, projIdS, newF, null, attachment.TYPE_TASK, null, null, true);	// versioning on
					taskObj.appendAttribute("AttachmentID", String.valueOf(attObj.getObjectId()));
					tMgr.commit(taskObj);
					ct++;

					// build fileLinkS for display in the blog and email notification
					if (fileLinkS.length() > 0) fileLinkS += "<br>";
					s = (String)attObj.getAttribute("Location")[0];
					if ((idx1 = s.lastIndexOf('/')) != -1)
						s = s.substring(idx1+1);
					fileLinkS += "<li><a class='plaintext' href='" + HOST + "/servlet/ShowFile?attId=" + attObj.getObjectId() + "'><u>"
								+ s + "</u></a>";

                    l.info("RoboMail uploaded attachment: " + (String)attObj.getAttribute("Location")[0] + " (" + len + " B)");
                }	// end for each attachment file
                if (bReject)
                	reject(m, "Post/Upload command completed with warning.<br>" + sessErrMsg);

                // most of the following notification/blog code is from post_updtask.jsp
                if (ct>0 || optMsg!=null)
                {
                	String projName = ((project)pjObj).getDisplayName();
                	ids = ptMgr.findId(jwu, "TaskID='" + taskIdS + "'");
                	Arrays.sort(ids);
                	int pTaskId = ids[ids.length-1];
            		String taskName = (String)ptMgr.get(jwu, pTaskId).getAttribute("Name")[0];
            		if (optSubj == null)
            		{
	            		if (ct > 0)
	            		{
		        			subj = ct + " file";
		        			if (ct > 1) subj += "s are ";
		        			else subj += " is ";
	            		}
	            		else
	            			subj = "A blog is ";
		        		subj += "posted on (" + projName + ")";
            		}
            		else {
            			subj = optSubj.trim();	// this should only be the email subject w/o post...
            		}
            		subj = "[" + app + " Blog] " + subj;
            		String nowS = df0.format(new Date());

            		StringBuffer msgBuf = new StringBuffer(4096);
            		if (optMsg != null)
            		{
        				//optMsg = "Message from " + myName + ":<br><div STYLE='font-size: 14px; font-family: Courier New'><br>"
        				optMsg = "Message from " + myName + ":<br><div><br>"
						+ optMsg + "</div><br />";
            			msgBuf = msgBuf.append(optMsg);
            			if (ct > 0) msgBuf.append("<hr>");
            		}
            		if (ct > 0)
            		{
	            		msgBuf.append(myName + " has posted " + ct + " new file");
	            		if (ct > 1) msgBuf.append("s");
	            		msgBuf.append(" on " + nowS + "<blockquote><table>");
	            		msgBuf.append("<tr><td class='plaintext' width='80'>PROJECT:</td><td class='plaintext'><a href='" + HOST + "/project/cr.jsp?projId=");
	            		msgBuf.append(projIdS + "'><u>" + projName + "</u></a></td></tr>");
	            		msgBuf.append("<tr><td class='plaintext' width='80'>TASK:</td><td class='plaintext'><a href='" + HOST + "/project/task_update.jsp?projId=");
	            		msgBuf.append( projIdS + "&taskId=" + taskIdS + "'><u>" + taskName + "</u></a></td></tr>");
	            		msgBuf.append("</table></blockquote>You may click on the following filename to open the file:<blockquote><ul>");
	            		msgBuf.append(fileLinkS);
	            		msgBuf.append("</ul></blockquote>");
            		}

            		// we must blog, but check to see if we need to send notification email
            		Object [] userIdArr = null;
            		String optStr = (String)pjObj.getAttribute("Option")[0];
            		if (optStr!=null && optStr.indexOf(project.OP_NOTIFY_BLOG)!=-1)
            		{
            			// need to send team notification email
            			userIdArr = pjObj.getAttribute("TeamMembers");		// userIdArr was null
            			Util.sendMailAsyn(uObj, fromEmail, userIdArr, null, null, subj, msgBuf.toString(),
            					MAILFILE, null, null, false, mailContentType);
            		}

            		// @ECC071408 post blog whether sending email or not
            		String blogIdS = Util2.postBlog(uObj, result.TYPE_TASK_BLOG, taskIdS, projIdS, subj,
            				msgBuf.toString(), charsetName);
            		
            		/////////////
            		// send notification event
            		// the below code is basically from post_addblog.jsp
					String lnkStr = "<blockquote class='bq_com'>uploaded email ... <a class='listlink' "
						+ "href='../blog/blog_task.jsp?blogId=" + blogIdS
						+ "&projId=" + projIdS + "&taskId=" + taskIdS
						+ "'>read more & reply</a></blockquote>";		// this link is used by both original blog or comment on task

					s = (String)pjObj.getAttribute("TownID")[0];
					event evt = PrmEvent.create(uObj, PrmEvent.EVT_BLG_PROJ, null, s, null);
					String temp = "<a href='" + Prm.getPrmHost() + "/project/proj_plan.jsp?projId="
						+ projIdS + "'>" + ((project)pjObj).getDisplayName() + "</a>";
					PrmEvent.setValueToVar(evt, "var1", temp);
					PrmEvent.setValueToVar(evt, "var2", lnkStr);
					if (Prm.isPRM()) {
						// send to project memebers
						ids = Util2.toIntArray(pjObj.getAttribute("TeamMembers"));
					}
					else {
						ids = uMgr.findId(uObj, "Towns=" + s);
					}
					ct = PrmEvent.stackEvent(uObj, ids, evt);
			    	l.info(uid + " RoboMail triggered Event [" + PrmEvent.EVT_BLG_PROJ + "] to "
			    			+ ct + " users for project (" + projIdS + ") blog.");

            		// @ECC091108 recalculate project space
            		if (bUploadedFile) {
	                	UtilThread th = new UtilThread(UtilThread.CAL_PROJ_SPACE, uObj);
	                	th.setParam(0, projIdS);
	                	th.start();
            		}
                }
            }	// end if there is any attachment
            else
            {
            	l.info("There is no attachment for this command.");
            }
		}
		catch (Exception e)
		{
			e.printStackTrace();
			reject(m, "Post/Upload command failed in upload() operation. " + e.toString());
			return false;
		}
		return true;
	}

	//
	// get the plain email format
	//
	private String getPlainFrom(MimeMessage m)
	{
		String fromEmail = null;
		try
		{
	        fromEmail = m.getFrom()[0].toString().toLowerCase();
	        int idx;
	        if ((idx = fromEmail.indexOf('<')) != -1)
	        	fromEmail = fromEmail.substring(++idx, fromEmail.indexOf('>', idx));
		}
		catch (MessagingException e) {}
        return fromEmail;
	}

	//
	// reject the command
	//
	private void reject(MimeMessage m, String msg)
	{
		// send a notification message back to the user sending the command
		// ECC: change to just send to Admin
		String subj = "[" + app + " RoboMail] Command rejected";
		String to = getPlainFrom(m);
		msg = subj + ": " + msg + " [" + to + "]";

		l.error(msg);
		
		if (bSendErrorMsg) {
			try
			{
				Util.sendMailAsyn(jwu, FROM, ADMIN_MAIL, null, null, subj, msg, MAILFILE);
			}
			catch (Exception e) {}
		}
	}

	public synchronized static boolean getRunning() {return RoboMailThread.running;}

	private synchronized static boolean setRunning(boolean running) {
		RoboMailThread.running = running;
		return RoboMailThread.running;
	}

	private synchronized static boolean checkCanRun() {
		if (!getRunning()) {
			setRunning(true);
			return true;
		}
		else {
			return false;
		}
	}
}
