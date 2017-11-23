<%
////////////////////////////////////////////////////
//	Copyright (c) 2004-2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	adduser.jsp
//	Author:	ECC
//	Date:	04/22/04
//	Description:
//		Allow admin to add a user.
//	Modification:
//
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>

<%

	PstUserAbstractObject gUser = (PstUserAbstractObject)session.getAttribute("pstuser");
	boolean isLogin = false;
	boolean isAdmin = false;

	if (gUser == null)
	{
		gUser = (PstUserAbstractObject) PstGuest.getInstance();
	}
	else
	{
		isLogin = true;

		// check admin
		int iRole = ((Integer)session.getAttribute("role")).intValue();
		if ( (iRole & user.iROLE_ADMIN) > 0 )
			isAdmin = true;
	}

	String title = "Register New User";

	String msg = request.getParameter("msg");
	if (msg == null) msg = "";

	String fName = "";
	String lName = "";
	String eMail = "";
	String deptName = "";
	int mgrId = 0;
	int [] selectedPjs = new int[0];
	String s;

%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="../init.jsp" flush="true" />
<jsp:include page="../forms.jsp" flush="true"/>

<script language="JavaScript">
<!--
function fixElement(e, msg)
{
	alert(msg);
	e.focus();
}

function validation()
{
	if (document.AddUser.Email.value =='')
	{
		fixElement(document.AddUser.Email,
			"Please make sure that the EMAIL field was properly completed.");
		return false;
	}
	if ((document.AddUser.Email.value.indexOf('@') == -1) ||
		(document.AddUser.Email.value.indexOf('.') == -1))
	{
		fixElement(document.AddUser.Email,
			"Please make sure to enter a valid EMAIL address (e.g. xxx@hotmail.com).");
		return false;
	}
	if (document.AddUser.FirstName.value =="")
	{
		fixElement(document.AddUser.FirstName,
			"Please make sure that the FIRST NAME field was properly completed.");
		return false;
	}
	if (document.AddUser.LastName.value =='')
	{
		fixElement(document.AddUser.LastName,
			"Please make sure that the LAST NAME field was properly completed.");
		return false;
	}

	getall(AddUser.SelectedProjects);
	return;
}

//-->
</script>

<title>
	Add New User
</title>

</head>

<body text="#000000" leftmargin="10" topmargin="10" marginwidth="0" marginheight="0">

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="715" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<b class="head">

	<%=title%>

	</b><br><br>
	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="/i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- CONTENT -->
<table border="0">

	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="plaintext"><font color="#aa0000">
		<%=msg%></font></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="instruction">
		<br>
		Please enter the information of the new user.
		<p>Note that fields marked with an * are required.<br><br></td>
	</tr>

<!-- division name -->

<form name="AddUser" method="post" action="post_adduser.jsp">

	<tr>
		<td width="15">&nbsp;</td>
		<td class="formtext_blue" width="180">&nbsp;&nbsp;&nbsp;Division Name: </td>
		<td>
			<input type="text" name="DepartmentName" value="<%=deptName%>" size="35">
		</td>
	</tr>


<!-- ********************** projects ********************** -->
<%
	// get all children towns
	projectManager pjMgr = projectManager.getInstance();
	PstAbstractObject [] projectList = null;
	int ids [] = pjMgr.findId(gUser, "om_acctname='%'");
	projectList = pjMgr.get(gUser, ids);

	Arrays.sort(projectList, new Comparator() {
		public int compare(Object o1, Object o2)
		  {
		   project t1 = (project) o1;
		   project t2 = (project) o2;

		   try
		   {
			   String name1 = t1.getObjectName();
			   String name2 = t2.getObjectName();
			   return name1.compareToIgnoreCase(name2);
		   }
		   catch(Exception e)
		   {
			   throw new ClassCastException("Could not compare.");
		   }
		  }
	});
%>

<tr>
		<td width="15">&nbsp;</td>
		<td class="formtext_blue">&nbsp;&nbsp;&nbsp;Project:</td>
		<td>
		<table border="0" cellspacing="0" cellpadding="0">
		<tr>
			<td>
			<select name="AllProjects" multiple size="5">
<%
	if (projectList != null && projectList.length > 0)
	{
		boolean found;
		for (int i=0; i < projectList.length; i++)
		{
			found = false;
			for (int j=0; j<selectedPjs.length; j++)
			{
				if (projectList[i].getObjectId() == selectedPjs[j])
				{
					found = true;
					break;
				}
			}
			if (found) continue;
%>
			<option value="<%=projectList[i].getObjectId() %>"><%=projectList[i].getObjectName()%></option>
<%
		}
	}

%>
			</select>
			</td>
			<td align="center" valign="middle" class="formtext">
				<input type="button" class="button" name="add" value="&nbsp;&nbsp;&nbsp;Add &gt;&gt;&nbsp;&nbsp;" onClick="swapdata(this.form.AllProjects,this.form.SelectedProjects)">
			<br><input type="button" class="button" name="remove" value="<< Remove" onClick="swapdata(this.form.SelectedProjects,this.form.AllProjects)">
			</td>
<!-- child towns selected -->
			<td>
				<select name="SelectedProjects" multiple size="5">
<%
for (int i=0; i<selectedPjs.length; i++)
{
		project pj = (project)pjMgr.get(gUser, selectedPjs[i]);
		out.print("<option value='" + selectedPjs[i] + "'>" + pj.getObjectName() + "</option>");
}
%>
				</select>
			</td>
		</tr>
		</table>
</td>
</tr>
<!-- end of children town -->



	<tr>
		<td width="15">&nbsp;</td>
		<td class="formtext_blue"><font color="#000000">*</font> Email: </td>
		<td>
			<input type="text" name="Email" value="<%=eMail%>" size="35">
		</td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="formtext_blue"><font color="#000000">*</font> First Name: </td>
		<td>
		<input type="text" name="FirstName" value="<%=fName%>" size="20">
		</td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="formtext_blue"><font color="#000000">*</font> Last Name: </td>
		<td>
			<input type="text" name="LastName" value="<%=lName%>" size="20">
		</td>
	</tr>

<%
	if (isAdmin)
	{%>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="formtext_blue">&nbsp;&nbsp;&nbsp;Username: </td>
		<td>
			<input type="text" name="UserName" size="20">
		</td>
	</tr>
<%	}%>

	<tr>
		<td width="15">&nbsp;</td>
		<td class="formtext_blue">&nbsp;&nbsp;&nbsp;Manager: </td>
		<td>
		<select class="formtext" name="Manager">
		<option value="">- select Manager -
<%
	userManager uMgr = userManager.getInstance();
	int allEmpIds[] = uMgr.findId(gUser, "om_acctname='%'");
	PstAbstractObject [] allMember = uMgr.get(gUser, allEmpIds);

	// sort the user list for owner assignment
	Arrays.sort(allMember, new Comparator() {
			public int compare(Object o1, Object o2)
			  {
			   user emp1 = (user) o1;
			   user emp2 = (user) o2;

			   try
			   {
					String eName1 = emp1.getAttribute("FirstName")[0] + " " +
							emp1.getAttribute("LastName")[0];
					String eName2 = emp2.getAttribute("FirstName")[0] + " " +
							emp1.getAttribute("LastName")[0];

					   return eName1.compareToIgnoreCase(eName2);
			   }
			   catch(Exception e)
			   {
				   throw new ClassCastException("Could not compare.");
			   }
			  }
	});
	for (int i=0; i<allMember.length; i++)
	{
		if (allMember[i].getAttribute("FirstName")[0] == null)
			allMember[i] = null;
	}


	//PstAbstractObject [] allMember = ((user)gUser).getAllUsers();
	user u;
	int id;

	for(int i=0; i < allMember.length; i++)
	{
		if (allMember[i] == null) continue;
		u = (user)allMember[i];
		id = u.getObjectId();
		String firstEmpName = (String)u.getAttribute("FirstName")[0];
		if (firstEmpName == null) continue;
		String lastEmpName = (String)u.getAttribute("LastName")[0];

		out.print("<option value='" + id + "'");
		if (id == mgrId) out.print(" selected");
		out.println(">" + firstEmpName + " " + lastEmpName + "</option>");
	}
%>
		</select>

<%	if (isAdmin) {%>
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan='2' class="formtext_blue">
			&nbsp;&nbsp;<input type="checkbox" name="SendEmail" checked>Send Email notification to new user
		</td>
	</tr>
<%	}

	String backBut = "javascript:location='../ep/ep_home.jsp';";
	if (isAdmin)
		backBut = "javascript:location='admin.jsp';";
%>

<!-- Submit Button -->
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan=2 class="10ptype" align="center"><br>
			<input type="Button" value="   Cancel   " onClick="<%=backBut%>">&nbsp;
			<input type="Submit" name="Submit" value="  Submit  " onclick="return validation();">&nbsp;
<%	if (isLogin) {%>
			<input type="Submit" name="AddMore" value="Add more user" onclick="return validation();">
<%	}%>
		</td>
	</tr>

</form>
</table>


<tr><td>&nbsp;</td><tr>


<!-- BEGIN FOOTER TABLE -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

