<script Language="JavaScript">
<!--

///// Manage Two Side by Side Select Input Fields
function addOption(selectvalue1,selectvalue2)
{

	//This is a javascript program transfering data from one select type (multiple selection support)
	//form object to the other select type form object.
	//If selectvalue2 has data originally, the value from selectvalue1 will be added on selectvalue2.
	//param1: form select type value (Src)
	//param2: form select type value (target)



	for(i = 0; i < selectvalue1.length; i++)
	{
		if(selectvalue1.options[i].selected) //if the item is selected, add to the result list.
		{
			var not_found = true;
			//alert("select value 1: " + selectvalue1.length);
			//alert("select value 2: " + selectvalue2.length);

			//check whether this selected value is on the 2nd value list.
			for (j = 0; j < selectvalue2.length; j++)
			{
				if (selectvalue1.options[i].value == selectvalue2.options[j].value)
				{
					not_found = false;
					break;
				}
			}

			if(not_found)
			{
				index = selectvalue2.length;

				selectvalue2.options[index] = new Option(selectvalue1.options[i].text, selectvalue1.options[i].value)
				selectvalue2.options[index].selected = false;
			}
		}
	}
}

/**
* Compare two sorted list to determine if there already exists the same
* value on the second list. If the second list already contains the value
* the item is ignored. NOTE: This method will break if the list is not sorted
* to begin with. It will break by not showing some items that are suppose to 
* be selected. 
*/
function addSortedOption(selectvalue1,selectvalue2)
{
	var startLength1 = selectvalue1.length;
	var startLength2 = selectvalue2.length;
	var idx1 = 0;
	var idx2 = 0;
	while(idx1 < startLength1 && idx2 < startLength2) {
		if(selectvalue1.options[idx1].selected)
		{
			var text1 = selectvalue1.options[idx1].text;
			var text2 = selectvalue2.options[idx2].text;
			// Add
			if(text1 < text2) {
				var index = selectvalue2.length;			
				selectvalue2[index] = new Option(selectvalue1.options[idx1].text, selectvalue1.options[idx1].value);
				selectvalue2.options[index].selected = false;

				idx1++;
			}
			// move to next item
			else if(text1 > text2) {
				idx2++;
			}	
			// equal, move to next items
			else { 
				idx1++;
				idx2++; 
			}
		}
		// not a selected value, skip
		else
		{
			idx1++;
		}	
	}
	
	// Add remaining selected options to other list
	while(idx1 < startLength1) {
		if(selectvalue1.options[idx1].selected) {
			var index = selectvalue2.length;			
			selectvalue2[index] = new Option(selectvalue1.options[idx1].text, selectvalue1.options[idx1].value)
			selectvalue2.options[index].selected = false;
		}
		idx1++;
	}
}

/**
* Compare two sorted list to determine if there already exists the same
* value on the second list. If the second list already contains the value
* the item is ignored. Once the item is added, it is removed from the first list
* NOTE: This method will break if the list is not sorted
* to begin with. It will break by not showing some items that are suppose to 
* be selected. 
*/
function addSortedOptionRemove(selectvalue1,selectvalue2)
{
	var startLength1 = selectvalue1.length;
	var startLength2 = selectvalue2.length;
	var idx1 = 0;
	var idx2 = 0;
	while(idx1 < startLength1 && idx2 < startLength2) {
		if(selectvalue1.options[idx1].selected)
		{
			var text1 = selectvalue1.options[idx1].text;
			var text2 = selectvalue2.options[idx2].text;
			// Add & Remove
			if(text1 < text2) {
				var index = selectvalue2.length;			
				selectvalue2[index] = new Option(selectvalue1.options[idx1].text, selectvalue1.options[idx1].value);
				selectvalue2.options[index].selected = false;
				selectvalue1.options[idx1].selected = false;
				selectvalue1.options[idx1] = null;
				startLength1--;
				//idx1++;
			}
			// move to next item
			else if(text1 > text2) {
				idx2++;
			}	
			// equal, move to next items and remove
			else { 
				selectvalue1.options[idx1].selected = false;
				selectvalue1.options[idx1] = null;
				startLength1--;
				idx2++; 
			}
		}
		// not a selected value, skip
		else
		{
			idx1++;
		}	
	}
	
	// Add remaining selected options to other list and remove
	while(idx1 < startLength1) {
		if(selectvalue1.options[idx1].selected) {
			var index = selectvalue2.length;			
			selectvalue2[index] = new Option(selectvalue1.options[idx1].text, selectvalue1.options[idx1].value)
			selectvalue2.options[index].selected = false;
			selectvalue1.options[idx1].selected = false;
			selectvalue1.options[idx1] = null;
			startLength1--;
		}
		else
			idx1++;
	}
}

/**
* Iterates through the Select list backwards and removes the
* selected items
*/
function removeOptionQuick(selectItem)
{
	var end = selectItem.length - 1;
	for(var i = end; i >= 0; i--) {
		if(selectItem.options[i].selected) {
			selectItem.options[i].selected = false;
			selectItem.options[i] = null;
		}
	}
}

function removeOption(selectItem)
{
	//Remove selected option.

	var max = selectItem.length
	for(j = 0; j < max; j++)
	{
		for(i = 0; i < selectItem.length; i++)
		{
			if(selectItem.options[i].selected)
			{
				selectItem.options[i].selected = false;
				selectItem.options[i] = null;
				break;
			}
		}
	}
}

function swapdata(select1, select2)
{
	// add data from select1 to select2
	//then remove the selected data from select1.

	//addOption(select1, select2);
	addSortedOptionRemove(select1, select2);
	//removeOption(select1);
	sortSelect(select1);
	sortSelect(select2);
}

function swapSorteddata(select1, select2)
{
	addSortedOptionRemove(select1, select2);
	//removeOptionQuick(select1);
	sortSelect(select1);
	sortSelect(select2);
}

function swapdata1(select1, select2)
{
	// add data from select1 to select2
	// then remove the selected data from select1.
	// check to see if "The Whole" is selected

	// safe guard: if nothing is chosen on select1, don't do anything
	var found = false;
	for (i=0; i<select1.length; i++)
	{
		if (select1.options[i].selected)
		{
			found = true;
			break;
		}
	}
	if (!found) return;

	// first check to see if The Whole is selected on the left
	found = false;
	for(i = 0; i < select1.length; i++)
	{
		if(select1.options[i].selected) //if the item is selected, add to the result list.
		{
			if (select1.options[i].text.substring(1,10) == 'The Whole')
			{
				for (j=0; j<select1.length; j++)
					if (j != i) select1.options[j].selected = false;	// only the Whole get selected

				// move all idtems on select2 back to select1
				getall(select2);
				swapdata(select2, select1);
				found = true;

				break;
			}
		}
	}
	if (!found)
	{
		// The Whole might already be on the right, if so, remove it
		if ((select2.length > 0) && (select2.options[0].text.substring(1,10) == 'The Whole'))
		{
			// The Whole must be the only item
			getall(select2);
			swapdata(select2, select1);
		}
	}


	addOption(select1, select2);
	removeOption(select1);
	sortSelect(select1);
	sortSelect(select2);
}

function addItem(item, selectvalue)
{
	var not_found = true;

	//check whether this selected value is on the 2nd value list.
	for (i = 0; i < selectvalue.length; i++)
	{
		if (item.value == selectvalue.options[i].value)
		{
			not_found = false;
			break;
		}
	}

	if (not_found)
	{
		index = selectvalue.length;

		selectvalue.options[index] = new Option(item.value, item.value)
		selectvalue.options[index].selected = false;
		item.value = "";
	}
}

function getall(selectItem)
{

	var max = selectItem.length;
	for(j = 0; j < max; j++)
	{
		selectItem.options[j].selected = true;
	}
	return;
}

function JumpBox(tempMaxLength,e,tempCurrBox,tempNextBox)
{
	var tempCurrValueLength = tempCurrBox.value;
	tempCurrValueLength = tempCurrValueLength.length;
	var charCode = e.keyCode
	if ((eval(charCode) != 9) && (eval(charCode) != 16)) {
		if (tempCurrValueLength >= eval(tempMaxLength)) {
			if (isNaN(tempCurrBox.value)) {
				alert("Please enter a valid number.");
				tempCurrBox.value = "";
				tempCurrBox.focus();
				}
			else {
				tempNextBox.focus();
				}
			}
		}
	return true;
}

// -------------------------------------------------------------------
// sortSelect(select_object)
//   Pass this function a SELECT object and the options will be sorted
//   by their text (display) values
// -------------------------------------------------------------------
function sortSelect(obj) {
	var o = new Array();
	if (!hasOptions(obj)) { return; }
	for (var i=0; i<obj.options.length; i++) {
		o[o.length] = new Option( obj.options[i].text, obj.options[i].value, obj.options[i].defaultSelected, obj.options[i].selected) ;
		}
	if (o.length==0) { return; }
	o = o.sort(
			function(a,b) {
				x = a.text.toLowerCase();
				y = b.text.toLowerCase();
				if (x < y) { return -1; }
				if (x > y) { return 1; }
				return 0;
				}
			);

	for (var i=0; i<o.length; i++) {
		obj.options[i] = new Option(o[i].text, o[i].value, o[i].defaultSelected, o[i].selected);
		}
	}

function hasOptions(obj) {
	if (obj!=null && obj.options!=null) { return true; }
	return false;
	}

function copyRadioValue(e1, e2)
{
	for (i=0; i<e1.length; i++)
		if (e1[i].checked) {e2.value = e1[i].value; break;}
}

function copySelectValue(e1, e2)
{
	for (i=0; i<e1.length; i++)
		if (e1[i].selected) {e2.value = e1[i].value; break;}
}
/////////
function affirm_addfile(fname)
{
	var regEx = new RegExp("[#%+'&]");
	if ((idx = fname.lastIndexOf("\\")) != -1) fname = fname.substring(idx+1);
	if (fname.match(regEx))
	{
		alert("Illegal characters ( # % + ' & ) found in filename.\nPlease change your filename and upload again.");
		return false;
	}
	return true;
}
function affirm_delfile(loc)
{
	var s = "This action is non-recoverable. Do you really want to delete the attachment file?";
	if (confirm(s))
		location = loc;
	else
		return;
}
/**
* Detects if the value given contains bad char
* *><!~#$%^()=+[]{}|?`&\
*/
function containsBadChar(value) {
	var regEx = "([*|>|<|!|~|#|$|%|^|(|)|=|+|[|]|{|}|\\\\|]|[&]|[\\?])";
	if (value.search(regEx) > -1)
		return true;
	else 
		return false;
}
/**
* Detects if the value given is an integer
*/
function isInt(value) {
	if(isNaN(value) || value.search("([.])") > -1)
		return false;
	else
		return true;
}

//-->
</script>
