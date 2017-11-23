//
//	Copyright (c) 2006 EGI Technologies.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
// $Header$
//
//	File:	$RCSfile$
//	Author:	Allen G Quan
//	Date:	$Date$
//  Description:
//      Servlet to attach or remove files. The doPost method checks the
//		available variables and either performs, attachment, removal,
//		or just saves attendee's list.
//
//  Required:
//		mid			- meeting id
//
//	Optional:
//		attachment	- the file to attach
//		fname		- the file to delete
//
//	Modification:
/////////////////////////////////////////////////////////////////////

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Date;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import oct.codegen.attachment;
import oct.codegen.attachmentManager;
import oct.codegen.meeting;
import oct.codegen.meetingManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstUserAbstractObject;
import oct.util.file.FileTransfer;
import oct.util.file.exception.FileTransferException;
import util.PrmMtgConstants;
import util.PrmUpdateCounter;
import util.Util;

import com.oreilly.servlet.MultipartRequest;

public class PrmFileAttachment extends HttpServlet implements PrmMtgConstants {
	
	public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
		PstUserAbstractObject pstuser = null;
		HttpSession httpSession = request.getSession(false);
		String midS = request.getParameter(MID);
		String message = "modify"; // used to display message if there is an error
		int myUid = 0;
		int recorderId = 0; 
		boolean isRun = true; // Only Recorders can access this servlet
		
		try {
			if (httpSession != null)
				pstuser = (PstUserAbstractObject)httpSession.getAttribute(PSTUSER);
			if (pstuser == null || midS == null) { 
				// TODO: post lost session 
				return; 	
			}
			
			// get meeting object
			meetingManager mMgr = meetingManager.getInstance();
			meeting mtg = (meeting)mMgr.get(pstuser, midS);
			// save attendee's checkbox list
			PrmLiveMtg.saveAttendeeList(request, mtg);
			// get user id
			myUid = pstuser.getObjectId();
			recorderId = PrmLiveMtg.getRecorderId(mtg);
			// Recorder status is revoked; do not save anything at all
			if (recorderId!=myUid) {
				PrmLiveMtg.createXmlRedirect(REVOKEDRECORDER + new Date(), "mtg_live.jsp?mid="+midS, response);
				return;
			}
			
			// file attachment upload
			String fileName = request.getParameter("Attachment"); // File to be attached
			String aID = request.getParameter("fname");	// File to be deleted; attributeName-filename.ext e.g. Attachment-abc.txt
			if (fileName != null && fileName.length() > 0) { // The length is to avoid files that are null
				message = "upload";
				saveFileAttachment(pstuser, mtg, fileName, request);
				PrmUpdateCounter.updateOrCreateCounterArray(midS, ATINDEX);
			}
			else if (aID != null) {
				message = "delete";
				deleteFileAttachment(pstuser, midS, mtg, aID);
				PrmUpdateCounter.updateOrCreateCounterArray(midS, ATINDEX);
			}
			
			//mtg.setAttribute(LASTUPDATEDDATE, new Date()); // Update lastUpdatedDate
			mMgr.commit(mtg);
			String atObjString = PrmLiveMtg.createATTable(pstuser, mtg.getAttribute(ATTACHMENTID), midS, isRun);
			
			ArrayList[] psNadLists = PrmLiveMtg.fetchPresentAttendeeList(mtg, myUid, mMgr);
			StringBuffer onlineStrBuf = new StringBuffer();
			String adObjString = PrmLiveMtg.createADTable(pstuser, psNadLists, isRun, midS, onlineStrBuf);
			Util.sortExUserList(pstuser, psNadLists[2]); // exchange the list of ids with list of users and sort
			
			PrmLiveMtg.createXml(null, null, null, null, null, null, atObjString, null, adObjString, onlineStrBuf.toString(), psNadLists[2], recorderId, null, null, -1, response);
		} catch (Exception e) {
			e.printStackTrace();
			String msg = e.getMessage();
			if (msg == null) msg = "";
			response.sendRedirect("../out.jsp?e=Failed to " + message + " file for meeting [" + midS + "]. " + msg);
		} 
	}

	private void deleteFileAttachment(PstUserAbstractObject pstuser, String midS, meeting mtg, String aID) throws PmpException {
		// delete file
		attachmentManager attmtMgr = attachmentManager.getInstance();
		attachment attmtObj = null;
		attmtObj = (attachment)attmtMgr.get(pstuser, aID);
		String filePath = null;
		Object obj = attmtObj.getAttribute("Location")[0]; 
		String fileLocation = (obj!=null)?obj.toString():"";
		
		if (Util.isAbsolutePath(fileLocation)) {
			filePath = fileLocation;
		}
		else {
			filePath = Util.getPropKey("pst", "FILE_UPLOAD_PATH");
			filePath += fileLocation;
		}
		File f = new File(filePath);
		if (f.exists()) {
			f.delete();
		}

		// cleanup the object and attribute id
		attmtMgr.delete(attmtObj);
		mtg.removeAttribute(ATTACHMENTID, aID);
	}

	private void saveFileAttachment(PstUserAbstractObject pstuser, meeting mtg, String fileName, HttpServletRequest request) throws FileTransferException, FileNotFoundException, IOException, PmpException {
		String repository = Util.getPropKey("pst", "FILE_UPLOAD_PATH");
		MultipartRequest mrequest = new MultipartRequest(request, repository, 100*1024*1024);
		
		File AttachmentFileObj = mrequest.getFile("Attachment");
		if (AttachmentFileObj != null)
		{
			FileTransfer ft = new FileTransfer(pstuser);
			String projIdS = (String)mtg.getAttribute("ProjectID")[0];

			// don't use versioning
			attachment att = ft.saveFile(mtg.getObjectId(), projIdS, AttachmentFileObj,
					null, attachment.TYPE_MEETING, null, null, false);
			mtg.appendAttribute(ATTACHMENTID, String.valueOf(att.getObjectId()));
		}
	}
}
