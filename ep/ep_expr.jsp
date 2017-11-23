<%@ page import = "util.Prm" %>
<%
	String leftPos = "780px";	// default
	String topPos = "200px";	// the picture top
	String imgWidth = "";
	if (Prm.isPDA(request)) {
		leftPos = "400px";
		topPos  = "250px";
		imgWidth= "width='250px'";
	}
%>
<div id="fixedbox">

<div id="hello" style="position:fixed; width:100px; left:<%=leftPos%>; top:<%=topPos%>; filter:alpha(opacity=0); opacity:0.0; -moz-opacity:0.0; display:none">
<img src="../i/hello.gif" border="0" <%=imgWidth%> alt="hello" />
</div>
<div id="hello1" style="position:fixed; width:300px; left:<%=leftPos%>; top:180px; filter:alpha(opacity=0); opacity:0.0; -moz-opacity:0.0; display:none;">
<span id="hello2" class='plaintext_blue'>@FROM@ says</span>
</div>

</div>
