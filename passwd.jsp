<!--
	Display a plane to prompt for password in a form,
	it will then call the post_passwd.jsp to check on
	password based on the context.
 -->
<%@ page import = "java.util.ArrayList" %>
<%
	String textColor = "#336699";
%>

<div id='pPanel' style="position:relative; font-size:50px; z-index:1; display:block;">
	<div id='pTansPad' style="position:relative; top:-20; left:5; z-index:2; height:200px;width:350px;padding:8px;background:#fff9b2;filter:alpha(opacity=70);-moz-opacity:70%;"></div>
	<div id='pMsgDiv' style="position:relative; top:-20; left:5; color:red; font-size:80px; z-index:3"></div>
</div>

<!--  >div id='pPanel' class='pMenu'>
	<div id='pTansPad' class='pTransBkgd'></div>
	<div id='pMsgDiv' class='pMsg'></div>
</div-->

<style type="text/css">
.pMenu {display:none;position:absolute;font-family:Verdana;font-size:12px;color:#000044;left:150px;top:5px;margin:10px;}
.pTransBkgd {left:10px;height:40px;width:350px;padding:8px;background:#fff9b2;filter:alpha(opacity=70);-moz-opacity:70%;}
.pMsg {filter:none;-moz-opacity:100%;position:relative;top:-55px;margin:5px;margin-left:10px;color:<%=textColor%>;}
img#pDel {position:relative;z-index:2;top:-75px; left:340px; border:0;}

</style>

<!--[if IE]>
<style type="text/css">
.pMsg {filter:none;-moz-opacity:100%;position:relative;top:-40px;margin:5px;color:<%=textColor%>;}
img#pDel {position:relative;z-index:2;top:-60px; left:470px; border:0;}
</style>
<![endif]-->



<script type='text/javascript' src='../plan/x_core.js'></script>
<script type="text/javascript">
<!--

function loadPasswdPanel()
{
	resizePanel();
	var panel = document.getElementById('pPanel');
	var e = document.getElementById('pMsgDiv');
	e.innerHTML = "";
	e.innerHTML += "<div>This is a form</div>";
	panel.style.display = 'block';
}

function resizePanel()
{
	var e = document.getElementById('pTansPad');
	//var windowW = parseInt(getViewportWidth() * 0.25);
	//e.style.width = windowW + "px";
	e.style.height = "200px";
	
	var ee = document.getElementById('pMsgDiv');
	ee.style.top = "-210px";
}
function hide()
{
	var panel = document.getElementById('pPanel');
	panel.style.display = 'none';
}
//-->
</script>
