<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>

<%
////////////////////////////////////////////////////
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	addblog.jsp
//	Author:	ECC
//	Date:	03/22/04
//	Description:
//		Write blog for town, project, task.  NO forum.
//	Modification:
//		@042905ECC	Support adding blog to bug.
//		@100905ECC	Support bug blog template.
//		@AGQ032806	Moved form to outside of table (for compatibility with Multi upload)
//					Added multi upload feature
//		@ECC090806	Support forum blogging (Help forum).
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
<%@ page import = "org.apache.log4j.Logger" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	Logger l = PrmLog.getLog();

	boolean isPDA = Prm.isPDA(request);
	String host = Util.getPropKey("pst", "PRM_HOST");

	String type = request.getParameter("type");			// Bug, Task, Action, Forum or Meeting
	String idS = request.getParameter("id");			// bug id or task id or meeting id
	String blogIdS = request.getParameter("update");
	String backPage = request.getParameter("backPage");
	String keepDate = request.getParameter("keepDate");
	if (keepDate==null) keepDate = "";
	String bText = "";
	String title = null;
	String subjTitle = request.getParameter("title");
	if (subjTitle == null) subjTitle = "";
	
	String s;

	String ownerName = null;			// name of the owner of MyPage
	project projObj = null;
	
	projectManager pjMgr = projectManager.getInstance();
	resultManager rMgr = resultManager.getInstance();
	taskManager tkMgr = taskManager.getInstance();
	bugManager bgMgr = bugManager.getInstance();
	meetingManager mtgMgr = meetingManager.getInstance();
	actionManager aMgr = actionManager.getInstance();

	boolean isForumBlog = false;
	boolean isCircleBlog = false;
	boolean isMtgBlog = false;
	boolean isQuestBlog = false;
	boolean isTaskBlog = false;
	boolean isBugBlog = false;
	boolean isActnBlog = false;
	boolean isProjBlog = false;

	if (type!=null) {
		if (type.equals(result.TYPE_FRUM_BLOG)) {
			if (backPage == null) {
				isForumBlog = true;
				backPage = "../info/help.jsp";
			}
			else
				isCircleBlog = true;
		}
		else if (type.equals(result.TYPE_MTG_BLOG)) {
			isMtgBlog = true;
			backPage = "../meeting/mtg_view.jsp?mid="+idS+"&refresh=1#blog";
		}
		else if (type.equals(result.TYPE_QUEST_BLOG)) {
			isQuestBlog = true;
			backPage = "../question/q_respond.jsp?qid="+idS;
		}
		else if (type.equals(result.TYPE_ENGR_BLOG)) {
			// @ECC101608 personal/private blog
			try {ownerName = ((user)userManager.getInstance().get(pstuser, Integer.parseInt(idS))).getFullName();}
			catch (Exception e) {}
		}
		else if (type.equals(result.TYPE_TASK_BLOG)) {
			isTaskBlog = true;
		}
		else if (type.equals(result.TYPE_BUG_BLOG)) {
			isBugBlog = true;
		}
		else if (type.equals(result.TYPE_ACTN_BLOG)) {
			isActnBlog = true;
		}
		else if (type.equals(result.TYPE_PROJ_BLOG)) {
			isProjBlog = true;
		}
	}

	boolean bUpdate = false;
	boolean isPrivate = false;
	result blog;
	Object bTextObj;
	String bugEmail2 = null;
	
	if (blogIdS!=null)
	{
		// update/edit a blog
		bUpdate = true;
		title = "Edit Blog";

		// get the blog text
		blog = (result)rMgr.get(pstuser, blogIdS);
		bTextObj = blog.getAttribute("Comment")[0];
		bText = (bTextObj==null)?"":new String((byte[])bTextObj, "utf-8");
		// bText = bText.replaceAll("<br>", "\n");
		
		if (isPDA) {
			// strip the HTML tag
			bText = bText.replaceAll("<p>", "\n");
			bText = bText.replaceAll("\\<.*?\\>", "");
		}

		if (blog.getAttribute("ShareID")[0] != null)
			isPrivate = true;

		// blog subject title
		if (isForumBlog || isMtgBlog) {
			if ( subjTitle.length()<=0 && (s = (String)blog.getAttribute("Name")[0])!=null )
				subjTitle = s;
		}
		
		// get the project object
		s = blog.getStringAttribute("ProjectID");
		if (s != null) {
			projObj = (project) pjMgr.get(pstuser, Integer.parseInt(s));
		}
	}
	
	// new blog
	else
	{
		title = "Post Blog";
		blogIdS = "none";			// for Javascript calling addFile

		// @100905ECC support bug blog template
		PstAbstractObject o;
		if (isBugBlog) {
			o = bgMgr.get(pstuser, idS);
			s = (String)o.getAttribute("ProjectID")[0];		// for issue, there might not be a proj Id yet
			if (s != null) {
				projObj = (project) pjMgr.get(pstuser, Integer.parseInt(s));
				
				// project level bug blog template
				String bugBlogIdS = projObj.getOption(project.BUG_BLOG_ID);
				if (bugBlogIdS != null) {
					blog = (result)rMgr.get(pstuser, bugBlogIdS);
					bTextObj = blog.getAttribute("Comment")[0];
					bText = (bTextObj==null)?"":new String((byte[])bTextObj, "utf-8");
				}
			}
			
			// Email2 for Ticket submitter
			s = o.getStringAttribute("Email2");
			if (s!=null && s.indexOf('@')!=-1)
				bugEmail2 = s;
		}
		else if (isTaskBlog) {
			o = tkMgr.get(pstuser, idS);
			s = o.getStringAttribute("ProjectID");
			if (s != null) {
				projObj = (project) pjMgr.get(pstuser, Integer.parseInt(s));
				
				// check task level then project level task blog template
				String taskBlogIdS = ((task)o).getOption(task.TASK_BLOG_ID);	// task level
				if (taskBlogIdS == null)
					taskBlogIdS = projObj.getOption(project.TASK_BLOG_ID);		// project level
				if (taskBlogIdS != null) {
					try {
						blog = (result)rMgr.get(pstuser, taskBlogIdS);
						bTextObj = blog.getAttribute("Comment")[0];
						bText = (bTextObj==null)?"":new String((byte[])bTextObj, "utf-8");
					}
					catch (PmpException e) {l.error("Blog template [" + taskBlogIdS + "] problem.");}
				}
			}
		}
		else if (isMtgBlog) {
			o = mtgMgr.get(pstuser, idS);
			s = o.getStringAttribute("ProjectID");
			if (s != null) {
				projObj = (project) pjMgr.get(pstuser, Integer.parseInt(s));
			}
		}
		else if (isActnBlog) {
			o = aMgr.get(pstuser, idS);
			s = o.getStringAttribute("ProjectID");
			if (s != null) {
				projObj = (project) pjMgr.get(pstuser, Integer.parseInt(s));
			}
		}
		else if (isProjBlog) {
			o = pjMgr.get(pstuser, Integer.parseInt(idS));
			projObj = (project) o;
		}
	}
	
	// check to see if project block posting option is on
	if (projObj != null) {
		if (projObj.getOption(project.OP_NO_POST) != null) {
			response.sendRedirect("../out.jsp?msg=5004&go=project/proj_top.jsp");
			return;
		}
	}

%>

<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8"/>
<script src="../multifile.js"></script>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../forms.jsp" flush="true"/>
<script type="text/javascript" src="../resize.js"></script>
<script type="text/javascript" src="<%=host%>/FCKeditor/fckeditor.js"></script>
<script type="text/javascript">

//enter refresh time in "minutes:seconds" Minutes should range from 0 to inifinity. Seconds should range from 0 to 59
var limit="30:0";
var oFCKeditor;
var parselimit=limit.split(":");
parselimit=parselimit[0]*60+parselimit[1]*1
var msgE;

window.onload = function()
{
	if (<%=isPDA%> == false) {
		oFCKeditor = new FCKeditor( 'logText' ) ;
		oFCKeditor.ReplaceTextarea() ;
	
		// to enable dragging editor box
		setTextBoxId('logText');
		initDrag(300);
		new dragObject(handleBottom[0], null, new Position(0, beginHeight), new Position(0, 800),
						null, BottomMove, null, false, 0);
	}

	msgE = document.getElementById("timeoutMsg");
	beginRefresh(document.addWeblog);
	fo(document.addWeblog);
}


<!--

function goBack()
{
	var backPg = '<%=backPage%>';
	backPg = backPg.replace(':', '&');
	location = backPg;
}

function validation()
{
	if (<%=isForumBlog%>!=true && <%=isMtgBlog%>!=true)
	{
		// circle and quest blog
		formblock= document.getElementById('inputs');
		forminputs = formblock.getElementsByTagName('input');
		var isFileName = true;
		for (var i=0; i<forminputs.length; i++) {
			if (forminputs[i].type == 'file' && forminputs[i].value != '') {
				if (isFileName)
					isFileName = affirm_addfile(forminputs[i].value);
				else
					break;
			}
		}
		if(!isFileName)
			return isFileName;

		// @AGQ040406
		if(!findDuplicateFileName(forminputs))
			return false;
	}

		// meeting and forum blog requires title
		/*addWeblog.title.value = trim(addWeblog.title.value);
		if (addWeblog.title.value == '')
		{
			fixElement(addWeblog.title, "Please enter a TITLE for the blog.");
			return false;
		}*/

	document.getElementById("cancelBut").disabled = true;
	document.getElementById("submitBut1").disabled = true;
	document.getElementById("submitBut2").disabled = true;
	return true;
}

function validateAndSubmit()
{
	if (validation()) {
		addWeblog.submit();
	}
}

function setAddFile()
{
// @AGQ032806
	if (multi_selector.count == 1)
	{
		fixElement(document.getElementById("my_file_element"), "To add a file attachment, click the Browse button and choose a file to be attached, then click the Add button.");
		return false;
	}
	if (!validation())
		return false;

	addFileForm.backPage.value = "../blog/addblog.jsp?type=" + '<%=type%>'
		+ "::id=" + '<%=idS%>' + "::update=" + '<%=blogIdS%>' + "::backPage=" + '<%=backPage%>';
	var oEditor = FCKeditorAPI.GetInstance('logText');
	oEditor.InsertHtml( "!@@!" ) ;	// help to mark the current cursor position
	addFileForm.blogText.value = oEditor.EditorDocument.body.innerHTML;
	//return true;
	addFileForm.submit();
}

function saveAndCont()
{
	if (!validation())
		return false;
	addWeblog.cont.value = "true";
	backPage = "../blog/addblog.jsp?type=" + '<%=type%>'
	+ "::id=" + '<%=idS%>' + "::update=" + '<%=blogIdS%>';
	addWeblog.backPage.value = "../blog/addblog.jsp?type=" + '<%=type%>'
		+ "::id=" + '<%=idS%>' + "::update=" + '<%=blogIdS%>' + "::title=" + '<%=subjTitle%>'
		+ "::backPage=" + '<%=backPage%>';
	addWeblog.submit();
}
//-->
</script>

</head>


<title>
	<%=Prm.getAppTitle()%> Post Blog
</title>

<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="90%" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true"/>

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<table>
	<tr>
	<td width="100%">

	<table>
	<tr><td>
	<b class="head">
	<%=title%>
	</b>
	</td></tr>
	</table>

	</td>
	</tr>

	<tr><td height="3"><img src="../i/spacer.gif" width="1" height="3" border="0"></td></tr>
	</table>

	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>


<!-- CONTENT -->
<table width='80%'>
	<tr><td colspan="2"><img src="../i/spacer.gif" width="1" height="10"/></td></tr>
<%	if (!isForumBlog && !isMtgBlog)
	{
		// circle blog and quest blog can attach files
%>
<!-- attachment file -->
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_big" valign="top">
			<!-- Attachment file for Blog -->
			<form name="addFileForm" action="../project/post_addfile.jsp" method="post" enctype="multipart/form-data">
			<input type="hidden" name="blogId" value="<%=blogIdS%>"/>
			<input type="hidden" name="type" value="<%=type%>"/>
			<input type="hidden" name="idS" value="<%=idS%>"/>
			<input type="hidden" name="blogText" value=""/>
			<input type="hidden" name="backPage" value=""/>
			<input type="hidden" name="keepDate" value="<%=keepDate%>"/>
				Click the below <b>Button</b> to select pictures and files for upload:<p>
		<%-- @AGQ032806 --%>
				<span id="inputs"><input id="my_file_element" type="file" class="formtext" size="50" /></span><br /><br />
				Click the <b>Upload Files</b> button to complete posting:<br />
				<table><tbody id="files_list"></tbody></table>
				<script>
					var multi_selector = new MultiSelector( document.getElementById( 'files_list' ), 10, document.getElementById( 'my_file_element' ).className , document.getElementById( 'my_file_element' ).size );
					multi_selector.addElement( document.getElementById( 'my_file_element' ) );
				</script>
				<br />
				<input class="formtext_small" type="button" name="add" value="Upload Files" onclick="return setAddFile();"/>
			</form>
		</td>
	</tr>
<!-- end attachment file -->


<form name="addWeblog" action="../blog/post_addblog.jsp" method="post">

<%	}
	else
	{	// for forum, need a title: start the form tag here
%>
<form name="addWeblog" action="../blog/post_addblog.jsp" method="post">

	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_blue">Title:&nbsp;&nbsp;
		<input class="formtext" type="text" name="title" size="80" value='<%=subjTitle%>'/>
		</td>
	</tr>
	<tr><td colspan="2"><img src="../i/spacer.gif" width="1" height="10"/></td></tr>

<%	} %>

<!-- Post or Update Blog -->
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_big">
<%	if (bUpdate)
	{%>
		<br>Update the Blog text below. Click the <b>Submit</b> Button to republish the Blog to the <%=type%>.
<%	}else
	{%>
		<br>Enter Blog text to be published to the <%=type%>.  Click the <b>Submit</b> Button to publish the Blog.
<%	}%>
		<br><br></td>
	</tr>

<!-- add comments -->
<input type="hidden" name="type" value="<%=type%>"/>
<input type="hidden" name="update" value="<%=blogIdS%>"/>
<input type="hidden" name="id" value="<%=idS%>"/>
<input type="hidden" name="cont" value=""/>
<input type="hidden" name="backPage" value="<%=backPage%>"/>
<%	if (bUpdate) {%>
		<input type="hidden" name="update" value="<%=blogIdS%>"/>
		<input type="hidden" name="keepDate" value="<%=keepDate%>"/>
<%	}%>
	<tr>
		<td width="15">&nbsp;</td>
		<td>
		<table width="100%" border="0" cellspacing="0" cellpadding="0">
		<tr><td colspan="2" valign="top">
			<div id='textDiv'>
				<textarea name="logText" id='logText' rows=10; style='width:100%'><%=bText%></textarea>
			</div>
			<div align='right'>
			<span id="handleBottom" ><img src='../i/drag.gif' style="cursor:s-resize;"/></span>
			<span><img src='../i/spacer.gif' width='20' height='1'/></span>
			</div>
		</td>
		</tr>
		
<%
	// option to email or suppress
	if (!bUpdate
			&& (isTaskBlog || isMtgBlog || isActnBlog || isQuestBlog || isCircleBlog || isBugBlog)) {
		String checkStr = "";
		if (projObj != null) {
			checkStr = projObj.getOption(project.OP_NOTIFY_BLOG)!=null?"checked":"";
		}
		out.print("<tr><td colspan='2' class='plaintext_big'>");
		out.print("<input type='checkbox' name='sendEmail' " + checkStr);
		out.print(">&nbsp;Send Email notification to ");
		if (isMtgBlog)
			out.print("meeting members");
		else if (isActnBlog)
			out.print("action item responsible members");
		else if (isQuestBlog)
			out.print("event/survey participants");
		else if (isCircleBlog)
			out.print("circle members");
		else	// isTaskBlog or BugBlog
			out.print("team members");
			
		// I need the following because checkbox returns null in post page if it is uncheck
		out.print("<input type='hidden' name='overrideSendEmail' value='true'>");
		out.print("</td></tr>");
		
		// for Bug ticket, send email to submitted user
		if (bugEmail2 != null) {
			out.print("<tr><td colspan='2' class='plaintext_big'>");
			out.print("<input type='checkbox' name='sendEmail2' checked");
			out.print(">&nbsp;Send Email notification to ticket submitter: " + bugEmail2);
			out.print("<input type='hidden' name='overrideSendEmail2' value='true'>");
			out.print("</td></tr>");
		}

	}
%>
		<tr><td id='timeoutMsg' class='plaintext' style='color:#00cc00'></td></tr>

<%	if (ownerName != null)
	{	// blog for MyPage to user
%>
		<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>
		<tr><td colspan='2' class='plaintext_big'>
			<img src='../i/spacer.gif' width='20' height='1' />
			<input type='checkbox' name='private' value='true' <%if (isPrivate) out.print(" checked");%>/>&nbsp;This blog is a private message and is only viewed by <b><%=ownerName%></b>
		</td></tr>
<%	}%>

		<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>

		<tr>
		<td colspan='2' align="center">
			<input type='button' id='cancelBut' class='button_medium' onclick='javascript:goBack();' value='Cancel'/>&nbsp;
			<input type='button' id='submitBut1' class='button_medium' onclick='return saveAndCont();' value='Continue'/>&nbsp;
			<input type='button' id='submitBut2' class='button_medium' onclick='return validateAndSubmit();' value='Submit'/>
		</td></tr>
		</table>
		</td>
	</tr>

</form>
<!-- End of add comments -->


</table>


	</td>
</tr>


<tr><td>&nbsp;</td><tr>


<!-- BEGIN FOOTER TABLE -->
<jsp:include page="/foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->


<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

