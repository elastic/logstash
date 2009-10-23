module RDoc
module Page

STYLE = File.read(File.join(File.dirname(__FILE__), 'merb_doc_styles.css'))
FONTS = ""

###################################################################

CLASS_PAGE = <<HTML
<div id="%class_seq%">
<div class='banner'>
  <span class="file-title-prefix">%classmod%</span><br />%full_name%<br/>
  In:
START:infiles
<a href="#" onclick="jsHref('%full_path_url%');">%full_path%</a>
IF:cvsurl
&nbsp;(<a href="#" onclick="jsHref('%cvsurl%');">CVS</a>)
ENDIF:cvsurl
END:infiles

IF:parent
Parent:&nbsp;
IF:par_url
        <a href="#" onclick="jsHref('%par_url%');">
ENDIF:par_url
%parent%
IF:par_url
         </a>
ENDIF:par_url
ENDIF:parent
</div>
HTML

###################################################################

METHOD_LIST = <<HTML
  <div id="content">
IF:diagram
  <table cellpadding='0' cellspacing='0' border='0' width="100%"><tr><td align="center">
    %diagram%
  </td></tr></table>
ENDIF:diagram

IF:description
  <div class="description">%description%</div>
ENDIF:description

IF:requires
  <div class="sectiontitle">Required Files</div>
  <ul>
START:requires
  <li><a href="#" onclick="jsHref('%href%');">%name%</a></li>
END:requires
  </ul>
ENDIF:requires

IF:toc
  <div class="sectiontitle">Contents</div>
  <ul>
START:toc
  <li><a href="#" onclick="jsHref('%href%');">%secname%</a></li>
END:toc
  </ul>
ENDIF:toc

IF:methods
  <div class="sectiontitle">Methods</div>
  <ul>
START:methods
  <li><a href="index.html?a=%href%&name=%name%" >%name%</a></li>
END:methods
  </ul>
ENDIF:methods

IF:includes
<div class="sectiontitle">Included Modules</div>
<ul>
START:includes
  <li><a href="#" onclick="jsHref('%href%');">%name%</a></li>
END:includes
</ul>
ENDIF:includes

START:sections
IF:sectitle
<div class="sectiontitle"><a href="%secsequence%">%sectitle%</a></div>
IF:seccomment
<div class="description">
%seccomment%
</div>
ENDIF:seccomment
ENDIF:sectitle

IF:classlist
  <div class="sectiontitle">Classes and Modules</div>
  %classlist%
ENDIF:classlist

IF:constants
  <div class="sectiontitle">Constants</div>
  <table border='0' cellpadding='5'>
START:constants
  <tr valign='top'>
    <td class="attr-name">%name%</td>
    <td>=</td>
    <td class="attr-value">%value%</td>
  </tr>
IF:desc
  <tr valign='top'>
    <td>&nbsp;</td>
    <td colspan="2" class="attr-desc">%desc%</td>
  </tr>
ENDIF:desc
END:constants
  </table>
ENDIF:constants

IF:attributes
  <div class="sectiontitle">Attributes</div>
  <table border='0' cellpadding='5'>
START:attributes
  <tr valign='top'>
    <td class='attr-rw'>
IF:rw
[%rw%]
ENDIF:rw
    </td>
    <td class='attr-name'>%name%</td>
    <td class='attr-desc'>%a_desc%</td>
  </tr>
END:attributes
  </table>
ENDIF:attributes

IF:method_list
START:method_list
IF:methods
<div class="sectiontitle">%type% %category% methods</div>
START:methods
<div id="%m_seq%" class="method">
  <div id="%m_seq%_title" class="title">
IF:callseq
    <b>%callseq%</b>
ENDIF:callseq
IFNOT:callseq
    <b>%name%</b>%params%
ENDIF:callseq
IF:codeurl
[ <a href="javascript:openCode('%codeurl%')">source</a> ]
ENDIF:codeurl
  </div>
IF:m_desc
  <div class="description">
  %m_desc%
  </div>
ENDIF:m_desc
IF:aka
<div class="aka">
  This method is also aliased as
START:aka
  <a href="index.html?a=%aref%&name=%name%">%name%</a>
END:aka
</div>
ENDIF:aka
IF:sourcecode
<div class="sourcecode">
  <p class="source-link">[ <a href="javascript:toggleSource('%aref%_source')" id="l_%aref%_source">show source</a> ]</p>
  <div id="%aref%_source" class="dyn-source">
<pre>
%sourcecode%
</pre>
  </div>
</div>
ENDIF:sourcecode
</div>
END:methods
ENDIF:methods
END:method_list
ENDIF:method_list
END:sections
</div>
HTML




BODY = <<ENDBODY
  !INCLUDE! <!-- banner header -->

  <div id="bodyContent" >
    #{METHOD_LIST}
  </div>

ENDBODY



SRC_BODY = <<ENDSRCBODY
  !INCLUDE! <!-- banner header -->

  <div id="bodyContent" >
    <h2>Source Code</h2>
    <pre>%file_source_code%</pre>
    </div>
ENDSRCBODY


###################### File Page ##########################
FILE_PAGE = <<HTML
<div id="fileHeader">
    <h1>%short_name%</h1>
    <table class="header-table">
    <tr class="top-aligned-row">
      <td><strong>Path:</strong></td>
      <td>%full_path%
IF:cvsurl
        &nbsp;(<a href="%cvsurl%"><acronym title="Concurrent Versioning System">CVS</acronym></a>)
ENDIF:cvsurl
      </td>
    </tr>
    <tr class="top-aligned-row">
      <td><strong>Last Update:</strong></td>
      <td>%dtm_modified%</td>
    </tr>
    </table>
  </div>
HTML


#### This is not used but kept for historical purposes
########################## Source code ########################## 
# Separate page onlye

SRC_PAGE = <<HTML
<html>
<head><title>%title%</title>
<meta http-equiv="Content-Type" content="text/html; charset=%charset%">
<style>
.ruby-comment    { color: green; font-style: italic }
.ruby-constant   { color: #4433aa; font-weight: bold; }
.ruby-identifier { color: #222222;  }
.ruby-ivar       { color: #2233dd; }
.ruby-keyword    { color: #3333FF; font-weight: bold }
.ruby-node       { color: #777777; }
.ruby-operator   { color: #111111;  }
.ruby-regexp     { color: #662222; }
.ruby-value      { color: #662222; font-style: italic }
  .kw { color: #3333FF; font-weight: bold }
  .cmt { color: green; font-style: italic }
  .str { color: #662222; font-style: italic }
  .re  { color: #662222; }
</style>
</head>
<body bgcolor="white">
<pre>%code%</pre>
</body>
</html>
HTML

########################### source page body ###################

SCR_CODE_BODY = <<HTML
    <div id="source">
    %source_code%
    </div>

HTML

########################## Index ################################

FR_INDEX_BODY = <<HTML
!INCLUDE!
HTML

FILE_INDEX = <<HTML
<ul>
START:entries
<li><a id="%seq_id%_link" href="index.html?a=%seq_id%&name=%name%" onclick="loadIndexContent('%href%','%seq_id%','%name%', '%scope%');">%name%</a><small>%scope%</small></li>
END:entries
</ul>
HTML

CLASS_INDEX = FILE_INDEX
METHOD_INDEX = FILE_INDEX

INDEX = <<HTML
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <meta name="description" content="A nifty way to interact with the Merb API" />
 	<meta name="author" content="created by Brian Chamberlain. You can contact me using 'blchamberlain' on the gmail." />
	<meta name="keywords" content="merb, ruby, purple, monkey, dishwasher" />
	<title>Merb | %title% API Documentation</title>
	<link rel="stylesheet" href="http://merbivore.com/documentation/stylesheet.css" type="text/css" media="screen" />    
	<script type="text/javascript" src="http://merbivore.com/documentation/prototype.js" ></script>
	<script type="text/javascript" src="http://merbivore.com/documentation/api_grease.js" ></script>
</head>
<body onload="setupPage();">
<ul id="groupType">
	<li>methods</li>
	<li>classes</li>
	<li>files</li>
	<li id="loadingStatus" style="display:none;">	loading...</li>
</ul>	
<div id="listFrame">
	<div id="listSearch">
		<form id="searchForm" method="get" action="#" onsubmit="return false">
			<input type="text" name="searchText" id="searchTextField" size="30" autocomplete="off" />
	 	</form>
	</div>
	<div id="listScroller">
	    Loading via ajax... this could take a sec.
	</div>	
</div>
<div id="browserBar">
	&nbsp;&nbsp;&nbsp;<span id="browserBarInfo">%title% README</span>
</div>
<div id="rdocContent">
  %content%
</div>
<div id="floater">
<strong>Documentation for %title% </strong><a href="#" onmouseover="$('tips').show();" onmouseout="$('tips').hide();">usage tips</a>
<div id="tips" style="position:absolute;width:350px;top:15px;right:20px;padding:5px;border:1px solid #333;background-color:#fafafa;display:none;">
	<p><strong>Some tips</strong> 
		<ul>
			<li> Up/Down keys move through the search list</li>
			<li> Return/enter key loads selected item</li>
			<li> Want to use this RDOC template for your own project? Check out <br /> http://rubyforge.org/projects/jaxdoc</li>
		</ul>
	</p>
</div>
<div id="blowOutListBox" style="display:none;">&nbsp;</div>
<script src="http://www.google-analytics.com/urchin.js" type="text/javascript">
</script>
<script type="text/javascript">
_uacct = "UA-3085184-1";
urchinTracker();
</script>
</body>
</html>
HTML

API_GREASE_JS = File.read(File.join(File.dirname(__FILE__), 'api_grease.js'))

PROTOTYPE_JS = File.read(File.join(File.dirname(__FILE__), 'prototype.js'))
end
end

