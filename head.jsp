<%@ page import = "util.*" %>
<%
	String NODE = Prm.getPrmHost();
	String prodName = Prm.getApp();
	String logoFile = null;
	if (!Prm.isMeetWE())
		logoFile = (String)session.getAttribute("comPicFile");
	if (logoFile == null) logoFile = "../i/logo.gif";
	else logoFile = "../file/memberPic/" + logoFile;

	if (Prm.isCR())
		prodName = "Central Repository";
	else if (Prm.isMeetWE())
		prodName = "Open Meeting Facilitator";
	else if (Prm.isPRM())
		prodName = "Collaborative Hospital Management";
	else
		prodName = "Central Repository - OMF";
%>

<script language="JavaScript">
<!--
function check(val)
{
	var url = parent.parent.document.URL;
	var bInProj = false;
	if (url.indexOf("proj_plan.jsp")!=-1 || url.indexOf("cr.jsp")!=-1) {
		searchForm.scope.value = "<%=session.getAttribute("projId")%>";
		bInProj = true;
	}
	if (val == 'Search') {
		if (bInProj)
			searchForm.query.value = "in project: ";
		else
			searchForm.query.value = '';
	}
	else if (trim(val)=='' || trim(val)=='in project:') {
		searchForm.query.value = 'Search';
	}
	setCaretToEnd(searchForm.query);
}

// need the followings to make IE cursor goes to end
function setSelectionRange(input, selectionStart, selectionEnd)
{
	if (input.setSelectionRange) {
		input.focus();
		input.setSelectionRange(selectionStart, selectionEnd);
	}
	else if (input.createTextRange) {
		var range = input.createTextRange();
		range.collapse(true);
		range.moveEnd('character', selectionEnd);
		range.moveStart('character', selectionStart);
		range.select();
	}
}
function setCaretToEnd (input)
{
	setSelectionRange(input, input.value.length, input.value.length);
}

//-->
</script>

<table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td colspan='2' align="left">
		<table width="90%" border="0" cellspacing="0" cellpadding="0">
		<tr><td><img src='../i/spacer.gif' height='10'></td></tr>
		<tr>
  			<td><img src='../i/spacer.gif' width='5'></td>
  			<td><table cellspacing='0' cellpadding='0'><tr>
				<td><a href='<%=NODE%>/index.jsp'><img src='<%=logoFile%>' height='70' border='0'></a></td>
				<td valign='top'><img src='../i/spacer.gif' height='35' width='1'/><font size="2px" face="Verdana, Arial, Helvetica, sans-serif" color="#003382">
						<b><%=prodName%></b></font></td>
			</tr></table></td>
			
			<td valign='top' align='right'>
<form name='searchForm' method='get' action='../servlet/PostSearch'>
<input type='hidden' name='scope' value=''>
			<table border="0" cellspacing="0" cellpadding="0">
				<tr><td><img src='../i/spacer.gif' height='15'></td></tr>
				<tr>
	 				<td><img src='../i/spacer.gif' width='10'></td>
					<td><a href='<%=NODE%>/ep/search.jsp?showFilter=true'><img src='../i/search.gif' title='Advanced Search' border='0'></a></td>
	 				<td><img src='../i/spacer.gif' width='3'></td>
					<td><input class='ptextS1' type='text' size='26' name='query' value='Search'
						style='color:#777;' onClick='check(this.value);' onBlur='check(this.value);'>
					</td>
					<td align='left'><a href='javascript:searchForm.submit()'><img src='../i/go.gif' border='0' alt='Go search'></a></td>
				</tr>
			</table>
</form>
			</td>
		</tr>
		</table>
    </td>
   </tr>

</table>

<!-- table width="100%" border="0" cellspacing="0" cellpadding="0">
	<tr>
	<td style="font-family: Verdana, Arial, Helvetica, Verdana,sans-serif; font-weight: bold; font-size: 18px; color: #bb0000" align='center'>
		The System will be shutting down in 5 minutes.<br>Sorry for the inconvenience.
	<td>
	</tr>
</table -->

