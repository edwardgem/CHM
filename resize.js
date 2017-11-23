/*
 * SOTC Resizeable Textbox Version 1
 * https://www.switchonthecode.com/tutorials/javascript-tutorial-resizeable-textboxes
 * ECC: To use this,
 	- include this JS file
 	- add the following after the window has loaded
 		initDrag();
		new dragObject(handleBottom[0], null, new Position(0, beginHeight),
						new Position(0, 1000), null, BottomMove, null, false, 0);
   If you have more than one textbox on the page, the last param of dragObject can
   go from 0, 1, 2, ...

 */

function Position(x, y)
{
  this.X = x;
  this.Y = y;

  this.Add = function(val)
  {
    var newPos = new Position(this.X, this.Y);
    if(val != null)
    {
      if(!isNaN(val.X))
        newPos.X += val.X;
      if(!isNaN(val.Y))
        newPos.Y += val.Y
    }
    return newPos;
  }

  this.Subtract = function(val)
  {
    var newPos = new Position(this.X, this.Y);
    if(val != null)
    {
      if(!isNaN(val.X))
        newPos.X -= val.X;
      if(!isNaN(val.Y))
        newPos.Y -= val.Y
    }
    return newPos;
  }

  this.Min = function(val)
  {
    var newPos = new Position(this.X, this.Y)
    if(val == null)
      return newPos;

    if(!isNaN(val.X) && this.X > val.X)
      newPos.X = val.X;
    if(!isNaN(val.Y) && this.Y > val.Y)
      newPos.Y = val.Y;

    return newPos;
  }

  this.Max = function(val)
  {
    var newPos = new Position(this.X, this.Y)
    if(val == null)
      return newPos;

    if(!isNaN(val.X) && this.X < val.X)
      newPos.X = val.X;
    if(!isNaN(val.Y) && this.Y < val.Y)
      newPos.Y = val.Y;

    return newPos;
  }

  this.Bound = function(lower, upper)
  {
    var newPos = this.Max(lower);
    return newPos.Min(upper);
  }

  this.Check = function()
  {
    var newPos = new Position(this.X, this.Y);
    if(isNaN(newPos.X))
      newPos.X = 0;
    if(isNaN(newPos.Y))
      newPos.Y = beginHeight;			// ECC: in the beginning, set it to 450
    return newPos;
  }

  this.Apply = function(element)
  {
    if(typeof(element) == "string")
      element = document.getElementById(element);
    if(element == null)
      return;
    if(!isNaN(this.X))
      element.style.left = this.X + 'px';
    if(!isNaN(this.Y))
      element.style.top = this.Y + 'px';
  }
}

function hookEvent(element, eventName, callback)
{
  if(typeof(element) == "string")
    element = document.getElementById(element);
  if(element == null)
    return;
  if(element.addEventListener)
  {
    element.addEventListener(eventName, callback, false);
  }
  else if(element.attachEvent)
    element.attachEvent("on" + eventName, callback);
}

function unhookEvent(element, eventName, callback)
{
  if(typeof(element) == "string")
    element = document.getElementById(element);
  if(element == null)
    return;
  if(element.removeEventListener)
    element.removeEventListener(eventName, callback, false);
  else if(element.detachEvent)
    element.detachEvent("on" + eventName, callback);
}

function cancelEvent(e)
{
  e = e ? e : window.event;
  if(e.stopPropagation)
    e.stopPropagation();
  if(e.preventDefault)
    e.preventDefault();
  e.cancelBubble = true;
  e.cancel = true;
  e.returnValue = false;
  return false;
}

function getMousePos(eventObj)
{
  eventObj = eventObj ? eventObj : window.event;
  var pos;
  if(isNaN(eventObj.layerX))
    pos = new Position(eventObj.offsetX, eventObj.offsetY);
  else
    pos = new Position(eventObj.layerX, eventObj.layerY);
  return correctOffset(pos, pointerOffset, true);
}

function getEventTarget(e)
{
  e = e ? e : window.event;
  return e.target ? e.target : e.srcElement;
}

function absoluteCursorPostion(eventObj)
{
  eventObj = eventObj ? eventObj : window.event;

  if(isNaN(window.scrollX))
    return new Position(eventObj.clientX + document.documentElement.scrollLeft + document.body.scrollLeft,
      eventObj.clientY + document.documentElement.scrollTop + document.body.scrollTop);
  else
    return new Position(eventObj.clientX + window.scrollX, eventObj.clientY + window.scrollY);
}

/**
	dragObject()
*/
function dragObject(element, attachElement, lowerBound, upperBound,
					startCallback, moveCallback, endCallback, attachLater,
					idx)
{
  if(typeof(element) == "string")
    element = document.getElementById(element);

  if(lowerBound != null && upperBound != null)
  {
    var temp = lowerBound.Min(upperBound);
    upperBound = lowerBound.Max(upperBound);
    lowerBound = temp;
  }

  var cursorStartPos = null;
  var elementStartPos = null;
  var dragging = false;
  var listening = false;
  var disposed = false;

  function dragStart(eventObj)
  {
    if(dragging || !listening || disposed) return;
    dragging = true;

    if(startCallback != null)
      startCallback(eventObj, element);

    cursorStartPos = absoluteCursorPostion(eventObj);

    elementStartPos = new Position(parseInt(element.style.left), parseInt(element.style.top));
	// debugOut(elementStartPos.Y + " " + new Date());

    elementStartPos = elementStartPos.Check();

    hookEvent(document, "mousemove", dragGo);
    hookEvent(document, "mouseup", dragStopHook);

    return cancelEvent(eventObj);
  }

  function dragGo(eventObj)
  {
    if(!dragging || disposed) return;

    var newPos = absoluteCursorPostion(eventObj);
    newPos = newPos.Add(elementStartPos).Subtract(cursorStartPos);
    newPos = newPos.Bound(lowerBound, upperBound);
    newPos.Apply(element);

    if(moveCallback != null)
      moveCallback(newPos, element, idx);

    return cancelEvent(eventObj);
  }

  function dragStopHook(eventObj)
  {
    dragStop();
    
    // save the winHeight cookie if needed.  Caller must first call setCookieName()
    if (winHeightCookie != null) {
    	setCookieNow(winHeightCookie, element.style.top);
    }
    
    return cancelEvent(eventObj);
  }

  function dragStop()
  {
    if(!dragging || disposed) return;
    unhookEvent(document, "mousemove", dragGo);
    unhookEvent(document, "mouseup", dragStopHook);
    cursorStartPos = null;
    elementStartPos = null;
    if(endCallback != null)
      endCallback(element);
    dragging = false;
  }

  this.Dispose = function()
  {
    if(disposed) return;
    this.StopListening(true);
    element = null;
    attachElement = null
    lowerBound = null;
    upperBound = null;
    startCallback = null;
    moveCallback = null
    endCallback = null;
    disposed = true;
  }

  this.StartListening = function()
  {
    if(listening || disposed) return;
    listening = true;
    hookEvent(attachElement, "mousedown", dragStart);
  }

  this.StopListening = function(stopCurrentDragging)
  {
    if(!listening || disposed) return;
    unhookEvent(attachElement, "mousedown", dragStart);
    listening = false;

    if(stopCurrentDragging && dragging)
      dragStop();
  }

  this.IsDragging = function(){ return dragging; }
  this.IsListening = function() { return listening; }
  this.IsDisposed = function() { return disposed; }

  if(typeof(attachElement) == "string")
    attachElement = document.getElementById(attachElement);
  if(attachElement == null)
    attachElement = element;

  if(!attachLater)
  {
    this.StartListening();
  }
}

function BottomMove(newPos, element, i)
{
  DoHeight(newPos.Y, element, i);
}

// not call now
function RightMove(newPos, element)
{
  DoWidth(newPos.X, element);
}

// not call now
function CornerMove(newPos, element)
{
  DoHeight(newPos.Y, element);
  DoWidth(newPos.X, element);
}

function DoHeight(y, element, i)
{
  //textDiv.style.height = (y + 5) + 'px';

 /*
  if(element != handleCorner)
    handleCorner.style.top = y + 'px';

  handleRight.style.height = y + 'px';
*/
  if(element != handleBottom[i])
    handleBottom[i].style.top = y + 'px';

  //textBox.style.height = (y - 5) + 'px';
  var e = document.getElementById(textBoxId + '___Frame');
  if (e != undefined)
  	e.style.height = (y) + 'px';
  else
  	textBox[i].style.height = (y) + 'px';
}

// not call now because we only drag on Y-axis
function DoWidth(x, element)
{
  if (true)
	  return;
  textDiv.style.width =  (x + 5) + 'px';

  if(element != handleCorner)
    handleCorner.style.left = x + 'px';

  if(element != handleRight)
    handleRight.style.left = x + 'px';

  handleBottom.style.width = x + 'px';

  textBox.style.width = (x - 5) + 'px';
}

// initDrag() must be called after the widgets are defined
function initDrag(h, idx)
{
	if (h != null) {
		var initHeight = 0;
		h = "" + h;
		if (h.indexOf("px")!=-1) {
			h = h.replace("px", "");
		}
		initHeight = parseInt(h);
		setBeginHeight(initHeight);
	}

	if (idx != null) {
		textBox[idx] = document.getElementById(textBoxId + idx);
		handleBottom[idx] = document.getElementById("handleBottom" + idx);
	}
	else {
		// assume caller doesn't use indexing on widget ID
		textBox[0] = document.getElementById(textBoxId);
		handleBottom[0] = document.getElementById("handleBottom");
		//textDiv[0] = document.getElementById("textDiv");
	}
	debugX = document.getElementById("debugX");
}

function setBeginHeight(h) {beginHeight = h;}
function debugOut(s) {debugX.innerHTML = s;}
function setTextBoxId(id) {textBoxId = id;}		// default is mtgText
function setCookieName(name) {winHeightCookie = name;}	// if caller wants to save drag position

var textBox = new Array();
var handleBottom = new Array();
//var textDiv = new Array();

var debugX;
var beginHeight = 450;	// default initial textbox height
var winHeightCookie = null;

// the following needs to be positioned after the widgets are defined
// use textBox to support non-FDK box dragging
var textBoxId = "mtgText";
/*
var textBox = document.getElementById("mtgText");

var handleBottom = document.getElementById("handleBottom");
var textDiv = document.getElementById("textDiv");
var debugX = document.getElementById("debugX");
*/

// need this to initiate the dragging action
//new dragObject(handleBottom, null, new Position(0, beginHeight), new Position(0, 1000), null, BottomMove, null, false);

//var handleRight = document.getElementById("handleRight");
//var handleCorner = document.getElementById("handleCorner");
//new dragObject(handleRight, null, new Position(15, 0), new Position(620, 0), null, RightMove, null, false);
//new dragObject(handleCorner, null, new Position(15, 15), new Position(620, 400), null, CornerMove, null, false);
