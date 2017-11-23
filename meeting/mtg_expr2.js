/**
 *******************************************************************************
 *  mtg_expr2.js for mtg_view.jsp
 *  This is a sister routine to mtg_expr1.js
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

var SIZE_OF_QUEUE = 10;

var queueIds  = new Array(SIZE_OF_QUEUE);
var queueFrom = new Array(SIZE_OF_QUEUE);

function showExpr(exprStr)
{
	// the exprStr format: nextIdx@id1:str1@id2:str2 ...
	// the first element nextIdx is the next index on the server expr queue to be read
	if (exprStr==null || exprStr=="")
	{
		if (!showing) dequeue();	// just in case if there are leftover items
		return -1;					// return -1 will not set nextIdx
	}

	exprArr = exprStr.split(":");	// id:str  i.e., divId:userId

	enqueue(exprArr[0], exprArr[1]);
	
	// start to dequeue: note that dequeue is a loop and will finish when there is no item left
	if (!showing)
		dequeue();
}
