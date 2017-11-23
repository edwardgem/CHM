
function togglePanel(panelType, showStr, hideStr)
{
	var eDiv = document.getElementById("Div" + panelType);
	var eA = document.getElementById("A" + panelType);
	var eImg = document.getElementById("Img" + panelType);
	if (eDiv.style.display == "none") {
		eA.innerHTML = hideStr;
		eImg.src = "../i/tri_dn.gif";
		eDiv.style.display = "block";
	}
	else {
		eA.innerHTML = showStr;
		eImg.src = "../i/bullet_tri.gif";
		eDiv.style.display = "none";
	}
}
