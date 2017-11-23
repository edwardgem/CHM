<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//	Copyright (c) 2005, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: logbook.jsp
//	Author: ECC
//	Date:	10/26/05
//	Description: Engineering logbook.
//	Modification:
//			@041906SSI	Added sort function to Project names.
//			@ECC081407	Support Blog Module to access Engineering Logbook.
//
/////////////////////////////////////////////////////////////////////
//

%>

<%@ page import = "util.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.util.regex.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>

<%
	String uidS = request.getParameter("uid");
	String noSession = "../out.jsp?go=ep/logbook.jsp?uid=" + uidS;
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%
	final int MAX_DISPLAY_BLOG = 10;
	final int MAX_DISPLAY_IDX = 4;

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	String host = Util.getPropKey("pst", "PRM_HOST");
	boolean isAdmin = false;
	boolean isDirector = false;
	boolean isProjAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if (iRole > 0)
	{
		if ((iRole & user.iROLE_ADMIN) > 0)
			isAdmin = true;
		if ((iRole & user.iROLE_DIRECTOR) > 0)
			isDirector = true;
	}

	// to check if session is CR, OMF, or PRM
	boolean isCRAPP = false;
	boolean isOMFAPP = false;
	boolean isPRMAPP = false;
	String app = (String)session.getAttribute("app");
	if (app.equals("CR"))
		isCRAPP = true;
	else if (app.equals("OMF"))
		isOMFAPP = true;
	else if (app.equals("PRM"))
		isPRMAPP = true;

	userManager uMgr = userManager.getInstance();
	resultManager rMgr = resultManager.getInstance();
	bugManager bMgr = bugManager.getInstance();
	projectManager pjMgr = projectManager.getInstance();
	taskManager tkMgr = taskManager.getInstance();
	planTaskManager ptkMgr = planTaskManager.getInstance();
	actionManager aMgr = actionManager.getInstance();

	String s;
	boolean bCheckPref = true;

	// project name: filter later
	int selectedProjId = 0;
	s = request.getParameter("projId");
	if (s!=null && !s.equals("null") && s!="")
		selectedProjId = Integer.parseInt(s);
	else bCheckPref = false;

	// construct expression
	boolean isMyLogbook = true;
	int uid;
	if (uidS==null || uidS.equals("null"))
		uid = pstuser.getObjectId();
	else
	{
		uid = Integer.parseInt(uidS);
		if (uid != pstuser.getObjectId())
			isMyLogbook = false;
	}
	String expr = "(Creator='" + uid + "')";
	String userName = PstManager.getNameById(pstuser, uid);
	
	if (selectedProjId != 0) {
		expr += " && (ProjectID='" + selectedProjId + "')";
	}

	// blog type
	String [] PRM_1_Type = {result.TYPE_ENGR_BLOG, result.TYPE_BUG_BLOG, result.TYPE_TASK_BLOG, result.TYPE_ACTN_BLOG};
	String [] PRM_2_Type = {result.TYPE_ENGR_BLOG, result.TYPE_TASK_BLOG, result.TYPE_ACTN_BLOG};
	String [] PRMblogType;
	if (Prm.isCtModule(session)) PRMblogType = PRM_1_Type;
	else PRMblogType = PRM_2_Type;
	String [] CRblogType  = {result.TYPE_ENGR_BLOG, result.TYPE_TASK_BLOG};
	String [] blogType;
	if (isPRMAPP)
		blogType = PRMblogType;
	else
		blogType = CRblogType;
	String tempExpr = "";
	int count = 0;
	for (int i=0; i < blogType.length; i++)
	{
		s = request.getParameter(blogType[i]);
		if (s!=null && s.length()>0)
		{
			if (tempExpr.length() > 0) tempExpr += " || ";
			tempExpr += "Type='" + blogType[i] + "'";
			count++;
			bCheckPref = false;
		}
	}
	if (count >= 4) tempExpr = "";		// select all types: optimize to no proj phase
	if (tempExpr.length() > 0)
	{
		tempExpr = "(" + tempExpr + ")";
		if (expr.length() > 0) expr += " && ";
		expr += tempExpr;
	}
	boolean bAllType = false;
	if (tempExpr.length() == 0)
	{
		bAllType = true;
		if (isPRMAPP)
			expr += " && (Type!='" + result.TYPE_PROJ_PHASE + "')";
		else
		{
			for (int i=0; i<blogType.length; i++)
			{
				if (tempExpr.length() > 0) tempExpr += " || ";
				tempExpr += "Type='" + blogType[i] + "'";
			}
			tempExpr = "(" + tempExpr + ")";
			if (expr.length() > 0) expr += " && ";
			expr += tempExpr;
		}
	}

	//////////////
	// keywords: use Java regex to filter
	String matchKey = "";
	boolean addParen = false;
	String keywords = request.getParameter("Keyword");
	if (keywords == null) keywords = "";
	if (keywords.length() > 0)
	{
		// OR together multiple keywords
		bCheckPref = false;
		String delim = " ";
		if (keywords.indexOf(",") != -1)
			delim = ",";
		else if (keywords.indexOf(";") != -1)
			delim = ";";
		String [] sa = keywords.split(delim);

		for (int i=0; i<sa.length; i++)
		{
			// trim trailing spaces and remove trailing % and *
			s = sa[i].replaceAll("^[ \t%*]+|[\\\\]+|[ \t%*]+$", "");
			if (s.length() == 0) continue;
			if (matchKey.length() > 0) matchKey += "|";
			matchKey += "(" + s + ")";
		}
	}

	Pattern p = Pattern.compile(matchKey, Pattern.CASE_INSENSITIVE);
	Matcher m = p.matcher("");

	// see if I need to check my preference
	if (bCheckPref)
	{
		userinfo ui = (userinfo)userinfoManager.getInstance().get(pstuser, String.valueOf(pstuser.getObjectId()));
		Object [] o = ui.getAttribute("Preference");
		for (int i=0; i<o.length; i++)
		{
			s = (String)o[i];
			if (s.startsWith("LogBkFilter"))
			{
				s = s.substring(s.indexOf(':')+1);
				response.sendRedirect("logbook.jsp?" + s);
				return;
			}
		}
	}

	// get the list of blogs
	int [] ids = rMgr.findId(pstuser, expr);
	PstAbstractObject [] blogArr = rMgr.get(pstuser, ids);
	Util.sortDate(blogArr, "CreatedDate", true);

	String projName = "";

	// the new engineering blog
	PstAbstractObject obj;
	Object bTextObj;
	String bText = "";
	String blogIdS = request.getParameter("update");
	if (blogIdS != null)
	{
		// it must be after clicking addfile: continue to update the blog text.  Get the blog
		obj = rMgr.get(pstuser, blogIdS);
		bTextObj = obj.getAttribute("Comment")[0];
		bText = new String((byte[])bTextObj, "utf-8");
	}
	else
		blogIdS = "none";		// for post_addfile to use

	int start = 0;
	int lastStart = 0;
	int startIdx = 0;
	s = request.getParameter("displayNum");
	if (s!=null && s.length()>0)
		start = Integer.parseInt(s);
	s = request.getParameter("lastStart");
	if (s!=null && s.length()>0) {
		lastStart = Integer.parseInt(s);
		if (lastStart<start && (lastStart+MAX_DISPLAY_IDX)>start) {
			startIdx = lastStart;
		}
		else if (lastStart==start && start>0) {
			startIdx = start-MAX_DISPLAY_IDX;
		}
		else {
			startIdx = start;
		}
	}
	if (startIdx < 0) startIdx = 0;
%>


<head>
<title><%=Prm.getAppTitle()%> Logbook</title>
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../forms.jsp" flush="true"/>
<script type="text/javascript" src="../effect.js"></script>
<script type="text/javascript" src="<%=host%>/FCKeditor/fckeditor.js"></script>
<script type="text/javascript">
  var oFCKeditor;
  window.onload = function()
  {
	if (<%=isMyLogbook%>)
	{
		oFCKeditor = new FCKeditor( 'logText' ) ;
		oFCKeditor.ReplaceTextarea() ;
	}
  }

var tog0 = false;	// default hide editor to begin with
var tog1 = true;	// default show filter to begin with
init_img(0, "../i/editor_show.gif", "../i/editor_hide.gif");
init_img(1, "../i/filter_show.gif", "../i/filter_hide.gif");

<!--

function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

function validation()
{
	if (!affirm_addfile(addFile.Attachment.value))
	{
		addFile.Attachment.focus();
		return false;
	}
	return true;
}

function setAddFile()
{
	if (addFile.Attachment.value == '')
	{
		fixElement(addFile.Attachment, "To add a file attachment, click the Browse button and choose a file to be attached, then click the Add button.");
		return false;
	}
	if (!validation())
		return false;
	addFile.backPage.value = "../ep/logbook.jsp?update=<%=blogIdS%>";
	//addFile.blogText.value = ((document.getElementById('logText___Frame').contentWindow.document.getElementById('eEditorArea')).contentWindow.document.body.innerHTML);
	var oEditor = FCKeditorAPI.GetInstance('logText');
	addFile.blogText.value = oEditor.EditorDocument.body.innerHTML;
	return true;
}

function toggle(text, i)
{
	if (i==0) tog = tog0;
	else tog = tog1;

	if (!tog)
		appear(text, i);
	else
		disappear(text, i);

	if (i==0) tog0 = !tog0;
	else tog1 = !tog1;
}

function toggle_editor(text, i)
{
	toggle(text, 0);

	// hide filter
	if (tog0)
	{
		tog1 = true;
		toggle(text, 1);
	}
}

function saveFilter()
{
	Filter.action = "../ep/save_pref.jsp";
	Filter.submit();
}

function check_task(type)
{
	/*if (!Filter.Task.checked)
		Filter.projName.disabled = true;
	else
		Filter.projName.disabled = false;*/
}

function at(i)
{
	var newStartIdx = <%=startIdx%>;
	if (i < <%=startIdx%>) {
		newStartIdx = <%=startIdx%> - <%=MAX_DISPLAY_IDX%>;
		if (newStartIdx < 0)
			newStartIdx = 0;
	}
	Filter.action = "logbook.jsp";
	Filter.displayNum.value = i;
	Filter.lastStart.value = newStartIdx;
	Filter.submit();
}

//-->
</script>

</head>

<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" height="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">

<table width="90%" border="0" cellspacing="0" cellpadding="0">
  <tr align="left" valign="top">
    <td width="100%">
	<jsp:include page="../head.jsp" flush="true"/>
</table>
<table border="0" cellspacing="0" cellpadding="0" width='90%'>
<tr>
</td>
  </tr>
  <tr align="left" valign="top">
    <td>
      <table width="100%" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td>
            <table width="100%" border="0" cellspacing="0" cellpadding="0">
              <tr>
                <td width="26" height="30"><a name="top">&nbsp;</a></td>
                <td height="30" align="left" valign="bottom" class="head">
				<%=userName%>'s eLogbook
				 </td>
              </tr>
            </table>
          </td>
        </tr>

        <tr>
          <td width="100%">

<!-- TAB -->
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Home" />
				<jsp:param name="subCat" value="eLogBook" />
				<jsp:param name="role" value="<%=iRole%>" />
			</jsp:include>

<!-- End of Navigation SUB-Menu -->
				</td>
	        </tr>
        <tr><td>&nbsp;</td></tr>


<table border="0" cellspacing="0" cellpadding="0">

<%	if (isMyLogbook)
	{%>
<!-- ********* Edit box for entering Journal -->
<tr>
	<td>&nbsp;&nbsp;&nbsp;&nbsp;
	<img id="nav0" name="nav0" onClick="toggle_editor('menu',0)" src="../i/editor_show.gif" alt="expand" border="0">
	</td>
</tr>

<tr>
	<td>
<div id="menu0" style="display: none">

	<table border="0" cellspacing="0" cellpadding="0">

<!-- Attachment file for Blog -->
<form name="addFile" action="../project/post_addfile.jsp" method="post" enctype="multipart/form-data">
<input type="hidden" name="blogId" value="<%=blogIdS%>">
<input type="hidden" name="type" value="Personal">
<input type="hidden" name="blogText" value="">
<input type="hidden" name="backPage" value="">
<input type="hidden" name="uid" value="<%=uidS%>">
	<tr>
		<td width="25">&nbsp;</td>
		<td class="plaintext_big" valign="top">
		Attach file to blog:
			<input class="formtext" type="file" name="Attachment" size="50">&nbsp;
			<input type="submit" class="formtext_small" name="add" value="&nbsp;&nbsp;Add&nbsp;&nbsp;" onClick="return setAddFile();">
		</td>
	</tr>
</form>

<!-- end attachment file -->

<tr><td colspan="2"><img src="../i/spacer.gif" width="1" height="10"></td></tr>

<!-- Post Blog -->

	<tr>
		<td width="25">&nbsp;</td>
		<td><table border="0" cellspacing="0" cellpadding="0"><tr>
		<td class="plaintext_big">

			Enter Blog text to be posted onto your personal Engineering Logbook.  Click</td>
			<td valign="bottom">
				<img src="../i/disk.gif" border="0"></td>
			<td class="plaintext_big"> on the menu bar to save.</td>
			</tr></table>
		</td>
	</tr>
	<tr><td><img src='../i/spacer.gif' height='10'/></td></tr>

<!-- add blog -->
<form name="addWeblog" action="../blog/post_addblog.jsp" method="post">
<input type="hidden" name="type" value="Personal">
<input type="hidden" name="update" value="<%=blogIdS%>">
<input type="hidden" name="backPage" value="../ep/logbook.jsp">
<input type="hidden" name="uid" value="<%=uidS%>">

	<tr>
		<td width="25">&nbsp;</td>
		<td>
		<table width="100%" border="0" cellspacing="0" cellpadding="0">
		<tr><td colspan="2" valign="top">
			<textarea name="logText"><%=bText%></textarea>
		</td></tr>
		</table>
		</td>
	</tr>

</form>

<tr><td colspan='2'><img src="../i/spacer.gif" width="1" height="15"></td></tr>

</table>

</div>
</td></tr>
<!-- End of add blog -->
<%	}	// END: if isMyLogbook %>

<!-- ************************* -->
<!-- Filter -->
<form name="Filter" action="logbook.jsp" method="post">
<input type="hidden" name="filterType" value="LogBkFilter">
<input type="hidden" name="displayNum" value="">
<input type="hidden" name="lastStart" value="">

<tr>
	<td>&nbsp;&nbsp;&nbsp;&nbsp;
	<img id="nav1" name="nav1" onClick="toggle('menu',1)" src="../i/filter_hide.gif" alt="hide" border="0">
	</td>
</tr>

<tr>
	<td>
<div id="menu1" style="display: block">
<table border="0" cellspacing="0" cellpadding="0" width='100%'>

<!-- blog type -->
<tr>
	<td width="25">&nbsp;</td>
	<td width="150" align="left" valign="top" class="plaintext_blue">Blog Type:</td>
	<td width="550">
		<table border='0' cellspacing='0' cellpadding='0'>
<%
		for (int i=0; i<blogType.length; i++)
		{
			out.print("<td class='formtext' width='130'><input type='checkbox' name='" + blogType[i] + "'");
			if (bAllType || request.getParameter(blogType[i])!=null) out.print("checked");
			//out.print(" onClick='javascript:check_task(\"" + blogType[i] + "\")'");
			out.print(">" + blogType[i] + "</td>");
		}
%>
		</table>
	</td>
</tr>

<tr><td colspan='3' width='1'><img src='../i/spacer.gif' width='1' height='5'></td></tr>

<!-- project name -->
<tr>
	<td></td>
	<td align="left" valign="top" class="plaintext_blue">Project Name:</td>
	<td>
		&nbsp;<select name="projId" class="formtext">
		<option value=''>- select project name -</option>
<%
	int [] projectObjId = pjMgr.getProjects(pstuser);
	if (projectObjId.length > 0)
	{
		PstAbstractObject [] projectObjList = pjMgr.get(pstuser, projectObjId);
		//@041906SSI
		Util.sortName(projectObjList, true);

		String pName;
		project pj;
		Date expDate;
		String expDateS = new String();
		for (int i=0; i < projectObjList.length ; i++)
		{
			// project
			pj = (project) projectObjList[i];
			pName = pj.getDisplayName();

			out.print("<option value='" + pj.getObjectId() +"' ");
			if (pj.getObjectId() == selectedProjId)
				out.print("selected");
			out.print(">" + pName + "</option>");
		}
	}
%>
		</select>
	</td>
</tr>

<tr><td colspan='3' width='1'><img src='../i/spacer.gif' width='1' height='5'></td></tr>

<!-- keywords -->
<tr>
	<td></td>
	<td class="plaintext_blue">Keyword:</td>
	<td>
		&nbsp;<input type="text" name="Keyword" class="formtext" size="60" value="<%=Util.stringToHTMLString(keywords)%>">
	</td>
</tr>

<tr><td colspan='3' width='1'><img src='../i/spacer.gif' width='1' height='15'></td></tr>

<!-- buttons -->
<tr>
	<td colspan="3" align="center">
		<input type='button' class='button_medium' value='Submit' onclick='document.Filter.submit();'>
		<input type='button' class='button_medium' value='Save Filter' onclick='saveFilter();'>
	</td>
</tr>

</table>
</div>
</td></tr>

<tr>
	<td id="adjust" height="100%"></td>
</tr>

</table>
</form>

<!-- Filter End -->

<script type="text/javascript">
// for update of log, open the editor window
if ('<%=blogIdS%>' != 'none' && !tog0)
{
	tog0 = true;
	appear('menu', 0);
	tog1 = false;
	disappear('menu', 1);
}
</script>


<!-- ***** List of Blog ***** -->

<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
<td width="25">&nbsp;</td>

<%
	String resultS = "";
	int totalNum = blogArr.length;
	int totalIdx = (int)Math.ceil((double)totalNum / MAX_DISPLAY_BLOG);
	int thisStartNum = start*MAX_DISPLAY_BLOG+1;
	int thisEndNum = thisStartNum+MAX_DISPLAY_BLOG-1;
	if (thisEndNum > totalNum) thisEndNum = totalNum;
	if (thisEndNum > 0)
		resultS = "<b>" + thisStartNum + "</b> - <b>" + thisEndNum + "</b>";
	else
		resultS = "<b>0</b>";
%>

<td>
	<table border='0' cellpadding="0" cellspacing="0" width='100%'>

<!-- ** display index for traversing -->
	<tr><td><table width='100%' border="0" cellspacing="0" cellpadding="0">
	<tr>
	<td class="blog_text">Results <%=resultS%> of <b><%=totalNum%></b> blogs found</td>
	<td class="blog_small" align='right'>
<%	if (startIdx > 0)
		out.print("<a href='javascript:at(" + (start-1) + ")'><< Prev</a>&nbsp;&nbsp;");
	int showNum = 0;
	if (totalIdx > 1)
	for (int i=startIdx; i<totalIdx; i++)
	{
		if (showNum++ > MAX_DISPLAY_IDX) break;
		if (start != i)
			out.print("<a href='javascript:at(" + i + ")'>" + (i+1) + "</a>");
		else
			out.print("<font color='red'>"+ (i+1) + "</font>");
		out.print("&nbsp;&nbsp;");
	}
	if (start < totalIdx-1)
		out.print("&nbsp;&nbsp;<a href='javascript:at(" + (start+1) + ")'>Next >></a>");
%>
	</td>
	</tr>
	</table></td>
	</tr>
<!-- ** END display index -->

	<tr><td><img src="../i/spacer.gif" height="3"></td></tr>

	<tr>
	<td bgcolor="#bb5555" height="1"><img src="../i/spacer.gif" width="100%" height="1" border="0"></td>
	</tr>
	</table>

	<table border="0" cellspacing="0" cellpadding="0" width='100%'>



<!-- list of blogs contents -->
<%
	String bgcolor="";
	boolean even = false;

	int blogId, id, idx, pTaskId=0;
	result blog;
	String type, nameStr, postDateS, uname, lname, parentIdS;
	String idS=null, projIdS=null, bugIdS=null, gotoS=null;
	String ADtypeStr = null;
	user bUser;
	Date dt;
	SimpleDateFormat df1 = new SimpleDateFormat ("MM/dd/yy (EEEEE)");
	SimpleDateFormat df2 = new SimpleDateFormat ("hh:mm a");

	count = 0;

	for (int i=start*MAX_DISPLAY_BLOG; i<totalNum && count<MAX_DISPLAY_BLOG; i++)
	{
		count++;					/// no. of blog I have processed in this round
		blog = (result)blogArr[i];
		if (blog == null) continue;
		// cannot handle archived blog at this point (future enhancement potential)
		type = (String)blog.getAttribute("Type")[0];
		if (type.endsWith(result.TYPE_ARCHIVE))
			continue;

		// do not list comments
		parentIdS = (String)blog.getAttribute("ParentID")[0];
		//if (parentIdS != null) continue;

		// check blog text
		bText = "";
		bTextObj = blog.getAttribute("Comment")[0];
		if (bTextObj != null)
			bText = new String((byte[])bTextObj, "utf-8");

		blogId = blog.getObjectId();
		dt		= (Date)blog.getAttribute("CreatedDate")[0];

		if (parentIdS == null)
			idS	= (String)blog.getAttribute("TaskID")[0];
		else
		{
			PstAbstractObject o = rMgr.get(pstuser, parentIdS);
			idS = (String)o.getAttribute("TaskID")[0];
		}

		if (type.equals(result.TYPE_BUG_BLOG))
		{
			// bug blog
			obj = bMgr.get(pstuser, idS);
			projIdS = (String)obj.getAttribute("ProjectID")[0];
			if (projIdS != null)
			{
				if (selectedProjId!=0 && selectedProjId != Integer.parseInt(projIdS))
					continue;
			}
			nameStr	= (String)obj.getAttribute("Synopsis")[0];
			bugIdS = idS;
			nameStr = "<a class='listlink' href='../bug/bug_update.jsp?bugId=" + bugIdS + "'>" + nameStr + "</a>";
			if (parentIdS == null)
				gotoS = "<a class='blog_small' href='../blog/blog_task.jsp?projId=" + projIdS + "&bugId=" + bugIdS + "#" + blogId + "'> GO TO BLOG</a>&nbsp;&nbsp;";
			else
			{
				nameStr += "<br>(Comment on Blog)";
				gotoS = "<a class='blog_small' href='../blog/blog_comment.jsp?blogId=" + parentIdS
					+ "&projId=" + projIdS + "&id=" + idS
					+ "&blogNum=" + parentIdS + "&type=Bug'> GO TO COMMENT</a>&nbsp;&nbsp;";
			}
		}
		else if (type.equals(result.TYPE_TASK_BLOG))
		{
			// task blog
			obj = tkMgr.get(pstuser, idS);
			projIdS = (String)obj.getAttribute("ProjectID")[0];
			if (selectedProjId!=0 && selectedProjId != Integer.parseInt(projIdS))
				continue;
			ids = ptkMgr.findId(pstuser, "TaskID='" + idS +"' && Status !='Deprecated'");
			if (ids.length <= 0) continue;
			Arrays.sort(ids);
			pTaskId = ids[ids.length-1];
			planTask ptk = (planTask)ptkMgr.get(pstuser, pTaskId);
			nameStr = TaskInfo.getTaskStack(pstuser, ptk);
			idx = nameStr.lastIndexOf(">>");
			if (idx > 0)
				nameStr = nameStr.substring(0, idx+2) + "<b>" + nameStr.substring(idx+2) + "</b>";
			else
				nameStr = "<b>" + nameStr + "</b>";
			nameStr = "<a class='listlink' href='../project/task_update.jsp?projId="
					+projIdS+ "&pTaskId=" + ptk.getObjectId() + "'>" + nameStr + "</a>";

			bugIdS = "";
			if (parentIdS == null)
				gotoS = "<a class='blog_small' href='../blog/blog_task.jsp?projId=" + projIdS + "&planTaskId=" + pTaskId + "#" + blogId + "'> GO TO BLOG</a>&nbsp;&nbsp;";
			else
			{
				nameStr += "<br>(Comment on Blog)";
				gotoS = "<a class='blog_small' href='../blog/blog_comment.jsp?blogId=" + parentIdS
					+ "&projId=" + projIdS + "&id=" + pTaskId
					+ "&blogNum=" + parentIdS + "&type=Task'> GO TO COMMENT</a>&nbsp;&nbsp;";
			}
		}
		else if (type.equals(result.TYPE_ACTN_BLOG))
		{
			// action/decision blog
			obj = aMgr.get(pstuser, idS);
			projIdS = (String)obj.getAttribute("ProjectID")[0];
			if (projIdS != null)
			{
				if (selectedProjId!=0 && selectedProjId != Integer.parseInt(projIdS))
					continue;
			}
			nameStr	= (String)obj.getAttribute("Subject")[0];
			ADtypeStr = (String)obj.getAttribute("Type")[0];

			// use view meeting or project action/decision
			idS = (String)obj.getAttribute("MeetingID")[0];
			if (idS != null)
			{
				nameStr = "<a class='listlink' href='../meeting/mtg_view.jsp?mid=" + idS
					+ "&aid=" + obj.getObjectId()+ "#action'>" + nameStr + "</a>";
			}
			else
			{
				nameStr = "<a class='listlink' href='../project/proj_action.jsp?projId=" + projIdS
					+ "&aid=" +obj.getObjectId()+ "'>" + nameStr + "</a>";
			}
			if (parentIdS == null)
				gotoS = "<a class='blog_small' href='../blog/blog_task.jsp?projId=" + projIdS + "&aId=" + obj.getObjectId() + "#" + blogId + "'> GO TO BLOG</a>&nbsp;&nbsp;";
			else
			{
				nameStr += "<br>(Comment on Blog)";
				gotoS = "<a class='blog_small' href='../blog/blog_comment.jsp?blogId=" + parentIdS
					+ "&projId=" + projIdS + "&id=" + obj.getObjectId()
					+ "&blogNum=" + parentIdS + "&type=Action'> GO TO COMMENT</a>&nbsp;&nbsp;";
			}
		}
		else
		{
			// personal blog
			nameStr = "Engineering Logbook Entry";
			idS = "-";
			bugIdS = projIdS = "";
			gotoS = "<a class='blog_small' href='logbook.jsp?update=" + blogId + "'> EDIT</a>&nbsp;&nbsp;";
		}

		// check keywords
		if (matchKey.length() > 0)
		{
			String plainText = bText.replaceAll("<\\S[^>]*>", "");
			m .reset(plainText);
			if (!m.find()) continue;
		}

		// partition line on top
		out.print("<tr><td width='1'><img src='../i/spacer.gif' width='1' height='5'></td></tr>");


		// *** top portion table
		out.print("<tr><td valign='top'>");
		out.print("<table border='0' width='100%' cellspacing='0' cellpadding='0'><tr>");

		/////// top left table contain Date and Blog Text
		out.print("<td width='70%' valign='top'>");
		out.print("<table width='100%' border='0' cellspacing='0' cellpadding='0'>");

		// posted date
		out.print("<tr><td width='1'><img src='../i/spacer.gif' width='1' height='15'></td></tr>");
		out.print("<tr><td class='blog_date' valign='top' align='left'>");
		if (dt != null)
			out.print(df1.format(dt));
		else
			out.print("-");
		out.println("</td></tr>");
		out.print("<tr><td width='1'><img src='../i/spacer.gif' width='1' height='10'></td></tr>");

		// display blog
		bUser = (user)uMgr.get(pstuser, Integer.parseInt((String)blog.getAttribute("Creator")[0]));
		lname = (String)bUser.getAttribute("LastName")[0];
		uname =  bUser.getAttribute("FirstName")[0] + " " + (lname==null?"":lname);
		out.print("<tr><td class='blog_text'>");
		out.print(bText);
		out.print("<p></p></td></tr>");

		// posted by
		out.print("<tr><td valign='bottom'>");
		out.print("<table border='0' width='100%' cellspacing='0' cellpadding='0'>");
		out.print("<tr><td class='blog_by'>POSTED BY " + uname.toUpperCase() + " | ");
		out.print("<font color='#dd8833'>" + df2.format(dt) + "</font></td>");

		// goto blog
		out.print("<td align='right' valign='bottom'>");
		out.print(gotoS);
		out.print("</td></tr></table></td></tr>");

		out.println("</table></td>");
		///// End top left table

		///// middle partition line
		out.print("<td width='5'><img src='../i/spacer.gif' width='5'></td>");
		out.print("<td width='1' class='headlinerule'>");
		out.print("<table border='0' cellspacing='0' cellpadding='0' class='headlinerule'>");
		out.print("<tr><td><img src='../i/spacer.gif' height='100%' width='1' alt=' ' /></td></tr>");
		out.print("</table></td>");

		///// top right table contain context and path
		out.print("<td width='10'>&nbsp;</td>");
		out.print("<td valign='top' width='250'>");
		out.print("<table width='100%' border='0' cellspacing='0' cellpadding='0'>");
		out.print("<tr><td width='1'><img src='../i/spacer.gif' width='1' height='15'></td></tr>");

		if (!type.equals(result.TYPE_ENGR_BLOG))
		{
			out.print("<tr><td width='55' class='blog_small' valign='top'>Project:</td>");
			if (projIdS != null && projIdS!= "")
			{
				// display project name and link
				projName = ((project)pjMgr.get(pstuser, Integer.parseInt(projIdS))).getDisplayName();
				projName = "<a class='listlink' href='../project/proj_plan.jsp?projId="
						+ projIdS + "'>" + projName + "</a>";	// use projId
				out.print("<td valign='top'>" + projName + "</td></tr>");
			}
			else
			{
				out.print("<td class='plaintext_grey' valign='top'>not specified</td></tr>");
			}

			// display task name and link
			out.print("<tr><td width='55' class='blog_small' valign='top'>");
			if (type.equals(result.TYPE_ACTN_BLOG))
				out.print(ADtypeStr);
			else
				out.print(type);
			out.print(":</td><td class='plaintext_grey' valign='top'>" + nameStr + "</td></tr>");
		}
		else
		{
			out.print("<tr><td class='blog_small' valign='top'>" + nameStr + "</td></tr>");
		}
		out.print("</table></td>");
		///// End top right table

		out.print("</tr></table></td></tr>");
		// *** close the top portion table


		// bottom portion

		// partition at the end
		out.print("<tr><td width='5'><img src='../i/spacer.gif' width='5'></td></tr>");
		out.print("<tr><td bgcolor='#bbbbbb' height='1'><img src='../i/spacer.gif' width='100%' height='1' border='0'></td></tr>");
	}
%>

	<tr><td><img src="../i/spacer.gif" height="3"></td></tr>

<!-- ** display index for traversing -->
	<tr><td class="blog_small" align='right'>
<%	if (startIdx > 0)
		out.print("<a href='javascript:at(" + (start-1) + ")'><< Prev</a>&nbsp;&nbsp;");
	showNum = 0;
	if (totalIdx > 1)
	for (int i=startIdx; i<totalIdx; i++)
	{
		if (showNum++ > MAX_DISPLAY_IDX) break;
		if (start != i)
			out.print("<a href='javascript:at(" + i + ")'>" + (i+1) + "</a>");
		else
			out.print("<font color='red'>"+ (i+1) + "</font>");
		out.print("&nbsp;&nbsp;");
	}
	if (start < totalIdx-1)
		out.print("&nbsp;&nbsp;<a href='javascript:at(" + (start+1) + ")'>Next >></a>");
%>
	</td></tr>
<!-- ** END display index -->

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
