<!--
//Hide Script

var pagelocation = location.href;
pagelocation = pagelocation.toLowerCase();

var showImg = new Array(2);
var hideImg = new Array(2);



function appear(text, a_id) {
	var e = document.getElementById(text+a_id);
	if(e.style.display == 'block')
		return;

	e.style.display = 'block';
	if(text == 'menu') {
		adjust();
		nav(a_id);
	}
}

function adjust() {
	var e = document.getElementById("adjust");
	if (e != null)
	{
		e.height = "80";
		e.height = "100%";
	}
}

function nav(a_id) {
	document.getElementById("nav" + a_id).src = hideImg[a_id];
	document.getElementById("nav" + a_id).alt =  "hide";
}

function disappear(text, a_id) {
	var e = document.getElementById(text+a_id);
	if (e!=null)
		e.style.display = 'none';
	adjust();
	e = document.getElementById("nav" + a_id);
	if (e != null)
	{
		e.src = showImg[a_id];
		e.alt =  "expand";
	}
}

function init_img(i, show, hide)
{
	showImg[i] = show;
	hideImg[i] = hide;
}


//End Hide
-->