<%@ page import = "java.util.Formatter" %>
<%
	// star rating system
	final String S1 = "It's alright";
	final String S2 = "Somewhat recommended";
	final String S3 = "Good stuff";
	final String S4 = "Really cool!";
	final String S5 = "This is WAY COOL!";
	final String [] SARR = {S1, S2, S3, S4, S5};
	
	double f = Double.parseDouble(request.getParameter("ratingS"));
	String votes = request.getParameter("votes");
	String backPage = request.getParameter("backPage");
	String idS = request.getParameter("id");
	String uidS = request.getParameter("uid");
	String app = request.getParameter("app");
	if (app == null) app = "OMF";

	String titleS;
	Formatter fr = new Formatter();
	if (f < 0)
		titleS = "not rated";
	else
	{
		titleS = fr.format("%.1f", f) + " stars (";
		if (f >= 4.5) titleS += S5;
		else if (f >= 3.5) titleS += S4;
		else if (f >= 2.5) titleS += S3;
		else if (f >= 1.5) titleS += S2;
		else titleS += S1;
		titleS += ")";
	}
	
	String link = "../info/post_rating.jsp?id=" + idS
		+ "&uid=" + uidS
		+ "&backPage=" + backPage
		+ "&app=" + app
		+ "&rating=";
%>
<link href="../omf.css" rel="stylesheet" type="text/css" media="all">
<script language="JavaScript" src="../login_cookie.js"></script>

<table border="0" cellspacing="0" cellpadding="0">
  <tr>
  <td>
<SCRIPT LANGUAGE="JavaScript">
<!--
var s1 = "<%=S1%>";
var s2 = "<%=S2%>";
var s3 = "<%=S3%>";
var s4 = "<%=S4%>";
var s5 = "<%=S5%>";
// *** NOTE: need to use double-quote for title below because of the single quote in the text here

var cookieName = "<%=app%><%=idS%>-<%=uidS%>";
var thisRating = getCookie(cookieName);
if (thisRating == null)
{
	document.write("<ul class='star-rating'>");
	document.write("<li><a href='<%=link%>1' title=\"" + s1 + "\" class='one-star'>1</a></li>");
	document.write("<li><a href='<%=link%>2' title=\"" + s2 + "\" class='two-stars'>2</a></li>");
	document.write("<li><a href='<%=link%>3' title=\"" + s3 + "\" class='three-stars'>3</a></li>");
	document.write("<li><a href='<%=link%>4' title=\"" + s4 + "\" class='four-stars'>4</a></li>");
	document.write("<li><a href='<%=link%>5' title=\"" + s5 + "\" class='five-stars'>5</a></li>");
	document.write("</ul>");
}
else
{
	document.write("<ul class='star-rating'>");
	var rating = parseInt(thisRating);
	var s = "The rating you gave was " + rating + " stars (";
	var jsSARR = new Array();
<%
	for (int i=0; i<SARR.length; i++) {
	out.println("jsSARR[" + i + "]=\"" + SARR[i] + "\"");
	}
%>

	switch (rating)
	{
		case 1: s += s1; break;
		case 2: s += s2; break;
		case 3: s += s3; break;
		case 4: s += s4; break;
		case 5: s += s5; break;
		deault: break;
	}
	s += ")";
	var ct = 1;
	while (rating-- > 0)
	{
//		document.write("<li class='current-rating'>");
//		document.write("<a href='<%=link%>" + ct + "&old=" + thisRating + "' title=\"" + s + "\" classs='");
		document.write("<li class='current-rating'>");
		document.write("<a href='<%=link%>" + ct + "&old=" + thisRating
				+ "' title=\"" + jsSARR[ct-1] + "\" classs='");
		switch (ct)
		{
			case 1: document.write("one-star'>1"); break;
			case 2: document.write("two-stars'>2"); break;
			case 3: document.write("three-stars'>3"); break;
			case 4: document.write("four-stars'>4"); break;
			case 5: document.write("five-stars'>5"); break;
			default: break;
		}
		document.write("</a></li>");
		ct++;
	}

	while (ct <= 5)
	{
		document.write("<li><a href='<%=link%>" + ct + "&old=" + thisRating + "' title=\"");
		switch (ct)
		{
			case 1: document.write(s1 + "\" class='one-star'>1"); break;		// impossible to be 1
			case 2: document.write(s2 + "\" class='two-stars'>2"); break;
			case 3: document.write(s3 + "\" class='three-stars'>3"); break;
			case 4: document.write(s4 + "\" class='four-stars'>4"); break;
			case 5: document.write(s5 + "\" class='five-stars'>5"); break;
			default: break;
		}
		document.write("</a></li>");
		ct++;
	}
	document.write("</ul>");
}
//-->
</script>

  </td>
  
  <td><img src='../i/spacer.gif' width='50' height='1'></td>
  
  <td class='plaintext' valign='middle'>
<%
	if (f < 0)
	{
		out.print("Average (not rated): ");
	}
	else
	{
		out.print("Average (" + votes + " votes):&nbsp;&nbsp;</td>");
		out.print("<td title=\"" + titleS + "\">");
		int i = 5;
		while (i-- > 0)
		{
			if (f >= 1)
				out.print("<img src='../i/star_full.gif' border='0'>");
			else if (f > 0)
				out.print("<img src='../i/star_half.gif' border='0'>");
			else
				out.print("<img src='../i/star_empty.gif' border='0'>");
			f--;
		}
		out.print("</td>");
	}
%>
  </td>
  </tr>
</table>

