/**
 * Convert a single file-input element into a 'multiple' input list
 *
 * Usage:
 *
 *   1. Create a file input element (no name)
 *      eg. <input type="file" id="first_file_element">
 *
 *   2. Create a DIV for the output to be written to
 *      eg. <div id="files_list"></div>
 *
 *   3. Instantiate a MultiSelector object, passing in the DIV and an (optional) maximum number of files
 *      eg. var multi_selector = new MultiSelector( document.getElementById( 'files_list' ), 3 );
 *
 *   4. Add the first element
 *      eg. multi_selector.addElement( document.getElementById( 'first_file_element' ) );
 *
 *   5. That's it.
 *
 *   You might (will) want to play around with the addListRow() method to make the output prettier.
 *
 *   You might also want to change the line
 *       element.name = 'file_' + this.count;
 *   ...to a naming convention that makes more sense to you.
 *
 * License:
 *   Use this however/wherever you like, just don't blame me if it breaks anything.
 *
 * Credit:
 *   If you're nice, you'll leave this bit:
 *
 *   Class by Stickman -- http://www.the-stickman.com
 *      with thanks to:
 *      [for Safari fixes]
 *         Luis Torrefranca -- http://www.law.pitt.edu
 *         and
 *         Shawn Parker & John Pennypacker -- http://www.fuzzycoconut.com
 *      [for duplicate name bug]
 *         'neal'
 */

var filenameList = "";		// ECC: remember for Subject header

function MultiSelector( list_target, max, class_name, browse_size, bNoPost ){

	// Where to write the list
	this.list_target = list_target;
	// How many elements?
	this.count = 0;
	// How many elements?
	this.id = 0;
	// Is there a maximum?
	if( max ){
		this.max = max;
	} else {
		this.max = -1;
	};
	this.class_name = class_name;
	this.browse_size = browse_size;

	/**
	 * Add a new file input element
	 */
	this.addElement = function( element ){

		// Make sure it's a file input element
		if( element.tagName == 'INPUT' && element.type == 'file' ){

			// Element name -- what number am I?
			element.name = 'file_' + this.id++;
			element.className = this.class_name;
			element.size = this.browse_size;

			// Add reference to this object
			element.multi_selector = this;
			
			element.onclick = function() {				
				// check if posting is blocked
				if (bNoPost!=null && bNoPost) {	// MSG.5004
					location = "../out.jsp?go=project/proj_top.jsp&msg=Posting to this project is not allowed.  Please contact the project coordinator if you have any questions.";
					return false;
				}
			}
			
			// What to do when a file is selected
			element.onchange = function(){
				var fileName = trimS(this.value);
				if (fileName.length > 0) {
					// New file input
					var new_element = document.createElement( 'input' );
					new_element.type = 'file';

					// Add new element
					this.parentNode.insertBefore( new_element, this );

					// Apply 'update' to element
					this.multi_selector.addElement( new_element );

					// Update list
					this.multi_selector.addListRow( this );

					// Hide this: we can't use display:none because Safari doesn't like it
					this.style.position = 'absolute';
					this.style.left = '-1000px';
				}
			};
			// If we've reached maximum number, disable input element
			if( this.max != -1 && this.count >= this.max ){
				element.disabled = true;
			};

			// File element counter
			this.count++;
			// Most recent element
			this.current_element = element;

		} else {
			// This can only be applied to file input elements!
			alert( 'Error: not a file input element' );
		};

	};

// Creates a table to show the files

	this.addListRow = function( element ){

		// Row div
		var new_row = document.createElement( 'tr' );
		var new_col_filename = document.createElement( 'td' );
		var new_col_button = document.createElement( 'td' );

		new_col_filename.setAttribute( 'align', 'left');
		new_col_filename.className = 'plaintext_blue';
		new_col_button.setAttribute( 'align', 'right');
		new_col_button.setAttribute( 'valign', 'top');
		new_col_button.setAttribute( 'width', '100px');

		// Delete button
		var new_row_button = document.createElement( 'input' );
		new_row_button.type = 'button';
		new_row_button.value = 'remove';
		new_row_button.className = 'plaintext'; //this.class_name;

		new_row.appendChild( new_col_filename );
		new_row.appendChild( new_col_button );

		var e = document.getElementById('uploadButton');
		if (e != null) {
			e.style.display = 'block';
		}

		// References
		new_row.element = element;

		// Set row value
		//new_row.innerHTML = element.value;
		var html = getName(element.value);			// the filename only

		// Delete function
		new_row_button.onclick= function(){

			// Remove row from table
			this.parentNode.parentNode.parentNode.removeChild(this.parentNode.parentNode);

			// Remove element from form
			this.parentNode.parentNode.element.parentNode.removeChild( this.parentNode.parentNode.element );

			// Decrement counter
			this.parentNode.parentNode.element.multi_selector.count--;

			// Re-enable input element (if it's disabled)
			this.parentNode.parentNode.element.multi_selector.current_element.disabled = false;

			// ECC: cleanup the filenameList remembered
			idx1 = filenameList.indexOf(html);
			idx2 = idx1 + html.length;
			if (filenameList.length > idx2)
				idx2 += 2;			// cut the comma and space
			filenameList = filenameList.substring(0, idx1) + filenameList.substring(idx2);
			filenameList = trimS(filenameList);
			idx1 = filenameList.length;
			if (idx1>0 && filenameList.charAt(idx1-1)==',')
				filenameList = filenameList.substring(0, idx1-1);
			
			// remove the upload button and message if there is no files in the list
			if (filenameList.length <= 0) {
				var e = document.getElementById('uploadButton');
				e.style.display = 'none';
			}

			// Appease Safari
			// without it Safari wants to reload the browser window
			// which nixes your already queued uploads
			return false;
		};

		// Display File Name:
		//	html - filename only;
		//	element.value - full file name;
		new_col_filename.innerHTML = html;

		// ECC: remember the filename for Subject
		if (filenameList != "") filenameList += ", ";
		filenameList += html;

		new_col_button.appendChild( new_row_button );

		// Add it to the list
		this.list_target.appendChild( new_row );
	};
};

function trimS(str) {
	if (str != null)
		return str.replace(/^\s*|\s*$/g,"");
	else
		return null;
}

function getName(value) {
	var c = value.lastIndexOf('\/'); //For Unix, etc.
	if (c != -1)
		html = value.substring(c+1);
	else {
		var c = value.lastIndexOf('\\'); //Win
		if (c != -1)
			html = value.substring(c+1);
		else
			html = value;
	}
	return html;
}

function findDuplicateFileName(forminputs) {
	for (var i=0; i<forminputs.length; i++) {
		if (forminputs[i].type == 'file' && forminputs[i].value != '') {
			var name = getName(forminputs[i].value);
			for (var j=i+1; j<forminputs.length; j++) {
				if (forminputs[j].type == 'file' && forminputs[j].value != '') {
					var name2 = getName(forminputs[j].value);
					if (name == name2) {
						alert("Upload filenames cannot be the same. Please remove filename: \n" + name);
						return false;
					}
				}
			}
		}
	}
	return true;
}

// ECC: functions for clipboard actions
function paste()
{
	document.getElementById("clipboard").style.display = "block";
}

function closeClip()
{
	document.getElementById("clipboard").style.display = "none";
}

function clip(op, f)
{
	if (op==2
		&& !confirm("Moving the files from clipboard will delete them from their original tasks.\nDo you want to continue?"))
		return false;
	f.op.value = op;
	f.encoding = "application/x-www-form-urlencoded";
	f.action = "../project/post_clipAction.jsp";
	f.submit();
}
