<%@ page import = "java.util.ArrayList" %>
<%
	// error msg
	String textColor = "#336699";
	ArrayList<String> errList = (ArrayList<String>) session.getAttribute("errorList");
	String errStr = "";
	int totalErr = 0;
	if (errList != null) {
		totalErr = errList.size();
		for (int i=0; i<totalErr; i++) {
			if (errStr != "") errStr += "@@@";
			errStr += errList.get(i);
		}
		String s = errStr.toLowerCase(); 
		if (s.contains("error")) {
			textColor = "#aa0000";
		}
		else if (s.contains(" success")) {
			textColor = "#00aa00";
		}
		session.removeAttribute("errorList");
	}
	else {
		return;
	}
%>

<div id='errPanel' class='menu'>
	<div id='transPad' class='transBkgd'></div>
	<div id='msgDiv' class='errMsg'></div>
	<img id='del' src='../i/delete.gif' onclick='hide();'/>
</div>

<style type="text/css">
.menu {display:none;position:absolute;font-family:Verdana;font-size:12px;color:#000044;left:150px;top:5px;margin:10px;}
.transBkgd {left:10px;height:40px;width:350px;padding:8px;background:#fff9b2;filter:alpha(opacity=70);-moz-opacity:70%;}
.errMsg {filter:none;-moz-opacity:100%;position:relative;top:-55px;margin:5px;margin-left:10px;color:<%=textColor%>;}
img#del {position:relative;z-index:2;top:-75px; left:340px; border:0;}
</style>

<!--[if IE]>
<style type="text/css">
.errMsg {filter:none;-moz-opacity:100%;position:relative;top:-40px;margin:5px;color:<%=textColor%>;}
img#del {position:relative;z-index:2;top:-60px; left:470px; border:0;}
</style>
<![endif]-->


<script type='text/javascript' src='../plan/x_core.js'></script>
<script type="text/javascript">
<!--
window.onload = function()
{
	alert("fine");
	loadErrPanel();
}

// can't put this directly in window.onload because if caller has window.onload this will get overwritten
// if caller has window.onload, just call loadErrPanel() in it.
function loadErrPanel()
{
	alert("ok2");
	var mStr = '<%=errStr%>';
	if (mStr == '') mStr = "I am testing error";
	
	if (mStr != '') {
		resizeErrPanel();
		var errArr = mStr.split("@@@");
		var panel = document.getElementById('errPanel');
		var e = document.getElementById('msgDiv');
		e.innerHTML = "";
		for (i=0; i<errArr.length; i++) {
			e.innerHTML += "<div>" + errArr[i] + "</div>";
		}
		panel.style.display = 'block';
	}
}
function resizeErrPanel()
{
	var e = document.getElementById('transPad');
	//var windowW = parseInt(getViewportWidth() * 0.25);
	//e.style.width = windowW + "px";
	var x = (1 + <%=totalErr%>) * 10 + 20;
	e.style.height = x + "px";
	
	x += 10;
	var ee = document.getElementById('msgDiv');
	ee.style.top = "-" + x + "px";
	
	var eee = document.getElementById('del');
	y = (1 + <%=totalErr%>) * 22 + 35;
	eee.style.top = "-" + y + "px";
}
function hide()
{
	var panel = document.getElementById('errPanel');
	panel.style.display = 'none';
}
//-->
</script>
