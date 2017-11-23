//
//  Copyright (c) 2008, EGI Technologies.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   Util3.java
//  Author:
//  Date:   11/06/2008
//  Description:
//
//  Modification:
//
/////////////////////////////////////////////////////////////////////
//
// Util3.java : implementation of the Util3 class for PRM
//
package util;

import java.awt.Container;
import java.awt.Graphics2D;
import java.awt.Image;
import java.awt.MediaTracker;
import java.awt.RenderingHints;
import java.awt.Toolkit;
import java.awt.image.BufferedImage;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.Hashtable;

import javax.servlet.http.HttpSession;

import oct.codegen.attachment;
import oct.codegen.attachmentManager;
import oct.codegen.event;
import oct.codegen.meetingManager;
import oct.codegen.plan;
import oct.codegen.project;
import oct.codegen.projectManager;
import oct.codegen.questManager;
import oct.codegen.req;
import oct.codegen.reqManager;
import oct.codegen.townManager;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstManager;
import oct.pst.PstUserAbstractObject;

import org.apache.log4j.Logger;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

import com.sun.image.codec.jpeg.JPEGCodec;
import com.sun.image.codec.jpeg.JPEGEncodeParam;
import com.sun.image.codec.jpeg.JPEGImageEncoder;

public class Util3 {

	private static final String PRM_OPEN				= "<";
	private static final String PRM_CLOSE				= ">";
	private static final String PRM_SLASH_OPEN			= "</";

	public static final String TERMINATOR0				= "@@";
	public static final String TERMINATOR1				= "::";
	public static final String PRM_OBJECT				= "PRM_OBJECT";
	public static final String PRM_CLASS				= "CLASS";

	public static final String EXCEPT_ATTR_MTG			= "Owner;Recorder;Attendee;AgendaItem;AttachmentID;TownID;ViewBlogNum;RemoteUsername";
	public static final String EXCEPT_ATTR_QST			= "Creator;Attendee;ParentID;MeetingID;Summary;TownID;RemoteUsername";

	public static final String TAG_REMOTE_UNAME			= "RemoteUsername";
	
	private static final String MAILFILE				= "alert.htm";
	private static final String NODE					= Util.getPropKey("pst", "PRM_HOST");
	private static final String uploadPath				= Util.getPropKey("pst", "FILE_UPLOAD_PATH");
	private static final String showFilePath			= Util.getPropKey("pst", "SHOW_FILE_PATH");
	private static final String urlFilePath			= Util.getPropKey("pst", "URL_FILE_PATH");

	private static final String REGX_HTML				= "<\\S[^>]*>";					// remove HTML

	private static final String IMG_FILE_EXT			= ".jpg.gif.bmp";

	public static final SimpleDateFormat df0 = new SimpleDateFormat("MM/dd/yyyy HH:mm:ss");
	public static final SimpleDateFormat df1 = new SimpleDateFormat("MM/dd/yyyy HH:mm");

	private static userManager 			uMgr;
	private static attachmentManager 	attMgr;
	private static meetingManager 		mtgMgr;
	private static questManager 		qMgr;
	private static reqManager			rqMgr;
	private static townManager			tMgr;
	private static projectManager		pjMgr;
	private static Logger l;

	static {
		l = PrmLog.getLog();

		try {
			uMgr	= userManager.getInstance();
			attMgr	= attachmentManager.getInstance();
			mtgMgr	= meetingManager.getInstance();
			qMgr	= questManager.getInstance();
			rqMgr	= reqManager.getInstance();
			tMgr	= townManager.getInstance();
			pjMgr	= projectManager.getInstance();
		} catch (PmpException e) {
			uMgr	= null;
			attMgr	= null;
			mtgMgr	= null;
			qMgr	= null;
			rqMgr	= null;
			tMgr	= null;
			pjMgr	= null;
		}
	}

	// extract only the filename from the attachment object without the versioning
	public static String getOnlyFileName(PstAbstractObject attObj)
	{
		String fName = "";
		try
		{
			fName = (String)attObj.getAttribute("Location")[0];
			fName = getOnlyFileName(fName);
		}
		catch (PmpException e)
		{
			e.printStackTrace();
		}
		return fName;
	}

	public static String getOnlyFileName(String fName)
	{
		int idx1, idx2;
		idx1 = fName.lastIndexOf('/');
		if (idx1 == -1)
			idx1 = fName.lastIndexOf('\\');
		if (idx1 != -1)
			fName = fName.substring(idx1+1);				// remove the path info
		if ((idx1 = fName.indexOf('(')) != -1)
		{
			// remove the versioning
			idx2 = fName.indexOf(')');
			fName = fName.substring(0, idx1) + fName.substring(idx2+1);
		}
		return fName;
	}

	// get the file version number from the filename
	public static int getFileVersion(String fName)
	{
		// e.g. test(5).txt will return 5
		int idx1, idx2;
		idx1 = fName.lastIndexOf('/');
		if (idx1 == -1)
			idx1 = fName.lastIndexOf('\\');
		if (idx1 != -1)
			fName = fName.substring(idx1+1);				// remove the path info

		if ((idx1 = fName.lastIndexOf('(')) == -1)
			return 0;				// no versioning info
		if ((idx2 = fName.lastIndexOf(')')) == -1)
			return 0;
		try
		{
			int ver = Integer.parseInt(fName.substring(idx1+1, idx2));
			return ver;
		}
		catch (Exception e) {return 0;}
	}

	// given a filename (with or without version), get the oldest version file attachment object
	public static PstAbstractObject getOldestVersionFile(PstUserAbstractObject u, int objId, String fName)
		throws PmpException
	{
		// the file belongs to the object of objId, located at .../objId/fName
		int lowestVer = getFileVersion(fName);
		if (lowestVer <= 0)
			return null;

		PstAbstractObject attObj = null;
		int idx1, idx2;
		if ((idx1 = fName.indexOf('(')) == -1)
			return null;
		if ((idx2 = fName.lastIndexOf(')')) == -1)
			return null;

		String loc;
		int ver;
		fName = objId + "/" + fName.substring(0, idx1+1) + "%" + fName.substring(idx2);
		int [] ids = attMgr.findId(u, "Location='%" + fName + "'");
		for (int i=0; i<ids.length; i++)
		{
			PstAbstractObject o = attMgr.get(u, ids[i]);
			loc = (String)o.getAttribute("Location")[0];
			ver = getFileVersion(loc);
			if (ver <= lowestVer)
			{
				attObj = o;
				lowestVer = ver;
			}
		}
		return attObj;
	}

	//
	// Construct an XML for the OMM object and send email to RoboMail for copying the object over
	//
	public static void sendRoboMail(PstUserAbstractObject u, PstManager mgr, String idS)
	{
		try
		{
			// get RoboMail address
			String to = Util2.getUserPreference(u, "RoboMail");
			if (to==null || to.length()<=0)
				return;												// no RoboMail address specified
			
			// the RoboMail user attribute may contain a part about remote site username
			int idx;
			String remoteUsername = null;
			if ((idx=to.indexOf(':')) != -1) {
				remoteUsername = to.substring(idx+1);
				to = to.substring(0, idx);
			}

			PstAbstractObject obj = mgr.get(u, idS);				// quest or meeting
			StringBuffer sBuf = new StringBuffer(4096);
			sBuf.append(PRM_OPEN + PRM_OBJECT + PRM_CLOSE);			// <PRM_OBJECT>
			sBuf.append(PRM_OPEN + PRM_CLASS + PRM_CLOSE);			// <CLASS>
			sBuf.append(mgr.getClass().getName());					// e.g. meetingManager
			sBuf.append(PRM_SLASH_OPEN + PRM_CLASS + PRM_CLOSE);	// </CLASS>

			// construct an XML message based on the value of the object
			boolean isMeeting = false;
			boolean isQuest = false;
			String [] attNames = null;
			String exceptAttr = "";
			if (mgr instanceof meetingManager)
			{
				// copy meeting
				isMeeting = true;
				attNames = ((meetingManager)mgr).getAllAttributeNames();
				exceptAttr = EXCEPT_ATTR_MTG;
			}
			else if (mgr instanceof questManager)
			{
				// copy event/questionnaire
				isQuest = true;
				attNames = ((questManager)mgr).getAllAttributeNames();
				exceptAttr = EXCEPT_ATTR_QST;
			}
			else
			{
				// can't handle other types
				l.error("sendRoboMail does not support this object type (" + mgr.getClass().getName() + ")");
				return;
			}

			// create XML values for each attribute
			String attName, valStr;
			int iType = 0;
			Object [] valArr;
			for (int i=0; i<attNames.length; i++)
			{
				// create each value as XML
				attName = attNames[i];
				if (exceptAttr.indexOf(attName) != -1)
					continue;										// ignore this attr: will handle below
				valArr = obj.getAttribute(attName);

				// insert values, separated by terminator @@
				valStr = "";
				try
				{
					if (isMeeting) iType = mtgMgr.getAttributeType(attName);
					else if (isQuest) iType = qMgr.getAttributeType(attName);

					for (int j=0; j<valArr.length; j++)
					{
						if (valArr[j]==null) break;
						if (valStr.length() > 0) valStr += TERMINATOR0;	// @@
						switch (iType)
						{
							case PstAbstractObject.INT:
								valStr += ((Integer)valArr[j]).toString();
								break;
							case PstAbstractObject.FLOAT:
								valStr += ((Float)valArr[j]).toString();
								break;
							case PstAbstractObject.STRING:
								valStr += (String)valArr[j];
								break;
							case PstAbstractObject.DATE:
								valStr += df0.format((Date)valArr[j]);
								break;
							case PstAbstractObject.RAW:
								valStr += new String((byte [])valArr[j]);
								break;
							default:
								break;
						}
					}	// END for each value in the value array
				}
				catch (PmpException e) {l.error("no such attribute [" + attName + "]");}

				if (valStr.length() > 0)
				{
					sBuf.append(PRM_OPEN + attName + PRM_CLOSE);		// <attrName>
					sBuf.append(valStr);
					sBuf.append(PRM_SLASH_OPEN + attName + PRM_CLOSE);	// </attrName>
				}
			}	// END for each attribute

			// handle special case
			String s, temp;
			Object [] oArr;
			int id;
			String [] sa;

			if (isMeeting)
			{
				// 1. for meeting: change Owner, Recorder and Attendee to email addresses
				sBuf.append(getUserEmailTag(u, obj, "Owner"));			// included tags
				sBuf.append(getUserEmailTag(u, obj, "Recorder"));
				sBuf.append(getXMLTag(TAG_REMOTE_UNAME, remoteUsername));

				// Attendees
				sBuf.append(PRM_OPEN + "Attendee" + PRM_CLOSE);			// <Attendee>
				oArr = obj.getAttribute("Attendee");
				valStr = "";
				for (int i=0; i<oArr.length; i++)
				{
					// each value looks like 12345::MandatoryAcceptLogonPresent
					if ((s = (String)oArr[i]) == null) continue;
					sa = s.split(TERMINATOR1);
					s = getUserEmail(u, sa[0]);
					if (s.length() <= 0)
						continue;
					if (valStr.length() > 0) valStr += TERMINATOR0;		// @@
					valStr += s;										// append the email address
					if (sa.length > 1)
						valStr += TERMINATOR1 + sa[1];					// ... @@jdoe@gmail.com::MandatoryAccept
				}
				sBuf.append(valStr);
				sBuf.append(PRM_SLASH_OPEN + "Attendee" + PRM_CLOSE);	// </Attendee>

				// Agenda
				sBuf.append(PRM_OPEN + "AgendaItem" + PRM_CLOSE);		// <AgendaItem>
				oArr = obj.getAttribute("AgendaItem");
				valStr = "";
				for (int i=0; i<oArr.length; i++)
				{
					// each value looks like 0::0::0::Review last week's actions::30::12345
					// the uid field can be -1 (no one) or -2 (all)
					if ((s = (String)oArr[i]) == null) continue;
					idx = s.lastIndexOf(TERMINATOR1)+2;
					temp = s.substring(idx);
					id = Integer.parseInt(temp);						// extract the userId
					if (id <= 0)
					{
						// not a user id
						if (valStr.length() > 0) valStr += TERMINATOR0;	// @@
						valStr += s;									// just copy the whole string
						continue;
					}

					// translate to email
					temp = getUserEmail(u, temp);
					if (s.length() <= 0)
						continue;										// no email, ignore
					if (valStr.length() > 0) valStr += TERMINATOR0;		// @@
					valStr += s.substring(0, idx);						// copy all except userid
					valStr += temp;										// copy the email
				}
				sBuf.append(valStr);
				sBuf.append(PRM_SLASH_OPEN + "AgendaItem" + PRM_CLOSE);	// </AgendaItem>

				// AttachmentID
				// not handle for now: should copyover attachments

				// TownID (company) attribute on meeting
				// not handle for now: should use Name to try matching

				// ViewBlogNum
				// always set to 1 on the other side

				// action/decision
				// no copying of action decision: we are only interesting from the scheduling point of view

				// meeting blog
				// no copying of meeting blog: we are only interesting from the scheduling point of view
			}	// END if isMeeting
			else if (isQuest)
			{
				// quest object
				sBuf.append(getUserEmailTag(u, obj, "Creator"));			// included tags
				sBuf.append(getXMLTag(TAG_REMOTE_UNAME, remoteUsername));

				// Attendees
				sBuf.append(PRM_OPEN + "Attendee" + PRM_CLOSE);			// <Attendee>
				oArr = obj.getAttribute("Attendee");
				valStr = "";
				for (int i=0; i<oArr.length; i++)
				{
					// each value looks like 12345
					if ((s = (String)oArr[i]) == null) continue;
					s = getUserEmail(u, s);
					if (s.length() <= 0)
						continue;
					if (valStr.length() > 0) valStr += TERMINATOR0;		// @@
					valStr += s;										// append the email address
				}
				sBuf.append(valStr);
				sBuf.append(PRM_SLASH_OPEN + "Attendee" + PRM_CLOSE);	// </Attendee>

				// ignore ParentID, MeetingID, Summary, TownID
			}
			sBuf.append(PRM_SLASH_OPEN + PRM_OBJECT + PRM_CLOSE);		// </PRM_OBJECT>

			// now ready to send Email to RoboMail
			String subj = "copy";
			Util.sendMailAsyn(u, (String)u.getAttribute("Email")[0], to, null, null, subj, sBuf.toString(), MAILFILE);
			l.info("user [" + u.getObjectName() + "] sent RoboMail to [" + to + "]");

			return;
		}
		catch (PmpException e) {}
	}	// END: sendRoboMail()

	private static String getXMLTag(String tagName, String tagValue) {
		if (StringUtil.isNullOrEmptyString(tagValue)) return "";
		String ret = PRM_OPEN + tagName + PRM_CLOSE;		// e.g. <RemoteUsername>
		ret += tagValue;
		ret += PRM_SLASH_OPEN + tagName + PRM_CLOSE;		// e.g. </RemoteUsername>
		return ret;
	}
	
	private static String getUserEmailTag(PstUserAbstractObject u, PstAbstractObject obj, String attrName)
	{
		try
		{
			String s = getUserEmail(u, (String)obj.getAttribute(attrName)[0]);
			if (s.length() <= 0)
				return "";

			String ret = PRM_OPEN + attrName + PRM_CLOSE;				// <Owner>
			ret += s;
			ret += PRM_SLASH_OPEN + attrName + PRM_CLOSE;		// </Owner>
			return ret;
		}
		catch (PmpException e) {return "";}
	}

	private static String getUserEmail(PstUserAbstractObject u, String uidS)
	{
		try
		{
			PstAbstractObject o = uMgr.get(u, Integer.parseInt(uidS));
			String ret = (String)o.getAttribute("Email")[0];
			if (ret == null)
				return "";
			return ret;
		}
		catch (Exception e) {return "";}
	}

	// return all tag names in an array
	public static String [] getXMLTagNames(String xmlStr)
	{
		String str = "";
		int idx1 = 0, idx2;
		while ((idx1 = xmlStr.indexOf('<', idx1)) != -1)
		{
			if (xmlStr.charAt(++idx1) == '/') continue;
			idx2 = xmlStr.indexOf('>', idx1);
			if (str.length() > 0)
				str += TERMINATOR0;
			str += xmlStr.substring(idx1, idx2);			// extract the tag name
			idx1 = idx2;
		}
		String [] sa = str.split(TERMINATOR0);
		return sa;
	}

	//
	// parse an XML string to find the tag and return the value
	//
	public static String getXMLValue(String xmlStr, String tag)
	{
		// open the properties file and extract the value of the tag
		int idx1, idx2;

		String begTag = "<" + tag + ">";
		String endTag = "</" + tag + ">";
		int tagLen = begTag.length();

		if ((idx1 = xmlStr.indexOf(begTag)) == -1)
			return "";									// tag not found
		idx1 += tagLen;									// skip the tag name

		if ((idx2 = xmlStr.indexOf(endTag, idx1)) == -1)
			return "";

		return xmlStr.substring(idx1, idx2);
	}	// END: getXMLValue()
	

	//
	// get the userID from Email address
	//
	public static String getUidFromEmail(PstUserAbstractObject u, String email)
	{
		try
		{
			PstAbstractObject o;
			try
			{
				o = uMgr.get(u, email);
				return String.valueOf(o.getObjectId());		// found the user and return
			}
			catch (PmpException e) {}

			// not found: try to find user from Email attribute
			int [] ids = uMgr.findId(u, "Email='" + email + "'");
			if (ids.length <=0 ) return null;				// no one found

			o = uMgr.get(u, ids[0]);						// should be only one match
			return String.valueOf(o.getObjectId());
		}
		catch (PmpException e) {return null;}
	}
	
	public static String getUidFromUsername(PstUserAbstractObject u, String uname) {
		try {
			PstAbstractObject o = uMgr.get(u, uname);
			return String.valueOf(o.getObjectId());
		}
		catch (PmpException e) {return null;}
	}

	//
	// display HTML for sharing files
	// called by cr.jsp, rdata.jsp and ep_home.jsp
	// either allow Clipboard or Delete, not both
	// bRevoke will show the lock (no share)
	// iType==1 if passing filenames (no caller)
	// iType==2 if passing attIds (cr.jsp, ep_home.jsp and rdata.jsp)
	// iType==3 when ep_home.jsp calls this to display for sharing machine folders
	// fileCt normally (for iType of 1 and 2) is the # of file in the list, but for iType==3, fileCt is
	//   the host index (on ep_home.jsp).
	public static String displayShareOption(PstUserAbstractObject u, int colSpan1, int colSpan2,
			int fileCt, int iType, boolean bRevoke, boolean bClipboard, boolean bRemove)
	{
		StringBuffer sBuf = new StringBuffer(1024);
		String iTypeLabel = "" + iType;
		if (iType == 3)
			iTypeLabel += "_" + fileCt;			// this is the hostIdx

		// file count and action
		sBuf.append("<tr><td id='total' align='right' class='plaintext' colspan='" + colSpan1 + "'>");
		if (iType!=3)
			sBuf.append("(<b>Total " + fileCt + " files</b>)");
		sBuf.append("</td>");
		sBuf.append("<td colspan='5'><a name='end'></a>&nbsp;</td>");
		sBuf.append("<td colspan='" + colSpan2 + "' align='right'><table cellspacing='0' cellpadding='0'><tr>");
		if (iType!=3)
			sBuf.append("<td width='80'><a id='checkTxt' href='javascript:selectAll(\"" + iTypeLabel + "\");'>Select All</a></td>");
		sBuf.append("<td width='22'><img src='../i/handshake.jpg' onclick='javascript:share(\"" + u.getObjectName() + "\", \"" + iTypeLabel + "\");' border='0' title='Share' /></td>");
		if (bRevoke)
			sBuf.append("<td align='center'><img src='../i/lock1.jpg' onclick='lock(2);' border='0' title='No Share' /></td>");
		if (bClipboard)
			sBuf.append("<td><img src='../i/clipboard.jpg' onclick='copy();' border='0' title='Copy to Clipboard' /></td>");
		if (bRemove)
			sBuf.append("<td width='20'><img src='../i/delete.gif' onclick='del();' border='0' title='Remove' /></td>");
		sBuf.append("</tr></table>");
		sBuf.append("</td></tr>");

		// textarea for specifying share email
		sBuf.append("<tr><td colspan='4'></td><td class='formtext' colspan='16' width='380'>");
		sBuf.append("<table id='shareBox_" + iTypeLabel + "' style='display:none' border='0'>");
		sBuf.append("<tr><td><img src='../i/spacer.gif' width='10' /></td>");
		sBuf.append("<td class='inst' style='word-break:normal'>To share the selected files with other people, enter their email addresses separated by comma and click SEND.</td></tr>");

		sBuf.append("<tr><td></td><td class='plaintext'><b>Share with</b>: <span class='inst'>(e.g. jdoe@gmail.com)</span></td></tr>");
		sBuf.append("<tr><td></td>");
		sBuf.append("<td><textarea name='shareMember_" + iTypeLabel + "' id='shareMember_" + iTypeLabel + "' rows='3' cols='40' style='word-break:normal' onKeyDown='return entSub(event);'></textarea></td></tr>");

		// @ECC102108 dropdown for choosing emails
		sBuf.append("<tr><td></td><td><div id='emails_" + iTypeLabel + "' style='display:none'><select id='emailSel_" + iTypeLabel + "' class='formtext_fix' multiple size='5' name='emails' "
				+ "onKeyDown='return entSub(event);' ondblClick='pickItem();'>");

		// @ECC102108 suggestive email dropdown
		String emailStr = null;
		try {emailStr = (String)u.getAttribute("Remember")[0];}	// emails separated by ";"
		catch (PmpException e) {}
		if (emailStr == null) emailStr = "";
		if (emailStr.length() > 0)
		{
			String [] sa = emailStr.split(";");
			Arrays.sort(sa);
			for (int i=0; i<sa.length; i++)
				sBuf.append("<option value='" + sa[i] + "'>" + sa[i] + "</option>");
		}
		sBuf.append("</select></div></td></tr>");

		sBuf.append("<tr><td></td><td class='plaintext'><b>Optional message</b>:</td></tr>");
		sBuf.append("<tr><td></td>");
		sBuf.append("<td><textarea name='optMsg_" + iTypeLabel + "' rows='3' cols='40' style='word-break:normal'></textarea></td></tr>");

		sBuf.append("<tr><td></td><td align='center'>");
		sBuf.append("<input type='button' class='plaintext' name='save' value=' SEND ' onclick='javascript:add_member(" + iType + ");'>&nbsp;&nbsp;");
		sBuf.append("<input type='button' class='plaintext' name='cancel' value='CANCEL' onclick='javascript:share(null, \"" + iTypeLabel + "\");'>");
		sBuf.append("</td></tr>");
		sBuf.append("</table></td></tr>");
		return sBuf.toString();
	}	// END displayShareOption()

	public static Hashtable fillHash(String bStr, String keyword)
	{
		// work@12345@13344@ ... @@ (terminated with double @ sign)
		Hashtable hs = new Hashtable();
		int idx1, idx2;

		if ((idx1 = bStr.indexOf(keyword)) < 0)
			return hs;
		if ((idx2 = bStr.indexOf("@@", idx1)) < 0)
			bStr = bStr.substring(idx1 + keyword.length() + 1);			// cannot find terminator, assume the end
		else
			bStr = bStr.substring((idx1 + keyword.length() + 1), idx2);

		String [] sa = bStr.split("@");
		for (int i=0; i<sa.length; i++)
			hs.put(sa[i], "");

		return hs;
	}

	public static void sendRequest(PstUserAbstractObject u, String uidS, String reqType, String optMsg)
	{
		sendRequest(u, uidS, reqType, optMsg, null, null);
	}
	public static void sendRequest(PstUserAbstractObject u, String uidS, String reqType, String optMsg,
			String introName, String circleIdS)
	{
		// reqType could be REQ_FRIEND, REQ_CIRCLE, REQ_INTROF, REQ_INTROC (in req.java)
		try
		{
			String evtTypeS;
			String circleName = null;
			PstAbstractObject o;

			String requesterName = ((user)u).getFullName();
			StringBuffer sBuf = new StringBuffer(1024);
			sBuf.append(requesterName);

			if (reqType.equals(req.REQ_FRIEND))
			{
				evtTypeS = PrmEvent.EVT_REQ_FRIEND;
				sBuf.append(" requests to be your friend.");
			}
			else if (reqType.equals(req.REQ_CIRCLE))
			{
				// for circle request, uidS is the circle ID
				evtTypeS = PrmEvent.EVT_REQ_CIRCLE;		// req.REQ_CIRCLE

				// need to find the Chief of the circle to stack the approval event to
				o = tMgr.get(u, Integer.parseInt(circleIdS));
				circleName = (String)o.getAttribute("Name")[0];
				uidS = (String)o.getAttribute("Chief")[0];	// change the uidS to the recipient of the req
				if (uidS == null)
					throw new PmpException("This circle doesn't have a moderator.  Please contact the Administrator for further help.");
				sBuf.append(" requests to join the " + circleName.replaceAll(REGX_HTML, "") + " circle.");
			}
			else if (reqType.equals(req.REQ_INTROF))
			{
				evtTypeS = PrmEvent.EVT_REQ_INTROF;
				sBuf.append(" introduces " + introName.replaceAll(REGX_HTML, "") + " to you as a friend.");
			}
			else if (reqType.equals(req.REQ_INTROC))
			{
				evtTypeS = PrmEvent.EVT_REQ_INTROC;		// the recommended circle name is in introName
				sBuf.append(" recommends you to join the " + introName.replaceAll(REGX_HTML, "") + " Circle.");
			}
			else
			{
				l.error("unsupported request type: " + reqType);
				return;
			}

			// create the req object
			o = rqMgr.create(u);
			o.setAttribute("CreatedDate", new Date());
			o.setAttribute("Creator", String.valueOf(u.getObjectId()));
			o.setAttribute("Owner", uidS);						// the recipient of the request
			o.setAttribute("Type", reqType);
			o.setAttribute("TownID", circleIdS);				// for friend req, this is null

			if (optMsg!=null && optMsg.trim().length()>0)
			{
				// put formating info (for event display in ep_home.jsp) into the content before storing it
				optMsg = optMsg.replaceAll("\n", "<br>");
				StringBuffer sBuf1 = new StringBuffer(1024);
				sBuf1.append("<blockquote class='bq_note'");
				String pref = Util2.getUserPreference(u, "NoteBackground");
				if (pref != null)
					sBuf1.append(" style='background:url(" + pref + ") repeat;'");
				sBuf1.append(">");
				sBuf1.append(optMsg);
				sBuf1.append("</blockquote>");

				o.setAttribute("Content", sBuf1.toString().getBytes());
			}
			rqMgr.commit(o);

			// send a event
			event evt = PrmEvent.createTriggerEventDirect(u, evtTypeS, Integer.parseInt(uidS),
					String.valueOf(o.getObjectId()));	// include the req ID in the townID attribute of the event

			if (reqType.equals(req.REQ_CIRCLE))
				PrmEvent.setValueToVar(evt, "var1", circleName);
			else if (reqType.equals(req.REQ_INTROF) || reqType.equals(req.REQ_INTROC))
				PrmEvent.setValueToVar(evt, "var1", introName);

			// send email notification
			String subj = "[MeetWE] Networking request from " + requesterName;
			o = uMgr.get(u, Integer.parseInt(uidS));
			sBuf.append("<blockquote>");
			sBuf.append("<table border='0' cellspacing='2' cellpadding='2'>");
			sBuf.append("<tr><td class='plaintext' width='120'><b>Your Username</b>:</td><td class='plaintext'>"
				+ o.getObjectName() + "</td></tr></table></blockquote>");
			sBuf.append("Click the following link and use your username to respond to the request: ");
			sBuf.append("<a href='" + NODE + "'>" + NODE + "</a><br><br>");

			if (optMsg != null)
			{
				optMsg = "<b>Message from " + requesterName + "</b>: <hr><div STYLE='font-size:12px; font-family:Courier New'><br>"
					+ optMsg + "</div><hr><br><br>";
			}
			else
				optMsg = "";
			sBuf.append(optMsg);
			sBuf.append("If you have any questions, please contact MeetWE Support at <a href='mailto:support@meetwe.com'>");
			sBuf.append("support@meetwe.com</a>");

			Util.sendMailAsyn(u, (String)u.getAttribute("Email")[0], (String)o.getAttribute("Email")[0],
					null, null, subj, sBuf.toString(), MAILFILE);
		}
		catch (PmpException e) {e.printStackTrace();}
	}

	// create a thrumbNail JPEG from an original attachment if it is an image type
	// else return a thrumbNail logo
	public static String getThrumbNail(PstAbstractObject aObj, int thumbWidth, int thumbHeight, int quality)
	{
		String urlStr = null;
		String fNameOnly = new Date().getTime() + ".jpg";
		String outFileName = showFilePath + "/" + fNameOnly;

		try
		{
			File outF = new File(outFileName);
			if (!outF.exists())
				outF.createNewFile();

			String loc = (String)aObj.getAttribute("Location")[0];
			if (!Util.isAbsolutePath(loc))
				loc = uploadPath + loc;

			String ext = (String)aObj.getAttribute("FileExt")[0];
			if (ext == null)
			{
				String type = (String)aObj.getAttribute("Type")[0];
				if (type!=null && type.equals(attachment.TYPE_FOLDER))
					return NODE + "/i/folder.jpg";
				else
					ext = "";
			}

			if (ext.length()>0 && IMG_FILE_EXT.contains(ext))
			{
				// load image from INFILE
			    Image image = Toolkit.getDefaultToolkit().getImage(loc);
			    MediaTracker mediaTracker = new MediaTracker(new Container());
			    mediaTracker.addImage(image, 0);
			    mediaTracker.waitForID(0);
			    // determine thumbnail size from WIDTH and HEIGHT
			    double thumbRatio = (double)thumbWidth / (double)thumbHeight;
			    int imageWidth = image.getWidth(null);
			    int imageHeight = image.getHeight(null);
			    double imageRatio = (double)imageWidth / (double)imageHeight;
			    if (thumbRatio < imageRatio) {
			      thumbHeight = (int)(thumbWidth / imageRatio);
			    } else {
			      thumbWidth = (int)(thumbHeight * imageRatio);
			    }
			    // draw original image to thumbnail image object and
			    // scale it to the new size on-the-fly
			    BufferedImage thumbImage = new BufferedImage(thumbWidth,
			      thumbHeight, BufferedImage.TYPE_INT_RGB);
			    Graphics2D graphics2D = thumbImage.createGraphics();
			    graphics2D.setRenderingHint(RenderingHints.KEY_INTERPOLATION,
			      RenderingHints.VALUE_INTERPOLATION_BILINEAR);
			    graphics2D.drawImage(image, 0, 0, thumbWidth, thumbHeight, null);
			    // save thumbnail image to OUTFILE
			    BufferedOutputStream out = new BufferedOutputStream(new
			      FileOutputStream(outFileName));
			    JPEGImageEncoder encoder = JPEGCodec.createJPEGEncoder(out);
			    JPEGEncodeParam param = encoder.
			      getDefaultJPEGEncodeParam(thumbImage);
			    quality = Math.max(0, Math.min(quality, 100));
			    param.setQuality((float)quality / 100.0f, false);
			    encoder.setJPEGEncodeParam(param);
			    encoder.encode(thumbImage);
			    out.close();
			    urlStr = urlFilePath + "/" + fNameOnly;
			}	// END if image file ext
			else if (ext.equals("pdf"))
				urlStr = NODE + "/i/file_pdf.jpg";
			else if (ext.equals("doc"))
				urlStr = NODE + "/i/file_word.jpg";
			else if (ext.equals("ppt"))
				urlStr = NODE + "/i/file_ppt.jpg";
			else if (ext.equals("xls"))
				urlStr = NODE + "/i/file_excel.jpg";
			else if (ext.equals("mp3"))
				urlStr = NODE + "/i/file_mp3.jpg";
			else if (ext.equals("txt"))
				urlStr = NODE + "/i/file_txt.jpg";
			else
				urlStr = NODE + "/i/file.jpg";
		}
		catch (PmpException e) {l.error("Got PmpException in Util3.thrumbNail()");e.printStackTrace();}
		catch (IOException e) {l.error("Got IOException in Util3.thrumbNail()");e.printStackTrace();}
		catch (InterruptedException e) {l.error("Got InterruptedException in Util3.thrumbNail()");e.printStackTrace();}
		return urlStr;
	}	// END: getThrumbNail()

	public static String copyPathExceptLastPart(String path)
	{
		if (path==null || path.length()<=0)
			return "";
		int idx = path.lastIndexOf('/');
		if (idx == -1)
			idx = path.lastIndexOf('\\');
		if (idx == -1)
			return path;
		else
			return path.substring(0, idx+1);
	}

	public static String getRelativePath(File fObj, String sourcePath)
	{
		String pathName = fObj.getAbsolutePath().replaceAll("\\\\", "/");
		pathName = pathName.replaceAll(sourcePath, "");
		return pathName;
	}

	public static void refreshPlanHash(
			PstUserAbstractObject u, HttpSession sess, String pjIdS)
		throws PmpException
	{
		project pj = (project)pjMgr.get(u, Integer.parseInt(pjIdS));
		plan latestPlan = pj.getLatestPlan(u);
		sess.removeAttribute("taskNameMap");
		PrmProjThread.backgroundConstructPlan(
				sess, u, latestPlan.getObjectName(), pjIdS, true, false);
		String s = (String)sess.getAttribute("planComplete");
		while (s!=null && s.equals("false"))
		{
			try {Thread.sleep(200);}		// sleep for 0.2 sec
			catch (InterruptedException e) {}
			s = (String)sess.getAttribute("planComplete");
		}
		sess.setAttribute("projId", pjIdS);
	}

	public static Integer [] toInteger(int [] ids)
	{
		if (ids == null) return null;
		Integer [] IArr = new Integer[ids.length];
		for (int i=0; i<ids.length; i++)
			IArr[i] = new Integer(ids[i]);
		return IArr;
	}
	
	/**
	 */
	public static String getTimeString(int min)
	{
		String retStr = "";
		int hr = min/60;
		min = min%60;
		if (hr > 0) retStr = hr + " Hr";
		if (min > 0) {
			if (retStr != "") retStr += " ";
			retStr += min + " Min";
		}
		return retStr;
	}
	
	public static String listTeamMembers(PstAbstractObject [] memberList, int projCoordinatorId)
	{
		StringBuffer retBuf = new StringBuffer(512);
		int uid;
		user aUser;
		String uname;
		for (int i = 0; i < memberList.length; i++)
		{
			aUser = (user)memberList[i];
			uid = aUser.getObjectId();
			uname = aUser.getFullName();

			retBuf.append("<div class='namelist'>");
			//out.print("<a href='../ep/ep1.jsp?uid=" + uid + "' class='namelist'>" + uname);
			retBuf.append("<a href='javascript:show_action(" + uid + ",null,null,\"" + uname + "\");'>" + uname);
			retBuf.append("</a>");
			if (uid==projCoordinatorId) {
				retBuf.append("&nbsp;&nbsp;(COORDINATOR)");
			}
			retBuf.append("</div>");
			retBuf.append("<div id='" + uid + "' class='plaintext' style='display:none;'></div>");

		}
		return retBuf.toString();
	}

	
	/**
	 *
	 *	inStr might be email or username, separated by , ; or blank space
	 */
	public static String [] toUidArr(PstUserAbstractObject uObj, String inStr)
	{
		String [] retArr = new String[0];
		if (StringUtil.isNullOrEmptyString(inStr)) return retArr;
		
		String [] sa = inStr.split(",|;| ");
		String s;
		int [] ids;
		PstAbstractObject o;
		ArrayList <String> retList = new ArrayList <String> (0);
		
		for (int i=0; i<sa.length; i++) {
			s = sa[i];
			if (StringUtil.isNullOrEmptyString(s)) continue;
			s = s.trim();
			o = null;
			
			try {
				if (s.indexOf('@') != -1) {
					// email
					ids = uMgr.findId(uObj, "Email='" + s + "'");
					if (ids.length > 0) {
						o = uMgr.get(uObj, ids[0]);
					}
				}
				else {
					// username
					o = uMgr.get(uObj, s);
				}
				if (o != null)
					retList.add(String.valueOf(o.getObjectId()));
			}
			catch (PmpException e) {}
		}
		
		retArr = retList.toArray(new String[0]);
		return retArr;
	}
	
	
	/**
	 * accept an array of meeting object, eliminate meetings that are subsets of others
	 * in terms of time
	 * @param mtgArr	an array of meeting objects, sorted by StartDate
	 */
	public static void removeDupMtgTime(PstAbstractObject [] mtgArr)
	{
		PstAbstractObject m1, m2;
		Date m1Dt1, m1Dt2, m2Dt1, m2Dt2;
		int ii;
		boolean bDone;
		
		// note: m1 starts earlier or at the same time as m2
		
		for (int i=0; i<mtgArr.length-1; i++) {
			if ((m1 = mtgArr[i]) == null) continue;
			ii = i+1;
			
			bDone = false;
			while ((m2 = mtgArr[ii]) == null) {
				if (ii >= mtgArr.length-1) {
					bDone = true;
					break;		// done
				}
				else {
					ii++;
				}
			}
			
			if (bDone) break;
			
			// now check if m1, m2 are subset of one another
			try {
				m1Dt1 = (Date) m1.getAttribute("StartDate")[0];
				m1Dt2 = (Date) m1.getAttribute("ExpireDate")[0];
				m2Dt1 = (Date) m2.getAttribute("StartDate")[0];
				m2Dt2 = (Date) m2.getAttribute("ExpireDate")[0];
				
				// only consider hour and minute
				m1Dt1 = df1.parse(df1.format(m1Dt1));
				m1Dt2 = df1.parse(df1.format(m1Dt2));
				m2Dt1 = df1.parse(df1.format(m2Dt1));
				m2Dt2 = df1.parse(df1.format(m2Dt2));
				
				// if we nullify m2, we need to use the same m1 to continue checking the next m2
				
				if (!m2Dt2.after(m1Dt2)) {
					m2 = mtgArr[ii] = null;
					i--;
				}
				else if (m1Dt1.compareTo(m2Dt1)==0 && m2Dt2.after(m1Dt2)) {
					m1 = mtgArr[i] = null;
				}
			}
			catch (Exception e) {continue;}
			
		}	// END: for loop thru the meeting array
	}

}
