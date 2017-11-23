<script language="JavaScript">

<!--

function popUp(page, w, h)
{
	if (w==null) w = 700;
	if (h==null) h = 560;
	path = window.open(page,"so","toolbar=0,scrollbars=1,location=0,status=1,menubars=1,resizable=1,width="
		+ w + ",height=" + h);
	so=eval(path);
	width=(screen.width/2)-380;
	height=(screen.height/2)-320;
	so.window.moveTo(width,height);
	window.so.location.reload();
}

var seltext = null;
var repltext = null;
function wrapIt(type)
{
	var beg, end, beg1;

	if ( typeof( document.forms.form1.text1 ) == "undefined" )
	{
		document.forms.form1.innerHTML += '<INPUT TYPE="text" NAME="text1">';
	}
	temp1 = form1.text1.createTextRange();
	temp1.execCommand( 'Paste' );
	s = form1.text1.value;

	if (type == 'l')
	{
		beg1='\">';
		end='</a>';
		var url=prompt("Please enter URL link here:", s);
		if (url!=null && url!="")
		{
			beg='<a href=\"' + url ;
		}
		else
			return;
	}
	else if (type == 'b'){beg='<b>';end='</b>'}
	else if (type == 'i'){beg='<i>';end='</i>'}
	else if (type == 'u'){beg='<u>';end='</u>'}
	seltext = (document.all)? document.selection.createRange() : document.getSelection();
	var selit = (document.all)? document.selection.createRange().text : document.getSelection();
	if (selit.length>=1){
		if (seltext)
		{
			if (type == 'l')
			{
				if (seltext.text.indexOf("<a") == -1)
				{
					var s = seltext.text;
					seltext.text = beg;
					seltext.text = beg1 + s + end;
				}
			}
			else
				seltext.text = beg + seltext.text + end;
			window.focus();
		}
	}
	else
		alert("Please select the text you want to insert a Hyperlink before clicking the Add Link button.");
}

 function storeCaret (textEl)
 {
   if (textEl.createTextRange)
	 textEl.caretPos = document.selection.createRange().duplicate();
 }

 function insertAtCaret (textEl, text)
 {
   if (textEl.createTextRange && textEl.caretPos) {
	 var caretPos = textEl.caretPos;
	 caretPos.text =
	   caretPos.text.charAt(caretPos.text.length - 1) == ' ' ?
		 text + ' ' : text;
   }
   else
	 textEl.value  = text;
   textEl.focus();
 }

//-->
</SCRIPT>
<form name="form1" action="post" method="">
</form>