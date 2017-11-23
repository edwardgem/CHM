
//
//  Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   PrmArchive.java
//  Author:	ECC
//  Date:   12/21/05
//  Description:
//			Background work to archive weblogs.
//			This is called by PrmThread.java to archive blogs away once a week.
//  Modification:
//			@ECC032014a	move arcv threshold, size and other constant to pst.properties
//			@ECC032014b	change garbageCollect() to not remove the blog text.
//
//
/////////////////////////////////////////////////////////////////////
//
// PrmArchive.java : implementation of the PrmArchive class for PRM
//

package main;

import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStreamWriter;
import java.io.UnsupportedEncodingException;
import java.nio.charset.Charset;
import java.text.SimpleDateFormat;
import java.util.Date;

import oct.codegen.actionManager;
import oct.codegen.bug;
import oct.codegen.bugManager;
import oct.codegen.meetingManager;
import oct.codegen.planTask;
import oct.codegen.planTaskManager;
import oct.codegen.project;
import oct.codegen.projectManager;
import oct.codegen.result;
import oct.codegen.resultManager;
import oct.codegen.task;
import oct.codegen.taskManager;
import oct.codegen.townManager;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.codegen.userinfoManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstManager;

import org.apache.log4j.Logger;

import util.Prm;
import util.PrmLog;
import util.StringUtil;
import util.TaskInfo;
import util.Util;
import util.Util2;


public class PrmArchive
{
	static final String ARCHIVE	= "Archive";

	static final int ARCHIVE_HOUR	= 4;				// 4 AM
	static final String WORK_DAY	= "Sun";			// do archive on Sunday
	static final long SIX_DAYS		= 518400000;		// 6 * 24 * 3600000
	static final int ONE_LINER_LEN	= 200;				// archive 1-liner
	
	static private int ARCV_THRESHOLD	= 20;			// archive if blog no. > ARCV_THRESHOLE
	static private int ARCV_ACTIVE_LEFT	= 10;			// no. of blogs left in the active space
	static private int ARCV_FILE_MAX	= 15;			// target archive file total # of blogs

	static projectManager pjMgr = PrmThread.getpjMgr();
	static taskManager tkMgr = PrmThread.gettkMgr();
	static planTaskManager ptMgr = PrmThread.getptMgr();
	static resultManager rsMgr = PrmThread.getrsMgr();
	static userinfoManager uiMgr = PrmThread.getuiMgr();
	static userManager uMgr = PrmThread.getuMgr();
	static actionManager aMgr = PrmThread.getaMgr();
	static meetingManager mtgMgr = PrmThread.getmtgMgr();
	static bugManager bugMgr = PrmThread.getbugMgr();
	static townManager tnMgr = PrmThread.gettnMgr();
	
	static boolean isOMFAPP = PrmThread.isOMFAPP();
	static boolean isCRAPP = PrmThread.isCRAPP();
	static boolean isPRMAPP = PrmThread.isPRMAPP();
	
	static private boolean bAddProjectTeamSection = false;

	static user jwu = PrmThread.getuser();
	static Logger l = PrmLog.getLog();
	
	static {
		// @ECC032014a
		String s = Util.getPropKey("pst", "ARCV_THRESHOLD");
		if (!StringUtil.isNullOrEmptyString(s)) ARCV_THRESHOLD = Integer.parseInt(s.trim());
		s = Util.getPropKey("pst", "ARCV_ACTIVE_LEFT");
		if (!StringUtil.isNullOrEmptyString(s)) ARCV_ACTIVE_LEFT = Integer.parseInt(s.trim());
		s = Util.getPropKey("pst", "ARCV_FILE_MAX");
		if (!StringUtil.isNullOrEmptyString(s)) ARCV_FILE_MAX = Integer.parseInt(s.trim());
	}

	public static int archive(boolean bTest)
		throws Exception
	{
		// for each user, check his lastLogin and compare to his
		// town weblog, proj weblog and task weblog
		// Email the result to him

		// check to see when was the last time I do Archive on the System.
		// do Archive on the system only once a week on Sun at 3AM
		if (!bTest && !PrmAlert.isTime(ARCHIVE, ARCHIVE_HOUR, WORK_DAY))
			return 0;


		////////////////////////////////////////////////////////////////
		// Need to work (on Sun after 3 AM)
		l.info("*** PrmThread Archive starts: (force=" + bTest + ")");

		// now check each town, project and task
		PrmThread.totalTaskArc = 0;
		PrmThread.totalBugArc = 0;

		// policy follows:
		// archive only if there are more than 20 (default) weblogs
		// sort by CreatedDate, archive no. min(5,n) to n

		int [] blogs;			// blog ids
		int rc;
		int [] ids;

		// at this point, only consider top blogs, not comments to blogs.  The latter doesn't have
		// TaskID.

		if (isCRAPP || isPRMAPP)
		{
			// for every task
			ids = tkMgr.findId(jwu, "om_acctname='%'");
			for (int i=0; i<ids.length; i++)
			{
				// for every task check the # of weblogs
				blogs = rsMgr.findId(jwu, "TaskID='" + ids[i] + "' && Type='" + result.TYPE_TASK_BLOG + "'");	// task Id
				if (blogs.length >= ARCV_THRESHOLD)
				{
					if ((rc = do_archive(tkMgr, ids[i], blogs)) != -1)
					{
						PrmThread.totalTaskArc++;
						if (rc == 2) i--;			// need to call again
					}
				}
			}

			if (isPRMAPP)
			{
				// for every bug
				ids = bugMgr.findId(jwu, "om_acctname='%'");
				for (int i=0; i<ids.length; i++)
				{
					// for every bug check the # of weblogs
					blogs = rsMgr.findId(jwu, "TaskID='" + ids[i] + "' && Type='" + result.TYPE_BUG_BLOG + "'");	// bug Id
					if (blogs.length >= ARCV_THRESHOLD)
					{
						if ((rc = do_archive(bugMgr, ids[i], blogs)) != -1)
						{
							PrmThread.totalBugArc++;
							if (rc == 2) i--;			// need to call again
						}
					}
				}
			}
		}
		if (isOMFAPP)
		{	// isOMFAPP
		
			// for every circle blog
			ids = tnMgr.findId(jwu, "om_acctname='%'");
			for (int i=0; i<ids.length; i++)
			{
				// for every circle check the # of weblogs
				blogs = rsMgr.findId(jwu, "TaskID='" + ids[i] + "' && Type='" + result.TYPE_FRUM_BLOG + "'");
				if (blogs.length >= ARCV_THRESHOLD)
				{
					if ((rc = do_archive(tnMgr, ids[i], blogs)) != -1)
					{
						PrmThread.totalCirArc++;
						if (rc == 2) i--;			// need to call again
					}
				}
			}
			
			// for every personal blog for OMF
			ids = uMgr.findId(jwu, "om_acctname='%'");
			for (int i=0; i<ids.length; i++)
			{
				// for every user check the # of weblogs
				blogs = rsMgr.findId(jwu, "TaskID='" + ids[i] + "' && Type='" + result.TYPE_ENGR_BLOG + "'");
				if (blogs.length >= ARCV_THRESHOLD)
				{
					if ((rc = do_archive(uMgr, ids[i], blogs)) != -1)
					{
						PrmThread.totalUsrArc++;
						if (rc == 2) i--;			// need to call again
					}
				}
			}
		}

		// PRM: do not archieve personal blog: there is no one page displaying personal blog in chronological
		// manner.  Indeed, we have to figure how to call back the archived blogs from the engr logbook.

		l.info("*** PrmThread " + ARCHIVE + " ends");
		return 1;
	}

	///////////////////////////////////////////////////////
	//
	//	do_archive()
	//	Perform archiving of a weblog
	//
	///////////////////////////////////////////////////////
	//
	public static int do_archive(PstManager objMgr, int objId, int [] blogs)
	{
		l.info("   do_archive() for " + objMgr.getClass().getName() + " [" + objId + "]");
		
		// objMgr can be tnMgr, fmMgr, pjMgr or tkMgr
		// objId can be id of town, proj or task, or user, circle
		project pj = null;
		task tk = null;
		bug bg = null;
		PstAbstractObject obj = null;
		int ptId = 0;
		PstAbstractObject [] blogList = null;
		boolean bCallAgain = false;
		String title = "";							// for OMF Page blog
		String picURL = null;
		String name = "";
		String descMotto = "";						// desc for circle or motto for user

	try
	{
		blogList = rsMgr.get(jwu, blogs);

		int totalBlogs = blogs.length;

		// sort blogs by create date.  Latest postings first.
		Util.sortDate(blogList, "CreatedDate", true);

		// create the archive file
		SimpleDateFormat df1 = new SimpleDateFormat ("MMMMMMMM dd, yyyy (EEEEEEEE)");
		SimpleDateFormat df2 = new SimpleDateFormat ("MMM dd, yyyy");
		SimpleDateFormat df3 = new SimpleDateFormat ("hh:mm a");

		boolean isTask = false;			// in PRM, it can be task or bug blog
		boolean isPage = false;			// either circle or user Page
		boolean isCircle = false;
		boolean isTaskBlog = false;
		boolean isBugBlog = false;
		boolean isActnBlog = false;
		boolean isProjectBlog = false;
		

		if (objMgr instanceof taskManager)
		{
			title = "Task Blog";
			isTask = true;
			tk = (task)tkMgr.get(jwu, objId);
			obj = tk;
			pj = (project)pjMgr.get(jwu, Integer.parseInt((String)tk.getAttribute("ProjectID")[0]));

			int [] ids = ptMgr.findId(jwu, "TaskID='" + objId + "'");	// there is only one planTask for this task
			if (ids.length <= 0) return -1;
			ptId = max(ids);
			planTask pTask = (planTask)ptMgr.get(jwu, ptId);

			String stackName = ">>" + TaskInfo.getTaskStack(jwu, pTask);
			int idx = stackName.lastIndexOf(">>");
			stackName = stackName.substring(0, idx+2) + "<span class='subtitle'>" + stackName.substring(idx+2) + "</span>";
			name = stackName.replaceAll(">>", "</td><tr><tr><td width='20' class='plaintext_grey' valign='top'>>></td><td class='plaintext_grey'>");
			isTaskBlog = true;

			/*name = pj.getObjectName() + "<div class='subtitle'>&nbsp;&nbsp;&nbsp;>> "
				+ (String)pt.getAttribute("Name")[0] + "</div>";*/
		}
		else if (objMgr instanceof bugManager)
		{
			title = "PR Blog";
			bg = (bug)bugMgr.get(jwu, objId);
			obj = bg;
			pj = (project)pjMgr.get(jwu, Integer.parseInt((String)bg.getAttribute("ProjectID")[0]));
			name = (String)bg.getAttribute("Synopsis")[0];
			isBugBlog = true;
		}
		else if (objMgr instanceof townManager)
		{
			// circle page
			obj = objMgr.get(jwu, objId);
			name = (String)obj.getAttribute("Name")[0];
			title = name + "'s Page";
			isPage = true;
			isCircle = true;
			
			// circle icon picture, name and description
			picURL = Util2.getPicURL(obj, "../i/group.jpg");

			Object bTextObj = obj.getAttribute("Description")[0];
			if (bTextObj != null)
				descMotto = new String((byte[])bTextObj, "utf-8");
			else
				descMotto = "No Description";
		}
		else if (objMgr instanceof userManager)
		{
			// user page
			obj = objMgr.get(jwu, objId);
			name = ((user)obj).getFullName();
			title = name + "'s Page";
			isPage = true;
			
			// icon picture and motto
			picURL = Util2.getPicURL(obj);
			descMotto = (String)obj.getAttribute("Motto")[0];
			if (descMotto == null) descMotto = "No Motto";
		}
		else
		{
			l.error("!!! Error in do_archive(): unexpected class.");
			return -1;
		}
		int dirId = 0;

		// blog archives directories are organized by project Ids
		if (isPage)
			dirId = objId;
		else
			dirId = pj.getObjectId();
		
		String subDirStr = PrmThread.getarcvpath() + File.separator + dirId;	// C:/repository/Archive/12345
		File subDirectory = new File(subDirStr);

		//If directory not exist, create it.
		if(!subDirectory.exists())
			subDirectory.mkdirs();

		// archive file name is: "objId_timestamp.jsp"
		Date now = new Date();
		String arvFileName = objId + "_" + now.getTime() + ".jsp";
		String absFileName = subDirStr + File.separator + arvFileName;
		String arvAttr = dirId + "/" + arvFileName;			// save to blog attribute later
		File arcvFile = new File(absFileName);
		arcvFile.createNewFile();
		OutputStreamWriter fos = 
			new OutputStreamWriter(new FileOutputStream(arcvFile), Charset.forName("UTF-8"));

		// start preparing the buffer
		StringBuffer buf = new StringBuffer(8192);
		buf.append(FILE_CONTENT_0);				// java code
		buf.append("<%int taskId=0;%>");
		buf.append("<%String arvfname=\"" + arvFileName + "\";%>");

		buf.append("<%String host=Util.getPropKey(\"pst\", \"PRM_HOST\");%>");
		if (!isPage)
		{
			buf.append("<%String projName=\"" + pj.getDisplayName() + "\";%>");
			buf.append("<%String projIdS=\"" + dirId + "\";%>");
			if (isTask)
			{
				buf.append("<%taskId=" + objId + ";%>");		// old code use planTaskId which might be deleted - change to use taskId
				buf.append("<%PstAbstractObject obj = taskManager.getInstance().get(pstuser, " + objId + ");%>");
			}
			else
			{
				buf.append("<%String bugIdS=\"" + objId + "\";%>");
				buf.append("<%PstAbstractObject obj = bugManager.getInstance().get(pstuser, " + objId + ");%>");
			}
		}
		else if (isCircle)
		{
			// isPage && isCircle
			buf.append("<%PstAbstractObject obj = townManager.getInstance().get(pstuser, " + objId + ");%>");
		}
		else
		{
			// isPage for individual
			buf.append("<%PstAbstractObject obj = userManager.getInstance().get(pstuser, " + objId + ");%>");
		}
		buf.append("<%String myUidS = String.valueOf(pstuser.getObjectId());%>");
		buf.append("<%String shareStr;%>");
		buf.append("<%boolean isPrivate;%>");
		buf.append("<%boolean isOMFAPP = " + isOMFAPP + ";%>"); 
		buf.append("<%boolean isTaskBlog = " + isTaskBlog + ";%>");
		buf.append("<%boolean isBugBlog = " + isBugBlog + ";%>");
		buf.append("<%boolean isActnBlog = " + isActnBlog + ";%>");
		buf.append("<%boolean isProjectBlog = " + isProjectBlog + ";%>");

		buf.append(FILE_CONTENT_1);				// header of the file
		buf.append(title);
		buf.append(FILE_CONTENT_2);

		// menu bar
		if (isPage)
			buf.append("<jsp:include page='../in/home.jsp' flush='true'>");
		else if (isTask) {
			//buf.append("<jsp:include page='../in/iproj.jsp' flush='true'>");
		}
		else
			buf.append("<jsp:include page='../in/itrack.jsp' flush='true'>");
		buf.append(FILE_CONTENT_3);		

		// submenu bar
		if (isPage)
		{
			buf.append(FILE_CONTENT_PAGE_1A);
			buf.append(title);
			buf.append(FILE_CONTENT_PAGE_1B);
			buf.append(FILE_CONTENT_PAGE_2);
			buf.append(FILE_CONTENT_PAGE_3A);		// icon picture and desc/motto
			buf.append(picURL);
			buf.append(FILE_CONTENT_PAGE_3B);
			buf.append(name);
			buf.append(FILE_CONTENT_PAGE_3C);
			buf.append(descMotto);
			buf.append(FILE_CONTENT_PAGE_3D);
			buf.append(FILE_CONTENT_PAGE_4A);		// link back to main blog
			
			buf.append(objId);
			buf.append("'>Back to Main Blog</a></td></tr>");
			
			// ECC: (Done) might want to add archive selection here.  Today, just allow going back to main blog
			// view other archives
			buf.append(insertViewArchive());

			buf.append("</table></td>");
			buf.append("</tr></tr></table>");
			
			buf.append(FILE_CONTENT_PAGE_5);		// partition line before blogs
		}
		else
		{
			if (isTask)
			{
				//buf.append(FILE_CONTENT_TK_1);
				buf.append(FILE_CONTENT_4A);
				buf.append(FILE_CONTENT_TK_2);		// display task name
				buf.append(name);
				buf.append("</td></tr></table>");
				buf.append(FILE_CONTENT_5);
				buf.append("taskId=" + objId);		// old code use planTaskId which might be deleted - change to use taskId
			}
			else
			{
				buf.append(FILE_CONTENT_BG_1);
				buf.append(FILE_CONTENT_4);
				buf.append(FILE_CONTENT_BG_2);		// display bug synopsis
				buf.append(name);
				buf.append(FILE_CONTENT_5);
				buf.append("bugId=" + objId);
			}
			buf.append(FILE_CONTENT_6A);
			buf.append(insertViewArchive());
			buf.append(FILE_CONTENT_6B);
		}

		// ready for the actual listing of blogs
		Date createDate;
		String creatorIdS;
		String uname;
		user aUser = null;

		String bText;
		Object bTextObj;

		// archive starts from the date of min(5, totalBlogs-5) to totalBlogs-1
		int idx = Math.min(ARCV_ACTIVE_LEFT, totalBlogs-ARCV_ACTIVE_LEFT);
		if (totalBlogs-idx > ARCV_FILE_MAX)
		{
			// will create more than one archive files
			idx = totalBlogs - ARCV_FILE_MAX;	// first segment to be archive away from the bottom of bloglist
			bCallAgain = true;
		}
		result blog = (result)blogList[idx];	// blogList listed by latest posting first
		Date latestDate = (Date)blog.getAttribute("CreatedDate")[0];	// the newest blog to be archived
		String end = df2.format(latestDate);
		String begin = null;
		int begIdx = -1;
		int comNum, blogId;
		String shareStr;

		for (int i=0; i<totalBlogs; i++)
		{
			blog = (result)blogList[i];
			createDate = (Date)blog.getAttribute("CreatedDate")[0];
			if ((createDate.compareTo(latestDate) > 0) && !end.equals(df2.format(createDate)))
				continue;	// too new, don't archive
			
			if (i < ARCV_ACTIVE_LEFT)
			{
				// ARCV_BEG is the active blogs left after archiving
				// I am about to archive too much (too few active blog left), don't do it!
				fos.close();
				arcvFile.delete();
				return -1;
			}

			if (begIdx < 0) begIdx = i;		// initialize

			// start archiving a blog
			creatorIdS = (String)blog.getAttribute("Creator")[0];
			try {aUser = (user)uMgr.get(jwu, Integer.parseInt(creatorIdS));
			uname =  aUser.getFullName();}
			catch (PmpException e) {uname="Unknown";}

			// @ECC101608 need to handle private blog
			shareStr = Util2.getAttributeString(blog, "ShareID", ";");
			buf.append("<%isPrivate = false;%>");
			buf.append("<%shareStr = \"" + shareStr + "\";%>");
			if (shareStr.length() > 0)
			{
				buf.append("<%if (shareStr.indexOf(myUidS) == -1) isPrivate = true;%>");	// not for this user to see
			}
			bTextObj = blog.getAttribute("Comment")[0];
			bText = (bTextObj==null)?"":new String((byte[])bTextObj, "utf-8");

			// comments (this will follow the top blog immediately)
			blogId = blog.getObjectId();
			int [] ids = rsMgr.findId(jwu, "ParentID='" + blogId + "'");
			comNum = ids.length;

			// Date
			buf.append("<%if (!isPrivate) {%>");
			buf.append("<tr><td height='60' class='blog_date'><a name='" + blogId + "'></a>");
			buf.append(df1.format(createDate));
			buf.append("</td>");
			buf.append("<%if (shareStr.length()>0) out.println(\"<td align='right' valign='top' class='plaintext_grey'>(Private blog for "
					+ name + " only)</td>\");%>");
			buf.append("</tr>");

			// Range of Dates that get archived
			if (i >= totalBlogs-1)
				begin = df2.format(createDate);

			// Text
			buf.append("<tr><td colspan='2' class='blog_text'>");
			buf.append(bText);
			buf.append("<p></p></td></tr>");

			// Author
			buf.append("<tr><td width='1'><img src='../i/spacer.gif' width='1' height='3'></td></tr><tr><td>");
			buf.append("<table border='0' width='100%' height='1' cellspacing='0' cellpadding='0'><tr><td class='blog_by'>POSTED BY ");
			buf.append(uname.toUpperCase());
			buf.append(" | <font color='#dd8833'>");
			buf.append(df3.format(createDate));
			buf.append("</font></td>");

			// Comment Num
			buf.append("<td align='right' class='blog_small'>");
			if (comNum > 0)
			{
				buf.append("<a id='" + blogId + "-A' href='javascript:toggle_comment(" + blogId + ", " + comNum + ");' class='listlink'>");
				buf.append("Hide Comments</a>");
			}
			else
				buf.append("COMMENT (" + comNum + ")");

			buf.append("</td></tr></table></td></tr>");

			buf.append(FILE_CONTENT_7B);		// blue partition after main blog

			// list comments if any
			if (comNum > 0)
			{
				PstAbstractObject [] comList = rsMgr.get(jwu, ids);
				Util.sortDate(comList, "CreatedDate", true);
				
				// allow expand and hide
				buf.append("<tr><td width='100%'><table width='100%' border='0' cellspacing='0' cellpadding='0'><tr><td>");
				buf.append("<div id='" + blogId + "-X' style='display:block'>");
				buf.append("<table width='100%' border='0' cellspacing='0' cellpadding='0'>");
				for (int j=0; j<comNum; j++)
				{
					result comObj = (result)comList[j];
					if (shareStr.length() > 0)
					{
						buf.append("<%if (shareStr.indexOf(myUidS) == -1) isPrivate = true;%>");	// not for this user to see
					}
					
					// check for private blocking
					shareStr = Util2.getAttributeString(comObj, "ShareID", ";");
					buf.append("<%isPrivate = false;%>");
					buf.append("<%shareStr = \"" + shareStr + "\";%>");
					if (shareStr.length() > 0)
					{
						buf.append("<%if (shareStr.indexOf(myUidS) == -1) isPrivate = true;%>");	// not for this user to see
					}
					buf.append("<%if (!isPrivate) {%>");
					
					createDate = (Date)comObj.getAttribute("CreatedDate")[0];
					creatorIdS = (String)comObj.getAttribute("Creator")[0];
					try {aUser = (user)uMgr.get(jwu, Integer.parseInt(creatorIdS));
					uname =  aUser.getFullName();}
					catch (PmpException e) {uname="Unknown";}

					bTextObj = comObj.getAttribute("Comment")[0];
					bText = (bTextObj==null)?"":new String((byte[])bTextObj, "utf-8");

					// Date
					buf.append("<tr><td height='60' class='plaintext'>");
					buf.append("<a name='" + comObj.getObjectId() + "'></a>");
					buf.append("<b>" + uname.toUpperCase() + "</b> wrote on <b>");
					buf.append(df1.format(createDate) + "</b>");
					buf.append("<%if (shareStr.length()>0) out.println(\"<span class='plaintext_grey'>&nbsp;&nbsp;&nbsp;(Private message for "
							+ name + " only)</span>\");%>");
					buf.append("</td></tr>");

					// Text
					buf.append("<tr><td colspan='2' class='blog_text'>");
					buf.append(bText + "<p></p></td></tr>");
					
					if (j < comNum-1)
						buf.append(FILE_CONTENT_7A);		// gray partition after each comment
					else
						buf.append(FILE_CONTENT_7B);		// blue partition after each comment
					
					buf.append("<%}   // End if !isPrivate for comment%>");

					// clean up this comment blog
					garbageCollect(comObj, arvAttr);
				}	// END for each comment
				
				buf.append("</table></div>");
				buf.append("</td></tr></table></td></tr>");
			}
			
			buf.append("<%}   // End if !isPrivate for main blog%>");

			// cleanup this top blog
			garbageCollect(blog, arvAttr);

		}	// END for listing each main blogs

		buf.append("</table></td>");
		buf.append("<td><img src='../i/spacer.gif' width='1' height='5'></td>");
		buf.append("</tr></table></td>");

		// the project team
		if (bAddProjectTeamSection) {
			if (!isPage)
			{
				buf.append(FILE_CONTENT_8);
				buf.append("<a href='addalert.jsp?townId=null&projId=" + dirId + "&taskId=");
				if (isTask)
					buf.append(objId);
				else
					buf.append("null");
				buf.append("&backPage=/servlet/ShowFile?archiveFile=" + dirId + "/" + arvFileName + "'>");
				buf.append("<img src='../i/eml.gif' border='0'></a><br><br></div>");
		
				PstAbstractObject [] memberList = jwu.getTeamMembers(dirId);
		
				int uid;
				String coordinatorIdS = (String)pj.getAttribute("Owner")[0];
				int coordinatorId = Integer.parseInt(coordinatorIdS);
				for (int j = 0; j < memberList.length; j++)
				{
					aUser = (user)memberList[j];
					uid = aUser.getObjectId();
					uname = aUser.getFullName();
		
					buf.append("<div class='namelist'>");
					buf.append("<a href='../ep/ep1.jsp?uid=" + uid + "' class='namelist'>" + uname + "</a>");
					if (uid==coordinatorId)
						buf.append("&nbsp;&nbsp;(COORDINATOR)");
					buf.append("</div>");
				}
			}	// END if isPage

			buf.append(FILE_CONTENT_9A);
		}
		else
			buf.append(FILE_CONTENT_9B);

		// save buffer to file
		//fos.write(buf.toString().getBytes());
		fos.write(buf.toString());
		fos.flush();
		fos.close();
		
		l.info("     created archive file: " + arcvFile.getAbsolutePath());

		// append Archive attribute to archived obj (Apr 04, 2004 - May 15, 2004:townId/objId_timestamp.jsp)
		String val = begin + " - " + end;
		// ECC: this segment is not necessary if archive is clean
		Object [] ar = obj.getAttribute("Archive");
		for (int i=0; i<ar.length; i++) {
			String s = (String) ar[i];
			if (s!=null && s.startsWith(val)) {
				// duplicate: remove
				obj.removeAttribute("Archive", ar[i]);
				try {
					String fname = s.substring(s.indexOf(':')+1);
					fname = PrmThread.getarcvpath() + File.separator + fname;
					File fObj = new File(fname);
					fObj.delete();
					System.out.println("removed OLD archive file.");
				}
				catch (Exception e) {};
			}
		}
		// END: end temp segment
		
		val = val + ":" + dirId + "/" + arvFileName;
		obj.appendAttribute("Archive", val);
		objMgr.commit(obj);
	}
	catch (Exception e)
	{
		l.error("!!! Error do_archive() for " + title + ": " + objId);
		e.printStackTrace();
		System.out.println("--- End stack trace ---");
		return -1;
	}

	l.info("     done archiving for (" + objId + ")");

	if (bCallAgain)
	{
		l.info("     ... need to archive more.");
		return 2;		// might need to archive more blogs to another file
	}

	return 0;

	}	// end do_archive()
	
	protected static String insertViewArchive()
	{
		StringBuffer buf = new StringBuffer(2048);
		
		buf.append("<tr><td valign='bottom'>");
		buf.append("<form name='ArchiveForm'>");
		buf.append("<img src='../i/bullet_tri.gif' width='20' height='10'>");
		buf.append("<select name='archive' onchange='view_archive(document.ArchiveForm.archive)'>");
		buf.append("<option class='formtext_small' value='' selected>-- view archive --");
		buf.append("<% ");
		buf.append("String [] st;");
		buf.append("String range;");

		buf.append("Object [] archives = obj.getAttribute(\"Archive\");");
		buf.append("Arrays.sort(archives, new Comparator()");
		buf.append("{public int compare(Object o1, Object o2)");
		buf.append("{");
		buf.append("try{");
		buf.append("String [] sa = ((String)o1).split(\"_\");");
		buf.append("long l1 = Long.parseLong(sa[1].substring(0,sa[1].length()-4));");
		buf.append("sa = ((String)o2).split(\"_\");");
		buf.append("long l2 = Long.parseLong(sa[1].substring(0,sa[1].length()-4));");
		buf.append("return (l2>l1)?-1:1;");
		buf.append("}catch(Exception e){");
		buf.append("return 0;}");
		buf.append("}});");
		buf.append("for (int i=archives.length-1; i>=0; i--)");
		buf.append("{");
		buf.append("String arc = (String)archives[i];");
		buf.append("if (arc == null) break;");
		buf.append("st = arc.split(\":\");");
		buf.append("range = st[0];");
		buf.append("out.print(\"<option class='formtext_small' value='\" + st[1] + \"' \");");
		buf.append("if (st[1].endsWith(arvfname)) ");
		buf.append("out.print(\"selected\");");
		buf.append("out.print(\">\" + range + \"</option>\");");
		buf.append("}");
		buf.append("%>");
		buf.append("</select>");
		buf.append("</form>");
		buf.append("</td></tr>");
		
		return buf.toString();
	}

	protected static void garbageCollect(result blogObj, String arvFName)
		throws PmpException
	{
		// clean up active db
		// ECC: do the following
		// 1. remove only the blog text
		// 2. change Type to xxx-Archive (e.g. Task-Archive, Bug-Archive)
		// 3. insert pjId/arvFileName in ArchiveFile (meaning the blog can be found in this file)
		// 4. put 1-liner text (max 200 char) in Name
		// 5. set archive timestamp

		Object bTextObj = blogObj.getAttribute("Comment")[0];
		String bText = "";
		try {bText = (bTextObj==null)?"":new String((byte[])bTextObj, "utf-8");}
		catch (UnsupportedEncodingException e) {l.error("PrmArchive got UnsupportedEncodingException.");}

		// 1. remove blog text **ECC
		//blogObj.setAttribute("Comment", null); 	// @ECC032014b use another archiving tool to remove text

		// 2. change type to archive
		String ty = (String)blogObj.getAttribute("Type")[0];
		if (ty != null) ty += result.TYPE_ARCHIVE;
		blogObj.setAttribute("Type", ty);

		// 3. save archive filename
		blogObj.setAttribute("ArchiveFile", arvFName);	// pjId/filename.jsp

		// 4. 1-liner (strip HTML)
		bText = bText.replaceAll("<\\S[^>]*>", "");		// strip HTML tag
		int len = bText.length();
		if (len > 0)
		{
			if (len > ONE_LINER_LEN) bText = bText.substring(0, ONE_LINER_LEN);
			blogObj.setAttribute("Name", bText);		// plain-text 1-liner
		}

		// 5. Set archive timestamp
		blogObj.setAttribute("ArchiveDate", new Date());

		rsMgr.commit(blogObj);
	}

	private static int max(int [] a) {int max=0; for (int i=0; i<a.length; i++){if (a[i]>max) max=a[i];} return max;}

	/////////////////////////////////////////////////
	// HTML contents of the archive file
	//

	private static String app = Prm.getAppTitle();
	
	private static String FILE_CONTENT_0 =
"<%@ page import = \"java.util.*\" %>" +
"<%@ page import = \"java.io.*\" %>" +
"<%@ page import = \"java.text.SimpleDateFormat\" %>" +
"<%@ page import = \"oct.codegen.*\" %>" +
"<%@ page import = \"oct.pmp.exception.*\" %>" +
"<%@ page import = \"oct.util.general.*\" %>" +
"<%@ page import = \"oct.pst.*\" %>" +
"<%@ page import = \"oct.pep.*\" %>" +
"<%@ page import = \"util.*\" %>" +
"<%@ taglib uri=\"/pmp-taglib\" prefix=\"pmp\" %>" +
"<pmp:useUser id=\"pstuser\" noSessionUrl=\"../out.jsp\" />" +
"<%" +
"	if (pstuser instanceof PstGuest) {" +
"	response.sendRedirect(\"../out.jsp?e=Access declined\");" +
"	return;}" +
"	int iRole = ((Integer)session.getAttribute(\"role\")).intValue();" +
"%>\n\n";

	private static String FILE_CONTENT_1 =
"<%@ page contentType='text/html; charset=utf-8'%>" +
"<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'>" +
"<html lang='en'>" +
"<head>" +
"<meta http-equiv='content-type' content='text/html; charset=utf-8'>" +
"<link href='../oct-basic.css' rel='stylesheet' type='text/css' media='screen'>" +
"<link href='../oct-print.css' rel='stylesheet' type='text/css' media='print'>" +
"<jsp:include page='../init.jsp' flush='true'/>" +
"<title>" + app + " Blog</title>" +
"<script type='text/javascript'>" +
"<!--\n" +
"function toggle_comment(id, comNum)" +
"{" +
"var e = document.getElementById(id + '-X');\n" +
"var ee = document.getElementById(id + '-A');\n" +
"if (e.style.display == 'block')\n" +
"{" +
"	e.style.display = 'none';\n" +
"	ee.innerHTML = 'Show Comments (' + comNum + ')';\n" +
"} " +
"else " +
"{\n" +
"	e.style.display = 'block';\n" +
"	ee.innerHTML = 'Hide Comments';\n" +
"}\n" +
"return;" +
"}	// END toggle_comment()\n" +
"function view_archive(e)" +
"{" +
"	var fname = e.options[e.selectedIndex].value;" +
"	if (fname != '')" +
"		location= '<%=host%>' + '/servlet/ShowFile?archiveFile=' + fname;" +
"	return;" +
"}	// END: view_archive()\n" +
"//-->\n" +
"</script>" +
"</head>" +
"<body bgcolor='#FFFFFF' leftmargin='0' topmargin='0' marginwidth='0' marginheight='0'>" +
"<table width='100%' border='0' cellspacing='0' cellpadding='0'>" +
"<tr><td valign='top'>" +
"<table width='100%' border='0' cellspacing='0' cellpadding='0'>" +
"<tr><td width='100%' valign='top'>" +
"<jsp:include page='../head.jsp' flush='true'/>" +
"</td></tr>" +
"<tr><td></table>" +
"<table width='90%' border='0' cellspacing='0' cellpadding='0'>" +
"<tr><td>" +
"<table><tr><td width='20' height='20'><a name='top'>&nbsp;</a></td>" +
"<td valign='top'><b class='head'>";

	private static String FILE_CONTENT_2 =
" Archive</b></td><td></td></tr>" +
"<tr>" +
"<td width='20'>&nbsp;</td>" +
"<td width='434'>&nbsp;</td>" +
"<td width='320'>&nbsp;</td>" +
"</tr>" +
"</table></td></tr>" +
"<tr><td width='100%'>" +
"<!-- Navigation Menu -->";

	private static String FILE_CONTENT_3 =
"<%if (isOMFAPP){%>" +
"<jsp:include page='../in/imtg.jsp' flush='true'>" +
"<jsp:param name='role' value='<%=iRole%>' />" +
"</jsp:include>" +
"<%	} else {" +
"int iBlogType = 0;\n" + 
"if (isProjectBlog) iBlogType = 0;\n" + 
"else if (isTaskBlog) iBlogType = 1;\n" + 
"else if (isBugBlog) iBlogType = 2;\n" + 
"else if (isActnBlog) iBlogType = 3;\n" + 
"else iBlogType = 4;\n%>" + 
"<jsp:include page='<%=Prm.getTabFile()%>' flush='true'>\n" + 
"<jsp:param name='cat' value='Project' />\n" + 
"<jsp:param name='subCat' value='ProjectBlog' />\n" + 
"<jsp:param name='role' value='<%=iRole%>' />\n" + 
"<jsp:param name='blogType' value='<%=iBlogType%>' />\n" + 
"<jsp:param name='projId' value='<%=projIdS%>' />\n" + 
"<jsp:param name='taskId' value='<%=taskId%>' />\n" + 
"</jsp:include>\n" + 
"<%	}%>\n" +
"<!-- End of Navigation Menu -->" +
"</td></tr></table></td></tr>";
/*
"<tr><td width='100%' valign='top'>" +
"<!-- Navigation SUB-Menu -->" +
"<table border='0' width='620' height='1' cellspacing='0' cellpadding='0'>" +
"<tr><td width='20' height='1' bgcolor='#FFFFFF'><img src='../i/spacer.gif' width='20' height='1' border='0'></td>" +
"<td bgcolor='#CCCCCC' width='100%' height='1'><img src='../images/spacer.gif' width='1' height='1' border='0'></td>" +
"</tr></table>" +
"<table border='0' width='620' height='14' cellspacing='0' cellpadding='0'>" +
"<tr><td width='20' height='14' bgcolor='#FFFFFF'><img src='../i/spacer.gif' height='1' border='0'></td>" +
"<td valign='top' class='BgSubnav'>" +
"<table border='0' cellspacing='0' cellpadding='0'>" +
"<tr class='BgSubnav'>";
*/
	
	private static String FILE_CONTENT_BG_1 =
"<!-- Problem Report Summary -->" +
"<td width='7'><img src='../i/spacer.gif' width='7' height='1' border='0'></td>" +
"<td width='7' height='14'><img src='../i/sub_line.gif' width='7' height='14' border='0'></td>" +
"<td width='15'><img src='../i/spacer.gif' width='20' height='1' border='0'></td>" +
"<td><a href='../bug/bug_search.jsp' class='subnav'>Problem Report Summary</a></td>" +
"<td width='15'><img src='../i/spacer.gif' width='20' height='1' border='0'></td>" +
"<!-- New Problem Report -->" +
"<td width='7' height='14'><img src='../i/sub_line.gif' width='7' height='14' border='0'></td>" +
"<td width='15'><img src='../i/spacer.gif' width='20' height='1' border='0'></td>" +
"<td><a href='../bug/bug_update.jsp' class='subnav'>New Problem Report</a></td>" +
"<td width='15'><img src='../i/spacer.gif' width='20' height='1' border='0'></td>" +
"<!-- View PR -->" +
"<td width='7' height='14'><img src='../i/sub_line.gif' width='7' height='14' border='0'></td>" +
"<td width='15'><img src='../i/spacer.gif' width='20' height='1' border='0'></td>" +
"<td><a href='../bug/bug_update.jsp?bugId=<%=bugIdS%>' class='subnav'>View PR</a></td>" +
"<td width='15'><img src='../i/spacer.gif' width='20' height='1' border='0'></td>" +
"<!-- PR Blog -->" +
"<td width='7' height='14'><img src='../i/sub_line.gif' width='7' height='14' border='0'></td>" +
"<td width='15'><img src='../i/spacer.gif' width='20' height='1' border='0'></td>" +
"<td width='15' height='14'><img src='../i/nav_arrow.gif' width='20' height='14' border='0'></td>" +
"<td><a href='#' class='subnav' onclick='return false'><u>PR Blog</u></a></td>" +
"<td width='15'><img src='../i/spacer.gif' width='20' height='1' border='0'></td>";

	/*
	private static String FILE_CONTENT_TK_1 =
"<!-- Current Plan -->" +
"<td width='7'><img src='../i/spacer.gif' width='7' height='1' border='0'></td>" +
"<td width='7' height='14'><img src='../i/sub_line.gif' width='7' height='14' border='0'></td>" +
"<td width='15'><img src='../i/spacer.gif' width='20' height='1' border='0'></td>" +
"<td><a href='../project/proj_plan.jsp?projId=<%=projIdS%>' class='subnav'>Current Plan</a></td>" +
"<td width='15'><img src='../i/spacer.gif' width='20' height='1' border='0'></td>" +
"<td width='7' height='14'><img src='../i/sub_line.gif' width='7' height='14' border='0'></td>" +
"<!-- Project Profile -->" +
"<td width='15'><img src='../i/spacer.gif' width='20' height='1' border='0'></td>" +
"<td><a href='../project/proj_profile.jsp?projId=<%=projIdS%>' class='subnav'>Project Profile</a></td>" +
"<td width='15'><img src='../i/spacer.gif' width='20' height='1' border='0'></td>" +
"<td width='7' height='14'><img src='../i/sub_line.gif' width='7' height='14' border='0'></td>" +
"<!-- Task Management -->" +
"<td width='15'><img src='../i/spacer.gif' width='20' height='1' border='0'></td>" +
"<td><a href='../project/task_update.jsp?projId=<%=projIdS%>&taskId=<%=taskId%>' class='subnav'>Task Management</a></td>" +
"<td width='15'><img src='../i/spacer.gif' width='20' height='1' border='0'></td>" +
"<td width='7' height='14'><img src='../i/sub_line.gif' width='7' height='14' border='0'></td>" +
"<!-- Task Blog -->" +
"<td width='15'><img src='../i/spacer.gif' width='20' height='1' border='0'></td>" +
"<td width='15' height='14'><img src='../i/nav_arrow.gif' width='20' height='14' border='0'></td>" +
"<td><a href='#' class='subnav' onclick='return false;'><u>Task Blog</u></a></td>" +
"<td width='15'><img src='../i/spacer.gif' width='20' height='1' border='0'></td>";
*/

	private static String FILE_CONTENT_PAGE_1A = 
"<!-- Home -->" +
"<td width='40'><img src='../i/spacer.gif' width='15' height='1' border='0'></td>" +
"<td width='7' height='14'><img src='../i/sub_line.gif' width='7' height='14' border='0'></td>" +
"<td width='15'><img src='../i/spacer.gif' width='15' height='1' border='0'></td>" +
"<td><a href='ep_home.jsp' class='subnav'>Home</a></td>" +
"<td width='15'><img src='../i/spacer.gif' width='15' height='1' border='0'></td>" +
"<!-- Search -->" +
"<td width='7' height='14'><img src='../i/sub_line.gif' width='7' height='14' border='0'></td>" +
"<td width='15'><img src='../i/spacer.gif' width='15' height='1' border='0'></td>" +
"<td><a href='search.jsp' class='subnav'>Search</a></td>" +
"<td width='15'><img src='../i/spacer.gif' width='15' height='1' border='0'></td>" +
"<!-- current display: My Page / Circle Page -->" +
"<td width='7' height='14'><img src='../i/sub_line.gif' width='7' height='14' border='0'></td>" +
"<td width='7'><img src='../i/spacer.gif' width='7' height='1' border='0'></td>" +
"<td width='15' height='14'><img src='../i/nav_arrow.gif' width='20' height='14' border='0'></td>" +
"<td><a href='#' onclick='return false;' class='subnav'><u>";
	
	private static String FILE_CONTENT_PAGE_1B = 
"</u></a></td>" +
"<td width='15'><img src='../i/spacer.gif' width='15' height='1' border='0'></td>" +
"<td width='7' height='14'><img src='../i/sub_line.gif' width='7' height='14' border='0'></td>";

	
	private static String FILE_CONTENT_4 =
"</tr></table></td></tr></table>" +
"<table border='0' width='100%' height='1' cellspacing='0' cellpadding='0'>" +
"<tr>" +
"<td width='20' height='1' bgcolor='#FFFFFF'><img src='../i/spacer.gif' width='20' height='1' border='0'></td>" +
"<td bgcolor='#CCCCCC' width='100%' height='1'><img src='../images/spacer.gif' width='1' height='1' border='0'></td>" +
"</tr></table>" +
"<!-- End of Navigation SUB-Menu -->" +
"</td></tr></table></td></tr>";
	
	private static String FILE_CONTENT_4A = 
"<!-- BEGIN INTERNAL CELL -->" +
"<tr><td valign='top'>" +
"<table><tr>" +
"<td><img src='../i/spacer.gif' width='15' height='1' />" +
"<td width='78%' valign='top'>" +
"<table border='0' width='100%'>" +
"<tr><td colspan='2'><img src='../i/spacer.gif' height='5' width='1' alt=' ' /></td></tr>" +
"<tr><td colspan='2' valign='top' class='title'>&nbsp;&nbsp;<%=projName%></td></tr>" +
"<tr>";

	private static String FILE_CONTENT_PAGE_2 =
"</tr></table></td></tr></table>" +
"<table border='0' width='780' height='1' cellspacing='0' cellpadding='0'>" +
"<tr><td width='20' height='1' bgcolor='#FFFFFF'><img src='../i/spacer.gif' width='20' height='1' border='0'></td>" +
"<td bgcolor='#CCCCCC' width='100%' height='1'><img src='../i/spacer.gif' width='1' height='1' border='0'></td>" +
"</tr></table>" +
"<!-- End of Navigation SUB-Menu -->" +
"</td></tr><tr><td>&nbsp;</td></tr>" +
"<tr><td><table border='0' cellspacing='0' cellpadding='0'>" +
"<tr><td><img src='../i/spacer.gif' width='20' /></td>";
	
	private static String FILE_CONTENT_PAGE_3A =
"<td width='85' height='80'>" +
"<img src=";
	
	private static String FILE_CONTENT_PAGE_3B =
" height='80' style='margin:10px; padding:5px; border:2px solid #6699cc;'/>" +
"<td width='370' valign='bottom'>" +
"<table><tr><td class='plaintext_bold'>";
	
	private static String FILE_CONTENT_PAGE_3C =
"</td></tr><tr><td class='plaintext_grey'>";
	
	private static String FILE_CONTENT_PAGE_3D =
"</td></tr><tr><td>&nbsp;</td></tr>" +
"</table></td>";

	private static String FILE_CONTENT_PAGE_4A =
"<td valign='top'><table border='0' cellspacing='0' cellpadding='0'>" +
"<tr><td valign='top'>" +
"<img src='../i/bullet_tri.gif' width='20' height='10'>" +
"<a class='listlinkbold' href='../ep/my_page.jsp?uid=";

	private static String FILE_CONTENT_PAGE_5 =
"<table width='770' border='0' cellspacing='0' cellpadding='0'>" +
"<tr><td width='25'>&nbsp;</td>" +
"<td><table border='0' cellpadding='0' cellspacing='0'>" +
"<tr><td><img src='../i/spacer.gif' height='3'></td></tr>" +
"<tr><td bgcolor='#bb5555' height='1'><img src='../i/spacer.gif' width='750' height='1' border='0'></td>" +
"</tr></table>" +
"<table border='0' cellspacing='0' cellpadding='0'>";

	private static String FILE_CONTENT_TK_2 =
"<td width='20'><img src='../i/spacer.gif' width='20' height='1' /></td>" +
"<td><table border='0' cellspacing='0' cellpadding='0'><tr><td class='plaintext_grey'>";

	private static String FILE_CONTENT_BG_2 =
"<td class='subtitle' valign='top' width='20'>&nbsp;&nbsp;&nbsp;>></td>" +
"<td class='subtitle'>";

	private static String FILE_CONTENT_5 =
"</td></tr>" +
"</table></td>" +
"<td><table cellspacing='0' cellpadding='0'>" +
"<tr><td valign='middle'>" +
"		<img src='../i/bullet_tri.gif' width='20' height='10'>" +
"		<a class='listlinkbold' href='<%=host%>/blog/blog_task.jsp?projId=<%=projIdS%>&";

	private static String FILE_CONTENT_6A =
"'>Back to Main Blog</a>" +
"	</td></tr>";
	
	private static String FILE_CONTENT_6B =
"</table></td>" +
"</tr></table>" +
"<table width='100%' border='0' cellspacing='0' cellpadding='0' class='headlinerule'>" +
"	    <tr>" +
"		<td><img src='../i/spacer.gif' height='1' width='1' alt=' ' /></td>" +
"	    </tr>" +
"	</table>" +
"<!-- CONTENT LEFT -->" +
"<table width='100%' border='0' cellspacing='0' cellpadding='0'>" +
"<tr>" +
"<td width='550' valign='top'>" +
"<!-- DISPLAY WEBLOG min height set to 110 -->" +
"<table height='110' width='100%'>" +
"<tr><td width='15'><img src=../i/spacer.gif' width='15' height='1' /></td>" +
"<td valign='top'>" +
"<table width='100%'>";

	private static String FILE_CONTENT_7A =
"<tr><td>" +
"<table border='0' width='80%' height='1' cellspacing='0' cellpadding='0'>" +
"<tr><td bgcolor='#bbbbbb' width='80%' height='1'><img src='../i/spacer.gif' width='1' height='1' border='0'></td>" +
"</tr></table></td></tr>";

	private static String FILE_CONTENT_7B =
"<tr><td>" +
"<table border='0' width='100%' height='1' cellspacing='0' cellpadding='0'>" +
"<tr><td bgcolor='#6699cc' width='100%' height='1'><img src='../i/spacer.gif' width='1' height='1' border='0'></td>" +
"</tr></table></td></tr>";

	private static String FILE_CONTENT_8 =
"<td class='headlinerule'>" +
"	<table width='100%' border='0' cellspacing='0' cellpadding='0' class='headlinerule'>" +
"	    <tr>" +
"		<td><img src='/i/spacer.gif' height='100' width='1' alt=' ' /></td>" +
"	    </tr>" +
"	</table>" +
"</td>" +
"<td valign='top'>" +
"	<table><tr>" +
"	<td width='3'>&nbsp;</td>" +
"	<td width='200'>" +
"	<div class='namelist_hdr'>The Project Team&nbsp;";

	private static String FILE_CONTENT_9A =
"	</td>" +
"	</tr></table>" +
"</td></tr>" +
"</table></td></tr>" +
"<tr><td>&nbsp;</td><tr>" +
"<jsp:include page='/foot.jsp' flush='true'/>" +
"</table>" +
"</body>" +
"</html>";

	private static String FILE_CONTENT_9B =
"</tr>" +
"</table></td></tr>" +
"<tr><td>&nbsp;</td><tr>" +
"<jsp:include page='/foot.jsp' flush='true'/>" +
"</table>" +
"</body>" +
"</html>";

}
