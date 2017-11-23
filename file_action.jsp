<script language="JavaScript">

<!--
var enteredVal = "";
var checkall = false;
var currentITypeLabel = "";				// this value must be set up when the set of functions are called here

// ECC: to understand these functions, the key is to understand currentITypeLabel, which takes the form of
// 1, 2, or 3_0, 3_1, etc.  See Util3.displayShareOption() and the callers: cr.jsp, rdata.jsp and ep_home.jsp.

function selectAll(iTypeLabel)
{
	currentITypeLabel = iTypeLabel;
	var eArr = document.getElementsByName("fileList");
	var e = document.getElementById("checkTxt");
	if (!checkall)
	{
		for (i=0; i<eArr.length; i++)
			eArr[i].checked = true;
		e.innerHTML = "Clear All";
	}
	else
	{
		for (i=0; i<eArr.length; i++)
			eArr[i].checked = false;
		e.innerHTML = "Select All";
		
		e = document.getElementById("shareBox_"+currentITypeLabel);
		e.style.display = "none";		// make sure boxes are closed
	}
	checkall = !checkall;
}

function hasCheckFile(name)
{
	var eArr = document.getElementsByName(name);
	var bHasFile = false;
	for (i=0; i<eArr.length; i++)
	{
		if (eArr[i].checked == true)
		{
			bHasFile = true;
			break;
		}
	}
	return bHasFile;
}

function getCheckedFile(name)
{
	var fname = "";
	var eArr = document.getElementsByName(name);
	for (i=0; i<eArr.length; i++)
	{
		if (eArr[i].checked == true)
		{
			if (fname != "") fname += "??";			// use this as separator because filename cannot have ?
			fname += eArr[i].value;
		}
	}
	return fname;
}

function getCheckedFileIds(name)
{
	// there is a different getCheckedFile()
	var fids = "";
	var eArr = document.getElementsByName(name);
	for (i=0; i<eArr.length; i++)
	{
		if (eArr[i].checked == true)
		{
			if (fids != "") fids += ";";			// attId separated by ";"
			fids += eArr[i].value;
		}
	}
	return fids;
}

function add_member(type)
{
	// actually click SEND to share files with other people
	// type 1 means using filenames, 2 means using file Ids
	var f, checkBoxName;
	if (currentITypeLabel.charAt(0)!='3')		// either 1, 2, or 3_0, 3_1, etc.
	{
		checkBoxName = "fileList";
		f = document.FileAction;
	}
	else
	{
		checkBoxName = "folderList";
		f = document.FolderAction;
	}

	var ee = document.getElementById("shareMember_" + currentITypeLabel);
	if (trim(ee.value) == "")
		return false;
		
	var val = ee.value;
	val = val.replace(/;/g, ",");
	val = val.replace(/\n/g, ",");
	var valArr = val.split(",");		// email now separated by comma
	var newVal = "";
	for (i=0; i<valArr.length; i++)
	{
		val = trim(valArr[i]);
		if (val == "") continue;
		if (bUsernameEmail && !checkMail(val))
		{
			fixElement(ee, "[" + val
				+ "] is not a valid email address.  You must enter valid email addresses to share files.");
			return false;
		}
		if (newVal != "") newVal += ",";
		newVal += val;
	}
	ee.value = newVal;

	// share all checked files
	var fname;
	if (type == 2)
		fname = getCheckedFileIds(checkBoxName);
	else
		fname = getCheckedFile(checkBoxName);		// iType of 1 (filenames) and 3 (folder names)

	if (fname != "")
	{
		f.fname.value = fname;						// use this to pass filenames or attIds
		f.iTypeLabel.value = currentITypeLabel;
		f.action = "../ep/post_share_file.jsp"
		f.submit();
	}
}

function share(userEmail, iTypeLabel)
{
	// click the button to specify shared email addresses (open hidden textboxes)
	// Parameter userEmail is the default email for sharing
	// Parameter iType: 1 or 2 - sharing file; 3 - share folder.

	currentITypeLabel = iTypeLabel;
	var e = document.getElementById("shareBox_" + iTypeLabel);
	var ee = document.getElementById("shareMember_" + currentITypeLabel);
	
	var f;
	if (currentITypeLabel.charAt(0)!='3')		// either 1, 2, or 3_0, 3_1, etc.
	{
		checkBoxName = "fileList";
		f = document.FileAction;
	}
	else
	{
		checkBoxName = "folderList";
		f = document.FolderAction;
	}

	if (e.style.display == "none")
	{
		if (!hasCheckFile(checkBoxName))
		{
			alert("To share files with others, select one or more files before clicking the SHARE icon.");
			return false;
		}
		enteredVal = "";
		
		e.style.display = "block";
		location = '#end';
	
		ee.focus();
		if (userEmail != null)
			ee.value = userEmail + ", ";
		
		var h = e.clientHeight;
		h = document.body.clientHeight + h;
		var px = "";
		if(navigator.userAgent.indexOf("Firefox") != -1) px = "px";
		document.body.style.height = h;
	}
	else
	{
		e.style.display = "none";
		ee.value = "";
		document.getElementById("emails_" + currentITypeLabel).style.display = "none";
	}
	
	e = document.getElementById("msg");
	if (e != null)
		e.innerHTML = "";
}

function lock(type)
{
	// type 1 means using filenames, 2 means using file Ids
	var f, checkBoxName;
	if (currentITypeLabel.charAt(0)!='3')		// either 1, 2, or 3_0, 3_1, etc.
	{
		checkBoxName = "fileList";
		f = document.FileAction;
	}
	else
	{
		checkBoxName = "folderList";
		f = document.FolderAction;
	}

	if (!hasCheckFile(checkBoxName))
	{
		alert("To turn shared files into private, select one or more files before clicking the LOCK icon.");
		return false;
	}
	
	var s = "Members' right in sharing the selected files would be revoked.\n\nDo you want to continue?";
	if (!confirm(s))
		return false;
		
	// remove the share list of all checked items
	var fname;
	if (type == 2)
		fname = getCheckedFileIds(checkBoxName);
	else
		fname = getCheckedFile(checkBoxName);		// iType of 1 (filenames) and 3 (folder names)

	if (fname != "")
	{
		f.fname.value = fname;
		f.iTypeLabel.value = currentITypeLabel;
		f.action = "../ep/post_del_share.jsp"
		f.submit();
	}
}

function pickItem(f)
{
	// take the currently selected item on the select box and add it to the email list
	if (f == null)
		f = document.FileAction;
	var e = document.getElementById("emailSel_" + currentITypeLabel);		// the select box for suggestive email
	var ee = document.getElementById("shareMember_" + currentITypeLabel);

	enteredVal = "";		// clear
	for (i=0; i<e.options.length; i++)
	{
		if (e.options[i].selected)
		{
			var val = ee.value;
			val = val.substring(0, val.lastIndexOf(","));
			if (val.length > 0) val += ", ";
			val += e.options[i].value;
			ee.value = val + ", ";
			e.options[i].selected = false;
			document.getElementById("emails_" + currentITypeLabel).style.display = "none";
			ee.focus();
			break;
		}
	}
}

function entSub(event, f)
{
	if (!window.event && !event)
		return true;
  
	var c;
	if (window.event)
		c = window.event.keyCode;
	else if (event)
		c = event.which;
		
	// compare and show emails on suggestive dropdown
	if (c == 13)
	{
		if (f==null && currentITypeLabel.charAt(0)!='3')
			f = document.FileAction;
		else
			f = document.FolderAction;
		pickItem(f);			// like double-click
		return false;			// return pressed: choose the current email
	}
	else if (c == 8)			// backspace
		enteredVal = enteredVal.substring(0, enteredVal.length-1);
	else if (c==188 || c==32)	// , or space
		enteredVal = "";
	else
		enteredVal += String.fromCharCode(c).toLowerCase();

	var e = document.getElementById("emailSel_" + currentITypeLabel);		// the select box for suggestive email
	if (e.options.length <= 0)
		return true;
		
	document.getElementById("emails_" + currentITypeLabel).style.display = "block";

	var found = false;
	for (i=0; i<e.options.length; i++)
	{
		if (!found && enteredVal!="" && e.options[i].value.indexOf(enteredVal) != -1)
		{
			e.options[i].selected = true;
			found = true;
		}
		else
			e.options[i].selected = false;
	}
	return true;
}

//-->
</SCRIPT>
