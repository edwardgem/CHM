/**
 *******************************************************************************
 *  mtg_expr.js
 *  This is a common, needed file for both mtg_expr1.js and mtg_expr2.js
 *  mtg_expr1.js is for mtg_live.jsp while mtg_expr2.js is for mtg_view.jsp
 *
 *	The caller JSP should have the following DIV defined.  The ID and FROM must match the
 *	parameters passed back from Ajax.  The position will needs to be adjusted.  Note:
 *  1.  The first DIV has id="ID" and the second DIV has id="ID1", and the text part has id="ID2". 
 *	2.  The @FROM@ will be replayed by the from string passed from servlet to the JSP through Ajax.
 *
	<div id="hand" style="position:fixed; width: 10px; left: -120; top: 50; filter:alpha(opacity=0); opacity: 0.0; -moz-opacity: 0.0; display:none">
	<img src="../i/hand.jpg" border="0" alt="hand" />
	</div>
	<div id="hand1" style="position:fixed; width: 10px; left: -110; top: 0; filter:alpha(opacity=0); opacity: 0.0; -moz-opacity: 0.0; display:none;">
	<span id="hand2" class='plaintext_blue'>@FROM@:<br>Raised Hand</span>
	</div>
 *
 *******************************************************************************
**/

var head = -1;	// the next element to be shown
var tail = 0;	// the next position to insert a new element

var showing = false;

var DEFAULT_USER_PIC = "../i/pigHead.jpg";

function enqueue(id, str)
{
	// insert an expression request to the queue to be shown for this client
	var newTail = (tail + 1) % SIZE_OF_QUEUE;
	if (head == newTail) return;	// the queue is full, simply return
	
	queueIds[tail] = id;
	queueFrom[tail] = str;
	tail = newTail;
	if (head < 0) head = 0;			// initialize the queue
}

function dequeue()
{
	// dequeue() is called by recvExpr() and by the subsequent call of dequeue()
	// dequeue() is only a beginning, through delay timers, it will call showExpr1, 2 and 3 and then to dequeue()
	//while (showing) {setTimeout("dequeue()", 1500);}	// this way of synchronization may not work but there is no harm

	if (head < 0 || head == tail)		// nothing to be shown
	{
		// dequeue will call itself until there is no more items left on queue
		showing = false;
		return;
	}
	showing = true;

	// show the expression for a period of time and then unshow it
	showExpr1(queueIds[head],queueFrom[head]);
	head = (head+1) % SIZE_OF_QUEUE;
}

function showExpr1(thisId, fm)
{
	var f1 = document.getElementById(thisId);			// image  DIV
	var f2 = document.getElementById(thisId + '1');		// message DIV
	var f3 = document.getElementById(thisId + '2');		// message SPAN (for changing text)
	
	if (thisId=="typing")
	{
		fm = checkPic(fm);
		if (fm == screenName)
		{
			setTimeout("dequeue();", 1000);		// just in case if there are other expr on the queue
			return;								// ignore my own typing expr
		}
	}

	if (f1 != null)
	{
		// insert the FROM string into the SPAN
		var s;
		// @AGQ100306
		if(document.all){ // IE
			s = f3.innerText;
		} else{ // FF
			s = f3.textContent;
		}
		if ((idx=fm.indexOf("@"))!=-1) fm = fm.substring(0, idx);
		s = s.replace(/@FROM@/, fm);
		// @AGQ100306
		if(document.all){ // IE
			f3.innerText = s;
		} else{ // FF
			f3.textContent = s;
		}
		
		// show the image and msg
		f1.style.display = 'inline';
		f2.style.display = 'inline';
		opacity(thisId, 0, 100, 1500);
		opacity(thisId+'1', 0, 100, 1500);
		
		setTimeout("showExpr2('" + thisId + "', '" + fm + "');", 4000);		// let the image/msg stay for 4 seconds
	}
}

function showExpr2(id, fm)
{
	var thisId = id + "";
	
	// now remove the image and msg
	opacity(thisId, 100, 0, 2000);
	opacity(thisId+'1', 100, 0, 2000);
	
	setTimeout("showExpr3('" + thisId + "', '" + fm + "');", 2000);		// wait for 2 seconds for image to be gone
}

function showExpr3(id, fm)
{
	var thisId = id + "";
	var f1 = document.getElementById(thisId);			// image  DIV
	var f2 = document.getElementById(thisId + '1');		// message DIV
	var f3 = document.getElementById(thisId + '2');		// message SPAN (for changing text)
	
	//if (thisId=="typing")
	//	fm = checkPic(fm);
	f1.style.display = 'none';
	f2.style.display = 'none';
	var s;
	if(document.all){ // IE
		s = f3.innerText;
	} else{ // FF
		s = f3.textContent;
	}
	s = s.replace(fm, "@FROM@");
	// @AGQ100306
	if(document.all){ // IE
		f3.innerText = s;
	} else{ // FF
		f3.textContent = s;
	}	
	dequeue();											// back to dequeue
}

function opacity(id, opacStart, opacEnd, millisec) { 
    //speed for each frame 
    var speed = Math.round(millisec / 100); 
    var timer = 0; 

    //determine the direction for the blending, if start and end are the same nothing happens 
    if(opacStart > opacEnd) { 
        for(i = opacStart; i >= opacEnd; i--) { 
            setTimeout("changeOpac(" + i + ",'" + id + "')",(timer * speed)); 
            timer++; 
        } 
    } else if(opacStart < opacEnd) { 
        for(i = opacStart; i <= opacEnd; i++) 
            { 
            setTimeout("changeOpac(" + i + ",'" + id + "')",(timer * speed)); 
            timer++; 
        } 
    }
}

//change the opacity for different browsers 
function changeOpac(opacity, id) { 
    var object = document.getElementById(id).style;
    object.opacity = (opacity / 100); 
    object.MozOpacity = (opacity / 100); 
    object.KhtmlOpacity = (opacity / 100); 
    object.filter = "alpha(opacity=" + opacity + ")";
}

function checkPic(fm)
{
	var e = document.getElementById("typingIMG");
	var idx = fm.indexOf(".");
	if (idx == -1)
		e.src = DEFAULT_USER_PIC;
	else
	{
		e.src = jUSER_PIC_URL + "/" + fm;
		fm = fm.substring(0, idx);
	}
	return fm;
}

