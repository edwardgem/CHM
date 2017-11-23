<%@ page contentType="text/html; charset=utf-8"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2007, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: 	my_page.jsp
//	Author: ECC
//	Date:	12/03/07
//	Description: My Page only for OMF.  Support showing user's page and circle page.
//
//	Modification:
//			@ECC070109	Angel reports outsider accessing the circle page.  I found that all circles are private
//						in that only members can see the blog.  Guest (isGuest) would see the empty page with only
//						moderator showing.  I change the code such that guest would not alter the Visitor list.
//
/////////////////////////////////////////////////////////////////////
//

%>

<%@ page import = "util.*" %>
<%@ page import = "mod.mfchat.OmfPresence" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.util.regex.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	String uidS = request.getParameter("uid");
	String noSession = "../out.jsp?go=ep/my_page.jsp?uid=" + uidS;
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%
	final int MAX_DISPLAY_BLOG = 10;
	final int MAX_VISITOR_NUM = 15;
	PstUserAbstractObject me = pstuser;

	if (me instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}

	String HOST = Util.getPropKey("pst", "PRM_HOST");
	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if (iRole > 0)
	{
		if ((iRole & user.iROLE_ADMIN) > 0)
			isAdmin = true;
	}

	// to check if session is CR, OMF, or PRM

	userManager uMgr = userManager.getInstance();
	userinfoManager uiMgr = userinfoManager.getInstance();
	resultManager rMgr = resultManager.getInstance();
	actionManager aMgr = actionManager.getInstance();
	meetingManager mtgMgr = meetingManager.getInstance();
	townManager tnMgr = townManager.getInstance();
	PstManager mgr = null;

	String s;

	boolean isMyPage = false;
	boolean isCirclePage = false;
	boolean isMyNote = false;
	boolean isGuest = false;			// circle guest can see description but not blog content
	int uid;
	user detailUser = null;
	int [] ids;
	int myUid = me.getObjectId();
	String myUidS = String.valueOf(myUid);

	OmfPresence.setOnline(myUid);

	PstAbstractObject targetObj;
	PstAbstractObject cirObj = null;
	String circleName = null;
	String cirOwnerLnk = null;

	s = request.getParameter("rf");
	boolean bRefresh = (s!=null && s.equals("1"));
	
	s = request.getParameter("type");
	if (s!=null && s.equals("note"))
		isMyNote = true;

	boolean isCircleGuest = false;
	if (uidS==null || uidS.equals("null"))
	{
		// this is showing the login user's page or showing my notes
		// it can also be circle guest come in to view the circle page
		String tidS = ((Integer)me.getAttribute("Towns")[0]).toString();
		if (((user)me).isCircleGuest()) {
			isCircleGuest = true;
			isCirclePage = true;
			cirObj = tnMgr.get(me, Integer.parseInt(tidS));

			// uid/uidS is set to circle Id
			uid = ((Integer)me.getAttribute("Towns")[0]).intValue();
			uidS = String.valueOf(uid);
		}
		else {
			if (!isMyNote)
				isMyPage = true;
			uid = me.getObjectId();
			uidS = String.valueOf(uid);
		}
	}
	else
	{
		// either showing another user's page or a circle page
		uid = Integer.parseInt(uidS);
		if (uid != me.getObjectId())
		{
			// this can be showing another user's page, or showing circle page
			try
			{
				detailUser = (user)uMgr.get(me, uid);	// may throw exception if it is circle page

				// check authorization
				if (!isAdmin)
				{
					ids = uMgr.findId(me, "om_acctname='" + detailUser.getObjectName()
							+ "' && TeamMembers=" + me.getObjectId());
					if (ids.length <=0)
					{
						s = detailUser.getFullName();
						response.sendRedirect("../out.jsp?msg=Access declined. Only " + s
								+ "'s friends are allowed to access this page.<br>"
								+ "Click this link to add <a href='ep/add_contact.jsp?search=" + detailUser.getObjectName() + "'><b>" + s + "</b></a> as your friend.&go=ep/ep_home.jsp");
						return;
					}
				}
			}
			catch (PmpException e)
			{
				// try to see if uid is actually a town (circle)
				try {cirObj = tnMgr.get(me, uid);}
				catch (PmpException ee) {response.sendRedirect("../out.jsp?msg=Page not found.&go=ep/ep_home.jsp"); return;}

				isCirclePage = true;

				// check authorization
				if (!isAdmin)
				{
					ids = uMgr.findId(me, "om_acctname='" + me.getObjectName()
							+ "' && Towns=" + uid);
					if (ids.length <=0)
					{
						//response.sendRedirect("../out.jsp?msg=Access declined. Only members of " + circleName
						//		+ " are allowed to access this page.&go=ep/ep_home.jsp");
						//return;
						isGuest = true;		// guest would only see who the moderator is, no blog show
					}
				}
			}
		}
		else
			isMyPage = true;
	}

	String userFullName = null;
	String userFirstName = "";
	if (isCirclePage) {
		circleName = (String)cirObj.getAttribute("Name")[0];
		if (circleName == null) circleName = cirObj.getObjectName();

		mgr = tnMgr;
		s = (String)cirObj.getAttribute("Chief")[0];
		if (s != null) {
			cirOwnerLnk = ((user)uMgr.get(me, Integer.parseInt(s))).getFullName();
			cirOwnerLnk = "<a href='ep1.jsp?uid=" + s + "'>" + cirOwnerLnk + "</a>";
		}
	}
	else {
		if  (detailUser == null)
			detailUser = (user)uMgr.get(me, uid);
		userFullName = detailUser.getFullName();
		userFirstName = detailUser.getStringAttribute("FirstName");
		mgr = uiMgr;
	}

	// labels
	String logbookTitle;
	String profileTitle=null;
	String subCat = "MyPage";
	if (isMyPage)
	{
		logbookTitle = "My Page";
		profileTitle = "My Profile";
	}
	else if (isMyNote)
	{
		logbookTitle = "My Notes";
		profileTitle = "My Profile";
		subCat = "MyNote";
	}
	else if (isCirclePage) {
		logbookTitle = "Circle Page";	//circleName + " Page";
		subCat = "";
	}
	else
	{
		logbookTitle = userFullName + "'s Page";
		profileTitle = userFullName + "'s Profile";
	}

	// visitors for Pages
	String visitorNames = "";
	String noteAuthorByMe = "";
	if (!isGuest)
	{
		// guest doesn't change the visitor list
		if (!isMyNote)
		{
			visitorNames = Util2.visitors(me, mgr, uid, MAX_VISITOR_NUM, isAdmin);
			String [] sa = visitorNames.split(" \\. ");
			if (sa.length >= MAX_VISITOR_NUM) visitorNames += " ...";
		}
		else
			noteAuthorByMe = "your friend " + PrmEvent.LNK1 + userFullName + PrmEvent.LNK2;
	}

	String backPage = "../ep/my_page.jsp?uid=" +uidS + ":rf=1";

	// construct expression
	// all or my blog or other's writing on mine
	String expr;
	if (!isMyNote)
		expr = "(TaskID='" + uidS + "')";			// user Id or circle Id
	else
		expr = "(Creator='" + uidS + "' || Attendee='" + uidS + "')";	// note i wrote or receive as individual

	String author = request.getParameter("author");
	String authExpr = "";
	if (author != null)
	{
		if (author.equals("me"))
			authExpr = " && (Creator='" + uid + "')";
		else if (author.equals("others"))
			authExpr = " && (Creator!='" + uid + "')";
		expr += authExpr;
	}
	else
		author = "all";

	// blog type
	boolean bAllType = false;
	String blogType;
	if (isCirclePage)
		blogType = result.TYPE_FRUM_BLOG;
	else if (isMyNote)
		blogType = result.TYPE_NOTE_BLOG;
	else
		blogType = result.TYPE_ENGR_BLOG;

	expr += " && (Type='" + blogType + "')";

	// for notes, also take out blocked ones *** SQL bug: this won't work
	//if (isMyNote)
	//	expr += " && (Block!='" + myUidS + "')";

	// get the list of blogs
	//System.out.println(expr);
	ids = rMgr.findId(me, expr);

	// for my notes, I need to include those to my towns
	if (isMyNote)
	{
		int [] ids1;
		Object [] towns = me.getAttribute("Towns");
		for (int i=0; i<towns.length; i++)
		{
			if (towns[i] == null) break;
			expr = "(Attendee='" + ((Integer)towns[i]).intValue() + "')" + authExpr;
			ids1 = rMgr.findId(me, expr);
			if (ids1.length > 0)
				ids = Util2.mergeIntArray(ids, ids1);	// sort merge
		}
	}

	PstAbstractObject [] blogArr = rMgr.get(me, ids);
	Util.sortDate(blogArr, "CreatedDate", true);

	// the new engineering blog
	PstAbstractObject obj;
	Object bTextObj;
	String bText = "";
	String blogIdS = request.getParameter("update");
	if (blogIdS != null)
	{
		// it must be after clicking addfile: continue to update the blog text.  Get the blog
		obj = rMgr.get(me, blogIdS);
		bTextObj = obj.getAttribute("Comment")[0];
		bText = new String((byte[])bTextObj);
	}
	else
		blogIdS = "none";		// for post_addfile to use

	Date now = new Date();
	Date fiveDaysAgo = new Date(now.getTime() - 5 * 86400000);
%>


<head>
<title><%=session.getAttribute("app")%> Page</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../forms.jsp" flush="true"/>
<script type="text/javascript">


<!--

function change_author(p)
{
	var type = "";
	if (<%=isMyNote%> == true)
		type = "&type=note";
	location = "my_page.jsp?uid=" + "<%=uidS%>" + "&author=" + p + type;
}

function reset_edit(id)
{
	var e = document.getElementById("note-" + id);
	e.value = '';

	e = document.getElementById("edit-" + id);
	e.style.display = "none";
}

function post_note(op, id)
{
	var f = document.forms["postNote-" + id];
	if (op == 2)
		f.email.value = "true";
}

function show_edit(id)
{
	var e = document.getElementById("edit-" + id);
	e.style.display = "block";
	document.getElementById("note-" + id).focus();
}

function del_note(id)
{
	// id is the blog id
	var f = document.forms["postNote-" + id];
	f.type.value = "<%=PrmEvent.ACT_DELTNOTE%>";
	f.uid.value = id + "";			// use the targetUid to pass the blog id
	f.submit();
}

function view_archive(e)
{
	var fname = e.options[e.selectedIndex].value;
	if (fname != "")
		location= '<%=HOST%>' + '/servlet/ShowFile?archiveFile=' + fname;
	return;
}

function showComment(id)
{
	var e = document.getElementById("com_"+id);
	if (e.style.display == 'none')
		e.style.display = 'block';
	else
		e.style.display = 'none';
}

//-->
</script>

<style type="text/css">
.blog_text { font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 14px; color: #353535; line-height: 20px;}
</style>

</head>

<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" height="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">

<table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr align="left" valign="top">
    <td width="100%">
	<jsp:include page="../head.jsp" flush="true"/>
</table>
<table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr align="left" valign="top">
    <td width='100%'>
      <table width='90%' border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td>
            <table width="100%" border="0" cellspacing="0" cellpadding="0">
              <tr>
                <td width="26" height="30"><a name="top">&nbsp;</a></td>
                <td width="754" height="30" align="left" valign="bottom" class="head">
				<%=logbookTitle%>
				 </td>
              </tr>
            </table>
          </td>
        </tr>
        <tr>
				<td width="100%">
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Home" />
				<jsp:param name="subCat" value="<%=subCat%>" />
				<jsp:param name="role" value="<%=iRole%>" />
			</jsp:include>
<!-- End of Navigation Menu -->
				</td>
	        </tr>

<tr>
	<td width='100%'>
	<table border='0' cellspacing="0" cellpadding="0" width='100%'>
	<tr>
	<td><img src='../i/spacer.gif' width='20' height='1'/></td>
<%
		String picURL = null;
		String name;
		if (!isCirclePage)
		{
			picURL = Util2.getPicURL(detailUser);
			name = userFullName;
			s = (String)detailUser.getAttribute("Motto")[0];
			if (s == null) s = "No Motto";
		}
		else
		{
			picURL = Util2.getPicURL(cirObj, "../i/group.jpg");
			name = circleName;

			bTextObj = cirObj.getAttribute("Description")[0];
			if (bTextObj != null)
				s = new String((byte[])bTextObj);
			else
				s = "No Description";
		}

		out.print("<td width='85' height='80'>");
		out.print("<img src=" + picURL + " height='80' style='margin:10px; padding:5px; border:2px solid #6699cc;'/></td>");
		out.print("<td width='90%' valign='bottom'>");
		out.print("<table><tr><td class='plaintext_bold'>" + name);

		if (isCirclePage) {
			// circle is a town, but use projId to pass to addalert.jsp which will use projId as townId for MeetWE
			out.print("&nbsp;<a href='../blog/addalert.jsp?projId=" + cirObj.getObjectId() + "&backPage=" + backPage + "'>");
			out.print("<img src='../i/eml.gif' border='0'></a>");
		}

		out.print("</td></tr>");
		out.print("<tr><td class='plaintext_grey'>" + s + "</td></tr>");
		if (isCirclePage && cirOwnerLnk!=null)
			out.print("<tr><td class='plaintext'>(Moderator: " + cirOwnerLnk + ")</td></tr>");
		out.print("<tr><td>&nbsp;</td></tr>");
		out.print("</table></td>");

		if (!isMyNote && !isGuest)
		{
			// post new blogs
			out.print("<td align='right' valign='top'><table width='250' border='0' cellspacing='0' cellpadding='0'>");
			out.print("<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>");
			out.print("<tr><td valign='middle'>");
			out.print("<img src='../i/bullet_tri.gif'>");
			out.print("<a class='listlinkbold' href='../blog/addblog.jsp?id=" + uidS + "&type=" + blogType + "&backPage=" + backPage + "'>");
			if (isMyPage) out.println("Write on My Page");
			else if (isCirclePage) out.println("Write on " + circleName + " Page");
			else out.println("Write on " + userFirstName + "'s Page");
			out.print("</a></td></tr>");

			// goto the user's profile
			if (!isMyPage && !isCirclePage) {
				out.print("<tr><td class='listlinkbold'><img src='../i/bullet_tri.gif'>");
				out.print("<a href='../ep/ep1.jsp?uid=" + uidS + "'>View " + userFirstName + "'s profile</a></td></tr>");
			}
%>

	<tr><td><img src='../i/spacer.gif' height='8'/></td></tr>
	<tr>
	<td valign="middle">
<form name='ArchiveForm'>
		<img src="../i/bullet_tri.gif" width="20" height="10">
	<select class="formtext" name="archive" onchange="view_archive(document.ArchiveForm.archive)">
		<option class="formtext" value="" selected>-- view archive --
<%
		String [] st;
		String range;

		Object [] archives;
		if (isCirclePage)
			archives = cirObj.getAttribute("Archive");
		else
			archives = detailUser.getAttribute("Archive");
		Arrays.sort(archives, new Comparator()
		{
			public int compare(Object o1, Object o2)
			{
				try{
				String [] sa = ((String)o1).split("_");
				long l1 = Long.parseLong(sa[1].substring(0,sa[1].length()-4));
				sa = ((String)o2).split("_");
				long l2 = Long.parseLong(sa[1].substring(0,sa[1].length()-4));
				return (l2>l1)?-1:1;
				}catch(Exception e){
					return 0;}
			}
		});
		for (int i=archives.length-1; i>=0; i--)
		{
			String arc = (String)archives[i];
			if (arc == null) break;
			st = arc.split(":");
			range = st[0];
			out.print("<option class='formtext' value='" + st[1] + "'>" + range + "</option>");
		}
%>
	</select>
</form>
	</td></tr>
	</table>
	</td>
<%	}	// END if (!isMyNote) show archieve
	else {
		out.print("</td></tr></table></td>");
	}
%>


</tr></table>


<!-- ************************* -->
<!-- ***** List of Blog ***** -->

<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
<td width="25"><img src='../i/spacer.gif' width='25'/></td>

<td>
	<table border='0' cellpadding="0" cellspacing="0" width='100%'>

<!-- show visitors -->
<%
	out.print("<tr><td><table width='100%' border='0' cellspacing='0' cellpadding='0'>");
	if (!isMyNote && !isGuest)
	{
		out.print("<tr><td class='blog_small' width='120' valign='top'>Recent visitors:</td>");
		out.print("<td class='blog_small' align='left'>&nbsp;&nbsp;" + visitorNames + "</td>");
		out.print("</tr>");
	}

// choose author
	if (!isCirclePage)
	{
		out.print("<form>");
		out.print("<tr>");
		out.print("<td class='blog_small' width='120'>Show postings by:</td>");
		out.print("<td class='blog_small' align='left'>");
		out.print("<input type='radio' name='author' value='all' onclick='javascript:change_author(\"all\");'");
		if (author.equals("all")) out.print(" checked");
		out.print(">All&nbsp;&nbsp;");
		out.print("<input type='radio' name='author' value='me' onclick='javascript:change_author(\"me\");'");
		if (author.equals("me")) out.print(" checked");
		out.print(">Me&nbsp;&nbsp;");
		out.print("<input type='radio' name='author' value='others' onclick='javascript:change_author(\"others\");'");
		if (author.equals("others")) out.print(" checked");
		out.print(">Others");
		out.print("</td></tr>");
		out.print("</form>");
	}
	out.print("</table></td></tr>");
%>

	<tr><td><img src="../i/spacer.gif" height="3"></td></tr>

	<tr>
	<td bgcolor="#bb5555" height="1"><img src="../i/spacer.gif" width="100%" height="1" border="0"></td>
	</tr>
	</table>

	<table width='100%' border="0" cellspacing="0" cellpadding="0">



<!-- list of blogs contents -->
<%
	String bgcolor="";
	boolean even = false;

	int blogId, id, idx, pTaskId=0, origBlogId, editBlogId;
	result blogObj;
	String type, nameStr, postDateS, uname, lname, parentIdS;
	String idS=null, projIdS=null, bugIdS=null, gotoS=null;
	String ADtypeStr = null;
	String mtgLink = null;
	PstAbstractObject mObj, o;
	user bUser;
	Date dt;
	SimpleDateFormat df1 = new SimpleDateFormat ("MM/dd/yy (EEEEE)");
	SimpleDateFormat df2 = new SimpleDateFormat ("hh:mm a");
	SimpleDateFormat df3 = new SimpleDateFormat ("MM/dd/yy (EEE) hh:mm a");

	boolean bEditOK, bIsAuthor;
	String commentStr, creatorIdS, creatorFullName, privateStr;
	Object [] blockArr;
	boolean blocked;
	Integer io;
	Object [] shareArr;

	if (!isGuest)
	for (int i=0; i<blogArr.length; i++)
	{
		blogObj = (result)blogArr[i];
		if (blogObj == null) continue;

		// ***** should fix SQL bug *****
		// filter blocked here: there is a bug in findId() that stop me from using SQL to do this
		blockArr = blogObj.getAttribute("Block");
		blocked = false;
		for (int j=0; j<blockArr.length; j++)
		{
			if (blockArr[j] == null) break;
			if (Integer.parseInt((String)blockArr[j]) == myUid)
			{
				blocked = true;
				break;
			}
		}
		if (blocked) continue;

		// @ECC101608 filter private/personal blog
		privateStr = "";
		if (!isMyNote && !isCirclePage && !isAdmin)
		{
			s = Util2.getAttributeString(blogObj, "ShareID", ";");
			if (s.length() > 0)
			{
				if (s.indexOf(myUidS) == -1)
					continue;				// this blog is not shared by this user
				else
					privateStr = "(Private blog for " + userFullName + " only)&nbsp;&nbsp;&nbsp;";
			}
		}

		// cannot handle archived blog at this point (future enhancement potential)
		type = (String)blogObj.getAttribute("Type")[0];
		if (type.endsWith(result.TYPE_ARCHIVE))
			continue;

		// get blog text -- ECC: done in parseBlog()
		//bTextObj = blogObj.getAttribute("Comment")[0];
		//bText = (bTextObj==null)?"":new String((byte[])bTextObj, "utf-8");
		
		// SHARE blog: check to see if it is a blog shared from other circle
		blogId = 0;
		boolean bSharedBlog = false;
		editBlogId = blogObj.getObjectId();	// always just edit on original blog
		
		
		// **************************
		// for shared blog, the blog object will change to the other blog, but the content
		// might be changed to a customized content, so I need to pass a StringBuffer
		StringBuffer sBuf = new StringBuffer();
		try {blogObj = result.parseBlog(me, blogObj, sBuf);}
		catch (PmpException e) {continue;}
		
		bText = sBuf.toString();		// this might just be blog content or customized content

		// END: SHARE blog

		blogId = blogObj.getObjectId();
		blogIdS = String.valueOf(blogId);

		// do not list comments
		parentIdS = (String)blogObj.getAttribute("ParentID")[0];

		creatorIdS = (String)blogObj.getAttribute("Creator")[0];
		bUser = (user)uMgr.get(me, Integer.parseInt(creatorIdS));
		creatorFullName = bUser.getFullName();
		bIsAuthor = (creatorIdS.equals(myUidS));

		// for my notes, need to change the names so that it makes sense
		if (isMyNote)
		{
			// check to see if recipient is individual user or circle
			s = (String)blogObj.getAttribute("Attendee")[0];		// can be userId or townId
			id = Integer.parseInt(s);
			if (blogObj.getAttribute("Attendee").length > 1)
				bText = bText.replaceFirst("to you", "to all friends");
			else if (id != myUid)
			{
				try {
					s = ((user)uMgr.get(me, id)).getFullName();
					s = "to <a class='listlink' href='ep1.jsp?uid=" + id + "'>" + s + "</a>";
				}
				catch (PmpException e)
				{
					try {
						s = (String)tnMgr.get(me, id).getAttribute("Name")[0];
						s = "to <a class='listlink' href='my_page.jsp?uid=" + id + "'>" + s + "</a>";
					}
					catch (PmpException ee) {s = null;}	// fail to get name
				}
				if (s != null)
					bText = bText.replaceFirst("to you", s);
			}

			if (Integer.parseInt(creatorIdS) == myUid)
			{
				// the note is created by me
				bText = bText.replaceFirst(noteAuthorByMe, "You");
			}
			else
			{
				// note posted by others
				s = "your friend " + PrmEvent.LNK1 + creatorFullName + PrmEvent.LNK2;
				bText = bText.replaceFirst(s, "Your friend <a class='listlink' href='ep1.jsp?uid=" + creatorIdS + "'>"
						+ creatorFullName + "</a>");
			}
		}
		//System.out.println(bText);

		dt	= (Date)blogObj.getAttribute("CreatedDate")[0];

		if (parentIdS == null)
			idS	= (String)blogObj.getAttribute("TaskID")[0];
		else
		{
			// this is a comment
			o = rMgr.get(me, parentIdS);			// get the parent blog
			idS = (String)o.getAttribute("TaskID")[0];	// parent blog contains user Id or circleId
		}

		// personal/forum blog
		if (isCirclePage)
			nameStr = "Circle Blog";
		else
			nameStr = blogType + " Blog";
		idS = "-";
		bugIdS = projIdS = "";
		gotoS = "<a class='blog_small' href='logbook.jsp?update=" + blogIdS + "'> EDIT</a>&nbsp;&nbsp;";

		// partition line on top
		out.print("<tr><td width='1'><a name='" + blogIdS + "'><img src='../i/spacer.gif' width='1' height='5'></a></td></tr>");


		// *** top portion table
		out.print("<tr><td valign='top' width='100%'>");
		out.print("<table style='table-layout:fixed' border='0' width='100%' height='100%' cellspacing='0' cellpadding='0'><tr>");

		///////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////////////////////////////////////////////////////////
		/////// top left table contain Date and Blog Text and buttons

		out.print("<td height='100%' width='75%' valign='top'>");
		out.print("<table width='100%' height='100%' border='0' cellspacing='0' cellpadding='0'>");	// left side table

		// posted date
		out.print("<tr><td><img src='../i/spacer.gif' width='1' height='15'></td></tr>");
		out.print("<tr><td><table width='100%' cellspacing='0' cellpadding='0'>");
		out.print("<tr><td class='blog_date' valign='top' align='left'>");
		if (dt != null)
			out.print(df1.format(dt));
		else
			out.print("-");
		out.print("</td><td class='plaintext_grey' align='right'>" + privateStr + "</td></tr>");
		out.println("</table></td></tr>");
		out.print("<tr><td width='1'><img src='../i/spacer.gif' width='1' height='10'></td></tr>");

		// display blog
		if (isMyNote)
			out.print("<tr><td width='100%'><table cellspacing='0' cellpadding='0' width='100%'>");
		// ECC bug fix: put a height 100 here to make sure the table occupies the full space.
		out.print("<tr><td height='100' valign='top' class='blog_text' style='word-break:normal;line-height:20px;' width='100%'>");
		out.print(bText);
		out.print("<p></p></td>");
		if (isMyNote)
			out.print("<td width='200'>&nbsp;</td></tr></table></td>");
		out.print("</tr>");

		// posted by
		out.print("<tr><td valign='bottom'>");
		out.print("<table border='0' width='100%' cellspacing='0' cellpadding='0'>");	// bottom line table
		out.print("<tr><td class='blog_by'>POSTED BY " + creatorFullName.toUpperCase() + " | ");
		out.print("<font color='#dd8833'>" + df2.format(dt) + "</font></td>");

		if (isAdmin || (bIsAuthor && !isMyNote && dt.after(fiveDaysAgo)) )
			bEditOK = true;
		else
			bEditOK = false;

		// buttons on the bottom right
		out.print("<td width='250' align='right'>");
		out.print("<table border='0' width='100%' cellspacing='0' cellpadding='0'><tr>");	//button table

		// edit
		out.print("<td width='50' align='center'>");
		if (bEditOK && bIsAuthor)
		{
			out.print("<a class='blog_small' href='../blog/addblog.jsp?type=" + type + "&id=" +uidS
					+ "&update=" + editBlogId + "&backPage=" + backPage + "'>EDIT</a>");
		}
		out.print("</td>");

		// delete
		out.print("<td width='40' align='center'>");
		if (bEditOK)
		{
			out.print("<a class='blog_small' href='../blog/delblog.jsp?blogId=" + editBlogId
				+ "&backPage=" + backPage + "' onClick='return confirm(\"Are you sure you want to delete this Blog?\")'>");
			out.print("DEL</a>");
		}
		else if (isMyNote)
		{
			out.print("<a class='blog_small' href='javascript:del_note(" + blogIdS + ");' onClick='return confirm(\"Are you sure you want to delete this note?\")'>");
			out.print("DEL</a>");
		}
		out.print("</td>");

		// comment
		int comNum = 0;
		ids = rMgr.findId(me, "ParentID='" + blogIdS + "'");
		comNum = ids.length;
		out.print("<td width='90' align='enter'>");
		if (!isMyNote)
		{
			//out.print("<a class='blog_small' href='../blog/blog_comment.jsp?blogId=" + blogId
			//	+ "&id=" + uidS + "&blogNum=" + blogId + "&type=" + type + "#reply'>REPLY (" + comNum + ")</a>");
			out.print("<a class='blog_small' href='javascript:showComment("
					+ blogIdS + ");'>REPLY (" + comNum + ")</a>");
		}
		out.print("</td>");

		commentStr = null;
		if (comNum > 0)
		{
			Arrays.sort(ids);
			o = rMgr.get(me, ids[ids.length-1]);		// get the latest comment
			s = Util2.getAttributeString(o, "ShareID", ";");
			if (s.length()<=0 || s.indexOf(myUidS)!=-1)
			{
				id = Integer.parseInt((String)o.getAttribute("Creator")[0]);
				try {
					s = ((user)uMgr.get(me, id)).getFullName();
					s = "<a href='../ep/ep1.jsp?uid=" + id + "'>" + s + "</a>";
				} catch (PmpException e) {s = "user";}
				commentStr = "Last response by " + s + "<div class='com_date'>&nbsp;&nbsp;" + df3.format((Date)o.getAttribute("CreatedDate")[0])
					+ "</div><blockquote class='bq_com'>";
				bTextObj = o.getAttribute("Comment")[0];
				bText = new String((byte[])bTextObj, "utf-8");
				if (bText.length() > 100)
				{
					idx = bText.indexOf(" ", 100);
					if (idx != -1)
						bText = bText.substring(0, idx);
				}
				if (i == 0) s = "&view=true";		// manage viewBlogNum
				else s = "";
				commentStr += bText + " ... <a class='listlink' href='../blog/blog_comment.jsp?blogId=" + blogIdS
						+ "&id=" + uidS + "&type=" + blogType + s + "#reply'>read more</a></blockquote>";
			}
		}

		String list = "";
		if (!isMyPage)
			list = uidS + "," + me.getObjectId();
		else
			list = uidS;

		// Skype
		if (!isMyPage && !isCirclePage && !isMyNote)
		{
			String skypeName = (String)bUser.getAttribute("SkypeName")[0];
			out.print("<td width='90' align='center'>");
			if (skypeName != null)
				out.print("<a href='skype:" + skypeName + "'>");	// for marketing, now always display icon
			else
				out.print("<a href='javascript:alert(\"Sorry, the user " + userFullName + " has not entered a Skype name.\");'>");
			out.print("<img src='../i/skype.gif' border='0'></a>");
			out.print("</td>");
		}

		// email
		if (!isMyNote)
		{
			out.print("<td width='60' align='center'>");
			out.print("<a class='blog_small' href='../blog/addalert.jsp?list=" + list + "&backPage=" + backPage
				+ "&id=" + blogObj.getObjectId());
			if (isCirclePage)
				out.print("&circle=" + uidS);
			out.print("&type=blog'>EMAIL</a></td>");
		}

		out.print("</tr></table>");	// close button table
		out.print("</tr>");

		out.println("</table>");	// close bottom line table

		/////////////////////////////////
		// add a DIV to show comments and add comment in place
		PstAbstractObject [] commentList = rMgr.get(me, ids);
		out.print("<DIV id='com_" + blogIdS + "' style='display:none;'>");
		// add a line
		out.print("<table width='100%'><tr><td bgcolor='#bbbbbb' width='100%' height='1'><tr><td>");
    	out.print("<img src='../i/spacer.gif' height='1' border='0'></td></tr></table>");

		out.print("<table width='100%'>");
		out.print(result.getBlogComments(me, commentList,
				blogIdS, uidS, blogType, backPage,
				true, isGuest, false));
		out.print("</table></DIV>");

		out.println("</td></tr></table></td>");	// close left side table
		///// End top left table

		///// middle partition line
		out.print("<td width='5'><img src='../i/spacer.gif' width='5'></td>");
		out.print("<td width='1' class='headlinerule'>");
		out.print("<table border='0' cellspacing='0' cellpadding='0' class='headlinerule'>");
		out.print("<tr><td><img src='../i/spacer.gif' height='100%' width='1' alt=' ' /></td></tr>");
		out.print("</table></td>");

		///////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////////////////////////////////////////////////////////
		///// top right table contain context and path
		out.print("<td width='10'>&nbsp;</td>");
		out.print("<td valign='top' width='25%'>");
		out.print("<table width='100%' border='0' cellspacing='0' cellpadding='0'>");
		out.print("<tr><td><img src='../i/spacer.gif' width='1' height='15'></td></tr>");

		// personal/forum blog/notes
		out.print("<tr><td width='100%' height='30' class='blog_small' valign='top'>" + nameStr);
		if (!isMyNote)
		{
			if (i==0 && !bRefresh) {
				// need to increment viewBlogNum for first blog if !bRefresh
				s = String.valueOf(Util.incAttrNum(rMgr, blogObj, "ViewBlogNum"));
			}
			else
				s = Util.getAttrNum(blogObj, "ViewBlogNum", "1");
			out.print("<span class='plaintext_small'>&nbsp;&nbsp;(viewed by: " + s + ")</span>");
		}
		out.print("</td></tr>");

		if (commentStr == null)
		{
			if (i == 0) s = "&view=true";		// manage viewBlogNum
			else s = "";
			if (!isMyNote)
				commentStr = "<img src='../i/bullet_tri.gif' /><a href='../blog/blog_comment.jsp?blogId=" + blogId
					+ "&id=" + uidS + "&type=" + blogType + s + "#reply'>Post a reply</a>";
			else
			{
				// for note, allow user to post a reply immediately
				s = "postNote-" + blogIdS;
				out.print("<form name='" + s + "' method='post' action='../servlet/OmfEventAjax'>");
				out.print("<input type='hidden' name='email' value=''>");
				out.print("<input type='hidden' name='uid' value='" + creatorIdS + "'>");	// targetUid
				out.print("<input type='hidden' name='backPage' value='" + HOST + "/ep/my_page.jsp?type=note'>");
				out.print("<input type='hidden' name='type' value='" + PrmEvent.ACT_POSTNOTE + "'>");
				if (Integer.parseInt(creatorIdS)!=myUid)
				{
					out.print("<tr><td width='100%' class='blog_small' valign='top'><img src='../i/bullet_tri.gif' />");
					out.print("<a href='javascript:show_edit(" + blogIdS + ");'>Post a reply</a></td></tr>");
					out.print("<tr id='edit-"+ blogIdS + "' style='display:none'>");
					out.print("<td width='100%' class='blog_text' valign='top'>");
					out.print("<textarea id='note-" + blogIdS + "' name='note' class='formtext' wrap='logical' rows='3' cols='26' style='padding:2px'></textarea>");
					out.print("<br><input type='reset' value='Cancel' onClick='reset_edit(" + blogIdS + ");' class='button_small'>&nbsp;");
					out.print("<input type='submit' value='Post' onClick='post_note(1, " + blogIdS + ");' class='button_small'>&nbsp;");
					out.print("<input type='submit' value='Post & Email' onClick='post_note(2, " + blogIdS + ");' class='button_small' style='width:78px'>");
					out.print("</td></tr>");
				}
				out.print("</form>");
			}
		}
		if (commentStr != null)
			out.print("<tr><td width='100%' class='blog_text' valign='top'>" + commentStr + "</td></tr>");

		out.print("</table></td>");
		///// End top right table

		out.print("</tr></table></td></tr>");
		// *** close the top portion table


		// bottom portion

		// partition at the end
		out.print("<tr><td><img src='../i/spacer.gif' width='3'></td></tr>");
		out.print("<tr><td bgcolor='#bbbbbb'><img src='../i/spacer.gif' height='1' width='100%' border='0'></td></tr>");
	}	// end for loop: listing of blog

	if (isGuest)
	{
		out.print("<tr><td><img src='../i/spacer.gif' height='5' /></td></tr>");
		out.print("<tr><td class='plaintext'>This is a private circle.  Only members of this circle may access the content of this page.");
		out.print("&nbsp;Back to <a href='ep_home.jsp'>My Home Page</a>.</td></tr>");
	}
%>

	<tr><td><img src="../i/spacer.gif" height="3"/></td></tr>


	</table>
</td>
<!-- End List of Blog -->

<!-- ************************** -->

      </table>
    </td>
  </tr>

</table>

<p>&nbsp;</p>
<jsp:include page="../foot.jsp" flush="true"/>
</body>
</html>
