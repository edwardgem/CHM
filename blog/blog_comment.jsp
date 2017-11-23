<%@ page contentType="text/html; charset=utf-8"%>
<%
////////////////////////////////////////////////////
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	blog_comment.jsp
//	Author:	ECC
//	Date:	04/04/05
//	Description:
//		Display and add blog/memo comments.
//	Modification:
//		@042805ECC	Support adding comments to bug blog.
//		@ECC041006	Add blog support to action/decision/issue.
//		@AGQ072706	Added hidden variable to determine if it is a comment type
//		@ECC101608	Private blog to personal.
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.*" %>
<%@ page import = "util.*" %>

<%
	// http://cpm.egiomm.com/blog/blog_comment.jsp?blogId=69339&projId=68621&id=69177
	//			&type=Task&blogNum=69363
	String blogIdS = request.getParameter("blogId");
	String projIdS = request.getParameter("projId");
	String idS = request.getParameter("id");		// bugId, planTaskId, action Id, quest Id, meeting Id or userId (viewing other user's page)
	String type = request.getParameter("type");			// Bug, Task, Action, Forum, Meeting, Note
	String blogNum = request.getParameter("blogNum");
	String noSession = "../out.jsp?go=blog/blog_comment.jsp?blogId="+blogIdS
			+ ":projId=" + projIdS + ":id=" + idS
			+ ":type=" + type + ":blogNum=" + blogNum;
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />
<%
	////////////////////////////////////////////////////////
	boolean isGuest = false;
	PstUserAbstractObject me = pstuser;
	if (me instanceof PstGuest)
	{
		isGuest = true;
	}

	if (projIdS!=null && projIdS.equals("null"))
		projIdS = null;
	String aIdS = request.getParameter("aid");			// action item id, may not have any
	if (aIdS!=null && aIdS.equals("null"))
		aIdS = null;

	int idx;
	if (idS!=null && (idx=idS.indexOf("#"))!=-1)
		idS = idS.substring(0, idx);

	boolean isOMFAPP = Prm.isOMF();
	String appS = Prm.getAppTitle();

	// task blog or bug blog
	planTask pTask = null;
	String taskIdS = null;
	String pTaskName = null;
	String synopsis = null;
	String objIdS = null;		// task id, bug id, meeting id
	String backPage = null;
	String midS = null;
	PstAbstractObject obj;
	String circleName = null;
	String cancelLnk = "javascript:history.back(-1);";
	String ownerName = null;			// name of the owner of MyPage

	boolean isBugBlog = false, isTaskBlog = false, isActnBlog = false, isFrumBlog = false,
			isMtgBlog = false, isPersonalBlog=false, isQuestBlog=false;

	if (type != null)
	{
		if (type.equalsIgnoreCase(result.TYPE_BUG_BLOG))
		{
			isBugBlog = true;
			objIdS = idS;
			obj = bugManager.getInstance().get(me, Integer.parseInt(idS));
			synopsis = (String)obj.getAttribute("Synopsis")[0];
			midS = (String)obj.getAttribute("MeetingID")[0];
			backPage = "../blog/blog_comment.jsp?blogId=" +blogIdS + ":id=" +idS
				+ ":type=" + result.TYPE_BUG_BLOG + ":projId=" +projIdS+ ":blogNum=" + blogNum;
			cancelLnk = "../blog/blog_task.jsp?projId=" + projIdS
				+ "&bugId=" + idS
				+ "&type=" + result.TYPE_BUG_BLOG;
		}
		else if (type.equalsIgnoreCase(result.TYPE_ACTN_BLOG))
		{
			// action/decision/issue comments
			isActnBlog = true;
			objIdS = idS;
			obj = actionManager.getInstance().get(me, Integer.parseInt(idS));
			synopsis = (String)obj.getAttribute("Subject")[0];
			midS = (String)obj.getAttribute("MeetingID")[0];
			backPage = "../blog/blog_comment.jsp?blogId=" +blogIdS + ":id=" +idS
				+ ":type=" + result.TYPE_ACTN_BLOG + ":projId=" +projIdS+ ":blogNum=" + blogNum;
		}
		else if (type.equalsIgnoreCase(result.TYPE_TASK_BLOG))
		{
			isTaskBlog = true;
			pTask = (planTask)planTaskManager.getInstance().get(me, Integer.parseInt(idS));
			taskIdS = (String)pTask.getAttribute("TaskID")[0];
			pTaskName = (String)pTask.getAttribute("Name")[0];
			objIdS = taskIdS;		// use taskId, not pTaskId
			backPage = "../blog/blog_comment.jsp?blogId=" +blogIdS + ":type=" + result.TYPE_TASK_BLOG
				+ ":projId=" +projIdS+ ":id=" +idS+ ":blogNum=" + blogNum;
			//backPage = "../blog/blog_task.jsp?projId=" + projIdS + "&planTaskId=" + idS;
			cancelLnk = "../blog/blog_task.jsp?projId=" + projIdS + "&planTaskId=" + idS;
		}
		else
		{
			backPage = "../blog/blog_comment.jsp?blogId=" + blogIdS + ":type=" + type + ":view=true";
			if (type.equalsIgnoreCase(result.TYPE_FRUM_BLOG))
			{
				isFrumBlog = true;
				if (idS != null)
				{
					objIdS = idS;		// town (circle) id
					obj = townManager.getInstance().get(me, Integer.parseInt(idS));
					circleName = (String)obj.getAttribute("Name")[0];
					backPage += ":id=" + idS;
					cancelLnk = "../ep/my_page.jsp?uid=" + idS;	// circle page
				}
				else
					cancelLnk = "../info/help.jsp?home=../ep/ep_home.jsp";
			}
			else if (type.equalsIgnoreCase(result.TYPE_MTG_BLOG))
			{
				isMtgBlog = true;
				objIdS = idS;		// meeting id
				backPage += ":id=" + idS;
				cancelLnk = "../meeting/mtg_view.jsp?mid=" + idS + "&refresh=1#blog";
			}
			else if (type.equals(result.TYPE_QUEST_BLOG))
			{
				isQuestBlog = true;
				backPage += ":id=" + idS;
				objIdS = idS;		// quest id
				cancelLnk = "../question/q_respond.jsp?qid=" + idS;
			}
			else
			{
				// personal blog
				isPersonalBlog = true;
				objIdS = idS;		// user id
				backPage += ":id=" + idS;
				cancelLnk = "../ep/my_page.jsp?uid=" + idS;

				// @ECC101608 personal/private blog
				try {ownerName = ((user)userManager.getInstance().get(pstuser, Integer.parseInt(idS))).getFullName();}
				catch (Exception e) {}
			}
			resultManager rMgr = resultManager.getInstance();
			obj = rMgr.get(me, blogIdS);
			synopsis = (String)obj.getAttribute("Name")[0];

			// check view blog
			if (request.getParameter("view") == null)
				Util.incAttrNum(rMgr, obj, "ViewBlogNum");
		}
		backPage += "#reply";		// jump back to the comment portion of the page in blog_comment.jsp
	}	// endif type!=null
	
	boolean isAdmin = false;
	boolean isDirector = false;
	int iRole = 0;
	if (!isGuest)
	{
		iRole = ((Integer)session.getAttribute("role")).intValue();
		if (iRole > 0)
		{
			if ((iRole & user.iROLE_ADMIN) > 0)
				isAdmin = true;
			if ((iRole & user.iROLE_DIRECTOR) > 0)
				isDirector = true;
		}
	}
	String myUidS = String.valueOf(me.getObjectId());

	// note that for issue blog, there might not be a project associated
	userManager uMgr = userManager.getInstance();
	String s;
	int tid = 0;
	int projCoordinatorId = 0;
	Object [] teamIdList = new Object[0];							// init
	PstAbstractObject [] memberList = new PstAbstractObject[0]; 	// init
	project proj = null;
	String projName = "";
	String pjType = "";

	if (projIdS != null)
	{
		proj = (project)projectManager.getInstance().get(me, Integer.parseInt(projIdS));
		projName = proj.getDisplayName();
		s = (String)proj.getAttribute("Owner")[0];
		projCoordinatorId = Integer.parseInt(s);

		try {tid = Integer.parseInt((String)proj.getAttribute("TownID")[0]);}
		catch (Exception e) {}
		pjType = (String)proj.getAttribute("Type")[0];

		// team members
		teamIdList = proj.getAttribute("TeamMembers");	// need this for comparison later
		memberList = ((user)me).getTeamMembers(proj);
	}


	// only allow posting and reply if it is not Read-only
	boolean bReadOnly = false;
	boolean bFound = false;
	Integer idObj = new Integer(me.getObjectId());
	for (int i=0; i<teamIdList.length; i++)
	{
		if (idObj.equals((Integer)teamIdList[i]))
		{
			bFound = true;	// I am a team member
			break;
		}
	}
	if (!bFound && !isAdmin && !isDirector)
	{
		if (pjType.equals("Private"))
		{
			response.sendRedirect("../out.jsp?e=Access declined");
			return;
		}
		else if (pjType.equals("Public Read-only"))
			bReadOnly = true;
	}

	SimpleDateFormat df1 = new SimpleDateFormat ("MMMMMMMM dd, yyyy (EEEEEEEE)");
	SimpleDateFormat df2 = new SimpleDateFormat ("hh:mm a");
	userinfo.setTimeZone(pstuser, df1);
	userinfo.setTimeZone(pstuser, df2);

	// get the weblog (result) objects associated to this project (TaskID is used to
	// store ProjID or TownID or TaskID.  It all depends on the Type attribute.
	resultManager rMgr = resultManager.getInstance();
	int [] resultIds = rMgr.findId(me, "ParentID='" + blogIdS + "'");
	PstAbstractObject [] blogList = rMgr.get(me, resultIds);

	// sort the result by create date.  Display latest postings first.
	//Util.sortDate(blogList, "CreatedDate", true);
	Util.sortById(blogList);	// display older comments first

%>


<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<jsp:include page="../init.jsp" flush="true"/>

<title>
	<%=appS%> Blog Comment
</title>

</head>

<style type="text/css">
.head_pink {  font-family:Verdana, Arial, Helvetica, sans-serif; color:#cc5577; font-size:15px; font-weight:bold; text-decoration:none}
</style>

<body bgcolor="#FFFFFF" style="margin:0px;">
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">
		<!-- Main Tables -->
		<table width="90%" border="0" cellspacing="0" cellpadding="0">
		  	<tr>
		    	<td width="100%" valign="top">
					<!-- Top -->
					<jsp:include page="../head.jsp" flush="true"/>
					<!-- End of Top -->
				</td>
			</tr>
			<tr>
	          <td>
	            <table width="100%" border="0" cellspacing="0" cellpadding="0">
	              <tr>
					<td width="15" height="30"><a name="top">&nbsp;</a></td>
					<td width="540" height="30" align="left" valign="bottom" class="head">
						<b>Blog Comments</b>
					</td>
	              </tr>
	            </table>
	          </td>
	        </tr>
			<tr>
          		<td width="100%">
<%
		int iBlogType = 0;
		if (isTaskBlog) iBlogType = 1;
		else if (isBugBlog) iBlogType = 2;
		else if (isActnBlog) iBlogType = 3;
		else iBlogType = 4;
%>
					<!-- Navigation Menu -->
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Project" />
				<jsp:param name="subCat" value="ProjectBlog" />
				<jsp:param name="role" value="<%=iRole%>" />
				<jsp:param name="blogType" value="<%=iBlogType%>" />
				<jsp:param name="projId" value="<%=projIdS%>" />
				<jsp:param name="taskId" value="<%=taskIdS%>" />
			</jsp:include>
					<!-- End of Navigation Menu -->
				</td>
	        </tr>

		</table>
</td>
</tr>

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">
	<table width='100%'>
		<tr>
			<td>
			<table width='100%'>
				<tr><td valign="top" class="title">
					&nbsp;&nbsp;&nbsp;<%=projName%>
<%	if (isTaskBlog) {%>
		  		<div class="subtitle">&nbsp;&nbsp;&nbsp;>> <%=pTaskName%></div>
<%	}
	else if (synopsis != null)
	{%>
		  		<div class="subtitle">&nbsp;&nbsp;&nbsp;>> <%=synopsis%></div>
<%	}%>
				</td></tr>
			</table>
			</td>
			<td>
			<table width='100%' cellspacing="0" cellpadding="0">
				<tr>
				<td>&nbsp;</td>
				<td width='420' valign="middle"><br>

				<img src="../i/bullet_tri.gif" width="20" height="10" />
<%	if (isTaskBlog) {%>
				<a class="listlinkbold" href="blog_task.jsp?projId=<%=projIdS%>&planTaskId=<%=idS%>#<%=blogNum%>">Back to Blog</a>
				<br>
				<img src="../i/bullet_tri.gif" width="20" height="10" />
				<a class="listlinkbold" href="../project/proj_plan.jsp?projId=<%=projIdS%>">Back to Project</a>
<%	}
	else if (isBugBlog)
	{%>
				<a class="listlinkbold" href="blog_task.jsp?projId=<%=projIdS%>&bugId=<%=idS%>#<%=blogNum%>">Back to Main Blog</a>
<%	}
	else if (isActnBlog)
	{%>
				<a class="listlinkbold" href="blog_task.jsp?projId=<%=projIdS%>&aid=<%=idS%>#<%=blogNum%>">Back to Main Blog</a>
<%	}
	else if (isFrumBlog)
	{
				if (idS == null)
				{
					out.print("<a class='listlinkbold' href='../info/help.jsp?");
					if (!isGuest)
						out.print("home=../ep/ep_home.jsp&blogId=" + blogIdS + "'>Back to Blog Listing</a>");
				}
				else
					out.print("<a class='listlinkbold' href='../ep/my_page.jsp?uid=" + idS + "'>Back to " + circleName + " Page");
	}
	else if (isMtgBlog)
	{%>
				<a class='listlinkbold' href='../meeting/mtg_view.jsp?mid=<%=idS%>&refresh=1#blog'>Back to Meeting</a><br>
				<img src="../i/bullet_tri.gif" width="20" height="10" />
				<a class="listlinkbold" href="../blog/addblog.jsp?type=<%out.print(result.TYPE_MTG_BLOG + "&id=" + idS);%>">New Post</a>
<%	}
	else if (isQuestBlog)
	{%>
				<a class='listlinkbold' href='../question/q_respond.jsp?qid=<%=idS%>'>Back to Event/Quest</a><br>
				<img src="../i/bullet_tri.gif" width="20" height="10" />
				<a class="listlinkbold" href="../blog/addblog.jsp?type=<%out.print(result.TYPE_QUEST_BLOG + "&id=" + idS);%>">New Post</a>
<%	}
	else if (isPersonalBlog)
	{
				if (idS.equals(myUidS))
					s = "My";
				else
					try {s = ((user)uMgr.get(me, Integer.parseInt(idS))).getFullName() + "'s";}
					catch (PmpException e) {s = "User's";}		// shouldn't get exception but just in case
%>
				<a class='listlinkbold' href='../ep/my_page.jsp?uid=<%=idS%>'>Back to <%=s%> Page</a><br>
				<img src="../i/bullet_tri.gif" width="20" height="10" />
				<a class="listlinkbold" href="../blog/addblog.jsp?type=<%out.print(result.TYPE_ENGR_BLOG + "&id=" + idS);%>">New Post</a>
<%	}%>
				</td></tr>
			</table>
			</td>
		</tr>
	</table>

	<table width="90%" border="0" cellspacing="0" cellpadding="0">
	    <tr>
	    <td width='20'></td>
		<td class="headlinerule"><img src="../i/spacer.gif" height="1" width="1" /></td>
	    </tr>
	</table>
</td>
</tr>

<tr>
<td>
<table width='90%' border='0' cellspacing='0' cellpadding='0'>
<tr>

<!-- CONTENT LEFT -->

<% if (isOMFAPP) {%>
	<td valign="top">
<% } else {%>
	<td width="85%" valign="top">
<% }%>



<!-- DISPLAY WEBLOG min height set to 110 -->
<table width="100%">

<tr>
	<td width="20">&nbsp;</td>

	<td valign="top">
	<table width="100%">
<%
	Date createDate;
	String creatorIdS;
	String uname;
	user aUser;

	String bText;
	Object bTextObj;
	int comNum = blogList.length;

	////////////////////////////////////////
	// show the parent blog
	result blog = (result)rMgr.get(me, blogIdS);
	createDate = (Date)blog.getAttribute("CreatedDate")[0];
	creatorIdS = (String)blog.getAttribute("Creator")[0];
	aUser = (user)uMgr.get(me, Integer.parseInt(creatorIdS));
	uname =  aUser.getFullName();

	bTextObj = blog.getAttribute("Comment")[0];
	bText = (bTextObj==null)?"":new String((byte[])bTextObj, "utf-8");
	bText = bText.replaceAll("&nbsp;", " ");

%>
<!-- DATE -->
	<tr>
		<td height="60" class="blog_date"><%=df1.format(createDate)%></td>
	</tr>

<!-- TEXT -->
	<tr>
		<td class="blog_text" style='line-height:20px;'>
		<%=bText%> <p></p>
		</td>
	</tr>

<!-- AUTHOR -->
	<tr><td width="1"><img src="../i/spacer.gif" width="1" height="3" /></td></tr>

	<tr><td>
	<table border="0" width="100%" height="1" cellspacing="0" cellpadding="0">
	<tr>
	<td class="blog_by">POSTED BY <%=uname.toUpperCase()%> |
			<font color="#dd8833"><%=df2.format(createDate)%></font></td>

	<td class="blog_small" align="right">
		COMMENT (<%=comNum%>)
	</td>

<%	if (isAdmin || creatorIdS.equals(myUidS))
	{
		if (isTaskBlog) idS = taskIdS;	// addblog.jsp uses taskId rather than pTaskId
%>
	<td class='blog_small' align="right">
		<a class="blog_small" href="../blog/addblog.jsp?type=<%=type%>&id=<%=idS%>&update=<%=blog.getObjectId()%>&backPage=<%=backPage%>&title=<%=synopsis%>">
		EDIT</a>
	</td>
<%	} %>

	</tr>
	</table>
	</td></tr>

	<tr><td><a name='reply'>&nbsp;</a>
	<table border="0" width="100%" height="1" cellspacing="0" cellpadding="0">
		<tr>
			<td bgcolor="#bb5555" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0" /></td>
		</tr>
	</table>
	</td></tr>
<!--// End parent blog
	////////////////////////////////////////-->


<%
	// label responses
	if (blogList.length > 0)
	{
		out.println("<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>");
		out.print("<tr><td class='head_pink'><b>Responses ... </b></td></tr>");
	}

	// list the children
	s = "location=\"" + cancelLnk + "\"";
    out.print(result.getBlogComments(pstuser, blogList,
    		blogIdS, objIdS, type, backPage, s, isPersonalBlog, isGuest, false));

	if (!isGuest) {
%>


	</table>
	</td>

	<td width="5">&nbsp;</td>
</tr>
</table>
</td>

<%
if (!isOMFAPP)
{%>
</td>
<td class="headlinerule">
	<table border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="100" width="1" /></td>
	    </tr>
	</table>
</td>

<td valign="top">
	<table><tr>
	<td width="3">&nbsp;</td>
	<td width='350'>
	<div class="namelist_hdr">The Project Team&nbsp;
		<a href="addalert.jsp?townId=<%=tid%>&projId=<%=projIdS%>&taskId=<%=taskIdS%>&backPage=<%=backPage%>">
		<img src="../i/eml.gif" border="0" /></a><br><br></div>

<%
	int uid;
	for (int i = 0; i < memberList.length; i++)
	{
		aUser = (user)memberList[i];
		uid = aUser.getObjectId();
		uname = aUser.getFullName();
%>
		<div class="namelist">
			<a href="../ep/ep1.jsp?uid=<%=uid%>" class="namelist"><%=uname%>
		</a><%if (uid==projCoordinatorId) {%>&nbsp;&nbsp;(COORDINATOR)<%}%></div>
<%	}	// end for

	// total team members
	out.print("<div><img src='../i/spacer.gif' height='10' /></div>");
	out.print("<div class='plaintext'>Total <b>" + memberList.length + "</b> team members</div>");
%>

	</td>
	</tr></table>

</td>
<%
}	// end if !isOMFAPP
else {
	out.print("</td>");
}
%>

</tr>
</table>
</td>
</tr>

<%	}	// END !isGuest %>

<tr><td>&nbsp;</td><tr>


<!-- BEGIN FOOTER TABLE -->
<jsp:include page="/foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

