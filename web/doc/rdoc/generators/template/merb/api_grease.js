
function setupPage(){
	hookUpActiveSearch();
	hookUpTabs();
	suppressPostbacks();
	var url_params = getUrlParams();
	if (url_params != null){
		loadUrlParams(url_params);
	}else{
		loadDefaults();
	}
	resizeDivs();
	window.onresize = function(){  resizeDivs(); };
}

function getUrlParams(){
	var window_location = window.location.href
	var param_pos = window_location.search(/\?/)
	if (param_pos > 0){
		return(window_location.slice(param_pos, window_location.length));
	}else{
		return(null);
	}
}

function loadUrlParams(url_param){
	//get the tabs
	var t = getTabs();
	// now find our variables
	var s_params = /(\?)(a=.+?)(&)(name=.*)/;
	var results = url_param.match(s_params);
	url_anchor = results[2].replace(/a=/,'');

	if (url_anchor.match(/M.+/)){//load the methods tab and scroller content
		setActiveTabAndLoadContent(t[0]);
	}else{
		if(url_anchor.match(/C.+/)){ //load the classes tab and scroller content
			setActiveTabAndLoadContent(t[1]);
		}else{
			if (url_anchor.match(/F.+/)){//load the files tab
				setActiveTabAndLoadContent(t[2]);
			}else{
				// default to loading the methods
				setActiveTabAndLoadContent(t[0]);
			}
		}
	}
	paramLoadOfContentAnchor(url_anchor + "_link");
}

function updateUrlParams(anchor_id, name){
	//Also setting the page title
	//window.document.title = name + " method - MerbBrain.com ";
	
	//updating the window location
	var current_href = window.location.href;
	//var m_name = name.replace("?","?");
	var rep_str = ".html?a=" + anchor_id + "&name=" + name;
	var new_href = current_href.replace(/\.html.*/, rep_str);
	if (new_href != current_href){
		window.location.href = new_href;
	}
}

//does as it says...
function hookUpActiveSearch(){
	
	var s_field = $('searchForm').getInputs('text')[0];
	//var s_field = document.forms[0].searchText;
	Event.observe(s_field, 'keydown', function(event) {
		var el = Event.element(event);
		var key = event.which || event.keyCode;
		
		switch (key) {
			case Event.KEY_RETURN:
				forceLoadOfContentAnchor(getCurrentAnchor());
				Event.stop(event);
			break;
			
			case Event.KEY_UP:
				scrollListToElementOffset(getCurrentAnchor(),-1);
			break;
			
			case Event.KEY_DOWN:
				scrollListToElementOffset(getCurrentAnchor(),1);
			break;
			
			default:
			break;
		}

	});
	
	Event.observe(s_field, 'keyup', function(event) {
		var el = Event.element(event);
		var key = event.which || event.keyCode;
		switch (key) {
			case Event.KEY_RETURN:
				Event.stop(event);
			break;
			
			case Event.KEY_UP:
			break;
			
			case Event.KEY_DOWN:
			break;
			
			default:
				scrollToName(el.value);
				setSavedSearch(getCurrentTab(), el.value);
			break;
		}
		
	});
	
	Event.observe(s_field, 'keypress', function(event){
		var el = Event.element(event);
		var key = event.which || event.keyCode;
		switch (key) {
			case Event.KEY_RETURN:
				Event.stop(event);
			break;
			
			default:
			break;
		}
		
	});
	
	//Event.observe(document, 'keypress', function(event){
	//	var key = event.which || event.keyCode;
	//	if (key == Event.KEY_TAB){
	//		cycleNextTab();
	//		Event.stop(event);
	//	}
	//});
}

function hookUpTabs(){
	
	var tabs = getTabs();
	for(x=0; x < tabs.length; x++)
	{
		Event.observe(tabs[x], 'click', function(event){
			    var el = Event.element(event);
         		setActiveTabAndLoadContent(el);
			});
		//tabs[x].onclick = function (){ return setActiveTabAndLoadContent(this);};	 //the prototype guys say this is bad..
	}

}

function suppressPostbacks(){
	Event.observe('searchForm', 'submit', function(event){
		Event.stop(event);
	});
}

function loadDefaults(){
	var t = getTabs();
	setActiveTabAndLoadContent(t[0]); //default loading of the first tab
}

function resizeDivs(){
	var inner_height = 700; 
	if (window.innerHeight){
		inner_height = window.innerHeight; //all browsers except IE use this to determine the space available inside a window. Thank you Microsoft!!
	}else{
		if(document.documentElement.clientHeight > 0){ //IE uses this in 'strict' mode
		inner_height = document.documentElement.clientHeight;
		}else{
			inner_height = document.body.clientHeight; //IE uses this in 'quirks' mode 
		}
	}
	$('rdocContent').style.height = (inner_height - 92) + "px";//Thankfully all browsers can agree on how to set the height of a div
	$('listScroller').style.height = (inner_height - 88) + "px";
}

//The main function for handling clicks on the tabs
function setActiveTabAndLoadContent(current_tab){
	changeLoadingStatus("on");
	var tab_string = String(current_tab.innerHTML).strip(); //thank you ProtoType!
	switch (tab_string){
		case "classes":
			setCurrentTab("classes");
		    loadScrollerContent('fr_class_index.html');
			setSearchFieldValue(getSavedSearch("classes"));
			scrollToName(getSavedSearch("classes"));
			setSearchFocus();
			break;
		
		case "files":
			setCurrentTab("files");
		    loadScrollerContent('fr_file_index.html');
			setSearchFieldValue(getSavedSearch("files"));
			scrollToName(getSavedSearch("files"));
			setSearchFocus();
			break;
			
		case "methods":
			setCurrentTab("methods");
			loadScrollerContent('fr_method_index.html');
			setSearchFieldValue(getSavedSearch("methods"));
			scrollToName(getSavedSearch("methods"));
			setSearchFocus();
			break;
		
		default:
			break;
	}
	changeLoadingStatus("off");
}

function cycleNextTab(){
	var currentT = getCurrentTab();
	var tabs = getTabs();
	if (currentT == "methods"){
		setActiveTabAndLoadContent(tabs[1]);
		setSearchFocus();
	}else{
		if (currentT == "classes"){
			setActiveTabAndLoadContent(tabs[2]);
			setSearchFocus();
		}else{
			if (currentT == "files"){
				setActiveTabAndLoadContent(tabs[0]);
				setSearchFocus();
			}
		}
	}
}

function getTabs(){
	return($('groupType').getElementsByTagName('li'));
}

var Active_Tab = "";
function getCurrentTab(){
	return Active_Tab;
}

function setCurrentTab(tab_name){
	var tabs = getTabs();
	for(x=0; x < tabs.length; x++)
	{
		if(tabs[x].innerHTML.strip() == tab_name) //W00t!!! String.prototype.strip!
		{
			tabs[x].className = "activeLi";
			Active_Tab = tab_name;
		}
		else
		{
			tabs[x].className = "";
		}
	}
}

//These globals should not be used globally (hence the getters and setters)
var File_Search = "";
var Method_Search = "";
var Class_Search = "";
function setSavedSearch(tab_name, s_val){
	switch(tab_name){
		case "methods":
			Method_Search = s_val;
			break;
		case "files":
			File_Search = s_val;
			break;
		case "classes":
			Class_Search = s_val;
			break;
	}
}

function getSavedSearch(tab_name){
	switch(tab_name){
		case "methods":
			return (Method_Search);
			break;
		case "files":
			return (File_Search);
			break;
		case "classes":
			return (Class_Search);
			break;
	}
}

//These globals handle the history stack


function setListScrollerContent(s){
	
	$('listScroller').innerHTML = s;
}

function setMainContent(s){
	
	$('rdocContent').innerHTML = s;
}

function setSearchFieldValue(s){
	
	document.forms[0].searchText.value = s;
}

function getSearchFieldValue(){
	
	return Form.Element.getValue('searchText');
}

function setSearchFocus(){
	
	document.forms[0].searchText.focus();
}

var Anchor_ID_Of_Current = null; // holds the last highlighted anchor tag in the scroll lsit
function getCurrentAnchor(){
	return(Anchor_ID_Of_Current);
}

function setCurrentAnchor(a_id){
	Anchor_ID_Of_Current = a_id;
}

//var Index_Of_Current = 0; //holds the last highlighted index
//function getCurrentIndex(){
//	return (Index_Of_Current);
//}

//function setCurrentIndex(new_i){
//	Index_Of_Current = new_i;
//}

function loadScrollerContent(url){

	var scrollerHtml = new Ajax.Request(url, {
	  asynchronous: false,
	  method: 'get',
	  onComplete: function(method_data) {
	   	setListScrollerContent(method_data.responseText);
	  }
	});

}

//called primarily from the links inside the scroller list
//loads the main page div then jumps to the anchor/element with id
function loadContent(url, anchor_id){
	
	var mainHtml = new Ajax.Request(url, {
	 method: 'get',
	  onLoading: changeLoadingStatus("on"),
	  onSuccess: function(method_data) {
	   	setMainContent(method_data.responseText);},
	  onComplete: function(request) {
			changeLoadingStatus("off");
			new jumpToAnchor(anchor_id);
		}
	});
}

//An alternative function that also will stuff the index history for methods, files, classes
function loadIndexContent(url, anchor_id, name, scope)
{
	if (From_URL_Param == true){
		var mainHtml = new Ajax.Request(url, {
			method: 'get',
			onLoading: changeLoadingStatus("on"),
			onSuccess: function(method_data) {
				setMainContent(method_data.responseText);},
				onComplete: function(request) {
					changeLoadingStatus("off");
					updateBrowserBar(name, anchor_id, scope);
					new jumpToAnchor(anchor_id);}
			});
		From_URL_Param = false;
	}else{
		updateUrlParams(anchor_id, name);
	}

}

function updateBrowserBar(name, anchor_id, scope){
	if (getCurrentTab() == "methods"){
		$('browserBarInfo').update("<small>class/module:</small>&nbsp;<a href=\"#\" onclick=\"jumpToTop();\">" + scope + "</a>&nbsp;&nbsp;<small>method:</small>&nbsp;<strong><a href=\"#\" onclick=\"jumpToAnchor('"+ anchor_id +"')\">" + name + "</a></strong> ");
	}else{ if(getCurrentTab() == "classes"){
			$('browserBarInfo').update("<small>class/module:</small>&nbsp;<a href=\"#\" onclick=\"jumpToTop();\">" + scope + "::" + name + "</strong> ");
		}else{
			$('browserBarInfo').update("<small>file:</small>&nbsp;<a href=\"#\" onclick=\"jumpToTop();\">" + scope + "/" + name + "</strong> ");
		}
	}
}


// Force loads the contents of the index of the current scroller list. It does this by
// pulling the onclick method out and executing it manually.
function forceLoadOfContent(index_to_load){
	var scroller = $('listScroller');
	var a_array = scroller.getElementsByTagName('a');
	if ((index_to_load >= 0) && (index_to_load < a_array.length)){
		var load_element = a_array[index_to_load];
		var el_text = load_element.innerHTML.strip();
		setSearchFieldValue(el_text);
		setSavedSearch(getCurrentTab(), el_text);
		eval("new " + load_element.onclick);
	}
}

function forceLoadOfContentAnchor(anchor_id){
	
	var load_element = $(anchor_id);
	if (load_element != null){
		var el_text = load_element.innerHTML.strip();
		setSearchFieldValue(el_text);
		scrollToAnchor(anchor_id);
		setSavedSearch(getCurrentTab(), el_text);
		eval("new " + load_element.onclick);
	}
}

var From_URL_Param = false;
function paramLoadOfContentAnchor(anchor_id){
	From_URL_Param = true;
	forceLoadOfContentAnchor(anchor_id);
}

//this handles the up/down keystrokes to move the selection of items in the list
function scrollListToElementOffset(anchor_id, offset){
	var scroller = $('listScroller');
	var a_array = scroller.getElementsByTagName('a');
	var current_index = findIndexOfAnchor(a_array, anchor_id);
	if ((current_index >= 0) && (current_index < a_array.length)){
		scrollListToAnchor(a_array[current_index + offset].id);
		setListActiveAnchor(a_array[current_index + offset].id);
	}
}

function findIndexOfAnchor(a_array, anchor_id){
	var found=false;
	var counter = 0;
	while(!found && counter < a_array.length){
		if (a_array[counter].id == anchor_id){
			found = true;
		}else{
			counter +=1;
		}
	}
	return(counter);
}

function scrollToName(searcher_name){

	var scroller = $('listScroller');
	var a_array = scroller.getElementsByTagName('a');

	if (!searcher_name.match(new RegExp(/\s+/))){ //if searcher name is blank
		
		var searcher_pattern = new RegExp("^"+searcher_name, "i"); //the "i" is for case INsensitive
		var found_index = -1;

		var found = false;
		var x = 0;
		while(!found && x < a_array.length){
			if(a_array[x].innerHTML.match(searcher_pattern)){
				found = true;
				found_index = x;
			}
			else{
				x++;
			}
		}

		// // an attempt at binary searching... have not given up on this yet...
		//found_index = binSearcher(searcher_pattern, a_array, 0, a_array.length);

		if ((found_index >= 0) && (found_index < a_array.length)){

			scrollListToAnchor(a_array[found_index].id);//scroll to the item
			setListActiveAnchor(a_array[found_index].id);//highlight the item
		}
	}else{ //since searcher name is blank 
		//scrollListToIndex(a_array, 0);//scroll to the item
		//setListActiveItem(a_array, 0);//highlight the item
	}
}

function scrollToAnchor(anchor_id){
	var scroller = $('listScroller');
	if ($(anchor_id) != null){
		scrollListToAnchor(anchor_id);
		setListActiveAnchor(anchor_id);
	}
}

function getY(element){
	
	var y = 0;
	for( var e = element; e; e = e.offsetParent)//iterate the offset Parents
	{
		y += e.offsetTop; //add up the offsetTop values
	}
	//for( e = element.parentNode; e && e != document.body; e = e.parentNode)
	//	if (e.scrollTop) y -= e.scrollTop; //subtract scrollbar values
	return y;
}

//function setListActiveItem(item_array, active_index){
//	
//	item_array[getCurrentIndex()].className = "";
//	setCurrentIndex(active_index);
//	item_array[getCurrentIndex()].className = "activeA"; //setting the active class name
//}

function setListActiveAnchor(active_anchor){
	if ((getCurrentAnchor() != null) && ($(getCurrentAnchor()) != null)){
		$(getCurrentAnchor()).className = "";
	}
	setCurrentAnchor(active_anchor);
	$(getCurrentAnchor()).className = "activeA";
	
}

//handles the scrolling of the list and setting of the current index
//function scrollListToIndex(a_array, scroll_index){
//	if (scroll_index > 0){
//	    var scroller = $('listScroller');
//		scroller.scrollTop = getY(a_array[scroll_index]) - 120; //the -120 is what keeps it from going to the top...
//	}
//}

function scrollListToAnchor(scroll2_anchor){
	var scroller = $('listScroller');
	scroller.scrollTop = getY($(scroll2_anchor)) - 120;
}

function jumpToAnchor(anchor_id){

	var contentScroller = $('rdocContent');
	var a_div = $(anchor_id);
	contentScroller.scrollTop = getY(a_div) - 80; //80 is the offset to adjust scroll point
	var a_title = $(anchor_id + "_title");
  a_title.style.backgroundColor = "#222";
  a_title.style.color = "#FFF";
  a_title.style.padding = "3px";
  // a_title.style.borderBottom = "2px solid #ccc";

	//other attempts
	//a_div.className = "activeMethod"; //setting the active class name
	//a_div.style.backgroundColor = "#ffc";
	//var titles = a_div.getElementsByClassName("title");
	//titles[0].className = "activeTitle";

}

function jumpToTop(){
	$('rdocContent').scrollTop = 0;
}

function changeLoadingStatus(status){
	if (status == "on"){
		$('loadingStatus').show();
	}
	else{
		$('loadingStatus').hide();
	}
}

//************* Misc functions (mostly from the old rdocs) ***********************
//snagged code from the old templating system
function toggleSource( id ){
	
         var elem
         var link

         if( document.getElementById )
         {
           elem = document.getElementById( id )
           link = document.getElementById( "l_" + id )
         }
         else if ( document.all )
         {
           elem = eval( "document.all." + id )
           link = eval( "document.all.l_" + id )
         }
         else
           return false;

         if( elem.style.display == "block" )
         {
           elem.style.display = "none"
           link.innerHTML = "show source"
         }
         else
         {
           elem.style.display = "block"
           link.innerHTML = "hide source"
         }
}

function openCode( url ){
     window.open( url, "SOURCE_CODE", "width=400,height=400,scrollbars=yes" )
}	

//this function handles the ajax calling and afterits loaded the jumping to the anchor...
function jsHref(url){
	//alert(url);
    var mainHtml = new Ajax.Request(url, {
	  method: 'get',
	  onSuccess: function(method_data) {
	   	setMainContent(method_data.responseText);}
		});
}

//function comparePatterns(string, regexp){
//	var direction = 0;
//	
//	
//	return (direction)
//}

////returns the index of the element 
//function binSearcher(regexp_pattern, list, start_index, stop_index){
//	//divide the list in half
//	var split_point = 0;
//	split_point = parseInt((stop_index - start_index)/2);
//	direction = comparePatterns(list[split_point].innerHTML, regexp_pattern);
//	if(direction < 0)
//		return (binSearcher(regexp_pattern, list, start_index, split_point));
//	else
//		if(direction > 0)
//			return (binSearcher(regexp_pattern, list, split_point, stop_index));
//		else
//			return(split_point);
//	
//}



