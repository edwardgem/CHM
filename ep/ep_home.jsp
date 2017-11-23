<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2010, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: ep_home.jsp (for PRM and CR and CR-OMF)
//	Author: ECC
//	Date:	03/25/10
//	Description: Home page selector.
//
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "util.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp?go=ep/ep_home.jsp" />

<%
	String app = Prm.getApp();
	boolean isPRMAPP = Prm.isPRM();
	
	String homePage = null;
	if (isPRMAPP) {
		homePage = pstuser.getStringAttribute("FirstPage");		
		if (homePage == null) {
			homePage = Prm.getSiteDefFirstPage();
		}
		if (homePage!=null && homePage.toLowerCase().contains("classichome")) {
			homePage = "ep_prm.jsp";
		}
		else {
			// default for CPM to dashboard
			homePage = "ep_db.jsp";
		}
	}
%>

<script type="text/javascript" language="javascript">

var loc;
var opt = "";
var fullURL = parent.document.URL;
var idx = fullURL.indexOf("?");
if (idx != -1)
	opt = fullURL.substring(idx);

if (<%=isPRMAPP%>)
	loc = "<%=homePage%>";
else if ("<%=app%>" == "OMF")
	loc = "ep_omf.jsp";
else
	loc = "ep_cr.jsp";
location = loc + opt;

</script>

<head>
<title><%=app%> Home</title>
</head>
</html>
