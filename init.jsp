<script language="JavaScript">

<!--
function MM_preloadImages() { //v3.0
  var d=document; if(d.images){ if(!d.MM_p) d.MM_p=new Array();
    var i,j=d.MM_p.length,a=MM_preloadImages.arguments; for(i=0; i<a.length; i++)
    if (a[i].indexOf("#")!=0){ d.MM_p[j]=new Image; d.MM_p[j++].src=a[i];}}
}
function MM_swapImgRestore() { //v3.0
  var i,x,a=document.MM_sr; for(i=0;a&&i<a.length&&(x=a[i])&&x.oSrc;i++) x.src=x.oSrc;
}
function MM_findObj(n, d) { //v3.0
  var p,i,x;  if(!d) d=document; if((p=n.indexOf("?"))>0&&parent.frames.length) {
    d=parent.frames[n.substring(p+1)].document; n=n.substring(0,p);}
  if(!(x=d[n])&&d.all) x=d.all[n]; for (i=0;!x&&i<d.forms.length;i++) x=d.forms[i][n];
  for(i=0;!x&&d.layers&&i<d.layers.length;i++) x=MM_findObj(n,d.layers[i].document); return x;
}
function MM_swapImage() { //v3.0
  var i,j=0,x,a=MM_swapImage.arguments; document.MM_sr=new Array; for(i=0;i<(a.length-2);i+=3)
   if ((x=MM_findObj(a[i]))!=null){document.MM_sr[j++]=x; if(!x.oSrc) x.oSrc=x.src; x.src=a[i+2];}
}
function demo_alert()
{
	var s = "This feature is not available in the DEMO version of the software.";
	alert(s);
}
function checkMail(str)
{
	var filter  = /^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/;
	return filter.test(str);
}
function checkDomain(str)
{
	var filter  = /^(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/;
	return filter.test(str);
}
function checkPhone(str)
{
	var filter  = /^((\+\d{1,3}(-| )?\(?\d\)?(-| )?\d{1,3})|(\(?\d{2,3}\)?))(-| )?(\d{3,4})(-| )?(\d{4})(( x| ext)\d{1,5}){0,1}$/
	return filter.test(str);
}
function trim(str) {
	if (str != null)
		return str.replace(/^\s*|\s*$/g,"");
	else
		return null;
}
function foundBadChar(str)
{
	for (i=0;i<str.length;i++)
	{
		char = str.charAt(i);
		if (char == '\"' || char == '\\' || char == '~'
				|| char == '`' || char == '!' || char == '#' || char == '$'
				|| char == '%' || char == '^' || char == '*' || char == '('
				|| char == ')' || char == '+' || char == '=' || char == '['
				|| char == ']' || char == '{' || char == '}' || char == '|'
				|| char == '>' || char == '<' || char == ' ' || char == '\t')
		{
			return true;	// bad
		}
	}
	return false;			// good
}
function fixElement(e, msg)
{
	alert(msg);
	if (e)
		e.focus();
}
function stripURLOption(url, opt)
{
	// strip the option "abc=123" or "abc=123&" from the URL
	var idx1 = url.indexOf("#");
	if (idx1 != -1)
		url = url.substring(0, idx1);				// strip anchor first

	idx1 = url.indexOf(opt+"=");	// opt is "abc"
	if (opt!="" && idx1!=-1)
	{
		var idx2 = url.indexOf("&", idx1+1);
		if (idx2 != -1)
			url = url.substring(0, idx1) + url.substring(idx2+1);	// done: term in middle - don't copy the "&"
		else
			url = url.substring(0, idx1);			// done: term at the end

		var len = url.length;
		if (url.charAt(len-1)=="?" || url.charAt(len-1)=="&")
			url = url.substring(0, url.length-1);	// trim the unused last ? or &
	}
	return url;
}
function addURLOption(url, opt)
{
	// add the option string.  opt is "xxx=123"
	var idx = opt.indexOf("=");
	if (idx == -1) return url;		// error
	var temp = opt.substring(0, idx);
	url = stripURLOption(url, temp);	// first strip the old value if present

	if (url.indexOf("?") != -1)
		url = url + "&" + opt;
	else
		url = url + "?" + opt;
	return url;
}
function getAnchor(url)
{
	var idx = url.indexOf("#");
	if (idx != -1)
		return url.substring(idx);		// return anchor starts with #
	return "";
}
function popHelp(anchor)
{
	window.open('../info/help_cpm.jsp#' + anchor, '',
		'scrollbars=yes,menubar=no,left=20,top=20,height=600,width=470,resizable=yes,toolbar=no,location=no,status=no');
}
function fo(f)
{
	for (i=0;i < f.length;i++) {
		if (f.elements[i].type != "hidden") {
			f.elements[i].focus();
			break;
		}
	}
}

function beginRefresh(f)
{
	// f is the form
	if (parselimit<=1)
	{
		if (confirm('Your session is about to timeout!  Do you want to save the changes?'))
		{
			saveAndCont();
			f.submit();
		}
	}
	else
	{
		parselimit -= 1;
		curmin=Math.floor(parselimit/60);
		cursec=parselimit%60;
		curtime = "Your session will timeout in ";
		if (curmin!=0)
			curtime +=  curmin+" min and "+cursec+" sec";
		else
			curtime += cursec+" sec";
		//window.status=curtime;
		msgE.innerHTML = curtime;
		setTimeout("beginRefresh()",1000);
	}
}

//-->
</SCRIPT>
