
var reqmfc;		// send request
var HOST;		// will be init by calling JSP files

function initAjax()
{
	if (window.XMLHttpRequest) {
		reqmfc = new XMLHttpRequest(); 
	} else if (window.ActiveXObject) {
		reqmfc = new ActiveXObject("Microsoft.XMLHTTP");
	}
}

function ajaxSetActionDone(aid, bSetDone)
{	
	initAjax();
	var url = HOST + "/servlet/PrmAjax";
	reqmfc.open("POST", url, true);
	reqmfc.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
	reqmfc.send("op=SET_ACTION_DONE&id=" + aid + "&bArg1=" + bSetDone);
	// no callback
}

function ajaxSetActionDueDate(aid, dt)
{
	initAjax();
	var url = HOST + "/servlet/PrmAjax";
	reqmfc.open("POST", url, true);
	reqmfc.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
	reqmfc.send("op=SET_ACTION_DUE&id=" + aid + "&dtArg1=" + dt);
	// no callback
}