function setPointer(theRow, thePointerColor)
{
    if (thePointerColor == '' || typeof(theRow.style) == 'undefined') {
        return false;
    }
    if (typeof(document.getElementsByTagName) != 'undefined') {
        var theCells = theRow.getElementsByTagName('td');
    }
    else if (typeof(theRow.cells) != 'undefined') {
        var theCells = theRow.cells;
    }
    else {
        return false;
    }

    var rowCellsCnt  = theCells.length;
    for (var c = 0; c < rowCellsCnt; c++) {
        theCells[c].style.backgroundColor = thePointerColor;
    }

    return true;
} // end of the 'setPointer()' function

//var zIndex_g=1;
var thislocation;
var elResize="no";

function load(docum)
{
// parent.box_loading.style.display='block';
 box_loading.style.display='block';
 thislocation=docum;
 document.frames[0].location=thislocation;
}

function load_box(docum)
{
 box_loading.style.display='block';
 document.frames[1].location=docum;
}

function base_reload()
{
 alert(thislocation);
 document.frames[0].location='';
 box_loading.style.display='block';
 document.frames[0].location=thislocation;
}

function extract()
{
 document.frames['frm_config'].document.location='save.pl?type=frame&id=frm_base' + '&src='+document.frames['frm_base'].document.location;

 box_loading.style.display='none';
 if (document.frames[0].info != null)
 {
  document.all['base_info'].innerHTML = document.frames[0].info.innerHTML;
 }
 else
 {
  document.all['base_info'].innerHTML = '';
 }
 document.all['divContent'].innerHTML = document.frames[0].document.body.innerHTML;
}


var elDragged = null;

function doMouseMove()
{
// win_move.style.display='block';
 if ((1 == event.button) && (elDragged != null))
 {
  var intTop = event.clientY + document.body.scrollTop;
  var intLeft = event.clientX + document.body.scrollLeft;
  var intLessTop  = 0;
  var intLessLeft = 0;
  var elCurrent = elDragged.offsetParent;
  while (elCurrent.offsetParent != null)
  {
   intLessTop += elCurrent.offsetTop;
   intLessLeft += elCurrent.offsetLeft;
   elCurrent = elCurrent.offsetParent;
  }
  var uprTop= intTop  - intLessTop - elDragged.y;
  var uprLeft= intLeft - intLessLeft  - elDragged.x;

  if (elResize=="yes")
  {
   var plusX = event.x-elDragged.style.pixelLeft;
   var plusY = event.y-elDragged.style.pixelTop;
   win_move.style.width=plusX-5;
   win_move.style.height=plusY-5;
  }
  else
  {
   win_move.style.pixelTop = uprTop;
   win_move.style.pixelLeft = uprLeft;
  }
  event.returnValue = false;
 }
}





function checkDrag(elCheck)
{
 while (elCheck != null)
 {
  if (null != elCheck.getAttribute("drag_here"))
  {
   while (elCheck != null)
   {
    if (null != elCheck.getAttribute("drag")) return elCheck;
	elCheck = elCheck.parentElement;
   }
  }
  elCheck = elCheck.parentElement;
 }      
 return null;
}


function GetDrag(elCheck)
{
 while (elCheck != null)
 {
  if (null != elCheck.getAttribute("drag")) return elCheck;
  elCheck = elCheck.parentElement;
 }
 return null;
}




function doMouseDown()
{
 var elCurrent = checkDrag(event.srcElement);
 // elCurrent je najblizssi object s DRAG
 if (null != elCurrent)
 {
   elResize="no";
   elDragged = elCurrent;
   elDragged.x = event.offsetX;
   elDragged.y = event.offsetY;
   elDragged.mousex=event.x;
   elDragged.mousey=event.y;
   var op = event.srcElement;
   if ((elDragged != op.offsetParent) && (elDragged != event.srcElement))
   {
    while (op != elDragged)
    {
     elDragged.x += op.offsetLeft;
     elDragged.y += op.offsetTop;
     op = op.offsetParent;
    }
   }
   // vytvorim duplikacny object
//   zIndex_g++;
//   win_move.style.zIndex=zIndex_g;

   if (elCurrent.all['box_sub'].style.display=='block')
   {
    if (elCurrent.all['box_sub'].style.width)
    {
//     var setX=elCurrent.all['box_sub'].style.width;
//     var setY=setX.substring(0,setX.length-2);
//     setY=setY+10;
//     win_move.style.width=setY+'px';
     win_move.style.width=elCurrent.all['box_sub'].style.width;
    }else{win_move.style.width='100'}
    if (elCurrent.all['box_sub'].style.height)
    {
     var setY=elCurrent.all['box_sub'].style.height;
     var setY0=setY.substring(0,setY.length-2);
     setY0++;
     setY0=setY0+20;
     win_move.style.height=setY0+'px';
    }else{win_move.style.height='14'}
   }
   else
   {
    win_move.style.width='100';
    win_move.style.height='14';
   }

   win_move.style.top=elCurrent.style.top;
   win_move.style.left=elCurrent.style.left;
   win_move.style.display='block';
   if (event.srcElement.drag_here=='resize'){elResize="yes";}
 }
}





function doMouseUp()
{
// win_move.style.display='none';
 if (elDragged != null)
 {
  if (elDragged.drag_save != null)
  {
   document.frames['frm_config'].document.location='save.pl?type=box' +
   '&id='+elDragged.id +
   '&version='+elDragged.drag_version +
   '&top='+elDragged.style.pixelTop +
   '&left='+elDragged.style.pixelLeft +
   '&width='+elDragged.style.width +
   '&height='+elDragged.style.height +
   '&auto_open='+elDragged.drag_open +
   '&box_sub='+elDragged.all['box_sub'].style.display;
  }
  elDragged.style.top=win_move.style.top;
  elDragged.style.left=win_move.style.left;
//  elDragged.style.zIndex=zIndex_g;
  win_move.style.display='none';


  if (elResize=="yes")
  {

     var setX=win_move.style.width;
     var setX0=setX.substring(0,setX.length-2);
     setX0=setX0-2;
     elDragged.all['box_sub'].style.width=setX0+'px';

     var setY=win_move.style.height;
     var setY0=setY.substring(0,setY.length-2);
     setY0=setY0-22;
     elDragged.all['box_sub'].style.height=setY0+'px';

//    var plusX = event.x-elDragged.style.pixelLeft;
//    var plusY = event.y-elDragged.style.pixelTop;
//    elDragged.style.width=plusX+5;
//    elDragged.style.height=plusY+5;


    for (var i=0; i < elDragged.all['box_sub'].all.length;i++)
    {
     if (null != elDragged.all['box_sub'].all[i].getAttribute("drag_resizeX"))
     {
      var minusX=elDragged.all['box_sub'].all[i].drag_resizeX;
      minusX++;
      minusX--;
      var setX=setX0+minusX-6;
      elDragged.all['box_sub'].all[i].style.width=setX;
     }

     if (null != elDragged.all['box_sub'].all[i].getAttribute("drag_resizeY"))
     {
      var minusY=elDragged.all['box_sub'].all[i].drag_resizeY;
      minusY++;
      minusY--;
      var setY=setY0+minusY-8;
      elDragged.all['box_sub'].all[i].style.height=setY;
     }


//     if (null != elDragged.all['box_sub'].all[i].getAttribute("drag_resizeY"))
//     {
//      var minusY=elDragged.all['box_sub'].all[i].drag_resizeY;
//      minusY++;
//      minusY--;
//      var setY=plusY+minusY;
//      elDragged.all['box_sub'].all[i].style.height=setY;
//     }
    }


  }


  elDragged.style.display='block';
 }
 elDragged=null;
}


function doSelectTest()
{return (null == checkDrag(event.srcElement) && (elDragged!=null));}

//superbase.onmousedown = doMouseDown;
//superbase.onmousemove = doMouseMove;
//superbase.onmouseup = doMouseUp;

document.onmousedown = doMouseDown;
document.onmousemove = doMouseMove;
document.onmouseup = doMouseUp;


//document.onmouseup = new Function("elDragged = null;");
//document.ondragstart = doSelectTest;
//document.onselectstart = doSelectTest;


function box_erase()
{
 var elCurrent = GetDrag(event.srcElement);
 if (null != elCurrent)
 {
  elCurrent.outerHTML='';
 }
}

var elErased=null;
function box_erase2()
{
 elErased = checkDrag(event.srcElement);
 setTimeout('elErased.innerHTML="";',500);
}


function box_extract()
{
 box_loading.style.display='none';
 if (document.frames['frm_micro'].document.body.extract!=null)
 {
	drO = document.createElement("DIV");
	drO.style.position = "absolute";
	drO.drag="range";
	drO.drag_popup="yes";
//	drO.drag_open="true";
//        zIndex_g=zIndex_g+1;
//	drO.style.zIndex=zIndex_g;
//	drO.id=document.frames['frm_micro'].document.body.extract;
	drO.style.pixelLeft = event.clientX  + document.body.scrollLeft;
	drO.style.pixelTop = event.clientY  + document.body.scrollTop;
	drO.style.width=150;
	drO.style.height=11;
	drO.innerHTML=document.frames['frm_micro'].document.body.innerHTML;
	superbase.appendChild(drO);
	document.frames['frm_micro'].document.body.innerHTML='';
 }
}




function create_log(text)
{
 var newop=document.createElement("option");
 newop.text=text;
 log.add(newop);
}
 

function editor_paste_img(what,align,about)
{
 var tr=edit.innerHTML;
 edit.innerHTML='<img src=\"'+what+'-t.jpg\" align='+align+' border=1 alt="'+about+'">'+tr;
}

function editor_paste_img2(what,align,about)
{
 edit.focus();
 document.selection.createRange().pasteHTML('<img src=\"'+what+'-t.jpg\" align='+align+' border=1 alt="'+about+'">');
}

function Toggle(text)
{
 edit.focus();

	if (text == "Bold")
		document.execCommand("Bold");

	else if (text == "Italic")
		document.execCommand("Italic");

	else if (text == "SuperScript")
		document.execCommand("SuperScript");

	else if (text == "SubScript")
		document.execCommand("SubScript");

	else if (text == "Underline")
		document.execCommand("Underline");

	else if (text == "Left")
		document.execCommand("JustifyLeft");

	else if (text == "Center")
		document.execCommand("JustifyCenter");

	else if (text == "Right")
		document.execCommand("JustifyRight");

	else if (text == "Undo")
		document.execCommand("Undo");

	else if (text == "Redo")
		document.execCommand("Redo");

	else if (text == "InsertOrderedList")
		document.execCommand("InsertOrderedList");

	else if (text == "InsertUnorderedList")
		document.execCommand("InsertUnorderedList");

	else if (text == "FontColor")
	{
		theColor = document.all.fontcolor.value;
		if (theColor != "")
			document.execCommand("ForeColor", false, theColor);
	}
		
	else if (text == "FontSize")
	{
		theSize = document.all.fontsize.value;
		if (theSize != "")		
			document.execCommand("FontSize", false, theSize);
	}
		
	else if (text == "FontName")
	{
		theName = document.all.fontname.value;
		if (theName != "")
			document.execCommand("FontName", false, theName);
	}

	else if (text == "InsertImage")
	{
		theImg = document.all.imagepath.value;
		if (theImg != "")
			document.execCommand("InsertImage", false, theImg);
	}
	
	else if (text == "InsertAnchor")
	{
			document.execCommand("CreateLink", false);
	}	
	else if (text == "InsertPage")
	{	
     document.selection.createRange().pasteHTML('<hr style=\'height:6px;background:blue;\'>');
	}
}
