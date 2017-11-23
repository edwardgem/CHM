/**
 *******************************************************************************
 *  mtg_expr1.js for mtg_live.jsp
 *  This is a sister routine to mtg_expr2.js
 *  mtg_expr1.js is for mtg_live.jsp while mtg_expr2.js is for mtg_view.jsp
 *  Finally, mtg_expr.js is a common file for both 1 and 2.
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

var SIZE_OF_QUEUE = 100;

var queueIds  = new Array(SIZE_OF_QUEUE);
var queueFrom = new Array(SIZE_OF_QUEUE);

function sendExpr(str)
{
	var thisId = "";
	var e = document.getElementById("expression");
	var f1 = null;
	var f2;
	for (i=0; i<e.length; i++)
	{
		if (e.options[i].selected)
		{
			thisId = e.options[i].value;
			break;
		}
	}
	if (thisId != "")
	{
		// call Ajax to submit expression over
		ajaxMFCSendExpr(thisId, str);
	}
	else
	{
		alert("Please select an expression you want to send");
	}
}

function recvExpr(exprStr)
{
	// this is constructed by PrmMtgParticipants.doGet() >> MeetingParticipants.getUnreadExpr()
	// the exprStr format: nextIdx@@id1:str1@@id2:str2 ...
	// the first element nextIdx is the next index on the server expr queue to be read
	if (exprStr==null || exprStr=="")
	{
		if (!showing) dequeue();	// just in case if there are leftover items
		return -1;					// return -1 will not set nextIdx
	}

	exprStr = exprStr.join("");
	exprPairArr = exprStr.split("@@");
	var nextIdx = parseInt(exprPairArr[0]+"");
	var len = exprPairArr.length;

	for (i=1; i<len; i++)
	{
		exprArr = exprPairArr[i].split(":");		// id:str:color
		enqueue(exprArr[0], exprArr[1]);
	}
	
	// insert the expression into the meeting note chat text
	if (isOn && len > 1 && exprStr.indexOf("typing")==-1)
	{
		var nodeArr = new Array(1);
		var s = exprArr[0];
		if (s=="ques") s = "question";
		else if (s=="thank") s = "thanks";
		else if (s=="hand") s = "raise hand";
		var dispName = exprArr[1];
		if ((idx=dispName.indexOf("@")) != -1) dispName = dispName.substring(0, idx);
		s = dispName + ": " + s;
		nodeArr[0] = "<div style='font-size:14px; font-weight:normal; text-indent:20px; line-height:25px; color:" + exprArr[2] +";'>" + s + "</div>";
		setElementInnerHTMLMtgNotes("meetingNotes", nodeArr);
	}
	
	// start to dequeue: note that dequeue is a loop and will finish when there is no item left
	if (!showing)
		dequeue();
	
	return nextIdx;
}



/**************** INPUT QUEUE ******************/
function sendInputQueue(uid, opt)
{

	var bRemove = false;			// remove this uid from the queue?
	if (opt!=null && opt=='remove')
	{
		if (!confirm("Are you sure you want to remove " + uid + " from the input queue?"))
			return;
		bRemove = true;
	}
	if (!isGuest)
		ajaxMFCSendQueue(uid, bRemove);
	else
		alert("Please login to participate in this meeting.");
}

function updateInputQueue(queStr)
{
	var len = 0;
	var queArr;
	if (queStr==null)
	{
		queStr = "";
	}
	else
	{
		queStr = queStr.join("");	// format of string edwardc:allenq: ...
		queArr = queStr.split(":");
		len = queArr.length;
	}
	var foundSelf = false;
	var nxt = 0;
	var dispName, idx;
	
	// check the first element to see if there is a current Q input user
	if (len>0 && queArr[0]!="" && queArr[0].charAt(0)=="*")
	{
		nxt = 1;
	}

	var str = "<table width='100%' border='0' cellspacing='0' cellpadding='0'>";
	str += "<tr><td class='plaintext_blue' align='center' colspan='3'>";
	str += "<b>Input<br>Queue</b></td></tr>";
	
	str += "<tr><td colspan='3'><img src='../i/spacer.gif' height='15'></td></tr>";

	if (isFacilitator)
	{
		// facilitator
		if (len-nxt>0 && queArr[nxt]!="")
		{
			inputQhead = queArr[nxt];			// remember the head person
			for (i=nxt; i<len; i++)
			{
				if ((idx = queArr[i].indexOf("@")) != -1)		// in case of email format username
					dispName = queArr[i].substring(0, idx);
				else
					dispName = queArr[i];
				str += "<tr><td class='plaintext'>[</td>";
				str += "<td width='80' align='center' title='Click to enable only this person to enter input'>";
				str += "<a href='javascript:enableInputQHead(\""
						+ midS + "\", 1, \"" + queArr[i] + "\");' class='listlink'>" + dispName + "</a></td>";
				str += "<td class='plaintext'>]</td></tr>";
			}
			
			// after showing all queuing users' name, add buttons for All People and All of the Above
			str += "<tr><td colspan='3'>&nbsp;</td></tr>";
			
			// all of above
			str += "<tr><td class='plaintext'>[</td>";
			str += "<td width='80' align='center' title='Click to enable all of the above users in the queue to enter input'>";
			str += "<a href='javascript:enableInputQHead(\"" + midS + "\", 2);' class='listlink'><b>All Above</b></a></td>";
			str += "<td class='plaintext'>]</td></tr>";
		}
			
		// all users: may be pressed to include all newly sign-on users
		str += "<tr><td class='plaintext'>[</td>";
		str += "<td width='80' align='center' title='Click to enable all online participants to enter input'>";
		str += "<a href='javascript:enableInputQHead(\"" + midS + "\", 3);' class='listlink'><b>All&nbsp;&nbsp;Users</b></a></td>";
		str += "<td class='plaintext'>]</td></tr>";
		
		if (isOn)
		{
			// allow to STOP input
			str += "<tr><td class='plaintext'>[</td>";
			str += "<td width='80' align='center' title='Click to END all participants from entering input'>";
			str += "<a href='javascript:enableInputQHead(\"" + midS + "\", 0, \"all\");' class='listlink'><font color='dd0000'><b>Stop</b></font></a></td>";
			str += "<td class='plaintext'>]</td></tr>";
		}
	}
	else
	{
		// I am not facilitator
		for (i=nxt; i<len; i++)
		{
			if (queArr[i] == "") break;
			if ((idx = queArr[i].indexOf("@")) != -1)	// in case of email format username
				dispName = queArr[i].substring(0, idx);
			else
				dispName = queArr[i];

			str += "<tr><td class='plaintext'>[</td>";
			str += "<td width='80' align='center' ";
			if (myObjName == queArr[i])
			{
				// this is my name on the queue
				foundSelf = true;
				str += "title='Click to remove yourself from the queue'>";
				str += "<a href='javascript:sendInputQueue(\""
						+ myObjName + "\", \"remove\");' class='listlink'>" + dispName + "</a></td>";
			}
			else
			{
				str += "class='plaintext'>" + dispName + "</td>";
			}
			str += "<td class='plaintext'>]</td></tr>";
		}
		if (len<10 && !foundSelf)
		{
			str += "<tr><td class='plaintext'>[</td>";
			str += "<td class='listlink' width='80' align='center'><a href='javascript:sendInputQueue(\""
					+ myObjName + "\");'><b>Enter</b></a></td>";
			str += "<td class='plaintext'>]</td></tr>";
		}
	}
	str += "</table>";
	
	var e = document.getElementById("InputQTable");
	e.innerHTML = str;
}

// enableInputQHead(): can be enable or disable or replace
// opt=0 (stop); opt=1 (enable or replace with next); opt=2 (enable all queuing users);
// opt=3 (enable all participants); opt=4 (add this uidS to the chat session)
function enableInputQHead(midS, opt, uidS)
{
	// get cursor position
	if (isRun == 1) {
		// Save meetings notes when facilitator clicks to invite participants
		setCursorIndex();
		ajaxMtgNotes(false);
	}
	if (uidS == null)
		uidS = inputQhead;
	
	var typeOption;
	if (opt == 0)
	{
		if (uidS == "all")
			typeOption = '&type=facilitator&qInput=stop';	// stop all
		else
			typeOption = '&type=selectParticipants&qInput=stop&uname=' + uidS;	// stop all
	}
	else if (opt == 1)	// opt=1(enable or replace)
		typeOption = '&type=selectParticipants&seconds=0&qInput=enable&uname=' + uidS;
	else if (opt == 2)
		typeOption = '&type=selectParticipants&seconds=0&qInput=queue';
	else if (opt == 3)
		typeOption = '&type=allParticipants&seconds=0&qInput=all';
	else if (opt == 4)
		typeOption = '&type=selectParticipants&seconds=0&qInput=add&uname=' + uidS;

	// call post page
	location = 'post_mtg_invite.jsp?mid=' + midS + '&pos='+position+'&charBefore='+charBefore
		+ '&charAfter='+charAfter + typeOption;
}

