
function chooseColor(op)
{
	var e = document.getElementById("selColor");
	e.style.display = 'block';
	e.innerHTML = "<table cellspacing='0' cellpadding='0'><tr>"
		+ "<td class='plaintext' width='135'>Change my color to </td>"
		+ "<td valign='bottom' onclick='chooseColor(" + op + ");'><input style='font-size: 8px; type='text' ID='sample' size='1' value=''></td>"
		+ "<td><input class='formtext' type='button' value='Accept' onclick='changeColor(" + op + ");'></td>"
		+ "<td><input class='formtext' type='button' value='Cancel' onclick='cancelColor();'></td></tr>";
	showColorGrid2('myColor','sample');
}
function cancelColor()
{
	var e = document.getElementById("selColor");
	e.style.display = 'none';
	e.innerHTML = "";
}
function changeColor(op)
{
	var newColor = document.getElementById("myColor").value;
	cancelColor();
	if (op==1)
	{
		omf_myColor = newColor;
		start_chat(null, chatObjIdS, "");
	}
	else
		showNewColor(newColor);
}
