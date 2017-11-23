<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>

<%
////////////////////////////////////////////////////
//	Copyright (c) 2016, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	pysample.jsp
//	Author:	ECC
//	Date:	12/01/16
//	Description:
//		Python sample file.
//	Modification:
//
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>



<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>

<script src="https://ajax.aspnetcdn.com/ajax/jQuery/jquery-3.2.1.min.js"></script>
<script language="JavaScript">
<!--

var reqAuto = null;

function ajaxCallPython(data)
{
	if (window.XMLHttpRequest)
		reqAuto = new XMLHttpRequest();
	else if (window.ActiveXObject)
		reqAuto = new ActiveXObject("Microsoft.XMLHTTP");

	// sends data
	var params = "pData=" + data;

	var url = "http://127.0.0.1:8000/polls/";

	reqAuto.open("POST", url, true);					// async=true
	reqAuto.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");	// text/html, application/x-www-form-urlencoded
	
	reqAuto.onreadystatechange = callbackAuto;
	reqAuto.send(params);
}

function callbackAuto()
{
	
	//alert("got back: " + reqAuto.readyState + "; " + reqAuto.status);
    if (reqAuto.readyState == 4)
    {
        if (reqAuto.status == 200)			// should be 200
        {
            // success
            var s = reqAuto.responseText + "";
			alert(s);
			var myArr = JSON.parse(reqAuto.responseText);
	        myFunction(myArr);
        }
        else {
        	alert("failed status code:: " + reqAuto.status + "; text=" + reqAuto.responseText);
        }
    }
}

function myFunction(arr) {
    var out = "";
    var i;
    for(i = 0; i < arr.length; i++) {
        out += '<a href="' + arr[i].url + '">'
        	+ arr[i].display + '</a><br>';
    }
    document.getElementById("id01").innerHTML = out;
}

function processText() {
	var e = document.pForm.inputText;
	ajaxCallPython(e.value);
}


//var s = ajaxCallPython('Mary had a little lamp.  Lofty data to process!');

//-->
</script>

 <script>
   //form Submit action
   
$(document).ready(function() {    
   
$("#jqForm").submit(function(evt){	 
      evt.preventDefault();
      var formData = new FormData($(this)[0]);
	  alert('call ajax 1');
      
   $.ajax({
       url: '"http://127.0.0.1:8000/polls/"',
       type: 'POST',
       data: formData,
       async: false,
       cache: false,
       contentType: false,
       accepts: {mycustomtype: 'application/json'},
       dataType: 'mycustomtype',
       enctype: 'multipart/form-data',
       processData: false,
       success: function (response) {
         alert(response);
       }
       error: function() {
    	      alert("error in ajax"));
    	   },
   });
   return false;
 });
});
</script>


<title>
	PythonJS
</title>

</head>


<body bgcolor="#FFFFFF" >



<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="715" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="../head.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->

<tr>
	<td valign="top">

	<table>

	<tr><td colspan="2">&nbsp;</td></tr>
	<tr>
	<td></td>
	<td class="head">
		Python Sample
	</td></tr>

	</table>

	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="../i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>

<!-- CONTENT -->

<table>

	<tr>
		<td width="15">&nbsp;</td>
		<td colspan='2' class="instruction_head"><br/><b>Instruction Header</b></td>
	</tr>

	<tr>
		<td width="15">&nbsp;</td>
		<td colspan='2' class="instruction">
		<br/>
		Detailed instruction.
		<p/>2nd line instruction.<br/><br/>
		<div id='id01'>&nbsp;</div>
		</td>
	</tr>


<form id='jqForm'>
    <tr>
		<td width="15">&nbsp;</td>
      <td colspan="2"><h2>File Upload</h2></td>
    </tr>
    <tr>
		<td width="15">&nbsp;</td>
      <th>Select File </th>
      <td><input id="csv" name="csv" type="file" /></td>
    </tr>
    <tr>
		<td width="15">&nbsp;</td>
      <td colspan="2">
        <input type="submit" value="submit"/> 
      </td>
    </tr>
</form>

	<tr><td colspan='3'><img src='../i/spacer.gif' height='10'/></td></tr>


<form name='pForm'>
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan='2'>
			<textarea cols='40' rows='5' name='inputText'></textarea>
		</td>
	</tr>
	
	<tr>
		<td width="15">&nbsp;</td>
		<td colspan='2'>
 
			<input type='button' name='submit' class='button_medium' value='Submit' onclick='processText();' />
			<input type='button' name='cancel' class='button_medium' value='Cancel' />

		</td>
	</tr>
</form>


	
</table>



<!-- BEGIN FOOTER TABLE -->
<jsp:include page="../foot.jsp" flush="true"/>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</td></tr>
</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->


</body>


</html>

