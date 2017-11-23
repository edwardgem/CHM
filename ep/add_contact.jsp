<%
//
//	Copyright (c) 2006 EGI Technologies.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
// $Header$
//
//	File:	$RCSfile$
//	Author:	Allen G Quan (AGQ)
//	Date:	$Date$
//  Description:
//      Interacts w/ Live Meeting to handle invite input from participants
//
//	Modification:
//			@AGQ091306	Added support to individually invite guests
/////////////////////////////////////////////////////////////////////
%>
<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1"%>
    
<%@ page import = "java.util.ArrayList" %>
<%@ page import = "java.util.HashMap" %>

<%@ page import = "util.PrmLog" %>
<%@ page import = "util.*" %>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.PstGuest" %>
<%@ page import = "oct.pst.PstAbstractObject" %>

<%@ page import = "org.apache.log4j.Logger" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />
   
<%	// Initialize java variables
	userManager	uMgr = userManager.getInstance();
	
	PstAbstractObject [] onlineParticipants;
	user curUser = (user) pstuser;
	boolean isAdmin = false;
	int uid = curUser.getObjectId();

	Logger l = PrmLog.getLog();
	
	// Find current user's role
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if (iRole > 0)
	{
		if ((iRole & user.iROLE_ADMIN) > 0)
			isAdmin = true;
	}
	
	String fullName = curUser.getFullName();
	String personalMsg = "Hi,\n\nThis is " + fullName + ", come and join me at MeetWE and my private circles, it's fun.";
	
	// Verifications	
	if ((pstuser instanceof PstGuest))
	{		
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	
	String backPage = "../ep/add_contact.jsp";
	
	// to check if session is OMF or PRM
	boolean isCRAPP = false;
	boolean isOMFAPP = false;
	String app = (String)session.getAttribute("app");
	if (app.equals("OMF"))
		isOMFAPP = true;
	if (app.equals("CR"))
		isCRAPP = true;
	
	// set up labels for CR/OMF
	String label1, label2;
	if (isOMFAPP) {label1="Circles & Friends"; label2="Add New Friends";}
	else {label1="Contacts & User Lists"; label2="Add New Contacts";}
	
	// The type of response
	// Case 1: No results found and search text was not an email
	// Case 2: No results found and search text was an email
	// Case 3: Found results
	// Case 4: Error or done
	String type = request.getParameter("type"); 
	if (type == null) type = "";
	String errorMessage = request.getParameter("errorMessage");
	if (errorMessage == null) errorMessage = "";
	
	String subCat = "SearchFriend";
	if (type.equals("case2"))
		subCat = "InviteFriend";
	
	// add link from manage circle to allow inviting friends to circle
    String s;
	int selectedTownId = 0;
	s = request.getParameter("tid");	// could be null
	if (s != null)
		selectedTownId = Integer.parseInt(s);
	
	String search = request.getParameter("search");
	if (search == null) search = "";
	// @AGQ091306
	String [] emailArr = request.getParameterValues("email");
	if (emailArr == null) {
		emailArr = request.getParameterValues("guests");
	}
	StringBuffer email = new StringBuffer();
	
	if (emailArr != null) {
		for (int i=0; i<emailArr.length; i++) {
			email.append(emailArr[i]);
			if (i != emailArr.length-1) 
				email.append(", ");
		}
	}
	else
		email.append(search);
	// @AGQ091306
	String action = request.getParameter("action");
	if (action == null) action = "search";
	
	String [] allId = request.getParameterValues("id");
	if (allId == null) allId = new String[0];
	int [] allIdInt = new int[allId.length];
	for (int i=0; i<allIdInt.length; i++) {
		try {
			allIdInt[i] = Integer.parseInt(allId[i]);
		} catch (NumberFormatException e) {
			allIdInt[i] = -1;
			l.warn(e.getMessage());
		}
	}
	
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
<title><%=app%> Add Contact</title>
<jsp:include page="../init.jsp" flush="true"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<style type="text/css">
.contactHeader {
	background-color: blue; 
	color: white; 
	font-size: 14px; 
	font-weight: bold;
	text-align: center;
}
</style>

<script type="text/javascript">
<!--

window.onload = function ()
{
	var search = document.getElementById("search")
	if (search)
		search.focus();

	
	var err = "<%=errorMessage%>";
	if ('<%=type%>'=="case2" && '<%=action%>'!="invite")
		document.form.message.focus();
	else if ('<%=type%>'=="case2" && '<%=action%>'=="invite")
		document.form.email.focus();
	else if ('<%=type%>'=="case4" && err.indexOf("Done")!=-1)
	{
		document.form.search.value = '';
		document.form.search.focus();
	}
}

function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

function validate() {
	// Check to make sure the text field contains only valid chars
	var search = document.getElementById("search");
	if (search) {
		var searchValue = search.value;
		if (searchValue == "")
			return false;
						
		for (i=0;i<searchValue.length;i++) {
			char = searchValue.charAt(i);
			if (char == '\'' || char == '\\' ) {
				fixElement(search,
					"Search cannot contain these characters: \' \\ ");
				return false;
			}
		}	
	}

	var form = document.getElementsByName("form");
	if (form.length > 0) {
		form[0].submit();
	}
}

function submitMessage() {
	// @AGQ091206
	var email = document.getElementsByName("email");
	if (email.length > 0) {
		var guestEmail = email[0].value;
		guestEmail = guestEmail.replace(new RegExp("[,;]", "g"), " ");
		var guestEmailArr = guestEmail.split(" ");
		for (var i=0; i < guestEmailArr.length; i++) {
			if (trim(guestEmailArr[i]).length > 0) {
				if (!checkMail(guestEmailArr[i])) {
					alert("'" + guestEmailArr[i] + "' is not a valid email address, \nplease correct the error and submit again.");
					return false;
				}
			}
		}
	}
	
	var action = document.getElementsByName("action");
	if (action.length > 0) {
<% 	if (action.equals("invite")) { %>
		var actionName = "<%=action%>";
<%	} 
	else { %>
		var actionName = "submitMail";
<%	} %>
		action[0].value = actionName;
	}
		
	var form = document.getElementsByName("form");
	if (form.length > 0) {
		form[0].onsubmit = "return true";
		form[0].submit();
	}
}

function addUser(userId) {
	var addId = document.getElementsByName("addId");
	if (addId.length > 0) {
		addId[0].value = userId;
	}

	var action = document.getElementsByName("action");
	if (action.length > 0) {
		action[0].value = "addUser";
	}

	var form = document.getElementsByName("form");
	if (form.length > 0) {
		form[0].onsubmit = "return true";
		form[0].submit();
	}	
}

function remove() {
	var email = document.getElementsByName("email");
	var message = document.getElementsByName("message");
	// @AGQ091306
	if (email.length > 0)
		email[0].value = "";
	if (message.length > 0) {
		message[0].value = "";
		message[0].innerHTML = ""; // Just in case
	}
}
// @AGQ091306
function trim(str) {
	if (str != null)
		return str.replace(/^\s*|\s*$/g,"");
	else
		return null;
}

function checkMail(str)
{
	var filter  = /^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/;
	return filter.test(str);
}

function onEnterSubmit(evt) {
	var code = evt.keyCode? evt.keyCode : evt.charCode;
	if (code == 13)
		return submitMessage();
}

function onEnterSubmitSearch(evt) {
	var code = evt.keyCode? evt.keyCode : evt.charCode;
	if (code == 13)
		return validate();
}

function onEnterBlock(evt) {
	var code = evt.keyCode? evt.keyCode : evt.charCode;
	if (code == 13)
		return false;
}
//-->
</script>

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
<table width='100%' border="0" cellspacing="0" cellpadding="0">
  <tr align="left" valign="top">
    <td>
      <table width="90%" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td>
            <table width="100%" border="0" cellspacing="0" cellpadding="0">
              <tr>
                <td width="26" height="28"><a name="top">&nbsp;</a></td>
                <td height="28" align="left" valign="bottom" class="head">
				Invite Friends to My Circle
				 </td>
              </tr>
            </table>
          </td>
        </tr>
	  </table>
	        
<table width='90%' border='0' cellspacing='0' cellpadding='0'>
			<tr>
				<td>
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Network" />
				<jsp:param name="subCat" value="<%=subCat%>" />
				<jsp:param name="role" value="<%=iRole%>" />
			</jsp:include>
<!-- End of Navigation Menu -->
				</td>
	        </tr>
		<tr>
		<td><table><tr><td width="18"></td><td>

<!-- start table -->

<table cellpadding="0" cellspacing="0" border="0" width="700">
   <tr><td>&nbsp;</td></tr>
<%	if (!action.equals("invite")) { %>     
   <tr>
      <td class="formtext">
         Enter part of the <b>Email</b>, <b>MeetWE username</b>, <b>Skype name</b> or <b>First name</b> or <b>Last name</b> of 
         the person you wish to search and add to your friend's list:
      </td>
   </tr>
   <tr><td>&nbsp;</td></tr>
<%	} %>     
   <tr>
      <td>
      <form name="form" action="post_add_contact.jsp" method="get" enctype="application/x-www-form-urlencoded">
      <input type="hidden" name="action" value="<%=action %>">
         <table cellpadding="0" cellspacing="0" border="0">
<%	// @AGQ091306
	if (!action.equals("invite")) { %>              
            <tr>
               <td width="100"><input type="text" id="search" name="search" value="<%=search %>" size="50" onkeydown="return onEnterSubmitSearch(event);"></td>
               <td width="10">&nbsp;</td>
               <td align="left" width="300"><input type="button" value=" Search " onclick="return validate();"></td>
            </tr>
            <tr><td colspan="3">&nbsp;</td></tr>
<%	} 
	// @AGQ091306 
	// @AGQ103106 Display message when it is a searching type
	if (type.equals("case4") || (type.equals("case3") && errorMessage.length() > 0)) {
%>            
            <!-- Case 4 -->
            <tr>
               <td colspan="3" class="formtext" style="color:#00bb00">
                  <%=errorMessage %>
               </td>
            </tr>
            <tr><td colspan="3">&nbsp;</td></tr>
            <!-- Case 4 end -->
<%	} 
	if (type.equals("case1")) {
%>                        
            <!-- Case 1 -->
            <tr>
               <td colspan="3" class="formtext" style="color: red">
                  <b><%=search %></b> cannot be found in MeetWE.  Please try to search 
                  again using Email address.
               </td>
            </tr>
            <tr><td colspan="3">&nbsp;</td></tr>
            <!-- Case 1 End -->
<%
	}
	// @AGQ091306
	else if (type.equals("case2") || action.equals("invite")) {
%>            
            <!-- Case 2 -->
<%	// @AGQ091306
	if (!action.equals("invite")) { %>            
            <tr>
               <td colspan="3" class="formtext" style="color:#00bb00">
                  <b><%=search %></b> is not yet a MeetWE member.  If you would like to
                  send a MeetWE invitation email to this contact, please 
                  provide the contact's email address and click the submit button.
               </td>
            </tr>
            <tr><td colspan="3">&nbsp;</td></tr>
<%	} %>
            <!-- Email New User -->
            <tr>
               <td colspan="3">
                  <table cellpadding="0" cellspacing="0" border="0">
<%-- @AGQ091306 --%>                  
                     <tr>
                        <td class="formtext" valign='top'>*Invite Guests:&nbsp;&nbsp;</td>
                        <td colspan="4" class="formtext"><textarea rows='4' cols="45" value="<%=email.toString() %>" name="email" onkeydown="return onEnterBlock(event);"></textarea></td>
                     </tr>
                     <tr>
                        <td>&nbsp;</td>
                        <td colspan="4">
                           <span class="footnotes">Enter email addresses separated by commas (e.g. aaa@z.com, bbb@z.com)</span>
                        </td>
                     </tr>
                     
					 <tr><td colspan="5">&nbsp;</td></tr>
                     <tr><td colspan='5' class="plaintext_blue">
                     		Invite the guests to join the following circles <span class='plaintext_small'>(optional)</span>:
					 <tr><td><img src='../i/spacer.gif' height='5' /></td></tr>
<%
	int id;
	int [] ids = null;
	Object [] oA = pstuser.getAttribute("Towns");
	if (oA[0] != null)
	{
		// get the town (circle) ids
		ids = new int[oA.length];
		for (int i=0; i<oA.length; i++)
			ids[i] = ((Integer)oA[i]).intValue();
	}
	PstAbstractObject [] cirArr = null;
	if (ids != null)
	{
		cirArr = townManager.getInstance().get(pstuser, ids);
		Util.sortString(cirArr, "Name", true);
	}

	if (cirArr != null)
	for (int i=0; i<cirArr.length; i++)
	{
		id = cirArr[i].getObjectId();
		s = (String)cirArr[i].getAttribute("Name")[0];
		out.print("<tr><td colspan='5'><table cellpadding='0' cellspacing='0'><tr><td valign='middle'>&nbsp;&nbsp;");
		out.print("<input type='checkbox' name='circle_" + id + "'");
		if (id == selectedTownId)
			out.print(" checked");
		out.print("></td><td class='plaintext'>&nbsp;" + s);
		out.print("</td></tr></table></td></tr>");
	}
%>
                     </td></tr>
                     
                     <tr><td colspan="5">&nbsp;</td></tr>
                     <tr>
                        <td colspan="5" class="formtext">
                           You may add an optional personal message to the 
                           invitation:
                        </td>
                     </tr>
					 <tr><td><img src='../i/spacer.gif' height='5' /></td></tr>
                     <tr>
                        <td colspan="5">
                           <textarea name="message" cols="58" rows="5"><%=personalMsg%></textarea>
                        </td>
                     </tr>
                     <tr><td colspan="5">&nbsp;</td></tr>
                     <tr>
                        <td colspan="5" align="center">
                           <input type="button" value=" Cancel " onclick="remove()">
                           &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                           <input type="button" value=" Submit " onclick="return submitMessage();">
                        </td>
                     </tr>
                     <tr><td colspan="5">&nbsp;</td></tr>
                  </table>
               </td>
            </tr>
            <!-- Case 2 End -->
<%
	}
	else if (type.equals("case3")) {
%>            
            <!-- Case 3 -->
<%
	PstAbstractObject [] pstArr = uMgr.get(curUser, allIdInt);
	// TODO: Sort user by some kind of order...
	// TODO: Remove already added users
	Object [] objArr = curUser.getAttribute(user.TEAMMEMBERS);
	HashMap hm = new HashMap();
	for (int i=0; i<objArr.length; i++) {
		hm.put(objArr[i].toString(), null);
	}
	
	user u = null;
	int length = pstArr.length;
	Util.sortUserArray(pstArr, true); // Sort by full name
	StringBuffer oldBuf = new StringBuffer();
	for (int i=0; i<pstArr.length; i++) {
		u = (user) pstArr[i];
		int curUid = u.getObjectId();
		String curUidS = String.valueOf(curUid);
		if (hm.containsKey(curUidS)) {
			// found the user in my contact list
			if (oldBuf.length()>0) oldBuf.append("</br>");
			oldBuf.append("&nbsp;&nbsp;<a class='listlink' href='ep1.jsp?uid=" + curUid + "'>" + pstArr[i].getObjectName() + "</a>");
			oldBuf.append(" - " + ((user)pstArr[i]).getFullName());
			length--;
			pstArr[i] = null;
		}
	}
	if (oldBuf.length() > 0)
	{
		out.print("<tr><td colspan='3' class='formtext'>");
		out.print("<b>Matched users already in your friend's list:</b></td></tr>");
		out.print("<tr><td colspan='3' class='formtext' align='left'>");
		out.print(oldBuf.toString());
		out.print("</td></tr>");
		out.print("<tr><td colspan='3'><img src='../i/spacer.gif' height='15'></td></tr>");
	}
%>               
            <tr>
               <td colspan="3" class="formtext"><b><%=length %> NEW contact(s) found:</b></td>
            </tr>
            <tr>
               <td colspan="4">
               <input type="hidden" name="addId" value="">
<%
	String [] label = {"Full Name", "MeetWE Name", "Skype Name", "Add"};
	int [] labelLength = { 150, 150, 150, 40 };
	out.println(Util.showLabel(label, labelLength, true));
%>  
<%
	boolean isEven = true;
	String bgGrey = "style='background-color: #eeeeee'";
	String empty = "";
	for (int i=0; i<pstArr.length; i++) {
		if (pstArr[i] != null) {
			u = (user) pstArr[i];
			int curUid = u.getObjectId();
			fullName = u.getFullName();
			String screenName = u.getObjectName();
			String skypeName = (String) u.getAttribute(user.SKYPENAME)[0];
			if (screenName == null) screenName = "";
			if (skypeName == null) skypeName = "";
			
			out.println	("<tr>");
			out.print	("<td " + ((isEven)?bgGrey:empty) + "></td>");
			out.println	("   <td " + ((isEven)?bgGrey:empty) + ">"
					+ "<a class='listlink' href='ep1.jsp?uid=" + curUid + "'>" +fullName+"</a></td>");
			out.print	("<td></td>");
			out.print	("<td " + ((isEven)?bgGrey:empty) + "></td>");
			out.println	("   <td class='formtext' " + ((isEven)?bgGrey:empty) + ">"+screenName+"</td>");
			out.print	("<td></td>");
			out.print	("<td " + ((isEven)?bgGrey:empty) + "></td>");
			out.println	("   <td class='formtext' " + ((isEven)?bgGrey:empty) + ">"+skypeName+"</td>");
			out.print	("<td></td>");
			out.print	("<td " + ((isEven)?bgGrey:empty) + "></td>");
			out.println	("   <td class='formtext' " + ((isEven)?bgGrey:empty) + "><input type='button' value=' Add ' onclick='addUser("+curUid+");'></td>");
			out.println	("</tr>");
			isEven = (!isEven);
		}
	}
%>
                  </table>
               </td>
            </tr>
            <!-- Case 3 end -->
<%	} %>
    
         </table>
      </form>
      </td>
   </tr>
</table>

<!-- end table -->
</td></tr>
</table>
</td>
</tr>
<tr>
	<td valign="bottom">
		<jsp:include page="../foot.jsp" flush="true"/>
	</td>
</tr>
</table>
</td>
</tr>
</table>
</td>
</tr>
</table>

</body>
</html>