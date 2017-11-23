<script Language="JavaScript">
<!--

///// Manage Four Side by Side Select Input Fields (design for Meeting Facilitator)
function swapdataM(selectvalue1, selectvalue2, selectvalue3, selectvalue4)
{

	//This is a javascript program transfering data from one select type (multiple selection support)
	//form object to the other select type form object.
	//If selectvalue2 has data originally, the value from selectvalue1 will be added on selectvalue2.
	//param1: form select type value (Src)
	//param2: form select type value (target)

	var select;

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

			// remove from selectvalue3 and 4
			for (n=0; n<2; n++)
			{
				if (n == 0) select = selectvalue3;
				else select = selectvalue4;

				for (j = 0; j < select.length; j++)
				{
					if (selectvalue1.options[i].value == select.options[j].value)
					{
						select.options[j] = null;
						break;
					}
				}
			}
		}
	}
	removeOption(selectvalue1);
	sortSelect(selectvalue1);
	sortSelect(selectvalue2);
	sortSelect(selectvalue3);
	sortSelect(selectvalue4);
}

/**
	@AGQ080206
	Adds the value from selectvalue1 to selectvalue2 while also comparing
	to see if the same item is on the other side. This list assumes that 
	the items are sorted.
**/
function swapdataMFast(selectvalue1, selectvalue2, selectvalue3, selectvalue4)
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
				selectvalue3.options[idx1].selected = false;
				selectvalue1.options[idx1] = null;
				selectvalue3.options[idx1] = null;
				startLength1--;
				//idx1++;
			}
			// move to next item
			else if(text1 > text2) {
				idx2++;
			}	
			// equal, move to next items and remove
			else { 
				// check if value is equal
				var value1 = selectvalue1.options[idx1].value;
				var value2 = selectvalue2.options[idx2].value;
				if (value1 != value2) {
					var index = selectvalue2.length;
					selectvalue2[index] = new Option(selectvalue1.options[idx1].text, selectvalue1.options[idx1].value);
					selectvalue2.options[index].selected = false;
				}
				selectvalue1.options[idx1].selected = false;
				selectvalue3.options[idx1].selected = false;
				selectvalue1.options[idx1] = null;
				selectvalue3.options[idx1] = null;
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
			selectvalue3.options[idx1].selected = false;
			selectvalue3.options[idx1] = null;
		}
		else
			idx1++;
	}

	sortSelect(selectvalue1);
	sortSelect(selectvalue2);
	sortSelect(selectvalue3);
	sortSelect(selectvalue4);
}

/**
	@AGQ080206
	Plainly moves selected items from selectvalue1 to selectvalue2. Removes
	the values from selectvalue3 also. Does not perform any duplication check
	since meeting page already performs that in the beginning before loading
	the list. Assumes that selectvalue1 and selectvalue3 are the same. Currently
	swapdataMFast is used instead since theres no visible change in performance.
**/
function swapdataMFaster(selectvalue1, selectvalue2, selectvalue3, selectvalue4)
{
	var startLength1 = selectvalue1.length;
	var startLength2 = selectvalue2.length;
	var idx1 = 0;
	var idx2 = 0;

	// Add remaining selected options to other list and remove
	while(idx1 < startLength1) {
		if(selectvalue1.options[idx1].selected) {
			var index = selectvalue2.length;			
			selectvalue2[index] = new Option(selectvalue1.options[idx1].text, selectvalue1.options[idx1].value)
			selectvalue2.options[index].selected = false;
			selectvalue1.options[idx1].selected = false;
			selectvalue1.options[idx1] = null;
			startLength1--;
			selectvalue3.options[idx1].selected = false;
			selectvalue3.options[idx1] = null;
		}
		else
			idx1++;
	}

	sortSelect(selectvalue1);
	sortSelect(selectvalue2);
	sortSelect(selectvalue3);
}

/**
	@AGQ080206
	Plainly moves selected items from selectvalue1 to selectvalue2 and selectvalue3.
	Does not perform any duplication check since meeting page already performs that
	in the beginning before loading the list. Assumes that selectvalue2 and selectvalue3
	are the same.
**/
function swapdataM1Fast(selectvalue1, selectvalue2, selectvalue3) {
	var startLength1 = selectvalue1.length;
	var startLength2 = selectvalue2.length;
	var idx1 = 0;
	var idx2 = 0;
		// Add remaining selected options to other list and remove
	while(idx1 < startLength1) {
		if(selectvalue1.options[idx1].selected) {
			var index = selectvalue2.length;			
			selectvalue2[index] = new Option(selectvalue1.options[idx1].text, selectvalue1.options[idx1].value)
			selectvalue2.options[index].selected = false;
			selectvalue3[index] = new Option(selectvalue1.options[idx1].text, selectvalue1.options[idx1].value)
			selectvalue3.options[index].selected = false;
			selectvalue1.options[idx1].selected = false;
			selectvalue1.options[idx1] = null;
			startLength1--;
		}
		else
			idx1++;
	}

	sortSelect(selectvalue1);
	sortSelect(selectvalue2);
	sortSelect(selectvalue3);
}

function swapdataM1(selectvalue1, selectvalue2, selectvalue3)
{

	var select;

	for(i = 0; i < selectvalue1.length; i++)
	{
		if(selectvalue1.options[i].selected) //if the item is selected, add to the result list.
		{
			var not_found = true;
			//alert("select value 1: " + selectvalue1.length);
			//alert("select value 2: " + selectvalue2.length);

			//check whether this selected value is on the 2nd value list.
			for (n=0; n<2; n++)
			{
				if (n == 0) select = selectvalue2;
				else select = selectvalue3;

				for (j = 0; j < select.length; j++)
				{
					if (selectvalue1.options[i].value == select.options[j].value)
					{
						not_found = false;
						break;
					}
				}

				if(not_found)
				{
					index = select.length;

					select.options[index] = new Option(selectvalue1.options[i].text, selectvalue1.options[i].value)
					select.options[index].selected = false;
				}
			}
		}
	}

	removeOption(selectvalue1);
	sortSelect(selectvalue1);
	sortSelect(selectvalue2);
	sortSelect(selectvalue3);
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

function getall(selectItem)
{

	var max = selectItem.length;
	for(j = 0; j < max; j++)
	{
		selectItem.options[j].selected = true;
	}
	return;
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
	/*o = o.sort(
	function(a,b) {
		if ((a.text+"") < (b.text+"")) { return -1; }
		if ((a.text+"") > (b.text+"")) { return 1; }
		return 0;
		}
	);*/

	for (var i=0; i<o.length; i++) {
		obj.options[i] = new Option(o[i].text, o[i].value, o[i].defaultSelected, o[i].selected);
		}
	}
function hasOptions(obj) {
	if (obj!=null && obj.options!=null) { return true; }
	return false;
	}
/////////
function affirm_addfile(fname)
{
	var regEx = new RegExp("[#%+'&]");
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
		return false;
}

function isInteger(val)
{
	if (isBlank(val)){return false;}
	for(var i=0;i<val.length;i++){
		if(!isDigit(val.charAt(i))){return false;}
		}
	return true;
}
function isDigit(num)
{
	if (num.length>1){return false;}
	var string="1234567890";
	if (string.indexOf(num)!=-1){return true;}
	return false;
}
function isBlank(val)
{
	if(val==null){return true;}
	for(var i=0;i<val.length;i++) {
		if ((val.charAt(i)!=' ')&&(val.charAt(i)!="\t")&&(val.charAt(i)!="\n")&&(val.charAt(i)!="\r")){return false;}
		}
	return true;
}

//-->
</script>
